# 1.5.2 - Character Update - Changes

* Dropping a martial advantage on a unit in the combat tracker adds that martial advantage to the unit. If the martial advantage has an effect associated with it, that effect is added to the unit as well.

# 1.5.1 - Character Update - Fixes

* Added general martial advantages to the list of automatically parsed advantages
* Fixed small issues with unit trait parsing

# 1.5 - Character Update

## Features

### General

* Added a new sidebar shortcut for martial advantages labaled "Advantages". These can be drag/dropped directly onto the PC's actions tab in the same way that spells can. They can also be drag/dropped onto the new NPC Powers tab to add the martial advantage to an NPC commander

* Overhauled the roll workflow. Now, unit traits and martial advantages no longer need to specify between 'tests' and 'saves' with regards to the target of a roll. Tests rolled from unit traits or martial advantages now determine their function based on if they have a target or not. If there's a target, the target rolls the Test, if there's no target, a unit will roll the test themselves. All this to say: **you no longer need to specify 'save' when entering unit traits or martial advantages.
* Units now display a "broken" icon when they are broken. This displays in the top right of the token
* Added an icon for the Disorganized conditions

### Effects

* Added ATKDMG and POWDMG effects, which can be used to add damage specifically to attack tests and power tests respectively
* Added GRANTADVDIM and GRANTDISDIM effects, which forces opposing units to roll their diminish check at advantage or disadvantage
* Added conditional check 'stronger' (ex. IFT: stronger;), which checks to see if the target has fewer casualties than the attacking unit
* Added conditional check 'weaker' (ex. IFT: weaker;), which checks to see if the target has more casualties than the attacking unit
* Added conditional check for ancestry (ex. IFT: ANCESTRY(undead);), which checks to see if the target unit has a matching ancestry. Use commas to specify several options. Ex. IFT: ANCESTRY(undead, goblinoid);

### Domains

* Added a Titles list to the domain sheet between the development tracks and officers list. You can enter the titles your domain offers here.
* You can drag/drop titles from the domain sheet to the PC sheet (see below)
* Updated the Power Pool by adding dice silhouettes behind the power pool dice entries.

### PC Sheet

* You can now drag/drop martial advantages onto the PC Abilities tab to add that advantage to the PC's list. This also adds the advantage to the Power tab as above.
* You can now drag/drop domain titles (see below) onto the PC Abilities tab.
* Powers on the Action tab of the PC sheet can now have Unit Test actions added to them. These unit tests can be used to handle martial advantages for player commanders. You can define which stat to roll and the DC for the roll, and these actions can be forced onto units by targeting or drag/dropping the dice directly onto a unit.
* Where applicable, when a martial advantage is dropped onto the PC's action tab, it will automatically create relevant actions for the martial advantage (tests, damage, healing, and effects)

### NPC Sheet

* Added a Powers tab to NPCs that contains warfare-related information: domain size and a list of martial advantages. Martial advantages allow you to roll from relevant text, and correctly handle "\<stat\> test (DC = # + DS)", calculating the DC based on the NPC's domain size
