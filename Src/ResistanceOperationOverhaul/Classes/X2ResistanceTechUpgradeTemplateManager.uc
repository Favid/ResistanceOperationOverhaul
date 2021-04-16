class X2ResistanceTechUpgradeTemplateManager extends X2DataTemplateManager;

static function X2ResistanceTechUpgradeTemplateManager GetTemplateManager()
{
	return X2ResistanceTechUpgradeTemplateManager(class'Engine'.static.GetTemplateManager(class'X2ResistanceTechUpgradeTemplateManager'));
}

function X2ResistanceTechUpgradeTemplate FindTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate( DataName );
	if (kTemplate != none)
	{
		return X2ResistanceTechUpgradeTemplate( kTemplate );
	}
	return none;
}

function array<name> GetStartingTemplates()
{
	local X2DataTemplate Template;
	local X2ResistanceTechUpgradeTemplate CastedTemplate;
	local array<name> TemplateNames;

	foreach IterateTemplates( Template, none )
	{
		CastedTemplate = X2ResistanceTechUpgradeTemplate(Template);
		if (CastedTemplate != none && CastedTemplate.bStarting)
		{
			TemplateNames.AddItem(CastedTemplate.DataName);
		}
	}

	return TemplateNames;
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2DataSet_ResistanceTechUpgrades'
	ManagedTemplateClass=class'X2ResistanceTechUpgradeTemplate'
}
