-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addEntry(sType, bFocus)
    local nodelist = getDatabaseNode();
    if nodelist then
        local nodeAction = nodelist.createChild();
        if nodeAction then
            DB.setValue(nodeAction, "type", "string", sType);
        end
	end
end

function reset()
    for _,v in pairs(getWindows()) do
        v.getDatabaseNode().delete();
    end
end

function setOrder(node)
    if DB.getValue(node, "order", 0) == 0 then
        local aOrder = {};
        for _,v in pairs(DB.getChildren(getDatabaseNode(), "")) do
            aOrder[DB.getValue(v, "order", 0)] = true;
        end
        
        local i = 1;
        while aOrder[i] do
            i = i + 1;
        end
        
        DB.setValue(node, "order", "number", i);
    end
end