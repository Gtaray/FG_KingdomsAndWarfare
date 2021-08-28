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

	if not CombatManager.getCTFromToken(v) then
		local prototype = tokenInstance.getPrototype();
		if (markers and markers[prototype]) or (fortifications and fortifications[prototype]) or prototype == collapsedMarker then
			tokenInstance.isLockable = true;
			tokenInstance.onClickRelease = onTokenClickRelease;
			tokenInstance.onDragStart = onTokenDragStart;
		end
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

function onTokenClickRelease(target, button, image)
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