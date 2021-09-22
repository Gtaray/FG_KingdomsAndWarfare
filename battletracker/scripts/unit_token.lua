-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onDoubleClick(x, y)
	window.windowlist.window.windowlist.window.active_unit.setValue("battletracker_unitsummary", window.getDatabaseNode().getPath());
end

-- todo drop handling ecosystem