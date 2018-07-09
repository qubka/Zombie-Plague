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
public Plugin GameModeMulti =
{
    name            = "[ZP] Game Mode: Multi-Infection",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of game modes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about human class.
 **/
#define GAME_MODE_NAME                   "Multi"
#define GAME_MODE_DESCRIPTION            "Multi mode" // String has taken from translation file
#define GAME_MODE_SOUND                  "ROUND_MULTI_SOUNDS" // Sounds has taken from sounds file
#define GAME_MODE_CHANCE                 20 // If value has 0, mode will be taken like a default    
#define GAME_MODE_MIN_PLAYERS            0
#define GAME_MODE_RATIO                  0.125
#define GAME_MODE_INFECTION              YES
#define GAME_MODE_RESPAWN                NO
#define GAME_MODE_SURVIVOR               NO
#define GAME_MODE_NEMESIS                NO
/**
 * @endsection
 **/

// Initialize game mode index
int gMulti;
#pragma unused gMulti

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initilizate game mode
        gMulti = ZP_RegisterGameMode(GAME_MODE_NAME, 
        GAME_MODE_DESCRIPTION, 
        GAME_MODE_SOUND, 
        GAME_MODE_CHANCE, 
        GAME_MODE_MIN_PLAYERS, 
        GAME_MODE_RATIO, 
        GAME_MODE_INFECTION,
        GAME_MODE_RESPAWN,
        GAME_MODE_SURVIVOR,
        GAME_MODE_NEMESIS);
    }
}