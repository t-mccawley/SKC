--------------------------------------
-- LOOT GUI
--------------------------------------
-- GUI used for initiating loot decisions (as the master looter)
--------------------------------------
-- HELPER FUNCTIONS
--------------------------------------
local function OnClick_StartLoot(self,button,down)
	-- fires on click of valid item
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	-- check that button is enabled
	if not self:IsEnabled() then return end

	-- Check that player is ML
	if not SKC:isML() then 
		return;
	end
	
	if LOOT_SAFE_MODE then 
		return;
	end

	local lootIndex = self.lootIndex;
	SKC:Debug("OnClick_StartLoot for "..self.lootName,SKC.DEV.VERBOSE.LOOT);

	-- Update SKC Active flag
	SKC:RefreshStatus();

	if not SKC:CheckActive() then
		return;
	end

	-- Check if loot decision already pending
	if SKC.db.char.LM:LootDecisionPending() then 
		return;
	end

	-- Check if read in progress
	local sync_status = SKC:GetSyncStatus()
	if sync_status.val == SKC.SYNC_STATUS_ENUM.READING.val then
		SKC:Alert("Reading in progress, please wait until sync is complete to start loot.");
		return;
	elseif sync_status.val == SKC.SYNC_STATUS_ENUM.SENDING.val then
		SKC:Warn("Sending in progress, loot will start soon, please wait...");
	end
	
	-- Scan all items and save each item / elligible player
	SKC:Debug("Starting Loot Distribution",SKC.DEV.VERBOSE.LOOT);
	-- Reset LootManager
	SKC.db.char.LM:Reset();
	-- get item data
	local _, lootName = GetLootSlotInfo(lootIndex);
	if lootName ~= nil then
		-- Only perform SK for items if they are found in loot prio and green or higher rarity
		local lootLink = GetLootSlotLink(lootIndex);
		-- Store item
		SKC.db.char.LM:AddLoot(lootName,lootIndex,lootLink);
		if SKC.db.char.LP:Exists(lootName) then
			-- Valid item for decisions (if players present)
			-- Alert raid of new item
			local msg = "Loot Decision: "..lootLink;
			if UnitIsGroupLeader("player") then
				SendChatMessage(msg,"RAID_WARNING");
			else
				SendChatMessage(msg,"RAID");
			end
			-- Scan all possible characters to determine elligibility
			local any_elligible = false;
			for i_char = 1,40 do
				local char_name = GetMasterLootCandidate(lootIndex,i_char);
				if char_name ~= nil and SKC.db.char.LP:IsElligible(lootName,char_name) then
					SKC.db.char.LM:AddCharacter(char_name);
					any_elligible = true;
				end
			end
			-- check that at least one character was elligible
			if any_elligible then
				-- Kick off loot decison
				SKC.db.char.LM:KickOff();
				return;
			end
		end
	else
		SKC:Error("LootID "..lootIndex.." does not exist");
	end
	return;
end

local function OnClick_PASS(self,button)
	if self:IsEnabled() then
		SKC:CancelLootTimer()
		SKC.db.char.LM:SendLootDecision(SKC.LOOT_DECISION.PASS);
		SKC:HideLootDecisionGUI();
	end
	return;
end
--------------------------------------
-- GUI
--------------------------------------
function SKC:CreateLootStarterGUI()
	-- Creates the GUI object for initiating loot distribution
	-- if already created, return
	if self:CheckLootStarterGUICreated() then return end

	-- Create main invisible Frame
	LootFrame.LootStarterGUI = CreateFrame("Frame",nil,LootFrame);

	-- initialize globally used variables
	LootFrame.LootStarterGUI.Page = 0;

	-- hook up/down cycle buttons
	-- NEED TO TEST
	local LootFrameDownButton_fh = LootFrameDownButton:GetScript("OnClick");
	LootFrameDownButton:SetScript("OnClick",
		function(self,button,down)
			LootFrameDownButton_fh(self,button,down);
			LootFrame.LootStarterGUI.Page = LootFrame.LootStarterGUI.Page + 1;
			SKC:Debug("Page: "..LootFrame.LootStarterGUI.Page,SKC.DEV.VERBOSE.LOOT);
			SKC:ManageLootWindow();
		end
	);
	local LootFrameUpButton_fh = LootFrameUpButton:GetScript("OnClick");
	LootFrameUpButton:SetScript("OnClick",
		function(self,button,down)
			LootFrameUpButton_fh(self,button,down);
			LootFrame.LootStarterGUI.Page = LootFrame.LootStarterGUI.Page - 1;
			SKC:Debug("Page: "..LootFrame.LootStarterGUI.Page,SKC.DEV.VERBOSE.LOOT);
			SKC:ManageLootWindow();
		end
	);

	-- Create starter buttons
	local btn_width = 50;
	local btn_height = 30;
	local btn_x_offst = 0;
	local btn_y_offst = 0;
	-- only 4 button icons possible
	for lootBtnIndex = 1,4 do
		-- create GUI
		LootFrame.LootStarterGUI[lootBtnIndex] = CreateFrame("Button", nil, LootFrame.LootStarterGUI, "GameMenuButtonTemplate");
		LootFrame.LootStarterGUI[lootBtnIndex]:SetPoint("LEFT",_G["LootButton"..lootBtnIndex.."NameFrame"],"RIGHT",btn_x_offst,btn_y_offst);
		LootFrame.LootStarterGUI[lootBtnIndex]:SetSize(btn_width, btn_height);
		LootFrame.LootStarterGUI[lootBtnIndex]:SetText("SKC");
		LootFrame.LootStarterGUI[lootBtnIndex]:SetNormalFontObject("GameFontNormal");
		LootFrame.LootStarterGUI[lootBtnIndex]:SetHighlightFontObject("GameFontHighlight");
		LootFrame.LootStarterGUI[lootBtnIndex]:SetScript("OnClick",OnClick_StartLoot);
		LootFrame.LootStarterGUI[lootBtnIndex]:Disable();
		LootFrame.LootStarterGUI[lootBtnIndex]:Hide();
		-- initialize meta data
		LootFrame.LootStarterGUI[lootBtnIndex].lootIndex = nil;
		LootFrame.LootStarterGUI[lootBtnIndex].lootName = nil;
		LootFrame.LootStarterGUI[lootBtnIndex].lootLink = nil;
	end

	
	return;
end

--------------------------------------
-- LOOT DECISION
--------------------------------------
-- methods relating to the management and distribution of loot
--------------------------------------
-- METHODS
--------------------------------------
function SKC:LootDistValid()
	-- returns true if loot distribution is valid
	-- Check that player is ML
	if not self:isML() then 
		return(false);
	end

	if LOOT_SAFE_MODE then 
		return(false);
	end

	-- Update SKC Active flag
	self:RefreshStatus();

	if not self:CheckActive() then
		return(false);
	end

	-- Check if loot decision already pending
	if self.db.char.LM:LootDecisionPending() then 
		return(false);
	end

	return(true);
end

function SKC:OnOpenLoot()
	-- Fires on LOOT_OPENED for first time loot is opened
	--Check validity
	-- if not self:LootDistValid() then return end

	-- ensure GUI is made
	self:CreateLootStarterGUI();

	-- initialize page tracker
	LootFrame.LootStarterGUI.Page = 0;

	-- start managing the loot window
	self:ManageLootWindow();
	return;
end

function SKC:ManageLootWindow()
	-- manages loot window and updates SKC buttons for elligible items which trigger loot initiation
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)

	--Check validity
	-- if not self:LootDistValid() then return end
	self:Debug("OnOpenLoot",self.DEV.VERBOSE.LOOT);

	-- check for multiple loot pages
	local max_loot_btns = 4;
	if LootFrameDownButton:IsVisible() or LootFrameUpButton:IsVisible() then
		max_loot_btns = 3;
	end

	-- only show SKC buttons for visible items
	for lootBtnIndex=1,4 do	
		-- show / hide
		if _G["LootButton"..lootBtnIndex]:IsVisible() then
			-- reset button
			LootFrame.LootStarterGUI[lootBtnIndex]:Show();
			LootFrame.LootStarterGUI[lootBtnIndex]:Disable();
			LootFrame.LootStarterGUI[lootBtnIndex].lootIndex = nil;
			LootFrame.LootStarterGUI[lootBtnIndex].lootName = nil;
			LootFrame.LootStarterGUI[lootBtnIndex].lootLink = nil;
		else
			LootFrame.LootStarterGUI[lootBtnIndex]:Hide();
		end
	end

	-- scan items by index and bind button functions for given page
	-- also prints out ALL elligible loot
	local first_lootIndex = max_loot_btns*LootFrame.LootStarterGUI.Page + 1;
	local last_lootIndex = max_loot_btns*(LootFrame.LootStarterGUI.Page + 1);
	local loot_cnt = 1;
	for lootIndex = 1, GetNumLootItems() do
		-- get item data
		local lootType = GetLootSlotType(lootIndex); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(lootIndex);
		-- only perform for items that are higher rarity than current threshold
		if lootName ~= nil and lootType == 1 and lootRarity >= GetLootThreshold() then
			-- valid for master looter API
			local lootLink = GetLootSlotLink(lootIndex);
			-- Store item
			self.db.char.LM:Reset();
			self.db.char.LM:AddLoot(lootName,lootIndex,lootLink)
			-- Only query decisions for items if they are found in loot prio
			if self.db.char.LP:Exists(lootName) then

				-- Scan all possible characters to determine elligible
				local any_elligible = false;
				for raidIndex = 1,40 do
					if any_elligible then break end
					local char_name = GetRaidRosterInfo(raidIndex);
					if char_name ~= nil and self.db.char.LP:IsElligible(lootName,char_name) then
						any_elligible = true;
					end
				end

				-- check that at least one character was elligible
				if any_elligible then
					-- Valid item
					-- Alert raid of new item
					local msg = "SKC: ["..loot_cnt.."] "..lootLink;
					SendChatMessage(msg,"RAID");
					loot_cnt = loot_cnt + 1;
					-- activate button if on current page
					if lootIndex >= first_lootIndex and lootIndex <= last_lootIndex then
						local lootBtnIndex = lootIndex % max_loot_btns;
						LootFrame.LootStarterGUI[lootBtnIndex]:Enable();
						LootFrame.LootStarterGUI[lootBtnIndex].lootIndex = lootIndex;
						LootFrame.LootStarterGUI[lootBtnIndex].lootName = lootName;
						LootFrame.LootStarterGUI[lootBtnIndex].lootLink = lootLink;
					end
				end
			end
		end
	end
	return;
end

function SKC:ReadLootMsg(addon_channel,msg,game_channel,sender)
	-- reads message from LOOT
	local msg_out = self:Read(msg);
	if msg_out == nil then return end
	self.db.char.LM:ReadLootMsg(msg_out,sender);
	return;
end

function SKC:ReadLootDecision(addon_channel,msg,game_channel,sender)
	-- reads message from LOOT_DECISION
	local msg_out = self:Read(msg);
	if msg_out == nil then return end
	self.db.char.LM:ReadLootDecision(msg_out,sender);
	return;
end

function SKC:PrintLootDecision(addon_channel,msg,game_channel,sender)
	-- reads / prints message from LOOT_DECISION_PRINT
	local msg_out = self:Read(msg);
	if msg_out == nil then return end
	self:Print(msg_out);
	return;
end

function SKC:PrintLootOutcome(addon_channel,msg,game_channel,sender)
	-- reads / prints message from LOOT_OUTCOME_PRINT
	local msg_out = self:Read(msg);
	if msg_out == nil then return end
	self:Alert(msg_out);
	return;
end