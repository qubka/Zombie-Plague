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
    name            = "[ZP] Zombie Class: Healer",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_REWARD       1 // For each zombie
#define ZOMBIE_CLASS_SKILL_RADIUS       250.0
#define ZOMBIE_CLASS_SKILL_COLOR_F      {255, 127, 80, 75}
#define ZOMBIE_CLASS_SKILL_DURATION_F   0.3
#define ZOMBIE_CLASS_SKILL_TIME_F       1.0
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
    gZombie = ZP_GetClassNameID("healer");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"healer\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("HEALER_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HEALER_SKILL_SOUNDS\" wasn't find");
    
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
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];
        
        // Gets client origin
        GetEntPropVector(clientIndex, Prop_Data, "m_vecAbsOrigin", vEntPosition);
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);

        // Create an fade
        UTIL_CreateFadeScreen(clientIndex, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, FFADE_IN, ZOMBIE_CLASS_SKILL_COLOR_F);  
        
        // Create an effect
        UTIL_CreateParticle(clientIndex, vEntPosition, _, _, "tornado", ZP_GetClassSkillDuration(gZombie));
        
        // Find any players in the radius
        int i; int it = 1; /// iterator
        while((i = ZP_FindPlayerInSphere(it, vEntPosition, ZOMBIE_CLASS_SKILL_RADIUS)) != INVALID_ENT_REFERENCE)
        {
            // Skip humans
            if(ZP_IsPlayerHuman(i))
            {
                continue;
            }

            // Gets victim zombie class/health
            int iClass = ZP_GetClientClass(i);
            int iHealth = ZP_GetClassHealth(iClass);
            int iSound = ZP_GetClassSoundRegenID(iClass);

            // Validate lower health
            if(GetEntProp(i, Prop_Send, "m_iHealth") < iHealth)
            {
                // Sets a new health 
                SetEntProp(i, Prop_Send, "m_iHealth", iHealth); 
                
                // Validate sound key
                if(iSound != -1)
                {
                    // Play sound
                    ZP_EmitSoundToAll(iSound, _, i, SNDCHAN_VOICE, hSoundLevel.IntValue);
                }
                
                // Create an effect
                GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vVictimPosition);
                UTIL_CreateParticle(i, vVictimPosition, _, _, "heal_ss", ZP_GetClassSkillDuration(gZombie));

                // Give reward
                ZP_SetClientMoney(clientIndex, ZP_GetClientMoney(clientIndex) + ZOMBIE_CLASS_SKILL_REWARD);
            }
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}
