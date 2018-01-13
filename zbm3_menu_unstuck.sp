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
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin UnStuck =
{
	name        	= "[ZP] Menu: UnStuck",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "Menu for unstucking player and teleport them on respawn point",
	version     	= "1.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Array to store spawn origin
float gOrigin[MAXPLAYERS+1][3];

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(StrEqual(sLibrary, "zombieplague"))
    {
        // Create a command
        RegConsoleCmd("zstuck", Command_Unstuck, "Unstuck player from the another entity.");
        
        // Hook spawn event
        HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
    }
}

/**
 * Handles the zstuck command. Unstuck player from the another entity.
 * 
 * @param clientIndex		The client index.
 * @param iArguments		The number of arguments that were in the argument string.
 **/ 
public Action Command_Unstuck(int clientIndex, int iArguments)
{
	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	/* 
	 * Checks to see if a player would collide with MASK_SOLID. (i.e. they would be stuck)
	 * Inflates player mins/maxs a little bit for better protection against sticking.
	 * Thanks to Andersso for the basis of this function.
	 */
	
	// Initialize vector variables
	float flOrigin[3];
	float flMax[3]; 
	float flMin[3]; 

	// Get client's location
	GetClientAbsOrigin(clientIndex, flOrigin);
	
	// Get the client's min and max size vector
	GetClientMins(clientIndex, flMin);
	GetClientMaxs(clientIndex, flMax);

	// Starts up a new trace hull using a global trace result and a customized trace ray filter
	TR_TraceHullFilter(flOrigin, flOrigin, flMin, flMax, MASK_SOLID, FilterStuck, clientIndex);

	// Returns if there was any kind of collision along the trace ray
	if(TR_DidHit())
	{
		// Teleport player back on the previus spawn point
		TeleportEntity(clientIndex, gOrigin[clientIndex], NULL_VECTOR, NULL_VECTOR);
	}
	else
	{
		// Emit fail sound
		ClientCommand(clientIndex, "play buttons/button11.wav");	
	}
}

/**
 * Event callback (player_spawn)
 * The player is spawning.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @dontBroadcast   	    If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerSpawn(Event gEventHook, const char[] gEventName, bool dontBroadcast)
{
	// Get real player index from event key
	int clientIndex = GetClientOfUserId(GetEventInt(gEventHook, "userid")); 

	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// Get client's position
	GetClientAbsOrigin(clientIndex, gOrigin[clientIndex]);
}


/*
 * Trace filtering functions
 */

 
/**
 * Trace filter.
 *
 * @param clientIndex		The client index.
 * @param contentsMask		The contents mask.
 * @param victimIndex		The victim index.
 **/
public bool FilterStuck(int clientIndex, int contentsMask, any victimIndex) 
{
    return (clientIndex != victimIndex);
}