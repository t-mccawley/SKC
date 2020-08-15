--------------------------------------
-- SK_List
--------------------------------------
-- A doubly linked list table where each node is referenced by player name. Each node is a SK_Node.
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
SK_List = { 
	top = nil, -- top name in list
	bottom = nil, -- bottom name in list
	list = {}, -- list of SK_Node
	edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
	edit_ts_generic = nil, -- timestamp of most recent edit
};
SK_List.__index = SK_List;

function SK_List:new(sk_list)
	if sk_list == nil then
		-- initalize fresh
		local obj = {};
		obj.top = nil; 
		obj.bottom = nil;
		obj.list = {};
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
		setmetatable(obj,SK_List);
		return obj;
	else
		-- set metatable of existing table and all sub tables
		for key,value in pairs(sk_list.list) do
			sk_list.list[key] = SK_Node:new(sk_list.list[key],nil,nil);
		end
		setmetatable(sk_list,SK_List);
		return sk_list;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function SK_List:SetEditTime()
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC:CheckActive() then self.edit_ts_raid = ts end
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
			SKC:Error("Your sk list is fucked. Bottom node not in list.");
			return true;
		elseif self.list[self.bottom].below ~= nil then
			SKC:Error("Your sk list is fucked. Below bottom is not nil.");
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
	local idx = 1;
	local current_name = self.top;
	while (current_name ~= nil) do
		list_out[idx] = current_name;
		current_name = self.list[current_name].below;
		idx = idx + 1;
	end
	return(list_out);
end

function SK_List:PrintNode(name)
	if self.list[name] == nil then
		SKC:Error(name.." not in list");
	elseif self.top == nil then
		SKC:Alert("EMPTY");
	elseif self.top == name and self.top == self.bottom then
		SKC:Alert(name);
	elseif self.top == name then
		SKC:Alert("TOP-->"..name.."-->"..self.list[name].below);
	elseif self.bottom == name then
		SKC:Alert(self.list[name].above.."-->"..name.."-->BOTTOM");
	else
		SKC:Alert(self.list[name].above.."-->"..name.."-->"..self.list[name].below);
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
	self.list.bottom = bot;
	-- no need to update position because PushBack first
	return;
end

function SK_List:LiveSK(winner)
	-- Performs SK on live list on winner
	if LIVE_MERGE_VERBOSE then SKC:Alert("Live List Merge") end

	local success = false;
	if LIVE_MERGE_VERBOSE then SKC:Alert("Checking SK List") end
	if self:CheckIfFucked() then return false end

	-- create temporary live list
	local live_list = SK_List:new(nil);
	if LIVE_MERGE_VERBOSE then SKC:Alert("Temporary Live List Created") end

	if LIVE_MERGE_VERBOSE then SKC:Alert("Checking Live List") end
	if live_list:CheckIfFucked() then return false end

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
	if LIVE_MERGE_VERBOSE then
		SKC:Alert("Temporary Live List (Pre SK)")
		live_list:PrintList();
	end

	-- Perform SK on live list
	success = live_list:PushBack(winner);
	if LIVE_MERGE_VERBOSE then
		SKC:Alert("Temporary Live List (Post SK)")
		live_list:PrintList();
	end

	if not success then return false end

	-- merge lists
	-- scan live list in order and push back into original list
	local current_live = live_list.top;
	local live_idx = 1;
	while current_live ~= nil do
		local live_pos_tmp = live_pos[live_idx];
		SKC:Debug(" ",SKC.DEV.VERBOSE.MERGE);
		SKC:Debug("Live Character: "..current_live,SKC.DEV.VERBOSE.MERGE);
		SKC:Debug("Current Pos: "..self:GetPos(current_live),SKC.DEV.VERBOSE.MERGE);
		SKC:Debug("Planned Pos: "..live_pos_tmp,SKC.DEV.VERBOSE.MERGE);
		-- set new position in original list
		success = self:SetByPos(current_live,live_pos_tmp);
		if not success then
			SKC:Error("Failed to set "..current_live.." position to "..live_pos_tmp);
			return false;
		else
			SKC:Debug(current_live.." set to position "..self:GetPos(current_live),SKC.DEV.VERBOSE.MERGE);
			SKC:Debug(" ",SKC.DEV.VERBOSE.MERGE);
		end
		-- increment
		current_live = live_list.list[current_live].below;
		live_idx = live_idx + 1;
	end

	success = live_idx == (#live_pos + 1) and current_live == nil;
	if not success then
		SKC:Error("Entire live list was not merged")
		return false;
	end
	
	return true;
end

function SK_List:GetBelow(name)
	-- gets the name of the character below name
	return self.list[name].below;
end

function SK_List:SetLive(name,live_status)
	-- note, this method does not change the edit timestamp
	if not self:Exists(name) then return false end
	self.list[name].live = live_status;
	return true;
end

function SK_List:GetLive(name)
	return self.list[name].live;
end