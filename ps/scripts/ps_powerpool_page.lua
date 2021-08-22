function onInit()
    if not Session.IsHost then
        powerpool_iedit.setVisible(false);
        powerpool_iadd.setVisible(false);
        features_iedit.setVisible(false);
        features_iadd.setVisible(false);
        powers_iedit.setVisible(false);
        powers_iadd.setVisible(false);
    end
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
end