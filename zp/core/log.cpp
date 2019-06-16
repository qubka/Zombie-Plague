/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          log.cpp
 *  Type:          Core 
 *  Description:   Logging API.
 *
 *  Copyright (C) 2015-2019 Greyscale, Richard Helgeby
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
 * @section Custom log file.
 **/
#define LOG_FILE "addons/sourcemod/logs/zombieplague.log"
/**
 * @endsection
 **/
 
/**
 * @section Log flags.
 **/
#define LOG_CORE_EVENTS        (1 << 0)    /** Log events from the plugin core like config validation and other messages. */
#define LOG_GAME_EVENTS        (1 << 1)    /** Log admin commands, console commands, and game related events from modules like suicide attempts and weapon restrictions. */
#define LOG_PLAYER_COMMANDS    (1 << 2)    /** Log events that are triggered by players, like chat triggers. */
#define LOG_DEBUG              (1 << 3)    /** Log debug messages, if any. Usually only developers enable this log flag. */
#define LOG_DEBUG_DETAIL       (1 << 4)    /** Log additional debug messages with more detail. May cause spam depending on filter settings. Usually only developers enable this log flag. */
/**
 * @endsection
 **/
 
/**
 * @section Log format types.
 **/
enum LogType
{
    LogType_Normal,               /** Normal log message. Printed in SourceMod logs. */
    LogType_Error,                /** Error message. Printed in SourceMod error logs. */
    LogType_Fatal,                /** Fatal error. Stops the plugin with the specified message. */
    LogType_Native,               /** Throws an error in the calling plugin of a native, instead of your own plugin. */
    LogType_Command               /** Command log message. Printed in SourceMod logs and in chat to all. */
};
/**
 * @endsection
 **/
 
/**
 * @section List of modules that write log events. Add new modules if needed (in alphabetical order).
 * 
 * Update following when adding modules:
 * - Admin log flag menu
 * - LogGetModuleNameString
 * - LogGetModule
 **/
enum LogModule
{
    bool:LogModule_Invalid,            /** Used as return value when an error occoured.*/

    bool:LogModule_Engine,
    bool:LogModule_Config,
    bool:LogModule_Debug,
    bool:LogModule_Tools,
    bool:LogModule_Database,
    bool:LogModule_Decrypt,
    bool:LogModule_Sounds,
    bool:LogModule_Downloads,
    bool:LogModule_Weapons,
    bool:LogModule_Effects,
    bool:LogModule_Menus,
    bool:LogModule_HitGroups,
    bool:LogModule_AntiStick,
    bool:LogModule_Death,
    bool:LogModule_Levels,
    bool:LogModule_Classes,
    bool:LogModule_ExtraItems,
    bool:LogModule_Costumes,
    bool:LogModule_GameModes,
    bool:LogModule_Admin,
    bool:LogModule_Native
};
/**
 * @endsection
 **/

/**
 * Cache of current module filter settings. For fast and easy access.
 **/
int LogModuleFilterCache[LogModule];

/**
 * @brief List of modules that write log events. 
 **/
void LogOnInit(/*void*/)
{
    // Initialize a module filter array
    gServerData.Logs = new ArrayList(SMALL_LINE_LENGTH);
    gServerData.Modules = new StringMap();

    // Push data into map
    gServerData.Modules.SetValue("engine", LogModule_Engine);
    gServerData.Modules.SetValue("config", LogModule_Config);
    gServerData.Modules.SetValue("debug", LogModule_Debug);
    gServerData.Modules.SetValue("tools", LogModule_Tools);
    gServerData.Modules.SetValue("database", LogModule_Database);
    gServerData.Modules.SetValue("models", LogModule_Decrypt);
    gServerData.Modules.SetValue("decrypt", LogModule_Sounds);
    gServerData.Modules.SetValue("downloads", LogModule_Downloads);
    gServerData.Modules.SetValue("weapons", LogModule_Weapons);
    gServerData.Modules.SetValue("effects", LogModule_Effects);
    gServerData.Modules.SetValue("menus", LogModule_Menus);
    gServerData.Modules.SetValue("hitgroups", LogModule_HitGroups);
    gServerData.Modules.SetValue("antistick", LogModule_AntiStick);
    gServerData.Modules.SetValue("death", LogModule_Death);
    gServerData.Modules.SetValue("levels", LogModule_Levels);
    gServerData.Modules.SetValue("classes", LogModule_Classes);
    gServerData.Modules.SetValue("extraitems", LogModule_ExtraItems);
    gServerData.Modules.SetValue("costumes", LogModule_Costumes);
    gServerData.Modules.SetValue("gamemodes", LogModule_GameModes);
    gServerData.Modules.SetValue("admin", LogModule_Admin);
    gServerData.Modules.SetValue("native", LogModule_Native);
}

/**
 * @brief Creates commands for log module.
 **/
void LogOnCommandInit(/*void*/)
{
    // Create config admin commands
    RegAdminCmd("zp_log_list", LogListOnCommandCatched, ADMFLAG_CONFIG, "List available logging flags and modules with their status values.");
    RegAdminCmd("zp_log_add_module", LogAddModuleOnCommandCatched, ADMFLAG_CONFIG, "Add one or more modules to the module filter. Usage: zp_log_add_module <module> [module] ...");
    RegAdminCmd("zp_log_remove_module", LogRemoveModuleOnCommandCatched, ADMFLAG_CONFIG, "Remove one or more modules from the module filter. Usage: zp_log_remove_module <module> [module] ...");
}

/**
 * Hook log cvar changes.
 **/
void LogOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_LOG]                = FindConVar("zp_log");
    gCvarList[CVAR_LOG_MODULE_FILTER]  = FindConVar("zp_log_module_filter");
    gCvarList[CVAR_LOG_IGNORE_CONSOLE] = FindConVar("zp_log_ignore_console");
    gCvarList[CVAR_LOG_ERROR_OVERRIDE] = FindConVar("zp_log_error_override");
    gCvarList[CVAR_LOG_PRINT_CHAT]     = FindConVar("zp_log_print_chat");
}

/*
 * Stocks log API.
 */

/**
 * @brief Converts a string module name into a module type.
 *
 * @param sModuleName       A string with the short module name. Case insensitive,
 *                          but not trimmed for white space.
 * @return                  The matcing module type or LogModule_Invalid if failed.
 **/
LogModule LogGetModule(char[] sModuleName)
{
    // Validate slots
    LogModule iModule;
    if(gServerData.Modules.GetValue(sModuleName, iModule))
    {
        // Return index
        return iModule;
    }

    // Name doesn't exist
    return LogModule_Invalid;
}

/**
 * @brief Check if the specified log flag is set.
 *
 * @param iEvent            The log flag to check.
 * @return                  True if set, false otherwise.
 **/
bool LogCheckFlag(int iEvent)
{
    // Check if event type is set
    return iEvent ? true : false;
}

/**
 * @brief Check if the specified module is enabled in the LOG_MODULE filter cache.
 *
 * @param iModule           Module to check.
 * @return                  True ifenabled, false otherwise. 
 **/
bool LogCheckModuleFilter(LogModule iModule)
{
    // Check if filter is set
    return LogModuleFilterCache[iModule] ? true : false;
}

/**
 * @brief Convert module type to a string.
 *
 * @param sBuffer           Destination string buffer.
 * @param iMaxLen           The lenght of string.
 * @param iModule           Module type to convert.
 * @param shortName         Optional. Use short name instead of human readable names. Default is false
 * @return                  Number of cells written.
 **/
int LogGetModuleNameString(char[] sBuffer, int iMaxLen, LogModule iModule, bool shortName = false)
{
    switch(iModule)
    {
        case LogModule_Engine :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "engine") : strcopy(sBuffer, iMaxLen, "Engine");
        }
        case LogModule_Config :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "config") : strcopy(sBuffer, iMaxLen, "Config");
        }
        case LogModule_Debug :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "debug") : strcopy(sBuffer, iMaxLen, "Debug");
        }
        case LogModule_Tools :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "tools") : strcopy(sBuffer, iMaxLen, "Tools");
        }
        case LogModule_Database :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "database") : strcopy(sBuffer, iMaxLen, "Database");
        }
        case LogModule_Decrypt :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "decrypt") : strcopy(sBuffer, iMaxLen, "Decrypt");
        }
        case LogModule_Sounds :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "sounds") : strcopy(sBuffer, iMaxLen, "Sounds");
        }
        case LogModule_Downloads :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "downloads") : strcopy(sBuffer, iMaxLen, "Downloads");
        }
        case LogModule_Weapons :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "weapons") : strcopy(sBuffer, iMaxLen, "Weapons");
        }
        case LogModule_Effects :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "effects") : strcopy(sBuffer, iMaxLen, "Effects");
        }
        case LogModule_Menus :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "menus") : strcopy(sBuffer, iMaxLen, "Menus");
        }
        case LogModule_HitGroups :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "hitgroups") : strcopy(sBuffer, iMaxLen, "HitGroups");
        }
        case LogModule_AntiStick :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "antistick") : strcopy(sBuffer, iMaxLen, "Antistick");
        }
        case LogModule_Death :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "death") : strcopy(sBuffer, iMaxLen, "Death");
        }
        case LogModule_Levels : 
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "levels") : strcopy(sBuffer, iMaxLen, "Levels");
        }
        case LogModule_Classes :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "classes") : strcopy(sBuffer, iMaxLen, "Classes");
        }
        case LogModule_ExtraItems :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "extraitems") : strcopy(sBuffer, iMaxLen, "Extra Items");
        }
        case LogModule_Costumes :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "costumes") : strcopy(sBuffer, iMaxLen, "Costumes");
        }
        case LogModule_GameModes :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "gamemodes") : strcopy(sBuffer, iMaxLen, "Game Modes");
        }
        case LogModule_Admin :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "admin") : strcopy(sBuffer, iMaxLen, "Admin");
        }
        case LogModule_Native :
        {
            return shortName ? strcopy(sBuffer, iMaxLen, "native") : strcopy(sBuffer, iMaxLen, "Native");
        }
    }

    // Module mismatch
    return 0;
}

/**
 * @brief Print a formatted message to logs depending on log settings.
 *
 * @param isConsole         Optional. Specifies whether the log event came from
 *                          client 0. Used in console commands, do not mix with
 *                          regular log events. Default is false.
 * @param iType             Optional. Log type and action. Default is
 *                          LogType_Normal.
 * @param iEvent            Optional. A log flag describing What kind of log event
 *                          it is. Default is LOG_CORE_EVENTS.
 * @param iModule           Module the log event were executed in.
 * @param sDescription      Event type or function name. A short descriptive phrase
 *                          to group together similar logs.
 * @param sMessage          Log message. Can be formatted.
 * @param ...               Formatting parameters.
 **/
void LogEvent(bool isConsole = false, LogType iType = LogType_Normal, int iEvent = LOG_CORE_EVENTS, LogModule iModule = LogModule_Config, char[] sDescription, char[] sMessage, any ...)
{    
    // Check filter overrides. Always log fatal errors, and check error override setting on error log types
    if((iType != LogType_Fatal && iType != LogType_Error) || (iType == LogType_Error && !gCvarList[CVAR_LOG_ERROR_OVERRIDE].BoolValue))
    {
        // Check iflogging is disabled
        if(!gCvarList[CVAR_LOG].BoolValue)
        {
            return;
        }

        // Check if console is ignored
        if(isConsole && gCvarList[CVAR_LOG_IGNORE_CONSOLE].BoolValue)
        {
            return;
        }

        // Check event type (log flag)
        if(!LogCheckFlag(iEvent))
        {
            return;
        }

        // Check ifmodule filtering is enabled
        if(gCvarList[CVAR_LOG_MODULE_FILTER].BoolValue)
        {
            // Check if the specified module is enabled
            if(!LogCheckModuleFilter(iModule))
            {
                return;
            }
        }
    }

    // Format extra parameters into the log buffer
    static char sLogBuffer[FILE_LINE_LENGTH];
    VFormat(sLogBuffer, sizeof(sLogBuffer), sMessage, 7);

    // Gets human readable module name
    static char sModule[SMALL_LINE_LENGTH];
    LogGetModuleNameString(sModule, sizeof(sModule), iModule);

    // Format 
    Format(sLogBuffer, sizeof(sLogBuffer), "[%s] [%s] %s", sModule, sDescription, sLogBuffer);

    // Format other parameters onto the log text
    switch(iType)
    {
        case LogType_Normal:
        {
            LogMessage(sLogBuffer);
        }

        case LogType_Error:
        {
            LogError(sLogBuffer);
        }

        case LogType_Fatal:
        {
            SetFailState(sLogBuffer);
        }

        case LogType_Native:
        {
            ThrowNativeError(SP_ERROR_NATIVE, sLogBuffer);
        }

        case LogType_Command:
        {
            LogToFile(LOG_FILE, sLogBuffer);
        }
    }

    // Check if printing log events to public chat is enabled
    if(gCvarList[CVAR_LOG_PRINT_CHAT].BoolValue)
    {
        // Print text to public chat
        PrintToChatAll(sLogBuffer);
    }
}

/**
 * @brief Adds a module to the module filter and updates the cache. If it already
 *        exist the command is ignored.
 *
 * @param iModule           The module to add.
 * @return                  True if added, false otherwise.
 **/
bool LogModuleFilterAdd(LogModule iModule)
{
    // Initialize some chars
    static char sModuleName[SMALL_LINE_LENGTH];
    
    // Check ifempty
    if(!hasLength(sModuleName))
    {
        return false;
    }
    
    // Convert module name
    LogGetModuleNameString(sModuleName, sizeof(sModuleName), iModule, true);
    
    // Check if the module isn't already is listed
    if(gServerData.Logs.FindString(sModuleName) == -1)
    {
        // Add module to filter
        gServerData.Logs.PushString(sModuleName);
        return true;
    }
    
    return false;
}

/**
 * @brief Removes a module to the module filter and updates the cache. If it doesn't
 *        exist the command is ignored.
 *
 * @param iModule           The module to remove.
 * @return                  True ifremoved, false otherwise.
 **/
bool LogModuleFilterRemove(LogModule iModule)
{
    // Initialize some chars
    static char sModuleName[SMALL_LINE_LENGTH]; int iModuleIndex;
    
    // Check ifempty
    if(!hasLength(sModuleName))
    {
        return false;
    }
    
    // Convert module name
    LogGetModuleNameString(sModuleName, sizeof(sModuleName), iModule, true);
    
    // Gets module index
    iModuleIndex = gServerData.Logs.FindString(sModuleName);
    
    // Check if successful
    if(iModuleIndex)
    {
        // Remove module from filter
        gServerData.Logs.Erase(iModuleIndex);
        return true;
    }
    
    return false;
}

/**
 * @brief Update module filter cache.
 **/
void LogModuleFilterCacheUpdate(/*void*/)
{
    static char sModuleName[SMALL_LINE_LENGTH]; LogModule iModule;
    
    // Clear all entries in module cache
    int iModuleCount = sizeof(LogModuleFilterCache);
    for(int i = 1; i < iModuleCount; i++)
    {
        LogModuleFilterCache[view_as<LogModule>(i)] = false;
    }
    
    // Loop through the module array
    int iSize = gServerData.Logs.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets module name
        gServerData.Logs.GetString(i, sModuleName, sizeof(sModuleName));
        
        // Convert to type
        iModule = LogGetModule(sModuleName);
        
        // Validate type
        if(iModule != LogModule_Invalid)
        {
            // Sets value in cache
            LogModuleFilterCache[iModule] = true;
        }
    }
}

/**
 * Console command callback (zp_log_list)
 * @brief Displays flags and module filter cache.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action LogListOnCommandCatched(int client, int iArguments)
{
    // Initialize some chars
    static char sBuffer[FILE_LINE_LENGTH];
    static char sLineBuffer[NORMAL_LINE_LENGTH];
    static char sModuleName[SMALL_LINE_LENGTH];
    
    // Strings to store translated phrases. Because formatting width settings
    // doesn't work with "%t", but "%s"
    static char sPhraseGenericFlag[SMALL_LINE_LENGTH];
    static char sPhraseValue[SMALL_LINE_LENGTH];
    static char sPhraseModule[SMALL_LINE_LENGTH];
    static char sPhraseShortName[SMALL_LINE_LENGTH];
    
    // Quick initialize string buffer
    sBuffer[0] = 0;
    
    // Sets language
    SetGlobalTransTarget(!client ? LANG_SERVER : client);
    
    // Gets phrases
    FormatEx(sPhraseGenericFlag, sizeof(sPhraseGenericFlag), "%t", "log generic flag");
    FormatEx(sPhraseValue, sizeof(sPhraseValue), "%t", "log value");
    FormatEx(sPhraseModule, sizeof(sPhraseModule), "%t", "log module");
    FormatEx(sPhraseShortName, sizeof(sPhraseShortName), "%t", "log module short name");
    
    // Log flags:
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "%-19s %-7s %t\n", sPhraseGenericFlag, sPhraseValue, "log status");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    StrCat(sBuffer, sizeof(sBuffer), "--------------------------------------------------------------------------------\n");
    
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "LOG_CORE_EVENTS     1       %s\n", LogCheckFlag(LOG_CORE_EVENTS) ? "On" : "Off");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "LOG_GAME_EVENTS     2       %s\n", LogCheckFlag(LOG_GAME_EVENTS) ? "On" : "Off");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "LOG_PLAYER_COMMANDS 4       %s\n", LogCheckFlag(LOG_PLAYER_COMMANDS) ? "On" : "Off");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "LOG_DEBUG           8       %s\n", LogCheckFlag(LOG_DEBUG) ? "On" : "Off");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "LOG_DEBUG_DETAIL    16      %s\n", LogCheckFlag(LOG_DEBUG_DETAIL) ? "On" : "Off");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    
    ReplyToCommand(client, sBuffer);
    sBuffer[0] = 0;
    
    // Module filtering status:
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "%t %s\n\n", "log module filter", gCvarList[CVAR_LOG_MODULE_FILTER].BoolValue ? "On" : "Off");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    
    FormatEx(sLineBuffer, sizeof(sLineBuffer), "%-23s %-19s %t\n", sPhraseModule, sPhraseShortName, "log status");
    StrCat(sBuffer, sizeof(sBuffer), sLineBuffer);
    StrCat(sBuffer, sizeof(sBuffer), "--------------------------------------------------------------------------------");
    
    ReplyToCommand(client, sBuffer);
    sBuffer[0] = 0;
    
    // Module status:
    int iModulecount = sizeof(LogModuleFilterCache);
    for(int i = 1; i < iModulecount; i++)
    {
        LogGetModuleNameString(sModuleName, sizeof(sModuleName), view_as<LogModule>(i));
        LogGetModuleNameString(sPhraseShortName, sizeof(sPhraseShortName), view_as<LogModule>(i), true);
        FormatEx(sLineBuffer, sizeof(sLineBuffer), "%-23s %-19s %s", sModuleName, sPhraseShortName, LogModuleFilterCache[view_as<LogModule>(i)] ? "On" : "Off");
        ReplyToCommand(client, sLineBuffer);
    }
    return Plugin_Handled;
}

/**
 * Console command callback (zp_log_add_module)
 * @brief Add one or modules to module filter.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action LogAddModuleOnCommandCatched(int client, int iArguments)
{
    // Initialize argument char
    static char sArgument[SMALL_LINE_LENGTH];

    // Module
    LogModule iModule;

    // Check if no arguments
    if(iArguments < 1)
    {
        // Display syntax info
        TranslationReplyToCommand(client, "log module invalid args");
    }

    // Loop through each argument
    for(int i = 1; i <= iArguments; i++)
    {
        // Gets argument string
        GetCmdArg(i, sArgument, sizeof(sArgument));

        // Convert to module type
        iModule = LogGetModule(sArgument);

        // Check ifinvalid
        if(iModule == LogModule_Invalid)
        {
            // Skip to next argument
            TranslationReplyToCommand(client, "log module invalid name", sArgument);
            continue;
        }

        // Add filter
        LogModuleFilterAdd(iModule);
        TranslationReplyToCommand(client, "log module filter added", sArgument);
    }

    // Update cache
    LogModuleFilterCacheUpdate();
    return Plugin_Handled;
}

/**
 * Console command callback (zp_log_remove_module)
 * @brief Remove one or modules to module filter.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/
public Action LogRemoveModuleOnCommandCatched(int client, int iArguments)
{
    // Initialize some chars
    static char sArgument[SMALL_LINE_LENGTH];

    // Module
    LogModule iModule;
    
    // Check if no arguments
    if(iArguments < 1)
    {
        // Display syntax info
        TranslationReplyToCommand(client, "log module invalid args");
    }
    
    // Loop through each argument
    for(int i = 1; i <= iArguments; i++)
    {
        // Gets argument string
        GetCmdArg(i, sArgument, sizeof(sArgument));
        
        // Convert to module type
        iModule = LogGetModule(sArgument);
        
        // Check ifinvalid
        if(iModule == LogModule_Invalid)
        {
            // Skip to next argument
            TranslationReplyToCommand(client, "log module invalid name", sArgument);
            continue;
        }
        
        // Remove filter
        LogModuleFilterRemove(iModule);
        TranslationReplyToCommand(client, "log module filter removed", sArgument);
    }
    
    // Update cache.
    LogModuleFilterCacheUpdate();
    return Plugin_Handled;
}
