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

// Decal index
int gTrail;

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
#define WEAPON_BEAM_COLOR {174, 56, 139, 255}
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
ConVar hCvarAirdropTrail;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarAirdropGlow       = CreateConVar("zp_weapon_airdrop_glow", "0", "Enable glow ?", 0, true, 0.0, true, 1.0);        
	hCvarAirdropAmount     = CreateConVar("zp_weapon_airdrop_amount", "6", "Amount of drops in heli", 0, true, 0.0);      
	hCvarAirdropHeight     = CreateConVar("zp_weapon_airdrop_height", "700.0", "Drop height spawn", 0, true, 0.0);      
	hCvarAirdropHealth     = CreateConVar("zp_weapon_airdrop_health", "300", "Health of drop", 0, true, 1.0);      
	hCvarAirdropSpeed      = CreateConVar("zp_weapon_airdrop_speed", "175.0", "Initial speed of drop", 0, true, 0.0);       
	hCvarAirdropExplosions = CreateConVar("zp_weapon_airdrop_explosions", "3", "How many c4 needed to open safe", 0, true, 0.0);  
	hCvarAirdropWeapons    = CreateConVar("zp_weapon_airdrop_weapons", "15", "Amount of weapons in the safe bag", 0, true, 0.0);     
	hCvarAirdropSmokeLife  = CreateConVar("zp_weapon_airdrop_smoke_life", "14.0", "", 0, true, 0.0); 
	hCvarAirdropTrail      = CreateConVar("zp_weapon_airdrop_trail", "0", "Attach trail to the projectile?", 0, true, 0.0, true, 1.0);
	
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
		HookEvent("tagrenade_detonate", EventEntityTanade, EventHookMode_Post);
		
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
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);

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
	/*PrecacheSound("survival/breach_activate_nobombs_01.wav", true);
	PrecacheSound("survival/breach_land_01.wav", true);
	PrecacheSound("survival/rocketincoming.wav", true);
	PrecacheSound("survival/rocketalarm.wav", true);
	PrecacheSound("survival/missile_land_01.wav", true);
	PrecacheSound("survival/missile_land_02.wav", true);
	PrecacheSound("survival/missile_land_03.wav", true);
	PrecacheSound("survival/missile_land_04.wav", true);
	PrecacheSound("survival/missile_land_05.wav", true);
	PrecacheSound("survival/missile_land_06.wav", true);*/

	//PrecacheModel("models/f18/f18.mdl", true);
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
	
	if (ZP_GetGameModeTypeHuman(mode) == gType && ZP_GetPlayingAmount() >= ZP_GetWeaponOnline(gWeapon))
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
				
				EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
			}
		}
	}
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
		if (hCvarAirdropTrail.BoolValue)
		{
			TE_SetupBeamFollow(grenade, gTrail, 0, 1.0, 10.0, 10.0, 5, WEAPON_BEAM_COLOR);
			TE_SendToAll();	
		}
		
		ZP_GiveClientWeapon(client, gWeaponC4, false);
	}
}

/**
 * Event callback (tagrenade_detonate)
 * @brief The tagrenade is exployed.
 * 
 * @param hEvent            The event handle.
 * @param sName             The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventEntityTanade(Event hEvent, char[] sName, bool dontBroadcast) 
{
	static float vPosition[3]; static float vAngle[3];

	int grenade = hEvent.GetInt("entityid");
	vPosition[0] = hEvent.GetFloat("x"); 
	vPosition[1] = hEvent.GetFloat("y"); 
	vPosition[2] = hEvent.GetFloat("z");

	if (IsValidEdict(grenade))
	{
		if (GetEntProp(grenade, Prop_Data, "m_iHammerID") == gWeapon)
		{
			vAngle[1] = GetRandomFloat(0.0, 360.0);
		
			float flDuration = hCvarAirdropSmokeLife.FloatValue;
			int smoke = UTIL_CreateSmoke(_, vPosition, vAngle, _, _, _, _, _, _, _, _, _, "255 20 147", "255", "particle/particle_smokegrenade1.vmt", flDuration, flDuration + 3.0);
			
			CreateHelicopter(vPosition, vAngle);
			
			if (smoke != -1)
			{
				EmitSoundToAll("survival/missile_gas_01.wav", smoke, SNDCHAN_STATIC);
			}
			
			AcceptEntityInput(grenade, "Kill");
			
			RequestFrame(EventEntityTanadePost);
		}
	}
	
	return Plugin_Continue;
}

/**
 * Event callback (tagrenade_detonate)
 * @brief The tagrenade was exployed. (Post)
 **/
public void EventEntityTanadePost()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
		{
			SetEntPropFloat(i, Prop_Send, "m_flDetectedByEnemySensorTime", ZP_IsGameModeXRay(ZP_GetCurrentGameMode()) ? (GetGameTime() + 9999.0) : 0.0);
		}
	}
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

		static int iAttach = -1;
		if (iAttach == -1) iAttach = LookupEntityAttachment(entity, "dropped");
		GetEntityAttachment(entity, entity, vPosition, vAngle); 

		ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD); 
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
		
		EmitSoundToAll("survival/dropbigguns.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE);
		
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
		
		static int iAttach = -1;
		if (iAttach == -1) iAttach = LookupEntityAttachment(entity, "dropped");
		GetEntityAttachment(entity, iAttach, vPosition, vAngle);
		
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
						
						EmitSoundToClient(i, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
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
		case 0 : EmitSoundToAll("survival/container_damage_01.wav", entity, SNDCHAN_STATIC);
		case 1 : EmitSoundToAll("survival/container_damage_02.wav", entity, SNDCHAN_STATIC);
		case 2 : EmitSoundToAll("survival/container_damage_03.wav", entity, SNDCHAN_STATIC);
		case 3 : EmitSoundToAll("survival/container_damage_04.wav", entity, SNDCHAN_STATIC);
		case 4 : EmitSoundToAll("survival/container_damage_05.wav", entity, SNDCHAN_STATIC);
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

						static int iAttach = -1;
						if (iAttach == -1) iAttach = LookupEntityAttachment(entity, "door");
						GetEntityAttachment(entity, iAttach, vPosition, vAngle);
						
						SetEntProp(entity, Prop_Send, "m_nBody", 1);
						
						int door = UTIL_CreatePhysics("door", vPosition, vAngle, "models/props_survival/safe/safe_door.mdl", PHYS_FORCESERVERSIDE);
						
						if (door != -1)
						{
							SetEntProp(door, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
							SetEntProp(door, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
						}
						
						int[] clients = new int[MaxClients]; int iTotal = 0;
						
						for (int i = 1; i <= MaxClients; i++)
						{
							if (IsPlayerExist(i) && ZP_IsPlayerHuman(i))
							{
								SetGlobalTransTarget(i);
								PrintHintText(i, "%t", "airdrop bag");
								
								clients[iTotal++] = i;
							}
						}
						
						if (iTotal)
						{
							EmitSound(clients, iTotal, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
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
		case 0 : EmitSoundToAll("survival/container_death_01.wav", entity, SNDCHAN_STATIC);
		case 1 : EmitSoundToAll("survival/container_death_02.wav", entity, SNDCHAN_STATIC);
		case 2 : EmitSoundToAll("survival/container_death_03.wav", entity, SNDCHAN_STATIC);
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
		
		if (!ZP_ClassHasTypeBits(ZP_GetWeaponTypes(i), gType) || !ZP_IsWeaponDrop(i))
		{
			continue;
		}

		weaponID[x++] = i;
	}
	
	return (x) ? weaponID[GetRandomInt(0, x-1)] : -1;
}