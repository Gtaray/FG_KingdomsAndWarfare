-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local selectionWidget;
local nSelectionSlot;
local activeWidget;
local activatedWidget;
local brokenWidget;

function onInit()
	CombatManagerKw.registerUnitSelectionHandler(unitSelected);

	local nodeUnit = window.getDatabaseNode();
	onActiveUpdated(DB.getChild(nodeUnit, "activeunit"));
	onActivatedUpdated(DB.getChild(nodeUnit, "activated"));
	onWoundsUpdated(DB.getChild(nodeUnit, "wounds"));
	DB.addHandler(DB.getPath(nodeUnit, "activeunit"), "onUpdate", onActiveUpdated);
	DB.addHandler(DB.getPath(nodeUnit, "activated"), "onUpdate", onActivatedUpdated);
	DB.addHandler(DB.getPath(nodeUnit, "wounds"), "onUpdate", onWoundsUpdated);
end

function onClose()
	CombatManagerKw.unregisterUnitSelectionHandler(unitSelected);
	local nodeUnit = DB.getChild(getDatabaseNode(), "..");
	DB.removeHandler(DB.getPath(nodeUnit, "activeunit"), "onUpdate", onActiveUpdated);
	DB.removeHandler(DB.getPath(nodeUnit, "activated"), "onUpdate", onActivatedUpdated);
	DB.removeHandler(DB.getPath(nodeUnit, "wounds"), "onUpdate", onWoundsUpdated);
end

function onDrop(x, y, draginfo)
	local sPrototype, dropref = draginfo.getTokenData();
	if (sPrototype or "") == "" then
		return nil;
	end
	
	setPrototype(sPrototype);
	CombatManager.replaceCombatantToken(window.getDatabaseNode(), dropref);
	return true;
end

function onDragStart(button, x, y, draginfo)
	local node = window.getDatabaseNode();

	draginfo.setType("battletrackerunit");
	draginfo.setTokenData(getPrototype());
	draginfo.setDatabaseNode(node);

	local base = draginfo.createBaseData();
	base.setType("token");
	base.setTokenData(getPrototype());
	
	local nSpace = DB.getValue(node, "space");
	TokenManager.setDragTokenUnits(nSpace);

	return true;
end
function onDragEnd(draginfo)
	TokenManager.endDragTokenWithUnits();

	local prototype, dropref = draginfo.getTokenData();
	if dropref then
		CombatManager.replaceCombatantToken(window.getDatabaseNode(), dropref);
	end
	return true;
end

function onClickDown(button, x, y)
	return true;
end
function onClickRelease(button, x, y)
	if button == 1 then
		if Input.isControlPressed() then
			local nodeActive = CombatManager.getActiveCT();
			if nodeActive then
				local nodeTarget = window.getDatabaseNode();
				if nodeTarget then
					TargetingManager.toggleCTTarget(nodeActive, nodeTarget);
				end
			end

			CombatManagerKw.selectUnit(window.getDatabaseNode(), 2);
		elseif Input.isShiftPressed() then
			CombatManagerKw.selectUnit(window.getDatabaseNode(), 2);
		else
			-- local tokeninstance = CombatManager.getTokenFromCT(window.getDatabaseNode());
			-- if tokeninstance and tokeninstance.isActivable() then
			-- 	tokeninstance.setActive(not tokeninstance.isActive()); -- todo this wont work on clients... remove/relocate?
			-- end

			CombatManagerKw.selectUnit(window.getDatabaseNode(), 1);
		end
	end

	return true;
end

function onDoubleClick(x, y)
	local nodeUnit = window.getDatabaseNode();
	CombatManager.openMap(nodeUnit);
	-- unit activation if it is the commander's turn, or should control overloading be avoided here?

	CombatManagerKw.notifyActivateUnit(nodeUnit)
end

function onWheel(notches)
	TokenManager.onWheelCT(window.getDatabaseNode(), notches);
	return true;
end

function unitSelected(nodeUnit, nSlot)
	if nodeUnit == window.getDatabaseNode() then
		local sSlot = tostring(nSlot);
		if selectionWidget then
			selectionWidget.setText(sSlot);
		else
			selectionWidget = addTextWidget("mini_name_selected",sSlot);
			selectionWidget.setFrame("mini_name", 5, 1, 4, 1);
	
			local w,h = selectionWidget.getSize();
			selectionWidget.setPosition("topright", 0*w/2, h/2+1);
		end

		nSelectionSlot = nSlot;
	elseif nSlot == nSelectionSlot and selectionWidget then
		selectionWidget.destroy();
		selectionWidget = nil;
	end
end

function onActiveUpdated(nodeActive)
	--todo
end

function onActivatedUpdated(nodeActivated)
	local bHasActivated = nodeActivated and (nodeActivated.getValue() == 1);
	if activatedWidget and not bHasActivated then
		activatedWidget.destroy()
		activatedWidget = nil;
	elseif not activatedWidget and bHasActivated then
		activatedWidget = addBitmapWidget();
		activatedWidget.setBitmap("state_activated");
		activatedWidget.setTooltipText("Has Activated");
		activatedWidget.setSize(15, 15);
		activatedWidget.setPosition("topleft", 0*15/2, 15/2)
	end
	--todo
end

function onWoundsUpdated(nodeWounds)
	local nodeUnit = DB.getChild(nodeWounds, "..");
	local bIsBroken = ActorHealthManager.getWoundPercent(ActorManager.resolveActor(nodeUnit)) >= 1;
	if brokenWidget and not bIsBroken then
		brokenWidget.destroy();
		brokenWidget = nil;
	end
	if not brokenWidget and bIsBroken then
		brokenWidget = addBitmapWidget();
		brokenWidget.setBitmap("cond_broken");
		brokenWidget.setTooltipText("Broken");
		brokenWidget.setSize(20, 20);
	end
	--todo
end