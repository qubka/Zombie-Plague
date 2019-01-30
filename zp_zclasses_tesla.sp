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
#define ZOMBIE_CLASS_SKILL_RADIUS_F          "300.0"
#define ZOMBIE_CLASS_SKILL_DURATION_F        0.1
#define ZOMBIE_CLASS_SKILL_TIME_F            0.2
#define ZOMBIE_CLASS_SKILL_SHAKE_AMP         2.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY   1.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_DURATION    0.1
#define ZOMBIE_CLASS_SKILL_RADIUS            300.0
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
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook player events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
    }
}

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
 * Event callback (player_death)
 * @brief Client has been killed.
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
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Initialize vectors
        static float vPosition[3]; 

        // Gets client eye position
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
            DispatchKeyValue(entityIndex, "m_flRadius", ZOMBIE_CLASS_SKILL_RADIUS_F);  
            DispatchKeyValue(entityIndex, "m_SoundName", "DoSpark");  
            DispatchKeyValue(entityIndex, "beamcount_min", "15");  
            DispatchKeyValue(entityIndex, "beamcount_max", "25");
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

            // Initialize time char
            static char sTime[SMALL_LINE_LENGTH];
            FormatEx(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", ZP_GetClassSkillDuration(gZombie));

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
public Action ClientOnHallucination(const Handle hTimer, const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Validate client
    if(clientIndex)
    {
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];

        // Gets client origin
        GetClientAbsOrigin(clientIndex, vEntPosition);

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
                if(flDistance <= ZOMBIE_CLASS_SKILL_RADIUS)
                {            
                    // Initialize color
                    static int vColor[4];
                    
                    // Generate color
                    vColor[0] = GetRandomInt(50, 200);
                    vColor[1] = GetRandomInt(50, 200);
                    vColor[2] = GetRandomInt(50, 200);
                    vColor[3] = GetRandomInt(200, 230);

                    // Create an fade
                    ZP_CreateFadeScreen(i, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, 0x0001, vColor);
                    
                    // Create a shake
                    ZP_CreateShakeScreen(i, ZOMBIE_CLASS_SKILL_SHAKE_AMP, ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY, ZOMBIE_CLASS_SKILL_SHAKE_DURATION);
                }
            }
        }

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    Task_ZombieHallucination[clientIndex] = null;

    // Destroy timer
    return Plugin_Stop;
}
