--------------------------------------
-- LootPrio
--------------------------------------
-- Collection of items with associated priority
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
LootPrio = {
	items = {},-- hash table mapping lootName to Prio object
	edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
	edit_ts_generic = nil, -- timestamp of most recent edit (non-raid)
}; 
LootPrio.__index = LootPrio;

function LootPrio:new(loot_prio)
	if loot_prio == nil then
		-- initalize fresh
		local obj = {};
		obj.items = {};
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
		setmetatable(obj,LootPrio);
		return obj;
	else
		-- set metatable of existing table
		for key,value in pairs(loot_prio.items) do
			loot_prio.items[key] = Prio:new(loot_prio.items[key]);
		end
		setmetatable(loot_prio,LootPrio);
		return loot_prio;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function LootPrio:length()
	local count = 0;
	for _ in pairs(self.items) do count = count + 1 end
	return count;
end

function LootPrio:Exists(lootName)
	-- returns true if given name is in data
	return self.items[lootName] ~= nil;
end

function LootPrio:GetSKList(lootName)
	if lootName == nil then return nil end
	if not self:Exists(lootName) then return nil end
	return self.items[lootName].sk_list;
end

function LootPrio:GetReserved(lootName)
	if lootName == nil then return nil end
	if not self:Exists(lootName) then return nil end
	return self.items[lootName].reserved;
end

function LootPrio:GetDE(lootName)
	if lootName == nil then return nil end
	if not self:Exists(lootName) then return nil end
	return self.items[lootName].DE;
end

function LootPrio:GetOpenRoll(lootName)
	if lootName == nil then return nil end
	if not self:Exists(lootName) then return nil end
	return self.items[lootName].open_roll;
end

function LootPrio:GetPrio(lootName,spec_idx)
	if lootName == nil then return nil end
	if not self:Exists(lootName) then return nil end
	return self.items[lootName].prio[spec_idx];
end

function LootPrio:IsElligible(lootName,char_name)
	-- character is elligible if their spec is non null in the loot prio
	local spec_idx = SKC_DB.GuildData:GetSpecIdx(char_name);
	local elligible = false;
	if spec_idx == nil then 
		elligible = false;
	else
		elligible = self:GetPrio(lootName,spec_idx) ~= PRIO_TIERS.PASS;
	end
	if LOOT_VERBOSE then
		if elligible then 
			SKC_Main:Print("NORMAL",char_name.." is elligible for "..lootName);
		else
			SKC_Main:Print("ERROR",char_name.." is not elligible for "..lootName);
		end
	end
	return elligible;
end

function LootPrio:PrintPrio(lootName,lootLink)
	-- prints the prio of given item (or item link)
	local data;
	if lootName == nil then
		SKC_Main:Print("NORMAL","Loot Prio contains "..self:length().." items");
		return;
	elseif self.items[lootName] == nil then
		SKC_Main:Print("ERROR","Item name not found in prio database");
		return;
	else
		data = self.items[lootName];
		print(" ");
		if lootLink == nil then 
			SKC_Main:Print("IMPORTANT",lootName);
		else
			SKC_Main:Print("IMPORTANT",lootLink);
		end
	end
	-- print associated sk list
	SKC_Main:Print("NORMAL","SK List: "..data.sk_list);
	-- print reserved states
	if data.reserved then
		SKC_Main:Print("NORMAL","Reserved: TRUE");
	else
		SKC_Main:Print("NORMAL","Reserved: FALSE");
	end
	-- print disenchant or guild bank default
	if data.DE then
		SKC_Main:Print("NORMAL","All Pass: Disenchant");
	else
		SKC_Main:Print("NORMAL","All Pass: Guild Bank");
	end
	-- print open roll
	if data.open_roll then
		SKC_Main:Print("NORMAL","Open Roll: TRUE");
	else
		SKC_Main:Print("NORMAL","Open Roll: FALSE");
	end
	-- create map from prio level to concatenated string of SpecClass's
	local spec_class_map = {};
	for i = 1,6 do
		spec_class_map[i] = {};
	end
	for spec_class_idx,plvl in pairs(data.prio) do
		if plvl ~= PRIO_TIERS.PASS then spec_class_map[plvl][#(spec_class_map[plvl]) + 1] = CLASS_SPEC_MAP[spec_class_idx] end
	end
	for plvl,tbl in ipairs(spec_class_map) do
		if plvl == 6 then
			SKC_Main:Print("NORMAL","OS Prio:");
		else
			SKC_Main:Print("NORMAL","MS Prio "..plvl..":");
		end
		for _,spec_class in pairs(tbl) do
			local hex = select(4, GetSpecClassColor(spec_class));
			DEFAULT_CHAT_FRAME:AddMessage("         "..string.format("|cff%s%s|r",hex:upper(),spec_class));
		end
	end
	print(" ");
	return;
end