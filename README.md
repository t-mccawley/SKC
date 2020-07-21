# SKC (Suicide Kings Classic)
A World of Warcraft Classic addon for the [suicide kings loot system](https://wowwiki.fandom.com/wiki/Suicide_Kings). This addon was designed based on the specific variant of SK used by the guild Whiteclaw Clan on Grobbulus [H]. Compared to a standard SK system, the primary differences of the variant implemented here include the use of two separate lists, Main SK and Tier SK, as well as a loot prioritization system which gives characters of certain spec / class priority over others for a given item. SKC fully automates this system. SKC will manage the SK lists in game, synchronize data between all members of a guild, and upon looting of an item, will automatically determine the elligible characters in the raid for that item, query for their decision (SK, roll, or pass), and award the loot based on a configurable loot prioritization.

![SKC GUI](/media/SKC_Addon.png)

## Features
- Single GUI interface
    - Open the main GUI with /skc
- Automatic Synchronization
    - SKC automatically synchronizes data in game within guild to ensure that every member has the most up to date SK list, guild data, and loot prio.
- Two Separate SK Lists 
    - Main SK (MSK): Intended as the primary SK list. More generally can be used for rare items or those that offer a significant upgrade.
    - Tier SK (TSK): Intended for tier set items or those usable by only a speicifc class / role. More generally can be used for common items or those that offer a relatively small upgrade.
    - Click MSK / TSK title in GUI to cycle between them
- Guild Roster Management
    - SKC provides an in game GUI for the Guild Leader to manage details about the guild members
    - These details are used in the automatic loot distribution process
       - TODO: Add configurable fields here
- Loot Prioritization System
 - Loot prio is a configurable input to SKC through a CSV import interface (/skc prio init)
 - **Only items in the loot prio system will be automatically distributed by SKC**
 - Loot prio is used to give certain Class / Spec combinations priority over others regardless of their SK positions. Loot prio is only relevant for characters who decide to SK for an item (it is not used for rolling / passing).
 - Schema for loot prio CSV can be found here
 - For a given item, a loot prio can be assigned for the 22 predefined Class / Spec combinations found in the appendix
 - Loot prio can be assigned a value of 1 (highest main spec priority) to 5 (lowest main spec priority) and OS. Omitting a prio value means that Spec / Class is inelligible for the item and will not receive a loot decision GUI.
 - Additionally, can configure the following options for a given item
  - SK List (MSK or TSK): What list the item is associated with
  - Reserved (TRUE or FALSE): TRUE if "Main" characters are given priority over "Alt" characters, otherwise there is no distinction betweel Mains and Alts.
  - Disenchant (TRUE or FALSE): In the event that everyone passes on this item, TRUE will cause SKC to give the item to the Disenchanter, otherwise given to Guild Banker
  - Open Roll (TRUE or FALSE): TRUE enables the "Roll" loot decision option to be selected for the given item, otherwise it is disabled.
- Automatic loot distribution
 - Sequence of automatic loot distribution:
  - Master looter of a raid (with SKC installed) opens the master looter GUI for an item
  - SKC uses the Loot Prio to determine which characters are elligible for the given loot

## Slash Commands

## Appendix
Supported Class / Specs:
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

Loot Prio Tiers (Prio 1 is highest priority)
| Prio | Loot Decision | Spec Prio |
|:----:|:-------------:|:---------:|
|   1  |   SK (Main)   | MS Prio 1 |
|   2  |   SK (Main)   | MS Prio 2 |
|   3  |   SK (Main)   | MS Prio 3 |
|   4  |   SK (Main)   | MS Prio 4 |
|   5  |   SK (Main)   | MS Prio 5 |
|   6  |   SK (Main)   |     OS    |
|   7  |    SK (Alt)   | MS Prio 1 |
|   8  |    SK (Alt)   | MS Prio 2 |
|   9  |    SK (Alt)   | MS Prio 3 |
|  10  |    SK (Alt)   | MS Prio 4 |
|  11  |    SK (Alt)   | MS Prio 5 |
|  12  |    SK (Alt)   |     OS    |
|  13  |  Roll (Main)  |     MS    |
|  14  |  Roll (Main)  |     OS    |
|  15  |   Roll (Alt)  |     MS    |
|  16  |   Roll (Alt)  |     OS    |
|  17  |      Pass     |     -     |
