class UITLE_LadderModeMenu_Override extends UITLE_LadderModeMenu config (LadderOptions);

enum EUILadderScreenState
{
	eUILadderScreenState_Base,
	eUILadderScreenState_CustomVisible,
	eUILadderScreenState_CustomSettings,
	eUILadderScreenState_AllowedClasses,
	eUILadderScreenState_AdvancedOptions,
	eUILadderScreenState_Save,
	eUILadderScreenState_Load,
	eUILadderScreenState_Squad,
	eUILadderScreenState_Soldier,
	eUILadderScreenState_Character,
	eUILadderScreenState_Class
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

var config int DefaultLadderLength;
var config int DefaultForceLevelStart;
var config int DefaultForceLevelEnd;
var config int DefaultAlertLevelStart;
var config int DefaultAlertLevelEnd;

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

var UIList CustomList;
var EUILadderScreenState UIScreenState;
var LadderSettings Settings;
var array<X2SoldierClassTemplate> MasterClassList;
var int SelectedSoldierIndex;

var int LastSelectedIndexes[EUILadderScreenState] <BoundEnum = EUILadderScreenState>;

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
	Settings.LadderLength = default.DefaultLadderLength;
	Settings.ForceLevelStart = default.DefaultForceLevelStart;
	Settings.ForceLevelEnd = default.DefaultForceLevelEnd;
	Settings.AlertLevelStart = default.DefaultAlertLevelStart;
	Settings.AlertLevelEnd = default.DefaultAlertLevelEnd;
	
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
	LastSelectedIndexes[UIScreenState] = ItemIndex;

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
		UIScreenState = eUILadderScreenState_CustomVisible;
		UpdateCustomListData();
	}
	else
	{
		UIScreenState = eUILadderScreenState_Base;
		UpdateCustomListData();
	}

	super.OnSelectedChange(ContainerList, ItemIndex);
}

simulated function UpdateCustomListData()
{
	HideListItems();
	
	switch (UIScreenState)
	{
	case eUILadderScreenState_Base:
	case eUILadderScreenState_CustomVisible:
		LastSelectedIndexes[eUILadderScreenState_CustomSettings] = 0;
	case eUILadderScreenState_CustomSettings:
		LastSelectedIndexes[eUILadderScreenState_AllowedClasses] = 0;
		LastSelectedIndexes[eUILadderScreenState_AdvancedOptions] = 0;
		LastSelectedIndexes[eUILadderScreenState_Squad] = 0;
		LastSelectedIndexes[eUILadderScreenState_Save] = 0;
		LastSelectedIndexes[eUILadderScreenState_Load] = 0;
	case eUILadderScreenState_Squad:
		LastSelectedIndexes[eUILadderScreenState_Soldier] = 0;
	case eUILadderScreenState_Soldier:
		LastSelectedIndexes[eUILadderScreenState_Character] = 0;
		LastSelectedIndexes[eUILadderScreenState_Class] = 0;
		break;
	};
	
	switch (UIScreenState)
	{
	case eUILadderScreenState_Base:
		// The vanilla screen behavior
		UpdateCustomListDataBase();
		break;
	case eUILadderScreenState_CustomVisible:
		// Showing new list, but still navigating on left column
		UpdateCustomListDataCustomVisible();
		break;
	case eUILadderScreenState_CustomSettings:
		// Showing new list, and navigating on it
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
	case eUILadderScreenState_Character:
		UpdateCustomListDataCharacter();
		break;
	case eUILadderScreenState_Class:
		UpdateCustomListDataClass();
		break;
	case eUILadderScreenState_Save:
		UpdateCustomListDataSave();
		break;
	case eUILadderScreenState_Load:
		UpdateCustomListDataLoad();
		break;
	};

	if( CustomList.IsSelectedNavigation() )
		CustomList.SetSelectedIndex(LastSelectedIndexes[UIScreenState]);
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
	if (CustomList.IsSelectedNavigation())
	{
		SelectLeftColumn();
	}
	CustomList.SetVisible(false);
}

simulated function UpdateCustomListDataCustomVisible()
{
	if (CustomList.IsSelectedNavigation())
	{
		SelectLeftColumn();
	}
	PopulateCustomSettings();
}

simulated function SelectLeftColumn()
{
	CustomList.Navigator.SetSelected(none);
	Navigator.SetSelected(LeftColumn);
	LeftColumn.Navigator.SetSelected(List);
	List.Navigator.SelectFirstAvailable();
}

simulated function UpdateCustomListDataCustomSettings()
{
	PopulateCustomSettings();
	LeftColumn.Navigator.SetSelected(none);
	Navigator.SetSelected(CustomList);
}

simulated function PopulateCustomSettings()
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
	UpdateMissionProgressLabel();
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

	CurrentValue = int(SpinnerPanel.value);
	NewValue = CurrentValue + Direction;

	if (NewValue >= default.LADDER_LENGTH_MIN && NewValue <= default.LADDER_LENGTH_MAX)
	{
		SpinnerPanel.SetValue(string(NewValue));
		Settings.LadderLength = NewValue;
	
		UpdateMissionProgressLabel();
	}
}

simulated function UpdateMissionProgressLabel()
{
	local int MissionIndex;

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

	mc.BeginFunctionOp("SetMissionProgressText");
	MC.QueueString(m_ProgressLabel);
	MC.QueueString(m_MissionLabel);
	MC.QueueString(1 @ "/" @ Settings.LadderLength);
	mc.EndOp();
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
	local LadderSaveData SaveData;	
	
	foreach m_LadderSaveData(SaveData)
	{
		`LOG("SaveData.Filename: " $ SaveData.Filename, class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
	}
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
	local string CharacterText;
	local string ClassText;

	Index = 0;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_NewSoldierText, "", OnClickAddSoldier);
	if (Settings.SoldierOptions.Length >= default.SQUAD_SIZE_MAX)
	{
		GetListItem(Index).SetDisabled(true);
	}
	Index++;

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
	
	LastSelectedIndexes[eUILadderScreenState_Squad] = CustomList.ItemCount;
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
	local int ClassIndex;
	local string SelectedClassText;
	local string SelectedCharacterText;
	local CharacterPoolManager CharacterPoolMgr;
	local int CharacterIndex;
	local XComGameState_Unit Character;
	
	Index = 0;
	Option = Settings.SoldierOptions[SelectedSoldierIndex];

	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_RemoveSoldierText, "", OnClickRemoveSoldier);
	if (Settings.SoldierOptions.Length <= 1)
	{
		GetListItem(Index).SetDisabled(true);
	}
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).SetWidgetType(EUILineItemType_Spinner);
	GetListItem(Index).UpdateDataSpinner(m_SoldierStartingMission, string(Option.StartingMission), StartingMissionSpinnerSpinned);
	Index++;
	
	SelectedClassText = m_SoldierRandomClass;
	if (!Option.bRandomClass)
	{
		for (ClassIndex = 0; ClassIndex < MasterClassList.Length; ClassIndex++)
		{
			if (MasterClassList[ClassIndex].DataName == Option.ClassName)
			{
				SelectedClassText = MasterClassList[ClassIndex].DisplayName;
			}
		}
	}
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(SelectedClassText, m_SoldierClass, OnClickSoldierClass);
	Index++;

	SelectedCharacterText = "";
	if (Option.bRandomlyGeneratedCharacter)
	{
		SelectedCharacterText = m_SoldierRandomlyGeneratedCharacter;
	}
	else if (Option.bRandomCharacter)
	{
		SelectedCharacterText = m_SoldierRandomCharacter;
	}
	else
	{
		CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		for (CharacterIndex = 0; CharacterIndex < CharacterPoolMgr.CharacterPool.Length; CharacterIndex++)
		{
			Character = CharacterPoolMgr.CharacterPool[CharacterIndex];
			if (Character.bAllowedTypeSoldier && Character.GetFullName() == Option.CharacterPoolName)
			{
				SelectedCharacterText = Character.GetFullName();
			}
		}
	}
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(SelectedCharacterText, m_SoldierCharacterPool, OnClickSoldierCharacter);
	Index++;
}

simulated function OnClickRemoveSoldier()
{
	Settings.SoldierOptions.Remove(SelectedSoldierIndex, 1);
	LastSelectedIndexes[eUILadderScreenState_Squad] = 0;

	UIScreenState = eUILadderScreenState_Squad;
	UpdateCustomListData();
}

simulated function OnClickSoldierClass()
{
	UIScreenState = eUILadderScreenState_Class;
	UpdateCustomListData();
}

simulated function UpdateCustomListDataClass()
{
	local int Index;
	local X2SoldierClassTemplate ClassTemplate;

	Index = 0;
	LastSelectedIndexes[eUILadderScreenState_Class] = 0;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SoldierRandomClass, "", , , OnClickClass);
	Index++;

	foreach MasterClassList (ClassTemplate)
	{
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(ClassTemplate.DisplayName, "", , , OnClickClass);
		GetListItem(Index).metadataString = string(ClassTemplate.DataName);

		if (!Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass && Settings.SoldierOptions[SelectedSoldierIndex].ClassName == ClassTemplate.DataName)
		{
			LastSelectedIndexes[eUILadderScreenState_Class] = Index;
		}

		Index++;
	}
}

simulated function OnClickClass(UIMechaListItem MechaItem)
{
	if (MechaItem.metadataString == "")
	{
		// Random is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass = true;
		Settings.SoldierOptions[SelectedSoldierIndex].ClassName = '';
	}
	else
	{
		// Actual class is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass = false;
		Settings.SoldierOptions[SelectedSoldierIndex].ClassName = name(MechaItem.metadataString);
	}

	ValidateCharacterBasedOnClassSelection();
	
	UIScreenState = eUILadderScreenState_Soldier;
	UpdateCustomListData();
}

private function ValidateCharacterBasedOnClassSelection()
{
	local CharacterPoolManager CharacterPoolMgr;
	local XComGameState_Unit Character;
	local X2SoldierClassTemplate ClassTemplate;

	if (!Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass && 
		!Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter &&
		!Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter)
	{
		CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		Character = CharacterPoolMgr.GetCharacter(Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName);
		ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Settings.SoldierOptions[SelectedSoldierIndex].ClassName);

		if (!class'ResistanceOverhaulHelpers'.static.CharacterIsValid(Character, ClassTemplate))
		{
			Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter = true;
			Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter = false;
			Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName = "";
		}
	}
}

simulated function OnClickSoldierCharacter()
{
	UIScreenState = eUILadderScreenState_Character;
	UpdateCustomListData();
}

simulated function UpdateCustomListDataCharacter()
{
	local int Index;
	local CharacterPoolManager CharacterPoolMgr;
	local int CharacterIndex;
	local XComGameState_Unit Character;

	Index = 0;
	LastSelectedIndexes[eUILadderScreenState_Class] = 0;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SoldierRandomlyGeneratedCharacter, "", , , OnClickCharacter);
	GetListItem(Index).metadataInt = 1;
	if (Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter)
	{
		LastSelectedIndexes[eUILadderScreenState_Character] = Index;
	}
	Index++;
	
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SoldierRandomCharacter, "", , , OnClickCharacter);
	GetListItem(Index).metadataInt = 2;
	if (Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter)
	{
		LastSelectedIndexes[eUILadderScreenState_Character] = Index;
	}
	Index++;
	
	CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
	for (CharacterIndex = 0; CharacterIndex < CharacterPoolMgr.CharacterPool.Length; CharacterIndex++)
	{
		Character = CharacterPoolMgr.CharacterPool[CharacterIndex];
		if (Character.bAllowedTypeSoldier)
		{
			GetListItem(Index).EnableNavigation();
			GetListItem(Index).UpdateDataValue(Character.GetFullName(), "", , , OnClickCharacter);
			GetListItem(Index).metadataString = Character.GetFullName();

			if (Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName == Character.GetFullName())
			{
				LastSelectedIndexes[eUILadderScreenState_Character] = Index;
			}

			Index++;
		}
	}
}

simulated function OnClickCharacter(UIMechaListItem MechaItem)
{
	if (MechaItem.metadataString == "" && MechaItem.metadataInt == 1)
	{
		// Randomly generated character is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter = true;
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName = "";
	}
	else if (MechaItem.metadataString == "" && MechaItem.metadataInt == 2)
	{
		// Random character is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter = true;
		Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName = "";
	}
	else
	{
		// Actual character is selected
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter = false;
		Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName = MechaItem.metadataString;
	}

	ValidateClassBasedOnCharacterSelection();
	
	UIScreenState = eUILadderScreenState_Soldier;
	UpdateCustomListData();
}

private function ValidateClassBasedOnCharacterSelection()
{
	local CharacterPoolManager CharacterPoolMgr;
	local XComGameState_Unit Character;
	local X2SoldierClassTemplate ClassTemplate;
	
	if (!Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass && 
		!Settings.SoldierOptions[SelectedSoldierIndex].bRandomlyGeneratedCharacter &&
		!Settings.SoldierOptions[SelectedSoldierIndex].bRandomCharacter)
	{
		CharacterPoolMgr = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		Character = CharacterPoolMgr.GetCharacter(Settings.SoldierOptions[SelectedSoldierIndex].CharacterPoolName);
		ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Settings.SoldierOptions[SelectedSoldierIndex].ClassName);

		if (!class'ResistanceOverhaulHelpers'.static.CharacterIsValid(Character, ClassTemplate))
		{
			Settings.SoldierOptions[SelectedSoldierIndex].bRandomClass = true;
			Settings.SoldierOptions[SelectedSoldierIndex].ClassName = '';
		}
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

	Index = 0;

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
	local UIList TargetList;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		if(Navigator.GetSelected() == CustomList)
		{
			// Selecting item from new list
			bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_KEY_ENTER, arg);
		}
		else
		{
			TargetList = UIList(LeftColumn.Navigator.GetSelected());
			if( TargetList == List && TargetList.SelectedIndex == 0 )
			{
				// Selecting new resistance operation, so show options
				UIScreenState = eUILadderScreenState_CustomSettings;
				UpdateCustomListData();
				bHandled = true;
			}
			else if (LeftColumn.Navigator.GetSelected() == List || LeftColumn.Navigator.GetSelected() == NarrativeList)
			{
				// Selected existing resistance operation, so do nothing (because we start them with Start now)
				bHandled = true;
			}
		}

		break;
	case class'UIUtilities_Input'.const.FXS_DPAD_UP :
	case class'UIUtilities_Input'.const.FXS_ARROW_UP :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP :
	case class'UIUtilities_Input'.const.FXS_KEY_W :
		if(Navigator.GetSelected() == CustomList)
		{
			// Navigate settings list
			bHandled = CustomList.GetSelectedItem().OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_UP, arg);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN :
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN :
	case class'UIUtilities_Input'.const.FXS_KEY_S :
		if(Navigator.GetSelected() == CustomList)
		{
			// Navigate settings list
			bHandled = CustomList.GetSelectedItem().OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_DOWN, arg);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			TargetList = UIList(LeftColumn.Navigator.GetSelected());
			if( TargetList != none )
			{
				// Start the selected resistance operation
				OnLadderClicked(TargetList, TargetList.SelectedIndex);
			}
			else
			{
				// In the new list, so start a new resistance operation
				OnLadderClicked(List, 0);
			}
			bHandled = true;
			break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
	case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
	case class'UIUtilities_Input'.const.FXS_BUTTON_R3:
			TargetList = UIList(LeftColumn.Navigator.GetSelected());
			if (TargetList == none || (TargetList == List && TargetList.SelectedIndex == 0))
			{
				// Either our custom list is selected, or new operation is selected, so these should do nothing
				bHandled = true;
			}
			break;
	}

	// always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

simulated public function OnCancel()
{
	switch (UIScreenState)
	{
	case eUILadderScreenState_Base:
	case eUILadderScreenState_CustomVisible:
		super.OnCancel();
		break;
	case eUILadderScreenState_CustomSettings:
		UIScreenState = eUILadderScreenState_CustomVisible;
		UpdateCustomListData();
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
	case eUILadderScreenState_Character:
	case eUILadderScreenState_Class:
		UIScreenState = eUILadderScreenState_Soldier;
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
			mc.FunctionString("SetContinueButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_START, 26, 26, -5) @ m_strContinueLadder);
		}
	}
	else // Starting a fresh ladder 
	{
		if( `ISCONTROLLERACTIVE )
		{
			mc.FunctionString("SetContinueButton", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_START, 26, 26, -5) @ m_strBeginLadder);
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

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_One);
	BattleDataState.PlayerTurnOrder.AddItem(AddPlayerState.GetReference());

	AddPlayerState = class'XComGameState_Player'.static.CreatePlayer(TacticalStartState, eTeam_Two);
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
	LadderData.LadderName = class'XGMission'.static.GenerateOpName( false ) @ "-" @ TimeStamp;
	class'UITacticalQuickLaunch'.static.ResetLastUsedSquad();
	
	// This block has been modified
	if (Settings.UseCustomSettings)
	{
		LadderData.LadderSize = Settings.LadderLength;
		LadderData.Settings = Settings;
		LadderData.CustomRungConfigurations = CalculateRungConfiguration();
	}
	else
	{
		LadderData.LadderSize = class'XComGameState_LadderProgress'.default.DefaultSize;
		LadderData.SquadProgressionName = class'XComGameState_LadderProgress'.default.SquadProgressions[ `SYNC_RAND_STATIC( class'XComGameState_LadderProgress'.default.SquadProgressions.Length ) ].SquadName;
		SquadMembers = class'XComGameState_LadderProgress'.static.GetSquadProgressionMembers( LadderData.SquadProgressionName, 1 );
		class'UITacticalQuickLaunch_MapData'.static.ApplySquad( SquadMembers );
	}

	LadderData.PopulateStartingUpgradeTemplates();
	LadderData.PopulateUpgradeProgression( );

	MissionType = class'XComGameState_LadderProgress_Override'.default.StartingMissionTypes[ `SYNC_RAND_STATIC( class'XComGameState_LadderProgress_Override'.default.StartingMissionTypes.Length ) ];
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
	
	// This block has been modified
	if (Settings.UseCustomSettings)
	{
		LadderData.ChosenMissionOption.MissionType = MissionType;
		LadderData.ChosenMissionOption.Credits = class'XComGameState_LadderProgress_Override'.default.CREDITS_BASE;
		LadderData.ChosenMissionOption.Science = class'XComGameState_LadderProgress_Override'.default.SCIENCE_TABLE[0];
		LadderData.InitMissionTypeOptions();
	}

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
		InitSquad(TacticalStartState, XComPlayerState, LadderData);
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
	}
	
	RungConfiguration.ForceLevel = Settings.ForceLevelEnd;
	RungConfiguration.AlertLevel = Settings.AlertLevelEnd;
	RungConfigurations.AddItem(RungConfiguration);

	return RungConfigurations;
}

private function InitSquad(XComGameState TacticalStartState, XComGameState_Player XComPlayerState, XComGameState_LadderProgress_Override LadderData)
{
	local SoldierOption Option;
	local XComGameState_Unit Soldier;
	local array<name> UsedClasses;
	local array<string> UsedCharacters;
	
	// Obliterate any previously added Units / Items
	class'UITacticalQuickLaunch_MapData'.static.PurgeGameState();
	
	// First, fill UsedClasses and UsedCharacters with user selected classes and characters
	foreach Settings.SoldierOptions (Option)
	{
		if (!Option.bRandomClass)
		{
			UsedClasses.AddItem(Option.ClassName);
		}
		
		if (!Option.bRandomlyGeneratedCharacter && !Option.bRandomCharacter)
		{
			UsedCharacters.AddItem(Option.CharacterPoolName);
		}
	}

	// Generate the soldiers, along with their characters and classes
	foreach Settings.SoldierOptions (Option)
	{
		if (Option.StartingMission == 1)
		{
			// Create these soldiers now, they will be on the first mission
			Soldier = class'ResistanceOverhaulHelpers'.static.CreateSoldier(TacticalStartState, XComPlayerState, Option, Settings.AllowedClasses, UsedClasses, UsedCharacters, Settings.AllowDuplicateClasses);
			if (UsedClasses.Find(Soldier.GetSoldierClassTemplateName()) == INDEX_NONE)
			{
				UsedClasses.AddItem(Soldier.GetSoldierClassTemplateName());
			}

			if (UsedCharacters.Find(Soldier.GetFullName()) == INDEX_NONE)
			{
				UsedCharacters.AddItem(Soldier.GetFullName());
			}
		}
		else
		{
			// Add these soldiers to the ladder data, and create them when we get to their starting missions
			// However, to maintain a consistent ladder every playthough (gameplay wise) we need to choose their classes now
			if (Option.bRandomClass)
			{
				Option.ClassName = class'ResistanceOverhaulHelpers'.static.RandomlyChooseClass(Settings.AllowedClasses, UsedClasses, Settings.AllowDuplicateClasses);
				Option.bRandomClass = false;
			}

			if (UsedClasses.Find(Option.ClassName) == INDEX_NONE)
			{
				UsedClasses.AddItem(Option.ClassName);
			}

			LadderData.FutureSoldierOptions.AddItem(Option);
		}
	}
}

simulated function OnLadderAbandoned( UIList ContainerList, int ItemIndex )
{
	local int LadderIndex;
	local XComGameStateHistory History;
	local XComGameState_LadderProgress_Override LadderDataOverride;
	local XComGameState_LadderProgress LadderData;
	local XComGameState_CampaignSettings CurrentCampaign;
	local LadderSaveData SaveData;

	LadderIndex = GetCurrentLadderIndex();

	// selected a ladder with an in progress savegame
	foreach m_LadderSaveData( SaveData )
	{
		if (SaveData.LadderIndex == LadderIndex)
		{
			History = class'XComGameStateHistory'.static.GetGameStateHistory();

			History.ReadHistoryFromFile( "Ladders/", "Ladder_" $ LadderIndex );
			
			CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
			LadderDataOverride = XComGameState_LadderProgress_Override(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override'));
			if (LadderDataOverride == none)
			{
				LadderData = XComGameState_LadderProgress(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));
				if (LadderData == none)
				{
					return;
				}
			}

			`FXSLIVE.BizAnalyticsLadderEnd( CurrentCampaign.BizAnalyticsCampaignID, LadderIndex, 0, 0, LadderDataOverride.SquadProgressionName, CurrentCampaign.DifficultySetting );

			`ONLINEEVENTMGR.DeleteSaveGame( SaveData.SaveID );
			`ONLINEEVENTMGR.UpdateSaveGameList();

			if (LadderDataOverride == none)
			{
				XComCheatManager(GetALocalPlayerController().CheatManager).CreateLadder( LadderIndex, LadderData.LadderSize, CurrentCampaign.DifficultySetting );
			}
			else if (!LadderDataOverride.Settings.UseCustomSettings)
			{
				XComCheatManager(GetALocalPlayerController().CheatManager).CreateLadder( LadderIndex, LadderDataOverride.LadderSize, CurrentCampaign.DifficultySetting );
			}
			else
			{
				// Would like to delete all the Mission_ save files in /Ladders except for the first one,
				// to account for the player choosing different missions on the second playthrough. 
				// This doesn't seem to be something I can do though...

				// TODO need to modify the saved ladder data such that it displays the first mission
				// RecreateAbandonedLadder(LadderDataOverride);
			}

			if(ContainerList == NarrativeList)
				UpdateData(ItemIndex);
			else
				UpdateData(ItemIndex + 4);

			return;
		}
	}

	// shouldn't be able to get here as we should only be able to abandon an in progress ladder which means there's a matching save
}
