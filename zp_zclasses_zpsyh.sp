/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
    name            = "[ZP] Zombie Class: Psyh",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
 **/    
#define ZOMBIE_CLASS_SKILL_RADIUS        250.0
#define ZOMBIE_CLASS_SKILL_DAMAGE        1.0
#define ZOMBIE_CLASS_SKILL_COLOR         {255, 0, 0, 200}
/**
 * @endsection
 **/

// Decal index
int gTrail;
#pragma unused gTrail

// Timer index
Handle hZombieScream[MAXPLAYERS+1] = null; 

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
    gZombie = ZP_GetClassNameID("psyh");
    //if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"psyh\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("PSYH_SKILL_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"PSYH_SKILL_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Models
    gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
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
        hZombieScream[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete hZombieScream[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
    // Delete timer
    delete hZombieScream[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
    // Delete timer
    delete hZombieScream[client];
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
        // Create scream damage task
        delete hZombieScream[client];
        hZombieScream[client] = CreateTimer(0.1, ClientOnScreaming, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

        // Play sound
        ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create effect
        static float vPosition[3];
        GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
        UTIL_CreateParticle(client, vPosition, _, _, "hell_end", ZP_GetClassSkillDuration(gZombie));
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Called when a skill duration is over.
 * 
 * @param client            The client index.
 **/
public void ZP_OnClientSkillOver(int client)
{
    // Validate the zombie class index
    if (ZP_GetClientClass(client) == gZombie) 
    {
        // Delete timer
        delete hZombieScream[client];
    }
}

/**
 * @brief Timer for the screamming process.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientOnScreaming(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID);
    
    // Validate client
    if (client)
    {
        // Gets client origin
        static float vPosition[3];
        GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition); vPosition[2] += 25.0;  

        // Find any players in the radius
        int i; int it = 1; /// iterator
        while ((i = ZP_FindPlayerInSphere(it, vPosition, ZOMBIE_CLASS_SKILL_RADIUS)) != -1)
        {
            // Skip zombies
            if (ZP_IsPlayerZombie(i))
            {
                continue;
            }
            
            // Create the damage for victim
            ZP_TakeDamage(i, client, client, ZOMBIE_CLASS_SKILL_DAMAGE, DMG_SONIC);
        }
       
        // Create a beamring effect               <Diameter>
        TE_SetupBeamRingPoint(vPosition, 50.0, ZOMBIE_CLASS_SKILL_RADIUS * 2.0, gTrail, 0, 1, 10, 1.0, 15.0, 0.0, ZOMBIE_CLASS_SKILL_COLOR, 50, 0);
        TE_SendToAll();
        
        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    hZombieScream[client] = null;

    // Destroy timer
    return Plugin_Stop;
}
