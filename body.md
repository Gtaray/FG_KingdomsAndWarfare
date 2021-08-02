# 1.5 - Character Update

## Features

* Powers on the Action tab of the PC sheet can now have Unit Test actions added to them. These unit tests can be used to handle martial advantages for player commanders. You can define which stat to roll and the DC for the roll, and these actions can be forced onto units by targeting or drag/dropping the dice directly onto a unit.
* Added a Powers tab to NPCs that contains warfare-related information: domain size and a list of martial advantages. Martial advantages allow you to roll from relevant text, and correctly handle "\<stat\> test (DC = # + DS)", calculating the DC based on the NPC's domain size
* Added a new sidebar shortcut for martial advantages labaled "Advantages". These can be drag/dropped directly onto the PC's actions tab in the same way that spells can. They can also be drag/dropped onto the new NPC Powers tab to add the martial advantage to an NPC commander
* Where applicable, when a martial advantage is dropped onto the PC's action tab, it will automatically create relevant actions for the martial advantage (tests, damage, healing, and effects)
* Added ATKDMG and POWDMG effects, which can be used to add damage specifically to attack tests and power tests respectively
* Overhauled the roll workflow. Now, unit traits and martial advantages no longer need to specify between 'tests' and 'saves' with regards to the target of a roll. Tests rolled from unit traits or martial advantages now determine their function based on if they have a target or not. If there's a target, the target rolls the Test, if there's no target, a unit will roll the test themselves. All this to say: **you no longer need to specify 'save' when entering unit traits or martial advantages.**
