-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Trait lookup data
-- Commented entries aren't possible with current mechanics. Need to add new effects handling for them to work
traitdata = {
    ["adaptable"] = "ADVTEST: morale, command",
    ["arcadian"] = "ADVTEST: battle magic",
    ["armored carapace"] = "IFT: TYPE(artillery); IMMUNE: attack",
    ["chaos vulnerability"] = "DISTEST: battle magic",
    ["cloud of darkness"] = "GRANTDISATK",
    ["damage resistant"] = "IMMUNE: attack",
    ["dead"] = "AUTOPASS: morale; IMMUNE: diminished",
    ["dire hyena mounts"] = "IFT: diminished; ADVTEST: attack",
    ["draconic ancestry"] = "IMMUNE: disorganized, weakened; Fearless",
    ["dragonkin"] = "ADVTEST: attack, command, morale",
    ["eternal"] = "ADVTEST: harrowing",
    ["fearless"] = "AUTOPASS: morale",
    ["hard hats"] = "IFT: TYPE(aerial); DEF: 2",
    --["holy"] = "IFT: ANCESTRY(undead, fiend); GRANTDISATK; GRANTDISPOW",
    ["magic resistant"] = "ADVTEST: battle magic",
    ["regenerate"] = "REGEN: 1",
    ["resolute"] = "AUTOPASS: morale",
    --["scourge of the wild"] = "IFT: ANCESTRY(orc, goblinoid, elf); ATK: 2; POW: 2",
    ["stalwart"] = "IF: diminished; IFT: TYPE(infantry, cavalry); GRANTDISPOW",
}