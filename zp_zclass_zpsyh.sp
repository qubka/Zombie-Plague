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
	name            = "[ZP] Zombie Class: Psyh",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gTrail;

// Timer index
Handle hZombieScream[MAXPLAYERS+1] = { null, ... }; 

// Sound index
int gSound;
 
// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillRadius;
ConVar hCvarSkillDamage;
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{ 
	// Initialize cvars
	hCvarSkillRadius = CreateConVar("zp_zclass_psyh_radius", "250.0", "Wave radius", 0, true, 0.0);
	hCvarSkillDamage = CreateConVar("zp_zclass_psyh_damage", "1.0", "Damage amount", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_psyh_effect", "hell_end", "Particle effect for the skill (''-off)");
	
	// Generate config
	AutoExecConfig(true, "zp_zclass_psyh", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("psyh");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"psyh\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("PSYH_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"PSYH_SKILL_SOUNDS\" wasn't find");
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
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Purge timer
		hZombieScream[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	// Delete timer
	delete hZombieScream[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	// Delete timer
	delete hZombieScream[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	// Delete timer
	delete hZombieScream[client];
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie)
	{
		// Create scream damage task
		delete hZombieScream[client];
		hZombieScream[client] = CreateTimer(0.1, ClientOnScreaming, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_SKILL);
		
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		// Validate effect
		if (hasLength(sEffect))
		{
			// Create an effect
			static float vPosition[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
			UTIL_CreateParticle(client, vPosition, _, _, sEffect, ZP_GetClassSkillDuration(gZombie));
		}
	}
	
	// Allow usage
	return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param client            The client index.
 **/
public void ZP_OnClientSkillOver(int client)
{
	// Validate the zombie class index
	if (ZP_GetClientClass(client) == gZombie) 
	{
		// Delete timer
		delete hZombieScream[client];
	}
}

/**
 * @brief Timer for the screamming process.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientOnScreaming(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);
	
	// Validate client
	if (client)
	{
		// Gets client origin
		static float vPosition[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition); vPosition[2] += 25.0;  

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
			ZP_TakeDamage(i, client, client, flDamage, DMG_SONIC);
		}
	   
		// Create a beamring effect            <Diameter>
		TE_SetupBeamRingPoint(vPosition, 50.0, flRadius * 2.0, gTrail, 0, 1, 10, 1.0, 15.0, 0.0, {255, 0, 0, 200}, 50, 0);
		TE_SendToAll();
		
		// Allow timer
		return Plugin_Continue;
	}

	// Clear timer
	hZombieScream[client] = null;

	// Destroy timer
	return Plugin_Stop;
}
