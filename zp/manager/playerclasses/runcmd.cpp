/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          runcmd.cpp
 *  Type:          Module
 *  Description:   Hook buttons, and initiliaze commands and menus.
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
 
/**
 * @brief Called when a clients movement buttons are being processed.
 *  
 * @param clientIndex       The client index.
 * @param iButtons          Copyback buffer containing the current commands. (as bitflags - see entity_prop_stocks.inc)
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles          Players desired view angles.    
 * @param weaponID          The entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param iSubType          Weapon subtype when selected from a menu.
 * @param iCmdNum           Command number. Increments from the first command sent.
 * @param iTickCount        Tick count. A client prediction based on the server GetGameTickCount value.
 * @param iSeed             Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse            Mouse direction (x, y).
 **/ 
public Action OnPlayerRunCmd(int clientIndex, int &iButtons, int &iImpulse, float flVelocity[3], float flAngles[3], int &weaponID, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
    // Initialize variables
    Action resultHandle; static int iLastButtons[MAXPLAYERS+1]; 

    // Validate client
    if(IsPlayerExist(clientIndex, false))
    {
        // If the client is alive, than continue
        if(IsPlayerAlive(clientIndex))
        {
            // Button leap hooks
            if((iButtons & IN_JUMP) && (iButtons & IN_DUCK))
            {    
                // Validate overtransmitting
                if(!((iLastButtons[clientIndex] & IN_JUMP) && (iLastButtons[clientIndex] & IN_DUCK)))
                {
                    // Forward event to modules
                    JumpBoostOnClientLeapJump(clientIndex);
                }
            }

            // Dublicate the button buffer
            int iButton = iButtons; /// for weapon forward
            
            // Forward event to modules
            resultHandle = WeaponsOnRunCmd(clientIndex, iButtons, iLastButtons[clientIndex]);
            
            // Store the previous button
            iLastButtons[clientIndex] = iButton;
            
            // Allow button
            return resultHandle;
        }
        else
        {
            // Block button (Bot control)
            iButtons &= (~IN_USE);
            return Plugin_Changed;
        }
    }
    
    // Store the current button
    iLastButtons[clientIndex] = iButtons;
    
    // Allow button
    return Plugin_Continue;
}
