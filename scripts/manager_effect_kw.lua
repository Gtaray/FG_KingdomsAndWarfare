-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOnEffectActorStartTurn;
local fCheckConditional;

function onInit()
    fCheckConditional = EffectManager5E.checkConditional;
    EffectManager5E.checkConditional = checkConditional;
    Debug.chat(checkConditional)

    fOnEffectActorStartTurn = EffectManager5E.onEffectActorStartTurn
    EffectManager.setCustomOnEffectActorStartTurn(onEffectActorStartTurn);
end

function onEffectActorStartTurn(nodeActor, nodeEffect)
    fOnEffectActorStartTurn(nodeActor, nodeEffect);

    local sEffName = DB.getValue(nodeEffect, "label", "");
	local aEffectComps = EffectManager.parseEffect(sEffName);
	for _,sEffectComp in ipairs(aEffectComps) do
        local rEffectComp = EffectManager5E.parseEffectComp(sEffectComp);

        -- Check for damage tokens
        if StringManager.contains(KingdomsAndWarfare.aDamageTokenTypes, rEffectComp.type) or
                StringManager.contains(KingdomsAndWarfare.aDamageTokenTypes, rEffectComp.original) then
            local nActive = DB.getValue(nodeEffect, "isactive", 0);
            if nActive == 1 then
                applyTokenDamage(nodeActor, nodeEffect, rEffectComp);
            end
        end
    end
end

function applyTokenDamage(nodeActor, nodeEffect, rEffectComp)
    local rTarget = ActorManager.resolveActor(nodeActor);

    local rAction = {};
    rAction.label = "Ongoing damage";
    rAction.clauses = {};

    -- For tokens, duration can be used to track damage
    local nDuration = DB.getValue(nodeEffect, "duration", 0);
    if nDuration > 0 then
        local aClause = {};
        aClause.dice = {};

        -- Nothing in the book has tokens dealing variable damage, but it could be possible
        -- so handle it here
        for k,v in pairs(rEffectComp.dice) do
            for i=1, nDuration do
                table.insert(aClause.dice, v);
            end
        end

        -- Dmg is a minimum of 1, and multiply duration by damage per turn
        local nDmg = rEffectComp.mod;
        if nDmg == 0 then nDmg = 1; end
        aClause.modifier = nDuration * nDmg;
        
        -- Bleed, Acid, Poison, or Fire
        if rEffectComp.type or "" == "" then
            rEffectComp.type = rEffectComp.original;
        end
        aClause.dmgtype = rEffectComp.type:lower();

        table.insert(rAction.clauses, aClause);

        local rRoll = ActionDamage.getRoll(nil, rAction);
        if EffectManager.isGMEffect(nodeActor, nodeEffect) then
            rRoll.bSecret = true;
        end

        ActionsManager.actionDirect(nil, "damage", { rRoll }, { { rTarget } });
    end
end

function checkConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore)
    if ActorManagerKw.isUnit(rActor) then
        local bReturn = true;
        
        if not aIgnore then
            aIgnore = {};
        end
        table.insert(aIgnore, nodeEffect.getPath());

        for _,v in ipairs(aConditions) do
            local sLower = v:lower();
            if sLower == "diminished" then
                local nPercentWounded = ActorHealthManager.getWoundPercent(rActor);
                if nPercentWounded < .5 then
                    Debug.chat('not diminished')
                    bReturn = false;
                    break;
                end
            else
                local sTypeCheck = sLower:match("^type%s*%(([^)]+)%)$");
                local sCustomCheck = sLower:match("^custom%s*%(([^)]+)%)$");
                if sTypeCheck then
                    if not ActorManagerKw.isUnitType(rActor, sTypeCheck) then
                        bReturn = false;
                        break;
                    end
                elseif sCustomCheck then
                    if not EffectManager5E.checkConditionalHelper(rActor, sCustomCheck, rTarget, aIgnore) then
                        bReturn = false;
                        break;
                    end
                end
            end
        end

        table.remove(aIgnore);

        return bReturn;
    else
        return fCheckConditional(rActor, nodeEffect, aConditions, rTarget, aIgnore);
    end
end