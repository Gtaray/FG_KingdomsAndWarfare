-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Initialization
function onInit()
	super.onInit();
	if Session.IsHost then
		registerMenuItem(Interface.getString("menu_restextended"), "rest_extended", 7, 2);
	end
end

function onMenuSelection(selection, subselection)
	super.onMenuSelection(selection, subselection);
	if Session.IsHost then
		if selection == 7 and subselection == 2 then
			local nodeChar = getDatabaseNode();
			extendedRest(nodeChar);
		end
	end
end

function extendedRest(nodeChar)
	ChatManager.Message(Interface.getString("message_restextended"), true, ActorManager.getActor("pc", nodeChar));
	PowerManagerKw.beginExtended();
	CharManager.rest(nodeChar, true);
	PowerManagerKw.endExtended();
end