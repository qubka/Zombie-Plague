/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: Balrog VII",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_EXPLOSION_RATIO           6
#define WEAPON_EXPLOSION_DAMAGE          300.0
#define WEAPON_EXPLOSION_RADIUS          150.0
#define WEAPON_EXPLOSION_TIME            2.0
/**
 * @endsection
 **/

// Weapon index
int gWeapon;

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("balrog7");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"balrog7\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BALROGVII2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALROGVII2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnBullet(int clientIndex, int weaponIndex, int iCounter, float vBulletPosition[3])
{
    #pragma unused clientIndex, weaponIndex, iCounter, vBulletPosition
    
    // Validate counter
    if(iCounter > (ZP_GetWeaponClip(gWeapon) / WEAPON_EXPLOSION_RATIO))
    {
        // Create an explosion
        UTIL_CreateExplosion(vBulletPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, WEAPON_EXPLOSION_DAMAGE, WEAPON_EXPLOSION_RADIUS, "prop_exploding_barrel", clientIndex, weaponIndex);

        // Create an explosion effect
        UTIL_CreateParticle(_, vBulletPosition, _, _, "explosion_hegrenade_interior", WEAPON_EXPLOSION_TIME);

        // Play sound
        ZP_EmitAmbientSound(gSound, 1, vBulletPosition, SOUND_FROM_WORLD, hSoundLevel.IntValue);
        
        // Resets the shots count
        iCounter = -1;
    }
    
    // Sets shots count
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, iCounter + 1);
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
                                \
        GetEntProp(%2, Prop_Data, "m_iHealth"/**/), \
                                \
        %3                      \
    )    

/**
 * @brief Called after a custom weapon is created.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Reset variables
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, 0);
    }
}    
    
/**
 * @brief Called on bullet of a weapon.
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