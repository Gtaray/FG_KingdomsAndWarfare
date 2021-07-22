-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onIDChanged();
end

function onLockChanged()
	StateChanged();
end

function StateChanged()
	if header.subwindow then
		header.subwindow.update();
	end
	if main.subwindow then
		main.subwindow.update();
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	description.setReadOnly(bReadOnly);
end

function onIDChanged()
	onNameUpdated();
	if header.subwindow then
		header.subwindow.updateIDState();
	end
	if Session.IsHost then
		if main.subwindow then
			main.subwindow.update();
		end
	else
		local bID = LibraryData.getIDState("unit", getDatabaseNode(), true);
		tabs.setVisibility(bID);
	end
end

function onNameUpdated()
	local nodeRecord = getDatabaseNode();
	local bID = LibraryData.getIDState("unit", nodeRecord, true);
	
	local sTooltip = "";
	if bID then
		sTooltip = DB.getValue(nodeRecord, "name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_npc")
		end
	else
		sTooltip = DB.getValue(nodeRecord, "nonid_name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_nonid_npc")
		end
	end
	setTooltipText(sTooltip);
end
