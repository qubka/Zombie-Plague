/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          soundeffects.cpp
 *  Type:          Module 
 *  Description:   Sounds basic functions.
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
 * @return                  True if the sound was emitted, false otherwise.
 **/
stock bool SEffectsInputEmitToAll(const int iKey, const int iNum, const int entityIndex = SOUND_FROM_PLAYER, const int iChannel = SNDCHAN_AUTO, const int iLevel = SNDLEVEL_NORMAL, const int iFlags = SND_NOFLAGS, const float flVolume = SNDVOL_NORMAL, const int iPitch = SNDPITCH_NORMAL, const int speakerIndex = INVALID_ENT_REFERENCE, const float vOrigin[3] = NULL_VECTOR, const float vDirection[3] = NULL_VECTOR, const bool updatePos = true, const float flSoundTime = 0.0)
{
    // Initialize sound char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), iKey, iNum);
    
    // Validate sound
    if(hasLength(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit sound
        EmitSoundToAll(sSound, entityIndex, iChannel, iLevel, iFlags, flVolume, iPitch, speakerIndex, vOrigin, vDirection, updatePos, flSoundTime);
        return true;
    }

    // Sound doesn't exist
    return false;
}

/**
 * Emits a sound to the client.
 *
 * @param iKey              The key array.
 * @param iNum              The position index.
 * @param clientIndex       The client index.
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
 * @return                  True if the sound was emitted, false otherwise.
 **/
stock bool SEffectsInputEmitToClient(const int iKey, const int iNum, const int clientIndex, const int entityIndex = SOUND_FROM_PLAYER, const int iChannel = SNDCHAN_AUTO, const int iLevel = SNDLEVEL_NORMAL, const int iFlags = SND_NOFLAGS, const float flVolume = SNDVOL_NORMAL, const int iPitch = SNDPITCH_NORMAL, const int speakerIndex = INVALID_ENT_REFERENCE, const float vOrigin[3] = NULL_VECTOR, const float vDirection[3] = NULL_VECTOR, const bool updatePos = true, const float flSoundTime = 0.0)
{
    // Initialize sound char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), iKey, iNum);
    
    // Validate sound
    if(hasLength(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit sound
        EmitSoundToClient(clientIndex, sSound, entityIndex, iChannel, iLevel, iFlags, flVolume, iPitch, speakerIndex, vOrigin, vDirection, updatePos, flSoundTime);
        return true;
    }

    // Sound doesn't exist
    return false;
}

/**
 * Emits an ambient sound
 * 
 * @param iKey              The key array.
 * @param iNum              The position index.
 * @param clientIndex       (Optional) The client index.
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
 * @return                  True if the sound was emitted, false otherwise.
 */
stock bool SEffectsInputEmitAmbient(const int iKey, const int iNum, const int clientIndex = -1, const int entityIndex = SOUND_FROM_PLAYER, const int iChannel = SNDCHAN_AUTO, const int iLevel = SNDLEVEL_NORMAL, const int iFlags = SND_NOFLAGS, const float flVolume = SNDVOL_NORMAL, const int iPitch = SNDPITCH_NORMAL, const int speakerIndex = INVALID_ENT_REFERENCE, const float vOrigin[3] = NULL_VECTOR, const float vDirection[3] = NULL_VECTOR, const bool updatePos = true, const float flSoundTime = 0.0)
{
    // Validate client
    if(IsPlayerExist(clientIndex) && !IsFakeClient(clientIndex))
    {
        // Emit sound to the client
        return SEffectsInputEmitToClient(iKey, iNum, clientIndex, entityIndex, iChannel, iLevel, iFlags, flVolume, iPitch, speakerIndex, vOrigin, vDirection, updatePos, flSoundTime);
    }

    // Emit sound to all
    return SEffectsInputEmitToAll(iKey, iNum, entityIndex, iChannel, iLevel, iFlags, flVolume, iPitch, speakerIndex, vOrigin, vDirection, updatePos, flSoundTime);
}

/**
 * Stop a sound.
 *  
 * @param iKey              The key array.
 * @param iNum              The position index.
 * @param clientIndex       (Optional) The client index.
 * @param iChannel          (Optional) The channel to emit with.
 * @return                  True if the sound was stopped, false otherwise.
 **/
stock bool SEffectsInputStopSound(const int iKey, const int iNum, const int clientIndex = -1, const int iChannel = SNDCHAN_AUTO)
{
    // Initialize sound char
    static char sSound[PLATFORM_MAX_PATH]; sSound[0] = '\0';
    
    // Select sound in the array
    SoundsGetSound(sSound, sizeof(sSound), iKey, iNum);
    
    // Validate sound
    if(hasLength(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);
        
        // Validate client
        if(IsPlayerExist(clientIndex) && !IsFakeClient(clientIndex))
        {
            // Stop sound
            StopSound(clientIndex, iChannel, sSound);
        }
        else
        {
            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate real client
                if(IsPlayerExist(i, false) && !IsFakeClient(i))
                {
                    // Stop sound
                    StopSound(i, iChannel, sSound);
                }
            }
        }
        
        // Return on success
        return true;
    }

    // Sound doesn't exist
    return false;
    
    // Stop sound
    ///return SEffectsInputEmitAmbient(iKey, iNum, clientIndex, _, iChannel, _, SND_STOP);
}

/**
 * Stop all sounds.
 **/
stock void SEffectsInputStopAll(/*void*/)
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