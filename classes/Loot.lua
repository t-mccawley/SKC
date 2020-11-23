--------------------------------------
-- Loot
--------------------------------------
-- Collection of data used to make a loot decision about a given item
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
Loot = {
	lootID = nil, -- loot ID
	lootName = nil, -- item name
	lootIndex = nil, -- index of loot in LootFrame
	lootLink = nil, -- item link
	open_roll = false, -- if true, enables roll option
	sk_list = "MSK", -- name of associated sk list (MSK TSK)
	decisions = {}, -- map from character name to LOOT_DECISION
	prios = {}, -- map from character name to PRIO_TIERS
	rolls = {}, -- map from character name to roll
	sk_pos = {}, -- map from character sk positions at time of decision
}; 
Loot.__index = Loot;

function Loot:new(loot,item_id,item_name,loot_index,item_link,open_roll,sk_list)
	if loot == nil then
		-- initalize fresh
		local obj = {};
		obj.lootID = item_id;
		obj.lootName = item_name;
		obj.lootIndex = loot_index;
		obj.lootLink = item_link;
		obj.open_roll = open_roll or false;
		obj.sk_list = sk_list or "MSK";
		obj.decisions = {};
		obj.prios = {};
		obj.rolls = {};
		obj.sk_pos = {};
		setmetatable(obj,Loot);
		return obj;
	else
		-- set metatable of existing table
		setmetatable(loot,Loot);
		return loot;
	end
end
--------------------------------------
-- METHODS
--------------------------------------