--------------------------------------
-- SYNCHRONIZATION
--------------------------------------
function SKC:Send(data,addon_channel,wow_channel,target,callback_fn)
	-- serialize, compress, and send an addon message
	local data_ser = self.lib_ser:Serialize(data);
	local data_comp = self.lib_comp:CompressHuffman(data_ser)
	local msg = self.lib_enc:Encode(data_comp)
	self:SendCommMessage(addon_channel,msg,wow_channel,target,nil,callback_fn);
	return;
end

function SKC:Read(msg)
	-- decode, decompress, and deserialize data from addon message
	-- if failed, returns nil
	-- Decode the compressed data
	local data_decode = self.lib_enc:Decode(msg);
		
	--Decompress the decoded data
	local data_decomp, err_message = self.lib_comp:Decompress(data_decode);
	if not data_decomp then
		self:Error("Error decompressing: "..err_message);
		return;
	end
		
	-- Deserialize the decompressed data
	local success, data_out = self.lib_ser:Deserialize(data_decomp);
	if not success then
		self:Error("Error deserializing: "..data_out);
		return;
	end

	return data_out;
end

function SKC:GetSyncStatus()
	-- scan all databases and return sync status
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		if self.SyncStatus[db].val == self.SYNC_STATUS_ENUM.IN_PROGRESS.val then
			return(self.SYNC_STATUS_ENUM.IN_PROGRESS);
		end
	end
	return(self.SYNC_STATUS_ENUM.COMPLETE);
end

function SKC:CheckSyncInProgress()
	-- scan all databases and return true if sync is in progress
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		if self.SyncStatus[db].val == self.SYNC_STATUS_ENUM.IN_PROGRESS.val then
			return(true);
		end
	end
	return(false);
end

local function SyncTickHandle()
	-- wrapper for main logic
	SKC:SyncTick();
	return;
end

function SKC:StartSyncTicker()
	-- Main ticker that periodically provides data to sync with guild
	-- prepare variables
	for _,db in ipairs(self.DB_SYNC_ORDER) do self:MarkSyncComplete(db) end
	-- start ticker
	self.Timers.Sync.Ticker = C_Timer.NewTicker(self.Timers.Sync.TIME_STEP,SyncTickHandle);
	self:Debug("Sync Ticker created!",self.DEV.VERBOSE.SYNC_TICK);
	return;
end

function SKC:SyncTick()
	-- function called periodically to synchronize with guild
	-- synchronization is performed individually for each db
	self:Debug("SyncTick",self.DEV.VERBOSE.SYNC_TICK);
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		-- check if need to increment in progress count
		if self.SyncPartner[db] ~= nil then
			-- sync in progress, increment counter
			self.Timers.Sync.SyncTicks[db] = self.Timers.Sync.SyncTicks[db] + 1;
			self:Debug("IN PROGRESS ["..self.Timers.Sync.SyncTicks[db].."]: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
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
			if self.SyncPartner[db] ~= nil then
				-- request sync from sync partner
				self:Debug("REQUEST: "..db.." , "..self.SyncPartner[db],self.DEV.VERBOSE.SYNC_TICK);
				self.SyncStatus[db] = self.SYNC_STATUS_ENUM.IN_PROGRESS;
				local msg = self:NilToStr(self.db.char.ADDON_VERSION)..","..db;
				self:Send(msg,self.CHANNELS.SYNC_RQST,"WHISPER",self.SyncPartner[db]);
			else
				-- send out sync check to guild
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
	-- read SYNC_CHECK and save msg (if they have newer data)
	-- reject self messages
	if sender == UnitName("player") then return end
	self:Debug("ReadSyncCheck",self.DEV.VERBOSE.SYNC_HIGH);
	-- read message
	local data = self:Read(msg);
	if data == nil then return end
	-- parse
	local their_addon_ver, db_name, their_edit_ts_raid, their_edit_ts_generic = strsplit(",",data,4);
	-- check that not already syncing for this database
	if self.SyncPartner[db_name] ~= nil then
		self:Debug("Reject ReadSyncCheck, already sync in progress for "..db_name,self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	-- check addon version
	if their_addon_ver ~= self.db.char.ADDON_VERSION then
		self:Debug("Reject ReadSyncCheck, mismatch addon version",self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	-- check that sender has correct permissions
	if sender == nil then
		self:Debug("Reject ReadSyncCheck for "..db_name..", sender is nil",self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	if db_name == "GLP" and not self:isGL(sender) then
		self:Debug("Reject ReadSyncCheck for GLP, "..sender.." is not the Guild Leader",self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	if db_name ~= "GLP" and not self:isLO(sender) then
		self:Debug("Reject ReadSyncCheck for "..db_name..", "..sender.." is not a Loot Officer",self.DEV.VERBOSE.SYNC_HIGH);
		return;
	end
	-- determine if their database is newer than sync candidate
	their_edit_ts_raid = self:NumOut(their_edit_ts_raid);
	their_edit_ts_generic = self:NumOut(their_edit_ts_generic);
	if their_edit_ts_raid > self.SyncCandidate[db_name].edit_ts_raid or 
	   (their_edit_ts_raid == self.SyncCandidate[db_name].edit_ts_raid and 
	   their_edit_ts_generic > self.SyncCandidate[db_name].edit_ts_generic) then
		-- they have newer raid data OR they have the same raid data but newer generic data
		-- mark as sync candidate
		self:Debug("New sync candidate: "..sender,self.DEV.VERBOSE.SYNC_LOW);
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
		self:Debug("Reject ReadSyncRqst, already sync in progress for "..db_name,self.DEV.VERBOSE.SYNC_HIGH);
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

function SKC:SendDB(db_name,game_channel,target)
	-- package and send table to target
	local payload = {
		db_name = db_name,
		addon_ver = self.db.char.ADDON_VERSION,
		data = self.db.char[db_name]
	};
	self:Send(payload,self.CHANNELS.SYNC_PUSH,game_channel,target);
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
	elseif db_name == "GD" then
		self.db.char.GD = GuildData:new(self.db.char.GD);
	elseif db_name == "LOP" then
		self.db.char.LOP = LootOfficerProtected:new(self.db.char.LOP);
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