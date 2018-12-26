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
    name            = "[ZP] Human Class: Blue Alice",
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
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gHuman = ZP_GetHumanClassNameID("bluealice");
    if(gHuman == -1) SetFailState("[ZP] Custom human class ID from name : \"bluealice\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("BLUEALICE_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BLUEALICE_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    if(hSoundLevel == INVALID_HANDLE) SetFailState("[ZP] Custom cvar key ID from name : \"zp_game_custom_sound_level\" wasn't find");
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param nemesisMode       Indicates that client will be a nemesis.
 * @param respawnMode       Indicates that infection was on spawn.
 **/
public void ZP_OnClientInfected(int clientIndex, int attackerIndex, bool nemesisMode, bool respawnMode)
{
    // Reset visibility
    SetEntPropFloat(clientIndex, Prop_Send, "m_flModelScale", 1.0);  
}
 
/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 * @param survivorMode      Indicates that client will be a survivor.
 * @param respawnMode       Indicates that humanizing was on spawn.
 **/
public void ZP_OnClientHumanized(int clientIndex, bool survivorMode, bool respawnMode)
{
    // Reset visibility
    SetEntPropFloat(clientIndex, Prop_Send, "m_flModelScale", 1.0);  
}

/**
 * Called when a client use a skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the human class index
    if(ZP_IsPlayerHuman(clientIndex) && ZP_GetClientHumanClass(clientIndex) == gHuman)
    {
        // Make model invisible
        SetEntPropFloat(clientIndex, Prop_Send, "m_flModelScale", 0.0);  

        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create effect
        static float vPosition[3];
        GetClientAbsOrigin(clientIndex, vPosition);
        FakeCreateParticle(clientIndex, vPosition, _, "ekvalaizer_gray", ZP_GetHumanClassSkillDuration(gHuman));
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
    // Validate the human class index
    if(ZP_IsPlayerHuman(clientIndex) && ZP_GetClientHumanClass(clientIndex) == gHuman)
    {
        // Reset visibility
        SetEntPropFloat(clientIndex, Prop_Send, "m_flModelScale", 1.0);  

        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
    }
}