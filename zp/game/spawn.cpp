/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          spawn.cpp
 *  Type:          Game 
 *  Description:   Spawn event.
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
 * Client has been spawned.
 *
 * @param clientIndex       The client index.
 **/
void SpawnOnClientSpawn(int clientIndex)
{
    // If mode doesn't started yet, then reset type
    if(gServerData[Server_RoundNew])
    {
        gClientData[clientIndex][Client_Respawn] = TEAM_HUMAN;
    }
    
    // Switch respawn types
    switch(gClientData[clientIndex][Client_Respawn])
    {
        // Respawn as zombie?
        case TEAM_ZOMBIE : ClassMakeZombie(clientIndex, _, ModesIsNemesis(gServerData[Server_RoundMode]), gServerData[Server_RoundStart]);
        
        // Respawn as human ?
        case TEAM_HUMAN : ClassMakeHuman(clientIndex, ModesIsSurvivor(gServerData[Server_RoundMode]), gServerData[Server_RoundNew]);
    }
}