[h1] [TLP] Resistance Operation Overhaul [/h1]

This mod is a major overhaul of the Resistance Operations that were added by the Tactical Legacy Pack DLC, aimed to give players more control over how their squad evolves over the course of the operation.

The flow of a Resistance Operation has changed quite a bit:
1. First you choose the settings for the operation. This includes how many missions there will be, how many soldiers you will have, what classes they will be, what mission they join on, the difficulty of the operation, and more.
2. Next, you play through the first randomly generated mission.
3. After the mission is complete you will earn Credits, your Research Level may increase, and all of your soldiers will rank up once.
4. You will be taken to a new interface where you can perform research. In order to research a project, you must meet the Research Level requirement and spend some Credits.
5. Choose new abilities for your squadmates who have ranked up, and equip them with any new gear that you have researched.
6. After performing preparations, you are taken to a new interface where you must choose the next mission. You will have 2 options to choose from, and the rewards will differ: some will grant additional Credits, further increase your Research Level, or perhaps a free research project.
7. Continue to the next mission. Rinse and repeat until you complete all missions in the Resistance Operation.

To clarify the two resources that are earned after each mission:
- Research Level: Researching a project requires your Research Level to have reached a certain value. For example, Magnetic Rifles require you to have a Research Level of 2 or higher. Research Level does [b]not[/b] decrease when a project is researched.
- Credits: Credits are spent to research a project.

Controllers are fully supported. Playing a Narrative Ladder operation, or playing without Enable Resistance Operation Overhaul checked, will not include any of the overhaul features, and the game will play as it normally would.

[h1] The Settings [/h1]

[b] Enable Resistance Operation Overhaul [/b]
This setting must be on to play the Resistance Operation Overhaul. If it is off, then the Resistance Operations will play out as if this mod was not installed.

[b] Configure Squad [/b]
Here you can customize what soldiers you will have for operation
For each soldier, you have the following options:
- What character from the Character Pool they are. There are also options for Random Character or Randomly Generated Character
- What class they are. There is an option for Random Class.
- Before What mission they join the squad.

[b] Set Allowed Classes [/b]
Choose the allowed class options that soldiers with their class set to Random Class can be.

[b] Allow Duplicate Classes [/b]
If enabled, you may end up with multiple soldiers with the same class. 

[b] Number of Missions [/b]
The number of missions in the Resistance Operation.ists). Allow Duplicate Classes must be enabled for this setting to take effect.

[b] Starting and Ending Force Levels [/b]
Force level on the first and last missions, respectively. Higher force level means fighting tougher enemies. Force level will increase linearly from the start of the Resistance Operation to the end based on the entered values.

[b] Starting and Ending Alert Levels [/b]
Alert level on the first and last missions, respectively. Higher alert level means fighting more enemies. Alert level will increase linearly from the start of the Resistance Operation to the end based on the entered values.

[b] Set Advanced Options [/b]
Lets you set Advanced Options (e.g. Beta Strike) for the Resistance Operation. Can work with Advanced Options added by mods, but it depends specifically on how they are implemented in those mods.

[b] Save and Load Configurations [/b]
Save and Load a set of custom settings. Note that these are written to XComROOSaves.ini in Documents\My Games\XCOM2 War of the Chosen\XComGame\Config so if that file is deleted, then your saved configurations will be deleted.

[h1] Mod Compatibility [/h1]
Most mods are compatible, see below for details. General ladder settings can be changed by modifying XComLadderOptions.ini. Research templates can be added or changed by modifying XComSoldierUpgrades.ini and ResistanceOperationOverhaul.int. More detailed instructions for adding mod compatibility are written in the top comment of XComSoldierUpgrades.ini.

[b] Required Mods [/b]
- X2WOTCCommunityHighlander
- WotC: robojumper's Squad Select

[b] Recommended Mods [/b]
- One of the "Rookie Psi Operative" mods. The base Psi Operative class is disabled because of some weirdness with their ability requirements, so a "Rookie Psi Operative" class works much better.

Class overrides - This mod will not be compatible with other mods that override these classes, but AFAIK there aren't any.
- XComGameState_LadderProgress
- UITLE_LadderModeMenu

[b] Mods that should just work [/b]
- Class mods
	- Exception: RPGO is not supported. 
	- Exception: Classes that add new equipment will need to have them entered into the config files, so that the new equipment can be researched and equipped.
- Enemy and AI mods
- Map mods
- Tactical gameplay mods

[b] Mods with built-in support [/b]
- [WOTC] Iridar's Five Tier Weapon Overhaul - Vanilla Balance
- Long War SMG Pack - WotC (unofficial)
- Beam Grenade Launcher
- WotC Ballistic Shields
- [WoTC]Tier III Grenades
- [WOTC] Superior Explosives
- [WOTC] LW2 Secondary Weapons
- [WOTC] Iridar's Underbarrel Attachments
- Primary Secondaries
- High Quality Rounds [WotC + Vanilla]
- [WOTC] Corrosive Rounds
- [WOTC] Frost Munitions
- [WOTC] LW2 Utility Plating
- [WOTC] Pharmacist Class
- [WOTC] LW2 Classes and Perks
- [WOTC] Cut Content Ammo
- [WOTC] Rocket Launchers 2.0
- [WOTC] Iridar's Spark Arsenal 3.0
- Immolator + Chemthrower Abilities
- Iridar's Molotovs
- Jump Jets
- [WOTC] Jet Packs

[b] Mods that will not be supported [/b]
- RPG Overhaul - I know many may be disappointed here, but the amount of extra work needed to support RPGO is just not something I'm interested in doing.
- True Primary Secondaries - Would require a lot of re-work to support, and most people who use True Primary Secondaries do so because they use RPGO anyway.
- Long War of the Chosen - I will likely build in support when 1.0 is released, I'm just waiting until it is more stable.
- [TLP] Custom Resistance Operations - This mod is a successor.
- [WOTC] Resistance Operations: Use Character Pool - Similar functionality is already in this mod.

[b] Known issues [/b]
- Abandoned ladders still show the details of where the ladder would be if it was not abandoned. Starting the abandoned ladder will still start you from the beginning as normal though. This is only a visual bug.
