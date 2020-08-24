--------------------------------------
-- INITIALIZE
--------------------------------------
-- handles initialization event of addon
function SKC:OnInitialize()
	-- initialize saved database
	self.db = LibStub("AceDB-3.0"):New("SKC_DB",self.DB_DEFAULT);
	-- initialize or refresh metatables
	-- self:ResetDBs(true); -- Used for hard reset in dev
	self.db.char.GLP = GuildLeaderProtected:new(self.db.char.GLP);
	self.db.char.GD = GuildData:new(self.db.char.GD);
	self.db.char.LOP = LootOfficerProtected:new(self.db.char.LOP);
	self.db.char.MSK = SK_List:new(self.db.char.MSK);
	self.db.char.TSK = SK_List:new(self.db.char.TSK);
	self.db.char.LP = LootPrio:new(self.db.char.LP);
	self.db.char.LM = LootManager:new(self.db.char.LM);
	-- request updated guild roster
	GuildRoster();
	-- check for fresh installation
	if self.db.char.INIT_SETUP then
		self:Alert("Welcome (/skc help)");
		self.db.char.INIT_SETUP = false;
	else
		self:Alert("Welcome Back (/skc)");
	end
	-- uncheck live filter because its confusing
	self.db.char.FS.Live = false;
	-- register slash commands
	self:RegisterChatCommand("rl",ReloadUI);
	self:RegisterChatCommand("skc","SlashHandler");
	-- register comms
	self:RegisterComm(self.CHANNELS.SYNC_CHECK,"ReadSyncCheck");
	self:RegisterComm(self.CHANNELS.SYNC_RQST,"ReadSyncRqst");
	self:RegisterComm(self.CHANNELS.SYNC_PUSH,"ReadSyncPush");
	self:RegisterComm(self.CHANNELS.LOOT,"ReadLootMsg");
	self:RegisterComm(self.CHANNELS.LOOT_DECISION,"ReadLootDecision");
	self:RegisterComm(self.CHANNELS.LOOT_DECISION_PRINT,"PrintLootDecision");
	self:RegisterComm(self.CHANNELS.LOOT_OUTCOME_PRINT,"PrintLootOutcome");
	-- register events
	self:RegisterEvent("GUILD_ROSTER_UPDATE","ManageGuildData");
	self:RegisterEvent("LOOT_OPENED","OnOpenLoot");
	self:RegisterEvent("LOOT_SLOT_CLEARED","ManageLootWindow");
	self:RegisterEvent("PLAYER_ENTERING_WORLD","RefreshStatus");
	self:RegisterEvent("GROUP_ROSTER_UPDATE","ManageRaidChanges");
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED","ManageRaidChanges");
	-- Mark addon loaded
	self.event_states.AddonLoaded = true;
	-- create blank main GUI
	self:CreateMainGUI();
	-- create blank loot GUI
	self:CreateLootGUI();
	-- create loot starter buttons
	self:CreateLootStarterGUI()
	-- Populate Data
	self:PopulateData();
	-- Start sync ticker
	self:StartSyncTicker();
	return;
end