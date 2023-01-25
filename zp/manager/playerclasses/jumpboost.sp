/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          jumpboost.sp
 *  Type:          Module 
 *  Description:   Modified jump vector magnitudes.
 *
 *  Copyright (C) 2015-2016 qubka (Nikita Ushakov)
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
 * @brief Jumpboost module init function.
 **/
void JumpBoostOnInit(/*void*/)
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
				JumpBoostOnClientInit(i);
			}
		}
	} 
	
	// If jump boost disabled, then unhook
	bool bJumpBoost = gCvarList.JUMPBOOST.BoolValue;
	if (!bJumpBoost)
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
	gCvarList.JUMPBOOST            = FindConVar("zp_jumpboost");
	gCvarList.JUMPBOOST_MULTIPLIER = FindConVar("zp_jumpboost_multiplier");
	gCvarList.JUMPBOOST_MAX        = FindConVar("zp_jumpboost_max"); 

	// Hook cvars
	HookConVarChange(gCvarList.JUMPBOOST, JumpBoostOnCvarHook);
}

/**
 * Cvar hook callback (zp_jumpboost)
 * @brief Jumpboost module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void JumpBoostOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Validate new value
	if (oldValue[0] == newValue[0])
	{
		return;
	}
	
	// Forward event to modules
	JumpBoostOnInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.
 **/
void JumpBoostOnClientInit(int client)
{
	// If jumpboost is disabled, then stop
	bool bJumpBoost = gCvarList.JUMPBOOST.BoolValue;
	if (!bJumpBoost)
	{
		// Unhook entity callbacks
		SDKUnhook(client, SDKHook_GroundEntChangedPost, JumpBoostOnClientEntChanged);
		return;
	}
	
	// Hook entity callbacks
	SDKHook(client, SDKHook_GroundEntChangedPost, JumpBoostOnClientEntChanged);
}

/**
 * Hook: GroundEntChangedPost
 * @brief Called right after the entities touching ground.
 * 
 * @param client            The client index.
 **/
public void JumpBoostOnClientEntChanged(int client)
{
	// If not on the ground, then stop
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		return;
	}
	
	// Validate movetype
	if (GetEntityMoveType(client) != MOVETYPE_LADDER)
	{
		// Resets gravity
		ToolsSetGravity(client, ClassGetGravity(gClientData[client].Class) + (gCvarList.LEVEL_SYSTEM.BoolValue ? (gCvarList.LEVEL_GRAVITY_RATIO.FloatValue * float(gClientData[client].Level)) : 0.0));
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
public Action JumpBoostOnClientJump(Event hEvent, char[] sName, bool dontBroadcast) 
{
	// Gets all required event info
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// Creates a single use next frame hook
	_call.JumpBoostOnClientJumpPost(client);
	
	// Allow event
	return Plugin_Continue;
}

/**
 * @brief Client has been jumped. *(Post)
 *
 * @param userID            The user id.
 **/
public void JumpBoostOnClientJumpPost(int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Gets client velocity
		static float vVelocity[3];
		ToolsGetVelocity(client, vVelocity);
		
		// Only apply horizontal multiplier if it not a bhop
		if (GetVectorLength(vVelocity) < gCvarList.JUMPBOOST_MAX.FloatValue)
		{
			// Apply horizontal multipliers to jump vector
			vVelocity[0] *= gCvarList.JUMPBOOST_MULTIPLIER.FloatValue;
			vVelocity[1] *= gCvarList.JUMPBOOST_MULTIPLIER.FloatValue;
		}

		// Apply height multiplier to jump vector
		vVelocity[2] *= gCvarList.JUMPBOOST_MULTIPLIER.FloatValue;

		// Sets new velocity
		ToolsSetVelocity(client, vVelocity, true, false);
	}
}

/**
 * @brief Called when player want do the leap jump.
 *
 * @param client            The client index.
 **/
void JumpBoostOnClientLeapJump(int client)
{
	// Validate access
	if (!ModesIsLeapJump(gServerData.RoundMode))
	{
		return;
	}
	
	// If not on the ground, then stop
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		return;
	}

   /*_________________________________________________________________________________________________________________________________________*/
   
	// Validate type of leap jump
	switch (ClassGetLeapJump(gClientData[client].Class))
	{
		// If leap disabled, then stop
		case 0 :
		{
			return;
		}
		// If leap just for single player
		case 2 :
		{
			if ((gClientData[client].Zombie ? fnGetZombies() : fnGetHumans()) > 1) 
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
	if (flCurrentTime - flDelay[client] < ClassGetLeapCountdown(gClientData[client].Class))
	{
		return;
	}
	
	// Update the leap jump delay
	flDelay[client] = flCurrentTime;
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Initialize some floats
	static float vAngle[3]; static float vPosition[3]; static float vVelocity[3];
	
	// Gets client location and view direction
	ToolsGetAbsOrigin(client, vPosition);
	GetClientEyeAngles(client, vAngle);
	
	// Store zero angle
	float flAngleZero = vAngle[0];    
	
	// Gets location angles
	vAngle[0] = -30.0;
	GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	// Scale vector for the boost
	ScaleVector(vVelocity, ClassGetLeapForce(gClientData[client].Class));
	
	// Restore eye angle
	vAngle[0] = flAngleZero;
	
	// Push the player
	TeleportEntity(client, vPosition, vAngle, vVelocity);
	
	// Forward event to modules
	SoundsOnClientJump(client);
	VEffectsOnClientJump(client);
}
