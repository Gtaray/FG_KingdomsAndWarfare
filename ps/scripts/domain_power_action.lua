-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("power_menu_actiondelete"), "deletepointer", 4);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 4, 3);
	
	updateDisplay();
	
	local node = getDatabaseNode();
	windowlist.setOrder(node);

	local sNode = getDatabaseNode().getPath();
	DB.addHandler(sNode, "onChildUpdate", onDataChanged);
	onDataChanged();
end

function onClose()
	local sNode = getDatabaseNode().getPath();
	DB.removeHandler(sNode, "onChildUpdate", onDataChanged);
end

function onMenuSelection(selection, subselection)
	if selection == 4 and subselection == 3 then
		getDatabaseNode().delete();
	end
end

function highlight(bState)
	if bState then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

function updateDisplay()
	local node = getDatabaseNode();
	
	local sType = DB.getValue(node, "type", "");
	
	local bShowCast = (sType == "cast");
	local bShowEffect = (sType == "effect");
	
	savebutton.setVisible(bShowCast);
	saveview.setVisible(bShowCast);
	castdetail.setVisible(bShowCast and Session.IsHost);

	effectbutton.setVisible(bShowEffect);
	effectview.setVisible(bShowEffect);
	effectdetail.setVisible(bShowEffect and Session.IsHost);
end

function updateViews()
	onDataChanged();
end

function onDataChanged()
	local sType = DB.getValue(getDatabaseNode(), "type", "");
	
	if sType == "cast" then
		onCastChanged();
	elseif sType == "effect" then
		onEffectChanged();
	end
end

function onCastChanged()
	local rAction = PowerManagerKw.getDomainPowerCastAction(getDatabaseNode());
	if not rAction then 
		return 
	end;
	local sSave = "";
	if (rAction.save or "") ~= "" and (rAction.savebase or "") ~= "" then
		sSave = StringManager.capitalize(rAction.save:sub(1,3)) .. " DC " .. rAction.savemod;
	end
	saveview.setValue(sSave);
end

function onEffectChanged()
	local nodeAction = getDatabaseNode();
	
	local sLabel = DB.getValue(nodeAction, "label", "");
	
	local sApply = DB.getValue(nodeAction, "apply", "");
	if sApply == "action" then
		sLabel = sLabel .. "; [ACTION]";
	elseif sApply == "roll" then
		sLabel = sLabel .. "; [ROLL]";
	elseif sApply == "single" then
		sLabel = sLabel .. "; [SINGLES]";
	end
	
	local sTargeting = DB.getValue(nodeAction, "targeting", "");
	if sTargeting == "self" then
		sLabel = sLabel .. "; [SELF]";
	end
	
	effectview.setValue(sLabel);
end