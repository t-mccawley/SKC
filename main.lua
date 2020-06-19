--------------------------------------
-- Namespaces
--------------------------------------
local _, core = ...; -- returns name of addon and namespace (core)
core.SKC_Main = {}; -- adds SKC_Main table to addon namespace

local SKC_Main = core.SKC_Main; -- assignment by reference in lua, ugh
SKC_Main.VarsLoaded = false;
SKC_Main.FilterStates = {
	SK1 = {
		DPS = true,
		Healer = true,
		Tank = true,
		Druid = true,
		Hunter = true,
		Mage = true,
		Paladin = true,
		Priest = true;
		Rogue = true,
		Shaman = true,
		Warlock = true,
		Warrior = true,
	},
};
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
	MAIN_WIDTH = 820,
	MAIN_HEIGHT = 470,
	SK_TAB_TOP_OFFST = -60,
	SK_TAB_TITLE_CARD_WIDTH = 80,
	SK_TAB_TITLE_CARD_HEIGHT = 40,
	SK_FILTER_WIDTH = 260,
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

function SK_Node:new(sk_node,above,below)
	if sk_node == nil then
		-- initalize fresh
		local obj = {};
		setmetatable(obj,SK_Node);
		obj.above = above or nil;
		obj.below = below or nil;
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
}
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
	local list_out = {};
	local idx = 0;
	local current_name = self.top;
	-- check data integrity
	local bot_name = self.bottom;
	if self.list[bot_name].below ~= nil then
		DEFAULT_CHAT_FRAME:AddMessage("SKC: Your database is fucked.")
		return list_out;
	end
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

function CharacterData:new(character_data,name,class)
	if character_data == nil then
		-- initalize fresh
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
-- SKC_Main functions
--------------------------------------
function SKC_Main:AddonLoad()
	SKC_Main.AddonLoaded = true;
	-- Initialize 
	if SKC_DB == nil then 
		SKC_DB = {};
	end
	if SKC_DB.SK_Lists == nil then 
		SKC_DB.SK_Lists = {};
	end
	-- Initialize or refresh metatables
	SKC_DB.SK_Lists["SK1"] = SK_List:new(SKC_DB.SK_Lists["SK1"]);
	SKC_DB.GuildData = GuildData:new(SKC_DB.GuildData);
end

function SKC_Main:FetchGuildInfo()
	SKC_DB.InGuild = IsInGuild();
	if not SKC_DB.InGuild then
		DEFAULT_CHAT_FRAME:AddMessage("SKC Error: You are not in a guild!");
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
			local name,_ = strsplit("-",full_name,2);
			if SKC_DB.GuildData[name] == nil then
				-- new player, add to DB and SK list
				SKC_DB.GuildData:Add(name,class);
				SKC_DB.SK_Lists["SK1"]:PushBack(name);
				-- local above = SKC_DB.SK_Lists["SK1"].list[name].above;
				-- local below = SKC_DB.SK_Lists["SK1"].list[name].below;
				-- DEFAULT_CHAT_FRAME:AddMessage("SKC: ["..cnt.."] "..name.." added to database!");
				-- if above == nil then
				-- 	DEFAULT_CHAT_FRAME:AddMessage("    TOP!")
				-- else
				-- 	DEFAULT_CHAT_FRAME:AddMessage("    Below: "..above);
				-- end
				-- if below == nil then
				-- 	DEFAULT_CHAT_FRAME:AddMessage("    BOTTOM!")
				-- else
				-- 	DEFAULT_CHAT_FRAME:AddMessage("    Above: "..below);
				-- end
			end
		end
	end
	SKC_DB.Count60 = cnt;
end

local function SK_Card_MouseDown(self, button)
	if button=='LeftButton' and self.Text:GetText() ~= nill then 
		local data = SKC_DB.GuildData[self.Text:GetText()];
		SKC_UIMain["Details_border"]["Name"].Text:SetText(data.name);
		SKC_UIMain["Details_border"]["Class"].Text:SetText(data.class);
		SKC_UIMain["Details_border"]["Raid Role"].Text:SetText(data.raid_role);
		SKC_UIMain["Details_border"]["Guild Role"].Text:SetText(data.guild_role);
		SKC_UIMain["Details_border"]["Status"].Text:SetText(data.status);
		SKC_UIMain["Details_border"]["Activity"].Text:SetText(data.activity);
	end
end

local function FilterClickFunction(self, button)
	SKC_Main.FilterStates["SK1"][self.text:GetText()] = self:GetChecked();
	SKC_Main:UpdateSK("SK1");
	return;
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
		-- only add cards to list which are not being filtered
		if SKC_Main.FilterStates["SK1"][class_tmp] and SKC_Main.FilterStates["SK1"][raid_role_tmp] then
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
end

function SKC_Main:Toggle()
	local menu = SKC_UIMain or SKC_Main:CreateMenu();
	menu:SetShown(not menu:IsShown());
end

function SKC_Main:GetThemeColor()
	local c = DEFAULTS.THEME;
	return c.r, c.g, c.b, c.hex;
end

-- function SKC_Main:CreateButton(point, relativeFrame, relativePoint, yOffset, text)
-- 	local btn = CreateFrame("Button", nil, SKC_UIMain.ScrollFrame, "GameMenuButtonTemplate");
-- 	btn:SetPoint(point, relativeFrame, relativePoint, 0, yOffset);
-- 	btn:SetSize(140, 40);
-- 	btn:SetText(text);
-- 	btn:SetNormalFontObject("GameFontNormalLarge");
-- 	btn:SetHighlightFontObject("GameFontHighlightLarge");
-- 	return btn;
-- end

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
	local filter_roles = {"DPS","Healer","Tank","Druid","Hunter","Mage","Paladin","Priest","Rogue","Shaman","Warlock","Warrior"};
	for idx,value in ipairs(filter_roles) do
		local row = math.floor((idx - 1) / 3); -- zero based
		local col = (idx - 1) % 3; -- zero based
		SKC_UIMain[filter_border_key][value] = CreateFrame("CheckButton", nil, SKC_UIMain[filter_border_key], "UICheckButtonTemplate");
		SKC_UIMain[filter_border_key][value]:SetChecked(SKC_Main.FilterStates["SK1"][value]);
		SKC_UIMain[filter_border_key][value]:SetScript("OnClick",FilterClickFunction)
		SKC_UIMain[filter_border_key][value]:SetPoint("TOPLEFT", SKC_UIMain[filter_border_key], "TOPLEFT", 15 + 75*col , -15 + -30*row);
		SKC_UIMain[filter_border_key][value].text:SetFontObject("GameFontNormalSmall");
		SKC_UIMain[filter_border_key][value].text:SetText(value);
		if idx > 3 then
			-- assign class colors
			SKC_UIMain[filter_border_key][value].text:SetTextColor(DEFAULTS.CLASS_COLORS[value].r,DEFAULTS.CLASS_COLORS[value].g,DEFAULTS.CLASS_COLORS[value].b,1.0);
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
	SKC_UIMain[sk_list].SK_List_SF:SetScript("OnMouseWheel",ScrollFrame_OnMouseWheel);
	SKC_UIMain[sk_list].SK_List_SF.ScrollBar:SetPoint("TOPLEFT",SKC_UIMain[sk_list].SK_List_SF,"TOPRIGHT",-22,-21);

	-- Create scroll child
	local scroll_child = CreateFrame("Frame",nil,SKC_UIMain[sk_list].SK_List_SF);
	local scroll_max = DEFAULTS.SK_CARD_SPACING + (SKC_DB.Count60 + 1)*(DEFAULTS.SK_CARD_HEIGHT + DEFAULTS.SK_CARD_SPACING)
	scroll_child:SetSize(DEFAULTS.SK_LIST_WIDTH,scroll_max);
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
		SKC_UIMain[sk_list].NameFrame[idx]:SetScript("OnMouseDown",SK_Card_MouseDown);
	end

	-- Update SK cards
	SKC_Main:UpdateSK("SK1")

	-- Create details panel
	local details_border_key = SKC_Main:CreateUIBorder("Details",DEFAULTS.SK_DETAILS_WIDTH,DEFAULTS.SK_DETAILS_HEIGHT,250,DEFAULTS.SK_TAB_TOP_OFFST);
	-- create details fields
	local details_fields = {"Name","Class","Raid Role","Guild Role","Status","Activity","Loot History"};
	for idx,value in ipairs(details_fields) do
		SKC_UIMain[details_border_key][value] = SKC_UIMain[details_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_border_key][value]:SetFontObject("GameFontNormal");
		SKC_UIMain[details_border_key][value]:SetPoint("RIGHT",SKC_UIMain[details_border_key],"TOPLEFT",100,-20*idx-10);
		SKC_UIMain[details_border_key][value]:SetText(value..":");
		SKC_UIMain[details_border_key][value].Text = SKC_UIMain[details_border_key]:CreateFontString(nil,"ARTWORK");
		SKC_UIMain[details_border_key][value].Text:SetFontObject("GameFontHighlight");
		SKC_UIMain[details_border_key][value].Text:SetPoint("LEFT",SKC_UIMain[details_border_key][value],"RIGHT",5,0);
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
events:SetScript("OnEvent", SKC_Main.AddonLoad);