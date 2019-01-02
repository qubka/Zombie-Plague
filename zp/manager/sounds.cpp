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

/*
 * Load other sound effect modules
 */
#include "zp/manager/soundeffects/voice.cpp"
#include "zp/manager/soundeffects/ambientsounds.cpp"
#include "zp/manager/soundeffects/soundeffects.cpp"
#include "zp/manager/soundeffects/playersounds.cpp"

/**
 * Array handle to store soundtable config data.
 **/
ArrayList arraySounds;

/**
 * Array for parsing strings.
 **/
int SoundBuffer[2048][ParamParseResult];

/**
 * Sounds module init function.
 **/
void SoundsInit(/*void*/)
{
    // Hooks server sounds
    AddNormalSoundHook(view_as<NormalSHook>(PlayerSoundsNormalHook));
}

/**
 * Prepare all sound data.
 **/
void SoundsLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Sounds, Structure_ArrayList, CONFIG_FILE_ALIAS_SOUNDS);

    // Gets sounds file path
    static char sPathSounds[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetFullPath(CONFIG_PATH_SOUNDS, sPathSounds);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing sounds file: \"%s\"", sPathSounds);
    }

    // Sets path to the config file
    ConfigSetConfigPath(File_Sounds, sPathSounds);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Sounds, arraySounds, PLATFORM_MAX_PATH);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Unexpected error encountered loading: \"%s\"", sPathSounds);
    }
    
    // Now copy data to array structure
    SoundsCacheData();
    
    // Sets config data
    ConfigSetConfigLoaded(File_Sounds, true);
    ConfigSetConfigReloadFunc(File_Sounds, GetFunctionByName(GetMyHandle(), "SoundsOnConfigReload"));
    ConfigSetConfigHandle(File_Sounds, arraySounds);

    // Forward event to sub-modules
    PlayerSoundsOnLoad();
}

/**
 * Caches sound data from file into arrays.
 * Make sure the file is loaded before (ConfigLoadConfig) to prep array structure.
 **/
void SoundsCacheData(/*void*/)
{
    // Gets config file path
    static char sPathSounds[PLATFORM_MAX_PATH];
    ConfigGetConfigPath(File_Sounds, sPathSounds, sizeof(sPathSounds));
    
    // Log what sounds file that is loaded
    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Loading sounds from file \"%s\"", sPathSounds);

    // Initialize numbers of sounds
    int iSoundCount;
    int iSoundValidCount;
    int iSoundUnValidCount;
    
    // Validate sound config
    int iSounds = iSoundCount = arraySounds.Length;
    if(!iSounds)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "No usable data found in sounds config file: \"%s\"", sPathSounds);
    }
    
    // i = sound array index
    for(int i = 0; i < iSounds; i++)
    {
        // Gets array line
        sPathSounds[0] = '\0'; SoundsGetLine(i, sPathSounds, sizeof(sPathSounds));

        // Parses a parameter string in key="value" format and store the result in a ParamParseResult array
        if(ParamParseString(SoundBuffer, sPathSounds, sizeof(sPathSounds), '=', i) == PARAM_ERROR_NO)
        {
            // Count number of parts inside of string
            static char sSound[PARAM_VALUE_MAXPARTS][PLATFORM_MAX_PATH];
            int nSounds = ExplodeString(sPathSounds, ",", sSound, sizeof(sSound), sizeof(sSound[]));
            
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
                FormatEx(sPathSounds, sizeof(sPathSounds), "sound/%s", sSound[x]);

                // Add to server precache list
                if(DownloadsOnPrecache(sPathSounds)) iSoundValidCount++; else iSoundUnValidCount++;
            }
        }
        else
        {
            // Log sound error info
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Error with parsing of sound block: %d = \"%s\"", i + 1, sPathSounds);
            
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
}

/**
 * Hook sounds cvar changes.
 **/
void SoundsOnCvarInit(/*void*/)
{
    // Create cvars
    gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL] = FindConVar("zp_game_custom_sound_level");
    
    // Forward event to sub-modules
    VoiceOnCvarInit();
    PlayerSoundsOnCvarInit();
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
 * The counter is begin.
 **/
void SoundsOnCounterStart(/*void*/)   
{
    // Forward event to sub-modules
    PlayerSoundsOnCounterStart();
}

/**
 * The round is ending.
 *
 * @param CReason           Reason the round has ended.
 **/
void SoundsOnRoundEnd(const CSRoundEndReason CReason)
{
    // Forward event to sub-modules
    VoiceOnRoundEnd();
    
    // Create timer for emit sounds
    SEffectsInputStopAll(); CreateTimer(0.2, PlayerSoundsOnRoundEndPost, CReason, TIMER_FLAG_NO_MAPCHANGE); /// (Bug fix)
}

/**
 * The counter is working.
 *
 * @return                  True or false.
 **/
bool SoundsOnCounter(/*void*/)
{
    // Forward event to sub-modules
    return PlayerSoundsOnCounter();
}

/**
 * The gamemode is starting.
 **/
void SoundsOnGameModeStart(/*void*/)
{
    // Forward event to sub-modules
    PlayerSoundsOnGameModeStart();
    AmbientSoundsOnGameModeStart();
}

/**
 * Client has been killed.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientDeath(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientDeath(clientIndex);
}

/**
 * Client has been hurt.
 * 
 * @param clientIndex       The client index.
 * @param damageType        The type of damage inflicted.
 **/
void SoundsOnClientHurt(const int clientIndex, const int damageType)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientHurt(clientIndex, (damageType & DMG_BURN || damageType & DMG_DIRECT));
}

/**
 * Client has been infected.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 **/
void SoundsOnClientInfected(const int clientIndex, const int attackerIndex)
{
    // Forward event to sub-modules
    VoiceOnClientInfected(clientIndex);
    PlayerSoundsOnClientInfected(clientIndex, attackerIndex);
    AmbientSoundsOnClientUpdate(clientIndex);
}

/**
 * Client has been humanized.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientHumanized(const int clientIndex)
{
    // Forward event to sub-modules
    VoiceOnClientHumanized(clientIndex);
    AmbientSoundsOnClientUpdate(clientIndex);
}

/**
 * Client has been regenerating.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientRegen(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientRegen(clientIndex);
}

/**
 * Client has been swith nightvision.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientNvgs(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientNvgs(clientIndex);
}

/**
 * Client has been swith flashlight.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientFlashLight(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientFlashLight(clientIndex);
}

/**
 * Client has been buy ammunition.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientAmmunition(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientAmmunition(clientIndex);
}

/**
 * Client has been level up.
 * 
 * @param clientIndex       The client index.
 **/
void SoundsOnClientLevelUp(const int clientIndex)
{
    // Forward event to sub-modules
    PlayerSoundsOnClientLevelUp(clientIndex);
}

/**
 * Client has been shoot.
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
 * Sets up natives for library.
 **/
void SoundsAPI(/*void*/) 
{
    CreateNative("ZP_GetSoundKeyID", API_GetSoundKeyID);
    CreateNative("ZP_GetSound",      API_GetSound);
}
 
/**
 * Gets the key id from a given name.
 *
 * native int ZP_GetSoundKeyID(name);
 **/
public int API_GetSoundKeyID(Handle hPlugin, const int iNumParams)
{
    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Sounds, "Native Validation", "Can't find key with an empty name");
        return -1;
    }

    // Gets native data
    static char sName[PARAM_NAME_MAXLEN];

    // General                                            
    GetNativeString(1, sName, sizeof(sName));

    // Return the value
    return SoundsKeyToIndex(sName);
}

/**
 * Gets sound from a key id from sounds config.
 *
 * native void ZP_GetSound(keyID, sound, maxlenght, position);
 **/
public int API_GetSound(Handle hPlugin, const int iNumParams)
{
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate s
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Sounds, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize sound char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), GetNativeCell(1), GetNativeCell(4));
    
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
 * Gets the line from a sound list.
 * 
 * @param iD                The sound array index.
 * @param sLine             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void SoundsGetLine(const int iD, char[] sLine, const int iMaxLen)
{
    // Gets array handle of sound at given index
    ArrayList arraySound = arraySounds.Get(iD);
    
    // Gets line
    arraySound.GetString(0, sLine, iMaxLen);
}
 
/**
 * Gets the current sound from a 2D array.
 * 
 * @param sLine             The string to return name in.
 * @param iMaxLen           The max length of the string.
 * @param iKey              The key index.
 * @param iNum              The position index.
 **/
stock void SoundsGetSound(char[] sLine, const int iMaxLen, const int iKey, const int iNum)
{
    // Validate key
    if(iKey != -1)
    {
        // Gets array handle of sound at given index
        ArrayList arraySound = arraySounds.Get(iKey);

        // Gets size of array handle
        int iSize = arraySound.Length;
        
        // Validate size
        if(iNum < iSize)
        {
            // Gets sound name
            arraySound.GetString(iNum ? iNum : GetRandomInt(1, iSize - 1), sLine, iMaxLen);
        }
    }
}

/**
 * Find the index at which the key is at.
 * 
 * @param sKey              The key name.
 * @return                  The array index containing the given key.
 **/
stock int SoundsKeyToIndex(const char[] sKey)
{
    // Find key index
    return ParamFindKey(SoundBuffer, arraySounds.Length, sKey);
}