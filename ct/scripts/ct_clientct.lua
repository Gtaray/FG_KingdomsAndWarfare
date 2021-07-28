-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    if super and super.onInit then
        super.onInit();
    end
    
    list.onFilter = onFilter;
end

-- Update the player CT filter to take into account extra things
-- token visibility
-- faction
-- unit hidden property
-- who was the last commander
-- if the unit's commander is on the CT
function onFilter(w)
    local node = w.getDatabaseNode();
    local sFaction = w.friendfoe.getStringValue();
    local bTokenVisible = w.tokenvis.getValue() ~= 0;

    -- If a token is hidden, it should 100% be hidden, no other concerns
    if not bTokenVisible then
        return false;
    end

    -- Units without commanders should be visible as long as their token isn't hidden
    local cmdrNode = ActorManagerKw.getCommanderCT(node);
    if not cmdrNode then
        return true;
    end

    -- Show units for the last non-unit actor on the combat tracker. 
    local lastCommandersUnit = CombatManagerKw.isUnitOwnedByLastCommander(node);
    if lastCommandersUnit then
        return true;
    end

    -- Check if unit is manually hidden
    if DB.getValue(node, "hide", 0) == 1 then
        return false;
    end

    -- Lastly, check if the unit is friendly faction
    if sFaction == "friend" then
        return true;
    end

    return false
end
