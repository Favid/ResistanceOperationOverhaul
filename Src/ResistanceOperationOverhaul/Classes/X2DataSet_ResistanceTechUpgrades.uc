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
	eUpCat_PCS,
	eUpCat_Grenade,
	eUpCat_Ammo,
	eUpCat_Vest,
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

var config array<TechUpgrade> TechUpgrades;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local TechUpgrade Upgrade;
	local bool AtleastOneExists;
	local bool ShouldCreate;
	local name Mod;

	foreach default.TechUpgrades (Upgrade)
	{
		ShouldCreate = true;
		AtleastOneExists = false;
		foreach Upgrade.RequiredMods (Mod)
		{
			if (class'ResistanceOverhaulHelpers'.static.IsModInstalled(Mod))
			{
				AtleastOneExists = true;
				break;
			}
		}

		if (Upgrade.RequiredMods.Length > 0 && !AtleastOneExists)
		{
			ShouldCreate = false;
		}
		
		if (ShouldCreate)
		{
			foreach Upgrade.IgnoreIfModsEnabled (Mod)
			{
				if (class'ResistanceOverhaulHelpers'.static.IsModInstalled(Mod))
				{
					ShouldCreate = false;
					break;
				}
			}
		}

		if (ShouldCreate)
		{
			Templates.AddItem(CreateTemplate(Upgrade));
			`LOG("=== Created X2ResistanceTechUpgradeTemplate: " $ string(Upgrade.TemplateName));
		}
		else
		{
			`LOG("=== Ignoring X2ResistanceTechUpgradeTemplate: " $ string(Upgrade.TemplateName));
		}
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