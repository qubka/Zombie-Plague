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
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin ZombieClassRange =
{
    name            = "[ZP] Zombie Class: Range",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "Range" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "RangeInfo" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/zombie_range/zombie_range.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/zombie_range/hand_v2/hand_zombie_range.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/zombie_range/grenade/grenade_zombie_range.mdl"    
#define ZOMBIE_CLASS_HEALTH             1200
#define ZOMBIE_CLASS_SPEED              1.0
#define ZOMBIE_CLASS_GRAVITY            0.9
#define ZOMBIE_CLASS_KNOCKBACK          1.0
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_VIP                NO
#define ZOMBIE_CLASS_DURATION           0.0    
#define ZOMBIE_CLASS_COUNTDOWN          0.0
#define ZOMBIE_CLASS_REGEN_HEALTH       500
#define ZOMBIE_CLASS_REGEN_INTERVAL     10.0
#define ZOMBIE_CLASS_EXP_RADIUS         40000.0 // [squared]
#define ZOMBIE_CLASS_EXP_LAST           false
#define ZOMBIE_CLASS_EXP_SURVIVOR       false
#define ZOMBIE_CLASS_EXP_DURATION       2.0
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_REGEN_SOUNDS"
/**
 * @endsection
 **/

// ConVar for sound level
ConVar hSoundLevel;
 
// Initialize zombie class index
int gZombieRange;
#pragma unused gZombieRange

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initilizate zombie class
        gZombieRange = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
        ZOMBIE_CLASS_INFO,
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW,  
        ZOMBIE_CLASS_GRENADE,
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_VIP, 
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
        
        // Hook events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
    }
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
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
        if(ZP_GetClientZombieClass(clientIndex) == gZombieRange)
        {
            // Initialize vectors
            static float vEntPosition[3]; static float vVictimPosition[3];

            // Gets the client's origin
            GetClientAbsOrigin(clientIndex, vEntPosition);

            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if(IsPlayerExist(i) && ((ZP_IsPlayerHuman(i) && !ZP_IsPlayerSurvivor(i)) || (ZP_IsPlayerSurvivor(i) && ZOMBIE_CLASS_EXP_SURVIVOR)))
                {
                    // Gets victim's origin
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
                FakeCreateParticle(iRagdoll, _, "explosion_hegrenade_dirt", ZOMBIE_CLASS_EXP_DURATION);
                
                // Emit sound
                EmitSoundToAll("*/zbm3/infect_exp.mp3", iRagdoll, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
        }
    }
}