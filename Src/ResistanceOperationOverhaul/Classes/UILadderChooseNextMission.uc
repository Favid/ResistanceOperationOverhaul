class UILadderChooseNextMission extends UIScreen dependson(AStructs);

var UIButton	 Mission0Button;
var UIButton	 Mission1Button;

var array<MissionOption> MissionOptions;

var int SelectedColumn; 

var localized string m_ChooseMissionLabel;
var localized string m_ChooseMissionSubtitle;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	Mission0Button = Spawn(class'UIButton', self);
	Mission1Button = Spawn(class'UIButton', self);
	
	Mission0Button.InitButton('Upgrade00', m_ChooseMissionLabel, ChooseMission0);
	Mission1Button.InitButton('Upgrade01', m_ChooseMissionLabel, ChooseMission1);

	if( `ISCONTROLLERACTIVE )
	{
		SelectColumn(SelectedColumn);
	}
}

simulated function OnInit()
{
	local XComGameState_LadderProgress_Override LadderData;
	
	super.OnInit();

	LadderData = XComGameState_LadderProgress_Override(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override'));
	
	MC.BeginFunctionOp("SetScreenTitle");
	MC.QueueString(class'UIMissionSummary'.default.m_strMissionComplete); // Title
	MC.QueueString(LadderData.LadderName);//Mission Name
	MC.QueueString(class'UILadderSoldierInfo'.default.m_MissionLabel);//Mission Label
	MC.QueueString(String(LadderData.LadderRung) $ "/" $ String(LadderData.LadderSize));//Mission Count
	MC.QueueString(m_ChooseMissionSubtitle);//Upgrade sub title
	MC.EndOp();

	MissionOptions = LadderData.GetMissionOptions();

	PopulateMissionPanel(0, MissionOptions[0]);
	PopulateMissionPanel(1, MissionOptions[1]);
}

simulated function PopulateMissionPanel(int Index, MissionOption Option)
{
	local X2MissionTemplateManager MissionTemplateManager;
	local string MapImagePath;
	local X2MissionTemplate MissionTemplate;
	local MissionDefinition MissionDef;
	local XComTacticalMissionManager MissionManager;
	local XComParcelManager ParcelManager;
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition NewPlot;
	local int InfoIndex;
	local int ResearchIndex;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	
	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.GetMissionDefinitionForType(Option.MissionType, MissionDef);
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(MissionDef.MissionName);
	
	ParcelManager = `PARCELMGR;
	ParcelManager.GetValidPlotsForMission(ValidPlots, MissionDef);
	NewPlot = ValidPlots[ `SYNC_RAND_STATIC(ValidPlots.Length) ];
	MapImagePath = `MAPS.SelectMapImage(NewPlot.strType);

	mc.BeginFunctionOp("SetUpgradePanel");
	mc.QueueNumber(Index); // index
	mc.QueueString("img:///"$MapImagePath); //upgrade image
	mc.QueueString(MissionTemplate.DisplayName); // upgrade title
	mc.QueueString(""); // upgrade info - this doesn't appear to do anything
	mc.QueueString(GetMissionButtonText(Index)); // choose this button text
	mc.EndOp();

	mc.BeginFunctionOp("SetUpgradeDetailRow");
	mc.QueueNumber(Index); // index
	
	InfoIndex = 0;

	MC.QueueString("Rewards:");
	InfoIndex++;

	MC.QueueString("Credits: " $ string(Option.Credits));
	InfoIndex++;

	MC.QueueString("Science: " $ string(Option.Science));
	InfoIndex++;
	
	UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();

	while (InfoIndex < 6)
	{
		if (Option.FreeUpgrades.Length > ResearchIndex)
		{
			Template = UpgradeTemplateManager.FindTemplate(Option.FreeUpgrades[ResearchIndex]);
			MC.QueueString("Free Research: " $ Template.DisplayName);
		}
		else
		{
			MC.QueueString("");
		}

		ResearchIndex++;
		InfoIndex++;
	}

	mc.EndOp();
}

simulated function ChooseMission0(UIButton button)
{
	local XComGameState_LadderProgress_Override LadderData;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	LadderData = XComGameState_LadderProgress_Override(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override', true));
	LadderData.OnChooseMission(MissionOptions[0]);
}

simulated function ChooseMission1(UIButton button)
{
	local XComGameState_LadderProgress_Override LadderData;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	LadderData = XComGameState_LadderProgress_Override(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress_Override', true));
	LadderData.OnChooseMission(MissionOptions[1]);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		//TODO : confirm column selection 
		if( SelectedColumn == 0 )
			ChooseMission0(none);
		else if( SelectedColumn == 1 )
			ChooseMission1(none);
		return true;

	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT :
	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT :
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT :
	case class'UIUtilities_Input'.const.FXS_KEY_D :
		SelectColumn(1);
		return true;

	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT :
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT :
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT :
	case class'UIUtilities_Input'.const.FXS_KEY_A :
		SelectColumn(0);
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function SelectColumn(int iCol)
{
	SelectedColumn = iCol; 
	MC.FunctionNum("SelectColumn", SelectedColumn); 

	RefreshContinueText(0);
	RefreshContinueText(1);
}

simulated function RefreshContinueText(int iCol)
{
	mc.BeginFunctionOp("SetContinueText");
	mc.QueueNumber(iCol); // index
	mc.QueueString(GetMissionButtonText(iCol)); // choose this button text
	mc.EndOp();
}

simulated function string GetMissionButtonText(int iCol)
{
	if( `ISCONTROLLERACTIVE && SelectedColumn == iCol )
	{
		return class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetAdvanceButtonIcon(), 26, 26, -10) @ m_ChooseMissionLabel;
	}
	else
	{
		return m_ChooseMissionLabel;
	}
}

defaultproperties
{
	Package = "/ package/gfxTLE_LadderLevelUp/TLE_LadderLevelUp";
	LibID = "UpgradeScreen";
	InputState = eInputState_Consume;

	bHideOnLoseFocus = false;

	SelectedColumn = 0; 
}


