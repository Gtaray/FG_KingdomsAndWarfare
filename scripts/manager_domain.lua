-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_DOMAIN_DEVELOPMENT = "domaindevelopment";

function onInit()
	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DOMAIN_DEVELOPMENT, handleDevelopment);
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