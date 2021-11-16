-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
OOB_MSGTYPE_USEPOWERDIE = "usepowerdie";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_USEPOWERDIE, handlePowerDieUsed);
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

	rMessage.text = string.gsub(rMessage.text, "%[NODE:.+%]", "");
	Comm.deliverChatMessage(rMessage);	

	if domainNode then
		if rRoll.sDesc:match("Added") then
			PowerPoolManager.AddDieToPool(nTotal, domainNode);
		elseif rRoll.sDesc:match("Used") then
			PowerPoolManager.RemoveDieFromPool(nTotal, domainNode);
			-- Add an effect to the consumer of this power die
			notifyPowerDieUsed(rSource, rTarget, nTotal);
		end
	end
end


-- NOTE: 
-- This currently won't work because the only way that ActionPowerDie.performRoll is invoked, it is invoked with a nil rActor
-- so rSource is nil, which means we can never set the power die to the person who used it. This is problematic, as it means
-- that unless we can infer the user based on their session details or the PCs that they own, we will never be able to know
-- who to give the power die to here.
-- Dragdata doesn't contain user information either, which would be helpful.
function notifyPowerDieUsed(rSource, rTarget, nTotal)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_USEPOWERDIE;
	msgOOB.nSecret = 0;
	msgOOB.nTotal = nTotal;
	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function handlePowerDieUsed(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local nTotal = tonumber(msgOOB.nTotal) or 0;

	ActorManagerKw.addPowerDie(rTarget or rSource, nTotal);
end