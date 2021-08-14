-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fPerformVsRoll;
function onInit()
    fPerformVsRoll = ActionSave.performVsRoll;
    ActionSave.performVsRoll = performVsRoll;
end

-- Override this to add a small check for a new effect: SAVEDC
function performVsRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc)
    local nTotal, nEffectCount = EffectManager5E.getEffectsBonus(rSource, "SAVEDC", true, {}, rActor, false)
    if nEffectCount > 0 then
        nTargetDC = nTargetDC + nTotal;
    end
    fPerformVsRoll(draginfo, rActor, sSave, nTargetDC, bSecretRoll, rSource, bRemoveOnMiss, sSaveDesc);
end