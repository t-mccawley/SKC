--------------------------------------
-- INITIALIZE
--------------------------------------
function SKC:OnInitialize()
	-- initialize saved database
	self.db = LibStub("AceDB-3.0"):New("SKC_DB",self.DB_DEFAULT);
	-- determine if fresh
	if self.db.char.INIT_SETUP then
		self:Alert("Welcome (/skc help)");
	else
		self:Alert("Welcome Back (/skc)");
	end
	-- initialize or refresh metatables
	self.db.char.GLP = GuildLeaderProtected:new(self.db.char.GLP);
	self.db.char.GD = GuildData:new(self.db.char.GD);
	self.db.char.LOP = LootOfficerProtected:new(self.db.char.LOP);
	self.db.char.MSK = SK_List:new(self.db.char.MSK);
	self.db.char.TSK = SK_List:new(self.db.char.TSK);
	self.db.char.LP = LootPrio:new(self.db.char.LP);
	self.db.char.LM = LootManager:new(self.db.char.LM);
	-- register slash commands
	self:RegisterChatCommand("rl",ReloadUI);
	self:RegisterChatCommand("skc","SlashHandler");
	-- register comms
	self:RegisterComm(self.CHANNELS.SYNC_CHECK,"ReadSyncCheck");
	self:RegisterComm(self.CHANNELS.SYNC_RQST,"ReadSyncRqst");
	self:RegisterComm(self.CHANNELS.SYNC_PUSH,"ReadSyncPush");
	-- LOGIN_SYNC_PUSH = "6-F?832qBmrJE?pR",
	-- LOGIN_SYNC_PUSH_RQST = "d$8B=qB4VsW&&Y^D",
	-- SYNC_PUSH = "8EtTWxyA$r6xi3=F",
	-- LOOT = "xBPE9,-Fjsc+A#rm",
	-- LOOT_DECISION = "ksg(Ak2.*/@&+`8Q",
	-- LOOT_DECISION_PRINT = "xP@&!9hQxY]1K&C4",
	-- LOOT_OUTCOME = "aP@yX9hQf}89K&C4",
	-- for _,channel in pairs(CHANNELS) do
	-- 	self:RegisterComm(channel,self.AddonMessageRead);
	-- 	-- TODO, need to make specific callback to read each channel....
	-- end
	-- register events
	self:RegisterEvent("GUILD_ROSTER_UPDATE","ManageGuildData");
	-- create blank main GUI
	self:CreateMainGUI();
	-- create blank loot GUI
	self:CreateLootGUI();
	-- Populate Data
	-- self:PopulateData();
	self.event_states.AddonLoaded = true;
	-- Start sync ticker
	self:StartSyncTicker();
	return;
end

-- local function OnAddonLoad(addon_name)
-- 	if addon_name ~= "SKC" then return end
-- 	self.event_states.InitGuildSync = false; -- only initialize if hard reset or new install
-- 	-- Initialize DBs
-- 	if SKC_DB == nil or HARD_DB_RESET then
-- 		HardReset();
-- 		if HARD_DB_RESET then 
-- 			self:Print("IMPORTANT","Hard Reset: Manual");
-- 		end
-- 		self:Print("IMPORTANT","Welcome (/skc help)");
-- 	else
-- 		self:Print("IMPORTANT","Welcome back (/skc)");
-- 	end
-- 	-- if self.db.char.AddonVersion == nil or self.db.char.AddonVersion ~= ADDON_VERSION then
-- 	-- 	-- addon version never set
-- 	-- 	HardReset();
-- 	-- 	self:Print("IMPORTANT","Hard Reset: New addon version "..self.db.char.AddonVersion);
-- 	-- end
-- 	if self.db.char.GLP == nil then
-- 		self.db.char.GLP = nil;
-- 	end
-- 	if SKC_DB.LOP == nil then
-- 		SKC_DB.LOP = nil;
-- 	end
-- 	if self.db.char.GD == nil then
-- 		self.db.char.GD = nil;
-- 	end
-- 	if self.db.char.MSK == nil then 
-- 		self.db.char.MSK = nil;
-- 	end
-- 	if self.db.char.TSK == nil then 
-- 		self.db.char.TSK = nil;
-- 	end
-- 	if SKC_DB.RaidLog == nil then
-- 		SKC_DB.RaidLog = {};
-- 	end
-- 	if SKC_DB.LootManager == nil then
-- 		SKC_DB.LootManager = nil
-- 	end
-- 	end
-- 	-- always reset live filter state because its confusing to see a blank list
-- 	SKC_DB.FilterStates.Live = false;
-- 	-- Initialize or refresh metatables
-- 	self.db.char.GLP = GuildLeaderProtected:new(self.db.char.GLP);
-- 	SKC_DB.LOP = LootOfficerProtected:new(SKC_DB.LOP);
-- 	self.db.char.GD = GuildData:new(self.db.char.GD);
-- 	self.db.char.MSK = SK_List:new(self.db.char.MSK);
-- 	self.db.char.TSK = SK_List:new(self.db.char.TSK);
-- 	SKC_DB.LootManager = LootManager:new(SKC_DB.LootManager);
-- 	-- Addon loaded
-- 	self.event_states.AddonLoaded = true;
-- 	-- Manage loot logging
-- 	ManageLootLogging();
-- 	-- Update live list
-- 	UpdateLiveList();
-- 	-- Populate data
-- 	self:PopulateData();
-- 	return;
-- end




-- -- WARNING: self automatically becomes events frame!
-- function core:init(event, name)
--     if (name ~= "SKC") then return end 

--     -- allows using left and right buttons to move through chat 'edit' box
--     for i = 1, NUM_CHAT_WINDOWS do
--         _G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
--     end
    
--     ----------------------------------
--     -- Register Slash Commands!
--     ----------------------------------
--     SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI
--     SlashCmdList.RELOADUI = ReloadUI;

--     SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
--     SlashCmdList.FRAMESTK = function()
--         LoadAddOn("Blizzard_DebugTools");
--         FrameStackTooltip_Toggle(false);
--     end

--     SLASH_SKC1 = "/skc";
--     SlashCmdList.SKC = HandleSlashCommands;
-- end

-- local events = CreateFrame("Frame");
-- events:RegisterEvent("ADDON_LOADED");
-- events:SetScript("OnEvent", core.init);

--------------------------------------
-- EVENTS
--------------------------------------
-- local function EventHandler(self,event,...)
-- 	-- if event == "CHAT_MSG_ADDON" then
-- 	-- 	AddonMessageRead(...);
-- 	-- else
-- 	if event == "ADDON_LOADED" then
-- 		OnAddonLoad(...);
-- 	elseif event == "GUILD_ROSTER_UPDATE" then
-- 		-- Sync GuildData (if GL) and create ticker to send sync requests
-- 		ManageGuildData();
-- 	elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LOOT_METHOD_CHANGED" then
-- 		ManageLootLogging();
-- 		UpdateLiveList();
-- 		UpdateDetailsButtons();
-- 	elseif event == "OPEN_MASTER_LOOT_LIST" then
-- 		SaveLoot();
-- 	elseif event == "PLAYER_ENTERING_WORLD" then
-- 		if COMM_VERBOSE then self:Print("Firing PLAYER_ENTERING_WORLD") end
-- 		ManageLootLogging();
-- 	end
	
-- 	return;
-- end

-- local events = CreateFrame("Frame");
-- -- events:RegisterEvent("CHAT_MSG_ADDON");
-- events:RegisterEvent("ADDON_LOADED");
-- events:RegisterEvent("GUILD_ROSTER_UPDATE");
-- events:RegisterEvent("GROUP_ROSTER_UPDATE");
-- events:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
-- events:RegisterEvent("OPEN_MASTER_LOOT_LIST");
-- events:RegisterEvent("PLAYER_ENTERING_WORLD");
-- events:SetScript("OnEvent", EventHandler);