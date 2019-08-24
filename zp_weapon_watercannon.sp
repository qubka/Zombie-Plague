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
    name            = "[ZP] Weapon: Watercannon",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_FIRE_DAMAGE          50.0
#define WEAPON_FIRE_RADIUS          30.0
#define WEAPON_FIRE_SPEED           1000.0
#define WEAPON_FIRE_GRAVITY         0.01
#define WEAPON_FIRE_LIFE            0.8
#define WEAPON_IGNITE_TIME          1.0
#define WEAPON_IDLE_TIME            1.66
#define WEAPON_ATTACK_START_TIME    0.2
#define WEAPON_ATTACK_END_TIME      0.7
/**
 * @endsection
 **/

// Item index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_ATTACK_LOOP1,
    ANIM_ATTACK_LOOP2,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_ATTACK_START,
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
    if (!strcmp(sLibrary, "zombieplague", false))
    {
        // If map loaded, then run custom forward
        if (ZP_IsMapLoaded())
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
    gWeapon = ZP_GetWeaponNameID("watercannon");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"watercannon\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("WATERCANNON_SHOOT_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"WATERCANNON_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Kill an effect
    Weapon_OnCreateEffect(weapon, "Kill");
    
    // Cancel reload
    SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate clip
    if (iClip <= 0)
    {
        // Validate ammo
        if (iAmmo)
        {
            Weapon_OnReload(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
            return; /// Execute fake reload
        }
    }
    
    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Sets idle animation
    ZP_SetWeaponAnimation(client, ANIM_IDLE); 
    
    // Sets next idle time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate clip
    if (min(ZP_GetWeaponClip(gWeapon) - iClip, iAmmo) <= 0)
    {
        return;
    }
    
    // Validate mode
    if (iStateMode > STATE_BEGIN)
    {
        Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }
    
    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
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
 
    // Sets draw animation
    ZP_SetWeaponAnimation(client, ANIM_DRAW); 
    
    // Sets attack state
    SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);
    
    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", 0);

    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
    
    // Create an effect
    Weapon_OnCreateEffect(weapon);
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate clip
    if (iClip <= 0)
    {
        // Validate mode
        if (iStateMode > STATE_BEGIN)
        {
            Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        }
        return;
    }

    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
        return;
    }

    // Switch mode
    switch (iStateMode)
    {
        case STATE_BEGIN :
        {
            // Sets begin animation
            ZP_SetWeaponAnimation(client, ANIM_ATTACK_START);        

            // Sets attack state
            SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_ATTACK);

            // Adds the delay to the game tick
            flCurrentTime += WEAPON_ATTACK_START_TIME;
            
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
            iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); if (!iClip)
            {
                Weapon_OnEndAttack(client, weapon, iClip, iAmmo, iStateMode, flCurrentTime);
                return;
            }

            // Play sound
            ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);

            // Adds the delay to the game tick
            flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
            
            // Sets next attack time
            SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);         

            // Sets shots count
            SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
            
            // Create a fire
            Weapon_OnCreateFire(client, weapon);

            // Initialize variables
            static float vVelocity[3]; int iFlags = GetEntityFlags(client);

            // Gets client velocity
            GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

            // Apply kick back
            if (GetVectorLength(vVelocity) <= 0.0)
            {
                ZP_CreateWeaponKickBack(client, 6.5, 5.45, 5.225, 5.05, 6.5, 7.5, 7);
            }
            else if (!(iFlags & FL_ONGROUND))
            {
                ZP_CreateWeaponKickBack(client, 7.0, 5.0, 5.5, 5.35, 14.0, 11.0, 5);
            }
            else if (iFlags & FL_DUCKING)
            {
                ZP_CreateWeaponKickBack(client, 5.9, 5.35, 5.15, 5.025, 10.5, 6.5, 9);
            }
            else
            {
                ZP_CreateWeaponKickBack(client, 5.0, 5.375, 5.175, 5.0375, 10.75, 1.75, 8);
            }
            
            // Start an effect
            Weapon_OnCreateEffect(weapon, "Start");
        }
    }
}

void Weapon_OnCreateFire(int client, int weapon)
{
    #pragma unused client, weapon

    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vSpeed[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 30.0, 10.0, 0.0, vPosition);
    
    // Gets client eye angle
    GetClientEyeAngles(client, vAngle);

    // Gets client velocity
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

    // Create a rocket entity
    int entity = UTIL_CreateProjectile(vPosition, vAngle);

    // Validate entity
    if (entity != -1)
    {
        // Sets grenade model scale
        SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 10.0);
        
        // Returns vectors in the direction of an angle
        GetAngleVectors(vAngle, vSpeed, NULL_VECTOR, NULL_VECTOR);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vSpeed, vSpeed);

        // Apply the magnitude by scaling the vector
        ScaleVector(vSpeed, WEAPON_FIRE_SPEED);

        // Adds two vectors
        AddVectors(vSpeed, vVelocity, vSpeed);

        // Push the fire
        TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vSpeed);
        
        // Sets an entity color
        UTIL_SetRenderColor(entity, Color_Alpha, 0);
        AcceptEntityInput(entity, "DisableShadow"); /// Prevents the entity from receiving shadows
        
        // Sets parent for the entity
        SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
        SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
        SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

        // Sets gravity
        SetEntPropFloat(entity, Prop_Data, "m_flGravity", WEAPON_FIRE_GRAVITY); 

        // Create touch hook
        SDKHook(entity, SDKHook_Touch, FireTouchHook);
        
        // Kill after some duration
        UTIL_RemoveEntity(entity, WEAPON_FIRE_LIFE);
    }
}

void Weapon_OnEndAttack(int client, int weapon, int iClip, int iAmmo, int iStateMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate mode
    if (iStateMode > STATE_BEGIN)
    {
        // Sets end animation
        ZP_SetWeaponAnimation(client, ANIM_ATTACK_END);        

        // Sets begin state
        SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_BEGIN);

        // Adds the delay to the game tick
        flCurrentTime += WEAPON_ATTACK_END_TIME;
        
        // Sets next attack time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
        
        // Stop an effect
        Weapon_OnCreateEffect(weapon, "Stop");
    }
}

void Weapon_OnCreateEffect(int weapon, char[] sInput = "")
{
    #pragma unused weapon, sInput

    // Gets effect index
    int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity");
    
    // Is effect should be created ?
    if (!hasLength(sInput))
    {
        // Validate entity 
        if (entity != -1)
        {
            return;
        }
        
        // Gets worldmodel index
        int world = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
        
        // Validate model 
        if (world != -1)
        {
            // Gets weapon muzzleflesh
            static char sMuzzle[NORMAL_LINE_LENGTH];
            ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

            // Create an attach fire effect
            entity = UTIL_CreateParticle(world, _, _, "muzzle_flash", sMuzzle);
            
            // Validate entity 
            if (entity != -1)
            {
                // Sets effect index
                SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
                
                // Stop an effect
                AcceptEntityInput(entity, "Stop"); 
            }
        }
    }
    else
    {
        // Validate entity 
        if (entity != -1)
        {
            // Toggle state
            AcceptEntityInput(entity, sInput); 
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
    if (weaponID == gWeapon)
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
    if (weaponID == gWeapon)
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
    if (weaponID == gWeapon)
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
    if (weaponID == gWeapon)
    {
        // Time to reload weapon
        static float flReloadTime;
        if ((flReloadTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flReloadTime <= GetGameTime())
        {
            // Call event
            _call.ReloadFinish(client, weapon);
        }
        else
        {
            // Button reload press
            if (iButtons & IN_RELOAD)
            {
                // Call event
                _call.Reload(client, weapon);
                iButtons &= (~IN_RELOAD); //! Bugfix
                return Plugin_Changed;
            }
        }

        // Button primary attack press
        if (iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(client, weapon);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }
        // Button primary attack release
        else if (iLastButtons & IN_ATTACK)
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

//**********************************************
//* Item (fire) hooks.                         *
//**********************************************

/**
 * @brief Fire touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action FireTouchHook(int entity, int target)
{
    // Validate target
    if (IsValidEdict(target))
    {
        // Gets thrower index
        int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
        
        // Validate thrower
        if (thrower == target)
        {
            // Return on the unsuccess
            return Plugin_Continue;
        }
        
        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Create the damage for victims
        UTIL_CreateDamage(_, vPosition, thrower, WEAPON_FIRE_DAMAGE, WEAPON_FIRE_RADIUS, DMG_NEVERGIB, gWeapon);
        
        // Validate zombie
        if (IsPlayerExist(target) && ZP_IsPlayerZombie(target)) 
        {
            // Put the fire on
            UTIL_IgniteEntity(target, WEAPON_IGNITE_TIME);   
        }
        
        // Remove the entity from the world
        AcceptEntityInput(entity, "Kill");
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value if you add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entity            Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFlags            The sound flags.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags)
{
    // Validate client
    if (IsValidEdict(entity))
    {
        
    }
    
    // Allow sounds
    return Plugin_Continue;
}

/**
 * @brief Called before a grenade sound is emitted.
 *
 * @param grenade           The grenade index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow sounds. Anything else
 *                              (like Plugin_Stop) to block sounds.
 **/
public Action ZP_OnGrenadeSound(int grenade, int weaponID)
{
    // Validate custom grenade
    if (weaponID == gWeapon)
    {
        // Block sounds
        return Plugin_Stop; 
    }
    
    // Allow sounds
    return Plugin_Continue;
}