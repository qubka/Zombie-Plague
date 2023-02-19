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
	hCvarSkillDelay  = CreateConVar("zp_zclass_smoker_delay", "0.5", "Delay between damage trigger", 0, true, 0.0);
	hCvarSkillDamage = CreateConVar("zp_zclass_smoker_damage", "5.0", "Damage amount", 0, true, 0.0);
	hCvarSkillRadius = CreateConVar("zp_zclass_smoker_radius", "200.0", "Cloud radius", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_smoker_effect", "explosion_smokegrenade_base_green", "Particle effect for the skill");
	
	AutoExecConfig(true, "zp_zclass_smoker", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("smoker");
	
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
	if (ZP_GetClientClass(client) == gZombie)
	{
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE);

		static float vPosition[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
				
		static char sEffect[NORMAL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));

		int entity = UTIL_CreateParticle(_, vPosition, _, _, sEffect, ZP_GetClassSkillDuration(gZombie));
		
		if (entity != -1)
		{
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
	
			CreateTimer(hCvarSkillDelay.FloatValue, ClientOnToxicGas, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
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
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
 
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		
		float flRadius = hCvarSkillRadius.FloatValue;
		float flDamage = hCvarSkillDamage.FloatValue;
		
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			if (ZP_IsPlayerZombie(i))
			{
				continue;
			}
			
			UTIL_CreateFadeScreen(i, 0.1, 0.2, FFADE_IN, {38, 87, 16, 75});  

			ZP_TakeDamage(i, owner, owner, flDamage, DMG_NERVEGAS);
		}
		
		return Plugin_Continue;
	}

	return Plugin_Stop;
}
