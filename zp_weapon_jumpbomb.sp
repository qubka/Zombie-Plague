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
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_COLOR {127, 255, 212, 255}
/**
 * @endsection
 **/
 
// Decal index
int gBeam; int gHalo; int gTrail;
#pragma unused gBeam, gHalo, gTrail

// Sound index
int gSound;
#pragma unused gSound
 
// Item index
int gWeapon;
#pragma unused gWeapon

// Cvars
ConVar gCvarJumpRadius;
ConVar gCvarJumpDamage;
ConVar gCvarJumpTrail;
ConVar gCvarJumpEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	gCvarJumpRadius = CreateConVar("zp_weapon_jumpbomb_radius", "400.0", "Explosiion radius", 0, true, 0.0);
	gCvarJumpDamage = CreateConVar("zp_weapon_jumpbomb_damage", "1000.0", "Explosiion physics damage", 0, true, 0.0);
	gCvarJumpTrail  = CreateConVar("zp_weapon_jumpbomb_trail", "0", "Attach trail to the projectile?", 0, true, 0.0, true, 1.0);
	gCvarJumpEffect = CreateConVar("zp_weapon_jumpbomb_effect", "explosion_hegrenade_water", "Particle effect for the explosion (''-default)");
	
	// Generate config
	AutoExecConfig(true, "zp_weapon_jumpbomb", "sourcemod/zombieplague");
}

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
	// Validate custom grenade
	if (weaponID == gWeapon)
	{
		// Validate trail
		if (gCvarJumpTrail.BoolValue)
		{
			// Create an trail effect
			TE_SetupBeamFollow(grenade, gTrail, 0, 1.0, 10.0, 10.0, 5, WEAPON_BEAM_COLOR);
			TE_SendToAll();	
		}
	}
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
			// Gets grenade variables
			float flRadius = gCvarJumpRadius.FloatValue;
			float flKnock = ZP_GetWeaponKnockBack(gWeapon);
			
			// Find any players in the radius
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
			{
				// Gets victim origin
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
		
				// Create a knockback
				UTIL_CreatePhysForce(i, vPosition, vEnemy, GetVectorDistance(vPosition, vEnemy), flKnock, flRadius);
				
				// Create a shake
				UTIL_CreateShakeScreen(i, 2.0, 1.0, 3.0);
			}

			// Gets particle name
			static char sEffect[SMALL_LINE_LENGTH];
			gCvarJumpEffect.GetString(sEffect, sizeof(sEffect));
			
			// Validate effect
			if (hasLength(sEffect))
			{
				// Create an explosion effect
				int entity = UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
				
				// Validate entity
				if (entity != -1)
				{
					// Create phys exp task
					CreateTimer(0.1, EntityOnPhysExp, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else 
			{
				// Create a simple effect
				TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, WEAPON_BEAM_COLOR, 0, 0);
				TE_SendToAll();
			}
			
			/// Fix of "Detonation of grenade 'flashbang_projectile' attempted to record twice!"
			
			// Remove grenade
			AcceptEntityInput(grenade, "Kill");
		}
	}
	
	// Allow event
	return Plugin_Continue;
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
			UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND | EXP_NOSMOKE | EXP_NOUNDERWATER, _, gCvarJumpDamage.FloatValue, gCvarJumpRadius.FloatValue, "jumpbomb", _, entity);

			// Remove the entity from the world
			AcceptEntityInput(entity, "Kill");
		}
	}
	
	// Destroy timer
	return Plugin_Stop;
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
		return Plugin_Continue;
	}
	
	// Remove blindness
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
	
	// Block event
	return Plugin_Handled;
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value ifyou add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entity            Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFrags            The sound flags.
 * @param sEntry            The game sound entry name.
 * @param iSeed             The sound seed.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS], int &numClients, char sSample[PLATFORM_MAX_PATH], int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFrags, char sEntry[PLATFORM_MAX_PATH], int& iSeed)
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
				ZP_EmitSoundToAll(gSound, GetRandomInt(1, 2), entity, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
				
				// Block sounds
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[29], "exp", 3, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
				
				// Block sounds
				return Plugin_Stop; 
			}
		}
	}
	
	// Allow sounds
	return Plugin_Continue;
}
