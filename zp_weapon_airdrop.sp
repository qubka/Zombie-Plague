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
	// Initialize cvars
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
	
	// Generate config
	AutoExecConfig(true, "zp_weapon_airdrop", "sourcemod/zombieplague");
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
		// Load translations phrases used by plugin
		LoadTranslations("airdrop.phrases");
		
		// If map loaded, then run custom forward
		if (ZP_IsMapLoaded())
		{
			// Execute it
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Purge timer
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
	// Delete timers
	delete hEmitterCreate[client];
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
	// Weapons
	gWeapon = ZP_GetWeaponNameID("airdrop");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"drone gun\" wasn't find");

	// Sounds
	gSound = ZP_GetSoundKeyID("HELICOPTER_SOUNDS");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HELICOPTER_SOUNDS\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Sounds
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

	// Models
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
	// If addon is unload, then stop
	if (gWeapon == -1)
	{
		return;
	}
	
	// Validate access
	if (ZP_IsGameModeHumanClass(mode, "human") && ZP_GetPlayingAmount() >= ZP_GetWeaponOnline(gWeapon))
	{
		// Gets random index of a human
		int client = ZP_GetRandomHuman();

		// Validate client
		if (client != -1)
		{
			// Validate weapon
			int weapon;
			if ((weapon = ZP_IsPlayerHasWeapon(client, gWeapon)) != -1)
			{
				// Resets variables
				SetEntProp(weapon, Prop_Data, "m_iMaxHealth", STATE_TRIGGER_OFF);
				SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_TRIGGER_OFF);
				SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
			}
			else
			{
				// Give item and select it
				ZP_GiveClientWeapon(client, gWeapon);

				// Show message
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
	// Delete timers
	delete hEmitterCreate[client];
	
	// Cancel mode change
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnIdle(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	// Validate trigger
	if (!bTrigger)
	{
		// Sets idle animation
		ZP_SetWeaponAnimation(client, ANIM_IDLE);
	
		// Sets next idle time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
	}
	else 
	{
		// Sets idle animation
		ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_IDLE_TRIGGER_OFF : ANIM_IDLE_TRIGGER_ON);
		
		// Sets next idle time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE2_TIME);
	}
}

void Weapon_OnDeploy(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	
	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", MAX_FLOAT);

	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
	
	// Sets draw animation
	ZP_SetWeaponAnimation(client, !bTrigger ? ANIM_DRAW : !iStateMode ? ANIM_DRAW_TRIGGER_OFF : ANIM_DRAW_TRIGGER_ON); 
}

void Weapon_OnPrimaryAttack(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	// Validate water
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
	{
		return;
	}

	// Initialize vectors
	static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

	// Validate trigger 
	if (!bTrigger)
	{
		// Gets trace line
		GetClientEyePosition(client, vPosition);
		ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);

		// Create the end-point trace
		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

		// Is hit world ?
		if (TR_DidHit() && TR_GetEntityIndex() < 1)
		{
			// Adds the delay to the game tick
			flCurrentTime += ZP_GetWeaponShoot(gWeapon);
		
			// Sets attack animation
			ZP_SetWeaponAnimation(client, ANIM_SHOOT);  
			
			// Create timer for emitter
			delete hEmitterCreate[client]; /// Bugfix
			hEmitterCreate[client] = CreateTimer(ZP_GetWeaponShoot(gWeapon) - 0.1, Weapon_OnCreateEmitter, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			// Adds the delay to the game tick
			flCurrentTime += 0.1;
		}
	}
	else
	{
		// Adds the delay to the game tick
		flCurrentTime += ZP_GetWeaponReload(gWeapon);

		// Gets controller
		int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity"); 

		// Validate entity
		if (entity != -1)
		{    
			// Gets position/angle
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);

			// Create exp effect
			TE_SetupSparks(vPosition, NULL_VECTOR, 5000, 1000);
			TE_SendToAll();

			// Switch mode
			switch (iStateMode)
			{
				case STATE_TRIGGER_OFF : 
				{
					// Create a smoke
					float flDuration = hCvarAirdropSmokeLife.FloatValue;
					int smoke = UTIL_CreateSmoke(_, vPosition, vAngle, _, _, _, _, _, _, _, _, _, "255 20 147", "255", "particle/particle_smokegrenade1.vmt", flDuration, flDuration + 3.0);
					
					// Sent drop
					CreateHelicopter(vPosition, vAngle);
					
					// Validate entity
					if (smoke != -1)
					{
						// Emit sound
						EmitSoundToAll("survival/missile_gas_01.wav", smoke, SNDCHAN_STATIC, SNDLEVEL_HOME);
					}
				}
				
				case STATE_TRIGGER_ON : 
				{
					// Start bombarding
					CreateJet(vPosition, vAngle);
					
					// Emit sound
					EmitSoundToAll("survival/rocketalarm.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
				}
			}
			
			// Remove the entity from the world
			AcceptEntityInput(entity, "Kill");
		}
		
		// Sets attack animation
		ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_SHOOT_TRIGGER_OFF : ANIM_SHOOT_TRIGGER_ON);  
		
		// Remove trigger
		CreateTimer(0.99, Weapon_OnRemove, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
}

void Weapon_OnSecondaryAttack(int client, int weapon, int bTrigger, int iStateMode, float flCurrentTime)
{
	// Validate trigger
	if (!bTrigger)
	{
		return;
	}
	
	// Validate animation delay
	if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
	{
		return;
	}

	// Sets change animation
	ZP_SetWeaponAnimation(client, !iStateMode ? ANIM_SWITCH_TRIGGER_ON : ANIM_SWITCH_TRIGGER_OFF);
	
	// Adds the delay to the game tick
	flCurrentTime += WEAPON_SWITCH_TIME;

	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);   
	
	// Remove the delay to the game tick
	flCurrentTime -= 0.5;
	
	// Sets switching time
	SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
	
	// Show message
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
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID); int weapon;

	// Clear timer 
	hEmitterCreate[client] = null;

	// Validate client
	if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
	{
		 // Initialize vectors
		static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

		// Gets trace line
		GetClientEyePosition(client, vPosition);
		ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);

		// Create the end-point trace
		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

		// Is hit world ?
		if (TR_DidHit() && TR_GetEntityIndex() < 1)
		{
			// Returns the collision position/normal of a trace result
			TR_GetEndPosition(vPosition);
			TR_GetPlaneNormal(null, vAngle); 
			
			// Gets model
			static char sModel[PLATFORM_LINE_LENGTH];
			ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
			
			// Create mine
			int entity = UTIL_CreatePhysics("emitter", vPosition, vAngle, sModel, PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);
			
			// Validate entity
			if (entity != -1)
			{
				// Sets physics
				SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
				SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
				
				// Sets owner to the entity
				SetEntPropEnt(entity, Prop_Data, "m_pParent", client);
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
				
				// Emit sound
				EmitSoundToAll("survival/breach_land_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_WHISPER);
				
				// Create solid hook
				//CreateTimer(0.1, EmitterSolidHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
			
			// Sets trigger mode
			SetEntProp(weapon, Prop_Data, "m_iHealth", STATE_TRIGGER_ON);

			// Sets pickup animation
			ZP_SetWeaponAnimation(client, ANIM_DRAW_TRIGGER_OFF);
		}
		else
		{
			// Sets pickup animation
			ZP_SetWeaponAnimation(client, ANIM_DRAW);
		}

		// Adds the delay to the game tick
		float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon);
		
		// Sets next attack time
		SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
		SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    
	}
	
	// Destroy timer
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
	// Gets entity index from reference key
	int weapon = EntRefToEntIndex(refID);

	// Validate entity
	if (weapon != -1)
	{
		// Gets active user
		int client = GetEntPropEnt(weapon, Prop_Send, "m_hOwner");

		// Validate client
		if (IsPlayerExist(client, false))
		{
			// Forces a player to remove weapon
			ZP_RemoveWeapon(client, weapon);
		}
		else
		{
			AcceptEntityInput(weapon, "Kill");
		}
	}
	
	// Destroy timer
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
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int client, int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Resets variables
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
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Call event
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
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Call event
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
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Time to apply new mode
		static float flApplyModeTime;
		if ((flApplyModeTime = GetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
		{
			// Sets switching time
			SetEntPropFloat(weapon, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

			// Sets different mode
			SetEntProp(weapon, Prop_Data, "m_iMaxHealth", !GetEntProp(weapon, Prop_Data, "m_iMaxHealth"));
			
			// Emit sound
			EmitSoundToAll("survival/breach_activate_nobombs_01.wav", client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
		}
	
		// Button primary attack press
		if (iButtons & IN_ATTACK)
		{
			// Call event
			_call.PrimaryAttack(client, weapon); 
			iButtons &= (~IN_ATTACK);
			return Plugin_Changed;
		}
		// Button secondary attack press
		else if (iButtons & IN_ATTACK2)
		{
			// Call event
			_call.SecondaryAttack(client, weapon);
			iButtons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
		
		// Call event
		_call.Idle(client, weapon);
	}

	// Allow button
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
	// Add to the position
	vPosition[2] += hCvarBombardingHeight.FloatValue;

	// Gets world size
	static float vMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
	
	// Validate world size
	float vMax = vMaxs[2] - 100.0;
	if (vPosition[2] > vMax) vPosition[2] = vMax; 
	
	// Randomize animation
	//static char sAnim[SMALL_LINE_LENGTH];
	//FormatEx(sAnim, sizeof(sAnim), "flyby%i", GetRandomInt(1, 5));

	// Create a model entity
	int entity = UTIL_CreateDynamic("f18", vPosition, vAngle, "models/f18/f18.mdl", "flyby1", false);
	
	// Validate entity
	if (entity != -1)
	{
		// Create thinks
		CreateTimer(2.7, JetBombHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);

		// Kill entity after delay
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
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Emit sound
		EmitSoundToAll("survival/rocketincoming.wav", entity, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);

		// Initialize vectors
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];

		// Gets position/angle
		ZP_GetAttachment(entity, "sound_maker", vPosition, vAngle); vAngle[0] += 180.0;
		
		// Create a bomb entity
		entity = UTIL_CreateProjectile(vPosition, vAngle, "models/player/custom_player/zombie/bomb/bomb.mdl");

		// Validate entity
		if (entity != -1)
		{
			// Correct angle
			vAngle[0] -= 90.0;//45.0;
	
			// Returns vectors in the direction of an angle
			GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);

			// Normalize the vector (equal magnitude at varying distances)
			NormalizeVector(vVelocity, vVelocity);

			// Apply the magnitude by scaling the vector
			ScaleVector(vVelocity, hCvarBombardingSpeed.FloatValue);
	
			// Push the bomb
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
			
			 // Sets physics
			SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01);

			// Create touch hook
			SDKHook(entity, SDKHook_Touch, BombTouchHook);
		}
	}
	
	// Destroy timer
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
	// Gets entity position
	static float vPosition[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

	// Create an explosion effect
	UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500", 2.0);
	UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500_fallback", 2.0);
	
	// Gets bombarding radius
	float flRadius = hCvarBombardingRadius.FloatValue;
	
	// Find any players in the radius
	int i; int it = 1; /// iterator
	while ((i = ZP_FindPlayerInSphere(it, vPosition, flRadius)) != -1)
	{
		// Skip humans
		if (ZP_IsPlayerHuman(i))
		{
			continue;
		}
		
		// Forces a player to commit suicide
		ForcePlayerSuicide(i);
	}
	
	// Emit sound
	switch (GetRandomInt(0, 5))
	{
		case 0 : EmitSoundToAll("survival/missile_land_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 1 : EmitSoundToAll("survival/missile_land_02.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 2 : EmitSoundToAll("survival/missile_land_03.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 3 : EmitSoundToAll("survival/missile_land_04.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 4 : EmitSoundToAll("survival/missile_land_05.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
		case 5 : EmitSoundToAll("survival/missile_land_06.wav", entity, SNDCHAN_STATIC, SNDLEVEL_ROCKET);
	}

	// Remove the entity from the world
	AcceptEntityInput(entity, "Kill");
	
	// Allow event
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
	// Add to the position
	vPosition[2] += hCvarAirdropHeight.FloatValue;
	
	// Gets world size
	static float vMaxs[3];
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
	
	// Validate world size
	float vMax = vMaxs[2] - 100.0;
	if (vPosition[2] > vMax) vPosition[2] = vMax; 
	
	// Create a model entity
	int entity = UTIL_CreateDynamic("helicopter", vPosition, vAngle, "models/buildables/helicopter_rescue_fix.mdl", "helicopter_coop_hostagepickup_flyin", false);
	
	// Validate entity
	if (entity != -1)
	{
		// Create thinks
		CreateTimer(20.0, HelicopterStopHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.41, HelicopterSoundHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
		// Sets main parameters
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
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Sets idle
		SetVariantString("helicopter_coop_hostagepickup_idle");
		AcceptEntityInput(entity, "SetAnimation");
		
		// Sets idle
		CreateTimer(5.0, HelicopterIdleHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Destroy timer
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
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3];

		// Gets position/angle
		ZP_GetAttachment(entity, "dropped", vPosition, vAngle); 

		// Play sound
		ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER); 
	}
	else
	{
		// Destroy timer
		return Plugin_Stop;
	}
	
	// Allow timer
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
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Sets idle
		SetVariantString("helicopter_coop_towerhover_idle");
		AcceptEntityInput(entity, "SetAnimation");
		
		// Emit sound
		EmitSoundToAll("survival/dropbigguns.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_FRIDGE);
		
		// Drops additional random staff
		CreateTimer(1.0, HelicopterDropHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		
		// Sets flying
		CreateTimer(6.6, HelicopterRemoveHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Destroy timer
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
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Validate cases
		int iLeft = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		if (iLeft)
		{
			// Reduce amount
			iLeft--;
			
			// Sets new amount
			SetEntProp(entity, Prop_Data, "m_iMaxHealth", iLeft);
		}
		else
		{
			// Destroy timer
			return Plugin_Stop;
		}

		// Initialize vectors
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];
		
		// Gets position/angle
		ZP_GetAttachment(entity, "dropped", vPosition, vAngle);
		
		// Gets drop type
		int iType = GetEntProp(entity, Prop_Data, "m_iHammerID"); int drop; int iCollision; int iDamage; int iHealth = hCvarAirdropHealth.IntValue;
		switch (iType)
		{
			case SAFE :
			{
				// Create safe
				drop = UTIL_CreatePhysics("safe", vPosition, NULL_VECTOR, "models/buildables/safe.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR | PHYS_GENERATEUSE);
				
				// Validate entity
				if (drop != -1)
				{
					// Sets physics
					iCollision = COLLISION_GROUP_PLAYER;
					iDamage = DAMAGE_EVENTS_ONLY;

					// Create damage/use hook
					SDKHook(drop, SDKHook_UsePost, SafeUseHook);
					SDKHook(drop, SDKHook_OnTakeDamage, SafeDamageHook);
				}
				
				// i = client index
				for (int i = 1; i <= MaxClients; i++)
				{
					// Validate human
					if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
					{
						// Show message
						SetGlobalTransTarget(i);
						PrintHintText(i, "%t", "airdrop safe", hCvarAirdropExplosions.IntValue);
					}
				}
			}
			
			default :
			{
				// Gets model path
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

				// Create case
				drop = UTIL_CreatePhysics("case", vPosition, NULL_VECTOR, sModel, PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
				
				// Validate entity
				if (drop != -1)
				{
					// Sets physics
					iCollision = COLLISION_GROUP_WEAPON;
					iDamage = DAMAGE_YES;

					// Create damage hook
					SDKHook(drop, SDKHook_OnTakeDamage, CaseDamageHook);
					
					// Validate glow
					if (hCvarAirdropGlow.BoolValue)
					{
						// Create a prop_dynamic_override entity
						int glow = UTIL_CreateDynamic("glow", vPosition, NULL_VECTOR, sModel, "ref");

						// Validate entity
						if (glow != -1)
						{
							// Sets parent to the entity
							SetVariantString("!activator");
							AcceptEntityInput(glow, "SetParent", drop, glow);

							// Sets glowing mode
							UTIL_CreateGlowing(glow, true, _, vColor[0], vColor[1], vColor[2], vColor[3]);
							
							// Create transmit hook
							///SDKHook(glow, SDKHook_SetTransmit, CaseTransmitHook);
						}
					}
				}
				
				// Randomize yaw a bit 
				vAngle[0] = GetRandomFloat(-45.0, 45.0);
			}
		}

		// Randomize the drop types (except safe)
		SetEntProp(entity, Prop_Data, "m_iHammerID", GetRandomInt(EXPL, HTOOL));
		
		// Validate entity
		if (drop != -1)
		{
			// Returns vectors in the direction of an angle
			GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
			
			// Normalize the vector (equal magnitude at varying distances)
			NormalizeVector(vVelocity, vVelocity);
			
			// Apply the magnitude by scaling the vector
			ScaleVector(vVelocity, hCvarAirdropSpeed.FloatValue);
		
			// Push the entity 
			TeleportEntity(drop, NULL_VECTOR, NULL_VECTOR, vVelocity);
			
			// Sets physics
			SetEntProp(drop, Prop_Data, "m_CollisionGroup", iCollision);
			SetEntProp(drop, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
			SetEntPropFloat(drop, Prop_Data, "m_flElasticity", 0.01);
			
			// Sets health
			SetEntProp(drop, Prop_Data, "m_takedamage", iDamage);
			SetEntProp(drop, Prop_Data, "m_iHealth", iHealth);
			SetEntProp(drop, Prop_Data, "m_iMaxHealth", iHealth);
			
			// Sets type
			SetEntProp(drop, Prop_Data, "m_iHammerID", iType);
		}
	}
	else
	{
		// Destroy timer
		return Plugin_Stop;
	}
	
	// Allow timer
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
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Sets idle
		SetVariantString("helicopter_coop_towerhover_flyaway");
		AcceptEntityInput(entity, "SetAnimation");
		
		// Kill entity after delay
		UTIL_RemoveEntity(entity, 8.3);
	}
	
	// Destroy timer
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
	// If safe open, then kill
	if (GetEntProp(entity, Prop_Send, "m_nBody"))
	{
		// Call death
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
	// Emit sound
	switch (GetRandomInt(0, 4))
	{
		case 0 : EmitSoundToAll("survival/container_damage_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_WHISPER);
		case 1 : EmitSoundToAll("survival/container_damage_02.wav", entity, SNDCHAN_STATIC, SNDLEVEL_WHISPER);
		case 2 : EmitSoundToAll("survival/container_damage_03.wav", entity, SNDCHAN_STATIC, SNDLEVEL_WHISPER);
		case 3 : EmitSoundToAll("survival/container_damage_04.wav", entity, SNDCHAN_STATIC, SNDLEVEL_WHISPER);
		case 4 : EmitSoundToAll("survival/container_damage_05.wav", entity, SNDCHAN_STATIC, SNDLEVEL_WHISPER);
	}
	
	// Validate mode
	if (GetEntProp(entity, Prop_Send, "m_nBody"))
	{
		// Calculate the damage
		int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

		// Destroy entity
		if (!iHealth)
		{   
			// Call death
			SafeExpload(entity);
		}
		else
		{
			// Apply damage
			SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
		}
	}
	else
	{
		// Entity was damaged by 'explosion'
		if (iBits & DMG_BLAST)
		{
			// Validate inflicter
			if (IsValidEdict(inflictor))
			{
				// Gets weapon classname
				static char sClassname[SMALL_LINE_LENGTH];
				GetEdictClassname(inflictor, sClassname, sizeof(sClassname));

				// Validate c4 projectile
				if (!strncmp(sClassname, "brea", 4, false))
				{
					// Increment explosions
					int iExp = GetEntProp(entity, Prop_Data, "m_iHammerID") + 1;
					SetEntProp(entity, Prop_Data, "m_iHammerID", iExp);
			
					// Validate explosions
					if (iExp >= hCvarAirdropExplosions.IntValue)
					{
						// Initialize vectors
						static float vPosition[3]; static float vAngle[3]; 
						
						// Gets position/angle
						GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
						GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
						
						// Create bag
						int bag = UTIL_CreatePhysics("bag", vPosition, vAngle, "models/props_survival/cash/dufflebag.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR | PHYS_GENERATEUSE);
						
						// Validate entity
						if (bag != -1)
						{
							// Sets physics
							SetEntProp(bag, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
							SetEntProp(bag, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);

							// Sets health
							SetEntProp(bag, Prop_Data, "m_takedamage", DAMAGE_NO);
							
							// Sets weapon amount
							SetEntProp(bag, Prop_Data, "m_iHammerID", hCvarAirdropWeapons.IntValue);
							
							// Create use hook
							SDKHook(bag, SDKHook_UsePost, BagUseHook);
						}

						// Gets position/angle
						ZP_GetAttachment(entity, "door", vPosition, vAngle);
						
						// Open door
						SetEntProp(entity, Prop_Send, "m_nBody", 1);
						
						// Create door
						int door = UTIL_CreatePhysics("door", vPosition, vAngle, "models/props_survival/safe/safe_door.mdl", PHYS_FORCESERVERSIDE);
						
						// Validate entity
						if (door != -1)
						{
							// Sets physics
							SetEntProp(door, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
							SetEntProp(door, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
						}
						
						// i = client index
						for (int i = 1; i <= MaxClients; i++)
						{
							// Validate human
							if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
							{
								// Show message
								SetGlobalTransTarget(i);
								PrintHintTextToAll("%t", "airdrop bag");
							}
						}
					}
				}
			}
		}
	}
	
	// Return on success
	return Plugin_Handled;
}

/**
 * @brief Exploade safe.
 * 
 * @param entity            The entity index.                    
 **/
void SafeExpload(int entity)
{
	// Destroy damage hook
	SDKUnhook(entity, SDKHook_OnTakeDamage, SafeDamageHook);

	// Initialize vectors
	static float vGib[3]; float vShoot[3];
	
	// Create a breaked drone effect
	static char sBuffer[SMALL_LINE_LENGTH];
	for (int x = 0; x <= 4; x++)
	{
		// Find gib positions
		vShoot[1] += 72.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
		{
			case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib1.mdl");
			case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib2.mdl");
			case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib3.mdl");
			case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib4.mdl");
			case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib5.mdl");
		}

		// Create gibs
		UTIL_CreateShooter(entity, "forward", _, MAT_METAL, _, sBuffer, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
	}
	
	// Emit sound
	switch (GetRandomInt(0, 2))
	{
		case 0 : EmitSoundToAll("survival/container_death_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
		case 1 : EmitSoundToAll("survival/container_death_02.wav", entity, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
		case 2 : EmitSoundToAll("survival/container_death_03.wav", entity, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
	}

	// Kill after some duration
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
	// Initialize vectors
	static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];
	
	// Gets entity position
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
	
	// Randomize a bit
	vPosition[2] += 10.0;
	vVelocity[0] = GetRandomFloat(-360.0, 360.0);
	vVelocity[1] = GetRandomFloat(-360.0, 360.0);
	vVelocity[2] = 10.0 + GetRandomFloat(0.0, 10.0);

	// Create random weapon
	SpawnRandomWeapon(vPosition, vAngle, vVelocity);
	
	// Validate weapons
	int iLeft = GetEntProp(entity, Prop_Data, "m_iHammerID");
	if (iLeft)
	{
		// Reduce amount
		iLeft--;

		// Sets new amount
		SetEntProp(entity, Prop_Data, "m_iHammerID", iLeft);

		// Sets filling status
		SetEntProp(entity, Prop_Send, "m_nBody", LeftToBody(iLeft));
	}
	else
	{
		// Destroy!
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
	// Calculate the damage
	int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

	// Validate death
	if (!iHealth)
	{
		// Initialize vectors
		static float vPosition[3]; static float vAngle[3];
						
		// Gets entity position
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
		GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);

		// Create random weapon
		SpawnRandomWeapon(vPosition, vAngle, NULL_VECTOR, TypeToSlot(GetEntProp(entity, Prop_Data, "m_iHammerID")));
		
		// Remove damage hook
		SDKUnhook(entity, SDKHook_OnTakeDamage, CaseDamageHook);
	}
	
	// Allow event
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
	// Validate zombie
	if (ZP_IsPlayerZombie(client))
	{
		// Block transmitting
		return Plugin_Handled;
	}

	// Allow transmitting
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
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Gets entity position
		static float vPosition[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

		// Initialize the hull vectors
		static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
		static const float vMaxs[3] = {  20.0,  20.0, 20.0  }; 
		
		// Create array of entities
		ArrayList hList = new ArrayList();
		
		// Create the hull trace
		TR_EnumerateEntitiesHull(vPosition, vPosition, vMins, vMaxs, false, HullEnumerator, hList);

		// Is hit world only ?
		if (!hList.Length)
		{
			// Sets physics
			SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
			
			// Destroy timer
			delete hList;
			return Plugin_Stop;
		}
		
		// Delete list
		delete hList;
	}
	else
	{
		// Destroy timer
		return Plugin_Stop;
	}
	
	// Allow timer
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
	// Validate player
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
	// Calculate left percentage
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
 * @param mSlot             (Optional) The slot index selected.
 **/
stock void SpawnRandomWeapon(float vPosition[3], float vAngle[3], float vVelocity[3], MenuType mSlot = MenuType_Invalid)
{
	// Valdiate random weapon id
	int iD = FindRandomWeapon(mSlot);
	if (iD != -1)
	{
		// Create a random weapon entity
		int weapon = ZP_CreateWeapon(iD, vPosition, vAngle);
		
		// Validate entity
		if (weapon != -1)
		{
			// Push the entity
			TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vVelocity);
		}
	}
}

/**
 * @brief Find the random id of any custom weapons.
 *       
 * @param mSlot             (Optional) The slot index selected.
 * @return                  The weapon id.
 **/
stock int FindRandomWeapon(MenuType mSlot = MenuType_Invalid) 
{
	// Initialize name char
	static char sClassname[SMALL_LINE_LENGTH];
	
	// Gets total amount of weapons
	int iSize = ZP_GetNumberWeapon();
	
	// Dynamicly allocate array
	int[] weaponID = new int[iSize]; int x;
	
	// Validate all types
	if (mSlot == MenuType_Invalid)
	{
		// i = weapon id 
		for (int i = 0; i < iSize; i++)
		{
			// Validate class/drop/slot
			ZP_GetWeaponClass(i, sClassname, sizeof(sClassname));
			if (StrContains(sClassname, "human", false) == -1 || !ZP_IsWeaponDrop(i))
			{
				continue;
			}

			// Validate def index
			ItemDef iItem = ZP_GetWeaponDefIndex(i);
			if (IsItem(iItem) || iItem == ItemDef_Fists)
			{
				continue;
			}
			
			// Append to list
			weaponID[x++] = i;
		}
	}
	else
	{
		// i = weapon id 
		for (int i = 0; i < iSize; i++)
		{
			// Validate class/drop/slot
			ZP_GetWeaponClass(i, sClassname, sizeof(sClassname));
			if (StrContains(sClassname, "human", false) == -1 || !ZP_IsWeaponDrop(i) || ZP_GetWeaponSlot(i) != mSlot)
			{
				continue;
			}

			// Validate def index
			ItemDef iItem = ZP_GetWeaponDefIndex(i);
			if (IsItem(iItem) || iItem == ItemDef_Fists)
			{
				continue;
			}
			
			// Append to list
			weaponID[x++] = i;
		}
	}
	
	// Return on success
	return (x) ? weaponID[GetRandomInt(0, x-1)] : -1;
}

/**
 * @brief Convert the type index to the menu slot.
 *       
 * @param iType             The type index.
 * @return                  The menu slot.
 **/
stock MenuType TypeToSlot(int iType)
{
	switch (iType)
	{
		case EXPL   : return MenuType_Shotguns;
		case HEAVY  : return MenuType_Machineguns;
		case LIGHT  : return MenuType_Rifles;
		case PISTOL : return MenuType_Pistols;
		case HPIST  : return MenuType_Snipers;
		case TOOLS  : return MenuType_Knifes;
		case HTOOL  : return MenuType_Invalid;
	}
	return MenuType_Invalid;
			
}