# 1.1 Update

New features:

* When a unit is reduced to half hit points, it gains the Diminished condition on the combat tracker
* When a unit is reduced to 0 casualties it gains the Broken condition
* All unit conditions have been added to the presets on the Effects window
* Units now have a "Rally" button on them. Clicking this button rolls a DC 13 Morale test. If this test succeeds the unit has the "Rallied" condition added to it. If the test fails, the unit has the "Disbanded" condition added to it.
* Units with the Hidden condition force attacks against them to have disadvantage
* Units with the Weakened condition have disadvantage on power tests
* Added more effects for unit tests:
  * ADVTEST              - Unit has advantage on all tests
  * ADVTEST: [stat, ...] - Unit has advantage on the listed stat tests
  * DISTEST              - Unit has disadvantage on all tests
  * DISTEST: [stat, ...] - Unit has disadvantage on the listed stat tests
  * GRANTADVATK          - Attackers have advantage on attack tests
  * GRANTDISATK          - Attackers have disadvantage on attack tests
  * GRANTADVPOW          - Attackers have advantage on power tests
  * GRANTDISPOW          - Attackers have disadvantage on power tests
* The Abilities tab of the PC sheet now has a "Martial Advantages" section where you can create and add martial advantages. There is no drag/drop support for this section, items can only be created with the "add" button.
