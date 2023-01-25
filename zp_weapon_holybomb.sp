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
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_HOLY_RADIUS            300.0         // Holy size (radius)
#define GRENADE_HOLY_IGNITE_TIME       5.0           // Ignite duration
#define GRENADE_HOLY_SHAKE_AMP         2.0           // Amplutude of the shake effect
#define GRENADE_HOLY_SHAKE_FREQUENCY   1.0           // Frequency of the shake effect
#define GRENADE_HOLY_SHAKE_DURATION    3.0           // Duration of the shake effect in seconds
#define GRENADE_HOLY_EXP_TIME          2.0           // Duration of the explosion effect in seconds
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
	
	// Cvars
	hSoundLevel = FindConVar("zp_seffects_level");
	if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
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
			// Find any players in the radius
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, GRENADE_HOLY_RADIUS)) != -1)
			{
				// Skip humans
				if (ZP_IsPlayerHuman(i))
				{
					continue;
				}
				
				// Gets victim origin
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vEnemy);
				
				// Put the fire on
				UTIL_IgniteEntity(i, GRENADE_HOLY_IGNITE_TIME);   
				
				// Create a knockback
				UTIL_CreatePhysForce(i, vPosition, vEnemy, GetVectorDistance(vPosition, vEnemy), ZP_GetWeaponKnockBack(gWeapon), GRENADE_HOLY_RADIUS);
				
				// Create a shake
				UTIL_CreateShakeScreen(i, GRENADE_HOLY_SHAKE_AMP, GRENADE_HOLY_SHAKE_FREQUENCY, GRENADE_HOLY_SHAKE_DURATION);
			}

			// Create an explosion effect
			UTIL_CreateParticle(_, vPosition, _, _, "explosion_hegrenade_water", GRENADE_HOLY_EXP_TIME);
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
				ZP_EmitSoundToAll(gSound, 2, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
				
				// Block sounds
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[20], "explode", 7, false))
			{
				// Play sound
				ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
				
				// Block sounds
				return Plugin_Stop; 
			}
		}
	}
	
	// Allow sounds
	return Plugin_Continue;
}
