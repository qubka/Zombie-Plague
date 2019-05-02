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
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: Hammer",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/  
#define WEAPON_SLASH_DAMAGE            1000.0
#define WEAPON_STAB_DAMAGE             500.0
#define WEAPON_SLASH_DISTANCE          90.0
#define WEAPON_STAB_DISTANCE           80.0
#define WEAPON_RADIUS_DAMAGE           50.0
/**
 * @endsection
 **/

// Timer index
Handle Task_Stab[MAXPLAYERS+1] = null; 
 
// Item index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Animation sequences
enum
{
    ANIM_DRAW,
    ANIM_IDLESLASH,
    ANIM_DRAWSTAB,
    ANIM_IDLESTAB,
    ANIM_MOVESLASH,
    ANIM_MOVESTAB,
    ANIM_SLASH1,
    ANIM_STAB1,
    ANIM_SLASH2,
    ANIM_STAB2
};

// Weapon states
enum
{
    STATE_SLASH,
    STATE_STAB
};

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timers
        Task_Stab[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
    }
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Delete timers
    delete Task_Stab[clientIndex];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID("big hammer");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"big hammer\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("HAMMER_HIT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HAMMER_HIT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int clientIndex, int weaponIndex, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iChangeMode, flCurrentTime
    
    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int clientIndex, int weaponIndex, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iChangeMode, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Validate mode
    if(iChangeMode)
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_IDLESTAB); 
    
        // Sets next idle time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_IDLESTAB));
    }
    else
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_IDLESLASH); 
    
        // Sets next idle time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_IDLESLASH));
    }
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iChangeMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);
    
    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, iChangeMode ? ANIM_DRAWSTAB : ANIM_DRAW); 
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iChangeMode, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate mode
    if(!iChangeMode)
    {
        // Sets the attack animation     
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SLASH1, ANIM_SLASH2 });  
        
        // Create timer for stab
        delete Task_Stab[clientIndex];
        Task_Stab[clientIndex] = CreateTimer(1.0, Weapon_OnStab, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        // Sets the attack animation
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_STAB1, ANIM_STAB2 }); 
        
        // Create timer for stab
        delete Task_Stab[clientIndex];
        Task_Stab[clientIndex] = CreateTimer(0.2, Weapon_OnStab, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Sets attack animation
    ZP_SetPlayerAnimation(clientIndex, AnimType_FirePrimary);
    
    // Play attack sound
    ZP_EmitSoundToAll(gSound, 3, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);        
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iChangeMode, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Sets the switch animation
    ZP_SetWeaponAnimation(clientIndex, !iChangeMode ? ANIM_MOVESTAB : ANIM_MOVESLASH); 

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponReload(gWeapon);
            
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime); 
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets the switching time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
}

void Weapon_OnSlash(int clientIndex, int weaponIndex, float flRightShift, bool bSlash)
{    
    #pragma unused clientIndex, weaponIndex, flRightShift, bSlash

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3];

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 5.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, bSlash ? WEAPON_SLASH_DISTANCE : WEAPON_STAB_DISTANCE, flRightShift, 5.0, vEndPosition);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, filter, clientIndex);

    // Initialize some variables
    int victimIndex;
    
    // Validate collisions
    if(!TR_DidHit(hTrace))
    {
        // Initialize the hull box
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, filter, clientIndex);
        
        // Validate collisions
        if(TR_DidHit(hTrace))
        {
            // Gets victim index
            victimIndex = TR_GetEntityIndex(hTrace);

            // Is hit world ?
            if(victimIndex < 1 || ZP_IsBSPModel(victimIndex))
            {
                UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, clientIndex);
            }
        }
    }
    
    // Validate collisions
    if(TR_DidHit(hTrace))
    {
        // Gets victim index
        victimIndex = TR_GetEntityIndex(hTrace);
        
        // Returns the collision position of a trace result
        TR_GetEndPosition(vEndPosition, hTrace);

        // Is hit world ?
        if(victimIndex < 1 || ZP_IsBSPModel(victimIndex))
        {
            // Returns the collision plane
            static float vAngle[3];
            TR_GetPlaneNormal(hTrace, vAngle); 
    
            // Create a sparks effect
            TE_SetupSparks(vEndPosition, vAngle, 100, 10);
            TE_SendToAll();
        }
        else
        {
            // Create the damage for victims
            UTIL_CreateDamage(_, vEndPosition, clientIndex, bSlash ? WEAPON_SLASH_DAMAGE : WEAPON_STAB_DAMAGE, WEAPON_RADIUS_DAMAGE, DMG_NEVERGIB, gWeapon);
        }

        // Play sound
        ZP_EmitSoundToAll(gSound, bSlash ? 2 : 1, clientIndex, SNDCHAN_ITEM, hSoundLevel.IntValue);
    }
    
    // Close trace 
    delete hTrace;
}

/**
 * @brief Timer for stab effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnStab(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_Stab[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {    
        // Do slash
        Weapon_OnSlash(clientIndex, weaponIndex, 0.0, !GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"));
    }

    // Destroy timer
    return Plugin_Stop;
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
        GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_SLASH);
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
        // Delete timers
        delete Task_Stab[clientIndex];

        // Call event
        _call.Holster(clientIndex, weaponIndex);
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
 *                                (like Plugin_Change) to change buttons.
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
            // Sets the switching time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets the different mode
            SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", !GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"));
        }

        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }

        // Button secondary attack press
        if(iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
        
        // Call event
        _call.Idle(clientIndex, weaponIndex);
    }
    
    // Allow button
    return Plugin_Continue;
}