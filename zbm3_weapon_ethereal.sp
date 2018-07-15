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
#define WEAPON_SPEED                    0.25
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
    // Initilizate weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_REFERANCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_REFERANCE);

    // Models
    decalBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex       The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
    // Hook entity callbacks
    SDKHook(clientIndex, SDKHook_WeaponSwitchPost, WeaponOnDeployPost);
}

/**
 * Hook: WeaponSwitchPost
 * Player deploy any weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
public void WeaponOnDeployPost(int clientIndex, int weaponIndex) 
{
    // Validate weapon
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        // Update weapon position on the next frame
        RequestFrame(view_as<RequestFrameCallback>(WeaponOnFakeDeployPost), GetClientUserId(clientIndex));
    }
}

/**
 * FakeHook: WeaponSwitchPost
 *
 * @param userID            The user id.
 **/
public void WeaponOnFakeDeployPost(int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Initialize vector variables
        static float flStart[3]; 
        
        // Update weapon position
        ZP_GetWeaponAttachmentPos(clientIndex, "muzzle_flash", flStart);
    }
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
        static float flStart[3]; static float flEnd[3];

        // Gets hit position
        flEnd[0] = hEvent.GetFloat("x");
        flEnd[1] = hEvent.GetFloat("y");
        flEnd[2] = hEvent.GetFloat("z");

        // Gets weapon position
        ZP_GetWeaponAttachmentPos(clientIndex, "muzzle_flash", flStart);
        
        // Sent a beam
        TE_SetupBeamPoints(flStart, flEnd, decalBeam, 0, 0, 0, WEAPON_BEAM_LIFE, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
        TE_SendToAll();
    }
}