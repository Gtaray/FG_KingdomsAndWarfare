-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function setColor(sColor)
	for _,winUnit in ipairs(list.getWindows()) do
		DB.setValue(winUnit.getDatabaseNode(), "color", "string", sColor); -- Let the TokenManager do the coloration work.
	end
end

-- todo drop handling ecosystem