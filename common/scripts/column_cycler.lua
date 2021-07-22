-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
    if super and super.onInit then
		super.onInit();
	end
    
	if isReadOnly() then
		self.update(true);
	else
		local node = getDatabaseNode();
		if not node or node.isReadOnly() then
			self.update(true);
		end
	end
end

function update(bReadOnly, bForceHide)
	local bLocalShow;
	if bForceHide then
		bLocalShow = false;
	else
		bLocalShow = true;
	end
	
	setReadOnly(bReadOnly);
	setVisible(bLocalShow);
	
	local sLabel = getName() .. "_label";
	if window[sLabel] then
		window[sLabel].setVisible(bLocalShow);
	end
	if separator then
		if window[separator[1]] then
			window[separator[1]].setVisible(bLocalShow);
		end
	end
	
	if self.onVisUpdate then
		self.onVisUpdate(bLocalShow, bReadOnly);
	end
	
	return bLocalShow;
end

function onVisUpdate(bLocalShow, bReadOnly)
	if bReadOnly then
		setFrame(nil);
	else
		setFrame("fielddark", 7,5,7,5);
	end
end
