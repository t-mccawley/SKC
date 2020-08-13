--------------------------------------
-- SimpleMap
--------------------------------------
-- A simple map with edit timestamp tracking
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
SimpleMap = {
	data = {}, --a hash table that maps elements to true boolean
	edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
	edit_ts_generic = nil, -- timestamp of most recent edit
};
SimpleMap.__index = SimpleMap;

function SimpleMap:new(simple_map)
	if simple_map == nil then
		-- initalize fresh
		local obj = {};
		obj.data = {};
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
		setmetatable(obj,SimpleMap);
		return obj;
	else
		-- set metatable of existing table and all sub tables
		setmetatable(simple_map,SimpleMap);
		return simple_map;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function SimpleMap:SetEditTime()
	local ts = time();
	self.edit_ts_generic = ts;
	if CheckActive() then self.edit_ts_raid = ts end
	return;
end

function SimpleMap:length()
	local count = 0;
	for _ in pairs(self.data) do count = count + 1 end
	return count;
end

function SimpleMap:Show()
	-- shows data
	local empty = true;
	for val,_ in pairs(self.data) do
		SKC_Main:Print("NORMAL",val);
		empty = false;
	end
	if empty then SKC_Main:Print("WARN","Empty") end
	return;
end

function SimpleMap:Add(element)
	-- adds element to data
	if (element == nil) then
		SKC_Main:Print("ERROR","Input cannot be nil");
		return false;
	end
	if self.data[element] then
		SKC_Main:Print("WARN",element.." already in list");
		return false;
	end
	if (self:length() == 19) then
		-- 19 names x 13 characters (12 + comma) = 247 < 250 character limit for msg
		SKC_Main:Print("ERROR","List can only contain 19 elements");
		return false;
	end
	-- add to list
	self.data[element] = true;
	-- update edit ts
	self:SetEditTime();
	return true;
end

function SimpleMap:Remove(element)
	-- remove element from data
	if (element == nil) then
		SKC_Main:Print("ERROR","Input cannot be nil");
		return false;
	end
	if self.data[element] == nil then
		SKC_Main:Print("ERROR","Input not found in list");
		return false;
	end
	-- remove from list
	self.data[element] = nil;
	-- update edit ts
	self:SetEditTime();
	return true;
end

function SimpleMap:Clear()
	-- clears a simple list
	self.data = {};
	-- update edit ts
	self:SetEditTime();
	return true;
end