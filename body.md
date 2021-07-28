# 1.3.1 Harrowing Update - Bug Fixes

Bug Fixes

* Units are now always visible if they have no commander on the combat tracker. If a commander is deleted while their units are hidden, the units become visible.
* Toggling a commander's unit visibility button no longer sets their units' token visibility, and instead forces the units' token visibility to match the commander's token's visibility.
* Units in the client combat tracker now filter appropriately based on if the token is visible, if the unit has a commander on the CT, if the unit is being force-hidden.
