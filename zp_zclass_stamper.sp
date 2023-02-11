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
	hCvarSkillAttach    = CreateConVar("zp_zclass_stamper_attach", "250.0", "Speed of attached victim", 0, true, 0.0);
	hCvarSkillHealth    = CreateConVar("zp_zclass_stamper_health", "200.0 ", "Health of coffin", 0, true, 0.0);
	hCvarSkillRadius    = CreateConVar("zp_zclass_stamper_radius", "250.0", "Radius of coffin attachment", 0, true, 0.0);
	hCvarSkillKnockback = CreateConVar("zp_zclass_stamper_knockback", "1000.0", "Knockback on coffin explosion", 0, true, 0.0);
	hCvarSkillEffect    = CreateConVar("zp_zclass_stamper_effect", "explosion_hegrenade_dirt", "Particle effect for the skill (''-default)");
	
	AutoExecConfig(true, "zp_zclass_stamper", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gZombie = ZP_GetClassNameID("stamper");
	
	gSound = ZP_GetSoundKeyID("COFFIN_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"COFFIN_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
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
	if (ZP_GetClientClass(client) == gZombie)
	{
		static float vPosition[3]; static float vAngle[3];

		ZP_GetPlayerEyePosition(client, 60.0, _, _, vPosition);
		GetClientEyeAngles(client, vAngle); vAngle[0] = vAngle[2] = 0.0; /// Only pitch
		
		static const float vMins[3] = { -3.077446, -9.829969, -37.660713 }; 
		static const float vMaxs[3] = { 11.564661, 20.737569, 38.451633  }; 
		
		vPosition[2] += vMaxs[2] / 2.0; /// Move center of hull upward
		TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
		
		if (!TR_DidHit())
		{
			int entity = UTIL_CreatePhysics("coffin", vPosition, vAngle, "models/player/custom_player/zombie/zombiepile/zombiepile.mdl", PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);

			if (entity != -1)
			{
				SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
				SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
				
				SetEntPropEnt(entity, Prop_Data, "m_pParent", client);

				int iHealth = hCvarSkillHealth.IntValue;
				if (iHealth > 0)
				{
					SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
					SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
					SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHealth);

					SDKHook(entity, SDKHook_OnTakeDamage, CoffinDamageHook);
				}
				
				ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, SNDLEVEL_SKILL);
				
				CreateTimer(ZP_GetClassSkillDuration(gZombie), CoffinExploadHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(1.0, CoffinIdleHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.1, CoffinThinkHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
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
	int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

	if (!iHealth)
	{
		SDKUnhook(entity, SDKHook_OnTakeDamage, CoffinDamageHook);

		CoffinExpload(entity);
	}
	else
	{
		ZP_EmitSoundToAll(gSound, GetRandomInt(2, 3), entity, SNDCHAN_STATIC, SNDLEVEL_HURT);
		
		SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
	}

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
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		ZP_EmitSoundToAll(gSound, GetRandomInt(5, 6), entity, SNDCHAN_VOICE, SNDLEVEL_SKILL);
	}
	else
	{
		return Plugin_Stop;
	}
	
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
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vPosition2[3];  

		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
	
		float flRadius = hCvarSkillRadius.FloatValue;
		float flAttach = hCvarSkillAttach.FloatValue;
	
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			if (ZP_IsPlayerZombie(i))
			{
				continue;
			}

			if (!UTIL_CanSeeEachOther(entity, i, vPosition, SelfFilter))
			{
				continue;
			}
			
			GetClientEyePosition(i, vPosition2);
			
			UTIL_GetVelocityByAim(vPosition2, vPosition, vAngle, vVelocity, flAttach);
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vVelocity);
		}
	}
	else
	{
		return Plugin_Stop;
	}
	
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
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		CoffinExpload(entity);
	}
	
	return Plugin_Stop;
}

/**
 * @brief Exploade coffin.
 * 
 * @param entity            The entity index.                    
 **/
void CoffinExpload(int entity)
{
	static float vPosition[3]; static float vPosition2[3]; static float vGib[3]; float vShoot[3];

	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

	float flRadius = hCvarSkillRadius.FloatValue;
	float flKnock = hCvarSkillKnockback.FloatValue;

	int i; int it = 1; /// iterator
	while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
	{
		GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2);

		UTIL_CreatePhysForce(i, vPosition, vPosition2, GetVectorDistance(vPosition, vPosition2), flKnock, flRadius);
		
		UTIL_CreateShakeScreen(i, 2.0, 1.0, 3.0);
	}
	
	static char sEffect[SMALL_LINE_LENGTH];
	hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
	
	if (hasLength(sEffect))
	{
		UTIL_CreateParticle(entity, vPosition, _, _, sEffect, 2.0);
	}
	else
	{
		TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {155, 118, 83, 255}, 0, 0);
		TE_SendToAll();
	}
	
	ZP_EmitSoundToAll(gSound, 4, entity, SNDCHAN_STATIC, SNDLEVEL_EXPLOSION);
	
	static char sBuffer[NORMAL_LINE_LENGTH];
	for (int x = 0; x <= 4; x++)
	{
		vShoot[1] += 72.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
		{
			case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib1.mdl");
			case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib2.mdl");
			case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib3.mdl");
			case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib4.mdl");
			case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib5.mdl");
		}
	
		UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, sBuffer, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
	}

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
