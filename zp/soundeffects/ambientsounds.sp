/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          ambientsounds.sp
 *  Type:          Module 
 *  Description:   Plays ambient sounds to the clients.
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
 * Array to store the client current ambients.
 **/
char gAmbient[MAXPLAYERS+1][PLATFORM_MAX_PATH]; 

/**
 * @brief The gamemode is starting.
 **/
void AmbientSoundsOnGameModeStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerExist(i, false))
		{
			AmbientSoundsOnClientUpdate(i);
		}
	}
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void AmbientSoundsOnClientDeath(int client)
{
	if (hasLength(gAmbient[client]))
	{
		StopSound(client, SNDCHAN_STATIC, gAmbient[client]);
	}
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void AmbientSoundsOnClientUpdate(int client)
{
	gAmbient[client][0] = NULL_STRING[0];

	if (!gServerData.RoundStart)
	{
		return;
	}

	float flVolume; int iLevel; int iFlags; int iPitch;

	float flDuration = SoundsGetSound(ModesGetSoundAmbientID(gServerData.RoundMode), _, gAmbient[client], flVolume, iLevel, iFlags, iPitch);
	if (flDuration)
	{
		EmitSoundToClient(client, gAmbient[client], SOUND_FROM_PLAYER, SNDCHAN_STATIC, iLevel, iFlags, flVolume, iPitch);

		delete gClientData[client].AmbientTimer;
		gClientData[client].AmbientTimer = CreateTimer(flDuration, AmbientSoundsOnMP3Repeat, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}
 
/**
 * @brief Timer callback, replays ambient sound on a client.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action AmbientSoundsOnMP3Repeat(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID);

	gClientData[client].AmbientTimer = null;

	if (client)
	{
		float flVolume; int iLevel; int iFlags; int iPitch;
	
		float flDuration = SoundsGetSound(ModesGetSoundAmbientID(gServerData.RoundMode), _, gAmbient[client], flVolume, iLevel, iFlags, iPitch);
		if (flDuration)
		{
			EmitSoundToClient(client, gAmbient[client], SOUND_FROM_PLAYER, SNDCHAN_STATIC, iLevel, iFlags, flVolume, iPitch);

			gClientData[client].AmbientTimer = CreateTimer(flDuration, AmbientSoundsOnMP3Repeat, userID, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Stop;
}
