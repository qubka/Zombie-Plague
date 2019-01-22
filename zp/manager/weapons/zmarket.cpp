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
 * @brief Client has been changed class state. *(Post)
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
 * @brief Creates commands for market module.
 **/
 void ZMarketOnCommandInit(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zp_rebuy_menu", ZMarketRebuyOnCommandCatched, "Changes the rebuy state.");
    RegConsoleCmd("zp_pistol_menu", ZMarketPistolsOnCommandCatched, "Opens the pistols menu.");
    RegConsoleCmd("zp_shotgun_menu", ZMarketShotgunsOnCommandCatched, "Opens the shotguns menu.");
    RegConsoleCmd("zp_rifle_menu", ZMarketRiflesOnCommandCatched, "Opens the rifles menu.");
    RegConsoleCmd("zp_sniper_menu", ZMarketSnipersOnCommandCatched, "Opens the snipers menu.");
    RegConsoleCmd("zp_machinegun_menu", ZMarketMachinegunsOnCommandCatched, "Opens the machineguns menu.");
    RegConsoleCmd("zp_knife_menu", ZMarketKnifesOnCommandCatched, "Opens the knifes menu.");
}

/*
 * Market main functions.
 */

/**
 * Console command callback (zp_rebuy_menu)
 * @brief Changes the rebuy state.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRebuyOnCommandCatched(const int clientIndex, const int iArguments)
{
    gClientData[clientIndex].AutoRebuy = !gClientData[clientIndex].AutoRebuy; 
    DataBaseOnClientUpdate(clientIndex, ColumnType_Rebuy);
    int iD[2]; iD = MenusCommandToArray("zp_rebuy_menu");
    if(iD[0] != -1) SubMenu(clientIndex, iD[0]);
    return Plugin_Handled;
}

/**
 * Console command callback (zp_pistols_menu)
 * @brief Opens the pistols menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketPistolsOnCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy pistols", MenuType_Pistols); 
    return Plugin_Handled;
}

/**
 * Console command callback (zp_shotguns_menu)
 * @brief Opens the shotguns menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketShotgunsOnCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy shotguns", MenuType_Shotguns); 
    return Plugin_Handled;
}

/**
 * Console command callback (zp_rifles_menu)
 * @brief Opens the rifles menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRiflesOnCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy rifles", MenuType_Rifles); 
    return Plugin_Handled;
}

/**
 * Console command callback (zp_snipers_menu)
 * @brief Opens the snipers menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketSnipersOnCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy snipers", MenuType_Snipers); 
    return Plugin_Handled;
}

/**
 * Console command callback (zp_machineguns_menu)
 * @brief Opens the machineguns menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketMachinegunsOnCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy machineguns", MenuType_Machineguns); 
    return Plugin_Handled;
}

/**
 * Console command callback (zp_knifes_menu)
 * @brief Opens the knifes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketKnifesOnCommandCatched(const int clientIndex, const int iArguments)
{
    ZMarketMenu(clientIndex, "buy knifes", MenuType_Knifes); 
    return Plugin_Handled;
}

/*
 * Stocks market API.
 */

/**
 * @brief Creates the weapons menu.
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
    if(gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode))
    {
        // Show block info
        TranslationPrintHintText(clientIndex, "buying round block"); 

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

    // Creates menu handle
    Menu hMenu = CreateMenu(ZMarketMenuSlots);
    
    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Format title for showing in menu
    FormatEx(sBuffer, sizeof(sBuffer), "%t", sTitle);
    
    // Sets title
    hMenu.SetTitle(sBuffer);
    
    // Initialize variables
    static Action resultHandle; static int iCount;
    
    // Opens weapon menu
    if(mSlot)
    {
        // i = weapon index
        iCount = gServerData.Weapons.Length;
        for(int i = 0; i < iCount; i++)
        {
            // Call forward
            gForwardData._OnClientValidateWeapon(clientIndex, i, resultHandle);
            
            // Skip, if weapon is disabled
            if(resultHandle == Plugin_Stop)
            {
                continue;
            }
        
            // Skip some weapons, if slot isn't equal
            if(WeaponsGetSlot(i) != mSlot) 
            {
                continue;
            }
            
            // Skip some weapons, if class isn't equal
            if(!WeaponsValidateClass(clientIndex, i)) 
            {
                continue;
            }

            // Gets weapon data
            WeaponsGetName(i, sName, sizeof(sName));
            WeaponsGetGroup(i, sGroup, sizeof(sGroup));
            
            // Format some chars for showing in menu
            FormatEx(sLevel, sizeof(sLevel), "%t", "level", WeaponsGetLevel(i));
            FormatEx(sOnline, sizeof(sOnline), "%t", "online", WeaponsGetOnline(i));      
            FormatEx(sBuffer, sizeof(sBuffer), (WeaponsGetCost(i)) ? "%t  %s  %t" : "%t  %s", sName, hasLength(sGroup) ? sGroup : (gClientData[clientIndex].Level < WeaponsGetLevel(i)) ? sLevel : (fnGetPlaying() < WeaponsGetOnline(i)) ? sOnline : "", "price", WeaponsGetCost(i), "money");
   
            // Show option
            IntToString(i, sInfo, sizeof(sInfo));
            hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(resultHandle == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup)) || WeaponsValidateID(clientIndex, i) || gClientData[clientIndex].Level < WeaponsGetLevel(i) || fnGetPlaying() < WeaponsGetOnline(i) || gClientData[clientIndex].Money < WeaponsGetCost(i) ? false : true));
        }
    }
    // Opens rebuy menu
    else
    {
        // i = array number
        iCount = gClientData[clientIndex].ShoppingCart.Length;
        for(int i = 0; i < iCount; i++)
        {
            // Gets weapon id from the list
            int iD = gClientData[clientIndex].ShoppingCart.Get(i);
            
            // Call forward
            gForwardData._OnClientValidateWeapon(clientIndex, iD, resultHandle);
            
            // Skip, if weapon is disabled
            if(resultHandle == Plugin_Stop)
            {
                continue;
            }
            
            // Skip some weapons, if class isn't equal
            if(!WeaponsValidateClass(clientIndex, iD))
            {
                continue;
            }    
        
            // Gets weapon name
            WeaponsGetName(iD, sName, sizeof(sName));

            // Format some chars for showing in menu
            FormatEx(sBuffer, sizeof(sBuffer), (WeaponsGetCost(iD)) ? "%t  %t" : "%s", sName, "price", WeaponsGetCost(iD), "money");

            // Show option
            IntToString(iD, sInfo, sizeof(sInfo));
            hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(resultHandle == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup)) || WeaponsValidateID(clientIndex, i) || gClientData[clientIndex].Level < WeaponsGetLevel(i) || fnGetPlaying() < WeaponsGetOnline(i) || gClientData[clientIndex].Money < WeaponsGetCost(i) ? false : true));
        }
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iCount)
    {   
        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
        hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the shop menu, and handles it.
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
                // Opens menu back
                int iD[2]; iD = MenusCommandToArray("zp_rebuy_menu");
                if(iD[0] != -1) SubMenu(clientIndex, iD[0]);
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
            
            // If mode doesn't ended yet, then stop
            if((gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode)) || gServerData.RoundEnd)
            {
                // Show block info
                TranslationPrintHintText(clientIndex, "buying round block");
        
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }

            // Initialize name char
            static char sWeaponName[BIG_LINE_LENGTH];

            // Gets menu info
            hMenu.GetItem(mSlot, sWeaponName, sizeof(sWeaponName));
            int iD = StringToInt(sWeaponName);

            // Call forward
            static Action resultHandle; 
            gForwardData._OnClientValidateWeapon(clientIndex, iD, resultHandle);
            
            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Validate access
                if(!WeaponsValidateID(clientIndex, iD) && WeaponsValidateClass(clientIndex, iD))
                {
                    // Gets weapon classname
                    WeaponsGetEntity(iD, sWeaponName, sizeof(sWeaponName));

                    // Validate primary/secondary weapon
                    if(strncmp(sWeaponName[7], "tas", 3, false) != 0)
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
                            AccountSetClientCash(clientIndex, gClientData[clientIndex].Money - WeaponsGetCost(iD));
                            gClientData[clientIndex].LastBoughtAmount += WeaponsGetCost(iD);
                        }

                        // Validate unique id
                        if(gClientData[clientIndex].ShoppingCart.FindValue(iD) == -1)
                        {
                            // Push data into array
                            gClientData[clientIndex].ShoppingCart.Push(iD);
                            
                            // If help messages enabled, then show info
                            if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
                            {
                                // Gets weapon info
                                WeaponsGetInfo(iD, sWeaponName, sizeof(sWeaponName));
                                
                                // Show weapon personal info
                                if(hasLength(sWeaponName)) TranslationPrintHintText(clientIndex, sWeaponName);
                            }
                        }
                        
                        // Return on success
                        return;
                    }
                }
            }
            
            // Gets weapon name
            WeaponsGetName(iD, sWeaponName, sizeof(sWeaponName));    
    
            // Show block info
            TranslationPrintHintText(clientIndex, "buying item block", sWeaponName);
            
            // Emit error sound
            ClientCommand(clientIndex, "play buttons/button11.wav");    
        }
    }
}

/**
 * @brief Rebuys weapons if auto-rebuy is enabled and player is a human (alive).
 *
 * @param clientIndex       The client index.
 **/
bool ZMarketRebuyMenu(const int clientIndex)
{
    // If array hasn't been created, then create
    if(gClientData[clientIndex].ShoppingCart == null)
    {
        // Initialize a buy history array
        gClientData[clientIndex].ShoppingCart = CreateArray();
    }

    // Validate cart size
    if(!gClientData[clientIndex].ShoppingCart.Length)
    {
        return false;
    }
    
    // If auto-rebuy is disabled, then clear
    if(!gClientData[clientIndex].AutoRebuy)
    {
        return true; /// Reset the shopping cart
    }

    // Opens weapons menu
    ZMarketMenu(clientIndex, "rebuy");
    return true;
}

/**
 * @brief Reset the purchase history for a client.
 * 
 * @param clientIndex       The client index.
 **/
void ZMarketResetPurchaseCount(const int clientIndex)
{
    // If mode doesn't started yet, then reset
    if(gServerData.RoundNew)
    {
        // Clear out the array of all data
        gClientData[clientIndex].ShoppingCart.Clear();
    }
}