-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function addEntry(bFocus, nVal)
	if User.isHost() then
		local bReadOnly = window.powerpool_iedit.getValue() == 0;
		local domainNode = DB.getChild(getDatabaseNode(), "..");
		local domainsize = DB.getValue(domainNode, "domainsize", 1);
		local w = createWindow();

		local powerdie = "d4";
		if domainsize == 2 then powerdie = "d6"
		elseif domainsize == 3 then powerdie = "d8"
		elseif domainsize == 4 then powerdie = "d10"
		elseif domainsize == 5 then powerdie = "d12"
		end

		if bFocus then
			w.value.setFocus();
		end
		if nVal then
			w.value.setValue(nVal);
		end
		w.die.setDice({ powerdie });
		w.value.setReadOnly(bReadOnly);

		local sEdit = getName() .. "_iedit";
		if window[sEdit] then
			w.idelete.setVisibility(not bReadOnly);
		end
		return w;
	else
		-- This case is when a player adds a die
		-- Need to send out a msg so the host adds the item
		PowerPoolManager.AddDieToPool(nVal, window.getDatabaseNode());
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "number" then
		-- Focus set to false since there's number data. No need to focus to enter data
		local w = addEntry(false, draginfo.getNumberData());
		return true;
	elseif sDragType == "dice" then
		local rAction = {}
		rAction.add = true;
		rAction.aDice = draginfo.getDieList();
		rAction.nMod = 0;
		rAction.domainNode = window.getDatabaseNode();
		ActionPowerDie.performRoll(nil, nil, rAction);
		return true;
	end
end

function update()
	local sEdit = getName() .. "_iedit";
	if window[sEdit] then
		local bEdit = (window[sEdit].getValue() == 1);
		for _,wAttribute in ipairs(getWindows()) do
			wAttribute.idelete.setVisibility(bEdit);
			wAttribute.value.setReadOnly(not bEdit);
		end
	end						
end