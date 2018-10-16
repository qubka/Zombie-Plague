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
#define WEAPON_ITEM_REFERENCE           "etherial" // Name in weapons.ini from translation file
#define WEAPON_BEAM_COLOR               {0, 194, 194, 255}
#define WEAPON_BEAM_MODEL               "materials/sprites/laserbeam.vmt"
/**
 * @endsection
 **/

// Weapon index
int gWeapon;

// Decal index
int decalBeam;

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_ITEM_REFERENCE);

    // Models
    decalBeam = PrecacheModel(WEAPON_BEAM_MODEL, true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnBullet(const int clientIndex, const int weaponIndex, float vBulletPosition[3])
{
    #pragma unused clientIndex, weaponIndex, vBulletPosition

    // Initialize vectors
    static float vEntPosition[3]; static float vEntAngle[3];

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, -5.0, vEntPosition);
    
    // Gets the beam lifetime
    float flLife = ZP_GetWeaponSpeed(gWeapon);
    
    // Sent a beam
    TE_SetupBeamPoints(vEntPosition, vBulletPosition, decalBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
    TE_SendToClient(clientIndex);
    
    // Gets the worldmodel index
    int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
    
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Gets attachment position
        ZP_GetAttachment(entityIndex, "muzzle_flash", vEntPosition, vEntAngle);
        
        // Sent a beam
        TE_SetupBeamPoints(vEntPosition, vBulletPosition, decalBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
        int[] iClients = new int[MaxClients]; int iCount;
        for (int i = 1; i <= MaxClients; i++)
        {
            if(!IsPlayerExist(i, false) || i == clientIndex || IsFakeClient(i)) continue;
            iClients[iCount++] = i;
        }
        TE_Send(iClients, iCount);
    }
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2,%3)      \
                                \
    Weapon_On%0                 \
    (                           \
        %1,                     \
        %2,                     \
        %3                      \
    )    



/**
 * Called on bullet of a weapon.
 *
 * @param clientIndex       The client index.
 * @param vBulletPosition   The position of a bullet hit.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponBullet(int clientIndex, float vBulletPosition[3], int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Bullet(clientIndex, weaponIndex, vBulletPosition);
    }
}