--------------------------------------
-- UTILS
--------------------------------------
function SKC:Error(msg)
    -- formats and prints msg with red color
    self:Print("|cff"..self.THEME.PRINT.ERROR.hex..msg.."|r")
    return;
end

function SKC:isML()
	-- Check if current player is master looter
	return(UnitName("player") == self.ML_OVRD or IsMasterLooter());
end

function SKC:isGL()
	-- Check if current player is guild leader
	return(UnitName("player") == self.GL_OVRD or IsGuildLeader());
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

local function SendCompMsg(data,addon_channel,wow_channel,target,prio,callback_fn)
	-- serialize, compress, and send
	local data_ser = SKC.lib_ser:Serialize(data);
	local data_comp = SKC.lib_comp:CompressHuffman(data_ser)
	local msg = SKC.lib_enc:Encode(data_comp)
	SKC:SendCommMessage(addon_channel,msg,wow_channel,target,prio,callback_fn);
end

local function CheckActive(verbose)
	-- returns true of SKC is active
	if verbose then SKC_Main:Print("NORMAL","SKC Status: "..SKC_Status.text) end
	return(SKC_Status.val == SKC_STATUS_ENUM.ACTIVE.val);
end

local function CheckAddonLoaded(verbose)
	-- checks that addon database has loaded
	if event_states.AddonLoaded then
		return true;
	else
		if verbose then SKC_Main:Print("ERROR","Addon databases not yet loaded") end
		return false;
	end
end

local function CheckAddonVerMatch()
	-- returns true if client addon version matches required version
	if SKC_DB == nil or SKC_DB.GLP == nil then return false end
	return(SKC_DB.GLP:IsAddonVerMatch());
end

local function StripRealmName(full_name)
	local name,_ = strsplit("-",full_name,2);
	return(name);
end

function SKC_Main:isLO(name)
	-- returns true if given name (current player if nil) is a loot officer
	if name == nil then name = UnitName("player") end
	return(LOOT_OFFICER_OVRD or (SKC_DB ~= nil and SKC_DB.GLP ~= nil and SKC_DB.GLP:IsLO(name)));
end

local function CheckIfReadInProgress()
	-- return true of any database is currently being read from
	for db_name,read in pairs(event_states.ReadInProgress) do
		if read then return true end
	end
	return false;
end

local function CheckIfPushInProgress()
	-- return true of any database is currently being read from
	for db_name,push in pairs(event_states.PushInProgress) do
		if push then return true end
	end
	return false;
end

local function CheckActivity(name)
	-- checks activity level
	-- returns true if still active
	return (SKC_DB.GuildData:CalcActivity(name) < SKC_DB.GLP:GetActivityThreshold()*DAYS_TO_SECS);
end

local function CheckIfGuildMemberOnline(target,verbose)
	-- checks if given guild member (target) is online
	-- prevents sending message to offline member and prevents that annoying spam
	if verbose then print("Checking online status for "..target) end
	for idx = 1, GetNumGuildMembers() do
		local full_name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(idx);
		if StripRealmName(full_name) == target then
			if verbose then
				if online then print("online") else print("offline") end
			end
			return(online);
		end
	end
	if verbose then print("unknown") end
	return(false);
end

local function CheckIfAnyGuildMemberOnline(verbose)
	-- checks if ANY guild member is online
	-- prevents sending message to offline member and prevents that annoying spam
	if verbose then print("Checking if any guild members are online") end
	for idx = 1, GetNumGuildMembers() do
		local _, _, _, _, _, _, _, _, online = GetGuildRosterInfo(idx);
		if online then
			if verbose then
				if online then print("online") else print("offline") end
			end
			return(true);
		end
	end
	if verbose then print("unknown") end
	return(false);
end

local function GetGuildLeader()
	-- returns name of guild leader
	-- if not in a guild, return nil
	if not IsInGuild() then
		SKC_Main:Print("ERROR","No guild leader, not in guild");
		return nil;
	end
	-- check if manual override
	if GL_OVRD ~= nil then return GL_OVRD end
	-- Scan guild roster and find guild leader
	for idx = 1, GetNumGuildMembers() do
		local full_name, _, rankIndex = GetGuildRosterInfo(idx);
		if rankIndex == 0 then
			local name = StripRealmName(full_name);
			return name;
		end
	end
	return nil;
end

local function FormatWithClassColor(char_name)
	-- formats str with class color for class
	if char_name == nil or not SKC_DB.GuildData:Exists(char_name) then return end
	local class = SKC_DB.GuildData:GetClass(char_name);
	if class == nil or CLASSES[class] == nil then return str_in end
	local class_color = CLASSES[class].color.hex
	local str_out = "|cff"..class_color..char_name.."|r"
	return str_out;
end

local function StrOut(inpt)
	if inpt == " " then return nil else return inpt end
end

local function NumOut(inpt)
	if inpt == " " then return nil else return tonumber(inpt) end
end

local function BoolOut(inpt)
	if inpt == " " then return nil else return ( (inpt == "1") or (inpt == "TRUE") ) end
end

local function NilToStr(inpt)
	if inpt == nil then return " " else return tostring(inpt) end
end

local function BoolToStr(inpt)
	if inpt then return "1" else return "0" end
end

local function DeepCopy(obj, seen)
	-- credit: https://gist.github.com/tylerneylon/81333721109155b2d244
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
  
    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[DeepCopy(k, s)] = DeepCopy(v, s) end
    return setmetatable(res, getmetatable(obj))
end

local function WriteToLog(event_type,subject,action,item,sk_list,prio,current_sk_pos,new_sk_pos,roll,item_rec,time_txt,master_looter_txt,class_txt,spec_txt,status_txt)
	-- writes new log entry (if raid logging active)
	if not event_states.RaidLoggingActive then return end
	local idx = #SKC_DB.RaidLog + 1;
	SKC_DB.RaidLog[idx] = {};
	if time_txt == nil then
		SKC_DB.RaidLog[idx][1] = date(DATE_FORMAT);
	else
		SKC_DB.RaidLog[idx][1] = time_txt;
	end
	if master_looter_txt == nil then
		if SKC_Main:isML() then
			SKC_DB.RaidLog[idx][2] = UnitName("player");
		else
			SKC_DB.RaidLog[idx][2] = "";
		end
	else
		SKC_DB.RaidLog[idx][2] = master_looter_txt;
	end
	SKC_DB.RaidLog[idx][3] = event_type or "";
	SKC_DB.RaidLog[idx][4] = subject or "";
	if class_txt == nil then
		SKC_DB.RaidLog[idx][5] = SKC_DB.GuildData:GetClass(subject) or "";
	else
		SKC_DB.RaidLog[idx][5] = class_txt;
	end
	if spec_txt == nil then
		SKC_DB.RaidLog[idx][6] = SKC_DB.GuildData:GetSpecName(subject) or "";
	else
		SKC_DB.RaidLog[idx][6] = spec_txt;
	end
	if status_txt == nil then
		local status_val = SKC_DB.GuildData:GetData(subject,"Status");
		local status_str = "";
		if status_val == 0 then
			status_str = "Main";
		elseif status_val == 1 then
			status_str = "Alt";
		end
		SKC_DB.RaidLog[idx][7] = status_str;
	else
		SKC_DB.RaidLog[idx][7] = status_txt;
	end
	SKC_DB.RaidLog[idx][8] = action or "";
	SKC_DB.RaidLog[idx][9] = item or "";
	SKC_DB.RaidLog[idx][10] = sk_list or "";
	SKC_DB.RaidLog[idx][11] = prio or "";
	SKC_DB.RaidLog[idx][12] = current_sk_pos or "";
	SKC_DB.RaidLog[idx][13] = new_sk_pos or "";
	SKC_DB.RaidLog[idx][14] = roll or "";
	SKC_DB.RaidLog[idx][15] = item_rec or "";
	return;
end

local function PrintSyncMsgStart(db_name,push,sender)
	if COMM_VERBOSE then 
		if push then
			DEBUG.PushTime[db_name] = time();
			SKC_Main:Print("IMPORTANT","["..DEBUG.PushTime[db_name].."] Pushing "..db_name.."...");
		else
			DEBUG.ReadTime[db_name] = time();
			SKC_Main:Print("IMPORTANT","["..DEBUG.ReadTime[db_name].."] Reading "..db_name.." from "..sender.."...");
		end
	end
	if push then
		event_states.PushInProgress[db_name] = true;
	else
		event_states.ReadInProgress[db_name] = true;
	end
	SKC_Main:RefreshStatus();
	return;
end

local function PrintSyncMsgEnd(db_name,push)
	if COMM_VERBOSE then 
		if push then
			DEBUG.PushTime[db_name] = time() - DEBUG.PushTime[db_name];
			SKC_Main:Print("IMPORTANT","["..DEBUG.PushTime[db_name].."] "..db_name.." push complete!");
		else
			DEBUG.ReadTime[db_name] = time() - DEBUG.ReadTime[db_name];
			SKC_Main:Print("IMPORTANT","["..DEBUG.ReadTime[db_name].."] "..db_name.." read complete!");
		end
	end
	if push then
		event_states.PushInProgress[db_name] = false;
	else
		event_states.ReadInProgress[db_name] = false;
	end
	SKC_Main:RefreshStatus();
	return;
end

