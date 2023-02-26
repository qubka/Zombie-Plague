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
	hCvarSkillSpeed  = CreateConVar("zp_zclass_deimos_speed", "3000.0", "Speed of sting", 0, true, 0.0);
	hCvarSkillRadius = CreateConVar("zp_zclass_deimos_radius", "150.0", "Dropping radius", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_deimos_effect", "gamma_trail_xz", "Particle effect for the skill (''-default)");
	hCvarSkillExp    = CreateConVar("zp_zclass_deimos_explosion", "pyrovision_explosion", "Particle effect for the skill explosion (''-default)");
	
	AutoExecConfig(true, "zp_zclass_deimos", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("deimos");
	
	gSound = ZP_GetSoundKeyID("deimos_skill_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"deimos_skill_sounds\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
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
	if (ZP_GetClientClass(client) == gZombie)
	{
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];
		
		GetClientEyePosition(client, vPosition);
		
		GetClientEyeAngles(client, vAngle);

		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
		
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE);
		
		int entity = UTIL_CreateProjectile(vPosition, vAngle);
		
		if (entity != -1)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.0);
			
			GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);
			
			NormalizeVector(vEndVelocity, vEndVelocity);
			
			ScaleVector(vEndVelocity, hCvarSkillSpeed.FloatValue);

			AddVectors(vEndVelocity, vVelocity, vEndVelocity);

			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

			SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

			SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01); 

			static char sEffect[SMALL_LINE_LENGTH];
			hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
			
			if (hasLength(sEffect))
			{
				UTIL_CreateParticle(entity, vPosition, _, _, sEffect, 10.0);
			}
			else
			{
				TE_SetupBeamFollow(entity, gTrail, 0, 5.0, 3.0, 3.0, 1, {209, 120, 9, 200});
				TE_SendToAll();	
			}
			
			UTIL_IgniteEntity(entity, 10.0);
			
			SDKHook(entity, SDKHook_Touch, BombTouchHook);
		}
		
		ZP_SetPlayerAnimation(client, PLAYERANIMEVENT_THROW_GRENADE);
	}
	
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
	if (IsValidEdict(target))
	{
		if (GetEntPropEnt(entity, Prop_Data, "m_hThrower") == target)
		{
			return Plugin_Continue;
		}

		static float vPosition[3]; static float vPosition2[3];
		
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		float flRadius = hCvarSkillRadius.FloatValue;
		float flRadius2 = flRadius * flRadius;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientValid(i) || ZP_IsPlayerZombie(i))
			{
				continue;
			}

			GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2);

			if (GetVectorDistance(vPosition, vPosition2, true) > flRadius2)
			{
				continue;
			}

			FakeClientCommandEx(i, "drop");

			UTIL_CreateFadeScreen(i, 0.3, 1.0, FFADE_IN, {209, 120, 9, 75});
			
			UTIL_CreateShakeScreen(i, 2.0, 1.0, 3.0);
		}
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillExp.GetString(sEffect, sizeof(sEffect));
		
		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
		}
		else
		{
			TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {209, 120, 9, 255}, 0, 0);
			TE_SendToAll();
		}
			
		ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC);

		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Continue;
}
