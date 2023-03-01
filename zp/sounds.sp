/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          sounds.sp
 *  Type:          Manager 
 *  Description:   Basic sound-management API.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 * @section Sound config data indexes.
 **/
enum
{
	SOUNDS_DATA_KEY,
	SOUNDS_DATA_PATH,
	SOUNDS_DATA_VOLUME,
	SOUNDS_DATA_LEVEL,
	SOUNDS_DATA_FLAGS,
	SOUNDS_DATA_PITCH,
	SOUNDS_DATA_DURATION
};
/**
 * @endsection
 **/
 
/*
 * Load other sound effect modules
 */
#include "zp/soundeffects/voice.sp"
#include "zp/soundeffects/ambientsounds.sp"
#include "zp/soundeffects/soundeffects.sp"
#include "zp/soundeffects/playersounds.sp"

/**
 * @brief Sounds module init function.
 **/
void SoundsOnInit()
{
	AddNormalSoundHook(view_as<NormalSHook>(PlayerSoundsNormalHook));
}

/**
 * @brief Prepare all sound data.
 **/
void SoundsOnLoad()
{
	ConfigRegisterConfig(File_Sounds, Structure_KeyValue, CONFIG_FILE_ALIAS_SOUNDS);

	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_SOUNDS, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing sounds config file: \"%s\"", sBuffer);
		return;
	}

	ConfigSetConfigPath(File_Sounds, sBuffer);

	bool bSuccess = ConfigLoadConfig(File_Sounds, gServerData.Sounds, PLATFORM_LINE_LENGTH);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Unexpected error encountered loading: \"%s\"", sBuffer);
		return;
	}
	
	SoundsOnCacheData();
	
	ConfigSetConfigLoaded(File_Sounds, true);
	ConfigSetConfigReloadFunc(File_Sounds, GetFunctionByName(GetMyHandle(), "SoundsOnConfigReload"));
	ConfigSetConfigHandle(File_Sounds, gServerData.Sounds);

	PlayerSoundsOnOnLoad();
}

/**
 * @brief Caches sound data from file into arrays.
 **/
void SoundsOnCacheData()
{
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Sounds, sBuffer, sizeof(sBuffer));

	KeyValues kvSounds;
	bool bSuccess = ConfigOpenConfigFile(File_Sounds, kvSounds);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Unexpected error caching data from sounds config file: \"%s\"", sBuffer);
		return;
	}

	int iSize = gServerData.Sounds.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "No usable data found in sounds config file: \"%s\"", sBuffer);
		return;
	}

	for (int i = 0; i < iSize; i++)
	{
		SoundsGetKey(i, sBuffer, sizeof(sBuffer)); // Index: 0
		kvSounds.Rewind();
		if (!kvSounds.JumpToKey(sBuffer))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Couldn't cache sound data for: \"%s\" (check sounds config)", sBuffer);
			continue;
		}
		
		ArrayList arraySound = gServerData.Sounds.Get(i);
		
		if (kvSounds.GotoFirstSubKey())
		{
			do
			{
				kvSounds.GetSectionName(sBuffer, sizeof(sBuffer));
				
				int iFormat = FindCharInString(sBuffer, '.', true);
				
				if (iFormat == -1)
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing sound format: %s", sBuffer);
					continue;
				}
				
				bool bMP3 = !strcmp(sBuffer[iFormat], ".mp3", false);
				
				if (bMP3)
				{
					Format(sBuffer, sizeof(sBuffer), "*/%s", sBuffer);
				}
				
				arraySound.PushString(sBuffer);                        // Index: i + 0
				arraySound.Push(kvSounds.GetFloat("volume", 1.0));     // Index: i + 1
				arraySound.Push(kvSounds.GetNum("level", 75));         // Index: i + 2
				arraySound.Push(kvSounds.GetNum("flags", 0));          // Index: i + 3
				arraySound.Push(kvSounds.GetNum("pitch", 100));        // Index: i + 4
				float flDuration = kvSounds.GetFloat("duration", 0.0); // Index: i + 5

				Format(sBuffer, sizeof(sBuffer), "sound/%s", sBuffer[bMP3 ? 2 : 0]);

				if (SoundsPrecacheQuirk(sBuffer) && !flDuration)
				{
					flDuration = GetSoundDuration(sBuffer[6]);
				}
				
				if (!flDuration)
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing sound duration: %s", sBuffer);
				}
				
				arraySound.Push(flDuration);                        
			}
			while (kvSounds.GotoNextKey());
		}
	}
	
	delete kvSounds;
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void SoundsOnConfigReload()
{
	SoundsOnLoad();
}

/**
 * @brief Hook sounds cvar changes.
 **/
void SoundsOnCvarInit()
{
	VoiceOnCvarInit();
	PlayerSoundsOnCvarInit();
}

/*
 * Sounds main functions.
 */

/**
 * @brief The round is starting.
 **/
void SoundsOnRoundStart()
{
	VoiceOnRoundStart();
}

/**
 * @brief The counter is begin.
 **/
void SoundsOnCounterStart()   
{
	PlayerSoundsOnCounterStart();
}

/**
 * @brief The round is ending.
 *
 * @param reason            The reason index.
 **/
void SoundsOnRoundEnd(CSRoundEndReason reason)
{
	VoiceOnRoundEnd();
	SEffectsStopAll();
	
	delete gServerData.EndTimer;
	gServerData.EndTimer = CreateTimer(0.2, PlayerSoundsOnRoundEndPost, reason, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief The counter is working.
 *
 * @return                  True or false.
 **/
bool SoundsOnCounter()
{
	return PlayerSoundsOnCounter();
}

/**
 * @brief The blast is started.
 **/
void SoundsOnBlast()
{
	delete gServerData.BlastTimer;
	gServerData.BlastTimer = CreateTimer(0.3, PlayerSoundsOnBlastPost, _, TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief The gamemode is starting.
 **/
void SoundsOnGameModeStart()
{
	VoiceOnGameModeStart();
	PlayerSoundsOnGameModeStart();
	AmbientSoundsOnGameModeStart();
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientDeath(int client)
{
	PlayerSoundsOnClientDeath(client);
	AmbientSoundsOnClientDeath(client);
}

/**
 * @brief Client has been hurt.
 * 
 * @param client            The client index.
 * @param iBits             The type of damage inflicted.
 **/
void SoundsOnClientHurt(int client, int iBits)
{
	PlayerSoundsOnClientHurt(client, ((iBits & DMG_BURN) || (iBits & DMG_DIRECT)));
}

/**
 * @brief Client has been infected.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
void SoundsOnClientInfected(int client, int attacker)
{
	PlayerSoundsOnClientInfected(client, attacker);
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientUpdate(int client)
{
	VoiceOnClientUpdate(client);
	AmbientSoundsOnClientUpdate(client);
}

/**
 * @brief Client has been regenerating.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientRegen(int client)
{
	PlayerSoundsOnClientRegen(client);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientJump(int client)
{
	PlayerSoundsOnClientJump(client);
}

/**
 * @brief Client has been shoot.
 * 
 * @param client            The client index.
 * @param iD                The weapon id.
 **/
Action SoundsOnClientShoot(int client, int iD)
{
	return PlayerSoundsOnClientShoot(client, iD) ? Plugin_Stop : Plugin_Continue;
}

/*
 * Sounds natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void SoundsOnNativeInit() 
{
	CreateNative("ZP_GetSoundKeyID",           API_GetSoundKeyID);
	CreateNative("ZP_GetSound",                API_GetSound);
	CreateNative("ZP_EmitSoundToAllNoRep", API_EmitSoundToAllNoRep);
	CreateNative("ZP_EmitSoundToAll",          API_EmitSoundToAll);
	CreateNative("ZP_EmitSoundToClient",       API_EmitSoundToClient);
	CreateNative("ZP_EmitAmbientSound",        API_EmitAmbientSound);
	CreateNative("ZP_StopSoundToAll",          API_StopSoundToAll);
}
 
/**
 * @brief Gets the key id from a given key.
 *
 * @note native int ZP_GetSoundKeyID(name);
 **/
public int API_GetSoundKeyID(Handle hPlugin, int iNumParams)
{
	int maxLen;
	GetNativeStringLength(1, maxLen);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Sounds, "Native Validation", "Can't find key with an empty name");
		return -1;
	}

	static char sName[SMALL_LINE_LENGTH];                                   
	GetNativeString(1, sName, sizeof(sName));

	return SoundsKeyToIndex(sName);
}

/**
 * @brief Gets the sound of a block at a given key.
 *
 * @note native float ZP_GetSound(keyID, num, sound, maxlenght, volume, level, flags, pitch);
 **/
public int API_GetSound(Handle hPlugin, int iNumParams)
{
	int maxLen = GetNativeCell(4);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Sounds, "Native Validation", "No buffer size");
		return -1;
	}

	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];

	float flVolume; int iLevel; int iFlags; int iPitch; 
	float flDuration = SoundsGetSound(GetNativeCell(1), GetNativeCell(2), sSound, flVolume, iLevel, iFlags, iPitch);
	
	SetNativeString(3, sSound, maxLen);
	SetNativeCellRef(5, flVolume);
	SetNativeCellRef(6, iLevel);
	SetNativeCellRef(7, iFlags);
	SetNativeCellRef(8, iPitch);

	return view_as<int>(flDuration);
}

/**
 * @brief Emits a sound to all clients. (Can't emit sounds until the previous emit finish)
 *
 * @note native float ZP_EmitSoundToAllNoRep(&time, keyID, num, entity, channel, human, zombie);
 **/
public int API_EmitSoundToAllNoRep(Handle hPlugin, int iNumParams)
{
	float flEmitTime = GetNativeCellRef(1);
	float flDuration = SEffectsEmitToAllNoRep(flEmitTime, GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7));
	
	if (flDuration)
	{
		SetNativeCellRef(1, flEmitTime);
	}
	
	return view_as<int>(flDuration);
}

/**
 * @brief Emits a sound to all clients.
 *
 * @note native float ZP_EmitSoundToAll(keyID, num, entity, channel, human, zombie);
 **/
public int API_EmitSoundToAll(Handle hPlugin, int iNumParams)
{
	return view_as<int>(SEffectsEmitToAll(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6)));
}

/**
 * @brief Emits a sound to the client.
 *
 * @note native float ZP_EmitSoundToClient(keyID, num, client, entity, channel);
 **/
public int API_EmitSoundToClient(Handle hPlugin, int iNumParams)
{
	return view_as<int>(SEffectsEmitToClient(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5)));
}

/**
 * @brief Emits an ambient sound.
 *
 * @note native float ZP_EmitAmbientSound(keyID, num, origin, entity, delay);
 **/
public int API_EmitAmbientSound(Handle hPlugin, int iNumParams)
{
	static float vPosition[3];
	GetNativeArray(3, vPosition, sizeof(vPosition));
	
	return view_as<int>(SEffectsEmitAmbient(GetNativeCell(1), GetNativeCell(2), vPosition, GetNativeCell(4), GetNativeCell(5)));
}

/**
 * @brief Stops a sound to all clients.
 *
 * @note native bool ZP_StopSoundToAll(keyID, num, entity, channel);
 **/
public int API_StopSoundToAll(Handle hPlugin, int iNumParams)
{
	return SEffectsStopToAll(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4));
}
 
/*
 * Sounds data reading API. 
 */

/**
 * @brief Gets the key of a sound list at a given key.
 * 
 * @param iKey              The sound index.
 * @param sKey              The string to return key in.
 * @param iMaxLen           The lenght of string.
 **/
void SoundsGetKey(int iKey, char[] sKey, int iMaxLen)
{
	ArrayList arraySound = gServerData.Sounds.Get(iKey);
	
	arraySound.GetString(SOUNDS_DATA_KEY, sKey, iMaxLen);
}

/**
 * @brief Gets the number of a sounds at a given key.
 * 
 * @param iKey              The sound index.
 * @return                  The sound count.
 **/
int SoundsGetCount(int iKey)
{
	ArrayList arraySound = gServerData.Sounds.Get(iKey);
		
	return (arraySound.Length - 1) / SOUNDS_DATA_DURATION;
}

/**
 * @brief Gets the sound of a block at a given key.
 * 
 * @param iKey              The block index.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param sPath             The string to return path in.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iFlags            The sound flags.
 * @param iPitch            The sound pitch.
 * @return                  The sound duration. (returns 0 if not found)
 **/
float SoundsGetSound(int iKey, int iNum = 0, char sPath[PLATFORM_LINE_LENGTH], float &flVolume, int &iLevel , int &iFlags, int &iPitch)
{
	if (iKey == -1)
	{
		return 0.0;
	}

	ArrayList arraySound = gServerData.Sounds.Get(iKey);

	int iSize = (arraySound.Length - 1) / SOUNDS_DATA_DURATION;
	if (iNum <= iSize)
	{
		int iD = ((iNum ? iNum : GetRandomInt(1, iSize)) - 1) * SOUNDS_DATA_DURATION;

		arraySound.GetString(iD + SOUNDS_DATA_PATH, sPath, sizeof(sPath));
		flVolume = arraySound.Get(iD + SOUNDS_DATA_VOLUME);
		iLevel = arraySound.Get(iD + SOUNDS_DATA_LEVEL);
		iFlags = arraySound.Get(iD + SOUNDS_DATA_FLAGS);
		iPitch = arraySound.Get(iD + SOUNDS_DATA_PITCH);
		return arraySound.Get(iD + SOUNDS_DATA_DURATION);
	}

	return 0.0;
}

/*
 * Stocks sounds API.
 */

/**
 * @brief Find the index at which the sound key is at.
 * 
 * @param sKey              The key name.
 * @return                  The sound index.
 **/
int SoundsKeyToIndex(const char[] sKey)
{
	static char sSoundKey[SMALL_LINE_LENGTH];
	
	int iSize = gServerData.Sounds.Length;
	for (int i = 0; i < iSize; i++)
	{
		SoundsGetKey(i, sSoundKey, sizeof(sSoundKey));

		if (!strcmp(sKey, sSoundKey, false))
		{
			return i;
		}
	}
	
	return -1;
}

/**
 * @brief Precache the sound in the sounds table.
 *
 * @param sPath             The sound path.
 * @return                  True if was precached, false otherwise.
 **/
bool SoundsPrecacheQuirk(const char[] sPath)
{
	if (!FileExists(sPath))
	{
		if (FileExists(sPath, true))
		{
			PrecacheSound(sPath[6], true);
			return true;
		}

		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Invalid sound path. File not found: \"%s\"", sPath);
		return false;
	}
	
	static char sSound[PLATFORM_LINE_LENGTH];
	FormatEx(sSound, sizeof(sSound), "*%s", sPath[5]);

	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("soundprecache");
	}

	if (FindStringIndex(table, sSound) == INVALID_STRING_INDEX)
	{
		AddFileToDownloadsTable(sPath);

		AddToStringTable(table, sSound);
	}
	
	return true;
}
