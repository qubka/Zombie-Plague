/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          antistick.cpp
 *  Type:          Game
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
 */

/**
 * @section Collision values.
 */
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

#define ANTISTICK_COLLISIONS_OFF COLLISION_GROUP_DEBRIS_TRIGGER
#define ANTISTICK_COLLISIONS_ON COLLISION_GROUP_PLAYER
/**
 * @endsection
 */

/**
 * Default player hull width.
 */
#define ANTISTICK_DEFAULT_HULL_WIDTH 32.0

/**
 * List of components that make up the model's rectangular boundaries.
 * 
 * F = Front
 * B = Back
 * L = Left
 * R = Right
 * U = Upper
 * D = Down
 */
enum AntiStickBoxBound
{
    BoxBound_FUR = 0, /** Front upper right */
    BoxBound_FUL,     /** etc.. */
    BoxBound_FDR,
    BoxBound_FDL,
    BoxBound_BUR,
    BoxBound_BUL,
    BoxBound_BDR,
    BoxBound_BDL,
}

/**
 * Client is joining the server.
 * 
 * @param clientIndex    The client index.
 */
void AntiStickClientInit(int clientIndex)
{
	// Hook entity callbacks
	SDKHook(clientIndex, SDKHook_StartTouch, AntiStickStartTouch);
}

/**
 * Callback function for StartTouch.
 * 
 * @param clientIndex        The client index.
 * @param entityIndex        The entity index of the entity being touched.
 */
public void AntiStickStartTouch(int clientIndex, int entityIndex)
{
	// If antistick is disabled, then stop.
	bool bAntiStick = GetConVarBool(gCvarList[CVAR_GAME_CUSTOM_ANTISTICK]);
	if(!bAntiStick)
	{
		return;
	}

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
	LogEvent(false, LogType_Normal, LOG_DEBUG, LogModule_Antistick, "Collision", "Player \"%N\" and \"%N\" are intersecting. Removing collisions.", clientIndex, entityIndex);

	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Get current collision groups of client and entity
	int collisionGroup = cBasePlayer->m_iCollisionGroup;

	// Note: If zombies get stuck on infection or stuck in a teleport, they'll
	//       get the COLLISION_GROUP_PUSHAWAY collision group, so check this
	//       one too.

	// If the client is in any other collision group than "off", than we must set them to off, to unstick
	if(collisionGroup != ANTISTICK_COLLISIONS_OFF)
	{
		// Disable collisions to unstick, and start timers to re-solidify
		cBasePlayer->m_iCollisionGroup = ANTISTICK_COLLISIONS_OFF;
		CreateTimer(0.0, AntiStickSolidifyTimer, cBasePlayer, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	}
}

/**
 * Callback for solidify timer.
 * 
 * @param hTimer			The timer handle.
 * @param cBasePlayer       The client index.
 */
public Action AntiStickSolidifyTimer(Handle hTimer, CBasePlayer* cBasePlayer)
{
	// Verify that the client is exist
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_STOP;
	}

	// If the client's collisions are already on, then stop
	if(cBasePlayer->m_iCollisionGroup == ANTISTICK_COLLISIONS_ON)
	{
		return ACTION_STOP;
	}

	// Loop through all clients and check ifclient is stuck in them
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client is dead, then skip it
		if(!IsPlayerExist(i))
		{
			continue;
		}
		
		// Don't compare the same clients
		if(cBasePlayer->Index == i)
		{
			continue;
		}
		
		// If the client is colliding with a client, then allow timer to continue
		if(AntiStickIsModelBoxColliding(cBasePlayer->Index, i))
		{
			return ACTION_CONTINUE;
		}
	}

	// Change collisions back to normal
	cBasePlayer->m_iCollisionGroup = ANTISTICK_COLLISIONS_ON;

	// Debug message. May be useful when calibrating antistick
	LogEvent(false, LogType_Normal, LOG_DEBUG, LogModule_Antistick, "Collision", "Player \"%N\" is no longer intersecting anyone. Applying normal collisions.", cBasePlayer->Index);
	return ACTION_STOP;
}

/**
 * Build the model box by finding all vertices.
 * 
 * @param clientIndex       The client index.
 * @param boundaries    	Array with 'AntiStickBoxBounds' for indexes to return bounds into.
 * @param width         	The width of the model box.
 */
stock void AntiStickBuildModelBox(int clientIndex, float boundaries[AntiStickBoxBound][3], float flWidth)
{
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	static float flClientLoc[3];
	static float flTwistAngle[3];
	static float flCornerAngle[3];
	static float flSideLoc[3];
	static float flFinalLoc[4][3];

	// Get needed vector info
	cBasePlayer->m_flGetOrigin(flClientLoc);

	// Set the pitch to 0
	flTwistAngle[1] = 90.0;
	flCornerAngle[1] = 0.0;

	for (int x = 0; x < 4; x++)
	{
		// Jump to point on player's left side.
		AntiStickJumpToPoint(flClientLoc, flTwistAngle, flWidth / 2, flSideLoc);

		// From this point, jump to the corner, which would be half the width from the middle of a side
		AntiStickJumpToPoint(flSideLoc, flCornerAngle, flWidth / 2, flFinalLoc[x]);

		// Twist 90 degrees to find next side/corner
		flTwistAngle[1] += 90.0;
		flCornerAngle[1] += 90.0;

		// Fix angles
		if(flTwistAngle[1] > 180.0)
		{
			flTwistAngle[1] -= 360.0;
		}

		if(flCornerAngle[1] > 180.0)
		{
			flCornerAngle[1] -= 360.0;
		}
	}

	// Copy all horizontal model box data to array
	boundaries[BoxBound_FUR][0] = flFinalLoc[3][0];
	boundaries[BoxBound_FUR][1] = flFinalLoc[3][1];
	boundaries[BoxBound_FUL][0] = flFinalLoc[0][0];
	boundaries[BoxBound_FUL][1] = flFinalLoc[0][1];
	boundaries[BoxBound_FDR][0] = flFinalLoc[3][0];
	boundaries[BoxBound_FDR][1] = flFinalLoc[3][1];
	boundaries[BoxBound_FDL][0] = flFinalLoc[0][0];
	boundaries[BoxBound_FDL][1] = flFinalLoc[0][1];
	boundaries[BoxBound_BUR][0] = flFinalLoc[2][0];
	boundaries[BoxBound_BUR][1] = flFinalLoc[2][1];
	boundaries[BoxBound_BUL][0] = flFinalLoc[1][0];
	boundaries[BoxBound_BUL][1] = flFinalLoc[1][1];
	boundaries[BoxBound_BDR][0] = flFinalLoc[2][0];
	boundaries[BoxBound_BDR][1] = flFinalLoc[2][1];
	boundaries[BoxBound_BDL][0] = flFinalLoc[1][0];
	boundaries[BoxBound_BDL][1] = flFinalLoc[1][1];

	// Set Z bounds
	static float flEyeLoc[3];
	cBasePlayer->m_flGetEyePosition(flEyeLoc);

	boundaries[BoxBound_FUR][2] = flEyeLoc[2];
	boundaries[BoxBound_FUL][2] = flEyeLoc[2];
	boundaries[BoxBound_FDR][2] = flClientLoc[2] + 15.0;
	boundaries[BoxBound_FDL][2] = flClientLoc[2] + 15.0;
	boundaries[BoxBound_BUR][2] = flEyeLoc[2];
	boundaries[BoxBound_BUL][2] = flEyeLoc[2];
	boundaries[BoxBound_BDR][2] = flClientLoc[2] + 15.0;
	boundaries[BoxBound_BDL][2] = flClientLoc[2] + 15.0;
}

/**
 * Jumps from a point to another based off angle and distance.
 * 
 * @param flVector      Point to jump from.
 * @param flAngle       Angle to base jump off of.
 * @param flDistance  	Distance to jump
 * @param flResult    	Resultant point.
 */
stock void AntiStickJumpToPoint(const float flVector[3], const float flAngle[3], float flDistance, float flResult[3])
{
    float flViewVector[3];
    
    // Turn client angle, into a vector
    GetAngleVectors(flAngle, flViewVector, NULL_VECTOR, NULL_VECTOR);
    
    // Normalize vector
    NormalizeVector(flViewVector, flViewVector);
    
    // Scale to the given distance
    ScaleVector(flViewVector, flDistance);
    
    // Add the vectors together
    AddVectors(flVector, flViewVector, flResult);
}

/**
 * Get the max/min value of a 3D box on any axis.
 * 
 * @param Axis          The axis to check.
 * @param boundaries    The boundaries to check.
 * @param iMin          Return the min value instead.
 */
stock float AntiStickGetBoxMaxBoundary(int Axis, float boundaries[AntiStickBoxBound][3], bool iMin = false)
{
    // Create 'outlier' with initial value of first boundary
    float outlier = boundaries[0][Axis];
    
    // x = Boundary index. (Start at 1 because we initialized 'outlier' with the 0 index's value)
    int iSize = sizeof(boundaries);
    for (int x = 1; x < iSize; x++)
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
 * Checks ifa player is currently stuck within another player.
 *
 * @param client1   The first client index.
 * @param client2   The second client index.
 * @return          True ifthey are stuck together, false ifnot.
 */
stock bool AntiStickIsModelBoxColliding(int client1, int client2)
{
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