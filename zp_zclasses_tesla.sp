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
    name            = "[ZP] Zombie Class: Tesla",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_DURATION_F        0.1
#define ZOMBIE_CLASS_SKILL_TIME_F            0.2
#define ZOMBIE_CLASS_SKILL_SHAKE_AMP         2.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY   1.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_DURATION    0.1
#define ZOMBIE_CLASS_SKILL_RADIUS            300.0
#define ZOMBIE_CLASS_SKILL_RADIUS_F          "300.0" /// Effect
/**
 * @endsection
 **/

// Timer index
Handle Task_ZombieHallucination[MAXPLAYERS+1] = null; 

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
    gZombie = ZP_GetClassNameID("tesla");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"tesla\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("TESLA_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TESLA_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Models
    PrecacheModel("materials/sprites/physbeam.vmt", true);
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
        Task_ZombieHallucination[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete Task_ZombieHallucination[clientIndex];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientDeath(int clientIndex, int attackerIndex)
{
    // Delete timer
    delete Task_ZombieHallucination[clientIndex];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientUpdated(int clientIndex, int attackerIndex)
{
    // Delete timer
    delete Task_ZombieHallucination[clientIndex];
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
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Gets client eye position
        static float vPosition[3]; 
        GetClientEyePosition(clientIndex, vPosition); vPosition[2] += 40.0;

        // Create hallucination task
        delete Task_ZombieHallucination[clientIndex];
        Task_ZombieHallucination[clientIndex] = CreateTimer(0.1, ClientOnHallucination, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

        // Create a tesla entity
        UTIL_CreateTesla(clientIndex, vPosition, _, _, ZOMBIE_CLASS_SKILL_RADIUS_F, _, "15", "25", _, _, "7.0", "9.0", _, _, _, _, ZP_GetClassSkillDuration(gZombie));
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientSkillOver(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie) 
    {
        // Delete timer
        delete Task_ZombieHallucination[clientIndex];
    }
}

/**
 * @brief Timer for the hallucination process.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientOnHallucination(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Validate client
    if(clientIndex)
    {
        // Initialize vectors
        static float vEntPosition[3]; static int vColor[4];

        // Gets client origin
        GetEntPropVector(clientIndex, Prop_Data, "m_vecAbsOrigin", vEntPosition);

        // Find any players in the radius
        int i; int it = 1; /// iterator
        while((i = ZP_FindPlayerInSphere(it, vEntPosition, ZOMBIE_CLASS_SKILL_RADIUS)) != INVALID_ENT_REFERENCE)
        {
            // Skip zombies
            if(ZP_IsPlayerZombie(i))
            {
                continue;
            }

            // Generate color
            vColor[0] = GetRandomInt(50, 200);
            vColor[1] = GetRandomInt(50, 200);
            vColor[2] = GetRandomInt(50, 200);
            vColor[3] = GetRandomInt(200, 230);

            // Create an fade
            UTIL_CreateFadeScreen(i, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, FFADE_IN, vColor);
            
            // Create a shake
            UTIL_CreateShakeScreen(i, ZOMBIE_CLASS_SKILL_SHAKE_AMP, ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY, ZOMBIE_CLASS_SKILL_SHAKE_DURATION);
        }

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    Task_ZombieHallucination[clientIndex] = null;

    // Destroy timer
    return Plugin_Stop;
}
