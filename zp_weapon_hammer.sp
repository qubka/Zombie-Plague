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
#pragma semicolon 1

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
Handle hWeaponStab[MAXPLAYERS+1] = null; 
 
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
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timers
        hWeaponStab[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
    }
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
    // Delete timers
    delete hWeaponStab[client];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID("big hammer");
    //if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"big hammer\" wasn't find");

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

void Weapon_OnHolster(int client, int weapon, int iChangeMode, float flCurrentTime)
{
    #pragma unused client, weapon, iChangeMode, flCurrentTime
    
    // Delete timers
    delete hWeaponStab[client];
    
    // Cancel mode change
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iChangeMode, float flCurrentTime)
{
    #pragma unused client, weapon, iChangeMode, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Validate mode
    if(iChangeMode)
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(client, ANIM_IDLESTAB); 
    
        // Sets next idle time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weapon, ANIM_IDLESTAB));
    }
    else
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(client, ANIM_IDLESLASH); 
    
        // Sets next idle time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weapon, ANIM_IDLESLASH));
    }
}

void Weapon_OnDeploy(int client, int weapon, int iChangeMode, float flCurrentTime)
{
    #pragma unused client, weapon, iChangeMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
    
    // Sets draw animation
    ZP_SetWeaponAnimation(client, iChangeMode ? ANIM_DRAWSTAB : ANIM_DRAW); 
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iChangeMode, float flCurrentTime)
{
    #pragma unused client, weapon, iChangeMode, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate mode
    if(!iChangeMode)
    {
        // Sets attack animation     
        ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SLASH1, ANIM_SLASH2 });  
        
        // Sets attack animation
        ZP_DoAnimationEvent(client, AnimType_MeleeSlash);
        
        // Create timer for stab
        delete hWeaponStab[client];
        hWeaponStab[client] = CreateTimer(1.0, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        // Sets attack animation
        ZP_SetWeaponAnimationPair(client, weapon, { ANIM_STAB1, ANIM_STAB2 }); 
        
        // Sets attack animation
        ZP_DoAnimationEvent(client, AnimType_MeleeStab);
        
        // Create timer for stab
        delete hWeaponStab[client];
        hWeaponStab[client] = CreateTimer(0.2, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Play attack sound
    ZP_EmitSoundToAll(gSound, 3, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);        
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iChangeMode, float flCurrentTime)
{
    #pragma unused client, weapon, iChangeMode, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Sets switch animation
    ZP_SetWeaponAnimation(client, !iChangeMode ? ANIM_MOVESTAB : ANIM_MOVESLASH); 

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponReload(gWeapon);
            
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime); 
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets switching time
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
}

void Weapon_OnSlash(int client, int weapon, float flRightShift, bool bSlash)
{    
    #pragma unused client, weapon, flRightShift, bSlash

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 0.0, 0.0, 5.0, vPosition);
    ZP_GetPlayerGunPosition(client, bSlash ? WEAPON_SLASH_DISTANCE : WEAPON_STAB_DISTANCE, flRightShift, 5.0, vEndPosition);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, SelfFilter, client);

    // Initialize some variables
    int victim;
    
    // Validate collisions
    if(!TR_DidHit(hTrace))
    {
        // Initialize the hull box
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, SelfFilter, client);
        
        // Validate collisions
        if(TR_DidHit(hTrace))
        {
            // Gets victim index
            victim = TR_GetEntityIndex(hTrace);

            // Is hit world ?
            if(victim < 1 || ZP_IsBSPModel(victim))
            {
                UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, SelfFilter, client);
            }
        }
    }
    
    // Validate collisions
    if(TR_DidHit(hTrace))
    {
        // Gets victim index
        victim = TR_GetEntityIndex(hTrace);
        
        // Returns the collision position of a trace result
        TR_GetEndPosition(vEndPosition, hTrace);

        // Is hit world ?
        if(victim < 1 || ZP_IsBSPModel(victim))
        {
            // Returns the collision plane
            TR_GetPlaneNormal(hTrace, vNormal); 
    
            // Create a sparks effect
            TE_SetupSparks(vEndPosition, vNormal, 100, 10);
            TE_SendToAll();
        }
        else
        {
            // Create the damage for victims
            UTIL_CreateDamage(_, vEndPosition, client, bSlash ? WEAPON_SLASH_DAMAGE : WEAPON_STAB_DAMAGE, WEAPON_RADIUS_DAMAGE, DMG_NEVERGIB, gWeapon);
        }

        // Play sound
        ZP_EmitSoundToAll(gSound, bSlash ? 2 : 1, client, SNDCHAN_ITEM, hSoundLevel.IntValue);
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
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID); int weapon;

    // Clear timer 
    hWeaponStab[client] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
    {    
        // Do slash
        Weapon_OnSlash(client, weapon, 0.0, !GetEntProp(weapon, Prop_Data, "m_iMaxHealth"));
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
        SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_SLASH);
        SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
    }
}     
    
/**
 * @brief Called on deploy of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDeploy(int client, int weapon, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Deploy(client, weapon);
    }
}

/**
 * @brief Called on holster of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponHolster(int client, int weapon, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Holster(client, weapon);
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
 *                                (like Plugin_Change) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Time to apply new mode
        static float flApplyModeTime;
        if((flApplyModeTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
        {
            // Sets switching time
            SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets different mode
            SetEntProp(weapon, Prop_Data, "m_iMaxHealth", !GetEntProp(weapon, Prop_Data, "m_iMaxHealth"));
        }

        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(client, weapon);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }

        // Button secondary attack press
        if(iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(client, weapon);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
        
        // Call event
        _call.Idle(client, weapon);
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Trace filter.
 *  
 * @param entity            The entity index.
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 *
 * @return                  True or false.
 **/
public bool SelfFilter(int entity, int contentsMask, int filter)
{
    return (entity != filter);
}