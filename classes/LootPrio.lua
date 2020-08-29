--------------------------------------
-- LootPrio
--------------------------------------
-- Collection of items with associated priority
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
LootPrio = {
	items = {},-- hash table mapping lootName to Prio object
	edit_ts = nil, -- timestamp of most recent edit
}; 
LootPrio.__index = LootPrio;

function LootPrio:new(loot_prio)
	if loot_prio == nil then
		-- initalize fresh
		local obj = {};
		obj.items = {};
		obj.edit_ts = 0;
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

function LootPrio:GetSKReserved(lootName)
	if lootName == nil then return nil end
	if not self:Exists(lootName) then return nil end
	return self.items[lootName].sk_res;
end

function LootPrio:GetRollReserved(lootName)
	if lootName == nil then return nil end
	if not self:Exists(lootName) then return nil end
	return self.items[lootName].roll_res;
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
	local spec_idx = SKC.db.char.GD:GetSpecIdx(char_name);
	local elligible = false;
	if spec_idx == nil then 
		elligible = false;
	else
		elligible = self:GetPrio(lootName,spec_idx) ~= SKC.PRIO_TIERS.PASS;
	end
	return elligible;
end

function LootPrio:PrintPrio(lootName,lootLink)
	-- prints the prio of given item (or item link)
	local data;
	if lootName == nil then
		SKC:Print("Loot Prio contains "..self:length().." items");
		return;
	elseif self.items[lootName] == nil then
		SKC:Error("Item not found in Loot Prio");
		return;
	else
		data = self.items[lootName];
		if lootLink == nil then 
			SKC:Alert(lootName);
		else
			SKC:Alert(lootLink);
		end
	end
	-- print associated sk list
	print("|cff"..SKC.THEME.PRINT.HELP.hex.."SK List:|r "..data.sk_list);
	-- print SK reserved state
	if data.sk_res then
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."SK Reserved:|r TRUE");
	else
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."SK Reserved:|r FALSE");
	end
	-- print open roll
	if data.open_roll then
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."Open Roll:|r TRUE");
	else
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."Open Roll:|r FALSE");
	end
	-- print Roll reserved state
	if data.roll_res then
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."Roll Reserved:|r TRUE");
	else
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."Roll Reserved:|r FALSE");
	end
	-- print disenchant or guild bank default
	if data.DE then
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."All Pass:|r Disenchant");
	else
		print("|cff"..SKC.THEME.PRINT.HELP.hex.."All Pass:|r Guild Bank");
	end
	-- create map from prio level to concatenated string of SpecClass's
	local spec_class_map = {};
	for i = 1,6 do
		spec_class_map[i] = {};
	end
	for spec_class_idx,plvl in pairs(data.prio) do
		if plvl ~= SKC.PRIO_TIERS.PASS then spec_class_map[plvl][#(spec_class_map[plvl]) + 1] = SKC.CLASS_SPEC_MAP[spec_class_idx] end
	end
	for plvl,tbl in ipairs(spec_class_map) do
		if plvl == 6 then
			print("|cff"..SKC.THEME.PRINT.HELP.hex.."OS Prio:|r");
		else
			print("|cff"..SKC.THEME.PRINT.HELP.hex.."MS Prio "..plvl..":|r");
		end
		for _,spec_class in pairs(tbl) do
			local hex = select(4, SKC:GetSpecClassColor(spec_class));
			DEFAULT_CHAT_FRAME:AddMessage("        "..string.format("|cff%s%s|r",hex:upper(),spec_class));
		end
	end
	return;
end