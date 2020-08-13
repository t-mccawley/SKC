--------------------------------------
-- CharacterData
--------------------------------------
-- Data about an individual character in the guild
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
CharacterData = {
	Name = nil, -- character name
	Class = nil, -- character class
	Spec = nil, -- character specialization (val)
	["Raid Role"] = nil, --DPS, Healer, or Tank
	["Guild Role"] = nil, --Disenchanter, Guild Banker, or None
	Status = nil, -- Main or Alt
	Activity = nil, -- Active or Inactive
	last_live_time = nil, -- most recent time added to ANY live list
}
CharacterData.__index = CharacterData;

function CharacterData:new(character_data,name,class)
	if character_data == nil then
		-- initalize fresh
		local obj = {};
		obj.Name = name;
		obj.Class = class;
		local default_spec = CLASSES[class].DEFAULT_SPEC;
		obj.Spec = CLASSES[class].Specs[default_spec].val;
		obj["Raid Role"] = CHARACTER_DATA["Raid Role"].OPTIONS[CLASSES[class].Specs[default_spec].RR].val;
		obj["Guild Role"] = CHARACTER_DATA["Guild Role"].OPTIONS.None.val;
		obj.Status = CHARACTER_DATA.Status.OPTIONS.Main.val;
		obj.Activity = CHARACTER_DATA.Activity.OPTIONS.Active.val;
		obj.last_live_time = time();
		setmetatable(obj,CharacterData);
		return obj;
	else
		-- set metatable of existing table
		setmetatable(character_data,CharacterData);
		return character_data;
	end
end
--------------------------------------
-- METHODS
--------------------------------------