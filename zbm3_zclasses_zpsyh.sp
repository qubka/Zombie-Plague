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
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: Psyh",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME                "Psyh" // Only will be taken from translation file         
#define ZOMBIE_CLASS_INFO                "PsyhInfo" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL               "models/player/custom_player/zombie/normalhost/normalhost.mdl"
#define ZOMBIE_CLASS_CLAW                "models/player/custom_player/zombie/normalhost/hand_v2/hand_zombie_normalhost.mdl"
#define ZOMBIE_CLASS_GRENADE             "models/player/custom_player/zombie/normalhost/grenade/grenade_normalhost.mdl"    
#define ZOMBIE_CLASS_HEALTH              4500
#define ZOMBIE_CLASS_SPEED               1.0
#define ZOMBIE_CLASS_GRAVITY             0.8
#define ZOMBIE_CLASS_KNOCKBACK           1.0
#define ZOMBIE_CLASS_LEVEL               1
#define ZOMBIE_CLASS_VIP                 NO
#define ZOMBIE_CLASS_DURATION            4.0
#define ZOMBIE_CLASS_COUNTDOWN           30.0 
#define ZOMBIE_CLASS_REGEN_HEALTH        200
#define ZOMBIE_CLASS_REGEN_INTERVAL      5.0
#define ZOMBIE_CLASS_SKILL_RADIUS        62500.0 // [squared]
#define ZOMBIE_CLASS_SKILL_DAMAGE        0.7 // 10 per second    
#define ZOMBIE_CLASS_SKILL_COLOR         {255, 0, 0, 200}
#define ZOMBIE_CLASS_SKILL_SURVIVOR      false
#define ZOMBIE_CLASS_SOUND_DEATH         "ZOMBIE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT          "ZOMBIE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE          "ZOMBIE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN       "ZOMBIE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN          "ZOMBIE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK        "ZOMBIE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP      "ZOMBIE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN         "ZOMBIE_REGEN_SOUNDS"
/**
 * @endsection
 **/

// Variables for precache resources
int decalTrail; int decalHalo;

// Initialize variables
Handle Task_ZombieScream[MAXPLAYERS+1] = INVALID_HANDLE; 

// Variables for the key sound block
int gSound;
 
// Initialize zombie class index
int gZombiePsyh;
#pragma unused gZombiePsyh

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook player events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);

        // Initialize zombie class
        gZombiePsyh = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
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
    }
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Sounds
    gSound = ZP_GetSoundKeyID("PSYH_SKILL_SOUNDS");

    // Models
    decalTrail = PrecacheModel("materials/sprites/laserbeam.vmt");
    decalHalo  = PrecacheModel("materials/sprites/glow.vmt");  
}

/**
 * The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timer
        Task_ZombieScream[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}


/**
 * Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Delete timer
    delete Task_ZombieScream[clientIndex];
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Delete timer
    delete Task_ZombieScream[GetClientOfUserId(hEvent.GetInt("userid"))];
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
    // Delete timer
    delete Task_ZombieScream[clientIndex];
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientHumanized(int clientIndex)
{
    // Delete timer
    delete Task_ZombieScream[clientIndex];
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Handled;
    }
    
    // Validate the zombie class index
    if(ZP_GetClientZombieClass(clientIndex) == gZombiePsyh)
    {
        // Create scream damage task
        delete Task_ZombieScream[clientIndex];
        Task_ZombieScream[clientIndex] = CreateTimer(0.1, ClientOnScreaming, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

        // Emit sound
        ZP_EmitSoundKeyID(clientIndex, gSound, SNDCHAN_VOICE);
        
        // Create an effect
        FakeCreateParticle(clientIndex, _, "hell_end", ZOMBIE_CLASS_DURATION);
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Called when a zombie skill duration is over.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientSkillOver(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Validate the zombie class index
    if(ZP_GetClientZombieClass(clientIndex) == gZombiePsyh) 
    {
        // Delete timer
        delete Task_ZombieScream[clientIndex];
    }
}

/**
 * Timer for the screamming process.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientOnScreaming(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Validate client
    if(clientIndex)
    {
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];

        // Gets client's origin
        GetClientAbsOrigin(clientIndex, vEntPosition); vEntPosition[2] += 25.0;

        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i) && ((ZP_IsPlayerHuman(i) && !ZP_IsPlayerSurvivor(i)) || (ZP_IsPlayerSurvivor(i) && ZOMBIE_CLASS_SKILL_SURVIVOR)))
            {
                // Gets victim's origin
                GetClientAbsOrigin(i, vVictimPosition);

                // Calculate the distance
                float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                // Validate distance
                if(flDistance <= ZOMBIE_CLASS_SKILL_RADIUS)
                {            
                    // Apply damage
                    SDKHooks_TakeDamage(i, clientIndex, clientIndex, ZOMBIE_CLASS_SKILL_DAMAGE, DMG_BURN);
                }
            }
        }

        // Create a beamring effect                                   <Diameter>
        TE_SetupBeamRingPoint(vEntPosition, 50.0, FloatMul(SquareRoot(ZOMBIE_CLASS_SKILL_RADIUS), 2.0), decalTrail, decalHalo, 1, 10, 1.0, 15.0, 0.0, ZOMBIE_CLASS_SKILL_COLOR, 50, 0);
        TE_SendToAll();

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    Task_ZombieScream[clientIndex] = INVALID_HANDLE;

    // Destroy timer
    return Plugin_Stop;
}
