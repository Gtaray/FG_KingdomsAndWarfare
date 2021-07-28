-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYUNITSAVEDC = "applyunitsavedc";
OOB_MSGTYPE_APPLYUNITSAVE = "applyunitsave";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYUNITSAVEDC, handleApplyUnitSaveDC);
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYUNITSAVE, handleApplyUnitSave);

	--ActionsManager.registerTargetingHandler("unitsave", onTargeting);
    ActionsManager.registerModHandler("unitsavedc", modUnitSaveDC);
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
	
	rRoll.sDesc = "[SAVE VS";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.label;
	if DataCommon.ability_ltos[rAction.save] then
		rRoll.sDesc = rRoll.sDesc .. " [" .. DataCommon.ability_ltos[rAction.save] .. " DC " .. rRoll.nMod .. "]";
	end
	if rAction.magic then
		rRoll.sDesc = rRoll.sDesc .. " [BATTLC MAGIC]";
	end
	if rAction.onmissdamage == "half" then
		rRoll.sDesc = rRoll.sDesc .. " [HALF ON SAVE]";
	end

	return rRoll;
end

function modUnitSaveDC(rSource, rTarget, rRoll)
end

function onUnitSaveDC(rSource, rTarget, rRoll)
    if onUnitSavingThrow(rSource, rTarget, rRoll) then
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
				notifyApplyUnitSaveVs(rSource, rTarget, rRoll.bSecret, rRoll.sDesc, rRoll.nMod, rRoll.bRemoveOnMiss);
				return true;
			end
		end
	end

	return false;
end

function notifyApplyUnitSaveDC(rSource, rTarget, bSecret, sDesc, nDC, bRemoveOnMiss)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSAVEVS;
	
	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = sDesc;
	msgOOB.nDC = nDC;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	if bRemoveOnMiss then
		msgOOB.bRemoveOnMiss = 1;
	end

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
			performUnitSaveRoll(nil, rTarget, sSave, msgOOB.nDC, (tonumber(msgOOB.nSecret) == 1), rSource, msgOOB.bRemoveOnMiss, msgOOB.sDesc);
		end
	end
end

-----------------------------------------------------------------------
-- SAVE DC ROLL
-----------------------------------------------------------------------
function performUnitSaveRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc)
    local rRoll = getUnitSaveRoll(rActor, sSave);
	
	if bSecretRoll then
		rRoll.bSecret = true;
	end
	rRoll.nTarget = nTargetDC;
	if bRemoveOnMiss then
		rRoll.bRemoveOnMiss = "true";
	end
	if sSaveDesc then
		rRoll.sSaveDesc = sSaveDesc;
	end
    if rSource then
		rRoll.sSource = ActorManager.getCTNodeName(rSource);
	end

    ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getUnitSaveRoll(rSource, sSave)
    local rRoll = {};
    rRoll.sType = "unitsave";
    rRoll.aDice = { "d20" };
    rRoll.nMod = ActorManagerKw.getUnitAbility(rSource, sSave) or 0;
    rRoll.sDesc = "[SAVE] " StringManager.capitalize(sSave);
    
    local sSaveShort = DataCommon.ability_ltos[sSave];
    if sSaveShort then
        rRoll.sDesc = rRoll.sDesc .. " [MOD:" .. sSaveShort .. "]";
    end
    return rRoll;
end

function modUnitSave(rSource, rTarget, rRoll)
    local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

    local bADV = false;
	local bDIS = false;
    local bBattleMagic = rRoll.sDesc:match("%[BATTLE MAGIC%]");
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");		
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

    local aTestFilter = {};
    local sModStat = rRoll.sDesc:match("%[MOD:(%w+)%]");
	if sModStat then
		sModStat = DataCommon.ability_stol[sModStat];
        table.insert(aTestFilter, sModStat:lower());
	end
    -- if the save is battle magic, also look for battle magic effects
    if bBattleMagic then
        table.insert(aTestFilter, "battle magic");
    end

    if rSource then
        -- Get attack effect modifiers
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, sModStat, false, {}, rTarget);
		if (nEffectCount > 0) then
			bEffects = true;
		end

		if EffectManager5E.hasEffectCondition(rSource, "ADVTEST") then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVTEST", aTestFilter)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffectCondition(rSource, "DISTEST") then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISTEST", aTestFilter)) > 0 then
			bDIS = true;
			bEffects = true;
        end

        -- If effects, then add them
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[" .. Interface.getString("effects_tag") .. " " .. sMod .. "]";
			else
				sEffects = "[" .. Interface.getString("effects_tag") .. "]";
			end
			table.insert(aAddDesc, sEffects);
		end
    end

    if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	ActionsManager2.encodeDesktopMods(rRoll);
    for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
    rRoll.nMod = rRoll.nMod + nAddMod;
    
    ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function onUnitSave(rSource, rTarget, rRoll)
    ActionsManager2.decodeAdvantage(rRoll);

    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);

    if rRoll.nTarget then
        notifyApplyUnitSave(rSource, rRoll);
    end
end

function notifyApplyUnitSave(rSource, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYUNITSAVE;
	
	if rRoll.bTower then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.nTotal = ActionsManager.total(rRoll);
	msgOOB.sSaveDesc = rRoll.sSaveDesc;
	msgOOB.nTarget = rRoll.nTarget;
	msgOOB.sResult = rRoll.sResult;
	if rRoll.bRemoveOnMiss then
		msgOOB.nRemoveOnMiss = 1;
	end

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	if rRoll.sSource ~= "" then
		msgOOB.sTargetNode = rRoll.sSource;
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleApplyUnitSave(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rOrigin = ActorManager.resolveActor(msgOOB.sTargetNode);
	
	local rAction = {};
	rAction.bSecret = (tonumber(msgOOB.nSecret) == 1);
	rAction.sDesc = msgOOB.sDesc;
	rAction.nTotal = tonumber(msgOOB.nTotal) or 0;
	rAction.sSaveDesc = msgOOB.sSaveDesc;
	rAction.nTarget = tonumber(msgOOB.nTarget) or 0;
	rAction.sResult = msgOOB.sResult;
	rAction.bRemoveOnMiss = (tonumber(msgOOB.nRemoveOnMiss) == 1);
	
	applySave(rSource, rOrigin, rAction);
end

function applySave(rSource, rOrigin, rAction, sUser)
	local msgShort = {font = "msgfont"};
	local msgLong = {font = "msgfont"};
	
	msgShort.text = "Test";
	msgLong.text = "Test [" .. rAction.nTotal ..  "]";
	if rAction.nTarget > 0 then
		msgLong.text = msgLong.text .. "[vs. DC " .. rAction.nTarget .. "]";
	end
	msgShort.text = msgShort.text .. " ->";
	msgLong.text = msgLong.text .. " ->";
	if rSource then
		msgShort.text = msgShort.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
		msgLong.text = msgLong.text .. " [for " .. ActorManager.getDisplayName(rSource) .. "]";
	end
	if rOrigin then
		msgShort.text = msgShort.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
		msgLong.text = msgLong.text .. " [vs " .. ActorManager.getDisplayName(rOrigin) .. "]";
	end
	
	msgShort.icon = "roll_cast";
		
	local sAttack = "";
	local bHalfMatch = false;
	if rAction.sSaveDesc then
		sAttack = rAction.sSaveDesc:match("%[SAVE VS[^]]*%] ([^[]+)") or "";
		bHalfMatch = (rAction.sSaveDesc:match("%[HALF ON SAVE%]") ~= nil);
	end
	rAction.sResult = "";
	
	if rAction.nTarget > 0 then
        -- TODO: Handle automatic success here

		if rAction.nTotal >= rAction.nTarget then
			msgLong.text = msgLong.text .. " [SUCCESS]";
			
			if rSource then
				local bHalfDamage = bHalfMatch;
				local bAvoidDamage = false;
				if bHalfDamage then
                    -- Currently no handling for half damage or avoidance
				end
				
				if bAvoidDamage then
					rAction.sResult = "none";
					rAction.bRemoveOnMiss = false;
				elseif bHalfDamage then
					rAction.sResult = "half_success";
					rAction.bRemoveOnMiss = false;
				end
				
				if rOrigin and rAction.bRemoveOnMiss then
					TargetingManager.removeTarget(ActorManager.getCTNodeName(rOrigin), ActorManager.getCTNodeName(rSource));
				end
			end
		else
			msgLong.text = msgLong.text .. " [FAILURE]";

			if rSource then
				local bHalfDamage = false;
				if bHalfMatch then
					-- Currently no handling for half damage or avoidance
				end
				
				if bHalfDamage then
					rAction.sResult = "half_failure";
				end
			end
		end
	end
	
	ActionsManager.outputResult(rAction.bSecret, rSource, rOrigin, msgLong, msgShort);
	
	if rSource and rOrigin then
		ActionDamage.setDamageState(rOrigin, rSource, StringManager.trim(sAttack), rAction.sResult);
	end
end