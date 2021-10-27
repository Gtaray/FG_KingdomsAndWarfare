-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--


local fSetCurrentValue;
local fSetCurrNode;

local sCurrNodeName;

function onInit()
	fSetCurrentValue = super.setCurrentValue;
	super.setCurrentValue = setCurrentValue;
	
	fSetCurrNode = super.setCurrNode;
	super.setCurrNode = setCurrNode;

	super.onInit();
end

function setCurrentValue(nCount)
	DomainManager.notifyDomainDevelopment(sCurrNodeName, nCount);
end

function setCurrNode(sNewCurrNodeName)
	sCurrNodeName = sNewCurrNodeName;
	fSetCurrNode(sNewCurrNodeName);
end