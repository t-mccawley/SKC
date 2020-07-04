--------------------------------------
-- NAMESPACES
--------------------------------------
local _, core = ...; -- returns name of addon and namespace (core)
core.SKC_Main = {}; -- adds SKC_Main table to addon namespace

local SKC_Main = core.SKC_Main; -- assignment by reference in lua, ugh
local SKC_UIMain; -- Table for main GUI
local SKC_UICSV = {}; -- Table for GUI associated with CSV import and export
--------------------------------------
-- DEV CONTROLS
--------------------------------------
local ML_OVRD = true; -- override master looter permissions
local GL_OVRD = true; -- override guild leader permissions
local HARD_DB_RESET = false; -- resets SKC_DB
local OVRD_CHARS = { -- characters which are pushed into GuildData
	Mctester = true,
	Skc = true,
};
local COMM_VERBOSE = true; -- prints messages relating to addon communication
local SYNC_RQST_CHAR_OVRD = "Mctester"; -- override for which character to send sync request to
--------------------------------------
-- LOCAL CONSTANTS
--------------------------------------
local UI_DIMENSIONS = { -- ui dimensions
	MAIN_WIDTH = 920,
	MAIN_HEIGHT = 455,
	MAIN_BORDER_Y_TOP = -60,
	MAIN_BORDER_PADDING = 25,
	SK_TAB_TITLE_CARD_WIDTH = 80,
	SK_TAB_TITLE_CARD_HEIGHT = 40,
	SK_FILTER_WIDTH = 330,
	SK_FILTER_HEIGHT = 130,
	DECISION_WIDTH = 330,
	DECISION_HEIGHT = 200,
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
	BTN_WIDTH = 75,
	BTN_HEIGHT = 40,
	STATUS_BAR_BRDR_WIDTH = 290,
	STATUS_BAR_BRDR_HEIGHT = 40,
	STATUS_BAR_WIDTH_OFFST = 24,
	STATUS_BAR_HEIGHT_OFFST = 24,
	CSV_WIDTH = 660,
	CSV_HEIGHT = 300,
	CSV_EB_WIDTH = 600,
	CSV_EB_HEIGHT = 200,
};

local THEME = { -- general color themes
	PRINT = {
		NORMAL = {r = 0, g = 0.8, b = 1, hex = "00ccff"},
		WARN = {r = 1, g = 0.8, b = 0, hex = "ffcc00"},
		ERROR = {r = 1, g = 0.2, b = 0, hex = "ff3300"},
		IMPORTANT = {r = 1, g = 0, b = 1, hex = "ff00ff"},
	},
	STATUS_BAR_COLOR = {0.0,0.6,0.0},
};

local OnClick_EditDropDownOption; -- forward declare for drop down menu details
local CLASSES = { -- wow classes
	Druid = {
		text = "Druid",
		color = {
			r = 1.0,
			g = 0.49,
			b = 0.04,
			hex = "FF7D0A"
		},
		Specs = {
			Balance = {
				val = 1,
				text = "Balance",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Balance") end,
			},
			Resto = {
				val = 2,
				text = "Resto",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("Spec","Resto") end
			},
			FeralTank = {
				val = 3,
				text = "FeralTank",
				RR = "Tank",
				func = function (self) OnClick_EditDropDownOption("Spec","FeralTank") end
			},
			FeralDPS = {
				val = 4,
				text = "FeralDPS",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","FeralDPS") end
			},
		},
		DEFAULT_SPEC = "Resto",
	},
	Hunter = {
		text = "",
		color = {
			r = 0.67, 
			g = 0.83,
			b = 0.45,
			hex = "ABD473"
		},
		Specs = {
			Any = {
				val = 5,
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Any") end
			},
		},
		DEFAULT_SPEC = "Any",
	},
	Mage = {
		text = "",
		color = {
			r = 0.41, 
			g = 0.80,
			b = 0.94,
			hex = "69CCF0"
		},
		Specs = {
			Any = {
				val = 6,
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Any") end
			},
		},
		DEFAULT_SPEC = "Any",
	},
	Paladin = {
		text = "",
		color = {
			r = 0.96, 
			g = 0.55,
			b = 0.73,
			hex = "F58CBA"
		},
		Specs = {
			Holy = {
				val = 7,
				text = "Holy",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("Spec","Holy") end
			},
			Prot = {
				val = 8,
				text = "Prot",
				RR = "Tank",
				func = function (self) OnClick_EditDropDownOption("Spec","Prot") end
			},
			Ret = {
				val = 9,
				text = "Ret",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Ret") end
			},
		},
		DEFAULT_SPEC = "Holy",
	},
	Priest = {
		text = "",
		color = {
			r = 1.00, 
			g = 1.00,
			b = 1.00,
			hex = "FFFFFF"
		},
		Specs = {
			Holy = {
				val = 10,
				text = "Holy",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("Spec","Holy") end
			},
			Shadow = {
				val = 11,
				text = "Shadow",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Shadow") end
			},
		},
		DEFAULT_SPEC = "Holy",
	},
	Rogue = {
		text = "",
		color = {
			r = 1.00, 
			g = 0.96,
			b = 0.41,
			hex = "FFF569"
		},
		Specs = {
			Any = {
				val = 12,
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Any") end
			},
			Daggers = {
				val = 13,
				text = "Daggers",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Daggers") end
			},
			Swords = {
				val = 14,
				text = "Swords",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Swords") end
			},
		},
		DEFAULT_SPEC = "Any",
	},
	Shaman = {
		text = "",
		color = {
			r = 0.96, 
			g = 0.55,
			b = 0.73,
			hex = "F58CBA"
		},
		Specs = {
			Ele = {
				val = 15,
				text = "Ele",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Ele") end
			},
			Enh = {
				val = 16,
				text = "Enh",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Enh") end
			},
			Resto = {
				val = 17,
				text = "Resto",
				RR = "Healer",
				func = function (self) OnClick_EditDropDownOption("Spec","Resto") end
			},
		},
		DEFAULT_SPEC = "Resto",
	},
	Warlock = {
		text = "",
		color = {
			r = 0.58, 
			g = 0.51,
			b = 0.79,
			hex = "9482C9"
		},
		Specs = {
			Any = {
				val = 18,
				text = "Any",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","Any") end
			},
		},
		DEFAULT_SPEC = "Any",
	},
	Warrior = {
		text = "",
		color = {
			r = 0.78, 
			g = 0.61,
			b = 0.43,
			hex = "C79C6E"
		},
		Specs = {
			DPS = {
				val = 19,
				text = "DPS",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","DPS") end
			},
			Prot = {
				val = 20,
				text = "Prot",
				RR = "Tank",
				func = function (self) OnClick_EditDropDownOption("Spec","Prot") end
			},
			TwoHanded = {
				val = 21,
				text = "TwoHanded",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","TwoHanded") end
			},
			DualWield = {
				val = 22,
				text = "DualWield",
				RR = "DPS",
				func = function (self) OnClick_EditDropDownOption("Spec","DualWield") end
			},
		},
		DEFAULT_SPEC = "DPS",
	},
};

local SPEC_CLASS = { -- used to quickly get spec name from value
	"DruidBalance",
	"DruidResto",
	"DruidFeralTank",
	"DruidFeralDPS",
	"HunterAny",
	"MageAny",
	"PaladinHoly",
	"PaladinProt",
	"PaladinRet",
	"PriestHoly",
	"PriestShadow",
	"RogueAny",
	"RogueDaggers",
	"RogueSwords",
	"ShamanEle",
	"ShamanEnh",
	"ShamanResto",
	"WarlockAny",
	"WarriorDPS",
	"WarriorProt",
	"WarriorTwoHanded",
	"WarriorDualWield",
}

local CHARACTER_DATA = { -- fields used to define character
	Name = {
		text = "Name",
		OPTIONS = {},
	},
	Class = {
		text = "Class",
		OPTIONS = {},
	},
	Spec = {
		text = "Spec",
		OPTIONS = {},
	},
	["Raid Role"] = {
		text = "Raid Role",
		OPTIONS = {
			DPS = {
				text = "DPS",
			},
			Healer = {
				text = "Healer",
			},
			Tank = {
				text = "Tank",
			},
		},
	},
	["Guild Role"] = {
		text = "Guild Role",
		OPTIONS = {
			None = {
				text = "None",
				func = function (self) OnClick_EditDropDownOption("Guild Role","None") end,
			},
			Disenchanter = {
				text = "Disenchanter",
				func = function (self) OnClick_EditDropDownOption("Guild Role","Disenchanter") end,
			},
			Banker = {
				text = "Banker",
				func = function (self) OnClick_EditDropDownOption("Guild Role","Banker") end,
			},
		},
	},
	Status = {
		text = "Status",
		OPTIONS = {
			Main = {
				text = "Main",
				func = function (self) OnClick_EditDropDownOption("Status","Main") end,
			},
			Alt = {
				text = "Alt",
				func = function (self) OnClick_EditDropDownOption("Status","Alt") end,
			},
		},
	},
	Activity = {
		text = "Activity",
		OPTIONS = {
			Active = {
				text = "Active",
				func = function (self) OnClick_EditDropDownOption("Activity","Active") end,
			},
			Inactive = {
				text = "Inactive",
				func = function (self) OnClick_EditDropDownOption("Activity","Inactive") end,
			},
		},
	},	
};

local LOOT_DECISION = {
	PASS = 0,
	SK = 1,
	ROLL = 2,
	OPTIONS = {
		MAX_TIME = 30,
		TIME_STEP = 1,
		RARITY_THRESHOLD = 2, -- threshold to initiate loot decision (2 = greens, 3 = blues)
	},
};

local PRIO_TIERS = { -- possible prio tiers and associated numerical ordering
	SK = {
		Main = {
			P1 = 1,
			P2 = 2,
			P3 = 3,
			P4 = 4,
			P5 = 5,
			OS = 6,
		},
		Alt = {
			P1 = 7,
			P2 = 8,
			P3 = 9,
			P4 = 10,
			P5 = 11,
			OS = 12,
		},
	},
	ROLL = {
		Main = {
			MS = 13,
			OS = 14,
		},
		Alt = {
			MS = 15,
			OS = 16,
		},
	},
	PASS = 17,
};

local LOG_OPTIONS = {
	["Timestamp"] = {
		Text = "Timestamp",
	},
	["Action"] = {
		Text = "Action",
		Options = {
			ALD = "Automatic Loot Distribution",
			ManSK = "Manual SK List Edit",
		},
	},
	["Source"] = {
		Text = "Source",
		Options = {
			SKC = "SKC",
			THIS_PLAYER = UnitName("player"),
		},
	},
	["SK List"] = {
		Text = "SK List",
		Options = {
			MSK = "MSK",
			TSK = "TSK",
		}
	},
	["Character"] = {
		Text = "Character",
	},
	["Item"] = {
		Text = "Item",
	},
	["Previous SK Position"] = {
		Text = "Previous SK Position",
	},
	["New SK Position"] = {
		Text = "New SK Position",
	},
};

--------------------------------------
-- REGISTER CHANNELS
--------------------------------------
CHANNELS = { -- channels for inter addon communication (const)
	LOGIN_SYNC_CHECK = "?Q!@$8aZpc8QqYyH",
	LOGIN_SYNC_PUSH = "6-F?8&2qBmrJE?pR",
	LOGIN_SYNC_PUSH_RQST = "d$8B=qB4VsW&4Y^D",
	SYNC_PUSH = "8EtTWxyA$r6x53=F",
	LOOT = "xBPE9,-Fjbc+A#rm",
	LOOT_DECISION = "ksg(AkE.*/@&+`8Q",
	LOOT_OUTCOME = "aP@yX9hQfU89K&C4",
};
for _,channel in pairs(CHANNELS) do
	C_ChatInfo.RegisterAddonMessagePrefix(channel);
end
--------------------------------------
-- LOCAL VARIABLES
--------------------------------------
local LootDecision = nil; -- personal loot decision
local MasterLooter = nil; -- name of master looter
local SK_Item = nil; -- name of item currently being SK'd for
local UnFilteredCnt = 0; -- defines max count of sk cards to scroll over
local SK_MessagesSent = 0;
local SK_MessagesReceived = 0;
local FilterStates = {
	MSK = {
		DPS = true,
		Healer = true,
		Tank = true,
		Live = false,
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
local event_states = { -- tracks if certain events have fired
	AddonLoaded = false,
	GuildRosterUpdated = false,
	RaidLoggingActive = false, -- latches true when raid is entered (controls RaidLog)
	SyncRequestSent = false,
	LoginSyncName = {
		MSK = nil,
		GuildData = nil,
		LootPrio = nil,
	}
};
local LootTimer = nil; -- current loot timer
local DD_State = 0; -- used to track state of drop down menu
local SetSK_Flag = false; -- true when SK position is being set
local SKC_Active = false; -- true when loot distribution is handled by SKC
local Loot_Decision_Pending = false; -- true when loot distribution is active (do not edit live lists)
local InitSetup = false; -- used to control for first time setup
--------------------------------------
-- CLASS DEFINITIONS / CONSTRUCTORS
--------------------------------------
Prio = {
	sk_list = nil, -- associated sk_list
	reserved = false, -- true if main prio over alts
	DE = false, -- true if item should be disenchanted before going to guild banker
	open_roll = false, -- open roll for this tiem
	prio = {}, -- map of SpecClass to prio level (P1,P2,P3,P4,P5)
};
Prio.__index = Prio;

function Prio:new(prio)
	if prio == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,Prio);
		obj.prio = {}; -- default is equal prio for all (considered OS for all)
		obj.reserved = false;
		obj.DE = false;
		obj.open_roll = false;
		obj.sk_list = "MSK";
		return obj;
	else
		-- set metatable of existing table
		setmetatable(prio,Prio);
		return prio;
	end
end

LootPrio = {
	items = {},-- hash table mapping itemName to Prio object
	edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
	edit_ts_generic = nil, -- timestamp of most recent edit (non-raid)
}; 
LootPrio.__index = LootPrio;

function LootPrio:new(loot_prio)
	if loot_prio == nil then
		-- initalize fresh
		local obj = {};
		obj.items = {};
		-- initialize default prio
		obj.items["DEFAULT"] = Prio:new(nil);
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
		setmetatable(obj,LootPrio);
		return obj;
	else
		-- set metatable of existing table
		setmetatable(loot_prio,LootPrio);
		for key,value in pairs(loot_prio.items) do
			loot_prio[key] = Prio:new(value);
		end
		return loot_prio;
	end
end

SK_Node = {
	above = nil, -- character name above this character in ths SK list
	below = nil, -- character name below this character in the SK list
	abs_pos = nil, -- absolute position of this node in the full list
	loot_decision = LOOT_DECISION.PASS, -- character current loot decision (PASS, SK, ROLL)
	loot_prio = PRIO_TIERS.PASS, -- priority on given loot item
	live = false, -- used to indicate a node that is currently in the live list
};
SK_Node.__index = SK_Node;

function SK_Node:new(sk_node,above,below)
	if sk_node == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,SK_Node);
		obj.above = above or nil;
		obj.below = below or nil;
		obj.abs_pos = 1;
		obj.loot_decision = LOOT_DECISION.PASS;
		obj.loot_prio = PRIO_TIERS.PASS;
		obj.live = false;
		return obj;
	else
		-- set metatable of existing table
		setmetatable(sk_node,SK_Node);
		return sk_node;
	end
end

SK_List = { --a doubly linked list table where each node is referenced by player name. Each node is a SK_Node:
	top = nil, -- top name in list
	bottom = nil, -- bottom name in list
	live_bottom = nil, -- bottom name in live list
	list = {}, -- list of SK_Node
	edit_ts_raid = nil, -- timestamp of most recent edit (in a raid)
	edit_ts_generic = nil, -- timestamp of most recent edit
};
SK_List.__index = SK_List;

function SK_List:new(sk_list)
	if sk_list == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,SK_List);
		obj.top = nil; 
		obj.bottom = nil;
		obj.live_bottom = nil;
		obj.list = {};
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
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

CharacterData = {
	Name = nil, -- character name
	Class = nil, -- character class
	Spec = nil, -- character specialization
	["Raid Role"] = nil, --DPS, Healer, or Tank
	["Guild Role"] = nil, --Disenchanter, Guild Banker, or None
	Status = nil, -- Main or Alt
	Activity = nil, -- Active or Inactive
	-- ["Loot History"] = {}, -- Table that maps timestamp to table with item (Rejuvenating Gem) and distribution method (MSK, Roll, DE, etc)
}
CharacterData.__index = CharacterData;

function CharacterData:new(character_data,name,class)
	if character_data == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,CharacterData);
		obj.Name = name;
		obj.Class = class;
		obj.Spec = CLASSES[class].DEFAULT_SPEC;
		obj["Raid Role"] = CLASSES[class].Specs[obj.Spec].RR;
		obj["Guild Role"] = CHARACTER_DATA["Guild Role"].OPTIONS.None.text;
		obj.Status = CHARACTER_DATA.Status.OPTIONS.Main.text;
		obj.Activity = CHARACTER_DATA.Activity.OPTIONS.Active.text;
		-- obj["Loot History"] = {};
		return obj;
	else
		-- set metatable of existing table
		setmetatable(character_data,CharacterData);
		return character_data;
	end
end

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
		setmetatable(obj,GuildData);
		obj.data = {};
		obj.edit_ts_raid = 0;
		obj.edit_ts_generic = 0;
		return obj;
	else
		-- set metatable of existing table and all sub tables
		setmetatable(guild_data,GuildData);
		for key,value in pairs(guild_data.data) do
			guild_data.data[key] = CharacterData:new(value,nil,nil);
		end
		return guild_data;
	end
end
--------------------------------------
-- CLASS METHODS
--------------------------------------
local function GetSpecClassColor(spec_class)
	-- Returns color code for given SpecClass
	for class,tbl in pairs(CLASSES) do
		if string.find(spec_class,class) ~= nil then
			return tbl.color.r, tbl.color.g, tbl.color.b, tbl.color.hex;
		end
	end
	return nil,nil,nil,nil;
end

function LootPrio:length()
	local count = 0;
	for _ in pairs(self.items) do count = count + 1 end
	return count;
end

function LootPrio:PrintPrio(itemName)
	-- prints the prio of given item
	-- prints default if nil
	local data;
	if itemName == nil or self.items[itemName] == nil then
		data = self.items.DEFAULT;
		SKC_Main:Print("IMPORTANT","DEFAULT")
	else
		data = self.items[itemName];
		SKC_Main:Print("IMPORTANT",itemName)
	end
	-- print reserved states
	if data.reserved then
		SKC_Main:Print("IMPORTANT","Reserved: TRUE");
	else
		SKC_Main:Print("IMPORTANT","Reserved: FALSE");
	end
	-- print open roll
	if data.open_roll then
		SKC_Main:Print("IMPORTANT","Open Roll: TRUE");
	else
		SKC_Main:Print("IMPORTANT","Open Roll: FALSE");
	end
	-- create map from prio level to concatenated string of SpecClass's
	local spec_class_map = {};
	for i = 1,6 do
		spec_class_map[i] = {};
	end
	for spec_class_idx,plvl in pairs(data.prio) do
		-- SKC_Main:Print("NORMAL","Prio");
		-- SKC_Main:Print("NORMAL","Prio Tier ["..key.."]: "..value);
		spec_class_map[plvl][#(spec_class_map[plvl]) + 1] = SPEC_CLASS[spec_class_idx];
	end
	for plvl,tbl in ipairs(spec_class_map) do
		if plvl == 6 then
			SKC_Main:Print("IMPORTANT","OS Prio:");
		else
			SKC_Main:Print("IMPORTANT","MS Prio "..plvl..":");
		end
		for _,spec_class in pairs(tbl) do
			local hex = select(4, GetSpecClassColor(spec_class));
			DEFAULT_CHAT_FRAME:AddMessage("         "..string.format("|cff%s%s|r",hex:upper(),spec_class));
		end
	end
	return;
end

function SK_List:GetPos(name)
	-- gets the absolute position of this node
	return self.list[name].abs_pos;
end

function SK_List:CheckIfFucked()
	-- checks integrity of list
	if self.bottom == nil or self.list[self.bottom].below ~= nil then
		SKC_Main:Print("ERROR","Your database is fucked.")
		return true;
	end
	return false;
end

function SK_List:SetLiveBottom()
	-- scan list to find bottom live player
	if self:CheckIfFucked() then return false end
	local current_name = self.top;
	local live_bottom_tmp = nil;
	while (current_name ~= nil) do
		if self.list[current_name].live then
			live_bottom_tmp = current_name;
		end
		current_name = self.list[current_name].below;
	end
	-- assign
	self.live_bottom = live_bottom_tmp;
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
	return true;
end

function SK_List:ResetPos()
	-- resets absolute positions of all nodes
	if self:CheckIfFucked() then return false end
	-- scan list and assign positions
	local idx = 1;
	local current_name = self.top;
	while (current_name ~= nil) do
		self.list[current_name].abs_pos = idx;
		current_name = self.list[current_name].below;
		idx = idx + 1;
	end
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
	return true;
end

function SK_List:PushTop(name)
	-- Push name on top
	-- Remove name from current spot
	local above_tmp = self.list[name].above;
	local below_tmp = self.list[name].below;
	self.list[above_tmp].below = below_tmp;
	self.list[below_tmp].above = above_tmp;
	-- put on top
	self.list[self.top].above = name;
	self.list[name].below = self.top;
	self.list[name].above = name;
	-- adjust top tracker
	self.top = name;
	-- reset positions
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
	return self:ResetPos();
end

function SK_List:ResetLoot()
	-- Resets all player loot decisions / prio to PASS
	for name,sk_node in pairs(self.list) do 
		sk_node.loot_decision = LOOT_DECISION.PASS;
		sk_node.loot_prio = PRIO_TIERS.PASS;
	end
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
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

function SK_List:PrintNode(name)
	if self.list[name] == nil then
		SKC_Main:Print("ERROR",name.." not in list");
	elseif self.top == nil then
		SKC_Main:Print("IMPORTANT","EMPTY");
	elseif self.top == name then
		SKC_Main:Print("IMPORTANT","TOP-->"..name.."-->"..self.list[name].below);
	elseif self.bottom == name then
		SKC_Main:Print("IMPORTANT",self.list[name].above.."-->"..name.."-->BOTTOM");
	else
		SKC_Main:Print("IMPORTANT",self.list[name].above.."-->"..name.."-->"..self.list[name].below);
	end
	return;
end

function SK_List:PrintList()
	-- prints list in order
	-- check data integrity
	if self:CheckIfFucked() then return end;
	-- Scan list in order
	local current_name = self.top;
	while (current_name ~= nil) do
		self:PrintNode(current_name);
		current_name = self.list[current_name].below;
	end
	return;
end

function SK_List:InsertBelow(name,new_above_name,verbose)
	-- Insert item below new_above_name
	if name == nil then
		SKC_Main:Print("ERROR","nil name to SK_List:InsertBelow()");
		return false;
	end
	-- check special cases
	if self.top == nil then
		-- First node in list
		self.top = name;
		self.bottom = name;
		self.list[name] = SK_Node:new(self.list[name],name,nil);
		local ts = time();
		self.edit_ts_generic = ts;
		if SKC_Active then self.edit_ts_raid = ts end
		if verbose then self:PrintNode(name) end
		return true;
	elseif name == new_above_name then
		-- do nothing
		return true;
	end
	if new_above_name == nil then
		SKC_Main:Print("ERROR","nil new_above_name to SK_List:InsertBelow()");
		return false;
	end
	-- check that new_above_name is in list
	if self.list[new_above_name] == nil then
		SKC_Main:Print("ERROR",new_above_name.." not in list");
		return false 
	end
	-- Instantiates if does not exist
	if self.list[name] == nil then
		-- new node
		self.list[name] = SK_Node:new(self.list[name],nil,nil);
	else
		-- existing node
		if self:CheckIfFucked() then return false end
		if self.list[name].above == new_above_name then
			-- already in correct order
			if verbose then self:PrintNode(name) end
			return true;
		end
		-- remove name from list
		local above_tmp = self.list[name].above;
		local below_tmp = self.list[name].below;
		if name == self.top then
			-- name is current top
			self.list[below_tmp].above = below_tmp;
			self.top = below_tmp;
		elseif name == self.bottom then
			-- name is current bottom node
			self.list[above_tmp].below = nil;
			self.bottom = above_tmp;
		else
			-- name is middle node
			self.list[below_tmp].above = above_tmp;
			self.list[above_tmp].below = below_tmp;
		end
	end
	-- get new below
	local new_below_name = self.list[new_above_name].below;
	-- insert to new location
	self.list[name].above = new_above_name;
	self.list[name].below = new_below_name;
	-- adjust surrounding
	self.list[new_above_name].below = name;
	if new_below_name ~= nil then self.list[new_below_name].above = name end
	-- check if new bottom or top and adjust
	if self.list[name].below == nil then self.bottom = name end
	if self.list[name].above == name then self.top = name end
	-- adjust position
	self:ResetPos();
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
	if verbose then self:PrintNode(name) end
	return true;
end

function SK_List:SetByPos(name,pos)
	-- sets the absolute position of given name
	local des_pos = pos;
	if self:CheckIfFucked() then return false end
	local curr_pos = self:GetPos(name);
	if pos == curr_pos then
		return true;
	elseif pos < curr_pos then
		-- desired position is above current position
		-- account for moving self node
		des_pos = des_pos - 1;
	end
	if des_pos == 0 then
		return self:PushTop(name);
	end
	-- find where to insert below
	local current_name = self.top;
	while (current_name ~= nil) do
		if (self:GetPos(current_name) == des_pos) then
			-- desired position found, insert
			return self:InsertBelow(name,current_name);
		end
		current_name = self.list[current_name].below;
	end
	return false;
end

function SK_List:PushBack(name)
	-- Pushes name to back (bottom) of list (creates if does not exist)
	return self:InsertBelow(name,self.bottom);
end

function SK_List:SetSK(name,new_above_name)
	-- Removes player from list and sets them to specific location
	-- returns error if names not already i list
	if self.list[name] == nil or self.list[new_above_name] == nil then
		SKC_Main:Print("ERROR",name.." or "..new_above_name.." not in list");
		return false
	else
		return self:InsertBelow(name,new_above_name);
	end
end

function SK_List:SK()
	-- Scan list and SK player with highest priority to bottom of list
	-- returns name of player that was SK'd
	local sk_name = nil;
	-- check data integrity
	if self:CheckIfFucked() then return sk_name end;
	local current_name = self.top;
	while (current_name ~= nil) do
		-- check if character SK'd and higher prio than current
		if self.list[current_name].loot_decision == LOOT_DECISION.SK then
			if sk_name == nil or self.list[current_name].loot_prio < self.list[sk_name].loot_prio then
				-- first SK or higher prio found
				sk_name = current_name;
			end
		end
	end
	if sk_name ~= nil then
		-- SK
		self:PushBack(sk_name);
	end
	return sk_name;
end

function SK_List:GetBelow(name)
	-- gets the name of the character below name
	return self.list[name].below;
end

function SK_List:SetLive(name,live_status)
	self.list[name].live = live_status;
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
	return;
end

function SK_List:GetLive(name)
	return self.list[name].live;
end

function SK_List:length()
	local count = 0;
	for _ in pairs(self.list) do count = count + 1 end
	return count;
end

function GuildData:length()
	local count = 0;
	for _ in pairs(self.data) do count = count + 1 end
	return count;
end

function GuildData:Add(name,class)
	self.data[name] = CharacterData:new(nil,name,class);
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
	return;
end

function GuildData:GetData(name,field)
	-- returns all data for a given name
	return self.data[name][field];
end

function GuildData:SetData(name,field,value)
	-- returns all data for a given name
	self.data[name][field] = value;
	if field == "Spec" then
		self.data[name]["Raid Role"] = CLASSES[self.data[name].Class].Specs[self.data[name].Spec].RR
	end
	local ts = time();
	self.edit_ts_generic = ts;
	if SKC_Active then self.edit_ts_raid = ts end
	return;
end

function GuildData:Exists(name)
	-- returns true if given name is in data
	return self.data[name] ~= nil;
end
--------------------------------------
-- LOCAL FUNCTIONS
--------------------------------------
local function StrOut(inpt)
	if inpt == " " then return nil else return inpt end
end

local function NumOut(inpt)
	if inpt == " " then return nil else return tonumber(inpt) end
end

local function BoolOut(inpt)
	if inpt == " " then return nil else return ( (inpt == "1") or (inpt == "TRUE") ) end
end

local function NilToStr(inpt)
	if inpt == nil then return " " else return tostring(inpt) end
end

local function BoolToStr(inpt)
	if inpt then return "1" else return "0" end
end

local function WriteToLog(time_in,action,src,sk_list,character,item,prev_sk_pos,new_sk_pos)
	-- writes new log entry (if raid logging active)
	if not event_states.RaidLoggingActive then return end
	local idx = #SKC_DB.RaidLog + 1;
	SKC_DB.RaidLog[idx] = {};
	if time_in == nil then
		SKC_DB.RaidLog[idx][1] = time();
	else
		SKC_DB.RaidLog[idx][1] = time_in;
	end
	SKC_DB.RaidLog[idx][2] = action;
	SKC_DB.RaidLog[idx][3] = src;
	SKC_DB.RaidLog[idx][4] = sk_list;
	SKC_DB.RaidLog[idx][5] = character;
	SKC_DB.RaidLog[idx][6] = item;
	SKC_DB.RaidLog[idx][7] = prev_sk_pos;
	SKC_DB.RaidLog[idx][8] = new_sk_pos;
	return;
end

local function ResetRaidLogging()
	SKC_DB.RaidLog = {};
	-- Initialize with header
	WriteToLog(
		LOG_OPTIONS["Timestamp"].Text,
		LOG_OPTIONS["Action"].Text,
		LOG_OPTIONS["Source"].Text,
		LOG_OPTIONS["SK List"].Text,
		LOG_OPTIONS["Character"].Text,
		LOG_OPTIONS["Item"].Text,
		LOG_OPTIONS["Previous SK Position"].Text,
		LOG_OPTIONS["New SK Position"].Text
	);
	SKC_Main:Print("WARN","Initialized RaidLog");
end

local function StripRealmName(full_name)
	local name,_ = strsplit("-",full_name,2);
	return(name);
end

local function FetchGuildInfo(init)
	if init then SKC_Main:Print("WARN","Populating fresh GuildData") end
	SKC_DB.InGuild = IsInGuild();
	SKC_DB.NumGuildMembers = GetNumGuildMembers()
	-- Determine # of level 60s and add any new 60s
	local cnt = 0;
	for idx = 1, SKC_DB.NumGuildMembers do
		local full_name, _, _, level, class = GetGuildRosterInfo(idx);
		local name = StripRealmName(full_name);
		if level == 60 or OVRD_CHARS[name] then
			cnt = cnt + 1;
			if not SKC_DB.GuildData:Exists(name) then
				-- new player, add to DB and SK lists
				SKC_DB.GuildData:Add(name,class);
				SKC_DB.MSK:PushBack(name);
				SKC_DB.TSK:PushBack(name);
				if init then
					SKC_DB.GuildData.edit_ts_generic = 0;
					SKC_DB.MSK.edit_ts_generic = 0;
					SKC_DB.TSK.edit_ts_generic = 0;
				end
				-- SKC_Main:Print("NORMAL","["..cnt.."] "..name.." added to database!");
			end
		end
	end
	SKC_DB.Count60 = cnt;
	UnFilteredCnt = cnt;
	return;
end

local function OnAddonLoad(addon_name)
	if addon_name ~= "SKC" then return end
	-- Initialize DBs 
	if SKC_DB == nil or HARD_DB_RESET then
		InitSetup = true;
		SKC_DB = {};
		SKC_DB.Integrity = true; -- triggers false if something is wrong with DB and disables loot distribution w/ SKC
	end
	if SKC_DB.GuildData == nil or HARD_DB_RESET then
		SKC_DB.GuildData = nil;
		SKC_Main:Print("WARN","Initialized GuildData");
	end
	if SKC_DB.LootPrio == nil or HARD_DB_RESET then 
		SKC_DB.LootPrio = nil;
		SKC_Main:Print("WARN","Initialized LootPrio");
	end
	if SKC_DB.MSK == nil or HARD_DB_RESET then 
		SKC_DB.MSK = nil;
		SKC_Main:Print("WARN","Initialized MSK List");
	end
	if SKC_DB.TSK == nil or HARD_DB_RESET then 
		SKC_DB.TSK = nil;
		SKC_Main:Print("WARN","Initialized TSK List");
	end
	if SKC_DB.RaidLog == nil or HARD_DB_RESET then
		SKC_DB.RaidLog = {};
		SKC_Main:Print("WARN","Initialized RaidLog");
	end
	SKC_DB.Bench = {}; -- array of names on bench
	-- Initialize or refresh metatables
	SKC_DB.GuildData = GuildData:new(SKC_DB.GuildData);
	SKC_DB.LootPrio = LootPrio:new(SKC_DB.LootPrio);
	SKC_DB.MSK = SK_List:new(SKC_DB.MSK);
	SKC_DB.TSK = SK_List:new(SKC_DB.TSK);
	event_states.AddonLoaded = true;
	return;
end

local function GetScrollMax()
	return((UnFilteredCnt)*(UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING));
end

local function OnMouseWheel_ScrollFrame(self,delta)
    -- delta: 1 scroll up, -1 scroll down
	-- value at top is 0, value at bottom is size of child
	-- scroll so that one wheel is 3 SK cards
	local scroll_range = self:GetVerticalScrollRange();
	local inc = 3 * (UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING)
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (inc*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

local function UpdateSKUI(sk_list)
	-- populates the SK list

	-- Addon not yet loaded, return
	if not event_states.AddonLoaded then return end

	-- Hide all cards
	for idx = 1, SKC_DB.Count60 do
		SKC_UIMain[sk_list].NumberFrame[idx]:Hide();
		SKC_UIMain[sk_list].NameFrame[idx]:Hide();
	end

	-- Populate non filtered cards
	-- SKC_DB[sk_list]:PrintNode(SKC_DB[sk_list].bottom);
	local print_order = SKC_DB[sk_list]:ReturnList();
	local idx = 1;
	for key,name in ipairs(print_order) do
		local class_tmp = SKC_DB.GuildData:GetData(name,"Class");
		local raid_role_tmp = SKC_DB.GuildData:GetData(name,"Raid Role");
		local status_tmp = SKC_DB.GuildData:GetData(name,"Status");
		local activity_tmp = SKC_DB.GuildData:GetData(name,"Activity");
		local live_tmp = SKC_DB[sk_list]:GetLive(name);
		-- only add cards to list which are not being filtered
		if FilterStates[sk_list][class_tmp] and 
		   FilterStates[sk_list][raid_role_tmp] and
		   FilterStates[sk_list][status_tmp] and
		   FilterStates[sk_list][activity_tmp] and
		   (live_tmp or (not live_tmp and not FilterStates[sk_list].Live)) then
			-- Add number text
			SKC_UIMain[sk_list].NumberFrame[idx].Text:SetText(SKC_DB[sk_list]:GetPos(name));
			SKC_UIMain[sk_list].NumberFrame[idx]:Show();
			-- Add name text
			SKC_UIMain[sk_list].NameFrame[idx].Text:SetText(name)
			-- create class color background
			SKC_UIMain[sk_list].NameFrame[idx].bg:SetColorTexture(CLASSES[class_tmp].color.r,CLASSES[class_tmp].color.g,CLASSES[class_tmp].color.b,0.25);
			SKC_UIMain[sk_list].NameFrame[idx]:Show();
			-- increment
			idx = idx + 1;
		end
	end
	UnFilteredCnt = idx; -- 1 larger than max cards
	-- update scroll length
	SKC_UIMain[sk_list].SK_List_SF:GetScrollChild():SetSize(UI_DIMENSIONS.SK_LIST_WIDTH,GetScrollMax());
end

local function OnCheck_FilterFunction (self, button)
	FilterStates["MSK"][self.text:GetText()] = self:GetChecked();
	UpdateSKUI("MSK");
	return;
end

local function Refresh_Details(name)
	local fields = {"Name","Class","Spec","Raid Role","Guild Role","Status","Activity"};
	if name == nil then
		for _,field in pairs(fields) do
			SKC_UIMain["Details_border"][field].Data:SetText(nil);
		end
		-- Initialize with instructions
		SKC_UIMain["Details_border"]["Name"].Data:SetText("            Click on a character."); -- lol, so elegant
	else
		for _,field in pairs(fields) do
			SKC_UIMain["Details_border"][field].Data:SetText(SKC_DB.GuildData:GetData(name,field));
		end
		local class_color = CLASSES[SKC_DB.GuildData:GetData(name,"Class")].color
		SKC_UIMain["Details_border"]["Class"].Data:SetTextColor(class_color.r,class_color.g,class_color.b,1.0);
	end
	return
end

local function PopulateData(sk_list)
	-- Refresh details
	Refresh_Details(nil);
	-- Update SK cards
	UpdateSKUI(sk_list);
	return;
end

local function SyncPushSend(db_name,addon_channel,game_channel,name)
	-- send target database to name
	if COMM_VERBOSE then SKC_Main:Print("WARN","SyncPushSend for "..db_name.." through "..game_channel) end
	if name ~= nil then
		name = StripRealmName(name);
		if COMM_VERBOSE then SKC_Main:Print("WARN","name: "..name) end
	end
	local db_msg = nil;
	if db_name == "MSK" or db_name == "TSK" then
		db_msg = "INIT,"..
			db_name..","..
			NilToStr(SKC_DB[db_name].edit_ts_generic);
		C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);
		db_msg = "META,"..
			db_name..","..
			NilToStr(SKC_DB[db_name].top)..","..
			NilToStr(SKC_DB[db_name].bottom)..","..
			NilToStr(SKC_DB[db_name].live_bottom);
		C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);
		for node_name,node in pairs(SKC_DB[db_name].list) do
			db_msg = "DATA,"..
				db_name..","..
				NilToStr(node_name)..","..
				NilToStr(node.above)..","..
				NilToStr(node.below)..","..
				NilToStr(node.abs_pos)..","..
				NilToStr(node.loot_decision)..","..
				NilToStr(node.loot_prio)..","..
				BoolToStr(node.live);
			C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);
		end
	elseif db_name == "GuildData" then
		db_msg = "INIT,"..
			db_name..","..
			NilToStr(SKC_DB.GuildData.edit_ts_generic);
		C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);
		for name,c_data in pairs(SKC_DB.GuildData.data) do
			db_msg = "DATA,"..
				db_name..","..
				NilToStr(name)..","..
				NilToStr(c_data.Class)..","..
				NilToStr(c_data.Spec)..","..
				NilToStr(c_data["Raid Role"])..","..
				NilToStr(c_data["Guild Role"])..","..
				NilToStr(c_data.Status)..","..
				NilToStr(c_data.Activity);
			C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);
		end
	elseif db_name == "LootPrio" then
		db_msg = "INIT,"..
			db_name..","..
			NilToStr(SKC_DB.LootPrio.edit_ts_generic);
		C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);	
		for item,prio in pairs(SKC_DB.LootPrio.items) do
			db_msg = "META,"..
				db_name..","..
				NilToStr(item)..","..
				NilToStr(prio.sk_list)..","..
				BoolToStr(prio.reserved)..","..
				BoolToStr(prio.DE)..","..
				BoolToStr(prio.open_roll);
			C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);
			db_msg = "DATA,"..db_name..","..item..",";
			for _,plvl in ipairs(prio) do
				db_msg = db_msg..","..plvl;
			end
			C_ChatInfo.SendAddonMessage(addon_channel,db_msg,game_channel,name);
		end
	end
	C_ChatInfo.SendAddonMessage(addon_channel,"END,"..db_name..", ,",game_channel,name); --awkward spacing to make csv parsing work
	return;
end

local function OnLoad_EditDropDown_Spec(self)
	local class = SKC_UIMain["Details_border"]["Class"].Data:GetText();
	for key,value in pairs(CLASSES[class].Specs) do
		UIDropDownMenu_AddButton(value);
	end
	return;
end

local function OnLoad_EditDropDown_GuildRole(self)
	UIDropDownMenu_AddButton(CHARACTER_DATA["Guild Role"].OPTIONS.None);
	UIDropDownMenu_AddButton(CHARACTER_DATA["Guild Role"].OPTIONS.Disenchanter);
	UIDropDownMenu_AddButton(CHARACTER_DATA["Guild Role"].OPTIONS.Banker);
	return;
end

local function OnLoad_EditDropDown_Status(self)
	UIDropDownMenu_AddButton(CHARACTER_DATA.Status.OPTIONS.Alt);
	UIDropDownMenu_AddButton(CHARACTER_DATA.Status.OPTIONS.Main);
	return;
end

local function OnLoad_EditDropDown_Activity(self)
	UIDropDownMenu_AddButton(CHARACTER_DATA.Activity.OPTIONS.Active);
	UIDropDownMenu_AddButton(CHARACTER_DATA.Activity.OPTIONS.Inactive);
	return;
end

function OnClick_EditDropDownOption(field,value) -- Must be global
	-- Triggered when drop down of edit button is selected
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	local class = SKC_UIMain["Details_border"]["Class"].Data:GetText();
	-- Edit GuildData
	local prev_val = SKC_DB.GuildData:GetData(name,field);
	prev_val = SKC_DB.GuildData:SetData(name,field,value);
	-- Refresh details
	Refresh_Details(name);
	-- Reset menu toggle
	DD_State = 0;
	-- -- Refresh SK Cards
	-- local sk_list = "MSK";
	-- UpdateSKUI(sk_list);
	-- send GuildData to all players
	SyncPushSend("GuildData",CHANNELS.SYNC_PUSH,"GUILD",nil);
	return;
end

local function OnClick_EditDetails(self, button)
	-- Manages drop down menu that is generated for edit buttons
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
	if button=='LeftButton' and self.Text:GetText() ~= nill and DD_State == 0 and not SetSK_Flag then
		-- Populate data
		Refresh_Details(self.Text:GetText());
		-- Enable edit buttons
		SKC_UIMain["Details_border"]["Spec"].Btn:Enable();
		SKC_UIMain["Details_border"]["Guild Role"].Btn:Enable();
		SKC_UIMain["Details_border"]["Status"].Btn:Enable();
		SKC_UIMain["Details_border"]["Activity"].Btn:Enable();
		if SKC_Main:isGL() or SKC_Main:isML() then
			SKC_UIMain["Details_border"].SingleSK_Btn:Enable();
			SKC_UIMain["Details_border"].FullSK_Btn:Enable();
			SKC_UIMain["Details_border"].SetSK_Btn:Enable();
		end
	end
end

local function OnClick_FullSK(self)
	local sk_list = "MSK";
	-- On click event for full SK of details targeted character
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	-- Get initial position
	local prev_pos = SKC_DB[sk_list]:GetPos(name);
	-- Execute full SK
	local success = SKC_DB[sk_list]:PushBack(name);
	if success then 
		-- log
		WriteToLog(
			nil,
			LOG_OPTIONS["Action"].Options.ManSK,
			LOG_OPTIONS["Source"].Options.THIS_PLAYER,
			LOG_OPTIONS["SK List"].Options[sk_list],
			name,
			"",
			prev_pos,
			SKC_DB[sk_list]:GetPos(name)
		);
		SKC_Main:Print("IMPORTANT","Full SK on "..name);
		-- send SK data to all players
		SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
		-- Refresh SK List
		UpdateSKUI(sk_list);
	else
		SKC_Main:Print("ERROR","Full SK on "..name.." rejected");
	end
	return;
end

local function OnClick_SingleSK(self)
	-- On click event for full SK of details targeted character
	local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
	local sk_list = "MSK";
	-- Get initial position
	local prev_pos = SKC_DB[sk_list]:GetPos(name);
	-- Execute full SK
	local name_below = SKC_DB[sk_list]:GetBelow(name);
	local success = SKC_DB[sk_list]:InsertBelow(name,name_below);
	if success then 
		-- log
		WriteToLog(
			nil,
			LOG_OPTIONS["Action"].Options.ManSK,
			LOG_OPTIONS["Source"].Options.THIS_PLAYER,
			LOG_OPTIONS["SK List"].Options[sk_list],
			name,
			"",
			prev_pos,
			SKC_DB[sk_list]:GetPos(name)
		);
		SKC_Main:Print("IMPORTANT","Single SK on "..name);
		-- send SK data to all players
		SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
		-- Refresh SK List
		UpdateSKUI(sk_list);
	else
		SKC_Main:Print("ERROR","Single SK on "..name.." rejected");
	end
	return;
end

local function OnClick_SetSK(self)
	-- On click event to set SK position of details targeted character
	-- Prompt user to click desired position number in list
	if SKC_UIMain["Details_border"]["Name"].Data ~= nil then
		SetSK_Flag = true;
		local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
		SKC_Main:Print("IMPORTANT","Click desired position in SK list for "..name);
	end
	return;
end

local function OnClick_NumberCard(self,button)
	-- On click event for number card in SK list
	if SetSK_Flag and SKC_UIMain["Details_border"]["Name"].Data ~= nil then
		local name = SKC_UIMain["Details_border"]["Name"].Data:GetText();
		local new_abs_pos = tonumber(self.Text:GetText());
		local sk_list = "MSK";
		-- Get initial position
		local prev_pos = SKC_DB[sk_list]:GetPos(name);
		-- Set new position
		local success = SKC_DB[sk_list]:SetByPos(name,new_abs_pos);
		if success then
			-- log
			WriteToLog(
				nil,
				LOG_OPTIONS["Action"].Options.ManSK,
				LOG_OPTIONS["Source"].Options.THIS_PLAYER,
				LOG_OPTIONS["SK List"].Options[sk_list],
				name,
				"",
				prev_pos,
				SKC_DB[sk_list]:GetPos(name)
			);
			SKC_Main:Print("IMPORTANT","Set SK position of "..name.." to "..SKC_DB[sk_list]:GetPos(name));
			-- send SK data to all players
			SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
			-- Refresh SK List
			UpdateSKUI(sk_list);
		else
			SKC_Main:Print("ERROR","Set SK on "..name.." rejected");
		end
		SetSK_Flag = false;
	end
	return;
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

local function SetSKItem()
	-- https://wow.gamepedia.com/ItemMixin
	-- local itemID = 19395; -- Rejuv
	-- Need to wrap in callback function to wait for item data to load
	local item = Item:CreateFromItemLink(SK_Item)
	item:ContinueOnItemLoad(function()
		-- item:GetItemLink();
		local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, texture, vendorPrice = GetItemInfo(SK_Item);
		-- Set texture icon and link
		local decision_border_key = "Decision_border";
		SKC_UIMain[decision_border_key].ItemTexture:SetTexture(texture);
		SKC_UIMain[decision_border_key].ItemLink:SetText(link);
	end)
end

local function SendLootDecision()
	C_ChatInfo.SendAddonMessage(CHANNELS.LOOT_DECISION,LootDecision,"WHISPER",MasterLooter);
end

local function InitTimerBarValue()
	SKC_UIMain["Decision_border"].TimerBar:SetValue(0);
	SKC_UIMain["Decision_border"].TimerText:SetText(LOOT_DECISION.OPTIONS.MAX_TIME);
end

local function TimerBarHandler()
	local time_elapsed = SKC_UIMain["Decision_border"].TimerBar:GetValue() + LOOT_DECISION.OPTIONS.TIME_STEP;

	-- updated timer bar
	SKC_UIMain["Decision_border"].TimerBar:SetValue(time_elapsed);
	SKC_UIMain["Decision_border"].TimerText:SetText(LOOT_DECISION.OPTIONS.MAX_TIME - time_elapsed);

	if time_elapsed >= LOOT_DECISION.OPTIONS.MAX_TIME then
		-- out of time
		-- send loot response
		SKC_Main:Print("WARN","Time expired. You PASS on "..SK_Item);
		LootDecision = LOOT_DECISION.PASS;
	end

	return;
end

local function StartLootTimer()
	InitTimerBarValue();
	if LootTimer ~= nil and not LootTimer:IsCancelled() then LootTimer:Cancel() end
	-- start new timer
	LootTimer = C_Timer.NewTicker(LOOT_DECISION.OPTIONS.TIME_STEP, TimerBarHandler, LOOT_DECISION.OPTIONS.MAX_TIME/LOOT_DECISION.OPTIONS.TIME_STEP);
	return;
end

local function OnClick_PASS(self,button)
	if self:IsEnabled() then
		LootDecision = LOOT_DECISION.PASS;
		LootTimer:Cancel()
		SendLootDecision();
	end
	return;
end

local function OnClick_SK(self,button)
	if self:IsEnabled() then
		LootDecision = LOOT_DECISION.SK;
		LootTimer:Cancel()
		SendLootDecision();
	end
	return;
end

local function OnClick_ROLL(self,button)
	if self:IsEnabled() then
		LOOT_DECLootDecision = LOOT_DECISION.ROLL;
		LootTimer:Cancel()
		SendLootDecision();
	end
	return;
end

local function CreateUICSV(name,import_btn)
	SKC_UICSV[name] = CreateFrame("Frame",name,UIParent,"UIPanelDialogTemplate");
	SKC_UICSV[name]:SetSize(UI_DIMENSIONS.CSV_WIDTH,UI_DIMENSIONS.CSV_HEIGHT);
	SKC_UICSV[name]:SetPoint("CENTER");
	SKC_UICSV[name]:SetMovable(true);
	SKC_UICSV[name]:EnableMouse(true);
	SKC_UICSV[name]:RegisterForDrag("LeftButton");
	SKC_UICSV[name]:SetScript("OnDragStart", SKC_UICSV[name].StartMoving);
	SKC_UICSV[name]:SetScript("OnDragStop", SKC_UICSV[name].StopMovingOrSizing);

	-- Add title
	SKC_UICSV[name].Title:SetPoint("LEFT", name.."TitleBG", "LEFT", 6, 0);
	SKC_UICSV[name].Title:SetText(name);

	-- Add edit box
	SKC_UICSV[name].SF = CreateFrame("ScrollFrame", nil, SKC_UICSV[name], "UIPanelScrollFrameTemplate");
	SKC_UICSV[name].SF:SetSize(UI_DIMENSIONS.CSV_EB_WIDTH,UI_DIMENSIONS.CSV_EB_HEIGHT);
	SKC_UICSV[name].SF:SetPoint("TOPLEFT",SKC_UICSV[name],"TOPLEFT",20,-40)
	SKC_UICSV[name].EditBox = CreateFrame("EditBox", nil, SKC_UICSV[name].SF)
	SKC_UICSV[name].EditBox:SetMultiLine(true)
	SKC_UICSV[name].EditBox:SetFontObject(ChatFontNormal)
	SKC_UICSV[name].EditBox:SetSize(UI_DIMENSIONS.CSV_EB_WIDTH,1000)
	SKC_UICSV[name].SF:SetScrollChild(SKC_UICSV[name].EditBox)

	-- Add import button
	if import_btn then
		SKC_UICSV[name].ImportBtn = CreateFrame("Button", nil, SKC_UICSV[name], "GameMenuButtonTemplate");
		SKC_UICSV[name].ImportBtn:SetPoint("BOTTOM",SKC_UICSV[name],"BOTTOM",0,15);
		SKC_UICSV[name].ImportBtn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
		SKC_UICSV[name].ImportBtn:SetText("Import");
		SKC_UICSV[name].ImportBtn:SetNormalFontObject("GameFontNormal");
		SKC_UICSV[name].ImportBtn:SetHighlightFontObject("GameFontHighlight");
	end

	-- set framel level and hide
	SKC_UICSV[name]:SetFrameLevel(4);
	SKC_UICSV[name]:Hide();
	return SKC_UICSV[name];
end

local function StartPersonalLootDecision()
	-- Begins personal loot decision process
	SKC_Main:Print("IMPORTANT","Would you like to SK for "..SK_Item.."?");
	LootDecision = LOOT_DECISION.PASS;
	-- Show UI
	SKC_Main:ToggleUIMain(true);
	-- Enable buttons
	SKC_UIMain["Decision_border"].Pass_Btn:Enable();
	SKC_UIMain["Decision_border"].SK_Btn:Enable();
	-- Set item
	SetSKItem();
	-- Initiate timer
	StartLootTimer();
	return;
end

local function DetermineWinner()
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
		if loot_decision_tmp == LOOT_DECISION.SK then
			-- If character SK'd, they win!
			SKC_Main:Print("IMPORTANT",winner.." won "..SK_Item.." by SK!");
			-- SK character
			-- local sk_success = SKC_DB["MSK"]:FullSK(name);
			-- Give loot!
			local awarded_success = SKC_Main:AwardLoot(name);
			return(sk_success and awarded_success);

		elseif loot_decision_tmp == LOOT_DECISION.ROLL then
			-- Add character to roll list
			roll_list[idx] = name_tmp;
		end
		name_tmp = self.list[name_tmp].below;
	end
end

local function DetermineLootPrio(name)
	-- Returns loot prio for given character for given SK item
	-- Alt's have loot SpecClass tier + 100 (only works so long as max # tiers < 100)
	-- OS (spec not found in prio doc) is equal to max tier + 1
	
end

local function SyncPushRead(msg)
	-- Write data to given datbase
	local part, db_name, msg_rem = strsplit(",",msg,3);
	-- if COMM_VERBOSE then SKC_Main:Print("WARN","SyncPushRead "..db_name.." "..part) end
	if db_name == "MSK" or db_name == "TSK" then
		if part == "INIT" then
			local time_stamp = msg_rem;
			time_stamp = NumOut(time_stamp);
			SKC_DB[db_name] = SK_List:new(nil);
			SKC_DB[db_name].edit_ts_generic = time_stamp;
			if COMM_VERBOSE then SKC_Main:Print("WARN","SyncPushRead for "..db_name..", "..part..", length: "..SKC_DB[db_name]:length()) end
		elseif part == "META" then
			local top, bottom, live_bottom = strsplit(",",msg_rem,3);
			SKC_DB[db_name].top = StrOut(top);
			SKC_DB[db_name].bottom = StrOut(bottom);
			SKC_DB[db_name].live_bottom = StrOut(live_bottom);
			if COMM_VERBOSE then SKC_Main:Print("WARN","SyncPushRead for "..db_name..", "..part..", length: "..SKC_DB[db_name]:length()) end
		elseif part == "DATA" then
			local name, above, below, abs_pos, loot_decision, loot_prio, live = strsplit(",",msg_rem,7);
			name = StrOut(name);
			-- if COMM_VERBOSE then SKC_Main:Print("WARN","DATA: "..msg_rem) end
			SKC_DB[db_name].list[name] = SK_Node:new(nil,nil,nil);
			SKC_DB[db_name].list[name].above = StrOut(above);
			SKC_DB[db_name].list[name].below = StrOut(below);
			SKC_DB[db_name].list[name].abs_pos = NumOut(abs_pos);
			SKC_DB[db_name].list[name].loot_decision = NumOut(loot_decision);
			SKC_DB[db_name].list[name].loot_prio = NumOut(loot_prio);
			SKC_DB[db_name].list[name].live = BoolOut(live);
			-- if COMM_VERBOSE then SKC_Main:Print("WARN",SKC_DB[db_name].list[name].above.."-->"..name.."-->"..SKC_DB[db_name].list[name].below) end
		elseif part == "END" then
			if COMM_VERBOSE then SKC_DB[db_name]:PrintNode(SKC_DB[db_name].bottom) end
			SKC_Main:ReloadUIMain();
			if COMM_VERBOSE then SKC_Main:Print("WARN","SyncPushRead for "..db_name..", "..part..", length: "..SKC_DB[db_name]:length()) end
		end
	elseif db_name == "GuildData" then
		if part == "INIT" then
			local time_stamp = msg_rem;
			time_stamp = NumOut(time_stamp);
			SKC_DB.GuildData = GuildData:new(nil);
			SKC_DB.GuildData.edit_ts_generic = time_stamp;
		elseif part == "META" then
			-- nothing to do
		elseif part == "DATA" then
			local name, class, spec, rr, gr, status, activity = strsplit(",",msg_rem,7);
			name = StrOut(name);
			class = StrOut(class);
			SKC_DB.GuildData.data[name] = CharacterData:new(nil,name,class);
			SKC_DB.GuildData.data[name].Spec = StrOut(spec);
			SKC_DB.GuildData.data[name]["Raid Role"] = StrOut(rr);
			SKC_DB.GuildData.data[name]["Guild Role"] = StrOut(gr);
			SKC_DB.GuildData.data[name].Status = StrOut(status);
			SKC_DB.GuildData.data[name].Activity = StrOut(activity);
		elseif part == "END" then
			SKC_Main:ReloadUIMain();
			if COMM_VERBOSE then SKC_Main:Print("WARN","SyncPushSend for "..db_name.." completed") end
		end
	elseif db_name == "LootPrio" then
		if part == "INIT" then
			local time_stamp = msg_rem;
			time_stamp = NumOut(time_stamp);
			SKC_DB.LootPrio = LootPrio:new(nil);
			SKC_DB.LootPrio.edit_ts_generic = time_stamp;
		elseif part == "META" then
			local item, sk_list, res, de, open_roll = strsplit(",",msg_rem,5);
			item = StrOut(item);
			SKC_DB.LootPrio.items[item] = Prio:new(nil);
			SKC_DB.LootPrio.items[item].sk_list = StrOut(sk_list);
			SKC_DB.LootPrio.items[item].reserved = BoolOut(res);
			SKC_DB.LootPrio.items[item].DE = BoolOut(de);
			SKC_DB.LootPrio.items[item].open_roll = BoolOut(open_roll);
		elseif part == "DATA" then
			local item, msg_rem = strsplit(",",msg_rem,2);
			item = StrOut(item);
			local plvl = nil;
			for idx,spec_class in ipairs(SPEC_CLASS) do
				plvl, msg_rem = strsplit(",",msg_rem,2);
				SKC_DB.LootPrio.items[item].prio[idx] = NumOut(plvl);
			end
		elseif part == "END" then
			if COMM_VERBOSE then SKC_Main:Print("WARN","SyncPushSend for "..db_name.." completed") end
		end
	end
	return;
end

local function LoginSyncCheckRead(db_name,their_edit_ts_raid,their_edit_ts_generic,name,addon_channel)
	-- Arbitrate based on timestamp to push or pull database
	local my_edit_ts_raid = SKC_DB[db_name].edit_ts_raid;
	local my_edit_ts_generic = SKC_DB[db_name].edit_ts_generic;
	if COMM_VERBOSE then 
		SKC_Main:Print("WARN","LoginSyncCheckRead for: "..db_name..", from: "..name);
		SKC_Main:Print("WARN","my raid ts:"..my_edit_ts_raid..", their raid ts:"..their_edit_ts_raid);
		SKC_Main:Print("WARN","my generic ts:"..my_edit_ts_generic..", their generic ts:"..their_edit_ts_generic);
	end
	if (my_edit_ts_raid > their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic > their_edit_ts_generic) ) then
		-- I have newer RAID data
		-- OR I have the same RAID data but newer generic data
		-- --> send them my data
		SyncPushSend(db_name,addon_channel,"WHISPER",name);
	elseif (my_edit_ts_raid < their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic < their_edit_ts_generic) ) then
		-- I have older RAID data
		-- OR I have the same RAID data but older generic data
		-- --> request their data
		if COMM_VERBOSE then SKC_Main:Print("WARN","LoginSyncPushRqst for "..db_name.." from "..name) end
		C_ChatInfo.SendAddonMessage(CHANNELS.LOGIN_SYNC_PUSH_RQST,db_name,"WHISPER",name);
	end
	return;
end

local function AddonMessageRead(prefix,msg,channel,sender)
	sender = StripRealmName(sender);
	if prefix == CHANNELS.LOGIN_SYNC_CHECK then
		--[[ 
			Send (LoginSyncCheckSend): Upon login character requests sync for each database
			Read (LoginSyncCheckRead): Arbitrate based on timestamp to push or pull database
		--]]
		if sender ~= UnitName("player") then
			if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","Channel: LOGIN_SYNC_CHECK, sender: "..sender) end
			local db_name, edit_ts_raid, edit_ts_generic = strsplit(",",msg,3);
			edit_ts_raid = NumOut(edit_ts_raid);
			edit_ts_generic = NumOut(edit_ts_generic);
			LoginSyncCheckRead(db_name,edit_ts_raid,edit_ts_generic,sender,CHANNELS.LOGIN_SYNC_PUSH);
		end
	elseif prefix == CHANNELS.LOGIN_SYNC_PUSH then
		--[[ 
			Send (SyncPushSend): Push given database to target player
			Read (SyncPushRead): Write given database to player (only accept first push)
		--]]
		local part, db_name, msg_rem = strsplit(",",msg,3);
		if (event_states.LoginSyncName[db_name] == nil or event_states.LoginSyncName[db_name] == sender) and sender ~= UnitName("player") then
			-- if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","Channel: LOGIN_SYNC_PUSH, sender: "..sender) end
			SyncPushRead(msg);
			event_states.LoginSyncName[db_name] = sender;
		end
	elseif prefix == CHANNELS.LOGIN_SYNC_PUSH_RQST then
		--[[ 
			Send (LoginSyncCheckRead): Request a push for given database from target player
			Read (SyncPushSend): Respond with push for given database
		--]]
		if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","Channel: LOGIN_SYNC_PUSH_RQST, sender: "..sender) end
		SyncPushSend(msg,CHANNELS.SYNC_PUSH,"WHISPER",sender);
	elseif prefix == CHANNELS.SYNC_PUSH then
		--[[ 
			Send (SyncPushSend): Push given database to target player
			Read (SyncPushRead): Write given datbase to player (accepts as many as possible)
		--]]
		-- Reject if message was from self
		if sender ~= UnitName("player") then
			-- if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","Channel: SYNC_PUSH, sender: "..sender) end
			SyncPushRead(msg);
		end
	elseif prefix == CHANNELS.LOOT then
		--[[ 
			Send: Send loot items for which each player is elligible to make a decision on
			Read: Initiate loot decision GUI for player
		--]]
		if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","Channel: LOOT, sender: "..sender) end
		-- save master looter
		MasterLooter = StripRealmName(sender);
		-- save item
		SK_Item = msg;
		-- initiate personal loot decision
		if COMM_VERBOSE then SKC_Main:Print("WARN",MasterLooter.." initiated decision for "..SK_Item) end
		SKC_Main:StartPersonalLootDecision();
	elseif prefix == CHANNELS.LOOT_DECISION then
		--[[ 
			Send: Send loot decision to 
			Read: Determine loot winner
		--]]
		if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","Channel: LOOT_DECISION, sender: "..sender) end
		-- Increment message counter
		SK_MessagesReceived = SK_MessagesReceived + 1;
		-- Alert ML of decision
		local name = StripRealmName(sender);
		if COMM_VERBOSE then SKC_Main:Print("WARN",name.." wants to "..msg..".") end
		-- Save loot decision
		-- SKC_DB["MSK"].list[name].loot_decision = msg;
		-- Determine loot prio of character
		-- SKC_DB["MSK"].list[name].loot_prio = SKC_Main:DetermineLootPrio(name);
		-- check if all messages received
		if SK_MessagesReceived >= SK_MessagesSent then
			-- Determine winner and allocate loot
			local success = DetermineWinner();
		end
	elseif prefix == CHANNELS.LOOT_OUTCOME then
		--[[ 
			Send: Loot outcome (including roll values) for all players
			Read: Print loot outcome
		--]]
		if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","Channel: LOOT_OUTCOME, sender: "..sender) end
	end
	return;
end

local function AwardLoot(name)
	-- Awards SK_Item to given character
	for i_loot = 1, GetNumLootItems() do
		if GetLootSlotLink(i_loot) == SK_Item then
			for i_char = 1,40 do
				if StripRealmName(GetMasterLootCandidate(i_loot,i_char)) == name then
					GiveMasterLoot(i_loot, i_char);
					SKC_Main:Print("IMPORTANT","Awarded "..SK_Item.." to "..name..".");
					return true;
				end
			end
		end
	end
	SKC_Main:Print("ERROR","Could not award "..SK_Item.." to "..name..".");
	return false;
end

local function LoginSyncCheckSend()
	if event_states.SyncRequestSent then return end -- sync check already performed
	if COMM_VERBOSE then SKC_Main:Print("WARN","LoginSyncCheckSend()") end
	-- Send timestamps of each database to each online member of GuildData (will sync with first response)
	local db_lsit = {"GuildData","LootPrio","MSK","TSK"}
	local msg = nil;
	for _,db_name in ipairs(db_lsit) do
		msg = db_name..","..NilToStr(SKC_DB[db_name].edit_ts_raid)..","..NilToStr(SKC_DB[db_name].edit_ts_generic);
		-- local success = C_ChatInfo.SendAddonMessage(CHANNELS.LOGIN_SYNC_CHECK,msg,"GUILD");
		local success = ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOGIN_SYNC_CHECK,msg,"GUILD");
		if COMM_VERBOSE and success then SKC_Main:Print("WARN",msg) end
	end
	return;
end

local function ActivateSKC()
	-- master control for wheter or not loot is managed with SKC
	local loot_method, _, _ = GetLootMethod();
	local active_prev = SKC_Active;
	if loot_method == "master" and UnitInRaid("player") ~= nil then
		-- current player is in raid with master loot method
		SKC_Active = true;
	else
		SKC_Active = false;
	end
	-- add message
	if SKC_Active and not active_prev then
		SKC_Main:Print("IMPORTANT","Enabled");
		if IsMasterLooter() then 
			SKC_Main:Print("NORMAL","Don't forget to add benched characters");
		end
	elseif not SKC_Active and active_prev then
		SKC_Main:Print("IMPORTANT","Disabled");
	end
end

local function SyncRaidAndLiveList()
	-- Start SKC
	ActivateSKC();

	-- Check if ML
	if not SKC_Main:isML() then return end

	-- Check SKC ACtive
	if not SKC_Active then return end

	-- Check if loot decision is pending
	if Loot_Decision_Pending then return end

	-- Scan all SK lists and assign live status
	local sk_lists = {"MSK","TSK"};
	for _,sk_list in pairs(sk_lists) do
		for name,_ in pairs(SKC_DB[sk_list].list) do
			SKC_DB[sk_list]:SetLive(name,UnitInRaid(name) ~= nil);
		end
	end

	-- Scan bench and adjust live
	for idx,name in ipairs(SKC_DB.Bench) do
		SKC_DB[sk_list]:SetLive(name,true);
	end

	-- Set live_bottom for all lists
	for _,sk_list in pairs(sk_lists) do
		SKC_DB[sk_list]:SetLiveBottom();
	end

	-- Sync SK lists with raid
	SyncPushSend("MSK",CHANNELS.SYNC_PUSH,"RAID")

	-- Reload GUI
	SKC_Main:ReloadUIMain();
	return;
end

local function InitiateLootDecision()
	-- Scans items / characters and initiates loot decisions for valid characters
	-- For Reference: local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i_loot)
	if not IsMasterLooter() then return end
	-- Make loot decision active
	Loot_Decision_Pending = true;
	-- Reset guild loot decisions and loot prio
	-- SKC_DB["MSK"]:ResetLoot();
	-- Reset message count
	SK_MessagesReceived = 0;
	SK_MessagesSent = 0;
	-- Determine item to start distribution event
	-- Initiate for first item
	local i_loot = 1;
	-- get item data
	local lootType = GetLootSlotType(i_loot); -- 1 for items, 2 for money, 3 for archeology(and other currencies?)
	local _, lootName, _, _, lootRarity, _, _, _, _ = GetLootSlotInfo(i_loot)
	-- Only perform SK for items of rarity threshold or higher
	if lootType == 1 and lootRarity >= LOOT_DECISION.OPTIONS.RARITY_THRESHOLD then
		-- Valid item
		SK_Item = GetLootSlotLink(i_loot);
		SKC_Main:Print("NORMAL","Distributing "..SK_Item);
		-- Scan all possible characters to distribute loot
		for i_char = 1,40 do
			local char_name = GetMasterLootCandidate(i_loot,i_char);
			if char_name ~= nil then
				-- send loot distribution initiation
				SK_MessagesSent = SK_MessagesSent + 1;
				C_ChatInfo.SendAddonMessage(CHANNELS.LOOT_DIST,LOOT_DECSK_Item,"WHISPER",char_name);
			end
		end
	end
	-- end loot decision
	Loot_Decision_Pending = false;
	-- sync live list
	SyncRaidAndLiveList();
	return;
end

local function CreateUIBorder(title,width,height)
	-- Create Border
	local border_key = title.."_border";
	SKC_UIMain[border_key] = CreateFrame("Frame",border_key,SKC_UIMain,"TranslucentFrameTemplate");
	SKC_UIMain[border_key]:SetSize(width,height);
	SKC_UIMain[border_key].Bg:SetAlpha(0.0);
	-- Create Title
	local title_key = "title";
	SKC_UIMain[border_key][title_key] = CreateFrame("Frame",title_key,SKC_UIMain[border_key],"TranslucentFrameTemplate");
	SKC_UIMain[border_key][title_key]:SetSize(UI_DIMENSIONS.SK_TAB_TITLE_CARD_WIDTH,UI_DIMENSIONS.SK_TAB_TITLE_CARD_HEIGHT);
	SKC_UIMain[border_key][title_key]:SetPoint("BOTTOM",SKC_UIMain[border_key],"TOP",0,-20);
	SKC_UIMain[border_key][title_key].Text = SKC_UIMain[border_key][title_key]:CreateFontString(nil,"ARTWORK")
	SKC_UIMain[border_key][title_key].Text:SetFontObject("GameFontNormal")
	SKC_UIMain[border_key][title_key].Text:SetPoint("CENTER",0,0)
	SKC_UIMain[border_key][title_key].Text:SetText(title)

	return border_key
end
--------------------------------------
-- SHARED FUNCTIONS
--------------------------------------
function SKC_Main:ToggleUIMain(force_show)
	local menu = SKC_UIMain or SKC_Main:CreateUIMain();
	-- Refresh Data
	PopulateData("MSK");
	menu:SetShown(force_show or not menu:IsShown());
end

function SKC_Main:ReloadUIMain()
	local is_shown = false;
	if SKC_UIMain ~= nil then is_shown = SKC_UIMain:IsShown() end
	local menu = SKC_UIMain or SKC_Main:CreateUIMain();
	-- Refresh Data
	PopulateData("MSK");
	menu:SetShown(is_shown);
end

function SKC_Main:GetThemeColor(type)
	local c = THEME.PRINT[type];
	return c.r, c.g, c.b, c.hex;
end

function SKC_Main:Print(type,...)
    local hex = select(4, SKC_Main:GetThemeColor(type));
	local prefix = string.format("|cff%s%s|r", hex:upper(), "SKC:");
    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, ...));
end

function SKC_Main:isML()
	-- Check if current player is master looter
	return(ML_OVRD or IsMasterLooter());
end

function SKC_Main:isGL()
	-- Check if current player is guild leader
	return(GL_OVRD or IsGuildLeader());
end

function SKC_Main:BenchShow()
	-- prints the current bench
	if #SKC_DB.Bench == 0 then
		SKC_Main:Print("NORMAL","Bench is empty");
	else
		SKC_Main:Print("NORMAL","Bench:");
		for idx,name in ipairs(SKC_DB.Bench) do
			SKC_Main:Print("NORMAL",name);
		end
	end
	return;
end

function SKC_Main:BenchAdd(name)
	-- add name to Bench if they exist in the guild DB
	if not SKC_Main:isGL() and not SKC_Main:isML() then
		SKC_Main:Print("ERROR","You must be master looter or guild leader to do that.")
		return false;
	end
	if not SKC_DB.GuildData:Exists(name) then
		SKC_Main:Print("ERROR",name.." not in guild database");
		return false;
	else
		SKC_DB.Bench[#SKC_DB.Bench + 1] = name;
		SKC_Main:Print("NORMAL",name.." added to bench");
		return true;
	end
end

function SKC_Main:BenchClear()
	-- prints the current bench
	if not SKC_Main:isGL() and not SKC_Main:isML() then
		SKC_Main:Print("ERROR","You must be master looter or guild leader to do that.")
		return;
	end
	SKC_DB.Bench = {};
	SKC_Main:Print("NORMAL","Bench cleared");
	return;
end

function SKC_Main:ExportLog()
	local name = "Log Export";
	-- instantiate frame
	local menu = SKC_UICSV[name] or CreateUICSV(name,false);
	menu:SetShown(true);
	-- Add log data
	local log_data = "";
	for idx1,log_entry in ipairs(SKC_DB.RaidLog) do
		for idx2,data in ipairs(log_entry) do
			log_data = log_data..tostring(data);
			log_data = log_data..",";
		end
		log_data = log_data.."\n";
	end
	SKC_UICSV[name].EditBox:SetText(log_data);
	SKC_UICSV[name].EditBox:HighlightText();
end

-- if part == "INIT" then
-- 	local time_stamp = msg_rem;
-- 	time_stamp = NumOut(time_stamp);
-- 	SKC_DB.LootPrio = LootPrio:new(nil);
-- 	SKC_DB.LootPrio.edit_ts_generic = time_stamp;
-- elseif part == "META" then
-- 	local item, sk_list, res, de, open_roll = strsplit(",",msg_rem,5);
-- 	item = StrOut(item);
-- 	SKC_DB.LootPrio.items[item] = Prio:new(nil);
-- 	SKC_DB.LootPrio.items[item].sk_list = StrOut(sk_list);
-- 	SKC_DB.LootPrio.items[item].reserved = BoolOut(res);
-- 	SKC_DB.LootPrio.items[item].DE = BoolOut(de);
-- 	SKC_DB.LootPrio.items[item].open_roll = BoolOut(open_roll);
-- elseif part == "DATA" then
-- 	local item, msg_rem = strsplit(",",msg_rem,2);
-- 	item = StrOut(item);
-- 	local plvl = nil;
-- 	for idx,spec_class in ipairs(SPEC_CLASS) do
-- 		plvl, msg_rem = strsplit(",",msg_rem,2);
-- 		SKC_DB.LootPrio.items[item].prio[idx] = NumOut(plvl);
-- 	end

local function OnClick_ImportLootPrio()
	-- imports loot prio CSV to database
	-- reset database
	SKC_DB.LootPrio = LootPrio:new(nil);
	-- get text
	local name = "Loot Priority Import";
	local txt = SKC_UICSV[name].EditBox:GetText();
	-- skip first 3 rows
	local skip_cnt = 0;
	local line = nil;
	local txt_rem = txt;
	while skip_cnt < 3 do
		line, txt_rem = strsplit("\n",txt_rem,2);
		skip_cnt = skip_cnt + 1;
	end
	-- read data
	local valid = true;
	while txt_rem ~= nil do
		line, txt_rem = strsplit("\n",txt_rem,2);
		local item, sk_list, res, de, open_roll, prios = strsplit(",",line,6);
		item = StrOut(item);
		sk_list = StrOut(sk_list);
		-- check validity
		valid = sk_list == "MSK" or sk_list == "TSK";
		if not valid then
			SKC_Main:Print("ERROR","Invalid SK List for "..item);
			break;
		end
		-- write meta data for item
		SKC_DB.LootPrio.items[item] = Prio:new(nil);
		SKC_DB.LootPrio.items[item].sk_list = sk_list;
		SKC_DB.LootPrio.items[item].reserved = BoolOut(res);
		SKC_DB.LootPrio.items[item].DE = BoolOut(de);
		SKC_DB.LootPrio.items[item].open_roll = BoolOut(open_roll);
		-- read prios
		local idx = 1;
		while prios ~= nil do
			valid = idx <= 22;
			if not valid then
				SKC_Main:Print("ERROR","Too many Class/Spec combinations");
				break;
			end
			val, prios = strsplit(",",prios,2);
			val = NumOut(val);
			-- check prio value
			valid = (val >= 1) and (val <= 6);
			if not valid then
				SKC_Main:Print("ERROR","Invalid prio level for "..item);
				break;
			end
			-- write prio value
			SKC_DB.LootPrio.items[item].prio[idx] = val;
			idx = idx + 1;
		end
		if not valid then break end
	end
	if not valid then
		SKC_DB.LootPrio = LootPrio:new(nil);
		return;
	end
	-- update edit timestamp
	local ts = time();
	SKC_DB.LootPrio.edit_ts_raid = ts;
	SKC_DB.LootPrio.edit_ts_generic = ts;
	SKC_Main:Print("NORMAL","Loot Priority Import Complete");
	SKC_Main:Print("NORMAL",SKC_DB.LootPrio:length().." items added");
	return;
end

local function OnClick_ImportGuildData()
	-- imports loot guild data CSV to database
end

function SKC_Main:CSVImport(name)
	-- instantiate frame
	local menu = SKC_UICSV[name] or CreateUICSV(name,true);
	menu:SetShown(true);
	-- bind function for import button
	if name == "Loot Priority Import" then
		SKC_UICSV[name].ImportBtn:SetScript("OnMouseDown",OnClick_ImportLootPrio);
	elseif name == "Guild Data Import" then
		SKC_UICSV[name].ImportBtn:SetScript("OnMouseDown",OnClick_ImportGuildData);
	end
	return;
end

function SKC_Main:CreateUIMain()
	-- If addon not yet loaded, reject
	if not event_states.AddonLoaded then return end

    SKC_UIMain = CreateFrame("Frame", "SKC_UIMain", UIParent, "UIPanelDialogTemplate");
	SKC_UIMain:SetSize(UI_DIMENSIONS.MAIN_WIDTH,UI_DIMENSIONS.MAIN_HEIGHT);
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
	local filter_border_key = CreateUIBorder("Filters",UI_DIMENSIONS.SK_FILTER_WIDTH,UI_DIMENSIONS.SK_FILTER_HEIGHT)
	-- set position
	SKC_UIMain[filter_border_key]:SetPoint("TOPLEFT", SKC_UIMainTitleBG, "TOPLEFT", UI_DIMENSIONS.MAIN_BORDER_PADDING, UI_DIMENSIONS.MAIN_BORDER_Y_TOP);
	-- create details fields
	local faction_class;
	if UnitFactionGroup("player") == "Horde" then faction_class="Shaman" else faction_class="Paladin" end
	local filter_roles = {"DPS","Healer","Tank","Live","Main","Alt","Inactive","Active","Druid","Hunter","Mage","Priest","Rogue","Warlock","Warrior",faction_class};
	for idx,value in ipairs(filter_roles) do
		if value ~= "SKIP" then
			local row = math.floor((idx - 1) / 4); -- zero based
			local col = (idx - 1) % 4; -- zero based
			SKC_UIMain[filter_border_key][value] = CreateFrame("CheckButton", nil, SKC_UIMain[filter_border_key], "UICheckButtonTemplate");
			SKC_UIMain[filter_border_key][value]:SetSize(25,25);
			SKC_UIMain[filter_border_key][value]:SetChecked(FilterStates["MSK"][value]);
			SKC_UIMain[filter_border_key][value]:SetScript("OnClick",OnCheck_FilterFunction)
			SKC_UIMain[filter_border_key][value]:SetPoint("TOPLEFT", SKC_UIMain[filter_border_key], "TOPLEFT", 22 + 73*col , -20 + -24*row);
			SKC_UIMain[filter_border_key][value].text:SetFontObject("GameFontNormalSmall");
			SKC_UIMain[filter_border_key][value].text:SetText(value);
			if idx > 8 then
				-- assign class colors
				SKC_UIMain[filter_border_key][value].text:SetTextColor(CLASSES[value].color.r,CLASSES[value].color.g,CLASSES[value].color.b,1.0);
			end
		end
	end

	-- SK List border
	local sk_list = "MSK";
	local sk_list_border_key = CreateUIBorder(sk_list,UI_DIMENSIONS.SK_LIST_WIDTH + 2*UI_DIMENSIONS.SK_LIST_BORDER_OFFST,UI_DIMENSIONS.SK_LIST_HEIGHT + 2*UI_DIMENSIONS.SK_LIST_BORDER_OFFST);
	-- set position
	SKC_UIMain[sk_list_border_key]:SetPoint("TOPLEFT", SKC_UIMain[filter_border_key], "TOPRIGHT", UI_DIMENSIONS.MAIN_BORDER_PADDING, 0);

	-- Create SK list panel
	SKC_UIMain[sk_list] = CreateFrame("Frame",sk_list,SKC_UIMain,"InsetFrameTemplate");
	SKC_UIMain[sk_list]:SetSize(UI_DIMENSIONS.SK_LIST_WIDTH,UI_DIMENSIONS.SK_LIST_HEIGHT);
	SKC_UIMain[sk_list]:SetPoint("TOP",SKC_UIMain[sk_list_border_key],"TOP",0,-UI_DIMENSIONS.SK_LIST_BORDER_OFFST);

	-- Create scroll frame on SK list
    SKC_UIMain[sk_list].SK_List_SF = CreateFrame("ScrollFrame","SK_List_SF",SKC_UIMain[sk_list],"UIPanelScrollFrameTemplate2");
    SKC_UIMain[sk_list].SK_List_SF:SetPoint("TOPLEFT",SKC_UIMain[sk_list],"TOPLEFT",0,-2);
	SKC_UIMain[sk_list].SK_List_SF:SetPoint("BOTTOMRIGHT",SKC_UIMain[sk_list],"BOTTOMRIGHT",0,2);
	SKC_UIMain[sk_list].SK_List_SF:SetClipsChildren(true);
	SKC_UIMain[sk_list].SK_List_SF:SetScript("OnMouseWheel",OnMouseWheel_ScrollFrame);
	SKC_UIMain[sk_list].SK_List_SF.ScrollBar:SetPoint("TOPLEFT",SKC_UIMain[sk_list].SK_List_SF,"TOPRIGHT",-22,-21);

	-- Create scroll child
	local scroll_child = CreateFrame("Frame",nil,SKC_UIMain[sk_list].SK_List_SF);
	scroll_child:SetSize(UI_DIMENSIONS.SK_LIST_WIDTH,GetScrollMax());
	SKC_UIMain[sk_list].SK_List_SF:SetScrollChild(scroll_child);

	-- Create SK cards
	SKC_UIMain[sk_list].NumberFrame = {};
	SKC_UIMain[sk_list].NameFrame = {};
	for idx = 1, SKC_DB.Count60 do
		-- Create number frames
		SKC_UIMain[sk_list].NumberFrame[idx] = CreateFrame("Frame",nil,SKC_UIMain[sk_list].SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain[sk_list].NumberFrame[idx]:SetSize(30,UI_DIMENSIONS.SK_CARD_HEIGHT);
		SKC_UIMain[sk_list].NumberFrame[idx]:SetPoint("TOPLEFT",SKC_UIMain[sk_list].SK_List_SF:GetScrollChild(),"TOPLEFT",8,-1*((idx-1)*(UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING) + UI_DIMENSIONS.SK_CARD_SPACING));
		SKC_UIMain[sk_list].NumberFrame[idx].Text = SKC_UIMain[sk_list].NumberFrame[idx]:CreateFontString(nil,"ARTWORK")
		SKC_UIMain[sk_list].NumberFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain[sk_list].NumberFrame[idx].Text:SetPoint("CENTER",0,0)
		SKC_UIMain[sk_list].NumberFrame[idx]:SetScript("OnMouseDown",OnClick_NumberCard);
		-- Create named card frames
		SKC_UIMain[sk_list].NameFrame[idx] = CreateFrame("Frame",nil,SKC_UIMain[sk_list].SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain[sk_list].NameFrame[idx]:SetSize(UI_DIMENSIONS.SK_CARD_WIDTH,UI_DIMENSIONS.SK_CARD_HEIGHT);
		SKC_UIMain[sk_list].NameFrame[idx]:SetPoint("TOPLEFT",SKC_UIMain[sk_list].SK_List_SF:GetScrollChild(),"TOPLEFT",43,-1*((idx-1)*(UI_DIMENSIONS.SK_CARD_HEIGHT + UI_DIMENSIONS.SK_CARD_SPACING) + UI_DIMENSIONS.SK_CARD_SPACING));
		SKC_UIMain[sk_list].NameFrame[idx].Text = SKC_UIMain[sk_list].NameFrame[idx]:CreateFontString(nil,"ARTWORK")
		SKC_UIMain[sk_list].NameFrame[idx].Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain[sk_list].NameFrame[idx].Text:SetPoint("CENTER",0,0)
		-- Add texture for color
		SKC_UIMain[sk_list].NameFrame[idx].bg = SKC_UIMain[sk_list].NameFrame[idx]:CreateTexture(nil,"BACKGROUND");
		SKC_UIMain[sk_list].NameFrame[idx].bg:SetAllPoints(true);
		-- Bind function for click event
		SKC_UIMain[sk_list].NameFrame[idx]:SetScript("OnMouseDown",OnClick_SK_Card);
	end

	-- Create details panel
	DD_State = 0; -- reset drop down options state
	local details_border_key = CreateUIBorder("Details",UI_DIMENSIONS.SK_DETAILS_WIDTH,UI_DIMENSIONS.SK_DETAILS_HEIGHT);
	-- set position
	SKC_UIMain[details_border_key]:SetPoint("TOPLEFT", SKC_UIMain[sk_list_border_key], "TOPRIGHT", UI_DIMENSIONS.MAIN_BORDER_PADDING, 0);
	-- create details fields
	local details_fields = {"Name","Class","Spec","Raid Role","Guild Role","Status","Activity"};
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

	-- Add SK buttons
	-- full SK
	SKC_UIMain[details_border_key].FullSK_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].FullSK_Btn:SetPoint("BOTTOM",SKC_UIMain[details_border_key],"BOTTOM",0,15);
	SKC_UIMain[details_border_key].FullSK_Btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[details_border_key].FullSK_Btn:SetText("Full SK");
	SKC_UIMain[details_border_key].FullSK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].FullSK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].FullSK_Btn:SetScript("OnMouseDown",OnClick_FullSK);
	SKC_UIMain[details_border_key].FullSK_Btn:Disable();
	-- single SK
	SKC_UIMain[details_border_key].SingleSK_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetPoint("RIGHT",SKC_UIMain[details_border_key].FullSK_Btn,"LEFT",-5,0);
	SKC_UIMain[details_border_key].SingleSK_Btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[details_border_key].SingleSK_Btn:SetText("Single SK");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].SingleSK_Btn:SetScript("OnMouseDown",OnClick_SingleSK);
	SKC_UIMain[details_border_key].SingleSK_Btn:Disable();
	-- set SK
	SKC_UIMain[details_border_key].SetSK_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[details_border_key].SetSK_Btn:SetPoint("LEFT",SKC_UIMain[details_border_key].FullSK_Btn,"RIGHT",5,0);
	SKC_UIMain[details_border_key].SetSK_Btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[details_border_key].SetSK_Btn:SetText("Set SK");
	SKC_UIMain[details_border_key].SetSK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[details_border_key].SetSK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[details_border_key].SetSK_Btn:SetScript("OnMouseDown",OnClick_SetSK);
	SKC_UIMain[details_border_key].SetSK_Btn:Disable();


	-- Decision region
	local decision_border_key = CreateUIBorder("Decision",UI_DIMENSIONS.DECISION_WIDTH,UI_DIMENSIONS.DECISION_HEIGHT)
	-- set position
	SKC_UIMain[decision_border_key]:SetPoint("TOPLEFT", SKC_UIMain[filter_border_key], "TOPLEFT", 0, -UI_DIMENSIONS.SK_FILTER_HEIGHT - UI_DIMENSIONS.MAIN_BORDER_PADDING);

	-- set texture / hidden frame for button click
	SKC_UIMain[decision_border_key].ItemTexture = SKC_UIMain[decision_border_key]:CreateTexture(nil, "ARTWORK");
	SKC_UIMain[decision_border_key].ItemTexture:SetSize(UI_DIMENSIONS.ITEM_WIDTH,UI_DIMENSIONS.ITEM_HEIGHT);
	SKC_UIMain[decision_border_key].ItemTexture:SetPoint("TOP",SKC_UIMain[decision_border_key],"TOP",0,-45)
	SKC_UIMain[decision_border_key].ItemClickBox = CreateFrame("Frame", nil, SKC_UIMain);
	SKC_UIMain[decision_border_key].ItemClickBox:SetSize(UI_DIMENSIONS.ITEM_WIDTH,UI_DIMENSIONS.ITEM_HEIGHT);
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
	SKC_UIMain[decision_border_key].SK_Btn:SetPoint("TOPRIGHT",SKC_UIMain[decision_border_key].ItemTexture,"BOTTOM",-60,-10);
	SKC_UIMain[decision_border_key].SK_Btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[decision_border_key].SK_Btn:SetText("SK");
	SKC_UIMain[decision_border_key].SK_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[decision_border_key].SK_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[decision_border_key].SK_Btn:SetScript("OnMouseDown",OnClick_SK);
	SKC_UIMain[decision_border_key].SK_Btn:Disable();
	-- Roll 
	SKC_UIMain[decision_border_key].Roll_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[decision_border_key].Roll_Btn:SetPoint("TOP",SKC_UIMain[decision_border_key].ItemTexture,"BOTTOM",0,-10);
	SKC_UIMain[decision_border_key].Roll_Btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[decision_border_key].Roll_Btn:SetText("Roll");
	SKC_UIMain[decision_border_key].Roll_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[decision_border_key].Roll_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[decision_border_key].Roll_Btn:SetScript("OnMouseDown",OnClick_ROLL);
	SKC_UIMain[decision_border_key].Roll_Btn:Disable();
	-- Pass
	SKC_UIMain[decision_border_key].Pass_Btn = CreateFrame("Button", nil, SKC_UIMain, "GameMenuButtonTemplate");
	SKC_UIMain[decision_border_key].Pass_Btn:SetPoint("TOPLEFT",SKC_UIMain[decision_border_key].ItemTexture,"BOTTOM",60,-10);
	SKC_UIMain[decision_border_key].Pass_Btn:SetSize(UI_DIMENSIONS.BTN_WIDTH, UI_DIMENSIONS.BTN_HEIGHT);
	SKC_UIMain[decision_border_key].Pass_Btn:SetText("Pass");
	SKC_UIMain[decision_border_key].Pass_Btn:SetNormalFontObject("GameFontNormal");
	SKC_UIMain[decision_border_key].Pass_Btn:SetHighlightFontObject("GameFontHighlight");
	SKC_UIMain[decision_border_key].Pass_Btn:SetScript("OnMouseDown",OnClick_PASS);
	SKC_UIMain[decision_border_key].Pass_Btn:Disable();
	-- timer bar
	SKC_UIMain[decision_border_key].TimerBorder = CreateFrame("Frame",nil,SKC_UIMain,"TranslucentFrameTemplate");
	SKC_UIMain[decision_border_key].TimerBorder:SetSize(UI_DIMENSIONS.STATUS_BAR_BRDR_WIDTH,UI_DIMENSIONS.STATUS_BAR_BRDR_HEIGHT);
	SKC_UIMain[decision_border_key].TimerBorder:SetPoint("TOP",SKC_UIMain[decision_border_key].Roll_Btn,"BOTTOM",0,-7);
	SKC_UIMain[decision_border_key].TimerBorder.Bg:SetAlpha(1.0);
	-- status bar
	SKC_UIMain[decision_border_key].TimerBar = CreateFrame("StatusBar",nil,SKC_UIMain);
	SKC_UIMain[decision_border_key].TimerBar:SetSize(UI_DIMENSIONS.STATUS_BAR_BRDR_WIDTH - UI_DIMENSIONS.STATUS_BAR_WIDTH_OFFST,UI_DIMENSIONS.STATUS_BAR_BRDR_HEIGHT - UI_DIMENSIONS.STATUS_BAR_HEIGHT_OFFST);
	SKC_UIMain[decision_border_key].TimerBar:SetPoint("CENTER",SKC_UIMain[decision_border_key].TimerBorder,"CENTER",0,-1);
	-- background texture
	SKC_UIMain[decision_border_key].TimerBar.bg = SKC_UIMain[decision_border_key].TimerBar:CreateTexture(nil,"BACKGROUND",nil,-7);
	SKC_UIMain[decision_border_key].TimerBar.bg:SetAllPoints(SKC_UIMain[decision_border_key].TimerBar);
	SKC_UIMain[decision_border_key].TimerBar.bg:SetColorTexture(unpack(THEME.STATUS_BAR_COLOR));
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
	SKC_UIMain[decision_border_key].TimerText:SetText(LOOT_DECISION.OPTIONS.MAX_TIME)
	-- values
	SKC_UIMain[decision_border_key].TimerBar:SetMinMaxValues(0,LOOT_DECISION.OPTIONS.MAX_TIME);
	SKC_UIMain[decision_border_key].TimerBar:SetValue(0);

	-- Populate Data
	PopulateData("MSK");
    
	SKC_UIMain:Hide();
	return SKC_UIMain;
end

--------------------------------------
-- EVENTS
--------------------------------------
local function EventHandler(self,event,...)
	if event == "CHAT_MSG_ADDON" then
		AddonMessageRead(...);
	elseif event == "ADDON_LOADED" then
		OnAddonLoad(...);
	elseif event == "PLAYER_LOGIN" then
		GuildRoster();
	elseif event == "GUILD_ROSTER_UPDATE" then
		FetchGuildInfo(InitSetup);
		InitSetup = false;
		event_states.GuildRosterUpdated = true;
		LoginSyncCheckSend();
		event_states.SyncRequestSent = true;
	elseif event == "RAID_ROSTER_UPDATE" then
		SyncRaidAndLiveList();
	elseif event == "PARTY_LOOT_METHOD_CHANGED" then
		SyncRaidAndLiveList();
	elseif event == "OPEN_MASTER_LOOT_LIST" then
		InitiateLootDecision();
	elseif event == "RAID_INSTANCE_WELCOME" then
		if not event_states.RaidLoggingActive then
			event_states.RaidLoggingActive = true;
			ResetRaidLogging();
		end
	end
	
	return;
end

local events = CreateFrame("Frame");
events:RegisterEvent("CHAT_MSG_ADDON");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("PLAYER_LOGIN");
events:RegisterEvent("GUILD_ROSTER_UPDATE");
events:RegisterEvent("RAID_ROSTER_UPDATE");
events:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
events:RegisterEvent("OPEN_MASTER_LOOT_LIST");
events:RegisterEvent("RAID_INSTANCE_WELCOME");
events:SetScript("OnEvent", EventHandler);