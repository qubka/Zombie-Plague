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
	name            = "[ZP] Zombie Class: Hunter",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gTrail;

// Sound index
int gSound;

// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillSpeed;
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSkillSpeed  = CreateConVar("zp_zclass_hunter_speed", "1.42", "Speed multiplier", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_hunter_effect", "sila_trail_apalaal", "Particle effect for the skill (''-default)");
	
	AutoExecConfig(true, "zp_zclass_hunter", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("hunter");
	
	gSound = ZP_GetSoundKeyID("FAST_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"FAST_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param client             The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	if (ZP_GetClientClass(client) == gZombie)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", hCvarSkillSpeed.FloatValue);
		
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_SKILL);
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		if (hasLength(sEffect))
		{
			static float vPosition[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
			UTIL_CreateParticle(client, vPosition, _, _, sEffect, ZP_GetClassSkillDuration(gZombie));
		}
		else
		{
			TE_SetupBeamFollow(client, gTrail, 0, ZP_GetClassSkillDuration(gZombie), 6.0, 6.0, 3, {255, 0, 0, 200});
			TE_SendToAll();	
		}
	}
	
	return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param client            The client index.
 **/
public void ZP_OnClientSkillOver(int client)
{
	if (ZP_GetClientClass(client) == gZombie) 
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}
