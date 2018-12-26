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
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: NormalF01",
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
 * Called after a zombie core is loaded.
 **/
 public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gZombie = ZP_GetZombieClassNameID("normalf01");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"normalf01\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("SLEEPER_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"SLEEPER_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    if(hSoundLevel == INVALID_HANDLE) SetFailState("[ZP] Custom cvar key ID from name : \"zp_game_custom_sound_level\" wasn't find");
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
    if(!IsPlayerExist(attackerIndex))
    {
        return;
    }
    
    // Initialize client chances
    static int nChanceIndex[MAXPLAYERS+1];
    
    // If client used the zombie skill, then stop appling damage
    if(ZP_IsPlayerZombie(clientIndex) && !ZP_IsPlayerNemesis(clientIndex))
    {
        // Validate the zombie class index
        if(ZP_GetClientZombieClass(clientIndex) == gZombie)
        {
            // Generate the chance
            nChanceIndex[clientIndex] = GetRandomInt(0, 999);
            
            // Validate chance
            if(nChanceIndex[clientIndex] < ZOMBIE_CLASS_SKILL_CHANCE_CAST)
            {
                // Emit sound
                static char sSound[PLATFORM_MAX_PATH];
                ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
                EmitSoundToAll(sSound, attackerIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
                
                // Create an fade
                FakeCreateFadeScreen(attackerIndex, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, 0x0001, ZOMBIE_CLASS_SKILL_COLOR_F);
                
                // Create effect
                static float vAttackerPosition[3];
                GetClientAbsOrigin(attackerIndex, vAttackerPosition);
                FakeCreateParticle(attackerIndex, vAttackerPosition, _, "sila_trail_apalaal", ZOMBIE_CLASS_SKILL_DURATION_F);
            }
        }
    }
}
