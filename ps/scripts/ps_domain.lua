-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onLockChanged()
	local bReadOnly = DB.getValue(getDatabaseNode(), "domain.locked", 0) == 1;
	diplomacy.setReadOnly(bReadOnly);
	espionage.setReadOnly(bReadOnly);
	lore.setReadOnly(bReadOnly);
	operations.setReadOnly(bReadOnly);

	communications.setReadOnly(bReadOnly);
	resolve.setReadOnly(bReadOnly);
	resources.setReadOnly(bReadOnly);

	diplomacytrack.setReadOnly(bReadOnly);
	espionagetrack.setReadOnly(bReadOnly);
	loretrack.setReadOnly(bReadOnly);
	operationstrack.setReadOnly(bReadOnly);
	
	communicationstrack.setReadOnly(bReadOnly);
	resolvetrack.setReadOnly(bReadOnly);
	resourcestrack.setReadOnly(bReadOnly);

	hardlocked.setVisible(not Session.IsHost and bReadOnly);
end

function onDrop(x, y, draginfo)
	if not Session.IsHost then
		return;
	end
	local sDragType = draginfo.getType();
	if sDragType == "shortcut" then
		local sClass,sRecord = draginfo.getShortcutData();
		if sClass == "reference_domain" then
			KingdomsAndWarfare.addDomainToPartySheet(DB.findNode(sRecord))
			KingdomsAndWarfare.addDefaultActionsToPartySheetPowers()
			return true;
		end
	end
	return false;
end