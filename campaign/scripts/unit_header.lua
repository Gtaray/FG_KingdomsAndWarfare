-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
	updateIDState();
end

function update()
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	name.setReadOnly(bReadOnly);
	nonid_name.setReadOnly(bReadOnly);
	token.setReadOnly(bReadOnly);
end

function updateIDState()
	if Session.IsHost then return; end
	local bID = LibraryData.getIDState("unit", getDatabaseNode());
	name.setVisible(bID);
	nonid_name.setVisible(not bID);
end
