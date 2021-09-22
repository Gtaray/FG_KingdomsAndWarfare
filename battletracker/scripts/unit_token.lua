-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDrop(x, y, draginfo)
	local sPrototype, dropref = draginfo.getTokenData();
	if (sPrototype or "") == "" then
		return nil;
	end
	
	setPrototype(sPrototype);
	CombatManager.replaceCombatantToken(window.getDatabaseNode(), dropref);
	return true;
end

function onDragStart(draginfo)
	local nSpace = DB.getValue(window.getDatabaseNode(), "space");
	TokenManager.setDragTokenUnits(nSpace);
end
function onDragEnd(draginfo)
	TokenManager.endDragTokenWithUnits();

	local prototype, dropref = draginfo.getTokenData();
	if dropref then
		CombatManager.replaceCombatantToken(window.getDatabaseNode(), dropref);
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end
function onClickRelease(button, x, y)
	if button == 1 then
		if Input.isControlPressed() then
			local nodeActive = CombatManager.getActiveCT();
			if nodeActive then
				local nodeTarget = window.getDatabaseNode();
				if nodeTarget then
					TargetingManager.toggleCTTarget(nodeActive, nodeTarget);
				end
			end

			--todo eww.
			window.windowlist.window.windowlist.window.selected_unit.setValue("battletracker_unitsummary", window.getDatabaseNode().getPath());
		elseif Input.isShiftPressed() then
			--todo eww.
			window.windowlist.window.windowlist.window.selected_unit.setValue("battletracker_unitsummary", window.getDatabaseNode().getPath());
		else
			local tokeninstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
			if tokeninstance and tokeninstance.isActivable() then
				tokeninstance.setActive(not tokeninstance.isActive()); -- todo this wont work on clients... remove/relocate?
			end

			--todo eww.
			window.windowlist.window.windowlist.window.active_unit.setValue("battletracker_unitsummary", window.getDatabaseNode().getPath());
		end
	end

	return true;
end

function onDoubleClick(x, y)
	CombatManager.openMap(window.getDatabaseNode());
	-- unit activation if it is the commander's turn, or should control overloading be avoided here?
end

function onWheel(notches)
	TokenManager.onWheelCT(window.getDatabaseNode(), notches);
	return true;
end