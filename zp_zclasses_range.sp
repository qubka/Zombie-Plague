/**
 * ============================================================================
 *
 *  Zombie Plague
 *
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

#include <sourcemod>
#include <sdktools>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Zombie Class: Range",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
 **/
//#define ZOMBIE_CLASS_EXP_LAST         // Can a last human be infected [uncomment-no // comment-yes]
#define ZOMBIE_CLASS_EXP_SINGLE         // Only 1 human can be infected [uncomment-no // comment-yes]
#define ZOMBIE_CLASS_EXP_RADIUS         200.0
#define ZOMBIE_CLASS_EXP_DURATION       2.0
/**
 * @endsection
 **/

// Sound index
int gSound;
#pragma unused gSound
 
// Zombie index
int gZombie;
#pragma unused gZombie

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		// If map loaded, then run custom forward
		if (ZP_IsMapLoaded())
		{
			// Execute it
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Classes
	gZombie = ZP_GetClassNameID("range");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"range\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("RANGE_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"RANGE_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie)
	{
		// Gets client origin
		static float vPosition[3]; 
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		// Validate infection round
		if (ZP_IsGameModeInfect(ZP_GetCurrentGameMode()) && ZP_IsStartedRound())
		{
#if !defined ZOMBIE_CLASS_EXP_LAST
			if (ZP_GetHumanAmount() > 1)
#endif
			{
				// Find any players in the radius
				int i; int it = 1; /// iterator
				while ((i = ZP_FindPlayerInSphere(it, vPosition, ZOMBIE_CLASS_EXP_RADIUS)) != -1)
				{
					// Skip zombies
					if (ZP_IsPlayerZombie(i))
					{
						continue;
					}

					// Validate visibility
					if (!UTIL_CanSeeEachOther(client, i, vPosition, SelfFilter))
					{
						continue;
					}
			  
					// Change class to zombie
					ZP_ChangeClient(i, client, "zombie");
					
#if defined ZOMBIE_CLASS_EXP_SINGLE
					// Stop loop
					break;
#endif
				}
			}
		}
		
		// Create an effect
		UTIL_CreateParticle(_, vPosition, _, _, "explosion_hegrenade_dirt", ZOMBIE_CLASS_EXP_DURATION);

		// Play sound
		ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD, SNDLEVEL_NORMAL); 
	}
}

/**
 * @brief Trace filter.
 *  
 * @param entity            The entity index.
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 *
 * @return                  True or false.
 **/
public bool SelfFilter(int entity, int contentsMask, int filter)
{
	return (entity != filter);
}
