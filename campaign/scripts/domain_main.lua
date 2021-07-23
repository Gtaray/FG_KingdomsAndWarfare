-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
		
	return self[sControl].update(bReadOnly, bForceHide);
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);

	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly) then bSection1 = true; end;
	else
		updateControl("nonid_name", bReadOnly, true);
	end

	powerdie.setReadOnly(bReadOnly);
	size.setReadOnly(bReadOnly);

    diplomacy.setReadOnly(bReadOnly);
    espionage.setReadOnly(bReadOnly);
    lore.setReadOnly(bReadOnly);
    operations.setReadOnly(bReadOnly);
	
	communications.setReadOnly(bReadOnly);
	resolve.setReadOnly(bReadOnly);
	resources.setReadOnly(bReadOnly);

	if bReadOnly then
		powerpool_iedit.setValue(0);
		powers_iedit.setValue(0);
		features_iedit.setValue(0);
	end

	powerpool_iedit.setVisible(not bReadOnly);
	powerpool_iadd.setVisible(not bReadOnly);
	for _,w in ipairs(powerpool.getWindows()) do
		w.value.setReadOnly(bReadOnly);
	end

	-- Powers
	powers_iedit.setVisible(not bReadOnly);
	powers_iadd.setVisible(not bReadOnly);
	for _,w in ipairs(powers.getWindows()) do
		w.name.setReadOnly(bReadOnly);
		w.desc.setReadOnly(bReadOnly);
	end

	-- Features
	features_iedit.setVisible(not bReadOnly);
	features_iadd.setVisible(not bReadOnly);
	for _,w in ipairs(features.getWindows()) do
		w.name.setReadOnly(bReadOnly);
		w.desc.setReadOnly(bReadOnly);
	end
end