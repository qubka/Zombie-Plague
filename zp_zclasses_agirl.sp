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
    name            = "[ZP] Zombie Class: Girl",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_SPEED        3000.0
#define ZOMBIE_CLASS_SKILL_GRAVITY      0.01
#define ZOMBIE_CLASS_SKILL_EXP_RADIUS   150.0
#define ZOMBIE_CLASS_SKILL_EXP_TIME     2.0
#define ZOMBIE_CLASS_SKILL_WIDTH        3.0
#define ZOMBIE_CLASS_SKILL_WIDTH_END    1.0
#define ZOMBIE_CLASS_SKILL_COLOR        {209, 120, 9, 200}
#define ZOMBIE_CLASS_SKILL_COLOR_F      {209, 120, 9, 75}
#define ZOMBIE_CLASS_SKILL_DURATION_F   0.3
#define ZOMBIE_CLASS_SKILL_TIME_F       1.0
#define ZOMBIE_CLASS_SKILL_FIRE         10.0
/**
 * @endsection
 **/

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
    gZombie = ZP_GetClassNameID("girl");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"girl\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("DEIMOS_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"DEIMOS_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
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
        
        // Create a bomb entity
        int entityIndex = UTIL_CreateProjectile(vPosition, vAngle);
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Sets bomb model scale
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
            TeleportEntity(entityIndex, NULL_VECTOR, NULL_VECTOR, vEntVelocity);

            // Sets parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);

            // Sets gravity
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY); 

            // Put fire on it
            UTIL_IgniteEntity(entityIndex, ZOMBIE_CLASS_SKILL_FIRE);
            
            // Create an effect
            UTIL_CreateParticle(entityIndex, vPosition, _, _, "gamma_trail_xz", 5.0);
    
            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, BombTouchHook);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Bomb touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action BombTouchHook(int entityIndex, int targetIndex)
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

        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
        
        // Create an explosion effect
        UTIL_CreateParticle(_, vPosition, _, _, "pyrovision_explosion", ZOMBIE_CLASS_SKILL_EXP_TIME);
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 2, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

        // Find any players in the radius
        int i; int it = 1; /// iterator
        while((i = ZP_FindPlayerInSphere(it, vPosition, ZOMBIE_CLASS_SKILL_EXP_RADIUS)) != INVALID_ENT_REFERENCE)
        {
            // Skip zombies
            if(ZP_IsPlayerZombie(i))
            {
                continue;
            }

            // Simple droping of the weapon
            FakeClientCommandEx(i, "drop");

            // Create an fade
            UTIL_CreateFadeScreen(i, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, FFADE_IN, ZOMBIE_CLASS_SKILL_COLOR_F);
        }

        // Remove entity from world
        AcceptEntityInput(entityIndex, "Kill");
    }

    // Return on the success
    return Plugin_Continue;
}
