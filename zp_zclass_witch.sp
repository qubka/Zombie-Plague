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
	name            = "[ZP] Zombie Class: Witch",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of zombie classses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gSmoke;

// Sound index
int gSound;

// Zombie index
int gZombie;

// Cvars
ConVar hCvarSkillSpeed;
ConVar hCvarSkillAttach;
ConVar hCvarSkillDuration;
ConVar hCvarSkillEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSkillSpeed    = CreateConVar("zp_zclass_witch_speed", "1500.0", "Speed of bat cloud", 0, true, 0.0);
	hCvarSkillAttach   = CreateConVar("zp_zclass_witch_attach", "150.0", "Speed of attached victim", 0, true, 0.0);
	hCvarSkillDuration = CreateConVar("zp_zclass_witch_duration", "4.0", "Duration of carrying with bats", 0, true, 0.0);
	hCvarSkillEffect   = CreateConVar("zp_zclass_witch_effect", "blood_pool", "Particle effect for the skill (''-off)");
	
	AutoExecConfig(true, "zp_zclass_witch", "sourcemod/zombieplague");
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
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gZombie = ZP_GetClassNameID("witch");
	
	gSound = ZP_GetSoundKeyID("WITCH_SKILL_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"WITCH_SKILL_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gSmoke = PrecacheModel("sprites/steam1.vmt", true);
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int client)
{
	if (ZP_GetClientClass(client) == gZombie)
	{
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEndVelocity[3];

		GetClientEyePosition(client, vPosition);

		GetClientEyeAngles(client, vAngle);

		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVelocity);
		
		ZP_EmitSoundToAll(gSound, 1, client, SNDCHAN_VOICE, SNDLEVEL_SKILL);
		
		int entity = UTIL_CreateProjectile(vPosition, vAngle, _, "models/weapons/cso/bazooka/w_bazooka_projectile.mdl");

		if (entity != -1)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 9.0);
			
			GetAngleVectors(vAngle, vEndVelocity, NULL_VECTOR, NULL_VECTOR);

			NormalizeVector(vEndVelocity, vEndVelocity);

			ScaleVector(vEndVelocity, hCvarSkillSpeed.FloatValue);

			AddVectors(vEndVelocity, vVelocity, vEndVelocity);

			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vEndVelocity);

			//UTIL_SetRenderColor(entity, Color_Alpha, 0);
			AcceptEntityInput(entity, "DisableDraw"); 
			AcceptEntityInput(entity, "DisableShadow"); /// Prevents the entity from receiving shadows
			
			int bat = UTIL_CreateDynamic("bats", NULL_VECTOR, NULL_VECTOR, "models/player/custom_player/zombie/bats/bats2.mdl", "fly", false);

			if (bat != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(bat, "SetParent", entity, bat);
				
				SetVariantString("1"); 
				AcceptEntityInput(bat, "SetParentAttachment", entity, bat);
			}

			SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			SetEntPropEnt(entity, Prop_Data, "m_hThrower", client);

			SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01);

			SDKHook(entity, SDKHook_Touch, BatTouchHook);
		}
	}

	return Plugin_Continue;
}


/**
 * @brief Bat touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action BatTouchHook(int entity, int target)
{
	if (IsValidEdict(target))
	{
		int thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
		
		if (thrower == target)
		{
			return Plugin_Continue;
		}
		
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		if (IsPlayerExist(target))
		{
			int bat = UTIL_CreateDynamic("bats", NULL_VECTOR, NULL_VECTOR, "models/player/custom_player/zombie/bats/bats2.mdl", "fly2", false);

			if (bat != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(bat, "SetParent", target, bat);
				SetEntPropEnt(bat, Prop_Data, "m_pParent", target); 
				if (thrower != -1)
				{
					SetEntPropEnt(bat, Prop_Data, "m_hOwnerEntity", thrower);
				}
				
				SetVariantString("eholster"); 
				AcceptEntityInput(bat, "SetParentAttachment", target, bat);

				float flDuration = hCvarSkillDuration.FloatValue;

				UTIL_RemoveEntity(bat, flDuration);

				CreateTimer(0.1, BatAttachHook, EntIndexToEntRef(bat), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}

			ZP_EmitSoundToAll(gSound, 2, target, SNDCHAN_VOICE, SNDLEVEL_SKILL);
		}
		else
		{
			static char sEffect[SMALL_LINE_LENGTH];
			hCvarSkillEffect.GetString(sEffect, sizeof(sEffect));
			
			if (hasLength(sEffect))
			{
				UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
			}
			
			ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, SNDLEVEL_SKILL);
			
			TE_SetupSmoke(vPosition, gSmoke, 130.0, 10);
			TE_SendToAll();
		}

		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Continue;
}

/**
 * @brief Main timer for attach bat hook.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action BatAttachHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		int target = GetEntPropEnt(entity, Prop_Data, "m_pParent"); 

		if (IsPlayerExist(owner) && IsPlayerExist(target))
		{
			static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];

			GetClientEyePosition(owner, vPosition);
			GetClientEyePosition(target, vAngle);

			MakeVectorFromPoints(vAngle, vPosition, vVelocity);
			
			vVelocity[2] = 0.0;

			NormalizeVector(vVelocity, vVelocity);

			ScaleVector(vVelocity, hCvarSkillAttach.FloatValue);

			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vVelocity);

			return Plugin_Continue;
		}
		else
		{
			AcceptEntityInput(entity, "Kill");
		}
	}

	return Plugin_Stop;
}
