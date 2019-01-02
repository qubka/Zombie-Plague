/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          death.cpp
 *  Type:          Game 
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
 * Death module init function.
 **/
void DeathInit(/*void*/)
{
    // Hook player events
    HookEvent("player_death", DeathOnClient, EventHookMode_Pre);
}

/**
 * Event callback (player_death)
 * Client has been killed.
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
    DeathOnClientDeath(clientIndex, attackerIndex);
    
    // Allow death
    return Plugin_Continue;
}
 
/**
 * Client has been killed.
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
void DeathOnClientDeath(const int clientIndex, const int attackerIndex)
{
    // Resets some tools
    ToolsResetTimers(clientIndex);
    ToolsSetClientDetecting(clientIndex, false);
    ToolsSetClientFlashLight(clientIndex, false);
    ToolsSetClientHud(clientIndex, true);
    ToolsSetClientFov(clientIndex);

    // Validate round
    if(!RoundEndOnValidate())
    {
        // Player was killed by other ?
        if(clientIndex != attackerIndex) 
        {
            // If respawn amount more, than limit, stop
            if(gClientData[clientIndex][Client_RespawnTimes] > ModesGetAmount(gServerData[Server_RoundMode]))
            {
                return;
            }
            
            // Verify that the attacker is exist
            if(IsPlayerExist(attackerIndex))
            {
                // Increment exp and bonuses
                if(gClientData[clientIndex][Client_Zombie])
                {
                    AccountSetClientCash(attackerIndex, gClientData[attackerIndex][Client_Money] + (gClientData[clientIndex][Client_Nemesis] ? gCvarList[CVAR_BONUS_KILL_NEMESIS].IntValue : gCvarList[CVAR_BONUS_KILL_ZOMBIE].IntValue));
                    LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex][Client_Exp] + (gClientData[clientIndex][Client_Nemesis] ? gCvarList[CVAR_LEVEL_KILL_NEMESIS].IntValue : gCvarList[CVAR_LEVEL_KILL_ZOMBIE].IntValue));
                }
                else
                {
                    AccountSetClientCash(attackerIndex, gClientData[attackerIndex][Client_Money] + (gClientData[clientIndex][Client_Survivor] ? gCvarList[CVAR_BONUS_KILL_SURVIVOR].IntValue : gCvarList[CVAR_BONUS_KILL_HUMAN].IntValue));
                    LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex][Client_Exp] + (gClientData[clientIndex][Client_Nemesis] ? gCvarList[CVAR_LEVEL_KILL_NEMESIS].IntValue : gCvarList[CVAR_LEVEL_KILL_HUMAN].IntValue));
                }
            }
        }
        // If player was killed by world, respawn on suicide?
        else if(!ModesIsSuicide(gServerData[Server_RoundMode]))
        {
            return;
        }

        // Increment count
        gClientData[clientIndex][Client_RespawnTimes]++;
        
        // Sets timer for respawn player
        delete gClientData[clientIndex][Client_RespawnTimer];
        gClientData[clientIndex][Client_RespawnTimer] = CreateTimer(ModesGetDelay(gServerData[Server_RoundMode]), DeathOnRespawn, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * Timer callback, respawn a player.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action DeathOnRespawn(Handle hTimer, const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Clear timer
    gClientData[clientIndex][Client_RespawnTimer] = INVALID_HANDLE;    
    
    // Validate client
    if(clientIndex)
    {
        // If mode doesn't started yet, then stop
        if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
        {
            return Plugin_Stop;
        }

        // Respawn player automatically, if allowed on the current game mode
        if(ModesIsRespawn(gServerData[Server_RoundMode]))
        {
            // Respawn if only the last human/zombie is left? (ignore this setting on survivor/nemesis rounds)
            int nLast = ModesGetLast(gServerData[Server_RoundMode]);
            if((!ModesIsSurvivor(gServerData[Server_RoundMode]) && nLast && fnGetHumans() <= nLast) || (!ModesIsNemesis(gServerData[Server_RoundMode]) && nLast && fnGetZombies() <= nLast))
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
 * Client has been killed. (Fake)
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
public void DeathOnHUD(const int clientIndex, const int attackerIndex)
{
    // Create and send custom death icon
    Event hEvent = CreateEvent("player_death");
    if(hEvent != INVALID_HANDLE)
    {
        // Sets event properties
        hEvent.SetInt("userid", GetClientUserId(clientIndex));
        hEvent.SetInt("attacker", GetClientUserId(attackerIndex));
        hEvent.SetString("weapon", "weapon_claws");
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