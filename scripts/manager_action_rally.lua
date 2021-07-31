-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_SETRALLYRESULT = "setrallyresult"

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_SETRALLYRESULT, handleSetRallyResult);

    ActionsManager.registerModHandler("rally", onModRally)
    ActionsManager.registerResultHandler("rally", onRally)
end

function performRoll(draginfo, rActor, rAction)
	-- If the unit has a CT entry, check for effects
	if ActorManager.hasCT(rActor) then
		if EffectManager5E.hasEffect(rActor, "Rallied") then
			ChatManager.SystemMessage(Interface.getString("message_unit_alreadyrallied"))
			return;
		end
		if EffectManager5E.hasEffect(rActor, "Disbanded") then
			ChatManager.SystemMessage(Interface.getString("message_unit_rallydisbanded"))
			return;
		end
		if not EffectManager5E.hasEffect(rActor, "Broken") then
			ChatManager.SystemMessage(Interface.getString("message_unit_rallybroken"))
			return;
		end
	end

	local rRoll = getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "rally";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.modifier;
	rRoll.sDesc = "[MORALE TEST] Rally";

	return rRoll;
end

function onModRally(rSource, rTarget, rRoll)
    local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;

    local bADV = false;
	local bDIS = false;
	if rRoll.sDesc:match(" %[ADV%]") then
		bADV = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[ADV%]", "");		
	end
	if rRoll.sDesc:match(" %[DIS%]") then
		bDIS = true;
		rRoll.sDesc = rRoll.sDesc:gsub(" %[DIS%]", "");
	end

	local aTestFilter = { "morale", "rally" };

    if rSource then
        -- Get effect modifiers
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, "MOR", false, {});
		if (nEffectCount > 0) then
			bEffects = true;
		end   

		if EffectManager5E.hasEffect(rSource, "ADVTEST", rTarget) then
			bADV = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "ADVTEST", aTestFilter, rTarget)) > 0 then
			bADV = true;
			bEffects = true;
		end
		if EffectManager5E.hasEffect(rSource, "DISTEST", rTarget) then
			bDIS = true;
			bEffects = true;
		elseif #(EffectManager5E.getEffectsByType(rSource, "DISTEST", aTestFilter, rTarget)) > 0 then
			bDIS = true;
			bEffects = true;
		end
		   
		-- Handle automatic success
		if EffectManager5E.hasEffect(rSource, "AUTOPASS", rTarget) then
			table.insert(aAddDesc, "[AUTOPASS]");
		elseif #EffectManager5E.getEffectsByType(rSource, "AUTOPASS", aTestFilter, rTarget) > 0 then
			table.insert(aAddDesc, "[AUTOPASS]");
		end

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

function onRally(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[AUTOPASS%]", "");

    local rAction = {};
    rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};

	-- Handle automatic success
	local sAutoPass = string.match(rRoll.sDesc, "%[AUTOPASS%]");

    -- Check if success
    rAction.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rAction.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if sAutoPass then
		rAction.sResult = "pass";
		table.insert(rAction.aMessages, "[AUTOMATIC SUCCESS]")
	elseif rAction.nFirstDie >= 20 then
		rAction.nRecover = 2;
		rAction.sResult = "pass";
		table.insert(rAction.aMessages, "[CRITICAL SUCCESS]");
	elseif rAction.nTotal >= 13 then
		rAction.nRecover = 1;
		rAction.sResult = "pass";
		table.insert(rAction.aMessages, "[PASSED]");
	else
		rAction.sResult = "fail";
		table.insert(rAction.aMessages, "[FAILED]");		
	end

    rMessage.text = rMessage.text .. " " .. table.concat(rAction.aMessages, " ");

    Comm.deliverChatMessage(rMessage);
    
	notifySetRallyResult(rSource, rAction);
end

function notifySetRallyResult(rSource, rAction)
	if not rSource or rTarget then
		return;
	end

	-- the gm can just set reaction without an OOB. Players need to send the OOB message
	if Session.IsHost then
		setRallyResult(rSource, bSuccess, rAction.nRecover)
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_SETRALLYRESULT;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sResult = rAction.sResult;
	msgOOB.nRecover = rAction.nRecover;

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleSetRallyResult(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local bSuccess = msgOOB.sResult == "pass";
	local nRecover = tonumber(msgOOB.nRecover) or 0;

	setRallyResult(rSource, bSuccess, nRecover);
end

function setRallyResult(rSource, bSuccess, nRecover)
	if not rSource then
		return;
	end

	-- In either case, remove Broken condition
    if EffectManager5E.hasEffect(rSource, "Broken") then
        EffectManager.removeEffect(ActorManager.getCTNode(rSource), "Broken");
    end
    if bSuccess then
        -- Put the RALLY condition on the unit
        if not EffectManager5E.hasEffect(rSource, "Rallied") then
            EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Rallied", nDuration = 0 }, true);
        end

        -- Apply healing
        ActionDamage.notifyApplyDamage(rSource, rSource, false, "Rally", -nRecover);
    else
        -- Disband the unit
        if not EffectManager5E.hasEffect(rSource, "Disbanded") then
            EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Disbanded", nDuration = 0 }, true);
        end
	end
end