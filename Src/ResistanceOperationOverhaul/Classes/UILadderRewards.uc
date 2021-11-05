class UILadderRewards extends UIScreen;

var float fInitPosX, fInitPosY, EDGE_PADDING, fAlpha;
var int SecondColumnOffsetX;
var int TOP_PADDING;
var int DIALOG_WIDTH;
var int DIALOG_HEIGHT;

var XComGameState_LadderProgress_Override LadderData;

var localized string m_Title;
var localized string m_Continue;
var localized string m_Credits;
var localized string m_Science;
var localized string m_Upgrades;
var localized string m_NoUpgrade;

simulated function InitScreen(XcomPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	`LOG("InitScreen()", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
	super.InitScreen(InitController, InitMovie, InitName);

	BuildContainer();
}

simulated function OnInit()
{
	`LOG("OnInit()", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
	super.OnInit();
}

simulated function BuildContainer()
{
	local UIPanel Panel;
	local UIBGBox Background,PanelDecoration;
	local UIText PanelTitle;
	local UIButton PanelButtonAccept;

	`LOG("BuildContainer()", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);

	//Background
	Background = Spawn(class'UIBGBox', self);
	Background.bAnimateOnInit = false;
	Background.bCascadeFocus = false;
	Background.InitBG('SelectChoice_Background');
	Background.AnchorCenter();
	Background.SetPosition(fInitPosX,fInitPosY);
	Background.SetSize(DIALOG_WIDTH,270);
	Background.SetBGColor("cyan");
	Background.SetAlpha(fAlpha);	

	//Decoration >> makes it look better//
	PanelDecoration = Spawn(class'UIBGBox',self);
	PanelDecoration.bAnimateOnInit = false;
	PanelDecoration.InitBG('SelectChoice_TitleBackground');
	PanelDecoration.AnchorCenter();
	PanelDecoration.setPosition(fInitPosX,fInitPosY-40);
	PanelDecoration.setSize(DIALOG_WIDTH,40);
	PanelDecoration.SetBGColor("cyan");
	PanelDecoration.SetAlpha(fAlpha);

	//Container
	Panel = Spawn(class'UIPanel', self);
	Panel.bAnimateOnInit = false;
	Panel.bCascadeFocus = false;
	Panel.InitPanel();
	Panel.SetPosition(fInitPosX,fInitPosY);
	Panel.SetSize(DIALOG_WIDTH,170);
	
	//Accept-Button
	PanelButtonAccept = Spawn(class'UIButton', self);
	PanelButtonAccept.bAnimateOnInit = false;
	PanelButtonAccept.InitButton('PanelButtonAccept', m_Continue, OnPanelButtonAccept);
	PanelButtonAccept.AnchorCenter();
	PanelButtonAccept.setPosition(-75,20);
	PanelButtonAccept.setSize(150,30);
	PanelButtonAccept.SetSelected(false);
	PanelButtonAccept.SetFontSize(18);
	
	//Title
	PanelTitle = Spawn(class'UIText',self);
	PanelTitle.bAnimateOnInit = false;
	PanelTitle.InitText('PanelTitle',m_Title,false);
	PanelTitle.AnchorCenter();
	PanelTitle.SetPosition(fInitPosX+EDGE_PADDING,fInitPosY-35);
	PanelTitle.SetSize(DIALOG_WIDTH,40);
	PanelTitle.SetText(m_Title);
	`LOG("BuildContainer() end", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
}

simulated function Populate(XComGameState_LadderProgress_Override InLadderData)
{
	local UIText CreditsText, ScienceText, UpgradeText;
	local UIText CreditsValText, ScienceValText, UpgradeValText;
	local int OffsetY;
	local int SpaceY;
	local string UpgradeString;
	local X2ResistanceTechUpgradeTemplateManager UpgradeTemplateManager;
	local X2ResistanceTechUpgradeTemplate Template;
	local string CreditsLabel;
	local string ScienceLabel;
	local string UpgradesLabel;

	`LOG("Populate()", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);

	LadderData = InLadderData;
	SpaceY = 30;

	CreditsLabel = class'UIUtilities_Text'.static.InjectImage(class'UILadderSquadUpgradeScreen'.const.CreditsIcon, 20, 20, 0) @ m_Credits $ ":";
	ScienceLabel = class'UIUtilities_Text'.static.InjectImage(class'UILadderSquadUpgradeScreen'.const.ScienceIcon, 20, 20, 0) @ m_Science $ ":";
	UpgradesLabel = m_Upgrades $ ":";

	// Credits
	OffsetY = 0;
	CreditsText = Spawn(class'UIText',self);
	CreditsText.bAnimateOnInit = false;
	CreditsText.InitText('CreditsText', CreditsLabel,false);
	CreditsText.AnchorCenter();
	CreditsText.SetPosition(fInitPosX+EDGE_PADDING,fInitPosY+TOP_PADDING);
	CreditsText.SetSize(SecondColumnOffsetX,40);
	CreditsText.SetText(CreditsLabel);
	
	CreditsValText = Spawn(class'UIText',self);
	CreditsValText.bAnimateOnInit = false;
	CreditsValText.InitText('CreditsValText', string(InLadderData.ChosenMissionOption.Credits),false);
	CreditsValText.AnchorCenter();
	CreditsValText.SetPosition(fInitPosX+EDGE_PADDING + SecondColumnOffsetX,fInitPosY+TOP_PADDING);
	CreditsValText.SetSize(200,40);
	CreditsValText.SetText(string(InLadderData.ChosenMissionOption.Credits));
	
	// Science
	OffsetY = OffsetY + SpaceY;
	ScienceText = Spawn(class'UIText',self);
	ScienceText.bAnimateOnInit = false;
	ScienceText.InitText('ScienceText', ScienceLabel,false);
	ScienceText.AnchorCenter();
	ScienceText.SetPosition(fInitPosX+EDGE_PADDING,fInitPosY+TOP_PADDING+OffsetY);
	ScienceText.SetSize(SecondColumnOffsetX,40);
	ScienceText.SetText(ScienceLabel);
	
	ScienceValText = Spawn(class'UIText',self);
	ScienceValText.bAnimateOnInit = false;
	ScienceValText.InitText('ScienceValText', string(InLadderData.ChosenMissionOption.Science),false);
	ScienceValText.AnchorCenter();
	ScienceValText.SetPosition(fInitPosX+EDGE_PADDING + SecondColumnOffsetX,fInitPosY+TOP_PADDING+OffsetY);
	ScienceValText.SetSize(200,40);
	ScienceValText.SetText(string(InLadderData.ChosenMissionOption.Science));
	
	// Upgrade
	OffsetY = OffsetY + SpaceY;
	UpgradeText = Spawn(class'UIText',self);
	UpgradeText.bAnimateOnInit = false;
	UpgradeText.InitText('UpgradeText', UpgradesLabel,false);
	UpgradeText.AnchorCenter();
	UpgradeText.SetPosition(fInitPosX+EDGE_PADDING,fInitPosY+TOP_PADDING+OffsetY);
	UpgradeText.SetSize(SecondColumnOffsetX,40);
	UpgradeText.SetText(UpgradesLabel);
	
	UpgradeString = m_NoUpgrade;
	if (InLadderData.ChosenMissionOption.FreeUpgrades.Length > 0)
	{
		// For now, assume at most one upgrade
		UpgradeTemplateManager = class'X2ResistanceTechUpgradeTemplateManager'.static.GetTemplateManager();
		Template = UpgradeTemplateManager.FindTemplate(InLadderData.ChosenMissionOption.FreeUpgrades[0]);
		UpgradeString = Template.DisplayName;
	}

	UpgradeValText = Spawn(class'UIText',self);
	UpgradeValText.bAnimateOnInit = false;
	UpgradeValText.InitText('UpgradeValText', UpgradeString,false);
	UpgradeValText.AnchorCenter();
	UpgradeValText.SetPosition(fInitPosX+EDGE_PADDING + SecondColumnOffsetX,fInitPosY+TOP_PADDING+OffsetY);
	UpgradeValText.SetSize(300,40);
	UpgradeValText.SetText(UpgradeString);

	`LOG("Populate() end", class'XComGameState_LadderProgress_Override'.default.ENABLE_LOG, class'XComGameState_LadderProgress_Override'.default.LOG_PREFIX);
}

public function OnPanelButtonAccept(UIButton Button)
{	
	LadderData.OnCloseRewardsScreen();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		OnPanelButtonAccept(none);
		bHandled = true;
		break;
	default:
		bHandled = false;
		break;
	}

	// always give base class a chance to handle the input so key input is propogated to the panel's navigator
	return (bHandled || super.OnUnrealCommand(cmd, arg));
}

defaultproperties
{
	EDGE_PADDING = 20;
	TOP_PADDING = 20;
	fInitPosX = -215;
	fInitPosY = -200;
	fAlpha = 1.0f;
	SecondColumnOffsetX=130;
	DIALOG_WIDTH=430;
}
