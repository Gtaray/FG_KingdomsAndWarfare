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

function addDefaultActions()
    for k,v in pairs(powers.getWindows()) do
        local powernode = v.getDatabaseNode()
        local powername = DB.getValue(powernode, "name", "");
        if powernode and (powername or "") ~= "" then
            loadActionData(powername, powernode)
        end
    end
end

function loadActionData(sPowerName, nodePower)
    if not nodePower then
        return;
    end

    local sNameLower = sPowerName:lower();

    -- Only process if there are no actions already added
    if DB.getChildCount(nodePower, "actions") == 0 then
        if DataKW.domainpowers[sNameLower] then
            local nodeActions = nodePower.createChild("actions");

            -- the added flag only exists here because a power COULD have effects, but if aura effects
            -- isn't loaded, then it won't add. So we want to make sure we don't print the 'added' message
            -- if no effects were added due to that.
            local bAdded = false
            for _,vAction in ipairs(DataKW.domainpowers[sNameLower]) do
                if addAction(nodeActions, vAction, sPowerName) then
                    bAdded = true;
                end
            end
            if bAdded then
                CharManager.outputUserMessage("message_ps_addaction", sPowerName)
            end
        else
            CharManager.outputUserMessage("message_ps_addaction_empty", sPowerName)
        end
    end
end

function addAction(nodeActions, vAction, sPowerName)
    if vAction.type == "powersave" then
        local nodeCastAction = DB.createChild(nodeActions);
        DB.setValue(nodeCastAction, "type", "string", "cast");

        if nodeCastAction then
            DB.setValue(nodeCastAction, "savetype", "string", vAction.save);
            DB.setValue(nodeCastAction, "savemagic", "number", 0);
            
            if vAction.savemod then
                DB.setValue(nodeCastAction, "savedcbase", "string", "fixed");
                DB.setValue(nodeCastAction, "savedcmod", "number", tonumber(vAction.savemod) or 0);
            end
        end

        return true;

    elseif vAction.type == "effect" then
        -- if this effect has an aura and the aura effects extension isn't loaded, don't add it.
        if vAction.sName:lower():match("aura:") and not KingdomsAndWarfare.isAuraEffectsLoaded() then
            CharManager.outputUserMessage("message_ps_addaction_aura", sPowerName)
            return false;
        end

        local nodeAction = DB.createChild(nodeActions);
        DB.setValue(nodeAction, "type", "string", "effect");
        
        DB.setValue(nodeAction, "label", "string", vAction.sName);

        if vAction.sTargeting then
            DB.setValue(nodeAction, "targeting", "string", vAction.sTargeting);
        end
        if vAction.sApply then
            DB.setValue(nodeAction, "apply", "string", vAction.sApply);
        end
        
        local nDuration = tonumber(vAction.nDuration) or 0;
        if nDuration ~= 0 then
            DB.setValue(nodeAction, "durmod", "number", nDuration);
            DB.setValue(nodeAction, "durunit", "string", vAction.sUnits);
        end

        return true;
    end

    return false;
end