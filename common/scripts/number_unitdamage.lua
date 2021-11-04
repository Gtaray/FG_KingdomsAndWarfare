-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	CombatManagerKw.pushListMode(CombatManagerKw.LIST_MODE_UNIT);
	local rActor = ActorManager.resolveActor(window.getDatabaseNode());
	local rAction = {};
	rAction.label = "Power";
	rAction.clauses = {}

	local clause = {};
	clause.dice = { };
	clause.modifier = getValue();
	clause.dmgtype = (ActorManagerKw.getUnitType(rActor) or ""):lower();
	table.insert(rAction.clauses, clause);					

	ActionDamage.performRoll(draginfo, rActor, rAction);
	CombatManagerKw.popListMode();
	return true;
end
function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end
	
function onDoubleClick(x, y)
	return action();
end