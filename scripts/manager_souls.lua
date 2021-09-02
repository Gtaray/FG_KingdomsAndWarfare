-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fModAttack;
local fModCheck;
local fModSave;
local fModSkill;

function onInit()
	fModAttack = ActionAttack.modAttack;
	ActionAttack.modAttack = modAttack;
	ActionsManager.registerModHandler("attack", modAttack);

	fModCheck = ActionCheck.modRoll;
	ActionAttack.modRoll = modCheck;
	ActionsManager.registerModHandler("check", modCheck);

	fModSave = ActionSave.modSave;
	ActionAttack.modSave = modSave;
	ActionsManager.registerModHandler("save", modSave);

	fModSkill = ActionSkill.modRoll;
	ActionAttack.modRoll = modSkill;
	ActionsManager.registerModHandler("skill", modSkill);
end

function initializeSouls(nodeEntry, sSoulsDice, bLetheImmune)
	if not nodeEntry then
		return;
	end

	-- TODO options
	local nSouls = StringManager.evalDiceString(sSoulsDice, true);
	if nSouls then
		local rEffect = { sName = string.format("SOULS: %i", nSouls), nDuration = 0, nGMOnly = 1 }
		if not bLetheImmune then
			rEffect.sName= rEffect.sName .. "; IF: SOULS(0); Lethe";
		end
		EffectManager.addEffect("", "", nodeEntry, rEffect, false);
	end
end

function addSouls(rActor, nAdjust)
	local nSouls, nodeEffect = EffectManagerKw.getEffect(rActor, "souls");
	if nodeEffect then
		local newTotal = math.max(nSouls + nAdjust, 0);
		local sLabel = DB.getValue(nodeEffect, "label", "");
		DB.setValue(nodeEffect, "label", "string", sLabel:gsub("SOULS: " .. nSouls, "SOULS: " .. newTotal));
	end
end

function modAttack(rSource, rTarget, rRoll)
	fModAttack(rSource, rTarget, rRoll);

	local bADV, bDIS = clearAdvantage(rRoll);
	
	if EffectManager5E.hasEffectCondition(rSource, "Lethe") then
		bADV = true;
	end
	
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function modCheck(rSource, rTarget, rRoll)
	fModCheck(rSource, rTarget, rRoll);
	modIntelligence(rSource, rTarget, rRoll);
end

function modSave(rSource, rTarget, rRoll)
	fModSave(rSource, rTarget, rRoll);
	modIntelligence(rSource, rTarget, rRoll);

	local bADV, bDIS = clearAdvantage(rRoll);

	local sAbility = rRoll.sDesc:match("%[SAVE%] (%w+)");
	if sAbility then
		sAbility = string.lower(sAbility);
	end

	if StringManager.contains({ "intelligence", "wisdom", "charisma" }, sAbility) then
		bDIS = true;
	end
	
	ActionsManager2.encodeAdvantage(rRoll, bADV, bDIS);
end

function modSkill(rSource, rTarget, rRoll)
	fModSkill(rSource, rTarget, rRoll);
	modIntelligence(rSource, rTarget, rRoll);
end

function modIntelligence(rSource, rTarget, rRoll)
	if not rSource then
		return;
	end
	
	-- Get ability used
	local sActionStat = nil;
	local sAbility = string.match(rRoll.sDesc, "%[CHECK%] (%w+)");
	if not sAbility then
		sAbility = rRoll.sDesc:match("%[SAVE%] (%w+)");
	end
	if not sAbility then
		local sSkill = StringManager.trim(string.match(rRoll.sDesc, "%[SKILL%] ([^[]+)"));
		if sSkill then
			sAbility = string.match(rRoll.sDesc, "%[MOD:(%w+)%]");
			if sAbility then
				sAbility = DataCommon.ability_stol[sAbility];
			else
				local sSkillLower = sSkill:lower();
				for k, v in pairs(DataCommon.skilldata) do
					if k:lower() == sSkillLower then
						sAbility = v.stat;
					end
				end
			end
		end
	end
	if sAbility then
		sAbility = string.lower(sAbility);
	end

	if sAbility == "intelligence" then
		local intMod = ActorManager5E.getAbilityBonus(rSource, "intelligence");
		if intMod > -4 then
			rRoll.nMod = rRoll.nMod - 4 - intMod;
			addLetheTag(rRoll)
		end
	end
end

function clearAdvantage(rRoll)
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

	return bADV, bDIS;
end

function addLetheTag(rRoll)
	if not rRoll.sDesc:match("%[LETHE%]") then
		rRoll.sDesc = rRoll.sDesc .. " [LETHE]";
	end
end