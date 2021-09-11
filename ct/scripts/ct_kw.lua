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

	CombatManager.setCustomTurnStart(onTurnStartSetCommander);
	CombatManager.setCustomDeleteCombatantHandler(onCommanderDelete);
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
	local nShowToken = DB.getValue(node, "tokenvis", 1);
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
					else
						DB.setValue(node, "hide", "number", 1);
					end

					DB.setValue(node, "tokenvis", "number", nShowToken);
				end
			end
		end
	end

	list.applyFilter();
end

-- This sets a value for the last non-unit actor to have gone in the CT
-- This is used by the CT filter to show units for the last active commander
function onTurnStartSetCommander(nodeCT)
	-- Only proceed for non-units
	if not ActorManagerKw.isUnit(nodeCT) then
		local lastNode = DB.createChild(DB.findNode(CombatManager.CT_MAIN_PATH), "lastcommander", "string");
		lastNode.setValue(nodeCT.getPath());

		list.applyFilter();
	end
end

function onCommanderDelete(nodeCT)
	list.applyFilter();
end

function onFilter(w)
	local node = w.getDatabaseNode();

	-- Units without commanders should ALWAYS be visible
	local cmdrNode = ActorManagerKw.getCommanderCT(node);
	if not cmdrNode then
		return true;
	end

	-- Check if unit is manually hidden
	local hide = DB.getValue(node, "hide", 0)
	
	-- Show units for the last non-unit actor on the combat tracker. 
	local lastCommandersUnit = CombatManagerKw.isUnitOwnedByLastCommander(node);
	return lastCommandersUnit or hide == 0;
end