-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
end

function update(bReadOnly)
	setReadOnly(bReadOnly);
end

function action(draginfo)
	CombatManagerKw.pushListMode(CombatManagerKw.LIST_MODE_UNIT);
	local rActor = ActorManager.resolveActor(window.getDatabaseNode());
	local rAction = {};
	rAction.label = StringManager.capitalize(target[1]);
	rAction.stat = target[1];
	rAction.modifier = getValue();
	rAction.defense = (defense or {""})[1];


	ActionTest.performRoll(draginfo, rActor, rAction);
	CombatManagerKw.popListMode();
	return true;
end

function onDragStart(button, x, y, draginfo)
	if rollable then
		return action(draginfo);
	end
end
	
function onDoubleClick(x, y)
	if rollable then
		return action();
	end
end
