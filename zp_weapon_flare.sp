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
	name            = "[ZP] Weapon: Flare",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_COLOR {255, 255, 255, 255}
/**
 * @endsection
 **/

// Decal index
int gTrail;

// Sound index
int gSound;

// Item index
int gWeapon;

// Cvars
ConVar hCvarFlareRadius;
ConVar hCvarFlareDistance;
ConVar hCvarFlareDuration;
ConVar hCvarFlareTrail;
ConVar hCvarFlareColor;
ConVar hCvarFlareSmoke;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarFlareRadius   = CreateConVar("zp_weapon_flare_radius", "500.0", "Flare lightning size (radius)", 0, true, 0.0);
	hCvarFlareDistance = CreateConVar("zp_weapon_flare_distance", "1000.0", "Flare lightning size (distance)", 0, true, 0.0);
	hCvarFlareDuration = CreateConVar("zp_weapon_flare_duration", "20.0", "Flare lightning duration in seconds", 0, true, 0.0);
	hCvarFlareTrail    = CreateConVar("zp_weapon_flare_trail", "0", "Attach trail to the projectile?", 0, true, 0.0, true, 1.0);
	hCvarFlareColor    = CreateConVar("zp_weapon_flare_color", "255 0 0 255", "Flare color in 'RGBA'");
	hCvarFlareSmoke    = CreateConVar("zp_weapon_flare_smoke", "smoking", "Particle effect for the smoke (''-off)");
	
	AutoExecConfig(true, "zp_weapon_flare", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("flare grenade");

	gSound = ZP_GetSoundKeyID("flare_grenade_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"flare_grenade_sounds\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

/**
 * @brief Called after a custom grenade is created.
 *
 * @param client            The client index.
 * @param grenade           The grenade index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnGrenadeCreated(int client, int grenade, int weaponID)
{
	if (weaponID == gWeapon)
	{
		SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);

		static float vPosition[3];
		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

		ZP_EmitSoundToAll(gSound, 1, grenade, SNDCHAN_STATIC);

		float flDuration = hCvarFlareDuration.FloatValue;
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarFlareColor.GetString(sEffect, sizeof(sEffect));
		
		UTIL_CreateLight(grenade, vPosition, _, _, _, _, _, _, _, sEffect, hCvarFlareDistance.FloatValue, hCvarFlareRadius.FloatValue, flDuration);
		
		hCvarFlareSmoke.GetString(sEffect, sizeof(sEffect));

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(grenade, vPosition, _, _, sEffect, flDuration);
		}
		
		if (hCvarFlareTrail.BoolValue)
		{
			TE_SetupBeamFollow(grenade, gTrail, 0, 1.0, 10.0, 10.0, 5, WEAPON_BEAM_COLOR);
			TE_SendToAll();	
		}

		UTIL_RemoveEntity(grenade, flDuration);
	}
}
