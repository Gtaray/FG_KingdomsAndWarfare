-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fUpdatedisplay;
local fUpdateViews;

function onInit()
    super.onInit();
    fUpdatedisplay = super.updateDisplay;
    super.updateDisplay = updateDisplay;
    fUpdateViews = super.updateViews;
    super.updateViews = updateViews;
end

function updateDispaly()
    fUpdteDisplay();

    local sType = DB.getValue(getDatabaseNode(), "type", "");
    if sType == "test" then
        button.setIcons("button_roll", "button_roll_down");
    end
end

function updateViews() 
    fUpdateViews();

    local sType = DB.getValue(getDatabaseNode(), "type", "");
    if sType == "test" then
        onTestChanged();
    end
end

function onTestChanged()
    local sTest = PowerManagerKw.getPCPowerTestActionText(getDatabaseNode());
    button.setTooltipText("TEST: " .. sTest);
end