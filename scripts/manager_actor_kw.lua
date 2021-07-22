-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActorManager.registerActorRecordType("unit");
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