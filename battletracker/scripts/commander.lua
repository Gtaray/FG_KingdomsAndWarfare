-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	local node = getDatabaseNode();
	DB.addHandler(CombatManager.CT_LIST .. ".*.commander_link", "onUpdate", commanderUpdated);
	DB.addHandler(node.getPath("friendfoe"), "onUpdate", onFactionUpdated);
	DB.addHandler(node.getPath("active"), "onUpdate", updateDisplay);
	DB.addHandler(node.getPath(), "onDelete", onDelete);

	updateDisplay();
	
	-- Initialize color
	if node then
		local rActor = ActorManager.resolveActor(node);
		if rActor and ActorManager.isPC(rActor) then
			local nodeCreature = ActorManager.getCreatureNode(rActor);
			if nodeCreature then
				local sCreatureIdentity = nodeCreature.getName();

				-- Check if the Pc is curerntly activated. If not, getIdentityColor will return black
				if StringManager.isWord(sCreatureIdentity, User.getAllActiveIdentities()) then
					local sColor = User.getIdentityColor(sCreatureIdentity);
					color_swatch.setColor(sColor);
				end
			end
		end
	end
end

function onClose()
	local node = getDatabaseNode();
	DB.removeHandler(CombatManager.CT_LIST .. ".*.commander_link", "onUpdate", commanderUpdated);
	DB.removeHandler(node.getPath("friendfoe"), "onUpdate", onFactionUpdated);
	DB.removeHandler(node.getPath("active"), "onUpdate", updateDisplay);
	DB.removeHandler(node.getPath(), "onDelete", onDelete);
end

-- Listen to its own delete event so it can neatly delete all of its units. Could also have the units set their commanders to nil.
function onDelete(nodeCommander)
	for k,window in pairs(list.getWindows()) do
		local node = window.getDatabaseNode();
		if node then
			node.delete();
		end
	end
end

-- this function is necessary because the link_ctentry template calls window.onLinkChanged()
function onLinkChanged()
	if link then
		commanderUpdated(link.getDatabaseNode())
	end
end

function commanderUpdated(nodeLink)
	if nodeLink then
		local sClass, sRecord = nodeLink.getValue();
		if sRecord == getDatabaseNode().getPath() then
			list.createWindow(DB.getChild(nodeLink, ".."));
		end
	end
end

function onFactionUpdated(nodeUpdated)
	local sFaction = nodeUpdated.getValue();
	for k,v in pairs(list.getWindows()) do
		local windownode = v.getDatabaseNode();
		if windownode then
			DB.setValue(windownode, "friendfoe", "string", sFaction);
		end
	end
	updateDisplay();
end

function updateDisplay()
	local sFaction = DB.getValue(getDatabaseNode(), "friendfoe", "");

	local sFrame = "";
	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then		
		if sFaction == "friend" then
			sFrame = "ctentrybox_friend_active";
		elseif sFaction == "neutral" then
			sFrame = "ctentrybox_neutral_active";
		elseif sFaction == "foe" then
			sFrame = "ctentrybox_foe_active";
		else
			sFrame = "ctentrybox_active";
		end
	else		
		if sFaction == "friend" then
			sFrame = "ctentrybox_friend";
		elseif sFaction == "neutral" then
			sFrame = "ctentrybox_neutral";
		elseif sFaction == "foe" then
			sFrame = "ctentrybox_foe";
		else
			sFrame = "ctentrybox";
		end
	end

	if sFrame ~= "" then
		setFrame(sFrame);
	end
end

function onUnitListChanged()
	local sColor = color_swatch.getColor();
	setColor(sColor);
end

function setColor(sColor)
	if Session.IsHost then
		for _,winUnit in ipairs(list.getWindows()) do
			DB.setValue(winUnit.getDatabaseNode(), "color", "string", sColor); -- Let the TokenManager do the coloration work.
		end
	end
end

function onDrop(x, y, draginfo)
	local sType = draginfo.getType();
	local sClass, sRecord = draginfo.getShortcutData();
	if sType == "battletrackerunit" then
		local sPath = getDatabaseNode().getPath();
		local node = draginfo.getDatabaseNode();
		local _,sCommander = DB.getValue(node, "commander_link");
		if sCommander ~= sPath then
			DB.setValue(node, "commander_link", "windowreference", "npc", sPath);
		end
		return true;
	elseif sClass == "reference_unit" then
		CombatManagerKw.setUnitDropCommander(getDatabaseNode());
		return CampaignDataManager.handleDrop("combattracker", draginfo);
	end
end