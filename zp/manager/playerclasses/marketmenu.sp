/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          marketmenu.sp
 *  Type:          Module
 *  Description:   Provides functions for managing market menu.
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
 * @brief Creates commands for market module.
 **/
void MarketMenuOnCommandInit(/*void*/)
{
	// Create commands
	RegConsoleCmd("zfavor", MarketMenuFavorOnCommandCatched, "Opens the favorites menu.");
	RegConsoleCmd("zmarket ", MarketMenuBuyOnCommandCatched, "Opens the market menu.");
}

/**
 * Console command callback (zfavor)
 * @brief Opens the favorites menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MarketMenuFavorOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.MARKET.BoolValue && gCvarList.MARKET_FAVORITES.BoolValue)
	{
		MarketEditMenu(client);
	}
	return Plugin_Handled;
}

/**
 * Console command callback (market)
 * @brief Opens the pistols menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MarketMenuBuyOnCommandCatched(int client, int iArguments)
{
	// Validate menu
	if (gCvarList.MARKET.BoolValue)
	{
		MarketMenu(client);
	}
	return Plugin_Handled;
}

/*
 * Market functions.
 */

/**
 * @brief Creates a buy menu.
 *
 * @param client            The client index.
 * @param target            (Optional) The selected index.
 **/
void MarketMenu(int client)
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}
	
	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	// Creates sections menu handle
	Menu hMenu = new Menu(MarketMenuSlots);

	// Sets language to target
	SetGlobalTransTarget(client);

	// Is favorites menu enabled ?
	if (gCvarList.MARKET_FAVORITES.BoolValue)
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "market favorites menu");
		
		// Show add option
		hMenu.AddItem("-1", sBuffer);
	}

	// i = array index
	int iSize = gServerData.Sections.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets section name
		gServerData.Sections.GetString(i, sBuffer, sizeof(sBuffer));

		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", sBuffer);

		// Show option
		IntToString(i, sInfo, sizeof(sInfo));
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
 * @brief Called when client selects option in the market menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MarketMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				int iD[2]; iD = MenusCommandToArray("market ");
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
				// Client hit 'Favorite' button
				case -1 :
				{
					// Opens edit menu 
					MarketEditMenu(client);
				}
				
				// Client hit 'Section' button
				default :
				{
					// Gets section name
					gServerData.Sections.GetString(iD, sBuffer, sizeof(sBuffer));

					// Opens buy menu at given section
					MarketBuyMenu(client, iD, sBuffer);
				}
			}
		}
	}
	
	return 0;
}

/**
 * @brief Creates the buy menu.
 *
 * @param client            The client index.
 * @param sTitle            (Optional) The menu title.
 * @param mSection          (Optional) The section index.
 * @param sType             (Optional) The class type.
 **/
void MarketBuyMenu(int client, int mSection = MenuType_Buy, char[] sTitle = "market favorites menu", char[] sType = "") 
{
	// Initialize variables
	bool bMenu = (mSection != MenuType_FavBuy); bool bEdit = (mSection == MenuType_FavAdd || mSection == MenuType_FavEdit);
	
	// Validate menu
	if (!bMenu && !gCvarList.MARKET_FAVORITES.BoolValue)
	{
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
	Action hResult; Menu hMenu = MarketSectionToHandle(mSection);

	// Sets language to target
	SetGlobalTransTarget(client);

	// Switch section
	switch (mSection)
	{
		case MenuType_FavEdit :
		{
			// Format some chars for showing in menu
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "market add");
			
			// Show add option
			hMenu.AddItem("-1", sBuffer);
		}
		
		case MenuType_FavBuy :
		{
			// Format some chars for showing in menu
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "market buy all");
			
			// Show add option
			hMenu.AddItem("-1", sBuffer);
		}
	}
	
	// Format title for showing in menu
	FormatEx(sBuffer, sizeof(sBuffer), "%t", bEdit && hasLength(sClass[client]) ? sClass[client] : sTitle);

	// Sets title
	hMenu.SetTitle(sBuffer);

	// i = array number
	int iSize = MarketSectionToCount(client, mSection); int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		// Gets item id from the list
		int iD = MarketSectionToIndex(client, mSection, i);

		// Validate add/option menu
		if (bEdit)
		{
			// Skip some items, if class isn't equal
			if (!ItemsValidateByClass(iD, sClass[client]))
			{
				continue;
			}

			// Gets item data
			ItemsGetName(iD, sName, sizeof(sName));

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
			gForwardData._OnClientValidateExtraItem(client, iD, hResult);
			
			// Skip, if item is disabled
			if (hResult == Plugin_Stop)
			{
				continue;
			}
			
			// Skip some items, if section isn't equal
			if (bMenu && ItemsGetSectionID(iD) != mSection) 
			{
				continue;
			}
			
			// Skip some items, if class isn't equal
			if (!ItemsValidateClass(client, iD))
			{
				continue;
			}    

			// Gets item data
			ItemsGetName(iD, sName, sizeof(sName));
			ItemsGetGroup(iD, sGroup, sizeof(sGroup));
			int weaponID = ItemsGetWeaponID(iD);
			
			// Format some chars for showing in menu
			FormatEx(sLevel, sizeof(sLevel), "%t", "level", ItemsGetLevel(iD));
			FormatEx(sLimit, sizeof(sLimit), "%t", "limit", ItemsGetLimit(iD));
			FormatEx(sOnline, sizeof(sOnline), "%t", "online", ItemsGetOnline(iD));      
			FormatEx(sBuffer, sizeof(sBuffer), (ItemsGetCost(iD)) ? "%t  %s  %t" : "%t  %s", sName, hasLength(sGroup) ? sGroup : (gClientData[client].Level < ItemsGetLevel(iD)) ? sLevel : (ItemsGetLimit(iD) && ItemsGetLimit(iD) <= ItemsGetLimits(client, iD)) ? sLimit : (iPlaying < ItemsGetOnline(iD)) ? sOnline : "", "price", ItemsGetCost(iD), "money");

			// Show option
			IntToString(iD, sInfo, sizeof(sInfo));
			hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((hResult == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || (weaponID != -1 && WeaponsValidateByID(client, weaponID)) || gClientData[client].Level < ItemsGetLevel(iD) || iPlaying < ItemsGetOnline(iD) || (ItemsGetLimit(iD) && ItemsGetLimit(iD) <= ItemsGetLimits(client, iD)) || (ItemsGetCost(iD) && gClientData[client].Money < ItemsGetCost(iD))) ? false : true));
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
 * @brief Called when client selects option in the favorites menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MarketBuyMenuSlots1(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				MarketMenu(client);
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
					MarketBuyMenu(client, MenuType_FavAdd, "market add");
				}
				
				// Client hit 'Item' button
				default :
				{
					// Validate index
					int iIndex = gClientData[client].DefaultCart.FindValue(iD);
					if (iIndex != -1)
					{
						// Remove index from the history
						gClientData[client].DefaultCart.Erase(iIndex);
					}
					
					// Gets item name
					ItemsGetName(iD, sBuffer, sizeof(sBuffer));
					
					// Remove item from the database
					DataBaseOnClientUpdate(client, ColumnType_Items, FactoryType_Delete, sBuffer);
					
					// Opens market menu back
					MarketBuyMenu(client, MenuType_FavEdit);
				}
			}
		}
	}
	
	return 0;
}

/**
 * @brief Called when client selects option in the favorites menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MarketBuyMenuSlots2(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				MarketBuyMenu(client, MenuType_FavEdit);
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

			// Gets item name
			ItemsGetName(iD, sBuffer, sizeof(sBuffer));
			
			// Add index to the history
			gClientData[client].DefaultCart.Push(iD);

			// Insert item in the database
			DataBaseOnClientUpdate(client, ColumnType_Items, FactoryType_Insert, sBuffer);
			
			// Opens market menu back
			MarketBuyMenu(client, MenuType_FavEdit);
		}
	}
	
	return 0;
}

/**
 * @brief Called when client selects option in the favorites menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MarketBuyMenuSlots3(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Call menu
	return MarketBuyMenuSlots(hMenu, mAction, client, mSlot, true);
}

/**
 * @brief Called when client selects option in the shop menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MarketBuyMenuSlots4(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Call menu
	return MarketBuyMenuSlots(hMenu, mAction, client, mSlot);
}

/**
 * @brief Called when client selects option in the shop menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bFavorites        (Optional) True to set the favorites mode, false to set normal mode.
 **/ 
int MarketBuyMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot, bool bFavorites = false)
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
				MarketMenu(client);
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
			
			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			// If item/weapon is not available during gamemode, then stop
			if (gServerData.RoundStart && !(ItemsGetWeaponID(iD) != -1 ? ModesIsWeapon(gServerData.RoundMode) : ModesIsExtraItem(gServerData.RoundMode)) || (gServerData.RoundEnd && gClientData[client].Zombie))
			{
				// Show block info
				TranslationPrintHintText(client, "block buying round");
		
				// Emit error sound
				EmitSoundToClient(client, SOUND_WEAPON_CANT_BUY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}

			// Validate button info
			switch (iD)
			{
				// Client hit 'Buy all' button
				case -1 :
				{
					// Initialize variables
					Action hResult; int iPlaying = fnGetPlaying();
					
					// i = array number
					int iSize = gClientData[client].ShoppingCart.Length;
					for (int i = 0; i < iSize; i++)
					{
						// Gets item id from the list
						iD = gClientData[client].ShoppingCart.Get(i);
						
						// Gets item data
						ItemsGetGroup(iD, sBuffer, sizeof(sBuffer));
						int weaponID = ItemsGetWeaponID(iD);
						
						// Access validation should be made here, because user is trying to buy all weapons without accessing a menu cases
						if ((hasLength(sBuffer) && !IsPlayerInGroup(client, sBuffer)) || (weaponID != -1 && WeaponsValidateByID(client, weaponID)) || !ItemsValidateClass(client, iD) || gClientData[client].Level < ItemsGetLevel(iD) || iPlaying < ItemsGetOnline(iD) || (ItemsGetLimit(iD) && ItemsGetLimit(iD) <= ItemsGetLimits(client, iD)) || (ItemsGetCost(iD) && gClientData[client].Money < ItemsGetCost(iD)))
						{
							continue;
						}
						
						// Call forward
						gForwardData._OnClientValidateExtraItem(client, iD, hResult);
						
						// Validate handle
						if (hResult == Plugin_Continue || hResult == Plugin_Changed)
						{
							// Give weapon for the player
							WeaponsGive(client, weaponID);

							// If item has a cost
							if (ItemsGetCost(iD))
							{
								// Remove money and store it for returning if player will be first zombie
								AccountSetClientCash(client, gClientData[client].Money - ItemsGetCost(iD));
								gClientData[client].LastPurchase += ItemsGetCost(iD);
							}
							
							// If item has a limit
							if (ItemsGetLimit(iD))
							{
								// Increment count
								ItemsSetLimits(client, iD, ItemsGetLimits(client, iD) + 1);
							}
							
							// Call forward
							gForwardData._OnClientBuyExtraItem(client, iD); /// Buy item

							// Remove index from the history
							gClientData[client].ShoppingCart.Erase(i);
							
							// Subtract one from count
							iSize--;

							// Backtrack one index, because we deleted it out from under the loop
							i--;
						}
					}
				}
				
				// Client hit 'Item' button
				default :
				{
					// Call forward
					Action hResult; 
					gForwardData._OnClientValidateExtraItem(client, iD, hResult);
					
					// Validate handle
					if (hResult == Plugin_Continue || hResult == Plugin_Changed)
					{
						// Gets item data
						int weaponID = ItemsGetWeaponID(iD);		
					
						// Validate access
						if ((weaponID == -1 || !WeaponsValidateByID(client, weaponID)) && ItemsValidateClass(client, iD))
						{
							// Give weapon for the player
							WeaponsGive(client, weaponID);

							// If item has a cost
							if (ItemsGetCost(iD))
							{
								// Remove money and store it for returning if player will be first zombie
								AccountSetClientCash(client, gClientData[client].Money - ItemsGetCost(iD));
								gClientData[client].LastPurchase += ItemsGetCost(iD);
							}
							
							// If item has a limit
							if (ItemsGetLimit(iD))
							{
								// Increment count
								ItemsSetLimits(client, iD, ItemsGetLimits(client, iD) + 1);
							}

							// Is it favorites menu ?
							if (bFavorites)
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
										MarketBuyMenu(client, MenuType_FavBuy);
									}
								}
							}
							else
							{
								// If help messages enabled, then show info
								if (gCvarList.MESSAGES_ITEM_ALL.BoolValue)
								{
									// Gets client name
									static char sInfo[SMALL_LINE_LENGTH];
									GetClientName(client, sInfo, sizeof(sInfo));

									// Gets item name
									ItemsGetName(iD, sBuffer, sizeof(sBuffer));    
									
									// Show item buying info
									TranslationPrintToChatAll("info buy", sInfo, sBuffer);
								}
								
								// If help messages enabled, then show info
								if (gCvarList.MESSAGES_ITEM_INFO.BoolValue)
								{
									// Gets item info
									ItemsGetInfo(iD, sBuffer, sizeof(sBuffer));
									
									// Show item personal info
									if (hasLength(sBuffer)) TranslationPrintHintText(client, sBuffer);
								}
								
								// If reopen enabled, then opens menu back
								if (gCvarList.MARKET_REOPEN.BoolValue)
								{
									// Reopen menu
									MarketBuyMenu(client, ItemsGetSectionID(iD));
								}
							}
														
							// Call forward
							gForwardData._OnClientBuyExtraItem(client, iD); /// Buy item
							
							// Return on success
							return 0;
						}
					}
					
					// Gets item name
					ItemsGetName(iD, sBuffer, sizeof(sBuffer));    
			
					// Show block info
					TranslationPrintHintText(client, "block buying item", sBuffer);
					
					// Emit error sound
					EmitSoundToClient(client, SOUND_WEAPON_CANT_BUY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);  
				}
			}
		}
	}
	
	return 0;
}

/*
 * Edit menu.
 */

/**
 * @brief Creates a market edit menu.
 *
 * @param client            The client index.
 **/
void MarketEditMenu(int client)
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
	Menu hMenu = new Menu(MarketEditMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "market favorites menu");

	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "market buy");
		
		// Show buy option
		hMenu.AddItem("", sBuffer);
	}
	
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
public int MarketEditMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				MarketMenu(client);
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

			// Client hit 'Type' button
			if (hasLength(sBuffer))
			{
				// Opens market menu back
				MarketBuyMenu(client, MenuType_FavEdit, _, sBuffer);
			}
			// Client hit 'Buy' button
			else
			{
				// Resets shopping cart for client
				MarketResetShoppingCart(client); 
				
				// Validate cart size
				if (gClientData[client].DefaultCart.Length)
				{
					// Opens favorites menu
					MarketBuyMenu(client, MenuType_FavBuy);
				}
			}
		}
	}
	
	return 0;
}


/**
 * @brief Find the handle at which the section is at.
 * 
 * @param mSection          The section index.
 * @return                  The menu handle.
 **/
Menu MarketSectionToHandle(int mSection)
{
	switch (mSection)
	{
		case MenuType_FavEdit :
		{
			return new Menu(MarketBuyMenuSlots1);
		}
		
		case MenuType_FavAdd :
		{
			return new Menu(MarketBuyMenuSlots2);
		}

		case MenuType_FavBuy :
		{
			return new Menu(MarketBuyMenuSlots3);
		}

		default :
		{
			return new Menu(MarketBuyMenuSlots4);
		}
	}
}

/**
 * @brief Find the index at which the section is at.
 * 
 * @param client            The client index.
 * @param mSection          The section index.
 * @param iIndex            The id variable.
 * @return                  The index variable.
 **/
int MarketSectionToIndex(int client, int mSection, int iIndex)
{
	switch (mSection)
	{
		case MenuType_FavEdit :
		{
			return gClientData[client].DefaultCart.Get(iIndex);
		}

		case MenuType_FavBuy :
		{
			return gClientData[client].ShoppingCart.Get(iIndex);
		}

		default :
		{
			return iIndex;
		}
	}
}

/**
 * @brief Find the count at which the section is at.
 * 
 * @param client            The client index.
 * @param mSection          The section index.
 * @return                  The amount variable.
 **/
int MarketSectionToCount(int client, int mSection)
{
	switch (mSection)
	{
		case MenuType_FavEdit :
		{
			return gClientData[client].DefaultCart.Length;
		}
   
		case MenuType_FavBuy :
		{
			return gClientData[client].ShoppingCart.Length;
		}

		// Default menu
		default :
		{
			return gServerData.ExtraItems.Length;
		}
	}
}