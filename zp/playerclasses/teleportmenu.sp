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
void TeleportMenuOnCommandInit()
{
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
	if (IsPlayerExist(client, false))
	{
		TeleportMenu(client);
	}
	return Plugin_Handled;
}

/**
 * @brief Creates the teleport menu.
 *
 * @param client            The client index.
 **/
void TeleportMenu(int client) 
{
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sInfo[SMALL_LINE_LENGTH];
	
	Menu hMenu = new Menu(TeleportMenuSlots);
	
	SetGlobalTransTarget(client);

	hMenu.SetTitle("%t", "teleport menu");
	
	int iAmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsPlayerExist(i))
		{
			continue;
		}

		FormatEx(sBuffer, sizeof(sBuffer), "%N", i);

		IntToString(GetClientUserId(i), sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer);

		iAmount++;
	}
	
	if (!iAmount)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer);
	}
	
	hMenu.ExitBackButton = true;

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
				
				int iD[2]; iD = MenusCommandToArray("zp_ztele_menu");
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
			int target = GetClientOfUserId(StringToInt(sBuffer));
			
			if (target) 
			{
				GetClientName(target, sBuffer, sizeof(sBuffer));
				
				bool bSuccess = TeleportClient(target, true);

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
				TranslationPrintHintText(client, "block selecting target");
				
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER); 
			}
			
			TeleportMenu(client);
		}
	}
	
	return 0;
}
