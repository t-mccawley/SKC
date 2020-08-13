--------------------------------------
-- INITIALIZE
--------------------------------------
local DB_DEFAULT = {
    char = {
        ADDON_VERSION = GetAddOnMetadata("SKC", "Version"),
        GLP = nil,
    },
};

function SKC:OnInitialize()
    -- Initialize saved database
	self.db = LibStub("AceDB-3.0"):New("SKC_DB",DB_DEFAULT);
	self:Print("test")
	-- Register slash commands
	self:RegisterChatCommand("rl",ReloadUI);
	self:RegisterChatCommand("skc","SlashHandler");
	-- Register comms
	self:RegisterComm(LOGIN_SYNC_CHECK,self.LoginSyncCheckRead);
	-- LOGIN_SYNC_PUSH = "6-F?832qBmrJE?pR",
	-- LOGIN_SYNC_PUSH_RQST = "d$8B=qB4VsW&&Y^D",
	-- SYNC_PUSH = "8EtTWxyA$r6xi3=F",
	-- LOOT = "xBPE9,-Fjsc+A#rm",
	-- LOOT_DECISION = "ksg(Ak2.*/@&+`8Q",
	-- LOOT_DECISION_PRINT = "xP@&!9hQxY]1K&C4",
	-- LOOT_OUTCOME = "aP@yX9hQf}89K&C4",
	-- for _,channel in pairs(CHANNELS) do
	-- 	self:RegisterComm(channel,self.AddonMessageRead);
	-- 	-- TODO, need to make specific callback to read each channel....
	-- end
	return;
end




-- -- WARNING: self automatically becomes events frame!
-- function core:init(event, name)
--     if (name ~= "SKC") then return end 

--     -- allows using left and right buttons to move through chat 'edit' box
--     for i = 1, NUM_CHAT_WINDOWS do
--         _G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
--     end
    
--     ----------------------------------
--     -- Register Slash Commands!
--     ----------------------------------
--     SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI
--     SlashCmdList.RELOADUI = ReloadUI;

--     SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
--     SlashCmdList.FRAMESTK = function()
--         LoadAddOn("Blizzard_DebugTools");
--         FrameStackTooltip_Toggle(false);
--     end

--     SLASH_SKC1 = "/skc";
--     SlashCmdList.SKC = HandleSlashCommands;
-- end

-- local events = CreateFrame("Frame");
-- events:RegisterEvent("ADDON_LOADED");
-- events:SetScript("OnEvent", core.init);