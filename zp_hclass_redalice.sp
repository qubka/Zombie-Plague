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
	name            = "[ZP] Human Class: Red Alice",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of human classes",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gBeam; int gHalo;
#pragma unused gBeam, gHalo

// Sound index
int gSound;
#pragma unused gSound
 
// Initialize human class index
int gHuman;
#pragma unused gHuman

// Cvars
ConVar gCvarSkillSpeed;
ConVar gCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	gCvarSkillSpeed  = CreateConVar("zp_hclass_redalice_speed", "1.2", "Speed multiplier", 0, true, 0.0);
	gCvarSkillEffect = CreateConVar("zp_hclass_redalice_effect", "vixr_final", "Particle effect for the skill (''-default)");

	// Generate config
	AutoExecConfig(true, "zp_hclass_redalice", "sourcemod/zombieplague");
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
	gHuman = ZP_GetClassNameID("redalice");
	//if (gHuman == -1) SetFailState("[ZP] Custom human class ID from name : \"redalice\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("REDALICE_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"REDALICE_SKILL_SOUNDS\" wasn't find");
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
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	// Validate the human class index
	if (ZP_GetClientClass(client) == gHuman)
	{
		// Sets a new speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", gCvarSkillSpeed.FloatValue);
		
		// Play sound
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
		
		// Gets client origin
		static float vPosition[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		// Gets particle name
		static char sEffect[SMALL_LINE_LENGTH];
		gCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
		
		// Validate effect
		if (hasLength(sEffect))
		{
			// Create an effect
			UTIL_CreateParticle(client, vPosition, _, _, sEffect, ZP_GetClassSkillDuration(gHuman));
		}
		else
		{
			// Create a simple effect
			TE_SetupBeamRingPoint(vPosition, 10.0, 100.0, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, {255, 0, 255, 255}, 0, 0);
			TE_SendToAll();
		}
	}
	
	// Allow usage
	return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param client            The client index.
 **/
public void ZP_OnClientSkillOver(int client)
{
	// Validate the human class index
	if (ZP_GetClientClass(client) == gHuman) 
	{
		// Sets previous speed
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
	}
}
