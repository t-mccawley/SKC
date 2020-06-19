--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...; -- returns name of addon and namespace (core)
core.Main = {}; -- adds Main table to addon namespace

local Main = core.Main; -- assignment by reference in lua, ugh
Main.VarsLoaded = false;
local SKC_UIMain;

--------------------------------------
-- DEFAULTS (usually a database!)
--------------------------------------
local DEFAULTS = {
	THEME = {
		r = 0, 
		g = 0.8, -- 204/255
		b = 1,
		hex = "00ccff"
	},
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
	MAIN_WIDTH = 800,
	MAIN_HEIGHT = 450,
	SK_TAB_TOP_OFFST = -60,
	SK_TAB_TITLE_CARD_WIDTH = 80,
	SK_TAB_TITLE_CARD_HEIGHT = 40,
	SK_FILTER_WIDTH = 250,
	SK_FILTER_HEIGHT = 150,
	SK_LIST_WIDTH = 175,
	SK_LIST_HEIGHT = 325,
	SK_LIST_BORDER_OFFST = 15,
	SK_DETAILS_WIDTH = 250,
	SK_DETAILS_HEIGHT = 355,
	SK_CARD_SPACING = 6,
	SK_CARD_WIDTH = 100,
	SK_CARD_HEIGHT = 20,
}

--------------------------------------
-- Classes
--------------------------------------
-- SK_Node class
SK_Node = {
	above = nil, --player name above this player in ths SK list
	below = nil, --player name below this player in the SK list
}
SK_Node.__index = SK_Node;

function SK_Node:new(above,below)
   local obj = {};
   setmetatable(obj,SK_Node);
   obj.above = above or nil;
   obj.below = below or nil;
   return obj;
end

-- SK_List class
SK_List = { --a doubly linked list table where each node is referenced by player name. Each node is a SK_Node:
	top = nil, -- top node in list
	bottom = nil, -- bottom node in list
	list = {}, -- list of nodes
}
SK_List.__index = SK_List;

function SK_List:new()
   local obj = {};
   setmetatable(obj,SK_List);
   obj.top = nil; 
   obj.bottom = nil; 
   obj.list = {}; 
   return obj;
end

function SK_List:PushBack(name)
	-- Push item to back of list (instantiate if doesnt exist)
	if self.top == nil then
		-- First node in list
		self.top = name;
		self.bottom = name;
		self.list[name] = SK_Node:new(name,nil);
	else
		-- list already exists
		if self.list[name] == nil then
			-- name does not exist yet, create node
			self.list[name] = SK_Node:new(nil,nil);
		end
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
	local list_out = {};
	local idx = 0;
	local current_name = self.top;
	while (current_name ~= nil) do
		list_out[idx] = current_name;
		current_name = self.list[current_name].below;
		idx = idx + 1;
	end
	return list_out;
end

function SK_List:FullSK(name)
	-- check if name is in SK list
	if (self.list[name] == nil) or (#self.list == 0) or (self.list[name] == self.bottom) then
		-- name is not in SK list
		-- OR list is empty
		-- OR name is already the bottom of list
		-- do nothing
		return;
	end
	-- make current above name point to below name and vice versa
	local above_tmp = self.list[name].above;
	local below_tmp = self.list[name].below;
	self.list[above_tmp].below = below_tmp;
	self.list[below_tmp].above = above_tmp;
	-- push to bottom
	self.list:PushBack(name);
	return;
end

-- CharacterData class
CharacterData = {
	name = nil, -- character name
	class = nil, -- character class
	raid_role = nil, --DPS, Healer, or Tank
	guild_role = nil, --Disenchanter, Guild Banker, or None
	status = nil, -- Main or Alt
	activity = nil, -- Active or Inactive
	loot_history = {}, -- Table that maps timestamp to table with item (Rejuvenating Gem) and distribution method (SK1, Roll, DE, etc)
}
CharacterData.__index = CharacterData;

function CharacterData:new(name,class)
	local obj = {};
	setmetatable(obj,CharacterData);
	obj.name = name or nil;
	obj.class = class or nil;
	obj.raid_role = "DPS";
	obj.guild_role = nil;
	obj.status = "Main";
	obj.activity = "Active";
	obj.loot_history = {};
	return obj;
 end

-- GuildData class
GuildData = {} --a hash table that maps character name to CharacterData
GuildData.__index = GuildData;

function GuildData:new()
   local obj = {};
   setmetatable(obj,GuildData);
   return obj;
end

function GuildData:length()
	local count = 0;
	for _ in pairs(self) do count = count + 1 end
	return count;
end

function GuildData:Add(name,class)
	self[name] = CharacterData:new(name,class);
	return;
end

--------------------------------------
-- Main functions
--------------------------------------
function Main:FetchGuildInfo()
	SKC_DB.InGuild = IsInGuild();
	SKC_DB.NumGuildMembers = GetNumGuildMembers()
	-- Determine # of level 60s
	local cnt = 0;
	for idx = 1, SKC_DB.NumGuildMembers do
		full_name, rank, rankIndex, level, class, zone, note, 
		officernote, online, status, classFileName, 
		achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(idx);
		if level == 60 then
			cnt = cnt + 1;
		end
	end
	SKC_DB.Count60 = cnt;
end

function Main:AddonLoad()
	Main.AddonLoaded = true;
	if (SKC_DB == nil or #SKC_DB == 0) then
		SKC_DB = {}
		SKC_DB.GuildData = GuildData:new();
		SKC_DB.SK_Lists = {};
		SKC_DB.SK_Lists.SK1 = SK_List:new();
	end
end

local function SK_Card_MouseDown(self, button)
	if button=='LeftButton' then 
		local data = SKC_DB.GuildData[self.Text:GetText()];
		SKC_UIMain.Details["Name"].Text:SetText(data.name);
		SKC_UIMain.Details["Class"].Text:SetText(data.class);
		SKC_UIMain.Details["Raid Role"].Text:SetText(data.raid_role);
		SKC_UIMain.Details["Guild Role"].Text:SetText(data.guild_role);
		SKC_UIMain.Details["Status"].Text:SetText(data.status);
		SKC_UIMain.Details["Activity"].Text:SetText(data.activity);
	end
end

function Main:PopulateSK_Cards()
	-- Addon not yet loaded, return
	if not Main.AddonLoaded then return end

	-- Check if character is in guild
	if SKC_DB.InGuild then
		for idx = 1, SKC_DB.NumGuildMembers do
			full_name, rank, rankIndex, level, class, zone, note, 
			officernote, online, status, classFileName, 
			achievementPoints, achievementRank, isMobile, isSoREligible, standingID = GetGuildRosterInfo(idx);
			if level == 60 then
				-- add to GuildData
				local name,_ = strsplit("-",full_name,2);
				SKC_DB.GuildData:Add(name,class);
				SKC_DB.SK_Lists.SK1:PushBack(name);
			end
		end
		DEFAULT_CHAT_FRAME:AddMessage("SKC: Initialized from guild roster!");
	else
		DEFAULT_CHAT_FRAME:AddMessage("SKC Error: You are not in a guild!");
		return;
	end
	-- Create SK cards
	local print_order = SKC_DB.SK_Lists.SK1:ReturnList();
	for key,value in ipairs(print_order) do
		-- Create order frame
		SKC_UIMain.SK_List.Order = CreateFrame("Frame",nil,SKC_UIMain.SK_List.SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain.SK_List.Order:SetSize(30,DEFAULTS.SK_CARD_HEIGHT);
		SKC_UIMain.SK_List.Order:SetPoint("TOPLEFT",SKC_UIMain.SK_List.SK_List_SF:GetScrollChild(),"TOPLEFT",8,-1*((key-1)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING) + DEFAULTS.SK_CARD_SPACING));
		SKC_UIMain.SK_List.Order.Text = SKC_UIMain.SK_List.Order:CreateFontString(nil,"ARTWORK")
		SKC_UIMain.SK_List.Order.Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain.SK_List.Order.Text:SetPoint("CENTER",0,0)
		SKC_UIMain.SK_List.Order.Text:SetText(key)

		-- Create named card
		local card_name = value.."_Card";
		local class_tmp = SKC_DB.GuildData[value].class;
		
		SKC_UIMain.SK_List[card_name] = CreateFrame("Frame",nil,SKC_UIMain.SK_List.SK_List_SF,"InsetFrameTemplate");
		SKC_UIMain.SK_List[card_name]:SetSize(DEFAULTS.SK_CARD_WIDTH,DEFAULTS.SK_CARD_HEIGHT);
		SKC_UIMain.SK_List[card_name]:SetPoint("TOPLEFT",SKC_UIMain.SK_List.SK_List_SF:GetScrollChild(),"TOPLEFT",43,-1*((key-1)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING) + DEFAULTS.SK_CARD_SPACING));
		SKC_UIMain.SK_List[card_name].Text = SKC_UIMain.SK_List[card_name]:CreateFontString(nil,"ARTWORK")
		SKC_UIMain.SK_List[card_name].Text:SetFontObject("GameFontHighlightSmall")
		SKC_UIMain.SK_List[card_name].Text:SetPoint("CENTER",0,0)
		SKC_UIMain.SK_List[card_name].Text:SetText(value)
		-- create class color background
		SKC_UIMain.SK_List[card_name].bg = SKC_UIMain.SK_List[card_name]:CreateTexture(nil,"BACKGROUND");
		SKC_UIMain.SK_List[card_name].bg:SetAllPoints(true);
		SKC_UIMain.SK_List[card_name].bg:SetColorTexture(DEFAULTS.CLASS_COLORS[class_tmp].r,DEFAULTS.CLASS_COLORS[class_tmp].g,DEFAULTS.CLASS_COLORS[class_tmp].b,0.25);
		-- Bind function for click event
		SKC_UIMain.SK_List[card_name]:SetScript("OnMouseDown",SK_Card_MouseDown);
	end
end

function Main:Toggle()
	local menu = SKC_UIMain or Main:CreateMenu();
	menu:SetShown(not menu:IsShown());
end

function Main:GetThemeColor()
	local c = DEFAULTS.THEME;
	return c.r, c.g, c.b, c.hex;
end

function Main:CreateButton(point, relativeFrame, relativePoint, yOffset, text)
	local btn = CreateFrame("Button", nil, SKC_UIMain.ScrollFrame, "GameMenuButtonTemplate");
	btn:SetPoint(point, relativeFrame, relativePoint, 0, yOffset);
	btn:SetSize(140, 40);
	btn:SetText(text);
	btn:SetNormalFontObject("GameFontNormalLarge");
	btn:SetHighlightFontObject("GameFontHighlightLarge");
	return btn;
end

local function ScrollFrame_OnMouseWheel(self,delta)
    -- delta: 1 scroll up, -1 scroll down
	-- value at top is 0, value at bottom is size of child
	-- scroll so that one wheel is 3 SK cards
	local scroll_range = self:GetVerticalScrollRange();
	local inc = 3 * (DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING)
    local newValue = math.min( scroll_range , math.max( 0 , self:GetVerticalScroll() - (inc*delta) ) );
    self:SetVerticalScroll(newValue);
    return
end

local function ScrollFrame_OnVerticalScroll(self,scroll)
    self:SetVerticalScroll(scroll);
    return
end

function Main:CreateUIBorder(title,width,height,x_pos,y_pos)
	-- Create Border
	local border_key = title;
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
end

function Main:CreateMenu()
	-- Fetch guild info into SK DB
	Main:FetchGuildInfo()

    SKC_UIMain = CreateFrame("Frame", "SKC_UIMain", UIParent, "UIPanelDialogTemplate");
	SKC_UIMain:SetSize(DEFAULTS.MAIN_WIDTH,DEFAULTS.MAIN_HEIGHT);
	SKC_UIMain:SetPoint("CENTER");
	-- SKC_UIMain:SetMovable(true)
	-- SKC_UIMain:EnableMouse(true)
	-- SKC_UIMain:RegisterForDrag("LeftButton")
	-- SKC_UIMain:SetScript("OnDragStart", SKC_UIMain.StartMoving)
	-- SKC_UIMain:SetScript("OnDragStop", SKC_UIMain.StopMovingOrSizing)
	SKC_UIMain:SetAlpha(0.8);
	
	-- Add title
    SKC_UIMain.Title:ClearAllPoints();
	SKC_UIMain.Title:SetPoint("LEFT", SKC_UIMainTitleBG, "LEFT", 6, 0);
	SKC_UIMain.Title:SetText("SKC");

	-- Create filter panel
	Main:CreateUIBorder("Filters",DEFAULTS.SK_FILTER_WIDTH,DEFAULTS.SK_FILTER_HEIGHT,-250,DEFAULTS.SK_TAB_TOP_OFFST)

	-- Create SK list panel
	SKC_UIMain.SK_List = CreateFrame("Frame","SK_List",SKC_UIMain,"InsetFrameTemplate");
	SKC_UIMain.SK_List:SetSize(DEFAULTS.SK_LIST_WIDTH,DEFAULTS.SK_LIST_HEIGHT);
	SKC_UIMain.SK_List:SetPoint("TOP",SKC_UIMain,"TOP",0,DEFAULTS.SK_TAB_TOP_OFFST - DEFAULTS.SK_LIST_BORDER_OFFST);
	Main:CreateUIBorder("SK1",DEFAULTS.SK_LIST_WIDTH + 2*DEFAULTS.SK_LIST_BORDER_OFFST,DEFAULTS.SK_LIST_HEIGHT + 2*DEFAULTS.SK_LIST_BORDER_OFFST,0,DEFAULTS.SK_TAB_TOP_OFFST)

	-- Create scroll frame on SK list
    SKC_UIMain.SK_List.SK_List_SF = CreateFrame("ScrollFrame","SK_List_SF",SKC_UIMain.SK_List,"UIPanelScrollFrameTemplate2");
    SKC_UIMain.SK_List.SK_List_SF:SetPoint("TOPLEFT",SKC_UIMain.SK_List,"TOPLEFT",0,-2);
	SKC_UIMain.SK_List.SK_List_SF:SetPoint("BOTTOMRIGHT",SKC_UIMain.SK_List,"BOTTOMRIGHT",0,2);
	SKC_UIMain.SK_List.SK_List_SF:SetClipsChildren(true);
	SKC_UIMain.SK_List.SK_List_SF:SetScript("OnMouseWheel",ScrollFrame_OnMouseWheel);
	SKC_UIMain.SK_List.SK_List_SF.ScrollBar:SetPoint("TOPLEFT",SKC_UIMain.SK_List.SK_List_SF,"TOPRIGHT",-22,-21);

	-- Create scroll child
	local scroll_child = CreateFrame("Frame",nil,SKC_UIMain.SK_List.ScrollFrame);
	local scroll_max = DEFAULTS.SK_CARD_SPACING + (SKC_DB.Count60 + 1)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING)
	scroll_child:SetSize(DEFAULTS.SK_LIST_WIDTH,scroll_max);
	SKC_UIMain.SK_List.SK_List_SF:SetScrollChild(scroll_child);

	-- Populate SK cards
	Main:PopulateSK_Cards()

	-- Create details panel
	local details_title = "Details";
	Main:CreateUIBorder(details_title,DEFAULTS.SK_DETAILS_WIDTH,DEFAULTS.SK_DETAILS_HEIGHT,250,DEFAULTS.SK_TAB_TOP_OFFST);
	-- create details fields
	local details_fields = {"Name","Class","Raid Role","Guild Role","Status","Activity","Loot History"};
	for idx,value in ipairs(details_fields) do
		SKC_UIMain[details_title][value] = SKC_UIMain[details_title]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_title][value]:SetFontObject("GameFontNormal");
		SKC_UIMain[details_title][value]:SetPoint("RIGHT",SKC_UIMain[details_title],"TOPLEFT",100,-20*idx-10);
		SKC_UIMain[details_title][value]:SetText(value..":");
		SKC_UIMain[details_title][value].Text = SKC_UIMain[details_title]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_title][value].Text:SetFontObject("GameFontHighlight");
		SKC_UIMain[details_title][value].Text:SetPoint("LEFT",SKC_UIMain[details_title][value],"RIGHT",5,0);
	end
	
	
	
	
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

-- Monitor addon loaded event
local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", Main.AddonLoad);