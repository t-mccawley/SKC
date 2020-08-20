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
	-- Fires on LOOT_OPENED and print all elligible items (to raid) and loots all inelligible items
	-- Check validity
	if not self:LootDistValid() then return end

	-- scan items and print all elligible items and collect all inelligible items
	-- Scan all items and save each item / elligible player
	self:Debug("OnOpenLoot",self.DEV.VERBOSE.LOOT);
	local loot_cnt = 1;
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		-- local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot);
		-- only perform for greens or higher rarity
		if lootName ~= nil and lootRarity >= 2 then
			-- Only perform SK for items if they are found in loot prio
			local lootLink = GetLootSlotLink(i_loot);
			if self.db.char.LP:Exists(lootName) then
				-- Valid item
				-- Alert raid of new item
				local msg = "SKC: ["..loot_cnt.."] "..lootLink;
				SendChatMessage(msg,"RAID");
				loot_cnt = loot_cnt + 1;
				-- Scan all possible characters to determine elligible
				local any_elligible = false;
				for raidIndex = 1,40 do
					if any_elligible then break end
					local char_name = GetRaidRosterInfo(raidIndex);
					if char_name ~= nil then
						if self.db.char.LP:IsElligible(lootName,char_name) then 
							any_elligible = true;
						end
					end
				end
				-- check that at least one character was elligible
				if not any_elligible then
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

function SKC:OnOpenMasterLoot()
	-- fires on OnOpenMasterLoot and scans items / characters and starts loot decision for item
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	-- Check validity
	self:Debug("OnOpenMasterLoot",self.DEV.VERBOSE.LOOT);
	if not self:LootDistValid() then return end

	-- Check if sync in progress
	if self:CheckSyncInProgress() then
		self:Alert("Synchronization in progress. Loot distribution will start soon...");
	end
	
	-- Scan all items and save each item / elligible player
	self:Debug("Starting Loot Distribution",self.DEV.VERBOSE.LOOT);
	for i_loot = 1, GetNumLootItems() do
		-- Reset LootManager
		self.db.char.LM:Reset();
		-- get item data
		-- local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot);
		-- only perform for greens or higher rarity
		if lootName ~= nil and lootRarity >= 2 then
			-- Only perform SK for items if they are found in loot prio
			local lootLink = GetLootSlotLink(i_loot);
			if self.db.char.LP:Exists(lootName) then
				-- Valid item
				-- Store item
				local loot_idx = self.db.char.LM:AddLoot(lootName,lootLink);
				-- Alert raid of new item
				local msg = "Loot Decision: "..lootLink;
				SendChatMessage(msg,"RAID_WARNING");
				-- Scan all possible characters to determine elligible
				local any_elligible = false;
				for i_char = 1,40 do
					local char_name = GetMasterLootCandidate(i_loot,i_char);
					if char_name ~= nil then
						if self.db.char.LP:IsElligible(lootName,char_name) then
							self.db.char.LM:AddCharacter(char_name,loot_idx);
							any_elligible = true;
						end
					end
				end
				-- check that at least one character was elligible
				if any_elligible then
					-- Kick off loot decison
					self.db.char.LM:KickOff();
					return;
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