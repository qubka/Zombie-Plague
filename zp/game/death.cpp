/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          death.cpp
 *  Type:          Game 
 *  Description:   Death event.
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
 * Timer for respawn a player.
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