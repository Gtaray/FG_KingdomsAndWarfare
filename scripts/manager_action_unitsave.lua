-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYUNITSAVEDC = "applyunitsavedc";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYUNITSAVEDC, handleApplyUnitSaveDC);

	ActionsManager.registerTargetingHandler("unitsaveinit", getUnitSaveInitRoll);
	ActionsManager.registerResultHandler("unitsaveinit", onUnitSaveInit);

	ActionsManager.registerResultHandler("unitsavedc", onModSaveDC)
    ActionsManager.registerResultHandler("unitsavedc", onUnitSaveDC)
end

-----------------------------------------------------------------------
-- TRAIT / MARTIAL ADVANTAGE NOTIFICATION
-----------------------------------------------------------------------
-- These are used to print out a message in chat whenever a unit or actor initiates a unitsavedc roll from a trait, power, or npc action.
function getUnitSaveInitRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "unitsaveinit";
	rRoll.aDice = {};
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[USED";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
		
	rRoll.sDesc = rRoll.sDesc .. "] ";
	if rAction.label then
		rRoll.sDesc = rRoll.sDesc .. rAction.label;
	end
	
	return rRoll;
end

function onUnitSaveInit(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.dice = nil;
	rMessage.icon = "roll_cast";

	if rTarget then
		rMessage.text = rMessage.text .. " [at " .. ActorManager.getDisplayName(rTarget) .. "]";
	end
	
	Comm.deliverChatMessage(rMessage);
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
	if DataCommon.ability_ltos[rAction.stat] then
		rRoll.sDesc = rRoll.sDesc .. " [" .. DataCommon.ability_ltos[rAction.stat] .. " DC " .. rRoll.nMod .. "]";
	end
	if rAction.battlemagic then
		rRoll.sDesc = rRoll.sDesc .. " [BATTLE MAGIC]";
	end
	if rAction.rally then
		rRoll.sDesc = rRoll.sDesc .. " [RALLY]"
	end

	rRoll.sPowerName = rAction.label;

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
	-- If a unit is initiating a roll, but they didn't select a target, automatically 
	-- assign the source as the target. This allows us to treat both rolls that units should
	-- make themselves and rolls they force others to make as tests. 
	if not rTarget and ActorManagerKw.isUnit(rSource) then
		rTarget = rSource;
	end

	if rTarget then
		local sSaveShort, sSaveDC = rRoll.sDesc:match("%[(%w+) DC (%d+)%]")
		if sSaveShort then
			local sSave = DataCommon.ability_stol[sSaveShort];
			if sSave then
				notifyApplyUnitSaveDC(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, rRoll.nMod, rRoll.sPowerName);
				return true;
			end
		end
	end

	return false;
end

function notifyApplyUnitSaveDC(rSource, rTarget, bSecret, sDesc, nDC, sPowerName)
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
	msgOOB.sPowerName = sPowerName;

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
				rAction.sOrigin = msgOOB.sSourceNode
				rAction.stat = "morale";
				ActionRally.performRoll(nil, rTarget, rAction)

			elseif msgOOB.sPowerName:lower():match("harrowing") then
			-- Perform harrowing morale test
				local rAction = {};
				rAction.nTargetDC = msgOOB.nDC
				ActionHarrowing.performRoll(nil, rTarget, rSource, rAction)

			-- Perform normal test roll
			else
				local rAction = {};
				rAction.label = StringManager.capitalize(sSave);
				rAction.stat = sSave;
				rAction.nTargetDC = msgOOB.nDC
				rAction.battlemagic = msgOOB.nBattleMagic
				-- if the source and target are different actors, track origin
				if msgOOB.sSourceNode ~= msgOOB.sTargetNode then
					rAction.sOrigin = msgOOB.sSourceNode
				end
				ActionTest.performRoll(nil, rTarget, rAction)
			end
		end
	end
end