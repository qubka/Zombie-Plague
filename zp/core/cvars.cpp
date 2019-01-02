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
 * Array handle to store variable config data.
 **/
ArrayList arrayCvars;

/**
 * Array for parsing strings.
 **/
int CvarBuffer[2048][ParamParseResult];

/**
 * @section List of cvars used by the plugin.
 **/
enum CvarsList
{
    ConVar:CVAR_SERVER_OCCULUSE,
    ConVar:CVAR_SERVER_TRANSMIT_PLAYERS,
    ConVar:CVAR_SERVER_TEAM_BALANCE,
    ConVar:CVAR_SERVER_LIMIT_TEAMS,
    ConVar:CVAR_SERVER_CASH_AWARD,
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
    ConVar:CVAR_SERVER_CT_DEFAULT_MELEE,
    ConVar:CVAR_SERVER_CT_DEFAULT_SECONDARY,
    ConVar:CVAR_SERVER_CT_DEFAULT_PRIMARY,
    ConVar:CVAR_SERVER_T_DEFAULT_GRENADES,
    ConVar:CVAR_SERVER_T_DEFAULT_MELEE,
    ConVar:CVAR_SERVER_T_DEFAULT_SECONDARY,
    ConVar:CVAR_SERVER_T_DEFAULT_PRIMARY,
    ConVar:CVAR_SERVER_CT_DEFAULT_GRENADES,
    
    ConVar:CVAR_GAME_CUSTOM_START,
    ConVar:CVAR_GAME_CUSTOM_MONEY,
    ConVar:CVAR_GAME_CUSTOM_DATABASE,
    ConVar:CVAR_GAME_CUSTOM_ANTISTICK,
    ConVar:CVAR_GAME_CUSTOM_HITGROUPS,
    ConVar:CVAR_GAME_CUSTOM_COSTUMES,
    ConVar:CVAR_GAME_CUSTOM_MENU_BUTTON,
    ConVar:CVAR_GAME_CUSTOM_SKILL_BUTTON,
    ConVar:CVAR_GAME_CUSTOM_LIGHT_BUTTON,
    ConVar:CVAR_GAME_CUSTOM_HUMAN_MENU,
    ConVar:CVAR_GAME_CUSTOM_ZOMBIE_MENU,
    ConVar:CVAR_GAME_CUSTOM_ARMOR_PROTECT,
    ConVar:CVAR_GAME_CUSTOM_SOUND_LEVEL,
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
    ConVar:CVAR_LEVEL_STATISTICS,
    ConVar:CVAR_LEVEL_HEALTH_RATIO,
    ConVar:CVAR_LEVEL_SPEED_RATIO,
    ConVar:CVAR_LEVEL_GRAVITY_RATIO,
    ConVar:CVAR_LEVEL_DAMAGE_RATIO,
    ConVar:CVAR_LEVEL_HUD,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_R,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_G,
    ConVar:CVAR_LEVEL_HUD_ZOMBIE_B,
    ConVar:CVAR_LEVEL_HUD_HUMAN_R,
    ConVar:CVAR_LEVEL_HUD_HUMAN_G,
    ConVar:CVAR_LEVEL_HUD_HUMAN_B,
    ConVar:CVAR_LEVEL_HUD_X,
    ConVar:CVAR_LEVEL_HUD_Y,
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
    ConVar:CVAR_VEFFECTS_SKYNAME, //!
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
    ConVar:CVAR_SEFFECTS_ALLTALK, ///!
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
 * Cvars module init function.
 **/
void CvarsInit(/*void*/)
{
    // Create zombieplague cvars
    CvarsLoad();
    
    // Hook cvars
    CvarsHook();

    // Create revision cvar
    CreateConVar("zombieplague_revision", PLUGIN_VERSION, "Revision number for this plugin in source code repository.", FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);

    // Adds core tag
    FindConVar("sv_tags").SetString(PLUGIN_TAG, true);
}

/**
 * Prepare all cvar data.
 **/
void CvarsLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Cvars, Structure_ArrayList, CONFIG_FILE_ALIAS_CVARS);

    // Gets cvars file path
    static char sPathCvars[PLATFORM_MAX_PATH];
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
    bool bSuccess = ConfigLoadConfig(File_Cvars, arrayCvars, PLATFORM_MAX_PATH);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        SetFailState("Unexpected error encountered loading: \"%s\"", sPathCvars);
    }

    // Now copy data to array structure
    CvarsCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Cvars, true);
    ConfigSetConfigReloadFunc(File_Cvars, GetFunctionByName(GetMyHandle(), "CvarsOnConfigReload"));
    ConfigSetConfigHandle(File_Cvars, arrayCvars);
    
    // Destroy all data
    ConfigClearKvArray(arrayCvars);
}

/**
 * Caches cvar data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void CvarsCacheData(/*void*/)
{
    // Gets config file path
    static char sPathCvars[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Cvars, sPathCvars, sizeof(sPathCvars));

    // Validate cvar config
    int iCvars = arrayCvars.Length;
    if(!iCvars)
    {
        SetFailState("No usable data found in cvar config file: \"%s\"", sPathCvars);
    }
    
    // i = cvar array index
    for(int i = 0; i < iCvars; i++)
    {
        // Gets array line
        sPathCvars[0] = '\0'; CvarsGetLine(i, sPathCvars, sizeof(sPathCvars));

        // Parses a parameter string in key="value" format and store the result in a ParamParseResult array
        if(ParamParseString(CvarBuffer, sPathCvars, sizeof(sPathCvars), ' ', i) == PARAM_ERROR_NO)
        {
            // Trim string
            TrimString(sPathCvars);
            
            // Strips a quote pair off a string 
            StripQuotes(sPathCvars);

            // Creates a new console variable
            CreateConVar(CvarBuffer[i][Param_Name], sPathCvars);
        }
        else
        {
            // Log cvar error info
            SetFailState("Error with parsing of cvar block: %d = \"%s\"", i + 1, sPathCvars);
    
            // Remove cvar block from array
            arrayCvars.Erase(i);

            // Subtract one from count
            iCvars--;

            // Backtrack one index, because we deleted it out from under the loop
            i--;
            continue;
        }
    }
}

/**
 * Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void CvarsOnConfigReload(ConfigFile iConfig)
{
    // Gets config file path
    static char sPathCvars[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Cvars, sPathCvars, sizeof(sPathCvars));

    // If file is exist, then execute
    if(FileExists(sPathCvars))
    {
        // Reload cvars config
        ServerCommand("exec %s", sPathCvars[4]);
    }
}

/**
 * Hook cvar changes.
 **/
void CvarsHook(/*void*/)
{
    // Forward event to sub-modules
    AntiStickOnCvarInit();
    DamageOnCvarInit();
    DataBaseOnCvarInit();
    AccountOnCvarInit();
    LogOnCvarInit();
    JumpBoostOnCvarInit();
    LevelSystemOnCvarInit();
    VEffectsOnCvarInit();
    SoundsOnCvarInit();
    ClassesOnCvarInit();
    SkillsOnCvarInit();
    ToolsOnCvarInit();
    WeaponsOnCvarInit();
    RoundStartOnCvarInit();
    GameModesOnCvarInit();
    HitGroupsOnCvarInit();
    CostumesOnCvarInit();
    MenusOnCvarInit();
}

/*
 * Cvars data reading API.
 */

/**
 * Gets the line from a cvar list.
 * 
 * @param iD                The cvar array index.
 * @param sLine             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void CvarsGetLine(const int iD, char[] sLine, const int iMaxLen)
{
    // Gets array handle of cvar at given index
    ArrayList arrayCvar = arrayCvars.Get(iD);
    
    // Gets line
    arrayCvar.GetString(0, sLine, iMaxLen);
}

/*
 * Stocks cvars API.
 */

/**
 * Cvar hook callback.
 * Prevents changes of default cvars.
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
 * Prevents changes of default cvars.
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
 * Prevents changes of cheat cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookLocked2(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    CvarsOnCheatSet(hConVar, 0);
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

/**
 * Cvar hook callback.
 * Prevents changes of default cvars.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void CvarsHookLocked3(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Revert to locked value
    hConVar.SetString("");
}