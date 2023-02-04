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
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Zombie Class: Smoker",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Sound index
int gSound;

// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillDelay;
ConVar hCvarSkillDamage;
ConVar hCvarSkillRadius;
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarSkillDelay  = CreateConVar("zp_zclass_smoker_delay", "0.5", "Delay between damage trigger", 0, true, 0.0);
	hCvarSkillDamage = CreateConVar("zp_zclass_smoker_damage", "5.0", "Damage amount", 0, true, 0.0);
	hCvarSkillRadius = CreateConVar("zp_zclass_smoker_radius", "200.0", "Cloud radius", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_smoker_effect", "explosion_smokegrenade_base_green", "Particle effect for the skill");
	
	// Generate config
	AutoExecConfig(true, "zp_zclass_smoker", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("smoker");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"smoker\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("SMOKE_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SMOKE_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                             (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie)
	{
		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);

		// Gets client origin
		static float vPosition[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
				
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));

		// Create a smoke effect
		int entity = UTIL_CreateParticle(_, vPosition, _, _, sEffect, ZP_GetClassSkillDuration(gZombie));
		
		// Validate entity
		if (entity != -1)
		{
			// Sets parent for the entity
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
	
			// Create gas damage task
			CreateTimer(hCvarSkillDelay.FloatValue, ClientOnToxicGas, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	// Allow usage
	return Plugin_Continue;
}

/**
 * @brief Timer for the toxic gas process.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action ClientOnToxicGas(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Gets entity position
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
 
		// Gets owner index
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
		// Gets skill variables
		float flRadius = hCvarSkillRadius.FloatValue;
		float flDamage = hCvarSkillDamage.FloatValue;
		
		// Find any players in the radius
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			// Skip zombies
			if (ZP_IsPlayerZombie(i))
			{
				continue;
			}

			// Create the damage for victim
			ZP_TakeDamage(i, owner, owner, flDamage, DMG_NERVEGAS);
		}
		
		// Allow timer
		return Plugin_Continue;
	}

	// Destroy timer
	return Plugin_Stop;
}