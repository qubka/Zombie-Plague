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
public Plugin ZombieClassTank =
{
	name        	= "[ZP] Zombie Class: Tank",
	author      	= "qubka (Nikita Ushakov)",
	description 	= "Addon of zombie classses",
	version     	= "4.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME				"@Tank" // If string has @, phrase will be taken from translation file	
#define ZOMBIE_CLASS_MODEL				"models/player/custom_player/zombie/sherif/sherif.mdl"
#define ZOMBIE_CLASS_CLAW				"models/player/custom_player/zombie/sherif/hand/hand_zombie_normal.mdl"
#define ZOMBIE_CLASS_HEALTH				8000
#define ZOMBIE_CLASS_SPEED				0.8
#define ZOMBIE_CLASS_GRAVITY			1.0
#define ZOMBIE_CLASS_KNOCKBACK			0.5
#define ZOMBIE_CLASS_LEVEL				1
#define ZOMBIE_CLASS_FEMALE				NO
#define ZOMBIE_CLASS_VIP				NO
#define ZOMBIE_CLASS_DURATION			3	
#define ZOMBIE_CLASS_COUNTDOWN			40
#define ZOMBIE_CLASS_REGEN_HEALTH		400
#define ZOMBIE_CLASS_REGEN_INTERVAL		2.0
/**
 * @endsection
 **/

// Initialize zombie class index
int gZombieTank; 
#pragma unused gZombieTank

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
        gZombieTank = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME, 
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

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Sounds
	FakePrecacheSound("zbm3/zombi_pressure.mp3");
	FakePrecacheSound("zbm3/zombi_pressure_female.mp3");
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex		The client index.
 *
 * @return					Plugin_Handled to block using skill. Anything else
 *                          	(like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return Plugin_Handled;
	}
	
	// Validate the zombie class index
	if(ZP_GetClientZombieClass(clientIndex) == gZombieTank)
	{
		// Set color
		SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);  
		SetEntityRenderColor(clientIndex, 0, 0, 0, 255);
		
		// Emit sound
		EmitSoundToAll("*/zbm3/zombi_pressure.mp3", clientIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
	}
	
	// Allow usage
	return Plugin_Continue;
}

/**
 * Called when a zombie skill duration is over.
 * 
 * @param clientIndex		The client index.
 **/
public void ZP_OnClientSkillOver(int clientIndex)
{
	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}

	// Validate the zombie class index
	if(ZP_GetClientZombieClass(clientIndex) == gZombieTank)
	{
		// Remove color
		SetEntityRenderMode(clientIndex, RENDER_TRANSCOLOR);  
		SetEntityRenderColor(clientIndex, 255, 255, 255, 255); 
		
		// Emit sound
		EmitSoundToAll("*/zbm3/zombi_pressure_female.mp3", clientIndex, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
	}
}

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 * @param damageAmount		The amount of damage inflicted.
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount)
{
	#pragma unused clientIndex
	
	// Validate client
	if(!IsPlayerExist(clientIndex))
	{
		return;
	}
	
	// If client used the zombie skill, then stop appling damage
	if(ZP_IsPlayerZombie(clientIndex))
	{
		// Validate the zombie class index
		if(ZP_GetClientZombieClass(clientIndex) == gZombieTank && ZP_IsPlayerUseZombieSkill(clientIndex))
		{
			damageAmount *= 0.1;
		}
	}
}