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

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: Sfsword",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_SLASH_DAMAGE            50.0
#define WEAPON_STAB_DAMAGE             100.0
#define WEAPON_RADIUS_DAMAGE           10.0
#define WEAPON_SLASH_DISTANCE          70.0
#define WEAPON_STAB_DISTANCE           35.0
/**
 * @endsection
 **/

// Timer index
Handle Task_Stab[MAXPLAYERS+1] = null; 
Handle Task_Swing[MAXPLAYERS+1] = null; 
Handle Task_SwingAgain[MAXPLAYERS+1] = null; 
 
// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSoundAttack; int gSoundHit; ConVar hSoundLevel;
#pragma unused gSoundAttack, gSoundHit, hSoundLevel

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_ON,
    ANIM_OFF,
    ANIM_DRAW,
    ANIM_STAB,
    ANIM_IDLE2,
    ANIM_MIDSLASH1,
    ANIM_MIDSLASH2,
    ANIM_MIDSLASH3,
    ANIM_OFF_IDLE,
    ANIM_OFF_SLASH1,
    ANIM_OFF_SLASH2
};

// Weapon attack
enum
{
    ATTACK_SLASH_1,
    ATTACK_SLASH_2,
    ATTACK_SLASH_3,
    ATTACK_SLASH_DOUBLE,
    ATTACK_SLASH_SIZE
};

// Weapon states
enum
{
    STATE_ON,
    STATE_OFF
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
        Task_Swing[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
        Task_SwingAgain[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE 
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
    delete Task_Swing[clientIndex];
    delete Task_SwingAgain[clientIndex];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID("sfsword");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"sfsword\" wasn't find");

    // Sounds
    gSoundAttack = ZP_GetSoundKeyID("SFSWORD_HIT_SOUNDS");
    if(gSoundAttack == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFSWORD_HIT_SOUNDS\" wasn't find");
    gSoundHit = ZP_GetSoundKeyID("SFSWORD2_HIT_SOUNDS");
    if(gSoundHit == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFSWORD2_HIT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnIdle(int clientIndex, int weaponIndex, int iStep, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iStep, iChangeMode, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }

    // Validate mode
    if(iChangeMode)
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_OFF_IDLE); 
    
        // Sets next idle time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_OFF_IDLE));
    }
    else
    {
        // Sets idle animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_IDLE); 
    
        // Sets next idle time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_IDLE));
    }
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iStep, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iStep, iChangeMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);
    
    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
    
    // Sets the default mode
    SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_ON);
    
    // Sets the attack mode
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth", ATTACK_SLASH_1);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int iStep, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iStep, iChangeMode, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate mode
    if(iChangeMode)
    {
        // Sets the attack animation  
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_OFF_SLASH1, ANIM_OFF_SLASH2 });

        // Create timer for stab
        delete Task_Stab[clientIndex];
        Task_Stab[clientIndex] = CreateTimer(0.35, Weapon_OnStab, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
        
        // Play the attack sound
        ZP_EmitSoundToAll(gSoundAttack, 5, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    else
    {
        // Generate the attack mode
        int iCount = iStep % ATTACK_SLASH_SIZE;

        // Switch count
        switch(iCount)
        {
            case ATTACK_SLASH_DOUBLE :
            {
                // Sets the attack animation  
                ZP_SetWeaponAnimation(clientIndex, ANIM_STAB);   
                
                // Play the attack sound
                ZP_EmitSoundToAll(gSoundAttack, 4, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            }

            default :
            {
                // Sets the attack animation  
                ZP_SetWeaponAnimation(clientIndex, ANIM_MIDSLASH1 + iCount);   
                
                // Play the attack sound
                ZP_EmitSoundToAll(gSoundAttack, GetRandomInt(1, 3), clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            }
        }

        // Create timer for swing
        delete Task_Swing[clientIndex];
        Task_Swing[clientIndex] = CreateTimer(0.35, Weapon_OnSwing, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
        
        // Sets the attack mode
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth", iCount + 1);
    }
    
    // Sets attack animation
    ZP_SetPlayerAnimation(clientIndex, AnimType_FirePrimary);

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
                
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iStep, int iChangeMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iStep, iChangeMode, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate mode
    if(iChangeMode)
    {
        // Validate water
        if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
        {
            return;
        }
        
        // Sets the on animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_ON); 
    }
    else
    {
        // Sets the off animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_OFF);
    }
    
    // Gets the worldmodel index
    int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
    
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Sets the body index
        SetEntProp(entityIndex, Prop_Send, "m_nBody", (!iChangeMode));
    }
    
    // Sets the different mode
    SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", (!iChangeMode));
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponReload(gWeapon);
                
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    
}

void Weapon_OnSlash(int clientIndex, int weaponIndex, float flRightShift, float flUpShift, bool bSlash)
{    
    #pragma unused clientIndex, weaponIndex, flRightShift, bSlash

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3];

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 5.0 + flUpShift, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, bSlash ? WEAPON_SLASH_DISTANCE : WEAPON_STAB_DISTANCE, flRightShift, 5.0 + flUpShift, vEndPosition);

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
            TE_SetupSparks(vEndPosition, vAngle, 50, 2);
            TE_SendToAll();
            
            // Play sound
            ZP_EmitSoundToAll(gSoundHit, bSlash ? GetRandomInt(3, 4) : 5, clientIndex, SNDCHAN_ITEM, hSoundLevel.IntValue);
        }
        else
        {
            // Create the damage for victims
            UTIL_CreateDamage(_, vEndPosition, clientIndex, bSlash ? WEAPON_SLASH_DAMAGE : WEAPON_STAB_DAMAGE, WEAPON_RADIUS_DAMAGE, DMG_NEVERGIB, gWeapon);

            // Validate victim
            if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
            {
                // Play sound
                ZP_EmitSoundToAll(gSoundHit, bSlash ? GetRandomInt(1, 2) : 5, victimIndex, SNDCHAN_ITEM, hSoundLevel.IntValue);
            }
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
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_Stab[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {    
        // Do slash
        Weapon_OnSlash(clientIndex, weaponIndex, 0.0, 0.0, false);
    }

    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Timer for swing effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnSwing(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_Swing[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    { 
        float flUpShift = 14.0;
        float flRightShift = 14.0;
        float flRightModifier = 2.0;
        
        // Swith attack mode
        switch((GetEntProp(weaponIndex, Prop_Data, "m_iHealth") - 1) % ATTACK_SLASH_SIZE)
        {
            case ATTACK_SLASH_2:
            {
                // Change shift
                flRightShift *= -1.0;
                flRightModifier *= -1.0;
            }
            
            case ATTACK_SLASH_DOUBLE:
            {
                // Create timer for swing again
                delete Task_SwingAgain[clientIndex];
                Task_SwingAgain[clientIndex] = CreateTimer(0.3, Weapon_OnSwingAgain, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
        
        for(int i = 0; i < 12; i++)
        {
            // Do slash
            Weapon_OnSlash(clientIndex, weaponIndex, flRightShift -= flRightModifier, flUpShift -= 2.0, true);
        }
    }

    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Timer for swing again effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnSwingAgain(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_SwingAgain[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        float flRightShift = -14.0;
        for(int i = 0; i < 14; i++)
        {
            // Do slash
            Weapon_OnSlash(clientIndex, weaponIndex, flRightShift += 2.0, 0.0, true);
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
        GetEntProp(%2, Prop_Data, "m_iHealth"), \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth", ATTACK_SLASH_1);
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_ON);
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
        delete Task_Swing[clientIndex];
        delete Task_SwingAgain[clientIndex];
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
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }

        // Button secondary attack press
        if(iButtons & IN_ATTACK2 || GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
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