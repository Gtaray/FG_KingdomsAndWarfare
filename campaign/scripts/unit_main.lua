-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onSummaryChanged();
	update();
end

function onDrop(x, y, draginfo)
	local sClass, sRecord = draginfo.getShortcutData();
	if sClass == "reference_martialadvantage" or sClass == "reference_unittrait" then
		local unit = getDatabaseNode();
		local rUnit = ActorManager.resolveActor(unit);
		local ctnode = ActorManager.getCTNode(rUnit);
		if unit then
			local traitnode = draginfo.getDatabaseNode();
			local sName = DB.getValue(traitnode, "name", "");
			if (sName or "") == "" then
				return true;
			end
			local sText = DB.getText(traitnode, "text", "");
			local nodeList = unit.createChild("traits");
			if not nodeList then
				return true;
			end

			-- Add the item
			local vNew = nodeList.createChild();

			DB.setValue(vNew, "name", "string", sName);
			DB.setValue(vNew, "desc", "string", sText);
			DB.setValue(vNew, "locked", "number", 1);

			CombatManagerKw.parseUnitTrait(rUnit, vNew)

			CharManager.outputUserMessage("unit_traits_message_traitadd", sName, DB.getValue(unit, "name", ""));

			update();

			-- Handle trait effects
			local nodeEffects = unit.createChild("effects");
			if not nodeEffects then
				return true;
			end

			for k,effectNode in pairs(DB.getChildren(traitnode, "uniteffects")) do
				local vNewEffect = nodeEffects.createChild();
				DB.copyNode(effectNode, vNewEffect);
			end

			return true;
		end
	end
    return false;
end

function onSummaryChanged()
	local sExperience = StringManager.capitalize(experience.getValue());
    local sArmor = armor.getValue();
	local sAncestry = ancestry.getValue();
    local sType = StringManager.capitalize(type.getValue());
	
	local aText = {};
	if sExperience ~= "-" then table.insert(aText, sExperience); end
    if sArmor ~= "-" then table.insert(aText, sArmor); end
    if sAncestry ~= "" then table.insert(aText, sAncestry); end
    if sType ~= "-" then table.insert(aText, sType); end
	
	local sText = table.concat(aText, ", ");
	summary_label.setValue(sText);
end

function updateControl(sControl, bReadOnly, bForceHide)
	if not self[sControl] then
		return false;
	end
		
	return self[sControl].update(bReadOnly, bForceHide);
end

function updateFriendZoneControls(sControl, bReadOnly, bForceHide)
	if KingdomsAndWarfare.IsFriendZoneLoaded() then
		-- if the path starts with unit, force hide
		-- Since we only want to show the health field for cohorts
		node = getDatabaseNode();
		if StringManager.startsWith(node.getPath(), "unit.") then
			bForceHide = true;
		end
	else
		bForceHide = true;		
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
	if updateControl("commander_readonly", bReadOnly) then bSection1 = true; end;
	
    summary_label.setVisible(bReadOnly);
	divider.setVisible(bSection1);

    casualties.setReadOnly(bReadOnly);
	tier.setReadOnly(bReadOnly);
    attacks.setReadOnly(bReadOnly);
    damage.setReadOnly(bReadOnly);

	button_rally.setVisible(bReadOnly);

	updateFriendZoneControls("wounds", bReadOnly)

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