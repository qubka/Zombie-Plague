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
    name            = "[ZP] Game Mode: Plague",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of game modes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about human class.
 **/
#define GAME_MODE_NAME                   "plague"
#define GAME_MODE_DESCRIPTION            "plague swarm" // String has taken from translation file
#define GAME_MODE_SOUND                  "ROUND_PLAGUE_SOUNDS" // Sounds has taken from sounds file
#define GAME_MODE_CHANCE                 20 // If value has 0, mode will be taken like a default    
#define GAME_MODE_MIN_PLAYERS            0
#define GAME_MODE_RATIO                  0.5
#define GAME_MODE_INFECTION              false
#define GAME_MODE_RESPAWN                false
#define GAME_MODE_SURVIVOR               false
#define GAME_MODE_NEMESIS                false
/**
 * @endsection
 **/

// Initialize game mode index
int gPlague;
#pragma unused gPlague

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize game mode
        gPlague = ZP_RegisterGameMode(GAME_MODE_NAME, 
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

/**
 * Called after a zombie round is started.
 **/
public void ZP_OnZombieModStarted(int modeIndex)
{
    // Validate plague mode
    if(modeIndex == gPlague) /* OR if(ZP_GetCurrentGameMode() == ZP_GetServerGameMode(GAME_MODE_NAME))*/
    {
        // Make a random nemesis/survivor
        ZP_SwitchClientClass(ZP_GetRandomHuman(), _, TYPE_NEMESIS);
        ZP_SwitchClientClass(ZP_GetRandomZombie(), _, TYPE_SURVIVOR);
    }
}