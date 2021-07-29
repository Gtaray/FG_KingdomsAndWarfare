-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYTEST = "applytest";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYTEST, handleApplyTest);

	ActionsManager.registerTargetingHandler("test", onTargeting);
    ActionsManager.registerModHandler("test", modTest);
    ActionsManager.registerResultHandler("test", onTest)
end

function performRoll(draginfo, rUnit, rAction)
	local rRoll = getRoll(rUnit, rAction);
	
	ActionsManager.performAction(draginfo, rUnit, rRoll);
end

function getRoll(rUnit, rAction)
	local bADV = rAction.bADV or false;
	local bDIS = rAction.bDIS or false;
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "test";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.modifier or 0;
	
	-- Build the description label
	rRoll.sDesc = "[TEST";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	if rAction.range then
		rRoll.sDesc = rRoll.sDesc .. " (" .. rAction.range .. ")";
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	
	-- Add crit range
	if rAction.nCritRange then
		rRoll.sDesc = rRoll.sDesc .. " [CRIT " .. rAction.nCritRange .. "]";
	end
	
	-- Add stat bonus
	if rAction.stat then
        local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end

	-- Add defense stat
	if rAction.defense then
		rRoll.sDesc = rRoll.sDesc .. " [DEF:" .. rAction.defense .. "]";
	end
	
	-- Add advantage/disadvantage tags
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end

	rRoll.nTarget = rAction.nTargetDC;

	return rRoll;
end

function onTargeting(rSource, aTargeting, rRolls)
	-- Debug.chat('onTargeting')
	-- Remove target if trying to target an NPC instead of a unit
	local aNewTargets = {};

	if aTargeting and #aTargeting > 0 then
		for _,target in pairs(aTargeting) do
			if target and target[1] and target[1].sType == "unit" then
				table.insert(aNewTargets, target);
			end
		end
	end

	if handleHarrowing(rSource, aTargeting, rRolls) then
		-- Debug.chat('handling harrowing')
		rRolls[1].sDesc = rRolls[1].sDesc .. "[BAIL]";
		rSource = nil;
	end


	return aNewTargets;
end

function handleHarrowing(rSource, aTargets, rRolls)
	-- Check for attack roll
	local bAttack = false;
	for k,v in pairs(rRolls) do
		if v.sDesc:match("Attack") then
			bAttack = true;
		end
	end
	if not bAttack then
		return false;
	end

	-- Handle Harrowing
	local aHarrowUnit = nil;
	if aTargets and #aTargets > 0 then
		for k,target in pairs(aTargets) do
			local isHarrowing = ActorManagerKw.hasHarrowingTrait(target[1])
			if isHarrowing then
				aHarrowUnit = target[1];
			end
		end
	end
	if aHarrowUnit then
		-- Check if source is immune to harrow
		if not EffectManager5E.hasEffectCondition(rSource, "Fearless") then
			local sourceType = ActorManagerKw.getUnitType(rSource);
			if sourceType or "" ~= "" then
				local sTypeLower = sourceType:lower();
				if sTypeLower == "infantry" or sTypeLower == "cavalry" or sTypeLower == "aerial" then
					ActionHarrowing.applyAttackState(rSource, aTargets, rRolls);
					ActionHarrowing.performRoll(nil, rSource, rTarget)
					return true;
				end
			end
		end
	end
	return false;
end

function modTest(rSource, rTarget, rRoll)
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

	local sModStat = rRoll.sDesc:match("%[MOD:(%w+)%]");
	if sModStat then
		sModStat = DataCommon.ability_stol[sModStat];
	end

	local aTestFilter = { };
	if sModStat then
		table.insert(aTestFilter, sModStat:lower());
	end

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

        -- Handle all of the conditions here
		if sActionStat == "attack" and EffectManager5E.hasEffectCondition(rTarget, "Hidden") then
			bEffects = true;
			bDIS = true;
		end
		if sActionStat == "power" and EffectManager5E.hasEffectCondition(rSource, "Weakened") then
			bEffects = true;
			bDIS = true;
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

	-- Advantage and disadvantage from effects on target
	if rTarget and ActorManager.hasCT(rTarget) then
		if sModStat == "attack" then
			if EffectManager5E.hasEffect(rTarget, "GRANTADVATK", rSource) then
				bADV = true;
			end
			if EffectManager5E.hasEffect(rTarget, "GRANTDISATK", rSource) then
				bDIS = true;
			end
		end
		if sModStat == "power" then
			if EffectManager5E.hasEffect(rTarget, "GRANTADVPOW", rSource) then
				bADV = true;
			end
			if EffectManager5E.hasEffect(rTarget, "GRANTDISPOW", rSource) then
				bDIS = true;
			end
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

function onTest(rSource, rTarget, rRoll)
    ActionsManager2.decodeAdvantage(rRoll);

	local sModStat = rRoll.sDesc:match("%[MOD:(%w+)%]");
	if sModStat then
		sModStat = DataCommon.ability_stol[sModStat];
	end

    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");
	rMessage.text = string.gsub(rMessage.text, " %[DEF:[^]]*%]", "");
	rMessage.text = string.gsub(rMessage.text, " %[AUTOPASS%]", "");

    local rAction = {};
    rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};

	local nDefenseVal, nAtkEffectsBonus, nDefEffectsBonus = ActorManagerKw.getDefenseValue(rSource, rTarget, rRoll);
	if nAtkEffectsBonus ~= 0 then
		rAction.nTotal = rAction.nTotal + nAtkEffectsBonus;
		local sFormat = "[" .. Interface.getString("effects_tag") .. " %+d]"
		table.insert(rAction.aMessages, string.format(sFormat, nAtkEffectsBonus));
	end
	if nDefEffectsBonus ~= 0 then
		nDefenseVal = nDefenseVal + nDefEffectsBonus;
		local sFormat = "[" .. Interface.getString("effects_def_tag") .. " %+d]"
		table.insert(rAction.aMessages, string.format(sFormat, nDefEffectsBonus));
	end

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
		table.insert(rAction.aMessages, "[CRITICAL HIT]");
	elseif rAction.nFirstDie == 1 then
		rAction.sResult = "fumble";
		table.insert(rAction.aMessages, "[AUTOMATIC MISS]");
	elseif nDefenseVal then
		if rAction.nTotal >= nDefenseVal then
			rAction.sResult = "hit";
			table.insert(rAction.aMessages, "[HIT]");
		else
			rAction.sResult = "miss";
			table.insert(rAction.aMessages, "[MISS]");
		end
	end

	-- If there's a target we use the message table later, so only display it now if there's no target
    if not rTarget then
		rMessage.text = rMessage.text .. " " .. table.concat(rAction.aMessages, " ");
	end

    Comm.deliverChatMessage(rMessage);

	if rTarget then
		notifyApplyTest(rSource, rTarget, rRoll.bTower, sModStat, rRoll.sDesc, rAction.nTotal, table.concat(rAction.aMessages, " "));

		-- Handle damage
		if rAction.sResult == "crit" or rAction.sResult == "hit" then
			-- Attacks only deal 1 damage
			if sModStat == "attack" then
				ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll.bTower, sModStat, 1);
			-- Power deals damage equal to the unit's stat
			elseif sModStat == "power" then
				local damage = ActorManagerKw.getDamage(rSource);
				ActionDamage.notifyApplyDamage(rSource, rTarget, rRoll.bTower, sModStat, damage);
			end
		end
	end
end

function notifyApplyTest(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYTEST;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sAttackType = sAttackType;
	msgOOB.nTotal = nTotal;
	msgOOB.sDesc = sDesc;
	msgOOB.sResults = sResults;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyTest(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	-- Print message to chat window
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyTest(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
end

function applyTest(rSource, rTarget, bSecret, sAttackType, sDesc, nTotal, sResults)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = StringManager.capitalize(sAttackType or "Test") .. " ->";
	msgLong.text = StringManager.capitalize(sAttackType or "Test") .. " [" .. nTotal .. "] ->";
	if rTarget then
		msgShort.text = msgShort.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
		msgLong.text = msgLong.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end
	
	msgShort.icon = "roll_attack";
	if string.match(sResults, "%[CRITICAL HIT%]") then
		msgLong.icon = "roll_attack_crit";
	elseif string.match(sResults, "HIT%]") then
		msgLong.icon = "roll_attack_hit";
	elseif string.match(sResults, "MISS%]") then
		msgLong.icon = "roll_attack_miss";
	else
		msgLong.icon = "roll_attack";
	end
		
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end
