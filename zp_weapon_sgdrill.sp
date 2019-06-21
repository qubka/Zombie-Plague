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
#include <ptah>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: SG-Drill",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_STAB_DAMAGE      500.0
#define WEAPON_STAB_RADIUS      50.0
#define WEAPON_STAB_DISTANCE    80.0
#define WEAPON_IDLE_TIME        4.0
#define WEAPON_ATTACK_TIME      1.0
#define WEAPON_STAB_TIME        1.76
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
    ANIM_STAB1,
    ANIM_STAB2
};

// Timer index
Handle hWeaponStab[MAXPLAYERS+1] = null; 

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSoundAttack; int gSoundIdle; ConVar hSoundLevel;
#pragma unused gSoundAttack, gSoundIdle, hSoundLevel

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
    gWeapon = ZP_GetWeaponNameID("sgdrill");
    //if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"sgdrill\" wasn't find");

    // Sounds
    gSoundAttack = ZP_GetSoundKeyID("SGDRILL_SHOOT_SOUNDS");
    if(gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"SGDRILL_SHOOT_SOUNDS\" wasn't find");
    gSoundIdle = ZP_GetSoundKeyID("SGDRILL_IDLE_SOUNDS");
    if(gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"SGDRILL_IDLE_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, flCurrentTime

    // Delete timers
    delete hWeaponStab[client];
    
    // Cancel reload
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0); 

    // Stop sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

    // Sets draw animation
    ZP_SetWeaponAnimation(client, ANIM_DRAW); 

    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, flCurrentTime

    // Validate clip
    if(min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
    {
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Sets reload animation
    ZP_SetWeaponAnimation(client, ANIM_RELOAD); 
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

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, flCurrentTime
    
    // Gets new amount
    int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

    // Sets ammunition
    SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + iAmount);
    SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

    // Sets reload time
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, flCurrentTime

    // Validate clip
    if(iClip <= 0)
    {
        // Validate ammo
        if(iAmmo)
        {
            Weapon_OnReload(client, weapon, iClip, iAmmo, flCurrentTime);
            return; /// Execute fake reload
        }
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }

    // Sets idle animation
    ZP_SetWeaponAnimation(client, ANIM_IDLE); 

    // Play sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets next idle time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate clip
    if(iClip <= 0)
    {
        // Emit empty sound
        ClientCommand(client, "play weapons/clipempty_rifle.wav");
        SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
        return;
    }

    // Substract ammo
    iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 

    // Sets attack animation
    ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });   

    // Play sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
    ZP_EmitSoundToAll(gSoundAttack, 1, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ///ZP_SetPlayerAnimation(client, AnimType_FirePrimary);;

    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));       

    // Sets next idle time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
    
    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);

    // Initiliaze name char
    static char sName[NORMAL_LINE_LENGTH];
    
    // Gets viewmodel index
    int view = ZP_GetClientViewModel(client, true);
    
    // Gets weapon muzzle
    ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
    UTIL_CreateParticle(view, _, _, "1", sName, 0.1);
    
    // Gets weapon shell
    ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
    UTIL_CreateParticle(view, _, _, "2", sName, 0.1);
    
    // Initialize variables
    static float vVelocity[3]; int iFlags = GetEntityFlags(client); 
    float flSpread = 0.01; float flInaccuracy = 0.013;

    // Gets client velocity
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(GetVectorLength(vVelocity) <= 0.0)
    {
        ZP_CreateWeaponKickBack(client, 2.5, 1.5, 0.15, 0.05, 5.5, 4.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(client, 5.0, 2.0, 0.4, 0.15, 7.0, 5.0, 5);
        flInaccuracy = 0.02;
        flSpread = 0.05;
    }
    else if(iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(client, 2.5, 0.5, 0.1, 0.025, 5.1, 6.3, 9);
        flInaccuracy = 0.01;
    }
    else
    {
        ZP_CreateWeaponKickBack(client, 2.8, 1.8, 0.14, 0.0375, 5.8, 5.8, 8);
    }
    
    // Create a bullet
    Weapon_OnCreateBullet(client, weapon, 0, GetRandomInt(0, 1000), flSpread, flInaccuracy);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Sets attack animation
    ZP_SetWeaponAnimationPair(client, weapon, { ANIM_STAB1, ANIM_STAB2});
    
    // Adds the delay to the game tick
    flCurrentTime += WEAPON_STAB_TIME;
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);

    // Play sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_WEAPON, SNDLEVEL_NONE, SND_STOP, 0.0);
    ZP_EmitSoundToAll(gSoundAttack, 2, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);

    // Create timer for stab
    delete hWeaponStab[client];
    hWeaponStab[client] = CreateTimer(0.8, Weapon_OnStab, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

void Weapon_OnCreateBullet(int client, int weapon, int iMode, int iSeed, float flSpread, float flInaccuracy)
{
    #pragma unused client, weapon, iMode, iSeed, flSpread, flInaccuracy
    
    // Initialize vectors
    static float vPosition[3]; static float vAngle[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 30.0, 7.0, 0.0, vPosition);

    // Gets client eye angle
    GetClientEyeAngles(client, vAngle);

    // Emulate bullet shot
    UTIL_FireBullets(client, PTaH_GetEconItemViewFromWeapon(weapon), vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, 0.0, 0, GetEntPropFloat(weapon, Prop_Send, "m_flRecoilIndex"));
}

void Weapon_OnSlash(int client, int weapon)
{    
    #pragma unused client, weapon

    // Initialize variables
    static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 0.0, 0.0, 10.0, vPosition);
    ZP_GetPlayerGunPosition(client, WEAPON_STAB_DISTANCE, 0.0, 10.0, vEndPosition);

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
        }
        else
        {
            // Create the damage for victims
            UTIL_CreateDamage(_, vEndPosition, client, WEAPON_STAB_DAMAGE, WEAPON_STAB_RADIUS, DMG_NEVERGIB, gWeapon);
        }
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
        Weapon_OnSlash(client, weapon);
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