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
#define ZOMBIE_CLASS_SKILL_REMOVE       0.1
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
        
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a bat entity
        int entityIndex = CreateEntityByName("hegrenade_projectile");

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Spawn the entity
            DispatchSpawn(entityIndex);

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
            TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);

            // Sets model
            SetEntityModel(entityIndex, "models/weapons/bazooka/w_bazooka_projectile.mdl");
            
            // Sets an entity color
            SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
            SetEntityRenderColor(entityIndex, _, _, _, 0);
            DispatchKeyValue(entityIndex, "disableshadows", "1"); /// Prevents the entity from receiving shadows
            
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
    // Validate entity
    if(IsValidEdict(entityIndex))
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
            static float vEntPosition[3]; static float vVictimPosition[3]; static float vVictimAngle[3]; static char sSound[PLATFORM_LINE_LENGTH];

            // Gets entity position
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

                    // Initialize time char
                    static char sTime[SMALL_LINE_LENGTH];
                    FormatEx(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", ZOMBIE_CLASS_SKILL_DURATION);

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
                int infoIndex = ZP_CreateEntity(vEntPosition, ZOMBIE_CLASS_SKILL_EXP_TIME);

                // Validate entity
                if(IsValidEdict(infoIndex))
                {
                    // Create an blood effect
                    ZP_CreateParticle(infoIndex, vEntPosition, _, "blood_pool", ZOMBIE_CLASS_SKILL_EXP_TIME);
                    
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

            // Sets vertical scale
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
