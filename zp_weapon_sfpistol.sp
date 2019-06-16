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
    name            = "[ZP] Weapon: SFPistol",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_COLOR           {185, 212, 11, 255}
/**
 * @endsection
 **/

// Item index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSoundAttack; int gSoundIdle; ConVar hSoundLevel;
#pragma unused gSoundAttack, gSoundIdle, hSoundLevel

// Decal index
int gBeam;
#pragma unused gBeam

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_ATTACK_LOOP1,
    ANIM_ATTACK_LOOP2,
    ANIM_DRAW,
    ANIM_RELOAD,
    ANIM_ATTACK_END
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
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("sfpistol");
    //if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"sfpistol\" wasn't find");

    // Sounds
    gSoundAttack = ZP_GetSoundKeyID("SFPISTOL_SHOOT_SOUNDS");
    if(gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFPISTOL_SHOOT_SOUNDS\" wasn't find");
    gSoundIdle = ZP_GetSoundKeyID("SFPISTOL_IDLE_SOUNDS");
    if(gSoundIdle == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFPISTOL_IDLE_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Models
    gBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Cancel reload
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
    
    // Stop sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0);
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
    
    // Sets idle animation
    ZP_SetWeaponAnimation(client, ANIM_IDLE); 
    
    // Play sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0);
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_STATIC, hSoundLevel.IntValue);

    // Sets next idle time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weapon, ANIM_IDLE));
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
    ZP_SetWeaponAnimation(client, ANIM_RELOAD); 
    ZP_SetPlayerAnimation(client, AnimType_Reload);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponReload(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

    // Stop sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0);
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets reloading time
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
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

    // Sets draw animation
    ZP_SetWeaponAnimation(client, ANIM_DRAW); 
    
    // Sets attack state
    SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);

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

    // Sets attack animation
    ZP_SetWeaponAnimationPair(client, weapon, { ANIM_ATTACK_LOOP1, ANIM_ATTACK_LOOP2 });   
    ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
    
    // Sets attack state
    SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ATTACK);
    
    // Substract ammo
    iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); if(!iClip)
    {
        Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }
    
    // Play sound
    ZP_EmitSoundToAll(gSoundIdle, 1, weapon, SNDCHAN_STATIC, SNDLEVEL_NONE, SND_STOP, 0.0);
    ZP_EmitSoundToAll(gSoundAttack, 1, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);         

    // Create a fire
    Weapon_OnCreateBeam(client, weapon);
    
    // Gets weapon muzzleflesh
    static char sMuzzle[NORMAL_LINE_LENGTH];
    ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

    // Creates a muzzle
    UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 0.1);
}

void Weapon_OnCreateBeam(int client, int weapon)
{
    #pragma unused client, weapon

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 30.0, 3.5, -10.0, vPosition);
    
    // Gets client eye angle
    GetClientEyeAngles(client, vAngle);

    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, SelfFilter, client);
    
    // Returns the collision position of a trace result
    TR_GetEndPosition(vEndPosition);
    
    // Emulate bullet shot
    PTaH_FX_FireBullets(client, PTaH_GetEconItemViewFromWeapon(weapon), vPosition, vAngle, 0, GetRandomInt(0, 1000), 0.0, 0.0, 0.0, 0, 0.0);

    // Gets beam lifetime
    float flLife = ZP_GetWeaponSpeed(gWeapon);
    
    // Sent a beam
    TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
    TE_SendToClient(client);
    
    // Gets worldmodel index
    int world = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
    
    // Validate entity
    if(world != -1)
    {
        // Gets attachment position
        ZP_GetAttachment(world, "muzzle_flash", vPosition, vAngle);
        
        // Sent a beam
        TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
        int[] iClients = new int[MaxClients]; int iCount;
        for(int i = 1; i <= MaxClients; i++)
        {
            if(!IsPlayerExist(i, false) || i == client || IsFakeClient(i)) continue;
            iClients[iCount++] = i;
        }
        TE_Send(iClients, iCount);
    }
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