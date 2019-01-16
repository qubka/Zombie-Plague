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
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_REWARD       1 // For each zombie
#define ZOMBIE_CLASS_SKILL_RADIUS       40000.0 // [squared]
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
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);

        // Create an fade
        ZP_CreateFadeScreen(clientIndex, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, 0x0001, ZOMBIE_CLASS_SKILL_COLOR_F);  
        
        // Initialize vectors
        static float vEntPosition[3]; static float vVictimPosition[3];
        
        // Gets client origin
        GetClientAbsOrigin(clientIndex, vEntPosition);
        
        // Create an effect
        ZP_CreateParticle(clientIndex, vEntPosition, _, "tornado", ZP_GetClassSkillDuration(gZombie));
        
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate zombie
            if(IsPlayerExist(i) && ZP_IsPlayerZombie(i))
            {
                // Gets victim origin
                GetClientAbsOrigin(i, vVictimPosition);

                // Calculate the distance
                float flDistance = GetVectorDistance(vEntPosition, vVictimPosition, true);

                // Validate distance
                if(flDistance <= ZOMBIE_CLASS_SKILL_RADIUS)
                {
                    // Gets victim zombie class/health
                    int iD = ZP_GetClientClass(i);
                    int iHealth = ZP_GetClassHealth(iD);

                    // Validate lower health
                    if(GetClientHealth(i) < iHealth)
                    {
                        // Emit sound
                        ZP_GetSound(ZP_GetClassSoundRegenID(iD), sSound, sizeof(sSound));
                        EmitSoundToAll(sSound, i, SNDCHAN_VOICE, hSoundLevel.IntValue);
                        
                        // Create an effect
                        ZP_CreateParticle(i, vVictimPosition, _, "heal_ss", ZP_GetClassSkillDuration(gZombie));
                        
                        // Sets a new health 
                        SetEntProp(i, Prop_Send, "m_iHealth", iHealth); 
                        
                        // Give reward
                        ZP_SetClientMoney(clientIndex, ZP_GetClientMoney(clientIndex) + ZOMBIE_CLASS_SKILL_REWARD);
                    }
                }
            }
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}
