/**
 * =============================================================================
 * Zombie Plague Copyright (C) 2015-2023 qubka (Nikita Ushakov).
 * =============================================================================
 *
 * This file is part of the Zombie Plague Core.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 **/

#if defined _soundlist_included
 #endinput
#endif
#define _soundlist_included

/**
 * @brief Gets the key id from a given key.
 *
 * @param key               The key name.
 *  
 * @return                  The key id containing the given key. 
 *
 * @note                    Can return a random index for multiple same unique keys!
 **/
native int ZP_GetSoundKeyID(const char[] key);

/**
 * @brief Gets the sound of a block at a given key.
 *
 * @param keyID             The key index.
 * @param num               (Optional) The position index. (for not random sound)
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 * @param volume            The sound volume.
 * @param level             The sound level.
 * @param flags             The sound flags.
 * @param pitch             The sound pitch.
 *
 * @return                  The sound duration. (returns 0 if not found)
 **/
native float ZP_GetSound(int keyID, int num = 0, char[] sound, int maxlenght = 256, float &volume, int &level, int &flags, int &pitch);

/**
 * @brief Emits a sound to all clients. (Can't emit sounds until the previous emit finish)
 *
 * @param time              The previous emit time.
 * @param keyID             The key array.
 * @param num               (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param channel           (Optional) The channel to emit with.
 * @param human             (Optional) True to include zombie players.
 * @param zombie            (Optional) True to include human players.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
native float ZP_EmitSoundToAllNoRep(float& time, int keyID, int num = 0, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, bool human = true, bool zombie = true);

/**
 * @brief Emits a sound to all clients.
 *
 * @param keyID             The key array.
 * @param num               (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param channel           (Optional) The channel to emit with.
 * @param human             (Optional) True to include zombie players.
 * @param zombie            (Optional) True to include human players.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
native float ZP_EmitSoundToAll(int keyID, int num = 0, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO, bool human = true, bool zombie = true);

/**
 * @brief Emits a sound to the client.
 *
 * @param keyID             The key array.
 * @param num               (Optional) The position index. (for not random sound)
 * @param client            The client index.
 * @param entity            (Optional) The entity to emit from.
 * @param channel           (Optional) The channel to emit with.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
native float ZP_EmitSoundToClient(int keyID, int num = 0, int client, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO);

/**
 * @brief Emits an ambient sound.
 *
 * @param keyID             The key array.
 * @param num               (Optional) The position index. (for not random sound)
 * @param origin            The sound origin.
 * @param entity            (Optional) The entity to associate sound with.
 * @param level             (Optional) The sound level.
 * @param flags             (Optional) The sound flags.
 * @param volume            (Optional) The sound volume.
 * @param pitch             (Optional) The sound pitch.
 * @param delay             (Optional) The play delay.
 * @return                  The sound duration. (returns 0 if not emitted)
 **/
native float ZP_EmitAmbientSound(int keyID, int num = 0, const float origin[3], int entity = SOUND_FROM_WORLD, float delay = 0.0);

/**
 * @brief Stops a sound to all clients.
 *
 * @param keyID             The key array.
 * @param num               (Optional) The position index. (for all sounds)
 * @param entity            (Optional) The entity to emit from.
 * @param channel           (Optional) The channel to emit with.
 * @return                  True if the sound was stopped, false otherwise.
 **/
native bool ZP_StopSoundToAll(int keyID, int num = 0, int entity = SOUND_FROM_PLAYER, int channel = SNDCHAN_AUTO);