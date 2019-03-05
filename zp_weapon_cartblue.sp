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
    name            = "[ZP] Weapon: CartBlue",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_TIME_DELAY_SWITCH    4.83
#define WEAPON_ACTIVE_MULTIPLIER    2.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_DRAW,
    ANIM_RELOAD,
    ANIM_CHANGE,
    ANIM_IDLE2,
    ANIM_RELOAD2,
    ANIM_DRAW2,
    ANIM_SHOOT2_1,
    ANIM_SHOOT2_2,
    ANIM_CHANGE2
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
    gWeapon = ZP_GetWeaponNameID("cartblue");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"cartblue\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("CARTBLUE2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"CARTBLUE2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int clientIndex, int weaponIndex, int iClip, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime

    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iClip, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, !iStateMode ?  ANIM_DRAW : ANIM_DRAW2); 
}

void Weapon_OnShoot(int clientIndex, int weaponIndex, int iClip, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode)
    {
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1); 
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
}

void Weapon_OnFire(int clientIndex, int weaponIndex, int iClip, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime
    
    // Validate ammo
    if(iClip <= 0)
    {
        return;
    }
    
    // Validate mode
    if(!iStateMode)
    {
        return;
    }
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon) * WEAPON_ACTIVE_MULTIPLIER;

    // Sets next attack time
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iClip, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer") > flCurrentTime)
    {
        return;
    }

    // Sets change animation
    ZP_SetWeaponAnimation(clientIndex, iStateMode ? ANIM_CHANGE2 : ANIM_CHANGE);        

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_SWITCH;

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets switching time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
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
        GetEntProp(%2, Prop_Data, "m_iIKCounter"), \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_NORMAL);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
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
 * @brief Called on holster of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponHolster(int clientIndex, int weaponIndex, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Holster(clientIndex, weaponIndex);
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
        // Time to apply new mode
        static float flApplyModeTime;
        if((flApplyModeTime = GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
        {
            // Resets the switching time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets different mode
            SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", !GetEntProp(weaponIndex, Prop_Data, "m_iIKCounter"));
        }
        else
        {
            // Validate state
            if(GetEntProp(weaponIndex, Prop_Data, "m_iIKCounter"))
            {
                // Switch animation
                switch(ZP_GetWeaponAnimation(clientIndex))
                {
                    case ANIM_IDLE :    ZP_SetWeaponAnimation(clientIndex, ANIM_IDLE2);
                    case ANIM_SHOOT1 :  ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2 });
                    case ANIM_RELOAD :  ZP_SetWeaponAnimation(clientIndex, ANIM_RELOAD2); 
                }
            }
        }

        // Button secondary attack press
        if(!(iButtons & IN_ATTACK) && iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflicter index.
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflicterIndex, float &flDamage, int &iBits, int &weaponIndex)
{
    // Client was damaged by 'bullet'
    if(iBits & DMG_NEVERGIB)
    {
        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Validate custom weapon
            if(ZP_GetWeaponID(weaponIndex) == gWeapon)
            {
                // Add additional damage
                if(GetEntProp(weaponIndex, Prop_Data, "m_iIKCounter")) flDamage *= WEAPON_ACTIVE_MULTIPLIER;
            }
        }
    }
}