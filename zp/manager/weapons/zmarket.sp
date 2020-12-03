/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          zmarket.sp
 *  Type:          Module
 *  Description:   ZMarket module, provides menu of weapons to buy from.
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
 * @brief Market module init function.
 **/
void ZMarketOnInit(/*void*/)
{
	// Initialize map containg market names and types
	gServerData.Market = new StringMap();
	
	// Push data into map
	gServerData.Market.SetValue("pistol", MenuType_Pistols);
	gServerData.Market.SetValue("shotgun", MenuType_Shotguns);
	gServerData.Market.SetValue("rifle", MenuType_Rifles);
	gServerData.Market.SetValue("sniper", MenuType_Snipers);
	gServerData.Market.SetValue("machinegun", MenuType_Machineguns);
	gServerData.Market.SetValue("knife",  MenuType_Knifes);
	gServerData.Market.SetValue("equipment", MenuType_Equipments);
	gServerData.Market.SetValue("custom", MenuType_Invalid);
}

/**
 * @brief Client has been changed class state. *(Post)
 * 
 * @param client            The client index.
 **/
void ZMarketOnClientUpdate(int client)
{
	// Resets purchase counts for client
	ZMarketRebuyMenu(client);
	
	// Validate real client
	if (gCvarList.BUY_BUTTON.BoolValue && !IsFakeClient(client)) 
	{
		// Unlock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "1");
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
}

/**
 * @brief Hook market cvar changes.
 **/
void ZMarketOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.BUY_BUTTON = FindConVar("zp_buy_button");
	
	// Hook cvars
	HookConVarChange(gCvarList.BUY_BUTTON, ZMarketOnCvarHook);
	
	// Load cvars
	ZMarketOnCvarLoad();
}

/**
 * @brief Load market listeners changes.
 **/
void ZMarketOnCvarLoad(/*void*/)
{
	// Validate buy button
	if (gCvarList.BUY_BUTTON.BoolValue)
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
		// Lock VGUI buy panel
		gCvarList.ACCOUNT_BUY_ANYWHERE.ReplicateToClient(client, "0");
		
		// Opens weapon menu
		int iD[2]; iD = MenusCommandToArray("zpistol");
		if (iD[0] != -1) SubMenu(client, iD[0]);
		
		// Sets timer for reseting command
		delete gClientData[client].BuyTimer;
		gClientData[client].BuyTimer = CreateTimer(1.0, ZMarketOnClientBuyMenu, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
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
	ZMarketOptionMenu(client);
	return Plugin_Handled;
}

/**
 * Console command callback (zp_pistols_menu)
 * @brief Opens the pistols menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketPistolsOnCommandCatched(int client, int iArguments)
{
	ZMarketMenu(client, "buy pistols", MenuType_Pistols); 
	return Plugin_Handled;
}

/**
 * Console command callback (zp_shotguns_menu)
 * @brief Opens the shotguns menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketShotgunsOnCommandCatched(int client, int iArguments)
{
	ZMarketMenu(client, "buy shotguns", MenuType_Shotguns); 
	return Plugin_Handled;
}

/**
 * Console command callback (zp_rifles_menu)
 * @brief Opens the rifles menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRiflesOnCommandCatched(int client, int iArguments)
{
	ZMarketMenu(client, "buy rifles", MenuType_Rifles); 
	return Plugin_Handled;
}

/**
 * Console command callback (zp_snipers_menu)
 * @brief Opens the snipers menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketSnipersOnCommandCatched(int client, int iArguments)
{
	ZMarketMenu(client, "buy snipers", MenuType_Snipers); 
	return Plugin_Handled;
}

/**
 * Console command callback (zp_machineguns_menu)
 * @brief Opens the machineguns menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketMachinegunsOnCommandCatched(int client, int iArguments)
{
	ZMarketMenu(client, "buy machineguns", MenuType_Machineguns); 
	return Plugin_Handled;
}

/**
 * Console command callback (zp_knifes_menu)
 * @brief Opens the knifes menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketKnifesOnCommandCatched(int client, int iArguments)
{
	ZMarketMenu(client, "buy knifes", MenuType_Knifes); 
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
	ZMarketMenu(client, "buy equipments", MenuType_Equipments); 
	return Plugin_Handled;
}

/*
 * Market functions.
 */

/**
 * @brief Creates the weapons menu.
 *
 * @param client            The client index.
 * @param sTitle            The menu title.
 * @param mSlot             (Optional) The slot index.
 * @param sType             (Optional) The class type.
 **/
void ZMarketMenu(int client, char[] sTitle, MenuType mSlot = MenuType_Equipments, char[] sType = "") 
{
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
		ClientCommand(client, "play buttons/weapon_cant_buy.wav");
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
	
	// Update class type mode
	if (hasLength(sType)) strcopy(sClass[client], sizeof(sClass[]), sType);
	
	// Initialize variables
	Action hResult; Menu hMenu = ZMarketSlotToHandle(client, mSlot); bool bMenu = (mSlot != MenuType_Rebuy); bool bRebuy = (mSlot == MenuType_Add || mSlot == MenuType_Option);

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
			FormatEx(sBuffer, sizeof(sBuffer), (WeaponsGetCost(iD)) ? "%t  %s  %t" : "%t  %s", sName, hasLength(sGroup) ? sGroup : (gClientData[client].Level < WeaponsGetLevel(iD)) ? sLevel : (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(client, iD)) ? sLimit : (fnGetPlaying() < WeaponsGetOnline(iD)) ? sOnline : "", "price", WeaponsGetCost(iD), "money");

			// Show option
			IntToString(iD, sInfo, sizeof(sInfo));
			hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((hResult == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || WeaponsValidateByID(client, iD) || gClientData[client].Level < WeaponsGetLevel(iD) || fnGetPlaying() < WeaponsGetOnline(iD) || (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(client, iD)) || (WeaponsGetCost(iD) && gClientData[client].Money < WeaponsGetCost(iD))) ? false : true));
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
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the rebuy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketMenuSlots1(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				return;
			}
		   
			// Gets menu info
			static char sBuffer[BIG_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Validate button info
			switch (iD)
			{
				// Client hit 'Add' button
				case -1 :
				{
					// Opens market menu back
					ZMarketMenu(client, "add", MenuType_Add);
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
					ZMarketMenu(client, "rebuy", MenuType_Option);
				}
			}
		}
	}
}

/**
 * @brief Called when client selects option in the rebuy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketMenuSlots2(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				ZMarketMenu(client, "rebuy", MenuType_Option);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client, false))
			{
				return;
			}
		   
			// Gets menu info
			static char sBuffer[BIG_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Gets weapon name
			WeaponsGetName(iD, sBuffer, sizeof(sBuffer));
			
			// Add index to the history
			gClientData[client].DefaultCart.Push(iD);

			// Insert weapon in the database
			DataBaseOnClientUpdate(client, ColumnType_Weapon, FactoryType_Insert, sBuffer);
			
			// Opens market menu back
			ZMarketMenu(client, "rebuy", MenuType_Option);
		}
	}
}

/**
 * @brief Called when client selects option in the rebuy menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketMenuSlots3(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Call menu
	ZMarketMenuSlots(hMenu, mAction, client, mSlot, true);
}

/**
 * @brief Called when client selects option in the shop menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketMenuSlots4(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Call menu
	ZMarketMenuSlots(hMenu, mAction, client, mSlot);
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
void ZMarketMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot, bool bRebuy = false)
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
				return;
			}
			
			// If mode already started, then stop
			if ((gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode) && !gClientData[client].Zombie) || gServerData.RoundEnd)
			{
				// Show block info
				TranslationPrintHintText(client, "buying round block");
		
				// Emit error sound
				ClientCommand(client, "play buttons/weapon_cant_buy.wav");    
				return;
			}

			// Gets menu info
			static char sBuffer[BIG_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// Validate button info
			switch (iD)
			{
				// Client hit 'Buy' button
				case -1 :
				{
					// Initialize variables
					Action hResult; int iAmount = fnGetPlaying();
					
					// i = array number
					int iSize = gClientData[client].ShoppingCart.Length;
					for (int i = 0; i < iSize; i++)
					{
						// Gets weapon id from the list
						iD = gClientData[client].ShoppingCart.Get(i);
						
						// Gets weapon data
						WeaponsGetGroup(iD, sBuffer, sizeof(sBuffer));
						
						// Access validation should be made here, because user is trying to buy all weapons without accessing a menu cases
						if ((hasLength(sBuffer) && !IsPlayerInGroup(client, sBuffer)) || WeaponsValidateByID(client, iD) || !WeaponsValidateClass(client, iD) || gClientData[client].Level < WeaponsGetLevel(iD) || iAmount < WeaponsGetOnline(iD) || (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(client, iD)) || (WeaponsGetCost(iD) && gClientData[client].Money < WeaponsGetCost(iD)))
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
											ZMarketMenu(client, "rebuy", MenuType_Rebuy);
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
								}
								
								// Return on success
								return;
							}
						}
					}
					
					// Gets weapon name
					WeaponsGetName(iD, sBuffer, sizeof(sBuffer));    
			
					// Show block info
					TranslationPrintHintText(client, "buying item block", sBuffer);
					
					// Emit error sound
					ClientCommand(client, "play buttons/weapon_cant_buy.wav");  
				}
			}
		}
	}
}

/**
 * @brief Creates a market option menu.
 *
 * @param client            The client index.
 **/
void ZMarketOptionMenu(int client)
{
	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sType[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	// Creates menu handle
	Menu hMenu = new Menu(ZMarketListMenuSlots);
	
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
public int ZMarketListMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				return;
			}

			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));

			// Opens market menu back
			ZMarketMenu(client, "rebuy", MenuType_Option, sBuffer);
		}
	}
}

/*
 * Stocks market API.
 */

/**
 * @brief Rebuys weapons if auto-rebuy is enabled and player is a human. (alive)
 *
 * @param client            The client index.
 **/
void ZMarketRebuyMenu(int client)
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
		
		// Opens rebuy menu
		ZMarketMenu(client, "rebuy", MenuType_Rebuy);
	}
}

/**
 * @brief Resets the purchase history for a client.
 * 
 * @param client            The client index.
 **/
void ZMarketResetPurchaseCount(int client)
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
 * @param mSlot             The slot index selected.
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
			// Creates menu handle
			return new Menu(ZMarketMenuSlots1);
		}
		
		// Add menu
		case MenuType_Add :
		{
			// Creates menu handle
			return new Menu(ZMarketMenuSlots2);
		}

		// Rebuy menu
		case MenuType_Rebuy :
		{
			// Boolean for reseting history
			bLock[client] = false;
		
			// Creates menu handle
			return new Menu(ZMarketMenuSlots3);
		}
		
		// Default menu
		default :
		{
			// Creates menu handle
			Menu hMenu = new Menu(ZMarketMenuSlots4);
			
			// Clear history
			if (!bLock[client]) 
			{
				ZMarketResetPurchaseCount(client);
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
 * @param mSlot             The slot index selected.
 * @param iIndex            The index variable.
 * @return                  The index amount.
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
 * @param mSlot             The slot index selected.
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