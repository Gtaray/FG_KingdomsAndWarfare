# Unofficial Kingdoms And Warfare (by MCDM) extension for Fantasy Grounds

Adds Fantasy Grounds support for MCDM's Kingdoms and Warfare D&amp;D 5th edition supplement.

[Download the latest version of the extension at this link](https://github.com/Gtaray/FG_KingdomsAndWarfare/releases/latest/download/UnofficialKingdomsAndWarfare.ext)

For any suggestions, comments, or issues feel free to create an issue here, or reach out to me on Discord. My username is: Saagael#5728

## Installing and Loading

To install and load the extension, you need to download the .ext file from the link above, put that file in Fantasy Ground's extension folder, and then activate the extension when loading your campaign. The below image shows to how to find the extension folder, and where to activate the extension at.

![Load extension](https://i.imgur.com/7XaJgvX.png)

Once your campaign is loaded, you can add the new domain and unit lists to the sidebar.

![Show unit and domain windows](https://i.imgur.com/brgZU4X.png)

## Using Units

Units can be used in all of the same ways NPCs can. You can add them directly to the combat tracker, or you can add them to encounters.

To give a player control over a unit, you must first put it on the combat tracker. Once you've done that you can drag the link icon from the combat tracker and drop it either in the chat window to share it with everyone, or you can drop it on top of a connected players portrait at the top of the screen to share it with just that one player. You will also need to **enable the "Party Vision and Movement" option in the game options window.**

The extension helps you manage all of the fiddly bits that can happen during battles. Below is a list of automation features this extension includes:

* When a unit is diminished it will automatically roll a morale test, suffering the consequences on a failure. Effects can allow units to automatically pass or ignore this test all together.
* When a unit is reduced to 0 casualties it is marked as Broken. If it later makes a rally test (there are buttons to do this on the combat tracker and on the unit's sheet) and succeeds, it is marked as Rallied. If it fails it is marked Disbanded.
* Units with the Harrowing trait force attackers to make their morale test. When a unit succeeds this test, they will no longer make morale tests.
* When a unit ends its turn, that unit is marked as having activated, and displays a relevant icon on the token. All units refresh their activation when a new round starts
* When a unit rolls a test on someone else's turn, that unit is marked as having spend its reaction, and displays a relevant icon on the token. Reactions are refreshed when a unit starts its turn. GMs can manually set this on the combat tracker. There is a game settings option to enable or disable this feature.
* The GM can show/hide units owned by individual commanders with a new button on the commander's entry on the combat tracker. The exception to this is that the units owned by the currently active commander are always displayed, regardless of the toggle.
* From the unit sheet you can initiate rolls by drag/dropping or clicking the relevant text of a trait in the same way you can do so with NPC actions. Currently you can initiate tests, saves*, damage, and healing rolls simply by clicking highlighted portions of the text.
* GMs can also initiate unit rolls directly from the combat tracker in the "Offense" section, where all unit traits are listed along with any relevant rolls.
* The GM can quickly assign units in the combat tracker to commanders by dragging the link icon for the unit and dropping it onto the commander that unit should be assigned to. This sets the unit's commander field, initiative result, and faction to match the commander.

* **IMPORTANT:** In order to reliably parse unit traits, there is a rigid distinction between TESTS and SAVES. A test is a roll that a unit makes itself: a command test, or a morale test, etc. A save is a roll that a unit forces another unit to make: a power save, or a morale save. In order for the system to know what to do with a roll, you must use the right verb when entering text. **TESTS** are for the active unit, **SAVES** are for an enemy unit.

### Unit Combat Tracker Entry

![Unit CT Entry](https://i.imgur.com/4n9TRvY.png)

## Example battle map

Here's an example battlemap using the map that [Weegedor made on the mattcolvile subreddit](https://www.reddit.com/r/mattcolville/comments/oszqnm/i_made_a_simple_warfare_map_for_virtual_tabletops/), with the example cards take from the Miro board the supertesters have been sharing. The grid I'm using is 120 units on a side. The combat tracker lets you track everything in combat, and you can drag/drop rolls onto the tokens/cards on the battlemap. As you can see actions, reactions, and conditions are automatically tracked in the combat tracker and dispaly on the tokens

![Battlemap](https://i.imgur.com/xioWFWW.png)

## Effects

Several unit traits are automatically tracked, but most are not. For most cases you can use the effects system to automatically track the many bonuses and penalties that units have.

### Unit Traits that are Tracked Automatically

* Adaptable
* Cloud of Darkness
* Dead
* Dire Hyena Mounts
* Draconic Ancestry
* Dragonkin
* Eternal
* Fearless
* Harrowing
* Hard Hats
* Regenerate
* Resolute
* Stalwart

### List of Effects and Conditions

Effect syntax is the same as used elsewhere in Fantasy Grounds:

* For effects that modify a value, use the following syntax - "Modifier: Value(s)"
* For conditions, simply enter the condition name in the effect line by itself.

| Modifier       | Value                                                          | Notes                                                                                                                   |
|----------------|----------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| Roll modifiers |                                                                |                                                                                                                         |
| ATK            | Number                                                         | Attack tests                                                                                                            |
| DEF            | Number                                                         | Defense                                                                                                                 |
| POW            | Number                                                         | Power tests                                                                                                             |
| TOU            | Number                                                         | Toughness                                                                                                               |
| MOR            | Number                                                         | Morale tests                                                                                                            |
| COM            | Number                                                         | Command tests                                                                                                           |
| DMG            | Number                                                         | Damage - both attack and power tests                                                                                    |
| ATKDMG         | Number                                                         | Damage - Only for attack tests                                                                                          |
| POWDMG         | Number                                                         | Damage - Only for power tests                                                                                           |
| ADVTEST        | Attack, power, morale, command,   diminished, rally, harrowing | Advantage on test                                                                                                       |
| DISTEST        | Attack, power, morale, command,   diminished, rally, harrowing | Disadvantage on test                                                                                                    |
| GRANTADVATK    |                                                                | Grant advantage on attack tests made against this unit                                                                  |
| GRANTDISATK    |                                                                | Grant disadvantage on attack tests made against this unit                                                               |
| GRANTADVPOW    |                                                                | Grant advantage on power tests made against this unit                                                                   |
| GRANTDISPOW    |                                                                | Grant disadvantage on power tests made against this unit                                                                |
| GRANTADVDIM    |                                                                | Targets damaged by units with this effect have advantage when rolling for diminishment                                  |
| GRANTDISDIM    |                                                                | Targets damaged by units with this effect have disadvantage when rolling for diminishment                               |
| AUTOPASS       | Attack, power, morale, command,   diminished, rally, harrowing | Automatically succeed on tests                                                                                          |
| RESIST         | Number, infantry, cavalry,   artillery, aerial                 | Resist damage from unit types. Enter a number value to specify flat   damage reduction. Ex. RESIST: 1 infantry          |
| VULN           | Number, infantry, cavalry,   artillery, aerial                 | Vulnerable to damage from unit types. Enter a number value to specify   flat damage addition.                           |
| IMMUNE         | Number, infantry, cavalry,   artillery, aerial, attack, power  | Immune to damage from unit types                                                                                        |
| ACID           | Number                                                         | Deals damage every round. Damage equals the effects duration. Enter   number to specify damage per token. Ex. ACID: 2   |
| BLEED          | Number                                                         | Deals damage every round. Damage equals the effects duration. Enter   number to specify damage per token. Ex. BLEED: 2  |
| FIRE           | Number                                                         | Deals damage every round. Damage equals the effects duration. Enter   number to specify damage per token. Ex. FIRE: 2   |
| POISON         | Number                                                         | Deals damage every round. Damage equals the effects duration. Enter   number to specify damage per token. Ex. POISON: 2 |
| Conditions     |                                                                |                                                                                                                         |
| Fearless       |                                                                | Immune to harrowing                                                                                                     |
| Broken         |                                                                | Can be rallied                                                                                                          |
| Disbanded      |                                                                | Cannot be rallied                                                                                                       |
| Rallied        |                                                                | Cannot be rallied                                                                                                       |
| Hidden         |                                                                | Attacking units have disadvantage                                                                                       |
| Weakened       |                                                                | Disadvantage on power tests                                                                                             |

### Conditional Effects

Some effects only work if either the active unit or their target meets some condition, for these, you can use the IF and IFT conditional effects.

What both these functions do is test a condition and if it is found to be true then the next part of the statement will be carried out, otherwise it will be ignored.

Let’s take the example IF: diminished; ADVTEST: power. What this is saying is that if the unit on which this effect is placed is diminished then they will have advantage on power tests, otherwise nothing happens.

The difference between the two components is that IF looks at the source (i.e. the creature on which the effect is sitting) whilst IFT looks at the target of the creature on which the effect is sitting.

Not only can IF and IFT test conditions (such as diminished, rallied, weakened, etc.) but they can also test for unit types, unit ancestry, and compare casualties. Below is a list of uses for IF and IFT

* Conditions (diminished, rallied, weakened, etc)
* If the target has fewer casualties than the unit - IFT: weaker;
* If the target has more casualties than the unit - IFT: stronger;
* Unit type - IFT: TYPE(artillery);
  * Options: infantry, artillery, cavalry, aerial
* Unit ancestry - IFT: ANCESTRY(undead);
  * Options: human, dwarf, elf, orc, goblinoid, undead

You can stack multiple conditions to get even more specific. Ex. IF: diminished; IFT: TYPE(infantry, cavalry); GRANTDISPOW. This effect is only active if the unit is diminished AND the unit is being attacked by an infantry or cavalry unit. If both of those are true, then the attacking unit has disadvantage on power tests against this unit.

## Domains

It's easy to forget that there's an entire second part to this extension. Domain management is thankfully simpler. The domain sheet has a place to track your domain's stats, defense score, defense levels, size, power pool, powers, features, officiers, and development points.

### The Power Pool

The Power Pool works by having players drop dice onto the box, which will roll the die and add the result. Players can then double click or drag/drop the numbers in the power pool into chat to consume those dice. This will put the dice result in chat and remove its entry from the power pool.

The GM can add dice manually and adjust their values.

### Skills and Defenses

Players can initiate domain skill rolls by double clicking or drag/dropping dice from the skill fields on the left. On the right are the defenses and defense levels. The GM can edit these.

### Powers and Features

Below the skills and defenses are powers and features. These are simple entries for text. No parsing or automation here.

### Officers

The GM can record a list of officers, as well as keep track of which officers have used their proficiency bonus and reactions during an intrigue.

### Development Tracks

These let you track the development points spent on a domain. They show the bonuses/scores associated with which milestones on the track.
