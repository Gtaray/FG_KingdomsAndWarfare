-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	DB.addHandler(CombatManager.CT_COMBATANT_PATH, "onDelete", commanderDeleted);
	DB.addHandler(CombatManager.CT_COMBATANT_PATH .. ".commander_link", "onUpdate", commanderLinkUpdated);
end

function onClose()
	DB.removeHandler(CombatManager.CT_COMBATANT_PATH, "onDelete", commanderDeleted);
	DB.removeHandler(CombatManager.CT_COMBATANT_PATH .. ".commander_link", "onUpdate", commanderLinkUpdated);
end

function commanderDeleted(nodeCommander)
	local sPath = nodeCommander.getPath();
	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes()) do
		if ActorManagerKw.isUnit(nodeCombatant) then
			local _,sRecord = DB.getValue(nodeCombatant, "commander_link");
			if sRecord == sPath then
				DB.setValue(nodeCombatant, "commander_link", "windowreference", "", "");
			end
		end
	end
end

function commanderLinkUpdated(nodeLink)
	local sRecord;
	if nodeLink then
		_, sRecord = nodeLink.getValue();
	end

	if (not sRecord) or (not DB.findNode(sRecord)) then
		addUnit(DB.getChild(nodeLink, ".."));
	end
end

function onDrop(x, y, draginfo)
	local sType = draginfo.getType();
	if sType == "battletrackerunit" then
		DB.setValue(nodeCombatant, "commander_link", "windowreference", "", "");
	end
end

function addUnit(nodeUnit)
	list.createWindow(nodeUnit);
	parentcontrol.setVisible(true);
end