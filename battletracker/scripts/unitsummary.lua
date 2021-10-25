-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodeUnit;

function onInit()
	updateSummary();
	local nodeUnit = link.getTargetDatabaseNode(); -- Build the summary of the linked node
	DB.addHandler(DB.getPath(nodeUnit, "tier"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "experience"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "armor"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "ancestry"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "type"), "onUpdate", updateSummary);

	nodeUnit = getDatabaseNode(); -- Color is only tracked in the CT node
	onColorChanged(DB.getChild(nodeUnit, "color"));
	DB.addHandler(DB.getPath(nodeUnit, "color"), "onUpdate", onColorChanged);

	if FriendZone then
		linkFields();
	end
end

function onClose()
	DB.removeHandler(DB.getPath(nodeUnit, "tier"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "experience"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "armor"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "ancestry"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "type"), "onUpdate", updateSummary);
end

function linkFields()
	local nodeUnit = link.getTargetDatabaseNode();
	if nodeUnit and FriendZone.isCohort(nodeUnit) then
		name.setLink(nodeUnit.createChild("name", "string"), true);
		size.setLink(nodeUnit.createChild("size", "number"), true);
		casualties.setLink(nodeUnit.createChild("casualties", "number"), true);
		defense.setLink(nodeUnit.createChild("abilities.defense", "number"), true);
		toughness.setLink(nodeUnit.createChild("abilities.toughness", "number"), true);
		attack.setLink(nodeUnit.createChild("abilities.attack", "number"), true);
		power.setLink(nodeUnit.createChild("abilities.power", "number"), true);
		morale.setLink(nodeUnit.createChild("abilities.morale", "number"), true);
		command.setLink(nodeUnit.createChild("abilities.command", "number"), true);
		number_attacks.setLink(nodeUnit.createChild("attacks", "number"), true);
		damage.setLink(nodeUnit.createChild("damage", "number"), true);
	end
end

function updateSummary()
	local nodeUnit = link.getTargetDatabaseNode();

	local nTier = DB.getValue(nodeUnit, "tier", 1);
	local sExperience = StringManager.capitalize(DB.getValue(nodeUnit, "experience", ""));
	local sArmor = DB.getValue(nodeUnit, "armor", "");
	local sAncestry = DB.getValue(nodeUnit, "ancestry", "");
	local sType = StringManager.capitalize(DB.getValue(nodeUnit, "type", ""));
	
	local aText = { "Tier " .. nTier };
	if sExperience ~= "" then table.insert(aText, sExperience); end
	if sArmor ~= "" then table.insert(aText, sArmor); end
	if sAncestry ~= "" then table.insert(aText, sAncestry); end
	if sType ~= "" then table.insert(aText, sType); end
	
	local sText = table.concat(aText, ", ");
	summary_label.setValue(sText);
end

function onColorChanged(nodeColor)
	color_swatch.setBackColor(DB.getValue(nodeColor, "", "00000000"))
end

-- No need to reinvent the CT action list wheel.
function setActiveVisible()
end