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
    name            = "[ZP] Weapon: Balrog I",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_TIME_DELAY_SWITCH         2.0
#define WEAPON_EXPLOSION_DAMAGE          300.0
#define WEAPON_EXPLOSION_RADIUS          150.0
#define WEAPON_EXPLOSION_KNOCKBACK       500.0
#define WEAPON_EXPLOSION_SHAKE_AMP       10.0
#define WEAPON_EXPLOSION_SHAKE_FREQUENCY 1.0
#define WEAPON_EXPLOSION_SHAKE_DURATION  2.0
#define WEAPON_EXPLOSION_TIME            2.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_DRAW,
    ANIM_RELOAD,
    ANIM_CHANGE,
    ANIM_CHANGE2,
    ANIM_IDLE2,
    ANIM_SHOOT2_1,
    ANIM_SHOOT2_2,
    ANIM_RELOAD2
};

// Weapon states
enum
{
    STATE_NORMAL,
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
    gWeapon = ZP_GetWeaponNameID("balrog1");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"balrog1\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BALROGI2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALROGI2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
}

void Weapon_OnShoot(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode)
    {
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1); 
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
}

void Weapon_OnFire(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime
    
    // Validate ammo
    if(iClip <= 0)
    {
        return;
    }
    
    // Validate mode
    if(!iStateMode)
    {
        return;
    }
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);

    // Sets next attack time
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
}

void Weapon_OnSecondaryAttack(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iStateMode, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer") > flCurrentTime)
    {
        return;
    }

    // Sets change animation
    ZP_SetWeaponAnimation(clientIndex, iStateMode ? ANIM_CHANGE2 : ANIM_CHANGE);        

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_SWITCH;

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets switching time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
}

void Weapon_OnBullet(const int clientIndex, const int weaponIndex, const int iStateMode, float vBulletPosition[3])
{
    #pragma unused clientIndex, weaponIndex, iStateMode, vBulletPosition

    // Validate mode
    if(!iStateMode)
    {
        return;
    }
    
    // Initialize vectors
    static float vVictimPosition[3]; static float vVelocity[3];

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if((IsPlayerExist(i) && ZP_IsPlayerZombie(i)))
        {
            // Gets victim origin
            GetClientAbsOrigin(i, vVictimPosition);

            // Calculate the distance
            float flDistance = GetVectorDistance(vBulletPosition, vVictimPosition);

            // Validate distance
            if(flDistance <= WEAPON_EXPLOSION_RADIUS)
            {
                // Create the damage for a victim
                ZP_TakeDamage(i, clientIndex, WEAPON_EXPLOSION_DAMAGE * (1.0 - (flDistance / WEAPON_EXPLOSION_RADIUS)), DMG_AIRBOAT);

                // Calculate the velocity vector
                SubtractVectors(vVictimPosition, vBulletPosition, vVelocity);
        
                // Create a knockback
                ZP_CreateRadiusKnockBack(i, vVelocity, flDistance, WEAPON_EXPLOSION_KNOCKBACK, WEAPON_EXPLOSION_RADIUS);
                
                // Create a shake
                ZP_CreateShakeScreen(i, WEAPON_EXPLOSION_SHAKE_AMP, WEAPON_EXPLOSION_SHAKE_FREQUENCY, WEAPON_EXPLOSION_SHAKE_DURATION);
            }
        }
    }
    
    // Create a info_target entity
    int infoIndex = ZP_CreateEntity(vBulletPosition, WEAPON_EXPLOSION_TIME);

    // Validate entity
    if(IsValidEdict(infoIndex))
    {
        // Create an explosion effect
        ZP_CreateParticle(infoIndex, vBulletPosition, _, "explosion_hegrenade_interior", WEAPON_EXPLOSION_TIME);
        
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
        EmitSoundToAll(sSound, infoIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
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
        GetGameTime()           \
    )    
    
#define _call2.%0(%1,%2,%3)     \
                                \
    Weapon_On%0                 \
    (                           \
        %1,                     \
        %2,                     \
                                \
        GetEntProp(%2, Prop_Send, "m_iClip2"), \
                                \
        %3                      \
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
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_NORMAL);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
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
 * @brief Called on fire of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponFire(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Fire(clientIndex, weaponIndex);
    }
}

/**
 * @brief Called on shoot of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponShoot(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Shoot(clientIndex, weaponIndex);
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
        // Call event
        _call2.Bullet(clientIndex, weaponIndex, vBulletPosition);
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
        if((flApplyModeTime = GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer")) != 0.0 && flApplyModeTime <= GetGameTime())
        {
            // Resets the switching time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets different mode
            SetEntProp(weaponIndex, Prop_Send, "m_iClip2", !GetEntProp(weaponIndex, Prop_Send, "m_iClip2"));
        }
        else
        {
            // Validate state
            if(GetEntProp(weaponIndex, Prop_Send, "m_iClip2"))
            {
                // Switch animation
                switch(ZP_GetWeaponAnimation(clientIndex))
                {
                    case ANIM_IDLE :    ZP_SetWeaponAnimation(clientIndex, ANIM_IDLE2);
                    case ANIM_SHOOT1, ANIM_SHOOT2 :  { ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2 } ); SetEntProp(weaponIndex, Prop_Send, "m_iClip2", STATE_NORMAL); } 
                    case ANIM_RELOAD :  ZP_SetWeaponAnimation(clientIndex, ANIM_RELOAD2); 
                }
            }
        }

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