/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          menus.sp
 *  Type:          Manager 
 *  Description:   Menus constructor.
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
 * @section Menu config data indexes.
 **/
enum
{
	MENUS_DATA_NAME,
	MENUS_DATA_GROUP,
	MENUS_DATA_TYPES,
	MENUS_DATA_HIDE,
	MENUS_DATA_COMMAND,
	MENUS_DATA_SUBMENU
};
/**
 * @endsection
 **/
 
/*
 * Load other menus modules
 */
#include "zp/manager/playerclasses/mainmenu.sp"

/**
 * @brief Prepare all menu data.
 **/
void MenusOnLoad(/*void*/)
{
	// Register config file
	ConfigRegisterConfig(File_Menus, Structure_KeyValue, CONFIG_FILE_ALIAS_MENUS);

	// Gets menus config path
	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_MENUS, sBuffer, sizeof(sBuffer));

	// If file doesn't exist, then log and stop
	if (!bExists)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Missing menus config file: \"%s\"", sBuffer);
		return;
	}

	// Sets path to the config file
	ConfigSetConfigPath(File_Menus, sBuffer);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_Menus, gServerData.Menus);

	// Unexpected error, stop plugin
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error encountered loading: \"%s\"", sBuffer);
		return;
	}

	// Now copy data to array structure
	MenusOnCacheData();

	// Sets config data
	ConfigSetConfigLoaded(File_Menus, true);
	ConfigSetConfigReloadFunc(File_Menus, GetFunctionByName(GetMyHandle(), "MenusOnConfigReload"));
	ConfigSetConfigHandle(File_Menus, gServerData.Menus);
}

/**
 * @brief Caches menu data from file into arrays.
 **/
void MenusOnCacheData(/*void*/)
{
	// Gets config file path
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Menus, sBuffer, sizeof(sBuffer));

	// Opens config
	KeyValues kvMenus;
	bool bSuccess = ConfigOpenConfigFile(File_Menus, kvMenus);

	// Validate config
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error caching data from menus config file: \"%s\"", sBuffer);
		return;
	}

	// Validate size
	int iSize = gServerData.Menus.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "No usable data found in menus config file: \"%s\"", sBuffer);
		return;
	}
	
	// i = array index
	for (int i = 0; i < iSize; i++)
	{
		// General
		MenusGetName(i, sBuffer, sizeof(sBuffer)); // Index: 0
		kvMenus.Rewind();
		if (!kvMenus.JumpToKey(sBuffer))
		{
			// Log menu fatal
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu data for: \"%s\" (check menus config)", sBuffer);
			continue;
		}
		
		// Validate translation
		if (!TranslationIsPhraseExists(sBuffer))
		{
			// Log menu error
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu name: \"%s\" (check translation file)", sBuffer);
		}

		// Initialize array block
		ArrayList arrayMenu = gServerData.Menus.Get(i);

		// Push data into array
		kvMenus.GetString("group", sBuffer, sizeof(sBuffer), "");  
		arrayMenu.PushString(sBuffer);                                // Index: 1
		kvMenus.GetString("types", sBuffer, sizeof(sBuffer), "");  
		arrayMenu.Push(ClassTypeToIndex(sBuffer));                    // Index: 2
		arrayMenu.Push(ConfigKvGetStringBool(kvMenus, "hide", "no")); // Index: 3
		kvMenus.GetString("command", sBuffer, sizeof(sBuffer), "");
		arrayMenu.PushString(sBuffer);                                // Index: 4
		if (hasLength(sBuffer)) 
		{
			AddCommandListener(MenusOnCommandListenedCommand, sBuffer);
		}
		else if (kvMenus.JumpToKey("submenu"))                        // Index: 5
		{
			// Read keys in the file
			if (kvMenus.GotoFirstSubKey())
			{
				do
				{
					// Retrieves the sub section name
					kvMenus.GetSectionName(sBuffer, sizeof(sBuffer));
					
					// Validate translation
					if (!TranslationIsPhraseExists(sBuffer))
					{
						// Log menu error
						LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache submenu name: \"%s\" (check translation file)", sBuffer);
						continue;
					}

					// Push data into array ~ (i = submenu index)
					arrayMenu.PushString(sBuffer);                                // Index: i + 0
					kvMenus.GetString("group", sBuffer, sizeof(sBuffer), "");  
					arrayMenu.PushString(sBuffer);                                // Index: i + 1
					kvMenus.GetString("types", sBuffer, sizeof(sBuffer), "");  
					arrayMenu.Push(ClassTypeToIndex(sBuffer));                    // Index: i + 2
					arrayMenu.Push(ConfigKvGetStringBool(kvMenus, "hide", "no")); // Index: i + 3
					kvMenus.GetString("command", sBuffer, sizeof(sBuffer), "");
					arrayMenu.PushString(sBuffer);                                // Index: i + 4
					if (hasLength(sBuffer)) 
					{
						AddCommandListener(MenusOnCommandListenedCommand, sBuffer);
					}
				}
				while (kvMenus.GotoNextKey());
			}
			
			// Jumps back to the main section
			kvMenus.GoBack();
			kvMenus.GoBack();
		}
	}

	// We're done with this file now, so we can close it
	delete kvMenus;
}

/**
 * @brief Called when config is being reloaded.
 **/
public void MenusOnConfigReload(/*void*/)
{
	// Reloads menus config
	MenusOnLoad();
}

/**
 * @brief Hook menus cvar changes.
 **/
void MenusOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.MENU_BUTTON       = FindConVar("zp_menu_button");
	gCvarList.MENU_BUTTON_BLOCK = FindConVar("zp_menu_button_block");
	
	// Hook cvars
	HookConVarChange(gCvarList.MENU_BUTTON, MenusOnCvarHook);
	
	// Load cvars
	MenusOnCvarLoad();
}

/**
 * @brief Creates commands for menus module.
 **/
void MenusOnCommandInit(/*void*/)
{
	// Forward event to sub-modules
	MainMenuOnCommandInit();
}

/**
 * @brief Load menus listeners changes.
 **/
void MenusOnCvarLoad(/*void*/)
{
	// Hook commands
	CreateCommandListener(gCvarList.MENU_BUTTON, MenusOnCommandListened);
}

/*
 * Menus main functions.
 */

/**
 * Listener command callback (any)
 * @brief Opens the main menu.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action MenusOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	MainMenuOnCommandCatched(client, iArguments);
	return gCvarList.MENU_BUTTON_BLOCK.BoolValue ? Plugin_Handled : Plugin_Continue;
}

/**
 * Listener command callback (any)
 * @brief Validate the main menu.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action MenusOnCommandListenedCommand(int client, char[] commandMsg, int iArguments)
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		// Block command
		return Plugin_Handled;
	}
	
	// Validate access
	if (!MenusHasAccessByCommand(client, commandMsg))
	{
		// Show block info
		TranslationPrintHintText(client, "block using menu"); 

		// Emit error sound
		EmitSoundToClient(client, SOUND_BUTTON_MENU_ERROR, SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
		
		// Terminate command
		return Plugin_Stop;
	}
	
	// Allow command
	return Plugin_Continue;
}

/**
 * Cvar hook callback (zp_menu_button)
 * @brief Menus module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void MenusOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Forward event to modules
	MenusOnCvarLoad();
}

/*
 * Menus natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void MenusOnNativeInit(/*void*/) 
{
	CreateNative("ZP_GetNumberMenu",    API_GetNumberMenu);
	CreateNative("ZP_GetMenuName",      API_GetMenuName);
	CreateNative("ZP_GetMenuGroup",     API_GetMenuGroup);
	CreateNative("ZP_GetMenuTypes",     API_GetMenuTypes);
	CreateNative("ZP_IsMenuHide",       API_IsMenuHide);
	CreateNative("ZP_GetMenuCommandID", API_GetMenuCommandID);
	CreateNative("ZP_GetMenuCommand",   API_GetMenuCommand);
	CreateNative("ZP_OpenMenuSub",      API_OpenMenuSub);
}
 
/**
 * @brief Gets the amount of all menus.
 *
 * @note native int ZP_GetNumberMenu();
 **/
public int API_GetNumberMenu(Handle hPlugin, int iNumParams)
{
	// Return the value 
	return gServerData.Menus.Length;
}

/**
 * @brief Gets the name of a menu at a given id.
 *
 * @note native void ZP_GetMenuName(iD, name, maxlen, sub);
 **/
public int API_GetMenuName(Handle hPlugin, int iNumParams)
{
	// Gets menu index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize name char
	static char sName[SMALL_LINE_LENGTH];
	MenusGetName(iD, sName, sizeof(sName), GetNativeCell(4));

	// Return on success
	return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the group of a menu at a given id.
 *
 * @note native void ZP_GetMenuGroup(iD, group, maxlen, sub);
 **/
public int API_GetMenuGroup(Handle hPlugin, int iNumParams)
{
	// Gets menu index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize group char
	static char sGroup[SMALL_LINE_LENGTH];
	MenusGetGroup(iD, sGroup, sizeof(sGroup), GetNativeCell(4));

	// Return on success
	return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the types of a menu.
 *
 * @note native int ZP_GetMenuTypes(iD, sub);
 **/
public int API_GetMenuTypes(Handle hPlugin, int iNumParams)
{
	// Gets menu index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Return the value 
	return MenusGetTypes(iD, GetNativeCell(2));
}

/**
 * @brief Gets the menu value of the menu.
 *
 * @note native bool ZP_IsMenuHide(iD, sub);
 **/
public int API_IsMenuHide(Handle hPlugin, int iNumParams)
{    
	// Gets menu index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Return the value 
	return MenusIsHide(iD, GetNativeCell(2));
}

/**
 * @brief Gets the array of a menu at a given command.
 *
 * @note native void ZP_GetGameModeNameID(command, index, maxlen);
 **/
public int API_GetMenuCommandID(Handle hPlugin, int iNumParams)
{
	// Retrieves the string length from a native parameter string
	int maxLen;
	GetNativeStringLength(1, maxLen);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Can't find menu with an empty command");
		return -1;
	}
	
	// Gets native data
	static char sCommand[SMALL_LINE_LENGTH];

	// General
	GetNativeString(1, sCommand, sizeof(sCommand));

	// Initialize id array
	static int iD[2];
	iD = MenusCommandToArray(sCommand);  
	
	// Return on success
	return SetNativeArray(2, iD, sizeof(iD));
}

/**
 * @brief Gets the command of a menu at a given id.
 *
 * @note native void ZP_GetMenuCommand(iD, command, maxlen, sub);
 **/
public int API_GetMenuCommand(Handle hPlugin, int iNumParams)
{
	// Gets menu index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize command char
	static char sCommand[SMALL_LINE_LENGTH];
	MenusGetCommand(iD, sCommand, sizeof(sCommand), GetNativeCell(4));

	// Return on success
	return SetNativeString(2, sCommand, maxLen);
}

/**
 * @brief Opens the submenu of the menu.
 *
 * @note native void ZP_OpenMenuSub(client, iD);
 **/
public int API_OpenMenuSub(Handle hPlugin, int iNumParams)
{
	// Gets real player index from native cell 
	int client = GetNativeCell(1);

	// Validate client
	if (!IsPlayerExist(client))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the client index (%d)", client);
		return -1;
	}
	
	// Gets menu index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Opens sub menu
	SubMenu(client, iD);
	
	// Return on success
	return iD;
}

/*
 * Menus data reading API.
 */

/**
 * @brief Gets the name of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 * @param iSubMenu          (Optional) The submenu index. (Loop += 4)
 **/
void MenusGetName(int iD, char[] sName, int iMaxLen, int iSubMenu = 0)
{
	// Gets array handle of menu at given index
	ArrayList arrayMenu = gServerData.Menus.Get(iD);
	
	// Gets menu name
	arrayMenu.GetString(MENUS_DATA_NAME + iSubMenu, sName, iMaxLen);
}

/**
 * @brief Gets the group of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The lenght of string.
 * @param iSubMenu          (Optional) The submenu index.
 **/
void MenusGetGroup(int iD, char[] sGroup, int iMaxLen, int iSubMenu = 0)
{
	// Gets array handle of menu at given index
	ArrayList arrayMenu = gServerData.Menus.Get(iD);

	// Gets menu group
	arrayMenu.GetString(MENUS_DATA_GROUP + iSubMenu, sGroup, iMaxLen);
}

/**
 * @brief Gets the types of a menu.
 *
 * @param iD                The menu index.
 * @param iSubMenu          (Optional) The submenu index.
 * @return                  The types bits.
 **/
int MenusGetTypes(int iD, int iSubMenu = 0)
{
	// Gets array handle of menu at given index
	ArrayList arrayMenu = gServerData.Menus.Get(iD);
	
	// Gets class bits
	return arrayMenu.Get(MENUS_DATA_TYPES + iSubMenu);
}

/**
 * @brief Retrieve menu hide value.
 * 
 * @param iD                The menu index.
 * @param iSubMenu          (Optional) The submenu index.
 * @return                  True if menu is hided, false if not.
 **/
bool MenusIsHide(int iD, int iSubMenu = 0)
{
	// Gets array handle of menu at given index
	ArrayList arrayMenu = gServerData.Menus.Get(iD);
	
	// Return true if menu is hide, false if not
	return arrayMenu.Get(MENUS_DATA_HIDE + iSubMenu);
}

/**
 * @brief Gets the command of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sCommand          The string to return command in.
 * @param iMaxLen           The lenght of string.
 * @param iSubMenu          (Optional) The submenu index.
 **/
void MenusGetCommand(int iD, char[] sCommand, int iMaxLen, int iSubMenu = 0)
{
	// Gets array handle of menu at given index
	ArrayList arrayMenu = gServerData.Menus.Get(iD);
	
	// Gets menu command
	arrayMenu.GetString(MENUS_DATA_COMMAND + iSubMenu, sCommand, iMaxLen);
}

/*
 * Stocks menus API.
 */

/**
 * @brief Find the indexes at which the menu command is at.
 * 
 * @param sCommand          The menu command.
 * @return                  The array containing the given menu command.
 **/
int[] MenusCommandToArray(char[] sCommand)
{
	// Initialize command char
	static char sMenuCommand[SMALL_LINE_LENGTH];
	
	// Initialize index array
	int iD[2] = {-1, 0};
	
	// i = menu index
	int iSize = gServerData.Menus.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets array handle of menu at given index
		ArrayList arrayMenu = gServerData.Menus.Get(i);
		
		// x = submenu index
		int iCount = arrayMenu.Length;
		for (int x = 0; x < iCount; x += MENUS_DATA_SUBMENU)
		{
			// Gets menu command 
			MenusGetCommand(i, sMenuCommand, sizeof(sMenuCommand), x);
			
			// If commands match, then return index
			if (!strcmp(sCommand, sMenuCommand, false))
			{
				// Sets indexes
				iD[0] = i; iD[1] = x;
				
				// Return this array
				return iD;
			}
		}
	}
	
	// Command doesn't exist
	return iD;
}
 
/**
 * @brief Returns true if the player has an access by the command to the menu id, false if not.
 *
 * @param client            The client index.
 * @param sCommand          The menu command.
 * @return                  True or false.    
 **/
bool MenusHasAccessByCommand(int client, char[] sCommand)
{
	// Validate menu index
	int iD[2]; iD = MenusCommandToArray(sCommand);
	if (iD[0] != -1)
	{
		// Gets menu group
		static char sGroup[SMALL_LINE_LENGTH];
		MenusGetGroup(iD[0], sGroup, sizeof(sGroup), iD[1]);

		// Validate access
		if (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup) || !MenusHasAccessByType(client, iD[0], iD[1]))
		{
			return false;
		}
	}
	
	// Return on success
	return true;
}

/**
 * @brief Returns true if the player has an access by the class to the menu id, false if not.
 *
 * @param client            The client index.
 * @param iD                The menu id.
 * @param iSubMenu          (Optional) The submenu index.
 * @return                  True or false.    
 **/
bool MenusHasAccessByType(int client, int iD, int iSubMenu = 0)
{
	// If class find, then return
	return ClassHasType(MenusGetTypes(iD, iSubMenu), ClassGetType(gClientData[client].Class));
}

/**
 * @brief Return itemdraw flag for radio menus.
 * 
 * @param menuCondition     If this is true, item will be drawn normally.
 **/
int MenusGetItemDraw(bool menuCondition)
{
	return menuCondition ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
}