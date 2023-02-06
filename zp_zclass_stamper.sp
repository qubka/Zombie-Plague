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
	name            = "[ZP] Zombie Class: Stamper",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT             5.0
#define METAL_GIBS_DELAY              0.05
#define METAL_GIBS_SPEED              500.0
#define METAL_GIBS_VARIENCE           1.0  
#define METAL_GIBS_LIFE               1.0  
#define METAL_GIBS_DURATION           2.0
/**
 * @endsection
 **/

// Decal index
int gBeam; int gHalo; 

// Sound index
int gSound;
 
// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillAttach;
ConVar hCvarSkillHealth;
ConVar hCvarSkillRadius;
ConVar hCvarSkillKnockback;
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{  
	// Initialize cvars
	hCvarSkillAttach    = CreateConVar("zp_zclass_stamper_attach", "250.0", "Speed of attached victim", 0, true, 0.0);
	hCvarSkillHealth    = CreateConVar("zp_zclass_stamper_health", "200.0 ", "Health of coffin", 0, true, 0.0);
	hCvarSkillRadius    = CreateConVar("zp_zclass_stamper_radius", "250.0", "Radius of coffin attachment", 0, true, 0.0);
	hCvarSkillKnockback = CreateConVar("zp_zclass_stamper_knockback", "1000.0", "Knockback on coffin explosion", 0, true, 0.0);
	hCvarSkillEffect    = CreateConVar("zp_zclass_stamper_effect", "explosion_hegrenade_dirt", "Particle effect for the skill (''-default)");
	
	// Generate config
	AutoExecConfig(true, "zp_zclass_stamper", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("stamper");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"stamper\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("COFFIN_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"COFFIN_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
	gBeam = PrecacheModel("materials/sprites/lgtning.vmt", true);
	gHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	PrecacheModel("models/gibs/metal_gib1.mdl", true);
	PrecacheModel("models/gibs/metal_gib2.mdl", true);
	PrecacheModel("models/gibs/metal_gib3.mdl", true);
	PrecacheModel("models/gibs/metal_gib4.mdl", true);
	PrecacheModel("models/gibs/metal_gib5.mdl", true);
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
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3];

		// Gets weapon position
		ZP_GetPlayerEyePosition(client, 60.0, _, _, vPosition);
		GetClientEyeAngles(client, vAngle); vAngle[0] = vAngle[2] = 0.0; /// Only pitch
		
		// Initialize the hull vectors
		static const float vMins[3] = { -3.077446, -9.829969, -37.660713 }; 
		static const float vMaxs[3] = { 11.564661, 20.737569, 38.451633  }; 
		
		// Create the hull trace
		vPosition[2] += vMaxs[2] / 2.0; /// Move center of hull upward
		TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
		
		// Validate no collisions
		if (!TR_DidHit())
		{
			// Create a physics entity
			int entity = UTIL_CreatePhysics("coffin", vPosition, vAngle, "models/player/custom_player/zombie/zombiepile/zombiepile.mdl", PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);

			// Validate entity
			if (entity != -1)
			{
				// Sets physics
				SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
				SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
				
				// Sets owner to the entity
				SetEntPropEnt(entity, Prop_Data, "m_pParent", client);

				// Validate health
				int iHealth = hCvarSkillHealth.IntValue;
				if (iHealth > 0)
				{
					// Sets health
					SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
					SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
					SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHealth);

					// Create damage hook
					SDKHook(entity, SDKHook_OnTakeDamage, CoffinDamageHook);
				}
				
				// Play sound
				ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, SNDLEVEL_SKILL);
				
				// Create remove/idle/think hook
				CreateTimer(ZP_GetClassSkillDuration(gZombie), CoffinExploadHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, CoffinIdleHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.1, CoffinThinkHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	// Allow usage
	return Plugin_Continue;
}

/**
 * @brief Coffin damage hook.
 *
 * @param entity            The entity index.    
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action CoffinDamageHook(int entity, int &attacker, int &inflictor, float &flDamage, int &iBits)
{
	// Calculate the damage
	int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

	// Destroy entity
	if (!iHealth)
	{
		// Destroy damage hook
		SDKUnhook(entity, SDKHook_OnTakeDamage, CoffinDamageHook);

		// Expload it
		CoffinExpload(entity);
	}
	else
	{
		// Play sound
		ZP_EmitSoundToAll(gSound, GetRandomInt(2, 3), entity, SNDCHAN_STATIC, SNDLEVEL_HURT);
		
		// Apply damage
		SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
	}

	// Return on success
	return Plugin_Handled;
}

/**
 * @brief Main timer for coffin idle.
 * 
 * @param hTimer            The timer handle.
 * @param refID             The reference index.                    
 **/
public Action CoffinIdleHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Play sound
		ZP_EmitSoundToAll(gSound, GetRandomInt(5, 6), entity, SNDCHAN_VOICE, SNDLEVEL_SKILL);
	}
	else
	{
		// Destroy think
		return Plugin_Stop;
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Main timer for coffin think.
 * 
 * @param hTimer            The timer handle.
 * @param refID             The reference index.                    
 **/
public Action CoffinThinkHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vPosition2[3];  

		// Gets entity position
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
	
		// Gets skill variables
		float flRadius = hCvarSkillRadius.FloatValue;
		float flAttach = hCvarSkillAttach.FloatValue;
	
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
			if (!UTIL_CanSeeEachOther(entity, i, vPosition, SelfFilter))
			{
				continue;
			}
			
			// Gets target's eye position 
			GetClientEyePosition(i, vPosition2);
			
			// Push the target
			UTIL_GetVelocityByAim(vPosition2, vPosition, vAngle, vVelocity, flAttach);
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vVelocity);
		}
	}
	else
	{
		// Destroy think
		return Plugin_Stop;
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Main timer for exploade coffin.
 * 
 * @param hTimer            The timer handle.
 * @param refID             The reference index.                    
 **/
public Action CoffinExploadHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Expload it
		CoffinExpload(entity);
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Exploade coffin.
 * 
 * @param entity            The entity index.                    
 **/
void CoffinExpload(int entity)
{
	// Initialize vectors
	static float vPosition[3]; static float vPosition2[3]; static float vGib[3]; float vShoot[3];

	// Gets entity position
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

	// Gets skill radius
	float flRadius = hCvarSkillRadius.FloatValue;
	float flKnock = hCvarSkillKnockback.FloatValue;

	// Find any players in the radius
	int i; int it = 1; /// iterator
	while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
	{
		// Gets victim origin
		GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2);

		// Create a knockback
		UTIL_CreatePhysForce(i, vPosition, vPosition2, GetVectorDistance(vPosition, vPosition2), flKnock, flRadius);
		
		// Create a shake
		UTIL_CreateShakeScreen(i, 2.0, 1.0, 3.0);
	}
	
	// Gets particle name
	static char sEffect[SMALL_LINE_LENGTH];
	hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
	
	// Validate effect
	if (hasLength(sEffect))
	{
		// Create an explosion effect
		UTIL_CreateParticle(entity, vPosition, _, _, sEffect, 2.0);
	}
	else
	{
		// Create a simple effect
		TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {155, 118, 83, 255}, 0, 0);
		TE_SendToAll();
	}
	
	// Play sound
	ZP_EmitSoundToAll(gSound, 4, entity, SNDCHAN_STATIC, SNDLEVEL_EXPLOSION);
	
	// Create a breaked metal effect
	static char sBuffer[NORMAL_LINE_LENGTH];
	for (int x = 0; x <= 4; x++)
	{
		// Find gib positions
		vShoot[1] += 72.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
		{
			case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib1.mdl");
			case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib2.mdl");
			case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib3.mdl");
			case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib4.mdl");
			case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib5.mdl");
		}
	
		// Create gibs
		UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, sBuffer, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
	}

	// Kill after some duration
	UTIL_RemoveEntity(entity, 0.1);
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
