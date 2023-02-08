/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          configmenu.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing config menu.
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
 * @brief Creates commands for config module.
 **/
void ConfigMenuOnCommandInit(/*void*/)
{
	// Hook commands
	RegAdminCmd("zp_config_menu", ConfigMenuOnCommandCatched, ADMFLAG_CONFIG, "Opens the configs menu.");
}

/**
 * Console command callback (zp_config_menu)
 * @brief Opens the config menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ConfigMenuOnCommandCatched(int client, int iArguments)
{
	ConfigMenu(client);
	return Plugin_Handled;
}

/**
 * @brief Creates the reload configs menu.
 *
 * @param client            The client index.
 **/
void ConfigMenu(int client) 
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sAlias[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	// Creates menu handle
	Menu hMenu = new Menu(ConfigMenuSlots);

	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "configs menu");
	
	// i = config file entry index
	for (int i = File_Cvars; i < File_Size; i++)
	{
		// Gets config alias
		ConfigGetConfigAlias(i, sAlias, sizeof(sAlias));
		
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "config menu reload", sAlias);
		
		// Show option
		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer);
	}
	
	// If there are no cases, add an "(Empty)" line
	/*if (!iSize)
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}*/
	
	// Sets exit and back button
	hMenu.ExitBackButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the config menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ConfigMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				int iD[2]; iD = MenusCommandToArray("zp_config_menu");
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
			
			// Gets config alias
			ConfigGetConfigAlias(iD, sBuffer, sizeof(sBuffer));
			
			// Reloads config file
			bool bSuccessful = ConfigReloadConfig(iD);
			
			// Validate load
			if (bSuccessful)
			{
				TranslationPrintToChat(client, "config reload finish", sBuffer);
			}
			else
			{
				TranslationPrintToChat(client, "config reload falied", sBuffer);
			}
			
			// Log action to game events
			LogEvent(true, _, _, _, "Command", "Admin \"%N\" reloaded all config files", client);
			
			// Opens config menu back
			ConfigMenu(client);
		}
	}
	
	return 0;
}
