class UILadderUpgradeScreen_Override extends UILadderUpgradeScreen dependson(X2DataSet_ResistanceTechUpgrades) config(SoldierUpgrades);

enum EUIScreenState
{
	eUIScreenState_Squad,
	eUIScreenState_Research,
	eUIScreenState_ResearchCategory,
	eUIScreenState_CompletedProjects,
	eUIScreenState_Soldier,
	eUIScreenState_PrimaryWeapon,
	eUIScreenState_WeaponAttachment,
	eUIScreenState_SecondaryWeapon,
	eUIScreenState_Armor,
	eUIScreenState_PCS,
	eUIScreenState_UtilItem1,
	eUIScreenState_UtilItem2,
	eUIScreenState_UtilItem3,
	eUIScreenState_GrenadePocket,
	eUIScreenState_AmmoPocket,
	eUIScreenState_HeavyWeapon,
	eUIScreenState_CustomSlot,
	eUIScreenState_Abilities
};

var EUIScreenState UIScreenState;

var UINavigationHelp NavHelp;

var int SelectedSoldierIndex;
var array<XComGameState_Unit> Squad;
var array<bool> HasEarnedNewAbility; // Index is the soldier's index in the squad
var array<bool> IsNew; // Index is the soldier's index in the squad
var int SelectedAbilityIndex;
var int SelectedAttachmentIndex;
var EUpgradeCategory SelectedUpgradeCategory;
var EInventorySlot SelectedInventorySlot;

var UIText CreditsText;
var UIPanel CreditsPanel;
var UIBGBox Background, PanelDecoration;
var UILargeButton ContinueButton;

var UIList List;

var XComGameState NewGameState;
var XComGameStateHistory History;
var XComGameState_LadderProgress_Override LadderData;

var localized string ScreenTitle;
var localized string ScreenSubtitles[EUIScreenState] <BoundEnum = EUIScreenState>;

delegate OnSelectorClickDelegate(UIMechaListItem MechaItem);

simulated function OnInit()
{
	if (IsNarrativeLadder())
	{
		super.OnInit();
		return;
	}

	super(UIScreen).OnInit();
}

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local StateObjectReference UnitStateRef;
	local UIPanel LeftColumn;
	local XComGameState_Unit Soldier;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit NewSoldier;
	local int Index;
	local int RankIndex;
	local array<name> UsedClasses;
	local array<string> UsedCharacters;
	local int X, Y;
	
	LadderData = XComGameState_LadderProgress_Override(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override'));
	if (IsNarrativeLadder())
	{
		super.InitScreen(InitController, InitMovie, InitName);
		return;
	}

	super(UIScreen).InitScreen(InitController, InitMovie, InitName);
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Progression upgrades");
	
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
	{
		if( PlayerState.GetTeam() == eTeam_XCom)
		{
			break;
		}
	}

	LadderData.SetSoldierStatesBeforeUpgrades();
	
	foreach XComHQ.Squad(UnitStateRef)
	{
		Soldier = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitStateRef.ObjectID));
		Squad.AddItem(Soldier);
		IsNew.AddItem(false);

		if (UsedClasses.Find(Soldier.GetSoldierClassTemplateName()) == INDEX_NONE)
		{
			UsedClasses.AddItem(Soldier.GetSoldierClassTemplateName());
		}

		if (UsedCharacters.Find(Soldier.GetFullName()) == INDEX_NONE)
		{
			UsedCharacters.AddItem(Soldier.GetFullName());
		}
	}

	// Check if we're getting any new soldiers next rung
	`LOG("=== LadderData.FutureSoldierOptions.Length: " $ string(LadderData.FutureSoldierOptions.Length));
	`LOG("=== LadderData.LadderRung: " $ string(LadderData.LadderRung));
	for (Index = LadderData.FutureSoldierOptions.Length - 1; Index >= 0; Index--)
	{
		if (LadderData.FutureSoldierOptions[Index].StartingMission == LadderData.LadderRung + 1)
		{
			`LOG("Getting a new soldier!");
			NewSoldier = class'ResistanceOverhaulHelpers'.static.CreateSoldier(NewGameState, PlayerState, LadderData.FutureSoldierOptions[Index], LadderData.Settings.AllowedClasses, UsedClasses, UsedCharacters);
			LadderData.FutureSoldierOptions.Remove(Index, 1);

			if (UsedClasses.Find(NewSoldier.GetSoldierClassTemplateName()) == INDEX_NONE)
			{
				UsedClasses.AddItem(NewSoldier.GetSoldierClassTemplateName());
			}

			if (UsedCharacters.Find(NewSoldier.GetFullName()) == INDEX_NONE)
			{
				UsedCharacters.AddItem(NewSoldier.GetFullName());
			}
			
			for (RankIndex = 1; RankIndex < LadderData.LadderRung && RankIndex < Soldier.GetSoldierClassTemplate().GetMaxConfiguredRank(); RankIndex++)
			{
				NewSoldier.RankUpSoldier(NewGameState);
			}

			Squad.AddItem(NewSoldier);
			IsNew.AddItem(true);
		}
	}

	// For any dead soldiers, give them a new appearance
	foreach Squad(Soldier)
	{
		if (!Soldier.IsAlive())
		{
			UpdateCustomizationForDeadSoldier(Soldier);
		}
	}

	// Rank up all soldiers
	foreach Squad(Soldier)
	{
		if (Soldier.GetSoldierRank() < Soldier.GetSoldierClassTemplate().GetMaxConfiguredRank())
		{
			Soldier.RankUpSoldier(NewGameState);
			HasEarnedNewAbility.AddItem(false);
		}
		else
		{
			HasEarnedNewAbility.AddItem(true);
		}
	}
	
	mc.FunctionString("SetScreenTitle", ScreenTitle);

	// Credits text
	X = 740;
	Y = -500;

	Background = Spawn(class'UIBGBox', self);
	Background.bAnimateOnInit = false;
	Background.bCascadeFocus = false;
	Background.InitBG('SelectChoice_Background');
	Background.AnchorCenter();
	Background.SetPosition(X,Y);
	Background.SetSize(200,40);
	Background.SetBGColor("cyan");
	Background.SetAlpha(0.9f);	

	PanelDecoration = Spawn(class'UIBGBox',self);
	PanelDecoration.bAnimateOnInit = false;
	PanelDecoration.InitBG('SelectChoice_TitleBackground');
	PanelDecoration.AnchorCenter();
	PanelDecoration.setPosition(X,Y);
	PanelDecoration.setSize(200,40);
	PanelDecoration.SetBGColor("cyan");
	PanelDecoration.SetAlpha(0.9f);

	CreditsText = Spawn(class'UIText',self);
	CreditsText.bAnimateOnInit = false;
	CreditsText.InitText('CreditsText',"Credits: " @ string(LadderData.Credits),false);
	CreditsText.AnchorCenter();
	CreditsText.SetPosition(X + 15, Y + 5);
	CreditsText.SetSize(200,40);
	CreditsText.SetText("Credits: " @ string(LadderData.Credits));

	`LOG("=== SCORE: " $ string(LadderData.CumulativeScore));
	`LOG("=== CREDITS: " $ string(LadderData.Credits));

	// Left column
	LeftColumn = Spawn(class'UIPanel', self);
	LeftColumn.bIsNavigable = true;
	LeftColumn.InitPanel('SkirmishLeftColumnContainer');
	Navigator.SetSelected(LeftColumn);
	LeftColumn.Navigator.LoopSelection = true;	

	// The container list for the soldiers
	List = Spawn(class'UIList', LeftColumn);
	List.InitList('MyList', , , , 825);
	List.Navigator.LoopOnReceiveFocus = true;
	List.Navigator.LoopSelection = false;
	List.bPermitNavigatorToDefocus = true;
	List.Navigator.SelectFirstAvailable();
	List.SetWidth(445);
	List.EnableNavigation();
	List.OnSetSelectedIndex = OnSetSelectedIndex;

	// Continue button
	ContinueButton = Spawn(class'UILargeButton', LeftColumn);
	ContinueButton.InitLargeButton('ContinueButton', , , OnContinueButtonClicked);
	ContinueButton.SetPosition(500, 965);

	// Not sure about this...
	LeftColumn.Navigator.SetSelected(ContinueButton);
	
	mc.FunctionVoid("HideAllScreens");
	mc.BeginFunctionOp("SetMissionInfo");
	
	mc.QueueString(""); // big image
	mc.QueueString("Mission Name");// mission name

	mc.QueueString("XCOM Squad"); //XCOM squad
	mc.QueueString("Enemy Label");
	mc.QueueString("Selected Enemy");
	mc.QueueString("Description");

	mc.QueueString("Objective");
	mc.QueueString("Mission Template");
	mc.QueueString("Continue");
	mc.EndOp();
	UpdateDetailsGeneric();

	UIScreenState = eUIScreenState_Squad;
	UpdateData();

	List.SetVisible(true);

	NavHelp = GetNavHelp();
	UpdateNavHelp();
}

simulated function UpdateCustomizationForDeadSoldier(XComGameState_Unit Soldier)
{
	local XGCharacterGenerator CharacterGenerator;
	local TSoldier GeneratedSoldier;
	
	CharacterGenerator = `XCOMGRI.Spawn(Soldier.GetMyTemplate().CharacterGeneratorClass);
	GeneratedSoldier = CharacterGenerator.CreateTSoldier( Soldier.GetMyTemplateName() );
	GeneratedSoldier.strNickName = Soldier.GenerateNickname( );
	
	Soldier.SetTAppearance(GeneratedSoldier.kAppearance);
	Soldier.SetCharacterName(GeneratedSoldier.strFirstName, GeneratedSoldier.strLastName, GeneratedSoldier.strNickName);
	Soldier.SetCountry(GeneratedSoldier.nmCountry);
}

simulated function UINavigationHelp GetNavHelp()
{
	local UINavigationHelp Result;

	Result = PC.Pres.GetNavHelp();
	if (Result == None)
	{
		if (`PRES != none) // Tactical
		{
			Result = Spawn(class'UINavigationHelp', self).InitNavHelp();
			Result.SetX(-500); //offset to match the screen. 
		}
		else if (`HQPRES != none) // Strategy
			Result = `HQPRES.m_kAvengerHUD.NavHelp;
	}
	return Result;
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(OnCancel);

	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericConfirm, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	}

	NavHelp.Show();
}

simulated function OnSetSelectedIndex(UIList ContainerList, int ItemIndex)
{
	local UIMechaListItem Item;

	if (UIScreenState == eUIScreenState_Squad)
	{
		// Index 0 is the Research menu item
		if (ItemIndex > 0)
		{
			SelectedSoldierIndex = ItemIndex - 1;
			RefreshSquadDetailsPanel();
		}
		else
		{
			UpdateDetailsGeneric();
		}
	}
	else if (UIScreenState == eUIScreenState_Soldier)
	{
		Item = UIMechaListItem(ContainerList.GetItem(ItemIndex));
		if (Item.metadataString == "Attachment")
		{
			SelectedAttachmentIndex = Item.metadataInt;
		}
	}
	else if (UIScreenState == eUIScreenState_Abilities)
	{
		SelectedAbilityIndex = ItemIndex;
		UpdateAbilityInfo(ItemIndex);
	}
	else if (UIScreenState >= eUIScreenState_PrimaryWeapon && UIScreenState <= eUIScreenState_HeavyWeapon)
	{
		UpdateSelectedEquipmentInfo(ItemIndex);
	}
	else if (UIScreenState == eUIScreenState_Research)
	{
		// Index 0 is the Completed Projects menu item
		if (ItemIndex > 0)
		{
			SelectedUpgradeCategory = EUpgradeCategory(ItemIndex - 1);
		}
		
		UpdateDetailsGeneric();
	}
	else if (UIScreenState == eUIScreenState_ResearchCategory || UIScreenState == eUIScreenState_CompletedProjects)
	{
		UpdateSelectedResearchInfo(ItemIndex);
	}
}

simulated function RefreshSquadDetailsPanel()
{
	mc.FunctionVoid("HideAllScreens");

	if(List.SelectedIndex > 0)
	{
		UpdateDataSoldierData();
	}
}

simulated function UpdateDetailsGeneric()
{
	mc.FunctionVoid("HideAllScreens");
}

simulated function UpdateDataSoldierData()
{
	local XComGameState_Unit Soldier;
	local XComGameState_CampaignSettings CurrentCampaign;
	local Texture2D SoldierPicture;

	Soldier = Squad[SelectedSoldierIndex];
	if (Soldier != none)
	{
		CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(CurrentCampaign.GameIndex, Soldier.ObjectID, 128, 128);

		mc.FunctionVoid("HideAllScreens");
		mc.BeginFunctionOp("SetSoldierData");
		
		if (SoldierPicture != none)
		{
			mc.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture))); // Picture Image
		}
		else
		{
			mc.QueueString("");
		}
		
		mc.QueueString(Soldier.GetSoldierClassTemplate().IconImage);
		mc.QueueString(class'UIUtilities_Image'.static.GetRankIcon(Soldier.GetSoldierRank(), Soldier.GetSoldierClassTemplateName()));
		mc.QueueString(class'X2ExperienceConfig'.static.GetRankName(Soldier.GetSoldierRank(), Soldier.GetSoldierClassTemplateName()));
		mc.QueueString(Soldier.GetFullName()); //Unit Name
		mc.QueueString(Soldier.GetSoldierClassTemplate().DisplayName); //Class Name
		mc.EndOp();

		SetSoldierStats();
		SetSoldierGear();
	}
}

simulated function SetSoldierStats()
{
	local int WillBonus, AimBonus, HealthBonus, MobilityBonus, TechBonus, PsiBonus, ArmorBonus, DodgeBonus;
	local string Health;
	local string Mobility;
	local string Aim;
	local string Will;
	local string Armor;
	local string Dodge;
	local string Tech;
	local string Psi;
	local XComGameState_Unit Unit;

	Unit = Squad[SelectedSoldierIndex];

	// Get Unit base stats and any stat modifications from abilities
	Will = string(int(Unit.GetCurrentStat(eStat_Will)) + Unit.GetUIStatFromAbilities(eStat_Will)) $ "/" $ string(int(Unit.GetMaxStat(eStat_Will)));
	Will = class'UIUtilities_Text'.static.GetColoredText(Will, Unit.GetMentalStateUIState());
	Aim = string(int(Unit.GetCurrentStat(eStat_Offense)) + Unit.GetUIStatFromAbilities(eStat_Offense));
	Health = string(int(Unit.GetCurrentStat(eStat_HP)) + Unit.GetUIStatFromAbilities(eStat_HP));
	Mobility = string(int(Unit.GetCurrentStat(eStat_Mobility)) + Unit.GetUIStatFromAbilities(eStat_Mobility));
	Tech = string(int(Unit.GetCurrentStat(eStat_Hacking)) + Unit.GetUIStatFromAbilities(eStat_Hacking));
	Armor = string(int(Unit.GetCurrentStat(eStat_ArmorMitigation)) + Unit.GetUIStatFromAbilities(eStat_ArmorMitigation));
	Dodge = string(int(Unit.GetCurrentStat(eStat_Dodge)) + Unit.GetUIStatFromAbilities(eStat_Dodge));
	Psi = string(int(Unit.GetCurrentStat(eStat_PsiOffense)) + Unit.GetUIStatFromAbilities(eStat_PsiOffense));

	// Get bonus stats for the Unit from items
	WillBonus = Unit.GetUIStatFromInventory(eStat_Will, NewGameState);
	AimBonus = Unit.GetUIStatFromInventory(eStat_Offense, NewGameState);
	HealthBonus = Unit.GetUIStatFromInventory(eStat_HP, NewGameState);
	MobilityBonus = Unit.GetUIStatFromInventory(eStat_Mobility, NewGameState);
	TechBonus = Unit.GetUIStatFromInventory(eStat_Hacking, NewGameState);
	ArmorBonus = Unit.GetUIStatFromInventory(eStat_ArmorMitigation, NewGameState);
	DodgeBonus = Unit.GetUIStatFromInventory(eStat_Dodge, NewGameState);
	PsiBonus = Unit.GetUIStatFromInventory(eStat_PsiOffense, NewGameState);

	if (WillBonus > 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText("+"$WillBonus, eUIState_Good);
	else if (WillBonus < 0)
		Will $= class'UIUtilities_Text'.static.GetColoredText(""$WillBonus, eUIState_Bad);

	if (AimBonus > 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText("+"$AimBonus, eUIState_Good);
	else if (AimBonus < 0)
		Aim $= class'UIUtilities_Text'.static.GetColoredText(""$AimBonus, eUIState_Bad);

	if (HealthBonus > 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText("+"$HealthBonus, eUIState_Good);
	else if (HealthBonus < 0)
		Health $= class'UIUtilities_Text'.static.GetColoredText(""$HealthBonus, eUIState_Bad);

	if (MobilityBonus > 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText("+"$MobilityBonus, eUIState_Good);
	else if (MobilityBonus < 0)
		Mobility $= class'UIUtilities_Text'.static.GetColoredText(""$MobilityBonus, eUIState_Bad);

	if (TechBonus > 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText("+"$TechBonus, eUIState_Good);
	else if (TechBonus < 0)
		Tech $= class'UIUtilities_Text'.static.GetColoredText(""$TechBonus, eUIState_Bad);

	if (ArmorBonus > 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText("+"$ArmorBonus, eUIState_Good);
	else if (ArmorBonus < 0)
		Armor $= class'UIUtilities_Text'.static.GetColoredText(""$ArmorBonus, eUIState_Bad);

	if (DodgeBonus > 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText("+"$DodgeBonus, eUIState_Good);
	else if (DodgeBonus < 0)
		Dodge $= class'UIUtilities_Text'.static.GetColoredText(""$DodgeBonus, eUIState_Bad);

	if (PsiBonus > 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText("+"$PsiBonus, eUIState_Good);
	else if (PsiBonus < 0)
		Psi $= class'UIUtilities_Text'.static.GetColoredText(""$PsiBonus, eUIState_Bad);

	//Stats will stack to the right, and clear out any unused stats 
	mc.BeginFunctionOp("SetSoldierStats");

	if (Health != "")
	{
		mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strHealthLabel);
		mc.QueueString(Health);
	}
	if (Mobility != "")
	{
		mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strMobilityLabel);
		mc.QueueString(Mobility);
	}
	if (Aim != "")
	{
		mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strAimLabel);
		mc.QueueString(Aim);
	}
	
	if (Will != "")
	{
		mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strWillLabel);
		mc.QueueString(Will);
	}
	if (Armor != "")
	{
		mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strArmorLabel);
		mc.QueueString(Armor);
	}
	if (Dodge != "")
	{
		mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strDodgeLabel);
		mc.QueueString(Dodge);
	}
	if (Tech != "")
	{
		mc.QueueString(class'UITLE_SkirmishModeMenu'.default.m_strTechLabel);
		mc.QueueString(Tech);
	}
	if (Psi != "")
	{
		mc.QueueString(class'UIUtilities_Text'.static.GetColoredText(class'UITLE_SkirmishModeMenu'.default.m_strPsiLabel, eUIState_Psyonic));
		mc.QueueString(class'UIUtilities_Text'.static.GetColoredText(Psi, eUIState_Psyonic));
	}
	else
	{
		mc.QueueString(" ");
		mc.QueueString(" ");
	}

	mc.EndOp();
}

simulated function SetSoldierGear()
{
	local XComGameState_Unit Soldier;
	local XComGameState_Item equippedItem;
	local array<XComGameState_Item> utilItems;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2SoldierClassTemplate SoldierClassTemplate;

	Soldier = Squad[SelectedSoldierIndex];

	if (Soldier == none)
	{
		return;
	}

	mc.BeginFunctionOp("SetSoldierGear");

	equippedItem = Soldier.GetItemInSlot(eInvSlot_Armor, NewGameState, false);
	mc.QueueString("Armor");//armor
	mc.QueueString(equippedItem.GetMyTemplate().strImage);
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());

	equippedItem = Soldier.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, false);
	mc.QueueString("Primary Weapon");//primary
	mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
	//primary weapon image is handled in a different function to support the stack of weapon attachments

	mc.QueueString("Secondary Weapon");//secondary
	
	//we need to handle the reaper claymore
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Soldier.GetSoldierClassTemplateName());
	if (SoldierClassTemplate.DataName == 'Reaper')
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('Reaper_Claymore'));
		mc.QueueString(EquipmentTemplate.strImage);
		mc.QueueString(EquipmentTemplate.GetItemFriendlyName());
	}
	else
	{
		equippedItem = Soldier.GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState, false);
		mc.QueueString(equippedItem.GetMyTemplate().strImage);
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
	}
	

	utilItems = Soldier.GetAllItemsInSlot(eInvSlot_Utility, NewGameState, false, true);
	mc.QueueString("Utility Items");//util 1

	if(utilItems.Length > 0)
	{
		mc.QueueString(utilItems[0].GetMyTemplate().strImage);
		mc.QueueString(utilItems[0].GetMyTemplate().GetItemFriendlyNameNoStats());
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	if (utilItems.Length > 1)
	{
		mc.QueueString(utilItems[1].GetMyTemplate().strImage);// util 2 and 3
		mc.QueueString(utilItems[1].GetMyTemplate().GetItemFriendlyNameNoStats());
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	equippedItem = Soldier.GetItemInSlot(eInvSlot_GrenadePocket, NewGameState, false);
	if (equippedItem != none)
	{
		mc.QueueString(equippedItem.GetMyTemplate().strImage);
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	

	mc.EndOp();

	equippedItem = Soldier.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, false);
	SetSoldierPrimaryWeapon(equippedItem);

	equippedItem = Soldier.GetItemInSlot(eInvSlot_HeavyWeapon, NewGameState, false);
	mc.BeginFunctionOp("SetSoldierHeavyWeaponSlot");
	if (equippedItem != none && Soldier.HasHeavyWeapon())
	{
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyNameNoStats());
		mc.QueueString(equippedItem.GetMyTemplate().strImage);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}
	mc.EndOp();
	
	equippedItem = Soldier.GetItemInSlot(eInvSlot_CombatSim, NewGameState, false);
	mc.BeginFunctionOp("SetSoldierPCS");
	if (equippedItem != none)
	{
		mc.QueueString(equippedItem.GetMyTemplate().GetItemFriendlyName(equippedItem.ObjectID));
		mc.QueueString(class'UIUtilities_Image'.static.GetPCSImage(equippedItem));
		mc.QueueString(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR);
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
		mc.QueueString(class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR);
	}
	mc.EndOp();
}

simulated function SetSoldierPrimaryWeapon(XComGameState_Item Item)
{
	local int i;
	local array<string> NewImages;

	if( Item == none )
	{
		MC.FunctionVoid("SetSoldierPrimaryWeapon");
		return;
	}

	NewImages = Item.GetWeaponPanelImages();
	
	//If no image at all is defined, mark it as empty 
	if( NewImages.length == 0 )
	{
		NewImages.AddItem("");
	}

	MC.BeginFunctionOp("SetSoldierPrimaryWeapon");

	for( i = 0; i < NewImages.Length; i++ )
		MC.QueueString(NewImages[i]);

	MC.EndOp();
}

simulated function UpdateSelectedEquipmentInfo(int ItemIndex)
{
	local UIMechaListItem ListItem;
	local X2ItemTemplate Template;

	MC.FunctionVoid("HideAllScreens");

	ListItem = UIMechaListItem(List.GetItem(ItemIndex));

	if (ListItem.metadataString == class'UITLE_SkirmishModeMenu'.default.m_strPCSNone || ListItem.metadataString == "")
	{
		UpdateDataSoldierData();
		return;
	}
	else
	{
		Template = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(ListItem.metadataString));
	}

	mc.BeginFunctionOp("SetEnemyPodData");

	mc.QueueString(Template.GetItemFriendlyNameNoStats());
	mc.QueueString(Template.GetItemBriefSummary());
	mc.QueueString("");

	mc.QueueString(Template.strImage); // Item Image
	mc.QueueString("");
	mc.EndOp();
}

simulated function UpdateSelectedResearchInfo(int ItemIndex)
{
	local UIMechaListItem ListItem;
	local X2ResistanceTechUpgradeTemplate Template;
	local InventoryUpgrade Upgrade;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;

	MC.FunctionVoid("HideAllScreens");

	ListItem = UIMechaListItem(List.GetItem(ItemIndex));

	if (ListItem.metadataString == "")
	{
		UpdateDataSoldierData();
		return;
	}
	else
	{
		Template = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager().FindTemplate(name(ListItem.metadataString));
	}

	mc.BeginFunctionOp("SetEnemyPodData");

	mc.QueueString(Template.DisplayName);
	mc.QueueString(Template.Description);
	mc.QueueString(Template.GetRequirementsText());

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach Template.InventoryUpgrades (Upgrade)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate(Upgrade.TemplateName);
		if (ItemTemplate != none)
		{
			mc.QueueString(ItemTemplate.strImage);
			mc.QueueString(ItemTemplate.GetItemFriendlyNameNoStats());
		}
	}

	mc.EndOp();
}

function UIMechaListItem GetListItem(int ItemIndex, optional bool bDisableItem, optional string DisabledReason)
{
	local UIMechaListItem CustomizeItem;
	local UIPanel Item;

	if (ItemIndex >= List.ItemContainer.ChildPanels.Length)
	{
		CustomizeItem = Spawn(class'UIMechaListItem', List.itemContainer);
		CustomizeItem.bAnimateOnInit = false;
		CustomizeItem.InitListItem(, , 400);
	}
	else
	{
		Item = List.GetItem(ItemIndex);
		CustomizeItem = UIMechaListItem(Item);
	}
	
	return CustomizeItem;
}

simulated function UpdateData()
{
	HideListItems();
	
	mc.FunctionString("SetScreenTitle", ScreenTitle);
	mc.FunctionString("SetScreenSubtitle", ScreenSubtitles[UIScreenState]);
	
	switch (UIScreenState)
	{
	case eUIScreenState_Squad:
		UpdateDataSquad();
		break;
	case eUIScreenState_Research:
		UpdateDataResearch();
		break;
	case eUIScreenState_ResearchCategory:
		UpdateDataResearchCategory();
		break;
	case eUIScreenState_CompletedProjects:
		UpdateDataCompletedProjects();
		break;
	case eUIScreenState_Soldier:
		UpdateDataSoldierData();
		UpdateDataSoldierOptions();
		// OpenPromotionScreen();
		break;
	case eUIScreenState_Abilities:
		UpdateDataSoldierAbilities();
		break;
	case eUIScreenState_PrimaryWeapon:
		UpdateDataPrimaryWeapon();
		break;
	case eUIScreenState_SecondaryWeapon:
		UpdateDataSecondaryWeapon();
		break;
	case eUIScreenState_Armor:
		UpdateDataArmor();
		break;
	case eUIScreenState_PCS:
		UpdateDataPCS();
		break;
	case eUIScreenState_UtilItem1:
		UpdateDataUtilItem1();
		break;
	case eUIScreenState_UtilItem2:
		UpdateDataUtilItem2();
		break;
	case eUIScreenState_UtilItem3:
		UpdateDataUtilItem3();
		break;
	case eUIScreenState_GrenadePocket:
		UpdateDataGrenadePocket();
		break;
	case eUIScreenState_AmmoPocket:
		UpdateDataAmmoPocket();
		break;
	case eUIScreenState_HeavyWeapon:
		UpdateDataHeavyWeapon();
		break;
	case eUIScreenState_WeaponAttachment:
		UpdateDataWeaponAttachment();
		break;
	case eUIScreenState_CustomSlot:
		UpdateDataCustomSlot();
		break;
	};

	if( List.IsSelectedNavigation() )
		List.Navigator.SelectFirstAvailable();
}

simulated function UpdateDataSquad()
{
	local int Index;
	local string PromoteIcon;
	local string NewIcon;

	GetListItem(0).EnableNavigation();
	GetListItem(Index).UpdateDataValue("Research", "", , , OnClickEditSoldier);

	for( Index = 1; Index < Squad.Length + 1; Index++ )
	{
		GetListItem(Index).EnableNavigation();

		if (!HasEarnedNewAbility[Index - 1])
		{
			PromoteIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_PromotionIcon, 20, 20, 0) $ " ";
		}
		else
		{
			PromoteIcon = "";
		}

		if (IsNew[Index - 1])
		{
			NewIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 20, 20, 0) $ " ";
		}
		else
		{
			NewIcon = "";
		}

		GetListItem(Index).UpdateDataValue(NewIcon $ PromoteIcon $ Squad[Index - 1].GetFullName(), "", , , OnClickEditSoldier);
	}

	//mc.FunctionVoid("HideAllScreens");
	//RefreshSquadDetailsPanel();
}

simulated function OnClickEditSoldier(UIMechaListItem MechaItem)
{
	local int SelectedIndex;

	for (SelectedIndex = 0; SelectedIndex < List.ItemContainer.ChildPanels.Length; SelectedIndex++)
	{
		if (GetListItem(SelectedIndex) == MechaItem)
		{
			break;
		}
	}

	if (SelectedIndex > 0)
	{
		// Selecting a soldier
		SelectedSoldierIndex = SelectedIndex - 1;
		UIScreenState = eUIScreenState_Soldier;
	}
	else
	{
		// Selecting the Research menu
		UIScreenState = eUIScreenState_Research;
	}
	
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	UpdateData();
}

simulated function UpdateDataSoldierOptions()
{
	local XComGameState_Unit Soldier;
	local int Index;
	local int ModIndex;
	local array<XComGameState_Item> EquippedPCSs;
	local string PcsText;
	local array<XComGameState_Item> EquippedUtilityItems;
	local XComGameState_Item EquippedItem;
	local int NumUtilitySlots;
	local string PromoteIcon;
	local int NumAttachmentSlots;
	local int NumAttachmentsEquipped;
	local int AttachmentIndex;
	local array<name> Attachments;
	local X2WeaponUpgradeTemplate AttachmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<CHItemSlot> ModSlots;
	local string LockedReason;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Update the inventory UI items to match the selected soldier's inventory
	Soldier = Squad[SelectedSoldierIndex];
	Index = 0;

	// Primary Weapon
	EquippedItem = Soldier.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, false);
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue("Primary Weapon", GetInventoryDisplayText(EquippedItem), OnClickPrimaryWeapon);
	Index++;

	// Weapon Attachments
	NumAttachmentSlots = 0;
	if (X2WeaponTemplate(EquippedItem.GetMyTemplate()) != none)
	{
		NumAttachmentSlots = X2WeaponTemplate(EquippedItem.GetMyTemplate()).NumUpgradeSlots;
	}
	
	Attachments = EquippedItem.GetMyWeaponUpgradeTemplateNames();
		
	for (AttachmentIndex = 0; AttachmentIndex < NumAttachmentSlots || AttachmentIndex < Attachments.Length; AttachmentIndex++)
	{
		if (AttachmentIndex < NumAttachmentSlots && Attachments.Length > AttachmentIndex)
		{
			AttachmentTemplate = X2WeaponUpgradeTemplate(ItemTemplateManager.FindItemTemplate(Attachments[AttachmentIndex]));
			if (AttachmentTemplate != none)
			{
				GetListItem(Index).EnableNavigation();
				if (AttachmentIndex >= NumAttachmentSlots)
				{
					GetListItem(Index).SetDisabled(true, "Cannot change attachment");
				}
				GetListItem(Index).UpdateDataValue("Attachment " $ string(AttachmentIndex + 1), AttachmentTemplate.GetItemFriendlyNameNoStats(), OnClickWeaponAttachment);
				GetListItem(Index).metadataInt = AttachmentIndex;
				GetListItem(Index).metadataString = "Attachment";
				Index++;
				continue;
			}
		}

		GetListItem(Index).EnableNavigation();
		if (AttachmentIndex >= NumAttachmentSlots)
		{
			GetListItem(Index).SetDisabled(true, "Cannot change attachment");
		}
		GetListItem(Index).UpdateDataValue("Attachment " $ string(AttachmentIndex + 1), "None", OnClickWeaponAttachment);
		GetListItem(Index).metadataInt = AttachmentIndex;
		GetListItem(Index).metadataString = "Attachment";
		Index++;
	}

	// Secondary Weapon
	EquippedItem = Soldier.GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState, false);
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue("Secondary Weapon", GetInventoryDisplayText(EquippedItem), OnClickSecondaryWeapon);
	Index++;

	// Armor
	EquippedItem = Soldier.GetItemInSlot(eInvSlot_Armor, NewGameState, false);
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue("Armor", GetInventoryDisplayText(EquippedItem), OnClickArmor);
	Index++;

	// PCS
	if (Soldier.IsSufficientRankToEquipPCS() && Soldier.GetCurrentStat(eStat_CombatSims) > 0)
	{
		EquippedPCSs = Soldier.GetAllItemsInSlot(eInvSlot_CombatSim, NewGameState, false, true);
		PcsText = class'UITLE_SkirmishModeMenu'.default.m_strPCSNone;
		if (EquippedPCSs.Length > 0)
		{
			PcsText = EquippedPCSs[0].GetMyTemplate().GetItemFriendlyNameNoStats();
		}
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(class'UITLE_SkirmishModeMenu'.default.m_PCSLabel, PcsText, OnClickPCS);
		Index++;
	}

	// Utility Slots
	NumUtilitySlots = Soldier.GetCurrentStat(eStat_UtilityItems);
	EquippedUtilityItems = Soldier.GetAllItemsInSlot(eInvSlot_Utility, NewGameState, false, true);

	// Utility Slot 1
	if (NumUtilitySlots > 0)
	{
		GetListItem(Index).EnableNavigation();
		if (EquippedUtilityItems.Length > 0)
		{
			GetListItem(Index).UpdateDataValue("Utility Item 1", EquippedUtilityItems[0].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem1);
		}
		else
		{
			GetListItem(Index).UpdateDataValue("Utility Item 1", "None", OnClickUtilItem1);
		}
		Index++;
	}

	// Utility Slot 2
	if (NumUtilitySlots > 1)
	{
		GetListItem(Index).EnableNavigation();
		if (EquippedUtilityItems.Length > 1)
		{
			GetListItem(Index).UpdateDataValue("Utility Item 2", EquippedUtilityItems[1].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem2);
		}
		else
		{
			GetListItem(Index).UpdateDataValue("Utility Item 2", "None", OnClickUtilItem2);
		}
		Index++;
	}

	// Utility Slot 3
	if (NumUtilitySlots > 2)
	{
		GetListItem(Index).EnableNavigation();
		if (EquippedUtilityItems.Length > 2)
		{
			GetListItem(Index).UpdateDataValue("Utility Item 3", EquippedUtilityItems[2].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem3);
		}
		else
		{
			GetListItem(Index).UpdateDataValue("Utility Item 3", "None", OnClickUtilItem3);
		}
		Index++;
	}

	// Grenade pocket
	if (Soldier.HasGrenadePocket())
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_GrenadePocket, NewGameState, false);
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue("Grenade Pocket", GetInventoryDisplayText(EquippedItem), OnClickGrenadePocket);
		Index++;
	}

	// Ammo pocket
	if (Soldier.HasAmmoPocket())
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_AmmoPocket, NewGameState, false);
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue("Ammo Pocket", GetInventoryDisplayText(EquippedItem), OnClickAmmoPocket);
		Index++;
	}

	// Heavy weapon
	if (Soldier.HasHeavyWeapon())
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_HeavyWeapon, NewGameState, false);
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(class'UITLE_SkirmishModeMenu'.default.m_HeavyWeaponLabel, GetInventoryDisplayText(EquippedItem), OnClickHeavyWeapon);
		Index++;
	}

	// Custom slots
	ModSlots = class'CHItemSlot'.static.GetAllSlotTemplates();
	for (ModIndex = 0; ModIndex < ModSlots.Length; ModIndex++)
	{
		if (ModSlots[ModIndex].UnitHasSlot(Soldier, LockedReason, NewGameState))
		{
			EquippedItem = Soldier.GetItemInSlot(ModSlots[ModIndex].InvSlot, NewGameState, false);
			GetListItem(Index).EnableNavigation();
			GetListItem(Index).UpdateDataValue(ToPascalCase(class'UIArmory_Loadout'.default.m_strInventoryLabels[ModSlots[ModIndex].InvSlot]), GetInventoryDisplayText(EquippedItem), , , OnClickCustomSlot);
			GetListItem(Index).metadataInt = ModSlots[ModIndex].InvSlot;
			Index++;
		}
	}

	// The abilities/promotion button
	GetListItem(Index).EnableNavigation();

	if (!HasEarnedNewAbility[SelectedSoldierIndex])
	{
		PromoteIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_PromotionIcon, 20, 20, 0) $ " ";
		GetListItem(Index).UpdateDataValue(PromoteIcon $ "Learn New Ability", "", OnClickAbilities);
	}
	else
	{
		GetListItem(Index).UpdateDataValue("Class Abilities", "", OnClickAbilities);
	}

	Index++;
}

simulated function string GetInventoryDisplayText(XComGameState_Item ItemState)
{
	local string Text;
	if (ItemState != none)
	{
		Text = ItemState.GetMyTemplate().GetItemFriendlyNameNoStats();
	}
	else
	{
		Text = "None";
	}
	return Text;
}

simulated function OnClickPrimaryWeapon()
{
	UIScreenState = eUIScreenState_PrimaryWeapon;
	UpdateData();
}

simulated function OnClickWeaponAttachment()
{
	UIScreenState = eUIScreenState_WeaponAttachment;
	UpdateData();
}

simulated function OnClickSecondaryWeapon()
{
	UIScreenState = eUIScreenState_SecondaryWeapon;
	UpdateData();
}

simulated function OnClickArmor()
{
	UIScreenState = eUIScreenState_Armor;
	UpdateData();
}

simulated function OnClickPCS()
{
	UIScreenState = eUIScreenState_PCS;
	UpdateData();
}

simulated function OnClickUtilItem1()
{
	UIScreenState = eUIScreenState_UtilItem1;
	UpdateData();
}

simulated function OnClickUtilItem2()
{
	UIScreenState = eUIScreenState_UtilItem2;
	UpdateData();
}

simulated function OnClickUtilItem3()
{
	UIScreenState = eUIScreenState_UtilItem3;
	UpdateData();
}

simulated function OnClickGrenadePocket()
{
	UIScreenState = eUIScreenState_GrenadePocket;
	UpdateData();
}

simulated function OnClickAmmoPocket()
{
	UIScreenState = eUIScreenState_AmmoPocket;
	UpdateData();
}

simulated function OnClickHeavyWeapon()
{
	UIScreenState = eUIScreenState_HeavyWeapon;
	UpdateData();
}

simulated function OnClickCustomSlot(UIMechaListItem MechaItem)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	SelectedInventorySlot = EInventorySlot(MechaItem.metadataInt);
	UIScreenState = eUIScreenState_CustomSlot;
	UpdateData();
}

simulated function OnClickAbilities()
{
	UIScreenState = eUIScreenState_Abilities;
	UpdateData();
}

simulated function UpdateDataPrimaryWeapon()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate WeaponTemplate;
	local array<X2WeaponTemplate> WeaponTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				WeaponTemplate = X2WeaponTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (WeaponTemplate != none 
					&& Soldier.GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate) 
					&& WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(WeaponTemplate.DataName, SelectedSoldierIndex)))
				{
					WeaponTemplates.AddItem(WeaponTemplate);
				}
			}
		}
	}

	UpdateDataItems(WeaponTemplates, OnClickUpgradePrimaryWeapon);
}

simulated function bool ItemAlreadyInUse(name TemplateName, int ExcludeSoldierIndex)
{
	local int Index;

	for (Index = 0; Index < Squad.Length; Index++)
	{
		if (Index != ExcludeSoldierIndex)
		{
			if (Squad[Index].HasItemOfTemplateType(TemplateName))
			{
				return true;
			}
		}
	}

	return false;
}

simulated function UpdateDataItems(array<X2ItemTemplate> ItemTemplates, delegate<OnSelectorClickDelegate> OnSelectorClickDelegate, optional bool bIncludeNone = false)
{
	local int Index;
	local X2ItemTemplate ItemTemplate;

	ItemTemplates.Sort(SortItemListByTier);
	
	Index = 0;
	if (bIncludeNone)
	{
		GetListItem(Index).UpdateDataValue("None", "", , , OnSelectorClickDelegate);
		GetListItem(Index).EnableNavigation();
		Index++;
	}

	foreach ItemTemplates(ItemTemplate)
	{
		GetListItem(Index).UpdateDataValue(ItemTemplate.GetItemFriendlyNameNoStats(), "", , , OnSelectorClickDelegate);
		GetListItem(Index).metadataString = string(ItemTemplate.DataName);
		GetListItem(Index).EnableNavigation();
		Index++;
	}
}

simulated function OnClickUpgradePrimaryWeapon(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_PrimaryWeapon, -1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataWeaponAttachment()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local int Index;
	local X2WeaponUpgradeTemplate AttachmentTemplate;
	local array<X2WeaponUpgradeTemplate> AttachmentTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	local XComGameState_Item EquippedWeapon;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();
	EquippedWeapon = Soldier.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, false);

	Index = 0;
	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				AttachmentTemplate = X2WeaponUpgradeTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (AttachmentTemplate != none 
					&& AttachmentTemplate.CanApplyUpgradeToWeapon(EquippedWeapon, SelectedAttachmentIndex)
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(AttachmentTemplate.DataName, SelectedSoldierIndex)))
				{
					AttachmentTemplates.AddItem(AttachmentTemplate);
				}
			}
		}
	}

	UpdateDataItems(AttachmentTemplates, OnClickUpgradeWeaponAttachment, true);
}

simulated function OnClickUpgradeWeaponAttachment(UIMechaListItem MechaItem)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponUpgradeTemplate EquipmentTemplate;
	local XComGameState_Item EquippedItem;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	EquippedItem = Squad[SelectedSoldierIndex].GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, false);
	EquippedItem.DeleteWeaponUpgradeTemplate(SelectedAttachmentIndex);

	if (MechaItem.metadataString != "")
	{
		EquipmentTemplate = X2WeaponUpgradeTemplate(ItemTemplateManager.FindItemTemplate( name(MechaItem.metadataString) ));
		if (EquipmentTemplate != none)
		{
			EquippedItem.ApplyWeaponUpgradeTemplate(EquipmentTemplate, SelectedAttachmentIndex);
		}
	}
	
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataSecondaryWeapon()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate WeaponTemplate;
	local array<X2WeaponTemplate> WeaponTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				WeaponTemplate = X2WeaponTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (WeaponTemplate != none 
					&& Soldier.GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate) 
					&& WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(WeaponTemplate.DataName, SelectedSoldierIndex)))
				{
					WeaponTemplates.AddItem(WeaponTemplate);
				}
			}
		}
	}

	UpdateDataItems(WeaponTemplates, OnClickUpgradeSecondaryWeapon);
}

simulated function OnClickUpgradeSecondaryWeapon(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_SecondaryWeapon, -1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataArmor()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ArmorTemplate ArmorTemplate;
	local array<X2ArmorTemplate> ArmorTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				ArmorTemplate = X2ArmorTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (ArmorTemplate != none 
					&& Soldier.GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate)
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(ArmorTemplate.DataName, SelectedSoldierIndex)))
				{
					ArmorTemplates.AddItem(ArmorTemplate);
				}
			}
		}
	}

	UpdateDataItems(ArmorTemplates, OnClickUpgradeArmor);
}

simulated function OnClickUpgradeArmor(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_Armor, -1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataPCS()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<X2EquipmentTemplate> EquipmentTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (EquipmentTemplate != none 
					&& EquipmentTemplate.InventorySlot == eInvSlot_CombatSim
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(EquipmentTemplate.DataName, SelectedSoldierIndex)))
				{
					EquipmentTemplates.AddItem(EquipmentTemplate);
				}
			}
		}
	}

	UpdateDataItems(EquipmentTemplates, OnClickUpgradePCS, true);
}

simulated function OnClickUpgradePCS(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_CombatSim, 0);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataUtilItem1()
{
	UpdateDataUtilItem(0, OnClickUpgradeUtil1);
}

simulated function OnClickUpgradeUtil1(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_Utility, 0);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataUtilItem2()
{
	UpdateDataUtilItem(1, OnClickUpgradeUtil2);
}

simulated function OnClickUpgradeUtil2(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_Utility, 1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataUtilItem3()
{
	UpdateDataUtilItem(2, OnClickUpgradeUtil3);
}

simulated function OnClickUpgradeUtil3(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_Utility, 2);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataUtilItem(int UtilityItemIndex, delegate<OnSelectorClickDelegate> OnSelectorClickDelegate)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<X2EquipmentTemplate> EquipmentTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (EquipmentTemplate != none 
					&& IsUtilityItemAllowed(EquipmentTemplate, UtilityItemIndex)
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(EquipmentTemplate.DataName, SelectedSoldierIndex)))
				{
					EquipmentTemplates.AddItem(EquipmentTemplate);
				}
			}
		}
	}

	UpdateDataItems(EquipmentTemplates, OnSelectorClickDelegate, true);
}

simulated function bool IsUtilityItemAllowed(X2EquipmentTemplate EquipmentTemplate, int UtilitySlotIndex)
{
	local bool bAllow;
	local XComGameState_Unit Soldier;
	local array<XComGameState_Item> ExistingItems;
	local XComGameState_Item ExistingItem;

	if (EquipmentTemplate.InventorySlot != eInvSlot_Utility)
	{
		return false;
	}

	bAllow = true;
	Soldier = Squad[SelectedSoldierIndex];

	// If it's a unique item, like offensive grenades, we don't want to show it if the soldier already has a grenade
	// But we do want to show it if the item they're replacing is a unique item of the same category
	if (!Soldier.RespectsUniqueRule(EquipmentTemplate, eInvSlot_Utility))
	{
		bAllow = false;
		ExistingItems = Soldier.GetAllItemsInSlot(eInvSlot_Utility, , , true);

		if (ExistingItems.Length > UtilitySlotIndex)
		{
			ExistingItem = ExistingItems[UtilitySlotIndex];
		}

		if (ExistingItem != none)
		{
			if (ExistingItem.GetMyTemplate().ItemCat == EquipmentTemplate.ItemCat)
			{
				bAllow = true;
			}
		}
	}

	return bAllow;
}

simulated function UpdateDataGrenadePocket()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local int Index;
	local X2GrenadeTemplate GrenadeTemplate;
	local array<X2GrenadeTemplate> GrenadeTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	Index = 0;
	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				GrenadeTemplate = X2GrenadeTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (GrenadeTemplate != none 
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(GrenadeTemplate.DataName, SelectedSoldierIndex)))
				{
					GrenadeTemplates.AddItem(GrenadeTemplate);
				}
			}
		}
	}

	UpdateDataItems(GrenadeTemplates, OnClickUpgradeGrenadePocket, true);
}

simulated function OnClickUpgradeGrenadePocket(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_GrenadePocket, -1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataAmmoPocket()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local int Index;
	local X2AmmoTemplate AmmoTemplate;
	local array<X2AmmoTemplate> AmmoTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	Index = 0;
	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				AmmoTemplate = X2AmmoTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (AmmoTemplate != none 
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(AmmoTemplate.DataName, SelectedSoldierIndex)))
				{
					AmmoTemplates.AddItem(AmmoTemplate);
				}
			}
		}
	}

	UpdateDataItems(AmmoTemplates, OnClickUpgradeAmmoPocket, true);
}

simulated function OnClickUpgradeAmmoPocket(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_AmmoPocket, -1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataHeavyWeapon()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<X2EquipmentTemplate> EquipmentTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (EquipmentTemplate != none 
					&& EquipmentTemplate.InventorySlot == eInvSlot_HeavyWeapon
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(EquipmentTemplate.DataName, SelectedSoldierIndex)))
				{
					EquipmentTemplates.AddItem(EquipmentTemplate);
				}
			}
		}
	}

	UpdateDataItems(EquipmentTemplates, OnClickUpgradeHeavyWeapon, true);
}

simulated function OnClickUpgradeHeavyWeapon(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), eInvSlot_HeavyWeapon, -1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function UpdateDataCustomSlot()
{
	local CHItemSlot CustomSlot;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<X2EquipmentTemplate> EquipmentTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	local XComGameState_Unit Soldier;
	
	CustomSlot = class'CHItemSlotStore'.static.GetStore().GetSlot(SelectedInventorySlot);
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Soldier = Squad[SelectedSoldierIndex];
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach PurchasedTemplateNames(PurchasedTemplateName)
	{
		UpgradeTemplate = UpgradeTemplateManager.FindTemplate(PurchasedTemplateName);
		if (UpgradeTemplate != none)
		{
			foreach UpgradeTemplate.InventoryUpgrades (ItemUpgrade)
			{
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (EquipmentTemplate != none 
					&& CustomSlot.ShowItemInLockerList(Soldier, none, EquipmentTemplate, NewGameState)
					&& !(ItemUpgrade.bSingle && ItemAlreadyInUse(EquipmentTemplate.DataName, SelectedSoldierIndex)))
				{
					EquipmentTemplates.AddItem(EquipmentTemplate);
				}
			}
		}
	}

	UpdateDataItems(EquipmentTemplates, OnClickUpgradeCustomSlot, true);
}

simulated function OnClickUpgradeCustomSlot(UIMechaListItem MechaItem)
{
	EquipItem(name(MechaItem.metadataString), SelectedInventorySlot, -1);
	UIScreenState = eUIScreenState_Soldier;
	UpdateData();
}

simulated function EquipItem(name TemplateName, EInventorySlot Slot, int MultiItemSlotIndex)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<XComGameState_Item> ExistingItems;
	local XComGameState_Item ExistingItem, NewItem;
	local XComGameState_Unit Soldier;

	`LOG("====== EquipItem");
	`LOG("====== MultiItemSlotIndex: " @ string(MultiItemSlotIndex));
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	Soldier = Squad[SelectedSoldierIndex];
	EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(TemplateName));

	if (EquipmentTemplate != none)
	{
		`LOG("====== EquipmentTemplate.DataName: " @ string(EquipmentTemplate.DataName));
	}

	if (MultiItemSlotIndex == -1)
	{	
		// Only one item for this slot, so just grab it
		ExistingItem = Soldier.GetItemInSlot(Slot);
	}
	else
	{
		// Could be multiple, so get the right one to replace
		ExistingItems = Soldier.GetAllItemsInSlot(Slot, , , true);
		`LOG("====== ExistingItems.Length: " @ string(ExistingItems.Length));

		if (ExistingItems.Length > MultiItemSlotIndex)
		{
			ExistingItem = ExistingItems[MultiItemSlotIndex];
			`LOG("====== ExistingItem.GetMyTemplate().DataName: " @ string(ExistingItem.GetMyTemplate().DataName));
		}
	}

	if (ExistingItem != none)
	{
		`LOG("====== ExistingItem.GetMyTemplate().DataName: " @ string(ExistingItem.GetMyTemplate().DataName));
		if (ExistingItem.GetMyTemplate() == EquipmentTemplate)
		{	
			// Trying to swap with the same item, so don't bother doing anything
			return;
		}

		// There is an item equipped here, so need to remove it first
		if (!Soldier.CanRemoveItemFromInventory( ExistingItem, NewGameState ))
		{
			`LOG("====== Cannot remove item from inventory");
		}

		if (!Soldier.RemoveItemFromInventory( ExistingItem, NewGameState ))
		{
			`LOG("====== Failed to remove item from inventory");
		}
	}

	// Now we add our item
	if (TemplateName != '' && EquipmentTemplate != none)
	{
		NewItem = EquipmentTemplate.CreateInstanceFromTemplate( NewGameState );
		if (!Soldier.CanAddItemToInventory(EquipmentTemplate, Slot, NewGameState))
		{
			`LOG("====== Cannot add item to inventory");
		}

		if (!Soldier.AddItemToInventory( NewItem, Slot, NewGameState ))
		{
			`LOG("====== Failed to add item to inventory");
		}

		Soldier.ValidateLoadout(NewGameState);
	}

	`LOG("====== EquipItem should be swapped");
}

simulated function int SortItemListByTier(X2ItemTemplate A, X2ItemTemplate B)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local int TierA, TierB;

	TierA = A.Tier;
	TierB = B.Tier;

	if (TierA > TierB) return -1;
	else if (TierA < TierB) return 1;
	else return 0;
}

simulated function UpdateDataSoldierAbilities()
{
	local XComGameState_Unit Soldier;
	local int RankIter;
	local int MaxRank;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> RankAbilities;
	local SoldierClassAbilityType RankAbility;
	local int Index;
	local SCATProgression Progression;
	local bool Earned;
	local X2AbilityTemplate AbilityTemplate;
	local UIMechaListItem ListItem;

	Soldier = Squad[SelectedSoldierIndex];
	MaxRank = Soldier.GetSoldierClassTemplate().GetMaxConfiguredRank();
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Index = 0;

	for (RankIter = 0; RankIter < MaxRank; RankIter++)
	{
		RankAbilities = Soldier.AbilityTree[RankIter].Abilities;

		foreach RankAbilities(RankAbility)
		{
			if (RankAbility.AbilityName != '')
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(RankAbility.AbilityName);
				Earned = Soldier.HasSoldierAbility(RankAbility.AbilityName);

				ListItem = GetListItem(Index);
				ListItem.UpdateDataCheckbox(AbilityTemplate.LocFriendlyName, "", Earned, OnAbilityCheckboxChanged);
				ListItem.metadataString = string(RankAbility.AbilityName);
				Index++;

				ListItem.SetDisabled(true);
				if (!Soldier.HasPurchasedPerkAtRank(RankIter) && RankIter <= Soldier.GetRank() - 1 && Soldier.MeetsAbilityPrerequisites(RankAbility.AbilityName))
				{
					ListItem.SetDisabled(false);
				}
			}
		}
	}
}

simulated function OnAbilityCheckboxChanged(UICheckbox CheckboxControl)
{
	local XComGameState_Unit Soldier;
	local UIMechaListItem ListItem;
	local int RankIter;
	local int BranchIter;
	local int AbilityRank;
	local int AbilityBranch;

	Soldier = Squad[SelectedSoldierIndex];
	ListItem = UIMechaListItem(List.GetItem(SelectedAbilityIndex));
	for (RankIter = 0; RankIter < Soldier.AbilityTree.length; RankIter++)
	{
		for (BranchIter = 0; BranchIter < Soldier.AbilityTree[RankIter].Abilities.length; BranchIter++)
		{
			if (Soldier.AbilityTree[RankIter].Abilities[BranchIter].AbilityName == name(ListItem.metadataString))
			{
				AbilityRank = RankIter;
				AbilityBranch = BranchIter;
			}
		}
	}
	
	Soldier.BuySoldierProgressionAbility(NewGameState, AbilityRank, AbilityBranch, 0);
	HasEarnedNewAbility[SelectedSoldierIndex] = true;
	UpdateData();
}

simulated function UpdateAbilityInfo(int ItemIndex)
{
	local XComGameState_Unit Soldier;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local UIMechaListItem ListItem;
	local UISummary_Ability AbilityData;
	local int RankIter;
	local int BranchIter;
	local int AbilityRank;

	MC.FunctionVoid("HideAllScreens");

	ListItem = UIMechaListItem(List.GetItem(ItemIndex));
	
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	if (ListItem.metadataString != "")
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(name(ListItem.metadataString));
	
		AbilityData = AbilityTemplate.GetUISummary_Ability();
		
		AbilityRank = -1;
		Soldier = Squad[SelectedSoldierIndex];
		for (RankIter = 0; RankIter < Soldier.AbilityTree.length; RankIter++)
		{
			for (BranchIter = 0; BranchIter < Soldier.AbilityTree[RankIter].Abilities.length; BranchIter++)
			{
				if (Soldier.AbilityTree[RankIter].Abilities[BranchIter].AbilityName == AbilityTemplate.DataName)
				{
					AbilityRank = RankIter;
				}
			}
		}

		MC.BeginFunctionOp("SetAbilityData");
		MC.QueueString(AbilityTemplate.IconImage);
		MC.QueueString(AbilityData.Name);
		MC.QueueString(AbilityData.Description);//AbilityTemplate.LocLongDescription);
		MC.QueueString("" /*unlockString*/ );
		
		if (AbilityRank > -1)
		{
			MC.QueueString(class'UIUtilities_Image'.static.GetRankIcon(AbilityRank + 1, Soldier.GetSoldierClassTemplateName())); /*rank icon*/
		}
		else
		{
			MC.QueueString("" /*rank icon*/ );
		}
		MC.EndOp();
	}
	else
	{
		MC.BeginFunctionOp("SetAbilityData");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");//AbilityTemplate.LocLongDescription);
		MC.QueueString("" /*unlockString*/ );
		MC.QueueString("" /*rank icon*/ );
		MC.EndOp();
	}
}

simulated function UpdateDataResearch()
{
	local int Index;
	local string Icon;

	// Add a button to view completed projects
	Index = 0;
	Icon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_GearIcon, 20, 20, 0) $ " ";
	GetListItem(Index).UpdateDataValue(Icon $ "View Completed Projects", "", OnClickCompletedProjects);
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("Primary Weapons", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Primary;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("Secondary Weapons", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Secondary;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("Heavy Weapons", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Heavy;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("Utility Items", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Utility;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("Armor", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Armor;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("Attachments", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Attachment;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("PCS Items", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_PCS;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue("Miscellaneous", "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Misc;
	GetListItem(Index).EnableNavigation();
	Index++;
}

simulated function OnClickResearchCategory(UIMechaListItem MechaItem)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	SelectedUpgradeCategory = EUpgradeCategory(MechaItem.metadataInt);
	UIScreenState = eUIScreenState_ResearchCategory;
	UpdateData();
}

simulated function UpdateDataResearchCategory()
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local int Index;
	local array<X2ResistanceTechUpgradeTemplate> Templates;
	local X2ResistanceTechUpgradeTemplate Template;
	local X2ArmorTemplate ArmorTemplate;
	local array<name> TemplateNames;
	local name TemplateName;

	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	TemplateManager.GetTemplateNames(TemplateNames);

	//`LOG("=== Found this many template names: " $ string(TemplateNames.Length));

	foreach TemplateNames(TemplateName)
	{
		//`LOG("=== Checking: " $ string(TemplateName));
		if (!LadderData.HasPurchasedTechUpgrade(TemplateName))
		{
			//`LOG("=== Not Purchased");
			Template = TemplateManager.FindTemplate(TemplateName);
			if (Template != none)
			{
				if (Template.Category == SelectedUpgradeCategory && Template.AtleastOneInventoryUpgradeExists())
				{
					//`LOG("=== Template Found");
					//`LOG("=== Template DataName: " $ string(Template.DataName));
					//`LOG("=== Template DisplayName: " $ Template.DisplayName);
					//`LOG("=== Template Description: " $ Template.Description);
					GetListItem(Index).UpdateDataValue(Template.DisplayName, string(Template.Cost), , , OnClickUpgradeTech);
					GetListItem(Index).metadataString = string(Template.DataName);
					GetListItem(Index).metadataInt = Template.Cost;
					GetListItem(Index).EnableNavigation();

					if (!LadderData.HasRequiredTechs(Template))
					{
						GetListItem(Index).SetDisabled(true, Template.GetRequirementsText());
					}
					else if (!LadderData.CanAfford(Template))
					{
						GetListItem(Index).SetDisabled(true, "Not enough points");
					}

					Index++;
				}
			}
		}
	}
}

simulated function OnClickUpgradeTech(UIMechaListItem MechaItem)
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	local int SelectedIndex;
	local int UpgradeIndex;

	for (SelectedIndex = 0; SelectedIndex < List.ItemContainer.ChildPanels.Length; SelectedIndex++)
	{
		if (GetListItem(SelectedIndex) == MechaItem)
		{
			break;
		}
	}
	
	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Template = TemplateManager.FindTemplate(name(GetListItem(SelectedIndex).metadataString));

	PurchaseTechUpgrade(Template);
	UpdateData();
}

simulated function PurchaseTechUpgrade(X2ResistanceTechUpgradeTemplate Template)
{
	LadderData.PurchaseTechUpgrade(Template.DataName, NewGameState);
	UpdateCreditsText();
	UpdateData();
}

simulated function OnClickCompletedProjects()
{
	UIScreenState = eUIScreenState_CompletedProjects;
	UpdateData();
}

simulated function UpdateDataCompletedProjects()
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local int Index;
	local X2ResistanceTechUpgradeTemplate Template;
	local array<name> TemplateNames;
	local name TemplateName;

	Index = 0;
	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	TemplateNames = LadderData.GetAvailableTechUpgradeNames();

	foreach TemplateNames(TemplateName)
	{
		Template = TemplateManager.FindTemplate(TemplateName);
		if (Template != none && Template.AtleastOneInventoryUpgradeExists())
		{
			GetListItem(Index).UpdateDataValue(Template.DisplayName, string(Template.Cost), , , );
			GetListItem(Index).metadataString = string(Template.DataName);
			GetListItem(Index).EnableNavigation();
			Index++;
		}
	}
}

simulated function OnCancel()
{
	switch (UIScreenState)
	{
	case eUIScreenState_Squad:
		// do nothing
		return;
	case eUIScreenState_Research:
		UIScreenState = eUIScreenState_Squad;
		break;
	case eUIScreenState_ResearchCategory:
		UIScreenState = eUIScreenState_Research;
		break;
	case eUIScreenState_CompletedProjects:
		UIScreenState = eUIScreenState_Research;
		break;
	case eUIScreenState_Soldier:
		UIScreenState = eUIScreenState_Squad;
		break;
	case eUIScreenState_Abilities:
	case eUIScreenState_PrimaryWeapon:
	case eUIScreenState_WeaponAttachment:
	case eUIScreenState_SecondaryWeapon:
	case eUIScreenState_Armor:
	case eUIScreenState_PCS:
	case eUIScreenState_UtilItem1:
	case eUIScreenState_UtilItem2:
	case eUIScreenState_UtilItem3:
	case eUIScreenState_GrenadePocket:
	case eUIScreenState_AmmoPocket:
	case eUIScreenState_HeavyWeapon:
	case eUIScreenState_CustomSlot:
		UIScreenState = eUIScreenState_Soldier;
		break;
	};

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	UpdateData();
}

simulated function UpdateCreditsText()
{
	CreditsText.SetText("Credits: " @ string(LadderData.Credits));
}

simulated function HideListItems()
{
	local int Index;

	for (Index = 0; Index < List.ItemCount; Index++)
	{
		List.GetItem(Index).Destroy();
	}
	List.ClearItems();
}

simulated function OnContinueButtonClicked(UIButton button)
{
	local XComGameState_CampaignSettings CampaignSettings;
	local XComGameState_HeadquartersXCom XComHQ;

	`GAMERULES.SubmitGameState(NewGameState);

	// See if our tech was researched
	`LOG("=== OnContinueButtonClicked");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ != None)
	{
		`LOG("=== OnContinueButtonClicked XComHQ found");
		if (XComHQ.IsTechResearched('BattlefieldMedicine'))
		{
			`LOG("=== OnContinueButtonClicked BattlefieldMedicine researched");
		}
	}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	LadderData.OnComplete('eUIAction_Accept');

	CampaignSettings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	`FXSLIVE.BizAnalyticsLadderUpgrade( CampaignSettings.BizAnalyticsCampaignID, 
											string(LadderData.ProgressionChoices1[LadderData.LadderRung - 1]),
											string(LadderData.ProgressionChoices2[LadderData.LadderRung - 1]),
											1 );
}

private function bool IsNarrativeLadder()
{
	if (LadderData != none)
	{
		if (!LadderData.bRandomLadder)
		{
			return true;
		}
	}

	return false;
}

simulated function OpenPromotionScreen()
{
	local UITactical_PromotionHero PromotionScreen;

	PromotionScreen = Spawn(class'UITactical_PromotionHero',self);
	PromotionScreen.InitPromotion(Squad[SelectedSoldierIndex], NewGameState);
	Movie.Stack.Push(PromotionScreen);
	PromotionScreen.Show();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (IsNarrativeLadder())
	{
		return super.OnUnrealCommand(cmd, arg);
	}

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_KEY_ENTER, arg);
		return true;
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		OnCancel();
		bHandled = true;
		break;
		
	case class'UIUtilities_Input'.const.FXS_DPAD_UP :
	case class'UIUtilities_Input'.const.FXS_ARROW_UP :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP :
	case class'UIUtilities_Input'.const.FXS_KEY_W :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_UP, arg);
		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN :
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN :
	case class'UIUtilities_Input'.const.FXS_KEY_S :
		bHandled = Navigator.OnUnrealCommand(class'UIUtilities_Input'.const.FXS_ARROW_DOWN, arg);
		break;

	default:
		bHandled = false;
		break;
	}

	if( !bHandled && Navigator.GetSelected() != none && Navigator.GetSelected().OnUnrealCommand(cmd, arg) )
	{
		bHandled = true;
	}


	// always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

simulated function string ToPascalCase(string Str)
{
	local string Result;
	local int Index;
	local string LastChar;

	for (Index = 0; Index < Len(Str); Index++)
	{
		if (Index == 0 || LastChar == " " || LastChar == "-")
		{
			Result = Result $ Caps(Mid(Str,Index,1));
		}
		else
		{
			Result = Result $ Locs(Mid(Str,Index,1));
		}

		LastChar = Mid(Str,Index,1);
	}

	return Result;
}

defaultproperties
{
	//Package = "NONE";
	//MCName = "theScreen"; // this matches the instance name of the EmptyScreen MC in components.swf
	LibID = "EmptyScreen"; // this is used to determine whether a LibID was overridden when UIMovie loads a screen
	
	Package = "/ package/gfxTLE_SkirmishMenu/TLE_SkirmishMenu";

	InputState = eInputState_Consume;
	bHideOnLoseFocus = false;
	SelectedColumn = 0; 
}