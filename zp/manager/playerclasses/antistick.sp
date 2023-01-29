/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          antistick.sp
 *  Type:          Module
 *  Description:   Antistick system.
 *
 *  Copyright (C) 2009-2023 Greyscale, Richard Helgeby
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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
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
enum /*AntiStickBoxBound*/
{
	BoxBound_FUR,       /** Front upper right */
	BoxBound_FUL,       /** etc.. */
	BoxBound_FDR,
	BoxBound_FDL,
	BoxBound_BUR,
	BoxBound_BUL,
	BoxBound_BDR,
	BoxBound_BDL,
	
	AntiStickBoxBound
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
	if (gServerData.MapLoaded)
	{
		// i = client index
		for (int i = 1; i <= MaxClients; i++)
		{
			// Validate client
			if (IsPlayerExist(i, false))
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
 * @param client            The client index.
 **/
void AntiStickOnClientInit(int client)
{
	// If antistick is disabled, then unhook
	bool bAntiStick = gCvarList.ANTISTICK.BoolValue;
	if (!bAntiStick)
	{
		// Unhook entity callbacks
		SDKUnhook(client, SDKHook_StartTouch, AntiStickOnStartTouch);
		return;
	}
	
	// Hook entity callbacks
	SDKHook(client, SDKHook_StartTouch, AntiStickOnStartTouch);
}

/**
 * @brief Creates commands for antistick module.
 **/
void AntiStickOnCommandInit(/*void*/)
{
	// Hook commands
	RegConsoleCmd("zstuck", AntiStickOnCommandCatched, "Unstucks player from the another prop.");
}

/**
 * @brief Hook antistick cvar changes.
 **/
void AntiStickOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.ANTISTICK = FindConVar("zp_antistick");
	
	// Hook cvars
	HookConVarChange(gCvarList.ANTISTICK, AntiStickOnCvarHook);
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
	if (!strcmp(oldValue, newValue, false))
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
 * @param client            The client index.
 * @param entity            The entity index of the entity being touched.
 **/
public void AntiStickOnStartTouch(int client, int entity)
{
	// If client is touching themselves, then leave them alone :P
	if (client == entity)
	{
		return;
	}

	// If touched entity isn't a valid client, then stop
	if (!IsPlayerExist(entity))
	{
		return;
	}

	// If the clients aren't colliding, then stop
	if (!AntiStickIsModelBoxColliding(client, entity))
	{
		return;
	}

	// From this point we know that client and entity is more or less within eachother
	LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_AntiStick, "Collision", "Player \"%N\" and \"%N\" are intersecting. Removing collisions.", client, entity);

	// Gets current collision groups of client
	int collisionGroup = AntiStickGetCollisionGroup(client);

	// Note: If players get stuck on change or stuck in a teleport, they'll
	//       get the COLLISION_GROUP_PUSHAWAY collision group, so check this
	//       one too.

	// If the client is in any other collision group than "off", than we must set them to off, to unstick
	if (collisionGroup != COLLISION_GROUP_PUSHAWAY)
	{
		// Disable collisions to unstick, and start timers to re-solidify
		AntiStickSetCollisionGroup(client, COLLISION_GROUP_PUSHAWAY);
		CreateTimer(0.0, AntiStickOnClientSolidify, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
	int client = GetClientOfUserId(userID);

	// Verify that the client is exist
	if (!client)
	{
		return Plugin_Stop;
	}

	// If the client collisions are already on, then stop
	if (AntiStickGetCollisionGroup(client) == COLLISION_GROUP_PLAYER)
	{
		return Plugin_Stop;
	}

	// Loop through all clients and check if client is stuck in them
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client is dead, then skip it
		if (!IsPlayerExist(i))
		{
			continue;
		}
		
		// Don't compare the same clients
		if (client == i)
		{
			continue;
		}
		
		// If the client is colliding with a client, then allow timer to continue
		if (AntiStickIsModelBoxColliding(client, i))
		{
			return Plugin_Continue;
		}
	}

	// Change collisions back to normal
	AntiStickSetCollisionGroup(client, COLLISION_GROUP_PLAYER);

	// Debug message. May be useful when calibrating antistick
	LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_AntiStick, "Collision", "Player \"%N\" is no longer intersecting anyone. Applying normal collisions.", client);
	return Plugin_Stop;
}

/**
 * Console command callback (zstuck)
 * @brief Unstucks player from the another prop.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action AntiStickOnCommandCatched(int client, int iArguments)
{
	// Validate client
	if (!IsPlayerExist(client))
	{
		return Plugin_Handled;
	}

	// Initialize vectors
	static float vPosition[3]; float vMaxs[3]; float vMins[3]; 

	// Gets client's location
	ToolsGetAbsOrigin(client, vPosition);
	
	// Gets client's min and max size vector
	GetClientMins(client, vMins);
	GetClientMaxs(client, vMaxs);

	// Create the hull trace
	TR_TraceHullFilter(vPosition, vPosition, vMins, vMaxs, MASK_SOLID, AntiStickFilter, client);

	// Returns if there was any kind of collision along the trace ray
	if (TR_DidHit())
	{
		// Gets victim index
		int victim = TR_GetEntityIndex();
		if (victim > 0)
		{
			// Gets current collision groups of entity
			switch (AntiStickGetCollisionGroup(victim))
			{
				case COLLISION_GROUP_PLAYER, COLLISION_GROUP_NPC : { /* < empty statement > */ }
				default : return Plugin_Handled;
			}
		}

		// Teleport player back on the spawn point
		SpawnTeleportToRespawn(client);
	}
	else
	{
		// Show block info
		TranslationPrintHintText(client, "unstucking prop block");
		
		// Emit error sound
		ClientCommand(client, "play buttons/button10.wav");    
	}
	
	// Return on success
	return Plugin_Handled;
}

/*
 * Stocks antistick API.
 */
 
/**
 * @brief Build the model box by finding all vertices.
 * 
 * @param client            The client index.
 * @param flBoundaries      Array with 'AntiStickBoxBounds' for indexes to return bounds into.
 * @param width             The width of the model box.
 **/
void AntiStickBuildModelBox(int client, float flBoundaries[AntiStickBoxBound][3], float flWidth)
{
	// Initialize vector variables
	static float vTwistAngle[3]; static float vCornerAngle[3]; static float vOriginLoc[3]; static float vSideLoc[3]; static float vFinalLoc[4][3];

	// Gets needed vector info
	ToolsGetAbsOrigin(client, vOriginLoc);

	// Sets pitch to 0
	vTwistAngle[1] = 90.0;
	vCornerAngle[1] = 0.0;

	// i = side index
	for (int x = 0; x < 4; x++)
	{
		// Jump to point on player left side.
		AntiStickJumpToPoint(vOriginLoc, vTwistAngle, flWidth / 2, vSideLoc);

		// From this point, jump to the corner, which would be half the width from the middle of a side
		AntiStickJumpToPoint(vSideLoc, vCornerAngle, flWidth / 2, vFinalLoc[x]);

		// Twist 90 degrees to find next side/corner
		vTwistAngle[1] += 90.0;
		vCornerAngle[1] += 90.0;

		// Fix angles
		if (vTwistAngle[1] > 180.0)
		{
			vTwistAngle[1] -= 360.0;
		}

		if (vCornerAngle[1] > 180.0)
		{
			vCornerAngle[1] -= 360.0;
		}
	}

	// Copy all horizontal model box data to array
	flBoundaries[BoxBound_FUR][0] = vFinalLoc[3][0];
	flBoundaries[BoxBound_FUR][1] = vFinalLoc[3][1];
	flBoundaries[BoxBound_FUL][0] = vFinalLoc[0][0];
	flBoundaries[BoxBound_FUL][1] = vFinalLoc[0][1];
	flBoundaries[BoxBound_FDR][0] = vFinalLoc[3][0];
	flBoundaries[BoxBound_FDR][1] = vFinalLoc[3][1];
	flBoundaries[BoxBound_FDL][0] = vFinalLoc[0][0];
	flBoundaries[BoxBound_FDL][1] = vFinalLoc[0][1];
	flBoundaries[BoxBound_BUR][0] = vFinalLoc[2][0];
	flBoundaries[BoxBound_BUR][1] = vFinalLoc[2][1];
	flBoundaries[BoxBound_BUL][0] = vFinalLoc[1][0];
	flBoundaries[BoxBound_BUL][1] = vFinalLoc[1][1];
	flBoundaries[BoxBound_BDR][0] = vFinalLoc[2][0];
	flBoundaries[BoxBound_BDR][1] = vFinalLoc[2][1];
	flBoundaries[BoxBound_BDL][0] = vFinalLoc[1][0];
	flBoundaries[BoxBound_BDL][1] = vFinalLoc[1][1];

	// Sets Z bounds
	static float vEyeLoc[3];
	GetClientEyePosition(client, vEyeLoc);

	flBoundaries[BoxBound_FUR][2] = vEyeLoc[2];
	flBoundaries[BoxBound_FUL][2] = vEyeLoc[2];
	flBoundaries[BoxBound_FDR][2] = vOriginLoc[2] + 15.0;
	flBoundaries[BoxBound_FDL][2] = vOriginLoc[2] + 15.0;
	flBoundaries[BoxBound_BUR][2] = vEyeLoc[2];
	flBoundaries[BoxBound_BUL][2] = vEyeLoc[2];
	flBoundaries[BoxBound_BDR][2] = vOriginLoc[2] + 15.0;
	flBoundaries[BoxBound_BDL][2] = vOriginLoc[2] + 15.0;
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
	static float vViewLoc[3];
	
	// Turn client angle, into a vector
	GetAngleVectors(vAngle, vViewLoc, NULL_VECTOR, NULL_VECTOR);
	
	// Normalize vector
	NormalizeVector(vViewLoc, vViewLoc);
	
	// Scale to the given distance
	ScaleVector(vViewLoc, flDistance);
	
	// Add the vectors together
	AddVectors(vVector, vViewLoc, vResult);
}

/**
 * @brief Gets the max/min value of a 3D box on any axis.
 * 
 * @param iAxis             The axis to check.
 * @param flBoundaries      The boundaries to check.
 * @param bMin              Return the min value instead.
 **/
float AntiStickGetBoxMaxBoundary(int iAxis, float flBoundaries[AntiStickBoxBound][3], bool bMin = false)
{
	// Creates 'outlier' with initial value of first boundary
	float flOutlier = flBoundaries[0][iAxis];
	
	// x = Boundary index. (Start at 1 because we initialized 'outlier' with the 0 index value)
	int iSize = sizeof(flBoundaries);
	for (int x = 1; x < iSize; x++)
	{
		if (!bMin && flBoundaries[x][iAxis] > flOutlier)
		{
			flOutlier = flBoundaries[x][iAxis];
		}
		else if (bMin && flBoundaries[x][iAxis] < flOutlier)
		{
			flOutlier = flBoundaries[x][iAxis];
		}
	}
	
	// Return value
	return flOutlier;
}

/**
 * @brief Checks if a player is currently stuck within another player.
 *
 * @param client     1      The first client index.
 * @param client     2      The second client index.
 * @return                  True if they are stuck together, false if not.
 **/
bool AntiStickIsModelBoxColliding(int clientIndex1, int clientIndex2)
{
	// Initialize vector variables
	float client1modelbox[AntiStickBoxBound][3];
	float client2modelbox[AntiStickBoxBound][3];
	
	// Build model boxes for each client
	AntiStickBuildModelBox(clientIndex1, client1modelbox, ANTISTICK_DEFAULT_HULL_WIDTH);
	AntiStickBuildModelBox(clientIndex2, client2modelbox, ANTISTICK_DEFAULT_HULL_WIDTH);
	
	// Compare x values
	float max1x = AntiStickGetBoxMaxBoundary(0, client1modelbox);
	float max2x = AntiStickGetBoxMaxBoundary(0, client2modelbox);
	float min1x = AntiStickGetBoxMaxBoundary(0, client1modelbox, true);
	float min2x = AntiStickGetBoxMaxBoundary(0, client2modelbox, true);
	
	if (max1x < min2x || min1x > max2x)
	{
		return false;
	}
	
	// Compare y values
	float max1y = AntiStickGetBoxMaxBoundary(1, client1modelbox);
	float max2y = AntiStickGetBoxMaxBoundary(1, client2modelbox);
	float min1y = AntiStickGetBoxMaxBoundary(1, client1modelbox, true);
	float min2y = AntiStickGetBoxMaxBoundary(1, client2modelbox, true);
	
	if (max1y < min2y || min1y > max2y)
	{
		return false;
	}
	
	// Compare z values
	float max1z = AntiStickGetBoxMaxBoundary(2, client1modelbox);
	float max2z = AntiStickGetBoxMaxBoundary(2, client2modelbox);
	float min1z = AntiStickGetBoxMaxBoundary(2, client1modelbox, true);
	float min2z = AntiStickGetBoxMaxBoundary(2, client2modelbox, true);
	
	if (max1z < min2z || min1z > max2z)
	{
		return false;
	}
	
	// They are intersecting
	return true;
}

/**
 * @brief Used to iterate all the clients collision within a sphere.
 * 
 * @param it                The iterator.
 * @param vPosition         The sphere origin.
 * @param flRadius          The sphere radius.
 **/
int AntiStickFindPlayerInSphere(int &it, float vPosition[3], float flRadius)
{
	// Initialize vector variables
	float clientmodelbox[AntiStickBoxBound][3];

	// i = client index
	for (int i = it; i <= MaxClients; i++)
	{
		// Validate client
		if (IsPlayerExist(i))
		{
			// Build model boxes for client
			AntiStickBuildModelBox(i, clientmodelbox, ANTISTICK_DEFAULT_HULL_WIDTH);

			// Validate collision
			if (AntiStickIsBoxIntersectingSphere(clientmodelbox, vPosition, flRadius))
			{ 
				// Move iterator
				it = i + 1;
		
				// Return index
				return i;
			}
		}
	}
	
	// Client doesn't exist
	return -1;
}

/**
 * @brief Returns true if there's an intersection between box and sphere.
 * 
 * @param flBoundaries      Array with 'AntiStickBoxBound' for indexes to return bounds into.
 * @param vPosition         The sphere center.
 * @param flRadius          The sphere radius.
 * 
 * @return                  True or false. 
 *
 * @link https://github.com/erich666/GraphicsGems/blob/master/gems/BoxSphere.c
 **/
bool AntiStickIsBoxIntersectingSphere(float flBoundaries[AntiStickBoxBound][3], float vPosition[3], float flRadius)
{
	// See graphics gems, box-sphere intersection
	float flDelta; float flDistance;

	/// Unrolled the loop.. this is a big cycle stealer...
	
	// Compare x values
	float maxBx = AntiStickGetBoxMaxBoundary(0, flBoundaries);
	float minBx = AntiStickGetBoxMaxBoundary(0, flBoundaries, true);  

	if (vPosition[0] < minBx) 
	{
		flDelta = vPosition[0] - minBx;
		flDistance += flDelta * flDelta;
	}
	else if (vPosition[0] > maxBx) 
	{   
		flDelta = vPosition[0] - maxBx;
		flDistance += flDelta * flDelta;   
	}
	
	// Compare y values
	float maxBy = AntiStickGetBoxMaxBoundary(1, flBoundaries);
	float minBy = AntiStickGetBoxMaxBoundary(1, flBoundaries, true);  
	
	if (vPosition[1] < minBy) 
	{
		flDelta = vPosition[1] - minBy;
		flDistance += flDelta * flDelta;
	}
	else if (vPosition[1] > maxBy) 
	{   
		flDelta = vPosition[1] - maxBy;
		flDistance += flDelta * flDelta;   
	}
	
	// Compare z values
	float maxBz = AntiStickGetBoxMaxBoundary(2, flBoundaries);
	float minBz = AntiStickGetBoxMaxBoundary(2, flBoundaries, true); 
	
	if (vPosition[2] < minBz) 
	{
		flDelta = vPosition[2] - minBz;
		flDistance += flDelta * flDelta;
	}
	else if (vPosition[2] > maxBz) 
	{   
		flDelta = vPosition[2] - maxBz;
		flDistance += flDelta * flDelta;   
	}

	// Return true on the collision
	return flDistance <= (flRadius * flRadius);
}

/**
 * @brief Sets the collision group on a client.
 *
 * @param client            The client index.
 * @param collisionGroup    The group flag.
 **/
void AntiStickSetCollisionGroup(int client, int collisionGroup)
{
	SetEntProp(client, Prop_Data, "m_CollisionGroup", collisionGroup);
}

/**
 * @brief Gets the collision group on a client.
 *
 * @param client            The client index.
 * @return                  The collision group on the client.
 **/
int AntiStickGetCollisionGroup(int client)
{
	return GetEntProp(client, Prop_Data, "m_CollisionGroup");
}

/**
 * @brief Trace filter.
 *  
 * @param entity            The entity index.
 * @param contentsMask      The contents mask.
 * @param client            The client index.
 * @return                  True or false.
 **/
public bool AntiStickFilter(int entity, int contentsMask, int client) 
{
	return (entity != client);
}
