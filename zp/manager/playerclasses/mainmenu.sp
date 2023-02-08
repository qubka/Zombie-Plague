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
void MainMenuOnCommandInit(/*void*/)
{
	// Create commands
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
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return Plugin_Handled;
	}
	
	// Call forward
	Action hResult;
	gForwardData._OnClientValidateButton(client, hResult);
	
	// Validate handle
	if (hResult == Plugin_Continue || hResult == Plugin_Changed)
	{
		MainMenu(client);
	}
	
	// Return on success
	return Plugin_Handled;
}

/**
 * @brief Creates a main menu.
 *
 * @param client            The client index.
 **/
void MainMenu(int client)
{
	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	// Creates menu handle
	Menu hMenu = new Menu(MainMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "main menu");
	
	// Initialize forward
	Action hResult;
	
	// i = menu index
	int iSize = gServerData.Menus.Length; int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		// Call forward
		gForwardData._OnClientValidateMenu(client, i, _, hResult);
		
		// Skip, if menu is disabled
		if (hResult == Plugin_Stop)
		{
			continue;
		}

		// Gets menu group
		MenusGetGroup(i, sName, sizeof(sName));

		// Validate access
		bool bHide = ((hasLength(sName) && !IsPlayerInGroup(client, sName)) || !MenusHasAccessByType(client, i));

		// Skip, if menu is hided
		if (bHide && MenusIsHide(i))
		{
			continue;
		}

		// Gets menu name
		MenusGetName(i, sName, sizeof(sName));

		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);

		// Show option
		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((hResult == Plugin_Handled || bHide) ? false : true));
	
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

	// Sets exit button
	hMenu.ExitButton = true;

	// Sets options and display it
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
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}

			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);
			
			// Validate access
			if (MenusHasAccessByType(client, iD)) 
			{
				// Gets menu command
				MenusGetCommand(iD, sBuffer, sizeof(sBuffer));
				
				// Validate command
				if (hasLength(sBuffer))
				{
					// Run the command
					FakeClientCommand(client, sBuffer);
				}
				else
				{
					// Opens sub menu
					SubMenu(client, iD);
				}
			}
			else
			{
				// Show block info
				TranslationPrintHintText(client, "block using menu"); 
		
				// Emit error sound
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
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}
	
	// Gets array handle of menu at given index
	ArrayList arrayMenu = gServerData.Menus.Get(iD);

	// Validate size
	int iSize = arrayMenu.Length;
	if (!(iSize - MENUS_DATA_SUBMENU))
	{
		// Opens main menu back
		MainMenu(client);
		return;
	}
	
	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	// Gets menu name
	MenusGetName(iD, sBuffer, sizeof(sBuffer));
	
	// Creates menu handle
	Menu hMenu = new Menu(SubMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", sBuffer);
	
	// Initialize forward
	Action hResult;
	
	// i = submenu index
	int iAmount;
	for (int i = MENUS_DATA_SUBMENU; i < iSize; i += MENUS_DATA_SUBMENU)
	{
		// Call forward
		gForwardData._OnClientValidateMenu(client, iD, i, hResult);
		
		// Skip, if menu is disabled
		if (hResult == Plugin_Stop)
		{
			continue;
		}
		
		// Gets menu group
		MenusGetGroup(iD, sName, sizeof(sName), i);

		// Validate access
		bool bHide = ((hasLength(sName) && !IsPlayerInGroup(client, sName)) || !MenusHasAccessByType(client, iD, i));

		// Skip, if menu is hided
		if (bHide && MenusIsHide(iD, i))
		{
			continue;
		}

		// Gets menu name
		MenusGetName(iD, sName, sizeof(sName), i);

		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);

		// Show option
		FormatEx(sInfo, sizeof(sInfo), "%d %d", iD, i);
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(hResult == Plugin_Handled || bHide ? false : true));
	
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
 * @brief Called when client selects option in the sub menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int SubMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				// Validate client
				if (!IsPlayerExist(client, false))
				{
					return 0;
				}
				
				// Opens main menu back
				MainMenu(client);
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
			static char sInfo[2][SMALL_LINE_LENGTH];
			ExplodeString(sBuffer, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int iD = StringToInt(sInfo[0]); int i = StringToInt(sInfo[1]);

			// Validate access
			if (MenusHasAccessByType(client, iD, i)) 
			{
				// Gets menu command
				MenusGetCommand(iD, sBuffer, sizeof(sBuffer), i);
				
				// Validate command
				if (hasLength(sBuffer))
				{
					// Run the command
					FakeClientCommand(client, sBuffer);
				}
			}
			else
			{
				// Show block info
				TranslationPrintHintText(client, "block using menu"); 
				
				// Emit error sound
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
			}
		}
	}
	
	return 0;
}
