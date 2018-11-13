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
    name            = "[ZP] Weapon: AirBurster",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "3.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_ITEM_REFERENCE       "airburster" // Name in weapons.ini from translation file
#define WEAPON_AIR_DAMAGE           10.0
#define WEAPON_AIR_DISTANCE         400.0
#define WEAPON_TIME_DELAY_ATTACK    0.075
#define WEAPON_TIME_DELAY_END       1.7
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT_MAIN,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_SHOOT1,
    ANIM_SHOOT_END,
    ANIM_SHOOT2,
};

// Weapon states
enum
{
    STATE_BEGIN,
    STATE_ATTACK
}

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Decal index
int decalSmoke;

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_ITEM_REFERENCE);

    // Sounds
    gSound = ZP_GetSoundKeyID("AIRBURSTER2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"AIRBURSTER2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    
    // Models
    decalSmoke = PrecacheModel("sprites/steam1.vmt", true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iAmmo, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
    
    // Sets the shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnSecondaryAttack(const int clientIndex, const int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Validate ammo
    if(iAmmo <= 0)
    {
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }

    // Substract ammo
    iAmmo -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo); 

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_ATTACK;
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    ///SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);

    // Sets the shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
    
    // Sets the attack state
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_ATTACK);
    
    // Emit sound
    static char sSound[PLATFORM_MAX_PATH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
    EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets the attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT1, ANIM_SHOOT2 });
    
    // Create a air
    Weapon_OnCreateAirBurst(clientIndex, weaponIndex);

    // Initialize some variables
    static float vVelocity[3]; static int iFlags; iFlags = GetEntityFlags(clientIndex);

    // Gets the client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        Weapon_OnKickBack(clientIndex, 3.5, 4.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        Weapon_OnKickBack(clientIndex, 5.0, 4.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        Weapon_OnKickBack(clientIndex, 3.5, 1.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        Weapon_OnKickBack(clientIndex, 2.75, 2.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }
}

void Weapon_OnCreateAirBurst(const int clientIndex, const int weaponIndex)
{
    #pragma unused clientIndex, weaponIndex

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3];

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 10.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, WEAPON_AIR_DISTANCE, 0.0, 10.0, vEndPosition);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter, clientIndex);

    // Validate collisions
    if(TR_GetFraction(hTrace) >= 1.0)
    {
        // Initialize the hull intersection
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter, clientIndex);
    }
    
    // Validate collisions
    if(TR_GetFraction(hTrace) < 1.0)
    {
        // Gets the victim index
        int victimIndex = TR_GetEntityIndex(hTrace);

        // Validate victim
        if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
        {    
            // Create the damage for a victim
            ZP_TakeDamage(victimIndex, clientIndex, WEAPON_AIR_DAMAGE, DMG_NEVERGIB, weaponIndex);
        }
        else
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vEndPosition, hTrace);
    
            // Create a sparks effect
            TE_SetupSmoke(vEndPosition, decalSmoke, 10.0, 10);
            TE_SendToAllInRange(vEndPosition, RangeType_Visibility);
        }
    }
    
    // Close the trace
    delete hTrace;
}

void Weapon_OnEndAttack(const int clientIndex, const int weaponIndex, const int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Validate attack
    if(GetEntProp(weaponIndex, Prop_Send, "m_iClip2"))
    {
        // Sets the end animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT_END);        

        // Sets the begin state
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_BEGIN);

        // Adds the delay to the game tick
        flCurrentTime += WEAPON_TIME_DELAY_END;
        
        // Sets the next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
        ///SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    }
}

void Weapon_OnKickBack(const int clientIndex, float upBase, float lateralBase, const float upMod, const float lateralMod, float upMax, float lateralMax, const int directionChange)
{
    #pragma unused clientIndex, upBase, lateralBase, upMod, lateralMod, upMax, lateralMax, directionChange 

    // Initialize some variables
    static int iDirection; static int iShotsFired; static float vPunchAngle[3];
    GetEntPropVector(clientIndex, Prop_Send, "m_aimPunchAngle", vPunchAngle);

    // Gets a shots fired
    if((iShotsFired = GetEntProp(clientIndex, Prop_Send, "m_iShotsFired")) != 1)
    {
        // Calculate a base power
        upBase += iShotsFired * upMod;
        lateralBase += iShotsFired * lateralMod;
    }

    // Reduce a max power
    upMax *= -1.0;
    vPunchAngle[0] -= upBase;

    // Validate max angle
    if(upMax >= vPunchAngle[0])
    {
        vPunchAngle[0] = upMax;
    }

    // Gets a direction change
    if((iDirection = GetEntProp(clientIndex, Prop_Send, "m_iDirection")))
    {
        // Increase the angle
        vPunchAngle[1] += lateralBase;

        // Validate min angle
        if(lateralMax < vPunchAngle[1])
        {
            vPunchAngle[1] = lateralMax;
        }
    }
    else
    {
        // Decrease the angle
        lateralMax *=  -1.0;
        vPunchAngle[1] -= lateralBase;

        // Validate max angle
        if(lateralMax > vPunchAngle[1])
        {
            vPunchAngle[1] = lateralMax;
        }
    }

    // Create a direction change
    if(!GetRandomInt(0, directionChange))
    {
        SetEntProp(clientIndex, Prop_Send, "m_iDirection", !iDirection);
    }

    // Sets a punch angle
    SetEntPropVector(clientIndex, Prop_Send, "m_aimPunchAngle", vPunchAngle);
    SetEntPropVector(clientIndex, Prop_Send, "m_viewPunchAngle", vPunchAngle);
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
        GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
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
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_BEGIN);
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
        /// Block the scope
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 9999.9);

        // Button secondary attack press
        if(!(iButtons & IN_ATTACK) && iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
        // Button secondary attack release
        else if(iLastButtons & IN_ATTACK2)
        {
            // Call event
            _call.EndAttack(clientIndex, weaponIndex);
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * Trace filter.
 *  
 * @param entityIndex       The entity index.
 * @param contentsMask      The contents mask.
 * @param clientIndex       The client index.
 *
 * @return                  True or false.
 **/
public bool TraceFilter(const int entityIndex, const int contentsMask, const int clientIndex)
{
    // If entity is a player, continue tracing
    return (entityIndex != clientIndex);
}