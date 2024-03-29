/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          soundeffects.sp
 *  Type:          Module 
 *  Description:   Sounds basic functions.
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
 * @brief Emits a sound to all clients. (Can't emit sounds until the previous emit finish)
 *
 * @param flEmitTime        The previous emit time.
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param bHuman            (Optional) True to include zombie players.
 * @param bZombie           (Optional) True to include human players.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
float SEffectsEmitToAllNoRep(float &flEmitTime, int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, bool bHuman = true, bool bZombie = true)
{
	static char sSound[PLATFORM_LINE_LENGTH];
	float flVolume; int iLevel; int iFlags; int iPitch;
	float flDuration = SoundsGetSound(iKey, iNum, sSound, flVolume, iLevel, iFlags, iPitch);
	
	if (flDuration)
	{
		float flCurrentTime = GetGameTime();

		if (flCurrentTime > flEmitTime)
		{
			int[] clients = new int[MaxClients]; int iCount = 0;

			if (bHuman && bZombie)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i))
					{
						clients[iCount++] = i;
					}
				}
			}
			else if (bHuman)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !gClientData[i].Zombie)
					{
						clients[iCount++] = i;
					}
				}
			}
			else if (bZombie)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && gClientData[i].Zombie)
					{
						clients[iCount++] = i;
					}
				}
			}
			else
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && gClientData[i].Custom)
					{
						clients[iCount++] = i;
					}
				}
			}
			
			if (iCount)
			{
				EmitSound(clients, iCount, sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch);
			}
		
			flEmitTime = flCurrentTime + flDuration;
		}
		else
		{
			flDuration = 0.0;
		}
	}
	
	return flDuration;
}

/**
 * @brief Emits a sound to all clients.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param bHuman            (Optional) True to include zombie players.
 * @param bZombie           (Optional) True to include human players.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
float SEffectsEmitToAll(int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, bool bHuman = true, bool bZombie = true)
{
	static char sSound[PLATFORM_LINE_LENGTH];
	float flVolume; int iLevel; int iFlags; int iPitch;
	float flDuration = SoundsGetSound(iKey, iNum, sSound, flVolume, iLevel, iFlags, iPitch);
	
	if (flDuration)
	{
		int[] clients = new int[MaxClients]; int iCount = 0;

		if (bHuman && bZombie)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					clients[iCount++] = i;
				}
			}
		}
		else if (bHuman)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !gClientData[i].Zombie)
				{
					clients[iCount++] = i;
				}
			}
		}
		else if (bZombie)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && gClientData[i].Zombie)
				{
					clients[iCount++] = i;
				}
			}
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && gClientData[i].Custom)
				{
					clients[iCount++] = i;
				}
			}
		}
		
		if (iCount)
		{
			EmitSound(clients, iCount, sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch);
		}
	}

	return flDuration;
}

/**
 * @brief Emits a sound to the client.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param client            The client index.
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
float SEffectsEmitToClient(int iKey, int iNum = 0, int client, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO)
{
	static char sSound[PLATFORM_LINE_LENGTH];
	float flVolume; int iLevel; int iFlags; int iPitch;
	float flDuration = SoundsGetSound(iKey, iNum, sSound, flVolume, iLevel, iFlags, iPitch);
	
	if (flDuration)
	{
		EmitSoundToClient(client, sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch);
	}

	return flDuration;
}

/**
 * @brief Emits an ambient sound.
 * 
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param vPosition         The sound origin.
 * @param entity            (Optional) The entity to associate sound with.
 * @param flDelay           (Optional) The play delay.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
float SEffectsEmitAmbient(int iKey, int iNum = 0, const float vPosition[3], int entity = SOUND_FROM_WORLD, float flDelay = 0.0)
{
	static char sSound[PLATFORM_LINE_LENGTH];
	float flVolume; int iLevel; int iFlags; int iPitch;
	float flDuration = SoundsGetSound(iKey, iNum, sSound, flVolume, iLevel, iFlags, iPitch);
	
	if (flDuration)
	{
		EmitAmbientSound(sSound, vPosition, entity, iLevel, iFlags, flVolume, iPitch, flDelay);
	}

	return flDuration;
}

/**
 * @brief Stops a sound to all clients.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for all sounds)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @return                  True if the sound was stopped, false otherwise.
 **/
bool SEffectsStopToAll(int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO)
{
	if (iNum == 0)
	{
		int iSize = SoundsGetCount(iKey);
		for (int i = 1; i <= iSize; i++)
		{
			SEffectsStopToAll(iKey, i, entity, iChannel);
		}
		return true;
	}
	
	static char sSound[PLATFORM_LINE_LENGTH];
	float flVolume; int iLevel; int iFlags; int iPitch;

	if (SoundsGetSound(iKey, iNum, sSound, flVolume, iLevel, iFlags, iPitch))
	{
		StopSound(entity, iChannel, sSound);
		return true;
	}

	return false;
}

/**
 * @brief Stop all sounds.
 **/
void SEffectsStopAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i, false, false))
		{
			ClientCommand(i, "playgamesound Music.StopAllExceptMusic");
		}
	}
}
