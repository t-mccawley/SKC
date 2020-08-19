--------------------------------------
-- GuildLeaderProtected
--------------------------------------
-- Data which is guild leader protected, i.e. this data is only sent by the GL and reading this data requires confirmation that it is coming from the GL
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
GuildLeaderProtected = {
	addon_ver = nil, -- addon version of the guild leader
	loot_officers = nil, -- map of player names who are loot officers
	active_instances = nil, -- map of instance acronyms which enable the addon
	edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
	edit_ts_generic = nil, -- timestamp of most recent edit (non-raid)
};
GuildLeaderProtected.__index = GuildLeaderProtected;

function GuildLeaderProtected:new(glp)
	if glp == nil then
		-- initalize fresh
		local obj = {};
		obj.addon_ver = nil;
		obj.loot_officers = {};
		obj.active_instances = {};
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
		setmetatable(obj,GuildLeaderProtected);
		return obj;
	else
		-- set metatable of existing table and all sub tables
		setmetatable(glp,GuildLeaderProtected);
		return glp;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function GuildLeaderProtected:SetEditTime()
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC:CheckActive() then self.edit_ts_raid = ts end
	return;
end

function GuildLeaderProtected:SetAddonVer(ver)
	-- sets guild leader addon version
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return;
	end
	if ver ~= self.addon_ver then
		self.addon_ver = ver;
		self:SetEditTime();
	end
	return;
end

function GuildLeaderProtected:GetAddonVer()
	-- returns guild leader addon version
	return self.addon_ver;
end

function GuildLeaderProtected:GetNumLootOfficers()
	local cnt = 0;
	for _,_ in pairs(self.loot_officers) do cnt = cnt + 1 end
	return(cnt);
end

function GuildLeaderProtected:GetNumActiveInstances()
	local cnt = 0;
	for _,_ in pairs(self.active_instances) do cnt = cnt + 1 end
	return(cnt);
end

function GuildLeaderProtected:AddLO(lo_name,bypass)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return false;
	end
	-- check if valid guild member
	if not bypass and not SKC.db.char.GD:Exists(lo_name) then
		SKC:Error(lo_name.." is not a valid guild member");
		return false;
	end
	self.loot_officers[lo_name] = true;
	self:SetEditTime();
	return true;
end

function GuildLeaderProtected:RemoveLO(lo_name)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that");
		return false;
	end
	-- first check if removal candidate is guild leader (cannot remove)
	if lo_name == UnitName("player") then
		SKC:Error("The guild leader must be a loot officer");
		return false;
	end
	self.loot_officers[lo_name] = nil;
	self:SetEditTime();
	return true;
end

function GuildLeaderProtected:ClearLO()
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that");
		return false;
	end
	-- clear data
	self.loot_officers = {};
	-- re-add GL
	self:AddLO(UnitName("player"));
	self:SetEditTime();
	return true;
end

function GuildLeaderProtected:ShowLO()
	SKC:Alert("Loot Officers:");
	for lo_name,_ in pairs(self.loot_officers) do
		SKC:Print(lo_name);
	end
	return;
end

function GuildLeaderProtected:AddAI(ai_acro)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that");
		return false;
	end
	-- check if valid acro
	if SKC.INSTANCE_NAME_MAP[ai_acro] == nil then
		SKC:Error("That is not a valid acronym. Please choose one of the following:");
		for acro,full_name in pairs(SKC.INSTANCE_NAME_MAP) do
			SKC:Print(acro.." ("..full_name..")");
		end
		return false;
	end
	self.active_instances[ai_acro] = true;
	self:SetEditTime();
	return true;
end

function GuildLeaderProtected:RemoveAI(ai_acro)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that");
		return false;
	end
	self.active_instances[ai_acro] = nil;
	self:SetEditTime();
	return true;
end

function GuildLeaderProtected:ClearAI()
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that");
		return false;
	end
	-- clear data
	self.active_instances = {};
	self:SetEditTime();
	return true;
end

function GuildLeaderProtected:ShowAI()
	SKC:Alert("Active Instances:");
	for ai_acro,_ in pairs(self.active_instances) do
		SKC:Print(ai_acro);
	end
	return;
end

function GuildLeaderProtected:IsActiveInstance()
	-- returns true of current instance is active_instances
	local raid_name = GetInstanceInfo();
	for ai_acro,_ in pairs(self.active_instances) do
		if raid_name == SKC.INSTANCE_NAME_MAP[ai_acro] then
			return true;
		end
	end
	return false;
end

function GuildLeaderProtected:IsAddonVerMatch(ver)
	-- returns true if this client has addon version that matches guild leader version
	return(self.addon_ver == ver);
end

function GuildLeaderProtected:CheckIfLO(full_name)
	local name = SKC:StripRealmName(full_name);
	return(self.loot_officers[name]);
end