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
void ModesMenuOnCommandInit()
{
	RegAdminCmd("zp_mode_menu", ModesMenuOnCommandCatched, ADMFLAG_CONFIG, "Opens the modes menu.");
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
	if (IsClientValid(client, false))
	{
		ModesMenu(client); 
	}
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
	if (!gServerData.RoundNew)
	{
		TranslationPrintHintText(client, "block starting round");     

		EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
		return;
	}

	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	Menu hMenu = new Menu(ModesMenuSlots);
	
	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", "modes menu");

	{
		if (target != -1)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%N\n \n", target);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t\n \n", "menu empty");
		}
		
		hMenu.AddItem("-1 -1", sBuffer);
	}

	int iAlive = fnGetAlive();
	int iFlags = GetUserFlagBits(client);
	
	Action hResult;
	
	int iSize = gServerData.GameModes.Length; int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		gForwardData._OnClientValidateMode(client, i, hResult);
		
		if (hResult == Plugin_Stop)
		{
			continue;
		}
		
		ModesGetName(i, sName, sizeof(sName));
		int iMin = ModesGetMinPlayers(i);
		int iGroup = ModesGetGroupFlags(i);
		
		bool bEnabled = false;
		
		if (iGroup && !(iGroup & iFlags))
		{
			ModesGetGroup(i, sInfo, sizeof(sInfo));
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu group", sInfo);
		}
		else if (iAlive < iMin)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu online", iMin);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);
			bEnabled = true;
		}

		FormatEx(sInfo, sizeof(sInfo), "%d %d", i, (target == -1) ? -1 : GetClientUserId(target));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(bEnabled && hResult != Plugin_Handled));
	
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
 * @brief Called when client selects option in the modes menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ModesMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				if (!IsClientValid(client, false))
				{
					return 0;
				}
				
				int iD[2]; iD = MenusCommandToArray("zp_mode_menu");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsClientValid(client, false))
			{
				return 0;
			}
			
			if (!gServerData.RoundNew)
			{
				TranslationPrintHintText(client, "block starting round");
		
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}
			
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			static char sInfo[2][SMALL_LINE_LENGTH];
			ExplodeString(sBuffer, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int iD = StringToInt(sInfo[0]); int target = StringToInt(sInfo[1]);
			
			if (target != -1) // then userid should be here 
			{
				target = GetClientOfUserId(target);
				
				if (!target || !IsPlayerAlive(target))
				{
					ModesMenu(client);
					
					TranslationPrintHintText(client, "block selecting target");
			
					EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
					return 0;
				}
			}
			
			if (iD == -1)
			{
				ModesOptionMenu(client);
				return 0;
			}

			Action hResult;
			gForwardData._OnClientValidateMode(client, iD, hResult);
			
			if (hResult == Plugin_Continue || hResult == Plugin_Changed)
			{
				GameModesOnBegin(iD, target);
				
				ModesGetName(iD, sBuffer, sizeof(sBuffer));
				
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
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sInfo[SMALL_LINE_LENGTH];
	
	Menu hMenu = new Menu(ModesListMenuSlots);

	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", "modes option");

	int iAmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientValid(i))
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
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}
	
	hMenu.ExitBackButton = true;

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
				if (!IsClientValid(client, false))
				{
					return 0;
				}
			
				ModesMenu(client);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsClientValid(client, false))
			{
				return 0;
			}
			
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int target = GetClientOfUserId(StringToInt(sBuffer));

			if (target) 
			{
				ModesMenu(client, target);
			}
			else
			{
				TranslationPrintHintText(client, "block selecting target");
				
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER); 
			}
		}
	}
	
	return 0;
}