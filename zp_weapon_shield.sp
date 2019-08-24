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
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Weapon: Shield",
    author          = "qubka (Nikita Ushakov), Rachnus",     
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the item.
 **/
#define SHIELD_DEFLECT_FORCE          600.0   // Amount of force to deflect nades
#define SHIELD_MAX_DEFLECT_DISTANCE   100.0   // The max amount of distance between the grenade and the player for a deflect
#define SHIELD_DOT_PRODUCT            0.70    // Dot between player forward angle and angle from player eyes to grenade position (The higher value, the preciser your aim has to be)
#define SHIELD_DETONATION_TIME        2.0     // Amount of time which will be add to the detonation timer
/**
 * @endsection
 **/

// Item index
int gWeapon; 
#pragma unused gWeapon

// Offset index
int gDamageOffset; int gDetonateOffset; //ConVar hHealthMax;
#pragma unused gDamageOffset, gDetonateOffset//, hHealthMax

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if (!strcmp(sLibrary, "zombieplague", false))
    {
        // Load custom offsets
        gDamageOffset = FindSendPropInfo("CWeaponShield", "m_iBurstShotsRemaining") + 16;
        gDetonateOffset = FindSendPropInfo("CBaseCSGrenadeProjectile", "m_hThrower") + 36;

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
    gWeapon = ZP_GetWeaponNameID("shield");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"shield\" wasn't find");
    
    // Cvars
    //hHealthMax = FindConVar("sv_shield_hitpoints");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Sounds
    PrecacheSound("physics/metal/metal_barrel_impact_soft2.wav", true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnFire(int client, int weapon, float flCurrentTime)
{
    #pragma unused client, weapon
    
    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vCenter[3]; 
    static float vEntPosition[3]; static float vEntAngle[3]; static float vEntVelocity[3]; bool bDeflect;

    // Gets client eye position
    GetClientEyeAngles(client, vPosition);
    
    // Gets client eye angle
    GetClientEyeAngles(client, vAngle);

    // Gets client velocity
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
    
    // Gets client center
    GetClientMaxs(client, vCenter);
    vCenter[0] = vPosition[0];
    vCenter[1] = vPosition[1];
    vCenter[2] = vPosition[2] + (vCenter[2] / 2.0);

    // Returns vectors in the direction of an angle
    GetAngleVectors(vAngle, vAngle, NULL_VECTOR, NULL_VECTOR);

    // Normalize the vector (equal magnitude at varying distances)
    NormalizeVector(vAngle, vAngle); vEntVelocity = vAngle;

    // Apply the magnitude by scaling the vector
    ScaleVector(vEntVelocity, SHIELD_DEFLECT_FORCE);

    // Adds two vectors
    AddVectors(vVelocity, vEntVelocity, vEntVelocity);

    // i = entity index
    int MaxEntities = GetMaxEntities();
    for (int i = MaxClients; i <= MaxEntities; i++)
    {
        // Validate projectile
        if (IsEntityProjectile(i))
        {
            // Gets grenade position
            GetEntPropVector(i, Prop_Data, "m_vecOrigin", vEntPosition);

            // Validate distance
            if (GetVectorDistance(vCenter, vEntPosition) > SHIELD_MAX_DEFLECT_DISTANCE)
            {
                continue;
            }
            
            // Gets vector from the given starting and ending points
            MakeVectorFromPoints(vPosition, vEntPosition, vEntAngle);
            
            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vEntAngle, vEntAngle);

            // Gets dot angle
            float flAngle = GetVectorDotProduct(vEntAngle, vAngle);
            
            // Validate PVS
            if (flAngle > SHIELD_DOT_PRODUCT)
            {
                // Adds the given vector to the client current velocity
                TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vEntVelocity);

                // Resets detonation timer
                SetEntDataFloat(i, gDetonateOffset, flCurrentTime + SHIELD_DETONATION_TIME, true);
                
                // Sets for sound
                bDeflect = true;
            }
        }
    }
    
    // Emit deflect sound
    if (bDeflect) EmitAmbientSound("physics/metal/metal_barrel_impact_soft2.wav", vPosition);
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
        GetGameTime()           \
    )    

/**
 * @brief Called on fire of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 *
 * @noreturn
 **/
public void ZP_OnWeaponFire(int client, int weapon, int weaponID)
{
    // Validate custom weapon
    if (weaponID == gWeapon)
    {
        // Call event
        _call.Fire(client, weapon);
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
        // Resets damage
        SetEntDataFloat(weapon, gDamageOffset, 0.0, true);
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Returns true if the entity is a projectile, false if not.
 *
 * @param entity            The entity index.
 * @return                  True or false.    
 **/
bool IsEntityProjectile(int entity)
{
    // Validate entity
    if (entity <= MaxClients || !IsValidEdict(entity))
    {
        return false;
    }
    
    // Gets entity classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEdictClassname(entity, sClassname, sizeof(sClassname));

    // Gets string length
    int iLen = strlen(sClassname) - 11;
    
    // Validate length
    if (iLen > 0)
    {
        // Validate grenade
        return (!strncmp(sClassname[iLen], "_proj", 5, false));
    }
    
    // Return on unsuccess
    return false;
}