/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          cvars.cpp
 *  Type:          Main 
 *  Description:   Config creation and cvar control.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
enum CvarsList
{    
    ConVar:CVAR_DATABASE,
    ConVar:CVAR_ANTISTICK,
    ConVar:CVAR_COSTUMES,
    ConVar:CVAR_MENU_BUTTON,
    ConVar:CVAR_SKILL_BUTTON,
    ConVar:CVAR_LIGHT_BUTTON,
    ConVar:CVAR_HUMAN_MENU,
    ConVar:CVAR_ZOMBIE_MENU,
    
    ConVar:CVAR_HITGROUP,
    ConVar:CVAR_HITGROUP_FRIENDLY_FIRE,
    ConVar:CVAR_HITGROUP_FRIENDLY_GRENADE,
    ConVar:CVAR_HITGROUP_FRIENDLY_BULLETS,
    ConVar:CVAR_HITGROUP_FRIENDLY_OTHER,
    ConVar:CVAR_HITGROUP_FRIENDLY_SELF,
    
    ConVar:CVAR_GAMEMODE,
    ConVar:CVAR_GAMEMODE_BLAST_TIME,
    ConVar:CVAR_GAMEMODE_TEAM_BALANCE,
    ConVar:CVAR_GAMEMODE_LIMIT_TEAMS,
    ConVar:CVAR_GAMEMODE_WARMUP_TIME,
    ConVar:CVAR_GAMEMODE_WARMUP_PERIOD,
    ConVar:CVAR_GAMEMODE_ROUNDTIME_ZP,
    ConVar:CVAR_GAMEMODE_ROUNDTIME_CS,
    ConVar:CVAR_GAMEMODE_ROUNDTIME_DE,
    ConVar:CVAR_GAMEMODE_ROUND_RESTART,
    ConVar:CVAR_GAMEMODE_RESTART_DELAY,
    
    ConVar:CVAR_WEAPON_GIVE_TASER,
    ConVar:CVAR_WEAPON_GIVE_BOMB,
    ConVar:CVAR_WEAPON_ALLOW_MAP,
    ConVar:CVAR_WEAPON_CT_DEFAULT_GRENADES,
    ConVar:CVAR_WEAPON_CT_DEFAULT_MELEE,
    ConVar:CVAR_WEAPON_CT_DEFAULT_SECONDARY,
    ConVar:CVAR_WEAPON_CT_DEFAULT_PRIMARY,
    ConVar:CVAR_WEAPON_T_DEFAULT_GRENADES,
    ConVar:CVAR_WEAPON_T_DEFAULT_MELEE,
    ConVar:CVAR_WEAPON_T_DEFAULT_SECONDARY,
    ConVar:CVAR_WEAPON_T_DEFAULT_PRIMARY,

    ConVar:CVAR_LOG,
    ConVar:CVAR_LOG_MODULE_FILTER,
    ConVar:CVAR_LOG_IGNORE_CONSOLE,
    ConVar:CVAR_LOG_ERROR_OVERRIDE,
    ConVar:CVAR_LOG_PRINT_CHAT,
    
    ConVar:CVAR_JUMPBOOST,
    ConVar:CVAR_JUMPBOOST_MULTIPLIER,
    ConVar:CVAR_JUMPBOOST_MAX,
    ConVar:CVAR_JUMPBOOST_KNOCKBACK,
    
    ConVar:CVAR_LEVEL_SYSTEM,
    ConVar:CVAR_LEVEL_HEALTH_RATIO,
    ConVar:CVAR_LEVEL_SPEED_RATIO,
    ConVar:CVAR_LEVEL_GRAVITY_RATIO,
    ConVar:CVAR_LEVEL_DAMAGE_RATIO,
    ConVar:CVAR_LEVEL_HUD,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_R,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_G,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_B,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_A,
    ConVar:CVAR_LEVEL_HUD_HUMAN_R,
    ConVar:CVAR_LEVEL_HUD_HUMAN_G,
    ConVar:CVAR_LEVEL_HUD_HUMAN_B,
    ConVar:CVAR_LEVEL_HUD_HUMAN_A,
    ConVar:CVAR_LEVEL_HUD_SPECTATOR_R,
    ConVar:CVAR_LEVEL_HUD_SPECTATOR_G,
    ConVar:CVAR_LEVEL_HUD_SPECTATOR_B,
    ConVar:CVAR_LEVEL_HUD_SPECTATOR_A,
    ConVar:CVAR_LEVEL_HUD_X,
    ConVar:CVAR_LEVEL_HUD_Y,
    
    ConVar:CVAR_ACCOUNT_CASH_AWARD,
    ConVar:CVAR_ACCOUNT_BUY_ANYWHERE,
    ConVar:CVAR_ACCOUNT_BUY_IMMUNITY,
    ConVar:CVAR_ACCOUNT_MONEY,
    ConVar:CVAR_ACCOUNT_CONNECT,
    ConVar:CVAR_ACCOUNT_BET,
    ConVar:CVAR_ACCOUNT_COMMISION,
    ConVar:CVAR_ACCOUNT_DECREASE,
    ConVar:CVAR_ACCOUNT_HUD_R,
    ConVar:CVAR_ACCOUNT_HUD_G,
    ConVar:CVAR_ACCOUNT_HUD_B,
    ConVar:CVAR_ACCOUNT_HUD_A,
    ConVar:CVAR_ACCOUNT_HUD_X,
    ConVar:CVAR_ACCOUNT_HUD_Y,
    
    ConVar:CVAR_VEFFECTS_SHAKE,
    ConVar:CVAR_VEFFECTS_SHAKE_AMP,
    ConVar:CVAR_VEFFECTS_SHAKE_FREQUENCY,
    ConVar:CVAR_VEFFECTS_SHAKE_DURATION,
    ConVar:CVAR_VEFFECTS_FADE,
    ConVar:CVAR_VEFFECTS_FADE_TIME,
    ConVar:CVAR_VEFFECTS_FADE_DURATION,
    ConVar:CVAR_VEFFECTS_PARTICLES,
    ConVar:CVAR_VEFFECTS_INFECT,
    ConVar:CVAR_VEFFECTS_HUMANIZE,
    ConVar:CVAR_VEFFECTS_RESPAWN,
    ConVar:CVAR_VEFFECTS_RESPAWN_NAME,
    ConVar:CVAR_VEFFECTS_RESPAWN_ATTACH,
    ConVar:CVAR_VEFFECTS_RESPAWN_DURATION,
    ConVar:CVAR_VEFFECTS_HEAL,
    ConVar:CVAR_VEFFECTS_HEAL_NAME,
    ConVar:CVAR_VEFFECTS_HEAL_ATTACH,
    ConVar:CVAR_VEFFECTS_HEAL_DURATION,
    ConVar:CVAR_VEFFECTS_LEAP,
    ConVar:CVAR_VEFFECTS_LEAP_NAME,
    ConVar:CVAR_VEFFECTS_LEAP_ATTACH,
    ConVar:CVAR_VEFFECTS_LEAP_DURATION,
    ConVar:CVAR_VEFFECTS_LIGHTSTYLE,
    ConVar:CVAR_VEFFECTS_LIGHTSTYLE_VALUE,
    ConVar:CVAR_VEFFECTS_SKY,
    ConVar:CVAR_VEFFECTS_SKYNAME,
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
    
    ConVar:CVAR_SEFFECTS_LEVEL,
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
    ConVar:CVAR_SEFFECTS_PLAYER_FLASHLIGHT, 
    ConVar:CVAR_SEFFECTS_PLAYER_NVGS,
    ConVar:CVAR_SEFFECTS_PLAYER_AMMUNITION,  
    ConVar:CVAR_SEFFECTS_PLAYER_LEVEL,       
    ConVar:CVAR_SEFFECTS_ROUND_START,       
    ConVar:CVAR_SEFFECTS_ROUND_COUNT,  
    ConVar:CVAR_SEFFECTS_ROUND_BLAST,
    
    ConVar:CVAR_INFECT_ICON,
    ConVar:CVAR_HEAD_ICON,
    
    ConVar:CVAR_MESSAGES_HELP,
    ConVar:CVAR_MESSAGES_BLOCK
};
/**
 * @endsection
 **/
 
/**
 * Array to store cvar data in.
 **/
ConVar gCvarList[CvarsList];

/**
 * @brief Cvars module init function.
 **/
void CvarsOnInit(/*void*/)
{
    // Prepare all cvar data
    CvarsOnLoad();
    
    // Forward event to sub-modules
    DataBaseOnCvarInit();
    LogOnCvarInit();
    VEffectsOnCvarInit();
    SoundsOnCvarInit();
    ClassesOnCvarInit();
    WeaponsOnCvarInit();
    GameModesOnCvarInit();
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
    bool bExists = ConfigGetFullPath(CONFIG_PATH_CVARS, sPathCvars, false);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure and stop plugin
        SetFailState("Missing cvars file: \"%s\"", sPathCvars);
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Cvars, sPathCvars);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Cvars, gServerData.Cvars, PLATFORM_LINE_LENGTH);

    // Unexpected error, stop plugin
    if(!bSuccess)
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
    if(!iCvars)
    {
        SetFailState("No usable data found in cvar config file: \"%s\"", sPathCvars);
    }
    
    // i = cvar array index
    for(int i = 0; i < iCvars; i++)
    {
        // Gets array line
        ArrayList arrayCvar = CvarsGetKey(i, sPathCvars, sizeof(sPathCvars), true);

        // Parses a parameter string in key="value" format
        if(ParamParseString(arrayCvar, sPathCvars, sizeof(sPathCvars), ' ') == PARAM_ERROR_NO)
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
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void CvarsOnConfigReload(ConfigFile iConfig)
{
    // Gets config file path
    static char sPathCvars[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(File_Cvars, sPathCvars, sizeof(sPathCvars));

    // If file is exist, then execute
    if(FileExists(sPathCvars))
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
    if(bDelete) arrayCvar.Erase(CVARS_DATA_KEY);
    
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