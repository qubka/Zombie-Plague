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
	name            = "[ZP] Zombie Class: Classic",
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
ConVar hCvarSkillChance;
ConVar hCvarSkillDuration;
ConVar hCvarSkillAlpha;
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSkillChance   = CreateConVar("zp_zclass_classic_chance", "20", "Smaller = more likely", 0, true, 0.0, true, 999.0);
	hCvarSkillDuration = CreateConVar("zp_zclass_classic_duration", "2.5", "Sleep duration", 0, true, 0.0);
	hCvarSkillAlpha    = CreateConVar("zp_zclass_classic_alpha", "255", "Sleep blind alpha", 0, true, 0.0, true, 255.0);
	hCvarSkillEffect   = CreateConVar("zp_zclass_classic_effect", "sila_trail_apalaal", "Particle effect for the skill (''-default)");

	AutoExecConfig(true, "zp_zclass_classic", "sourcemod/zombieplague");
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
	gZombie = ZP_GetClassNameID("classic");
	
	gSound = ZP_GetSoundKeyID("sleeper_skill_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"sleeper_skill_sounds\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

/**
 * @brief Called after a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 * @param iHealth           The current health amount of a victim.
 * @param iArmor            The current armor amount of a victim.
 **/
public void ZP_OnClientDamaged(int client, int attacker, int inflictor, float flDamage, int iBits, int weapon, int iHealth, int iArmor)
{
	if (weapon == -1 || !IsClientValid(attacker))
	{
		return;
	}
	
	static int iChance[MAXPLAYERS+1];

	if (ZP_GetClientClass(client) == gZombie)
	{
		iChance[client] = GetRandomInt(0, 999);
		
		if (iChance[client] < hCvarSkillChance.IntValue)
		{
			ZP_EmitSoundToAll(gSound, 1, attacker, SNDCHAN_VOICE);
			
			float flDuration = hCvarSkillDuration.FloatValue;

			static int iColor[4];
			iColor[3] = hCvarSkillAlpha.IntValue;
			UTIL_CreateFadeScreen(attacker, flDuration, flDuration + 0.5, FFADE_IN, iColor);
			
			static char sEffect[SMALL_LINE_LENGTH];
			hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
			
			if (hasLength(sEffect))
			{
				static float vPosition[3];
				GetEntPropVector(attacker, Prop_Data, "m_vecAbsOrigin", vPosition);
				UTIL_CreateParticle(attacker, vPosition, _, _, sEffect, flDuration);
			}
			else
			{
				TE_SetupBeamFollow(attacker, gTrail, 0, flDuration, 6.0, 6.0, 3, {80, 200, 120, 200});
				TE_SendToAll();	
			}
		}
	}
}
