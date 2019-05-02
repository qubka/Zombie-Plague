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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @brief Client has been changed class state. *(Post)
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
    
    // Validate real client
    if(!IsFakeClient(clientIndex)) 
    {
        // Unlock VGUI buy panel
        gCvarList[CVAR_ACCOUNT_BUY_ANYWHERE].ReplicateToClient(clientIndex, "1");
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
    
    // Hook listeners
    AddCommandListener(ZMarketOnCommandListened, "open_buymenu");
    //AddCommandListener(ZMarketOnCommandListened, "close_buymenu");
}

/*
 * Market main functions.
 */

/**
 * Listener command callback (open_buymenu)
 * @brief Buying of the weapons.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action ZMarketOnCommandListened(int clientIndex, char[] commandMsg, int iArguments)
{
    // Validate real client
    if(IsPlayerExist(clientIndex) && !IsFakeClient(clientIndex))
    {
        // Lock VGUI buy panel
        gCvarList[CVAR_ACCOUNT_BUY_ANYWHERE].ReplicateToClient(clientIndex, "0");
        
        // Opens weapon menu
        int iD[2]; iD = MenusCommandToArray("zp_rebuy_menu");
        if(iD[0] != -1) SubMenu(clientIndex, iD[0]);
        
        // Sets timer for reseting command
        delete gClientData[clientIndex].BuyTimer;
        gClientData[clientIndex].BuyTimer = CreateTimer(1.0, ZMarketOnClientBuyMenu, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Timer callback, auto-close a default buy menu.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ZMarketOnClientBuyMenu(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Clear timer
    gClientData[clientIndex].BuyTimer = null;
    
    // Validate client
    if(clientIndex)
    {
        // Unlock VGUI buy panel
        gCvarList[CVAR_ACCOUNT_BUY_ANYWHERE].ReplicateToClient(clientIndex, "1");
    }
    
    // Destroy timer
    return Plugin_Stop;
}
/**
 * @brief Called when a player attempts to purchase an item.
 * 
 * @param clientIndex       The client index.
 * @param sName             The weapon name.
 **/
public Action CS_OnBuyCommand(int clientIndex, const char[] sName)
{
    // Block buy
    return Plugin_Handled;
}

/**
 * Console command callback (zp_rebuy_menu)
 * @brief Changes the rebuy state.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ZMarketRebuyOnCommandCatched(int clientIndex, int iArguments)
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
public Action ZMarketPistolsOnCommandCatched(int clientIndex, int iArguments)
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
public Action ZMarketShotgunsOnCommandCatched(int clientIndex, int iArguments)
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
public Action ZMarketRiflesOnCommandCatched(int clientIndex, int iArguments)
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
public Action ZMarketSnipersOnCommandCatched(int clientIndex, int iArguments)
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
public Action ZMarketMachinegunsOnCommandCatched(int clientIndex, int iArguments)
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
public Action ZMarketKnifesOnCommandCatched(int clientIndex, int iArguments)
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
void ZMarketMenu(int clientIndex, char[] sTitle, MenuType mSlot = MenuType_Invisible) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // If mode already started, then stop
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
    static char sLimit[SMALL_LINE_LENGTH];
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
    Action resultHandle; bool bMenu = mSlot != MenuType_Invisible;
    
    // i = array number
    int iCount = bMenu ? gServerData.Weapons.Length : gClientData[clientIndex].ShoppingCart.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Gets weapon id from the list
        int iD = bMenu ? i : gClientData[clientIndex].ShoppingCart.Get(i);
        
        // Call forward
        gForwardData._OnClientValidateWeapon(clientIndex, iD, resultHandle);
        
        // Skip, if weapon is disabled
        if(resultHandle == Plugin_Stop)
        {
            continue;
        }
        
        // Skip some weapons, if slot isn't equal
        if(bMenu && WeaponsGetSlot(iD) != mSlot) 
        {
            continue;
        }
        
        // Skip some weapons, if class isn't equal
        if(!WeaponsValidateClass(clientIndex, iD))
        {
            continue;
        }    
    
        // Gets weapon data
        WeaponsGetName(iD, sName, sizeof(sName));
        WeaponsGetGroup(iD, sGroup, sizeof(sGroup));
        
        // Format some chars for showing in menu
        FormatEx(sLevel, sizeof(sLevel), "%t", "level", WeaponsGetLevel(iD));
        FormatEx(sLimit, sizeof(sLimit), "%t", "limit", WeaponsGetLimit(iD));
        FormatEx(sOnline, sizeof(sOnline), "%t", "online", WeaponsGetOnline(iD));      
        FormatEx(sBuffer, sizeof(sBuffer), (WeaponsGetCost(iD)) ? "%t  %s  %t" : "%t  %s", sName, hasLength(sGroup) ? sGroup : (gClientData[clientIndex].Level < WeaponsGetLevel(iD)) ? sLevel : (WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(clientIndex, iD)) ? sLimit : (fnGetPlaying() < WeaponsGetOnline(iD)) ? sOnline : "", "price", WeaponsGetCost(iD), "money");

        // Show option
        IntToString(iD, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(resultHandle == Plugin_Handled || (hasLength(sGroup) && !IsPlayerInGroup(clientIndex, sGroup)) || WeaponsValidateID(clientIndex, iD) || gClientData[clientIndex].Level < WeaponsGetLevel(iD) || fnGetPlaying() < WeaponsGetOnline(iD) || WeaponsGetLimit(iD) && WeaponsGetLimit(iD) <= WeaponsGetLimits(clientIndex, iD) || gClientData[clientIndex].Money < WeaponsGetCost(iD) ? false : true));
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
            
            // If mode already started, then stop
            if((gServerData.RoundStart && !ModesIsWeapon(gServerData.RoundMode)) || gServerData.RoundEnd)
            {
                // Show block info
                TranslationPrintHintText(clientIndex, "buying round block");
        
                // Emit error sound
                ClientCommand(clientIndex, "play buttons/button11.wav");    
                return;
            }

            // Gets menu info
            static char sBuffer[BIG_LINE_LENGTH];
            hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
            int iD = StringToInt(sBuffer);

            // Call forward
            Action resultHandle; 
            gForwardData._OnClientValidateWeapon(clientIndex, iD, resultHandle);
            
            // Validate handle
            if(resultHandle == Plugin_Continue || resultHandle == Plugin_Changed)
            {
                // Validate access
                if(!WeaponsValidateID(clientIndex, iD) && WeaponsValidateClass(clientIndex, iD))
                {
                    // Gets weapon classname
                    WeaponsGetEntity(iD, sBuffer, sizeof(sBuffer));

                    // Validate primary/secondary weapon
                    if(strncmp(sBuffer[7], "tas", 3, false))
                    {
                        // Drop weapon
                        WeaponsDrop(clientIndex, GetPlayerWeaponSlot(clientIndex, (WeaponsGetSlot(iD) == MenuType_Pistols) ? view_as<int>(SlotType_Secondary) : ((WeaponsGetSlot(iD) == MenuType_Knifes) ? view_as<int>(SlotType_Melee) : view_as<int>(SlotType_Primary))), true);
                    }

                    // Give weapon for the player
                    if(WeaponsGive(clientIndex, iD) != INVALID_ENT_REFERENCE)
                    {
                        // If weapon has a cost
                        if(WeaponsGetCost(iD))
                        {
                            // Remove money and store it for returning if player will be first zombie
                            AccountSetClientCash(clientIndex, gClientData[clientIndex].Money - WeaponsGetCost(iD));
                            gClientData[clientIndex].LastPurchase += WeaponsGetCost(iD);
                        }
                        
                        // If weapon has a limit
                        if(WeaponsGetLimit(iD))
                        {
                            // Increment count
                            WeaponsSetLimits(clientIndex, iD, WeaponsGetLimits(clientIndex, iD) + 1);
                        }

                        // Validate unique id
                        if(gClientData[clientIndex].ShoppingCart.FindValue(iD) == -1)
                        {
                            // Push data into array
                            gClientData[clientIndex].ShoppingCart.Push(iD);
                            
                            // If help messages enabled, then show info
                            if(gCvarList[CVAR_MESSAGES_WEAPON_ALL].BoolValue)
                            {
                                // Gets client name
                                static char sClient[SMALL_LINE_LENGTH];
                                GetClientName(clientIndex, sClient, sizeof(sClient));

                                // Gets weapon name
                                WeaponsGetName(iD, sBuffer, sizeof(sBuffer));    
                                
                                // Show item buying info
                                TranslationPrintToChatAll("buy info", sClient, sBuffer);
                            }
                            
                            // If help messages enabled, then show info
                            if(gCvarList[CVAR_MESSAGES_WEAPON_INFO].BoolValue)
                            {
                                // Gets weapon info
                                WeaponsGetInfo(iD, sBuffer, sizeof(sBuffer));
                                
                                // Show weapon personal info
                                if(hasLength(sBuffer)) TranslationPrintHintText(clientIndex, sBuffer);
                            }
                        }
                        
                        // Return on success
                        return;
                    }
                }
            }
            
            // Gets weapon name
            WeaponsGetName(iD, sBuffer, sizeof(sBuffer));    
    
            // Show block info
            TranslationPrintHintText(clientIndex, "buying item block", sBuffer);
            
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
bool ZMarketRebuyMenu(int clientIndex)
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
void ZMarketResetPurchaseCount(int clientIndex)
{
    // If mode doesn't started yet, then reset
    if(gServerData.RoundNew)
    {
        // Clear out the array of all data
        gClientData[clientIndex].ShoppingCart.Clear();
    }
}