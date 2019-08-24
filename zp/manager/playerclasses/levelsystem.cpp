/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          levelsystem.cpp
 *  Type:          Module 
 *  Description:   Provides functions for level system.
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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @section Level config data indexes.
 **/
enum
{
    LEVELS_DATA_INDEX
};
/**
 * @endsection 
 **/

/**
 * @brief Level system module init function.
 **/
void LevelSystemOnInit(/*void*/)
{
    // If level system disable, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue || !gCvarList[CVAR_LEVEL_HUD].BoolValue)
    {
        // Validate loaded map
        if (gServerData.MapLoaded)
        {
            // Validate sync
            if (gServerData.LevelSync != null)
            {
                // i = client index
                for (int i = 1; i <= MaxClients; i++)
                {
                    // Validate client
                    if (IsPlayerExist(i, false))
                    {
                        // Remove timer
                        delete gClientData[i].LevelTimer;
                    }
                }
                
                // Remove sync
                delete gServerData.LevelSync;
            }
        }
        return;
    }
    
    // Creates a HUD synchronization object
    if (gServerData.LevelSync == null)
    {
        gServerData.LevelSync = CreateHudSynchronizer();
    }
    
    // Validate loaded map
    if (gServerData.MapLoaded)
    {
        // Prepare all levels data
        LevelSystemOnLoad();

        // i = client index
        for (int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if (IsPlayerExist(i, false))
            {
                // Enable level system
                LevelSystemOnClientUpdate(i);
            }
        }
    }
}

/**
 * @brief Prepare all level data.
 **/
void LevelSystemOnLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Levels, Structure_IntegerList, CONFIG_FILE_ALIAS_LEVELS);
    
    // If level system disabled, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Gets levels config path
    static char sPathLevels[PLATFORM_LINE_LENGTH];
    bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_LEVELS, sPathLevels, sizeof(sPathLevels));

    // If file doesn't exist, then log and stop
    if (!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Levels, "Config Validation", "Missing levels config file: %s", sPathLevels);
        return;
    }
    
    // Sets path to the config file
    ConfigSetConfigPath(File_Levels, sPathLevels);
    
    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Levels, gServerData.Levels);

    // Unexpected error, stop plugin
    if (!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Levels, "Config Validation", "Unexpected error encountered loading: %s", sPathLevels);
        return;
    }

    // Now copy data to array structure
    LevelSystemOnCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_Levels, true);
    ConfigSetConfigReloadFunc(File_Levels, GetFunctionByName(GetMyHandle(), "LevelSystemOnConfigReload"));
    ConfigSetConfigHandle(File_Levels, gServerData.Levels);
}

/**
 * @brief Caches level data from file into arrays.
 **/
void LevelSystemOnCacheData(/*void*/)
{
    // Gets config file path
    static char sPathLevels[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(File_Levels, sPathLevels, sizeof(sPathLevels));
    
    // Validate levels config
    int iLevels = gServerData.Levels.Length;
    if (!iLevels)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Levels, "Config Validation", "No usable data found in levels config file: %s", sPathLevels);
        return;
    }
    
    // Initialize a level list array
    ArrayList hLevel = new ArrayList();

    // i = level array index
    for (int i = 0; i < iLevels; i++)
    {
        // Gets level index
        int iLimit = gServerData.Levels.Get(i);
        
        // Validate unique integer
        if (iLimit <= 0 || hLevel.FindValue(iLimit) != -1)
        {
            // Log level error info
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Levels, "Config Validation", "Incorrect level \"%s\" = %i , %i", sPathLevels, iLimit, i);
            
            // Remove level from array
            gServerData.Levels.Erase(i);

            // Subtract one from count
            iLevels--;

            // Backtrack one index, because we deleted it out from under the loop
            i--;
            continue;
        }
        
        // Push data into array
        hLevel.Push(iLimit);
    }
    
    // Validate levels config (after converation)
    if (!iLevels)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Levels, "Config Validation", "No usable data found in levels config file: %s", sPathLevels);
        return;
    }
    
    /// Do quick sort!
    SortADTArray(hLevel, Sort_Ascending, Sort_Integer);
    
    // Replace with new array
    delete gServerData.Levels;
    gServerData.Levels = hLevel.Clone();
    delete hLevel;
}

/**
 * @brief Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void LevelSystemOnConfigReload(ConfigFile iConfig)
{
    // Reloads level config
    LevelSystemOnLoad();
}

/**
 * @brief Creates commands for level system module.
 **/
void LevelSystemOnCommandInit(/*void*/)
{
    // Hook commands
    RegAdminCmd("zp_level_give", LevelSystemLevelOnCommandCatched, ADMFLAG_GENERIC, "Gives the level. Usage: zp_level_give <name> [amount]");
    RegAdminCmd("zp_exp_give", LevelSystemExpOnCommandCatched, ADMFLAG_GENERIC, "Gives the experience. Usage: zp_exp_give <name> [amount]");
}

/**
 * @brief Hook level system cvar changes.
 **/
void LevelSystemOnCvarInit(/*void*/)
{
    // Creates cvars
    gCvarList[CVAR_LEVEL_SYSTEM]          = FindConVar("zp_level_system");
    gCvarList[CVAR_LEVEL_HEALTH_RATIO]    = FindConVar("zp_level_health_ratio");
    gCvarList[CVAR_LEVEL_SPEED_RATIO]     = FindConVar("zp_level_speed_ratio");
    gCvarList[CVAR_LEVEL_GRAVITY_RATIO]   = FindConVar("zp_level_gravity_ratio");
    gCvarList[CVAR_LEVEL_DAMAGE_RATIO]    = FindConVar("zp_level_damage_ratio");
    gCvarList[CVAR_LEVEL_HUD]             = FindConVar("zp_level_hud");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_R]    = FindConVar("zp_level_hud_zombie_R");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_G]    = FindConVar("zp_level_hud_zombie_G");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_B]    = FindConVar("zp_level_hud_zombie_B");
    gCvarList[CVAR_LEVEL_HUD_ZOMBIE_A]    = FindConVar("zp_level_hud_zombie_A");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_R]     = FindConVar("zp_level_hud_human_R");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_G]     = FindConVar("zp_level_hud_human_G");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_B]     = FindConVar("zp_level_hud_human_B");
    gCvarList[CVAR_LEVEL_HUD_HUMAN_A]     = FindConVar("zp_level_hud_human_A");
    gCvarList[CVAR_LEVEL_HUD_SPECTATOR_R] = FindConVar("zp_level_hud_spectator_R");
    gCvarList[CVAR_LEVEL_HUD_SPECTATOR_G] = FindConVar("zp_level_hud_spectator_G");
    gCvarList[CVAR_LEVEL_HUD_SPECTATOR_B] = FindConVar("zp_level_hud_spectator_B");    
    gCvarList[CVAR_LEVEL_HUD_SPECTATOR_A] = FindConVar("zp_level_hud_spectator_A");
    gCvarList[CVAR_LEVEL_HUD_X]           = FindConVar("zp_level_hud_X");
    gCvarList[CVAR_LEVEL_HUD_Y]           = FindConVar("zp_level_hud_Y");
    
    // Hook cvars
    HookConVarChange(gCvarList[CVAR_LEVEL_SYSTEM],        LevelSystemOnCvarHook);       
    HookConVarChange(gCvarList[CVAR_LEVEL_HUD],           LevelSystemOnCvarHook); 
    HookConVarChange(gCvarList[CVAR_LEVEL_HEALTH_RATIO],  LevelSystemChangeOnCvarHook);         
    HookConVarChange(gCvarList[CVAR_LEVEL_SPEED_RATIO],   LevelSystemChangeOnCvarHook);           
    HookConVarChange(gCvarList[CVAR_LEVEL_GRAVITY_RATIO], LevelSystemChangeOnCvarHook); 
}

/*
 * Level data reading API.
 */

/**
 * @brief Gets the limit at a given level.
 * 
 * @param iLevel            The level amount.
 * @return                  The limit amount.
 **/ 
int LevelSystemGetLimit(int iLevel)
{
    // Return the value 
    return gServerData.Levels.Get(iLevel-1);
}

/*
 * Level main functions.
 */

/**
 * @brief Client has been spawned.
 * 
 * @param client            The client index.
 **/
void LevelSystemOnClientSpawn(int client)
{
    // Resets HUD on the team change
    LevelSystemOnClientUpdate(client);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void LevelSystemOnClientDeath(int client)
{
    // Enable HUD for spectator
    LevelSystemOnClientUpdate(client);
}

/**
 * @brief Client has been changed class state.
 *
 * @param client            The client index.
 **/
void LevelSystemOnClientUpdate(int client)
{
    // If level system disabled, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue || !gCvarList[CVAR_LEVEL_HUD].BoolValue)
    {
        return;
    }
    
    // Validate real client
    if (!IsFakeClient(client))
    {
        // Sets timer for player level HUD
        delete gClientData[client].LevelTimer;
        gClientData[client].LevelTimer = CreateTimer(1.0, LevelSystemOnClientHUD, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Sets the client level and prevent it from overloading.
 *
 * @param client            The client index.
 * @param iLevel            The level amount.
 **/
void LevelSystemOnSetLvl(int client, int iLevel)
{
    // If level system disabled, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }

    // Call forward
    gForwardData._OnClientLevel(client, iLevel);

    // If amount below 0, then set to 1
    if (iLevel <= 0)
    {
        iLevel = 1;
    }

    // Sets level
    gClientData[client].Level = iLevel;

    // Gets max level
    int iMaxLevel = gServerData.Levels.Length;
    
    // Validate level
    if (gClientData[client].Level > iMaxLevel)
    {
        // Resets it
        gClientData[client].Level = iMaxLevel;
    }
    else
    {
        // Validate client
        if (IsPlayerExist(client)) 
        {
            // Forward event to modules
            SoundsOnClientLevelUp(client);
        }
    }
    
    // Update level in the database
    DataBaseOnClientUpdate(client, ColumnType_Level);
}

/**
 * @brief Sets the client experience, increasing level if it reach level experience limit and prevent it from overloading.
 *
 * @param client            The client index.
 * @param iExp              The experience amount.
 **/
void LevelSystemOnSetExp(int client, int iExp)
{
    // If level system disabled, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }

    // Call forward
    gForwardData._OnClientExp(client, iExp);
    
    // If amount below 0, then set to 0
    if (iExp < 0)
    {
        iExp = 0;
    }

    // Sets experience
    gClientData[client].Exp = iExp;

    // Gets max level
    int iMaxLevel = gServerData.Levels.Length;
    
    // Give experience to the player
    if (gClientData[client].Level == iMaxLevel && gClientData[client].Exp > LevelSystemGetLimit(gClientData[client].Level))
    {
        // Resets it
        gClientData[client].Exp = LevelSystemGetLimit(gClientData[client].Level);
    }
    else
    {
        // Count through experience
        while (gClientData[client].Level < iMaxLevel && gClientData[client].Exp >= LevelSystemGetLimit(gClientData[client].Level))
        {
            // Increase level
            LevelSystemOnSetLvl(client, gClientData[client].Level + 1);
        }
    }
    
    // Update experience in the database
    DataBaseOnClientUpdate(client, ColumnType_Exp);
}

/**
 * @brief Timer callback, show HUD text within information about client level and experience.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action LevelSystemOnClientHUD(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID); 

    // Validate client
    if (client)
    {
        // Initialize color array
        static int iColor[4];

        // Store the default index
        int target = client;

        // Validate spectator 
        if (!IsPlayerAlive(client))
        {
            // Validate spectator mode
            int iSpecMode = ToolsGetObserverMode(client);
            if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
            {
                // Allow timer
                return Plugin_Continue;
            }
            
            // Gets observer target
            target = ToolsGetObserverTarget(client);
            
            // Validate target
            if (!IsPlayerExist(target)) 
            {
                // Allow timer
                return Plugin_Continue;
            }
            
            // Gets colors 
            iColor[0] = gCvarList[CVAR_LEVEL_HUD_SPECTATOR_R].IntValue;
            iColor[1] = gCvarList[CVAR_LEVEL_HUD_SPECTATOR_G].IntValue;
            iColor[2] = gCvarList[CVAR_LEVEL_HUD_SPECTATOR_B].IntValue;
            iColor[3] = gCvarList[CVAR_LEVEL_HUD_SPECTATOR_A].IntValue;
        }
        else
        {
            // Validate zombie hud
            if (gClientData[client].Zombie)
            {
                // Gets colors 
                iColor[0] = gCvarList[CVAR_LEVEL_HUD_ZOMBIE_R].IntValue;
                iColor[1] = gCvarList[CVAR_LEVEL_HUD_ZOMBIE_G].IntValue;
                iColor[2] = gCvarList[CVAR_LEVEL_HUD_ZOMBIE_B].IntValue;
                iColor[3] = gCvarList[CVAR_LEVEL_HUD_ZOMBIE_A].IntValue;
            }
            // Otherwise, show human hud
            else
            {
                // Gets colors 
                iColor[0] = gCvarList[CVAR_LEVEL_HUD_HUMAN_R].IntValue;
                iColor[1] = gCvarList[CVAR_LEVEL_HUD_HUMAN_G].IntValue;
                iColor[2] = gCvarList[CVAR_LEVEL_HUD_HUMAN_B].IntValue;
                iColor[3] = gCvarList[CVAR_LEVEL_HUD_HUMAN_A].IntValue;
            }
        }

        // Gets class name
        static char sInfo[SMALL_LINE_LENGTH];
        ClassGetName(gClientData[target].Class, sInfo, sizeof(sInfo));

        // Print hud text to the client
        TranslationPrintHudText(gServerData.LevelSync, client, gCvarList[CVAR_LEVEL_HUD_X].FloatValue, gCvarList[CVAR_LEVEL_HUD_Y].FloatValue, 1.1, iColor[0], iColor[1], iColor[2], iColor[3], 0, 0.0, 0.0, 0.0, "level info", sInfo, gClientData[target].Level, gClientData[target].Exp, LevelSystemGetLimit(gClientData[target].Level));

        // Allow timer
        return Plugin_Continue;
    }
    
    // Clear timer
    gClientData[client].LevelTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Cvar hook callback (zp_level_system)
 * @brief Level system module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
    // Validate new value
    if (oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    LevelSystemOnInit();
}

/**
 * Cvar hook callback (zp_level_*_ratio)
 * @brief Reloads the health variable on zombie/human.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemChangeOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{    
    // If level system disabled, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return;
    }
    
    // Validate new value
    if (!strcmp(oldValue, newValue, false))
    {
        return;
    }
    
    // Validate loaded map
    if (gServerData.MapLoaded)
    {
        // i = client index
        for (int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if (IsPlayerExist(i))
            {
                // Update variables
                ToolsSetHealth(i, ClassGetHealth(gClientData[i].Class) + (RoundToNearest(gCvarList[CVAR_LEVEL_HEALTH_RATIO].FloatValue * float(gClientData[i].Level))), true);
                ToolsSetLMV(i, ClassGetSpeed(gClientData[i].Class) + (gCvarList[CVAR_LEVEL_SPEED_RATIO].FloatValue * float(gClientData[i].Level)));
                ToolsSetGravity(i, ClassGetGravity(gClientData[i].Class) + (gCvarList[CVAR_LEVEL_GRAVITY_RATIO].FloatValue * float(gClientData[i].Level)));
            }
        }
    }
}

/**
 * Console command callback (zp_level_give)
 * @brief Gives the level.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action LevelSystemLevelOnCommandCatched(int client, int iArguments)
{
    // If level system disabled, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return Plugin_Handled;
    }
    
    // If not enough arguments given, then stop
    if (iArguments < 2)
    {
        // Write syntax info
        TranslationReplyToCommand(client, "level give invalid args");
        return Plugin_Handled;
    }
    
    // Initialize argument char
    static char sArgument[SMALL_LINE_LENGTH];
    
    // Gets target index
    GetCmdArg(1, sArgument, sizeof(sArgument));
    int target = FindTarget(client, sArgument, true, false);

    // Validate target
    if (target < 0)
    {
        // Note: FindTarget automatically write error messages
        return Plugin_Handled;
    }
    
    // Gets level amount
    GetCmdArg(2, sArgument, sizeof(sArgument));
    
    // Validate amount
    int iLevel = StringToInt(sArgument);
    if (iLevel <= 0)
    {
        // Write error info
        TranslationReplyToCommand(client, "level give invalid amount", iLevel);
        return Plugin_Handled;
    }

    // Sets level for the target 
    LevelSystemOnSetLvl(target, gClientData[target].Level + iLevel);

    // Log action to game events
    LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Classes, "Command", "Admin \"%N\" gived level: \"%d\" to Player \"%N\"", client, iLevel, target);
    return Plugin_Handled;
}

/**
 * Console command callback (zp_exp_give)
 * @brief Gives the experience.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action LevelSystemExpOnCommandCatched(int client, int iArguments)
{
    // If level system disabled, then stop
    if (!gCvarList[CVAR_LEVEL_SYSTEM].BoolValue)
    {
        return Plugin_Handled;
    }
    
    // If not enough arguments given, then stop
    if (iArguments < 2)
    {
        // Write syntax info
        TranslationReplyToCommand(client, "experience give invalid args");
        return Plugin_Handled;
    }
    
    // Initialize argument char
    static char sArgument[SMALL_LINE_LENGTH];
    
    // Gets target index
    GetCmdArg(1, sArgument, sizeof(sArgument));
    int target = FindTarget(client, sArgument, true, false);

    // Validate target
    if (target < 0)
    {
        // Note: FindTarget automatically write error messages
        return Plugin_Handled;
    }
    
    // Gets experience amount
    GetCmdArg(2, sArgument, sizeof(sArgument));
    
    // Validate amount
    int iExp = StringToInt(sArgument);
    if (iExp <= 0)
    {
        // Write error info
        TranslationReplyToCommand(client, "experience give invalid amount", iExp);
        return Plugin_Handled;
    }

    // Sets experience for the target 
    LevelSystemOnSetExp(target, gClientData[target].Exp + iExp);

    // Log action to game events
    LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Classes, "Command", "Admin \"%N\" gived experience: \"%d\" to Player \"%N\"", client, iExp, target);
    return Plugin_Handled;
}

/*
 * Level system natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void LevelSystemOnNativeInit(/*void*/)
{
    CreateNative("ZP_GetLevelMax",    API_GetLevelMax);
    CreateNative("ZP_GetLevelLimit",  API_GetLevelLimit);
    CreateNative("ZP_GetClientLevel", API_GetClientLevel);
    CreateNative("ZP_SetClientLevel", API_SetClientLevel);
    CreateNative("ZP_GetClientExp",   API_GetClientExp);
    CreateNative("ZP_SetClientExp",   API_SetClientExp);
}

/**
 * @brief Gets the maximum level.
 *
 * @note native int ZP_GetLevelMax();
 **/
public int API_GetLevelMax(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.Levels.Length;
}

/**
 * @brief Gets the level experience limit.
 *
 * @note native int ZP_GetLevelLimit(iD);
 **/
public int API_GetLevelLimit(Handle hPlugin, int iNumParams)
{
    // Gets level index from native cell 
    int iD = GetNativeCell(1);
    
    // Validate index
    if (iD < 1 || iD > gServerData.Levels.Length)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Levels, "Native Validation", "Invalid the level index (%d)", iD);
        return -1;
    }

    // Return the value 
    return LevelSystemGetLimit(iD);
}

/**
 * @brief Gets the player level.
 *
 * @note native int ZP_GetClientLevel(client);
 **/
public int API_GetClientLevel(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Return the value 
    return gClientData[client].Level;
}

/**
 * @brief Sets the player level.
 *
 * @note native void ZP_SetClientLevel(client, iD);
 **/
public int API_SetClientLevel(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Sets level for the client
    LevelSystemOnSetLvl(client, GetNativeCell(2));
}

/**
 * @brief Gets the player exp.
 *
 * @note native int ZP_GetClientExp(client);
 **/
public int API_GetClientExp(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Return the value 
    return gClientData[client].Exp;
}

/**
 * @brief Sets the player exp.
 *
 * @note native void ZP_SetClientExp(client, iD);
 **/
public int API_SetClientExp(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int client = GetNativeCell(1);

    // Sets exp for the client
    LevelSystemOnSetExp(client, GetNativeCell(2));
}