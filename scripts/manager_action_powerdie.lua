-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local OOB_MSGTYPE_REMOVEPOWERDIE = "powerdie";

function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_REMOVEPOWERDIE, handleRemovePowerDie);
    ActionsManager.registerResultHandler("powerdie", onPowerDie)
end

function performRoll(draginfo, rActor, nPowerDie, domainNode)
	local rRoll = getRoll(rActor, nPowerDie, domainNode);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, nPowerDie, domainNode)
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "powerdie";
	rRoll.aDice = { };
	rRoll.nMod = nPowerDie;
	rRoll.sDesc = "[POWER DIE]";
    if domainNode then
        rRoll.sDesc = rRoll.sDesc .. "[NODE:" .. domainNode .. "]";
    end

	return rRoll;
end

function onPowerDie(rSource, rTarget, rRoll)
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

    if sPowerDieNode then
        notifyRemovePowerDie(rSource, sPowerDieNode);
    end
end

function notifyRemovePowerDie(rSource, sNode)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_REMOVEPOWERDIE;
	msgOOB.sPowerDie = sNode.getNodeName();
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