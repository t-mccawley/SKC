local function SyncPushSend(db_name,addon_channel,game_channel,name,end_msg_callback_fn)
	-- send target database to name
	if not CheckAddonLoaded() then return end
	if not CheckAddonVerMatch() then
		if COMM_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncPushSend, addon version mismatch from GL") end
		return;
	end
	-- confirm that database is valid to send
	if SKC_DB[db_name].edit_ts_generic == nil or SKC_DB[db_name].edit_ts_raid == nil then
		if COMM_VERBOSE then SKC_Main:Print("ERROR","Rejected SyncPushSend, edit timestamp(s) are nil for "..db_name) end
	end
	-- initiate send
	PrintSyncMsgStart(db_name,true);
	local db_msg = nil;
	if db_name == "MSK" or db_name == "TSK" then
		db_msg = "INIT,"..
			db_name..","..
			NilToStr(SKC_DB[db_name].edit_ts_generic)..","..
			NilToStr(SKC_DB[db_name].edit_ts_raid);
		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
		db_msg = "META,"..
			db_name..","..
			NilToStr(SKC_DB[db_name].top)..","..
			NilToStr(SKC_DB[db_name].bottom);
		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
		for node_name,node in pairs(SKC_DB[db_name].list) do
			db_msg = "DATA,"..
				db_name..","..
				NilToStr(node_name)..","..
				NilToStr(node.above)..","..
				NilToStr(node.below)..","..
				NilToStr(node.abs_pos)..","..
				BoolToStr(node.live);
			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
		end
	elseif db_name == "GuildData" then
		db_msg = "INIT,"..
			db_name..","..
			NilToStr(SKC_DB.GuildData.edit_ts_generic)..","..
			NilToStr(SKC_DB.GuildData.edit_ts_raid)..","..
			NilToStr(SKC_DB.GuildData.activity_thresh);
		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
		for guildie_name,c_data in pairs(SKC_DB.GuildData.data) do
			db_msg = "DATA,"..
				db_name..","..
				NilToStr(guildie_name)..","..
				NilToStr(c_data.Class)..","..
				NilToStr(c_data.Spec)..","..
				NilToStr(c_data["Raid Role"])..","..
				NilToStr(c_data["Guild Role"])..","..
				NilToStr(c_data.Status)..","..
				NilToStr(c_data.Activity)..","..
				NilToStr(c_data.last_live_time);
			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
		end
	elseif db_name == "LootPrio" then
		db_msg = "INIT,"..
			db_name..","..
			NilToStr(SKC_DB.LootPrio.edit_ts_generic)..","..
			NilToStr(SKC_DB.LootPrio.edit_ts_raid);
		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");	
		for item,prio in pairs(SKC_DB.LootPrio.items) do
			db_msg = "META,"..
				db_name..","..
				NilToStr(item)..","..
				NilToStr(prio.sk_list)..","..
				BoolToStr(prio.reserved)..","..
				BoolToStr(prio.DE)..","..
				BoolToStr(prio.open_roll);
			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
			db_msg = "DATA,"..db_name..","..NilToStr(item);
			for idx,plvl in ipairs(prio.prio) do
				db_msg = db_msg..","..NilToStr(plvl);
			end
			-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
		end
	elseif db_name == "Bench" or db_name == "ActiveRaids" or db_name == "LootOfficers" then
		db_msg = "INIT,"..
			db_name..","..
			NilToStr(SKC_DB[db_name].edit_ts_generic)..","..
			NilToStr(SKC_DB[db_name].edit_ts_raid);
		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
		db_msg = "DATA,"..db_name;
		for val,_ in pairs(SKC_DB[db_name].data) do
			db_msg = db_msg..","..NilToStr(val);
		end
		-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue");
	end
	local db_msg = "END,"..db_name..", ,"; --awkward spacing to make csv parsing work
	-- construct callback message
	local func = function()
		if end_msg_callback_fn then end_msg_callback_fn() end
		-- complete send
		PrintSyncMsgEnd(db_name,true);
	end
	-- ChatThrottleLib:SendAddonMessage("NORMAL",addon_channel,db_msg,game_channel,name,"main_queue",func);
	return;
end