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

local function OnClick_LootItem(self,button,down)
	-- fires on click of valid item
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	local lootIndex = self.Index;
	SKC:Debug("OnClick_LootItem for ID "..lootIndex,SKC.DEV.VERBOSE.LOOT);
	-- Check validity
	if not SKC:LootDistValid() then return end

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
			else
				SKC:Debug("No elligible characters in raid. Giving directly to ML",SKC.DEV.VERBOSE.LOOT);
				-- give directly to ML
				SKC.db.char.LM:GiveLootToML(lootName,lootLink,SKC.LOG_OPTIONS["Event Type"].Options.NE);
			end
		else
			SKC:Debug("Item not in Loot Prio. Giving directly to ML",SKC.DEV.VERBOSE.LOOT);
			-- give directly to ML
			SKC.db.char.LM:GiveLootToML(lootName,lootLink,SKC.LOG_OPTIONS["Event Type"].Options.AL);
		end
	else
		SKC:Error("LootID "..lootIndex.." does not exist");
	end
	return;
end

function SKC:OnOpenLoot()
	-- Fires on LOOT_OPENED and print all elligible items (to raid) and loots all inelligible items
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	-- Check validity
	if not self:LootDistValid() then return end

	-- scan items and print all elligible items and collect all inelligible items
	-- Scan all items and save each item / elligible player
	self:Debug("OnOpenLoot",self.DEV.VERBOSE.LOOT);
	local loot_cnt = 1;
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot);
		-- only perform for items that are greens or higher rarity
		if lootName ~= nil and lootType == 1 and lootRarity >= 2 then
			-- Only perform SK for items if they are found in loot prio
			local lootLink = GetLootSlotLink(i_loot);
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
					-- set onclick event
					SKC:Print("Binding function to i_loot: "..i_loot)
					_G["LootButton"..i_loot].Index = i_loot;
					_G["LootButton"..i_loot]:SetScript("OnClick", OnClick_LootItem);
				else
					self:Debug("No elligible characters in raid. Giving directly to ML",self.DEV.VERBOSE.LOOT);
					-- give directly to ML
					self.db.char.LM:GiveLootToML(lootName,lootLink,self.LOG_OPTIONS["Event Type"].Options.NE);
				end
			else
				self:Debug("Item not in Loot Prio. Giving directly to ML",self.DEV.VERBOSE.LOOT);
				-- give directly to ML
				self.db.char.LM:GiveLootToML(lootName,lootLink,self.LOG_OPTIONS["Event Type"].Options.AL);
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