-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local enableglobaltoggle = true;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	registerMenuItem(Interface.getString("menu_restextended"), "rest_extended", 8, 2);
end

function onMenuSelection(selection, subselection, subsubselection)
	super.onMenuSelection(selection, subselection, subsubselection);
	if selection == 8 and subselection == 2 then
		extendedRest()
	end
end

function extendedRest()
	ChatManager.Message(Interface.getString("message_ct_restextended"), true);
	PowerManagerKw.beginExtended();
	CombatManager2.rest(true);
	PowerManagerKw.endExtended();
end