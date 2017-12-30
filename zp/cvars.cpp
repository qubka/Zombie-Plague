/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          cvars.cpp
 *  Type:          Main 
 *  Description:   Config creation and cvar control.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland  Dublin)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation  either version 3 of the License  or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful 
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not  see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/
 
/**
 * Number of max rounds during map.
 **/
#define CvarsRoundMax 15
 
/**
 * List of cvars used by the plugin.
 **/
enum CvarsList
{
	ConVar:CVAR_SERVER_OCCULUSE,
	ConVar:CVAR_SERVER_CLAMP,
	ConVar:CVAR_SERVER_TEAM_BALANCE,
	ConVar:CVAR_SERVER_LIMIT_TEAMS,
	ConVar:CVAR_SERVER_CASH_AWARD,
	ConVar:CVAR_SERVER_FRIENDLY_FIRE,
	ConVar:CVAR_SERVER_BUY_ANYWHERE,
	ConVar:CVAR_SERVER_GIVE_BOMB,
	ConVar:CVAR_SERVER_WARMUP_TIME,
	ConVar:CVAR_SERVER_WARMUP_PERIOD,
	ConVar:CVAR_SERVER_ROUNDTIME_ZP,
	ConVar:CVAR_SERVER_ROUNDTIME_CS,
	ConVar:CVAR_SERVER_ROUNDTIME_DE,
	ConVar:CVAR_SERVER_ROUND_RESTART,
	ConVar:CVAR_GAME_CUSTOM_START,
	ConVar:CVAR_GAME_CUSTOM_MODELS,
	ConVar:CVAR_GAME_CUSTOM_ANTISTICK,
	ConVar:CVAR_GAME_CUSTOM_MENU,
	ConVar:CVAR_CONFIG_PATH_DOWNLOADS,
	ConVar:CVAR_CONFIG_PATH_HITGROUPS,
	ConVar:CVAR_CONFIG_PATH_SOUNDS,
	ConVar:CVAR_CONFIG_PATH_WEAPONS,
	ConVar:CVAR_CONFIG_PATH_MENUS,
	ConVar:CVAR_LOG,
    ConVar:CVAR_LOG_MODULE_FILTER,
    ConVar:CVAR_LOG_IGNORE_CONSOLE,
    ConVar:CVAR_LOG_ERROR_OVERRIDE,
    ConVar:CVAR_LOG_PRINT_CHAT,
	ConVar:CVAR_JUMPBOOST_ENABLE,
	ConVar:CVAR_JUMPBOOST_MULTIPLIER,
	ConVar:CVAR_JUMPBOOST_MAX,
	ConVar:CVAR_MODE_MULTI,
	ConVar:CVAR_MODE_MULTI_CHANCE,
	ConVar:CVAR_MODE_MULTI_MIN,
	ConVar:CVAR_MODE_MULTI_RATIO,
	ConVar:CVAR_MODE_SWARM,
	ConVar:CVAR_MODE_SWARM_CHANCE,
	ConVar:CVAR_MODE_SWARM_MIN,
	ConVar:CVAR_MODE_SWARM_RATIO,
	ConVar:CVAR_MODE_NEMESIS,
	ConVar:CVAR_MODE_NEMESIS_CHANCE,
	ConVar:CVAR_MODE_NEMESIS_MIN,
	ConVar:CVAR_MODE_SURVIVOR,
	ConVar:CVAR_MODE_SURVIVOR_CHANCE,
	ConVar:CVAR_MODE_SURVIVOR_MIN,
	ConVar:CVAR_MODE_ARMAGEDDON,
	ConVar:CVAR_MODE_ARMAGEDDON_CHANCE,
	ConVar:CVAR_MODE_ARMAGEDDON_MIN,
	ConVar:CVAR_HUMAN_GRENADES,
	ConVar:CVAR_HUMAN_ARMOR_PROTECT,
	ConVar:CVAR_HUMAN_LAST_INFECTION,
	ConVar:CVAR_HUMAN_INF_AMMO,
	ConVar:CVAR_HUMAN_ANTIDOT,
	ConVar:CVAR_SURVIVOR_SPEED,
	ConVar:CVAR_SURVIVOR_GRAVITY,
	ConVar:CVAR_SURVIVOR_HEALTH,
	ConVar:CVAR_SURVIVOR_DAMAGE,
	ConVar:CVAR_SURVIVOR_INF_AMMO,
	ConVar:CVAR_SURVIVOR_GLOW,
	ConVar:CVAR_SURVIVOR_GLOW_COLOR,
	ConVar:CVAR_SURVIVOR_PLAYER_MODEL,
	ConVar:CVAR_SURVIVOR_WEAPON_PRIMARY,
	ConVar:CVAR_SURVIVOR_WEAPON_SECONDARY,
	ConVar:CVAR_ZOMBIE_GRENADES,
	ConVar:CVAR_ZOMBIE_FISRT_HEALTH,
	ConVar:CVAR_ZOMBIE_NIGHT_VISION,
	ConVar:CVAR_ZOMBIE_XRAY,
	ConVar:CVAR_ZOMBIE_FOV,
	ConVar:CVAR_ZOMBIE_SILENT,
	ConVar:CVAR_ZOMBIE_BLEEDING,
	ConVar:CVAR_ZOMBIE_RESTORE,
	ConVar:CVAR_NEMESIS_SPEED,
	ConVar:CVAR_NEMESIS_GRAVITY,
	ConVar:CVAR_NEMESIS_DAMAGE,
	ConVar:CVAR_NEMESIS_HEALTH,
	ConVar:CVAR_NEMESIS_KNOCKBACK,
	ConVar:CVAR_NEMESIS_GLOW,
	ConVar:CVAR_NEMESIS_GLOW_COLOR,
	ConVar:CVAR_NEMESIS_PLAYER_MODEL,
	ConVar:CVAR_LEAP_ZOMBIE, 			
	ConVar:CVAR_LEAP_ZOMBIE_FORCE, 			
	ConVar:CVAR_LEAP_ZOMBIE_COUNTDOWN, 		
	ConVar:CVAR_LEAP_NEMESIS, 				
	ConVar:CVAR_LEAP_NEMESIS_FORCE, 			
	ConVar:CVAR_LEAP_NEMESIS_COUNTDOWN, 		
	ConVar:CVAR_LEAP_SURVIVOR, 				
	ConVar:CVAR_LEAP_SURVIVOR_FORCE,		
	ConVar:CVAR_LEAP_SURVIVOR_COUNTDOWN,
	ConVar:CVAR_BONUS_INFECT,
	ConVar:CVAR_BONUS_INFECT_HEALTH,
	ConVar:CVAR_BONUS_KILL_HUMAN,
	ConVar:CVAR_BONUS_KILL_ZOMBIE,
	ConVar:CVAR_BONUS_KILL_NEMESIS,
	ConVar:CVAR_BONUS_KILL_SURVIVOR,
	ConVar:CVAR_BONUS_DAMAGE_HUMAN,
	ConVar:CVAR_BONUS_DAMAGE_ZOMBIE,
	ConVar:CVAR_BONUS_DAMAGE_SURVIVOR,
	ConVar:CVAR_BONUS_ZOMBIE_WIN,
	ConVar:CVAR_BONUS_ZOMBIE_FAIL,
	ConVar:CVAR_BONUS_HUMAN_WIN,
	ConVar:CVAR_BONUS_HUMAN_FAIL,
	ConVar:CVAR_LEVEL_SYSTEM,
	ConVar:CVAR_LEVEL_STATISTICS,
	ConVar:CVAR_LEVEL_HEALTH_RATIO,
	ConVar:CVAR_LEVEL_SPEED_RATIO,
	ConVar:CVAR_LEVEL_GRAVITY_RATIO,
	ConVar:CVAR_LEVEL_DAMAGE_RATIO,
	ConVar:CVAR_LEVEL_DAMAGE_HUMAN,
	ConVar:CVAR_LEVEL_DAMAGE_ZOMBIE,
	ConVar:CVAR_LEVEL_DAMAGE_SURVIVOR,
	ConVar:CVAR_LEVEL_INFECT,
	ConVar:CVAR_LEVEL_KILL_HUMAN,
	ConVar:CVAR_LEVEL_KILL_ZOMBIE,
	ConVar:CVAR_LEVEL_KILL_NEMESIS,
	ConVar:CVAR_LEVEL_KILL_SURVIVOR,
	ConVar:CVAR_RESPAWN_DEATHMATCH,
	ConVar:CVAR_RESPAWN_SUICIDE,
	ConVar:CVAR_RESPAWN_AMOUNT,
	ConVar:CVAR_RESPAWN_TIME,
	ConVar:CVAR_RESPAWN_WORLD,
	ConVar:CVAR_RESPAWN_LAST,
	ConVar:CVAR_RESPAWN_INFETION,
	ConVar:CVAR_RESPAWN_ALLOW_NEMESIS,
	ConVar:CVAR_RESPAWN_ALLOW_SURVIVOR,
	ConVar:CVAR_RESPAWN_ALLOW_SWARM,
	ConVar:CVAR_RESPAWN_ZOMBIE,
	ConVar:CVAR_RESPAWN_HUMAN,
	ConVar:CVAR_RESPAWN_NEMESIS,
	ConVar:CVAR_RESPAWN_SURVIVOR,
	ConVar:CVAR_VEFFECTS_EXPLOSION,
	ConVar:CVAR_VEFFECTS_SPLASH,
	ConVar:CVAR_VEFFECTS_SHAKE,
    ConVar:CVAR_VEFFECTS_SHAKE_AMP,
    ConVar:CVAR_VEFFECTS_SHAKE_FREQUENCY,
    ConVar:CVAR_VEFFECTS_SHAKE_DURATION,
	ConVar:CVAR_VEFFECTS_FADE,
	ConVar:CVAR_VEFFECTS_FADE_TIME,
	ConVar:CVAR_VEFFECTS_FADE_DURATION,
	ConVar:CVAR_VEFFECTS_LIGHTSTYLE,
    ConVar:CVAR_VEFFECTS_LIGHTSTYLE_VALUE,
    ConVar:CVAR_VEFFECTS_SKY,
    ConVar:CVAR_VEFFECTS_SKY_PATH,
    ConVar:CVAR_VEFFECTS_SUN_DISABLE,
    ConVar:CVAR_VEFFECTS_FOG,
    ConVar:CVAR_VEFFECTS_FOG_COLOR,
    ConVar:CVAR_VEFFECTS_FOG_DENSITY,
    ConVar:CVAR_VEFFECTS_FOG_STARTDIST,
    ConVar:CVAR_VEFFECTS_FOG_ENDDIST,
    ConVar:CVAR_VEFFECTS_FOG_FARZ,
    ConVar:CVAR_VEFFECTS_RAGDOLL_REMOVE,
    ConVar:CVAR_VEFFECTS_RAGDOLL_DISSOLVE,
    ConVar:CVAR_VEFFECTS_RAGDOLL_DELAY,
	ConVar:CVAR_GRENADE_DAMAGE_HEGRENADE,
	ConVar:CVAR_GRENADE_DAMAGE_MOLOTOV,
	ConVar:CVAR_GRENADE_IGNITTING,
	ConVar:CVAR_GRENADE_EXP_RADIUS,
	ConVar:CVAR_GRENADE_EXP_KNOCKBACK,
	ConVar:CVAR_GRENADE_LIGHT_RADIUS,
	ConVar:CVAR_GRENADE_LIGHT_DISTANCE,
	ConVar:CVAR_GRENADE_LIGHT_DURATION,
	ConVar:CVAR_GRENADE_LIGHT_COLOR,
	ConVar:CVAR_GRENADE_FREEZING,
	ConVar:CVAR_GRENADE_FREEZING_NEMESIS,
	ConVar:CVAR_GRENADE_FREEZING_RADIUS,
	ConVar:CVAR_HUD_ZOMBIE_WIN,
	ConVar:CVAR_HUD_HUMAN_WIN,
	ConVar:CVAR_MESSAGES_HELP,
	ConVar:CVAR_MESSAGES_BLOCK
};

/**
 * Array to store cvar data in.
 **/
ConVar gCvarList[CvarsList];

/**
 * Cvars module init function.
 **/
void CvarsInit(/*void*/)
{
	// Create zombieplague cvars
	CvarsCreate();
	
	// Hook cvars
	CvarsHook();

	// Create revision cvar
	CreateConVar("zombieplague_revision", PLUGIN_VERSION, "Revision number for this plugin in source code repository.", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Forward event to modules
	VEffectsOnCvarInit();
	VersionOnCvarInit();
}

/**
 * Create all cvars for plugin.
 **/
void CvarsCreate(/*void*/)
{
	
	//*********************************************************************
	//*           AUTOMATIC CREATION OF THE CONFIGURATION FILE            *
	//*           FILE RELATIVE TO CONFIG SOURCEMOD REPOSITORY            *
	//*********************************************************************
	
	
	// =========================== //
    // 		Server Purpose		   //
    // =========================== //
	gCvarList[CVAR_SERVER_OCCULUSE]				= FindConVar("sv_occlude_players");
	gCvarList[CVAR_SERVER_CLAMP]				= FindConVar("sv_clamp_unsafe_velocities");
	gCvarList[CVAR_SERVER_TEAM_BALANCE]			= FindConVar("mp_autoteambalance"); 
	gCvarList[CVAR_SERVER_LIMIT_TEAMS]			= FindConVar("mp_limitteams");
	gCvarList[CVAR_SERVER_CASH_AWARD]			= FindConVar("mp_playercashawards");
	gCvarList[CVAR_SERVER_FRIENDLY_FIRE]		= FindConVar("mp_friendlyfire");
	gCvarList[CVAR_SERVER_BUY_ANYWHERE]			= FindConVar("mp_buy_anywhere");
	gCvarList[CVAR_SERVER_GIVE_BOMB]			= FindConVar("mp_give_player_c4");
	gCvarList[CVAR_SERVER_WARMUP_TIME]			= FindConVar("mp_warmuptime");
	gCvarList[CVAR_SERVER_WARMUP_PERIOD]		= FindConVar("mp_do_warmup_period");
	gCvarList[CVAR_SERVER_ROUNDTIME_ZP]			= FindConVar("mp_roundtime");
	gCvarList[CVAR_SERVER_ROUNDTIME_CS]			= FindConVar("mp_roundtime_hostage");
	gCvarList[CVAR_SERVER_ROUNDTIME_DE]			= FindConVar("mp_roundtime_defuse");
	gCvarList[CVAR_SERVER_ROUND_RESTART]		= FindConVar("mp_restartgame");

	// =========================== //
    // 		Game Purpose		   //
    // =========================== // 
	gCvarList[CVAR_GAME_CUSTOM_START]			= CreateConVar("zp_game_custom_time",  				"30");
	gCvarList[CVAR_GAME_CUSTOM_MODELS]			= CreateConVar("zp_game_custom_models",   			"1");
	gCvarList[CVAR_GAME_CUSTOM_ANTISTICK]		= CreateConVar("zp_game_custom_antistick",   		"1");
	gCvarList[CVAR_GAME_CUSTOM_MENU]			= CreateConVar("zp_game_custom_menu_button",   		"5");

	// =========================== //
    // 			Configs			   //
    // =========================== //
	gCvarList[CVAR_CONFIG_PATH_DOWNLOADS]     	= CreateConVar("zp_config_path_downloads",      	"zombieplague/downloads.ini");
	gCvarList[CVAR_CONFIG_PATH_HITGROUPS]     	= CreateConVar("zp_config_path_hitgroups",      	"zombieplague/hitgroups.ini");
	gCvarList[CVAR_CONFIG_PATH_SOUNDS]        	= CreateConVar("zp_config_path_sounds",  			"zombieplague/sounds.ini");
	gCvarList[CVAR_CONFIG_PATH_WEAPONS]       	= CreateConVar("zp_config_path_weapons",        	"zombieplague/weapons.ini");
	gCvarList[CVAR_CONFIG_PATH_MENUS]       	= CreateConVar("zp_config_path_menus",        		"zombieplague/menus.ini");

	// =========================== //
    // 			Logs			   //
    // =========================== //
	gCvarList[CVAR_LOG]                       	= CreateConVar("zp_log",                   	 		"1");
	gCvarList[CVAR_LOG_MODULE_FILTER]         	= CreateConVar("zp_log_module_filter",      		"0");
	gCvarList[CVAR_LOG_IGNORE_CONSOLE]        	= CreateConVar("zp_log_ignore_console",     		"0");
	gCvarList[CVAR_LOG_ERROR_OVERRIDE]        	= CreateConVar("zp_log_error_override",     		"1");
	gCvarList[CVAR_LOG_PRINT_CHAT]            	= CreateConVar("zp_log_print_chat",         		"0");

	// =========================== //
	// 		   Jump boost		   //
	// =========================== //
	gCvarList[CVAR_JUMPBOOST_ENABLE] 			= CreateConVar("zp_jumpboost_enable",     			"1");
	gCvarList[CVAR_JUMPBOOST_MULTIPLIER]		= CreateConVar("zp_jumpboost_multiplier",  			"1.1");
	gCvarList[CVAR_JUMPBOOST_MAX]				= CreateConVar("zp_jumpboost_max",   	   			"300.0");

	// =========================== //
    // 			Multi Mode		   //
    // =========================== //
	gCvarList[CVAR_MODE_MULTI] 				    = CreateConVar("zp_multi_mode_enabled",  			"1");
	gCvarList[CVAR_MODE_MULTI_CHANCE] 		    = CreateConVar("zp_multi_mode_chance",  			"20"); 			 
	gCvarList[CVAR_MODE_MULTI_MIN] 			    = CreateConVar("zp_multi_mode_min_players",  		"0"); 	 
	gCvarList[CVAR_MODE_MULTI_RATIO] 		    = CreateConVar("zp_multi_mode_ratio",  				"0.125"); 	 

	// =========================== //
    // 		   Swarm Mode		   //
    // =========================== //
	gCvarList[CVAR_MODE_SWARM] 			 	    = CreateConVar("zp_swarm_mode_enabled",  			"1"); 
	gCvarList[CVAR_MODE_SWARM_CHANCE]		    = CreateConVar("zp_swarm_mode_chance",  			"20"); 
	gCvarList[CVAR_MODE_SWARM_MIN]			    = CreateConVar("zp_swarm_mode_min_players",  		"0"); 
	gCvarList[CVAR_MODE_SWARM_RATIO]		    = CreateConVar("zp_swarm_mode_ratio",  				"2.0"); 

	// =========================== //
    //     Armageddon Mode		   //
    // =========================== //
	gCvarList[CVAR_MODE_ARMAGEDDON] 	 	    = CreateConVar("zp_armageddon_mode_enabled",  		"1");
	gCvarList[CVAR_MODE_ARMAGEDDON_CHANCE]      = CreateConVar("zp_armageddon_mode_chance",  		"20"); 
	gCvarList[CVAR_MODE_ARMAGEDDON_MIN]		    = CreateConVar("zp_armageddon_mode_min_players",  	"0"); 

	// =========================== //
    // 			Humans			   //
    // =========================== //
	gCvarList[CVAR_HUMAN_GRENADES] 	    		= CreateConVar("zp_human_grenades",  				"hegrenade,decoy,smokegrenade"); 
	gCvarList[CVAR_HUMAN_ARMOR_PROTECT] 	    = CreateConVar("zp_human_armor_protect",  			"1"); 
	gCvarList[CVAR_HUMAN_LAST_INFECTION] 	    = CreateConVar("zp_human_last_infection",  			"1"); 
	gCvarList[CVAR_HUMAN_INF_AMMO] 				= CreateConVar("zp_human_unlimited_ammo", 			"1");
	gCvarList[CVAR_HUMAN_ANTIDOT]				= CreateConVar("zp_human_antidot_spawn",   			"1");

	// =========================== //
    // 			Survivor		   //
    // =========================== // 
	gCvarList[CVAR_MODE_SURVIVOR]				= CreateConVar("zp_survivor_mode_enabled",  		"1"); 
	gCvarList[CVAR_MODE_SURVIVOR_CHANCE]   	    = CreateConVar("zp_survivor_mode_chance",  			"20"); 
	gCvarList[CVAR_MODE_SURVIVOR_MIN]			= CreateConVar("zp_survivor_mode_min_players",  	"0"); 
	
	gCvarList[CVAR_SURVIVOR_SPEED] 			    = CreateConVar("zp_survivor_speed",  				"1.3"); 
	gCvarList[CVAR_SURVIVOR_GRAVITY] 		    = CreateConVar("zp_survivor_gravity",  				"0.8"); 
	gCvarList[CVAR_SURVIVOR_HEALTH] 		    = CreateConVar("zp_survivor_health",  				"2000"); 
	gCvarList[CVAR_SURVIVOR_DAMAGE] 		    = CreateConVar("zp_survivor_damage",  				"5.0"); 
	gCvarList[CVAR_SURVIVOR_INF_AMMO]			= CreateConVar("zp_survivor_unlimited_ammo",  		"1");
	gCvarList[CVAR_SURVIVOR_GLOW] 		 	    = CreateConVar("zp_survivor_glow",  				"1"); 
	gCvarList[CVAR_SURVIVOR_GLOW_COLOR] 	  	= CreateConVar("zp_survivor_glow_color",  			"0 0 255 255"); 
	gCvarList[CVAR_SURVIVOR_PLAYER_MODEL] 		= CreateConVar("zp_survivor_model",  				"models/player/custom_player/legacy/tm_phoenix_heavy.mdl");
	gCvarList[CVAR_SURVIVOR_WEAPON_PRIMARY] 	= CreateConVar("zp_survivor_weapon_primary",  		"weapon_m249");
	gCvarList[CVAR_SURVIVOR_WEAPON_SECONDARY] 	= CreateConVar("zp_survivor_weapon_secondary",  	"weapon_elite");

	// =========================== //
    // 			Zombies			   //
    // =========================== //
	gCvarList[CVAR_ZOMBIE_GRENADES] 	    	= CreateConVar("zp_zombie_grenades",  				""); 
	gCvarList[CVAR_ZOMBIE_FISRT_HEALTH] 	    = CreateConVar("zp_zombie_additional_health",  		"10000"); 
	gCvarList[CVAR_ZOMBIE_NIGHT_VISION] 	    = CreateConVar("zp_zombie_nvg_give",  				"1"); 
	gCvarList[CVAR_ZOMBIE_XRAY]				    = CreateConVar("zp_zombie_xray_give",  				"1"); 
	gCvarList[CVAR_ZOMBIE_FOV]					= CreateConVar("zp_zombie_fov",  					"90");
	gCvarList[CVAR_ZOMBIE_SILENT]				= CreateConVar("zp_zombie_silent",  				"0");
	gCvarList[CVAR_ZOMBIE_BLEEDING]				= CreateConVar("zp_zombie_bleeding",  				"1");
	gCvarList[CVAR_ZOMBIE_RESTORE]				= CreateConVar("zp_zombie_restore",  				"0");   

	// =========================== //
    // 			Nemesis			   //
    // =========================== //
	gCvarList[CVAR_MODE_NEMESIS] 			    = CreateConVar("zp_nemesis_mode_enabled",  			"1"); 
	gCvarList[CVAR_MODE_NEMESIS_CHANCE]		    = CreateConVar("zp_nemesis_mode_chance",  			"20"); 
	gCvarList[CVAR_MODE_NEMESIS_MIN]		    = CreateConVar("zp_nemesis_mode_min_players",  		"0"); 

	gCvarList[CVAR_NEMESIS_SPEED] 			    = CreateConVar("zp_nemesis_speed",  				"1.5"); 
	gCvarList[CVAR_NEMESIS_GRAVITY] 		    = CreateConVar("zp_nemesis_gravity",  				"0.8"); 
	gCvarList[CVAR_NEMESIS_DAMAGE]			    = CreateConVar("zp_nemesis_slash_damage",  			"499.0"); 
	gCvarList[CVAR_NEMESIS_HEALTH] 			    = CreateConVar("zp_nemesis_health_ratio",  			"2000"); 
	gCvarList[CVAR_NEMESIS_KNOCKBACK] 			= CreateConVar("zp_nemesis_knockback", 				"0"); 
	gCvarList[CVAR_NEMESIS_GLOW] 			    = CreateConVar("zp_nemesis_glow",  					"1"); 
	gCvarList[CVAR_NEMESIS_GLOW_COLOR] 			= CreateConVar("zp_nemesis_glow_color",  			"255 0 0 255");
	gCvarList[CVAR_NEMESIS_PLAYER_MODEL] 		= CreateConVar("zp_nemesis_model",  				"models/player/custom_player/zombie/zombie_bomb/zombie_bomb.mdl"); 

	// =========================== //
    // 		   Leap jump		   //
    // =========================== //
	gCvarList[CVAR_LEAP_ZOMBIE] 				= CreateConVar("zp_leap_zombies", 					"0");
	gCvarList[CVAR_LEAP_ZOMBIE_FORCE] 			= CreateConVar("zp_leap_zombies_force", 			"500.0");
	gCvarList[CVAR_LEAP_ZOMBIE_COUNTDOWN] 		= CreateConVar("zp_leap_zombies_cooldown", 			"5.0");
	gCvarList[CVAR_LEAP_NEMESIS] 				= CreateConVar("zp_leap_nemesis", 					"1");
	gCvarList[CVAR_LEAP_NEMESIS_FORCE] 			= CreateConVar("zp_leap_nemesis_force", 			"500.0");
	gCvarList[CVAR_LEAP_NEMESIS_COUNTDOWN] 		= CreateConVar("zp_leap_nemesis_cooldown", 			"5.0");
	gCvarList[CVAR_LEAP_SURVIVOR] 				= CreateConVar("zp_leap_survivor", 					"0");
	gCvarList[CVAR_LEAP_SURVIVOR_FORCE] 		= CreateConVar("zp_leap_survivor_force", 			"500.0");
	gCvarList[CVAR_LEAP_SURVIVOR_COUNTDOWN] 	= CreateConVar("zp_leap_survivor_cooldown", 		"5.0");
	
	// =========================== //
    // 			Bonuses			   //
    // =========================== //
	gCvarList[CVAR_BONUS_INFECT] 			    = CreateConVar("zp_bonus_infect",  					"1"); 
	gCvarList[CVAR_BONUS_INFECT_HEALTH] 		= CreateConVar("zp_bonus_infect_health",  			"500"); 
	gCvarList[CVAR_BONUS_KILL_HUMAN] 			= CreateConVar("zp_bonus_kill_human",				"1"); 
	gCvarList[CVAR_BONUS_KILL_ZOMBIE] 			= CreateConVar("zp_bonus_kill_zombie",				"1"); 
	gCvarList[CVAR_BONUS_KILL_NEMESIS] 		 	= CreateConVar("zp_bonus_kill_nemesis",				"10"); 
	gCvarList[CVAR_BONUS_KILL_SURVIVOR] 		= CreateConVar("zp_bonus_kill_survivor",			"10"); 
	gCvarList[CVAR_BONUS_DAMAGE_HUMAN] 			= CreateConVar("zp_bonus_damage_human",  			"500");
	gCvarList[CVAR_BONUS_DAMAGE_ZOMBIE] 	    = CreateConVar("zp_bonus_damage_zombie",  			"200");
	gCvarList[CVAR_BONUS_DAMAGE_SURVIVOR] 	    = CreateConVar("zp_bonus_damage_survivor",  		"2000"); 
	gCvarList[CVAR_BONUS_ZOMBIE_WIN] 	    	= CreateConVar("zp_bonus_zombie_win",  				"2"); 
	gCvarList[CVAR_BONUS_ZOMBIE_FAIL] 	    	= CreateConVar("zp_bonus_zombie_fail",  			"1"); 
	gCvarList[CVAR_BONUS_HUMAN_WIN] 	    	= CreateConVar("zp_bonus_human_win",  				"2"); 
	gCvarList[CVAR_BONUS_HUMAN_FAIL] 	    	= CreateConVar("zp_bonus_human_fail",  				"1"); 

	// =========================== //
    // 			Level System	   //
    // =========================== //
	gCvarList[CVAR_LEVEL_SYSTEM]				= CreateConVar("zp_level_system",  					"1"); 
	gCvarList[CVAR_LEVEL_STATISTICS]			= CreateConVar("zp_level_statistics",  				"0,100,200,300,400,500,600,700,800,900,1000"); 
	gCvarList[CVAR_LEVEL_HEALTH_RATIO]			= CreateConVar("zp_level_health_ratio",  			"0.1"); 
	gCvarList[CVAR_LEVEL_SPEED_RATIO]			= CreateConVar("zp_level_speed_ratio",  			"0.1"); 
	gCvarList[CVAR_LEVEL_GRAVITY_RATIO]			= CreateConVar("zp_level_gravity_ratio",  			"0.01"); 
	gCvarList[CVAR_LEVEL_DAMAGE_RATIO]			= CreateConVar("zp_level_damage_ratio",  			"0.1"); 
	gCvarList[CVAR_LEVEL_DAMAGE_HUMAN] 			= CreateConVar("zp_level_damage_human",  			"500");
	gCvarList[CVAR_LEVEL_DAMAGE_ZOMBIE] 	    = CreateConVar("zp_level_damage_zombie",  			"200");
	gCvarList[CVAR_LEVEL_DAMAGE_SURVIVOR] 	    = CreateConVar("zp_level_damage_survivor",  		"2000");
	gCvarList[CVAR_LEVEL_INFECT]				= CreateConVar("zp_level_infect",  					"1"); 
	gCvarList[CVAR_LEVEL_KILL_HUMAN]			= CreateConVar("zp_level_kill_human",  				"1"); 
	gCvarList[CVAR_LEVEL_KILL_ZOMBIE]			= CreateConVar("zp_level_kill_zombie",  			"1"); 
	gCvarList[CVAR_LEVEL_KILL_NEMESIS]			= CreateConVar("zp_level_kill_nemesis",  			"10"); 
	gCvarList[CVAR_LEVEL_KILL_SURVIVOR]			= CreateConVar("zp_level_kill_survivor",  			"10"); 

	// =========================== //
    // 		  Deathmatch		   //
    // =========================== //
	gCvarList[CVAR_RESPAWN_DEATHMATCH] 			= CreateConVar("zp_deathmatch", 					"0");
	gCvarList[CVAR_RESPAWN_SUICIDE] 			= CreateConVar("zp_suicide", 						"0");
	gCvarList[CVAR_RESPAWN_AMOUNT] 			    = CreateConVar("zp_respawn_amount",  				"5"); 
	gCvarList[CVAR_RESPAWN_TIME] 			    = CreateConVar("zp_respawn_time",  					"5.0"); 
	gCvarList[CVAR_RESPAWN_WORLD] 				= CreateConVar("zp_respawn_on_suicide", 			"1");
	gCvarList[CVAR_RESPAWN_LAST] 				= CreateConVar("zp_respawn_after_last_human", 		"1");
	gCvarList[CVAR_RESPAWN_INFETION] 			= CreateConVar("zp_infection_allow_respawn", 		"1");
	gCvarList[CVAR_RESPAWN_ALLOW_NEMESIS]  		= CreateConVar("zp_nemesis_allow_respawn", 			"0"); 
	gCvarList[CVAR_RESPAWN_ALLOW_SURVIVOR] 		= CreateConVar("zp_survivor_allow_respawn", 		"0"); 
	gCvarList[CVAR_RESPAWN_ALLOW_SWARM]			= CreateConVar("zp_swarm_allow_respawn", 			"0"); 
	gCvarList[CVAR_RESPAWN_ZOMBIE] 				= CreateConVar("zp_respawn_zombies", 				"1");
	gCvarList[CVAR_RESPAWN_HUMAN] 				= CreateConVar("zp_respawn_humans", 				"0"); 
	gCvarList[CVAR_RESPAWN_NEMESIS]				= CreateConVar("zp_respawn_nemesis", 				"1"); 
	gCvarList[CVAR_RESPAWN_SURVIVOR] 			= CreateConVar("zp_respawn_survivor", 				"1");

	// =========================== //
    // 			Effects			   //
    // =========================== //
	gCvarList[CVAR_VEFFECTS_EXPLOSION] 		    = CreateConVar("zp_veffects_smoke_explosion",    	"1");
	gCvarList[CVAR_VEFFECTS_SPLASH] 		 	= CreateConVar("zp_veffects_splash",  				"1"); 
	gCvarList[CVAR_VEFFECTS_SHAKE] 			 	= CreateConVar("zp_veffects_shake",  	  			"1"); 
	gCvarList[CVAR_VEFFECTS_SHAKE_AMP]         	= CreateConVar("zp_veffects_shake_amp",             "15.0");
	gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY]   	= CreateConVar("zp_veffects_shake_frequency",       "1.0");
	gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]    	= CreateConVar("zp_veffects_shake_duration",        "5.0"); 
	gCvarList[CVAR_VEFFECTS_FADE] 			 	= CreateConVar("zp_veffects_fade",  	  			"1"); 
	gCvarList[CVAR_VEFFECTS_FADE_TIME] 			= CreateConVar("zp_veffects_fade_time",  	  		"0.7"); 
	gCvarList[CVAR_VEFFECTS_FADE_DURATION] 		= CreateConVar("zp_veffects_fade_duration",  	  	"0.2"); 
	
	// =========================== //
    // 			  Sky			   //
    // =========================== //
	gCvarList[CVAR_VEFFECTS_LIGHTSTYLE]     	= CreateConVar("zp_veffects_lightstyle",         	"1");
	gCvarList[CVAR_VEFFECTS_LIGHTSTYLE_VALUE]   = CreateConVar("zp_veffects_lightstyle_value",   	"b");
	gCvarList[CVAR_VEFFECTS_SKY]                = CreateConVar("zp_veffects_sky",                	"1");
	gCvarList[CVAR_VEFFECTS_SKY_PATH]           = CreateConVar("zp_veffects_sky_path",           	"jungle");
	gCvarList[CVAR_VEFFECTS_SUN_DISABLE]     	= CreateConVar("zp_veffects_sun_disable",        	"1");

	// =========================== //
    // 			 Fog			   //
    // =========================== //
	gCvarList[CVAR_VEFFECTS_FOG]             	= CreateConVar("zp_veffects_fog",                	"1");
	gCvarList[CVAR_VEFFECTS_FOG_COLOR]     	    = CreateConVar("zp_veffects_fog_color",          	"200 200 200");
	gCvarList[CVAR_VEFFECTS_FOG_DENSITY]     	= CreateConVar("zp_veffects_fog_density",        	"0.2");
	gCvarList[CVAR_VEFFECTS_FOG_STARTDIST]      = CreateConVar("zp_veffects_fog_startdist",     	"300");
	gCvarList[CVAR_VEFFECTS_FOG_ENDDIST]        = CreateConVar("zp_veffects_fog_enddist",        	"1200");
	gCvarList[CVAR_VEFFECTS_FOG_FARZ]           = CreateConVar("zp_veffects_fog_farz",           	"4000");

	// =========================== //
    // 			Ragdoll			   //
    // =========================== //
	gCvarList[CVAR_VEFFECTS_RAGDOLL_REMOVE]     = CreateConVar("zp_veffects_ragdoll_remove",     	"1");
	gCvarList[CVAR_VEFFECTS_RAGDOLL_DISSOLVE]   = CreateConVar("zp_veffects_ragdoll_dissolve",   	"-1");
	gCvarList[CVAR_VEFFECTS_RAGDOLL_DELAY]      = CreateConVar("zp_veffects_ragdoll_delay",      	"0.5");

	// =========================== //
    // 			Grenades	       //
    // =========================== //
	gCvarList[CVAR_GRENADE_DAMAGE_HEGRENADE] 	= CreateConVar("zp_grenade_explosion_damage",  		"6.0"); 
	gCvarList[CVAR_GRENADE_DAMAGE_MOLOTOV]  	= CreateConVar("zp_grenade_igniting_damage",  		"7.0");
	gCvarList[CVAR_GRENADE_IGNITTING] 		    = CreateConVar("zp_grenade_igniting_time",  		"5.0");
	gCvarList[CVAR_GRENADE_EXP_RADIUS]      	= CreateConVar("zp_grenade_exp_radius",  	 		"300.0");
	gCvarList[CVAR_GRENADE_EXP_KNOCKBACK]       = CreateConVar("zp_grenade_exp_knockback",   		"500.0");  
	gCvarList[CVAR_GRENADE_LIGHT_RADIUS]      	= CreateConVar("zp_grenade_light_radius",  	 		"150.0"); 	
	gCvarList[CVAR_GRENADE_LIGHT_DISTANCE]      = CreateConVar("zp_grenade_light_distance",  		"2000.0");  
	gCvarList[CVAR_GRENADE_LIGHT_DURATION]      = CreateConVar("zp_grenade_light_duration",  		"60.0");  	
	gCvarList[CVAR_GRENADE_LIGHT_COLOR]        	= CreateConVar("zp_grenade_light_color",  	 		"255 255 255 255"); 
	gCvarList[CVAR_GRENADE_FREEZING] 			= CreateConVar("zp_grenade_freeze_time", 			"4.0"); 
	gCvarList[CVAR_GRENADE_FREEZING_NEMESIS] 	= CreateConVar("zp_grenade_freeze_nemesis", 		"0"); 
	gCvarList[CVAR_GRENADE_FREEZING_RADIUS] 	= CreateConVar("zp_grenade_freeze_radius", 			"200.0"); 
	
	// =========================== //
    // 			Resources		   //
    // =========================== //
	gCvarList[CVAR_HUD_ZOMBIE_WIN]              = CreateConVar("zp_overlay_zombie_win",     		"overlays/zp/zg_zombies_win"); 
	gCvarList[CVAR_HUD_HUMAN_WIN]               = CreateConVar("zp_overlay_human_win",     			"overlays/zp/zg_humans_win");
	
	// =========================== //
    // 			Messages		   //
    // =========================== //
	gCvarList[CVAR_MESSAGES_HELP]				= CreateConVar("zp_messages_help",   				"1");
	gCvarList[CVAR_MESSAGES_BLOCK]				= CreateConVar("zp_messages_block",   				"Player_Cash_Award_Team_Cash_Award_Player_Point_Award");
	
	
	// Auto-generate config file ifit doesn't exist, then execute.
	AutoExecConfig(true, "zombieplague");
}

/**
 * Hook cvar changes.
 **/
void CvarsHook(/*void*/)
{
	// Set locked cvars to their locked value
	SetConVarInt(gCvarList[CVAR_SERVER_CLAMP],				0);
	SetConVarInt(gCvarList[CVAR_SERVER_TEAM_BALANCE],		0);
	SetConVarInt(gCvarList[CVAR_SERVER_LIMIT_TEAMS],		0);
	SetConVarInt(gCvarList[CVAR_SERVER_CASH_AWARD],			0);
	SetConVarInt(gCvarList[CVAR_SERVER_FRIENDLY_FIRE],		0);
	SetConVarInt(gCvarList[CVAR_SERVER_BUY_ANYWHERE],		0);
	SetConVarInt(gCvarList[CVAR_SERVER_GIVE_BOMB],			0);
	SetConVarInt(gCvarList[CVAR_SERVER_WARMUP_TIME],		0);
	SetConVarInt(gCvarList[CVAR_SERVER_WARMUP_PERIOD],		0);
	
	// Hook locked cvars to prevent it from changing
	HookConVarChange(gCvarList[CVAR_SERVER_CLAMP],			CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_TEAM_BALANCE],	CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_LIMIT_TEAMS],	CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_CASH_AWARD],		CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_FIRE],	CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_BUY_ANYWHERE],	CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_GIVE_BOMB],		CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_WARMUP_TIME],	CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_WARMUP_PERIOD],	CvarsHookLocked);
	HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_ZP],	CvarsHookRoundTime);
	HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_CS],	CvarsHookRoundTime);
	HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_DE],	CvarsHookRoundTime);
	HookConVarChange(gCvarList[CVAR_SERVER_ROUND_RESTART],	CvarsHookRoundRestart);
	HookConVarChange(gCvarList[CVAR_ZOMBIE_XRAY], 			CvarsHookZombieVision);
}

/**
 * Cvar hook callback.
 * Prevents changes of the some cvars.
 * 
 * @param hConVar			The cvar handle.
 * @param oldValue			The value before the attempted change.
 * @param newValue			The new value.
 **/
public void CvarsHookLocked(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    SetConVarInt(hConVar, 0);
}

/**
 * Cvar hook callback (mp_roundtime, mp_roundtime_hostage, mp_roundtime_defuse)
 * Prevent from long rounds.
 * 
 * @param hConVar			The cvar handle.
 * @param oldValue			The value before the attempted change.
 * @param newValue			The new value.
 **/
public void CvarsHookRoundTime(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	// If cvar is mp_roundtime_hostage or mp_roundtime_defuse, then continue
	if(hConVar == gCvarList[CVAR_SERVER_ROUNDTIME_CS] || hConVar == gCvarList[CVAR_SERVER_ROUNDTIME_DE])
	{
		// Revert to specific value
        SetConVarInt(hConVar, GetConVarInt(gCvarList[CVAR_SERVER_ROUNDTIME_ZP]));
	}
	
	// If value was invalid, then stop
	int iDelay = StringToInt(newValue);
	if(iDelay <= CvarsRoundMax)
	{
		return;
	}
	
	// Revert to minimum value
	SetConVarInt(hConVar, CvarsRoundMax);
}

/**
 * Cvar hook callback. (mp_restartgame)
 * Stops restart and just ends the round.
 * 
 * @param hConVar			The cvar handle.
 * @param oldValue			The value before the attempted change.
 * @param newValue			The new value.
 **/
public void CvarsHookRoundRestart(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	// Prevent round restart
	SetConVarInt(hConVar, 0);

	// If value was invalid, then stop
	int iDelay = StringToInt(newValue);
	if(iDelay <= 0)
	{
		return;
	}
	
	// Reset number of rounds
	gServerData[Server_RoundNumber] = 0;
	
	// Reset score in the scoreboard
	SetTeamScore(TEAM_ZOMBIE, 0);
	SetTeamScore(TEAM_HUMAN,  0);

	// Terminate the round with restart time as delay
	CS_TerminateRound(float(iDelay), CSRoundEnd_GameStart, false);
}

/**
 * Cvar hook callback. (zp_zombie_xray_give)
 * Enable or disable wall hack feature due to the x-ray vision.
 * 
 * @param hConVar			The cvar handle.
 * @param oldValue			The value before the attempted change.
 * @param newValue			The new value.
 **/
public void CvarsHookZombieVision(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	// Revert to opposite value
	SetConVarInt(gCvarList[CVAR_SERVER_OCCULUSE], !StringToInt(newValue));
}

/**
 * Replicates a convar values to a specific client. 
 * This does not change the actual convar values.
 *
 * @param clientIndex 		The client index.
 **/
void CvarsOnClientSpawn(int clientIndex)
{
	// If client is bot, then stop
	if(IsFakeClient(clientIndex))
	{	
		return;
	}

	// Send a convar to client
	SendConVarValue(clientIndex, gCvarList[CVAR_SERVER_CASH_AWARD], "1");
}