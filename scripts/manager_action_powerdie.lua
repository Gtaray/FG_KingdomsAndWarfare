-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local OOB_MSGTYPE_ADDPOWERDIE = "addpowerdie";
local OOB_MSGTYPE_REMOVEPOWERDIE = "removepowerdie";

function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_REMOVEPOWERDIE, handleRemovePowerDie);
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
        rRoll.nMod = rAction.nPowerdie;
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
            notifyAddPowerDie(rSource, domainNode, nTotal);
        elseif rRoll.sDesc:match("Used") then
            -- iterate on all of the power pool entries
            local entries = DB.getChildren(node, "powerpool")
            for k,v in pairs(entries) do
                local value = DB.getValue(v, "value", 0);
                if value == nTotal then
                    -- Delete
                    notifyRemovePowerDie(rSource, v);
                    break;
                end
            end
        end
    end

    rMessage.text = string.gsub(rMessage.text, "%[NODE:.+%]", "");
    Comm.deliverChatMessage(rMessage);    
end

function notifyAddPowerDie(rSource, domainNode, nTotal)
    local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_ADDPOWERDIE;
	msgOOB.sDomain = domainNode.getNodeName();
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
    msgOOB.nTotal = nTotal;

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleAddPowerDie(msgOOB)
    local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
    domainNode = DB.findNode(msgOOB.sDomain or "");
    if domainNode then
        local newDie = domainNode.createChild();
        DB.setValue(newDie, "value", "number", msgOOB.nTotal or 0);
    end
end

function notifyRemovePowerDie(rSource, domainNode)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_REMOVEPOWERDIE;
	msgOOB.sPowerDie = domainNode.getNodeName();
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleRemovePowerDie(msgOOB)
    local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
    local sNode = msgOOB.sPowerDie;
    if sNode then
        DB.deleteNode(sNode);
    end
end