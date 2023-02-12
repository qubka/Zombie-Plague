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
	name            = "[ZP] ExtraItem: AirDrop",
	author          = "qubka (Nikita Ushakov)",     
	description     = "Addon of extra items",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Sound index
int gSound;

 // Type index
int gType;

// Item index
int gWeapon; int gWeaponC4;

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
#define WEAPON_IDLE_TIME    1.66  
#define WEAPON_IDLE2_TIME   2.0
#define WEAPON_SWITCH_TIME  1.0
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

/**
 * @section Types of drop.
 **/
enum 
{
	SAFE,
	EXPL,
	HEAVY,
	LIGHT,
	PISTOL,
	HPIST,
	TOOLS,
	HTOOL
};
/**
 * @endsection
 **/

// Cvars
ConVar hCvarAirdropGlow;        
ConVar hCvarAirdropAmount;
ConVar hCvarAirdropHeight; 
ConVar hCvarAirdropHealth;
ConVar hCvarAirdropSpeed; 
ConVar hCvarAirdropExplosions;
ConVar hCvarAirdropWeapons ;
ConVar hCvarAirdropSmokeLife;
ConVar hCvarBombardingHeight; 
ConVar hCvarBombardingRadius; 
ConVar hCvarBombardingSpeed ;
	
/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarAirdropGlow        = CreateConVar("zp_weapon_airdrop_glow", "0", "Enable glow ?", 0, true, 0.0, true, 1.0);        
	hCvarAirdropAmount      = CreateConVar("zp_weapon_airdrop_amount", "6", "Amount of drops in heli", 0, true, 0.0);      
	hCvarAirdropHeight      = CreateConVar("zp_weapon_airdrop_height", "700.0", "Drop height spawn", 0, true, 0.0);      
	hCvarAirdropHealth      = CreateConVar("zp_weapon_airdrop_health", "300", "Health of drop", 0, true, 1.0);      
	hCvarAirdropSpeed       = CreateConVar("zp_weapon_airdrop_speed", "175.0", "Initial speed of drop", 0, true, 0.0);       
	hCvarAirdropExplosions  = CreateConVar("zp_weapon_airdrop_explosions", "3", "How many c4 needed to open safe", 0, true, 0.0);  
	hCvarAirdropWeapons     = CreateConVar("zp_weapon_airdrop_weapons", "15", "Amount of weapons in the safe bag", 0, true, 0.0);     
	hCvarAirdropSmokeLife   = CreateConVar("zp_weapon_airdrop_smoke_life", "14.0", "", 0, true, 0.0); 
	hCvarBombardingHeight   = CreateConVar("zp_weapon_bombarding_height", "700.0", "Rocket height spawn", 0, true, 0.0);   
	hCvarBombardingRadius   = CreateConVar("zp_weapon_bombarding_radius", "800.0", "Explosion radius", 0, true, 0.0);   
	hCvarBombardingSpeed    = CreateConVar("zp_weapon_bombarding_speed", "500.0", "Rocket speed", 0, true, 0.0);    
	
	AutoExecConfig(true, "zp_weapon_airdrop", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		LoadTranslations("airdrop.phrases");
		
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
	gWeapon = ZP_GetWeaponNameID("airdrop");
	gWeaponC4 = ZP_GetWeaponNameID("breachcharge");

	gSound = ZP_GetSoundKeyID("HELICOPTER_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HELICOPTER_SOUNDS\" wasn't find");
	
	gType = ZP_GetClassTypeID("human");
	if (gType == -1) SetFailState("[ZP] Custom class type ID from name : \"human\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	PrecacheSound("survival/container_death_01.wav", true);
	PrecacheSound("survival/container_death_02.wav", true);
	PrecacheSound("survival/container_death_03.wav", true);
	PrecacheSound("survival/container_damage_01.wav", true);
	PrecacheSound("survival/container_damage_02.wav", true);
	PrecacheSound("survival/container_damage_03.wav", true);
	PrecacheSound("survival/container_damage_04.wav", true);
	PrecacheSound("survival/container_damage_05.wav", true);
	PrecacheSound("survival/missile_gas_01.wav", true);
	PrecacheSound("survival/dropzone_freefall.wav", true);
	PrecacheSound("survival/dropzone_parachute_deploy.wav", true);
	PrecacheSound("survival/dropzone_parachute_success.wav", true);
	PrecacheSound("survival/dropzone_parachute_success_02.wav", true);
	PrecacheSound("survival/dropbigguns.wav", true);
	PrecacheSound("survival/breach_activate_nobombs_01.wav", true);
	PrecacheSound("survival/breach_land_01.wav", true);
	PrecacheSound("survival/rocketincoming.wav", true);
	PrecacheSound("survival/rocketalarm.wav", true);
	PrecacheSound("survival/missile_land_01.wav", true);
	PrecacheSound("survival/missile_land_02.wav", true);
	PrecacheSound("survival/missile_land_03.wav", true);
	PrecacheSound("survival/missile_land_04.wav", true);
	PrecacheSound("survival/missile_land_05.wav", true);
	PrecacheSound("survival/missile_land_06.wav", true);

	PrecacheModel("models/f18/f18.mdl", true);
	PrecacheModel("models/props_survival/safe/safe_door.mdl", true);
	PrecacheModel("models/props_survival/cash/dufflebag.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy.mdl", true);
	PrecacheModel("particle/particle_smokegrenade1.vmt", true); 
	PrecacheModel("particle/particle_smokegrenade2.vmt", true); 
	PrecacheModel("particle/particle_smokegrenade3.vmt", true); 
	PrecacheModel("models/gibs/metal_gib1.mdl", true);
	PrecacheModel("models/gibs/metal_gib2.mdl", true);
	PrecacheModel("models/gibs/metal_gib3.mdl", true);
	PrecacheModel("models/gibs/metal_gib4.mdl", true);
	PrecacheModel("models/gibs/metal_gib5.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib001.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib002.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib003.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib004.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib005.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib006.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib007.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib008.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib009.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib010.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib011.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib012.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib013.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib014.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib015.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib016.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib017.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib018.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib019.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib020.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib021.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib022.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib023.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib024.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib025.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib026.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib027.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib028.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib029.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib030.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib031.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib032.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib033.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib034.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib035.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib036.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib037.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib038.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib039.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib040.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib041.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib042.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib001.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib002.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib003.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib004.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib005.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib006.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib007.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib008.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib009.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib010.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib011.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib012.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib013.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib014.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib015.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib016.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib017.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib018.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib019.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib020.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib021.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib022.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib023.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib024.mdl", true);
	PrecacheModel("models/props_survival/cases/case_explosive_gib025.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib001.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib002.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib003.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib004.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib005.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib006.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib007.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib008.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib009.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib010.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib011.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib012.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib013.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib014.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib015.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib016.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib017.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib018.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib019.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib020.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib021.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib022.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib023.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib024.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_gib025.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib001.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib002.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib003.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib004.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib005.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib006.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib007.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib008.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib009.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib010.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib011.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib012.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib013.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib014.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib015.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib016.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib017.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib018.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib019.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib020.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib021.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib022.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib023.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib024.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib025.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib026.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib027.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib028.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib029.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib030.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib031.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib032.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib033.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib034.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib035.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy_gib036.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib001.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib002.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib003.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib004.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib005.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib006.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib007.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib008.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib009.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib010.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib011.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib012.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib013.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib014.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib015.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib016.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib017.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib018.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib019.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib020.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib021.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib022.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib023.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib024.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib025.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib026.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib027.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib028.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib029.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib030.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib031.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib032.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib033.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib034.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib035.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib036.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib001.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib002.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib003.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib004.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib005.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib006.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib007.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib008.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib009.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib010.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib011.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib012.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib013.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib014.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib015.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib016.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib017.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib018.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib019.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib020.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib021.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib022.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib023.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib024.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_gib025.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib001.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib002.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib003.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib004.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib005.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib006.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib007.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib008.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib009.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib010.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib011.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib012.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib013.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib014.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib015.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib016.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib017.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib018.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib019.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib020.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib021.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib022.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib023.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib024.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib025.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib026.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib027.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib028.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib029.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib030.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib031.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib032.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib033.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib034.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib035.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib036.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib037.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon_gib038.mdl", true);
}

/**
 * @brief Called after a zombie round is started.
 *
 * @param mode              The mode index. 
 **/
public void ZP_OnGameModeStart(int mode)
{
	if (gWeapon == -1)
	{
		return;
	}
	
	if (ZP_GetGameModeHumanType(mode) == gType && ZP_GetPlayingAmount() >= ZP_GetWeaponOnline(gWeapon))
	{
		int client = ZP_GetRandomHuman();

		if (client != -1)
		{
			int weapon;
			if ((weapon = ZP_IsPlayerHasWeapon(client, gWeapon)) != -1)
			{
				SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_TRIGGER_OFF);
				SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_TRIGGER_OFF);
				SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
			}
			else
			{
				ZP_GiveClientWeapon(client, gWeapon);

				SetGlobalTransTarget(client);
				PrintHintText(client, "%t", "airdrop info");
			}
		}
	}
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

	static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

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

		int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity"); 

		if (entity != -1)
		{    
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);

			TE_SetupSparks(vPosition, NULL_VECTOR, 5000, 1000);
			TE_SendToAll();

			switch (iStateMode)
			{
				case STATE_TRIGGER_OFF : 
				{
					float flDuration = hCvarAirdropSmokeLife.FloatValue;
					int smoke = UTIL_CreateSmoke(_, vPosition, vAngle, _, _, _, _, _, _, _, _, _, "255 20 147", "255", "particle/particle_smokegrenade1.vmt", flDuration, flDuration + 3.0);
					
					CreateHelicopter(vPosition, vAngle);
					
					if (smoke != -1)
					{
						EmitSoundToAll("survival/missile_gas_01.wav", smoke, SNDCHAN_STATIC, SNDLEVEL_WEAPON);
					}
				}
				
				case STATE_TRIGGER_ON : 
				{
					CreateJet(vPosition, vAngle);
					
					EmitSoundToAll("survival/rocketalarm.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_SKILL);
				}
			}
			
			AcceptEntityInput(entity, "Kill");
		}
		
		ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_SHOOT_TRIGGER_OFF : ANIM_SHOOT_TRIGGER_ON);  
		
		CreateTimer(0.99, Weapon_OnRemove, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
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
	
	flCurrentTime += WEAPON_SWITCH_TIME;

	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
	
	flCurrentTime -= 0.5;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	SetGlobalTransTarget(client);
	PrintHintText(client, "%t", !iStateMode ? "trigger on info" : "trigger off info");
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
				
				SetEntPropEnt(entity, Prop_Data, "m_pParent", client);
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
				
				EmitSoundToAll("survival/breach_land_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_AMBIENT);
				
			}
			
			SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_TRIGGER_ON);

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

		if (IsPlayerExist(client))
		{
			ZP_RemoveWeapon(client, weapon);
			
			ZP_GiveClientWeapon(client, gWeaponC4);
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
		GetEntProp(%2, Prop_Data, "m_iHealth"), \
						\
		GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
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
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_TRIGGER_OFF);
		SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_TRIGGER_OFF);
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

			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", !GetEntProp(weapon, Prop_Data, "m_iMaxHealth"));
			
			EmitSoundToAll("survival/breach_activate_nobombs_01.wav", client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
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

//**********************************************
//* Jet functions.                             *
//**********************************************

/**
 * @brief Create a jet entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.    
 **/
void CreateJet(float vPosition[3], float vAngle[3])
{
	vPosition[2] += hCvarBombardingHeight.FloatValue;

	static float vMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
	
	float vMax = vMaxs[2] - 100.0;
	if (vPosition[2] > vMax) vPosition[2] = vMax; 
	

	int entity = UTIL_CreateDynamic("f18", vPosition, vAngle, "models/f18/f18.mdl", "flyby1", false);
	
	if (entity != -1)
	{
		CreateTimer(2.7, JetBombHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);

		UTIL_RemoveEntity(entity, 6.6);
	}
}

/**
 * @brief Main timer for spawn bombs.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action JetBombHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		EmitSoundToAll("survival/rocketincoming.wav", entity, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);

		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];

		ZP_GetAttachment(entity, "sound_maker", vPosition, vAngle); vAngle[0] += 180.0;
		
		entity = UTIL_CreateProjectile(vPosition, vAngle, "models/player/custom_player/zombie/bomb/bomb.mdl");

		if (entity != -1)
		{
			vAngle[0] -= 90.0;//45.0;
	
			GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);

			NormalizeVector(vVelocity, vVelocity);

			ScaleVector(vVelocity, hCvarBombardingSpeed.FloatValue);
	
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
			
			 // Sets physics
			SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01);

			SDKHook(entity, SDKHook_Touch, BombTouchHook);
		}
	}
	
	return Plugin_Stop;
}

/**
 * @brief Bomb touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action BombTouchHook(int entity, int target)
{
	static float vPosition[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

	UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500", 2.0);
	UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500_fallback", 2.0);
	
	float flRadius = hCvarBombardingRadius.FloatValue;
	
	int i; int it = 1; /// iterator
	while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
	{
		if (ZP_IsPlayerHuman(i))
		{
			continue;
		}
		
		ForcePlayerSuicide(i);
	}
	
	switch (GetRandomInt(0, 5))
	{
		case 0 : EmitSoundToAll("survival/missile_land_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 1 : EmitSoundToAll("survival/missile_land_02.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 2 : EmitSoundToAll("survival/missile_land_03.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 3 : EmitSoundToAll("survival/missile_land_04.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 4 : EmitSoundToAll("survival/missile_land_05.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 5 : EmitSoundToAll("survival/missile_land_06.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
	}

	AcceptEntityInput(entity, "Kill");
	
	return Plugin_Continue;
}

//**********************************************
//* Helicopter functions.                      *
//**********************************************

/**
 * @brief Create a helicopter entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.                    
 **/
void CreateHelicopter(float vPosition[3], float vAngle[3])
{
	vPosition[2] += hCvarAirdropHeight.FloatValue;
	
	static float vMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
	
	float vMax = vMaxs[2] - 100.0;
	if (vPosition[2] > vMax) vPosition[2] = vMax; 
	
	int entity = UTIL_CreateDynamic("helicopter", vPosition, vAngle, "models/buildables/helicopter_rescue_fix.mdl", "helicopter_coop_hostagepickup_flyin", false);
	
	if (entity != -1)
	{
		CreateTimer(20.0, HelicopterStopHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.41, HelicopterSoundHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
		SetEntProp(entity, Prop_Data, "m_iHammerID", SAFE);
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", hCvarAirdropAmount.FloatValue);
	}
}

/**
 * @brief Main timer for stop helicopter.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action HelicopterStopHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		SetVariantString("helicopter_coop_hostagepickup_idle");
		AcceptEntityInput(entity, "SetAnimation");
		
		CreateTimer(5.0, HelicopterIdleHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

/**
 * @brief Main timer for creating sound. (Helicopter)
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action HelicopterSoundHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		static float vPosition[3]; static float vAngle[3];

		ZP_GetAttachment(entity, "dropped", vPosition, vAngle); 

		ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER); 
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Main timer for idling helicopter.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action HelicopterIdleHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		SetVariantString("helicopter_coop_towerhover_idle");
		AcceptEntityInput(entity, "SetAnimation");
		
		EmitSoundToAll("survival/dropbigguns.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_SKILL);
		
		CreateTimer(1.0, HelicopterDropHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		CreateTimer(6.6, HelicopterRemoveHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Stop;
}

/**
 * @brief Main timer for creating drop.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action HelicopterDropHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		int iLeft = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		if (iLeft)
		{
			iLeft--;
			
			SetEntProp(entity, Prop_Data, "m_iMaxHealth", iLeft);
		}
		else
		{
			return Plugin_Stop;
		}

		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];
		
		ZP_GetAttachment(entity, "dropped", vPosition, vAngle);
		
		int iType = GetEntProp(entity, Prop_Data, "m_iHammerID"); int drop; int iCollision; int iDamage; int iHealth = hCvarAirdropHealth.IntValue;
		switch (iType)
		{
			case SAFE :
			{
				drop = UTIL_CreatePhysics("safe", vPosition, NULL_VECTOR, "models/buildables/safe.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR | PHYS_GENERATEUSE);
				
				if (drop != -1)
				{
					iCollision = COLLISION_GROUP_PLAYER;
					iDamage = DAMAGE_EVENTS_ONLY;

					SDKHook(drop, SDKHook_UsePost, SafeUseHook);
					SDKHook(drop, SDKHook_OnTakeDamage, SafeDamageHook);
				}
				
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
					{
						SetGlobalTransTarget(i);
						PrintHintText(i, "%t", "airdrop safe", hCvarAirdropExplosions.IntValue);
					}
				}
			}
			
			default :
			{
				static char sModel[PLATFORM_LINE_LENGTH]; 
				static int vColor[4];

				switch (iType)
				{
					case EXPL : 
					{ 
						strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_explosive.mdl");    
						vColor = {255, 127, 80, 255};  
					}
					case HEAVY : 
					{ 
						strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_heavy_weapon.mdl"); 
						vColor = {220, 20, 60, 255};   
					} 
					case LIGHT : 
					{ 
						strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_light_weapon.mdl"); 
						vColor = {255, 0, 0, 255};  
					} 
					case PISTOL : 
					{ 
						strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_pistol.mdl");
						vColor = {240, 128, 128, 255}; 
					} 
					case HPIST : 
					{ 
						strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_pistol_heavy.mdl"); 
						vColor = {219, 112, 147, 255}; 
					} 
					case TOOLS : 
					{ 
						strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_tools.mdl");  
						vColor = {0, 0, 205, 255};     
					} 
					case HTOOL : 
					{ 
						strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_tools_heavy.mdl");
						vColor = {95, 158, 160, 255};  
					} 
				}

				drop = UTIL_CreatePhysics("case", vPosition, NULL_VECTOR, sModel, PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
				
				if (drop != -1)
				{
					iCollision = COLLISION_GROUP_WEAPON;
					iDamage = DAMAGE_YES;

					SDKHook(drop, SDKHook_OnTakeDamage, CaseDamageHook);
					
					if (hCvarAirdropGlow.BoolValue)
					{
						int glow = UTIL_CreateDynamic("glow", vPosition, NULL_VECTOR, sModel, "ref");

						if (glow != -1)
						{
							SetVariantString("!activator");
							AcceptEntityInput(glow, "SetParent", drop, glow);

							UTIL_CreateGlowing(glow, true, _, vColor[0], vColor[1], vColor[2], vColor[3]);
							
						}
					}
				}
				
				vAngle[0] = GetRandomFloat(-45.0, 45.0);
			}
		}

		SetEntProp(entity, Prop_Data, "m_iHammerID", GetRandomInt(EXPL, HTOOL));
		
		if (drop != -1)
		{
			GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
			
			NormalizeVector(vVelocity, vVelocity);
			
			ScaleVector(vVelocity, hCvarAirdropSpeed.FloatValue);
		
			TeleportEntity(drop, NULL_VECTOR, NULL_VECTOR, vVelocity);
			
			SetEntProp(drop, Prop_Data, "m_CollisionGroup", iCollision);
			SetEntProp(drop, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
			SetEntPropFloat(drop, Prop_Data, "m_flElasticity", 0.01);
			
			SetEntProp(drop, Prop_Data, "m_takedamage", iDamage);
			SetEntProp(drop, Prop_Data, "m_iHealth", iHealth);
			SetEntProp(drop, Prop_Data, "m_iMaxHealth", iHealth);
			
			SetEntProp(drop, Prop_Data, "m_iHammerID", iType);
		}
	}
	else
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Main timer for remove helicopter.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action HelicopterRemoveHook(Handle hTimer, int refID)
{
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		SetVariantString("helicopter_coop_towerhover_flyaway");
		AcceptEntityInput(entity, "SetAnimation");
		
		UTIL_RemoveEntity(entity, 8.3);
	}
	
	return Plugin_Stop;
}

/**
 * @brief Safe use hook.
 *
 * @param entity            The entity index.
 * @param activator         The activator index.
 * @param caller            The caller index.
 * @param use               The use type.
 * @param flValue           The value parameter.
 **/
public void SafeUseHook(int entity, int activator, int caller, UseType use, float flValue)
{
	if (GetEntProp(entity, Prop_Send, "m_nBody"))
	{
		SafeExpload(entity);
	}
}

/**
 * @brief Safe damage hook.
 *
 * @param entity            The entity index.    
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action SafeDamageHook(int entity, int &attacker, int &inflictor, float &flDamage, int &iBits)
{
	switch (GetRandomInt(0, 4))
	{
		case 0 : EmitSoundToAll("survival/container_damage_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_HURT);
		case 1 : EmitSoundToAll("survival/container_damage_02.wav", entity, SNDCHAN_STATIC, SNDLEVEL_HURT);
		case 2 : EmitSoundToAll("survival/container_damage_03.wav", entity, SNDCHAN_STATIC, SNDLEVEL_HURT);
		case 3 : EmitSoundToAll("survival/container_damage_04.wav", entity, SNDCHAN_STATIC, SNDLEVEL_HURT);
		case 4 : EmitSoundToAll("survival/container_damage_05.wav", entity, SNDCHAN_STATIC, SNDLEVEL_HURT);
	}
	
	if (GetEntProp(entity, Prop_Send, "m_nBody"))
	{
		int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

		if (!iHealth)
		{   
			SafeExpload(entity);
		}
		else
		{
			SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
		}
	}
	else
	{
		if (iBits & DMG_BLAST)
		{
			if (IsValidEdict(inflictor))
			{
				static char sClassname[SMALL_LINE_LENGTH];
				GetEdictClassname(inflictor, sClassname, sizeof(sClassname));

				if (!strncmp(sClassname, "brea", 4, false))
				{
					int iExp = GetEntProp(entity, Prop_Data, "m_iHammerID") + 1;
					SetEntProp(entity, Prop_Data, "m_iHammerID", iExp);
			
					if (iExp >= hCvarAirdropExplosions.IntValue)
					{
						static float vPosition[3]; static float vAngle[3]; 
						
						GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
						GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
						
						int bag = UTIL_CreatePhysics("bag", vPosition, vAngle, "models/props_survival/cash/dufflebag.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR | PHYS_GENERATEUSE);
						
						if (bag != -1)
						{
							SetEntProp(bag, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
							SetEntProp(bag, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);

							SetEntProp(bag, Prop_Data, "m_takedamage", DAMAGE_NO);
							
							SetEntProp(bag, Prop_Data, "m_iHammerID", hCvarAirdropWeapons.IntValue);
							
							SDKHook(bag, SDKHook_UsePost, BagUseHook);
						}

						ZP_GetAttachment(entity, "door", vPosition, vAngle);
						
						SetEntProp(entity, Prop_Send, "m_nBody", 1);
						
						int door = UTIL_CreatePhysics("door", vPosition, vAngle, "models/props_survival/safe/safe_door.mdl", PHYS_FORCESERVERSIDE);
						
						if (door != -1)
						{
							SetEntProp(door, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
							SetEntProp(door, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
						}
						
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
							{
								SetGlobalTransTarget(i);
								PrintHintTextToAll("%t", "airdrop bag");
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

/**
 * @brief Exploade safe.
 * 
 * @param entity            The entity index.                    
 **/
void SafeExpload(int entity)
{
	SDKUnhook(entity, SDKHook_OnTakeDamage, SafeDamageHook);

	static float vGib[3]; float vShoot[3];
	
	static char sBuffer[SMALL_LINE_LENGTH];
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

		UTIL_CreateShooter(entity, "forward", _, MAT_METAL, _, sBuffer, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
	}
	
	switch (GetRandomInt(0, 2))
	{
		case 0 : EmitSoundToAll("survival/container_death_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_DEATH);
		case 1 : EmitSoundToAll("survival/container_death_02.wav", entity, SNDCHAN_STATIC, SNDLEVEL_DEATH);
		case 2 : EmitSoundToAll("survival/container_death_03.wav", entity, SNDCHAN_STATIC, SNDLEVEL_DEATH);
	}

	UTIL_RemoveEntity(entity, 0.1);
}

/**
 * @brief Bag use hook.
 *
 * @param entity            The entity index.
 * @param activator         The activator index.
 * @param caller            The caller index.
 * @param use               The use type.
 * @param flValue           The value parameter.
 **/ 
public void BagUseHook(int entity, int activator, int caller, UseType use, float flValue)
{
	static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];
	
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
	
	vPosition[2] += 10.0;
	vVelocity[0] = GetRandomFloat(-360.0, 360.0);
	vVelocity[1] = GetRandomFloat(-360.0, 360.0);
	vVelocity[2] = 10.0 + GetRandomFloat(0.0, 10.0);

	SpawnRandomWeapon(vPosition, vAngle, vVelocity);
	
	int iLeft = GetEntProp(entity, Prop_Data, "m_iHammerID");
	if (iLeft)
	{
		iLeft--;

		SetEntProp(entity, Prop_Data, "m_iHammerID", iLeft);

		SetEntProp(entity, Prop_Send, "m_nBody", LeftToBody(iLeft));
	}
	else
	{
		AcceptEntityInput(entity, "Kill");
	}
}

/**
 * @brief Case damage hook.
 *
 * @param entity            The entity index.    
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action CaseDamageHook(int entity, int &attacker, int &inflictor, float &flDamage, int &iBits)
{
	int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

	if (!iHealth)
	{
		static float vPosition[3]; static float vAngle[3];
						
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
		GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);

		SpawnRandomWeapon(vPosition, vAngle, NULL_VECTOR/*, GetEntProp(entity, Prop_Data, "m_iHammerID"))*/);
		
		SDKUnhook(entity, SDKHook_OnTakeDamage, CaseDamageHook);
	}
	
	return Plugin_Continue;
}

/**
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 **/
/*public Action CaseTransmitHook(int entity, int client)
{
	if (ZP_IsPlayerZombie(client))
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}*/

//**********************************************
//* Item (both) functions.                     *
//**********************************************

/**
 * @brief Main timer for making solid emitter.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
/*public Action EmitterSolidHook(Handle hTimer, int refID)
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
}*/

//**********************************************
//* Item (npc) stocks.                         *
//**********************************************

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
 * @brief Hull filter.
 *
 * @param entity            The entity index.
 * @param hData             The array handle.
 * @return                  True to continue enumerating, otherwise false.
 **/
public bool HullEnumerator(int entity, ArrayList hData)
{
	if (IsPlayerExist(entity))
	{
		TR_ClipCurrentRayToEntity(MASK_ALL, entity);
		if (TR_DidHit()) hData.Push(entity);
	}
		
	return true;
}

/**
 * @brief Transform filling amount to body index.
 * 
 * @param iLeft             The amount which left.        
 * @return                  The skin index.
 **/
stock int LeftToBody(int iLeft)
{
	float flLeft = float(iLeft) / hCvarAirdropWeapons.IntValue;
	if (flLeft > 0.8)      return 0;    
	else if (flLeft > 0.6) return 1;
	else if (flLeft > 0.4) return 2;
	else if (flLeft > 0.2) return 3;
	return 4;   
}

/**
 * @brief Spawn the random weapon.
 *       
 * @param vPosition         The origin of the spawn.
 * @param vAngle            The angle of the spawn.
 * @param vVelocity         The velocity of the spawn.
 **/
stock void SpawnRandomWeapon(float vPosition[3], float vAngle[3], float vVelocity[3])
{
	int iD = FindRandomWeapon();
	if (iD != -1)
	{
		int weapon = ZP_CreateWeapon(iD, vPosition, vAngle);
		
		if (weapon != -1)
		{
			TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vVelocity);
		}
	}
}

/**
 * @brief Find the random id of any custom weapons.
 * 
 * @return                  The weapon id.
 **/
stock int FindRandomWeapon() 
{
	int iSize = ZP_GetNumberWeapon();
	
	int[] weaponID = new int[iSize]; int x;

	for (int i = 0; i < iSize; i++)
	{
		ItemDef iItem = ZP_GetWeaponDefIndex(i);
		if (!IsGun(iItem))
		{
			continue;
		}
		
		if (!ZP_ClassHasType(ZP_GetWeaponTypes(i), gType) || !ZP_IsWeaponDrop(i))
		{
			continue;
		}

		weaponID[x++] = i;
	}
	
	return (x) ? weaponID[GetRandomInt(0, x-1)] : -1;
}