/**
 * ============================================================================
 *
 *   Plague
 *
 *  File:          classmenus.cpp
 *  Type:          Module 
 *  Description:   Provides functions for managing class menus.
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
 * Menu duration of the instant change.
 **/
#define MENU_TIME_INSTANT 10 

/**
 * @brief Creates commands for classes module.
 **/
void ClassMenusOnCommandInit(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zp_human_menu", ClassHumanOnCommandCatched, "Opens the human classes menu.");
    RegConsoleCmd("zp_zombie_menu", ClassZombieOnCommandCatched, "Opens the zombie classes menu.");
    RegConsoleCmd("zp_class_menu", ClassesOnCommandCatched, "Opens the classes menu.");
}

/**
 * Console command callback (zp_human_menu)
 * @brief Opens the human classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ClassHumanOnCommandCatched(const int clientIndex, const int iArguments)
{
    ClassMenu(clientIndex, "choose humanclass", "human", gClientData[clientIndex].HumanClassNext);
    return Plugin_Handled;
}

/**
 * Console command callback (zp_zombie_menu)
 * @brief Opens the zombie classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ClassZombieOnCommandCatched(const int clientIndex, const int iArguments)
{
    ClassMenu(clientIndex, "choose zombieclass", "zombie", gClientData[clientIndex].ZombieClassNext);
    return Plugin_Handled;
}

/**
 * Console command callback (zp_class_menu)
 * @brief Opens the classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ClassesOnCommandCatched(const int clientIndex, const int iArguments)
{
    ClassesMenu(clientIndex);
    return Plugin_Handled;
}

/*
 * Stocks class API.
 */

/**
 * @brief Validate zombie class for client availability.
 *
 * @param clientIndex       The client index.
 **/
void ZombieValidateClass(const int clientIndex)
{
    // Validate class
    int iClass = ClassValidateIndex(clientIndex, "zombie");
    switch(iClass)
    {
        case -2 : LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache any default \"zombie\" class");
        
        case -1 : { /* < empty statement > */ }
        
        default :
        {
            // Update zombie class
            gClientData[clientIndex].ZombieClassNext  = iClass;
            gClientData[clientIndex].Class = iClass;
            
            // Update class in the database
            DataBaseOnClientUpdate(clientIndex, ColumnType_Zombie);
        }
    }
}

/**
 * @brief Validate human class for client availability.
 *
 * @param clientIndex       The client index.
 **/
void HumanValidateClass(const int clientIndex)
{
    // Validate class
    int iClass = ClassValidateIndex(clientIndex, "human");
    switch(iClass)
    {
        case -2 : LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't cache any default \"human\" class");
        
        case -1 : { /* < empty statement > */ }
        
        default :
        {
            // Update human class
            gClientData[clientIndex].HumanClassNext  = iClass;
            gClientData[clientIndex].Class = iClass;
            
            // Update class in the database
            DataBaseOnClientUpdate(clientIndex, ColumnType_Human);
        }
    }
}

/**
 * @brief Validate class for client availability.
 *
 * @param clientIndex       The client index.
 * @return                  The class index. 
 **/
int ClassValidateIndex(const int clientIndex, const char[] sType)
{
    // Gets array size
    int iSize = gServerData.Classes.Length;

    // Choose random class for the bot
    if(IsFakeClient(clientIndex) || iSize <= gClientData[clientIndex].Class)
    {
        // Validate class index
        int iD = ClassTypeToIndex(sType);
        if(iD == -1)
        {
            return -2;
        }
        
        // Update class
        gClientData[clientIndex].Class = iD;
    }
    
    // Gets class group
    static char sClassGroup[SMALL_LINE_LENGTH];
    ClassGetGroup(gClientData[clientIndex].Class, sClassGroup, sizeof(sClassGroup));
    
    // Gets class type
    static char sClassType[SMALL_LINE_LENGTH];
    ClassGetType(gClientData[clientIndex].Class, sClassType, sizeof(sClassType));
    
    // Find any accessable class 
    if((hasLength(sClassGroup) && !IsPlayerInGroup(clientIndex, sClassGroup)) || ClassGetLevel(gClientData[clientIndex].Class) > gClientData[clientIndex].Level || strcmp(sClassType, sType) != 0)
    {
        // Choose any accessable class
        for(int i = 0; i < iSize; i++)
        {
            // Skip some classes, if group isn't accessable
            ClassGetGroup(i, sClassGroup, sizeof(sClassGroup));
            if(hasLength(sClassGroup) && !IsPlayerInGroup(clientIndex, sClassGroup))
            {
                continue;
            }
            
            // Skip some classes, if types isn't equal
            ClassGetType(i, sClassType, sizeof(sClassType));
            if(strcmp(sClassType, sType) != 0)
            {
                continue;
            }
            
            // Skip some classes, if level too low
            if(ClassGetLevel(i) > gClientData[clientIndex].Level)
            {
                continue;
            }
            
            // Return this index
            return i;
        }
    }
    // Client already had accessable class
    else return -1;
    
    // Class doesn't exist
    return -2;
}

/*
 * Menu classes API.
 */

/**
 * @brief Creates the class menu.
 *
 * @param clientIndex       The client index.
 * @param sTitle            The menu title.
 * @param sType             The class type.
 * @param iClass            The current class.
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/
void ClassMenu(const int clientIndex, const char[] sTitle, const char[] sType, const int iClass, const bool bInstant = false) 
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
    static char sLevel[SMALL_LINE_LENGTH];
    static char sGroup[SMALL_LINE_LENGTH];

    // Creates menu handle
    Menu hMenu = CreateMenu((!strcmp(sType, "zombie")) ? (bInstant ? ClassZombieMenuSlots2 : ClassZombieMenuSlots1) : (bInstant ? ClassHumanMenuSlots2 : ClassHumanMenuSlots1));

    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", sTitle);
    
    // Initialize forward
    static Action resultHandle;
    
    // i = class index
    int iSize = gServerData.Classes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Call forward
        gForwardData._OnClientValidateClass(clientIndex, i, resultHandle);
        
        // Skip, if class is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Gets class type
        ClassGetType(i, sName, sizeof(sName));
        
        // Skip some classes, if types isn't equal
        if(strcmp(sName, sType) != 0)
        {
            continue;
        }
        
        // Gets general class data
        ClassGetName(i, sName, sizeof(sName));
        ClassGetGroup(i, sGroup, sizeof(sGroup));
        
        // Format some chars for showing in menu
        FormatEx(sLevel, sizeof(sLevel), "%t", "level", ClassGetLevel(i));
        FormatEx(sBuffer, sizeof(sBuffer), "%t\t%s", sName, (hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup)) ? sGroup : (gClientData[clientIndex].Level < ClassGetLevel(i)) ? sLevel : "");

        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(resultHandle == Plugin_Handled || ((hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup)) || gClientData[clientIndex].Level < ClassGetLevel(i) || iClass == i) ? false : true));
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iSize)
    {
        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
        hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, bInstant ? MENU_TIME_INSTANT : MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassZombieMenuSlots1(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ClassMenuSlots(hMenu, mAction, "zp_zombie_menu", clientIndex, mSlot);
}

/**
 * @brief Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassZombieMenuSlots2(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ClassMenuSlots(hMenu, mAction, "zp_zombie_menu", clientIndex, mSlot, true);
}

/**
 * @brief Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassHumanMenuSlots1(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ClassMenuSlots(hMenu, mAction, "zp_human_menu", clientIndex, mSlot);
}

/**
 * @brief Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassHumanMenuSlots2(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ClassMenuSlots(hMenu, mAction, "zp_human_menu", clientIndex, mSlot, true);
}

/**
 * @brief Called when client selects option in the class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param sCommand          The menu command.
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/ 
void ClassMenuSlots(Menu hMenu, MenuAction mAction, const char[] sCommand, const int clientIndex, const int mSlot, const bool bInstant = false)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hMenu;
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Opens menu back
                int iD[2]; iD = MenusCommandToArray(sCommand);
                if(iD[0] != -1) SubMenu(clientIndex, iD[0]);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }

            // Initialize name char
            static char sClassName[SMALL_LINE_LENGTH];

            // Gets menu info
            hMenu.GetItem(mSlot, sClassName, sizeof(sClassName));
            int iD = StringToInt(sClassName);
            
            // Call forward
            static Action resultHandle;
            gForwardData._OnClientValidateClass(clientIndex, iD, resultHandle);

            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Gets class type
                ClassGetType(iD, sClassName, sizeof(sClassName));
                
                // Validate human
                if(!strcmp(sClassName, "human", false))
                {
                    // Sets next human class
                    gClientData[clientIndex].HumanClassNext = iD;
                    
                    // Update class in the database
                    DataBaseOnClientUpdate(clientIndex, ColumnType_Human);
                        
                    // Validate instant change
                    if(bInstant)
                    {
                        // Make human
                        ApplyOnClientUpdate(clientIndex, _, "human");
                    }
                }
                // Validate zombie
                else if(!strcmp(sClassName, "zombie", false))
                {
                    // Sets next zombie class
                    gClientData[clientIndex].ZombieClassNext = iD;
                    
                    // Update class in the database
                    DataBaseOnClientUpdate(clientIndex, ColumnType_Zombie);
                    
                    // Validate instant change
                    if(bInstant)
                    {
                        // Make zombie
                        ApplyOnClientUpdate(clientIndex, _, "zombie");
                    }
                }
                else 
                {
                    // Emit error sound
                    ClientCommand(clientIndex, "play buttons/button11.wav");
                    return;
                }
                
                // Gets class name
                ClassGetName(iD, sClassName, sizeof(sClassName));
                
                // If help messages enabled, then show info
                if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintToChat(clientIndex, "class info", sClassName, ClassGetHealth(iD), ClassGetArmor(iD), ClassGetSpeed(iD));
            }
        }
    }
}

/**
 * @brief Creates the classes menu. (admin)
 *
 * @param clientIndex       The client index.
 **/
void ClassesMenu(const int clientIndex) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Validate access
    if(!gServerData.RoundStart)
    {
        // Show block info
        TranslationPrintHintText(clientIndex, "classes round block"); 

        // Emit error sound
        ClientCommand(clientIndex, "play buttons/button11.wav");
        return;
    }
    
    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sType[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];
    
    // Creates menu handle
    Menu hMenu = CreateMenu(ClassesMenuSlots);
    
    // Sets language to target
    SetGlobalTransTarget(clientIndex);

    // Sets title
    hMenu.SetTitle("%t", "classes menu");

    // i = client index
    int iCount;
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(!IsPlayerExist(i, false))
        {
            continue;
        }

        // Gets class data
        ClassGetType(gClientData[i].Class, sType, sizeof(sType));
        
        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%N [%t]", i, IsPlayerAlive(i) ? sType : "dead");

        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer);

        // Increment count
        iCount++;
    }
    
    // If there are no clients, add an "(Empty)" line
    if(!iCount)
    {
        // Format some chars for showing in menu
        Format(sBuffer, sizeof(sBuffer), "%t", "empty");
        hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the classes menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassesMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{   
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hMenu;
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Opens menu back
                int iD[2]; iD = MenusCommandToArray("zp_class_menu");
                if(iD[0] != -1) SubMenu(clientIndex, iD[0]);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }
            
            // If mode doesn't started yet, then stop
            if(!gServerData.RoundStart)
            {
                // Show block info
                TranslationPrintHintText(clientIndex, "using menu block");
        
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }
            
            // Initialize key char
            static char sKey[SMALL_LINE_LENGTH];

            // Gets menu info
            hMenu.GetItem(mSlot, sKey, sizeof(sKey));
            int targetIndex = StringToInt(sKey);
            
            // Validate target
            if(IsPlayerExist(targetIndex, false))
            {
                // Validate dead
                if(!IsPlayerAlive(targetIndex))
                {
                    // Force client to respawn
                    ToolsForceToRespawn(targetIndex);
                }
                else
                {
                    // Creates a option menu
                    ClassesOptionMenu(clientIndex, targetIndex);
                    return;
                }
            }
            else
            {
                // Show block info
                TranslationPrintHintText(clientIndex, "selecting target block");
                    
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav"); 
            }

            // Opens classes menu back
            ClassesMenu(clientIndex);
        }
    }
}

/**
 * @brief Creates a classes option menu.
 *
 * @param clientIndex       The client index.
 * @param targetIndex       The target index.
 **/
void ClassesOptionMenu(const int clientIndex, const int targetIndex)
{
    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH]; 
    static char sType[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];
    
    // Creates menu handle
    Menu hMenu = CreateMenu(ClassesListMenuSlots);
    
    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%N", targetIndex);
    
    // i = array index
    int iSize = gServerData.Types.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets type data
        gServerData.Types.GetString(i, sType, sizeof(sType));
        
        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%t", sType);
        
        // Show option
        FormatEx(sInfo, sizeof(sInfo), "%s:%d", sType, targetIndex);
        hMenu.AddItem(sInfo, sBuffer);
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iSize)
    {
        // Format some chars for showing in menu
        Format(sBuffer, sizeof(sBuffer), "%t", "empty");
        hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}   

/**
 * @brief Called when client selects option in the classes option menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ClassesListMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{   
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hMenu;
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Opens classes menu back
                ClassesMenu(clientIndex);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }
            
            // If mode doesn't started yet, then stop
            if(!gServerData.RoundStart)
            {
                // Show block info
                TranslationPrintHintText(clientIndex, "using menu block");
        
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }
            
            // Initialize type char
            static char sClassType[SMALL_LINE_LENGTH];
        
            // Gets menu info
            hMenu.GetItem(mSlot, sClassType, sizeof(sClassType));
            static char sInfo[2][SMALL_LINE_LENGTH];
            ExplodeString(sClassType, ":", sInfo, sizeof(sInfo), sizeof(sInfo[]));
            int targetIndex = StringToInt(sInfo[1]);

            // Validate target
            if(IsPlayerExist(targetIndex))
            {
                // Force client to update
                ApplyOnClientUpdate(targetIndex, _, sInfo[0]);
                
                // Log action to game events
                LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_GameModes, "Command", "Admin \"%N\" changed a class for Player \"%N\" to \"%s\"", clientIndex, targetIndex, sInfo[0]);
            }
            else
            {
                // Show block info
                TranslationPrintHintText(clientIndex, "selecting target block");
                    
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");  
            }
            
            // Opens classes menu back
            ClassesMenu(clientIndex);
        }
    }
}