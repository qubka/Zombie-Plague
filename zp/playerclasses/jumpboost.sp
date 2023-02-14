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
void JumpBoostOnInit()
{
	if (gServerData.MapLoaded)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsPlayerExist(i, false))
			{
				JumpBoostOnClientInit(i);
			}
		}
	} 
	
	bool bJumpBoost = gCvarList.JUMPBOOST.BoolValue;
	if (!bJumpBoost)
	{
		UnhookEvent2("player_jump", JumpBoostOnClientJump, EventHookMode_Post);
		return;
	}
	
	HookEvent("player_jump", JumpBoostOnClientJump, EventHookMode_Post);
}

/**
 * @brief Hook jumpboost cvar changes.
 **/
void JumpBoostOnCvarInit()
{
	gCvarList.JUMPBOOST            = FindConVar("zp_jumpboost");
	gCvarList.JUMPBOOST_MULTIPLIER = FindConVar("zp_jumpboost_multiplier");
	gCvarList.JUMPBOOST_MAX        = FindConVar("zp_jumpboost_max"); 

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
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	JumpBoostOnInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index.
 **/
void JumpBoostOnClientInit(int client)
{
	bool bJumpBoost = gCvarList.JUMPBOOST.BoolValue;
	if (!bJumpBoost)
	{
		SDKUnhook(client, SDKHook_GroundEntChangedPost, JumpBoostOnClientEntChanged);
		return;
	}
	
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
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		return;
	}
	
	if (GetEntityMoveType(client) != MOVETYPE_LADDER)
	{
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
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	_call.JumpBoostOnClientJumpPost(client);
	
	return Plugin_Continue;
}

/**
 * @brief Client has been jumped. *(Next frame)
 *
 * @param userID            The user id.
 **/
public void JumpBoostOnClientJumpPost(int userID)
{
	int client = GetClientOfUserId(userID);

	if (client)
	{
		static float vVelocity[3];
		ToolsGetVelocity(client, vVelocity);
		
		if (GetVectorLength(vVelocity) < gCvarList.JUMPBOOST_MAX.FloatValue)
		{
			vVelocity[0] *= gCvarList.JUMPBOOST_MULTIPLIER.FloatValue;
			vVelocity[1] *= gCvarList.JUMPBOOST_MULTIPLIER.FloatValue;
		}
		
		vVelocity[2] *= gCvarList.JUMPBOOST_MULTIPLIER.FloatValue;

		int weapon = ToolsGetActiveWeapon(client);
		
		if (weapon != -1)
		{
			int iD = ToolsGetCustomID(weapon);
			if (iD != -1)
			{
				vVelocity[2] += WeaponsGetJump(iD);
			}
		}

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
	if (!ModesIsLeapJump(gServerData.RoundMode))
	{
		return;
	}
	
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		return;
	}

   /*_________________________________________________________________________________________________________________________________________*/
   
	switch (ClassGetLeapJump(gClientData[client].Class))
	{
		case 0 :
		{
			return;
		}
		case 2 :
		{
			if ((gClientData[client].Zombie ? fnGetZombies() : fnGetHumans()) > 1) 
			{
				return;
			}
		}
	}

	/*_________________________________________________________________________________________________________________________________________*/
	
	static float flDelay[MAXPLAYERS+1];
	
	float flCurrentTime = GetTickedTime();
	
	if (flCurrentTime - flDelay[client] < ClassGetLeapCountdown(gClientData[client].Class))
	{
		return;
	}
	
	flDelay[client] = flCurrentTime;
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	static float vAngle[3]; static float vPosition[3]; static float vVelocity[3];
	
	ToolsGetAbsOrigin(client, vPosition);
	GetClientEyeAngles(client, vAngle);
	
	float flAngleZero = vAngle[0];    
	
	vAngle[0] = -30.0;
	GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	ScaleVector(vVelocity, ClassGetLeapForce(gClientData[client].Class));
	
	vAngle[0] = flAngleZero;
	
	TeleportEntity(client, vPosition, vAngle, vVelocity);
	
	SoundsOnClientJump(client);
	VEffectsOnClientJump(client);
}
