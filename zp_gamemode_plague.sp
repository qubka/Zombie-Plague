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
    name            = "[ZP] Game Mode: Plague",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of game modes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Mode index
int gGameMode;
#pragma unused gGameMode

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize mode
    gGameMode = ZP_GetServerGameMode("plague");
    if(gGameMode == -1) SetFailState("[ZP] Custom gamemode ID from name : \"plague\" wasn't find");
}

/**
 * Called after a zombie round is started.
 **/
public void ZP_OnZombieModStarted(int modeIndex)
{
    // Validate plague mode
    if(modeIndex == gGameMode) /* OR if(ZP_GetCurrentGameMode() == ZP_GetServerGameMode("plague"))*/
    {
        // Make a random nemesis/survivor
        ZP_SwitchClientClass(ZP_GetRandomHuman(), _, TYPE_NEMESIS);
        ZP_SwitchClientClass(ZP_GetRandomZombie(), _, TYPE_SURVIVOR);
    }
}