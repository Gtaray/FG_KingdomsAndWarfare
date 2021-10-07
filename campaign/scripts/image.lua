-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sPreviousMode;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	local markers = WarfareManager.getRankMarkers();
	local collapsedMarker = WarfareManager.getCollapsedMarker();
	for _,token in pairs(getTokens()) do
		ImageManagerKw.configureLockability(token, markers, collapsedMarker);
		ImageManagerKw.configureSelection(token);

		token.onClickRelease = a
		token.onClickRelease = b
	end
end

function onTokenAdded(token)
	ImageManagerKw.configureLockability(token);
	ImageManagerKw.configureSelection(token);

	if super and super.onTokenAdded then
		super.onTokenAdded(token);
	end
end

function onCursorModeChanged(mode)
	if sPreviousMode == "select" then
		local bEdit = window.toolbar.subwindow.warfare.getValue() == 1
		ImageManagerKw.deselectLockableTokens(window.image, bEdit);
	end
	sPreviousMode = mode;

	if super and super.onCursorModeChanged then
		super.onCursorModeChanged(mode);
	end
end