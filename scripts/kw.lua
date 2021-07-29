-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fGetNPCSourceType;
local fHandleDrop;
local fApplyDamage;
local fActionRoll;

aRecordOverrides = {	
	-- New record types
	["unit"] = { 
		bExport = true,
        sRecordDisplayClass = "reference_unit", 
		aDataMap = { "unit", "reference.unitdata" }, 
		aCustomFilters = {
			["Type"] = { sField = "type" },
            ["Tier"] = { sField = "tier" },
            ["Ancestry"] = { sField = "ancestry" },
            
		},
	},
	["domain"] = {
		bExport = true,
		sRecordDisplayClass = "reference_domain",
		aDataMap = { "domain", "reference.domaindata" }
	}
};

-- aListViews = {
-- 	["unit"] = {
-- 		["bytier"] = {
-- 			sTitleRes = "npc_grouped_title_byletter",
-- 			aColumns = {
-- 				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
-- 				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRe = "npc_grouped_tooltip_cr", bCentered=true },
-- 			},
-- 			aFilters = { },
-- 			aGroups = { { sDBField = "name", nLength = 1 } },
-- 			aGroupValueOrder = { },
-- 		},
-- 		["byancestry"] = {
-- 			sTitleRes = "npc_grouped_title_bycr",
-- 			aColumns = {
-- 				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
-- 				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRe = "npc_grouped_tooltip_cr", bCentered=true },
-- 			},
-- 			aFilters = { },
-- 			aGroups = { { sDBField = "cr", sPrefix = "CR" } },
-- 			aGroupValueOrder = { "CR", "CR 0", "CR 1/8", "CR 1/4", "CR 1/2", 
-- 								"CR 1", "CR 2", "CR 3", "CR 4", "CR 5", "CR 6", "CR 7", "CR 8", "CR 9" },
-- 		},
-- 		["bytype"] = {
-- 			sTitleRes = "npc_grouped_title_bytype",
-- 			aColumns = {
-- 				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=250 },
-- 				{ sName = "cr", sType = "string", sHeadingRes = "npc_grouped_label_cr", sTooltipRe = "npc_grouped_tooltip_cr", bCentered=true },
-- 			},
-- 			aFilters = { },
-- 			aGroups = { { sDBField = "type" } },
-- 			aGroupValueOrder = { },
-- 		},	
-- 	},
-- };

function onInit()
	for kRecordType,vRecordType in pairs(aRecordOverrides) do
		LibraryData.overrideRecordTypeInfo(kRecordType, vRecordType);
	end
	-- for kRecordType,vRecordListViews in pairs(aListViews) do
	-- 	for kListView, vListView in pairs(vRecordListViews) do
	-- 		LibraryData.setListView(kRecordType, kListView, vListView);
	-- 	end
	-- end

	GameSystem.actions.test = { bUseModStack = true, sTargeting = "each" };
	GameSystem.actions.rally = { bUseModStack = true };
	GameSystem.actions.powerdie = { bUseModStack = false };
	GameSystem.actions.domainskill = { bUseModStack = true };
	GameSystem.actions.diminished = { bUseModStack = true };
	GameSystem.actions.harrowing = { bUseModStack = true };
	GameSystem.actions.unitsavedc = { bUseModStack = true, sTargeting = "each" }
	GameSystem.actions.unitsave = { bUseModStack = true };
	table.insert(GameSystem.targetactions, "test");
	table.insert(GameSystem.targetactions, "unitsavedc");

	table.insert(DataCommon.abilities, "attack");
	table.insert(DataCommon.abilities, "defense");
	table.insert(DataCommon.abilities, "power");
	table.insert(DataCommon.abilities, "toughness");
	table.insert(DataCommon.abilities, "morale");
	table.insert(DataCommon.abilities, "command");

	DataCommon.ability_ltos.attack = "ATK";
	DataCommon.ability_ltos.defense = "DEF";
	DataCommon.ability_ltos.power = "POW";
	DataCommon.ability_ltos.toughness = "TOU";
	DataCommon.ability_ltos.morale = "MOR";
	DataCommon.ability_ltos.command = "COM";

	DataCommon.ability_stol.ATK = "attack";
	DataCommon.ability_stol.DEF = "defense";
	DataCommon.ability_stol.POW = "power";
	DataCommon.ability_stol.TOU = "toughness";
	DataCommon.ability_stol.MOR = "morale";
	DataCommon.ability_stol.COM = "command";

	table.insert(DataCommon.conditions, "broken");
	table.insert(DataCommon.conditions, "disbanded");
	table.insert(DataCommon.conditions, "disorganized");
	table.insert(DataCommon.conditions, "disoriented");
	table.insert(DataCommon.conditions, "exposed");
	table.insert(DataCommon.conditions, "hidden");
	table.insert(DataCommon.conditions, "misled");
	table.insert(DataCommon.conditions, "weakened");

	LibraryData.setCustomData("battle", "acceptdrop", { "unit", "reference_unit" });

	fGetNPCSourceType = NPCManager.getNPCSourceType;
	NPCManager.getNPCSourceType = getNPCSourceType;

	fHandleDrop = CampaignDataManager.handleDrop;
	CampaignDataManager.handleDrop = handleUnitDropOnCT;

	fApplyDamage = ActionDamage.applyDamage;
	ActionDamage.applyDamage = handleUnitDamage;

	fActionRoll = ActionsManager.actionRoll;
	ActionsManager.actionRoll = actionRoll;
end

-- Replacement function for get NPC type that will also return "unit" for units
function getNPCSourceType(vNode)
	local sNodePath = nil;
	if type(vNode) == "databasenode" then
		sNodePath = vNode.getPath();
	elseif type(vNode) == "string" then
		sNodePath = vNode;
	end
	if not sNodePath then
		return "";
	end
	
	local type = fGetNPCSourceType(vNode);

	if type == "" then
		for _,vMapping in ipairs(LibraryData.getMappings("unit")) do
			if StringManager.startsWith(sNodePath, vMapping) then
				return "unit";
			end
		end
	end
		
	return type;
end

function handleUnitDropOnCT(sTarget, draginfo)
	local handled = fHandleDrop(sTarget, draginfo);

	-- if not handled by something else, check if we're dropping a unit on the CT
	if not handled then
		if sTarget == "combattracker" then
			local sClass, sRecord = draginfo.getShortcutData();
			if sClass == "unit" or sClass == "reference_unit" then
				-- For some reason draginfo.getDatabaseNode() isn't working here
				CombatManagerKw.addUnit(sClass, DB.findNode(sRecord));
			end
		end
	end
end

function handleUnitDamage(rSource, rTarget, bSecret, sDamage, nTotal)
	fApplyDamage(rSource, rTarget, bSecret, sDamage, nTotal);

	local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if not nodeTarget then
		return;
	end

	-- if the target is a unit, re-do health conditions
	local bIsUnit = DB.getValue(nodeTarget, "isUnit", 0) == 1;
	if bIsUnit then
		-- Remove character conditions
		if EffectManager5E.hasEffect(rTarget, "Stable") then
			EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Stable");
		end
		if EffectManager5E.hasEffect(rTarget, "Unconscious") then
			EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Unconscious");
		end
		if EffectManager5E.hasEffect(rTarget, "Dead") then
			EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Dead");
		end

		local nTotalHP = DB.getValue(nodeTarget, "hptotal", 0);
		local nWounds = DB.getValue(nodeTarget, "wounds", 0);

		-- Add unit conditions
		local immuneToDiminished = EffectManager5E.getEffectsByType(rTarget, "IMMUNE", { "diminished" });
		local nHalf = nTotalHP/2;
		local isDiminished = EffectManager5E.hasEffect(rTarget, "Diminished")
		local isBroken = EffectManager5E.hasEffect(rTarget, "Broken")
		if nWounds < nHalf then
			if isDiminished then
				EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Diminished");
			end
			if isBroken then
				EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Broken");
			end
		elseif nWounds >= nHalf and nWounds < nTotalHP then
			if not isDiminished and #immuneToDiminished == 0 then
				EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = "Diminished", nDuration = 0 }, true);
				ActorManagerKw.rollMoraleTestForDiminished(rTarget, rSource);
			end
			if isBroken then
				EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Broken");
			end
		elseif nWounds >= nTotalHP then
			if isDiminished then
				EffectManager.removeEffect(ActorManager.getCTNode(rTarget), "Diminished");
			end
			if not isBroken then
				EffectManager.addEffect("", "", ActorManager.getCTNode(rTarget), { sName = "Broken", nDuration = 0 }, true);
			end
		end
	end
end

-- Big hack
-- Add a check so that we can bail early (if targeting a harrowing creature with an attack)
function actionRoll(rSource, vTarget, rRolls)
	if rRolls[1].sDesc:match("%[BAIL%]") then 
		return; 
	end

	fActionRoll(rSource, vTarget, rRolls);
end

---------------------------------------------------------------
-- NPC Action Parsing
---------------------------------------------------------------
function parseNPCPower(nodePower)
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
	consolidationHelper(aActions, aWordStats, "test", parseTests(nodeUnit, sPowerName, aWords));
	consolidationHelper(aActions, aWordStats, "unitsavedc", parseSaves(nodeUnit, sPowerName, aWords));
	consolidationHelper(aActions, aWordStats, "damage", parseDamages(nodeUnit, sPowerName, aWords));
	consolidationHelper(aActions, aWordStats, "heal", parseHeals(nodeUnit, sPowerName, aWords));
	-- consolidationHelper(aActions, aWordStats, "effect", parseEffects(sPowerName, aWords));
	
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
	local tests = {};

	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "test") then
			local nIndex = i;
			if StringManager.isWord(aWords[nIndex - 1], DataCommon.abilities) and
					StringManager.isNumberString(aWords[nIndex - 2]) and
					StringManager.isWord(aWords[nIndex - 3], "dc") then
				local rTest = {};
				rTest.startindex = nIndex - 3;
				rTest.endindex = nIndex;
				rTest.stat = aWords[nIndex - 1];
				rTest.label = StringManager.capitalize(rTest.stat) .. " - " .. sPowerName;
				rTest.nTargetDC = tonumber(aWords[nIndex - 2]);
				rTest.modifier = ActorManagerKw.getAbilityBonus(nodeUnit, rTest.stat) or 0;
				table.insert(tests, rTest);
			end
		end
	end

	return tests;
end

function parseSaves(nodeUnit, sPowerName, aWords)
	local saves = {};

	for i = 1, #aWords do
		if StringManager.isWord(aWords[i], "save") then
			local nIndex = i;
			if StringManager.isWord(aWords[nIndex - 1], DataCommon.abilities) then
				local rSave = {};
				rSave.save = aWords[nIndex - 1];
				rSave.label = sPowerName;
				rSave.savemod = 8;
				rSave.startindex = 1;
				rSave.endindex = 1;

				-- Check for "DC # <stat> save"
				if StringManager.isNumberString(aWords[nIndex - 2]) and
						StringManager.isWord(aWords[nIndex - 3], "dc") then
					rSave.savemod = tonumber(aWords[nIndex - 2]);
					rSave.startindex = nIndex - 3;
					rSave.endindex = nIndex;
					table.insert(saves, rSave);

				-- Check for <stat> save (DC = # + this unit's size)
				elseif StringManager.isWord(aWords[nIndex + 1], "dc") and
						StringManager.isNumberString(aWords[nIndex + 2]) and
						StringManager.isWord(aWords[nIndex + 3], "+") and
						StringManager.isWord(aWords[nIndex + 4], "this") and
						StringManager.isWord(aWords[nIndex + 5], "unit's") and
						StringManager.isWord(aWords[nIndex + 6], "size") then
					rSave.savemod = rSave.savemod + (ActorManagerKw.getUnitSize(nodeUnit) or 0)
					rSave.startindex = nIndex - 1;
					rSave.endindex = nIndex + 6;
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