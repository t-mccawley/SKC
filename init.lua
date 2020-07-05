-- Tutorial: https://www.youtube.com/watch?v=nfaE7NQhMlc&list=PL3wt7cLYn4N-3D3PTTUZBM2t1exFmoA2G
-- FUNCTION
--[[
local myFunc = function() 
	local x;
	x = 3;
  return x;
end
--]]
-- CLASS
--[[
local MyClass = {
  -- index:
  1,2,3,4,
  -- hash table:
  size = 5,
}
--]]
-- FOR LOOP (NUMERIC)
--[[

for i = startValue, endValue, stepValue do
  -- code to iterate
end

--]]
-- FOR LOOP (GENERIC)
-- will iterate index part first then hash table portion
-- Will not necessarily print hash table in order
--[[

for key, value in pairs(tbl) do
  -- code to iterate
end

--]]
-- to print out just the index part, use ipairs
-- WHILE LOOP
--[[

while (true) do
end

--]]
-- DO LOOP
--[[

repeat
until (condition)

--]]
-- No switch statements, no continue statements (there is a break)
-- LAYERS
-- Layers placed in order to display graphics
-- Frame = Canvas, Layer = paint on top
-- BACKGROUND
-- BORDER
-- ARTWORK
-- OVERLAY
-- HIGHLIGHT
------------------------------------------------------------------------------------------------
local _, core = ...; -- Namespace

--------------------------------------
-- Custom Slash Command
--------------------------------------
core.commands = {
  ["help"] = function()
    local help_color = "ffcc00";
    print(" ");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."Slash Commands:|r");
    -- all members
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc help|r - shows help info");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc|r - toggles SKC GUI");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc prio <item name>|r - displays loot prio for given item");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc log|r - export skc log (CSV) for past 90 days");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc bench show|r - displays bench");
    if core.SKC_Main:isML() then
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc bench add <character name>|r - adds character to bench");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc bench clear|r - clears bench");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc enable|r - enables loot distribution with skc");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc disable|r - disables loot distribution with skc");
    end
    if core.SKC_Main:isGL() then
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc activity <#>|r - sets inactivity threshold to # days");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc init prio|r - initialze loot prio with a CSV");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc init sk <MSK/TSK>|r - initialze sk list with a CSV");
    end
		print(" ");
	end,
  ["prio"] = function(...)
    local itemName = "";
    for idx,arg in ipairs({...}) do
      if idx == 1 then
        itemName = arg;
      else
        itemName = itemName.." "..arg;
      end
    end
    SKC_DB.LootPrio:PrintPrio(itemName)
    return;
  end,
  ["log"] = function() 
    -- opens UI to export log
    core.SKC_Main:ExportLog(); 
  end,
  ["bench"] = {
    ["show"] = function()
      -- Prints the current bench
      core.SKC_Main:BenchShow();
    end,
    ["add"] = function(name)
      -- Initializes the specified SK list with a CSV pasted into a window
      core.SKC_Main:BenchAdd(name);
    end,
    ["clear"] = function()
      core.SKC_Main:BenchClear()
    end,
  },
  ["enable"] = function()
    core.SKC_Main:Enable(true);
  end,
  ["disable"] = function()
    core.SKC_Main:Enable(false);
  end,
  ["activity"] = function(new_thresh)
    new_thresh = tonumber(new_thresh);
    if new_thresh ~= nil and new_thresh <= 90 then
      SKC_DB["MSK"]:SetActivityThreshold(new_thresh);
      SKC_DB["TSK"]:SetActivityThreshold(new_thresh);
      core.SKC_Main:Print("NORMAL","Activity threshold set to "..new_thresh.." days")
    else
      core.SKC_Main:Print("ERROR","Must input a number less than 90 days")
    end
  end,
  ["init"] = {
    ["sk"] = function(sk_list)
      -- Initializes the specified SK list with a CSV pasted into a window
      core.SKC_Main:CSVImport("SK List Import",sk_list);
    end,
    ["prio"] = function()
      -- Initializes the loot prio with a CSV pasted into a window
      core.SKC_Main:CSVImport("Loot Priority Import"); 
    end,
  },
};

local function HandleSlashCommands(str)
  if (#str == 0) then
    core.SKC_Main:ToggleUIMain(false);
  else
    -- split out args in string
    local args = {};
    for _, arg in ipairs({ string.split(' ', str) }) do
      if (#arg > 0) then
        table.insert(args, arg);
      end
    end

    local path = core.commands; -- required for updating found table.
	
    for id, arg in ipairs(args) do
      if (#arg > 0) then -- if string length is greater than 0.
        arg = arg:lower();			
        if (path[arg]) then
          if (type(path[arg]) == "function") then				
            -- pass remaining args to function
            path[arg](select(id + 1, unpack(args))); 
            return;					
          elseif (type(path[arg]) == "table") then				
            path = path[arg]; -- another sub-table found!
          end
        else
          -- does not exist!
          core.commands.help();
          return;
        end
      end
    end

  end
  return
end

-- WARNING: self automatically becomes events frame!
function core:init(event, name)
	if (name ~= "SKC") then return end 

	-- allows using left and right buttons to move through chat 'edit' box
	for i = 1, NUM_CHAT_WINDOWS do
		_G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
	end
	
	----------------------------------
	-- Register Slash Commands!
	----------------------------------
	SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI
	SlashCmdList.RELOADUI = ReloadUI;

	SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
	SlashCmdList.FRAMESTK = function()
		LoadAddOn("Blizzard_DebugTools");
		FrameStackTooltip_Toggle(false);
	end

	SLASH_SKC1 = "/skc";
  SlashCmdList.SKC = HandleSlashCommands;
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.init);