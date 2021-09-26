-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- todo menu option to delete
function onInit()
	DB.addHandler(CombatManager.CT_LIST .. ".*.commander_link", "onUpdate", commanderUpdated);
	DB.addHandler(CombatManager.CT_LIST .. ".*.commander_link", "onDelete", commanderDeleted);
end

function onClose()
	DB.removeHandler(CombatManager.CT_LIST .. ".*.commander_link", "onUpdate", commanderUpdated);
end

function commanderUpdated(nodeLink)
	Debug.chat("updated", nodeLink, nodeLink.getValue());
	if nodeLink then
		local sClass, sRecord = nodeLink.getValue();
		if sRecord == getDatabaseNode().getPath() then
			list.createWindow(DB.getChild(nodeLink, ".."));
		end
	end
end

function commanderDeleted(nodeLink)
	Debug.chat("deleted", nodeLink, nodeLink.getValue());
end

function setColor(sColor)
	for _,winUnit in ipairs(list.getWindows()) do
		DB.setValue(winUnit.getDatabaseNode(), "color", "string", sColor); -- Let the TokenManager do the coloration work.
	end
end

-- todo drop handling ecosystem
function onDrop(x, y, draginfo)
	local sType = draginfo.getType();
	local sClass, sRecord = draginfo.getShortcutData();
	if sType == "battletrackerunit" then
		local sPath = getDatabaseNode().getPath();
		local node = draginfo.getDatabaseNode();
		local _,sCommander = DB.getValue(node, "commander_link");
		if sCommander ~= sPath then
			DB.setValue(node, "commander_link", "windowreference", "npc", sPath);
		end
		return true;
	elseif sClass == "reference_unit" then
		Debug.chat()
		CombatManagerKw.setUnitDropCommander(getDatabaseNode());
		return CampaignDataManager.handleDrop("combattracker", draginfo);
	end
end