-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

TOKEN_STATE_SIZE = 15
TOKEN_STATE_POSX = 0;
TOKEN_STATE_POSY = 0;
TOKEN_STATE_SPACING = 2;

TOKEN_BROKEN_SIZE = 20;

function onInit()
    TokenManager.registerWidgetSet("state", { "action", "reaction" })
    TokenManager.registerWidgetSet("unithealth", { "broken" })
    CombatManager.addCombatantFieldChangeHandler("activated", "onUpdate", updateState)
    CombatManager.addCombatantFieldChangeHandler("reaction", "onUpdate", updateState)
    CombatManager.addCombatantFieldChangeHandler("reaction", "onUpdate", updateState)
    CombatManager.addCombatantFieldChangeHandler("wounds", "onUpdate", updateWounds)

    -- Initialize the states of tokens
    initializeStates();
end

function initializeStates()
    local aCurrentCombatants = CombatManager.getCombatantNodes();
	for _,nodeCT in pairs(aCurrentCombatants) do
		if ActorManagerKw.isUnit(nodeCT) then
			local tokenCT = CombatManager.getTokenFromCT(nodeCT);
            if tokenCT then
                updateStateHelper(tokenCT, nodeCT);
                updateWoundsHelper(tokenCT, nodeCT)
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
    if ActorManagerKw.isUnit(nodeCT) then
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
            wBroken.setPosition("topright", -(TOKEN_BROKEN_SIZE / 2) - 2, (TOKEN_BROKEN_SIZE / 2) + 2   )
        end
    end
end

function updateState(nodeState)
    local nodeCT = nodeState.getParent();
	local tokenCT = CombatManager.getTokenFromCT(nodeCT);
    if tokenCT and ActorManagerKw.isUnit(nodeCT) then
        updateStateHelper(tokenCT, nodeCT);     
    end
end

function updateStateHelper(tokenCT, nodeCT)
    -- Only do this for units
    if ActorManagerKw.isUnit(nodeCT) then
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