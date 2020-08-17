--------------------------------------
-- SLASH COMMANDS
--------------------------------------
--------------------------------------
-- LOCAL CONSTANTS
--------------------------------------
local not_gl_error_msg = "You must be Guild Leader to do that";
local not_ml_error_msg = "You must be Master Looter to do that";
local not_valid_slash_msg = "That is not a valid slash command";
local too_many_inpts_msg = "Too many inputs";
--------------------------------------
-- FUNCTIONS
--------------------------------------
function SKC:SlashHandler(args)
    arg1, arg2, arg3 = self:GetArgs(args,3);
	if arg1 == nil then
		self:ToggleMainGUI();
	elseif arg1 == "ver" then
        self:PrintVersion();
    elseif arg1 == "lo" then
        if arg2 == "add" then
            self:AddLO(arg3);
            self:ShowLO();
        elseif arg2 == "remove" then
            self:RemoveLO(arg3);
            self:ShowLO();
        elseif arg2 == "clear" then
            self:ClearLO();
            self:ShowLO();
        else
            self:ShowLO();
        end
    elseif arg1 == "reset" then
        self:ResetDBs();
    else
        self:PrintHelp();
    end
    return;
end

function SKC:PrintHelp()
    -- prints help for slash commands
    print(" ");
    print("|cff"..self.THEME.PRINT.NORMAL.hex.."SKC Slash Commands:|r");
    -- all members
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc help|r - Lists all available slash commands");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc|r - Toggles GUI");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ver|r - Shows addon version");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lp|r - Displays the number of items in the Loot Prio database");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lp <item link/name>|r - Displays Loot Prio for given item");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b|r - Displays the Bench");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai|r - Displays Active Instances");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo|r - Displays Loot Officers");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export sk|r - Export (CSV) current sk lists");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc reset|r - Resets local SKC data");
    if self:isML() then
        print("|cff"..self.THEME.PRINT.NORMAL.hex.."Master Looter Only:|r");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b add <character name>|r - Adds character to the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b remove <character name>|r - Removes character from the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b clear|r - Clears the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc enable|r - Enables loot distribution with SKC");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc disable|r - Disables loot distribution with SKC");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export log|r - Export (CSV) loot log for most recent raid");
    end
    if self:isGL() then
        print("|cff"..self.THEME.PRINT.NORMAL.hex.."Guild Leader Only:|r");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lp init|r - Initialze Loot Prio with a CSV");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc <msk/tsk> init|r - Initialze SK List with a CSV");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai add <acro>|r - Adds instance to Active Instances");      
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai remove <acro>|r - Removes instance from Active Instances");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai clear|r - Clears Active Instances");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo add <name>|r - Adds name to Loot Officers");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo remove <name>|r - Removes name from Loot Officers");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo clear|r - Clears Loot Officers");
    end
    print(" ");
end

function SKC:PrintVersion()
    if self.db.char.ADDON_VERSION ~= nil then
        self:Print(self.db.char.ADDON_VERSION);
    else
        self:Error("Addon version missing");
    end
    return;
end

function SKC:ToggleMainGUI(force_show)
    -- toggles the main GUI
	-- create (does nothing if already created)
	self:CreateMainGUI();
	-- Refresh Data
	self:PopulateData();
	-- make shown
	self.MainGUI:SetShown(force_show or not self.MainGUI:IsShown());
	return;
end

function SKC:ShowLO(name)
	-- adds name to list of loot officers
	SKC.db.char.GLP:ShowLO();
	return;
end

function SKC:AddLO(name)
	-- adds name to list of loot officers
	SKC.db.char.GLP:AddLO(name);
	return;
end

function SKC:RemoveLO(name)
	-- adds name to list of loot officers
	SKC.db.char.GLP:RemoveLO(name);
	return;
end

function SKC:ClearLO()
	-- adds name to list of loot officers
	SKC.db.char.GLP:ClearLO();
	return;
end

function SKC:ResetDBs()
    -- resets all databases
    if not self:CheckAddonLoaded() then
        self:Error("Please wait for the addon to load");
        return;
    end
    self.db.char.GLP = GuildLeaderProtected:new();
	self.db.char.GD = GuildData:new();
	self.db.char.LOP = LootOfficerProtected:new();
	self.db.char.MSK = SK_List:new();
	self.db.char.TSK = SK_List:new();
	self.db.char.LP = LootPrio:new();
    self.db.char.LM = LootManager:new();
    self.db.char.INIT_SETUP = true;
    ReloadUI();
    return;
end












-- function SKC:HardReset()
-- 	-- resets the saved variables completely
-- 	self.db:Reset(self.DB_DEFAULT)
-- 	self.event_states.InitGuildSync = true;
-- 	return;
-- end

-- local function OnClick_ImportLootPrio()
-- 	-- imports loot prio CSV to database
-- 	-- reset database
-- 	SKC_DB.LootPrio = LootPrio:new(nil);
-- 	-- get text
-- 	local name = "Loot Priority Import";
-- 	local txt = SKC_UICSV[name].EditBox:GetText();
-- 	local line = nil;
-- 	local txt_rem = txt;
-- 	-- check if first row is header
-- 	line = strsplit(",",txt_rem,2);
-- 	if line == "Item" then
-- 		-- header --> skip
-- 		line, txt_rem = strsplit("\n",txt_rem,2);
-- 	end
-- 	-- read data
-- 	local valid = true;
-- 	local line_count = 2; -- account for header
-- 	while txt_rem ~= nil do
-- 		line, txt_rem = strsplit("\n",txt_rem,2);
-- 		local item, sk_list, res, de, open_roll, prios_txt = strsplit(",",line,6);
-- 		-- clean input data
-- 		item = StrOut(item);
-- 		sk_list = StrOut(sk_list);
-- 		-- check input data validity
-- 		if item == nil then
-- 			valid = false;
-- 			SKC_Main:Print("ERROR","Invalid Item (line: "..line_count..")");
-- 			break;
-- 		elseif not (sk_list == "MSK" or sk_list == "TSK") then
-- 			valid = false;
-- 			SKC_Main:Print("ERROR","Invalid SK List for "..item.." (line: "..line_count..")");
-- 			break;
-- 		elseif not (res == "TRUE" or res == "FALSE") then
-- 			valid = false;
-- 			SKC_Main:Print("ERROR","Invalid Reserved for "..item.." (line: "..line_count..")");
-- 			break;
-- 		elseif not (de == "TRUE" or de == "FALSE") then
-- 			valid = false;
-- 			SKC_Main:Print("ERROR","Invalid Disenchant for "..item.." (line: "..line_count..")");
-- 			break;
-- 		elseif not (open_roll == "TRUE" or open_roll == "FALSE") then
-- 			valid = false;
-- 			SKC_Main:Print("ERROR","Invalid Open Roll for "..item.." (line: "..line_count..")");
-- 			break;
-- 		end
-- 		-- write meta data for item
-- 		SKC_DB.LootPrio.items[item] = Prio:new(nil);
-- 		SKC_DB.LootPrio.items[item].sk_list = sk_list;
-- 		SKC_DB.LootPrio.items[item].reserved = BoolOut(res);
-- 		SKC_DB.LootPrio.items[item].DE = BoolOut(de);
-- 		SKC_DB.LootPrio.items[item].open_roll = BoolOut(open_roll);
-- 		-- read prios
-- 		local spec_class_cnt = 0;
-- 		while prios_txt ~= nil do
-- 			spec_class_cnt = spec_class_cnt + 1;
-- 			valid = spec_class_cnt <= 22;
-- 			if not valid then
-- 				SKC_Main:Print("ERROR","Too many Class/Spec combinations");
-- 				break;
-- 			end
-- 			-- split off next value
-- 			val, prios_txt = strsplit(",",prios_txt,2);
-- 			valid = false;
-- 			if val == "" then
-- 				-- Inelligible for loot --> permanent pass prio tier
-- 				val = PRIO_TIERS.PASS;
-- 				valid = true;
-- 			elseif val == "OS" then
-- 				val = PRIO_TIERS.SK.Main.OS;
-- 				valid = true;
-- 			else
-- 				val = NumOut(val);
-- 				valid = (val ~= nil and (val >= 1) and (val <= 5));
-- 			end 
-- 			if not valid then
-- 				SKC_Main:Print("ERROR","Invalid prio level for "..item.." and Class/Spec index "..spec_class_cnt);
-- 				break;
-- 			end
-- 			-- write prio value
-- 			SKC_DB.LootPrio.items[item].prio[spec_class_cnt] = val;
-- 			-- increment spec class counter
-- 		end
-- 		-- check that all expected columns were scanned (1 past actual count)
-- 		if (spec_class_cnt ~= 22) then
-- 			valid = false;
-- 			SKC_Main:Print("ERROR","Wrong number of Class/Spec combinations. Expected 22. Got "..spec_class_cnt);
-- 			break;
-- 		end
-- 		if not valid then break end
-- 		-- Check if item added was actually a tier armor set
-- 		if TIER_ARMOR_SETS[item] ~= nil then
-- 			local armor_set = item;
-- 			-- scan through armor set and individually add each item
-- 			for set_item_idx,set_item in ipairs(TIER_ARMOR_SETS[armor_set]) do
-- 				SKC_DB.LootPrio.items[set_item] = DeepCopy(SKC_DB.LootPrio.items[armor_set]);
-- 			end
-- 			-- remove armor set itself from database
-- 			SKC_DB.LootPrio.items[armor_set] = nil;
-- 		end
-- 		line_count = line_count + 1;
-- 	end
-- 	if not valid then
-- 		SKC_DB.LootPrio = LootPrio:new(nil);
-- 		return;
-- 	end
-- 	-- update edit timestamp
-- 	local ts = time();
-- 	SKC_DB.LootPrio.edit_ts_raid = ts;
-- 	SKC_DB.LootPrio.edit_ts_generic = ts;
-- 	SKC_Main:Print("NORMAL","Loot Priority Import Complete");
-- 	SKC_Main:Print("NORMAL",SKC_DB.LootPrio:length().." items added");
-- 	SKC_Main:RefreshStatus();
-- 	-- push new loot prio to guild
-- 	SyncPushSend("LootPrio",CHANNELS.SYNC_PUSH,"GUILD",nil);
-- 	-- close import GUI
-- 	SKC_UICSV[name]:Hide();
-- 	return;
-- end

-- local function OnClick_ImportSKList(sk_list)
-- 	-- imports SK list CSV into database
-- 	-- get text
-- 	local name = "SK List Import";
-- 	local txt = SKC_UICSV[name].EditBox:GetText();
-- 	-- check that every name in text is in GuildData
-- 	local txt_rem = txt;
-- 	local valid = true;
-- 	local char_name = nil;
-- 	local new_sk_list = {};
-- 	local new_chars_map = {};
-- 	while txt_rem ~= nil do
-- 		char_name, txt_rem = strsplit("\n",txt_rem,2);
-- 		if SKC_DB.GuildData:Exists(char_name) then
-- 			new_sk_list[#new_sk_list + 1] = char_name;
-- 			new_chars_map[char_name] = (new_chars_map[char_name] or 0) + 1;
-- 		else
-- 			-- character not in GuildData
-- 			SKC_Main:Print("ERROR",char_name.." not in GuildData");
-- 			valid = false;
-- 		end
-- 	end
-- 	if not valid then
-- 		SKC_Main:Print("ERROR","SK list not imported");
-- 		return;
-- 	end;
-- 	-- check that every name in GuildData is in text
-- 	valid = true;
-- 	for guild_member,_ in pairs(SKC_DB.GuildData.data) do
-- 		if new_chars_map[guild_member] == nil then
-- 			-- guild member not in list
-- 			SKC_Main:Print("ERROR",guild_member.." not in your SK list");
-- 			valid = false;
-- 		elseif new_chars_map[guild_member] == 1 then
-- 			-- guild member is in list exactly once
-- 		elseif new_chars_map[guild_member] > 1 then
-- 			-- guild member is in list more than once
-- 			SKC_Main:Print("ERROR",guild_member.." is in your SK list more than once");
-- 			valid = false;
-- 		else
-- 			-- guild member not in list
-- 			SKC_Main:Print("ERROR","DUNNO");
-- 			valid = false;
-- 		end
-- 	end
-- 	if not valid then
-- 		SKC_Main:Print("ERROR","SK list not imported");
-- 		return;
-- 	end;
-- 	-- reset database
-- 	SKC_DB[sk_list] = SK_List:new(nil);
-- 	-- write new database
-- 	for idx,val in ipairs(new_sk_list) do
-- 		SKC_DB[sk_list]:PushBack(val);
-- 	end
-- 	SKC_Main:Print("NORMAL",sk_list.." imported");
-- 	-- Set GUI to given SK list
-- 	self.MainGUI["sk_list_border"].Title.Text:SetText(sk_list);
-- 	-- Refresh data
-- 	SKC_Main:PopulateData();
-- 	-- push new sk list to guild
-- 	SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
-- 	SKC_UICSV[name]:Hide();
-- 	return;
-- end

-- function SKC_Main:SimpleListShow(list_name)
-- 	-- shows a simple list
-- 	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
-- 		SKC_Main:Print("ERROR","Input list is not valid");
-- 		return;
-- 	end
-- 	DEFAULT_CHAT_FRAME:AddMessage(" ");
-- 	SKC_Main:Print("IMPORTANT",list_name..":");
-- 	SKC_DB[list_name]:Show();
-- 	DEFAULT_CHAT_FRAME:AddMessage(" ");
-- 	return;
-- end

-- function SKC_Main:SimpleListAdd(list_name,element)
-- 	-- adds element to a simple list
-- 	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
-- 		SKC_Main:Print("ERROR","Input list is not valid");
-- 		return;
-- 	end
-- 	-- check for special conditions
-- 	if element == nil then
-- 		SKC_Main:Print("ERROR","Input cannot be nil");
-- 		return;
-- 	end
-- 	if (list_name == "Bench" or list_name == "LootOfficers") and not SKC_DB.GuildData:Exists(element) then
-- 		SKC_Main:Print("ERROR",element.." is not a valid guild member");
-- 		return;
-- 	end
-- 	if list_name == "ActiveRaids" and RAID_NAME_MAP[element] == nil then
-- 		SKC_Main:Print("ERROR",element.." is not a valid raid acronym");
-- 		SKC_Main:Print("WARN","Valid raid acronyms are:");
-- 		for raid_acro_tmp,raid_name_full in pairs(RAID_NAME_MAP) do
-- 			SKC_Main:Print("WARN",raid_acro_tmp.." ("..raid_name_full..")");
-- 		end
-- 		return;
-- 	end
-- 	-- add to list
-- 	local success = SKC_DB[list_name]:Add(element);
-- 	if success then
-- 		SKC_Main:Print("NORMAL",element.." added to "..list_name);
-- 		-- sync / update GUI
-- 		if list_name == "Bench" then 
-- 			UpdateLiveList();
-- 		elseif list_name == "LootOfficers" then 
-- 			UpdateDetailsButtons();
-- 		end
-- 		SyncPushSend(list_name,CHANNELS.SYNC_PUSH,"GUILD",nil);
-- 		SKC_Main:SimpleListShow(list_name);
-- 		SKC_Main:RefreshStatus();
-- 	end
-- 	return;
-- end

-- function SKC_Main:SimpleListRemove(list_name,element)
-- 	-- remove element from a simple list
-- 	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
-- 		SKC_Main:Print("ERROR","Input list is not valid");
-- 		return;
-- 	end
-- 	-- add to list
-- 	local success = SKC_DB[list_name]:Remove(element);
-- 	if success then
-- 		SKC_Main:Print("NORMAL",element.." removed from "..list_name);
-- 		-- sync
-- 		-- sync / update GUI
-- 		if list_name == "Bench" then 
-- 			UpdateLiveList();
-- 		elseif list_name == "LootOfficers" then 
-- 			UpdateDetailsButtons();
-- 		end
-- 		SyncPushSend(list_name,CHANNELS.SYNC_PUSH,"GUILD",nil);
-- 		SKC_Main:SimpleListShow(list_name);
-- 		SKC_Main:RefreshStatus();
-- 	end
-- 	return;
-- end

-- function SKC_Main:SimpleListClear(list_name)
-- 	-- clears a simple list
-- 	if list_name == nil or (list_name ~= "Bench" and list_name ~= "LootOfficers" and list_name ~= "ActiveRaids") then
-- 		SKC_Main:Print("ERROR","Input list is not valid");
-- 		return;
-- 	end
-- 	-- add to list
-- 	local success = SKC_DB[list_name]:Clear();
-- 	if success then
-- 		SKC_Main:Print("NORMAL",list_name.." cleared");
-- 		-- sync
-- 		if list_name == "Bench" then 
-- 			UpdateLiveList();
-- 		elseif list_name == "LootOfficers" then 
-- 			UpdateDetailsButtons();
-- 		end
-- 		SyncPushSend(list_name,CHANNELS.SYNC_PUSH,"GUILD",nil);
-- 		SKC_Main:SimpleListShow(list_name);
-- 		SKC_Main:RefreshStatus();
-- 	end
-- 	return;
-- end

-- function SKC_Main:ExportLog()
-- 	local name = "Log Export";
-- 	-- instantiate frame
-- 	local menu = SKC_UICSV[name] or CreateUICSV(name,false);
-- 	menu:SetShown(true);
-- 	-- Add log data
-- 	local log_data = "";
-- 	for idx1,log_entry in ipairs(SKC_DB.RaidLog) do
-- 		for idx2,data in ipairs(log_entry) do
-- 			log_data = log_data..tostring(data);
-- 			log_data = log_data..",";
-- 		end
-- 		log_data = log_data.."\n";
-- 	end
-- 	SKC_UICSV[name].EditBox:SetText(log_data);
-- 	SKC_UICSV[name].EditBox:HighlightText();
-- end

-- function SKC_Main:ExportSK()
-- 	local name = "SK List Export";
-- 	-- instantiate frame
-- 	local menu = SKC_UICSV[name] or CreateUICSV(name,false);
-- 	menu:SetShown(true);
-- 	-- get sk list data
-- 	local msk = SKC_DB.MSK:ReturnList();
-- 	local tsk = SKC_DB.TSK:ReturnList();
-- 	if #msk ~= #tsk then
-- 		SKC_Main:Print("ERROR","MSK and TSK lists are different lengths. That's bad.");
-- 		return;
-- 	end
-- 	-- construct data
-- 	local data = "MSK,TSK,\n";
-- 	for i = 1,#msk do
-- 		data = data..msk[i]..","..tsk[i].."\n";
-- 	end
-- 	-- add data to export
-- 	SKC_UICSV[name].EditBox:SetText(data);
-- 	SKC_UICSV[name].EditBox:HighlightText();
-- end

-- function SKC_Main:CSVImport(name,sk_list)
-- 	-- error checking + bind function for import button
-- 	-- confirm that addon loaded and ui created
-- 	if LoginSyncCheckTickerActive() then
-- 		SKC_Main:Print("ERROR","Please wait for login sync to complete");
-- 		return;
-- 	end
-- 	if not CheckAddonLoaded() then 
-- 		SKC_Main:Print("ERROR","Please wait for addon data to fully load");
-- 		return;
-- 	end
-- 	if CheckIfReadInProgress() then
-- 		SKC_Main:Print("ERROR","Please wait for read to complete");
-- 		return;
-- 	end
-- 	if self.MainGUI == nil then
-- 		-- create GUI
-- 		SKC_Main:CreateUIMain();
-- 	end
-- 	if name == "Loot Priority Import" then
-- 		-- instantiate frame
-- 		local menu = SKC_UICSV[name] or CreateUICSV(name,true);
-- 		menu:SetShown(true);
-- 		SKC_UICSV[name].ImportBtn:SetScript("OnMouseDown",OnClick_ImportLootPrio);
-- 	elseif name == "SK List Import" then
-- 		if sk_list ~= "MSK" and sk_list ~= "TSK" then
-- 			if sk_list == nil then
-- 				SKC_Main:Print("ERROR","No SK list name given")
-- 			else
-- 				SKC_Main:Print("ERROR",sk_list.." is not a list name");
-- 			end
-- 			return;
-- 		end
-- 		-- instantiate frame
-- 		local menu = SKC_UICSV[name] or CreateUICSV(name,true);
-- 		menu:SetShown(true);
-- 		SKC_UICSV[name].ImportBtn:SetScript("OnMouseDown",function() OnClick_ImportSKList(sk_list) end);
-- 	end
-- 	return;
-- end

-- function SKC_Main:Enable(enable_flag)
-- 	-- primary manual control over SKC
-- 	-- only can be changed my ML
-- 	if not SKC_Main:isML() then return end
-- 	SKC_DB.SKC_Enable = enable_flag;
-- 	SKC_Main:RefreshStatus();
-- 	return;
-- end

-- function SKC_Main:ResetData()
-- 	-- Manually resets data
-- 	-- First hide SK cards
-- 	SKC_Main:HideSKCards();
-- 	-- Reset data
-- 	HARD_DB_RESET = true;
-- 	OnAddonLoad("SKC");
-- 	HARD_DB_RESET = false;
-- 	-- re populate guild data
-- 	InitGuildSync = true;
-- 	SyncGuildData();
-- 	-- Refresh Data
-- 	SKC_Main:PopulateData();
-- end

-- local function CreateUICSV(name,import_btn)
-- 	SKC_UICSV[name] = CreateFrame("Frame",name,UIParent,"UIPanelDialogTemplate");
-- 	SKC_UICSV[name]:SetSize(UI_DIMENSIONS.CSV_WIDTH,UI_DIMENSIONS.CSV_HEIGHT);
-- 	SKC_UICSV[name]:SetPoint("CENTER");
-- 	SKC_UICSV[name]:SetMovable(true);
-- 	SKC_UICSV[name]:EnableMouse(true);
-- 	SKC_UICSV[name]:RegisterForDrag("LeftButton");
-- 	SKC_UICSV[name]:SetScript("OnDragStart", SKC_UICSV[name].StartMoving);
-- 	SKC_UICSV[name]:SetScript("OnDragStop", SKC_UICSV[name].StopMovingOrSizing);

-- 	-- Add title
-- 	SKC_UICSV[name].Title:SetPoint("LEFT", name.."TitleBG", "LEFT", 6, 0);
-- 	SKC_UICSV[name].Title:SetText(name);

-- 	-- Add edit box
-- 	SKC_UICSV[name].SF = CreateFrame("ScrollFrame", nil, SKC_UICSV[name], "UIPanelScrollFrameTemplate");
-- 	SKC_UICSV[name].SF:SetSize(UI_DIMENSIONS.CSV_EB_WIDTH,UI_DIMENSIONS.CSV_EB_HEIGHT);
-- 	SKC_UICSV[name].SF:SetPoint("TOPLEFT",SKC_UICSV[name],"TOPLEFT",20,-40)
-- 	SKC_UICSV[name].EditBox = CreateFrame("EditBox", nil, SKC_UICSV[name].SF)
-- 	SKC_UICSV[name].EditBox:SetMultiLine(true)
-- 	SKC_UICSV[name].EditBox:SetFontObject(ChatFontNormal)
-- 	SKC_UICSV[name].EditBox:SetSize(UI_DIMENSIONS.CSV_EB_WIDTH,1000)
-- 	SKC_UICSV[name].SF:SetScrollChild(SKC_UICSV[name].EditBox)

-- 	-- Add import button
-- 	if import_btn then
-- 		SKC_UICSV[name].ImportBtn = CreateFrame("Button", nil, SKC_UICSV[name], "GameMenuButtonTemplate");
-- 		SKC_UICSV[name].ImportBtn:SetPoint("BOTTOM",SKC_UICSV[name],"BOTTOM",0,15);
-- 		SKC_UICSV[name].ImportBtn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
-- 		SKC_UICSV[name].ImportBtn:SetText("Import");
-- 		SKC_UICSV[name].ImportBtn:SetNormalFontObject("GameFontNormal");
-- 		SKC_UICSV[name].ImportBtn:SetHighlightFontObject("GameFontHighlight");
-- 	end

-- 	-- set framel level and hide
-- 	SKC_UICSV[name]:SetFrameLevel(4);
-- 	SKC_UICSV[name]:Hide();

-- 	return SKC_UICSV[name];
-- end
    

-- SKC.commands = {
    
--     ["lp"] = function(...)
--     local itemName = nil;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         itemName = arg;
--         else
--         itemName = itemName.." "..arg;
--         end
--     end
--     -- check if want to init
--     if itemName == "init" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--         end
--         -- Initializes the loot prio with a CSV pasted into a window
--         core.SKC_Main:CSVImport("Loot Priority Import"); 
--         return;
--     end

--     if SKC_DB == nil or SKC_DB.LootPrio == nil then
--         SKC_Main:Print("ERROR","LootPrio does not exist");
--         return;
--     end

--     if itemName == nil then
--         -- print item count
--         SKC_DB.LootPrio:PrintPrio(itemName);
--     elseif string.sub(itemName,1,1) == "|" then
--         local item = Item:CreateFromItemLink(itemName)
--         item:ContinueOnItemLoad(function()
--         SKC_DB.LootPrio:PrintPrio(item:GetItemName(),itemName);
--         end)
--     else
--         -- call directly with itemName
--         SKC_DB.LootPrio:PrintPrio(itemName);
--     end
--     return;
--     end,
--     ["export"] = function(inpt)
--     if inpt == "log" then
--         -- opens UI to export log
--         core.SKC_Main:ExportLog(); 
--     elseif inpt == "sk" then
--         -- opens UI to export log
--         core.SKC_Main:ExportSK(); 
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     end,
--     ["reset"] = function() 
--     -- resets and re-syncs data
--     core.SKC_Main:ResetData();
--     end,
--     ["b"] = function(...)
--     -- parse input
--     local cmd, element;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         cmd = arg;
--         elseif idx == 2 then
--         element = arg;
--         else
--         core.SKC_Main:Print("ERROR",too_many_inpts_msg); 
--         return;
--         end
--     end
--     -- perform command
--     if cmd == nil then
--         core.SKC_Main:SimpleListShow("Bench");
--     elseif cmd == "add" then
--         if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListAdd("Bench",element);
--     elseif cmd == "remove" then
--         if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListRemove("Bench",element);
--     elseif cmd == "clear" then
--         if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListClear("Bench");
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     return;
--     end,
--     ["ai"] = function(...)
--     -- parse input
--     local cmd, element;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         cmd = arg;
--         elseif idx == 2 then
--         element = arg;
--         else
--         core.SKC_Main:Print("ERROR",too_many_inpts_msg); 
--         return;
--         end
--     end
--     -- perform command
--     if cmd == nil then
--         core.SKC_Main:SimpleListShow("ActiveRaids");
--     elseif cmd == "add" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListAdd("ActiveRaids",element);
--     elseif cmd == "remove" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListRemove("ActiveRaids",element);
--     elseif cmd == "clear" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListClear("ActiveRaids");
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     return;
--     end,
--     ["lo"] = function(...)
--     -- parse input
--     local cmd, element;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         cmd = arg;
--         elseif idx == 2 then
--         element = arg;
--         else
--         core.SKC_Main:Print("ERROR",too_many_inpts_msg); 
--         return;
--         end
--     end
--     -- perform command
--     if cmd == nil then
--         core.SKC_Main:SimpleListShow("LootOfficers");
--     elseif cmd == "add" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListAdd("LootOfficers",element);
--     elseif cmd == "remove" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListRemove("LootOfficers",element);
--     elseif cmd == "clear" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListClear("LootOfficers");
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     return;
--     end,
--     ["enable"] = function()
--     if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--     end
--     core.SKC_Main:Enable(true);
--     end,
--     ["disable"] = function()
--     if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--     end
--     core.SKC_Main:Enable(false);
--     end,
--     ["at"] = function(new_thresh)
--     new_thresh = tonumber(new_thresh);
--     if new_thresh == nil then
--         core.SKC_Main:Print("NORMAL","Activity threshold is "..SKC_DB.GLP:GetActivityThreshold().." days")
--         return;
--     end
--     if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--     end
--     if new_thresh <= 90 then
--         SKC_DB.GLP:SetActivityThreshold(new_thresh);
--         core.SKC_Main:Print("NORMAL","Activity threshold set to "..new_thresh.." days")
--     else
--         core.SKC_Main:Print("ERROR","Must input a number less than 90 days")
--     end
--     return;
--     end,
--     ["msk"] = {
--     ["init"] = function()
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--         end
--         -- Initializes the specified SK list with a CSV pasted into a window
--         core.SKC_Main:CSVImport("SK List Import","MSK");
--     end,
--     },
--     ["tsk"] = {
--     ["init"] = function()
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--         end
--         -- Initializes the specified SK list with a CSV pasted into a window
--         core.SKC_Main:CSVImport("SK List Import","TSK");
--     end,
--     },
-- };

-- local function HandleSlashCommands(str)
--     if (#str == 0) then
--     core.SKC_Main:ToggleUIMain(false);
--     else
--     -- split out args in string
--     local args = {};
--     for _, arg in ipairs({ string.split(' ', str) }) do
--         if (#arg > 0) then
--         table.insert(args, arg);
--         end
--     end

--     local path = core.commands; -- required for updating found table.
    
--     for id, arg in ipairs(args) do
--         if (#arg > 0) then -- if string length is greater than 0.
--         arg = arg:lower();			
--         if (path[arg]) then
--             if (type(path[arg]) == "function") then				
--             -- pass remaining args to function
--             path[arg](select(id + 1, unpack(args))); 
--             return;					
--             elseif (type(path[arg]) == "table") then				
--             path = path[arg]; -- another sub-table found!
--             end
--         else
--             -- does not exist!
--             core.commands.help();
--             return;
--         end
--         end
--     end

--     end
--     return
-- end
