/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          soundeffects.sp
 *  Type:          Module 
 *  Description:   Sounds basic functions.
 *
 *  Copyright (C) 2015-2023 Greyscale, Richard Helgeby
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
 * @brief Gets sound from a key id from sounds config.
 *
 * @param iKey              The key index.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param sSample           The string to return sound in.
 *
 * @return                  True if sound was found, false otherwise.
 **/
bool SEffectsGetSound(int iKey, int iNum = 0, char sSample[PLATFORM_MAX_PATH])
{
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	if (hasLength(sSound))
	{
		Format(sSample, sizeof(sSample), "*/%s", sSound);

		return true;
	}

	return false;
}

/**
 * @brief Emits a sound to all clients. (Can't emit sounds until the previous emit finish)
 *
 * @param flEmitTime        The previous emit time.
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speaker           (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (update positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsEmitToAllNoRestart(float &flEmitTime, int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speaker = -1, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	if (hasLength(sSound))
	{
		float flCurrentTime = GetGameTime();

		if (flCurrentTime > flEmitTime)
		{
			float flDuration;
			gServerData.Durations.GetValue(sSound, flDuration);
			
			Format(sSound, sizeof(sSound), "*/%s", sSound);

			EmitSoundToAll(sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch, speaker, vPosition, vDirection, updatePos, flSoundTime);
		
			flEmitTime = flCurrentTime + flDuration;
			
			return true;
		}
	}
	
	return false;
}

/**
 * @brief Emits a sound to all humans.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speaker           (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (update positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsEmitToHumans(int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speaker = -1, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	if (hasLength(sSound))
	{
		int[] clients = new int[MaxClients]; int iTotal = 0;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !gClientData[i].Zombie)
			{
				clients[iTotal++] = i;
			}
		}

		if (iTotal)
		{
			Format(sSound, sizeof(sSound), "*/%s", sSound);
			EmitSound(clients, iTotal, sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch, speaker, vPosition, vDirection, updatePos, flSoundTime);
		}
		return true;
	}

	return false;
}

/**
 * @brief Emits a sound to all zombies.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speaker           (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (update positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsEmitToZombies(int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speaker = -1, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	if (hasLength(sSound))
	{
		int[] clients = new int[MaxClients]; int iTotal = 0;

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && gClientData[i].Zombie)
			{
				clients[iTotal++] = i;
			}
		}

		if (iTotal)
		{
			Format(sSound, sizeof(sSound), "*/%s", sSound);
			EmitSound(clients, iTotal, sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch, speaker, vPosition, vDirection, updatePos, flSoundTime);
		}
		return true;
	}

	return false;
}

/**
 * @brief Emits a sound to all clients.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speaker           (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (update positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsEmitToAll(int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speaker = -1, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	if (hasLength(sSound))
	{
		Format(sSound, sizeof(sSound), "*/%s", sSound);

		EmitSoundToAll(sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch, speaker, vPosition, vDirection, updatePos, flSoundTime);
		return true;
	}

	return false;
}

/**
 * @brief Emits a sound to the client.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param client            The client index.
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speaker           (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (update positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsEmitToClient(int iKey, int iNum = 0, int client, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speaker = -1, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	if (hasLength(sSound))
	{
		Format(sSound, sizeof(sSound), "*/%s", sSound);

		EmitSoundToClient(client, sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch, speaker, vPosition, vDirection, updatePos, flSoundTime);
		return true;
	}

	return false;
}

/**
 * @brief Emits an ambient sound.
 * 
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param vPosition         The sound origin.
 * @param entity            (Optional) The entity to associate sound with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param flDelay           (Optional) The play delay.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsEmitAmbient(int iKey, int iNum = 0, float vPosition[3], int entity = SOUND_FROM_WORLD, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, float flDelay = 0.0)
{
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	if (hasLength(sSound))
	{
		Format(sSound, sizeof(sSound), "*/%s", sSound);

		EmitAmbientSound(sSound, vPosition, entity, iLevel, iFlags, flVolume, iPitch, flDelay);
		return true;
	}

	return false;
}

/**
 * @brief Stop sounds.
 *  
 * @param iKey              The key array.
 * @param client            (Optional) The client index.
 * @param iChannel          (Optional) The channel to emit with.
 **/
void SEffectsStopSound(int iKey, int client = -1, int iChannel = SNDCHAN_AUTO)
{
	SoundsStopAll(iKey, client, iChannel);
}

/**
 * @brief Stop all sounds.
 **/
void SEffectsStopAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerExist(i, false) && !IsFakeClient(i))
		{
			ClientCommand(i, "playgamesound Music.StopAllExceptMusic");
		}
	}
}
