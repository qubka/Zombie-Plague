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
 * Hook death cvar changes.
 **/
void DeathOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_RESPAWN_DEATHMATCH]          = FindConVar("zp_deathmatch");
    gCvarList[CVAR_RESPAWN_SUICIDE]             = FindConVar("zp_suicide");
    gCvarList[CVAR_RESPAWN_AMOUNT]              = FindConVar("zp_respawn_amount"); 
    gCvarList[CVAR_RESPAWN_TIME]                = FindConVar("zp_respawn_time"); 
    gCvarList[CVAR_RESPAWN_WORLD]               = FindConVar("zp_respawn_on_suicide");
    gCvarList[CVAR_RESPAWN_LAST]                = FindConVar("zp_respawn_after_last_human"); 
    gCvarList[CVAR_RESPAWN_ZOMBIE]              = FindConVar("zp_respawn_zombies");
    gCvarList[CVAR_RESPAWN_HUMAN]               = FindConVar("zp_respawn_humans"); 
    gCvarList[CVAR_RESPAWN_NEMESIS]             = FindConVar("zp_respawn_nemesis"); 
    gCvarList[CVAR_RESPAWN_SURVIVOR]            = FindConVar("zp_respawn_survivor");
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
    int victimIndex   = GetClientOfUserId(hEvent.GetInt("userid"));
    int attackerIndex = GetClientOfUserId(hEvent.GetInt("attacker"));
    
    // Validate client
    if(!IsPlayerExist(victimIndex, false))
    {
        // If the client isn't a player, a player really didn't die now. Some
        // other mods might sent this event with bad data.
        return Plugin_Handled;
    }

    // Forward event to modules
    RagdollOnClientDeath(victimIndex);
    SoundsOnClientDeath(victimIndex);
    VEffectOnClientDeath(victimIndex);
    WeaponsOnClientDeath(victimIndex);
    DeathOnClientDeath(victimIndex, attackerIndex);
    
    // Allow death
    return Plugin_Continue;
}
 
/**
 * Client has been killed.
 * 
 * @param victimIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
void DeathOnClientDeath(const int victimIndex, const int attackerIndex)
{
    // Resets some tools
    ToolsResetTimers(victimIndex);
    ToolsSetClientDetecting(victimIndex, false);
    ToolsSetClientFlashLight(victimIndex, false);
    ToolsSetClientHud(victimIndex, true);

    // Update or clean screen overlay
    ///VOverlayOnClientUpdate(victimIndex, Overlay_Reset);
    
    // Validate round
    if(!RoundEndOnValidate())
    {
        // Player was killed by other ?
        if(victimIndex != attackerIndex) 
        {
            // If respawn amount more, than limit, stop
            if(gClientData[victimIndex][Client_RespawnTimes] > gCvarList[CVAR_RESPAWN_AMOUNT].IntValue)
            {
                return;
            }
            
            // Verify that the attacker is exist
            if(IsPlayerExist(attackerIndex))
            {
                // Increment exp and bonuses
                if(gClientData[victimIndex][Client_Zombie])
                {
                    AccountSetClientCash(attackerIndex, gClientData[attackerIndex][Client_AmmoPacks] + (gClientData[victimIndex][Client_Nemesis] ? gCvarList[CVAR_BONUS_KILL_NEMESIS].IntValue : gCvarList[CVAR_BONUS_KILL_ZOMBIE].IntValue));
                    LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex][Client_Exp] + (gClientData[victimIndex][Client_Nemesis] ? gCvarList[CVAR_LEVEL_KILL_NEMESIS].IntValue : gCvarList[CVAR_LEVEL_KILL_ZOMBIE].IntValue));
                }
                else
                {
                    AccountSetClientCash(attackerIndex, gClientData[attackerIndex][Client_AmmoPacks] + (gClientData[victimIndex][Client_Survivor] ? gCvarList[CVAR_BONUS_KILL_SURVIVOR].IntValue : gCvarList[CVAR_BONUS_KILL_HUMAN].IntValue));
                    LevelSystemOnSetExp(attackerIndex, gClientData[attackerIndex][Client_Exp] + (gClientData[victimIndex][Client_Nemesis] ? gCvarList[CVAR_LEVEL_KILL_NEMESIS].IntValue : gCvarList[CVAR_LEVEL_KILL_HUMAN].IntValue));
                }
            }
        }
        // If player was killed by world, respawn on suicide?
        else if(!gCvarList[CVAR_RESPAWN_WORLD].BoolValue)
        {
            return;
        }

        // Respawn if human/zombie/nemesis/survivor?
        if((gClientData[victimIndex][Client_Zombie] && !gClientData[victimIndex][Client_Nemesis] && !gCvarList[CVAR_RESPAWN_ZOMBIE].BoolValue) || (!gClientData[victimIndex][Client_Zombie] && !gClientData[victimIndex][Client_Survivor] && !gCvarList[CVAR_RESPAWN_HUMAN].BoolValue) || (gClientData[victimIndex][Client_Nemesis] && !gCvarList[CVAR_RESPAWN_NEMESIS].BoolValue) || (gClientData[victimIndex][Client_Survivor] && !gCvarList[CVAR_RESPAWN_SURVIVOR].BoolValue))
        {
            return;
        }
        
        // Increment count
        gClientData[victimIndex][Client_RespawnTimes]++;
        
        // Sets timer for respawn player
        delete gClientData[victimIndex][Client_RespawnTimer];
        gClientData[victimIndex][Client_RespawnTimer] = CreateTimer(gCvarList[CVAR_RESPAWN_TIME].FloatValue, DeathOnRespawn, GetClientUserId(victimIndex), TIMER_FLAG_NO_MAPCHANGE);
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
    // Gets the client index from the user ID
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
            if((!ModesIsSurvivor(gServerData[Server_RoundMode]) && !gCvarList[CVAR_RESPAWN_LAST].BoolValue && fnGetHumans() <= 1) || (!ModesIsNemesis(gServerData[Server_RoundMode]) && !gCvarList[CVAR_RESPAWN_LAST].BoolValue && fnGetZombies() <= 1))
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
 * @param victimIndex       The victim index.
 * @param attackerIndex     The attacker index.
 **/
public void DeathOnHUD(const int victimIndex, const int attackerIndex)
{
    // Create and send custom death icon
    Event hEvent = CreateEvent("player_death");
    if(hEvent != INVALID_HANDLE)
    {
        // Sets event properties
        hEvent.SetInt("userid", GetClientUserId(victimIndex));
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