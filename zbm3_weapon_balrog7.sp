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
    name            = "[ZP] Weapon: Balrog VII",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_ITEM_REFERENCE            "balrog7" // Name in weapons.ini from translation file
#define WEAPON_EXPLOSION_RATIO           6
#define WEAPON_EXPLOSION_DAMAGE          300.0
#define WEAPON_EXPLOSION_RADIUS          150.0
#define WEAPON_EXPLOSION_KNOCKBACK       500.0
#define WEAPON_EXPLOSION_SHAKE_AMP       10.0
#define WEAPON_EXPLOSION_SHAKE_FREQUENCY 1.0
#define WEAPON_EXPLOSION_SHAKE_DURATION  2.0
#define WEAPON_EXPLOSION_TIME            5.0
/**
 * @endsection
 **/

// Weapon index
int gWeapon;

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_ITEM_REFERENCE);
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BALROGVII2_SHOOT_SOUNDS");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnBullet(const int clientIndex, const int weaponIndex, int iCounter, const float vBulletPosition[3])
{
    #pragma unused clientIndex, weaponIndex, iCounter, vBulletPosition

    // Validate counter
    if(iCounter > (ZP_GetWeaponClip(gWeapon) / WEAPON_EXPLOSION_RATIO))
    {
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
                    FakeCreateKnockBack(i, vVelocity, flDistance, WEAPON_EXPLOSION_KNOCKBACK, WEAPON_EXPLOSION_RADIUS);
                    
                    // Create a shake
                    FakeCreateShakeScreen(i, WEAPON_EXPLOSION_SHAKE_AMP, WEAPON_EXPLOSION_SHAKE_FREQUENCY, WEAPON_EXPLOSION_SHAKE_DURATION);
                }
            }
        }
        
        // Create a info_target entity
        int infoIndex = FakeCreateEntity(vBulletPosition, WEAPON_EXPLOSION_TIME);

        // Validate entity
        if(IsValidEdict(infoIndex))
        {
            // Create an explosion effect
            FakeCreateParticle(infoIndex, vBulletPosition, _, "expl_coopmission_skyboom", WEAPON_EXPLOSION_TIME);
            
            // Emit sound
            static char sSound[PLATFORM_MAX_PATH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
            EmitSoundToAll(sSound, infoIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        }
        
        // Resets the shots count
        iCounter = -1;
    }
    
    // Sets the shots count
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", iCounter + 1);
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2,%3)      \
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
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);
    }
}    
    
/**
 * Called on bullet of a weapon.
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
        _call.Bullet(clientIndex, weaponIndex, vBulletPosition);
    }
}