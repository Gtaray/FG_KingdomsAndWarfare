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
	return false;
end

function endIntrigue()
	for _,nodePS in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(nodePS, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				PowerManagerKw.resetIntriguePowers(nodePC);
			end
		end
	end

	ChatManager.Message(Interface.getString("message_ps_intrigueended"), true);
end