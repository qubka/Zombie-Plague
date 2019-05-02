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
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gZombie = ZP_GetClassNameID("smoker");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"smoker\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("SMOKE_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SMOKE_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie)
    {
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Gets client origin
        static float vPosition[3];
        GetEntPropVector(clientIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
        
        // Create a smoke effect
        int particleIndex = UTIL_CreateParticle(_, vPosition, _, _, "explosion_smokegrenade_base_green", ZP_GetClassSkillDuration(gZombie));
        
        // Validate entity
        if(particleIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent for the entity
            SetEntPropEnt(particleIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
    
            // Create gas damage task
            CreateTimer(ZOMBIE_CLASS_SKILL_DELAY, ClientOnToxicGas, EntIndexToEntRef(particleIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Timer for the toxic gas process.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action ClientOnToxicGas(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
 
        // Create the damage for victims
        UTIL_CreateDamage(_, vPosition, GetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity"), ZOMBIE_CLASS_SKILL_DAMAGE, ZOMBIE_CLASS_SKILL_RADIUS, DMG_NERVEGAS);

        // Allow scream
        return Plugin_Continue;
    }

    // Destroy scream
    return Plugin_Stop;
}