[TLP] Resistance Operation Overhaul

This mod is a major overhaul of the Resistance Operations that were added by the Tactical Legacy Pack DLC. The flow of a Resistance Operation has changed quite a bit:
1. First you choose the settings for the operation. This includes how many missions there will be, how many soldiers you will have, what classes they will be, what mission they join on, the difficulty of the operation, and more.
2. Next, you play through the first randomly generated mission.
3. After the mission is complete you will earn Credits and Science, and all of your soldiers will rank up once.
4. You will be taken to a new interface where you can perform research. Performing research requires two resources: Credits and Science. You will need Science to access new Reseach projects (e.g. you need 2 Science to research Magnetic Rifles), but Science is never consumed. Credits are used to perform the research, and are consumed.
5. Choose new abilities for your squadmates who have ranked up, and equip them with any new gear that you have researched.
6. After performing preparations, you are taken to a new interface will you must choose the next mission. You will have 2 options to choose from, and the rewards will differ: some will grant additional Credits, Science, or perhaps a free research project.
7. Continue to the next mission. Rinse and repeat until you beat all missions in the Resistance Operation.

Controllers are fully supported. Playing a Narrative Ladder operation, or playing without Enable Custom Settings checked, will not include any of the overhaul features, and the game will play as it normally would.

Mod Compatibility

Most mods are compatible (see below for details). General ladder settings can be changed by modifying XComLadderOptions.ini. Research templates can be added or changed by modifying XComSoldierUpgrades.ini and ResistanceOperationOverhaul.int. More detailed instructions for adding mod compatibility are written in the top comment of XComSoldierUpgrades.ini.

Required Mods:
- X2WOTCCommunityHighlander
- WotC: robojumper's Squad Select

Recommended Mods:
- One of the "Rookie Psi Operative" mods. The base Psi Operative class is disabled because of some weirdness with their ability requirements, so a "Rookie Psi Operative" class works much better.

Class overrides - This mod will not be compatible with other mods that override these classes, but AFAIK there aren't any.
- XComGameState_LadderProgress
- UITLE_LadderModeMenu

Mods that should just work:
- Class mods
	- Exception: RPGO is not supported. 
	- Exception: Classes that add new equipment will need to have them entered into the config files, so that the new equipment can be researched and equipped.
- Enemy and AI mods
- Map mods
- Tactical gameplay mods

Mods with built-in support:
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

Mods that will not be supported:
- RPG Overhaul - I know many may be disappointed here, but the amount of extra work needed to support RPGO is just not something I'm interested in doing.
- True Primary Secondaries - Would require a lot of re-work to support, and most people who use True Primary Secondaries do so because they use RPGO anyway.
- Long War of the Chosen - I will likely build in support when 1.0 is released, I'm just waiting until it is more stable.
- [TLP] Custom Resistance Operations - This mod is a successor.
- [WOTC] Resistance Operations: Use Character Pool - Similar functionality is already in this mod.

Known issues:
- Abandoned ladders still show the details of where the ladder would be if it was not abandoned. Starting the abandoned ladder will still start you from the beginning as normal though. This is only a visual bug.
