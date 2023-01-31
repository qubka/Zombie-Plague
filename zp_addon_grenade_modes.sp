/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Addon: Grenade Modes",
	author          = "qubka (Nikita Ushakov), Nyuu",
	description     = "Adds 6 new modes for all the grenades",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the addon.
 **/
#define GRENADE_DAMAGE                 /// Uncoment to block activatation from the other damage
#define GRENADE_SELF_COLOR             {125, 0, 125, 255} // The color of the self effects
#define GRENADE_TEAMMATE_COLOR         {0, 125, 0, 255}   // The color of the teammate effects
#define GRENADE_ENEMY_COLOR            {125, 0, 0, 255}   // The color of the enemy effects
#define GRENADE_PROXIMITY_POWERUP_TIME 2.0                // The proximity powerup time
#define GRENADE_PROXIMITY_RADIUS       100.0              // The radius of detection
#define GRENADE_SENSOR_ACTIVATE        100.0              // The speed of the enemy to activate
#define GRENADE_TRIPWIRE_POWERUP_TIME  2.0                // The tripwire powerup time
#define GRENADE_TRIPWIRE_DISTANCE      8192.0             // The tripwire distance
#define GRENADE_SATCHEL_POWERUP_TIME   1.5                // The satchel powerup time
#define GRENADE_SATCHEL_RADIUS         25.0               // The satchel effect radius
#define GRENADE_HOMING_RADIUS          500.0              // The radius of homing  
#define GRENADE_HOMING_SPEED           500.0              // The speed of homing
#define GRENADE_HOMING_ROTATION        0.5                // The speed of rotation
#define GRENADE_HOMING_AVOID           100.0              // The range of avoid homing  
/**
 * @endsection
 **/
 
/**
 * @section Grenade modes.
 **/ 
enum
{
	GRENADE_MODE_NORMAL,
	GRENADE_MODE_IMPACT,
	GRENADE_MODE_PROXIMITY,
	GRENADE_MODE_TRIPWIRE,
	GRENADE_MODE_SATCHEL,
	GRENADE_MODE_HOMING,
	GRENADE_MODE_SENSOR,
	
	GRENADE_MODE_MAXIMUM
};
/**
 * @endsection
 **/
 
/**
 * @section Proximity states. (Sensor)
 **/ 
enum
{
	PROXIMITY_STATE_WAIT_IDLE,
	PROXIMITY_STATE_POWERUP,
	PROXIMITY_STATE_DETECT
};
/**
 * @endsection
 **/
 
/**
 * @section Tripwire states.
 **/ 
enum
{
	TRIPWIRE_STATE_POWERUP,
	TRIPWIRE_STATE_DETECT
};
/**
 * @endsection
 **/
 
/**
 * @section Satchel states.
 **/ 
enum
{
	SATCHEL_STATE_POWERUP,
	SATCHEL_STATE_ENABLED
};
/**
 * @endsection
 **/
 
// Grenade mode names
static const char sModes[GRENADE_MODE_MAXIMUM][SMALL_LINE_LENGTH] =
{
	"normal",         // NORMAL
	"impact",         // IMPACT
	"proximity",      // PROXIMITY
	"trip wire",      // TRIPWIRE
	"satchel charge", // SATCHEL
	"homing",         // HOMING
	"motion sensor"   // SENSOR
};

// Decal index
int gBeacon; int gBeam; int gHalo; int gGlow;
#pragma unused gBeacon, gBeam, gHalo, gGlow

// Player index
int iGrenadeMode[MAXPLAYERS+1]; ArrayList hGrenadeList[MAXPLAYERS+1] = { null, ... };
#pragma unused iGrenadeMode, hGrenadeList

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		// Load translations phrases used by plugin
		LoadTranslations("grenade_modes.phrases");
	}
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
	gBeacon = PrecacheModel("materials/sprites/physbeam.vmt", true);
	gBeam   = PrecacheModel("materials/sprites/purplelaser1.vmt", true);
	gHalo   = PrecacheModel("materials/sprites/purpleglow1.vmt", true);
	gGlow   = PrecacheModel("materials/sprites/blueflare1.vmt", true);
	
	// Sounds
	PrecacheSound("buttons/blip1.wav", true);
	PrecacheSound("buttons/blip2.wav", true);
	PrecacheSound("buttons/bell1.wav", true);
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	// Activate list
	GrenadeActivate(client);
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	// Activate list
	GrenadeActivate(client);
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	// Activate list
	GrenadeActivate(client);
}

//**********************************************
//* Grenade (common) function.                 *
//**********************************************

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param client            The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
	// Button reload press
	if (iButtons & IN_RELOAD && !(iLastButtons & IN_RELOAD))
	{
		// Validate custom grenade
		ItemDef iItem = ZP_GetWeaponDefIndex(weaponID);
		if (IsProjectile(iItem))
		{
			// Cache the grenade mode and limit
			int iMode = iGrenadeMode[client];
			
			// Go to the next grenade mode
			iMode = (iMode + 1) % GRENADE_MODE_MAXIMUM;

			// Sets grenade mode
			iGrenadeMode[client] = iMode;
			
			// Display the grenade mode
			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "grenade mode", sModes[iMode]);
		}
	}
	// Button secondary attack press
	else if (iButtons & IN_ATTACK2 && !(iLastButtons & IN_ATTACK2))
	{
		// Validate client
		if (IsPlayerAlive(client))
		{
			// Activate list
			GrenadeActivate(client);
		}
	}

	// Allow button
	return Plugin_Continue;
}

/**
 * @brief Called after a custom grenade is created.
 *
 * @param client            The client index.
 * @param grenade           The grenade index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnGrenadeCreated(int client, int grenade, int weaponID)
{
	DataPack hPack = new DataPack();
	/// Initialize pack
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteCell(EntIndexToEntRef(grenade));
	hPack.WriteCell(weaponID);
	
	// Execute forward on the next frame
	RequestFrame(ZP_OnGrenadeCreatedPost, hPack);
}

/**
 * @brief Called after a custom grenade is created.
 *
 * @param hPack             The pack handle.
 **/
public void ZP_OnGrenadeCreatedPost(DataPack hPack)
{
	/// Extract data from pack and delete it
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	int grenade = EntRefToEntIndex(hPack.ReadCell());
	int weaponID = hPack.ReadCell();
	delete hPack;
	
	// Validate ouputs
	if (!client || grenade == -1)
	{
		return;
	}
	
	// If grenade is disabled, then stop
	if (GetEntProp(grenade, Prop_Data, "m_nNextThinkTick") == -1)
	{
		return;
	}
	
	// Validate custom grenade
	ItemDef iItem = ZP_GetWeaponDefIndex(weaponID);
	if (IsProjectile(iItem))
	{
		// Gets grenade owner
		int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");

		// Validate owner
		if (owner != -1)
		{
			// Switch on the player grenade mode
			switch (iGrenadeMode[owner])
			{
				case GRENADE_MODE_NORMAL :
				{
					// Nothing to do
				}
				
				case GRENADE_MODE_IMPACT :
				{
					// Sets grenade as infinite
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);
					
					// Hook the grenade touch function
					SDKHook(grenade, SDKHook_TouchPost, GrenadeImpactTouchPost);
				}
				
				case GRENADE_MODE_TRIPWIRE :
				{
					// Sets grenade as infinite
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);
					
					// Resets variables
					SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", false);
					SetEntProp(grenade, Prop_Data, "m_iMaxHealth", TRIPWIRE_STATE_POWERUP);
					SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", GRENADE_TRIPWIRE_POWERUP_TIME);
					
					// Hook the grenade touch function
					SDKHook(grenade, SDKHook_Touch, GrenadeTripwireTouch);
				}
				
				case GRENADE_MODE_PROXIMITY, GRENADE_MODE_SENSOR :
				{
					// Sets grenade as infinite
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);
					
					// Resets variables
					SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", (iGrenadeMode[owner] == GRENADE_MODE_SENSOR));
					SetEntProp(grenade, Prop_Data, "m_iMaxHealth", PROXIMITY_STATE_WAIT_IDLE);
					SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", 0.0);
					
					// Sets grenade think function
					CreateTimer(0.1, GrenadeProximityThinkHook, EntIndexToEntRef(grenade), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					
					// Hook the grenade touch function
					SDKHook(grenade, SDKHook_Touch, GrenadeProximityTouch);
				}
				
				case GRENADE_MODE_SATCHEL :
				{
					// Sets grenade as infinite
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);

					// Resets variables
					SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", false);
					SetEntProp(grenade, Prop_Data, "m_iMaxHealth", SATCHEL_STATE_POWERUP);
					SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", GRENADE_SATCHEL_POWERUP_TIME);

					// Hook the grenade touch function
					SDKHook(grenade, SDKHook_Touch, GrenadeSatchelTouch);
					
					// Push grenade to the list
					GrenadePush(client, grenade);
					
					// Show message
					SetGlobalTransTarget(client);
					PrintHintText(client, "%t", "satchel info");   
				}
				
				case GRENADE_MODE_HOMING :
				{
					// Resets variables
					SetEntProp(grenade, Prop_Data, "m_iMaxHealth", GetEntProp(grenade, Prop_Data, "m_iTeamNum"));
					SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", 0.0);
					
					// Sets grenade think function
					CreateTimer(0.1, GrenadeHomingThinkHook, EntIndexToEntRef(grenade), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
}

/**
 * @brief Grenade damage hook.
 * 
 * @param grenade           The entity index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action GrenadeDamageHook(int grenade, int &attacker, int &inflictor, float &flDamage, int &damageBits)
{
#if defined GRENADE_DAMAGE
	// Validate attacker
	if (IsPlayerExist(attacker))
	{
		// Gets grenade team
		int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
		
		// Check if the owner is still connected and in the same team than the attacker
		if (ZP_GetPlayerTeam(attacker) == iTeam)
		{
			// Block damage
			return Plugin_Handled;
		}
	}
	
	// Allow damage
	return Plugin_Continue;
#else
	// Block damage
	return Plugin_Handled;
#endif
}

//**********************************************
//* Grenade (impact) function.                 *
//**********************************************

/**
 * @brief Called right after the grenade touch other entity.
 * 
 * @param grenade           The grenade index.
 * @param target            The entity index of the entity being touched.
 **/
public void GrenadeImpactTouchPost(int grenade, int target)
{
	// Gets grenade owner
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	// Check if it's not the owner
	if (owner == target)
	{
		return;
	}
	
	// Detonate the grenade
	GrenadeDetonate(grenade);
}

/**
 * @brief Timer for detonate grenade.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action GrenadeDetonateHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int grenade = EntRefToEntIndex(refID);
	
	// Validate grenade
	if (grenade != -1)
	{
		// Detonate the grenade
		GrenadeDetonate(grenade);
	}
	
	// Stop timer
	return Plugin_Stop;
}

//**********************************************
//* Grenade (proximity/sensor) function.       *
//**********************************************

/**
 * @brief Called right before the grenade touch other entity.
 * 
 * @param grenade           The grenade index.
 * @param target            The entity index of the entity being touched.
 **/
public Action GrenadeProximityTouch(int grenade, int target)
{
	// Block touch
	return Plugin_Handled;
}

/**
 * @brief Move to another state.
 * 
 * @param grenade           The grenade index.
 * @param iState            The state index.
 * @param flCounter         The counter timer.
 **/
Action GrenadeProximityThinkWaitIdle(int grenade, int &iState, float &flCounter)
{
	// Gets grenade velocity
	static float vVelocity[3];
	GetEntPropVector(grenade, Prop_Data, "m_vecVelocity", vVelocity);
	
	// Check if the grenade is stationary
	if (GetVectorLength(vVelocity) <= 0.0)
	{
		// Sets grenade as breakable
		GrenadeSetBreakable(grenade);

		// Sets grenade next state
		iState    = PROXIMITY_STATE_POWERUP;
		flCounter = GRENADE_PROXIMITY_POWERUP_TIME;
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Emit proximity sounds.
 * 
 * @param grenade           The grenade index.
 * @param iState            The state index.
 * @param flCounter         The counter timer.
 **/
Action GrenadeProximityThinkPowerUp(int grenade, int &iState, float &flCounter)
{
	// Convert seconds to milis
	int iCounter = RoundToNearest(flCounter * 10.0);
	
	// Check if the grenade is ready
	if (flCounter <= 0.0)
	{
		// Play a sound
		EmitSoundToAll("buttons/blip2.wav", grenade, _, SNDLEVEL_LIBRARY);
		
		// Sets grenade next state
		iState    = PROXIMITY_STATE_DETECT;
		flCounter = 0.0;
	}
	else if (!(iCounter % 2))
	{
		// Determine the pitch
		int iPitch = 200 - iCounter * 4;
		
		// Validate max
		if (iPitch <= 100)
		{
			iPitch = 100;
		}
		
		// Play a sound
		EmitSoundToAll("buttons/blip1.wav", grenade, _, SNDLEVEL_LIBRARY, _, _, iPitch);
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Detect any victims.
 * 
 * @param grenade           The grenade index.
 * @param iState            The state index.
 * @param flCounter         The counter timer.
 **/
Action GrenadeProximityThinkDetect(int grenade, int &iState, float &flCounter)
{
	// Gets grenade owner
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	// Validate owner
	if (owner != -1)
	{
		// Initialize vectors
		static float vPosition[3]; static float vVelocity[3];

		// Gets grenade origin
		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		// Initialize the context
		bool bDetonate; int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
		bool bSensor = view_as<bool>(GetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget"));
		
		// Find any players in the radius
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, GRENADE_PROXIMITY_RADIUS)) != -1)
		{
			// Skip same team
			if (ZP_GetPlayerTeam(i) == iTeam)
			{
				continue;
			}
			
			// Validate sensor mode
			if (bSensor)
			{
				// Gets victim origin
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vVelocity);
				
				// Validate speed
				if (GetVectorLength(vVelocity) < GRENADE_SENSOR_ACTIVATE)
				{
					continue;
				}
			}

			// Allow to detonate
			bDetonate = true;
		}
		
		// Check if the grenade must detonate
		if (bDetonate)
		{
			CreateTimer(0.1, GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
		
		// Warn the players
		if (flCounter <= 0.0)
		{
			// Initialize some variables
			static int iPlayers[MAXPLAYERS+1]; static int vColor[4];
			
			// Gets all the players in range
			int iMaxPlayers = GetClientsInRange(vPosition, RangeType_Audibility, iPlayers, MaxClients);
			
			// Send the beam effect to all the close players
			for (i = 0 ; i < iMaxPlayers ; i++)
			{
				// Gets client index
				int client = iPlayers[i];
   
				// Determine the color of the beam
				if (ZP_GetPlayerTeam(client) == iTeam)
				{
					vColor = (client == owner) ? GRENADE_SELF_COLOR : GRENADE_TEAMMATE_COLOR;
				}
				else
				{
					vColor = GRENADE_ENEMY_COLOR;
				}
				
				// Create the beacon effect
				TE_SetupBeamRingPoint(vPosition, bSensor ? GRENADE_PROXIMITY_RADIUS : 0.0, GRENADE_PROXIMITY_RADIUS * 2.0, gBeacon, gHalo, 0, 0, 0.5, 4.0, 0.0, vColor, 30, 0);
				TE_SendToClient(client);
			}
			
			// 1.0 sec
			flCounter = 1.0; 
		}
	}
	else
	{
		// Detonate the grenade
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Timer for proximity think.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action GrenadeProximityThinkHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int grenade = EntRefToEntIndex(refID);

	// By default, exit the timer
	Action hResult = Plugin_Stop;
	
	// Check if the grenade is still valid
	if (grenade != -1)
	{
		// Gets local variables
		int iState = GetEntProp(grenade, Prop_Data, "m_iMaxHealth");
		float flCounter = GetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle");

		// Decrement the grenade counter
		if (flCounter > 0.0)
		{
			flCounter -= 0.1;
		}
		
		// Execute the grenade think function
		switch (iState)
		{
			case PROXIMITY_STATE_WAIT_IDLE :
			{
				hResult = GrenadeProximityThinkWaitIdle(grenade, iState, flCounter);
			}
			case PROXIMITY_STATE_POWERUP :
			{
				hResult = GrenadeProximityThinkPowerUp(grenade, iState, flCounter);
			}
			case PROXIMITY_STATE_DETECT :
			{
				hResult = GrenadeProximityThinkDetect(grenade, iState, flCounter);
			}
		}
		
		// Update variables
		SetEntProp(grenade, Prop_Data, "m_iMaxHealth", iState);
		SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", flCounter);
	}
	
	// Return on success
	return hResult;
}

//**********************************************
//* Grenade (tripwire) function.               *
//**********************************************

/**
 * @brief Called right before the grenade touch other entity.
 * 
 * @param grenade           The grenade index.
 * @param target            The entity index of the entity being touched.
 **/
public Action GrenadeTripwireTouch(int grenade, int target)
{
	// Avoid double touch
	if (!GetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget"))
	{
		// Check if the grenade touches the world or static entity
		if (!target || ZP_IsBSPModel(target))
		{
			// Search a wall near the grenade
			GrenadeTripwireTrackWall(grenade);
		}
	}
	
	// Make grenade non-physical entity in order to prevent players and bots blocking
	SetEntProp(grenade, Prop_Data, "m_nSolidType", SOLID_NONE);
	SetEntProp(grenade, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
	
	// Block touch
	return Plugin_Handled;
}

/**
 * @brief Move to another state.
 * 
 * @param grenade           The grenade index.
 **/
void GrenadeTripwireTrackWall(int grenade)
{
	// Initialize some vectors
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];
	
	/// Search in order: +Z axis -Z axis +X axis -X axis +Y axis -Y axis
	static const int vLoop[6][2] = { {2, 1}, {2, -1}, {0, 1}, {0, -1}, {1, 1}, {1, -1} };
	
	// Gets grenade origin
	GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

	// Initialize some variables
	int victim; float flFraction; float flBestFraction = 1.0;
	
	// i = dimention order
	for (int i = 0; i < 6; i++)
	{
		// Calculate the end position
		vEndPosition[vLoop[i][0]] = vPosition[vLoop[i][0]] + (2.0 * float(vLoop[i][1]));
		
		// Create the end-point trace
		Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, PlayerFilter, grenade);

		// Validate collisions
		if (!TR_DidHit(hTrace))
		{
			// Initialize the hull box
			static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
			static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
			
			// Create the hull trace
			delete hTrace;
			hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, PlayerFilter, grenade);
			
			// Validate collisions
			if (TR_DidHit(hTrace))
			{
				// Gets victim index
				victim = TR_GetEntityIndex(hTrace);

				// Is hit world ?
				if (victim < 1 || ZP_IsBSPModel(victim))
				{
					UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, PlayerFilter, grenade);
				}
			}
		}
		
		// Validate collisions
		if (TR_DidHit(hTrace))
		{
			// Gets victim index
			victim = TR_GetEntityIndex(hTrace);

			// Is hit world ?
			if (victim < 1 || ZP_IsBSPModel(victim))
			{
				// Find smallest collision
				flFraction = TR_GetFraction(hTrace);
				if (flBestFraction > flFraction)
				{
					// Store the best suiltable value
					flBestFraction = flFraction;
					
					// Returns the collision position/normal of a trace result
					TR_GetEndPosition(vEndPosition, hTrace);
					TR_GetPlaneNormal(hTrace, vNormal);
				}
			}
		}
		
		// Close trace 
		delete hTrace;
	}
	
	// Validate collision
	if (flBestFraction < 1.0)
	{
		// Teleport the entity
		TeleportEntity(grenade, vEndPosition, NULL_VECTOR, NULL_VECTOR);

		// Calculate and store endpoint
		ScaleVector(vNormal, GRENADE_TRIPWIRE_DISTANCE);
		AddVectors(vNormal, vPosition, vEndPosition);

		// Create the end-point trace
		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, PlayerFilter, grenade);

		// Returns the collision position of a trace result
		TR_GetEndPosition(vEndPosition); 
		
		// Store end position
		SetEntPropVector(grenade, Prop_Data, "m_vecViewOffset", vEndPosition);
		
		// Sets grenade think function
		CreateTimer(0.1, GrenadeTripwireThinkHook, EntIndexToEntRef(grenade), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		// Block the grenade touch function
		SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", true);
		
		// Block the grenade
		SetEntityMoveType(grenade, MOVETYPE_NONE);
		
		// Sets grenade breakable
		GrenadeSetBreakable(grenade);
	}
	else
	{
		/// If we reach here, we have serious problems. This means that the grenade hit something like a func_breakable
		/// that disappeared before the scan was able to take place. Now, the grenade is floating in mid air. So we just
		/// explode it!!!
		
		// Detonate the grenade
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * @brief Emit tripwire sounds.
 * 
 * @param grenade           The grenade index.
 * @param iState            The state index.
 * @param flCounter         The counter timer.
 **/
Action GrenadeTripwireThinkPowerUp(int grenade, int &iState, float &flCounter)
{
	// Convert seconds to milis
	int iCounter = RoundToNearest(flCounter * 10.0);
	
	// Check if the grenade is ready
	if (flCounter <= 0.0)
	{
		// Play a sound
		EmitSoundToAll("buttons/blip2.wav", grenade, _, SNDLEVEL_LIBRARY);
		
		// Sets grenade next state
		iState    = TRIPWIRE_STATE_DETECT;
		flCounter = 0.0;
	}
	else if (!(iCounter % 2))
	{
		// Determine the pitch
		int iPitch = 200 - iCounter * 4;
		
		// Validate max
		if (iPitch <= 100)
		{
			iPitch = 100;
		}
		
		// Play a sound
		EmitSoundToAll("buttons/blip1.wav", grenade, _, SNDLEVEL_LIBRARY, _, _, iPitch);
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Detect any victims.
 * 
 * @param grenade           The grenade index.
 * @param iState            The state index.
 * @param flCounter         The counter timer.
 **/
Action GrenadeTripwireThinkDetect(int grenade, int &iState, float &flCounter)
{
	// Gets grenade owner
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	// Validate owner
	if (owner != -1)
	{
		// Initialize vectors
		static float vPosition[3]; static float vEndPosition[3];

		// Gets grenade origin
		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);
		GetEntPropVector(grenade, Prop_Data, "m_vecViewOffset", vEndPosition);
		
		// Initialize the context
		bool bDetonate; int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
		
		// Create the end-point trace
		TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, SelfFilter, grenade);

		// Validate collisions
		if (TR_DidHit())
		{
			// Returns the collision position of a trace result
			TR_GetEndPosition(vEndPosition);
			
			// Gets victim index
			int victim = TR_GetEntityIndex();
			
			// Validate victim
			if ((IsPlayerExist(victim)) && (ZP_GetPlayerTeam(victim) != iTeam))
			{
				// Allow detonation
				bDetonate = true;
			}
		}
		
		// Check if the grenade must detonate
		if (bDetonate)
		{
			CreateTimer(0.1, GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
		
		// Warn the players
		if (flCounter <= 0.0)
		{
			// Initialize some variables
			static int iPlayers[MAXPLAYERS+1]; static int vColor[4];
			
			// Gets all the players in range
			int iMaxPlayers = GetClientsInRange(vPosition, RangeType_Audibility, iPlayers, MaxClients);
			
			// Send the beam effect to all the close players
			for (int i = 0; i < iMaxPlayers; i++)
			{
				// Gets client index
				int client = iPlayers[i];
				
				// Determine the color of the beam
				if (ZP_GetPlayerTeam(client) == iTeam)
				{
					vColor = (client == owner) ? GRENADE_SELF_COLOR : GRENADE_TEAMMATE_COLOR;
				}
				else
				{
					vColor = GRENADE_ENEMY_COLOR;
				}
				
				// Create the beam effect
				TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, gHalo, 0, 0, 0.1, 8.0, 8.0, 0, 0.0, vColor, 30);
				TE_SendToClient(client);
			}
			
			// 0.1 sec
			flCounter = 0.1; 
		}
	}
	else
	{
		// Detonate the grenade
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Timer for tripwire think.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action GrenadeTripwireThinkHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int grenade = EntRefToEntIndex(refID);

	// By default, exit the timer
	Action hResult = Plugin_Stop;
	
	// Check if the grenade is still valid
	if (grenade != -1)
	{
		// Gets local variables
		int iState = GetEntProp(grenade, Prop_Data, "m_iMaxHealth");
		float flCounter = GetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle");

		// Decrement the grenade counter
		if (flCounter > 0.0)
		{
			flCounter -= 0.1;
		}
		
		// Execute the grenade think function
		switch (iState)
		{
			case TRIPWIRE_STATE_POWERUP :
			{
				hResult = GrenadeTripwireThinkPowerUp(grenade, iState, flCounter);
			}
			case TRIPWIRE_STATE_DETECT :
			{
				hResult = GrenadeTripwireThinkDetect(grenade, iState, flCounter);
			}
		}
		
		// Update variables
		SetEntProp(grenade, Prop_Data, "m_iMaxHealth", iState);
		SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", flCounter);
	}
	
	// Return on success
	return hResult;
}

//**********************************************
//* Grenade (satchel) function.                *
//**********************************************

/**
 * @brief Called right before the grenade touch other entity.
 * 
 * @param grenade           The grenade index.
 * @param target            The entity index of the entity being touched.
 **/
public Action GrenadeSatchelTouch(int grenade, int target)
{
	// Avoid double touch
	if (!GetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget"))
	{
		// Check if the grenade touches the world or static entity
		if (!target || ZP_IsBSPModel(target))
		{
			// Search a wall near the grenade
			GrenadeSatchelTrackWall(grenade);
		}
	}
	
	// Block touch
	return Plugin_Handled;
}

/**
 * @brief Move to another state.
 * 
 * @param grenade           The grenade index.
 **/
void GrenadeSatchelTrackWall(int grenade)
{
	// Initialize some vectors
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];
	
	/// Search in order: +Z axis -Z axis +X axis -X axis +Y axis -Y axis
	static const int vLoop[6][2] = { {2, 1}, {2, -1}, {0, 1}, {0, -1}, {1, 1}, {1, -1} };
	
	// Gets grenade origin
	GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

	// Initialize some variables
	int victim; float flFraction; float flBestFraction = 1.0;
	
	// i = dimention order
	for (int i = 0; i < 6; i++)
	{
		// Calculate the end position
		vEndPosition[vLoop[i][0]] = vPosition[vLoop[i][0]] + (2.0 * float(vLoop[i][1]));
		
		// Create the end-point trace
		Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, PlayerFilter, grenade);

		// Validate collisions
		if (!TR_DidHit(hTrace))
		{
			// Initialize the hull box
			static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
			static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
			
			// Create the hull trace
			delete hTrace;
			hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, PlayerFilter, grenade);
			
			// Validate collisions
			if (TR_DidHit(hTrace))
			{
				// Gets victim index
				victim = TR_GetEntityIndex(hTrace);

				// Is hit world ?
				if (victim < 1 || ZP_IsBSPModel(victim))
				{
					UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, PlayerFilter, grenade);
				}
			}
		}
		
		// Validate collisions
		if (TR_DidHit(hTrace))
		{
			// Gets victim index
			victim = TR_GetEntityIndex(hTrace);

			// Is hit world ?
			if (victim < 1 || ZP_IsBSPModel(victim))
			{
				// Find smallest collision
				flFraction = TR_GetFraction(hTrace);
				if (flBestFraction > flFraction)
				{
					// Store the best suiltable value
					flBestFraction = flFraction;
					
					// Returns the collision position/normal of a trace result
					TR_GetEndPosition(vEndPosition, hTrace);
					TR_GetPlaneNormal(hTrace, vNormal);
				}
			}
		}
		
		// Close trace 
		delete hTrace;
	}
	
	// Validate collision
	if (flBestFraction < 1.0)
	{
		// Teleport the entity
		TeleportEntity(grenade, vEndPosition, NULL_VECTOR, NULL_VECTOR);

		// Sets grenade think function
		CreateTimer(0.1, GrenadeSatchelThinkHook, EntIndexToEntRef(grenade), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		// Block the grenade touch function
		SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", true);
		
		// Block the grenade
		SetEntityMoveType(grenade, MOVETYPE_NONE);
		
		// Sets grenade breakable
		GrenadeSetBreakable(grenade);
	}
	else
	{
		/// If we reach here, we have serious problems. This means that the grenade hit something like a func_breakable
		/// that disappeared before the scan was able to take place. Now, the grenade is floating in mid air. So we just
		/// explode it!!!
		
		// Detonate the grenade
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * @brief Emit satchel sounds.
 * 
 * @param grenade           The grenade index.
 * @param iState            The state index.
 * @param flCounter         The counter timer.
 **/
Action GrenadeSatchelThinkPowerUp(int grenade, int &iState, float &flCounter)
{
	// Convert seconds to milis
	int iCounter = RoundToNearest(flCounter * 10.0);
	
	// Check if the grenade is ready
	if (flCounter <= 0.0)
	{
		// Play a sound
		EmitSoundToAll("buttons/blip2.wav", grenade, _, SNDLEVEL_LIBRARY);
		
		// Sets grenade next state
		iState    = SATCHEL_STATE_ENABLED;
		flCounter = 0.0;
	}
	else if (!(iCounter % 2))
	{
		// Determine the pitch
		int iPitch = 200 - iCounter * 4;
		
		// Validate max
		if (iPitch <= 100)
		{
			iPitch = 100;
		}
		
		// Play a sound
		EmitSoundToAll("buttons/blip1.wav", grenade, _, SNDLEVEL_LIBRARY, _, _, iPitch);
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Enabled satchel.
 * 
 * @param grenade           The grenade index.
 * @param iState            The state index.
 * @param flCounter         The counter timer.
 **/
Action GrenadeSatchelThinkEnabled(int grenade, int &iState, float &flCounter)
{
	// Gets grenade owner
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	// Validate owner
	if (owner != -1)
	{
		// Gets grenade origin
		static float vPosition[3];
		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

		// Warn the players
		if (flCounter <= 0.0)
		{
			// Initialize some variables
			static int iPlayers[MAXPLAYERS+1]; static int vColor[4]; int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
			
			// Gets all the players in range
			int iMaxPlayers = GetClientsInRange(vPosition, RangeType_Audibility, iPlayers, MaxClients);
			
			// Send the beam effect to all the close players
			for (int i = 0; i < iMaxPlayers; i++)
			{
				// Gets client index
				int client = iPlayers[i];
				
				// Determine the color of the beam
				if (ZP_GetPlayerTeam(client) == iTeam)
				{
					vColor = (client == owner) ? GRENADE_SELF_COLOR : GRENADE_TEAMMATE_COLOR;
				}
				else
				{
					vColor = GRENADE_ENEMY_COLOR;
				}
				
				// Create the beacon effect
				TE_SetupBeamRingPoint(vPosition, GRENADE_SATCHEL_RADIUS, GRENADE_SATCHEL_RADIUS * 2.0, gBeacon, gHalo, 0, 0, 0.1, 4.0, 0.0, vColor, 30, 0);
				TE_SendToClient(client);
			}
			
			// 0.1 sec
			flCounter = 0.1; 
		}
	}
	else
	{
		// Detonate the grenade
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	
	// Return on success
	return Plugin_Continue;
}

/**
 * @brief Timer for satchel think.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action GrenadeSatchelThinkHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int grenade = EntRefToEntIndex(refID);

	// By default, exit the timer
	Action hResult = Plugin_Stop;
	
	// Check if the grenade is still valid
	if (grenade != -1)
	{
		// Gets local variables
		int iState = GetEntProp(grenade, Prop_Data, "m_iMaxHealth");
		float flCounter = GetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle");

		// Decrement the grenade counter
		if (flCounter > 0.0)
		{
			flCounter -= 0.1;
		}
		
		// Execute the grenade think function
		switch (iState)
		{
			case SATCHEL_STATE_POWERUP :
			{
				hResult = GrenadeSatchelThinkPowerUp(grenade, iState, flCounter);
			}
			case SATCHEL_STATE_ENABLED :
			{
				hResult = GrenadeSatchelThinkEnabled(grenade, iState, flCounter);
			}
		}
		
		// Update variables
		SetEntProp(grenade, Prop_Data, "m_iMaxHealth", iState);
		SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", flCounter);
	}
	
	// Return on success
	return hResult;
}

//**********************************************
//* Grenade (homing) function.                 *
//**********************************************

/**
 * @brief Main timer for homing think.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action GrenadeHomingThinkHook(Handle hTimer, int refID)
{ 
	// Gets entity index from reference key
	int grenade = EntRefToEntIndex(refID);

	// Validate grenade
	if (grenade != -1)
	{
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3]; static float vEnemy[3]; static float vVelocity[3]; static float vSpeed[3];

		// Gets grenade origin
		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);
			
		// Find target
		int target = GetEntPropEnt(grenade, Prop_Data, "m_pParent");
		if (target != 0 || !UTIL_CanSeeEachOther(grenade, target, vPosition, SelfFilter) || ZP_GetPlayerTeam(target) != GetEntProp(grenade, Prop_Data, "m_iMaxHealth")) /// If team was changed, reset target
		{
			// Gets grenade team
			int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
	
			// If we have an enemy get his minimum distance to check against
			float flOldDistance = MAX_FLOAT; float flNewDistance;

			// Find any players in the radius
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, GRENADE_PROXIMITY_RADIUS)) != -1)
			{
				// Skip same team
				int iPending = ZP_GetPlayerTeam(i);
				if (iPending == iTeam)
				{
					continue;
				}
				
				// Gets target origin
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
			
				// Gets target distance
				flNewDistance = GetVectorDistance(vPosition, vEnemy);
				
				// It is closer, then store index
				if (flNewDistance < flOldDistance)
				{
					flOldDistance = flNewDistance;
					SetEntPropEnt(grenade, Prop_Data, "m_pParent", i);
					SetEntProp(grenade, Prop_Data, "m_iMaxHealth", iPending);
					SetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle", flOldDistance);
				}
			}
		}
		else
		{
			// Play a sound
			//EmitSoundToAll("buttons/bell1.wav", grenade, _, SNDLEVEL_LIBRARY);
	
			// Gets grenade velocity
			GetEntPropVector(grenade, Prop_Data, "m_vecVelocity", vVelocity);
	
			// Gets target origin
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vEnemy);

			// Gets vector from the given starting and ending points
			MakeVectorFromPoints(vPosition, vEnemy, vSpeed);

			// Ignore turning arc if the missile is close to the enemy to avoid it circling them
			if (GetEntPropFloat(grenade, Prop_Data, "m_flUseLookAtAngle") > GRENADE_HOMING_AVOID)
			{
				// Normalize the vector (equal magnitude at varying distances)
				NormalizeVector(vSpeed, vSpeed);
				NormalizeVector(vVelocity, vVelocity);
				
				// Calculate and store speed
				ScaleVector(vSpeed, GRENADE_HOMING_ROTATION); 
				AddVectors(vSpeed, vVelocity, vSpeed);
			}
		
			// Normalize the vector (equal magnitude at varying distances)
			NormalizeVector(vSpeed, vSpeed);
			
			// Apply the magnitude by scaling the vector
			ScaleVector(vSpeed, GRENADE_HOMING_SPEED);

			// Gets angles of the speed vector
			GetVectorAngles(vSpeed, vAngle);

			// Push the entity
			TeleportEntity(grenade, NULL_VECTOR, vAngle, vSpeed);
		}
	}
	else
	{
		// Destroy timer
		return Plugin_Stop;
	}
	
	// Allow timer
	return Plugin_Continue;
}

//**********************************************
//* Grenade (useful) stocks.                   *
//**********************************************

/**
 * @brief Sets the breakable ability for a grenade.
 *
 * @param grenade           The grenade index.
 **/
stock void GrenadeSetBreakable(int grenade)
{
	// Sets grenade as breakable
	SetEntProp(grenade, Prop_Data, "m_takedamage", DAMAGE_YES);
	SetEntProp(grenade, Prop_Data, "m_iHealth", 1);
	
	// Hook the grenade takedamage function
	SDKHook(grenade, SDKHook_OnTakeDamage, GrenadeDamageHook);
}

/**
 * @brief Force the grenade to a detonation.
 *
 * @param grenade           The grenade index.
 **/
stock void GrenadeDetonate(int grenade)
{
	// Gets grenade classname
	static char sClassname[SMALL_LINE_LENGTH];
	GetEdictClassname(grenade, sClassname, sizeof(sClassname));

	// Check if the grenade is a smoke or a tactical
	if (!strncmp(sClassname, "smoke", 5, false) || !strncmp(sClassname, "tag", 3, false))
	{
		// Stop the grenade velocity
		static float vEmpty[3];
		TeleportEntity(grenade, NULL_VECTOR, NULL_VECTOR, vEmpty);
		
		// Explode in the next tick
		SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", 1);
	}
	else
	{
		// Sets grenade as breakable
		GrenadeSetBreakable(grenade);
		
		// Inflict some damage
		SDKHooks_TakeDamage(grenade, grenade, grenade, 1.0);
	}
}

/**
 * @brief Force the grenade list to an activation.
 *
 * @param client            The client index.
 **/
stock void GrenadeActivate(int client)
{
	// Validate array
	if (hGrenadeList[client] != null)
	{
		int i; int grenade; /// Pop all grenades in the list
		while ((i = hGrenadeList[client].Length - 1) != -1)
		{
			// Validate grenade
			grenade = EntRefToEntIndex(hGrenadeList[client].Get(i));
			if (grenade != -1)
			{
				// Detonate the grenade
				CreateTimer(GetRandomFloat(0.3, 0.5), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
			}
			
			// Remove index from array
			hGrenadeList[client].Erase(i);
		}
		
		// Delete array
		delete hGrenadeList[client];
	}
}

/**
 * @brief Push the grenade to a list.
 *
 * @param client            The client index.
 * @param grenade           The grenade index.
 **/
stock void GrenadePush(int client, int grenade)
{
	// If array hasn't been created, then create
	if (hGrenadeList[client] == null)
	{
		// Initialize a default list array
		hGrenadeList[client] = new ArrayList();
	}
	
	// Push ref into array
	hGrenadeList[client].Push(EntIndexToEntRef(grenade));
}

/**
 * @brief Trace filter.
 *  
 * @param entity            The entity index.
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 *
 * @return                  True or false.
 **/
public bool SelfFilter(int entity, int contentsMask, int filter)
{
	return (entity != filter);
}

/**
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 * @return                  True or false.
 **/
public bool PlayerFilter(int entity, int contentsMask, int filter)
{
	// Validate player
	if (IsPlayerExist(entity)) 
	{
		return false;
	}

	return (entity != filter);
}
