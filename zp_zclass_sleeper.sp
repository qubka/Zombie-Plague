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
	name            = "[ZP] Zombie Class: Sleeper",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gTrail;
#pragma unused gTrail

// Sound index
int gSound;
#pragma unused gSound
 
// Zombie index
int gZombie;
#pragma unused gZombie

// Cvars
ConVar gCvarSkillChance;
ConVar gCvarSkillDuration;
ConVar gCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	gCvarSkillChance   = CreateConVar("zp_zclass_sleeper_chance", "20", "Smaller = more likely", 0, true, 0.0, true, 999.0);
	gCvarSkillDuration = CreateConVar("zp_zclass_sleeper_duration", "3.5", "Sleep duration", 0, true, 0.0);
	gCvarSkillEffect   = CreateConVar("zp_zclass_sleeper_effect", "sila_trail_apalaal", "Particle effect for the skill (''-default)");

	// Generate config
	AutoExecConfig(true, "zp_zclass_sleeper", "sourcemod/zombieplague");
}

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
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
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
		if (iChance[client] < gCvarSkillChance.IntValue)
		{
			// Play sound
			ZP_EmitSoundToAll(gSound, 1, attacker, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
			
			// Gets skill duration
			float flDuration = gCvarSkillDuration.FloatValue;
			
			// Create an fade
			UTIL_CreateFadeScreen(attacker, flDuration, flDuration + 0.5, FFADE_IN, {0, 0, 0, 255});
			
			// Gets particle name
			static char sEffect[SMALL_LINE_LENGTH];
			gCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
			
			// Validate effect
			if (hasLength(sEffect))
			{
				// Create an effect
				static float vPosition[3];
				GetEntPropVector(attacker, Prop_Data, "m_vecAbsOrigin", vPosition);
				UTIL_CreateParticle(attacker, vPosition, _, _, sEffect, flDuration);
			}
			else
			{
				// Create an trail effect
				TE_SetupBeamFollow(attacker, gTrail, 0, flDuration, 6.0, 6.0, 3, {80, 200, 120, 200});
				TE_SendToAll();	
			}
		}
	}
}
