--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...; -- returns name of addon and namespace (core)
core.SKC_Main = {}; -- adds SKC_Main table to addon namespace

local SKC_Main = core.SKC_Main; -- assignment by reference in lua, ugh
local SKC_UIMain;

SKC_Main.VarsLoaded = false;
SKC_Main.DISTRIBUTION_CHANNEL = "xBPE9,-Fjbc+A#rm";
SKC_Main.SYNC_CHANNEL = "&95n%nR2!&;QZJSh";
SKC_Main.DECISION_CHANNEL = "ksg(AkE.*/@&+`8Q";
SKC_Main.RARITY_THRESHOLD = 2; -- greens
SKC_Main.LootDecision = nil;
SKC_Main.MasterLooter = nil;
SKC_Main.SK_Item = nil;
SKC_Main.SK_MessagesSent = 0;
SKC_Main.SK_MessagesReceived = 0;
SKC_Main.FilterStates = {
	SK1 = {
		DPS = true,
		Healer = true,
		Tank = true,
		Main = true,
		Alt = true,
		Active = true,
		Inactive = false,
		Druid = true,
		Hunter = true,
		Mage = true,
		Paladin = UnitFactionGroup("player") == "Alliance",
		Priest = true;
		Rogue = true,
		Shaman = UnitFactionGroup("player") == "Horde",
		Warlock = true,
		Warrior = true,
	},
};
--------------------------------------
-- DEFAULTS (usually a database!)
--------------------------------------
local OnClick_EditDropDownOption;
local DEFAULTS = {
	THEME = { 
		NORMAL = {r = 0, g = 0.8, b = 1, hex = "00ccff"},
		WARN = {r = 1, g = 0.8, b = 0, hex = "ffcc00"},
		ERROR = {r = 1, g = 0.2, b = 0, hex = "ff3300"},
		IMPORTANT = {r = 1, g = 0, b = 1, hex = "ff00ff"},
	},
	STATUS_BAR_COLOR = {0.0,0.6,0.0},
	LOOT_DECISIONS = {
		PASS = "PASS",
		SK = "SK",
		ROLL = "ROLL",
	},
	LOOT_DECISION_TIME_MAX = 30,
	LOOT_DECISION_TIME_STEP = 1,
	CLASS_COLORS = {
		Druid = {
			r = 1.0,
			g = 0.49,
			b = 0.04,
			hex = "FF7D0A"
		},
		Hunter = {
			r = 0.67, 
			g = 0.83,
			b = 0.45,
			hex = "ABD473"
		},
		Mage = {
			r = 0.41, 
			g = 0.80,
			b = 0.94,
			hex = "69CCF0"
		},
		Paladin = {
			r = 0.96, 
			g = 0.55,
			b = 0.73,
			hex = "F58CBA"
		},
		Priest = {
			r = 1.00, 
			g = 1.00,
			b = 1.00,
			hex = "FFFFFF"
		},
		Rogue = {
			r = 1.00, 
			g = 0.96,
			b = 0.41,
			hex = "FFF569"
		},
		Shaman = {
			r = 0.96, 
			g = 0.55,
			b = 0.73,
			hex = "F58CBA"
		},
		Warlock = {
			r = 0.58, 
			g = 0.51,
			b = 0.79,
			hex = "9482C9"
		},
		Warrior = {
			r = 0.78, 
			g = 0.61,
			b = 0.43,
			hex = "C79C6E"
		},
	},
	MAIN_WIDTH = 840,
	MAIN_HEIGHT = 450,
	SK_TAB_TOP_OFFST = -60,
	SK_TAB_TITLE_CARD_WIDTH = 80,
	SK_TAB_TITLE_CARD_HEIGHT = 40,
	SK_FILTER_WIDTH = 270,
	SK_FILTER_HEIGHT = 155,
	DECISION_WIDTH = 270,
	DECISION_HEIGHT = 180,
	SK_DETAILS_WIDTH = 270,
	SK_DETAILS_HEIGHT = 355,
	ITEM_WIDTH = 40,
	ITEM_HEIGHT = 40,
	SK_LIST_WIDTH = 175,
	SK_LIST_HEIGHT = 325,
	SK_LIST_BORDER_OFFST = 15,
	SK_CARD_SPACING = 6,
	SK_CARD_WIDTH = 100,
	SK_CARD_HEIGHT = 20,
	DET_OPTIONS = {
		de = {
			text = "DE",
			func = function (self) OnClick_EditDropDownOption("guild_role","DE") end,
		},
		gb = {
			text = "GB",
			func = function (self) OnClick_EditDropDownOption("guild_role","GB") end,
		},
		none = {
			text = "None",
			func = function (self) OnClick_EditDropDownOption("guild_role","None") end,
		},
		main = {
			text = "Main",
			func = function (self) OnClick_EditDropDownOption("status","Main") end,
		},
		alt = {
			text = "Alt",
			func = function (self) OnClick_EditDropDownOption("status","Alt") end,
		},
		active = {
			text = "Active",
			func = function (self) OnClick_EditDropDownOption("activity","Active") end,
		},
		inactive = {
			text = "Inactive",
			func = function (self) OnClick_EditDropDownOption("activity","Inactive") end,
		},
	},
	SPECS = {
		Druid = {
			Balance = {
				text = "Balance",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Balance") end,
			},
			Resto = {
				text = "Resto",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("spec","Resto") end
			},
		},
		Hunter = {
			Any = {
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Any") end
			},
		},
		Mage = {
			Any = {
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Any") end
			},
			Arcane = {
				text = "Arcane",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Arcane") end
			},
			Fire = {
				text = "Fire",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Fire") end
			},
			Frost = {
				text = "Frost",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Frost") end
			},
		},
		Priest = {
			Holy = {
				text = "Holy",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("spec","Holy") end
			},
			Shadow = {
				text = "Shadow",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Shadow") end
			},
		},
		Rogue = {
			Any = {
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Any") end
			},
			Daggers = {
				text = "Daggers",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Daggers") end
			},
			Swords = {
				text = "Swords",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Swords") end
			},
		},
		Warlock = {
			Any = {
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Any") end
			},
		},
		Warrior = {
			DPS = {
				text = "DPS",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","DPS") end
			},
			Prot = {
				text = "Prot",
				RR = "Tank",
				func = function (self) OnClick_EditDropDownOption("spec","Prot") end
			},
		},
		Shaman = {
			Ele = {
				text = "Ele",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Ele") end
			},
			Enh = {
				text = "Enh",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Enh") end
			},
			Resto = {
				text = "Resto",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("spec","Resto") end
			},
		},
		Paladin = {
			Holy = {
				text = "Holy",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("spec","Holy") end
			},
			Prot = {
				text = "Prot",
				RR = "Tank",
				func = function (self) OnClick_EditDropDownOption("spec","Prot") end
			},
			Ret = {
				text = "Ret",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("spec","Ret") end
			},
		},
	},
}
-- Add names with spaces
DEFAULTS.SPECS["Druid"]["Feral Tank"] = {};
DEFAULTS.SPECS["Druid"]["Feral Tank"].text = "Feral Tank";
DEFAULTS.SPECS["Druid"]["Feral Tank"].RR = "Tank";
DEFAULTS.SPECS["Druid"]["Feral Tank"].func = function (self) OnClick_EditDropDownOption("spec","Feral Tank") end
DEFAULTS.SPECS["Druid"]["Feral DPS"] = {};
DEFAULTS.SPECS["Druid"]["Feral DPS"].text = "Feral DPS";
DEFAULTS.SPECS["Druid"]["Feral DPS"].RR = "DPS";
DEFAULTS.SPECS["Druid"]["Feral DPS"].func = function (self) OnClick_EditDropDownOption("spec","Feral DPS") end
DEFAULTS.SPECS["Warrior"]["Two-handed"] = {};
DEFAULTS.SPECS["Warrior"]["Two-handed"].text = "Two-handed";
DEFAULTS.SPECS["Warrior"]["Two-handed"].RR = "DPS";
DEFAULTS.SPECS["Warrior"]["Two-handed"].func = function (self) OnClick_EditDropDownOption("spec","Two-handed") end
DEFAULTS.SPECS["Warrior"]["Dual Wield"] = {};
DEFAULTS.SPECS["Warrior"]["Dual Wield"].text = "Dual Wield";
DEFAULTS.SPECS["Warrior"]["Dual Wield"].RR = "DPS";
DEFAULTS.SPECS["Warrior"]["Dual Wield"].func = function (self) OnClick_EditDropDownOption("spec","Dual Wield") end
-- DEFAULTS.SPECS["Warrior"]["2H Swords"] = {};
-- DEFAULTS.SPECS["Warrior"]["2H Swords"].text = "2H Swords";
-- DEFAULTS.SPECS["Warrior"]["2H Swords"].RR = "DPS";
-- DEFAULTS.SPECS["Warrior"]["2H Swords"].func = function (self) OnClick_EditDropDownOption("spec","2H Swords") end
-- DEFAULTS.SPECS["Warrior"]["2H Axes"] = {};
-- DEFAULTS.SPECS["Warrior"]["2H Axes"].text = "2H Axes";
-- DEFAULTS.SPECS["Warrior"]["2H Axes"].RR = "DPS";
-- DEFAULTS.SPECS["Warrior"]["2H Axes"].func = function (self) OnClick_EditDropDownOption("spec","2H Axes") end
-- DEFAULTS.SPECS["Warrior"]["2H Maces"] = {};
-- DEFAULTS.SPECS["Warrior"]["2H Maces"].text = "2H Maces";
-- DEFAULTS.SPECS["Warrior"]["2H Maces"].RR = "DPS";
-- DEFAULTS.SPECS["Warrior"]["2H Maces"].func = function (self) OnClick_EditDropDownOption("spec","2H Maces") end
-- DEFAULTS.SPECS["Warrior"]["DW Swords"] = {};
-- DEFAULTS.SPECS["Warrior"]["DW Swords"].text = "DW Swords";
-- DEFAULTS.SPECS["Warrior"]["DW Swords"].RR = "DPS";
-- DEFAULTS.SPECS["Warrior"]["DW Swords"].func = function (self) OnClick_EditDropDownOption("spec","DW Swords") end
-- DEFAULTS.SPECS["Warrior"]["DW Axes"] = {};
-- DEFAULTS.SPECS["Warrior"]["DW Axes"].text = "DW Axes";
-- DEFAULTS.SPECS["Warrior"]["DW Axes"].RR = "DPS";
-- DEFAULTS.SPECS["Warrior"]["DW Axes"].func = function (self) OnClick_EditDropDownOption("spec","DW Axes") end
-- DEFAULTS.SPECS["Warrior"]["DW Maces"] = {};
-- DEFAULTS.SPECS["Warrior"]["DW Maces"].text = "DW Maces";
-- DEFAULTS.SPECS["Warrior"]["DW Maces"].RR = "DPS";
-- DEFAULTS.SPECS["Warrior"]["DW Maces"].func = function (self) OnClick_EditDropDownOption("spec","DW Maces") end
-- Specify default spec for initialization
DEFAULTS.SPECS["Druid"].Default = DEFAULTS.SPECS["Druid"].Resto;
DEFAULTS.SPECS["Hunter"].Default = DEFAULTS.SPECS["Hunter"].Any;
DEFAULTS.SPECS["Mage"].Default = DEFAULTS.SPECS["Mage"].Any;
DEFAULTS.SPECS["Priest"].Default = DEFAULTS.SPECS["Priest"].Holy;
DEFAULTS.SPECS["Rogue"].Default = DEFAULTS.SPECS["Rogue"].Any;
DEFAULTS.SPECS["Warlock"].Default = DEFAULTS.SPECS["Warlock"].Any;
DEFAULTS.SPECS["Warrior"].Default = DEFAULTS.SPECS["Warrior"].DPS;
DEFAULTS.SPECS["Shaman"].Default = DEFAULTS.SPECS["Shaman"].Resto;
DEFAULTS.SPECS["Paladin"].Default = DEFAULTS.SPECS["Paladin"].Holy;
--------------------------------------
-- Local Variables
--------------------------------------
local DD_State = 0; -- used to track state of drop down menu

--------------------------------------
-- Classes
--------------------------------------
-- Prio class
Prio = {
	{}, {}, {}, {}, {}, -- lists of SpecClass at each prio level (1 is highest prio)
	reserved = false,
	DE = true,
};
Prio.__index = Prio;

function Prio:new(prio)
	if prio == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,Prio);
		obj[1] = GetAllSpecClass();
		obj.reserved = false;
		obj.DE = true;
		return obj;
	else
		-- set metatable of existing table
		setmetatable(prio,Prio);
		return prio;
	end
end

-- LootPrio
LootPrio = {}; -- hash table mapping lootLink to Prio
Loot.__index = Loot;

function Loot:new(loot)
	if loot == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,Loot);
		obj.prio = { {}, {}, {}, {}, {}, };
		obj.prio = GetAllSpecClass();
		obj.reserved = false;
		obj.DE = true;
		return obj;
	else
		-- set metatable of existing table
		setmetatable(loot,Loot);
		return loot;
	end
end

-- SK_Node class
SK_Node = {
	above = nil, -- character name above this character in ths SK list
	below = nil, -- character name below this character in the SK list
	loot_decision = DEFAULTS.LOOT_DECISIONS.PASS, -- character current loot decision (PASS, SK, ROLL)
	loot_prio = 1; -- priority on given loot item
};
SK_Node.__index = SK_Node;

function SK_Node:new(sk_node,above,below)
	if sk_node == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,SK_Node);
		obj.above = above or nil;
		obj.below = below or nil;
		obj.loot_decision = DEFAULTS.LOOT_DECISIONS.PASS;
		return obj;
	else
		-- set metatable of existing table
		setmetatable(sk_node,SK_Node);
		return sk_node;
	end
end

-- SK_List class
SK_List = { --a doubly linked list table where each node is referenced by player name. Each node is a SK_Node:
	top = nil, -- top name in list
	bottom = nil, -- bottom name in list
	list = {}, -- list of SK_Node
};
SK_List.__index = SK_List;

function SK_List:new(sk_list)
	if sk_list == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,SK_List);
		obj.top = nil; 
		obj.bottom = nil; 
		obj.list = {};
		return obj;
	else
		-- set metatable of existing table and all sub tables
		setmetatable(sk_list,SK_List);
		for key,value in pairs(sk_list.list) do
			sk_list.list[key] = SK_Node:new(value,nil,nil);
		end
		return sk_list;
	end
end

function SK_List:CheckIfFucked()
	-- checks integrity of list
	if self.list[self.bottom].below ~= nil then
		SKC_Main:Print("ERROR","Your database is fucked.")
		return true;
	end
	return false;
end

function SK_List:Reset()
	-- Resets all player loot decisions to PASS and prio to 1
	for _,value in pairs(self.list) do 
		value.loot_decision = DEFAULTS.LOOT_DECISIONS.PASS;
		value.loot_prio = 1;
	end
	return;
end

function SK_List:PushBack(name)
	-- Push item to back of list (instantiate if doesnt exist)
	self.list[name] = SK_Node:new(self.list[name],nil,nil);
	if self.top == nil then
		-- First node in list
		self.top = name;
		self.bottom = name;
	else
		-- get current bottom name
		local bottom_tmp = self.bottom;
		-- adjust current bottom
		self.list[bottom_tmp].below = name;
		-- push to bottom
		self.list[name].above = bottom_tmp;
		self.list[name].bottom = nil;
		self.bottom = name;
	end
	return;
end

function SK_List:ReturnList()
	-- Returns list in ordered array
	-- check data integrity
	if self:CheckIfFucked() then return({}) end;
	-- Scan list in order
	local list_out = {};
	local idx = 1;
	local current_name = self.top;
	while (current_name ~= nil) do
		list_out[idx] = current_name;
		current_name = self.list[current_name].below;
		idx = idx + 1;
	end
	return(list_out);
end

function SK_List:FullSK(name)
	-- check if name is in SK list
	if self.list[name] == nil then
		-- name is not in SK list
		SKC_Main:Print("ERROR","Rejected, "..name.." not in SK List")
		return false;
	elseif name == self.bottom then
		return true;
	end
	-- make current above name point to below name and vice versa
	local above_tmp = self.list[name].above;
	local below_tmp = self.list[name].below;
	self.list[above_tmp].below = below_tmp; --TODO: FIX THIS FOR TOP SK
	self.list[below_tmp].above = above_tmp;
	-- remove character from list (will be recreated in PushBack)
	self.list[name] = nil;
	-- push to bottom
	self:PushBack(name);
	return true;
end

-- CharacterData class
CharacterData = {
	name = nil, -- character name
	class = nil, -- character class
	spec = nil, -- character specialization
	raid_role = nil, --DPS, Healer, or Tank
	guild_role = nil, --Disenchanter, Guild Banker, or None
	status = nil, -- Main or Alt
	activity = nil, -- Active or Inactive
	loot_history = {}, -- Table that maps timestamp to table with item (Rejuvenating Gem) and distribution method (SK1, Roll, DE, etc)
}
CharacterData.__index = CharacterData;

function CharacterData:new(character_data,name,class)
	if character_data == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,CharacterData);
		obj.name = name or nil;
		obj.class = class or nil;
		obj.spec = DEFAULTS.SPECS[class].Default.text;
		obj.raid_role = DEFAULTS.SPECS[class].Default.RR;
		obj.guild_role = DEFAULTS.DET_OPTIONS.none.text;
		obj.status = DEFAULTS.DET_OPTIONS.main.text;
		obj.activity = DEFAULTS.DET_OPTIONS.active.text;
		obj.loot_history = {};
		return obj;
	else
		-- set metatable of existing table
		setmetatable(character_data,CharacterData);
		return character_data;
	end
 end

-- GuildData class
GuildData = {} --a hash table that maps character name to CharacterData
GuildData.__index = GuildData;

function GuildData:new(guild_data)
	if guild_data == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,GuildData);
		return obj;
	else
		-- set metatable of existing table and all sub tables
		setmetatable(guild_data,GuildData);
		for key,value in pairs(guild_data) do CharacterData:new(value,nil,nil) end
		return guild_data;
	end
end

function GuildData:length()
	local count = 0;
	for _ in pairs(self) do count = count + 1 end
	return count;
end

function GuildData:Add(name,class)
	self[name] = CharacterData:new(nil,name,class);
	return;
end

--------------------------------------
-- local functions
--------------------------------------
local function GetAllSpecClass()
	-- Return a table of all SpecClass combinations
	local tbl_out = {};
	local idx = 1;
	for key1,value1 in pairs(DEFAULTS.SPECS) do
		local class = key1;
		for key2,value2 in pairs(DEFAULTS.SPECS[class]) do
			local spec = value2.text;
			if key2 ~= "Default" then
				tbl_out[idx] = spec..class;
			end
		end
	end
	return(tbl_out);
end

local function OnMouseWheel_ScrollFrame(self,delta)
    -- delta: 1 scroll up, -1 scroll down
	-- value at top is 0, value at bottom is size of child
	-- scroll so that one wheel is 3 SK cards
	local scroll_range = self:GetVerticalScrollRange();
	local inc = 3 * (DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING)
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (inc*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

local function OnCheck_FilterFunction (self, button)
	SKC_Main.FilterStates["SK1"][self.text:GetText()] = self:GetChecked();
	SKC_Main:UpdateSK("SK1");
	return;
end

local function Refresh_Details(name)
	local data = SKC_DB.GuildData[name];
	SKC_UIMain["Details_border"]["Name"].Data:SetText(data.name);
	SKC_UIMain["Details_border"]["Class"].Data:SetText(data.class);
	SKC_UIMain["Details_border"]["Class"].Data:SetTextColor(DEFAULTS.CLASS_COLORS[data.class].r,DEFAULTS.CLASS_COLORS[data.class].g,DEFAULTS.CLASS_COLORS[data.class].b,1.0);
	SKC_UIMain["Details_border"]["Spec"].Data:SetText(data.spec);
	SKC_UIMain["Details_border"]["Raid Role"].Data:SetText(data.raid_role);
	SKC_UIMain["Details_border"]["Guild Role"].Data:SetText(data.guild_role);
	SKC_UIMain["Details_border"]["Status"].Data:SetText(data.status);
	SKC_UIMain["Details_border"]["Activity"].Data:SetText(data.activity);
end

local function OnLoad_EditDropDown_Spec(self)
	local class = SKC_UIMain["Details_border"]["Class"].Data:GetText();
	for key,value in pairs(DEFAULTS.SPECS[class]) do
		if key ~= "Default" then
			UIDropDownMenu_AddButton(value);
		end
	end
	return;
end

local function OnLoad_EditDropDown_GuildRole(self)
	UIDropDownMenu_AddButton(DEFAULTS.DET_OPTIONS.de);
	UIDropDownMenu_AddButton(DEFAULTS.DET_OPTIONS.gb);
	UIDropDownMenu_AddButton(DEFAULTS.DET_OPTIONS.none);
	return;
end

local function OnLoad_EditDropDown_Status(self)
	UIDropDownMenu_AddButton(DEFAULTS.DET_OPTIONS.alt);
	UIDropDownMenu_AddButton(DEFAULTS.DET_OPTIONS.main);
	return;
end

local function OnLoad_EditDropDown_Activity(self)
	UIDropDownMenu_AddButton(DEFAULTS.DET_OPTIONS.active);
	UIDropDownMenu_AddButton(DEFAULTS.DET_OPTIONS.inactive);
	return;
end

function OnClick_EditDropDownOption(field,value)
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	local class = SKC_UIMain["Details_border"]["Class"].Data:GetText();
	-- Edit GuildData
	SKC_DB.GuildData[name][field] = value;
	-- Ensure Raid Role is in sync
	local spec = SKC_DB.GuildData[name]["spec"];
	SKC_DB.GuildData[name].raid_role = (DEFAULTS.SPECS[class][spec].RR);
	-- Refresh details
	Refresh_Details(name);
	-- Reset menu toggle
	DD_State = 0;
	return;
end

local function OnClick_EditDetails(self, button)
	if not self:IsEnabled() then return end
	-- SKC_UIMain.EditFrame:Show();
	local ID = self:GetID();
	-- Populate drop down options
	local field;
	if ID == 3 then
		field = "Spec";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_Spec) end
	elseif ID == 5 then
		-- Guild Role
		field = "Guild Role";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_GuildRole) end
	elseif ID == 6 then
		-- Status
		field = "Status";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_Status) end
	elseif ID == 7 then
		-- Activity
		field = "Activity";
		if DD_State ~= ID then UIDropDownMenu_Initialize(SKC_UIMain["Details_border"][field].DD,OnLoad_EditDropDown_Activity) end
	else
		SKC_Main:Print("ERROR","Menu not found.");
		return;
	end
	ToggleDropDownMenu(1, nil, SKC_UIMain["Details_border"][field].DD, SKC_UIMain["Details_border"][field].DD, 0, 0);
	if DD_State == ID then
		DD_State = 0;
	else
		DD_State = ID;
	end
	return;
end

local function OnClick_SK_Card(self, button)
	if button=='LeftButton' and self.Text:GetText() ~= nill and DD_State == 0 then
		-- Populate data
		Refresh_Details(self.Text:GetText());
		-- Enable edit buttons
		SKC_UIMain["Details_border"]["Spec"].Btn:Enable();
		SKC_UIMain["Details_border"]["Guild Role"].Btn:Enable();
		SKC_UIMain["Details_border"]["Status"].Btn:Enable();
		SKC_UIMain["Details_border"]["Activity"].Btn:Enable();
		SKC_UIMain["Details_border"].SingleSK_Btn:Enable();
		SKC_UIMain["Details_border"].FullSK_Btn:Enable();
	end
end

local function OnClick_FullSK(self)
	-- On click event for full SK of details targeted character
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	-- Execute full SK
	local sk_list = "SK1";
	SKC_Main:Print("IMPORTANT","Full SK on "..name);
	local success = SKC_DB.SK_Lists["SK1"]:FullSK(name);
	-- Refresh SK List
	SKC_Main:UpdateSK(sk_list);
	return;
end

local function OnClick_SingleSK(self)
	-- On click event for single SK of details targeted character
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	-- Execute single SK
	local sk_list = "SK1";
	SKC_Main:Print("IMPORTANT","Single SK on "..name);
	-- local success = SKC_DB.SK_Lists["SK1"]:FullSK(name);
	-- Refresh SK List
	SKC_Main:UpdateSK(sk_list);
	return;
end

local SetSK_Flag = false;
local function OnClick_SetSK(self)
	-- On click event to set SK position of details targeted character
	-- Prompt user to click desired position number in list
	SetSK_Flag = true;
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	SKC_Main:Print("IMPORTANT","Click desired position in SK list for "..name);
	return;
end

local function OnClick_NumberCard(self)
	-- On click event for number card in SK list
	if SetSK_Flag then
		local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
		-- Refresh SK List
		SKC_Main:UpdateSK(sk_list);
	end
end

local function OnMouseDown_ShowItemTooltip(self, button)
	--[[
		function ChatFrame_OnHyperlinkShow(chatFrame, link, text, button)
			SetItemRef(link, text, button, chatFrame);
		end
		https://wowwiki.fandom.com/wiki/API_ChatFrame_OnHyperlinkShow
		https://wowwiki.fandom.com/wiki/API_strfind

		chatFrame 
			table (Frame) - ChatFrame in which the link was clicked.
		link 
			String - The link component of the clicked hyperlink. (e.g. "item:6948:0:0:0...")
		text 
			String - The label component of the clicked hyperlink. (e.g. "[Hearthstone]")
		button 
			String - Button clicking the hyperlink button. (e.g. "LeftButton")
		
		itemLink ex:
			|cff9d9d9d|Hitem:3299::::::::20:257::::::|h[Fractured Canine]|h|r
		itemString ex:
			item:3299::::::::20:257::::::
		itemLabel ex:
			[Fractured Canine]
	--]]
	local decision_border_key = "Decision_border";
	local frame = SKC_UIMain[decision_border_key];
	local itemLink = SKC_UIMain[decision_border_key].ItemLink:GetText();
	local itemString = string.match(itemLink,"item[%-?%d:]+");
	local itemLabel = string.match(itemLink,"|h.+|h");
	SetItemRef(itemString, itemLabel, button, frame);
end

local function GetScrollMax()
	return((SKC_DB.UnFilteredCnt)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING));
end

local function SetSKItem()
	-- https://wow.gamepedia.com/ItemMixin
	-- local itemID = 19395; -- Rejuv
	-- Need to wrap in callback function to wait for item data to load
	local item = Item:CreateFromItemLink(SKC_Main.SK_Item)
	item:ContinueOnItemLoad(function()
		-- item:GetItemLink();
		local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(SKC_Main.SK_Item);
		-- Set texture icon and link
		local decision_border_key = "Decision_border";
		SKC_UIMain[decision_border_key].ItemTexture:SetTexture(texture);
		SKC_UIMain[decision_border_key].ItemLink:SetText(link);
	end)
end

local function SendLootDecision()
	C_ChatInfo.SendAddonMessage(SKC_Main.DECISION_CHANNEL,SKC_Main.LootDecision,"WHISPER",SKC_Main.MasterLooter);
end

local function InitTimerBarValue()
	SKC_UIMain["Decision_border"].TimerBar:SetValue(0);
	SKC_UIMain["Decision_border"].TimerText:SetText(DEFAULTS.LOOT_DECISION_TIME_MAX);
end

local function TimerBarHandler()
	local time_elapsed = SKC_UIMain["Decision_border"].TimerBar:GetValue() + DEFAULTS.LOOT_DECISION_TIME_STEP;

	-- updated timer bar
	SKC_UIMain["Decision_border"].TimerBar:SetValue(time_elapsed);
	SKC_UIMain["Decision_border"].TimerText:SetText(DEFAULTS.LOOT_DECISION_TIME_MAX - time_elapsed);

	if time_elapsed >= DEFAULTS.LOOT_DECISION_TIME_MAX then
		-- out of time
		-- send loot response
		SKC_Main:Print("WARN","Time expired. You PASS on "..SKC_Main.SK_Item);
		SKC_Main.LootDecision = DEFAULTS.LOOT_DECISIONS.PASS;
	end

	return;
end

local LootTimer = nil;
local function StartLootTimer()
	InitTimerBarValue();
	if LootTimer ~= nil and not LootTimer:IsCancelled() then LootTimer:Cancel() end
	-- start new timer
	LootTimer = C_Timer.NewTicker(DEFAULTS.LOOT_DECISION_TIME_STEP, TimerBarHandler, DEFAULTS.LOOT_DECISION_TIME_MAX/DEFAULTS.LOOT_DECISION_TIME_STEP);
	return;
end

local function StripRealmName(full_name)
	local name,_ = strsplit("-",full_name,2);
	return(name);
end

local function OnClick_PASS(self,button)
	if self:IsEnabled() then
		SKC_Main.LootDecision = DEFAULTS.LOOT_DECISIONS.PASS;
		LootTimer:Cancel()
		SendLootDecision();
	end
	return;
end

local function OnClick_SK(self,button)
	if self:IsEnabled() then
		SKC_Main.LootDecision = DEFAULTS.LOOT_DECISIONS.SK;
		LootTimer:Cancel()
		SendLootDecision();
	end
	return;
end

local function OnClick_ROLL(self,button)
	if self:IsEnabled() then
		SKC_Main.LootDecision = DEFAULTS.LOOT_DECISIONS.ROLL;
		LootTimer:Cancel()
		SendLootDecision();
	end
	return;
end

--------------------------------------
-- SKC_Main functions
--------------------------------------
function SKC_Main:Toggle(force_show)
	local menu = SKC_UIMain or SKC_Main:CreateMenu();
	menu:SetShown(force_show or not menu:IsShown());
	DD_State = 0;
	GetAllSpecClass();
end

function SKC_Main:GetThemeColor(type)
	local c = DEFAULTS.THEME[type];
	return c.r, c.g, c.b, c.hex;
end

function SKC_Main:Print(type,...)
    local hex = select(4, SKC_Main:GetThemeColor(type));
	local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

function SKC_Main:StartPersonalLootDecision()
	-- Begins personal loot decision process
	SKC_Main:Print("IMPORTANT","Would you like to SK for "..SKC_Main.SK_Item.."?");
	SKC_Main.LootDecision = DEFAULTS.LOOT_DECISIONS.PASS;
	-- Show UI
	SKC_Main:Toggle(true);
	-- Enable buttons
	SKC_UIMain["Decision_border"].Pass_Btn:Enable();
	SKC_UIMain["Decision_border"].SK_Btn:Enable();
	-- Set item
	SetSKItem();
	-- Initiate timer
	StartLootTimer();
	return;
end

function SKC_Main:DetermineWinner()
	-- Determine winner of loot decison
	-- TODO: Add loot prio logic here:
	-- 		for SK guys, store top SK char with highest prio (smallest number)
	-- 		add roll guys to list
	-- 		if SK heap isnt empty, pop top for winner
	-- 		if SK heap is empty, do rolls
	-- 		if roll list is empty, allocate to GB or DE
	-- 		if no DE, allocate to GB
	-- 		if no GB, give to ML
	-- Ensure data integrity of list before scanning
	if self:CheckIfFucked() then return(false) end;
	-- scan list in order
	local roll_list = {};
	local name_tmp = self.top;
	local idx = 1;
	while name_tmp ~= nil do
		local loot_decision_tmp = self.list[name_tmp].loot_decision;
		if loot_decision_tmp == DEFAULTS.LOOT_DECISIONS.SK then
			-- If character SK'd, they win!
			SKC_Main:Print("IMPORTANT",winner.." won "..SKC_Main.SK_Item.." by SK!");
			-- SK character
			local sk_success = SKC_DB.SK_Lists["SK1"]:FullSK(name);
			-- Give loot!
			local awarded_success = SKC_Main:AwardLoot(name);
			return(sk_success and awarded_success);

		elseif loot_decision_tmp == DEFAULTS.LOOT_DECISIONS.ROLL then
			-- Add character to roll list
			roll_list[idx] = name_tmp;
		end
		name_tmp = self.list[name_tmp].below;
	end
end

function SKC_Main:DetermineLootPrio(name)
	-- Returns loot prio for given character fir given SK item
	
end

function SKC_Main:AddonMessageRead(self,prefix,msg,channel,sender)
	if prefix == SKC_Main.SYNC_CHANNEL then
		DEFAULT_CHAT_FRAME:AddMessage("We should: "..msg);
	elseif prefix == SKC_Main.DISTRIBUTION_CHANNEL then
		--[[ 
			Listening: Everyone
		 	Talking: ML
		 --]]
		-- save master looter
		SKC_Main.MasterLooter = StripRealmName(sender);
		-- save item
		SKC_Main.SK_Item = msg;
		-- initiate personal loot decision
		SKC_Main:StartPersonalLootDecision();
	elseif prefix == SKC_Main.DECISION_CHANNEL then
		--[[ 
			Listening: ML
		 	Talking: Everyone
		 --]]
		 -- Increment message counter
		SKC_Main.SK_MessagesReceived = SKC_Main.SK_MessagesReceived + 1;
		-- Alert ML of decision
		local name = StripRealmName(sender);
		SKC_Main:Print("NORMAL",name.." wants to "..msg..".");
		-- Save loot decision
		SKC_DB.SK_Lists["SK1"].list[name].loot_decision = msg;
		-- Determine character prio
		SKC_DB.SK_Lists["SK1"].list[name].loot_prio = SKC_Main:DetermineLootPrio(name);
		-- check if all messages received
		if SKC_Main.SK_MessagesReceived >= SKC_Main.SK_MessagesSent then
			-- Determine winner and allocate loot
			local success = SKC_Main:DetermineWinner();
		end
	end
	return;
end

function SKC_Main:AwardLoot(name)
	-- Awards SKC_Main.SK_Item to given character
	for i_loot = 1, GetNumLootItems() do
		if GetLootSlotLink(i_loot) == SKC_Main.SK_Item then
			for i_char = 1,40 do
				if StripRealmName(GetMasterLootCandidate(i_loot,i_char)) == name then
					GiveMasterLoot(i_loot, i_char);
					SKC_Main:Print("IMPORTANT","Awarded "..SKC_Main.SK_Item.." to "..name..".");
					return true;
				end
			end
		end
	end
	SKC_Main:Print("ERROR","Could not award "..SKC_Main.SK_Item.." to "..name..".");
	return false;
end

function SKC_Main:InitiateLootDecision()
	-- Scans items / characters and initiates loot decisions for valid characters
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	if not IsMasterLooter() then return end
	-- Reset guild loot decisions and loot prio
	SKC_DB.SK_Lists["SK1"]:Reset();
	-- Reset message count
	SKC_Main.SK_MessagesReceived = 0;
	SKC_Main.SK_MessagesSent = 0;
	-- Determine item to start distribution event
	-- Initiate for first item
	local i_loot = 1;
	-- get item data
	local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
	local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot)
	-- Only perform SK for items of rarity threshold or higher
	if lootType == 1 and lootRarity >= SKC_Main.RARITY_THRESHOLD then
		-- Valid item
		SKC_Main.SK_Item = GetLootSlotLink(i_loot);
		SKC_Main:Print("NORMAL","Distributing "..SKC_Main.SK_Item);
		-- Scan all possible characters to distribute loot
		for i_char = 1,40 do
			local char_name = GetMasterLootCandidate(i_loot,i_char);
			-- determine if character is valid for given loot item / prio
			-- TODO add prio management
			if char_name ~= nil then
				-- send loot decision message
				SKC_Main.SK_MessagesSent = SKC_Main.SK_MessagesSent + 1;
				C_ChatInfo.SendAddonMessage(SKC_Main.DISTRIBUTION_CHANNEL,SKC_Main.SK_Item,"WHISPER",char_name);
			end
		end
	end
	return;
end

function SKC_Main:AddonLoad()
	SKC_Main.AddonLoaded = true;
	local hard_reset = false;
	-- Initialize 
	if SKC_DB == nil or hard_reset then 
		SKC_DB = {};
	end
	if SKC_DB.SK_Lists == nil or hard_reset then 
		SKC_DB.SK_Lists = {};
	end
	-- Initialize or refresh metatables
	SKC_DB.SK_Lists["SK1"] = SK_List:new(SKC_DB.SK_Lists["SK1"]);
	SKC_DB.GuildData = GuildData:new(SKC_DB.GuildData);
	-- SK_DB.LootPrio = GuildData:new(SKC_DB.LootPrio);
	SKC_DB.UnFilteredCnt = 0;
end

function SKC_Main:FetchGuildInfo()
	SKC_DB.InGuild = IsInGuild();
	if not SKC_DB.InGuild then
		SKC_Main:Print("ERROR","You are not in a guild.")
	end
	SKC_DB.NumGuildMembers = GetNumGuildMembers()
	-- Determine # of level 60s and add any new 60s
	local cnt = 0;
	for idx = 1, SKC_DB.NumGuildMembers do
		full_name, rank, rankIndex, level, class, zone, note, 
		officernote, online, status, classFileName, 
		achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(idx);
		if level == 60 then
			cnt = cnt + 1;
			local name = StripRealmName(full_name);
			if SKC_DB.GuildData[name] == nil then
				-- new player, add to DB and SK list
				SKC_DB.GuildData:Add(name,class);
				SKC_DB.SK_Lists["SK1"]:PushBack(name);
				SKC_Main:Print("NORMAL","["..cnt.."] "..name.." added to database!");
			end
		end
	end
	SKC_DB.Count60 = cnt;
	SKC_DB.UnFilteredCnt = cnt;
end

function SKC_Main:UpdateSK(sk_list)
	-- Addon not yet loaded, return
	if not SKC_Main.AddonLoaded then return end

	-- Hide all cards
	for idx = 1, SKC_DB.Count60 do
		SKC_UIMain[sk_list].NumberFrame[idx]:Hide();
		SKC_UIMain[sk_list].NameFrame[idx]:Hide();
	end

	-- Populate non filtered cards
	local print_order = SKC_DB.SK_Lists[sk_list]:ReturnList();
	local idx = 1;
	for key,value in ipairs(print_order) do
		local class_tmp = SKC_DB.GuildData[value].class;
		local raid_role_tmp = SKC_DB.GuildData[value].raid_role;
		local status_tmp = SKC_DB.GuildData[value].status;
		local activity_tmp = SKC_DB.GuildData[value].activity;
		-- only add cards to list which are not being filtered
		if SKC_Main.FilterStates["SK1"][class_tmp] and 
		   SKC_Main.FilterStates["SK1"][raid_role_tmp] and
		   SKC_Main.FilterStates["SK1"][status_tmp] and
		   SKC_Main.FilterStates["SK1"][activity_tmp] then
			-- Add number text
			SKC_UIMain[sk_list].NumberFrame[idx].Text:SetText(key)
			SKC_UIMain[sk_list].NumberFrame[idx]:Show();
			-- Add name text
			SKC_UIMain[sk_list].NameFrame[idx].Text:SetText(value)
			-- create class color background
			SKC_UIMain[sk_list].NameFrame[idx].bg:SetColorTexture(DEFAULTS.CLASS_COLORS[class_tmp].r,DEFAULTS.CLASS_COLORS[class_tmp].g,DEFAULTS.CLASS_COLORS[class_tmp].b,0.25);
			SKC_UIMain[sk_list].NameFrame[idx]:Show();
			-- increment
			idx = idx + 1;
		end
	end
	SKC_DB.UnFilteredCnt = idx;
	-- update scroll length
	SKC_UIMain[sk_list].SK_List_SF:GetScrollChild():SetSize(DEFAULTS.SK_LIST_WIDTH,GetScrollMax());
end

function SKC_Main:CreateUIBorder(title,width,height,x_pos,y_pos)
	-- Create Border
	local border_key = title.."_border";
	SKC_UIMain[border_key] = CreateFrame("Frame",border_key,SKC_UIMain,"TranslucentFrameTemplate");
	SKC_UIMain[border_key]:SetSize(width,height);
	SKC_UIMain[border_key]:SetPoint("TOP",SKC_UIMain,"TOP",x_pos,y_pos);
	SKC_UIMain[border_key].Bg:SetAlpha(0.0);
	-- Create Title
	local title_key = "title";
	SKC_UIMain[border_key][title_key] = CreateFrame("Frame",title_key,SKC_UIMain[border_key],"TranslucentFrameTemplate");
	SKC_UIMain[border_key][title_key]:SetSize(DEFAULTS.SK_TAB_TITLE_CARD_WIDTH,DEFAULTS.SK_TAB_TITLE_CARD_HEIGHT);
	SKC_UIMain[border_key][title_key]:SetPoint("BOTTOM",SKC_UIMain[border_key],"TOP",0,-20);
	SKC_UIMain[border_key][title_key].Text = SKC_UIMain[border_key][title_key]:CreateFontString(nil,"ARTWORK")
	SKC_UIMain[border_key][title_key].Text:SetFontObject("GameFontNormal")
	SKC_UIMain[border_key][title_key].Text:SetPoint("CENTER",0,0)
	SKC_UIMain[border_key][title_key].Text:SetText(title)

	return border_key
end

function SKC_Main:CreateMenu()
	-- If addon not yet loaded, reject
	if not SKC_Main.AddonLoaded then return end

	-- Fetch guild info into SK DB
	SKC_Main:FetchGuildInfo()

    SKC_UIMain = CreateFrame("Frame", "SKC_UIMain", UIParent, "UIPanelDialogTemplate");
	SKC_UIMain:SetSize(DEFAULTS.MAIN_WIDTH,DEFAULTS.MAIN_HEIGHT);
	SKC_UIMain:SetPoint("CENTER");
	SKC_UIMain:SetMovable(true)
	SKC_UIMain:EnableMouse(true)
	SKC_UIMain:RegisterForDrag("LeftButton")
	SKC_UIMain:SetScript("OnDragStart", SKC_UIMain.StartMoving)
	SKC_UIMain:SetScript("OnDragStop", SKC_UIMain.StopMovingOrSizing)
	SKC_UIMain:SetAlpha(0.8);
	
	-- Add title
    SKC_UIMain.Title:ClearAllPoints();
	SKC_UIMain.Title:SetPoint("LEFT", SKC_UIMainTitleBG, "LEFT", 6, 0);
	SKC_UIMain.Title:SetText("SKC");

	-- Create filter panel
	local filter_border_key = SKC_Main:CreateUIBorder("Filters",DEFAULTS.SK_FILTER_WIDTH,DEFAULTS.SK_FILTER_HEIGHT,-250,DEFAULTS.SK_TAB_TOP_OFFST)
	-- create details fields
	local faction_class;
	if UnitFactionGroup("player") == "Horde" then faction_class="Shaman" else faction_class="Paladin" end
	local filter_roles = {"DPS","Healer","Tank","Main","Alt","Inactive","Active","Druid","Hunter","Mage","Priest","Rogue","Warlock","Warrior",faction_class};
	for idx,value in ipairs(filter_roles) do
		if value ~= "SKIP" then
			local row = math.floor((idx - 1) / 3); -- zero based
			local col = (idx - 1) % 3; -- zero based
			SKC_UIMain[filter_border_key][value] = CreateFrame("CheckButton", nil, SKC_UIMain[filter_border_key], "UICheckButtonTemplate");
			SKC_UIMain[filter_border_key][value]:SetSize(25,25);
			SKC_UIMain[filter_border_key][value]:SetChecked(SKC_Main.FilterStates["SK1"][value]);
			SKC_UIMain[filter_border_key][value]:SetScript("OnClick",OnCheck_FilterFunction)
			SKC_UIMain[filter_border_key][value]:SetPoint("TOPLEFT", SKC_UIMain[filter_border_key], "TOPLEFT", 22 + 73*col , -20 + -24*row);
			SKC_UIMain[filter_border_key][value].text:SetFontObject("GameFontNormalSmall");
			SKC_UIMain[filter_border_key][value].text:SetText(value);
			if idx > 7 then
				-- assign class colors
				SKC_UIMain[filter_border_key][value].text:SetTextColor(DEFAULTS.CLASS_COLORS[value].r,DEFAULTS.CLASS_COLORS[value].g,DEFAULTS.CLASS_COLORS[value].b,1.0);
			end
		end
	end

	-- Create SK list panel
	local sk_list = "SK1";
	SKC_UIMain[sk_list] = CreateFrame("Frame",sk_list,SKC_UIMain,"InsetFrameTemplate");
	SKC_UIMain[sk_list]:SetSize(DEFAULTS.SK_LIST_WIDTH,DEFAULTS.SK_LIST_HEIGHT);
	SKC_UIMain[sk_list]:SetPoint("TOP",SKC_UIMain,"TOP",0,DEFAULTS.SK_TAB_TOP_OFFST - DEFAULTS.SK_LIST_BORDER_OFFST);
	local sk_list_border_key = SKC_Main:CreateUIBorder(sk_list,DEFAULTS.SK_LIST_WIDTH + 2*DEFAULTS.SK_LIST_BORDER_OFFST,DEFAULTS.SK_LIST_HEIGHT + 2*DEFAULTS.SK_LIST_BORDER_OFFST,0,DEFAULTS.SK_TAB_TOP_OFFST)

	-- Create scroll frame on SK list
    SKC_UIMain[sk_list].SK_List_SF = CreateFrame("ScrollFrame","SK_List_SF",SKC_UIMain[sk_list],"UIPanelScrollFrameTemplate2");
    SKC_UIMain[sk_list].SK_List_SF:SetPoint("TOPLEFT",SKC_UIMain[sk_list],"TOPLEFT",0,-2);
	SKC_UIMain[sk_list].SK_List_SF:SetPoint("BOTTOMRIGHT",SKC_UIMain[sk_list],"BOTTOMRIGHT",0,2);
	SKC_UIMain[sk_list].SK_List_SF:SetClipsChildren(true);
	SKC_UIMain[sk_list].SK_List_SF:SetScript("OnMouseWheel",OnMouseWheel_ScrollFrame);
	SKC_UIMain[sk_list].SK_List_SF.ScrollBar:SetPoint("TOPLEFT",SKC_UIMain[sk_list].SK_List_SF,"TOPRIGHT",-22,-21);

	-- Create scroll child
	local scroll_child = CreateFrame("Frame",nil,SKC_UIMain[sk_list].SK_List_SF);
	scroll_child:SetSize(DEFAULTS.SK_LIST_WIDTH,GetScrollMax());
	SKC_UIMain[sk_list].SK_List_SF:SetScrollChild(scroll_child);

	-- Create SK cards
	SKC_UIMain[sk_list].NumberFrame = {};
	SKC_UIMain[sk_list].NameFrame = {};
	for idx = 1, SKC_DB.Count60 do
		-- Create order frames
		SKC_UIMain[sk_list].NumberFrame[idx] = CreateFrame("Frame",nil,SKC_UIMain[sk_list].SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain[sk_list].NumberFrame[idx]:SetSize(30,DEFAULTS.SK_CARD_HEIGHT);
		SKC_UIMain[sk_list].NumberFrame[idx]:SetPoint("TOPLEFT",SKC_UIMain[sk_list].SK_List_SF:GetScrollChild(),"TOPLEFT",8,-1*((idx-1)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING) + DEFAULTS.SK_CARD_SPACING));
		SKC_UIMain[sk_list].NumberFrame[idx].Text = SKC_UIMain[sk_list].NumberFrame[idx]:CreateFontString(nil,"ARTWORK")
		SKC_UIMain[sk_list].NumberFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain[sk_list].NumberFrame[idx].Text:SetPoint("CENTER",0,0)

		-- Create named card frames
		SKC_UIMain[sk_list].NameFrame[idx] = CreateFrame("Frame",nil,SKC_UIMain[sk_list].SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain[sk_list].NameFrame[idx]:SetSize(DEFAULTS.SK_CARD_WIDTH,DEFAULTS.SK_CARD_HEIGHT);
		SKC_UIMain[sk_list].NameFrame[idx]:SetPoint("TOPLEFT",SKC_UIMain[sk_list].SK_List_SF:GetScrollChild(),"TOPLEFT",43,-1*((idx-1)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING) + DEFAULTS.SK_CARD_SPACING));
		SKC_UIMain[sk_list].NameFrame[idx].Text = SKC_UIMain[sk_list].NameFrame[idx]:CreateFontString(nil,"ARTWORK")
		SKC_UIMain[sk_list].NameFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain[sk_list].NameFrame[idx].Text:SetPoint("CENTER",0,0)
		-- Add texture for color
		SKC_UIMain[sk_list].NameFrame[idx].bg = SKC_UIMain[sk_list].NameFrame[idx]:CreateTexture(nil,"BACKGROUND");
		SKC_UIMain[sk_list].NameFrame[idx].bg:SetAllPoints(true);
		-- Bind function for click event
		SKC_UIMain[sk_list].NameFrame[idx]:SetScript("OnMouseDown",OnClick_SK_Card);
	end

	-- Update SK cards
	SKC_Main:UpdateSK("SK1")

	-- Create details panel
	local details_border_key = SKC_Main:CreateUIBorder("Details",DEFAULTS.SK_DETAILS_WIDTH,DEFAULTS.SK_DETAILS_HEIGHT,250,DEFAULTS.SK_TAB_TOP_OFFST);
	-- create details fields
	local details_fields = {"Name","Class","Spec","Raid Role","Guild Role","Status","Activity","Loot History"};
	for idx,value in ipairs(details_fields) do
		-- fields
		SKC_UIMain[details_border_key][value] = CreateFrame("Frame",SKC_UIMain[details_border_key])
		SKC_UIMain[details_border_key][value].Field = SKC_UIMain[details_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_border_key][value].Field:SetFontObject("GameFontNormal");
		SKC_UIMain[details_border_key][value].Field:SetPoint("RIGHT",SKC_UIMain[details_border_key],"TOPLEFT",100,-20*idx-10);
		SKC_UIMain[details_border_key][value].Field:SetText(value..":");
		-- data
		SKC_UIMain[details_border_key][value].Data = SKC_UIMain[details_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_border_key][value].Data:SetFontObject("GameFontHighlight");
		SKC_UIMain[details_border_key][value].Data:SetPoint("CENTER",SKC_UIMain[details_border_key][value].Field,"RIGHT",45,0);
		if idx == 3 or 
		   idx == 5 or
		   idx == 6 or
		   idx == 7 then
			-- edit buttons
			SKC_UIMain[details_border_key][value].Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
			SKC_UIMain[details_border_key][value].Btn:SetID(idx);
			SKC_UIMain[details_border_key][value].Btn:SetPoint("LEFT",SKC_UIMain[details_border_key][value].Field,"RIGHT",95,0);
			SKC_UIMain[details_border_key][value].Btn:SetSize(40, 20);
			SKC_UIMain[details_border_key][value].Btn:SetText("Edit");
			SKC_UIMain[details_border_key][value].Btn:SetNormalFontObject("GameFontNormalSmall");
			SKC_UIMain[details_border_key][value].Btn:SetHighlightFontObject("GameFontHighlightSmall");
			SKC_UIMain[details_border_key][value].Btn:SetScript("OnMouseDown",OnClick_EditDetails);
			SKC_UIMain[details_border_key][value].Btn:Disable();
			-- associated drop down menu
			SKC_UIMain[details_border_key][value].DD = CreateFrame("Frame",nil, SKC_UIMain, "UIDropDownMenuTemplate");
			UIDropDownMenu_SetAnchor(SKC_UIMain[details_border_key][value].DD, 0, 0, "TOPLEFT", SKC_UIMain[details_border_key][value].Btn, "TOPRIGHT");
		end
	end
	-- Initialize with instructions
	SKC_UIMain[details_border_key]["Name"].Data:SetText("            Click on a character."); -- lol, so elegant

	-- Add SK buttons
	-- full SK
	SKC_UIMain[details_border_key].FullSK_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].FullSK_Btn:SetPoint("BOTTOM",SKC_UIMain[details_border_key],"BOTTOM",0,15);
	SKC_UIMain[details_border_key].FullSK_Btn:SetSize(75, 40);
	SKC_UIMain[details_border_key].FullSK_Btn:SetText("Full SK");
	SKC_UIMain[details_border_key].FullSK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].FullSK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].FullSK_Btn:SetScript("OnMouseDown",OnClick_FullSK);
	SKC_UIMain[details_border_key].FullSK_Btn:Disable();
	-- single SK
	SKC_UIMain[details_border_key].SingleSK_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetPoint("RIGHT",SKC_UIMain[details_border_key].FullSK_Btn,"LEFT",-5,0);
	SKC_UIMain[details_border_key].SingleSK_Btn:SetSize(75, 40);
	SKC_UIMain[details_border_key].SingleSK_Btn:SetText("Single SK");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetScript("OnMouseDown",OnClick_SingleSK);
	SKC_UIMain[details_border_key].SingleSK_Btn:Disable();
	-- set SK
	SKC_UIMain[details_border_key].SetSK_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].SetSK_Btn:SetPoint("LEFT",SKC_UIMain[details_border_key].FullSK_Btn,"RIGHT",5,0);
	SKC_UIMain[details_border_key].SetSK_Btn:SetSize(75, 40);
	SKC_UIMain[details_border_key].SetSK_Btn:SetText("Set SK");
	SKC_UIMain[details_border_key].SetSK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].SetSK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].SetSK_Btn:SetScript("OnMouseDown",OnClick_SetSK);
	SKC_UIMain[details_border_key].SetSK_Btn:Disable();


	-- Decision region
	local decision_border_key = SKC_Main:CreateUIBorder("Decision",DEFAULTS.DECISION_WIDTH,DEFAULTS.DECISION_HEIGHT,-250,DEFAULTS.SK_TAB_TOP_OFFST-DEFAULTS.SK_FILTER_HEIGHT-20);

	-- set texture / hidden frame for button click
	SKC_UIMain[decision_border_key].ItemTexture = SKC_UIMain[decision_border_key]:CreateTexture(nil, "ARTWORK");
	SKC_UIMain[decision_border_key].ItemTexture:SetSize(DEFAULTS.ITEM_WIDTH,DEFAULTS.ITEM_HEIGHT);
	SKC_UIMain[decision_border_key].ItemTexture:SetPoint("TOP",SKC_UIMain[decision_border_key],"TOP",0,-45)
	SKC_UIMain[decision_border_key].ItemClickBox = CreateFrame("Frame", nil, SKC_UIMain);
	SKC_UIMain[decision_border_key].ItemClickBox:SetSize(DEFAULTS.ITEM_WIDTH,DEFAULTS.ITEM_HEIGHT);
	SKC_UIMain[decision_border_key].ItemClickBox:SetPoint("CENTER",SKC_UIMain[decision_border_key].ItemTexture,"CENTER");
	SKC_UIMain[decision_border_key].ItemClickBox:SetScript("OnMouseDown",OnMouseDown_ShowItemTooltip);
	-- set name / link
	SKC_UIMain[decision_border_key].ItemLink = SKC_UIMain[decision_border_key]:CreateFontString(nil,"ARTWORK");
	SKC_UIMain[decision_border_key].ItemLink:SetFontObject("GameFontNormal");
	SKC_UIMain[decision_border_key].ItemLink:SetPoint("TOP",SKC_UIMain[decision_border_key],"TOP",0,-25);
	SKC_UIMain[decision_border_key]:SetHyperlinksEnabled(true)
	SKC_UIMain[decision_border_key]:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
	-- set decision buttons
	-- SK 
	SKC_UIMain[decision_border_key].SK_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[decision_border_key].SK_Btn:SetPoint("TOPRIGHT",SKC_UIMain[decision_border_key].ItemTexture,"BOTTOM",-40,-5);
	SKC_UIMain[decision_border_key].SK_Btn:SetSize(65,35);
	SKC_UIMain[decision_border_key].SK_Btn:SetText("SK");
	SKC_UIMain[decision_border_key].SK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[decision_border_key].SK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[decision_border_key].SK_Btn:SetScript("OnMouseDown",OnClick_SK);
	SKC_UIMain[decision_border_key].SK_Btn:Disable();
	-- Roll 
	SKC_UIMain[decision_border_key].Roll_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[decision_border_key].Roll_Btn:SetPoint("TOP",SKC_UIMain[decision_border_key].ItemTexture,"BOTTOM",0,-5);
	SKC_UIMain[decision_border_key].Roll_Btn:SetSize(65,35);
	SKC_UIMain[decision_border_key].Roll_Btn:SetText("Roll");
	SKC_UIMain[decision_border_key].Roll_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[decision_border_key].Roll_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[decision_border_key].Roll_Btn:SetScript("OnMouseDown",OnClick_ROLL);
	SKC_UIMain[decision_border_key].Roll_Btn:Disable();
	-- Pass
	SKC_UIMain[decision_border_key].Pass_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[decision_border_key].Pass_Btn:SetPoint("TOPLEFT",SKC_UIMain[decision_border_key].ItemTexture,"BOTTOM",40,-5);
	SKC_UIMain[decision_border_key].Pass_Btn:SetSize(65,35);
	SKC_UIMain[decision_border_key].Pass_Btn:SetText("Pass");
	SKC_UIMain[decision_border_key].Pass_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[decision_border_key].Pass_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[decision_border_key].Pass_Btn:SetScript("OnMouseDown",OnClick_PASS);
	SKC_UIMain[decision_border_key].Pass_Btn:Disable();
	-- timer bar
	SKC_UIMain[decision_border_key].TimerBorder = CreateFrame("Frame",nil,SKC_UIMain,"TranslucentFrameTemplate");
	SKC_UIMain[decision_border_key].TimerBorder:SetSize(210,40);
	SKC_UIMain[decision_border_key].TimerBorder:SetPoint("TOP",SKC_UIMain[decision_border_key].Roll_Btn,"BOTTOM",0,-3);
	SKC_UIMain[decision_border_key].TimerBorder.Bg:SetAlpha(1.0);
	-- status bar
	SKC_UIMain[decision_border_key].TimerBar = CreateFrame("StatusBar",nil,SKC_UIMain);
	SKC_UIMain[decision_border_key].TimerBar:SetSize(186,16);
	SKC_UIMain[decision_border_key].TimerBar:SetPoint("CENTER",SKC_UIMain[decision_border_key].TimerBorder,"CENTER",0,-1);
	-- background texture
	SKC_UIMain[decision_border_key].TimerBar.bg = SKC_UIMain[decision_border_key].TimerBar:CreateTexture(nil,"BACKGROUND",nil,-7);
	SKC_UIMain[decision_border_key].TimerBar.bg:SetAllPoints(SKC_UIMain[decision_border_key].TimerBar);
	SKC_UIMain[decision_border_key].TimerBar.bg:SetColorTexture(unpack(DEFAULTS.STATUS_BAR_COLOR));
	SKC_UIMain[decision_border_key].TimerBar.bg:SetAlpha(0.8);
	-- bar texture
	SKC_UIMain[decision_border_key].TimerBar.Bar = SKC_UIMain[decision_border_key].TimerBar:CreateTexture(nil,"BACKGROUND",nil,-6);
	SKC_UIMain[decision_border_key].TimerBar.Bar:SetColorTexture(0,0,0);
	SKC_UIMain[decision_border_key].TimerBar.Bar:SetAlpha(1.0);
	-- set status texture
	SKC_UIMain[decision_border_key].TimerBar:SetStatusBarTexture(SKC_UIMain[decision_border_key].TimerBar.Bar);
	-- add text
	SKC_UIMain[decision_border_key].TimerText = SKC_UIMain[decision_border_key]:CreateFontString(nil,"ARTWORK")
	SKC_UIMain[decision_border_key].TimerText:SetFontObject("GameFontHighlightSmall")
	SKC_UIMain[decision_border_key].TimerText:SetPoint("CENTER",SKC_UIMain[decision_border_key].TimerBar,"CENTER")
	SKC_UIMain[decision_border_key].TimerText:SetText(DEFAULTS.LOOT_DECISION_TIME_MAX)
	-- values
	SKC_UIMain[decision_border_key].TimerBar:SetMinMaxValues(0,DEFAULTS.LOOT_DECISION_TIME_MAX);
	SKC_UIMain[decision_border_key].TimerBar:SetValue(0);
	
	
	
	-- ----------------------------------
	-- -- Buttons
	-- ----------------------------------
	-- -- Save Button:
    -- SKC_UIMain.saveBtn = self:CreateButton("CENTER", child, "TOP", -70, "Save");

	-- -- Reset Button:	
	-- SKC_UIMain.resetBtn = self:CreateButton("TOP", SKC_UIMain.saveBtn, "BOTTOM", -10, "Reset");

	-- -- Load Button:	
	-- SKC_UIMain.loadBtn = self:CreateButton("TOP", SKC_UIMain.resetBtn, "BOTTOM", -10, "Load");

	-- ----------------------------------
	-- -- Sliders
	-- ----------------------------------
	-- -- Slider 1:
	-- SKC_UIMain.slider1 = CreateFrame("SLIDER", nil, SKC_UIMain.ScrollFrame, "OptionsSliderTemplate");
	-- SKC_UIMain.slider1:SetPoint("TOP", SKC_UIMain.loadBtn, "BOTTOM", 0, -20);
	-- SKC_UIMain.slider1:SetMinMaxValues(1, 100);
	-- SKC_UIMain.slider1:SetValue(50);
	-- SKC_UIMain.slider1:SetValueStep(30);
	-- SKC_UIMain.slider1:SetObeyStepOnDrag(true);

	-- -- Slider 2:
	-- SKC_UIMain.slider2 = CreateFrame("SLIDER", nil, SKC_UIMain.ScrollFrame, "OptionsSliderTemplate");
	-- SKC_UIMain.slider2:SetPoint("TOP", SKC_UIMain.slider1, "BOTTOM", 0, -20);
	-- SKC_UIMain.slider2:SetMinMaxValues(1, 100);
	-- SKC_UIMain.slider2:SetValue(40);
	-- SKC_UIMain.slider2:SetValueStep(30);
	-- SKC_UIMain.slider2:SetObeyStepOnDrag(true);

	-- ----------------------------------
	-- -- Check Buttons
	-- ----------------------------------
	-- -- Check Button 1:
	-- SKC_UIMain.checkBtn1 = CreateFrame("CheckButton", nil, SKC_UIMain.ScrollFrame, "UICheckButtonTemplate");
	-- SKC_UIMain.checkBtn1:SetPoint("TOPLEFT", SKC_UIMain.slider1, "BOTTOMLEFT", -10, -40);
	-- SKC_UIMain.checkBtn1.text:SetText("My Check Button!");

	-- -- Check Button 2:
	-- SKC_UIMain.checkBtn2 = CreateFrame("CheckButton", nil, SKC_UIMain.ScrollFrame, "UICheckButtonTemplate");
	-- SKC_UIMain.checkBtn2:SetPoint("TOPLEFT", SKC_UIMain.checkBtn1, "BOTTOMLEFT", 0, -10);
	-- SKC_UIMain.checkBtn2.text:SetText("Another Check Button!");
	-- SKC_UIMain.checkBtn2:SetChecked(true);
    
	SKC_UIMain:Hide();
	return SKC_UIMain;
end

-- Monitor events
local AddonLoaded = CreateFrame("Frame");
AddonLoaded:RegisterEvent("ADDON_LOADED");
AddonLoaded:SetScript("OnEvent", SKC_Main.AddonLoad);

local LootOpened = CreateFrame("Frame");
LootOpened:RegisterEvent("OPEN_MASTER_LOOT_LIST");
LootOpened:SetScript("OnEvent", SKC_Main.InitiateLootDecision);

local AddonMessageReceived = CreateFrame("Frame");
AddonMessageReceived:RegisterEvent("CHAT_MSG_ADDON");
AddonMessageReceived:SetScript("OnEvent", SKC_Main.AddonMessageRead);
