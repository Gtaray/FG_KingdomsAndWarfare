-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_init"), "turn", 7);
		registerMenuItem(Interface.getString("menu_initall"), "shuffle", 7, 8);
		registerMenuItem(Interface.getString("menu_initnpc"), "mask", 7, 7);
		registerMenuItem(Interface.getString("menu_initpc"), "portrait", 7, 6);
		registerMenuItem(Interface.getString("menu_initclear"), "pointer_circle", 7, 4);

		registerMenuItem(Interface.getString("menu_rest"), "lockvisibilityon", 8);
		registerMenuItem(Interface.getString("menu_restshort"), "pointer_cone", 8, 8);
		registerMenuItem(Interface.getString("menu_restlong"), "pointer_circle", 8, 6);

		registerMenuItem(Interface.getString("ct_menu_itemdelete"), "delete", 3);
		registerMenuItem(Interface.getString("bt_menu_itemdeletenonfriendly_all"), "delete", 3, 1);
		registerMenuItem(Interface.getString("bt_menu_itemdeletefoe_all"), "delete", 3, 3);
        registerMenuItem(Interface.getString("bt_menu_itemdeletenonfriendly_units"), "delete", 3, 5);
		registerMenuItem(Interface.getString("bt_menu_itemdeletefoe_units"), "delete", 3, 6);

		registerMenuItem(Interface.getString("ct_menu_effectdelete"), "hand", 5);
		registerMenuItem(Interface.getString("ct_menu_effectdeleteall"), "pointer_circle", 5, 7);
		registerMenuItem(Interface.getString("ct_menu_effectdeleteexpiring"), "pointer_cone", 5, 5);
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if button == 1 then
		Interface.openRadialMenu();
		return true;
	end
end

function onMenuSelection(selection, subselection, subsubselection)
	if Session.IsHost then
		if selection == 7 then
			if subselection == 4 then
				CombatManager.resetInit();
			elseif subselection == 8 then
				CombatManager2.rollInit();
			elseif subselection == 7 then
				CombatManager2.rollInit("npc");
			elseif subselection == 6 then
				CombatManager2.rollInit("pc");
			end
		end
		if selection == 8 then
			if subselection == 8 then
				ChatManager.Message(Interface.getString("ct_message_rest"), true);
				CombatManager2.rest(false);
			elseif subselection == 6 then
				ChatManager.Message(Interface.getString("ct_message_restlong"), true);
				CombatManager2.rest(true);
			end
		end
		if selection == 5 then
			if subselection == 7 then
				CombatManager.resetCombatantEffects();
			elseif subselection == 5 then
				CombatManager2.clearExpiringEffects();
			end
		end
		if selection == 3 then
			if subselection == 1 then
				clearNPCs();
			elseif subselection == 3 then
				clearNPCs(true);
            elseif subselection == 5 then
                clearUnits()
            elseif subselection == 6 then
                clearUnits(true);
			end
		end
	end
end

function clearNPCs(bDeleteOnlyFoe)
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		local sFaction = vChild.getChild("friendfoe").getValue();

		if bDeleteOnlyFoe then
			if sFaction == "foe" then
				vChild.delete();
			end
		else
			if sFaction ~= "friend" then
				vChild.delete();
			end
		end
	end
end

function clearUnits(bDeleteOnlyFoe)
	for _, vChild in pairs(DB.getChildren(CombatManager.CT_LIST)) do
        if ActorManagerKw.isUnit(vChild) then
            local sFaction = vChild.getChild("friendfoe").getValue();

            if bDeleteOnlyFoe then
                if sFaction == "foe" then
                    vChild.delete();
                end
            else
                if sFaction ~= "friend" then
                    vChild.delete();
                end
            end
        end
	end
end
