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
	name            = "[ZP] Human Class: Blue Tank",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of human classes",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gBeam; int gHalo;

// Sound index
int gSound;
 
// Human index
int gHuman;

// Cvars
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSkillEffect = CreateConVar("zp_hclass_bluetank_effect", "vixr_final", "Particle effect for the skill (''-default)");

	AutoExecConfig(true, "zp_hclass_bluetank", "sourcemod/zombieplague");
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
	gHuman = ZP_GetClassNameID("bluetank");
	
	gSound = ZP_GetSoundKeyID("BLUETANK_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BLUETANK_SKILL_SOUNDS\" wasn't find");
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
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	if (ZP_GetClientClass(client) == gHuman)
	{
		int iHealth = ZP_GetClassHealth(gHuman);
		if (GetEntProp(client, Prop_Send, "m_iHealth") >= iHealth)
		{
			return Plugin_Handled;
		}

		SetEntProp(client, Prop_Send, "m_iHealth", iHealth);

		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
		
		float flDuration = ZP_GetClassSkillDuration(gHuman);
		
		UTIL_CreateFadeScreen(client, 0.3, flDuration, FFADE_IN, {50, 200, 50, 50});  
		
		static float vPosition[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(client, vPosition, _, _, sEffect, flDuration);
		}
		else
		{
			TE_SetupBeamRingPoint(vPosition, 10.0, 100.0, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {0, 128, 255, 255}, 0, 0);
			TE_SendToAll();
		}
	}
	
	return Plugin_Continue;
}
