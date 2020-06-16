--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...; -- returns name of addon and namespace (core)
core.Main = {}; -- adds Main table to addon namespace

local Main = core.Main; -- assignment by reference in lua, ugh
local UIMain;

--------------------------------------
-- Defaults (usually a database!)
--------------------------------------
local defaults = {
	theme = {
		r = 0, 
		g = 0.8, -- 204/255
		b = 1,
		hex = "00ccff"
	}
}

--------------------------------------
-- Main functions
--------------------------------------
function Main:VarLoad()
	-- SKC_DB == nil or #SKC_DB == 0
	if (true) then
		SKC_DB = {}
		-- SKC_DB has never been created
		-- Parse guild record and store all characters
		if IsInGuild() then
			SKC_DB["SK_List"] = {}
			local order = 1;
			for idx = 1, GetNumGuildMembers() do
				full_name, rank, rankIndex, level, class, zone, note, 
				officernote, online, status, classFileName, 
				achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(idx);
				if level == 60 then
					local name_tmp,_ = strsplit("-",full_name,2);
					SKC_DB.SK_List[name_tmp] = {};
					SKC_DB.SK_List[name_tmp]["name"] = name_tmp;
					SKC_DB.SK_List[name_tmp]["order"] = order;
					order = order + 1;
					-- DEFAULT_CHAT_FRAME:AddMessage(name);
				end
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("SKC Error: You are not in a guild!");
		end
	else
	end

	-- Create SK card
	local print_order = {}
	for key, value in pairs(SKC_DB["SK_List"]) do
		print_order[value.order] = value.name;
		-- DEFAULT_CHAT_FRAME:AddMessage(key.." "..value.order);
		-- UIMain.SK_List.SK_Card = CreateFrame("Frame",nil,UIMain.SK_List.ScrollFrame,"InsetFrameTemplate3");
		-- UIMain.SK_List.SK_Card:SetSize(100,20);
		-- UIMain.SK_List.SK_Card:SetPoint("TOP",child,"TOP",0,-5);
		-- break;
	end
	for key,value in ipairs(print_order) do
		DEFAULT_CHAT_FRAME:AddMessage("["..key.."] "..value);
	end
end

function Main:Toggle()
	local menu = UIMain or Main:CreateMenu();
	menu:SetShown(not menu:IsShown());
end

function Main:GetThemeColor()
	local c = defaults.theme;
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
    local scroll_range = self:GetVerticalScrollRange()
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (0.05*scroll_range*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

function Main:CreateMenu()
    UIMain = CreateFrame("Frame", "SKC_Main", UIParent, "UIPanelDialogTemplate");
	UIMain:SetSize(350, 600);
	UIMain:SetPoint("CENTER");
	-- UIMain:SetMovable(true)
	-- UIMain:EnableMouse(true)
	-- UIMain:RegisterForDrag("LeftButton")
	-- UIMain:SetScript("OnDragStart", UIMain.StartMoving)
	-- UIMain:SetScript("OnDragStop", UIMain.StopMovingOrSizing)
    UIMain:SetAlpha(0.8);

    UIMain.Title:ClearAllPoints();
    -- UIMain.Title:SetFontObject("GameFontHighlight");
	UIMain.Title:SetPoint("LEFT", SKC_MainTitleBG, "LEFT", 6, 0);
	UIMain.Title:SetText("SKC");
	
	-- Create SK list panel
	UIMain.SK_List = CreateFrame("Frame",nil,UIMain,"InsetFrameTemplate");
	UIMain.SK_List:SetSize(200,500);
	UIMain.SK_List:SetPoint("TOP",UIMain,"TOP",0,-50);
	
	-- Create scroll frame on SK list
    UIMain.SK_List.ScrollFrame = CreateFrame("ScrollFrame",nil,UIMain.SK_List,"UIPanelScrollFrameTemplate");
    UIMain.SK_List.ScrollFrame:SetPoint("TOPLEFT",UIMain.SK_List,"TOPLEFT",0,0);
	UIMain.SK_List.ScrollFrame:SetPoint("BOTTOMRIGHT",UIMain.SK_List,"BOTTOMRIGHT",0,0);
	UIMain.SK_List.ScrollFrame:SetScript("OnMouseWheel",ScrollFrame_OnMouseWheel)
    UIMain.SK_List.ScrollFrame:SetClipsChildren(true);

	-- Creat scroll child
    local child = CreateFrame("Frame",nil,UIMain.SK_List.ScrollFrame);
    child:SetSize(200,1000);
	UIMain.SK_List.ScrollFrame:SetScrollChild(child);

	-- Position scroll bar
    UIMain.SK_List.ScrollFrame.ScrollBar:ClearAllPoints();
    UIMain.SK_List.ScrollFrame.ScrollBar:SetPoint("TOPLEFT",UIMain.SK_List,"TOPRIGHT",-13,-21);
	UIMain.SK_List.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT",UIMain.SK_List,"BOTTOMRIGHT",-13,20);
	
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