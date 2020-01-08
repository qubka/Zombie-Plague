/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_FLARE_RADIUS         150.0                 // Flare lightning size (radius)
#define GRENADE_FLARE_DISTANCE       600.0                 // Flare lightning size (distance)
#define GRENADE_FLARE_DURATION       20.0                  // Flare lightning duration in seconds
#define GRENADE_FLARE_COLOR          "255 0 0 255"         // Flare color in 'RGBA'
/**
 * @endsection
 **/
 
// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Item index
int gWeapon;
#pragma unused gWeapon

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
    // Weapons
    gWeapon = ZP_GetWeaponNameID("flare grenade");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"flare grenade\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("FLARE_GRENADE_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"FLARE_GRENADE_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
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
    // Validate custom grenade
    if (weaponID == gWeapon) /* OR if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)*/
    {
        // Block grenade
        SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);

        // Gets parent position
        static float vPosition[3];
        GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Play sound
        ZP_EmitSoundToAll(gSound, 1, grenade, SNDCHAN_STATIC, hSoundLevel.IntValue);

        // Create effects
        UTIL_CreateLight(grenade, vPosition, _, _, _, _, _, _, _, GRENADE_FLARE_COLOR, GRENADE_FLARE_DISTANCE, GRENADE_FLARE_RADIUS, GRENADE_FLARE_DURATION);
        UTIL_CreateParticle(grenade, vPosition, _, _, "smoking", GRENADE_FLARE_DURATION);

        // Kill after some duration
        UTIL_RemoveEntity(grenade, GRENADE_FLARE_DURATION);
    }
}