class AStructs extends Object;

enum EUpgradeCategory
{
	eUpCat_Misc,
	eUpCat_Primary,
	eUpCat_Secondary,
	eUpCat_Heavy,
	eUpCat_Utility,
	eUpCat_Armor,
	eUpCat_Attachment,
	eUpCat_PCS,
	eUpCat_Grenade,
	eUpCat_Ammo,
	eUpCat_Vest,
};

struct MissionOption
{
	var string MissionType;
	var int Credits;
	var int Science;
	var array<name> FreeUpgrades;
};

struct SoldierOption
{
	var bool bRandomCharacter;
	var bool bRandomlyGeneratedCharacter;
	var string CharacterPoolName;
	var bool bRandomClass;
	var name ClassName;
	var int StartingMission;
};

struct LadderSettings
{
	var bool UseCustomSettings;
	var int LadderLength;
	var bool AllowDuplicateClasses;
	var array<name> AllowedClasses;
	var array<name> SecondWaveOptions;
	var int ForceLevelStart;
	var int ForceLevelEnd;
	var int AlertLevelStart;
	var int AlertLevelEnd;
	var array<SoldierOption> SoldierOptions;
};

struct ResistanceHistorySavePair
{
	var name Filename;
	var string DisplayName;
	var LadderSettings Settings;
};

struct MissionTypeOption
{
	var string MissionType0;
	var string MissionType1;
};

struct UnitEndState
{
	var XComGameState_Unit UnitState;
	var array<XComGameState_Item> Inventory;
};

struct InventoryUpgrade
{
	var name TemplateName;
	var bool bSingle;
};

struct TechUpgrade
{
	var name TemplateName;
	var int Cost;
	var int RequiredScience;
	var name AssociatedTech;
	var array<InventoryUpgrade> InventoryUpgrades;
	var array<name> RequiredTechUpgrades;
	var bool bStarting;
	var EUpgradeCategory Category;
	var array<name> RequiredMods;         // This is an OR. At least one mod in the list must be enabled for this upgrade to exist
	var array<name> IgnoreIfModsEnabled;  // This is an OR. If any mod in this list is enabled, then this upgrade will not exist
};