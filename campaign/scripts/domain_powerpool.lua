-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addEntry(bFocus, nVal)
    if User.isHost() then
        local bReadOnly = WindowManager.getReadOnlyState(window.getDatabaseNode());
        local domainNode = DB.getChild(getDatabaseNode(), "..");
        local powerdie = DB.getValue(domainNode, "powerdie", "d4");
        local w = createWindow();
        if bFocus then
            w.value.setFocus();
        end
        if nVal then
            w.value.setValue(nVal);
        end
        w.die.setDice({ powerdie });
        w.value.setReadOnly(bReadOnly);

        local sEdit = getName() .. "_iedit";
        if window[sEdit] then
            local bEdit = (window[sEdit].getValue() == 1);
            w.idelete.setVisibility(bEdit);
        end
        return w;
    else
        -- This case is when a player adds a die
        -- Need to send out a msg so the host adds the item
        PowerPoolManager.AddDieToPool(nVal, window.getDatabaseNode());
    end
end

function onDrop(x, y, draginfo)
    local sDragType = draginfo.getType();
    if sDragType == "number" then
        -- Focus set to false since there's number data. No need to focus to enter data
        local w = addEntry(false, draginfo.getNumberData());
        return true;
    elseif sDragType == "dice" then
        local rAction = {}
        rAction.add = true;
        rAction.aDice = draginfo.getDieList();
        rAction.nMod = 0;
        rAction.domainNode = window.getDatabaseNode();
        ActionPowerDie.performRoll(nil, nil, rAction);
        return true;
    end
end

function update()
    local sEdit = getName() .. "_iedit";
    if window[sEdit] then
        local bEdit = (window[sEdit].getValue() == 1);
        for _,wAttribute in ipairs(getWindows()) do
            wAttribute.idelete.setVisibility(bEdit);
        end
    end                        
end