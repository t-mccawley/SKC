# SKC (Suicide Kings Classic)
A World of Warcraft Classic addon for the [suicide kings loot system](https://wowwiki.fandom.com/wiki/Suicide_Kings). This addon was designed based on the specific variant of SK used by the guild Whiteclaw Clan on Grobbulus [H]. Compared to a standard SK system, the primary differences of this variant is the use of a loot prioritization system as well as utilizing two separate lists, Main SK and Tier SK. SKC fully automates this system. SKC will manage the SK lists in game, synchronize data between all members of a guild, and upon looting of an item, will automatically determine the elligible characters in the raid for that item, query for their decision (SK, roll, or pass), and award the loot based on a configurable loot prioritization.

You can download SKC on [CurseForge](https://www.curseforge.com/wow/addons/skc) and Twitch.

![SKC GUI](/media/SKC_GUI.png)

![SKC Loot](/media/SKC_Loot.png)

## TLDR
[Video Tutorials](https://www.youtube.com/playlist?list=PLde2gp4VU_iNecMuSxlkR1hmU6NPqFekL)

## Features
### Simple GUI interface
- Open the main GUI with `/skc`
- Loot decision GUI opens automatically
### Automatic Synchronization
- SKC automatically synchronizes data in game within guild to ensure that every member has the most up to date SK list, guild data, and loot prio.
- Specifically, data synchronizes with the Loot Officer who has the newest data.
- The Synchronization field in the Status portion of the main GUI describes the status. The possible enumeraions are:
    - **In Progress**: SKC is in the process of synchronizing with a Loot Officer.
    - **Complete**: SKC is synchronized with all online Loot Officers.
### Two Separate SK Lists 
- Main SK (MSK): Intended as the primary SK list. More generally can be used for rare items or those that offer a significant upgrade.
- Tier SK (TSK): Intended for tier set items or those usable by only a speicifc class / role. More generally can be used for common items or those that offer a relatively small upgrade.
- Click MSK / TSK title in the GUI to cycle between them
### Automatic Loot Distribution
- Once SKC is **Active**, loot may be distributed automatically by SKC (see Addon Status Display below).
- Sequence of automatic loot distribution:
    1. Master looter of a raid (who is a Loot Officer) opens the master looter GUI for an item
    2. SKC uses the Loot Prio to determine which characters are elligible for the given loot
    3. SKC prompts elligible characters with the possible loot decisions (SK, Roll, or Pass)
    4. Characters have a configurable amount of time (see slash commands) to make a decision
    5. SKC collects the decisions and arbitrates the winner based on Loot Prio and player decisions
    6. SKC sends the loot to the winner and performs the SK (if necessary)
    7. SKC logs the loot distribution event and player responses
### Loot Prioritization System
- Loot prio is a configurable input to SKC through a CSV import interface (see slash commands)
- **Only items in the loot prio system will be automatically distributed by SKC**. All other green or rarer items will be automatically looted by the Master Looter.
- Loot prio is used to give certain Class / Spec combinations priority over others regardless of their SK positions. Loot prio is only relevant for characters who decide to SK for an item (it is not used for rolling / passing).
- Schema for loot prio CSV can be found here (TODO)
- For a given item, a loot prio can be assigned for the 22 predefined Class / Spec combinations found in the Appendix
- Loot prio can be assigned a value of 1 (highest main spec priority) to 5 (lowest main spec priority) and OS. Omitting a prio value means that Spec / Class is inelligible for the item and will not receive a loot decision GUI.
- Additionally, can configure the following options for a given item
    - **SK List** (MSK or TSK): What list the item is associated with
    - **Reserved** (TRUE or FALSE): TRUE if "Main" characters are given priority over "Alt" characters, otherwise there is no distinction betweel Mains and Alts.
    - **Disenchant** (TRUE or FALSE): In the event that everyone passes on this item, TRUE will cause SKC to give the item to the Disenchanter, otherwise given to Guild Banker
    - **Open Roll** (TRUE or FALSE): TRUE enables the "Roll" loot decision option to be selected for the given item, otherwise it is disabled.
### Guild Roster Management
- SKC provides an in game GUI for the Guild Leader to manage details about the guild members
- Some of these details are used in the automatic loot distribution process.
- The data can be initialized from a CSV (recommended)
- The character specific details are:
    - **Name**: Character name
    - **Class**: Character class
    - **Spec**: Character main raiding spec (available options found in the Appendix) **Editable by Guild Leader**
    - **Raid Role** (DPS, Healer, Tank): Automatically determined by Spec. Used for filtering of SK list
    - **Guild Role** (None, Disenchanter, Banker): In the event that everyone passes on a parituclar item, a person with the approriate role would instead be awarded the loot. **Editable by Guild Leader**
    - **Status** (Main or Alt): Main characters receive prio over Alts if the given item is marked as Reserved **Editable by Guild Leader**
### Bench / Live List Support
- Members of a raid are automatically added to the live list
- Any automatic SKs performed during the raid will drop the character to a position below that of the bottom of the **live** list.
- The Loot Officers can manually add characters to the bench (see slash commands)
### Automatic Loot Activity Log
- SKC automatically records all loot distribution events made by the addon during a raid
- The log is saved until the start of next raid
- The log is exportable as a CSV (see slash commands)
### SK Usage Control
- The guild leader can control the usage of SKC as a loot distribution system through the following means:
    - **Loot Officers**: In order for SKC to be enabled, a Loot Officer must be a member of the raid. To manage the Loot Officer list, see slash commands.
    - **Active Instances**: In order for SKC to be enabled, the given instance must be found in the Active Instances list. Possible Active Instances can be found in the Appendix.
    - **Manual Enable/Disable**: The Guild Leader (or any Loot Officer) can manually enable / disable the addon, see the relevant slash commands.
### Addon Status Display
- The GUI displays a status message to describe the state of SKC. The possible enumerations are:
    - **Active**: SKC will distribute loot automatically.
    - **Disabled**: SKC has been manually disabled by a Loot Officer
    - **Inactive (GL)**: SKC is inactive due to either the Guild Leader not yet having installed the addon or not yet logging on to synchronize their data
    - **Inactive (VER)**: SKC is inactive due to your version of the addon not matching the version of the Guild Leader's
    - **Inactive (RAID)**: SKC is inactive due to not being a member of a raid
    - **Inactive (ML)**: SKC is inactive due to not being in a raid with the Master Looter loot distribution method
    - **Inactive (LO)**: SKC is inactive due to the Master Looter not being a Loot Officer
    - **Inactive (AI)**: SKC is inactive due to not being in an instance specified in the Active Instances
### Security
- The addon has built in security to ensure that players cannot maliciously manipulate the SK lists.
- Only the Guild Leader can manage the Loot Officers, and only the Loot Officers can manage the SK lists and provide synchronization data.

## FAQ
### Where is the TSK list?
Click the MSK title on the GUI to cycle between the lists.
### Why Isn't SKC Active?
In order for SKC to be active, the following conditions must be met:
1. SKC must be enabled (see the slash command `/skc enable`).
2. The Guild Leader must have the addon installed.
3. Your addon version must match your Guild Leader's addon version.
4. You must be in a raid.
5. Your raid must be using the Master Looter distribution method.
6. Your raid must have a Master Looter who is a Loot Officer (see SK Usage Control).
7. You must be in an Active Raid (see SK Usage Control).
### Why Isn't the Loot Distribution GUI Appearing?
SKC automatically synchronizes data between guild members. First check the main GUI to see if SKC is currently synchronizing. Loot distribution will be delayed until synchronization is complete, so just wait a few seconds.
If loot distribution never starts, it is likely because the item is not in your Loot Prio database, or the elligible class / spec combinations are not members of the raid.
### Why is the Synchronization Status Stuck on In Progress?
SKC automatically syncs with online Loot Officers. If there are significant changes since the last time you sync'd, the synchronization might take a bit, give it a few minutes. World of Warcraft only allows a certain rate of addon message communication so the speed is limited. 

## Slash Commands
Some slash commands are protected by character privelages, see the available slash commands for each member type below:
### All Members
- `/skc help`: Lists all available slash commands
- `/skc`: Toggles GUI
- `/skc ver`: Shows addon version
- `/skc lp`: Displays the number of items in the Loot Prio database
- `/skc lp <item link/name>`: Displays Loot Prio for given item
- `/skc b`: Displays the Bench
- `/skc ai`: Displays Active Instances
- `/skc lo`: Displays Loot Officers
- `/skc ldt`: Displays the current loot decision time
- `/skc export sk`: Export (CSV) current SK lists
- `/skc export g`: Export (CSV) current Guild Data
- `/skc reset`: Resets local SKC data and reloads ui

### Loot Officer Only      
- `/skc b add <character name>`: Adds character to the Bench
- `/skc b remove <character name>`: Removes character from the Bench
- `/skc b clear`: Clears the Bench
- `/skc enable`: Enables loot distribution with SKC
- `/skc disable`: Disables loot distribution with SKC
- `/skc export log`: Export (CSV) sk log for most recent raid
    
### Guild Leader Only
- `/skc g init`: Initialze Guild Data with a CSV (same schema as export)
- `/skc lp init`: Initialze Loot Prio with a CSV ([link](schema/loot_prio_import_schema.txt) to schema)
- `/skc <msk/tsk> init`: Initialze SK List with a CSV (vertical list of names)
- `/skc ai add <acro>`: Adds instance to Active Instances
- `/skc ai remove <acro>`: Removes instance from Active Instances
- `/skc ai clear`: Clears Active Instances
- `/skc lo add <name>`: Adds name to Loot Officers
- `/skc lo remove <name>`: Removes name from Loot Officers
- `/skc lo clear`: Clears Loot Officers
- `/skc ldt <#>`: Changes the loot decision time to # in seconds

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

Loot Prio Tiers (Prio 1 is highest priority):
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

Supported Instances:
|         Raid        | Acronym |
|:-------------------:|:-------:|
|    Ragefire Chasm   |   RFC   |
|   Wailing Caverns   |    WC   |
|    The Deadmines    |    VC   |
|    Onyxia's Lair    |   ONY   |
|     Molten Core     |    MC   |
|    Blackwing Lair   |   BWL   |
|      Zul'Gurub      |    ZG   |
|  Ruins of Ahn'Qiraj |   AQ20  |
| Temple of Ahn'Qiraj |   AQ40  |
|      Naxxramas      |   NAXX  |
