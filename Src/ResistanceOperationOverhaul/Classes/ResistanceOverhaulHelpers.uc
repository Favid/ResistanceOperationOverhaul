class ResistanceOverhaulHelpers extends Object config(LadderOptions);

var config bool bUseWeightedClassSelection;
var config int DEFAULT_CLASS_WEIGHT;
var config array<ClassWeight> ClassWeights;

static function XComGameState_Unit CreateSoldier(XComGameState GameState, XComGameState_Player XComPlayerState, SoldierOption Option, array<name> AllowedClasses, array<name> UsedClasses, array<string> UsedCharacters)
{
	local XComGameState_Unit Soldier;
	local name ChosenClass;
	local string ChosenCharacter;

	if (Option.bRandomClass)
	{
		ChosenClass = RandomlyChooseClass(AllowedClasses, UsedClasses);
	}
	else
	{
		ChosenClass = Option.ClassName;
	}

	if (UsedClasses.Find(ChosenClass) == INDEX_NONE)
	{
		UsedClasses.AddItem(ChosenClass);
	}

	if (Option.bRandomlyGeneratedCharacter)
	{
		ChosenCharacter = "";
	}
	else if (Option.bRandomCharacter)
	{
		ChosenCharacter = RandomlyChooseCharacter(ChosenClass, UsedCharacters);
	}
	else
	{
		ChosenCharacter = Option.CharacterPoolName;
	}

	if (ChosenCharacter != "" && UsedCharacters.Find(ChosenCharacter) == INDEX_NONE)
	{
		UsedCharacters.AddItem(ChosenCharacter);
	}
			
	Soldier = GenerateUnit(ChosenClass, ChosenCharacter, GameState, XComPlayerState);

	if (Soldier.GetMyTemplate().DataName == 'Soldier')
	{
		Soldier.RankUpSoldier(GameState, ChosenClass);
	}

	Soldier.ApplySquaddieLoadout(GameState);
	Soldier.ApplyBestGearLoadout(GameState);

	return Soldier;	
}


public static function name RandomlyChooseClass(array<name> AllowedClasses, array<name> DisallowedClasses)
{
	local name ChosenClass;
	local name AllowedClass;
	local array<name> RandomClassOptions;
	
	foreach AllowedClasses (AllowedClass)
	{
		if (DisallowedClasses.Find(AllowedClass) == INDEX_NONE)
		{
			RandomClassOptions.AddItem(AllowedClass);
		}
	}

	if (RandomClassOptions.Length > 0)
	{
		ChosenClass = default.bUseWeightedClassSelection ? GetWeightedRandomClass(RandomClassOptions)
			: RandomClassOptions[`SYNC_RAND_STATIC(RandomClassOptions.Length)];
	}
	else
	{
		// There are no valid classes left, so just pick one from the disallowed classes
		ChosenClass = default.bUseWeightedClassSelection ? GetWeightedRandomClass(DisallowedClasses)
			: DisallowedClasses[`SYNC_RAND_STATIC(DisallowedClasses.Length)];
	}

	return ChosenClass;
}

private static function name GetWeightedRandomClass(array<name> ClassOptions)
{
	local name ClassName;
	local int index;
	local int WeightSum;
	local int RandRoll;

	local array<ClassWeight> WeightedClassOptions;
	local ClassWeight Entry;

	// Build weighted class list
	foreach ClassOptions(ClassName)
	{
		Entry.ClassName = ClassName;

		// Check for manually specified weight
		index = default.ClassWeights.Find('ClassName', ClassName);

		Entry.Weight = index != INDEX_NONE ? default.ClassWeights[index].Weight
			: default.DEFAULT_CLASS_WEIGHT;

		WeightSum += Entry.Weight;
		WeightedClassOptions.AddItem(Entry);

		//`LOG("added" @ Entry.ClassName @ Entry.Weight);
	}

	RandRoll = `SYNC_RAND_STATIC(WeightSum);
	//`LOG("rolled" @ RandRoll @ WeightSum);

	// Loop over weighted list, rand(100) = [0, 99] -> 99 - 100 = -1
	foreach WeightedClassOptions(Entry)
	{
		RandRoll -= Entry.Weight;
		//`LOG("at" @ Entry.ClassName @ RandRoll);
		if (RandRoll < 0)
		{
			return Entry.ClassName;
		}
	}
}

private static function string RandomlyChooseCharacter(name ClassName, array<string> DisallowedCharacters)
{
	local CharacterPoolManager CharacterPoolMgr;
	local XComGameState_Unit Character;
	local array<string> RandomCharacterOptions;
	local X2SoldierClassTemplate ClassTemplate;
	local string ChosenCharacter;
	
	`LOG("RandomlyChooseCharacter");

	CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Classname);

	foreach CharacterPoolMgr.CharacterPool (Character)
	{
		`LOG("RandomlyChooseCharacter checking " $ Character.GetFullName());
		if (DisallowedCharacters.Find(Character.GetFullName()) == INDEX_NONE)
		{
			`LOG("RandomlyChooseCharacter not disallowed");
			if (CharacterIsValid(Character, ClassTemplate))
			{
				`LOG("RandomlyChooseCharacter adding to RandomCharacterOptions");
				RandomCharacterOptions.AddItem(Character.GetFullName());
			}
		}
	}

	if (RandomCharacterOptions.Length > 0)
	{
		ChosenCharacter = RandomCharacterOptions[`SYNC_RAND_STATIC(RandomCharacterOptions.Length)];
		`LOG("RandomlyChooseCharacter using " $ ChosenCharacter);
	}
	else
	{
		`LOG("RandomlyChooseCharacter using blank");
		// There are no valid characters left, so return a blank string to have the soldier be randomly generated
		ChosenCharacter = "";
	}

	return ChosenCharacter;
}

private static function bool CharacterIsValid(XComGameState_Unit Character, X2SoldierClassTemplate ClassTemplate)
{
	local bool bValid;

	`LOG("=== CharacterIsValid: ");
	`LOG("=== Character: " $ Character.GetFullName());
	`LOG("=== ClassTemplate: " $ string(ClassTemplate.DataName));

	bValid = false;
	if (Character != none && Character.bAllowedTypeSoldier)
	{
		if (Character.GetMyTemplate().DataName == 'Soldier' && 
			(ClassTemplate.AcceptedCharacterTemplates.Length == 0 || ClassTemplate.AcceptedCharacterTemplates.Find('Soldier') != INDEX_NONE) &&
			(ClassTemplate.RequiredCharacterClass == '' || ClassTemplate.RequiredCharacterClass == 'Soldier'))
		{
			// Character is a generic Soldier, and either the class is not restricted, or the class allows Soldiers
			bValid = true;
			`LOG("=== Valid because character is a generic Soldier, and either the class is not restricted, or the class allows Soldiers");
		}
		else if (Character.GetMyTemplate().DataName != 'Soldier' &&
			ClassTemplate.AcceptedCharacterTemplates.Find(Character.GetMyTemplate().DataName) != INDEX_NONE || ClassTemplate.RequiredCharacterClass == Character.GetMyTemplate().DataName)
		{
			// Character is of a special type, and the class allows that type
			bValid = true;
			`LOG("=== Valid because character is of a special type, and the class allows that type");
		}
	}

	if (!bValid)
	{
		`LOG("=== Invalid");
	}
	
	`LOG("===");

	return bValid;
}

private static function XComGameState_Unit GenerateUnit(name ClassName, string CharacterName, XComGameState GameState, XComGameState_Player XComPlayerState)
{
	local X2SoldierClassTemplate ClassTemplate;
	local X2CharacterTemplate CharTemplate;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_Unit BuildUnit;
	local TSoldier Soldier;
	local XComGameState_HeadquartersXCom HeadquartersStateObject;
	local name RequiredLoadout;
	local CharacterPoolManager CharacterPoolMgr;
	local XComGameState_Unit Character;
	local name AcceptedCharacterTemplate;
	
	`LOG("GenerateUnit");
	`LOG("GenerateUnit ClassName: " $ string(ClassName));
	`LOG("GenerateUnit CharacterName: " $ CharacterName);
	
	CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
	Character = CharacterPoolMgr.GetCharacter(CharacterName);

	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Classname);
	`assert(ClassTemplate != none);

	CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate((ClassTemplate.RequiredCharacterClass != '') ? ClassTemplate.RequiredCharacterClass : 'Soldier');
	`assert(CharTemplate != none);
	CharacterGenerator = `XCOMGRI.Spawn(CharTemplate.CharacterGeneratorClass);
	`assert(CharacterGenerator != None);

	BuildUnit = CharTemplate.CreateInstanceFromTemplate(GameState);
	BuildUnit.bRolledForAWCAbility = false;	// Do not allow AWC abilities to be added to skirmish units
	BuildUnit.SetSoldierClassTemplate(ClassTemplate.DataName);
	BuildUnit.SetControllingPlayer(XComPlayerState.GetReference());
	
	`LOG("GenerateUnit Character == none: " $ string(Character == none));
	if (Character != none)
	{
		`LOG("GenerateUnit Character.GetMyTemplate().DataName: " $ Character.GetMyTemplate().DataName);

		foreach ClassTemplate.AcceptedCharacterTemplates (AcceptedCharacterTemplate)
		{
			`LOG("GenerateUnit AcceptedCharacterTemplate: " $ string(AcceptedCharacterTemplate));
		}
	}
	
	if (CharacterName == "" || !CharacterIsValid(Character, ClassTemplate))
	{
		// Randomly roll what the character looks like
		`LOG("GenerateUnit randomly rolling");
		Soldier = CharacterGenerator.CreateTSoldier();
		BuildUnit.SetTAppearance(Soldier.kAppearance);
		BuildUnit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
		BuildUnit.SetCountry(Soldier.nmCountry);
		if (!BuildUnit.HasBackground())
			BuildUnit.GenerateBackground(, CharacterGenerator.BioCountryName);
	}
	else
	{
		// Use the character pool soldier for the appearance
		`LOG("GenerateUnit using character");
		BuildUnit.SetTAppearance(Character.kAppearance);
		BuildUnit.SetCharacterName(Character.GetFirstName(), Character.GetLastName(), Character.GetNickName(true));
		BuildUnit.SetCountry(Character.GetCountry());
		BuildUnit.SetBackground(Character.GetBackground());
	}
	
	HeadquartersStateObject = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	HeadquartersStateObject.Squad.AddItem(BuildUnit.GetReference());
	HeadquartersStateObject.AddToCrewNoStrategy(BuildUnit);

	RequiredLoadout = CharTemplate.RequiredLoadout;
	if (RequiredLoadout != '')
	{
		BuildUnit.ApplyInventoryLoadout(GameState, RequiredLoadout);
	}

	CharacterGenerator.Destroy( );

	return BuildUnit;
}

static function bool IsModInstalled(name X2DCIName)
{
	local X2DownloadableContentInfo Mod;

	foreach `ONLINEEVENTMGR.m_cachedDLCInfos (Mod)
	{
		if (Mod.Class.Name == X2DCIName)
		{
			return true;
		}
	}
	return false;
}