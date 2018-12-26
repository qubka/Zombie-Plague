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
    name            = "[ZP] Zombie Class: Fast",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_SPEED        1.5
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
    gZombie = ZP_GetZombieClassNameID("fast");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"fast\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("FAST_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"FAST_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    if(hSoundLevel == INVALID_HANDLE) SetFailState("[ZP] Custom cvar key ID from name : \"zp_game_custom_sound_level\" wasn't find");
}

/**
 * Called when a client use a skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_IsPlayerZombie(clientIndex) && ZP_GetClientZombieClass(clientIndex) == gZombie)
    {
        // Sets a new speed
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", ZOMBIE_CLASS_SKILL_SPEED);
        
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create effect
        static float vPosition[3];
        GetClientAbsOrigin(clientIndex, vPosition);
        FakeCreateParticle(clientIndex, vPosition, _, "viy_viy_viy", ZP_GetZombieClassSkillDuration(gZombie));
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Called when a skill duration is over.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientSkillOver(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_IsPlayerZombie(clientIndex) && ZP_GetClientZombieClass(clientIndex) == gZombie) 
    {
        // Sets the previous speed
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", ZP_GetZombieClassSpeed(gZombie));
    }
}
