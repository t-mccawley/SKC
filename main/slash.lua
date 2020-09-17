--------------------------------------
-- SLASH COMMANDS
--------------------------------------
-- handles slash commands
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
		if arg2 == "add" or arg2 == "remove" or arg2 == "clear" then
			if arg2 == "add" then
				if self.db.char.LOP:AddBench(arg3) then self.db.char.LOP:ShowBench() end
			elseif arg2 == "remove" then
				if self.db.char.LOP:RemoveBench(arg3) then self.db.char.LOP:ShowBench() end
			elseif arg2 == "clear" then
				if self.db.char.LOP:ClearBench() then self.db.char.LOP:ShowBench() end
			end
			self:ManageRaidChanges();
			self:RefreshStatus();
        else
            self.db.char.LOP:ShowBench();
		end
	elseif arg1 == "lo" then
		if arg2 == "add" or arg2 == "remove" or arg2 == "clear" then
			if arg2 == "add" then
				if self.db.char.GLP:AddLO(arg3) then self.db.char.GLP:ShowLO() end
			elseif arg2 == "remove" then
				if self.db.char.GLP:RemoveLO(arg3) then self.db.char.GLP:ShowLO() end
			elseif arg2 == "clear" then
				if self.db.char.GLP:ClearLO() then self.db.char.GLP:ShowLO() end
			end
			self:ManageRaidChanges();
			self:RefreshStatus();
        else
            self.db.char.GLP:ShowLO();
        end
	elseif arg1 == "ai" then
		if arg2 == "add" or arg2 == "remove" or arg2 == "clear" then
			if arg2 == "add" then
				if self.db.char.GLP:AddAI(arg3) then self.db.char.GLP:ShowAI() end
			elseif arg2 == "remove" then
				if self.db.char.GLP:RemoveAI(arg3) then self.db.char.GLP:ShowAI() end
			elseif arg2 == "clear" then
				if self.db.char.GLP:ClearAI() then self.db.char.GLP:ShowAI() end
			end
			self:RefreshStatus();
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
					return;
            end
            -- Initializes the loot prio with a CSV pasted into a window
            self:CSVImport("Loot Prio Import"); 
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
		elseif arg2 == "g" then
			self:ExportGuildData();
        else
            self:Error("Not a valid export command");
        end
    elseif (arg1 == "msk" or arg1 == "tsk") and arg2 == "init" then
        if not self:isGL() then
			self:Error("You must be guild leader to do that");
				return;
        end
		self:CSVImport("SK List Import",string.upper(arg1));
	elseif arg1 == "g" and arg2 == "init" then
        if not self:isGL() then
			self:Error("You must be guild leader to do that");
			return;
        end
        self:CSVImport("Guild Data Import"); 
    elseif arg1 == "reset" then
        self:ResetDBs();
    elseif arg1 == "enable" then
        self.db.char.LOP:Enable(true);
    elseif arg1 == "disable" then
		self.db.char.LOP:Enable(false);
	elseif arg1 == "ldt" then
		local time_in = tonumber(arg2);
		if time_in == nil then
			self.db.char.GLP:PrintLootDecisionTime();
		else
			self.db.char.GLP:SetLootDecisionTime(tonumber(arg2));
		end
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
	print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ldt|r - Displays the current loot decision time");
	print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export sk|r - Export (CSV) current SK lists");
	print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export g|r - Export (CSV) current Guild Data");
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
		print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ldt <#>|r - Changes the loot decision time to # in seconds");
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

function SKC:ResetDBs(force)
    -- resets all databases
    if not force and not self:CheckAddonLoaded() then
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
	-- create temporary db
	temp_lp = LootPrio:new();
	-- get text
	local name = "Loot Prio Import";
	local txt = SKC.CSVGUI[name].EditBox:GetText();
	local line = nil;
	local txt_rem = txt;
	local line_count = 1;
	-- check if first row is header
	line = strsplit(",",txt_rem,2);
	if line == "Item" then
		-- header --> skip
		line, txt_rem = strsplit("\n",txt_rem,2);
		line_count = line_count + 1;
	end
	-- read data
	local valid = true;
	while txt_rem ~= nil do
		line, txt_rem = strsplit("\n",txt_rem,2);
		local item, sk_list, sk_res, open_roll, roll_res, de, prios_txt = strsplit(",",line,7);
		-- clean input data
		item = SKC:StrOut(item);
		sk_list = SKC:StrOut(sk_list);
		-- check input data validity
		if item == nil then
			valid = false;
			SKC:Error("Invalid Item (line: "..line_count..")");
			break;
		elseif not (sk_list == "MSK" or sk_list == "TSK" or sk_list == "NONE") then
			valid = false;
			SKC:Error("Invalid SK List for "..item.." (line: "..line_count..")");
			break;
		elseif not (sk_res == "TRUE" or sk_res == "FALSE") then
			valid = false;
			SKC:Error("Invalid SK Reserved for "..item.." (line: "..line_count..")");
			break;
		elseif not (open_roll == "TRUE" or open_roll == "FALSE") then
			valid = false;
			SKC:Error("Invalid Open Roll for "..item.." (line: "..line_count..")");
			break;
		elseif not (roll_res == "TRUE" or roll_res == "FALSE") then
			valid = false;
			SKC:Error("Invalid Roll Reserved for "..item.." (line: "..line_count..")");
			break;
		elseif not (de == "TRUE" or de == "FALSE") then
			valid = false;
			SKC:Error("Invalid Disenchant for "..item.." (line: "..line_count..")");
			break;
		end
		-- check if no SK or ROLL option
		if sk_list == "NONE" and open_roll == "FALSE" then
			valid = false;
			SKC:Error(item.." (line: "..line_count..") cannot have SK List NONE and Open Roll FALSE");
			break;
		end
		-- check if SK List is NONE and sk_res is TRUE
		if sk_list == "NONE" and sk_res == "TRUE" then
			valid = false;
			SKC:Error(item.." (line: "..line_count..") cannot have SK List NONE and SK Reserved TRUE");
			break;
		end
		-- check if open_roll is FALSE and roll_res is TRUE
		if open_roll == "FALSE" and roll_res == "TRUE" then
			valid = false;
			SKC:Error(item.." (line: "..line_count..") cannot have Open Roll FALSE and Roll Reserved TRUE");
			break;
		end
		-- Check if item imported is an item with a comma in the name
		if SKC.ITEMS_WITH_COMMA[item] ~= nil then
			-- replace item name with actual name
			item = SKC.ITEMS_WITH_COMMA[item];
		end
		-- write meta data for item
		temp_lp.items[item] = Prio:new(nil);
		temp_lp.items[item].sk_list = sk_list;
		temp_lp.items[item].sk_res = SKC:BoolOut(sk_res);
		temp_lp.items[item].open_roll = SKC:BoolOut(open_roll);
		temp_lp.items[item].roll_res = SKC:BoolOut(roll_res);
		temp_lp.items[item].de = SKC:BoolOut(de);
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
			temp_lp.items[item].prio[spec_class_cnt] = val;
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
				temp_lp.items[set_item] = SKC:DeepCopy(temp_lp.items[armor_set]);
			end
			-- remove armor set itself from database
			temp_lp.items[armor_set] = nil;
		end
		line_count = line_count + 1;
	end
	if not valid then
		return;
	end
	-- copy temp variable
	SKC.db.char.LP = SKC:DeepCopy(temp_lp)
	-- update edit timestamp to ensure sync
	SKC.db.char.LP.edit_ts = time();
	SKC:Print("Loot Prio Import Complete");
	SKC:Print(SKC.db.char.LP:length().." items added");
	-- Refresh
	SKC:RefreshStatus();
	SKC:ManageLootWindow();
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
	SKC.CSVGUI[name]:Hide();
	return;
end

local function OnClick_ImportGuildData()
	-- imports GuildData CSV to database
	-- get text
	local name = "Guild Data Import";
	local txt = SKC.CSVGUI[name].EditBox:GetText();
	local line = nil;
	local txt_rem = txt;
	local line_count = 1;
	-- check if first row is header
	line = strsplit(",",txt_rem,2);
	if line == "Character Name" then
		-- header --> skip
		line, txt_rem = strsplit("\n",txt_rem,2);
		line_count = line_count + 1;
	end
	-- collect data and verify
	local valid = true;
	local char_name_array = {};
	local char_name_map = {};
	local class_array = {};
	local spec_array = {};
	local guild_role_array = {};
	local status_array = {};
	local import_cnt = 0;
	while txt_rem ~= nil do
		line, txt_rem = strsplit("\n",txt_rem,2);
		local char_name, spec, guild_role, status = strsplit(",",line,4);
		-- check validity of char_name
		if char_name == nil or char_name == "" or char_name == " " then
			SKC:Error("Missing character name on line "..line_count);
			valid = false;
		elseif not SKC.db.char.GD:Exists(char_name) then
			SKC:Error(char_name.." is not in the current GuildData");
			valid = false;
		else
			char_name_map[char_name] = true;
			-- get class
			local class = SKC.db.char.GD:GetClass(char_name);
			-- check validity of spec
			if spec == nil or spec == "" or spec == " " then
				SKC:Error("Spec is missing for character "..char_name);
				valid = false;
			elseif SKC.CLASSES[class].Specs[spec] == nil then
				SKC:Error(spec.." is not a valid Spec for character "..char_name.." of class "..class);
				valid = false;
			else
				-- check validity of guild_role
				if guild_role == nil or guild_role == "" or guild_role == "" then
					SKC:Error("Guild Role is missing for character "..char_name);
					valid = false;
				elseif SKC.CHARACTER_DATA["Guild Role"].OPTIONS[guild_role] == nil then
					SKC:Error(guild_role.." is not a valid Guild Role for character "..char_name);
					valid = false;
				else
					-- check validity of status
					if status == nil or status == "" or status == " " then
						SKC:Error("Status is missing for character "..char_name);
						valid = false;
					elseif SKC.CHARACTER_DATA["Status"].OPTIONS[status] == nil then
						SKC:Error(status.." is not a valid Status for character "..char_name);
						valid = false;
					else
						-- valid -> store
						import_cnt = import_cnt + 1;
						char_name_array[import_cnt] = char_name;
						class_array[import_cnt] = class;
						spec_array[import_cnt] = spec;
						guild_role_array[import_cnt] = guild_role;
						status_array[import_cnt] = status;
					end
				end
			end			
		end
		-- increment line
		line_count = line_count + 1;
	end
	-- confirm that every member of current GuildData is in import
	local guild_cnt = 0;
	for char_name_gd,_ in pairs(SKC.db.char.GD.data) do
		guild_cnt = guild_cnt + 1;
		if not char_name_map[char_name_gd] then
			SKC:Error(char_name_gd.." is missing from your import");
			valid = false;
		end
	end
	if not valid then
		SKC:Error("Guild Data not imported");
		return;
	end
	if import_cnt ~= guild_cnt then
		SKC:Error("Import has "..import_cnt.." members but Guild Data has "..guild_cnt.." members");
		SKC:Error("Guild Data not imported");
		return;
	end
	-- completely valid, store into guild data
	SKC.db.char.GD = GuildData:new();
	for idx,char_name in ipairs(char_name_array) do
		SKC.db.char.GD:Add(char_name,class_array[idx]);
		SKC.db.char.GD:SetData(char_name,"Spec",spec_array[idx]);
		SKC.db.char.GD:SetData(char_name,"Guild Role",guild_role_array[idx]);
		SKC.db.char.GD:SetData(char_name,"Status",status_array[idx]);
	end
	SKC:Print("Guild Data Import Complete");
	SKC:PopulateData();
	-- close import GUI
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
	local sync_status = self:GetSyncStatus()
	if sync_status.val == self.SYNC_STATUS_ENUM.READING.val then
		self:Error("Please wait for sync to complete");
		return;
	end
	if name == "Loot Prio Import" then
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
	elseif name == "Guild Data Import" then
		-- instantiate frame
		self:CreateCSVGUI(name,true);
		self.CSVGUI[name]:SetShown(true);
		self.CSVGUI[name].ImportBtn:SetScript("OnMouseDown",OnClick_ImportGuildData);
	end
	return;
end

function SKC:ExportLog()
    if not self:isLO() then
        self:Error("You must be a loot officer to do that");
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

function SKC:ExportGuildData()
	local name = "Guild Data Export";
	-- instantiate frame
    self:CreateCSVGUI(name,false);
	self.CSVGUI[name]:SetShown(true);
	-- scan guild data and construct output
	local output = "Character Name,Spec,Guild Role,Status\n"
	for char_name,c_data in pairs(self.db.char.GD.data) do
		output = output..char_name..","..self.db.char.GD:GetData(char_name,"Spec")..","..self.db.char.GD:GetData(char_name,"Guild Role")..","..self.db.char.GD:GetData(char_name,"Status").."\n";
	end
	-- add data to export
	self.CSVGUI[name].EditBox:SetText(output);
	self.CSVGUI[name].EditBox:HighlightText();
end