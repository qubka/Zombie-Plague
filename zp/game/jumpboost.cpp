/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          jumpboost.cpp
 *  Type:          Game 
 *  Description:   Modified jump vector magnitudes.
 *
 *  Copyright (C) 2015-2016 Nikita Ushakov (Ireland, Dublin)
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
 * Client is jumping.
 * 
 * @param clientIndex       The client index.
 **/
void JumpBoostOnClientJump(int clientIndex)
{ 
    // If jump boost disabled, then stop
    if(!gCvarList[CVAR_JUMPBOOST_ENABLE].BoolValue)
    {
        return;
    }

    // Creates a single use next frame hook
    RequestFrame(view_as<RequestFrameCallback>(JumpBoostOnClientJumpPost), GetClientUserId(clientIndex));
}  

/**
 * Client is jumping. *(Post)
 *
 * @param userID            The user id.
 **/
public void JumpBoostOnClientJumpPost(int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Initialize velocity vector
        static float vVelocity[3];
        
        // Gets the client velocity
        ToolsGetClientVelocity(clientIndex, vVelocity);
        
        // Only apply horizontal multiplier if it not a bhop
        if(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0)) < gCvarList[CVAR_JUMPBOOST_MAX].FloatValue)
        {
            // Apply horizontal multipliers to jump vector
            vVelocity[0] *= gCvarList[CVAR_JUMPBOOST_MULTIPLIER].FloatValue;
            vVelocity[1] *= gCvarList[CVAR_JUMPBOOST_MULTIPLIER].FloatValue;
        }

        // Apply height multiplier to jump vector
        vVelocity[2] *= gCvarList[CVAR_JUMPBOOST_MULTIPLIER].FloatValue;

        // Set new velocity
        ToolsClientVelocity(clientIndex, vVelocity, true, false);
    }
}

/**
 * Called when player want do the leap jump.
 *
 * @param clientIndex       The client index.
 **/
void JumpBoostOnClientLeapJump(int clientIndex)
{
    // If not on the ground, then stop
    if(!(GetEntityFlags(clientIndex) & FL_ONGROUND))
    {
        return;
    }

    //*********************************************************************
    //*                    INITIALIZE LEAP JUMP PROPERTIES                        *
    //*********************************************************************
    
    // Initialize variable
    static float flCountDown;
    
    // Verify that the client is zombie
    if(gClientData[clientIndex][Client_Zombie])
    {
        // Verify that the client is nemesis
        if(gClientData[clientIndex][Client_Nemesis])
        {
            // If nemesis leap disabled, then stop
            if(!gCvarList[CVAR_LEAP_NEMESIS].BoolValue) 
            {
                return;
            }
            
            // Gets countdown time
            flCountDown = gCvarList[CVAR_LEAP_NEMESIS_COUNTDOWN].FloatValue;
        }
        
        // If not
        else
        {
            // Switch type of leap jump
            switch(gCvarList[CVAR_LEAP_ZOMBIE].IntValue)
            {
                // If zombie leap disabled, then stop
                case 0 :
                {
                    return;
                }
                // If zombie leap just for single zombie
                case 2 :
                {
                    if(fnGetZombies() > 1) 
                    {
                        return;
                    }
                }
            }
            
            // Gets countdown time
            flCountDown = gCvarList[CVAR_LEAP_ZOMBIE_COUNTDOWN].FloatValue;
        }
    }
    
    // If not
    else
    {
        // Verify that the client is survivor
        if(gClientData[clientIndex][Client_Survivor])
        {
            // If survivor leap disabled, then stop
            if(!gCvarList[CVAR_LEAP_SURVIVOR].BoolValue)
            {
                return;
            }
            
            // Gets countdown time
            flCountDown = gCvarList[CVAR_LEAP_SURVIVOR_COUNTDOWN].FloatValue;
        }
        
        // If player is human, stop
        else return;
    }
    
    //*********************************************************************
    //*                     CHECK DELAY OF THE LEAP JUMP                       *
    //*********************************************************************
    
    // Initialize variable
    static float flDelay[MAXPLAYERS+1];
    
    // Returns the game time based on the game tick
    float flCurrentTime = GetGameTime();
    
    // Cooldown don't over yet, then stop
    if(flCurrentTime - flDelay[clientIndex] < flCountDown)
    {
        return;
    }
    
    // Update the leap jump delay
    flDelay[clientIndex] = flCurrentTime;
    
    //*********************************************************************
    //*                            DO THE LEAP JUMP                               *
    //*********************************************************************
    
    // Initialize some floats
    static float vAngle[3]; static float vOrigin[3]; static float vVelocity[3];
    
    // Gets client location and view direction
    GetClientAbsOrigin(clientIndex, vOrigin);
    GetClientEyeAngles(clientIndex, vAngle);
    
    // Store zero angle
    float flAngleZero = vAngle[0];    
    
    // Gets location angles
    vAngle[0] = -30.0;
    GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
    
    // Scale vector for the boost
    ScaleVector(vVelocity, gClientData[clientIndex][Client_Survivor] ? gCvarList[CVAR_LEAP_SURVIVOR_FORCE].FloatValue : (gClientData[clientIndex][Client_Nemesis] ? gCvarList[CVAR_LEAP_NEMESIS_FORCE].FloatValue : gCvarList[CVAR_LEAP_ZOMBIE_FORCE].FloatValue));
    
    // Restore eye angle
    vAngle[0] = flAngleZero;
    
    // Push the player
    TeleportEntity(clientIndex, vOrigin, vAngle, vVelocity);
    
    // Forward event to modules
    VEffectsOnClientJump(clientIndex);
}
