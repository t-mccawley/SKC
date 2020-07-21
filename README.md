# SKC (Suicide Kings Classic)
A World of Warcraft Classic addon for the [suicide kings loot system](https://wowwiki.fandom.com/wiki/Suicide_Kings). This addon was designed based on the specific variant of SK used by the guild Whiteclaw Clan on Grobbulus [H]. Compared to a standard SK system, the primary differences of the variant implemented here include the use of two separate lists, Main SK and Tier SK, as well as a loot prioritization system which gives characters of certain spec / class priority over others for a given item. SKC fully automates this system. SKC will manage the SK lists in game, synchronize data between all members of a guild, and upon looting of an item, will automatically determine the elligible characters in the raid for that item, query for their decision (SK, roll, or pass), and award the loot based on a configurable loot prioritization.

![SKC GUI](/media/SKC_Addon.png)

## Features
- Single GUI interface (/skc)
- Supports two separate lists (Click MSK / TSK title to cycle):
  - Tier SK (TSK): Intended for tier set items or those usable by only a speicifc class / role. More generally can be used for common items or those that offer a relatively small upgrade.
  - Main SK (MSK): Intended as the primary SK list. More generally can be used for rare items or those that offer a significant upgrade.
- Loot Prioritization System
  - Loot prio is a configurable input to SKC through a CSV import interface (/skc prio init)
  - Schema for loot prio CSV can be found here
  - For a given item, a loot prio can be assigned for the 22 predefined Class / Spec combinations below:

|  Class  |     Spec    |
|:-------:|:-----------:|
|  Druid  |   Balance   |
|  Druid  | Restoration |
|  Druid  |  Feral Tank |
|  Druid  |  Feral DPS  |
|  Hunter |     Any     |
|   Mage  |     Any     |
| Paladin |     Holy    |
| Paladin |  Protection |
| Paladin | Retribution |
|  Priest |     Holy    |
|  Priest |    Shadow   |
|  Rogue  |     Any     |
|  Rogue  |   Daggers   |
|  Rogue  |    Swords   |
|  Shaman |  Elemental  |
|  Shaman | Enhancement |
|  Shaman | Restoration |
| Warlock |     Any     |
| Warrior |     DPS     |
| Warrior |  Protection |
| Warrior |  Two Handed |
| Warrior |  Dual Wield |

- Automatic loot distribution
  - When the master looter GUI is opened in a raid, 

## Slash Commands
