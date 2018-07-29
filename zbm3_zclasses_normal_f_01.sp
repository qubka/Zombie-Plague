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
public Plugin myinfo =
{
    name            = "[ZP] Zombie Class: NormalF01",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "NormalF01" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "NormalF01Info" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/normal_f_01/normal_f_01.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/normal_f_01/hand_v2/hand_zombie_normal_f_01.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/normal_f_01/grenade/grenade_normal_f_01.mdl"    
#define ZOMBIE_CLASS_HEALTH             4500
#define ZOMBIE_CLASS_SPEED              1.0
#define ZOMBIE_CLASS_GRAVITY            0.9
#define ZOMBIE_CLASS_KNOCKBACK          1.0
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_VIP                NO
#define ZOMBIE_CLASS_DURATION           0.0    
#define ZOMBIE_CLASS_COUNTDOWN          0.0
#define ZOMBIE_CLASS_REGEN_HEALTH       300
#define ZOMBIE_CLASS_REGEN_INTERVAL     7.0
#define ZOMBIE_CLASS_SKILL_CHANCE_CAST  20
#define ZOMBIE_CLASS_EFFECT_DURATION_F  3.3
#define ZOMBIE_CLASS_EFFECT_TIME_F      4.0
#define ZOMBIE_CLASS_EFFECT_COLOR_F     {0, 0, 0, 255}
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

// Variables for the key sound block
int gSound;
 
// Initialize zombie class index
int gZombieNormalF01;
#pragma unused gZombieNormalF01

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize zombie class
        gZombieNormalF01 = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
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
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Sounds
    gSound = ZP_GetSoundKeyID("SLEEPER_SKILL_SOUNDS");
}

/**
 * Called when a client take a fake damage.
 * 
 * @param clientIndex        The client index.
 * @param attackerIndex      The attacker index.
 * @param damageAmount       The amount of damage inflicted.
 * @param damageType         The ditfield of damage types
 **/
public void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount, int damageType)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
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
        if(ZP_GetClientZombieClass(clientIndex) == gZombieNormalF01)
        {
            // Generate the chance
            nChanceIndex[clientIndex] = GetRandomInt(0, 999);
            
            // Validate chance
            if(nChanceIndex[clientIndex] < ZOMBIE_CLASS_SKILL_CHANCE_CAST)
            {
                // Emit sound
                ZP_EmitSoundKeyID(attackerIndex, gSound, SNDCHAN_VOICE);
                
                // Create an fade
                FakeCreateFadeScreen(attackerIndex, ZOMBIE_CLASS_EFFECT_DURATION_F, ZOMBIE_CLASS_EFFECT_TIME_F, 0x0001, ZOMBIE_CLASS_EFFECT_COLOR_F);
                
                // Create an effect
                FakeCreateParticle(attackerIndex, _, "sila_trail_apalaal", ZOMBIE_CLASS_EFFECT_DURATION_F);
            }
        }
    }
}
