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
	name            = "[ZP] Weapon: Freeze",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_COLOR {75, 75, 255, 255}
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define GLASS_GIBS_AMOUNT             5.0
#define GLASS_GIBS_DELAY              0.05
#define GLASS_GIBS_SPEED              500.0
#define GLASS_GIBS_VARIENCE           1.0  
#define GLASS_GIBS_LIFE               1.0  
#define GLASS_GIBS_DURATION           2.0
/**
 * @endsection
 **/
 
// Timer index
Handle hZombieFreezed[MAXPLAYERS+1] = { null, ... }; 

// Decal index
int gBeam; int gHalo; int gTrail;

// Sound index
int gSound;

// Item index
int gWeapon;

// Cvars
ConVar hCvarFreezeDuration;
ConVar hCvarFreezeRadius;
ConVar hCvarFreezeDamage;
ConVar hCvarFreezeTrail;
ConVar hCvarFreezeEffect;
ConVar hCvarFreezeExp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarFreezeDuration = CreateConVar("zp_weapon_freeze_duration", "3.5", "Freeze duration", 0, true, 0.0);
	hCvarFreezeRadius   = CreateConVar("zp_weapon_freeze_radius", "200.0", "Freeze radius", 0, true, 0.0);
	hCvarFreezeDamage   = CreateConVar("zp_weapon_freeze_damage", "1", "Zombie will immune to damage when frost", 0, true, 0.0, true, 1.0);
	hCvarFreezeTrail    = CreateConVar("zp_weapon_freeze_trail", "0", "Attach trail to the projectile?", 0, true, 0.0, true, 1.0);
	hCvarFreezeEffect   = CreateConVar("zp_weapon_freeze_effect", "dynamic_smoke5", "Particle effect for the freezing (''-off)");
	hCvarFreezeExp      = CreateConVar("zp_weapon_freeze_explosion", "explosion_hegrenade_dirt", "Particle effect for the explosion (''-default)");
	
	AutoExecConfig(true, "zp_weapon_freeze", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		HookEvent("smokegrenade_detonate", EventEntitySmoke, EventHookMode_Post);

		AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
		
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("freeze grenade");

	gSound = ZP_GetSoundKeyID("FREEZE_GRENADE_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"FREEZE_GRENADE_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	gBeam = PrecacheModel("materials/sprites/lgtning.vmt", true);
	gHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	PrecacheModel("models/gibs/glass_shard01.mdl", true);
	PrecacheModel("models/gibs/glass_shard02.mdl", true);
	PrecacheModel("models/gibs/glass_shard03.mdl", true);
	PrecacheModel("models/gibs/glass_shard04.mdl", true);
	PrecacheModel("models/gibs/glass_shard05.mdl", true);
	PrecacheModel("models/gibs/glass_shard06.mdl", true);
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		hZombieFreezed[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	delete hZombieFreezed[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	delete hZombieFreezed[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	SetEntityMoveType(client, MOVETYPE_WALK);

	delete hZombieFreezed[client];
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
	if (hCvarFreezeDamage.BoolValue && hZombieFreezed[client] != null) flDamage = 0.0;
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
	if (weaponID == gWeapon)
	{
		if (hCvarFreezeTrail.BoolValue)
		{
			TE_SetupBeamFollow(grenade, gTrail, 0, 1.0, 10.0, 10.0, 5, WEAPON_BEAM_COLOR);
			TE_SendToAll();	
		}
	}
}

/**
 * Event callback (smokegrenade_detonate)
 * @brief The smokegrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntitySmoke(Event hEvent, char[] sName, bool dontBroadcast) 
{

	static float vPosition[3]; static float vAngle[3]; static float vPosition2[3];

	int grenade = hEvent.GetInt("entityid");
	vPosition[0] = hEvent.GetFloat("x"); 
	vPosition[1] = hEvent.GetFloat("y"); 
	vPosition[2] = hEvent.GetFloat("z");
	
	if (IsValidEdict(grenade))
	{
		if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)
		{
			float flRadius = hCvarFreezeRadius.FloatValue;
			float flDuration = hCvarFreezeDuration.FloatValue;
			
			static char sEffect[SMALL_LINE_LENGTH];
			hCvarFreezeEffect.GetString(sEffect, sizeof(sEffect));

			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
			{
				if (ZP_IsPlayerHuman(i))
				{
					continue;
				}
				
				SetEntityMoveType(i, MOVETYPE_NONE);

				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2);

				if (hasLength(sEffect))
				{
					UTIL_CreateParticle(i, vPosition2, _, _, sEffect, flDuration + 0.5);
				}
				
				delete hZombieFreezed[i];
				hZombieFreezed[i] = CreateTimer(flDuration, ClientRemoveFreeze, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);

				vAngle[1] = GetRandomFloat(0.0, 360.0);
	   
				int ice = UTIL_CreateDynamic("ice", vPosition2, vAngle, "models/player/custom_player/zombie/ice/ice.mdl", "idle");

				if (ice != -1)
				{
					UTIL_RemoveEntity(ice, flDuration);
					
					ZP_EmitSoundToAll(gSound, 1, ice, SNDCHAN_STATIC, SNDLEVEL_WEAPON);
				}
			}

			hCvarFreezeExp.GetString(sEffect, sizeof(sEffect));
			
			if (hasLength(sEffect))
			{
				UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			}
			else
			{
				TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, WEAPON_BEAM_COLOR, 0, 0);
				TE_SendToAll();
			}
			
			TE_SetupSparks(vPosition, NULL_VECTOR, 5000, 1000);
			TE_SendToAll();
			
			AcceptEntityInput(grenade, "Kill");
		}
	}
	
	return Plugin_Continue;
}

/**
 * @brief Timer for the remove freeze.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action ClientRemoveFreeze(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);
	
	hZombieFreezed[client] = null;

	if (client)
	{
		static float vGib[3]; float vShoot[3]; 

		SetEntityMoveType(client, MOVETYPE_WALK);
		
		ZP_EmitSoundToAll(gSound, 2, client, SNDCHAN_VOICE, SNDLEVEL_SKILL);

		static char sBuffer[NORMAL_LINE_LENGTH];
		for (int x = 0; x <= 5; x++)
		{
			vShoot[1] += 60.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
			{
				case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard01.mdl");
				case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard02.mdl");
				case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard03.mdl");
				case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard04.mdl");
				case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard05.mdl");
				case 5 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/glass_shard06.mdl");
			}
		
			UTIL_CreateShooter(client, "eholster", _, MAT_GLASS, _, sBuffer, vShoot, vGib, GLASS_GIBS_AMOUNT, GLASS_GIBS_DELAY, GLASS_GIBS_SPEED, GLASS_GIBS_VARIENCE, GLASS_GIBS_LIFE, GLASS_GIBS_DURATION);
		}
	}
	
	return Plugin_Stop;
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
	if (IsValidEdict(entity))
	{
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == gWeapon)
		{
			if (!strncmp(sSample[31], "hit", 3, false))
			{
				ZP_EmitSoundToAll(gSound, GetRandomInt(4, 6), entity, SNDCHAN_STATIC, SNDLEVEL_BOUNCE);
				
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[29], "emit", 4, false))
			{
				ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, SNDLEVEL_BOUNCE);
			   
				return Plugin_Stop; 
			}
		}
	}
	
	return Plugin_Continue;
}
