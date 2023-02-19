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
	name            = "[ZP] Weapon: JetPack",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Timer index
Handle hItemReload[MAXPLAYERS+1] = { null, ... }; Handle hItemDuration[MAXPLAYERS+1];

// Sound index
int gSound;

// Item index
int gWeapon;

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		LoadTranslations("jetpack.phrases");
		
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		hItemReload[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
		hItemDuration[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("jetpack");
	
	gSound = ZP_GetSoundKeyID("JETPACK_FLY_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JETPACK_FLY_SOUNDS\" wasn't find");
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	delete hItemReload[client];
	delete hItemDuration[client];
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	delete hItemReload[client];
	delete hItemDuration[client];
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	delete hItemReload[client];
	delete hItemDuration[client];
}

/**
 * @brief Called before show a weapon in the weapons menu.
 * 
 * @param client            The client index.
 * @param weaponID          The weapon index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
public Action ZP_OnClientValidateWeapon(int client, int weaponID)
{
	if (weaponID == gWeapon)
	{
		if (GetEntProp(client, Prop_Send, "m_bHasDefuser"))
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Item_OnActive(int client)
{
	if (IsItemActive(client, 0.1))
	{
		return;
	}
	
	if (hItemReload[client] != null)
	{
		return;
	}
	
	if (hItemDuration[client] == null)
	{
		float flDuration = ZP_GetWeaponDeploy(gWeapon);
		
		hItemDuration[client] = CreateTimer(flDuration, Item_OnDisable, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	
		ZP_SetProgressBarTime(client, RoundToNearest(flDuration));
	}
	
	static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; 
	
	GetClientEyeAngles(client, vAngle); vAngle[0] = -40.0;
	
	GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
	
	ScaleVector(vVelocity, ZP_GetWeaponShoot(gWeapon));
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE);
	
	int entity = ZP_GetClientAttachModel(client, BitType_DefuseKit);

	if (entity != -1)
	{
		static int iAttach = -1;
		if (iAttach == -1) iAttach = LookupEntityAttachment(entity, "1");
		GetEntityAttachment(entity, iAttach, vPosition, vAngle);
		
		static char sMuzzle[NORMAL_LINE_LENGTH];
		ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
		
		UTIL_CreateParticle(entity, vPosition, _, _, sMuzzle, 0.5);
	}
}

/**
 * @brief Timer for disabled jetpack.
 *
 * @param hTimer            The timer handle.
 * @param client            The user id.
 **/
public Action Item_OnDisable(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);
	
	hItemDuration[client] = null;
	
	if (client)
	{
		ZP_SetProgressBarTime(client, 0);
		
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "jetpack empty");
		
		EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
		
		delete hItemReload[client];
		hItemReload[client] = CreateTimer(ZP_GetWeaponReload(gWeapon), Item_OnReload, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

/**
 * @brief Timer for reload jetpack.
 *
 * @param hTimer            The timer handle.
 * @param client            The user id.
 **/
public Action Item_OnReload(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);
	
	hItemReload[client] = null;
	
	if (client)
	{
		SetGlobalTransTarget(client);
		PrintHintText(client, "%t", "jetpack reloaded");
		
		EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
	}
	
	return Plugin_Stop;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1) \
					 \
	Item_On%0        \
	(                \
		%1           \
	)    
	
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
	if ((iButtons & IN_JUMP) && (iButtons & IN_DUCK))
	{
		if (GetEntProp(client, Prop_Send, "m_bHasDefuser"))
		{
			_call.Active(client);
		}
	}
	
	return Plugin_Continue;
}

//**********************************************
//* Useful stocks.                             *
//**********************************************

/**
 * @brief Validate the active delay.
 * 
 * @param client            The client index.
 * @param flTimeDelay       The delay time.
 **/
stock bool IsItemActive(int client, float flTimeDelay)
{
	static float flActiveTime[MAXPLAYERS+1];
	
	float flCurrentTime = GetTickedTime();
	
	if ((flCurrentTime - flActiveTime[client]) < flTimeDelay)
	{
		return true;
	}
	
	flActiveTime[client] = flCurrentTime;
	return false;
}
