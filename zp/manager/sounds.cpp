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

/**
 * Number of max valid sounds blocks.
 **/
#define SoundBlocksMax 64

/**
 * Array handle to store soundtable config data.
 **/
ArrayList arraySounds;

/**
 * Array for parsing strings.
 **/
int SoundBuffer[SoundBlocksMax][ParamParseResult];

/**
 * Prepare all sound/download data.
 **/
void SoundsLoad(/*void*/)
{
	// Register config file
	ConfigRegisterConfig(File_Sounds, Structure_ArrayList, CONFIG_FILE_ALIAS_SOUNDS);

	// Get sounds file path
	static char sSoundsPath[PLATFORM_MAX_PATH];
	bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_SOUNDS, sSoundsPath);

	// If file doesn't exist, then log and stop
	if(!bExists)
	{
		// Log failure and stop plugin
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing sounds file: \"%s\"", sSoundsPath);
	}

	// Set the path to the config file
	ConfigSetConfigPath(File_Sounds, sSoundsPath);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_Sounds, arraySounds, PLATFORM_MAX_PATH);

	// Unexpected error, stop plugin
	if(!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Unexpected error encountered loading: %s", sSoundsPath);
	}
	
	// Log what sounds file that is loaded
	LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Loading sounds from file \"%s\".", sSoundsPath);
	
	// Validate sound config
	int iSize = GetArraySize(arraySounds);
	if(!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "No usable data found in sounds config file: %s", sSoundsPath);
	}
	
	// Initialize numbers of sounds
	int iSoundValidCount;
	int iSoundUnValidCount;
	
	// Initialize line char
	static char sLine[PLATFORM_MAX_PATH];
	
	// i = sound array index
	for (int i = 0; i < iSize; i++)
	{
		// Get array line
		SoundsGetLine(i, sLine, sizeof(sLine));

		// Parses a parameter string in key="value" format and store the result in a ParamParseResult array
		if(ParamParseString(SoundBuffer, sLine, sizeof(sLine), i) == PARAM_ERROR_NO)
		{
			// Count number of parts inside of string
			static char sSound[PARAM_VALUE_MAXPARTS][PLATFORM_MAX_PATH];
			int nSounds = ExplodeString(sLine, ",", sSound, sizeof(sSound), sizeof(sSound[]));
			
			// Get array size
			Handle arraySound = GetArrayCell(arraySounds, i);
			
			// Breaks a string into pieces and stores each piece into an array of buffers
			for(int x = 0; x < nSounds; x++)
			{
				// Trim string
				TrimString(sSound[x]);
				
				// Strips a quote pair off a string 
				StripQuotes(sSound[x]);

				// Push data into array
				PushArrayString(arraySound, sSound[x]);
				
				// Adding sound to download list
				Format(sLine, sizeof(sLine), "sound/%s", sSound[x]);
				AddFileToDownloadsTable(sLine);

				// If file doesn't exist, then log, and stop
				if(!FileExists(sLine))
				{
					iSoundUnValidCount++;
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing file \"%s\"", sLine);
					continue;
				}
				
				// Precache sound
				Format(sLine, sizeof(sLine), "*/%s", sSound[x]);
				AddToStringTable(FindStringTable("soundprecache"), sLine);
				
				// Increment downloadvalidcount
				iSoundValidCount++;
			}
		}
		else
		{
			// Log error
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Error with parsing of sound block: %i in sounds config file: %s", i + 1, sSoundsPath);
			
			// Remove sound block from array
			RemoveFromArray(arraySounds, i);

			// Subtract one from count
			iSize--;

			// Backtrack one index, because we deleted it out from under the loop
			i--;
			
			continue;
		}
	}
	
	// Log sound validation info
	LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Total: %d | Successful: %d | Unsuccessful: %d", iSoundValidCount + iSoundUnValidCount, iSoundValidCount, iSoundUnValidCount);

	// Set config data
	ConfigSetConfigLoaded(File_Sounds, true);
	ConfigSetConfigReloadFunc(File_Sounds, GetFunctionByName(GetMyHandle(), "SoundsOnConfigReload"));
	ConfigSetConfigHandle(File_Sounds, arraySounds);
	
	// Hooks server sounds
	AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
}

/**
 * Called when configs are being reloaded.
 * 
 * @param iConfig    		The config being reloaded. (only if'all' is false)
 **/
public void SoundsOnConfigReload(ConfigFile iConfig)
{
    // Reload download config
    SoundsLoad();
}

/*
 * Sounds data reading API.
 */

/**
 * Gets the line from a sound list.
 * 
 * @param iD				The sound array index.
 * @param sLine				The string to return name in.
 * @param iMaxLen			The max length of the string.
 **/
stock void SoundsGetLine(int iD, char[] sLine, int iMaxLen)
{
    // Get array handle of weapon at given index
    Handle arraySound = GetArrayCell(arraySounds, iD);
    
    // Get line
    GetArrayString(arraySound, view_as<int>(NULL), sLine, iMaxLen);
}

/*
 * Sounds natives API.
 */

/**
 * Gets the current sound from a 2D array.
 * 
 * @param sLine				The string to return name in.
 * @param iMaxLen			The max length of the string.
 * @param sKey				The key to search for array ID.
 * @param iNum				The number of sound in 2D array. (Optional) If 0 sound will be choose randomly from key.
 **/
stock void SoundsGetSound(char[] sLine, int iMaxLen, char[] sKey, int iNum = 0)
{
	// Get number of sound block
	int iBlockNum = ParamFindKey(SoundBuffer, SoundBlocksMax, sKey);
	
	// If block didn't find, then stop
	if(iBlockNum == -1)
	{
		return;
	}
	
	// Get array handle of weapon at given index
	Handle arraySound = GetArrayCell(arraySounds, iBlockNum);

	// Get size of array handle
	int iSize = GetArraySize(arraySound);
	
	// Validate size
	if(iNum >= iSize)
	{
		return;
	}
	
	// Get sound name
	GetArrayString(arraySound, iNum ? iNum : GetRandomInt(1, iSize - 1), sLine, iMaxLen);
}

/**
 * Emits sounds to all players.
 * 
 * @param sKey				The key to search for array ID.
 * @param nNum				(Optional) The number of sound from the key array.
 **/
stock void SoundsInputEmitToAll(char[] sKey, int nNum = 0)
{
	// Initialize char
	static char sSound[BIG_LINE_LENGTH];
	
	// Select sound in the array
	SoundsGetSound(sSound, sizeof(sSound), sKey, nNum);
	
	// Validate sound
	if(strlen(sSound))
	{
		// Format sound
		Format(sSound, sizeof(sSound), "*/%s", sSound);
		
		// Emit sound
		EmitSoundToAll(sSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL);
	}
}

/*
 * Sounds server hooks.
 */

/**
 * Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients			Array of client's indexes.
 * @param numClients		Number of clients in the array (modify this value ifyou add/remove elements from the client array).
 * @param sSample			Sound file name relative to the "sounds" folder.
 * @param clientIndex		Entity emitting the sound.
 * @param iChannel			Channel emitting the sound.
 * @param flVolume			The sound volume.
 * @param iLevel			The sound level.
 * @param iPitch			The sound pitch.
 * @param iFrags			The sound flags.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &clientIndex, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFrags)
{
	// Get real player index from event key 
	CBasePlayer* cBasePlayer = CBasePlayer(clientIndex);

	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index))
	{
		return ACTION_CONTINUE;
	}

	// Verify that the client is zombie
	if(cBasePlayer->m_bZombie)
	{
		// If a footstep sound, then
		if(StrContains(sSample, "footsteps") != -1)
		{
			// Emit a custom footstep sound
			if(!GetConVarBool(gCvarList[CVAR_ZOMBIE_SILENT])) cBasePlayer->InputEmitAISound(SNDCHAN_STREAM, SNDLEVEL_LIBRARY, ZombieIsFemale(cBasePlayer->m_nZombieClass) ? "ZOMBIE_FEMALE_FOOTSTEP_SOUNDS" : "ZOMBIE_FOOTSTEP_SOUNDS");
			
			// Block sounds
			return ACTION_STOP; 
		}
	}
	
	// Allow sounds
	return ACTION_CONTINUE;
}