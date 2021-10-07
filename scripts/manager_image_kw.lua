-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function configureLockability(tokenInstance, markers, collapsedMarker, fortifications)
	if not markers then
		markers = WarfareManager.getRankMarkers();
	end
	if not collapsedMarker then
		collapsedMarker = WarfareManager.getCollapsedMarker();
	end
	if not fortifications then
		fortifications = WarfareManager.getFortificationTokens();
	end

	if not CombatManager.getCTFromToken(tokenInstance) then
		local prototype = tokenInstance.getPrototype();
		if (markers and markers[prototype]) or (fortifications and fortifications[prototype]) or prototype == collapsedMarker then
			tokenInstance.isLockable = true;
			tokenInstance.onClickRelease = onLockableTokenClickRelease;
			tokenInstance.onDragStart = onTokenDragStart;
		end
	end
end

function configureSelection(tokenInstance)
	local nodeCT = CombatManager.getCTFromToken(tokenInstance);
	if nodeCT and ActorManagerKw.isUnit(nodeCT) then
		tokenInstance.onClickRelease = onUnitTokenClickRelease;
	end
end

function deselectLockableTokens(image, bEdit)
	for _,token in pairs(image.getSelectedTokens()) do
		if token.isLockable and (not bEdit) then
			-- TODO #79 Investigate removal of selection indication when locking token
			image.selectToken(token.getId(), false);
		end
	end
end

function onLockableTokenClickRelease(target, button, image)
	local image, windowinstance = ImageManager.getImageControl(target);
	if target.isLockable and (image.window.toolbar.subwindow.warfare.getValue() == 0) then
		return true;
	end
end

function onTokenDragStart(target, button, x, y, dragdata)
	local image, windowinstance = ImageManager.getImageControl(target);
	if target.isLockable and (image.window.toolbar.subwindow.warfare.getValue() == 0) then
		return true;
	end
end

function onUnitTokenClickRelease(target, button, image)
	if button == 1 then
		local nodeCT = CombatManager.getCTFromToken(target);
		if Input.isControlPressed() or Input.isShiftPressed() then
			CombatManagerKw.selectUnit(nodeCT, 2);
		else
			CombatManagerKw.selectUnit(nodeCT, 1);
		end
	end
end