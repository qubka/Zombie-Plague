/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: Ethereal",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of survivor weapon",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_REFERANCE                "Etherial" // Models and other properties in the 'weapons.ini'
#define WEAPON_BEAM_LIFE                0.105
#define WEAPON_BEAM_COLOR               {0, 194, 194, 255}
/**
 * @endsection
 **/

// Initialize variables
int gWeapon;

// Variables for precache resources
int decalBeam;

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook temp entity
        HookEvent("bullet_impact", WeaponImpactBullets, EventHookMode_Post);
    }
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_REFERANCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_REFERANCE);

    // Models
    decalBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}

/**
 * Event callback (bullet_impact)
 * The bullet hits something.
 * 
 * @param hEvent            The event handle.
 * @param sName             Name of the event.
 * @param iDontBroadcast    If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponImpactBullets(Event hEvent, const char[] sName, bool iDontBroadcast) 
{
    // Initialize weapon index
    int weaponIndex;

    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Validate weapon
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        // Initialize vector variables
        static float vEntPosition[3]; static float vBulletPosition[3];

        // Gets hit position
        vBulletPosition[0] = hEvent.GetFloat("x");
        vBulletPosition[1] = hEvent.GetFloat("y");
        vBulletPosition[2] = hEvent.GetFloat("z");

        // Gets the weapon's position
        ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, -5.0, vEntPosition);
        
        // Sent a beam
        TE_SetupBeamPoints(vEntPosition, vBulletPosition, decalBeam, 0, 0, 0, WEAPON_BEAM_LIFE, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
        TE_SendToAll();
        
        // Create a muzzleflesh / True for getting the custom viewmodel index
        FakeDispatchEffect(ZP_GetClientViewModel(clientIndex, true), "weapon_muzzle_flash_taser", "ParticleEffect", _, _, _, 1);
        TE_SendToClient(clientIndex);
    }
}