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
#include <cstrike>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: DroneGun",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_DRONE_HEALTH        500
#define WEAPON_DRONE_MULTIPLIER    3.0
/**
 * @endsection
 **/
 
// Item index
int gItem;
#pragma unused gItem

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("drone gun");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"drone gun\" wasn't find");
    
    // Sounds
    PrecacheSound("sound/survival/turret_death_01.wav", true);
    PrecacheSound("sound/survival/turret_idle_01.wav", true);
    PrecacheSound("sound/survival/turret_takesdamage_01.wav", true);
    PrecacheSound("sound/survival/turret_takesdamage_02.wav", true);
    PrecacheSound("sound/survival/turret_takesdamage_03.wav", true);
    PrecacheSound("sound/survival/turret_lostplayer_01.wav", true);
    PrecacheSound("sound/survival/turret_lostplayer_02.wav", true);
    PrecacheSound("sound/survival/turret_lostplayer_03.wav", true);
    PrecacheSound("sound/survival/turret_sawplayer_01.wav", true);
    
    // Models
    PrecacheModel("models/props_survival/dronegun/dronegun.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib1.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib2.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib3.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib4.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib5.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib6.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib7.mdl", true);
    PrecacheModel("models/props_survival/dronegun/dronegun_gib8.mdl", true);
}

/**
 * Called before show an extraitem in the equipment menu.
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
        // Validate class
        if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
        {
            return Plugin_Stop;
        }
    }

    // Allow showing
    return Plugin_Continue;
}

/**
 * Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    { 
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3];
        
        // Gets the weapon position
        ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 0.0, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 150.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter);

        // Validate collisions
        if(TR_DidHit(hTrace) && TR_GetEntityIndex(hTrace) < 1)
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vPosition, hTrace);
            
            // Shift position
            vPosition[2] += 15.0;
            
            // Create a dronegun entity
            int entityIndex = CreateEntityByName("dronegun"); 

            // Validate entity
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Spawn the entity
                DispatchSpawn(entityIndex);

                // Teleport the turret
                TeleportEntity(entityIndex, vPosition, NULL_VECTOR, NULL_VECTOR);
                
                // Sets the parent for the entity
                SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);

                // Sets the health     
                SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
                SetEntProp(entityIndex, Prop_Data, "m_iHealth", WEAPON_DRONE_HEALTH);
                SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", WEAPON_DRONE_HEALTH);
                
                // Create damage hook
                SDKHook(entityIndex, SDKHook_OnTakeDamage, DroneDamageHook);
            }
        }
        else
        {
            // Give ammopakcs back
            ZP_SetClientAmmoPack(clientIndex, ZP_GetClientAmmoPack(clientIndex) + ZP_GetWeaponCost(gItem));
        }

        // Close the trace
        delete hTrace;
    }
}

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflictorIndex, float &damageAmount, int &damageType, int &weaponIndex)
{
    // Validate attacker
    if(IsValidEdict(inflictorIndex))
    {
        // Gets classname of the inflictor
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(inflictorIndex, sClassname, sizeof(sClassname));

        // If entity is a turret, then block damage
        if(!strcmp(sClassname, "env_gunfire", false))
        {
            // Multiply damage
            damageAmount *= ZP_IsPlayerZombie(clientIndex) ? WEAPON_DRONE_MULTIPLIER : 0.0;
        }
    }
}

/**
 * Drone damage hook.
 *
 * @param entityIndex       The entity index.    
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damageAmount      The damage amount.
 * @param damageType        The damage type.
 **/
public Action DroneDamageHook(const int entityIndex, int &attackerIndex, int &inflictorIndex, float &damageAmount, int &damageType)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Validate zombie
        if(IsPlayerExist(attackerIndex) && ZP_IsPlayerZombie(attackerIndex))
        {
            // Calculate the damage
            int healthAmount = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToCeil(damageAmount); healthAmount = (healthAmount > 0) ? healthAmount : 0;

            // Destroy entity
            if(!healthAmount)
            {
                // Destroy damage hook
                SDKUnhook(entityIndex, SDKHook_OnTakeDamage, DroneDamageHook);
            }
            else
            {
                // Apply damage
                SetEntProp(entityIndex, Prop_Data, "m_iHealth", healthAmount);
            }
        }
    }

    // Return on success
    return Plugin_Handled;
}

/**
 * Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @return                  True or false.
 **/
public bool TraceFilter(const int entityIndex, const int contentsMask)
{
    return !(1 <= entityIndex <= MaxClients);
}