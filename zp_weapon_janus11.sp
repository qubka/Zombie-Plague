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
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: Janus XI",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_TIME_DELAY_SWITCH    2.2
#define WEAPON_SIGNAL_COUNTER       10
#define WEAPON_ACTIVE_COUNTER       10
#define WEAPON_TIME_DELAY_ACTIVE    0.075
#define WEAPON_ACTIVE_MULTIPLIER    2.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_START_RELOAD,
    ANIM_INSERT,
    ANIM_AFTER_RELOAD,
    ANIM_DRAW,
    ANIM_IDLE_SIGNAL,
    ANIM_SHOOT_SIGNAL,
    ANIM_START_RELOAD_SIGNAL,
    ANIM_INSERT_SIGNAL,
    ANIM_AFTER_RELOAD_SIGNAL,
    ANIM_DRAW_SIGNAL,
    ANIM_IDLE2,
    ANIM_SHOOT2,
    ANIM_DRAW2,
    ANIM_CHANGE,
    ANIM_CHANGE2
};

// Weapon states
enum
{
    STATE_NORMAL,
    STATE_SIGNAL,
    STATE_ACTIVE
}

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
    // Weapons
    gWeapon = ZP_GetWeaponNameID("janus11");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"janus11\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("JANUSXI2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSXI2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    if(hSoundLevel == INVALID_HANDLE) SetFailState("[ZP] Custom cvar key ID from name : \"zp_game_custom_sound_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

Action Weapon_OnReload(const int clientIndex, const int weaponIndex, const int iClip, const int iCounter, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    return iStateMode == STATE_ACTIVE ? Plugin_Handled : Plugin_Continue;
}

void Weapon_OnHolster(const int clientIndex, const int weaponIndex, const int iClip, const int iCounter, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime
    
    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iClip, const int iCounter, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime

    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

    // Sets the shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnShoot(const int clientIndex, const int weaponIndex, const int iClip, int iCounter, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime
    
    // Initialize variable
    static char sSound[PLATFORM_MAX_PATH];
    
    // Validate counter
    if(iCounter > WEAPON_SIGNAL_COUNTER)
    {
        // Sets the signal mode
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_SIGNAL);

        // Resets the shots count
        iCounter = -1;
        
        // Emit sound
        ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
    }
    
    // Switch mode
    if(iStateMode == STATE_ACTIVE)
    {
        // Emit sound
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1); 
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    
    // Sets the shots count
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", iCounter + 1);
}

void Weapon_OnFire(const int clientIndex, const int weaponIndex, int iClip, const int iCounter, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime

    // Validate mode
    if(iStateMode != STATE_ACTIVE)
    {
        return;
    }
    
    // Validate counter
    if(iCounter > WEAPON_ACTIVE_COUNTER)
    {
        Weapon_OnFinish(clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime);
        return;
    }
    
    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_ACTIVE;

    // Sets the next attack time
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    
    // Substract ammo
    iClip += 1; SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip);  
}

void Weapon_OnSecondaryAttack(const int clientIndex, const int weaponIndex, const int iClip, const int iCounter, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode == STATE_SIGNAL)
    {
        // Sets the change animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE);        

        // Sets the active state
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_ACTIVE);
        
        // Resets the shots count
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);
        
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
}

void Weapon_OnFinish(const int clientIndex, const int weaponIndex, const int iClip, const int iCounter, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iCounter, iStateMode, flCurrentTime
    
    // Sets the active state
    SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_NORMAL);
    
    // Resets the shots count
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_SWITCH;
    
    // Sets the next attack time
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    
    /// Sets the change animation on the next frame
    RequestFrame(view_as<RequestFrameCallback>(Weapon_OnFinishPost), GetClientUserId(clientIndex));
}

public void Weapon_OnFinishPost(const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Sets the change animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE2);    
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
        GetEntProp(%2, Prop_Send, "m_iClip2"), \
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
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_NORMAL);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
        
        // Hook weapon callbacks
        SDKHook(weaponIndex, SDKHook_Reload, OnWeaponReload);
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

            // Sets the active state
            SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_ACTIVE);
        }
        else
        {
            // Validate state
            static int iStateMode;
            if((iStateMode = GetEntProp(weaponIndex, Prop_Data, "m_iIKCounter")))
            {
                // Button reload press
                /*if(iButtons & IN_RELOAD)
                {
                    // Validate active mode
                    if(iStateMode == STATE_ACTIVE)
                    {
                        iButtons &= (~IN_RELOAD); //! Block reload
                        return Plugin_Changed;
                    }
                }*/
        
                // Switch animation
                switch(ZP_GetWeaponAnimation(clientIndex))
                {
                    case ANIM_IDLE : ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_IDLE2 : ANIM_IDLE_SIGNAL);
                    case ANIM_SHOOT1 : if(iStateMode == STATE_ACTIVE) ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT2); else ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT_SIGNAL); 
                    case ANIM_START_RELOAD : ZP_SetWeaponAnimation(clientIndex, ANIM_START_RELOAD_SIGNAL); 
                    case ANIM_INSERT : ZP_SetWeaponAnimation(clientIndex, ANIM_INSERT_SIGNAL); 
                    case ANIM_AFTER_RELOAD : ZP_SetWeaponAnimation(clientIndex, ANIM_AFTER_RELOAD_SIGNAL); 
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
 * Called on reload of a weapon. (~PRE~ hook)
 *
 * @param weaponIndex       The weapon index.
 **/
public Action /*ZP_*/OnWeaponReload(const int weaponIndex) 
{
    // Call event
    return _call.Reload(GetEntPropEnt(weaponIndex, Prop_Send, "m_hOwner"), weaponIndex);
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
public void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflictorIndex, float &damageAmount, int &damageType, int &weaponIndex)
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