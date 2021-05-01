class XComGameState_LadderProgress_Override extends XComGameState_LadderProgress dependson(X2DataSet_ResistanceTechUpgrades) config (LadderOptions);

struct UnitEndState
{
	var XComGameState_Unit UnitState;
	var array<XComGameState_Item> Inventory;
};

struct MissionTypeOption
{
	var string MissionType0;
	var string MissionType1;
};

struct MissionOption
{
	var string MissionType;
	var int Credits;
	var int Science;
	var array<name> FreeUpgrades;
};

var config int CREDITS_BASE;
var config int CREDITS_LADDER_BONUS;
var config int CREDITS_NO_WOUNDS_BONUS;
var config int CREDITS_NO_DEATHS_BONUS;
var config array<int> SCIENCE_TABLE;

var array<name> PurchasedTechUpgrades;
var array<XComGameState_Unit> SoldierStatesBeforeUpgrades;
var LadderSettings Settings;
var array<RungConfig> CustomRungConfigurations;
var array<SoldierOption> FutureSoldierOptions;
var int Credits;
var int Science;
var MissionOption ChosenMissionOption; // set this when the player chooses a map type from UILadderChooseNextMission
var array<MissionTypeOption> LadderMissionTypeOptions;

var UILadderRewards RewardsScreen;
var UILadderSquadUpgradeScreen UpgradeScreen;
var UILadderChooseNextMission MissionScreen;

static function ProceedToNextRung( )
{
	local XComGameStateHistory History;
	local X2EventManager EventManager;
	local XComParcelManager ParcelManager;
	local XComTacticalMissionManager MissionManager;
	local X2TacticalGameRuleset Rules;

	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState StartState;

	local string MissionType;
	local MissionDefinition MissionDef;

	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local PlotTypeDefinition PlotType;

	local XComGameState_LadderProgress_Override LadderData, NextMissionLadder;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ, NextHQ;
	local StateObjectReference LocalPlayerReference, OriginalPlayerReference;
	local XComGameState_Player PlayerState;
	local XComGameState_Player NewPlayerState;
	local XComGameState_BaseObject BaseState;
	local XComGameState_Unit UnitState;
	local XComGameState_MissionSite MissionSite;

	local StateObjectReference UnitStateRef;

	local X2MissionTemplateManager MissionTemplateManager;
	local X2MissionTemplate MissionTemplate;

	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;

	local int SoldierIndex;

	local XComGameState_CampaignSettings CurrentCampaign, NextCampaign;
	
	local UnitEndState EndingState;
	local array<UnitEndState> EndingStates;
	local int EndingIndex;

	local array<Actor> Visualizers;
	local Actor Visualizer;

	local int CampaignSaveID;

	local XComGameState_Analytics CurrentAnalytics, CampaignAnalytics;

	`LOG("==== ProceedToNextRung");

	History = `XCOMHISTORY;
	ParcelManager = `PARCELMGR;
	MissionManager = `TACTICALMISSIONMGR;
	Rules = `TACTICALRULES;
	EventManager = `XEVENTMGR;

	LadderData = XComGameState_LadderProgress_Override(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override', true));
	if (LadderData == none || !LadderData.bRandomLadder || !LadderData.Settings.UseCustomSettings)
	{
		`LOG("==== LadderData not an overhaul ladder, performing normal routine");
		super.ProceedToNextRung();
		return;
	}
	
	`LOG("==== Overhaul ladder");

	CurrentCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CurrentAnalytics = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));

	// The squad after upgrades
	foreach XComHQ.Squad(UnitStateRef)
	{
		`LOG("=== Adding stuff to EndingStates");
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID( UnitStateRef.ObjectID));
		if (!UnitState.bMissionProvided)
		{
			`LOG("=== Adding one to EndingStates");
			EndingState.UnitState = UnitState;
		
			EndingState.Inventory.Length = 0;
			for (EndingIndex = 0; EndingIndex < EndingState.UnitState.InventoryItems.length; EndingIndex++)
			{
				EndingState.Inventory.AddItem(XComGameState_Item(History.GetGameStateForObjectID(EndingState.UnitState.InventoryItems[EndingIndex].ObjectID)));
			}
		
			EndingStates.AddItem(EndingState);
		}
	}

	// Case for completing a ladder
	if (LadderData.LadderRung + 1 > LadderData.LadderSize)
	{
		`LOG("===== Ladder completed");
		// Finished the ladder, delete the save so that next time the player will start from the beginning
		CampaignSaveID = `AUTOSAVEMGR.GetSaveIDForCampaign( CurrentCampaign );
		if (CampaignSaveID >= 0)
		{
			`ONLINEEVENTMGR.DeleteSaveGame( CampaignSaveID );
		}
		`ONLINEEVENTMGR.SaveLadderSummary( );

		LadderData.ProgressCommand = "disconnect";
		LadderData.LadderRung++;
		return;
	}

	// Case for restarting an existing ladder (which was previously abandoned or completed)
	if (LadderData.LadderRung == 0 && !LadderData.bNewLadder)
	{
		`LOG("===== Existing ladder");
		Visualizers = History.GetAllVisualizers( );

		if (History.ReadHistoryFromFile( "Ladders/", "Mission_" $ LadderData.LadderIndex $ "_" $ (LadderData.LadderRung + 1) $ "_" $ CurrentCampaign.DifficultySetting ))
		{
			`LOG("===== Save file found");
			foreach Visualizers( Visualizer ) // gotta get rid of all these since we'll be wiping out the history objects they may be referring to (but only if we loaded a history)
			{
				if (Visualizer.bNoDelete)
					continue;

				Visualizer.SetTickIsDisabled( true );
				Visualizer.Destroy( );
			}

			// abuse the history diffing function to copy data from the current campaign into the new start state
			CampaignAnalytics = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
			CampaignAnalytics.SingletonCopyForHistoryDiffDuplicate( CurrentAnalytics );

			NextHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			NextHQ.SeenCharacterTemplates = XComHQ.SeenCharacterTemplates;

			// transfer over the player's current score, campaign settings, and credits to the loaded history start state.
			NextMissionLadder = XComGameState_LadderProgress_Override( History.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress_Override' ) );
			NextMissionLadder.CumulativeScore = LadderData.CumulativeScore;
			NextMissionLadder.LastMissionState = LadderData.SoldierStatesBeforeUpgrades;
			NextMissionLadder.PurchasedTechUpgrades = LadderData.PurchasedTechUpgrades;
			NextMissionLadder.Settings = LadderData.Settings;
			NextMissionLadder.CustomRungConfigurations = LadderData.CustomRungConfigurations;
			NextMissionLadder.FutureSoldierOptions = LadderData.FutureSoldierOptions;
			NextMissionLadder.Credits = LadderData.Credits;
			NextMissionLadder.Science = LadderData.Science;
			NextMissionLadder.LadderMissionTypeOptions = LadderData.LadderMissionTypeOptions;
			NextMissionLadder.ChosenMissionOption = LadderData.ChosenMissionOption;

			// Maintain the campaign start times
			NextCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
			NextCampaign.SetStartTime( CurrentCampaign.StartTime );
			NextCampaign.HACK_ForceGameIndex( CurrentCampaign.GameIndex );
			NextCampaign.BizAnalyticsCampaignID = CurrentCampaign.BizAnalyticsCampaignID;
			
			// Update the squad we loaded from the save so that they have the gear and abilities for the new ladder we're playing
			SoldierIndex = 0;
			foreach NextHQ.Squad(UnitStateRef)
			{
				// pull the unit from the archives, and add it to the start state
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));

				if (!UnitState.bMissionProvided)
				{
					RefreshUnit(History, NextMissionLadder, UnitStateRef, EndingStates[SoldierIndex]);

					if (SoldierIndex < EndingStates.Length)
					{
						UpdateUnitCustomization(UnitState, EndingStates[SoldierIndex].UnitState);
					}

					++SoldierIndex;
				}
			}

			BattleData = XComGameState_BattleData( History.GetSingleGameStateObjectForClass( class'XComGameState_BattleData' ) );
			NextMissionLadder.ProgressCommand =  BattleData.m_strMapCommand;
			BattleData.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );
			return;
		}
	}
	
	`LOG("===== Procedural Ladder");

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	LadderData = XComGameState_LadderProgress_Override(StartState.ModifyStateObject(class'XComGameState_LadderProgress_Override', LadderData.ObjectID));
	LadderData.bNewLadder = true; // in case we're picking up from an abandoned ladder and the last rung was not new.

	LadderData.LastMissionState = LadderData.SoldierStatesBeforeUpgrades;

	MissionType = LadderData.GetNextMissionType();
	if(!MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
	{
		`Redscreen("ProceedToNextRung(): Mission Type " $ MissionType $ " has no definition!");
		LadderData.ProgressCommand = "disconnect";
		return;
	}
	
	if (LadderData.PlayedMissionFamilies.Find(MissionDef.MissionFamily) == INDEX_NONE)
	{
		LadderData.PlayedMissionFamilies.AddItem( MissionDef.MissionFamily );
	}
	MissionManager.ForceMission = MissionDef;

	// pick our new map
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	if(ValidPlots.Length == 0)
	{
		`Redscreen("ProceedToNextRung(): Could not find a plot to transfer to for mission type " $ MissionType $ "!");
		LadderData.ProgressCommand = "disconnect";
		return;
	}

	// Get the local player id before creating the new battle data since this uses latest battle data to find that value.
	LocalPlayerReference.ObjectID = Rules.GetLocalClientPlayerObjectID();

	NewPlot = ValidPlots[ `SYNC_RAND_STATIC(ValidPlots.Length) ];
	PlotType = ParcelManager.GetPlotTypeDefinition( NewPlot.strType );

	BattleData = XComGameState_BattleData( StartState.CreateNewStateObject( class'XComGameState_BattleData' ) );
	BattleData.m_iMissionType = MissionManager.arrMissions.Find('sType', MissionType);
	BattleData.MapData.PlotMapName = NewPlot.MapName;
	BattleData.MapData.ActiveMission = MissionDef;
	BattleData.LostSpawningLevel = BattleData.SelectLostActivationCount();
	BattleData.m_strMapCommand = "open" @ BattleData.MapData.PlotMapName $ "?game=XComGame.XComTacticalGame";
	BattleData.SetForceLevel( LadderData.CustomRungConfigurations[ LadderData.LadderRung ].ForceLevel );
	BattleData.SetAlertLevel( LadderData.CustomRungConfigurations[ LadderData.LadderRung ].AlertLevel );
	BattleData.m_nQuestItem = SelectQuestItem( MissionDef.sType );
	BattleData.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );

	if (NewPlot.ValidBiomes.Length > 0)
		BattleData.MapData.Biome = NewPlot.ValidBiomes[ `SYNC_RAND_STATIC(NewPlot.ValidBiomes.Length) ];

	AppendNames( BattleData.ActiveSitReps, MissionDef.ForcedSitreps );
	AppendNames( BattleData.ActiveSitReps, PlotType.ForcedSitReps );

	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(MissionDef.MissionName);
	if( MissionTemplate != none )
	{
		BattleData.m_strDesc = MissionTemplate.Briefing;
	}
	else
	{
		BattleData.m_strDesc = "NO LOCALIZED BRIEFING TEXT!";
	}

	MissionSite = SetupMissionSite( StartState, BattleData );

	// copy over the xcom headquarters object. Need to do this first so it's available for the unit transfer
	XComHQ = XComGameState_HeadquartersXCom(StartState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.TacticalGameplayTags.Length = 0;

	OriginalPlayerReference = LocalPlayerReference;

	// Player states and ai groups will automatically be removed as part of the archive process, but we still need
	// to remove them from the player turn order
	assert(class'XComGameState_Player'.default.bTacticalTransient); // verify that the player will automatically be removed
	assert(class'XComGameState_AIGroup'.default.bTacticalTransient); // verify that the ai groups will automatically be removed
	BattleData.PlayerTurnOrder.Length = 0;

	// Create new states for the players
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		// create a new player. This will clear out any old data about
		// units and AI
		NewPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, PlayerState.GetTeam());
		NewPlayerState.bPlayerReady = true; // Single Player game, this will be synchronized out of the gate!
		BattleData.PlayerTurnOrder.AddItem(NewPlayerState.GetReference());

		if (PlayerState.ObjectID == LocalPlayerReference.ObjectID) // this is the local human team, need to keep track of it
		{
			LocalPlayerReference.ObjectID = NewPlayerState.ObjectID;
		}
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		// remove any events associated with units. We'll re-add them when the next mission starts
		TransferUnitToNewMission(UnitState, StartState, XComHQ, BattleData, OriginalPlayerReference, LocalPlayerReference);
	}

	// copy over any other non-transient state objects, excepting player objects and alien units
	foreach History.IterateByClassType(class'XComGameState_BaseObject', BaseState)
	{
		if (XComGameState_Player(BaseState) != none) // we already handled players above
			continue;

		if (XComGameState_HeadquartersXCom(BaseState) != none) // we also handled xcom headquarters
			continue;

		if (XComGameState_Unit(BaseState) != none) // we also handled units
			continue;
		
		if (XComGameState_BattleData(BaseState) != none)
			continue;

		if (BaseState.bTacticalTransient) // a transient state, so don't bring it along
			continue;
		
		BaseState = StartState.ModifyStateObject(BaseState.Class, BaseState.ObjectID);

		if (XComGameState_ObjectivesList(BaseState) != none)
		{
			XComGameState_ObjectivesList(BaseState).ClearTacticalObjectives();
		}
	}

	// Get the soldiers ready for the next mission
	SoldierIndex = 0;
	foreach XComHQ.Squad(UnitStateRef)
	{
		// pull the unit from the archives, and add it to the start state
		UnitState = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', UnitStateRef.ObjectID));
		
		if (!UnitState.bMissionProvided)
		{
			UnitState.SetHQLocation(eSoldierLoc_Dropship);
			UnitState.ClearRemovedFromPlayFlag();
			UpdateUnitCustomization(UnitState, EndingStates[SoldierIndex].UnitState);
			UnitState.SetCurrentStat( eStat_HP, UnitState.GetMaxStat( eStat_HP ) );
			++SoldierIndex;
		}
	}

	History.UpdateStateObjectCache( );

	// give mods/dlcs a chance to modify the transfer state
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.ModifyTacticalTransferStartState(StartState);
	}

	// This is not the correct way to handle this. Ideally, we should be calling EndTacticalState
	// or some variant there of on each object. Unfortunately, this also requires adding a new
	// modified state object to a game state, and we can't do that here as it will just add the object to
	// the start state, causing it to be pulled along to the next part of the mission. What should happen is 
	// that we build a list of transient tactical objects that are coming along to the next mission, call some
	// PrepareForTransfer function on them, EndTacticalPlay on the others, and add that as a change container
	// state before beginning to build the tactical start state. This is a pretty large change, however, and not
	// one that I have time to do before I leave. Leaving this comment here for my future code inheritors.
	// Also I'm really sorry. - dburchanowski
	foreach History.IterateByClassType(class'XComGameState_BaseObject', BaseState)
	{
		if(BaseState.bTacticalTransient && StartState.GetGameStateForObjectID(BaseState.ObjectID) == none)
		{
			EventManager.UnRegisterFromAllEvents(BaseState);
		}
	}

	MissionSite.UpdateSitrepTags( );
	XComHQ.AddMissionTacticalTags( MissionSite );
	class'X2SitRepTemplate'.static.ModifyPreMissionBattleDataState(BattleData, BattleData.ActiveSitReps);

	LadderData.ProgressCommand = BattleData.m_strMapCommand;
	LadderData.LadderRung++;

	History.AddGameStateToHistory(StartState);
}

// Same as XComGameState_LadderProgress.UpdateUnitCustomization(), but since it's private and we use it we need to reimplement it
private static function UpdateUnitCustomization( XComGameState_Unit NextMissionUnit, XComGameState_Unit PrevMissionUnit )
{
	local XGCharacterGenerator CharacterGenerator;
	local TSoldier Soldier;

	`LOG("==== UpdateUnitCustomization");

	if (PrevMissionUnit.IsAlive( ))
	{
		`LOG("==== Using PrevMissionUnit");
		Soldier.kAppearance = PrevMissionUnit.kAppearance;
		Soldier.nmCountry = PrevMissionUnit.GetCountry( );

		Soldier.strFirstName = PrevMissionUnit.GetFirstName( );
		Soldier.strLastName = PrevMissionUnit.GetLastName( );
		Soldier.strNickName = PrevMissionUnit.GetNickName( );
	}
	else
	{
		`LOG("==== Using Random");
		CharacterGenerator = `XCOMGRI.Spawn(NextMissionUnit.GetMyTemplate().CharacterGeneratorClass);

		Soldier = CharacterGenerator.CreateTSoldier( NextMissionUnit.GetMyTemplateName() );
		Soldier.strNickName = NextMissionUnit.GenerateNickname( );
	}

	NextMissionUnit.SetTAppearance(Soldier.kAppearance);
	NextMissionUnit.SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
	NextMissionUnit.SetCountry(Soldier.nmCountry);
}

private static function RefreshUnit( XComGameStateHistory History, XComGameState_LadderProgress LadderData, StateObjectReference NewUnitStateRef, UnitEndState EndingState )
{
	local XComGameState StartState;
	local int Index;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item ItemState;
	local XComGameState_Item NewItemState;

	`LOG("==== RefreshUnit");

	StartState = History.GetStartState( );
	`assert( StartState != none );

	NewUnitState = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', NewUnitStateRef.ObjectID));

	// remove all their items
	`LOG("==== RefreshUnit: NewUnitState.InventoryItems.Length: " $ string(NewUnitState.InventoryItems.Length));
	for (Index = NewUnitState.InventoryItems.Length - 1; Index >= 0; --Index)
	{
		ItemState = XComGameState_Item( StartState.ModifyStateObject(class'XComGameState_Item', NewUnitState.InventoryItems[Index].ObjectID) );
		if (ItemState != none && NewUnitState.CanRemoveItemFromInventory( ItemState, StartState ))
		{
			`LOG("==== RefreshUnit: Can remove: " $ string(ItemState.GetMyTemplateName()));
			NewUnitState.RemoveItemFromInventory( ItemState, StartState );
			History.PurgeObjectIDFromStartState( ItemState.ObjectID, false ); // don't refresh the cache every time, we'll do that once after removing all items from all units

			if (ItemState.CosmeticUnitRef.ObjectID > 0) // we also need to destroy any associated units that may exist
			{
				History.PurgeObjectIDFromStartState( ItemState.CosmeticUnitRef.ObjectID, false ); // don't refresh the cache every time, we'll do that once after removing all items from all units
			}
		}
	}

	// add all items from the old state
	`LOG("==== RefreshUnit: EndingState.Inventory.Length: " $ string(EndingState.Inventory.Length));
	NewUnitState.bIgnoreItemEquipRestrictions = true;
	for (Index = 0; Index < EndingState.Inventory.Length; Index++)
	{
		ItemState = EndingState.Inventory[Index];
		if (ItemState != none)
		{
			NewItemState = ItemState.GetMyTemplate().CreateInstanceFromTemplate(StartState);
			if (ItemState.GetMyTemplate().iItemSize > 0 && NewUnitState.CanAddItemToInventory(NewItemState.GetMyTemplate(), ItemState.InventorySlot, StartState, ItemState.Quantity, NewItemState))
			{
				`LOG("==== RefreshUnit: Can add: " $ string(NewItemState.GetMyTemplateName()));
				if (NewUnitState.AddItemToInventory(NewItemState, ItemState.InventorySlot, StartState))
				{
					`LOG("==== RefreshUnit: added item to inventory: " $ string(NewItemState.GetMyTemplateName()));
				}
			}
		}
	}
	NewUnitState.bIgnoreItemEquipRestrictions = false;

	// add all abilities from the old state
	NewUnitState.SetSoldierProgression(EndingState.UnitState.m_SoldierProgressionAbilties);
	
	// refill hp
	NewUnitState.SetCurrentStat( eStat_HP, NewUnitState.GetMaxStat( eStat_HP ) );

	History.UpdateStateObjectCache( );
}

// Same as XComGameState_LadderProgress.TransferUnitToNewMission(), but since it's private and we use it we need to reimplement it
private static function TransferUnitToNewMission(XComGameState_Unit UnitState, 
													XComGameState NewStartState,
													XComGameState_HeadquartersXCom XComHQ, 
													XComGameState_BattleData BattleData,
													StateObjectReference OriginalPlayerObjectID,
													StateObjectReference NewLocalPlayerObjectID)
{
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference StateRef, EmptyReference;
	local int SquadIdx;

	`LOG("==== TransferUnitToNewMission");

	History = `XCOMHISTORY;

	SquadIdx = XComHQ.Squad.Find( 'ObjectID', UnitState.ObjectID );

	if (!UnitState.bMissionProvided // don't keep anyone the mission started them with
		&& (SquadIdx != INDEX_NONE)) // don't keep anyone that wasn't configured as part of our squad
	{
		UnitState = XComGameState_Unit(NewStartState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

		UnitState.SetCurrentStat( eStat_Will, UnitState.GetMaxStat( eStat_Will ) );
		UnitState.SetControllingPlayer( NewLocalPlayerObjectID );

		// and clear any effects they are under
		while (UnitState.AppliedEffects.Length > 0)
		{
			StateRef = UnitState.AppliedEffects[UnitState.AppliedEffects.Length - 1];
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(StateRef.ObjectID));
			UnitState.RemoveAppliedEffect(EffectState);
			UnitState.UnApplyEffectFromStats(EffectState);
		}

		while (UnitState.AffectedByEffects.Length > 0)
		{
			StateRef = UnitState.AffectedByEffects[UnitState.AffectedByEffects.Length - 1];
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(StateRef.ObjectID));

			if (EffectState != None)
			{
				// Some effects like Stasis and ModifyStats need to be undone
				EffectState.GetX2Effect().UnitEndedTacticalPlay(EffectState, UnitState);
			}

			UnitState.RemoveAffectingEffect(EffectState);
			UnitState.UnApplyEffectFromStats(EffectState);
		}

		UnitState.bDisabled = false;
		UnitState.ReflexActionState = eReflexActionState_None;
		UnitState.DamageResults.Length = 0;
		UnitState.Ruptured = 0;
		UnitState.bTreatLowCoverAsHigh = false;
		UnitState.m_SpawnedCocoonRef = EmptyReference;
		UnitState.m_MultiTurnTargetRef = EmptyReference;
		UnitState.m_SuppressionHistoryIndex = -1;
		UnitState.bPanicked = false;
		UnitState.bInStasis = false;
		UnitState.bBleedingOut = false;
		UnitState.bUnconscious = false;
		UnitState.bHasSuperConcealment = false;
		UnitState.SuperConcealmentLoss = 0;
		UnitState.bGeneratesCover = false;
		UnitState.CoverForceFlag = CoverForce_Default;
		UnitState.ReflectedAbilityContext = none;

		UnitState.ClearAllTraversalChanges();
	}
	else if (SquadIdx != INDEX_NONE) // if they were in the squad they should be removed.
	{
		XComHQ.Squad.Remove( SquadIdx, 1 );
	}
}

function OnComplete( Name ActionName )
{
	local XComPresentationLayer Pres;

	`LOG("==== OnComplete");
	
	if (!bRandomLadder || !Settings.UseCustomSettings)
	{
		`LOG("==== LadderData not an overhaul ladder, performing normal routine");
		super.OnComplete(ActionName);
		return;
	}

	// Bring down the squad screen
	Pres = `PRES;
	Pres.Screenstack.Pop(UpgradeScreen);
	UpgradeScreen.Destroy();
	UpgradeScreen = none;
	
	// Only bring up the mission selection screen if we aren't going to the last mission
	if (LadderRung + 1 < LadderSize)
	{
		// Bring up the mission selection screen
		MissionScreen = Pres.Spawn(class'UILadderChooseNextMission');
		Pres.Screenstack.Push(MissionScreen);
	}
	else
	{
		`TACTICALRULES.bWaitingForMissionSummary = false;
	}
}

function OnChooseMission(MissionOption Option)
{
	local XComPresentationLayer Pres;

	`LOG("==== OnChooseMission");

	ChosenMissionOption = Option;

	`TACTICALRULES.bWaitingForMissionSummary = false;

	Pres = `PRES;
	Pres.Screenstack.Pop(MissionScreen);
	MissionScreen.Destroy();
	MissionScreen = none;
}

static function bool MaybeDoLadderProgressionChoice( )
{
	local XComPresentationLayer Pres;
	local XComGameState_LadderProgress_Override LadderData;

	`LOG("==== MaybeDoLadderProgressionChoice");

	LadderData = XComGameState_LadderProgress_Override(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress', true));
	
	if (LadderData == none || !LadderData.bRandomLadder || !LadderData.Settings.UseCustomSettings)
	{
		`LOG("==== LadderData not an overhaul ladder, performing normal routine");
		return super.MaybeDoLadderProgressionChoice();
	}

	// don't do any of our new screens after completing the last mission
	if (LadderData.LadderRung == LadderData.LadderSize)
		return false;

	// Bring up the rewards screen
	Pres = `PRES;
	LadderData.RewardsScreen = Pres.Spawn(class'UILadderRewards');
	Pres.Screenstack.Push(LadderData.RewardsScreen);
	LadderData.RewardsScreen.Populate(LadderData);

	return true;
}

function OnCloseRewardsScreen()
{
	local XComPresentationLayer Pres;

	// Bring down the rewards scren
	Pres = `PRES;
	Pres.Screenstack.Pop(RewardsScreen);
	RewardsScreen.Destroy();
	RewardsScreen = none;

	// Bring up the upgrade screen
	UpgradeScreen = Pres.Spawn(class'UILadderSquadUpgradeScreen');
	Pres.Screenstack.Push(UpgradeScreen);
}

function PurchaseTechUpgrade(name DataName, XComGameState NewGameState)
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	//local X2StrategyElementTemplateManager TechMgr;
	//local X2TechTemplate TechTemplate, RequiredTechTemplate;
	//local XComGameState_Tech TechState, RequiredTechState;
	//local XComGameState_HeadquartersXCom XComHQ;

	`LOG("=== PurchaseTechUpgrade");

	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	Template = TemplateManager.FindTemplate(DataName);

	`LOG("=== PurchaseTechUpgrade DataName: " $ string(DataName));

	//if (Template.AssociatedTech != '')
	//{
		//`LOG("=== PurchaseTechUpgrade Template.AssociatedTech: " $ string(Template.AssociatedTech));
		//TechMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		//TechTemplate = X2TechTemplate(TechMgr.FindStrategyElementTemplate(Template.AssociatedTech));
		//RequiredTechTemplate = X2TechTemplate(TechMgr.FindStrategyElementTemplate('AutopsyViper'));
		//
		//// Try to get requirement
		//RequiredTechState = XComGameState_Tech(NewGameState.CreateNewStateObject(class'XComGameState_Tech', RequiredTechTemplate));
		//RequiredTechState.bForceInstant = true;
		//RequiredTechState.bBlocked = false;
			//
		//XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		//XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		//XComHQ.TechsResearched.AddItem(RequiredTechState.GetReference());
			//
		//RequiredTechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', RequiredTechState.ObjectID));
		//RequiredTechState.TimesResearched++;
		//RequiredTechState.TimeReductionScalar = 0;
		//RequiredTechState.OnResearchCompleted(NewGameState);
//
//
		//if (TechTemplate != none)
		//{
			//`LOG("=== PurchaseTechUpgrade TechTemplate found");
			//TechState = XComGameState_Tech(NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate));
			//TechState.bForceInstant = true;
			//TechState.bBlocked = false;
//
			//XComHQ.TechsResearched.AddItem(TechState.GetReference());
			//
			//TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechState.ObjectID));
			//TechState.TimesResearched++;
			//TechState.TimeReductionScalar = 0;
			//TechState.OnResearchCompleted(NewGameState);
			//`LOG("=== PurchaseTechUpgrade Research completed");
//
			//Credits -= Template.Cost;
		//}
	//}
	
	Credits -= Template.Cost;
	PurchasedTechUpgrades.AddItem(DataName);
}

function bool HasPurchasedTechUpgrade(name UpgradeName)
{
	local name Upgrade;
	foreach PurchasedTechUpgrades (Upgrade)
	{
		if (Upgrade == UpgradeName)
		{
			return true;
		}
	}

	return false;
}

function bool HasRequiredTechs(X2ResistanceTechUpgradeTemplate Template)
{
	local name Upgrade;
	foreach Template.RequiredTechUpgrades (Upgrade)
	{
		if (!HasPurchasedTechUpgrade(Upgrade))
		{
			return false;
		}
	}

	return true;
}

function bool HasEnoughScience(X2ResistanceTechUpgradeTemplate Template)
{
	if (Science < Template.RequiredScience)
	{
		return false;
	}

	return true;
}

function bool CanAfford(X2ResistanceTechUpgradeTemplate Template)
{
	if (Credits < Template.Cost || Science < Template.RequiredScience)
	{
		return false;
	}

	return true;
}

function array<name> GetAvailableTechUpgradeNames()
{
	return PurchasedTechUpgrades;
}

function PopulateStartingUpgradeTemplates()
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local array<name> StartingTemplates;
	local name TemplateName;

	TemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	StartingTemplates = TemplateManager.GetStartingTemplates();
	foreach StartingTemplates (TemplateName)
	{
		PurchasedTechUpgrades.AddItem(TemplateName);
	}
}

function SetSoldierStatesBeforeUpgrades()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitStateRef;
	local XComGameState_Unit UnitState;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SoldierStatesBeforeUpgrades.Length = 0;

	foreach XComHQ.Squad(UnitStateRef)
	{
		UnitState = XComGameState_Unit( History.GetGameStateForObjectID( UnitStateRef.ObjectID ) );
		if (!UnitState.bMissionProvided)
		{
			SoldierStatesBeforeUpgrades.AddItem(UnitState);
		}
	}
}

function AddMissionCompletedRewards()
{
	local int NewCredits;
	local int NewScience;
	local name NewUpgrade;
	
	NewCredits = ChosenMissionOption.Credits;
	NewScience = ChosenMissionOption.Science;

	if (NewCredits > 0)
	{
		Credits += NewCredits;
	}

	if (NewScience > 0)
	{
		Science += NewScience;
	}

	foreach ChosenMissionOption.FreeUpgrades (NewUpgrade)
	{
		if (PurchasedTechUpgrades.Find(NewUpgrade) == INDEX_NONE)
		{
			PurchasedTechUpgrades.AddItem(NewUpgrade);
			// TODO upgrade soldier gear if better
		}
	}
}

function array<MissionOption> GetMissionOptions()
{
	local MissionTypeOption MissionTypeOptions;
	local MissionOption Option0;
	local MissionOption Option1;
	local array<MissionOption> MissionOptions;
	local int BaseCredits;
	local int ChoiceSet;
	local X2ResistanceTechUpgradeTemplate Template0;
	local X2ResistanceTechUpgradeTemplate Template1;

	// LadderRung will be 1 when this is first called (after the first mission is complete)
	`LOG("=== GetMissionOptions LadderRung: " $ LadderRung);

	BaseCredits = default.CREDITS_BASE;
	BaseCredits += (LadderRung * default.CREDITS_LADDER_BONUS);
	
	MissionTypeOptions = LadderMissionTypeOptions[LadderRung - 1];

	Option0.MissionType = MissionTypeOptions.MissionType0;
	Option0.Credits = BaseCredits;
	Option0.Science = default.SCIENCE_TABLE[LadderRung];

	Option1.MissionType = MissionTypeOptions.MissionType1;
	Option1.Credits = BaseCredits;
	Option1.Science = default.SCIENCE_TABLE[LadderRung];

	Template0 = GetFreeResearchOption('');
	Template1 = GetFreeResearchOption(Template0.DataName);

	if (Template0 == none)
	{
		// No valid free upgrades
		ChoiceSet = 0;
	}
	else if (Template1 == none)
	{
		// Only one valid free upgrade
		ChoiceSet = `SYNC_RAND_STATIC(3);
	}
	else
	{
		ChoiceSet = `SYNC_RAND_STATIC(4);
	}
	
	switch (ChoiceSet)
	{
	case 0:
		// Science vs Credits
		Option0.Science += 1;
		Option1.Credits += (LadderRung * default.CREDITS_LADDER_BONUS);
		break;
	case 1:
		// Credits vs Free Research
		Option0.FreeUpgrades.AddItem(Template0.DataName); 
		Option1.Credits += Template0.Cost / 2;
		break;
	case 2:
		// Science vs Free Research
		Option0.FreeUpgrades.AddItem(Template0.DataName); 
		Option1.Science += 1;
		break;
	case 3:
		// Free Research vs Free Research
		Option0.FreeUpgrades.AddItem(Template0.DataName); 
		Option1.FreeUpgrades.AddItem(Template1.DataName); 

		if (Template0.Cost > Template1.Cost)
		{
			Option1.Credits += (Template0.Cost - Template1.Cost);
		}
		else if (Template1.Cost > Template0.Cost)
		{
			Option0.Credits += (Template1.Cost - Template0.Cost);
		}

		break;
	}

	// Coin flip to determine which one is on which side
	if (`SYNC_RAND_STATIC(2) == 0)
	{
		MissionOptions.AddItem(Option0);
		MissionOptions.AddItem(Option1);
	}
	else
	{
		MissionOptions.AddItem(Option1);
		MissionOptions.AddItem(Option0);
	}

	return MissionOptions;
}

private function X2ResistanceTechUpgradeTemplate GetFreeResearchOption(name IgnoreTemplateName)
{
	local int MinCreditCost;
	local int MaxCreditCost;
	local array<name> TemplateNames;
	local name TemplateName;
	local array<X2ResistanceTechUpgradeTemplate> ResearchOptions;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	local int RandomIndex;

	MinCreditCost = (LadderRung * default.CREDITS_LADDER_BONUS);
	MaxCreditCost = ((LadderRung + 2) * default.CREDITS_LADDER_BONUS);
	
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
	
	UpgradeTemplateManager.GetTemplateNames(TemplateNames);
	foreach TemplateNames (TemplateName)
	{
		Template = UpgradeTemplateManager.FindTemplate(TemplateName);
		if (PurchasedTechUpgrades.Find(TemplateName) == INDEX_NONE 
			&& HasRequiredTechs(Template)
			&& HasEnoughScience(Template)
			&& Template.Cost <= MaxCreditCost
			&& Template.Cost >= MinCreditCost
			&& TemplateName != IgnoreTemplateName)
		{
			if (DoesSomeoneBenefit(Template))
			{
				ResearchOptions.AddItem(Template);
			}
		}
	}

	if (ResearchOptions.Length == 0)
	{
		return none;
	}

	RandomIndex = `SYNC_RAND_STATIC(ResearchOptions.Length);
	Template = ResearchOptions[RandomIndex];

	return Template;
}

private function bool DoesSomeoneBenefit(X2ResistanceTechUpgradeTemplate Template)
{
	local InventoryUpgrade Upgrade;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local X2ArmorTemplate ArmorTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local StateObjectReference UnitStateRef;
	local XComGameState_Unit Soldier;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach Template.InventoryUpgrades (Upgrade)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate(Upgrade.TemplateName);
		if (ItemTemplate != none)
		{
			ArmorTemplate = X2ArmorTemplate(ItemTemplate);
			if (ArmorTemplate != none)
			{
				foreach XComHQ.Squad(UnitStateRef)
				{
					Soldier = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));
					if (Soldier.GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate))
					{
						return true;
					}
				}
			}
		
			WeaponTemplate = X2WeaponTemplate(ItemTemplate);
			if (WeaponTemplate != none)
			{
				foreach XComHQ.Squad(UnitStateRef)
				{
					Soldier = XComGameState_Unit(History.GetGameStateForObjectID(UnitStateRef.ObjectID));
					if (Soldier.GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate))
					{
						return true;
					}
				}
			}

			if (ArmorTemplate == none && WeaponTemplate == none)
			{
				// If it's not a weapon or armor, it's probably a utility item or something that anyone can use
				return true;
			}
		}
	}

	return false;
}

public function InitMissionTypeOptions()
{
	local int Index;
	local MissionTypeOption Option;
	local string MissionType;

	LadderMissionTypeOptions.Length = 0;
	for (Index = 0; Index < LadderSize - 1; Index++)
	{
		if (Index < LadderSize - 2)
		{
			Option.MissionType0 = GetRandomMissionType();
			Option.MissionType1 = GetRandomMissionType();
			LadderMissionTypeOptions.AddItem(Option);
		}
		else
		{
			// This is for the final mission
			MissionType = default.FinalMissionTypes[ `SYNC_RAND_STATIC( default.FinalMissionTypes.Length ) ];
			Option.MissionType0 = MissionType;
			Option.MissionType1 = MissionType;
			LadderMissionTypeOptions.AddItem(Option);
		}
	}
}

private function string GetRandomMissionType()
{
	local array<string> PossibleMissionTypes;
	local string MissionType;
	local XComTacticalMissionManager MissionManager;
	local MissionDefinition MissionDef;
	local int RandIndex;

	`LOG("=== GetRandomMissionType");
	
	MissionManager = `TACTICALMISSIONMGR;

	PossibleMissionTypes = default.AllowedMissionTypes;

	// Start by populating PossibleMissionTypes with everything that hasn't been played
	foreach default.AllowedMissionTypes (MissionType)
	{
		if (MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
		{
			if (PlayedMissionFamilies.Find(MissionDef.MissionFamily) == INDEX_NONE)
			{
				PossibleMissionTypes.AddItem(MissionType);
			}
		}
	}
	
	// If we don't have at least 1 mission type...
	if (PossibleMissionTypes.Length == 0)
	{
		// Remove half the history of played mission types, and retry
		PlayedMissionFamilies.Remove( 0, PlayedMissionFamilies.Length / 2 );

		foreach default.AllowedMissionTypes (MissionType)
		{
			if (MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
			{
				if (PlayedMissionFamilies.Find(MissionDef.MissionFamily) == INDEX_NONE && PossibleMissionTypes.Find(MissionType) == INDEX_NONE)
				{
					PossibleMissionTypes.AddItem(MissionType);
				}
			}
		}
	}
	
	RandIndex = `SYNC_RAND_STATIC(PossibleMissionTypes.Length);
	MissionType = PossibleMissionTypes[RandIndex];

	`LOG("=== GetRandomMissionType MissionType: " $ MissionType);

	// Add the one we're choosing to the list of played families
	if (MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
	{
		if (PlayedMissionFamilies.Find(MissionDef.MissionFamily) == INDEX_NONE)
		{
			`LOG("=== GetRandomMissionType Adding to PlayedMissionFamilies: " $ MissionDef.MissionFamily);
			PlayedMissionFamilies.AddItem(MissionDef.MissionFamily);
		}
	}

	return MissionType;
}

function string GetNextMissionType()
{
	local string MissionType;

	if (LadderRung == 0)
	{
		// This should never happen, because the first mission is chosen in UITLE_LadderModeMenu_Override
		MissionType = default.AllowedMissionTypes[ `SYNC_RAND_STATIC( default.AllowedMissionTypes.Length ) ];
	}
	else if (LadderRung < (LadderSize - 1))
	{
		// Use the mission that the user chose
		MissionType = ChosenMissionOption.MissionType;
	}
	else
	{
		// Grab the last randomized mission from earlier
		MissionType = LadderMissionTypeOptions[LadderMissionTypeOptions.Length - 1].MissionType0;
	}

	return MissionType;
}