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
    name            = "[ZP] Weapon: CartBlue",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "3.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_ITEM_REFERENCE       "cartblue" // Name in weapons.ini from translation file
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
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_ITEM_REFERENCE);
    
    // Sounds
    gSound = ZP_GetSoundKeyID("CARTBLUE2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"CARTBLUE2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(const int clientIndex, const int weaponIndex, const int iClip, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime

    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iClip, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime
    
    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, !iStateMode ?  ANIM_DRAW : ANIM_DRAW2); 
}

void Weapon_OnShoot(const int clientIndex, const int weaponIndex, const int iClip, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode)
    {
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1); 
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
}

void Weapon_OnFire(const int clientIndex, const int weaponIndex, const int iClip, const int iStateMode, float flCurrentTime)
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

    // Sets the next attack time
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
}

void Weapon_OnSecondaryAttack(const int clientIndex, const int weaponIndex, const int iClip, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iStateMode, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer") > flCurrentTime)
    {
        return;
    }

    // Sets the change animation
    ZP_SetWeaponAnimation(clientIndex, iStateMode ? ANIM_CHANGE2 : ANIM_CHANGE);        

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_SWITCH;

    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets the switching time
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
 * Called after a custom weapon is created.
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
 * Called on deploy of a weapon.
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
 * Called on holster of a weapon.
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
 * Called on fire of a weapon.
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
 * Called on shoot of a weapon.
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
 * Called on each frame of a weapon holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Change) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Time to apply new mode
        static float flApplyModeTime;
        if((flApplyModeTime = GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer")) != 0.0 && flApplyModeTime <= GetGameTime())
        {
            // Resets the switching time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets the different mode
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
 * Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, int inflictorIndex, float &damageAmount, int damageType, int weaponIndex)
{
    // Client was damaged by 'bullet'
    if(damageType & DMG_NEVERGIB)
    {
        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Validate custom weapon
            if(ZP_GetWeaponID(weaponIndex) == gWeapon)
            {
                // Add additional damage
                if(GetEntProp(weaponIndex, Prop_Data, "m_iIKCounter")) damageAmount *= WEAPON_ACTIVE_MULTIPLIER;
            }
        }
    }
}