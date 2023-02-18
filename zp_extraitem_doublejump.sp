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
	name            = "[ZP] ExtraItem: DoubleJump",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of extra items",
	version         = "1.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Jump state
bool bHasJump[MAXPLAYERS+1]; bool bDoJump[MAXPLAYERS+1]; int iJumpNum[MAXPLAYERS+1];

// Item index
int gItem;

// Cvars
ConVar hCvarJumpsMax;
ConVar hCvarJumpsAdmin;
ConVar hCvarJumpsFlags;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarJumpsMax   = CreateConVar("zp_extraitem_doublejump_max", "1", "Maximum amount of jumps", 0, true, 1.0);
	hCvarJumpsAdmin = CreateConVar("zp_extraitem_doublejump_admin", "1", "Permanent access for admins (0-no, 1-humans, 2-zombies, 3-all)", 0, true, 0.0, true, 3.0);
	hCvarJumpsFlags = CreateConVar("zp_extraitem_doublejump_flags", "o", "Access flag string");

	AutoExecConfig(true, "zp_extraitem_doublejump", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	PrecacheSound("survival/jump_ability_01.wav", true);
	PrecacheSound("survival/jump_ability_long_01.wav", true);
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gItem = ZP_GetExtraItemNameID("double jump");
}

/**
 * @brief Called when a client is disconnecting from the server.
 *
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	bHasJump[client] = false;
	bDoJump[client] = false;
	iJumpNum[client] = 0;
}

/**
 * @brief Called when a client has been killed.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientDeath(int client, int attacker)
{
	bHasJump[client] = false;
	bDoJump[client] = false;
	iJumpNum[client] = 0;
}

/**
 * @brief Called when a client became a zombie/human.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
public void ZP_OnClientUpdated(int client, int attacker)
{
	bHasJump[client] = false;
	bDoJump[client] = false;
	iJumpNum[client] = 0;

	int iAdmin = hCvarJumpsAdmin.IntValue;
	if (iAdmin)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		hCvarJumpsFlags.GetString(sFlags, sizeof(sFlags));

		if (GetUserFlagBits(client) & ReadFlagString(sFlags))
		{
			bHasJump[client] = (iAdmin == 1 && ZP_IsPlayerHuman(client)) || (iAdmin == 2 && ZP_IsPlayerZombie(client)) || iAdmin == 3;
		}
	}
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param client            The client index.
 * @param itemID            The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int client, int itemID)
{
	if (itemID == gItem)
	{
		if (bHasJump[client])
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

/**
 * @brief Called after select an extraitem in the equipment menu.
 * 
 * @param client            The client index.
 * @param itemID            The item index.
 **/
public void ZP_OnClientBuyExtraItem(int client, int itemID)
{
	if (itemID == gItem)
	{
		bHasJump[client] = true;
	}
}

/**
 * @brief Called when a clients movement buttons are being processed.
 *  
 * @param client            The client index.
 * @param iButtons          Copyback buffer containing the current commands. (as bitflags - see entity_prop_stocks.inc)
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles          Players desired view angles.    
 * @param weaponID          The entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param iSubType          Weapon subtype when selected from a menu.
 * @param iCmdNum           Command number. Increments from the first command sent.
 * @param iTickCount        Tick count. A client prediction based on the server GetGameTickCount value.
 * @param iSeed             Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse            Mouse direction (x, y).
 **/ 
public void OnPlayerRunCmdPre(int client, int iButtons, int iImpulse, const float flVelocity[3], const float flAngles[3], int weaponID, int iSubType, int iCmdNum, int iTickCount, int iSeed, const int iMouse[2])
{
	if (!bHasJump[client] || !IsPlayerAlive(client))
	{
		return;
	}

	static int iLastButtons[MAXPLAYERS+1]; 
	
	if (iButtons & IN_JUMP)
	{
		int ground = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");

		if (ground == -1)
		{
			if (!(iLastButtons[client] & IN_JUMP))
			{
				if (iJumpNum[client] < hCvarJumpsMax.IntValue)
				{
					bDoJump[client] = true;
					iJumpNum[client]++;
				}
			}
		}
		else
		{
			iJumpNum[client] = 0;
		}
	}

	iLastButtons[client] = iButtons;
}

/**
 * @brief Called when a clients movement buttons are being processed.
 *  
 * @param client            The client index.
 * @param iButtons          Copyback buffer containing the current commands. (as bitflags - see entity_prop_stocks.inc)
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles          Players desired view angles.    
 * @param weaponID          The entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param iSubType          Weapon subtype when selected from a menu.
 * @param iCmdNum           Command number. Increments from the first command sent.
 * @param iTickCount        Tick count. A client prediction based on the server GetGameTickCount value.
 * @param iSeed             Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse            Mouse direction (x, y).
 **/ 
public void OnPlayerRunCmdPost(int client, int iButtons, int iImpulse, const float flVelocity[3], const float flAngles[3], int weaponID, int iSubType, int iCmdNum, int iTickCount, int iSeed, const int iMouse[2])
{
	if (!bHasJump[client] || !IsPlayerAlive(client))
	{
		return;
	}

	if (bDoJump[client])
	{
		static float vVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
		
		vVelocity[2] = GetRandomFloat(265.0, 285.0);
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
		
		EmitSoundToAll(GetRandomInt(0, 1) ? "survival/jump_ability_01.wav" : "survival/jump_ability_long_01.wav", entity, SNDCHAN_VOICE, SNDLEVEL_NORMAL);
		
		bDoJump[client] = false;
	}
}