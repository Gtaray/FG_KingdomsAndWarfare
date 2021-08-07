-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATTACKSTATE = "applyattackstate";
OOB_MSGTYPE_NOTIFYHARROW = "applyharrow"
OOB_MSGTYPE_ADDHARROWEFFECT= "addharroweffect"

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATTACKSTATE, handleApplyAttackState);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_NOTIFYHARROW, handleHarrow);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ADDHARROWEFFECT, handleAddHarrowEffect);

    ActionsManager.registerModHandler("harrowing", modHarrowing);
    ActionsManager.registerResultHandler("harrowing", onHarrowing)
end

function performRoll(draginfo, rUnit, rTarget, rAction)
	local rRoll = getRoll(rUnit, rTarget, rAction);
	
	ActionsManager.performAction(draginfo, rUnit, rRoll);
end

function getRoll(rUnit, rTarget, rAction)
	local bADV = false;
	local bDIS = false;
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "harrowing";
	rRoll.aDice = { "d20" };
	rRoll.nMod = ActorManagerKw.getAbilityBonus(rUnit, "morale") or 0;
	if rAction.nTargetDC then
		rRoll.nTarget = rAction.nTargetDC
	else
		rRoll.nTarget = 10 + (ActorManagerKw.getUnitTier(rTarget) or 0)
	end

	-- Build the description label
    rRoll.sDesc = "[TEST] Morale";
    if rAttacker and rAttacker.sName then
        rRoll.sDesc = rRoll.sDesc .. " from " .. rAttacker.sName;
    end

	-- Add advantage/disadvantage tags
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end

	-- Track if this effect came from this unit, or a different unit
	if rTarget and rTarget.sCreatureNode then
		rRoll.sDesc = rRoll.sDesc .. " [ORIGIN:" .. rTarget.sCreatureNode .. "]";
	elseif rAction.sOrigin then
		rRoll.sDesc = rRoll.sDesc .. " [ORIGIN:" .. rAction.sOrigin .. "]";
	end

	return rRoll;
end

function modHarrowing(rSource, rTarget, rRoll)
    local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

    local bADV = false;
	local bDIS = false;
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");		
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

	local aTestFilter = { "morale", "harrowing" };

    if rSource then
        -- Get attack effect modifiers
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, sModStat, false, {}, rTarget);
		if (nEffectCount > 0) then
			bEffects = true;
		end

		if EffectManager5E.hasEffect(rSource, "ADVTEST", rTarget) then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVTEST", aTestFilter, rTarget)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffect(rSource, "DISTEST", rTarget) then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISTEST", aTestFilter, rTarget)) > 0 then
			bDIS = true;
			bEffects = true;
		end

		-- Handle automatic success
		if EffectManager5E.hasEffect(rSource, "AUTOPASS", rTarget) then
			table.insert(aAddDesc, "[AUTOPASS]");
		elseif #EffectManager5E.getEffectsByType(rSource, "AUTOPASS", aTestFilter, rTarget) > 0 then
			table.insert(aAddDesc, "[AUTOPASS]");
		end

        -- If effects, then add them
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
    end

    if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	ActionsManager2.encodeDesktopMods(rRoll);
    for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
    rRoll.nMod = rRoll.nMod + nAddMod;
    
    ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function onHarrowing(rSource, rTarget, rRoll)
    ActionsManager2.decodeAdvantage(rRoll);

	local sModStat = "morale";
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[AUTOPASS%]", "");
	rMessage.text = string.gsub(rMessage.text, " %[ORIGIN:[^]]*%]", "");

	local sOrigin = rRoll.sDesc:match("%[ORIGIN:(.-)%]");
	if not rTarget and sOrigin then
		rTarget = ActorManager.resolveActor(sOrigin);
	end

    local rAction = {};
    rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};

    local sCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	local nCritThreshold = tonumber(sCritThreshold) or 20;
	if nCritThreshold < 2 or nCritThreshold > 20 then
		nCritThreshold = 20;
	end

	-- Handle automatic success
	local sAutoPass = string.match(rRoll.sDesc, "%[AUTOPASS%]");

	rAction.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rAction.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if sAutoPass then
		rAction.sResult = "hit";
		table.insert(rAction.aMessages, "[AUTOMATIC SUCCESS]")
	elseif rAction.nFirstDie >= nCritThreshold then
		rAction.bSpecial = true;
		rAction.sResult = "crit";
		table.insert(rAction.aMessages, "[CRITICAL SUCCESS]");
	elseif rAction.nFirstDie == 1 then
		rAction.sResult = "fumble";
		table.insert(rAction.aMessages, "[AUTOMATIC FAILURE]");
	elseif rRoll.nTarget then
		if rAction.nTotal >= tonumber(rRoll.nTarget) then
			rAction.sResult = "hit";
			table.insert(rAction.aMessages, "[PASSED]");
		else
			rAction.sResult = "miss";
			table.insert(rAction.aMessages, "[FAILED]");
		end
	end

    Comm.deliverChatMessage(rMessage);

	notifyHarrow(rSource, rTarget, false, rRoll.sDesc, rAction.nTotal, rRoll.nTarget, table.concat(rAction.aMessages, " "));
	local bSuccess = (rAction.sResult == "crit" or rAction.sResult == "hit");
	notifyAddHarrowEffect(rSource, rTarget, bSuccess);
end

function notifyHarrow(rSource, rTarget, bSecret, sDesc, nTotal, nDC, sResults)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_NOTIFYHARROW;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;
	msgOOB.nDC = nDC or 0;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	if rTarget then
		msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleHarrow(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local bSecret = msgOOB.nSecret == "1";

	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	msgShort.text = "Harrowing"
	msgLong.text = "Harrowing" .. " [" .. msgOOB.nTotal .. "]";
	msgLong.icon = "roll_harrow";

	if (tonumber(msgOOB.nDC) or 0) > 0 then
		msgLong.text = msgLong.text .. "[vs. ";
		local sDef = msgOOB.sDesc:match("%[DEF:(.-)%]");
		if sDef then
			msgLong.text = msgLong.text .. " " .. StringManager.capitalize(sDef) .. " ";
		else
			msgLong.text = msgLong.text .. " DC ";
		end
		msgLong.text = msgLong.text .. msgOOB.nDC .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [from " .. ActorManager.getDisplayName(rTarget) .. "]";
		msgLong.text = msgLong.text .. " [from " .. ActorManager.getDisplayName(rTarget) .. "]";
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. msgOOB.sResults;
	end	

	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end

function notifyAddHarrowEffect(rSource, rTarget, bSuccess)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_ADDHARROWEFFECT;
	if bSuccess then
		msgOOB.nSuccess = 1;
	else
		msgOOB.nSuccess = 0;
	end

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	if rTarget then
		msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleAddHarrowEffect(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode)
	local ctnode = ActorManager.getCTNode(rSource)
	if msgOOB.nSuccess == '0' then
		if not EffectManager.hasEffect(ctnode, "Harrowed") then
        	EffectManager.addEffect("", "", ctnode, { sName = "Harrowed", nDuration = 1 }, true);
		end
	else
		if not EffectManager.hasEffect(ctnode, "Fearless") then
			EffectManager.addEffect("", "", ctnode, { sName = "Fearless", nDuration = 0 }, true);
		end
		
		local aState = getAttackState(rSource);
		if aState and aState.rRolls then
			ActionsManager.actionRoll(rSource, aState.aTargets, aState.rRolls);
		end
    end
end

----------------------------------------
-- HARROWING STATE TABLES
----------------------------------------
aAttackState = {};

function applyAttackState(rSource, aTargets, rRolls)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYATTACKSTATE;
	
	msgOOB.sSourceNode = ActorManager.getCTNodeName(rSource);

	for k,v in ipairs(rRolls) do
		local rollkey = "roll" .. k;
		msgOOB[rollkey .. "_mod"] = rRolls[k].nMod;
		msgOOB[rollkey .. "_desc"] = rRolls[k].sDesc;
	end
	for k,v in ipairs(aTargets) do
		local targetkey = "target" .. k;
		msgOOB[targetkey .. "_sType"] = v[1].sType;
		msgOOB[targetkey .. "_sCreatureNode"] = v[1].sCreatureNode;
		msgOOB[targetkey .. "_sCTNode"] = v[1].sCTNode;
		msgOOB[targetkey .. "_sName"] = v[1].sName;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyAttackState(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local aState = {};
	aState.rRolls = {};
	aState.aTargets = {};

	local i = 1;
	while msgOOB["roll" .. i .. "_desc"] do
		local rRoll = {};
		rRoll.sType = "test";
		rRoll.aDice = { "d20" };
		rRoll.nMod = tonumber(msgOOB["roll" .. i .. "_mod"]) or 0;
		rRoll.sDesc = msgOOB["roll" .. i .. "_desc"]

		table.insert(aState.rRolls, rRoll);
		i = i + 1;
	end

	local j = 1;
	while msgOOB["target" .. j .. "_sName"] do
		local aOuterTarget = {};
		local aTarget = {};
		aTarget.sType = msgOOB["target" .. j .. "_sType"];
		aTarget.sCreatureNode = msgOOB["target" .. j .. "_sCreatureNode"];
		aTarget.sCTNode = msgOOB["target" .. j .. "_sCTNode"];
		aTarget.sName = msgOOB["target" .. j .. "_sName"];

		table.insert(aOuterTarget, aTarget)
		table.insert(aState.aTargets, aOuterTarget);
		j = j + 1;
	end

	if Session.IsHost then
		setAttackState(rSource, aState);
	end
end

function setAttackState(rSource, aState)
	local sSourceCT = ActorManager.getCreatureNodeName(rSource);
	if sSourceCT == "" then
		return;
	end
	
	if not aAttackState[sSourceCT] then
		aAttackState[sSourceCT] = {};
	end

	aAttackState[sSourceCT] = aState;
end

function getAttackState(rSource)
	local sSourceCT = ActorManager.getCTNodeName(rSource);
	if sSourceCT == "" then
		return {};
	end
	
	if not aAttackState[sSourceCT] then
		return {};
	end
	
	local aState = aAttackState[sSourceCT];
	aAttackState[sSourceCT] = nil;
	return aState;
end