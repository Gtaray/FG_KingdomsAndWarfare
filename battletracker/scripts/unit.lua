-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- todo menu option to delete
function onInit()
	DB.addHandler(getDatabaseNode().getPath("commander_link"), "onUpdate", commanderUpdated);
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("commander_link"), "onUpdate", commanderUpdated);
end

function commanderUpdated(nodeLink)
	local sRecord = CombatManager.CT_MAIN_PATH;
	if nodeLink then
		_, sRecord = DB.getValue(nodeLink, "", "", CombatManager.CT_MAIN_PATH);
	end

	Debug.chat("unit commander updated", sRecord, windowlist.window.getDatabaseNode().getPath());
	if sRecord ~= windowlist.window.getDatabaseNode().getPath() then
		close();
	end
end