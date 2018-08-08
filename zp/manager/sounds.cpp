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
#define SoundBlocksMax 256

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
                if(DownloadsOnPrecache(sSoundsPath)) iSoundValidCount++; else iSoundUnValidCount++;
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

    // Forward event to sub-modules
    PlayerSoundsOnLoad();
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
void SoundsOnRoundEnd(const int CReason)
{
    // Forward event to sub-modules
    VoiceOnRoundEnd();
    SoundsInputStop();
    
    // Create timer for emit sounds 
    CreateTimer(0.1, PlayerSoundsOnRoundEnd, CReason, TIMER_FLAG_NO_MAPCHANGE); /// (Bug fix)
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
 * @param respawnMode       (Optional) Indicates that infection was on spawn.
 **/
void SoundsOnClientInfected(const int clientIndex, const bool respawnMode)
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
void SoundsOnClientHumanized(const int clientIndex)
{
    // Forward event to sub-modules
    VoiceOnClientHumanized(clientIndex);
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

/*
 * Sounds natives API.
 */

/**
 * Gets the key id from a given name.
 *
 * native int ZP_GetSoundKeyID(name);
 **/
public int API_GetSoundKeyID(Handle isPlugin, const int iNumParams)
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
public int API_GetSound(Handle isPlugin, const int iNumParams)
{
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate s
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Sounds, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), GetNativeCell(1), GetNativeCell(4));
    
    // Validate sound
    if(strlen(sSound))
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
    arraySound.GetString(view_as<int>(INVALID_HANDLE), sLine, iMaxLen);
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

/**
 * Emits a sound to all clients.
 *
 * @param iKey              The key array.
 * @param iNum              The position index.
 * @param entityIndex       (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speakerIndex      (Optional) Unknown.
 * @param vOrigin           (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (updates positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emit, false otherwise.
 **/
stock bool SoundsInputEmitToAll(int iKey, int iNum, const int entityIndex = SOUND_FROM_PLAYER, const int iChannel = SNDCHAN_AUTO, const int iLevel = SNDLEVEL_NORMAL, const int iFlags = SND_NOFLAGS, const float flVolume = SNDVOL_NORMAL, const int iPitch = SNDPITCH_NORMAL, const int speakerIndex = INVALID_ENT_REFERENCE, const float vOrigin[3] = NULL_VECTOR, const float vDirection[3] = NULL_VECTOR, const bool updatePos = true, const float flSoundTime = 0.0)
{
    // Initialize char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), iKey, iNum);
    
    // Validate sound
    if(strlen(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit normal sound
        EmitSoundToAll(sSound, entityIndex, iChannel, iLevel, iFlags, flVolume, iPitch, speakerIndex, vOrigin, vDirection, updatePos, flSoundTime);
        return true;
    }

    // Return on unsuccess
    return false;
}

/**
 * Emits an ambient sound to all clients.
 *
 * @param iKey              The key array.
 * @param iNum              The position index.
 * @param vOrigin           The origin of sound.
 * @param entityIndex       (Optional) The entity index to associate sound with.
 * @param iLevel            (Optional) The sound level (from 0 to 255).
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The volume (from 0.0 to 1.0).
 * @param iPitch            (Optional) The pitch (from 0 to 255).
 * @param flDelay           (Optional) The play delay.
 * @return                  True if the sound was emit, false otherwise.
 **/
stock bool SoundsInputEmitAmbient(int iKey, int iNum, const float vOrigin[3], const int entityIndex = SOUND_FROM_WORLD, const int iLevel = SNDLEVEL_NORMAL,const int iFlags = SND_NOFLAGS, const float flVolume = SNDVOL_NORMAL, const int iPitch = SNDPITCH_NORMAL, const float flDelay = 0.0)
{
    // Initialize char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), iKey, iNum);
    
    // Validate sound
    if(strlen(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit ambient sound
        EmitAmbientSound(sSound, vOrigin, entityIndex, iLevel, iFlags, flVolume, iPitch, flDelay);
        return true;
    }

    // Return on unsuccess
    return false;
}

/**
 * Stop sounds.
 **/
stock void SoundsInputStop(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate real client
        if(IsPlayerExist(i, false) && !IsFakeClient(i))
        {
            // Stop sound
            ClientCommand(i, "playgamesound Music.StopAllExceptMusic");
        }
    }
}
