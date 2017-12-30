/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
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

#include <sourcemod>
#include <cstrike>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin AutoRespawn =
{
	name        	= "[ZP] Addon: Auto-Respawn on Connect",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Addon respawn new players on first connection",
	version     	= "4.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * SteamID lenght.
 **/
#define STEAMID_MAX_LENGTH 	32

/**
 * Delay before respawning of the new player.
 **/
#define AUTORESPAWN_DELAY   10.0

/**
 * Create array for storing player.
 **/
char SteamID[MAXPLAYERS+1][STEAMID_MAX_LENGTH];
char DataSteamID[MAXPLAYERS+1][STEAMID_MAX_LENGTH];

/**
 * The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
	// Reset any saved data on the map end
	for (int i = 0; i < sizeof(DataSteamID); i++)
	{
		DataSteamID[i][0] = 0;
	}
}

/**
 * Called when a client is disconnected from the server.
 *
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect_Post(int clientIndex)
{
	#pragma unused clientIndex

	// Save player ID
	DataSteamID[clientIndex] = SteamID[clientIndex];
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex		The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
	#pragma unused clientIndex
	
	// Verify that the client is non-bot
	if(IsFakeClient(clientIndex))
	{
		return;
	}
	
	// Get client's authentication string (SteamID)
	GetClientAuthId(clientIndex, AuthId_Steam2, SteamID[clientIndex], sizeof(SteamID));	
	
	// Player is new one ? If true, then can respawn
	for (int i = 0; i < sizeof(DataSteamID); i++)
	{
		if(StrEqual(SteamID[clientIndex], DataSteamID[i]))
		{
			return;
		}
	}
	
	// Create respawning timer
	CreateTimer(AUTORESPAWN_DELAY, EventAutoRespawn, clientIndex, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * The player is about to respawn.
 *
 * @param hTimer			The timer handle.
 * @param clientIndex		The client index.
 **/
public Action EventAutoRespawn(Handle hTimer, any clientIndex)
{
	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		return Plugin_Stop;
	}
	
	// If round end, then stop
	if(!ZP_GetRoundState(SERVER_ROUND_END))
	{
		// Initialize round type
		int CMode = ZP_GetRoundState(SERVER_ROUND_MODE);

		// Switch game round
		switch(CMode)
		{
			// If specific game round, then stop respawn
			case MODE_SURVIVOR, MODE_ARMAGEDDON : { /*void*/ }
			
			// If not those
			default :
			{
				// Verify that the client is dead
				if(!IsPlayerAlive(clientIndex))
				{
					// Force a human respawn
					ZP_ForceClientRespawn(clientIndex);
				}
			}
		}
	}
	
	// Destroy timer
	return Plugin_Stop;
}