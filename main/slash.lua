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
    elseif arg1 == "b" then
        if arg2 == "add" then
            if self.db.char.LOP:AddBench(arg3) then self.db.char.LOP:ShowBench() end
        elseif arg2 == "remove" then
            if self.db.char.LOP:RemoveBench(arg3) then self.db.char.LOP:ShowBench() end
        elseif arg2 == "clear" then
            if self.db.char.LOP:ClearBench() then self.db.char.LOP:ShowBench() end
        else
            self.db.char.LOP:ShowBench();
        end
    elseif arg1 == "lo" then
        if arg2 == "add" then
            if self.db.char.GLP:AddLO(arg3) then self.db.char.GLP:ShowLO() end
        elseif arg2 == "remove" then
            if self.db.char.GLP:RemoveLO(arg3) then self.db.char.GLP:ShowLO() end
        elseif arg2 == "clear" then
            if self.db.char.GLP:ClearLO() then self.db.char.GLP:ShowLO() end
        else
            self.db.char.GLP:ShowLO();
        end
    elseif arg1 == "ai" then
        if arg2 == "add" then
            if self.db.char.GLP:AddAI(arg3) then self.db.char.GLP:ShowAI() end
        elseif arg2 == "remove" then
            if self.db.char.GLP:RemoveAI(arg3) then self.db.char.GLP:ShowAI() end
        elseif arg2 == "clear" then
            if self.db.char.GLP:ClearAI() then self.db.char.GLP:ShowAI() end
        else
            self.db.char.GLP:ShowAI();
        end
    elseif arg1 == "lp" then
        if arg2 == nil then
            -- print item count
            self.db.char.LP:PrintPrio(itemName);
        elseif arg2 == "init" then
            if not self:isGL() then
                self:Error("You must be guild leader to do that");
            end
            -- Initializes the loot prio with a CSV pasted into a window
            self:CSVImport("Loot Priority Import"); 
        elseif string.sub(arg2,1,1) == "|" then
            -- argument is item link
            local item = Item:CreateFromItemLink(arg2)
            item:ContinueOnItemLoad(function()
                self.db.char.LP:PrintPrio(item:GetItemName(),arg2);
            end)
        else
            self:Error("Not a valid lp command");
        end
    elseif arg1 == "export" then
        if arg2 == "sk" then
            self:ExportSK();
        elseif arg2 == "log" then
            self:ExportLog();
        else
            self:Error("Not a valid export command");
        end
    elseif (arg1 == "msk" or arg1 == "tsk") and arg2 == "init" then
        if not self:isGL() then
            self:Error("You must be guild leader to do that");
        end
        self:CSVImport("SK List Import",string.upper(arg1)); 
    elseif arg1 == "reset" then
        self:ResetDBs();
    elseif arg1 == "enable" then
        self.db.char.LOP:Enable(true);
    elseif arg1 == "disable" then
        self.db.char.LOP:Enable(false);
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
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lp <item link>|r - Displays Loot Prio for given item");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b|r - Displays the Bench");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai|r - Displays Active Instances");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo|r - Displays Loot Officers");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export sk|r - Export (CSV) current sk lists");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc reset|r - Resets local SKC data and reloads ui");
    if self:isLO() then
        print("|cff"..self.THEME.PRINT.NORMAL.hex.."Loot Officer Only:|r");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b add <character name>|r - Adds character to the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b remove <character name>|r - Removes character from the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b clear|r - Clears the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc enable|r - Enables loot distribution with SKC");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc disable|r - Disables loot distribution with SKC");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export log|r - Export (CSV) loot log for most recent raid");
    end
    if self:isGL() then
        print("|cff"..self.THEME.PRINT.NORMAL.hex.."Guild Leader Only:|r");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc g init|r - Initialze Guild Data with a CSV");
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

--------------------------------------
-- IMPORT / EXPORT
--------------------------------------
function SKC:CreateCSVGUI(name,enable_btn)
	-- creates CSV GUI used for import / export
	if self.CSVGUI[name] ~= nil then return end

	-- create main frame
	self.CSVGUI[name] = CreateFrame("Frame",name,UIParent,"UIPanelDialogTemplate");
	self.CSVGUI[name]:SetSize(self.UI_DIMS.CSV_WIDTH,self.UI_DIMS.CSV_HEIGHT);
	self.CSVGUI[name]:SetPoint("CENTER");
	self.CSVGUI[name]:SetMovable(true);
	self.CSVGUI[name]:EnableMouse(true);
	self.CSVGUI[name]:RegisterForDrag("LeftButton");
	self.CSVGUI[name]:SetScript("OnDragStart", self.CSVGUI[name].StartMoving);
	self.CSVGUI[name]:SetScript("OnDragStop", self.CSVGUI[name].StopMovingOrSizing);

	-- Add title
	self.CSVGUI[name].Title:SetPoint("LEFT", name.."TitleBG", "LEFT", 6, 0);
	self.CSVGUI[name].Title:SetText(name);

	-- Add edit box
	self.CSVGUI[name].SF = CreateFrame("ScrollFrame", nil, self.CSVGUI[name], "UIPanelScrollFrameTemplate");
	self.CSVGUI[name].SF:SetSize(self.UI_DIMS.CSV_EB_WIDTH,self.UI_DIMS.CSV_EB_HEIGHT);
	self.CSVGUI[name].SF:SetPoint("TOPLEFT",self.CSVGUI[name],"TOPLEFT",20,-40)
	self.CSVGUI[name].EditBox = CreateFrame("EditBox", nil, self.CSVGUI[name].SF)
	self.CSVGUI[name].EditBox:SetMultiLine(true)
	self.CSVGUI[name].EditBox:SetFontObject(ChatFontNormal)
	self.CSVGUI[name].EditBox:SetSize(self.UI_DIMS.CSV_EB_WIDTH,1000)
	self.CSVGUI[name].SF:SetScrollChild(self.CSVGUI[name].EditBox)

	-- Add import button
	if enable_btn then
		self.CSVGUI[name].ImportBtn = CreateFrame("Button", nil, self.CSVGUI[name], "GameMenuButtonTemplate");
		self.CSVGUI[name].ImportBtn:SetPoint("BOTTOM",self.CSVGUI[name],"BOTTOM",0,15);
		self.CSVGUI[name].ImportBtn:SetSize(self.UI_DIMS.BTN_WIDTH, self.UI_DIMS.BTN_HEIGHT);
		self.CSVGUI[name].ImportBtn:SetText("Import");
		self.CSVGUI[name].ImportBtn:SetNormalFontObject("GameFontNormal");
		self.CSVGUI[name].ImportBtn:SetHighlightFontObject("GameFontHighlight");
	end

	-- set framel level and hide
	self.CSVGUI[name]:SetFrameLevel(4);
	self.CSVGUI[name]:Hide();

	return;
end

local function OnClick_ImportLootPrio()
	-- imports loot prio CSV to database
	-- reset database
	SKC.db.char.LP = LootPrio:new();
	-- get text
	local name = "Loot Priority Import";
	local txt = SKC.CSVGUI[name].EditBox:GetText();
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
		item = SKC:StrOut(item);
		sk_list = SKC:StrOut(sk_list);
		-- check input data validity
		if item == nil then
			valid = false;
			SKC:Error("Invalid Item (line: "..line_count..")");
			break;
		elseif not (sk_list == "MSK" or sk_list == "TSK") then
			valid = false;
			SKC:Error("Invalid SK List for "..item.." (line: "..line_count..")");
			break;
		elseif not (res == "TRUE" or res == "FALSE") then
			valid = false;
			SKC:Error("Invalid Reserved for "..item.." (line: "..line_count..")");
			break;
		elseif not (de == "TRUE" or de == "FALSE") then
			valid = false;
			SKC:Error("Invalid Disenchant for "..item.." (line: "..line_count..")");
			break;
		elseif not (open_roll == "TRUE" or open_roll == "FALSE") then
			valid = false;
			SKC:Error("Invalid Open Roll for "..item.." (line: "..line_count..")");
			break;
		end
		-- write meta data for item
		SKC.db.char.LP.items[item] = Prio:new(nil);
		SKC.db.char.LP.items[item].sk_list = sk_list;
		SKC.db.char.LP.items[item].reserved = SKC:BoolOut(res);
		SKC.db.char.LP.items[item].DE = SKC:BoolOut(de);
		SKC.db.char.LP.items[item].open_roll = SKC:BoolOut(open_roll);
		-- read prios
		local spec_class_cnt = 0;
		while prios_txt ~= nil do
			spec_class_cnt = spec_class_cnt + 1;
			valid = spec_class_cnt <= 22;
			if not valid then
				SKC:Error("Too many Class/Spec combinations");
				break;
			end
			-- split off next value
			val, prios_txt = strsplit(",",prios_txt,2);
			valid = false;
			if val == "" then
				-- Inelligible for loot --> permanent pass prio tier
				val = SKC.PRIO_TIERS.PASS;
				valid = true;
			elseif val == "OS" then
				val = SKC.PRIO_TIERS.SK.Main.OS;
				valid = true;
			else
				val = SKC:NumOut(val);
				valid = (val ~= nil and (val >= 1) and (val <= 5));
			end 
			if not valid then
				SKC:Error("Invalid prio level for "..item.." and Class/Spec index "..spec_class_cnt);
				break;
			end
			-- write prio value
			SKC.db.char.LP.items[item].prio[spec_class_cnt] = val;
			-- increment spec class counter
		end
		-- check that all expected columns were scanned (1 past actual count)
		if (spec_class_cnt ~= 22) then
			valid = false;
			SKC:Error("Wrong number of Class/Spec combinations. Expected 22. Got "..spec_class_cnt);
			break;
		end
		if not valid then break end
		-- Check if item added was actually a tier armor set
		if SKC.TIER_ARMOR_SETS[item] ~= nil then
			local armor_set = item;
			-- scan through armor set and individually add each item
			for _,set_item in ipairs(SKC.TIER_ARMOR_SETS[armor_set]) do
				SKC.db.char.LP.items[set_item] = SKC:DeepCopy(SKC.db.char.LP.items[armor_set]);
			end
			-- remove armor set itself from database
			SKC.db.char.LP.items[armor_set] = nil;
		end
		line_count = line_count + 1;
	end
	if not valid then
		SKC.db.char.LP = LootPrio:new();
		return;
	end
	-- update edit timestamp
	local ts = time();
	SKC.db.char.LP.edit_ts_raid = ts;
	SKC.db.char.LP.edit_ts_generic = ts;
	SKC:Print("Loot Priority Import Complete");
	SKC:Print(SKC.db.char.LP:length().." items added");
	SKC:RefreshStatus();
    -- push new loot prio to guild
    SKC:SendDB("LP","GUILD");
	-- close import GUI
	SKC.CSVGUI[name]:Hide();
	return;
end

local function OnClick_ImportSKList(sk_list)
	-- imports SK list CSV into database
	-- get text
	local name = "SK List Import";
	local txt = SKC.CSVGUI[name].EditBox:GetText();
	-- check that every name in text is in GuildData
	local txt_rem = txt;
	local valid = true;
	local char_name = nil;
	local new_sk_list = {};
	local new_chars_map = {};
	while txt_rem ~= nil do
		char_name, txt_rem = strsplit("\n",txt_rem,2);
		if SKC.db.char.GD:Exists(char_name) then
			new_sk_list[#new_sk_list + 1] = char_name;
			new_chars_map[char_name] = (new_chars_map[char_name] or 0) + 1;
		else
			-- character not in GuildData
			SKC:Error(char_name.." not in GuildData");
			valid = false;
		end
	end
	if not valid then
		SKC:Error("SK list not imported");
		return;
	end;
	-- check that every name in GuildData is in text
	valid = true;
	for guild_member,_ in pairs(SKC.db.char.GD.data) do
		if new_chars_map[guild_member] == nil then
			-- guild member not in list
			SKC:Error(guild_member.." not in your SK list");
			valid = false;
		elseif new_chars_map[guild_member] == 1 then
			-- guild member is in list exactly once
		elseif new_chars_map[guild_member] > 1 then
			-- guild member is in list more than once
			SKC:Error(guild_member.." is in your SK list more than once");
			valid = false;
		else
			-- guild member not in list
			SKC:Error("DUNNO");
			valid = false;
		end
	end
	if not valid then
		SKC:Error("SK list not imported");
		return;
	end;
	-- reset database
	SKC.db.char[sk_list] = SK_List:new();
	-- write new database
	for idx,val in ipairs(new_sk_list) do
		SKC.db.char[sk_list]:PushBack(val);
	end
	SKC:Print(sk_list.." imported");
	-- Set GUI to given SK list
	SKC.MainGUI["sk_list_border"].Title.Text:SetText(sk_list);
	-- Refresh data
	SKC:PopulateData();
	-- push new sk list to guild
	SKC:SendDB(sk_list,"GUILD");
	SKC.CSVGUI[name]:Hide();
	return;
end

function SKC:CSVImport(name,sk_list)
	-- error checking + bind function for import button
	-- confirm that addon loaded and ui created
	if not self:CheckAddonLoaded() then 
		self:Error("Please wait for addon data to load");
		return;
	end
	if self:CheckIfSyncInProgress() then
		self:Error("Please wait for sync to complete");
		return;
	end
	if name == "Loot Priority Import" then
		-- instantiate frame
		self:CreateCSVGUI(name,true);
		self.CSVGUI[name]:SetShown(true);
		self.CSVGUI[name].ImportBtn:SetScript("OnMouseDown",OnClick_ImportLootPrio);
	elseif name == "SK List Import" then
		if sk_list ~= "MSK" and sk_list ~= "TSK" then
			if sk_list == nil then
				self:Error("No SK list name given")
			else
				self:Error(sk_list.." is not a valid list name");
			end
			return;
		end
		-- instantiate frame
		self:CreateCSVGUI(name,true);
		self.CSVGUI[name]:SetShown(true);
		self.CSVGUI[name].ImportBtn:SetScript("OnMouseDown",function() OnClick_ImportSKList(sk_list) end);
	end
	return;
end

function SKC:ExportLog()
    if not self:isMLO() then
        self:Error("You must be the master looter and a loot officer to do that");
        return;
    end
	local name = "Log Export";
    -- instantiate frame
    self:CreateCSVGUI(name,false);
    self.CSVGUI[name]:SetShown(true);
	-- Add log data
	local log_data = "";
	for idx1,log_entry in ipairs(self.db.char.LOG) do
		for idx2,data in ipairs(log_entry) do
			log_data = log_data..tostring(data);
			log_data = log_data..",";
		end
		log_data = log_data.."\n";
	end
	self.CSVGUI[name].EditBox:SetText(log_data);
	self.CSVGUI[name].EditBox:HighlightText();
end

function SKC:ExportSK()
	local name = "SK List Export";
	-- instantiate frame
    self:CreateCSVGUI(name,false);
    self.CSVGUI[name]:SetShown(true);
	-- get sk list data
	local msk = SKC.db.char.MSK:ReturnList();
	local tsk = SKC.db.char.TSK:ReturnList();
	if #msk ~= #tsk then
		SKC:Print("ERROR","MSK and TSK lists are different lengths. That's bad.");
		return;
	end
	-- construct data
	local data = "MSK,TSK,\n";
	for i = 1,#msk do
		data = data..msk[i]..","..tsk[i].."\n";
	end
	-- add data to export
	self.CSVGUI[name].EditBox:SetText(data);
	self.CSVGUI[name].EditBox:HighlightText();
end