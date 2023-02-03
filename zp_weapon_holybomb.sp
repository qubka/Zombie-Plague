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
	name            = "[ZP] Weapon: HolyGrenade",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_COLOR {255, 75, 75, 255}
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define GLASS_GIBS_AMOUNT              5.0
#define GLASS_GIBS_DELAY               0.05
#define GLASS_GIBS_SPEED               500.0
#define GLASS_GIBS_VARIENCE            1.0  
#define GLASS_GIBS_LIFE                1.0  
#define GLASS_GIBS_DURATION            2.0
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
ConVar gCvarHolyRadius;
ConVar gCvarHolyDuration;
ConVar gCvarHolyTrail;
ConVar gCvarHolyEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	// Initialize cvars
	gCvarHolyRadius   = CreateConVar("zp_weapon_holybomb_radius", "300.0", "Explosion radius", 0, true, 0.0);
	gCvarHolyDuration = CreateConVar("zp_weapon_holybomb_duration", "5.0", "Ignite duration", 0, true, 0.0);
	gCvarHolyTrail    = CreateConVar("zp_weapon_holybomb_trail", "0", "Attach trail to the projectile?", 0, true, 0.0, true, 1.0);
	gCvarHolyEffect   = CreateConVar("zp_weapon_holybomb_effect", "explosion_hegrenade_water", "Particle effect for the explosion (''-default)");
		
	// Generate config
	AutoExecConfig(true, "zp_weapon_holybomb", "sourcemod/zombieplague");
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
		// Hook entity events
		HookEvent("hegrenade_detonate", EventEntityNapalm, EventHookMode_Post);

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
	gWeapon = ZP_GetWeaponNameID("holy grenade");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"holy grenade\" wasn't find");
	
	// Sounds
	gSound = ZP_GetSoundKeyID("HOLY_GRENADE_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HOLY_GRENADE_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Models
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	gBeam = PrecacheModel("materials/sprites/lgtning.vmt", true);
	gHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
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
	// Client was damaged by 'explosion'
	if (iBits & DMG_BLAST)
	{
		// Validate inflicter
		if (IsValidEdict(inflictor))
		{
			// Validate custom grenade
			if (GetEntProp(inflictor, Prop_Data, "m_iHammerID") == gWeapon)
			{
				// Resets explosion damage
				flDamage *= ZP_IsPlayerHuman(client) ? 0.0 : ZP_GetWeaponDamage(gWeapon);
			}
		}
	}
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
		if (gCvarHolyTrail.BoolValue)
		{
			// Create an trail effect
			TE_SetupBeamFollow(grenade, gTrail, 0, 1.0, 10.0, 10.0, 5, WEAPON_BEAM_COLOR);
			TE_SendToAll();	
		}
	}
}

/**
 * Event callback (hegrenade_detonate)
 * @brief The hegrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityNapalm(Event hEvent, char[] sName, bool dontBroadcast) 
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
			float flDuration = gCvarHolyDuration.FloatValue;
			float flRadius = gCvarHolyRadius.FloatValue;
			float flKnock = ZP_GetWeaponKnockBack(gWeapon);
			
			// Find any players in the radius
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
			{
				// Skip humans
				if (ZP_IsPlayerHuman(i))
				{
					continue;
				}
				
				// Gets victim origin
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
				
				// Put the fire on
				UTIL_IgniteEntity(i, flDuration);   
				
				// Create a knockback
				UTIL_CreatePhysForce(i, vPosition, vEnemy, GetVectorDistance(vPosition, vEnemy), flKnock, flRadius);
				
				// Create a shake
				UTIL_CreateShakeScreen(i, 2.0, 1.0, 3.0);
			}

			// Gets particle name
			static char sEffect[SMALL_LINE_LENGTH];
			gCvarHolyEffect.GetString(sEffect, sizeof(sEffect));
			
			// Validate effect
			if (hasLength(sEffect))
			{
				// Create an explosion effect
				UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			}
			else
			{
				// Create a simple effect
				TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, WEAPON_BEAM_COLOR, 0, 0);
				TE_SendToAll();
			}
		}
	}
	
	// Allow event
	return Plugin_Continue;
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
			if (!strncmp(sSample[23], "bounce", 6, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
				
				// Block sounds
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[20], "explode", 7, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
				
				// Block sounds
				return Plugin_Stop; 
			}
		}
	}
	
	// Allow sounds
	return Plugin_Continue;
}
