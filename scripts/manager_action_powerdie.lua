-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActionsManager.registerResultHandler("powerdie", onPowerDie)
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "powerdie";
    if rAction.add then
        rRoll.aDice = rAction.aDice;
        rRoll.nMod = 0;
        rRoll.sDesc = "[POWER DIE] Added";
    elseif rAction.remove then
        rRoll.aDice = { };
        rRoll.nMod = rAction.nMod;
        rRoll.sDesc = "[POWER DIE] Used";
    end
	
    if rAction.domainNode then
        rRoll.sDesc = rRoll.sDesc .. "[NODE:" .. rAction.domainNode.getNodeName() .. "]";
    end

	return rRoll;
end

function onPowerDie(rSource, rTarget, rRoll)
    local nTotal = ActionsManager.total(rRoll);
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

    local sNode = rRoll.sDesc:match("%[NODE:(.+)%]");
    local domainNode = DB.findNode(sNode);
    local sPowerDieNode = nil;

    if domainNode then
        if rRoll.sDesc:match("Added") then
            PowerPoolManager.AddDieToPool(nTotal, domainNode);
        elseif rRoll.sDesc:match("Used") then
            PowerPoolManager.RemoveDieFromPool(nTotal, domainNode);
        end
    end

    rMessage.text = string.gsub(rMessage.text, "%[NODE:.+%]", "");
    Comm.deliverChatMessage(rMessage);    
end