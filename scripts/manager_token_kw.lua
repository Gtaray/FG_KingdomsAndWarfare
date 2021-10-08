-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

TOKEN_STATE_SIZE = 15
TOKEN_STATE_POSX = 0;
TOKEN_STATE_POSY = 0;
TOKEN_STATE_SPACING = 2;

TOKEN_BROKEN_SIZE = 40;

UNDERLAY_OPACITY = "7F";
DEFAULT_COLOR = "FFFFFFFF";

local fUpdateEffectsHelper;
local fUpdateSizeHelper;
local fUpdateTokenColor;

function onInit()
	fUpdateEffectsHelper = TokenManager.updateEffectsHelper;
	TokenManager.updateEffectsHelper = updateEffectsHelper;
	fUpdateSizeHelper = TokenManager.updateSizeHelper;
	TokenManager.updateSizeHelper = updateSizeHelper;
	fUpdateTokenColor = TokenManager.updateTokenColor;
	TokenManager.updateTokenColor = updateTokenColor;

	TokenManager.registerWidgetSet("state", { "action", "reaction" });
	TokenManager.registerWidgetSet("exposed", { "exposed", "reaction" });
	TokenManager.registerWidgetSet("unithealth", { "broken" });
	CombatManager.addCombatantFieldChangeHandler("activated", "onUpdate", updateState);
	CombatManager.addCombatantFieldChangeHandler("reaction", "onUpdate", updateState);
	CombatManager.addCombatantFieldChangeHandler("exposed", "onUpdate", updateExposed);
	CombatManager.addCombatantFieldChangeHandler("wounds", "onUpdate", updateWounds);

	if Session.IsHost then
		CombatManager.addCombatantFieldChangeHandler("color", "onUpdate", updateColor);
	end

	CombatManagerKw.registerUnitSelectionHandler(onBattleTrackerSelection);

	-- Initialize the states of tokens
	initializeStates();
end

function updateEffectsHelper(tokenCT, nodeCT)
	fUpdateEffectsHelper(tokenCT, nodeCT);
	updateStateHelper(tokenCT, nodeCT);
	updateWoundsHelper(tokenCT, nodeCT);
	updateExposedHelper(tokenCT, nodeCT);
end

function updateSizeHelper(tokenCT, nodeCT)
	fUpdateSizeHelper(tokenCT, nodeCT)
	updateColorHelper(tokenCT, nodeCT)
end

function updateTokenColor(token)
	if not token then
		return;
	end
	local nodeCT = CombatManager.getCTFromToken(token);
	if ActorManagerKw.isUnit(nodeCT) then
		updateColorHelper(token, nodeCT);
	else
		fUpdateTokenColor(token);
	end
end

--==================================================================================--

function initializeStates()
	-- todo relocate this to updateAttributesHelper, which is invoked (indirectly) on demand by the ImageManager
	local aCurrentCombatants = CombatManagerKw.getCombatantNodes(CombatManagerKw.LIST_MODE_UNIT);
	for _,nodeCT in pairs(aCurrentCombatants) do
		if ActorManagerKw.isUnit(nodeCT) then
			local tokenCT = CombatManager.getTokenFromCT(nodeCT);
			if tokenCT then
				updateStateHelper(tokenCT, nodeCT);
				updateWoundsHelper(tokenCT, nodeCT);
				updateColorHelper(tokenCT, nodeCT);
			end
		end
	end
end

function updateWounds(nodeWounds)
	if not nodeWounds then return; end

	local nodeCT = nodeWounds.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateWoundsHelper(tokenCT, nodeCT)
	end
end

function updateWoundsHelper(tokenCT, nodeCT)
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		local aWidgets = TokenManager.getWidgetList(tokenCT, "unithealth");
		local bIsBroken = ActorHealthManager.getWoundPercent(ActorManager.resolveActor(nodeCT)) >= 1;

		local wBroken = aWidgets["broken"];
		if wBroken and not bIsBroken then
			wBroken.destroy();
			wBroken = nil;
		end
		if not wBroken and bIsBroken then
			wBroken = tokenCT.addBitmapWidget();
			if wBroken then
				wBroken.setName("broken")
			end
		end

		if wBroken then
			wBroken.setBitmap("cond_broken");
			wBroken.setTooltipText("Broken");
			wBroken.setSize(TOKEN_BROKEN_SIZE, TOKEN_BROKEN_SIZE);
		end
	end
end

function updateState(nodeState)
	if not nodeState then return; end

	local nodeCT = nodeState.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateStateHelper(tokenCT, nodeCT);	 
	end
end

function updateStateHelper(tokenCT, nodeCT)
	-- Only do this for units
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		local aWidgets = TokenManager.getWidgetList(tokenCT, "state");
		local bHasActivated = DB.getValue(nodeCT, "activated", 0) == 1;
		local bHasReacted = DB.getValue(nodeCT, "reaction", 0) == 1;

		local posx = 0;

		local wAction = aWidgets["action"]
		if wAction and not bHasActivated then
			wAction.destroy()
			wAction = nil;
		elseif not wAction and bHasActivated then
			wAction = tokenCT.addBitmapWidget();
			if wAction then
				wAction.setName("action");
			end
		end
		if wAction then
			wAction.setBitmap("state_activated");
			wAction.setTooltipText("Has Activated");
			wAction.setSize(TOKEN_STATE_SIZE, TOKEN_STATE_SIZE);
			wAction.setPosition("topleft", posx + TOKEN_STATE_SIZE / 2, TOKEN_STATE_SIZE / 2)
			posx = posx + TOKEN_STATE_SIZE;
		end

		local wReaction = aWidgets["reaction"]
		if wReaction and not bHasReacted then
			wReaction.destroy()
			wReaction = nil;
		elseif not wReaction and bHasReacted then
			wReaction = tokenCT.addBitmapWidget();
			if wReaction then
				wReaction.setName("reaction");
			end
		end
		if wReaction then
			wReaction.setBitmap("state_reacted");
			wReaction.setTooltipText("Has Reacted");
			wReaction.setSize(TOKEN_STATE_SIZE, TOKEN_STATE_SIZE);
			wReaction.setPosition("topleft", posx + TOKEN_STATE_SIZE / 2, TOKEN_STATE_SIZE / 2)
		end
	end
end

function updateExposed(nodeExposed)
	if not nodeExposed then return; end

	local nodeCT = nodeExposed.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateExposedHelper(tokenCT, nodeCT);	 
	end
end

function updateExposedHelper(tokenCT, nodeCT)
	-- Only do this for units
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		local aWidgets = TokenManager.getWidgetList(tokenCT, "exposed");
		local bIsExposed = DB.getValue(nodeCT, "exposed", 0) == 1;

		local wExposed = aWidgets["exposed"]
		if wExposed and not bIsExposed then
			wExposed.destroy()
			wExposed = nil;
		elseif not wExposed and bIsExposed then
			wExposed = tokenCT.addBitmapWidget();
			if wExposed then
				wExposed.setName("exposed");
			end
		end
		if wExposed then
			wExposed.setBitmap("state_exposed");
			wExposed.setTooltipText("Is Exposed");
			wExposed.setSize(TOKEN_STATE_SIZE, TOKEN_STATE_SIZE);
			wExposed.setPosition("bottomright", -(TOKEN_STATE_SIZE / 2), -(TOKEN_STATE_SIZE / 2));
		end
	end
end

function updateColor(nodeColor)
	if not nodeColor then return; end

	local nodeCT = nodeColor.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		updateColorHelper(tokenCT, nodeCT);	 
	end
end

function updateColorHelper(tokenCT, nodeCT)
	-- Only do this for units
	if tokenCT and ActorManagerKw.isUnit(nodeCT) then
		local sColor = DB.getValue(nodeCT, "color", DEFAULT_COLOR);
		local sUnderlay = UNDERLAY_OPACITY .. sColor:sub(3);

		tokenCT.removeAllUnderlays();
		tokenCT.addUnderlay(0.5, sUnderlay);
		tokenCT.setColor(sColor);
	end
end

-- Return CT of a token, otherwise nil
function hasCT(token)
	local ct = CombatManager.getCTFromToken(token); 
	return ct; 
end

function onBattleTrackerSelection(nodeUnit, nSlot)
	local sSlot = tostring(nSlot);
	local tokenCT = CombatManager.getTokenFromCT(nodeUnit);
	if tokenCT then
		local selectionWidget = tokenCT.findWidget("selectionslot");
		if selectionWidget then
			selectionWidget.setText(sSlot);
		else
			selectionWidget = tokenCT.addTextWidget("mini_name_selected", sSlot);
			selectionWidget.setFrame("mini_name", 5, 2, 4, 2);
	
			local w,h = selectionWidget.getSize();
			selectionWidget.setPosition("topright", -w/2-5, h/2+2);

			selectionWidget.setName("selectionslot")
		end
	end

	for _,nodeCombatant in pairs(CombatManagerKw.getCombatantNodes(CombatManagerKw.LIST_MODE_UNIT)) do
		if nodeCombatant ~= nodeUnit then
			tokenCT = CombatManager.getTokenFromCT(nodeCombatant);
			if tokenCT then
				local selectionWidget = tokenCT.findWidget("selectionslot");
				if selectionWidget and (selectionWidget.getText() == sSlot) then
					selectionWidget.destroy();
				end
			end
		end
	end
end