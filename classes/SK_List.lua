--------------------------------------
-- SK_List
--------------------------------------
-- A doubly linked list and hash map where each node is referenced by player name. Each node is a SK_Node.
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
SK_List = { 
	top = nil, -- top name in list
	bottom = nil, -- bottom name in list
	list = {}, -- list of SK_Node
	edit_ts = nil, -- timestamp of most recent edit
};
SK_List.__index = SK_List;

function SK_List:new(sk_list)
	if sk_list == nil then
		-- initalize fresh
		local obj = {};
		obj.top = nil; 
		obj.bottom = nil;
		obj.list = {};
		obj.edit_ts = 0;
		setmetatable(obj,SK_List);
		return obj;
	else
		-- set metatable of existing table and all sub tables
		for key,value in pairs(sk_list.list) do
			sk_list.list[key] = SK_Node:new(sk_list.list[key]);
		end
		setmetatable(sk_list,SK_List);
		return sk_list;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function SK_List:SetEditTime()
	self.edit_ts = time();
	return;
end

function SK_List:Exists(name)
	-- returns true if given name is in data
	return self.list[name] ~= nil;
end

function SK_List:length()
	local count = 0;
	for _ in pairs(self.list) do count = count + 1 end
	return count;
end

function SK_List:GetPos(name)
	-- gets the absolute position of this node
	return self.list[name].abs_pos;
end

function SK_List:CheckIfFucked()
	-- checks integrity of list
	-- invalid if non empty list has nil bottom node or node below bottom is not nil
	if self:length() ~=0 then
		if self.bottom == nil then
			SKC:Error("Your sk list is fucked. Nil bottom.");
			return true;
		elseif self.list[self.bottom] == nil then
			SKC:Error("Your sk list is fucked. Bottom node ["..self.bottom.."] is not in list.");
			return true;
		elseif self.list[self.bottom].below ~= nil then
			SKC:Error("Your sk list is fucked. Below bottom node ["..self.bottom.."] is not nil.");
			return true;
		end
		return false;
	end
	return false;
end

function SK_List:ResetPos()
	-- resets absolute positions of all nodes
	if self:CheckIfFucked() then return false end
	-- scan list and assign positions
	local idx = 1;
	local current_name = self.top;
	while (current_name ~= nil) do
		self.list[current_name].abs_pos = idx;
		current_name = self.list[current_name].below;
		idx = idx + 1;
	end
	self:SetEditTime();
	return true;
end

function SK_List:PushTop(name)
	-- Push name on top
	-- check if current bottom
	if self.bottom == name then
		-- adjust new bottom
		local new_bot = self.list[name].above
		self.list[new_bot].below = nil;
		self.bottom = new_bot;
	else
		-- regular node
		-- Remove name from current spot
		local above_tmp = self.list[name].above;
		local below_tmp = self.list[name].below;
		self.list[above_tmp].below = below_tmp;
		self.list[below_tmp].above = above_tmp;
	end
	-- put on top
	self.list[self.top].above = name;
	self.list[name].below = self.top;
	self.list[name].above = name;
	-- adjust top tracker
	self.top = name;
	-- adjust position
	self:ResetPos();
	-- reset positions / adjust time
	self:SetEditTime();
	return true;
end

function SK_List:ReturnList()
	-- Returns list in ordered array
	-- check data integrity
	if self:CheckIfFucked() then return({}) end;
	-- Scan list in order
	local list_out = {};
	local current_name = self.top;
	while (current_name ~= nil) do
		list_out[self.list[current_name].abs_pos] = current_name;
		current_name = self.list[current_name].below;
	end
	return(list_out);
end

function SK_List:PrintNode(name)
	if self.list[name] == nil then
		SKC:Error(name.." not in list");
	elseif self.top == nil then
		SKC:Alert("EMPTY");
	elseif self.top == name and self.top == self.bottom then
		SKC:Alert("TOP-->["..self.list[name].abs_pos.."] "..name.."-->BOTTOM");
	elseif self.top == name then
		SKC:Alert("TOP-->["..self.list[name].abs_pos.."] "..name.."-->"..self.list[name].below);
	elseif self.bottom == name then
		SKC:Alert(self.list[name].above.."-->["..self.list[name].abs_pos.."] "..name.."-->BOTTOM");
	else
		SKC:Alert(self.list[name].above.."-->["..self.list[name].abs_pos.."] "..name.."-->"..self.list[name].below);
	end
	return;
end

function SK_List:PrintList()
	-- prints list in order
	-- check data integrity
	if self:CheckIfFucked() then return end;
	-- Scan list in order
	local current_name = self.top;
	while (current_name ~= nil) do
		self:PrintNode(current_name);
		current_name = self.list[current_name].below;
	end
	return;
end

function SK_List:InsertBelow(name,new_above_name,verbose)
	-- Insert item below new_above_name
	if name == nil then
		SKC:Error("nil name to SK_List:InsertBelow()");
		return false;
	end
	-- check special cases
	if self.top == nil then
		-- First node in list
		self.top = name;
		self.bottom = name;
		self.list[name] = SK_Node:new(self.list[name],name,nil);
		-- adjust position
		self:ResetPos();
		self:SetEditTime();
		if verbose then self:PrintNode(name) end
		return true;
	elseif name == new_above_name then
		-- do nothing
		return true;
	end
	if new_above_name == nil then
		SKC:Error("nil new_above_name for SK_List:InsertBelow()");
		return false;
	end
	-- check that new_above_name is in list
	if self.list[new_above_name] == nil then
		SKC:Error("New above, "..new_above_name..", not in list [insert]");
		return false 
	end
	-- Instantiates if does not exist
	if self.list[name] == nil then
		-- new node
		self.list[name] = SK_Node:new(self.list[name],nil,nil);
	else
		-- existing node
		if self:CheckIfFucked() then return false end
		if self.list[name].above == new_above_name then
			-- already in correct order
			if verbose then self:PrintNode(name) end
			return true;
		end
		-- remove name from list
		local above_tmp = self.list[name].above;
		local below_tmp = self.list[name].below;
		if name == self.top then
			-- name is current top
			self.list[below_tmp].above = below_tmp;
			self.top = below_tmp;
		elseif name == self.bottom then
			-- name is current bottom node
			self.list[above_tmp].below = nil;
			self.bottom = above_tmp;
		else
			-- name is middle node
			self.list[below_tmp].above = above_tmp;
			self.list[above_tmp].below = below_tmp;
		end
	end
	-- get new below
	local new_below_name = self.list[new_above_name].below;
	-- insert to new location
	self.list[name].above = new_above_name;
	self.list[name].below = new_below_name;
	-- adjust surrounding
	self.list[new_above_name].below = name;
	if new_below_name ~= nil then self.list[new_below_name].above = name end
	-- check if new bottom or top and adjust
	if self.list[name].below == nil then self.bottom = name end
	if self.list[name].above == name then self.top = name end
	-- adjust position
	self:ResetPos();
	self:SetEditTime();
	if verbose then self:PrintNode(name) end
	return true;
end

function SK_List:SetByPos(name,pos)
	-- sets the absolute position of given name
	local des_pos = pos;
	if self:CheckIfFucked() then return false end
	local curr_pos = self:GetPos(name);
	if pos == curr_pos then
		return true;
	elseif pos < curr_pos then
		-- desired position is above current position
		-- account for moving self node
		des_pos = des_pos - 1;
	end
	if des_pos == 0 then
		return self:PushTop(name);
	end
	-- find where to insert below
	local current_name = self.top;
	while (current_name ~= nil) do
		if (self:GetPos(current_name) == des_pos) then
			-- desired position found, insert
			return self:InsertBelow(name,current_name);
		end
		current_name = self.list[current_name].below;
	end
	return false;
end

function SK_List:PushBack(name)
	-- Pushes name to back (bottom) of list (creates if does not exist)
	return  self:InsertBelow(name,self.bottom);
end

function SK_List:SetSK(name,new_above_name)
	-- Removes player from list and sets them to specific location
	-- returns error if names not already i list
	if self.list[name] == nil or self.list[new_above_name] == nil then
		SKC:Error(name.." or "..new_above_name.." not in list");
		return false
	else
		return self:InsertBelow(name,new_above_name);
	end
end

function SK_List:Remove(name)
	-- removes character from sk list
	-- first push to back
	self:PushBack(name);
	-- get new bottom
	local bot = self.list[name].above;
	-- remove node
	self.list[name] = nil;
	-- update new bottom node
	self.list[bot].below = nil;
	self.bottom = bot;
	-- adjust position
	self:ResetPos();
	self:SetEditTime();
	return;
end

function SK_List:LiveSK(winner)
	-- Performs SK on live list on winner
	local success = false;
	if self:CheckIfFucked() then return false end

	-- create temporary live list
	local live_list = SK_List:new(nil);
	if live_list:CheckIfFucked() then return false end
	SKC:Debug("Live list created",SKC.DEV.VERBOSE.MERGE);

	-- push all live characters into live list
	-- scan list in order
	-- record live positions
	local live_pos = {};
	local current_name = self.top;
	while (current_name ~= nil) do
		if self.list[current_name].live then
			live_list:PushBack(current_name);
			live_pos[#live_pos + 1] = self:GetPos(current_name);
		end
		current_name = self.list[current_name].below;
	end
	if SKC.DEV.VERBOSITY_LEVEL >= SKC.DEV.VERBOSE.MERGE then
		SKC:Debug("Live List (Pre SK):",SKC.DEV.VERBOSE.MERGE);
		live_list:PrintList();
	end

	-- Perform SK on live list
	success = live_list:PushBack(winner);
	if not success then
		SKC:Error("Live SK failed");
		return false;
	end
	if SKC.DEV.VERBOSITY_LEVEL >= SKC.DEV.VERBOSE.MERGE then
		SKC:Debug("Live List (Post SK):",SKC.DEV.VERBOSE.MERGE);
		live_list:PrintList();
	end

	-- merge lists
	local merged_list = SK_List:new(nil);
	current_name = self.top;
	local live_name = live_list.top;
	SKC:Debug("Merging Lists...",SKC.DEV.VERBOSE.MERGE);
	while current_name ~= nil do
		local current_pos_tmp = self:GetPos(current_name);
		if live_name ~= nil and live_pos[live_list:GetPos(live_name)] == current_pos_tmp then
			-- live position, append live node
			merged_list:PushBack(live_name);
			-- update live status
			merged_list:SetLive(live_name,true);
			SKC:Debug("["..current_pos_tmp.."] [LIVE] "..live_name,SKC.DEV.VERBOSE.MERGE);
			-- increment
			live_name = live_list.list[live_name].below;
		else
			-- not live position, append current node
			merged_list:PushBack(current_name);
			SKC:Debug("["..current_pos_tmp.."] "..current_name,SKC.DEV.VERBOSE.MERGE);
		end
		-- increment
		current_name = self.list[current_name].below;
	end
	if SKC.DEV.VERBOSITY_LEVEL >= SKC.DEV.VERBOSE.MERGE then
		SKC:Debug("Merged List:",SKC.DEV.VERBOSE.MERGE);
		-- merged_list:PrintList();
	end

	success = live_name == nil;
	if not success then
		SKC:Error("Entire live list was not merged");
		return false;
	end

	-- deep copy
	self.list = SKC:DeepCopy(merged_list.list);
	self.top = merged_list.top;
	self.bottom = merged_list.bottom;
	self.edit_ts = merged_list.edit_ts;
	if SKC.DEV.VERBOSITY_LEVEL >= SKC.DEV.VERBOSE.MERGE then
		SKC:Debug("Final List:",SKC.DEV.VERBOSE.MERGE);
		-- self:PrintList();
	end
	SKC:Debug("Merge successful!",SKC.DEV.VERBOSE.MERGE);
	
	return true;
end

function SK_List:GetBelow(name)
	-- gets the name of the character below name
	return self.list[name].below;
end

function SK_List:SetLive(name,live_status)
	-- NOTE: this method does not change the edit timestamp
	if not self:Exists(name) then return false end
	self.list[name].live = live_status;
	return true;
end

function SK_List:GetLive(name)
	return self.list[name].live;
end