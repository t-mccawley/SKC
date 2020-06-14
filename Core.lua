-- Tutorial: https://www.youtube.com/watch?v=nfaE7NQhMlc&list=PL3wt7cLYn4N-3D3PTTUZBM2t1exFmoA2G
-- FUNCTION
--[[
local myFunc = function() 
	local x;
	x = 3;
  return x;
end
--]]
-- CLASS
--[[
local MyClass = {
  -- index:
  1,2,3,4,
  -- hash table:
  size = 5,
}
--]]
-- FOR LOOP (NUMERIC)
--[[

for i = startValue, endValue, stepValue do
  -- code to iterate
end

--]]
-- FOR LOOP (GENERIC)
-- will iterate index part first then hash table portion
-- Will not necessarily print hash table in order
--[[

for key, value in pairs(tbl) do
  -- code to iterate
end

--]]
-- to print out just the index part, use ipairs
-- WHILE LOOP
--[[

while (true) do
end

--]]
-- DO LOOP
--[[

repeat
until (condition)

--]]
-- No switch statements, no continue statements (there is a break)
-- LAYERS
-- Layers placed in order to display graphics
-- Frame = Canvas, Layer = paint on top
-- BACKGROUND
-- BORDER
-- ARTWORK
-- OVERLAY
-- HIGHLIGHT
------------------------------------------------------------------------------------------------
-- faster reload command
SLASH_RELOADUI1 = "/rl"
SlashCmdList.RELOADUI = ReloadUI

-- quicker access to frame stack
SLASH_FRAMESTK1 = "/fs"
SlashCmdList.FRAMESTK = function()
  LoadAddon('Blizzard_DebugTools')
  FrameStackTooltip_Toggle()
end

-- left and right arrows in the edit box without rotating your character
for i = 1, NUM_CHAT_WINDOWS do
  _G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false)
end
------------------------------------------------------------------------------------------------
local UIConfig = CreateFrame("Frame","SKC_Frame",UIParent,"BasicFrameTemplateWithInset");
--[[
1. type of frame - "Frame"
2. global frame name - "SKC_Frame"
3. The parent frame (not string name) - UIParent
4. CSV list of XML templates to inherit from
--]]
UIConfig:SetSize(300,360); -- width, height
UIConfig:SetPoint("CENTER",UIParent,"CENTER"); -- point, relativeFrame, relativePoint, xOffset, yOffset

-- Child frames and regions:
UIConfig.title = UIConfig:CreateFontString(nil,"OVERLAY");
UIConfig.title:SetFontObject("GameFontHighlight");
-- UIConfig.TitleBg is not actually a frame, it is a texture
UIConfig.title:SetPoint("LEFT",UIConfig.TitleBg,"LEFT",5,0);
UIConfig.title:SetText("SK List");

---------------------------------
-- Buttons
---------------------------------
-- Save Button:
UIConfig.saveBtn = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
UIConfig.saveBtn:SetPoint("CENTER", UIConfig, "TOP", 0, -70);
UIConfig.saveBtn:SetSize(140, 40);
UIConfig.saveBtn:SetText("Save");
UIConfig.saveBtn:SetNormalFontObject("GameFontNormalLarge");
UIConfig.saveBtn:SetHighlightFontObject("GameFontHighlightLarge");

--UIConfig.saveBtn:SetPushedFontObject(""); -- removed from API
--UIConfig.saveBtn:SetDisabledFontObject(" "); -- requires a name (cannot be empty!)

-- Reset Button:
UIConfig.resetBtn = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
UIConfig.resetBtn:SetPoint("TOP", UIConfig.saveBtn, "BOTTOM", 0, -10);
UIConfig.resetBtn:SetSize(140, 40);
UIConfig.resetBtn:SetText("Reset");
UIConfig.resetBtn:SetNormalFontObject("GameFontNormalLarge");
UIConfig.resetBtn:SetHighlightFontObject("GameFontHighlightLarge");

-- Load Button:
UIConfig.loadBtn = CreateFrame("Button", nil, UIConfig, "GameMenuButtonTemplate");
UIConfig.loadBtn:SetPoint("TOP", UIConfig.resetBtn, "BOTTOM", 0, -10);
UIConfig.loadBtn:SetSize(140, 40);
UIConfig.loadBtn:SetText("Load");
UIConfig.loadBtn:SetNormalFontObject("GameFontNormalLarge");
UIConfig.loadBtn:SetHighlightFontObject("GameFontHighlightLarge");

---------------------------------
-- Sliders
---------------------------------
-- Slider 1:
UIConfig.slider1 = CreateFrame("SLIDER", nil, UIConfig, "OptionsSliderTemplate");
UIConfig.slider1:SetPoint("TOP", UIConfig.loadBtn, "BOTTOM", 0, -20);
UIConfig.slider1:SetMinMaxValues(1, 100);
UIConfig.slider1:SetValue(50);
UIConfig.slider1:SetValueStep(30);
UIConfig.slider1:SetObeyStepOnDrag(true);

-- Slider 2:
UIConfig.slider2 = CreateFrame("SLIDER", nil, UIConfig, "OptionsSliderTemplate");
UIConfig.slider2:SetPoint("TOP", UIConfig.slider1, "BOTTOM", 0, -20);
UIConfig.slider2:SetMinMaxValues(1, 100);
UIConfig.slider2:SetValue(40);
UIConfig.slider2:SetValueStep(30);
UIConfig.slider2:SetObeyStepOnDrag(true);

---------------------------------
-- Check Buttons
---------------------------------
-- Check Button 1:
UIConfig.checkBtn1 = CreateFrame("CheckButton", nil, UIConfig, "UICheckButtonTemplate");
UIConfig.checkBtn1:SetPoint("TOPLEFT", UIConfig.slider1, "BOTTOMLEFT", -10, -40);
UIConfig.checkBtn1.text:SetText("My Check Button!");

-- Check Button 2:
UIConfig.checkBtn2 = CreateFrame("CheckButton", nil, UIConfig, "UICheckButtonTemplate");
UIConfig.checkBtn2:SetPoint("TOPLEFT", UIConfig.checkBtn1, "BOTTOMLEFT", 0, -10);
UIConfig.checkBtn2.text:SetText("Another Check Button!");
UIConfig.checkBtn2:SetChecked(true);

