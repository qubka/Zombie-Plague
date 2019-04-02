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
    name            = "[ZP] Weapon: SG-Drill",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_STAB_DAMAGE      500.0
#define WEAPON_STAB_DISTANCE    80.0
#define WEAPON_STAB_TIME        1.2
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
Handle Task_Stab[MAXPLAYERS+1] = null; 

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

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
    // Weapons
    gWeapon = ZP_GetWeaponNameID("sgdrill");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"sgdrill\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("SGDRILL2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SGDRILL2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int clientIndex, int weaponIndex, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime

    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
    {
        return;
    }

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_STAB_TIME;
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);

    // Play sound
    ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_STAB1, ANIM_STAB2});

    // Create timer for stab
    delete Task_Stab[clientIndex];
    Task_Stab[clientIndex] = CreateTimer(0.8, Weapon_OnStab, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
}

void Weapon_OnSlash(int clientIndex, int weaponIndex)
{    
    #pragma unused clientIndex, weaponIndex

    // Initialize variables
    static float vPosition[3]; static float vEndPosition[3];  static float vPlaneNormal[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 10.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, WEAPON_STAB_DISTANCE, 0.0, 10.0, vEndPosition);

    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TraceFilter, clientIndex);

    // Validate collisions
    if(TR_GetFraction() >= 1.0)
    {
        // Initialize the hull intersection
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter, clientIndex);
    }
    
    // Validate collisions
    if(TR_GetFraction() < 1.0)
    {
        // Gets victim index
        int victimIndex = TR_GetEntityIndex();

        // Validate victim
        if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
        {    
            // Create the damage for a victim
            if(!ZP_TakeDamage(victimIndex, clientIndex, clientIndex, WEAPON_STAB_DAMAGE, DMG_SLASH))
            {
                // Create a custom death event
                UTIL_CreateIcon(victimIndex, clientIndex, "radarjammer", true);
            }

            // Gets center position
            GetEntPropVector(clientIndex, Prop_Data, "m_vecAbsOrigin", vPosition); vPosition[2] += 40.0;
            
            // Create a blood effect
            UTIL_CreateParticle(victimIndex, vPosition, _, _, "blood", 0.3);
        }
        else
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vEndPosition);
            TR_GetPlaneNormal(null, vPlaneNormal); 
    
            // Create a sparks effect
            TE_SetupSparks(vEndPosition, vPlaneNormal, 50, 2);
            TE_SendToAllInRange(vEndPosition, RangeType_Visibility);
        }
    }
}

/**
 * Timer for stab effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnStab(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_Stab[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {    
        // Do slash
        Weapon_OnSlash(clientIndex, weaponIndex);
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
        GetGameTime()           \
    )    

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