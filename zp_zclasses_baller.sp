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
    name            = "[ZP] Zombie Class: Baller",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_COLOR_F          {186, 85, 211, 75}
#define ZOMBIE_CLASS_SKILL_DURATION_F       2.3
#define ZOMBIE_CLASS_SKILL_TIME_F           3.0      
#define ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY  1.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_DURATION   3.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_AMP        2.0  
#define ZOMBIE_CLASS_SKILL_SPEED            2000.0
#define ZOMBIE_CLASS_SKILL_GRAVITY          0.01
#define ZOMBIE_CLASS_SKILL_SIZE             0.3
#define ZOMBIE_CLASS_SKILL_ELASTICITY       10.0
#define ZOMBIE_CLASS_SKILL_DISSOLVE         40  // Amount of energy which ball lose to dissolve
#define ZOMBIE_CLASS_SKILL_DURATION         3.0 
#define ZOMBIE_CLASS_SKILL_EXP_RADIUS       150.0
#define ZOMBIE_CLASS_SKILL_EXP_DAMAGE       100.0
#define ZOMBIE_CLASS_SKILL_EXP_TIME         2.0
/**
 * @endsection
 **/

// Timer index
Handle Task_HumanBlasted[MAXPLAYERS+1] = null;
 
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
    gZombie = ZP_GetClassNameID("baller");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"baller\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BALLER_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALLER_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timer
        Task_HumanBlasted[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Delete timer
    delete Task_HumanBlasted[clientIndex];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientUpdated(int clientIndex, int attackerIndex)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    
    // Delete timer
    delete Task_HumanBlasted[clientIndex];
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
        
        // Create a blast entity
        int entityIndex = CreateEntityByName("hegrenade_projectile");
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Spawn the entity
            DispatchSpawn(entityIndex);
            
            // Sets model
            SetEntityModel(entityIndex, "models/player/custom_player/zombie/aura_shield/aura_shield2.mdl");
            
            // Sets blast model scale
            SetEntPropFloat(entityIndex, Prop_Send, "m_flModelScale", ZOMBIE_CLASS_SKILL_SIZE);
            
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);
            
            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vEntVelocity, vEntVelocity);
            
            // Apply the magnitude by scaling the vector
            ScaleVector(vEntVelocity, ZOMBIE_CLASS_SKILL_SPEED);

            // Adds two vectors
            AddVectors(vEntVelocity, vVelocity, vEntVelocity);

            // Push the blast
            TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);

            // Sets parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);
            
            // Sets gravity
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY);
            SetEntPropFloat(entityIndex, Prop_Send, "m_flElasticity", ZOMBIE_CLASS_SKILL_ELASTICITY);
            
            // Emit sound
            ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
            EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            
            // Create an effect
            ZP_CreateParticle(entityIndex, vPosition, _, "gamma_blue", ZP_GetClassSkillDuration(gZombie));
            
            // Put fire on it
            IgniteEntity(entityIndex, ZP_GetClassSkillDuration(gZombie));

            // Sets blue render color
            SetEntityRenderMode(entityIndex, RENDER_TRANSCOLOR);
            SetEntityRenderColor(entityIndex, 186, 85, 211, 255);

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, BlastTouchHook);
            
            // Create remove timer
            CreateTimer(ZP_GetClassSkillDuration(gZombie), BlastExploadHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Blast touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action BlastTouchHook(int entityIndex, int targetIndex)
{
    // Emit sound
    static char sSound[PLATFORM_LINE_LENGTH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), GetRandomInt(3, 4));
    EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Main timer for exploade blast.
 * 
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.                    
 **/
public Action BlastExploadHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];

        // Gets entity position
        GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

        // Create a info_target entity
        int infoIndex = ZP_CreateEntity(vEntPosition, ZOMBIE_CLASS_SKILL_EXP_TIME);

        // Validate entity
        if(IsValidEdict(infoIndex))
        {
            // Create an explosion effect
            ZP_CreateParticle(infoIndex, vEntPosition, _, "explosion_molotov_air", ZOMBIE_CLASS_SKILL_EXP_TIME);
            
            // Emit sound
            static char sSound[PLATFORM_LINE_LENGTH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 5);
            EmitSoundToAll(sSound, infoIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        }
        
        // Gets blast owner
        int ownerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hThrower");
        
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate human
            if(IsPlayerExist(i) && ZP_IsPlayerHuman(i))
            {
                // Gets victim origin
                GetClientAbsOrigin(i, vVictimPosition);

                // Calculate the distance
                float flDistance = GetVectorDistance(vEntPosition, vVictimPosition);

                // Validate distance
                if(flDistance <= ZOMBIE_CLASS_SKILL_EXP_RADIUS)
                {
                    // Blaat the client
                    SetEntityMoveType(i, MOVETYPE_NONE);

                    // Create the damage for a victim
                    if(!ZP_TakeDamage(i, ownerIndex, entityIndex, ZOMBIE_CLASS_SKILL_EXP_DAMAGE * (1.0 - (flDistance / ZOMBIE_CLASS_SKILL_EXP_RADIUS)), DMG_AIRBOAT))
                    {
                        // Create a custom death event
                        ZP_CreateDeathEvent(i, ownerIndex, "snowball", true);
                    }
                    
                    // Create a fade
                    ZP_CreateFadeScreen(i, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, 0x0001, ZOMBIE_CLASS_SKILL_COLOR_F);
                    
                    // Create a shake
                    ZP_CreateShakeScreen(i, ZOMBIE_CLASS_SKILL_SHAKE_AMP, ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY, ZOMBIE_CLASS_SKILL_SHAKE_DURATION);
                    
                    // Create timer for removing freezing
                    delete Task_HumanBlasted[i];
                    Task_HumanBlasted[i] = CreateTimer(ZOMBIE_CLASS_SKILL_DURATION, ClientRemoveBlastEffect, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }

        // Remove entity from the world
        AcceptEntityInput(entityIndex, "Kill");
    }
}

/**
 * @brief Timer for remove blast effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveBlastEffect(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_HumanBlasted[clientIndex] = null;

    // Validate client
    if(clientIndex)
    {    
        // Untrap the client
        SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    }

    // Destroy timer
    return Plugin_Stop;
}
