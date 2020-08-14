--------------------------------------
-- GuildData
--------------------------------------
-- Collection of CharacterData for all guild members
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
GuildData = {
	data = {}, --a hash table that maps character name to CharacterData
	edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
	edit_ts_generic = nil, -- timestamp of most recent edit
};
GuildData.__index = GuildData;

function GuildData:new(guild_data)
	if guild_data == nil then
		-- initalize fresh
		local obj = {};
		obj.data = {};
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
		setmetatable(obj,GuildData);
		return obj;
	else
		-- set metatable of existing table and all sub tables
		for key,value in pairs(guild_data.data) do
			guild_data.data[key] = CharacterData:new(guild_data.data[key],nil,nil);
		end
		setmetatable(guild_data,GuildData);
		return guild_data;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function GuildData:SetEditTime()
	local ts = time();
	self.edit_ts_generic = ts;
	if CheckActive() then self.edit_ts_raid = ts end
	return;
end

function GuildData:length()
	local count = 0;
	for _ in pairs(self.data) do count = count + 1 end
	return count;
end

function GuildData:CalcActivity(name)
	-- calculate time difference (in seconds)
	return ((time() - self.data[name].last_live_time));
end

function GuildData:GetFirstGuildRoles()
	-- scan guild data and return first disenchanter and banker
	local disenchanter = nil;
	local banker = nil;
	for char_name,data_tmp in pairs(self.data) do
		if disenchanter == nil and data_tmp["Guild Role"] == CHARACTER_DATA["Guild Role"].OPTIONS.Disenchanter.val then
			disenchanter = char_name;
		end
		if banker == nil and data_tmp["Guild Role"] == CHARACTER_DATA["Guild Role"].OPTIONS.Banker.val then
			banker = char_name;
		end
	end
	return disenchanter, banker;
end

function GuildData:GetData(name,field)
	-- returns text for a given name and field
	local value = self.data[name][field];
	if field == "Name" or field == "Class" then
		return value;
	elseif field == "Spec" then
		local class = self.data[name].Class;
		for _,data in pairs(CLASSES[class].Specs) do
			if data.val == value then
				return data.text;
			end
		end
	else
		for _,data in pairs(CHARACTER_DATA[field].OPTIONS) do
			if data.val == value then
				return data.text;
			end
		end
	end
end

function GuildData:SetData(name,field,value)
	-- assigns data based on field and string name of value
	if field == "Name" or field == "Class" then
		self.data[name][field] = value;
	elseif field == "Spec" then
		local class = self.data[name].Class;
		self.data[name][field] = CLASSES[class].Specs[value].val;
	elseif field == "Activity" then
		local curr_str = self:GetData(name,field);
		local new_str = CHARACTER_DATA[field].OPTIONS[value].text
		if curr_str == "Active" and new_str == "Inactive" then
			SKC_DB.GuildData:SetLastLiveTime(name,time()-SKC_DB.GLP:GetActivityThreshold()*DAYS_TO_SECS);
		elseif curr_str == "Inactive" and new_str == "Active" then
			SKC_DB.GuildData:SetLastLiveTime(name,time());
		end
		self.data[name][field] = CHARACTER_DATA[field].OPTIONS[value].val;
	else
		self.data[name][field] = CHARACTER_DATA[field].OPTIONS[value].val;
	end
	-- update raid role
	if field == "Spec" then
		local class = self.data[name].Class;
		local spec = value;
		local raid_role = CLASSES[class].Specs[spec].RR;
		self.data[name]["Raid Role"] = CHARACTER_DATA["Raid Role"].OPTIONS[raid_role].val;
	end
	self:SetEditTime();
	return;
end

function GuildData:Exists(name)
	-- returns true if given name is in data
	return self.data[name] ~= nil;
end

function GuildData:Add(name,class)
	self.data[name] = CharacterData:new(nil,name,class);
	self:SetEditTime();
	return;
end

function GuildData:Remove(name)
	if not self:Exists(name) then return end
	self.data[name] = nil;
	self:SetEditTime();
	return;
end

function GuildData:GetClass(name)
	-- gets SpecClass of given name
	if not self:Exists(name) then return nil end
	return self.data[name].Class;
end

function GuildData:GetSpecIdx(name)
	-- gets spec value of given name
	if not self:Exists(name) then return nil end
	return self.data[name].Spec;
end

function GuildData:GetSpecName(name)
	-- gets spec value of given name
	if not self:Exists(name) then return nil end
	return SPEC_MAP[self:GetSpecIdx(name)];
end

function GuildData:SetLastLiveTime(name,ts)
	-- sets the last time the given player was on a live list
	if not self:Exists(name) then return end
	self.data[name].last_live_time = ts;
	return;
end