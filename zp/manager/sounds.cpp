/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          sounds.cpp
 *  Type:          Manager 
 *  Description:   Sound table generator.
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

/*
 * Load other sound effect modules
 */
#include "zp/manager/soundeffects/voice.cpp"
#include "zp/manager/soundeffects/playersounds.cpp"
 
/**
 * Number of max valid sounds blocks.
 **/
#define SoundBlocksMax 128

/**
 * Array handle to store soundtable config data.
 **/
ArrayList arraySounds;

/**
 * Array for parsing strings.
 **/
int SoundBuffer[SoundBlocksMax][ParamParseResult];

/**
 * Sounds module init function.
 **/
void SoundsInit(/*void*/)
{
    // Hooks server sounds
    AddNormalSoundHook(view_as<NormalSHook>(PlayerSoundsNormalHook));
}

/**
 * Prepare all sound/download data.
 **/
void SoundsLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Sounds, Structure_ArrayList, CONFIG_FILE_ALIAS_SOUNDS);

    // Gets sounds file path
    static char sSoundsPath[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_SOUNDS, sSoundsPath);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing sounds file: \"%s\"", sSoundsPath);
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_Sounds, sSoundsPath);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Sounds, arraySounds, PLATFORM_MAX_PATH);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Unexpected error encountered loading: \"%s\"", sSoundsPath);
    }
    
    // Log what sounds file that is loaded
    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Loading sounds from file \"%s\"", sSoundsPath);

    // Initialize numbers of sounds
    int iSoundCount;
    int iSoundValidCount;
    int iSoundUnValidCount;
    
    // Validate sound config
    int iSounds = iSoundCount = arraySounds.Length;
    if(!iSounds)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "No usable data found in sounds config file: \"%s\"", sSoundsPath);
    }
    
    // i = sound array index
    for(int i = 0; i < iSounds; i++)
    {
        // Gets array line
        sSoundsPath[0] = '\0'; SoundsGetLine(i, sSoundsPath, sizeof(sSoundsPath));

        // Parses a parameter string in key="value" format and store the result in a ParamParseResult array
        if(ParamParseString(SoundBuffer, sSoundsPath, sizeof(sSoundsPath), i) == PARAM_ERROR_NO)
        {
            // Count number of parts inside of string
            static char sSound[PARAM_VALUE_MAXPARTS][PLATFORM_MAX_PATH];
            int nSounds = ExplodeString(sSoundsPath, ",", sSound, sizeof(sSound), sizeof(sSound[]));
            
            // Gets array size
            ArrayList arraySound = arraySounds.Get(i);
            
            // Breaks a string into pieces and stores each piece into an array of buffers
            for(int x = 0; x < nSounds; x++)
            {
                // Trim string
                TrimString(sSound[x]);
                
                // Strips a quote pair off a string 
                StripQuotes(sSound[x]);

                // Push data into array
                arraySound.PushString(sSound[x]);
                
                // Format the full path
                Format(sSoundsPath, sizeof(sSoundsPath), "sound/%s", sSound[x]);

                // Add to server precache list
                if(fnMultiFilePrecache(sSoundsPath)) iSoundValidCount++; else iSoundUnValidCount++;
            }
        }
        else
        {
            // Log sound error info
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Error with parsing of sound block: %d", i + 1);
            
            // Remove sound block from array
            arraySounds.Erase(i);

            // Subtract one from count
            iSounds--;

            // Backtrack one index, because we deleted it out from under the loop
            i--;
            continue;
        }
    }
    
    // Log sound validation info
    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Total blocks: %d | Unsuccessful blocks: %d | Total: %d | Successful: %d | Unsuccessful: %d", iSoundCount, iSoundCount - iSounds, iSoundValidCount + iSoundUnValidCount, iSoundValidCount, iSoundUnValidCount);
    
    // Sets config data
    ConfigSetConfigLoaded(File_Sounds, true);
    ConfigSetConfigReloadFunc(File_Sounds, GetFunctionByName(GetMyHandle(), "SoundsOnConfigReload"));
    ConfigSetConfigHandle(File_Sounds, arraySounds);
}

/**
 * Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void SoundsOnConfigReload(ConfigFile iConfig)
{
    // Reload download config
    SoundsLoad();
}

/**
 * The round is starting.
 **/
void SoundsOnRoundStart(/*void*/)
{
    // Forward event to sub-modules
    VoiceOnRoundStart();
}

/**
 * The round is ending.
 *
 * @param CReason           Reason the round has ended.
 **/
void SoundsOnRoundEnd(int CReason)
{
    // Forward event to sub-modules
    VoiceOnRoundEnd();
    SoundsInputStop();
    
    // Create timer for emit sounds 
    CreateTimer(0.1, SoundsOnRoundEndPost, CReason, TIMER_FLAG_NO_MAPCHANGE); /// (Bug fix)
}

/**
 * The round is ending. (Post)
 *
 * @param CReason           Reason the round has ended.
 **/
public Action SoundsOnRoundEndPost(Handle hTimer, int CReason)
{
    // Switch end round reason
    switch(CReason)
    {
        // Emit sounds
        case ROUNDEND_TERRORISTS_WIN : SoundsInputEmitToAll("ROUND_ZOMBIE_SOUNDS");   
        case ROUNDEND_CTS_WIN :        SoundsInputEmitToAll("ROUND_HUMAN_SOUNDS");
        case ROUNDEND_ROUND_DRAW :     SoundsInputEmitToAll("ROUND_DRAW_SOUNDS");
    }
}

/**
 * Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientDeath(int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientDeath(clientIndex);
}

/**
 * Client has been hurt.
 * 
 * @param clientIndex       The client index.
 * @param damageBits        The type of damage inflicted.
 **/
void SoundsOnClientHurt(int clientIndex, int damageBits)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientHurt(clientIndex, (damageBits & DMG_BURN || damageBits & DMG_DIRECT));
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 **/
void SoundsOnClientInfected(int clientIndex, bool respawnMode)
{
    // Forward event to sub-modules
    VoiceOnClientInfected(clientIndex);
    PlayerSoundsOnClientInfected(clientIndex, respawnMode);
}

/**
 * Client has been humanized.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientHumanized(int clientIndex)
{
    // Forward event to sub-modules
    VoiceOnClientHumanized(clientIndex);
}

/**
 * Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientRegen(int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientRegen(clientIndex);
}

/*
 * Sounds natives API.
 */

/**
 * Emits random sound from a block from sounds config.
 *
 * native bool ZP_EmitSound(sKey, clientIndex);
 **/
public int API_EmitSound(Handle isPlugin, int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Sounds, "Native Validation", "Can't find block with an empty name");
        return -1;
    }

    // Gets native data
    char sSoundKey[SMALL_LINE_LENGTH];

    // General                                            
    GetNativeString(1, sSoundKey, sizeof(sSoundKey));

    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(2);

    // Play sound to client
    return IsPlayerExist(clientIndex) ? SoundsInputEmitToClient(clientIndex, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, sSoundKey) : SoundsInputEmitToAll(sSoundKey);
}
 
/*
 * Sounds data reading API.
 */

/**
 * Gets the line from a sound list.
 * 
 * @param iD                The sound array index.
 * @param sLine             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void SoundsGetLine(int iD, char[] sLine, int iMaxLen)
{
    // Gets array handle of weapon at given index
    ArrayList arraySound = arraySounds.Get(iD);
    
    // Gets line
    arraySound.GetString(view_as<int>(INVALID_HANDLE), sLine, iMaxLen);
}
 
/**
 * Gets the current sound from a 2D array.
 * 
 * @param sLine             The string to return name in.
 * @param iMaxLen           The max length of the string.
 * @param sKey              The key to search for array ID.
 * @param iNum              The number of sound in 2D array. (Optional) If 0 sound will be choose randomly from key.
 **/
stock void SoundsGetSound(char[] sLine, int iMaxLen, char[] sKey, int iNum = 0)
{
    // Gets number of sound block
    int iBlockNum = ParamFindKey(SoundBuffer, SoundBlocksMax, sKey);
    
    // If block didn't find, then stop
    if(iBlockNum == -1)
    {
        return;
    }
    
    // Gets array handle of weapon at given index
    ArrayList arraySound = arraySounds.Get(iBlockNum);

    // Gets size of array handle
    int iSize = arraySound.Length;
    
    // Validate size
    if(iNum >= iSize)
    {
        return;
    }
    
    // Gets sound name
    arraySound.GetString(iNum ? iNum : GetRandomInt(1, iSize - 1), sLine, iMaxLen);
}

/**
 * Emits sounds to all players.
 * 
 * @param sKey              The key to search for array ID.
 * @param nNum              (Optional) The number of sound from the key array.
 * @return                  True if the sound was emit, false otherwise.
 **/
stock bool SoundsInputEmitToAll(char[] sKey, int nNum = 0)
{
    // Initialize char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), sKey, nNum);
    
    // Validate sound
    if(strlen(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);
        
        // Emit sound
        EmitSoundToAll(sSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue);
        return true;
    }

    // Return on unsuccess
    return false;
}

/**
 * Emits sounds to particular player.
 * 
 * @param clientIndex       The client index.
 * @param iChannel          The channel to emit with.
 * @param nLevel            The sound level.
 * @param sKey              The key to search for array ID.
 * @param entityIndex       (Optional) The entity to emit from.  
 * @return                  True if the sound was emit, false otherwise.
 **/
stock bool SoundsInputEmitToClient(int clientIndex, int iChannel, int nLevel, char[] sKey, int entityIndex = 0)
{
    // Initialize char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), sKey);
    
    // Validate sound
    if(strlen(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit sound
        EmitSoundToAll(sSound, entityIndex ? entityIndex : clientIndex, iChannel, nLevel);
        return true;
    }

    // Return on unsuccess
    return false;
}

/**
 * Stop sound to the all players.
 *  
 * @param sSound            The path to the sound file (relative to sounds/) 
 **/
stock void SoundsInputStop(/*const char[] sSound*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i, false))
        {
            // Stop sound
            ClientCommand(i, "playgamesound Music.StopAllExceptMusic"); 
            ClientCommand(i, "playgamesound Music.StopAllMusic"); 
            ClientCommand(i, "playgamesound Music.StopAll");
        }
    }
}
