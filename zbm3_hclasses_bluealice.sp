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
    name            = "[ZP] Human Class: Blue Alice",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of human classes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about human class.
 **/
#define HUMAN_CLASS_NAME                "bluealice" // Only will be taken from translation file
#define HUMAN_CLASS_INFO                "bluealice info" // Only will be taken from translation file ("" - disabled)
#define HUMAN_CLASS_MODEL               "models/player/custom_player/napas/alice_blue/alice_blue.mdl"    
#define HUMAN_CLASS_ARM                 "models/player/custom_player/zombie/arms/bluefemale_arms.mdl"  
#define HUMAN_CLASS_VIEW                {5, -1}
#define HUMAN_CLASS_HEALTH              150
#define HUMAN_CLASS_SPEED               0.9
#define HUMAN_CLASS_GRAVITY             0.9
#define HUMAN_CLASS_ARMOR               30
#define HUMAN_CLASS_LEVEL               10
#define HUMAN_CLASS_GROUP               ""
#define HUMAN_CLASS_DURATION            10.0    
#define HUMAN_CLASS_COUNTDOWN           30.0
#define HUMAN_CLASS_SOUND_DEATH         "HUMAN_FEMALE_DEATH_SOUNDS"
#define HUMAN_CLASS_SOUND_HURT          "HUMAN_FEMALE_HURT_SOUNDS"
#define HUMAN_CLASS_SOUND_INFECT        "HUMAN_FEMALE_INFECTION_SOUNDS"
/**
 * @endsection
 **/

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Initialize human class index
int gHuman;
#pragma unused gHuman

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize human class
        gHuman = ZP_RegisterHumanClass(HUMAN_CLASS_NAME, 
        HUMAN_CLASS_INFO,
        HUMAN_CLASS_MODEL, 
        HUMAN_CLASS_ARM, 
        HUMAN_CLASS_VIEW,
        HUMAN_CLASS_HEALTH, 
        HUMAN_CLASS_SPEED, 
        HUMAN_CLASS_GRAVITY, 
        HUMAN_CLASS_ARMOR,
        HUMAN_CLASS_LEVEL,
        HUMAN_CLASS_GROUP,
        HUMAN_CLASS_DURATION,
        HUMAN_CLASS_COUNTDOWN,
        HUMAN_CLASS_SOUND_DEATH,
        HUMAN_CLASS_SOUND_HURT,
        HUMAN_CLASS_SOUND_INFECT);
    }
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Sounds
    gSound = ZP_GetSoundKeyID("REDALICE_SKILL_SOUNDS");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
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
        FakeCreateParticle(clientIndex, vPosition, _, "ekvalaizer_gray", HUMAN_CLASS_DURATION);
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