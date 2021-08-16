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
        local nodeActions = nodePower.createChild("actions");

        if DataKW.domainpowers[sNameLower] then
            for _,vAction in ipairs(DataKW.domainpowers[sNameLower]) do
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

                elseif vAction.type == "effect" then
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
                end
            end
            CharManager.outputUserMessage("message_ps_addaction", sPowerName)
        else
            CharManager.outputUserMessage("message_ps_addaction_empty", sPowerName)
        end
    end
end