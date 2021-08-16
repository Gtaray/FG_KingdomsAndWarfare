-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fGetNPCSourceType;
local fHandleDrop;
local fActionRoll;

aRecordOverrides = {	
	-- New record types
	["unit"] = { 
		bExport = true,
        sRecordDisplayClass = "reference_unit", 
		aDataMap = { "unit", "reference.unitdata" }, 
		aGMListButtons = { "button_unit_letter", "button_unit_tier", "button_unit_type", "button_unit_ancestry" },
		aPlayerListButtons = { "button_unit_letter", "button_unit_tier", "button_unit_type", "button_unit_ancestry" },
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
	},
	["advantage"] = {
		bExport = true,
		sRecordDisplayClass = "reference_martialadvantage",
		aDataMap = { "martialadvantage", "reference.martialadvantagedata" },
		aCustomFilters = {
			["Class"] = { sField = "source" },
			["Domain Size"] = { sField = "domainsize" },
		}
	},
	["trait"] = {
		bExport = true,
		sRecordDisplayClass = "reference_unittrait",
		aDataMap = { "unittrait", "reference.unittraitdata" }
	}
};

aListViews = {
	["unit"] = {
		["byletter"] = {
			sTitleRes = "unit_grouped_title_byletter",
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "unit_grouped_label_name", nWidth=250 },
				{ sName = "ancestry", sType = "ancestry", sHeadingRes = "unit_grouped_label_ancestry", nWidth=100 },
				{ sName = "type", sType = "type", sHeadingRes = "unit_grouped_label_type", nWidth=80 },
				{ sName = "tier", sType = "number", sHeadingRes = "unit_grouped_label_tier", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "name", nLength = 1 } },
			aGroupValueOrder = { },
		},
		["bytier"] = {
			sTitleRes = "unit_grouped_title_bytier",
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "unit_grouped_label_name", nWidth=250 },
				{ sName = "ancestry", sType = "ancestry", sHeadingRes = "unit_grouped_label_ancestry", nWidth=100 },
				{ sName = "type", sType = "type", sHeadingRes = "unit_grouped_label_type", nWidth=80 },
				{ sName = "tier", sType = "number", sHeadingRes = "unit_grouped_label_tier", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "tier", sPrefix = "Tier" } },
			aGroupValueOrder = { },
		},
		["bytype"] = {
			sTitleRes = "unit_grouped_title_bytype",
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "unit_grouped_label_name", nWidth=250 },
				{ sName = "ancestry", sType = "ancestry", sHeadingRes = "unit_grouped_label_ancestry", nWidth=100 },
				{ sName = "type", sType = "type", sHeadingRes = "unit_grouped_label_type", nWidth=80 },
				{ sName = "tier", sType = "number", sHeadingRes = "unit_grouped_label_tier", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = { "Infantry", "Artillery", "Cavalry", "Aerial" },
		},
		["byancestry"] = {
			sTitleRes = "unit_grouped_title_byancestry",
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "unit_grouped_label_name", nWidth=250 },
				{ sName = "ancestry", sType = "ancestry", sHeadingRes = "unit_grouped_label_ancestry", nWidth=100 },
				{ sName = "type", sType = "type", sHeadingRes = "unit_grouped_label_type", nWidth=80 },
				{ sName = "tier", sType = "number", sHeadingRes = "unit_grouped_label_tier", bCentered=true },
			},
			aFilters = { },
			aGroups = { { sDBField = "ancestry" } },
			aGroupValueOrder = { },
		},
	},
};

aDamageTokenTypes = {
	"acid",
	"bleed",
	"fire",
	"poison"
}

function onInit()
	for kRecordType,vRecordType in pairs(aRecordOverrides) do
		LibraryData.overrideRecordTypeInfo(kRecordType, vRecordType);
	end
	for kRecordType,vRecordListViews in pairs(aListViews) do
		for kListView, vListView in pairs(vRecordListViews) do
			LibraryData.setListView(kRecordType, kListView, vListView);
		end
	end

	GameSystem.actions.test = { bUseModStack = true, sTargeting = "each" };
	GameSystem.actions.rally = { bUseModStack = true };
	GameSystem.actions.powerdie = { bUseModStack = false, sTargeting = "all" };
	GameSystem.actions.domainskill = { bUseModStack = true };
	GameSystem.actions.diminished = { bUseModStack = true };
	GameSystem.actions.harrowing = { bUseModStack = true };
	GameSystem.actions.unitsaveinit = { sTargeting = "each" };
	GameSystem.actions.unitsavedc = { bUseModStack = true, sTargeting = "each" };
	GameSystem.actions.endure = { bUseModStack = true }

	table.insert(GameSystem.targetactions, "test");
	table.insert(GameSystem.targetactions, "unitsaveinit");
	table.insert(GameSystem.targetactions, "unitsavedc");
	table.insert(GameSystem.targetactions, "powerdie");

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

	table.insert(DataCommon.dmgtypes, "infantry");
	table.insert(DataCommon.dmgtypes, "artillery");
	table.insert(DataCommon.dmgtypes, "cavalry");
	table.insert(DataCommon.dmgtypes, "aerial");

	table.insert(DataCommon.conditions, "broken");
	table.insert(DataCommon.conditions, "disbanded");
	table.insert(DataCommon.conditions, "disorganized");
	table.insert(DataCommon.conditions, "disoriented");
	table.insert(DataCommon.conditions, "exposed");
	table.insert(DataCommon.conditions, "fearless");
	table.insert(DataCommon.conditions, "harrowed");
	table.insert(DataCommon.conditions, "hidden");
	table.insert(DataCommon.conditions, "misled");
	table.insert(DataCommon.conditions, "rallied");
	table.insert(DataCommon.conditions, "weakened");

	TokenManager.addEffectTagIconBonus("DEF");
	TokenManager.addEffectTagIconBonus("POW");
	TokenManager.addEffectTagIconBonus("TOU");
	TokenManager.addEffectTagIconBonus("MOR");
	TokenManager.addEffectTagIconBonus("COM");

	TokenManager.addEffectConditionIcon("disorganized", "cond_disorganized");
	TokenManager.addEffectConditionIcon("disoriented", "cond_disoriented");
	TokenManager.addEffectConditionIcon("fearless", "cond_harrowpassed");
	TokenManager.addEffectConditionIcon("harrowed", "cond_harrowed");
	TokenManager.addEffectConditionIcon("hidden", "cond_blinded");
	TokenManager.addEffectConditionIcon("misled", "cond_misled");
	TokenManager.addEffectConditionIcon("rallied", "cond_rallied");
	TokenManager.addEffectConditionIcon("weakened", "cond_weakened");
	TokenManager.addEffectConditionIcon("advtest", "cond_advantage");
	TokenManager.addEffectConditionIcon("distest", "cond_disadvantage");
	TokenManager.addEffectConditionIcon("acid", "token_acid");
	TokenManager.addEffectConditionIcon("bleed", "token_bleed");
	TokenManager.addEffectConditionIcon("fire", "token_fire");
	TokenManager.addEffectConditionIcon("poison", "token_poison");

	TokenManager.addEffectTagIconSimple("ACID", "token_acid");
	TokenManager.addEffectTagIconSimple("BLEED", "token_bleed");
	TokenManager.addEffectTagIconSimple("FIRE", "token_fire");
	TokenManager.addEffectTagIconSimple("POISON", "token_poison");
	TokenManager.addEffectTagIconSimple("ADVTEST", "cond_advantage");
	TokenManager.addEffectTagIconSimple("DISTEST", "cond_disadvantage");

	TokenManager.addEffectTagIconSimple("GRANTDISPOW", "cond_advantage");
	TokenManager.addEffectTagIconSimple("GRANTADVPOW", "cond_disadvantage");

	LibraryData.setCustomData("battle", "acceptdrop", { "unit", "reference_unit" });

	fGetNPCSourceType = NPCManager.getNPCSourceType;
	NPCManager.getNPCSourceType = getNPCSourceType;

	fHandleDrop = CampaignDataManager.handleDrop;
	CampaignDataManager.handleDrop = handleUnitDropOnCT;

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
				handled = CombatManagerKw.addUnit(sClass, DB.findNode(sRecord)) ~= nil;
			end
		end
	end

	return handled;
end

-- Big hack
-- Add a check so that we can bail early (if targeting a harrowing creature with an attack)
function actionRoll(rSource, vTarget, rRolls)
	if rRolls and rRolls[1].sDesc:match("%[BAIL%]") then 
		return; 
	end

	fActionRoll(rSource, vTarget, rRolls);
end

function IsFriendZoneLoaded()
	for _,v in pairs(Extension.getExtensions()) do
		if v == "FriendZone" then
			return true;
		end
	end
	return false;
end

function isAuraEffectsLoaded()
	for _,v in pairs(Extension.getExtensions()) do
		if v == "FG-Aura-Effect" then
			return true;
		end
	end
	return false;
end