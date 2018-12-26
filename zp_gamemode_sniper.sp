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
    name            = "[ZP] Game Mode: Sniper",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of game modes",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about human class.
 **/
#define GAME_MODE_WEAPON                "sfsniper" // Name in weapons.ini from translation file. Also change it in 'zbm3_menu_admin.sp', line 810
#define GAME_MODE_HEALTH                200 // Also change it in 'zbm3_menu_admin.sp', line 807
/**
 * @endsection
 **/

// Mode index
int gGameMode;
#pragma unused gGameMode

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize mode
    gGameMode = ZP_GetServerGameMode("sniper");
    if(gGameMode == -1) SetFailState("[ZP] Custom gamemode ID from name : \"sniper\" wasn't find");
}

/**
 * Called after a zombie round is started.
 **/
public void ZP_OnZombieModStarted(int modeIndex)
{
    // Validate plague mode
    if(modeIndex == gGameMode) /* OR if(ZP_GetCurrentGameMode() == ZP_GetServerGameMode("sniper"))*/
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i) && ZP_IsPlayerSurvivor(i))
            {
                // Set the new health
                SetEntityHealth(i, GAME_MODE_HEALTH);
        
                // Give item and select it
                ZP_GiveClientWeapon(i, GAME_MODE_WEAPON, SLOT_PRIMARY);
            }
        }
    }
}