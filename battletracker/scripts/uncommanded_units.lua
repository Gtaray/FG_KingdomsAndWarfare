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
	Debug.chat("commander deleted", nodeCommander)
	local sPath = nodeCommander.getPath();
	for _,nodeCombatant in pairs(CombatManager.getCombatantNodes()) do
		if ActorManagerKw.isUnit(nodeCombatant) then
			local _,sRecord = DB.getValue(nodeCombatant, "commander_link");
			Debug.chat(sRecord, sPath);
			if sRecord == sPath then
				list.createWindow(nodeCombatant);
			end
		end
	end
end

function commanderLinkUpdated(nodeLink)
	local sRecord;
	if nodeLink then
		Debug.chat("uncommmanded link update 1", nodeLink, nodeLink.getValue());
		_, sRecord = nodeLink.getValue();
	end

	if not sRecord then
		Debug.printstack();
	end
	Debug.chat("uncommmanded link update 2", nodeLink, sRecord);
	if (not sRecord) or (not DB.findNode(sRecord)) then
		list.createWindow(DB.getChild(nodeLink, ".."));
	end
end

-- todo drop handling ecosystem
function onDrop(x, y, draginfo)
	Debug.chat("uncommandeddrop", draginfo, draginfo.getDatabaseNode())
	local sType = draginfo.getType();
	if sType == "battletrackerunit" then
		DB.deleteNode(DB.getPath(draginfo.getDatabaseNode(), "commander_link"));
	end
end