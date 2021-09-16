-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	for _,nodeCombatant in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		addCombatant(nodeCombatant);
	end
	-- todo subscribve to additions
end

function addCombatant(nodeCombatant)
	if ActorManagerKw.isUnit(nodeCombatant) then
	else
	end
end

function onDrop(x, y, draginfo)
    if Session.IsHost then
        local sClass, sRecord = draginfo.getShortcutData();
        if sClass == "reference_unit" then
            local ctnode = draginfo.getDatabaseNode();
            local bIsCT = (UtilityManager.getRootNodeName(ctnode) == CombatManager.CT_MAIN_PATH);
            if ctnode and ActorManagerKw.isUnit(ctnode) and bIsCT then
                -- only process drops on npcs/pcs, not units
                -- Only process if we're dropping a CT node. If it's not a CT node, then process as normal
                local cmdrnode = getDatabaseNode();
                if not ActorManagerKw.isUnit(cmdrnode) then
                    DB.setValue(ctnode, "commander", "string", name.getValue());
                    DB.setValue(ctnode, "initresult", "number", initresult.getValue() - 0.1);

                    local friendfoe = DB.getValue(cmdrnode, "friendfoe", "")
                    if friendfoe ~= "" then
                        DB.setValue(ctnode, "friendfoe", "string", friendfoe)
                    end

                    -- Setting owner isn't working here
                    ctnode.addHolder(DB.getOwner(cmdrnode), true);
                    return true;
                end
            end
        elseif sClass == "reference_martialadvantage" or sClass == "reference_unittrait" then
            local ctnode = getDatabaseNode();
            local bIsCT = (UtilityManager.getRootNodeName(ctnode) == CombatManager.CT_MAIN_PATH);
            if ctnode and ActorManagerKw.isUnit(ctnode) and bIsCT then
                local maNode = draginfo.getDatabaseNode();
                local sName = DB.getValue(maNode, "name", "");
                if (sName or "") == "" then
                    return true;
                end
                local sText = DB.getText(maNode, "text", "");
                local nodeList = ctnode.createChild("traits");
                if not nodeList then
                    return true;
                end

                -- Add the item
                local vNew = nodeList.createChild();
                DB.setValue(vNew, "name", "string", sName);
                DB.setValue(vNew, "desc", "string", sText);
                DB.setValue(vNew, "locked", "number", 1);

                local sEffect = DataKW.traitdata[sName:lower()];
                if sEffect then
                    EffectManager.addEffect("", "", ctnode, { sName = sName .. "; " .. sEffect, nDuration = 0, nGMOnly = 0 }, false);
                end

                CombatManagerKw.parseUnitTrait(ActorManager.resolveActor(ctnode), vNew)

                CharManager.outputUserMessage("unit_traits_message_traitadd", sName, DB.getValue(ctnode, "name", ""));

                return true;
            end
        end
    end
    return false;
end