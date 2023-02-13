/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          mainmenus.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing main/sub menus.
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
 * @brief Creates commands for menus module.
 **/
void MainMenuOnCommandInit()
{
	RegConsoleCmd("zmenu", MainMenuOnCommandCatched, "Opens the main menu.");
}

/**
 * Console command callback (zmenu)
 * @brief Opens the main menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MainMenuOnCommandCatched(int client, int iArguments)
{
	if (!IsPlayerExist(client, false))
	{
		return Plugin_Handled;
	}
	
	Action hResult;
	gForwardData._OnClientValidateButton(client, hResult);
	
	if (hResult == Plugin_Continue || hResult == Plugin_Changed)
	{
		MainMenu(client);
	}
	
	return Plugin_Handled;
}

/**
 * @brief Creates a main menu.
 *
 * @param client            The client index.
 **/
void MainMenu(int client)
{
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	Menu hMenu = new Menu(MainMenuSlots);
	
	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", "main menu");
	
	int iFlags = GetUserFlagBits(client);

	Action hResult;
	
	int iSize = gServerData.Menus.Length; int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		gForwardData._OnClientValidateMenu(client, i, _, hResult);
		
		if (hResult == Plugin_Stop)
		{
			continue;
		}

		int iGroup = MenusGetGroupFlags(i);
		bool bMissGroup = iGroup && !(iGroup & iFlags);
		
		bool bHidden = bMissGroup || !MenusHasAccessByType(client, i);

		if (bHidden && MenusIsHide(i))
		{
			continue;
		}

		MenusGetName(i, sName, sizeof(sName));

		if (bMissGroup)
		{
			MenusGetGroup(i, sInfo, sizeof(sInfo));
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu group", sInfo);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);
		}
		
		if (MenusIsSpace(i))
		{
			StrCat(sBuffer, sizeof(sBuffer), "\n \n");
		}
		
		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(!bHidden && hResult != Plugin_Handled));
	
		iAmount++;
	}
	
	if (!iAmount)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}

	hMenu.ExitButton = true;

	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the main menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MainMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
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
			
			if (MenusHasAccessByType(client, iD)) 
			{
				MenusGetCommand(iD, sBuffer, sizeof(sBuffer));
				
				if (hasLength(sBuffer))
				{
					FakeClientCommand(client, sBuffer);
				}
				else
				{
					SubMenu(client, iD);
				}
			}
			else
			{
				TranslationPrintHintText(client, "block using menu"); 
		
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
			}
		}
	}
	
	return 0;
}

/**
 * @brief Creates a sub menu.
 *
 * @param client            The client index.
 * @param iD                The menu index.
 **/
void SubMenu(int client, int iD)
{
	ArrayList arrayMenu = gServerData.Menus.Get(iD);

	int iSize = arrayMenu.Length;
	if (!(iSize - MENUS_DATA_SUBMENU))
	{
		MainMenu(client);
		return;
	}
	
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	MenusGetName(iD, sBuffer, sizeof(sBuffer));
	
	Menu hMenu = new Menu(SubMenuSlots);
	
	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", sBuffer);
	
	int iFlags = GetUserFlagBits(client);
	
	Action hResult;
	
	int iAmount;
	for (int i = MENUS_DATA_SUBMENU; i < iSize; i += MENUS_DATA_SUBMENU)
	{
		gForwardData._OnClientValidateMenu(client, iD, i, hResult);
		
		if (hResult == Plugin_Stop)
		{
			continue;
		}
		
		int iGroup = MenusGetGroupFlags(iD, i);
		bool bMissGroup = iGroup && !(iGroup & iFlags);

		bool bHidden = bMissGroup || !MenusHasAccessByType(client, iD, i);
		if (bHidden && MenusIsHide(iD, i))
		{
			continue;
		}

		MenusGetName(iD, sName, sizeof(sName), i);

		if (bMissGroup)
		{
			MenusGetGroup(iD, sInfo, sizeof(sInfo), i);
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu group", sInfo);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);
		}
		
		if (MenusIsSpace(iD, i))
		{
			StrCat(sBuffer, sizeof(sBuffer), "\n \n");
		}

		FormatEx(sInfo, sizeof(sInfo), "%d %d", iD, i);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(!bHidden && hResult != Plugin_Handled));
	
		iAmount++;
	}
	
	if (!iAmount)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}
	
	hMenu.ExitBackButton = true;

	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the sub menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int SubMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				
				MainMenu(client);
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
			static char sInfo[2][SMALL_LINE_LENGTH];
			ExplodeString(sBuffer, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int iD = StringToInt(sInfo[0]); int i = StringToInt(sInfo[1]);

			if (MenusHasAccessByType(client, iD, i)) 
			{
				MenusGetCommand(iD, sBuffer, sizeof(sBuffer), i);
				
				if (hasLength(sBuffer))
				{
					FakeClientCommand(client, sBuffer);
				}
			}
			else
			{
				TranslationPrintHintText(client, "block using menu"); 
				
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
			}
		}
	}
	
	return 0;
}
