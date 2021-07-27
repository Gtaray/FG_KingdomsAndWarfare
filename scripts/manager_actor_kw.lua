-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActorManager.registerActorRecordType("unit");
end

function isUnit(v)
    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(v));
    if not node then
        return false;
    end

    local isUnit = DB.getValue(node, "isUnit", 0);
    return isUnit == 1;
end

function getCommanderCT(v)
    -- Only get commander's for units
    if not isUnit(v) then
        return;
    end

    local sType, node = ActorManager.getTypeAndNode(ActorManager.resolveActor(v));
    if not node then
        return false;
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

-- So far this isn't used...
function getAbilityBonus(rUnit, sAbility)
    if not rUnit or ((sAbility or "") == "") then
		return 0, 0;
	end

    local sAbilityEffect = DataCommon.ability_ltos[sAbility];
    if not sAbilityEffect then
		return 0, 0;
	end

    local nEffectBonus, nAbilityEffects = EffectManager5E.getEffectsBonus(rUnit, sAbilityEffect, true);

    local dbpath = rUnit.sCreatureNode .. ".abilities." .. sAbility;
    local nAbilityScore = DB.getValue(dbpath, nil, 0);
    nAbilityScore = nAbilityScore + nEffectBonus;

    return nAbilityScore, nAbilityEffects;
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
    rAction.label = "Morale test (Diminished";
    if rAttacker and rAttacker.sName then
        rAction.label = rAction.label .. " by " .. rAttacker.sName;
    end
    rAction.label = rAction.label .. ")"
    rAction.stat = "morale";

    local nTier = ActorManagerKw.getUnitTier(aHarrowUnit)
    rAction.nTargetDC = 10 + nTier

    ActionTest.performAction(nil, rUnit, rAction)
end