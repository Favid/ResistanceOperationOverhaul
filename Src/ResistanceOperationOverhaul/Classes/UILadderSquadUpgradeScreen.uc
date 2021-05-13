class UILadderSquadUpgradeScreen extends UIScreen dependson(AStructs) config(SoldierUpgrades);

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

var int PendingAbilityRank;
var int PendingAbilityBranch;
var name PendingUpgradeName;

var int LastSelectedIndexes[EUIScreenState] <BoundEnum = EUIScreenState>;

var UIText CreditsText;
var UIText ScienceText;
var UIPanel CreditsPanel;
var UIBGBox Background;
var UILargeButton ContinueButton;

var UIList List;

var XComGameState_HeadquartersXCom XComHQ;
var XComGameState NewGameState;
var XComGameStateHistory History;
var XComGameState_LadderProgress_Override LadderData;

var localized string m_ScreenSubtitles_eUIScreenState_Squad;
var localized string m_ScreenSubtitles_eUIScreenState_Research;
var localized string m_ScreenSubtitles_eUIScreenState_ResearchCategory;
var localized string m_ScreenSubtitles_eUIScreenState_CompletedProjects;
var localized string m_ScreenSubtitles_eUIScreenState_Soldier;
var localized string m_ScreenSubtitles_eUIScreenState_PrimaryWeapon;
var localized string m_ScreenSubtitles_eUIScreenState_WeaponAttachment;
var localized string m_ScreenSubtitles_eUIScreenState_SecondaryWeapon;
var localized string m_ScreenSubtitles_eUIScreenState_Armor;
var localized string m_ScreenSubtitles_eUIScreenState_PCS;
var localized string m_ScreenSubtitles_eUIScreenState_UtilItem1;
var localized string m_ScreenSubtitles_eUIScreenState_UtilItem2;
var localized string m_ScreenSubtitles_eUIScreenState_UtilItem3;
var localized string m_ScreenSubtitles_eUIScreenState_GrenadePocket;
var localized string m_ScreenSubtitles_eUIScreenState_AmmoPocket;
var localized string m_ScreenSubtitles_eUIScreenState_HeavyWeapon;
var localized string m_ScreenSubtitles_eUIScreenState_Abilities;
var localized string m_ScreenSubtitles_eUIScreenState_CustomSlot;

var localized string m_ScreenTitle;
var localized string m_Credits;
var localized string m_Science;
var localized string m_Continue;
var localized string m_Research;
var localized string m_CompletedResearch;
var localized string m_PrimaryWeapon;
var localized string m_SecondaryWeapon;
var localized string m_WeaponAttachment;
var localized string m_Armor;
var localized string m_PCS;
var localized string m_UtilityItem;
var localized string m_GrenadePocket;
var localized string m_AmmoPocket;
var localized string m_HeavyWeapon;
var localized string m_NewAbility;
var localized string m_ClassAbilities;
var localized string m_None;
var localized string m_PrimaryWeaponCat;
var localized string m_SecondaryWeaponCat;
var localized string m_HeavyWeaponCat;
var localized string m_UtilityItemCat;
var localized string m_ArmorCat;
var localized string m_WeaponAttachmentCat;
var localized string m_PCSCat;
var localized string m_MiscCat;
var localized string m_GrenadeCat;
var localized string m_AmmoCat;
var localized string m_VestCat;
var localized string m_ErrorNotEnoughCredits;
var localized string m_ConfirmResearchTitle;
var localized string m_ConfirmResearchText;
var localized string m_ConfirmContinueTitle;
var localized string m_ConfirmContinueText;
var localized string m_Requires;
var localized string m_SaleTooltip;

const CreditsIcon = "UIEvent_engineer";
const ScienceIcon = "img:///UILibrary_Common.UIEvent_science";

var string CreditsPrefix;
var string SciencePrefix;

delegate OnSelectorClickDelegate(UIMechaListItem MechaItem);

simulated function OnInit()
{
	local XComGameState_LadderProgress_Override LocalLadderData;

	`LOG("==== OnInit");

	LocalLadderData = XComGameState_LadderProgress_Override(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override'));
	if (!IsOverhaulLadder(LocalLadderData))
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
	local int CreditsX, CreditsY;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local name NewUpgrade;
	local X2ResistanceTechUpgradeTemplate NewUpgradeTemplate;
	local array<XComGameState_Item> UtilityItems;
	local XComGameState_Item UtilityItem;

	`LOG("==== InitScreen");

	LadderData = XComGameState_LadderProgress_Override(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override'));
	if (!IsOverhaulLadder(LadderData))
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
	LadderData.AddMissionCompletedRewards();
	LadderData.InitSaleOptions();
	
	foreach XComHQ.Squad(UnitStateRef)
	{
		Soldier = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitStateRef.ObjectID));
		if (!Soldier.bMissionProvided)
		{
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
	}

	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	foreach LadderData.ChosenMissionOption.FreeUpgrades (NewUpgrade)
	{
		NewUpgradeTemplate = UpgradeTemplateManager.FindTemplate(NewUpgrade);
		UpgradeSquadGear(NewUpgradeTemplate);
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
			
			for (RankIndex = 1; RankIndex < LadderData.LadderRung && RankIndex < NewSoldier.GetSoldierClassTemplate().GetMaxConfiguredRank(); RankIndex++)
			{
				`LOG("Ranking them up");
				NewSoldier.RankUpSoldier(NewGameState);
			}

			UpgradeSoldierGear(NewSoldier);
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
			// Remove all effects before ranking up, to avoid stat errors
			
			while (Soldier.AppliedEffects.Length > 0)
			{
				EffectRef = Soldier.AppliedEffects[Soldier.AppliedEffects.Length - 1];
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				Soldier.RemoveAppliedEffect(EffectState);
				Soldier.UnApplyEffectFromStats(EffectState);
			}

			while (Soldier.AffectedByEffects.Length > 0)
			{
				EffectRef = Soldier.AffectedByEffects[Soldier.AffectedByEffects.Length - 1];
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

				if (EffectState != None)
				{
					// Some effects like Stasis and ModifyStats need to be undone
					EffectState.GetX2Effect().UnitEndedTacticalPlay(EffectState, Soldier);
				}

				Soldier.RemoveAffectingEffect(EffectState);
				Soldier.UnApplyEffectFromStats(EffectState);
			}

			Soldier.RankUpSoldier(NewGameState);
			HasEarnedNewAbility.AddItem(false);
		}
		else
		{
			HasEarnedNewAbility.AddItem(true);
		}

		// Need to remove any utility items with a quantity of 0 for compatibility with Proficiency Class Pack
		UtilityItems = Soldier.GetAllItemsInSlot(eInvSlot_Utility, NewGameState, false, true);
		foreach UtilityItems (UtilityItem)
		{
			if (UtilityItem.Quantity <= 0)
			{
				Soldier.RemoveItemFromInventory(UtilityItem, NewGameState);
			}
		}
	}
	
	mc.FunctionString("SetScreenTitle", m_ScreenTitle);

	// Credits text
	CreditsPrefix = class'UIUtilities_Text'.static.InjectImage(CreditsIcon, 20, 20, 0) $ " " $ m_Credits $ ": ";
	SciencePrefix = class'UIUtilities_Text'.static.InjectImage(ScienceIcon, 20, 20, 0) $ " " $ m_Science $ ": ";
	CreditsX = -780;
	CreditsY = -460;

	Background = Spawn(class'UIBGBox', self);
	Background.bAnimateOnInit = false;
	Background.bCascadeFocus = false;
	Background.InitBG('SelectChoice_Background');
	Background.AnchorCenter();
	Background.SetPosition(CreditsX,CreditsY);
	Background.SetSize(200,80);
	Background.SetBGColor("cyan");
	Background.SetAlpha(0.9f);

	CreditsText = Spawn(class'UIText',self);
	CreditsText.bAnimateOnInit = false;
	CreditsText.InitText('CreditsText', CreditsPrefix $ string(LadderData.Credits),false);
	CreditsText.AnchorCenter();
	CreditsText.SetPosition(CreditsX + 15, CreditsY + 5);
	CreditsText.SetSize(200,40);
	CreditsText.SetText(CreditsPrefix $ string(LadderData.Credits));

	ScienceText = Spawn(class'UIText',self);
	ScienceText.bAnimateOnInit = false;
	ScienceText.InitText('ScienceText', SciencePrefix $ string(LadderData.Science),false);
	ScienceText.AnchorCenter();
	ScienceText.SetPosition(CreditsX + 15, CreditsY + 5 + 40);
	ScienceText.SetSize(200,40);
	ScienceText.SetText(SciencePrefix $ string(LadderData.Science));

	`LOG("=== SCORE: " $ string(LadderData.CumulativeScore));
	`LOG("=== CREDITS: " $ string(LadderData.Credits));
	`LOG("=== SCIENCE: " $ string(LadderData.Science));

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
	List.Navigator.LoopSelection = true;
	List.bPermitNavigatorToDefocus = true;
	List.Navigator.SelectFirstAvailable();
	List.SetWidth(445);
	List.EnableNavigation();
	List.OnSetSelectedIndex = OnSetSelectedIndex;

	// Continue button
	ContinueButton = Spawn(class'UILargeButton', LeftColumn);
	ContinueButton.InitLargeButton('ContinueButton', , , OnContinueButtonClicked);
	ContinueButton.SetPosition(500, 965);
	ContinueButton.DisableNavigation();

	// Not sure about this...
	LeftColumn.Navigator.SetSelected(List);
	
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
	
	if( `ISCONTROLLERACTIVE )
	{
		mc.QueueString(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.const.ICON_START, 26, 26, -5) @ m_Continue);
	}
	else
	{
		mc.QueueString(m_Continue);
	}

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

	LastSelectedIndexes[UIScreenState] = ItemIndex;

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
	else if (UIScreenState >= eUIScreenState_PrimaryWeapon && UIScreenState <= eUIScreenState_CustomSlot)
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
	mc.QueueString("Utility Items");

	// Utility 1
	if(utilItems.Length > 0 && utilItems[0].Quantity > 0)
	{
		mc.QueueString(utilItems[0].GetMyTemplate().strImage);
		mc.QueueString(utilItems[0].GetMyTemplate().GetItemFriendlyNameNoStats());
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	// Utility 2
	if (utilItems.Length > 1 && utilItems[1].Quantity > 0)
	{
		mc.QueueString(utilItems[1].GetMyTemplate().strImage);
		mc.QueueString(utilItems[1].GetMyTemplate().GetItemFriendlyNameNoStats());
	}
	else
	{
		mc.QueueString("");
		mc.QueueString("");
	}

	// Other utility slot
	equippedItem = FindThirdUtilityItemToDisplay(Soldier, utilItems);
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
	if (equippedItem != none && Soldier.HasHeavyWeapon(NewGameState))
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

simulated function XComGameState_Item FindThirdUtilityItemToDisplay(XComGameState_Unit Soldier, array<XComGameState_Item> UtilityItems)
{
	local XComGameState_Item ItemState;
	local array<CHItemSlot> ModSlots;
	local int ModIndex;
	local string LockedReason;

	ItemState = Soldier.GetItemInSlot(eInvSlot_GrenadePocket, NewGameState, false);
	if (ItemState != none && ItemState.Quantity > 0)
	{
		return ItemState;
	}

	ItemState = Soldier.GetItemInSlot(eInvSlot_AmmoPocket, NewGameState, false);
	if (ItemState != none && ItemState.Quantity > 0)
	{
		return ItemState;
	}

	if (UtilityItems.Length > 2 && UtilityItems[2].Quantity > 0)
	{
		return UtilityItems[2];
	}

	ModSlots = class'CHItemSlot'.static.GetAllSlotTemplates();
	for (ModIndex = 0; ModIndex < ModSlots.Length; ModIndex++)
	{
		if (ModSlots[ModIndex].UnitHasSlot(Soldier, LockedReason, NewGameState))
		{
			ItemState = Soldier.GetItemInSlot(ModSlots[ModIndex].InvSlot, NewGameState, false);
			if (ItemState != none && ItemState.Quantity > 0)
			{
				return ItemState;
			}
		}
	}

	return none;
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

function UIMechaListItem GetListItem(int ItemIndex)
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
	local string Subtitle;
	HideListItems();

	mc.FunctionString("SetScreenTitle", m_ScreenTitle);
	
	switch (UIScreenState)
	{
	case eUIScreenState_Squad:
		LastSelectedIndexes[eUIScreenState_Research] = 0;
		LastSelectedIndexes[eUIScreenState_Soldier] = 0;
		break;
	case eUIScreenState_Research:
		LastSelectedIndexes[eUIScreenState_ResearchCategory] = 0;
		LastSelectedIndexes[eUIScreenState_CompletedProjects] = 0;
		break;
	case eUIScreenState_Soldier:
		LastSelectedIndexes[eUIScreenState_Abilities] = 0;
		LastSelectedIndexes[eUIScreenState_PrimaryWeapon] = 0;
		LastSelectedIndexes[eUIScreenState_SecondaryWeapon] = 0;
		LastSelectedIndexes[eUIScreenState_Armor] = 0;
		LastSelectedIndexes[eUIScreenState_PCS] = 0;
		LastSelectedIndexes[eUIScreenState_UtilItem1] = 0;
		LastSelectedIndexes[eUIScreenState_UtilItem2] = 0;
		LastSelectedIndexes[eUIScreenState_UtilItem3] = 0;
		LastSelectedIndexes[eUIScreenState_GrenadePocket] = 0;
		LastSelectedIndexes[eUIScreenState_AmmoPocket] = 0;
		LastSelectedIndexes[eUIScreenState_HeavyWeapon] = 0;
		LastSelectedIndexes[eUIScreenState_WeaponAttachment] = 0;
		LastSelectedIndexes[eUIScreenState_CustomSlot] = 0;
		break;
	};
	
	switch (UIScreenState)
	{
	case eUIScreenState_Squad:
		Subtitle = m_ScreenSubtitles_eUIScreenState_Squad;
		UpdateDataSquad();
		break;
	case eUIScreenState_Research:
		Subtitle = m_ScreenSubtitles_eUIScreenState_Research;
		UpdateDataResearch();
		break;
	case eUIScreenState_ResearchCategory:
		Subtitle = m_ScreenSubtitles_eUIScreenState_ResearchCategory;
		UpdateDataResearchCategory();
		break;
	case eUIScreenState_CompletedProjects:
		Subtitle = m_ScreenSubtitles_eUIScreenState_CompletedProjects;
		UpdateDataCompletedProjects();
		break;
	case eUIScreenState_Soldier:
		Subtitle = m_ScreenSubtitles_eUIScreenState_Soldier;
		UpdateDataSoldierData();
		UpdateDataSoldierOptions();
		break;
	case eUIScreenState_Abilities:
		Subtitle = m_ScreenSubtitles_eUIScreenState_Abilities;
		UpdateDataSoldierAbilities();
		break;
	case eUIScreenState_PrimaryWeapon:
		Subtitle = m_ScreenSubtitles_eUIScreenState_PrimaryWeapon;
		UpdateDataPrimaryWeapon();
		break;
	case eUIScreenState_SecondaryWeapon:
		Subtitle = m_ScreenSubtitles_eUIScreenState_SecondaryWeapon;
		UpdateDataSecondaryWeapon();
		break;
	case eUIScreenState_Armor:
		Subtitle = m_ScreenSubtitles_eUIScreenState_Armor;
		UpdateDataArmor();
		break;
	case eUIScreenState_PCS:
		Subtitle = m_ScreenSubtitles_eUIScreenState_PCS;
		UpdateDataPCS();
		break;
	case eUIScreenState_UtilItem1:
		Subtitle = m_ScreenSubtitles_eUIScreenState_UtilItem1;
		UpdateDataUtilItem1();
		break;
	case eUIScreenState_UtilItem2:
		Subtitle = m_ScreenSubtitles_eUIScreenState_UtilItem2;
		UpdateDataUtilItem2();
		break;
	case eUIScreenState_UtilItem3:
		Subtitle = m_ScreenSubtitles_eUIScreenState_UtilItem3;
		UpdateDataUtilItem3();
		break;
	case eUIScreenState_GrenadePocket:
		Subtitle = m_ScreenSubtitles_eUIScreenState_GrenadePocket;
		UpdateDataGrenadePocket();
		break;
	case eUIScreenState_AmmoPocket:
		Subtitle = m_ScreenSubtitles_eUIScreenState_AmmoPocket;
		UpdateDataAmmoPocket();
		break;
	case eUIScreenState_HeavyWeapon:
		Subtitle = m_ScreenSubtitles_eUIScreenState_HeavyWeapon;
		UpdateDataHeavyWeapon();
		break;
	case eUIScreenState_WeaponAttachment:
		Subtitle = m_ScreenSubtitles_eUIScreenState_WeaponAttachment;
		UpdateDataWeaponAttachment();
		break;
	case eUIScreenState_CustomSlot:
		Subtitle = m_ScreenSubtitles_eUIScreenState_CustomSlot;
		UpdateDataCustomSlot();
		break;
	};
	
	mc.FunctionString("SetScreenSubtitle", Subtitle);

	if( List.IsSelectedNavigation() )
		List.SetSelectedIndex(LastSelectedIndexes[UIScreenState]);
}

simulated function UpdateDataSquad()
{
	local int Index;
	local string PromoteIcon;
	local string NewIcon;

	Index = 0;
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_Research, "", , , OnClickEditSoldier);

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
	GetListItem(Index).UpdateDataValue(m_PrimaryWeapon, GetInventoryDisplayText(EquippedItem), OnClickPrimaryWeapon);
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
				GetListItem(Index).UpdateDataValue(m_WeaponAttachment @ string(AttachmentIndex + 1), AttachmentTemplate.GetItemFriendlyNameNoStats(), OnClickWeaponAttachment);
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
		GetListItem(Index).UpdateDataValue(m_WeaponAttachment @ string(AttachmentIndex + 1), "None", OnClickWeaponAttachment);
		GetListItem(Index).metadataInt = AttachmentIndex;
		GetListItem(Index).metadataString = "Attachment";
		Index++;
	}

	// Secondary Weapon
	EquippedItem = Soldier.GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState, false);
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_SecondaryWeapon, GetInventoryDisplayText(EquippedItem), OnClickSecondaryWeapon);
	Index++;

	// Armor
	EquippedItem = Soldier.GetItemInSlot(eInvSlot_Armor, NewGameState, false);
	GetListItem(Index).EnableNavigation();
	GetListItem(Index).UpdateDataValue(m_Armor, GetInventoryDisplayText(EquippedItem), OnClickArmor);
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
		GetListItem(Index).UpdateDataValue(m_PCS, PcsText, OnClickPCS);
		Index++;
	}

	// Utility Slots
	NumUtilitySlots = Soldier.GetCurrentStat(eStat_UtilityItems);
	EquippedUtilityItems = Soldier.GetAllItemsInSlot(eInvSlot_Utility, NewGameState, false, true);

	// Utility Slot 1
	if (NumUtilitySlots > 0)
	{
		GetListItem(Index).EnableNavigation();
		if (EquippedUtilityItems.Length > 0 && EquippedUtilityItems[0].Quantity > 0)
		{
			GetListItem(Index).UpdateDataValue(m_UtilityItem @ string(1), EquippedUtilityItems[0].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem1);
		}
		else
		{
			GetListItem(Index).UpdateDataValue(m_UtilityItem @ string(1), "None", OnClickUtilItem1);
		}
		Index++;
	}

	// Utility Slot 2
	if (NumUtilitySlots > 1)
	{
		GetListItem(Index).EnableNavigation();
		if (EquippedUtilityItems.Length > 1 && EquippedUtilityItems[1].Quantity > 0)
		{
			GetListItem(Index).UpdateDataValue(m_UtilityItem @ string(2), EquippedUtilityItems[1].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem2);
		}
		else
		{
			GetListItem(Index).UpdateDataValue(m_UtilityItem @ string(2), "None", OnClickUtilItem2);
		}
		Index++;
	}

	// Utility Slot 3
	if (NumUtilitySlots > 2)
	{
		GetListItem(Index).EnableNavigation();
		if (EquippedUtilityItems.Length > 2 && EquippedUtilityItems[2].Quantity > 0)
		{
			GetListItem(Index).UpdateDataValue(m_UtilityItem @ string(3), EquippedUtilityItems[2].GetMyTemplate().GetItemFriendlyNameNoStats(), OnClickUtilItem3);
		}
		else
		{
			GetListItem(Index).UpdateDataValue(m_UtilityItem @ string(3), "None", OnClickUtilItem3);
		}
		Index++;
	}

	// Grenade pocket
	if (Soldier.HasGrenadePocket())
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_GrenadePocket, NewGameState, false);
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(m_GrenadePocket, GetInventoryDisplayText(EquippedItem), OnClickGrenadePocket);
		Index++;
	}

	// Ammo pocket
	if (Soldier.HasAmmoPocket())
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_AmmoPocket, NewGameState, false);
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(m_AmmoPocket, GetInventoryDisplayText(EquippedItem), OnClickAmmoPocket);
		Index++;
	}

	// Heavy weapon
	if (Soldier.HasHeavyWeapon(NewGameState))
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_HeavyWeapon, NewGameState, false);
		GetListItem(Index).EnableNavigation();
		GetListItem(Index).UpdateDataValue(m_HeavyWeapon, GetInventoryDisplayText(EquippedItem), OnClickHeavyWeapon);
		Index++;
	}

	// Custom slots
	ModSlots = class'CHItemSlot'.static.GetAllSlotTemplates();
	for (ModIndex = 0; ModIndex < ModSlots.Length; ModIndex++)
	{
		if (ModSlots[ModIndex].UnitHasSlot(Soldier, LockedReason, NewGameState) && ModSlots[ModIndex].IsUserEquipSlot)
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
		GetListItem(Index).UpdateDataValue(PromoteIcon $ m_NewAbility, "", OnClickAbilities);
	}
	else
	{
		GetListItem(Index).UpdateDataValue(m_ClassAbilities, "", OnClickAbilities);
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
		Text = m_None;
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

simulated function bool AttachmentAlreadyInUse(name TemplateName, int ExcludeSoldierIndex)
{
	local int Index;
	local XComGameState_Item ItemState;
	local array<name> AttachmentNames;

	for (Index = 0; Index < Squad.Length; Index++)
	{
		if (Index != ExcludeSoldierIndex)
		{
			ItemState = Squad[Index].GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState, false);
			if (ItemState != none && X2WeaponTemplate(ItemState.GetMyTemplate()).NumUpgradeSlots > 0)
			{
				AttachmentNames = ItemState.GetMyWeaponUpgradeTemplateNames();
				if (AttachmentNames.Find(TemplateName) != INDEX_NONE)
				{
					return true;
				}
			}
		}
	}

	return false;
}

simulated function bool PCSAlreadyInUse(name TemplateName, int ExcludeSoldierIndex)
{
	local int Index;
	local XComGameState_Item ItemState;

	for (Index = 0; Index < Squad.Length; Index++)
	{
		if (Index != ExcludeSoldierIndex)
		{
			ItemState = Squad[Index].GetItemInSlot(eInvSlot_CombatSim, NewGameState, false);
			if (ItemState != none && ItemState.GetMyTemplateName() == TemplateName)
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
		GetListItem(Index).UpdateDataValue(m_None, "", , , OnSelectorClickDelegate);
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
					&& !(ItemUpgrade.bSingle && AttachmentAlreadyInUse(AttachmentTemplate.DataName, SelectedSoldierIndex)))
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
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
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
					&& !(ItemUpgrade.bSingle && PCSAlreadyInUse(EquipmentTemplate.DataName, SelectedSoldierIndex)))
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
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
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
	local X2GrenadeTemplate GrenadeTemplate;
	local array<X2GrenadeTemplate> GrenadeTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

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
	local X2AmmoTemplate AmmoTemplate;
	local array<X2AmmoTemplate> AmmoTemplates;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local array<name> PurchasedTemplateNames;
	local name PurchasedTemplateName;
	local X2ResistanceTechUpgradeTemplate UpgradeTemplate;
	local InventoryUpgrade ItemUpgrade;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	PurchasedTemplateNames = LadderData.GetAvailableTechUpgradeNames();

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
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
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

		if (Slot == eInvSlot_PrimaryWeapon)
		{
			TransferAttachments(ExistingItem, NewItem);
		}

		Soldier.ValidateLoadout(NewGameState);
	}

	History.UpdateStateObjectCache(NewGameState);

	`LOG("====== EquipItem should be swapped");
}

simulated function int SortItemListByTier(X2ItemTemplate A, X2ItemTemplate B)
{
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
	local bool Earned;
	local X2AbilityTemplate AbilityTemplate;
	local UIMechaListItem ListItem;
	local string RankIcon;

	Soldier = Squad[SelectedSoldierIndex];
	MaxRank = Soldier.GetSoldierClassTemplate().GetMaxConfiguredRank();
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Index = 0;

	for (RankIter = 0; RankIter < MaxRank; RankIter++)
	{
		RankAbilities = Soldier.AbilityTree[RankIter].Abilities;
		RankIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.static.GetRankIcon(RankIter + 1, Soldier.GetSoldierClassTemplateName()), 20, 20, 0);

		foreach RankAbilities(RankAbility)
		{
			if (RankAbility.AbilityName != '')
			{
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(RankAbility.AbilityName);
				if (AbilityTemplate != none)
				{
					Earned = Soldier.HasSoldierAbility(RankAbility.AbilityName);

					ListItem = GetListItem(Index);
					ListItem.UpdateDataCheckbox(RankIcon @ AbilityTemplate.LocFriendlyName, "", Earned, OnAbilityCheckboxChanged);
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
}

simulated function OnAbilityCheckboxChanged(UICheckbox CheckboxControl)
{
	local XComGameState_Unit Soldier;
	local UIMechaListItem ListItem;
	local int RankIter;
	local int BranchIter;

	Soldier = Squad[SelectedSoldierIndex];
	ListItem = UIMechaListItem(List.GetItem(SelectedAbilityIndex));
	for (RankIter = 0; RankIter < Soldier.AbilityTree.length; RankIter++)
	{
		for (BranchIter = 0; BranchIter < Soldier.AbilityTree[RankIter].Abilities.length; BranchIter++)
		{
			if (Soldier.AbilityTree[RankIter].Abilities[BranchIter].AbilityName == name(ListItem.metadataString))
			{
				PendingAbilityRank = RankIter;
				PendingAbilityBranch = BranchIter;
			}
		}
	}

	ConfirmAbilitySelection();
}

simulated function ConfirmAbilitySelection()
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local UIMechaListItem ListItem;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	DialogData.eType = eDialog_Alert;
	DialogData.bMuteAcceptSound = true;
	DialogData.strTitle = class'UIArmory_Promotion'.default.m_strConfirmAbilityTitle;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNO;
	DialogData.fnCallback = ComfirmAbilityCallback;

	ListItem = UIMechaListItem(List.GetItem(SelectedAbilityIndex));
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(name(ListItem.metadataString));

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = AbilityTemplate.LocFriendlyName;
	DialogData.strText = `XEXPAND.ExpandString(class'UIArmory_Promotion'.default.m_strConfirmAbilityText);
	Movie.Pres.UIRaiseDialog(DialogData);
	UpdateNavHelp();
}

simulated function ComfirmAbilityCallback(Name Action)
{
	local XComGameState_Unit Soldier;

	if(Action == 'eUIAction_Accept')
	{
		Soldier = Squad[SelectedSoldierIndex];
		Soldier.BuySoldierProgressionAbility(NewGameState, PendingAbilityRank, PendingAbilityBranch, 0);
		HasEarnedNewAbility[SelectedSoldierIndex] = true;
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		List.SetSelectedIndex(SelectedAbilityIndex, true);
	}
	
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
	Icon = class'UIUtilities_Text'.static.InjectImage(ScienceIcon, 20, 20, 0) $ " ";
	GetListItem(Index).UpdateDataValue(Icon $ m_CompletedResearch, "", OnClickCompletedProjects);
	GetListItem(Index).EnableNavigation();
	Index++;

	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_PrimaryWeaponCat, eUpCat_Primary), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Primary;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_SecondaryWeaponCat, eUpCat_Secondary), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Secondary;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_HeavyWeaponCat, eUpCat_Heavy), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Heavy;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_ArmorCat, eUpCat_Armor), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Armor;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_GrenadeCat, eUpCat_Grenade), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Grenade;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_AmmoCat, eUpCat_Ammo), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Ammo;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_VestCat, eUpCat_Vest), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Vest;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_UtilityItemCat, eUpCat_Utility), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Utility;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_WeaponAttachmentCat, eUpCat_Attachment), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Attachment;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_PCSCat, eUpCat_PCS), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_PCS;
	GetListItem(Index).EnableNavigation();
	Index++;
	
	GetListItem(Index).UpdateDataValue(GetResearchCategoryText(m_MiscCat, eUpCat_Misc), "", , , OnClickResearchCategory);
	GetListItem(Index).metadataInt = eUpCat_Misc;
	GetListItem(Index).EnableNavigation();
	Index++;
}

simulated function string GetResearchCategoryText(string Text, EUpgradeCategory Category)
{
	if (LadderData.IsUpgradeOnSaleInCategory(Category))
	{
		return class'UIUtilities_Text'.static.GetColoredText(Text, eUIState_Good);
	}

	return Text;
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
	local X2ResistanceTechUpgradeTemplate Template;
	local array<name> TemplateNames;
	local name TemplateName;
	local int CreditsValue;
	local string CostString;
	local string NameString;
	local string CreditsString;

	Index = 0;
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

					if (LadderData.IsUpgradeOnSale(Template.DataName))
					{
						CreditsValue = Template.Cost * class'XComGameState_LadderProgress_Override'.default.SALE_CREDITS_MOD;
						CreditsString = class'UIUtilities_Text'.static.GetColoredText(string(CreditsValue), eUIState_Good);
						NameString = class'UIUtilities_Text'.static.GetColoredText(Template.DisplayName, eUIState_Good);
					}
					else
					{
						CreditsValue = Template.Cost;
						CreditsString = string(CreditsValue);
						NameString = Template.DisplayName;
					}

					CostString = "";
					if (Template.RequiredScience > 0)
					{
						CostString = CostString $ string(Template.RequiredScience) $ " " $ class'UIUtilities_Text'.static.InjectImage(ScienceIcon, 20, 20, 0) $ "  ";
					}

					CostString = CostString $ CreditsString $ " " $ class'UIUtilities_Text'.static.InjectImage(CreditsIcon, 20, 20, 0);

					GetListItem(Index).UpdateDataValue(NameString, CostString, , , OnClickUpgradeTech);
					GetListItem(Index).metadataString = string(Template.DataName);
					GetListItem(Index).metadataInt = CreditsValue;
					GetListItem(Index).EnableNavigation();

					if (!LadderData.HasRequiredTechs(Template))
					{
						GetListItem(Index).SetDisabled(true, Template.GetRequirementsText());
					}
					else if (!LadderData.CanAfford(Template))
					{
						GetListItem(Index).SetDisabled(true, m_ErrorNotEnoughCredits);
					}
					else if (LadderData.IsUpgradeOnSale(Template.DataName))
					{
						GetListItem(Index).BG.SetTooltipText(m_SaleTooltip, , , 10, , , , 0.0f);
					}

					Index++;
				}
			}
		}
	}
}

simulated function OnClickUpgradeTech(UIMechaListItem MechaItem)
{
	local int SelectedIndex;

	for (SelectedIndex = 0; SelectedIndex < List.ItemContainer.ChildPanels.Length; SelectedIndex++)
	{
		if (GetListItem(SelectedIndex) == MechaItem)
		{
			PendingUpgradeName = name(GetListItem(SelectedIndex).metadataString);
			break;
		}
	}

	ConfirmUpgradeSelection();
}

simulated function ConfirmUpgradeSelection()
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	DialogData.eType = eDialog_Alert;
	DialogData.bMuteAcceptSound = true;
	DialogData.strTitle = m_ConfirmResearchTitle;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNO;
	DialogData.fnCallback = ComfirmUpgradeCallback;
	
	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Template = TemplateManager.FindTemplate(PendingUpgradeName);

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Template.DisplayName;
	
	LocTag.IntValue0 = Template.Cost;
	if (LadderData.IsUpgradeOnSale(Template.DataName))
	{
		LocTag.IntValue0 = Template.Cost * class'XComGameState_LadderProgress_Override'.default.SALE_CREDITS_MOD; 
	}

	DialogData.strText = `XEXPAND.ExpandString(m_ConfirmResearchText);
	Movie.Pres.UIRaiseDialog(DialogData);
	UpdateNavHelp();
}

simulated function ComfirmUpgradeCallback(Name Action)
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;

	if(Action == 'eUIAction_Accept')
	{
		TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
		Template = TemplateManager.FindTemplate(PendingUpgradeName);
		PurchaseTechUpgrade(Template);
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
	}
	
	UpdateData();
}

simulated function PurchaseTechUpgrade(X2ResistanceTechUpgradeTemplate Template)
{
	LadderData.PurchaseTechUpgrade(Template.DataName, NewGameState);
	UpdateCreditsText();
	UpgradeSquadGear(Template);
	UpdateData();
}

simulated function UpgradeSquadGear(X2ResistanceTechUpgradeTemplate Template)
{
	local XComGameState_Unit Soldier;
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryUpgrade ItemUpgrade;
	local X2EquipmentTemplate EquipmentTemplate;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach Template.InventoryUpgrades (ItemUpgrade)
	{
		if (!ItemUpgrade.bSingle)
		{
			EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
			if (EquipmentTemplate != none)
			{
				foreach Squad(Soldier)
				{
					UpgradeIfBetter(Soldier, EquipmentTemplate);
				}
			}
		}
	}
}

simulated function UpgradeSoldierGear (XComGameState_Unit Soldier)
{
	local array<name> PurchasedUpgrades;
	local name UpgradeName;
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	local InventoryUpgrade ItemUpgrade;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;

	PurchasedUpgrades = LadderData.GetAvailableTechUpgradeNames();
	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach PurchasedUpgrades (UpgradeName)
	{
		Template = TemplateManager.FindTemplate(UpgradeName);
		foreach Template.InventoryUpgrades (ItemUpgrade)
		{
			if (!ItemUpgrade.bSingle)
			{
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(ItemUpgrade.TemplateName));
				if (EquipmentTemplate != none)
				{
					UpgradeIfBetter(Soldier, EquipmentTemplate);
				}
			}
		}
	}
}

private simulated function UpgradeIfBetter (XComGameState_Unit Soldier, X2EquipmentTemplate EquipmentTemplate)
{
	local X2ArmorTemplate NewArmorTemplate;
	local X2WeaponTemplate NewWeaponTemplate;
	local array<X2EquipmentTemplate> NewEquipmentTemplates;
	local bool ChangeMade;
	local XComGameState_Item EquippedItem;
	local XComGameState_Item NewlyEquippedItem;

	ChangeMade = false;

	// Primary Weapon
	NewWeaponTemplate = X2WeaponTemplate(EquipmentTemplate);
	if (NewWeaponTemplate != none 
		&& Soldier.GetSoldierClassTemplate().IsWeaponAllowedByClass(NewWeaponTemplate) 
		&& NewWeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon
		&& NewWeaponTemplate.bInfiniteItem)
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
		NewEquipmentTemplates.Length = 0;
		NewEquipmentTemplates.AddItem(NewWeaponTemplate);
		ChangeMade = Soldier.UpgradeEquipment(NewGameState, EquippedItem, NewEquipmentTemplates, eInvSlot_PrimaryWeapon, NewlyEquippedItem) || ChangeMade;

		if (ChangeMade)
		{
			TransferAttachments(EquippedItem, NewlyEquippedItem);
		}
	}

	// Secondary Weapon
	if (NewWeaponTemplate != none 
		&& Soldier.GetSoldierClassTemplate().IsWeaponAllowedByClass(NewWeaponTemplate) 
		&& NewWeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon
		&& NewWeaponTemplate.bInfiniteItem)
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState);
		NewEquipmentTemplates.Length = 0;
		NewEquipmentTemplates.AddItem(NewWeaponTemplate);
		ChangeMade = Soldier.UpgradeEquipment(NewGameState, EquippedItem, NewEquipmentTemplates, eInvSlot_SecondaryWeapon) || ChangeMade;
	}

	// Armor
	NewArmorTemplate = X2ArmorTemplate(EquipmentTemplate);
	if (NewArmorTemplate != none
		&& Soldier.GetSoldierClassTemplate().IsArmorAllowedByClass(NewArmorTemplate)
		&& NewArmorTemplate.bInfiniteItem)
	{
		EquippedItem = Soldier.GetItemInSlot(eInvSlot_Armor, NewGameState);
		NewEquipmentTemplates.Length = 0;
		NewEquipmentTemplates.AddItem(NewArmorTemplate);
		ChangeMade = Soldier.UpgradeEquipment(NewGameState, EquippedItem, NewEquipmentTemplates, eInvSlot_Armor) || ChangeMade;
	}

	if (ChangeMade)
	{
		Soldier.ValidateLoadout(NewGameState);
	}
}

private simulated function TransferAttachments(XComGameState_Item PrevEquippedItem, XComGameState_Item NewlyEquippedItem)
{
	local array<X2WeaponUpgradeTemplate> AttachmentTemplates;
	local X2WeaponUpgradeTemplate AttachmentTemplate;
	local int SlotIndex;

	// Transfer attachments to the new weapon
	if (PrevEquippedItem != none 
		&& NewlyEquippedItem != none 
		&& X2WeaponTemplate(PrevEquippedItem.GetMyTemplate()).NumUpgradeSlots > 0
		&& X2WeaponTemplate(NewlyEquippedItem.GetMyTemplate()).NumUpgradeSlots > 0)
	{
		SlotIndex = 0;
		AttachmentTemplates = PrevEquippedItem.GetMyWeaponUpgradeTemplates();
		foreach AttachmentTemplates (AttachmentTemplate)
		{
			if (X2WeaponTemplate(NewlyEquippedItem.GetMyTemplate()).NumUpgradeSlots > SlotIndex)
			{
				NewlyEquippedItem.ApplyWeaponUpgradeTemplate(AttachmentTemplate);
			}
			SlotIndex++;
		}
	}
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
	CreditsText.SetText(CreditsPrefix $ string(LadderData.Credits));
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
	local int Index;
	local bool bShowConfirmation;

	bShowConfirmation = false;
	for (Index = 0; Index < HasEarnedNewAbility.Length; Index++)
	{
		if (!HasEarnedNewAbility[Index])
		{
			bShowConfirmation = true;
			break;
		}
	}

	if (bShowConfirmation)
	{
		ConfirmContinue();
	}
	else
	{
		ContinueToNextScreen();
	}
}

simulated function ConfirmContinue()
{
	local TDialogueBoxData DialogData;
	
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	DialogData.eType = eDialog_Alert;
	DialogData.bMuteAcceptSound = true;
	DialogData.strTitle = m_ConfirmContinueTitle;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNO;
	DialogData.fnCallback = ConfirmContinueCallback;

	DialogData.strText = `XEXPAND.ExpandString(m_ConfirmContinueText);
	Movie.Pres.UIRaiseDialog(DialogData);
	UpdateNavHelp();
}

simulated function ConfirmContinueCallback(Name Action)
{
	if(Action == 'eUIAction_Accept')
	{
		ContinueToNextScreen();
	}
	else
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		UpdateData();
	}
}

simulated function ContinueToNextScreen()
{
	local XComGameState_CampaignSettings CampaignSettings;

	`GAMERULES.SubmitGameState(NewGameState);

	// See if our tech was researched
	//`LOG("=== OnContinueButtonClicked");
	//XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	//if (XComHQ != None)
	//{
		//`LOG("=== OnContinueButtonClicked XComHQ found");
		//if (XComHQ.IsTechResearched('BattlefieldMedicine'))
		//{
			//`LOG("=== OnContinueButtonClicked BattlefieldMedicine researched");
		//}
	//}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	LadderData.OnComplete('eUIAction_Accept');

	CampaignSettings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	`FXSLIVE.BizAnalyticsLadderUpgrade( CampaignSettings.BizAnalyticsCampaignID, 
											string(LadderData.ProgressionChoices1[LadderData.LadderRung - 1]),
											string(LadderData.ProgressionChoices2[LadderData.LadderRung - 1]),
											1 );
}

private function bool IsOverhaulLadder(XComGameState_LadderProgress_Override LocalLadderData)
{
	`LOG("==== IsOverhaulLadder");
	`LOG("==== IsOverhaulLadder LocalLadderData == none: " $ string(LocalLadderData == none));
	`LOG("==== IsOverhaulLadder LocalLadderData.bRandomLadder: " $ string(LocalLadderData.bRandomLadder));
	`LOG("==== IsOverhaulLadder LocalLadderData.Settings.UseCustomSettings: " $ string(LocalLadderData.Settings.UseCustomSettings));
	if (LocalLadderData == none || !LocalLadderData.bRandomLadder || !LocalLadderData.Settings.UseCustomSettings)
	{
		`LOG("==== IsOverhaulLadder Not an overhaul ladder");
		return false;
	}
	
	`LOG("==== IsOverhaulLadder Yes an overhaul ladder");
	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

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

	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		OnContinueButtonClicked(ContinueButton);
		bHandled = true;
		break;

	case class'UIUtilities_Input'.const.FXS_MOUSE_5:
	case class'UIUtilities_Input'.const.FXS_KEY_TAB:
	case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
		ToNextSoldier();
		bHandled = true;
		break;
		
	case class'UIUtilities_Input'.const.FXS_MOUSE_4:
	case class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT:
	case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
		ToPreviousSoldier();
		bHandled = true;
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

simulated function ToNextSoldier()
{
	if (UIScreenState >= eUIScreenState_Soldier)
	{
		SelectedSoldierIndex++;
		if (SelectedSoldierIndex >= Squad.Length)
		{
			SelectedSoldierIndex = 0;
		}
		
		LastSelectedIndexes[eUIScreenState_Squad] = SelectedSoldierIndex + 1;
		UIScreenState = eUIScreenState_Soldier;
		UpdateData();
	}
}

simulated function ToPreviousSoldier()
{
	if (UIScreenState >= eUIScreenState_Soldier)
	{
		SelectedSoldierIndex--;
		if (SelectedSoldierIndex < 0)
		{
			SelectedSoldierIndex = Squad.Length - 1;
		}
		
		LastSelectedIndexes[eUIScreenState_Squad] = SelectedSoldierIndex + 1;
		UIScreenState = eUIScreenState_Soldier;
		UpdateData();
	}
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
	LibID = "EmptyScreen"; // this is used to determine whether a LibID was overridden when UIMovie loads a screen
	
	Package = "/ package/gfxTLE_SkirmishMenu/TLE_SkirmishMenu";

	InputState = eInputState_Consume;
	bHideOnLoseFocus = false;
}