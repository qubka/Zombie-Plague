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
public Action ZMarketCommandCatched(int clientIndex, int iArguments)
{
    // Open the weapon menu
    ZMarketMenu(clientIndex);
}

/**
 * Client has been changed class state. (Post)
 * 
 * @param clientIndex       The client index.
 **/
void ZMarketOnClientUpdate(int clientIndex)
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
void ZMarketMenu(int clientIndex) 
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
    hMenu.SetTitle("%t", "Buy weapons");

    // Initialize char
    static char sBuffer[NORMAL_LINE_LENGTH];

    // Gets auto-rebuy setting
    static char sRebuy[SMALL_LINE_LENGTH];
    ConfigBoolToSetting(gClientData[clientIndex][Client_AutoRebuy], sRebuy, sizeof(sRebuy), false, clientIndex);

    // Show rebuy button
    Format(sBuffer, sizeof(sBuffer), "%t", "Auto-Rebuy", sRebuy);
    hMenu.AddItem("1", sBuffer);

    // Show pistol list
    Format(sBuffer, sizeof(sBuffer), "%t", "Buy pistols");
    hMenu.AddItem("2", sBuffer);

    // Show shotgun list
    Format(sBuffer, sizeof(sBuffer), "%t", "Buy shothuns");
    hMenu.AddItem("3", sBuffer);

    // Show rifle list
    Format(sBuffer, sizeof(sBuffer), "%t", "Buy rifles");
    hMenu.AddItem("4", sBuffer);

    // Show sniper list
    Format(sBuffer, sizeof(sBuffer), "%t", "Buy snipers");
    hMenu.AddItem("5", sBuffer);

    // Show machinegun list
    Format(sBuffer, sizeof(sBuffer), "%t", "Buy machinehuns");
    hMenu.AddItem("6", sBuffer);

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
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
public int ZMarketMenuSlots(Menu hMenu, MenuAction mAction, int clientIndex, int mSlot)
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
                    // Initialize chars
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
void ZMarketSubMenu(int clientIndex, char[] sTitle, int mSlot = 0) 
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
    
    // Initialize chars
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sName[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];

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
            if(WeaponsGetSlot(i) != mSlot)
                continue;
        
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

            // Gets weapon name
            WeaponsGetName(i, sName, sizeof(sName));
            if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
            
            // Format some chars for showing in menu
            Format(sBuffer, sizeof(sBuffer), (WeaponsGetCost(i)) ? "%s    %t" : "%s", sName, "Price", WeaponsGetCost(i), "Ammopack");

            // Show option
            IntToString(i, sInfo, sizeof(sInfo));
            hSubMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw((WeaponsIsExist(clientIndex, i) || gClientData[clientIndex][Client_Level] < WeaponsGetLevel(i) || fnGetPlaying() < WeaponsGetOnline(i) || gClientData[clientIndex][Client_AmmoPacks] < WeaponsGetCost(i)) ? false : true));
        }
    }
    // Otherwise open rebuy menu
    else
    {
        // i = array number
        iCount = arrayShoppingList[clientIndex].Length;
        for(int i = 0; i < iCount; i++)
        {
            // Gets the weapon index from the list
            int iD = arrayShoppingList[clientIndex].Get(i);
        
            // Gets weapon name
            WeaponsGetName(iD, sName, sizeof(sName));
            if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
            
            // Format some chars for showing in menu
            Format(sBuffer, sizeof(sBuffer), (WeaponsGetCost(iD)) ? "%s    %t" : "%s", sName, "Price", WeaponsGetCost(iD), "Ammopack");

            // Show option
            IntToString(iD, sInfo, sizeof(sInfo));
            hSubMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw((WeaponsIsExist(clientIndex, iD) || gClientData[clientIndex][Client_Level] < WeaponsGetLevel(iD) || fnGetPlaying() < WeaponsGetOnline(iD) || gClientData[clientIndex][Client_AmmoPacks] < WeaponsGetCost(iD)) ? false : true));
        }
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iCount)
    {
        static char sEmpty[SMALL_LINE_LENGTH];
        Format(sEmpty, sizeof(sEmpty), "%t", "Empty");

        hSubMenu.AddItem("empty", sEmpty, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hSubMenu.ExitBackButton = true;

    // Sets options and display it
    hSubMenu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
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
public int ZMarketMenuSubSlots(Menu hSubMenu, MenuAction mAction, int clientIndex, int mSlot)
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

            // Initialize char
            static char sWeaponName[SMALL_LINE_LENGTH];

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

            // Gets weapon alias
            WeaponsGetEntity(iD, sWeaponName, sizeof(sWeaponName));
            
            // If client have this weapon
            if(WeaponsIsExist(clientIndex, iD))
            {
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }
            
            // Force client to drop weapon
            if(!!strcmp(sWeaponName[7], "taser", false))
            {
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
                }
            }
        }
    }
}

/**
 * Rebuys weapons if auto-rebuy is enabled and player is a human (alive).
 *
 * @param clientIndex       The client index.
 **/
bool ZMarketRebuyMenu(int clientIndex)
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
    int iSize = arrayShoppingList[clientIndex].Length;
    if(!iSize)
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
    Format(sTitle, sizeof(sTitle), "%t", "Rebuy");

    // Open weapon sub menu
    ZMarketSubMenu(clientIndex, sTitle);
    return true;
}

/**
 * Reset the purchase count(s) for a client.
 * 
 * @param clientIndex       The client index.
 **/
void ZMarketResetPurchaseCount(int clientIndex)
{
    // Clear out the array of all data
    if(arrayShoppingList[clientIndex] != INVALID_HANDLE)
    {
        arrayShoppingList[clientIndex].Clear();
    }
}
