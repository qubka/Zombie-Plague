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
public Plugin WeaponAWPBazooka =
{
    name            = "[ZP] Weapon: Bazooka",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_REFERANCE                "Bazooka" // Models and other properties in the 'weapons.ini'
#define WEAPON_SPEED                    1.0   
#define WEAPON_ROCKET_SPEED             2000.0
#define WEAPON_ROCKET_GRAVITY           0.01
#define WEAPON_ROCKET_RADIUS            250000.0 // [squared]
#define WEAPON_ROCKET_DAMAGE            700.0
#define WEAPON_ROCKET_EXPLOSION         0.1
#define WEAPON_ROCKET_SHAKE_AMP         10.0
#define WEAPON_ROCKET_SHAKE_FREQUENCY   1.0
#define WEAPON_ROCKET_SHAKE_DURATION    2.0
#define WEAPON_EFFECT_TIME              5.0
#define WEAPON_EXPLOSION_TIME           2.0
/**
 * @endsection
 **/

/**
 * @section Explosion flags.
 **/
#define EXP_NODAMAGE          1
#define EXP_REPEATABLE        2
#define EXP_NOFIREBALL        4
#define EXP_NOSMOKE           8
#define EXP_NODECAL           16
#define EXP_NOSPARKS          32
#define EXP_NOSOUND           64
#define EXP_RANDOMORIENTATION 128
#define EXP_NOFIREBALLSMOKE   256
#define EXP_NOPARTICLES       512
#define EXP_NODLIGHTS         1024
#define EXP_NOCLAMPMIN        2048
#define EXP_NOCLAMPMAX        4096
/**
 * @endsection
 **/
 
// ConVar for sound level
ConVar hSoundLevel;

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook temp entity
        AddTempEntHook("Shotgun Shot", WeaponFireBullets);
    }
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

/**
 * Event callback (Shotgun Shot)
 * The weapon was been shoted.
 * 
 * @param sTEName       Temp name.
 * @param iPlayers      Array containing target player indexes.
 * @param numClients    Number of players in the array.
 * @param flDelay       Delay in seconds to send the TE.
 **/
public Action WeaponFireBullets(const char[] sTEName, const int[] iPlayers, int numClients, float flDelay)
{
    // Initialize weapon index
    int weaponIndex;

    // Gets all required event info
    int clientIndex = TE_ReadNum("m_iPlayer") + 1;

    // Validate weapon
    if(!IsCustomItem(clientIndex, weaponIndex))
    {
        // Allow broadcast
        return Plugin_Continue;
    }

    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];

    // Gets the weapon's shoot position
    ZP_GetWeaponAttachmentPos(clientIndex, "muzzle_flash", vPosition);

    // Gets the client's eye angle
    GetClientEyeAngles(clientIndex, vAngle);

    // Gets the client's speed
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Emit fire sound
    EmitSoundToAll("*/zombie/bazooka/bazooka_1.mp3", clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    EmitSoundToAll("*/zombie/bazooka/bazooka_1.mp3", clientIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

    // Sets speed of shooting
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", GetGameTime() + WEAPON_SPEED);
    
    // Create a rocket entity
    int entityIndex = CreateEntityByName("hegrenade_projectile");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Spawn the entity
        DispatchSpawn(entityIndex);

        // Returns vectors in the direction of an angle
        GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vEntVelocity, vEntVelocity);

        // Apply the magnitude by scaling the vector
        ScaleVector(vEntVelocity, WEAPON_ROCKET_SPEED);

        // Adds two vectors
        AddVectors(vEntVelocity, vVelocity, vEntVelocity);

        // Push the rocket
        TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);

        // Sets the model
        SetEntityModel(entityIndex, "models/player/custom_player/zombie/bazooka/bazooka_w_projectile.mdl");

        // Create an effect
        FakeCreateParticle(entityIndex, _, "smoking", WEAPON_EFFECT_TIME);

        // Sets the parent for the entity
        SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
        SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
        SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);

        // Sets the gravity
        SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", WEAPON_ROCKET_GRAVITY); 
        
        // Emit sound
        EmitSoundToAll("*/zombie/bazooka/ignite_trail.mp3", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

        // Create touch hook
        SDKHook(entityIndex, SDKHook_Touch, RocketTouchHook);
    }

    // Block broadcast
    return Plugin_Stop;
}

/**
 * Rocket touch hook.
 * 
 * @param entityIndex    The entity index.        
 * @param targetIndex    The target index.               
 **/
public Action RocketTouchHook(int entityIndex, int targetIndex)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Validate target
        if(IsValidEdict(targetIndex))
        {
            // Gets the thrower index
            int throwerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hThrower");

            // Validate thrower
            if(throwerIndex == targetIndex)
            {
                // Return on the unsuccess
                return Plugin_Continue;
            }

            // Initialize vectors
            static float vEntPosition[3]; static float vVictimPosition[3];

            // Gets the entity's position
            GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

            // Create a info_target entity
            int infoIndex = FakeCreateEntity(vEntPosition, WEAPON_EXPLOSION_TIME);
            
            // Validate entity
            if(IsValidEdict(infoIndex))
            {
                // Create an explosion effect
                FakeCreateParticle(infoIndex, _, "expl_coopmission_skyboom", WEAPON_EXPLOSION_TIME);
                
                // Emit sound
                EmitSoundToAll("*/zombie/bazooka/rocket_explode.mp3", infoIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }

            // Validate owner
            if(IsPlayerExist(throwerIndex))
            {
                // i = client index
                for(int i = 1; i <= MaxClients; i++)
                {
                    // Validate client
                    if(IsPlayerExist(i) && ZP_IsPlayerZombie(i))
                    {
                        // Gets victim's origin
                        GetClientAbsOrigin(i, vVictimPosition);

                        // Calculate the distance
                        float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                        // Validate distance
                        if(flDistance <= WEAPON_ROCKET_RADIUS)
                        {
                            // Create the damage for a victim
                            SDKHooks_TakeDamage(i, throwerIndex, throwerIndex, WEAPON_ROCKET_DAMAGE);

                            // Create a shake
                            FakeCreateShakeScreen(i, WEAPON_ROCKET_SHAKE_AMP, WEAPON_ROCKET_SHAKE_FREQUENCY, WEAPON_ROCKET_SHAKE_DURATION);
                        }
                    }
                }
            }

            // Remove the entity from the world
            AcceptEntityInput(entityIndex, "Kill");
        }
    }

    // Return on the success
    return Plugin_Continue;
}

//**********************************************
//* VALIDATIONS                                *
//**********************************************

/**
 * Validate custom weapon and player.
 * 
 * @param clientIndex       The client index. 
 * @param weaponIndex       The weapon index.
 * @return                  True if valid, false if not.
 **/
stock bool IsCustomItem(int clientIndex, int &weaponIndex)
{
    // Validate client
    if (!IsPlayerExist(clientIndex))
    {
        return false;
    }

    // Gets weapon index
    weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");

    // Verify that the weapon is valid
    if(!IsValidEdict(weaponIndex))
    {
        return false;
    }

    // Gets custom weapon id
    static int iD;
    if(!iD) iD = ZP_GetWeaponNameID(WEAPON_REFERANCE);
    
    // If weapon id isn't equal, then stop
    if(ZP_GetWeaponID(weaponIndex) != iD)
    {
        return false;
    }

    // Return on unsuccess
    return true;
}