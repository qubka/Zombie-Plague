/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          modesmenu.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing modes menu.
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
 * @brief Creates commands for modes module.
 **/
void ModesMenuOnCommandInit(/*void*/)
{
	// Create commands
	RegAdminCmd("zp_mode_menu", ConfigReloadOnCommandCatched, ADMFLAG_CONFIG, "Opens the modes menu.");
}

/**
 * Console command callback (zp_mode_menu)
 * @brief Opens the modes menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ModesMenuOnCommandCatched(int client, int iArguments)
{
	ModesMenu(client); 
	return Plugin_Handled;
}

/*
 * Menu modes API.
 */

/**
 * @brief Creates a modes menu.
 *
 * @param client            The client index.
 * @param target            (Optional) The selected index.
 **/
void ModesMenu(int client, int target = -1)
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	// If mode already started, then stop 
	if (!gServerData.RoundNew)
	{
		// Show block info
		TranslationPrintHintText(client, "block starting round");     

		// Emit error sound
		EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
		return;
	}

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	static char sOnline[SMALL_LINE_LENGTH];
	static char sGroup[SMALL_LINE_LENGTH];

	// Gets amount of total alive players
	int iAlive = fnGetAlive();
	
	// Creates menu handle
	Menu hMenu = new Menu(ModesMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "modes menu");

	{
		// If there are no target, add an "(Empty)" line
		if (target != -1)
		{
			// Format some chars for showing in menu
			FormatEx(sBuffer, sizeof(sBuffer), "%N\n \n", target);
		}
		else
		{
			// Format some chars for showing in menu
			FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "empty");
		}
		
		// Show target option
		hMenu.AddItem("-1 -1", sBuffer);
	}
	
	// Initialize forward
	Action hResult;
	
	// i = array index
	int iSize = gServerData.GameModes.Length; int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		// Call forward
		gForwardData._OnClientValidateMode(client, i, hResult);
		
		// Skip, if class is disabled
		if (hResult == Plugin_Stop)
		{
			continue;
		}
		
		// Gets gamemode data
		ModesGetName(i, sName, sizeof(sName));
		ModesGetGroup(i, sGroup, sizeof(sGroup));
		
		// Format some chars for showing in menu
		FormatEx(sOnline, sizeof(sOnline), "%t", "online", ModesGetMinPlayers(i));
		FormatEx(sBuffer, sizeof(sBuffer), "%t  %s", sName, (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) ? sGroup : (iAlive < ModesGetMinPlayers(i)) ? sOnline : "");

		// Show option
		FormatEx(sInfo, sizeof(sInfo), "%d %d", i, (target == -1) ? -1 : GetClientUserId(target));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw((hResult == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup)) || iAlive < ModesGetMinPlayers(i)) ? false : true));
	
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
 * @brief Called when client selects option in the modes menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ModesMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				int iD[2]; iD = MenusCommandToArray("zp_mode_menu");
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
			
			// If mode already started, then stop
			if (!gServerData.RoundNew)
			{
				// Show block info
				TranslationPrintHintText(client, "block starting round");
		
				// Emit error sound
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}
			
			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			static char sInfo[2][SMALL_LINE_LENGTH];
			ExplodeString(sBuffer, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int iD = StringToInt(sInfo[0]); int target = StringToInt(sInfo[1]);
			if (target != -1) // then userid should be here 
			{
				/// Function returns 0 if invalid userid, then stop
				target = GetClientOfUserId(target);
				
				// Validate target
				if (!target || !IsPlayerAlive(target))
				{
					// Opens mode menu back
					ModesMenu(client);
					
					// Show block info
					TranslationPrintHintText(client, "block selecting target");
			
					// Emit error sound
					EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
					return 0;
				}
			}
			
			// Validalite list option
			if (iD == -1)
			{
				// Creates a option menu
				ModesOptionMenu(client);
				return 0;
			}

			// Call forward
			Action hResult;
			gForwardData._OnClientValidateMode(client, iD, hResult);
			
			// Validate handle
			if (hResult == Plugin_Continue || hResult == Plugin_Changed)
			{
				// Start the game mode
				GameModesOnBegin(iD, target);
				
				// Gets mode name
				ModesGetName(iD, sBuffer, sizeof(sBuffer));
				
				// Log action to game events
				LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_GameModes, "Command", "Admin \"%N\" started a gamemode: \"%s\"", client, sBuffer);
			}
		}
	}
	
	return 0;
}

/**
 * @brief Creates a modes option menu.
 *
 * @param client            The client index.
 **/
void ModesOptionMenu(int client)
{
	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sInfo[SMALL_LINE_LENGTH];
	
	// Creates menu handle
	Menu hMenu = new Menu(ModesListMenuSlots);

	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "modes option");

	// i = client index
	int iAmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if (!IsPlayerExist(i))
		{
			continue;
		}

		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%N", i);

		// Show option
		IntToString(GetClientUserId(i), sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer);

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
 * @brief Called when client selects option in the modes option menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ModesListMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				// Opens modes menu back
				ModesMenu(client);
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
			int target = GetClientOfUserId(StringToInt(sBuffer));

			// Validate target
			if (target) 
			{
				// Opens modes menu back with selected index
				ModesMenu(client, target);
			}
			else
			{
				// Show block info
				TranslationPrintHintText(client, "block selecting target");
				
				// Emit error sound
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER); 
			}
		}
	}
	
	return 0;
}