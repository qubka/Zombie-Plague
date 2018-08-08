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
#define OBJECTIVE_ENTITIES "func_bomb_target_hostage_entity_func_hostage_rescue_func_buyzone"

/**
 * The round is pre starting.
 **/
void RoundStartOnRoundPreStart(/*void*/)
{
    // Resets server grobal variables
    gServerData[Server_RoundNew] = true;
    gServerData[Server_RoundEnd] = false;
    gServerData[Server_RoundStart] = false;
    
    // Update server grobal variables
    gServerData[Server_RoundMode] = -1;
    gServerData[Server_RoundNumber]++;
    gServerData[Server_RoundCount] = gCvarList[CVAR_GAME_CUSTOM_START].IntValue;

    // Balance of all teams
    RoundStartOnBalanceTeams();
}
 
/**
 * The round is started.
 **/
void RoundStartOnRoundStart(/*void*/)
{
    // Kill all objective entities
    RoundStartOnKillEntity();
}

/**
 * Balances all teams.
 **/
void RoundStartOnBalanceTeams(/*void*/)
{
    // Move team clients to random teams
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i, false))
        {
            // Validate team
            if(GetClientTeam(i) <= TEAM_SPECTATOR)
            {
                continue;
            }
    
            // Swith team
            bool bState = ToolsGetClientDefuser(i);
            ToolsSetClientTeam(i, !(i % 2) ? TEAM_ZOMBIE : TEAM_HUMAN);
            ToolsSetClientDefuser(i, bState);
        }
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
    
    // x = entity index
    for(int x = MaxClients; x <= nGetMaxEnt; x++)
    {
        // Validate entity
        if(IsValidEdict(x))
        {
            // Gets valid edict classname
            GetEdictClassname(x, sClassname, sizeof(sClassname));
            
            // Validate objectives
            if(StrContains(OBJECTIVE_ENTITIES, sClassname) != -1) 
            {
                AcceptEntityInput(x, "Kill"); //! Destroy
            }
            // Validate weapon
            else if(!strncmp(sClassname, "weapon_", 7, false))
            {
                // Gets the weapon owner
                int clientIndex = GetEntDataEnt2(x, g_iOffset_WeaponOwner);
                
                // Validate owner
                if(!IsPlayerExist(clientIndex))
                {
                    AcceptEntityInput(x, "Kill"); //! Destroy
                }
            }
        }
    }
}
