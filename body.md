# 1.6.0 - Party Sheet Update

## Wiki

* There is now a full wiki documenting all of the features for this extension. [You can find it here](https://github.com/Gtaray/FG_KingdomsAndWarfare/wiki)

## Party Sheet

* There are two new tabs on the Party Sheet: Domain and Pwr Pool. These tabs contain everything the party needs to manage their domain.
* The domain tab contains domain skills, defenses, titles, and development tracks
* The Power Pool tab contains domain features, powers, and the power pool.
* You can add actions to domain powers on the party sheet the same way you add actions to PC powers through the radial menu. See more details [on the wiki](https://github.com/Gtaray/FG_KingdomsAndWarfare/wiki/Domain-Powers)
* Full documentation [on the wiki](https://github.com/Gtaray/FG_KingdomsAndWarfare/wiki/Party-Sheet)

## Power Dice

* Power Dice pulled from a power pool add an effect to the person who pulls the dice: POWERDIE: #, where # is the value on the dice pulled. Pulling multiple dice adds them together
* Effects can reference the power die by using the keyword "PDIE" in the effect. Ex. ATK: PDIE
* Use the keyword "DECREMENT" in an effect to decrement the power die at the end of your turn. Ex. "DECREMENT; AC: PDIE"
* Multiply the power die using the keyword "#x " where # is the multiplier. Ex. "DMG: 5x PDIE"
* Make PDIE a penalty by adding a dash in front of it. Ex. "ATK: -PDIE; DMG: 5x PDIE"
* Full documentation [on the wiki](https://github.com/Gtaray/FG_KingdomsAndWarfare/wiki/Using-Power-Dice)
