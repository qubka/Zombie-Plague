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
public Plugin ZombieClassRange =
{
	name        	= "[ZP] Zombie Class: Range",
	author      	= "qubka (Nikita Ushakov)",
	description 	= "Addon of zombie classses",
	version     	= "4.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME				"@Range" // If string has @, phrase will be taken from translation file
#define ZOMBIE_CLASS_MODEL				"models/player/custom_player/zombie/zombie_range/zombie_range.mdl"	
#define ZOMBIE_CLASS_CLAW				"models/player/custom_player/zombie/zombie_range/hand/hand_zombie_range.mdl"	
#define ZOMBIE_CLASS_HEALTH				2000
#define ZOMBIE_CLASS_SPEED				0.9
#define ZOMBIE_CLASS_GRAVITY			0.9
#define ZOMBIE_CLASS_KNOCKBACK			1.0
#define ZOMBIE_CLASS_LEVEL				1
#define ZOMBIE_CLASS_FEMALE				NO
#define ZOMBIE_CLASS_VIP				NO
#define ZOMBIE_CLASS_DURATION			0	
#define ZOMBIE_CLASS_COUNTDOWN			0
#define ZOMBIE_CLASS_REGEN_HEALTH		500
#define ZOMBIE_CLASS_REGEN_INTERVAL		10.0
/**
 * @endsection
 **/

 // Initialize zombie class index
int gZombieRange;
#pragma unused gZombieRange

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(StrEqual(sLibrary, "zombieplague"))
    {
        // Initilizate zombie class
        gZombieRange = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME, 
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW, 
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_FEMALE,
        ZOMBIE_CLASS_VIP, 
        ZOMBIE_CLASS_DURATION, 
        ZOMBIE_CLASS_COUNTDOWN, 
        ZOMBIE_CLASS_REGEN_HEALTH, 
        ZOMBIE_CLASS_REGEN_INTERVAL);
        
        // Hook events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
    }
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Sprites
	PrecacheModel("materials/sprites/xfireball3.vmt");
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook       	The event handle.
 * @param gEventName      	The name of the event.
 * @param dontBroadcast   	If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventPlayerDeath(Event gEventHook, const char[] gEventName, bool dontBroadcast) 
{
	// Get all required event info
	int clientIndex   = GetClientOfUserId(GetEventInt(gEventHook, "userid"));

	// Validate client
	if(!IsPlayerExist(clientIndex, false))
	{
		// If the client isn't a player, a player really didn't die now. Some
		// other mods might sent this event with bad data.
		return;
	}
	
	// Validate the zombie class index
	if(ZP_GetClientZombieClass(clientIndex) == gZombieRange)
	{
		// Initialize vectors
		static float vClientPosition[3];

		// Gets the client's origin
		GetClientAbsOrigin(clientIndex, vClientPosition);

		// Create an explosion entity
		int iExplosion = CreateEntityByName("env_explosion");

		// If explosion entity isn't valid, then stop.
		if(iExplosion)
		{
			// Spawn the entity into the world
			DispatchSpawn(iExplosion);

			// Set the origin of the explosion
			DispatchKeyValueVector(iExplosion, "origin", vClientPosition);

			// Set fireball material
			DispatchKeyValue(iExplosion, "fireballsprite", "materials/sprites/xfireball3.vmt");

			// Tell the entity to explode
			AcceptEntityInput(iExplosion, "Explode");

			// Remove entity from world
			AcceptEntityInput(iExplosion, "Kill");
		}
	}
}