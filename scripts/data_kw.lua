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
    ["big"] = "IFT: weaker; ADVTEST: power",
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
    ["holy"] = "IFT: ANCESTRY(undead, fiend); GRANTDISATK; GRANTDISPOW",
    ["magic resistant"] = "ADVTEST: battle magic",
    ["regenerate"] = "REGEN: 1",
    ["resolute"] = "AUTOPASS: morale",
    ["scourge of the wild"] = "IFT: ANCESTRY(orc, goblinoid, elf); ATK: 2; POW: 2",
    ["stalwart"] = "IF: diminished; IFT: TYPE(infantry, cavalry); GRANTDISPOW",
    -- MARTIAL ADVANTAGES
    ["furious assault"] = "ATKDMG: 1",
    ["berserkers"] = "AUTOPASS: diminished; IF: diminished; ADVTEST: power",
    ["song of battles won"] = "IFT: stronger; GRANTDISATK",
    ["exorcizers"] = "IFT: ANCESTRY(undead, fiend); AUTOPASS: attack; ATKDMG: 1",
    ["focused resolve"] = "ADVTEST: battle magic",
    ["cavaliers"] = "ADVTEST: attack; DMG: 1",
    ["hell's hammer"] = "IFT: ANCESTRY(undead, fiend); ADVTEST: power",
    ["archery training"] = "ADVTEST: power",
    ["rough terrain training"] = "IMMUNE: disorganized",
    ["sorcerous training"] = "ADVTEST: battle magic",
    ["righteous"] = "GRANTDISDIM"
}

-- Should go through here and add sTargeting = "self" to most of the effects, since they're supposed to be self only
domainpowers = {
    -- Adventuring Parties
    -- This one will probably never be an effect since it can be applied after the roll is made
    --["never tell me the odds"] = { type = "effect", sName = "SAVEDC: 2x PDIE", nDuration = 1, sApply = "single" },
    ["avenge me"] = {
        { type = "effect", sName = "AURA: 30 friend; DMG: PDIE", nDuration = 0 }
    },
    ["fighting dirty"] = {
        { type = "effect", sName = "ATK: -PDIE; DMG: 5x PDIE", nDuration = 1, sApply = "single" }
    },
    -- Martial Regiment
    ["brute force"] = { 
        { type = "effect", sName = "ATK: PDIE; DMG: PDIE", nDuration = 1, sApply = "single" }
    },
    ["steel resolve"] = {
        { type = "effect", sName = "SAVE: PDIE", nDuration = 1, sApply = "single" }
    },
    ["sworn to protect"] = { 
        { type = "effect", sName = "DECREMENT; AC: PDIE; AURA: 15 friend; SAVE: PDIE" }
    },
    ["skirmisher"] = { 
        { type = "effect", sName = "DECREMENT; Speed 5x PDIE; DMG: PDIE" }
    },
    -- Mercantile Guild
    ["action plan"] = {
        { type = "effect", sName = "ATK: PDIE; CHECK: PDIE; SAVEDC: PDIE", nDuration = 1, sApply = "roll" }
    },
    -- Mystic Circle
    ["universal energy field"] = {
        { type = "effect", sName = "DMG: PDIE acid", nDuration = 1 },
        { type = "effect", sName = "DMG: PDIE cold", nDuration = 1 },
        { type = "effect", sName = "DMG: PDIE fire", nDuration = 1 },
        { type = "effect", sName = "DMG: PDIE lightning", nDuration = 1 },
    },
    ["magic misdirection"] = {
        { type = "effect", sName = "CHECK: PDIE", nDuration = 1, sApply = "roll" }
    },
    -- Nature Pact
    ["vine entrapment"] = {
        -- Currently this forces a saving throw, but that will require more thought to work out
    },
    ["impenetrable defense"] = {
        { type = "effect", sName = "RESIST: PDIE", nDuration = 1 }
    },
    ["rapid assault"] = {
        { type = "effect", sName = "ATK: PDIE; DMG: PDIE", nDuration = 1, sApply = "single" }
    },
    -- Noble Court
    ["mantle of authority"] = {
        -- This will not work, because the stat short hands (STR, CON, etc) add to the modifier
        -- Not the score total. This is problematic
        -- { type = "effect", sName = "DECREMENT; STR: PDIE", nDuration = 1 }
    },
    ["conqueror"] = {
        { type = "effect", sName = "ATK: PDIE; Speed 10;", nDuration = 1 }
    },
    ["timely aid"] = {
        { type = "effect", sName = "AC: PDIE", nDuration = 1 },
        -- { type = "heal", clauses = { { dice = { }, bonus = "PDIE" } } }
    },
    -- Religious Order
    ["penance"] = {
        -- This could be problematic, as the effect goes on a target that doesn't have the PDIE effect
        { type = "effect", sName = "DECREMENT", sTargeting = "self" },
        { type = "effect", sName = "DMGO: 2x PDIE; Speed penalty: 5x PDIE" },
    },
    -- Underworld Syndicate
    ["find weakness"] = {
        { type = "effect", sName = "AC: -PDIE", nDuration = 1 },
    },
    ["poison weapons"] = {
        { type = "effect", sName = "DECREMENT; DMG: PDIE poison", nDuration = 1, sTargeting = "self", sApply = "single" },
        { type = "effect", sName = "Poisoned", nDuration = 1 },
    },

}

auratraits = {
    ["burning"] = "AURA: 5 foe; Burning; DMGO: 1",
    ["rime"] = "AURA: 5 foe; Rime; Cannot move"
}

-- Martial Advantage look up data 
-- Used on the PC sheet actions tab for drag/dropping martial advantages
martialadvantages = {
    ["blood fever"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 13 }
    },
    ["troops of fame and great renown"] = {
        { type = "test", stat = "morale", savetype = "", savemod = 11 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["scroll of mass hypnosis"] = { 
        { type = "test", save = "command", savetype = "", savemod = 13, battlemagic = 1 },
        { type = "effect", sName = "disorganized", nDuration = 1 }
    },
    ["scroll of omund's trumpet"] = {
        { type = "effect", sName = "ADVTEST: attack, power", nDuration = 1 }
    },
    ["impassioned speech"] = {
        { type = "test", stat = "morale", savetype = "fixed", savemod = 12, rally = 1 },
        { type = "heal", clauses = { { dice = { "d4" }, bonus = 1 } } }
    },
    ["divine rally"] = {
        { type = "test", stat = "morale", savetype = "fixed", savemod = 13, rally = 1},
        { type = "heal", clauses = { { dice = { "d4" } } } },
        { type = "effect", sName = "DEF: 2; TOU: 2" }
    },
    ["wand of healing"] = {
        { type = "heal", clauses = { { dice = { "d4" } } } },
    },
    ["scroll of mass healing"] = {
        { type = "heal", clauses = { { dice = { }, bonus = 4 } } },
    },
    ["wand of grasping root"] = {
        { type = "test", stat = "power", savetype = "", savemod = 11, battlemagic = 1 },
        { type = "effect", sName = "disoriented", nDuration = 1 }
    },
    ["scroll of torrential rain"] = {
        { type = "effect", sName = "DISTEST: attack", nDuration = 1 }
    },
    ["bark and root"] = {
        { type = "heal", clauses = { { dice = { }, bonus = 1 } } },
    },
    ["scroll of storms"] = {
        { type = "test", stat = "power", savetype = "", savemod = 11, battlemagic = 1 },
        { type = "damage", clauses = { { dice = {}, bonus = 2 } } },
    },
    ["martial rally"] = {
        { type = "test", stat = "morale", savetype = "fixed", savemod = "13", rally = 1 },
        { type = "heal", clauses = { { dice = { "d4" } } } },
    },
    ["field promotion"] = {
        { type = "effect", sName = "ATK: 2; POW: 2; MOR: 2: COM: 2;", nDuration = 0 }
    },
    ["death commandos"] = {
        { type = "test", stat = "morale", savetype = "fixed", savemod = 13 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["infernal rally"] = {
        { type = "test", stat = "morale", savetype = "fixed", savemod = 13, rally = 1 },
        { type = "heal", clauses = { { dice = { "d4" } } } },
        { type = "effect", sName = "+1 attack; +1 movement; ADVTEST: attack, power; DMGO: 1" }
    },
    ["scroll of hellfire"] = {
        { type = "test", stat = "power", savetype = "", savemod = 13, battlemagic = 1 },
        { type = "effect", sName = "FIRE", nDuration = 4 },
        { type = "effect", sName = "FIRE", nDuration = 2 },
    },
    ["execution"] = {
        { type = "effect", sName = "ADVTEST: attack, power", },
    },
    ["hidden reserve"] = {
        { type = "heal", clauses = { { dice = { "d4" } } } },
    },
    ["like water"] = {
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["mine over body"] = {
        { type = "effect", sName = "Power tests against this unit fail", nDuration = 1 },
    },
    ["righteous"] = {
        { type = "effect", sName = "ADVTEST: attack", nDuration = 1, sApply = "action" },
    },
    ["templar's rally"] = {
        { type = "test", stat = "morale", savetype = "fixed", savemod = 13, rally = 1 },
        { type = "heal", clauses = { { dice = { "d4" } } } },
        { type = "effect", sName = "ATK: 2; POW: 2" }
    },
    ["scroll of clarity"] = {
        { type = "heal", clauses = { { dice = { "d4" } } } },
    },
    ["scroll of templar's blessing"] = {
        { type = "effect", sName = "AUTOPASS: command; +1 attack" }
    },
    ["pin them down"] = {
        { type = "effect", sName = "-1 movement" }
    },
    ["coordinated fire"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 8 }
    },
    ["skirmishers"] = {
        { type = "effect", sName = "ATK: 2" }
    },
    ["poison arrows"] = {
        { type = "effect", sName = "POISON", nDuration = 1 }
    },
    ["wand of fire"] = {
        { type = "test", stat = "power", savetype = "", savemod = 13, battlemagic = 1 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
        { type = "effect", sName = "FIRE", nDuration = 1 }
    },
    ["Invisibility"] = {
        { type = "effect", sName = "Hidden" }
    },
    ["scroll of translocation"] = {
        { type = "test", stat = "power", savetype = "", savemod = 11, battlemagic = 1 },
    },
    ["fire shield"] = {
        { type = "test", stat = "power", savetype = "", savemod = 13, battlemagic = 1 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["scroll of earthquake"] = {
        { type = "test", stat = "power", savetype = "", savemod = 13, battlemagic = 1 },
        { type = "damage", clauses = { { dice = {}, bonus = 2 } } },
        { type = "effect", sName = "Disorganized", nDuration = 1 }
    },
    ["wand of acid pool"] = {
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["patron's curse"] = {
        { type = "effect", sName = "Disoriented", nDuration = 1 }
    },
    ["scroll of blood magic"] = {
        { type = "effect", sName = "ADVTEST: power", nDuration = 1, sApply = "single" }
    },
    ["flaming hooves"] = {
        { type = "effect", sName = "FIRE", nDuration = 1 }
    },
    ["scroll of hell's maw"] = {
        { type = "test", stat = "power", savetype = "", savemod = 15, battlemagic = 1 },
        { type = "damage", clauses = { { dice = { "d6" }, bonus = 0 } } },
        { type = "effect", sName = "Disbanded" }
    },
    ["arrows of dancing lights"] = {
        { type = "effect", sName = "ADVTEST: attack", nDuration = 1, sApply = "single" }
    },
    ["wand of lightning storm"] = {
        { type = "test", stat = "power", savetype = "", savemod = 11, battlemagic = 1 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["wand of lightning storm"] = {
        { type = "damage", clauses = { { dice = { "d4" }, bonus = 0 } } },
    },
    ["scroll of cataclysm"] = {
        { type = "test", stat = "power", savetype = "", savemod = 15, battlemagic = 1 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
        { type = "effect", sName = "Disorganized", nDuration = 1 }
    },
    ["fiery defense"] = {
        { type = "test", stat = "power", savetype = "", savemod = 13, battlemagic = 1 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["scroll of firestorm"] = {
        { type = "test", stat = "power", savetype = "", savemod = 13, battlemagic = 1 },
        { type = "damage", clauses = { { dice = { "d4" }, bonus = 2 } } },
        { type = "damage", clauses = { { dice = { }, bonus = 2 } } },
    },
    ["well-motivated"] = {
        { type = "damage", clauses = { { dice = { }, bonus = 1 } } },
    },   
    -- Universal advantages
    ["retreat"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 8 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["set for charge"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 13 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["strafe"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 13 },
        { type = "damage", clauses = { { dice = {}, bonus = 1 } } },
    },
    ["volley"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 13 },
    },
    ["feint"] = {
        { type = "test", stat = "command" },
    },
    ["find cover"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 13 },
        { type = "effect", sName = "DISTEST: attack", nDuration = 1 }
    },
    ["follow up"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 8 }
    },
    ["mobility trap"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 13 },
        { type = "effect", sName = "Mobility Trap", nDuration = 1 }
    },
    ["rage charge"] = {
        { type = "test", stat = "command", savetype = "fixed", savemod = 13 },
    },
}