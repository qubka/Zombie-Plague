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
public Plugin ZombieClassPsyh =
{
	name        	= "[ZP] Zombie Class: Psyh",
	author      	= "qubka (Nikita Ushakov)",
	description 	= "Addon of zombie classses",
	version     	= "4.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME				"@Psyh" // If string has @, phrase will be taken from translation file		 
#define ZOMBIE_CLASS_MODEL				"models/player/custom_player/zombie/normalhost/normalhost.mdl"
#define ZOMBIE_CLASS_CLAW				"models/player/custom_player/zombie/normalhost/hand/hand_zombie_normalhost.mdl"
#define ZOMBIE_CLASS_HEALTH				7000
#define ZOMBIE_CLASS_SPEED				1.1
#define ZOMBIE_CLASS_GRAVITY			0.8
#define ZOMBIE_CLASS_KNOCKBACK			1.0
#define ZOMBIE_CLASS_LEVEL				1
#define ZOMBIE_CLASS_FEMALE				NO
#define ZOMBIE_CLASS_VIP				NO
#define ZOMBIE_CLASS_DURATION			0
#define ZOMBIE_CLASS_COUNTDOWN			0	
#define ZOMBIE_CLASS_REGEN_HEALTH		50
#define ZOMBIE_CLASS_REGEN_INTERVAL		2.0
/**
 * @endsection
 **/

// Initialize zombie class index
int gZombiePsyh;
#pragma unused gZombiePsyh

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
        gZombiePsyh = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME, 
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
    }
}