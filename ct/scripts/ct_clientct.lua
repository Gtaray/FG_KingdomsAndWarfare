-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOnFilter;

function onInit()
    if super and super.onInit then
        super.onInit();
    end
    
    fOnFilter = list.onFilter;
    list.onFilter = onFilter;

    list.applyFilter();
end

-- Update the player CT filter to take into account extra things
-- token visibility & faction
-- unit hidden property
-- who was the last commander
-- if the unit's commander is on the CT
function onFilter(w)
    local node = w.getDatabaseNode();
    local sFaction = w.friendfoe.getStringValue();
    local bTokenVisible = w.tokenvis.getValue() ~= 0;

    if ActorManagerKw.isUnit(node) then
        -- If a token is hidden and not friendly, it should 100% be hidden, no other concerns
        if not bTokenVisible then
            if sFaction ~= "friend" then
                return false;
            end
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
        local bHidden = DB.getValue(node, "hide", 0) == 1
        if not bHidden then
            return true;
        end

        return false
    end

    return fOnFilter(w);
end
