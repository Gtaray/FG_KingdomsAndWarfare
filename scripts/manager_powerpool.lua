-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- This script is needed to manage the ability for players to add power dice to a domain's power pool
local OOB_MSGTYPE_ADDPOWERDIE = "addpowerdie";

function onInit()
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ADDPOWERDIE, handleAddPowerDie);
end

function AddDieToPool(nValue, domainNode)
    if domainNode then
        local msgOOB = {};
        msgOOB.type = OOB_MSGTYPE_ADDPOWERDIE;
        msgOOB.sDomain = domainNode.getNodeName();
        msgOOB.nValue = nValue;

        Comm.deliverOOBMessage(msgOOB, "");
    end
end

function handleAddPowerDie(msgOOB)
    local sNode = msgOOB.sDomain;
    if sNode then
        local domainNode = DB.findNode(sNode);
        local powerDice = domainNode.getChild("powerpool");
        local newDie = powerDice.createChild();
        local valueNode = newDie.createChild("value", "number")
        valueNode.setValue(msgOOB.nValue or 0);
    end
end