local _, core = ...; -- Namespace
local not_gl_error_msg = "You must be Guild Leader to do that";
local not_ml_error_msg = "You must be Master Looter to do that";
--------------------------------------
-- Custom Slash Command
--------------------------------------
core.commands = {
  ["help"] = function()
    local title_color = "1affb2";
    local help_color = "ffcc00";
    print(" ");
    core.SKC_Main:Print("NORMAL","|cff"..title_color.."Slash Commands:|r");
    -- all members
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc help|r - Lists all available slash commands");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc|r - Toggles GUI");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc ver|r - Shows addon version");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc at|r - Displays the current Activity Threshold in days");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc lp|r - Displays the number of items in the Loot Prio database");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc lp <item link/name>|r - Displays Loot Prio for given item");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc b show|r - Displays the Bench");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc ai show|r - Displays Active Instances");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc lo show|r - Displays Loot Officers");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc export log|r - Export (CSV) sk log for most recent raid");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc export sk|r - Export (CSV) current sk lists");
    core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc reset|r - Resets local SKC data");
    if core.SKC_Main:isML() then
      core.SKC_Main:Print("NORMAL","|cff"..title_color.."Master Looter Only:|r");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc b add <character name>|r - Adds character to the Bench");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc b remove <character name>|r - Removes character from the Bench");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc b clear|r - Clears the Bench");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc enable|r - Enables loot distribution with SKC");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc disable|r - Disables loot distribution with SKC");
    end
    if core.SKC_Main:isGL() then
      core.SKC_Main:Print("NORMAL","|cff"..title_color.."Guild Leader Only:|r");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc at <#>|r - Sets Activity Threshold to # days");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc lp init|r - Initialze Loot Prio with a CSV");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc <msk/tsk> init|r - Initialze SK List with a CSV");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc ai add <acro>|r - Adds instance to Active Instances");      
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc ai remove <acro>|r - Removes instance from Active Instances");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc ai clear|r - Clears Active Instances");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc lo add <name>|r - Adds name to Loot Officers");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc lo remove <name>|r - Removes name from Loot Officers");
      core.SKC_Main:Print("NORMAL","|cff"..help_color.."/skc lo clear|r - Clears Loot Officers");
    end
		print(" ");
  end,
  ["ver"] = function()
    core.SKC_Main:PrintVersion(); 
  end,
  ["lp"] = function(...)
    local itemName = nil;
    for idx,arg in ipairs({...}) do
      if idx == 1 then
        itemName = arg;
      else
        itemName = itemName.." "..arg;
      end
    end
    -- check if want to init
    if itemName == "init" then
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      -- Initializes the loot prio with a CSV pasted into a window
      core.SKC_Main:CSVImport("Loot Priority Import"); 
      return;
    end

    if SKC_DB == nil SKC_DB.LootPrio == nil then
      SKC_Main:Print("ERROR","LootPrio does not exist");
      return;
    end

    if itemName == nil then
      -- print item count
      SKC_DB.LootPrio:PrintPrio(itemName);
    elseif string.sub(itemName,1,1) == "|" then
      local item = Item:CreateFromItemLink(itemName)
      item:ContinueOnItemLoad(function()
        SKC_DB.LootPrio:PrintPrio(item:GetItemName(),itemName);
      end)
    else
      -- call directly with itemName
      SKC_DB.LootPrio:PrintPrio(itemName);
    end
    return;
  end,
  ["export"] = {
    ["log"] = function() 
      -- opens UI to export log
      core.SKC_Main:ExportLog(); 
    end,
    ["sk"] = function() 
      -- opens UI to export log
      core.SKC_Main:ExportSK(); 
    end,
  },
  ["reset"] = function() 
    -- resets and re-syncs data
    core.SKC_Main:ResetData();
  end,
  ["b"] = {
    ["show"] = function()
      core.SKC_Main:SimpleListShow("Bench");
    end,
    ["add"] = function(element)
      if not core.SKC_Main:isML() then
        core.SKC_Main:Print("ERROR",not_ml_error_msg); 
        return;
      end
      core.SKC_Main:SimpleListAdd("Bench",element);
    end,
    ["remove"] = function(element)
      if not core.SKC_Main:isML() then
        core.SKC_Main:Print("ERROR",not_ml_error_msg); 
        return;
      end
      core.SKC_Main:SimpleListRemove("Bench",element);
    end,
    ["clear"] = function()
      if not core.SKC_Main:isML() then
        core.SKC_Main:Print("ERROR",not_ml_error_msg); 
        return;
      end
      core.SKC_Main:SimpleListClear("Bench");
    end,
  },
  ["ai"] = {
    ["show"] = function()
      core.SKC_Main:SimpleListShow("ActiveRaids");
    end,
    ["add"] = function(element)
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      core.SKC_Main:SimpleListAdd("ActiveRaids",element);
    end,
    ["remove"] = function(element)
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      core.SKC_Main:SimpleListRemove("ActiveRaids",element);
    end,
    ["clear"] = function()
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      core.SKC_Main:SimpleListClear("ActiveRaids");
    end,
  },
  ["lo"] = {
    ["show"] = function()
      core.SKC_Main:SimpleListShow("LootOfficers");
    end,
    ["add"] = function(element)
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      core.SKC_Main:SimpleListAdd("LootOfficers",element);
    end,
    ["remove"] = function(element)
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      core.SKC_Main:SimpleListRemove("LootOfficers",element);
    end,
    ["clear"] = function()
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      core.SKC_Main:SimpleListClear("LootOfficers");
    end,
  },
  ["enable"] = function()
    if not core.SKC_Main:isML() then
      core.SKC_Main:Print("ERROR",not_ml_error_msg); 
      return;
    end
    core.SKC_Main:Enable(true);
  end,
  ["disable"] = function()
    if not core.SKC_Main:isML() then
      core.SKC_Main:Print("ERROR",not_ml_error_msg); 
      return;
    end
    core.SKC_Main:Enable(false);
  end,
  ["at"] = function(new_thresh)
    new_thresh = tonumber(new_thresh);
    if new_thresh == nil then
      core.SKC_Main:Print("NORMAL","Activity threshold is "..SKC_DB.GuildData:GetActivityThreshold().." days")
      return;
    end
    if not core.SKC_Main:isGL() then
      core.SKC_Main:Print("ERROR",not_gl_error_msg);
      return;
    end
    if new_thresh <= 90 then
      SKC_DB.GuildData:SetActivityThreshold(new_thresh);
      core.SKC_Main:Print("NORMAL","Activity threshold set to "..new_thresh.." days")
    else
      core.SKC_Main:Print("ERROR","Must input a number less than 90 days")
    end
    return;
  end,
  ["msk"] = {
    ["init"] = function()
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      -- Initializes the specified SK list with a CSV pasted into a window
      core.SKC_Main:CSVImport("SK List Import","MSK");
    end,
  },
  ["tsk"] = {
    ["init"] = function()
      if not core.SKC_Main:isGL() then
        core.SKC_Main:Print("ERROR",not_gl_error_msg);
        return;
      end
      -- Initializes the specified SK list with a CSV pasted into a window
      core.SKC_Main:CSVImport("SK List Import","TSK");
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