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
	hCvarSkillLast   = CreateConVar("zp_zclass_range_last", "0", "Can a last human be infected?", 0, true, 0.0, true, 1.0);
	hCvarSkillSingle = CreateConVar("zp_zclass_range_single", "1", "Only 1 human can be infected?", 0, true, 0.0, true, 1.0);
	hCvarSkillRadius = CreateConVar("zp_zclass_range_radius", "200.0", "Infection radius", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_range_effect", "explosion_hegrenade_dirt", "Particle effect for the skill (''-default)");
	
	AutoExecConfig(true, "zp_zclass_range", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("range");
	
	gSound = ZP_GetSoundKeyID("RANGE_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"RANGE_SKILL_SOUNDS\" wasn't find");
	
	gType = ZP_GetClassTypeID("zombie");
	if (gType == -1) SetFailState("[ZP] Custom class type ID from name : \"zombie\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
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
	if (ZP_GetClientClass(client) == gZombie)
	{
		static float vPosition[3]; 
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		float flRadius = hCvarSkillRadius.FloatValue;
		bool bLast = hCvarSkillLast.BoolValue;
		bool bSingle = hCvarSkillSingle.BoolValue;
			
		if (ZP_IsGameModeInfect(ZP_GetCurrentGameMode()) && ZP_IsStartedRound())
		{
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
			{
				if (ZP_IsPlayerZombie(i))
				{
					continue;
				}

				if (!UTIL_CanSeeEachOther(client, i, vPosition, SelfFilter))
				{
					continue;
				}
				
				if (!bLast && ZP_GetHumanAmount() <= 1)
				{
					break;
				}
		  
				ZP_ChangeClient(i, client, gType);
				
				if (bSingle)
				{
					break;
				}
			}
		}
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
		}
		else
		{
			TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {75, 255, 75, 255}, 0, 0);
			TE_SendToAll();
		}
		
		ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD); 
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
