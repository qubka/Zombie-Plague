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
    name            = "[ZP] Weapon: Janus XI",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_SIGNAL_COUNTER       10
#define WEAPON_ACTIVE_COUNTER       10
#define WEAPON_ACTIVE_MULTIPLIER    2.0
#define WEAPON_BULLET_DAMAGE        80.0
#define WEAPON_BULLET_RADIUS        1.0
#define WEAPON_TIME_DELAY_ATTACK    0.3
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_START_RELOAD,
    ANIM_SHOOT2,
    ANIM_AFTER_RELOAD,
    ANIM_DRAW,
    ANIM_IDLE_SIGNAL,
    ANIM_SHOOT_SIGNAL_1,
    ANIM_START_RELOAD_SIGNAL,
    ANIM_INSERT1,
    ANIM_AFTER_RELOAD_SIGNAL,
    ANIM_DRAW_SIGNAL,
    ANIM_IDLE2,
    ANIM_SHOOT2_1,
    ANIM_DRAW2,
    ANIM_CHANGE,
    ANIM_CHANGE2,
    ANIM_INSERT2,
    ANIM_SHOOT_SIGNAL_2,
    ANIM_INSERT_SIGNAL_1,
    ANIM_INSERT_SIGNAL_2,
    ANIM_SHOOT2_2
};

// Weapon states
enum
{
    STATE_NORMAL,
    STATE_SIGNAL,
    STATE_ACTIVE
};

// Reload states
enum
{
    RELOAD_START,
    RELOAD_INSERT,
    RELOAD_END
};

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
    gWeapon = ZP_GetWeaponNameID("janus11");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"janus11\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("JANUSXI_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSXI_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnThink(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);
    /// HACK~HACK apply on each frame for shotguns
    
    // Validate clip/ammo
    if(iClip == ZP_GetWeaponClip(gWeapon) || iAmmo <= 0)
    {
        // Validate mode
        if(iReloadMode == RELOAD_END)
        {
            Weapon_OnReloadFinish(clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
            return;
        }
    }

    // Switch mode
    switch(iReloadMode)
    {
        case RELOAD_INSERT :
        {        
            // Validate animation delay
            if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
            {
                return;
            }

            // Sets reload animation
            ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, !iStateMode ? { ANIM_INSERT1, ANIM_INSERT2 } : { ANIM_INSERT_SIGNAL_1, ANIM_INSERT_SIGNAL_2 });
            ZP_SetPlayerAnimation(clientIndex, AnimType_ReloadLoop);
            
            // Adds the delay to the game tick
            flCurrentTime += ZP_GetSequenceDuration(weaponIndex, ANIM_INSERT1);
            
            // Sets next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);

            // Sets new reload state
            SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_END);
        }
        
        case RELOAD_END :
        {
            // Sets the ammunition
            SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip + 1)
            SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - 1);
            
            // Sets new reload state
            SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
        }
    }
}

void Weapon_OnHolster(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flUseLookAtAngle", 0.0);
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

    // Cancel reload
    SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
    
    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnIdle(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Validate mode
    if(iReloadMode == RELOAD_START)
    {
        // Validate clip
        if(iClip <= 0)
        {
            // Validate ammo
            if(iAmmo)
            {
                Weapon_OnReload(clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
                return; /// Execute fake reload
            }
        }
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Sets the sequence index
    int iSequence = (iStateMode == STATE_ACTIVE) ? ANIM_IDLE2 : (iStateMode == STATE_SIGNAL) ? ANIM_IDLE_SIGNAL : ANIM_IDLE
       
    // Sets idle animation
    ZP_SetWeaponAnimation(clientIndex, iSequence); 

    // Sets next idle time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, iSequence));
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Validate mode
    if(iReloadMode > RELOAD_START)
    {
        Weapon_OnReloadFinish(clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate mode
    if(iStateMode == STATE_ACTIVE)
    {
        // Validate counter
        if(iCounter > WEAPON_ACTIVE_COUNTER)
        {
            Weapon_OnFinish(clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
            return;
        }

        // Sets attack animation
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2 });   

        // Sets next idle time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_SHOOT2_1));

        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + (ZP_GetWeaponSpeed(gWeapon) - WEAPON_TIME_DELAY_ATTACK));       

        // Play sound
        ZP_EmitSoundToAll(gSound, 2, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    else
    {
        // Validate clip
        if(iClip <= 0)
        {
            // Emit empty sound
            ClientCommand(clientIndex, "play weapons/clipempty_rifle.wav");
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
            return;
        }
        
        // Substract ammo
        iClip -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip); 
        
        // Validate counter
        if(iCounter > WEAPON_SIGNAL_COUNTER)
        {
            // Sets signal mode
            SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_SIGNAL);

            // Sets the shots count
            iCounter = -1;
            
            // Play sound
            ZP_EmitSoundToAll(gSound, 3, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        }
        
        // Sets attack animation
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, (iStateMode == STATE_SIGNAL) ? { ANIM_SHOOT_SIGNAL_1, ANIM_SHOOT_SIGNAL_2 } : { ANIM_SHOOT1, ANIM_SHOOT2 });   

        // Sets next idle time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_SHOOT_SIGNAL_1));
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));       
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    
    // Sets attack animation
    ZP_SetPlayerAnimation(clientIndex, AnimType_FirePrimary);
    
    // Sets shots count
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth", iCounter + 1);

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);

    // Initiliaze name char
    static char sName[NORMAL_LINE_LENGTH];
    
    // Gets the viewmodel index
    int viewIndex = ZP_GetClientViewModel(clientIndex, true);
    
    // Gets weapon muzzle
    ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
    UTIL_CreateParticle(viewIndex, _, _, "1", sName, 0.1);
    
    // Gets weapon shell
    ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
    UTIL_CreateParticle(viewIndex, _, _, "2", sName, 0.1);
    
    // Initialize variables
    static float vVelocity[3]; int iFlags = GetEntityFlags(clientIndex); 
    float flSpread = 0.1; float flInaccuracy = 0.03;

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        ZP_CreateWeaponKickBack(clientIndex, 2.5, 1.5, 0.15, 0.05, 5.5, 4.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(clientIndex, 6.0, 3.0, 0.4, 0.15, 7.0, 5.0, 5);
        flInaccuracy = 0.04;
        flSpread = 0.2;
    }
    else if(iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(clientIndex, 2.5, 0.5, 0.1, 0.025, 5.5, 6.5, 9);
        flInaccuracy = 0.02;
    }
    else
    {
        ZP_CreateWeaponKickBack(clientIndex, 2.75, 1.8, 0.14, 0.0375, 5.75, 5.75, 8);
    }
    
    // Create a bullet
    Weapon_OnCreateBullet(clientIndex, weaponIndex, 0, GetRandomInt(0, 1000), flSpread, flInaccuracy);
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Validate mode
    if(iStateMode == STATE_SIGNAL)
    {
        // Validate mode
        if(iReloadMode > RELOAD_START)
        {
            Weapon_OnReloadFinish(clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime);
            return;
        }
    
        // Validate animation delay
        if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
        {
            return;
        }
        
        // Sets change animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE);        

        // Sets active state
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_ACTIVE);
        
        // Sets the shots count
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth", 0);
        
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetSequenceDuration(weaponIndex, ANIM_CHANGE);
                
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);
        
        // Remove the delay to the game tick
        flCurrentTime -= 0.5;
        
        // Sets switching time
        SetEntPropFloat(weaponIndex, Prop_Data, "m_flUseLookAtAngle", flCurrentTime);
    }
}

void Weapon_OnReload(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Validate mode
    if(iStateMode == STATE_ACTIVE)
    {
        return;
    }
    
    // Validate ammo
    if(iAmmo <= 0)
    {
        return;
    }
    
    // Validate clip
    if(iClip >= ZP_GetWeaponClip(gWeapon))
    {
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate mode
    if(iReloadMode == RELOAD_START)
    {
        // Sets the sequence index
        int iSequence = !iStateMode ? ANIM_START_RELOAD : ANIM_START_RELOAD_SIGNAL;

        // Sets start reload animation
        ZP_SetWeaponAnimation(clientIndex, iSequence); 
        ZP_SetPlayerAnimation(clientIndex, AnimType_ReloadStart);
        
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetSequenceDuration(weaponIndex, iSequence);
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);

        // Sets new reload state
        SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
    }
}

void Weapon_OnReloadFinish(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Sets the sequence index
    int iSequence = !iStateMode ? ANIM_AFTER_RELOAD : ANIM_AFTER_RELOAD_SIGNAL
    
    // Sets end animation
    ZP_SetWeaponAnimation(clientIndex, iSequence); 
    ZP_SetPlayerAnimation(clientIndex, AnimType_ReloadEnd);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetSequenceDuration(weaponIndex, iSequence);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Stop reload
    SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
}

void Weapon_OnFinish(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, iReloadMode, flCurrentTime
    
    // Sets change animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE2);  
    
    // Sets active state
    SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
    
    // Sets the shots count
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth", 0);

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetSequenceDuration(weaponIndex, ANIM_CHANGE2);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);
}

void Weapon_OnCreateBullet(int clientIndex, int weaponIndex, int iMode, int iSeed, float flSpread, float flInaccuracy)
{
    #pragma unused clientIndex, weaponIndex, iMode, iSeed, flSpread, flInaccuracy
    
    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vEndPosition[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 7.0, 0.0, vPosition);

    // Gets client eye angle
    GetClientEyeAngles(clientIndex, vAngle);

    // Emulate primary attack, will return false on Windows
    if(!ZP_FireBullets(clientIndex, weaponIndex, vPosition, vAngle, iMode, iSeed, flInaccuracy, flSpread, 0))
    {
        /*
         * This code bellow execute on Windows only, in future it will be removed
         * SourceMod still not able to call functions with registers via parameters
         */
         
        // Fire a bullet 
        TR_TraceRayFilter(vPosition, vAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, filter, clientIndex); 

        // Validate collisions
        if(TR_DidHit()) 
        {
            // Returns the collision position of a trace result
            TR_GetEndPosition(vEndPosition); 
        
            // Weapons are perfectly accurate, but this doesn't look good for tracers
            // Add a little noise to them, but not enough so that it looks like they're missing
            vEndPosition[0] += GetRandomFloat(-10.0, 10.0); 
            vEndPosition[1] += GetRandomFloat(-10.0, 10.0); 
            vEndPosition[2] += GetRandomFloat(-10.0, 10.0); 

            // Bullet tracer
            ZP_CreateWeaponTracer(clientIndex, weaponIndex, "1", "muzzle_flash", "weapon_tracers_shot", vEndPosition, ZP_GetWeaponSpeed(gWeapon));

            // Create the damage for victims
            UTIL_CreateDamage(_, vEndPosition, clientIndex, WEAPON_BULLET_DAMAGE, WEAPON_BULLET_RADIUS, DMG_NEVERGIB, gWeapon);
        }
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
        GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
                                \
        GetEntProp(%2, Prop_Data, "m_iReloadHudHintCount"), \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth", 0);
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
        SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
        SetEntPropFloat(weaponIndex, Prop_Data, "m_flUseLookAtAngle", 0.0);
    }
}

/**
 * @brief Called on bullet of a weapon.
 *
 * @param clientIndex       The client index.
 * @param vBulletPosition   The position of a bullet hit.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponBullet(int clientIndex, float vBulletPosition[3], int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Sent a tracer
        ZP_CreateWeaponTracer(clientIndex, weaponIndex, "1", "muzzle_flash", "weapon_tracers_shot", vBulletPosition, ZP_GetWeaponSpeed(gWeapon));
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
        // Call event
        _call.Think(clientIndex, weaponIndex);

        // Button reload press
        if(iButtons & IN_RELOAD)
        {
            // Call event
            _call.Reload(clientIndex, weaponIndex);
            iButtons &= (~IN_RELOAD); //! Bugfix
            return Plugin_Changed;
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

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits, int &weaponIndex)
{
    // Client was damaged by 'bullet'
    if(iBits & DMG_NEVERGIB)
    {
        // Validate weapon
        if(IsValidEdict(weaponIndex))
        {
            // Validate custom weapon
            if(GetEntProp(weaponIndex, Prop_Data, "m_iHammerID") == gWeapon)
            {
                // Add additional damage
                if(GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth")) flDamage *= WEAPON_ACTIVE_MULTIPLIER;
            }
        }
    }
}