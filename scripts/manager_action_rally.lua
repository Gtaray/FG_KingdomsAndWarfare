-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
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

    if rSource then
        -- Get effect modifiers
		local bEffects = false;
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, "MOR", false, {});
		if (nEffectCount > 0) then
			bEffects = true;
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

    local rAction = {};
    rAction.nTotal = ActionsManager.total(rRoll);
	rAction.aMessages = {};

    -- Check if success
    rAction.nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		rAction.nFirstDie = rRoll.aDice[1].result or 0;
	end
	if rAction.nFirstDie >= 20 then
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

    -- In either case, remove Broken condition
    if EffectManager5E.hasEffect(rSource, "Broken") then
        EffectManager.removeEffect(ActorManager.getCTNode(rSource), "Broken");
    end
    if rAction.sResult == "pass" then
        -- Put the RALLY condition on the unit
        if not EffectManager5E.hasEffect(rSource, "Rallied") then
            EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Rallied", nDuration = 0 }, true);
        end

        -- Apply healing
        --ActionDamage.notifyApplyDamage(rSource, rSource, rRoll.bTower, "Rally", -rAction.nRecover);
    elseif rAction.sResult == "fail" then
        -- Disband the unit
        if not EffectManager5E.hasEffect(rSource, "Disbanded") then
            EffectManager.addEffect("", "", ActorManager.getCTNode(rSource), { sName = "Disbanded", nDuration = 0 }, true);
        end
    end
end