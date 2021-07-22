-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- This class manages overrides for the combat manager 5e script

local fAddNPC;

function onInit()
    fAddNPC = CombatManager2.addNPC;
    CombatManager.setCustomAddNPC(addNpcOrUnit);
end

-- Override default add NPC function to handle Units.
function addNpcOrUnit(sClass, nodeActor, sName)
    local nodeEntry = nil;
    if sClass == "npc" or sClass == "reference_npc" then
        nodeEntry = fAddNPC(sClass, nodeActor, sName);
    end
    if sClass == "unit" or sClass == "reference_unit" then
        nodeEntry = addUnit(sClass, nodeActor, sName);
    end
    return nodeEntry;
end

function addUnit(sClass, nodeUnit, sName)
    if not nodeUnit then
        return nil;
    end

    -- Setup
	local aCurrentCombatants = CombatManager.getCombatantNodes();

    -- Get the name to use for this addition
	local bIsCT = (UtilityManager.getRootNodeName(nodeUnit) == CombatManager.CT_MAIN_PATH);
	local sNameLocal = sName;
	if not sNameLocal then
		sNameLocal = DB.getValue(nodeUnit, "name", "");
		if bIsCT then
			sNameLocal = CombatManager.stripCreatureNumber(sNameLocal);
		end
	end
	local sNonIDLocal = DB.getValue(nodeUnit, "nonid_name", "");
	if sNonIDLocal == "" then
		sNonIDLocal = Interface.getString("library_recordtype_empty_nonid_npc");
	elseif bIsCT then
		sNonIDLocal = CombatManager.stripCreatureNumber(sNonIDLocal);
	end
	
	local nLocalID = DB.getValue(nodeUnit, "isidentified", 1);
	if not bIsCT then
		local sSourcePath = nodeUnit.getPath()
		local aMatches = {};
		for _,v in pairs(aCurrentCombatants) do
			local _,sRecord = DB.getValue(v, "sourcelink", "", "");
			if sRecord == sSourcePath then
				table.insert(aMatches, v);
			end
		end
		if #aMatches > 0 then
			nLocalID = 0;
			for _,v in ipairs(aMatches) do
				if DB.getValue(v, "isidentified", 1) == 1 then
					nLocalID = 1;
				end
			end
		end
	end
	
	local nodeLastMatch = nil;
	if sNameLocal:len() > 0 then
		-- Determine the number of Units with the same name
		local nNameHigh = 0;
		local aMatchesWithNumber = {};
		local aMatchesToNumber = {};
		for _,v in pairs(aCurrentCombatants) do
			local sEntryName = DB.getValue(v, "name", "");
			local sTemp, sNumber = CombatManager.stripCreatureNumber(sEntryName);
			if sTemp == sNameLocal then
				nodeLastMatch = v;
				
				local nNumber = tonumber(sNumber) or 0;
				if nNumber > 0 then
					nNameHigh = math.max(nNameHigh, nNumber);
					table.insert(aMatchesWithNumber, v);
				else
					table.insert(aMatchesToNumber, v);
				end
			end
		end
	
		-- If multiple Units of same name, then figure out whether we need to adjust the name based on options
		local sOptNNPC = OptionsManager.getOption("NNPC");
		if sOptNNPC ~= "off" then
			local nNameCount = #aMatchesWithNumber + #aMatchesToNumber;
			
			for _,v in ipairs(aMatchesToNumber) do
				local sEntryName = DB.getValue(v, "name", "");
				local sEntryNonIDName = DB.getValue(v, "nonid_name", "");
				if sEntryNonIDName == "" then
					sEntryNonIDName = Interface.getString("library_recordtype_empty_nonid_npc");
				end
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					DB.setValue(v, "name", "string", sEntryName .. " " .. nNameHigh);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nNameHigh);
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sEntryName);
					DB.setValue(v, "name", "string", sNewName);
					DB.setValue(v, "nonid_name", "string", sEntryNonIDName .. " " .. nSuffix);
				end
			end
			
			if nNameCount > 0 then
				if sOptNNPC == "append" then
					nNameHigh = nNameHigh + 1;
					sNameLocal = sNameLocal .. " " .. nNameHigh;
					sNonIDLocal = sNonIDLocal .. " " .. nNameHigh;
				elseif sOptNNPC == "random" then
					local sNewName, nSuffix = CombatManager.randomName(sNameLocal);
					sNameLocal = sNewName;
					sNonIDLocal = sNonIDLocal .. " " .. nSuffix;
				end
			end
		end
	end
	
	DB.createNode(CombatManager.CT_LIST);
	local nodeEntry = DB.createChild(CombatManager.CT_LIST);
	if not nodeEntry then
		return nil;
	end
	DB.copyNode(nodeUnit, nodeEntry);

	-- Remove any combatant specific information
	DB.setValue(nodeEntry, "active", "number", 0);
	DB.setValue(nodeEntry, "tokenrefid", "string", "");
	DB.setValue(nodeEntry, "tokenrefnode", "string", "");
	DB.deleteChildren(nodeEntry, "effects");
	
	-- Set the final name value
	DB.setValue(nodeEntry, "name", "string", sNameLocal);
	DB.setValue(nodeEntry, "nonid_name", "string", sNonIDLocal);
	DB.setValue(nodeEntry, "isidentified", "number", nLocalID);
	
	-- Lock NPC record view by default when copying to CT
	DB.setValue(nodeEntry, "locked", "number", 1);

	-- Set up the CT specific information
	DB.setValue(nodeEntry, "link", "windowreference", "", ""); -- Workaround to force field update on client; client does not pass network update to other clients if setValue creates value node with default value
	DB.setValue(nodeEntry, "link", "windowreference", "reference_unit", "");
	DB.setValue(nodeEntry, "friendfoe", "string", "foe");
	if not bIsCT then
		DB.setValue(nodeEntry, "sourcelink", "windowreference", "reference_unit", nodeUnit.getPath());
	end
	
	-- Calculate space/reach
	DB.setValue(nodeEntry, "space", "number", 1);
	DB.setValue(nodeEntry, "reach", "number", 1);

	-- Set default letter token, if no token defined
	local sToken = DB.getValue(nodeUnit, "token", "");
	if sToken == "" or not Interface.isToken(sToken) then
		local sLetter = StringManager.trim(sNameLocal):match("^([a-zA-Z])");
		if sLetter then
			sToken = "tokens/Medium/" .. sLetter:lower() .. ".png@Letter Tokens";
		else
			sToken = "tokens/Medium/z.png@Letter Tokens";
		end
		DB.setValue(nodeEntry, "token", "token", sToken);
	end

    -- set casualty die (aka hit points)
    local nHP = DB.getValue(nodeUnit, "casualties", 0);
    DB.setValue(nodeEntry, "hptotal", "number", nHP);

    -- TODO: Handle traits that might add effects here
    local aEffects = {};

    -- Decode traits
    for _,v in pairs(DB.getChildren(nodeEntry, "traits")) do
		CombatManager2.parseNPCPower(rActor, v, aEffects);
	end

    -- Add special effects
	if #aEffects > 0 then
		EffectManager.addEffect("", "", nodeEntry, { sName = table.concat(aEffects, "; "), nDuration = 0, nGMOnly = 1 }, false);
	end

    -- try to find the Commander in the CT and use their initiative and faction
    -- else leave initiative blank and faction = foe
    local sCommander = DB.getValue(nodeUnit, "commander", "");
    for _,v in pairs(aCurrentCombatants) do
        local sName = DB.getValue(v, "name", "", "");
        if sCommander == sName then
            local init = DB.getValue(v, "initresult", 0);
            DB.setValue(nodeEntry, "initresult", "number", init);
            local faction = DB.getValue(v, "friendfoe", "foe");
            DB.setValue(nodeEntry, "friendfoe", "string", faction);
        end
    end
	
	return nodeEntry;
end