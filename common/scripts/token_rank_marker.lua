-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local prototype = "";

function onInit()
    if (getPrototype() or "") == "" then
        if fallback and fallback[1] then
            setPrototype(fallback[1]);
        end
    end
    prototype = getPrototype();
end
function onValueChanged()
    local newToken = getPrototype();
    local windowinstance = window.parentcontrol.window;
    if windowinstance and windowinstance.image then
        for _,token in pairs(windowinstance.image.getTokens()) do
            -- Ignore anything that has a CT entry attached to it
            if CombatManager.getCTFromToken(token) == nil then
                -- If the prototypes match, swap them
                if token.getPrototype() == prototype then
                    swapTokens(token, newToken);
                end
            end
        end
    end

    prototype = newToken;
end

function swapTokens(oldToken, newToken)
    if not oldToken or not newToken then
        return;
    end

    local nodeContainerOld = oldToken.getContainerNode();
    if nodeContainerOld then
        local x,y = oldToken.getPosition();
        newToken = Token.addToken(nodeContainerOld.getPath(), getValue(), x, y);
        oldToken.delete();
    end
end