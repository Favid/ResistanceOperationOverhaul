class XComGameState_LadderProgress_Override extends XComGameState_LadderProgress;

struct EndState
{
	var XComGameState_Unit UnitState;
	var array<XComGameState_Item> Inventory;
};

var array<name> PurchasedTechUpgrades;
var array<XComGameState_Unit> SoldierStatesBeforeUpgrades;
var LadderSettings Settings;
var array<RungConfig> CustomRungConfigurations;
var array<SoldierOption> FutureSoldierOptions;
var int Credits;

var UILadderSquadUpgradeScreen UpgradeScreen;

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

	local array<name> SquadProgressionNames;
	local ConfigurableSoldier SoldierConfigData;
	local name ConfigName;
	local int SoldierIndex;
	local XComGameState_Player XComPlayer;
	local XComOnlineProfileSettings Profile;

	local array<string> PossibleMissionTypes;

	local XComGameState_CampaignSettings CurrentCampaign, NextCampaign;
	
	local EndState EndingState;
	local array<EndState> EndingStates;
	local int EndingIndex;

	local int MedalLevel;

	local array<Actor> Visualizers;
	local Actor Visualizer;

	local int CampaignSaveID;

	local LadderMissionID ID, Entry;
	local bool Found;

	local XComGameState_Analytics CurrentAnalytics, CampaignAnalytics;

	`LOG("==== ProceedToNextRung");

	History = `XCOMHISTORY;
	ParcelManager = `PARCELMGR;
	MissionManager = `TACTICALMISSIONMGR;
	Rules = `TACTICALRULES;
	EventManager = `XEVENTMGR;

	LadderData = XComGameState_LadderProgress_Override(History.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override', true));
	if (LadderData == none)
	{
		`LOG("==== LadderData not found, returning");
		return;
	}
	
	if (!LadderData.bRandomLadder || !LadderData.Settings.UseCustomSettings)
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

	if (LadderData.LadderIndex < 10)
	{
		Profile = `XPROFILESETTINGS;

		ID.LadderIndex = LadderData.LadderIndex;
		ID.MissionIndex = LadderData.LadderRung;

		Found = false;

		foreach Profile.Data.HubStats.LadderCompletions(Entry)
		{
			if (Entry == ID)
			{
				Found = true;
				break;
			}
		}

		if (!Found)
		{
			Profile.Data.HubStats.LadderCompletions.AddItem( ID );

			`ONLINEEVENTMGR.SaveProfileSettings();
		}
	}

	// Case for completing a ladder
	if (LadderData.LadderRung + 1 > LadderData.LadderSize)
	{
		`LOG("===== Ladder completed");
		if (LadderData.MedalThresholds.Length > 0)
		{
			for (MedalLevel = 0; (LadderData.CumulativeScore > LadderData.MedalThresholds[ MedalLevel ]) && (MedalLevel < LadderData.MedalThresholds.Length); ++MedalLevel)
				; // no actual work to be done, once the condition fails MedalLevel will be the value we want
		}
		else
		{
			MedalLevel = 0;
		}

		`FXSLIVE.BizAnalyticsLadderEnd( CurrentCampaign.BizAnalyticsCampaignID, LadderData.LadderIndex, LadderData.CumulativeScore, MedalLevel, LadderData.SquadProgressionName, CurrentCampaign.DifficultySetting );

		if (MedalLevel == 3)
		{
			switch (LadderData.LadderIndex)
			{
				case 1:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold Blast from the Past");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldBlastFromThePast);
					break;

				case 2:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold It Came from the Sea");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldItCameFromTheSea);
					break;

				case 3:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold Avenger Assemble");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldAvengerAssemble);
					break;

				case 4:
					class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Gold Lazarus Project");
					`ONLINEEVENTMGR.UnlockAchievement(AT_GoldLazarusProject);
					break;
			}
		}

		if (LadderData.bNewLadder && LadderData.bRandomLadder)
		{
			class'X2TacticalGameRuleset'.static.ReleaseScriptLog("TLE Achievement Awarded: Complete Procedural Ladder");
			`ONLINEEVENTMGR.UnlockAchievement(AT_CompleteProceduralLadder);
		}

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

	// Case for an existing ladder
	if (!LadderData.bNewLadder)
	{
		`LOG("===== Existing ladder");
		Visualizers = History.GetAllVisualizers( );

		if (!History.ReadHistoryFromFile( "Ladders/", "Mission_" $ LadderData.LadderIndex $ "_" $ (LadderData.LadderRung + 1) $ "_" $ CurrentCampaign.DifficultySetting ))
		{
			`LOG("===== Failed to find save file");
			if (!LadderData.bRandomLadder)
			{
				LadderData.ProgressCommand = "disconnect";
				return;
			}
			// there isn't a next mission for this procedural ladder, fall through to the normal procedural ladder progression
			`LOG("===== Falling through");
		}
		else
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

			// transfer over the player's current score to the loaded history start state.
			NextMissionLadder = XComGameState_LadderProgress_Override( History.GetSingleGameStateObjectForClass( class'XComGameState_LadderProgress_Override' ) );
			NextMissionLadder.CumulativeScore = LadderData.CumulativeScore;

			// transfer over the active set of player choices (overwriting the choices they had made the previous time)
			NextMissionLadder.ProgressionUpgrades = LadderData.ProgressionUpgrades;

			NextMissionLadder.LastMissionState = LadderData.SoldierStatesBeforeUpgrades;

			// My new properties
			NextMissionLadder.PurchasedTechUpgrades = LadderData.PurchasedTechUpgrades;
			NextMissionLadder.Settings = LadderData.Settings;
			NextMissionLadder.CustomRungConfigurations = LadderData.CustomRungConfigurations;
			NextMissionLadder.FutureSoldierOptions = LadderData.FutureSoldierOptions;
			NextMissionLadder.Credits = LadderData.Credits;

			// Maintain the campaign start times
			NextCampaign = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
			NextCampaign.SetStartTime( CurrentCampaign.StartTime );
			NextCampaign.HACK_ForceGameIndex( CurrentCampaign.GameIndex );
			NextCampaign.BizAnalyticsCampaignID = CurrentCampaign.BizAnalyticsCampaignID;

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

			// Don't want to do this anymore, it will make the squad use a squad progression
			// fix up the soldier equipment for the choices we've made along the way
			//HandlePreExistingSoliderEquipment( History, NextMissionLadder );
		
			// update the ability states based on the patch-ups that we've done to the gamestate
			//RefreshAbilities( History ); // moved to tactical ruleset so that any cosmetic units that are spawned happen after we've loaded the new map

			// TODO: any other patch up from the previous mission history into the new history.

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

	if (LadderData.LadderRung < (LadderData.LadderSize - 1))
	{
		PossibleMissionTypes = default.AllowedMissionTypes;

		do {
			MissionType = PossibleMissionTypes[ `SYNC_RAND_STATIC( PossibleMissionTypes.Length ) ]; // try a random mission

			if (!MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
			{
				MissionType = "";
				continue; // try again
			}

			// see if we've already played that
			if ((LadderData.PlayedMissionFamilies.Find( MissionDef.MissionFamily ) != INDEX_NONE) && (default.AllowedMissionTypes.Length > 1))
			{
				PossibleMissionTypes.RemoveItem( MissionType );

				// if we ran out of mission types, start over but remove half the history
				// this way we do repeat, but at least we repeat stuff that's older than what we just played.
				if (PossibleMissionTypes.Length == 0)
				{
					PossibleMissionTypes = default.AllowedMissionTypes;
					LadderData.PlayedMissionFamilies.Remove( 0, LadderData.PlayedMissionFamilies.Length / 2 );
				}

				MissionType = "";
				continue; // try again
			}

		} until( MissionType != "" );

		LadderData.PlayedMissionFamilies.AddItem( MissionDef.MissionFamily ); // add to the ladder history
	}
	else
	{
		MissionType = default.FinalMissionTypes[ `SYNC_RAND_STATIC( default.FinalMissionTypes.Length ) ];

		if(!MissionManager.GetMissionDefinitionForType(MissionType, MissionDef))
		{
			`Redscreen("TransferToNewMission(): Mission Type " $ MissionType $ " has no definition!");
			LadderData.ProgressCommand = "disconnect";
			return;
		}
	}

	MissionManager.ForceMission = MissionDef;

	// pick our new map
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	if(ValidPlots.Length == 0)
	{
		`Redscreen("TransferToNewMission(): Could not find a plot to transfer to for mission type " $ MissionType $ "!");
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

	if (LadderData.Settings.UseCustomSettings)
	{
		BattleData.SetForceLevel( LadderData.CustomRungConfigurations[ LadderData.LadderRung ].ForceLevel );
		BattleData.SetAlertLevel( LadderData.CustomRungConfigurations[ LadderData.LadderRung ].AlertLevel );
	}
	else
	{
		BattleData.SetForceLevel( default.RungConfiguration[ LadderData.LadderRung ].ForceLevel );
		BattleData.SetAlertLevel( default.RungConfiguration[ LadderData.LadderRung ].AlertLevel );
	}

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
			XComPlayer = NewPlayerState;
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

	// Keeping it simple for now - no upgrades at all, just get them ready for the next mission and heal
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

	//SquadProgressionNames = GetSquadProgressionMembers( LadderData.SquadProgressionName, LadderData.LadderRung + 1 );
//
	//// make sure every unit on this leg of the mission is ready to go
	//SoldierIndex = 0;
	//foreach XComHQ.Squad(UnitStateRef)
	//{
		//// pull the unit from the archives, and add it to the start state
		//UnitState = XComGameState_Unit(StartState.ModifyStateObject(class'XComGameState_Unit', UnitStateRef.ObjectID));
		//UnitState.SetHQLocation(eSoldierLoc_Dropship);
//
		//UnitState.ClearRemovedFromPlayFlag();
//
		//ConfigName = SquadProgressionNames[ SoldierIndex ];
//
		//if (class'UITacticalQuickLaunch_MapData'.static.GetConfigurableSoldierSpec( ConfigName, SoldierConfigData ))
		//{
			//UnitState.bIgnoreItemEquipRestrictions = true;
			//UpdateUnitCustomization( UnitState, EndingUnitStates[ SoldierIndex ] );
			//UpdateUnitState( StartState, UnitState, SoldierConfigData, LadderData.ProgressionUpgrades );
		//}
		//else
		//{
			//`warn("LadderMode Progression unable to find '" $ ConfigName $ "' soldier data.");
		//}
//
		//++SoldierIndex;
	//}

	// For now, don't allow new squad members to be added
	//while (SoldierIndex < SquadProgressionNames.Length) // new soldier added to the squad
	//{
		//ConfigName = SquadProgressionNames[ SoldierIndex ];
//
		//UnitState = class'UITacticalQuickLaunch_MapData'.static.ApplySoldier( ConfigName, StartState, XComPlayer );
//
		//if (class'UITacticalQuickLaunch_MapData'.static.GetConfigurableSoldierSpec( ConfigName, SoldierConfigData ))
		//{
			//UnitState.bIgnoreItemEquipRestrictions = true;
			//UpdateUnitState( StartState, UnitState, SoldierConfigData, LadderData.ProgressionUpgrades );
		//}
//
		//++SoldierIndex;
	//}

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
	++LadderData.LadderRung;

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

private static function RefreshUnit( XComGameStateHistory History, XComGameState_LadderProgress LadderData, StateObjectReference NewUnitStateRef, EndState EndingState )
{
	local XComGameState StartState;
	local XComGameState_HeadquartersXCom XComHQ;
	local int SoldierIndex, Index;
	local StateObjectReference UnitStateRef;
	local ConfigurableSoldier SoldierConfigData;
	local name ConfigName;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item ItemState;
	local XComGameState_Item NewItemState;

	`LOG("==== RefreshUnit");

	StartState = History.GetStartState( );
	`assert( StartState != none );

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
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

event OnCreation( optional X2DataTemplate InitTemplate )
{
	local X2EventManager EventManager;
	local Object ThisObj;

	`LOG("==== OnCreation");

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.RegisterForEvent( ThisObj, 'KillMail', OnKillMail, ELD_OnStateSubmitted, , , true ); // unit died messages
	EventManager.RegisterForEvent( ThisObj, 'KillMail', OnUnitKilled, ELD_OnStateSubmitted, , , true ); // unit died messages
	EventManager.RegisterForEvent( ThisObj, 'KnockSelfoutUnconscious', OnUnitUnconscious, ELD_OnStateSubmitted, , , true ); // unit goes unconscious instead of killed messages
	EventManager.RegisterForEvent( ThisObj, 'CivilianRescued', OnCivilianRescued, ELD_OnStateSubmitted, , , true ); // civilian rescued
	EventManager.RegisterForEvent( ThisObj, 'MissionObjectiveMarkedCompleted', OnMissionObjectiveComplete, ELD_OnStateSubmitted, , , true ); // mission objective complete
	EventManager.RegisterForEvent( ThisObj, 'UnitTakeEffectDamage', OnUnitDamage, ELD_OnStateSubmitted, , , true ); // unit damaged messages
	EventManager.RegisterForEvent( ThisObj, 'ChallengeModeScoreChange', OnChallengeModeScore, ELD_OnStateSubmitted, , , true );
}

function EventListenerReturn OnUnitDamage(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState, PreviousState;
	local XComChallengeModeManager ChallengeModeManager;
	local ChallengeSoldierScoring SoldierScoring;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress_Override LadderData;
	local XComGameState_ChallengeScore ChallengeScore;
	local UnitValue UnitValue;
	local XComGameState_Analytics Analytics;

	`LOG("==== OnUnitDamage");

	UnitState = XComGameState_Unit( EventData );

	if (UnitState.GetPreviousTeam() != eTeam_XCom) // Not XCom
		return ELR_NoInterrupt;
	if (UnitState.bMissionProvided) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetMyTemplate().bIsCosmetic) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetUnitValue( 'NewSpawnedUnit', UnitValue )) // spawned unit like a Ghost or Mimic Beacon
		return ELR_NoInterrupt;

	PreviousState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( UnitState.ObjectID, , GameState.HistoryIndex - 1 ) );
	if (PreviousState.HighestHP > PreviousState.LowestHP) // already taken damage
		return ELR_NoInterrupt;

	ChallengeModeManager = `CHALLENGEMODE_MGR;
	ChallengeModeManager.GetSoldierScoring( SoldierScoring );

	if (SoldierScoring.UninjuredBonus > 0)
	{
		NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( );

		ChallengeScore = XComGameState_ChallengeScore( NewGameState.CreateStateObject( class'XComGameState_ChallengeScore' ) );
		ChallengeScore.ScoringType = CMPT_WoundedSoldier;
		ChallengeScore.AddedPoints = -SoldierScoring.UninjuredBonus;

		LadderData = XComGameState_LadderProgress_Override( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );
		LadderData.CumulativeScore -= SoldierScoring.UninjuredBonus;
		LadderData.Credits -= SoldierScoring.UninjuredBonus;

		Analytics = XComGameState_Analytics( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_Analytics', true ) );
		if (Analytics != none)
		{
			Analytics = XComGameState_Analytics( NewGameState.ModifyStateObject( class'XComGameState_Analytics', Analytics.ObjectID ) );
			Analytics.AddValue( "TLE_INJURIES", 1 );
		}

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitKilled(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState, UnitStateUpdated;
	local XComChallengeModeManager ChallengeModeManager;
	local ChallengeSoldierScoring SoldierScoring;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress_Override LadderData;
	local XComGameState_ChallengeScore ChallengeScore;
	local UnitValue UnitValue;

	`LOG("==== OnUnitKilled");

	UnitState = XComGameState_Unit( EventData );

	if (UnitState.GetPreviousTeam() != eTeam_XCom) // Not XCom
		return ELR_NoInterrupt;
	if (UnitState.bMissionProvided) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetMyTemplate().bIsCosmetic) // Not a soldier
		return ELR_NoInterrupt;
	if (UnitState.GetUnitValue( 'NewSpawnedUnit', UnitValue )) // spawned unit like a Ghost or Mimic Beacon
		return ELR_NoInterrupt;

	ChallengeModeManager = `CHALLENGEMODE_MGR;
	ChallengeModeManager.GetSoldierScoring( SoldierScoring );

	if (SoldierScoring.WoundedBonus > 0)
	{
		NewGameState = class'XComGameStateContext_ChallengeScore'.static.CreateChangeState( );

		ChallengeScore = XComGameState_ChallengeScore( NewGameState.CreateStateObject( class'XComGameState_ChallengeScore' ) );
		ChallengeScore.ScoringType = CMPT_DeadSoldier;
		ChallengeScore.AddedPoints = -SoldierScoring.WoundedBonus;

		LadderData = XComGameState_LadderProgress_Override( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );
		LadderData.CumulativeScore -= SoldierScoring.WoundedBonus;
		LadderData.Credits -= SoldierScoring.WoundedBonus;

		if(UnitState.IsUnconscious())
		{
			// We only set this if the unit went unconscious. This helps prevent issues if a unit is not allowed to become unconscious.
			UnitStateUpdated = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			UnitStateUpdated.SetUnitFloatValue('LadderKilledScored', 1.0, eCleanup_BeginTactical);
		}

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitUnconscious(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local StateObjectReference AbilityRef;
	local UnitValue UnitValue;

	`LOG("==== OnUnitUnconscious");

	UnitState = XComGameState_Unit(EventSource);
	AbilityRef = UnitState.FindAbility('LadderUnkillable');
	if (AbilityRef.ObjectID == 0) // Does not have the LadderUnkillable ability
		return ELR_NoInterrupt;
	if (UnitState.GetUnitValue('LadderKilledScored', UnitValue)) // Already scored as Ladder Killed (and not been revived)
		return ELR_NoInterrupt;

	return OnUnitKilled(UnitState, EventSource, GameState, Event, CallbackData);
}

function EventListenerReturn OnChallengeModeScore(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_ChallengeScore Scoring;

	`LOG("==== OnChallengeModeScore");

	foreach GameState.IterateByClassType(class'XComGameState_ChallengeScore', Scoring)
	{
		if (Scoring.LadderBonus > 0)
		{
			GameState.GetContext().PostBuildVisualizationFn.AddItem( BuildLadderBonusVis );
			return ELR_NoInterrupt;
		}
	}

	return ELR_NoInterrupt;
}

static function BuildLadderBonusVis( XComGameState VisualizeGameState )
{
	local XComGameState_ChallengeScore Scoring;
	local VisualizationActionMetadata ActionMetadata;
	local X2Action_PlayMessageBanner Action;
	local XGParamTag Tag;

	`LOG("==== BuildLadderBonusVis");

	Tag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_ChallengeScore', Scoring)
	{
		if (Scoring.LadderBonus <= 0)
			continue;

		if (Action == none)
		{
			ActionMetadata.StateObject_OldState = Scoring;
			ActionMetadata.StateObject_NewState = ActionMetadata.StateObject_OldState;
			ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer( `TACTICALRULES.GetLocalClientPlayerObjectID() );

			Action = X2Action_PlayMessageBanner( class'X2Action_PlayMessageBanner'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext() ) );
		}

		Tag.IntValue0 = Scoring.LadderBonus;

		Action.AddMessageBanner(	default.EarlyBirdTitle,
									,
									,
									`XEXPAND.ExpandString( default.EarlyBirdBonus ),
									eUIState_Good );
	}
}

function EventListenerReturn OnKillMail(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local int AddedPoints;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress_Override LadderData;

	`LOG("==== OnKillMail");

	AddedPoints = class'XComGameState_ChallengeScore'.static.AddKillMail( XComGameState_Unit(EventSource), XComGameState_Unit(EventData), GameState );

	if (AddedPoints > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "LadderScoreKillMail" );
		LadderData = XComGameState_LadderProgress_Override( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );

		LadderData.CumulativeScore += AddedPoints;
		LadderData.Credits += AddedPoints;

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnMissionObjectiveComplete(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local SeqAct_DisplayMissionObjective SeqActDisplayMissionObjective;
	local int AddedPoints;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress_Override LadderData;

	`LOG("==== OnMissionObjectiveComplete");

	SeqActDisplayMissionObjective = SeqAct_DisplayMissionObjective( EventSource );
	if (SeqActDisplayMissionObjective != none)
	{
		AddedPoints = class'XComGameState_ChallengeScore'.static.AddIndividualMissionObjectiveComplete( SeqActDisplayMissionObjective );

		if (AddedPoints > 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "LadderScoreObjectiveComplete" );
			LadderData = XComGameState_LadderProgress_Override( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );

			LadderData.CumulativeScore += AddedPoints;
			LadderData.Credits += AddedPoints;

			`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnCivilianRescued(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local int AddedPoints;
	local XComGameState NewGameState;
	local XComGameState_LadderProgress_Override LadderData;

	`LOG("==== OnCivilianRescued");

	AddedPoints = class'XComGameState_ChallengeScore'.static.AddCivilianRescued( XComGameState_Unit(EventSource), XComGameState_Unit(EventData) );

	if (AddedPoints > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "LadderScoreCivilianRescue" );
		LadderData = XComGameState_LadderProgress_Override( NewGameState.ModifyStateObject( class'XComGameState_LadderProgress', ObjectID ) );

		LadderData.CumulativeScore += AddedPoints;
		LadderData.Credits += AddedPoints;

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	return ELR_NoInterrupt;
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

	`TACTICALRULES.bWaitingForMissionSummary = false;
	Pres = `PRES;
	Pres.Screenstack.Pop(UpgradeScreen);
	UpgradeScreen.Destroy();
	UpgradeScreen = none;
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

	// don't do an upgrade choice for completing the last mission
	if (LadderData.LadderRung == LadderData.LadderSize)
		return false;

	Pres = `PRES;
	LadderData.UpgradeScreen = Pres.Spawn(class'UILadderSquadUpgradeScreen');
	Pres.Screenstack.Push(LadderData.UpgradeScreen);

	return true;
}

function PurchaseTechUpgrade(name DataName, XComGameState NewGameState)
{
	local X2ResistanceTechUpgradeTemplateManager TemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	local X2StrategyElementTemplateManager TechMgr;
	local X2TechTemplate TechTemplate, RequiredTechTemplate;
	local XComGameState_Tech TechState, RequiredTechState;
	local XComGameState_HeadquartersXCom XComHQ;

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

function bool CanAfford(X2ResistanceTechUpgradeTemplate Template)
{
	if (Credits < Template.Cost)
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