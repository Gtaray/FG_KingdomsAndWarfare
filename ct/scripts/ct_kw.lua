-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local enableglobaltoggle = true;

function onInit()
    if super and super.onInit then
        super.onInit();
    end
    list.toggleUnits = toggleUnits;
    list.onUnitsToggle = onUnitsToggle;
    list.onFilter = onFilter;

    -- Any time this is opened, make sure to set the units to visible
    for _,v in pairs(list.getWindows()) do
        local isUnit = ActorManagerKw.isUnit(v.getDatabaseNode());
        if not isUnit then
            v.activateunits.setValue(1);
        else
            v.activateunits.setValue(0);
        end
    end
end

-- The original function also runs, so there's no reason to store
-- a pointer and execute it here
function onDrop(x, y, draginfo)
    button_global_units.setValue(1);
end

-- toggles units for all commanders
function toggleUnits()
    if not enableglobaltoggle then
        return;
    end

    local unitson = button_global_units.getValue();
    for _,v in pairs(list.getWindows()) do
        local node = v.getDatabaseNode();
        local isUnit = ActorManagerKw.isUnit(node);
        if not isUnit then
            v.activateunits.setValue(unitson);
        else
            -- Always disable, just in case it somehow gets set
            v.activateunits.setValue(0);
        end
    end
end

-- Toggles units for a specific commander
function onUnitsToggle(window)
    local node = window.getDatabaseNode();
    local anyunits = 0;

    for _,v in pairs(list.getWindows()) do
        if v.activateunits.getValue() == 1 then
            anyunits = 1;
        end
    end

    enableglobaltoggle = false;
    button_global_units.setValue(anyunits);
    enableglobaltoggle = true;
    
    local sName = DB.getValue(node, "name", "");
    local bShowUnits = window.activateunits.getValue() == 1;
    if sName ~= "" then
        -- Go through the ct list and toggle units appropriately
        for _,v in pairs(list.getWindows()) do
            local node = v.getDatabaseNode()
            local bIsUnit = ActorManagerKw.isUnit(node);
            if bIsUnit then
                local sCommander = DB.getValue(node, "commander", "");
                -- if the unit's commander name matches the ct entry name
                -- set its visibility
                if sCommander == sName then
                    if bShowUnits then
                        DB.setValue(node, "hide", "number", 0);
                        DB.setValue(node, "tokenvis", "number", 1)
                    else
                        DB.setValue(node, "hide", "number", 1);
                        DB.setValue(node, "tokenvis", "number", 0)
                    end
                end
            end
        end
    end

    list.applyFilter();
end

function onFilter(w)
    -- Check if unit is manually hidden
    local hide = DB.getValue(w.getDatabaseNode(), "hide", 0)
    
    -- Show units for the last non-unit actor on the combat tracker. 
    local lastCommander = DB.findNode(DB.getValue(CombatManager.CT_MAIN_PATH, "lastcommander", ""));
    if lastCommander then
        local sLastCmdrName = DB.getValue(lastCommander, "name", "");
        local sCommander = DB.getValue(w, "name", "");
        if sCommander == sLastCmdrName then
            hide = 0;
        end
    end
    
    return hide == 0;
end