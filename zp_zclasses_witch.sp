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
    name            = "[ZP] Zombie Class: Witch",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_SPEED        1500.0
#define ZOMBIE_CLASS_SKILL_GRAVITY      0.01
#define ZOMBIE_CLASS_SKILL_ATTACH       150.0 // Attach speed
#define ZOMBIE_CLASS_SKILL_DURATION     4.0
#define ZOMBIE_CLASS_SKILL_EXP_TIME     2.0
/**
 * @endsection
 **/

// Decal index
int decalSmoke;

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Zombie index
int gZombie;
#pragma unused gZombie

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gZombie = ZP_GetClassNameID("witch");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"witch\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("WITCH_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"WITCH_SKILL_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Models
    decalSmoke = PrecacheModel("sprites/steam1.vmt", true);
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];

        // Gets client eye position
        GetClientEyePosition(clientIndex, vPosition);

        // Gets client eye angle
        GetClientEyeAngles(clientIndex, vAngle);

        // Gets client speed
        GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a bat entity
        int entityIndex = UTIL_CreateProjectile(vPosition, vAngle, "models/weapons/bazooka/w_bazooka_projectile.mdl");

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Sets bat model scale
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
            TeleportEntity(entityIndex, NULL_VECTOR, NULL_VECTOR, vEntVelocity);

            // Sets an entity color
            SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
            SetEntityRenderColor(entityIndex, _, _, _, 0);
            AcceptEntityInput(entityIndex, "DisableShadow"); /// Prevents the entity from receiving shadows
            
            // Create a prop_dynamic_override entity
            int batIndex = UTIL_CreateDynamic(NULL_VECTOR, NULL_VECTOR, "models/player/custom_player/zombie/bats/bats2.mdl", "fly");

            // Validate entity
            if(batIndex != INVALID_ENT_REFERENCE)
            {
                // Sets parent/owner to the entity
                SetVariantString("!activator");
                AcceptEntityInput(batIndex, "SetParent", entityIndex, batIndex);
                
                // Sets attachment to the projectile
                SetVariantString("1"); 
                AcceptEntityInput(batIndex, "SetParentAttachment", entityIndex, batIndex);
            }

            // Sets parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);

            // Sets gravity
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY);

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, BatTouchHook);
        }
    }

    // Allow usage
    return Plugin_Continue;
}


/**
 * @brief Bat touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action BatTouchHook(int entityIndex, int targetIndex)
{
    // Validate target
    if(IsValidEdict(targetIndex))
    {
        // Gets thrower index
        int throwerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hThrower");
        
        // Validate thrower
        if(throwerIndex == targetIndex)
        {
            // Return on the unsuccess
            return Plugin_Continue;
        }
        
        // Initialize variables
        static float vEntPosition[3]; static float vVictimPosition[3]; static float vVictimAngle[3];

        // Gets entity position
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vEntPosition);

        // Validate target
        if(IsPlayerExist(targetIndex))
        {
            // Gets victim origin
            GetEntPropVector(targetIndex, Prop_Data, "m_vecAbsOrigin", vVictimPosition);
    
            // Gets victim origin angle
            GetEntPropVector(targetIndex, Prop_Data, "m_angAbsRotation", vVictimAngle);
    
            // Create a prop_dynamic_override entity
            int batIndex = UTIL_CreateDynamic(NULL_VECTOR, NULL_VECTOR, "models/player/custom_player/zombie/bats/bats2.mdl", "fly2");

            // Validate entity
            if(batIndex != INVALID_ENT_REFERENCE)
            {
                // Sets parent/owner to the entity
                SetVariantString("!activator");
                AcceptEntityInput(batIndex, "SetParent", targetIndex, batIndex);
                SetEntPropEnt(batIndex, Prop_Data, "m_pParent", targetIndex); 
                if(throwerIndex != INVALID_ENT_REFERENCE)
                {
                    SetEntPropEnt(batIndex, Prop_Send, "m_hOwnerEntity", throwerIndex);
                }
                
                // Sets attachment to the client
                SetVariantString("eholster"); 
                AcceptEntityInput(batIndex, "SetParentAttachment", targetIndex, batIndex);

                // Kill after some duration
                UTIL_RemoveEntity(batIndex, ZOMBIE_CLASS_SKILL_DURATION);

                // Create a connection
                CreateTimer(0.1, BatAttachHook, EntIndexToEntRef(batIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            }

            // Play sound
            ZP_EmitSoundToAll(gSound, 2, targetIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        }
        else
        {
            // Create an blood effect
            UTIL_CreateParticle(_, vEntPosition, _, _, "blood_pool", ZOMBIE_CLASS_SKILL_EXP_TIME);
            
            // Play sound
            ZP_EmitSoundToAll(gSound, 3, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            
            // Create effect
            TE_SetupSmoke(vEntPosition, decalSmoke, 130.0, 10);
            TE_SendToAllInRange(vEntPosition, RangeType_Visibility);
        }

        // Remove entity from world
        AcceptEntityInput(entityIndex, "Kill");
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Main timer for attach bat hook.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action BatAttachHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Gets owner/target index
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

            // Block vertical scale
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
        else
        {
            // Remove entity from world
            AcceptEntityInput(entityIndex, "Kill");
        }
    }

    // Destroy timer
    return Plugin_Stop;
}
