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
#pragma unused gBeam, gHalo

// Sound index
int gSound;
#pragma unused gSound
 
// Zombie index
int gZombie;
#pragma unused gZombie

// Cvars
ConVar gCvarSkillReward;
ConVar gCvarSkillRadius;
ConVar gCvarSkillEffect;
ConVar gCvarSkillHeal;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	gCvarSkillReward = CreateConVar("zp_zclass_healer_reward", "1", "Reward for healing each zombie", 0, true, 0.0);
	gCvarSkillRadius = CreateConVar("zp_zclass_healer_radius", "250.0", "Healing radius", 0, true, 0.0);
	gCvarSkillEffect = CreateConVar("zp_zclass_sleeper_effect", "tornado", "Particle effect for the skill (''-default)");
	gCvarSkillHeal   = CreateConVar("zp_zclass_sleeper_heal", "heal_ss", "Particle effect for the heal (''-off)");
	
	// Generate config
	AutoExecConfig(true, "zp_zclass_healer", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("healer");
	//if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"healer\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("HEALER_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HEALER_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
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
		static float vPosition[3]; static float vEnemy[3];
		
		// Gets client origin
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);

		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);

		// Create an fade
		UTIL_CreateFadeScreen(client, 0.3, 1.0, FFADE_IN, {255, 127, 80, 75});  

		// Gets skill variables
		float flRadius = gCvarSkillRadius.FloatValue;
		int iTotal = 0; int iReward = gCvarSkillReward.IntValue;
		float flDuration = ZP_GetClassSkillDuration(gZombie);
				
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		gCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		// Validate effect
		if (hasLength(sEffect))
		{
			// Create an effect
			UTIL_CreateParticle(client, vPosition, _, _, sEffect, flDuration);
		}
		else
		{
			// Create a simple effect
			TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {0, 255, 0, 255}, 0, 0);
			TE_SendToAll();
		}
		
		// Gets particle name
		gCvarSkillHeal.GetString(sEffect, sizeof(sEffect));
		
		// Find any players in the radius
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			// Skip humans
			if (ZP_IsPlayerHuman(i))
			{
				continue;
			}

			// Gets victim zombie class/health
			int iClass = ZP_GetClientClass(i);
			int iHealth = ZP_GetClassHealth(iClass);
			int iSound = ZP_GetClassSoundRegenID(iClass);

			// Validate lower health
			if (GetEntProp(i, Prop_Send, "m_iHealth") < iHealth)
			{
				// Sets a new health 
				SetEntProp(i, Prop_Send, "m_iHealth", iHealth); 
				
				// Create a fade
				UTIL_CreateFadeScreen(i, 0.3, 1.0, FFADE_IN, {0, 255, 0, 75});
				
				// Validate sound key
				if (iSound != -1)
				{
					// Play sound
					ZP_EmitSoundToAll(iSound, _, i, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
				}
				
				// Gets victim origin
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
				
				// Append to total reward
				iTotal += iReward;
				
				// Validate effect
				if (hasLength(sEffect))
				{
					// Create an effect
					UTIL_CreateParticle(i, vEnemy, _, _, sEffect, flDuration);
				}
			}
		}
		
		// Give reward
		ZP_SetClientMoney(client, ZP_GetClientMoney(client) + iTotal);	
	}
	
	// Allow usage
	return Plugin_Continue;
}
