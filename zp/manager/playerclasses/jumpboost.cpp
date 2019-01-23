/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          jumpboost.cpp
 *  Type:          Module 
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
 * @brief Jumpboost module init function.
 **/
void JumpBoostOnInit(/*void*/)
{
    // Validate loaded map
    if(gServerData.MapLoaded)
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i, false))
            {
                // Update the client data
                JumpBoostOnClientInit(i);
            }
        }
    } 
    
    // If jump boost disabled, then unhook
    bool bJumpBoost = gCvarList[CVAR_JUMPBOOST].BoolValue;
    if(!bJumpBoost)
    {
        // Unhook player events
        UnhookEvent2("player_jump", JumpBoostOnClientJump, EventHookMode_Post);
        return;
    }
    
    // Hook player events
    HookEvent("player_jump", JumpBoostOnClientJump, EventHookMode_Post);
}

/**
 * @brief Hook jumpboost cvar changes.
 **/
void JumpBoostOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_JUMPBOOST]            = FindConVar("zp_jumpboost");
    gCvarList[CVAR_JUMPBOOST_MULTIPLIER] = FindConVar("zp_jumpboost_multiplier");
    gCvarList[CVAR_JUMPBOOST_MAX]        = FindConVar("zp_jumpboost_max"); 
    gCvarList[CVAR_JUMPBOOST_KNOCKBACK]  = FindConVar("zp_jumpboost_knockback");

    // Hook cvars
    HookConVarChange(gCvarList[CVAR_JUMPBOOST], JumpBoostOnCvarHook);
}

/**
 * Cvar hook callback (zp_jumpboost)
 * @brief Jumpboost module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void JumpBoostOnCvarHook(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    JumpBoostOnInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param clientIndex       The client index.
 **/
void JumpBoostOnClientInit(const int clientIndex)
{
    // If jumpboost is disabled, then stop
    bool bJumpBoost = gCvarList[CVAR_JUMPBOOST].BoolValue;
    if(!bJumpBoost)
    {
        // Unhook entity callbacks
        SDKUnhook(clientIndex, SDKHook_GroundEntChangedPost, JumpBoostOnClientEntChanged);
        return;
    }
    
    // Hook entity callbacks
    SDKHook(clientIndex, SDKHook_GroundEntChangedPost, JumpBoostOnClientEntChanged);
}

/**
 * Hook: GroundEntChangedPost
 * @brief Called right after the entities touching ground.
 * 
 * @param clientIndex       The client index.
 **/
public void JumpBoostOnClientEntChanged(const int clientIndex)
{
    // Verify that the client is exist
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }

    // If not on the ground, then stop
    if(!(GetEntityFlags(clientIndex) & FL_ONGROUND))
    {
        return;
    }
    
    // Validate movetype
    if(GetEntityMoveType(clientIndex) != MOVETYPE_LADDER)
    {
        // Reset gravity
        ToolsSetClientGravity(clientIndex, ClassGetGravity(gClientData[clientIndex].Class) + (gCvarList[CVAR_LEVEL_SYSTEM].BoolValue ? (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[clientIndex].Level)) : 0.0));
    }
}

/**
 * Event callback (player_jump)
 * @brief Client has been jumped.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action JumpBoostOnClientJump(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // Creates a single use next frame hook
    RequestFrame(view_as<RequestFrameCallback>(JumpBoostOnClientJumpPost), GetClientUserId(clientIndex));
}

/**
 * @brief Client has been jumped. *(Post)
 *
 * @param userID            The user id.
 **/
public void JumpBoostOnClientJumpPost(const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Initialize velocity vector
        static float vVelocity[3];
        
        // Gets client velocity
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

        // Sets new velocity
        ToolsClientVelocity(clientIndex, vVelocity, true, false);
    }
}

/**
 * @brief Called when player want do the leap jump.
 *
 * @param clientIndex       The client index.
 **/
void JumpBoostOnClientLeapJump(const int clientIndex)
{
    // Validate access
    if(!ModesIsLeapJump(gServerData.RoundMode))
    {
        return;
    }
    
    // If not on the ground, then stop
    if(!(GetEntityFlags(clientIndex) & FL_ONGROUND))
    {
        return;
    }

   /*_________________________________________________________________________________________________________________________________________*/
   
    // Validate type of leap jump
    switch(ClassGetLeapJump(gClientData[clientIndex].Class))
    {
        // If leap disabled, then stop
        case 0 :
        {
            return;
        }
        // If leap just for single player
        case 2 :
        {
            if((gClientData[clientIndex].Zombie ? fnGetZombies() : fnGetHumans()) > 1) 
            {
                return;
            }
        }
    }

    /*_________________________________________________________________________________________________________________________________________*/
    
    // Initialize delay
    static float flDelay[MAXPLAYERS+1];
    
    // Gets simulated game time
    float flCurrentTime = GetTickedTime();
    
    // Cooldown don't over yet, then stop
    if(flCurrentTime - flDelay[clientIndex] < ClassGetLeapCountdown(gClientData[clientIndex].Class))
    {
        return;
    }
    
    // Update the leap jump delay
    flDelay[clientIndex] = flCurrentTime;
    
    /*_________________________________________________________________________________________________________________________________________*/
    
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
    ScaleVector(vVelocity, ClassGetLeapForce(gClientData[clientIndex].Class));
    
    // Restore eye angle
    vAngle[0] = flAngleZero;
    
    // Push the player
    TeleportEntity(clientIndex, vOrigin, vAngle, vVelocity);
    
    // Forward event to modules
    VEffectsOnClientJump(clientIndex);
}