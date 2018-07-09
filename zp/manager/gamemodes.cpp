/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          gamemodes.cpp
 *  Type:          Manager 
 *  Description:   Game Modes generator.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 * Number of max valid game modes.
 **/
#define GameModesMax 32

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
 * Initialization of game modes. 
 **/
void GameModesLoad(/*void*/)
{
    // No game modes?
    if(arrayGameModes == INVALID_HANDLE)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Gamemodes, "Game Mode Validation", "No game modes loaded");
    }
    
    // Forward event to modules (FakeHook)
    RoundStartOnRoundPreStart();
    RoundStartOnRoundStart();
    
    // Create timer for starting game mode
    CreateTimer(1.0, GameModesStart, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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
                    // If help messages enabled, show info
                    if(gCvarList[CVAR_MESSAGES_HELP].BoolValue)
                    {
                        // Validate beginning
                        if(gServerData[Server_RoundCount] == (gCvarList[CVAR_GAME_CUSTOM_START].IntValue - 2))
                        {
                            // Show help information
                            TranslationPrintToChatAll("General round objective");
                            TranslationPrintHintTextAll("General buttons reminder");
                        }

                        // Show counter message
                        if(gServerData[Server_RoundCount] <= 20)
                        {
                            // Play counter sounds
                            if(1 <= gServerData[Server_RoundCount] <= 10) SoundsInputEmitToAll("ROUND_COUNTER_SOUNDS", gServerData[Server_RoundCount]);
                            
                            // Player round start sounds
                            if(gServerData[Server_RoundCount] == 20) SoundsInputEmitToAll("ROUND_START_SOUNDS");
                            
                            // Initialize string and format it
                            TranslationPrintHintTextAll("Zombie comming", gServerData[Server_RoundCount]);
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
void GameModesEventStart(int modeIndex = -1, int selectedIndex = 0)
{
    // Initalize some variables
    static int lastMode; int defaultMode; int nAlive = fnGetAlive(); 

    // Mode fully started
    gServerData[Server_RoundNew] = false;
    gServerData[Server_RoundEnd] = false;
    gServerData[Server_RoundStart] = true;

    // Validate random mode
    if(modeIndex == -1)
    {
        // i = mode number
        int iCount = GetArraySize(arrayGameModes);
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
    TranslationPrintHintTextAll(sBuffer);

    // Play game mode sounds
    ModesGetSound(modeIndex, sBuffer, sizeof(sBuffer));
    SoundsInputEmitToAll(sBuffer);

    // Random players should be zombie
    GameModesTurnIntoZombie(selectedIndex, nMaxZombies);

    // Remaining players should be humans
    GameModesTurnIntoHuman();

    // Terminate the round, if zombies weren't infect
    if(!RoundEndOnValidate())
    {
        // Call forward
        API_OnZombieModStarted();
    }
    
    // Update mode index for the next round
    lastMode = gServerData[Server_RoundMode];
}

/**
 * Turn random players into the zombies.
 *
 * @param selectedIndex     The selected index.
 * @param nMaxZombies       The amount of zombies.
 **/
void GameModesTurnIntoZombie(int selectedIndex, int nMaxZombies)
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
    for(int i = 0; i < nMaxZombies; i++)
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
            ToolsSetClientTeam(i, TEAM_HUMAN);

            // Sets glowing for the zombie vision
            ToolsSetClientDetecting(i, gCvarList[CVAR_ZOMBIE_XRAY].BoolValue);
        }
    }
}

/*
 * Game modes natives API.
 */
 
/**
 * Gets the current game mode.
 *
 * native int ZP_GetCurrentGameMode();
 **/
public int API_GetCurrentGameMode(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundMode];
}

/**
 * Gets the amount of all game modes.
 *
 * native int ZP_GetNumberGameMode();
 **/
public int API_GetNumberGameMode(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return GetArraySize(arrayGameModes);
}

/**
 * Gets the index of a game mode at a given name.
 *
 * native int ZP_GetServerGameMode(name);
 **/
public int API_GetServerGameMode(Handle isPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Can't find mode with an empty name");
        return -1;
    }
    
    // Gets native data
    static char sName[SMALL_LINE_LENGTH];

    // General
    GetNativeString(1, sName, sizeof(sName));

    // i = mode number
    int iCount = GetArraySize(arrayGameModes);
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
public int API_SetServerGameMode(Handle isPlugin, int iNumParams)
{
    // If mode doesn't started yet, then stop
    if(!gServerData[Server_RoundNew])
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Can't start game mode during the round");
        return -1;
    }
    
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Can't find mode with an empty name");
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
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the client index (%d)", clientIndex);
        return -1;
    }

    // i = mode number
    int iCount = GetArraySize(arrayGameModes);
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
 * Load game modes from other plugin.
 *
 * native int ZP_RegisterGameMode(name, desc, sound, chance, min, ratio, infect, respawn, survivor, nemesis)
 **/
public int API_RegisterGameMode(Handle isPlugin, int iNumParams)
{
    // If array hasn't been created, then create
    if(arrayGameModes == INVALID_HANDLE)
    {
        // Create array in handle
        arrayGameModes = CreateArray(GameModesMax);
    }

    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);
    
    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Can't register game mode with an empty name");
        return -1;
    }
    
    // Gets game modes amount
    int iCount = GetArraySize(arrayGameModes);
    
    // Maximum amout of game modes
    if(iCount >= GameModesMax)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation",  "Maximum number of game modes reached (%d). Skipping other modes.", GameModesMax);
        return -1;
    }

    // Gets native data
    char sModeName[SMALL_LINE_LENGTH];
    char sModeDesc[SMALL_LINE_LENGTH];
    char sModeSound[SMALL_LINE_LENGTH];
    
    // General                                            
    GetNativeString(1, sModeName,  sizeof(sModeName));  
    GetNativeString(2, sModeDesc,  sizeof(sModeDesc));  
    GetNativeString(3, sModeSound, sizeof(sModeSound)); 
    
    // Initialize char
    static char sName[SMALL_LINE_LENGTH];
    
    // i = Game mode number
    for(int i = 0; i < iCount; i++)
    {
        // Gets game mode name
        ModesGetName(i, sName, sizeof(sName));
    
        // If names match, then stop
        if(!strcmp(sModeName, sName, false))
        {
            LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Game mode already registered (%s)", sName);
            return -1;
        }
    }
    
    // Initialize array block
    ArrayList arrayGameMode = CreateArray(GameModesMax);
    
    // Push native data into array
    arrayGameMode.PushString(sModeName);      // Index: 0
    arrayGameMode.PushString(sModeDesc);      // Index: 1
    arrayGameMode.PushString(sModeSound);     // Index: 2
    arrayGameMode.Push(GetNativeCell(4));     // Index: 3
    arrayGameMode.Push(GetNativeCell(5));     // Index: 4
    arrayGameMode.Push(GetNativeCell(6));     // Index: 5
    arrayGameMode.Push(GetNativeCell(7));     // Index: 6
    arrayGameMode.Push(GetNativeCell(8));     // Index: 7
    arrayGameMode.Push(GetNativeCell(9));     // Index: 8
    arrayGameMode.Push(GetNativeCell(10));    // Index: 9

    // Store this handle in the main array
    arrayGameModes.Push(arrayGameMode);
    
    // Return id under which we registered the item
    return GetArraySize(arrayGameModes)-1;
}

/**
 * Gets the name of a game mode at a given index.
 *
 * native void ZP_GetGameModeName(iD, sName, maxLen);
 **/
public int API_GetGameModeName(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "No buffer size");
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
public int API_GetGameModeDesc(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize description char
    static char sName[SMALL_LINE_LENGTH];
    ModesGetDesc(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the sound of a game mode at a given index.
 *
 * native void ZP_GetGameModeSound(iD, sName, maxLen);
 **/
public int API_GetGameModeSound(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);

    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize sound char
    static char sName[SMALL_LINE_LENGTH];
    ModesGetSound(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the chance of the game mode.
 *
 * native int ZP_GetGameModeChance(iD);
 **/
public int API_GetGameModeChance(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
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
public int API_GetGameModeMinPlayers(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
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
public int API_GetGameModeRatio(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return iD;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
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
public int API_IsGameModeInfect(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
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
public int API_IsGameModeRespawn(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
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
public int API_IsGameModeSurvivor(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
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
public int API_IsGameModeNemesis(Handle isPlugin, int iNumParams)
{
    // Gets mode index from native cell
    int iD = GetNativeCell(1);
    
    // Validate no game mode
    if(iD == -1)
    {
        return false;
    }
    
    // Validate index
    if(iD >= GetArraySize(arrayGameModes))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Gamemodes, "Native Validation", "Invalid the mode index (%d)", iD);
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
stock void ModesGetName(int iD, char[] sName, int iMaxLen)
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
stock void ModesGetDesc(int iD, char[] sDesc, int iMaxLen)
{
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode description
    arrayGameMode.GetString(GAMEMODES_DATA_DESCRIPTION, sDesc, iMaxLen);
}

/**
 * Gets the sound of a game mode at a given index.
 *
 * @param iD                The game mode index.
 * @param sSound            The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void ModesGetSound(int iD, char[] sSound, int iMaxLen)
{
    // Gets array handle of game mode at given index
    ArrayList arrayGameMode = arrayGameModes.Get(iD);
    
    // Gets game mode sound
    arrayGameMode.GetString(GAMEMODES_DATA_SOUND, sSound, iMaxLen);
}

/**
 * Gets the chance of the game mode.
 *
 * @param iD                The game mode index.
 * @return                  The chance amount.
 **/
stock int ModesGetChance(int iD)
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
stock int ModesGetMinPlayers(int iD)
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
stock float ModesGetRatio(int iD)
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
stock bool ModesIsInfection(int iD)
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
stock bool ModesIsRespawn(int iD)
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
stock bool ModesIsSurvivor(int iD)
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
stock bool ModesIsNemesis(int iD)
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