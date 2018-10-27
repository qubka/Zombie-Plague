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
    ConVar:CVAR_SERVER_CASH_MAX,
    ConVar:CVAR_SERVER_FRIENDLY_FIRE,
    ConVar:CVAR_SERVER_FRIENDLY_GRENADE,
    ConVar:CVAR_SERVER_FRIENDLY_BULLETS,
    ConVar:CVAR_SERVER_FRIENDLY_OTHER,
    ConVar:CVAR_SERVER_FRIENDLY_SELF,
    ConVar:CVAR_SERVER_BUY_ANYWHERE,
    ConVar:CVAR_SERVER_WARMUP_TIME,
    ConVar:CVAR_SERVER_WARMUP_PERIOD,
    ConVar:CVAR_SERVER_GIVE_WEAPON,
    ConVar:CVAR_SERVER_GIVE_TASER,
    ConVar:CVAR_SERVER_GIVE_BOMB,
    ConVar:CVAR_SERVER_ROUNDTIME_ZP,
    ConVar:CVAR_SERVER_ROUNDTIME_CS,
    ConVar:CVAR_SERVER_ROUNDTIME_DE,
    ConVar:CVAR_SERVER_ROUND_RESTART,
    ConVar:CVAR_SERVER_RESTART_DELAY,
    ConVar:CVAR_GAME_CUSTOM_START,
    ConVar:CVAR_GAME_CUSTOM_MODELS,
    ConVar:CVAR_GAME_CUSTOM_ANTISTICK,
    ConVar:CVAR_GAME_CUSTOM_HITGROUPS,
    ConVar:CVAR_GAME_CUSTOM_COSTUMES,
    ConVar:CVAR_GAME_CUSTOM_DATABASE,
    ConVar:CVAR_GAME_CUSTOM_MENU_BUTTON,
    ConVar:CVAR_GAME_CUSTOM_SOUND_LEVEL,
    ConVar:CVAR_CONFIG_PATH_DOWNLOADS,
    ConVar:CVAR_CONFIG_PATH_HITGROUPS,
    ConVar:CVAR_CONFIG_PATH_SOUNDS,
    ConVar:CVAR_CONFIG_PATH_WEAPONS,
    ConVar:CVAR_CONFIG_PATH_MENUS,
    ConVar:CVAR_CONFIG_PATH_COSTUMES,
    ConVar:CVAR_CONFIG_PATH_DATABASE,
    ConVar:CVAR_CONFIG_NAME_DATABASE,
    ConVar:CVAR_LOG,
    ConVar:CVAR_LOG_MODULE_FILTER,
    ConVar:CVAR_LOG_IGNORE_CONSOLE,
    ConVar:CVAR_LOG_ERROR_OVERRIDE,
    ConVar:CVAR_LOG_PRINT_CHAT,
    ConVar:CVAR_JUMPBOOST_ENABLE,
    ConVar:CVAR_JUMPBOOST_MULTIPLIER,
    ConVar:CVAR_JUMPBOOST_MAX,
    ConVar:CVAR_HUMAN_CLASS_MENU,
    ConVar:CVAR_HUMAN_ARMOR_PROTECT,
    ConVar:CVAR_HUMAN_LAST_INFECTION,
    ConVar:CVAR_HUMAN_INF_AMMUNITION,
    ConVar:CVAR_HUMAN_PRICE_AMMUNITION,
    ConVar:CVAR_SURVIVOR_SPEED,
    ConVar:CVAR_SURVIVOR_GRAVITY,
    ConVar:CVAR_SURVIVOR_HEALTH,
    ConVar:CVAR_SURVIVOR_INF_AMMUNITION,
    ConVar:CVAR_SURVIVOR_PRICE_AMMUNITION,
    ConVar:CVAR_SURVIVOR_PLAYER_MODEL,
    ConVar:CVAR_SURVIVOR_ARM_MODEL,
    ConVar:CVAR_ZOMBIE_CLASS_MENU,
    ConVar:CVAR_ZOMBIE_FISRT_HEALTH,
    ConVar:CVAR_ZOMBIE_NIGHT_VISION,
    ConVar:CVAR_ZOMBIE_XRAY,
    ConVar:CVAR_ZOMBIE_CROSSHAIR,
    ConVar:CVAR_ZOMBIE_RESTORE,
    ConVar:CVAR_NEMESIS_SPEED,
    ConVar:CVAR_NEMESIS_GRAVITY,
    ConVar:CVAR_NEMESIS_HEALTH,
    ConVar:CVAR_NEMESIS_KNOCKBACK,
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
    ConVar:CVAR_BONUS_CONNECT,
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
    ConVar:CVAR_BONUS_ZOMBIE_DRAW,
    ConVar:CVAR_BONUS_HUMAN_WIN,
    ConVar:CVAR_BONUS_HUMAN_FAIL,
    ConVar:CVAR_BONUS_HUMAN_DRAW,
    ConVar:CVAR_BONUS_HUD_ACCOUNT_R,
    ConVar:CVAR_BONUS_HUD_ACCOUNT_G,
    ConVar:CVAR_BONUS_HUD_ACCOUNT_B,
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
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_R,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_G,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_B,
    ConVar:CVAR_LEVEL_HUD_HUMAN_R,
    ConVar:CVAR_LEVEL_HUD_HUMAN_G,
    ConVar:CVAR_LEVEL_HUD_HUMAN_B,
    ConVar:CVAR_RESPAWN_DEATHMATCH,
    ConVar:CVAR_RESPAWN_SUICIDE,
    ConVar:CVAR_RESPAWN_AMOUNT,
    ConVar:CVAR_RESPAWN_TIME,
    ConVar:CVAR_RESPAWN_WORLD,
    ConVar:CVAR_RESPAWN_LAST,
    ConVar:CVAR_RESPAWN_ZOMBIE,
    ConVar:CVAR_RESPAWN_HUMAN,
    ConVar:CVAR_RESPAWN_NEMESIS,
    ConVar:CVAR_RESPAWN_SURVIVOR,
    ConVar:CVAR_VEFFECTS_SHAKE,
    ConVar:CVAR_VEFFECTS_SHAKE_AMP,
    ConVar:CVAR_VEFFECTS_SHAKE_FREQUENCY,
    ConVar:CVAR_VEFFECTS_SHAKE_DURATION,
    ConVar:CVAR_VEFFECTS_FADE,
    ConVar:CVAR_VEFFECTS_FADE_TIME,
    ConVar:CVAR_VEFFECTS_FADE_DURATION,
    ConVar:CVAR_VEFFECTS_PARTICLES,
    ConVar:CVAR_VEFFECTS_RESPAWN,
    ConVar:CVAR_VEFFECTS_RESPAWN_NAME,
    ConVar:CVAR_VEFFECTS_RESPAWN_ATTACH,
    ConVar:CVAR_VEFFECTS_RESPAWN_DURATION,
    ConVar:CVAR_VEFFECTS_INFECT,
    ConVar:CVAR_VEFFECTS_INFECT_NAME,
    ConVar:CVAR_VEFFECTS_INFECT_ATTACH,
    ConVar:CVAR_VEFFECTS_INFECT_DURATION,
    ConVar:CVAR_VEFFECTS_ANTIDOT,
    ConVar:CVAR_VEFFECTS_ANTIDOT_NAME,
    ConVar:CVAR_VEFFECTS_ANTIDOT_ATTACH,
    ConVar:CVAR_VEFFECTS_ANTIDOT_DURATION,
    ConVar:CVAR_VEFFECTS_HEAL,
    ConVar:CVAR_VEFFECTS_HEAL_NAME,
    ConVar:CVAR_VEFFECTS_HEAL_ATTACH,
    ConVar:CVAR_VEFFECTS_HEAL_DURATION,
    ConVar:CVAR_VEFFECTS_NEMESIS,
    ConVar:CVAR_VEFFECTS_NEMESIS_NAME,
    ConVar:CVAR_VEFFECTS_NEMESIS_ATTACH,
    ConVar:CVAR_VEFFECTS_NEMESIS_DURATION,
    ConVar:CVAR_VEFFECTS_SURVIVOR,
    ConVar:CVAR_VEFFECTS_SURVIVOR_NAME,
    ConVar:CVAR_VEFFECTS_SURVIVOR_ATTACH,
    ConVar:CVAR_VEFFECTS_SURVIVOR_DURATION,
    ConVar:CVAR_VEFFECTS_LEAP,
    ConVar:CVAR_VEFFECTS_LEAP_NAME,
    ConVar:CVAR_VEFFECTS_LEAP_ATTACH,
    ConVar:CVAR_VEFFECTS_LEAP_DURATION,
    ConVar:CVAR_VEFFECTS_SKYNAME,
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
    ConVar:CVAR_VEFFECTS_HUD_ZOMBIE,
    ConVar:CVAR_VEFFECTS_HUD_HUMAN,
    ConVar:CVAR_VEFFECTS_HUD_DRAW,
    ConVar:CVAR_VEFFECTS_HUD_VISION,
    ConVar:CVAR_SEFFECTS_ALLTALK,
    ConVar:CVAR_SEFFECTS_VOICE,
    ConVar:CVAR_SEFFECTS_VOICE_ZOMBIES_MUTE,
    ConVar:CVAR_SEFFECTS_INFECT,
    ConVar:CVAR_SEFFECTS_MOAN,
    ConVar:CVAR_SEFFECTS_GROAN,
    ConVar:CVAR_SEFFECTS_BURN,
    ConVar:CVAR_SEFFECTS_DEATH,
    ConVar:CVAR_SEFFECTS_FOOTSTEPS,
    ConVar:CVAR_SEFFECTS_CLAWS,
    ConVar:CVAR_SEFFECTS_SURVIVOR_INFECT,
    ConVar:CVAR_SEFFECTS_SURVIVOR_HURT,
    ConVar:CVAR_SEFFECTS_SURVIVOR_DEATH,
    ConVar:CVAR_SEFFECTS_NEMESIS_IDLE,
    ConVar:CVAR_SEFFECTS_NEMESIS_HURT,
    ConVar:CVAR_SEFFECTS_NEMESIS_DEATH,
    ConVar:CVAR_SEFFECTS_NEMESIS_BURN,
    ConVar:CVAR_SEFFECTS_NEMESIS_FOOTSTEP,
    ConVar:CVAR_SEFFECTS_NEMESIS_RESPAWN, 
    ConVar:CVAR_SEFFECTS_NEMESIS_ATTACK,     
    ConVar:CVAR_SEFFECTS_PLAYER_FLASHLIGHT, 
    ConVar:CVAR_SEFFECTS_PLAYER_AMMUNITION,  
    ConVar:CVAR_SEFFECTS_PLAYER_LEVEL,       
    ConVar:CVAR_SEFFECTS_ROUND_START,       
    ConVar:CVAR_SEFFECTS_ROUND_COUNT,        
    ConVar:CVAR_SEFFECTS_ROUND_ZOMBIE,           
    ConVar:CVAR_SEFFECTS_ROUND_HUMAN,         
    ConVar:CVAR_SEFFECTS_ROUND_DRAW,
    ConVar:CVAR_MESSAGES_HELP,
    ConVar:CVAR_MESSAGES_BLOCK,
    ConVar:CVAR_CT_DEFAULT_GRENADES,
    ConVar:CVAR_CT_DEFAULT_MELEE,
    ConVar:CVAR_CT_DEFAULT_SECONDARY,
    ConVar:CVAR_CT_DEFAULT_PRIMARY,
    ConVar:CVAR_T_DEFAULT_GRENADES,
    ConVar:CVAR_T_DEFAULT_MELEE,
    ConVar:CVAR_T_DEFAULT_SECONDARY,
    ConVar:CVAR_T_DEFAULT_PRIMARY,
    ConVar:CVAR_H_DEFAULT_EQUIPMENT,
    ConVar:CVAR_H_DEFAULT_MELEE,
    ConVar:CVAR_H_DEFAULT_SECONDARY,
    ConVar:CVAR_H_DEFAULT_PRIMARY,
    ConVar:CVAR_Z_DEFAULT_EQUIPMENT,
    ConVar:CVAR_Z_DEFAULT_MELEE,
    ConVar:CVAR_Z_DEFAULT_SECONDARY,
    ConVar:CVAR_Z_DEFAULT_PRIMARY,
    ConVar:CVAR_N_DEFAULT_EQUIPMENT,
    ConVar:CVAR_N_DEFAULT_MELEE,
    ConVar:CVAR_N_DEFAULT_SECONDARY,
    ConVar:CVAR_N_DEFAULT_PRIMARY,
    ConVar:CVAR_S_DEFAULT_EQUIPMENT,
    ConVar:CVAR_S_DEFAULT_MELEE,
    ConVar:CVAR_S_DEFAULT_SECONDARY,
    ConVar:CVAR_S_DEFAULT_PRIMARY
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
    //        Server Purpose       //
    // =========================== //
    gCvarList[CVAR_SERVER_OCCULUSE]             = FindConVar("sv_occlude_players");
    gCvarList[CVAR_SERVER_CLAMP]                = FindConVar("sv_clamp_unsafe_velocities");
    gCvarList[CVAR_SERVER_TEAM_BALANCE]         = FindConVar("mp_autoteambalance"); 
    gCvarList[CVAR_SERVER_LIMIT_TEAMS]          = FindConVar("mp_limitteams");
    gCvarList[CVAR_SERVER_CASH_AWARD]           = FindConVar("mp_playercashawards");
    gCvarList[CVAR_SERVER_CASH_MAX]             = FindConVar("mp_maxmoney");
    gCvarList[CVAR_SERVER_FRIENDLY_FIRE]        = FindConVar("mp_friendlyfire");
    gCvarList[CVAR_SERVER_FRIENDLY_GRENADE]     = FindConVar("ff_damage_reduction_grenade");
    gCvarList[CVAR_SERVER_FRIENDLY_BULLETS]     = FindConVar("ff_damage_reduction_bullets");
    gCvarList[CVAR_SERVER_FRIENDLY_OTHER]       = FindConVar("ff_damage_reduction_other");
    gCvarList[CVAR_SERVER_FRIENDLY_SELF]        = FindConVar("ff_damage_reduction_grenade_self");
    gCvarList[CVAR_SERVER_BUY_ANYWHERE]         = FindConVar("mp_buy_anywhere");
    gCvarList[CVAR_SERVER_WARMUP_TIME]          = FindConVar("mp_warmuptime");
    gCvarList[CVAR_SERVER_WARMUP_PERIOD]        = FindConVar("mp_do_warmup_period");
    gCvarList[CVAR_SERVER_GIVE_WEAPON]          = FindConVar("mp_weapons_allow_map_placed");
    gCvarList[CVAR_SERVER_GIVE_TASER]           = FindConVar("mp_weapons_allow_zeus");
    gCvarList[CVAR_SERVER_GIVE_BOMB]            = FindConVar("mp_give_player_c4");
    gCvarList[CVAR_SERVER_ROUNDTIME_ZP]         = FindConVar("mp_roundtime");
    gCvarList[CVAR_SERVER_ROUNDTIME_CS]         = FindConVar("mp_roundtime_hostage");
    gCvarList[CVAR_SERVER_ROUNDTIME_DE]         = FindConVar("mp_roundtime_defuse");
    gCvarList[CVAR_SERVER_ROUND_RESTART]        = FindConVar("mp_restartgame");
    gCvarList[CVAR_SERVER_RESTART_DELAY]        = FindConVar("mp_round_restart_delay");

    // =========================== //
    //         Game Purpose        //
    // =========================== // 
    gCvarList[CVAR_GAME_CUSTOM_START]           = CreateConVar("zp_game_custom_time",               "30",                                                              "Time before any game mode starts in seconds [0-disabled]");
    gCvarList[CVAR_GAME_CUSTOM_MODELS]          = CreateConVar("zp_game_custom_models",             "1",                                                               "Enable custom weapon models [0-no // 1-yes] (Disable it, if you do not want to have possible ban)");
    gCvarList[CVAR_GAME_CUSTOM_ANTISTICK]       = CreateConVar("zp_game_custom_antistick",          "1",                                                               "Enable auto unstick players when stuck within each others' collision hull [0-no // 1-yes]");
    gCvarList[CVAR_GAME_CUSTOM_HITGROUPS]       = CreateConVar("zp_game_custom_hitgroups",          "1",                                                               "Enable hitgroups module, disabling this will disable hitgroup-related features. (hitgroup knockback multipliers, hitgroup damage control) [0-no // 1-yes]");
    gCvarList[CVAR_GAME_CUSTOM_COSTUMES]        = CreateConVar("zp_game_custom_costumes",           "1",                                                               "Enable costumes module, disabling this will disable costumes-related features. (hats on the players) [0-no // 1-yes]");
    gCvarList[CVAR_GAME_CUSTOM_DATABASE]        = CreateConVar("zp_game_custom_database",           "1",                                                               "Enable auto saving of players data in the database [0-off // 1-always // 2-map]");
    gCvarList[CVAR_GAME_CUSTOM_MENU_BUTTON]     = CreateConVar("zp_game_custom_menu_button",        "5",                                                               "Index of the button for the main menu");
    gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL]     = CreateConVar("zp_game_custom_sound_level",        "75",                                                              "Index of the sound level for the modification");

    // =========================== //
    //           Configs           //
    // =========================== //
    gCvarList[CVAR_CONFIG_PATH_DOWNLOADS]       = CreateConVar("zp_config_path_downloads",          "zombieplague/downloads.ini",                                      "Path, relative to root sourcemod directory, to downloads file");
    gCvarList[CVAR_CONFIG_PATH_HITGROUPS]       = CreateConVar("zp_config_path_hitgroups",          "zombieplague/hitgroups.ini",                                      "Path, relative to root sourcemod directory, to hitgroups config file");
    gCvarList[CVAR_CONFIG_PATH_SOUNDS]          = CreateConVar("zp_config_path_sounds",             "zombieplague/sounds.ini",                                         "Path, relative to root sourcemod directory, to sounds config file");
    gCvarList[CVAR_CONFIG_PATH_WEAPONS]         = CreateConVar("zp_config_path_weapons",            "zombieplague/weapons.ini",                                        "Path, relative to root sourcemod directory, to weapons config file");
    gCvarList[CVAR_CONFIG_PATH_MENUS]           = CreateConVar("zp_config_path_menus",              "zombieplague/menus.ini",                                          "Path, relative to root sourcemod directory, to menus config file");
    gCvarList[CVAR_CONFIG_PATH_COSTUMES]        = CreateConVar("zp_config_path_costumes",           "zombieplague/costumes.ini",                                       "Path, relative to root sourcemod directory, to costumes config file");
    gCvarList[CVAR_CONFIG_PATH_DATABASE]        = CreateConVar("zp_config_path_database",           "zombiedatabase",                                                  "Section, relative to root sourcemod directory, to default 'database.cfg' file");
    gCvarList[CVAR_CONFIG_NAME_DATABASE]        = CreateConVar("zp_config_name_database",           "zombieplague",                                                    "Name of database in the section above");
    
    // =========================== //
    //            Logs             //
    // =========================== //
    gCvarList[CVAR_LOG]                         = CreateConVar("zp_log",                            "1",                                                               "Enable logging of events in the plugin. Fatal errors are always logged [0-no // 1-yes]");
    gCvarList[CVAR_LOG_MODULE_FILTER]           = CreateConVar("zp_log_module_filter",              "0",                                                               "Enable module filtering. Only events from listed modules will be logged [0-no // 1-yes]");
    gCvarList[CVAR_LOG_IGNORE_CONSOLE]          = CreateConVar("zp_log_ignore_console",             "0",                                                               "Don't log events triggered by console commands that are executed by the console itself, like commands in configs [0-no // 1-yes]");
    gCvarList[CVAR_LOG_ERROR_OVERRIDE]          = CreateConVar("zp_log_error_override",             "1",                                                               "Always log error messages no matter what logging flags or modules filters that are enabled [0-no // 1-yes]");
    gCvarList[CVAR_LOG_PRINT_CHAT]              = CreateConVar("zp_log_print_chat",                 "0",                                                               "Print log events to public chat in addition to the log file [0-no // 1-yes]");

    // =========================== //
    //          Jump boost         //
    // =========================== //
    gCvarList[CVAR_JUMPBOOST_ENABLE]            = CreateConVar("zp_jumpboost_enable",               "1",                                                               "Enable jump boost [0-no // 1-yes]");
    gCvarList[CVAR_JUMPBOOST_MULTIPLIER]        = CreateConVar("zp_jumpboost_multiplier",           "1.1",                                                             "Multiplier with power of jump");
    gCvarList[CVAR_JUMPBOOST_MAX]               = CreateConVar("zp_jumpboost_max",                  "300.0",                                                           "Maximum speed, which allow to increse jump");

    // =========================== //
    //           Humans            //
    // =========================== //
    gCvarList[CVAR_HUMAN_CLASS_MENU]            = CreateConVar("zp_human_class_menu",               "0",                                                               "Enable human class menu on a humanize with instant class change for 10 seconds [0-no // 1-yes]");
    gCvarList[CVAR_HUMAN_ARMOR_PROTECT]         = CreateConVar("zp_human_armor_protect",            "1",                                                               "Armor needs to be reduced completely in order to get infected ? [0-no // 1-yes]"); 
    gCvarList[CVAR_HUMAN_LAST_INFECTION]        = CreateConVar("zp_human_last_infection",           "1",                                                               "Allow last human to be infected [0-no // 1-yes]"); 
    gCvarList[CVAR_HUMAN_INF_AMMUNITION]        = CreateConVar("zp_human_inf_ammunition",           "1",                                                               "Give unlimited amount of ammunition for humans [0-disabled // 1-BP ammunition // 2-clip ammunition]");
    gCvarList[CVAR_HUMAN_PRICE_AMMUNITION]      = CreateConVar("zp_human_price_ammunition",         "1",                                                               "Clip price of the ammunition for humans, if unlimited amount is off [0-disabled]");

    // =========================== //
    //           Survivor          //
    // =========================== // 
    gCvarList[CVAR_SURVIVOR_SPEED]              = CreateConVar("zp_survivor_speed",                 "1.3",                                                             "Speed"); 
    gCvarList[CVAR_SURVIVOR_GRAVITY]            = CreateConVar("zp_survivor_gravity",               "0.8",                                                             "Gravity"); 
    gCvarList[CVAR_SURVIVOR_HEALTH]             = CreateConVar("zp_survivor_health",                "200",                                                             "Health [player count*health ratio]"); 
    gCvarList[CVAR_SURVIVOR_INF_AMMUNITION]     = CreateConVar("zp_survivor_inf_ammunition",        "1",                                                               "Give unlimited amount of ammunition for survivors [0-disabled // 1-BP ammunition // 2-clip ammunition]");
    gCvarList[CVAR_SURVIVOR_PRICE_AMMUNITION]   = CreateConVar("zp_survivor_price_ammunition",      "1",                                                               "Clip price of the ammunition for survivors, if unlimited amount is off [0-disabled]");
    gCvarList[CVAR_SURVIVOR_PLAYER_MODEL]       = CreateConVar("zp_survivor_model",                 "models/player/custom_player/legacy/tm_phoenix_heavy.mdl",         "Player model. This model files/textures will be automatically precache");
    gCvarList[CVAR_SURVIVOR_ARM_MODEL]          = CreateConVar("zp_survivor_arm",                   "models/player/custom_player/zombie/arms/male_arms.mdl",           "Arm skin model for standart weapons. This model files/textures will be automatically precache");
    
    // =========================== //
    //            Zombies          //
    // =========================== //
    gCvarList[CVAR_ZOMBIE_CLASS_MENU]           = CreateConVar("zp_zombie_class_menu",              "0",                                                               "Enable zombie class menu on an infection with instant class change for 10 seconds [0-no // 1-yes]");
    gCvarList[CVAR_ZOMBIE_FISRT_HEALTH]         = CreateConVar("zp_zombie_additional_health",       "100",                                                             "Additional health to first zombie [player count*health ratio]"); 
    gCvarList[CVAR_ZOMBIE_NIGHT_VISION]         = CreateConVar("zp_zombie_nvg_give",                "1",                                                               "Enable custom nightvision [0-no // 1-yes]"); 
    gCvarList[CVAR_ZOMBIE_XRAY]                 = CreateConVar("zp_zombie_xray_give",               "1",                                                               "Enable custom x-ray for viewing through walls [0-no // 1-yes]"); 
    gCvarList[CVAR_ZOMBIE_CROSSHAIR]            = CreateConVar("zp_zombie_crosshair_give",          "0",                                                               "Enable crosshair on weapons [0-no // 1-yes]"); 
    gCvarList[CVAR_ZOMBIE_RESTORE]              = CreateConVar("zp_zombie_restore",                 "0",                                                               "Enable restoring health, when zombie don't moving [0-no // 1-yes]");   

    // =========================== //
    //            Nemesis          //
    // =========================== //
    gCvarList[CVAR_NEMESIS_SPEED]               = CreateConVar("zp_nemesis_speed",                  "1.5",                                                             "Speed"); 
    gCvarList[CVAR_NEMESIS_GRAVITY]             = CreateConVar("zp_nemesis_gravity",                "0.8",                                                             "Gravity"); 
    gCvarList[CVAR_NEMESIS_HEALTH]              = CreateConVar("zp_nemesis_health_ratio",           "1000",                                                            "Health [player count*health ratio]"); 
    gCvarList[CVAR_NEMESIS_KNOCKBACK]           = CreateConVar("zp_nemesis_knockback",              "0",                                                               "Nemesis knockback [0-no // 1-yes]"); 
    gCvarList[CVAR_NEMESIS_PLAYER_MODEL]        = CreateConVar("zp_nemesis_model",                  "models/player/custom_player/zombie/zombie_bomb/zombie_bomb.mdl",  "Player model. This model files will be automatically precache, just add model textures files into downloads.ini"); 

    // =========================== //
    //           Leap jump         //
    // =========================== //
    gCvarList[CVAR_LEAP_ZOMBIE]                 = CreateConVar("zp_leap_zombies",                   "0",                                                               "Give leap to zombies [0-disabled // 1-enabled // 2-only if zombie alone]");
    gCvarList[CVAR_LEAP_ZOMBIE_FORCE]           = CreateConVar("zp_leap_zombies_force",             "500.0",                                                           "Force multiplier");
    gCvarList[CVAR_LEAP_ZOMBIE_COUNTDOWN]       = CreateConVar("zp_leap_zombies_cooldown",          "5.0",                                                             "Time between leap uses");
    gCvarList[CVAR_LEAP_NEMESIS]                = CreateConVar("zp_leap_nemesis",                   "1",                                                               "Give leap to nemesis [0-disabled // 1-enabled // 2-only if zombie alone]");
    gCvarList[CVAR_LEAP_NEMESIS_FORCE]          = CreateConVar("zp_leap_nemesis_force",             "500.0",                                                           "Force multiplier");
    gCvarList[CVAR_LEAP_NEMESIS_COUNTDOWN]      = CreateConVar("zp_leap_nemesis_cooldown",          "5.0",                                                             "Time between leap uses");
    gCvarList[CVAR_LEAP_SURVIVOR]               = CreateConVar("zp_leap_survivor",                  "0",                                                               "Give leap to survivor [0-disabled // 1-enabled // 2-only if zombie alone]");
    gCvarList[CVAR_LEAP_SURVIVOR_FORCE]         = CreateConVar("zp_leap_survivor_force",            "500.0",                                                           "Force multiplier");
    gCvarList[CVAR_LEAP_SURVIVOR_COUNTDOWN]     = CreateConVar("zp_leap_survivor_cooldown",         "5.0",                                                             "Time between leap uses");
    
    // =========================== //
    //           Bonuses           //
    // =========================== //
    gCvarList[CVAR_BONUS_CONNECT]               = CreateConVar("zp_bonus_connection",               "50",                                                              "Ammo packs given on first connection"); 
    gCvarList[CVAR_BONUS_INFECT]                = CreateConVar("zp_bonus_infect",                   "1",                                                               "Ammo packs given to zombie for infecting"); 
    gCvarList[CVAR_BONUS_INFECT_HEALTH]         = CreateConVar("zp_bonus_infect_health",            "500",                                                             "How much health a zombie regains with every infection"); 
    gCvarList[CVAR_BONUS_KILL_HUMAN]            = CreateConVar("zp_bonus_kill_human",               "1",                                                               "Ammo packs given to zombie for killing human"); 
    gCvarList[CVAR_BONUS_KILL_ZOMBIE]           = CreateConVar("zp_bonus_kill_zombie",              "1",                                                               "Ammo packs given to human for killing zombie"); 
    gCvarList[CVAR_BONUS_KILL_NEMESIS]          = CreateConVar("zp_bonus_kill_nemesis",             "10",                                                              "Ammo packs given to human for killing nemesis"); 
    gCvarList[CVAR_BONUS_KILL_SURVIVOR]         = CreateConVar("zp_bonus_kill_survivor",            "10",                                                              "Ammo packs given to zombie for killing survivor"); 
    gCvarList[CVAR_BONUS_DAMAGE_HUMAN]          = CreateConVar("zp_bonus_damage_human",             "500",                                                             "How much damage humans must deal on zombies to get an ammo pack");
    gCvarList[CVAR_BONUS_DAMAGE_ZOMBIE]         = CreateConVar("zp_bonus_damage_zombie",            "200",                                                             "How much damage zombie must deal on human to get an ammo pack");
    gCvarList[CVAR_BONUS_DAMAGE_SURVIVOR]       = CreateConVar("zp_bonus_damage_survivor",          "2000",                                                            "How much damage survivor must deal on zombies to get an ammo pack"); 
    gCvarList[CVAR_BONUS_ZOMBIE_WIN]            = CreateConVar("zp_bonus_zombie_win",               "3",                                                               "Amount of ammopacks, for winning round, if you a zombie"); 
    gCvarList[CVAR_BONUS_ZOMBIE_FAIL]           = CreateConVar("zp_bonus_zombie_fail",              "2",                                                               "Amount of ammopacks, for losing round, if you a zombie"); 
    gCvarList[CVAR_BONUS_ZOMBIE_DRAW]           = CreateConVar("zp_bonus_zombie_draw",              "1",                                                               "Amount of ammopacks, for drawing round, if you a zombie"); 
    gCvarList[CVAR_BONUS_HUMAN_WIN]             = CreateConVar("zp_bonus_human_win",                "3",                                                               "Amount of ammopacks, for winning round, if you a human"); 
    gCvarList[CVAR_BONUS_HUMAN_FAIL]            = CreateConVar("zp_bonus_human_fail",               "2",                                                               "Amount of ammopacks, for losing round, if you a human"); 
    gCvarList[CVAR_BONUS_HUMAN_DRAW]            = CreateConVar("zp_bonus_human_draw",               "1",                                                               "Amount of ammopacks, for drawing round, if you a human"); 
    gCvarList[CVAR_BONUS_HUD_ACCOUNT_R]         = CreateConVar("zp_bonus_hud_account_R",            "255",                                                             "Color of account hud (Red)");
    gCvarList[CVAR_BONUS_HUD_ACCOUNT_G]         = CreateConVar("zp_bonus_hud_account_G",            "255",                                                             "Color of account hud (Green)"); 
    gCvarList[CVAR_BONUS_HUD_ACCOUNT_B]         = CreateConVar("zp_bonus_hud_account_B",            "255",                                                             "Color of account hud (Blue)");   
    
    // =========================== //
    //         Level System        //
    // =========================== //
    gCvarList[CVAR_LEVEL_SYSTEM]                = CreateConVar("zp_level_system",                   "1",                                                               "Enable level system [0-no // 1-yes]"); 
    gCvarList[CVAR_LEVEL_STATISTICS]            = CreateConVar("zp_level_statistics",               "0 100 200 300 400 500 600 700 800 900 1000",                      "Exps required to reach level [\"0 1 2 3 4 5 6 7 8 9 10\" - in the string divided by ' '] Can be possibly increase to higher number. First 0 ~ is vital and shown empty level"); 
    gCvarList[CVAR_LEVEL_HEALTH_RATIO]          = CreateConVar("zp_level_health_ratio",             "10.0",                                                            "Health multiplier for each level (health += health_ratio*level)"); 
    gCvarList[CVAR_LEVEL_SPEED_RATIO]           = CreateConVar("zp_level_speed_ratio",              "0.01",                                                            "Speed multiplier for each level (speed += speed_ratio*level)"); 
    gCvarList[CVAR_LEVEL_GRAVITY_RATIO]         = CreateConVar("zp_level_gravity_ratio",            "0.01",                                                            "Gravity multiplier for each level (gravity += gravity_ratio*level)"); 
    gCvarList[CVAR_LEVEL_DAMAGE_RATIO]          = CreateConVar("zp_level_damage_ratio",             "0.1",                                                             "Damage multiplier for each level (damage *= damage_ratio*level+1.0)"); 
    gCvarList[CVAR_LEVEL_DAMAGE_HUMAN]          = CreateConVar("zp_level_damage_human",             "500",                                                             "How much damage humans must deal on zombies to get an one exp");
    gCvarList[CVAR_LEVEL_DAMAGE_ZOMBIE]         = CreateConVar("zp_level_damage_zombie",            "200",                                                             "How much damage zombie must deal on human to get an one exp");
    gCvarList[CVAR_LEVEL_DAMAGE_SURVIVOR]       = CreateConVar("zp_level_damage_survivor",          "2000",                                                            "How much damage survivor must deal on zombies to get an one exp");
    gCvarList[CVAR_LEVEL_INFECT]                = CreateConVar("zp_level_infect",                   "1",                                                               "Exps given to zombie for infecting"); 
    gCvarList[CVAR_LEVEL_KILL_HUMAN]            = CreateConVar("zp_level_kill_human",               "1",                                                               "Exps given to zombie for killing human"); 
    gCvarList[CVAR_LEVEL_KILL_ZOMBIE]           = CreateConVar("zp_level_kill_zombie",              "1",                                                               "Exps given to human for killing zombie"); 
    gCvarList[CVAR_LEVEL_KILL_NEMESIS]          = CreateConVar("zp_level_kill_nemesis",             "10",                                                              "Exps given to human for killing nemesis"); 
    gCvarList[CVAR_LEVEL_KILL_SURVIVOR]         = CreateConVar("zp_level_kill_survivor",            "10",                                                              "Exps given to zombie for killing survivor"); 
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_R]          = CreateConVar("zp_level_hud_zombie_R",             "255",                                                             "Color of zombie hud (Red)");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_G]          = CreateConVar("zp_level_hud_zombie_G",             "0",                                                               "Color of zombie hud (Green)");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_B]          = CreateConVar("zp_level_hud_zombie_B",             "0",                                                               "Color of zombie hud (Blue)");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_R]           = CreateConVar("zp_level_hud_human_R",              "0",                                                               "Color of human hud (Red)");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_G]           = CreateConVar("zp_level_hud_human_G",              "255",                                                             "Color of human hud (Green)");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_B]           = CreateConVar("zp_level_hud_human_B",              "0",                                                               "Color of human hud (Blue)");

    // =========================== //
    //         Deathmatch          //
    // =========================== //
    gCvarList[CVAR_RESPAWN_DEATHMATCH]          = CreateConVar("zp_deathmatch",                     "0",                                                               "Deathmatch mode during normal rounds, respawn as: [0-zombie // 1-human // 2-randomly // 3-balance]");
    gCvarList[CVAR_RESPAWN_SUICIDE]             = CreateConVar("zp_suicide",                        "0",                                                               "Allow kill or suicide command [0-no // 1-yes]");
    gCvarList[CVAR_RESPAWN_AMOUNT]              = CreateConVar("zp_respawn_amount",                 "5",                                                               "Times of respawn for zombie on normal infection mode"); 
    gCvarList[CVAR_RESPAWN_TIME]                = CreateConVar("zp_respawn_time",                   "5.0",                                                             "Delay before respawning on deathmatch mode in seconds"); 
    gCvarList[CVAR_RESPAWN_WORLD]               = CreateConVar("zp_respawn_on_suicide",             "1",                                                               "Respawn players if they commited suicide [0-no // 1-yes]");
    gCvarList[CVAR_RESPAWN_LAST]                = CreateConVar("zp_respawn_after_last_human",       "1",                                                               "Respawn players if only the last human/zombie is left [0-no // 1-yes]"); 
    gCvarList[CVAR_RESPAWN_ZOMBIE]              = CreateConVar("zp_respawn_zombies",                "1",                                                               "Whether to respawn killed zombies [0-no // 1-yes]");
    gCvarList[CVAR_RESPAWN_HUMAN]               = CreateConVar("zp_respawn_humans",                 "0",                                                               "Whether to respawn killed humans [0-no // 1-yes]"); 
    gCvarList[CVAR_RESPAWN_NEMESIS]             = CreateConVar("zp_respawn_nemesis",                "1",                                                               "Whether to respawn killed nemesis [0-no // 1-yes]"); 
    gCvarList[CVAR_RESPAWN_SURVIVOR]            = CreateConVar("zp_respawn_survivor",               "1",                                                               "Whether to respawn killed survivors [0-no // 1-yes]");

    // =========================== //
    //         Visual Effects      //
    // =========================== //
    gCvarList[CVAR_VEFFECTS_SHAKE]              = CreateConVar("zp_veffects_shake",                 "1",                                                               "Screen shake for infected player [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_SHAKE_AMP]          = CreateConVar("zp_veffects_shake_amp",             "15.0",                                                            "Amplitude of shaking effect");
    gCvarList[CVAR_VEFFECTS_SHAKE_FREQUENCY]    = CreateConVar("zp_veffects_shake_frequency",       "1.0",                                                             "Frequency of shaking effect");
    gCvarList[CVAR_VEFFECTS_SHAKE_DURATION]     = CreateConVar("zp_veffects_shake_duration",        "5.0",                                                             "Duration of shaking effect"); 
    gCvarList[CVAR_VEFFECTS_FADE]               = CreateConVar("zp_veffects_fade",                  "1",                                                               "Screen fade for restoring health player [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_FADE_TIME]          = CreateConVar("zp_veffects_fade_time",             "0.7",                                                             "Holding time of fade effect"); 
    gCvarList[CVAR_VEFFECTS_FADE_DURATION]      = CreateConVar("zp_veffects_fade_duration",         "0.2",                                                             "Duration of fade effect"); 
    
    // =========================== //
    //       Partical Effects      //
    // =========================== //
    gCvarList[CVAR_VEFFECTS_PARTICLES]          = CreateConVar("zp_veffects_particles",             "1",                                                               "Enable custom particle effects. Can cause the performance a lot [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_RESPAWN]            = CreateConVar("zp_veffects_respawn",               "1",                                                               "Partical effect on re-spawn [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_RESPAWN_NAME]       = CreateConVar("zp_veffects_respawn_name",          "spiral_spiral_akskkk",                                            "Name of partical effect (Not a path, each '.pcf' have a name inside) For standart particles. Look here: https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles");
    gCvarList[CVAR_VEFFECTS_RESPAWN_ATTACH]     = CreateConVar("zp_veffects_respawn_attachment",    "",                                                                "Attachment of re-spawn effect [\"\"-client position // \"eholster\"-model attachment name] "); 
    gCvarList[CVAR_VEFFECTS_RESPAWN_DURATION]   = CreateConVar("zp_veffects_respawn_duration",      "1.0",                                                             "Duration of re-spawn effect");
    gCvarList[CVAR_VEFFECTS_INFECT]             = CreateConVar("zp_veffects_infect",                "1",                                                               "Partical effect on infect [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_INFECT_NAME]        = CreateConVar("zp_veffects_infect_name",           "fire_vixr_final",                                                 "Name of partical effect (Not a path, each '.pcf' have a name inside) For standart particles. Look here: https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles");
    gCvarList[CVAR_VEFFECTS_INFECT_ATTACH]      = CreateConVar("zp_veffects_infect_attachment",     "",                                                                "Attachment of infect effect [\"\"-client position // \"eholster\"-model attachment name]"); 
    gCvarList[CVAR_VEFFECTS_INFECT_DURATION]    = CreateConVar("zp_veffects_infect_duration",       "1.0",                                                             "Duration of infect effect");
    gCvarList[CVAR_VEFFECTS_ANTIDOT]            = CreateConVar("zp_veffects_antidot",               "1",                                                               "Partical effect on humanize [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_ANTIDOT_NAME]       = CreateConVar("zp_veffects_antidot_name",          "cubecolor",                                                       "Name of partical effect (Not a path, each '.pcf' have a name inside) For standart particles. Look here: https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles");
    gCvarList[CVAR_VEFFECTS_ANTIDOT_ATTACH]     = CreateConVar("zp_veffects_antidot_attachment",    "",                                                                "Attachment of humanize effect [\"\"-client position // \"eholster\"-model attachment name]"); 
    gCvarList[CVAR_VEFFECTS_ANTIDOT_DURATION]   = CreateConVar("zp_veffects_antidot_duration",      "1.0",                                                             "Duration of humanize effect");
    gCvarList[CVAR_VEFFECTS_HEAL]               = CreateConVar("zp_veffects_heal",                  "1",                                                               "Partical effect on healing [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_HEAL_NAME]          = CreateConVar("zp_veffects_heal_name",             "heal_ss",                                                         "Name of partical effect (Not a path, each '.pcf' have a name inside) For standart particles. Look here: https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles");
    gCvarList[CVAR_VEFFECTS_HEAL_ATTACH]        = CreateConVar("zp_veffects_heal_attachment",       "",                                                                "Attachment of healing effect [\"\"-client position // \"eholster\"-model attachment name]"); 
    gCvarList[CVAR_VEFFECTS_HEAL_DURATION]      = CreateConVar("zp_veffects_heal_duration",         "1.0",                                                             "Duration of healing effect");
    gCvarList[CVAR_VEFFECTS_NEMESIS]            = CreateConVar("zp_veffects_nemesis",               "1",                                                               "Partical effect on nemesis [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_NEMESIS_NAME]       = CreateConVar("zp_veffects_nemesis_name",          "end",                                                             "Name of partical effect (Not a path, each '.pcf' have a name inside) For standart particles. Look here: https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles");
    gCvarList[CVAR_VEFFECTS_NEMESIS_ATTACH]     = CreateConVar("zp_veffects_nemesis_attachment",    "",                                                                "Attachment of nemesis effect [\"\"-client position // \"eholster\"-model attachment name]"); 
    gCvarList[CVAR_VEFFECTS_NEMESIS_DURATION]   = CreateConVar("zp_veffects_nemesis_duration",      "9999.9",                                                          "Duration of nemesis effect");
    gCvarList[CVAR_VEFFECTS_SURVIVOR]           = CreateConVar("zp_veffects_survivor",              "1",                                                               "Partical effect on survivor [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_SURVIVOR_NAME]      = CreateConVar("zp_veffects_survivor_name",         "molnii_final",                                                    "Name of partical effect (Not a path, each '.pcf' have a name inside) For standart particles. Look here: https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles");
    gCvarList[CVAR_VEFFECTS_SURVIVOR_ATTACH]    = CreateConVar("zp_veffects_survivor_attachment",   "",                                                                "Attachment of survivor effect [\"\"-client position // \"eholster\"-model attachment name]"); 
    gCvarList[CVAR_VEFFECTS_SURVIVOR_DURATION]  = CreateConVar("zp_veffects_survivor_duration",     "9999.9",                                                          "Duration of survivor effect");
    gCvarList[CVAR_VEFFECTS_LEAP]               = CreateConVar("zp_veffects_leap",                  "1",                                                               "Partical effect on leap-jump [0-no // 1-yes]"); 
    gCvarList[CVAR_VEFFECTS_LEAP_NAME]          = CreateConVar("zp_veffects_leap_name",             "block_trail_xzaa",                                                "Name of partical effect (Not a path, each '.pcf' have a name inside) For standart particles. Look here: https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles");
    gCvarList[CVAR_VEFFECTS_LEAP_ATTACH]        = CreateConVar("zp_veffects_leap_attachment",       "",                                                                "Attachment of leap-jump effect [\"\"-client position // \"eholster\"-model attachment name]"); 
    gCvarList[CVAR_VEFFECTS_LEAP_DURATION]      = CreateConVar("zp_veffects_leap_duration",         "1.5",                                                             "Duration of leap-jump effect");
    
    // =========================== //
    //               Sky           //
    // =========================== //
    gCvarList[CVAR_VEFFECTS_SKYNAME]            = FindConVar("sv_skyname");
    gCvarList[CVAR_VEFFECTS_LIGHTSTYLE]         = CreateConVar("zp_veffects_lightstyle",            "1",                                                               "Change lightstyle (brightness) of the map [0-no // 1-yes]");
    gCvarList[CVAR_VEFFECTS_LIGHTSTYLE_VALUE]   = CreateConVar("zp_veffects_lightstyle_value",      "b",                                                               "Lightstyle value ['b' = Darkest | 'z' = Brightest]");
    gCvarList[CVAR_VEFFECTS_SKY]                = CreateConVar("zp_veffects_sky",                   "1",                                                               "Change map skybox [0-no // 1-yes] ");
    gCvarList[CVAR_VEFFECTS_SKY_PATH]           = CreateConVar("zp_veffects_sky_path",              "jungle",                                                          "Skybox name. Look here: https://developer.valvesoftware.com/wiki/Sky_List");
    gCvarList[CVAR_VEFFECTS_SUN_DISABLE]        = CreateConVar("zp_veffects_sun_disable",           "1",                                                               "Disable sun rendering on map [0-no // 1-yes]");

    // =========================== //
    //              Fog            //
    // =========================== //
    gCvarList[CVAR_VEFFECTS_FOG]                = CreateConVar("zp_veffects_fog",                   "1",                                                               "Enable fog rendering on the map [0-no // 1-yes]");
    gCvarList[CVAR_VEFFECTS_FOG_COLOR]          = CreateConVar("zp_veffects_fog_color",             "200 200 200",                                                     "Primary and secondary color of the fog");
    gCvarList[CVAR_VEFFECTS_FOG_DENSITY]        = CreateConVar("zp_veffects_fog_density",           "0.2",                                                             "Density (thickness) of the fog");
    gCvarList[CVAR_VEFFECTS_FOG_STARTDIST]      = CreateConVar("zp_veffects_fog_startdist",         "300",                                                             "Distance from player to start rendering foremost fog");
    gCvarList[CVAR_VEFFECTS_FOG_ENDDIST]        = CreateConVar("zp_veffects_fog_enddist",           "1200",                                                            "Distance from player to stop rendering fog");
    gCvarList[CVAR_VEFFECTS_FOG_FARZ]           = CreateConVar("zp_veffects_fog_farz",              "4000",                                                            "Vertical clipping plane. Look here: https://developer.valvesoftware.com/wiki/Env_fog_controller");

    // =========================== //
    //             Ragdoll         //
    // =========================== //
    gCvarList[CVAR_VEFFECTS_RAGDOLL_REMOVE]     = CreateConVar("zp_veffects_ragdoll_remove",        "1",                                                               "Remove players' ragdolls from the game after a delay");
    gCvarList[CVAR_VEFFECTS_RAGDOLL_DISSOLVE]   = CreateConVar("zp_veffects_ragdoll_dissolve",      "-1",                                                              "The ragdoll removal effect. ['-2' = Effectless removal | '-1' = Random effect | '0' = Energy dissolve | '1' = Heavy electrical dissolve | '2' = Light electrical dissolve | '3' = Core dissolve]");
    gCvarList[CVAR_VEFFECTS_RAGDOLL_DELAY]      = CreateConVar("zp_veffects_ragdoll_delay",         "0.5",                                                             "Time to wait before removing the ragdoll");

    // =========================== //
    //           Resources         //
    // =========================== //
    gCvarList[CVAR_VEFFECTS_HUD_ZOMBIE]         = CreateConVar("zp_veffects_hud_zombie",            "overlays/zp/zg_zombies_win.vmt",                                   "[\"\"-disabled] Overlay (.vmt), relative to \"materials\" folder, to display when zombies win the round. This file is automatically downloaded to clients"); 
    gCvarList[CVAR_VEFFECTS_HUD_HUMAN]          = CreateConVar("zp_veffects_hud_human",             "overlays/zp/zg_humans_win.vmt",                                    "[\"\"-disabled] Overlay (.vmt), relative to \"materials\" folder, to display when humans win the round. This file is automatically downloaded to clients");
    gCvarList[CVAR_VEFFECTS_HUD_DRAW]           = CreateConVar("zp_veffects_hud_draw",              "",                                                                 "[\"\"-disabled] Overlay (.vmt), relative to \"materials\" folder, to display when the round draw. This file is automatically downloaded to clients");
    gCvarList[CVAR_VEFFECTS_HUD_VISION]         = CreateConVar("zp_veffects_hud_vision",            "overlays/zp/zvision.vmt",                                          "[\"\"-default nightvision] Overlay (.vmt), relative to \"materials\" folder, to display when humans win the round. This file is automatically downloaded to clients");
    
    // =========================== //
    //         Sound Effects       //
    // =========================== //
    gCvarList[CVAR_SEFFECTS_ALLTALK]            = FindConVar("sv_alltalk");
    gCvarList[CVAR_SEFFECTS_VOICE]              = CreateConVar("zp_seffects_voice",                 "0",                                                               "Modify sv_alltalk to obey zombie/human teams instead of t/ct");
    gCvarList[CVAR_SEFFECTS_VOICE_ZOMBIES_MUTE] = CreateConVar("zp_seffects_voice_zombies_mute",    "0",                                                               "Only allow humans to communicate, block verbal zombie communication");
    gCvarList[CVAR_SEFFECTS_INFECT]             = CreateConVar("zp_seffects_infect",                "1",                                                               "Emit a infect sound when a human become zombie");
    gCvarList[CVAR_SEFFECTS_MOAN]               = CreateConVar("zp_seffects_moan",                  "30.0",                                                            "Time between emission of a moan sound from a zombie");
    gCvarList[CVAR_SEFFECTS_GROAN]              = CreateConVar("zp_seffects_groan",                 "5",                                                               "The probability that a groan sound will be emitted from a zombie when shot/burn. ['100' = 1% chance | '50' = 2% chance | '1' = 100% chance]");
    gCvarList[CVAR_SEFFECTS_BURN]               = CreateConVar("zp_seffects_burn",                  "1",                                                               "Emit a burn sound when a zombie on fire");
    gCvarList[CVAR_SEFFECTS_DEATH]              = CreateConVar("zp_seffects_death",                 "1",                                                               "Emit a death sound when a zombie dies");
    gCvarList[CVAR_SEFFECTS_FOOTSTEPS]          = CreateConVar("zp_seffects_footsteps",             "1",                                                               "Emit a footstep sound when a zombie walks");
    gCvarList[CVAR_SEFFECTS_CLAWS]              = CreateConVar("zp_seffects_claws",                 "1",                                                               "Emit a claw sound when a zombie attacks");
    gCvarList[CVAR_SEFFECTS_SURVIVOR_INFECT]    = CreateConVar("zp_seffects_survivor_infect",       "SURVIVOR_INFECTION_SOUNDS",                                       "The key block for survivor infect sounds");
    gCvarList[CVAR_SEFFECTS_SURVIVOR_HURT]      = CreateConVar("zp_seffects_survivor_hurt",         "SURVIVOR_HURT_SOUNDS",                                            "The key block for survivor hurt sounds");
    gCvarList[CVAR_SEFFECTS_SURVIVOR_DEATH]     = CreateConVar("zp_seffects_survivor_death",        "SURVIVOR_DEATH_SOUNDS",                                           "The key block for survivor death sounds");
    gCvarList[CVAR_SEFFECTS_NEMESIS_IDLE]       = CreateConVar("zp_seffects_nemesis_idle",          "NEMESIS_IDLE_SOUNDS",                                             "The key block for nemesis idle sounds"); 
    gCvarList[CVAR_SEFFECTS_NEMESIS_HURT]       = CreateConVar("zp_seffects_nemesis_hurt",          "NEMESIS_HURT_SOUNDS",                                             "The key block for nemesis hurt sounds");  
    gCvarList[CVAR_SEFFECTS_NEMESIS_DEATH]      = CreateConVar("zp_seffects_nemesis_death",         "NEMESIS_DEATH_SOUNDS",                                            "The key block for nemesis death sounds"); 
    gCvarList[CVAR_SEFFECTS_NEMESIS_BURN]       = CreateConVar("zp_seffects_nemesis_burn",          "NEMESIS_BURN_SOUNDS",                                             "The key block for nemesis burn sounds");
    gCvarList[CVAR_SEFFECTS_NEMESIS_FOOTSTEP]   = CreateConVar("zp_seffects_nemesis_footstep",      "NEMESIS_FOOTSTEP_SOUNDS",                                         "The key block for nemesis footstep sounds"); 
    gCvarList[CVAR_SEFFECTS_NEMESIS_RESPAWN]    = CreateConVar("zp_seffects_nemesis_respawn",       "NEMESIS_RESPAWN_SOUNDS",                                          "The key block for nemesis respawn sounds"); 
    gCvarList[CVAR_SEFFECTS_NEMESIS_ATTACK]     = CreateConVar("zp_seffects_nemesis_attack",        "NEMESIS_ATTACK_SOUNDS",                                           "The key block for nemesis attack sounds");
    gCvarList[CVAR_SEFFECTS_PLAYER_FLASHLIGHT]  = CreateConVar("zp_seffects_player_flashlight",     "FLASH_LIGHT_SOUNDS",                                              "The key block for player flashlight sounds");  
    gCvarList[CVAR_SEFFECTS_PLAYER_AMMUNITION]  = CreateConVar("zp_seffects_player_ammunition",     "AMMUNITION_BUY_SOUNDS",                                           "The key block for player ammunition sounds");
    gCvarList[CVAR_SEFFECTS_PLAYER_LEVEL]       = CreateConVar("zp_seffects_player_level",          "LEVEL_UP_SOUNDS",                                                 "The key block for player levelup sounds");
    gCvarList[CVAR_SEFFECTS_ROUND_START]        = CreateConVar("zp_seffects_round_start",           "ROUND_START_SOUNDS",                                              "The key block for round start sounds");   
    gCvarList[CVAR_SEFFECTS_ROUND_COUNT]        = CreateConVar("zp_seffects_round_count",           "ROUND_COUNTER_SOUNDS",                                            "The key block for round counter sounds");   
    gCvarList[CVAR_SEFFECTS_ROUND_ZOMBIE]       = CreateConVar("zp_seffects_round_zombie",          "ROUND_ZOMBIE_SOUNDS",                                             "The key block for round zombie sounds");
    gCvarList[CVAR_SEFFECTS_ROUND_HUMAN]        = CreateConVar("zp_seffects_round_human",           "ROUND_HUMAN_SOUNDS",                                              "The key block for round human sounds");  
    gCvarList[CVAR_SEFFECTS_ROUND_DRAW]         = CreateConVar("zp_seffects_round_draw",            "ROUND_DRAW_SOUNDS",                                               "The key block for round draw sounds");  
    
    // =========================== //
    //            Messages         //
    // =========================== //
    gCvarList[CVAR_MESSAGES_HELP]               = CreateConVar("zp_messages_help",                  "1",                                                               "Enable help messages [0-no // 1-yes]");
    gCvarList[CVAR_MESSAGES_BLOCK]              = CreateConVar("zp_messages_block",                 "Player_Cash_Award_Team_Cash_Award_Player_Point_Award_Match_Will_Start_Chat_SavePlayer_YouDroppedWeapon_CannotDropWeapon", "List of standart engine messages and notifications for blocking. Look here: ../Counter-Strike Global Offensive/csgo/resource/csgo_*.txt");

    // =========================== //
    //     Additional settings     //
    // =========================== //
    gCvarList[CVAR_CT_DEFAULT_GRENADES]         = FindConVar("mp_ct_default_grenades");
    gCvarList[CVAR_CT_DEFAULT_MELEE]            = FindConVar("mp_ct_default_melee");
    gCvarList[CVAR_CT_DEFAULT_SECONDARY]        = FindConVar("mp_ct_default_secondary");
    gCvarList[CVAR_CT_DEFAULT_PRIMARY]          = FindConVar("mp_ct_default_primary");
    gCvarList[CVAR_T_DEFAULT_GRENADES]          = FindConVar("mp_t_default_grenades");
    gCvarList[CVAR_T_DEFAULT_MELEE]             = FindConVar("mp_t_default_melee");
    gCvarList[CVAR_T_DEFAULT_SECONDARY]         = FindConVar("mp_t_default_secondary");
    gCvarList[CVAR_T_DEFAULT_PRIMARY]           = FindConVar("mp_t_default_primary");
    gCvarList[CVAR_H_DEFAULT_EQUIPMENT]         = CreateConVar("mp_h_default_equipment",            "",                                                                "Default equipment for human [\"hegrenade, freeze grenade ...\" - in the string divided by ',']");
    gCvarList[CVAR_H_DEFAULT_MELEE]             = CreateConVar("mp_h_default_melee",                "knife",                                                           "Default knife for human");
    gCvarList[CVAR_H_DEFAULT_SECONDARY]         = CreateConVar("mp_h_default_secondary",            "",                                                                "Default secondaty for human");
    gCvarList[CVAR_H_DEFAULT_PRIMARY]           = CreateConVar("mp_h_default_primary",              "",                                                                "Default primary for human");
    gCvarList[CVAR_Z_DEFAULT_EQUIPMENT]         = CreateConVar("mp_z_default_equipment",            "",                                                                "Default equipment for zombie [\"hegrenade, ...\" - in the string divided by ',']");
    gCvarList[CVAR_Z_DEFAULT_MELEE]             = CreateConVar("mp_z_default_melee",                "zombie claw",                                                     "Default knife for zombie");
    gCvarList[CVAR_Z_DEFAULT_SECONDARY]         = CreateConVar("mp_z_default_secondary",            "",                                                                "Default secondaty for zombie");
    gCvarList[CVAR_Z_DEFAULT_PRIMARY]           = CreateConVar("mp_z_default_primary",              "",                                                                "Default primary for zombie");
    gCvarList[CVAR_N_DEFAULT_EQUIPMENT]         = CreateConVar("mp_n_default_equipment",            "",                                                                "Default equipment for nemesis [\"hegrenade, ...\" - in the string divided by ',']");
    gCvarList[CVAR_N_DEFAULT_MELEE]             = CreateConVar("mp_n_default_melee",                "nemesis claw",                                                    "Default knife for nemesis");
    gCvarList[CVAR_N_DEFAULT_SECONDARY]         = CreateConVar("mp_n_default_secondary",            "",                                                                "Default secondaty for nemesis");
    gCvarList[CVAR_N_DEFAULT_PRIMARY]           = CreateConVar("mp_n_default_primary",              "",                                                                "Default primary for nemesis");
    gCvarList[CVAR_S_DEFAULT_EQUIPMENT]         = CreateConVar("mp_s_default_equipment",            "",                                                                "Default equipment for survivor [\"hegrenade, ...\" - in the string divided by ',']");
    gCvarList[CVAR_S_DEFAULT_MELEE]             = CreateConVar("mp_s_default_melee",                "survivor knife",                                                  "Default knife for survivor");
    gCvarList[CVAR_S_DEFAULT_SECONDARY]         = CreateConVar("mp_s_default_secondary",            "",                                                                "Default secondaty for survivor");
    gCvarList[CVAR_S_DEFAULT_PRIMARY]           = CreateConVar("mp_s_default_primary",              "",                                                                "Default primary for survivor");    
    
    // Auto-generate config file if it doesn't exist, then execute
    AutoExecConfig(true, "zombieplague");
}

/**
 * Hook cvar changes.
 **/
void CvarsHook(/*void*/)
{
    // Sets locked cvars to their locked value
    gCvarList[CVAR_SERVER_CLAMP].IntValue = 0;
    gCvarList[CVAR_SERVER_TEAM_BALANCE].IntValue = 0;
    gCvarList[CVAR_SERVER_LIMIT_TEAMS].IntValue = 0;
    gCvarList[CVAR_SERVER_CASH_AWARD].IntValue = 0;
    gCvarList[CVAR_SERVER_FRIENDLY_FIRE].IntValue = 0;
    gCvarList[CVAR_SERVER_BUY_ANYWHERE].IntValue = 0;
    gCvarList[CVAR_SERVER_WARMUP_TIME].IntValue = 0;
    gCvarList[CVAR_SERVER_WARMUP_PERIOD].IntValue = 0;
    gCvarList[CVAR_SERVER_GIVE_WEAPON].IntValue = 0;
    gCvarList[CVAR_SERVER_GIVE_TASER].IntValue = 1;
    gCvarList[CVAR_SERVER_GIVE_BOMB].IntValue = 1;
    gCvarList[CVAR_CT_DEFAULT_GRENADES].SetString("");
    gCvarList[CVAR_CT_DEFAULT_MELEE].SetString("");
    gCvarList[CVAR_CT_DEFAULT_SECONDARY].SetString("");
    gCvarList[CVAR_CT_DEFAULT_PRIMARY].SetString("");
    gCvarList[CVAR_T_DEFAULT_GRENADES].SetString("");
    gCvarList[CVAR_T_DEFAULT_MELEE].SetString("");
    gCvarList[CVAR_T_DEFAULT_SECONDARY].SetString("");
    gCvarList[CVAR_T_DEFAULT_PRIMARY].SetString("");
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_GRENADE], 0);
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_BULLETS], 0);
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_OTHER], 0);
    CvarsOnCheatSet(gCvarList[CVAR_SERVER_FRIENDLY_SELF], 0);
    
    // Hook locked cvars to prevent it from changing
    HookConVarChange(gCvarList[CVAR_SERVER_CLAMP],            CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_TEAM_BALANCE],     CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_LIMIT_TEAMS],      CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_CASH_AWARD],       CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_FIRE],    CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_BUY_ANYWHERE],     CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_WARMUP_TIME],      CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_WARMUP_PERIOD],    CvarsHookLocked);
    HookConVarChange(gCvarList[CVAR_SERVER_GIVE_WEAPON],      CvarsHookLocked);    
    HookConVarChange(gCvarList[CVAR_SERVER_GIVE_TASER],       CvarsHookUnlocked);
    HookConVarChange(gCvarList[CVAR_SERVER_GIVE_BOMB],        CvarsHookUnlocked);
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_GRENADES],     CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_MELEE],        CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_SECONDARY],    CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_CT_DEFAULT_PRIMARY],      CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_GRENADES],      CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_MELEE],         CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_SECONDARY],     CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_T_DEFAULT_PRIMARY],       CvarsHookLockedString);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_GRENADE], CvarsHookLockedCheat);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_BULLETS], CvarsHookLockedCheat);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_OTHER],   CvarsHookLockedCheat);
    HookConVarChange(gCvarList[CVAR_SERVER_FRIENDLY_SELF],    CvarsHookLockedCheat);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_ZP],     CvarsHookRoundTime);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_CS],     CvarsHookRoundTime);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUNDTIME_DE],     CvarsHookRoundTime);
    HookConVarChange(gCvarList[CVAR_SERVER_ROUND_RESTART],    CvarsHookRoundRestart);
    HookConVarChange(gCvarList[CVAR_ZOMBIE_XRAY],             CvarsHookZombieVision);
}

/**
 * Cvar hook callback.
 * Prevents changes of the normal cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookLocked(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    hConVar.IntValue = 0;
}

/**
 * Cvar hook callback.
 * Prevents changes of the normal cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookUnlocked(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    hConVar.IntValue = 1;
}

/**
 * Cvar hook callback.
 * Prevents changes of the normal cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookLockedString(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    hConVar.SetString("");
}

/**
 * Cvar hook callback.
 * Prevents changes of the cheat cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookLockedCheat(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    CvarsOnCheatSet(hConVar, 0);
}

/**
 * Cvar hook callback (mp_roundtime, mp_roundtime_hostage, mp_roundtime_defuse)
 * Prevent from long rounds.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookRoundTime(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // If cvar is mp_roundtime_hostage or mp_roundtime_defuse, then continue
    if(hConVar == gCvarList[CVAR_SERVER_ROUNDTIME_CS] || hConVar == gCvarList[CVAR_SERVER_ROUNDTIME_DE])
    {
        // Revert to specific value
        hConVar.IntValue = gCvarList[CVAR_SERVER_ROUNDTIME_ZP].IntValue;
    }
    
    // If value was invalid, then stop
    int iDelay = StringToInt(newValue);
    if(iDelay <= CvarsRoundMax)
    {
        return;
    }
    
    // Revert to minimum value
    hConVar.SetInt(CvarsRoundMax);
}

/**
 * Cvar hook callback. (mp_restartgame)
 * Stops restart and just ends the round.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookRoundRestart(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    #define ROUNDEND_GAME_COMMENCING    15  // Game Commencing!
    
    // Prevent round restart
    hConVar.IntValue = 0;

    // If value was invalid, then stop
    int iDelay = StringToInt(newValue);
    if(iDelay <= 0)
    {
        return;
    }
    
    // Resets number of rounds
    gServerData[Server_RoundNumber] = 0;
    
    // Resets score in the scoreboard
    SetTeamScore(TEAM_ZOMBIE, 0);
    SetTeamScore(TEAM_HUMAN,  0);

    // Terminate the round with restart time as delay
    ToolsTerminateRound(ROUNDEND_GAME_COMMENCING);
}

/**
 * Cvar hook callback. (zp_zombie_xray_give)
 * Enable or disable wall hack feature due to the x-ray vision.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookZombieVision(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to opposite value
    gCvarList[CVAR_SERVER_OCCULUSE].SetBool(!StringToInt(newValue));
}

/**
 * Sets the integer value of a cvar variable. (sv_cheat 1)
 *
 * @param hConVar           Handle to the convar.
 * @param iValue            New integer value.
 **/
stock void CvarsOnCheatSet(ConVar hConVar, const int iValue) 
{
    // Revert to locked value
    hConVar.Flags = hConVar.Flags & ~FCVAR_CHEAT;
    hConVar.IntValue = iValue;
    //hConVar.Flags = hConVar.Flags | FCVAR_CHEAT;  -> Sent errors to console!
}
