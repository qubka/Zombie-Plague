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
    name            = "[ZP] Zombie Class: Smoker",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_RADIUS       200.0
#define ZOMBIE_CLASS_SKILL_DAMAGE       5.0
#define ZOMBIE_CLASS_SKILL_DELAY        0.5
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
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if (!strcmp(sLibrary, "zombieplague", false))
    {
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
    // Classes
    gZombie = ZP_GetClassNameID("smoker");
    //if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"smoker\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("SMOKE_SKILL_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SMOKE_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                             (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
    // Validate the zombie class index
    if (ZP_GetClientClass(client) == gZombie)
    {
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Gets client origin
        static float vPosition[3];
        GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
        
        // Create a smoke effect
        int entity = UTIL_CreateParticle(_, vPosition, _, _, "explosion_smokegrenade_base_green", ZP_GetClassSkillDuration(gZombie));
        
        // Validate entity
        if (entity != -1)
        {
            // Sets parent for the entity
            SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
    
            // Create gas damage task
            CreateTimer(ZOMBIE_CLASS_SKILL_DELAY, ClientOnToxicGas, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Timer for the toxic gas process.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action ClientOnToxicGas(Handle hTimer, int refID)
{
    // Gets entity index from reference key
    int entity = EntRefToEntIndex(refID);

    // Validate entity
    if (entity != -1)
    {
        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
 
        // Gets owner index
        int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
 
        // Find any players in the radius
        int i; int it = 1; /// iterator
        while ((i = ZP_FindPlayerInSphere(it, vPosition, ZOMBIE_CLASS_SKILL_RADIUS)) != -1)
        {
            // Skip zombies
            if (ZP_IsPlayerZombie(i))
            {
                continue;
            }

            // Create the damage for victim
            ZP_TakeDamage(i, owner, owner, ZOMBIE_CLASS_SKILL_DAMAGE, DMG_NERVEGAS);
        }
        
        // Allow timer
        return Plugin_Continue;
    }

    // Destroy timer
    return Plugin_Stop;
}