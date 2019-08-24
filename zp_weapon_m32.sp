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
    name            = "[ZP] Weapon: M32",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_GRENADE_SPEED            1500.0
#define WEAPON_GRENADE_DAMAGE           100.0
#define WEAPON_GRENADE_GRAVITY          1.5
#define WEAPON_GRENADE_RADIUS           300.0
#define WEAPON_EXPLOSION_TIME           2.0
#define WEAPON_EFFECT_TIME              5.0
#define WEAPON_IDLE_TIME                2.0
#define WEAPON_ATTACK_TIME              1.0
#define WEAPON_INSERT_TIME              0.86
#define WEAPON_INSERT_START_TIME        0.7
#define WEAPON_INSERT_END_TIME          0.73
/**
 * @endsection
 **/

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_START_INSERT,
    ANIM_DRAW,
    ANIM_INSERT1,
    ANIM_INSERT2,
    ANIM_FINISH_INSERT
};

// Reload states
enum
{
    RELOAD_START,
    RELOAD_INSERT,
    RELOAD_END
};

// Item index
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
    gWeapon = ZP_GetWeaponNameID("m32");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"m32\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("M32_SHOOT_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"M32_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Effects
    PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnThink(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);
    /// HACK~HACK apply on each frame for shotguns
    
    // Validate clip/ammo
    if (iClip == ZP_GetWeaponClip(gWeapon) || iAmmo <= 0)
    {
        // Validate mode
        if (iReloadMode == RELOAD_END)
        {
            Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
            return;
        }
    }

    // Switch mode
    switch (iReloadMode)
    {
        case RELOAD_INSERT :
        {        
            // Validate animation delay
            if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
            {
                return;
            }

            // Sets reload animation
            ZP_SetWeaponAnimationPair(client, weapon, { ANIM_INSERT1, ANIM_INSERT2 });
            ZP_SetPlayerAnimation(client, AnimType_ReloadLoop);
            
            // Adds the delay to the game tick
            flCurrentTime += WEAPON_INSERT_TIME;
            
            // Sets next attack time
            SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

            // Sets new reload state
            SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_END);
        }
        
        case RELOAD_END :
        {
            // Sets ammunition
            SetEntProp(weapon, Prop_Send, "m_iClip1", iClip + 1);
            SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - 1);
            
            // Sets new reload state
            SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
        }
    }
}

void Weapon_OnIdle(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate mode
    if (iReloadMode == RELOAD_START)
    {
        // Validate clip
        if (iClip <= 0)
        {
            // Validate ammo
            if (iAmmo)
            {
                Weapon_OnReload(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
                return; /// Execute fake reload
            }
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

void Weapon_OnReload(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate ammo
    if (iAmmo <= 0)
    {
        return;
    }
    
    // Validate clip
    if (iClip >= ZP_GetWeaponClip(gWeapon))
    {
        return;
    }
    
    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate mode
    if (iReloadMode == RELOAD_START)
    {
        // Sets start reload animation
        ZP_SetWeaponAnimation(client, ANIM_START_INSERT); 
        ZP_SetPlayerAnimation(client, AnimType_ReloadStart);
        
        // Adds the delay to the game tick
        flCurrentTime += WEAPON_INSERT_START_TIME;
        
        // Sets next attack time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

        // Sets new reload state
        SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
        
        // Sets default FOV for the client
        SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
    }
}

void Weapon_OnReloadFinish(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime

    // Sets end animation
    ZP_SetWeaponAnimation(client, ANIM_FINISH_INSERT);        
    ZP_SetPlayerAnimation(client, AnimType_ReloadEnd);
    
    // Adds the delay to the game tick
    flCurrentTime += WEAPON_INSERT_END_TIME;
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);

    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
    
    // Stop reload
    SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
}

void Weapon_OnDeploy(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime

    // Sets draw animation
    ZP_SetWeaponAnimation(client, ANIM_DRAW); 
    
    // Cancel reload
    SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
    
    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate mode
    if (iReloadMode > RELOAD_START)
    {
        Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
        return;
    }
    
    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate clip
    if (iClip <= 0)
    {
        // Emit empty sound
        ClientCommand(client, "play weapons/clipempty_rifle.wav");
        SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
        return;
    }
    
    // Validate water
    if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }

    // Substract ammo
    iClip -= 1; SetEntProp(weapon, Prop_Send, "m_iClip1", iClip); 

    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_ATTACK_TIME);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));    

    // Sets shots count
    SetEntProp(client, Prop_Send, "m_iShotsFired", GetEntProp(client, Prop_Send, "m_iShotsFired") + 1);
    
    // Play sound
    ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(client, weapon, { ANIM_SHOOT1, ANIM_SHOOT2 });
    ZP_SetPlayerAnimation(client, AnimType_FirePrimary);
    
    // Create a grenade
    Weapon_OnCreateGrenade(client);

    // Initialize variables
    static float vVelocity[3]; int iFlags = GetEntityFlags(client);

    // Gets client velocity
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if (GetVectorLength(vVelocity) <= 0.0)
    {
        ZP_CreateWeaponKickBack(client, 5.5, 2.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if (!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(client, 7.0, 5.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if (iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(client, 5.5, 1.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        ZP_CreateWeaponKickBack(client, 5.75, 5.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }

    // Gets weapon muzzleflesh
    static char sMuzzle[NORMAL_LINE_LENGTH];
    ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

    // Creates a muzzle
    UTIL_CreateParticle(ZP_GetClientViewModel(client, true), _, _, "1", sMuzzle, 0.1);
}

void Weapon_OnSecondaryAttack(int client, int weapon, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate mode
    if (iReloadMode > RELOAD_START)
    {
        Weapon_OnReloadFinish(client, weapon, iClip, iAmmo, iReloadMode, flCurrentTime);
        return;
    }
    
    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.3);
    
    // Sets FOV for the client
    int iDefaultFOV = GetEntProp(client, Prop_Send, "m_iDefaultFOV");
    SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iFOV") == iDefaultFOV ? 55 : iDefaultFOV);
}

void Weapon_OnCreateGrenade(int client)
{
    #pragma unused client

    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vSpeed[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(client, 30.0, 10.0, 0.0, vPosition);

    // Gets client eye angle
    GetClientEyeAngles(client, vAngle);

    // Gets client velocity
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);

    // Create a rocket entity
    int entity = UTIL_CreateProjectile(vPosition, vAngle, "models/weapons/cso/m32/w_m32_projectile.mdl");

    // Validate entity
    if (entity != -1)
    {
        // Returns vectors in the direction of an angle
        GetAngleVectors(vAngle, vSpeed, NULL_VECTOR, NULL_VECTOR);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vSpeed, vSpeed);

        // Apply the magnitude by scaling the vector
        ScaleVector(vSpeed, WEAPON_GRENADE_SPEED);

        // Adds two vectors
        AddVectors(vSpeed, vVelocity, vSpeed);

        // Push the rocket
        TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vSpeed);

        // Create an effect
        UTIL_CreateParticle(entity, vPosition, _, _, "critical_rocket_red", WEAPON_EFFECT_TIME);

        // Sets parent for the entity
        SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
        SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
        SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

        // Sets gravity
        SetEntPropFloat(entity, Prop_Data, "m_flGravity", WEAPON_GRENADE_GRAVITY); 

        // Create touch hook
        SDKHook(entity, SDKHook_Touch, GrenadeTouchHook);
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
        GetEntProp(%2, Prop_Data, "m_iReloadHudHintCount"), \
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
        SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
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
        // Call event
        _call.Think(client, weapon);

        // Button reload press
        if (iButtons & IN_RELOAD)
        {
            // Call event
            _call.Reload(client, weapon);
            iButtons &= (~IN_RELOAD); //! Bugfix
            return Plugin_Changed;
        }
        
        // Button primary attack press
        if (iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(client, weapon);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }
        
        // Button secondary attack press
        if (iButtons & IN_ATTACK2)
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

//**********************************************
//* Item (grenade) hooks.                       *
//**********************************************

/**
 * @brief Grenade touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action GrenadeTouchHook(int entity, int target)
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
        UTIL_CreateExplosion(vPosition, /*EXP_NOFIREBALL | */EXP_NOSOUND, _, WEAPON_GRENADE_DAMAGE, WEAPON_GRENADE_RADIUS, "m32", thrower, entity);

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