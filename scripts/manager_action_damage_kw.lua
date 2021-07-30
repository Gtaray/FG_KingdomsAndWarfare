-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- The only reason I have to make an entire new workflow is because I don't want the unconscious
-- status being applied to units. Since that bit of code is in the middle of a huge function, and I 
-- don't want to copy/re-implement hte whole function, I'm going to branch it, so units
-- are dealt damage here, while pcs/npcs are dealt damage per the ActionDamage.applyDamage function

local fGetRoll;
local fOnDamage;
local fApplyDamage;

function onInit()
	fGetRoll = ActionDamage.getRoll;
	ActionDamage.getRoll = getRoll;

	fOnDamage = ActionDamage.onDamage;
	ActionsManager.registerResultHandler("damage", onDamage);

    fApplyDamage = ActionDamage.applyDamage;
    ActionDamage.applyDamage = applyDamage;
end

function getRoll(rActor, rAction)
	local rRoll = fGetRoll(rActor, rAction);

	-- Add in a clause for automatic target handling
	if rAction.target or "" ~= "" then
		rRoll.sDesc = rRoll.sDesc .. "[TARGET:" .. rAction.target .. "]";
	end

	return rRoll;
end

function onDamage(rSource, rTarget, rRoll)
	-- if target is nil, try to resolve target from the roll text
	if rTarget == nil then
		local sTarget = rRoll.sDesc:match("%[TARGET:([^]]*)%]")
		if sTarget then
			rRoll.sDesc = rRoll.sDesc:gsub("%[TARGET:[^]]*%]", "")
			local newTarget = ActorManager.resolveActor(sTarget);
			if newTarget then
				rTarget = newTarget;
			end
		end
	end

	fOnDamage(rSource, rTarget, rRoll);
end

-- Fork the data flow here so that updates to the 5e ruleset don't break all damage
-- it only risks breaking this extensions handling of unit damage.
function applyDamage(rSource, rTarget, bSecret, sDamage, nTotal)
    local nodeTarget = ActorManager.getCTNode(rTarget);
    local bIsUnit = DB.getValue(nodeTarget, "isUnit", 0) == 1;
    if bIsUnit then
        applyDamageToUnit(rSource, rTarget, bSecret, sDamage, nTotal)
    else
        fApplyDamage(rSource, rTarget, bSecret, sDamage, nTotal);
    end
end

-- Trimmed down version of the applyDamge function. Got rid of most of the extraneous stuff:
-- like concentration, half damage, avoidance, death saves, recovery, etc.
function applyDamageToUnit(rSource, rTarget, bSecret, sDamage, nTotal)
	-- Get health fields
	local nTotalHP, nTempHP, nWounds;

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return;
	end
	if sTargetNodeType == "ct" then
		nTotalHP = DB.getValue(nodeTarget, "hptotal", 0);
		nTempHP = DB.getValue(nodeTarget, "hptemp", 0);
		nWounds = DB.getValue(nodeTarget, "wounds", 0);
	else
		return;
	end

	-- Remember current health status
	local sOriginalStatus = ActorHealthManager.getHealthStatus(rTarget);

	-- Decode damage/heal description
	local rDamageOutput = ActionDamage.decodeDamageText(nTotal, sDamage);
	rDamageOutput.tNotifications = {};
	
	-- Healing
	if rDamageOutput.sType == "heal" then
		if nWounds <= 0 then
			table.insert(rDamageOutput.tNotifications, "[NOT WOUNDED]");
		else
			-- Calculate heal amounts
			local nHealAmount = rDamageOutput.nVal;
			
			-- If healing from zero (or negative), then remove Stable effect and reset wounds to match HP
			if (nHealAmount > 0) and (nWounds >= nTotalHP) then
				nWounds = nTotalHP;
			end
			
			local nWoundHealAmount = math.min(nHealAmount, nWounds);
			nWounds = nWounds - nWoundHealAmount;
			
			-- Display actual heal amount
			rDamageOutput.nVal = nWoundHealAmount;
			rDamageOutput.sVal = string.format("%01d", nWoundHealAmount);
		end

	-- Temporary hit points
	elseif rDamageOutput.sType == "temphp" then
		nTempHP = math.max(nTempHP, rDamageOutput.nVal);

	-- Damage
	else
		-- Apply any targeted damage effects 
		if rSource and rTarget and rTarget.nOrder then
			ActionDamage.applyTargetedDmgEffectsToDamageOutput(rDamageOutput, rSource, rTarget);
			ActionDamage.applyTargetedDmgTypeEffectsToDamageOutput(rDamageOutput, rSource, rTarget);
		end
		
		-- Apply damage type adjustments
		local nDamageAdjust, bVulnerable, bResist = ActionDamage.getDamageAdjust(rSource, rTarget, rDamageOutput.nVal, rDamageOutput);
		local nAdjustedDamage = rDamageOutput.nVal + nDamageAdjust;
		if nAdjustedDamage < 0 then
			nAdjustedDamage = 0;
		end
		if bResist then
			if nAdjustedDamage <= 0 then
				table.insert(rDamageOutput.tNotifications, "[RESISTED]");
			else
				table.insert(rDamageOutput.tNotifications, "[PARTIALLY RESISTED]");
			end
		end
		if bVulnerable then
			table.insert(rDamageOutput.tNotifications, "[VULNERABLE]");
		end
		
		-- Reduce damage by temporary hit points
		if nTempHP > 0 and nAdjustedDamage > 0 then
			if nAdjustedDamage > nTempHP then
				nAdjustedDamage = nAdjustedDamage - nTempHP;
				nTempHP = 0;
				table.insert(rDamageOutput.tNotifications, "[PARTIALLY ABSORBED]");
			else
				nTempHP = nTempHP - nAdjustedDamage;
				nAdjustedDamage = 0;
				table.insert(rDamageOutput.tNotifications, "[ABSORBED]");
			end
		end

		-- Apply remaining damage
		if nAdjustedDamage > 0 then
			-- Remember previous wounds
			local nPrevWounds = nWounds;
			
			-- Apply wounds
			nWounds = math.max(nWounds + nAdjustedDamage, 0);
			
			-- Calculate wounds above HP
			local nRemainder = 0;
			if nWounds > nTotalHP then
				nRemainder = nWounds - nTotalHP;
				nWounds = nTotalHP;
			end
			
			-- Deal with remainder damage
			if nRemainder > 0 then
				table.insert(rDamageOutput.tNotifications, "[DAMAGE EXCEEDS CASUALTIES BY " .. nRemainder.. "]");
			end
		end
		
		-- Update the damage output variable to reflect adjustments
		rDamageOutput.nVal = nAdjustedDamage;
		rDamageOutput.sVal = string.format("%01d", nAdjustedDamage);
	end
	
	-- Add unit conditions
    local immuneToDiminished = EffectManager5E.getEffectsByType(rTarget, "IMMUNE", { "diminished" });
    local nHalf = nTotalHP/2;
    local isDiminished = EffectManager5E.hasEffect(rTarget, "Diminished")
    local isBroken = EffectManager5E.hasEffect(rTarget, "Broken")
    if nWounds < nHalf then
        if isDiminished then
            EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Diminished");
        end
        if isBroken then
            EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Broken");
        end
    elseif nWounds >= nHalf and nWounds < nTotalHP then
        if not isDiminished and #immuneToDiminished == 0 then
            EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = "Diminished", nDuration = 0 }, true);
            ActorManagerKw.rollMoraleTestForDiminished(rTarget, rSource);
        end
        if isBroken then
            EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Broken");
        end
    elseif nWounds >= nTotalHP then
        if isDiminished then
            EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Diminished");
        end
        if not isBroken then
            EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = "Broken", nDuration = 0 }, true);
        end
    end

	-- Set health fields
    DB.setValue(nodeTarget, "hptemp", "number", nTempHP);
    DB.setValue(nodeTarget, "wounds", "number", nWounds);

	-- Check for status change
	local bShowStatus = false;
	if ActorManager.getFaction(rTarget) == "friend" then
		bShowStatus = not OptionsManager.isOption("SHPC", "off");
	else
		bShowStatus = not OptionsManager.isOption("SHNPC", "off");
	end
	if bShowStatus then
		local sNewStatus = ActorHealthManager.getHealthStatus(rTarget);
		if sOriginalStatus ~= sNewStatus then
			table.insert(rDamageOutput.tNotifications, "[" .. Interface.getString("combat_tag_status") .. ": " .. sNewStatus .. "]");
		end
	end
	
	-- Output results
	ActionDamage.messageDamage(rSource, rTarget, bSecret, rDamageOutput.sTypeOutput, sDamage, rDamageOutput.sVal, table.concat(rDamageOutput.tNotifications, " "));
end