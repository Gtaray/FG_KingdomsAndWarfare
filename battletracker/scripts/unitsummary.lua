-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nodeUnit;

function onInit()
	updateSummary();
	local nodeUnit = getDatabaseNode();
	DB.addHandler(DB.getPath(nodeUnit, "tier"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "experience"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "armor"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "ancestry"), "onUpdate", updateSummary);
	DB.addHandler(DB.getPath(nodeUnit, "type"), "onUpdate", updateSummary);

	onColorChanged(DB.getChild(nodeUnit, "color"));
	DB.addHandler(DB.getPath(nodeUnit, "color"), "onUpdate", onColorChanged);
end

function onClose()
	DB.removeHandler(DB.getPath(nodeUnit, "tier"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "experience"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "armor"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "ancestry"), "onUpdate", updateSummary);
	DB.removeHandler(DB.getPath(nodeUnit, "type"), "onUpdate", updateSummary);
end

function updateSummary()
	local nodeUnit = getDatabaseNode();

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