-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fUpdateDisplay;
local fOnDataChanged;

function onInit()
    fUpdateDisplay = super.updateDisplay
    super.updateDisplay = updateDisplay

    fOnDataChanged = super.onDataChanged
    super.onDataChanged = onDataChanged
    local sNode = getDatabaseNode().getPath();

    super.onInit();

    DB.removeHandler(sNode, "onChildUpdate", super.onDataChanged);
    DB.addHandler(sNode, "onChildUpdate", onDataChanged);

    local powernode = getDatabaseNode().getChild("...");
    DB.addHandler(DB.getPath(powernode, "group"), "onUpdate", onGroupChanged);
end
function onClose()
    super.onClose();
    local sNode = getDatabaseNode().getPath();
    DB.removeHandler(sNode, "onChildUpdate", onDataChanged);

    local powernode = getDatabaseNode().getChild("...");
    DB.removeHandler(DB.getPath(powernode, "group"), "onUpdate", onGroupChanged);
end
function updateDisplay()
    fUpdateDisplay();

    local node = getDatabaseNode();
    local sType = DB.getValue(node, "type", "");
    local bShowTest = (sType == "test");

    testbutton.setVisible(bShowTest);
    testlabel.setVisible(bShowTest);
    testview.setVisible(bShowTest);
    testdetail.setVisible(bShowTest);
end
function onDataChanged()
    fOnDataChanged();

    local sType = DB.getValue(getDatabaseNode(), "type", "");
    if sType == "test" then
        onTestChanged()
    end
end
function onGroupChanged()
    if DB.getValue(getDatabaseNode(), "type", "") == "test" then
        onTestChanged()
    end
end
function onTestChanged()
    local sTest = PowerManagerKw.getPCPowerTestActionText(getDatabaseNode());
    testview.setValue(sTest);
end