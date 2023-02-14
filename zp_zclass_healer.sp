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
	name            = "[ZP] Zombie Class: Healer",
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

// Cvars
ConVar hCvarSkillReward;
ConVar hCvarSkillRadius;
ConVar hCvarSkillEffect;
ConVar hCvarSkillHeal;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSkillReward = CreateConVar("zp_zclass_healer_reward", "1", "Reward for healing each zombie", 0, true, 0.0);
	hCvarSkillRadius = CreateConVar("zp_zclass_healer_radius", "250.0", "Healing radius", 0, true, 0.0);
	hCvarSkillEffect = CreateConVar("zp_zclass_sleeper_effect", "tornado", "Particle effect for the skill (''-default)");
	hCvarSkillHeal   = CreateConVar("zp_zclass_sleeper_heal", "heal_ss", "Particle effect for the heal (''-off)");
	
	AutoExecConfig(true, "zp_zclass_healer", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("healer");
	
	gSound = ZP_GetSoundKeyID("HEALER_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HEALER_SKILL_SOUNDS\" wasn't find");
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
		static float vPosition[3]; static float vPosition2[3];
		
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);

		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_NORMAL);

		UTIL_CreateFadeScreen(client, 0.3, 1.0, FFADE_IN, {255, 127, 80, 50});  

		float flRadius = hCvarSkillRadius.FloatValue;
		int iTotal = 0; int iReward = hCvarSkillReward.IntValue;
		float flDuration = ZP_GetClassSkillDuration(gZombie);
				
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(client, vPosition, _, _, sEffect, flDuration);
		}
		else
		{
			TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {0, 255, 0, 255}, 0, 0);
			TE_SendToAll();
		}
		
		hCvarSkillHeal.GetString(sEffect, sizeof(sEffect));
		
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			if (ZP_IsPlayerHuman(i))
			{
				continue;
			}

			int iClass = ZP_GetClientClass(i);
			int iHealth = ZP_GetClassHealth(iClass);
			int iSound = ZP_GetClassSoundRegenID(iClass);

			if (GetEntProp(i, Prop_Send, "m_iHealth") < iHealth)
			{
				SetEntProp(i, Prop_Send, "m_iHealth", iHealth); 
				
				UTIL_CreateFadeScreen(i, 0.3, 1.0, FFADE_IN, {0, 255, 0, 50});
				
				if (iSound != -1)
				{
					ZP_EmitSoundToAll(iSound, _, i, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
				}
				
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2);
				
				iTotal += iReward;
				
				if (hasLength(sEffect))
				{
					UTIL_CreateParticle(i, vPosition2, _, _, sEffect, flDuration);
				}
			}
		}
		
		ZP_SetClientMoney(client, ZP_GetClientMoney(client) + iTotal);	
	}
	
	return Plugin_Continue;
}
