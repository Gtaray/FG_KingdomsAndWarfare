-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local enableglobaltoggle = true;
local fIsCTHidden;
local fNextActor;

function onInit()
    if super and super.onInit then
        super.onInit();
    end
    list.toggleUnits = toggleUnits;
    list.onUnitsToggle = onUnitsToggle;
    list.onFilter = onFilter;

    -- Override the default isCTHidden function to account for units
    -- which can be the friendly faction, but also can be hidden and skipped
    fIsCTHidden = CombatManager.isCTHidden;
    CombatManager.isCTHidden = isCTUnitHidden;
    fNextActor = CombatManager.nextActor;
    CombatManager.nextActor = nextActor;

    -- Any time this is opened, make sure to set the units to visible
    for _,v in pairs(list.getWindows()) do
        if DB.getValue(v.getDatabaseNode(), "isUnit", 0) == 0 then
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

function isCTUnitHidden(vEntry)
    local isHidden = fIsCTHidden(vEntry);

    -- replicate argument checking
    local nodeCT = nil;
	if type(vEntry) == "string" then
		nodeCT = DB.findNode(vEntry);
	elseif type(vEntry) == "databasenode" then
		nodeCT = vEntry;
	end
	if not nodeCT then
		return false;
	end

    local bIsUnit = DB.getValue(nodeCT, "isUnit", 0) == 1;
    if bIsUnit then
        local hide = DB.getValue(nodeCT, "hide", 0) == 1;
        return isHidden or hide;
    end

    return isHidden;
end

-- We have to override this whole function just to add the one little
-- check in the middle to see if the actor is a unit
-- and if they are a unit, ignore the 'friends are always visible' clause
-- 5e doesn't override this function, but another extension might, and this could
-- definitely cause issues.
function nextActor(bSkipBell, bNoRoundAdvance)
    if not Session.IsHost then
		return;
	end

	local nodeActive = CombatManager.getActiveCT();
	local nIndexActive = 0;
	
	-- Check the skip hidden NPC option
	local bSkipHidden = OptionsManager.isOption("CTSH", "on");
	
	-- Determine the next actor
	local nodeNext = nil;
	local aEntries = CombatManager.getSortedCombatantList();
	if #aEntries > 0 then
		if nodeActive then
			for i = 1,#aEntries do
				if aEntries[i] == nodeActive then
					nIndexActive = i;
					break;
				end
			end
		end
        local bIsUnit = DB.getValue(aEntries[nIndexActive+1], "isUnit", 0) == 1;
        -- Force units to always check if they're hidden
		if bIsUnit or bSkipHidden then
			local nIndexNext = 0;
			for i = nIndexActive + 1, #aEntries do
				if not bIsUnit and DB.getValue(aEntries[i], "friendfoe", "") == "friend" then
					nIndexNext = i;
					break;
				else
					if not CombatManager.isCTHidden(aEntries[i]) then
						nIndexNext = i;
						break;
					end
				end
			end
			if nIndexNext > nIndexActive then
				nodeNext = aEntries[nIndexNext];
				for i = nIndexActive + 1, nIndexNext - 1 do
					CombatManager.showTurnMessage(aEntries[i], false);
				end
			end
		else
			nodeNext = aEntries[nIndexActive + 1];
		end
	end

	-- If next actor available, advance effects, activate and start turn
	if nodeNext then
		-- End turn for current actor
		CombatManager.onTurnEndEvent(nodeActive);
	
		-- Process effects in between current and next actors
		if nodeActive then
			CombatManager.onInitChangeEvent(nodeActive, nodeNext);
		else
			CombatManager.onInitChangeEvent(nil, nodeNext);
		end
		
		-- Start turn for next actor
		CombatManager.requestActivation(nodeNext, bSkipBell);
		CombatManager.onTurnStartEvent(nodeNext);
	elseif not bNoRoundAdvance then
		if bSkipHidden then
			for i = nIndexActive + 1, #aEntries do
				CombatManager.showTurnMessage(aEntries[i], false);
			end
		end
		CombatManager.nextRound(1);
	end
end

-- toggles units for all commanders
function toggleUnits()
    if not enableglobaltoggle then
        return;
    end

    local unitson = button_global_units.getValue();
    for _,v in pairs(list.getWindows()) do
        local node = v.getDatabaseNode();
        local isUnit = DB.getValue(node, "isUnit", 0) == 1;
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
            local bIsUnit = DB.getValue(node, "isUnit", 0) == 1;
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
    local hide = DB.getValue(w.getDatabaseNode(), "hide", 0)
    return hide == 0;
end