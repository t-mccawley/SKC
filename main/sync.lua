--------------------------------------
-- SYNCHRONIZATION
--------------------------------------
local function SyncTickHandle()
	-- wrapper for main logic
	SKC:SyncTick();
	return;
end

local function CreateSyncTicker()
	-- creates the actual SyncTicker
	SKC.Timers.Sync.Ticker = C_Timer.NewTicker(SKC.Timers.Sync.TIME_STEP,SyncTickHandle);
	SKC:Debug("Sync Ticker created!",SKC.DEV.VERBOSE.SYNC_TICK);
end

function SKC:StartSyncTicker()
	-- starts the main ticker that periodically provides data to sync with guild
	-- prepare variables
	for _,db in ipairs(self.DB_SYNC_ORDER) do self:MarkSyncComplete(db) end
	C_Timer.After(self.Timers.Sync.INIT_DELAY,CreateSyncTicker)
	return;
end

function SKC:SyncTick()
	-- function called periodically to synchronize with guild
	-- synchronization is performed individually for each db
	self:Debug("SyncTick",self.DEV.VERBOSE.SYNC_HIGH);
	-- request updated guild roster data
	GuildRoster();
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		-- check if need to increment in progress count
		if self.SyncPartner[db] ~= nil then
			-- sync in progress, increment counter
			self.Timers.Sync.SyncTicks[db] = self.Timers.Sync.SyncTicks[db] + 1;
			self:Debug("IN PROGRESS ["..self.Timers.Sync.SyncTicks[db]*self.Timers.Sync.TIME_STEP.."]: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
		end
		-- check if current sync has timed out
		if self.Timers.Sync.SyncTicks[db] >= self.Timers.Sync.SYNC_TIMEOUT_TICKS then
			-- sync has timed out, reset
			self:Debug("TIMEOUT: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
			self:MarkSyncComplete(db);
		end
		-- check if ready for new sync (no current sync partner)
		if self.SyncPartner[db] == nil then
			-- get sync partner for current db
			self:DetermineSyncPartner(db);
			if self.SyncPartner[db] ~= nil and self:CheckIfGuildMemberOnline(self.SyncPartner[db])  then
				-- request sync from sync partner (if online)
				-- note, online check is necesary because underlying ChatThrottleLib will block send if target offline, this function ensures constantly updated GuildRoster
				self:Debug("REQUEST: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
				self.SyncStatus[db] = self.SYNC_STATUS_ENUM.IN_PROGRESS;
				local msg = self:NilToStr(self.db.char.ADDON_VERSION)..","..db;
				self:Send(msg,self.CHANNELS.SYNC_RQST,"WHISPER",self.SyncPartner[db]);
			elseif self:isLO() then
				-- send out sync check to guild (if self is LO)
				local msg = self:NilToStr(self.db.char.ADDON_VERSION)..","..db..","..self:NilToStr(self.db.char[db].edit_ts_raid)..","..self:NilToStr(self.db.char[db].edit_ts_generic);
				self:Send(msg,self.CHANNELS.SYNC_CHECK,"GUILD");
				self:MarkSyncComplete(db);
			end
		end
	end
	-- update status on GUI
	self:RefreshStatus();
	return;
end

function SKC:MarkSyncComplete(db)
	-- resets variables used to track the state of a sync for given db and marks complete
	self.SyncStatus[db] = self.SYNC_STATUS_ENUM.COMPLETE;
	self.Timers.Sync.SyncTicks[db] = 0;
	self.SyncPartner[db] = nil;
	-- initialize sync candidate with self data
	self.SyncCandidate[db].name = UnitName("player");
	self.SyncCandidate[db].edit_ts_raid = self.db.char[db].edit_ts_raid;
	self.SyncCandidate[db].edit_ts_generic = self.db.char[db].edit_ts_generic;
	return;
end

function SKC:DetermineSyncPartner(db)
	-- determines sync partner for given database
	-- marks that player in self.SyncPartner[db]
	if self.SyncCandidate[db].name == UnitName("player") then
		-- sync candidate is still self, no need to sync
		self.SyncPartner[db] = nil;
		return;
	else
		-- new sync partner!
		self.SyncPartner[db] = self.SyncCandidate[db].name;
	end
	return;
end

function SKC:ReadSyncCheck(addon_channel,msg,game_channel,sender)
	-- read SYNC_CHECK and save msg (if they have sync permission and have newer data)
	-- reject self messages
	if sender == UnitName("player") then return end
	if self.Timers.Sync.Ticker == nil then return end
	self:Debug("ReadSyncCheck",self.DEV.VERBOSE.SYNC_HIGH);
	-- read message
	local data = self:Read(msg);
	if data == nil then return end
	-- parse
	local their_addon_ver, db_name, their_edit_ts_raid, their_edit_ts_generic = strsplit(",",data,4);
	-- check for malformed message
	if 
	self:CheckIfEffectivelyNil(their_addon_ver) or 
	self:CheckIfEffectivelyNil(db_name) or 
	self:CheckIfEffectivelyNil(their_edit_ts_raid) or 
	self:CheckIfEffectivelyNil(their_edit_ts_generic) then
		self:Debug("Reject ReadSyncCheck, malformed message",self.DEV.VERBOSE.SYNC_LOW);
		return;
	 end
	-- check addon version
	if their_addon_ver ~= self.db.char.ADDON_VERSION then
		self:Debug("Reject ReadSyncCheck, mismatch addon version",self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	-- check that not already syncing for this database
	if self.SyncPartner[db_name] ~= nil then
		self:Debug("Reject ReadSyncCheck, already sync in progress for "..db_name,self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	-- check that sender has correct permissions
	if sender == nil then
		self:Debug("Reject ReadSyncCheck for "..db_name..", sender is nil",self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	if db_name == "GLP" then
		-- GLP is GL protected
		if not self:isGL(sender) then
			self:Debug("Reject ReadSyncCheck for GLP, "..sender.." is not the Guild Leader",self.DEV.VERBOSE.SYNC_HIGH);
			return;
		end
	else
		-- all other databases are LO protected
		if not self:isLO(sender) then
			self:Debug("Reject ReadSyncCheck for "..db_name..", "..sender.." is not a Loot Officer",self.DEV.VERBOSE.SYNC_HIGH);
			return;
		end
	end
	-- determine if their database is newer than sync candidate
	their_edit_ts_raid = self:NumOut(their_edit_ts_raid);
	their_edit_ts_generic = self:NumOut(their_edit_ts_generic);
	if their_edit_ts_raid > self.SyncCandidate[db_name].edit_ts_raid or 
	   (their_edit_ts_raid == self.SyncCandidate[db_name].edit_ts_raid and 
	   their_edit_ts_generic > self.SyncCandidate[db_name].edit_ts_generic) then
		-- they have newer raid data OR they have the same raid data but newer generic data
		-- mark as sync candidate
		self:Debug("New sync candidate for "..db_name..": "..sender,self.DEV.VERBOSE.SYNC_LOW);
		self.SyncCandidate[db_name].name = sender;
		self.SyncCandidate[db_name].edit_ts_raid = their_edit_ts_raid;
		self.SyncCandidate[db_name].edit_ts_generic = their_edit_ts_generic;
	end
	return;
end

function SKC:ReadSyncRqst(addon_channel,msg,game_channel,sender)
	-- read SYNC_RQST and send that player requested database
	-- reject self messages
	if sender == UnitName("player") then return end
	self:Debug("ReadSyncRqst",self.DEV.VERBOSE.SYNC_LOW);
	-- read message
	local data = self:Read(msg);
	if data == nil then return end
	-- parse
	local their_addon_ver, db_name = strsplit(",",data,2);
	-- check that not already syncing for this database
	if self.SyncPartner[db_name] ~= nil then
		self:Debug("Reject ReadSyncRqst, already sync in progress for "..db_name,self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- check addon version
	if their_addon_ver ~= self.db.char.ADDON_VERSION then
		self:Debug("Reject ReadSyncRqst, mismatch addon version",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- check that sender is not nil
	if sender == nil then
		self:Debug("Reject ReadSyncRqst for "..db_name..", sender is nil",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- confirm that sender is online
	if not self:CheckIfGuildMemberOnline(sender) then
		self:Debug("Reject ReadSyncRqst for "..db_name..", sender is offline",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- confirm that self is Loot Officer
	if not self:isLO() then
		self:Debug("Reject ReadSyncRqst for "..db_name..", I am not a Loot Officer",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- send requested database
	self:Debug("Sending "..db_name.." to "..sender,self.DEV.VERBOSE.SYNC_LOW);
	self:SendDB(db_name,"WHISPER",sender);
	return;
end

function SKC:ReadSyncPush(addon_channel,msg,game_channel,sender)
	-- read SYNC_PUSH and save database
	if sender == UnitName("player") then return end
	self:Debug("ReadSyncPush",self.DEV.VERBOSE.SYNC_LOW);
	-- read message
	local payload = self:Read(msg);
	if payload == nil then return end
	-- parse
	local db_name = payload.db_name;
	local their_addon_ver = payload.addon_ver;
	-- check addon version
	if their_addon_ver ~= self.db.char.ADDON_VERSION then
		self:Debug("Reject ReadSyncCheck, mismatch addon version",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- check that sender has correct permissions
	if sender == nil then
		self:Debug("Reject ReadSyncCheck for "..db_name..", sender is nil",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	if db_name == "GLP" and not self:isGL(sender) then
		self:Debug("Reject ReadSyncCheck for GLP, "..sender.." is not the Guild Leader",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	if db_name ~= "GLP" and not self:isLO(sender) then
		self:Debug("Reject ReadSyncCheck for "..db_name..", "..sender.." is not a Loot Officer",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- copy
	self:CopyDB(db_name,payload.data)
	self:Debug("Copied "..db_name.." from "..sender,self.DEV.VERBOSE.SYNC_LOW);
	-- mark sync as completed
	self:MarkSyncComplete(db_name);
	-- refresh GUI
	self:PopulateData();
	return;
end

function SKC:CopyDB(db_name,data)
	-- deep copy given data to db_name and set metatable appropriately
	self.db.char[db_name] = self:DeepCopy(data);
	if db_name == "GLP" then
		self.db.char.GLP = GuildLeaderProtected:new(self.db.char.GLP);
		self:ManageRaidChanges();
	elseif db_name == "GD" then
		self.db.char.GD = GuildData:new(self.db.char.GD);
	elseif db_name == "LOP" then
		self.db.char.LOP = LootOfficerProtected:new(self.db.char.LOP);
		self:ManageRaidChanges();
	elseif db_name == "MSK" then
		self.db.char.MSK = SK_List:new(self.db.char.MSK);
	elseif db_name == "TSK" then
		self.db.char.TSK = SK_List:new(self.db.char.TSK);
	elseif db_name == "LP" then
		self.db.char.LP = LootPrio:new(self.db.char.LP);
	else
		self:Error("CopyDB: db_name not recognized");
		self.db.char[db_name] = nil;
	end
	return;
end

function SKC:SendDB(db_name,game_channel,target)
	-- package and send table to target
	local payload = {
		db_name = db_name,
		addon_ver = self.db.char.ADDON_VERSION,
		data = self.db.char[db_name],
	};
	self:Send(payload,self.CHANNELS.SYNC_PUSH,game_channel,target);
	return;
end