--------------------------------------
-- SYNCHRONIZATION
--------------------------------------
-- Methods used for data synchronization between characters
--------------------------------------
-- METHODS
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
	for _,db in ipairs(self.DB_SYNC_ORDER) do self:ResetRead(db) end
	C_Timer.After(self.Timers.Sync.INIT_DELAY,CreateSyncTicker)
	return;
end

function SKC:SyncTick()
	-- function called periodically to synchronize with guild
	-- synchronization is performed individually for each db
	self:Debug("SyncTick",self.DEV.VERBOSE.SYNC_HIGH);
	-- request updated guild roster
	GuildRoster();
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		-- check if need to increment in ticker for in progress read
		if self.ReadStatus[db] then
			-- reading, increment counter
			self.Timers.Sync.SyncTicks[db] = self.Timers.Sync.SyncTicks[db] + 1;
			self:Debug("IN PROGRESS ["..self.Timers.Sync.SyncTicks[db]*self.Timers.Sync.TIME_STEP.."]: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
		end
		-- check if current sync has timed out
		if self.Timers.Sync.SyncTicks[db] >= self.Timers.Sync.SYNC_TIMEOUT_TICKS then
			-- sync has timed out, reset
			self:Debug("TIMEOUT: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
			self:ResetRead(db);
		end
		-- check if ready for new sync (not currently reading / waiting for read)
		if not self.ReadStatus[db] then
			-- get sync partner for current db
			self:DetermineSyncPartner(db);
			if self.SyncPartner[db] ~= nil and self:CheckIfGuildMemberOnline(self.SyncPartner[db])  then
				-- request sync from sync partner (if online)
				-- note, online check is necesary because underlying ChatThrottleLib will block send if target offline, this function ensures constantly updated GuildRoster
				self:Debug("REQUEST: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
				local msg = self:NilToStr(self.db.char.ADDON_VERSION)..","..db;
				self:Send(msg,self.CHANNELS.SYNC_RQST,"WHISPER",self.SyncPartner[db]);
				self.ReadStatus[db] = true;
			end
			if not self.ReadStatus[db] and self:isLO() then
				-- not currently reading and loot officer --> send out sync check for guild (i.e. does anyone want this data?)
				self:ResetRead(db);
				local msg = self:NilToStr(self.db.char.ADDON_VERSION)..","..db..","..self:NilToStr(self.db.char[db].edit_ts);
				self:Send(msg,self.CHANNELS.SYNC_CHECK,"GUILD");
			end
		end
	end
	-- update status on GUI
	self:RefreshStatus();
	return;
end

function SKC:ResetRead(db)
	-- resets from the reading state to prepare for new requests
	self.ReadStatus[db] = false;
	self.Timers.Sync.SyncTicks[db] = 0;
	self.SyncPartner[db] = nil;
	-- initialize sync candidate with self data
	self.SyncCandidate[db].name = UnitName("player");
	self.SyncCandidate[db].edit_ts = self.db.char[db].edit_ts;
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
	local their_addon_ver, db_name, their_edit_ts = strsplit(",",data,3);
	-- check for malformed message
	if 
	self:CheckIfEffectivelyNil(their_addon_ver) or 
	self:CheckIfEffectivelyNil(db_name) or 
	self:CheckIfEffectivelyNil(their_edit_ts) then
		self:Debug("Reject ReadSyncCheck, malformed message",self.DEV.VERBOSE.SYNC_LOW);
		return;
	 end
	-- check addon version
	if their_addon_ver ~= self.db.char.ADDON_VERSION then
		self:Debug("Reject ReadSyncCheck, mismatch addon version",self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	-- check that not already reading this database
	if self.ReadStatus[db] then
		self:Debug("Reject ReadSyncCheck, already reading "..db_name,self.DEV.VERBOSE.SYNC_HIGH);
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
	-- determine if their database is newer than current sync candidate
	their_edit_ts = self:NumOut(their_edit_ts);
	if their_edit_ts > self.SyncCandidate[db_name].edit_ts then
		-- they have newer generic data
		-- mark as sync candidate
		self:Debug("New sync candidate for "..db_name..": "..sender.." (their ts = "..their_edit_ts..") (my ts = "..self.SyncCandidate[db_name].edit_ts..")",self.DEV.VERBOSE.SYNC_LOW);
		self.SyncCandidate[db_name].name = sender;
		self.SyncCandidate[db_name].edit_ts = their_edit_ts;
	end
	return;
end

function SKC:ReadSyncRqst(addon_channel,msg,game_channel,sender)
	-- read SYNC_RQST and send the requested database out on GUILD
	-- reject self messages
	if sender == UnitName("player") then return end
	self:Debug("ReadSyncRqst",self.DEV.VERBOSE.SYNC_LOW);
	-- read message
	local data = self:Read(msg);
	if data == nil then return end
	-- parse
	local their_addon_ver, db_name = strsplit(",",data,2);
	-- check that sender is not nil
	if sender == nil then
		self:Debug("Reject ReadSyncRqst for "..db_name..", sender is nil",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- check that db_name is not nil
	if db_name == nil then
		self:Debug("Reject ReadSyncRqst from "..sender..", db_name is nil",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- check addon version
	if their_addon_ver ~= self.db.char.ADDON_VERSION then
		self:Debug("Reject ReadSyncRqst, mismatch addon version",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- check that not already reading this database
	if self.ReadStatus[db_name] then
		self:Debug("Reject ReadSyncRqst, already reading "..db_name,self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- check if still sending this database
	if self.SendStatus[db_name] < 1.0 then
		self:Debug("Reject ReadSyncRqst, already sending "..db_name,self.DEV.VERBOSE.SYNC_LOW);
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
	self:Debug("Sending "..db_name.." in response to "..sender,self.DEV.VERBOSE.SYNC_LOW);
	self:SendDB(db_name);
	return;
end

function SKC:ReadSyncPush(addon_channel,msg,game_channel,sender)
	-- read SYNC_PUSH (GUILD) and save database
	if sender == UnitName("player") then return end
	self:Debug("ReadSyncPush",self.DEV.VERBOSE.SYNC_LOW);
	-- read message
	local payload = self:Read(msg);
	if payload == nil then return end
	-- parse
	local db_name = payload.db_name;
	local their_addon_ver = payload.addon_ver;
	local their_edit_ts = payload.edit_ts;
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
	if db_name == "GLP" then
		-- GLP is GL permission to send only
		if not self:isGL(sender) then
			self:Debug("Reject ReadSyncCheck for GLP, "..sender.." is not the Guild Leader",self.DEV.VERBOSE.SYNC_LOW);
			return;
		end
	else
		-- all other databases are LO permission to send only
		if not self:isLO(sender) then
			self:Debug("Reject ReadSyncCheck for "..db_name..", "..sender.." is not a Loot Officer",self.DEV.VERBOSE.SYNC_LOW);
			return;
		end
	end
	-- confirm that incoming database is in fact newer than current database
	if self.db.char[db_name].edit_ts > their_edit_ts then
		self:Debug("Reject ReadSyncCheck, incoming "..db_name.." from "..sender.." was older",self.DEV.VERBOSE.SYNC_LOW);
		return;
	end
	-- copy
	self:CopyDB(db_name,payload.data)
	self:Debug("Copied "..db_name.." from "..sender,self.DEV.VERBOSE.SYNC_LOW);
	-- mark sync as completed
	self:ResetRead(db_name);
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

function SKC:SendDB(db_name)
	-- package and send table to target
	local payload = {
		db_name = db_name,
		addon_ver = self.db.char.ADDON_VERSION,
		edit_ts = self.db.char[db_name].edit_ts,
		data = self.db.char[db_name],
	};
	self.SendStatus[db_name] = 0.0;
	self:Send(payload,self.CHANNELS.SYNC_PUSH,"GUILD",nil,
		function(arg,curr_bytes,tot_bytes)
			-- save the current progress [0,1] for this db
			if curr_bytes == tot_bytes then
				SKC.SendStatus[db_name] = 1.0;
				self:Debug("Sent "..db_name,self.DEV.VERBOSE.SYNC_LOW);
			else
				SKC.SendStatus[db_name] = curr_bytes/tot_bytes;
			end
			-- update gui
			SKC:RefreshStatus();
		end);
	return;
end