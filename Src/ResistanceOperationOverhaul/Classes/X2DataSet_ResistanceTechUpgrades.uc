class X2DataSet_ResistanceTechUpgrades extends X2DataSet config(SoldierUpgrades);

enum EUpgradeCategory
{
	eUpCat_Misc,
	eUpCat_Primary,
	eUpCat_Secondary,
	eUpCat_Heavy,
	eUpCat_Utility,
	eUpCat_Armor,
	eUpCat_Attachment,
	eUpCat_PCS
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
};

var config array<TechUpgrade> TechUpgrades;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local TechUpgrade Upgrade;

	foreach default.TechUpgrades (Upgrade)
	{
		Templates.AddItem(CreateTemplate(Upgrade));
	}

	`LOG("=== Created this many templates: " $ string(Templates.Length));
	return Templates;
}

private static function X2DataTemplate CreateTemplate(TechUpgrade Upgrade)
{
	local X2ResistanceTechUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ResistanceTechUpgradeTemplate', Template, Upgrade.TemplateName);

	Template.Cost = Upgrade.Cost;
	Template.RequiredScience = Upgrade.RequiredScience;
	Template.AssociatedTech = Upgrade.AssociatedTech;
	Template.InventoryUpgrades = Upgrade.InventoryUpgrades;
	Template.RequiredTechUpgrades = Upgrade.RequiredTechUpgrades;
	Template.bStarting = Upgrade.bStarting;
	Template.Category = Upgrade.Category;
	return Template;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = true
}