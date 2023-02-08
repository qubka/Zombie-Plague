/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          teleport.sp
 *  Type:          Module 
 *  Description:   Teleport handle functions.
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

/*
 * Load other teleport modules
 */
#include "zp/manager/playerclasses/teleportmenu.sp"

/**
 * @brief Creates commands for Teleport module.
 **/
void TeleportOnCommandInit(/*void*/)
{
	// Create commands
	RegAdminCmd("zp_teleport_force", TeleportForceOnCommandCatched, ADMFLAG_GENERIC, "Force Teleport on a client. Usage: zp_teleport_force <client>");
	RegConsoleCmd("ztele", TeleportOnCommandCatched, "Teleport back to spawn.");
	
	// Forward event to sub-modules
	TeleportMenuOnCommandInit();
}

/**
 * @brief Hook account cvar changes.
 **/
void TeleportOnCvarInit(/*void*/)
{
	// Create cvars
	gCvarList.TELEPORT_ESCAPE          = FindConVar("zp_teleport_escape");
	gCvarList.TELEPORT_ZOMBIE          = FindConVar("zp_teleport_zombie");
	gCvarList.TELEPORT_HUMAN           = FindConVar("zp_teleport_human");
	gCvarList.TELEPORT_DELAY_ZOMBIE    = FindConVar("zp_teleport_delay_zombie");
	gCvarList.TELEPORT_DELAY_HUMAN     = FindConVar("zp_teleport_delay_human");
	gCvarList.TELEPORT_MAX_ZOMBIE      = FindConVar("zp_teleport_max_zombie");
	gCvarList.TELEPORT_MAX_HUMAN       = FindConVar("zp_teleport_max_human");
	gCvarList.TELEPORT_AUTOCANCEL      = FindConVar("zp_teleport_autocancel");
	gCvarList.TELEPORT_AUTOCANCEL_DIST = FindConVar("zp_teleport_autocancel_distance");
}

/**
 * Console command callback (zp_teleport_force)
 * @brief Force ZSpawn on a client.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action TeleportForceOnCommandCatched(int client, int iArguments)
{
	// If not enough arguments given, then stop
	if (iArguments < 1)
	{
		TranslationReplyToCommand(client, "teleport command force syntax");
		return Plugin_Handled;
	}
	
	// Initialize argument char
	static char sArgument[SMALL_LINE_LENGTH]; static char sName[SMALL_LINE_LENGTH]; int targets[MAXPLAYERS]; bool tn_is_ml;
	
	// Get targetname
	GetCmdArg(1, sArgument, sizeof(sArgument));
	
	// Find a target
	int iCount = ProcessTargetString(sArgument, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, sName, sizeof(sName), tn_is_ml);
	
	// Check if there was a problem finding a client
	if (iCount <= 0)
	{
		// Write error info
		TranslationReplyToCommand(client, "teleport invalid client");
		return Plugin_Handled;
	}
	
	// i = client index
	for (int i = 0; i < iCount; i++)
	{
		// Give client the item
		bool bSuccess = TeleportClient(targets[i], true);
		
		// Tell admin the outcome of the command if only 1 client was targetted
		if (iCount == 1)
		{
			if (bSuccess)
			{
				TranslationReplyToCommand(client, "teleport command force successful", sName);
			}
			else
			{
				TranslationReplyToCommand(client, "teleport command force unsuccessful", sName);
			}
		}
		
		// Log action to game events
		LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Teleport, "Force Teleport", "\"%L\" teleported \"%L\" to spawn.", client, targets[i]);
	}
	
	// Log action to game events
	return Plugin_Handled;
}

/**
 * Console command callback (teleport)
 * @brief Teleport back to spawn if you are stuck.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action TeleportOnCommandCatched(int client, int iArguments)
{
	TeleportClient(client);
	return Plugin_Handled;
}

/*
 * Stocks teleport API.
 */

/**
 * @brief Teleports a client back to spawn if conditions are met.
 * 
 * @param client            The client index.
 * @param bForce            (Optional) True to force teleporting of the client, false to follow rules.
 * @return                  True if teleport was successful, false otherwise. 
 **/
bool TeleportClient(int client, bool bForce = false)
{
	// Validate client
	if (!IsPlayerExist(client))
	{
		return false;
	}
	
	// If the cvar is disabled and the round are non-escape, then stop
	bool bTeleportEscape = gCvarList.TELEPORT_ESCAPE.BoolValue;
	if (!bForce && bTeleportEscape && !ModesIsEscape(gServerData.RoundMode))
	{
		// Tell client that feature is restricted at this time
		TranslationPrintToChat(client, "teleport restricted escape");
		return false;
	}
	
	// Is client is zombie ?
	bool bInfect = gClientData[client].Zombie;

	// If zombie cvar is disabled and the client is a zombie, then stop
	bool bTeleportZombie = gCvarList.TELEPORT_ZOMBIE.BoolValue;
	if (!bForce && bInfect && !bTeleportZombie)
	{
		// Tell client they must be human to use this feature
		TranslationPrintToChat(client, "teleport restricted zombie");
		return false;
	}

	// If zombie has spawned, get before value, get the after value otherwise
	// If the cvar is disabled and the client is a human, then stop
	bool bTeleportHuman = gCvarList.TELEPORT_HUMAN.BoolValue;
	if (!bForce && !bInfect && !bTeleportHuman)
	{
		// Tell client that feature is restricted at this time
		TranslationPrintToChat(client, "teleport restricted human");
		return false;
	}
	
	// If the tele limit has been reached, then stop
	int iTeleportMax = bInfect ? gCvarList.TELEPORT_MAX_ZOMBIE.IntValue : gCvarList.TELEPORT_MAX_HUMAN.IntValue;
	if (!bForce && gClientData[client].TeleTimes >= iTeleportMax)
	{
		// Tell client that they have already reached their limit
		TranslationPrintToChat(client, "teleport max", iTeleportMax);
		return false;
	}
	
	// If teleport is already in progress, then stop
	if (gClientData[client].TeleTimer != null)
	{
		if (!bForce)
		{
			TranslationPrintToChat(client, "teleport in progress");
		}
		return false;
	}
	
	// If we are forcing, then teleport now and stop
	if (bForce)
	{
		// Teleport client to spawn
		SpawnTeleportToRespawn(client);
		return true;
	}
	
	// Get current location
	ToolsGetAbsOrigin(client, gClientData[client].TeleOrigin);
	
	// Set timeleft array to value of respective cvar
	gClientData[client].TeleCounter = bInfect ? gCvarList.TELEPORT_DELAY_ZOMBIE.IntValue : gCvarList.TELEPORT_DELAY_HUMAN.IntValue;
	if (gClientData[client].TeleCounter > 0)
	{
		// Tell client how much time is left until teleport
		TranslationPrintHintText(client, "teleport countdown", gClientData[client].TeleCounter);
		
		// Start timer
		gClientData[client].TeleTimer = CreateTimer(1.0, TeleportOnClientCount, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
	else
	{
		// Teleport player back on the spawn point
		SpawnTeleportToRespawn(client);
		
		// Increment teleport count
		gClientData[client].TeleTimes++;
		
		// If we're forcing the Teleport, then don't increment the count or print how many teleports they have used
		// Tell client they've been teleported
		TranslationPrintHintText(client, "teleport countdown end", gClientData[client].TeleTimes, iTeleportMax);
	}
	
	// Return true on success
	return true;
}

/**
 * @brief Timer callback, counts down teleport to the client.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action TeleportOnClientCount(Handle timer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Validate auto cancel on movement
		if (gCvarList.TELEPORT_AUTOCANCEL.BoolValue)
		{
			// Gets origin position
			static float vPosition[3];
			ToolsGetAbsOrigin(client, vPosition); 
			
			// Gets the distance from starting origin
			float flDistance = GetVectorDistance(vPosition, gClientData[client].TeleOrigin);
			float flAutoCancelDist = gCvarList.TELEPORT_AUTOCANCEL_DIST.FloatValue;
  
			// Check if distance has been surpassed
			if (flDistance > flAutoCancelDist)
			{
				// Tell client teleport has been cancelled
				TranslationPrintHintText(client, "teleport autocancel centertext");
				TranslationPrintToChat(client, "teleport autocancel text", RoundToNearest(flAutoCancelDist));
				
				// Clear timer
				gClientData[client].TeleTimer = null;
				
				// Stop timer
				return Plugin_Stop;
			}
		}

		// Decrement time left
		gClientData[client].TeleCounter--;
		
		// Tell client how much time is left until teleport
		TranslationPrintHintText(client, "teleport countdown", gClientData[client].TeleCounter);
		
		// Time has expired
		if (gClientData[client].TeleCounter <= 0)
		{
			// Teleport player back on the spawn point
			SpawnTeleportToRespawn(client);
			
			// Increment teleport count
			gClientData[client].TeleTimes++;
			
			// Tell client spawn protection is over
			TranslationPrintHintText(client, "teleport countdown end", gClientData[client].TeleTimes, gClientData[client].Zombie ? gCvarList.TELEPORT_MAX_ZOMBIE.IntValue : gCvarList.TELEPORT_MAX_HUMAN.IntValue);
			
			// Clear timer
			gClientData[client].TeleTimer = null;
			
			// Destroy timer
			return Plugin_Stop;
		}
		
		// Allow timer
		return Plugin_Continue;
	}
	
	// Clear timer
	gClientData[client].TeleTimer = null;
	
	// Destroy timer
	return Plugin_Stop;
}