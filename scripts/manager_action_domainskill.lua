-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActionsManager.registerResultHandler("domaincheck", onDomainSkillRoll)
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "domaincheck";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.modifier;
	rRoll.sDesc = "[DOMAIN SKILL] " .. StringManager.capitalize(rAction.skill or "");

	return rRoll;
end

function onDomainSkillRoll(rSource, rTarget, rRoll)
    local nTotal = ActionsManager.total(rRoll);
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

    local sNode = rRoll.sDesc:match("%[NODE:(.+)%]");
    local sPowerDieNode = nil;
    if sNode then
        local node = DB.findNode(sNode);
        -- if there's a node, try to remove the value from the power pool
        if node then
            -- iterate on all of the power pool entries
            local entries = DB.getChildren(node, "powerpool")
            for k,v in pairs(entries) do
                local value = DB.getValue(v, "value", 0);
                if value == nTotal then
                    -- Delete
                    sPowerDieNode = v;
                    break;
                end
            end
        end
    end
    
    rMessage.text = string.gsub(rMessage.text, "%[NODE:.+%]", "");
    Comm.deliverChatMessage(rMessage);
end