-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local commanderWindows = mapCommanderWindows();
	for _,nodeCombatant in pairs(CombatManagerKw.getCombatantNodes(CombatManagerKw.LIST_MODE_BOTH)) do
		addCombatant(nodeCombatant, commanderWindows);
	end

	DB.addHandler(CombatManager.CT_COMBATANT_PATH, "onDelete", onDeleted);

	CombatManagerKw.registerCombatantAddedHandler(combatantAdded);
	CombatManagerKw.registerUnitSelectionHandler(primaryUnitSelected, 1);
	CombatManagerKw.registerUnitSelectionHandler(secondaryUnitSelected, 2);

	-- Handle color changes
	if Session.IsHost and UtilityManager.isClientFGU() then
		User.onIdentityStateChange = onIdentityStateChange;
	end
end

function onClose()
	DB.removeHandler(CombatManager.CT_COMBATANT_PATH, "onDelete", onDeleted);
	
	CombatManagerKw.unregisterCombatantAddedHandler(combatantAdded);
	CombatManagerKw.unregisterUnitSelectionHandler(primaryUnitSelected, 1);
	CombatManagerKw.unregisterUnitSelectionHandler(secondaryUnitSelected, 2);
end

function onIdentityStateChange(sIdentity, sUser, sStateName, vState)
	if sStateName == "color" and sUser ~= "" then
		local sColor = User.getIdentityColor(sIdentity);

		-- The long process of getting the actor whose color needs changing.
		for _,winCommander in ipairs(list.getWindows()) do
			local node = winCommander.getDatabaseNode();
			if node then
				local rActor = ActorManager.resolveActor(node);
				if rActor and ActorManager.isPC(rActor) then
					local nodeCreature = ActorManager.getCreatureNode(rActor);
					if nodeCreature then
						local sCreatureIdentity = nodeCreature.getName();
						if sCreatureIdentity == sIdentity then
							winCommander.color_swatch.setColor(sColor);
						end
					end
				end
			end
		end
	end
end

function combatantAdded(nodeEntry)
	Debug.chat('combatantAdded')
	addCombatant(nodeEntry);
end

function onDeleted(nodeDeleted)
	if nodeDeleted == primary_selected_unit.subwindow.getDatabaseNode() then
		primary_selected_unit.setValue("battletracker_emptysummary");
	elseif nodeDeleted == secondary_selected_unit.subwindow.getDatabaseNode() then
		secondary_selected_unit.setValue("battletracker_emptysummary");
	end
end

function sortUnitsLast(nodeLeft, nodeRight)
	return ActorManagerKw.isUnit(nodeRight);
end

function mapCommanderWindows()
	local commanderWindows = {};
	for _,winCommander in ipairs(list.getWindows()) do
		addToMap(commanderWindows, winCommander);
	end
	return commanderWindows;
end

function addToMap(commanderWindows, winCommander)
	Debug.chat('addToMap');
	local nodeCommander = winCommander.getDatabaseNode();
	if not commanderWindows[nodeCommander] then
		Debug.chat('added');
		commanderWindows[nodeCommander] = winCommander;
	end
end

function getuncommandedUnitWindows()
	local uncommandedUnitWindows = {};
	for _,winUnit in ipairs(uncommanded_units.subwindow.list.getWindows()) do
		trackUnitMissingCommander(uncommandedUnitWindows, winUnit);
	end
	return uncommandedUnitWindows;
end

function trackUnitMissingCommander(uncommandedUnitWindows, winUnit)
	local nodeCombatant = winUnit.getDatabaseNode();
	local nodeCommander = ActorManagerKw.getCommanderCT(nodeCombatant);
	if nodeCommander then
		if not uncommandedUnitWindows[nodeCommander] then
			uncommandedUnitWindows[nodeCommander] = {};
		end

		table.insert(uncommandedUnitWindows[nodeCommander], winUnit);
	end
end

function addCombatant(nodeCombatant, commanderWindows, uncommandedUnitWindows)
	Debug.chat('addCombatant', nodeCombatant)
	if not commanderWindows then
		commanderWindows = mapCommanderWindows()
	end
	if not uncommandedUnitWindows then
		uncommandedUnitWindows = getuncommandedUnitWindows();
	end


	if ActorManagerKw.isUnit(nodeCombatant) then
		addUnit(nodeCombatant, commanderWindows, uncommandedUnitWindows);
	else
		addCommander(nodeCombatant, commanderWindows, uncommandedUnitWindows);
	end
end

function addCommander(nodeCombatant, commanderWindows, uncommandedUnitWindows)
	Debug.chat('addCommander');
	for _,winCommander in pairs(commanderWindows) do
		if winCommander.getDatabaseNode() == nodeCombatant then
			Debug.chat('commander is already added')
			return;
		end
	end
	local winCommander = list.createWindow(nodeCombatant);
	addToMap(commanderWindows, winCommander);

	local nodeCommander = winCommander.getDatabaseNode();


	-- If color is not already assigned, then assign a random one
	local sColor = DB.getValue(nodeCommander, "color", "");
	if Session.IsHost and sColor == "" then
		-- Assign a random color
		sColor = getRandomCommanderColor();
		if (sColor or "") ~= "" then
			winCommander.color_swatch.setColor(sColor);
		end	
	end

	-- If there are uncommanded units that should have this commander, assign them
	if uncommandedUnitWindows[nodeCommander] then
		for _,winUnit in ipairs(uncommandedUnitWindows[nodeCommander]) do
			winCommander.list.createWindow(winUnit.getDatabaseNode());
			winUnit.close();
		end
		uncommandedUnitWindows[nodeCommander] = nil;
	end
end

function addUnit(nodeCombatant, commanderWindows, uncommandedUnitWindows)
	local nodeCommander = ActorManagerKw.getCommanderCT(nodeCombatant);
	if nodeCommander and commanderWindows[nodeCommander] then
		for _,winUnit in ipairs(commanderWindows[nodeCommander].list.getWindows()) do
			if winUnit.getDatabaseNode() == nodeCombatant then
				return;
			end
		end
		commanderWindows[nodeCommander].list.createWindow(nodeCombatant);
	else
		for _,winUnit in ipairs(uncommanded_units.subwindow.list.getWindows()) do
			if winUnit.getDatabaseNode() == nodeCombatant then
				return;
			end
		end
		local winUnit = uncommanded_units.subwindow.addUnit(nodeCombatant);
		trackUnitMissingCommander(uncommandedUnitWindows, winUnit);
	end
end

function getRandomCommanderColor()
	local colorsUsed = {};
	for _,winCommander in pairs(list.getWindows()) do
		local commanderNode = winCommander.getDatabaseNode();
		if not ActorManager.isPC(commanderNode) then
			local sColor = DB.getValue(commanderNode, "color", "");
			if (sColor or "") ~= "" then
				colorsUsed[sColor] = true;
			end
		end
	end

	local availableColors = {};
	for color,_ in pairs(DataKW.colors) do
		if not colorsUsed[color] then
			table.insert(availableColors, color);
		end
	end

	sColor = "";
	-- Just in case someone is crazy and wants to have 9+ NPC commander's
	if #availableColors < 1 then
		--%02x: 0 means replace " "s with "0"s, 2 is width, x means hex
		sColor = string.format("FF%02x%02x%02x", math.random(0,255), math.random(0,255), math.random(0,255)):upper();
	else
	 	sColor = availableColors[math.random(1, #availableColors)];
	end
	return sColor;
end

-- todo break this down to work as intended, presently it is all on the wrong relative scope if nothing else
function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		return CampaignDataManager.handleDrop("combattracker", draginfo);
	end
	
	-- Capture any drops meant for specific CT entries
	local win = list.getWindowAt(x,y);
	if win then
		local nodeWin = win.getDatabaseNode();
		if nodeWin then
			return CombatManager.onDrop("ct", nodeWin.getPath(), draginfo);
		end
	end
end

function primaryUnitSelected(nodeUnit)
	primary_selected_unit.setValue("battletracker_unitsummary", nodeUnit);
	if secondary_selected_unit.subwindow and secondary_selected_unit.subwindow.getDatabaseNode() == nodeUnit then
		secondary_selected_unit.setValue("battletracker_emptysummary");
	end
end

function secondaryUnitSelected(nodeUnit)
	secondary_selected_unit.setValue("battletracker_unitsummary", nodeUnit);
	if primary_selected_unit.subwindow and primary_selected_unit.subwindow.getDatabaseNode() == nodeUnit then
		primary_selected_unit.setValue("battletracker_emptysummary");
	end
end