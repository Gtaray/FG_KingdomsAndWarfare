-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local MIN_WIDTH = 200;
local MIN_HEIGHT = 200;
local SMALL_WIDTH = 500;
local SMALL_HEIGHT = 500;

local IMAGEDATA_WIDTH = 288;
local bImagePositionInitialized = false;
local nImageLeft, nImageTop, nImageRight, nImageBottom;

local _bLastHasTokens = nil;

function onInit()
	if isPanel() then
		registerMenuItem(Interface.getString("windowshare"), "windowshare", 7, 7);
		if toolbar and toolbar.subwindow then
			toolbar.subwindow.toolbar_anchor.setAnchor("right", nil, "right", "absolute", -100);
		end
	else
		if not UtilityManager.isClientFGU() then
			registerMenuItem(Interface.getString("image_menu_size"), "imagesize", 3);
			local x, y = image.getImageSize()
			if (x > 500) or (y > 500) then
				registerMenuItem(Interface.getString("image_menu_sizesmall"), "imagesizesmall", 3, 1)
			end
			registerMenuItem(Interface.getString("image_menu_sizeoriginal"), "imagesizeoriginal", 3, 2);
			registerMenuItem(Interface.getString("image_menu_sizevertical"), "imagesizevertical", 3, 4);
			registerMenuItem(Interface.getString("image_menu_sizehorizontal"), "imagesizehorizontal", 3, 5);
		end
	end
	
	saveImagePosition();

	updateHeaderDisplay();
	updateImagePosition();
	updateToolbarDisplay();

	ImageManager.registerImage(image);

	-- If image has tokens, then show toolbar initially
	if not isPanel() then
		_bLastHasTokens = image.hasTokens();
		if _bLastHasTokens then
			setToolbarVisibility(true);
		end
	end
end

function onClose()
	ImageManager.unregisterImage(image);
end

function isPanel()
	return (getClass() ~= "imagewindow");
end

function onIDChanged()
	updateHeaderDisplay();
	onNameUpdated();
end

function onLockChanged()
	updateHeaderDisplay();
	updateImagePosition();
end

function onToolbarChanged(nState)
	local bShow = (nState == 1);
	updateToolbarVisibility(bShow);
end

function onCursorModeChanged()
	updateToolbarDisplay();
end

function onMaskingStateChanged()
	updateToolbarDisplay();
end

function onGridStateChanged()
	updateToolbarDisplay();
end

function onStateChanged()
	updateToolbarDisplay();
end

function onTokenCountChanged()
	updateToolbarDisplay();
	
	if not isPanel() then
		local bHasTokens = image.hasTokens();
		if _bLastHasTokens ~= bHasTokens then
			_bLastHasTokens = bHasTokens;
			setToolbarVisibility(bHasTokens);
		end
	end
end

function saveImagePosition()
	nImageLeft, nImageTop, nImageRight, nImageBottom = image.getStaticBounds();
	bImagePositionInitialized = true;
end

function updateImagePosition()
	if not bImagePositionInitialized then return; end
	if Session.IsHost then
		if UtilityManager.isClientFGU() then
			if WindowManager.getLockedState(getDatabaseNode()) then
				image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);
				imagedata.setVisible(false);
			else
				image.setStaticBounds(nImageLeft, nImageTop, nImageRight - IMAGEDATA_WIDTH, nImageBottom);
				imagedata.setVisible(true);
				imagedata.setStaticBounds(nImageRight - IMAGEDATA_WIDTH, nImageTop, nImageRight, nImageBottom);
			end
		else
			image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);
		end
	else
		image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);
	end
end

function updateHeaderDisplay()
	if header and header.subwindow then
		header.subwindow.update();
	end
end

function setToolbarVisibility(bState)
	local nState;
	if bState then
		nState = 1;
	else
		nState = 0;
	end
	if header and header.subwindow and header.subwindow.button_toolbar then
		header.subwindow.button_toolbar.setValue(nState);
	end
end

function updateToolbarVisibility(bShowToolbar)
	if not bImagePositionInitialized then return; end
	if not toolbar then return; end
	
	if isPanel() then
		bShowToolbar = true;
	end

	if bShowToolbar ~= toolbar.isVisible() then
		local nToolbarLeft, nToolbarTop, nToolbarRight, nToolbarHeight = toolbar.getStaticBounds();
		if bShowToolbar then
			nImageTop = nToolbarTop + nToolbarHeight;
		else
			nImageTop = nToolbarTop;
		end

		updateImagePosition();

		toolbar.setVisible(bShowToolbar);
	end
end

function updateToolbarDisplay()
	if toolbar and toolbar.subwindow then
		toolbar.subwindow.update();
	end
end

function onNameUpdated()
	local nodeRecord = getDatabaseNode();
	local bID = LibraryData.getIDState("image", nodeRecord);
	
	local sTooltip = "";
	if bID then
		sTooltip = DB.getValue(nodeRecord, "name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_image")
		end
	else
		sTooltip = DB.getValue(nodeRecord, "nonid_name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_nonid_image")
		end
	end
	setTooltipText(sTooltip);
	if header and header.subwindow and header.subwindow.link then
		header.subwindow.link.setTooltipText(sTooltip);
	end
end

function onMenuSelection(item, subitem)
	if item == 3 then
		if subitem == 1 then
			local w,h = getWindowSizeAtSmallImageSize();
			setSize(w, h);
			image.setViewpoint(0,0,0);
		elseif subitem == 2 then
			local w,h = getWindowSizeAtOriginalImageSize();
			setSize(w, h);
			image.setViewpoint(0,0,1);
		elseif subitem == 4 then
			local w,h = getWindowSizeAtOriginalHeight();
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		elseif subitem == 5 then
			local w,h = getWindowSizeAtOriginalWidth();
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		end
	elseif item == 7 then
		if subitem == 7 then
			share();
		end
	end
end

function getWindowSizeAtSmallImageSize()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = iw + nMarginLeft + nMarginRight;
	local h = ih + nMarginTop + nMarginBottom;
	if w > SMALL_WIDTH then
		w = SMALL_WIDTH;
	end
	if h > SMALL_HEIGHT then
		h = SMALL_HEIGHT;
	end
	
	return w,h;
end

function getWindowSizeAtOriginalImageSize()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = iw + nMarginLeft + nMarginRight;
	local h = ih + nMarginTop + nMarginBottom;
	if w < MIN_WIDTH then
		local fScaleW = (MIN_WIDTH/w);
		w = w * fScaleW;
		h = h * fScaleW;
	end
	if h < MIN_HEIGHT then
		local fScaleH = (MIN_HEIGHT/h);
		w = w * fScaleH;
		h = h * fScaleH;
	end
	
	return w,h;
end

function getWindowSizeAtOriginalHeight()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = cw + nMarginLeft + nMarginRight;
	local h = ((ih/iw)*cw) + nMarginTop + nMarginBottom;
	
	return w,h;
end

function getWindowSizeAtOriginalWidth()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = ((iw/ih)*ch) + nMarginLeft + nMarginRight;
	local h = ch + nMarginTop + nMarginBottom;
	
	return w,h;
end
