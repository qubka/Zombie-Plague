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
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: Range",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_EXP_RADIUS         40000.0 // [squared]
#define ZOMBIE_CLASS_EXP_LAST           false
#define ZOMBIE_CLASS_EXP_SURVIVOR       false
#define ZOMBIE_CLASS_EXP_DURATION       2.0
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
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
    }
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gZombie = ZP_GetZombieClassNameID("range");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"range\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("RANGE_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"RANGE_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    if(hSoundLevel == INVALID_HANDLE) SetFailState("[ZP] Custom cvar key ID from name : \"zp_game_custom_sound_level\" wasn't find");
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false ifnot.
 **/
public Action EventPlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // If client is zombie, then expload him
    if(ZP_IsPlayerZombie(clientIndex) && !ZP_IsPlayerNemesis(clientIndex))
    {
        // Validate the zombie class index
        if(ZP_GetClientZombieClass(clientIndex) == gZombie)
        {
            // Validate zombie amount
            if(ZP_GetZombieAmount() <= 0)
            {
                return;
            }
    
            // Initialize vectors
            static float vEntPosition[3]; static float vVictimPosition[3];

            // Gets the client origin
            GetClientAbsOrigin(clientIndex, vEntPosition);

            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if(IsPlayerExist(i) && ((ZP_IsPlayerHuman(i) && !ZP_IsPlayerSurvivor(i)) || (ZP_IsPlayerSurvivor(i) && ZOMBIE_CLASS_EXP_SURVIVOR)))
                {
                    // Gets victim origin
                    GetClientAbsOrigin(i, vVictimPosition);

                    // Calculate the distance
                    float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                    // Validate distance
                    if(flDistance <= ZOMBIE_CLASS_EXP_RADIUS)
                    {
                        // Change class to zombie
                        if(ZP_GetHumanAmount() > 1 || ZOMBIE_CLASS_EXP_LAST) ZP_SwitchClientClass(i, clientIndex, TYPE_ZOMBIE);
                    }
                }
            }
            
            // Gets the ragdoll index
            int iRagdoll = GetEntPropEnt(clientIndex, Prop_Send, "m_hRagdoll");

            // If the ragdoll is invalid, then stop
            if(IsValidEdict(iRagdoll))
            {
                // Create an effect
                FakeCreateParticle(iRagdoll, vEntPosition, _, "explosion_hegrenade_dirt", ZOMBIE_CLASS_EXP_DURATION);
                
                // Emit sound
                static char sSound[PLATFORM_MAX_PATH];
                ZP_GetSound(gSound, sSound, sizeof(sSound));
                EmitSoundToAll(sSound, iRagdoll, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
        }
    }
}
