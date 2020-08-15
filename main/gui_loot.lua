--------------------------------------
-- LOOT GUI
--------------------------------------
--------------------------------------
-- HELPER FUNCTIONS
--------------------------------------
local function OnClick_PASS(self,button)
	if self:IsEnabled() then
		SKC:CancelLootTimer()
		SKC.db.char.LM:SendLootDecision(SKC.LOOT_DECISION.PASS);
		SKC:HideLootDecisionGUI();
	end
	return;
end

local function OnClick_SK(self,button)
	if self:IsEnabled() then
		SKC:CancelLootTimer()
		SKC.db.char.LM:SendLootDecision(SKC.LOOT_DECISION.SK);
		SKC:HideLootDecisionGUI();
	end
	return;
end

local function OnClick_ROLL(self,button)
	if self:IsEnabled() then
		SKC:CancelLootTimer()
		SKC.db.char.LM:SendLootDecision(SKC.LOOT_DECISION.ROLL);
		SKC:HideLootDecisionGUI();
	end
	return;
end

local function OnMouseDown_ShowItemTooltip(self, button)
	-- shows tooltip when loot GUI clicked
	local lootLink = SKC.db.char.LM:GetCurrentLootLink();
	local itemString = string.match(lootLink,"item[%-?%d:]+");
	local itemLabel = string.match(lootLink,"|h.+|h");
	SetItemRef(itemString, itemLabel, button, self.LootGUI);
	return;
end
--------------------------------------
-- GUI
--------------------------------------
function SKC:CreateLootGUI()
	-- Creates the GUI object for making a loot decision
	if not self:CheckLootGUICreated() then return end

	-- Create Frame
	self.LootGUI = CreateFrame("Frame",nil,UIParent,"TranslucentFrameTemplate");
	self.LootGUI:SetSize(self.UI_DIMS.DECISION_WIDTH,self.UI_DIMS.DECISION_HEIGHT);
	self.LootGUI:SetPoint("TOP",UIParent,"CENTER",0,-130);
	self.LootGUI:SetAlpha(0.8);
	self.LootGUI:SetFrameLevel(6);

	-- Make it movable
	self.LootGUI:SetMovable(true);
	self.LootGUI:EnableMouse(true);
	self.LootGUI:RegisterForDrag("LeftButton");
	self.LootGUI:SetScript("OnDragStart", self.LootGUI.StartMoving);
	self.LootGUI:SetScript("OnDragStop", self.LootGUI.StopMovingOrSizing);

	-- Create Title
	self.LootGUI.Title = CreateFrame("Frame",title_key,self.LootGUI,"TranslucentFrameTemplate");
	self.LootGUI.Title:SetSize(self.UI_DIMS.LOOT_GUI_TITLE_CARD_WIDTH,self.UI_DIMS.LOOT_GUI_TITLE_CARD_HEIGHT);
	self.LootGUI.Title:SetPoint("BOTTOM",self.LootGUI,"TOP",0,-20);
	self.LootGUI.Title.Text = self.LootGUI.Title:CreateFontString(nil,"ARTWORK");
	self.LootGUI.Title.Text:SetFontObject("GameFontNormal");
	self.LootGUI.Title.Text:SetPoint("CENTER",0,0);
	self.LootGUI.Title:SetHyperlinksEnabled(true)
	self.LootGUI.Title:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)

	-- set texture / hidden frame for button click
	local item_texture_y_offst = -23;
	self.LootGUI.ItemTexture = self.LootGUI:CreateTexture(nil, "ARTWORK");
	self.LootGUI.ItemTexture:SetSize(self.UI_DIMS.ITEM_WIDTH,self.UI_DIMS.ITEM_HEIGHT);
	self.LootGUI.ItemTexture:SetPoint("TOP",self.LootGUI,"TOP",0,item_texture_y_offst)
	self.LootGUI.ItemClickBox = CreateFrame("Frame", nil, SKC_UIMain);
	self.LootGUI.ItemClickBox:SetFrameLevel(7)
	self.LootGUI.ItemClickBox:SetSize(self.UI_DIMS.ITEM_WIDTH,self.UI_DIMS.ITEM_HEIGHT);
	self.LootGUI.ItemClickBox:SetPoint("CENTER",self.LootGUI.ItemTexture,"CENTER");
	-- set decision buttons
	-- SK
	local loot_btn_x_offst = 40;
	local loot_btn_y_offst = -7;
	self.LootGUI.loot_decision_sk_btn = CreateFrame("Button", nil, self.LootGUI, "GameMenuButtonTemplate");
	self.LootGUI.loot_decision_sk_btn:SetPoint("TOPRIGHT",self.LootGUI.ItemTexture,"BOTTOM",-loot_btn_x_offst,loot_btn_y_offst);
	self.LootGUI.loot_decision_sk_btn:SetSize(self.UI_DIMS.LOOT_BTN_WIDTH, self.UI_DIMS.LOOT_BTN_HEIGHT);
	self.LootGUI.loot_decision_sk_btn:SetText("SK");
	self.LootGUI.loot_decision_sk_btn:SetNormalFontObject("GameFontNormal");
	self.LootGUI.loot_decision_sk_btn:SetHighlightFontObject("GameFontHighlight");
	self.LootGUI.loot_decision_sk_btn:SetScript("OnMouseDown",OnClick_SK);
	self.LootGUI.loot_decision_sk_btn:Disable();
	-- Roll 
	self.LootGUI.loot_decision_roll_btn = CreateFrame("Button", nil, self.LootGUI, "GameMenuButtonTemplate");
	self.LootGUI.loot_decision_roll_btn:SetPoint("TOP",self.LootGUI.ItemTexture,"BOTTOM",0,loot_btn_y_offst);
	self.LootGUI.loot_decision_roll_btn:SetSize(self.UI_DIMS.LOOT_BTN_WIDTH, self.UI_DIMS.LOOT_BTN_HEIGHT);
	self.LootGUI.loot_decision_roll_btn:SetText("Roll");
	self.LootGUI.loot_decision_roll_btn:SetNormalFontObject("GameFontNormal");
	self.LootGUI.loot_decision_roll_btn:SetHighlightFontObject("GameFontHighlight");
	self.LootGUI.loot_decision_roll_btn:SetScript("OnMouseDown",OnClick_ROLL);
	self.LootGUI.loot_decision_roll_btn:Disable();
	-- Pass
	self.LootGUI.loot_decision_pass_btn = CreateFrame("Button", nil, self.LootGUI, "GameMenuButtonTemplate");
	self.LootGUI.loot_decision_pass_btn:SetPoint("TOPLEFT",self.LootGUI.ItemTexture,"BOTTOM",loot_btn_x_offst,loot_btn_y_offst);
	self.LootGUI.loot_decision_pass_btn:SetSize(self.UI_DIMS.LOOT_BTN_WIDTH, self.UI_DIMS.LOOT_BTN_HEIGHT);
	self.LootGUI.loot_decision_pass_btn:SetText("Pass");
	self.LootGUI.loot_decision_pass_btn:SetNormalFontObject("GameFontNormal");
	self.LootGUI.loot_decision_pass_btn:SetHighlightFontObject("GameFontHighlight");
	self.LootGUI.loot_decision_pass_btn:SetScript("OnMouseDown",OnClick_PASS);
	self.LootGUI.loot_decision_pass_btn:Disable();
	-- timer bar
	local timer_bar_y_offst = -3;
	self.LootGUI.TimerBorder = CreateFrame("Frame",nil,self.LootGUI,"TranslucentFrameTemplate");
	self.LootGUI.TimerBorder:SetSize(self.UI_DIMS.STATUS_BAR_BRDR_WIDTH,self.UI_DIMS.STATUS_BAR_BRDR_HEIGHT);
	self.LootGUI.TimerBorder:SetPoint("TOP",self.LootGUI.loot_decision_roll_btn,"BOTTOM",0,timer_bar_y_offst);
	self.LootGUI.TimerBorder.Bg:SetAlpha(1.0);
	-- status bar
	self.LootGUI.TimerBar = CreateFrame("StatusBar",nil,self.LootGUI);
	self.LootGUI.TimerBar:SetSize(self.UI_DIMS.STATUS_BAR_BRDR_WIDTH - self.UI_DIMS.STATUS_BAR_WIDTH_OFFST,self.UI_DIMS.STATUS_BAR_BRDR_HEIGHT - self.UI_DIMS.STATUS_BAR_HEIGHT_OFFST);
	self.LootGUI.TimerBar:SetPoint("CENTER",self.LootGUI.TimerBorder,"CENTER",0,-1);
	-- background texture
	self.LootGUI.TimerBar.bg = self.LootGUI.TimerBar:CreateTexture(nil,"BACKGROUND",nil,-7);
	self.LootGUI.TimerBar.bg:SetAllPoints(self.LootGUI.TimerBar);
	self.LootGUI.TimerBar.bg:SetColorTexture(unpack(THEME.STATUS_BAR_COLOR));
	self.LootGUI.TimerBar.bg:SetAlpha(0.8);
	-- bar texture
	self.LootGUI.TimerBar.Bar = self.LootGUI.TimerBar:CreateTexture(nil,"BACKGROUND",nil,-6);
	self.LootGUI.TimerBar.Bar:SetColorTexture(0,0,0);
	self.LootGUI.TimerBar.Bar:SetAlpha(1.0);
	-- set status texture
	self.LootGUI.TimerBar:SetStatusBarTexture(self.LootGUI.TimerBar.Bar);
	-- add text
	self.LootGUI.TimerBar.Text = self.LootGUI.TimerBar:CreateFontString(nil,"ARTWORK",nil,7)
	self.LootGUI.TimerBar.Text:SetFontObject("GameFontHighlightSmall")
	self.LootGUI.TimerBar.Text:SetPoint("CENTER",self.LootGUI.TimerBar,"CENTER")
	self.LootGUI.TimerBar.Text:SetText(self.LOOT_DECISION.OPTIONS.MAX_DECISION_TIME)
	-- values
	self.LootGUI.TimerBar:SetMinMaxValues(0,self.LOOT_DECISION.OPTIONS.MAX_DECISION_TIME);
	self.LootGUI.TimerBar:SetValue(0);

	-- Make frame closable with esc
	table.insert(UISpecialFrames, "self.LootGUI");

	-- hide
	SKC:HideLootDecisionGUI();
	return;
end

function SKC:HideLootDecisionGUI()
	-- hide loot decision gui
	-- if not yet created, do nothing
	if not self:CheckLootGUICreated() then return end
	self.LootGUI.ItemClickBox:SetScript("OnMouseDown",nil);
	self.LootGUI.ItemClickBox:EnableMouse(false);
	self.LootGUI:Hide();
	return;
end

function SKC:DisplayLootDecisionGUI(open_roll,sk_list)
	-- ensure LootGUI is created
	if not self:CheckLootGUICreated() then SKC:CreateLootGUI() end
	-- Enable correct buttons
	self.LootGUI.loot_decision_pass_btn:Enable(); -- OnClick_PASS
	self.LootGUI.loot_decision_sk_btn:Enable(); -- OnClick_SK
	self.LootGUI.loot_decision_sk_btn:SetText(sk_list);
	if open_roll then
		self.LootGUI.loot_decision_roll_btn:Enable(); -- OnClick_ROLL
	else
		self.LootGUI.loot_decision_roll_btn:Disable();
	end
	-- Set item (in GUI)
	self:SetSKItem();
	-- Initiate timer
	StartLootTimer();
	-- enable mouse
	self.LootGUI.ItemClickBox:EnableMouse(true);
	-- set link
	self.LootGUI.ItemClickBox:SetScript("OnMouseDown",OnMouseDown_ShowItemTooltip);
	-- show
	self.LootGUI:Show();
	return;
end

function SKC:SetSKItem()
	-- https://wow.gamepedia.com/ItemMixin
	-- local itemID = 19395; -- Rejuv
	local lootLink = self.db.char.LM:GetCurrentLootLink();
	local item = Item:CreateFromItemLink(lootLink)
	item:ContinueOnItemLoad(function()
		-- item:GetlootLink();
		local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(lootLink);
		-- Set texture icon and link
		self.LootGUI.ItemTexture:SetTexture(texture);
		self.LootGUI.Title.Text:SetText(lootLink);
		self.LootGUI.Title:SetWidth(self.LootGUI.Title.Text:GetStringWidth()+35);   
	end)
end

function SKC:StartLootTimer()
	-- start loot timer and update GUI
	-- cancel current loot timer
	self:CancelLootTimer();
	-- reset ticks / display time
	self.Timers.Loot.Ticks = 0;
	self.Timers.Loot.ElapsedTime = 0;
	-- update GUI
	self:UpdateLootTimerGUI();
	-- start new ticker
	self.Timers.Loot.Ticker = C_Timer.NewTicker(self.LOOT_DECISION.OPTIONS.TIME_STEP, "UpdateLootTimer", self.LOOT_DECISION.OPTIONS.MAX_DECISION_TIME/self.LOOT_DECISION.OPTIONS.TIME_STEP);
	return;
end

function SKC:UpdateLootTimer()
	-- Handles tick / elapsed time and updates GUI
	self.Timers.Loot.Ticks = self.Timers.Loot.Ticks + 1;
	self.Timers.Loot.ElapsedTime = self.Timers.Loot.ElapsedTime - self.LOOT_DECISION.OPTIONS.TIME_STEP;
	self:UpdateLootTimerGUI();
	if self.Timers.Loot.ElapsedTime >= self.LOOT_DECISION.OPTIONS.MAX_DECISION_TIME then
		-- out of time
		self:CancelLootTimer();
		-- send loot response
		self:Print("Time expired. You PASS on "..self.db.char.LM:GetCurrentLootLink());
		self.db.char.LM:SendLootDecision(self.LOOT_DECISION.PASS);
		self:HideLootDecisionGUI();
	end
	return;
end

function SKC:UpdateLootTimerGUI()
	-- updates loot timer GUI
	self.LootGUI.TimerBar:SetValue(self.Timers.Loot.ElapsedTime);
	self.LootGUI.TimerBar.Text:SetText(self.LOOT_DECISION.OPTIONS.MAX_DECISION_TIME - self.Timers.Loot.ElapsedTime);
	return;
end

function SKC:CancelLootTimer()
	-- cancels current loot timer (if it exists / isnt already cancelled)
	if self.Timers.Loot.Ticker == nil or self.Timers.Loot.Ticker:IsCancelled() then return end
	self.Timers.Loot.Ticker:Cancel();
	return;
end