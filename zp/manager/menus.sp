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
	MENUS_DATA_CLASS,
	MENUS_DATA_HIDE,
	MENUS_DATA_COMMAND,
	MENUS_DATA_SUBMENU
};
/**
 * @endsection
 **/
 
/**
 * @brief Prepare all menu data.
 **/
void MenusOnLoad(/*void*/)
{
	// Register config file
	ConfigRegisterConfig(File_Menus, Structure_Keyvalue, CONFIG_FILE_ALIAS_MENUS);

	// Gets menus config path
	static char sPathMenus[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_MENUS, sPathMenus, sizeof(sPathMenus));

	// If file doesn't exist, then log and stop
	if (!bExists)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Menus, "Config Validation", "Missing menus config file: \"%s\"", sPathMenus);
		return;
	}

	// Sets path to the config file
	ConfigSetConfigPath(File_Menus, sPathMenus);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_Menus, gServerData.Menus);

	// Unexpected error, stop plugin
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathMenus);
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
	static char sPathMenus[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Menus, sPathMenus, sizeof(sPathMenus));

	// Opens config
	KeyValues kvMenus;
	bool bSuccess = ConfigOpenConfigFile(File_Menus, kvMenus);

	// Validate config
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error caching data from menus config file: \"%s\"", sPathMenus);
		return;
	}

	// Validate size
	int iSize = gServerData.Menus.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Menus, "Config Validation", "No usable data found in menus config file: \"%s\"", sPathMenus);
		return;
	}
	
	// i = array index
	for (int i = 0; i < iSize; i++)
	{
		// General
		MenusGetName(i, sPathMenus, sizeof(sPathMenus)); // Index: 0
		kvMenus.Rewind();
		if (!kvMenus.JumpToKey(sPathMenus))
		{
			// Log menu fatal
			LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu data for: \"%s\" (check menus config)", sPathMenus);
			continue;
		}
		
		// Validate translation
		StringToLower(sPathMenus);
		if (!TranslationPhraseExists(sPathMenus))
		{
			// Log menu error
			LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu name: \"%s\" (check translation file)", sPathMenus);
		}

		// Initialize array block
		ArrayList arrayMenu = gServerData.Menus.Get(i);

		// Push data into array
		kvMenus.GetString("group", sPathMenus, sizeof(sPathMenus), "");  
		arrayMenu.PushString(sPathMenus);                             // Index: 1
		kvMenus.GetString("class", sPathMenus, sizeof(sPathMenus), "");  
		arrayMenu.PushString(sPathMenus);                             // Index: 2
		arrayMenu.Push(ConfigKvGetStringBool(kvMenus, "hide", "no")); // Index: 3
		kvMenus.GetString("command", sPathMenus, sizeof(sPathMenus), "");
		arrayMenu.PushString(sPathMenus);                             // Index: 4
		if (hasLength(sPathMenus)) 
		{
			AddCommandListener(MenusCommandOnCommandListened, sPathMenus);
		}
		else if (kvMenus.JumpToKey("submenu"))                         // Index: 5
		{
			// Read keys in the file
			if (kvMenus.GotoFirstSubKey())
			{
				do
				{
					// Retrieves the sub section name
					kvMenus.GetSectionName(sPathMenus, sizeof(sPathMenus));
					
					// Validate translation
					StringToLower(sPathMenus);
					if (!TranslationPhraseExists(sPathMenus))
					{
						// Log menu error
						LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache submenu name: \"%s\" (check translation file)", sPathMenus);
						continue;
					}

					// Push data into array ~ (i = submenu index)
					arrayMenu.PushString(sPathMenus);                                // Index: i + 0
					kvMenus.GetString("group", sPathMenus, sizeof(sPathMenus), "");  
					arrayMenu.PushString(sPathMenus);                                // Index: i + 1
					kvMenus.GetString("class", sPathMenus, sizeof(sPathMenus), "");  
					arrayMenu.PushString(sPathMenus);                                // Index: i + 2
					arrayMenu.Push(ConfigKvGetStringBool(kvMenus, "hide", "no"));    // Index: i + 3
					kvMenus.GetString("command", sPathMenus, sizeof(sPathMenus), "");
					arrayMenu.PushString(sPathMenus);                                // Index: i + 4
					if (hasLength(sPathMenus)) 
					{
						AddCommandListener(MenusCommandOnCommandListened, sPathMenus);
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
 * @brief Creates commands for menus module.
 **/
void MenusOnCommandInit(/*void*/)
{
	// Hook commands
	RegConsoleCmd("zmenu", MenusOnCommandCatched, "Opens the main menu.");
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
 * @brief Load menus listeners changes.
 **/
void MenusOnCvarLoad(/*void*/)
{
	// Initialize command char
	static char sCommand[SMALL_LINE_LENGTH];
	
	// Validate alias
	if (hasLength(sCommand))
	{
		// Unhook listeners
		RemoveCommandListener2(MenusMainOnCommandListened, sCommand);
	}
	
	// Gets menu command alias
	gCvarList.MENU_BUTTON.GetString(sCommand, sizeof(sCommand));
	
	// Validate alias
	if (!hasLength(sCommand))
	{
		// Unhook listeners
		RemoveCommandListener2(MenusMainOnCommandListened, sCommand);
		return;
	}
	
	// Hook listeners
	AddCommandListener(MenusMainOnCommandListened, sCommand);
}

/*
 * Menus main functions.
 */

/**
 * Console command callback (zmenu)
 * @brief Opens the main menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MenusOnCommandCatched(int client, int iArguments)
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
 * Listener command callback (any)
 * @brief Opens the main menu.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action MenusMainOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	MenusOnCommandCatched(client, iArguments);
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
public Action MenusCommandOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		// Block command
		return Plugin_Handled;
	}
	
	// Validate access
	if (!MenusValidateByCommand(client, commandMsg))
	{
		// Show block info
		TranslationPrintHintText(client, "using menu block"); 

		// Emit error sound
		EmitSoundToClient(client, "*/buttons/button11.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
		
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
	CreateNative("ZP_GetMenuClass",     API_GetMenuClass);
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
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
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
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize group char
	static char sGroup[SMALL_LINE_LENGTH];
	MenusGetGroup(iD, sGroup, sizeof(sGroup), GetNativeCell(4));

	// Return on success
	return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the class of a menu at a given id.
 *
 * @note native void ZP_GetMenuClass(iD, class, maxlen, sub);
 **/
public int API_GetMenuClass(Handle hPlugin, int iNumParams)
{
	// Gets menu index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize class char
	static char sClass[BIG_LINE_LENGTH];
	MenusGetClass(iD, sClass, sizeof(sClass), GetNativeCell(4));

	// Return on success
	return SetNativeString(2, sClass, maxLen);
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
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
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
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Can't find menu with an empty command");
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
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
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
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Invalid the client index (%d)", client);
		return -1;
	}
	
	// Gets menu index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if (iD >= gServerData.Menus.Length)
	{
		LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
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
 * @brief Gets the class of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sClass            The string to return class in.
 * @param iMaxLen           The lenght of string.
 * @param iSubMenu          (Optional) The submenu index.
 **/
void MenusGetClass(int iD, char[] sClass, int iMaxLen, int iSubMenu = 0)
{
	// Gets array handle of menu at given index
	ArrayList arrayMenu = gServerData.Menus.Get(iD);

	// Gets menu class
	arrayMenu.GetString(MENUS_DATA_CLASS + iSubMenu, sClass, iMaxLen);
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
bool MenusValidateByCommand(int client, char[] sCommand)
{
	// Validate menu index
	int iD[2]; iD = MenusCommandToArray(sCommand);
	if (iD[0] != -1)
	{
		// Gets menu group
		static char sGroup[SMALL_LINE_LENGTH];
		MenusGetGroup(iD[0], sGroup, sizeof(sGroup), iD[1]);

		// Validate access
		if (hasLength(sGroup) && !IsPlayerInGroup(client, sGroup) || !MenusValidateClass(client, iD[0], iD[1]))
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
bool MenusValidateClass(int client, int iD, int iSubMenu = 0)
{
	// Gets menu class
	static char sClass[BIG_LINE_LENGTH];
	MenusGetClass(iD, sClass, sizeof(sClass), iSubMenu);
	
	// Validate length
	if (hasLength(sClass))
	{
		// Gets class type 
		static char sType[SMALL_LINE_LENGTH];
		ClassGetType(gClientData[client].Class, sType, sizeof(sType));

		// If class find, then return
		return (hasLength(sType) && StrContain(sType, sClass, ','));
	}
	
	// Return on success
	return true;
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

/*
 * Menu main API.
 */

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
		bool bHide = ((hasLength(sName) && !IsPlayerInGroup(client, sName)) || !MenusValidateClass(client, i));

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
			if (MenusValidateClass(client, iD)) 
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
				TranslationPrintHintText(client, "using menu block"); 
		
				// Emit error sound
				EmitSoundToClient(client, "*/buttons/button11.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
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
		bool bHide = ((hasLength(sName) && !IsPlayerInGroup(client, sName)) || !MenusValidateClass(client, iD, i));

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
			if (MenusValidateClass(client, iD, i)) 
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
				TranslationPrintHintText(client, "using menu block"); 
				
				// Emit error sound
				EmitSoundToClient(client, "*/buttons/button11.wav", SOUND_FROM_PLAYER, SNDCHAN_ITEM, SNDLEVEL_WHISPER);    
			}
		}
	}
	
	return 0;
}
