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
    name            = "[ZP] Weapon: M134",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/ 
#define WEAPON_TIME_DELAY_START     1.2
#define WEAPON_TIME_DELAY_END       1.2
/**
 * @endsection
 **/

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_ATTACK_START,
    ANIM_ATTACK_END
};

// Weapon states
enum
{
    STATE_BEGIN,
    STATE_ATTACK
};

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("m134");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"m134\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
    
    // Sets attack state
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_BEGIN);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnReload(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponReload(gWeapon));
}

void Weapon_OnReloadStart(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode > STATE_BEGIN)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate ammo
    if(!iAmmo)
    {
        return;
    }
    
    // Validate clip
    if(iClip < ZP_GetWeaponClip(gWeapon))
    {
        // Sets reload animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_RELOAD); 

        /// Reset for allowing reload
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    }
}

void Weapon_OnPrimaryAttack(const int clientIndex, const int weaponIndex, int iClip, const int iAmmo, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate ammo
    if(iClip <= 0)
    {
        // Validate mode
        if(iStateMode > STATE_BEGIN)
        {
            Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime);
        }
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Switch mode
    switch(iStateMode)
    {
        case STATE_BEGIN :
        {
            // Sets begin animation
            ZP_SetWeaponAnimation(clientIndex, ANIM_ATTACK_START);        

            // Sets attack state
            SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_ATTACK);

            // Adds the delay to the game tick
            flCurrentTime += WEAPON_TIME_DELAY_START;
            
            // Sets next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime - 0.1);
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);   
        }
    }
}

void Weapon_OnEndAttack(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate mode
    if(iStateMode > STATE_BEGIN)
    {
        /// Block the real attack
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

        // Sets end animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_ATTACK_END);        

        // Sets begin state
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_BEGIN);

        // Adds the delay to the game tick
        flCurrentTime += WEAPON_TIME_DELAY_END;
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);
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
        GetEntProp(%2, Prop_Send, "m_iClip2"), \
                                \
        GetGameTime() \
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
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_BEGIN);
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
 * @brief Called on reload of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponReload(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Reload(clientIndex, weaponIndex);
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
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            return Plugin_Changed;
        }
        // Button primary attack release
        else if(iLastButtons & IN_ATTACK)
        {
            // Call event
            _call.EndAttack(clientIndex, weaponIndex);
        }

        // Button reload press
        if(iButtons & IN_RELOAD)
        {
            // Validate overtransmitting
            if(!(iLastButtons & IN_RELOAD))
            {
                // Call event
                _call.ReloadStart(clientIndex, weaponIndex);
            }
        }
    }
    
    // Allow button
    return Plugin_Continue;
}