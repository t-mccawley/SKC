--------------------------------------
-- GuildLeaderProtected
--------------------------------------
-- Data which is guild leader protected, i.e. this data is only sent by the GL and reading this data requires confirmation that it is coming from the GL
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
GuildLeaderProtected = {
	addon_ver = nil, -- addon version of the guild leader
	loot_decision_time = nil, -- time in seconds that the loot GUI will wait before timeout
	loot_officers = nil, -- map of player names who are loot officers
	active_instances = nil, -- map of instance acronyms which enable the addon
	edit_ts = nil, -- timestamp of most recent edit
};
GuildLeaderProtected.__index = GuildLeaderProtected;

function GuildLeaderProtected:new(glp)
	if glp == nil then
		-- initalize fresh
		local obj = {};
		obj.addon_ver = nil;
		obj.loot_decision_time = SKC.LOOT_DECISION.DEFAULT_DECISION_TIME;
		obj.loot_officers = {};
		obj.active_instances = {
			ONY = true,
			MC = true,
			BWL = true,
			AQ40 = true,
			NAXX = true,
		};
		obj.edit_ts = 0;
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
	self.edit_ts = time();
	return;
end

function GuildLeaderProtected:SetAddonVer(ver)
	-- sets guild leader addon version
	if not SKC:isGL() then
		SKC:Error("[SetAddonVer] You must be guild leader to do that")
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

function GuildLeaderProtected:SetLootDecisionTime(val)
	if not SKC:isGL() then
		SKC:Error("[SetLootDecisionTime] You must be guild leader to do that")
		return false;
	end
	-- check for valid input
	if val == nil or type(val) ~= "number" or val < SKC.LOOT_DECISION.MIN_DECISION_TIME or val > SKC.LOOT_DECISION.MAX_DECISION_TIME then
		SKC:Error("That is not a valid time, must be a number between "..SKC.LOOT_DECISION.MIN_DECISION_TIME.." and "..SKC.LOOT_DECISION.MAX_DECISION_TIME);
		return false;
	end
	self.loot_decision_time = val;
	self:SetEditTime();
	self:PrintLootDecisionTime();
	return true;
end

function GuildLeaderProtected:GetLootDecisionTime()
	return(self.loot_decision_time);
end

function GuildLeaderProtected:PrintLootDecisionTime()
	SKC:Print("The loot decision time is "..self.loot_decision_time.."s");
	return;
end

function GuildLeaderProtected:AddLO(lo_name,bypass)
	if not SKC:isGL() then
		SKC:Error("[AddLO] You must be guild leader to do that")
		return false;
	end
	-- check if valid guild member
	if not bypass and not SKC.db.char.GD:Exists(lo_name) then
		SKC:Error(lo_name.." is not a valid guild member");
		return false;
	end
	if not self.loot_officers[lo_name] then
		self.loot_officers[lo_name] = true;
		self:SetEditTime();
	end
	return true;
end

function GuildLeaderProtected:RemoveLO(lo_name)
	if not SKC:isGL() then
		SKC:Error("[RemoveLO] You must be guild leader to do that");
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
		SKC:Error("[ClearLO] You must be guild leader to do that");
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
		SKC:Error("[AddAI] You must be guild leader to do that");
		return false;
	end
	-- check if valid acro
	if SKC.INSTANCE_ID_MAP[ai_acro] == nil then
		SKC:Error("That is not a valid acronym. Please choose one of the following:");
		for acro,full_name in pairs(SKC.INSTANCE_NAME_MAP) do
			SKC:Print(acro.." ("..full_name..")");
		end
		return false;
	end
	if not self.active_instances[ai_acro] then
		self.active_instances[ai_acro] = true;
		self:SetEditTime();
	end
	return true;
end

function GuildLeaderProtected:RemoveAI(ai_acro)
	if not SKC:isGL() then
		SKC:Error("[RemoveAI] You must be guild leader to do that");
		return false;
	end
	self.active_instances[ai_acro] = nil;
	self:SetEditTime();
	return true;
end

function GuildLeaderProtected:ClearAI()
	if not SKC:isGL() then
		SKC:Error("[ClearAI] You must be guild leader to do that");
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
	local instance_name, _, _, _, _, _, _, instanceMapId, _ = GetInstanceInfo();
	for ai_acro,_ in pairs(self.active_instances) do
		if instanceMapId == SKC.INSTANCE_ID_MAP[ai_acro] then
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