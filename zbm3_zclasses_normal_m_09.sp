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
    name            = "[ZP] Zombie Class: NormalM09",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "4.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_NAME               "NormalM09" // Only will be taken from translation file
#define ZOMBIE_CLASS_INFO               "NormalM09Info" // Only will be taken from translation file ("" - disabled)
#define ZOMBIE_CLASS_MODEL              "models/player/custom_player/zombie/normal_m_09/normal_m_09.mdl"    
#define ZOMBIE_CLASS_CLAW               "models/player/custom_player/zombie/normal_m_09/hand_v2/hand_zombie_normal_m_09.mdl"    
#define ZOMBIE_CLASS_GRENADE            "models/player/custom_player/zombie/normal_m_09/grenade/grenade_normal_m_09.mdl"    
#define ZOMBIE_CLASS_HEALTH             3500
#define ZOMBIE_CLASS_SPEED              0.8
#define ZOMBIE_CLASS_GRAVITY            1.1
#define ZOMBIE_CLASS_KNOCKBACK          1.0
#define ZOMBIE_CLASS_LEVEL              1
#define ZOMBIE_CLASS_VIP                NO
#define ZOMBIE_CLASS_DURATION           2.0    
#define ZOMBIE_CLASS_COUNTDOWN          30.0
#define ZOMBIE_CLASS_REGEN_HEALTH       0
#define ZOMBIE_CLASS_REGEN_INTERVAL     0.0
#define ZOMBIE_CLASS_SKILL_REWARD       1 // For each zombie
#define ZOMBIE_CLASS_SKILL_RADIUS       40000.0 // [squared]
#define ZOMBIE_CLASS_SKILL_NEMESIS      false
#define ZOMBIE_CLASS_EFFECT_COLOR_F     {255, 127, 80, 75}
#define ZOMBIE_CLASS_EFFECT_DURATION_F  0.3
#define ZOMBIE_CLASS_EFFECT_TIME_F      1.0
#define ZOMBIE_CLASS_SOUND_DEATH        "ZOMBIE_DEATH_SOUNDS"
#define ZOMBIE_CLASS_SOUND_HURT         "ZOMBIE_HURT_SOUNDS"
#define ZOMBIE_CLASS_SOUND_IDLE         "ZOMBIE_IDLE_SOUNDS"
#define ZOMBIE_CLASS_SOUND_RESPAWN      "ZOMBIE_RESPAWN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_BURN         "ZOMBIE_BURN_SOUNDS"
#define ZOMBIE_CLASS_SOUND_ATTACK       "ZOMBIE_ATTACK_SOUNDS"
#define ZOMBIE_CLASS_SOUND_FOOTSTEP     "ZOMBIE_FOOTSTEP_SOUNDS"
#define ZOMBIE_CLASS_SOUND_REGEN        "ZOMBIE_REGEN_SOUNDS"
/**
 * @endsection
 **/

// Variables for the key sound block
int gSound;
 
// Initialize zombie class index
int gZombieNormalM09;
#pragma unused gZombieNormalM09

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
        gZombieNormalM09 = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME,
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
    gSound = ZP_GetSoundKeyID("HEALER_SKILL_SOUNDS");
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
    if(ZP_GetClientZombieClass(clientIndex) == gZombieNormalM09)
    {
        // Emit sound
        ZP_EmitSoundKeyID(clientIndex, gSound, SNDCHAN_VOICE);

        // Create an effect
        FakeCreateParticle(clientIndex, _, "tornado", ZOMBIE_CLASS_DURATION);
        
        // Create an fade
        FakeCreateFadeScreen(clientIndex, ZOMBIE_CLASS_EFFECT_DURATION_F, ZOMBIE_CLASS_EFFECT_TIME_F, 0x0001, ZOMBIE_CLASS_EFFECT_COLOR_F);  
        
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];
        
        // Gets client's origin
        GetClientAbsOrigin(clientIndex, vEntPosition);
        
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i) && ((ZP_IsPlayerZombie(i) && !ZP_IsPlayerNemesis(i)) || (ZP_IsPlayerNemesis(i) && ZOMBIE_CLASS_SKILL_NEMESIS)))
            {
                // Gets victim's origin
                GetClientAbsOrigin(i, vVictimPosition);

                // Calculate the distance
                float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                // Validate distance
                if(flDistance <= ZOMBIE_CLASS_SKILL_RADIUS)
                {
                    // Gets victim's zombie class/health
                    int iD = ZP_GetClientZombieClass(i);
                    int iHealth = ZP_GetZombieClassHealth(iD);
            
                    // Validate lower health
                    if(GetClientHealth(i) < iHealth)
                    {
                        // Emit sound
                        ZP_EmitSoundKeyID(i, ZP_GetZombieClassSoundRegenID(iD), SNDCHAN_VOICE);    
                        
                        // Create an effect
                        FakeCreateParticle(i, _, "heal_ss", ZOMBIE_CLASS_DURATION);
                        
                        // Set a new health 
                        SetEntProp(i, Prop_Send, "m_iHealth", iHealth, 4); 
                        
                        // Give reward
                        ZP_SetClientAmmoPack(clientIndex, ZP_GetClientAmmoPack(clientIndex) + ZOMBIE_CLASS_SKILL_REWARD);
                    }
                }
            }
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}
