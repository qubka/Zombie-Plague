/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          teleportmenu.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing teleport menu.
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
 * @brief Creates commands for Teleport module.
 **/
void TeleportMenuOnCommandInit(/*void*/)
{
	// Create commands
	RegAdminCmd("zp_ztele_menu", TeleportMenuOnCommandCatched, ADMFLAG_CONFIG, "Opens the teleport menu.");
}

/**
 * Console command callback (zp_ztele_menu)
 * @brief Opens the teleport menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action TeleportMenuOnCommandCatched(int client, int iArguments)
{
	TeleportMenu(client);
	return Plugin_Handled;
}

/**
 * @brief Creates the teleport menu.
 *
 * @param client            The client index.
 **/
void TeleportMenu(int client) 
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}
	
	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sInfo[SMALL_LINE_LENGTH];
	
	// Creates menu handle
	Menu hMenu = new Menu(TeleportMenuSlots);
	
	// Sets language to target
	SetGlobalTransTarget(client);

	// Sets donate title
	hMenu.SetTitle("%t", "teleport menu");
	
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
		hMenu.AddItem("empty", sBuffer);
	}
	
	// Sets exit and back button
	hMenu.ExitBackButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the donates menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int TeleportMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				int iD[2]; iD = MenusCommandToArray("zp_ztele_menu");
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
			int target = GetClientOfUserId(StringToInt(sBuffer));
			
			// Validate target
			if (target) 
			{
				// Get the target's name for future use
				GetClientName(target, sBuffer, sizeof(sBuffer));
				
				// Force ZSpawn on the target
				bool bSuccess = TeleportClient(target, true);
				
				// Tell admin the outcome of the action
				if (bSuccess)
				{
					TranslationPrintToChat(client, "teleport command force successful", sBuffer);
				}
				else
				{
					TranslationPrintToChat(client, "teleport command force unsuccessful", sBuffer);
				}
			}
			else
			{
				// Show block info
				TranslationPrintHintText(client, "block selecting target");
				
				// Emit error sound
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER); 
			}
			
			// Re-send the menu
			TeleportMenu(client);
		}
	}
	
	return 0;
}
