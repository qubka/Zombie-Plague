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
    name            = "[ZP] Zombie Class: Witch",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
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
int gSmoke;
#pragma unused gSmoke

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Zombie index
int gZombie;
#pragma unused gZombie

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // If map loaded, then run custom forward
        if(ZP_IsMapLoaded())
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
    // Classes
    gZombie = ZP_GetClassNameID("witch");
    //if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"witch\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("WITCH_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"WITCH_SKILL_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Models
    gSmoke = PrecacheModel("sprites/steam1.vmt", true);
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(client) == gZombie)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vSpeed[3];

        // Gets client eye position
        GetClientEyePosition(client, vPosition);

        // Gets client eye angle
        GetClientEyeAngles(client, vAngle);

        // Gets client speed
        GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a bat entity
        int entity = UTIL_CreateProjectile(vPosition, vAngle, "models/weapons/cso/bazooka/w_bazooka_projectile.mdl");

        // Validate entity
        if(entity != -1)
        {
            // Sets bat model scale
            SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 9.0);
            
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vSpeed, NULL_VECTOR, NULL_VECTOR);

            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vSpeed, vSpeed);

            // Apply the magnitude by scaling the vector
            ScaleVector(vSpeed, ZOMBIE_CLASS_SKILL_SPEED);

            // Adds two vectors
            AddVectors(vSpeed, vVelocity, vSpeed);

            // Push the bat
            TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vSpeed);

            // Sets an entity color
            UTIL_SetRenderColor(entity, Color_Alpha, 0);
            AcceptEntityInput(entity, "DisableShadow"); /// Prevents the entity from receiving shadows
            
            // Create a prop_dynamic_override entity
            int bat = UTIL_CreateDynamic("bats", NULL_VECTOR, NULL_VECTOR, "models/player/custom_player/zombie/bats/bats2.mdl", "fly", false);

            // Validate entity
            if(bat != -1)
            {
                // Sets parent to the entity
                SetVariantString("!activator");
                AcceptEntityInput(bat, "SetParent", entity, bat);
                
                // Sets attachment to the projectile
                SetVariantString("1"); 
                AcceptEntityInput(bat, "SetParentAttachment", entity, bat);
            }

            // Sets parent for the entity
            SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
            SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
            SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

            // Sets gravity
            SetEntPropFloat(entity, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY);

            // Create touch hook
            SDKHook(entity, SDKHook_Touch, BatTouchHook);
        }
    }

    // Allow usage
    return Plugin_Continue;
}


/**
 * @brief Bat touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action BatTouchHook(int entity, int target)
{
    // Validate target
    if(IsValidEdict(target))
    {
        // Gets thrower index
        int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
        
        // Validate thrower
        if(thrower == target)
        {
            // Return on the unsuccess
            return Plugin_Continue;
        }
        
        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Validate target
        if(IsPlayerExist(target))
        {
            // Create a prop_dynamic_override entity
            int bat = UTIL_CreateDynamic("bats", NULL_VECTOR, NULL_VECTOR, "models/player/custom_player/zombie/bats/bats2.mdl", "fly2", false);

            // Validate entity
            if(bat != -1)
            {
                // Sets parent to the entity
                SetVariantString("!activator");
                AcceptEntityInput(bat, "SetParent", target, bat);
                SetEntPropEnt(bat, Prop_Data, "m_pParent", target); 
                if(thrower != -1)
                {
                    SetEntPropEnt(bat, Prop_Data, "m_hOwnerEntity", thrower);
                }
                
                // Sets attachment to the client
                SetVariantString("eholster"); 
                AcceptEntityInput(bat, "SetParentAttachment", target, bat);

                // Kill after some duration
                UTIL_RemoveEntity(bat, ZOMBIE_CLASS_SKILL_DURATION);

                // Create a attach timer
                CreateTimer(0.1, BatAttachHook, EntIndexToEntRef(bat), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            }

            // Play sound
            ZP_EmitSoundToAll(gSound, 2, target, SNDCHAN_VOICE, hSoundLevel.IntValue);
        }
        else
        {
            // Create an blood effect
            UTIL_CreateParticle(_, vPosition, _, _, "blood_pool", ZOMBIE_CLASS_SKILL_EXP_TIME);
            
            // Play sound
            ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
            
            // Create effect
            TE_SetupSmoke(vPosition, gSmoke, 130.0, 10);
            TE_SendToAll();
        }

        // Remove entity from world
        AcceptEntityInput(entity, "Kill");
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Main timer for attach bat hook.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action BatAttachHook(Handle hTimer, int refID)
{
    // Gets entity index from reference key
    int entity = EntRefToEntIndex(refID);

    // Validate entity
    if(entity != -1)
    {
        // Gets owner/target index
        int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
        int target = GetEntPropEnt(entity, Prop_Data, "m_pParent"); 

        // Validate owner/target
        if(IsPlayerExist(owner) && IsPlayerExist(target))
        {
            // Initialize vectors
            static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];

            // Gets owner/target eye position
            GetClientEyePosition(owner, vPosition);
            GetClientEyePosition(target, vAngle);

            // Calculate the velocity vector
            MakeVectorFromPoints(vAngle, vPosition, vVelocity);
            
            // Block vertical scale
            vVelocity[2] = 0.0;

            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vVelocity, vVelocity);

            // Apply the magnitude by scaling the vector
            ScaleVector(vVelocity, ZOMBIE_CLASS_SKILL_ATTACH);

            // Push the target
            TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vVelocity);

            // Allow timer
            return Plugin_Continue;
        }
        else
        {
            // Remove entity from world
            AcceptEntityInput(entity, "Kill");
        }
    }

    // Destroy timer
    return Plugin_Stop;
}
