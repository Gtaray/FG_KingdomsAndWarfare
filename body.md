# 1.3.1 Harrowing Update - Bug Fixes

Bug Fixes

* Units are now always visible if they have no commander on the combat tracker. If a commander is deleted while their units are hidden, the units become visible.
* Toggling a commander's unit visibility button no longer sets their units' token visibility, and instead forces the units' token visibility to match the commander's token's visibility.
* Units in the client combat tracker now filter appropriately based on if the token is visible, if the unit has a commander on the CT, if the unit is being force-hidden.

New features

* You can now initiate rolls by hovering over the relevant text in a unit's trait. Currently the four types of rolls that it parses are tests (the unit making a roll), saves (the unit forcing another unit to make a roll), damage, and healing. With one exception, the text from Kingdoms and Warfare all is parsed correctly. **The only change necessary is to force another unit to make a save, you must replace the text 'test' with 'save'**. So 'An enemy unit makes a DC 15 Power test' becomes 'An enemy unit makes a DC 15 Power save.'
  