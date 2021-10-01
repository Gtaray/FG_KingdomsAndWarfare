-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActorManager.registerActorRecordType("unit");
end

function isUnit(v)
    local rActor = ActorManager.resolveActor(v);
    if rActor then
        return rActor.sType == "unit";
    end
    return false;
end

function getCommanderCT(v)
    -- Only get commander's for units
    if not isUnit(v) then
        return;
    end

    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(v));
    if not node then
        return;
    end

    local _,sRecord = DB.getValue(node, "commander_link", "", "");
    local nodeCommander = DB.findNode(sRecord);
    if nodeCommander and ActorManager.getActorRecordTypeFromPath(nodeCommander.getPath()) then
        return nodeCommander;
    end

    local sCommander = DB.getValue(node, "commander", "");
    if sCommander == "" then return; end

    local aEntries = CombatManager.getSortedCombatantList();
    if #aEntries > 0 then
        for i = 1, #aEntries do
            -- Only look at non-units
            if not isUnit(aEntries[i]) then
                local sName = DB.getValue(aEntries[i], "name", "");

                -- If the names match, return the CT node
                if sName == sCommander then
                    return aEntries[i];
                end
            end
		end
	end
end

function getUnitType(v)
    -- Only get commander's for units
    if not isUnit(v) then
        return;
    end
    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(v));
    if not node then
        return false;
    end
    return DB.getValue(node, "type", "");
end

function getUnitTier(v)
    -- Only get commander's for units
    if not isUnit(v) then
        return 0;
    end
    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(v));
    if not node then
        return 0;
    end
    return DB.getValue(node, "tier", 0);
end

function getUnitSize(v)
    if not isUnit(v) then
        return 0;
    end
    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(v));
    if not node then
        return 0;
    end
    return DB.getValue(node, "casualties", 0);
end

function getUnitCurrentHP(v)
    if not isUnit(v) then
        return 0;
    end
    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(v));
    if not node then
        return 0;
    end
    local maxHP = DB.getValue(node, "hptotal", 0);
    local wounds = DB.getValue(node, "wounds", 0);
    return maxHP - wounds;
end

function getDamage(rUnit)
    if not rUnit then
        return 0, 0;
    end

    local nEffectBonus, nDmgEffects = EffectManager5E.getEffectsBonus(rUnit, "DMG", true);
    local dbpath = rUnit.sCreatureNode .. ".damage";
    local nDmg = DB.getValue(dbpath, nil, 1);

    nDmg = nDmg + nEffectBonus;

    return nDmg, nDmgEffects
end

function getAbilityBonus(rUnit, sAbility)
    if not rUnit or ((sAbility or "") == "") then
		return 0;
	end
    if type(rUnit) == "databasenode" then
        rUnit = ActorManager.resolveActor(rUnit);
    end

    local dbpath = rUnit.sCreatureNode .. ".abilities." .. sAbility;
    local nAbilityScore = DB.getValue(dbpath, nil, 0);
    return nAbilityScore;
end

function getDefenseValue(rAttacker, rDefender, rRoll)
    if not rDefender or not rRoll then
		return nil, 0, 0, false, false;
	end

    local sDef = rRoll.sDesc:match("%[DEF:(%w+)%]");
    if not sDef then
        return nil, 0, 0, false, false;
    end
	
	-- Base calculations
	local sAttack = rRoll.sDesc;

	local sNodeDefenderType, nodeDefender = ActorManager.getTypeAndNode(rDefender);
	if not nodeDefender then
		return nil, 0, 0, false, false;
	end

    -- Only process if this is targeting another unit.
    if sNodeDefenderType ~= "ct" then
        return nil, 0, 0, false, false;
    end

    local nDefense = DB.getValue(nodeDefender, "abilities." .. sDef, 10);
	
	-- Effects
	local nDefenseEffectMod = 0;
	local bADV = false;
	local bDIS = false;
	if ActorManager.hasCT(rDefender) then
		local nBonusDef = 0;
		local nBonusStat = 0;
		local nBonusSituational = 0;

        sEffectType = DataCommon.ability_ltos[sDef];
        if sEffectType then
            local aACEffects, nACEffectCount = EffectManager5E.getEffectsBonusByType(rDefender, {sEffectType}, true, aAttackFilter, rAttacker);
            for _,v in pairs(aACEffects) do
                nBonusDef = nBonusDef + v.mod;
            end 
        end
		
        -- TODO: Handle all of the conditions that could affect a unit's defense
		
		nDefenseEffectMod = nBonusDef;
	end
	
	-- Results
	return nDefense, 0, nDefenseEffectMod, bADV, bDIS;
end

function hasUsedReaction(rUnit)
    local nodect = ActorManager.getCTNode(rUnit);
    if nodect then
        local bReactionUsed = DB.getValue(nodect, "reaction", 0) == 1;
        return bReactionUsed;
    end
    return true; -- If unit is not on combat tracker
end

function hasHarrowingTrait(rUnit)
    if not rUnit then 
        return false; 
    end

    local unitNode = ActorManager.getCreatureNode(rUnit)
    if not unitNode then 
        return false;
    end
    local traits = unitNode.getChild("traits");
    if traits then
        for k,v in pairs(traits.getChildren(traits.getChildren())) do
            local traitName = DB.getValue(v, "name", "");
            if traitName:lower() == "harrowing" then
                return true;
            end
        end
    end
    return false;
end

function rollMoraleTestForDiminished(rUnit, rAttacker)
    if not rUnit then 
        return;
    end

    local rAction = {}
    rAction.modifier = getAbilityBonus(rUnit, "morale");
    ActionDiminished.performRoll(nil, rUnit, rAttacker, rAction)
end

--
--	CONDITIONALS
--

function isUnitType(rUnit, sTypeCheck)
    local sType = ActorManagerKw.getUnitType(rUnit);
    return sType:lower() == sTypeCheck:lower();
end

function isUnitAncestry(rUnit, sAncestryCheck)
    -- Only get commander's for units
    if not isUnit(rUnit) then
        return false;
    end
    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(rUnit));
    if not node then
        return false;
    end
    local sAncestry = DB.getValue(node, "ancestry", "");
    local bMatch = false;
    if sAncestry then
        sAncestry = StringManager.trim(sAncestry):lower();
        if DataKW.ancestrydata[sAncestry] then
            bMatch = DataKW.ancestrydata[sAncestry] == sAncestryCheck:lower();
        end
    end
    return bMatch;
end

--
-- POWER DIE
--
function getPowerDie(rActor)
    local total = EffectManagerKw.getPowerDieEffect(rActor);
    return total;
end

function addPowerDie(rActor, nTotal)
    local nExistingTotal, effectNode = EffectManagerKw.getPowerDieEffect(rActor);

    -- If there's already an effect, add the value to that effect
    if effectNode and nExistingTotal > 0 then
        local sLabel = DB.getValue(effectNode, "label", "");
        DB.setValue(effectNode, "label", "string", sLabel:gsub("POWERDIE: " .. nExistingTotal, "POWERDIE: " .. (nExistingTotal + nTotal)));
    -- Otherwise, add new effect
    elseif nTotal and nTotal > 0 then
        EffectManager.addEffect("", "", ActorManager.getCTNode(rActor), { sName = "POWERDIE: " .. nTotal, nDuration = 0, nGMOnly = 0 }, false);
    end
end

function decrementPowerDie(rActor)
    if not rActor then 
        return;
    end
    
    local nExistingTotal, effectNode = EffectManagerKw.getPowerDieEffect(rActor);
    local newTotal = nExistingTotal - 1;

    if not effectNode then
        return;
    end

    if newTotal <= 0 then
        -- expire power die
        -- and expire the effect with 'decrement' in it
        EffectManager.notifyExpire(effectNode, 0, true);
    else
        local sLabel = DB.getValue(effectNode, "label", "");
        DB.setValue(effectNode, "label", "string", sLabel:gsub("POWERDIE: " .. nExistingTotal, "POWERDIE: " .. newTotal));
    end

    return newTotal, effectNode;
end