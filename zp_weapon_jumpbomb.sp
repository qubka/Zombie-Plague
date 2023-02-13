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

// Sound index
int gSound;
 
// Item index
int gWeapon;

// Cvars
ConVar hCvarJumpRadius;
ConVar hCvarJumpDamage;
ConVar hCvarJumpTrail;
ConVar hCvarJumpEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarJumpRadius = CreateConVar("zp_weapon_jumpbomb_radius", "400.0", "Explosiion radius", 0, true, 0.0);
	hCvarJumpDamage = CreateConVar("zp_weapon_jumpbomb_damage", "1000.0", "Explosiion physics damage", 0, true, 0.0);
	hCvarJumpTrail  = CreateConVar("zp_weapon_jumpbomb_trail", "0", "Attach trail to the projectile?", 0, true, 0.0, true, 1.0);
	hCvarJumpEffect = CreateConVar("zp_weapon_jumpbomb_effect", "explosion_hegrenade_water", "Particle effect for the explosion (''-default)");
	
	AutoExecConfig(true, "zp_weapon_jumpbomb", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		HookEvent("player_blind", EventPlayerBlind, EventHookMode_Pre);

		HookEvent("flashbang_detonate", EventEntityFlash, EventHookMode_Post);

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
	gWeapon = ZP_GetWeaponNameID("jump bomb");
	
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
	if (weaponID == gWeapon)
	{
		if (hCvarJumpTrail.BoolValue)
		{
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
	static float vPosition[3]; static float vPosition2[3];

	int grenade = hEvent.GetInt("entityid");
	vPosition[0] = hEvent.GetFloat("x"); 
	vPosition[1] = hEvent.GetFloat("y"); 
	vPosition[2] = hEvent.GetFloat("z");

	if (IsValidEdict(grenade))
	{
		if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)
		{
			float flRadius = hCvarJumpRadius.FloatValue;
			float flKnock = ZP_GetWeaponKnockBack(gWeapon);
			
			int i; int it = 1; /// iterator
			while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
			{
				GetEntPropVector(i, Prop_Data, "m_vecAbsOrigin", vPosition2);
		
				UTIL_CreatePhysForce(i, vPosition, vPosition2, GetVectorDistance(vPosition, vPosition2), flKnock, flRadius);
				
				UTIL_CreateShakeScreen(i, 2.0, 1.0, 3.0);
			}

			static char sEffect[SMALL_LINE_LENGTH];
			hCvarJumpEffect.GetString(sEffect, sizeof(sEffect));
			
			if (hasLength(sEffect))
			{
				int entity = UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
				
				if (entity != -1)
				{
					CreateTimer(0.1, EntityOnPhysExp, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else 
			{
				TE_SetupBeamRingPoint(vPosition, 10.0, flRadius, gBeam, gHalo, 1, 1, 0.2, 100.0, 1.0, WEAPON_BEAM_COLOR, 0, 0);
				TE_SendToAll();
			}
			
			
			AcceptEntityInput(grenade, "Kill");
		}
	}
	
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
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
 
		entity = UTIL_CreateProjectile(vPosition, NULL_VECTOR, gWeapon);
		
		if (entity != -1)
		{
			UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND | EXP_NOSMOKE | EXP_NOUNDERWATER, _, hCvarJumpDamage.FloatValue, hCvarJumpRadius.FloatValue, "jumpbomb", _, entity);

			AcceptEntityInput(entity, "Kill");
		}
	}
	
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
	if (IsValidEdict(inflictor))
	{
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
	if (!dontBroadcast) 
	{
		hEvent.BroadcastDisabled = true;
	}
	
	int client = GetClientOfUserId(hEvent.GetInt("userid"));

	if (!IsPlayerExist(client))
	{
		return Plugin_Continue;
	}
	
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 0.0);
	
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
	if (IsValidEdict(entity))
	{
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == gWeapon)
		{
			if (!strncmp(sSample[27], "hit", 3, false))
			{
				ZP_EmitSoundToAll(gSound, GetRandomInt(1, 2), entity, SNDCHAN_STATIC, SNDLEVEL_BOUNCE);
				
				return Plugin_Stop; 
			}
			else if (!strncmp(sSample[29], "exp", 3, false))
			{
				ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, SNDLEVEL_BOUNCE);
				
				return Plugin_Stop; 
			}
		}
	}
	
	return Plugin_Continue;
}
