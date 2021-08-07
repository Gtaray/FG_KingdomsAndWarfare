-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local fAddInfoDB;
function onInit()
    fAddInfoDB = CharManager.addInfoDB;
    CharManager.addInfoDB = addInfoDB;
end
function addInfoDB(nodeChar, sClass, sRecord)
	-- Validate parameters
	if not nodeChar then
		return false;
	end

    if fAddInfoDB(nodeChar, sClass, sRecord) then
        return true;
    end
	
	if sClass == "ref_title" then
		addTitleDB(nodeChar, sClass, sRecord);
    elseif sClass == "reference_martialadvantage" then
        addMartialAdvantageDB(nodeChar, sClass, sRecord);
	else
		return false;
	end
	
	return true;
end

function addTitleDB(nodeChar, sClass, sRecord)
	local nodeSource = CharManager.resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end

	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("featurelist");
	if not nodeList then
		return false;
	end
	
	-- Make sure this item does not already exist
	local sName = DB.getValue(nodeSource, "name", "");
	for _,v in pairs(nodeList.getChildren()) do
		if DB.getValue(v, "name", "") == sName then
			return false;
		end
	end

	-- Add the item
	local vNew = nodeList.createChild();
	DB.copyNode(nodeSource, vNew);
	DB.setValue(vNew, "locked", "number", 1);
	
	-- Announce
	CharManager.outputUserMessage("char_abilities_message_titleadd", DB.getValue(vNew, "name", ""), DB.getValue(nodeChar, "name", ""));
	return true;
end

function addMartialAdvantageDB(nodeChar, sClass, sRecord, bSkipAction)
    local nodeSource = CharManager.resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end

	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("martialadvantages");
	if not nodeList then
		return false;
	end
	
	-- Make sure this item does not already exist
	local sName = DB.getValue(nodeSource, "name", "");
	for _,v in pairs(nodeList.getChildren()) do
		if DB.getValue(v, "name", "") == sName then
			return false;
		end
	end

	-- Add the item
	local vNew = nodeList.createChild();
	DB.copyNode(nodeSource, vNew);
	DB.setValue(vNew, "locked", "number", 1);

    -- Add to powers tab
	if not bSkipAction then
    	local nodeNewPower = PowerManagerKw.addMartialAdvantage(sClass, nodeSource, nodeChar, true);
	end
	
	-- Announce
	CharManager.outputUserMessage("char_abilities_message_maadd", DB.getValue(vNew, "name", ""), DB.getValue(nodeChar, "name", ""));
	return true;
end