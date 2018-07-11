/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          runcmd.cpp
 *  Type:          Game
 *  Description:   Hook buttons, and initiliaze commands and menus.
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
 
/**
 * Called when a clients movement buttons are being processed.
 *  
 * @param clientIndex       The client index.
 * @param iButtons          Copyback buffer containing the current commands (as bitflags - see entity_prop_stocks.inc).
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles          Players desired view angles.    
 * @param weaponIndex       Entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param iSubType          Weapon subtype when selected from a menu.
 * @param iCmdNum           Command number. Increments from the first command sent.
 * @param iTickCount        Tick count. A client's prediction based on the server's GetGameTickCount value.
 * @param iSeed             Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse            Mouse direction (x, y).
 **/ 
public Action OnPlayerRunCmd(int clientIndex, int &iButtons, int &iImpulse, float flVelocity[3], float flAngles[3], int &weaponIndex, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
    // Initialize variable
    static int nLastButtons[MAXPLAYERS+1];
    
    // Button menu button
    if(iButtons & (1 << gCvarList[CVAR_GAME_CUSTOM_MENU_BUTTON].IntValue))
    {
        // Validate overtransmitting
        if(!(nLastButtons[clientIndex] & (1 << gCvarList[CVAR_GAME_CUSTOM_MENU_BUTTON].IntValue)))
        {
            // Validate that menu isn't open yet, then open
            if(GetClientMenu(clientIndex, INVALID_HANDLE) == MenuSource_None) 
            {
                // The main menu
                MenuMain(clientIndex);
            }
        }
    }
    
    // Validate client
    if(IsPlayerExist(clientIndex, false))
    {
        // If the client is alive, than continue
        if(IsPlayerAlive(clientIndex))
        {
            //!! IMPORTANT BUG FIX !!//
            // Ladder can reset gravity, so update it each frame
            ToolsSetClientGravity(clientIndex, gClientData[clientIndex][Client_Nemesis] ? gCvarList[CVAR_NEMESIS_GRAVITY].FloatValue : (gClientData[clientIndex][Client_Zombie] ? ZombieGetGravity(gClientData[clientIndex][Client_ZombieClass]) : HumanGetGravity(gClientData[clientIndex][Client_HumanClass])));

            // Update client position on the radar
            ToolsSetClientSpot(clientIndex, !gClientData[clientIndex][Client_Zombie]);
            
            // Button leap hooks
            if((iButtons & IN_JUMP) && (iButtons & IN_DUCK))
            {    
                // Validate overtransmitting
                if(!((nLastButtons[clientIndex] & IN_JUMP) && (nLastButtons[clientIndex] & IN_DUCK)))
                {
                    // Create a leap jump
                    JumpBoostOnClientLeapJump(clientIndex);
                }
            }
        }
        else
        {
            // Block button (Bot control)
            iButtons &= (~IN_USE);
            return Plugin_Changed;
        }
    }
    
    // Store the button for next usage
    nLastButtons[clientIndex] = iButtons;
    
    // Allow button
    return Plugin_Continue;
}
