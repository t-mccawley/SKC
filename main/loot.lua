--------------------------------------
-- LOOT DECISION
--------------------------------------
local function SaveLoot()
	-- Scans items / characters and stores loot in LootManager
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	-- Check that player is ML
	if not SKC_Main:isML() then return end

	if LOOT_SAFE_MODE then 
		SKC_Main:Print("WARN","Loot Safe Mode");
		return;
	end

	-- Update SKC Active flag
	SKC_Main:RefreshStatus();

	if not CheckActive() then
		SKC_Main:Print("WARN","SKC not active. Skipping loot distribution.");
		return;
	end

	-- Check if loot decision already pending
	if SKC_DB.LootManager:LootDecisionPending() then return end

	-- Check if sync in progress
	if CheckIfReadInProgress() or CheckIfPushInProgress() then
		SKC_Main:Print("IMPORTANT","Synchronization in progress. Loot distribution will start soon...");
	end
	
	-- Reset LootManager
	SKC_DB.LootManager:Reset();
	
	-- Scan all items and save each item / elligible player
	if LOOT_VERBOSE then SKC_Main:Print("IMPORTANT","Starting Loot Distribution") end
	local loot_cnt = 1;
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		-- local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
		local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot);
		if lootName ~= nil then
			-- Only perform SK for items if they are found in loot prio
			if SKC_DB.GLP.loot_prio:Exists(lootName) then
				-- Valid item
				local lootLink = GetLootSlotLink(i_loot);
				-- Store item
				local loot_idx = SKC_DB.LootManager:AddLoot(lootName,lootLink);
				-- Alert raid of new item
				local msg = "["..loot_cnt.."] "..lootLink;
				SendChatMessage(msg,"RAID_WARNING");
				loot_cnt = loot_cnt + 1;
				-- Scan all possible characters to determine elligible
				local any_elligible = false;
				for i_char = 1,40 do
					local char_name = GetMasterLootCandidate(i_loot,i_char);
					if char_name ~= nil then
						if SKC_DB.GLP.loot_prio:IsElligible(lootName,char_name) then 
							SKC_DB.LootManager:AddCharacter(char_name,loot_idx);
							any_elligible = true;
						end
					end
				end
				-- check that at least one character was elligible
				if not any_elligible then
					if LOOT_VERBOSE then SKC_Main:Print("WARN","No elligible characters in raid. Giving directly to ML.") end
					-- give directly to ML
					SKC_DB.LootManager:GiveLootToML(lootName,lootLink);
					SKC_DB.LootManager:MarkLootAwarded(lootName);
					WriteToLog( 
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
				if LOOT_VERBOSE then SKC_Main:Print("WARN","Item not in Loot Prio. Giving directly to ML.") end
				-- give directly to ML
				SKC_DB.LootManager:GiveLootToML(lootName,GetLootSlotLink(i_loot));
				SKC_DB.LootManager:MarkLootAwarded(lootName);
				WriteToLog( 
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
	SKC_DB.LootManager:KickOff();
	return;
end