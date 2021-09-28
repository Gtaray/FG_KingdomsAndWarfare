-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- todo menu option to delete
function onInit()
	DB.addHandler(CombatManager.CT_LIST .. ".*.commander_link", "onUpdate", commanderUpdated);
	DB.addHandler(getDatabaseNode().getPath("friendfoe"), "onUpdate", onFactionUpdated);
end

function onClose()
	DB.removeHandler(CombatManager.CT_LIST .. ".*.commander_link", "onUpdate", commanderUpdated);
	DB.removeHandler(getDatabaseNode().getPath("friendfoe"), "onUpdate", onFactionUpdated);
end

function commanderUpdated(nodeLink)
	if nodeLink then
		local sClass, sRecord = nodeLink.getValue();
		if sRecord == getDatabaseNode().getPath() then
			list.createWindow(DB.getChild(nodeLink, ".."));
		end
	end
end

function onFactionUpdated(nodeUpdated)
	local sFaction = nodeUpdated.getValue();
	for k,v in pairs(list.getWindows()) do
		local windownode = v.getDatabaseNode();
		if windownode then
			DB.setValue(windownode, "friendfoe", "string", sFaction);
		end
	end
end

function setColor(sColor)
	for _,winUnit in ipairs(list.getWindows()) do
		DB.setValue(winUnit.getDatabaseNode(), "color", "string", sColor); -- Let the TokenManager do the coloration work.
	end
end

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
		CombatManagerKw.setUnitDropCommander(getDatabaseNode());
		return CampaignDataManager.handleDrop("combattracker", draginfo);
	end
end