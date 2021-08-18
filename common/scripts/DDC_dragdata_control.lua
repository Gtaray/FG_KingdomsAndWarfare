
--[[
The contents of this file were simply copied from the
Fantasy Grounds XML and Scripting Reference document
then edited to present local variables and expose
functions. The verbiage of the document provides
accurate functionality comments.
]]

local aDragDataDatabaseNode;
local sDragDataDescription;
local sDragDataIcon;
local bDragDataSecret;
local sDragDataType;
local bHotKeysDisabled;
local bRevealDice;

local tShortcuts;

local tSlots;
local nSlotIndex;

function onInit()
--Debug.console("DDC_dragdata_control.lua | onInit() | status=", "arrived");
  -- see the cooments near the DDC_getDatabaseNode() function 
  -- for an explanation as to why the following is necessary
  if getDatabaseNode then
    DDC_getDatabaseNode_default = getDatabaseNode;
  end
  getDatabaseNode = DDC_getDatabaseNode;

  reset();
end

function addSlot()
--[[
  Each slot record is a LUA table with the following fields:
  type: String. Slot type.
  number: Number. Numeric value associated with this slot.
  string: String. Textual value associated with this slot.
  token: String. Token identified associated with this slot. (FROM TESTING IT MAY BE MORE COMPLICATED THAN THIS)
  shortcut: Table. Shortcut associated with this slot. Each shortcut record is a table containing class and recordname string fields.
  dice: Table. Dice associated with this slot. The table contains numerically indexed die resource names.
  metadata: Table. Metadata associated with this slot.
  custom: Object. Custom LUA variable associated with this slot. This information will not be saved for drag objects placed on hot key bar.
]]
  local slot = { };
  slot["type"] = "";
  slot["number"] = 0;
  slot["string"] = "";
  slot["token"] = "";       -- { ["prototype"] = nil, ["instance"] = nil };
  slot["shortcut"] = { };
  slot["dice"] = { };
  slot["metadata"] = nil;
  slot["custom"] = nil;
  local nNewIndex = #tSlots + 1;
  tSlots[nNewIndex] = slot;
end

function addShortcut(sClass, sRecordname)
--Debug.console("DDC_dragdata_control.lua | addShortcut() | status, class, recordname=", "arrived", sClass, sRecordname);
--[[
  Adds a shortcut record to the list of shortcut records for this drag object.
  Parameters
    class   (string)   
      Windowclass to use when opening the shortcut link
    recordname   (string)   
      Data base node identifier to use when opening the shortcut link
]]
  -- don't add it if it is already there
  local bAdd = true;
  for vIndex,vValue in pairs(tShortcuts) do
    if vValue["class"] == sClass then
      if vValue["recordname"] == sRecordname then
        bAdd = false;
        break;
      end
    end
  end
  if bAdd == true then
    local nNewIndex = #tShortcuts + 1;
    local tShortcut = { };
    tShortcut["class"] = sClass;
    tShortcut["recordname"] = sRecordname;
    tShortcuts[nNewIndex] = tShortcut;
  end
--Debug.console("DDC_dragdata_control.lua | addShortcut() | tShortcuts=", tShortcuts);
end

--function createBaseData(sType)
--Debug.console("DDC_dragdata_control.lua | createBaseData() | status=", "NOT SUPPORTED AT THIS TIME");
--[[
  Create a new dragdata object as an inherited base data to the current top level data. Existing base data is destroyed.
  Parameters
    type   (string)   [optional]
      The type applied to the created base dragdata 
  Return values
    (dragdata)
      Returns a dragdata object representing the created base data object.
]]
--  return nil;
--end

function disableHotkeying(bState)
--Debug.console("DDC_dragdata_control.lua | disableHotkeying() | status, value=", "arrived", bState);
--[[
  This function can be used to indicate that the current dragdata can not be dropped
  in the hot key bar. This is useful if the drag contains custom data, or other references 
  that might not be valid across several sessions.
  Parameters
    state   (boolean)   
      A true value to indicate that hotkeying should be disabled, or false to enable hotkeying
]]
  bHotKeysDisabled = bState;
end

function getCustomData()
--Debug.console("DDC_dragdata_control.lua | getCustomData() | status, customdata=", "arrived", tSlots[nSlotIndex]["custom"]);
--[[
  Retrieves the Lua variable stored in the custom data value in the currently active slot in the top level data.
  Return values
    (any)
      A variable stored in the active slot or nil if no custom variable has been set
]]
  return tSlots[nSlotIndex]["custom"];
end

-- the genericcontrol's context, windowinstance, has a getDatabaseNode()
-- function which cannot be simply overriden with a getDatabaseNode() here,
-- instead the ubiquitous "renaming" methodology is employed (see onInit)
function DDC_getDatabaseNode()
--Debug.console("DDC_dragdata_control.lua | getDatabaseNode() | status, node=", "arrived", aDragDataDatabaseNode);
--[[
  Get the database node associated with the dragdata object.
  The database node returned will either be last value set by setDatabaseNode 
  or setShortcutData (even though setShortcutData is set by slot).
  Return values
    (databasenode)
      A databasenode object
]]
  return aDragDataDatabaseNode;
end

function getDescription()
--Debug.console("DDC_dragdata_control.lua | getDescription() | status, description=", "arrived", sDragDataDescription);
--[[
  Retrieve the description for the entire drag item.
  Return values
    (string)
      The description string
]]
  return sDragDataDescription;
end

function getDieList()
--Debug.console("DDC_dragdata_control.lua | getDieList() | status, dice=", "arrived", tSlots[nSlotIndex]["dice"]);
--[[
  Get the list of dice in the currently active slot in the top level data. 
  The result is an integer indexed table of table values specifying the data 
  related to the dice. The subtable will contain the field type that is a 
  string identifying the type of die, and a field named result containing the 
  numeric result of the die roll if the dice have already been rolled.
  Return values
    (table)
      An integer indexed table of data containing the die types and possibly results
]]
  return tSlots[nSlotIndex]["dice"];
end

function getMetaData(sKey)
--Debug.console("DDC_dragdata_control.lua | getMetaData() | status, key, metadata=", "arrived", sKey, tSlots[nSlotIndex]["metadata"][sKey]);
--[[
  Returns the requested meta data attribute from the current slot.
  Parameters
    key   (string)   
      Meta data key
  Return values
    (string)
      Meta data value stored under the specified key
]]
  if tSlots[nSlotIndex]["metadata"] == nil then
    return nil;
  else
    return tSlots[nSlotIndex]["metadata"][sKey];
  end
end

function getMetaDataList()
--Debug.console("DDC_dragdata_control.lua | getMetaDataList() | status=", "arrived");
--[[
  UNDOCUMENTED in XML and Scripting Reference as of March 19, 2019
]]
  local tList = { };
  for nIndex,vValue in pairs(tSlots) do
    local tMetadata = vValue["metadata"];
    if tMetadata ~= nil then
      tList[nIndex] = tMetadata;
    end
  end
  return tList;
end

function getNumberData()
--Debug.console("DDC_dragdata_control.lua | getNumberData() | status, number=", "arrived", tSlots[nSlotIndex]["number"]);
--[[
  Retrieves the number value in the currently active slot in the top level data.
  Return values
    (number)
      Returns the number value
]]
  return tSlots[nSlotIndex]["number"];
end

function getSecret()
--Debug.console("DDC_dragdata_control.lua | getSecret() | status, secret=", "arrived", bDragDataSecret);
--[[
  Returns whether the secret flag is set on the drag object. By default, objects dragged onto the chat window will only show locally if this flag set.
  Return values
    (string)
      Returns true if the secret flag is set for this drag object; otherwise, returns false.
]]
  return bDragDataSecret;
end

function getShortcutData()
--Debug.console("DDC_dragdata_control.lua | getShortcutData() | status=", "arrived", tSlots[nSlotIndex]["class"], tSlots[nSlotIndex]["recordname"]);
--[[
  Retrieves the shortcut value in the currently active slot in the top level data.
  Return values
    (string)
      The windowclass for the shortcut data or nil if no shortcut has been specified
    (string)
      The database node identifier for the shortcut target or nil if no shortcut has been specified
]]
  return tSlots[nSlotIndex]["shortcut"]["class"], tSlots[nSlotIndex]["shortcut"]["recordname"];
end

function getShortcutList()
--Debug.console("DDC_dragdata_control.lua | getShortcutList() | status, shortcuts=", "arrived", tShortcuts);
--[[
  Returns the list of shortcut records stored for this drag object.
  Return values
    (table)
      Table of shortcut records, where each record is a table with 2 values stored under class and recordname keys.
]]
  return tShortcuts;
end

function getSlot()
--Debug.console("DDC_dragdata_control.lua | getSlot() | status, index=", "arrived", nSlotIndex);
--[[
  Get the currently active slot's index number.
  Return values
    (number)
      The current index slot in the range 1 .. (number of slots)
]]
  return nSlotIndex;
end

function getSlotCount()
--Debug.console("DDC_dragdata_control.lua | getSlotCount() | status, count=", "arrived", #tSlots);
--[[
  Get the number of slots in the dragdata object
  Return values
    (number)
      The number of slots
]]
  return #tSlots;
end

function getSlotType()
--Debug.console("DDC_dragdata_control.lua | getSlotType() | status, type=", "arrived", tSlots[nSlotIndex]["type"]);
--[[
  Returns the type attribute of the current slot.
  Return values
    (string)
      The string specifying the slot type
]]
  return tSlots[nSlotIndex]["type"];
end

function getStringData()
--Debug.console("DDC_dragdata_control.lua | getStringData() | status=", "arrived", tSlots[nSlotIndex]["string"]);
--[[
  Retrieves the string value in the currently active slot in the top level data.
  Return values
    (string)
      Returns the string value
]]
  return tSlots[nSlotIndex]["string"];
end

function getTokenData()
--Debug.console("DDC_dragdata_control.lua | getTokendata() | status=", "arrived", tSlots[nSlotIndex]["token"]);
--[[
  Retrieves the value of the token prototype identifier string in the currently active slot in the top level data.
  Return values
    (any)
      The string identifying the token prototype, or nil if no token is contained in the data
]]
  return tSlots[nSlotIndex]["token"];
end

function getType()
--Debug.console("DDC_dragdata_control.lua | getType() | status=", "arrived");
--[[
  Returns the type string of the current top level data without performing checks on the inheritance chain.
  Return values
    (string)
      The string specifying the data type
]]
  return sDragDataType;
end

function isType(sType)
--Debug.console("DDC_dragdata_control.lua | isType() | status=", "arrived");
--[[
  Check the inheritance chain for matching types to the type given as a parameter, 
  starting at the current top level data. If a match is found, the match is set as 
  the current top level data.
  Parameters
    type   (string)   
      The type being sought
  Return values
    (boolean)
      If a match is found, returns true, otherwise returns false.
]]
  local bReturn = false;
  if sDragDataType == sType then
    bReturn = true;
  end
  return bReturn;
end

function nextSlot()
--Debug.console("DDC_dragdata_control.lua | nextSlot() | status=", "arrived");
--[[
  Increments the slot counter by one, if there are more slots available.
  Return values
    (boolean)
      Returns true if successful, or false if the operation fails because the current slot is the last one
]]
  local bReturn = false;
  if nSlotIndex < #tSlots then
    nSlotIndex = nSlotIndex + 1;
    bReturn = true;
  end
  return bReturn;
end

function reset()
--Debug.console("DDC_dragdata_control.lua | reset() | status=", "arrived");
--[[
  Delete and reset all properties of the drag data item. 
  The type field must be set after this operation for the object to represent valid drag contents.
]]
  aDragDataDatabaseNode = nil;
  sDragDataDescription = "User defined, user created pseudo dragdata object."
  sDragDataIcon = "";
  bDragDataSecret = false;
  sDragDataType = "none";
  bHotKeysDisabled = false;
  bRevealDice = false;

  tShortcuts = { };

  tSlots = { };
  addSlot();
  nSlotIndex = #tSlots;
end

function resetType()
--Debug.console("DDC_dragdata_control.lua | resetType() | status=", "arrived");
--[[
  Set the highest level data as the current top level element.
]]
  sDragDataType = "none";
end

function revealDice(bBtate)
--Debug.console("DDC_dragdata_control.lua | revealDice() | status, value=", "arrived", bState);
--[[
  This function can be used to indicate that GM rolls, which are by default hidden, 
  should be displayed directly to clients. This function has no effect if the drag 
  does not contain dice or does not cause a roll of the dice.
  Parameters
    state   (boolean)   
      A value of true to reveal the dice, or false to make a hidden roll
]]
  bRevealDice = bState;
end

function setCustomData(aVariable)
--Debug.console("DDC_dragdata_control.lua | setCustomData() | status, value=", "arrived", aVariable);
--[[
  Sets an arbitrary Lua variable into the custom data value in the currently active slot in the top level data.
  Parameters
    variable   (any)   
      Any variable
]]
  tSlots[nSlotIndex]["custom"] = aVariable;
end

--function setData(tDragRecord)
--Debug.console("DDC_dragdata_control.lua | setData() | status=", "NOT SUPPORTED AT THIS TIME");
--[[
  Set the drag object to the attributes specified in the drag record.
  Parameters
    dragrecord   (table)   
      See dragdata description for details on the drag record structure.
]]
--end

function setDatabaseNode(aNode)
--Debug.console("DDC_dragdata_control.lua | setDatabaseNode() | status, node=", "arrived", aNode);
--[[
  Set a database node to be associated with the dragdata object.
  Parameters
    node   (databasenode)   
      A databasenode object
  OR
    nodename   (string)   
      A data mode identifier
]]
  if type(aNode) == "string" then
    -- the following is from 5E CharManager.resolveRefNode()
    local nodeSource = DB.findNode(aNode);
    if not nodeSource then
      local sRecordSansModule = StringManager.split(aNode, "@")[1];
      nodeSource = DB.findNode(sRecordSansModule .. "@*");
      if not nodeSource then
        Debug.console("DDC_dragdata_control.lua | setDatabaseNode() | status=", "Failed to resolve path: ", aNode);
      end
    end
    aDragDataDatabaseNode = nodeSource;
  else
    aDragDataDatabaseNode = aNode;
  end
end

function setDescription(sDescription)
--Debug.console("DDC_dragdata_control.lua | setDescription() | status, description=", "arrived", sDescription);
--[[
  Set the string used as a label for the entire drag item. This data is shared between all slots in the object.
  Parameters
    description   (string)   
      The description string
]]
  sDragDataDescription = sDescription;
end

function setDieList(tDieList)
--Debug.console("DDC_dragdata_control.lua | setDieList() | status, dice=", "arrived", tDieList);
--[[
  Set the list of dice in the currently active slot in the top level data. 
  The existing dice in the slot will be removed and the set of held dice in all slots will be rebuilt.
  Parameters
    dielist   (table)   
      An integer indexed table of strings listing the types of the dice to be added to the slot.
]]
  tSlots[nSlotIndex]["dice"] = tDieList;
end

function setIcon(sIcon)
--Debug.console("DDC_dragdata_control.lua | setIcon() | status, icon=", "arrived", sIcon);
--[[
  Set the name of the icon resource used to render a graphic at the mouse cursor while the drag is taking place.
  Parameters
    icon   (string)   
      The name of an icon resource used for the icon
]]
  sDragDataIcon = sIcon;
end

function setMetaData(sKey, sValue)
--Debug.console("DDC_dragdata_control.lua | setMetaData() | status, key, value=", "arrived", sKey, sValue);
--[[
  Sets the given meta data attribute in the current slot.
  Parameters
    key   (string)   
      Meta data key
    value   (string)   
      Meta data value
]]
  if tSlots[nSlotIndex]["metadata"] == nil then
    tSlots[nSlotIndex]["metadata"] = { };
  end
  tSlots[nSlotIndex]["metadata"][sKey] = sValue;
end

function setNumberData(nValue)
--Debug.console("DDC_dragdata_control.lua | setNumberData() | status, value=", "arrived", nValue);
--[[
  Sets the number value in the currently active slot in the top level data.
  Parameters
    value   (number)   
      The desired number value
]]
  tSlots[nSlotIndex]["number"] = nValue;
end

function setSecret(bValue)
--Debug.console("DDC_dragdata_control.lua | setSecret() | status, value=", "arrived", bValue);
--[[
  Specifies whether the secret flag is set on the drag object. 
  By default, objects dragged onto the chat window will only show locally if this flag set.
  Parameters
    value   (boolean)   
      Set to true to mark the drag data as secret; otherwise, set to false.
]]
  bDragDataSecret = bValue;
end

function setShortcutData(sClass, sRecordname)
--Debug.console("DDC_dragdata_control.lua | setShortcutData() | status, class, recordname=", "arrived", sClass, sRecordname);
--[[
  Sets the shortcut value in the currently active slot in the top level data. 
  The value consists of a windowclass name and an absolute database node identifier.
  Parameters
    class   (string)   
      The name of the windowclass resource used as a target of the shortcut
    recordname   (string)   
      The database node identifier used to construct the target data source
]]
  local tShortcut = { };
  tShortcut["class"] = sClass;
  tShortcut["recordname"] = sRecordname;
  tSlots[nSlotIndex]["shortcut"] = tShortcut;
  -- also add it to the "higher level" shortcut list
  -- testing does not indicate that the following is correct behavior
--  addShortcut(sClass, sRecordname);
  -- and make this the most current node
  local sPath = DB.getPath(sRecordname) 
  if setDatabaseNode then setDatabaseNode(sPath); end;
end

function setSlot(nIndex)
--Debug.console("DDC_dragdata_control.lua | setSlot() | status, index=", "arrived", nIndex);
--[[
  Set the slot counter to the specified index. 
  The index can be any positive integer, if it is smaller than the largest 
  slot index, the number of slots is adjusted to match the given index.
  Parameters
    index   (number)   
      The new slot index
  Return values
    (boolean)
      Returns true if successful, or false if the operation fails because the specified slot index is less than 1
]]
  local bReturn = false;
  if nIndex > 0 then
    while true do
      if nIndex <= #tSlots then break; end;
      addSlot();
    end
    nSlotIndex = nIndex;
    bReturn = true;
  end
--Debug.console("DDC_dragdata_control.lua | setSlot() | tSlots=", tSlots);
  return bReturn;
end

function setSlotType(sType)
--Debug.console("DDC_dragdata_control.lua | setSlotType() | status, type=", "arrived", sType);
--[[
  Sets the type attribute of the current slot.
  Parameters
    type   (string)   
      The new value used as the type of the current slot
]]
  tSlots[nSlotIndex]["type"] = sType;
end

function setStringData(sValue)
--Debug.console("DDC_dragdata_control.lua | setStringData() | status, value=", "arrived", sValue);
--[[
  Sets the string value in the currently active slot in the top level data.
  Parameters
    value   (string)   
      The desired string value
]]
  tSlots[nSlotIndex]["string"] = sValue;
end

function setTokenData(sPrototypeName)
--Debug.console("DDC_dragdata_control.lua | setTok--endata() | status, prototypename=", "arrived", sPrototypeName);
--[[
  Sets the token prototype identifier string value in the currently active slot in the top level data.
  Only strings obtained through secondary token sources (such as other tokencontrol instances 
  or token containers) should be used as the parameter.
  Parameters
    prototypename   (string)   
      The string identifying the token prototype to add to the data
]]
  tSlots[nSlotIndex]["token"] = sPrototypeName;
end

function setType(sType)
--Debug.console("DDC_dragdata_control.lua | setType() | status, type=", "arrived", sType);
--[[
  Set the type string.
  Parameters
    type   (string)   
      The new value used as the type of the object
]]
  sDragDataType = sType;
end
