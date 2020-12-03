/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
	name            = "[ZP] Zombie Class: Sleeper",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_CHANCE_CAST  20
#define ZOMBIE_CLASS_SKILL_DURATION_F   3.3
#define ZOMBIE_CLASS_SKILL_TIME_F       4.0
#define ZOMBIE_CLASS_SKILL_COLOR_F      {0, 0, 0, 255}
/**
 * @endsection
 **/

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
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
	gZombie = ZP_GetClassNameID("sleeper");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"sleeper\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("SLEEPER_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SLEEPER_SKILL_SOUNDS\" wasn't find");
	
	// Cvars
	hSoundLevel = FindConVar("zp_seffects_level");
	if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called after a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 * @param iHealth           The current health amount of a victim.
 * @param iArmor            The current armor amount of a victim.
 **/
public void ZP_OnClientDamaged(int client, int attacker, int inflictor, float flDamage, int iBits, int weapon, int iHealth, int iArmor)
{
	// Validate attacker
	if (!IsPlayerExist(attacker))
	{
		return;
	}
	
	// Initialize client chances
	static int iChance[MAXPLAYERS+1];

	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie)
	{
		// Generate the chance
		iChance[client] = GetRandomInt(0, 999);
		
		// Validate chance
		if (iChance[client] < ZOMBIE_CLASS_SKILL_CHANCE_CAST)
		{
			// Play sound
			ZP_EmitSoundToAll(gSound, 1, attacker, SNDCHAN_VOICE, hSoundLevel.IntValue);
			
			// Create an fade
			UTIL_CreateFadeScreen(attacker, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, FFADE_IN, ZOMBIE_CLASS_SKILL_COLOR_F);
			
			// Create effect
			static float vPosition[3];
			GetEntPropVector(attacker, Prop_Data, "m_vecAbsOrigin", vPosition);
			UTIL_CreateParticle(attacker, vPosition, _, _, "sila_trail_apalaal", ZOMBIE_CLASS_SKILL_DURATION_F);
		}
	}
}
