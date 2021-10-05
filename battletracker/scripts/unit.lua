-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- todo menu option to delete
function onInit()
	local nodeUnit = getDatabaseNode();
	activeUpdated(DB.getChild(nodeActive, "activeunit"));
	DB.addHandler(nodeUnit.getPath("commander_link"), "onUpdate", commanderUpdated);
	DB.addHandler(nodeUnit.getPath("activeunit"), "onUpdate", activeUpdated);
	
	updateName();
end

function onClose()
	DB.removeHandler(getDatabaseNode().getPath("commander_link"), "onUpdate", commanderUpdated);
	DB.removeHandler(getDatabaseNode().getPath("activeunit"), "onUpdate", activeUpdated);
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

function updateName()
	token.setTooltipText(name.getValue());
end

function activeUpdated(nodeActive)
	local bActive = nodeActive and (nodeActive.getValue() == 1);
	if bActive then
		setFrame("border");
	else
		setFrame(nil);
	end
end