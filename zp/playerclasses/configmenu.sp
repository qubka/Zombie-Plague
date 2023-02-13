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
void ConfigMenuOnCommandInit()
{
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
	if (IsPlayerExist(client, false))
	{
		ConfigMenu(client);
	}
	return Plugin_Handled;
}

/**
 * @brief Creates the reload configs menu.
 *
 * @param client            The client index.
 **/
void ConfigMenu(int client) 
{
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	Menu hMenu = new Menu(ConfigMenuSlots);

	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", "configs menu");
	
	for (int i = File_Cvars; i < File_Size; i++)
	{
		ConfigGetConfigAlias(i, sInfo, sizeof(sInfo));
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "config menu reload", sInfo);
		
		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer);
	}
	
	/*if (!iSize)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}*/
	
	hMenu.ExitBackButton = true;

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
				
				int iD[2]; iD = MenusCommandToArray("zp_config_menu");
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
			
			ConfigGetConfigAlias(iD, sBuffer, sizeof(sBuffer));
			
			bool bSuccessful = ConfigReloadConfig(iD);

			if (bSuccessful)
			{
				TranslationPrintToChat(client, "config reload finish", sBuffer);
			}
			else
			{
				TranslationPrintToChat(client, "config reload falied", sBuffer);
			}
			
			LogEvent(true, _, _, _, "Command", "Admin \"%N\" reloaded all config files", client);
			
			ConfigMenu(client);
		}
	}
	
	return 0;
}
