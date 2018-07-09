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
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin ZombieClassFast =
{
    name            = "[ZP] Zombie Class: Fast",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "Fast" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "FastInfo" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/police/police.mdl"
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/police/hand_v2/hand_zombie_normalhost_f.mdl"
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/police/grenade/grenade_zombie_police.mdl"    
#define ZOMBIE_CLASS_HEALTH             4000
#define ZOMBIE_CLASS_SPEED              1.1
#define ZOMBIE_CLASS_GRAVITY            0.8
#define ZOMBIE_CLASS_KNOCKBACK          1.2
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_VIP                NO
#define ZOMBIE_CLASS_DURATION           5.0    
#define ZOMBIE_CLASS_COUNTDOWN          30.0
#define ZOMBIE_CLASS_REGEN_HEALTH       30
#define ZOMBIE_CLASS_REGEN_INTERVAL     4.0
#define ZOMBIE_CLASS_SKILL_SPEED        1.5
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_FEMALE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_FEMALE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_FEMALE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_FEMALE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_FEMALE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_FEMALE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FEMALE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_FEMALE_REGEN_SOUNDS"
/**
 * @endsection
 **/

// ConVar for sound level
ConVar hSoundLevel;

// Initialize zombie class index
int gZombieFast;
#pragma unused gZombieFast

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initilizate zombie class
        gZombieFast = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
        ZOMBIE_CLASS_INFO,
        ZOMBIE_CLASS_MODEL, 
        ZOMBIE_CLASS_CLAW,  
        ZOMBIE_CLASS_GRENADE,
        ZOMBIE_CLASS_HEALTH, 
        ZOMBIE_CLASS_SPEED, 
        ZOMBIE_CLASS_GRAVITY, 
        ZOMBIE_CLASS_KNOCKBACK, 
        ZOMBIE_CLASS_LEVEL,
        ZOMBIE_CLASS_VIP, 
        ZOMBIE_CLASS_DURATION, 
        ZOMBIE_CLASS_COUNTDOWN, 
        ZOMBIE_CLASS_REGEN_HEALTH, 
        ZOMBIE_CLASS_REGEN_INTERVAL,
        ZOMBIE_CLASS_SOUND_DEATH,
        ZOMBIE_CLASS_SOUND_HURT,
        ZOMBIE_CLASS_SOUND_IDLE,
        ZOMBIE_CLASS_SOUND_RESPAWN,
        ZOMBIE_CLASS_SOUND_BURN,
        ZOMBIE_CLASS_SOUND_ATTACK,
        ZOMBIE_CLASS_SOUND_FOOTSTEP,
        ZOMBIE_CLASS_SOUND_REGEN);
    }
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex        The client index.
 *
 * @return                   Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Handled;
    }
    
    // Validate the zombie class index
    if(ZP_GetClientZombieClass(clientIndex) == gZombieFast)
    {
        // Sets a new speed
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", ZOMBIE_CLASS_SKILL_SPEED);
        
        // Emit sound
        EmitSoundToAll("*/zbm3/zombie_madness1.mp3", clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create an effect
        FakeCreateParticle(clientIndex, _, "viy_viy_viy", ZOMBIE_CLASS_DURATION);
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * Called when a zombie skill duration is over.
 * 
 * @param clientIndex       The client index.
 **/
public void ZP_OnClientSkillOver(int clientIndex)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // Validate the zombie class index
    if(ZP_GetClientZombieClass(clientIndex) == gZombieFast) 
    {
        // Sets the previous speed
        SetEntPropFloat(clientIndex, Prop_Data, "m_flLaggedMovementValue", ZP_GetZombieClassSpeed(gZombieFast));
    }
}