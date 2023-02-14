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
 * @brief The gamemode is starting.
 **/
void AmbientSoundsOnGameModeStart()
{
	float flAmbientDuration = ModesGetSoundDuration(gServerData.RoundMode);
	if (!flAmbientDuration)
	{
		return;
	}
	
	float flAmbientVolume = ModesGetSoundVolume(gServerData.RoundMode);
	if (!flAmbientVolume)
	{
		return;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerExist(i, false) && !IsFakeClient(i))
		{
			delete gClientData[i].AmbientTimer;
			gClientData[i].AmbientTimer = CreateTimer(flAmbientDuration, AmbientSoundsOnMP3Repeat, GetClientUserId(i), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

/**
 * @brief Client has been changed class state.
 * 
 * @param client            The client index.
 **/
void AmbientSoundsOnClientUpdate(int client)
{
	if (!gServerData.RoundStart)
	{
		return;
	}
	
	float flAmbientDuration = ModesGetSoundDuration(gServerData.RoundMode);
	if (!flAmbientDuration)
	{
		return;
	}
	
	float flAmbientVolume = ModesGetSoundVolume(gServerData.RoundMode);
	if (!flAmbientVolume)
	{
		return;
	}
	
	SEffectsInputStopSound(ModesGetSoundAmbientID(gServerData.RoundMode), client, SNDCHAN_STATIC);

	SEffectsInputEmitToClient(ModesGetSoundAmbientID(gServerData.RoundMode), _, client, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_LIBRARY, _, flAmbientVolume);

	delete gClientData[client].AmbientTimer;
	gClientData[client].AmbientTimer = CreateTimer(flAmbientDuration, AmbientSoundsOnMP3Repeat, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
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

	if (client)
	{
		float flAmbientVolume = ModesGetSoundVolume(gServerData.RoundMode);
		if (!flAmbientVolume || !ModesGetSoundDuration(gServerData.RoundMode))
		{
			gClientData[client].AmbientTimer = null;
	
			return Plugin_Stop;
		}
	
		SEffectsInputStopSound(ModesGetSoundAmbientID(gServerData.RoundMode), client, SNDCHAN_STATIC);

		SEffectsInputEmitToClient(ModesGetSoundAmbientID(gServerData.RoundMode), _, client, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_LIBRARY, _, flAmbientVolume);

		return Plugin_Continue;
	}

	gClientData[client].AmbientTimer = null;
	
	return Plugin_Stop;
}
