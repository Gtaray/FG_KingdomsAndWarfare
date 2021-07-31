# 1.4.3 - Effective Tokens Updated

## 1.4.3 Bug Fixes and Updates

* Units on the GM's combat tracker now list all of the unit's traits (below their stats), and you can initiate tests, saves, damage, and healing rolls directly from the combat tracker. You no longer need to dig into the unit's sheet to roll (you still can though)
* Added support for immunity to damage attack and power tests. 'IMMUNE: attack' and 'IMMUNE: power'.
* Added automatic handling of the Armored Carapace and Damage Resistant traits
* Players rolling rally test now applies the correct state to the unit depending on the result.
* Players units now correctly mark reactions as used when their units roll a test outside of their (or their commander's) turn on the combat tracker

## 1.4.2 Updates

* Units now track reactions not based on their own activation, but on whether the currently active CT combatant has the same commander as it. In this way you can activate and move a commanders units in any order without accidentally triggering a unit's reaction.
* From the combat tracker, the GM can drag/drop the link icon from a unit onto a non-unit actor, and the unit that was dropped onto the commander will be assigned to that commander. This sets the unit's commander name, sets its initiative to match the commander, and sets its faction to match the commander

## 1.4 Features

### Effects Updates

* Added support for IF and IFT. Both can check for unit conditions (diminished, rallied, harrowed, fearless, broken, disbanded), as well as unit types using the TYPES keyword. Examples
  * IFT: TYPE(infantry); ADVTEST: attack - Gives advantage on attack tests when targeting infantry units
  * IF: diminished; IFT: TYPE(infantry, cavalry); GRANTDISPOW - When this unit is diminished and is attacked by an infantry or a cavalry unit, the attacking unit has disadvantage on power tests.
  * IFT: diminished; ADVTEST: attack - This unit has advantage on attack tests against a diminished target
* Added AUTOPASS effect that causes a unit to always succeed on a type of tests. Example:
  * AUTOPASS: morale - automatically pass morale tests
  * AUTOPASS: diminished - automatically pass tests vs diminishing
  * AUTOPASS: rally - automatically pass rally tests
* Added damage token effects: ACID, BLEED, FIRE, POISON. The damage dealt is equal to the duration of the effect multiplied by a given value. Example:
  * BLEED - deals damage equal to the duration of the effect on turn start
  * ACID: 2 - deals damage equal to 2 times the duration of the effect on turn start
  * FIRE - deals damage equal to the duration of the effect on turn start
  * POISON: 3 - deals damage equal to 3 times the duration of the effect on turn start
* Added the Fearless effect, which makes a unit immune to Harrow.

### Action and Reaction tracking

* When a unit ends its turn the token is marked with an 'X' icon, signifying that the unit has already activated. These icons are reset when a new round starts
* When a unit rolls a test (not a save) and it is not that unit's turn, the unit is marked having used its reaction. This displays a '!' icon on the token. A unit's reaction is reset when it starts its turn. GMs can manually set this reaction on the combat tracker.
* There is a game setting under the "Kingdoms and Warfare" header to enable/disable automatic reaction tracking. It is on by default.

### Other Features

* Added a number of custom icons for various unit conditions, including: harrowed, immune to harrow, rallied, damage tokens, weakened, disoriented, and misled
* When a unit deals damage, that damage's damage type is set to match the unit's type. E.x. Infantry will deal 'infantry' damage, cavalry deal 'cavalry' damage. This allows you to specify resistances, vulnerabilities, and immunities to these types of damage with effects. Examples:
  * RESIST: 1 infantry - Reduce damage taken from infantry by 1
  * VULN: aerial - Take double damage from aerial units.
  * IMMUNE: artillery - Immune to damage from artillary units
  