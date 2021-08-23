-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sPreviousMode;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local markers = WarfareManager.getRankMarkers(self);
	local collapsedMarker = WarfareManager.getCollapsedMarker(self);
	for _,token in pairs(getTokens()) do
		configureLockability(token, markers, collapsedMarker);
	end
end

function onTokenAdded(token)
	configureLockability(token);

	if super and super.onTokenAdded then
		super.onTokenAdded(token);
	end
end

function onCursorModeChanged(mode)
	if sPreviousMode == "select" then
		deselectLockableTokens();
	end
	sPreviousMode = mode;

	if super and super.onCursorModeChanged then
		super.onCursorModeChanged(mode);
	end
end

function onTokenClickRelease(target, button, image)
	if target.isLockable and (window.toolbar.subwindow.warfare.getValue() == 0) then
		return true;
	end
end

function onTokenDragStart(target, button, x, y, dragdata)
	if target.isLockable and (window.toolbar.subwindow.warfare.getValue() == 0) then
		return true;
	end
end

function configureLockability(tokenInstance, markers, collapsedMarker)
	if not markers then
		markers = WarfareManager.getRankMarkers(self);
	end
	if not collapsedMarker then
		collapsedMarker = WarfareManager.getCollapsedMarker(self);
	end

	if not CombatManager.getCTFromToken(v) then
		local prototype = tokenInstance.getPrototype();
		if (markers and markers[prototype]) or prototype == collapsedMarker then
			tokenInstance.isLockable = true;
			tokenInstance.onClickRelease = onTokenClickRelease;
			tokenInstance.onDragStart = onTokenDragStart;
		end
	end
end

function deselectLockableTokens()
	for _,token in pairs(getSelectedTokens()) do
		if token.isLockable and (window.toolbar.subwindow.warfare.getValue() == 0) then
			-- TODO #79 Investigate removal of selection indication when locking token
			selectToken(token.getId(), false);
		end
	end
end