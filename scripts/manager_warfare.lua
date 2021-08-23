-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

MARKERS = {
	["rank_vanguard_friend"] = { rank = "vanguard", faction = "friend" },
	["rank_reserves_friend"] = { rank = "reserve", faction = "friend" },
	["rank_center_friend"] = { rank = "center", faction = "friend" },
	["rank_rear_friend"] = { rank = "rear", faction = "friend" },
	["rank_vanguard_foe"] = { rank = "vanguard", faction = "foe" },
	["rank_reserves_foe"] = { rank = "reserve", faction = "foe" },
	["rank_center_foe"] = { rank = "center", faction = "foe" },
	["rank_rear_foe"] = { rank = "rear", faction = "foe" },
}

function onInit()
end

function setMarkersActive(windowinstance, bActive)
	local sMarkerPos = getImageRankPositionOption(windowinstance);
	if not sMarkerPos then
		return;
	end
	local image = windowinstance.image;
	if not image then
		return;
	end
	local markers = getRankMarkers(image);
	if not markers then
		return;
	end
	local collapsedMarker = getCollapsedMarker(image);

	for k,v in pairs(image.getTokens()) do
		if not CombatManager.getCTFromToken(v) then
			local prototype = v.getPrototype();
			if (markers and markers[prototype]) or prototype == collapsedMarker then
				v.setActivable(bActive);
				v.setModifiable(bActive);
			end	 
		end
	end
end

function onTurnStart(nodeCT)
	--Debug.chat('onTurnStart()')
	local windowinstance = getImageWindow(nodeCT);
	if not windowinstance then
		return;
	end
	updateTokensOnMap(windowinstance);

end

function updateTokensOnMap(windowinstance)
	local sMarkerPos = getImageRankPositionOption(windowinstance);
	if not sMarkerPos then 
		return;
	end

	local image = windowinstance.image;
	if not image then
		return;
	end

	local ranks, units = getRanksAndUnits(image, sMarkerPos);
	if ranks and units then
		checkForExposedUnits(ranks, units, sMarkerPos);
	end
end

function getImageWindow(ctnode)
	-- Debug.chat('getImageWindow')
	if not ctnode then
		return;
	end

	local token = CombatManager.getTokenFromCT(ctnode)
	if not token then
		return;
	end

	local container = token.getContainerNode()
	if not container then
		return;
	end

	-- Remove the last '.image' from the container path, since we want the imagewindow record name.
	local dbpath = container.getPath():gsub(".image", "");
	local windowinstance = Interface.findWindow("imagewindow", dbpath)
	if not windowinstance then
		return;
	end

	return windowinstance;
end

function getImageRankPositionOption(windowinstance)
	if not windowinstance then
		return;
	end
	if not windowinstance.toolbar then
		return;
	end
	if not windowinstance.toolbar.subwindow then
		return;
	end
	if not windowinstance.toolbar.subwindow.rank_position then
		return;
	end

	local nRankPos = windowinstance.toolbar.subwindow.rank_position.getValue();
	
	return getMarkerPosition(nRankPos);
end

function getRankMarkers(image)
	local markers = {};
	if image.window then
		local imagenode = image.window.getDatabaseNode();
		if imagenode then
			for nodename,data in pairs(MARKERS) do
				local token = DB.getValue(imagenode, nodename, "")
				if (token or "") ~= "" then
					markers[token] = data
				end
			end
		end
	end

	return markers;
end

function getCollapsedMarker(image)
	if image.window then
		local imagenode = image.window.getDatabaseNode();
		if imagenode then
			return  DB.getValue(imagenode, "token_collapsed", "")
		end
	end
end

function getMarkerPosition(nPos)
	if nPos == 0 then
		return "right";
	elseif nPos == 1 then
		return "left";
	elseif nPos == 2 then
		return "top";
	elseif nPos == 3 then
		return "bottom";
	end
end

-- Gets the number of files in a warfare grid
-- Files are orthogonal to ranks
function getNumberOfFiles(image)
	if image.window then
		local imagenode = image.window.getDatabaseNode();
		if imagenode then
			return DB.getValue(imagenode, "files", 5)
		end
	end
end

function getRanksAndUnits(image, sMarkerPos)
	--Debug.chat('getRanksAndUnits');
	local matchAxis, offAxis = getAxis(sMarkerPos);
	if not matchAxis or not offAxis then
		return;
	end

	local markers = getRankMarkers(image);
	local collapsedMarker = getCollapsedMarker(image);

	local ranks = {};
	local units = {};
	local collapsed = {};
	local nBorder = 0;

	for k,v in pairs(image.getTokens()) do
		local prototype = v.getPrototype();
		if markers[prototype] then
			local rank = {};
			rank.rank = markers[prototype].rank;
			rank.faction = markers[prototype].faction;
			rank.x, rank.y = v.getPosition();
			ranks[rank[matchAxis]] = rank;

			-- Set the pixel position of the markers along the axis opposite the direction the tokens stack
			-- This is used to remove cavalry from the exposure checks
			nBorder = rank[offAxis];
		elseif prototype == collapsedMarker then
			-- DON'T get tokens that are on the CT
			if not CombatManager.getCTFromToken(v) then
				local ctoken = {}
				ctoken.x, ctoken.y = v.getPosition()

				-- We are simply tracking how many collapsed tokens there are in any given rank
				collapsed[ctoken[matchAxis]] = (collapsed[ctoken[matchAxis]] or 0) + 1;
			end
		else
			-- Only add CT Node units
			local ctnode = CombatManager.getCTFromToken(v);
			if ActorManagerKw.isUnit(ActorManager.resolveActor(ctnode)) then
				local unit = {};
				unit.x, unit.y = v.getPosition();
				unit.unitfaction = DB.getValue(ctnode, "friendfoe", "string", "foe");
				unit.ctnode = ctnode.getPath();
				table.insert(units, unit);
			end
		end
	end

	-- If there aren't a full set of ranks, return nil
	local i = 0;
	for k,v in pairs(ranks) do
		i = i + 1
	end
	if i < 7 then
		return; 
	end

	-- Calculate which ranks are collapsed based on the collapsed table
	local nFileCount = getNumberOfFiles(image);
	for k,rank in pairs(ranks) do
		if collapsed[k] and collapsed[k] >= nFileCount then
			ranks[k].collapsed = true;
		end
	end

	-- Go through all units and assign them to their ranks
	local finalUnits = {};
	for _, unit in ipairs(units) do
		-- Mark units outside the battlemaps bounds as such (i.e. cavalry)
		if (sMarkerPos == "right" or sMarkerPos == "bottom") and unit[offAxis] < nBorder then
		elseif (sMarkerPos == "left" or sMarkerPos == "top") and unit[offAxis] > nBorder then
		else
			unit.oob = true;
		end

		-- Rank is only nil if a unit is placed between grid spaces
		-- because then it's x position won't match any of the markers.
		local rank = ranks[unit[matchAxis]]
		if rank then
			unit.rank = rank.rank;
			unit.rankfaction = rank.faction;

			if unit.rankfaction ~= unit.unitfaction then
				unit.front = true;
			end
			
			if not finalUnits[unit[matchAxis]] then
				finalUnits[unit[matchAxis]] = {};
			end
			finalUnits[unit[matchAxis]][unit[offAxis]] = unit;
			--table.insert(finalUnits, unit);
		end
	end
	
	return ranks, finalUnits;
end

function setExposed(unit, bExposed)
	local nExposed = 0;
	if bExposed then nExposed = 1; end
	if unit.ctnode then
		DB.setValue(DB.findNode(unit.ctnode), "exposed", "number", nExposed);
	end
end

function checkForExposedUnits(ranks, units, sMarkerPos)
	-- Debug.chat('checkForExposedUnits()');
	for rank,file in pairs(units) do
		for _,unit in pairs(file) do
			local bExposed = isUnitExposed(unit, units, sMarkerPos)
			setExposed(unit, bExposed);
		end
	end
end

function isUnitExposed(unit, units, sMarkerPos)
	local matchAxis, offAxis = getAxis(sMarkerPos);
	if not matchAxis or not offAxis then
		return;
	end

	-- Debug.chat('isUnitExposed', unit);
	-- if the unit is out of bounds, always mark it exposed
	if unit.oob then
		return true;
	end
	-- Unit's in the rear are always exposed
	if unit.rank == "rear" then
		--Debug.chat('unit is in rear');
		return true;
	end
	-- Center and reserve are always protected if a side has a front and rear
	if unit.rank == "center" or unit.rank == "reserve" then
		-- Only check if the unit is in its own side's rank
		if unit.rankfaction == unit.unitfaction then
			if factionHasFrontAndRear(unit.unitfaction, units) then
				--Debug.chat('unit is in center/reserves and there is a front and rear')
				return false;
			end
		end
	end

	local rankPos = unit[matchAxis];
	local bLeft = false;
	local bRight = false;

	for _, checkUnit in pairs(units[rankPos]) do
		-- Unit should ignore checking itself.
		if not checkUnit.oob and unit.ctnode ~= checkUnit.ctnode then
			--Debug.chat('checking against', checkUnit.ctnode);
			--Debug.chat(unit[offAxis], checkUnit[offAxis])
			if checkUnit[offAxis] < unit[offAxis] then
				--Debug.chat('there is a unit to the left')
				bLeft = true;
			elseif checkUnit[offAxis] > unit[offAxis] then
				--Debug.chat('there is a unit to the right');
				bRight = true;
			end
		end
	end
	return not (bLeft and bRight)
end

function factionHasFrontAndRear(faction, units)
	-- Debug.chat('factionHasFrontAndRear()')
	local bFront = false;
	local bRear = false;
	for rank,file in pairs(units) do
		for _,unit in pairs(file) do
			if unit.unitfaction == faction and unit.rankfaction == faction and unit.rank == "rear" then
				bRear = true;
			elseif unit.unitfaction == faction and (unit.rankfaction ~= faction or unit.rank == "vanguard") then
				bFront = true;
			end
		end
	end
	return bFront and bRear;
end

function factionHasRear(faction, units)
	for rank,file in pairs(units) do
		for _,unit in pairs(file) do
			if unit.unitfaction == faction and unit.rankfaction == faction and unit.rank == "rear" then
				return true;
			end
		end
	end
	return false;
end

function factionHasFront(faction, units)
	for rank,file in pairs(units) do
		for _,unit in pairs(file) do
			if unit.unitfaction == faction and unit.rankfaction ~= faction then
				return true;
			end
		end
	end
	return false;
end

function getAxis(sMarkerPos)
	local matchAxis, offAxis;
	if sMarkerPos == "left" or sMarkerPos == "right" then 
		matchAxis = "y";
		offAxis = "x";
	elseif sMarkerPos == "top" or sMarkerPos == "bottom" then 
		matchAxis = "x";
		offAxis = "y" 
	end
	return matchAxis, offAxis;
end

--
-- Handling Collapsed Ranks
-- 

function onNewRound(ctunit)
	--Debug.chat('onNewRound')
	local windowinstance = getImageWindow(ctunit);
	checkForCollapsedRanks(windowinstance);
end

function checkForCollapsedRanks(windowinstance)
	--Debug.chat('checkForCollapsedRanks')
	local sMarkerPos = getImageRankPositionOption(windowinstance);
	if not sMarkerPos then 
		return;
	end

	local image = windowinstance.image;
	if not image then
		return;
	end

	local ranks, units = getRanksAndUnits(image, sMarkerPos);
	if not ranks or not units then
		return;
	end

	for k,v in pairs(ranks) do
		-- If the rank is not marked as collapsed, place tokens so that it gets marked as collapsed
		if not v.collapsed then
			if not units[k] then
				-- Rank has collapsed
				placeCollapsedMarkersOnRank(image, v, sMarkerPos);
				notifyRankCollapsed(v);
			end
		end
	end
end

function placeCollapsedMarkersOnRank(image, rank, sMarkerPos)
	--Debug.chat('placeCollapsedMarkersOnRank', rank)
	local token = getCollapsedMarker(image);
	local nGridSize = image.getGridSize();
	local x = rank.x;
	local y = rank.y;
	local dX = 0
	local dY = 0;

	if sMarkerPos == "right" then
		dX = -nGridSize;
	elseif sMarkerPos == "left" then
		dX = nGridSize;
	elseif sMarkerPos == "top" then
		dY = nGridSize;
	elseif sMarkerPos == "bottom" then
		dY = -nGridSize;
	end

	-- Hardcoded for 5 files. Need to dynamically determine that
	local nFiles = getNumberOfFiles(image)
	for i=1, nFiles do
		x = x + dX;
		y = y + dY;
		image.addToken(token, x, y)
	end
end

function notifyRankCollapsed(rank)
	local sFaction = "unknown"
	if rank.faction == "friend" then
		sFaction = "allied"
	elseif rank.faction == "foe" then
		sFaction = "enemy"
	end

	CharManager.outputUserMessage("message_rank_collapsed", StringManager.capitalize(rank.rank), sFaction);
end