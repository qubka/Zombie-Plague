/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          zmarket.cpp
 *  Type:          Module
 *  Description:   ZMarket module, provides menu of weapons to buy from.
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
 * Array handle to store the amount of purchases of a last round.
 **/
ArrayList arrayShoppingList[MAXPLAYERS+1];

/**
 * Create commands specific to ZMarket. Called when commands are created.
 **/
void ZMarketOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zweaponmenu", ZMarketCommandCatched, "Open the weapons menu.");
}

/**
 * Handles the <!zweaponmenu> command. Open the weapons menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketCommandCatched(const int clientIndex, const int iArguments)
{
    // Open the weapon menu
    ZMarketMenu(clientIndex);
    return Plugin_Handled;
}

/**
 * Client has been changed class state. (Post)
 * 
 * @param clientIndex       The client index.
 **/
void ZMarketOnClientUpdate(const int clientIndex)
{
    // Resets purchase counts for client
    if(ZMarketRebuyMenu(clientIndex))
    {
        // Rebuy if auto-rebuy is enabled
        ZMarketResetPurchaseCount(clientIndex);
    }
}

/**
 * Create the weapons menu.
 *
 * @param clientIndex       The client index.
 **/
void ZMarketMenu(const int clientIndex) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Initialize menu
    Menu hMenu = CreateMenu(ZMarketMenuSlots);

    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "buy weapons");

    // Initialize variable
    static char sBuffer[NORMAL_LINE_LENGTH];

    // Gets auto-rebuy setting
    static char sRebuy[SMALL_LINE_LENGTH];
    ConfigBoolToSetting(gClientData[clientIndex][Client_AutoRebuy], sRebuy, sizeof(sRebuy), false, clientIndex);

    // Show rebuy button
    Format(sBuffer, sizeof(sBuffer), "%t", "auto rebuy", sRebuy);
    hMenu.AddItem("1", sBuffer);

    // Show pistol list
    Format(sBuffer, sizeof(sBuffer), "%t", "buy pistols");
    hMenu.AddItem("2", sBuffer);

    // Show shotgun list
    Format(sBuffer, sizeof(sBuffer), "%t", "buy shothuns");
    hMenu.AddItem("3", sBuffer);

    // Show rifle list
    Format(sBuffer, sizeof(sBuffer), "%t", "buy rifles");
    hMenu.AddItem("4", sBuffer);

    // Show sniper list
    Format(sBuffer, sizeof(sBuffer), "%t", "buy snipers");
    hMenu.AddItem("5", sBuffer);

    // Show machinegun list
    Format(sBuffer, sizeof(sBuffer), "%t", "buy machinehuns");
    hMenu.AddItem("6", sBuffer);
    
    // Show knife list
    Format(sBuffer, sizeof(sBuffer), "%t", "buy knifes");
    hMenu.AddItem("7", sBuffer);

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the weapons menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
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
            switch(mSlot)
            {
                // Auto-rebuy
                case 0 : 
                { 
                    // If auto-rebuy is enabled, then force client to disable rebuy
                    gClientData[clientIndex][Client_AutoRebuy] = !gClientData[clientIndex][Client_AutoRebuy]; 
                    
                    // Open the weapon menu with updated state
                    ZMarketMenu(clientIndex);  
                }
                
                // Weapons list
                default: 
                { 
                    // Initialize variables
                    static char sTitle[SMALL_LINE_LENGTH];
                    static char sInfo[SMALL_LINE_LENGTH];
                    
                    // Gets name of the slot (Convert the slot into the new sub title)
                    hMenu.GetItem(mSlot, sInfo, sizeof(sInfo), _, sTitle, sizeof(sTitle));
                
                    // Open weapon sub menu
                    ZMarketSubMenu(clientIndex, sTitle, mSlot); 
                }
            }
        }
    }
}

/**
 * Create the sub weapons menu.
 *
 * @param clientIndex       The client index.
 * @param sTitle            The menu title.
 * @param mSlot             The slot index selected. (starting from 0)
 **/
void ZMarketSubMenu(const int clientIndex, const char[] sTitle, const int mSlot = 0) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // If client is survivor or nemesis/zombie, then stop 
    if(gClientData[clientIndex][Client_Zombie] || gClientData[clientIndex][Client_Survivor])
    {
        // Emit error sound
        ClientCommand(clientIndex, "play buttons/button11.wav");
        return;
    }
    
    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sName[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];
    static char sLevel[SMALL_LINE_LENGTH];
    static char sOnline[SMALL_LINE_LENGTH];
    static char sGroup[SMALL_LINE_LENGTH];

    // Initialize counter
    static int iCount;
    
    // Create menu handle
    Menu hSubMenu = CreateMenu(ZMarketMenuSubSlots);
    
    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hSubMenu.SetTitle(sTitle);
    
    // Open weapon menu
    if(mSlot)
    {
        // i = weapon number
        iCount = arrayWeapons.Length;
        for(int i = 0; i < iCount; i++)
        {
            // Skip some weapons, if slot isn't equal
            if(WeaponsGetSlot(i) != mSlot) continue;

            // Skip some weapons, if class isn't equal
            switch(WeaponsGetClass(i))
            {
                // Validate human class
                case ClassType_Human : if(!(!gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Survivor]))   continue;
                
                // Validate survivor class
                case ClassType_Survivor : if(!(!gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Survivor])) continue;
                
                // Validate zombie class
                case ClassType_Zombie : if(!(gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Nemesis]))    continue;
                
                // Validate nemesis class
                case ClassType_Nemesis : if(!(gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Nemesis]))    continue;
            
                // Validate invalid class
                default: continue;
            }

            // Gets weapon data
            WeaponsGetName(i, sName, sizeof(sName));
            WeaponsGetGroup(i, sGroup, sizeof(sGroup));
            
            // Format some chars for showing in menu
            Format(sLevel, sizeof(sLevel), "%t", "level", WeaponsGetLevel(i));
            Format(sOnline, sizeof(sOnline), "%t", "online", WeaponsGetOnline(i));      
            Format(sBuffer, sizeof(sBuffer), (WeaponsGetCost(i)) ? "%t\t%s\t%t" : "%t\t%s", sName, strlen(sGroup) ? sGroup : (gClientData[clientIndex][Client_Level] < WeaponsGetLevel(i)) ? sLevel : (fnGetPlaying() < WeaponsGetOnline(i)) ? sOnline : "", "price", WeaponsGetCost(i), "ammopack");
   
            // Show option
            IntToString(i, sInfo, sizeof(sInfo));
            hSubMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw((!IsPlayerInGroup(clientIndex, sGroup) && strlen(sGroup)) || (WeaponsIsExist(clientIndex, i) || gClientData[clientIndex][Client_Level] < WeaponsGetLevel(i) || fnGetPlaying() < WeaponsGetOnline(i) || gClientData[clientIndex][Client_AmmoPacks] < WeaponsGetCost(i)) ? false : true));
        }
    }
    // Otherwise open rebuy menu
    else
    {
        // i = array number
        iCount = arrayShoppingList[clientIndex].Length;
        for(int i = 0; i < iCount; i++)
        {
            // Gets weapon id from the list
            int iD = arrayShoppingList[clientIndex].Get(i);
        
            // Gets weapon name
            WeaponsGetName(iD, sName, sizeof(sName));

            // Format some chars for showing in menu
            Format(sBuffer, sizeof(sBuffer), (WeaponsGetCost(iD)) ? "%t\t%t" : "%s", sName, "price", WeaponsGetCost(iD), "ammopack");

            // Show option
            IntToString(iD, sInfo, sizeof(sInfo));
            hSubMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw((WeaponsIsExist(clientIndex, iD) || gClientData[clientIndex][Client_Level] < WeaponsGetLevel(iD) || fnGetPlaying() < WeaponsGetOnline(iD) || gClientData[clientIndex][Client_AmmoPacks] < WeaponsGetCost(iD)) ? false : true));
        }
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iCount)
    {
        static char sEmpty[SMALL_LINE_LENGTH];
        Format(sEmpty, sizeof(sEmpty), "%t", "empty");

        hSubMenu.AddItem("empty", sEmpty, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hSubMenu.ExitBackButton = true;

    // Sets options and display it
    hSubMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hSubMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the shop menu, and handles it.
 *  
 * @param hSubMenu          The handle of the sub menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ZMarketMenuSubSlots(Menu hSubMenu, MenuAction mAction, const int clientIndex, const int mSlot)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hSubMenu;
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Open weapon menu back
                ZMarketMenu(clientIndex);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex))
            {
                return;
            }

            // Initialize variable
            static char sWeaponName[BIG_LINE_LENGTH];

            // Gets ID of the weapon
            hSubMenu.GetItem(mSlot, sWeaponName, sizeof(sWeaponName));
            int iD = StringToInt(sWeaponName);

            // if class isn't equal, then stop
            switch(WeaponsGetClass(iD))
            {
                // Validate human class
                case ClassType_Human : if(!(!gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Survivor]))   return;
                
                // Validate survivor class
                case ClassType_Survivor : if(!(!gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Survivor])) return;
                
                // Validate zombie class
                case ClassType_Zombie : if(!(gClientData[clientIndex][Client_Zombie] && !gClientData[clientIndex][Client_Nemesis]))    return;
                
                // Validate nemesis class
                case ClassType_Nemesis : if(!(gClientData[clientIndex][Client_Zombie] && gClientData[clientIndex][Client_Nemesis]))    return;
            
                // Validate invalid class
                default: return;
            }

            // Gets weapon classname
            WeaponsGetEntity(iD, sWeaponName, sizeof(sWeaponName));
            
            // Validate existance
            if(WeaponsIsExist(clientIndex, iD))
            {
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }

            // Validate primary/secondary weapon
            if(!!strcmp(sWeaponName[7], "taser", false)) 
            {
                // Drop weapon
                WeaponsDrop(clientIndex, GetPlayerWeaponSlot(clientIndex, (WeaponsGetSlot(iD) == 1) ? view_as<int>(SlotType_Secondary) : view_as<int>(SlotType_Primary)));
            }
            
            // Gets weapon name
            WeaponsGetName(iD, sWeaponName, sizeof(sWeaponName));
            
            // Give weapon for the player
            if(WeaponsGive(clientIndex, sWeaponName) != INVALID_ENT_REFERENCE)
            {
                // If weapon has a cost
                if(WeaponsGetCost(iD))
                {
                    // Remove ammopacks and store it for returning if player will be first zombie
                    AccountSetClientCash(clientIndex, gClientData[clientIndex][Client_AmmoPacks] - WeaponsGetCost(iD));
                    gClientData[clientIndex][Client_LastBoughtAmount] += WeaponsGetCost(iD);
                }

                // Check if the weapon isn't already is listed
                if(arrayShoppingList[clientIndex].FindValue(iD) == -1)
                {
                    // Add weapon to list
                    arrayShoppingList[clientIndex].Push(iD);
                    
                    // If help messages enable, then show 
                    if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
                    {
                        // Gets weapon info
                        WeaponsGetInfo(iD, sWeaponName, sizeof(sWeaponName));
                        
                        // Show weapon personal info
                        if(strlen(sWeaponName)) TranslationPrintHintText(clientIndex, sWeaponName);
                    }
                }
            }
            else
            {
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
            }
        }
    }
}

/**
 * Rebuys weapons if auto-rebuy is enabled and player is a human (alive).
 *
 * @param clientIndex       The client index.
 **/
bool ZMarketRebuyMenu(const int clientIndex)
{
    // If client is survivor or nemesis/zombie, then stop 
    if(gClientData[clientIndex][Client_Zombie] || gClientData[clientIndex][Client_Survivor])
    {
        return false;
    }

    // If array hasn't been created, then create
    if(arrayShoppingList[clientIndex] == INVALID_HANDLE)
    {
        // Create array in handle
        arrayShoppingList[clientIndex] = CreateArray(arrayWeapons.Length);
    }

    // Validate list size
    if(!arrayShoppingList[clientIndex].Length)
    {
        return false;
    }
    
    // If auto-rebuy is disabled, then clear
    if(!gClientData[clientIndex][Client_AutoRebuy])
    {
        return true; //! Reset the shopping list
    }
    
    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Format title for showing in menu
    static char sTitle[SMALL_LINE_LENGTH];
    Format(sTitle, sizeof(sTitle), "%t", "rebuy");

    // Open weapon sub menu
    ZMarketSubMenu(clientIndex, sTitle);
    return true;
}

/**
 * Reset the purchase count(s) for a client.
 * 
 * @param clientIndex       The client index.
 **/
void ZMarketResetPurchaseCount(const int clientIndex)
{
    // Clear out the array of all data
    if(arrayShoppingList[clientIndex] != INVALID_HANDLE)
    {
        arrayShoppingList[clientIndex].Clear();
    }
}