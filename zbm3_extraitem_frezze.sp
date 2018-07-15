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
    name            = "[ZP] ExtraItem: Freeze",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_REFERENCE          "FreezeNade" // Name in weapons.ini
#define EXTRA_ITEM_NAME               "Freeze Grenade" // Only will be taken from translation file        
#define EXTRA_ITEM_COST               5
#define EXTRA_ITEM_LEVEL              0
#define EXTRA_ITEM_ONLINE             0
#define EXTRA_ITEM_LIMIT              0
/**
 * @endsection
 **/
 
/**
 * @section Properties of the grenade.
 **/
#define GRENADE_FREEZE_TIME           4.0     // Freeze duration in seconds
#define GRENADE_FREEZE_RADIUS         40000.0 // Freeze size (radius) [squared]
#define GRENADE_FREEZE_NEMESIS        false   // Can nemesis freezed [false-no // true-yes]
#define GRENADE_FREEZE_EXP_TIME       2.0     // Duration of the explosion effect in seconds
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
 
// Initialize variables
Handle Task_ZombieFreezed[MAXPLAYERS+1] = INVALID_HANDLE; 

// ConVar for sound level
ConVar hSoundLevel;

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook entity events
        HookEvent("smokegrenade_detonate", EventEntitySmoke, EventHookMode_Post);

        // Hook player events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);

        // Initilizate extra item
        gItem = ZP_RegisterExtraItem(EXTRA_ITEM_NAME, EXTRA_ITEM_COST, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT);
    }
}

/**
 * Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
    // Hooks server sounds
    AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initilizate weapon
    gWeapon = ZP_GetWeaponNameID(EXTRA_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", EXTRA_ITEM_REFERENCE);

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
        Task_ZombieFreezed[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete Task_ZombieFreezed[clientIndex];
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
    delete Task_ZombieFreezed[GetClientOfUserId(hEvent.GetInt("userid"))];
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);

    // Delete timer
    delete Task_ZombieFreezed[clientIndex];
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientHumanized(int clientIndex)
{
    // Reset move
    SetEntityMoveType(clientIndex, MOVETYPE_WALK);

    // Delete timer
    delete Task_ZombieFreezed[clientIndex];
}

/**
 * Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item's index
    if(extraitemIndex == gItem)
    {
        // Validate class
        if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
        {
            return Plugin_Stop;
        }
        
        // Validate access
        if(ZP_IsPlayerHasWeapon(clientIndex, gWeapon))
        {
            return Plugin_Handled;
        }
    }

    // Allow showing
    return Plugin_Continue;
}

/**
 * Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item's index
    if(extraitemIndex == gItem)
    { 
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, EXTRA_ITEM_REFERENCE);
    }
}

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The ditfield of damage types
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount, int damageType)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // Client was damaged by 'bullet'
    if(damageType & DMG_NEVERGIB)
    {
        // If the client is frozen, then stop
        if(GetEntityMoveType(clientIndex) == MOVETYPE_NONE) damageAmount *= 0.0;
    }
}

/**
 * Event callback (smokegrenade_detonate)
 * The smokegrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntitySmoke(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets real player index from event key
    ///int ownerIndex = GetClientOfUserId(hEvent.GetInt("userid")); 

    // Initialize vectors
    static float vEntPosition[3]; static float vVictimPosition[3]; static float vVictimAngle[3];

    // Gets all required event info
    int grenadeIndex = hEvent.GetInt("entityid");
    vEntPosition[0] = hEvent.GetFloat("x"); 
    vEntPosition[1] = hEvent.GetFloat("y"); 
    vEntPosition[2] = hEvent.GetFloat("z");
    
    // Validate entity
    if(IsValidEdict(grenadeIndex))
    {
        // Validate custom grenade
        if(ZP_GetWeaponID(grenadeIndex) == gWeapon)
        {
            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if(IsPlayerExist(i) && ((ZP_IsPlayerZombie(i) && !ZP_IsPlayerNemesis(i)) || (ZP_IsPlayerNemesis(i) && GRENADE_FREEZE_NEMESIS)))
                {
                    // Gets victim's origin
                    GetClientAbsOrigin(i, vVictimPosition);

                    // Gets victim's origin angle
                    GetClientAbsAngles(i, vVictimAngle);

                    // Calculate the distance
                    float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                    // Validate distance
                    if(flDistance <= GRENADE_FREEZE_RADIUS)
                    {            
                        // Freeze the client
                        SetEntityMoveType(i, MOVETYPE_NONE);

                        // Create an effect
                        FakeCreateParticle(i, _, "dynamic_smoke5", GRENADE_FREEZE_TIME+0.5);

                        // Create timer for removing freezing
                        delete Task_ZombieFreezed[i];
                        Task_ZombieFreezed[i] = CreateTimer(GRENADE_FREEZE_TIME, ClientRemoveFreezeEffect, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);

                        // Create a prop_dynamic_override entity
                        int iceIndex = CreateEntityByName("prop_dynamic_override");

                        // Validate entity
                        if(iceIndex != INVALID_ENT_REFERENCE)
                        {
                            // Dispatch main values of the entity
                            DispatchKeyValue(iceIndex, "model", "models/player/custom_player/zombie/ice/ice.mdl");
                            DispatchKeyValue(iceIndex, "spawnflags", "256"); /// Start with collision disabled
                            DispatchKeyValue(iceIndex, "solid", "0");
                            
                            // Spawn the entity
                            DispatchSpawn(iceIndex);
                            TeleportEntity(iceIndex, vVictimPosition, vVictimAngle, NULL_VECTOR);

                            // Initialize char
                            static char sTime[SMALL_LINE_LENGTH];
                            Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", GRENADE_FREEZE_TIME);

                            // Sets modified flags on entity
                            SetVariantString(sTime);
                            AcceptEntityInput(iceIndex, "AddOutput");
                            AcceptEntityInput(iceIndex, "FireUser1");
                            
                            // Emit freeze sound
                            EmitSoundToAll("*/zbm3/freeze.mp3", iceIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                        }
                    }
                }
            }
             
            // Create a info_target entity
            int infoIndex = FakeCreateEntity(vEntPosition, GRENADE_FREEZE_EXP_TIME);

            // Validate entity
            if(IsValidEdict(infoIndex))
            {
                // Create an explosion effect
                FakeCreateParticle(infoIndex, _, "explosion_hegrenade_snow", GRENADE_FREEZE_EXP_TIME);
            }
            
            // Create sparks splash effect
            TE_SetupSparks(vEntPosition, NULL_VECTOR, 5000, 1000);
            TE_SendToAll();
            
            // Remove grenade
            AcceptEntityInput(grenadeIndex, "Kill");
        }
    }
}

/**
 * Timer for the remove freeze effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveFreezeEffect(Handle hTimer, int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);
    
    // Clear timer 
    Task_ZombieFreezed[clientIndex] = INVALID_HANDLE;

    // Validate client
    if(clientIndex)
    {
        // Initialize vectors
        float vEntPosition[3]; static float vEntAngle[3];

        // Unfreeze the client
        SetEntityMoveType(clientIndex, MOVETYPE_WALK);
        
        // Emit sound
        EmitSoundToAll("*/zbm3/zombi_wood_broken.mp3", clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);

        // Create a breaked glass effect
        static char sModel[NORMAL_LINE_LENGTH];
        for(int x = 0; x <= 5; x++)
        {
            // Find gib positions
            vEntPosition[1] += 60.0; vEntAngle[0] = GetRandomFloat(0.0, 360.0); vEntAngle[1] = GetRandomFloat(-15.0, 15.0); vEntAngle[2] = GetRandomFloat(-15.0, 15.0); switch(x)
            {
                case 0 : strcopy(sModel, sizeof(sModel), "models/gibs/glass_shard01.mdl");
                case 1 : strcopy(sModel, sizeof(sModel), "models/gibs/glass_shard02.mdl");
                case 2 : strcopy(sModel, sizeof(sModel), "models/gibs/glass_shard03.mdl");
                case 3 : strcopy(sModel, sizeof(sModel), "models/gibs/glass_shard04.mdl");
                case 4 : strcopy(sModel, sizeof(sModel), "models/gibs/glass_shard05.mdl");
                case 5 : strcopy(sModel, sizeof(sModel), "models/gibs/glass_shard06.mdl");
            }
        
            // Create a shooter entity
            int entityIndex = CreateEntityByName("env_shooter");

            // If entity isn't valid, then skip
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Dispatch main values of the entity
                DispatchKeyValueVector(entityIndex, "angles", vEntPosition);
                DispatchKeyValueVector(entityIndex, "gibangles", vEntAngle);
                DispatchKeyValue(entityIndex, "rendermode", "5");
                DispatchKeyValue(entityIndex, "shootsounds", "0");  PrecacheModel(sModel); //! Prevent errors 
                DispatchKeyValue(entityIndex, "shootmodel", sModel);
                DispatchKeyValueFloat(entityIndex, "m_iGibs", GLASS_GIBS_AMOUNT);
                DispatchKeyValueFloat(entityIndex, "delay", GLASS_GIBS_DELAY);
                DispatchKeyValueFloat(entityIndex, "m_flVelocity", GLASS_GIBS_SPEED);
                DispatchKeyValueFloat(entityIndex, "m_flVariance", GLASS_GIBS_VARIENCE);
                DispatchKeyValueFloat(entityIndex, "m_flGibLife", GLASS_GIBS_LIFE);

                // Spawn the entity into the world
                DispatchSpawn(entityIndex);

                // Activate the entity
                ActivateEntity(entityIndex);  
                AcceptEntityInput(entityIndex, "Shoot");

                // Sets parent to the client
                SetVariantString("!activator"); 
                AcceptEntityInput(entityIndex, "SetParent", clientIndex, entityIndex); 

                // Sets attachment to the client
                SetVariantString("eholster"); 
                AcceptEntityInput(entityIndex, "SetParentAttachment", clientIndex, entityIndex);

                // Initialize char
                static char sTime[SMALL_LINE_LENGTH];
                Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", GLASS_GIBS_DURATION);

                // Sets modified flags on the entity
                SetVariantString(sTime);
                AcceptEntityInput(entityIndex, "AddOutput");
                AcceptEntityInput(entityIndex, "FireUser1");
            }
        }
    }
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client's indexes.
 * @param numClients        Number of clients in the array (modify this value if you add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entityIndex       Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFlags            The sound flags.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &entityIndex, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags)
{
    // Validate client
    if(IsValidEdict(entityIndex))
    {
        // Gets the entity's classname
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(entityIndex, sClassname, sizeof(sClassname));

        // Validate grenade
        if(!strncmp(sClassname, "smokegrenade_", 13, false))
        {
            if(!strncmp(sSample[31], "hit", 3, false))
            {
                // Emit a custom bounce sound
                EmitSoundToAll("*/zbm3/freeze_bounce-1.mp3", entityIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            }
            else if(!strncmp(sSample[29], "emit", 4, false))
            {
                // Emit explosion sound
                EmitSoundToAll("*/zbm3/freeze_exp.mp3", entityIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            }

            // Block sounds
            return Plugin_Stop; 
        }
    }
    
    // Allow sounds
    return Plugin_Continue;
}
