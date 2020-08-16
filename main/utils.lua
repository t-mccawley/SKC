--------------------------------------
-- UTILS
--------------------------------------
--------------------------------------
-- ADDON CONTROL
--------------------------------------
function SKC:Activate()
	-- master control for wheter or not loot is managed with SKC
	if not self:CheckAddonLoaded() then return end
	if not self.db.char.ENABLED then
		self.Status = self.STATUS_ENUM.DISABLED;
	elseif self.db.char.GLP:GetGLAddonVer() == nil then
		self.Status = self.STATUS_ENUM.INACTIVE_GL;
	elseif not self:CheckAddonVerMatch() then
		self.Status = self.STATUS_ENUM.INACTIVE_VER;
	elseif not UnitInRaid("player") then
		self.Status = self.STATUS_ENUM.INACTIVE_RAID;
	elseif GetLootMethod() ~= "master" then
		self.Status = self.STATUS_ENUM.INACTIVE_ML;
	else
		-- Master Looter is Loot Officer
		local _, _, masterlooterRaidIndex = GetLootMethod();
		local master_looter_full_name = GetRaidRosterInfo(masterlooterRaidIndex);
		local loot_officer_check = self.DEV.LOOT_OFFICER_OVRD or self:isLO(self.StripRealmName(master_looter_full_name));
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
function SKC:isML()
	-- Check if current player is master looter
	return(UnitName("player") == self.DEV.ML_OVRD or IsMasterLooter());
end

function SKC:isGL(name)
	-- Check if name is guild leader
	if name == nil then
		return(UnitName("player") == self.DEV.GL_OVRD or IsGuildLeader());
	else
		local _,_,guildRankIndex = GetGuildInfo(name);
		return(guildRankIndex == 0)
	end
end

function SKC:isLO(name)
	-- returns true if given name (current player if nil) is a loot officer
	if name == nil then name = UnitName("player") end
	return(self:CheckDatabasePopulated("GLP") and self.db.char.GLP:CheckIfLO(name));
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
	local output = self.db ~= nil and self.db.char ~= nil;
	if output and db_target ~= nil then
		output = output and self.db.char[db_target] ~= nil
	end
	return(output);
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

function SKC:CheckAddonVerMatch()
	-- returns true if client addon version matches required version
	if not self:CheckDatabasePopulated("GLP") then return false end
	return(self.db.char.GLP:IsAddonVerMatch());
end

function SKC:CheckIfReadInProgress()
	-- return true of any database is currently being read from
	for db_name,read in pairs(self.event_states.ReadInProgress) do
		if read then return true end
	end
	return false;
end

function SKC:CheckIfPushInProgress()
	-- return true of any database is currently being read from
	for db_name,push in pairs(self.event_states.PushInProgress) do
		if push then return true end
	end
	return false;
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
			self:Debug(name.." in "..sk_list.." but not in GuildData",self.DEV.VERBOSE.COMM)
			return false;
		end
	end
	return true;
end

function SKC:CheckActiveInstance()
	if not self:CheckDatabasePopulated("GLP") then return false end
	return(self.db.char.GLP:IsActiveInstance());
end
--------------------------------------
-- LOGGING
--------------------------------------
function SKC:WriteToLog(event_type,subject,action,item,sk_list,prio,current_sk_pos,new_sk_pos,roll,item_rec,time_txt,master_looter_txt,class_txt,spec_txt,status_txt)
	-- writes new log entry (if raid logging active)
	if not self.event_states.LoggingActive then return end
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
		local status_val = self.db.char.GD:GetData(subject,"Status");
		local status_str = "";
		if status_val == 0 then
			status_str = "Main";
		elseif status_val == 1 then
			status_str = "Alt";
		end
		self.db.char.LOG[idx][7] = status_str;
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
	-- determines if logging should be on or off
	-- activate SKC / update GUI
	self:RefreshStatus();
	-- check if SKC is active, if so start loot logging
	local prev_log_state = self.event_states.LoggingActive;
	if self.DEV.LOG_ACTIVE_OVRD or self:CheckActive() then
		self.event_states.LoggingActive = true;
		if not prev_log_state then
			ResetLog();
			self:Print("Loot logging turned on");
		end
	else
		self.event_states.LoggingActive = false;
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
-- MISC
--------------------------------------
function SKC:DeepCopy(obj, seen)
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
	for class,tbl in pairs(self.self.CLASSES) do
		if string.find(spec_class,class) ~= nil then
			return tbl.color.r, tbl.color.g, tbl.color.b, tbl.color.hex;
		end
	end
	return nil,nil,nil,nil;
end



-- local function PrintSyncMsgStart(db_name,push,sender)
-- 	if COMM_VERBOSE then 
-- 		if push then
-- 			DEBUG.PushTime[db_name] = time();
-- 			self:Print("IMPORTANT","["..DEBUG.PushTime[db_name].."] Pushing "..db_name.."...");
-- 		else
-- 			DEBUG.ReadTime[db_name] = time();
-- 			self:Print("IMPORTANT","["..DEBUG.ReadTime[db_name].."] Reading "..db_name.." from "..sender.."...");
-- 		end
-- 	end
-- 	if push then
-- 		event_states.PushInProgress[db_name] = true;
-- 	else
-- 		event_states.ReadInProgress[db_name] = true;
-- 	end
-- 	self:RefreshStatus();
-- 	return;
-- end

-- local function PrintSyncMsgEnd(db_name,push)
-- 	if COMM_VERBOSE then 
-- 		if push then
-- 			DEBUG.PushTime[db_name] = time() - DEBUG.PushTime[db_name];
-- 			self:Print("IMPORTANT","["..DEBUG.PushTime[db_name].."] "..db_name.." push complete!");
-- 		else
-- 			DEBUG.ReadTime[db_name] = time() - DEBUG.ReadTime[db_name];
-- 			self:Print("IMPORTANT","["..DEBUG.ReadTime[db_name].."] "..db_name.." read complete!");
-- 		end
-- 	end
-- 	if push then
-- 		event_states.PushInProgress[db_name] = false;
-- 	else
-- 		event_states.ReadInProgress[db_name] = false;
-- 	end
-- 	self:RefreshStatus();
-- 	return;
-- end





