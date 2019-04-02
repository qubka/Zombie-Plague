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
 * @brief Emits a sound to all clients.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entityIndex       (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speakerIndex      (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (updates positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsInputEmitToAll(int iKey, int iNum = 0, int entityIndex = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speakerIndex = INVALID_ENT_REFERENCE, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
    // Initialize sound char
    static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = '\0';
    
    // Gets sound path
    SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
    
    // Validate sound
    if(hasLength(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit sound
        EmitSoundToAll(sSound, entityIndex, iChannel, iLevel, iFlags, flVolume, iPitch, speakerIndex, vPosition, vDirection, updatePos, flSoundTime);
        return true;
    }

    // Sound doesn't exist
    return false;
}

/**
 * @brief Emits a sound to the client.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param clientIndex       The client index.
 * @param entityIndex       (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speakerIndex      (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (updates positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsInputEmitToClient(int iKey, int iNum = 0, int clientIndex, int entityIndex = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speakerIndex = INVALID_ENT_REFERENCE, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
    // Initialize sound char
    static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = '\0';
    
    // Gets sound path
    SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
    
    // Validate sound
    if(hasLength(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit sound
        EmitSoundToClient(clientIndex, sSound, entityIndex, iChannel, iLevel, iFlags, flVolume, iPitch, speakerIndex, vPosition, vDirection, updatePos, flSoundTime);
        return true;
    }

    // Sound doesn't exist
    return false;
}

/**
 * @brief Emits an ambient sound.
 * 
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param vPosition         The sound origin.
 * @param entityIndex       (Optional) The entity to associate sound with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param flDelay           (Optional) The play delay.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsInputEmitAmbient(int iKey, int iNum = 0, float vPosition[3], int entityIndex = SOUND_FROM_WORLD, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, float flDelay = 0.0)
{
    // Initialize sound char
    static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = '\0';
    
    // Gets sound path
    SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
    
    // Validate sound
    if(hasLength(sSound))
    {
        // Format sound
        Format(sSound, sizeof(sSound), "*/%s", sSound);

        // Emit sound
        EmitAmbientSound(sSound, vPosition, entityIndex, iLevel, iFlags, flVolume, iPitch, flDelay);
        return true;
    }

    // Sound doesn't exist
    return false;
}

/**
 * @brief Stop sounds.
 *  
 * @param iKey              The key array.
 * @param clientIndex       (Optional) The client index.
 * @param iChannel          (Optional) The channel to emit with.
 **/
void SEffectsInputStopSound(int iKey, int clientIndex = -1, int iChannel = SNDCHAN_AUTO)
{
    // Stop all sounds
    SoundsStopAll(iKey, clientIndex, iChannel);
}

/**
 * @brief Stop all sounds.
 **/
void SEffectsInputStopAll(/*void*/)
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