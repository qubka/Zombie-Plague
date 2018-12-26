/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          gamemodes.cpp
 *  Type:          Manager 
 *  Description:   Game Modes generator.
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
 * Mode native data indexes.
 **/
enum
{
    GAMEMODES_DATA_NAME,
    GAMEMODES_DATA_DESCRIPTION,
    GAMEMODES_DATA_SOUND,
    GAMEMODES_DATA_CHANCE,
    GAMEMODES_DATA_MINPLAYERS,
    GAMEMODES_DATA_RATIO,
    GAMEMODES_DATA_INFECTION,
    GAMEMODES_DATA_RESPAWN,
    GAMEMODES_DATA_SURVIVOR,
    GAMEMODES_DATA_NEMESIS
}

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
    
    // Sets the path to the config file
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
    CreateTimer(1.0, GameModesStart, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
        arrayGameMode.PushString(sPathModes);                                     // Index: 1
        kvGameModes.GetString("sound", sPathModes, sizeof(sPathModes), "");
        arrayGameMode.Push(SoundsKeyToIndex(sPathModes));                         // Index: 2
        arrayGameMode.Push(kvGameModes.GetNum("chance", 0));                      // Index: 3
        arrayGameMode.Push(kvGameModes.GetNum("min", 0));                         // Index: 4
        arrayGameMode.Push(kvGameModes.GetFloat("ratio", 0.0));                   // Index: 5
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "infect", "yes"));  // Index: 6
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "respawn", "yes")); // Index: 7
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "survivor", "no")); // Index: 8
        arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "nemesis", "no"));  // Index: 9
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
    gCvarList[CVAR_GAME_CUSTOM_START]           = FindConVar("zp_game_custom_time");
}

/**
 * Main timer for start zombie round.
 *
 * @param hTimer            The timer handle.
 **/
public Action GameModesStart(Handle hTimer)
{
    // If gamemodes disabled, then stop
    if(!gCvarList[CVAR_GAME_CUSTOM_START].IntValue)
    {
        return Plugin_Stop;
    }
    
    // If round didn't start yet
    if(gServerData[Server_RoundNew])
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

                        // Emit round start sound
                        SoundsInputEmitToAll(gServerKey[Round_Start], 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
                    }
            
                    // Validate counter
                    if(SoundsInputEmitToAll(gServerKey[Round_Count], gServerData[Server_RoundCount], SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue))
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
                    GameModesEventStart();
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
 * Called right before mode is started.
 *
 * @param modeIndex         (Optional) The mode index. 
 * @param selectedIndex     (Optional) The selected index.
 **/
void GameModesEventStart(int modeIndex = -1, const int selectedIndex = 0)
{
    // Initalize some variables
    static int lastMode; static int defaultMode; int nAlive = fnGetAlive(); 

    // Validate random mode
    if(modeIndex == -1)
    {
        // i = mode number
        int iCount = arrayGameModes.Length;
        for(int i = 0; i < iCount; i++)
        {
            // Starting default game mode ?
            if(lastMode != i && GetRandomInt(1, ModesGetChance(i)) == ModesGetChance(i) && nAlive > ModesGetMinPlayers(i)) modeIndex = i; 
            else if(!ModesGetChance(i)) defaultMode = i; //! Find a default mode    
        }
        
        // Try choosing a default game mode
        if(modeIndex == -1) modeIndex = defaultMode;
    }

    // Initialize buffer char
    static char sBuffer[SMALL_LINE_LENGTH];
    
    // Sets chosen game mode index
    gServerData[Server_RoundMode] = modeIndex;

    // Compute the maximumum zombie amount
    int nMaxZombies = RoundToCeil(nAlive * ModesGetRatio(modeIndex)); 
    if(nMaxZombies == nAlive) nMaxZombies--; //! Subsract for a high ratio
    else if(!nMaxZombies) nMaxZombies++; //! Increment for a low ratio

    // Print game mode description
    ModesGetDesc(modeIndex, sBuffer, sizeof(sBuffer));
    if(hasLength(sBuffer)) TranslationPrintHintTextAll(sBuffer);

    // Play game mode sounds
    SoundsInputEmitToAll(ModesGetSoundID(modeIndex), 0, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);

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
    lastMode = gServerData[Server_RoundMode];
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

            // Sets glowing for the zombie vision
            ToolsSetClientDetecting(i, gCvarList[CVAR_ZOMBIE_XRAY].BoolValue);
        }
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
    CreateNative("ZP_GetCurrentGameMode",             API_GetCurrentGameMode);
    CreateNative("ZP_GetNumberGameMode",              API_GetNumberGameMode);
    CreateNative("ZP_GetServerGameMode",              API_GetServerGameMode);
    CreateNative("ZP_SetServerGameMode",              API_SetServerGameMode);
    CreateNative("ZP_GetGameModeName",                API_GetGameModeName);
    CreateNative("ZP_GetGameModeDesc",                API_GetGameModeDesc);
    CreateNative("ZP_GetGameModeSoundID",             API_GetGameModeSoundID);
    CreateNative("ZP_GetGameModeChance",              API_GetGameModeChance);
    CreateNative("ZP_GetGameModeMinPlayers",          API_GetGameModeMinPlayers);
    CreateNative("ZP_GetGameModeRatio",               API_GetGameModeRatio);
    CreateNative("ZP_IsGameModeInfect",               API_IsGameModeInfect);
    CreateNative("ZP_IsGameModeRespawn",              API_IsGameModeRespawn);
    CreateNative("ZP_IsGameModeSurvivor",             API_IsGameModeSurvivor);
    CreateNative("ZP_IsGameModeNemesis",              API_IsGameModeNemesis);
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
 * Gets the index of a game mode at a given name.
 *
 * native int ZP_GetServerGameMode(name);
 **/
public int API_GetServerGameMode(Handle hPlugin, const int iNumParams)
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

    // i = mode number
    int iCount = arrayGameModes.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Gets the name of a game mode at a given index
        static char sModeName[SMALL_LINE_LENGTH];
        ModesGetName(i, sModeName, sizeof(sModeName));

        // If names match, then return index
        if(!strcmp(sName, sModeName, false))
        {
            return i;
        }
    }

    // Return on the unsuccess
    return -1;
}

/**
 * Sets the index of a game mode at a given name.
 *
 * native int ZP_SetServerGameMode(name, client);
 **/
public int API_SetServerGameMode(Handle hPlugin, const int iNumParams)
{
    // If mode doesn't started yet, then stop
    if(!gServerData[Server_RoundNew])
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Can't start game mode during the round");
        return -1;
    }
    
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

    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(2);

    // Validate client
    if(clientIndex && !IsPlayerExist(clientIndex))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }

    // i = mode number
    int iCount = arrayGameModes.Length;
    for(int i = 0; i < iCount; i++)
    {
        // Gets the name of a game mode at a given index
        static char sModeName[SMALL_LINE_LENGTH];
        ModesGetName(i, sModeName, sizeof(sModeName));

        // If names match, then return index
        if(!strcmp(sName, sModeName, false))
        {
            // Start the game mode
            GameModesEventStart(i, clientIndex);
            return i;
        }
    }

    // Return on the unsuccess
    return -1;
}

/**
 * Gets the name of a game mode at a given index.
 *
 * native void ZP_GetGameModeName(iD, sName, maxLen);
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
 * native void ZP_GetGameModeDesc(iD, sName, maxLen);
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
    static char sName[SMALL_LINE_LENGTH];
    ModesGetDesc(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the sound key of the game mode.
 *
 * native int ZP_GetGameModeSoundID(iD);
 **/
public int API_GetGameModeSoundID(Handle hPlugin, const int iNumParams)
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
    return ModesGetSoundID(iD);
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
 * Check the survivor type of the game mode.
 *
 * native bool ZP_IsGameModeSurvivor(iD);
 **/
public int API_IsGameModeSurvivor(Handle hPlugin, const int iNumParams)
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
    return ModesIsSurvivor(iD);
}

/**
 * Check the nemesis type of the game mode.
 *
 * native bool ZP_IsGameModeNemesis(iD);
 **/
public int API_IsGameModeNemesis(Handle hPlugin, const int iNumParams)
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
    return ModesIsNemesis(iD);
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
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode description
    arrayGameMode.GetString(GAMEMODES_DATA_DESCRIPTION, sDesc, iMaxLen);
}

/**
 * Gets the sound key of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The key index.
 **/
stock int ModesGetSoundID(const int iD)
{
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode sound key
    return arrayGameMode.Get(GAMEMODES_DATA_SOUND);
}

/**
 * Gets the chance of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The chance amount.
 **/
stock int ModesGetChance(const int iD)
{
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
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode ratio
    return arrayGameMode.Get(GAMEMODES_DATA_RATIO);
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
 * Check the survivor type of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsSurvivor(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode survivor type
    return arrayGameMode.Get(GAMEMODES_DATA_SURVIVOR);
}

/**
 * Check the nemesis type of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  True or false.
 **/
stock bool ModesIsNemesis(const int iD)
{
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);

    // Gets game mode nemesis type
    return arrayGameMode.Get(GAMEMODES_DATA_NEMESIS);
}
