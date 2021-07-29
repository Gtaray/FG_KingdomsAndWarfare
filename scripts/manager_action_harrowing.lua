-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYATTACKSTATE = "applyattackstate";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYATTACKSTATE, handleApplyAttackState);

    ActionsManager.registerModHandler("harrowing", modHarrowing);
    ActionsManager.registerResultHandler("harrowing", onHarrowing)
end

function performRoll(draginfo, rUnit, rTarget)
	local rRoll = getRoll(rUnit, rTarget);
	
	ActionsManager.performAction(draginfo, rUnit, rRoll);
end

function getRoll(rUnit, rTarget)
	local bADV = false;
	local bDIS = false;
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "harrowing";
	rRoll.aDice = { "d20" };
	rRoll.nMod = ActorManagerKw.getAbilityBonus(rUnit, "morale") or 0;
	rRoll.nTarget = 10 + (ActorManagerKw.getUnitTier(rTarget) or 0)

	-- Build the description label
    rRoll.sDesc = "[TEST] Morale (Harrowing";
    if rAttacker and rAttacker.sName then
        rRoll.sDesc = rRoll.sDesc .. " from " .. rAttacker.sName;
    end
    rRoll.sDesc = rRoll.sDesc .. ")"

	-- Add advantage/disadvantage tags
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
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

		if EffectManager5E.hasEffectCondition(rSource, "ADVTEST") then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVTEST", aTestFilter)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISTEST") then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISTEST", aTestFilter)) > 0 then
			bDIS = true;
			bEffects = true;
		end

		-- Handle automatic success
		if EffectManager5E.hasEffectCondition(rSource, "AUTOPASS") then
			table.insert(aAddDesc, "[AUTOPASS]");
		elseif #EffectManager5E.getEffectsByType(rSource, "AUTOPASS", aTestFilter) > 0 then
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
			table.insert(rAction.aMessages, "[SUCCESS]");
		else
			rAction.sResult = "miss";
			table.insert(rAction.aMessages, "[FAILURE]");
		end
	end

    rMessage.text = rMessage.text .. " " .. table.concat(rAction.aMessages, " ");
    Comm.deliverChatMessage(rMessage);

    if rAction.sResult == "miss" or rAction.sResult == "fumble" then
        EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Harrowed", nDuration = 1 }, true);
	else
		EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Fearless", nDuration = 0 }, true);
		local aState = getAttackState(rSource);
		-- Debug.chat(aState.aTargets);
		-- Debug.chat(aState.rRolls)
		ActionsManager.actionRoll(rSource, aState.aTargets, aState.rRolls);
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
	-- Debug.chat(aTargets);
	-- Debug.chat(rRolls);

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
	-- Debug.chat('handleApplyAttackState()')
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
	-- Debug.chat(msgOOB)
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

	-- Debug.chat(aState.aTargets);
	-- Debug.chat(aState.rRolls);

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