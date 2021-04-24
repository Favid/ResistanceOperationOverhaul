// This is used to prevent LW2 Gauntlet users from equipping heavy weapons.
// This basically functions the same as the OverrideHasHeavyWeapon from LW2 Secondary Weapons,
// except that one only runs in strategy, and we need one that runs in tactical, because 
// UILadderSquadUpgradeScreen technically does its inventory modification in tactical. This
// shouldn't have any reason to do anything during the actual mission part of the tactical scene.
class X2EventListener_HasHeavyWeapon extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateOverrideHasHeavyWeaponListenerTemplate());

	return Templates;
}

static function CHEventListenerTemplate CreateOverrideHasHeavyWeaponListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'GauntletOverrideHasHeavyWeaponTactical');

	Template.RegisterInTactical = true;

	Template.AddCHEvent('OverrideHasHeavyWeapon', OnGauntletOverrideHasHeavyWeaponTactical, ELD_Immediate, 75);
	`LOG("X2EventListener_HasHeavyWeapon: Register Event OverrideHasHeavyWeapon: Resistance Operation Overhaul");

	return Template;
}

static function EventListenerReturn OnGauntletOverrideHasHeavyWeaponTactical(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple						OverrideTuple;
	local XComGameState_Unit				UnitState;
	local XComGameState						CheckGameState;
	local bool								bOverrideHasHeavyWeapon;
	local bool								bHasHeavyWeapon;
	local XComGameState_Item				InventoryItem;
	local array<XComGameState_Item>			CurrentInventory;
	local X2WeaponTemplate					WeaponTemplate;
	local name								WeaponCategory;
	local XComGameState						NewGameState;
	local XComGameState_HeadquartersXCom	XComHQ;
	local XGWeapon							HeavyWeapon;
	
	`LOG("=== X2EventListener_HasHeavyWeapon: OnGauntletOverrideHasHeavyWeapon");

	OverrideTuple = XComLWTuple(EventData);
	if(OverrideTuple == none)
		return ELR_NoInterrupt;

	bOverrideHasHeavyWeapon = OverrideTuple.Data[0].b;
	bHasHeavyWeapon = OverrideTuple.Data[1].b;
	UnitState = XComGameState_Unit(EventSource);
	CheckGameState = XComGameState(OverrideTuple.Data[2].o);

	if (UnitState == none)
	{
		return ELR_NoInterrupt;
	}

	// Search the inventory for the heavy gauntlet
	CurrentInventory = UnitState.GetAllInventoryItems(, true);
	foreach CurrentInventory(InventoryItem)
	{
		WeaponTemplate = X2WeaponTemplate(InventoryItem.GetMyTemplate());
		if (WeaponTemplate == none)
			continue;

		WeaponCategory = WeaponTemplate.WeaponCat;
	
		if (WeaponCategory == 'lw_gauntlet')
		{
			bOverrideHasHeavyWeapon = true;
			bHasHeavyWeapon = false;

			OverrideTuple.Data[0].b = bOverrideHasHeavyWeapon;
			OverrideTuple.Data[1].b = bHasHeavyWeapon;

			// Remove the equipped heavy weapon, if applicable
			InventoryItem = UnitState.GetItemInSlot(eInvSlot_HeavyWeapon, CheckGameState);
			if (InventoryItem != none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unequip Heavy Weapon From Unit Loadout");
				XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				
				// Weapon must be graphically detached, otherwise destroying it leaves a NULL component attached at that socket
				HeavyWeapon = XGWeapon(InventoryItem.GetVisualizer());
				XComUnitPawn(UnitState.GetVisualizer()).DetachItem(HeavyWeapon.GetEntity().Mesh);
				HeavyWeapon.Destroy();

				// Add the dropped item back to the HQ
				if (UnitState.RemoveItemFromInventory(InventoryItem, NewGameState))
				{
					XComHQ.PutItemInInventory(NewGameState, InventoryItem);
				}

				UnitState.ValidateLoadout(NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}	
			return ELR_NoInterrupt;
		}
	}
	return ELR_NoInterrupt;
}