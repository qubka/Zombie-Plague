/**
 * ============================================================================
 *
 *   Plague
 *
 *  File:          classmenus.cpp
 *  Type:          Manager 
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
 * Creates commands for classes module.
 **/
void ClassMenusOnCommandsCreate(/*void*/)
{
    // Hook commands
    //RegConsoleCmd("zp_human_menu", ClassHumanCommandCatched, "Open the human classes menu.");
    //RegConsoleCmd("zp_zombie_menu", ClassZombieCommandCatched, "Open the zombie classes menu.");
}

/**
 * Handles the <!zp_human_menu> command. Open the human classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
/*public Action ClassHumanCommandCatched(const int clientIndex, const int iArguments)
{
    Menu(clientIndex);
    return Plugin_Handled;
}*/

/**
 * Handles the <!zp_zombie_menu> command. Open the zombie classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
/*public Action ClassZombieCommandCatched(const int clientIndex, const int iArguments)
{
    Menu(clientIndex);
    return Plugin_Handled;
}*/

/**
 * Validate zombie class for client availability.
 *
 * @param clientIndex       The client index.
 **/
/*void ZombieOnValidate(const int clientIndex)
{
    // Gets array size
    int iSize = arrayZombieClasses.Length;

    // Choose random zombie class for the client
    if(IsFakeClient(clientIndex) || iSize <= gClientData[clientIndex][Client_Class])
    {
        gClientData[clientIndex][Client_Class] = GetRandomInt(0, iSize-1);
    }
    
    // Gets class group
    static char sGroup[SMALL_LINE_LENGTH];
    ZombieGetGroup(gClientData[clientIndex][Client_Class], sGroup, sizeof(sGroup));
    
    // Validate that user does not have VIP flag to play it
    if(!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup))
    {
        // Choose any accessable zombie class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable zombie classes
            ZombieGetGroup(i, sGroup, sizeof(sGroup));
            if(!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup))
            {
                continue;
            }
            
            // Update zombie class
            gClientData[clientIndex][Client_ZombieClassNext]  = i;
            gClientData[clientIndex][Client_Class] = i;
            break;
        }
    }
    
    // Validate that user does not have level to play it
    if(ZombieGetLevel(gClientData[clientIndex][Client_Class]) > gClientData[clientIndex][Client_Level])
    {
        // Choose any accessable zombie class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable zombie classes
            if(ZombieGetLevel(i) > gClientData[clientIndex][Client_Level])
            {
                continue;
            }
            
            // Update zombie class
            gClientData[clientIndex][Client_ZombieClassNext]  = i;
            gClientData[clientIndex][Client_Class] = i;
            break;
        }
    }
}*/

/**
 * Create the zombie class menu.
 *
 * @param clientIndex       The client index.
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/
/*void ZombieMenu(const int clientIndex, const bool bInstant = false) 
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

    // Create menu handle
    Menu hMenu = CreateMenu(bInstant ? ZombieMenuSlots2 : ZombieMenuSlots1);

    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "choose zombieclass");
    
    // Initialize forward
    static Action resultHandle;
    
    // i = zombieclass index
    int iCount = arrayZombieClasses.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Call forward
        resultHandle = API_OnClientValidateZombieClass(clientIndex, i);
        
        // Skip, if class is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Gets zombie class data
        ZombieGetName(i, sName, sizeof(sName));
        ZombieGetGroup(i, sGroup, sizeof(sGroup));

        // Format some chars for showing in menu
        FormatEx(sLevel, sizeof(sLevel), "%t", "level", ZombieGetLevel(i));
        FormatEx(sBuffer, sizeof(sBuffer), "%t\t%s", sName, (!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup)) ? sGroup : (gClientData[clientIndex][Client_Level] < ZombieGetLevel(i)) ? sLevel : "");
        
        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(resultHandle == Plugin_Handled || ((!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup)) || gClientData[clientIndex][Client_Level] < ZombieGetLevel(i) || gClientData[clientIndex][Client_ZombieClassNext] == i) ? false : true));
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, bInstant ? MENU_TIME_INSTANT : MENU_TIME_FOREVER); 
}*/

/**
 * Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
/*public int ZombieMenuSlots1(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ZombieMenuSlots(hMenu, mAction, clientIndex, mSlot);
}*/

/**
 * Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
/*public int ZombieMenuSlots2(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   ZombieMenuSlots(hMenu, mAction, clientIndex, mSlot, true);
}*/

/**
 * Called when client selects option in the zombie class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/ 
/*void ZombieMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot, const bool bInstant = false)
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
                // Open main menu back
                MenuMain(clientIndex);
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

            // Initialize info char
            static char sZombieName[SMALL_LINE_LENGTH];

            // Gets menu info
            hMenu.GetItem(mSlot, sZombieName, sizeof(sZombieName));
            int iD = StringToInt(sZombieName);
            
            // Call forward
            Action resultHandle = API_OnClientValidateZombieClass(clientIndex, iD);

            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Validate instant change
                if(bInstant)
                {
                    // Force client to switch player class
                    ClassMakeZombie(clientIndex, _, _, true);
                }
                else
                {
                    // Sets next zombie class
                    gClientData[clientIndex][Client_ZombieClassNext] = iD;
                }
                
                // Gets zombie name
                ZombieGetName(iD, sZombieName, sizeof(sZombieName));

                // If help messages enabled, show info
                if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintToChat(clientIndex, "zombie info", sZombieName, ZombieGetHealth(iD), ZombieGetSpeed(iD), ZombieGetGravity(iD));
            }
        }
    }
}
*/

/**
 * Validate human class for client availability.
 *
 * @param clientIndex       The client index.
 **/
/*void HumanOnValidate(const int clientIndex)
{
    // Gets array size
    int iSize = arrayHumanClasses.Length;

    // Choose random human class for the client
    if(IsFakeClient(clientIndex) || iSize <= gClientData[clientIndex][Client_Class])
    {
        gClientData[clientIndex][Client_Class] = GetRandomInt(0, iSize-1);
    }

    // Gets class group
    static char sGroup[SMALL_LINE_LENGTH];
    HumanGetGroup(gClientData[clientIndex][Client_Class], sGroup, sizeof(sGroup));

    // Validate that user does not have VIP flag to play it
    if(!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup))
    {
        // Choose any accessable human class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable human classes
            HumanGetGroup(i, sGroup, sizeof(sGroup));
            if(!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup))
            {
                continue;
            }
            
            // Update human class
            gClientData[clientIndex][Client_HumanClassNext] = i;
            gClientData[clientIndex][Client_Class] = i;
            break;
        }
    }
    
    // Validate that user does not have level to play it
    if(HumanGetLevel(gClientData[clientIndex][Client_Class]) > gClientData[clientIndex][Client_Level])
    {
        // Choose any accessable human class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable human classes
            if(HumanGetLevel(i) > gClientData[clientIndex][Client_Level])
            {
                continue;
            }
            
            // Update human class
            gClientData[clientIndex][Client_HumanClassNext] = i;
            gClientData[clientIndex][Client_Class] = i;
            break;
        }
    }
}
*/

/**
 * Create the human class menu.
 *
 * @param clientIndex       The client index.
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/
/*void HumanMenu(const int clientIndex, const bool bInstant = false) 
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
    
    // Create menu handle
    Menu hMenu = CreateMenu(bInstant ? HumanMenuSlots2 : HumanMenuSlots1);

    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "choose humanclass");
    
    // Initialize forward
    static Action resultHandle;
    
    // i = humanclass index
    int iCount = arrayHumanClasses.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Call forward
        resultHandle = API_OnClientValidateHumanClass(clientIndex, i);
        
        // Skip, if class is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Gets human class data
        HumanGetName(i, sName, sizeof(sName));
        HumanGetGroup(i, sGroup, sizeof(sGroup));
        
        // Format some chars for showing in menu
        FormatEx(sLevel, sizeof(sLevel), "%t", "level", HumanGetLevel(i));
        FormatEx(sBuffer, sizeof(sBuffer), "%t\t%s", sName, (!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup)) ? sGroup : (gClientData[clientIndex][Client_Level] < HumanGetLevel(i)) ? sLevel : "");

        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(resultHandle == Plugin_Handled || ((!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup)) || gClientData[clientIndex][Client_Level] < HumanGetLevel(i) || gClientData[clientIndex][Client_HumanClassNext] == i) ? false : true));
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, bInstant ? MENU_TIME_INSTANT : MENU_TIME_FOREVER); 
}*/

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
/*public int HumanMenuSlots1(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   HumanMenuSlots(hMenu, mAction, clientIndex, mSlot);
}*/

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
/*public int HumanMenuSlots2(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
   // Call menu
   HumanMenuSlots(hMenu, mAction, clientIndex, mSlot, true);
}*/

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 * @param bInstant          (Optional) True to set the class instantly, false to set it on the next class change.
 **/ 
/*void HumanMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot, const bool bInstant = false)
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
                // Open main menu back
                MenuMain(clientIndex);
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
            static char sHumanName[SMALL_LINE_LENGTH];

            // Gets menu info
            hMenu.GetItem(mSlot, sHumanName, sizeof(sHumanName));
            int iD = StringToInt(sHumanName);
            
            // Call forward
            Action resultHandle = API_OnClientValidateHumanClass(clientIndex, iD);

            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Validate instant change
                if(bInstant)
                {
                    // Force client to switch player class
                    ClassMakeHuman(clientIndex, _, true);
                }
                else
                {
                    // Sets next human class
                    gClientData[clientIndex][Client_HumanClassNext] = iD;
                }
                
                // Gets human name
                HumanGetName(iD, sHumanName, sizeof(sHumanName));
                
                // If help messages enabled, show info
                if(gCvarList[CVAR_MESSAGES_HELP].BoolValue) TranslationPrintToChat(clientIndex, "human info", sHumanName, HumanGetHealth(iD), HumanGetSpeed(iD), HumanGetGravity(iD));
            }
        }
    }
}*/