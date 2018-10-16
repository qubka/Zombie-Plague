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
    name            = "[ZP] Human Class: Blue Tank",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of human classes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about human class.
 **/
#define HUMAN_CLASS_NAME                "bluetank" // Only will be taken from translation file
#define HUMAN_CLASS_INFO                "bluetank info" // Only will be taken from translation file ("" - disabled)
#define HUMAN_CLASS_MODEL               "models/player/custom_player/napas/tank_blue/zbm3_tank_blue_final4.mdl"    
#define HUMAN_CLASS_ARM                 "models/player/custom_player/zombie/arms/bluemale_arms.mdl"  
#define HUMAN_CLASS_VIEW                {4, -1}
#define HUMAN_CLASS_HEALTH              250
#define HUMAN_CLASS_SPEED               0.9
#define HUMAN_CLASS_GRAVITY             0.9
#define HUMAN_CLASS_ARMOR               10
#define HUMAN_CLASS_LEVEL               8
#define HUMAN_CLASS_GROUP               ""
#define HUMAN_CLASS_DURATION            2.0    
#define HUMAN_CLASS_COUNTDOWN           30.0
#define HUMAN_CLASS_SOUND_DEATH         "HUMAN_DEATH_SOUNDS"
#define HUMAN_CLASS_SOUND_HURT          "HUMAN_HURT_SOUNDS"
#define HUMAN_CLASS_SOUND_INFECT        "HUMAN_INFECTION_SOUNDS"
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
    gSound = ZP_GetSoundKeyID("BLUETANK_SKILL_SOUNDS");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
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
        // Validate amount
        int iHealth = ZP_GetHumanClassHealth(gHuman);
        if(GetClientHealth(clientIndex) >= iHealth)
        {
            return Plugin_Handled;
        }

        // Sets health
        SetEntProp(clientIndex, Prop_Send, "m_iHealth", iHealth, 1);

        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create effect
        static float vPosition[3];
        GetClientAbsOrigin(clientIndex, vPosition);
        FakeCreateParticle(clientIndex, vPosition, _, "vixr_final", HUMAN_CLASS_DURATION);
    }
    
    // Allow usage
    return Plugin_Continue;
}