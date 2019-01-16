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
 
/**
 * @brief Death module init function.
 **/
void DeathOnInit(/*void*/)
{
    // Hook player events
    HookEvent("player_death", DeathOnClient, EventHookMode_Pre);
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
public Action DeathOnClient(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex   = GetClientOfUserId(hEvent.GetInt("userid"));
    int attackerIndex = GetClientOfUserId(hEvent.GetInt("attacker"));
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        // If the client isn't a player, a player really didn't die now. Some
        // other mods might sent this event with bad data.
        return Plugin_Handled;
    }

    // Forward event to modules
    RagdollOnClientDeath(clientIndex);
    SoundsOnClientDeath(clientIndex);
    VEffectOnClientDeath(clientIndex);
    WeaponsOnClientDeath(clientIndex);
    DeathOnClientKill(clientIndex, attackerIndex);
    LevelSystemOnClientDeath(clientIndex);
    AccountOnClientDeath(clientIndex);
    
    // Allow death
    return Plugin_Continue;
}
 
/**
 * @brief Client has been killed.
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
void DeathOnClientKill(const int clientIndex, const int attackerIndex)
{
    // Delete player timers
    gClientData[clientIndex].ResetTimers();
    
    // Resets some tools
    ToolsSetClientDetecting(clientIndex, false);
    ToolsSetClientFlashLight(clientIndex, false);
    ToolsSetClientHud(clientIndex, true);
    ToolsSetClientFov(clientIndex);

    // Validate round
    if(!ModesValidateRound())
    {
        // Player was killed by other ?
        if(clientIndex != attackerIndex) 
        {
            // If respawn amount more, than limit, stop
            if(gClientData[clientIndex].RespawnTimes > ModesGetAmount(gServerData.RoundMode))
            {
                return;
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
        }
        // If player was killed by world, respawn on suicide?
        else if(!ModesIsSuicide(gServerData.RoundMode))
        {
            return;
        }

        // Increment count
        gClientData[clientIndex].RespawnTimes++;
        
        // Sets timer for respawn player
        delete gClientData[clientIndex].RespawnTimer;
        gClientData[clientIndex].RespawnTimer = CreateTimer(ModesGetDelay(gServerData.RoundMode), DeathOnClientRespawn, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Timer callback, respawn a player.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action DeathOnClientRespawn(Handle hTimer, const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Clear timer
    gClientData[clientIndex].RespawnTimer = null;    
    
    // Validate client
    if(clientIndex)
    {
        // If mode doesn't started yet, then stop
        if(!gServerData.RoundStart)
        {
            return Plugin_Stop;
        }

        // Respawn player automatically, if allowed on the current game mode
        if(ModesIsRespawn(gServerData.RoundMode))
        {
            // Respawn if only the last humans/zombies are left?
            int iLast = ModesGetLast(gServerData.RoundMode);
            if(fnGetHumans() <= iLast || fnGetZombies() <= iLast)
            {
                return Plugin_Stop;
            }

            // Respawn a player
            ToolsForceToRespawn(clientIndex);
        }
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