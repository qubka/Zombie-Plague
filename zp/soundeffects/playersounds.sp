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
void PlayerSoundsOnOnLoad()
{
	static char sBuffer[SMALL_LINE_LENGTH];
	
	gCvarList.SEFFECTS_PLAYER_FLASHLIGHT.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Flashlight = SoundsKeyToIndex(sBuffer);

	gCvarList.SEFFECTS_PLAYER_NVGS.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Nvgs = SoundsKeyToIndex(sBuffer);
	
	gCvarList.SEFFECTS_PLAYER_AMMUNITION.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Ammunition = SoundsKeyToIndex(sBuffer);

	gCvarList.SEFFECTS_PLAYER_LEVEL.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Level = SoundsKeyToIndex(sBuffer);

	gCvarList.SEFFECTS_ROUND_START.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Start = SoundsKeyToIndex(sBuffer);

	gCvarList.SEFFECTS_ROUND_COUNT.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Count = SoundsKeyToIndex(sBuffer);
	
	gCvarList.SEFFECTS_ROUND_BLAST.GetString(sBuffer, sizeof(sBuffer));
	gSoundData.Blast = SoundsKeyToIndex(sBuffer);
}

/**
 * @brief Hook player sounds cvar changes.
 **/
void PlayerSoundsOnCvarInit()
{
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
void PlayerSoundsOnCounterStart()
{
	SEffectsInputEmitToAll(gSoundData.Start, _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_AMBIENT);
}

/**
 * @brief Timer callback, the round is ending. *(Post)
 *
 * @param reason            The reason index.
 **/
public Action PlayerSoundsOnRoundEndPost(Handle hTimer, CSRoundEndReason reason)
{
	gServerData.EndTimer = null;
	
	switch (reason)
	{
		case CSRoundEnd_TerroristWin : SEffectsInputEmitToAll(ModesGetSoundEndZombieID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_AMBIENT);   
		case CSRoundEnd_CTWin :        SEffectsInputEmitToAll(ModesGetSoundEndHumanID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_AMBIENT);
		case CSRoundEnd_Draw :         SEffectsInputEmitToAll(ModesGetSoundEndDrawID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_AMBIENT);
	}
	
	return Plugin_Stop;
}

/**
 * @brief The counter is working.
 *
 * @return                  True or false.
 **/
bool PlayerSoundsOnCounter()
{
	return SEffectsInputEmitToAll(gSoundData.Count, gServerData.RoundCount, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_AMBIENT * 2);
}

/**
 * @brief Timer callback, the blast is started. *(Post)
 **/
public Action PlayerSoundsOnBlastPost(Handle hTimer)
{
	gServerData.BlastTimer = null;
	
	SEffectsInputEmitToAll(gSoundData.Blast, _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_EXPLOSION);

	return Plugin_Stop;
}

/**
 * @brief The gamemode is starting.
 **/
void PlayerSoundsOnGameModeStart()
{
	SEffectsInputEmitToAll(ModesGetSoundStartID(gServerData.RoundMode), _, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_AMBIENT);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientDeath(int client)
{
	bool bDeath = gCvarList.SEFFECTS_DEATH.BoolValue;
	if (!bDeath)
	{
		return;
	}

	SEffectsInputEmitToAll(ClassGetSoundDeathID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_DEATH);
}

/**
 * @brief Client has been hurt.
 * 
 * @param client            The client index.
 * @param bBurning          The burning type of damage. 
 **/
void PlayerSoundsOnClientHurt(int client, bool bBurning)
{
	int iGroan = gCvarList.SEFFECTS_GROAN.IntValue;
	if (!iGroan)
	{
		return;
	}

	if (GetRandomInt(1, iGroan) == 1)
	{
		if (bBurning)
		{
			if (gCvarList.SEFFECTS_BURN.BoolValue) 
			{
				SEffectsInputEmitToAll(ClassGetSoundBurnID(gClientData[client].Class), _, client, SNDCHAN_BODY, SNDLEVEL_BURN);
				return; /// Exit here
			}
		}
		
		SEffectsInputEmitToAll(ClassGetSoundHurtID(gClientData[client].Class), _, client, SNDCHAN_BODY, SNDLEVEL_HURT);
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
	if (gCvarList.SEFFECTS_INFECT.BoolValue) 
	{
		if (!attacker)
		{
			SEffectsInputEmitToAll(ClassGetSoundRespawnID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_RESPAWN);
		}
		else
		{
			SEffectsInputEmitToAll(ClassGetSoundInfectID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_INFECT);
		}
	}
	
	float flInterval = gCvarList.SEFFECTS_MOAN.FloatValue;
	if (!flInterval)
	{
		return;
	}

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
	int client = GetClientOfUserId(userID);

	if (client)
	{
		SEffectsInputEmitToAll(ClassGetSoundIdleID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_MOAN);

		return Plugin_Continue;
	}

	gClientData[client].MoanTimer = null;
	
	return Plugin_Stop;
}

/**
 * @brief Client has been regenerating.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientRegen(int client)
{
	SEffectsInputEmitToAll(ClassGetSoundRegenID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_REGEN);
}

/**
 * @brief Client has been leap jumped.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientJump(int client)
{
	SEffectsInputEmitToAll(ClassGetSoundJumpID(gClientData[client].Class), _, client, SNDCHAN_STATIC, SNDLEVEL_LEAPJUMP);
}

/**
 * @brief Client has been switch nightvision.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientNvgs(int client)
{
	SEffectsInputEmitToAll(gSoundData.Nvgs, _, client, SNDCHAN_ITEM, SNDLEVEL_ITEM);
}

/**
 * @brief Client has been switch flashlight.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientFlashLight(int client)
{
	SEffectsInputEmitToAll(gSoundData.Flashlight, _, client, SNDCHAN_ITEM, SNDLEVEL_ITEM);
}

/**
 * @brief Client has been buy ammunition.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientAmmunition(int client)
{
	SEffectsInputEmitToAll(gSoundData.Ammunition, _, client, SNDCHAN_ITEM, SNDLEVEL_ITEM);
}

/**
 * @brief Client has been level up.
 * 
 * @param client            The client index.
 **/
void PlayerSoundsOnClientLevelUp(int client)
{
	SEffectsInputEmitToAll(gSoundData.Level, _, client, SNDCHAN_ITEM, SNDLEVEL_ITEM);
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
	return SEffectsInputEmitToAll(WeaponsGetSoundID(iD), _, client, SNDCHAN_WEAPON, SNDLEVEL_WEAPON);
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
	if (IsValidEdict(entity))
	{
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));

		if (IsPlayerExist(entity))
		{
			if (StrContains(sSample, "footsteps", false) != -1)
			{
				if (GetEntityMoveType(entity) == MOVETYPE_NONE)
				{
					return Plugin_Stop; 
				}

				if (gCvarList.SEFFECTS_FOOTSTEPS.BoolValue) 
				{
					if (SEffectsInputEmitToAll(ClassGetSoundFootID(gClientData[entity].Class), _, entity, SNDCHAN_STREAM, SNDLEVEL_FOOTSTEPS))
					{
						return Plugin_Stop; 
					}
				}
			}
		}
		else if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_' && // weapon_
			   (sClassname[7] == 'k' || // knife
			   (sClassname[7] == 'm' && sClassname[8] == 'e') ||  // melee
			   (sClassname[7] == 'f' && sClassname[9] == 's'))) // fists
		{
			if (StrContains(sSample, "knife", false) != -1)
			{
				if (gCvarList.SEFFECTS_CLAWS.BoolValue) 
				{
					int client = ToolsGetOwner(entity);
					if (IsPlayerExist(client))
					{
						if (SEffectsInputEmitToAll(ClassGetSoundAttackID(gClientData[client].Class), _, entity, SNDCHAN_STATIC, SNDLEVEL_CLAWS))
						{
							return Plugin_Stop; 
						}
					}
				}
			}
		}
		else
		{
			int iLen = strlen(sClassname) - 11;
			
			if (iLen > 0)
			{
				if (!strncmp(sClassname[iLen], "_proj", 5, false))
				{
					Action hResult;
					gForwardData._OnGrenadeSound(entity, ToolsGetCustomID(entity), hResult); 
					return hResult;
				}
			}
		}
	}

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
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	if (gServerData.MapLoaded)
	{
		PlayerSoundsOnOnLoad();
	}
}
