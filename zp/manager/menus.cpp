/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          menus.cpp
 *  Type:          Manager 
 *  Description:   Menus table generator.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
    MENUS_DATA_ACCESS,
    MENUS_DATA_COMMAND
}

/**
 * Creates commands for menu module. Called when commands are created.
 **/
void MenusOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zmainmenu", MenusCommandCatched, "Open the main menu.");
}

/**
 * Handles the <!zmainmenu> command. Open the main menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MenusCommandCatched(int clientIndex, int iArguments)
{
    // Open the main menu
    MenuMain(clientIndex);
    return Plugin_Handled;
}

/**
 * Prepare all menu data.
 **/
void MenusLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Menus, Structure_Keyvalue, CONFIG_FILE_ALIAS_MENUS);

    // Gets menus config path
    static char sMenuPath[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_MENUS, sMenuPath);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Missing menus config file: \"%s\"", sMenuPath);
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_Menus, sMenuPath);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Menus, arrayMenus);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error encountered loading: \"%s\"", sMenuPath);
    }

    // Validate menus config
    int iSize = arrayMenus.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "No usable data found in menus config file: \"%s\"", sMenuPath);
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
    static char sMenusPath[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Menus, sMenusPath, sizeof(sMenusPath));

    KeyValues kvMenus;
    bool bSuccess = ConfigOpenConfigFile(File_Menus, kvMenus);

    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error caching data from menus config file: \"%s\"", sMenusPath);
    }

    // i = array index
    int iSize = arrayMenus.Length;
    for(int i = 0; i < iSize; i++)
    {
        // General
        MenusGetName(i, sMenusPath, sizeof(sMenusPath)); // Index: 0
        kvMenus.Rewind();
        if(!kvMenus.JumpToKey(sMenusPath))
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu data for: \"%s\" (check menus config)", sMenusPath);
            continue;
        }

        // Initialize array block
        ArrayList arrayMenu = arrayMenus.Get(i);

        // Push data into array
        kvMenus.GetString("access", sMenusPath, sizeof(sMenusPath), "");  
        arrayMenu.PushString(sMenusPath); // Index: 1
        kvMenus.GetString("command", sMenusPath, sizeof(sMenusPath), "");
        arrayMenu.PushString(sMenusPath); // Index: 2
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
 * Gets the amount of all menus.
 *
 * native int ZP_GetNumberMenu();
 **/
public int API_GetNumberMenu(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return arrayMenus.Length;
}

/**
 * Gets the name of a menu at a given id.
 *
 * native void ZP_GetMenuName(iD, name, maxlen);
 **/
public int API_GetMenuName(Handle isPlugin, int iNumParams)
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
 * Gets the access of a menu at a given id.
 *
 * native void ZP_GetMenuAccess(iD, flags, maxlen);
 **/
public int API_GetMenuAccess(Handle isPlugin, int iNumParams)
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
    
    // Initialize flags char
    static char sFlags[SMALL_LINE_LENGTH];
    MenusGetAccess(iD, sFlags, sizeof(sFlags));

    // Return on success
    return SetNativeString(2, sFlags, maxLen);
}

/**
 * Gets the command of a menu at a given id.
 *
 * native void ZP_GetMenuCommand(iD, command, maxlen);
 **/
public int API_GetMenuCommand(Handle isPlugin, int iNumParams)
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
stock void MenusGetName(int iD, char[] sName, int iMaxLen)
{
    // Gets array handle of menu at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);
    
    // Gets menu name
    arrayMenu.GetString(MENUS_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the access flag of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sType             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetAccess(int iD, char[] sType, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);

    // Gets menu access
    arrayMenu.GetString(MENUS_DATA_ACCESS, sType, iMaxLen);
}

/**
 * Gets the command of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sCommand          The string to return command in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetCommand(int iD, char[] sCommand, int iMaxLen)
{
    // Gets array handle of weapon at given index
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
void MenuMain(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Call forward
    Action resultHandle = API_OnClientValidateMainMenu(clientIndex);

    // Validate handle
    if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
    {
        // Initialize chars
        static char sBuffer[NORMAL_LINE_LENGTH];
        static char sName[SMALL_LINE_LENGTH];
        static char sInfo[SMALL_LINE_LENGTH];

        // Create menu handle
        Menu hMenu = CreateMenu(MenuMainSlots);
        
        // Sets the language to target
        SetGlobalTransTarget(clientIndex);
        
        // Sets title
        hMenu.SetTitle("%t", "Main menu");
        
        // i = Array index
        int iSize = arrayMenus.Length;
        for(int i = 0; i < iSize; i++)
        {
            // Gets menu name
            MenusGetName(i, sName, sizeof(sName));
            
            // Format some chars for showing in menu
            Format(sBuffer, sizeof(sBuffer), "%t", sName);

            // Gets menu access flags
            MenusGetAccess(i, sName, sizeof(sName));
            
            // Show option
            IntToString(i, sInfo, sizeof(sInfo));
            hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(IsPlayerHasFlags(clientIndex, sName)));
        }
        
        // If there are no cases, add an "(Empty)" line
        if(!iSize)
        {
            static char sEmpty[SMALL_LINE_LENGTH];
            Format(sEmpty, sizeof(sEmpty), "%t", "Empty");

            hMenu.AddItem("empty", sEmpty, ITEMDRAW_DISABLED);
        }

        // Sets exit and back button
        hMenu.ExitButton = true;

        // Sets options and display it
        hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
        hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
    }
}

/**
 * Called when client selects option in the main menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int MenuMainSlots(Menu hMenu, MenuAction mAction, int clientIndex, int mSlot)
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
stock int MenuGetItemDraw(bool menuCondition)
{
    return menuCondition ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
}
