-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- todo menu option to delete
function onInit()
	DB.addHandler(getDatabaseNode().getPath("commander_link"), "onUpdate", commanderUpdated);
	DB.addHandler(getDatabaseNode().getPath("commander_link"), "onDelete", commanderDeleted);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("commander_link"), "onUpdate", commanderUpdated);
	DB.removeHandler(getDatabaseNode().getPath("commander_link"), "onDelete", commanderDeleted);
end

function commanderUpdated(nodeLink)
	local sRecord = CombatManager.CT_MAIN_PATH;
	if nodeLink then
		_, sRecord = DB.getValue(nodeLink, "", "", CombatManager.CT_MAIN_PATH);
	end

	if sRecord ~= windowlist.window.getDatabaseNode().getPath() then
		close();
	end
end

function commanderDeleted(nodeLink)
	close();
end