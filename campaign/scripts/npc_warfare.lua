-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);

	domainsize.setReadOnly(bReadOnly);
	
	if bReadOnly then
		if martialadvantages_iedit then
			martialadvantages_iedit.setValue(0);
			martialadvantages_iedit.setVisible(false);
			martialadvantages_iadd.setVisible(false);
		end
		
		local bShow = (martialadvantages.getWindowCount() ~= 0);
		header_martialadvantages.setVisible(bShow);
		martialadvantages.setVisible(bShow);
	else
		if martialadvantages_iedit then
			martialadvantages_iedit.setVisible(true);
			martialadvantages_iadd.setVisible(true);
		end
		header_martialadvantages.setVisible(true);
		martialadvantages.setVisible(true);
	end
	for _,w in ipairs(martialadvantages.getWindows()) do
		w.name.setReadOnly(bReadOnly);
		w.desc.setReadOnly(bReadOnly);
	end
end

function addMartialAdvantage(sName, sDesc)
	local w = martialadvantages.createWindow();
	if w then
		w.name.setValue(sName);
		w.desc.setValue(sDesc);
	end
end

function onDrop(x, y, draginfo)
	if WindowManager.getReadOnlyState(getDatabaseNode()) then
		return true;
	end
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();
		
		if sClass == "reference_martialadvantage" then
			addMartialAdvantage(DB.getValue(nodeSource, "name", ""), DB.getText(nodeSource, "text", ""));
		end
		return true;
	end
end
