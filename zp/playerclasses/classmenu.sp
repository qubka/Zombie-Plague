/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          classmenus.sp
 *  Type:          Module 
 *  Description:   Provides functions for managing class menus.
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
 * Menu duration of the instant change.
 **/
#define MENU_TIME_INSTANT 10 

/**
 * @brief Creates commands for classes module.
 **/
void ClassMenuOnCommandInit()
{
	RegConsoleCmd("zhuman", ClassHumanOnCommandCatched, "Opens the human classes menu.");
	RegConsoleCmd("zzombie", ClassZombieOnCommandCatched, "Opens the zombie classes menu.");
	RegAdminCmd("zp_class_menu", ClassMenuOnCommandCatched, ADMFLAG_CONFIG, "Opens the classes menu.");
}

/**
 * Console command callback (zhuman)
 * @brief Opens the human classes menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ClassHumanOnCommandCatched(int client, int iArguments)
{
	if (IsPlayerExist(client, false))
	{
		ClassMenu(client, "choose humanclass", gServerData.Human, gClientData[client].HumanClassNext);
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zzombie)
 * @brief Opens the zombie classes menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ClassZombieOnCommandCatched(int client, int iArguments)
{
	if (IsPlayerExist(client, false))
	{
		ClassMenu(client, "choose zombieclass", gServerData.Zombie, gClientData[client].ZombieClassNext);
	}
	return Plugin_Handled;
}

/**
 * Console command callback (zp_class_menu)
 * @brief Opens the classes menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ClassMenuOnCommandCatched(int client, int iArguments)
{
	if (IsPlayerExist(client, false))
	{
		ClassesMenu(client);
	}
	return Plugin_Handled;
}

/*
 * Stocks class API.
 */

/**
 * @brief Validate zombie class for client availability.
 *
 * @param client            The client index.
 **/
void ZombieValidateClass(int client)
{
	int iClass = ClassValidateIndex(client, gServerData.Zombie);
	switch (iClass)
	{
		case -2 : LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache any default \"zombie\" class");
		
		case -1 : { /* < empty statement > */ }
		
		default :
		{
			gClientData[client].ZombieClassNext  = iClass;
			gClientData[client].Class = iClass;
			
			DataBaseOnClientUpdate(client, ColumnType_Zombie);
		}
	}
}

/**
 * @brief Validate human class for client availability.
 *
 * @param client            The client index.
 **/
void HumanValidateClass(int client)
{
	int iClass = ClassValidateIndex(client, gServerData.Human);
	switch (iClass)
	{
		case -2 : LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache any default \"human\" class");
		
		case -1 : { /* < empty statement > */ }
		
		default :
		{
			gClientData[client].HumanClassNext  = iClass;
			gClientData[client].Class = iClass;
			
			DataBaseOnClientUpdate(client, ColumnType_Human);
		}
	}
}

/**
 * @brief Validate class for client availability.
 *
 * @param client            The client index.
 * @param iType             The class type.
 * @return                  The class index. 
 **/
int ClassValidateIndex(int client, int iType)
{
	int iSize = gServerData.Classes.Length;

	if (IsFakeClient(client) || iSize <= gClientData[client].Class)
	{
		int iD = ClassTypeToRandomClassIndex(iType);
		if (iD == -1)
		{
			return -2;
		}
		
		gClientData[client].Class = iD;
	}
	
	int iFlags = GetUserFlagBits(client);
	
	int iGroup = ClassGetGroupFlags(gClientData[client].Class);

	if ((iGroup && !(iGroup & iFlags)) || ClassGetLevel(gClientData[client].Class) > gClientData[client].Level || ClassGetType(gClientData[client].Class) != iType)
	{
		for (int i = 0; i < iSize; i++)
		{
			iGroup = ClassGetGroupFlags(i);
			
			if (iGroup && !(iGroup & iFlags))
			{
				continue;
			}
			
			if (ClassGetType(i) != iType)
			{
				continue;
			}
			
			if (ClassGetLevel(i) > gClientData[client].Level)
			{
				continue;
			}
			
			return i;
		}
	}
	else return -1;
	
	return -2;
}

/*
 * Menu classes API.
 */

/**
 * @brief Creates the class menu.
 *
 * @param client            The client index.
 * @param sTitle            The menu title.
 * @param iType             The class type.
 * @param iClass            The current class.
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/
void ClassMenu(int client, char[] sTitle, int iType, int iClass, bool bInstant = false) 
{
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sName[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	Menu hMenu = new Menu(iType == gServerData.Zombie ? (bInstant ? ClassZombieMenuSlots2 : ClassZombieMenuSlots1) : (bInstant ? ClassHumanMenuSlots2 : ClassHumanMenuSlots1));

	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%t", sTitle);
	
	int iFlags = GetUserFlagBits(client);
	
	Action hResult;
	
	int iSize = gServerData.Classes.Length; int iAmount;
	for (int i = 0; i < iSize; i++)
	{
		if (ClassGetType(i) != iType)
		{
			continue;
		}
	
		gForwardData._OnClientValidateClass(client, i, hResult);
		
		if (hResult == Plugin_Stop)
		{
			continue;
		}

		ClassGetName(i, sName, sizeof(sName));
		int iLevel = ClassGetLevel(i);
		int iGroup = ClassGetGroupFlags(i);
		
		bool bEnabled = false;
		
		if (iGroup && !(iGroup & iFlags))
		{
			ClassGetGroup(i, sInfo, sizeof(sInfo));
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu group", sInfo);
		}
		else if (gCvarList.LEVEL_SYSTEM.BoolValue && gClientData[client].Level < iLevel)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t  %t", sName, "menu level", iLevel);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", sName);
			bEnabled = true;
		}

		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(bEnabled && hResult != Plugin_Handled && iClass != i));
	
		iAmount++;
	}
	
	if (!iAmount)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "menu empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}

	hMenu.ExitBackButton = true;

	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, bInstant ? MENU_TIME_INSTANT : MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassZombieMenuSlots1(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
   // Call menu
   return ClassMenuSlots(hMenu, mAction, "zzombie", client, mSlot);
}

/**
 * @brief Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassZombieMenuSlots2(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
   // Call menu
   return ClassMenuSlots(hMenu, mAction, "zzombie", client, mSlot, true);
}

/**
 * @brief Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassHumanMenuSlots1(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
   // Call menu
   return ClassMenuSlots(hMenu, mAction, "zhuman", client, mSlot);
}

/**
 * @brief Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassHumanMenuSlots2(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
   // Call menu
   return ClassMenuSlots(hMenu, mAction, "zhuman", client, mSlot, true);
}

/**
 * @brief Called when client selects option in the class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param sCommand          The menu command.
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/ 
int ClassMenuSlots(Menu hMenu, MenuAction mAction, char[] sCommand, int client, int mSlot, bool bInstant = false)
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
				
				int iD[2]; iD = MenusCommandToArray(sCommand);
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, bInstant))
			{
				return 0;
			}

			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);
			
			Action hResult;
			gForwardData._OnClientValidateClass(client, iD, hResult);

			if (hResult == Plugin_Continue || hResult == Plugin_Changed)
			{
				int iType = ClassGetType(iD);
				
				if (iType == gServerData.Human)
				{
					gClientData[client].HumanClassNext = iD;
					
					DataBaseOnClientUpdate(client, ColumnType_Human);
						
					if (bInstant)
					{
						ApplyOnClientUpdate(client, _, gServerData.Human);
					}
				}
				else if (iType == gServerData.Zombie)
				{
					gClientData[client].ZombieClassNext = iD;
					
					DataBaseOnClientUpdate(client, ColumnType_Zombie);
					
					if (bInstant)
					{
						ApplyOnClientUpdate(client, _, gServerData.Zombie);
					}
				}
				else 
				{
					EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
					return 0;
				}
				
				ClassGetName(iD, sBuffer, sizeof(sBuffer));
  
				if (gCvarList.MESSAGES_CLASS_CHOOSE.BoolValue) TranslationPrintToChat(client, "info class", sBuffer, ClassGetHealth(iD), ClassGetArmor(iD), ClassGetSpeed(iD));
			
				if (gCvarList.MESSAGES_CLASS_DUMP.BoolValue) 
				{
					ClassDump(client, iD);
					
					TranslationPrintToChat(client, "config dump class info");
				}
			}
		}
	}
	
	return 0;
}

/**
 * @brief Creates the classes menu. (admin)
 *
 * @param client            The client index.
 **/
void ClassesMenu(int client) 
{
	if (!gServerData.RoundStart)
	{
		TranslationPrintHintText(client, "block classes round"); 

		EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
		return;
	}
	
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sType[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	Menu hMenu = new Menu(ClassesMenuSlots);
	
	SetGlobalTransTarget(client);

	hMenu.SetTitle("%t", "classes menu");

	int iAmount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsPlayerExist(i, false))
		{
			continue;
		}

		gServerData.Types.GetString(ClassGetType(gClientData[i].Class), sType, sizeof(sType));
		
		FormatEx(sBuffer, sizeof(sBuffer), "%N [%t]", i, IsPlayerAlive(i) ? sType : "dead");

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
 * @brief Called when client selects option in the classes menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassesMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
				
				int iD[2]; iD = MenusCommandToArray("zp_class_menu");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
			
			if (!gServerData.RoundStart)
			{
				TranslationPrintHintText(client, "block using menu");
		
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}

			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int target = GetClientOfUserId(StringToInt(sBuffer));
			
			if (target)
			{
				if (!IsPlayerAlive(target))
				{
					ToolsForceToRespawn(target);
				}
				else
				{
					ClassesOptionMenu(client, target);
					return 0;
				}
			}
			else
			{
				TranslationPrintHintText(client, "block selecting target");
					
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER); 
			}

			ClassesMenu(client);
		}
	}
	
	return 0;
}

/**
 * @brief Creates a classes option menu.
 *
 * @param client            The client index.
 * @param target            The target index.
 **/
void ClassesOptionMenu(int client, int target)
{
	static char sBuffer[NORMAL_LINE_LENGTH]; 
	static char sType[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	
	Menu hMenu = new Menu(ClassesListMenuSlots);
	
	SetGlobalTransTarget(client);
	
	hMenu.SetTitle("%N", target);
	
	int iSize = gServerData.Types.Length;
	for (int i = 0; i < iSize; i++)
	{
		gServerData.Types.GetString(i, sType, sizeof(sType));
		
		FormatEx(sBuffer, sizeof(sBuffer), "%t", sType);
		
		FormatEx(sInfo, sizeof(sInfo), "%d %d", i, GetClientUserId(target));
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
 * @brief Called when client selects option in the classes option menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassesListMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
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
			
				ClassesMenu(client);
			}
		}
		
		case MenuAction_Select :
		{
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}
			
			if (!gServerData.RoundStart)
			{
				TranslationPrintHintText(client, "block using menu");
		
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
				return 0;
			}

			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			static char sInfo[2][SMALL_LINE_LENGTH];
			ExplodeString(sBuffer, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
			int iD = StringToInt(sInfo[0]); int target = GetClientOfUserId(StringToInt(sInfo[1]));

			if (target && IsPlayerAlive(target))
			{
				ApplyOnClientUpdate(target, _, iD);
				
				gServerData.Types.GetString(iD, sBuffer, sizeof(sBuffer));
				
				LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Classes, "Command", "Admin \"%N\" changed a class for Player \"%N\" to \"%s\"", client, target, sBuffer);
			}
			else
			{
				TranslationPrintHintText(client, "block selecting target");
					
				EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);  
			}
			
			ClassesMenu(client);
		}
	}
	
	return 0;
}
