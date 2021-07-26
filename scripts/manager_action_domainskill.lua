-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    ActionsManager.registerModHandler("domaincheck", modDomainSkillRoll)
    ActionsManager.registerResultHandler("domaincheck", onDomainSkillRoll)
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, rAction)
	
	-- Build basic roll
	local rRoll = {};
	rRoll.sType = "domaincheck";
	rRoll.aDice = { "d20" };
	rRoll.nMod = rAction.modifier;
	rRoll.sDesc = "[DOMAIN SKILL] " .. StringManager.capitalize(rAction.skill or "");

	return rRoll;
end

function modDomainSkillRoll(rSource, rTarget, rRoll)
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

function onDomainSkillRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);
    local nTotal = ActionsManager.total(rRoll);
    local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

    local aNotifications = {}
	local nFirstDie = 0;
	if #(rRoll.aDice) > 0 then
		nFirstDie = rRoll.aDice[1].result or 0;
	end
    if nFirstDie >= 20 then
		table.insert(aNotifications, "[CRITICAL SUCCESS]");
	end
    
    rMessage.text = rMessage.text .. " " .. table.concat(aNotifications, " ");
    Comm.deliverChatMessage(rMessage);
end