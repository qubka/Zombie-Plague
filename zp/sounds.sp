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
	SOUNDS_DATA_VALUE
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
	ConfigRegisterConfig(File_Sounds, Structure_ArrayList, CONFIG_FILE_ALIAS_SOUNDS);

	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_SOUNDS, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Missing sounds file: \"%s\"", sBuffer);
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
	
	LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_Sounds, "Config Validation", "Loading sounds from file \"%s\"", sBuffer);

	int iSoundCount; int iSoundValidCount; int iSoundUnValidCount;
	
	int iSounds = iSoundCount = gServerData.Sounds.Length;
	if (!iSounds)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "No usable data found in sounds config file: \"%s\"", sBuffer);
		return;
	}
	
	for (int i = 0; i < iSounds; i++)
	{
		ArrayList arraySound = SoundsGetKey(i, sBuffer, sizeof(sBuffer), true);

		if (ParamParseString(arraySound, sBuffer, sizeof(sBuffer), '=') == PARAM_ERROR_NO)
		{
			int iSize = arraySound.Length;
			for (int x = 1; x < iSize; x++)
			{
				arraySound.GetString(x, sBuffer, sizeof(sBuffer));

				Format(sBuffer, sizeof(sBuffer), "sound/%s", sBuffer);

				if (DownloadsOnPrecache(sBuffer)) iSoundValidCount++; else iSoundUnValidCount++;
			}
		}
		else
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Error with parsing of the sound block: \"%d\" = \"%s\"", i + 1, sBuffer);
			
			gServerData.Sounds.Erase(i);

			iSounds--;

			i--;
		}
	}
	
	LogEvent(true, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Sounds, "Config Validation", "Total blocks: \"%d\" | Unsuccessful blocks: \"%d\" | Total: %d | Successful: \"%d\" | Unsuccessful: \"%d\"", iSoundCount, iSoundCount - iSounds, iSoundValidCount + iSoundUnValidCount, iSoundValidCount, iSoundUnValidCount);
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
	SEffectsInputStopAll();
	
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
 * @brief Client has been swith nightvision.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientNvgs(int client)
{
	PlayerSoundsOnClientNvgs(client);
}

/**
 * @brief Client has been swith flashlight.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientFlashLight(int client)
{
	PlayerSoundsOnClientFlashLight(client);
}

/**
 * @brief Client has been buy ammunition.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientAmmunition(int client)
{
	PlayerSoundsOnClientAmmunition(client);
}

/**
 * @brief Client has been level up.
 * 
 * @param client            The client index.
 **/
void SoundsOnClientLevelUp(int client)
{
	PlayerSoundsOnClientLevelUp(client);
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
	CreateNative("ZP_GetSoundKeyID",     API_GetSoundKeyID);
	CreateNative("ZP_GetSound",          API_GetSound);
	CreateNative("ZP_EmitSoundToAll",    API_EmitSoundToAll);
	CreateNative("ZP_EmitSoundToClient", API_EmitSoundToClient);
	CreateNative("ZP_EmitAmbientSound",  API_EmitAmbientSound);
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
 * @brief Gets sound from a key id from sounds config.
 *
 * @note native void ZP_GetSound(keyID, sound, maxlenght, position);
 **/
public int API_GetSound(Handle hPlugin, int iNumParams)
{
	int maxLen = GetNativeCell(3);

	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Sounds, "Native Validation", "No buffer size");
		return -1;
	}
	
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(GetNativeCell(1), sSound, sizeof(sSound), GetNativeCell(4));
	
	if (hasLength(sSound))
	{
		Format(sSound, sizeof(sSound), "*/%s", sSound);
	}
	
	return SetNativeString(2, sSound, maxLen);
}

/**
 * @brief Emits a sound to all clients.
 *
 * @note native bool ZP_EmitSoundToAll(keyID, num, entity, channel, level, flags, volume, pitch);
 **/
public int API_EmitSoundToAll(Handle hPlugin, int iNumParams)
{
	return SEffectsInputEmitToAll(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8));
}

/**
 * @brief Emits a sound to the client.
 *
 * @note native bool ZP_EmitSoundToClient(keyID, num, client, entity, channel, level, flags, volume, pitch);
 **/
public int API_EmitSoundToClient(Handle hPlugin, int iNumParams)
{
	return SEffectsInputEmitToClient(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), GetNativeCell(9));
}

/**
 * @brief Emits an ambient sound.
 *
 * @note native bool ZP_EmitAmbientSound(keyID, num, origin, entity, level, flags, volume, pitch, delay);
 **/
public int API_EmitAmbientSound(Handle hPlugin, int iNumParams)
{
	static float vPosition[3];
	GetNativeArray(3, vPosition, sizeof(vPosition));
	
	return SEffectsInputEmitAmbient(GetNativeCell(1), GetNativeCell(2), vPosition, GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), GetNativeCell(9));
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
ArrayList SoundsGetKey(int iKey, char[] sKey, int iMaxLen, bool bDelete = false)
{
	ArrayList arraySound = gServerData.Sounds.Get(iKey);
	
	arraySound.GetString(SOUNDS_DATA_KEY, sKey, iMaxLen);
	
	if (bDelete) arraySound.Erase(SOUNDS_DATA_KEY);
	
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
void SoundsGetPath(int iKey, char[] sPath, int iMaxLen, int iNum = 0)
{
	if (iKey == -1)
	{
		return;
	}
	
	ArrayList arraySound = gServerData.Sounds.Get(iKey);

	int iSize = arraySound.Length;
	if (iNum < iSize)
	{
		arraySound.GetString(iNum ? iNum : GetRandomInt(SOUNDS_DATA_VALUE, iSize - 1), sPath, iMaxLen);
	}
}

/**
 * @brief Stops a sound list at a given key.
 * 
 * @param iKey              The sound array index.
 * @param client            (Optional) The client index.
 * @param iChannel          (Optional) The channel to emit with.
 **/
void SoundsStopAll(int iKey, int client = -1, int iChannel = SNDCHAN_AUTO)
{
	if (iKey == -1)
	{
		return;
	}
	
	static char sSound[PLATFORM_LINE_LENGTH];
	
	ArrayList arraySound = gServerData.Sounds.Get(iKey);

	int iSize = arraySound.Length;
	for (int i = 1; i < iSize; i++)
	{
		arraySound.GetString(i, sSound, sizeof(sSound));
		
		if (hasLength(sSound))
		{
			Format(sSound, sizeof(sSound), "*/%s", sSound);
			
			if (IsPlayerExist(client, false) && !IsFakeClient(client))
			{
				StopSound(client, iChannel, sSound);
			}
			else
			{
				for (int x = 1; x <= MaxClients; x++)
				{
					if (IsPlayerExist(x, false) && !IsFakeClient(x))
					{
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
int SoundsKeyToIndex(char[] sKey)
{
	static char sSoundKey[SMALL_LINE_LENGTH]; 
	
	int iSize = gServerData.Sounds.Length; int iRandom; static int keyID[MAXPLAYERS+1];
	for (int i = 0; i < iSize; i++)
	{
		SoundsGetKey(i, sSoundKey, sizeof(sSoundKey));
		
		if (!strcmp(sSoundKey, sKey, false))
		{
			keyID[iRandom++] = i;
		}
	}
	
	return (iRandom) ? keyID[GetRandomInt(0, iRandom-1)] : -1;
}

/**
 * @brief Precache the sound in the sounds table.
 *
 * @param sPath             The sound path.
 * @return                  True if was precached, false otherwise.
 **/
bool SoundsPrecacheQuirk(char[] sPath)
{
	if (!FileExists(sPath))
	{
		if (FileExists(sPath, true))
		{
			PrecacheSound(sPath, true);
			return true;
		}

		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Invalid sound path. File not found: \"%s\"", sPath);
		return false;
	}
	
	static char sSound[PLATFORM_LINE_LENGTH];
	strcopy(sSound, sizeof(sSound), sPath);

	if (ReplaceStringEx(sSound, sizeof(sSound), "sound", "*", 5, 1, true) != -1)
	{
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
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Sounds, "Config Validation", "Invalid sound path. File not found: \"%s\"", sPath);
		return false;
	}
	
	return true;
}
