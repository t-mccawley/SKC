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
	self.addon_ver = ver;
	self:SetEditTime();
	return;
end

function GuildLeaderProtected:GetGLAddonVer()
	-- returns guild leader addon version
	return self.addon_ver;
end

function GuildLeaderProtected:GetNumLootOfficers()
	return(#self.loot_officers);
end

function GuildLeaderProtected:SetGLAddonVer(ver)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return;
	end
	-- updates GL version if it is different than previous version
	if self.addon_ver ~= ver then
		self.addon_ver = ver;
		self:SetEditTime();
	end
	return;
end

function GuildLeaderProtected:SetActivityThreshold(new_thresh)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return;
	end
	-- sets new activity threshold (input days, stored as seconds)
	self.activity_thresh = new_thresh;
	SKC_Main:RefreshStatus();
	self:SetEditTime();
	return;
end

function GuildLeaderProtected:GetActivityThreshold()
	-- returns activity threshold in days
	return self.activity_thresh;
end

function GuildLeaderProtected:AddLO(lo_name)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that")
		return;
	end
	self.loot_officers:Add(lo_name);
	self:SetEditTime();
	return;
end

function GuildLeaderProtected:RemoveLO(lo_name)
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that");
		return;
	end
	-- first check if removal candidate is guild leader (cannot remove)
	if lo_name == UnitName("player") then
		SKC:Error("You cannot remove the guild leader as a loot officer");
		return;
	end
	self.loot_officers:Remove(lo_name);
	self:SetEditTime();
	return;
end

function GuildLeaderProtected:ClearLO()
	if not SKC:isGL() then
		SKC:Error("You must be guild leader to do that");
		return;
	end
	-- clear data
	self.loot_officers:Clear();
	-- re-add GL
	self.loot_officers:Add(UnitName("player"));
	self:SetEditTime();
	return;
end

function GuildLeaderProtected:ShowLO()
	self.loot_officers:Show();
	return;
end

function GuildLeaderProtected:IsActiveInstance()
	-- returns true of current instance is active_instances
	if ACTIVE_RAID_OVRD then return true end
	if self.active_raids == nil or self.active_raids.data == nil then return false end
	local raid_name = GetInstanceInfo();
	for active_raid_acro,_ in pairs(self.active_raids.data) do
		if raid_name == RAID_NAME_MAP[active_raid_acro] then
			return true;
		end
	end
	return false;
end

function GuildLeaderProtected:IsAddonVerMatch()
	-- returns true if this client has addon version that matches guild leader version
	return(SKC_DB.AddonVersion == self:GetGLAddonVer());
end

function GuildLeaderProtected:IsLO(full_name)
	local name = StripRealmName(full_name);
	return(self.loot_officers.data[name]);
end