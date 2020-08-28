--------------------------------------
-- SKC
--------------------------------------
-- Addon definition
-- TODO:
-- add SK off field to LP (turn off SK button, check that both sk cant be off and roll off)
-- clean out text fields after import? (kinda useful for testing)
--------------------------------------
-- ADDON CONSTRUCTOR
--------------------------------------
SKC = LibStub("AceAddon-3.0"):NewAddon("SKC","AceComm-3.0","AceConsole-3.0","AceEvent-3.0");
SKC.lib_ser = LibStub:GetLibrary("AceSerializer-3.0");
SKC.lib_comp = LibStub:GetLibrary("LibCompress");
SKC.lib_enc = SKC.lib_comp:GetAddonEncodeTable();
--------------------------------------
-- DEV CONTROLS
--------------------------------------
SKC.DEV = {
	GL_OVRD = nil, -- name of faux GL to override guild leader permissions (local)
    ML_OVRD = nil, -- name of faux ML override master looter permissions (local)
    LOOT_SAFE_MODE = false, -- true if saving loot is immediately rejected
    LOOT_DIST_DISABLE = false, -- true if loot distribution is disabled
    LOG_ACTIVE_OVRD = false, -- true to force logging
	GUILD_CHARS_OVRD = { -- characters which are pushed into GuildData
	},
    ACTIVE_INSTANCE_OVRD = false, -- true if SKC can be used outside of active instances
    LOOT_OFFICER_OVRD = false, -- true if SKC can be used without loot officer 
	VERBOSITY_LEVEL = 0,-- verbosity level (debug messages at or below this level will print)
	VERBOSE = { -- verbosity levels
		COMM = 1,
		LOOT = 2,
		SYNC_TICK = 3,
		SYNC_LOW = 4,
		SYNC_HIGH = 5,
		RAID = 5,
		GUILD = 5,
		GUI = 5,
		MERGE = 5,
	}
};
--------------------------------------
-- CONSTANTS
--------------------------------------
SKC.GUILD_LEADER = nil;
SKC.DATE_FORMAT = "%m/%d/%Y %I:%M:%S %p";
SKC.UI_DIMS = {
	MAIN_WIDTH = 815,
	MAIN_HEIGHT = 450,
	MAIN_BORDER_Y_TOP = -60,
	MAIN_BORDER_PADDING = 15,
	SK_TAB_TITLE_CARD_WIDTH = 80,
	SK_TAB_TITLE_CARD_HEIGHT = 40,
	LOOT_GUI_TITLE_CARD_WIDTH = 80,
	LOOT_GUI_TITLE_CARD_HEIGHT = 40,
	SK_FILTER_WIDTH = 255,
	SK_FILTER_HEIGHT = 185,
	SK_FILTER_Y_OFFST = -34,
	SKC_STATUS_WIDTH = 255,
	SKC_STATUS_HEIGHT = 135,
	DECISION_WIDTH = 250,
	DECISION_HEIGHT = 160,
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
	LOOT_BTN_WIDTH = 60,
	LOOT_BTN_HEIGHT = 35,
	STATUS_BAR_BRDR_WIDTH = 210,
	STATUS_BAR_BRDR_HEIGHT = 40,
	STATUS_BAR_WIDTH_OFFST = 24,
	STATUS_BAR_HEIGHT_OFFST = 24,
	CSV_WIDTH = 660,
	CSV_HEIGHT = 300,
	CSV_EB_WIDTH = 600,
	CSV_EB_HEIGHT = 200,
	MAX_SK_CARDS = 500,
};
SKC.THEME = { -- general color themes
	PRINT = {
		NORMAL = {r = 26/255, g = 1, b = 178/255, hex = "1affb2"},
		WARN = {r = 1, g = 0.8, b = 0, hex = "ffcc00"},
		ALERT = {r = 1, g = 0, b = 1, hex = "ff00ff"},
		ERROR = {r = 1, g = 0.2, b = 0, hex = "ff3300"},
		DEBUG = {r = 102/255, g = 0/255, b = 204/255, hex = "6600cc"},
		HELP = {r = 1, g = 204/255, b = 0, hex = "ffcc00"},
	},
	STATUS_BAR_COLOR = {0.0,0.6,0.0},
};
SKC.CHANNELS = { -- channels for inter addon communication (const)
	SYNC_CHECK = "?Q!@$8a1pc8QqYyH",
	SYNC_RQST = "6-F?832qBmrJE?pR",
	SYNC_PUSH = "d$8B=qB4VsW&&Y^D",
	LOOT = "xBPE9,-Fjsc+A#rm",
	LOOT_DECISION = "ksg(Ak2.*/@&+`8Q",
	LOOT_DECISION_PRINT = "xP@&!9hQxY]1K&C4",
	LOOT_OUTCOME_PRINT = "aP@yX9hQf}89K&C4",
};
function OnClick_EditDropDownOption(field,value) -- Must be global
	-- Triggered when drop down of edit button is selected
	local name = SKC.MainGUI["Details_border"]["Name"].Data:GetText();
	local class = SKC.MainGUI["Details_border"]["Class"].Data:GetText();
	-- Edit GuildData
	local prev_val = SKC.db.char.GD:GetData(name,field);
	prev_val = SKC.db.char.GD:SetData(name,field,value);
	-- Refresh data
	SKC:PopulateData(name);
	-- Reset menu toggle
	SKC.event_states.DropDownID = 0;
	return;
end
SKC.CLASSES = { -- wow classes
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
			r = 0.0, 
			g = 0.44,
			b = 0.87,
			hex = "0070DE"
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
SKC.TIER_ARMOR_SETS = { -- map from armor set name to ordered list of individual item names (used as a shortcut for prio doc import)
	["Cenarion Raiment"] = {
		"Cenarion Belt",
		"Cenarion Boots",
		"Cenarion Bracers",
		"Cenarion Vestments",
		"Cenarion Gloves",
		"Cenarion Helm",
		"Cenarion Leggings",
		"Cenarion Spaulders",
	},
	["Stormrage Raiment"] = {
		"Stormrage Belt",
		"Stormrage Boots",
		"Stormrage Bracers",
		"Stormrage Chestguard",
		"Stormrage Cover",
		"Stormrage Handguards",
		"Stormrage Legguards",
		"Stormrage Pauldrons",
	},
	["Giantstalker Armor"] = {
		"Giantstalker's Belt",
		"Giantstalker's Boots",
		"Giantstalker's Bracers",
		"Giantstalker's Breastplate",
		"Giantstalker's Epaulets",
		"Giantstalker's Gloves",
		"Giantstalker's Helmet",
		"Giantstalker's Leggings",
	},
	["Dragonstalker Armor"] = {
		"Dragonstalker's Belt",
		"Dragonstalker's Bracers",
		"Dragonstalker's Breastplate",
		"Dragonstalker's Gauntlets",
		"Dragonstalker's Greaves",
		"Dragonstalker's Helm",
		"Dragonstalker's Legguards",
		"Dragonstalker's Spaulders",
	},
	["Arcanist Regalia"] = {
		"Arcanist Belt",
		"Arcanist Bindings",
		"Arcanist Crown",
		"Arcanist Boots",
		"Arcanist Gloves",
		"Arcanist Leggings",
		"Arcanist Mantle",
		"Arcanist Robes",
	},
	["Netherwind Regalia"] = {
		"Netherwind Belt",
		"Netherwind Bindings",
		"Netherwind Boots",
		"Netherwind Crown",
		"Netherwind Mantle",
		"Netherwind Gloves",
		"Netherwind Pants",
		"Netherwind Robes",
	},
	["Lawbringer Armor"] = {
		"Lawbringer Belt",
		"Lawbringer Boots",
		"Lawbringer Bracers",
		"Lawbringer Chestguard",
		"Lawbringer Gauntlets",
		"Lawbringer Helm",
		"Lawbringer Legplates",
		"Lawbringer Spaulders",	
	},
	["Judgement Armor"] = {
		"Judgement Belt",
		"Judgement Bindings",
		"Judgement Breastplate",
		"Judgement Crown",
		"Judgement Gauntlets",
		"Judgement Legplates",
		"Judgement Sabatons",
		"Judgement Spaulders",
	},
	["Vestments of Prophecy"] = {
		"Boots of Prophecy",
		"Circlet of Prophecy",
		"Girdle of Prophecy",
		"Gloves of Prophecy",
		"Pants of Prophecy",
		"Mantle of Prophecy",
		"Robes of Prophecy",
		"Vambraces of Prophecy",
	},
	["Vestments of Transcendence"] = {
		"Belt of Transcendence",
		"Bindings of Transcendence",
		"Boots of Transcendence",
		"Halo of Transcendence",
		"Handguards of Transcendence",
		"Leggings of Transcendence",
		"Pauldrons of Transcendence",
		"Robes of Transcendence",
	},
	["Nightslayer Armor"] = {
		"Nightslayer Belt",
		"Nightslayer Boots",
		"Nightslayer Bracelets",
		"Nightslayer Chestpiece",
		"Nightslayer Cover",
		"Nightslayer Gloves",
		"Nightslayer Pants",
		"Nightslayer Shoulder Pads",
	},
	["Bloodfang Armor"] = {
		"Bloodfang Belt",
		"Bloodfang Boots",
		"Bloodfang Bracers",
		"Bloodfang Chestpiece",
		"Bloodfang Gloves",
		"Bloodfang Hood",
		"Bloodfang Pants",
		"Bloodfang Spaulders",
	},
	["The Earthfury"] = {
		"Earthfury Belt",
		"Earthfury Boots",
		"Earthfury Bracers",
		"Earthfury Vestments",
		"Earthfury Epaulets",
		"Earthfury Gauntlets",
		"Earthfury Helmet",
		"Earthfury Legguards",
	},
	["The Ten Storms"] = {
		"Belt of Ten Storms",
		"Bracers of Ten Storms",
		"Breastplate of Ten Storms",
		"Epaulets of Ten Storms",
		"Gauntlets of Ten Storms",
		"Greaves of Ten Storms",
		"Helmet of Ten Storms",
		"Legplates of Ten Storms",
	},
	["Felheart Raiment"] = {
		"Felheart Belt",
		"Felheart Bracers",
		"Felheart Gloves",
		"Felheart Pants",
		"Felheart Robes",
		"Felheart Shoulder Pads",
		"Felheart Horns",
		"Felheart Slippers",
	},
	["Nemesis Raiment"] = {
		"Nemesis Belt",
		"Nemesis Boots",
		"Nemesis Bracers",
		"Nemesis Gloves",
		"Nemesis Leggings",
		"Nemesis Robes",
		"Nemesis Skullcap",
		"Nemesis Spaulders",	
	},
	["Battlegear of Might"] = {
		"Belt of Might",
		"Bracers of Might",
		"Breastplate of Might",
		"Gauntlets of Might",
		"Helm of Might",
		"Legplates of Might",
		"Pauldrons of Might",
		"Sabatons of Might",
	},
	["Battlegear of Wrath"] = {
		"Bracelets of Wrath",
		"Breastplate of Wrath",
		"Gauntlets of Wrath",
		"Helm of Wrath",
		"Legplates of Wrath",
		"Pauldrons of Wrath",
		"Sabatons of Wrath",
		"Waistband of Wrath",
	},

};
SKC.CLASS_SPEC_MAP = { -- used to quickly get class spec name from value
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
};
SKC.SPEC_MAP = { -- used to quickly get spec name from value
	"Balance",
	"Resto",
	"FeralTank",
	"FeralDPS",
	"Any",
	"Any",
	"Holy",
	"Prot",
	"Ret",
	"Holy",
	"Shadow",
	"Any",
	"Daggers",
	"Swords",
	"Ele",
	"Enh",
	"Resto",
	"Any",
	"DPS",
	"Prot",
	"TwoHanded",
	"DualWield",
};
SKC.CHARACTER_DATA = { -- fields used to define character
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
				val = 0,
				text = "DPS",
			},
			Healer = {
				val = 1,
				text = "Healer",
			},
			Tank = {
				val = 2,
				text = "Tank",
			},
		},
	},
	["Guild Role"] = {
		text = "Guild Role",
		OPTIONS = {
			None = {
				val = 0,
				text = "None",
				func = function (self) OnClick_EditDropDownOption("Guild Role","None") end,
			},
			Disenchanter = {
				val = 1,
				text = "Disenchanter",
				func = function (self) OnClick_EditDropDownOption("Guild Role","Disenchanter") end,
			},
			Banker = {
				val = 2,
				text = "Banker",
				func = function (self) OnClick_EditDropDownOption("Guild Role","Banker") end,
			},
		},
	},
	Status = {
		text = "Status",
		OPTIONS = {
			Main = {
				val = 0,
				text = "Main",
				func = function (self) OnClick_EditDropDownOption("Status","Main") end,
			},
			Alt = {
				val = 1,
				text = "Alt",
				func = function (self) OnClick_EditDropDownOption("Status","Alt") end,
			},
		},
	},	
};
SKC.LOOT_DECISION = {
	PENDING = 1,
	PASS = 2,
	SK = 3,
	ROLL = 4,
	TEXT_MAP = {
		"PENDING",
		"PASS",
		"SK",
		"ROLL",
	},
	MIN_DECISION_TIME = 0,
	MAX_DECISION_TIME = 120,
	DEFAULT_DECISION_TIME = 30,
};
SKC.PRIO_TIERS = { -- possible prio tiers and associated numerical ordering
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
SKC.LOG_OPTIONS = {
	["Timestamp"] = {
		Text = "Timestamp",
	},
	["Master Looter"] = {
		Text = "Master Looter",
		Options = {
			THIS_PLAYER = UnitName("player"),
		},
	},
	["Event Type"] = {
		Text = "Event Type",
		Options = {
			Decision = "Decision",
			Outcome = "Outcome",
			SK_Change = "SK Change",
			LD = "Loot Distribution",
		},
	},
	["Event Details"] = {
		Text = "Event Details",
		Options = {
			-- Decision
			-- Outcome
			WSK = "Winner by SK",
			WR = "Winner by ROLL",
			DE = "Disenchant",
			GB = "Guild Bank",
			NLP = "Not in Loot Prio",
			NE = "None Elligible",
			-- SK Change
			AutoSK = "Auto SK",
			ManSetSK = "Manual Set SK",
			ManFullSK = "Manual Full SK",
			ManSingleSK = "Manual Single SK",
			-- Loot Distribution
			ALS = "Auto Loot Success",
			ALF = "Auto Loot Failure",
		},
	},
	["Subject"] = {
		Text = "Subject",
	},
	["Class"] = {
		Text = "Class",
	},
	["Spec"] = {
		Text = "Spec",
	},
	["Status"] = {
		Text = "Status",
	},
	["Item"] = {
		Text = "Item",
	},
	["SK List"] = {
		Text = "SK List",
		Options = {
			NONE = "NONE",
			MSK = "MSK",
			TSK = "TSK",
		}
	},
	["Prio"] = {
		Text = "Prio",
	},
	["Current SK Position"] = {
		Text = "Current SK Position",
	},
	["New SK Position"] = {
		Text = "New SK Position",
	},
	["Roll"] = {
		Text = "Roll",
	},
};
SKC.INSTANCE_NAME_MAP = {
	RFC = "Ragefire Chasm",
	WC = "Wailing Caverns",
	VC = "The Deadmines",
	ONY = "Onyxia's Lair",
	MC = "Molten Core",
	BWL = "Blackwing Lair",
	ZG = "Zul'Gurub",
	AQ20 = "Ruins of Ahn'Qiraj",
	AQ40 = "Temple of Ahn'Qiraj",
	NAXX = "Naxxramas",
};
SKC.ITEMS_WITH_COMMA = {
	["Ashjre'thul"] = "Ashjre'thul, Crossbow of Smiting",
	Ashkandi = "Ashkandi, Greatsword of the Brotherhood",
	["Crul'shorukh"] = "Crul'shorukh, Edge of Chaos",
	Gressil = "Gressil, Dawn of Ruin",
	Iblis = "Iblis, Blade of the Fallen Seraph",
	Maladath = "Maladath, Runed Blade of the Black Flight",
	["Mish'undare"] = "Mish'undare, Circlet of the Mind Flayer",
	Neretzek = "Neretzek, The Blood Drinker",
	["Zin'rokh"] = "Zin'rokh, Destroyer of Worlds",
};
SKC.STATUS_ENUM = {
	ACTIVE = {
		val = 0,
		text = "Active",
		color = {0,1,0},
	},
	DISABLED = {
		val = 1,
		text = "Disabled",
		color = {1,0,0},
	},
	INACTIVE_GL = {
		val = 2,
		text = "Inactive (GL)",
		color = {1,0,0},
	},
	INACTIVE_VER = {
		val = 3,
		text = "Inactive (VER)",
		color = {1,0,0},
	},
	INACTIVE_RAID = {
		val = 4,
		text = "Inactive (RAID)",
		color = {1,0,0},
	},
	INACTIVE_ML = {
		val = 5,
		text = "Inactive (ML)",
		color = {1,0,0},
	},
	INACTIVE_LO = {
		val = 6,
		text = "Inactive (LO)",
		color = {1,0,0},
	},
	INACTIVE_AI = {
		val = 7,
		text = "Inactive (AI)",
		color = {1,0,0},
	},
};
SKC.SYNC_STATUS_ENUM = {
	COMPLETE = {
		val = 0,
		text = "Complete",
		color = {0,1,0},
	},
	SENDING = {
		val = 1,
		text = "Sending",
		color = {1,0,0},
	},
	READING = {
		val = 2,
		text = "Reading",
		color = {1,0,0},
	},
};
SKC.DB_SYNC_ORDER = { -- order in which databases are synchronized
	"GLP",
	"GD",
	"LOP",
	"MSK",
	"TSK",
	"LP",
}
--------------------------------------
-- VARIABLES
--------------------------------------
SKC.Status = SKC.STATUS_ENUM.INACTIVE_GL; -- SKC status state enumeration
SKC.ReadStatus = {}; -- Synchronization reading status state (per database). true = reading, false = complete
SKC.SendStatus = {}; -- Synchronization reading status state (per database). 0.0 = send is 0% complete, 1.0 = send is 100% complete
SKC.SyncPartner = {}; -- name of player who we are currently expecting a sync from. nil if no sync expected
SKC.SyncCandidate = {}; -- map of db to name of candidate sync partner
-- local tmp_sync_var = {}; -- temporary variable used to hold incoming data when synchronizing
SKC.UnFilteredCnt = 0; -- defines max count of sk cards to scroll over (XXX)
-- local SK_MessagesSent = 0;
-- local SK_MessagesReceived = 0;
SKC.event_states = { -- tracks if certain events have fired
	AddonLoaded = false,
	DropDownID = 0, -- used to track state of drop down menu
	SetSKInProgress = false; -- true when SK position is being set
};
-- local blacklist = {}; -- map of names for which SyncPushRead's are blocked (due to addon version or malformed messages)
SKC.Timers = {
	Sync = {-- ticker that requests sync each iteration until over or cancelled
		INIT_DELAY = 15, -- seconds of delay upon login before ticker starts
		TIME_STEP = 1, -- number of seconds between each tick
		SYNC_TIMEOUT_TICKS = 60, -- number of ticks before an initiated sync will timeout
		Ticker = nil,
		SyncTicks = {}, -- number of ticks elapsed since sync started
	}, 
	Loot = { -- current loot timer
		Ticker = nil,
		Ticks = 0,
		ElapsedTime = 0,
	}, 
};
SKC.CSVGUI = {}; -- table of CSV frame objects
-- initialize all sync state variables
for _,db in ipairs(SKC.DB_SYNC_ORDER) do
	SKC.ReadStatus[db] = false;
	SKC.SendStatus[db] = 1.0;
	SKC.SyncPartner[db] = nil;
	SKC.Timers.Sync.SyncTicks[db] = 0;
	SKC.SyncCandidate[db] = {};
	SKC.SyncCandidate[db].name = UnitName("player");
	SKC.SyncCandidate[db].edit_ts = 0;
end
--------------------------------
-- DB INIT
--------------------------------------
SKC.DB_DEFAULT = {
	global = {
		localGL = {} -- map of guild name to boolean to note if player has a character which is guild leader
	},
    char = {
		INIT_SETUP = true,
		ADDON_VERSION = GetAddOnMetadata("SKC","Version"),
		GLP = nil, -- GuildLeaderProtected
		LOP = nil, -- LootOfficersProtected
		GD = nil, -- GuildData
		MSK = nil, -- SK_List
		TSK = nil, -- SK_List
		LP = nil, --LootPrio
		LM = nil, -- LootManager
		FS = { -- filter states
			DPS = true,
			Healer = true,
			Tank = true,
			Main = true,
			Alt = true,
			Live = false,
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
		LoggingActive = SKC.DEV.LOG_ACTIVE_OVRD, -- latches true when SKC is activated (controls LOG)
		LOG = {}, -- data logging
    },
};