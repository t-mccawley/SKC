--------------------------------------
-- MAIN GUI
--------------------------------------
-- Main SKC GUI
--------------------------------------
-- EVENT FUNCTIONS
--------------------------------------
function OnMouseWheel_ScrollFrame(self,delta)
    -- delta: 1 scroll up, -1 scroll down
	-- value at top is 0, value at bottom is size of child
	-- scroll so that one wheel is 3 SK cards
	local scroll_range = self:GetVerticalScrollRange();
	local inc = 3 * (SKC.UI_DIMS.SK_CARD_HEIGHT + SKC.UI_DIMS.SK_CARD_SPACING)
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (inc*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

function OnCheck_FilterFunction(self)
	SKC.db.char.FS[self.text:GetText()] = self:GetChecked();
	SKC:UpdateSKUI();
	return;
end

local function OnLoad_EditDropDown_Spec(self)
	local class = SKC.MainGUI["Details_border"]["Class"].Data:GetText();
	for key,value in pairs(SKC.CLASSES[class].Specs) do
		UIDropDownMenu_AddButton(value);
	end
	return;
end

local function OnLoad_EditDropDown_GuildRole(self)
	UIDropDownMenu_AddButton(SKC.CHARACTER_DATA["Guild Role"].OPTIONS.None);
	UIDropDownMenu_AddButton(SKC.CHARACTER_DATA["Guild Role"].OPTIONS.Disenchanter);
	UIDropDownMenu_AddButton(SKC.CHARACTER_DATA["Guild Role"].OPTIONS.Banker);
	return;
end

local function OnLoad_EditDropDown_Status(self)
	UIDropDownMenu_AddButton(SKC.CHARACTER_DATA.Status.OPTIONS.Alt);
	UIDropDownMenu_AddButton(SKC.CHARACTER_DATA.Status.OPTIONS.Main);
	return;
end

local function OnClick_EditDetails(self, button)
	-- Manages drop down menu that is generated for edit buttons
	-- Triggers when the edit button is clicked
	if not self:IsEnabled() then return end
	-- self.MainGUI.EditFrame:Show();
	local ID = self:GetID();
	-- Populate drop down options
	local field;
	if ID == 3 then
		field = "Spec";
		if SKC.event_states.DropDownID ~= ID then UIDropDownMenu_Initialize(SKC.MainGUI["Details_border"][field].DD,OnLoad_EditDropDown_Spec) end
	elseif ID == 5 then
		-- Guild Role
		field = "Guild Role";
		if SKC.event_states.DropDownID ~= ID then UIDropDownMenu_Initialize(SKC.MainGUI["Details_border"][field].DD,OnLoad_EditDropDown_GuildRole) end
	elseif ID == 6 then
		-- Status
		field = "Status";
		if SKC.event_states.DropDownID ~= ID then UIDropDownMenu_Initialize(SKC.MainGUI["Details_border"][field].DD,OnLoad_EditDropDown_Status) end
	else
		SKC:Error("Menu not found.");
		return;
	end
	ToggleDropDownMenu(1, nil, SKC.MainGUI["Details_border"][field].DD, SKC.MainGUI["Details_border"][field].DD, 0, 0);
	if SKC.event_states.DropDownID == ID then
		SKC.event_states.DropDownID = 0;
	else
		SKC.event_states.DropDownID = ID;
	end
	return;
end

local function OnClick_SK_Card(self, button)
	-- populates details frame for given sk card character
	if button=='LeftButton' and self.Text:GetText() ~= nill and SKC.event_states.DropDownID == 0 and not SKC.event_states.SetSKInProgress then
		-- Populate data
		SKC:RefreshDetails(self.Text:GetText());
		-- Enable edit buttons
		SKC:UpdateDetailsButtons();
	end
	return;
end

local function OnClick_FullSK(self)
	if self:IsEnabled() then
		SKC.event_states.SetSKInProgress = false;
		local sk_list = SKC.MainGUI["sk_list_border"].Title.Text:GetText();
		-- On click event for full SK of details targeted character
		local name = SKC.MainGUI["Details_border"]["Name"].Data:GetText();
		-- Get initial position
		local prev_pos = SKC.db.char[sk_list]:GetPos(name);
		-- Execute full SK
		local success = SKC.db.char[sk_list]:PushBack(name);
		if success then 
			-- log
			SKC:WriteToLog( 
				SKC.LOG_OPTIONS["Event Type"].Options.ManEdit,
				name,
				"Full SK",
				"",
				sk_list,
				"",
				prev_pos,
				SKC.db.char[sk_list]:GetPos(name),
				"",
				""
			);
			SKC:Print("Full SK on "..SKC:FormatWithClassColor(name));
			-- Refresh SK List
			SKC:UpdateSKUI();
		else
			SKC:Error("Full SK on "..name.." rejected");
		end
	end
	return;
end

local function OnClick_SingleSK(self)
	if self:IsEnabled() then
		SKC.event_states.SetSKInProgress = false;
		-- On click event for full SK of details targeted character
		local name = SKC.MainGUI["Details_border"]["Name"].Data:GetText();
		local sk_list = SKC.MainGUI["sk_list_border"].Title.Text:GetText();
		-- Get initial position
		local prev_pos = SKC.db.char[sk_list]:GetPos(name);
		-- Execute full SK
		local name_below = SKC.db.char[sk_list]:GetBelow(name);
		local success = SKC.db.char[sk_list]:InsertBelow(name,name_below);
		if success then 
			-- log
			SKC:WriteToLog( 
				SKC.LOG_OPTIONS["Event Type"].Options.ManEdit,
				name,
				"Single SK",
				"",
				sk_list,
				"",
				prev_pos,
				SKC.db.char[sk_list]:GetPos(name),
				"",
				""
			);
			SKC:Print("Single SK on "..SKC:FormatWithClassColor(name));
			-- Refresh SK List
			SKC:UpdateSKUI();
		else
			SKC:Error("Single SK on "..name.." rejected");
		end
	end
	return;
end

local function OnClick_SetSK(self)
	-- On click event to set SK position of details targeted character
	-- Prompt user to click desired position number in list
	if self:IsEnabled() then
		SKC.event_states.SetSKInProgress = true;
		local name = SKC.MainGUI["Details_border"]["Name"].Data:GetText();
		SKC:Alert("Click desired position in SK list for "..SKC:FormatWithClassColor(name));
	end
	return;
end

function OnClick_NumberCard(self)
	-- On click event for number card in SK list
	if SKC.event_states.SetSKInProgress and SKC.MainGUI["Details_border"]["Name"].Data ~= nil then
		local name = SKC.MainGUI["Details_border"]["Name"].Data:GetText();
		local new_abs_pos = tonumber(self.Text:GetText());
		local sk_list = SKC.MainGUI["sk_list_border"].Title.Text:GetText();
		-- Get initial position
		local prev_pos = SKC.db.char[sk_list]:GetPos(name);
		-- Set new position
		local success = SKC.db.char[sk_list]:SetByPos(name,new_abs_pos);
		if success then
			-- log
			SKC:WriteToLog( 
				SKC.LOG_OPTIONS["Event Type"].Options.ManEdit,
				name,
				"Set SK",
				"",
				sk_list,
				"",
				prev_pos,
				SKC.db.char[sk_list]:GetPos(name),
				"",
				""
			);
			SKC:Print("Set SK position of "..SKC:FormatWithClassColor(name).." to "..SKC.db.char[sk_list]:GetPos(name));
			-- Refresh SK List
			SKC:UpdateSKUI();
		else
			SKC:Error("Set SK on "..name.." rejected");
		end
		SKC.event_states.SetSKInProgress = false;
	end
	return;
end


local function OnClick_SKListCycle()
	-- cycle SK list when click title
	if SKC.event_states.SetSKInProgress then return end -- reject cycle if SK is being set
	-- cycle through SK lists
	local sk_list = SKC.MainGUI["sk_list_border"].Title.Text:GetText();
	if sk_list == "MSK" then
		SKC.MainGUI["sk_list_border"].Title.Text:SetText("TSK");
	else
		SKC.MainGUI["sk_list_border"].Title.Text:SetText("MSK");
	end
	-- populate data
	SKC:PopulateData();
	-- enable / disable details buttons
	SKC:UpdateDetailsButtons(true);
end
--------------------------------------
-- GUI
--------------------------------------
function SKC:CreateMainGUI()
	-- creates primary GUI for SKC
	self:Debug("CreateMainGUI() start",self.DEV.VERBOSE.GUI);

	-- check if MainGUI already exists
	if self.MainGUI ~= nil then return end

	-- create main frame and make moveable
    self.MainGUI = CreateFrame("Frame", "MainGUI", UIParent, "UIPanelDialogTemplate");
	self.MainGUI:SetSize(self.UI_DIMS.MAIN_WIDTH,self.UI_DIMS.MAIN_HEIGHT);
	self.MainGUI:SetPoint("CENTER");
	self.MainGUI:SetMovable(true)
	self.MainGUI:EnableMouse(true)
	self.MainGUI:RegisterForDrag("LeftButton")
	self.MainGUI:SetScript("OnDragStart", self.MainGUI.StartMoving)
	self.MainGUI:SetScript("OnDragStop", self.MainGUI.StopMovingOrSizing)
	self.MainGUI:SetAlpha(0.8);
	self.MainGUI:SetFrameLevel(0);

	-- Make frame closable with esc
	table.insert(UISpecialFrames, "MainGUI");
	
	-- Add title
    self.MainGUI.Title:ClearAllPoints();
	self.MainGUI.Title:SetPoint("LEFT", MainGUITitleBG, "LEFT", 6, 0);
	self.MainGUI.Title:SetText("SKC ("..GetAddOnMetadata("SKC", "Version")..")");

	-- Create status panel
	local status_border_key = self:CreateUIBorder("Status",self.UI_DIMS.SKC_STATUS_WIDTH,self.UI_DIMS.SKC_STATUS_HEIGHT)
	-- set position
	self.MainGUI[status_border_key]:SetPoint("TOPLEFT", MainGUITitleBG, "TOPLEFT", self.UI_DIMS.MAIN_BORDER_PADDING+5, self.UI_DIMS.MAIN_BORDER_Y_TOP);
	-- create status fields
	local status_fields = {"Status","Synchronization","Loot Prio Items","Loot Officers","Active Instances"};
	for idx,value in ipairs(status_fields) do
		-- fields
		self.MainGUI[status_border_key][value] = CreateFrame("Frame",self.MainGUI[status_border_key])
		self.MainGUI[status_border_key][value].Field = self.MainGUI[status_border_key]:CreateFontString(nil,"ARTWORK");
		self.MainGUI[status_border_key][value].Field:SetFontObject("GameFontNormal");
		self.MainGUI[status_border_key][value].Field:SetPoint("RIGHT",self.MainGUI[status_border_key],"TOPLEFT",130,-20*idx-10);
		self.MainGUI[status_border_key][value].Field:SetText(value..":");
		-- data
		self.MainGUI[status_border_key][value].Data = self.MainGUI[status_border_key]:CreateFontString(nil,"ARTWORK");
		self.MainGUI[status_border_key][value].Data:SetFontObject("GameFontHighlight");
		self.MainGUI[status_border_key][value].Data:SetPoint("CENTER",self.MainGUI[status_border_key][value].Field,"RIGHT",55,0);
	end

	-- Create filter panel
	local filter_border_key = self:CreateUIBorder("Filters",self.UI_DIMS.SK_FILTER_WIDTH,self.UI_DIMS.SK_FILTER_HEIGHT)
	-- set position
	self.MainGUI[filter_border_key]:SetPoint("TOPLEFT", self.MainGUI[status_border_key],"BOTTOMLEFT", 0, self.UI_DIMS.SK_FILTER_Y_OFFST);
	-- create details fields
	local faction_class;
	if UnitFactionGroup("player") == "Horde" then faction_class="Shaman" else faction_class="Paladin" end
	local filter_roles = {"DPS","Healer","Tank","Main","Alt","Live","Druid","Hunter","Mage","Priest","Rogue","Warlock","Warrior",faction_class};
	local num_cols = 3;
	for idx,value in ipairs(filter_roles) do
		if value ~= "SKIP" then
			local row = math.floor((idx - 1) / num_cols); -- zero based
			local col = (idx - 1) % num_cols; -- zero based
			self.MainGUI[filter_border_key][value] = CreateFrame("CheckButton", nil, self.MainGUI[filter_border_key], "UICheckButtonTemplate");
			self.MainGUI[filter_border_key][value]:SetSize(25,25);
			self.MainGUI[filter_border_key][value]:SetChecked(self.db.char.FS[value]);
			self.MainGUI[filter_border_key][value]:SetScript("OnClick",OnCheck_FilterFunction)
			self.MainGUI[filter_border_key][value]:SetPoint("TOPLEFT", self.MainGUI[filter_border_key], "TOPLEFT", 22 + 73*col , -20 + -24*row);
			self.MainGUI[filter_border_key][value].text:SetFontObject("GameFontNormalSmall");
			self.MainGUI[filter_border_key][value].text:SetText(value);
			if idx > 6 then
				-- assign class colors
				self.MainGUI[filter_border_key][value].text:SetTextColor(self.CLASSES[value].color.r,self.CLASSES[value].color.g,self.CLASSES[value].color.b,1.0);
			end
		end
	end
	-- create filter status fields
	-- Shown
	-- filter
	local filter_status_name = "Filter Status";
	self.MainGUI[filter_border_key][filter_status_name] = CreateFrame("Frame",self.MainGUI[filter_border_key]);
	self.MainGUI[filter_border_key][filter_status_name].Field = self.MainGUI[filter_border_key]:CreateFontString(nil,"ARTWORK");
	self.MainGUI[filter_border_key][filter_status_name].Field:SetFontObject("GameFontNormal");
	self.MainGUI[filter_border_key][filter_status_name].Field:SetPoint("BOTTOMLEFT",self.MainGUI[filter_border_key],"BOTTOMLEFT",25,22);
	self.MainGUI[filter_border_key][filter_status_name].Field:SetText(filter_status_name..":");
	-- data
	self.MainGUI[filter_border_key][filter_status_name].Data = self.MainGUI[filter_border_key]:CreateFontString(nil,"ARTWORK");
	self.MainGUI[filter_border_key][filter_status_name].Data:SetFontObject("GameFontHighlight");
	self.MainGUI[filter_border_key][filter_status_name].Data:SetPoint("LEFT",self.MainGUI[filter_border_key][filter_status_name].Field,"RIGHT",10,0);


	-- SK List border
	-- Create Border
	local sk_list_border_key = "sk_list_border";
	self.MainGUI[sk_list_border_key] = CreateFrame("Frame",sk_list_border_key,self.MainGUI,"TranslucentFrameTemplate");
	self.MainGUI[sk_list_border_key]:SetSize(self.UI_DIMS.SK_LIST_WIDTH + 2*self.UI_DIMS.SK_LIST_BORDER_OFFST,self.UI_DIMS.SK_LIST_HEIGHT + 2*self.UI_DIMS.SK_LIST_BORDER_OFFST);
	self.MainGUI[sk_list_border_key].Bg:SetAlpha(0.0);
	-- Create Title
	self.MainGUI[sk_list_border_key].Title = CreateFrame("Frame",title_key,self.MainGUI[sk_list_border_key],"TranslucentFrameTemplate");
	self.MainGUI[sk_list_border_key].Title:SetSize(self.UI_DIMS.SK_TAB_TITLE_CARD_WIDTH,self.UI_DIMS.SK_TAB_TITLE_CARD_HEIGHT);
	self.MainGUI[sk_list_border_key].Title:SetPoint("BOTTOM",self.MainGUI[sk_list_border_key],"TOP",0,-20);
	self.MainGUI[sk_list_border_key].Title.Text = self.MainGUI[sk_list_border_key].Title:CreateFontString(nil,"ARTWORK")
	self.MainGUI[sk_list_border_key].Title.Text:SetFontObject("GameFontNormal")
	self.MainGUI[sk_list_border_key].Title.Text:SetPoint("CENTER",0,0)
	self.MainGUI[sk_list_border_key].Title.Text:SetText("MSK")
	self.MainGUI[sk_list_border_key].Title:SetScript("OnMouseDown",OnClick_SKListCycle);
	-- set position
	self.MainGUI[sk_list_border_key]:SetPoint("TOPLEFT", self.MainGUI[status_border_key], "TOPRIGHT", self.UI_DIMS.MAIN_BORDER_PADDING, 0);

	-- Create SK list panel
	self.MainGUI.sk_list = CreateFrame("Frame",sk_list,self.MainGUI,"InsetFrameTemplate");
	self.MainGUI.sk_list:SetSize(self.UI_DIMS.SK_LIST_WIDTH,self.UI_DIMS.SK_LIST_HEIGHT);
	self.MainGUI.sk_list:SetPoint("TOP",self.MainGUI[sk_list_border_key],"TOP",0,-self.UI_DIMS.SK_LIST_BORDER_OFFST);

	-- Create scroll frame on SK list
	self.MainGUI.sk_list.SK_List_SF = CreateFrame("ScrollFrame","SK_List_SF",self.MainGUI.sk_list,"UIPanelScrollFrameTemplate2");
	self.MainGUI.sk_list.SK_List_SF:SetPoint("TOPLEFT",self.MainGUI.sk_list,"TOPLEFT",0,-2);
	self.MainGUI.sk_list.SK_List_SF:SetPoint("BOTTOMRIGHT",self.MainGUI.sk_list,"BOTTOMRIGHT",0,2);
	self.MainGUI.sk_list.SK_List_SF:SetClipsChildren(true);
	self.MainGUI.sk_list.SK_List_SF:SetScript("OnMouseWheel",OnMouseWheel_ScrollFrame);
	self.MainGUI.sk_list.SK_List_SF.ScrollBar:SetPoint("TOPLEFT",self.MainGUI.sk_list.SK_List_SF,"TOPRIGHT",-22,-21);

	-- Create scroll child
	local scroll_child = CreateFrame("Frame",nil,self.MainGUI.sk_list.SK_List_SF);
	scroll_child:SetSize(self.UI_DIMS.SK_LIST_WIDTH,self:GetScrollMax());
	self.MainGUI.sk_list.SK_List_SF:SetScrollChild(scroll_child);

	-- Create SK cards
	self.MainGUI.sk_list.NumberFrame = {};
	self.MainGUI.sk_list.NameFrame = {};
	for idx = 1, self.UI_DIMS.MAX_SK_CARDS do
		-- Create number frames
		self.MainGUI.sk_list.NumberFrame[idx] = CreateFrame("Frame",nil,self.MainGUI.sk_list.SK_List_SF,"InsetFrameTemplate");
		self.MainGUI.sk_list.NumberFrame[idx]:SetSize(30,self.UI_DIMS.SK_CARD_HEIGHT);
		self.MainGUI.sk_list.NumberFrame[idx]:SetPoint("TOPLEFT",self.MainGUI.sk_list.SK_List_SF:GetScrollChild(),"TOPLEFT",8,-1*((idx-1)*(self.UI_DIMS.SK_CARD_HEIGHT + self.UI_DIMS.SK_CARD_SPACING) + self.UI_DIMS.SK_CARD_SPACING));
		self.MainGUI.sk_list.NumberFrame[idx].Text = self.MainGUI.sk_list.NumberFrame[idx]:CreateFontString(nil,"ARTWORK")
		self.MainGUI.sk_list.NumberFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		self.MainGUI.sk_list.NumberFrame[idx].Text:SetPoint("CENTER",0,0)
		self.MainGUI.sk_list.NumberFrame[idx]:SetScript("OnMouseDown",OnClick_NumberCard);
		self.MainGUI.sk_list.NumberFrame[idx]:Hide();
		-- Create named card frames
		self.MainGUI.sk_list.NameFrame[idx] = CreateFrame("Frame",nil,self.MainGUI.sk_list.SK_List_SF,"InsetFrameTemplate");
		self.MainGUI.sk_list.NameFrame[idx]:SetSize(self.UI_DIMS.SK_CARD_WIDTH,self.UI_DIMS.SK_CARD_HEIGHT);
		self.MainGUI.sk_list.NameFrame[idx]:SetPoint("TOPLEFT",self.MainGUI.sk_list.SK_List_SF:GetScrollChild(),"TOPLEFT",43,-1*((idx-1)*(self.UI_DIMS.SK_CARD_HEIGHT + self.UI_DIMS.SK_CARD_SPACING) + self.UI_DIMS.SK_CARD_SPACING));
		self.MainGUI.sk_list.NameFrame[idx].Text = self.MainGUI.sk_list.NameFrame[idx]:CreateFontString(nil,"ARTWORK")
		self.MainGUI.sk_list.NameFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		self.MainGUI.sk_list.NameFrame[idx].Text:SetPoint("CENTER",0,0)
		-- Add texture for color
		self.MainGUI.sk_list.NameFrame[idx].bg = self.MainGUI.sk_list.NameFrame[idx]:CreateTexture(nil,"BACKGROUND");
		self.MainGUI.sk_list.NameFrame[idx].bg:SetAllPoints(true);
		-- Bind function for click event
		self.MainGUI.sk_list.NameFrame[idx]:SetScript("OnMouseDown",OnClick_SK_Card);
		self.MainGUI.sk_list.NameFrame[idx]:Hide();
	end

	-- Create details panel
	self.event_states.DropDownID = 0; -- reset drop down options state
	local details_border_key = self:CreateUIBorder("Details",self.UI_DIMS.SK_DETAILS_WIDTH,self.UI_DIMS.SK_DETAILS_HEIGHT);
	-- set position
	self.MainGUI[details_border_key]:SetPoint("TOPLEFT", self.MainGUI[sk_list_border_key], "TOPRIGHT", self.UI_DIMS.MAIN_BORDER_PADDING, 0);
	-- create details fields
	local details_fields = {"Name","Class","Spec","Raid Role","Guild Role","Status"};
	for idx,value in ipairs(details_fields) do
		-- fields
		self.MainGUI[details_border_key][value] = CreateFrame("Frame",self.MainGUI[details_border_key])
		self.MainGUI[details_border_key][value].Field = self.MainGUI[details_border_key]:CreateFontString(nil,"ARTWORK");
		self.MainGUI[details_border_key][value].Field:SetFontObject("GameFontNormal");
		self.MainGUI[details_border_key][value].Field:SetPoint("RIGHT",self.MainGUI[details_border_key],"TOPLEFT",100,-20*idx-10);
		self.MainGUI[details_border_key][value].Field:SetText(value..":");
		-- data
		self.MainGUI[details_border_key][value].Data = self.MainGUI[details_border_key]:CreateFontString(nil,"ARTWORK");
		self.MainGUI[details_border_key][value].Data:SetFontObject("GameFontHighlight");
		self.MainGUI[details_border_key][value].Data:SetPoint("CENTER",self.MainGUI[details_border_key][value].Field,"RIGHT",45,0);
		if idx == 3 or 
		   idx == 5 or
		   idx == 6 or
		   idx == 7 then
			-- edit buttons
			self.MainGUI[details_border_key][value].Btn = CreateFrame("Button", nil, self.MainGUI, "GameMenuButtonTemplate");
			self.MainGUI[details_border_key][value].Btn:SetID(idx);
			self.MainGUI[details_border_key][value].Btn:SetPoint("LEFT",self.MainGUI[details_border_key][value].Field,"RIGHT",95,0);
			self.MainGUI[details_border_key][value].Btn:SetSize(40, 20);
			self.MainGUI[details_border_key][value].Btn:SetText("Edit");
			self.MainGUI[details_border_key][value].Btn:SetNormalFontObject("GameFontNormalSmall");
			self.MainGUI[details_border_key][value].Btn:SetHighlightFontObject("GameFontHighlightSmall");
			self.MainGUI[details_border_key][value].Btn:SetScript("OnMouseDown",OnClick_EditDetails);
			self.MainGUI[details_border_key][value].Btn:Disable();
			-- associated drop down menu
			self.MainGUI[details_border_key][value].DD = CreateFrame("Frame",nil, self.MainGUI, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetAnchor(self.MainGUI[details_border_key][value].DD, 0, 0, "TOPLEFT", self.MainGUI[details_border_key][value].Btn, "TOPRIGHT");
		end
	end

	-- Add SK buttons
	-- full SK
	self.MainGUI[details_border_key].manual_full_sk_btn = CreateFrame("Button", nil, self.MainGUI, "GameMenuButtonTemplate");
	self.MainGUI[details_border_key].manual_full_sk_btn:SetPoint("BOTTOM",self.MainGUI[details_border_key],"BOTTOM",0,15);
	self.MainGUI[details_border_key].manual_full_sk_btn:SetSize(self.UI_DIMS.BTN_WIDTH, self.UI_DIMS.BTN_HEIGHT);
	self.MainGUI[details_border_key].manual_full_sk_btn:SetText("Full SK");
	self.MainGUI[details_border_key].manual_full_sk_btn:SetNormalFontObject("GameFontNormal");
	self.MainGUI[details_border_key].manual_full_sk_btn:SetHighlightFontObject("GameFontHighlight");
	self.MainGUI[details_border_key].manual_full_sk_btn:SetScript("OnMouseDown",OnClick_FullSK);
	self.MainGUI[details_border_key].manual_full_sk_btn:Disable();
	-- single SK
	self.MainGUI[details_border_key].manual_single_sk_btn = CreateFrame("Button", nil, self.MainGUI, "GameMenuButtonTemplate");
	self.MainGUI[details_border_key].manual_single_sk_btn:SetPoint("RIGHT",self.MainGUI[details_border_key].manual_full_sk_btn,"LEFT",-5,0);
	self.MainGUI[details_border_key].manual_single_sk_btn:SetSize(self.UI_DIMS.BTN_WIDTH, self.UI_DIMS.BTN_HEIGHT);
	self.MainGUI[details_border_key].manual_single_sk_btn:SetText("Single SK");
	self.MainGUI[details_border_key].manual_single_sk_btn:SetNormalFontObject("GameFontNormal");
	self.MainGUI[details_border_key].manual_single_sk_btn:SetHighlightFontObject("GameFontHighlight");
	self.MainGUI[details_border_key].manual_single_sk_btn:SetScript("OnMouseDown",OnClick_SingleSK);
	self.MainGUI[details_border_key].manual_single_sk_btn:Disable();
	-- set SK
	self.MainGUI[details_border_key].manual_set_sk_btn = CreateFrame("Button", nil, self.MainGUI, "GameMenuButtonTemplate");
	self.MainGUI[details_border_key].manual_set_sk_btn:SetPoint("LEFT",self.MainGUI[details_border_key].manual_full_sk_btn,"RIGHT",5,0);
	self.MainGUI[details_border_key].manual_set_sk_btn:SetSize(self.UI_DIMS.BTN_WIDTH, self.UI_DIMS.BTN_HEIGHT);
	self.MainGUI[details_border_key].manual_set_sk_btn:SetText("Set SK");
	self.MainGUI[details_border_key].manual_set_sk_btn:SetNormalFontObject("GameFontNormal");
	self.MainGUI[details_border_key].manual_set_sk_btn:SetHighlightFontObject("GameFontHighlight");
	self.MainGUI[details_border_key].manual_set_sk_btn:SetScript("OnMouseDown",OnClick_SetSK);
	self.MainGUI[details_border_key].manual_set_sk_btn:Disable();
    
	self.MainGUI:Hide();

	self:Debug("CreateMainGUI() complete",self.DEV.VERBOSE.GUI);
	return;
end

function SKC:CreateUIBorder(title,width,height)
	-- Create Border
	local border_key = title.."_border";
	self.MainGUI[border_key] = CreateFrame("Frame",border_key,self.MainGUI,"TranslucentFrameTemplate");
	self.MainGUI[border_key]:SetSize(width,height);
	self.MainGUI[border_key].Bg:SetAlpha(0.0);
	-- Create Title
	local title_key = "title";
	self.MainGUI[border_key][title_key] = CreateFrame("Frame",title_key,self.MainGUI[border_key],"TranslucentFrameTemplate");
	self.MainGUI[border_key][title_key]:SetSize(self.UI_DIMS.SK_TAB_TITLE_CARD_WIDTH,self.UI_DIMS.SK_TAB_TITLE_CARD_HEIGHT);
	self.MainGUI[border_key][title_key]:SetPoint("BOTTOM",self.MainGUI[border_key],"TOP",0,-20);
	self.MainGUI[border_key][title_key].Text = self.MainGUI[border_key][title_key]:CreateFontString(nil,"ARTWORK")
	self.MainGUI[border_key][title_key].Text:SetFontObject("GameFontNormal")
	self.MainGUI[border_key][title_key].Text:SetPoint("CENTER",0,0)
	self.MainGUI[border_key][title_key].Text:SetText(title)

	return border_key
end

function SKC:GetScrollMax()
	return((self.UnFilteredCnt)*(self.UI_DIMS.SK_CARD_HEIGHT + self.UI_DIMS.SK_CARD_SPACING));
end

function SKC:HideSKCards()
	-- Hide all cards
	if not self:CheckMainGUICreated() then return end
	local sk_list = self.MainGUI["sk_list_border"].Title.Text:GetText();
	for idx = 1, self.UI_DIMS.MAX_SK_CARDS do
		self.MainGUI.sk_list.NumberFrame[idx]:Hide();
		self.MainGUI.sk_list.NameFrame[idx]:Hide();
	end
	return;
end

function SKC:UpdateSKUI()
	-- populates the SK list
	self:Debug("UpdateSKUI() start",self.DEV.VERBOSE.GUI);
	if not self:CheckMainGUICreated() then return end
	if not self:CheckAddonLoaded(COMM_VERBOSE) then return end
	
	self:HideSKCards();

	-- Fetch SK list
	local sk_list = self.MainGUI["sk_list_border"].Title.Text:GetText();
	local print_order = self.db.char[sk_list]:ReturnList();

	-- Confirm that every character in SK list is also in GuildData
	if not self:CheckSKinGuildData(sk_list,print_order) then return end

	-- Populate non filtered cards
	local idx = 1;
	local max_cnt = 0;
	for pos,name in ipairs(print_order) do
		local class_tmp = self.db.char.GD:GetData(name,"Class");
		local raid_role_tmp = self.db.char.GD:GetData(name,"Raid Role");
		local status_tmp = self.db.char.GD:GetData(name,"Status");
		local live_tmp = self.db.char[sk_list]:GetLive(name);
		-- only add cards to list which are not being filtered
		if self.db.char.FS[class_tmp] and 
		   self.db.char.FS[raid_role_tmp] and
		   self.db.char.FS[status_tmp] and
		   (live_tmp or (not live_tmp and not self.db.char.FS.Live)) then
			-- Add position number text
			self.MainGUI.sk_list.NumberFrame[idx].Text:SetText(pos);
			self.MainGUI.sk_list.NumberFrame[idx]:Show();
			-- Add name text
			self.MainGUI.sk_list.NameFrame[idx].Text:SetText(name)
			-- create class color background
			self.MainGUI.sk_list.NameFrame[idx].bg:SetColorTexture(self.CLASSES[class_tmp].color.r,self.CLASSES[class_tmp].color.g,self.CLASSES[class_tmp].color.b,0.25);
			self.MainGUI.sk_list.NameFrame[idx]:Show();
			-- increment
			idx = idx + 1;
		end
		-- increment
		max_cnt = max_cnt + 1;
	end
	self.UnFilteredCnt = idx; -- 1 larger than max cards
	-- update scroll length
	self.MainGUI.sk_list.SK_List_SF:GetScrollChild():SetSize(self.UI_DIMS.SK_LIST_WIDTH,self:GetScrollMax());
	-- update filter status
	local filter_status_name = "Filter Status";
	self.MainGUI["Filters_border"][filter_status_name].Data:SetText((self.UnFilteredCnt - 1).." / "..max_cnt);
	self:Debug("UpdateSKUI() end",self.DEV.VERBOSE.GUI);
	return;
end

function SKC:RefreshStatus()
	-- refresh variable and update GUI
	self:Activate();
	if not self:CheckMainGUICreated() then return end
	self.MainGUI["Status_border"]["Status"].Data:SetText(self.Status.text);
	self.MainGUI["Status_border"]["Status"].Data:SetTextColor(unpack(self.Status.color));
	local sync_status = self:GetSyncStatus();
	self.MainGUI["Status_border"]["Synchronization"].Data:SetText(sync_status.text);
	self.MainGUI["Status_border"]["Synchronization"].Data:SetTextColor(unpack(sync_status.color));
	self.MainGUI["Status_border"]["Loot Prio Items"].Data:SetText(self.db.char.LP:length().." items");
	self.MainGUI["Status_border"]["Loot Officers"].Data:SetText(self.db.char.GLP:GetNumLootOfficers());
	self.MainGUI["Status_border"]["Active Instances"].Data:SetText(self.db.char.GLP:GetNumActiveInstances());
	-- manage loot logging
	self:ManageLogging();
	return;
end

function SKC:RefreshDetails(name)
	-- populates the details fields
	if not self:CheckMainGUICreated() then return end
	local fields = {"Name","Class","Spec","Raid Role","Guild Role","Status"};
	if name == nil then
		-- reset
		for _,field in pairs(fields) do
			self.MainGUI["Details_border"][field].Data:SetText(nil);
		end
		-- Initialize with instructions
		self.MainGUI["Details_border"]["Name"].Data:SetText("            Click on a character."); -- lol, so elegant
	else
		for _,field in pairs(fields) do
			self.MainGUI["Details_border"][field].Data:SetText(self.db.char.GD:GetData(name,field));
		end
		-- updated class color
		local class_color = self.CLASSES[self.db.char.GD:GetData(name,"Class")].color;
		self.MainGUI["Details_border"]["Class"].Data:SetTextColor(class_color.r,class_color.g,class_color.b,1.0);
	end
	return;
end

function SKC:PopulateData(name)
	-- Populates GUI with data (if GUI already exists)
	self:Debug("PopulateData()",self.DEV.VERBOSE.GUI);
	if not self:CheckAddonLoaded() then return end
	if not self:CheckMainGUICreated() then return end
	-- Update Status
	self:RefreshStatus();
	-- Refresh details
	self:RefreshDetails(name);
	-- Update SK cards
	self:UpdateSKUI();
	-- Reset Set SK Flag
	self.event_states.SetSKInProgress = false;
	return;
end

function SKC:UpdateDetailsButtons(disable)
	-- disable / enable buttons in details frame appropriately for player privileges
	if not self:CheckMainGUICreated() then return end
	-- Enable edit buttons
	if disable then
		self.MainGUI["Details_border"]["Spec"].Btn:Disable();
		self.MainGUI["Details_border"]["Guild Role"].Btn:Disable();
		self.MainGUI["Details_border"]["Status"].Btn:Disable();
		self.MainGUI["Details_border"].manual_single_sk_btn:Disable();
		self.MainGUI["Details_border"].manual_full_sk_btn:Disable();
		self.MainGUI["Details_border"].manual_set_sk_btn:Disable();
	else
		if self:isGL() then
			self.MainGUI["Details_border"]["Spec"].Btn:Enable();
			self.MainGUI["Details_border"]["Guild Role"].Btn:Enable();
			self.MainGUI["Details_border"]["Status"].Btn:Enable();
		else
			self.MainGUI["Details_border"]["Spec"].Btn:Disable();
			self.MainGUI["Details_border"]["Guild Role"].Btn:Disable();
			self.MainGUI["Details_border"]["Status"].Btn:Disable();
		end
		if self:isGL() or self:isMLO() then
			self.MainGUI["Details_border"].manual_single_sk_btn:Enable();
			self.MainGUI["Details_border"].manual_full_sk_btn:Enable();
			self.MainGUI["Details_border"].manual_set_sk_btn:Enable();
		else
			self.MainGUI["Details_border"].manual_single_sk_btn:Disable();
			self.MainGUI["Details_border"].manual_full_sk_btn:Disable();
			self.MainGUI["Details_border"].manual_set_sk_btn:Disable();
		end
	end
	return
end