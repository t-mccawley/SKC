--------------------------------------
-- SLASH COMMANDS
--------------------------------------
--------------------------------------
-- LOCAL CONSTANTS
--------------------------------------
local not_gl_error_msg = "You must be Guild Leader to do that";
local not_ml_error_msg = "You must be Master Looter to do that";
local not_valid_slash_msg = "That is not a valid slash command";
local too_many_inpts_msg = "Too many inputs";
--------------------------------------
-- FUNCTIONS
--------------------------------------
function SKC:SlashHandler(args)
    arg1, arg2, arg3 = self:GetArgs(args,1);
    if arg1 == "ver" then
        self:PrintVersion();
    else
        self:PrintHelp();
    end
    return;
end

function SKC:PrintHelp()
    -- prints help for slash commands
    print(" ");
    print("|cff"..self.THEME.PRINT.TITLE.hex.."SKC Slash Commands:|r");
    -- all members
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc help|r - Lists all available slash commands");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc|r - Toggles GUI");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ver|r - Shows addon version");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lp|r - Displays the number of items in the Loot Prio database");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lp <item link/name>|r - Displays Loot Prio for given item");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b|r - Displays the Bench");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai|r - Displays Active Instances");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo|r - Displays Loot Officers");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc at|r - Displays the current Activity Threshold in days");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export sk|r - Export (CSV) current sk lists");
    print("|cff"..self.THEME.PRINT.HELP.hex.."/skc reset|r - Resets local SKC data");
    if self:isML() then
        print("|cff"..self.THEME.PRINT.TITLE.hex.."Master Looter Only:|r");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b add <character name>|r - Adds character to the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b remove <character name>|r - Removes character from the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc b clear|r - Clears the Bench");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc enable|r - Enables loot distribution with SKC");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc disable|r - Disables loot distribution with SKC");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc export log|r - Export (CSV) loot log for most recent raid");
    end
    if self:isGL() then
        print("|cff"..self.THEME.PRINT.TITLE.hex.."Guild Leader Only:|r");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc at <#>|r - Sets Activity Threshold to # days");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lp init|r - Initialze Loot Prio with a CSV");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc <msk/tsk> init|r - Initialze SK List with a CSV");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai add <acro>|r - Adds instance to Active Instances");      
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai remove <acro>|r - Removes instance from Active Instances");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc ai clear|r - Clears Active Instances");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo add <name>|r - Adds name to Loot Officers");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo remove <name>|r - Removes name from Loot Officers");
        print("|cff"..self.THEME.PRINT.HELP.hex.."/skc lo clear|r - Clears Loot Officers");
    end
    print(" ");
end

function SKC:PrintVersion()
    if self.db.char.ADDON_VERSION ~= nil then
        self:Print(self.db.char.ADDON_VERSION);
    else
        self:Error("Addon version missing");
    end
    return;
end
    

-- SKC.commands = {
    
--     ["lp"] = function(...)
--     local itemName = nil;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         itemName = arg;
--         else
--         itemName = itemName.." "..arg;
--         end
--     end
--     -- check if want to init
--     if itemName == "init" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--         end
--         -- Initializes the loot prio with a CSV pasted into a window
--         core.SKC_Main:CSVImport("Loot Priority Import"); 
--         return;
--     end

--     if SKC_DB == nil or SKC_DB.LootPrio == nil then
--         SKC_Main:Print("ERROR","LootPrio does not exist");
--         return;
--     end

--     if itemName == nil then
--         -- print item count
--         SKC_DB.LootPrio:PrintPrio(itemName);
--     elseif string.sub(itemName,1,1) == "|" then
--         local item = Item:CreateFromItemLink(itemName)
--         item:ContinueOnItemLoad(function()
--         SKC_DB.LootPrio:PrintPrio(item:GetItemName(),itemName);
--         end)
--     else
--         -- call directly with itemName
--         SKC_DB.LootPrio:PrintPrio(itemName);
--     end
--     return;
--     end,
--     ["export"] = function(inpt)
--     if inpt == "log" then
--         -- opens UI to export log
--         core.SKC_Main:ExportLog(); 
--     elseif inpt == "sk" then
--         -- opens UI to export log
--         core.SKC_Main:ExportSK(); 
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     end,
--     ["reset"] = function() 
--     -- resets and re-syncs data
--     core.SKC_Main:ResetData();
--     end,
--     ["b"] = function(...)
--     -- parse input
--     local cmd, element;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         cmd = arg;
--         elseif idx == 2 then
--         element = arg;
--         else
--         core.SKC_Main:Print("ERROR",too_many_inpts_msg); 
--         return;
--         end
--     end
--     -- perform command
--     if cmd == nil then
--         core.SKC_Main:SimpleListShow("Bench");
--     elseif cmd == "add" then
--         if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListAdd("Bench",element);
--     elseif cmd == "remove" then
--         if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListRemove("Bench",element);
--     elseif cmd == "clear" then
--         if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListClear("Bench");
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     return;
--     end,
--     ["ai"] = function(...)
--     -- parse input
--     local cmd, element;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         cmd = arg;
--         elseif idx == 2 then
--         element = arg;
--         else
--         core.SKC_Main:Print("ERROR",too_many_inpts_msg); 
--         return;
--         end
--     end
--     -- perform command
--     if cmd == nil then
--         core.SKC_Main:SimpleListShow("ActiveRaids");
--     elseif cmd == "add" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListAdd("ActiveRaids",element);
--     elseif cmd == "remove" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListRemove("ActiveRaids",element);
--     elseif cmd == "clear" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListClear("ActiveRaids");
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     return;
--     end,
--     ["lo"] = function(...)
--     -- parse input
--     local cmd, element;
--     for idx,arg in ipairs({...}) do
--         if idx == 1 then
--         cmd = arg;
--         elseif idx == 2 then
--         element = arg;
--         else
--         core.SKC_Main:Print("ERROR",too_many_inpts_msg); 
--         return;
--         end
--     end
--     -- perform command
--     if cmd == nil then
--         core.SKC_Main:SimpleListShow("LootOfficers");
--     elseif cmd == "add" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListAdd("LootOfficers",element);
--     elseif cmd == "remove" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListRemove("LootOfficers",element);
--     elseif cmd == "clear" then
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg); 
--         return;
--         end
--         core.SKC_Main:SimpleListClear("LootOfficers");
--     else
--         core.SKC_Main:Print("ERROR",not_valid_slash_msg);
--     end
--     return;
--     end,
--     ["enable"] = function()
--     if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--     end
--     core.SKC_Main:Enable(true);
--     end,
--     ["disable"] = function()
--     if not (core.SKC_Main:isML() and core.SKC_Main:isLO()) then
--         core.SKC_Main:Print("ERROR",not_ml_error_msg); 
--         return;
--     end
--     core.SKC_Main:Enable(false);
--     end,
--     ["at"] = function(new_thresh)
--     new_thresh = tonumber(new_thresh);
--     if new_thresh == nil then
--         core.SKC_Main:Print("NORMAL","Activity threshold is "..SKC_DB.GLP:GetActivityThreshold().." days")
--         return;
--     end
--     if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--     end
--     if new_thresh <= 90 then
--         SKC_DB.GLP:SetActivityThreshold(new_thresh);
--         core.SKC_Main:Print("NORMAL","Activity threshold set to "..new_thresh.." days")
--     else
--         core.SKC_Main:Print("ERROR","Must input a number less than 90 days")
--     end
--     return;
--     end,
--     ["msk"] = {
--     ["init"] = function()
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--         end
--         -- Initializes the specified SK list with a CSV pasted into a window
--         core.SKC_Main:CSVImport("SK List Import","MSK");
--     end,
--     },
--     ["tsk"] = {
--     ["init"] = function()
--         if not core.SKC_Main:isGL() then
--         core.SKC_Main:Print("ERROR",not_gl_error_msg);
--         return;
--         end
--         -- Initializes the specified SK list with a CSV pasted into a window
--         core.SKC_Main:CSVImport("SK List Import","TSK");
--     end,
--     },
-- };

-- local function HandleSlashCommands(str)
--     if (#str == 0) then
--     core.SKC_Main:ToggleUIMain(false);
--     else
--     -- split out args in string
--     local args = {};
--     for _, arg in ipairs({ string.split(' ', str) }) do
--         if (#arg > 0) then
--         table.insert(args, arg);
--         end
--     end

--     local path = core.commands; -- required for updating found table.
    
--     for id, arg in ipairs(args) do
--         if (#arg > 0) then -- if string length is greater than 0.
--         arg = arg:lower();			
--         if (path[arg]) then
--             if (type(path[arg]) == "function") then				
--             -- pass remaining args to function
--             path[arg](select(id + 1, unpack(args))); 
--             return;					
--             elseif (type(path[arg]) == "table") then				
--             path = path[arg]; -- another sub-table found!
--             end
--         else
--             -- does not exist!
--             core.commands.help();
--             return;
--         end
--         end
--     end

--     end
--     return
-- end
