--------------------------------------
-- INITIALIZE
--------------------------------------
function SKC:OnInitialize()
	-- initialize saved database
	self.db = LibStub("AceDB-3.0"):New("SKC_DB",self.DB_DEFAULT);
	-- determine if fresh
	if self.db.char.INIT_SETUP then
		self:Alert("Welcome (/skc help)");
	else
		self:Alert("Welcome Back (/skc)");
	end
	-- initialize or refresh metatables
	self.db.char.GLP = GuildLeaderProtected:new(self.db.char.GLP);
	self.db.char.GD = GuildData:new(self.db.char.GD);
	self.db.char.LOP = LootOfficerProtected:new(self.db.char.LOP);
	self.db.char.MSK = SK_List:new(self.db.char.MSK);
	self.db.char.TSK = SK_List:new(self.db.char.TSK);
	self.db.char.LP = LootPrio:new(self.db.char.LP);
	self.db.char.LM = LootManager:new(self.db.char.LM);
	-- register slash commands
	self:RegisterChatCommand("rl",ReloadUI);
	self:RegisterChatCommand("skc","SlashHandler");
	-- register comms
	self:RegisterComm(self.CHANNELS.SYNC_CHECK,"ReadSyncCheck");
	self:RegisterComm(self.CHANNELS.SYNC_RQST,"ReadSyncRqst");
	self:RegisterComm(self.CHANNELS.SYNC_PUSH,"ReadSyncPush");
	self:RegisterComm(self.CHANNELS.LOOT,"TODO");
	self:RegisterComm(self.CHANNELS.LOOT_DECISION,"TODO");
	self:RegisterComm(self.CHANNELS.LOOT_DECISION_PRINT,"TODO");
	self:RegisterComm(self.CHANNELS.LOOT_OUTCOME,"TODO");
	-- register events
	self:RegisterEvent("GUILD_ROSTER_UPDATE","ManageGuildData");
	self:RegisterEvent("LOOT_OPENED","OnOpenLoot");
	self:RegisterEvent("OPEN_MASTER_LOOT_LIST","OnOpenMasterLoot");
	self:RegisterEvent("PLAYER_ENTERING_WORLD","ManageLogging");
	self:RegisterEvent("GROUP_ROSTER_UPDATE","ManageRaidChanges");
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED","ManageRaidChanges");
	-- create blank main GUI
	self:CreateMainGUI();
	-- create blank loot GUI
	self:CreateLootGUI();
	-- Populate Data
	-- self:PopulateData();
	self.event_states.AddonLoaded = true;
	-- Start sync ticker
	self:StartSyncTicker();
	return;
end

-- local function EventHandler(self,event,...)
-- 	if event == "CHAT_MSG_ADDON" then
-- 		AddonMessageRead(...);
-- 	elseif event == "ADDON_LOADED" then
-- 		OnAddonLoad(...);
-- 	elseif event == "GUILD_ROSTER_UPDATE" then
-- 		-- Sync GuildData (if GL) and create ticker to send sync requests
-- 		SyncGuildData();
-- 	elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LOOT_METHOD_CHANGED" then
-- 		UpdateLiveList();
-- 		UpdateDetailsButtons();
-- 	elseif event == "OPEN_MASTER_LOOT_LIST" then
-- 		SaveLoot();
-- 	elseif event == "PLAYER_ENTERING_WORLD" then
-- 		if COMM_VERBOSE then SKC_Main:Print("NORMAL","Firing PLAYER_ENTERING_WORLD") end
-- 		ManageLootLogging();
-- 	end
	
-- 	return;
-- end

-- local events = CreateFrame("Frame");
-- events:RegisterEvent("CHAT_MSG_ADDON");
-- events:RegisterEvent("ADDON_LOADED");
-- events:RegisterEvent("GUILD_ROSTER_UPDATE");
-- events:RegisterEvent("GROUP_ROSTER_UPDATE");
-- events:RegisterEvent("PARTY_LOOT_METHOD_CHANGED");
-- events:RegisterEvent("OPEN_MASTER_LOOT_LIST");
-- events:RegisterEvent("PLAYER_ENTERING_WORLD");
-- events:SetScript("OnEvent", EventHandler);

-- local function AddonMessageRead(prefix,msg,channel,sender)
-- 	sender = StripRealmName(sender);
-- 	if prefix == CHANNELS.LOGIN_SYNC_CHECK then
-- 		--[[ 
-- 			Send (LoginSyncCheckSend): Upon login character requests sync for each database
-- 			Read (LoginSyncCheckRead): Arbitrate based on timestamp to push or pull database
-- 		--]]
-- 		LoginSyncCheckRead(msg,sender);
-- 	elseif prefix == CHANNELS.LOGIN_SYNC_PUSH then
-- 		--[[ 
-- 			Send (LoginSyncCheckRead -> SyncPushSend - LOGIN_SYNC_PUSH): Push given database to target player
-- 			Read (SyncPushRead): Write given database to player (only accept first push)
-- 		--]]
-- 		local part, db_name, msg_rem = strsplit(",",msg,3);
-- 		if sender ~= UnitName("player") and (event_states.LoginSyncPartner == nil or event_states.LoginSyncPartner == sender) then
-- 			event_states.LoginSyncPartner = sender;
-- 			LoginSyncCheckAnswered(sender);
-- 			SyncPushRead(msg,sender);
-- 		end
-- 	elseif prefix == CHANNELS.LOGIN_SYNC_PUSH_RQST then
-- 		--[[ 
-- 			Send (LoginSyncCheckRead): Request a push for given database from target player
-- 			Read (SyncPushSend - SYNC_PUSH): Respond with push for given database
-- 		--]]
-- 		LoginSyncCheckAnswered(sender);
-- 		-- send data out to entire guild (if one person needed it, everyone needs it)
-- 		SyncPushSend(msg,CHANNELS.SYNC_PUSH,"GUILD",nil);
-- 	elseif prefix == CHANNELS.SYNC_PUSH then
-- 		--[[ 
-- 			Send (SyncPushSend - SYNC_PUSH): Push given database to target player
-- 			Read (SyncPushRead): Write given datbase to player (accepts as many as possible)
-- 		--]]
-- 		-- Reject if message was from self
-- 		if sender ~= UnitName("player") then
-- 			SyncPushRead(msg,sender);
-- 		end
-- 	elseif prefix == CHANNELS.LOOT then
-- 		--[[ 
-- 			Send (SendLootMsgs): Send loot items for which each player is elligible to make a decision on
-- 			Read (ReadLootMsg): Initiate loot decision GUI for player
-- 		--]]
-- 		-- read loot message and save to LootManager
-- 		if msg ~= "BLANK" then
-- 			SKC_DB.LootManager:ReadLootMsg(msg,sender);
-- 		end
-- 	elseif prefix == CHANNELS.LOOT_DECISION then
-- 		--[[ 
-- 			Send (SendLootDecision): Send loot decision to ML
-- 			Read (ReadLootDecision): Determine loot winner
-- 		--]]
-- 		-- read message, determine winner, award loot, start next loot decision
-- 		SKC_DB.LootManager:ReadLootDecision(msg,sender);
-- 	elseif prefix == CHANNELS.LOOT_OUTCOME then
-- 		if msg ~= nil then
-- 			print(" ");
-- 			SKC_Main:Print("IMPORTANT",msg);
-- 			print(" ");
-- 		end
-- 	end
-- 	return;
-- end