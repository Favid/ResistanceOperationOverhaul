class UITLE_LadderModeMenu_Override extends UITLE_LadderModeMenu config (LadderOptions);

enum EUILadderScreenState
{
	eUILadderScreenState_Base,
	eUILadderScreenState_CustomSettings,
	eUILadderScreenState_AllowedClasses,
	eUILadderScreenState_AdvancedOptions,
	eUILadderScreenState_Save,
	eUILadderScreenState_Load,
	eUILadderScreenState_Squad,
	eUILadderScreenState_Soldier
};

var config int SQUAD_SIZE_MIN;
var config int SQUAD_SIZE_MAX;

var config int LADDER_LENGTH_MIN;
var config int LADDER_LENGTH_MAX;

var config int FORCE_LEVEL_MIN;
var config int FORCE_LEVEL_MAX;

var config int ALERT_LEVEL_MIN;
var config int ALERT_LEVEL_MAX;

var int NEW_MENU_LEFT;
var int NEW_MENU_TOP;
var int NEW_MENU_WIDTH;
var int NEW_MENU_HEIGHT;

var config array<name> SecondWaveOptionsToDisable;
var config array<name> ClassesToHide;

var localized string m_EnableModText;
var localized string m_SquadText;
var localized string m_LadderLengthText;
var localized string m_SelectAllowedClassesText;
var localized string m_SelectAdvancedOptionsText;
var localized string m_AllowDuplicateClassesText;
var localized string m_ForceLevelStartText;
var localized string m_ForceLevelEndText;
var localized string m_AlertLevelStartText;
var localized string m_AlertLevelEndText;
var localized string m_SaveText;
var localized string m_LoadText;

var localized string m_EnableModTooltip;
var localized string m_SquadTooltip;
var localized string m_LadderLengthTooltip;
var localized string m_SelectAllowedClassesTooltip;
var localized string m_SelectAdvancedOptionsTooltip;
var localized string m_AllowDuplicateClassesTooltip;
var localized string m_ForceLevelStartTooltip;
var localized string m_ForceLevelEndTooltip;
var localized string m_AlertLevelStartTooltip;
var localized string m_AlertLevelEndTooltip;
var localized string m_SaveTooltip;
var localized string m_LoadTooltip;

var localized string m_NewSaveText;
var localized string m_NewSaveDialogTitle;

var localized string m_NewSoldierText;
var localized string m_RemoveSoldierText;
var localized string m_SoldierCharacterPool;
var localized string m_SoldierClass;
var localized string m_SoldierStartingMission;

var localized string m_SoldierRandomlyGeneratedCharacter;
var localized string m_SoldierRandomCharacter;
var localized string m_SoldierRandomClass;

var int CustomListLastSelectedIndex;
var UIList CustomList;
var EUILadderScreenState UIScreenState;
var LadderSettings Settings;
var array<X2SoldierClassTemplate> MasterClassList;
var int SelectedSoldierIndex;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local X2SoldierClassTemplate ClassTemplate;
	local int Index;
	local SoldierOption Soldier;

	super.InitScreen(InitController, InitMovie, InitName);
	
	NEW_MENU_LEFT = 900;
	NEW_MENU_TOP = 310;
	NEW_MENU_WIDTH = 600;
	NEW_MENU_HEIGHT = 530;

	CustomList = Spawn(class'UIList', self);
	CustomList.InitList('CustomList', NEW_MENU_LEFT, NEW_MENU_TOP, NEW_MENU_WIDTH, NEW_MENU_HEIGHT);
	CustomList.bStickyClickyHighlight = false;
	CustomList.bPermitNavigatorToDefocus = true;
	CustomList.Navigator.LoopSelection = true;
	CustomList.Navigator.LoopOnReceiveFocus = true;
	CustomList.Navigator.SelectFirstAvailable();
	CustomList.EnableNavigation();
	CustomList.OnSetSelectedIndex = OnSetSelectedIndex;

	// Set default ladder settings
	Settings.AllowDuplicateClasses = false;
	Settings.LadderLength = class'XComGameState_LadderProgress'.default.DefaultSize;
	Settings.ForceLevelStart = 3;
	Settings.ForceLevelEnd = 20;
	Settings.AlertLevelStart = 1;
	Settings.AlertLevelEnd = 4;
	
	// Get all classes except for special ones like Rookie or Shen
	MasterClassList = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().GetAllSoldierClassTemplates();
	for (Index = MasterClassList.Length -1; Index >= 0; Index--)
	{
		if (MasterClassList[Index].bHideInCharacterPool || MasterClassList[Index].DataName == 'Rookie' || default.ClassesToHide.Find(MasterClassList[Index].DataName) != INDEX_NONE)
		{
			MasterClassList.Remove(Index, 1);
		}
	}

	// Start with all classes being allowed
	foreach MasterClassList (ClassTemplate)
	{
		Settings.AllowedClasses.AddItem(ClassTemplate.DataName);
	}

	// Start with the default squad - 4 random soldiers at the start, with others joining at missions 2 and 4
	Soldier.bRandomlyGeneratedCharacter = true;
	Soldier.bRandomClass = true;
	Soldier.StartingMission = 1;
	Settings.SoldierOptions.AddItem(Soldier);
	Settings.SoldierOptions.AddItem(Soldier);
	Settings.SoldierOptions.AddItem(Soldier);
	Settings.SoldierOptions.AddItem(Soldier);
	Soldier.StartingMission = 2;
	Settings.SoldierOptions.AddItem(Soldier);
	Soldier.StartingMission = 4;
	Settings.SoldierOptions.AddItem(Soldier);

	UIScreenState = eUILadderScreenState_Base;
	UpdateCustomListData();
}

simulated function OnSetSelectedIndex(UIList ContainerList, int ItemIndex)
{
	if (UIScreenState == eUILadderScreenState_Squad)
	{
		if (ItemIndex == 0)
		{
			// Add new unit was selected, so set selected index to the end of the soldier options list
			SelectedSoldierIndex = Settings.SoldierOptions.Length;
		}
		else
		{
			SelectedSoldierIndex = ItemIndex - 1;
		}
	}
}

// Overriding the base class's OnSelectedChange - this is for the List on the left
simulated function OnSelectedChange(UIList ContainerList, int ItemIndex)
{
	if (ContainerList == List && ItemIndex == 0)
	{
		UIScreenState = eUILadderScreenState_CustomSettings;
	}
	else
	{
		UIScreenState = eUILadderScreenState_Base;
	}
	
	UpdateCustomListData();

	super.OnSelectedChange(ContainerList, ItemIndex);
}

simulated function UpdateCustomListData()
{
	HideListItems();
	
	switch (UIScreenState)
	{
	case eUILadderScreenState_Base:
		// The vanilla screen
		UpdateCustomListDataBase();
		break;
	case eUILadderScreenState_CustomSettings:
		UpdateCustomListDataCustomSettings();
		break;
	case eUILadderScreenState_AllowedClasses:
		UpdateCustomListDataAllowedClasses();
		break;
	case eUILadderScreenState_AdvancedOptions:
		UpdateCustomListDataAdvancedOptions();
		break;
	case eUILadderScreenState_Squad:
		UpdateCustomListDataSquad();
		break;
	case eUILadderScreenState_Soldier:
		UpdateCustomListDataSoldier();
		break;
	case eUILadderScreenState_Save:
		UpdateCustomListDataSave();
		break;
	case eUILadderScreenState_Load:
		UpdateCustomListDataLoad();
		break;
	};

	if( CustomList.IsSelectedNavigation() )
		CustomList.Navigator.SelectFirstAvailable();
}

function UIMechaListItem GetListItem(int ItemIndex, optional bool bDisableItem, optional string DisabledReason)
{
	local UIMechaListItem CustomizeItem;
	local UIPanel Item;

	if (ItemIndex >= CustomList.ItemContainer.ChildPanels.Length)
	{
		CustomizeItem = Spawn(class'UIMechaListItem', CustomList.itemContainer);
		CustomizeItem.bAnimateOnInit = false;
		CustomizeItem.InitListItem(, , 400);
	}
	else
	{
		Item = CustomList.GetItem(ItemIndex);
		CustomizeItem = UIMechaListItem(Item);
	}
	
	return CustomizeItem;
}

simulated function HideListItems()
{
	local int Index;

	for (Index = 0; Index < CustomList.ItemCount; Index++)
	{
		CustomList.GetItem(Index).Destroy();
	}
	CustomList.ClearItems();
}

simulated function UpdateCustomListDataBase()
{
	CustomList.SetVisible(false);
}

simulated function UpdateCustomListDataCustomSettings()
{
	local int Index;

	Index = 0;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Checkbox);
	GetListItem(Index).UpdateDataCheckbox(m_EnableModText, "", Settings.UseCustomSettings, OnEnableCustomSettingsToggled);
	GetListItem(Index).BG.SetTooltipText(m_EnableModTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SquadText, "", OnClickSquad);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_SquadTooltip);
	GetListItem(Index).BG.SetTooltipText(m_SquadTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SelectAllowedClassesText, "", OnClickSelectAllowedClasses);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_SelectAllowedClassesTooltip);
	GetListItem(Index).BG.SetTooltipText(m_SelectAllowedClassesTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Checkbox);
	GetListItem(Index).UpdateDataCheckbox(m_AllowDuplicateClassesText, "", Settings.AllowDuplicateClasses, OnAllowDuplicateClassesToggled);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_AllowDuplicateClassesTooltip);
	GetListItem(Index).BG.SetTooltipText(m_AllowDuplicateClassesTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Spinner);
	GetListItem(Index).UpdateDataSpinner(m_LadderLengthText, string(Settings.LadderLength), LadderLengthSpinnerSpinned);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_LadderLengthTooltip);
	GetListItem(Index).BG.SetTooltipText(m_LadderLengthTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Spinner);
	GetListItem(Index).UpdateDataSpinner(m_ForceLevelStartText, string(Settings.ForceLevelStart), ForceLevelStartSpinnerSpinned);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_ForceLevelStartTooltip);
	GetListItem(Index).BG.SetTooltipText(m_ForceLevelStartTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Spinner);
	GetListItem(Index).UpdateDataSpinner(m_ForceLevelEndText, string(Settings.ForceLevelEnd), ForceLevelEndSpinnerSpinned);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_ForceLevelEndTooltip);
	GetListItem(Index).BG.SetTooltipText(m_ForceLevelEndTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Spinner);
	GetListItem(Index).UpdateDataSpinner(m_AlertLevelStartText, string(Settings.AlertLevelStart), AlertLevelStartSpinnerSpinned);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_AlertLevelStartTooltip);
	GetListItem(Index).BG.SetTooltipText(m_AlertLevelStartTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Spinner);
	GetListItem(Index).UpdateDataSpinner(m_AlertLevelEndText, string(Settings.AlertLevelEnd), AlertLevelEndSpinnerSpinned);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_AlertLevelEndTooltip);
	GetListItem(Index).BG.SetTooltipText(m_AlertLevelEndTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SelectAdvancedOptionsText, "", OnClickSelectAdvancedOptions);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_SelectAdvancedOptionsTooltip);
	GetListItem(Index).BG.SetTooltipText(m_SelectAdvancedOptionsTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SaveText, "", OnClickSave);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_SaveTooltip);
	GetListItem(Index).BG.SetTooltipText(m_SaveTooltip, , , 10, , , , 0.0f);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_LoadText, "", OnClickLoad);
	GetListItem(Index).SetDisabled(!Settings.UseCustomSettings, m_LoadTooltip);
	GetListItem(Index).BG.SetTooltipText(m_LoadTooltip, , , 10, , , , 0.0f);
	Index++;
	
	CustomList.SetVisible(true);
}

simulated function OnEnableCustomSettingsToggled(UICheckbox checkboxControl)
{
	Settings.UseCustomSettings = checkboxControl.bChecked;
	UIScreenState = eUILadderScreenState_CustomSettings;
	UpdateCustomListData();
}

simulated function OnClickSquad()
{
	UIScreenState = eUILadderScreenState_Squad;
	UpdateCustomListData();
}

simulated function OnClickSelectAllowedClasses()
{
	UIScreenState = eUILadderScreenState_AllowedClasses;
	UpdateCustomListData();
}

simulated function OnAllowDuplicateClassesToggled(UICheckbox checkboxControl)
{
	Settings.AllowDuplicateClasses = checkboxControl.bChecked;
}

simulated function LadderLengthSpinnerSpinned(UIListItemSpinner SpinnerPanel, int Direction)
{
	local int CurrentValue;
	local int NewValue;
	local int MissionIndex;

	CurrentValue = int(SpinnerPanel.value);
	NewValue = CurrentValue + Direction;

	if (NewValue >= default.LADDER_LENGTH_MIN && NewValue <= default.LADDER_LENGTH_MAX)
	{
		SpinnerPanel.SetValue(string(NewValue));
		Settings.LadderLength = NewValue;

		for (MissionIndex = 0; MissionIndex < Settings.LadderLength; MissionIndex++)
		{
			mc.BeginFunctionOp("SetMissionNode");
			mc.QueueNumber(MissionIndex);
			if (MissionIndex == 0)
			{
				mc.QueueNumber(1);
			}
			else
			{
				mc.QueueNumber(0);
			}
			mc.EndOp();
		}
	}
}

simulated function ForceLevelStartSpinnerSpinned( UIListItemSpinner SpinnerPanel, int Direction )
{
	local int CurrentValue;
	local int NewValue;

	CurrentValue = int(SpinnerPanel.value);
	NewValue = CurrentValue + Direction;
	
	if (NewValue >= default.FORCE_LEVEL_MIN && NewValue <= default.FORCE_LEVEL_MAX)
	{
		SpinnerPanel.SetValue(string(NewValue));
		Settings.ForceLevelStart = NewValue;
	}
}

simulated function ForceLevelEndSpinnerSpinned( UIListItemSpinner SpinnerPanel, int Direction )
{
	local int CurrentValue;
	local int NewValue;

	CurrentValue = int(SpinnerPanel.value);
	NewValue = CurrentValue + Direction;
	
	if (NewValue >= default.FORCE_LEVEL_MIN && NewValue <= default.FORCE_LEVEL_MAX)
	{
		SpinnerPanel.SetValue(string(NewValue));
		Settings.ForceLevelEnd = NewValue;
	}
}

simulated function AlertLevelStartSpinnerSpinned( UIListItemSpinner SpinnerPanel, int Direction )
{
	local int CurrentValue;
	local int NewValue;

	CurrentValue = int(SpinnerPanel.value);
	NewValue = CurrentValue + Direction;
	
	if (NewValue >= default.ALERT_LEVEL_MIN && NewValue <= default.ALERT_LEVEL_MAX)
	{
		SpinnerPanel.SetValue(string(NewValue));
		Settings.AlertLevelStart = NewValue;
	}
}

simulated function AlertLevelEndSpinnerSpinned( UIListItemSpinner SpinnerPanel, int Direction )
{
	local int CurrentValue;
	local int NewValue;

	CurrentValue = int(SpinnerPanel.value);
	NewValue = CurrentValue + Direction;
	
	if (NewValue >= default.ALERT_LEVEL_MIN && NewValue <= default.ALERT_LEVEL_MAX)
	{
		SpinnerPanel.SetValue(string(NewValue));
		Settings.AlertLevelEnd = NewValue;
	}
}

simulated function OnClickSelectAdvancedOptions()
{
	UIScreenState = eUILadderScreenState_AdvancedOptions;
	UpdateCustomListData();
}

simulated function OnClickSave()
{
	UIScreenState = eUILadderScreenState_Save;
	UpdateCustomListData();
}

simulated function OnClickLoad()
{
	UIScreenState = eUILadderScreenState_Load;
	UpdateCustomListData();
}

simulated function UpdateCustomListDataAllowedClasses()
{
	local int Index;
	local X2SoldierClassTemplate ClassTemplate;
	local bool bAllowed;

	Index = 0;

	foreach MasterClassList (ClassTemplate)
	{
		bAllowed = Settings.AllowedClasses.Find(ClassTemplate.DataName) != INDEX_NONE;
		
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).SetWidgetType(EUILineItemType_Checkbox);
		GetListItem(Index).UpdateDataCheckbox(ClassTemplate.DisplayName, "", bAllowed, OnAllowedClassToggled);
		GetListItem(Index).metadataString = string(ClassTemplate.DataName);
		Index++;
	}
}

simulated function OnAllowedClassToggled(UICheckbox checkboxControl)
{
	local int Index;
	local name ClassDataName;

	for (Index = 0; Index < CustomList.ItemCount; Index++)
	{
		if (GetListItem(Index).Checkbox == checkboxControl)
		{
			ClassDataName = name(GetListItem(Index).metadataString);
			break;
		}
	}

	if (checkboxControl.bChecked && Settings.AllowedClasses.Find(ClassDataName) == INDEX_NONE)
	{
		Settings.AllowedClasses.AddItem(ClassDataName);
	}
	else if (!checkboxControl.bChecked && Settings.AllowedClasses.Find(ClassDataName) != INDEX_NONE)
	{
		Settings.AllowedClasses.RemoveItem(ClassDataName);
	}
}

simulated function UpdateCustomListDataAdvancedOptions()
{
	local int Index;
	local bool bEnabled;
	local name SecondWaveOption;

	for (Index = 0; Index < class'UIShellDifficulty'.default.SecondWaveOptions.length; Index++)
	{
		SecondWaveOption = class'UIShellDifficulty'.default.SecondWaveOptions[Index].ID;
		bEnabled = Settings.SecondWaveOptions.Find(SecondWaveOption) != INDEX_NONE;
		
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).SetWidgetType(EUILineItemType_Checkbox);
		GetListItem(Index).UpdateDataCheckbox(class'UIShellDifficulty'.default.SecondWaveDescriptions[Index], "", bEnabled, OnSecondWaveOptionToggled);
		GetListItem(Index).metadataString = string(SecondWaveOption);

		if (default.SecondWaveOptionsToDisable.Find(SecondWaveOption) != INDEX_NONE)
		{
			GetListItem(Index).SetDisabled(true);
		}
	}
}

simulated function OnSecondWaveOptionToggled(UICheckbox checkboxControl)
{
	local int Index;
	local name OptionName;

	for (Index = 0; Index < CustomList.ItemCount; Index++)
	{
		if (GetListItem(Index).Checkbox == checkboxControl)
		{
			OptionName = name(GetListItem(Index).metadataString);
			break;
		}
	}

	if (checkboxControl.bChecked && Settings.SecondWaveOptions.Find(OptionName) == INDEX_NONE)
	{
		Settings.SecondWaveOptions.AddItem(OptionName);
	}
	else if (!checkboxControl.bChecked && Settings.SecondWaveOptions.Find(OptionName) != INDEX_NONE)
	{
		Settings.SecondWaveOptions.RemoveItem(OptionName);
	}
}

simulated function UpdateCustomListDataSquad()
{
	local int Index;
	local int SoldierIndex;
	local SoldierOption Option;
	local X2SoldierClassTemplate ClassTemplate;
	local string CharacterText;
	local string ClassText;
	
	if (Settings.SoldierOptions.Length < default.SQUAD_SIZE_MAX)
	{
		GetListItem(0).EnableNavigation();
		GetListItem(0).UpdateDataValue(m_NewSoldierText, "", OnClickAddSoldier);
		Index++;
	}

	for (SoldierIndex = 0; SoldierIndex < Settings.SoldierOptions.Length; SoldierIndex++)
	{
		Option = Settings.SoldierOptions[SoldierIndex];

		if (Option.bRandomCharacter)
		{
			CharacterText = m_SoldierRandomCharacter;
		}
		else if (Option.bRandomlyGeneratedCharacter)
		{
			CharacterText = m_SoldierRandomlyGeneratedCharacter;
		}
		else
		{
			CharacterText = Option.CharacterPoolName;
		}

		CharacterText = string(Option.StartingMission) @ CharacterText;

		if (Option.bRandomClass)
		{
			ClassText = m_SoldierRandomClass;
		}
		else
		{
			ClassText = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Option.ClassName).DisplayName;
		}

		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(CharacterText, ClassText, OnClickSoldier);
		Index++;
	}
}

simulated function OnClickAddSoldier()
{
	local SoldierOption Option;

	Option.bRandomlyGeneratedCharacter = true;
	Option.bRandomClass = true;
	Option.StartingMission = 1;
	Settings.SoldierOptions.AddItem(Option);

	UIScreenState = eUILadderScreenState_Soldier;
	UpdateCustomListData();
}

simulated function OnClickSoldier()
{
	UIScreenState = eUILadderScreenState_Soldier;
	UpdateCustomListData();
}

simulated function UpdateCustomListDataSoldier()
{
	local int Index;
	local SoldierOption Option;
	local X2SoldierClassTemplate ClassTemplate;
	local array<string> ClassOptions;
	local int ClassIndex;
	local int SelectedClassIndex;
	local CharacterPoolManager CharacterPoolMgr;
	local array<string> CharacterOptions;
	local int CharacterIndex;
	local int SelectedCharacterIndex;
	local XComGameState_Unit Character;

	Option = Settings.SoldierOptions[SelectedSoldierIndex];

	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_RemoveSoldierText, "", OnClickRemoveSoldier);
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Spinner);
	GetListItem(Index).UpdateDataSpinner(m_SoldierStartingMission, string(Option.StartingMission), StartingMissionSpinnerSpinned);
	Index++;

	SelectedClassIndex = 0;
	ClassOptions.AddItem(m_SoldierRandomClass);
	for (ClassIndex = 0; ClassIndex < MasterClassList.Length; ClassIndex++)
	{
		ClassTemplate = MasterClassList[ClassIndex];
		ClassOptions.AddItem(ClassTemplate.DisplayName);

		if (!Option.bRandomClass && ClassTemplate.DataName == Option.ClassName)
		{
			SelectedClassIndex = ClassIndex + 1;
		}
	}
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Dropdown);
	GetListItem(Index).UpdateDataDropdown(m_SoldierClass, ClassOptions, SelectedClassIndex, OnClassDropdownSelectionChanges);
	GetListItem(Index).MoveToHighestDepth();
	Index++;
	
	CharacterOptions.AddItem(m_SoldierRandomlyGeneratedCharacter);
	CharacterOptions.AddItem(m_SoldierRandomCharacter);
	if (Option.bRandomlyGeneratedCharacter)
	{
		SelectedCharacterIndex = 0;
	}
	else if (Option.bRandomCharacter)
	{
		SelectedCharacterIndex = 1;
	}
	
	CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
	for (CharacterIndex = 0; CharacterIndex < CharacterPoolMgr.CharacterPool.Length; CharacterIndex++)
	{
		Character = CharacterPoolMgr.CharacterPool[CharacterIndex];
		CharacterOptions.AddItem(Character.GetFullName());

		if (!Option.bRandomlyGeneratedCharacter && !Option.bRandomCharacter && Character.GetFullName() == Option.CharacterPoolName)
		{
			SelectedCharacterIndex = CharacterIndex + 2;
		}
	}
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Dropdown);
	GetListItem(Index).UpdateDataDropdown(m_SoldierCharacterPool, CharacterOptions, SelectedCharacterIndex, OnCharacterDropdownSelectionChanges);
	Index++;
}

simulated function OnClickRemoveSoldier()
{
	Settings.SoldierOptions.Remove(SelectedSoldierIndex, 1);

	UIScreenState = eUILadderScreenState_Squad;
	UpdateCustomListData();
}

simulated function OnClassDropdownSelectionChanges(UIDropdown DropdownControl)
{
	if (DropdownControl.SelectedItem == 0)
	{
		// Random is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass = true;
		Settings.SoldierOptions[SelectedSoldierIndex].ClassName = '';
	}
	else
	{
		// Actual class is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass = false;
		Settings.SoldierOptions[SelectedSoldierIndex].ClassName = MasterClassList[DropdownControl.SelectedItem - 1].DataName;
	}
}

simulated function OnCharacterDropdownSelectionChanges(UIDropdown DropdownControl)
{
	local CharacterPoolManager CharacterPoolMgr;

	if (DropdownControl.SelectedItem == 0)
	{
		// Randomly generated character is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter = true;
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName = "";
	}
	else if (DropdownControl.SelectedItem == 1)
	{
		// Random character is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter = true;
		Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName = "";
	}
	else
	{
		// Actual character is selected
		CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName = CharacterPoolMgr.CharacterPool[DropdownControl.SelectedItem - 2].GetFullName();
	}
}

simulated function StartingMissionSpinnerSpinned(UIListItemSpinner SpinnerPanel, int Direction)
{
	local int CurrentValue;
	local int NewValue;

	CurrentValue = int(SpinnerPanel.value);
	NewValue = CurrentValue + Direction;

	if (NewValue >= default.LADDER_LENGTH_MIN && NewValue <= default.LADDER_LENGTH_MAX)
	{
		SpinnerPanel.SetValue(string(NewValue));
		Settings.SoldierOptions[SelectedSoldierIndex].StartingMission = NewValue;
	}
}

simulated function UpdateCustomListDataSave()
{
	local int Index;
	local int SaveIndex;
	local array<string> SaveDisplays;
	local array<name> SaveFileNames;

	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_NewSaveText, "", OnClickNewSave);
	Index++;
	
	class'ResistanceHistorySavePairs'.static.GetHistory(SaveFileNames, SaveDisplays);

	for (SaveIndex = 0; SaveIndex < SaveFileNames.Length; SaveIndex++)
	{
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(SaveDisplays[SaveIndex], "", , , OnClickExistingSave);
		GetListItem(Index).metadataString = SaveDisplays[SaveIndex];
		Index++;
	}
}

simulated function OnClickNewSave()
{
	local TInputDialogData DialogData;
	
	DialogData.strTitle = m_NewSaveDialogTitle;
	DialogData.iMaxChars = class'XComCharacterCustomization'.const.NICKNAME_NAME_MAX_CHARS;
	DialogData.strInputBoxText = "Save" @ (class'ResistanceHistorySavePairs'.default.HistorySaveIndex + 1);
	DialogData.fnCallback = OnNameInputBoxClosed;

	Movie.Pres.UIInputDialog(DialogData);
}

function OnNameInputBoxClosed(string Text)
{
	if (Text != "")
	{
		class'ResistanceHistorySavePairs'.static.SaveHistory(Text, Settings);
	}

	UIScreenState = eUILadderScreenState_CustomSettings;
	UpdateCustomListData();
}

simulated function OnClickExistingSave(UIMechaListItem MechaItem)
{
	class'ResistanceHistorySavePairs'.static.SaveHistory(MechaItem.metadataString, Settings);

	UIScreenState = eUILadderScreenState_CustomSettings;
	UpdateCustomListData();
}

simulated function UpdateCustomListDataLoad()
{
	local int Index;
	local array<string> SaveDisplays;
	local array<name> SaveFileNames;
	
	class'ResistanceHistorySavePairs'.static.GetHistory(SaveFileNames, SaveDisplays);

	for (Index = 0; Index < SaveFileNames.Length; Index++)
	{
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(SaveDisplays[Index], "", , , OnClickLoadFile);
		GetListItem(Index).metadataString = string(SaveFileNames[Index]);
	}
}

simulated function OnClickLoadFile(UIMechaListItem MechaItem)
{
	local LadderSettings LoadedSettings;

	LoadedSettings = class'ResistanceHistorySavePairs'.static.GetFileSettings(name(MechaItem.metadataString));
	if (LoadedSettings.UseCustomSettings)
	{
		Settings = LoadedSettings;
	}

	UIScreenState = eUILadderScreenState_CustomSettings;
	UpdateCustomListData();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	// TODO

	// always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

simulated public function OnCancel()
{
	switch (UIScreenState)
	{
	case eUILadderScreenState_Base:
	case eUILadderScreenState_CustomSettings:
		super.OnCancel();
		break;
	case eUILadderScreenState_AllowedClasses:
	case eUILadderScreenState_AdvancedOptions:
	case eUILadderScreenState_Squad:
	case eUILadderScreenState_Save:
	case eUILadderScreenState_Load:
		UIScreenState = eUILadderScreenState_CustomSettings;
		UpdateCustomListData();
		break;
	case eUILadderScreenState_Soldier:
		UIScreenState = eUILadderScreenState_Squad;
		UpdateCustomListData();
		break;
	};
}

simulated function RefreshButtonHelpLabels(int LadderIndex)
{
	super.RefreshButtonHelpLabels(LadderIndex);

	// Ladders are started with the Start button instead of A for controllers now, so updated button text accordingly
	if (HasLadderSave(LadderIndex)) // We are continuing a ladder
	{
		if( `ISCONTROLLERACTIVE )
		{
			mc.FunctionString("SetContinueButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_START, 26, 26, -10) @ m_strContinueLadder);
		}
	}
	else // Starting a fresh ladder 
	{
		if( `ISCONTROLLERACTIVE )
		{
			mc.FunctionString("SetContinueButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_START, 26, 26, -10) @ m_strBeginLadder);
		}
	}
}

simulated function CreateNewLadder(int LadderDifficulty, bool NarrativesOn)
{
	local XComOnlineProfileSettings Profile;
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState TacticalStartState;
	local XComGameState_LadderProgress_Override LadderData;
	local string MissionType;
	local XComGameState_CampaignSettings CampaignSettings;
	local array<name> SquadMembers;
	local XComGameState_HeadquartersXCom HeadquartersStateObject;
	local XComGameState_BattleData BattleDataState;
	local XComTacticalMissionManager  TacticalMissionManager;
	local MissionDefinition MissionDef;
	local XComParcelManager ParcelManager;
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local X2MissionTemplate MissionTemplate;
	local X2MissionTemplateManager MissionTemplateManager;
	local XComGameState_Player AddPlayerState;
	local XComGameState_Player XComPlayerState;
	local WorldInfo LocalWorldInfo;
	local int Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond;
	local string TimeStamp;
	local PlotTypeDefinition PlotType;
	local XComGameState_MissionSite MissionSite;

	`ONLINEEVENTMGR.ClearUpdateSaveListCompleteDelegate( OnReadSaveGameListComplete );

	LocalWorldInfo = class'Engine'.static.GetCurrentWorldInfo();

	LocalWorldInfo.GetSystemTime( Year, Month, DayOfWeek, Day, Hour, Minute, Second, Millisecond );
	class'XComOnlineEventMgr'.static.FormatTimeStampSingleLine12HourClock( TimeStamp, Year, Month, Day, Hour, Minute );

	Profile = `XPROFILESETTINGS;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();

	History = `XCOMHISTORY;
	History.ResetHistory(, false);

	// Grab the start state from the profile
	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	TacticalStartState = History.CreateNewGameState(false, TacticalStartContext);

	class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart( 
		TacticalStartState, 
		, 
		,
		,
		,
		`CampaignDifficultySetting,
		`TacticalDifficultySetting,
		`StrategyDifficultySetting,
		`GameLengthSetting);

	History.AddGameStateToHistory(TacticalStartState);

	//Add basic states to the start state ( battle, players, abilities, etc. )
	BattleDataState = XComGameState_BattleData(TacticalStartState.CreateNewStateObject(class'XComGameState_BattleData'));	
	BattleDataState.iLevelSeed = class'Engine'.static.GetEngine().GetSyncSeed();

	XComPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_XCom);
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_Alien);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_Neutral);
	BattleDataState.CivilianPlayerRef = AddPlayerState.GetReference();

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_TheLost);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_Resistance);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	TacticalStartState.CreateNewStateObject(class'XComGameState_Cheats');

	++Profile.Data.m_Ladders;
	`ONLINEEVENTMGR.SaveProfileSettings();

	LadderData = XComGameState_LadderProgress_Override( TacticalStartState.CreateNewStateObject( class'XComGameState_LadderProgress_Override' ) );

	LadderData.bNewLadder = true;
	LadderData.bRandomLadder = true;
	LadderData.LadderSize = class'XComGameState_LadderProgress_Override'.default.DefaultSize;
	LadderData.LadderRung = 1;
	LadderData.LadderIndex = Profile.Data.m_Ladders;
	
	// This block has been modified
	if (Settings.UseCustomSettings)
	{
		LadderData.Settings = Settings;
		LadderData.CustomRungConfigurations = CalculateRungConfiguration();
		LadderData.LadderSize = Settings.LadderLength;
		InitSquad(TacticalStartState, XComPlayerState, LadderData);
	}
	else
	{
		LadderData.SquadProgressionName = class'XComGameState_LadderProgress'.default.SquadProgressions[ `SYNC_RAND_STATIC( class'XComGameState_LadderProgress'.default.SquadProgressions.Length ) ].SquadName;
		LadderData.LadderSize = class'XComGameState_LadderProgress'.default.DefaultSize;
		SquadMembers = class'XComGameState_LadderProgress'.static.GetSquadProgressionMembers( LadderData.SquadProgressionName, 1 );
		class'UITacticalQuickLaunch_MapData'.static.ApplySquad( SquadMembers );
	}

	class'UITacticalQuickLaunch'.static.ResetLastUsedSquad( );
	LadderData.LadderName = class'XGMission'.static.GenerateOpName( false ) @ "-" @ TimeStamp;
	LadderData.PopulateStartingUpgradeTemplates();
	LadderData.PopulateUpgradeProgression( );

	MissionType = class'XComGameState_LadderProgress_Override'.default.AllowedMissionTypes[ `SYNC_RAND_STATIC( class'XComGameState_LadderProgress_Override'.default.AllowedMissionTypes.Length ) ];
	BattleDataState.m_iMissionType = TacticalMissionManager.arrMissions.Find( 'sType', MissionType );

	if(!TacticalMissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
	{
		`Redscreen("CreateNewLadder(): Mission Type " $ MissionType $ " has no definition!");
		return;
	}

	TacticalMissionManager.ForceMission = MissionDef;

	// pick our new map
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	if(ValidPlots.Length == 0)
	{
		`Redscreen("TransferToNewMission(): Could not find a plot to transfer to for mission type " $ MissionType $ "!");
		return;
	}

	Month = `SYNC_RAND(ValidPlots.Length);
	NewPlot = ValidPlots[ Month ];
	PlotType = ParcelManager.GetPlotTypeDefinition( NewPlot.strType );

	BattleDataState.MapData.PlotMapName = NewPlot.MapName;
	BattleDataState.MapData.ActiveMission = MissionDef;

	if (NewPlot.ValidBiomes.Length > 0)
		BattleDataState.MapData.Biome = NewPlot.ValidBiomes[ `SYNC_RAND(NewPlot.ValidBiomes.Length) ];

	BattleDataState.LostSpawningLevel = BattleDataState.SelectLostActivationCount();
	BattleDataState.m_strMapCommand = "open" @ BattleDataState.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";

	// This block has been modified
	if (Settings.UseCustomSettings)
	{
		BattleDataState.SetForceLevel( LadderData.CustomRungConfigurations[ 0 ].ForceLevel );
		BattleDataState.SetAlertLevel( LadderData.CustomRungConfigurations[ 0 ].AlertLevel );
	}
	else
	{
		BattleDataState.SetForceLevel( class'XComGameState_LadderProgress'.default.RungConfiguration[ 0 ].ForceLevel );
		BattleDataState.SetAlertLevel( class'XComGameState_LadderProgress'.default.RungConfiguration[ 0 ].AlertLevel );
	}

	BattleDataState.m_nQuestItem = class'XComGameState_LadderProgress'.static.SelectQuestItem( MissionType );
	BattleDataState.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );

	class'XComGameState_LadderProgress'.static.AppendNames( BattleDataState.ActiveSitReps, MissionDef.ForcedSitreps );
	class'XComGameState_LadderProgress'.static.AppendNames( BattleDataState.ActiveSitReps, PlotType.ForcedSitReps );

	MissionSite = class'XComGameState_LadderProgress'.static.SetupMissionSite( TacticalStartState, BattleDataState );

	MissionTemplate = MissionTemplateManager.FindMissionTemplate(MissionDef.MissionName);
	if( MissionTemplate != none )
	{
		BattleDataState.m_strDesc = MissionTemplate.Briefing;
	}
	else
	{
		BattleDataState.m_strDesc = "NO LOCALIZED BRIEFING TEXT!";
	}

	LadderData.PlayedMissionFamilies.AddItem( TacticalMissionManager.arrMissions[ BattleDataState.m_iMissionType ].MissionFamily );

	CampaignSettings = XComGameState_CampaignSettings( History.GetSingleGameStateObjectForClass( class'XComGameState_CampaignSettings' ) );
	CampaignSettings.SetSuppressFirstTimeNarrativeEnabled( true );
	CampaignSettings.SetTutorialEnabled( false );
	CampaignSettings.SetIronmanEnabled( true );
	CampaignSettings.SetStartTime( class'XComCheatManager'.static.GetCampaignStartTime() );
	CampaignSettings.SetDifficulty( LadderDifficulty );

	// This block has been modified
	if (Settings.UseCustomSettings)
	{
		AddSecondWaveOptionsToCampaignSettings(CampaignSettings);
	}

	HeadquartersStateObject = XComGameState_HeadquartersXCom( History.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
	HeadquartersStateObject.bHasPlayedAmbushTutorial = true;
	HeadquartersStateObject.bHasPlayedMeleeTutorial = true;
	HeadquartersStateObject.bHasPlayedNeutralizeTargetTutorial = true;
	HeadquartersStateObject.SetGenericKeyValue( "NeutralizeTargetTutorial", 1 );

	MissionSite.UpdateSitrepTags( );
	HeadquartersStateObject.AddMissionTacticalTags( MissionSite );

	ConsoleCommand( BattleDataState.m_strMapCommand );

	`FXSLIVE.BizAnalyticsLadderStart( CampaignSettings.BizAnalyticsCampaignID, LadderData.LadderIndex, true, LadderDifficulty, LadderData.SquadProgressionName );
}

function AddSecondWaveOptionsToCampaignSettings(XComGameState_CampaignSettings CampaignSettings)
{
	local name SecondWaveOption;

	foreach Settings.SecondWaveOptions (SecondWaveOption)
	{
		CampaignSettings.AddSecondWaveOption(SecondWaveOption);
	}
}

function array<RungConfig> CalculateRungConfiguration()
{
	local RungConfig RungConfiguration;
	local array<RungConfig> RungConfigurations;
	local float ForceInterval;
	local float AlertInterval;
	local int Index;
	
	if (Settings.ForceLevelStart > Settings.ForceLevelEnd)
	{
		Settings.ForceLevelEnd = Settings.ForceLevelStart;
	}
	
	if (Settings.AlertLevelStart > Settings.AlertLevelEnd)
	{
		Settings.AlertLevelEnd = Settings.AlertLevelStart;
	}

	ForceInterval = float(Settings.ForceLevelEnd - Settings.ForceLevelStart) / float(Settings.LadderLength - 1);
	AlertInterval = float(Settings.AlertLevelEnd - Settings.AlertLevelStart) / float(Settings.LadderLength - 1);
	
	// don't do last one in a loop since we'll just use ending values directly
	for(Index = 0; Index < Settings.LadderLength - 1; Index++)
	{
		RungConfiguration.ForceLevel = int(Settings.ForceLevelStart + (ForceInterval * Index));
		RungConfiguration.AlertLevel = int(Settings.AlertLevelStart + (AlertInterval * Index));;
		RungConfigurations.AddItem(RungConfiguration);

		//`LOG("=== Rung: " $ string(i));
		//`LOG("=== FL: " $ string(RungConfiguration.ForceLevel));
		//`LOG("=== AL: " $ string(RungConfiguration.AlertLevel));
	}
	
	RungConfiguration.ForceLevel = Settings.ForceLevelEnd;
	RungConfiguration.AlertLevel = Settings.AlertLevelEnd;
	RungConfigurations.AddItem(RungConfiguration);

	return RungConfigurations;
}

private function InitSquad(XComGameState TacticalStartState, XComGameState_Player XComPlayerState, XComGameState_LadderProgress_Override LadderData)
{
	local XComGameState_HeadquartersXCom HeadquartersStateObject;
	local array<XComGameState_Unit> SquadMembers;
	local SoldierOption Option;
	local XComGameState_Unit Soldier;
	local array<name> UsedClasses;
	local array<string> UsedCharacters;

	`LOG("InitSquad");

	// Somehow, the squad progression soldiers are being added
	// Need to figure out how, but for now we can just remove them here before adding ours
	HeadquartersStateObject = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	HeadquartersStateObject.Squad.length = 0;

	// First, fill UsedClasses and UsedCharacters with user selected classes and characters
	foreach Settings.SoldierOptions (Option)
	{
		if (!Option.bRandomClass)
		{
			`LOG("Adding to UsedClasses: " $ string(Option.ClassName));
			UsedClasses.AddItem(Option.ClassName);
		}
		
		if (!Option.bRandomlyGeneratedCharacter && !Option.bRandomCharacter)
		{
			`LOG("Adding to UsedCharacters: " $ Option.CharacterPoolName);
			UsedCharacters.AddItem(Option.CharacterPoolName);
		}
	}

	// Generate the soldiers, along with their characters and classes
	foreach Settings.SoldierOptions (Option)
	{
		if (Option.StartingMission == 1)
		{
			// Create these soldiers now, they will be on the first mission
			Soldier = class'ResistanceOverhaulHelpers'.static.CreateSoldier(TacticalStartState, XComPlayerState, Option, Settings.AllowedClasses, UsedClasses, UsedCharacters);
			if (UsedClasses.Find(Soldier.GetSoldierClassTemplateName()) == INDEX_NONE)
			{
				UsedClasses.AddItem(Soldier.GetSoldierClassTemplateName());
			}

			if (UsedCharacters.Find(Soldier.GetFullName()) == INDEX_NONE)
			{
				UsedCharacters.AddItem(Soldier.GetFullName());
			}
			SquadMembers.AddItem(Soldier);
		}
		else
		{
			// Add these soldiers to the ladder data, and create them when we get to their starting missions
			LadderData.FutureSoldierOptions.AddItem(Option);
		}
	}
}
