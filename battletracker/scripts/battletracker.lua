-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local combatants = DB.getChildren(CombatManager.CT_LIST);
	local commanderWindows = mapCommanderWindows();
	for _,nodeCombatant in pairs(combatants) do
		addCombatant(nodeCombatant, commanderWindows);
	end

	DB.addHandler(CombatManager.CT_LIST .. ".*.link", "onUpdate", linkUpdated);

	CombatManagerKw.registerUnitSelectionHandler(1, function(nodeUnit) primary_selected_unit.setValue("battletracker_unitsummary", nodeUnit) end);
	CombatManagerKw.registerUnitSelectionHandler(2, function(nodeUnit) secondary_selected_unit.setValue("battletracker_unitsummary", nodeUnit) end);
end

function onClose()
	DB.removeHandler(CombatManager.CT_LIST .. ".*.link", "onUpdate", linkUpdated);
end

function linkUpdated(nodeLink)
	sClass, sRecord = nodeLink.getValue();
	if (sClass or "") ~= "" then
		addCombatant(DB.getChild(nodeLink, ".."))
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
	local nodeCommander = winCommander.getDatabaseNode();
	if commanderWindows[nodeCommander] then
		--todo figure out what to do here, maybe nothing?
	else
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
	for _,winCommander in pairs(commanderWindows) do
		if winCommander.getDatabaseNode() == nodeCombatant then
			return;
		end
	end
	local winCommander = list.createWindow(nodeCombatant);
	addToMap(commanderWindows, winCommander);

	local nodeCommander = winCommander.getDatabaseNode();
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

-- todo break this down to work as intended, presently it is all on the wrong relative scope if nothing else
function notOnDrop(x, y, draginfo)
	if Session.IsHost then
		local sClass, sRecord = draginfo.getShortcutData();
		if sClass == "reference_unit" then
			local ctnode = draginfo.getDatabaseNode();
			local bIsCT = (UtilityManager.getRootNodeName(ctnode) == CombatManager.CT_MAIN_PATH);
			if ctnode and ActorManagerKw.isUnit(ctnode) and bIsCT then
				-- only process drops on npcs/pcs, not units
				-- Only process if we're dropping a CT node. If it's not a CT node, then process as normal
				local cmdrnode = getDatabaseNode();
				if not ActorManagerKw.isUnit(cmdrnode) then
					DB.setValue(ctnode, "commander", "string", name.getValue());
					DB.setValue(ctnode, "initresult", "number", initresult.getValue() - 0.1);

					local friendfoe = DB.getValue(cmdrnode, "friendfoe", "")
					if friendfoe ~= "" then
						DB.setValue(ctnode, "friendfoe", "string", friendfoe)
					end

					-- Setting owner isn't working here
					ctnode.addHolder(DB.getOwner(cmdrnode), true);
					return true;
				end
			end
		elseif sClass == "reference_martialadvantage" or sClass == "reference_unittrait" then
			local ctnode = getDatabaseNode();
			local bIsCT = (UtilityManager.getRootNodeName(ctnode) == CombatManager.CT_MAIN_PATH);
			if ctnode and ActorManagerKw.isUnit(ctnode) and bIsCT then
				local maNode = draginfo.getDatabaseNode();
				local sName = DB.getValue(maNode, "name", "");
				if (sName or "") == "" then
					return true;
				end
				local sText = DB.getText(maNode, "text", "");
				local nodeList = ctnode.createChild("traits");
				if not nodeList then
					return true;
				end

				-- Add the item
				local vNew = nodeList.createChild();
				DB.setValue(vNew, "name", "string", sName);
				DB.setValue(vNew, "desc", "string", sText);
				DB.setValue(vNew, "locked", "number", 1);

				local sEffect = DataKW.traitdata[sName:lower()];
				if sEffect then
					EffectManager.addEffect("", "", ctnode, { sName = sName .. "; " .. sEffect, nDuration = 0, nGMOnly = 0 }, false);
				end

				CombatManagerKw.parseUnitTrait(ActorManager.resolveActor(ctnode), vNew)

				CharManager.outputUserMessage("unit_traits_message_traitadd", sName, DB.getValue(ctnode, "name", ""));

				return true;
			end
		end
	end
	return false;
end