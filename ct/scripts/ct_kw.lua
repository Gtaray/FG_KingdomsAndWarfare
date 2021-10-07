-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	list.onFilter = onFilter;
	list.applyFilter();

	CombatManager.setCustomTurnStart(onTurnStartSetCommander);
	CombatManager.setCustomDeleteCombatantHandler(onCommanderDelete);
end

function onFilter(w)
	local node = w.getDatabaseNode();
	return not ActorManagerKw.isUnit(node);
end