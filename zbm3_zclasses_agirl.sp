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
public Plugin ZombieClassGirl =
{
    name            = "[ZP] Zombie Class: Girl",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "Girl" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "GirlInfo" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/zombie_f/zombie_f.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/zombie_f/hand_v2/hand_zombie_normal_f.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/zombie_f/grenade/grenade_zombie_f.mdl"    
#define ZOMBIE_CLASS_HEALTH             3000
#define ZOMBIE_CLASS_SPEED              1.0
#define ZOMBIE_CLASS_GRAVITY            0.9
#define ZOMBIE_CLASS_KNOCKBACK          1.0
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_VIP                NO
#define ZOMBIE_CLASS_DURATION           2.0   
#define ZOMBIE_CLASS_COUNTDOWN          30.0
#define ZOMBIE_CLASS_REGEN_HEALTH       300
#define ZOMBIE_CLASS_REGEN_INTERVAL     5.0
#define ZOMBIE_CLASS_SKILL_SPEED        3000.0
#define ZOMBIE_CLASS_SKILL_GRAVITY      0.01
#define ZOMBIE_CLASS_SKILL_EXP_RADIUS   22500.0 //[squared]
#define ZOMBIE_CLASS_SKILL_EXP_TIME     2.0
#define ZOMBIE_CLASS_EFFECT_WIDTH       3.0
#define ZOMBIE_CLASS_EFFECT_WIDTH_END   1.0
#define ZOMBIE_CLASS_EFFECT_COLOR       {209, 120, 9, 200}
#define ZOMBIE_CLASS_EFFECT_COLOR_F     {209, 120, 9, 75}
#define ZOMBIE_CLASS_EFFECT_DURATION_F  0.3
#define ZOMBIE_CLASS_EFFECT_TIME_F      1.0
#define ZOMBIE_CLASS_EFFECT_FIRE        10.0
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_FEMALE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_FEMALE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_FEMALE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_FEMALE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_FEMALE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_FEMALE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FEMALE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_FEMALE_REGEN_SOUNDS"
/**
 * @endsection
 **/
 
/**
 * @section Explosion flags.
 **/
#define EXP_NODAMAGE            1
#define EXP_REPEATABLE          2
#define EXP_NOFIREBALL          4
#define EXP_NOSMOKE             8
#define EXP_NODECAL             16
#define EXP_NOSPARKS            32
#define EXP_NOSOUND             64
#define EXP_RANDOMORIENTATION   128
#define EXP_NOFIREBALLSMOKE     256
#define EXP_NOPARTICLES         512
#define EXP_NODLIGHTS           1024
#define EXP_NOCLAMPMIN          2048
#define EXP_NOCLAMPMAX          4096
/**
 * @endsection
 **/

// ConVar for sound level
ConVar hSoundLevel;
 
// Initialize zombie class index
int gZombieGirl;
#pragma unused gZombieGirl

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initilizate zombie class
        gZombieGirl = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
        ZOMBIE_CLASS_INFO,
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW, 
        ZOMBIE_CLASS_GRENADE,
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_VIP, 
        ZOMBIE_CLASS_DURATION, 
        ZOMBIE_CLASS_COUNTDOWN, 
        ZOMBIE_CLASS_REGEN_HEALTH, 
        ZOMBIE_CLASS_REGEN_INTERVAL,
        ZOMBIE_CLASS_SOUND_DEATH,
        ZOMBIE_CLASS_SOUND_HURT,
        ZOMBIE_CLASS_SOUND_IDLE,
        ZOMBIE_CLASS_SOUND_RESPAWN,
        ZOMBIE_CLASS_SOUND_BURN,
        ZOMBIE_CLASS_SOUND_ATTACK,
        ZOMBIE_CLASS_SOUND_FOOTSTEP,
        ZOMBIE_CLASS_SOUND_REGEN);
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
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Handled;
    }
    
    // Validate the zombie class index
    if(ZP_GetClientZombieClass(clientIndex) == gZombieGirl)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];
        
        // Gets the client's eye position
        GetClientEyePosition(clientIndex, vPosition);
        
        // Gets the client's eye angle
        GetClientEyeAngles(clientIndex, vAngle);

        // Gets the client's speed
        GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);
        
        // Emit sound
        EmitSoundToAll("*/zbm3/deimos_skill_start.mp3", clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a bomb entity
        int entityIndex = CreateEntityByName("hegrenade_projectile");
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Spawn the entity
            DispatchSpawn(entityIndex);
            
            // Sets the bomb's model scale
            SetEntPropFloat(entityIndex, Prop_Send, "m_flModelScale", 0.0);
            
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);
            
            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vEntVelocity, vEntVelocity);
            
            // Apply the magnitude by scaling the vector
            ScaleVector(vEntVelocity, ZOMBIE_CLASS_SKILL_SPEED);

            // Adds two vectors
            AddVectors(vEntVelocity, vVelocity, vEntVelocity);

            // Push the bomb
            TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);

            // Sets the parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);

            // Sets the gravity
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY); 

            // Put fire on it
            IgniteEntity(entityIndex, ZOMBIE_CLASS_EFFECT_FIRE);
            
            // Create an effect
            FakeCreateParticle(entityIndex, _, "gamma_trail_xz", 5.0);
    
            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, BombTouchHook);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Bomb touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action BombTouchHook(int entityIndex, int targetIndex)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Validate target
        if(IsValidEdict(targetIndex))
        {
            // Validate thrower
            if(GetEntPropEnt(entityIndex, Prop_Send, "m_hThrower") == targetIndex)
            {
                // Return on the unsuccess
                return Plugin_Continue;
            }

            // Initialize vectors
            static float vEntPosition[3]; static float vVictimPosition[3];

            // Gets the entity's position
            GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

            // Create a info_target entity
            int infoIndex = FakeCreateEntity(vEntPosition, ZOMBIE_CLASS_SKILL_EXP_TIME);

            // Validate entity
            if(IsValidEdict(infoIndex))
            {
                // Create an explosion effect
                FakeCreateParticle(infoIndex, _, "explosion_hegrenade_interior", ZOMBIE_CLASS_SKILL_EXP_TIME);
                
                // Emit sound
                EmitSoundToAll("*/zbm3/deimos_skill_hit.mp3", infoIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }

            // Remove entity from world
            AcceptEntityInput(entityIndex, "Kill");

            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if(IsPlayerExist(i) && ZP_IsPlayerHuman(i) && !ZP_IsPlayerSurvivor(i))
                {
                    // Gets victim's origin
                    GetClientAbsOrigin(i, vVictimPosition);

                    // Calculate the distance
                    float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                    // Validate distance
                    if(flDistance <= ZOMBIE_CLASS_SKILL_EXP_RADIUS)
                    {
                        // Simple droping of the weapon
                        FakeClientCommandEx(i, "drop");
    
                        // Create an fade
                        FakeCreateFadeScreen(i, ZOMBIE_CLASS_EFFECT_DURATION_F, ZOMBIE_CLASS_EFFECT_TIME_F, 0x0001, ZOMBIE_CLASS_EFFECT_COLOR_F);
                    }
                }
            }
        }
    }

    // Return on the success
    return Plugin_Continue;
}
