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
}
CharacterData.__index = CharacterData;

function CharacterData:new(character_data,name,class)
	if character_data == nil then
		-- initalize fresh
		local obj = {};
		obj.Name = name;
		obj.Class = class;
		local default_spec = SKC.CLASSES[class].DEFAULT_SPEC;
		obj.Spec = SKC.CLASSES[class].Specs[default_spec].val;
		obj["Raid Role"] = SKC.CHARACTER_DATA["Raid Role"].OPTIONS[SKC.CLASSES[class].Specs[default_spec].RR].val;
		obj["Guild Role"] = SKC.CHARACTER_DATA["Guild Role"].OPTIONS.None.val;
		obj.Status = SKC.CHARACTER_DATA.Status.OPTIONS.Main.val;
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