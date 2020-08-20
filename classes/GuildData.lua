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
	if SKC:CheckActive() then self.edit_ts_raid = ts end
	return;
end

function GuildData:length()
	local count = 0;
	for _ in pairs(self.data) do count = count + 1 end
	return count;
end

function GuildData:GetFirstGuildRolesInRaid()
	-- scan raid and return first disenchanter and banker
	local disenchanter = nil;
	local banker = nil;
	for raidIndex = 1,40 do
		local char_name = GetRaidRosterInfo(raidIndex);
		if char_name ~= nil and SKC.db.char.GD:Exists(char_name) then
			if disenchanter == nil and self.data[char_name]["Guild Role"] == SKC.CHARACTER_DATA["Guild Role"].OPTIONS.Disenchanter.val then
				disenchanter = char_name;
			end
			if banker == nil and self.data[char_name]["Guild Role"] == SKC.CHARACTER_DATA["Guild Role"].OPTIONS.Banker.val then
				banker = char_name;
			end
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
		for _,data in pairs(SKC.CLASSES[class].Specs) do
			if data.val == value then
				return data.text;
			end
		end
	else
		for _,data in pairs(SKC.CHARACTER_DATA[field].OPTIONS) do
			if data.val == value then
				return data.text;
			end
		end
	end
end

function GuildData:SetData(name,field,value)
	-- assigns data based on field and string name of value
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return;
	end
	if field == "Name" or field == "Class" then
		self.data[name][field] = value;
	elseif field == "Spec" then
		local class = self.data[name].Class;
		self.data[name][field] = SKC.CLASSES[class].Specs[value].val;
	else
		self.data[name][field] = SKC.CHARACTER_DATA[field].OPTIONS[value].val;
	end
	-- update raid role
	if field == "Spec" then
		local class = self.data[name].Class;
		local spec = value;
		local raid_role = SKC.CLASSES[class].Specs[spec].RR;
		self.data[name]["Raid Role"] = SKC.CHARACTER_DATA["Raid Role"].OPTIONS[raid_role].val;
	end
	self:SetEditTime();
	return;
end

function GuildData:Exists(name)
	-- returns true if given name is in data
	return self.data[name] ~= nil;
end

function GuildData:Add(name,class)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return;
	end
	self.data[name] = CharacterData:new(nil,name,class);
	self:SetEditTime();
	return;
end

function GuildData:Remove(name)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return;
	end
	if not self:Exists(name) then return end
	self.data[name] = nil;
	self:SetEditTime();
	return;
end

function GuildData:GetClass(name)
	-- gets Class of given name
	if not self:Exists(name) then return nil end
	return self.data[name].Class;
end

function GuildData:GetSpecIdx(name)
	-- gets spec value of given name
	if not self:Exists(name) then return nil end
	return self.data[name].Spec;
end

function GuildData:GetSpecName(name)
	-- gets spec text name of given name
	if not self:Exists(name) then return nil end
	return SKC.SPEC_MAP[self:GetSpecIdx(name)];
end