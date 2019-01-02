/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          ambientsounds.cpp
 *  Type:          Module 
 *  Description:   Plays ambient sounds to the clients.
 *
 *  Copyright (C) 2015-2019  Greyscale, Richard Helgeby
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
 * The gamemode is starting.
 **/
void AmbientSoundsOnGameModeStart(/*void*/)
{
    // Get ambient sound duration
    float flAmbientDuration = ModesGetSoundDuration(gServerData[Server_RoundMode]);
    if(!flAmbientDuration)
    {
        return;
    }
    
    // Get ambient sound volume
    float flAmbientVolume = ModesGetSoundVolume(gServerData[Server_RoundMode]);
    if(!flAmbientVolume)
    {
        return;
    }
    
    // Stop sound before playing again
    SEffectsInputStopSound(ModesGetSoundAmbientID(gServerData[Server_RoundMode]), 0, _, SNDCHAN_STATIC);

    // Emit ambient sound
    SEffectsInputEmitAmbient(ModesGetSoundAmbientID(gServerData[Server_RoundMode]), 0, _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, _, flAmbientVolume);

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate real client
        if(IsPlayerExist(i, false) && !IsFakeClient(i))
        {
            // Start repeating timer
            delete gClientData[i][Client_AmbientTimer];
            gClientData[i][Client_AmbientTimer] = CreateTimer(flAmbientDuration, AmbientOnRepeat, GetClientUserId(i), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

/**
 * Client has been changed class state.
 * 
 * @param clientIndex       The client index.
 **/
void AmbientSoundsOnClientUpdate(const int clientIndex)
{
    // If round didn't start yet, then stop
    if(gServerData[Server_RoundNew])
    {
        return;
    }
    
    // Get ambient sound duration
    float flAmbientDuration = ModesGetSoundDuration(gServerData[Server_RoundMode]);
    if(!flAmbientDuration)
    {
        return;
    }
    
    // Get ambient sound volume
    float flAmbientVolume = ModesGetSoundVolume(gServerData[Server_RoundMode]);
    if(!flAmbientVolume)
    {
        return;
    }
    
    // Stop sound before playing again
    SEffectsInputStopSound(ModesGetSoundAmbientID(gServerData[Server_RoundMode]), 0, clientIndex, SNDCHAN_STATIC);

    // Emit ambient sound
    SEffectsInputEmitAmbient(ModesGetSoundAmbientID(gServerData[Server_RoundMode]), 0, clientIndex, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, _, flAmbientVolume);

    // Start repeating timer
    delete gClientData[clientIndex][Client_AmbientTimer];
    gClientData[clientIndex][Client_AmbientTimer] = CreateTimer(flAmbientDuration, AmbientOnRepeat, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
 
/**
 * Timer callback, replays ambient sound on a client.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action AmbientOnRepeat(Handle hTimer, const int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Get ambient sound volume
        float flAmbientVolume = ModesGetSoundVolume(gServerData[Server_RoundMode]);
        if(!flAmbientVolume || !ModesGetSoundDuration(gServerData[Server_RoundMode]))
        {
            // Clear timer
            gClientData[clientIndex][Client_AmbientTimer] = INVALID_HANDLE;
    
            // Destroy timer
            return Plugin_Stop;
        }
    
        // Stop sound before playing again
        SEffectsInputStopSound(ModesGetSoundAmbientID(gServerData[Server_RoundMode]), 0, clientIndex, SNDCHAN_STATIC);

        // Emit ambient sound
        SEffectsInputEmitAmbient(ModesGetSoundAmbientID(gServerData[Server_RoundMode]), 0, clientIndex, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_GAME_CUSTOM_SOUND_LEVEL].IntValue, _, flAmbientVolume);

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex][Client_AmbientTimer] = INVALID_HANDLE;
    
    // Destroy timer
    return Plugin_Stop;
}