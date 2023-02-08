/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          spawn.sp
 *  Type:          Module 
 *  Description:   Spawn event.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
	gServerData.Spawns = new ArrayList(3); 
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
	if (!gServerData.Spawns.Length)
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
	int entity;
	while ((entity = FindEntityByClassname(entity, sClassname)) != -1)
	{
		// Gets origin position
		static float vPosition[3];
		ToolsGetAbsOrigin(entity, vPosition); 
		
		// Push data into array 
		gServerData.Spawns.PushArray(vPosition, sizeof(vPosition));
	}
}

/**
 * @brief Creates commands for spawn module.
 **/
void SpawnOnCommandInit(/*void*/)
{
	// Hook commands
	AddCommandListener(SpawnOnCommandListened, "jointeam");
}

/**
 * Listener command callback (jointeam)
 * @brief Selects the correct team.
 *
 * @param client            The client index.
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action SpawnOnCommandListened(int client, char[] commandMsg, int iArguments)
{
	// Validate client 
	if (IsPlayerExist(client, false))
	{
		// Retrieves a command argument given its index
		static char sArg[SMALL_LINE_LENGTH];
		GetCmdArg(1, sArg, sizeof(sArg));

		// Validate arguments
		if (!hasLength(sArg))
		{
			// Allow command
			return Plugin_Continue;
		}
		
		// Gets team index
		int iTeam = StringToInt(sArg);

		// Gets current team
		switch (ToolsGetTeam(client))
		{
			case TEAM_NONE :
			{
				// Switch new team
				switch (iTeam)
				{
					case TEAM_HUMAN, TEAM_ZOMBIE :
					{
						// Validate last disconnection delay
						int iDelay = RoundToNearest(float(GetTime() - gClientData[client].Time) / 60.0);
						if (iDelay > gCvarList.GAMEMODE_ROUNDTIME_ZP.IntValue || gServerData.RoundMode == -1)
						{
							// Switch team
							ToolsSetTeam(client, (client & 1) ? TEAM_ZOMBIE : TEAM_HUMAN);
							
							// If game round didn't start, then respawn
							if (gServerData.RoundMode == -1)
							{
								// Force client to respawn
								ToolsForceToRespawn(client);
							}
							else
							{   
								// Call respawning
								DeathOnClientRespawn(client, _, false);
							}

							// Validate first connection
							if (gClientData[client].Time <= 0) 
							{
								// Sets time of disconnection
								gClientData[client].Time = GetTime();
								
								// Update time in the database
								DataBaseOnClientUpdate(client, ColumnType_Time);
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
				switch (iTeam)
				{
					case TEAM_HUMAN, TEAM_ZOMBIE :
					{
						// If game round didn't start, then respawn
						if (gServerData.RoundMode == -1)
						{
							// Switch team
							ToolsSetTeam(client, (client & 1) ? TEAM_ZOMBIE : TEAM_HUMAN);
							
							// Force client to respawn
							ToolsForceToRespawn(client);
							
							// Block command
							return Plugin_Handled;
						}
					}
				}
			}
			
			case TEAM_ZOMBIE :
			{
				// Validate new team
				switch (iTeam)
				{
					// Block command     
					case TEAM_NONE, TEAM_HUMAN : return Plugin_Handled;
				}
			}
			
			case TEAM_HUMAN :
			{
				// Validate new team
				switch (iTeam)
				{
					// Block command     
					case TEAM_NONE, TEAM_ZOMBIE : return Plugin_Handled;
				}
			}
		}
		
		// Forward event to modules
		AccountOnClientSpawn(client);
		LevelSystemOnClientSpawn(client);
		VOverlayOnClientSpawn(client);
		VEffectsOnClientSpawn(client);
		WeaponsOnClientSpawn(client);
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
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// Validate client
	if (!IsPlayerExist(client))
	{
		return Plugin_Continue;
	}
	
	// Forward event to modules
	ApplyOnClientSpawn(client);
	
	// Allow event
	return Plugin_Continue;
}

/**
 * @brief Teleport client to a random spawn position.
 * 
 * @param client            The client index.
 **/
void SpawnTeleportToRespawn(int client)
{
	// Initialize vectors
	static float vPosition[3]; float vMaxs[3]; float vMins[3]; 

	// Gets client's min and max size vector
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	// i = origin index
	int iSize = gServerData.Spawns.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets random array
		gServerData.Spawns.GetArray(i, vPosition, sizeof(vPosition));
		
		// Create the hull trace
		TR_TraceHullFilter(vPosition, vPosition, vMins, vMaxs, MASK_SOLID, AntiStickFilter, client);
		
		// Returns if there was any kind of collision along the trace ray
		if (!TR_DidHit())
		{
			// Teleport player back on the spawn point
			TeleportEntity(client, vPosition, NULL_VECTOR, NULL_VECTOR);
			return;
		}
	}
}
