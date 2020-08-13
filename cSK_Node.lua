--------------------------------------
-- SK_Node
--------------------------------------
-- A node of an SK_List
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
SK_Node = {
	above = nil, -- character name above this character in ths SK list
	below = nil, -- character name below this character in the SK list
	abs_pos = nil, -- absolute position of this node in the full list
	live = false, -- used to indicate a node that is currently in the live list
};
SK_Node.__index = SK_Node;

function SK_Node:new(sk_node,above,below)
	if sk_node == nil then
		-- initalize fresh
		local obj = {};
		obj.above = above or nil;
		obj.below = below or nil;
		obj.abs_pos = 1;
		obj.live = false;
		setmetatable(obj,SK_Node);
		return obj;
	else
		-- set metatable of existing table
		setmetatable(sk_node,SK_Node);
		return sk_node;
	end
end
--------------------------------------
-- METHODS
--------------------------------------