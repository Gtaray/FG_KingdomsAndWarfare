-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOnFilter;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	
	fOnFilter = list.onFilter;
	list.onFilter = onFilter;

	list.applyFilter();
end

-- Update the player CT filter to take into account extra things
-- token visibility & faction
-- unit hidden property
-- who was the last commander
-- if the unit's commander is on the CT
function onFilter(w)
	local node = w.getDatabaseNode();
	if ActorManagerKw.isUnit(node) then
		return false
	end

	return fOnFilter(w);
end
