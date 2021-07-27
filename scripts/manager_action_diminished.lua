-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActionsManager.registerModHandler("diminished", modDiminished);
    ActionsManager.registerResultHandler("diminished", onDiminished)
end

function performRoll(draginfo, rUnit, rAttacker, rAction)
	local rRoll = getRoll(rUnit, rAttacker, rAction);
	
	ActionsManager.performAction(draginfo, rUnit, rRoll);
end

function getRoll(rUnit, rAttacker, rAction)
	local bADV = rAction.bADV or false;
	local bDIS = rAction.bDIS or false;
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "diminished";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.modifier or 0;
	
	-- Build the description label
    rRoll.sDesc = "[TEST] Morale (Diminished";
    if rAttacker and rAttacker.sName then
        rRoll.sDesc = rRoll.sDesc .. " by " .. rAttacker.sName;
    end
    rRoll.sDesc = rRoll.sDesc .. ")"
	
	-- Add crit range
	if rAction.nCritRange then
		rRoll.sDesc = rRoll.sDesc .. " [CRIT " .. rAction.nCritRange .. "]";
	end

	-- Add advantage/disadvantage tags
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end

	rRoll.nTarget = rAction.nTarget or 13;

	return rRoll;
end

function modDiminished(rSource, rTarget, rRoll)
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

	local sModStat = "morale"
	local aTestFilter = {};
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

function onDiminished(rSource, rTarget, rRoll)
    ActionsManager2.decodeAdvantage(rRoll);

	local sModStat = "morale";
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

    local rAction = {};
    rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};

    local sCritThreshold = string.match(rRoll.sDesc, "%[CRIT (%d+)%]");
	local nCritThreshold = tonumber(sCritThreshold) or 20;
	if nCritThreshold < 2 or nCritThreshold > 20 then
		nCritThreshold = 20;
	end

	rAction.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rAction.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if rAction.nFirstDie >= nCritThreshold then
		rAction.bSpecial = true;
		rAction.sResult = "crit";
		table.insert(rAction.aMessages, "[CRITICAL SUCCESS]");
	elseif rAction.nFirstDie == 1 then
		rAction.sResult = "fumble";
		table.insert(rAction.aMessages, "[AUTOMATIC FAILURE]");
	elseif rRoll.nTarget then
        --Debug.chat(rRoll.nTarget, rAction.nTotal)
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
        ActionDamage.notifyApplyDamage(rSource, rSource, rRoll.bTower, rRoll.sDesc, 1);
    end
end