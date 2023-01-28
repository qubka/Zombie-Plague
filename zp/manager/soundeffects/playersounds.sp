/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          playersounds.sp
 *  Type:          Module 
 *  Description:   Player sound effects.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 * @section Struct of sounds used by the plugin.
 **/
enum struct SoundData
{
	int Flashlight;
	int Ammunition;
	int Level;
	int Nvgs;
	int Start;
	int Count;
	int Blast;
}
/**
 * @endsection
 **/
 
/**
 * Array to store sound data in.
 **/
SoundData gSoundData;

/**
 * @brief Prepare all player sounds data.
 **/
void PlayerSoundsOnOnLoad(/*void*/)
{
	// Initialize buffer char
	static char sBuffer[SMALL_LINE_LENGTH];
	
	// Load player flashlight sounds
	gCvarList.SEFFECTS_PLAYER_FLASHLIGHT.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Flashlight = SoundsKeyToIndex(sBuffer);

	// Load player nightvision sounds
	gCvarList.SEFFECTS_PLAYER_NVGS.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Nvgs = SoundsKeyToIndex(sBuffer);
	
	// Load player ammunition sounds
	gCvarList.SEFFECTS_PLAYER_AMMUNITION.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Ammunition = SoundsKeyToIndex(sBuffer);

	// Load player level sounds
	gCvarList.SEFFECTS_PLAYER_LEVEL.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Level = SoundsKeyToIndex(sBuffer);

	// Load round start sounds
	gCvarList.SEFFECTS_ROUND_START.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Start = SoundsKeyToIndex(sBuffer);

	// Load round count sounds
	gCvarList.SEFFECTS_ROUND_COUNT.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Count = SoundsKeyToIndex(sBuffer);
	
	// Load round blast sounds
	gCvarList.SEFFECTS_ROUND_BLAST.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Blast = SoundsKeyToIndex(sBuffer);
}

/**
 * @brief Hook player sounds cvar changes.
 **/
void PlayerSoundsOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.SEFFECTS_INFECT            = FindConVar("zp_seffects_infect");
	gCvarList.SEFFECTS_MOAN              = FindConVar("zp_seffects_moan");
	gCvarList.SEFFECTS_GROAN             = FindConVar("zp_seffects_groan");
	gCvarList.SEFFECTS_BURN              = FindConVar("zp_seffects_burn");
	gCvarList.SEFFECTS_DEATH             = FindConVar("zp_seffects_death");
	gCvarList.SEFFECTS_FOOTSTEPS         = FindConVar("zp_seffects_footsteps");
	gCvarList.SEFFECTS_CLAWS             = FindConVar("zp_seffects_claws");
	gCvarList.SEFFECTS_PLAYER_FLASHLIGHT = FindConVar("zp_seffects_player_flashlight");  
	gCvarList.SEFFECTS_PLAYER_NVGS       = FindConVar("zp_seffects_player_nvgs");  
	gCvarList.SEFFECTS_PLAYER_AMMUNITION = FindConVar("zp_seffects_player_ammunition");
	gCvarList.SEFFECTS_PLAYER_LEVEL      = FindConVar("zp_seffects_player_level");
	gCvarList.SEFFECTS_ROUND_START       = FindConVar("zp_seffects_round_start");   
	gCvarList.SEFFECTS_ROUND_COUNT       = FindConVar("zp_seffects_round_count");   
	gCvarList.SEFFECTS_ROUND_BLAST       = FindConVar("zp_seffects_round_blast");
	
	// Hook cvars
	HookConVarChange(gCvarList.SEFFECTS_PLAYER_FLASHLIGHT, PlayerSoundsOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_PLAYER_NVGS,       PlayerSoundsOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_PLAYER_AMMUNITION, PlayerSoundsOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_PLAYER_LEVEL,      PlayerSoundsOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_ROUND_START,       PlayerSoundsOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_ROUND_COUNT,       PlayerSoundsOnCvarHook);
	HookConVarChange(gCvarList.SEFFECTS_ROUND_BLAST,       PlayerSoundsOnCvarHook);
}

/**
 * @brief The counter is begin.
 **/
void PlayerSoundsOnCounterStart(/*void*/)
{
	// Emit round start sound
	SEffectsInputEmitToAll(gSoundData.Start, _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
}

/**
 * @brief Timer callback, the round is ending. *(Post)
 *
 * @param reason            The reason index.
 **/
public Action PlayerSoundsOnRoundEndPost(Handle hTimer, CSRoundEndReason reason)
{
	// Clear timer
	gServerData.EndTimer = null;
	
	// Gets reason
	switch (reason)
	{
		// Emit sounds
		case CSRoundEnd_TerroristWin : SEffectsInputEmitToAll(ModesGetSoundEndZombieID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);   
		case CSRoundEnd_CTWin :        SEffectsInputEmitToAll(ModesGetSoundEndHumanID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
		case CSRoundEnd_Draw :         SEffectsInputEmitToAll(ModesGetSoundEndDrawID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief The counter is working.
 *
 * @return                  True or false.
 **/
bool PlayerSoundsOnCounter(/*void*/)
{
	// Emit counter sound
	return SEffectsInputEmitToAll(gSoundData.Count, gServerData.RoundCount, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_CONVO);
}

/**
 * @brief Timer callback, the blast is started. *(Post)
 **/
public Action PlayerSoundsOnBlastPost(Handle hTimer)
{
	// Clear timer
	gServerData.BlastTimer = null;
	
	// Emit blast sound
	SEffectsInputEmitToAll(gSoundData.Blast, _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_CAR);

	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief The gamemode is starting.
 **/
void PlayerSoundsOnGameModeStart(/*void*/)
{
	// Emit round start sound
	SEffectsInputEmitToAll(ModesGetSoundStartID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientDeath(int client)
{
	// If death sound cvar is disabled, then stop
	bool bDeath = gCvarList.SEFFECTS_DEATH.BoolValue;
	if (!bDeath)
	{
		return;
	}

	// Emit death sound
	SEffectsInputEmitToAll(ClassGetSoundDeathID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_DISHWASHER);
}

/**
 * @brief Client has been hurt.
 * 
 * @param client            The client index.
 * @param bBurning          The burning type of damage. 
 **/
void PlayerSoundsOnClientHurt(int client, bool bBurning)
{
	// Gets groan factor, if 0, then stop
	int iGroan = gCvarList.SEFFECTS_GROAN.IntValue;
	if (!iGroan)
	{
		return;
	}

	// 1 in 'groan' chance of groaning
	if (GetRandomInt(1, iGroan) == 1)
	{
		// Validate burning
		if (bBurning)
		{
			// If burn sounds disabled, then skip
			if (gCvarList.SEFFECTS_BURN.BoolValue) 
			{
				// Emit burn sound
				SEffectsInputEmitToAll(ClassGetSoundBurnID(gClientData[client].Class), _, client, SNDCHAN_BODY, SNDLEVEL_FRIDGE);
				return; /// Exit here
			}
		}
		
		// Emit hurt sound
		SEffectsInputEmitToAll(ClassGetSoundHurtID(gClientData[client].Class), _, client, SNDCHAN_BODY, SNDLEVEL_FRIDGE);
	}
}

/**
 * @brief Client has been infected.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index.
 **/
void PlayerSoundsOnClientInfected(int client, int attacker)
{
	// If infect sound cvar is disabled, then skip
	if (gCvarList.SEFFECTS_INFECT.BoolValue) 
	{
		// If change was done by server
		if (!attacker)
		{
			// Emit respawn sound
			SEffectsInputEmitToAll(ClassGetSoundRespawnID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_HOME);
		}
		else
		{
			// Emit infect sound
			SEffectsInputEmitToAll(ClassGetSoundInfectID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_DRYER);
		}
	}
	
	// If interval is set to 0, then stop
	float flInterval = gCvarList.SEFFECTS_MOAN.FloatValue;
	if (!flInterval)
	{
		return;
	}

	// Start repeating timer
	delete gClientData[client].MoanTimer;
	gClientData[client].MoanTimer = CreateTimer(flInterval, PlayerSoundsOnMoanRepeat, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief Timer callback, repeats a moaning sound on zombies.
 * 
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action PlayerSoundsOnMoanRepeat(Handle hTimer, int userID)
{
	// Gets client index from the user ID
	int client = GetClientOfUserId(userID);

	// Validate client
	if (client)
	{
		// Emit moan sound
		SEffectsInputEmitToAll(ClassGetSoundIdleID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_CONVO);

		// Allow timer
		return Plugin_Continue;
	}

	// Clear timer
	gClientData[client].MoanTimer = null;
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Client has been regenerating.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientRegen(int client)
{
	// Emit regen sound
	SEffectsInputEmitToAll(ClassGetSoundRegenID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientJump(int client)
{
	// Emit jump sound
	SEffectsInputEmitToAll(ClassGetSoundJumpID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
}

/**
 * @brief Client has been switch nightvision.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientNvgs(int client)
{
	// Emit player nightvision sound
	SEffectsInputEmitToAll(gSoundData.Nvgs, _, client, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
}

/**
 * @brief Client has been switch flashlight.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientFlashLight(int client)
{
	// Emit player flashlight sound
	SEffectsInputEmitToAll(gSoundData.Flashlight, _, client, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
}

/**
 * @brief Client has been buy ammunition.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientAmmunition(int client)
{
	// Emit player ammunition sound
	SEffectsInputEmitToAll(gSoundData.Ammunition, _, client, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
}

/**
 * @brief Client has been level up.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientLevelUp(int client)
{
	// Emit player levelup sound
	SEffectsInputEmitToAll(gSoundData.Level, _, client, SNDCHAN_ITEM, SNDLEVEL_WHISPER);
}

/**
 * @brief Client has been shoot.
 * 
 * @param client            The client index.
 * @param iD                The weapon id.
 * @return                  True or false.
 **/
bool PlayerSoundsOnClientShoot(int client, int iD)
{
	// Emit player shoot sound
	return SEffectsInputEmitToAll(WeaponsGetSoundID(iD), _, client, SNDCHAN_WEAPON, SNDLEVEL_HOME);
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value ifyou add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entity            Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFrags            The sound flags.
 * @param sEntry            The game sound entry name.
 * @param iSeed             The sound seed.
 **/ 
public Action PlayerSoundsNormalHook(int clients[MAXPLAYERS], int &numClients, char sSample[PLATFORM_MAX_PATH], int &entity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFrags, char sEntry[PLATFORM_MAX_PATH], int& iSeed)
{
	// Validate entity 
	if (IsValidEdict(entity))
	{
		// Gets entity classname
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));

		// Validate client
		if (IsPlayerExist(entity))
		{
			// If a footstep sounds, then proceed
			if (StrContains(sSample, "footsteps", false) != -1)
			{
				// If the client is frozen, then stop
				if (GetEntityMoveType(entity) == MOVETYPE_NONE)
				{
					// Block sounds
					return Plugin_Stop; 
				}

				// If footstep sounds disabled, then stop
				if (gCvarList.SEFFECTS_FOOTSTEPS.BoolValue) 
				{
					// Emit footstep sound
					if (SEffectsInputEmitToAll(ClassGetSoundFootID(gClientData[entity].Class), _, entity, SNDCHAN_STREAM, SNDLEVEL_LIBRARY))
					{
						// Block sounds
						return Plugin_Stop; 
					}
				}
			}
		}
		// Validate melee
		else if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_' && // weapon_
			   (sClassname[7] == 'k' || // knife
			   (sClassname[7] == 'm' && sClassname[8] == 'e') ||  // melee
			   (sClassname[7] == 'f' && sClassname[9] == 's'))) // fists
		{
			// If a knife sounds, then proceed 
			if (StrContains(sSample, "knife", false) != -1)
			{
				// If attack sounds disabled, then stop
				if (gCvarList.SEFFECTS_CLAWS.BoolValue) 
				{
					// Validate client
					int client = ToolsGetOwner(entity);
					if (IsPlayerExist(client))
					{
						// Emit slash sound
						if (SEffectsInputEmitToAll(ClassGetSoundAttackID(gClientData[client].Class), _, entity, SNDCHAN_STATIC, SNDLEVEL_HOME))
						{
							// Block sounds
							return Plugin_Stop; 
						}
					}
				}
			}
		}
		else
		{
			// Gets string length
			int iLen = strlen(sClassname) - 11;
			
			// Validate length
			if (iLen > 0)
			{
				// Validate grenade
				if (!strncmp(sClassname[iLen], "_proj", 5, false))
				{
					// Call forward
					Action hResult;
					gForwardData._OnGrenadeSound(entity, WeaponsGetCustomID(entity), hResult); 
					return hResult;
				}
			}
		}
	}

	// Allow sounds
	return Plugin_Continue;
}

/**
 * Cvar hook callback (zp_seffects_player_*, zp_seffects_round_*)
 * @brief Load the sound variables.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void PlayerSoundsOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{    
	// Validate new value
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	// Validate loaded map
	if (gServerData.MapLoaded)
	{
		// Forward event to modules
		PlayerSoundsOnOnLoad();
	}
}
