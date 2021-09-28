-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- This class manages overrides for the combat manager 5e script

local fAddNPC;
local fIsCTHidden;
local fNextActor;
local fParseAttackLine;
local parseNPCPower;

function onInit()
	fAddNPC = CombatManager2.addNPC;
	CombatManager.setCustomAddNPC(addNpcOrUnit);
	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomTurnEnd(onTurnEnd);
	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomAddBattle(addBattle);

	-- Override the default isCTHidden function to account for units
	-- which can be the friendly faction, but also can be hidden and skipped
	fIsCTHidden = CombatManager.isCTHidden;
	CombatManager.isCTHidden = isCTUnitHidden;
	fNextActor = CombatManager.nextActor;
	CombatManager.nextActor = nextActor;
	fParseAttackLine = CombatManager2.parseAttackLine;
	CombatManager2.parseAttackLine = parseAttackLine;
	fParseNPCPower = CombatManager2.parseNPCPower;
	CombatManager2.parseNPCPower = parseNPCPower;


	OOBManager.registerOOBMsgHandler(CombatManager.OOB_MSGTYPE_ENDTURN, handleEndTurn);
end

function getActiveUnitCT()
	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes()) do
		if ActorManagerKw.isUnit(nodeCombatant) or DB.getValue(nodeCombatant, "active", 0) == 1 then
			return nodeCombatant;
		end
	end
	return nil;
end

local unitSelectionHandlers = {};
function registerUnitSelectionHandler(nSlot, fHandler)
	unitSelectionHandlers[nSlot] = fHandler;
end

function selectUnit(nodeUnit, nSlot)
	if unitSelectionHandlers[nSlot] then
		unitSelectionHandlers[nSlot](nodeUnit);
	end
end

-- Custom addBattle function that adds NPCs before Units, so that units get assigned appropriately.addContextMenuItem(undefined, undefined, undefined)
function addBattle(nodeBattle)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";
	
	-- Organize npcs in the encounter into units and NPCs
	local units = {};
	local npcs = {};
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if ActorManagerKw.isUnit(sRecord) then
			table.insert(units, vNPCItem)
		else
			table.insert(npcs, vNPCItem)
		end
	end

	-- Cycle through the NPC list, and add them to the tracker
	for _, vNPCItem in pairs(npcs) do
		addBattleHelper(vNPCItem);
	end
	for _, vNPCItem in pairs(units) do
		addBattleHelper(vNPCItem);
	end
	
	Interface.openWindow("combattracker_host", "combattracker");
end

function addBattleHelper(vNPCItem)
	-- Get link database node
	local nodeNPC = nil;
	local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
	if sRecord ~= "" then
		nodeNPC = DB.findNode(sRecord);
	end
	local sName = DB.getValue(vNPCItem, "name", "");
	
	if nodeNPC then
		local aPlacement = {};
		for _,vPlacement in pairs(DB.getChildren(vNPCItem, "maplink")) do
			local rPlacement = {};
			local _, sRecord = DB.getValue(vPlacement, "imageref", "", "");
			rPlacement.imagelink = sRecord;
			rPlacement.imagex = DB.getValue(vPlacement, "imagex", 0);
			rPlacement.imagey = DB.getValue(vPlacement, "imagey", 0);
			table.insert(aPlacement, rPlacement);
		end
		
		local nCount = DB.getValue(vNPCItem, "count", 0);
		for i = 1, nCount do
			local nodeEntry = CombatManager.addNPC(sClass, nodeNPC, sName);
			if nodeEntry then
				local sFaction = DB.getValue(vNPCItem, "faction", "");
				if sFaction ~= "" then
					DB.setValue(nodeEntry, "friendfoe", "string", sFaction);
				end
				local sToken = DB.getValue(vNPCItem, "token", "");
				if sToken == "" or not Interface.isToken(sToken) then
					local sLetter = StringManager.trim(sName):match("^([a-zA-Z])");
					if sLetter then
						sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
					else
						sToken = "tokens/Medium/z.png@Letter Tokens";
					end
				end
				if sToken ~= "" then
					DB.setValue(nodeEntry, "token", "token", sToken);
					
					if aPlacement[i] and aPlacement[i].imagelink ~= "" then
						TokenManager.setDragTokenUnits(DB.getValue(nodeEntry, "space"));
						local tokenAdded = Token.addToken(aPlacement[i].imagelink, sToken, aPlacement[i].imagex, aPlacement[i].imagey);
						TokenManager.endDragTokenWithUnits(nodeEntry);
						if tokenAdded then
							TokenManager.linkToken(nodeEntry, tokenAdded);
						end
					end
				end
				
				-- Set identification state from encounter record, and disable source link to prevent overriding ID for existing CT entries when identification state changes
				local sSourceClass,sSourceRecord = DB.getValue(nodeEntry, "sourcelink", "", "");
				DB.setValue(nodeEntry, "sourcelink", "windowreference", "", "");
				DB.setValue(nodeEntry, "isidentified", "number", DB.getValue(vNPCItem, "isidentified", 1));
				DB.setValue(nodeEntry, "sourcelink", "windowreference", sSourceClass, sSourceRecord);
			else
				ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail") .. " (" .. sName .. ")");
			end
		end
	else
		ChatManager.SystemMessage(Interface.getString("ct_error_addnpcfail2") .. " (" .. sName .. ")");
	end
end

-- Override default add NPC function to handle Units.
function addNpcOrUnit(sClass, nodeActor, sName)
	local nodeEntry = nil;
	if sClass == "npc" or sClass == "reference_npc" then
		nodeEntry = addNpc(sClass, nodeActor, sName);
	elseif sClass == "unit" or sClass == "reference_unit" then
		nodeEntry = addUnit(sClass, nodeActor, sName);
	end
	return nodeEntry;
end

-- Temporary variables to allow adding a distinct effect for Souls without rewriting the whole addNpc flow.
local sSoulsToAdd = nil;
local bLetheImmune = false;
function addNpc(sClass, nodeActor, sName)
	local nodeEntry = fAddNPC(sClass, nodeActor, sName);
	if nodeEntry and sSoulsToAdd then
		SoulsManager.initializeSouls(nodeEntry, sSoulsToAdd, bLetheImmune)
	end
	sSoulsToAdd = nil;
	bLetheImmune = false;

	if EffectManagerADND then
		EffectManagerADND.updateCharEffects(nodeActor, nodeEntry);
	end

	return nodeEntry;
end

function parseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride)
	fParseNPCPower(rActor, nodePower, aEffects, bAllowSpellDataOverride);

	local sName = DB.getValue(nodePower, "name", "");
	local sName = StringManager.trim(sName:lower());
	if sName:match("^souls") then
		sSoulsToAdd = sName:match("%((%d+d%d+)%)");
	elseif sName:match("^lethe immunity") then
		bLetheImmune = true;
	end
	
	local sSoulCost = sName:match("%(costs (%d+[-+]?%d*) souls?%)");
	if sSoulCost then
		if sSoulCost then
			if not StringManager.isNumberString(sSoulCost) then
				sSoulCost = "1";
			end
			local sDisplay = DB.getValue(nodePower, "value", "");
			sDisplay = sDisplay .. "[BURN:" .. sSoulCost .. "]";
			DB.setValue(nodePower, "value", "string", sDisplay);
		end
	end

	local sDesc = DB.getValue(nodePower, "desc", ""):lower();
	sOngoingSouls = sDesc:match("automatically gains (%d+d?%d*%s?[+-]?%s?%d*) souls?");
	if sOngoingSouls and StringManager.isDiceMathString(sOngoingSouls) then
		table.insert(aEffects, "OSOULS: " .. sOngoingSouls:gsub("%s", ""));
	end

	local sSoulIncrease = sDesc:match("adds (%d+d?%d*%s?[+-]?%s?%d*) to %w+ soul count");
	if sSoulIncrease and StringManager.isDiceMathString(sSoulIncrease) then
		local sDisplay = DB.getValue(nodePower, "value", "");
		sDisplay = sDisplay .. "[SOULS:" .. sSoulIncrease:gsub("%s", "") .. "]";
		DB.setValue(nodePower, "value", "string", sDisplay);
	end
end

-- Used to indicate which commander a newly added unit should be placed under as a result of a drop.
local nodeDropCommander;
function setUnitDropCommander(nodeCommander)
	nodeDropCommander = nodeCommander;
end

function clearUnitDropCommander()
	nodeDropCommander = nilo;
end

function addUnit(sClass, nodeUnit, sName)
	if not nodeUnit then
		return nil;
	end

	-- Setup
	local aCurrentCombatants = CombatManager.getCombatantNodes();

	-- Get the name to use for this addition
	local bIsCT = (UtilityManager.getRootNodeName(nodeUnit) == CombatManager.CT_MAIN_PATH);
	local sNameLocal = sName;
	if not sNameLocal then
		sNameLocal = DB.getValue(nodeUnit, "name", "");
		if bIsCT then
			sNameLocal = CombatManager.stripCreatureNumber(sNameLocal);
		end
	end
	local sNonIDLocal = DB.getValue(nodeUnit, "nonid_name", "");
	if sNonIDLocal == "" then
		sNonIDLocal = Interface.getString("library_recordtype_empty_nonid_npc");
	elseif bIsCT then
		sNonIDLocal = CombatManager.stripCreatureNumber(sNonIDLocal);
	end
	
	local nLocalID = DB.getValue(nodeUnit, "isidentified", 1);
	if not bIsCT then
		local sSourcePath = nodeUnit.getPath()
		local aMatches = {};
		for _,v in pairs(aCurrentCombatants) do
			local _,sRecord = DB.getValue(v, "sourcelink", "", "");
			if sRecord == sSourcePath then
				table.insert(aMatches, v);
			end
		end
		if #aMatches > 0 then
			nLocalID = 0;
			for _,v in ipairs(aMatches) do
				if DB.getValue(v, "isidentified", 1) == 1 then
					nLocalID = 1;
				end
			end
		end
	end
	
	local nodeLastMatch = nil;
	if sNameLocal:len() > 0 then
		-- Determine the number of Units with the same name
		local nNameHigh = 0;
		local aMatchesWithNumber = {};
		local aMatchesToNumber = {};
		for _,v in pairs(aCurrentCombatants) do
			local sEntryName = DB.getValue(v, "name", "");
			local sTemp, sNumber = CombatManager.stripCreatureNumber(sEntryName);
			if sTemp == sNameLocal then
				nodeLastMatch = v;
				
				local nNumber = tonumber(sNumber) or 0;
				if nNumber > 0 then
					nNameHigh = math.max(nNameHigh, nNumber);
					table.insert(aMatchesWithNumber, v);
				else
					table.insert(aMatchesToNumber, v);
				end
			end
		end
	
		-- If multiple Units of same name, then figure out whether we need to adjust the name based on options
		local sOptNNPC = OptionsManager.getOption("NNPC");
		if sOptNNPC ~= "off" then
			local nNameCount = #aMatchesWithNumber + #aMatchesToNumber;
			
			for _,v in ipairs(aMatchesToNumber) do
				local sEntryName = DB.getValue(v, "name", "");
				local sEntryNonIDName = DB.getValue(v, "nonid_name", "");
				if sEntryNonIDName == "" then
					sEntryNonIDName = Interface.getString("library_recordtype_empty_nonid_npc");
				end
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nNameHigh);
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sEntryName);
					DB.setValue(v, "name", "string", sNewName);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nSuffix);
				end
			end
			
			if nNameCount > 0 then
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					sNameLocal = sNameLocal .. " " .. nNameHigh;
					sNonIDLocal = sNonIDLocal .. " " .. nNameHigh;
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sNameLocal);
					sNameLocal = sNewName;
					sNonIDLocal = sNonIDLocal .. " " .. nSuffix;
				end
			end
		end
	end
	
	DB.createNode(CombatManager.CT_LIST);
	local nodeEntry = DB.createChild(CombatManager.CT_LIST);
	if not nodeEntry then
		return nil;
	end
	DB.copyNode(nodeUnit, nodeEntry);

	-- Remove any combatant specific information
	DB.setValue(nodeEntry, "active", "number", 0);
	DB.setValue(nodeEntry, "tokenrefid", "string", "");
	DB.setValue(nodeEntry, "tokenrefnode", "string", "");
	DB.deleteChildren(nodeEntry, "effects");
	
	-- Set the final name value
	DB.setValue(nodeEntry, "name", "string", sNameLocal);
	DB.setValue(nodeEntry, "nonid_name", "string", sNonIDLocal);
	DB.setValue(nodeEntry, "isidentified", "number", nLocalID);
	
	-- Lock NPC record view by default when copying to CT
	DB.setValue(nodeEntry, "locked", "number", 1);

	-- Set up the CT specific information
	DB.setValue(nodeEntry, "link", "windowreference", "", ""); -- Workaround to force field update on client; client does not pass network update to other clients if setValue creates value node with default value
	DB.setValue(nodeEntry, "link", "windowreference", "reference_unit", "");
	DB.setValue(nodeEntry, "friendfoe", "string", "foe");
	if not bIsCT then
		DB.setValue(nodeEntry, "sourcelink", "windowreference", "reference_unit", nodeUnit.getPath());
	end
	
	-- Calculate space/reach
	DB.setValue(nodeEntry, "space", "number", 1);
	DB.setValue(nodeEntry, "reach", "number", 1);

	-- Set default letter token, if no token defined
	local sToken = DB.getValue(nodeUnit, "token", "");
	if sToken == "" or not Interface.isToken(sToken) then
		local sLetter = StringManager.trim(sNameLocal):match("^([a-zA-Z])");
		if sLetter then
			sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
		else
			sToken = "tokens/Medium/z.png@Letter Tokens";
		end
		DB.setValue(nodeEntry, "token", "token", sToken);
	end

	-- set casualty die (aka hit points)
	local nHP = DB.getValue(nodeUnit, "casualties", 0);
	DB.setValue(nodeEntry, "hptotal", "number", nHP);

	-- TODO: Handle traits that might add effects here
	local aTraits = DB.getChildren(nodeEntry, "traits");
	local aEffects = {};
	for _,v in pairs(aTraits) do
		local traitname = DB.getValue(v, "name", "");
		if traitname then
			local sLower = traitname:lower();
			local sEffect = DataKW.traitdata[sLower];
			if sEffect then
				EffectManager.addEffect("", "", nodeEntry, { sName = traitname .. "; " .. sEffect, nDuration = 0, nGMOnly = 0 }, false);
			end
		end
	end

	-- Decode traits
	for _,v in pairs(aTraits) do
		parseUnitTrait(rActor, v);
	end

	-- try to find the Commander in the CT and use their initiative and faction
	-- else leave initiative blank and faction = foe
	local nodeCommander = nodeDropCommander or ActorManagerKw.getCommanderCT(nodeEntry);
	if nodeCommander then
	-- todo rework commander stuff
		local init = DB.getValue(nodeCommander, "initresult", 0);
		local faction = DB.getValue(nodeCommander, "friendfoe", "foe");

		-- The -0.1 is so that the untis are always listed after the commander
		-- This fails if there are multiple commanders with the same initiative
		-- So the GM should adjust commander inits so as not to do that.
		DB.setValue(nodeEntry, "initresult", "number", init - 0.1);
		DB.setValue(nodeEntry, "friendfoe", "string", faction);
		DB.setValue(nodeEntry, "commander_link", "windowreference", "npc", DB.getPath(nodeCommander));
	end
	
	return nodeEntry;
end

function isUnitOwnedByLastCommander(nodeUnit)
	local ctNode = DB.findNode(DB.getPath(CombatManager.CT_MAIN_PATH, "lastcommander"));
	if not ctNode then
		return false;
	end
	local lastCommanderNode = DB.findNode(ctNode.getValue() or "");
	if lastCommanderNode then
		local sCommanderName = DB.getValue(lastCommanderNode, "name", "")
		if sCommanderName ~= "" then
			local sUnitCommander = DB.getValue(nodeUnit, "commander", "");
			if sUnitCommander == sCommanderName then
				return true;
			end
		end
	end
	return false;
end

function isCTUnitHidden(vEntry)
	local isHidden = fIsCTHidden(vEntry);

	-- replicate argument checking
	local nodeCT = nil;
	if type(vEntry) == "string" then
		nodeCT = DB.findNode(vEntry);
	elseif type(vEntry) == "databasenode" then
		nodeCT = vEntry;
	end
	if not nodeCT then
		return false;
	end

	local bIsUnit = ActorManagerKw.isUnit(nodeCT);
	if bIsUnit then
		local lastCommandersUnit = isUnitOwnedByLastCommander(nodeCT);
		local hide = DB.getValue(nodeCT, "hide", 0) == 1;
		-- If the last commander to act was this unit's commander, this unit should always be shown
		if lastCommandersUnit then return false; end
		-- else return whether this unit is hidden or not
		return isHidden or hide;
	end

	return isHidden;
end

function onTurnStart(nodeCT)
	-- Update Exposed for all tokens
	WarfareManager.onTurnStart(nodeCT)
end

function onTurnEnd(nodeCT)
	-- Set the activated property so we can apply the token widget 
	DB.setValue(nodeCT, "activated", "number", 1);
end

function onRoundStart(nCurRound)
	-- This gets set to the first unit on the combat tracker
	-- it is ONLY used to pass to the warfare manager so that the manager can get
	-- which image the token is on in order to check if any ranks have collapsed
	-- CAVEAT: This will fail if units are on multiple maps. So just don't do that.
	local anyUnit = nil;

	local aCurrentCombatants = CombatManager.getCombatantNodes();
	for _,v in pairs(aCurrentCombatants) do
		if ActorManagerKw.isUnit(v) then
			DB.setValue(v, "activated", "number", 0);
			if anyUnit == nil then
				anyUnit = v;
			end
		end
	end

	WarfareManager.onNewRound(anyUnit);
end

-- todo remove?
-- We have to override this whole function just to add the one little
-- check in the middle to see if the actor is a unit
-- and if they are a unit, ignore the 'friends are always visible' clause
-- 5e doesn't override this function, but another extension might, and this could
-- definitely cause issues.
function nextActor(bSkipBell, bNoRoundAdvance)
	if not Session.IsHost then
		return;
	end

	local nodeActive = CombatManager.getActiveCT();
	local nIndexActive = 0;
	
	-- Check the skip hidden NPC option
	local bSkipHidden = OptionsManager.isOption("CTSH", "on");
	
	-- Determine the next actor
	local nodeNext = nil;
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries > 0 then
		if nodeActive then
			for i = 1,#aEntries do
				if aEntries[i] == nodeActive then
					nIndexActive = i;
					break;
				end
			end
		end
		local bIsUnit = ActorManagerKw.isUnit(aEntries[nIndexActive+1]);
		-- Force units to always check if they're hidden
		if bIsUnit or bSkipHidden then
			local nIndexNext = 0;
			for i = nIndexActive + 1, #aEntries do
				if not bIsUnit and DB.getValue(aEntries[i], "friendfoe", "") == "friend" then
					nIndexNext = i;
					break;
				else
					if not CombatManager.isCTHidden(aEntries[i]) then
						nIndexNext = i;
						break;
					end
				end
			end
			if nIndexNext > nIndexActive then
				nodeNext = aEntries[nIndexNext];
				for i = nIndexActive + 1, nIndexNext - 1 do
					CombatManager.showTurnMessage(aEntries[i], false);
				end
			end
		else
			nodeNext = aEntries[nIndexActive + 1];
		end
	end

	-- If next actor available, advance effects, activate and start turn
	if nodeNext then
		-- End turn for current actor
		CombatManager.onTurnEndEvent(nodeActive);
	
		-- Process effects in between current and next actors
		if nodeActive then
			CombatManager.onInitChangeEvent(nodeActive, nodeNext);
		else
			CombatManager.onInitChangeEvent(nil, nodeNext);
		end
		
		-- Start turn for next actor
		CombatManager.requestActivation(nodeNext, bSkipBell);
		CombatManager.onTurnStartEvent(nodeNext);
	elseif not bNoRoundAdvance then
		if bSkipHidden then
			for i = nIndexActive + 1, #aEntries do
				CombatManager.showTurnMessage(aEntries[i], false);
			end
		end
		CombatManager.nextRound(1);
	end
end

function handleEndTurn(msgOOB)
	local rActor = ActorManager.resolveActor(CombatManager.getActiveCT());
	local nodeActor = ActorManager.getCreatureNode(rActor);
	local isUnit = ActorManagerKw.isUnit(nodeActor);
	if isUnit then		
		-- It's dumb that I have to get the commander node, resolve actor, then re-get the creature node
		-- but that's the only way getOwner() worked correctly. It didn't work directly off of 
		-- commanderNode
		local commanderNode = ActorManagerKw.getCommanderCT(nodeActor);
		local rCommander = ActorManager.resolveActor(commanderNode);
		local nodeCommander = ActorManager.getCreatureNode(rCommander);
		if nodeCommander and nodeCommander.getOwner() == msgOOB.user then
			CombatManager.nextActor();
		end
	-- This is the default action
	elseif nodeActor and nodeActor.getOwner() == msgOOB.user then
		CombatManager.nextActor();
	end
end

function parseUnitTrait(rUnit, nodeTrait)
	local sDisplay = DB.getValue(nodeTrait, "name", "");
	local aDisplayOptions = {};
	
	local sName = StringManager.trim(sDisplay:lower());

	-- Handle all the other traits and actions (i.e. look for recharge, attacks, damage, saves, reach, etc.)
	local aAbilities = PowerManagerKw.parseUnitTrait(nodeTrait);
	for _,v in ipairs(aAbilities) do			
		if v.type == "unitsavedc" then
			local line =  "[TEST:";
			if v.savemod then
				line = line .. " DC " .. v.savemod;
			end
			if DataCommon.ability_ltos[v.stat] then
				line = line .. " " .. DataCommon.ability_ltos[v.stat] .. "]"
			else
			end
			
			table.insert(aDisplayOptions, line);
		
		elseif v.type == "damage" then
			local aDmgDisplay = {};
			for _,vClause in ipairs(v.clauses) do
				local sDmg = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
				if vClause.dmgtype and vClause.dmgtype ~= "" then
					sDmg = sDmg .. " " .. vClause.dmgtype;
				end
				table.insert(aDmgDisplay, sDmg);
			end
			table.insert(aDisplayOptions, string.format("[DMG: %s]", table.concat(aDmgDisplay, " + ")));
			
		elseif v.type == "heal" then
			local aHealDisplay = {};
			for _,vClause in ipairs(v.clauses) do
				local sHeal = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
				table.insert(aHealDisplay, sHeal);
			end
			
			local sHeal = table.concat(aHealDisplay, " + ");
			if v.subtype then
				sHeal = sHeal .. " " .. v.subtype;
			end
			
			table.insert(aDisplayOptions, string.format("[HEAL: %s]", sHeal));
		
		elseif v.type == "effect" then
			table.insert(aDisplayOptions, EffectManager5E.encodeEffectForCT(v));
		
		end

		-- Remove recharge in title, and move to details
		local sRecharge = string.match(sName, "recharge (%d)");
		if sRecharge then
			sDisplay = string.gsub(sDisplay, "%s?%([Rr]echarge %d[-�]*%d?%)", "");
			table.insert(aDisplayOptions, "[R:" .. sRecharge .. "]");
		end
	end
	
	-- Set the value field to the short version
	if #aDisplayOptions > 0 then
		sDisplay = sDisplay .. " " .. table.concat(aDisplayOptions, " ");
	end
	DB.setValue(nodeTrait, "value", "string", sDisplay);
end

function parseAttackLine(sLine)
	local rPower = fParseAttackLine(sLine);


	local nIntroStart, nIntroEnd, sName = sLine:find("([^%[]*)[%[]?");
	if nIntroStart then
		if not rPower.name then
			rPower.name = StringManager.trim(sName);
		end
		if not rPower.aAbilities then
			rPower.aAbilities = {};
		end

		nIndex = nIntroEnd;
		local nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nIntroEnd);
		while nAbilityStart do
			if sAbility:sub(1,5) == "TEST:" and #sAbility > 5 then
				local aWords = StringManager.parseWords(sAbility:sub(7));
				
				local rSave = {};
				rSave.sType = "unitsavedc";
				local sDC, sStat = sAbility:sub(7):match("DC (%d+)%s*(%a+)");
				rSave.nStart = nAbilityStart + 1;
				rSave.nEnd = nAbilityEnd;
				rSave.stat = DataCommon.ability_stol[sStat] or "";
				rSave.label = rPower.name;
				if sDC then
					rSave.savemod = tonumber(sDC) or 0;
				end
				table.insert(rPower.aAbilities, rSave);
			elseif sAbility:sub(1,5) == "BURN:" then
				local rSoulBurn = {};
				rSoulBurn.sType = "burn";
				rSoulBurn.nStart = nAbilityStart + 1;
				rSoulBurn.nEnd = nAbilityEnd;
				rSoulBurn.label = rPower.name;
				rSoulBurn.nBurn = tonumber(sAbility:sub(6):match("(%d+)")) or 0;
				table.insert(rPower.aAbilities, rSoulBurn);
			elseif sAbility:sub(1,6) == "SOULS:" then
				local rSoulGain = {};
				rSoulGain.sType = "souls";
				rSoulGain.nStart = nAbilityStart + 1;
				rSoulGain.nEnd = nAbilityEnd;
				rSoulGain.label = "Increase Soul Count";
				rSoulGain.sTargeting = "self";
				rSoulGain.aDice, rSoulGain.nMod = StringManager.convertStringToDice(sAbility:sub(7));
				table.insert(rPower.aAbilities, rSoulGain);
			end
			
			nAbilityStart, nAbilityEnd, sAbility = sLine:find("%[([^%]]+)%]", nAbilityEnd + 1);
		end
	end

	return rPower;
end