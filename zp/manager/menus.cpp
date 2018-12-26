/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          menus.cpp
 *  Type:          Manager 
 *  Description:   Menus table generator.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * Array handle to store menu generator config data.
 **/
ArrayList arrayMenus;

/**
 * Menu config data indexes.
 **/
enum
{
    MENUS_DATA_NAME,
    MENUS_DATA_GROUP,
    MENUS_DATA_HIDE,
    MENUS_DATA_COMMAND
}

/**
 * Menus module init function.
 **/
void MenusInit(/*void*/)
{
    // Initialize variable
    static char sCommand[SMALL_LINE_LENGTH];
    
    // Validate alias
    if(hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(MenusOnOpen, sCommand);
    }
    
    // Gets menu command alias
    gCvarList[CVAR_GAME_CUSTOM_MENU_BUTTON].GetString(sCommand, sizeof(sCommand));
    
    // Validate alias
    if(!hasLength(sCommand))
    {
        // Unhook listeners
        RemoveCommandListener2(MenusOnOpen, sCommand);
        return;
    }
    
    // Hook listeners
    AddCommandListener(MenusOnOpen, sCommand);
}

/**
 * Creates commands for menus module.
 **/
void MenusOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zp_main_menu", MenusCommandCatched, "Open the main menu.");
    
    // Prepare all menu data
    MenusLoad();
}

/**
 * Hook menus cvar changes.
 **/
void MenusOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_GAME_CUSTOM_MENU_BUTTON]     = FindConVar("zp_game_custom_menu_button");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_GAME_CUSTOM_MENU_BUTTON],     MenusCvarsHookEnable);
}

/**
 * Handles the <!zp_main_menu> command. Open the main menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MenusCommandCatched(const int clientIndex, const int iArguments)
{
    MenuMain(clientIndex);
    return Plugin_Handled;
}

/**
 * Callback for command listener to open the main menu.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action MenusOnOpen(const int clientIndex, const char[] commandMsg, const int iArguments)
{
    // Open the main menu
    MenuMain(clientIndex);
    return Plugin_Handled;
}

/**
 * Cvar hook callback (zp_game_custom_menu_button)
 * Menus module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void MenusCvarsHookEnable(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Forward event to modules
    MenusInit();
}

/**
 * Prepare all menu data.
 **/
void MenusLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Menus, Structure_Keyvalue, CONFIG_FILE_ALIAS_MENUS);

    // Gets menus config path
    static char sPathMenus[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_MENUS, sPathMenus);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Missing menus config file: \"%s\"", sPathMenus);
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_Menus, sPathMenus);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Menus, arrayMenus);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathMenus);
    }

    // Validate menus config
    int iSize = arrayMenus.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "No usable data found in menus config file: \"%s\"", sPathMenus);
    }

    // Now copy data to array structure
    MenusCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Menus, true);
    ConfigSetConfigReloadFunc(File_Menus, GetFunctionByName(GetMyHandle(), "MenusOnConfigReload"));
    ConfigSetConfigHandle(File_Menus, arrayMenus);
}

/**
 * Caches menu data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void MenusCacheData(/*void*/)
{
    // Gets config file path
    static char sPathMenus[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Menus, sPathMenus, sizeof(sPathMenus));

    // Open config
    KeyValues kvMenus;
    bool bSuccess = ConfigOpenConfigFile(File_Menus, kvMenus);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error caching data from menus config file: \"%s\"", sPathMenus);
    }

    // i = array index
    int iSize = arrayMenus.Length;
    for(int i = 0; i < iSize; i++)
    {
        // General
        MenusGetName(i, sPathMenus, sizeof(sPathMenus)); // Index: 0
        kvMenus.Rewind();
        if(!kvMenus.JumpToKey(sPathMenus))
        {
            // Log menu fatal
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu data for: \"%s\" (check menus config)", sPathMenus);
            continue;
        }
        
        // Validate translation
        if(!TranslationPhraseExists(sPathMenus))
        {
            // Log menu error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu name: \"%s\" (check translation file)", sPathMenus);
        }

        // Initialize array block
        ArrayList arrayMenu = arrayMenus.Get(i);

        // Push data into array
        kvMenus.GetString("group", sPathMenus, sizeof(sPathMenus), "");  
        arrayMenu.PushString(sPathMenus);                             // Index: 1
        arrayMenu.Push(ConfigKvGetStringBool(kvMenus, "hide", "no")); // Index: 2
        kvMenus.GetString("command", sPathMenus, sizeof(sPathMenus), "");
        arrayMenu.PushString(sPathMenus);                             // Index: 3
    }

    // We're done with this file now, so we can close it
    delete kvMenus;
}

/**
 * Called when config is being reloaded.
 **/
public void MenusOnConfigReload(/*void*/)
{
    // Reload menus config
    MenusLoad();
}

/*
 * Menus natives API.
 */

/**
 * Sets up natives for library.
 **/
void MenusAPI(/*void*/) 
{
    CreateNative("ZP_GetNumberMenu",                  API_GetNumberMenu);
    CreateNative("ZP_GetMenuName",                    API_GetMenuName);
    CreateNative("ZP_GetMenuGroup",                   API_GetMenuGroup);
    CreateNative("ZP_IsMenuHide",                     API_IsMenuHide);
    CreateNative("ZP_GetMenuCommand",                 API_GetMenuCommand);
}
 
/**
 * Gets the amount of all menus.
 *
 * native int ZP_GetNumberMenu();
 **/
public int API_GetNumberMenu(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return arrayMenus.Length;
}

/**
 * Gets the name of a menu at a given id.
 *
 * native void ZP_GetMenuName(iD, name, maxlen);
 **/
public int API_GetMenuName(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayMenus.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    MenusGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the group of a menu at a given id.
 *
 * native void ZP_GetMenuGroup(iD, group, maxlen);
 **/
public int API_GetMenuGroup(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayMenus.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    MenusGetGroup(iD, sGroup, sizeof(sGroup));

    // Return on success
    return SetNativeString(2, sGroup, maxLen);
}

/**
 * Gets the menu value of the costume.
 *
 * native bool ZP_IsMenuHide(iD);
 **/
public int API_IsMenuHide(Handle hPlugin, const int iNumParams)
{    
    // Gets costume index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayMenus.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
        return -1;
    }
    
    // Return the value 
    return MenusIsHide(iD);
}

/**
 * Gets the command of a menu at a given id.
 *
 * native void ZP_GetMenuCommand(iD, command, maxlen);
 **/
public int API_GetMenuCommand(Handle hPlugin, const int iNumParams)
{
    // Gets weapon index from native cell
    int iD = GetNativeCell(1);
    
    // Validate index
    if(iD >= arrayMenus.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "Invalid the menu index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Menus, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize command char
    static char sCommand[SMALL_LINE_LENGTH];
    MenusGetCommand(iD, sCommand, sizeof(sCommand));

    // Return on success
    return SetNativeString(2, sCommand, maxLen);
}

/*
 * Menus data reading API.
 */

/**
 * Gets the name of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Gets array handle of menu at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);
    
    // Gets menu name
    arrayMenu.GetString(MENUS_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the access group of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetGroup(const int iD, char[] sGroup, const int iMaxLen)
{
    // Gets array handle of menu at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);

    // Gets menu group
    arrayMenu.GetString(MENUS_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * Retrieve menu hide value.
 * 
 * @param iD                The menu index.
 * @return                  True if menu is hided, false if not.
 **/
stock bool MenusIsHide(const int iD)
{
    // Gets array handle of menu at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);
    
    // Return true if menu is hide, false if not
    return arrayMenu.Get(MENUS_DATA_HIDE);
}

/**
 * Gets the command of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sCommand          The string to return command in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetCommand(const int iD, char[] sCommand, const int iMaxLen)
{
    // Gets array handle of menu at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);
    
    // Gets menu command
    arrayMenu.GetString(MENUS_DATA_COMMAND, sCommand, iMaxLen);
}

/*
 * Stocks menus API.
 */
 
/**
 * Create a main menu.
 *
 * @param clientIndex       The client index.
 **/
void MenuMain(const int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sName[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];

    // Create menu handle
    Menu hMenu = CreateMenu(MenuMainSlots);
    
    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "main menu");
    
    // i = Array index
    int iSize = arrayMenus.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets menu group
        MenusGetGroup(i, sName, sizeof(sName));

        // Validate access
        bool bHide = (!IsPlayerInGroup(clientIndex, sName) && hasLength(sName));

        // Skip, if menu is hided
        if(bHide && MenusIsHide(i))
        {
            continue;
        }

        // Gets menu name
        MenusGetName(i, sName, sizeof(sName));

        // Format some chars for showing in menu
        Format(sBuffer, sizeof(sBuffer), "%t", sName);

        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(bHide ? false : true));
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iSize)
    {
        static char sEmpty[SMALL_LINE_LENGTH];
        Format(sEmpty, sizeof(sEmpty), "%t", "empty");

        hMenu.AddItem("empty", sEmpty, ITEMDRAW_DISABLED);
    }

    // Sets exit and back button
    hMenu.ExitButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the main menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MenuMainSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
    // Switch the menu action
    switch(mAction)
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
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }
            
            // Initialize command char
            static char sCommand[SMALL_LINE_LENGTH];

            // Gets ID of menu
            hMenu.GetItem(mSlot, sCommand, sizeof(sCommand));
            int iD = StringToInt(sCommand);
            
            // Gets menu command
            MenusGetCommand(iD, sCommand, sizeof(sCommand));
            
            // Run the command
            FakeClientCommand(clientIndex, sCommand);
        }
    }
}

/**
 * Return itemdraw flag for radio menus.
 * 
 * @param menuCondition     If this is true, item will be drawn normally.
 **/
stock int MenuGetItemDraw(const bool menuCondition)
{
    return menuCondition ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
}
