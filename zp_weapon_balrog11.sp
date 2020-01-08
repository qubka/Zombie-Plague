/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
    name            = "[ZP] Weapon: Balrog XI",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_FIRE_DAMAGE      200.0
#define WEAPON_FIRE_RADIUS      50.0
#define WEAPON_FIRE_SPEED       1000.0
#define WEAPON_FIRE_GRAVITY     0.01
#define WEAPON_FIRE_COUNTER     4
#define WEAPON_FIRE_LIFE        0.5
#define WEAPON_FIRE_TIME        2.0
#define WEAPON_ATTACK_TIME      1.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT,
    ANIM_START_RELOAD,
    ANIM_INSERT,
    ANIM_AFTER_RELOAD,
    ANIM_DRAW,
    ANIM_SHOOT_BSC1,
    ANIM_SHOOT_BSC2
};

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

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
    gWeapon = ZP_GetWeaponNameID("balrog11");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"balrog11\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("BALROGXI2_SHOOT_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALROGXI2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, int iCounter, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iCounter, iAmmo, flCurrentTime
    
    // Sets draw animation
    ZP_SetWeaponAnimation(client, ANIM_DRAW); 
    
    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnShoot(int client, int weapon, int iCounter, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iCounter, iAmmo, flCurrentTime
    
    // Validate ammo
    if (!GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount"))
    {
        return;
    }
    
    // Validate counter
    if (iCounter > WEAPON_FIRE_COUNTER)
    {
        // Validate clip
        if (iAmmo < ZP_GetWeaponClip(gWeapon))
        {
            // Sets clip count
            SetEntProp(weapon, Prop_Data, "m_iMaxHealth", iAmmo + 1);
         
            // Play sound
            ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            
            // Sets shots counter
            iCounter = -1;
        }
    }

    // Sets shots count
    SetEntProp(weapon, Prop_Data, "m_iHealth", iCounter + 1);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iCounter, int iAmmo, float flCurrentTime)
{
    #pragma unused client, weapon, iCounter, iAmmo, flCurrentTime

    // Validate reload
    int iAnim = ZP_GetWeaponAnimation(client);
    if (iAnim == ANIM_START_RELOAD || iAnim == ANIM_INSERT)
    {
        return;
    }
    
    // Validate ammo
    if (iAmmo <= 0)
    {
        return;
    }

    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
    {
        return;
    }
    
    // Validate water
    if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }

    // Sets next idle time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);

    // Substract ammo
    iAmmo -= 1; SetEntProp(weapon, Prop_Data, "m_iMaxHealth", iAmmo); 
    
    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
 
    // Play sound
    ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT_BSC1, ANIM_SHOOT_BSC2 });
    
    // Initialize vectors
    static float vPosition[5][3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 50.0, 60.0, -10.0, vPosition[0]);
    ZP_GetPlayerGunPosition(client, 50.0, 30.0, -10.0, vPosition[1]);
    ZP_GetPlayerGunPosition(client, 50.0, 0.0, -10.0, vPosition[2]);
    ZP_GetPlayerGunPosition(client, 50.0, -30.0, -10.0, vPosition[3]);
    ZP_GetPlayerGunPosition(client, 50.0, -60.0, -10.0, vPosition[4]);

    // i - fire index
    for (int i = 0; i < 5; i++)
    {
        // Create a fire
        Weapon_OnCreateFire(client, weapon, vPosition[i]);
    }

    // Initialize variables
    static float vVelocity[3]; int iFlags = GetEntityFlags(client);

    // Gets client velocity
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if (GetVectorLength(vVelocity) <= 0.0)
    {
        ZP_CreateWeaponKickBack(client, 10.5, 7.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if (!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(client, 14.0, 10.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if (iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(client, 10.5, 6.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        ZP_CreateWeaponKickBack(client, 10.75, 10.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }
    
    // Initialize name char
    static char sName[NORMAL_LINE_LENGTH];
    
    // Gets viewmodel index
    int view = ZP_GetClientViewModel(client, true);
    
    // Create a muzzle
    ZP_GetWeaponModelMuzzle(gWeapon, sName, sizeof(sName));
    UTIL_CreateParticle(view, _, _, "1", sName, 0.1);
    
    // Create a shell
    ZP_GetWeaponModelShell(gWeapon, sName, sizeof(sName));
    UTIL_CreateParticle(view, _, _, "2", sName, 0.1);
}

void Weapon_OnCreateFire(int client, int weapon, float vPosition[3])
{
    #pragma unused client, weapon, vPosition

    // Initialize vectors
    static float vAngle[3]; static float vVelocity[3]; static float vSpeed[3];

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
        
        // Create an effect
        UTIL_CreateParticle(entity, vPosition, _, _, "flaregun_trail_crit_red", WEAPON_FIRE_LIFE);
        
        // Kill after some duration
        UTIL_RemoveEntity(entity, WEAPON_FIRE_LIFE);
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
        GetEntProp(%2, Prop_Data, "m_iHealth"), \
                                \
        GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
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
    if (weaponID == gWeapon)
    {
        // Resets variables
        SetEntProp(weapon, Prop_Data, "m_iMaxHealth", 0);
        SetEntProp(weapon, Prop_Data, "m_iHealth", 0);
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
        // Button secondary attack press
        if (!(iButtons & IN_ATTACK) && iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(client, weapon);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Called on shoot of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponShoot(int client, int weapon, int weaponID)
{
    // Validate custom weapon
    if (weaponID == gWeapon)
    {
        // Call event
        _call.Shoot(client, weapon);
    }
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
        
        // Create an explosion
        UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, WEAPON_FIRE_DAMAGE, WEAPON_FIRE_RADIUS, "balrog11", thrower, entity);

        // Create an explosion effect
        UTIL_CreateParticle(_, vPosition, _, _, "projectile_fireball_crit_red", WEAPON_FIRE_TIME);
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
        // Remove the entity from the world
        AcceptEntityInput(entity, "Kill");
    }

    // Return on the success
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