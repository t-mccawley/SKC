--------------------------------------
-- LootManager
--------------------------------------
-- Datastructure used by master looter to manage loot items and to determine winners
--------------------------------------
-- DEFINITION + CONSTRUCTOR
--------------------------------------
LootManager = {
	master_looter = nil, -- name of the master looter
	current_loot = nil, -- Loot object of loot that is being decided on
	current_loot_timer = nil, -- timer used to track when decision time has expired
}; 
LootManager.__index = LootManager;

function LootManager:new(loot_manager)
	if loot_manager == nil then
		-- initalize fresh
		local obj = {};
		obj.master_looter = nil;
		obj.current_loot = Loot:new(nil);
		obj.current_loot_timer = nil;
		setmetatable(obj,LootManager);
		return obj;
	else
		-- reset timer
		loot_manager.current_loot_timer = nil;
		-- set metatable of existing table
		loot_manager.current_loot = Loot:new(loot_manager.current_loot);
		setmetatable(loot_manager,LootManager);
		return loot_manager;
	end
end
--------------------------------------
-- METHODS
--------------------------------------
function LootManager:Reset()
	-- reset loot manager
	if self.current_loot_timer ~= nil then self.current_loot_timer:Cancel() end
	self.current_loot_timer = nil;
	self.current_loot = nil;
	self.master_looter = nil;
	return;
end

function LootManager:GetCurrentLootName()
	if self.current_loot == nil then
		SKC:Error("Current loot not set");
		return nil;
	end
	return self.current_loot.lootName;
end

function LootManager:GetCurrentLootLink()
	if self.current_loot == nil then
		SKC:Error("Current loot not set");
		return nil;
	end
	return self.current_loot.lootLink;
end

function LootManager:GetCurrentOpenRoll()
	if self.current_loot == nil then
		SKC:Error("Current loot not set");
		return nil;
	end
	return self.current_loot.open_roll;
end

function LootManager:GetCurrentLootSKList()
	if self.current_loot == nil then
		SKC:Error("Current loot not set");
		return nil;
	end
	return self.current_loot.sk_list;
end

function LootManager:AddLoot(item_name,item_link)
	-- add loot as new current_loot
	-- check if current loot is not empty
	if self.current_loot ~= nil then
		SKC:Error("Current loot is not empty");
	end
	local open_roll =SKC.db.char.LP:GetOpenRoll(item_name);
	local sk_list =SKC.db.char.LP:GetSKList(item_name);
	self.current_loot = Loot:new(nil,item_name,item_link,open_roll,sk_list);
	return;
end

function LootManager:AddCharacter(char_name)
	-- add given character as pending loot decision for current_loot
	-- set player decision to pending
	self.current_loot.decisions[char_name] = SKC.LOOT_DECISION.PENDING;
	-- save player position
	self.current_loot.sk_pos[char_name] = SKC.db.char[self.current_loot.sk_list]:GetPos(char_name);
	-- roll for character
	self.current_loot.rolls[char_name] = math.random(100); -- random number between 1 and 100
	return;
end

function LootManager:KickOff()
	-- initiates loot decision
	-- MASTER LOOTER ONLY
	if not SKC:isML() then
		SKC:Error("Cannot KickOff, not master looter");
		return;
	end
	-- check that item exists
	if self.current_loot == nil then
		SKC:Error("Cannot KickOff, current_loot does not exist");
		return;
	end
	-- sends loot messages to all elligible players
	self:SendLootMsgs();
	-- Start timer for when loot is automatically passed on by players that never responded
	-- Put blank message in queue so that timer starts after last message has been sent
	SKC:Send("BLANK",SKC.CHANNELS.LOOT,"WHISPER",UnitName("player"),ForceDistributionWithDelay);
	return;
end

function LootManager:SendLootMsgs()
	-- send loot message to all elligible characters on LOOT
	-- construct message
	local loot_msg = self.current_loot.lootName..","..
		self.current_loot.lootLink..","..
		SKC:BoolToStr(self.current_loot.open_roll)..","..	
		self.current_loot.sk_list;
	-- scan elligible players and send message
	for char_name,_ in pairs(self.current_loot.decisions) do
		SKC:Send(loot_msg,SKC.CHANNELS.LOOT,"WHISPER",char_name);
	end
	return;
end

function LootManager:StartPersonalLootDecision()
	if self.current_loot == nil then 
		SKC:Error("No loot to decide on");
		return;
	end
	-- Begins personal loot decision process
	local sk_list = self:GetCurrentLootSKList();
	local open_roll = self:GetCurrentOpenRoll();
	local alert_msg = "Would you like to "..sk_list.." for "..self:GetCurrentLootLink().."?";
	SKC:Alert(alert_msg);
	-- Trigger GUI
	SKC:DisplayLootDecisionGUI(open_roll,sk_list);
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
			SKC:Error("Still waiting on loot decision for "..self:GetCurrentLootLink());
			return true;
		end
	end
end

function LootManager:ReadLootMsg(msg,sender)
	-- reads loot message on LOOT (not necessarily ML)
	-- saves item as current_loot
	if msg == "BLANK" then return end
	local item_name, item_link, open_roll, sk_list = strsplit(",",msg,4);
	open_roll = SKC:BoolOut(open_roll);
	if not SKC:isML() then
		-- reset loot and add item
		self:Reset();
		self.current_loot = Loot:new(nil,item_name,item_link,open_roll,sk_list);
	else
		-- current loot already exists, just check that item matches
		if item_name ~= self.current_loot.lootName then
			SKC:Error("Received loot message for item that is not current_loot!");
		end
	end
	-- save ML
	self.master_looter = SKC:StripRealmName(sender);
	-- Check that SKC is active for client
	if not SKC:CheckActive() then
		-- Automatically pass
		SKC:Warn("SKC is not active, automatically passing");
		self:SendLootDecision(SKC.LOOT_DECISION.PASS);
	else
		-- start GUI
		self:StartPersonalLootDecision();
	end
	return;
end

function LootManager:SendLootDecision(loot_decision)
	-- send decision to master looter
	local msg = self:GetCurrentLootName()..","..loot_decision;
	SKC:Send(msg,SKC.CHANNELS.LOOT_DECISION,"WHISPER",self.master_looter);
	return;
end

function LootManager:ConstructDecisionMsg(char_name,loot_decision)
	-- constructs + sends decision message and writes to log
	-- Write to log
	SKC:WriteToLog(
		SKC.LOG_OPTIONS["Event Type"].Options.Response,
		char_name,
		SKC.LOOT_DECISION.TEXT_MAP[loot_decision],
		self:GetCurrentLootName(),
		self:GetCurrentLootSKList(),
		self.current_loot.prios[char_name],
		self.current_loot.sk_pos[char_name],
		"",
		self.current_loot.rolls[char_name],
		""
	);
	-- send message (if not pass)
	if loot_decision ~= SKC.LOOT_DECISION.PASS then
		local decision_msg = SKC:FormatWithClassColor(char_name).." [p"..self.current_loot.prios[char_name].."] wants to ";
		if loot_decision == SKC.LOOT_DECISION.ROLL then
			decision_msg = decision_msg.."ROLL ("..self.current_loot.rolls[char_name]..")";
		elseif loot_decision == SKC.LOOT_DECISION.SK then
			decision_msg = decision_msg..self:GetCurrentLootSKList().." ("..self.current_loot.sk_pos[char_name]..")";
		end
		decision_msg = decision_msg.." for "..self:GetCurrentLootName();
		SKC:Send(decision_msg,SKC.CHANNELS.LOOT_DECISION_PRINT,"RAID");
	end
end

function LootManager:ConstructOutcomeMsg(winner,loot_name,loot_link,DE,send_success,receiver)
	-- constructs outcome message and writes to log
	local winner_with_color = SKC:FormatWithClassColor(winner);
	local event_type_log = SKC.LOG_OPTIONS["Event Type"].Options.Winner;
	local sk_list = self:GetCurrentLootSKList();
	local winner_decision = self.current_loot.decisions[winner];
	local msg = winner_with_color.." [p"..self.current_loot.prios[winner].."] won "..loot_link.." by ";
	if winner_decision == SKC.LOOT_DECISION.SK then
		msg = msg..sk_list.." ("..self.current_loot.sk_pos[winner].." --> "..SKC.db.char[sk_list]:GetPos(winner)..")!";
	elseif winner_decision == SKC.LOOT_DECISION.ROLL then
		msg = msg.."ROLL ("..self.current_loot.rolls[winner]..")!";
	else
		-- Everyone passed
		msg = "Everyone passed on "..loot_link..", awarded to "..winner_with_color;
		if DE then
			msg = msg.." to be DISENCHANTED."
			event_type_log = SKC.LOG_OPTIONS["Event Type"].Options.DE;
		else
			msg = msg.." for the GUILD BANK."
			event_type_log = SKC.LOG_OPTIONS["Event Type"].Options.GB;
		end
	end
	if not send_success then
		msg = msg.." Send failed, item given to master looter."
	end
	-- Write outcome to log
	SKC:WriteToLog( 
		event_type_log,
		winner,
		SKC.LOOT_DECISION.TEXT_MAP[winner_decision],
		loot_name,
		sk_list,
		self.current_loot.prios[winner],
		self.current_loot.sk_pos[winner],
		SKC.db.char[sk_list]:GetPos(winner),
		self.current_loot.rolls[winner],
		receiver
	);
	return msg;
end

function LootManager:CheckIfLootExists(loot_name)
	-- returns true if the loot exists in current loot window
	for i_loot = 1, GetNumLootItems() do
		-- get item data
		local _, lootName, _, _, _, _, _, _, _ = GetLootSlotInfo(i_loot);
		if lootName == loot_name then
			return(true);
		end
	end
	return(false);
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
					if SKC.DEV.LOOT_DIST_DISABLE or SKC.DEV.LOOT_SAFE_MODE then
						SKC:Alert("GiveLoot success! (FAKE)");
					else 
						GiveMasterLoot(i_loot,i_char);
						-- TODO:
						-- Log the winner to raid AND to log
						-- Call this function to give loot
						-- Start a timer here to wait for ~1-2s
						-- At end of timer, check if item still exists in loot window
						-- If item still exists, give to ML (do not perform SK)
						-- ML give should also do this check with same confirm delay after (can cause infinite loop)
						-- If item doesnt exist, give to winner (perform SK)
						-- only log / print out who received item once item is confirmed to no longer be in loot window
					end
					success = true;
				end
			end
		end
	end
	if not success then
		SKC:Error("Failed to award "..loot_link.." to "..winner);
	end
	return success;
end

function LootManager:GiveLootToML(loot_name,loot_link,event_type)
	-- sends loot to ML (and optionally writes to log)
	if not SKC:isML() then 
		SKC:Error("Current player is not Master Looter.");
		return;
	end
	self:GiveLoot(loot_name,loot_link,UnitName("player"));
	if event_type ~= nil then
		SKC:WriteToLog( 
			event_type,
			UnitName("player"),
			"ML",
			loot_name,
			"",
			"",
			"",
			"",
			"",
			UnitName("player")
		);
	end
	return;
end

function LootManager:AwardLoot(loot_idx,winner)
	-- award actual loot to winner, perform SK (if necessary), and send alert message
	-- initialize
	local loot_name = self.current_loot.lootName;
	local loot_link = self.current_loot.lootLink;
	local DE =SKC.db.char.LP:GetDE(self.current_loot.lootName);
	local disenchanter, banker = SKC.db.char.GD:GetFirstGuildRolesInRaid();
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
	local prev_sk_pos = SKC.db.char[sk_list]:GetPos(winner);
	if self.current_loot.decisions[winner] == SKC.LOOT_DECISION.SK then
		-- perform SK on winner (below current live bottom)
		local sk_success = SKC.db.char[sk_list]:LiveSK(winner);
		if not sk_success then
			SKC:Error(sk_list.." for "..winner.." failed");
		end
		-- populate data
		SKC:PopulateData();
	end
	-- give loot to winner
	local send_success = self:GiveLoot(loot_name,loot_link,winner);
	local receiver = winner;
	if not send_success then
		-- GiveLoot failed, send item to ML
		self:GiveLootToML(loot_name,loot_link);
		receiver = UnitName("player");
	end
	-- construct outcome message and write to log
	local outcome_msg = self:ConstructOutcomeMsg(winner,loot_name,loot_link,DE,send_success,receiver)
	-- reset loot
	self:Reset();
	-- send outcome message
	SKC:Send(outcome_msg,SKC.CHANNELS.LOOT_OUTCOME_PRINT,"RAID");
	return;
end

function LootManager:DetermineWinner()
	-- Determines winner for current loot, awards loot to player, and sends alert message to raid
	local winner = nil;
	local winner_decision = SKC.LOOT_DECISION.PASS;
	local winner_prio = SKC.PRIO_TIERS.PASS;
	local winner_sk_pos = nil;
	local winner_roll = nil; -- random number [0,1)
	local sk_list = self.current_loot.sk_list;
	-- scan decisions and determine winner
	for char_name,loot_decision in pairs(self.current_loot.decisions) do
		if loot_decision ~= SKC.LOOT_DECISION.PASS then
			local new_winner = false;
			local prio_tmp = self.current_loot.prios[char_name];
			local sk_pos_tmp = self.current_loot.sk_pos[char_name];
			local roll_tmp = self.current_loot.rolls[char_name];
			if prio_tmp < winner_prio then
				-- higher prio, automatic winner
				new_winner = true;
			elseif prio_tmp == winner_prio then
				-- prio tie
				if loot_decision == SKC.LOOT_DECISION.SK then
					if sk_pos_tmp < winner_sk_pos then
						-- char_name is higher on SK list, new winner
						new_winner = true;
					end
				elseif loot_decision == SKC.LOOT_DECISION.ROLL then
					if roll_tmp > winner_roll then
						-- char_name won roll (tie goes to previous winner)
						new_winner = true;
					end
				end
			end
			if new_winner then
				-- assign new winner
				winner = char_name;
				winner_decision = loot_decision;
				winner_prio = prio_tmp;
				winner_sk_pos = sk_pos_tmp;
				winner_roll = roll_tmp;
			end
		end
	end
	-- award loot to winner
	-- note, winner is nil if everyone passed
	self:AwardLoot(loot_idx,winner);
	return;
end

function LootManager:DeterminePrio(char_name)
	-- determines loot prio (SKC.PRIO_TIERS) of given char for current loot
	-- get character spec
	local spec = SKC.db.char.GD:GetSpecIdx(char_name);
	-- start with base prio of item for given spec, then adjust based on character attributes
	local loot_name = self.current_loot.lootName;
	local prio = SKC.db.char.LP:GetPrio(loot_name,spec);
	local reserved = SKC.db.char.LP:GetReserved(loot_name);
	local spec_type = "MS";
	if prio == SKC.PRIO_TIERS.SK.Main.OS then spec_type = "OS" end
	-- get character main / alt status
	local status = SKC.db.char.GD:GetData(char_name,"Status"); -- text version (Main or Alt)
	local loot_decision = self.current_loot.decisions[char_name];
	if loot_decision == SKC.LOOT_DECISION.SK then
		if reserved and status == "Alt" then
			prio = prio + SKC.PRIO_TIERS.SK.Main.OS; -- increase prio past that for any main
		end
	elseif loot_decision == SKC.LOOT_DECISION.ROLL then
		if reserved then
			prio = SKC.PRIO_TIERS.ROLL[status][spec_type];
		else
			prio = SKC.PRIO_TIERS.ROLL["Main"][spec_type];
		end
	elseif loot_decision == SKC.LOOT_DECISION.PASS then
		prio = SKC.PRIO_TIERS.PASS;
	end
	self.current_loot.prios[char_name] = prio;
	return;
end

function LootManager:ForceDistribution()
	-- forces loot distribution due to timeout
	SKC:Warn("Time expired for players to decide on "..self:GetCurrentLootLink());
	-- set all currently pending players to pass
	for char_name, decision in pairs(self.current_loot.decisions) do
		if decision == SKC.LOOT_DECISION.PENDING then
			SKC:Warn(char_name.." never responded, automoatically passing");
			self.current_loot.decisions[char_name] = SKC.LOOT_DECISION.PASS;
		end
	end
	self:DetermineWinner();
	return;
end

local function ForceDistributionWrapper()
	-- wrapper because i cant figure out how to call object method from NewTimer()
	SKC:Debug("ForceDistributionWrapper",SKC.DEV.VERBOSE.LOOT);
	SKC.db.char.LM:ForceDistribution();
	return;
end

function ForceDistributionWithDelay()
	-- calls kick off function after configurable amount of delay
	SKC.db.char.LM.current_loot_timer = C_Timer.NewTimer(SKC.db.char.GLP:GetLootDecisionTime() + 5, ForceDistributionWrapper);
	SKC:Debug("Starting current loot timer",SKC.DEV.VERBOSE.LOOT);
	return;
end

function LootManager:ReadLootDecision(msg,sender)
	-- read loot decision from loot participant on LOOT_DECISION
	-- determines if all decisions received and ready to award loot
	-- MASTER LOOTER ONLY
	if not SKC:isML() then return end
	local char_name = SKC:StripRealmName(sender);
	local loot_name, loot_decision = strsplit(",",msg,2);
	loot_decision = tonumber(loot_decision);
	-- confirm that loot decision is for current loot
	if self:GetCurrentLootName() ~= loot_name then
		SKC:Error("Received decision for item other than Current Loot");
		return;
	end
	self.current_loot.decisions[char_name] = loot_decision;
	-- calculate / save prio
	self:DeterminePrio(char_name);
	-- send decision message + write to log
	self:ConstructDecisionMsg(char_name,loot_decision);
	-- check if still waiting on another player
	for char_name_tmp,ld_tmp in pairs(self.current_loot.decisions) do
		if ld_tmp == SKC.LOOT_DECISION.PENDING then 
			SKC:Warn("Waiting on: "..char_name_tmp);
			return;
		end
	end
	-- Determine winner and award loot
	self:DetermineWinner();
	return;
end