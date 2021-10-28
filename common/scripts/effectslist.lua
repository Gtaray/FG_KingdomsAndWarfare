-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
function onInit()
    update();
end

function addEntry(sType, bFocus)
    local nodelist = getDatabaseNode();
    if nodelist then
        local nodeAction = nodelist.createChild();
        DB.setValue(nodeAction, "duration", "number", 0);
        return nodeAction;
	end
end

function update()
    local bReadOnly = WindowManager.getReadOnlyState(window.parentcontrol.window.getDatabaseNode());
    for _,window in pairs(getWindows()) do
        window.isgmonly.setReadOnly(bReadOnly);
        window.duration.setReadOnly(bReadOnly);
        window.label.setReadOnly(bReadOnly);
        window.apply.setReadOnly(bReadOnly);
        window.unit.setReadOnly(bReadOnly);
    end
end

function reset()
    for _,v in pairs(getWindows()) do
        v.getDatabaseNode().delete();
    end
end