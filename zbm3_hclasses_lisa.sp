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
    name            = "[ZP] Human Class: Lisa",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of human classes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about human class.
 **/
#define HUMAN_CLASS_NAME                "lisa" // Only will be taken from translation file
#define HUMAN_CLASS_MODEL               "models/player/custom_player/kuristaja/cso2/lisa/lisa.mdl"    
#define HUMAN_CLASS_ARM                 "models/player/custom_player/kuristaja/cso2/lisa/lisa_arms.mdl"    
#define HUMAN_CLASS_HEALTH              100
#define HUMAN_CLASS_SPEED               1.0
#define HUMAN_CLASS_GRAVITY             1.0
#define HUMAN_CLASS_ARMOR               0
#define HUMAN_CLASS_LEVEL               1
#define HUMAN_CLASS_GROUP               ""
#define HUMAN_CLASS_SOUND_DEATH         "HUMAN_FEMALE_DEATH_SOUNDS"
#define HUMAN_CLASS_SOUND_HURT          "HUMAN_FEMALE_HURT_SOUNDS"
#define HUMAN_CLASS_SOUND_INFECT        "HUMAN_FEMALE_INFECTION_SOUNDS"
/**
 * @endsection
 **/

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
        HUMAN_CLASS_MODEL, 
        HUMAN_CLASS_ARM, 
        HUMAN_CLASS_HEALTH, 
        HUMAN_CLASS_SPEED, 
        HUMAN_CLASS_GRAVITY, 
        HUMAN_CLASS_ARMOR,
        HUMAN_CLASS_LEVEL,
        HUMAN_CLASS_GROUP,
        HUMAN_CLASS_SOUND_DEATH,
        HUMAN_CLASS_SOUND_HURT,
        HUMAN_CLASS_SOUND_INFECT);
    }
}