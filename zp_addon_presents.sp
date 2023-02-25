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
	name            = "[ZP] Addon: Presents",
	author          = "qubka (Nikita Ushakov), Pelipoika",     
	description     = "Spawns presents on the map that give some bonuses",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

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

// Timer index
Handle hPresentSpawn = null; ArrayList hPosition; bool bLoad; int gCaseCount;

// Type index
int gType;

// Sound index
int gSound;
 
// Cvars
ConVar hCvarPresentGlow;
ConVar hCvarPresentMax;
ConVar hCvarPresentHealth;
ConVar hCvarPresentDelay;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarPresentGlow   = CreateConVar("zp_presents_glow", "0", "Enable glow effect", 0, true, 0.0, true, 1.0);
	hCvarPresentMax    = CreateConVar("zp_presents_max", "6", "Maximum amount of presents on map", 0, true, 1.0);
	hCvarPresentHealth = CreateConVar("zp_presents_health", "0", "Health of present. If disabled will be pickup on touch", 0, true, 0.0);
	hCvarPresentDelay  = CreateConVar("zp_presents_delay", "60.0", "Delay between presents spawn", 0, true, 0.0);
	
	AutoExecConfig(true, "zp_addon_presents", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		hPosition = new ArrayList(3);
		
		LoadTranslations("presents.phrases");
		
		HookEvent("round_prestart", RoundStateHook, EventHookMode_Pre);
		HookEvent("round_end", RoundStateHook, EventHookMode_Pre);
		
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
	gSound = ZP_GetSoundKeyID("present_sounds");
	if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"present_sounds\" wasn't find");
	
	gType = ZP_GetClassTypeID("human");
	if (gType == -1) SetFailState("[ZP] Custom class type ID from name : \"human\" wasn't find");
}

/**
 * @brief The map is loading.
 **/
public void OnMapStart()
{
	GameData hConfig = LoadGameConfigFile("plugin.presents");

	if (!hConfig) 
	{
		SetFailState("Failed to load presents gamedata.");
		return;
	}

	Address TheNavAreas = hConfig.GetAddress("TheNavAreas");

	if (TheNavAreas == Address_Null) SetFailState("Failed to get address: \"TheNavAreas\". Update address in \"plugin.presents\"");    

	int TheNavAreas_Count = view_as<int>(hConfig.GetAddress("TheNavAreas::Count"));
	if (TheNavAreas_Count <= 0)
	{
		PrintToServer("[ZP] Addon: Presents = unloaded on the current map. Generate \"nav_mesh\" to make it work!");
		
		bLoad = false;
		
		delete hConfig;
		return;
	}

	delete hConfig;
	
	hPosition.Clear();
	
	for (int i = 0; i < TheNavAreas_Count; ++i)
	{
		Address pNavArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(i * 4), NumberType_Int32));
		if (pNavArea != Address_Null)
		{
			static float nwCorner[3]; static float seCorner[3]; static float vCenter[3];
	
			nwCorner[0] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(4), NumberType_Int32));
			nwCorner[1] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(8), NumberType_Int32));
			nwCorner[2] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(12), NumberType_Int32));

			seCorner[0] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(16), NumberType_Int32));
			seCorner[1] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(20), NumberType_Int32));
			seCorner[2] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(24), NumberType_Int32));
			
			if ((seCorner[0] - nwCorner[0]) <= 50.0 || (seCorner[1] - nwCorner[1]) <= 50.0)
			{
				continue;
			}

			AddVectors(nwCorner, seCorner, vCenter);
			ScaleVector(vCenter, 0.5);

			hPosition.PushArray(vCenter, sizeof(vCenter));
		}
	}
	
	int iSize = hPosition.Length;
	if (!iSize)
	{
		bLoad = false;
		return;
	}
	
	bLoad = true;

	PrecacheSound("survival/container_death_01.wav", true);
	PrecacheSound("survival/container_death_02.wav", true);
	PrecacheSound("survival/container_death_03.wav", true);
	PrecacheSound("survival/container_damage_01.wav", true);
	PrecacheSound("survival/container_damage_02.wav", true);
	PrecacheSound("survival/container_damage_03.wav", true);
	PrecacheSound("survival/container_damage_04.wav", true);
	PrecacheSound("survival/container_damage_05.wav", true);
	
	PrecacheModel("models/props_survival/cases/case_explosive.mdl", true);
	PrecacheModel("models/props_survival/cases/case_heavy_weapon.mdl", true);
	PrecacheModel("models/props_survival/cases/case_light_weapon.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol.mdl", true);
	PrecacheModel("models/props_survival/cases/case_pistol_heavy.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools.mdl", true);
	PrecacheModel("models/props_survival/cases/case_tools_heavy.mdl", true);
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
 * @brief The map is ending.
 **/
public void OnMapEnd()
{
	hPresentSpawn = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
}

/**
 * @brief Called after a zombie round is started.
 *
 * @param mode              The mode index. 
 **/
public void ZP_OnGameModeStart(int mode)
{
	if (!bLoad)
	{
		return;
	}
	
	if (ZP_GetGameModeTypeHuman(mode) == gType)
	{
		delete hPresentSpawn;
		hPresentSpawn = CreateTimer(hCvarPresentDelay.FloatValue, CaseSpawnHook, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * Event callback (round_prestart, round_end)
 * @brief The round is starting/ending.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action RoundStateHook(Event hEvent, char[] sName, bool dontBroadcast) 
{
	gCaseCount = 0;
	
	delete hPresentSpawn;
	
	return Plugin_Continue;
}

/**
 * @brief Timer for spawing presents.
 *
 * @param hTimer            The timer handle.
 **/
public Action CaseSpawnHook(Handle hTimer)
{
	int iAmount = hCvarPresentMax.IntValue - gCaseCount;
	if (!iAmount)
	{
		return Plugin_Continue;
	}
	
	for (int i = 0; i < iAmount; i++)
	{
		static float vPosition[3];
		if (!FindRandomPosition(vPosition))
		{
			iAmount++;
			continue;
		}

		static char sModel[PLATFORM_LINE_LENGTH]; int iType = GetRandomInt(EXPL, HTOOL); 
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

		int iHealth = hCvarPresentHealth.IntValue;
		int iFlags = PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR;
		if (iHealth <= 0) 
		{
			iFlags |= PHYS_MOTIONDISABLED;
		}
		
		int drop = UTIL_CreatePhysics("present", vPosition, NULL_VECTOR, sModel, iFlags);
		
		if (drop != -1)
		{
			// TODO: Spawn using case type
			///SetEntProp(drop, Prop_Data, "m_iHammerID", iType);
			
			if (iHealth > 0)
			{
				SetEntProp(drop, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
				SetEntProp(drop, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
				SetEntPropFloat(drop, Prop_Data, "m_flElasticity", 0.01);

				SetEntProp(drop, Prop_Data, "m_takedamage", DAMAGE_YES);
				SetEntProp(drop, Prop_Data, "m_iHealth", iHealth);
				SetEntProp(drop, Prop_Data, "m_iMaxHealth", iHealth);

				SDKHook(drop, SDKHook_OnTakeDamage, CaseDamageHook);
			}
			else
			{
				SetEntProp(drop, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
				SetEntProp(drop, Prop_Data, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); /// Make trigger
				SetEntProp(drop, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
				
				SetEntProp(drop, Prop_Data, "m_takedamage", DAMAGE_NO);
				
				SDKHook(drop, SDKHook_Touch, CaseTouchHook);
			}
			
			if (hCvarPresentGlow.BoolValue)
			{		
				int glow = UTIL_CreateGlowing("glow", vPosition, NULL_VECTOR, sModel, "ref", _, _, vColor);

				if (glow != -1)
				{
					SetVariantString("!activator");
					AcceptEntityInput(glow, "SetParent", drop, glow);
				}
			}
		}
		
		gCaseCount++;
	}
	
	int[] clients = new int[MaxClients]; int iTotal = 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			if (ZP_IsPlayerHuman(i))
			{
				SetGlobalTransTarget(i);
				PrintHintText(i, "%t", "present arrived");
				
				clients[iTotal++] = i;
			}
		}
	}
	
	if (iTotal)
	{
		EmitSound(clients, iTotal, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
	}
	
	ZP_EmitSoundToAll(gSound, 1, SOUND_FROM_PLAYER, SNDCHAN_STATIC, true, false);
	
	return Plugin_Continue;
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

		SpawnRandomWeapon(vPosition, vAngle, NULL_VECTOR, gType);
		
		SDKUnhook(entity, SDKHook_OnTakeDamage, CaseDamageHook);
				
		gCaseCount--;
	}
	
	return Plugin_Continue;
}

/**
 * @brief Case touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action CaseTouchHook(int entity, int target)
{
	if (IsClientValid(target))
	{
		if (ZP_IsPlayerHuman(target))
		{
			static float vPosition[3]; static float vAngle[3];
							
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);

			SpawnRandomWeapon(vPosition, vAngle, NULL_VECTOR, gType);

			AcceptEntityInput(entity, "Kill");
		}
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
//* Item (npc) stocks.                         *
//**********************************************

/**
 * @brief Find the random position from the navigation mesh.
 *       
 * @param vPosition         (Optional) The position output.
 * @return                  True on no colission, false otherwise.
 **/
stock bool FindRandomPosition(float vPosition[3])
{
	hPosition.GetArray(GetRandomInt(0, hPosition.Length - 1), vPosition, sizeof(vPosition));

	static float vCenter[3]; vCenter = vPosition;
		
	static const float vMins[3] = { -30.0, -30.0, 0.0   }; 
	static const float vMaxs[3] = {  30.0,  30.0, 30.0  }; 
	
	vCenter[2] += vMaxs[2] / 2.0; /// Move center of hull upward
	TR_TraceHull(vCenter, vCenter, vMins, vMaxs, MASK_SOLID);
	
	return !TR_DidHit();
}