-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ancestry lookup data
-- Used to map the various unit ancestries to single categories
ancestrydata = {
    ["human"] = "human",
    ["dwarf"] = "dwarf",
    ["elf"] = "elf",
    ["orc"] = "orc",
    ["goblin"] = "goblinoid",
    ["hobgoblin"] = "goblinoid",
    ["bugbear"] = "goblinoid",
    ["zombie"] = "undead",
    ["skeleton"] = "undead",
    ["ghoul"] = "undead",
    ["wight"] = "undead",
    ["wraith"] = "undead",
}

-- Trait lookup data
-- Commented entries aren't possible with current mechanics. Need to add new effects handling for them to work
traitdata = {
    -- UNIT TRAITS
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
    -- MARTIAL ADVANTAGES
    --["furious assault"] = "DMG: 1 attack",
    ["berserkers"] = "AUTOPASS: diminished; IF: diminished; ADVTEST: power",
    ["song of battles won"] = "IFT: stronger; GRANTDISATK",
    --["exorcizers"] = "IFT: ANCESTRY(undead, fiend); AUTOPASS: attack; DMG: 1 attack",
    ["focused resolve"] = "ADVTEST: battle magic",
    ["cavaliers"] = "ADVTEST: attack; DMG: 1",
    --["hell's hammer"] = "IFT: ANCESTRY(undead, fiend); ADVTEST: power",
    ["archery training"] = "ADVTEST: power",
    ["rough terrain training"] = "IMMUNE: disorganized",
    ["sorcerous training"] = "ADVTEST: battle magic"
}

-- Martial Advantage look up data 
-- Used on the PC sheet actions tab for drag/dropping martial advantages
-- TODO: Mark these effects as battle magic
martialadvantages = {
    ["troops of fame and great renown"] = {
        { type = "unitsavedc", save = "morale" },
        { type = "damage", clauses = { { dice = {}, modifier = 1 } } },
    },
    ["scroll of mass hypnosis"] = { 
        { type = "unitsavedc", save = "command" },
        { type = "effect", sName = "disorganized", nDuration = 1 }
    },
    ["scroll of omund's trumpet"] = {
        { type = "effect", sName = "ADVTEST: attack, power", nDuration = 1 }
    },
    ["impassioned speech"] = {
        { type = "rally", dc = 12 },
        { type = "heal", clauses = { { dice = { "1d4" }, modifier = 1 } } }
    },
    ["divine rally"] = {
        { type = "rally", dc = 13 },
        { type = "heal", clauses = { { dice = { "1d4" } } } },
        { type = "effect", sName = "DEF: 2; TOU: 2" }
    },
    ["wand of healing"] = {
        { type = "heal", clauses = { { dice = { "1d4" } } } },
    },
    ["scroll of mass healing"] = {
        { type = "heal", clauses = { { dice = { }, modifier = 4 } } },
    },
    ["wand of grasping root"] = {
        { type = "unitsavedc", save = "power" },
        { type = "effect", sName = "disoriented", nDuration = 1 }
    },
    ["scroll of torrential rain"] = {
        { type = "effect", sName = "DISTEST: attack", nDuration = 1 }
    },
    ["bark and root"] = {
        { type = "heal", clauses = { { dice = { }, modifier = 1 } } },
    },
    ["scroll of storms"] = {
        { type = "unitsavedc", save = "power" },
        { type = "damage", clauses = { { dice = {}, modifier = 2 } } },
    },
    ["martial rally"] = {
        { type = "rally", dc = 13 },
        { type = "heal", clauses = { { dice = { "1d4" } } } },
    },
    ["field promotion"] = {
        { type = "effect", sName = "ATK: 2; POW: 2; MOR: 2: COM: 2;", nDuration = 0 }
    },
    ["death commandos"] = {
        { type = "unitsavedc", save = "morale" },
        { type = "damage", clauses = { { dice = {}, modifier = 1 } } },
    },
    ["infernal rally"] = {
        { type = "rally", dc = 13 },
        { type = "heal", clauses = { { dice = { "1d4" } } } },
        { type = "effect", sName = "+1 attack; +1 movement; ADVTEST: attack, power; DMGO: 1" }
    },
    ["scroll of hellfire"] = {
        { type = "unitsavedc", save = "power" },
        { type = "effect", sName = "FIRE", nDuration = 4 },
        { type = "effect", sName = "FIRE", nDuration = 2 },
    },
    ["execution"] = {
        { type = "effect", sName = "ADVTEST: attack, power", },
    },
    ["hidden reserve"] = {
        { type = "heal", clauses = { { dice = { "1d4" } } } },
    },
    ["like water"] = {
        { type = "damage", clauses = { { dice = {}, modifier = 1 } } },
    },
    ["mine over body"] = {
        { type = "effect", sName = "Power tests against this unit fail", nDuration = 1 },
    },
    ["righteous"] = {
        { type = "effect", sName = "ADVTEST: attack", nDuration = 1, sApply = "action" },
    },
    ["templar's rally"] = {
        { type = "rally", dc = 13 },
        { type = "heal", clauses = { { dice = { "1d4" } } } },
        { type = "effect", sName = "ATK: 2; POW: 2" }
    },
    ["scroll of clarity"] = {
        { type = "heal", clauses = { { dice = { "1d4" } } } },
    },
    ["scroll of templar's blessing"] = {
        { type = "effect", sName = "AUTOPASS: command; +1 attack" }
    },
    ["pin them down"] = {
        { type = "effect", sName = "-1 movement" }
    }
}