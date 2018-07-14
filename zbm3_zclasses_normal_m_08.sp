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
public Plugin ZombieClassNormalM08 =
{
    name            = "[ZP] Zombie Class: NormalM08",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "NormalM08" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "NormalM08Info" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/normal_m_08/normal_m_08.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/normal_m_08/hand_v2/hand_zombie_normal_m_08.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/normal_m_08/grenade/grenade_normal_m_08.mdl"    
#define ZOMBIE_CLASS_HEALTH             6000
#define ZOMBIE_CLASS_SPEED              1.0
#define ZOMBIE_CLASS_GRAVITY            0.9
#define ZOMBIE_CLASS_KNOCKBACK          1.0
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_VIP                NO
#define ZOMBIE_CLASS_DURATION           5.0    
#define ZOMBIE_CLASS_COUNTDOWN          30.0
#define ZOMBIE_CLASS_REGEN_HEALTH       300
#define ZOMBIE_CLASS_REGEN_INTERVAL     4.0
#define ZOMBIE_CLASS_SKILL_RADIUS       90000.0 // [squared]
#define ZOMBIE_CLASS_SKILL_SURVIVOR     false
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_REGEN_SOUNDS"
#define ZOMBIE_CLASS_EFFECT_RADIUS            "300.0"
#define ZOMBIE_CLASS_EFFECT_DURATION_F        0.1
#define ZOMBIE_CLASS_EFFECT_TIME_F            0.2
#define ZOMBIE_CLASS_EFFECT_SHAKE_AMP         2.0           
#define ZOMBIE_CLASS_EFFECT_SHAKE_FREQUENCY   1.0           
#define ZOMBIE_CLASS_EFFECT_SHAKE_DURATION    0.1
/**
 * @endsection
 **/

// Initialize variables
Handle Task_ZombieHallucination[MAXPLAYERS+1] = INVALID_HANDLE; 

// ConVar for sound level
ConVar hSoundLevel;

// Initialize zombie class index
int gZombieNormalM08;
#pragma unused gZombieNormalM08

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

        // Initilizate zombie class
        gZombieNormalM08 = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
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
        Task_ZombieHallucination[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete Task_ZombieHallucination[clientIndex];
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
    delete Task_ZombieHallucination[GetClientOfUserId(hEvent.GetInt("userid"))];
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
    delete Task_ZombieHallucination[clientIndex];
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientHumanized(int clientIndex)
{
    // Delete timer
    delete Task_ZombieHallucination[clientIndex];
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
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
    if(ZP_GetClientZombieClass(clientIndex) == gZombieNormalM08)
    {
        // Emit sound
        EmitSoundToAll("*/zbm3/td_debuff.mp3", clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
    
        // Initialize vectors
        static float vPosition[3]; 

        // Gets the client's eye position
        GetClientEyePosition(clientIndex, vPosition); vPosition[2] += 40.0;

        // Create hallucination task
        delete Task_ZombieHallucination[clientIndex];
        Task_ZombieHallucination[clientIndex] = CreateTimer(0.1, ClientOnHallucination, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

        // Create a tesla entity
        int entityIndex = CreateEntityByName("point_tesla");

        // If entity isn't valid, then skip
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValueVector(entityIndex, "origin", vPosition);
            DispatchKeyValue(entityIndex, "m_flRadius", ZOMBIE_CLASS_EFFECT_RADIUS);  
            DispatchKeyValue(entityIndex, "m_SoundName", "DoSpark");  
            DispatchKeyValue(entityIndex, "beamcount_min", "15");  
            DispatchKeyValue(entityIndex, "beamcount_max", "25");  PrecacheModel("materials/sprites/physbeam.vmt"); //! Prevent errors 
            DispatchKeyValue(entityIndex, "texture", "materials/sprites/physbeam.vmt");  
            DispatchKeyValue(entityIndex, "m_Color", "255 255 255");  
            DispatchKeyValue(entityIndex, "thick_min", "7.0");     
            DispatchKeyValue(entityIndex, "thick_max", "9.0");     
            DispatchKeyValue(entityIndex, "lifetime_min", "0.3");  
            DispatchKeyValue(entityIndex, "lifetime_max", "0.3");  
            DispatchKeyValue(entityIndex, "interval_min", "0.1");     
            DispatchKeyValue(entityIndex, "interval_max", "0.2");   

            // Spawn the entity into the world
            DispatchSpawn(entityIndex);

            // Activate the entity
            ActivateEntity(entityIndex);
            AcceptEntityInput(entityIndex, "TurnOn");     
            AcceptEntityInput(entityIndex, "DoSpark");    

            // Sets parent to the entity
            SetVariantString("!activator"); 
            AcceptEntityInput(entityIndex, "SetParent", clientIndex, entityIndex); 

            // Initialize char
            static char sTime[SMALL_LINE_LENGTH];
            Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", ZOMBIE_CLASS_DURATION);

            // Sets modified flags on the entity
            SetVariantString(sTime);
            AcceptEntityInput(entityIndex, "AddOutput");
            AcceptEntityInput(entityIndex, "FireUser1");
        }
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
    if(ZP_GetClientZombieClass(clientIndex) == gZombieNormalM08) 
    {
        // Delete timer
        delete Task_ZombieHallucination[clientIndex];
    }
}

/**
 * Timer for the hallucination process.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientOnHallucination(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Validate client
    if(clientIndex)
    {
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];

        // Gets client's origin
        GetClientAbsOrigin(clientIndex, vEntPosition);

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
                    // Initialize variable
                    static int vColor[4];
                    
                    // Generate color
                    vColor[0] = GetRandomInt(50, 200);
                    vColor[1] = GetRandomInt(50, 200);
                    vColor[2] = GetRandomInt(50, 200);
                    vColor[3] = GetRandomInt(200, 230);

                    // Create an fade
                    FakeCreateFadeScreen(i, ZOMBIE_CLASS_EFFECT_DURATION_F, ZOMBIE_CLASS_EFFECT_TIME_F, 0x0001, vColor);
                    
                    // Create a shake
                    FakeCreateShakeScreen(i, ZOMBIE_CLASS_EFFECT_SHAKE_AMP, ZOMBIE_CLASS_EFFECT_SHAKE_FREQUENCY, ZOMBIE_CLASS_EFFECT_SHAKE_DURATION);
                }
            }
        }

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    Task_ZombieHallucination[clientIndex] = INVALID_HANDLE;

    // Destroy timer
    return Plugin_Stop;
}
