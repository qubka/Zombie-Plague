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
    name            = "[ZP] Human Class: Blue Tank",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of human classes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Initialize human class index
int gHuman;
#pragma unused gHuman

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gHuman = ZP_GetClassNameID("bluetank");
    if(gHuman == -1) SetFailState("[ZP] Custom human class ID from name : \"bluetank\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BLUETANK_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BLUETANK_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the human class index
    if(ZP_GetClientClass(clientIndex) == gHuman)
    {
        // Validate amount
        int iHealth = ZP_GetClassHealth(gHuman);
        if(GetClientHealth(clientIndex) >= iHealth)
        {
            return Plugin_Handled;
        }

        // Sets health
        SetEntProp(clientIndex, Prop_Send, "m_iHealth", iHealth, 1);

        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create effect
        static float vPosition[3];
        GetClientAbsOrigin(clientIndex, vPosition);
        ZP_CreateParticle(clientIndex, vPosition, _, "vixr_final", ZP_GetClassSkillDuration(gHuman));
    }
    
    // Allow usage
    return Plugin_Continue;
}