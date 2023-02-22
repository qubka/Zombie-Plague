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
void SpawnOnInit()
{
	HookEvent("player_spawn", SpawnOnClientSpawn, EventHookMode_Post);
	
	gServerData.Spawns = new ArrayList(3); 
}

/**
 * @brief Spawn module load function.
 **/
void SpawnOnLoad()
{
	gServerData.Spawns.Clear();
	
	SpawnOnCacheData("info_player_terrorist");
	SpawnOnCacheData("info_player_counterterrorist");
	
	if (!gServerData.Spawns.Length)
	{
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
void SpawnOnCacheData(const char[] sClassname)
{
	int entity;
	while ((entity = FindEntityByClassname(entity, sClassname)) != -1)
	{
		static float vPosition[3];
		ToolsGetAbsOrigin(entity, vPosition); 
		
		gServerData.Spawns.PushArray(vPosition, sizeof(vPosition));
	}
}

/**
 * @brief Creates commands for spawn module.
 **/
void SpawnOnCommandInit()
{
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
	if (IsClientValid(client, false))
	{
		static char sArg[SMALL_LINE_LENGTH];
		GetCmdArg(1, sArg, sizeof(sArg));

		if (!hasLength(sArg))
		{
			return Plugin_Continue;
		}
		
		int iTeam = StringToInt(sArg);

		switch (ToolsGetTeam(client))
		{
			case TEAM_NONE :
			{
				switch (iTeam)
				{
					case TEAM_HUMAN, TEAM_ZOMBIE :
					{
						int iDelay = RoundToNearest(float(GetTime() - gClientData[client].Time) / 60.0);
						if (iDelay > gCvarList.GAMEMODE_ROUNDTIME_ZP.IntValue || gServerData.RoundMode == -1)
						{
							ToolsSetTeam(client, (client & 1) ? TEAM_ZOMBIE : TEAM_HUMAN);
							
							if (gServerData.RoundMode == -1)
							{
								ToolsForceToRespawn(client);
							}
							else
							{   
								DeathOnClientRespawn(client, _, false);
							}

							if (gClientData[client].Time <= 0) 
							{
								gClientData[client].Time = GetTime();
								
								DataBaseOnClientUpdate(client, ColumnType_Time);
							}
							
							return Plugin_Handled;
						}
					}
				}
			}

			case TEAM_SPECTATOR :
			{
				switch (iTeam)
				{
					case TEAM_HUMAN, TEAM_ZOMBIE :
					{
						if (gServerData.RoundMode == -1)
						{
							ToolsSetTeam(client, (client & 1) ? TEAM_ZOMBIE : TEAM_HUMAN);
							
							ToolsForceToRespawn(client);
							
							return Plugin_Handled;
						}
					}
				}
			}
			
			case TEAM_ZOMBIE :
			{
				switch (iTeam)
				{
					case TEAM_NONE, TEAM_HUMAN : return Plugin_Handled;
				}
			}
			
			case TEAM_HUMAN :
			{
				switch (iTeam)
				{
					case TEAM_NONE, TEAM_ZOMBIE : return Plugin_Handled;
				}
			}
		}
		
		AccountOnClientSpawn(client);
		LevelSystemOnClientSpawn(client);
		VOverlayOnClientSpawn(client);
		VEffectsOnClientSpawn(client);
		WeaponsOnClientSpawn(client);
	}
	
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
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsClientValid(client))
	{
		return Plugin_Continue;
	}

	ApplyOnClientSpawn(client);
	
	return Plugin_Continue;
}

/**
 * @brief Teleport client to a random spawn position.
 * 
 * @param client            The client index.
 **/
void SpawnTeleportToRespawn(int client)
{
	static float vPosition[3]; float vMaxs[3]; float vMins[3]; 

	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	int iSize = gServerData.Spawns.Length;
	for (int i = 0; i < iSize; i++)
	{
		gServerData.Spawns.GetArray(i, vPosition, sizeof(vPosition));
		
		TR_TraceHullFilter(vPosition, vPosition, vMins, vMaxs, MASK_SOLID, AntiStickFilter, client);
		
		if (!TR_DidHit())
		{
			TeleportEntity(client, vPosition, NULL_VECTOR, NULL_VECTOR);
			return;
		}
	}
}
