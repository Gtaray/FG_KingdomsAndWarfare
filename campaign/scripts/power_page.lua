-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOnDrop;
function onInit()
	fOnDrop = super.onDrop;
	super.onDrop = onDrop

	if super and super.onInit then
		super.onInit();
	end

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "powergroup.*.domainsize"), "onUpdate", onAbilityChanged);
end
function onClose()
	super.onClose();

	local node = getDatabaseNode();
	DB.removeHandler(DB.getPath(node, "powergroup.*.domainsize"), "onUpdate", onAbilityChanged);
end

function onDrop(x, y, draginfo)
	local bReturn = fOnDrop(x, y, draginfo);
	if bReturn then
		return bReturn; 
	end

	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		if sClass == "reference_martialadvantage" then
			local node = draginfo.getDatabaseNode();
			if node then
				bUpdatingGroups = true;
				PowerManagerKw.addMartialAdvantage(sClass, draginfo.getDatabaseNode(), getDatabaseNode());
				bUpdatingGroups = false;
				return true;
			end
		end
	end
end