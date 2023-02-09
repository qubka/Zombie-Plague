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
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gBeam; int gHalo; 

// Sound index
int gSound;
 
// Zombie index
int gZombie;

// Type index
int gType;

// Cvars
ConVar hCvarSkillLast;
ConVar hCvarSkillSingle;
ConVar hCvarSkillRadius;
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarSkillLast   = CreateConVar("zp_zclass_range_last", "0", "Can a last human be infected?", 0, true, 0.0, true, 1.0);
	hCvarSkillSingle = CreateConVar("zp_zclass_range_single", "1", "Only 1 human can be infected?", 0, true, 0.0, true, 1.0);
	hCvarSkillRadius = CreateConVar("zp_zclass_range_radius", "200.0", "Infection radius", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_range_effect", "explosion_hegrenade_dirt", "Particle effect for the skill (''-default)");
	
	// Generate config
	AutoExecConfig(true, "zp_zclass_range", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("range");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"range\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("RANGE_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"RANGE_SKILL_SOUNDS\" wasn't find");
	
	// Types
	gType = ZP_GetClassTypeID("zombie");
	if (gType == -1) SetFailState("[ZP] Custom class type ID from name : \"zombie\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
	gBeam = PrecacheModel("materials/sprites/lgtning.vmt", true);
	gHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
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
		
		// Gets skill variables
		float flRadius = hCvarSkillRadius.FloatValue;
		bool bLast = hCvarSkillLast.BoolValue;
		bool bSingle = hCvarSkillSingle.BoolValue;
			
		// Validate infection round
		if (ZP_IsGameModeInfect(ZP_GetCurrentGameMode()) && ZP_IsStartedRound())
		{
			// Find any players in the radius
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
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
				
				// Can last human be infected ?
				if (!bLast && ZP_GetHumanAmount() <= 1)
				{
					break;
				}
		  
				// Change class to zombie
				ZP_ChangeClient(i, client, gType);
				
				// Single infection ?
				if (bSingle)
				{
					break;
				}
			}
		}
		
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		// Validate effect
		if (hasLength(sEffect))
		{
			// Create an explosion effect
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
		}
		else
		{
			// Create a simple effect
			TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {75, 255, 75, 255}, 0, 0);
			TE_SendToAll();
		}
		
		// Play sound
		ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD, SNDLEVEL_EXPLOSION); 
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
