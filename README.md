# SKC (Suicide Kings Classic)
A World of Warcraft Classic addon for the [suicide kings loot system](https://wowwiki.fandom.com/wiki/Suicide_Kings). This addon was designed based on the specific variant of SK used by the guild Whiteclaw Clan on Grobbulus [H]. Compared to a standard SK system, the primary differences of the variant implemented here include the use of two separate lists, Main SK and Tier SK, as well as a loot prioritization system which gives characters of certain spec / class priority over others for a given item. SKC fully automates this system. SKC will manage the SK lists in game, synchronize data between all members of a guild, and upon looting of an item, will automatically determine the elligible characters in the raid for that item, query for their decision (SK, roll, or pass), and award the loot based on a configurable loot prioritization.

![SKC GUI](/media/SKC_Addon.png)

## Features
### Single GUI interface
- Open the main GUI with `/skc`
### Automatic Synchronization
- SKC automatically synchronizes data in game within guild to ensure that every member has the most up to date SK list, guild data, and loot prio.
### Two Separate SK Lists 
- Main SK (MSK): Intended as the primary SK list. More generally can be used for rare items or those that offer a significant upgrade.
- Tier SK (TSK): Intended for tier set items or those usable by only a speicifc class / role. More generally can be used for common items or those that offer a relatively small upgrade.
- Click MSK / TSK title in GUI to cycle between them
### Guild Roster Management
- SKC provides an in game GUI for the Guild Leader to manage details about the guild members
- Some of these details are used in the automatic loot distribution process.
- The character specific details are:
   - **Name**: Character name
   - **Class**: Character class
   - **Spec**: Character main raiding spec (available options found in Appendix) **Editable by Guild Leader**
   - **Raid Role** (DPS, Healer, Tank): Automatically determined by Spec. Used for filtering of SK list
   - **Guild Role** (None, Disenchanter, Banker): In the event that everyone passes on a parituclar item, a person with the approriate role would instead be awarded the loot. **Editable by Guild Leader**
   - **Status** (Main or Alt): Main characters receive prio over Alts if the given item is marked as Reserved **Editable by Guild Leader**
   - **Activity** (Active or Inactive): Indicates if the character has been to a raid within a given amount of days. The activity threshold is configurable by the guild leader (see more in slash commands seciton) **Editable by Guild Leader**
   - **Last Raid** (days): Number of days since character was last added to a live list (either by being in a raid or added to bench)
### Bench / Live List Support
- Members of a raid are automatically added to the live list
- Any automatic SKs performed during the raid will drop the character to a position below that of the bottom of the **live** list.
- The Master Looter can manually add characters to the bench (see slash commands)
### Loot Prioritization System
- Loot prio is a configurable input to SKC through a CSV import interface (see slash commands)
- **Only items in the loot prio system will be automatically distributed by SKC**
- Loot prio is used to give certain Class / Spec combinations priority over others regardless of their SK positions. Loot prio is only relevant for characters who decide to SK for an item (it is not used for rolling / passing).
- Schema for loot prio CSV can be found here (TODO)
- For a given item, a loot prio can be assigned for the 22 predefined Class / Spec combinations found in the appendix
- Loot prio can be assigned a value of 1 (highest main spec priority) to 5 (lowest main spec priority) and OS. Omitting a prio value means that Spec / Class is inelligible for the item and will not receive a loot decision GUI.
- Additionally, can configure the following options for a given item
    - **SK List** (MSK or TSK): What list the item is associated with
    - **Reserved** (TRUE or FALSE): TRUE if "Main" characters are given priority over "Alt" characters, otherwise there is no distinction betweel Mains and Alts.
    - **Disenchant** (TRUE or FALSE): In the event that everyone passes on this item, TRUE will cause SKC to give the item to the Disenchanter, otherwise given to Guild Banker
    - **Open Roll** (TRUE or FALSE): TRUE enables the "Roll" loot decision option to be selected for the given item, otherwise it is disabled.
### Automatic loot distribution
- Sequence of automatic loot distribution:
    1. Master looter of a raid (with SKC installed) opens the master looter GUI for an item
    2. SKC uses the Loot Prio to determine which characters are elligible for the given loot
    3. SKC prompts elligible characters with the possible loot decisions (SK, Roll, or Pass)
    4. Characters have **10 seconds** to make a decision
    5. SKC collects the decisions and arbitrates the winner based on loot prio
    6. SKC sends the loot to the winner and executes the SK (if necessary)
    7. SKC logs the SK event
### Automatic SK Activity Log
- SKC automatically records all SK changes (manual or automatic) made during a raid
- The log is saved until the start of next raid
- The log is exportable as a CSV (see slash commands)

## Slash Commands
Some slash commands are protected by character privelages, see the available slash commands for each member below:
### All Members
- `/skc help`: Lists all available slash commands
- `/skc`: Toggles GUI
- `/skc prio <item link/name>`: Displays loot prio for given item
- `/skc prio`: Displays the number of items in saved loot prio
- `/skc reset`: Resets SKC data and re-sync with guild
- `/skc bench show`: Displays bench

### Guild Leader and Master Looter Only
- `/skc bench add <character name>`: Adds character to bench
- `/skc bench clear`: Clears bench
- `/skc enable`: Enables loot distribution with skc
- `/skc disable`: Disables loot distribution with skc
- `/skc export log`: Export sk log (CSV) for most recent raid
- `/skc export sk`: Export current sk lists (CSV)
    
### Guild Leader Only
- `/skc activity`: Displays the current inactivity threshold in days
- `/skc activity <#>`: Sets inactivity threshold to # days
- `/skc prio init`: Initialze loot prio with a CSV ([link](schema/loot_prio_import_schema.txt) to schema)
- `/skc <MSK/TSK> init`: Initialze sk list with a CSV (vertical list of names)

## Appendix
Supported Class / Specs:
|  Class  |     Spec    |
|:-------:|:-----------:|
|  Druid  |   Balance, Restoration, Feral Tank, Feral DPS   |
|  Hunter |     Any     |
|   Mage  |     Any     |
| Paladin |     Holy, Protection, Retribution    |
|  Priest |     Holy, Shadow    |
|  Rogue  |     Any, Daggers, Swords     |
|  Shaman |  Elemental, Enhancement, Restoration  |
| Warlock |     Any     |
| Warrior |     DPS, Protection, Two Handed, Dual Wield     |

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
