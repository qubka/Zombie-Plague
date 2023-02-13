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
void MarketMenuOnCommandInit()
{
	RegConsoleCmd("zfavor", MarketMenuFavorOnCommandCatched, "Opens the favorites menu.");
	RegConsoleCmd("zmarket", MarketMenuBuyOnCommandCatched, "Opens the market menu.");
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
	if (gCvarList.MARKET.BoolValue && gCvarList.MARKET_FAVORITES.BoolValue)
	{
		MarketEditMenu(client);
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zmarket)
 * @brief Opens the pistols menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MarketMenuBuyOnCommandCatched(int client, int iArguments)
{
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
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	if (MarketIsBuyTimeExpired(client) && (gClientData[client].Zombie && !gCvarList.MARKET_ZOMBIE_OPEN_ALL.BoolValue || !gClientData[client].Zombie && !gCvarList.MARKET_HUMAN_OPEN_ALL.BoolValue))
	{
		int iD = gServerData.Sections.Length - 1;
		
		gServerData.Sections.GetString(iD, sBuffer, sizeof(sBuffer));

		MarketBuyMenu(client, iD, sBuffer);
		return;
	} 
	
	Menu hMenu = new Menu(MarketMenuSlots);

	SetGlobalTransTarget(client);

	if (gCvarList.MARKET_FAVORITES.BoolValue)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "market favorites menu");
		hMenu.AddItem("-1", sBuffer);
	}

	int iSize = gServerData.Sections.Length;
	for (int i = 0; i < iSize; i++)
	{
		gServerData.Sections.GetString(i, sBuffer, sizeof(sBuffer));

		FormatEx(sBuffer, sizeof(sBuffer), "%t", sBuffer);

		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(MarketIsBuyTimeExpired(client, i) ? false : true));
	}
	
	if (!iSize)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}

	hMenu.ExitBackButton = true;

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
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				int iD[2]; iD = MenusCommandToArray("zmarket");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
			
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			switch (iD)
			{
				case -1 :
				{
					MarketEditMenu(client);
				}
				
				default :
				{
					if (MarketIsBuyTimeExpired(client, iD))
					{
						TranslationPrintHintText(client, "block buying round");
				
						EmitSoundToClient(client, SOUND_WEAPON_CANT_BUY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
						return 0;
					}
				
					gServerData.Sections.GetString(iD, sBuffer, sizeof(sBuffer));

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
 * @param iType             (Optional) The class type.
 **/
void MarketBuyMenu(int client, int mSection = MenuType_Buy, char[] sTitle = "market favorites menu", int iType = -1) 
{
	bool bMenu = (mSection != MenuType_FavBuy); bool bEdit = (mSection == MenuType_FavAdd || mSection == MenuType_FavEdit);

	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	static int iTypes[MAXPLAYERS+1];

	if (iType != -1) 
	{
		iTypes[client] = iType;
	}
	else
	{
		iType = iTypes[client];
	}
	
	Action hResult; Menu hMenu = MarketSectionToHandle(mSection);

	SetGlobalTransTarget(client);

	switch (mSection)
	{
		case MenuType_FavEdit :
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "market add");
			hMenu.AddItem("-1", sBuffer);
		}
		
		case MenuType_FavBuy :
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "market buy all");
			hMenu.AddItem("-1", sBuffer);
		}
	}
	
	if (bEdit && iType != -1)
	{
		gServerData.Types.GetString(iType, sTitle, SMALL_LINE_LENGTH);
	}

	hMenu.SetTitle("%t", sTitle);
	
	int iPlaying = fnGetPlaying();
	int iFlags = GetUserFlagBits(client);
	
	int iSize = MarketSectionToCount(client, mSection); int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		int iD = MarketSectionToIndex(client, mSection, i);

		if (bEdit)
		{
			if (!ClassHasTypeBits(ItemsGetTypes(iD), iType))
			{
				continue;
			}

			ItemsGetName(iD, sName, sizeof(sName));

			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);

			IntToString(iD, sInfo, sizeof(sInfo));
			hMenu.AddItem(sInfo, sBuffer);
		}
		else
		{
			if (!ItemsHasAccessByType(client, iD))
			{
				continue;
			}    
			
			if (bMenu && ItemsGetSectionID(iD) != mSection) 
			{
				continue;
			}

			gForwardData._OnClientValidateExtraItem(client, iD, hResult);
			
			if (hResult == Plugin_Stop)
			{
				continue;
			}

			ItemsGetName(iD, sName, sizeof(sName));
			int iCost = ItemsGetCost(iD);
			int iLevel = ItemsGetLevel(iD);
			int iLimit = ItemsGetLimit(iD);
			int iOnline = ItemsGetOnline(iD);
			int iWeapon = ItemsGetWeaponID(iD);
			int iGroup = ItemsGetGroupFlags(iD);
			
			bool bEnabled = false;
			
			if (iGroup && !(iGroup & iFlags))
			{
				ItemsGetGroup(iD, sInfo, sizeof(sInfo));
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu group", sInfo);
			}
			else if (gCvarList.LEVEL_SYSTEM.BoolValue && gClientData[client].Level < iLevel)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu level", iLevel);
			}
			else if ((ItemsGetFlags(iD) & ADMFLAG_CUSTOM1) && ItemsGetMapLimits(client, iD))
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t*", sName, "menu limit", 1);
			}
			else if (iLimit && iLimit <= ItemsGetLimits(client, iD))
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu limit", iLimit);
			}
			else if (iPlaying < iOnline)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu online", iOnline);    
			}
			else if (gClientData[client].Money < iCost)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu price", iCost, "menu money");
			}
			else if (iWeapon != -1 && WeaponsFindByID(client, iWeapon) != -1)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu weapon");    
			}
			else if (iCost)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu price", iCost, "menu money");
				bEnabled = true;
			}
			else
			{
				FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);
				bEnabled = true;
			}

			IntToString(iD, sInfo, sizeof(sInfo));
			hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(bEnabled && hResult != Plugin_Handled && !MarketIsBuyTimeExpired(client, ItemsGetSectionID(iD)) && !ItemHasFlags(client, iD)));
		}
		
		iAmount++;
	}
	
	if (!iAmount)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}
	
	hMenu.ExitBackButton = true;

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
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				if (MarketIsBuyTimeExpired(client) && (gClientData[client].Zombie && !gCvarList.MARKET_ZOMBIE_OPEN_ALL.BoolValue || !gClientData[client].Zombie && !gCvarList.MARKET_HUMAN_OPEN_ALL.BoolValue))
				{
					int iD[2]; iD = MenusCommandToArray("zmarket");
					if (iD[0] != -1) SubMenu(client, iD[0]);
				}
				else
				{
					MarketMenu(client);
				}
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
		   
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			switch (iD)
			{
				case -1 :
				{
					MarketBuyMenu(client, MenuType_FavAdd, "market add");
				}
				
				default :
				{
					int iIndex = gClientData[client].DefaultCart.FindValue(iD);
					if (iIndex != -1)
					{
						gClientData[client].DefaultCart.Erase(iIndex);
					}
					
					ItemsGetName(iD, sBuffer, sizeof(sBuffer));
					
					DataBaseOnClientUpdate(client, ColumnType_Items, FactoryType_Delete, sBuffer);
					
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
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				if (!IsPlayerExist(client, false))
				{
					return 0;
				}
			
				MarketBuyMenu(client, MenuType_FavEdit);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
		   
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			ItemsGetName(iD, sBuffer, sizeof(sBuffer));
			
			gClientData[client].DefaultCart.Push(iD);

			DataBaseOnClientUpdate(client, ColumnType_Items, FactoryType_Insert, sBuffer);
			
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
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				MarketMenu(client);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client))
			{
				return 0;
			}

			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			switch (iD)
			{
				case -1 :
				{
					int iSize = gClientData[client].ShoppingCart.Length;
					for (int i = 0; i < iSize; i++)
					{
						iD = gClientData[client].ShoppingCart.Get(i);

						if (MarketBuyItem(client, iD, false))
						{
							gClientData[client].ShoppingCart.Erase(i);
							
							iSize--;

							i--;
						}
					}
				}
				
				default :
				{
					if (MarketBuyItem(client, iD))
					{
						if (bFavorites)
						{
							int iIndex = gClientData[client].ShoppingCart.FindValue(iD);
							if (iIndex != -1)
							{
								gClientData[client].ShoppingCart.Erase(iIndex);

								if (gClientData[client].ShoppingCart.Length)
								{
									MarketBuyMenu(client, MenuType_FavBuy);
								}
							}
						}
						else
						{
							switch (gCvarList.MARKET_REOPEN.IntValue)
							{
								case 1 : { MarketBuyMenu(client, ItemsGetSectionID(iD)); }
								case 2 : { MarketMenu(client); }
								default : { /* < empty statement > */ }
							}
						}
					}
					else
					{
						ItemsGetName(iD, sBuffer, sizeof(sBuffer));    
				
						TranslationPrintHintText(client, "block buying item", sBuffer);
						
						EmitSoundToClient(client, SOUND_WEAPON_CANT_BUY, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);  
					}
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
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sType[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	Menu hMenu = new Menu(MarketEditMenuSlots);
	
	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", "market favorites menu");

	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "market buy");
		hMenu.AddItem("-1", sBuffer);
	}
	
	int iSize = gServerData.Types.Length;
	for (int i = 0; i < iSize; i++)
	{
		gServerData.Types.GetString(i, sType, sizeof(sType));
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t", sType);
		
		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer);
	}
	
	if (!iSize)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}
	
	hMenu.ExitBackButton = true;

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
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				MarketMenu(client);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}

			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);

			switch (iD)
			{
				case -1 :
				{
					MarketResetShoppingCart(client); 
					
					if (gClientData[client].DefaultCart.Length)
					{
						MarketBuyMenu(client, MenuType_FavBuy);
					}
				}
				
				default :
				{
					MarketBuyMenu(client, MenuType_FavEdit, _, iD);
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
 * @param iD                The id variable.
 * @return                  The index variable.
 **/
int MarketSectionToIndex(int client, int mSection, int iD)
{
	switch (mSection)
	{
		case MenuType_FavEdit :
		{
			return gClientData[client].DefaultCart.Get(iD);
		}

		case MenuType_FavBuy :
		{
			return gClientData[client].ShoppingCart.Get(iD);
		}

		default :
		{
			return iD;
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

		default :
		{
			return gServerData.ExtraItems.Length;
		}
	}
}
