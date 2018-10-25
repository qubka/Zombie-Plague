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
    name            = "[ZP] Weapon: SFPistol",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_ITEM_REFERENCE       "sfpistol" // Name in weapons.ini from translation file 
#define WEAPON_BEAM_DAMAGE          50.0
#define WEAPON_BEAM_COLOR           {185, 212, 11, 255}
#define WEAPON_BEAM_MODEL           "materials/sprites/laserbeam.vmt"
#define WEAPON_TIME_DELAY_END       0.4
/**
 * @endsection
 **/

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Decal index
int decalBeam;

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
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_ITEM_REFERENCE);

    // Sounds
    gSound = ZP_GetSoundKeyID("SFPISTOL_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SFPISTOL_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    
    // Models
    decalBeam = PrecacheModel(WEAPON_BEAM_MODEL, true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnReload(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponReload(gWeapon));
}

void Weapon_OnReloadStart(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode > STATE_BEGIN)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate ammo
    if(!iAmmo)
    {
        return;
    }
    
    // Validate clip
    if(iClip < ZP_GetWeaponClip(gWeapon))
    {
        // Sets the reload animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_RELOAD); 

        /// Reset for allowing reload
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    }
}

bool Weapon_OnReloadEmulate(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate reload
    return !iClip && iAmmo ? true : false;
}

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
    
    // Sets the attack state
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_BEGIN);

    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(const int clientIndex, const int weaponIndex, int iClip, const int iAmmo, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9); // Should be here for pistols!
    
    // Validate ammo
    if(iClip <= 0)
    {
        // Validate mode
        if(iStateMode > STATE_BEGIN)
        {
            Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime);
        }
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }

    // Sets the attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_ATTACK_LOOP1, ANIM_ATTACK_LOOP2 });   

    // Sets the attack state
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_ATTACK);
    
    // Substract ammo
    iClip -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip); if(!iClip)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }

    // Emit the attack sound
    static char sSound[PLATFORM_MAX_PATH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
    EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);         

    // Create a fire
    Weapon_OnCreateBeam(clientIndex, weaponIndex);
}

void Weapon_OnCreateBeam(const int clientIndex, const int weaponIndex)
{
    #pragma unused clientIndex, weaponIndex

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 3.5, -10.0, vPosition);
    
    // Gets the client eye angle
    GetClientEyeAngles(clientIndex, vAngle);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vAngle, MASK_SHOT, RayType_Infinite, TraceFilter, clientIndex);

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
            ZP_TakeDamage(victimIndex, clientIndex, WEAPON_BEAM_DAMAGE, DMG_NEVERGIB, weaponIndex);
        }
    }
    
    // Returns the collision position/angle of a trace result
    TR_GetEndPosition(vEndPosition, hTrace);
    
    // Gets the beam lifetime
    float flLife = ZP_GetWeaponSpeed(gWeapon);
    
    // Sent a beam
    TE_SetupBeamPoints(vPosition, vEndPosition, decalBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
    TE_SendToClient(clientIndex);
    
    // Gets the worldmodel index
    int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
    
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Gets attachment position
        ZP_GetAttachment(entityIndex, "muzzle_flash", vPosition, vAngle);
        
        // Sent a beam
        TE_SetupBeamPoints(vPosition, vEndPosition, decalBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
        int[] iClients = new int[MaxClients]; int iCount;
        for(int i = 1; i <= MaxClients; i++)
        {
            if(!IsPlayerExist(i, false) || i == clientIndex || IsFakeClient(i)) continue;
            iClients[iCount++] = i;
        }
        TE_Send(iClients, iCount);
    }
    
    // Close the trace
    delete hTrace;
}

void Weapon_OnEndAttack(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate mode
    if(iStateMode > STATE_BEGIN)
    {
        // Sets the end animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_ATTACK_END);        

        // Stop the attack sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue, SND_STOP);
        
        // Sets the begin state
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_BEGIN);

        // Adds the delay to the game tick
        flCurrentTime += WEAPON_TIME_DELAY_END;
        
        // Sets the next attack time
        SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + ZP_GetWeaponReload(gWeapon));
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);
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
        GetEntProp(%2, Prop_Send, "m_iClip2"), \
                                \
        GetGameTime() \
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
 * Called on reload of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponReload(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Reload(clientIndex, weaponIndex);
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
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }
        // Button primary attack release
        else if(iLastButtons & IN_ATTACK)
        {
            // Call event
            _call.EndAttack(clientIndex, weaponIndex);
        }
        
        // Button reload press
        if(iButtons & IN_RELOAD)
        {
            // Validate overtransmitting
            if(!(iLastButtons & IN_RELOAD))
            {
                // Call event
                _call.ReloadStart(clientIndex, weaponIndex);
            }
        }
        else
        {
            // Call event
            if(_call.ReloadEmulate(clientIndex, weaponIndex))
            {
                iButtons |= IN_RELOAD; //! Bugfix
                return Plugin_Changed;
            }
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