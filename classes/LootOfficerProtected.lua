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