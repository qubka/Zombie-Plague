/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          account.cpp
 *  Type:          Game 
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
 * Maximum limit for cash in CS:GO.
 **/
#define ACCOUNT_CASH_MAX 65000

/**
 * HUD synchronization handle.
 **/
Handle hHudAccount;

/**
 * Account module init function.
 **/
void AccountInit(/*void*/)
{
    // If account disabled, then purge
    if(!gCvarList[CVAR_GAME_CUSTOM_MONEY].BoolValue)
    {
        // Validate loaded map
        if(IsMapLoaded())
        {
            // Validate sync
            if(hHudAccount != INVALID_HANDLE)
            {
                // i = client index
                for(int i = 1; i <= MaxClients; i++)
                {
                    // Validate client
                    if(IsPlayerExist(i))
                    {
                        // Remove timer
                        delete gClientData[i][Client_AccountTimer];
                    }
                }
                
                // Remove sync
                delete hHudAccount;
            }
        }
        return;
    }
    
    // Find offsets
    AccountFindOffsets();
    
    /*
     * Creates a HUD synchronization object. This object is used to automatically assign and re-use channels for a set of messages.
     * The HUD has a hardcoded number of channels (usually 6) for displaying text. You can use any channel for any area of the screen. 
     * Text on different channels can overlap, but text on the same channel will erase the old text first. This overlapping and overwriting gets problematic.
     * A HUD synchronization object automatically selects channels for you based on the following heuristics: - If channel X was last used by the object, 
     * and hasn't been modified again, channel X gets re-used. - Otherwise, a new channel is chosen based on the least-recently-used channel.
     * This ensures that if you display text on a sync object, that the previous text displayed on it will always be cleared first. 
     * This is because your new text will either overwrite the old text on the same channel, or because another channel has already erased your text.
     * Note that messages can still overlap if they are on different synchronization objects, or they are displayed to manual channels.
     * These are particularly useful for displaying repeating or refreshing HUD text, in addition to displaying multiple message sets in one area of the screen 
     * (for example, center-say messages that may pop up randomly that you don't want to overlap each other).
     */
    delete hHudAccount;
    hHudAccount = CreateHudSynchronizer();
    
    // Validate loaded map
    if(IsMapLoaded())
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
 * Hook account cvar changes.
 **/
void AccountOnCvarInit(/*void*/)
{
    // Create money cvars
    gCvarList[CVAR_GAME_CUSTOM_MONEY]           = FindConVar("zp_game_custom_money");

    // Create bonus cvars
    gCvarList[CVAR_BONUS_CONNECT]               = FindConVar("zp_bonus_connection");
    gCvarList[CVAR_BONUS_INFECT]                = FindConVar("zp_bonus_infect");
    gCvarList[CVAR_BONUS_INFECT_HEALTH]         = FindConVar("zp_bonus_infect_health");
    gCvarList[CVAR_BONUS_KILL_HUMAN]            = FindConVar("zp_bonus_kill_human");
    gCvarList[CVAR_BONUS_KILL_ZOMBIE]           = FindConVar("zp_bonus_kill_zombie");
    gCvarList[CVAR_BONUS_KILL_NEMESIS]          = FindConVar("zp_bonus_kill_nemesis");
    gCvarList[CVAR_BONUS_KILL_SURVIVOR]         = FindConVar("zp_bonus_kill_survivor"); 
    gCvarList[CVAR_BONUS_DAMAGE_HUMAN]          = FindConVar("zp_bonus_damage_human");
    gCvarList[CVAR_BONUS_DAMAGE_ZOMBIE]         = FindConVar("zp_bonus_damage_zombie");
    gCvarList[CVAR_BONUS_DAMAGE_SURVIVOR]       = FindConVar("zp_bonus_damage_survivor");
    gCvarList[CVAR_BONUS_ZOMBIE_WIN]            = FindConVar("zp_bonus_zombie_win");
    gCvarList[CVAR_BONUS_ZOMBIE_FAIL]           = FindConVar("zp_bonus_zombie_fail");
    gCvarList[CVAR_BONUS_ZOMBIE_DRAW]           = FindConVar("zp_bonus_zombie_draw");
    gCvarList[CVAR_BONUS_HUMAN_WIN]             = FindConVar("zp_bonus_human_win");
    gCvarList[CVAR_BONUS_HUMAN_FAIL]            = FindConVar("zp_bonus_human_fail");
    gCvarList[CVAR_BONUS_HUMAN_DRAW]            = FindConVar("zp_bonus_human_draw");
    gCvarList[CVAR_BONUS_HUD_ACCOUNT_R]         = FindConVar("zp_bonus_hud_account_R");
    gCvarList[CVAR_BONUS_HUD_ACCOUNT_G]         = FindConVar("zp_bonus_hud_account_G");
    gCvarList[CVAR_BONUS_HUD_ACCOUNT_B]         = FindConVar("zp_bonus_hud_account_B");
    
    // Create server cvars
    gCvarList[CVAR_SERVER_CASH_AWARD]           = FindConVar("mp_playercashawards");
    gCvarList[CVAR_SERVER_BUY_ANYWHERE]         = FindConVar("mp_buy_anywhere");
    
    // Sets locked cvars to their locked values
    gCvarList[CVAR_SERVER_CASH_AWARD].IntValue   = 0;
    gCvarList[CVAR_SERVER_BUY_ANYWHERE].IntValue = 0;
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_GAME_CUSTOM_MONEY],           AccountCvarsHookEnable); 
    HookConVarChange(gCvarList[CVAR_SERVER_CASH_AWARD],           CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_BUY_ANYWHERE],         CvarsHookLocked);
}

/**
 * Cvar hook callback (zp_game_custom_money)
 * Account module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void AccountCvarsHookEnable(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    AccountInit();
}

/**
 * Find account-specific offsets here.
 **/
void AccountFindOffsets(/*void*/)
{
    // Load offsets here
    fnInitSendPropOffset(g_iOffset_PlayerAccount, "CCSPlayer", "m_iAccount");
}

/**
 * Client has been changed class state. (Post)
 *
 * @param userID            The user id.
 **/
public void AccountOnClientUpdate(const int userID)
{
    // If account disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_MONEY].BoolValue)
    {
        return;
    }
    
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Validate real client
        if(!IsFakeClient(clientIndex))
        {
            // If value higher, then create custom HUD
            if(gClientData[clientIndex][Client_AmmoPacks] > ACCOUNT_CASH_MAX)
            {
                // Send a convar to client
                gCvarList[CVAR_SERVER_CASH_AWARD].ReplicateToClient(clientIndex, "0");

                // Sets timer for player account HUD
                delete gClientData[clientIndex][Client_AccountTimer];
                gClientData[clientIndex][Client_AccountTimer] = CreateTimer(1.0, AccountOnHUD, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            }
            else
            {
                // Send a convar to client
                gCvarList[CVAR_SERVER_CASH_AWARD].ReplicateToClient(clientIndex, "1");
                
                // Update client cash
                SetEntData(clientIndex, g_iOffset_PlayerAccount, gClientData[clientIndex][Client_AmmoPacks], 4, true);
            }
        }
    }
}

/**
 * Set a client account value. (ammopacks)
 * 
 * @param clientIndex       The client index.
 * @param nAmmoPacks        The ammopacks amount.
 **/
stock void AccountSetClientCash(const int clientIndex, int nAmmoPacks)
{
    // If value below 0, then set to 0
    if(nAmmoPacks < 0)
    {
        nAmmoPacks = 0;
    }

    // Sets the ammopacks
    gClientData[clientIndex][Client_AmmoPacks] = nAmmoPacks;

    // If account disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_MONEY].BoolValue)
    {
        return;
    }
    
    // If value higher, then create custom HUD
    if(nAmmoPacks > ACCOUNT_CASH_MAX)
    {
        // Validate timer
        if(gClientData[clientIndex][Client_AccountTimer] == INVALID_HANDLE)
        {
            // Send a convar to client
            gCvarList[CVAR_SERVER_CASH_AWARD].ReplicateToClient(clientIndex, "0");
  
            // Sets timer for player account HUD
            delete gClientData[clientIndex][Client_AccountTimer];
            gClientData[clientIndex][Client_AccountTimer] = CreateTimer(1.0, AccountOnHUD, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else
    {
        // Update client cash
        SetEntData(clientIndex, g_iOffset_PlayerAccount, gClientData[clientIndex][Client_AmmoPacks], 4, true);
    }
}

/**
 * Timer callback, show HUD text within information about client account value. (ammopacks)
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action AccountOnHUD(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Print hud text to client
        TranslationPrintHudText(hHudAccount, clientIndex, 0.02, 0.01, 1.1, gCvarList[CVAR_BONUS_HUD_ACCOUNT_R].IntValue, gCvarList[CVAR_BONUS_HUD_ACCOUNT_G].IntValue, gCvarList[CVAR_BONUS_HUD_ACCOUNT_B].IntValue, 255, 0, 0.0, 0.0, 0.0, "account info", "ammopack", gClientData[clientIndex][Client_AmmoPacks]);

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex][Client_AccountTimer] = INVALID_HANDLE;

    // Destroy timer
    return Plugin_Stop;
}