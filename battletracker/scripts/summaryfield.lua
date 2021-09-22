-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- todo probably delete file

local sFieldNode;
local bUpdating;

function setNode(sUnitNode)
	if sFieldNode then
		DB.removeHandler(sFieldNode, "onUpdate", onNodeValueChanged);
	end

	sNode = sNewNode;

	if sUnitNode then
		sFieldNode = sNode .. "." .. getName()
		DB.addHandler(sFieldNode, "onUpdate", onNodeValueChanged);
		setValue(DB.getValue(sFieldNode));
	else
		sFieldNode = nil;
	end
end

function onNodeValueChanged(nodeField)
	if bUpdating then
		return;
	end

	bUpdating = true;
	setValue(DB.getValue(sFieldNode));
	bUpdating = false;
end

function onValueChanged(nodeField)
	if bUpdating then
		return;
	end

	bUpdating = true;
	DB.setValue(sFieldNode, type[1], getValue());
	bUpdating = false;
end