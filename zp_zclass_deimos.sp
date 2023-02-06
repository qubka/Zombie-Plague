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
	name            = "[ZP] Zombie Class: Deimos",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gBeam; int gHalo; int gTrail;

// Sound index
int gSound;
 
// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillSpeed;
ConVar hCvarSkillRadius;
ConVar hCvarSkillEffect;
ConVar hCvarSkillExp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	hCvarSkillSpeed  = CreateConVar("zp_zclass_deimos_speed", "3000.0", "Speed of sting", 0, true, 0.0);
	hCvarSkillRadius = CreateConVar("zp_zclass_deimos_radius", "150.0", "Dropping radius", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_deimos_effect", "gamma_trail_xz", "Particle effect for the skill (''-default)");
	hCvarSkillExp    = CreateConVar("zp_zclass_deimos_explosion", "pyrovision_explosion", "Particle effect for the skill explosion (''-default)");
	
	// Generate config
	AutoExecConfig(true, "zp_zclass_deimos", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("deimos");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"deimos\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("DEIMOS_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"DEIMOS_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	gBeam = PrecacheModel("materials/sprites/lgtning.vmt", true);
	gHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
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
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];
		
		// Gets client eye position
		GetClientEyePosition(client, vPosition);
		
		// Gets client eye angle
		GetClientEyeAngles(client, vAngle);

		// Gets client speed
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
		
		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
		
		// Create a bomb entity
		int entity = UTIL_CreateProjectile(vPosition, vAngle);
		
		// Validate entity
		if (entity != -1)
		{
			// Sets bomb model scale
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.0);
			
			// Returns vectors in the direction of an angle
			GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);
			
			// Normalize the vector (equal magnitude at varying distances)
			NormalizeVector(vEndVelocity, vEndVelocity);
			
			// Apply the magnitude by scaling the vector
			ScaleVector(vEndVelocity, hCvarSkillSpeed.FloatValue);

			// Adds two vectors
			AddVectors(vEndVelocity, vVelocity, vEndVelocity);

			// Push the bomb
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

			// Sets parent for the entity
			SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

			// Sets gravity
			SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 

			// Gets particle name
			static char sEffect[SMALL_LINE_LENGTH];
			hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
			
			// Validate effect
			if (hasLength(sEffect))
			{
				// Create an effect
				UTIL_CreateParticle(entity, vPosition, _, _, sEffect, 10.0);
			}
			else
			{
				// Create an trail effect
				TE_SetupBeamFollow(entity, gTrail, 0, 5.0, 3.0, 3.0, 1, {209, 120, 9, 200});
				TE_SendToAll();	
			}
			
			// Put fire on it
			UTIL_IgniteEntity(entity, 10.0);
			
			// Create touch hook
			SDKHook(entity, SDKHook_Touch, BombTouchHook);
		}
	}
	
	// Allow usage
	return Plugin_Continue;
}

/**
 * @brief Bomb touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action BombTouchHook(int entity, int target)
{
	// Validate target
	if (IsValidEdict(target))
	{
		// Validate thrower
		if (GetEntPropEnt(entity, Prop_Data, "m_hThrower") == target)
		{
			// Return on the unsuccess
			return Plugin_Continue;
		}

		// Gets entity position
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		// Gets skill radius
		float flRadius = hCvarSkillRadius.FloatValue;

		// Find any players in the radius
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			// Skip zombies
			if (ZP_IsPlayerZombie(i))
			{
				continue;
			}

			// Simple and safe droping of the weapon
			FakeClientCommandEx(i, "drop");

			// Create an fade
			UTIL_CreateFadeScreen(i, 0.3, 1.0, FFADE_IN, {209, 120, 9, 75});
			
			// Create a shake
			UTIL_CreateShakeScreen(i, 2.0, 1.0, 3.0);
		}
		
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillExp.GetString(sEffect, sizeof(sEffect));
		
		// Validate effect
		if (hasLength(sEffect))
		{
			// Create an explosion effect
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
		}
		else
		{
			// Create a simple effect
			TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {209, 120, 9, 255}, 0, 0);
			TE_SendToAll();
		}
			
		// Play sound
		ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

		// Remove entity from world
		AcceptEntityInput(entity, "Kill");
	}

	// Return on the success
	return Plugin_Continue;
}
