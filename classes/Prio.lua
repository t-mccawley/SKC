--------------------------------------
-- Prio
--------------------------------------
-- Represents priority and other meta data about possible loot
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
Prio = {
	sk_list = nil, -- associated sk_list
	sk_res = false, -- true if main has prio over alts on SK decisions
	open_roll = false, -- open roll for this tiem
	roll_res = false, -- true if main has prio over alts on roll decisions
	de = false, -- true if item should be disenchanted before going to guild banker
	prio = {}, -- map of SpecClass to prio level (P1,P2,P3,P4,P5)
};
Prio.__index = Prio;

function Prio:new(prio)
	if prio == nil then
		-- initalize fresh
		local obj = {};
		obj.sk_list = "NONE";
		obj.sk_res = false;
		obj.open_roll = false;
		obj.roll_res = false;
		obj.de = false;
		obj.prio = {};
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