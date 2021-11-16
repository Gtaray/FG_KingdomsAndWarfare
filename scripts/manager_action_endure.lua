-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
OOB_MSGTYPE_APPLYENDURE = "applyendure";
function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYENDURE, handleEndure);
	ActionsManager.registerModHandler("endure", modEndureRoll)
	ActionsManager.registerResultHandler("endure", onEndureRoll)
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	ActoinsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "endure";
	rRoll.aDice = { "d20" };
	if rAction.modifier then
		rRoll.nMod = rAction.modifier;
	else
		rRoll.nMod = ActorManagerKw.getAbilityBonus(rUnit, rAction.stat) or 0;
	end

	-- Build the description label
	rRoll.sDesc = "[TEST] " .. rAction.label;

	-- Add advantage/disadvantage tags
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end

	if rAction.stat then
		local sAbilityEffect = DataCommon.ability_ltos[rAction.stat];
		if sAbilityEffect then
			rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sAbilityEffect .. "]";
		end
	end

	-- Track the attacking unit
	if rAction.sOrigin then
		rRoll.sDesc = rRoll.sDesc .. " [ORIGIN:" .. rAction.sOrigin .. "]";
	end
	if rAction.bReaction then
		rRoll.sDesc = rRoll.sDesc .. " [REACTION]";
	end

	if (rAction.dc or 0) > 0 then
		rRoll.nTarget = rAction.dc;
	end

	return rRoll;
end

function modEndureRoll(rSource, rTarget, rRoll)
	-- Keep all of the mod logic the same as the base test roll
	ActionTest.modTest(rSource, rTarget, rRoll)
end

function onEndureRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local sModStat = rRoll.sDesc:match("%[MOD:(%w+)%]");
	if sModStat then
		sModStat = DataCommon.ability_stol[sModStat];
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");
	rMessage.text = string.gsub(rMessage.text, " %[ORIGIN:[^]]*%]", "");
	rMessage.text = string.gsub(rMessage.text, " %[AUTOPASS%]", "");
	rMessage.text = string.gsub(rMessage.text, " %[REACTION%]", "");

	local rAction = {};
	rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};

	-- If this roll was a success, heal target for 1
	local sAutoPass = string.match(rRoll.sDesc, "%[AUTOPASS%]");

	rAction.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rAction.nFirstDie = rRoll.aDice[1].result or 0;
	end

	if sAutoPass then
		rAction.sResult = "pass";
		table.insert(rAction.aMessages, "[AUTOMATIC SUCCESS]")
	elseif rAction.nFirstDie >= 20 then
		rAction.sResult = "pass";
		table.insert(rAction.aMessages, "[CRITICAL SUCCESS]");
	elseif rAction.nFirstDie == 1 then
		rAction.sResult = "fail";
		table.insert(rAction.aMessages, "[AUTOMATIC FAILURE]");
	elseif rRoll.nTarget then
		if rAction.nTotal >= tonumber(rRoll.nTarget) then
			rAction.sResult = "pass";
			table.insert(rAction.aMessages, "[SUCCESS]");
		else
			rAction.sResult = "fail";
			table.insert(rAction.aMessages, "[FAILURE]");
		end
	end

	if rAction.sResult == "pass" then
		local sSourceNodeType, nodeSource = ActorManager.getTypeAndNode(rSource);
		local nTotalHP = DB.getValue(nodeSource, "hptotal", 0);
		local nWounds = nTotalHP - 1;
		
		DB.setValue(nodeSource, "wounds", "number", nWounds);
		ActionTest.updateStatusConditions(nil, rSource, nil, nTotalHP, nWounds, true)
	end

	Comm.deliverChatMessage(rMessage);

	notifyEndure(rSource, rTarget, false, rAction.nTotal, rRoll.nTarget, table.concat(rAction.aMessages, " "))
end

function notifyEndure(rSource, rTarget, bSecret, nTotal, nDC, sResults)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYENDURE;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.nTotal = nTotal;
	msgOOB.sResults = sResults;
	msgOOB.nDC = nDC or 0;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	if rTarget then
		msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleEndure(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	local nDC = tonumber(msgOOB.nDC) or 0;
	
	-- Print message to chat window
	local nTotal = tonumber(msgOOB.nTotal) or 0;
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text ="Endure";
	msgLong.text = "Endure [" .. nTotal .. "]";
	if (nDC or 0) > 0 then
		msgLong.text = msgLong.text .. "[vs. DC " .. nDC .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
		msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
	end
	if sResults ~= "" then
		msgLong.text = msgLong.text .. " " .. sResults;
	end
		
	ActionsManager.outputResult(bSecret, rSource, rTarget, msgLong, msgShort);
end