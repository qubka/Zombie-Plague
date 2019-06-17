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
    name            = "[ZP] Weapon: ChainSaw",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_SLASH_DAMAGE            100.0
#define WEAPON_STAB_DAMAGE             50.0
#define WEAPON_SLASH_DISTANCE          80.0
#define WEAPON_RADIUS_DAMAGE           10.0
#define WEAPON_STAB_DISTANCE           90.0
/**
 * @endsection
 **/

// Timer index
Handle hWeaponStab[MAXPLAYERS+1] = null; 
 
// Item index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSoundAttack; int gSoundHit; int gSoundIdle; ConVar hSoundLevel;
#pragma unused gSoundAttack, gSoundHit, gSoundIdle, hSoundLevel

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_DUMMY,
    ANIM_EMPTY_IDLE,
    ANIM_EMPTY_SHOOT1,
    ANIM_EMPTY_RELOAD,
    ANIM_EMPTY_DRAW,
    ANIM_ATTACK_END,
    ANIM_ATTACK_LOOP1,
    ANIM_ATTACK_LOOP2,
    ANIM_ATTACK_START,
    ANIM_EMPTY_SHOOT2
};

// Weapon states
enum
{
    STATE_BEGIN,
    STATE_ATTACK
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
    // Weapons
    gWeapon = ZP_GetWeaponNameID("chainsaw");
    //if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"chainsaw\" wasn't find");

    // Sounds
    gSoundAttack = ZP_GetSoundKeyID("CHAINSAW_SHOOT_SOUNDS");
    if(gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"CHAINSAW_SHOOT_SOUNDS\" wasn't find");
    gSoundHit = ZP_GetSoundKeyID("CHAINSAW_HIT_SOUNDS");
    if(gSoundHit == -1) SetFailState("[ZP] Custom sound key ID from name : \"CHAINSAW_HIT_SOUNDS\" wasn't find");
    gSoundIdle = ZP_GetSoundKeyID("CHAINSAW_IDLE_SOUNDS");
    if(gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"CHAINSAW_IDLE_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Delete timers
    delete hWeaponStab[client];
    
    // Cancel reload
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
    
    // Stop sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate clip
    if(iClip <= 0)
    {
        // Validate ammo
        if(iAmmo)
        {
            Weapon_OnReload(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
            return; /// Execute fake reload
        }
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Resets sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
    
    // Validate clip
    if(iClip)
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(client, ANIM_IDLE); 
        
        // Sets next idle time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weapon, ANIM_IDLE));
    
        // Play sound
        ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    else
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(client, ANIM_EMPTY_IDLE);
        
        // Sets next idle time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weapon, ANIM_EMPTY_IDLE));
    }
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate clip
    if(min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
    {
        return;
    }
    
    // Validate mode
    if(iStateMode > STATE_BEGIN)
    {
        Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Sets reload animation
    ZP_SetWeaponAnimation(client, !iClip ? ANIM_EMPTY_RELOAD : ANIM_RELOAD); 
    ZP_SetPlayerAnimation(client, AnimType_Reload);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponReload(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

    // Stop sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets reloading time
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
    
    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Gets new amount
    int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

    // Sets ammunition
    SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
    SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

    // Sets reload time
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
    
    // Sets draw animation
    ZP_SetWeaponAnimation(client, !iClip ? ANIM_EMPTY_DRAW : ANIM_DRAW); 
    
    // Sets attack state
    SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
    
    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", 0);

    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate clip
    if(iClip <= 0)
    {
        // Validate mode
        if(iStateMode > STATE_BEGIN)
        {
            Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        }
        else
        {
            Weapon_OnSecondaryAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        }
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }
    
    // Resets sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);

    // Switch mode
    switch(iStateMode)
    {
        case STATE_BEGIN :
        {
            // Sets begin animation
            ZP_SetWeaponAnimation(client, ANIM_ATTACK_START);        

            // Sets attack state
            SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ATTACK);

            // Adds the delay to the game tick
            flCurrentTime += ZP_GetSequenceDuration(weapon, ANIM_ATTACK_START);
            
            // Sets next attack time
            SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
        }

        case STATE_ATTACK :
        {
            // Sets attack animation
            ZP_SetWeaponAnimationPair(client, weapon, { ANIM_ATTACK_LOOP1, ANIM_ATTACK_LOOP2 });   
            ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
    
            // Substract ammo
            iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); if(!iClip)
            {
                Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
                return;
            }

            // Play sound
            ZP_EmitSoundToAll(gSoundAttack, 2, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            
            // Adds the delay to the game tick
            flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
            
            // Sets next attack time
            SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);         

            // Sets shots count
            SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
            
            // Create a melee attack
            Weapon_OnSlash(client, weapon, 0.0, true);

            // Gets weapon muzzleflesh
            static char sMuzzle[NORMAL_LINE_LENGTH];
            ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
            
            // Creates a muzzle
            UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 3.5);
            
            // Initialize variables
            static float vVelocity[3]; int iFlags = GetEntityFlags(client);

            // Gets client velocity
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

            // Apply kick back
            if(GetVectorLength(vVelocity) <= 0.0)
            {
                ZP_CreateWeaponKickBack(client, 6.5, 5.45, 5.225, 5.05, 6.5, 7.5, 7);
            }
            else if(!(iFlags & FL_ONGROUND))
            {
                ZP_CreateWeaponKickBack(client, 7.0, 5.0, 5.5, 5.35, 14.0, 11.0, 5);
            }
            else if(iFlags & FL_DUCKING)
            {
                ZP_CreateWeaponKickBack(client, 5.9, 5.35, 5.15, 5.025, 10.5, 6.5, 9);
            }
            else
            {
                ZP_CreateWeaponKickBack(client, 5.0, 5.375, 5.175, 5.0375, 10.75, 1.75, 8);
            }
        }
    }
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }

    // Validate mode
    if(iStateMode > STATE_BEGIN)
    {
        Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }
    
    // Resets sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);

    // Validate no ammo
    if(!iClip)
    {
        // Sets attack animation  
        ZP_SetWeaponAnimationPair(client, weapon, { ANIM_EMPTY_SHOOT1, ANIM_EMPTY_SHOOT2 });    

        // Adds the delay to the game tick
        flCurrentTime += ZP_GetSequenceDuration(weapon, ANIM_EMPTY_SHOOT1);
        
        // Play sound
        ZP_EmitSoundToAll(gSoundAttack, 4, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    else
    {
        // Sets attack animation
        ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });     

        // Adds the delay to the game tick
        flCurrentTime += ZP_GetSequenceDuration(weapon, ANIM_SHOOT1);
        
        // Play sound
        ZP_EmitSoundToAll(gSoundAttack, GetRandomInt(2, 3), client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }

    // Create timer for stab
    delete hWeaponStab[client];
    hWeaponStab[client] = CreateTimer(0.105, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
}

void Weapon_OnSlash(int client, int weapon, float flRightShift, bool bSlash)
{    
    #pragma unused client, weapon, flRightShift, bSlash

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 0.0, 0.0, 10.0, vPosition);
    ZP_GetPlayerGunPosition(client, bSlash ? WEAPON_SLASH_DISTANCE : WEAPON_STAB_DISTANCE, flRightShift, 10.0, vEndPosition);

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
            TE_SetupSparks(vEndPosition, vNormal, 50, 2);
            TE_SendToAll();
            
            // Play sound
            ZP_EmitSoundToAll(gSoundHit, GetRandomInt(1, 2), client, SNDCHAN_ITEM, hSoundLevel.IntValue);
        }
        else
        {
            // Create the damage for victims
            UTIL_CreateDamage(_, vEndPosition, client, bSlash ? WEAPON_SLASH_DAMAGE : WEAPON_STAB_DAMAGE, WEAPON_RADIUS_DAMAGE, DMG_NEVERGIB, gWeapon);

            // Validate victim
            if(IsPlayerExist(victim) && ZP_IsPlayerZombie(victim))
            {
                // Play sound
                ZP_EmitSoundToAll(gSoundHit, GetRandomInt(3, 4), victim, SNDCHAN_ITEM, hSoundLevel.IntValue);
            }
        }
    }
    
    // Close trace 
    delete hTrace;
}

void Weapon_OnEndAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate mode
    if(iStateMode > STATE_BEGIN)
    {
        // Sets end animation
        ZP_SetWeaponAnimation(client, ANIM_ATTACK_END);        

        // Sets begin state
        SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);

        // Adds the delay to the game tick
        flCurrentTime += ZP_GetSequenceDuration(weapon, ANIM_ATTACK_END);
        
        // Sets next attack time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
    }
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
        float flRightShift = -14.0;
        for(int i = 0; i < 15; i++)
        {
            // Do slash
            Weapon_OnSlash(client, weapon, flRightShift += 4.0, false);
        }
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
        GetEntProp(%2, Prop_Send, "m_iClip1"), \
                                \
        GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
                                \
        GetEntProp(%2, Prop_Data, "m_iHealth"), \
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
        SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
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
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Time to reload weapon
        static float flReloadTime;
        if((flReloadTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flReloadTime <= GetGameTime())
        {
            // Call event
            _call.ReloadFinish(client, weapon);
        }
        else
        {
            // Button reload press
            if(iButtons & IN_RELOAD)
            {
                // Call event
                _call.Reload(client, weapon);
                iButtons &= (~IN_RELOAD); //! Bugfix
                return Plugin_Changed;
            }
        }

        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(client, weapon);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }
        // Button primary attack release
        else if(iLastButtons & IN_ATTACK)
        {
            // Call event
            _call.EndAttack(client, weapon);
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