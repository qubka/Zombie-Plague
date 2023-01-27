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
	name            = "[ZP] Zombie Class: Girl",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_SPEED        3000.0
#define ZOMBIE_CLASS_SKILL_GRAVITY      0.01
#define ZOMBIE_CLASS_SKILL_EXP_RADIUS   150.0
#define ZOMBIE_CLASS_SKILL_EXP_TIME     2.0
#define ZOMBIE_CLASS_SKILL_WIDTH        3.0
#define ZOMBIE_CLASS_SKILL_WIDTH_END    1.0
#define ZOMBIE_CLASS_SKILL_COLOR        {209, 120, 9, 200}
#define ZOMBIE_CLASS_SKILL_COLOR_F      {209, 120, 9, 75}
#define ZOMBIE_CLASS_SKILL_DURATION_F   0.3
#define ZOMBIE_CLASS_SKILL_TIME_F       1.0
#define ZOMBIE_CLASS_SKILL_FIRE         10.0
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
	gZombie = ZP_GetClassNameID("girl");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"girl\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("DEIMOS_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"DEIMOS_SKILL_SOUNDS\" wasn't find");
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
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vSpeed[3];
		
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
			GetAngleVectors(vAngle, vSpeed, NULL_VECTOR, NULL_VECTOR);
			
			// Normalize the vector (equal magnitude at varying distances)
			NormalizeVector(vSpeed, vSpeed);
			
			// Apply the magnitude by scaling the vector
			ScaleVector(vSpeed, ZOMBIE_CLASS_SKILL_SPEED);

			// Adds two vectors
			AddVectors(vSpeed, vVelocity, vSpeed);

			// Push the bomb
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vSpeed);

			// Sets parent for the entity
			SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

			// Sets gravity
			SetEntPropFloat(entity, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY); 

			// Put fire on it
			UTIL_IgniteEntity(entity, ZOMBIE_CLASS_SKILL_FIRE);
			
			// Create an effect
			UTIL_CreateParticle(entity, vPosition, _, _, "gamma_trail_xz", 5.0);
	
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
		
		// Create an explosion effect
		UTIL_CreateParticle(_, vPosition, _, _, "pyrovision_explosion", ZOMBIE_CLASS_SKILL_EXP_TIME);
		
		// Play sound
		ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

		// Find any players in the radius
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, ZOMBIE_CLASS_SKILL_EXP_RADIUS)) != -1)
		{
			// Skip zombies
			if (ZP_IsPlayerZombie(i))
			{
				continue;
			}

			// Simple droping of the weapon
			FakeClientCommandEx(i, "drop");

			// Create an fade
			UTIL_CreateFadeScreen(i, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, FFADE_IN, ZOMBIE_CLASS_SKILL_COLOR_F);
		}

		// Remove entity from world
		AcceptEntityInput(entity, "Kill");
	}

	// Return on the success
	return Plugin_Continue;
}
