--------------------------------------
-- MAIN GUI
--------------------------------------
--------------------------------------
-- HELPER FUNCTIONS
--------------------------------------
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
--------------------------------------
-- GUI
--------------------------------------
function SKC:CreateMainGUI()
	-- creates primary GUI for SKC
	self:Debug("CreateUIMain() start",SKC.DEV.VERBOSE.GUI);

	-- check if MainGUI already exists
	if self:MainGUI ~= nil then return end

	-- create main frame and make moveable
    self:MainGUI = CreateFrame("Frame", "MainGUI", UIParent, "UIPanelDialogTemplate");
	self:MainGUI:SetSize(UI_DIMENSIONS.MAIN_WIDTH,UI_DIMENSIONS.MAIN_HEIGHT);
	self:MainGUI:SetPoint("CENTER");
	self:MainGUI:SetMovable(true)
	self:MainGUI:EnableMouse(true)
	self:MainGUI:RegisterForDrag("LeftButton")
	self:MainGUI:SetScript("OnDragStart", self:MainGUI.StartMoving)
	self:MainGUI:SetScript("OnDragStop", self:MainGUI.StopMovingOrSizing)
	self:MainGUI:SetAlpha(0.8);
	self:MainGUI:SetFrameLevel(0);

	-- Make frame closable with esc
	table.insert(UISpecialFrames, "MainGUI");
	
	-- Add title
    self:MainGUI.Title:ClearAllPoints();
	self:MainGUI.Title:SetPoint("LEFT", MainGUITitleBG, "LEFT", 6, 0);
	self:MainGUI.Title:SetText("SKC ("..GetAddOnMetadata("SKC", "Version")..")");

	-- Create status panel
	local status_border_key = CreateUIBorder("Status",UI_DIMENSIONS.SKC_STATUS_WIDTH,UI_DIMENSIONS.SKC_STATUS_HEIGHT)
	-- set position
	self:MainGUI[status_border_key]:SetPoint("TOPLEFT", MainGUITitleBG, "TOPLEFT", UI_DIMENSIONS.MAIN_BORDER_PADDING+5, UI_DIMENSIONS.MAIN_BORDER_Y_TOP);
	-- create status fields
	local status_fields = {"Status","Synchronization","Loot Prio Items","Loot Officers"};
	for idx,value in ipairs(status_fields) do
		-- fields
		self:MainGUI[status_border_key][value] = CreateFrame("Frame",self:MainGUI[status_border_key])
		self:MainGUI[status_border_key][value].Field = self:MainGUI[status_border_key]:CreateFontString(nil,"ARTWORK");
		self:MainGUI[status_border_key][value].Field:SetFontObject("GameFontNormal");
		self:MainGUI[status_border_key][value].Field:SetPoint("RIGHT",self:MainGUI[status_border_key],"TOPLEFT",130,-20*idx-10);
		self:MainGUI[status_border_key][value].Field:SetText(value..":");
		-- data
		self:MainGUI[status_border_key][value].Data = self:MainGUI[status_border_key]:CreateFontString(nil,"ARTWORK");
		self:MainGUI[status_border_key][value].Data:SetFontObject("GameFontHighlight");
		self:MainGUI[status_border_key][value].Data:SetPoint("CENTER",self:MainGUI[status_border_key][value].Field,"RIGHT",55,0);
	end

	-- Create filter panel
	-- TODO STOPPED HERE
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