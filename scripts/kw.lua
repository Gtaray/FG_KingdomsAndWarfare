-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fGetNPCSourceType;
local fHandleDrop;
local fApplyDamage;

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
	table.insert(GameSystem.targetactions, "test");

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

	ActionsManager.actionDirect = actionDirect;
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
-- Add a check to see if aTargeting is false, and if so, terminate early
-- This way I can force a roll to bail at the OnTargeting step
function actionDirect(rActor, sDragType, rRolls, aTargeting)
	--Debug.chat('new actionsDirect')
	if not aTargeting then
		if ModifierStack.getTargeting() then
			aTargeting = ActionsManager.getTargeting(rActor, nil, sDragType, rRolls);
		else
			aTargeting = { { } };
		end
	end

	-- Start edit
	--Debug.chat(aTargeting);
	if aTargeting == { false } then
		return;
	end
	-- End edit
	
	ActionsManager.actionRoll(rActor, aTargeting, rRolls);
end