---
toc: WoD5e
summary: Staff Commands
---
# Staff Commands

`sheet <player>` - See a player's sheet

`sheet/init <player>=<type>[/confirm]` - Initializes a `player`'s sheet with the specified `type`.  `/confirm` will delete an existing sheet wholesale and create a new one.

`sheet/set <player>=<statType>/<statName>=<mainValue>/<subValue>` - Set values on a player's sheet.
  Valid values are based on the chosen statType --
  `basic`: 
    statName: `type`
      mainValue: Any valid type (Currently: `hunter`)
      subValue: Not Used
  `attribute`:
    statName: Name of the attribute (`Strength`, `Dexterity`, etc)
      mainValue: Any positive number
      subValue: Not Used
  `skill`:
    statName: Name of any skill (`Athletics`, `Larceny`, etc.)
      mainValue: `0` or any positive number
      subValue: Not Used
  `specialty`:
    statName: Name of any skill (`Athletics`, `Larceny`, etc.)
      mainValue: Desired Specialty
      subValue: Not Used
  `advantage`:
    statName: Name of the Advantage (Merit, Flaw, or Background -- Notes should)
      mainValue: `0` will remove the Advantage.
        subValue: Not Used
      mainValue: Any negative or positive number
        subValue: Not Used
      mainValue: Name of an Advantage option (ex: the `Safe House` Merit can have options like `Hidden Armory`)
        subValue: `0` to remove, or a positive number to set

