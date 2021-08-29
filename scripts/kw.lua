-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fGetNPCSourceType;
local fHandleDrop;
local fActionRoll;

function getMartialAdvantageSourceValue(vNode)
	return StringManager.split(DB.getValue(vNode, "source", ""), ",", true);
end

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
			["Source"] = { sField = "source", fGetValue = getMartialAdvantageSourceValue },
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

aCoreDesktopStack = {
	["host"] = {
		{
			icon="button_kw_tokens",
			icon_down="button_kw_tokens_down",
			tooltipres="sidebar_tooltip_warfaretokens",
			class="warfare_tokens",
			path="warfare"
		}
	}
}

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
	if Session.IsHost then
		DesktopManager.registerStackShortcuts(aCoreDesktopStack["host"]);
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

--
-- PARTY SHEET
--
-- This is to handle dropping a domain onto the party sheet
function addDomainToPartySheet(domainNode)
	if not domainNode then
		return;
	end

	local partysheet = DB.findNode("partysheet");
	if not partysheet then
		return;
	end

	-- domain size
	DB.setValue(partysheet, "domainsize", "number", DB.getValue(domainNode, "size", 1))

	-- skills
	DB.setValue(partysheet, "domain.skills.diplomacy.score", "number", DB.getValue(domainNode, "diplomacy", 0))
	DB.setValue(partysheet, "domain.skills.diplomacy.modifier", "number", DB.getValue(domainNode, "diplomacymodifier", 0))
	DB.setValue(partysheet, "domain.skills.espionage.score", "number", DB.getValue(domainNode, "espionage", 0))
	DB.setValue(partysheet, "domain.skills.espionage.modifier", "number", DB.getValue(domainNode, "espionagemodifier", 0))
	DB.setValue(partysheet, "domain.skills.lore.score", "number", DB.getValue(domainNode, "lore", 0))
	DB.setValue(partysheet, "domain.skills.lore.modifier", "number", DB.getValue(domainNode, "loremodifier", 0))
	DB.setValue(partysheet, "domain.skills.operations.score", "number", DB.getValue(domainNode, "operations", 0))
	DB.setValue(partysheet, "domain.skills.operations.modifier", "number", DB.getValue(domainNode, "operationsmodifier", 0))

	-- defenses
	DB.setValue(partysheet, "domain.defenses.communications.score", "number", DB.getValue(domainNode, "communications", 10))
	DB.setValue(partysheet, "domain.defenses.communications.modifier", "number", DB.getValue(domainNode, "communicationsmodifier", 0))
	DB.setValue(partysheet, "domain.defenses.communications.level", "number", DB.getValue(domainNode, "communications_level", 0))
	DB.setValue(partysheet, "domain.defenses.resolve.score", "number", DB.getValue(domainNode, "resolve", 10))
	DB.setValue(partysheet, "domain.defenses.resolve.modifier", "number", DB.getValue(domainNode, "resolvemodifier", 0))
	DB.setValue(partysheet, "domain.defenses.resolve.level", "number", DB.getValue(domainNode, "resolve_level", 0))
	DB.setValue(partysheet, "domain.defenses.resources.score", "number", DB.getValue(domainNode, "resources", 10))
	DB.setValue(partysheet, "domain.defenses.resources.modifier", "number", DB.getValue(domainNode, "resourcesmodifier", 0))
	DB.setValue(partysheet, "domain.defenses.resources.level", "number", DB.getValue(domainNode, "resources_level", 0))

	-- development track
	DB.setValue(partysheet, "domain.development.diplomacy", "number", DB.getValue(domainNode, "skills.diplomacy.track", 0))
	DB.setValue(partysheet, "domain.development.espionage", "number", DB.getValue(domainNode, "skills.espionage.track", 0))
	DB.setValue(partysheet, "domain.development.lore", "number", DB.getValue(domainNode, "skills.lore.track", 0))
	DB.setValue(partysheet, "domain.development.operations", "number", DB.getValue(domainNode, "skills.operations.track", 0))
	DB.setValue(partysheet, "domain.development.communications", "number", DB.getValue(domainNode, "defenses.communications.track", 0))
	DB.setValue(partysheet, "domain.development.resolve", "number", DB.getValue(domainNode, "defenses.resolve.track", 0))
	DB.setValue(partysheet, "domain.development.resources", "number", DB.getValue(domainNode, "defenses.resources.track", 0))

	-- Powers
	local powerNode = DB.getChild(domainNode, "powers");
	for _,power in pairs(DB.getChildren(powerNode)) do
		local newPower = partysheet.createChild("powers").createChild()
		DB.setValue(newPower, "name", "string", DB.getValue(power, "name", ""))
		DB.setValue(newPower, "desc", "formattedtext", DB.getValue(power, "desc", ""))
	end

	-- Features
	local featureNode = DB.getChild(domainNode, "features");
	for _,feature in pairs(DB.getChildren(featureNode)) do
		local newFeature = partysheet.createChild("features").createChild()
		DB.setValue(newFeature, "name", "string", DB.getValue(feature, "name", ""))
		DB.setValue(newFeature, "desc", "formattedtext", DB.getValue(feature, "desc", ""))
	end

	-- Power pool
	local powerpoolNode = DB.getChild(domainNode, "powerpool");
	for _,die in pairs(DB.getChildren(powerpoolNode)) do
		local newDie = partysheet.createChild("powerpool").createChild()
		DB.copyNode(die, newDie);
	end
end

function addDefaultActionsToPartySheetPowers()
	local partysheet = DB.findNode("partysheet");
	if not partysheet then
		return;
	end
	local powers = partysheet.getChild("powers");
	if not powers then
		return;
	end
    for k,powernode in pairs(powers.getChildren()) do
        local powername = DB.getValue(powernode, "name", "");
        if powernode and (powername or "") ~= "" then
            loadActionData(powername, powernode)
        end
    end
end

function loadActionData(sPowerName, nodePower)
    if not nodePower then
        return;
    end

    local sNameLower = sPowerName:lower();

    -- Only process if there are no actions already added
    if DB.getChildCount(nodePower, "actions") == 0 then
        if DataKW.domainpowers[sNameLower] then
            local nodeActions = nodePower.createChild("actions");

            -- the added flag only exists here because a power COULD have effects, but if aura effects
            -- isn't loaded, then it won't add. So we want to make sure we don't print the 'added' message
            -- if no effects were added due to that.
            local bAdded = false
            for _,vAction in ipairs(DataKW.domainpowers[sNameLower]) do
                if addAction(nodeActions, vAction, sPowerName) then
                    bAdded = true;
                end
            end
            if bAdded then
                CharManager.outputUserMessage("message_ps_addaction", sPowerName)
            end
        else
            CharManager.outputUserMessage("message_ps_addaction_empty", sPowerName)
        end
    end
end

function addAction(nodeActions, vAction, sPowerName)
    if vAction.type == "powersave" then
        local nodeCastAction = DB.createChild(nodeActions);
        DB.setValue(nodeCastAction, "type", "string", "cast");

        if nodeCastAction then
            DB.setValue(nodeCastAction, "savetype", "string", vAction.save);
            DB.setValue(nodeCastAction, "savemagic", "number", 0);
            
            if vAction.savemod then
                DB.setValue(nodeCastAction, "savedcbase", "string", "fixed");
                DB.setValue(nodeCastAction, "savedcmod", "number", tonumber(vAction.savemod) or 0);
            end
        end

        return true;

    elseif vAction.type == "effect" then
        -- if this effect has an aura and the aura effects extension isn't loaded, don't add it.
        if vAction.sName:lower():match("aura:") and not KingdomsAndWarfare.isAuraEffectsLoaded() then
            CharManager.outputUserMessage("message_ps_addaction_aura", sPowerName)
            return false;
        end

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

        return true;
    end

    return false;
end