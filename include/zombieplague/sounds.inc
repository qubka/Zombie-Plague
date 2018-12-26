/**
 * =============================================================================
 * Zombie Plague X Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin).
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
 * Gets sound from a key id from sounds config.
 *
 * @param keyID             The key index.
 * @param sound             The string to return sound in.
 * @param maxlenght         The lenght of string.
 * @param position          (Optional) The position index.
 **/
native void ZP_GetSound(int keyID, char[] sound, int maxlenght, int position = 0);