/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          sounds.cpp
 *  Type:          Manager 
 *  Description:   Basic sound-management API.
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
    SOUNDS_DATA_KEY,
    SOUNDS_DATA_VALUE
};
/**
 * @endsection
 **/
 
/*
 * Load other sound effect modules
 */
#include "zp/manager/soundeffects/voice.cpp"
#include "zp/manager/soundeffects/ambientsounds.cpp"
#include "zp/manager/soundeffects/soundeffects.cpp"
#include "zp/manager/soundeffects/playersounds.cpp"

/**
 * @brief Sounds module init function.
 **/
void SoundsOnInit(/*void*/)
{
    // Hooks server sounds
    AddNormalSoundHook(view_as<NormalSHook>(PlayerSoundsNormalHook));
}

/**
 * @brief Prepare all sound data.
 **/
void SoundsOnLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Sounds, Structure_ArrayList, CONFIG_FILE_ALIAS_SOUNDS);

    // Gets sounds file path
    static char sPathSounds[PLATFORM_LINE_LENGTH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_SOUNDS, sPathSounds);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Sounds, "Config Validation", "Missing sounds file: \"%s\"", sPathSounds);
        return;
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Sounds, sPathSounds);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Sounds, gServerData.Sounds, PLATFORM_LINE_LENGTH);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Sounds, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathSounds);
        return;
    }
    
    // Now copy data to array structure
    SoundsOnCacheData();
    
    // Sets config data
    ConfigSetConfigLoaded(File_Sounds, true);
    ConfigSetConfigReloadFunc(File_Sounds, GetFunctionByName(GetMyHandle(), "SoundsOnConfigReload"));
    ConfigSetConfigHandle(File_Sounds, gServerData.Sounds);

    // Forward event to sub-modules
    PlayerSoundsOnOnLoad();
}

/**
 * @brief Caches sound data from file into arrays.
 **/
void SoundsOnCacheData(/*void*/)
{
    // Gets config file path
    static char sPathSounds[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(File_Sounds, sPathSounds, sizeof(sPathSounds));
    
    // Log what sounds file that is loaded
    LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_Sounds, "Config Validation", "Loading sounds from file \"%s\"", sPathSounds);

    // Initialize numbers of sounds
    int iSoundCount;
    int iSoundValidCount;
    int iSoundUnValidCount;
    
    // Validate sound config
    int iSounds = iSoundCount = gServerData.Sounds.Length;
    if(!iSounds)
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Sounds, "Config Validation", "No usable data found in sounds config file: \"%s\"", sPathSounds);
        return;
    }
    
    // i = sound array index
    for(int i = 0; i < iSounds; i++)
    {
        // Gets array line
        ArrayList arraySound = SoundsGetKey(i, sPathSounds, sizeof(sPathSounds), true);

        // Parses a parameter string in key="value" format
        if(ParamParseString(arraySound, sPathSounds, sizeof(sPathSounds), '=') == PARAM_ERROR_NO)
        {
            // i = block index
            int iSize = arraySound.Length;
            for(int x = 1; x < iSize; x++)
            {
                // Gets sound path
                arraySound.GetString(x, sPathSounds, sizeof(sPathSounds));

                // Format the full path
                Format(sPathSounds, sizeof(sPathSounds), "sound/%s", sPathSounds);

                // Add to server precache list
                if(DownloadsOnPrecache(sPathSounds)) iSoundValidCount++; else iSoundUnValidCount++;
            }
        }
        else
        {
            // Log sound error info
            LogEvent(false, LogType_Error, LOG_GAME_EVENTS, LogModule_Sounds, "Config Validation", "Error with parsing of the sound block: \"%d\" = \"%s\"", i + 1, sPathSounds);
            
            // Remove sound block from array
            gServerData.Sounds.Erase(i);

            // Subtract one from count
            iSounds--;

            // Backtrack one index, because we deleted it out from under the loop
            i--;
        }
    }
    
    // Log sound validation info
    LogEvent(true, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Sounds, "Config Validation", "Total blocks: \"%d\" | Unsuccessful blocks: \"%d\" | Total: %d | Successful: \"%d\" | Unsuccessful: \"%d\"", iSoundCount, iSoundCount - iSounds, iSoundValidCount + iSoundUnValidCount, iSoundValidCount, iSoundUnValidCount);
}

/**
 * @brief Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void SoundsOnConfigReload(ConfigFile iConfig)
{
    // Reloads download config
    SoundsOnLoad();
}

/**
 * @brief Hook sounds cvar changes.
 **/
void SoundsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_SEFFECTS_LEVEL] = FindConVar("zp_seffects_level");
    
    // Forward event to sub-modules
    VoiceOnCvarInit();
    PlayerSoundsOnCvarInit();
}

/*
 * Sounds main functions.
 */

/**
 * @brief The round is starting.
 **/
void SoundsOnRoundStart(/*void*/)
{
    // Forward event to sub-modules
    VoiceOnRoundStart();
}

/**
 * @brief The counter is begin.
 **/
void SoundsOnCounterStart(/*void*/)   
{
    // Forward event to sub-modules
    PlayerSoundsOnCounterStart();
}

/**
 * @brief The round is ending.
 *
 * @param reasonIndex       The reason index.
 **/
void SoundsOnRoundEnd(const CSRoundEndReason reasonIndex)
{
    // Forward event to sub-modules
    VoiceOnRoundEnd();
    
    // Create timer for emit sounds
    SEffectsInputStopAll(); CreateTimer(0.2, PlayerSoundsOnRoundEndPost, reasonIndex, TIMER_FLAG_NO_MAPCHANGE); /// (Bug fix)
}

/**
 * @brief The counter is working.
 *
 * @return                  True or false.
 **/
bool SoundsOnCounter(/*void*/)
{
    // Forward event to sub-modules
    return PlayerSoundsOnCounter();
}

/**
 * @brief The gamemode is starting.
 **/
void SoundsOnGameModeStart(/*void*/)
{
    // Forward event to sub-modules
    PlayerSoundsOnGameModeStart();
    AmbientSoundsOnGameModeStart();
}

/**
 * @brief Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientDeath(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientDeath(clientIndex);
}

/**
 * @brief Client has been hurt.
 * 
 * @param clientIndex       The client index.
 * @param iBits             The type of damage inflicted.
 **/
void SoundsOnClientHurt(const int clientIndex, const int iBits)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientHurt(clientIndex, ((iBits & DMG_BURN) || (iBits & DMG_DIRECT)));
}

/**
 * @brief Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
void SoundsOnClientInfected(const int clientIndex, const int attackerIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientInfected(clientIndex, attackerIndex);
}

/**
 * @brief Client has been changed class state.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientUpdate(const int clientIndex)
{
    // Forward event to sub-modules
    VoiceOnClientUpdate(clientIndex);
    AmbientSoundsOnClientUpdate(clientIndex);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientRegen(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientRegen(clientIndex);
}

/**
 * @brief Client has been swith nightvision.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientNvgs(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientNvgs(clientIndex);
}

/**
 * @brief Client has been swith flashlight.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientFlashLight(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientFlashLight(clientIndex);
}

/**
 * @brief Client has been buy ammunition.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientAmmunition(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientAmmunition(clientIndex);
}

/**
 * @brief Client has been level up.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientLevelUp(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientLevelUp(clientIndex);
}

/**
 * @brief Client has been shoot.
 * 
 * @param clientIndex       The client index.
 * @param iD                The weapon id.
 **/
Action SoundsOnClientShoot(const int clientIndex, const int iD)
{
    // Forward event to sub-modules
    return PlayerSoundsOnClientShoot(clientIndex, iD) ? Plugin_Stop : Plugin_Continue;
}

/*
 * Sounds natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void SoundsOnNativeInit(/*void*/) 
{
    CreateNative("ZP_GetSoundKeyID", API_GetSoundKeyID);
    CreateNative("ZP_GetSound",      API_GetSound);
}
 
/**
 * @brief Gets the key id from a given key.
 *
 * @note native int ZP_GetSoundKeyID(name);
 **/
public int API_GetSoundKeyID(Handle hPlugin, const int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Sounds, "Native Validation", "Can't find key with an empty name");
        return -1;
    }

    // Gets native data
    static char sName[SMALL_LINE_LENGTH];

    // General                                            
    GetNativeString(1, sName, sizeof(sName));

    // Return the value
    return SoundsKeyToIndex(sName);
}

/**
 * @brief Gets sound from a key id from sounds config.
 *
 * @note native void ZP_GetSound(keyID, sound, maxlenght, position);
 **/
public int API_GetSound(Handle hPlugin, const int iNumParams)
{
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate s
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_GAME_EVENTS, LogModule_Sounds, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize sound char
    static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = '\0';
    
    // Gets sound path
    SoundsGetPath(GetNativeCell(1), sSound, sizeof(sSound), GetNativeCell(4));
    
    // Validate sound
    if(hasLength(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);
    }
    
    // Return on success
    return SetNativeString(2, sSound, maxLen);
}
 
/*
 * Sounds data reading API. 
 */

/**
 * @brief Gets the key of a sound list at a given key.
 * 
 * @param iKey              The sound array index.
 * @param sKey              The string to return key in.
 * @param iMaxLen           The lenght of string.
 * @param bDelete           (Optional) Clear the array key position.
 **/
ArrayList SoundsGetKey(const int iKey, char[] sKey, const int iMaxLen, const bool bDelete = false)
{
    // Gets array handle of sound at given index
    ArrayList arraySound = gServerData.Sounds.Get(iKey);
    
    // Gets sound key
    arraySound.GetString(SOUNDS_DATA_KEY, sKey, iMaxLen);
    
    // Shifting array value
    if(bDelete) arraySound.Erase(SOUNDS_DATA_KEY);
    
    // Return array list
    return arraySound;
}
 
/**
 * @brief Gets the path of a sound list at a given key.
 * 
 * @param iKey              The sound array index.
 * @param sPath             The string to return name in.
 * @param iMaxLen           The lenght of string.
 * @param iNum              (Optional) The position index. (for not random sound)
 **/
void SoundsGetPath(const int iKey, char[] sPath, const int iMaxLen, const int iNum = 0)
{
    // Validate key
    if(iKey == -1)
    {
        return;
    }
    
    // Gets array handle of sound at given index
    ArrayList arraySound = gServerData.Sounds.Get(iKey);

    // Validate size
    int iSize = arraySound.Length;
    if(iNum < iSize)
    {
        // Gets sound path
        arraySound.GetString(iNum ? iNum : GetRandomInt(SOUNDS_DATA_VALUE, iSize - 1), sPath, iMaxLen);
    }
}

/**
 * @brief Stops a sound list at a given key.
 * 
 * @param iKey              The sound array index.
 * @param clientIndex       (Optional) The client index.
 * @param iChannel          (Optional) The channel to emit with.
 **/
void SoundsStopAll(const int iKey, const int clientIndex = -1, const int iChannel = SNDCHAN_AUTO)
{
    // Initialize sound char
    static char sSound[PLATFORM_LINE_LENGTH];
    
    // Gets array handle of sound at given index
    ArrayList arraySound = gServerData.Sounds.Get(iKey);

    // i = sound index
    int iSize = arraySound.Length;
    for(int i = 1; i < iSize; i++)
    {
        // Gets sound path
        arraySound.GetString(i, sSound, sizeof(sSound));
        
        // Validate sound
        if(hasLength(sSound))
        {
            // Format sound
            Format(sSound, sizeof(sSound), "*/%s", sSound);
            
            // Validate client
            if(IsPlayerExist(clientIndex, false) && !IsFakeClient(clientIndex))
            {
                // Stop sound
                StopSound(clientIndex, iChannel, sSound);
            }
            else
            {
                // x = client index
                for(int x = 1; x <= MaxClients; x++)
                {
                    // Validate real client
                    if(IsPlayerExist(x, false) && !IsFakeClient(x))
                    {
                        // Stop sound
                        StopSound(x, iChannel, sSound);
                    }
                }
            }
        }
    }
}

/*
 * Stocks sounds API.
 */

/**
 * @brief Find the random index at which the sound key is at.
 * 
 * @param sKey              The key name.
 * @return                  The array index containing the given sound key.
 **/
int SoundsKeyToIndex(const char[] sKey)
{
    // Initialize key char
    static char sSoundKey[SMALL_LINE_LENGTH]; 
    
    // i = block index
    int iSize = gServerData.Sounds.Length; int iRandom; static int keyIndex[MAXPLAYERS+1];
    for(int i = 0; i < iSize; i++)
    {
        // Gets sound key 
        SoundsGetKey(i, sSoundKey, sizeof(sSoundKey));
        
        // If keys match, then store index
        if(!strcmp(sSoundKey, sKey, false))
        {
            // Increment amount
            keyIndex[iRandom++] = i;
        }
    }
    
    // Return index
    return (iRandom) ? keyIndex[GetRandomInt(0, iRandom-1)] : -1;
}