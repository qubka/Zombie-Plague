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
    name            = "[ZP] Zombie Class: Baller",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
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
Handle hHumanBlasted[MAXPLAYERS+1] = null;
 
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
    if (!strcmp(sLibrary, "zombieplague", false))
    {
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
    // Classes
    gZombie = ZP_GetClassNameID("baller");
    //if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"baller\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BALLER_SKILL_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALLER_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for (int i = 1; i <= MaxClients; i++)
    {
        // Purge timer
        hHumanBlasted[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
    // Delete timer
    delete hHumanBlasted[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
    // Resets move
    SetEntityMoveType(client, MOVETYPE_WALK);
    
    // Delete timer
    delete hHumanBlasted[client];
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
    if (ZP_GetClientClass(client) == gZombie)
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
        
        // Create a blast entity
        int entity = UTIL_CreateProjectile(vPosition, vAngle, "models/player/custom_player/zombie/aura_shield/aura_shield2.mdl");
        
        // Validate entity
        if (entity != -1)
        {
            // Sets blast model scale
            SetEntPropFloat(entity, Prop_Send, "m_flModelScale", ZOMBIE_CLASS_SKILL_SIZE);
            
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vSpeed, NULL_VECTOR, NULL_VECTOR);
            
            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vSpeed, vSpeed);
            
            // Apply the magnitude by scaling the vector
            ScaleVector(vSpeed, ZOMBIE_CLASS_SKILL_SPEED);

            // Adds two vectors
            AddVectors(vSpeed, vVelocity, vSpeed);

            // Push the blast
            TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vSpeed);
            TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vSpeed);

            // Sets parent for the entity
            SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
            SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
            SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);
            
            // Sets gravity
            SetEntPropFloat(entity, Prop_Data, "m_flGravity", ZOMBIE_CLASS_SKILL_GRAVITY);
            SetEntPropFloat(entity, Prop_Data, "m_flElasticity", ZOMBIE_CLASS_SKILL_ELASTICITY);
            
            // Play sound
            ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
            
            // Create an effect
            UTIL_CreateParticle(entity, vPosition, _, _, "gamma_blue", ZP_GetClassSkillDuration(gZombie));
            
            // Put fire on it
            UTIL_IgniteEntity(entity, ZP_GetClassSkillDuration(gZombie));

            // Sets blue render color
            SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
            SetEntityRenderColor(entity, 186, 85, 211, 255);
            
            // Create touch hook
            SDKHook(entity, SDKHook_Touch, BlastTouchHook);
            
            // Create remove timer
            CreateTimer(ZP_GetClassSkillDuration(gZombie), BlastExploadHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Blast touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action BlastTouchHook(int entity, int target)
{
    // Play sound
    ZP_EmitSoundToAll(gSound, GetRandomInt(3, 4), entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Main timer for exploade blast.
 * 
 * @param hTimer            The timer handle.
 * @param refID             The reference index.                    
 **/
public Action BlastExploadHook(Handle hTimer, int refID)
{
    // Gets entity index from reference key
    int entity = EntRefToEntIndex(refID);

    // Validate entity
    if (entity != -1)
    {
        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Create an explosion effect
        UTIL_CreateParticle(_, vPosition, _, _, "Explosions_MA_Dustup_2", ZOMBIE_CLASS_SKILL_EXP_TIME);
        
        // Gets thrower index
        int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
        
        // Find any players in the radius
        int i; int it = 1; /// iterator
        while ((i = ZP_FindPlayerInSphere(it, vPosition, ZOMBIE_CLASS_SKILL_EXP_RADIUS)) != -1)
        {
            // Skip zombies
            if (ZP_IsPlayerZombie(i))
            {
                continue;
            }

            // Blast the client
            SetEntityMoveType(i, MOVETYPE_NONE);

            // Create the damage for victim
            ZP_TakeDamage(i, thrower, thrower, ZOMBIE_CLASS_SKILL_EXP_DAMAGE, DMG_SHOCK);
            
            // Create a fade
            UTIL_CreateFadeScreen(i, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, FFADE_IN, ZOMBIE_CLASS_SKILL_COLOR_F);
            
            // Create a shake
            UTIL_CreateShakeScreen(i, ZOMBIE_CLASS_SKILL_SHAKE_AMP, ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY, ZOMBIE_CLASS_SKILL_SHAKE_DURATION);
            
            // Create timer for removing freezing
            delete hHumanBlasted[i];
            hHumanBlasted[i] = CreateTimer(ZOMBIE_CLASS_SKILL_DURATION, ClientRemoveBlastEffect, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);    
        }
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 5, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);

        // Remove entity from the world
        AcceptEntityInput(entity, "Kill");
    }
    
    // Destroy timer
    return Plugin_Stop;
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
    int client = GetClientOfUserId(userID);
    
    // Clear timer 
    hHumanBlasted[client] = null;

    // Validate client
    if (client)
    {    
        // Untrap the client
        SetEntityMoveType(client, MOVETYPE_WALK);
    }

    // Destroy timer
    return Plugin_Stop;
}
