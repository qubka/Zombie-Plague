/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          roundstart.cpp
 *  Type:          Game 
 *  Description:   Round start event.
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
 * List of objective entities.
 **/
#define ROUNDSTART_OBJECTIVE_ENTITIES "func_bomb_target_hostage_entity_func_hostage_rescue_func_buyzone"

/**
 * The round is pre starting.
 **/
void RoundStartOnRoundPreStart(/*void*/)
{
    // Resets server grobal bools
    gServerData[Server_RoundNew] = true;
    gServerData[Server_RoundEnd] = false;
    gServerData[Server_RoundStart] = false;
    
    // Resets mode
    gServerData[Server_RoundMode] = -1;
    
    // Increment number of rounds
    gServerData[Server_RoundNumber]++;
    
    // Restore default time for zombie event timer
    gServerData[Server_RoundCount] = gCvarList[CVAR_GAME_CUSTOM_START].IntValue;
    
    // Balance of all teams
    RoundStartOnBalanceTeams();
}
 
/**
 * The round is started.
 **/
void RoundStartOnRoundStart(/*void*/)
{
    // Create timer for terminate round
    delete gServerData[Server_RoundTimer];
    gServerData[Server_RoundTimer] = CreateTimer(gCvarList[CVAR_SERVER_ROUNDTIME_ZP].FloatValue * 60.0 - 1.0, RoundEndTimer);

    // Kill all objective entities
    RoundStartOnKillEntity();
}

/**
 * Balances all teams.
 **/
void RoundStartOnBalanceTeams(/*void*/)
{
    // Gets amount of total playing players
    int nPlayers = fnGetPlaying();

    // If there aren't clients on both teams, then stop
    if(!nPlayers)
    {
        return;
    }

    // Move all clients to random teams
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Verify that the client is exist
        if(!IsPlayerExist(i, false))
        {
            continue;
        }

        // Swith team
        ToolsSetClientTeam(i, !(i % 2) ? TEAM_ZOMBIE : TEAM_HUMAN);
    }
}

/**
 * Kills all objective entities.
 **/
void RoundStartOnKillEntity(/*void*/)
{
    // Initialize char
    static char sClassname[NORMAL_LINE_LENGTH];
    
    // Gets max amount of entities
    int nGetMaxEnt = GetMaxEntities();
    
    // entityIndex = entity index
    for(int entityIndex = MaxClients; entityIndex <= nGetMaxEnt; entityIndex++)
    {
        // If entity isn't valid, then continue
        if(IsValidEdict(entityIndex))
        {
            // Gets valid edict's classname
            GetEdictClassname(entityIndex, sClassname, sizeof(sClassname));
            
            // Check if it matches any objective entities, then stop if it doesn't
            if(StrContains(ROUNDSTART_OBJECTIVE_ENTITIES, sClassname) != -1) 
            {
                // Entity is an objective, kill it
                RemoveEdict(entityIndex);
            }
        }
    }
}