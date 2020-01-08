/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
    gZombie = ZP_GetClassNameID("healer");
    //if (gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"healer\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("HEALER_SKILL_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HEALER_SKILL_SOUNDS\" wasn't find");
    
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
        // Initialize vectors
        static float vPosition[3]; static float vEnemy[3];
        
        // Gets client origin
        GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
        
        // Play sound
        ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, hSoundLevel.IntValue);

        // Create an fade
        UTIL_CreateFadeScreen(client, ZOMBIE_CLASS_SKILL_DURATION_F, ZOMBIE_CLASS_SKILL_TIME_F, FFADE_IN, ZOMBIE_CLASS_SKILL_COLOR_F);  
        
        // Create an effect
        UTIL_CreateParticle(client, vPosition, _, _, "tornado", ZP_GetClassSkillDuration(gZombie));
        
        // Find any players in the radius
        int i; int it = 1; /// iterator
        while ((i = ZP_FindPlayerInSphere(it, vPosition, ZOMBIE_CLASS_SKILL_RADIUS)) != -1)
        {
            // Skip humans
            if (ZP_IsPlayerHuman(i))
            {
                continue;
            }

            // Gets victim zombie class/health
            int iClass = ZP_GetClientClass(i);
            int iHealth = ZP_GetClassHealth(iClass);
            int iSound = ZP_GetClassSoundRegenID(iClass);

            // Validate lower health
            if (GetEntProp(i, Prop_Send, "m_iHealth") < iHealth)
            {
                // Sets a new health 
                SetEntProp(i, Prop_Send, "m_iHealth", iHealth); 
                
                // Validate sound key
                if (iSound != -1)
                {
                    // Play sound
                    ZP_EmitSoundToAll(iSound, _, i, SNDCHAN_VOICE, hSoundLevel.IntValue);
                }
                
                // Gets victim origin
                GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
                
                // Create an effect
                UTIL_CreateParticle(i, vEnemy, _, _, "heal_ss", ZP_GetClassSkillDuration(gZombie));

                // Give reward
                ZP_SetClientMoney(client, ZP_GetClientMoney(client) + ZOMBIE_CLASS_SKILL_REWARD);
            }
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}
