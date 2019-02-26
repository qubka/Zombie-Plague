/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          antistick.cpp
 *  Type:          Module
 *  Description:   Antistick system.
 *
 *  Copyright (C) 2009-2018  Greyscale, Richard Helgeby
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
 * @section Collision values.
 **/
#define COLLISION_GROUP_NONE                0   /** Default; collides with static and dynamic objects. */
#define COLLISION_GROUP_DEBRIS              1   /** Collides with nothing but world and static stuff. */
#define COLLISION_GROUP_DEBRIS_TRIGGER      2   /** Same as debris, but hits triggers. */
#define COLLISION_GROUP_INTERACTIVE_DEBRIS  3   /** Collides with everything except other interactive debris or debris. */
#define COLLISION_GROUP_INTERACTIVE         4   /** Collides with everything except interactive debris or debris. */
#define COLLISION_GROUP_PLAYER              5   /** This is the default behavior expected for most prop_physics. */
#define COLLISION_GROUP_BREAKABLE_GLASS     6   /** Special group for glass debris. */
#define COLLISION_GROUP_VEHICLE             7   /** Collision group for driveable vehicles. */
#define COLLISION_GROUP_PLAYER_MOVEMENT     8   /** For HL2, same as Collision_Group_Player. */
#define COLLISION_GROUP_NPC                 9   /** Generic NPC group. */
#define COLLISION_GROUP_IN_VEHICLE          10  /** For any entity inside a vehicle. */
#define COLLISION_GROUP_WEAPON              11  /** For any weapons that need collision detection. */
#define COLLISION_GROUP_VEHICLE_CLIP        12  /** Vehicle clip brush to restrict vehicle movement. */
#define COLLISION_GROUP_PROJECTILE          13  /** Projectiles. */
#define COLLISION_GROUP_DOOR_BLOCKER        14  /** Blocks entities not permitted to get near moving doors. */
#define COLLISION_GROUP_PASSABLE_DOOR       15  /** Doors that the player shouldn't collide with. */
#define COLLISION_GROUP_DISSOLVING          16  /** Things that are dissolving are in this group. */
#define COLLISION_GROUP_PUSHAWAY            17  /** Nonsolid on client and server, pushaway in player code. */
#define COLLISION_GROUP_NPC_ACTOR           18  /** Used so NPCs in scripts ignore the player. */

#define ANTISTICK_COLLISIONS_OFF COLLISION_GROUP_PUSHAWAY
#define ANTISTICK_COLLISIONS_ON  COLLISION_GROUP_PLAYER
/**
 * @endsection
 **/

/**
 * Default player hull width.
 **/
#define ANTISTICK_DEFAULT_HULL_WIDTH 32.0

/**
 * @section List of components that make up the model rectangular boundaries.
 * 
 * F = Front
 * B = Back
 * L = Left
 * R = Right
 * U = Upper
 * D = Down
 **/
enum AntiStickBoxBound
{
    BoxBound_FUR,       /** Front upper right */
    BoxBound_FUL,       /** etc.. */
    BoxBound_FDR,
    BoxBound_FDL,
    BoxBound_BUR,
    BoxBound_BUL,
    BoxBound_BDR,
    BoxBound_BDL,
};
/**
 * @endsection
 **/
 
/**
 * @brief Antistick module init function.
 **/
void AntiStickOnInit(/*void*/)
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
                AntiStickOnClientInit(i);
            }
        }
    } 
}

/**
 * @brief Client has been joined.
 * 
 * @param clientIndex       The client index.
 **/
void AntiStickOnClientInit(int clientIndex)
{
    // If antistick is disabled, then unhook
    bool bAntiStick = gCvarList[CVAR_ANTISTICK].BoolValue;
    if(!bAntiStick)
    {
        // Unhook entity callbacks
        SDKUnhook(clientIndex, SDKHook_StartTouch, AntiStickOnStartTouch);
        return;
    }
    
    // Hook entity callbacks
    SDKHook(clientIndex, SDKHook_StartTouch, AntiStickOnStartTouch);
}

/**
 * @brief Creates commands for antistick module.
 **/
void AntiStickOnCommandInit(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zp_antistick_prop", AntiStickOnCommandCatched, "Unstucks player from the another prop.");
}

/**
 * @brief Hook antistick cvar changes.
 **/
void AntiStickOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_ANTISTICK] = FindConVar("zp_antistick");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_ANTISTICK], AntiStickOnCvarHook);
}

/**
 * Cvar hook callback (zp_antistick)
 * @brief Antistick module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void AntiStickOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    AntiStickOnInit();
}

/**
 * Hook: StartTouch
 * @brief Called right before the entities touch each other.
 * 
 * @param clientIndex       The client index.
 * @param entityIndex       The entity index of the entity being touched.
 **/
public void AntiStickOnStartTouch(int clientIndex, int entityIndex)
{
    // Verify that the client is exist
    if(!IsPlayerExist(clientIndex))
    {
        return;
    }
    
    // If client is touching themselves, then leave them alone :P
    if(clientIndex == entityIndex)
    {
        return;
    }

    // If touched entity isn't a valid client, then stop
    if(!IsPlayerExist(entityIndex))
    {
        return;
    }

    // If the clients aren't colliding, then stop
    if(!AntiStickIsModelBoxColliding(clientIndex, entityIndex))
    {
        return;
    }

    // From this point we know that client and entity is more or less within eachother
    LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_AntiStick, "Collision", "Player \"%N\" and \"%N\" are intersecting. Removing collisions.", clientIndex, entityIndex);

    // Gets current collision groups of client and entity
    int collisionGroup = AntiStickGetCollisionGroup(clientIndex);

    // Note: If players get stuck on change or stuck in a teleport, they'll
    //       get the COLLISION_GROUP_PUSHAWAY collision group, so check this
    //       one too.

    // If the client is in any other collision group than "off", than we must set them to off, to unstick
    if(collisionGroup != ANTISTICK_COLLISIONS_OFF)
    {
        // Disable collisions to unstick, and start timers to re-solidify
        AntiStickSetCollisionGroup(clientIndex, ANTISTICK_COLLISIONS_OFF);
        CreateTimer(0.0, AntiStickOnClientSolidify, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Timer callback, checks solidify on a client.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action AntiStickOnClientSolidify(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Verify that the client is exist
    if(!clientIndex)
    {
        return Plugin_Stop;
    }

    // If the client collisions are already on, then stop
    if(AntiStickGetCollisionGroup(clientIndex) == ANTISTICK_COLLISIONS_ON)
    {
        return Plugin_Stop;
    }

    // Loop through all clients and check if client is stuck in them
    for(int i = 1; i <= MaxClients; i++)
    {
        // If the client is dead, then skip it
        if(!IsPlayerExist(i))
        {
            continue;
        }
        
        // Don't compare the same clients
        if(clientIndex == i)
        {
            continue;
        }
        
        // If the client is colliding with a client, then allow timer to continue
        if(AntiStickIsModelBoxColliding(clientIndex, i))
        {
            return Plugin_Continue;
        }
    }

    // Change collisions back to normal
    AntiStickSetCollisionGroup(clientIndex, ANTISTICK_COLLISIONS_ON);

    // Debug message. May be useful when calibrating antistick
    LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_AntiStick, "Collision", "Player \"%N\" is no longer intersecting anyone. Applying normal collisions.", clientIndex);
    return Plugin_Stop;
}

/**
 * Console command callback (zp_antistick_prop)
 * @brief Unstucks player from the another prop.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action AntiStickOnCommandCatched(int clientIndex, int iArguments)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return Plugin_Handled;
    }
    
    /* 
     * Checks to see if a player would collide with MASK_SOLID. (i.e. they would be stuck)
     * Inflates player mins/maxs a little bit for better protection against sticking.
     * Thanks to Andersso for the basis of this function.
     */
    
    // Initialize vector variables
    static float vOrigin[3]; float vMax[3]; float vMin[3]; 

    // Get client's location
    GetClientAbsOrigin(clientIndex, vOrigin);
    
    // Get the client's min and max size vector
    GetClientMins(clientIndex, vMin);
    GetClientMaxs(clientIndex, vMax);

    // Create the hull trace
    Handle hTrace = TR_TraceHullFilterEx(vOrigin, vOrigin, vMin, vMax, MASK_SOLID, AntiStickFilter, clientIndex);

    // Returns if there was any kind of collision along the trace ray
    if(TR_DidHit(hTrace))
    {
        // Gets spawn position
        SpawnGetRandomPosition(vOrigin);
        
        // Teleport player back on the spawn point
        TeleportEntity(clientIndex, vOrigin, NULL_VECTOR, NULL_VECTOR);
    }
    else
    {
        // Show block info
        TranslationPrintHintText(clientIndex, "unstucking prop block");
                
        // Emit error sound
        ClientCommand(clientIndex, "play buttons/button11.wav");    
    }
    
    // Close the trace
    delete hTrace;
    return Plugin_Handled;
}

/*
 * Stocks antistick API.
 */

/**
 * @brief Build the model box by finding all vertices.
 * 
 * @param clientIndex       The client index.
 * @param boundaries        Array with 'AntiStickBoxBounds' for indexes to return bounds into.
 * @param width             The width of the model box.
 **/
void AntiStickBuildModelBox(int clientIndex, float boundaries[AntiStickBoxBound][3], float flWidth)
{
    // Initialize vector variables
    static float vClientLoc[3];
    static float vTwistAngle[3];
    static float vCornerAngle[3];
    static float vSideLoc[3];
    static float vFinalLoc[4][3];

    // Gets needed vector info
    GetClientAbsOrigin(clientIndex, vClientLoc);

    // Sets pitch to 0
    vTwistAngle[1] = 90.0;
    vCornerAngle[1] = 0.0;

    for(int x = 0; x < 4; x++)
    {
        // Jump to point on player left side.
        AntiStickJumpToPoint(vClientLoc, vTwistAngle, flWidth / 2, vSideLoc);

        // From this point, jump to the corner, which would be half the width from the middle of a side
        AntiStickJumpToPoint(vSideLoc, vCornerAngle, flWidth / 2, vFinalLoc[x]);

        // Twist 90 degrees to find next side/corner
        vTwistAngle[1] += 90.0;
        vCornerAngle[1] += 90.0;

        // Fix angles
        if(vTwistAngle[1] > 180.0)
        {
            vTwistAngle[1] -= 360.0;
        }

        if(vCornerAngle[1] > 180.0)
        {
            vCornerAngle[1] -= 360.0;
        }
    }

    // Copy all horizontal model box data to array
    boundaries[BoxBound_FUR][0] = vFinalLoc[3][0];
    boundaries[BoxBound_FUR][1] = vFinalLoc[3][1];
    boundaries[BoxBound_FUL][0] = vFinalLoc[0][0];
    boundaries[BoxBound_FUL][1] = vFinalLoc[0][1];
    boundaries[BoxBound_FDR][0] = vFinalLoc[3][0];
    boundaries[BoxBound_FDR][1] = vFinalLoc[3][1];
    boundaries[BoxBound_FDL][0] = vFinalLoc[0][0];
    boundaries[BoxBound_FDL][1] = vFinalLoc[0][1];
    boundaries[BoxBound_BUR][0] = vFinalLoc[2][0];
    boundaries[BoxBound_BUR][1] = vFinalLoc[2][1];
    boundaries[BoxBound_BUL][0] = vFinalLoc[1][0];
    boundaries[BoxBound_BUL][1] = vFinalLoc[1][1];
    boundaries[BoxBound_BDR][0] = vFinalLoc[2][0];
    boundaries[BoxBound_BDR][1] = vFinalLoc[2][1];
    boundaries[BoxBound_BDL][0] = vFinalLoc[1][0];
    boundaries[BoxBound_BDL][1] = vFinalLoc[1][1];

    // Sets Z bounds
    static float vEyeLoc[3];
    GetClientEyePosition(clientIndex, vEyeLoc);

    boundaries[BoxBound_FUR][2] = vEyeLoc[2];
    boundaries[BoxBound_FUL][2] = vEyeLoc[2];
    boundaries[BoxBound_FDR][2] = vClientLoc[2] + 15.0;
    boundaries[BoxBound_FDL][2] = vClientLoc[2] + 15.0;
    boundaries[BoxBound_BUR][2] = vEyeLoc[2];
    boundaries[BoxBound_BUL][2] = vEyeLoc[2];
    boundaries[BoxBound_BDR][2] = vClientLoc[2] + 15.0;
    boundaries[BoxBound_BDL][2] = vClientLoc[2] + 15.0;
}

/**
 * @brief Jumps from a point to another based off angle and distance.
 * 
 * @param flVector          Point to jump from.
 * @param flAngle           Angle to base jump off of.
 * @param flDistance        Distance to jump
 * @param flResult          Resultant point.
 **/
void AntiStickJumpToPoint(float vVector[3], float vAngle[3], float flDistance, float vResult[3])
{
    // Initialize vector variable
    static float vViewVector[3];
    
    // Turn client angle, into a vector
    GetAngleVectors(vAngle, vViewVector, NULL_VECTOR, NULL_VECTOR);
    
    // Normalize vector
    NormalizeVector(vViewVector, vViewVector);
    
    // Scale to the given distance
    ScaleVector(vViewVector, flDistance);
    
    // Add the vectors together
    AddVectors(vVector, vViewVector, vResult);
}

/**
 * @brief Gets the max/min value of a 3D box on any axis.
 * 
 * @param Axis              The axis to check.
 * @param boundaries        The boundaries to check.
 * @param iMin              Return the min value instead.
 **/
float AntiStickGetBoxMaxBoundary(int Axis, float boundaries[AntiStickBoxBound][3],bool iMin = false)
{
    // Creates 'outlier' with initial value of first boundary
    float outlier = boundaries[0][Axis];
    
    // x = Boundary index. (Start at 1 because we initialized 'outlier' with the 0 index value)
    int iSize = sizeof(boundaries);
    for(int x = 1; x < iSize; x++)
    {
        if(!iMin && boundaries[x][Axis] > outlier)
        {
            outlier = boundaries[x][Axis];
        }
        else if(iMin && boundaries[x][Axis] < outlier)
        {
            outlier = boundaries[x][Axis];
        }
    }
    
    // Return value
    return outlier;
}

/**
 * @brief Checks if a player is currently stuck within another player.
 *
 * @param client1           The first client index.
 * @param client2           The second client index.
 * @return                  True if they are stuck together, false if not.
 **/
bool AntiStickIsModelBoxColliding(int client1, int client2)
{
    // Initialize vector variables
    float client1modelbox[AntiStickBoxBound][3];
    float client2modelbox[AntiStickBoxBound][3];
    
    // Build model boxes for each client
    AntiStickBuildModelBox(client1, client1modelbox, ANTISTICK_DEFAULT_HULL_WIDTH);
    AntiStickBuildModelBox(client2, client2modelbox, ANTISTICK_DEFAULT_HULL_WIDTH);
    
    // Compare x values
    float max1x = AntiStickGetBoxMaxBoundary(0, client1modelbox);
    float max2x = AntiStickGetBoxMaxBoundary(0, client2modelbox);
    float min1x = AntiStickGetBoxMaxBoundary(0, client1modelbox, true);
    float min2x = AntiStickGetBoxMaxBoundary(0, client2modelbox, true);
    
    if(max1x < min2x || min1x > max2x)
    {
        return false;
    }
    
    // Compare y values
    float max1y = AntiStickGetBoxMaxBoundary(1, client1modelbox);
    float max2y = AntiStickGetBoxMaxBoundary(1, client2modelbox);
    float min1y = AntiStickGetBoxMaxBoundary(1, client1modelbox, true);
    float min2y = AntiStickGetBoxMaxBoundary(1, client2modelbox, true);
    
    if(max1y < min2y || min1y > max2y)
    {
        return false;
    }
    
    // Compare z values
    float max1z = AntiStickGetBoxMaxBoundary(2, client1modelbox);
    float max2z = AntiStickGetBoxMaxBoundary(2, client2modelbox);
    float min1z = AntiStickGetBoxMaxBoundary(2, client1modelbox, true);
    float min2z = AntiStickGetBoxMaxBoundary(2, client2modelbox, true);
    
    if(max1z < min2z || min1z > max2z)
    {
        return false;
    }
    
    // They are intersecting
    return true;
}

/**
 * @brief Sets the collision group on a client.
 *
 * @param clientIndex       The client index.
 * @param collisiongroup    Collision group flag.
 **/
void AntiStickSetCollisionGroup(int clientIndex, int collisiongroup)
{
    SetEntData(clientIndex, g_iOffset_PlayerCollision, collisiongroup, _, true);
}

/**
 * @brief Gets the collision group on a client.
 *
 * @param clientIndex       The client index.
 * @return                  The collision group on the client.
 **/
int AntiStickGetCollisionGroup(int clientIndex)
{
    return GetEntData(clientIndex, g_iOffset_PlayerCollision);
}

/**
 * @brief Trace filter.
 *  
 * @param entityIndex       The entity index.
 * @param contentsMask      The contents mask.
 * @param clientIndex       The client index.
 *
 * @return                  True or false.
 **/
public bool AntiStickFilter(int entityIndex, int contentsMask, int clientIndex) 
{
    return (entityIndex != clientIndex);
}