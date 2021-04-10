class UITactical_PromotionHeroColumn extends UIPanel;

var int Rank;
var array<name> AbilityNames;

var array<UIButton> InfoButtons;
var array<UIIcon> AbilityIcons;

var bool bIsDisabled;
var bool bEligibleForPurchase;

var int m_iPanelIndex; // bsg-nlong (1.25.17): the index to keep track of which panel in the column is currently selected

function UITactical_PromotionHeroColumn InitPromotionHeroColumn(int InitRank)
{
	local UIIcon AbilityIcon;

	Rank = InitRank;

	InitPanel();
	
	AbilityIcon = Spawn(class'UIIcon', self).InitIcon('Ability0');
	AbilityIcon.ProcessMouseEvents(OnAbilityIconMouseEvent);
	AbilityIcon.bDisableSelectionBrackets = true;
	AbilityIcon.bAnimateOnInit = false;
	AbilityIcon.Hide(); // starts hidden
	AbilityIcons.AddItem(AbilityIcon);
	CreateInfoButton(AbilityIcon);
	
	AbilityIcon = Spawn(class'UIIcon', self).InitIcon('Ability1');
	AbilityIcon.ProcessMouseEvents(OnAbilityIconMouseEvent);
	AbilityIcon.bDisableSelectionBrackets = true;
	AbilityIcon.bAnimateOnInit = false;
	AbilityIcon.Hide(); // starts hidden
	AbilityIcons.AddItem(AbilityIcon);
	CreateInfoButton(AbilityIcon);

	AbilityIcon = Spawn(class'UIIcon', self).InitIcon('Ability2');
	AbilityIcon.ProcessMouseEvents(OnAbilityIconMouseEvent);
	AbilityIcon.bDisableSelectionBrackets = true;
	AbilityIcon.bAnimateOnInit = false;
	AbilityIcon.Hide(); // starts hidden
	AbilityIcons.AddItem(AbilityIcon);
	CreateInfoButton(AbilityIcon);
	
	AbilityIcon = Spawn(class'UIIcon', self).InitIcon('Ability3');
	AbilityIcon.ProcessMouseEvents(OnAbilityIconMouseEvent);
	AbilityIcon.bDisableSelectionBrackets = true;
	AbilityIcon.bAnimateOnInit = false;
	AbilityIcon.Hide(); // starts hidden
	AbilityIcons.AddItem(AbilityIcon);
	CreateInfoButton(AbilityIcon);

	DisableNavigation(); // bsg-nlong (1.25.17): Disable the navigator to manually impliment navigation
	
	return self;
}

function CreateInfoButton(UIIcon ParentIcon)
{
	local UIButton InfoButton;

	InfoButton = Spawn(class'UIButton', self);
	InfoButton.bIsNavigable = false;
	InfoButton.InitButton(Name("Info" $ ParentIcon.MCName));
	InfoButton.ProcessMouseEvents(OnInfoButtonMouseEvent);
	InfoButton.bAnimateOnInit = false;
	InfoButton.Hide(); // starts hidden
	InfoButtons.AddItem(InfoButton);
}

function PreviewAbility(int idx)
{
	local UITactical_PromotionHero PromotionScreen;
	
	PromotionScreen = UITactical_PromotionHero(Screen);
	PromotionScreen.PreviewAbility(Rank, idx);
}

function HideAbilityPreview()
{
	local UITactical_PromotionHero PromotionScreen;

	PromotionScreen = UITactical_PromotionHero(Screen);
	PromotionScreen.HidePreview();
}

function SelectAbility(int idx)
{
	local UITactical_PromotionHero PromotionScreen;
	
	PromotionScreen = UITactical_PromotionHero(Screen);

	if( PromotionScreen.OwnsAbility(AbilityNames[idx]) )
		OnInfoButtonMouseEvent(InfoButtons[idx], class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
	else if (bEligibleForPurchase && PromotionScreen.CanPurchaseAbility(Rank, idx, AbilityNames[idx]))
		PromotionScreen.ConfirmAbilitySelection(Rank, idx);
	else if (!PromotionScreen.IsAbilityLocked(Rank))
		OnInfoButtonMouseEvent(InfoButtons[idx], class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
}

function OnAbilityInfoClicked(UIButton Button)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local UIButton InfoButton;
	local UITactical_PromotionHero PromotionScreen;
	local int idx;

	PromotionScreen = UITactical_PromotionHero(Screen);

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach InfoButtons(InfoButton, idx)
	{
		if (InfoButton == Button)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityNames[idx]);
			break;
		}
	}
	
	// TODO
	//if (AbilityTemplate != none)
		//`HQPRES.UIAbilityPopup(AbilityTemplate, PromotionScreen.UnitReference);

	if( InfoButton != none )
		InfoButton.Hide();
}

function OnAbilityIconMouseEvent(UIPanel Panel, int Cmd)
{
	local UIIcon AbilityIcon;
	local bool bHandled;
	local int idx;
	
	foreach AbilityIcons(AbilityIcon, idx)
	{
		if (Panel == AbilityIcon)
		{
			if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
			{
				SelectAbility(idx);
			}
			else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
			{
				OnReceiveFocus();
				AbilityIcon.OnReceiveFocus();
				RealizeAvailableState(idx);
				
				PreviewAbility(idx);

				if( !UITactical_PromotionHero(Screen).IsAbilityLocked(Rank) )
				{
					InfoButtons[idx].Show();
				}
				ClearTimer('Hide', InfoButtons[idx]);
			}
			else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT)
			{
				AbilityIcon.OnLoseFocus();
				RealizeAvailableState(idx);

				HideAbilityPreview();
				SetTimer(0.01, false, 'Hide', InfoButtons[idx]);
			}

			bHandled = true;
			break;
		}
	}

	if (bHandled)
		RealizeVisuals();
}

function OnInfoButtonMouseEvent(UIPanel Panel, int Cmd)
{
	local UIButton InfoButton;
	local bool bHandled;
	local int idx;

	foreach InfoButtons(InfoButton, idx)
	{
		if (Panel == InfoButton )
		{
			if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
			{
				OnAbilityInfoClicked(UIButton(Panel));
				SetTimer(0.01, false, 'Hide', InfoButtons[idx]);
			}
			else if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER )
			{
				OnReceiveFocus();
				AbilityIcons[idx].OnReceiveFocus();
				RealizeAvailableState(idx);

				PreviewAbility(idx);
				InfoButtons[idx].Show();
				ClearTimer('Hide', InfoButtons[idx]);
			}
			else if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT )
			{
				AbilityIcons[idx].OnLoseFocus();
				RealizeAvailableState(idx);

				HideAbilityPreview();
				SetTimer(0.01, false, 'Hide', InfoButtons[idx]);
				InfoButtons[idx].Hide();
			}

			bHandled = true;
			break;
		}
	}

	if (bHandled)
		RealizeVisuals();
}

// bsg-nlong (1.25.17): Manual focus and navigation: the functions called in FocusIcon and UnfocusIcon are from OnAbilityIconMouseEvent
// The functions are copied in instead of just calling OnAbilityIconMouseEvent, because we need to call FocusIcon and UnfocusIcon in OnReceiveFocus() and OnLoseFocus() respectively
// and directly calling OnAbilityIconMouseEvent would cause an infinite loop. Creating these functions instead of creating a new class.
simulated function FocusIcon(int index)
{
	AbilityIcons[index].OnReceiveFocus();
	RealizeAvailableState(index);
	PreviewAbility(index);

	AbilityIcons[index].MC.FunctionVoid("mouseIn");
}

simulated function UnfocusIcon(int index)
{
	AbilityIcons[index].OnLoseFocus();
	RealizeAvailableState(index);
	HideAbilityPreview();

	AbilityIcons[index].MC.FunctionVoid("mouseOut");
}

simulated function SelectNextIcon()
{
	local int newIndex;
	newIndex = m_iPanelIndex; //Establish a baseline so we can loop correctly

	do
	{
		newIndex += 1;
		if( newIndex >= AbilityIcons.Length )
			newIndex = 0;
	} until( AbilityIcons[newIndex].bIsVisible);
	
	UnfocusIcon(m_iPanelIndex);
	m_iPanelIndex = newIndex;
	FocusIcon(m_iPanelIndex);
	Movie.Pres.PlayUISound(eSUISound_MenuSelect); //bsg-crobinson (5.11.17): Add sound
}

simulated function SelectPrevIcon()
{
	local int newIndex;
	newIndex = m_iPanelIndex; //Establish a baseline so we can loop correctly

	do
	{
		newIndex -= 1;
		if( newIndex < 0 )
			newIndex = AbilityIcons.Length - 1;
	} until( AbilityIcons[newIndex].bIsVisible);
	
	UnfocusIcon(m_iPanelIndex);
	m_iPanelIndex = newIndex;
	FocusIcon(m_iPanelIndex);
	Movie.Pres.PlayUISound(eSUISound_MenuSelect); //bsg-crobinson (5.11.17): Add sound
}

simulated function OnReceiveFocus()
{
	local int i;

	super.OnReceiveFocus();

	if( `ISCONTROLLERACTIVE )
	{
		for(i = 0; i < AbilityIcons.Length; ++i)
		{
			if( i != m_iPanelIndex && AbilityIcons[i].bIsVisible )
				UnfocusIcon(i);
		}

		FocusIcon(m_iPanelIndex);
	}
}

simulated function OnLoseFocus()
{
	local int i;

	super.OnLoseFocus();

	if( `ISCONTROLLERACTIVE )
	{
		for(i = 0; i < AbilityIcons.Length; ++i)
		{
			if( AbilityIcons[i].bIsVisible )
			{
				UnfocusIcon(i);
			}
		}
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	bHandled = true;

	switch(cmd)
	{
	case class'UIUtilities_Input'.static.GetAdvanceButtonInputCode():
		SelectAbility(m_iPanelIndex);
		bHandled = true;
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_L3:
		//bsg-hlee (05.08.17): If the ability is locked then don't show a description when clicked.
		if(!UITactical_PromotionHero(Screen).IsAbilityLocked(Rank))
		{
			OnAbilityInfoClicked(InfoButtons[m_iPanelIndex]);
			bHandled = true;
		}
		//bsg-hlee (05.08.17): End
		break;
	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN :
		SelectNextIcon();
		bHandled = true;
		break;
	case class'UIUtilities_Input'.const.FXS_DPAD_UP :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP :
		SelectPrevIcon();
		bHandled = true;
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled;
}
// bsg-nlong (1.25.17): end


function RealizeAvailableState(int AbilityIndex)
{
	if (bEligibleForPurchase && Movie.Pres.ScreenStack.GetCurrentScreen() == Screen)
		SetAvailable(true, AbilityIndex);
}

//==============================================================================

function SetDisabled(bool bDisabled)
{
	local UIIcon AbilityIcon;

	bIsDisabled = bDisabled;

	foreach AbilityIcons(AbilityIcon)
	{
		AbilityIcon.SetDisabled(bIsDisabled);
	}

	// TODO: Add Disabled function on Flash side
	//MC.FunctionBool("setDisabled", bIsDisabled);
}

function SetAvailable(bool bIsAvailable, optional int AbilityIndex = -1)
{
	bEligibleForPurchase = bIsAvailable;
	//AbilityIcons[AbilityIndex].bIsFocused;
}

function RealizeVisuals()
{
	// TODO: Highlight state for each column here on mouse-over?
}

function AS_SetData(bool bShowHighlight, string HighlightText, string RankIcon, string RankLabel)
{
	MC.BeginFunctionOp("SetData");
	MC.QueueBoolean(bShowHighlight);
	MC.QueueString(HighlightText);
	MC.QueueString(RankIcon);
	MC.QueueString(RankLabel);
	MC.EndOp();
}

function AS_SetIconState(int Index, bool bShowHighlight, string Image, string Label, int IconState, string ForegroundColor, string BackgroundColor, bool bIsConnected)
{
	AbilityIcons[Index].Show();

	MC.BeginFunctionOp("SetIconState");
	MC.QueueNumber(Index);
	MC.QueueBoolean(bShowHighlight);
	MC.QueueString(Image);
	MC.QueueString(Label);
	MC.QueueNumber(IconState); // 0: Locked, 1: Normal, 2: Equipped
	MC.QueueString(BackgroundColor);
	MC.QueueString(ForegroundColor);
	MC.QueueBoolean(bIsConnected);
	MC.EndOp();
}

defaultproperties
{
	LibID = "HeroAbilityColumn";
	MCName = "theScreen";
	bCascadeFocus = false;
}