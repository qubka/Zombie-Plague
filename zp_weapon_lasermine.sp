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
	name            = "[ZP] Weapon: LaserMine",
	author          = "qubka (Nikita Ushakov)",
	description     = "Addon of custom weapon",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_LIFE           0.1
#define WEAPON_BEAM_WIDTH          3.0
#define WEAPON_BEAM_HUMAN_COLOR    {0, 0, 255, 255}
#define WEAPON_BEAM_HUMAN_COLOR_F  "0 0 255"
#define WEAPON_GLOW_HUMAN_COLOR    {0, 255, 0, 255}
#define WEAPON_BEAM_ZOMBIE_COLOR   {255, 0, 0, 255}
#define WEAPON_BEAM_ZOMBIE_COLOR_F "255 0 0"
#define WEAPON_GLOW_ZOMBIE_COLOR   {255, 255, 0, 255}
#define WEAPON_IDLE_TIME           1.66
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT   5.0
#define METAL_GIBS_DELAY    0.05
#define METAL_GIBS_SPEED    500.0
#define METAL_GIBS_VARIENCE 1.0  
#define METAL_GIBS_LIFE     1.0  
#define METAL_GIBS_DURATION 2.0
/**
 * @endsection
 **/

// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_SHOOT,
	ANIM_DRAW
};

// Timer index
Handle hMineCreate[MAXPLAYERS+1] = { null, ... }; 

// Item index
int gWeapon;

// Sound index
int gSound; ConVar hKnockBack;

// Decal index
int gBeam;

// Cvars
ConVar hCvarLaserminePickup;
ConVar hCvarLasermineImpulse;
ConVar hCvarLasermineRewards;
ConVar hCvarLasermineDamage;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarLaserminePickup  = CreateConVar("zp_weapon_lasermine_pickup", "1", "Can pickup?", 0, true, 0.0, true, 1.0);
	hCvarLasermineImpulse = CreateConVar("zp_weapon_lasermine_impulse", "0", "Use the classical beam?", 0, true, 0.0, true, 1.0);
	hCvarLasermineRewards = CreateConVar("zp_weapon_lasermine_rewards", "1", "Give rewards for damaging to the owner?", 0, true, 0.0, true, 1.0);
	hCvarLasermineDamage  = CreateConVar("zp_weapon_lasermine_damage", "150.0", "Damage amount", 0, true, 0.0);
	
	AutoExecConfig(true, "zp_weapon_lasermine", "sourcemod/zombieplague");
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
	gWeapon = ZP_GetWeaponNameID("lasermine");

	gSound = ZP_GetSoundKeyID("lasermine_shoot_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"lasermine_shoot_sounds\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gBeam = PrecacheModel("materials/sprites/purplelaser1.vmt", true);
	PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
	PrecacheModel("models/gibs/metal_gib1.mdl", true);
	PrecacheModel("models/gibs/metal_gib2.mdl", true);
	PrecacheModel("models/gibs/metal_gib3.mdl", true);
	PrecacheModel("models/gibs/metal_gib4.mdl", true);
	PrecacheModel("models/gibs/metal_gib5.mdl", true);

	PrecacheSound("weapons/taser/taser_hit.wav", true);
	PrecacheSound("weapons/taser/taser_shoot.wav", true);
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		hMineCreate[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
	}
}

/**
 * @brief Called when a client is disconnecting from the server.
 * 
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
	delete hMineCreate[client];
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);

	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnIdle(int client, int weapon, float flCurrentTime)
{
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, float flCurrentTime)
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
	
	GetClientEyePosition(client, vPosition);
	ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);
	
	TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

	if (TR_DidHit() && TR_GetEntityIndex() < 1)
	{
		flCurrentTime += ZP_GetWeaponReload(gWeapon);

		ZP_SetWeaponAnimation(client, ANIM_SHOOT);

		delete hMineCreate[client];
		hMineCreate[client] = CreateTimer(ZP_GetWeaponReload(gWeapon) - 0.1, Weapon_OnCreateMine, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		flCurrentTime += 0.1;
	}
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
}

/**
 * @brief Timer for creating mine.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateMine(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID); int weapon;

	hMineCreate[client] = null;

	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{
		static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; 
		
		GetClientEyePosition(client, vPosition);
		ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);

		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

		if (TR_DidHit() && TR_GetEntityIndex() < 1)
		{
			TR_GetEndPosition(vPosition);
			TR_GetPlaneNormal(null, vAngle);

			GetVectorAngles(vAngle, vAngle); vAngle[0] += 90.0;

			static char sModel[PLATFORM_LINE_LENGTH];
			ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
			
			int iFlags = PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR;
			if (hCvarLaserminePickup.BoolValue)
			{
				iFlags |= PHYS_GENERATEUSE;
			}
			
			int entity = UTIL_CreatePhysics("mine", vPosition, vAngle, sModel, iFlags);
			
			if (entity != -1)
			{
				SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
				SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);

				int iHealth = GetEntProp(weapon, Prop_Data, "m_iClip2");
				
				if (iHealth > 0)
				{
					SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
					SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
					SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHealth);
					
					SDKHook(entity, SDKHook_OnTakeDamage, MineDamageHook);
				}
				else
				{
					SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_NO);
				}
				
				SDKHook(entity, SDKHook_UsePost, MineUseHook);
				
				vAngle[0] -= 90.0;
				TR_TraceRayFilter(vPosition, vAngle, MASK_SOLID, RayType_Infinite, PlayerFilter, entity);
				
				TR_GetEndPosition(vEndPosition);
				
				SetEntPropVector(entity, Prop_Data, "m_vecViewOffset", vEndPosition);
				
				SetEntPropEnt(entity, Prop_Data, "m_hEffectEntity", client); /// m_hOwnerEntity will block SDKHook_UsePost
				
				SetEntProp(entity, Prop_Data, "m_iTeamNum", ZP_IsPlayerZombie(client) ? TEAM_ZOMBIE : TEAM_HUMAN); 

				CreateTimer(ZP_GetWeaponModelHeat(gWeapon), MineActivateHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.1, MineSolidHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				
				ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC);
			}
			
			ZP_RemoveWeapon(client, weapon);
			
			return Plugin_Stop;
		}

		float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon);
		
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    

		ZP_SetWeaponAnimation(client, ANIM_DRAW);
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
		SetEntProp(weapon, Prop_Data, "m_iClip2", ZP_GetWeaponClip(gWeapon));
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
		delete hMineCreate[client];
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
		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon); 
			iButtons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		
		_call.Idle(client, weapon);
	}

	return Plugin_Continue;
}

//**********************************************
//* Item (mine) hooks.                         *
//**********************************************

/**
 * @brief Mine use hook.
 *
 * @param entity            The entity index.
 * @param activator         The activator index.
 * @param caller            The caller index.
 * @param use               The use type.
 * @param flValue           The value parameter.
 **/ 
public void MineUseHook(int entity, int activator, int caller, UseType use, float flValue)
{
	if (IsClientValid(activator))
	{
		if (ZP_IsPlayerHasWeapon(activator, gWeapon) == -1 && IsEntitySameTeam(entity, activator))
		{
			int owner = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
			
			if (owner == activator)
			{
				int weapon = ZP_GiveClientWeapon(activator, gWeapon);
				
				if (weapon != -1)
				{
					SetEntProp(weapon, Prop_Data, "m_iClip2", GetEntProp(entity, Prop_Data, "m_iHealth"));
					
					AcceptEntityInput(entity, "Kill");
				}
			}
		}
	}
}

/**
 * @brief Mine damage hook.
 * 
 * @param entity            The entity index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action MineDamageHook(int entity, int &attacker, int &inflictor, float &flDamage, int &damageBits)
{
	if (IsClientValid(attacker))
	{
		if (!IsEntitySameTeam(entity, attacker))
		{
			int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

			if (!iHealth)
			{
				SDKUnhook(entity, SDKHook_OnTakeDamage, MineDamageHook);
		
				MineExpload(entity);
			}
			else
			{
				SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
			}
		}
	}
	
	return Plugin_Handled;
}

/**
 * @brief Exploade mine.
 * 
 * @param entity            The entity index.                    
 **/
void MineExpload(int entity)
{
	static float vPosition[3]; static float vGib[3]; float vShoot[3];

	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

	UTIL_CreateExplosion(vPosition, /*EXP_NOFIREBALL | */EXP_NOSOUND | EXP_NODAMAGE);
	
	ZP_EmitSoundToAll(gSound, 5, entity, SNDCHAN_STATIC);

	for (int x = 1; x <= 5; x++)
	{
		vShoot[1] += 72.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); 
		switch (x)
		{
			case 1 : UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, "models/gibs/metal_gib1.mdl", vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
			case 2 : UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, "models/gibs/metal_gib2.mdl", vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
			case 3 : UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, "models/gibs/metal_gib3.mdl", vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
			case 4 : UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, "models/gibs/metal_gib4.mdl", vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
			case 5 : UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, "models/gibs/metal_gib5.mdl", vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
		}
	}
	
	UTIL_RemoveEntity(entity, 0.1);
}

/**
 * @brief Main timer for activate mine.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action MineActivateHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		static float vPosition[3]; static float vEndPosition[3]; 

		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC);
		
		CreateTimer(ZP_GetWeaponShoot(gWeapon), MineUpdateHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

		bool bZombie = GetEntProp(entity, Prop_Data, "m_iTeamNum") == TEAM_ZOMBIE;

		if (hCvarLasermineImpulse.BoolValue)
		{
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vEndPosition);
			
			static char sModel[PLATFORM_LINE_LENGTH];
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

			int glow = UTIL_CreateGlowing("glow", vPosition, vEndPosition, sModel, "dropped", _, _, bZombie ? WEAPON_GLOW_ZOMBIE_COLOR : WEAPON_GLOW_HUMAN_COLOR);

			if (glow != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(glow, "SetParent", entity, glow);
			}
		}
		else
		{
			GetEntPropVector(entity, Prop_Data, "m_vecViewOffset", vEndPosition);
			
			int beam = UTIL_CreateBeam(vPosition, vEndPosition, _, _, _, _, _, _, _, _, _, "materials/sprites/purplelaser1.vmt", _, _, _, _, _, _, bZombie ? WEAPON_BEAM_ZOMBIE_COLOR_F : WEAPON_BEAM_HUMAN_COLOR_F, 0.002, 0.0, "beam");
			
			if (beam != -1)
			{
				SetEntPropEnt(entity, Prop_Data, "m_hMoveChild", beam);
				SetEntPropEnt(beam, Prop_Data, "m_hEffectEntity", entity);
			}
		}
	}
	
	return Plugin_Stop;
} 

/**
 * @brief Main timer for making solid mine.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action MineSolidHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
		static const float vMaxs[3] = {  20.0,  20.0, 20.0  }; 
		
		ArrayList hList = new ArrayList();
		
		TR_EnumerateEntitiesHull(vPosition, vPosition, vMins, vMaxs, false, HullEnumerator, hList);

		if (!hList.Length)
		{
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
			
			delete hList;
			return Plugin_Stop;
		}
		
		delete hList;
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Main timer for update mine.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action MineUpdateHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		static float vPosition[3]; static float vEndPosition[3];
		
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
		GetEntPropVector(entity, Prop_Data, "m_vecViewOffset", vEndPosition);

		int owner = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
		int attacker = hCvarLasermineRewards.BoolValue && IsClientValid(owner, false) && IsEntitySameTeam(entity, owner) ? owner : -1;
		float flDamage = hCvarLasermineDamage.FloatValue;

		if (hCvarLasermineImpulse.BoolValue)
		{
			static float vVelocity[3]; static float vVelocity2[3];
		
			TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TeamFilter, entity);

			if (TR_DidHit())
			{
				int victim = TR_GetEntityIndex();

				TR_GetEndPosition(vEndPosition);

				if (IsClientValid(victim) && !IsEntitySameTeam(entity, victim))
				{    
					ZP_TakeDamage(victim, attacker, entity, flDamage, DMG_BULLET);
			
					ZP_EmitSoundToAll(gSound, 4, victim, SNDCHAN_ITEM);
					
					float flForce = ZP_GetClassKnockBack(ZP_GetClientClass(victim)) * ZP_GetWeaponKnockBack(gWeapon); 
					if (flForce > 0.0)
					{
						if (hKnockBack.BoolValue)
						{
							MakeVectorFromPoints(vPosition, vEndPosition, vVelocity);

							NormalizeVector(vVelocity, vVelocity);

							ScaleVector(vVelocity, flForce);
							
							GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vVelocity2);
							
							AddVectors(vVelocity2, vVelocity, vVelocity);
						
							TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vVelocity);
						}
						else
						{
							SetEntPropFloat(victim, Prop_Send, "m_flStamina",  min(flForce, 100.0));
						}
					}
				}
				
				bool bZombie = GetEntProp(entity, Prop_Data, "m_iTeamNum") == TEAM_ZOMBIE;
				
				TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, WEAPON_BEAM_LIFE, WEAPON_BEAM_WIDTH, WEAPON_BEAM_WIDTH, 10, 1.0, bZombie ? WEAPON_BEAM_ZOMBIE_COLOR : WEAPON_BEAM_HUMAN_COLOR, 30);
				TE_SendToAll();

				EmitAmbientSound("weapons/taser/taser_hit.wav", vEndPosition, SOUND_FROM_WORLD, _, _, 0.5, SNDPITCH_LOW);
				EmitAmbientSound("weapons/taser/taser_shoot.wav", vPosition, SOUND_FROM_WORLD, _, _, 0.3, SNDPITCH_LOW);
			}
		}
		else
		{
			ArrayList hList = new ArrayList();

			TR_EnumerateEntities(vPosition, vEndPosition, false, RayType_EndPoint, RayEnumerator, hList);
			
			for(int i = 0; i < hList.Length; i++)
			{
				int victim = hList.Get(i);
				
				if (IsClientValid(victim) && !IsEntitySameTeam(entity, victim))
				{
					ZP_TakeDamage(victim, attacker, entity, flDamage, DMG_BULLET);
				
					ZP_EmitSoundToAll(gSound, 4, victim, SNDCHAN_ITEM);
				}
			}

			delete hList;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

//**********************************************
//* Useful stocks.                             *
//**********************************************

/**
 * @brief Validate a lasermine.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
/*bool IsEntityBeam(int entity)
{
	if (entity <= MaxClients || !IsValidEdict(entity))
	{
		return false;
	}
	
	static char sClassname[SMALL_LINE_LENGTH];
	GetEntPropString(entity, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
	
	return (!strncmp(sClassname, "beam", 4, false));
}*/

/**
 * @brief Validate a lasermine.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
/*bool IsEntityLasermine(int entity)
{
	if (entity <= MaxClients || !IsValidEdict(entity))
	{
		return false;
	}
	
	static char sClassname[SMALL_LINE_LENGTH];
	GetEntPropString(entity, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
	
	return (!strcmp(sClassname, "mine", false));
}*/

/**
 * @brief Validates that an entity in the same team as a given client.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 * @return                  True or false.
 **/
bool IsEntitySameTeam(int entity, int client)
{
	int iTeam = GetEntProp(entity, Prop_Data, "m_iTeamNum");
	return (iTeam == TEAM_HUMAN && ZP_IsPlayerHuman(client)) || (iTeam == TEAM_ZOMBIE && ZP_IsPlayerZombie(client));
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
 * @return                  True or false.
 **/
public bool PlayerFilter(int entity, int contentsMask, int filter)
{
	if (IsClientValid(entity)) 
	{
		return false;
	}

	return (entity != filter);
}

/**
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 * @return                  True or false.
 **/
public bool TeamFilter(int entity, int contentsMask, int filter)
{
	if (IsClientValid(entity) && IsEntitySameTeam(filter, entity)) 
	{
		return false;
	}

	return (entity != filter);
}

/**
 * @brief Hull filter.
 *
 * @param entity            The entity index.
 * @param hData             The array handle.
 * @return                  True to continue enumerating, otherwise false.
 **/
public bool HullEnumerator(int entity, ArrayList hData)
{
	if (IsClientValid(entity))
	{
		TR_ClipCurrentRayToEntity(MASK_ALL, entity);
		if (TR_DidHit()) hData.Push(entity);
	}
		
	return true;
}

/**
 * @brief Ray filter.
 *
 * @param entity            The entity index.
 * @param hData             The array handle.
 * @return                  True to continue enumerating, otherwise false.
 **/
public bool RayEnumerator(int entity, ArrayList hData)
{
	if (IsClientValid(entity))
	{
		TR_ClipCurrentRayToEntity(MASK_ALL, entity);
		if (TR_DidHit()) hData.Push(entity);
	}
		
	return true;
}
