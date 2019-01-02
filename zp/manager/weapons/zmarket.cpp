/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          zmarket.cpp
 *  Type:          Module
 *  Description:   ZMarket module, provides menu of weapons to buy from.
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
 * Array handle to store the amount of purchases of a last round.
 **/
ArrayList arrayShoppingList[MAXPLAYERS+1];

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
 * Creates commands for market module.
 **/
void ZMarketOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zp_rebuy_menu", ZMarketRebuyCommandCatched, "Change the rebuy state.");
    RegConsoleCmd("zp_pistol_menu", ZMarketPistolsCommandCatched, "Open the pistol menu.");
    RegConsoleCmd("zp_shotgun_menu", ZMarketShotgunsCommandCatched, "Open the shotgun menu.");
    RegConsoleCmd("zp_rifle_menu", ZMarketRiflesCommandCatched, "Open the rifle menu.");
    RegConsoleCmd("zp_sniper_menu", ZMarketSnipersCommandCatched, "Open the sniper menu.");
    RegConsoleCmd("zp_machinegun_menu", ZMarketMachinegunsCommandCatched, "Open the machinegun menu.");
    RegConsoleCmd("zp_knife_menu", ZMarketKnifesCommandCatched, "Open the knife menu.");
}

/**
 * Handles the <!zp_rebuy_menu> command. Change the rebuy state.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRebuyCommandCatched(const int clientIndex, const int iArguments)
{
    gClientData[clientIndex][Client_AutoRebuy] = !gClientData[clientIndex][Client_AutoRebuy]; 
    MenuSub(clientIndex, MenusNameToIndex("buy weapons"));
    return Plugin_Handled;
}

/**
 * Handles the <!zp_pistols_menu> command. Open the pistols menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketPistolsCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy pistols", MenuType_Pistols); 
    return Plugin_Handled;
}

/**
 * Handles the <!zp_shotguns_menu> command. Open the shotguns menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketShotgunsCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy shotguns", MenuType_Shotguns); 
    return Plugin_Handled;
}

/**
 * Handles the <!zp_rifles_menu> command. Open the rifles menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRiflesCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy rifles", MenuType_Rifles); 
    return Plugin_Handled;
}

/**
 * Handles the <!zp_snipers_menu> command. Open the snipers menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketSnipersCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy snipers", MenuType_Snipers); 
    return Plugin_Handled;
}

/**
 * Handles the <!zp_machineguns_menu> command. Open the machineguns menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketMachinegunsCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy machineguns", MenuType_Machineguns); 
    return Plugin_Handled;
}

/**
 * Handles the <!zp_knifes_menu> command. Open the knifes menu.
 * 
 * @param clientIndex        The client index.
 * @param iArguments         The number of arguments that were in the argument string.
 **/ 
public Action ZMarketKnifesCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy knifes", MenuType_Knifes); 
    return Plugin_Handled;
}

/**
 * Create the weapons menu.
 *
 * @param clientIndex       The client index.
 * @param sTitle            The menu title.
 * @param mSlot             The slot index selected. (starting from 0)
 **/
void ZMarketMenu(const int clientIndex, const char[] sTitle, const MenuType mSlot = MenuType_Invisible) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Validate access
    if(gServerData[Server_RoundStart] && !ModesIsWeapon(gServerData[Server_RoundMode]))
    {
        // Show block info
        TranslationPrintHintText(clientIndex, "round block"); 

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
    Menu hMenu = CreateMenu(ZMarketMenuSlots);
    
    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Format title for showing in menu
    FormatEx(sBuffer, sizeof(sBuffer), "%t", sTitle);
    
    // Sets title
    hMenu.SetTitle(sBuffer);
    
    // Open weapon menu
    if(mSlot)
    {
        // i = weapon index
        iCount = arrayWeapons.Length;
        for(int i = 0; i < iCount; i++)
        {
            // Skip some weapons, if slot isn't equal
            if(WeaponsGetSlot(i) != mSlot) continue;

            // Skip some weapons, if class isn't equal
            if(!WeaponsValidateClass(clientIndex, i)) continue;

            // Gets weapon data
            WeaponsGetName(i, sName, sizeof(sName));
            WeaponsGetGroup(i, sGroup, sizeof(sGroup));
            
            // Format some chars for showing in menu
            FormatEx(sLevel, sizeof(sLevel), "%t", "level", WeaponsGetLevel(i));
            FormatEx(sOnline, sizeof(sOnline), "%t", "online", WeaponsGetOnline(i));      
            FormatEx(sBuffer, sizeof(sBuffer), (WeaponsGetCost(i)) ? "%t\t%s\t%t" : "%t\t%s", sName, hasLength(sGroup) ? sGroup : (gClientData[clientIndex][Client_Level] < WeaponsGetLevel(i)) ? sLevel : (fnGetPlaying() < WeaponsGetOnline(i)) ? sOnline : "", "price", WeaponsGetCost(i), "money");
   
            // Show option
            IntToString(i, sInfo, sizeof(sInfo));
            hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw((!IsPlayerInGroup(clientIndex, sGroup) && hasLength(sGroup)) || (WeaponsIsExist(clientIndex, i) || gClientData[clientIndex][Client_Level] < WeaponsGetLevel(i) || fnGetPlaying() < WeaponsGetOnline(i) || gClientData[clientIndex][Client_Money] < WeaponsGetCost(i)) ? false : true));
        }
    }
    // Open rebuy menu
    else
    {
        // i = array number
        iCount = arrayShoppingList[clientIndex].Length;
        for(int i = 0; i < iCount; i++)
        {
            // Gets weapon id from the list
            int iD = arrayShoppingList[clientIndex].Get(i);
            
            // Skip some weapons, if class isn't equal
            if(!WeaponsValidateClass(clientIndex, iD)) continue;
        
            // Gets weapon name
            WeaponsGetName(iD, sName, sizeof(sName));

            // Format some chars for showing in menu
            FormatEx(sBuffer, sizeof(sBuffer), (WeaponsGetCost(iD)) ? "%t\t%t" : "%s", sName, "price", WeaponsGetCost(iD), "money");

            // Show option
            IntToString(iD, sInfo, sizeof(sInfo));
            hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw((WeaponsIsExist(clientIndex, iD) || gClientData[clientIndex][Client_Level] < WeaponsGetLevel(iD) || fnGetPlaying() < WeaponsGetOnline(iD) || gClientData[clientIndex][Client_Money] < WeaponsGetCost(iD)) ? false : true));
        }
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iCount)
    {
        static char sEmpty[SMALL_LINE_LENGTH];
        FormatEx(sEmpty, sizeof(sEmpty), "%t", "empty");

        hMenu.AddItem("empty", sEmpty, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the shop menu, and handles it.
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
                // Open weapon menu back
                MenuSub(clientIndex, MenusNameToIndex("buy weapons"));
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
            
            // Validate access
            if((gServerData[Server_RoundStart] && !ModesIsWeapon(gServerData[Server_RoundMode])) || gServerData[Server_RoundEnd])
            {
                // Show block info
                TranslationPrintHintText(clientIndex, "round block");
        
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }

            // Initialize name char
            static char sWeaponName[BIG_LINE_LENGTH];

            // Gets menu info
            hMenu.GetItem(mSlot, sWeaponName, sizeof(sWeaponName));
            int iD = StringToInt(sWeaponName);

            // Validate access
            if(WeaponsIsExist(clientIndex, iD) || !WeaponsValidateClass(clientIndex, iD))
            {
                // Gets weapon name
                WeaponsGetName(iD, sWeaponName, sizeof(sWeaponName));    
        
                // Show weapon block info
                TranslationPrintHintText(clientIndex, "buying block", sWeaponName);
        
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }
            
            // Gets weapon classname
            WeaponsGetEntity(iD, sWeaponName, sizeof(sWeaponName));

            // Validate primary/secondary weapon
            if(!!strcmp(sWeaponName[7], "taser", false))
            {
                // Drop weapon
                WeaponsDrop(clientIndex, GetPlayerWeaponSlot(clientIndex, (WeaponsGetSlot(iD) == MenuType_Pistols) ? view_as<int>(SlotType_Secondary) : ((WeaponsGetSlot(iD) == MenuType_Knifes) ? view_as<int>(SlotType_Melee) : view_as<int>(SlotType_Primary))));
            }

            // Give weapon for the player
            if(WeaponsGive(clientIndex, iD) != INVALID_ENT_REFERENCE)
            {
                // If weapon has a cost
                if(WeaponsGetCost(iD))
                {
                    // Remove money and store it for returning if player will be first zombie
                    AccountSetClientCash(clientIndex, gClientData[clientIndex][Client_Money] - WeaponsGetCost(iD));
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
                        if(hasLength(sWeaponName)) TranslationPrintHintText(clientIndex, sWeaponName);
                    }
                }
            }
            else
            {
                // Gets weapon name
                WeaponsGetName(iD, sWeaponName, sizeof(sWeaponName));    
        
                // Show weapon block info
                TranslationPrintHintText(clientIndex, "buying block", sWeaponName);
                
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

    // Open weapons menu
    ZMarketMenu(clientIndex, "rebuy");
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