-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fGetPCPowerAction;
local fGetPowerGroupRecord;
local fEvalAction;
local fPerformAction;

function onInit()
    fGetPCPowerAction = PowerManager.getPCPowerAction;
    PowerManager.getPCPowerAction = getPCPowerAction;

    fGetPowerGroupRecord = PowerManager.getPowerGroupRecord;
    PowerManager.getPowerGroupRecord = getPowerGroupRecord;

    fEvalAction = PowerManager.evalAction;
    PowerManager.evalAction = evalAction;

    fPerformAction = PowerManager.performAction;
    PowerManager.performAction = performAction;
end

function addMartialAdvantage(sClass, nodeSource, nodeCreature)
	-- Validate
	if not nodeSource or not nodeCreature then
		return nil;
	end
	
	-- Create the powers list entry
	local nodePowers = nodeCreature.createChild("powers");
	if not nodePowers then
		return nil;
	end
	
	-- Create the new power entry
	local nodeNewPower = nodePowers.createChild();
	if not nodeNewPower then
		return nil;
	end
	
	-- Copy the power details over
	DB.copyNode(nodeSource, nodeNewPower);
	
	-- Determine group setting
	DB.setValue(nodeNewPower, "group", "string", "Martial Advantages");
	
	-- Remove level data
	DB.deleteChild(nodeNewPower, "level");
		
	-- Copy text to description
	local nodeText = nodeNewPower.getChild("text");
	if nodeText then
		local nodeDesc = nodeNewPower.createChild("description", "formattedtext");
		DB.copyNode(nodeText, nodeDesc);
		nodeText.delete();
	end
	
	-- Set locked state for editing detailed record
	DB.setValue(nodeNewPower, "locked", "number", 1);
	
	-- Parse power details to create actions
	if DB.getChildCount(nodeNewPower, "actions") == 0 then
		parseMartialAdvantage(nodeNewPower);
	end

	-- If PC, then make sure all spells are visible
	if ActorManager.isPC(nodeCreature) then
		DB.setValue(nodeCreature, "powermode", "string", "standard");
	end
	
	return nodeNewPower;
end

function getPCPowerAction(nodeAction, sSubRoll)
    if not nodeAction then
		return;
	end
	local rActor = ActorManager.resolveActor(nodeAction.getChild("....."));
	if not rActor then
		return;
	end

    local rAction = {};
	rAction.type = DB.getValue(nodeAction, "type", "");
	rAction.label = DB.getValue(nodeAction, "...name", "");
	rAction.order = PowerManager.getPCPowerActionOutputOrder(nodeAction);

    if rAction.type == "test" then
        rAction.stat = DB.getValue(nodeAction, "ability", "");
		-- if (rAction.stat or "") ~= "" then 
		-- 	rAction.label = StringManager.capitalize(rAction.stat) .. " - " .. rAction.label;
		-- end
        rAction.savemod = DB.getValue(nodeAction, "savemod", 0);
        
        local savetype = DB.getValue(nodeAction, "dc", "");
        if savetype == "fixed" then
            rAction.base = "fixed";
        else
            rAction.base = "domainsize";
        end

        rAction.rally = DB.getValue(nodeAction, "rally", 0) == 1;
        rAction.battlemagic = DB.getValue(nodeAction, "battlemagic", 0) == 1;

        return rAction, rActor;
    else
        return fGetPCPowerAction(nodeAction, sSubRoll);
    end
end

function getPCPowerTestActionText(node)
    local sTest = "";
    local rAction, rActor = PowerManager.getPCPowerAction(node);

    if rAction then
        -- All this call does is evaluate domain size from the group details
        PowerManager.evalAction(rActor, node.getChild("..."), rAction);

        if rAction.savemod then
            sTest = sTest .. "DC " .. rAction.savemod .. " ";
        end
        if rAction.stat then
            sTest = sTest .. StringManager.capitalize(rAction.stat);    
        end        
        if rAction.rally then
            sTest  = sTest .. " [RALLY]";
        end
        if rAction.battlemagic then
            sTest  = sTest .. " [BATTLE MAGIC]";
        end
    end
    return sTest;
end

-- Small change to add domain size to the group table
function getPowerGroupRecord(rActor, nodePower, bNPCInnate)
    local aPowerGroup = fGetPowerGroupRecord(rActor, nodePower, bNPCInnate);

    local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if sNodeType == "pc" then
        local nodePowerGroup = nil;
		local sGroup = DB.getValue(nodePower, "group", "");
		for _,v in pairs(DB.getChildren(nodeActor, "powergroup")) do
			if DB.getValue(v, "name", "") == sGroup then
				nodePowerGroup = v;
			end
		end
		if nodePowerGroup then
            aPowerGroup.nDomainSize = DB.getValue(nodePowerGroup, "domainsize", 1);
        end
    end

    return aPowerGroup;
end

function evalAction(rActor, nodePower, rAction)
    fEvalAction(rActor, nodePower, rAction);

    local aPowerGroup = nil;
    if rAction.type == "test" then
        if (rAction.base or "") == "domainsize" then
            if not aPowerGroup then
                aPowerGroup = PowerManager.getPowerGroupRecord(rActor, nodePower);
            end
            if aPowerGroup then
                rAction.savemod = (rAction.savemod or 0) + aPowerGroup.nDomainSize;
            end
        end

		-- Do this in the roll init function
		-- local sStatShort = DataCommon.ability_ltos[rAction.stat];
		-- if sStatShort then
		-- 	rAction.label = rAction.label .. " [" .. sStatShort .. " DC " .. rAction.savemod .. "]"
		-- end
    end
end

function performAction(draginfo, rActor, rAction, nodePower)
    if not rActor or not rAction then
		return false;
	end
	
	PowerManager.evalAction(rActor, nodePower, rAction);

    local rRolls = {};
    if rAction.type == "test" then
		table.insert(rRolls, ActionUnitSave.getUnitSaveInitRoll(rActor, rAction))
        table.insert(rRolls, ActionUnitSave.getUnitSaveDCRoll(rActor, rAction))
    else
        return fPerformAction(draginfo, rActor, rAction, nodePower)
    end

    if #rRolls > 0 then
		ActionsManager.performMultiAction(draginfo, rActor, rRolls[2].sType, rRolls);
	end
    return true;
end

------------------------------
-- POWER PARSING
-----------------------------
function parseUnitTrait(nodePower)
	local sPowerName = DB.getValue(nodePower, "name", "");
	local sPowerDesc = DB.getValue(nodePower, "desc", "");

	local nodeUnit = DB.getChild(nodePower, "...");

	-- Get rid of some problem characters, and make lowercase
	local sLocal = sPowerDesc:gsub("’", "'");
	sLocal = sLocal:gsub("–", "-");
	sLocal = sLocal:lower();
	
	-- Parse the words
	local aWords, aWordStats = StringManager.parseWords(sLocal, ".:;\n");
	
	-- Add/separate markers for end of sentence, end of clause and clause label separators
	aWords, aWordStats = parseHelper(sPowerDesc, aWords, aWordStats);
	
	-- Build master list of all power abilities
	local aActions = {};
	--consolidationHelper(aActions, aWordStats, "test", parseTests(nodeUnit, sPowerName, aWords));
	consolidationHelper(aActions, aWordStats, "unitsavedc", parseTests(nodeUnit, sPowerName, aWords));
	consolidationHelper(aActions, aWordStats, "damage", parseDamages(nodeUnit, sPowerName, aWords));
	consolidationHelper(aActions, aWordStats, "heal", parseHeals(nodeUnit, sPowerName, aWords));
	consolidationHelper(aActions, aWordStats, "effect", parseEffects(sPowerName, aWords));
	
	-- Sort the abilities
	table.sort(aActions, function(a,b) return a.startpos < b.startpos end)

	return aActions;
end

function parseHelper(s, words, words_stats)
	local final_words = {};
	local final_words_stats = {};
	
	-- Separate words ending in periods, colons and semicolons
	for i = 1, #words do
	  local nSpecialChar = string.find(words[i], "[%.:;\n]");
	  if nSpecialChar then
		  local sWord = words[i];
		  local nStartPos = words_stats[i].startpos;
		  while nSpecialChar do
			  if nSpecialChar > 1 then
				  table.insert(final_words, string.sub(sWord, 1, nSpecialChar - 1));
				  table.insert(final_words_stats, {startpos = nStartPos, endpos = nStartPos + nSpecialChar - 1});
			  end
			  
			  table.insert(final_words, string.sub(sWord, nSpecialChar, nSpecialChar));
			  table.insert(final_words_stats, {startpos = nStartPos + nSpecialChar - 1, endpos = nStartPos + nSpecialChar});
			  
			  nStartPos = nStartPos + nSpecialChar;
			  sWord = string.sub(sWord, nSpecialChar + 1);
			  
			  nSpecialChar = string.find(sWord, "[%.:;\n]");
		  end
		  if string.len(sWord) > 0 then
			  table.insert(final_words, sWord);
			  table.insert(final_words_stats, {startpos = nStartPos, endpos = words_stats[i].endpos});
		  end
	  else
		  table.insert(final_words, words[i]);
		  table.insert(final_words_stats, words_stats[i]);
	  end
	end
	
  return final_words, final_words_stats;
end

function consolidationHelper(aMasterAbilities, aWordStats, sAbilityType, aNewAbilities)
	-- Iterate through new abilities
	for i = 1, #aNewAbilities do

		-- Add type
		aNewAbilities[i].type = sAbilityType;

		-- Convert word indices to character positions
		aNewAbilities[i].startpos = aWordStats[aNewAbilities[i].startindex].startpos;
		aNewAbilities[i].endpos = aWordStats[aNewAbilities[i].endindex].endpos;
		aNewAbilities[i].startindex = nil;
		aNewAbilities[i].endindex = nil;

		-- Add to master abilities list
		table.insert(aMasterAbilities, aNewAbilities[i]);
	end
end

function parseTests(nodeUnit, sPowerName, aWords)
	local saves = {};

	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "test") then
			local nIndex = i;
			if StringManager.isWord(aWords[nIndex - 1], DataCommon.abilities) then
				local rSave = {};
				rSave.stat = aWords[nIndex - 1];
				rSave.label = sPowerName;
				rSave.savemod = 8;
				rSave.startindex = 1;
				rSave.endindex = 1;

				-- Check for "DC # <stat> test"
				if StringManager.isNumberString(aWords[nIndex - 2]) and
						StringManager.isWord(aWords[nIndex - 3], "dc") then
					rSave.savemod = tonumber(aWords[nIndex - 2]);
					rSave.startindex = nIndex - 3;
					rSave.endindex = nIndex;
					table.insert(saves, rSave);

				-- Check for <stat> test (DC = # + this unit's size/tier)
				elseif StringManager.isWord(aWords[nIndex + 1], "dc") and
						StringManager.isNumberString(aWords[nIndex + 2]) and
						StringManager.isWord(aWords[nIndex + 3], "+") and
						StringManager.isWord(aWords[nIndex + 4], "this") and
						StringManager.isWord(aWords[nIndex + 5], "unit's") and
						StringManager.isWord(aWords[nIndex + 6], { "size", "tier" }) then
							
					rSave.savemod = tonumber(aWords[nIndex + 2]) or 0;
					if StringManager.isWord(aWords[nIndex + 6], "size") then
						rSave.savemod = rSave.savemod + (ActorManagerKw.getUnitSize(nodeUnit) or 0)
					elseif StringManager.isWord(aWords[nIndex + 6], "tier") then
						rSave.savemod = rSave.savemod + (ActorManagerKw.getUnitTier(nodeUnit) or 0)
					end

					rSave.startindex = nIndex - 1;
					rSave.endindex = nIndex + 6;
					table.insert(saves, rSave);

				-- Check for: <stat> test (DC = # + DS)
				-- Note: This can only really be used for npcs, since units don't have a domain size property 
				elseif StringManager.isWord(aWords[nIndex + 1], "dc") and
						StringManager.isNumberString(aWords[nIndex + 2]) and
						StringManager.isWord(aWords[nIndex + 3], "+") and
						StringManager.isWord(aWords[nIndex + 4], "ds") then

					rSave.savemod = tonumber(aWords[nIndex + 2]) or 0;
					rSave.savemod = rSave.savemod + DB.getValue(nodeUnit, "domainsize", 0);
					rSave.startindex = nIndex - 1;
					rSave.endindex = nIndex + 4;
					table.insert(saves, rSave);
				end
			end
		end
	end

	return saves;
end

function parseDamages(nodeUnit, sPowerName, aWords)
	local damages = {};

	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], { "damage", "casualty", "casualties" }) then
			local nIndex = i;
			local rDamage = {};
			rDamage.label = sPowerName;
			rDamage.clauses = {};

			-- Adjust for extra word 'additional'
			if StringManager.isWord(aWords[nIndex - 1], "additional") then
				nIndex = nIndex - 1;
			end

			if StringManager.isDiceString(aWords[nIndex - 1]) then
				rDamage.startindex = nIndex - 1;
				rDamage.endindex = i;

				local rDmgClause = {};
				rDmgClause.dice, rDmgClause.modifier = StringManager.convertStringToDice(aWords[nIndex - 1]);
				rDmgClause.dmgtype = ActorManagerKw.getUnitType(nodeUnit);
				table.insert(rDamage.clauses, rDmgClause);
				table.insert(damages, rDamage);
			end
		end
	end

	return damages;
end

function parseHeals(nodeUnit, sPowerName, aWords)
	local heals = {};

	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "casualty") and
				StringManager.isWord(aWords[i + 1], "die") then
			local nIndex = i;

			if StringManager.isWord(aWords[nIndex - 1], "its") then
				nIndex = nIndex - 1;

			elseif StringManager.isWord(aWords[nIndex - 2], "this") and
					StringManager.isWord(aWords[nIndex - 1], "units") then
				nIndex = nIndex - 2;

			end

			if StringManager.isWord(aWords[nIndex - 1], { "increment", "increments" }) then
				rHeal = {}
				rHeal.label = sPowerName;
				rHeal.clauses = {};
				rHeal.startindex = nIndex - 1;
				rHeal.endindex = i + 1;

				rClause = {};
				rClause.dice = {};
				rClause.modifier = 1;	
				
				-- Look for 'by #'
				if StringManager.isWord(aWords[i + 2], "by") and 
						StringManager.isDiceString(aWords[i + 3]) then
					rHeal.endindex = i + 3;
					rClause.dice, rClause.modifier = StringManager.convertStringToDice(aWords[i + 3]);
				end

				table.insert(rHeal.clauses, rClause);
				table.insert(heals, rHeal);
			end
		elseif StringManager.isWord(aWords[i], { "recovers", "regains" }) and
				StringManager.isDiceString(aWords[i + 1]) then
			rHeal = {};
			rHeal.label = sPowerName;
			rHeal.clauses = {};
			rHeal.startindex = i;

			local bValid = false;
			if StringManager.isWord(aWords[i + 2], "hit") and StringManager.isWord(aWords[i + 3], "points") then
				rHeal.endindex = i + 3;
				bValid = true;
			elseif StringManager.isWord(aWords[i + 2], "hp") then
				bValid = true;
				rHeal.endindex = i + 2;
			end

			if bValid then
				rClause = {};
				rClause.dice = {};
				rClause.modifier = 0;	
				rClause.dice, rClause.modifier = StringManager.convertStringToDice(aWords[i + 1]);
				table.insert(rHeal.clauses, rClause);
				table.insert(heals, rHeal);
			end
		end
	end

	return heals;
end

function parseEffects(sPowerName, aWords)
	local effects = {};
	local rCurrent = nil;

	local i = 1;
	while aWords[i] do
		if (i > 1) and StringManager.isWord(aWords[i], DataCommon.conditions) then
			local bValidCondition = false;
			local nConditionStart = i;
			local j = i - 1;

			while aWords[j] do
				if StringManager.isWord(aWords[j], "is") then
					bValidCondition = true;
					nConditionStart = j;
					break;
				
				elseif StringManager.isWord(aWords[j], "also") then
					if StringManager.isWord(aWords[j-1], "is") then
						bValidCondition = true;
						nConditionStart = j - 1;
						break;
					end

				elseif StringManager.isWord(aWords[j], "be") then
					if StringManager.isWord(aWords[j-1], "or") then
						bValidCondition = true;
						nConditionStart = j;
						break;
					elseif StringManager.isWord(aWords[j-1], "cannot") then
						bValidCondition = false;
						break;
					end

				elseif StringManager.isWord(aWords[j], "become") then
					if StringManager.isWord(aWords[j-1], { "or", "and" }) then
						bValidCondition = true;
						nConditionStart = j;
						break;
					end

				elseif StringManager.isWord(aWords[j], DataCommon.conditions) then
					break;
				else
					break;
				end
				j = j - 1;
			end

			if bValidCondition then
				rCurrent = {};
				rCurrent.sName = StringManager.capitalize(aWords[i]);
				rCurrent.startindex = nConditionStart;
				rCurrent.endindex = i;
				rCurrent.nDuration = 1;
			end
		elseif StringManager.isWord(aWords[i], { "acid", "bleed", "fire", "poison"}) then
			if StringManager.isWord(aWords[i + 1], { "token", "tokens" }) then
				local nConditionStart = i;
				local j = i - 1;

				rCurrent = {};
				rCurrent.sName = StringManager.capitalize(aWords[i]);
				rCurrent.endindex = i + 1;
				rCurrent.startindex = i - 1;

				if StringManager.isWord(aWords[j], { "one", "1", "a" }) then
					rCurrent.nDuration = 1;
				elseif StringManager.isWord(aWords[j], { "two", "2" }) then
					rCurrent.nDuration = 2;
				elseif StringManager.isWord(aWords[j], { "three", "3" }) then
					rCurrent.nDuration = 3;
				elseif StringManager.isWord(aWords[j], { "four", "4" }) then
					rCurrent.nDuration = 4;
				elseif StringManager.isWord(aWords[j], { "five", "5" }) then
					rCurrent.nDuration = 5;
				elseif StringManager.isWord(aWords[j], { "six", "6" }) then
					rCurrent.nDuration = 6;
				else
					rCurrent = nil;
				end

				if rCurrent then
					-- This puts j on the word directly after "tokens"
					j = i + 2;
					if StringManager.isWord(aWords[j], "on") and StringManager.isWord(aWords[j + 1], "the") then
						j = j + 2
						if StringManager.isWord(aWords[j], { "target", "targets" }) or StringManager.isWord(aWords[j], { "unit", "units" }) then
							j = j + 1;
						end
						-- Compensate for 'on the unit' vs 'on the target unit'
						if StringManager.isWord(aWords[j], { "unit", "units" }) then
							j = j + 1;
						end
					end

					if StringManager.isWord(aWords[j + 1], { "each", "every" }) and
							StringManager.isWord(aWords[j + 3], { "token", "tokens" }) and
							StringManager.isWord(aWords[j + 4], { "inflict", "inflicts", "deal", "deals", "cause", "causes" }) and
							StringManager.isWord(aWords[j + 6], { "damage", "casualty", "casualties" }) then
						rCurrent.endindex = j + 6;
						rCurrent.sName = rCurrent.sName .. ": " .. aWords[j + 5];
					end
				end
			end
		elseif StringManager.isWord(aWords[i], { "advantage", "disadvantage" }) then
			local nConditionStart = i;
			

			rCurrent = {};
			rCurrent.endindex = i + 1;
			rCurrent.startindex = i - 1;
			rCurrent.sName = "";
			if aWords[i] == "advantage" then
				rCurrent.sName = "ADVTEST:";
			elseif aWords[i] == "disadvantage" then
				rCurrent.sName = "DISTEST:";
			end

			local j = i + 1;
			if StringManager.isWord(aWords[j], "on") then
				if StringManager.isWord(aWords[j + 1], { "attack", "power", "morale", "command" }) and
						StringManager.isWord(aWords[j + 2], "tests") then
					rCurrent.sName = rCurrent.sName .. " " .. aWords[j + 1];	
					rCurrent.nDuration = 1;
					rCurrent.endindex = j + 2;
				end
			end
		end

		if rCurrent then
			if #effects > 0 and effects[#effects].endindex + 1 == rEffect.startindex and not effects[#effects].nDuration then
				local rComboEffect = effects[#effects];
				rComboEffect.sName = rComboEffect.sName .. "; " .. rEffect.sName;
				rComboEffect.endindex = rEffect.endindex;
				rComboEffect.nDuration = rEffect.nDuration;
				rComboEffect.sUnits = rEffect.sUnits;
			else
				table.insert(effects, rCurrent);
			end
			rCurrent = nil;
		end
		
		i = i + 1;
	end

	return effects;
end

function parseMartialAdvantage(nodePower)
	-- Clean out old actions
	local nodeActions = nodePower.createChild("actions");
	for _,v in pairs(nodeActions.getChildren()) do
		v.delete();
	end
	
	-- Track whether cast action already created
	local nodeCastAction = nil;
	
	-- Get the power name
	local sPowerName = DB.getValue(nodePower, "name", "");
	local sPowerNameLower = StringManager.trim(sPowerName:lower());
	
	-- Pull the actions from the spell data table (if available)
	if DataKW.martialadvantages[sPowerNameLower] then
		for _,vAction in ipairs(DataKW.martialadvantages[sPowerNameLower]) do
			if vAction.type then
				if vAction.type == "test" then
					if not nodeCastAction then
						nodeCastAction = DB.createChild(nodeActions);
						DB.setValue(nodeCastAction, "type", "string", "test");
					end
					if nodeCastAction then
						DB.setValue(nodeCastAction, "ability", "string", vAction.stat)
						DB.setValue(nodeCastAction, "dc", "string", vAction.savetype);
						DB.setValue(nodeCastAction, "rally", "number", vAction.rally);
						DB.setValue(nodeCastAction, "battlemagic", "number", vAction.battlemagic);
						
						if vAction.savemod then
							DB.setValue(nodeCastAction, "savemod", "number", tonumber(vAction.savemod));
						end
					end
				
				elseif vAction.type == "damage" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "damage");
					
					local nodeDmgList = DB.createChild(nodeAction, "damagelist");
					for _,vDamage in ipairs(vAction.clauses) do
						local nodeEntry = DB.createChild(nodeDmgList);
						
						DB.setValue(nodeEntry, "dice", "dice", vDamage.dice);
						DB.setValue(nodeEntry, "bonus", "number", vDamage.bonus);
						if vDamage.stat then
							DB.setValue(nodeEntry, "stat", "string", vDamage.stat);
						end
						if vDamage.statmult then
							DB.setValue(nodeEntry, "statmult", "number", vDamage.statmult);
						end
						DB.setValue(nodeEntry, "type", "string", vDamage.dmgtype);
					end
				
				elseif vAction.type == "heal" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "heal");
						
					if vAction.subtype == "temp" then
						DB.setValue(nodeAction, "healtype", "string", "temp");
					end
					if vAction.sTargeting then
						DB.setValue(nodeAction, "healtargeting", "string", vAction.sTargeting);
					end
					
					local nodeHealList = DB.createChild(nodeAction, "heallist");
					for _,vHeal in ipairs(vAction.clauses) do
						local nodeEntry = DB.createChild(nodeHealList);
						
						DB.setValue(nodeEntry, "dice", "dice", vHeal.dice);
						DB.setValue(nodeEntry, "bonus", "number", vHeal.bonus);
						if vHeal.stat then
							DB.setValue(nodeEntry, "stat", "string", vHeal.stat);
						end
						if vHeal.statmult then
							DB.setValue(nodeEntry, "statmult", "number", vHeal.statmult);
						end
					end
				
				elseif vAction.type == "effect" then
					local nodeAction = DB.createChild(nodeActions);
					DB.setValue(nodeAction, "type", "string", "effect");
					
					DB.setValue(nodeAction, "label", "string", vAction.sName);

					if vAction.sTargeting then
						DB.setValue(nodeAction, "targeting", "string", vAction.sTargeting);
					end
					if vAction.sApply then
						DB.setValue(nodeAction, "apply", "string", vAction.sApply);
					end
					
					local nDuration = tonumber(vAction.nDuration) or 0;
					if nDuration ~= 0 then
						DB.setValue(nodeAction, "durmod", "number", nDuration);
						DB.setValue(nodeAction, "durunit", "string", vAction.sUnits);
					end

				end
			end
		end
	-- Otherwise, parse the power description for actions
	else
		-- This is a lot of work, and it would probably be wrong anyway. So I'm putting it off
	end
end