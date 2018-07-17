/**
 * =============================================================================
 * Zombie Plague 8.x Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin).
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
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
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
 * @brief Gets the key id from a given name.
 *
 * @param key               The key name.
 *  
 * @return                  The key id containing the given key.
 **/
native int ZP_GetSoundKeyID(char[] key);

/**
 * @brief Emits sound from a key id from 'sounds.ini' config.
 *
 *     Note: The level will be taken from the 'zp_game_custom_sound_level' server cvar.
 *              
 * @param entityIndex       The entity index. (Can be SOUND_FROM_PLAYER, SOUND_FROM_LOCAL_PLAYER or SOUND_FROM_WORLD)
 * @param keyID             The key id.
 * @param channel           (Optional) The channel to emit with.
 * @param position          (Optional) If 0 sound will be choose randomly from the key.
 *  
 * @return                  True if the sound was emit, false otherwise. 
 **/
native bool ZP_EmitSoundKeyID(int entityIndex, int keyID, int channel = SNDCHAN_STATIC, int position = 0);
