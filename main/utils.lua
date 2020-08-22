--------------------------------------
-- UTILS
--------------------------------------
-- various general utilities used in SKC
--------------------------------------
-- ADDON CONTROL
--------------------------------------
function SKC:Activate()
	-- master control for wheter or not loot is managed with SKC
	if not self:CheckAddonLoaded() then return end
	if not self.db.char.LOP:IsEnabled() then
		self.Status = self.STATUS_ENUM.DISABLED;
	elseif self.db.char.GLP:GetAddonVer() == nil then
		self.Status = self.STATUS_ENUM.INACTIVE_GL;
	elseif not self:CheckAddonVerMatch(self.db.char.ADDON_VERSION) then
		self.Status = self.STATUS_ENUM.INACTIVE_VER;
	elseif not UnitInRaid("player") then
		self.Status = self.STATUS_ENUM.INACTIVE_RAID;
	elseif GetLootMethod() ~= "master" then
		self.Status = self.STATUS_ENUM.INACTIVE_ML;
	else
		-- Master Looter is Loot Officer
		local _, _, masterlooterRaidIndex = GetLootMethod();
		local master_looter_name = GetRaidRosterInfo(masterlooterRaidIndex);
		local loot_officer_check = self.DEV.LOOT_OFFICER_OVRD or self:isLO(master_looter_name);
		if not loot_officer_check then
			self.Status = self.STATUS_ENUM.INACTIVE_LO;
		else
			-- Elligible instance
			local active_instance_check = self.DEV.ACTIVE_INSTANCE_OVRD or self:CheckActiveInstance()
			if not active_instance_check then
				self.Status = self.STATUS_ENUM.INACTIVE_AI;
			else
				self.Status = self.STATUS_ENUM.ACTIVE;
			end
		end
	end
	return;
end
--------------------------------------
-- PRINTING
--------------------------------------
function SKC:GetThemeColor(type)
	local c = self.THEME.PRINT[type];
	return c.r, c.g, c.b, c.hex;
end

function SKC:Print(msg)
	-- formats and prints msg with red color
	local hex = select(4, self:GetThemeColor("NORMAL"));
	local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
	DEFAULT_CHAT_FRAME:AddMessage(string.join(" ",prefix,msg));
    return;
end

function SKC:Warn(msg)
	-- formats and prints msg with red color
	local hex = select(4, self:GetThemeColor("WARN"));
	local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
	DEFAULT_CHAT_FRAME:AddMessage(string.join(" ",prefix,msg));
    return;
end

function SKC:Alert(msg)
	-- formats and prints msg with red color
	local hex = select(4, self:GetThemeColor("ALERT"));
	local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
	DEFAULT_CHAT_FRAME:AddMessage(string.join(" ",prefix,msg));
    return;
end

function SKC:Error(msg)
	-- formats and prints msg with red color
	local hex = select(4, self:GetThemeColor("ERROR"));
	local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
	DEFAULT_CHAT_FRAME:AddMessage(string.join(" ",prefix,msg));
    return;
end

function SKC:Debug(msg,lvl)
	-- prints message if level is at or below VERBOSITY_LEVEL
	if lvl <= SKC.DEV.VERBOSITY_LEVEL then
		local hex = select(4, self:GetThemeColor("DEBUG"));
		local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
		DEFAULT_CHAT_FRAME:AddMessage(string.join(" ",prefix,msg));
	end
    return;
end

function SKC:FormatWithClassColor(char_name)
	-- formats str with class color for class
	if char_name == nil or not self.db.char.GD:Exists(char_name) then return end
	local class = self.db.char.GD:GetClass(char_name);
	if class == nil or self.CLASSES[class] == nil then return str_in end
	local class_color = self.CLASSES[class].color.hex
	local str_out = "|cff"..class_color..char_name.."|r"
	return str_out;
end
--------------------------------------
-- PERMISSIONS
--------------------------------------
function SKC:isML(name)
	-- Check if name or current player is master looter
	local check;
	if name == nil then
		check = UnitName("player") == self.DEV.ML_OVRD or IsMasterLooter();
	else
		local _, _, masterlooterRaidIndex = GetLootMethod();
		check = name == self.DEV.ML_OVRD or (masterlooterRaidIndex ~= nil and name == GetRaidRosterInfo(masterlooterRaidIndex));
	end
	return(check);
end

function SKC:isGL(name)
	-- Check if name is guild leader
	if name == nil then
		local guildName = GetGuildInfo("player");
		return(UnitName("player") == self.DEV.GL_OVRD or (self.db.global.localGL[guildName] ~= nil and self.db.global.localGL[guildName]));
	else
		return(self.GUILD_LEADER == name)
	end
end

function SKC:isLO(name)
	-- returns true if given name (current player if nil) is a loot officer
	if name == nil then name = UnitName("player") end
	return(self:CheckDatabasePopulated("GLP") and self.db.char.GLP:CheckIfLO(name));
end

function SKC:isMLO(name)
	-- returns true if given name (current player if nil) is a loot officer AND master looter
	if name == nil then name = UnitName("player") end
	return(self:isLO(name) and self:isML(name));
end

function SKC:GetGuildLeader()
	-- returns name of guild leader
	-- if not in a guild, return nil
	if not IsInGuild() then
		self:Error("No guild leader, not in guild");
		return nil;
	end
	-- check if manual override
	if self.DEV.GL_OVRD ~= nil then return self.DEV.GL_OVRD end
	-- Scan guild roster and find guild leader
	for idx = 1, GetNumGuildMembers() do
		local full_name, _, rankIndex = GetGuildRosterInfo(idx);
		if rankIndex == 0 then
			local name = self:StripRealmName(full_name);
			return name;
		end
	end
	return nil;
end
--------------------------------------
-- CHECKS
--------------------------------------
function SKC:CheckDatabasePopulated(db_target)
	-- returns true of target database has been populated
	if self.db == nil or self.db.char == nil or db_target == nil or self.db.char[db_target] == nil then
		return(false);
	end
	return(true);
end

function SKC:CheckMainGUICreated()
	-- returns true if MainGUI has been created
	return(self.MainGUI ~= nil)
end

function SKC:CheckLootGUICreated()
	-- returns true if LootGUI has been created
	return(self.LootGUI ~= nil)
end

function SKC:CheckActive()
	-- returns true of SKC is active
	return(self.Status.val == SKC.STATUS_ENUM.ACTIVE.val);
end

function SKC:CheckAddonLoaded()
	-- checks that addon database has loaded
	if self.event_states.AddonLoaded then
		return true;
	else
		return false;
	end
end

function SKC:CheckAddonVerMatch(ver)
	-- returns true if client addon version matches required version
	if not self:CheckDatabasePopulated("GLP") then return(false) end
	return(self.db.char.GLP:IsAddonVerMatch(ver));
end

function SKC:CheckIfSyncInProgress()
	-- returns true if addon is currently syncing
	return((self:GetSyncStatus()).val == self.SYNC_STATUS_ENUM.IN_PROGRESS.val);
end

function SKC:GetOnlineSyncables()
	-- returns ordered list of guild leader and loot officers that are online
	local syncables = {};
	for idx = 1, GetNumGuildMembers() do
		local full_name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(idx);
		local name = self:StripRealmName(full_name);
		if self:isGL(name) or self:isLO(name) then
			syncables[#syncables + 1] = name;
		end
	end
	return(syncables);
end

function SKC:CheckIfGuildMemberOnline(target)
	-- checks if given guild member (target) is online
	-- prevents sending message to offline member and prevents that annoying spam
	for idx = 1, GetNumGuildMembers() do
		local full_name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(idx);
		if self:StripRealmName(full_name) == target then
			return(online);
		end
	end
	return(false);
end

function SKC:CheckIfAnyGuildMemberOnline()
	-- checks if ANY guild member is online
	-- prevents sending message to offline member and prevents that annoying spam
	for idx = 1, GetNumGuildMembers() do
		local _, _, _, _, _, _, _, _, online = GetGuildRosterInfo(idx);
		if online then
			return(true);
		end
	end
	return(false);
end

function SKC:CheckSKinGuildData(sk_list,sk_list_data)
	-- Check that every character in SK list is also in GuildData
	if sk_list_data == nil then
		sk_list_data = self.db.char[sk_list]:ReturnList();
	end
	for pos,name in ipairs(sk_list_data) do
		if not self.db.char.GD:Exists(name) then
			self:Debug(name.." in "..sk_list.." but not in GuildData",self.DEV.VERBOSE.SYNC_LOW);
			return false;
		end
	end
	return true;
end

function SKC:CheckActiveInstance()
	if not self:CheckDatabasePopulated("GLP") then return false end
	return(self.db.char.GLP:IsActiveInstance());
end

function SKC:CheckSyncInProgress()
	-- scan all databases and return true if sync is in progress
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		if self.SyncStatus[db].val == self.SYNC_STATUS_ENUM.IN_PROGRESS.val then
			return(true);
		end
	end
	return(false);
end

function SKC:CheckIfEffectivelyNil(str)
	-- check if string is effectively nil
	return(str == nil or str == " " or str == "");
end
--------------------------------------
-- LOGGING
--------------------------------------
function SKC:WriteToLog(
	event_type,
	subject,
	action,
	item,
	sk_list,
	prio,
	current_sk_pos,
	new_sk_pos,
	roll,
	item_rec,
	time_txt,
	master_looter_txt,
	class_txt,
	spec_txt,
	status_txt
)
	-- writes new log entry (if raid logging active)
	if not self.db.char.LoggingActive then return end
	local idx = #self.db.char.LOG + 1;
	self.db.char.LOG[idx] = {};
	if time_txt == nil then
		self.db.char.LOG[idx][1] = date(DATE_FORMAT);
	else
		self.db.char.LOG[idx][1] = time_txt;
	end
	if master_looter_txt == nil then
		if self:isML() then
			self.db.char.LOG[idx][2] = UnitName("player");
		else
			self.db.char.LOG[idx][2] = "";
		end
	else
		self.db.char.LOG[idx][2] = master_looter_txt;
	end
	self.db.char.LOG[idx][3] = event_type or "";
	self.db.char.LOG[idx][4] = subject or "";
	if class_txt == nil then
		self.db.char.LOG[idx][5] = self.db.char.GD:GetClass(subject) or "";
	else
		self.db.char.LOG[idx][5] = class_txt;
	end
	if spec_txt == nil then
		self.db.char.LOG[idx][6] = self.db.char.GD:GetSpecName(subject) or "";
	else
		self.db.char.LOG[idx][6] = spec_txt;
	end
	if status_txt == nil then
		self.db.char.LOG[idx][7] = self.db.char.GD:GetData(subject,"Status");
	else
		self.db.char.LOG[idx][7] = status_txt;
	end
	self.db.char.LOG[idx][8] = action or "";
	self.db.char.LOG[idx][9] = item or "";
	self.db.char.LOG[idx][10] = sk_list or "";
	self.db.char.LOG[idx][11] = prio or "";
	self.db.char.LOG[idx][12] = current_sk_pos or "";
	self.db.char.LOG[idx][13] = new_sk_pos or "";
	self.db.char.LOG[idx][14] = roll or "";
	self.db.char.LOG[idx][15] = item_rec or "";
	return;
end

function SKC:ResetLog()
	self.db.char.LOG = {};
	-- Initialize with header
	self:WriteToLog(
		self.LOG_OPTIONS["Event Type"].Text,
		self.LOG_OPTIONS["Subject"].Text,
		self.LOG_OPTIONS["Action"].Text,
		self.LOG_OPTIONS["Item"].Text,
		self.LOG_OPTIONS["SK List"].Text,
		self.LOG_OPTIONS["Prio"].Text,
		self.LOG_OPTIONS["Current SK Position"].Text,
		self.LOG_OPTIONS["New SK Position"].Text,
		self.LOG_OPTIONS["Roll"].Text,
		self.LOG_OPTIONS["Item Receiver"].Text,
		self.LOG_OPTIONS["Timestamp"].Text,
		self.LOG_OPTIONS["Master Looter"].Text,
		self.LOG_OPTIONS["Class"].Text,
		self.LOG_OPTIONS["Spec"].Text,
		self.LOG_OPTIONS["Status"].Text
	);
	return;
end

function SKC:ManageLogging()
	-- determines if logging should be on or off based on status
	-- check if SKC is active, if so start loot logging
	local prev_log_state = self.db.char.LoggingActive;
	if self.DEV.LOG_ACTIVE_OVRD or self:CheckActive() then
		self.db.char.LoggingActive = true;
		if not prev_log_state then
			self:ResetLog();
			self:Print("Loot logging turned on");
		end
	else
		self.db.char.LoggingActive = false;
		if prev_log_state then self:Print("Loot logging turned off") end
	end
	return;
end
--------------------------------------
-- DATA CLEANING
--------------------------------------
function SKC:StripRealmName(full_name)
	-- removes realm name (separated by hyphen) from full name
	local name,_ = strsplit("-",full_name,2);
	return(name);
end

function SKC:StrOut(inpt)
	if inpt == " " then return nil else return inpt end
end

function SKC:NumOut(inpt)
	if inpt == " " then return nil else return tonumber(inpt) end
end

function SKC:BoolOut(inpt)
	if inpt == " " then return nil else return ( (inpt == "1") or (inpt == "TRUE") ) end
end

function SKC:NilToStr(inpt)
	if inpt == nil then return " " else return tostring(inpt) end
end

function SKC:BoolToStr(inpt)
	if inpt then return "1" else return "0" end
end
--------------------------------------
-- COMMUNICATION
--------------------------------------
function SKC:Send(data,addon_channel,wow_channel,target,callback_fn)
	-- serialize, compress, and send an addon message
	local data_ser = self.lib_ser:Serialize(data);
	local data_comp = self.lib_comp:CompressHuffman(data_ser)
	local msg = self.lib_enc:Encode(data_comp)
	self:SendCommMessage(addon_channel,msg,wow_channel,target,"NORMAL",callback_fn);
	return;
end

function SKC:Read(msg)
	-- decode, decompress, and deserialize data from addon message
	-- if failed, returns nil
	-- Decode the compressed data
	local data_decode = self.lib_enc:Decode(msg);
		
	--Decompress the decoded data
	local data_decomp, err_message = self.lib_comp:Decompress(data_decode);
	if not data_decomp then
		self:Error("Error decompressing: "..err_message);
		return;
	end
		
	-- Deserialize the decompressed data
	local success, data_out = self.lib_ser:Deserialize(data_decomp);
	if not success then
		self:Error("Error deserializing: "..data_out);
		return;
	end

	return data_out;
end

function SKC:GetSyncStatus()
	-- scan all databases and return sync status
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		if self.SyncStatus[db].val == self.SYNC_STATUS_ENUM.IN_PROGRESS.val then
			return(self.SYNC_STATUS_ENUM.IN_PROGRESS);
		end
	end
	return(self.SYNC_STATUS_ENUM.COMPLETE);
end
--------------------------------------
-- MISC
--------------------------------------
function SKC:DeepCopy(obj,seen)
	-- credit: https://gist.github.com/tylerneylon/81333721109155b2d244
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
  
    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[self:DeepCopy(k, s)] = self:DeepCopy(v, s) end
    return setmetatable(res, getmetatable(obj))
end

function SKC:GetSpecClassColor(spec_class)
	-- Returns color code for given SpecClass
	for class,tbl in pairs(self.CLASSES) do
		if string.find(spec_class,class) ~= nil then
			return tbl.color.r, tbl.color.g, tbl.color.b, tbl.color.hex;
		end
	end
	return nil,nil,nil,nil;
end

function SKC:ManageLocalGuildLeader()
	-- records locally if player is a guild leader of the current guild
	if not IsInGuild() then return end
	local guildName = GetGuildInfo("player");
	if guildName == nil then return end
	if UnitName("player") == self.DEV.GL_OVRD or IsGuildLeader() then
		-- guild leader
		self.db.global.localGL[guildName] = true;
	elseif self.db.global.localGL[guildName] == nil then
		-- not yet marked and not GL
		self.db.global.localGL[guildName] = false;
	end
	return;
end

function SKC:ManageGuildData()
	-- synchronize GuildData with guild roster
	if not self:CheckAddonLoaded() then
		self:Debug("Reject ManageGuildData, addon not loaded yet",self.DEV.VERBOSE.GUILD);
		return;
	end
	if not IsInGuild() then
		self:Debug("Rejected ManageGuildData, not in guild",self.DEV.VERBOSE.GUILD);
		return;
	end
	-- save local confirmation that player is a guild leader of this guild
	self:ManageLocalGuildLeader();
	-- store name of guild leader
	self.GUILD_LEADER = self:GetGuildLeader();
	-- manage GLP
	if self:isGL() then
		-- set required version to current version
		self.db.char.GLP:SetAddonVer(self.db.char.ADDON_VERSION);
		-- add self (GL) to loot officers (bypass GD Exists check in case guild data has not yet intialized)
		self.db.char.GLP:AddLO(UnitName("player"),true);
	end
	if GetNumGuildMembers() <= 1 then
		-- guild is only one person, no members to fetch data for
		self:Debug("Rejected ManageGuildData, no guild members",self.DEV.VERBOSE.GUILD);
		return;
	end
	if self.SyncPartner.GD ~= nil then
		self:Debug("Rejected ManageGuildData, sync in progress",self.DEV.VERBOSE.GUILD);
		return;
	end
	if not self:isGL() then
		-- only fetch data if guild leader
		self:Debug("Rejected ManageGuildData, not guild leader",self.DEV.VERBOSE.GUILD);
	else
		-- Scan guild roster and add new players
		local guild_roster = {};
		for idx = 1, GetNumGuildMembers() do
			local full_name, _, _, level, class = GetGuildRosterInfo(idx);
			local name = self:StripRealmName(full_name);
			if level == 60 or self.DEV.GUILD_CHARS_OVRD[name] then
				guild_roster[name] = true;
				if not self.db.char.GD:Exists(name) then
					-- new player, add to DB and SK lists
					self.db.char.GD:Add(name,class);
					self.db.char.MSK:PushBack(name);
					self.db.char.TSK:PushBack(name);
					self:Print(name.." added to databases");
				end
			end
		end
		-- Scan guild data and remove players
		for name,data in pairs(self.db.char.GD.data) do
			if guild_roster[name] == nil then
				self.db.char.MSK:Remove(name);
				self.db.char.TSK:Remove(name);
				self.db.char.GD:Remove(name);
				self:Warn(name.." removed from databases");
			end
		end
		-- prepare filter count for GUI
		self.UnFilteredCnt = self.db.char.GD:length();
		self:Debug("ManageGuildData success!",self.DEV.VERBOSE.GUILD);
	end
	return;
end

function SKC:ManageRaidChanges()
	self:UpdateLiveList();
	self:UpdateDetailsButtons();
	return;
end

function SKC:ManageLiveLists(name,live_status)
	-- adds / removes player to live lists and records time in guild data
	-- NOTE: this method does not change the edit timestamp of the SK lists to avoid constant syncing
	local sk_lists = {"MSK","TSK"};
	for _,sk_list in pairs(sk_lists) do
		local success = self.db.char[sk_list]:SetLive(name,live_status);
	end
	return;
end

function SKC:UpdateLiveList()
	-- Adds every player in raid to live list
	-- All players update their own local live lists
	if not self:CheckAddonLoaded() then return end
	self:Debug("Updating live list",self.DEV.VERBOSE.RAID);

	-- Activate SKC
	self:RefreshStatus();

	-- Scan guild data and update live list if in raid
	for char_name,_ in pairs(self.db.char.GD.data) do
		self:ManageLiveLists(char_name,UnitInRaid(char_name) ~= nil);
	end

	-- Scan bench and update live list
	for char_name,_ in pairs(self.db.char.LOP.bench) do
		self:ManageLiveLists(char_name,true);
	end

	-- populate data
	self:PopulateData();
	return;
end