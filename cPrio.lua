--------------------------------------
-- Prio
--------------------------------------
-- Represents priority and other meta data about possible loot
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
Prio = {
	sk_list = nil, -- associated sk_list
	reserved = false, -- true if main prio over alts
	DE = false, -- true if item should be disenchanted before going to guild banker
	open_roll = false, -- open roll for this tiem
	prio = {}, -- map of SpecClass to prio level (P1,P2,P3,P4,P5)
};
Prio.__index = Prio;

function Prio:new(prio)
	if prio == nil then
		-- initalize fresh
		local obj = {};
		obj.prio = {}; -- default is equal prio for all (considered OS for all)
		obj.reserved = false;
		obj.DE = false;
		obj.open_roll = false;
		obj.sk_list = "MSK";
		setmetatable(obj,Prio);
		return obj;
	else
		-- set metatable of existing table
		setmetatable(prio,Prio);
		return prio;
	end
end
--------------------------------------
-- METHODS
--------------------------------------