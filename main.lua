-- TODO:
-- package AI and LO with GuildData instead (GuildData is all data that only GL can send / must be verified to come from GL)
-- serialize communications
-- make loot officers only ones able to push (client checks that sender is loot officer)
-- make guild leader only one that sends LootOfficers and ActiveRaids (change name) i.e. not auto sync based on time stamps
-- client chekcs that sender of GuildData is in fact the guild leader
-- make init slash command for guild data

--------------------------------------
-- NAMESPACES
--------------------------------------
local _, core = ...; -- returns name of addon and namespace (core)
core.SKC_Main = {}; -- adds SKC_Main table to addon namespace

local SKC_Main = core.SKC_Main; -- assignment by reference in lua, ugh
local SKC_UIMain; -- Main GUI
local SKC_UICSV = {}; -- Table for GUI associated with CSV import and export
local SKC_LootGUI; -- Loot GUI
--------------------------------------
-- LOAD LIBRARIES
--------------------------------------
SKC = LibStub("AceAddon-3.0"):NewAddon("SKC","AceComm-3.0");
SKC.lib_ser = LibStub:GetLibrary("AceSerializer-3.0");
SKC.lib_comp = LibStub:GetLibrary("LibCompress");
SKC.lib_enc = SKC.lib_comp:GetAddonEncodeTable();
--------------------------------------
-- DEV CONTROLS
--------------------------------------
local HARD_DB_RESET = false; -- resets SKC_DB
local ML_OVRD = nil; -- name of faux ML override master looter permissions
local GL_OVRD = "Paskal"; -- name of faux GL to override guild leader permissions
local LOOT_SAFE_MODE = false; -- true if saving loot is immediately rejected
local LOOT_DIST_DISABLE = true; -- true if loot distribution is disabled
local LOG_ACTIVE_OVRD = false; -- true to force logging
local CHARS_OVRD = { -- characters which are pushed into GuildData
	-- Freznic = true,
};
local ACTIVE_RAID_OVRD = false; -- true if SKC can be used outside of active raids
local LOOT_OFFICER_OVRD = false; -- true if SKC can be used without loot officer 
-- verbosity
local GUI_VERBOSE = false; -- relating to GUI objects
local GUILD_SYNC_VERBOSE = false; -- relating to guild sync
local COMM_VERBOSE = true; -- prints messages relating to addon communication
local LOOT_VERBOSE = false; -- prints lots of messages during loot distribution
local RAID_VERBOSE = false; -- relating to raid activity
local LIVE_MERGE_VERBOSE = false; -- relating to live list merging
--------------------------------------
-- DEFINE CHANNELS
--------------------------------------
local CHANNELS = { -- channels for inter addon communication (const)
	LOGIN_SYNC_CHECK = "?Q!@$8a1pc8QqYyH",
	LOGIN_SYNC_PUSH = "6-F?832qBmrJE?pR",
	LOGIN_SYNC_PUSH_RQST = "d$8B=qB4VsW&&Y^D",
	SYNC_PUSH = "8EtTWxyA$r6xi3=F",
	LOOT = "xBPE9,-Fjsc+A#rm",
	LOOT_DECISION = "ksg(Ak2.*/@&+`8Q",
	LOOT_DECISION_PRINT = "xP@&!9hQxY]1K&C4",
	LOOT_OUTCOME = "aP@yX9hQf}89K&C4",
};
--------------------------------------
-- LOCAL VARIABLES
--------------------------------------
local tmp_sync_var = {}; -- temporary variable used to hold incoming data when synchronizing
local UnFilteredCnt = 0; -- defines max count of sk cards to scroll over
local SK_MessagesSent = 0;
local SK_MessagesReceived = 0;
local event_states = { -- tracks if certain events have fired
	AddonLoaded = false,
	RaidLoggingActive = LOG_ACTIVE_OVRD, -- latches true when raid is entered (controls RaidLog)
	LoginSyncCheckTicker = nil, -- ticker that requests sync each iteration until over or cancelled
	LoginSyncCheckTicker_InitDelay = 5, -- seconds
	LoginSyncCheckTicker_Intvl = 10, -- seconds between function calls
	LoginSyncCheckTicker_MaxTicks = 59, -- 1 tick = 1 sec
	LoginSyncCheckTicker_Ticks = nil,
	LoginSyncPartner = nil, -- name of sender who answered LoginSyncCheck first
	ReadInProgress = {
		MSK = false,
		TSK = false,
		GuildData = false,
		LootPrio = false,
		Bench = false,
		ActiveRaids = false,
		LootOfficers = false,
	},
	PushInProgress = {
		MSK = false,
		TSK = false,
		GuildData = false,
		LootPrio = false,
		Bench = false,
		ActiveRaids = false,
		LootOfficers = false,
	},
};
event_states.LoginSyncCheckTicker_Ticks = event_states.LoginSyncCheckTicker_MaxTicks + 1;
local blacklist = {}; -- map of names for which SyncPushRead's are blocked (due to addon version or malformed messages)
local LootTimer = nil; -- current loot timer
local DD_State = 0; -- used to track state of drop down menu
local SetSK_Flag = false; -- true when SK position is being set
local SKC_Status = SKC_STATUS_ENUM.INACTIVE_GL; -- SKC status state enumeration
local InitGuildSync = false; -- used to control for first time setup
local DEBUG = {
	ReadTime = {
		GLP = nil,
		LOP = nil,
		GuildData = nil,
		MSK = nil,
		TSK = nil,
	},
	PushTime = {
		GLP = nil,
		LOP = nil,
		GuildData = nil,
		MSK = nil,
		TSK = nil,
	},
};


--------------------------------------
-- HELPER METHODS
--------------------------------------


--------------------------------------
-- LOCAL FUNCTIONS
--------------------------------------
local function ResetLootLog()
	SKC_DB.RaidLog = {};
	-- Initialize with header
	WriteToLog(
		LOG_OPTIONS["Event Type"].Text,
		LOG_OPTIONS["Subject"].Text,
		LOG_OPTIONS["Action"].Text,
		LOG_OPTIONS["Item"].Text,
		LOG_OPTIONS["SK List"].Text,
		LOG_OPTIONS["Prio"].Text,
		LOG_OPTIONS["Current SK Position"].Text,
		LOG_OPTIONS["New SK Position"].Text,
		LOG_OPTIONS["Roll"].Text,
		LOG_OPTIONS["Item Receiver"].Text,
		LOG_OPTIONS["Timestamp"].Text,
		LOG_OPTIONS["Master Looter"].Text,
		LOG_OPTIONS["Class"].Text,
		LOG_OPTIONS["Spec"].Text,
		LOG_OPTIONS["Status"].Text
	);
	return;
end

local function ManageLootLogging()
	-- determines if loot loging should be on or off
	-- activate SKC / update GUI
	SKC_Main:RefreshStatus();
	-- check if SKC is active, if so start loot logging
	local prev_log_state = event_states.RaidLoggingActive;
	if LOG_ACTIVE_OVRD or CheckActive() then
		event_states.RaidLoggingActive = true;
		if not prev_log_state then
			ResetLootLog();
			SKC_Main:Print("WARN","Loot logging turned on");
		end
	else
		event_states.RaidLoggingActive = false;
		if prev_log_state then SKC_Main:Print("WARN","Loot logging turned off") end
	end
	return;
end

local function LoginSyncCheckSend()
	-- Send timestamps of each database to each online member of guild (will sync with first response)
	-- decrement ticker
	event_states.LoginSyncCheckTicker_Ticks = event_states.LoginSyncCheckTicker_Ticks - 1;
	-- check if interval met
	if event_states.LoginSyncCheckTicker_Ticks % event_states.LoginSyncCheckTicker_Intvl == 0 then
		-- Reject if addon database has not yet loaded
		if not CheckAddonLoaded(COMM_VERBOSE) then
			if COMM_VERBOSE then SKC_Main:Print("WARN","Reject LoginSyncCheckSend()") end
			return;
		end
		if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","LoginSyncCheckSend()") end
		local db_lsit = {"GLP","LOP","GuildData","MSK","TSK"}; -- important that they are requested in this order
		local msg = SKC_DB.AddonVersion;
		for _,db_name in ipairs(db_lsit) do
			msg = msg..","..db_name..","..NilToStr(SKC_DB[db_name].edit_ts_raid)..","..NilToStr(SKC_DB[db_name].edit_ts_generic);
		end
		-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOGIN_SYNC_CHECK,msg,"GUILD",nil,"main_queue");
		SendCompMsg(msg,CHANNELS.LOGIN_SYNC_CHECK,"GUILD");
	end
	-- check if ticker has completed entire duration
	if event_states.LoginSyncCheckTicker_Ticks <= 0 then
		-- cancel
		event_states.LoginSyncCheckTicker:Cancel();
	end
	-- update status
	SKC_Main:RefreshStatus();
	return;
end

local function UpdateActivity(name)
	-- check if activity exceeds threshold and updates if different
	local activity = "Inactive";
	if CheckActivity(name) then activity = "Active" end
	if SKC_DB.GuildData:GetData(name,"Activity") ~= activity then
		if not init then SKC_Main:Print("IMPORTANT",name.." set to "..activity) end
		SKC_DB.GuildData:SetData(name,"Activity",activity);
	end
end

local function StartSyncCheckTimer()
	-- Create ticker that attempts to sync with guild at each iteration
	-- once responded to, ticker is cancelled
	if event_states.LoginSyncCheckTicker == nil then
		-- only create ticker if one doesnt exist
		event_states.LoginSyncCheckTicker = C_Timer.NewTicker(1,LoginSyncCheckSend,event_states.LoginSyncCheckTicker_MaxTicks);
		if COMM_VERBOSE then SKC_Main:Print("NORMAL", "LoginSyncCheckTicker created") end
		-- call function immediately
		LoginSyncCheckSend();
	end
	return;
end

local function SyncGuildData()
	-- synchronize GuildData with guild roster
	if not CheckAddonLoaded(COMM_VERBOSE) then
		if COMM_VERBOSE then SKC_Main:Print("WARN","Reject SyncGuildData()") end
		return;
	end
	if event_states.ReadInProgress.GuildData or event_states.PushInProgress.GuildData then
		if GUILD_SYNC_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncGuildData, sync in progress") end
		return;
	end
	if not IsInGuild() then
		if GUILD_SYNC_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncGuildData, not in guild") end
		return;
	end
	if not CheckIfAnyGuildMemberOnline() then
		if GUILD_SYNC_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncGuildData, no online guild members") end
		return;
	end
	if GetNumGuildMembers() <= 1 then
		-- guild is only one person, no members to fetch data for
		if GUILD_SYNC_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncGuildData, no guild members") end
		return;
	end
	if not SKC_Main:isGL() then
		-- only fetch data if guild leader
		if GUILD_SYNC_VERBOSE then SKC_Main:Print("WARN","Rejected SyncGuildData, not guild leader") end
	else
		-- Scan guild roster and add new players
		local guild_roster = {};
		for idx = 1, GetNumGuildMembers() do
			local full_name, _, _, level, class = GetGuildRosterInfo(idx);
			local name = StripRealmName(full_name);
			if level == 60 or CHARS_OVRD[name] then
				guild_roster[name] = true;
				if not SKC_DB.GuildData:Exists(name) then
					-- new player, add to DB and SK lists
					SKC_DB.GuildData:Add(name,class);
					SKC_DB.MSK:PushBack(name);
					SKC_DB.TSK:PushBack(name);
					if not InitGuildSync then SKC_Main:Print("NORMAL",name.." added to databases") end
				end
				-- check activity level and update
				UpdateActivity(name);
			end
		end
		-- Scan guild data and remove players
		for name,data in pairs(SKC_DB.GuildData.data) do
			if guild_roster[name] == nil then
				SKC_DB.MSK:Remove(name);
				SKC_DB.TSK:Remove(name);
				SKC_DB.GuildData:Remove(name);
				if not InitGuildSync then SKC_Main:Print("ERROR",name.." removed from databases") end
			end
		end
		-- miscellaneous
		UnFilteredCnt = SKC_DB.GuildData:length();
		if InitGuildSync and (SKC_DB.GuildData:length() ~= 0) then
			-- init sync completed
			SKC_Main:Print("WARN","Populated fresh GuildData ("..SKC_DB.GuildData:length()..")");
			if COMM_VERBOSE then SKC_Main:Print("NORMAL","Generic TS: "..SKC_DB.GuildData.edit_ts_generic..", Raid TS: "..SKC_DB.GuildData.edit_ts_raid) end
			-- add self (GL) to loot officers
			SKC_DB.GLP:AddLO(UnitName("player"));
			InitGuildSync = false;
		end
		-- set required version to current version
		SKC_DB.GLP:SetAddonVer(SKC_DB.AddonVersion);
		if GUILD_SYNC_VERBOSE then SKC_Main:Print("NORMAL","SyncGuildData success!") end
	end
	-- sync with guild
	if event_states.LoginSyncCheckTicker == nil then
		C_Timer.After(event_states.LoginSyncCheckTicker_InitDelay,StartSyncCheckTimer);
	end
	return;
end

local function CheckActiveInstance()
	if SKC_DB == nil or SKC_DB.GLP == nil then return false end
	return(SKC_DB.GLP:IsActiveInstance());
end

local function ActivateSKC()
	-- master control for wheter or not loot is managed with SKC
	if not CheckAddonLoaded() then return end
	if not SKC_DB.SKC_Enable then
		SKC_Status = SKC_STATUS_ENUM.DISABLED;
	elseif SKC_DB.GLP:GetGLAddonVer() == nil then
		SKC_Status = SKC_STATUS_ENUM.INACTIVE_GL;
	elseif not CheckAddonVerMatch() then
		SKC_Status = SKC_STATUS_ENUM.INACTIVE_VER;
	elseif not UnitInRaid("player") then
		SKC_Status = SKC_STATUS_ENUM.INACTIVE_RAID;
	elseif GetLootMethod() ~= "master" then
		SKC_Status = SKC_STATUS_ENUM.INACTIVE_ML;
	else
		-- Master Looter is Loot Officer
		local _, _, masterlooterRaidIndex = GetLootMethod();
		local master_looter_full_name = GetRaidRosterInfo(masterlooterRaidIndex);
		local loot_officer_check = SKC_Main:isLO(master_looter_full_name);
		if not loot_officer_check then
			SKC_Status = SKC_STATUS_ENUM.INACTIVE_LO;
		else
			-- Elligible instance
			if not CheckActiveInstance() then
				SKC_Status = SKC_STATUS_ENUM.INACTIVE_AI;
			else
				SKC_Status = SKC_STATUS_ENUM.ACTIVE;
			end
		end
	end
	return;
end

local function ManageLiveLists(name,live_status)
	-- adds / removes player to live lists and records time in guild data
	local sk_lists = {"MSK","TSK"};
	for _,sk_list in pairs(sk_lists) do
		local success = SKC_DB[sk_list]:SetLive(name,live_status);
	end
	-- update guild data if SKC is active
	if CheckActive() then
		local ts = time();
		SKC_DB.GuildData:SetLastLiveTime(name,ts);
	end
	return;
end

local function UpdateLiveList()
	-- Adds every player in raid to live list
	-- All players update their own local live lists
	if not CheckAddonLoaded() then return end
	if RAID_VERBOSE then SKC_Main:Print("IMPORTANT","Updating live list") end

	-- Activate SKC
	SKC_Main:RefreshStatus();

	-- Scan raid and update live list
	for char_name,_ in pairs(SKC_DB.GuildData.data) do
		ManageLiveLists(char_name,UnitInRaid(char_name) ~= nil);
	end

	-- Scan bench and adjust live
	for char_name,_ in pairs(SKC_DB.LOP.bench.data) do
		ManageLiveLists(char_name,true);
	end

	-- populate data
	SKC_Main:PopulateData();
	return;
end

local function HardReset()
	-- resets the saved variables completely
	SKC_DB = {};
	SKC_DB.SKC_Enable = true;
	SKC_DB.AddonVersion = ADDON_VERSION;
	InitGuildSync = true;
	return;
end

function SKC:LoginSyncCheckRead(data,channel,sender)
	-- Arbitrate based on timestamp to push or pull database from sender
	-- reject if addon not yet loaded
	if not CheckAddonLoaded(COMM_VERBOSE) then
		if COMM_VERBOSE then SKC_Main:Print("WARN","Reject LoginSyncCheckRead()") end
		return;
	end
	-- ignore messages from self
	if sender == UnitName("player") then return end
	-- check if sender has confirmed that databses are sync'd
	if msg == "DONE" then
		LoginSyncCheckAnswered(sender);
		return;
	end
	-- ignore checks if self check ticker is still active
	if LoginSyncCheckTickerActive() then return end
	-- Check if any read or push is in progress
	if CheckIfReadInProgress() then
		if COMM_VERBOSE then SKC_Main:Print("WARN","Reject LoginSyncCheckRead(), read already in progress") end
		return;
	end
	-- because wow online status API sucks, need to confirm that we see that the sender is online before responding
	-- addon messages are discarded if player is offline
	if not CheckIfGuildMemberOnline(sender) then
		-- need to keep requesting new guild roster...
		GuildRoster();
		return;
	end
	-- parse message
	local db_name, their_edit_ts_raid, their_edit_ts_generic, msg_rem;
	their_addon_ver, msg_rem = strsplit(",",msg,2);
	-- first check that addon version is valid
	if their_addon_ver ~= SKC_DB.AddonVersion then
		if COMM_VERBOSE then SKC_Main:Print("ERROR","Rejected LoginSyncCheckRead from "..sender.." due to addon version. Theirs: "..their_addon_ver.." Mine: "..SKC_DB.AddonVersion) end
		return;
	end
	if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","LoginSyncCheckRead() from "..sender) end
	while msg_rem ~= nil do
		-- iteratively parse out each db and arbitrate how to sync
		db_name, their_edit_ts_raid, their_edit_ts_generic, msg_rem = strsplit(",",msg_rem,4);
		their_edit_ts_raid = NumOut(their_edit_ts_raid);
		their_edit_ts_generic = NumOut(their_edit_ts_generic);
		-- get self edit time stamps (possible to be nil)
		local my_edit_ts_raid = SKC_DB[db_name].edit_ts_raid;
		local my_edit_ts_generic = SKC_DB[db_name].edit_ts_generic;
		if (my_edit_ts_raid ~= nil and my_edit_ts_generic ~=nil) and ( (my_edit_ts_raid > their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic > their_edit_ts_generic) ) ) then
			-- I have an existing version of this database AND
			-- I have newer RAID data OR I have the same RAID data but newer generic data
			-- --> send them my data
			if COMM_VERBOSE then SKC_Main:Print("WARN","Pushing "..db_name.." to "..sender) end
			SyncPushSend(db_name,CHANNELS.LOGIN_SYNC_PUSH,"WHISPER",sender);
		elseif (my_edit_ts_raid == nil or my_edit_ts_generic ==nil) or ( (my_edit_ts_raid < their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic < their_edit_ts_generic) ) ) then
			-- I do not have this database at all yet
			-- OR I have older RAID data
			-- OR I have the same RAID data but older generic data
			-- --> request their data (for the whole guild)
			if COMM_VERBOSE then SKC_Main:Print("WARN","Requesting "..db_name.." from "..sender) end
			-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOGIN_SYNC_PUSH_RQST,db_name,"WHISPER",sender,"main_queue");
		else
			-- alert them that already sync'd
			if COMM_VERBOSE then SKC_Main:Print("NORMAL","Already synchronized "..db_name.." with "..sender) end
			-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOGIN_SYNC_CHECK,"DONE","WHISPER",sender,"main_queue");
		end
	end
	return;
end

function SKC:OnInitialize()
	self:RegisterComm(LOGIN_SYNC_CHECK,self.LoginSyncCheckRead);
	-- LOGIN_SYNC_PUSH = "6-F?832qBmrJE?pR",
	-- LOGIN_SYNC_PUSH_RQST = "d$8B=qB4VsW&&Y^D",
	-- SYNC_PUSH = "8EtTWxyA$r6xi3=F",
	-- LOOT = "xBPE9,-Fjsc+A#rm",
	-- LOOT_DECISION = "ksg(Ak2.*/@&+`8Q",
	-- LOOT_DECISION_PRINT = "xP@&!9hQxY]1K&C4",
	-- LOOT_OUTCOME = "aP@yX9hQf}89K&C4",
	for _,channel in pairs(CHANNELS) do
		self:RegisterComm(channel,self.AddonMessageRead);
		-- TODO, need to make specific callback to read each channel....
	end
	return;
end

local function OnAddonLoad(addon_name)
	if addon_name ~= "SKC" then return end
	InitGuildSync = false; -- only initialize if hard reset or new install
	-- Initialize DBs
	if SKC_DB == nil or HARD_DB_RESET then
		HardReset();
		if HARD_DB_RESET then 
			SKC_Main:Print("IMPORTANT","Hard Reset: Manual");
		end
		SKC_Main:Print("IMPORTANT","Welcome (/skc help)");
	else
		SKC_Main:Print("IMPORTANT","Welcome back (/skc)");
	end
	-- if SKC_DB.AddonVersion == nil or SKC_DB.AddonVersion ~= ADDON_VERSION then
	-- 	-- addon version never set
	-- 	HardReset();
	-- 	SKC_Main:Print("IMPORTANT","Hard Reset: New addon version "..SKC_DB.AddonVersion);
	-- end
	if SKC_DB.GLP == nil then
		SKC_DB.GLP = nil;
	end
	if SKC_DB.LOP == nil then
		SKC_DB.LOP = nil;
	end
	if SKC_DB.GuildData == nil then
		SKC_DB.GuildData = nil;
	end
	if SKC_DB.MSK == nil then 
		SKC_DB.MSK = nil;
	end
	if SKC_DB.TSK == nil then 
		SKC_DB.TSK = nil;
	end
	if SKC_DB.RaidLog == nil then
		SKC_DB.RaidLog = {};
	end
	if SKC_DB.LootManager == nil then
		SKC_DB.LootManager = nil
	end
	if SKC_DB.FilterStates == nil then
		SKC_DB.FilterStates = {
			DPS = true,
			Healer = true,
			Tank = true,
			Live = false,
			Main = true,
			Alt = true,
			Active = true,
			Inactive = false,
			Druid = true,
			Hunter = true,
			Mage = true,
			Paladin = UnitFactionGroup("player") == "Alliance",
			Priest = true;
			Rogue = true,
			Shaman = UnitFactionGroup("player") == "Horde",
			Warlock = true,
			Warrior = true,
		};
	end
	-- always reset live filter state because its confusing to see a blank list
	SKC_DB.FilterStates.Live = false;
	-- Initialize or refresh metatables
	SKC_DB.GLP = GuildLeaderProtected:new(SKC_DB.GLP);
	SKC_DB.LOP = LootOfficerProtected:new(SKC_DB.LOP);
	SKC_DB.GuildData = GuildData:new(SKC_DB.GuildData);
	SKC_DB.MSK = SK_List:new(SKC_DB.MSK);
	SKC_DB.TSK = SK_List:new(SKC_DB.TSK);
	SKC_DB.LootManager = LootManager:new(SKC_DB.LootManager);
	-- Addon loaded
	event_states.AddonLoaded = true;
	-- Manage loot logging
	ManageLootLogging();
	-- Update live list
	UpdateLiveList();
	-- Populate data
	SKC_Main:PopulateData();
	return;
end

local function GetScrollMax()
	return((UnFilteredCnt)*(UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING));
end

local function OnMouseWheel_ScrollFrame(self,delta)
    -- delta: 1 scroll up, -1 scroll down
	-- value at top is 0, value at bottom is size of child
	-- scroll so that one wheel is 3 SK cards
	local scroll_range = self:GetVerticalScrollRange();
	local inc = 3 * (UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING)
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (inc*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

local function CheckSKinGuildData(sk_list,sk_list_data)
	-- Check that every character in SK list is also in GuildData
	if sk_list_data == nil then
		sk_list_data = SKC_DB[sk_list]:ReturnList();
	end
	for pos,name in ipairs(sk_list_data) do
		if not SKC_DB.GuildData:Exists(name) then
			if COMM_VERBOSE then SKC_Main:Print("WARN",name.." in "..sk_list.." but not in GuildData") end
			return false;
		end
	end
	return true;
end

function SKC_Main:HideSKCards()
	-- Hide all cards
	if SKC_UIMain == nil then return end
	local sk_list = SKC_UIMain["sk_list_border"].Title.Text:GetText();
	for idx = 1, SKC_DB.GuildData:length() do
		SKC_UIMain.sk_list.NumberFrame[idx]:Hide();
		SKC_UIMain.sk_list.NameFrame[idx]:Hide();
	end
	return;
end

function SKC_Main:UpdateSKUI()
	-- populates the SK list
	if GUI_VERBOSE then SKC_Main:Print("NORMAL","UpdateSKUI() start") end
	if SKC_UIMain == nil then return end
	if not CheckAddonLoaded(COMM_VERBOSE) then return end
	
	SKC_Main:HideSKCards();

	-- Fetch SK list
	local sk_list = SKC_UIMain["sk_list_border"].Title.Text:GetText();
	local print_order = SKC_DB[sk_list]:ReturnList();

	-- Confirm that every character in SK list is also in GuildData
	if not CheckSKinGuildData(sk_list,print_order) then return end

	-- Populate non filtered cards
	local idx = 1;
	local max_cnt = 0;
	for pos,name in ipairs(print_order) do
		local class_tmp = SKC_DB.GuildData:GetData(name,"Class");
		local raid_role_tmp = SKC_DB.GuildData:GetData(name,"Raid Role");
		local status_tmp = SKC_DB.GuildData:GetData(name,"Status");
		local activity_tmp = SKC_DB.GuildData:GetData(name,"Activity");
		local live_tmp = SKC_DB[sk_list]:GetLive(name);
		-- only add cards to list which are not being filtered
		if SKC_DB.FilterStates[class_tmp] and 
		   SKC_DB.FilterStates[raid_role_tmp] and
		   SKC_DB.FilterStates[status_tmp] and
		   SKC_DB.FilterStates[activity_tmp] and
		   (live_tmp or (not live_tmp and not SKC_DB.FilterStates.Live)) then
			-- Add position number text
			SKC_UIMain.sk_list.NumberFrame[idx].Text:SetText(pos);
			SKC_UIMain.sk_list.NumberFrame[idx]:Show();
			-- Add name text
			SKC_UIMain.sk_list.NameFrame[idx].Text:SetText(name)
			-- create class color background
			SKC_UIMain.sk_list.NameFrame[idx].bg:SetColorTexture(CLASSES[class_tmp].color.r,CLASSES[class_tmp].color.g,CLASSES[class_tmp].color.b,0.25);
			SKC_UIMain.sk_list.NameFrame[idx]:Show();
			-- increment
			idx = idx + 1;
		end
		-- increment
		max_cnt = max_cnt + 1;
	end
	UnFilteredCnt = idx; -- 1 larger than max cards
	-- update scroll length
	SKC_UIMain.sk_list.SK_List_SF:GetScrollChild():SetSize(UI_DIMENSIONS.SK_LIST_WIDTH,GetScrollMax());
	-- update filter status
	local filter_status_name = "Filter Status";
	SKC_UIMain["Filters_border"][filter_status_name].Data:SetText((UnFilteredCnt - 1).." / "..max_cnt);
	if GUI_VERBOSE then SKC_Main:Print("NORMAL","UpdateSKUI() end") end
	return;
end

local function OnCheck_FilterFunction (self, button)
	SKC_DB.FilterStates[self.text:GetText()] = self:GetChecked();
	SKC_Main:UpdateSKUI();
	return;
end

function SKC_Main:RefreshStatus()
	-- refresh variable and update GUI
	if GUI_VERBOSE then SKC_Main:Print("NORMAL","RefreshStatus()") end
	ActivateSKC();
	if SKC_UIMain == nil then return end
	SKC_UIMain["Status_border"]["Status"].Data:SetText(SKC_Status.text);
	SKC_UIMain["Status_border"]["Status"].Data:SetTextColor(unpack(SKC_Status.color));
	if CheckIfPushInProgress() then
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetText("Pushing");
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetTextColor(1,0,0,1);
	elseif CheckIfReadInProgress() then
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetText("Reading");
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetTextColor(1,0,0,1);
	elseif event_states.LoginSyncCheckTicker == nil or not event_states.LoginSyncCheckTicker:IsCancelled() then
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetText("Waiting ("..event_states.LoginSyncCheckTicker_Ticks.."s)");
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetTextColor(1,0,0,1);
	else
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetText("Complete");
		SKC_UIMain["Status_border"]["Synchronization"].Data:SetTextColor(0,1,0,1);
	end
	SKC_UIMain["Status_border"]["Loot Prio Items"].Data:SetText(SKC_DB.GLP.loot_prio:length().." items");
	SKC_UIMain["Status_border"]["Loot Officers"].Data:SetText(SKC_DB.GLP.loot_officers:length());
	return;
end

function SKC_Main:RefreshDetails(name)
	-- populates the details fields
	if SKC_UIMain == nil then return end
	local fields = {"Name","Class","Spec","Raid Role","Guild Role","Status","Activity","Last Raid"};
	if name == nil then
		-- reset
		for _,field in pairs(fields) do
			SKC_UIMain["Details_border"][field].Data:SetText(nil);
		end
		-- Initialize with instructions
		SKC_UIMain["Details_border"]["Name"].Data:SetText("            Click on a character."); -- lol, so elegant
	else
		for _,field in pairs(fields) do
			if field == "Last Raid" then
				-- calculate # days since last active
				local days = math.floor(SKC_DB.GuildData:CalcActivity(name)/DAYS_TO_SECS);
				SKC_UIMain["Details_border"][field].Data:SetText(days.." days ago");
			else
				SKC_UIMain["Details_border"][field].Data:SetText(SKC_DB.GuildData:GetData(name,field));
			end
		end
		-- updated class color
		local class_color = CLASSES[SKC_DB.GuildData:GetData(name,"Class")].color;
		SKC_UIMain["Details_border"]["Class"].Data:SetTextColor(class_color.r,class_color.g,class_color.b,1.0);
		-- update last raid time
		UpdateActivity(name);
	end
	return;
end

function SKC_Main:PopulateData(name)
	-- Populates GUI with data if it already exists
	if GUI_VERBOSE then SKC_Main:Print("NORMAL","PopulateData()") end
	if not CheckAddonLoaded() then return end
	if SKC_UIMain == nil then return end
	-- Update Status
	SKC_Main:RefreshStatus();
	-- Refresh details
	SKC_Main:RefreshDetails(name);
	-- Update SK cards
	SKC_Main:UpdateSKUI();
	-- Reset Set SK Flag
	SetSK_Flag = false;
	return;
end

local function OnLoad_EditDropDown_Spec(self)
	local class = SKC_UIMain["Details_border"]["Class"].Data:GetText();
	for key,value in pairs(CLASSES[class].Specs) do
		UIDropDownMenu_AddButton(value);
	end
	return;
end

local function OnLoad_EditDropDown_GuildRole(self)
	UIDropDownMenu_AddButton(CHARACTER_DATA["Guild Role"].OPTIONS.None);
	UIDropDownMenu_AddButton(CHARACTER_DATA["Guild Role"].OPTIONS.Disenchanter);
	UIDropDownMenu_AddButton(CHARACTER_DATA["Guild Role"].OPTIONS.Banker);
	return;
end

local function OnLoad_EditDropDown_Status(self)
	UIDropDownMenu_AddButton(CHARACTER_DATA.Status.OPTIONS.Alt);
	UIDropDownMenu_AddButton(CHARACTER_DATA.Status.OPTIONS.Main);
	return;
end

local function OnLoad_EditDropDown_Activity(self)
	UIDropDownMenu_AddButton(CHARACTER_DATA.Activity.OPTIONS.Active);
	UIDropDownMenu_AddButton(CHARACTER_DATA.Activity.OPTIONS.Inactive);
	return;
end

function OnClick_EditDropDownOption(field,value) -- Must be global
	-- Triggered when drop down of edit button is selected
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	local class = SKC_UIMain["Details_border"]["Class"].Data:GetText();
	-- Edit GuildData
	local prev_val = SKC_DB.GuildData:GetData(name,field);
	prev_val = SKC_DB.GuildData:SetData(name,field,value);
	-- Refresh data
	SKC_Main:PopulateData(name);
	-- Reset menu toggle
	DD_State = 0;
	-- send GuildData to all players
	SyncPushSend("GuildData",CHANNELS.SYNC_PUSH,"GUILD",nil);
	return;
end

local function OnClick_EditDetails(self, button)
	-- Manages drop down menu that is generated for edit buttons
	if not self:IsEnabled() then return end
	-- SKC_UIMain.EditFrame:Show();
	local ID = self:GetID();
	-- Populate drop down options
	local field;
	if ID == 3 then
		field = "Spec";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_Spec) end
	elseif ID == 5 then
		-- Guild Role
		field = "Guild Role";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_GuildRole) end
	elseif ID == 6 then
		-- Status
		field = "Status";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_Status) end
	elseif ID == 7 then
		-- Activity
		field = "Activity";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_Activity) end
	else
		SKC_Main:Print("ERROR","Menu not found.");
		return;
	end
	ToggleDropDownMenu(1, nil, SKC_UIMain["Details_border"][field].DD, SKC_UIMain["Details_border"][field].DD, 0, 0);
	if DD_State == ID then
		DD_State = 0;
	else
		DD_State = ID;
	end
	return;
end

local function UpdateDetailsButtons(disable)
	-- disable / enable buttons in details frame appropriately for player privileges
	if SKC_UIMain == nil then return end
	-- Enable edit buttons
	if disable then
		SKC_UIMain["Details_border"]["Spec"].Btn:Disable();
		SKC_UIMain["Details_border"]["Guild Role"].Btn:Disable();
		SKC_UIMain["Details_border"]["Status"].Btn:Disable();
		SKC_UIMain["Details_border"]["Activity"].Btn:Disable();
		SKC_UIMain["Details_border"].manual_single_sk_btn:Disable();
		SKC_UIMain["Details_border"].manual_full_sk_btn:Disable();
		SKC_UIMain["Details_border"].manual_set_sk_btn:Disable();
	else
		if SKC_Main:isGL() then
			SKC_UIMain["Details_border"]["Spec"].Btn:Enable();
			SKC_UIMain["Details_border"]["Guild Role"].Btn:Enable();
			SKC_UIMain["Details_border"]["Status"].Btn:Enable();
			SKC_UIMain["Details_border"]["Activity"].Btn:Enable();
		else
			SKC_UIMain["Details_border"]["Spec"].Btn:Disable();
			SKC_UIMain["Details_border"]["Guild Role"].Btn:Disable();
			SKC_UIMain["Details_border"]["Status"].Btn:Disable();
			SKC_UIMain["Details_border"]["Activity"].Btn:Disable();
		end
		if SKC_Main:isGL() or (SKC_Main:isML() and SKC_Main:isLO()) then
			SKC_UIMain["Details_border"].manual_single_sk_btn:Enable();
			SKC_UIMain["Details_border"].manual_full_sk_btn:Enable();
			SKC_UIMain["Details_border"].manual_set_sk_btn:Enable();
		else
			SKC_UIMain["Details_border"].manual_single_sk_btn:Disable();
			SKC_UIMain["Details_border"].manual_full_sk_btn:Disable();
			SKC_UIMain["Details_border"].manual_set_sk_btn:Disable();
		end
	end
	return
end

local function OnClick_SK_Card(self, button)
	-- populates details frame for given sk card character
	if button=='LeftButton' and self.Text:GetText() ~= nill and DD_State == 0 and not SetSK_Flag then
		-- Populate data
		SKC_Main:RefreshDetails(self.Text:GetText());
		-- Enable edit buttons
		UpdateDetailsButtons();
	end
	return;
end

local function OnClick_FullSK(self)
	if self:IsEnabled() then
		SetSK_Flag = false;
		local sk_list = SKC_UIMain["sk_list_border"].Title.Text:GetText();
		-- On click event for full SK of details targeted character
		local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
		-- Get initial position
		local prev_pos = SKC_DB[sk_list]:GetPos(name);
		-- Execute full SK
		local success = SKC_DB[sk_list]:PushBack(name);
		if success then 
			-- log
			WriteToLog( 
				LOG_OPTIONS["Event Type"].Options.ManEdit,
				name,
				"Full SK",
				"",
				sk_list,
				"",
				prev_pos,
				SKC_DB[sk_list]:GetPos(name),
				"",
				""
			);
			SKC_Main:Print("IMPORTANT","Full SK on "..name);
			-- send SK data to all players
			SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
			-- Refresh SK List
			SKC_Main:UpdateSKUI();
		else
			SKC_Main:Print("ERROR","Full SK on "..name.." rejected");
		end
	end
	return;
end

local function OnClick_SingleSK(self)
	if self:IsEnabled() then
		SetSK_Flag = false;
		-- On click event for full SK of details targeted character
		local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
		local sk_list = SKC_UIMain["sk_list_border"].Title.Text:GetText();
		-- Get initial position
		local prev_pos = SKC_DB[sk_list]:GetPos(name);
		-- Execute full SK
		local name_below = SKC_DB[sk_list]:GetBelow(name);
		local success = SKC_DB[sk_list]:InsertBelow(name,name_below);
		if success then 
			-- log
			WriteToLog( 
				LOG_OPTIONS["Event Type"].Options.ManEdit,
				name,
				"Single SK",
				"",
				sk_list,
				"",
				prev_pos,
				SKC_DB[sk_list]:GetPos(name),
				"",
				""
			);
			SKC_Main:Print("IMPORTANT","Single SK on "..name);
			-- send SK data to all players
			SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
			-- Refresh SK List
			SKC_Main:UpdateSKUI();
		else
			SKC_Main:Print("ERROR","Single SK on "..name.." rejected");
		end
	end
	return;
end

local function OnClick_SetSK(self)
	-- On click event to set SK position of details targeted character
	-- Prompt user to click desired position number in list
	if self:IsEnabled() then
		SetSK_Flag = true;
		local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
		SKC_Main:Print("IMPORTANT","Click desired position in SK list for "..name);
	end
	return;
end

local function OnClick_NumberCard(self,button)
	-- On click event for number card in SK list
	if SetSK_Flag and SKC_UIMain["Details_border"]["Name"].Data ~= nil then
		local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
		local new_abs_pos = tonumber(self.Text:GetText());
		local sk_list = SKC_UIMain["sk_list_border"].Title.Text:GetText();
		-- Get initial position
		local prev_pos = SKC_DB[sk_list]:GetPos(name);
		-- Set new position
		local success = SKC_DB[sk_list]:SetByPos(name,new_abs_pos);
		if success then
			-- log
			WriteToLog( 
				LOG_OPTIONS["Event Type"].Options.ManEdit,
				name,
				"Set SK",
				"",
				sk_list,
				"",
				prev_pos,
				SKC_DB[sk_list]:GetPos(name),
				"",
				""
			);
			SKC_Main:Print("IMPORTANT","Set SK position of "..name.." to "..SKC_DB[sk_list]:GetPos(name));
			-- send SK data to all players
			SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
			-- Refresh SK List
			SKC_Main:UpdateSKUI();
		else
			SKC_Main:Print("ERROR","Set SK on "..name.." rejected");
		end
		SetSK_Flag = false;
	end
	return;
end

local function OnMouseDown_ShowItemTooltip(self, button)
	--[[
		function ChatFrame_OnHyperlinkShow(chatFrame, link, text, button)
			SetItemRef(link, text, button, chatFrame);
		end
		https://wowwiki.fandom.com/wiki/API_ChatFrame_OnHyperlinkShow
		https://wowwiki.fandom.com/wiki/API_strfind

		chatFrame 
			table (Frame) - ChatFrame in which the link was clicked.
		link 
			String - The link component of the clicked hyperlink. (e.g. "item:6948:0:0:0...")
		text 
			String - The label component of the clicked hyperlink. (e.g. "[Hearthstone]")
		button 
			String - Button clicking the hyperlink button. (e.g. "LeftButton")
		
		lootLink ex:
			|cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r
		itemString ex:
			item:3299::::::::20:257::::::
		itemLabel ex:
			[Fractured Canine]
	--]]
	local lootLink = SKC_DB.LootManager:GetCurrentLootLink();
	local itemString = string.match(lootLink,"item[%-?%d:]+");
	local itemLabel = string.match(lootLink,"|h.+|h");
	SetItemRef(itemString, itemLabel, button, SKC_LootGUI);
	return;
end

local function SetSKItem()
	-- https://wow.gamepedia.com/ItemMixin
	-- local itemID = 19395; -- Rejuv
	local lootLink = SKC_DB.LootManager:GetCurrentLootLink();
	local item = Item:CreateFromItemLink(lootLink)
	item:ContinueOnItemLoad(function()
		-- item:GetlootLink();
		local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(lootLink);
		-- Set texture icon and link
		SKC_LootGUI.ItemTexture:SetTexture(texture);
		SKC_LootGUI.Title.Text:SetText(lootLink);
		SKC_LootGUI.Title:SetWidth(SKC_LootGUI.Title.Text:GetStringWidth()+35);   
	end)
end

local function InitTimerBarValue()
	SKC_LootGUI.TimerBar:SetValue(0);
	SKC_LootGUI.TimerBar.Text:SetText(LOOT_DECISION.OPTIONS.MAX_DECISION_TIME);
end

local function TimerBarHandler()
	local time_elapsed = SKC_LootGUI.TimerBar:GetValue() + LOOT_DECISION.OPTIONS.TIME_STEP;

	-- updated timer bar
	SKC_LootGUI.TimerBar:SetValue(time_elapsed);
	SKC_LootGUI.TimerBar.Text:SetText(LOOT_DECISION.OPTIONS.MAX_DECISION_TIME - time_elapsed);

	if time_elapsed >= LOOT_DECISION.OPTIONS.MAX_DECISION_TIME then
		-- out of time
		-- send loot response
		SKC_Main:Print("WARN","Time expired. You PASS on "..SKC_DB.LootManager:GetCurrentLootLink());
		LootTimer:Cancel();
		SKC_DB.LootManager:SendLootDecision(LOOT_DECISION.PASS);
		SKC_Main:HideLootDecisionGUI();
	end

	return;
end

local function StartLootTimer()
	InitTimerBarValue();
	if LootTimer ~= nil and not LootTimer:IsCancelled() then LootTimer:Cancel() end
	-- start new timer
	LootTimer = C_Timer.NewTicker(LOOT_DECISION.OPTIONS.TIME_STEP, TimerBarHandler, LOOT_DECISION.OPTIONS.MAX_DECISION_TIME/LOOT_DECISION.OPTIONS.TIME_STEP);
	return;
end

local function OnClick_PASS(self,button)
	if self:IsEnabled() then
		LootTimer:Cancel();
		SKC_DB.LootManager:SendLootDecision(LOOT_DECISION.PASS);
		SKC_Main:HideLootDecisionGUI();
	end
	return;
end

local function OnClick_SK(self,button)
	if self:IsEnabled() then
		LootTimer:Cancel();
		SKC_DB.LootManager:SendLootDecision(LOOT_DECISION.SK);
		SKC_Main:HideLootDecisionGUI();
	end
	return;
end

local function OnClick_ROLL(self,button)
	if self:IsEnabled() then
		LootTimer:Cancel();
		SKC_DB.LootManager:SendLootDecision(LOOT_DECISION.ROLL);
		SKC_Main:HideLootDecisionGUI();
	end
	return;
end

local function CreateUICSV(name,import_btn)
	SKC_UICSV[name] = CreateFrame("Frame",name,UIParent,"UIPanelDialogTemplate");
	SKC_UICSV[name]:SetSize(UI_DIMENSIONS.CSV_WIDTH,UI_DIMENSIONS.CSV_HEIGHT);
	SKC_UICSV[name]:SetPoint("CENTER");
	SKC_UICSV[name]:SetMovable(true);
	SKC_UICSV[name]:EnableMouse(true);
	SKC_UICSV[name]:RegisterForDrag("LeftButton");
	SKC_UICSV[name]:SetScript("OnDragStart", SKC_UICSV[name].StartMoving);
	SKC_UICSV[name]:SetScript("OnDragStop", SKC_UICSV[name].StopMovingOrSizing);

	-- Add title
	SKC_UICSV[name].Title:SetPoint("LEFT", name.."TitleBG", "LEFT", 6, 0);
	SKC_UICSV[name].Title:SetText(name);

	-- Add edit box
	SKC_UICSV[name].SF = CreateFrame("ScrollFrame", nil, SKC_UICSV[name], "UIPanelScrollFrameTemplate");
	SKC_UICSV[name].SF:SetSize(UI_DIMENSIONS.CSV_EB_WIDTH,UI_DIMENSIONS.CSV_EB_HEIGHT);
	SKC_UICSV[name].SF:SetPoint("TOPLEFT",SKC_UICSV[name],"TOPLEFT",20,-40)
	SKC_UICSV[name].EditBox = CreateFrame("EditBox", nil, SKC_UICSV[name].SF)
	SKC_UICSV[name].EditBox:SetMultiLine(true)
	SKC_UICSV[name].EditBox:SetFontObject(ChatFontNormal)
	SKC_UICSV[name].EditBox:SetSize(UI_DIMENSIONS.CSV_EB_WIDTH,1000)
	SKC_UICSV[name].SF:SetScrollChild(SKC_UICSV[name].EditBox)

	-- Add import button
	if import_btn then
		SKC_UICSV[name].ImportBtn = CreateFrame("Button", nil, SKC_UICSV[name], "GameMenuButtonTemplate");
		SKC_UICSV[name].ImportBtn:SetPoint("BOTTOM",SKC_UICSV[name],"BOTTOM",0,15);
		SKC_UICSV[name].ImportBtn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
		SKC_UICSV[name].ImportBtn:SetText("Import");
		SKC_UICSV[name].ImportBtn:SetNormalFontObject("GameFontNormal");
		SKC_UICSV[name].ImportBtn:SetHighlightFontObject("GameFontHighlight");
	end

	-- set framel level and hide
	SKC_UICSV[name]:SetFrameLevel(4);
	SKC_UICSV[name]:Hide();

	return SKC_UICSV[name];
end

local function GetLootIdx(lootName)
	local lootIdx = nil;
	for idx,tmp in ipairs(pending_loot) do
		if tmp.lootName == lootName then return idx end
	end
	if lootIdx == nil then SKC_Main:Print("ERROR",lootName.." not found in pending list") end
	return nil;
end

local function LoginSyncCheckTickerActive()
	-- returns true of login sync check is still active (or hasn't started yet)
	return(event_states.LoginSyncCheckTicker == nil or not event_states.LoginSyncCheckTicker:IsCancelled());
end

local function SyncPushRead(msg,sender)
	-- Write data to tmp_sync_var first, then given datbase
	if not CheckAddonLoaded() then return end -- reject if addon not loaded yet
	if LoginSyncCheckTickerActive() then return end -- reject if still waiting for login sync
	-- parse first part of message
	local part, db_name, msg_rem = strsplit(",",msg,3);
	if db_name ~= "GuildData" and not CheckAddonVerMatch() then
		-- reject any out of date database that isn't GuildData
		if COMM_VERBOSE and part == "INIT" then 
			SKC_Main:Print("ERROR","Rejected SyncPushRead, addon version does not match GL version from "..sender);
		end
		return;
	end
	if part == "INIT" then
		-- first check to ensure that incoming data is actually fresher
		-- get self edit time stamps
		local my_edit_ts_raid = SKC_DB[db_name].edit_ts_raid;
		local my_edit_ts_generic = SKC_DB[db_name].edit_ts_generic;
		-- parse out timestamps
		local their_edit_ts_generic, their_edit_ts_raid, _ = strsplit(",",msg_rem,3);
		their_edit_ts_generic = NumOut(their_edit_ts_generic);
		their_edit_ts_raid = NumOut(their_edit_ts_raid);
		if their_edit_ts_generic == nil or their_edit_ts_raid == nil then
			if COMM_VERBOSE then SKC_Main:Print("ERROR","Reject SyncPushRead, got nil timestamp(s) for "..db_name.." from "..sender) end
			-- blacklist
			blacklist[sender] = true;
			return;
		elseif (my_edit_ts_raid > their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic > their_edit_ts_generic) ) then
			-- I have newer RAID data
			-- OR I have the same RAID data but newer generic data
			-- --> I have fresher data
			if COMM_VERBOSE then SKC_Main:Print("ERROR","Reject SyncPushRead, incoming stale data for "..db_name.." from "..sender) end
			-- blacklist
			blacklist[sender] = true;
			return;
		end
		-- cleanse blacklist
		blacklist[sender] = nil;
		-- data is fresh, begin read
		PrintSyncMsgStart(db_name,false,sender);
	elseif blacklist[sender] then
		-- check if already blacklisted
		if COMM_VERBOSE and part == "END" then SKC_Main:Print("ERROR","Reject SyncPushRead,"..sender.." was blacklisted for "..db_name) end
		return;
	end
	-- If last part, deep copy to actual database
	if part == "END" then
		SKC_DB[db_name] = DeepCopy(tmp_sync_var)
	end
	-- Check if master looter, loot officer, and in active raid
	if SKC_Main:isML() and SKC_Main:isLO() and CheckActive() then
		-- reject read for MSK and TSK
		if part == "MSK" or part == "TSK" then
			if COMM_VERBOSE and part == "INIT" then SKC_Main:Print("ERROR","Reject SyncPushRead from "..sender.." because I HAVE THE POWER") end
			return;
		end
	end
	-- Read in data
	if db_name == "MSK" or db_name == "TSK" then
		if part == "INIT" then
			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
			ts_generic = NumOut(ts_generic);
			ts_raid = NumOut(ts_raid);
			tmp_sync_var = SK_List:new(nil);
			tmp_sync_var.edit_ts_generic = ts_generic;
			tmp_sync_var.edit_ts_raid = ts_raid;
		elseif part == "META" then
			local top, bottom = strsplit(",",msg_rem,2);
			tmp_sync_var.top = StrOut(top);
			tmp_sync_var.bottom = StrOut(bottom);
		elseif part == "DATA" then
			local name, above, below, abs_pos, live = strsplit(",",msg_rem,7);
			name = StrOut(name);
			tmp_sync_var.list[name] = SK_Node:new(nil,nil,nil);
			tmp_sync_var.list[name].above = StrOut(above);
			tmp_sync_var.list[name].below = StrOut(below);
			tmp_sync_var.list[name].abs_pos = NumOut(abs_pos);
			tmp_sync_var.list[name].live = BoolOut(live);		
		end
	elseif db_name == "GuildData" then
		if part == "INIT" then
			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
			ts_generic = NumOut(ts_generic);
			ts_raid = NumOut(ts_raid);
			tmp_sync_var = GuildData:new(nil);
			tmp_sync_var.edit_ts_generic = ts_generic;
			tmp_sync_var.edit_ts_raid = ts_raid;
		elseif part == "META" then
			-- nothing to do
		elseif part == "DATA" then
			local name, class, spec, rr, gr, status, activity, last_live_time = strsplit(",",msg_rem,8);
			name = StrOut(name);
			class = StrOut(class);
			tmp_sync_var.data[name] = CharacterData:new(nil,name,class);
			tmp_sync_var.data[name].Spec = NumOut(spec);
			tmp_sync_var.data[name]["Raid Role"] = NumOut(rr);
			tmp_sync_var.data[name]["Guild Role"] = NumOut(gr);
			tmp_sync_var.data[name].Status = NumOut(status);
			tmp_sync_var.data[name].Activity = NumOut(activity);
			tmp_sync_var.data[name].last_live_time = NumOut(last_live_time);
		end
	elseif db_name == "LootPrio" then
		if part == "INIT" then
			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
			ts_generic = NumOut(ts_generic);
			ts_raid = NumOut(ts_raid);
			tmp_sync_var = LootPrio:new(nil);
			tmp_sync_var.edit_ts_generic = ts_generic;
			tmp_sync_var.edit_ts_raid = ts_raid;
		elseif part == "META" then
			local item, sk_list, res, de, open_roll = strsplit(",",msg_rem,5);
			item = StrOut(item);
			tmp_sync_var.items[item] = Prio:new(nil);
			tmp_sync_var.items[item].sk_list = StrOut(sk_list);
			tmp_sync_var.items[item].reserved = BoolOut(res);
			tmp_sync_var.items[item].DE = BoolOut(de);
			tmp_sync_var.items[item].open_roll = BoolOut(open_roll);
		elseif part == "DATA" then
			local item, msg_rem = strsplit(",",msg_rem,2);
			item = StrOut(item);
			local plvl = nil;
			for idx,_ in ipairs(CLASS_SPEC_MAP) do
				plvl, msg_rem = strsplit(",",msg_rem,2);
				tmp_sync_var.items[item].prio[idx] = NumOut(plvl);
			end
		end
	elseif db_name == "Bench" or db_name == "ActiveRaids" or db_name == "LootOfficers" then
		if part == "INIT" then
			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
			ts_generic = NumOut(ts_generic);
			ts_raid = NumOut(ts_raid);
			tmp_sync_var = SimpleMap:new(nil);
			tmp_sync_var.edit_ts_generic = ts_generic;
			tmp_sync_var.edit_ts_raid = ts_raid;
		elseif part == "DATA" then
			while msg_rem ~= nil do
				val, msg_rem = strsplit(",",msg_rem,2);
				tmp_sync_var.data[val] = true;
			end
		elseif part == "END" then
			if db_name == "Bench" then 
				UpdateLiveList();
			elseif db_name == "LootOfficers" then 
				UpdateDetailsButtons();
			end
		end
	end
	if part == "END" then
		PrintSyncMsgEnd(db_name,false);
		SKC_Main:PopulateData();
	end
	return;
end

local function LoginSyncCheckAnswered(savior)
	-- cancels the LoginSyncCheckTicker
	if COMM_VERBOSE and LoginSyncCheckTickerActive() then
		SKC_Main:Print("IMPORTANT","Login Sync Check Answered by "..savior.."!");
	end
	if event_states.LoginSyncCheckTicker ~= nil then event_states.LoginSyncCheckTicker:Cancel() end
	-- update status
	SKC_Main:RefreshStatus();
	return;
end

function SKC:AddonMessageRead(data,channel,sender)
	sender = StripRealmName(sender);
	-- TODO, deserialize data
	if prefix == CHANNELS.LOGIN_SYNC_CHECK then
		--[[ 
			Send (LoginSyncCheckSend): Upon login character requests sync for each database
			Read (LoginSyncCheckRead): Arbitrate based on timestamp to push or pull database
		--]]
		SKC_Main:Print("WARN","GOT SOMETHING!")
		LoginSyncCheckRead(msg,sender);
	elseif prefix == CHANNELS.LOGIN_SYNC_PUSH then
		--[[ 
			Send (LoginSyncCheckRead -> SyncPushSend - LOGIN_SYNC_PUSH): Push given database to target player
			Read (SyncPushRead): Write given database to player (only accept first push)
		--]]
		local part, db_name, msg_rem = strsplit(",",msg,3);
		if sender ~= UnitName("player") and (event_states.LoginSyncPartner == nil or event_states.LoginSyncPartner == sender) then
			event_states.LoginSyncPartner = sender;
			LoginSyncCheckAnswered(sender);
			SyncPushRead(msg,sender);
		end
	elseif prefix == CHANNELS.LOGIN_SYNC_PUSH_RQST then
		--[[ 
			Send (LoginSyncCheckRead): Request a push for given database from target player
			Read (SyncPushSend - SYNC_PUSH): Respond with push for given database
		--]]
		LoginSyncCheckAnswered(sender);
		-- send data out to entire guild (if one person needed it, everyone needs it)
		SyncPushSend(msg,CHANNELS.SYNC_PUSH,"GUILD",nil);
	elseif prefix == CHANNELS.SYNC_PUSH then
		--[[ 
			Send (SyncPushSend - SYNC_PUSH): Push given database to target player
			Read (SyncPushRead): Write given datbase to player (accepts as many as possible)
		--]]
		-- Reject if message was from self
		if sender ~= UnitName("player") then
			SyncPushRead(msg,sender);
		end
	elseif prefix == CHANNELS.LOOT then
		--[[ 
			Send (SendLootMsgs): Send loot items for which each player is elligible to make a decision on
			Read (ReadLootMsg): Initiate loot decision GUI for player
		--]]
		-- read loot message and save to LootManager
		if msg ~= "BLANK" then
			SKC_DB.LootManager:ReadLootMsg(msg,sender);
		end
	elseif prefix == CHANNELS.LOOT_DECISION then
		--[[ 
			Send (SendLootDecision): Send loot decision to ML
			Read (ReadLootDecision): Determine loot winner
		--]]
		-- read message, determine winner, award loot, start next loot decision
		SKC_DB.LootManager:ReadLootDecision(msg,sender);
	elseif prefix == CHANNELS.LOOT_DECISION_PRINT then
		if msg ~= nil then
			SKC_Main:Print("NORMAL",msg);
		end
	elseif prefix == CHANNELS.LOOT_OUTCOME then
		if msg ~= nil then
			SKC_Main:Print("IMPORTANT",msg);
		end
	end
	return;
end

local function SaveLoot()
	-- Scans items / characters and stores loot in LootManager
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	-- Check that player is ML
	if not SKC_Main:isML() then return end

	if LOOT_SAFE_MODE then 
		SKC_Main:Print("WARN","Loot Safe Mode");
		return;
	end

	-- Update SKC Active flag
	SKC_Main:RefreshStatus();

	if not CheckActive() then
		SKC_Main:Print("WARN","SKC not active. Skipping loot distribution.");
		return;
	end

	-- Check if loot decision already pending
	if SKC_DB.LootManager:LootDecisionPending() then return end

	-- Check if sync in progress
	if CheckIfReadInProgress() or CheckIfPushInProgress() then
		SKC_Main:Print("IMPORTANT","Synchronization in progress. Loot distribution will start soon...");
	end
	
	-- Reset LootManager
	SKC_DB.LootManager:Reset();
	
	-- Scan all items and save each item / elligible player
	if LOOT_VERBOSE then SKC_Main:Print("IMPORTANT","Starting Loot Distribution") end
	local loot_cnt = 1;
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		-- local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot);
		if lootName ~= nil then
			-- Only perform SK for items if they are found in loot prio
			if SKC_DB.GLP.loot_prio:Exists(lootName) then
				-- Valid item
				local lootLink = GetLootSlotLink(i_loot);
				-- Store item
				local loot_idx = SKC_DB.LootManager:AddLoot(lootName,lootLink);
				-- Alert raid of new item
				local msg = "["..loot_cnt.."] "..lootLink;
				SendChatMessage(msg,"RAID_WARNING");
				loot_cnt = loot_cnt + 1;
				-- Scan all possible characters to determine elligible
				local any_elligible = false;
				for i_char = 1,40 do
					local char_name = GetMasterLootCandidate(i_loot,i_char);
					if char_name ~= nil then
						if SKC_DB.GLP.loot_prio:IsElligible(lootName,char_name) then 
							SKC_DB.LootManager:AddCharacter(char_name,loot_idx);
							any_elligible = true;
						end
					end
				end
				-- check that at least one character was elligible
				if not any_elligible then
					if LOOT_VERBOSE then SKC_Main:Print("WARN","No elligible characters in raid. Giving directly to ML.") end
					-- give directly to ML
					SKC_DB.LootManager:GiveLootToML(lootName,lootLink);
					SKC_DB.LootManager:MarkLootAwarded(lootName);
					WriteToLog( 
						LOG_OPTIONS["Event Type"].Options.NE,
						"",
						"ML",
						lootName,
						"",
						"",
						"",
						"",
						"",
						UnitName("player")
					);
				end
			else
				if LOOT_VERBOSE then SKC_Main:Print("WARN","Item not in Loot Prio. Giving directly to ML.") end
				-- give directly to ML
				SKC_DB.LootManager:GiveLootToML(lootName,GetLootSlotLink(i_loot));
				SKC_DB.LootManager:MarkLootAwarded(lootName);
				WriteToLog( 
					LOG_OPTIONS["Event Type"].Options.AL,
					"",
					"ML",
					lootName,
					"",
					"",
					"",
					"",
					"",
					UnitName("player")
				);
			end
		end
	end

	-- Kick off loot decison
	SKC_DB.LootManager:KickOff();
	return;
end

local function CreateUIBorder(title,width,height)
	-- Create Border
	local border_key = title.."_border";
	SKC_UIMain[border_key] = CreateFrame("Frame",border_key,SKC_UIMain,"TranslucentFrameTemplate");
	SKC_UIMain[border_key]:SetSize(width,height);
	SKC_UIMain[border_key].Bg:SetAlpha(0.0);
	-- Create Title
	local title_key = "title";
	SKC_UIMain[border_key][title_key] = CreateFrame("Frame",title_key,SKC_UIMain[border_key],"TranslucentFrameTemplate");
	SKC_UIMain[border_key][title_key]:SetSize(UI_DIMENSIONS.SK_TAB_TITLE_CARD_WIDTH,UI_DIMENSIONS.SK_TAB_TITLE_CARD_HEIGHT);
	SKC_UIMain[border_key][title_key]:SetPoint("BOTTOM",SKC_UIMain[border_key],"TOP",0,-20);
	SKC_UIMain[border_key][title_key].Text = SKC_UIMain[border_key][title_key]:CreateFontString(nil,"ARTWORK")
	SKC_UIMain[border_key][title_key].Text:SetFontObject("GameFontNormal")
	SKC_UIMain[border_key][title_key].Text:SetPoint("CENTER",0,0)
	SKC_UIMain[border_key][title_key].Text:SetText(title)

	return border_key
end

local function OnClick_SKListCycle()
	-- cycle SK list when click title
	if SetSK_Flag then return end -- reject cycle if SK is being set
	-- cycle through SK lists
	local sk_list = SKC_UIMain["sk_list_border"].Title.Text:GetText();
	if sk_list == "MSK" then
		SKC_UIMain["sk_list_border"].Title.Text:SetText("TSK");
	else
		SKC_UIMain["sk_list_border"].Title.Text:SetText("MSK");
	end
	-- populate data
	SKC_Main:PopulateData();
	-- enable / disable details buttons
	UpdateDetailsButtons(true);
end
--------------------------------------
-- SHARED FUNCTIONS
--------------------------------------
function SKC_Main:ToggleUIMain(force_show)
	if GUI_VERBOSE then SKC_Main:Print("NORMAL","ToggleUIMain()") end
	-- create (does nothing if already created)
	SKC_Main:CreateUIMain();
	-- Refresh Data
	SKC_Main:PopulateData();
	-- make shown
	SKC_UIMain:SetShown(force_show or not SKC_UIMain:IsShown());
end

function SKC_Main:Enable(enable_flag)
	-- primary manual control over SKC
	-- only can be changed my ML
	if not SKC_Main:isML() then return end
	SKC_DB.SKC_Enable = enable_flag;
	SKC_Main:RefreshStatus();
	return;
end

function SKC_Main:ResetData()
	-- Manually resets data
	-- First hide SK cards
	SKC_Main:HideSKCards();
	-- Reset data
	HARD_DB_RESET = true;
	OnAddonLoad("SKC");
	HARD_DB_RESET = false;
	-- re populate guild data
	InitGuildSync = true;
	SyncGuildData();
	-- Refresh Data
	SKC_Main:PopulateData();
end

function SKC_Main:GetThemeColor(type)
	local c = THEME.PRINT[type];
	return c.r, c.g, c.b, c.hex;
end

function SKC_Main:Print(type,...)
    local hex = select(4, SKC_Main:GetThemeColor(type));
	local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

function SKC_Main:isML()
	-- Check if current player is master looter
	return(UnitName("player") == ML_OVRD or IsMasterLooter());
end

function SKC_Main:isGL()
	-- Check if current player is guild leader
	return(UnitName("player") == GL_OVRD or IsGuildLeader());
end

function SKC_Main:SimpleListShow(list_name)
	-- shows a simple list
	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
		SKC_Main:Print("ERROR","Input list is not valid");
		return;
	end
	DEFAULT_CHAT_FRAME:AddMessage(" ");
	SKC_Main:Print("IMPORTANT",list_name..":");
	SKC_DB[list_name]:Show();
	DEFAULT_CHAT_FRAME:AddMessage(" ");
	return;
end

function SKC_Main:SimpleListAdd(list_name,element)
	-- adds element to a simple list
	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
		SKC_Main:Print("ERROR","Input list is not valid");
		return;
	end
	-- check for special conditions
	if element == nil then
		SKC_Main:Print("ERROR","Input cannot be nil");
		return;
	end
	if (list_name == "Bench" or list_name == "LootOfficers") and not SKC_DB.GuildData:Exists(element) then
		SKC_Main:Print("ERROR",element.." is not a valid guild member");
		return;
	end
	if list_name == "ActiveRaids" and RAID_NAME_MAP[element] == nil then
		SKC_Main:Print("ERROR",element.." is not a valid raid acronym");
		SKC_Main:Print("WARN","Valid raid acronyms are:");
		for raid_acro_tmp,raid_name_full in pairs(RAID_NAME_MAP) do
			SKC_Main:Print("WARN",raid_acro_tmp.." ("..raid_name_full..")");
		end
		return;
	end
	-- add to list
	local success = SKC_DB[list_name]:Add(element);
	if success then
		SKC_Main:Print("NORMAL",element.." added to "..list_name);
		-- sync / update GUI
		if list_name == "Bench" then 
			UpdateLiveList();
		elseif list_name == "LootOfficers" then 
			UpdateDetailsButtons();
		end
		SyncPushSend(list_name,CHANNELS.SYNC_PUSH,"GUILD",nil);
		SKC_Main:SimpleListShow(list_name);
		SKC_Main:RefreshStatus();
	end
	return;
end

function SKC_Main:SimpleListRemove(list_name,element)
	-- remove element from a simple list
	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
		SKC_Main:Print("ERROR","Input list is not valid");
		return;
	end
	-- add to list
	local success = SKC_DB[list_name]:Remove(element);
	if success then
		SKC_Main:Print("NORMAL",element.." removed from "..list_name);
		-- sync
		-- sync / update GUI
		if list_name == "Bench" then 
			UpdateLiveList();
		elseif list_name == "LootOfficers" then 
			UpdateDetailsButtons();
		end
		SyncPushSend(list_name,CHANNELS.SYNC_PUSH,"GUILD",nil);
		SKC_Main:SimpleListShow(list_name);
		SKC_Main:RefreshStatus();
	end
	return;
end

function SKC_Main:SimpleListClear(list_name)
	-- clears a simple list
	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
		SKC_Main:Print("ERROR","Input list is not valid");
		return;
	end
	-- add to list
	local success = SKC_DB[list_name]:Clear();
	if success then
		SKC_Main:Print("NORMAL",list_name.." cleared");
		-- sync
		if list_name == "Bench" then 
			UpdateLiveList();
		elseif list_name == "LootOfficers" then 
			UpdateDetailsButtons();
		end
		SyncPushSend(list_name,CHANNELS.SYNC_PUSH,"GUILD",nil);
		SKC_Main:SimpleListShow(list_name);
		SKC_Main:RefreshStatus();
	end
	return;
end

function SKC_Main:PrintVersion()
	if SKC_DB ~= nil and SKC_DB.AddonVersion ~= nil then
		SKC_Main:Print("NORMAL",SKC_DB.AddonVersion);
	else
		SKC_Main:Print("ERROR","Addon version missing");
	end
	return;
end

function SKC_Main:ExportLog()
	local name = "Log Export";
	-- instantiate frame
	local menu = SKC_UICSV[name] or CreateUICSV(name,false);
	menu:SetShown(true);
	-- Add log data
	local log_data = "";
	for idx1,log_entry in ipairs(SKC_DB.RaidLog) do
		for idx2,data in ipairs(log_entry) do
			log_data = log_data..tostring(data);
			log_data = log_data..",";
		end
		log_data = log_data.."\n";
	end
	SKC_UICSV[name].EditBox:SetText(log_data);
	SKC_UICSV[name].EditBox:HighlightText();
end

function SKC_Main:ExportSK()
	local name = "SK List Export";
	-- instantiate frame
	local menu = SKC_UICSV[name] or CreateUICSV(name,false);
	menu:SetShown(true);
	-- get sk list data
	local msk = SKC_DB.MSK:ReturnList();
	local tsk = SKC_DB.TSK:ReturnList();
	if #msk ~= #tsk then
		SKC_Main:Print("ERROR","MSK and TSK lists are different lengths. That's bad.");
		return;
	end
	-- construct data
	local data = "MSK,TSK,\n";
	for i = 1,#msk do
		data = data..msk[i]..","..tsk[i].."\n";
	end
	-- add data to export
	SKC_UICSV[name].EditBox:SetText(data);
	SKC_UICSV[name].EditBox:HighlightText();
end

local function OnClick_ImportLootPrio()
	-- imports loot prio CSV to database
	-- reset database
	SKC_DB.LootPrio = LootPrio:new(nil);
	-- get text
	local name = "Loot Priority Import";
	local txt = SKC_UICSV[name].EditBox:GetText();
	local line = nil;
	local txt_rem = txt;
	-- check if first row is header
	line = strsplit(",",txt_rem,2);
	if line == "Item" then
		-- header --> skip
		line, txt_rem = strsplit("\n",txt_rem,2);
	end
	-- read data
	local valid = true;
	local line_count = 2; -- account for header
	while txt_rem ~= nil do
		line, txt_rem = strsplit("\n",txt_rem,2);
		local item, sk_list, res, de, open_roll, prios_txt = strsplit(",",line,6);
		-- clean input data
		item = StrOut(item);
		sk_list = StrOut(sk_list);
		-- check input data validity
		if item == nil then
			valid = false;
			SKC_Main:Print("ERROR","Invalid Item (line: "..line_count..")");
			break;
		elseif not (sk_list == "MSK" or sk_list == "TSK") then
			valid = false;
			SKC_Main:Print("ERROR","Invalid SK List for "..item.." (line: "..line_count..")");
			break;
		elseif not (res == "TRUE" or res == "FALSE") then
			valid = false;
			SKC_Main:Print("ERROR","Invalid Reserved for "..item.." (line: "..line_count..")");
			break;
		elseif not (de == "TRUE" or de == "FALSE") then
			valid = false;
			SKC_Main:Print("ERROR","Invalid Disenchant for "..item.." (line: "..line_count..")");
			break;
		elseif not (open_roll == "TRUE" or open_roll == "FALSE") then
			valid = false;
			SKC_Main:Print("ERROR","Invalid Open Roll for "..item.." (line: "..line_count..")");
			break;
		end
		-- write meta data for item
		SKC_DB.LootPrio.items[item] = Prio:new(nil);
		SKC_DB.LootPrio.items[item].sk_list = sk_list;
		SKC_DB.LootPrio.items[item].reserved = BoolOut(res);
		SKC_DB.LootPrio.items[item].DE = BoolOut(de);
		SKC_DB.LootPrio.items[item].open_roll = BoolOut(open_roll);
		-- read prios
		local spec_class_cnt = 0;
		while prios_txt ~= nil do
			spec_class_cnt = spec_class_cnt + 1;
			valid = spec_class_cnt <= 22;
			if not valid then
				SKC_Main:Print("ERROR","Too many Class/Spec combinations");
				break;
			end
			-- split off next value
			val, prios_txt = strsplit(",",prios_txt,2);
			valid = false;
			if val == "" then
				-- Inelligible for loot --> permanent pass prio tier
				val = PRIO_TIERS.PASS;
				valid = true;
			elseif val == "OS" then
				val = PRIO_TIERS.SK.Main.OS;
				valid = true;
			else
				val = NumOut(val);
				valid = (val ~= nil and (val >= 1) and (val <= 5));
			end 
			if not valid then
				SKC_Main:Print("ERROR","Invalid prio level for "..item.." and Class/Spec index "..spec_class_cnt);
				break;
			end
			-- write prio value
			SKC_DB.LootPrio.items[item].prio[spec_class_cnt] = val;
			-- increment spec class counter
		end
		-- check that all expected columns were scanned (1 past actual count)
		if (spec_class_cnt ~= 22) then
			valid = false;
			SKC_Main:Print("ERROR","Wrong number of Class/Spec combinations. Expected 22. Got "..spec_class_cnt);
			break;
		end
		if not valid then break end
		-- Check if item added was actually a tier armor set
		if TIER_ARMOR_SETS[item] ~= nil then
			local armor_set = item;
			-- scan through armor set and individually add each item
			for set_item_idx,set_item in ipairs(TIER_ARMOR_SETS[armor_set]) do
				SKC_DB.LootPrio.items[set_item] = DeepCopy(SKC_DB.LootPrio.items[armor_set]);
			end
			-- remove armor set itself from database
			SKC_DB.LootPrio.items[armor_set] = nil;
		end
		line_count = line_count + 1;
	end
	if not valid then
		SKC_DB.LootPrio = LootPrio:new(nil);
		return;
	end
	-- update edit timestamp
	local ts = time();
	SKC_DB.LootPrio.edit_ts_raid = ts;
	SKC_DB.LootPrio.edit_ts_generic = ts;
	SKC_Main:Print("NORMAL","Loot Priority Import Complete");
	SKC_Main:Print("NORMAL",SKC_DB.LootPrio:length().." items added");
	SKC_Main:RefreshStatus();
	-- push new loot prio to guild
	SyncPushSend("LootPrio",CHANNELS.SYNC_PUSH,"GUILD",nil);
	-- close import GUI
	SKC_UICSV[name]:Hide();
	return;
end

local function OnClick_ImportSKList(sk_list)
	-- imports SK list CSV into database
	-- get text
	local name = "SK List Import";
	local txt = SKC_UICSV[name].EditBox:GetText();
	-- check that every name in text is in GuildData
	local txt_rem = txt;
	local valid = true;
	local char_name = nil;
	local new_sk_list = {};
	local new_chars_map = {};
	while txt_rem ~= nil do
		char_name, txt_rem = strsplit("\n",txt_rem,2);
		if SKC_DB.GuildData:Exists(char_name) then
			new_sk_list[#new_sk_list + 1] = char_name;
			new_chars_map[char_name] = (new_chars_map[char_name] or 0) + 1;
		else
			-- character not in GuildData
			SKC_Main:Print("ERROR",char_name.." not in GuildData");
			valid = false;
		end
	end
	if not valid then
		SKC_Main:Print("ERROR","SK list not imported");
		return;
	end;
	-- check that every name in GuildData is in text
	valid = true;
	for guild_member,_ in pairs(SKC_DB.GuildData.data) do
		if new_chars_map[guild_member] == nil then
			-- guild member not in list
			SKC_Main:Print("ERROR",guild_member.." not in your SK list");
			valid = false;
		elseif new_chars_map[guild_member] == 1 then
			-- guild member is in list exactly once
		elseif new_chars_map[guild_member] > 1 then
			-- guild member is in list more than once
			SKC_Main:Print("ERROR",guild_member.." is in your SK list more than once");
			valid = false;
		else
			-- guild member not in list
			SKC_Main:Print("ERROR","DUNNO");
			valid = false;
		end
	end
	if not valid then
		SKC_Main:Print("ERROR","SK list not imported");
		return;
	end;
	-- reset database
	SKC_DB[sk_list] = SK_List:new(nil);
	-- write new database
	for idx,val in ipairs(new_sk_list) do
		SKC_DB[sk_list]:PushBack(val);
	end
	SKC_Main:Print("NORMAL",sk_list.." imported");
	-- Set GUI to given SK list
	SKC_UIMain["sk_list_border"].Title.Text:SetText(sk_list);
	-- Refresh data
	SKC_Main:PopulateData();
	-- push new sk list to guild
	SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
	SKC_UICSV[name]:Hide();
	return;
end

function SKC_Main:CSVImport(name,sk_list)
	-- error checking + bind function for import button
	-- confirm that addon loaded and ui created
	if LoginSyncCheckTickerActive() then
		SKC_Main:Print("ERROR","Please wait for login sync to complete");
		return;
	end
	if not CheckAddonLoaded() then 
		SKC_Main:Print("ERROR","Please wait for addon data to fully load");
		return;
	end
	if CheckIfReadInProgress() then
		SKC_Main:Print("ERROR","Please wait for read to complete");
		return;
	end
	if SKC_UIMain == nil then
		-- create GUI
		SKC_Main:CreateUIMain();
	end
	if name == "Loot Priority Import" then
		-- instantiate frame
		local menu = SKC_UICSV[name] or CreateUICSV(name,true);
		menu:SetShown(true);
		SKC_UICSV[name].ImportBtn:SetScript("OnMouseDown",OnClick_ImportLootPrio);
	elseif name == "SK List Import" then
		if sk_list ~= "MSK" and sk_list ~= "TSK" then
			if sk_list == nil then
				SKC_Main:Print("ERROR","No SK list name given")
			else
				SKC_Main:Print("ERROR",sk_list.." is not a list name");
			end
			return;
		end
		-- instantiate frame
		local menu = SKC_UICSV[name] or CreateUICSV(name,true);
		menu:SetShown(true);
		SKC_UICSV[name].ImportBtn:SetScript("OnMouseDown",function() OnClick_ImportSKList(sk_list) end);
	end
	return;
end

function SKC_Main:HideLootDecisionGUI()
	-- hide loot decision gui
	-- if not yet created, do nothing
	if SKC_LootGUI == nil then return end
	SKC_LootGUI.ItemClickBox:SetScript("OnMouseDown",nil);
	SKC_LootGUI.ItemClickBox:EnableMouse(false);
	SKC_LootGUI:Hide();
	return;
end

function SKC_Main:DisplayLootDecisionGUI(open_roll,sk_list)
	-- ensure SKC_LootGUI is created
	if SKC_LootGUI == nil then SKC_Main:CreateLootGUI() end
	-- Enable correct buttons
	SKC_LootGUI.loot_decision_pass_btn:Enable(); -- OnClick_PASS
	SKC_LootGUI.loot_decision_sk_btn:Enable(); -- OnClick_SK
	SKC_LootGUI.loot_decision_sk_btn:SetText(sk_list);
	if open_roll then
		SKC_LootGUI.loot_decision_roll_btn:Enable(); -- OnClick_ROLL
	else
		SKC_LootGUI.loot_decision_roll_btn:Disable();
	end
	-- Set item (in GUI)
	SetSKItem();
	-- Initiate timer
	StartLootTimer();
	-- enable mouse
	SKC_LootGUI.ItemClickBox:EnableMouse(true);
	-- set link
	SKC_LootGUI.ItemClickBox:SetScript("OnMouseDown",OnMouseDown_ShowItemTooltip);
	-- show
	SKC_LootGUI:Show();
	return;
end

function SKC_Main:CreateLootGUI()
	-- Creates the GUI object for making a loot decision
	if SKC_LootGUI ~= nil then return end

	-- Create Frame
	SKC_LootGUI = CreateFrame("Frame",border_key,UIParent,"TranslucentFrameTemplate");
	SKC_LootGUI:SetSize(UI_DIMENSIONS.DECISION_WIDTH,UI_DIMENSIONS.DECISION_HEIGHT);
	SKC_LootGUI:SetPoint("TOP",UIParent,"CENTER",0,-130);
	SKC_LootGUI:SetAlpha(0.8);
	SKC_LootGUI:SetFrameLevel(6);

	-- Make it movable
	SKC_LootGUI:SetMovable(true);
	SKC_LootGUI:EnableMouse(true);
	SKC_LootGUI:RegisterForDrag("LeftButton");
	SKC_LootGUI:SetScript("OnDragStart", SKC_LootGUI.StartMoving);
	SKC_LootGUI:SetScript("OnDragStop", SKC_LootGUI.StopMovingOrSizing);

	-- Create Title
	SKC_LootGUI.Title = CreateFrame("Frame",title_key,SKC_LootGUI,"TranslucentFrameTemplate");
	SKC_LootGUI.Title:SetSize(UI_DIMENSIONS.LOOT_GUI_TITLE_CARD_WIDTH,UI_DIMENSIONS.LOOT_GUI_TITLE_CARD_HEIGHT);
	SKC_LootGUI.Title:SetPoint("BOTTOM",SKC_LootGUI,"TOP",0,-20);
	SKC_LootGUI.Title.Text = SKC_LootGUI.Title:CreateFontString(nil,"ARTWORK");
	SKC_LootGUI.Title.Text:SetFontObject("GameFontNormal");
	SKC_LootGUI.Title.Text:SetPoint("CENTER",0,0);
	SKC_LootGUI.Title:SetHyperlinksEnabled(true)
	SKC_LootGUI.Title:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)

	-- set texture / hidden frame for button click
	local item_texture_y_offst = -23;
	SKC_LootGUI.ItemTexture = SKC_LootGUI:CreateTexture(nil, "ARTWORK");
	SKC_LootGUI.ItemTexture:SetSize(UI_DIMENSIONS.ITEM_WIDTH,UI_DIMENSIONS.ITEM_HEIGHT);
	SKC_LootGUI.ItemTexture:SetPoint("TOP",SKC_LootGUI,"TOP",0,item_texture_y_offst)
	SKC_LootGUI.ItemClickBox = CreateFrame("Frame", nil, SKC_UIMain);
	SKC_LootGUI.ItemClickBox:SetFrameLevel(7)
	SKC_LootGUI.ItemClickBox:SetSize(UI_DIMENSIONS.ITEM_WIDTH,UI_DIMENSIONS.ITEM_HEIGHT);
	SKC_LootGUI.ItemClickBox:SetPoint("CENTER",SKC_LootGUI.ItemTexture,"CENTER");
	-- set decision buttons
	-- SK
	local loot_btn_x_offst = 40;
	local loot_btn_y_offst = -7;
	SKC_LootGUI.loot_decision_sk_btn = CreateFrame("Button", nil, SKC_LootGUI, "GameMenuButtonTemplate");
	SKC_LootGUI.loot_decision_sk_btn:SetPoint("TOPRIGHT",SKC_LootGUI.ItemTexture,"BOTTOM",-loot_btn_x_offst,loot_btn_y_offst);
	SKC_LootGUI.loot_decision_sk_btn:SetSize(UI_DIMENSIONS.LOOT_BTN_WIDTH, UI_DIMENSIONS.LOOT_BTN_HEIGHT);
	SKC_LootGUI.loot_decision_sk_btn:SetText("SK");
	SKC_LootGUI.loot_decision_sk_btn:SetNormalFontObject("GameFontNormal");
	SKC_LootGUI.loot_decision_sk_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_LootGUI.loot_decision_sk_btn:SetScript("OnMouseDown",OnClick_SK);
	SKC_LootGUI.loot_decision_sk_btn:Disable();
	-- Roll 
	SKC_LootGUI.loot_decision_roll_btn = CreateFrame("Button", nil, SKC_LootGUI, "GameMenuButtonTemplate");
	SKC_LootGUI.loot_decision_roll_btn:SetPoint("TOP",SKC_LootGUI.ItemTexture,"BOTTOM",0,loot_btn_y_offst);
	SKC_LootGUI.loot_decision_roll_btn:SetSize(UI_DIMENSIONS.LOOT_BTN_WIDTH, UI_DIMENSIONS.LOOT_BTN_HEIGHT);
	SKC_LootGUI.loot_decision_roll_btn:SetText("Roll");
	SKC_LootGUI.loot_decision_roll_btn:SetNormalFontObject("GameFontNormal");
	SKC_LootGUI.loot_decision_roll_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_LootGUI.loot_decision_roll_btn:SetScript("OnMouseDown",OnClick_ROLL);
	SKC_LootGUI.loot_decision_roll_btn:Disable();
	-- Pass
	SKC_LootGUI.loot_decision_pass_btn = CreateFrame("Button", nil, SKC_LootGUI, "GameMenuButtonTemplate");
	SKC_LootGUI.loot_decision_pass_btn:SetPoint("TOPLEFT",SKC_LootGUI.ItemTexture,"BOTTOM",loot_btn_x_offst,loot_btn_y_offst);
	SKC_LootGUI.loot_decision_pass_btn:SetSize(UI_DIMENSIONS.LOOT_BTN_WIDTH, UI_DIMENSIONS.LOOT_BTN_HEIGHT);
	SKC_LootGUI.loot_decision_pass_btn:SetText("Pass");
	SKC_LootGUI.loot_decision_pass_btn:SetNormalFontObject("GameFontNormal");
	SKC_LootGUI.loot_decision_pass_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_LootGUI.loot_decision_pass_btn:SetScript("OnMouseDown",OnClick_PASS);
	SKC_LootGUI.loot_decision_pass_btn:Disable();
	-- timer bar
	local timer_bar_y_offst = -3;
	SKC_LootGUI.TimerBorder = CreateFrame("Frame",nil,SKC_LootGUI,"TranslucentFrameTemplate");
	SKC_LootGUI.TimerBorder:SetSize(UI_DIMENSIONS.STATUS_BAR_BRDR_WIDTH,UI_DIMENSIONS.STATUS_BAR_BRDR_HEIGHT);
	SKC_LootGUI.TimerBorder:SetPoint("TOP",SKC_LootGUI.loot_decision_roll_btn,"BOTTOM",0,timer_bar_y_offst);
	SKC_LootGUI.TimerBorder.Bg:SetAlpha(1.0);
	-- status bar
	SKC_LootGUI.TimerBar = CreateFrame("StatusBar",nil,SKC_LootGUI);
	SKC_LootGUI.TimerBar:SetSize(UI_DIMENSIONS.STATUS_BAR_BRDR_WIDTH - UI_DIMENSIONS.STATUS_BAR_WIDTH_OFFST,UI_DIMENSIONS.STATUS_BAR_BRDR_HEIGHT - UI_DIMENSIONS.STATUS_BAR_HEIGHT_OFFST);
	SKC_LootGUI.TimerBar:SetPoint("CENTER",SKC_LootGUI.TimerBorder,"CENTER",0,-1);
	-- background texture
	SKC_LootGUI.TimerBar.bg = SKC_LootGUI.TimerBar:CreateTexture(nil,"BACKGROUND",nil,-7);
	SKC_LootGUI.TimerBar.bg:SetAllPoints(SKC_LootGUI.TimerBar);
	SKC_LootGUI.TimerBar.bg:SetColorTexture(unpack(THEME.STATUS_BAR_COLOR));
	SKC_LootGUI.TimerBar.bg:SetAlpha(0.8);
	-- bar texture
	SKC_LootGUI.TimerBar.Bar = SKC_LootGUI.TimerBar:CreateTexture(nil,"BACKGROUND",nil,-6);
	SKC_LootGUI.TimerBar.Bar:SetColorTexture(0,0,0);
	SKC_LootGUI.TimerBar.Bar:SetAlpha(1.0);
	-- set status texture
	SKC_LootGUI.TimerBar:SetStatusBarTexture(SKC_LootGUI.TimerBar.Bar);
	-- add text
	SKC_LootGUI.TimerBar.Text = SKC_LootGUI.TimerBar:CreateFontString(nil,"ARTWORK",nil,7)
	SKC_LootGUI.TimerBar.Text:SetFontObject("GameFontHighlightSmall")
	SKC_LootGUI.TimerBar.Text:SetPoint("CENTER",SKC_LootGUI.TimerBar,"CENTER")
	SKC_LootGUI.TimerBar.Text:SetText(LOOT_DECISION.OPTIONS.MAX_DECISION_TIME)
	-- values
	SKC_LootGUI.TimerBar:SetMinMaxValues(0,LOOT_DECISION.OPTIONS.MAX_DECISION_TIME);
	SKC_LootGUI.TimerBar:SetValue(0);

	-- Make frame closable with esc
	table.insert(UISpecialFrames, "SKC_LootGUI");

	-- hide
	SKC_Main:HideLootDecisionGUI();
	return;
end

function SKC_Main:CreateUIMain()
	-- creates primary GUI for SKC
	if GUI_VERBOSE then SKC_Main:Print("NORMAL","CreateUIMain() start") end

	-- check if SKC_UIMain already exists
	if SKC_UIMain ~= nil then return SKC_UIMain end

	-- create main frame and make moveable
    SKC_UIMain = CreateFrame("Frame", "SKC_UIMain", UIParent, "UIPanelDialogTemplate");
	SKC_UIMain:SetSize(UI_DIMENSIONS.MAIN_WIDTH,UI_DIMENSIONS.MAIN_HEIGHT);
	SKC_UIMain:SetPoint("CENTER");
	SKC_UIMain:SetMovable(true)
	SKC_UIMain:EnableMouse(true)
	SKC_UIMain:RegisterForDrag("LeftButton")
	SKC_UIMain:SetScript("OnDragStart", SKC_UIMain.StartMoving)
	SKC_UIMain:SetScript("OnDragStop", SKC_UIMain.StopMovingOrSizing)
	SKC_UIMain:SetAlpha(0.8);
	SKC_UIMain:SetFrameLevel(0);

	-- Make frame closable with esc
	table.insert(UISpecialFrames, "SKC_UIMain");
	
	-- Add title
    SKC_UIMain.Title:ClearAllPoints();
	SKC_UIMain.Title:SetPoint("LEFT", SKC_UIMainTitleBG, "LEFT", 6, 0);
	SKC_UIMain.Title:SetText("SKC ("..ADDON_VERSION..")");

	-- Create status panel
	local status_border_key = CreateUIBorder("Status",UI_DIMENSIONS.SKC_STATUS_WIDTH,UI_DIMENSIONS.SKC_STATUS_HEIGHT)
	-- set position
	SKC_UIMain[status_border_key]:SetPoint("TOPLEFT", SKC_UIMainTitleBG, "TOPLEFT", UI_DIMENSIONS.MAIN_BORDER_PADDING+5, UI_DIMENSIONS.MAIN_BORDER_Y_TOP);
	-- create status fields
	local status_fields = {"Status","Synchronization","Loot Prio Items","Loot Officers"};
	for idx,value in ipairs(status_fields) do
		-- fields
		SKC_UIMain[status_border_key][value] = CreateFrame("Frame",SKC_UIMain[status_border_key])
		SKC_UIMain[status_border_key][value].Field = SKC_UIMain[status_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[status_border_key][value].Field:SetFontObject("GameFontNormal");
		SKC_UIMain[status_border_key][value].Field:SetPoint("RIGHT",SKC_UIMain[status_border_key],"TOPLEFT",130,-20*idx-10);
		SKC_UIMain[status_border_key][value].Field:SetText(value..":");
		-- data
		SKC_UIMain[status_border_key][value].Data = SKC_UIMain[status_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[status_border_key][value].Data:SetFontObject("GameFontHighlight");
		SKC_UIMain[status_border_key][value].Data:SetPoint("CENTER",SKC_UIMain[status_border_key][value].Field,"RIGHT",55,0);
	end

	-- Create filter panel
	local filter_border_key = CreateUIBorder("Filters",UI_DIMENSIONS.SK_FILTER_WIDTH,UI_DIMENSIONS.SK_FILTER_HEIGHT)
	-- set position
	SKC_UIMain[filter_border_key]:SetPoint("TOPLEFT", SKC_UIMain[status_border_key],"BOTTOMLEFT", 0, UI_DIMENSIONS.SK_FILTER_Y_OFFST);
	-- create details fields
	local faction_class;
	if UnitFactionGroup("player") == "Horde" then faction_class="Shaman" else faction_class="Paladin" end
	local filter_roles = {"DPS","Healer","Tank","Main","Alt","SKIP","Inactive","Active","Live","Druid","Hunter","Mage","Priest","Rogue","Warlock","Warrior",faction_class};
	local num_cols = 3;
	for idx,value in ipairs(filter_roles) do
		if value ~= "SKIP" then
			local row = math.floor((idx - 1) / num_cols); -- zero based
			local col = (idx - 1) % num_cols; -- zero based
			SKC_UIMain[filter_border_key][value] = CreateFrame("CheckButton", nil, SKC_UIMain[filter_border_key], "UICheckButtonTemplate");
			SKC_UIMain[filter_border_key][value]:SetSize(25,25);
			SKC_UIMain[filter_border_key][value]:SetChecked(SKC_DB.FilterStates[value]);
			SKC_UIMain[filter_border_key][value]:SetScript("OnClick",OnCheck_FilterFunction)
			SKC_UIMain[filter_border_key][value]:SetPoint("TOPLEFT", SKC_UIMain[filter_border_key], "TOPLEFT", 22 + 73*col , -20 + -24*row);
			SKC_UIMain[filter_border_key][value].text:SetFontObject("GameFontNormalSmall");
			SKC_UIMain[filter_border_key][value].text:SetText(value);
			if idx > 9 then
				-- assign class colors
				SKC_UIMain[filter_border_key][value].text:SetTextColor(CLASSES[value].color.r,CLASSES[value].color.g,CLASSES[value].color.b,1.0);
			end
		end
	end
	-- create filter status fields
	-- Shown
	-- filter
	local filter_status_name = "Filter Status";
	SKC_UIMain[filter_border_key][filter_status_name] = CreateFrame("Frame",SKC_UIMain[filter_border_key]);
	SKC_UIMain[filter_border_key][filter_status_name].Field = SKC_UIMain[filter_border_key]:CreateFontString(nil,"ARTWORK");
	SKC_UIMain[filter_border_key][filter_status_name].Field:SetFontObject("GameFontNormal");
	SKC_UIMain[filter_border_key][filter_status_name].Field:SetPoint("BOTTOMLEFT",SKC_UIMain[filter_border_key],"BOTTOMLEFT",25,22);
	SKC_UIMain[filter_border_key][filter_status_name].Field:SetText(filter_status_name..":");
	-- data
	SKC_UIMain[filter_border_key][filter_status_name].Data = SKC_UIMain[filter_border_key]:CreateFontString(nil,"ARTWORK");
	SKC_UIMain[filter_border_key][filter_status_name].Data:SetFontObject("GameFontHighlight");
	SKC_UIMain[filter_border_key][filter_status_name].Data:SetPoint("LEFT",SKC_UIMain[filter_border_key][filter_status_name].Field,"RIGHT",10,0);


	-- SK List border
	-- Create Border
	local sk_list_border_key = "sk_list_border";
	SKC_UIMain[sk_list_border_key] = CreateFrame("Frame",sk_list_border_key,SKC_UIMain,"TranslucentFrameTemplate");
	SKC_UIMain[sk_list_border_key]:SetSize(UI_DIMENSIONS.SK_LIST_WIDTH + 2*UI_DIMENSIONS.SK_LIST_BORDER_OFFST,UI_DIMENSIONS.SK_LIST_HEIGHT + 2*UI_DIMENSIONS.SK_LIST_BORDER_OFFST);
	SKC_UIMain[sk_list_border_key].Bg:SetAlpha(0.0);
	-- Create Title
	SKC_UIMain[sk_list_border_key].Title = CreateFrame("Frame",title_key,SKC_UIMain[sk_list_border_key],"TranslucentFrameTemplate");
	SKC_UIMain[sk_list_border_key].Title:SetSize(UI_DIMENSIONS.SK_TAB_TITLE_CARD_WIDTH,UI_DIMENSIONS.SK_TAB_TITLE_CARD_HEIGHT);
	SKC_UIMain[sk_list_border_key].Title:SetPoint("BOTTOM",SKC_UIMain[sk_list_border_key],"TOP",0,-20);
	SKC_UIMain[sk_list_border_key].Title.Text = SKC_UIMain[sk_list_border_key].Title:CreateFontString(nil,"ARTWORK")
	SKC_UIMain[sk_list_border_key].Title.Text:SetFontObject("GameFontNormal")
	SKC_UIMain[sk_list_border_key].Title.Text:SetPoint("CENTER",0,0)
	SKC_UIMain[sk_list_border_key].Title.Text:SetText("MSK")
	SKC_UIMain[sk_list_border_key].Title:SetScript("OnMouseDown",OnClick_SKListCycle);
	-- set position
	SKC_UIMain[sk_list_border_key]:SetPoint("TOPLEFT", SKC_UIMain[status_border_key], "TOPRIGHT", UI_DIMENSIONS.MAIN_BORDER_PADDING, 0);

	-- Create SK list panel
	SKC_UIMain.sk_list = CreateFrame("Frame",sk_list,SKC_UIMain,"InsetFrameTemplate");
	SKC_UIMain.sk_list:SetSize(UI_DIMENSIONS.SK_LIST_WIDTH,UI_DIMENSIONS.SK_LIST_HEIGHT);
	SKC_UIMain.sk_list:SetPoint("TOP",SKC_UIMain[sk_list_border_key],"TOP",0,-UI_DIMENSIONS.SK_LIST_BORDER_OFFST);

	-- Create scroll frame on SK list
	SKC_UIMain.sk_list.SK_List_SF = CreateFrame("ScrollFrame","SK_List_SF",SKC_UIMain.sk_list,"UIPanelScrollFrameTemplate2");
	SKC_UIMain.sk_list.SK_List_SF:SetPoint("TOPLEFT",SKC_UIMain.sk_list,"TOPLEFT",0,-2);
	SKC_UIMain.sk_list.SK_List_SF:SetPoint("BOTTOMRIGHT",SKC_UIMain.sk_list,"BOTTOMRIGHT",0,2);
	SKC_UIMain.sk_list.SK_List_SF:SetClipsChildren(true);
	SKC_UIMain.sk_list.SK_List_SF:SetScript("OnMouseWheel",OnMouseWheel_ScrollFrame);
	SKC_UIMain.sk_list.SK_List_SF.ScrollBar:SetPoint("TOPLEFT",SKC_UIMain.sk_list.SK_List_SF,"TOPRIGHT",-22,-21);

	-- Create scroll child
	local scroll_child = CreateFrame("Frame",nil,SKC_UIMain.sk_list.SK_List_SF);
	scroll_child:SetSize(UI_DIMENSIONS.SK_LIST_WIDTH,GetScrollMax());
	SKC_UIMain.sk_list.SK_List_SF:SetScrollChild(scroll_child);

	-- Create SK cards
	SKC_UIMain.sk_list.NumberFrame = {};
	SKC_UIMain.sk_list.NameFrame = {};
	for idx = 1, GetNumGuildMembers() do
		-- Create number frames
		SKC_UIMain.sk_list.NumberFrame[idx] = CreateFrame("Frame",nil,SKC_UIMain.sk_list.SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain.sk_list.NumberFrame[idx]:SetSize(30,UI_DIMENSIONS.SK_CARD_HEIGHT);
		SKC_UIMain.sk_list.NumberFrame[idx]:SetPoint("TOPLEFT",SKC_UIMain.sk_list.SK_List_SF:GetScrollChild(),"TOPLEFT",8,-1*((idx-1)*(UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING) + UI_DIMENSIONS.SK_CARD_SPACING));
		SKC_UIMain.sk_list.NumberFrame[idx].Text = SKC_UIMain.sk_list.NumberFrame[idx]:CreateFontString(nil,"ARTWORK")
		SKC_UIMain.sk_list.NumberFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain.sk_list.NumberFrame[idx].Text:SetPoint("CENTER",0,0)
		SKC_UIMain.sk_list.NumberFrame[idx]:SetScript("OnMouseDown",OnClick_NumberCard);
		SKC_UIMain.sk_list.NumberFrame[idx]:Hide();
		-- Create named card frames
		SKC_UIMain.sk_list.NameFrame[idx] = CreateFrame("Frame",nil,SKC_UIMain.sk_list.SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain.sk_list.NameFrame[idx]:SetSize(UI_DIMENSIONS.SK_CARD_WIDTH,UI_DIMENSIONS.SK_CARD_HEIGHT);
		SKC_UIMain.sk_list.NameFrame[idx]:SetPoint("TOPLEFT",SKC_UIMain.sk_list.SK_List_SF:GetScrollChild(),"TOPLEFT",43,-1*((idx-1)*(UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING) + UI_DIMENSIONS.SK_CARD_SPACING));
		SKC_UIMain.sk_list.NameFrame[idx].Text = SKC_UIMain.sk_list.NameFrame[idx]:CreateFontString(nil,"ARTWORK")
		SKC_UIMain.sk_list.NameFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain.sk_list.NameFrame[idx].Text:SetPoint("CENTER",0,0)
		-- Add texture for color
		SKC_UIMain.sk_list.NameFrame[idx].bg = SKC_UIMain.sk_list.NameFrame[idx]:CreateTexture(nil,"BACKGROUND");
		SKC_UIMain.sk_list.NameFrame[idx].bg:SetAllPoints(true);
		-- Bind function for click event
		SKC_UIMain.sk_list.NameFrame[idx]:SetScript("OnMouseDown",OnClick_SK_Card);
		SKC_UIMain.sk_list.NameFrame[idx]:Hide();
	end

	-- Create details panel
	DD_State = 0; -- reset drop down options state
	local details_border_key = CreateUIBorder("Details",UI_DIMENSIONS.SK_DETAILS_WIDTH,UI_DIMENSIONS.SK_DETAILS_HEIGHT);
	-- set position
	SKC_UIMain[details_border_key]:SetPoint("TOPLEFT", SKC_UIMain[sk_list_border_key], "TOPRIGHT", UI_DIMENSIONS.MAIN_BORDER_PADDING, 0);
	-- create details fields
	local details_fields = {"Name","Class","Spec","Raid Role","Guild Role","Status","Activity","Last Raid"};
	for idx,value in ipairs(details_fields) do
		-- fields
		SKC_UIMain[details_border_key][value] = CreateFrame("Frame",SKC_UIMain[details_border_key])
		SKC_UIMain[details_border_key][value].Field = SKC_UIMain[details_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_border_key][value].Field:SetFontObject("GameFontNormal");
		SKC_UIMain[details_border_key][value].Field:SetPoint("RIGHT",SKC_UIMain[details_border_key],"TOPLEFT",100,-20*idx-10);
		SKC_UIMain[details_border_key][value].Field:SetText(value..":");
		-- data
		SKC_UIMain[details_border_key][value].Data = SKC_UIMain[details_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_border_key][value].Data:SetFontObject("GameFontHighlight");
		SKC_UIMain[details_border_key][value].Data:SetPoint("CENTER",SKC_UIMain[details_border_key][value].Field,"RIGHT",45,0);
		if idx == 3 or 
		   idx == 5 or
		   idx == 6 or
		   idx == 7 then
			-- edit buttons
			SKC_UIMain[details_border_key][value].Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
			SKC_UIMain[details_border_key][value].Btn:SetID(idx);
			SKC_UIMain[details_border_key][value].Btn:SetPoint("LEFT",SKC_UIMain[details_border_key][value].Field,"RIGHT",95,0);
			SKC_UIMain[details_border_key][value].Btn:SetSize(40, 20);
			SKC_UIMain[details_border_key][value].Btn:SetText("Edit");
			SKC_UIMain[details_border_key][value].Btn:SetNormalFontObject("GameFontNormalSmall");
			SKC_UIMain[details_border_key][value].Btn:SetHighlightFontObject("GameFontHighlightSmall");
			SKC_UIMain[details_border_key][value].Btn:SetScript("OnMouseDown",OnClick_EditDetails);
			SKC_UIMain[details_border_key][value].Btn:Disable();
			-- associated drop down menu
			SKC_UIMain[details_border_key][value].DD = CreateFrame("Frame",nil, SKC_UIMain, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetAnchor(SKC_UIMain[details_border_key][value].DD, 0, 0, "TOPLEFT", SKC_UIMain[details_border_key][value].Btn, "TOPRIGHT");
		end
	end

	-- Add SK buttons
	-- full SK
	SKC_UIMain[details_border_key].manual_full_sk_btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].manual_full_sk_btn:SetPoint("BOTTOM",SKC_UIMain[details_border_key],"BOTTOM",0,15);
	SKC_UIMain[details_border_key].manual_full_sk_btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[details_border_key].manual_full_sk_btn:SetText("Full SK");
	SKC_UIMain[details_border_key].manual_full_sk_btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].manual_full_sk_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].manual_full_sk_btn:SetScript("OnMouseDown",OnClick_FullSK);
	SKC_UIMain[details_border_key].manual_full_sk_btn:Disable();
	-- single SK
	SKC_UIMain[details_border_key].manual_single_sk_btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].manual_single_sk_btn:SetPoint("RIGHT",SKC_UIMain[details_border_key].manual_full_sk_btn,"LEFT",-5,0);
	SKC_UIMain[details_border_key].manual_single_sk_btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[details_border_key].manual_single_sk_btn:SetText("Single SK");
	SKC_UIMain[details_border_key].manual_single_sk_btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].manual_single_sk_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].manual_single_sk_btn:SetScript("OnMouseDown",OnClick_SingleSK);
	SKC_UIMain[details_border_key].manual_single_sk_btn:Disable();
	-- set SK
	SKC_UIMain[details_border_key].manual_set_sk_btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].manual_set_sk_btn:SetPoint("LEFT",SKC_UIMain[details_border_key].manual_full_sk_btn,"RIGHT",5,0);
	SKC_UIMain[details_border_key].manual_set_sk_btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[details_border_key].manual_set_sk_btn:SetText("Set SK");
	SKC_UIMain[details_border_key].manual_set_sk_btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].manual_set_sk_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].manual_set_sk_btn:SetScript("OnMouseDown",OnClick_SetSK);
	SKC_UIMain[details_border_key].manual_set_sk_btn:Disable();

	-- create blank loot GUI
	SKC_Main:CreateLootGUI();

	-- Populate Data
	SKC_Main:PopulateData();
    
	SKC_UIMain:Hide();

	if GUI_VERBOSE then SKC_Main:Print("NORMAL","CreateUIMain() complete") end
	return SKC_UIMain;
end

--------------------------------------
-- EVENTS
--------------------------------------
local function EventHandler(self,event,...)
	-- if event == "CHAT_MSG_ADDON" then
	-- 	AddonMessageRead(...);
	-- else
	if event == "ADDON_LOADED" then
		OnAddonLoad(...);
	elseif event == "GUILD_ROSTER_UPDATE" then
		-- Sync GuildData (if GL) and create ticker to send sync requests
		SyncGuildData();
	elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LOOT_METHOD_CHANGED" then
		ManageLootLogging();
		UpdateLiveList();
		UpdateDetailsButtons();
	elseif event == "OPEN_MASTER_LOOT_LIST" then
		SaveLoot();
	elseif event == "PLAYER_ENTERING_WORLD" then
		if COMM_VERBOSE then SKC_Main:Print("NORMAL","Firing PLAYER_ENTERING_WORLD") end
		ManageLootLogging();
	end
	
	return;
end

local events = CreateFrame("Frame");
-- events:RegisterEvent("CHAT_MSG_ADDON");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("GUILD_ROSTER_UPDATE");
events:RegisterEvent("GROUP_ROSTER_UPDATE");
events:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
events:RegisterEvent("OPEN_MASTER_LOOT_LIST");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:SetScript("OnEvent", EventHandler);