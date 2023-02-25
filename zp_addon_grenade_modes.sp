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
#define GRENADE_SELF_COLOR     {125, 0, 125, 255} // The color of the self effects
#define GRENADE_TEAMMATE_COLOR {0, 125, 0, 255}   // The color of the teammate effects
#define GRENADE_ENEMY_COLOR    {125, 0, 0, 255}   // The color of the enemy effects
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
int gBeacon; int gBeam; int gHalo;

// Player index
int iGrenadeMode[MAXPLAYERS+1]; ArrayList hGrenadeList[MAXPLAYERS+1] = { null, ... };

// Cvars
ConVar hCvarGrenadeDamageMode;
ConVar hCvarGrenadeProximityPowerupTime;
ConVar hCvarGrenadeProximityRadius;
ConVar hCvarGrenadeSensorActivate;
ConVar hCvarGrenadeTripwirePowerupTime;
ConVar hCvarGrenadeTripwireDistance;
ConVar hCvarGrenadeSatchelPowerupTime;
ConVar hCvarGrenadeSatchelRadius;
ConVar hCvarGrenadeHomingRadius;
ConVar hCvarGrenadeHomingSpeed;
ConVar hCvarGrenadeHomingRotation;
ConVar hCvarGrenadeHomingAvoid;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarGrenadeDamageMode           = CreateConVar("zp_grenade_modes_damage_mode", "1", "Allow activation from the other damage", 0, true, 0.0, true, 1.0);
	hCvarGrenadeProximityPowerupTime = CreateConVar("zp_grenade_modes_proximity_powerup_time", "2.0", "Proximity powerup time", 0, true, 0.0);
	hCvarGrenadeProximityRadius      = CreateConVar("zp_grenade_modes_proximity_radius", "100.0", "Radius of detection", 0, true, 0.0);
	hCvarGrenadeSensorActivate       = CreateConVar("zp_grenade_modes_sensor_activate", "100.0", "Speed of the enemy to activate", 0, true, 0.0);
	hCvarGrenadeTripwirePowerupTime  = CreateConVar("zp_grenade_modes_tripwire_powerup_time", "2.0", "Tripwire powerup time", 0, true, 0.0);
	hCvarGrenadeTripwireDistance     = CreateConVar("zp_grenade_modes_tripwire_distance", "8192.0", "Tripwire distance", 0, true, 0.0);
	hCvarGrenadeSatchelPowerupTime   = CreateConVar("zp_grenade_modes_satchel_powerup_time", "1.5", "Satchel powerup time", 0, true, 0.0);
	hCvarGrenadeSatchelRadius        = CreateConVar("zp_grenade_modes_satchel_radius", "25.0", "Satchel effect radius", 0, true, 0.0);
	hCvarGrenadeHomingRadius         = CreateConVar("zp_grenade_modes_homing_radius", "500.0", "Radius of homing", 0, true, 0.0);
	hCvarGrenadeHomingSpeed          = CreateConVar("zp_grenade_modes_homing_speed", "500.0", "Speed of homing", 0, true, 0.0);
	hCvarGrenadeHomingRotation       = CreateConVar("zp_grenade_modes_homing_rotation", "0.5", "Speed of rotation", 0, true, 0.0);
	hCvarGrenadeHomingAvoid          = CreateConVar("zp_grenade_modes_homing_avoid", "100.0", "Range of avoid homing", 0, true, 0.0);

	AutoExecConfig(true, "zp_addon_grenade_modes", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		LoadTranslations("grenade_modes.phrases");
	}
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gBeacon = PrecacheModel("materials/sprites/physbeam.vmt", true);
	gBeam   = PrecacheModel("materials/sprites/purplelaser1.vmt", true);
	gHalo   = PrecacheModel("materials/sprites/purpleglow1.vmt", true);
	
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
	if (iButtons & IN_RELOAD && !(iLastButtons & IN_RELOAD))
	{
		ItemDef iItem = ZP_GetWeaponDefIndex(weaponID);
		if (IsProjectile(iItem))
		{
			int iMode = iGrenadeMode[client];
			
			iMode = (iMode + 1) % GRENADE_MODE_MAXIMUM;

			iGrenadeMode[client] = iMode;
			
			SetGlobalTransTarget(client);
			PrintHintText(client, "%t", "grenade mode", sModes[iMode]);
			
			EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
		}
	}
	else if (iButtons & IN_ATTACK2 && !(iLastButtons & IN_ATTACK2))
	{
		if (IsPlayerAlive(client))
		{
			GrenadeActivate(client);
		}
	}

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
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteCell(EntIndexToEntRef(grenade));
	hPack.WriteCell(weaponID);
	
	RequestFrame(ZP_OnGrenadeCreatedPost, hPack);
}

/**
 * @brief Called after a custom grenade is created.
 *
 * @param hPack             The pack handle.
 **/
public void ZP_OnGrenadeCreatedPost(DataPack hPack)
{
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	int grenade = EntRefToEntIndex(hPack.ReadCell());
	int weaponID = hPack.ReadCell();
	delete hPack;
	
	if (!client || grenade == -1)
	{
		return;
	}
	
	if (GetEntProp(grenade, Prop_Data, "m_nNextThinkTick") == -1)
	{
		return;
	}
	
	ItemDef iItem = ZP_GetWeaponDefIndex(weaponID);
	if (IsProjectile(iItem))
	{
		int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");

		if (owner != -1)
		{
			switch (iGrenadeMode[owner])
			{
				case GRENADE_MODE_NORMAL :
				{
				}
				
				case GRENADE_MODE_IMPACT :
				{
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);
					
					SDKHook(grenade, SDKHook_TouchPost, GrenadeImpactTouchPost);
				}
				
				case GRENADE_MODE_TRIPWIRE :
				{
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);
					
					SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", false);
					SetEntProp(grenade, Prop_Data, "m_iHammerID", TRIPWIRE_STATE_POWERUP);
					SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", hCvarGrenadeTripwirePowerupTime.FloatValue);
					
					SDKHook(grenade, SDKHook_Touch, GrenadeTripwireTouch);
				}
				
				case GRENADE_MODE_PROXIMITY, GRENADE_MODE_SENSOR :
				{
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);
					
					SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", (iGrenadeMode[owner] == GRENADE_MODE_SENSOR));
					SetEntProp(grenade, Prop_Data, "m_iHammerID", PROXIMITY_STATE_WAIT_IDLE);
					SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", 0.0);
					
					CreateTimer(0.1, GrenadeProximityThinkHook, EntIndexToEntRef(grenade), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					
					SDKHook(grenade, SDKHook_Touch, GrenadeProximityTouch);
				}
				
				case GRENADE_MODE_SATCHEL :
				{
					SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", -1);

					SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", false);
					SetEntProp(grenade, Prop_Data, "m_iHammerID", SATCHEL_STATE_POWERUP);
					SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", hCvarGrenadeSatchelPowerupTime.FloatValue);

					SDKHook(grenade, SDKHook_Touch, GrenadeSatchelTouch);
					
					GrenadePush(client, grenade);
					
					SetGlobalTransTarget(client);
					PrintHintText(client, "%t", "satchel info");  
					
					EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
				}
				
				case GRENADE_MODE_HOMING :
				{
					SetEntProp(grenade, Prop_Data, "m_iHammerID", GetEntProp(grenade, Prop_Data, "m_iTeamNum"));
					SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", 0.0);
					
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
	if (hCvarGrenadeDamageMode.BoolValue)
	{
		if (IsClientValid(attacker))
		{
			int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
			
			if (ZP_GetPlayerTeam(attacker) == iTeam)
			{
				return Plugin_Handled;
			}
		}
		
		return Plugin_Continue;
	}

	return Plugin_Handled;
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
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	if (owner == target)
	{
		return;
	}
	
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
	int grenade = EntRefToEntIndex(refID);
	
	if (grenade != -1)
	{
		GrenadeDetonate(grenade);
	}
	
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
	static float vVelocity[3];
	GetEntPropVector(grenade, Prop_Data, "m_vecVelocity", vVelocity);
	
	if (GetVectorLength(vVelocity) <= 0.0)
	{
		GrenadeSetBreakable(grenade);

		iState    = PROXIMITY_STATE_POWERUP;
		flCounter = hCvarGrenadeProximityPowerupTime.FloatValue;
	}
	
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
	int iCounter = RoundToNearest(flCounter * 10.0);
	
	if (flCounter <= 0.0)
	{
		EmitSoundToAll("buttons/blip2.wav", grenade, _);
		
		iState    = PROXIMITY_STATE_DETECT;
		flCounter = 0.0;
	}
	else if (!(iCounter % 2))
	{
		int iPitch = 200 - iCounter * 4;
		
		if (iPitch <= 100)
		{
			iPitch = 100;
		}
		
		EmitSoundToAll("buttons/blip1.wav", grenade, _, _, _, _, iPitch);
	}
	
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
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	if (owner != -1)
	{
		static float vPosition[3]; static float vVelocity[3];

		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);
		
		bool bDetonate; int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
		bool bSensor = view_as<bool>(GetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget"));
		
		float flRadius = hCvarGrenadeProximityRadius.FloatValue;
		float flSensorActivate = hCvarGrenadeSensorActivate.FloatValue;
		
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			if (ZP_GetPlayerTeam(i) == iTeam)
			{
				continue;
			}
			
			if (bSensor)
			{
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", vVelocity);
				
				if (GetVectorLength(vVelocity) < flSensorActivate)
				{
					continue;
				}
			}

			bDetonate = true;
		}
		
		if (bDetonate)
		{
			CreateTimer(0.1, GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
		
		if (flCounter <= 0.0)
		{
			static int iPlayers[MAXPLAYERS+1]; static int vColor[4];
			
			int iMaxPlayers = GetClientsInRange(vPosition, RangeType_Audibility, iPlayers, MaxClients);
			
			for (i = 0 ; i < iMaxPlayers ; i++)
			{
				int client = iPlayers[i];
   
				if (ZP_GetPlayerTeam(client) == iTeam)
				{
					vColor = (client == owner) ? GRENADE_SELF_COLOR : GRENADE_TEAMMATE_COLOR;
				}
				else
				{
					vColor = GRENADE_ENEMY_COLOR;
				}
				
				TE_SetupBeamRingPoint(vPosition, bSensor ? flRadius : 0.0, flRadius * 2.0, gBeacon, gHalo, 0, 0, 0.5, 4.0, 0.0, vColor, 30, 0);
				TE_SendToClient(client);
			}
			
			flCounter = 1.0; 
		}
	}
	else
	{
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	
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
	int grenade = EntRefToEntIndex(refID);

	Action hResult = Plugin_Stop;
	
	if (grenade != -1)
	{
		int iState = GetEntProp(grenade, Prop_Data, "m_iHammerID");
		float flCounter = GetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime");

		if (flCounter > 0.0)
		{
			flCounter -= 0.1;
		}
		
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
		
		SetEntProp(grenade, Prop_Data, "m_iHammerID", iState);
		SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", flCounter);
	}
	
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
	if (!GetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget"))
	{
		if (!target || ZP_IsBSPModel(target))
		{
			GrenadeTripwireTrackWall(grenade);
		}
	}
	
	SetEntProp(grenade, Prop_Data, "m_nSolidType", SOLID_NONE);
	SetEntProp(grenade, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
	
	return Plugin_Handled;
}

/**
 * @brief Move to another state.
 * 
 * @param grenade           The grenade index.
 **/
void GrenadeTripwireTrackWall(int grenade)
{
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];
	
	static const int vLoop[6][2] = { {2, 1}, {2, -1}, {0, 1}, {0, -1}, {1, 1}, {1, -1} };
	
	GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

	int victim; float flFraction; float flBestFraction = 1.0;
	
	for (int i = 0; i < 6; i++)
	{
		vEndPosition[vLoop[i][0]] = vPosition[vLoop[i][0]] + (2.0 * float(vLoop[i][1]));
		
		Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, PlayerFilter, grenade);

		if (!TR_DidHit(hTrace))
		{
			static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
			static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
			
			delete hTrace;
			hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, PlayerFilter, grenade);
			
			if (TR_DidHit(hTrace))
			{
				victim = TR_GetEntityIndex(hTrace);

				if (victim < 1 || ZP_IsBSPModel(victim))
				{
					UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, PlayerFilter, grenade);
				}
			}
		}
		
		if (TR_DidHit(hTrace))
		{
			victim = TR_GetEntityIndex(hTrace);

			if (victim < 1 || ZP_IsBSPModel(victim))
			{
				flFraction = TR_GetFraction(hTrace);
				if (flBestFraction > flFraction)
				{
					flBestFraction = flFraction;
					
					TR_GetEndPosition(vEndPosition, hTrace);
					TR_GetPlaneNormal(hTrace, vNormal);
				}
			}
		}
		
		delete hTrace;
	}
	
	if (flBestFraction < 1.0)
	{
		TeleportEntity(grenade, vEndPosition, NULL_VECTOR, NULL_VECTOR);

		ScaleVector(vNormal, hCvarGrenadeTripwireDistance.FloatValue);
		AddVectors(vNormal, vPosition, vEndPosition);

		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, PlayerFilter, grenade);

		TR_GetEndPosition(vEndPosition); 
		
		SetEntPropVector(grenade, Prop_Data, "m_vecViewOffset", vEndPosition);
		
		CreateTimer(0.1, GrenadeTripwireThinkHook, EntIndexToEntRef(grenade), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", true);
		
		SetEntityMoveType(grenade, MOVETYPE_NONE);
		
		GrenadeSetBreakable(grenade);
	}
	else
	{
		
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
	int iCounter = RoundToNearest(flCounter * 10.0);
	
	if (flCounter <= 0.0)
	{
		EmitSoundToAll("buttons/blip2.wav", grenade);
		
		iState    = TRIPWIRE_STATE_DETECT;
		flCounter = 0.0;
	}
	else if (!(iCounter % 2))
	{
		int iPitch = 200 - iCounter * 4;
		
		if (iPitch <= 100)
		{
			iPitch = 100;
		}
		
		EmitSoundToAll("buttons/blip1.wav", grenade, _, _, _, _, iPitch);
	}
	
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
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	if (owner != -1)
	{
		static float vPosition[3]; static float vEndPosition[3];

		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);
		GetEntPropVector(grenade, Prop_Data, "m_vecViewOffset", vEndPosition);
		
		bool bDetonate; int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
		
		TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, SelfFilter, grenade);

		if (TR_DidHit())
		{
			TR_GetEndPosition(vEndPosition);
			
			int victim = TR_GetEntityIndex();
			
			if ((IsClientValid(victim)) && (ZP_GetPlayerTeam(victim) != iTeam))
			{
				bDetonate = true;
			}
		}
		
		if (bDetonate)
		{
			CreateTimer(0.1, GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Stop;
		}
		
		if (flCounter <= 0.0)
		{
			static int iPlayers[MAXPLAYERS+1]; static int vColor[4];
			
			int iMaxPlayers = GetClientsInRange(vPosition, RangeType_Audibility, iPlayers, MaxClients);
			
			for (int i = 0; i < iMaxPlayers; i++)
			{
				int client = iPlayers[i];
				
				if (ZP_GetPlayerTeam(client) == iTeam)
				{
					vColor = (client == owner) ? GRENADE_SELF_COLOR : GRENADE_TEAMMATE_COLOR;
				}
				else
				{
					vColor = GRENADE_ENEMY_COLOR;
				}
				
				TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, gHalo, 0, 0, 0.1, 8.0, 8.0, 0, 0.0, vColor, 30);
				TE_SendToClient(client);
			}
			
			flCounter = 0.1; 
		}
	}
	else
	{
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	
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
	int grenade = EntRefToEntIndex(refID);

	Action hResult = Plugin_Stop;
	
	if (grenade != -1)
	{
		int iState = GetEntProp(grenade, Prop_Data, "m_iHammerID");
		float flCounter = GetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime");

		if (flCounter > 0.0)
		{
			flCounter -= 0.1;
		}
		
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
		
		SetEntProp(grenade, Prop_Data, "m_iHammerID", iState);
		SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", flCounter);
	}
	
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
	if (!GetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget"))
	{
		if (!target || ZP_IsBSPModel(target))
		{
			GrenadeSatchelTrackWall(grenade);
		}
	}
	
	return Plugin_Handled;
}

/**
 * @brief Move to another state.
 * 
 * @param grenade           The grenade index.
 **/
void GrenadeSatchelTrackWall(int grenade)
{
	static float vPosition[3]; static float vEndPosition[3]; static float vNormal[3];
	
	static const int vLoop[6][2] = { {2, 1}, {2, -1}, {0, 1}, {0, -1}, {1, 1}, {1, -1} };
	
	GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

	int victim; float flFraction; float flBestFraction = 1.0;
	
	for (int i = 0; i < 6; i++)
	{
		vEndPosition[vLoop[i][0]] = vPosition[vLoop[i][0]] + (2.0 * float(vLoop[i][1]));
		
		Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, PlayerFilter, grenade);

		if (!TR_DidHit(hTrace))
		{
			static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
			static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
			
			delete hTrace;
			hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, PlayerFilter, grenade);
			
			if (TR_DidHit(hTrace))
			{
				victim = TR_GetEntityIndex(hTrace);

				if (victim < 1 || ZP_IsBSPModel(victim))
				{
					UTIL_FindHullIntersection(hTrace, vPosition, vMins, vMaxs, PlayerFilter, grenade);
				}
			}
		}
		
		if (TR_DidHit(hTrace))
		{
			victim = TR_GetEntityIndex(hTrace);

			if (victim < 1 || ZP_IsBSPModel(victim))
			{
				flFraction = TR_GetFraction(hTrace);
				if (flBestFraction > flFraction)
				{
					flBestFraction = flFraction;
					
					TR_GetEndPosition(vEndPosition, hTrace);
					TR_GetPlaneNormal(hTrace, vNormal);
				}
			}
		}
		
		delete hTrace;
	}
	
	if (flBestFraction < 1.0)
	{
		TeleportEntity(grenade, vEndPosition, NULL_VECTOR, NULL_VECTOR);

		CreateTimer(0.1, GrenadeSatchelThinkHook, EntIndexToEntRef(grenade), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		SetEntProp(grenade, Prop_Data, "m_bIsAutoaimTarget", true);
		
		SetEntityMoveType(grenade, MOVETYPE_NONE);
		
		GrenadeSetBreakable(grenade);
	}
	else
	{
		
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
	int iCounter = RoundToNearest(flCounter * 10.0);
	
	if (flCounter <= 0.0)
	{
		EmitSoundToAll("buttons/blip2.wav", grenade);
		
		iState    = SATCHEL_STATE_ENABLED;
		flCounter = 0.0;
	}
	else if (!(iCounter % 2))
	{
		int iPitch = 200 - iCounter * 4;
		
		if (iPitch <= 100)
		{
			iPitch = 100;
		}
		
		EmitSoundToAll("buttons/blip1.wav", grenade, _, _, _, _, iPitch);
	}
	
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
	int owner = GetEntPropEnt(grenade, Prop_Data, "m_hOwnerEntity");
	
	if (owner != -1)
	{
		static float vPosition[3];
		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);

		if (flCounter <= 0.0)
		{
			static int iPlayers[MAXPLAYERS+1]; static int vColor[4]; int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
			
			int iMaxPlayers = GetClientsInRange(vPosition, RangeType_Audibility, iPlayers, MaxClients);
			
			float flRadius = hCvarGrenadeSatchelRadius.FloatValue;
			
			for (int i = 0; i < iMaxPlayers; i++)
			{
				int client = iPlayers[i];
				
				if (ZP_GetPlayerTeam(client) == iTeam)
				{
					vColor = (client == owner) ? GRENADE_SELF_COLOR : GRENADE_TEAMMATE_COLOR;
				}
				else
				{
					vColor = GRENADE_ENEMY_COLOR;
				}
				
				TE_SetupBeamRingPoint(vPosition, flRadius, flRadius * 2.0, gBeacon, gHalo, 0, 0, 0.1, 4.0, 0.0, vColor, 30, 0);
				TE_SendToClient(client);
			}
			
			flCounter = 0.1; 
		}
	}
	else
	{
		CreateTimer(GetRandomFloat(0.5, 2.0), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Stop;
	}
	
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
	int grenade = EntRefToEntIndex(refID);

	Action hResult = Plugin_Stop;
	
	if (grenade != -1)
	{
		int iState = GetEntProp(grenade, Prop_Data, "m_iHammerID");
		float flCounter = GetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime");

		if (flCounter > 0.0)
		{
			flCounter -= 0.1;
		}
		
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
		
		SetEntProp(grenade, Prop_Data, "m_iHammerID", iState);
		SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", flCounter);
	}
	
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
	int grenade = EntRefToEntIndex(refID);

	if (grenade != -1)
	{
		static float vPosition[3]; static float vAngle[3]; static float vPosition2[3]; static float vVelocity[3]; static float vEndVelocity[3];

		GetEntPropVector(grenade, Prop_Data, "m_vecAbsOrigin", vPosition);
			
		int target = GetEntPropEnt(grenade, Prop_Data, "m_hEffectEntity");
		if (target != 0 || !UTIL_CanSeeEachOther(grenade, target, vPosition, SelfFilter) || ZP_GetPlayerTeam(target) != GetEntProp(grenade, Prop_Data, "m_iHammerID")) /// If team was changed, reset target
		{
			int iTeam = GetEntProp(grenade, Prop_Data, "m_iTeamNum");
	
			float flOldDistance = MAX_FLOAT; float flNewDistance;

			float flRadius = hCvarGrenadeHomingRadius.FloatValue;

			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
			{
				int iPending = ZP_GetPlayerTeam(i);
				if (iPending == iTeam)
				{
					continue;
				}
				
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2);
			
				flNewDistance = GetVectorDistance(vPosition, vPosition2);
				
				if (flNewDistance < flOldDistance)
				{
					flOldDistance = flNewDistance;
					SetEntPropEnt(grenade, Prop_Data, "m_hEffectEntity", i);
					SetEntProp(grenade, Prop_Data, "m_iHammerID", iPending);
					SetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime", flOldDistance);
				}
			}
		}
		else
		{
	
			GetEntPropVector(grenade, Prop_Data, "m_vecVelocity", vVelocity);
	
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vPosition2);

			MakeVectorFromPoints(vPosition, vPosition2, vEndVelocity);

			if (GetEntPropFloat(grenade, Prop_Data, "m_flDissolveStartTime") > hCvarGrenadeHomingAvoid.FloatValue)
			{
				NormalizeVector(vEndVelocity, vEndVelocity);
				NormalizeVector(vVelocity, vVelocity);
				
				ScaleVector(vEndVelocity, hCvarGrenadeHomingRotation.FloatValue); 
				AddVectors(vEndVelocity, vVelocity, vEndVelocity);
			}
		
			NormalizeVector(vEndVelocity, vEndVelocity);
			
			ScaleVector(vEndVelocity, hCvarGrenadeHomingSpeed.FloatValue);

			GetVectorAngles(vEndVelocity, vAngle);

			TeleportEntity(grenade, NULL_VECTOR, vAngle, vEndVelocity);
		}
	}
	else
	{
		return Plugin_Stop;
	}
	
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
	SetEntProp(grenade, Prop_Data, "m_takedamage", DAMAGE_YES);
	SetEntProp(grenade, Prop_Data, "m_iHealth", 1);
	
	SDKHook(grenade, SDKHook_OnTakeDamage, GrenadeDamageHook);
}

/**
 * @brief Force the grenade to a detonation.
 *
 * @param grenade           The grenade index.
 **/
stock void GrenadeDetonate(int grenade)
{
	static char sClassname[SMALL_LINE_LENGTH];
	GetEdictClassname(grenade, sClassname, sizeof(sClassname));

	if (!strncmp(sClassname, "smoke", 5, false) || !strncmp(sClassname, "tag", 3, false))
	{
		static float vEmpty[3];
		TeleportEntity(grenade, NULL_VECTOR, NULL_VECTOR, vEmpty);
		
		SetEntProp(grenade, Prop_Data, "m_nNextThinkTick", 1);
	}
	else
	{
		GrenadeSetBreakable(grenade);
		
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
	if (hGrenadeList[client] != null)
	{
		int i; int grenade; /// Pop all grenades in the list
		while ((i = hGrenadeList[client].Length - 1) != -1)
		{
			grenade = EntRefToEntIndex(hGrenadeList[client].Get(i));
			if (grenade != -1)
			{
				CreateTimer(GetRandomFloat(0.3, 0.5), GrenadeDetonateHook, EntIndexToEntRef(grenade), TIMER_FLAG_NO_MAPCHANGE);
			}
			
			hGrenadeList[client].Erase(i);
		}
		
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
	if (hGrenadeList[client] == null)
	{
		hGrenadeList[client] = new ArrayList();
	}
	
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
	if (IsClientValid(entity)) 
	{
		return false;
	}

	return (entity != filter);
}
