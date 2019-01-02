/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          gamemodes.cpp
 *  Type:          Manager 
 *  Description:   API for loading gamemodes specific variables.
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
 * Array handle to store game mode native data.
 **/
ArrayList arrayGameModes;
 
/**
 * @section Mode native data indexes.
 **/
enum
{
    GAMEMODES_DATA_NAME,
    GAMEMODES_DATA_DESCRIPTION,
    GAMEMODES_DATA_CHANCE,
    GAMEMODES_DATA_MINPLAYERS,
    GAMEMODES_DATA_RATIO,
    GAMEMODES_DATA_SOUNDSTART,
    GAMEMODES_DATA_SOUNDAMBIENT,
    GAMEMODES_DATA_SOUNDDURATION,
    GAMEMODES_DATA_SOUNDVOLUME,
    GAMEMODES_DATA_INFECTION,
    GAMEMODES_DATA_RESPAWN,
    GAMEMODES_DATA_HUMAN,
    GAMEMODES_DATA_ZOMBIE,
    GAMEMODES_DATA_DEATHMATCH,
    GAMEMODES_DATA_AMOUNT,
    GAMEMODES_DATA_DELAY,
    GAMEMODES_DATA_LAST,
    GAMEMODES_DATA_SUICIDE,
    GAMEMODES_DATA_ESCAPE,
    GAMEMODES_DATA_XRAY,
    GAMEMODES_DATA_REGEN,
    GAMEMODES_DATA_SKILL,
    GAMEMODES_DATA_LEAPJUMP,
    GAMEMODES_DATA_WEAPON,
    GAMEMODES_DATA_EXTRAITEM
};
/**
 * @endsection
 **/
 
/**
 * Prepare all gamemode data.
 **/
void GameModesLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_GameModes, Structure_Keyvalue, CONFIG_FILE_ALIAS_GAMEMODES);

    // Gets gamemodes config path
    static char sPathModes[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_GAMEMODES, sPathModes);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Missing gamemodes config file: \"%s\"", sPathModes);
    }
    
    // Sets path to the config file
    ConfigSetConfigPath(File_GameModes, sPathModes);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_GameModes, arrayGameModes);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathModes);
    }

    // Validate gamemodes config
    int iSize = arrayGameModes.Length;
    if(!iSize)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "No usable data found in gamemodes config file: \"%s\"", sPathModes);
    }

    // Now copy data to array structure
    GameModesCacheData();

    // Sets config data
    ConfigSetConfigLoaded(File_GameModes, true);
    ConfigSetConfigReloadFunc(File_GameModes, GetFunctionByName(GetMyHandle(), "GameModesOnConfigReload"));
    ConfigSetConfigHandle(File_GameModes, arrayGameModes);
    
    // Create timer for starting game mode
    CreateTimer(1.0, GameModesOnCounter, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * Caches gamemode data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void GameModesCacheData(/*void*/)
{
    // Gets config file path
    static char sPathModes[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_GameModes, sPathModes, sizeof(sPathModes));

    // Open config
    KeyValues kvGameModes;
    bool bSuccess = ConfigOpenConfigFile(File_GameModes, kvGameModes);

    // Validate config
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Unexpected error caching data from gamemodes config file: \"%s\"", sPathModes);
    }

    // i = array index
    int iSize = arrayGameModes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // General
        ModesGetName(i, sPathModes, sizeof(sPathModes)); // Index: 0
        kvGameModes.Rewind();
        if(!kvGameModes.JumpToKey(sPathModes))
        {
            // Log gamemode fatal
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Couldn't cache gamemode data for: \"%s\" (check gamemodes config)", sPathModes);
            continue;
        }

        // Initialize array block
        ArrayList arrayGameMode = arrayGameModes.Get(i);

        // Push data into array
        kvGameModes.GetString("desc", sPathModes, sizeof(sPathModes), "");
        if(!TranslationPhraseExists(sPathModes) && hasLength(sPathModes))
        {
            // Log gamemode error
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Couldn't cache gamemode description: \"%s\" (check translation file)", sPathModes);
        }
        arrayGameMode.PushString(sPathModes);                                       // Index: 1
        arrayGameMode.Push(kvGameModes.GetNum("chance", 0));                        // Index: 2
        arrayGameMode.Push(kvGameModes.GetNum("min", 0));                           // Index: 3
        arrayGameMode.Push(kvGameModes.GetFloat("ratio", 0.0));                     // Index: 4
        kvGameModes.GetString("start", sPathModes, sizeof(sPathModes), "");
        arrayGameMode.Push(SoundsKeyToIndex(sPathModes));                           // Index: 5
        
        

        kvGameModes.GetString("ambient", sPathModes, sizeof(sPathModes), "");
        arrayGameMode.Push(SoundsKeyToIndex(sPathModes));                           // Index: 6
        arrayGameMode.Push(kvGameModes.GetFloat("duration", 60.0));                 // Index: 7
        arrayGameMode.Push(kvGameModes.GetFloat("volume", 1.0));                    // Index: 8
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "infect", "yes"));    // Index: 9
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "respawn", "yes"));   // Index: 10
        kvGameModes.GetString("human", sPathModes, sizeof(sPathModes), "human");
        arrayGameMode.PushString(sPathModes);                                       // Index: 11
        kvGameModes.GetString("zombie", sPathModes, sizeof(sPathModes), "zombie");
        arrayGameMode.PushString(sPathModes);                                       // Index: 12
        arrayGameMode.Push(kvGameModes.GetNum("deathmatch", 0));                    // Index: 13
        arrayGameMode.Push(kvGameModes.GetNum("amount", 0));                        // Index: 14
        arrayGameMode.Push(kvGameModes.GetFloat("delay", 0.0));                     // Index: 15
        arrayGameMode.Push(kvGameModes.GetNum("last", 0));                          // Index: 16
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "suicide", "no"));    // Index: 17
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "escape", "off"));    // Index: 18
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "xray", "on"));       // Index: 19
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "regen", "on"));      // Index: 20
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "skill", "yes"));     // Index: 21
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "leapjump", "yes"));  // Index: 22
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "weapon", "yes"));    // Index: 23
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "extraitem", "yes")); // Index: 24
    }

    // We're done with this file now, so we can close it
    delete kvGameModes;
}

/**
 * Called when configs are being reloaded.
 **/
public void GameModesOnConfigReload(/*void*/)
{
    // Reload gamemodes config
    GameModesLoad();
}

/**
 * Hook gamemodes cvar changes.
 **/
void GameModesOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_GAME_CUSTOM_START] = FindConVar("zp_game_custom_time");
}

/**
 * Timer callback, use by the main counter.
 *
 * @param hTimer            The timer handle.
 **/
public Action GameModesOnCounter(Handle hTimer)
{
    // If gamemodes disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_START].IntValue)
    {
        return Plugin_Stop;
    }
    
    // If round didn't start yet
    if(gServerData[Server_RoundNew] && !GameRules_GetProp("m_bWarmupPeriod"))
    {
        // Gets amount of total alive players
        int nAlive = fnGetAlive();

        // Switch amount of alive players
        switch(nAlive)
        {
            // Wait other players
            case 0, 1 : { /*break*/ }
            
            // If players exists
            default :                             
            {
                // If counter is counting ?
                if(gServerData[Server_RoundCount])
                {
                    // Validate beginning
                    if(gServerData[Server_RoundCount] == (gCvarList[CVAR_GAME_CUSTOM_START].IntValue - 2))
                    {
                        // If help messages enabled, then proceed
                        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
                        {
                            // Show help information
                            TranslationPrintToChatAll("general round objective");
                            TranslationPrintToChatAll("general ammunition reminder");
                            TranslationPrintHintTextAll("general buttons reminder");
                        }
                        
                        // Forward event to modules
                        SoundsOnCounterStart(); //! Play round start after some time
                    }

                    // Validate counter
                    if(SoundsOnCounter()) /// (2)
                    {
                        // If help messages enabled, then proceed
                        if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
                        {
                            // Show help information
                            TranslationPrintHintTextAll("zombie comming", gServerData[Server_RoundCount]);
                        }
                    }
                }
                // If else, than start game
                else 
                {
                    // Forward event to modules
                    GameModesEventStart();
                    SoundsOnGameModeStart();
                }
                
                // Substitute second
                gServerData[Server_RoundCount]--;
            }
        }
    }

    // If not, then wait
    return Plugin_Continue;
}

/**
 * The gamemode is start.
 *
 * @param modeIndex         (Optional) The mode index. 
 * @param selectedIndex     (Optional) The selected index.
 **/
void GameModesEventStart(int modeIndex = -1, const int selectedIndex = 0)
{
    // Gets amount of total players
    int nAlive = fnGetAlive(); 

    // Validate random mode
    if(modeIndex == -1)
    {
        // i = mode number
        int iCount = arrayGameModes.Length; static int defaultMode; 
        for(int i = 0; i < iCount; i++)
        {
            // Starting default game mode ?
            if(gServerData[Server_RoundLast] != i && GetRandomInt(1, ModesGetChance(i)) == ModesGetChance(i) && nAlive > ModesGetMinPlayers(i)) modeIndex = i; 
            else if(!ModesGetChance(i)) defaultMode = i; //! Find a default mode    
        }
        
        // Try choosing a default game mode
        if(modeIndex == -1) modeIndex = defaultMode;
    }

    // Initialize buffer char
    static char sBuffer[SMALL_LINE_LENGTH];
    
    // Sets chosen game mode index
    gServerData[Server_RoundMode] = modeIndex;

    // Compute the maximum zombie amount
    int nMaxZombies = RoundToCeil(nAlive * ModesGetRatio(modeIndex)); 
    if(nMaxZombies == nAlive) nMaxZombies--; //! Subsract for a high ratio
    else if(!nMaxZombies) nMaxZombies++; //! Increment for a low ratio

    // Print game mode description
    ModesGetDesc(modeIndex, sBuffer, sizeof(sBuffer));
    if(hasLength(sBuffer)) TranslationPrintHintTextAll(sBuffer);

    // Random players should be zombie
    GameModesTurnIntoZombie(selectedIndex, nMaxZombies);

    // Remaining players should be humans
    GameModesTurnIntoHuman();

    // Call forward
    API_OnZombieModStarted(modeIndex);

    // Resets server grobal variables
    gServerData[Server_RoundNew] = false;
    gServerData[Server_RoundEnd] = false;
    gServerData[Server_RoundStart] = true;

    // Update mode index for the next round
    gServerData[Server_RoundLast] = gServerData[Server_RoundMode];
}

/**
 * Turn random players into the zombies.
 *
 * @param selectedIndex     The selected index.
 * @param MaxZombies        The amount of zombies.
 **/
void GameModesTurnIntoZombie(const int selectedIndex, const int MaxZombies)
{
    // Validate client for a given client index
    if(IsPlayerExist(selectedIndex))
    {
        // Validate survivor mode
        if(ModesIsSurvivor(gServerData[Server_RoundMode]))
        {
            // Make a survivor
            ClassMakeHuman(selectedIndex, true);
        }
        else
        {
            // Make a zombie/nemesis
            ClassMakeZombie(selectedIndex, _, ModesIsNemesis(gServerData[Server_RoundMode]));
            return;
        }
    }

    // i = zombie index
    for(int i = 0; i < MaxZombies; i++)
    {
        // Make a zombie/nemesis
        ClassMakeZombie(fnGetRandomHuman(), _, ModesIsNemesis(gServerData[Server_RoundMode]));
    }
}

/**
 * Turn remaining players into the humans.
 **/
void GameModesTurnIntoHuman(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Verify that the client is exist
        if(!IsPlayerExist(i))
        {
            continue;
        }
        
        // Verify that the client is human
        if(gClientData[i][Client_Zombie] || gClientData[i][Client_Survivor])
        {
            continue;
        }
        
        // Validate survivor mode
        if(ModesIsSurvivor(gServerData[Server_RoundMode])) 
        {
            // Make a survivor
            ClassMakeHuman(i, true);
        }
        else
        {
            // Switch to CT
            bool bState = ToolsGetClientDefuser(i);
            ToolsSetClientTeam(i, TEAM_HUMAN);
            ToolsSetClientDefuser(i, bState);
        }
        
        // Sets glowing for the zombie vision
        ToolsSetClientDetecting(i, ModesIsXRay(gServerData[Server_RoundMode]));
    }
}

/*
 * Game modes natives API.
 */

/**
 * Sets up natives for library.
 **/
void GameModesAPI(/*void*/) 
{
    CreateNative("ZP_GetCurrentGameMode",        API_GetCurrentGameMode);
    CreateNative("ZP_GetLastGameMode",           API_GetLastGameMode);
    CreateNative("ZP_GetNumberGameMode",         API_GetNumberGameMode);
    CreateNative("ZP_StartGameMode",             API_StartGameMode);
    CreateNative("ZP_GetGameModeNameID",         API_GetGameModeNameID);
    CreateNative("ZP_GetGameModeName",           API_GetGameModeName);
    CreateNative("ZP_GetGameModeDesc",           API_GetGameModeDesc);
    CreateNative("ZP_GetGameModeChance",         API_GetGameModeChance);
    CreateNative("ZP_GetGameModeMinPlayers",     API_GetGameModeMinPlayers);
    CreateNative("ZP_GetGameModeRatio",          API_GetGameModeRatio);
    CreateNative("ZP_GetGameModeSoundStartID",   API_GetGameModeSoundStartID);
    CreateNative("ZP_GetGameModeSoundAmbientID", API_GetGameModeSoundAmbientID);
    CreateNative("ZP_GetGameModeSoundDuration",  API_GetGameModeSoundDuration);
    CreateNative("ZP_GetGameModeSoundVolume",    API_GetGameModeSoundVolume);
    CreateNative("ZP_IsGameModeInfect",          API_IsGameModeInfect);
    CreateNative("ZP_IsGameModeRespawn",         API_IsGameModeRespawn);
    CreateNative("ZP_GetGameModeHuman",          API_GetGameModeHuman);
    CreateNative("ZP_GetGameModeZombie",         API_GetGameModeZombie);
    CreateNative("ZP_GetGameModeMatch",          API_GetGameModeMatch);
    CreateNative("ZP_GetGameModeAmount",         API_GetGameModeAmount);
    CreateNative("ZP_GetGameModeDelay",          API_GetGameModeDelay);
    CreateNative("ZP_GetGameModeLast",           API_GetGameModeLast);
    CreateNative("ZP_IsGameModeSuicide",         API_IsGameModeSuicide);
    CreateNative("ZP_IsGameModeEscape",          API_IsGameModeEscape);
    CreateNative("ZP_IsGameModeXRay",            API_IsGameModeXRay);
    CreateNative("ZP_IsGameModeRegen",           API_IsGameModeRegen);
    CreateNative("ZP_IsGameModeSkill",           API_IsGameModeSkill);
    CreateNative("ZP_IsGameModeLeapJump",        API_IsGameModeLeapJump);
    CreateNative("ZP_IsGameModeWeapon",          API_IsGameModeWeapon);
    CreateNative("ZP_IsGameModeExtraItem",       API_IsGameModeExtraItem);
}
 
/**
 * Gets the current game mode.
 *
 * native int ZP_GetCurrentGameMode();
 **/
public int API_GetCurrentGameMode(Handle hPlugin, const int iNumParams)
{
    // Return the value
    return gServerData[Server_RoundMode];
}

/**
 * Gets the last game mode.
 *
 * native int ZP_GetLastGameMode();
 **/
public int API_GetLastGameMode(Handle hPlugin, const int iNumParams)
{
    // Return the value
    return gServerData[Server_RoundLast];
}

/**
 * Gets the amount of all game modes.
 *
 * native int ZP_GetNumberGameMode();
 **/
public int API_GetNumberGameMode(Handle hPlugin, const int iNumParams)
{
    // Return the value 
    return arrayGameModes.Length;
}

/**
 * Start the game mode.
 *
 * native void ZP_StartGameMode(iD, clientIndex);
 **/
public int API_StartGameMode(Handle hPlugin, const int iNumParams)
{
    // If mode doesn't started yet, then stop
    if(!gServerData[Server_RoundNew])
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Can't start game mode during the round");
        return -1;
    }
    
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(2);

    // Validate client
    if(clientIndex && !IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }

    // Start the game mode
    GameModesEventStart(iD, clientIndex);
   
    // Return on success
    return iD;
}

/**
 * Gets the index of a game mode at a given name.
 *
 * native int ZP_GetGameModeNameID(name);
 **/
public int API_GetGameModeNameID(Handle hPlugin, const int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Can't find mode with an empty name");
        return -1;
    }
    
    // Gets native data
    static char sName[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sName, sizeof(sName));

    // Return the value
    return ModesNameToIndex(sName);  
}

/**
 * Gets the name of a game mode at a given index.
 *
 * native void ZP_GetGameModeName(iD, name, maxlen);
 **/
public int API_GetGameModeName(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    ModesGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the description of a game mode at a given index.
 *
 * native void ZP_GetGameModeDesc(iD, name, maxlen);
 **/
public int API_GetGameModeDesc(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize description char
    static char sDesc[SMALL_LINE_LENGTH];
    ModesGetDesc(iD, sDesc, sizeof(sDesc));

    // Return on success
    return SetNativeString(2, sDesc, maxLen);
}

/**
 * Gets the chance of the game mode.
 *
 * native int ZP_GetGameModeChance(iD);
 **/
public int API_GetGameModeChance(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesGetChance(iD);
}

/**
 * Gets the min players of the game mode.
 *
 * native int ZP_GetGameModeMinPlayers(iD);
 **/
public int API_GetGameModeMinPlayers(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesGetMinPlayers(iD);
}

/**
 * Gets the ratio of the game mode.
 *
 * native float ZP_GetGameModeRatio(iD);
 **/
public int API_GetGameModeRatio(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value (Float fix)
    return view_as<int>(ModesGetRatio(iD));
}

/**
 * Gets the start sound key of the game mode.
 *
 * native int ZP_GetGameModeSoundStartID(iD);
 **/
public int API_GetGameModeSoundStartID(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value
    return ModesGetSoundStartID(iD);
}

/**
 * Gets the ambient sound key of the game mode.
 *
 * native int ZP_GetGameModeSoundAmbientID(iD);
 **/
public int API_GetGameModeSoundAmbientID(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value
    return ModesGetSoundAmbientID(iD);
}

/**
 * Gets the ambient sound duration of the game mode.
 *
 * native int ZP_GetGameModeSoundDuration(iD);
 **/
public int API_GetGameModeSoundDuration(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value (Float fix)
    return view_as<int>(ModesGetSoundDuration(iD));
}

/**
 * Gets the ambient sound volume of the game mode.
 *
 * native int ZP_GetGameModeSoundVolume(iD);
 **/
public int API_GetGameModeSoundVolume(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value (Float fix)
    return view_as<int>(ModesGetSoundVolume(iD));
}

/**
 * Check the infection type of the game mode.
 *
 * native bool ZP_IsGameModeInfect(iD);
 **/
public int API_IsGameModeInfect(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsInfection(iD);
}

/**
 * Check the respawn type of the game mode.
 *
 * native bool ZP_IsGameModeRespawn(iD);
 **/
public int API_IsGameModeRespawn(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsRespawn(iD);
}

/**
 * Gets the human class of a game mode at a given index.
 *
 * native void ZP_GetGameModeName(iD, class, maxlen);
 **/
public int API_GetGameModeHuman(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize class char
    static char sClass[SMALL_LINE_LENGTH];
    ModesGetHuman(iD, sClass, sizeof(sClass));

    // Return on success
    return SetNativeString(2, sClass, maxLen);
}

/**
 * Gets the human class of a game mode at a given index.
 *
 * native void ZP_GetGameModeZombie(iD, class, maxlen);
 **/
public int API_GetGameModeZombie(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize class char
    static char sClass[SMALL_LINE_LENGTH];
    ModesGetZombie(iD, sClass, sizeof(sClass));

    // Return on success
    return SetNativeString(2, sClass, maxLen);
}

/**
 * Gets the deathmatch mode of the game mode.
 *
 * native int ZP_GetGameModeMatch(iD);
 **/
public int API_GetGameModeMatch(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value
    return ModesGetMatch(iD);
}

/**
 * Gets the amount of the game mode.
 *
 * native int ZP_GetGameModeAmount(iD);
 **/
public int API_GetGameModeAmount(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value
    return ModesGetAmount(iD);
}

/**
 * Gets the delay of the game mode.
 *
 * native float ZP_GetGameModeDelay(iD);
 **/
public int API_GetGameModeDelay(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value (Float fix)
    return view_as<int>(ModesGetDelay(iD));
}

/**
 * Gets the last amount of the game mode.
 *
 * native int ZP_GetGameModeLast(iD);
 **/
public int API_GetGameModeLast(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }

    // Return value
    return ModesGetLast(iD);
}

/**
 * Check the suicide mode of the game mode.
 *
 * native bool ZP_IsGameModeSuicide(iD);
 **/
public int API_IsGameModeSuicide(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsSuicide(iD);
}

/**
 * Check the escape mode of the game mode.
 *
 * native bool ZP_IsGameModeEscape(iD);
 **/
public int API_IsGameModeEscape(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsEscape(iD);
}

/**
 * Check the xray access of the game mode.
 *
 * native bool ZP_IsGameModeXRay(iD);
 **/
public int API_IsGameModeXRay(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsXRay(iD);
}

/**
 * Check the regen access of the game mode.
 *
 * native bool ZP_IsGameModeRegen(iD);
 **/
public int API_IsGameModeRegen(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsRegen(iD);
}

/**
 * Check the skill access of the game mode.
 *
 * native bool ZP_IsGameModeSkill(iD);
 **/
public int API_IsGameModeSkill(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsSkill(iD);
}

/**
 * Check the leapjump access of the game mode.
 *
 * native bool ZP_IsGameModeLeapJump(iD);
 **/
public int API_IsGameModeLeapJump(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsLeapJump(iD);
}

/**
 * Check the weapon access of the game mode.
 *
 * native bool ZP_IsGameModeWeapon(iD);
 **/
public int API_IsGameModeWeapon(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsWeapon(iD);
}

/**
 * Check the extraitem access of the game mode.
 *
 * native bool ZP_IsGameModeExtraItem(iD);
 **/
public int API_IsGameModeExtraItem(Handle hPlugin, const int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= arrayGameModes.Length)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Return value
    return ModesIsExtraItem(iD);
}

/*
 * Game modes data reading API.
 */
 
/**
 * Gets the name of a game mode at a given index.
 *
 * @param iD                The game mode index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ModesGetName(const int iD, char[] sName, const int iMaxLen)
{
    // Validate no game mode
    if(iD == -1)
    {
        strcopy(sName, iMaxLen, "");
        return;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode name
    arrayGameMode.GetString(GAMEMODES_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the description of a game mode at a given index.
 *
 * @param iD                The game mode index.
 * @param sDesc             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ModesGetDesc(const int iD, char[] sDesc, const int iMaxLen)
{
    // Validate no game mode
    if(iD == -1)
    {
        strcopy(sDesc, iMaxLen, "");
        return;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode description
    arrayGameMode.GetString(GAMEMODES_DATA_DESCRIPTION, sDesc, iMaxLen);
}

/**
 * Gets the chance of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The chance amount.
 **/
stock int ModesGetChance(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return -1;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode chance
    return arrayGameMode.Get(GAMEMODES_DATA_CHANCE);
}

/**
 * Gets the min players of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The min players amount.
 **/
stock int ModesGetMinPlayers(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return -1;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode chance
    return arrayGameMode.Get(GAMEMODES_DATA_MINPLAYERS);
}

/**
 * Gets the ratio of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The ratio amount.
 **/
stock float ModesGetRatio(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return 0.0;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode ratio
    return arrayGameMode.Get(GAMEMODES_DATA_RATIO);
}

/**
 * Gets the start sound key of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The key index.
 **/
stock int ModesGetSoundStartID(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return -1;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode start sound key
    return arrayGameMode.Get(GAMEMODES_DATA_SOUNDSTART);
}

/**
 * Gets the ambient sound key of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The key index.
 **/
stock int ModesGetSoundAmbientID(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return -1;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode ambient sound key
    return arrayGameMode.Get(GAMEMODES_DATA_SOUNDAMBIENT);
}

/**
 * Gets the ambient sound duration of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The duration amount.
 **/
stock float ModesGetSoundDuration(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return 0.0;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode ambient sound duration
    return arrayGameMode.Get(GAMEMODES_DATA_SOUNDDURATION);
}

/**
 * Gets the ambient sound volume of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The volume amount.
 **/
stock float ModesGetSoundVolume(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return 0.0;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode ambient sound volume
    return arrayGameMode.Get(GAMEMODES_DATA_SOUNDVOLUME);
}

/**
 * Check the infection type of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsInfection(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode infection type
    return arrayGameMode.Get(GAMEMODES_DATA_INFECTION);
}

/**
 * Check the respawn type of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsRespawn(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode respawn type
    return arrayGameMode.Get(GAMEMODES_DATA_RESPAWN);
}

/**
 * Gets the human class of a game mode at a given index.
 *
 * @param iD                The game mode index.
 * @param sClass            The string to return class in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ModesGetHuman(const int iD, char[] sClass, const int iMaxLen)
{
    // Validate no game mode
    if(iD == -1)
    {
        strcopy(sClass, iMaxLen, "");
        return;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode human class
    arrayGameMode.GetString(GAMEMODES_DATA_HUMAN, sClass, iMaxLen);
}

/**
 * Gets the zombie class of a game mode at a given index.
 *
 * @param iD                The game mode index.
 * @param sClass            The string to return class in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ModesGetZombie(const int iD, char[] sClass, const int iMaxLen)
{
    // Validate no game mode
    if(iD == -1)
    {
        strcopy(sClass, iMaxLen, "");
        return;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode zombie class
    arrayGameMode.GetString(GAMEMODES_DATA_ZOMBIE, sClass, iMaxLen);
}

/**
 * Gets the deathmatch mode of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The deathmatch mode.
 **/
stock int ModesGetMatch(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return 0;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode deathmatch mode
    return arrayGameMode.Get(GAMEMODES_DATA_DEATHMATCH);
}

/**
 * Gets the amount of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The amount.
 **/
stock int ModesGetAmount(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return 0;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode amount
    return arrayGameMode.Get(GAMEMODES_DATA_AMOUNT);
}

/**
 * Gets the delay of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The delay.
 **/
stock float ModesGetDelay(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return 0.0;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode delay
    return arrayGameMode.Get(GAMEMODES_DATA_DELAY);
}

/**
 * Gets the last amount of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The last amount.
 **/
stock int ModesGetLast(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return 0;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode last amount
    return arrayGameMode.Get(GAMEMODES_DATA_LAST);
}

/**
 * Check the suicide mode of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsSuicide(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode suicide mode
    return arrayGameMode.Get(GAMEMODES_DATA_SUICIDE);
}

/**
 * Check the escape mode of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsEscape(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode escape mode
    return arrayGameMode.Get(GAMEMODES_DATA_ESCAPE);
}

/**
 * Check the xray access of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsXRay(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode xray access
    return arrayGameMode.Get(GAMEMODES_DATA_XRAY);
}

/**
 * Check the regen access of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsRegen(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode regen access
    return arrayGameMode.Get(GAMEMODES_DATA_REGEN);
}

/**
 * Check the skill access of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsSkill(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode skill access
    return arrayGameMode.Get(GAMEMODES_DATA_SKILL);
}

/**
 * Check the leapjump access of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsLeapJump(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode leapjump access
    return arrayGameMode.Get(GAMEMODES_DATA_LEAPJUMP);
}

/**
 * Check the weapon access of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsWeapon(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode weapon access
    return arrayGameMode.Get(GAMEMODES_DATA_WEAPON);
}

/**
 * Check the extraitem access of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsExtraItem(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode extraitem access
    return arrayGameMode.Get(GAMEMODES_DATA_EXTRAITEM);
}

/*
 * Stocks game modes API.
 */
 
/**
 * Find the index at which the gamemode name is at.
 * 
 * @param sName             The mode name.
 * @param iMaxLen           (Only if 'overwritename' is true) The max length of the mode name. 
 * @param bOverWriteName    (Optional) If true, the mode given will be overwritten with the name from the config.
 * @return                  The array index containing the given mode name.
 **/
stock int ModesNameToIndex(char[] sName, const int iMaxLen = 0, const bool bOverWriteName = false)
{
    // Initialize name char
    static char sModeName[SMALL_LINE_LENGTH];
    
    // i = mode index
    int iSize = arrayGameModes.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets mode name 
        ModesGetName(i, sModeName, sizeof(sModeName));
        
        // If names match, then return index
        if(!strcmp(sName, sModeName, false))
        {
            // If 'overwrite' name is true, then overwrite the old string with new
            if(bOverWriteName)
            {
                // Copy config name to return string
                strcopy(sName, iMaxLen, sModeName);
            }
            
            // Return this index
            return i;
        }
    }
    
    // Name doesn't exist
    return -1;
}