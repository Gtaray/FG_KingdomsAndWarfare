-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

MARKERS = {
    ["rank_vanguard_friend"] = { rank = "vanguard", faction = "friend" },
    ["rank_reserves_friend"] = { rank = "reserve", faction = "friend" },
    ["rank_center_friend"] = { rank = "center", faction = "friend" },
    ["rank_rear_friend"] = { rank = "rear", faction = "friend" },
    ["rank_vanguard_foe"] = { rank = "vanguard", faction = "foe" },
    ["rank_reserves_foe"] = { rank = "reserve", faction = "foe" },
    ["rank_reserves_foe"] = { rank = "center", faction = "foe" },
    ["rank_rear_foe"] = { rank = "rear", faction = "foe" },
}

function onInit()
end

function onTurnEnd(nodeCT)
    local windowinstance = getImageWindow(nodeCT);
    updateTokensOnMap(windowinstance);
end

function updateTokensOnMap(windowinstance)
    local sMarkerPos = getImageRankPositionOption(windowinstance);

    local image = windowinstance.image;
    if not image then
        return;
    end

    local ranks, units = getRanksAndUnits(image, sMarkerPos);
    if ranks and units then
        checkForExposedUnits(ranks, units, sMarkerPos);
    end
end

function getImageWindow(ctnode)
    -- Debug.chat('getImageWindow')
    -- Debug.chat('ctnode', ctnode)
    if not ctnode then
        return;
    end

    local token = CombatManager.getTokenFromCT(ctnode)
    -- Debug.chat('token', token)
    if not token then
        return;
    end

    local container = token.getContainerNode()
    -- Debug.chat('container', container)
    if not container then
        return;
    end

    -- Remove the last '.image' from the container path, since we want the imagewindow record name.
    local dbpath = container.getPath():gsub(".image", "");
    local windowinstance = Interface.findWindow("imagewindow", dbpath)
    if not windowinstance then
        return;
    end

    return windowinstance;
end

function getImageRankPositionOption(windowinstance)
    local nRankPos = windowinstance.toolbar.subwindow.rank_position.getValue();
    
    return getMarkerPosition(nRankPos);
end

function getRankMarkers(image)
    local markers = {};
    if image.window then
        local imagenode = image.window.getDatabaseNode();
        if imagenode then
            for nodename,data in pairs(MARKERS) do
                local token = DB.getValue(imagenode, nodename, "")
                if (token or "") ~= "" then
                    markers[token] = data
                end
            end
        end
    end

    return markers;
end

function getMarkerPosition(nPos)
    if nPos == 0 then
        return "right";
    elseif nPos == 1 then
        return "left";
    elseif nPos == 2 then
        return "top";
    elseif nPos == 3 then
        return "bottom";
    end
end

function getRanksAndUnits(image, sMarkerPos)
    local matchAxis, offAxis;
    if sMarkerPos == "left" or sMarkerPos == "right" then 
        matchAxis = "y";
        offAxis = "x";
    elseif sMarkerPos == "top" or sMarkerPos == "bottom" then 
        matchAxis = "x";
        offAxis = "y" 
    end
    if not matchAxis or not offAxis then
        return;
    end

    markers = getRankMarkers(image);

    local ranks = {};
    local units = {};
    local nBorder = 0;

    for k,v in pairs(image.getTokens()) do
        local prototype = v.getPrototype();
        if markers[prototype] then
            local rank = markers[prototype];
            rank.x, rank.y = v.getPosition();
            ranks[rank[matchAxis]] = rank;

            -- Set the pixel position of the markers along the axis opposite the direction the tokens stack
            -- This is used to remove cavalry from the exposure checks
            nBorder = rank[offAxis];
        else
            local unit = {};
            unit.x, unit.y = v.getPosition();
            local ctnode = CombatManager.getCTFromToken(v);
            if ActorManagerKw.isUnit(ActorManager.resolveActor(ctnode)) then
                unit.unitfaction = DB.getValue(ctnode, "friendfoe", "string", "foe");
                unit.ctnode = ctnode.getPath();
                table.insert(units, unit);
            end
        end
    end

    -- If there aren't a full set of ranks, return nil
    local i = 0;
    for k,v in pairs(ranks) do
        i = i + 1
    end
    if i < 7 then
        return; 
    end

    -- Go through all units and assign them to their ranks
    local finalUnits = {};
    for _, unit in ipairs(units) do
        -- Mark units outside the battlemaps bounds as such (i.e. cavalry)
        if (sMarkerPos == "right" or sMarkerPos == "bottom") and unit[offAxis] < nBorder then
        elseif (sMarkerPos == "left" or sMarkerPos == "top") and unit[offAxis] > nBorder then
        else
            unit.oob = true;
        end

        local rank = ranks[unit[matchAxis]]
        unit.rank = rank.rank;
        unit.rankfaction = rank.faction;

        if unit.rankfaction ~= unit.unitfaction then
            unit.front = true;
        end
        
        if not finalUnits[unit[matchAxis]] then
            finalUnits[unit[matchAxis]] = {};
        end
        finalUnits[unit[matchAxis]][unit[offAxis]] = unit;
        --table.insert(finalUnits, unit);
    end
    
    return ranks, finalUnits;
end

function setExposed(unit, bExposed)
    local nExposed = 0;
    if bExposed then nExposed = 1; end
    if unit.ctnode then
        DB.setValue(DB.findNode(unit.ctnode), "exposed", "number", nExposed);
    end
end

function checkForExposedUnits(ranks, units, sMarkerPos)
    -- Debug.chat('checkForExposedUnits()');
    for rank,file in pairs(units) do
        for _,unit in pairs(file) do
            local bExposed = isUnitExposed(unit, units, sMarkerPos)
            setExposed(unit, bExposed);
        end
    end
end

function isUnitExposed(unit, units, sMarkerPos)
    local matchAxis, offAxis = getAxis(sMarkerPos);
    if not matchAxis or not offAxis then
        return;
    end

    -- Debug.chat('isUnitExposed', unit);
    -- if the unit is out of bounds, always mark it exposed
    if unit.oob then
        return true;
    end
    -- Unit's in the rear are always exposed
    if unit.rank == "rear" then
        --Debug.chat('unit is in rear');
        return true;
    end
    -- Center and reserve are always protected if a side has a front and rear
    if unit.rank == "center" or unit.rank == "reserve" then
        -- Only check if the unit is in its own side's rank
        if unit.rankfaction == unit.unitfaction then
            if factionHasFrontAndRear(unit.unitfaction, units) then
                --Debug.chat('unit is in center/reserves and there is a front and rear')
                return false;
            end
        end
    end

    local rankPos = unit[matchAxis];
    local bLeft = false;
    local bRight = false;

    for _, checkUnit in pairs(units[rankPos]) do
        -- Unit should ignore checking itself.
        if not checkUnit.oob and unit.ctnode ~= checkUnit.ctnode then
            --Debug.chat('checking against', checkUnit.ctnode);
            --Debug.chat(unit[offAxis], checkUnit[offAxis])
            if checkUnit[offAxis] < unit[offAxis] then
                --Debug.chat('there is a unit to the left')
                bLeft = true;
            elseif checkUnit[offAxis] > unit[offAxis] then
                --Debug.chat('there is a unit to the right');
                bRight = true;
            end
        end
    end
    return not (bLeft and bRight)
end

function factionHasFrontAndRear(faction, units)
    -- Debug.chat('factionHasFrontAndRear()')
    local bFront = false;
    local bRear = false;
    for rank,file in pairs(units) do
        for _,unit in pairs(file) do
            if unit.unitfaction == faction and unit.rankfaction == faction and unit.rank == "rear" then
                bRear = true;
            elseif unit.unitfaction == faction and (unit.rankfaction ~= faction or unit.rank == "vanguard") then
                bFront = true;
            end
        end
    end
    return bFront and bRear;
end

function factionHasRear(faction, units)
    for rank,file in pairs(units) do
        for _,unit in pairs(file) do
            if unit.unitfaction == faction and unit.rankfaction == faction and unit.rank == "rear" then
                return true;
            end
        end
    end
    return false;
end

function factionHasFront(faction, units)
    for rank,file in pairs(units) do
        for _,unit in pairs(file) do
            if unit.unitfaction == faction and unit.rankfaction ~= faction then
                return true;
            end
        end
    end
    return false;
end

function getAxis(sMarkerPos)
    local matchAxis, offAxis;
    if sMarkerPos == "left" or sMarkerPos == "right" then 
        matchAxis = "y";
        offAxis = "x";
    elseif sMarkerPos == "top" or sMarkerPos == "bottom" then 
        matchAxis = "x";
        offAxis = "y" 
    end
    return matchAxis, offAxis;
end