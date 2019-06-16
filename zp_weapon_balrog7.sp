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
    name            = "[ZP] Weapon: Balrog VII",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
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
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // If map loaded, then run custom forward
        if(ZP_IsMapLoaded())
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
    gWeapon = ZP_GetWeaponNameID("balrog7");
    //if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"balrog7\" wasn't find");
    
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

void Weapon_OnReload(int client, int weapon, float vBullet[3], int iCounter, float flCurrentTime)
{
    #pragma unused client, weapon, vBullet, iCounter, flCurrentTime

    // Sets default FOV for the client
    SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
}

void Weapon_OnSecondaryAttack(int client, int weapon, float vBullet[3], int iCounter, float flCurrentTime)
{
    #pragma unused client, weapon, vBullet, iCounter, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
    {
        return;
    }
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 0.3);
    
    // Sets FOV for the client
    int iDefaultFOV = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
    SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iFOV") == iDefaultFOV ? 55 : iDefaultFOV);
}

void Weapon_OnBullet(int client, int weapon, float vBullet[3], int iCounter, float flCurrentTime)
{
    #pragma unused client, weapon, vBullet, iCounter, flCurrentTime
    
    // Validate counter
    if(iCounter > (ZP_GetWeaponClip(gWeapon) / WEAPON_EXPLOSION_RATIO))
    {
        // Create an explosion
        UTIL_CreateExplosion(vBullet, EXP_NOFIREBALL | EXP_NOSOUND, _, WEAPON_EXPLOSION_DAMAGE, WEAPON_EXPLOSION_RADIUS, "balrog7", client, weapon);

        // Create an explosion effect
        UTIL_CreateParticle(_, vBullet, _, _, "explosion_hegrenade_interior", WEAPON_EXPLOSION_TIME);

        // Play sound
        ZP_EmitAmbientSound(gSound, 1, vBullet, SOUND_FROM_WORLD, hSoundLevel.IntValue);
        
        // Sets shots count
        iCounter = -1;
    }
    
    // Sets shots count
    SetEntProp(weapon, Prop_Data, "m_iHealth", iCounter + 1);
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
        %3,                     \
                                \
        GetEntProp(%2, Prop_Data, "m_iHealth"), \
                                \
        GetGameTime()           \
    )    

/**
 * @brief Called after a custom weapon is created.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int client, int weapon, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Resets variables
        SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
    }
}

/**
 * @brief Called on reload of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponReload(int client, int weapon, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Reload(client, weapon, NULL_VECTOR);
    }
}
    
/**
 * @brief Called on bullet of a weapon.
 *
 * @param client            The client index.
 * @param vBullet           The position of a bullet hit.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponBullet(int client, float vBullet[3], int weapon, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Bullet(client, weapon, vBullet);
    }
}

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param client            The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Button secondary attack press
        if(!(iButtons & IN_ATTACK) && iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(client, weapon, NULL_VECTOR);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
    }
    
    // Allow button
    return Plugin_Continue;
}