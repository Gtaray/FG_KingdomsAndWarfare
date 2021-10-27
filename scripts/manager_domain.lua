-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
OOB_MSGTYPE_DOMAIN_DEVELOPMENT = "domaindevelopment";

function onInit()
	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DOMAIN_DEVELOPMENT, handleDevelopment);

		-- We have to watch the link here (instead of using onChildAdded on the list node)
		-- Because the link is updated after the child is added, and the link is how we get the owner
		-- Of the character sheet node.
		DB.addHandler("partysheet.partyinformation.*.link", "onUpdate", onOfficerAdded);

		-- Handle assigning prof and reaction checkboxes on the public party sheet
		if UtilityManager.isClientFGU() then
			User.onIdentityActivation = onIdentityActivation;
		end
	end
end

function onClose()
	if Session.IsHost then
		DB.removeHandler("partysheet.partyinformation.*.link", "onUpdate", onOfficerAdded);
	end
end

function notifyDomainDevelopment(sPath, nCount)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_DOMAIN_DEVELOPMENT;
	msgOOB.sCount = tostring(nCount);
	msgOOB.sPath = sPath;

	if Session.IsHost then
		handleDevelopment(msgOOB);
	else
		Comm.deliverOOBMessage(msgOOB, "")
	end
end

function handleDevelopment(msgOOB)
	local nCount = tonumber(msgOOB.sCount);
	DB.setValue(msgOOB.sPath, "number", nCount);
end

function onOfficerAdded(nodeLink)
	-- If for some reason a client makes it here, bail
	if not Session.IsHost then
		return;
	end

	local sClass, sRecord = nodeLink.getValue();
	if sClass == "charsheet" and sRecord then
		local nodePC = DB.findNode(sRecord);
		local sOwner = nodePC.getOwner();
		if sOwner ~= "" then
			setPartySheetOwner(DB.getChild(nodeLink, ".."), sOwner);
		end
	end
end

function onIdentityActivation(sIdentity, sUser, bActivated)
	local vPartySheetNode = getPartySheetEntry(sIdentity);
	if not vPartySheetNode then
		return;
	end

	if bActivated then
		setPartySheetOwner(vPartySheetNode, sUser);
	else
		clearPartySheetOwner(vPartySheetNode);
	end
end

function setPartySheetOwner(vNode, sUser)
	local profnode = DB.createChild(vNode, "proficiencyused", "number");
	if profnode then
		DB.setOwner(profnode, sUser);
	end
	local reactnode = DB.createChild(vNode, "reactionused", "number");
	if reactnode then
		DB.setOwner(reactnode, sUser);
	end
end

function clearPartySheetOwner(vNode)
	local profnode = DB.createChild(vNode, "proficiencyused", "number");
	if profnode then
		DB.setOwner(profnode, nil);
	end
	local reactnode = DB.createChild(vNode, "reactionused", "number");
	if reactnode then
		DB.setOwner(reactnode, nil);
	end
end

function getPartySheetEntry(sIdentity)
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local identity = sRecord:match("charsheet.(.+)")
			if identity == sIdentity then
				return v;
			end
		end
	end
end