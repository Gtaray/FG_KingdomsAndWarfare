-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYUNITSAVEDC = "applyunitsavedc";
OOB_MSGTYPE_APPLYUNITSAVE = "applyunitsave";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYUNITSAVEDC, handleApplyUnitSaveDC);
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYUNITSAVE, handleApplyUnitSave);

	ActionsManager.registerResultHandler("unitsavedc", onModSaveDC)
    ActionsManager.registerResultHandler("unitsavedc", onUnitSaveDC)

    ActionsManager.registerModHandler("unitsave", modUnitSave);
    ActionsManager.registerResultHandler("unitsave", onUnitSave)
end

-----------------------------------------------------------------------
-- SAVE DC ROLL
-----------------------------------------------------------------------
function performUnitSaveDCRoll(draginfo, rActor, rAction)
    local rRoll = getUnitSaveDCRoll(rActor, rAction);
    ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getUnitSaveDCRoll(rActor, rAction)
    local rRoll = {};
	rRoll.sType = "unitsavedc";
	rRoll.aDice = {};
	rRoll.nMod = rAction.savemod or 0;
	
	rRoll.sDesc = "[TEST VS";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if DataCommon.ability_ltos[rAction.save] then
		rRoll.sDesc = rRoll.sDesc .. " [" .. DataCommon.ability_ltos[rAction.save] .. " DC " .. rRoll.nMod .. "]";
	end
	if rAction.battlemagic then
		rRoll.sDesc = rRoll.sDesc .. " [BATTLE MAGIC]";
	end
	if rAction.rally then
		rRoll.sDesc = rRoll.sDesc .. " [RALLY]"
	end

	return rRoll;
end

function onModSaveDC(rSource, rTarget, rRoll)
end

function onUnitSaveDC(rSource, rTarget, rRoll)
    if onUnitSavingThrowDC(rSource, rTarget, rRoll) then
		return;
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

function onUnitSavingThrowDC(rSource, rTarget, rRoll)
	if rTarget then
		local sSaveShort, sSaveDC = rRoll.sDesc:match("%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.ability_stol[sSaveShort];
			if sSave then
				notifyApplyUnitSaveDC(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, rRoll.nMod);
				return true;
			end
		end
	end

	return false;
end

function notifyApplyUnitSaveDC(rSource, rTarget, bSecret, sDesc, nDC)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYUNITSAVEDC;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = sDesc;
	msgOOB.nDC = nDC;

	if msgOOB.sDesc:match("%[RALLY%]") then
		msgOOB.nRally = 1;
		msgOOB.sDesc = msgOOB.sDesc:gsub(" %[RALLY%]", "");
	end
	if msgOOB.sDesc:match("%[BATTLE MAGIC%]") then
		msgOOB.nBattleMagic = 1;
		msgOOB.sDesc = msgOOB.sDesc:gsub(" %[BATTLE MAGIC%]", "");
	end

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if nodeTarget and (sTargetNodeType == "pc") then
		if Session.IsHost then
			local sOwner = DB.getOwner(nodeTarget);
			if sOwner ~= "" then
				for _,vUser in ipairs(User.getActiveUsers()) do
					if vUser == sOwner then
						for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
							if nodeTarget.getName() == vIdentity then
								Comm.deliverOOBMessage(msgOOB, sOwner);
								return;
							end
						end
					end
				end
			end
		else
			if DB.isOwner(nodeTarget) then
				handleApplyUnitSaveVs(msgOOB);
				return;
			end
		end
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyUnitSaveDC(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local sSaveShort, sSaveDC = string.match(msgOOB.sDesc, "%[(%w+) DC (%d+)%]")
	if sSaveShort then
		local sSave = DataCommon.ability_stol[sSaveShort];
		if sSave then
			-- Perform rally roll
			if (msgOOB.nRally or "") == "1" then
				local rAction = {};
				rAction.label = msgOOB.sDesc;
				rAction.nTargetDC = msgOOB.nDC
				ActionRally.performRoll(nil, rTarget, rAction)

			-- Perform normal test roll
			else
				local rAction = {};
				rAction.label = msgOOB.sDesc;
				rAction.stat = sSave;
				rAction.nTargetDC = msgOOB.nDC
				rAction.battlemagic = msgOOB.nBattleMagic
				ActionTest.performRoll(nil, rTarget, rAction)
			end
		end
	end
end