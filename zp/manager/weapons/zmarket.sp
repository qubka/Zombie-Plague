/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          zmarket.sp
 *  Type:          Module
 *  Description:   ZMarket module, provides menu of weapons to buy from.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/
 
/**
 * @section Number of valid buy menus.
 **/
enum MenuType
{
	/* Buymenu */
	MenuType_Invalid = -1,        /** Used as return value when a menu doens't exist. */
	
	MenuType_Pistols,             /** Pistol menu */
	MenuType_Shotguns,            /** Shotgun menu */
	MenuType_Rifles,              /** Rifle menu */
	MenuType_Snipers,             /** Sniper menu */
	MenuType_Machineguns,         /** Machineguns menu */
	MenuType_Knifes,              /** Knife menu */
	MenuType_Equipments,          /** Equipment menu */
	
	/* Rebuy */
	MenuType_Rebuy,               /** Rebuy menu */  
	MenuType_Option,              /** Option menu */  
	MenuType_Add                  /** Add menu */
};
/**
 * @endsection
 **/ 
 
/**
 * @section Number of valid arsenal menus.
 **/
enum /*ArsenalType*/
{
	ArsenalType_Primary,             /** Primary menu */  
	ArsenalType_Secondary,           /** Secondary menu */  
	ArsenalType_Melee                /** Melee menu */
};
/**
 * @endsection
 **/ 

/**
 * @brief Market module init function.
 **/
void ZMarketOnInit(/*void*/)
{
	// Initialize map containg market names and types
	gServerData.Market = new StringMap();
	
	// Push data into map
	gServerData.Market.SetValue("custom", MenuType_Invalid);
	gServerData.Market.SetValue("pistol", MenuType_Pistols);
	gServerData.Market.SetValue("shotgun", MenuType_Shotguns);
	gServerData.Market.SetValue("rifle", MenuType_Rifles);
	gServerData.Market.SetValue("sniper", MenuType_Snipers);
	gServerData.Market.SetValue("machinegun", MenuType_Machineguns);
	gServerData.Market.SetValue("knife",  MenuType_Knifes);
	gServerData.Market.SetValue("equipment", MenuType_Equipments);
}

/**
 * @brief Initialize arsenal weapons during the loading.
 **/
void ZMarketOnLoad(/*void*/)
{
	// Validate arsenal
	if (!gCvarList.ZMARKET_ARSENAL.BoolValue)
	{
		return;
	}
	
	// If array hasn't been created, then create
	if (gServerData.Arsenal == null)
	{
		// Initialize a type list array
		gServerData.Arsenal = new ArrayList();
	}
	else
	{
		// Clear out the array of all data
		ConfigClearKvArray(gServerData.Arsenal);
	}
	
	// Load weapons from cvars
	ZMarketArsenalSet(gCvarList.ZMARKET_PRIMARY);
	ZMarketArsenalSet(gCvarList.ZMARKET_SECONDARY);
	ZMarketArsenalSet(gCvarList.ZMARKET_MELEE);
	ZMarketArsenalSet(gCvarList.ZMARKET_ADDITIONAL);
	
	// i = client index
	for (int i = 1; i <= MaxClients; i++) 
	{
		// Validate client
		if (IsPlayerExist(i, false)) 
		{
			// x = array index
			for (int x = ArsenalType_Primary; x <= ArsenalType_Melee; x++)
			{
				// Resets stored arsenal
				gClientData[i].Arsenal[x] = -1;
			}
		}
	}
}

/**
 * @brief Client has been changed class state. *(Post)
 * 
 * @param client            The client index.
 **/
void ZMarketOnClientUpdate(int client)
{
	// Variable to prevent open several menus
	bool bOpen = false;
	
	// Resets the current arsenal menu
	gClientData[client].CurrentMenu = ArsenalType_Primary;
	gClientData[client].BlockMenu = false;
	
	// Validate arsenal
	if (gCvarList.ZMARKET_ARSENAL.BoolValue)
	{
		// Give weapons
		bOpen = ZMarketArsenallGive(client);
	}
	
	// Resets shopping cart for client
	ZMarketResetShoppingCart(client); 
	
	// Validate cart size
	if (!bOpen && gClientData[client].DefaultCart.Length)
	{
		// Opens rebuy menu
		ZMarketBuyMenu(client, "rebuy", MenuType_Rebuy);
	}
	
	// Validate real client
	if (gCvarList.ZMARKET_BUTTON.BoolValue && !IsFakeClient(client)) 
	{
		// Unlock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "1");
	}
}

/**
 * @brief Fake client has been think.
 *
 * @param client            The client index.
 **/
void ZMarketOnFakeClientThink(int client)
{
	// Buying chance
	if (GetRandomInt(0, 10))
	{
		return
	} 
	
	// If mode already started, then stop
	if ((gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode) && !gClientData[client].Zombie) || gServerData.RoundEnd)
	{ 
		return;
	}
	
	// Get random weapon
	int iD = GetRandomInt(0, gServerData.Weapons.Length - 1);

	// Validate access
	if (WeaponsGetSlot(iD) == MenuType_Invalid || !WeaponsValidateClass(client, iD) || WeaponsValidateByID(client, iD))
	{
		return;
	}    
	
	// Call forward
	Action hResult; 
	gForwardData._OnClientValidateWeapon(client, iD, hResult);
	
	// Validate access
	if (hResult == Plugin_Stop || hResult == Plugin_Handled)
	{
		return;
	}
	
	// Gets weapon group
	static char sBuffer[SMALL_LINE_LENGTH];
	WeaponsGetGroup(iD, sBuffer, sizeof(sBuffer));
	
	// Validate access
	if ((hasLength(sBuffer) && !IsPlayerInGroup(client, sBuffer)) || gClientData[client].Level < WeaponsGetLevel(iD) || fnGetPlaying() < WeaponsGetOnline(iD) || (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(client, iD)) || (WeaponsGetCost(iD) && gClientData[client].Money < WeaponsGetCost(iD)))
	{
		return;
	}
	
	// Give weapon for the player
	if (WeaponsGive(client, iD) != -1)
	{
		// If weapon has a cost
		if (WeaponsGetCost(iD))
		{
			// Remove money and store it for returning if player will be first zombie
			AccountSetClientCash(client, gClientData[client].Money - WeaponsGetCost(iD));
			gClientData[client].LastPurchase += WeaponsGetCost(iD);
		}
		
		// If weapon has a limit
		if (WeaponsGetLimit(iD))
		{
			// Increment count
			WeaponsSetLimits(client, iD, WeaponsGetLimits(client, iD) + 1);
		}

		// If help messages enabled, then show info
		if (gCvarList.MESSAGES_WEAPON_ALL.BoolValue)
		{
			// Gets client name
			static char sInfo[SMALL_LINE_LENGTH];
			GetClientName(client, sInfo, sizeof(sInfo));

			// Gets weapon name
			WeaponsGetName(iD, sBuffer, sizeof(sBuffer));    
			
			// Show item buying info
			TranslationPrintToChatAll("buy info", sInfo, sBuffer);
		}
	}
}

/**
 * @brief Creates commands for market module.
 **/
void ZMarketOnCommandInit(/*void*/)
{
	// Hook commands
	RegConsoleCmd("zrebuy", ZMarketRebuyOnCommandCatched, "Opens the rebuy menu.");
	RegConsoleCmd("zpistol", ZMarketPistolsOnCommandCatched, "Opens the pistols menu.");
	RegConsoleCmd("zshotgun", ZMarketShotgunsOnCommandCatched, "Opens the shotguns menu.");
	RegConsoleCmd("zrifle", ZMarketRiflesOnCommandCatched, "Opens the rifles menu.");
	RegConsoleCmd("zsniper", ZMarketSnipersOnCommandCatched, "Opens the snipers menu.");
	RegConsoleCmd("zmach", ZMarketMachinegunsOnCommandCatched, "Opens the machineguns menu.");
	RegConsoleCmd("zknife", ZMarketKnifesOnCommandCatched, "Opens the knifes menu.");
	RegConsoleCmd("zequip", ZMarketEquipsOnCommandCatched, "Opens the equipments menu.");
	RegConsoleCmd("zarsenal", ZMarketArsenalOnCommandCatched, "Opens the arsenal menu.");
}

/**
 * @brief Hook market cvar changes.
 **/
void ZMarketOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.ZMARKET_BUTTON         = FindConVar("zp_zmarket_button");
	gCvarList.ZMARKET_REOPEN         = FindConVar("zp_zmarket_reopen");
	gCvarList.ZMARKET_REBUY          = FindConVar("zp_zmarket_rebuy");
	gCvarList.ZMARKET_PISTOL         = FindConVar("zp_zmarket_pistol");
	gCvarList.ZMARKET_SHOTGUN        = FindConVar("zp_zmarket_shotgun");
	gCvarList.ZMARKET_RIFLE          = FindConVar("zp_zmarket_rifle");
	gCvarList.ZMARKET_SNIPER         = FindConVar("zp_zmarket_sniper");
	gCvarList.ZMARKET_MACH           = FindConVar("zp_zmarket_mach");
	gCvarList.ZMARKET_KNIFE          = FindConVar("zp_zmarket_knife");
	gCvarList.ZMARKET_EQUIP          = FindConVar("zp_zmarket_equip");
	gCvarList.ZMARKET_ARSENAL        = FindConVar("zp_zmarket_arsenal");
	gCvarList.ZMARKET_RANDOM_WEAPONS = FindConVar("zp_zmarket_random_weapons");
	gCvarList.ZMARKET_PRIMARY        = FindConVar("zp_zmarket_primary");
	gCvarList.ZMARKET_SECONDARY      = FindConVar("zp_zmarket_secondary");
	gCvarList.ZMARKET_MELEE          = FindConVar("zp_zmarket_melee");
	gCvarList.ZMARKET_ADDITIONAL     = FindConVar("zp_zmarket_additional");
	
	// Hook cvars
	HookConVarChange(gCvarList.ZMARKET_BUTTON,     ZMarketOnCvarHook);
	HookConVarChange(gCvarList.ZMARKET_ARSENAL,    ZMarketOnCvarHookShop);
	HookConVarChange(gCvarList.ZMARKET_PRIMARY,    ZMarketOnCvarHookShop);
	HookConVarChange(gCvarList.ZMARKET_SECONDARY,  ZMarketOnCvarHookShop);
	HookConVarChange(gCvarList.ZMARKET_MELEE,      ZMarketOnCvarHookShop);
	HookConVarChange(gCvarList.ZMARKET_ADDITIONAL, ZMarketOnCvarHookShop);
	
	// Load cvars
	ZMarketOnCvarLoad();
}

/**
 * @brief Load market listeners changes.
 **/
void ZMarketOnCvarLoad(/*void*/)
{
	// Validate buy button
	if (gCvarList.ZMARKET_BUTTON.BoolValue)
	{
		// Hook listeners
		AddCommandListener(ZMarketOnCommandListened, "open_buymenu");
	}
	else
	{
		// Unhook listeners
		RemoveCommandListener2(ZMarketOnCommandListened, "open_buymenu");
	}
}

/*
 * Market main functions.
 */

/**
 * Cvar hook callback (zp_buy_button)
 * @brief Buymenu button hooks initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ZMarketOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Forward event to modules
	ZMarketOnCvarLoad();
}

/**
 * Cvar hook callback (zp_zmarket_arsenal, zp_zmarket_primary, zp_zmarket_secondary, zp_zmarket_melee, zp_zmarket_additional)
 * @brief ZMarket buymenu module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void ZMarketOnCvarHookShop(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Forward event to modules
	ZMarketOnLoad();
}
 
/**
 * Listener command callback (open_buymenu)
 * @brief Buying of the weapons.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action ZMarketOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	// Validate real client
	if (IsPlayerExist(client) && !IsFakeClient(client))
	{
		// If mode already started, then stop
		if (gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode) && !gClientData[client].Zombie)
		{
			// Show block info
			TranslationPrintHintText(client, "buying round block"); 

			// Emit error sound
			EmitSoundToClient(client, "*buttons/weapon_cant_buy.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
			return Plugin_Continue;
		}
		
		// Lock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "0");
		
		// Opens weapon menu
		int iD[2]; iD = MenusCommandToArray("zpistol");
		if (iD[0] != -1) SubMenu(client, iD[0]);
		
		// Sets timer for reseting command
		delete gClientData[client].BuyTimer;
		gClientData[client].BuyTimer = CreateTimer(1.0, ZMarketOnClientBuyMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Allow command
	return Plugin_Continue;
}

/**
 * @brief Timer callback, auto-close a default buy menu.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ZMarketOnClientBuyMenu(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Clear timer
	gClientData[client].BuyTimer = null;
	
	// Validate client
	if (client)
	{
		// Unlock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "1");
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Called when a player attempts to purchase an item.
 * 
 * @param client            The client index.
 * @param sName             The weapon name.
 **/
public Action CS_OnBuyCommand(int client, const char[] sName)
{
	// Block buy
	return Plugin_Handled;
}

/**
 * Console command callback (zrebuy)
 * @brief Changes the rebuy state.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRebuyOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_REBUY.BoolValue)
	{
		ZMarketOptionMenu(client);
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zpistol)
 * @brief Opens the pistols menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketPistolsOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_PISTOL.BoolValue)
	{
		ZMarketBuyMenu(client, "buy pistols", MenuType_Pistols); 
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zshotgun)
 * @brief Opens the shotguns menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketShotgunsOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_SHOTGUN.BoolValue)
	{
		ZMarketBuyMenu(client, "buy shotguns", MenuType_Shotguns); 
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zrifle)
 * @brief Opens the rifles menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRiflesOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_RIFLE.BoolValue)
	{
		ZMarketBuyMenu(client, "buy rifles", MenuType_Rifles); 
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zsniper)
 * @brief Opens the snipers menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketSnipersOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_SNIPER.BoolValue)
	{
		ZMarketBuyMenu(client, "buy snipers", MenuType_Snipers); 
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zmachinegun)
 * @brief Opens the machineguns menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketMachinegunsOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_MACH.BoolValue)
	{
		ZMarketBuyMenu(client, "buy machineguns", MenuType_Machineguns); 
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zknife)
 * @brief Opens the knifes menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketKnifesOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_KNIFE.BoolValue)
	{
		ZMarketBuyMenu(client, "buy knifes", MenuType_Knifes); 
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zequip)
 * @brief Opens the equipments menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketEquipsOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.ZMARKET_EQUIP.BoolValue)
	{
		ZMarketBuyMenu(client, "buy equipments", MenuType_Equipments); 
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zarsenal)
 * @brief Opens the arsenal menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketArsenalOnCommandCatched(int client, int iArguments)
{
	// Validate arsenal
	if (gCvarList.ZMARKET_ARSENAL.BoolValue && !gCvarList.ZMARKET_RANDOM_WEAPONS.BoolValue)
	{
		ZMarketArsenalOpen(client, gClientData[client].CurrentMenu);
	}
	return Plugin_Handled;
}

/*
 * Market functions.
 */

/**
 * @brief Creates the buy menu.
 *
 * @param client            The client index.
 * @param sTitle            The menu title.
 * @param mSlot             (Optional) The slot index.
 * @param sType             (Optional) The class type.
 **/
void ZMarketBuyMenu(int client, char[] sTitle, MenuType mSlot = MenuType_Equipments, char[] sType = "") 
{
	// Initialize variables
	bool bMenu = (mSlot != MenuType_Rebuy); bool bRebuy = (mSlot == MenuType_Add || mSlot == MenuType_Option);
	
	// Validate menu
	if (!bMenu && !gCvarList.ZMARKET_REBUY.BoolValue)
	{
		return;
	}

	// Validate client
	if (!IsPlayerExist(client))
	{
		return;
	}

	// If mode already started, then stop
	if (gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode) && !gClientData[client].Zombie)
	{
		// Show block info
		TranslationPrintHintText(client, "buying round block"); 

		// Emit error sound
		EmitSoundToClient(client, "*buttons/weapon_cant_buy.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
		return;
	}

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	static char sLevel[SMALL_LINE_LENGTH];
	static char sLimit[SMALL_LINE_LENGTH];
	static char sOnline[SMALL_LINE_LENGTH];
	static char sGroup[SMALL_LINE_LENGTH];
	static char sClass[MAXPLAYERS+1][SMALL_LINE_LENGTH];
	
	// Gets amount of total players
	int iPlaying = fnGetPlaying();
	
	// Update class type mode
	if (hasLength(sType)) strcopy(sClass[client], sizeof(sClass[]), sType);
	
	// Creates menu handle
	Action hResult; Menu hMenu = ZMarketSlotToHandle(client, mSlot);

	// Sets language to target
	SetGlobalTransTarget(client);

	// Switch slot
	switch (mSlot)
	{
		case MenuType_Option :
		{
			// Format some chars for showing in menu
			FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "add");
			
			// Show add option
			hMenu.AddItem("-1", sBuffer);
		}
		
		case MenuType_Rebuy :
		{
			// Format some chars for showing in menu
			FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "buy");
			
			// Show add option
			hMenu.AddItem("-1", sBuffer);
		}
	}
	
	// Format title for showing in menu
	FormatEx(sBuffer, sizeof(sBuffer), "%t", bRebuy && hasLength(sClass[client]) ? sClass[client] : sTitle);

	// Sets title
	hMenu.SetTitle(sBuffer);

	// i = array number
	int iSize = ZMarketSlotToCount(client, mSlot); int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		// Gets weapon id from the list
		int iD = ZMarketSlotToIndex(client, mSlot, i);

		// Validate add/option menu
		if (bRebuy)
		{
			// Skip some weapons, if class isn't equal
			if (!WeaponsValidateByClass(iD, sClass[client]))
			{
				continue;
			}
			
			// Skip some weapons, if slot isn't equal
			if (WeaponsGetSlot(iD) == MenuType_Invalid) 
			{
				continue;
			}
			
			// Gets weapon data
			WeaponsGetName(iD, sName, sizeof(sName));

			// Format some chars for showing in menu    
			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);

			// Show option
			IntToString(iD, sInfo, sizeof(sInfo));
			hMenu.AddItem(sInfo, sBuffer);
		}
		// Default menu
		else
		{
			// Call forward
			gForwardData._OnClientValidateWeapon(client, iD, hResult);
			
			// Skip, if weapon is disabled
			if (hResult == Plugin_Stop)
			{
				continue;
			}
			
			// Skip some weapons, if slot isn't equal
			if (bMenu && WeaponsGetSlot(iD) != mSlot) 
			{
				continue;
			}
			
			// Skip some weapons, if class isn't equal
			if (!WeaponsValidateClass(client, iD))
			{
				continue;
			}    

			// Gets weapon data
			WeaponsGetName(iD, sName, sizeof(sName));
			WeaponsGetGroup(iD, sGroup, sizeof(sGroup));
			
			// Format some chars for showing in menu
			FormatEx(sLevel, sizeof(sLevel), "%t", "level", WeaponsGetLevel(iD));
			FormatEx(sLimit, sizeof(sLimit), "%t", "limit", WeaponsGetLimit(iD));
			FormatEx(sOnline, sizeof(sOnline), "%t", "online", WeaponsGetOnline(iD));      
			FormatEx(sBuffer, sizeof(sBuffer), (WeaponsGetCost(iD)) ? "%t  %s  %t" : "%t  %s", sName, hasLength(sGroup) ? sGroup : (gClientData[client].Level < WeaponsGetLevel(iD)) ? sLevel : (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(client, iD)) ? sLimit : (iPlaying < WeaponsGetOnline(iD)) ? sOnline : "", "price", WeaponsGetCost(iD), "money");

			// Show option
			IntToString(iD, sInfo, sizeof(sInfo));
			hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((hResult == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || WeaponsValidateByID(client, iD) || gClientData[client].Level < WeaponsGetLevel(iD) || iPlaying < WeaponsGetOnline(iD) || (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(client, iD)) || (WeaponsGetCost(iD) && gClientData[client].Money < WeaponsGetCost(iD))) ? false : true));
		}
		
		// Increment amount
		iAmount++;
	}
	
	// If there are no cases, add an "(Empty)" line
	if (!iAmount)
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}
	
	// Sets exit and back button
	hMenu.ExitBackButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	if (!bMenu && !iAmount) delete hMenu;
	else hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the rebuy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketBuyMenuSlots1(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				// Opens menu back
				int iD[2]; iD = MenusCommandToArray("zpistol");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
		   
			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Validate button info
			switch (iD)
			{
				// Client hit 'Add' button
				case -1 :
				{
					// Opens market menu back
					ZMarketBuyMenu(client, "add", MenuType_Add);
				}
				
				// Client hit 'Weapon' button
				default :
				{
					// Validate index
					int iIndex = gClientData[client].DefaultCart.FindValue(iD);
					if (iIndex != -1)
					{
						// Remove index from the history
						gClientData[client].DefaultCart.Erase(iIndex);
					}
					
					// Gets weapon name
					WeaponsGetName(iD, sBuffer, sizeof(sBuffer));
					
					// Remove weapon from the database
					DataBaseOnClientUpdate(client, ColumnType_Weapon, FactoryType_Delete, sBuffer);
					
					// Opens market menu back
					ZMarketBuyMenu(client, "rebuy", MenuType_Option);
				}
			}
		}
	}
	
	return 0;
}

/**
 * @brief Called when client selects option in the rebuy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketBuyMenuSlots2(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				// Opens market menu back
				ZMarketBuyMenu(client, "rebuy", MenuType_Option);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
		   
			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Gets weapon name
			WeaponsGetName(iD, sBuffer, sizeof(sBuffer));
			
			// Add index to the history
			gClientData[client].DefaultCart.Push(iD);

			// Insert weapon in the database
			DataBaseOnClientUpdate(client, ColumnType_Weapon, FactoryType_Insert, sBuffer);
			
			// Opens market menu back
			ZMarketBuyMenu(client, "rebuy", MenuType_Option);
		}
	}
	
	return 0;
}

/**
 * @brief Called when client selects option in the rebuy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketBuyMenuSlots3(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Call menu
	return ZMarketBuyMenuSlots(hMenu, mAction, client, mSlot, true);
}

/**
 * @brief Called when client selects option in the shop menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketBuyMenuSlots4(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Call menu
	return ZMarketBuyMenuSlots(hMenu, mAction, client, mSlot);
}

/**
 * @brief Called when client selects option in the shop menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bRebuy            (Optional) True to set the rebuy mode, false to set normal mode.
 **/ 
int ZMarketBuyMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot, bool bRebuy = false)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				// Opens menu back
				int iD[2]; iD = MenusCommandToArray("zpistol");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client))
			{
				return 0;
			}
			
			// If mode already started, then stop
			if ((gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode) && !gClientData[client].Zombie) || gServerData.RoundEnd)
			{
				// Show block info
				TranslationPrintHintText(client, "buying round block");
		
				// Emit error sound
				EmitSoundToClient(client, "*buttons/weapon_cant_buy.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}

			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Validate button info
			switch (iD)
			{
				// Client hit 'Buy' button
				case -1 :
				{
					// Initialize variables
					Action hResult; int iPlaying = fnGetPlaying();
					
					// i = array number
					int iSize = gClientData[client].ShoppingCart.Length;
					for (int i = 0; i < iSize; i++)
					{
						// Gets weapon id from the list
						iD = gClientData[client].ShoppingCart.Get(i);
						
						// Gets weapon data
						WeaponsGetGroup(iD, sBuffer, sizeof(sBuffer));
						
						// Access validation should be made here, because user is trying to buy all weapons without accessing a menu cases
						if ((hasLength(sBuffer) && !IsPlayerInGroup(client, sBuffer)) || WeaponsValidateByID(client, iD) || !WeaponsValidateClass(client, iD) || gClientData[client].Level < WeaponsGetLevel(iD) || iPlaying < WeaponsGetOnline(iD) || (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(client, iD)) || (WeaponsGetCost(iD) && gClientData[client].Money < WeaponsGetCost(iD)))
						{
							continue;
						}
						
						// Call forward
						gForwardData._OnClientValidateWeapon(client, iD, hResult);
						
						// Validate handle
						if (hResult == Plugin_Continue || hResult == Plugin_Changed)
						{
							// Give weapon for the player
							if (WeaponsGive(client, iD) != -1)
							{
								// If weapon has a cost
								if (WeaponsGetCost(iD))
								{
									// Remove money and store it for returning if player will be first zombie
									AccountSetClientCash(client, gClientData[client].Money - WeaponsGetCost(iD));
									gClientData[client].LastPurchase += WeaponsGetCost(iD);
								}
								
								// If weapon has a limit
								if (WeaponsGetLimit(iD))
								{
									// Increment count
									WeaponsSetLimits(client, iD, WeaponsGetLimits(client, iD) + 1);
								}
								
								// Remove index from the history
								gClientData[client].ShoppingCart.Erase(i);
								
								// Subtract one from count
								iSize--;

								// Backtrack one index, because we deleted it out from under the loop
								i--;
							}
						}
					}
				}
				
				// Client hit 'Weapon' button
				default :
				{
					// Call forward
					Action hResult; 
					gForwardData._OnClientValidateWeapon(client, iD, hResult);
					
					// Validate handle
					if (hResult == Plugin_Continue || hResult == Plugin_Changed)
					{
						// Validate access
						if (!WeaponsValidateByID(client, iD) && WeaponsValidateClass(client, iD))
						{
							// Give weapon for the player
							if (WeaponsGive(client, iD) != -1)
							{
								// If weapon has a cost
								if (WeaponsGetCost(iD))
								{
									// Remove money and store it for returning if player will be first zombie
									AccountSetClientCash(client, gClientData[client].Money - WeaponsGetCost(iD));
									gClientData[client].LastPurchase += WeaponsGetCost(iD);
								}
								
								// If weapon has a limit
								if (WeaponsGetLimit(iD))
								{
									// Increment count
									WeaponsSetLimits(client, iD, WeaponsGetLimits(client, iD) + 1);
								}

								// Is it rebuy menu ?
								if (bRebuy)
								{
									// Validate index
									int iIndex = gClientData[client].ShoppingCart.FindValue(iD);
									if (iIndex != -1)
									{
										// Remove index from the history
										gClientData[client].ShoppingCart.Erase(iIndex);

										// Validate cart size
										if (gClientData[client].ShoppingCart.Length)
										{
											// Reopen menu
											ZMarketBuyMenu(client, "rebuy", MenuType_Rebuy);
										}
									}
								}
								else
								{
									// If help messages enabled, then show info
									if (gCvarList.MESSAGES_WEAPON_ALL.BoolValue)
									{
										// Gets client name
										static char sInfo[SMALL_LINE_LENGTH];
										GetClientName(client, sInfo, sizeof(sInfo));

										// Gets weapon name
										WeaponsGetName(iD, sBuffer, sizeof(sBuffer));    
										
										// Show item buying info
										TranslationPrintToChatAll("buy info", sInfo, sBuffer);
									}
									
									// If help messages enabled, then show info
									if (gCvarList.MESSAGES_WEAPON_INFO.BoolValue)
									{
										// Gets weapon info
										WeaponsGetInfo(iD, sBuffer, sizeof(sBuffer));
										
										// Show weapon personal info
										if (hasLength(sBuffer)) TranslationPrintHintText(client, sBuffer);
									}
									
									// If reopen enabled, then opens menu back
									if (gCvarList.ZMARKET_REOPEN.BoolValue)
									{
										// Opens menu back
										int _iD[2]; _iD = MenusCommandToArray("zpistol");
										if (_iD[0] != -1) SubMenu(client, _iD[0]);
									}
								}
								
								// Return on success
								return 0;
							}
						}
					}
					
					// Gets weapon name
					WeaponsGetName(iD, sBuffer, sizeof(sBuffer));    
			
					// Show block info
					TranslationPrintHintText(client, "buying item block", sBuffer);
					
					// Emit error sound
					EmitSoundToClient(client, "*buttons/weapon_cant_buy.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);  
				}
			}
		}
	}
	
	return 0;
}

/*
 * Rebuy menu.
 */

/**
 * @brief Creates a market option menu.
 *
 * @param client            The client index.
 **/
void ZMarketOptionMenu(int client)
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}
	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sType[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	// Creates menu handle
	Menu hMenu = new Menu(ZMarketOptionMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "rebuy");

	// i = array index
	int iSize = gServerData.Types.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets type data
		gServerData.Types.GetString(i, sType, sizeof(sType));
		
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", sType);
		
		// Show option
		FormatEx(sInfo, sizeof(sInfo), "%s", sType);
		hMenu.AddItem(sInfo, sBuffer);
	}
	
	// If there are no cases, add an "(Empty)" line
	if (!iSize)
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}
	
	// Sets exit and back button
	hMenu.ExitBackButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the market option menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketOptionMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
{   
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				// Opens menu back
				int iD[2]; iD = MenusCommandToArray("zpistol");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}

			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));

			// Opens market menu back
			ZMarketBuyMenu(client, "rebuy", MenuType_Option, sBuffer);
		}
	}
	
	return 0;
}

/*
 * Arsenal menu.
 */

/**
 * @brief Creates an arsenal menu.
 *
 * @param client            The client index.
 * @param mSlot             The slot index. (arsenal)
 **/
void ZMarketArsenalMenu(int client, int mSlot)
{
	// Validate client
	if (!IsPlayerExist(client))
	{
		return;
	}
	
	// Disable menu for non humans and if blocked
	bool bDisabled = gClientData[client].BlockMenu || gClientData[client].Zombie || gClientData[client].Custom;

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	static char sLevel[SMALL_LINE_LENGTH];
	static char sOnline[SMALL_LINE_LENGTH];
	static char sGroup[SMALL_LINE_LENGTH];

	// Gets amount of total players
	int iPlaying = fnGetPlaying();

	// Creates menu handle
	Menu hMenu = ZMarketArsenalSlotToHandle(mSlot);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	static char sTitle[3][SMALL_LINE_LENGTH] = { "primary", "secondary", "melee" };
	hMenu.SetTitle("%t", sTitle[mSlot]);

	// Gets current arsenal list
	ArrayList hList = gServerData.Arsenal.Get(mSlot);

	// i = array index
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets weapon id from the list
		int iD = hList.Get(i);

		// Gets weapon data
		WeaponsGetName(iD, sName, sizeof(sName));
		WeaponsGetGroup(iD, sGroup, sizeof(sGroup))

		// Format some chars for showing in menu    
		FormatEx(sLevel, sizeof(sLevel), "%t", "level", WeaponsGetLevel(iD));
		FormatEx(sOnline, sizeof(sOnline), "%t", "online", WeaponsGetOnline(iD));  
		FormatEx(sBuffer, sizeof(sBuffer), (i == iSize - 1) ? "%t  %s\n \n" : "%t  %s", sName, hasLength(sGroup) ? sGroup : (gClientData[client].Level < WeaponsGetLevel(iD)) ? sLevel : (iPlaying < WeaponsGetOnline(iD)) ? sOnline : "");

		// Show option
		IntToString(iD, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((bDisabled || (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || gClientData[client].Level < WeaponsGetLevel(iD) || iPlaying < WeaponsGetOnline(iD)) ? false : true));
	}

	// Format some chars for showing in menu
	FormatEx(sBuffer, sizeof(sBuffer), "%t [%t]", "remember", gClientData[client].AutoSelect ? "On" : "Off");
	
	// Show toggle option
	hMenu.AddItem("-1", sBuffer);

	// Sets exit button
	hMenu.ExitButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it. (primary)
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketArsenalMenuSlots1(Menu hMenu, MenuAction mAction, int client, int mSlot)
{   
	return ZMarketArsenalMenuSlots(hMenu, mAction, client, mSlot, ArsenalType_Primary);
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it. (secondary)
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketArsenalMenuSlots2(Menu hMenu, MenuAction mAction, int client, int mSlot)
{   
	return ZMarketArsenalMenuSlots(hMenu, mAction, client, mSlot, ArsenalType_Secondary);
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it. (melee)
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketArsenalMenuSlots3(Menu hMenu, MenuAction mAction, int client, int mSlot)
{   
	return ZMarketArsenalMenuSlots(hMenu, mAction, client, mSlot, ArsenalType_Melee);
}

/**
 * @brief Called when client selects option in the market buy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param iIndex            The arsenal menu index.
 **/ 
int ZMarketArsenalMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot, int iIndex)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}

		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client))
			{
				return 0;
			}
			
			// Validate any except human, then stop
			if (gClientData[client].Zombie || gClientData[client].Custom)
			{
				// Show block info
				TranslationPrintHintText(client, "using menu block");
				
				// Emit error sound
				EmitSoundToClient(client, "*buttons/weapon_cant_buy.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}

			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Validate button info
			switch (iD)
			{
				// Client hit 'Remember' button
				case -1 :
				{
					// Toggle autoselect
					gClientData[client].AutoSelect = !gClientData[client].AutoSelect;
					
					// Opens same menu back
					ZMarketArsenalMenu(client, iIndex);
				}
				
				// Client hit 'Weapon' button
				default :
				{
					// Buy weapon
					if (WeaponsGive(client, iD) != -1)
					{
						// If help messages enabled, then show info
						if (gCvarList.MESSAGES_WEAPON_INFO.BoolValue)
						{
							// Gets weapon info
							WeaponsGetInfo(iD, sBuffer, sizeof(sBuffer));
							
							// Show weapon personal info
							if (hasLength(sBuffer)) TranslationPrintHintText(client, sBuffer);
						}
					}
					
					// Store selected weapon id
					gClientData[client].Arsenal[iIndex] = iD;
					gClientData[client].CurrentMenu = iIndex + 1;

					// Opens next menu
					if (ZMarketArsenalOpen(client, gClientData[client].CurrentMenu))
					{
						return 0;
					}

					// If last one, give additional weapons and opens rebuy menu

					// Give additional weapons
					ZMarketArsenalGiveAdds(client);
					
					// Validate cart size
					if (gClientData[client].DefaultCart.Length)
					{
						// Opens rebuy menu
						ZMarketBuyMenu(client, "rebuy", MenuType_Rebuy);
					}
				}
			}
		}
	}
	
	return 0;
}

/*
 * Stocks market API.
 */

/**
 * @brief Resets the shopping history for a client.
 *
 * @param client            The client index.
 **/
void ZMarketResetShoppingCart(int client)
{
	// If array hasn't been created, then create
	if (gClientData[client].DefaultCart == null)
	{
		// Initialize a default cart array
		gClientData[client].DefaultCart = new ArrayList();
	}
	
	// Validate cart size
	if (gClientData[client].DefaultCart.Length)
	{
		// Recreate shopping cart array
		delete gClientData[client].ShoppingCart;
		gClientData[client].ShoppingCart = gClientData[client].DefaultCart.Clone();
	}
}

/**
 * @brief Clear the shopping history for a client.
 * 
 * @param client            The client index.
 **/
void ZMarketClearShoppingCart(int client)
{
	// If mode already started, then stop
	if (!gServerData.RoundNew)
	{
		return;
	}
	
	// If array hasn't been created, then stop
	if (gClientData[client].ShoppingCart != null)
	{
		// Clear out the array of all data
		gClientData[client].ShoppingCart.Clear();
	}
}

/**
 * @brief Find the type at which the slot name is at.
 * 
 * @param sName             The slot name.
 * @return                  The type index.
 **/
MenuType ZMarketNameToIndex(char[] sName)
{
	// Validate slots
	MenuType nMenu;
	if (gServerData.Market.GetValue(sName, nMenu))
	{
		// Return index
		return nMenu;
	}
	
	// Name doesn't exist, may be that number ?
	return view_as<MenuType>(StringToInt(sName));
}

/**
 * @brief Find the handle at which the slot type is at.
 * 
 * @param client            The client index.
 * @param mSlot             The slot index.
 * @return                  The menu handle.
 **/
Menu ZMarketSlotToHandle(int client, MenuType mSlot)
{
	// Intitialize bool variable
	static bool bLock[MAXPLAYERS+1];
	
	// Validate shop menu
	switch (mSlot)
	{
		// Option menu
		case MenuType_Option :
		{
			return new Menu(ZMarketBuyMenuSlots1);
		}
		
		// Add menu
		case MenuType_Add :
		{
			return new Menu(ZMarketBuyMenuSlots2);
		}

		// Rebuy menu
		case MenuType_Rebuy :
		{
			// Boolean for reseting history
			bLock[client] = false;
		
			// Creates menu handle
			return new Menu(ZMarketBuyMenuSlots3);
		}

		// Default menu
		default :
		{
			// Creates menu handle
			Menu hMenu = new Menu(ZMarketBuyMenuSlots4);
			
			// Clear history
			if (!bLock[client]) 
			{
				ZMarketClearShoppingCart(client);
				bLock[client] = true;
			}
			
			// Return on success
			return hMenu;
		}
	}
}

/**
 * @brief Find the index at which the slot type is at.
 * 
 * @param client            The client index.
 * @param mSlot             The slot index.
 * @param iIndex            The id variable.
 * @return                  The index variable.
 **/
int ZMarketSlotToIndex(int client, MenuType mSlot, int iIndex)
{
	// Validate shop menu
	switch (mSlot)
	{
		// Option menu
		case MenuType_Option :
		{
			return gClientData[client].DefaultCart.Get(iIndex);
		}

		// Rebuy menu
		case MenuType_Rebuy :
		{
			return gClientData[client].ShoppingCart.Get(iIndex);
		}

		// Default menu
		default :
		{
			return iIndex;
		}
	}
}

/**
 * @brief Find the count at which the slot type is at.
 * 
 * @param client            The client index.
 * @param mSlot             The slot index.
 * @return                  The amount variable.
 **/
int ZMarketSlotToCount(int client, MenuType mSlot)
{
	// Validate shop menu
	switch (mSlot)
	{
		// Option menu
		case MenuType_Option :
		{
			return gClientData[client].DefaultCart.Length;
		}
   
		// Rebuy menu
		case MenuType_Rebuy :
		{
			return gClientData[client].ShoppingCart.Length;
		}

		// Default menu
		default :
		{
			return gServerData.Weapons.Length;
		}
	}
}

/**
 * @brief Find the handle at which the slot type is at.
 * 
 * @param mSlot             The slot index.
 * @return                  The menu handle.
 **/
Menu ZMarketArsenalSlotToHandle(int mSlot)
{
	// Validate shop menu
	switch (mSlot)
	{
		// Primary menu
		case ArsenalType_Primary :
		{
			return new Menu(ZMarketArsenalMenuSlots1);
		}
		
		// Secondary menu
		case ArsenalType_Secondary :
		{
			return new Menu(ZMarketArsenalMenuSlots2);
		}

		// Melee menu
		default :
		{
			return new Menu(ZMarketArsenalMenuSlots3);
		}
	}
}

/**
 * @brief Sets the weapons ids to the string map using the appropriate key.
 * 
 * @param hConVar           The cvar handle.
 **/
void ZMarketArsenalSet(ConVar hConVar)
{
	// Initialize variables
	static char sBuffer[PLATFORM_LINE_LENGTH];
	static char sWeapon[SMALL_LINE_LENGTH][SMALL_LINE_LENGTH];
	
	// Create array of indexes
	ArrayList hList = new ArrayList();
	
	// Gets the weapon string divived by commas
	hConVar.GetString(sBuffer, sizeof(sBuffer));
	int nWeapon = ExplodeString(sBuffer, ",", sWeapon, sizeof(sWeapon), sizeof(sWeapon[]));
	for (int i = 0; i < nWeapon; i++)
	{
		// Trim string
		TrimString(sWeapon[i]);

		// Validate index
		int iIndex = WeaponsNameToIndex(sWeapon[i]);
		if (iIndex != -1)
		{  
			// Validate access
			if (WeaponsValidateByClass(iIndex, "human"))
			{
				// Push data into array
				hList.Push(iIndex);
			}
		}
	}
	
	// Push list into array 
	gServerData.Arsenal.Push(hList);
}

/**
 * @brief Open the arsenal menu at which the slot type is at. (or next available)
 * 
 * @param client            The client index.
 * @param mSlot             The slot index.
 * @return                  True or false.
 **/
bool ZMarketArsenalOpen(int client, int mSlot)
{
	// i = array index
	for (int i = mSlot; i <= ArsenalType_Melee; i++) 
	{
		// Validate arsenal at given index
		ArrayList hList = gServerData.Arsenal.Get(i);
		if (hList.Length > 0)
		{
			// Opens menu
			ZMarketArsenalMenu(client, i);
			return true;
		}
	}
	
	// Return on failure
	return false;
}

/**
 * @brief Gives an arsenal weapons.
 *
 * @param client            The client index.
 * @return 					True if the menu was open, false otherwise.
 **/
bool ZMarketArsenallGive(int client)
{
	// Validate any except human, then stop
	if (gClientData[client].Zombie || gClientData[client].Custom)
	{
		return false;
	}
	
	// If mode already started, then stop
	if ((gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode)) || gServerData.RoundEnd)
	{ 
		return false;
	}
	
	// Random weapons setting enabled / Bots pick their weapons randomly
	if (gCvarList.ZMARKET_RANDOM_WEAPONS.BoolValue || IsFakeClient(client))
	{
		// Give additional weapons
		int weapon = ZMarketArsenalGiveAdds(client);

		// i = array index
		for (int i = ArsenalType_Melee; i != -1; i--)
		{
			// Validate that slot is knife
			if (i != ArsenalType_Melee)
			{
				// If knife is non default skip
				int weapon2 = GetPlayerWeaponSlot(client, i);
				if (weapon2 != -1 && ToolsGetCustomID(weapon2) != gServerData.Melee)
				{
					continue;
				}
			}
			
			// Gets current arsenal list
			ArrayList hList = gServerData.Arsenal.Get(i);
			
			// Validate size
			int iSize = hList.Length;
			if (iSize > 0)
			{
				// Give random weapons
				weapon = WeaponsGive(client, hList.Get(GetRandomInt(0, iSize - 1)), false);
			}
		}
		
		// Validate weapon
		if (weapon != -1)
		{
			// Switch weapon
			WeaponsSwitch(client, weapon);
		}
	}
	else 
	{
		// Open menu if autoselect turn off
		if (!gClientData[client].AutoSelect) 
		{
			return ZMarketArsenalOpen(client, ArsenalType_Primary);
		}
		else 
		{
			// i = array index
			for (int i = ArsenalType_Primary; i <= ArsenalType_Melee; i++)
			{
				// Open menu if autoselect turn on but some default not set
				ArrayList hList = gServerData.Arsenal.Get(i);
				if (gClientData[client].Arsenal[i] == -1 && hList.Length > 0)
				{
					return ZMarketArsenalOpen(client, ArsenalType_Primary);
				}
			}
			
			// Give additional weapons
			int weapon = ZMarketArsenalGiveAdds(client);

			// i = array index
			for (int i = ArsenalType_Melee; i != -1; i--)
			{
				// Validate that slot is knife
				if (i != ArsenalType_Melee)
				{
					// If knife is non default skip
					int weapon2 = GetPlayerWeaponSlot(client, i);
					if (weapon2 != -1 && ToolsGetCustomID(weapon2) != gServerData.Melee)
					{
						continue;
					}
				}
				
				// Give main weapons
				weapon = WeaponsGive(client, gClientData[client].Arsenal[i], false);
			}
			
			// Validate weapon
			if (weapon != -1)
			{
				// Switch weapon
				WeaponsSwitch(client, weapon);
			}
		}
	}
	
	// Return on success
	return false;
}

/**
 * @brief Gives an additional weapons.
 *
 * @param client            The client index.
 * @return                  The last weapon index.
 **/
int ZMarketArsenalGiveAdds(int client)
{
	// Gets additional weapons
	ArrayList hList = gServerData.Arsenal.Get(gServerData.Arsenal.Length - 1); int weapon = -1;
	
	// i = array index
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Give additional weapons
		weapon = WeaponsGive(client, hList.Get(i), false);
	}

	// Block arsenal from use
	gClientData[client].CurrentMenu = ArsenalType_Primary;
	gClientData[client].BlockMenu = true;
	
	// Return last weapon index
	return weapon;
}
