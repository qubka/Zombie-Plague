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
    name            = "[ZP] Weapon: Freeze",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_FREEZE_TIME           GetRandomFloat(3.0, 5.0)  // Freeze duration in seconds
#define GRENADE_FREEZE_RADIUS         200.0                     // Freeze size (radius)
#define GRENADE_FREEZE_EXP_TIME       2.0                       // Duration of the explosion effect in seconds
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define GLASS_GIBS_AMOUNT             5.0
#define GLASS_GIBS_DELAY              0.05
#define GLASS_GIBS_SPEED              500.0
#define GLASS_GIBS_VARIENCE           1.0  
#define GLASS_GIBS_LIFE               1.0  
#define GLASS_GIBS_DURATION           2.0
/**
 * @endsection
 **/
 
// Timer index
Handle hZombieFreezed[MAXPLAYERS+1] = null; 

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Item index
int gWeapon;
#pragma unused gWeapon

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if (!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook entity events
        HookEvent("smokegrenade_detonate", EventEntitySmoke, EventHookMode_Post);

        // Hook server sounds
        AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
        
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
    // Weapons
    gWeapon = ZP_GetWeaponNameID("freeze grenade");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"freeze grenade\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("FREEZE_GRENADE_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"FREEZE_GRENADE_SOUNDS\" wasn't find");
   
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
    PrecacheModel("models/gibs/glass_shard01.mdl", true);
    PrecacheModel("models/gibs/glass_shard02.mdl", true);
    PrecacheModel("models/gibs/glass_shard03.mdl", true);
    PrecacheModel("models/gibs/glass_shard04.mdl", true);
    PrecacheModel("models/gibs/glass_shard05.mdl", true);
    PrecacheModel("models/gibs/glass_shard06.mdl", true);
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
        hZombieFreezed[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete hZombieFreezed[client];
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
    delete hZombieFreezed[client];
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
    delete hZombieFreezed[client];
}

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon)
{
    // If the client is frozen, then stop
    if (GetEntityMoveType(client) == MOVETYPE_NONE) flDamage = 0.0;
}

/**
 * Event callback (smokegrenade_detonate)
 * @brief The smokegrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntitySmoke(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets real player index from event key
    ///int owner = GetClientOfUserId(hEvent.GetInt("userid")); 

    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vEnemy[3];

    // Gets all required event info
    int grenade = hEvent.GetInt("entityid");
    vPosition[0] = hEvent.GetFloat("x"); 
    vPosition[1] = hEvent.GetFloat("y"); 
    vPosition[2] = hEvent.GetFloat("z");
    
    // Validate entity
    if (IsValidEdict(grenade))
    {
        // Validate custom grenade
        if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)
        {
            // Find any players in the radius
            int i; int it = 1; /// iterator
            while ((i = ZP_FindPlayerInSphere(it, vPosition, GRENADE_FREEZE_RADIUS)) != -1)
            {
                // Skip humans
                if (ZP_IsPlayerHuman(i))
                {
                    continue;
                }
                
                // Freeze the client
                SetEntityMoveType(i, MOVETYPE_NONE);

                // Create an effect
                GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
                UTIL_CreateParticle(i, vEnemy, _, _, "dynamic_smoke5", GRENADE_FREEZE_TIME+0.5);

                // Create timer for removing freezing
                delete hZombieFreezed[i];
                hZombieFreezed[i] = CreateTimer(GRENADE_FREEZE_TIME, ClientRemoveFreezeEffect, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);

                // Randomize pitch
                vAngle[1] = GetRandomFloat(0.0, 360.0);
       
                // Create a prop_dynamic_override entity
                int ice = UTIL_CreateDynamic("ice", vEnemy, vAngle, "models/player/custom_player/zombie/ice/ice.mdl", "idle");

                // Validate entity
                if (ice != -1)
                {
                    // Kill after some duration
                    UTIL_RemoveEntity(ice, GRENADE_FREEZE_TIME);
                    
                    // Play sound
                    ZP_EmitSoundToAll(gSound, 1, ice, SNDCHAN_STATIC, hSoundLevel.IntValue);
                }
            }

            // Create an explosion effect
            UTIL_CreateParticle(_, vPosition, _, _, "explosion_hegrenade_snow", GRENADE_FREEZE_EXP_TIME);
            
            // Create sparks splash effect
            TE_SetupSparks(vPosition, NULL_VECTOR, 5000, 1000);
            TE_SendToAll();
            
            // Remove grenade
            AcceptEntityInput(grenade, "Kill");
        }
    }
}

/**
 * @brief Timer for the remove freeze effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveFreezeEffect(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID);
    
    // Clear timer 
    hZombieFreezed[client] = null;

    // Validate client
    if (client)
    {
        // Initialize vectors
        static float vGib[3]; float vShoot[3]; 

        // Unfreeze the client
        SetEntityMoveType(client, MOVETYPE_WALK);
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_VOICE, hSoundLevel.IntValue);

        // Create a breaked glass effect
        static char sBuffer[NORMAL_LINE_LENGTH];
        for (int x = 0; x <= 5; x++)
        {
            // Find gib positions
            vShoot[1] += 60.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
            {
                case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard01.mdl");
                case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard02.mdl");
                case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard03.mdl");
                case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard04.mdl");
                case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard05.mdl");
                case 5 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard06.mdl");
            }
        
            // Create gibs
            UTIL_CreateShooter(client, "eholster", _, MAT_GLASS, _, sBuffer, vShoot, vGib, GLASS_GIBS_AMOUNT, GLASS_GIBS_DELAY, GLASS_GIBS_SPEED, GLASS_GIBS_VARIENCE, GLASS_GIBS_LIFE, GLASS_GIBS_DURATION);
        }
    }
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value if you add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entity            Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFlags            The sound flags.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags)
{
    // Validate client
    if (IsValidEdict(entity))
    {
        // Validate custom grenade
        if (GetEntProp(entity, Prop_Data, "m_iHammerID") == gWeapon)
        {
            // Validate sound
            if (!strncmp(sSample[31], "hit", 3, false))
            {
                // Play sound
                ZP_EmitSoundToAll(gSound, GetRandomInt(4, 6), entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
                
                // Block sounds
                return Plugin_Stop; 
            }
            else if (!strncmp(sSample[29], "emit", 4, false))
            {
                // Play sound
                ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
               
                // Block sounds
                return Plugin_Stop; 
            }
        }
    }
    
    // Allow sounds
    return Plugin_Continue;
}