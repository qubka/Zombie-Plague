/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          soundeffects.sp
 *  Type:          Module 
 *  Description:   Sounds basic functions.
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
 * @brief Emits a sound to all clients.
 *
 * @param iKey              The key array.
 * @param iNum              (Optional) The position index. (for not random sound)
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speaker           (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (update positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsInputEmitToAll(int iKey, int iNum = 0, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speaker = -1, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
	// Initialize sound char
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	// Gets sound path
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	// Validate sound
	if (hasLength(sSound))
	{
		// Format sound
		Format(sSound, sizeof(sSound), "*/%s", sSound);

		// Emit sound
		EmitSoundToAll(sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch, speaker, vPosition, vDirection, updatePos, flSoundTime);
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
 * @param client            The client index.
 * @param entity            (Optional) The entity to emit from.
 * @param iChannel          (Optional) The channel to emit with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param speaker           (Optional) Unknown.
 * @param vPosition         (Optional) The sound origin.
 * @param vDirection        (Optional) The sound direction.
 * @param updatePos         (Optional) Unknown (update positions?)
 * @param flSoundTime       (Optional) Alternate time to play sound for.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsInputEmitToClient(int iKey, int iNum = 0, int client, int entity = SOUND_FROM_PLAYER, int iChannel = SNDCHAN_AUTO, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, int speaker = -1, float vPosition[3] = NULL_VECTOR, float vDirection[3] = NULL_VECTOR, bool updatePos = true, float flSoundTime = 0.0)
{
	// Initialize sound char
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	// Gets sound path
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	// Validate sound
	if (hasLength(sSound))
	{
		// Format sound
		Format(sSound, sizeof(sSound), "*/%s", sSound);

		// Emit sound
		EmitSoundToClient(client, sSound, entity, iChannel, iLevel, iFlags, flVolume, iPitch, speaker, vPosition, vDirection, updatePos, flSoundTime);
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
 * @param entity            (Optional) The entity to associate sound with.
 * @param iLevel            (Optional) The sound level.
 * @param iFlags            (Optional) The sound flags.
 * @param flVolume          (Optional) The sound volume.
 * @param iPitch            (Optional) The sound pitch.
 * @param flDelay           (Optional) The play delay.
 * @return                  True if the sound was emitted, false otherwise.
 **/
bool SEffectsInputEmitAmbient(int iKey, int iNum = 0, float vPosition[3], int entity = SOUND_FROM_WORLD, int iLevel = SNDLEVEL_NORMAL, int iFlags = SND_NOFLAGS, float flVolume = SNDVOL_NORMAL, int iPitch = SNDPITCH_NORMAL, float flDelay = 0.0)
{
	// Initialize sound char
	static char sSound[PLATFORM_LINE_LENGTH]; sSound[0] = NULL_STRING[0];
	
	// Gets sound path
	SoundsGetPath(iKey, sSound, sizeof(sSound), iNum);
	
	// Validate sound
	if (hasLength(sSound))
	{
		// Format sound
		Format(sSound, sizeof(sSound), "*/%s", sSound);

		// Emit sound
		EmitAmbientSound(sSound, vPosition, entity, iLevel, iFlags, flVolume, iPitch, flDelay);
		return true;
	}

	// Sound doesn't exist
	return false;
}

/**
 * @brief Stop sounds.
 *  
 * @param iKey              The key array.
 * @param client            (Optional) The client index.
 * @param iChannel          (Optional) The channel to emit with.
 **/
void SEffectsInputStopSound(int iKey, int client = -1, int iChannel = SNDCHAN_AUTO)
{
	// Stop all sounds
	SoundsStopAll(iKey, client, iChannel);
}

/**
 * @brief Stop all sounds.
 **/
void SEffectsInputStopAll(/*void*/)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate real client
		if (IsPlayerExist(i, false) && !IsFakeClient(i))
		{
			// Stop sound
			ClientCommand(i, "playgamesound Music.StopAllExceptMusic");
		}
	}
}

/**
 * @brief Control sounds of a weapon on the client side.
 *  
 * @param client            The client index.
 * @param iItem             The weapon def.
 * @param bEnable           True to enable sounds, false otherwise.
 **/
/*void SEffectsInputClientWeapon(int client, ItemDef iItem, bool bEnable)
{
	// Validate real client
	if (IsFakeClient(client))
	{
		return;
	}
	
	/// Format sound
	static char sSound[NORMAL_LINE_LENGTH];
	FormatEx(sSound, sizeof(sSound), "snd_setsoundparam ");
	switch (iItem)
	{
		case ItemDef_Deagle : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_DEagle.Single");
		}
		case ItemDef_Elite : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Elite.Single");
		}
		case ItemDef_FiveSeven : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_FiveSeven.Single");
		}
		case ItemDef_Glock : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Glock.Single");
		}
		case ItemDef_AK47 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_AK47.Single");
		}
		case ItemDef_AUG : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_AUG.Single");
		}
		case ItemDef_AWP : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_AWP.Single");
		}
		case ItemDef_Famas : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_FAMAS.Single");
		}
		case ItemDef_G3SG1 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_G3SG1.Single");
		}
		case ItemDef_GalilAR : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_GalilAR.Single");
		}
		case ItemDef_M249 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_M249.Single");
		}
		case ItemDef_M4A4 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_M4A4.Single");
		}
		case ItemDef_MAC10 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_MAC10.Single");
		}
		case ItemDef_P90 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_P90.Single");
		}
		case ItemDef_MP5 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_MP5.Single");
		}
		case ItemDef_UMP45 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_UMP45.Single");
		}
		case ItemDef_XM1014 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_XM1014.Single");
		}
		case ItemDef_Bizon : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_bizon.Single");
		}
		case ItemDef_MAG7 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Mag7.Single");
		}
		case ItemDef_Negev : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Negev.Single");
		}
		case ItemDef_SawedOff : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Sawedoff.Single");
		}
		case ItemDef_TEC9 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_tec9.Single");
		}
		case ItemDef_Taser : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Taser.Single");
		}
		case ItemDef_HKP2000 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_hkp2000.Single");
		}
		case ItemDef_MP7 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_MP7.Single");
		}
		case ItemDef_MP9 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_MP9.Single");
		}
		case ItemDef_Nova : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Nova.Single");
		}
		case ItemDef_P250 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_P250.Single");
		}
		case ItemDef_SCAR20 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_scar20.Single");
		}
		case ItemDef_SG553 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_SG556.Single");
		}
		case ItemDef_SSG08 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_SSG08.Single");
		}
		case ItemDef_FlashBang : 
		{
			StrCat(sSound, sizeof(sSound), "Flashbang.Throw");
		}
		case ItemDef_HEGrenade : 
		{
			StrCat(sSound, sizeof(sSound), "HEGrenade.Throw");
		}
		case ItemDef_SmokeGrenade : 
		{
			StrCat(sSound, sizeof(sSound), "SmokeGrenade.Throw");
		}
		case ItemDef_Molotov : 
		{
			StrCat(sSound, sizeof(sSound), "MolotovGrenade.Throw");
		}
		case ItemDef_Decoy : 
		{
			StrCat(sSound, sizeof(sSound), "Decoy.Throw");
		}
		case ItemDef_IncGrenade : 
		{
			StrCat(sSound, sizeof(sSound), "IncGrenade.Throw");
		}
		case ItemDef_C4 : 
		{
			StrCat(sSound, sizeof(sSound), "c4.plant");
		}
		case ItemDef_Healthshot : 
		{
			StrCat(sSound, sizeof(sSound), "c4.plant");
		}
		case ItemDef_M4A1 : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_M4A1.Silenced");
		}
		case ItemDef_USP : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_USP.Single");
		}
		case ItemDef_CZ75A : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_CZ75A.Single");
		}
		case ItemDef_Revolver : 
		{
			StrCat(sSound, sizeof(sSound), "Weapon_Revolver.Single");
		}
		case ItemDef_TAGrenade : 
		{
			StrCat(sSound, sizeof(sSound), "Decoy.Throw");
		}
		case ItemDef_BreachCharge : 
		{
			StrCat(sSound, sizeof(sSound), "c4.plant");
		}
		case ItemDef_SnowBall :
		{
			StrCat(sSound, sizeof(sSound), "Player.SnowballThrow");
		}
		default :
		{
			return;
		}
	}
	Format(sSound, sizeof(sSound), "%s volume %d", sSound, bEnable);
	
	// Sets sound
	ClientCommand(client, sSound);
}*/
