--------------------------------------
-- LootManager
--------------------------------------
-- Datastructure used by master looter to manage loot items and to determine winners
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
LootManager = {
	loot_master = nil, -- name of the master looter
	current_loot = nil, -- Loot object of loot that is being decided on
	pending_loot = {}, -- array of Loot objects
	current_loot_timer = nil, -- timer used to track when decision time has expired
}; 
LootManager.__index = LootManager;

function LootManager:new(loot_manager)
	if loot_manager == nil then
		-- initalize fresh
		local obj = {};
		obj.loot_master = nil;
		obj.current_loot = Loot:new(nil);
		obj.pending_loot = {};
		obj.current_loot_timer = nil;
		setmetatable(obj,LootManager);
		return obj;
	else
		-- reset timer
		loot_manager.current_loot_timer = nil;
		-- set metatable of existing table
		loot_manager.current_loot = Loot:new(loot_manager.current_loot);
		for key,value in ipairs(loot_manager.pending_loot) do
			loot_manager.pending_loot[key] = Loot:new(loot_manager.pending_loot[key]);
		end
		setmetatable(loot_manager,LootManager);
		return loot_manager;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function LootManager:Reset()
	-- reset entire loot manager
	self.pending_loot = {};
	self:ResetCurrentLoot();
	return;
end

function LootManager:GetLootIdx(item_name,silent)
	-- returns index for given item name
	for idx,loot in ipairs(self.pending_loot) do
		if item_name == loot.lootName then return idx end
	end
	if not silent then SKC_Main:Print("ERROR",item_name.." not in LootManager") end;
	return nil;
end

function LootManager:SetCurrentLootDirect(item_name,item_link,open_roll,sk_list)
	-- directly writes new Loot object for current loot
	self.current_loot = Loot:new(nil,item_name,item_link,open_roll,sk_list);
	return
end

function LootManager:SetCurrentLootByIdx(loot_idx)
	-- sets current loot by index of loot already in pending_loot
	-- only usable by loot master
	if not SKC_Main:isML() then
		SKC_Main:Print("ERROR","Cannot SetCurrentLootByIdx, not loot master");
		return 
	end
	if self.pending_loot[loot_idx] == nil then
		SKC_Main:Print("ERROR","Cannot SetCurrentLootByIdx, index "..loot_idx.." not found");
		return;
	end
	local item_name = self.pending_loot[loot_idx].lootName;
	local item_link = self.pending_loot[loot_idx].lootLink;
	local open_roll = self.pending_loot[loot_idx].open_roll;
	local sk_list = self.pending_loot[loot_idx].sk_list;
	self:SetCurrentLootDirect(item_name,item_link,open_roll,sk_list);
	-- copy over all decisions, rolls, and sk positions from pending_loot
	-- copy pending decisions over from pending_loot (created when item was originally saved to LootManager)
	self.current_loot.decisions = DeepCopy(self.pending_loot[loot_idx].decisions);
	self.current_loot.sk_pos = DeepCopy(self.pending_loot[loot_idx].sk_pos);
	self.current_loot.rolls = DeepCopy(self.pending_loot[loot_idx].rolls);
	return
end

function LootManager:GetCurrentLootName()
	if self.current_loot == nil then
		SKC_Main:Print("ERROR","Current loot not set");
		return nil;
	end
	return self.current_loot.lootName;
end

function LootManager:GetCurrentLootLink()
	if self.current_loot == nil then
		SKC_Main:Print("ERROR","Current loot not set");
		return nil;
	end
	return self.current_loot.lootLink;
end

function LootManager:GetCurrentOpenRoll()
	if self.current_loot == nil then
		SKC_Main:Print("ERROR","Current loot not set");
		return nil;
	end
	return self.current_loot.open_roll;
end

function LootManager:GetCurrentLootSKList()
	if self.current_loot == nil then
		SKC_Main:Print("ERROR","Current loot not set");
		return nil;
	end
	return self.current_loot.sk_list;
end

function LootManager:AddLoot(item_name,item_link)
	-- add new loot item to pending_loot
	-- check if item already added
	if self:GetLootIdx(item_name,true) ~= nil then
		if LOOT_VERBOSE then SKC_Main:Print("WARN",item_link.." already added to LootManager") end
		return nil;
	end
	local idx = #self.pending_loot + 1;
	local open_roll = SKC_DB.LootPrio:GetOpenRoll(item_name);
	local sk_list = SKC_DB.LootPrio:GetSKList(item_name);
	self.pending_loot[idx] = Loot:new(nil,item_name,item_link,open_roll,sk_list);
	if LOOT_VERBOSE then
		DEFAULT_CHAT_FRAME:AddMessage(" ");
		SKC_Main:Print("NORMAL","Added "..item_link);
		SKC_Main:Print("NORMAL","Item Name: "..item_name);
		if open_roll then SKC_Main:Print("NORMAL","Open Roll: TRUE") else SKC_Main:Print("NORMAL","Open Roll: FALSE") end
		SKC_Main:Print("NORMAL","SK List: "..sk_list);
		SKC_Main:Print("NORMAL","Loot Index: "..idx);
		DEFAULT_CHAT_FRAME:AddMessage(" ");
	end
	return idx;
end

function LootManager:AddCharacter(char_name,item_idx)
	-- add given character as pending loot decision for given item index in pending_loot
	-- get index of given item_name
	if item_idx == nil then
		item_idx = self:GetLootIdx(item_name);
		if item_idx == nil then return end
	end
	-- set player decision to pending
	self.pending_loot[item_idx].decisions[char_name] = LOOT_DECISION.PENDING;
	-- save player position
	self.pending_loot[item_idx].sk_pos[char_name] = SKC_DB[self.pending_loot[item_idx].sk_list]:GetPos(char_name);
	-- roll for character
	self.pending_loot[item_idx].rolls[char_name] = math.random(100); -- random number between 1 and 100
	return;
end

function LootManager:SendLootMsgs(item_idx)
	-- send loot message to all elligible characters
	-- construct message
	local loot_msg = self.current_loot.lootName..","..
		self.current_loot.lootLink..","..
		BoolToStr(self.current_loot.open_roll)..","..	
		self.current_loot.sk_list;
	-- scan elligible players and send message
	for char_name,_ in pairs(self.current_loot.decisions) do
		-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOOT,loot_msg,"WHISPER",char_name,"main_queue");
	end
	return;
end

function LootManager:StartPersonalLootDecision()
	if self.current_loot == nil then 
		if LOOT_VERBOSE then SKC_Main:Print("ERROR","No loot to decide on") end
		return;
	end
	-- Begins personal loot decision process
	local sk_list = self:GetCurrentLootSKList();
	local open_roll = self:GetCurrentOpenRoll();
	local alert_msg = "Would you like to "..sk_list.." for "..self:GetCurrentLootLink().."?";
	SKC_Main:Print("IMPORTANT",alert_msg);
	-- Trigger GUI
	SKC_Main:DisplayLootDecisionGUI(open_roll,sk_list);
	return;
end

function LootManager:LootDecisionPending()
	-- returns true if there is still loot currently being decided on
	if self.current_loot_timer == nil then
		-- no pending loot decision
		return false;
	else
		if self.current_loot_timer:IsCancelled() then
			-- no pending loot decision
			return false;
		else
			-- pending loot decision
			SKC_Main:Print("ERROR","Still waiting on loot decision for "..self:GetCurrentLootLink());
			return true;
		end
	end
end

function LootManager:ReadLootMsg(msg,sender)
	-- reads loot message on local client side (not necessarily ML)
	-- saves item into current loot index and loot_master
	self.loot_master = StripRealmName(sender);
	local item_name, item_link, open_roll, sk_list = strsplit(",",msg,4);
	open_roll = BoolOut(open_roll);
	if not SKC_Main:isML() then
		-- instantiate fresh object
		self:SetCurrentLootDirect(item_name,item_link,open_roll,sk_list);
	else
		-- current loot already exists, just check that item matches
		if item_name ~= self.current_loot.lootName then
			SKC_Main:Print("ERROR","Received loot message for item that is not current_loot!");
		end
	end
	-- Check that SKC is active for client
	if not CheckActive() then
		-- Automatically pass
		self:SendLootDecision(LOOT_DECISION.PASS);
	else
		-- start GUI
		self:StartPersonalLootDecision();
	end
	return;
end

function LootManager:SendLootDecision(loot_decision)
	SKC_Main:Print("IMPORTANT","You selected "..LOOT_DECISION.TEXT_MAP[loot_decision].." for "..self:GetCurrentLootLink());
	local msg = self:GetCurrentLootName()..","..loot_decision;
	-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOOT_DECISION,msg,"WHISPER",self.loot_master,"main_queue");
	return;
end

local function KickOffWrapper()
	-- wrapper function for kick off because i cant figure out how to call class method with After()
	SKC_DB.LootManager:KickOff();
	return;
end

local function KickOffWithDelay()
	-- calls kick off function after configurable amount of delay
	C_Timer.After(LOOT_DECISION.OPTIONS.KICKOFF_DELAY,KickOffWrapper);
	return;
end

function LootManager:ConstructOutcomeMsg(winner,loot_name,loot_link,DE,send_success,receiver)
	-- constructs outcome message and writes to log
	local msg = nil;
	local winner_with_color = FormatWithClassColor(winner);
	local event_type_log = LOG_OPTIONS["Event Type"].Options.Winner;
	local sk_list = self:GetCurrentLootSKList();
	local winner_decision = self.current_loot.decisions[winner];
	if winner_decision == LOOT_DECISION.SK then
		msg = winner_with_color.." won "..loot_link.." by "..sk_list.." (prio: "..self.current_loot.prios[winner]..", position: "..self.current_loot.sk_pos[winner].." --> "..SKC_DB[sk_list]:GetPos(winner)..")!";
	elseif winner_decision == LOOT_DECISION.ROLL then
		msg = winner_with_color.." won "..loot_link.." by ROLL ("..self.current_loot.rolls[winner]..") [p"..self.current_loot.prios[winner].."]!";
	else
		-- Everyone passed
		msg = "Everyone passed on "..loot_link..", awarded to "..winner_with_color;
		if DE then
			msg = msg.." to be DISENCHANTED."
			event_type_log = LOG_OPTIONS["Event Type"].Options.DE;
		else
			msg = msg.." for the GUILD BANK."
			event_type_log = LOG_OPTIONS["Event Type"].Options.GB;
		end
	end
	if not send_success then
		msg = msg.." Send failed, item given to master looter."
	end
	-- Write outcome to log
	WriteToLog( 
		event_type_log,
		winner,
		LOOT_DECISION.TEXT_MAP[winner_decision],
		loot_name,
		sk_list,
		self.current_loot.prios[winner],
		self.current_loot.sk_pos[winner],
		SKC_DB[sk_list]:GetPos(winner),
		self.current_loot.rolls[winner],
		receiver
	);
	return msg;
end

function LootManager:SendOutcomeMsg(msg)
	-- Send Outcome Message
	-- when message has been sent, kick off next loot (with delay)
	-- if there are already SK messages in the queue, this will be (correctly) further delayed due to transmission bottleneck
	-- next item won't be initiated until SK lists on clients have been updated
	-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOOT_OUTCOME,msg,"RAID",nil,"main_queue",KickOffWithDelay);
	return;
end

function LootManager:ResetCurrentLoot()
	-- resets current loot
	if self.current_loot_timer ~= nil then self.current_loot_timer:Cancel() end
	self.current_loot_timer = nil;
	self.current_loot = nil;
	return;
end

function LootManager:MarkLootAwarded(loot_name)
	-- mark loot awarded
	-- get loot index
	local loot_idx = self:GetLootIdx(loot_name,true);
	if loot_idx ~= nil then
		-- remove item from pending loot
		if LOOT_VERBOSE then SKC_Main:Print("NORMAL","Removing "..loot_name.." from pending loot") end
		self.pending_loot[loot_idx] = nil;
	else
		-- loot already not in pending loot
		if LOOT_VERBOSE then SKC_Main:Print("WARN",loot_name.." was not in pending loot") end
	end
	-- check that give loot name is current loot
	if self.current_loot ~= nil and loot_name == self.current_loot.lootName then
		-- cancel / reset current loot
		self:ResetCurrentLoot();
		if LOOT_VERBOSE then SKC_Main:Print("NORMAL","Removing "..loot_name.." as the current loot item") end
	else
		if LOOT_VERBOSE then SKC_Main:Print("WARN",loot_name.." was not the current loot item") end
	end
	return;
end

function LootManager:GiveLoot(loot_name,loot_link,winner)
	-- sends loot to winner
	local success = false;
	-- TODO: check that player is online / in raid?
	-- find item
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		local _, lootName, _, _, _, _, _, _, _ = GetLootSlotInfo(i_loot);
		if lootName == loot_name then
			-- find character in raid
			for i_char = 1,40 do
				if GetMasterLootCandidate(i_loot, i_char) == winner then
					if LOOT_DIST_DISABLE or LOOT_SAFE_MODE then
						if LOOT_VERBOSE then SKC_Main:Print("IMPORTANT","Faux distribution of loot successful!") end
					else 
						GiveMasterLoot(i_loot,i_char);
					end
					success = true;
				end
			end
		end
	end
	if not success then
		SKC_Main:Print("ERROR","Failed to award "..loot_link.." to "..winner);
	end
	return success;
end

function LootManager:GiveLootToML(loot_name,loot_link)
	if not SKC_Main:isML() then 
		SKC_Main:Print("ERROR","Current player is not Master Looter.");
		return;
	end
	self:GiveLoot(loot_name,loot_link,UnitName("player"));
	return;
end

function LootManager:AwardLoot(loot_idx,winner)
	-- award actual loot to winner, perform SK (if necessary), and send alert message
	-- initialize
	local loot_name = self.current_loot.lootName;
	local loot_link = self.current_loot.lootLink;
	local DE = SKC_DB.LootPrio:GetDE(self.current_loot.lootName);
	local disenchanter, banker = SKC_DB.GuildData:GetFirstGuildRoles();
	local sk_list = self.current_loot.sk_list;
	-- check if everyone passed
	if winner == nil then
		if DE then
			if disenchanter == nil then 
				winner = UnitName("player");
			else 
				winner = disenchanter;
			end
		else
			if banker == nil then 
				winner = UnitName("player");
			else 
				winner = banker;
			end
		end
	end
	-- perform SK (if necessary) and record SK position before SK
	local prev_sk_pos = SKC_DB[sk_list]:GetPos(winner);
	if self.current_loot.decisions[winner] == LOOT_DECISION.SK then
		-- perform SK on winner (below current live bottom)
		local sk_success = SKC_DB[sk_list]:LiveSK(winner);
		if not sk_success then
			SKC_Main:Print("ERROR",sk_list.." for "..winner.." failed");
		else
			-- push new sk list to guild
			SyncPushSend(sk_list,CHANNELS.SYNC_PUSH,"GUILD",nil);
		end
		-- populate data
		SKC_Main:PopulateData();
	end
	-- send loot and mark as awarded (removes from current_loot)
	local send_success = self:GiveLoot(loot_name,loot_link,winner);
	local receiver = winner;
	if not send_success then
		-- GiveLoot failed, send item to ML
		self:GiveLootToML(loot_name,loot_link);
		receiver = UnitName("player");
	end
	-- construct outcome message
	local outcome_msg = self:ConstructOutcomeMsg(winner,loot_name,loot_link,DE,send_success,receiver)
	-- mark loot as awarded
	self:MarkLootAwarded(loot_name);
	-- send outcome message (and write to log)
	self:SendOutcomeMsg(outcome_msg);
	return;
end

function LootManager:DetermineWinner()
	-- Determines winner for current loot, awards loot to player, and sends alert message to raid
	local winner = nil;
	local winner_decision = LOOT_DECISION.PASS;
	local winner_prio = PRIO_TIERS.PASS;
	local winner_sk_pos = nil;
	local winner_roll = nil; -- random number [0,1)
	local sk_list = self.current_loot.sk_list;
	-- scan decisions and determine winner
	if LOOT_VERBOSE then
		DEFAULT_CHAT_FRAME:AddMessage(" ");
		SKC_Main:Print("IMPORTANT","DETERMINE WINNER");
		DEFAULT_CHAT_FRAME:AddMessage(" ");
	end
	for char_name,loot_decision in pairs(self.current_loot.decisions) do
		if LOOT_VERBOSE then
			SKC_Main:Print("IMPORTANT","Character: "..char_name);
			SKC_Main:Print("IMPORTANT","Loot Decision: "..LOOT_DECISION.TEXT_MAP[loot_decision]);
		end
		if loot_decision ~= LOOT_DECISION.PASS then
			local new_winner = false;
			local prio_tmp = self.current_loot.prios[char_name];
			local sk_pos_tmp = self.current_loot.sk_pos[char_name];
			local roll_tmp = self.current_loot.rolls[char_name];
			if LOOT_VERBOSE then
				SKC_Main:Print("WARN","Prio: "..prio_tmp);
				SKC_Main:Print("WARN","SK Position: "..sk_pos_tmp);
				SKC_Main:Print("WARN","Roll: "..roll_tmp);
				DEFAULT_CHAT_FRAME:AddMessage(" ");
			end
			if prio_tmp < winner_prio then
				-- higher prio, automatic winner
				new_winner = true;
			elseif prio_tmp == winner_prio then
				-- prio tie
				if loot_decision == LOOT_DECISION.SK then
					if sk_pos_tmp < winner_sk_pos then
						-- char_name is higher on SK list, new winner
						new_winner = true;
					end
				elseif loot_decision == LOOT_DECISION.ROLL then
					if roll_tmp > winner_roll then
						-- char_name won roll (tie goes to previous winner)
						new_winner = true;
					end
				end
			end
			if new_winner then
				if LOOT_VERBOSE then
					-- save previous winner
					local prev_winner = winner;
					local prev_winner_decision = winner_decision;
					local prev_winner_prio = winner_prio;
					local prev_winner_sk_pos = winner_sk_pos;
					local prev_winner_roll = winner_roll;
				end
				-- assign new winner
				winner = char_name;
				winner_decision = loot_decision;
				winner_prio = prio_tmp;
				winner_sk_pos = sk_pos_tmp;
				winner_roll = roll_tmp;
				if LOOT_VERBOSE then
					SKC_Main:Print("IMPORTANT","New Winner");
					if prev_winner == nil then
						SKC_Main:Print("WARN","Name:  "..winner);
						SKC_Main:Print("WARN","Decision:  "..LOOT_DECISION.TEXT_MAP[winner_decision]);
						SKC_Main:Print("WARN","Prio:  "..winner_prio);
						SKC_Main:Print("WARN","SK Position:  "..winner_sk_pos);
						SKC_Main:Print("WARN","Roll:  "..winner_roll);
					else
						SKC_Main:Print("WARN","Name:  "..prev_winner.." --> "..winner);
						SKC_Main:Print("WARN","Decision:  "..LOOT_DECISION.TEXT_MAP[prev_winner_decision].." --> "..LOOT_DECISION.TEXT_MAP[winner_decision]);
						SKC_Main:Print("WARN","Prio:  "..prev_winner_prio.." --> "..winner_prio);
						SKC_Main:Print("WARN","SK Position:  "..prev_winner_sk_pos.." --> "..winner_sk_pos);
						SKC_Main:Print("WARN","Roll:  "..prev_winner_roll.." --> "..winner_roll);
					end
					DEFAULT_CHAT_FRAME:AddMessage(" ");
				end
			end
		end
	end
	-- award loot to winner
	-- note, winner is nil if everyone passed
	self:AwardLoot(loot_idx,winner);
	return;
end

function LootManager:DeterminePrio(char_name)
	-- determines loot prio (PRIO_TIERS) of given char for current loot
	-- get character spec
	local spec = SKC_DB.GuildData:GetSpecIdx(char_name);
	-- start with base prio of item for given spec, then adjust based on character attributes
	local prio = SKC_DB.GLP.loot_prio:GetPrio(self.current_loot.lootName,spec);
	local loot_name = self.current_loot.lootName;
	local reserved = SKC_DB.GLP.loot_prio:GetReserved(loot_name);
	local spec_type = "MS";
	if prio == PRIO_TIERS.SK.Main.OS then spec_type = "OS" end
	-- get character main / alt status
	local status = SKC_DB.GuildData:GetData(char_name,"Status"); -- text version (Main or Alt)
	local loot_decision = self.current_loot.decisions[char_name];
	if loot_decision == LOOT_DECISION.SK then
		if reserved and status == "Alt" then
			prio = prio + PRIO_TIERS.SK.Main.OS; -- increase prio past that for any main
		end
	elseif loot_decision == LOOT_DECISION.ROLL then
		if reserved then
			prio = PRIO_TIERS.ROLL[status][spec_type];
		else
			prio = PRIO_TIERS.ROLL["Main"][spec_type];
		end
	elseif loot_decision == LOOT_DECISION.PASS then
		prio = PRIO_TIERS.PASS;
	end
	self.current_loot.prios[char_name] = prio;
	if LOOT_VERBOSE then
		SKC_Main:Print("IMPORTANT","Prio for "..char_name);
		SKC_Main:Print("WARN","spec: "..CLASS_SPEC_MAP[spec]);
		SKC_Main:Print("WARN","status: "..status);
		if reserved then
			SKC_Main:Print("WARN","reserved: TRUE");
		else
			SKC_Main:Print("WARN","reserved: FALSE");
		end
		SKC_Main:Print("WARN","loot_decision: "..LOOT_DECISION.TEXT_MAP[loot_decision]);
		SKC_Main:Print("WARN","spec_type: "..spec_type);
		SKC_Main:Print("WARN","prio: "..prio);
	end
	return;
end

function LootManager:ForceDistribution()
	-- forces loot distribution due to timeout
	SKC_Main:Print("WARN","Time expired for players to decide on "..self:GetCurrentLootLink());
	-- set all currently pending players to pass
	for char_name, decision in pairs(self.current_loot.decisions) do
		if LOOT_VERBOSE then 
			SKC_Main:Print("NORMAL","char_name: "..char_name);
			SKC_Main:Print("NORMAL","decision: "..LOOT_DECISION.TEXT_MAP[decision]);
		end
		if decision == LOOT_DECISION.PENDING then
			SKC_Main:Print("WARN",char_name.." never responded, automoatically passing");
			self.current_loot.decisions[char_name] = LOOT_DECISION.PASS;
		end
	end
	self:DetermineWinner();
	return;
end

local function ForceDistributionWrapper()
	-- wrapper because i cant figure out how to call object method from NewTimer()
	SKC_DB.LootManager:ForceDistribution();
	return;
end

local function ForceDistributionWithDelay()
	-- calls kick off function after configurable amount of delay
	SKC_DB.LootManager.current_loot_timer = C_Timer.NewTimer(LOOT_DECISION.OPTIONS.MAX_DECISION_TIME + LOOT_DECISION.OPTIONS.ML_WAIT_BUFFER, ForceDistributionWrapper);
	if LOOT_VERBOSE then SKC_Main:Print("WARN","Starting current loot timer") end
	return;
end

function LootManager:KickOff()
	-- determine if there is still pending loot that needs to be decided on
	-- MASTER LOOTER ONLY
	if not SKC_Main:isML() then
		SKC_Main:Print("ERROR","Cannot KickOff, not loot master");
		return;
	end
	for loot_idx,loot in ipairs(self.pending_loot) do
		if not loot.awarded then 
			-- store item as current item on ML side (does not trigger loot decision)
			self:SetCurrentLootByIdx(loot_idx);
			-- sends loot messages to all elligible players
			self:SendLootMsgs(loot_idx); 
			-- Start timer for when loot is automatically passed on by players that never responded
			-- Put blank message in queue so that timer starts after last message has been sent
			-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOOT,"BLANK","WHISPER",UnitName("player"),"main_queue",ForceDistributionWithDelay);
			return;
		end
	end
	SKC_Main:Print("IMPORTANT","Loot distribution complete");
	return;
end

function LootManager:ReadLootDecision(msg,sender)
	-- read loot decision from loot participant
	-- determines if all decisions received and ready to allocate loot
	-- MASTER LOOTER ONLY
	if not SKC_Main:isML() then return end
	local char_name = StripRealmName(sender);
	local loot_name, loot_decision = strsplit(",",msg,2);
	loot_decision = tonumber(loot_decision);
	-- confirm that loot decision is for current loot
	if self:GetCurrentLootName() ~= loot_name then
		SKC_Main:Print("ERROR","Received decision for item other than Current Loot");
		return;
	end
	self.current_loot.decisions[char_name] = loot_decision;
	-- calculate / save prio
	self:DeterminePrio(char_name);
	-- Write to log
	WriteToLog(
		LOG_OPTIONS["Event Type"].Options.Response,
		char_name,
		LOOT_DECISION.TEXT_MAP[loot_decision],
		self:GetCurrentLootName(),
		self:GetCurrentLootSKList(),
		self.current_loot.prios[char_name],
		self.current_loot.sk_pos[char_name],
		"",
		self.current_loot.rolls[char_name],
		""
	);
	-- print loot decision (if not pass)
	if loot_decision ~= LOOT_DECISION.PASS then
		local raid_print_msg = FormatWithClassColor(char_name).." wants to ";
		if loot_decision == LOOT_DECISION.ROLL then
			raid_print_msg = raid_print_msg.."ROLL ("..self.current_loot.rolls[char_name]..")";
		elseif loot_decision == LOOT_DECISION.SK then
			raid_print_msg = raid_print_msg..self:GetCurrentLootSKList().." ("..self.current_loot.sk_pos[char_name]..")";
		end
		raid_print_msg = raid_print_msg.." for "..self:GetCurrentLootName().." [p"..self.current_loot.prios[char_name].."]";
		-- ChatThrottleLib:SendAddonMessage("NORMAL",CHANNELS.LOOT_DECISION_PRINT,raid_print_msg,"RAID",nil,"main_queue");
	end
	-- check if still waiting on another player
	for char_name_tmp,ld_tmp in pairs(self.current_loot.decisions) do
		if ld_tmp == LOOT_DECISION.PENDING then 
			SKC_Main:Print("WARN","Waiting on: "..char_name_tmp);
			return;
		end
	end
	-- Determine winner and award loot
	self:DetermineWinner();
	return;
end