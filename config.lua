--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...;
core.Config = {}; -- adds Config table to addon namespace

local Config = core.Config;
local UIConfig;

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
-- Config functions
--------------------------------------
function Config:Toggle()
	local menu = UIConfig or Config:CreateMenu();
	menu:SetShown(not menu:IsShown());
end

function Config:GetThemeColor()
	local c = defaults.theme;
	return c.r, c.g, c.b, c.hex;
end

function Config:CreateButton(point, relativeFrame, relativePoint, yOffset, text)
	local btn = CreateFrame("Button", nil, UIConfig.ScrollFrame, "GameMenuButtonTemplate");
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
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (0.1*scroll_range*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

function Config:CreateMenu()
	UIConfig = CreateFrame("Frame", "SKC_Config", UIParent, "UIPanelDialogTemplate");
	UIConfig:SetSize(350, 400);
	UIConfig:SetPoint("CENTER"); -- Doesn't need to be ("CENTER", UIParent, "CENTER")

    UIConfig.Title:ClearAllPoints();
    UIConfig.Title:SetFontObject("GameFontHighlight");
	UIConfig.Title:SetPoint("LEFT", SKC_ConfigTitleBG, "LEFT", 6, 0);
    UIConfig.Title:SetText("SKC Configuration");
    
    UIConfig.ScrollFrame = CreateFrame("ScrollFrame",nil,UIConfig,"UIPanelScrollFrameTemplate");
    UIConfig.ScrollFrame:SetPoint("TOPLEFT",SKC_ConfigDialogBG,"TOPLEFT",4,-8);
    UIConfig.ScrollFrame:SetPoint("BOTTOMRIGHT",SKC_ConfigDialogBG,"BOTTOMRIGHT",-3,4);

    UIConfig.ScrollFrame:SetClipsChildren(true);

    local child = CreateFrame("Frame",nil,UIConfig.ScrollFrame);
    child:SetSize(308,500);

    UIConfig.ScrollFrame:SetScrollChild(child);

    UIConfig.ScrollFrame:SetScript("OnMouseWheel",ScrollFrame_OnMouseWheel)

    UIConfig.ScrollFrame.ScrollBar:ClearAllPoints();
    UIConfig.ScrollFrame.ScrollBar:SetPoint("TOPLEFT",UIConfig.ScrollFrame,"TOPRIGHT",-12,-18);
    UIConfig.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT",UIConfig.ScrollFrame,"BOTTOMRIGHT",-7,18);

	----------------------------------
	-- Buttons
	----------------------------------
	-- Save Button:
	UIConfig.saveBtn = self:CreateButton("CENTER", child, "TOP", -70, "Save");

	-- Reset Button:	
	UIConfig.resetBtn = self:CreateButton("TOP", UIConfig.saveBtn, "BOTTOM", -10, "Reset");

	-- Load Button:	
	UIConfig.loadBtn = self:CreateButton("TOP", UIConfig.resetBtn, "BOTTOM", -10, "Load");

	----------------------------------
	-- Sliders
	----------------------------------
	-- Slider 1:
	UIConfig.slider1 = CreateFrame("SLIDER", nil, UIConfig.ScrollFrame, "OptionsSliderTemplate");
	UIConfig.slider1:SetPoint("TOP", UIConfig.loadBtn, "BOTTOM", 0, -20);
	UIConfig.slider1:SetMinMaxValues(1, 100);
	UIConfig.slider1:SetValue(50);
	UIConfig.slider1:SetValueStep(30);
	UIConfig.slider1:SetObeyStepOnDrag(true);

	-- Slider 2:
	UIConfig.slider2 = CreateFrame("SLIDER", nil, UIConfig.ScrollFrame, "OptionsSliderTemplate");
	UIConfig.slider2:SetPoint("TOP", UIConfig.slider1, "BOTTOM", 0, -20);
	UIConfig.slider2:SetMinMaxValues(1, 100);
	UIConfig.slider2:SetValue(40);
	UIConfig.slider2:SetValueStep(30);
	UIConfig.slider2:SetObeyStepOnDrag(true);

	----------------------------------
	-- Check Buttons
	----------------------------------
	-- Check Button 1:
	UIConfig.checkBtn1 = CreateFrame("CheckButton", nil, UIConfig.ScrollFrame, "UICheckButtonTemplate");
	UIConfig.checkBtn1:SetPoint("TOPLEFT", UIConfig.slider1, "BOTTOMLEFT", -10, -40);
	UIConfig.checkBtn1.text:SetText("My Check Button!");

	-- Check Button 2:
	UIConfig.checkBtn2 = CreateFrame("CheckButton", nil, UIConfig.ScrollFrame, "UICheckButtonTemplate");
	UIConfig.checkBtn2:SetPoint("TOPLEFT", UIConfig.checkBtn1, "BOTTOMLEFT", 0, -10);
	UIConfig.checkBtn2.text:SetText("Another Check Button!");
	UIConfig.checkBtn2:SetChecked(true);
	
	UIConfig:Hide();
	return UIConfig;
end