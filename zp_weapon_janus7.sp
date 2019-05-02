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
    name            = "[ZP] Weapon: Janus VII",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_SIGNAL_COUNTER       100
#define WEAPON_ACTIVE_COUNTER       150
#define WEAPON_BULLET_DAMAGE        15.0
#define WEAPON_BULLET_RADIUS        1.0
#define WEAPON_BEAM_DAMAGE          50.0
#define WEAPON_BEAM_DAMAGE_R        10.0 // dmg radius
#define WEAPON_BEAM_RADIUS          500.0
#define WEAPON_BEAM_SHAKE_AMP       10.0
#define WEAPON_BEAM_SHAKE_FREQUENCY 1.0
#define WEAPON_BEAM_SHAKE_DURATION  2.0
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
    ANIM_SHOOT_SIGNAL_1,
    ANIM_CHANGE,
    ANIM_IDLE2,
    ANIM_DRAW2,
    ANIM_SHOOT2_1,
    ANIM_SHOOT2_2,
    ANIM_CHANGE2,
    ANIM_IDLE_SIGNAL,
    ANIM_RELOAD_SIGNAL,
    ANIM_DRAW_SIGNAL,
    ANIM_SHOOT_SIGNAL_2
};

// Weapon states
enum
{
    STATE_NORMAL,
    STATE_SIGNAL,
    STATE_ACTIVE
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
    gWeapon = ZP_GetWeaponNameID("janus7");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"janus7\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("JANUSVII_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSVII_SHOOT_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
    
    // Kill an effect
    Weapon_OnCreateEffect(clientIndex, weaponIndex, "Kill");
    
    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Data, "m_flUseLookAtAngle", 0.0);
    
    // Cancel reload
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);
    
    // Create an effect
    Weapon_OnCreateEffect(clientIndex, weaponIndex);
    
    // Validate mode
    if(iStateMode == STATE_ACTIVE)
    {
        // Start an effect
        Weapon_OnCreateEffect(clientIndex, weaponIndex, "Start");
    }
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnReload(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode == STATE_ACTIVE)
    {
        return;
    }
    
    // Validate clip
    if(min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
    {
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Sets reload animation
    ZP_SetWeaponAnimation(clientIndex, !iStateMode ? ANIM_RELOAD : ANIM_RELOAD_SIGNAL); 
    ZP_SetPlayerAnimation(clientIndex, AnimType_Reload);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponReload(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);

    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets reloading time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
    
    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnReloadFinish(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
    
    // Gets new amount
    int iAmount = min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo);

    // Sets the ammunition
    SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip + iAmount)
    SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - iAmount);

    // Sets the reload time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

    // Validate mode
    if(iStateMode != STATE_ACTIVE)
    {
        // Validate clip
        if(iClip <= 0)
        {
            // Validate ammo
            if(iAmmo)
            {
                Weapon_OnReload(clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime);
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
    int iSequence = (iStateMode == STATE_ACTIVE) ? ANIM_IDLE2 : (iStateMode == STATE_SIGNAL) ? ANIM_IDLE_SIGNAL : ANIM_IDLE;

    // Sets idle animation
    ZP_SetWeaponAnimation(clientIndex, iSequence); 

    // Sets next idle time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, iSequence));
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime

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
            Weapon_OnFinish(clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime);
            return;
        }
        
        // Validate water
        if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
        {
            return;
        }
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 2, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
        
        // Sets attack animation
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2});
        
        // Sets next idle time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_SHOOT2_1));
        
        // Create a beam
        Weapon_OnCreateBeam(clientIndex, weaponIndex);
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
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);    
    
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
        float flSpread = 0.01; float flInaccuracy = 0.015;

        // Gets client velocity
        GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

        // Apply kick back
        if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
        {
            ZP_CreateWeaponKickBack(clientIndex, 3.5, 2.5, 0.15, 0.05, 5.5, 4.5, 7);
        }
        else if(!(iFlags & FL_ONGROUND))
        {
            ZP_CreateWeaponKickBack(clientIndex, 6.0, 4.0, 0.4, 0.15, 7.0, 5.0, 5);
            flInaccuracy = 0.02;
            flSpread = 0.05;
        }
        else if(iFlags & FL_DUCKING)
        {
            ZP_CreateWeaponKickBack(clientIndex, 3.5, 1.5, 0.1, 0.025, 5.5, 6.5, 9);
            flInaccuracy = 0.01;
        }
        else
        {
            ZP_CreateWeaponKickBack(clientIndex, 3.75, 2.8, 0.14, 0.0375, 5.75, 5.75, 8);
        }
        
        // Create a bullet
        Weapon_OnCreateBullet(clientIndex, weaponIndex, 0, GetRandomInt(0, 1000), flSpread, flInaccuracy);
    }
    
    // Sets attack animation
    ZP_SetPlayerAnimation(clientIndex, AnimType_FirePrimary);

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));    

    // Sets shots count
    SetEntProp(weaponIndex, Prop_Data, "m_iHealth", iCounter + 1);
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode == STATE_SIGNAL)
    {
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
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flUseLookAtAngle", flCurrentTime);
        
        // Start an effect
        Weapon_OnCreateEffect(clientIndex, weaponIndex, "Start");
    }
}

void Weapon_OnFinish(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iCounter, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iCounter, iStateMode, flCurrentTime
    
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
    
    // Stop an effect
    Weapon_OnCreateEffect(clientIndex, weaponIndex, "Stop");
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
            ZP_CreateWeaponTracer(clientIndex, weaponIndex, "1", "muzzle_flash", "weapon_tracers_mach", vEndPosition, ZP_GetWeaponSpeed(gWeapon));

            // Create the damage for victims
            UTIL_CreateDamage(_, vEndPosition, clientIndex, WEAPON_BULLET_DAMAGE, WEAPON_BULLET_RADIUS, DMG_NEVERGIB, gWeapon);
        }
    }
}

void Weapon_OnCreateBeam(int clientIndex, int weaponIndex)
{
    #pragma unused clientIndex, weaponIndex
    
    // Initialize variables
    static float vEntPosition[3]; static float vEntAngle[3]; static float vVictimPosition[3]; bool bFound;

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, -10.0, vEntPosition);

    // Find any players in the radius
    int i; int it = 1; /// iterator
    while((i = ZP_FindPlayerInSphere(it, vEntPosition, WEAPON_BEAM_RADIUS)) != INVALID_ENT_REFERENCE)
    {
        // Skip humans
        if(ZP_IsPlayerHuman(i))
        {
            continue;
        }

        // Gets victim center
        GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vVictimPosition); vVictimPosition[2] += 45.0;

        // Validate visibility
        if(!UTIL_TraceRay(clientIndex, i, vEntPosition, vVictimPosition))
        {
            continue;
        }

        // Create the damage for victims
        UTIL_CreateDamage(_, vVictimPosition, clientIndex, WEAPON_BEAM_DAMAGE, WEAPON_BEAM_DAMAGE_R, DMG_NEVERGIB, gWeapon);
        
        // Create a shake
        UTIL_CreateShakeScreen(i, WEAPON_BEAM_SHAKE_AMP, WEAPON_BEAM_SHAKE_FREQUENCY, WEAPON_BEAM_SHAKE_DURATION);
        
        // Sets found state
        bFound = true; 
        break;
    }
    
    // Found the aim origin
    if(!bFound)
    {
        // Gets client eye angle
        GetClientEyeAngles(clientIndex, vEntAngle);

        // Calculate aim end-vector
        TR_TraceRayFilter(vEntPosition, vEntAngle, (MASK_SHOT|CONTENTS_GRATE), RayType_Infinite, filter, clientIndex);
        TR_GetEndPosition(vVictimPosition);
    }

    // Sent a beam
    ZP_CreateWeaponTracer(clientIndex, weaponIndex, "1", "muzzle_flash", "medicgun_beam_red_invun", vVictimPosition, ZP_GetWeaponSpeed(gWeapon));
}

void Weapon_OnCreateEffect(int clientIndex, int weaponIndex, char[] sInput = "")
{
    #pragma unused clientIndex, weaponIndex, sInput

    // Gets the effect index
    int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity");
    
    // Is effect should be created ?
    if(!hasLength(sInput))
    {
        // Validate entity 
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            return;
        }

        // Creates a muzzle
        entityIndex = UTIL_CreateParticle(ZP_GetClientViewModel(clientIndex, true), _, _, "1", "medicgun_invulnstatus_fullcharge_red", 9999.9);
            
        // Validate entity 
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Sets the effect index
            SetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity", entityIndex);
            
            // Stop an effect
            AcceptEntityInput(entityIndex, "Stop"); 
        }
    }
    else
    {
        // Validate entity 
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Toggle state
            AcceptEntityInput(entityIndex, sInput); 
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
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_NORMAL);
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth", 0);
        SetEntPropFloat(weaponIndex, Prop_Data, "m_flUseLookAtAngle", 0.0);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
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
        ZP_CreateWeaponTracer(clientIndex, weaponIndex, "1", "muzzle_flash", "weapon_tracers_mach", vBulletPosition, ZP_GetWeaponSpeed(gWeapon));
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
        // Time to apply new mode
        static float flApplyModeTime;
        if((flApplyModeTime = GetEntPropFloat(weaponIndex, Prop_Data, "m_flUseLookAtAngle")) && flApplyModeTime <= GetGameTime())
        {
            // Sets the switching time
            SetEntPropFloat(weaponIndex, Prop_Data, "m_flUseLookAtAngle", 0.0);

            // Sets different mode
            SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_ACTIVE);
        }
        
        // Time to reload weapon
        static float flReloadTime;
        if((flReloadTime = GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer")) && flReloadTime <= GetGameTime())
        {
            // Call event
            _call.ReloadFinish(clientIndex, weaponIndex);
        }
        else
        {
            // Button reload press
            if(iButtons & IN_RELOAD)
            {
                // Call event
                _call.Reload(clientIndex, weaponIndex);
                iButtons &= (~IN_RELOAD); //! Bugfix
                return Plugin_Changed;
            }
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