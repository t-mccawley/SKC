--------------------------------------
-- LootOfficerProtected
--------------------------------------
-- Data which is loot officer protected, i.e. this data is only sent by the LOs and reading this data requires confirmation that it is coming from the LOs
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
LootOfficerProtected = {
bench = nil, -- map of player names who are loot officers
edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
edit_ts_generic = nil, -- timestamp of most recent edit (non-raid)
};
LootOfficerProtected.__index = LootOfficerProtected;

function LootOfficerProtected:new(lop)
    if lop == nil then
        -- initalize fresh
        local obj = {};
        obj.bench = {};
        obj.edit_ts_raid = 0;
        obj.edit_ts_generic = 0;
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
-- local function ManageLiveLists(name,live_status)
-- 	-- adds / removes player to live lists and records time in guild data
-- 	local sk_lists = {"MSK","TSK"};
-- 	for _,sk_list in pairs(sk_lists) do
-- 		local success = self.db.char[sk_list]:SetLive(name,live_status);
-- 	end
-- 	-- update guild data if SKC is active
-- 	if CheckActive() then
-- 		local ts = time();
-- 		self.db.char.GD:SetLastLiveTime(name,ts);
-- 	end
-- 	return;
-- end

-- function SKC:UpdateLiveList()
-- 	-- Adds every player in raid to live list
-- 	-- All players update their own local live lists
-- 	if not self:CheckAddonLoaded() then return end
-- 	self:Debug("Updating live list",self.DEV.VERBOSE.RAID);

-- 	-- Activate SKC
-- 	self:RefreshStatus();

-- 	-- Scan raid and update live list
-- 	for char_name,_ in pairs(self.db.char.GD.data) do
-- 		ManageLiveLists(char_name,UnitInRaid(char_name) ~= nil);
-- 	end

-- 	-- Scan bench and adjust live
-- 	for char_name,_ in pairs(self.db.char.LOP.bench.data) do
-- 		ManageLiveLists(char_name,true);
-- 	end

-- 	-- populate data
-- 	self:PopulateData();
-- 	return;
-- end