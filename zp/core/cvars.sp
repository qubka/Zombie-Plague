/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          cvars.sp
 *  Type:          Main 
 *  Description:   Config creation and cvar control.
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
 
/**
 * @section Sound config data indexes.
 **/
enum
{
	CVARS_DATA_KEY,
	CVARS_DATA_VALUE
};
/**
 * @endsection
 **/
 
/**
 * @section List of cvars used by the plugin.
 **/
enum struct CvarsList
{    
	ConVar DATABASE;
	ConVar ANTISTICK;
	ConVar COSTUMES;
	ConVar EXTRAITEMS;

	ConVar HITGROUP;
	ConVar HITGROUP_KNOCKBACK;
	ConVar HITGROUP_KNOCKBACK_AIR;
	ConVar HITGROUP_FRIENDLY_FIRE;
	ConVar HITGROUP_FRIENDLY_GRENADE;
	ConVar HITGROUP_FRIENDLY_BULLETS;
	ConVar HITGROUP_FRIENDLY_OTHER;
	ConVar HITGROUP_FRIENDLY_SELF;

	ConVar GAMEMODE;
	ConVar GAMEMODE_BLAST_TIME;
	ConVar GAMEMODE_WEAPONS_REMOVE;
	ConVar GAMEMODE_TEAM_BALANCE;
	ConVar GAMEMODE_LIMIT_TEAMS;
	ConVar GAMEMODE_WARMUP_TIME;
	ConVar GAMEMODE_WARMUP_PERIOD;
	ConVar GAMEMODE_ROUNDTIME_ZP;
	ConVar GAMEMODE_ROUNDTIME_CS;
	ConVar GAMEMODE_ROUNDTIME_DE;
	ConVar GAMEMODE_ROUND_RESTART;
	ConVar GAMEMODE_RESTART_DELAY;

	ConVar WEAPON_GIVE_TASER;
	ConVar WEAPON_GIVE_BOMB;
	ConVar WEAPON_DROP_GRENADE;
	ConVar WEAPON_DROP_BREACH;
	ConVar WEAPON_DROP_KNIFE;
	ConVar WEAPON_CT_DEFAULT_GRENADES;
	ConVar WEAPON_CT_DEFAULT_MELEE;
	ConVar WEAPON_CT_DEFAULT_SECONDARY;
	ConVar WEAPON_CT_DEFAULT_PRIMARY;
	ConVar WEAPON_T_DEFAULT_GRENADES;
	ConVar WEAPON_T_DEFAULT_MELEE;
	ConVar WEAPON_T_DEFAULT_SECONDARY;
	ConVar WEAPON_T_DEFAULT_PRIMARY;
	ConVar WEAPON_PICKUP_RANGE;
	ConVar WEAPON_PICKUP_LEVEL;
	ConVar WEAPON_PICKUP_ONLINE;
	ConVar WEAPON_DEFAULT_MELEE;

	ConVar LOG;
	ConVar LOG_MODULE_FILTER;
	ConVar LOG_IGNORE_CONSOLE;
	ConVar LOG_ERROR_OVERRIDE;
	ConVar LOG_PRINT_CHAT;

	ConVar JUMPBOOST;
	ConVar JUMPBOOST_MULTIPLIER;
	ConVar JUMPBOOST_MAX;

	ConVar LEVEL_SYSTEM;
	ConVar LEVEL_HEALTH_RATIO;
	ConVar LEVEL_SPEED_RATIO;
	ConVar LEVEL_GRAVITY_RATIO;
	ConVar LEVEL_DAMAGE_RATIO;
	ConVar LEVEL_HUD;
	ConVar LEVEL_HUD_ZOMBIE_R;
	ConVar LEVEL_HUD_ZOMBIE_G;
	ConVar LEVEL_HUD_ZOMBIE_B;
	ConVar LEVEL_HUD_ZOMBIE_A;
	ConVar LEVEL_HUD_HUMAN_R;
	ConVar LEVEL_HUD_HUMAN_G;
	ConVar LEVEL_HUD_HUMAN_B;
	ConVar LEVEL_HUD_HUMAN_A;
	ConVar LEVEL_HUD_SPECTATOR_R;
	ConVar LEVEL_HUD_SPECTATOR_G;
	ConVar LEVEL_HUD_SPECTATOR_B;
	ConVar LEVEL_HUD_SPECTATOR_A;
	ConVar LEVEL_HUD_X;
	ConVar LEVEL_HUD_Y;

	ConVar ACCOUNT_CASH_AWARD;
	ConVar ACCOUNT_BUY_ANYWHERE;
	ConVar ACCOUNT_BUY_IMMUNITY;
	ConVar ACCOUNT_MONEY;
	ConVar ACCOUNT_CONNECT;
	ConVar ACCOUNT_BET;
	ConVar ACCOUNT_COMMISION;
	ConVar ACCOUNT_DECREASE;
	ConVar ACCOUNT_HUD_R;
	ConVar ACCOUNT_HUD_G;
	ConVar ACCOUNT_HUD_B;
	ConVar ACCOUNT_HUD_A;
	ConVar ACCOUNT_HUD_X;
	ConVar ACCOUNT_HUD_Y;

	ConVar ZTELE_ESCAPE;
	ConVar ZTELE_ZOMBIE;
	ConVar ZTELE_HUMAN;
	ConVar ZTELE_DELAY_ZOMBIE;
	ConVar ZTELE_DELAY_HUMAN;
	ConVar ZTELE_MAX_ZOMBIE;
	ConVar ZTELE_MAX_HUMAN;
	ConVar ZTELE_AUTOCANCEL;
	ConVar ZTELE_AUTOCANCEL_DIST;

	ConVar ZMARKET_BUTTON;
	ConVar ZMARKET_REBUY_MENU;
	ConVar ZMARKET_PISTOL_MENU;
	ConVar ZMARKET_SHOTGUN_MENU;
	ConVar ZMARKET_RIFLE_MENU;
	ConVar ZMARKET_SNIPER_MENU;
	ConVar ZMARKET_MACH_MENU;
	ConVar ZMARKET_KNIFE_MENU;
	ConVar ZMARKET_EQUIP_MENU;
	ConVar ZMARKET_ARSENAL;
	ConVar ZMARKET_RANDOM_WEAPONS;
	ConVar ZMARKET_PRIMARY;
	ConVar ZMARKET_SECONDARY;
	ConVar ZMARKET_MELEE;
	ConVar ZMARKET_ADDITIONAL;

	ConVar VEFFECTS_IMMUNITY_ALPHA;
	ConVar VEFFECTS_HEALTH;
	ConVar VEFFECTS_HEALTH_SPRITE;
	ConVar VEFFECTS_HEALTH_SCALE;
	ConVar VEFFECTS_HEALTH_VAR;
	ConVar VEFFECTS_HEALTH_FRAMES;
	ConVar VEFFECTS_HEALTH_DURATION;
	ConVar VEFFECTS_HEALTH_HEIGHT;
	ConVar VEFFECTS_INFECT;
	ConVar VEFFECTS_INFECT_FADE;
	ConVar VEFFECTS_INFECT_FADE_TIME;
	ConVar VEFFECTS_INFECT_FADE_DURATION;
	ConVar VEFFECTS_INFECT_FADE_R;
	ConVar VEFFECTS_INFECT_FADE_G;
	ConVar VEFFECTS_INFECT_FADE_B;
	ConVar VEFFECTS_INFECT_FADE_A;
	ConVar VEFFECTS_INFECT_SHAKE;
	ConVar VEFFECTS_INFECT_SHAKE_AMP;
	ConVar VEFFECTS_INFECT_SHAKE_FREQUENCY;
	ConVar VEFFECTS_INFECT_SHAKE_DURATION;
	ConVar VEFFECTS_HUMANIZE;
	ConVar VEFFECTS_HUMANIZE_FADE;
	ConVar VEFFECTS_HUMANIZE_FADE_TIME;
	ConVar VEFFECTS_HUMANIZE_FADE_DURATION;
	ConVar VEFFECTS_HUMANIZE_FADE_R;
	ConVar VEFFECTS_HUMANIZE_FADE_G;
	ConVar VEFFECTS_HUMANIZE_FADE_B;
	ConVar VEFFECTS_HUMANIZE_FADE_A;
	ConVar VEFFECTS_RESPAWN;
	ConVar VEFFECTS_RESPAWN_NAME;
	ConVar VEFFECTS_RESPAWN_ATTACH;
	ConVar VEFFECTS_RESPAWN_DURATION;
	ConVar VEFFECTS_HEAL;
	ConVar VEFFECTS_HEAL_NAME;
	ConVar VEFFECTS_HEAL_ATTACH;
	ConVar VEFFECTS_HEAL_DURATION;
	ConVar VEFFECTS_HEAL_FADE;
	ConVar VEFFECTS_HEAL_FADE_TIME;
	ConVar VEFFECTS_HEAL_FADE_DURATION;
	ConVar VEFFECTS_HEAL_FADE_R;
	ConVar VEFFECTS_HEAL_FADE_G;
	ConVar VEFFECTS_HEAL_FADE_B;
	ConVar VEFFECTS_HEAL_FADE_A;
	ConVar VEFFECTS_LEAP;
	ConVar VEFFECTS_LEAP_NAME;
	ConVar VEFFECTS_LEAP_ATTACH;
	ConVar VEFFECTS_LEAP_DURATION;
	ConVar VEFFECTS_LEAP_SHAKE;
	ConVar VEFFECTS_LEAP_SHAKE_AMP;
	ConVar VEFFECTS_LEAP_SHAKE_FREQUENCY;
	ConVar VEFFECTS_LEAP_SHAKE_DURATION;
	ConVar VEFFECTS_LIGHTSTYLE;
	ConVar VEFFECTS_LIGHTSTYLE_VALUE;
	ConVar VEFFECTS_SKY;
	ConVar VEFFECTS_SKYNAME;
	ConVar VEFFECTS_SKY_PATH; 
	ConVar VEFFECTS_SUN_DISABLE;
	ConVar VEFFECTS_FOG;
	ConVar VEFFECTS_FOG_COLOR;
	ConVar VEFFECTS_FOG_DENSITY;
	ConVar VEFFECTS_FOG_STARTDIST;
	ConVar VEFFECTS_FOG_ENDDIST;
	ConVar VEFFECTS_FOG_FARZ;
	ConVar VEFFECTS_RAGDOLL_REMOVE;
	ConVar VEFFECTS_RAGDOLL_DISSOLVE;
	ConVar VEFFECTS_RAGDOLL_DELAY;

	ConVar SEFFECTS_ALLTALK;
	ConVar SEFFECTS_VOICE;
	ConVar SEFFECTS_VOICE_ZOMBIES_MUTE;
	ConVar SEFFECTS_INFECT;
	ConVar SEFFECTS_MOAN;
	ConVar SEFFECTS_GROAN;
	ConVar SEFFECTS_BURN;
	ConVar SEFFECTS_DEATH;
	ConVar SEFFECTS_FOOTSTEPS;
	ConVar SEFFECTS_CLAWS;    
	ConVar SEFFECTS_PLAYER_FLASHLIGHT; 
	ConVar SEFFECTS_PLAYER_NVGS;
	ConVar SEFFECTS_PLAYER_AMMUNITION;  
	ConVar SEFFECTS_PLAYER_LEVEL;       
	ConVar SEFFECTS_ROUND_START;       
	ConVar SEFFECTS_ROUND_COUNT;  
	ConVar SEFFECTS_ROUND_BLAST;

	ConVar MESSAGES_OBJECTIVE;
	ConVar MESSAGES_COUNTER;
	ConVar MESSAGES_BLAST;
	ConVar MESSAGES_DAMAGE;
	ConVar MESSAGES_DONATE;
	ConVar MESSAGES_CLASS_INFO;
	ConVar MESSAGES_CLASS_CHOOSE;
	ConVar MESSAGES_CLASS_DUMP;
	ConVar MESSAGES_ITEM_INFO;
	ConVar MESSAGES_ITEM_ALL;
	ConVar MESSAGES_WEAPON_INFO;
	ConVar MESSAGES_WEAPON_ALL;
	ConVar MESSAGES_WEAPON_DROP;
	ConVar MESSAGES_BLOCK;

	ConVar ICON_INFECT;
	ConVar ICON_HEAD;

	ConVar MENU_BUTTON;
	ConVar SKILL_BUTTON;
	ConVar LIGHT_BUTTON;

	ConVar HUMAN_MENU;
	ConVar ZOMBIE_MENU;

	ConVar SEND_TABLES;
}
/**
 * @endsection
 **/
 
/**
 * Array to store cvar data in.
 **/
CvarsList gCvarList;

/**
 * @brief Cvars module init function.
 **/
void CvarsOnInit(/*void*/)
{
	// Prepare all cvar data
	CvarsOnLoad();
	
	// Forward event to modules
	DataBaseOnCvarInit();
	LogOnCvarInit();
	VEffectsOnCvarInit();
	SoundsOnCvarInit();
	ClassesOnCvarInit();
	WeaponsOnCvarInit();
	GameModesOnCvarInit();
	ExtraItemsOnCvarInit();
	HitGroupsOnCvarInit();
	CostumesOnCvarInit();
	MenusOnCvarInit();

	// Creates revision cvar
	CreateConVar("zombieplague_revision", PLUGIN_VERSION, "Revision number for this plugin in source code repository.", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Adds core tag
	FindConVar("sv_tags").SetString(PLUGIN_TAG, true);
}

/**
 * @brief Prepare all cvar data.
 **/
void CvarsOnLoad(/*void*/)
{
	// Register config file
	ConfigRegisterConfig(File_Cvars, Structure_ArrayList, CONFIG_FILE_ALIAS_CVARS);

	// Gets cvars file path
	static char sPathCvars[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_CVARS, sPathCvars, sizeof(sPathCvars), false);

	// If file doesn't exist, then log and stop
	if (!bExists)
	{
		// Log failure and stop plugin
		SetFailState("Missing cvars file: \"%s\"", sPathCvars);
	}

	// Sets path to the config file
	ConfigSetConfigPath(File_Cvars, sPathCvars);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_Cvars, gServerData.Cvars, PLATFORM_LINE_LENGTH);

	// Unexpected error, stop plugin
	if (!bSuccess)
	{
		SetFailState("Unexpected error encountered loading: \"%s\"", sPathCvars);
	}

	// Now copy data to array structure
	CvarsOnCacheData();

	// Sets config data
	ConfigSetConfigLoaded(File_Cvars, true);
	ConfigSetConfigReloadFunc(File_Cvars, GetFunctionByName(GetMyHandle(), "CvarsOnConfigReload"));
	ConfigSetConfigHandle(File_Cvars, gServerData.Cvars);
}

/**
 * @brief Caches cvar data from file into arrays.
 **/
void CvarsOnCacheData(/*void*/)
{
	// Gets config file path
	static char sPathCvars[PLATFORM_LINE_LENGTH]; static char sValueCvars[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Cvars, sPathCvars, sizeof(sPathCvars));

	// Validate cvar config
	int iCvars = gServerData.Cvars.Length;
	if (!iCvars)
	{
		SetFailState("No usable data found in cvar config file: \"%s\"", sPathCvars);
	}
	
	// i = cvar array index
	for (int i = 0; i < iCvars; i++)
	{
		// Gets array line
		ArrayList arrayCvar = CvarsGetKey(i, sPathCvars, sizeof(sPathCvars), true);

		// Parses a parameter string in key="value" format
		if (ParamParseString(arrayCvar, sPathCvars, sizeof(sPathCvars), ' ') == PARAM_ERROR_NO)
		{
			// Gets cvar key
			arrayCvar.GetString(CVARS_DATA_KEY, sPathCvars, sizeof(sPathCvars));
			
			// Gets cvar value
			arrayCvar.GetString(CVARS_DATA_VALUE, sValueCvars, sizeof(sValueCvars));

			// Creates a new console variable
			CreateConVar(sPathCvars, sValueCvars);
		}
		else
		{
			// Log cvar error info
			SetFailState("Error with parsing of the cvar block: \"%d\" = \"%s\"", i + 1, sPathCvars);
	
			// Remove cvar block from array
			gServerData.Cvars.Erase(i);

			// Subtract one from count
			iCvars--;

			// Backtrack one index, because we deleted it out from under the loop
			i--;
		}
	}
	
	// Destroy all data
	ConfigClearKvArray(gServerData.Cvars);
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void CvarsOnConfigReload(/*void*/)
{
	// Gets config file path
	static char sPathCvars[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Cvars, sPathCvars, sizeof(sPathCvars));

	// If file is exist, then execute
	if (FileExists(sPathCvars))
	{
		// Reloads cvars config
		ServerCommand("exec %s", sPathCvars[4]);
	}
}

/*
 * Cvars data reading API.
 */

/**
 * @brief Gets the key of a cvar list at a given key.
 * 
 * @param iD                The cvar array index.
 * @param sKey              The string to return key in.
 * @param iMaxLen           The lenght of string.
 * @param bDelete           (Optional) Clear the array key position.
 **/
ArrayList CvarsGetKey(int iD, char[] sKey, int iMaxLen, bool bDelete = false)
{
	// Gets array handle of cvar at given index
	ArrayList arrayCvar = gServerData.Cvars.Get(iD);
	
	// Gets cvar key
	arrayCvar.GetString(CVARS_DATA_KEY, sKey, iMaxLen);
	
	// Shifting array value
	if (bDelete) arrayCvar.Erase(CVARS_DATA_KEY);
	
	// Return array list
	return arrayCvar;
}

/*
 * Callback of standart cvars.
 */
 
/**
 * Cvar hook callback.
 * @brief Prevents changes of default cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsLockOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Revert to locked value
	hConVar.IntValue = 0;
}

/**
 * Cvar hook callback.
 * @brief Prevents changes of default cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsUnlockOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Revert to locked value
	hConVar.IntValue = 1;
}

/**
 * Cvar hook callback.
 * @brief Prevents changes of cheat cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsLockOnCvarHook2(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Revert to locked value
	CvarsOnCheatSet(hConVar, 0);
}

/**
 * Cvar hook callback.
 * @brief Prevents changes of default cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsLockOnCvarHook3(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Revert to locked value
	hConVar.SetString("");
}

/*
 * Stocks cvars API.
 */

/**
 * @brief Sets the integer value of a cvar variable. (sv_cheat 1)
 *
 * @param hConVar           Handle to the convar.
 * @param iValue            New integer value.
 **/
void CvarsOnCheatSet(ConVar hConVar, int iValue) 
{
	// Revert to locked value
	hConVar.Flags = (hConVar.Flags & ~FCVAR_CHEAT);
	hConVar.IntValue = iValue;
	//hConVar.Flags = hConVar.Flags | FCVAR_CHEAT;  -> Sent errors to console!
}
