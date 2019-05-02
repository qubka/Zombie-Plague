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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @brief The gamemode is starting.
 **/
void AmbientSoundsOnGameModeStart(/*void*/)
{
    // Gets ambient sound duration
    float flAmbientDuration = ModesGetSoundDuration(gServerData.RoundMode);
    if(!flAmbientDuration)
    {
        return;
    }
    
    // Gets ambient sound volume
    float flAmbientVolume = ModesGetSoundVolume(gServerData.RoundMode);
    if(!flAmbientVolume)
    {
        return;
    }

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate real client
        if(IsPlayerExist(i, false) && !IsFakeClient(i))
        {
            // Start repeating timer
            delete gClientData[i].AmbientTimer;
            gClientData[i].AmbientTimer = CreateTimer(flAmbientDuration, AmbientSoundsOnMP3Repeat, GetClientUserId(i), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

/**
 * @brief Client has been changed class state.
 * 
 * @param clientIndex       The client index.
 **/
void AmbientSoundsOnClientUpdate(int clientIndex)
{
    // If mode doesn't started yet, then stop
    if(!gServerData.RoundStart)
    {
        return;
    }
    
    // Gets ambient sound duration
    float flAmbientDuration = ModesGetSoundDuration(gServerData.RoundMode);
    if(!flAmbientDuration)
    {
        return;
    }
    
    // Gets ambient sound volume
    float flAmbientVolume = ModesGetSoundVolume(gServerData.RoundMode);
    if(!flAmbientVolume)
    {
        return;
    }
    
    // Stop sound before playing again
    SEffectsInputStopSound(ModesGetSoundAmbientID(gServerData.RoundMode), clientIndex, SNDCHAN_STATIC);

    // Emit ambient sound
    SEffectsInputEmitToClient(ModesGetSoundAmbientID(gServerData.RoundMode), _, clientIndex, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue, _, flAmbientVolume);

    // Start repeating timer
    delete gClientData[clientIndex].AmbientTimer;
    gClientData[clientIndex].AmbientTimer = CreateTimer(flAmbientDuration, AmbientSoundsOnMP3Repeat, GetClientUserId(clientIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}
 
/**
 * @brief Timer callback, replays ambient sound on a client.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action AmbientSoundsOnMP3Repeat(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID);

    // Validate client
    if(clientIndex)
    {
        // Gets ambient sound volume
        float flAmbientVolume = ModesGetSoundVolume(gServerData.RoundMode);
        if(!flAmbientVolume || !ModesGetSoundDuration(gServerData.RoundMode))
        {
            // Clear timer
            gClientData[clientIndex].AmbientTimer = null;
    
            // Destroy timer
            return Plugin_Stop;
        }
    
        // Stop sound before playing again
        SEffectsInputStopSound(ModesGetSoundAmbientID(gServerData.RoundMode), clientIndex, SNDCHAN_STATIC);

        // Emit ambient sound
        SEffectsInputEmitToClient(ModesGetSoundAmbientID(gServerData.RoundMode), _, clientIndex, SOUND_FROM_PLAYER, SNDCHAN_STATIC, gCvarList[CVAR_SEFFECTS_LEVEL].IntValue, _, flAmbientVolume);

        // Allow timer
        return Plugin_Continue;
    }

    // Clear timer
    gClientData[clientIndex].AmbientTimer = null;
    
    // Destroy timer
    return Plugin_Stop;
}