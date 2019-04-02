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
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
 public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: Sleeper",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_CHANCE_CAST  20
#define ZOMBIE_CLASS_SKILL_DURATION_F   3.3
#define ZOMBIE_CLASS_SKILL_TIME_F       4.0
#define ZOMBIE_CLASS_SKILL_COLOR_F      {0, 0, 0, 255}
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
    gZombie = ZP_GetClassNameID("sleeper");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"sleeper\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("SLEEPER_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SLEEPER_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits, int &weaponIndex)
{
    // Validate attacker
    if(!IsPlayerExist(attackerIndex))
    {
        return;
    }
    
    // Initialize client chances
    static int nChanceIndex[MAXPLAYERS+1];

    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie)
    {
        // Generate the chance
        nChanceIndex[clientIndex] = GetRandomInt(0, 999);
        
        // Validate chance
        if(nChanceIndex[clientIndex] < ZOMBIE_CLASS_SKILL_CHANCE_CAST)
        {
            // Play sound
            ZP_EmitSoundToAll(gSound, 1, attackerIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
            
            // Create an fade
            UTIL_CreateFadeScreen(attackerIndex, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, 0x0001, ZOMBIE_CLASS_SKILL_COLOR_F);
            
            // Create effect
            static float vPosition[3];
            GetEntPropVector(attackerIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
            UTIL_CreateParticle(attackerIndex, vPosition, _, _, "sila_trail_apalaal", ZOMBIE_CLASS_SKILL_DURATION_F);
        }
    }
}
