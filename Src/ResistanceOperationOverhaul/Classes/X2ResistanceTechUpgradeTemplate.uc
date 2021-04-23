class X2ResistanceTechUpgradeTemplate extends X2DataTemplate;

// var name DataName; from X2DataTemplate
var int Cost;
var int RequiredScience;
var name AssociatedTech;
var array<InventoryUpgrade> InventoryUpgrades;
var array<name> RequiredTechUpgrades;
var bool bStarting;
var EUpgradeCategory Category;

var localized string DisplayName;
var localized string Description;

function string GetRequirementsText()
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local name RequiredTech;
	local X2ResistanceTechUpgradeTemplate RequiredTemplate;
	local string Text;

	Text = "";
	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();

	foreach RequiredTechUpgrades (RequiredTech)
	{
		RequiredTemplate = TemplateManager.FindTemplate(RequiredTech);
		if (RequiredTemplate != none)
		{
			if (Text == "")
			{
				Text = class'UILadderSquadUpgradeScreen'.default.m_Requires @ RequiredTemplate.DisplayName;
			}
			else
			{
				Text = Text $ "," @ RequiredTemplate.DisplayName;
			}
		}
	}
	
	return Text;
}

function bool AtleastOneInventoryUpgradeExists()
{
	local InventoryUpgrade Upgrade;
	local X2ItemTemplateManager ItemTemplateManager;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach InventoryUpgrades (Upgrade)
	{
		if (ItemTemplateManager.FindItemTemplate(Upgrade.TemplateName) != none)
		{
			return true;
		}
	}

	return false;
}