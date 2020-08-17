--------------------------------------
-- LOOT DECISION
--------------------------------------
function SKC:LootDistValid()
	-- returns true if loot distribution is valid
	-- Check that player is ML
	if not self:isML() then 
		return(false);
	end

	if LOOT_SAFE_MODE then 
		self:Warn("Loot Safe Mode");
		return(false);
	end

	-- Update SKC Active flag
	self:RefreshStatus();

	if not self:CheckActive() then
		self:Warn("SKC not active. Skipping loot distribution.");
		return(false);
	end

	-- Check if loot decision already pending
	if self.db.char.LM:LootDecisionPending() then 
		return(false);
	end

	return(true);
end

function SKC:OnOpenLoot()
	-- Fires on LOOT_OPENED and print all elligible items (to raid) and collect all inelligible items
	-- Check validity
	self:LootDistValid();

	-- scan items and print all elligible items and collect all inelligible items
	-- Scan all items and save each item / elligible player
	self:Debug("Starting Loot Distribution",self.DEV.VERBOSE.LOOT) end
	local loot_cnt = 1;
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		-- local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot);
		if lootName ~= nil then
			-- Only perform SK for items if they are found in loot prio
			if self.db.char.LP:Exists(lootName) then
				-- Valid item
				local lootLink = GetLootSlotLink(i_loot);
				-- Alert raid of new item
				local msg = "["..loot_cnt.."] "..lootLink;
				SendChatMessage(msg,"RAID");
				loot_cnt = loot_cnt + 1;
				-- Scan all possible characters to determine elligible
				local any_elligible = false;
				for i_char = 1,40 do
					if any_elligible then break end
					local char_name = GetMasterLootCandidate(i_loot,i_char);
					if char_name ~= nil then
						if self.db.char.LP:IsElligible(lootName,char_name) then 
							any_elligible = true;
						end
					end
				end
				-- check that at least one character was elligible
				if not any_elligible then
					self:Debug("No elligible characters in raid. Giving directly to ML",self.DEV.VERBOSE.LOOT) end
					-- give directly to ML
					self.db.char.LM:GiveLootToML(lootName,lootLink);
					self:WriteToLog( 
						LOG_OPTIONS["Event Type"].Options.NE,
						"",
						"ML",
						lootName,
						"",
						"",
						"",
						"",
						"",
						UnitName("player")
					);
				end
			else
				self:Debug("Item not in Loot Prio. Giving directly to ML",self.DEV.VERBOSE.LOOT) end
				-- give directly to ML
				self.db.char.LM:GiveLootToML(lootName,GetLootSlotLink(i_loot));
				self:WriteToLog( 
					LOG_OPTIONS["Event Type"].Options.AL,
					"",
					"ML",
					lootName,
					"",
					"",
					"",
					"",
					"",
					UnitName("player")
				);
			end
		end
	end

	return;
end
function SKC:OnOpenMasterLoot()
	-- Scans items / characters and starts loot decision for item
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	-- Check validity
	if not self:LootDistValid() then
		return;
	end

	-- Check if sync in progress
	if self:CheckSyncInProgress() then
		self:Alert("Synchronization in progress. Loot distribution will start soon...");
	end

	-- Reset LootManager
	self.db.char.LM:Reset();
	
	-- Scan all items and save each item / elligible player
	self:Debug("Starting Loot Distribution",self.DEV.VERBOSE.LOOT) end
	local loot_cnt = 1;
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		-- local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot);
		if lootName ~= nil then
			-- Only perform SK for items if they are found in loot prio
			if self.db.char.LP:Exists(lootName) then
				-- Valid item
				local lootLink = GetLootSlotLink(i_loot);
				-- Store item
				local loot_idx = self.db.char.LM:AddLoot(lootName,lootLink);
				-- Alert raid of new item
				local msg = "["..loot_cnt.."] "..lootLink;
				SendChatMessage(msg,"RAID_WARNING");
				loot_cnt = loot_cnt + 1;
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
				if not any_elligible then
					self:Debug("No elligible characters in raid. Giving directly to ML",self.DEV.VERBOSE.LOOT) end
					-- give directly to ML
					self.db.char.LM:GiveLootToML(lootName,lootLink);
					self.db.char.LM:MarkLootAwarded(lootName);
					self:WriteToLog( 
						LOG_OPTIONS["Event Type"].Options.NE,
						"",
						"ML",
						lootName,
						"",
						"",
						"",
						"",
						"",
						UnitName("player")
					);
				end
			else
				self:Debug("Item not in Loot Prio. Giving directly to ML",self.DEV.VERBOSE.LOOT) end
				-- give directly to ML
				self.db.char.LM:GiveLootToML(lootName,GetLootSlotLink(i_loot));
				self.db.char.LM:MarkLootAwarded(lootName);
				self:WriteToLog( 
					LOG_OPTIONS["Event Type"].Options.AL,
					"",
					"ML",
					lootName,
					"",
					"",
					"",
					"",
					"",
					UnitName("player")
				);
			end
		end
	end

	-- Kick off loot decison
	self.db.char.LM:KickOff();
	return;
end