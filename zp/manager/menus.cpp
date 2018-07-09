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
    MENUS_DATA_TITLE,
    MENUS_DATA_ACCESS,
    MENUS_DATA_COMMAND
}

/**
 * Creates commands for mainmenu module. Called when commands are created.
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
    int iSize = GetArraySize(arrayMenus);
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
    // Gets config's file path
    static char sMenusPath[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Menus, sMenusPath, sizeof(sMenusPath));

    KeyValues kvMenus;
    bool bSuccess = ConfigOpenConfigFile(File_Menus, kvMenus);

    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Unexpected error caching data from menus config file: \"%s\"", sMenusPath);
    }

    static char sMenuName[SMALL_LINE_LENGTH];

    // i = array index
    int iSize = GetArraySize(arrayMenus);
    for(int i = 0; i < iSize; i++)
    {
        // General
        MenusGetName(i, sMenuName, sizeof(sMenuName)); // Index: 0
        kvMenus.Rewind();
        if(!kvMenus.JumpToKey(sMenuName))
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Menus, "Config Validation", "Couldn't cache menu data for: \"%s\" (check menus config)", sMenuName);
            continue;
        }

        // Gets config data
        static char sMenuTitle[CONFIG_MAX_LENGTH];
        static char sMenuAccess[CONFIG_MAX_LENGTH];
        static char sMenuCommand[CONFIG_MAX_LENGTH];
        
        // General                                                              
        kvMenus.GetString("menutitle", sMenuTitle, sizeof(sMenuTitle));   
        kvMenus.GetString("menuaccess", sMenuAccess, sizeof(sMenuAccess));  
        kvMenus.GetString("menucommand", sMenuCommand, sizeof(sMenuCommand));
        
        // Initialize array block
        ArrayList arrayMenu = arrayMenus.Get(i);

        // Push data into array
        arrayMenu.PushString(sMenuTitle);     // Index: 1
        arrayMenu.PushString(sMenuAccess);    // Index: 2
        arrayMenu.PushString(sMenuCommand);   // Index: 3
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

/**
 * Gets the name of a menu at a given index.
 *
 * @param iD                The menu index.
 * @param sClassname        The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetName(int iD, char[] sClassname, int iMaxLen)
{
    // Gets array handle of menu at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);
    
    // Gets menu name
    arrayMenu.GetString(MENUS_DATA_NAME, sClassname, iMaxLen);
}

/**
 * Gets the title of a menu at a given index.
 *
 * @param iD                The weapon index.
 * @param sType             The string to return entity in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetTitle(int iD, char[] sType, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);
    
    // Gets menu title
    arrayMenu.GetString(MENUS_DATA_TITLE, sType, iMaxLen);
}

/**
 * Gets the access flag of a menu at a given index.
 *
 * @param iD                The weapon index.
 * @param sType             The string to return entity in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetAcess(int iD, char[] sType, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);

    // Gets menu access
    arrayMenu.GetString(MENUS_DATA_ACCESS, sType, iMaxLen);
}

/**
 * Gets the command of a menu at a given index.
 *
 * @param iD                The weapon index.
 * @param sType             The string to return entity in.
 * @param iMaxLen           The max length of the string.
 **/
stock void MenusGetCommand(int iD, char[] sType, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arrayMenu = arrayMenus.Get(iD);
    
    // Gets menu command
    arrayMenu.GetString(MENUS_DATA_COMMAND, sType, iMaxLen);
}

/*
 * Main menu
 */
 
/**
 * Create an main menu.
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
    int iSize = GetArraySize(arrayMenus);
    for(int i = 0; i < iSize; i++)
    {
        // Gets menu title
        MenusGetTitle(i, sName, sizeof(sName));
        
        // Format some chars for showing in menu
        Format(sBuffer, sizeof(sBuffer), "%t", sName);

        // Gets menu access flags
        MenusGetAcess(i, sName, sizeof(sName));
        
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