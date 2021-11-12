-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

DEFAULT_COLOR = "FFFFFFFF";
local sCurrentColor = "";
local bDialogShown = false;

function onInit()
	--todo default color cycle?
	sCurrentColor = DB.getValue(window.getDatabaseNode(), "color", DEFAULT_COLOR);
	onColorUpdate();
end

function onClose()
	if bDialogShown then
		Interface.dialogColorClose();
	end
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if not bDialogShown then
		bDialogShown = Interface.dialogColor(colorDialogCallback, sCurrentColor);
	end
end

function colorDialogCallback(sResult, sColor)
	if sResult == "ok" or sResult == "cancel" then
		bDialogShown = false;
	end
	sCurrentColor = sColor;
	if sResult == "ok" then
		DB.setValue(window.getDatabaseNode(), "color", "string", sColor);
	end
	onColorUpdate();
end

function onColorUpdate()
	setBackColor(sCurrentColor);
	window.setColor(sCurrentColor);
end

function setColor(sColor)
	local node = window.getDatabaseNode();
	sCurrentColor = sColor;
	DB.setValue(node, "color", "string", sColor);
	onColorUpdate();
end

function getColor()
	return sCurrentColor;
end