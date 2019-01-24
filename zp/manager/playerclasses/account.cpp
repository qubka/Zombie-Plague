/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          account.cpp
 *  Type:          Module 
 *  Description:   Handles client accounts. (cash)
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
 * Maximum cash limit in CS:GO.
 **/
#define ACCOUNT_CASH_MAX 65000

/**
 * @brief Account module init function.
 **/
void AccountOnInit(/*void*/)
{
    // If account disabled, then stop
    if(!gCvarList[CVAR_ACCOUNT_MONEY].BoolValue)
    {
        // Validate loaded map
        if(gServerData.MapLoaded)
        {
            // Validate sync
            if(gServerData.Account != null)
            {
                // i = client index
                for(int i = 1; i <= MaxClients; i++)
                {
                    // Validate client
                    if(IsPlayerExist(i))
                    {
                        // Remove timer
                        delete gClientData[i].AccountTimer;
                    }
                }
                
                // Remove sync
                delete gServerData.Account;
            }
        }
        return;
    }

    // Creates a HUD synchronization object
    if(gServerData.Account == null)
    {
        gServerData.Account = CreateHudSynchronizer();
    }
    
    // Validate loaded map
    if(gServerData.MapLoaded)
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i))
            {
                // Enable account system
                AccountOnClientUpdate(GetClientUserId(i));
            }
        }
    }
}

/**
 * @brief Creates commands for account module.
 **/
void AccountOnCommandInit(/*void*/)
{
    // Hook commands
    RegAdminCmd("zp_money_give", AccountGiveOnCommandCatched, ADMFLAG_GENERIC, "Gives the money. Usage: zp_money_give <name> [amount]");
    RegConsoleCmd("zp_donate_menu", AccountMenuOnCommandCatched, "Opens the donates menu.");
}

/**
 * @brief Hook account cvar changes.
 **/
void AccountOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_ACCOUNT_CASH_AWARD]   = FindConVar("mp_playercashawards");
    gCvarList[CVAR_ACCOUNT_BUY_ANYWHERE] = FindConVar("mp_buy_anywhere");
    gCvarList[CVAR_ACCOUNT_MONEY]        = FindConVar("zp_account_money");
    gCvarList[CVAR_ACCOUNT_CONNECT]      = FindConVar("zp_account_connect");
    gCvarList[CVAR_ACCOUNT_BET]          = FindConVar("zp_account_bet");
    gCvarList[CVAR_ACCOUNT_COMMISION]    = FindConVar("zp_account_commision");
    gCvarList[CVAR_ACCOUNT_DECREASE]     = FindConVar("zp_account_decrease");
    gCvarList[CVAR_ACCOUNT_HUD_R]        = FindConVar("zp_account_hud_R");
    gCvarList[CVAR_ACCOUNT_HUD_G]        = FindConVar("zp_account_hud_G");
    gCvarList[CVAR_ACCOUNT_HUD_B]        = FindConVar("zp_account_hud_B");
    gCvarList[CVAR_ACCOUNT_HUD_A]        = FindConVar("zp_account_hud_A");
    gCvarList[CVAR_ACCOUNT_HUD_X]        = FindConVar("zp_account_hud_X");
    gCvarList[CVAR_ACCOUNT_HUD_Y]        = FindConVar("zp_account_hud_Y");
    
    // Sets locked cvars to their locked values
    gCvarList[CVAR_ACCOUNT_CASH_AWARD].IntValue   = 0;
    gCvarList[CVAR_ACCOUNT_BUY_ANYWHERE].IntValue = 0;
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_ACCOUNT_MONEY],        AccountOnCvarHook); 
    HookConVarChange(gCvarList[CVAR_ACCOUNT_CASH_AWARD],   CvarsLockOnCvarHook);
    HookConVarChange(gCvarList[CVAR_ACCOUNT_BUY_ANYWHERE], CvarsLockOnCvarHook);
}

/**
 * Cvar hook callback (zp_money)
 * @brief Account module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void AccountOnCvarHook(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    AccountOnInit();
}

/**
 * @brief Client has been spawned.
 * 
 * @param clientIndex       The client index.
 **/
void AccountOnClientSpawn(const int clientIndex)
{
    // Reset HUD on the team change
    AccountOnClientUpdate(GetClientUserId(clientIndex));
}

/**
 * @brief Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void AccountOnClientDeath(const int clientIndex)
{
    // Enable HUD for spectator
    AccountOnClientUpdate(GetClientUserId(clientIndex));
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param userID            The user id.
 **/
public void AccountOnClientUpdate(const int userID)
{
    // If account disabled, then stop
    if(!gCvarList[CVAR_ACCOUNT_MONEY].BoolValue)
    {
        return;
    }
    
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Validate real client
        if(!IsFakeClient(clientIndex))
        {
            // If value higher or client is spectator, then create custom HUD
            if(gClientData[clientIndex].Money > ACCOUNT_CASH_MAX || !IsPlayerAlive(clientIndex))
            {
                // Send a convar to the client
                gCvarList[CVAR_ACCOUNT_CASH_AWARD].ReplicateToClient(clientIndex, "0");

                // Sets timer for player account HUD
                delete gClientData[clientIndex].AccountTimer;
                gClientData[clientIndex].AccountTimer = CreateTimer(1.0, AccountOnClientHUD, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            }
            else
            {
                // Send a convar to the client
                gCvarList[CVAR_ACCOUNT_CASH_AWARD].ReplicateToClient(clientIndex, "1");
                
                // Update client moeny
                AccountSetMoney(clientIndex, gClientData[clientIndex].Money);
            }
        }
    }
}

/**
 * @brief Timer callback, show HUD text within information about client account value. (money)
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action AccountOnClientHUD(Handle hTimer, const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Store the default index
        int targetIndex = clientIndex;

        // Validate spectator 
        if(!IsPlayerAlive(clientIndex))
        {
            // Validate spectator mode
            int iSpecMode = ToolsGetClientObserverMode(clientIndex);
            if(iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
            {
                // Allow timer
                return Plugin_Continue;
            }
            
            // Gets the observer target
            targetIndex = ToolsGetClientObserverTarget(clientIndex);
            
            // Validate target
            if(!IsPlayerExist(targetIndex)) 
            {
                // Allow timer
                return Plugin_Continue;
            }
        }
        
        // Print hud text to the client
        TranslationPrintHudText(gServerData.Account, clientIndex, gCvarList[CVAR_ACCOUNT_HUD_X].FloatValue, gCvarList[CVAR_ACCOUNT_HUD_Y].FloatValue, 1.1, gCvarList[CVAR_ACCOUNT_HUD_R].IntValue, gCvarList[CVAR_ACCOUNT_HUD_G].IntValue, gCvarList[CVAR_ACCOUNT_HUD_B].IntValue, gCvarList[CVAR_ACCOUNT_HUD_A].IntValue, 0, 0.0, 0.0, 0.0, "account info", "money", gClientData[targetIndex].Money);

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex].AccountTimer = null;

    // Destroy timer
    return Plugin_Stop;
}

/**
 * Console command callback (zp_money_give)
 * @brief Gives the money.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action AccountGiveOnCommandCatched(const int clientIndex, const int iArguments)
{
    // If not enough arguments given, then stop
    if(iArguments < 2)
    {
        // Write syntax info
        TranslationReplyToCommand(clientIndex, "account give invalid args");
        return Plugin_Handled;
    }
    
    // Initialize argument char
    static char sArgument[SMALL_LINE_LENGTH];
    
    // Gets target index
    GetCmdArg(1, sArgument, sizeof(sArgument));
    int targetIndex = FindTarget(clientIndex, sArgument, true, false);

    // Validate target
    if(targetIndex < 0)
    {
        // Note: FindTarget automatically write error messages
        return Plugin_Handled;
    }
    
    // Gets money amount
    GetCmdArg(2, sArgument, sizeof(sArgument));
    
    // Validate amount
    int iMoney = StringToInt(sArgument);
    if(iMoney <= 0)
    {
        // Write error info
        TranslationReplyToCommand(clientIndex, "account give invalid amount", iMoney);
        return Plugin_Handled;
    }

    // Sets money for the target 
    AccountSetClientCash(targetIndex, gClientData[targetIndex].Money + iMoney);

    // Log action to game events
    LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Classes, "Command", "Admin \"%N\" gived money: \"%d\" to Player \"%N\"", clientIndex, iMoney, targetIndex);
    return Plugin_Handled;
}

/**
 * Console command callback (zp_donate_menu)
 * @brief Opens the donates menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action AccountMenuOnCommandCatched(const int clientIndex, const int iArguments)
{
    AccountMenu(clientIndex, gCvarList[CVAR_ACCOUNT_BET].IntValue, gCvarList[CVAR_ACCOUNT_COMMISION].FloatValue);
    return Plugin_Handled;
}

/*
 * Account natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void AccountOnNativeInit(/*void*/)
{
    CreateNative("ZP_GetClientMoney",        API_GetClientMoney);
    CreateNative("ZP_SetClientMoney",        API_SetClientMoney);
    CreateNative("ZP_GetClientLastPurchase", API_GetClientLastPurchase);
    CreateNative("ZP_SetClientLastPurchase", API_SetClientLastPurchase);
}

/**
 * @brief Gets the player amount of money.
 *
 * @note native int ZP_GetClientMoney(clientIndex);
 **/
public int API_GetClientMoney(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex].Money;
}

/**
 * @brief Sets the player amount of money.
 *
 * @note native void ZP_SetClientMoney(clientIndex, iD);
 **/
public int API_SetClientMoney(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets money for the client
    AccountSetClientCash(clientIndex, GetNativeCell(2));
}

/**
 * @brief Gets the player amount of previous money spended.
 *
 * @note native int ZP_GetClientLastPurchase(clientIndex);
 **/
public int API_GetClientLastPurchase(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex].LastPurchase;
}

/**
 * @brief Sets the player amount of money spending.
 *
 * @note native void ZP_SetClientLastPurchase(clientIndex, iD);
 **/
public int API_SetClientLastPurchase(Handle hPlugin, const int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets purchase for the client
    gClientData[clientIndex].LastPurchase = GetNativeCell(2);
}

/*
 * Stocks account API.
 */

/**
 * @brief Sets a client account value.
 * 
 * @param clientIndex       The client index.
 * @param iMoney            The money amount.
 **/
void AccountSetClientCash(const int clientIndex, int iMoney)
{
    // Call forward
    gForwardData._OnClientMoney(clientIndex, iMoney);
    
    // If value below 0, then set to 0
    if(iMoney < 0)
    {
        iMoney = 0;
    }

    // Sets money
    gClientData[clientIndex].Money = iMoney;
    
    // Update money in the database
    DataBaseOnClientUpdate(clientIndex, ColumnType_Money);

    // If account disabled, then stop
    if(!gCvarList[CVAR_ACCOUNT_MONEY].BoolValue)
    {
        return;
    }
    
    // If value higher, then create custom HUD
    if(iMoney > ACCOUNT_CASH_MAX)
    {
        // Validate timer
        if(gClientData[clientIndex].AccountTimer == null)
        {
            // Send a convar to the client
            gCvarList[CVAR_ACCOUNT_CASH_AWARD].ReplicateToClient(clientIndex, "0");
  
            // Sets timer for player account HUD
            delete gClientData[clientIndex].AccountTimer;
            gClientData[clientIndex].AccountTimer = CreateTimer(1.0, AccountOnClientHUD, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else
    {
        // Validate timer
        if(gClientData[clientIndex].AccountTimer != null)
        {
            // Remove timer
            delete gClientData[clientIndex].AccountTimer;
            
            // Send a convar to the client
            gCvarList[CVAR_ACCOUNT_CASH_AWARD].ReplicateToClient(clientIndex, "1");
        }
        
        // Update client moeny
        AccountSetMoney(clientIndex, gClientData[clientIndex].Money);
    }
}

/**
 * @brief Sets the money on a client.
 *
 * @param clientIndex       The client index.
 * @param iMoney            The money amount.
 **/
void AccountSetMoney(const int clientIndex, const int iMoney)
{
    SetEntData(clientIndex, g_iOffset_PlayerAccount, iMoney, _, true);
}

/*
 * Menu account API.
 */

/**
 * @brief Creates the donates menu.
 *
 * @param clientIndex       The client index.
 * @param iMoney            The money amount.   
 * @param flCommision       The commision amount.
 **/
void AccountMenu(const int clientIndex, int iMoney, float flCommision) 
{
    // If amount below bet, then set to default
    int iBet = gCvarList[CVAR_ACCOUNT_BET].IntValue;
    if(iMoney < iBet)
    {
        iMoney = iBet;
    }

    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH]; 
    static char sInfo[SMALL_LINE_LENGTH];
    
    // Creates menu handle
    Menu hMenu = CreateMenu(AccountMenuSlots);
    
    // Sets language to target
    SetGlobalTransTarget(clientIndex);

    // Validate commision
    if(flCommision <= 0.0)
    {
        // Sets donate title
        hMenu.SetTitle("%t", "donate", iMoney, "money");
    }
    else
    {
        // Sets commision title
        FormatEx(sInfo, sizeof(sInfo), "%.2f%", flCommision);
        hMenu.SetTitle("%t", "commision", iMoney, "money", sInfo);
    }

    // Format some chars for showing in menu
    FormatEx(sBuffer, sizeof(sBuffer), "%t", "increase");
    
    // Show increase option
    FormatEx(sInfo, sizeof(sInfo), "0 %d %f", iMoney, flCommision);
    hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney <= gClientData[clientIndex].Money));

    // Format some chars for showing in menu
    FormatEx(sBuffer, sizeof(sBuffer), "%t", "decrease");
    
    // Show decrease option
    FormatEx(sInfo, sizeof(sInfo), "-1 %d %f", iMoney, flCommision);
    hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney > iBet));
    
    // i = client index
    int iCount;
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(!IsPlayerExist(i, false) || clientIndex == i)
        {
            continue;
        }

        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%N", i);

        // Show option
        FormatEx(sInfo, sizeof(sInfo), "%d %d %f", i, iMoney, flCommision);
        hMenu.AddItem(sInfo, sBuffer, MenusGetItemDraw(iMoney <= gClientData[clientIndex].Money));

        // Increment count
        iCount++;
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iCount)
    {
        // Format some chars for showing in menu
        Format(sBuffer, sizeof(sBuffer), "%t", "empty");
        hMenu.AddItem("empty", sBuffer);
    }
    
    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the donates menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int AccountMenuSlots(Menu hMenu, MenuAction mAction, const int clientIndex, const int mSlot)
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
                int iD[2]; iD = MenusCommandToArray("zp_donate_menu");
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
            
            // Initialize type char
            static char sKey[SMALL_LINE_LENGTH];
        
            // Gets menu info
            hMenu.GetItem(mSlot, sKey, sizeof(sKey));
            static char sInfo[3][SMALL_LINE_LENGTH];
            ExplodeString(sKey, " ", sInfo, sizeof(sInfo), sizeof(sInfo[]));
            int targetIndex = StringToInt(sInfo[0]); int iMoney = StringToInt(sInfo[1]); 
            float flCommision = StringToFloat(sInfo[2]);

            // Validate button info
            switch(targetIndex)
            {
                // Client hit 'Decrease' button 
                case -1 :
                {
                    AccountMenu(clientIndex, iMoney - gCvarList[CVAR_ACCOUNT_BET].IntValue, flCommision + gCvarList[CVAR_ACCOUNT_DECREASE].FloatValue);
                }
                
                // Client hit 'Increase' button
                case 0  :
                {
                    AccountMenu(clientIndex, iMoney + gCvarList[CVAR_ACCOUNT_BET].IntValue, flCommision - gCvarList[CVAR_ACCOUNT_DECREASE].FloatValue);
                }
                
                // Client hit 'Target' button
                default :
                {
                    // Validate target
                    if(!IsPlayerExist(targetIndex, false))
                    {
                        // Show block info
                        TranslationPrintHintText(clientIndex, "selecting target block");
                    
                        // Emit error sound
                        ClientCommand(clientIndex, "play buttons/button11.wav"); 
                        return;
                    }
                    
                    // Validate commision
                    int iAmount;
                    if(flCommision <= 0.0)
                    {
                        // Sets amount
                        iAmount = iMoney;
                    }
                    else
                    {
                        // Calculate amount
                        iAmount = RoundToNearest(float(iMoney) * (1.0 - flCommision));
                    }
                    
                    // Sets money for the client
                    AccountSetClientCash(clientIndex, gClientData[clientIndex].Money - iMoney);
                    
                    // Sets money for the target 
                    AccountSetClientCash(targetIndex, gClientData[targetIndex].Money + iAmount);
                    
                    // If help messages enabled, then show info
                    if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
                    {
                        // Gets client/target name
                        GetClientName(clientIndex, sInfo[0], sizeof(sInfo[]));
                        GetClientName(targetIndex, sInfo[1], sizeof(sInfo[]));
                        
                        // Show message of successful transaction
                        TranslationPrintToChatAll("donate info", sInfo[0], iAmount, "money", sInfo[1]);
                    }
                }
            }
        }
    }
}