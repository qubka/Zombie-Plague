/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          death.cpp
 *  Type:          Module 
 *  Description:   Death event.
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
 
#if defined USE_DHOOKS
/**
 * Variables to store DHook calls handlers.
 **/
Handle hDHookCommitSuicide;

/**
 * Variables to store dynamic DHook offsets.
 **/
int DHook_CommitSuicide;
#endif 
 
/**
 * @brief Death module init function.
 **/
void DeathOnInit(/*void*/)
{
    // Hook player events
    HookEvent("player_death", DeathOnClientDeath, EventHookMode_Post);
    
    #if defined USE_DHOOKS
    // Load offsets
    fnInitGameConfOffset(gServerData.SDKTools, DHook_CommitSuicide, /*CBasePlayer::*/"CommitSuicide");
    
    /// CBasePlayer::CommitSuicide(CBasePlayer *this, bool a2, bool a3)
    hDHookCommitSuicide = DHookCreate(DHook_CommitSuicide, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DeathDhookOnCommitSuicide);
    DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
    DHookAddParam(hDHookCommitSuicide, HookParamType_Bool);
    #endif
}

/**
 * @brief Creates commands for death module.
 **/
void DeathOnCommandInit(/*void*/)
{
    // Hook listeners
    AddCommandListener(DeathOnCommandListened, "kill");
    AddCommandListener(DeathOnCommandListened, "explode");
    AddCommandListener(DeathOnCommandListened, "killvector");
}

/**
 * @brief Hook death cvar changes.
 **/
void DeathOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_INFECT_ICON] = FindConVar("zp_infect_icon");
}

/**
 * @brief Client has been joined.
 * 
 * @param clientIndex       The client index.  
 **/
void DeathOnClientInit(const int clientIndex)
{
    #if defined USE_DHOOKS
    // Hook entity callbacks
    DHookEntity(hDHookCommitSuicide, true, clientIndex);
    #else
        #pragma unused clientIndex
    #endif
}

/**
 * Listener command callback (kill, explode, killvector)
 * @brief Blocks the suicide.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action DeathOnCommandListened(const int clientIndex, const char[] commandMsg, const int iArguments)
{
    // Validate client 
    if(IsPlayerExist(clientIndex, false))
    {
        // Block command
        return Plugin_Handled;
    }
    
    // Allow command
    return Plugin_Continue;
}

/**
 * Event callback (player_death)
 * @brief Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action DeathOnClientDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex   = GetClientOfUserId(hEvent.GetInt("userid"));
    int attackerIndex = GetClientOfUserId(hEvent.GetInt("attacker"));
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }
    
    // Delete player timers
    gClientData[clientIndex].ResetTimers();
    
    // Resets some tools
    ToolsSetClientDetecting(clientIndex, false);
    ToolsSetClientFlashLight(clientIndex, false);
    ToolsSetClientHud(clientIndex, true);
    ToolsSetClientFov(clientIndex);
    
    // Forward event to modules
    RagdollOnClientDeath(clientIndex);
    SoundsOnClientDeath(clientIndex);
    VEffectOnClientDeath(clientIndex);
    WeaponsOnClientDeath(clientIndex);
    VOverlayOnClientDeath(clientIndex);
    LevelSystemOnClientDeath(clientIndex);
    AccountOnClientDeath(clientIndex);
    if(!DeathOnClientRespawn(clientIndex, attackerIndex))
    {
        // Terminate the round
        ModesValidateRound();
    }
}
/**
 * @brief 
 *
 * @param clientIndex       The client index.
 * @param attackerIndex     (Optional) The attacker index.
 * @param bTimer            If true, run the respawning timer, false to respawn instantly.
 **/
bool DeathOnClientRespawn(const int clientIndex, const int attackerIndex = 0,  const bool bTimer = true)
{
    // If mode doesn't started yet, then stop
    if(!gServerData.RoundStart)
    {
        return true; //! Avoid double check in 'ModesValidateRound'
    }

    // If respawn disabled on the current game mode, then stop
    if(!ModesIsRespawn(gServerData.RoundMode))
    {
        return false;
    }
    
    // If any last humans/zombies are left, then stop
    int iLast = ModesGetLast(gServerData.RoundMode);
    if(fnGetHumans() < iLast || fnGetZombies() < iLast)
    {
        return false;
    }
        
    // If player was killed by world, then stop
    if(clientIndex == attackerIndex && !ModesIsSuicide(gServerData.RoundMode)) 
    {
        return false;
    }

    // If respawn amount exceed limit, the stop
    if(gClientData[clientIndex].RespawnTimes >= ModesGetAmount(gServerData.RoundMode))
    {
        return false;
    }

    // Verify that the attacker is exist
    if(IsPlayerExist(attackerIndex))
    {
        // Gets class exp and money bonuses
        static int iExp[6]; static int iMoney[6];
        ClassGetExp(gClientData[attackerIndex].Class, iExp, sizeof(iExp));
        ClassGetMoney(gClientData[attackerIndex].Class, iMoney, sizeof(iMoney));

        // Increment money/exp/health
        LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex].Exp + iExp[BonusType_Kill]);
        AccountSetClientCash(attackerIndex, gClientData[attackerIndex].Money + iMoney[BonusType_Kill]);
        ToolsSetClientHealth(attackerIndex, GetClientHealth(attackerIndex) + ClassGetLifeSteal(gClientData[attackerIndex].Class));
    }
        
    // Validate timer
    if(bTimer)
    {
        // Increment count
        gClientData[clientIndex].RespawnTimes++;
    
        // Sets timer for respawn player
        delete gClientData[clientIndex].RespawnTimer;
        gClientData[clientIndex].RespawnTimer = CreateTimer(ModesGetDelay(gServerData.RoundMode), DeathOnClientRespawning, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        // Respawn a player
        ToolsForceToRespawn(clientIndex);
    }
    
    // Return on success
    return true;
}

/**
 * @brief Timer callback, respawning a player.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action DeathOnClientRespawning(const Handle hTimer, const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Clear timer
    gClientData[clientIndex].RespawnTimer = null;    
    
    // Validate client
    if(clientIndex)
    {
        // Call respawning
        DeathOnClientRespawn(clientIndex, _, false);
    }
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Event creation (player_death)
 * @brief Client has been killed. *(Fake)
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
public void DeathOnClientHUD(const int clientIndex, const int attackerIndex)
{
    // Creates and send custom death icon
    Event hEvent = CreateEvent("player_death");
    if(hEvent != null)
    {
        // Gets infect alias
        static char sAlias[SMALL_LINE_LENGTH];
        gCvarList[CVAR_INFECT_ICON].GetString(sAlias, sizeof(sAlias));
        
        // Sets event properties
        hEvent.SetInt("userid", GetClientUserId(clientIndex));
        hEvent.SetInt("attacker", GetClientUserId(attackerIndex));
        hEvent.SetString("weapon", sAlias);
        hEvent.SetBool("headshot", true);
        
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Send fake event
            if(IsPlayerExist(i, false) && !IsFakeClient(i)) hEvent.FireToClient(i);
        }
        
        // Close it
        hEvent.Close();
    }
}

#if defined USE_DHOOKS
/**
 * DHook: Suicide the current player.
 * @note void CBasePlayer::CommitSuicide(bool, bool)
 *
 * @param clientIndex       The client index.
 **/
public MRESReturn DeathDhookOnCommitSuicide(const int clientIndex)
{
    // Validate client
    if(IsPlayerExist(clientIndex, false))
    {
        // Reset any respawning 
        delete gClientData[clientIndex].RespawnTimer;
        
        // Terminate the round
        ModesValidateRound();
    }
}
#endif