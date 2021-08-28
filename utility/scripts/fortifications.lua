-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	end
end

function onMenuSelection(selection)
	if selection == 5 then
		addEntry();
	end
end
function onClickDown(button, x, y)
	if Session.IsHost then
		return true;
	end
end
function onClickRelease(button, x, y)
	if Session.IsHost then
		if getWindowCount() == 0 then
			addEntry();
		end
		return true;
	end
end
function onDrop(x, y, draginfo)
	if Session.IsHost then
		local rEffect = EffectManager.decodeEffectFromDrag(draginfo);
		if rEffect then
			local node = addEntry();
			if node then
				EffectManager.setEffect(node, rEffect);
			end
		end
		return true;
	end
end
function onListChanged()
	update();
end

function addEntry()
	local w = createWindow();

	local sEdit = getName() .. "_iedit";
	window[sEdit].setValue(1);
	return node;
end
function update()
	local sEdit = getName() .. "_iedit";
	if window[sEdit] then
		local bEdit = (window[sEdit].getValue() == 1);
		for _,w in ipairs(getWindows()) do
			w.idelete.setVisibility(bEdit);
			w.name.setReadOnly(not bEdit)
			w.morale.setReadOnly(not bEdit)
			w.defense.setReadOnly(not bEdit)
			w.power.setReadOnly(not bEdit)
		end
	end
end
