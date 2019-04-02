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
    name            = "[ZP] Weapon: Balrog III",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_ACTIVE_COUNTER       15
#define WEAPON_TIME_DELAY_ACTIVE    0.083
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_SHOOT,
    ANIM_SHOOT_MODE1,
    ANIM_SHOOT_MODE2
};

// Weapon states
enum
{
    STATE_NORMAL,
    STATE_ACTIVE
};

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("balrog3");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"balrog3\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BALROGIII2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALROGIII2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
}

void Weapon_OnEndAttack(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

    // Reset variables
    SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, 0);
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, STATE_NORMAL);
}

void Weapon_OnFire(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
    
    // Validate clip
    if(iClip <= 0)
    {
        return;
    }
    
    // Validate ammo
    if(iAmmo <= 0)
    {
        return;
    }
    
    // Validate mode
    if(!iStateMode)
    {
        return;
    }
    
    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_ACTIVE;

    // Sets next attack time
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    
    // Substract ammo
    iClip += 1; SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip); 
    iAmmo -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo); 
}

void Weapon_OnShoot(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
    
    // Validate ammo
    if(!iAmmo)
    {
        // Sets normal mode
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, STATE_NORMAL);
    }
    else
    {
        // Validate counter
        if(iCounter > WEAPON_ACTIVE_COUNTER)
        {
            // Sets active mode
            SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, STATE_ACTIVE);

            // Resets the shots count
            iCounter = -1;
        }
        
        // Sets shots count
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, iCounter + 1);
        
        // Validate mode
        if(iStateMode)
        {
            // Play sound
            ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
        }
    }
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2)         \
                                \
    Weapon_On%0                 \
    (                           \
        %1,                     \
        %2,                     \
                                \
        GetEntProp(%2, Prop_Send, "m_iClip1"), \
                                \
        GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
                                \
        GetEntProp(%2, Prop_Data, "m_iMaxHealth"/**/), \
                                \
        GetEntProp(%2, Prop_Data, "m_iHealth"/**/), \
                                \
        GetGameTime()           \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, 0);
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, STATE_NORMAL);
    }
}  
    
/**
 * @brief Called on shoot of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponShoot(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Shoot(clientIndex, weaponIndex);
    }
}

/**
 * @brief Called on deploy of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDeploy(int clientIndex, int weaponIndex, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Deploy(clientIndex, weaponIndex);
    }
}

/**
 * @brief Called on fire of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponFire(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Fire(clientIndex, weaponIndex);
    }
}

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Validate state
        if(GetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/))
        {
            // Switch animation
            switch(ZP_GetWeaponAnimation(clientIndex))
            {
                case ANIM_SHOOT : ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT_MODE1, ANIM_SHOOT_MODE2});
            }
        }

        // Button primary attack release
        if(!(iButtons & IN_ATTACK)) 
        {
            // Call event
            _call.EndAttack(clientIndex, weaponIndex);
        }
    }
    
    // Allow button
    return Plugin_Continue;
}