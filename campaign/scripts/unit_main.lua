-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSummaryChanged();
	update();
end

function onSummaryChanged()
	local sExperience = StringManager.capitalize(experience.getValue());
    local sArmor = armor.getValue();
    local sArmorDesc = "";
    if sArmor == "superheavy" then 
        sArmorDesc = "Super Heavy";
    else
        sArmorDesc = StringManager.capitalize(sArmor);
    end
	local sAncestry = ancestry.getValue();
    local sType = StringManager.capitalize(type.getValue());
	
	local aText = {};
	table.insert(aText, sExperience);
    table.insert(aText, sArmorDesc);
    if sAncestry ~= "" then
        table.insert(aText, sAncestry);
    end
    table.insert(aText, sType);
	local sText = table.concat(aText, ", ");
	
	summary_label.setValue(sText);
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
	local bID = LibraryData.getIDState("unit", nodeRecord);

	local bSection1 = false;
	if Session.IsHost then
		if updateControl("nonid_name", bReadOnly) then bSection1 = true; end;
	else
		updateControl("nonid_name", bReadOnly, true);
	end
    if updateControl("commander", bReadOnly) then bSection1 = true; end;
    summary_label.setVisible(bReadOnly);
	divider.setVisible(bSection1);

    casualties.setReadOnly(bReadOnly);
	tier.setReadOnly(bReadOnly);
    attacks.setReadOnly(bReadOnly);
    damage.setReadOnly(bReadOnly);

    updateControl("experience", bReadOnly, bReadOnly);
    updateControl("armor", bReadOnly, bReadOnly);
    updateControl("ancestry", bReadOnly, bReadOnly);
    updateControl("type", bReadOnly, bReadOnly);
	
	updateControl("attack", bReadOnly);
	updateControl("defense", bReadOnly);
	updateControl("power", bReadOnly);
	updateControl("toughness", bReadOnly);
	updateControl("morale", bReadOnly);
	updateControl("command", bReadOnly);
	
	if bReadOnly then
		if traits_iedit then
			traits_iedit.setValue(0);
			traits_iedit.setVisible(false);
			traits_iadd.setVisible(false);
		end
		
		local bShow = (traits.getWindowCount() ~= 0);
		header_traits.setVisible(bShow);
		traits.setVisible(bShow);
	else
		if traits_iedit then
			traits_iedit.setVisible(true);
			traits_iadd.setVisible(true);
		end
		header_traits.setVisible(true);
		traits.setVisible(true);
	end
	for _,w in ipairs(traits.getWindows()) do
		w.name.setReadOnly(bReadOnly);
		w.desc.setReadOnly(bReadOnly);
	end
end

function addTrait(sName, sDesc)
	local w = traits.createWindow();
	if w then
		w.name.setValue(sName);
		w.desc.setValue(sDesc);
	end
end