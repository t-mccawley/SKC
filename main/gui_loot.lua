--------------------------------------
-- LOOT GUI
--------------------------------------
--------------------------------------
-- HELPER FUNCTIONS
--------------------------------------
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

local function OnMouseDown_ShowItemTooltip(self, button)
	-- shows tooltip when loot GUI clicked
	local lootLink = SKC_DB.LootManager:GetCurrentLootLink();
	local itemString = string.match(lootLink,"item[%-?%d:]+");
	local itemLabel = string.match(lootLink,"|h.+|h");
	SetItemRef(itemString, itemLabel, button, SKC_LootGUI);
	return;
end

local function SetSKItem()
	-- https://wow.gamepedia.com/ItemMixin
	-- local itemID = 19395; -- Rejuv
	local lootLink = SKC_DB.LootManager:GetCurrentLootLink();
	local item = Item:CreateFromItemLink(lootLink)
	item:ContinueOnItemLoad(function()
		-- item:GetlootLink();
		local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(lootLink);
		-- Set texture icon and link
		SKC_LootGUI.ItemTexture:SetTexture(texture);
		SKC_LootGUI.Title.Text:SetText(lootLink);
		SKC_LootGUI.Title:SetWidth(SKC_LootGUI.Title.Text:GetStringWidth()+35);   
	end)
end

local function InitTimerBarValue()
	SKC_LootGUI.TimerBar:SetValue(0);
	SKC_LootGUI.TimerBar.Text:SetText(LOOT_DECISION.OPTIONS.MAX_DECISION_TIME);
end

local function TimerBarHandler()
	local time_elapsed = SKC_LootGUI.TimerBar:GetValue() + LOOT_DECISION.OPTIONS.TIME_STEP;

	-- updated timer bar
	SKC_LootGUI.TimerBar:SetValue(time_elapsed);
	SKC_LootGUI.TimerBar.Text:SetText(LOOT_DECISION.OPTIONS.MAX_DECISION_TIME - time_elapsed);

	if time_elapsed >= LOOT_DECISION.OPTIONS.MAX_DECISION_TIME then
		-- out of time
		-- send loot response
		SKC_Main:Print("WARN","Time expired. You PASS on "..SKC_DB.LootManager:GetCurrentLootLink());
		LootTimer:Cancel();
		SKC_DB.LootManager:SendLootDecision(LOOT_DECISION.PASS);
		SKC_Main:HideLootDecisionGUI();
	end

	return;
end

local function StartLootTimer()
	InitTimerBarValue();
	if LootTimer ~= nil and not LootTimer:IsCancelled() then LootTimer:Cancel() end
	-- start new timer
	LootTimer = C_Timer.NewTicker(LOOT_DECISION.OPTIONS.TIME_STEP, TimerBarHandler, LOOT_DECISION.OPTIONS.MAX_DECISION_TIME/LOOT_DECISION.OPTIONS.TIME_STEP);
	return;
end
--------------------------------------
-- GUI
--------------------------------------
function SKC_Main:CreateLootGUI()
	-- Creates the GUI object for making a loot decision
	if SKC_LootGUI ~= nil then return end

	-- Create Frame
	SKC_LootGUI = CreateFrame("Frame",border_key,UIParent,"TranslucentFrameTemplate");
	SKC_LootGUI:SetSize(UI_DIMENSIONS.DECISION_WIDTH,UI_DIMENSIONS.DECISION_HEIGHT);
	SKC_LootGUI:SetPoint("TOP",UIParent,"CENTER",0,-130);
	SKC_LootGUI:SetAlpha(0.8);
	SKC_LootGUI:SetFrameLevel(6);

	-- Make it movable
	SKC_LootGUI:SetMovable(true);
	SKC_LootGUI:EnableMouse(true);
	SKC_LootGUI:RegisterForDrag("LeftButton");
	SKC_LootGUI:SetScript("OnDragStart", SKC_LootGUI.StartMoving);
	SKC_LootGUI:SetScript("OnDragStop", SKC_LootGUI.StopMovingOrSizing);

	-- Create Title
	SKC_LootGUI.Title = CreateFrame("Frame",title_key,SKC_LootGUI,"TranslucentFrameTemplate");
	SKC_LootGUI.Title:SetSize(UI_DIMENSIONS.LOOT_GUI_TITLE_CARD_WIDTH,UI_DIMENSIONS.LOOT_GUI_TITLE_CARD_HEIGHT);
	SKC_LootGUI.Title:SetPoint("BOTTOM",SKC_LootGUI,"TOP",0,-20);
	SKC_LootGUI.Title.Text = SKC_LootGUI.Title:CreateFontString(nil,"ARTWORK");
	SKC_LootGUI.Title.Text:SetFontObject("GameFontNormal");
	SKC_LootGUI.Title.Text:SetPoint("CENTER",0,0);
	SKC_LootGUI.Title:SetHyperlinksEnabled(true)
	SKC_LootGUI.Title:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)

	-- set texture / hidden frame for button click
	local item_texture_y_offst = -23;
	SKC_LootGUI.ItemTexture = SKC_LootGUI:CreateTexture(nil, "ARTWORK");
	SKC_LootGUI.ItemTexture:SetSize(UI_DIMENSIONS.ITEM_WIDTH,UI_DIMENSIONS.ITEM_HEIGHT);
	SKC_LootGUI.ItemTexture:SetPoint("TOP",SKC_LootGUI,"TOP",0,item_texture_y_offst)
	SKC_LootGUI.ItemClickBox = CreateFrame("Frame", nil, SKC_UIMain);
	SKC_LootGUI.ItemClickBox:SetFrameLevel(7)
	SKC_LootGUI.ItemClickBox:SetSize(UI_DIMENSIONS.ITEM_WIDTH,UI_DIMENSIONS.ITEM_HEIGHT);
	SKC_LootGUI.ItemClickBox:SetPoint("CENTER",SKC_LootGUI.ItemTexture,"CENTER");
	-- set decision buttons
	-- SK
	local loot_btn_x_offst = 40;
	local loot_btn_y_offst = -7;
	SKC_LootGUI.loot_decision_sk_btn = CreateFrame("Button", nil, SKC_LootGUI, "GameMenuButtonTemplate");
	SKC_LootGUI.loot_decision_sk_btn:SetPoint("TOPRIGHT",SKC_LootGUI.ItemTexture,"BOTTOM",-loot_btn_x_offst,loot_btn_y_offst);
	SKC_LootGUI.loot_decision_sk_btn:SetSize(UI_DIMENSIONS.LOOT_BTN_WIDTH, UI_DIMENSIONS.LOOT_BTN_HEIGHT);
	SKC_LootGUI.loot_decision_sk_btn:SetText("SK");
	SKC_LootGUI.loot_decision_sk_btn:SetNormalFontObject("GameFontNormal");
	SKC_LootGUI.loot_decision_sk_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_LootGUI.loot_decision_sk_btn:SetScript("OnMouseDown",OnClick_SK);
	SKC_LootGUI.loot_decision_sk_btn:Disable();
	-- Roll 
	SKC_LootGUI.loot_decision_roll_btn = CreateFrame("Button", nil, SKC_LootGUI, "GameMenuButtonTemplate");
	SKC_LootGUI.loot_decision_roll_btn:SetPoint("TOP",SKC_LootGUI.ItemTexture,"BOTTOM",0,loot_btn_y_offst);
	SKC_LootGUI.loot_decision_roll_btn:SetSize(UI_DIMENSIONS.LOOT_BTN_WIDTH, UI_DIMENSIONS.LOOT_BTN_HEIGHT);
	SKC_LootGUI.loot_decision_roll_btn:SetText("Roll");
	SKC_LootGUI.loot_decision_roll_btn:SetNormalFontObject("GameFontNormal");
	SKC_LootGUI.loot_decision_roll_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_LootGUI.loot_decision_roll_btn:SetScript("OnMouseDown",OnClick_ROLL);
	SKC_LootGUI.loot_decision_roll_btn:Disable();
	-- Pass
	SKC_LootGUI.loot_decision_pass_btn = CreateFrame("Button", nil, SKC_LootGUI, "GameMenuButtonTemplate");
	SKC_LootGUI.loot_decision_pass_btn:SetPoint("TOPLEFT",SKC_LootGUI.ItemTexture,"BOTTOM",loot_btn_x_offst,loot_btn_y_offst);
	SKC_LootGUI.loot_decision_pass_btn:SetSize(UI_DIMENSIONS.LOOT_BTN_WIDTH, UI_DIMENSIONS.LOOT_BTN_HEIGHT);
	SKC_LootGUI.loot_decision_pass_btn:SetText("Pass");
	SKC_LootGUI.loot_decision_pass_btn:SetNormalFontObject("GameFontNormal");
	SKC_LootGUI.loot_decision_pass_btn:SetHighlightFontObject("GameFontHighlight");
	SKC_LootGUI.loot_decision_pass_btn:SetScript("OnMouseDown",OnClick_PASS);
	SKC_LootGUI.loot_decision_pass_btn:Disable();
	-- timer bar
	local timer_bar_y_offst = -3;
	SKC_LootGUI.TimerBorder = CreateFrame("Frame",nil,SKC_LootGUI,"TranslucentFrameTemplate");
	SKC_LootGUI.TimerBorder:SetSize(UI_DIMENSIONS.STATUS_BAR_BRDR_WIDTH,UI_DIMENSIONS.STATUS_BAR_BRDR_HEIGHT);
	SKC_LootGUI.TimerBorder:SetPoint("TOP",SKC_LootGUI.loot_decision_roll_btn,"BOTTOM",0,timer_bar_y_offst);
	SKC_LootGUI.TimerBorder.Bg:SetAlpha(1.0);
	-- status bar
	SKC_LootGUI.TimerBar = CreateFrame("StatusBar",nil,SKC_LootGUI);
	SKC_LootGUI.TimerBar:SetSize(UI_DIMENSIONS.STATUS_BAR_BRDR_WIDTH - UI_DIMENSIONS.STATUS_BAR_WIDTH_OFFST,UI_DIMENSIONS.STATUS_BAR_BRDR_HEIGHT - UI_DIMENSIONS.STATUS_BAR_HEIGHT_OFFST);
	SKC_LootGUI.TimerBar:SetPoint("CENTER",SKC_LootGUI.TimerBorder,"CENTER",0,-1);
	-- background texture
	SKC_LootGUI.TimerBar.bg = SKC_LootGUI.TimerBar:CreateTexture(nil,"BACKGROUND",nil,-7);
	SKC_LootGUI.TimerBar.bg:SetAllPoints(SKC_LootGUI.TimerBar);
	SKC_LootGUI.TimerBar.bg:SetColorTexture(unpack(THEME.STATUS_BAR_COLOR));
	SKC_LootGUI.TimerBar.bg:SetAlpha(0.8);
	-- bar texture
	SKC_LootGUI.TimerBar.Bar = SKC_LootGUI.TimerBar:CreateTexture(nil,"BACKGROUND",nil,-6);
	SKC_LootGUI.TimerBar.Bar:SetColorTexture(0,0,0);
	SKC_LootGUI.TimerBar.Bar:SetAlpha(1.0);
	-- set status texture
	SKC_LootGUI.TimerBar:SetStatusBarTexture(SKC_LootGUI.TimerBar.Bar);
	-- add text
	SKC_LootGUI.TimerBar.Text = SKC_LootGUI.TimerBar:CreateFontString(nil,"ARTWORK",nil,7)
	SKC_LootGUI.TimerBar.Text:SetFontObject("GameFontHighlightSmall")
	SKC_LootGUI.TimerBar.Text:SetPoint("CENTER",SKC_LootGUI.TimerBar,"CENTER")
	SKC_LootGUI.TimerBar.Text:SetText(LOOT_DECISION.OPTIONS.MAX_DECISION_TIME)
	-- values
	SKC_LootGUI.TimerBar:SetMinMaxValues(0,LOOT_DECISION.OPTIONS.MAX_DECISION_TIME);
	SKC_LootGUI.TimerBar:SetValue(0);

	-- Make frame closable with esc
	table.insert(UISpecialFrames, "SKC_LootGUI");

	-- hide
	SKC_Main:HideLootDecisionGUI();
	return;
end

function SKC_Main:HideLootDecisionGUI()
	-- hide loot decision gui
	-- if not yet created, do nothing
	if SKC_LootGUI == nil then return end
	SKC_LootGUI.ItemClickBox:SetScript("OnMouseDown",nil);
	SKC_LootGUI.ItemClickBox:EnableMouse(false);
	SKC_LootGUI:Hide();
	return;
end

function SKC_Main:DisplayLootDecisionGUI(open_roll,sk_list)
	-- ensure SKC_LootGUI is created
	if SKC_LootGUI == nil then SKC_Main:CreateLootGUI() end
	-- Enable correct buttons
	SKC_LootGUI.loot_decision_pass_btn:Enable(); -- OnClick_PASS
	SKC_LootGUI.loot_decision_sk_btn:Enable(); -- OnClick_SK
	SKC_LootGUI.loot_decision_sk_btn:SetText(sk_list);
	if open_roll then
		SKC_LootGUI.loot_decision_roll_btn:Enable(); -- OnClick_ROLL
	else
		SKC_LootGUI.loot_decision_roll_btn:Disable();
	end
	-- Set item (in GUI)
	SetSKItem();
	-- Initiate timer
	StartLootTimer();
	-- enable mouse
	SKC_LootGUI.ItemClickBox:EnableMouse(true);
	-- set link
	SKC_LootGUI.ItemClickBox:SetScript("OnMouseDown",OnMouseDown_ShowItemTooltip);
	-- show
	SKC_LootGUI:Show();
	return;
end