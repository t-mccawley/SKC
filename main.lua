--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...; -- returns name of addon and namespace (core)
core.Main = {}; -- adds Main table to addon namespace

local Main = core.Main; -- assignment by reference in lua, ugh
Main.VarsLoaded = false;
local UIMain;

--------------------------------------
-- DEFAULTS (usually a database!)
--------------------------------------
local DEFAULTS = {
	THEME = {
		r = 0, 
		g = 0.8, -- 204/255
		b = 1,
		hex = "00ccff"
	},
	MAIN_WIDTH = 350,
	MAIN_HEIGHT = 600,
	SK_LIST_WIDTH = 150,
	SK_LIST_HEIGHT = 325,
	SK_CARD_SPACING = 5,
	SK_CARD_WIDTH = 100,
	SK_CARD_HEIGHT = 20,
}

--------------------------------------
-- Main functions
--------------------------------------
function Main:VarLoad()
	Main.VarsLoaded = true;
	if (SKC_DB == nil or #SKC_DB == 0) then
		SKC_DB = {}
	end
	SKC_DB.InGuild = IsInGuild();
	SKC_DB.NumGuildMembers = GetNumGuildMembers()
end

function Main:PopulateSK_Cards()
	-- Variables not yet loaded, return
	if not Main.VarsLoaded then return end

	if SKC_DB.InGuild then
		SKC_DB.SK_List = {}
		local order = 1;
		for idx = 1, SKC_DB.NumGuildMembers do
			full_name, rank, rankIndex, level, class, zone, note, 
			officernote, online, status, classFileName, 
			achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(idx);
			if level == 60 then
				local name_tmp,_ = strsplit("-",full_name,2);
				SKC_DB.SK_List[name_tmp] = {};
				SKC_DB.SK_List[name_tmp]["name"] = name_tmp;
				SKC_DB.SK_List[name_tmp]["order"] = order;
				order = order + 1;
			end
		end
	else
		DEFAULT_CHAT_FRAME:AddMessage("SKC Error: You are not in a guild!");
		return;
	end

	-- Create SK card
	local print_order = {}
	for key, value in pairs(SKC_DB.SK_List) do
		print_order[value.order] = value.name;
	end
	local i_card = 0;
	for key,value in ipairs(print_order) do
		UIMain.SK_List.SK_Card = CreateFrame("Frame",nil,UIMain.SK_List.SK_List_SF,"InsetFrameTemplate3");
		UIMain.SK_List.SK_Card:SetSize(DEFAULTS.SK_CARD_WIDTH,DEFAULTS.SK_CARD_HEIGHT);
		UIMain.SK_List.SK_Card:SetPoint("TOPLEFT",UIMain.SK_List.SK_List_SF:GetScrollChild(),"TOPLEFT",15,-1*(i_card*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING) + DEFAULTS.SK_CARD_SPACING));
		UIMain.SK_List.SK_Card.Text = UIMain.SK_List.SK_Card:CreateFontString(nil,"ARTWORK")
		UIMain.SK_List.SK_Card.Text:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")
		UIMain.SK_List.SK_Card.Text:SetPoint("CENTER",0,0)
		UIMain.SK_List.SK_Card.Text:SetText(value)
		i_card = i_card + 1;
	end
end

function Main:Toggle()
	local menu = UIMain or Main:CreateMenu();
	menu:SetShown(not menu:IsShown());
end

function Main:GetThemeColor()
	local c = DEFAULTS.THEME;
	return c.r, c.g, c.b, c.hex;
end

function Main:CreateButton(point, relativeFrame, relativePoint, yOffset, text)
	local btn = CreateFrame("Button", nil, UIMain.ScrollFrame, "GameMenuButtonTemplate");
	btn:SetPoint(point, relativeFrame, relativePoint, 0, yOffset);
	btn:SetSize(140, 40);
	btn:SetText(text);
	btn:SetNormalFontObject("GameFontNormalLarge");
	btn:SetHighlightFontObject("GameFontHighlightLarge");
	return btn;
end

local function ScrollFrame_OnMouseWheel(self,delta)
    -- delta: 1 scroll up, -1 scroll down
	-- value at top is 0, value at bottom is size of child
	-- scroll so that one wheel is 3 SK cards
	local scroll_range = self:GetVerticalScrollRange();
	local inc = 3 * (DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING)
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (inc*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

local function ScrollFrame_OnVerticalScroll(self,scroll)
    self:SetVerticalScroll(scroll);
    return
end

function Main:CreateMenu()
    UIMain = CreateFrame("Frame", "UIMain", UIParent, "UIPanelDialogTemplate");
	UIMain:SetSize(DEFAULTS.MAIN_WIDTH,DEFAULTS.MAIN_HEIGHT);
	UIMain:SetPoint("CENTER");
	-- UIMain:SetMovable(true)
	-- UIMain:EnableMouse(true)
	-- UIMain:RegisterForDrag("LeftButton")
	-- UIMain:SetScript("OnDragStart", UIMain.StartMoving)
	-- UIMain:SetScript("OnDragStop", UIMain.StopMovingOrSizing)
    UIMain:SetAlpha(0.8);

    UIMain.Title:ClearAllPoints();
	UIMain.Title:SetPoint("LEFT", SKC_MainTitleBG, "LEFT", 6, 0);
	UIMain.Title:SetText("SKC");
	
	-- Create SK list panel
	UIMain.SK_List = CreateFrame("Frame","SK_List",UIMain,"InsetFrameTemplate");
	UIMain.SK_List:SetSize(DEFAULTS.SK_LIST_WIDTH,DEFAULTS.SK_LIST_HEIGHT);
	UIMain.SK_List:SetPoint("TOP",UIMain,"TOP",0,-50);
	
	-- Create scroll frame on SK list
    UIMain.SK_List.SK_List_SF = CreateFrame("ScrollFrame","SK_List_SF",UIMain.SK_List,"UIPanelScrollFrameTemplate2");
    UIMain.SK_List.SK_List_SF:SetPoint("TOPLEFT",UIMain.SK_List,"TOPLEFT",0,-2);
	UIMain.SK_List.SK_List_SF:SetPoint("BOTTOMRIGHT",UIMain.SK_List,"BOTTOMRIGHT",0,2);
	UIMain.SK_List.SK_List_SF:SetClipsChildren(true);
	UIMain.SK_List.SK_List_SF:SetScript("OnMouseWheel",ScrollFrame_OnMouseWheel);
	-- SK_List_SFTop:SetSize(31,400);
	-- SK_List_SFBottom:SetHeight(200);
	
	-- -- Position scroll bar
	-- UIMain.SK_List.SK_List_SF.ScrollBar:SetParent(UIMain.SK_List);
	-- UIMain.SK_List.SK_List_SF:SetScript("OnVerticalScroll",ScrollFrame_OnVerticalScroll);
	-- UIMain.SK_List.SK_List_SF.ScrollBar:ClearAllPoints();
	UIMain.SK_List.SK_List_SF.ScrollBar:SetPoint("TOPLEFT",UIMain.SK_List.SK_List_SF,"TOPRIGHT",-22,-21);
	-- UIMain.SK_List.SK_List_SF.ScrollBar:SetPoint("BOTTOMRIGHT",UIMain.SK_List.SK_List_SF,"BOTTOMRIGHT",0,0);
	-- UIMain.SK_List.SK_List_SF.ScrollBar:SetPoint("BOTTOMRIGHT",UIMain.SK_List.SK_List_SF,"BOTTOMRIGHT",-13,20);
	-- UIMain.SK_List.SK_List_SF.ScrollBar:SetPoint("TOPLEFT",UIMain.SK_List.SK_List_SF,"TOPRIGHT",13,-21);
	-- UIMain.SK_List.SK_List_SF.ScrollBar:SetPoint("BOTTOMRIGHT",UIMain.SK_List.SK_List_SF,"BOTTOMRIGHT",13,20);

	-- Create scroll child
	local scroll_child = CreateFrame("Frame",nil,UIMain.SK_List.ScrollFrame);
	local scroll_max = DEFAULTS.SK_CARD_SPACING + (SKC_DB.NumGuildMembers + 1)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING)
	scroll_child:SetSize(DEFAULTS.SK_LIST_WIDTH,scroll_max);
	UIMain.SK_List.SK_List_SF:SetScrollChild(scroll_child);

	-- Populate SK cards
	Main:PopulateSK_Cards()
	
	-- ----------------------------------
	-- -- Buttons
	-- ----------------------------------
	-- -- Save Button:
    -- UIMain.saveBtn = self:CreateButton("CENTER", child, "TOP", -70, "Save");

	-- -- Reset Button:	
	-- UIMain.resetBtn = self:CreateButton("TOP", UIMain.saveBtn, "BOTTOM", -10, "Reset");

	-- -- Load Button:	
	-- UIMain.loadBtn = self:CreateButton("TOP", UIMain.resetBtn, "BOTTOM", -10, "Load");

	-- ----------------------------------
	-- -- Sliders
	-- ----------------------------------
	-- -- Slider 1:
	-- UIMain.slider1 = CreateFrame("SLIDER", nil, UIMain.ScrollFrame, "OptionsSliderTemplate");
	-- UIMain.slider1:SetPoint("TOP", UIMain.loadBtn, "BOTTOM", 0, -20);
	-- UIMain.slider1:SetMinMaxValues(1, 100);
	-- UIMain.slider1:SetValue(50);
	-- UIMain.slider1:SetValueStep(30);
	-- UIMain.slider1:SetObeyStepOnDrag(true);

	-- -- Slider 2:
	-- UIMain.slider2 = CreateFrame("SLIDER", nil, UIMain.ScrollFrame, "OptionsSliderTemplate");
	-- UIMain.slider2:SetPoint("TOP", UIMain.slider1, "BOTTOM", 0, -20);
	-- UIMain.slider2:SetMinMaxValues(1, 100);
	-- UIMain.slider2:SetValue(40);
	-- UIMain.slider2:SetValueStep(30);
	-- UIMain.slider2:SetObeyStepOnDrag(true);

	-- ----------------------------------
	-- -- Check Buttons
	-- ----------------------------------
	-- -- Check Button 1:
	-- UIMain.checkBtn1 = CreateFrame("CheckButton", nil, UIMain.ScrollFrame, "UICheckButtonTemplate");
	-- UIMain.checkBtn1:SetPoint("TOPLEFT", UIMain.slider1, "BOTTOMLEFT", -10, -40);
	-- UIMain.checkBtn1.text:SetText("My Check Button!");

	-- -- Check Button 2:
	-- UIMain.checkBtn2 = CreateFrame("CheckButton", nil, UIMain.ScrollFrame, "UICheckButtonTemplate");
	-- UIMain.checkBtn2:SetPoint("TOPLEFT", UIMain.checkBtn1, "BOTTOMLEFT", 0, -10);
	-- UIMain.checkBtn2.text:SetText("Another Check Button!");
	-- UIMain.checkBtn2:SetChecked(true);
    
	UIMain:Hide();
	return UIMain;
end

-- Monitor variables loaded event
local events = CreateFrame("Frame");
events:RegisterEvent("VARIABLES_LOADED");
events:SetScript("OnEvent", Main.VarLoad);