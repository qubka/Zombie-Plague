/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
	name            = "[ZP] Weapon: JumpBomb",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_JUMP_RADIUS            400.0         // Jump size (radius)
#define GRENADE_JUMP_DAMAGE            1000.0        // Jump phys damage
#define GRENADE_JUMP_SHAKE_AMP         2.0           // Amplutude of the shake effect
#define GRENADE_JUMP_SHAKE_FREQUENCY   1.0           // Frequency of the shake effect
#define GRENADE_JUMP_SHAKE_DURATION    3.0           // Duration of the shake effect in seconds
#define GRENADE_JUMP_EXP_TIME          2.0           // Duration of the explosion effect in seconds
/**
 * @endsection
 **/
 
// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Item index
int gWeapon;
#pragma unused gWeapon

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		// Hook player events
		HookEvent("player_blind", EventPlayerBlind, EventHookMode_Pre);

		// Hook entity events
		HookEvent("flashbang_detonate", EventEntityFlash, EventHookMode_Post);

		// Hook server sounds
		AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
		
		// If map loaded, then run custom forward
		if (ZP_IsMapLoaded())
		{
			// Execute it
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Weapons
	gWeapon = ZP_GetWeaponNameID("jump bomb");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"jump bomb\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("JUMP_GRENADE_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JUMP_GRENADE_SOUNDS\" wasn't find");
	
	// Cvars
	hSoundLevel = FindConVar("zp_seffects_level");
	if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * Event callback (flashbang_detonate)
 * @brief The flashbang is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityFlash(Event hEvent, char[] sName, bool dontBroadcast) 
{
	// Gets real player index from event key
	///int owner = GetClientOfUserId(hEvent.GetInt("userid")); 

	// Initialize vectors
	static float vPosition[3]; static float vEnemy[3];

	// Gets all required event info
	int grenade = hEvent.GetInt("entityid");
	vPosition[0] = hEvent.GetFloat("x"); 
	vPosition[1] = hEvent.GetFloat("y"); 
	vPosition[2] = hEvent.GetFloat("z");

	// Validate entity
	if (IsValidEdict(grenade))
	{
		// Validate custom grenade
		if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)
		{
			// Find any players in the radius
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, GRENADE_JUMP_RADIUS)) != -1)
			{
				// Gets victim origin
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
		
				// Create a knockback
				UTIL_CreatePhysForce(i, vPosition, vEnemy, GetVectorDistance(vPosition, vEnemy), ZP_GetWeaponKnockBack(gWeapon), GRENADE_JUMP_RADIUS);
				
				// Create a shake
				UTIL_CreateShakeScreen(i, GRENADE_JUMP_SHAKE_AMP, GRENADE_JUMP_SHAKE_FREQUENCY, GRENADE_JUMP_SHAKE_DURATION);
			}

			/// Fix of "Detonation of grenade 'flashbang_projectile' attempted to record twice!"
			
			// Create an explosion effect
			int entity = UTIL_CreateParticle(_, vPosition, _, _, "explosion_hegrenade_water", GRENADE_JUMP_EXP_TIME);
			
			// Validate entity
			if (entity != -1)
			{
				// Create phys exp task
				CreateTimer(0.1, EntityOnPhysExp, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
			}
			
			// Remove grenade
			AcceptEntityInput(grenade, "Kill");
		}
	}
}

/**
 * @brief Timer for the additional phys explosion.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action EntityOnPhysExp(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Gets entity position
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
 
		/// Create additional grenade to exploade for phys force and to avoid from recursion
		entity = UTIL_CreateProjectile(vPosition, NULL_VECTOR);
		
		// Validate entity
		if (entity != -1)
		{
			// Sets grenade id
			SetEntProp(entity, Prop_Data, "m_iHammerID", gWeapon);

			// Create an explosion
			UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND | EXP_NOSMOKE | EXP_NOUNDERWATER, _, GRENADE_JUMP_DAMAGE, GRENADE_JUMP_RADIUS, "jumpbomb", _, entity);

			// Remove the entity from the world
			AcceptEntityInput(entity, "Kill");
		}
	}
}

/**
 * @brief Called before a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index. (Not validated!)
 * @param inflicter         The inflicter index. (Not validated!)
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 *
 * @note To block damage reset the damage to zero. 
 **/
public void ZP_OnClientValidateDamage(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon)
{
	// Validate grenade
	if (IsValidEdict(inflictor))
	{
		// Validate custom weapon
		if (GetEntProp(inflictor, Prop_Data, "m_iHammerID") == gWeapon)
		{
			flDamage = 0.0;
		}
	}
}

/**
 * Event callback (player_blind)
 * @brief Client has been blind.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerBlind(Event hEvent, char[] sName, bool dontBroadcast) 
{
	// Sets whether an event broadcasting will be disabled
	if (!dontBroadcast) 
	{
		// Disable broadcasting
		hEvent.BroadcastDisabled = true;
	}
	
	// Gets all required event info
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	// Validate client
	if (!IsPlayerExist(client))
	{
		return;
	}
	
	// Remove blindness
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value if you add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entity            Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFlags            The sound flags.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags)
{
	// Validate client
	if (IsValidEdict(entity))
	{
		// Validate custom grenade
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == gWeapon)
		{
			// Validate sound
			if (!strncmp(sSample[27], "hit", 3, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, GetRandomInt(1, 2), entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
				
				// Block sounds
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[29], "exp", 3, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
				
				// Block sounds
				return Plugin_Stop; 
			}
		}
	}
	
	// Allow sounds
	return Plugin_Continue;
}