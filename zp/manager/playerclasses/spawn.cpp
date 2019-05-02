/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          spawn.cpp
 *  Type:          Module 
 *  Description:   Spawn event.
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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @brief Spawn module init function.
 **/
void SpawnOnInit(/*void*/)
{
    // Hook player events
    HookEvent("player_spawn", SpawnOnClientSpawn, EventHookMode_Post);
    
    // Initialize a spawn position array
    gServerData.Spawns = CreateArray(3); 
}

/**
 * @brief Spawn module load function.
 **/
void SpawnOnLoad(/*void*/)
{
    // Clear out the array of all data
    gServerData.Spawns.Clear();
    
    // Now copy positions to array structure
    SpawnOnCacheData("info_player_terrorist");
    SpawnOnCacheData("info_player_counterterrorist");
    
    // If team spawns weren't found
    if(!gServerData.Spawns.Length)
    {
        // Now copy positions to array structure
        SpawnOnCacheData("info_player_deathmatch");
        SpawnOnCacheData("info_player_start");
        SpawnOnCacheData("info_player_teamspawn");
    }
}

/**
 * @brief Caches spawn data from the server.
 *
 * @param sClassname        The string with info name. 
 **/
void SpawnOnCacheData(char[] sClassname)
{
    // Loop throught all entities
    int entityIndex;
    while((entityIndex = FindEntityByClassname(entityIndex, sClassname)) != INVALID_ENT_REFERENCE)
    {
        // Gets the origin position
        static float vPosition[3];
        ToolsGetAbsOrigin(entityIndex, vPosition); 
        
        // Push data into array 
        gServerData.Spawns.PushArray(vPosition, sizeof(vPosition));
    }
}

/**
 * @brief Creates commands for spawn module.
 **/
void SpawnOnCommandInit(/*void*/)
{
    // Hook listeners
    AddCommandListener(SpawnOnCommandListened, "jointeam");
}

/**
 * Listener command callback (jointeam)
 * @brief Selects the correct team.
 *
 * @param clientIndex       The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action SpawnOnCommandListened(int clientIndex, char[] commandMsg, int iArguments)
{
    // Validate client 
    if(IsPlayerExist(clientIndex, false))
    {
        // Retrieves a command argument given its index
        static char sArg[SMALL_LINE_LENGTH];
        GetCmdArg(1, sArg, sizeof(sArg));

        // Validate arguments
        if(!hasLength(sArg))
        {
            // Allow command
            return Plugin_Continue;
        }
        
        // Gets team index
        int iTeam = StringToInt(sArg);

        // Gets current team
        switch(ToolsGetTeam(clientIndex))
        {
            case TEAM_NONE :
            {
                // Switch new team
                switch(iTeam)
                {
                    case TEAM_HUMAN, TEAM_ZOMBIE :
                    {
                        // Validate last disconnection delay
                        int iDelay = RoundToNearest(float(GetTime() - gClientData[clientIndex].Time) / 60.0);
                        if(iDelay > gCvarList[CVAR_GAMEMODE_ROUNDTIME_ZP].IntValue || gServerData.RoundMode == -1)
                        {
                            // Switch team
                            ToolsSetTeam(clientIndex, (clientIndex & 1) ? TEAM_ZOMBIE : TEAM_HUMAN);
                            
                            // If game round didn't start, then respawn
                            if(gServerData.RoundMode == -1)
                            {
                                // Force client to respawn
                                ToolsForceToRespawn(clientIndex);
                            }
                            else
                            {   
                                // Call respawning
                                DeathOnClientRespawn(clientIndex, _, false);
                            }

                            // Validate first connection
                            if(gClientData[clientIndex].Time <= 0) 
                            {
                                // Sets time of disconnection
                                gClientData[clientIndex].Time = GetTime();
                                
                                // Update time in the database
                                DataBaseOnClientUpdate(clientIndex, ColumnType_Time);
                            }
                            
                            // Block command
                            return Plugin_Handled;
                        }
                    }
                }
            }

            case TEAM_SPECTATOR :
            {
                // Validate new team
                switch(iTeam)
                {
                    case TEAM_HUMAN, TEAM_ZOMBIE :
                    {
                        // If game round didn't start, then respawn
                        if(gServerData.RoundMode == -1)
                        {
                            // Switch team
                            ToolsSetTeam(clientIndex, (clientIndex & 1) ? TEAM_ZOMBIE : TEAM_HUMAN);
                            
                            // Force client to respawn
                            ToolsForceToRespawn(clientIndex);
                            
                            // Block command
                            return Plugin_Handled;
                        }
                    }
                }
            }
            
            case TEAM_ZOMBIE :
            {
                // Validate new team
                switch(iTeam)
                {
                    // Block command     
                    case TEAM_NONE, TEAM_HUMAN : return Plugin_Handled;
                }
            }
            
            case TEAM_HUMAN :
            {
                // Validate new team
                switch(iTeam)
                {
                    // Block command     
                    case TEAM_NONE, TEAM_ZOMBIE : return Plugin_Handled;
                }
            }
        }
        
        // Forward event to modules
        AccountOnClientSpawn(clientIndex);
        LevelSystemOnClientSpawn(clientIndex);
        VOverlayOnClientSpawn(clientIndex);
        VEffectOnClientSpawn(clientIndex);
    }
    
    // Allow command
    return Plugin_Continue;
}
 
/**
 * Event callback (player_spawn)
 * @brief Client has ben spawned.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action SpawnOnClientSpawn(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Forward event to modules
    ApplyOnClientSpawn(clientIndex);
}

/**
 * @brief Gets the random spawn position.
 * 
 * @param vPosition         The origin output.
 **/
void SpawnGetRandomPosition(float vPosition[3])
{
    // Validate lenght
    int iSize = gServerData.Spawns.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Classes, "Config Validation", "Couldn't find any spawn locations.");
        return;
    }
    
    // Gets random array
    gServerData.Spawns.GetArray(GetRandomInt(0, iSize - 1), vPosition, sizeof(vPosition));
}