--------------------------------------
-- LootOfficerProtected
--------------------------------------
-- Data which is loot officer protected, i.e. this data is only sent by the LOs and reading this data requires confirmation that it is coming from the LOs
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
LootOfficerProtected = {
    enabled = nil, -- primary manual control over SKC
    bench = nil, -- map of player names who are loot officers
    edit_ts = nil, -- timestamp of most recent edit
};
LootOfficerProtected.__index = LootOfficerProtected;

function LootOfficerProtected:new(lop)
    if lop == nil then
        -- initalize fresh
        local obj = {};
        obj.enabled = true;
        obj.bench = {};
        obj.edit_ts = 0;
        setmetatable(obj,LootOfficerProtected);
        return obj;
    else
        -- set metatable of existing table and all sub tables
        setmetatable(lop,LootOfficerProtected);
        return lop;
    end
end
--------------------------------------
-- METHODS
--------------------------------------
function LootOfficerProtected:SetEditTime()
	self.edit_ts = time();
	return;
end

function LootOfficerProtected:Enable(flag)
    if not SKC:isLO() then
		SKC:Error("You must be a loot officer to do that");
		return false;
    end
    self.enabled = flag;
    self:SetEditTime();
    SKC:RefreshStatus();
    return true;
end

function LootOfficerProtected:IsEnabled()
    return(self.enabled);
end

function LootOfficerProtected:AddBench(name)
	if not SKC:isLO() then
		SKC:Error("You must be a loot officer to do that");
		return false;
	end
	-- check if valid guild member
	if not SKC.db.char.GD:Exists(name) then
		SKC:Error(name.." is not a valid guild member");
		return false;
	end
	self.bench[name] = true;
    self:SetEditTime();
	return true;
end

function LootOfficerProtected:RemoveBench(name)
	if not SKC:isLO() then
		SKC:Error("You must be a loot officer to do that");
		return false;
	end
	self.bench[name] = nil;
    self:SetEditTime();
	return true;
end

function LootOfficerProtected:ClearBench()
	if not SKC:isLO() then
		SKC:Error("You must be a loot officer to do that");
		return false;
	end
	-- clear data
	self.bench = {};
    self:SetEditTime();
	return true;
end

function LootOfficerProtected:ShowBench()
	SKC:Alert("Bench:");
	for name,_ in pairs(self.bench) do
		SKC:Print(name);
	end
	return;
end