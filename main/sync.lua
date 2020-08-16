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

local function OnUpdate_SyncCheck()
	-- wrapper for main logic
	SKC:SyncUpdate();
	return;
end

function SKC:StartSyncTicker()
	-- Main ticker that periodically provides data to sync with guild
	self.Timers.Sync.Ticker = C_Timer.NewTicker(self.Timers.Sync.TIME_STEP,OnUpdate_SyncCheck);
	self:Debug("Sync Ticker created!",self.DEV.VERBOSE.SYNC);
	return;
end

function SKC:SyncUpdate()
	-- function called periodically to synchronize
	-- synchronization is performed individually for each db
	self:Debug("SyncUpdate",self.DEV.VERBOSE.SYNC);
	-- initialize with completed sync overall
	self.SyncStatus = self.SYNC_STATUS_ENUM.COMPLETE;
	for _,db in ipairs(self.DB_SYNC_ORDER) do
		-- check if current sync has timed out
		if self.Timers.Sync.SyncTicks[db] >= self.Timers.Sync.SYNC_TIMEOUT_TICKS then
			-- sync has timed out, reset
			self:Debug("TIMEOUT: "..db.." , "..self.SyncPartners[db],self.DEV.VERBOSE.SYNC);
			self.Timers.Sync.SyncTicks[db] = 0;
			self.SyncPartners[db] = nil;
		elseif self.SyncPartners[db] ~= nil then
			-- sync in progress, increment counter
			self.SyncStatus = self.SYNC_STATUS_ENUM.IN_PROGRESS;
			self.Timers.Sync.SyncTicks[db] = self.Timers.Sync.SyncTicks[db] + 1;
			self:Debug("IN PROGRESS ["..self.Timers.Sync.SyncTicks[db].."]: "..db.." , "..self.SyncPartners[db],self.DEV.VERBOSE.SYNC);
		end
		-- check if sync completed
		if self.SyncPartners[db] == nil then
			-- get sync partner for current db
			self:DetermineSyncPartner(db);
			if self.SyncPartners[db] ~= nil then
				-- request sync
				self:Debug("REQUEST: "..db.." , "..self.SyncPartners[db],self.DEV.VERBOSE.SYNC);
				self.SyncStatus = self.SYNC_STATUS_ENUM.IN_PROGRESS;
				self:Send(self.db.char.ADDON_VERSION,self.CHANNELS.SYNC_RQST,"WHISPER",self.SyncPartners[db]);
			else
				-- send out sync check
				local msg = self:NilToStr(self.db.char.ADDON_VERSION)..","..db..","..self:NilToStr(self.db.char[db].edit_ts_raid)..","..self:NilToStr(self.db.char[db].edit_ts_generic);
				self:Send(msg,self.CHANNELS.SYNC_CHECK,"GUILD");
			end
		end
	end
	-- update status on GUI
	self:RefreshStatus();
	return;
end

function SKC:DetermineSyncPartner(db)
	-- determines sync partner for given database
	-- scan all collected SYNC_CHECK messages and determine if there is a LO/GL with a newer database
	-- mark that player in self.SyncPartners[db]
	return;
end

function SKC:ReadSyncCheck(msg,sender)
	-- read SYNC_CHECK and save msg
	-- check addon version
	-- only keep data from players with appropriate permissions (GL or LO)
	return;
end

function SKC:ReadSyncRqst(msg,sender)
	-- read SYNC_RQST and send that player requested database
	-- check addon version
	return;
end

function SKC:ReadSyncPush(msg,sender)
	-- read SYNC_PUSH and save database
	-- check addon version
	-- confirm that sender has correct permision (GL or LO)
	-- after sync is complete, mark self.SyncPartners[db] to nil
	return;
end










-- function SKC:LoginSyncCheckExists()
-- 	-- returns true if LoginSyncCheck exists (exists even if its been cancelled)
-- 	return(self.Timers.LoginSyncCheck.Ticker ~= nil);
-- end

-- function SKC:LoginSyncCheckActive()
-- 	-- returns true if LoginSyncCheck is active
-- 	-- considered active if timer hasnt started yet
-- 	return(self.Timers.LoginSyncCheck.Ticker == nil or not self.Timers.LoginSyncCheck.Ticker:IsCancelled());
-- end

-- local function OnUpdate_LoginSyncCheckSend()
-- 	-- Send timestamps of each database to online guild leaders and loot officers (if any)
-- 	-- will sync with first response
-- 	-- check if ticker has completed entire duration
-- 	if SKC.Timers.LoginSyncCheck.Ticks >= SKC.Timers.LoginSyncCheck.MAX_TICKS then
-- 		-- sync has not been answered yet / no one online --> if GL or LO, push all data to guild
-- 		if SKC.isGL() or SKC.isLO() then
-- 			SKC:Debug("LoginSyncCheck Timer expired, push data to guild",SKC.DEV.VERBOSE.COMM);
-- 			-- TODO
-- 		end
-- 		-- cancel
-- 		SKC.Timers.LoginSyncCheck.Ticker:Cancel();
-- 	end
-- 	-- check if interval met
-- 	if SKC:CheckAddonLoaded() and SKC.Timers.LoginSyncCheck.Ticks % SKC.Timers.LoginSyncCheck.UPDATE_INVTL == 0 then
-- 		SKC:Debug("LoginSyncCheckSend!",SKC.DEV.VERBOSE.COMM);
-- 		-- construct message
-- 		local db_lsit = {"GLP","LOP","GD","MSK","TSK","LP"}; -- important that they are requested in precisely this order
-- 		local msg = SKC.db.char.ADDON_VERSION;
-- 		for _,db_name in ipairs(db_lsit) do
-- 			msg = msg..","..db_name..","..SKC:NilToStr(SKC.db.char[db_name].edit_ts_raid)..","..SKC:NilToStr(SKC.db.char[db_name].edit_ts_generic);
-- 		end
-- 		-- send message to guild leader and loot officers that are online
-- 		local syncables = SKC:GetOnlineSyncables();
-- 		for idx,target in ipairs(syncables) do
-- 			SKC:Send(msg,CHANNELS.LOGIN_SYNC_CHECK,"WHISPER",target);
-- 		end
-- 	end
-- 	-- update ticker
-- 	SKC.Timers.LoginSyncCheck.Ticks = SKC.Timers.LoginSyncCheck.Ticks + 1;
-- 	SKC.Timers.LoginSyncCheck.ElapsedTime = SKC.Timers.LoginSyncCheck.ElapsedTime + SKC.Timers.LoginSyncCheck.TIME_STEP;
-- 	-- update status
-- 	SKC:RefreshStatus();
-- 	return;
-- end

-- function SKC:StartLoginSyncCheckTicker()
-- 	-- Create ticker that attempts to sync with guild at each iteration
-- 	-- once responded to, ticker is cancelled
-- 	if not self:LoginSyncCheckExists() then
-- 		-- only create ticker if one doesnt exist
-- 		self.Timers.LoginSyncCheck.Ticker = C_Timer.NewTicker(self.Timers.LoginSyncCheck.TIME_STEP,OnUpdate_LoginSyncCheckSend,self.Timers.LoginSyncCheck.MAX_TICKS);
-- 		self:Debug("LoginSyncCheckTicker created",self.DEV.VERBOSE.COMM);
-- 	end
-- 	return;
-- end

-- local function SyncPushSend(db_name,addon_channel,game_channel,name,end_msg_callback_fn)
-- 	-- send target database to name
-- 	if not CheckAddonLoaded() then return end
-- 	if not CheckAddonVerMatch() then
-- 		if COMM_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncPushSend, addon version mismatch from GL") end
-- 		return;
-- 	end
-- 	-- confirm that database is valid to send
-- 	if SKC_DB[db_name].edit_ts_generic == nil or SKC_DB[db_name].edit_ts_raid == nil then
-- 		if COMM_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncPushSend, edit timestamp(s) are nil for "..db_name) end
-- 	end
-- 	-- initiate send
-- 	PrintSyncMsgStart(db_name,true);
-- 	local db_msg = nil;
-- 	if db_name == "MSK" or db_name == "TSK" then
-- 		db_msg = "INIT,"..
-- 			db_name..","..
-- 			NilToStr(SKC_DB[db_name].edit_ts_generic)..","..
-- 			NilToStr(SKC_DB[db_name].edit_ts_raid);
-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 		db_msg = "META,"..
-- 			db_name..","..
-- 			NilToStr(SKC_DB[db_name].top)..","..
-- 			NilToStr(SKC_DB[db_name].bottom);
-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 		for node_name,node in pairs(SKC_DB[db_name].list) do
-- 			db_msg = "DATA,"..
-- 				db_name..","..
-- 				NilToStr(node_name)..","..
-- 				NilToStr(node.above)..","..
-- 				NilToStr(node.below)..","..
-- 				NilToStr(node.abs_pos)..","..
-- 				BoolToStr(node.live);
-- 			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 		end
-- 	elseif db_name == "GuildData" then
-- 		db_msg = "INIT,"..
-- 			db_name..","..
-- 			NilToStr(SKC_DB.GuildData.edit_ts_generic)..","..
-- 			NilToStr(SKC_DB.GuildData.edit_ts_raid)..","..
-- 			NilToStr(SKC_DB.GuildData.activity_thresh);
-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 		for guildie_name,c_data in pairs(SKC_DB.GuildData.data) do
-- 			db_msg = "DATA,"..
-- 				db_name..","..
-- 				NilToStr(guildie_name)..","..
-- 				NilToStr(c_data.Class)..","..
-- 				NilToStr(c_data.Spec)..","..
-- 				NilToStr(c_data["Raid Role"])..","..
-- 				NilToStr(c_data["Guild Role"])..","..
-- 				NilToStr(c_data.Status)..","..
-- 				NilToStr(c_data.Activity)..","..
-- 				NilToStr(c_data.last_live_time);
-- 			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 		end
-- 	elseif db_name == "LootPrio" then
-- 		db_msg = "INIT,"..
-- 			db_name..","..
-- 			NilToStr(SKC_DB.LootPrio.edit_ts_generic)..","..
-- 			NilToStr(SKC_DB.LootPrio.edit_ts_raid);
-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");	
-- 		for item,prio in pairs(SKC_DB.LootPrio.items) do
-- 			db_msg = "META,"..
-- 				db_name..","..
-- 				NilToStr(item)..","..
-- 				NilToStr(prio.sk_list)..","..
-- 				BoolToStr(prio.reserved)..","..
-- 				BoolToStr(prio.DE)..","..
-- 				BoolToStr(prio.open_roll);
-- 			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 			db_msg = "DATA,"..db_name..","..NilToStr(item);
-- 			for idx,plvl in ipairs(prio.prio) do
-- 				db_msg = db_msg..","..NilToStr(plvl);
-- 			end
-- 			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 		end
-- 	elseif db_name == "Bench" or db_name == "ActiveRaids" or db_name == "LootOfficers" then
-- 		db_msg = "INIT,"..
-- 			db_name..","..
-- 			NilToStr(SKC_DB[db_name].edit_ts_generic)..","..
-- 			NilToStr(SKC_DB[db_name].edit_ts_raid);
-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 		db_msg = "DATA,"..db_name;
-- 		for val,_ in pairs(SKC_DB[db_name].data) do
-- 			db_msg = db_msg..","..NilToStr(val);
-- 		end
-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
-- 	end
-- 	local db_msg = "END,"..db_name..", ,"; --awkward spacing to make csv parsing work
-- 	-- construct callback message
-- 	local func = function()
-- 		if end_msg_callback_fn then end_msg_callback_fn() end
-- 		-- complete send
-- 		PrintSyncMsgEnd(db_name,true);
-- 	end
-- 	-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue",func);
-- 	return;
-- end

-- local function SyncPushRead(msg,sender)
-- 	-- Write data to tmp_sync_var first, then given datbase
-- 	if not CheckAddonLoaded() then return end -- reject if addon not loaded yet
-- 	if LoginSyncCheckTickerActive() then return end -- reject if still waiting for login sync
-- 	-- parse first part of message
-- 	local part, db_name, msg_rem = strsplit(",",msg,3);
-- 	if db_name ~= "GuildData" and not CheckAddonVerMatch() then
-- 		-- reject any out of date database that isn't GuildData
-- 		if COMM_VERBOSE and part == "INIT" then 
-- 			SKC_Main:Print("ERROR","Rejected SyncPushRead, addon version does not match GL version from "..sender);
-- 		end
-- 		return;
-- 	end
-- 	if part == "INIT" then
-- 		-- first check to ensure that incoming data is actually fresher
-- 		-- get self edit time stamps
-- 		local my_edit_ts_raid = SKC_DB[db_name].edit_ts_raid;
-- 		local my_edit_ts_generic = SKC_DB[db_name].edit_ts_generic;
-- 		-- parse out timestamps
-- 		local their_edit_ts_generic, their_edit_ts_raid, _ = strsplit(",",msg_rem,3);
-- 		their_edit_ts_generic = NumOut(their_edit_ts_generic);
-- 		their_edit_ts_raid = NumOut(their_edit_ts_raid);
-- 		if their_edit_ts_generic == nil or their_edit_ts_raid == nil then
-- 			if COMM_VERBOSE then SKC_Main:Print("ERROR","Reject SyncPushRead, got nil timestamp(s) for "..db_name.." from "..sender) end
-- 			-- blacklist
-- 			blacklist[sender] = true;
-- 			return;
-- 		elseif (my_edit_ts_raid > their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic > their_edit_ts_generic) ) then
-- 			-- I have newer RAID data
-- 			-- OR I have the same RAID data but newer generic data
-- 			-- --> I have fresher data
-- 			if COMM_VERBOSE then SKC_Main:Print("ERROR","Reject SyncPushRead, incoming stale data for "..db_name.." from "..sender) end
-- 			-- blacklist
-- 			blacklist[sender] = true;
-- 			return;
-- 		end
-- 		-- cleanse blacklist
-- 		blacklist[sender] = nil;
-- 		-- data is fresh, begin read
-- 		PrintSyncMsgStart(db_name,false,sender);
-- 	elseif blacklist[sender] then
-- 		-- check if already blacklisted
-- 		if COMM_VERBOSE and part == "END" then SKC_Main:Print("ERROR","Reject SyncPushRead,"..sender.." was blacklisted for "..db_name) end
-- 		return;
-- 	end
-- 	-- If last part, deep copy to actual database
-- 	if part == "END" then
-- 		SKC_DB[db_name] = DeepCopy(tmp_sync_var)
-- 	end
-- 	-- Check if master looter, loot officer, and in active raid
-- 	if SKC_Main:isML() and SKC_Main:isLO() and CheckActive() then
-- 		-- reject read for MSK and TSK
-- 		if part == "MSK" or part == "TSK" then
-- 			if COMM_VERBOSE and part == "INIT" then SKC_Main:Print("ERROR","Reject SyncPushRead from "..sender.." because I HAVE THE POWER") end
-- 			return;
-- 		end
-- 	end
-- 	-- Read in data
-- 	if db_name == "MSK" or db_name == "TSK" then
-- 		if part == "INIT" then
-- 			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
-- 			ts_generic = NumOut(ts_generic);
-- 			ts_raid = NumOut(ts_raid);
-- 			tmp_sync_var = SK_List:new(nil);
-- 			tmp_sync_var.edit_ts_generic = ts_generic;
-- 			tmp_sync_var.edit_ts_raid = ts_raid;
-- 		elseif part == "META" then
-- 			local top, bottom = strsplit(",",msg_rem,2);
-- 			tmp_sync_var.top = StrOut(top);
-- 			tmp_sync_var.bottom = StrOut(bottom);
-- 		elseif part == "DATA" then
-- 			local name, above, below, abs_pos, live = strsplit(",",msg_rem,7);
-- 			name = StrOut(name);
-- 			tmp_sync_var.list[name] = SK_Node:new(nil,nil,nil);
-- 			tmp_sync_var.list[name].above = StrOut(above);
-- 			tmp_sync_var.list[name].below = StrOut(below);
-- 			tmp_sync_var.list[name].abs_pos = NumOut(abs_pos);
-- 			tmp_sync_var.list[name].live = BoolOut(live);		
-- 		end
-- 	elseif db_name == "GuildData" then
-- 		if part == "INIT" then
-- 			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
-- 			ts_generic = NumOut(ts_generic);
-- 			ts_raid = NumOut(ts_raid);
-- 			tmp_sync_var = GuildData:new(nil);
-- 			tmp_sync_var.edit_ts_generic = ts_generic;
-- 			tmp_sync_var.edit_ts_raid = ts_raid;
-- 		elseif part == "META" then
-- 			-- nothing to do
-- 		elseif part == "DATA" then
-- 			local name, class, spec, rr, gr, status, activity, last_live_time = strsplit(",",msg_rem,8);
-- 			name = StrOut(name);
-- 			class = StrOut(class);
-- 			tmp_sync_var.data[name] = CharacterData:new(nil,name,class);
-- 			tmp_sync_var.data[name].Spec = NumOut(spec);
-- 			tmp_sync_var.data[name]["Raid Role"] = NumOut(rr);
-- 			tmp_sync_var.data[name]["Guild Role"] = NumOut(gr);
-- 			tmp_sync_var.data[name].Status = NumOut(status);
-- 			tmp_sync_var.data[name].Activity = NumOut(activity);
-- 			tmp_sync_var.data[name].last_live_time = NumOut(last_live_time);
-- 		end
-- 	elseif db_name == "LootPrio" then
-- 		if part == "INIT" then
-- 			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
-- 			ts_generic = NumOut(ts_generic);
-- 			ts_raid = NumOut(ts_raid);
-- 			tmp_sync_var = LootPrio:new(nil);
-- 			tmp_sync_var.edit_ts_generic = ts_generic;
-- 			tmp_sync_var.edit_ts_raid = ts_raid;
-- 		elseif part == "META" then
-- 			local item, sk_list, res, de, open_roll = strsplit(",",msg_rem,5);
-- 			item = StrOut(item);
-- 			tmp_sync_var.items[item] = Prio:new(nil);
-- 			tmp_sync_var.items[item].sk_list = StrOut(sk_list);
-- 			tmp_sync_var.items[item].reserved = BoolOut(res);
-- 			tmp_sync_var.items[item].DE = BoolOut(de);
-- 			tmp_sync_var.items[item].open_roll = BoolOut(open_roll);
-- 		elseif part == "DATA" then
-- 			local item, msg_rem = strsplit(",",msg_rem,2);
-- 			item = StrOut(item);
-- 			local plvl = nil;
-- 			for idx,_ in ipairs(CLASS_SPEC_MAP) do
-- 				plvl, msg_rem = strsplit(",",msg_rem,2);
-- 				tmp_sync_var.items[item].prio[idx] = NumOut(plvl);
-- 			end
-- 		end
-- 	elseif db_name == "Bench" or db_name == "ActiveRaids" or db_name == "LootOfficers" then
-- 		if part == "INIT" then
-- 			local ts_generic, ts_raid = strsplit(",",msg_rem,2);
-- 			ts_generic = NumOut(ts_generic);
-- 			ts_raid = NumOut(ts_raid);
-- 			tmp_sync_var = SimpleMap:new(nil);
-- 			tmp_sync_var.edit_ts_generic = ts_generic;
-- 			tmp_sync_var.edit_ts_raid = ts_raid;
-- 		elseif part == "DATA" then
-- 			while msg_rem ~= nil do
-- 				val, msg_rem = strsplit(",",msg_rem,2);
-- 				tmp_sync_var.data[val] = true;
-- 			end
-- 		elseif part == "END" then
-- 			if db_name == "Bench" then 
-- 				UpdateLiveList();
-- 			elseif db_name == "LootOfficers" then 
-- 				UpdateDetailsButtons();
-- 			end
-- 		end
-- 	end
-- 	if part == "END" then
-- 		PrintSyncMsgEnd(db_name,false);
-- 		SKC_Main:PopulateData();
-- 	end
-- 	return;
-- end

function SKC:LoginSyncCheckRead(data,channel,sender)
	-- -- Arbitrate based on timestamp to push or pull database from sender
	-- -- reject if addon not yet loaded
	-- if not CheckAddonLoaded(COMM_VERBOSE) then
	-- 	if COMM_VERBOSE then SKC_Main:Print("WARN","Reject LoginSyncCheckRead()") end
	-- 	return;
	-- end
	-- -- ignore messages from self
	-- if sender == UnitName("player") then return end
	-- -- check if sender has confirmed that databses are sync'd
	-- if msg == "DONE" then
	-- 	LoginSyncCheckAnswered(sender);
	-- 	return;
	-- end
	-- -- ignore checks if self check ticker is still active
	-- if LoginSyncCheckTickerActive() then return end
	-- -- Check if any read or push is in progress
	-- if CheckIfReadInProgress() then
	-- 	if COMM_VERBOSE then SKC_Main:Print("WARN","Reject LoginSyncCheckRead(), read already in progress") end
	-- 	return;
	-- end
	-- -- because wow online status API sucks, need to confirm that we see that the sender is online before responding
	-- -- addon messages are discarded if player is offline
	-- if not CheckIfGuildMemberOnline(sender) then
	-- 	-- need to keep requesting new guild roster...
	-- 	GuildRoster();
	-- 	return;
	-- end
	-- -- parse message
	-- local db_name, their_edit_ts_raid, their_edit_ts_generic, msg_rem;
	-- their_addon_ver, msg_rem = strsplit(",",msg,2);
	-- -- first check that addon version is valid
	-- if their_addon_ver ~= SKC_DB.ADDON_VERSION then
	-- 	if COMM_VERBOSE then SKC_Main:Print("ERROR","Rejected LoginSyncCheckRead from "..sender.." due to addon version. Theirs: "..their_addon_ver.." Mine: "..SKC_DB.ADDON_VERSION) end
	-- 	return;
	-- end
	-- if COMM_VERBOSE then SKC_Main:Print("IMPORTANT","LoginSyncCheckRead() from "..sender) end
	-- while msg_rem ~= nil do
	-- 	-- iteratively parse out each db and arbitrate how to sync
	-- 	db_name, their_edit_ts_raid, their_edit_ts_generic, msg_rem = strsplit(",",msg_rem,4);
	-- 	their_edit_ts_raid = NumOut(their_edit_ts_raid);
	-- 	their_edit_ts_generic = NumOut(their_edit_ts_generic);
	-- 	-- get self edit time stamps (possible to be nil)
	-- 	local my_edit_ts_raid = SKC_DB[db_name].edit_ts_raid;
	-- 	local my_edit_ts_generic = SKC_DB[db_name].edit_ts_generic;
	-- 	if (my_edit_ts_raid ~= nil and my_edit_ts_generic ~=nil) and ( (my_edit_ts_raid > their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic > their_edit_ts_generic) ) ) then
	-- 		-- I have an existing version of this database AND
	-- 		-- I have newer RAID data OR I have the same RAID data but newer generic data
	-- 		-- --> send them my data
	-- 		if COMM_VERBOSE then SKC_Main:Print("WARN","Pushing "..db_name.." to "..sender) end
	-- 		SyncPushSend(db_name,CHANNELS.LOGIN_SYNC_PUSH,"WHISPER",sender);
	-- 	elseif (my_edit_ts_raid == nil or my_edit_ts_generic ==nil) or ( (my_edit_ts_raid < their_edit_ts_raid) or ( (my_edit_ts_raid == their_edit_ts_raid) and (my_edit_ts_generic < their_edit_ts_generic) ) ) then
	-- 		-- I do not have this database at all yet
	-- 		-- OR I have older RAID data
	-- 		-- OR I have the same RAID data but older generic data
	-- 		-- --> request their data (for the whole guild)
	-- 		if COMM_VERBOSE then SKC_Main:Print("WARN","Requesting "..db_name.." from "..sender) end
	-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOGIN_SYNC_PUSH_RQST,db_name,"WHISPER",sender,"main_queue");
	-- 	else
	-- 		-- alert them that already sync'd
	-- 		if COMM_VERBOSE then SKC_Main:Print("NORMAL","Already synchronized "..db_name.." with "..sender) end
	-- 		-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOGIN_SYNC_CHECK,"DONE","WHISPER",sender,"main_queue");
	-- 	end
	-- end
	return;
end

-- local function LoginSyncCheckTickerActive()
-- 	-- returns true of login sync check is still active (or hasn't started yet)
-- 	return(event_states.LoginSyncCheckTicker == nil or not event_states.LoginSyncCheckTicker:IsCancelled());
-- end

-- local function LoginSyncCheckAnswered(savior)
-- 	-- cancels the LoginSyncCheckTicker
-- 	if COMM_VERBOSE and LoginSyncCheckTickerActive() then
-- 		SKC_Main:Print("IMPORTANT","Login Sync Check Answered by "..savior.."!");
-- 	end
-- 	if event_states.LoginSyncCheckTicker ~= nil then event_states.LoginSyncCheckTicker:Cancel() end
-- 	-- update status
-- 	SKC_Main:RefreshStatus();
-- 	return;
-- end

-- function SKC:AddonMessageRead(data,channel,sender)
-- 	sender = StripRealmName(sender);
-- 	-- TODO, deserialize data
-- 	if prefix == CHANNELS.LOGIN_SYNC_CHECK then
-- 		--[[ 
-- 			Send (LoginSyncCheckSend): Upon login character requests sync for each database
-- 			Read (LoginSyncCheckRead): Arbitrate based on timestamp to push or pull database
-- 		--]]
-- 		SKC_Main:Print("WARN","GOT SOMETHING!")
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
-- 	elseif prefix == CHANNELS.LOOT_DECISION_PRINT then
-- 		if msg ~= nil then
-- 			SKC_Main:Print("NORMAL",msg);
-- 		end
-- 	elseif prefix == CHANNELS.LOOT_OUTCOME then
-- 		if msg ~= nil then
-- 			SKC_Main:Print("IMPORTANT",msg);
-- 		end
-- 	end
-- 	return;
-- end