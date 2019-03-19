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
    name            = "[ZP] ExtraItem: HolyGrenade",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_HOLY_RADIUS            300.0         // Holy size (radius)
#define GRENADE_HOLY_IGNITE_TIME       5.0           // Ignite duration
#define GRENADE_HOLY_SHAKE_AMP         2.0           // Amplutude of the shake effect
#define GRENADE_HOLY_SHAKE_FREQUENCY   1.0           // Frequency of the shake effect
#define GRENADE_HOLY_SHAKE_DURATION    3.0           // Duration of the shake effect in seconds
#define GRENADE_HOLY_EXP_TIME          2.0           // Duration of the explosion effect in seconds
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define GLASS_GIBS_AMOUNT               5.0
#define GLASS_GIBS_DELAY                0.05
#define GLASS_GIBS_SPEED                500.0
#define GLASS_GIBS_VARIENCE             1.0  
#define GLASS_GIBS_LIFE                 1.0  
#define GLASS_GIBS_DURATION             2.0
/**
 * @endsection
 **/
 
// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook entity events
        HookEvent("hegrenade_detonate", EventEntityNapalm, EventHookMode_Post);
        
        // Hooks server sounds
        AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("holy grenade");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"holy grenade\" wasn't find");

    // Weapons
    gWeapon = ZP_GetWeaponNameID("holy grenade");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"holy grenade\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("HOLY_GRENADE_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HOLY_GRENADE_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
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
 * @brief Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, gWeapon);
    }
}

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflicter index.
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflicterIndex, float &flDamage, int &iBits, int &weaponIndex)
{
    // Client was damaged by 'explosion'
    if(iBits & DMG_BLAST)
    {
        // Validate inflicter
        if(IsValidEdict(inflicterIndex))
        {
            // Validate custom grenade
            if(ZP_GetWeaponID(inflicterIndex) == gWeapon)
            {
                // Reset explosion damage
                flDamage *= ZP_IsPlayerZombie(attackerIndex) ? 0.0 : ZP_GetWeaponDamage(gWeapon);
            }
        }
    }
}

/**
 * Event callback (hegrenade_detonate)
 * @brief The hegrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityNapalm(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Gets real player index from event key
    ///int ownerIndex = GetClientOfUserId(hEvent.GetInt("userid")); 

    // Initialize vectors
    static float vEntPosition[3]; static float vVictimPosition[3]; static float vVelocity[3];

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
                // Validate zombie
                if(IsPlayerExist(i) && ZP_IsPlayerZombie(i))
                {
                    // Gets victim origin
                    GetClientAbsOrigin(i, vVictimPosition);
                    
                    // Calculate the distance
                    float flDistance = GetVectorDistance(vEntPosition, vVictimPosition);
                    
                    // Validate distance
                    if(flDistance <= GRENADE_HOLY_RADIUS)
                    {
                        // Put the fire on
                        IgniteEntity(i, GRENADE_HOLY_IGNITE_TIME);   
                
                        // Calculate the velocity vector
                        SubtractVectors(vVictimPosition, vEntPosition, vVelocity);
                
                        // Create a knockback
                        ZP_CreateRadiusKnockBack(i, vVelocity, flDistance, ZP_GetWeaponKnockBack(gWeapon), GRENADE_HOLY_RADIUS);
                        
                        // Create a shake
                        ZP_CreateShakeScreen(i, GRENADE_HOLY_SHAKE_AMP, GRENADE_HOLY_SHAKE_FREQUENCY, GRENADE_HOLY_SHAKE_DURATION);
                    }
                }
            }
            
            // Create a info_target entity
            int infoIndex = ZP_CreateEntity(vEntPosition, GRENADE_HOLY_EXP_TIME);

            // Validate entity
            if(infoIndex != INVALID_ENT_REFERENCE)
            {
                // Create an explosion effect
                ZP_CreateParticle(infoIndex, vEntPosition, _, "explosion_hegrenade_water", GRENADE_HOLY_EXP_TIME);
            }
    
        }
    }
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
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
        // Validate custom grenade
        if(ZP_GetWeaponID(entityIndex) == gWeapon)
        {
            // Initialize sound char
            static char sSound[PLATFORM_LINE_LENGTH];

            // Validate sound
            if(!strncmp(sSample[23], "bounce", 6, false))
            {
                // Emit a custom bounce sound
                ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
                EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            else if(!strncmp(sSample[20], "explode", 7, false))
            {
                // Emit explosion sound
                ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
                EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }

            // Block sounds
            return Plugin_Stop; 
        }
    }
    
    // Allow sounds
    return Plugin_Continue;
}