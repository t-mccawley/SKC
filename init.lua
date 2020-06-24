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
		print(" ");
    core.SKC_Main:Print("NORMAL","List of slash commands:");
    core.SKC_Main:Print("NORMAL","|cff00cc66/skc help|r - shows help info");
    core.SKC_Main:Print("NORMAL","|cff00cc66/skc|r - toggles SKC GUI");
    core.SKC_Main:Print("NORMAL","|cff00cc66/skc prio itemName|r - displays loot prio for given itemName");
		print(" ");
	end,
  ["prio"] = function(...)
    SKC_DB.LootPrio:PrintPrio(...)
  end,
  ["init"] = {
    ["sk"] = function(sk_list)
      -- Initializes the specified SK list with a CSV pasted into a window
      core.SKC_Main:Print("NORMAL",sk_list);
    end,
    ["prio"] = function()
      -- Initializes the loot prio with a CSV pasted into a window
    end,
    ["guild"] = function()
      -- Initializes the guild data with a CSV pasted into a window
    end,
  },
  -- ["prio"] = {
  --   ["default"] = function(...)
  --     SKC_DB.LootPrio:PrintPrio(itemName)
  --     -- for key,value in pairs(SKC_DB.LootPrio.default.prio) do
  --     --   core.SKC_Main:Print("NORMAL",key);
  --     -- end 
  --   end,
	-- }
};

local function HandleSlashCommands(str)
  if (#str == 0) then
    core.SKC_Main:Toggle(false);
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
	
  core.SKC_Main:Print("NORMAL","Welcome back", UnitName("player").."!");
end

local events = CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:SetScript("OnEvent", core.init);

-- Register addon message prefixs
C_ChatInfo.RegisterAddonMessagePrefix(core.SKC_Main.DISTRIBUTION_CHANNEL);
C_ChatInfo.RegisterAddonMessagePrefix(core.SKC_Main.DECISION_CHANNEL);
C_ChatInfo.RegisterAddonMessagePrefix(core.SKC_Main.SYNC_CHANNEL);