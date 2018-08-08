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
    name            = "[ZP] Zombie Class: NormalF05",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "normalf05" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "normalf05 info" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/normal_f_05/normal_f_05.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/normal_f_05/hand_v2/hand_normal_f_05.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/normal_f_05/grenade/grenade_normal_f_05.mdl"    
#define ZOMBIE_CLASS_HEALTH             4000
#define ZOMBIE_CLASS_SPEED              0.9
#define ZOMBIE_CLASS_GRAVITY            0.9
#define ZOMBIE_CLASS_KNOCKBACK          1.5
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_GROUP              "[VIP]"
#define ZOMBIE_CLASS_DURATION           10.0    
#define ZOMBIE_CLASS_COUNTDOWN          30.0
#define ZOMBIE_CLASS_REGEN_HEALTH       0
#define ZOMBIE_CLASS_REGEN_INTERVAL     0.0
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_FEMALE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_FEMALE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_FEMALE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_FEMALE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_FEMALE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_FEMALE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FEMALE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_FEMALE_REGEN_SOUNDS"
#define ZOMBIE_CLASS_SKILL_SPEED        1500.0
#define ZOMBIE_CLASS_SKILL_GRAVITY      0.01
#define ZOMBIE_CLASS_SKILL_ATTACH       150.0 // Attach speed
#define ZOMBIE_CLASS_SKILL_DURATION     4.0
#define ZOMBIE_CLASS_SKILL_REMOVE       0.1
#define ZOMBIE_CLASS_SKILL_EXP_TIME     2.0
/**
 * @endsection
 **/


// Variables for precache resources
int decalSmoke;

// Variables for the key sound block
int gSound; ConVar hSoundLevel;

// Initialize zombie class index
int gZombieNormalF05;
#pragma unused gZombieNormalF05

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize zombie class
        gZombieNormalF05 = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
        ZOMBIE_CLASS_INFO,
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW,  
        ZOMBIE_CLASS_GRENADE,
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_GROUP, 
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
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Sounds
    gSound = ZP_GetSoundKeyID("WITCH_SKILL_SOUNDS");

    // Models
    decalSmoke = PrecacheModel("sprites/steam1.vmt", true);
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
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
    if(ZP_GetClientZombieClass(clientIndex) == gZombieNormalF05)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];

        // Gets the client eye position
        GetClientEyePosition(clientIndex, vPosition);

        // Gets the client eye angle
        GetClientEyeAngles(clientIndex, vAngle);

        // Gets the client speed
        GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);
        
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a bat entity
        int entityIndex = CreateEntityByName("hegrenade_projectile");

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Spawn the entity
            DispatchSpawn(entityIndex);

            // Sets the bat model scale
            SetEntPropFloat(entityIndex, Prop_Send, "m_flModelScale", 9.0);
            
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);

            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vEntVelocity, vEntVelocity);

            // Apply the magnitude by scaling the vector
            ScaleVector(vEntVelocity, ZOMBIE_CLASS_SKILL_SPEED);

            // Adds two vectors
            AddVectors(vEntVelocity, vVelocity, vEntVelocity);

            // Push the bat
            TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);

            // Sets the model
            SetEntityModel(entityIndex, "models/player/custom_player/zombie/bazooka/bazooka_w_projectile.mdl");
            
            // Sets an entity color
            SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
            SetEntityRenderColor(entityIndex, _, _, _, 0); 
            
            // Create a prop_dynamic_override entity
            int batIndex = CreateEntityByName("prop_dynamic_override");

            // Validate entity
            if(batIndex != INVALID_ENT_REFERENCE)
            {
                // Dispatch main values of the entity
                DispatchKeyValue(batIndex, "model", "models/player/custom_player/zombie/bats/bats2.mdl");
                DispatchKeyValue(batIndex, "DefaultAnim", "fly");
                DispatchKeyValue(batIndex, "spawnflags", "256"); /// Start with collision disabled
                DispatchKeyValue(batIndex, "solid", "0");

                // Spawn the entity
                DispatchSpawn(batIndex);

                // Sets parent/owner to the entity
                SetVariantString("!activator");
                AcceptEntityInput(batIndex, "SetParent", entityIndex, batIndex);
                
                // Sets attachment to the projectile
                SetVariantString("1"); 
                AcceptEntityInput(batIndex, "SetParentAttachment", entityIndex, batIndex);
            }

            // Sets the parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);

            // Sets the gravity
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY);

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, BatTouchHook);
        }
    }

    // Allow usage
    return Plugin_Continue;
}


/**
 * Bat touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action BatTouchHook(const int entityIndex, const int targetIndex)
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
            
            // Initialize variables
            static float vEntPosition[3]; static float vVictimPosition[3]; static float vVictimAngle[3]; static char sSound[PLATFORM_MAX_PATH];

            // Gets the entity position
            GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

            // Validate target
            if(IsPlayerExist(targetIndex))
            {
                // Gets victim origin
                GetClientAbsOrigin(targetIndex, vVictimPosition);
        
                // Gets victim origin angle
                GetClientAbsAngles(targetIndex, vVictimAngle);
        
                // Create a prop_dynamic_override entity
                int batIndex = CreateEntityByName("prop_dynamic_override");

                // Validate entity
                if(batIndex != INVALID_ENT_REFERENCE)
                {
                    // Dispatch main values of the entity
                    DispatchKeyValue(batIndex, "model", "models/player/custom_player/zombie/bats/bats2.mdl");
                    DispatchKeyValue(batIndex, "DefaultAnim", "fly2");
                    DispatchKeyValue(batIndex, "spawnflags", "256"); /// Start with collision disabled
                    DispatchKeyValue(batIndex, "solid", "0");

                    // Spawn the entity
                    DispatchSpawn(batIndex);

                    // Sets parent/owner to the entity
                    SetVariantString("!activator");
                    AcceptEntityInput(batIndex, "SetParent", targetIndex, batIndex);
                    SetEntPropEnt(batIndex, Prop_Data, "m_pParent", targetIndex); 
                    SetEntPropEnt(batIndex, Prop_Send, "m_hOwnerEntity", throwerIndex);

                    // Sets attachment to the client
                    SetVariantString("eholster"); 
                    AcceptEntityInput(batIndex, "SetParentAttachment", targetIndex, batIndex);

                    // Initialize char
                    static char sTime[SMALL_LINE_LENGTH];
                    Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", ZOMBIE_CLASS_SKILL_DURATION);

                    // Sets modified flags on entity
                    SetVariantString(sTime);
                    AcceptEntityInput(batIndex, "AddOutput");
                    AcceptEntityInput(batIndex, "FireUser1");

                    // Create a connection
                    CreateTimer(0.1, BatAttachHook, EntIndexToEntRef(batIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                }

                // Emit sound
                ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
                EmitSoundToAll(sSound, targetIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
            }
            else
            {
                // Create a info_target entity
                int infoIndex = FakeCreateEntity(vEntPosition, ZOMBIE_CLASS_SKILL_EXP_TIME);

                // Validate entity
                if(IsValidEdict(infoIndex))
                {
                    // Create an explosion effect
                    FakeCreateParticle(infoIndex, vEntPosition, _, "blood_pool", ZOMBIE_CLASS_SKILL_EXP_TIME);
                    
                    // Emit sound
                    ZP_GetSound(gSound, sSound, sizeof(sSound), 3);
                    EmitSoundToAll(sSound, infoIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                }
        
                // Create effect
                TE_SetupSmoke(vEntPosition, decalSmoke, 130.0, 10);
                TE_SendToAllInRange(vEntPosition, RangeType_Visibility);
            }

            // Remove entity from world
            AcceptEntityInput(entityIndex, "Kill");
        }
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * Main timer for attach bat hook.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action BatAttachHook(Handle hTimer, const int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Gets the owner/target index
        int ownerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity");
        int targetIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent"); 

        // Validate owner/target
        if(IsPlayerExist(ownerIndex) && IsPlayerExist(targetIndex))
        {
            // Initialize vectors
            static float vEntVelocity[3]; static float vEntPosition[3]; static float vTargetPosition[3];

            // Gets owner/target eye position
            GetClientEyePosition(ownerIndex, vEntPosition);
            GetClientEyePosition(targetIndex, vTargetPosition);

            // Calculate the velocity vector
            SubtractVectors(vEntPosition, vTargetPosition, vEntVelocity);

            // Sets the vertical scale
            vEntVelocity[2] = 0.0;

            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vEntVelocity, vEntVelocity);

            // Apply the magnitude by scaling the vector
            ScaleVector(vEntVelocity, ZOMBIE_CLASS_SKILL_ATTACH);

            // Push the target
            TeleportEntity(targetIndex, NULL_VECTOR, NULL_VECTOR, vEntVelocity);

            // Allow timer
            return Plugin_Continue;
        }
    }

    // Destroy timer
    return Plugin_Stop;
}
