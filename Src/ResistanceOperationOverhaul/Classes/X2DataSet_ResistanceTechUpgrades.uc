class X2DataSet_ResistanceTechUpgrades extends X2DataSet config(SoldierUpgrades);

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
			`LOG("Created X2ResistanceTechUpgradeTemplate: " $ string(Upgrade.TemplateName), class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
		}
		else
		{
			`LOG("Ignoring X2ResistanceTechUpgradeTemplate: " $ string(Upgrade.TemplateName), class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
		}
	}

	`LOG("Created this many templates: " $ string(Templates.Length), class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
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