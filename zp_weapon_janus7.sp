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
    name            = "[ZP] Weapon: Janus VII",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_TIME_DELAY_SWITCH    2.2
#define WEAPON_SIGNAL_COUNTER       100
#define WEAPON_ACTIVE_COUNTER       150
#define WEAPON_BEAM_DAMAGE          50.0
#define WEAPON_BEAM_RADIUS          500.0
#define WEAPON_BEAM_SHAKE_AMP       10.0
#define WEAPON_BEAM_SHAKE_FREQUENCY 1.0
#define WEAPON_BEAM_SHAKE_DURATION  2.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_SHOOT_SIGNAL,
    ANIM_CHANGE,
    ANIM_IDLE2,
    ANIM_DRAW2,
    ANIM_SHOOT2_1,
    ANIM_SHOOT2_2,
    ANIM_CHANGE2,
    ANIM_IDLE_SIGNAL,
    ANIM_RELOAD_SIGNAL,
    ANIM_DRAW_SIGNAL
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
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("janus7");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"janus7\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("JANUSVII2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSVII2_SHOOT_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int clientIndex, int weaponIndex, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime

    // Validate mode
    if(iStateMode == STATE_ACTIVE)
    {
        /// Block the real attack
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
        
        // Create a muzzleflesh / True for getting the custom viewmodel index
        TE_DispatchEffect(ZP_GetClientViewModel(clientIndex, true), "medicgun_invulnstatus_fullcharge_red", "ParticleEffect", _, _, _, 1);
        TE_SendToClient(clientIndex);
    }
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnShoot(int clientIndex, int weaponIndex, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Validate counter
    if(iCounter > WEAPON_SIGNAL_COUNTER)
    {
        // Sets signal mode
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, STATE_SIGNAL);

        // Resets the shots count
        iCounter = -1;

        // Play sound
        ZP_EmitSoundToAll(gSound, 2, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    
    // Sets shots count
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, iCounter + 1);
}

bool Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode != STATE_ACTIVE)
    {
        return false;
    }

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
    // Validate counter
    if(iCounter > WEAPON_ACTIVE_COUNTER)
    {
        Weapon_OnFinish(clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime);
        return false;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return false;
    }
    
    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return false;
    }
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
    
    // Play sound
    ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2});
    
    // Create a beam
    Weapon_OnCreateBeam(clientIndex, weaponIndex);
    
    // Sets shots count
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, iCounter + 1);

    // Initialize variables
    /*static float vVelocity[3]; static int iFlags; iFlags = GetEntityFlags(clientIndex);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        ZP_CreateWeaponKickBack(clientIndex, 7.5, 4.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(clientIndex, 10.0, 7.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(clientIndex, 7.5, 4.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        ZP_CreateWeaponKickBack(clientIndex, 6.75, 6.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }*/
    
    // Return on the success
    return true;
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode == STATE_SIGNAL)
    {
        /// Block the real attack
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
        // Sets change animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE);        

        // Sets active state
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, STATE_ACTIVE);
        
        // Resets the shots count
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, 0);
        
        // Adds the delay to the game tick
        flCurrentTime += WEAPON_TIME_DELAY_SWITCH;
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime); 
        
        // Remove the delay to the game tick
        flCurrentTime -= 0.5;
        
        // Create a muzzleflesh / True for getting the custom viewmodel index
        TE_DispatchEffect(ZP_GetClientViewModel(clientIndex, true), "medicgun_invulnstatus_fullcharge_red", "ParticleEffect", _, _, _, 1);
        TE_SendToClient(clientIndex);
        
        // Sets switching time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
    }
}

void Weapon_OnFinish(int clientIndex, int weaponIndex, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Sets change animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE2);        

    // Sets active state
    SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, STATE_NORMAL);
    
    // Resets the shots count
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, 0);

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_SWITCH;
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    
    // Delete an effect
    TE_DispatchEffect(ZP_GetClientViewModel(clientIndex, true), _, "ParticleEffectStop");
    TE_SendToClient(clientIndex);
}

void Weapon_OnCreateBeam(int clientIndex, int weaponIndex)
{
    #pragma unused clientIndex
    
    // Initialize variables
    static float vEntPosition[3]; static float vEntAngle[3]; static float vVictimPosition[3]; bool bFound;

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, -10.0, vEntPosition);

    // Find any players in the radius
    int i; int it = 1; /// iterator
    while((i = ZP_FindPlayerInSphere(it, vEntPosition, WEAPON_BEAM_RADIUS)) != INVALID_ENT_REFERENCE)
    {
        // Skip humans
        if(ZP_IsPlayerHuman(i))
        {
            continue;
        }

        // Gets victim center
        GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vVictimPosition); vVictimPosition[2] += 45.0;

        // Validate visibility
        if(!TraceRay(clientIndex, i, vEntPosition, vVictimPosition))
        {
            continue;
        }

        // Create the damage for a victim
        if(!ZP_TakeDamage(i, clientIndex, clientIndex, WEAPON_BEAM_DAMAGE, DMG_BURN))
        {
            // Create a custom death event
            UTIL_CreateIcon(i, clientIndex, "inferno", true);
        }
        
        // Create a shake
        UTIL_CreateShakeScreen(i, WEAPON_BEAM_SHAKE_AMP, WEAPON_BEAM_SHAKE_FREQUENCY, WEAPON_BEAM_SHAKE_DURATION);
        
        // Sets found state
        bFound = true; 
        break;
    }
    
    // Found the aim origin
    if(!bFound)
    {
        // Gets client eye angle
        GetClientEyeAngles(clientIndex, vEntAngle);

        // Calculate aim end-vector
        TR_TraceRayFilter(vEntPosition, vEntAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, TraceFilter, clientIndex);
        TR_GetEndPosition(vVictimPosition);
    }

    // Sent a beam
    ZP_CreateWeaponTracer(clientIndex, weaponIndex, "1", "muzzle_flash", "medicgun_beam_red_invun", vVictimPosition, ZP_GetWeaponSpeed(gWeapon));
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
        GetEntProp(%2, Prop_Data, "m_iHealth"/**/), \
                                \
        GetEntProp(%2, Prop_Data, "m_iMaxHealth"/**/), \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, STATE_NORMAL);
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth"/**/, 0);
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

            // Sets active state
            SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, STATE_ACTIVE);
        }
        else
        {
            // Validate state
            static int iStateMode;
            if((iStateMode = GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/)))
            {
                // Switch animation
                switch(ZP_GetWeaponAnimation(clientIndex))
                {
                    case ANIM_IDLE : ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_IDLE2 : ANIM_IDLE_SIGNAL);
                    case ANIM_SHOOT1, ANIM_SHOOT2 : if(iStateMode == STATE_ACTIVE) ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2 }); else ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT_SIGNAL); 
                    case ANIM_RELOAD : ZP_SetWeaponAnimation(clientIndex, ANIM_RELOAD_SIGNAL); 
                }
            }
        }

        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            if(_call.PrimaryAttack(clientIndex, weaponIndex))
            {
                iButtons &= (~IN_ATTACK); //! Bugfix
                return Plugin_Changed;
            }
        }
        
        // Button secondary attack press
        else if(iButtons & IN_ATTACK2)
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
 * @brief Starts up a new trace ray using a new trace result and a customized trace ray filter. 
 *
 * @param entityIndex       The entity index.
 * @param targetIndex       The target index. 
 * @param vStartPosition    The starting position of the ray.
 * @param vEndPosition      The ending position of the ray.
 *
 * @return                  True of false.        
 **/
stock bool TraceRay(int entityIndex, int targetIndex, float vStartPosition[3], float vEndPosition[3])
{
    // Starts up a new trace ray using a new trace result and a customized trace ray filter
    TR_TraceRayFilter(vStartPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TraceFilter, entityIndex);

    // Validate any kind of collision along the trace ray
    bool bHit;
    if(!TR_DidHit() || TR_GetEntityIndex() == targetIndex) 
    {
        // If trace hit, then stop
        bHit = true;
    }

    // Return on the end
    return bHit;
}

/**
 * @brief Trace filter.
 *  
 * @param entityIndex       The entity index.
 * @param contentsMask      The contents mask.
 * @param filterIndex       The filter index.
 *
 * @return                  True or false.
 **/
public bool TraceFilter(int entityIndex, int contentsMask, int filterIndex)
{
    return (entityIndex != filterIndex);
}