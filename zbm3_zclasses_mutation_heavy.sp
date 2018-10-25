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
    name            = "[ZP] Zombie Class: MutationHeavy",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "mutationheavy" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "mutationheavy info" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/mutation_heavy/mutation_heavy.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/mutation_heavy/hand_v2/hand_zombie_mutation_heavy.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/mutation_heavy/grenade/grenade_mutation_heavy.mdl"    
#define ZOMBIE_CLASS_HEALTH             6000
#define ZOMBIE_CLASS_SPEED              0.8
#define ZOMBIE_CLASS_GRAVITY            1.1
#define ZOMBIE_CLASS_KNOCKBACK          0.5
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_GROUP              ""
#define ZOMBIE_CLASS_DURATION           5.0    
#define ZOMBIE_CLASS_COUNTDOWN          30.0
#define ZOMBIE_CLASS_REGEN_HEALTH       500
#define ZOMBIE_CLASS_REGEN_INTERVAL     5.0
#define ZOMBIE_CLASS_SKILL_SURVIVOR     false
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

// Timer index
Handle Task_HumanTrapped[MAXPLAYERS+1] = INVALID_HANDLE;  bool bStandOnTrap[MAXPLAYERS+1];

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
        // Hook player events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);

        // Initialize zombie class
        gZombie = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
        ZOMBIE_CLASS_INFO,
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW,  
        ZOMBIE_CLASS_GRENADE,
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_GROUP, 
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
    gSound = ZP_GetSoundKeyID("TRAP_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TRAP_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
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
        Task_HumanTrapped[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete Task_HumanTrapped[clientIndex];
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
    delete Task_HumanTrapped[GetClientOfUserId(hEvent.GetInt("userid"))];
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param nemesisMode       Indicates that client will be a nemesis.
 * @param respawnMode       Indicates that infection was on spawn.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex, bool nemesisMode, bool respawnMode)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    
    // Delete timer
    delete Task_HumanTrapped[clientIndex];
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 * @param survivorMode      Indicates that client will be a survivor.
 * @param respawnMode       Indicates that humanizing was on spawn.
 **/
public void ZP_OnClientHumanized(int clientIndex, bool survivorMode, bool respawnMode)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    
    // Delete timer
    delete Task_HumanTrapped[clientIndex];
}
/**
 * Called when a client use a skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_IsPlayerZombie(clientIndex) && ZP_GetClientZombieClass(clientIndex) == gZombie)
    {
        // Validate place
        if(bStandOnTrap[clientIndex])
        {
            bStandOnTrap[clientIndex] = false; /// To avoid placing trap on the trap
            return Plugin_Handled;
        }
        
        // Initialize vectors
        static float vPosition[3];
        
        // Gets the client position
        GetClientAbsOrigin(clientIndex, vPosition);
        
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a trap entity
        int entityIndex = CreateEntityByName("prop_physics_multiplayer"); 

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", "models/player/custom_player/zombie/ice/ice.mdl");
            DispatchKeyValue(entityIndex, "spawnflags", "8834"); /// Don't take physics damage | Not affected by rotor wash | Prevent pickup | Force server-side
            
            // Spawn the entity
            DispatchSpawn(entityIndex);
            
            // Teleport the trap
            TeleportEntity(entityIndex, vPosition, NULL_VECTOR, NULL_VECTOR);
            
            // Sets the physics
            SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
            SetEntProp(entityIndex, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); 
            SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
            SetEntityMoveType(entityIndex, MOVETYPE_NONE);

            // Sets an entity color
            SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
            SetEntityRenderColor(entityIndex, _, _, _, 0); 

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, TrapTouchHook);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Trap touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action TrapTouchHook(const int entityIndex, const int targetIndex)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Validate target
        if(IsPlayerExist(targetIndex))
        {
            // Validate human
            if(ZP_IsPlayerHuman(targetIndex) && GetEntityMoveType(targetIndex) != MOVETYPE_NONE && ((ZP_IsPlayerHuman(targetIndex) && !ZP_IsPlayerSurvivor(targetIndex)) || (ZP_IsPlayerSurvivor(targetIndex) && ZOMBIE_CLASS_SKILL_SURVIVOR)))
            {
                // Initialize vectors
                static float vPosition[3];

                // Gets victim origin
                GetClientAbsOrigin(targetIndex, vPosition);
                
                // Trap the client
                SetEntityMoveType(targetIndex, MOVETYPE_NONE);

                // Create timer for removing freezing
                delete Task_HumanTrapped[targetIndex];
                Task_HumanTrapped[targetIndex] = CreateTimer(ZOMBIE_CLASS_DURATION, ClientRemoveTrapEffect, GetClientUserId(targetIndex), TIMER_FLAG_NO_MAPCHANGE);

                // Emit sound
                static char sSound[PLATFORM_MAX_PATH];
                ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
                EmitSoundToAll(sSound, targetIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
                
                // Remove entity from world
                AcceptEntityInput(entityIndex, "Kill");

                // Create a prop_dynamic entity
                int trapIndex = CreateEntityByName("prop_dynamic");

                // Validate entity
                if(trapIndex != INVALID_ENT_REFERENCE)
                {
                    // Dispatch main values of the entity
                    DispatchKeyValue(trapIndex, "model", "models/player/custom_player/zombie/zombie_trap/trap.mdl");
                    DispatchKeyValue(trapIndex, "DefaultAnim", "trap");
                    DispatchKeyValue(trapIndex, "spawnflags", "256"); /// Start with collision disabled
                    DispatchKeyValue(trapIndex, "solid", "0");

                    // Spawn the entity
                    DispatchSpawn(trapIndex);
                    TeleportEntity(trapIndex, vPosition, NULL_VECTOR, NULL_VECTOR);

                    // Initialize variable
                    static char sTime[SMALL_LINE_LENGTH];
                    Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", ZOMBIE_CLASS_DURATION);

                    // Sets modified flags on entity
                    SetVariantString(sTime);
                    AcceptEntityInput(trapIndex, "AddOutput");
                    AcceptEntityInput(trapIndex, "FireUser1");
                }
            }
            //Validate zombie
            else if(ZP_IsPlayerZombie(targetIndex)) bStandOnTrap[targetIndex] = true; // Reset installing here!
        }
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * Timer for remove trap effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveTrapEffect(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_HumanTrapped[clientIndex] = INVALID_HANDLE;

    // Validate client
    if(clientIndex)
    {    
        // Untrap the client
        SetEntityMoveType(clientIndex, MOVETYPE_WALK);
    }

    // Destroy timer
    return Plugin_Stop;
}
