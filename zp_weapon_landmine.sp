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
	name            = "[ZP] ExtraItem: Landmine",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of extra items",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Item index
int gWeapon;

// Timer index
Handle hEmitterCreate[MAXPLAYERS+1] = { null, ... }; 

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT,
	ANIM_DRAW,
	ANIM_IDLE_TRIGGER_OFF,
	ANIM_IDLE_TRIGGER_ON,
	ANIM_SWITCH_TRIGGER_OFF,
	ANIM_SWITCH_TRIGGER_ON,
	ANIM_SHOOT_TRIGGER_OFF,
	ANIM_SHOOT_TRIGGER_ON,
	ANIM_DRAW_TRIGGER_OFF,
	ANIM_DRAW_TRIGGER_ON
};

// Weapon states
enum
{
	STATE_TRIGGER_OFF,
	STATE_TRIGGER_ON
};


/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME      1.66  
#define WEAPON_IDLE2_TIME     2.0
#define WEAPON_SWITCH_TIME    1.0
#define WEAPON_BEAM_COLOR_F   "255 165 0"

/**
 * @endsection
 **/

/**
 * @section Properties of the gibs shooter.
 **/                                  
#define METAL_GIBS_AMOUNT   5.0
#define METAL_GIBS_DELAY    0.05
#define METAL_GIBS_SPEED    500.0
#define METAL_GIBS_VARIENCE 2.0  
#define METAL_GIBS_LIFE     2.0  
#define METAL_GIBS_DURATION 3.0
/**
 * @endsection
 **/

// Cvars
ConVar hCvarLandmineDamage;
ConVar hCvarLandmineRadius;
ConVar hCvarLandmineExp;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarLandmineDamage = CreateConVar("zp_weapon_landmine_damage", "3000.0", "Mine damage", 0, true, 0.0);
	hCvarLandmineRadius = CreateConVar("zp_weapon_landmine_radius", "300.0", "Damage radius", 0, true, 0.0);
	hCvarLandmineExp    = CreateConVar("zp_weapon_landmine_explosion", "explosion_basic", "Particle effect for the explosion (''-default)");

	AutoExecConfig(true, "zp_weapon_landmine", "sourcemod/zombieplague");
}


/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		LoadTranslations("landmine.phrases");
		
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
	PrecacheSound("survival/breach_land_01.wav", true);
	PrecacheSound("survival/breach_activate_01.wav", true);
	PrecacheSound("survival/breach_defuse_01.wav", true);
	PrecacheSound("survival/breach_activate_nobombs_01.wav", true);
	PrecacheSound("survival/missile_land_01.wav", true);
	PrecacheSound("survival/missile_land_02.wav", true);
	PrecacheSound("survival/missile_land_03.wav", true);
	PrecacheSound("survival/missile_land_04.wav", true);
	PrecacheSound("survival/missile_land_05.wav", true);
	PrecacheSound("survival/missile_land_06.wav", true);
	
	PrecacheModel("models/gibs/metal_gib1.mdl", true);
	PrecacheModel("models/gibs/metal_gib2.mdl", true);
	PrecacheModel("models/gibs/metal_gib3.mdl", true);
	PrecacheModel("models/gibs/metal_gib4.mdl", true);
	PrecacheModel("models/gibs/metal_gib5.mdl", true);
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		hEmitterCreate[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 * 
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	delete hEmitterCreate[client];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("landmine");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	delete hEmitterCreate[client];
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	if (!bTrigger)
	{
		ZP_SetWeaponAnimation(client, ANIM_IDLE);
	
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
	}
	else 
	{
		ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_IDLE_TRIGGER_OFF : ANIM_IDLE_TRIGGER_ON);
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE2_TIME);
	}
}

void Weapon_OnDeploy(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
	
	ZP_SetWeaponAnimation(client, !bTrigger ? ANIM_DRAW : !iStateMode ? ANIM_DRAW_TRIGGER_OFF : ANIM_DRAW_TRIGGER_ON); 
}

void Weapon_OnPrimaryAttack(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}

	static float vPosition[3]; static float vEndPosition[3];

	if (!bTrigger)
	{
		GetClientEyePosition(client, vPosition);
		ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);

		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

		if (TR_DidHit() && TR_GetEntityIndex() < 1)
		{
			flCurrentTime += ZP_GetWeaponShoot(gWeapon);
		
			ZP_SetWeaponAnimation(client, ANIM_SHOOT);  
			
			delete hEmitterCreate[client]; /// Bugfix
			hEmitterCreate[client] = CreateTimer(ZP_GetWeaponShoot(gWeapon) - 0.1, Weapon_OnCreateEmitter, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			flCurrentTime += 0.1;
		}
	}
	else
	{
		flCurrentTime += ZP_GetWeaponReload(gWeapon);

		ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_SHOOT_TRIGGER_OFF : ANIM_SHOOT_TRIGGER_ON);  
		
		CreateTimer(0.99, Weapon_OnRemove, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);

		int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity"); 

		if (entity != -1)
		{    
			MineExpload(entity);
		}
	}
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
}

void Weapon_OnSecondaryAttack(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	if (!bTrigger)
	{
		return;
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_SWITCH_TRIGGER_ON : ANIM_SWITCH_TRIGGER_OFF);
	ZP_SetPlayerAnimation(client, PLAYERANIMEVENT_GRENADE_PULL_PIN);
	
	flCurrentTime += WEAPON_SWITCH_TIME;

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
	
	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	SetGlobalTransTarget(client);
	PrintHintText(client, "%t", !iStateMode ? "trigger on info" : "trigger off info");
	
	EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
}

/**
 * @brief Timer for creating emitter.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateEmitter(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID); int weapon;

	hEmitterCreate[client] = null;

	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{
		 // Initialize vectors
		static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

		GetClientEyePosition(client, vPosition);
		ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);

		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

		if (TR_DidHit() && TR_GetEntityIndex() < 1)
		{
			TR_GetEndPosition(vPosition);
			TR_GetPlaneNormal(null, vAngle); 

			static char sModel[PLATFORM_LINE_LENGTH];
			ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
			
			int entity = UTIL_CreatePhysics("emitter", vPosition, vAngle, sModel, PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);
			
			if (entity != -1)
			{
				SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
				SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
				
				SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_NO);
				
				SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
				SetEntPropEnt(entity, Prop_Data, "m_hDamageFilter", weapon);
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
				
				SetEntProp(entity, Prop_Data, "m_iHammerID", STATE_TRIGGER_OFF);
				
				EmitSoundToAll("survival/breach_land_01.wav", entity, SNDCHAN_STATIC);
				
				CreateTimer(0.2, MineThinkHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
			
			SetEntProp(weapon, Prop_Data, "m_iClip2", STATE_TRIGGER_ON);

			ZP_SetWeaponAnimation(client, ANIM_DRAW_TRIGGER_OFF);
		}
		else
		{
			ZP_SetWeaponAnimation(client, ANIM_DRAW);
		}

		float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon);
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
	}
	
	return Plugin_Stop;
}

/**
 * @brief Timer for removing trigger.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action Weapon_OnRemove(Handle hTimer, int refID)
{
	int weapon = EntRefToEntIndex(refID);

	if (weapon != -1)
	{
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");

		if (IsClientValid(client))
		{
			ZP_RemoveWeapon(client, weapon);
		}
		else
		{
			AcceptEntityInput(weapon, "Kill");
		}
	}
	
	return Plugin_Stop;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2) \
						\
	Weapon_On%0         \
	(                   \
		%1,             \
		%2,             \
						\
		GetEntProp(%2, Prop_Data, "m_iClip2"), \
						\
		GetEntProp(%2, Prop_Data, "m_iSecondaryAmmoCount"), \
						\
		GetGameTime()   \
   )    

/**
 * @brief Called after a custom weapon is created.
 *
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", STATE_TRIGGER_OFF);
		SetEntProp(weapon, Prop_Data, "m_iClip2", STATE_TRIGGER_OFF);
		SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
	}
}    
   
/**
 * @brief Called on deploy of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDeploy(int client, int weapon, int weaponID) 
{
	if (weaponID == gWeapon)
	{
		_call.Deploy(client, weapon);
	}
}    

/**
 * @brief Called on holster of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponHolster(int client, int weapon, int weaponID) 
{
	if (weaponID == gWeapon)
	{
		_call.Holster(client, weapon);
	}
}

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
	if (weaponID == gWeapon)
	{
		static float flApplyModeTime;
		if ((flApplyModeTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
		{
			SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

			int iStateMode = !GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount");
			
			SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", iStateMode);
			
			EmitSoundToAll("survival/breach_activate_nobombs_01.wav", client, SNDCHAN_WEAPON);

			int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity"); 

			if (entity != -1)
			{
				SetEntProp(entity, Prop_Data, "m_iHammerID", iStateMode);
				
				EmitSoundToAll(iStateMode ? "survival/breach_activate_01.wav" : "survival/breach_defuse_01.wav", entity, SNDCHAN_STATIC);
			}
		}
	
		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon); 
			iButtons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		else if (iButtons & IN_ATTACK2)
		{
			_call.SecondaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
		
		_call.Idle(client, weapon);
	}

	return Plugin_Continue;
}

/**
 * @brief Main timer for mine think.
 * 
 * @param hTimer            The timer handle.
 * @param refID             The reference index.                    
 **/
public Action MineThinkHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		if (GetEntProp(entity, Prop_Data, "m_iHammerID") == STATE_TRIGGER_OFF)
		{
			return Plugin_Continue;
		}

		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
				
		float flRadius = hCvarLandmineRadius.FloatValue;
		
		int i; int it = 1; /// iterator
		while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
		{
			if (!ZP_IsPlayerZombie(i))
			{
				continue;
			}

			if (!UTIL_CanSeeEachOther(entity, i, vPosition, SelfFilter))
			{
				continue;
			}
			
			MineExpload(entity, true);
			
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Exploade mine.
 * 
 * @param entity            The entity index.   
 * @param bRemove           (Optional) Remove client's trigger? 
 **/
void MineExpload(int entity, bool bRemove = false)
{
	static float vPosition[3]; static float vGib[3]; float vShoot[3];

	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

	static char sEffect[SMALL_LINE_LENGTH];
	hCvarLandmineExp.GetString(sEffect, sizeof(sEffect));

	int iFlags = EXP_NOSOUND;

	if (hasLength(sEffect))
	{
		UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
		iFlags |= EXP_NOFIREBALL; /// remove effect sprite
	}
	
	int client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	int weapon = GetEntPropEnt(entity, Prop_Data, "m_hDamageFilter");
	
	if (weapon != -1)
	{
		SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", -1);
		
		if (bRemove && IsClientValid(client)) 
		{
			ZP_RemoveWeapon(client, weapon);
		}
	}

	UTIL_CreateExplosion(vPosition, iFlags, _, hCvarLandmineDamage.FloatValue, hCvarLandmineRadius.FloatValue, "landmine", client, entity);
	
	switch (GetRandomInt(0, 5))
	{
		case 0 : EmitSoundToAll("survival/missile_land_01.wav", entity, SNDCHAN_STATIC);
		case 1 : EmitSoundToAll("survival/missile_land_02.wav", entity, SNDCHAN_STATIC);
		case 2 : EmitSoundToAll("survival/missile_land_03.wav", entity, SNDCHAN_STATIC);
		case 3 : EmitSoundToAll("survival/missile_land_04.wav", entity, SNDCHAN_STATIC);
		case 4 : EmitSoundToAll("survival/missile_land_05.wav", entity, SNDCHAN_STATIC);
		case 5 : EmitSoundToAll("survival/missile_land_06.wav", entity, SNDCHAN_STATIC);
	}
	
	static char sBuffer[NORMAL_LINE_LENGTH];
	for (int x = 0; x <= 4; x++)
	{
		vShoot[1] += 72.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
		{
			case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib1.mdl");
			case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib2.mdl");
			case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib3.mdl");
			case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib4.mdl");
			case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib5.mdl");
		}
		
		UTIL_CreateShooter(entity, "weapon_hand_R", _, MAT_METAL, _, sBuffer, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
	}

	UTIL_RemoveEntity(entity, 0.1);
}

/**
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @return                  True or false.
 **/
public bool ClientFilter(int entity, int contentsMask)
{
	return !(1 <= entity <= MaxClients);
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