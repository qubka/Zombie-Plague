/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          gamemodes.sp
 *  Type:          Manager 
 *  Description:   API for loading gamemodes specific variables.
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
 * Number of max valid rounds.
 **/
#define GAMEMODES_ROUND_MAX 15 
 
/**
 * @section Mode native data indexes.
 **/
enum
{
	GAMEMODES_DATA_NAME,
	GAMEMODES_DATA_DESC,
	GAMEMODES_DATA_DESCCOLOR,
	GAMEMODES_DATA_DESCPOSX,
	GAMEMODES_DATA_DESCPOSY,
	GAMEMODES_DATA_DESCTIME,
	GAMEMODES_DATA_CHANCE,
	GAMEMODES_DATA_MINPLAYERS,
	GAMEMODES_DATA_RATIO,
	GAMEMODES_DATA_HEALTHHUMAN,
	GAMEMODES_DATA_HEALTHZOMBIE,
	GAMEMODES_DATA_GROUP,
	GAMEMODES_DATA_SOUNDSTART,
	GAMEMODES_DATA_SOUNDENDHUMAN,
	GAMEMODES_DATA_SOUNDENDZOMBIE,
	GAMEMODES_DATA_SOUNDENDDRAW,
	GAMEMODES_DATA_SOUNDAMBIENT,
	GAMEMODES_DATA_SOUNDDURATION,
	GAMEMODES_DATA_SOUNDVOLUME,
	GAMEMODES_DATA_INFECTION,
	GAMEMODES_DATA_RESPAWN,
	GAMEMODES_DATA_HUMANTYPE,
	GAMEMODES_DATA_ZOMBIETYPE,
	GAMEMODES_DATA_OVERLAYHUMAN,
	GAMEMODES_DATA_OVERLAYZOMBIE,
	GAMEMODES_DATA_OVERLAYDRAW,
	GAMEMODES_DATA_DEATHMATCH,
	GAMEMODES_DATA_AMOUNT,
	GAMEMODES_DATA_DELAY,
	GAMEMODES_DATA_LAST,
	GAMEMODES_DATA_SUICIDE,
	GAMEMODES_DATA_ESCAPE,
	GAMEMODES_DATA_BLAST,
	GAMEMODES_DATA_XRAY,
	GAMEMODES_DATA_REGEN,
	GAMEMODES_DATA_SKILL,
	GAMEMODES_DATA_LEAPJUMP,
	GAMEMODES_DATA_WEAPON,
	GAMEMODES_DATA_EXTRAITEM
};
/**
 * @endsection
 **/
 
/*
 * Load other modes modules
 */
#include "zp/manager/playerclasses/modesmenu.sp"

/**
 * @brief Gamemodes module init function.
 **/
void GameModesOnInit(/*void*/)
{
	// Hook server events
	HookEvent("round_prestart",     GameModesOnStartPre,  EventHookMode_Pre);
	HookEvent("round_start",        GameModesOnStart,     EventHookMode_Post);
	///HookEvent("round_poststart", GameModesOnStartPost, EventHookMode_Post);
	HookEvent("cs_win_panel_round", GameModesOnPanel,     EventHookMode_Pre);
	
	// Creates a HUD synchronization object
	gServerData.GameSync = CreateHudSynchronizer();
	
	// Initialize an eligible client array
	gServerData.Clients = CreateArray();
	gServerData.LastZombies = CreateArray();
}

/**
 * @brief Gamemodes module purge function.
 **/
void GameModesOnPurge(/*void*/)
{
	// Purge server timers
	gServerData.PurgeTimers();
}

/**
 * @brief Prepare all gamemode data.
 **/
void GameModesOnLoad(/*void*/)
{
	// Register config file
	ConfigRegisterConfig(File_GameModes, Structure_KeyValue, CONFIG_FILE_ALIAS_GAMEMODES);

	// Gets gamemodes config path
	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_GAMEMODES, sBuffer, sizeof(sBuffer));

	// If file doesn't exist, then log and stop
	if (!bExists)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Missing gamemodes config file: \"%s\"", sBuffer);
		return;
	}
	
	// Sets path to the config file
	ConfigSetConfigPath(File_GameModes, sBuffer);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_GameModes, gServerData.GameModes);

	// Unexpected error, stop plugin
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Unexpected error encountered loading: \"%s\"", sBuffer);
		return;
	}

	// Now copy data to array structure
	GameModesOnCacheData();

	// Sets config data
	ConfigSetConfigLoaded(File_GameModes, true);
	ConfigSetConfigReloadFunc(File_GameModes, GetFunctionByName(GetMyHandle(), "GameModesOnConfigReload"));
	ConfigSetConfigHandle(File_GameModes, gServerData.GameModes);
	
	// Call server events *(Fake)
	GameModesOnStartPre(view_as<Event>(null), "", false); 
	///GameModesOnStart(view_as<Event>(null), "", false); 
}

/**
 * @brief Caches gamemode data from file into arrays.
 **/
void GameModesOnCacheData(/*void*/)
{
	// Gets config file path
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_GameModes, sBuffer, sizeof(sBuffer));

	// Opens config
	KeyValues kvGameModes;
	bool bSuccess = ConfigOpenConfigFile(File_GameModes, kvGameModes);

	// Validate config
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Unexpected error caching data from gamemodes config file: \"%s\"", sBuffer);
		return;
	}

	// Validate size
	int iSize = gServerData.GameModes.Length;
	if (!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "No usable data found in gamemodes config file: \"%s\"", sBuffer);
		return;
	}
	
	// i = array index
	for (int i = 0; i < iSize; i++)
	{
		// General
		ModesGetName(i, sBuffer, sizeof(sBuffer)); // Index: 0
		kvGameModes.Rewind();
		if (!kvGameModes.JumpToKey(sBuffer))
		{
			// Log gamemode fatal
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Couldn't cache gamemode data for: \"%s\" (check gamemodes config)", sBuffer);
			continue;
		}
		
		// Validate translation
		if (!TranslationIsPhraseExists(sBuffer))
		{
			// Log weapon error
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Couldn't cache gamemode name: \"%s\" (check translation file)", sBuffer);
			continue;
		}

		// Initialize array block
		ArrayList arrayGameMode = gServerData.GameModes.Get(i);

		// Push data into array
		kvGameModes.GetString("desc", sBuffer, sizeof(sBuffer), "");
		if (!TranslationIsPhraseExists(sBuffer) && hasLength(sBuffer))
		{
			// Log gamemode error
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_GameModes, "Config Validation", "Couldn't cache gamemode description: \"%s\" (check translation file)", sBuffer);
		}
		arrayGameMode.PushString(sBuffer);                                          // Index: 1
		int iColor[4]; kvGameModes.GetColor4("color", iColor);
		arrayGameMode.PushArray(iColor, sizeof(iColor));                            // Index: 2
		arrayGameMode.Push(kvGameModes.GetFloat("position_X", -1.0));               // Index: 3
		arrayGameMode.Push(kvGameModes.GetFloat("position_Y", -1.0));               // Index: 4
		arrayGameMode.Push(kvGameModes.GetFloat("time", 0.0));                      // Index: 5
		arrayGameMode.Push(kvGameModes.GetNum("chance", 0));                        // Index: 6
		arrayGameMode.Push(kvGameModes.GetNum("min", 0));                           // Index: 7
		arrayGameMode.Push(kvGameModes.GetFloat("ratio", 0.0));                     // Index: 8
		arrayGameMode.Push(kvGameModes.GetNum("health_human", 0));                  // Index: 9
		arrayGameMode.Push(kvGameModes.GetNum("health_zombie", 0));                 // Index: 10
		kvGameModes.GetString("group", sBuffer, sizeof(sBuffer), "");
		arrayGameMode.PushString(sBuffer);                                          // Index: 11
		kvGameModes.GetString("start", sBuffer, sizeof(sBuffer), "");               
		arrayGameMode.Push(SoundsKeyToIndex(sBuffer));                              // Index: 12
		kvGameModes.GetString("end_human", sBuffer, sizeof(sBuffer), "");           
		arrayGameMode.Push(SoundsKeyToIndex(sBuffer));                              // Index: 13
		kvGameModes.GetString("end_zombie", sBuffer, sizeof(sBuffer), "");          
		arrayGameMode.Push(SoundsKeyToIndex(sBuffer));                              // Index: 14
		kvGameModes.GetString("end_draw", sBuffer, sizeof(sBuffer), "");            
		arrayGameMode.Push(SoundsKeyToIndex(sBuffer));                              // Index: 15
		kvGameModes.GetString("ambient", sBuffer, sizeof(sBuffer), "");             
		arrayGameMode.Push(SoundsKeyToIndex(sBuffer));                              // Index: 16
		arrayGameMode.Push(kvGameModes.GetFloat("duration", 60.0));                 // Index: 17
		arrayGameMode.Push(kvGameModes.GetFloat("volume", 1.0));                    // Index: 18
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "infect", "yes"));    // Index: 19
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "respawn", "yes"));   // Index: 20
		kvGameModes.GetString("humantype", sBuffer, sizeof(sBuffer), "human");
		arrayGameMode.Push(gServerData.Types.FindString(sBuffer));                  // Index: 21
		kvGameModes.GetString("zombietype", sBuffer, sizeof(sBuffer), "zombie");   
		arrayGameMode.Push(gServerData.Types.FindString(sBuffer));                  // Index: 22
		kvGameModes.GetString("overlay_human", sBuffer, sizeof(sBuffer), "");       
		arrayGameMode.PushString(sBuffer);                                          // Index: 23
		if (hasLength(sBuffer))                                                     
		{
			// Precache material
			Format(sBuffer, sizeof(sBuffer), "materials/%s", sBuffer);
			DecryptPrecacheTextures("self", sBuffer);
		}
		kvGameModes.GetString("overlay_zombie", sBuffer, sizeof(sBuffer), "");
		arrayGameMode.PushString(sBuffer);                                       // Index: 24
		if (hasLength(sBuffer)) 
		{
			// Precache material
			Format(sBuffer, sizeof(sBuffer), "materials/%s", sBuffer);
			DecryptPrecacheTextures("self", sBuffer);
		}
		kvGameModes.GetString("overlay_draw", sBuffer, sizeof(sBuffer), "");
		arrayGameMode.PushString(sBuffer);                                       // Index: 25
		if (hasLength(sBuffer)) 
		{
			// Precache material
			Format(sBuffer, sizeof(sBuffer), "materials/%s", sBuffer);
			DecryptPrecacheTextures("self", sBuffer);
		}
		arrayGameMode.Push(kvGameModes.GetNum("deathmatch", 0));                    // Index: 26
		arrayGameMode.Push(kvGameModes.GetNum("amount", 0));                        // Index: 27
		arrayGameMode.Push(kvGameModes.GetFloat("delay", 0.0));                     // Index: 28
		arrayGameMode.Push(kvGameModes.GetNum("last", 0));                          // Index: 29
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "suicide", "no"));    // Index: 30
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "escape", "off"));    // Index: 31
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "blast", "on"));      // Index: 32
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "xray", "on"));       // Index: 33
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "regen", "on"));      // Index: 34
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "skill", "yes"));     // Index: 35
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "leapjump", "yes"));  // Index: 36
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "weapon", "yes"));    // Index: 37
		arrayGameMode.Push(ConfigKvGetStringBool(kvGameModes, "extraitem", "yes")); // Index: 38
	}

	// We're done with this file now, so we can close it
	delete kvGameModes;
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void GameModesOnConfigReload(/*void*/)
{
	// Reloads gamemodes config
	GameModesOnLoad();
}

/**
 * @brief Hook gamemodes cvar changes.
 **/
void GameModesOnCvarInit(/*void*/)
{
	// Creates cvars
	gCvarList.GAMEMODE                     = FindConVar("zp_gamemode");
	gCvarList.GAMEMODE_BLAST_TIME          = FindConVar("zp_blast_time");
	gCvarList.GAMEMODE_WEAPONS_REMOVE      = FindConVar("zp_remove_weapons_when_mode_started");
	gCvarList.GAMEMODE_TEAM_BALANCE        = FindConVar("mp_autoteambalance"); 
	gCvarList.GAMEMODE_LIMIT_TEAMS         = FindConVar("mp_limitteams");
	gCvarList.GAMEMODE_WARMUP_TIME         = FindConVar("mp_warmuptime");
	gCvarList.GAMEMODE_WARMUP_PERIOD       = FindConVar("mp_do_warmup_period");
	gCvarList.GAMEMODE_ROUNDTIME_ZP        = FindConVar("mp_roundtime");
	gCvarList.GAMEMODE_ROUNDTIME_CS        = FindConVar("mp_roundtime_hostage");
	gCvarList.GAMEMODE_ROUNDTIME_DE        = FindConVar("mp_roundtime_defuse");
	gCvarList.GAMEMODE_ROUND_RESTART       = FindConVar("mp_restartgame");
	gCvarList.GAMEMODE_RESTART_DELAY       = FindConVar("mp_round_restart_delay");
	
	// Sets locked cvars to their locked value
	gCvarList.GAMEMODE_TEAM_BALANCE.IntValue  = 0;
	gCvarList.GAMEMODE_LIMIT_TEAMS.IntValue   = 0;
	gCvarList.GAMEMODE_WARMUP_TIME.IntValue   = 0;
	gCvarList.GAMEMODE_WARMUP_PERIOD.IntValue = 0;
	
	// Hook locked cvars to prevent it from changing
	HookConVarChange(gCvarList.GAMEMODE_TEAM_BALANCE,  CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.GAMEMODE_LIMIT_TEAMS,   CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.GAMEMODE_WARMUP_TIME,   CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.GAMEMODE_WARMUP_PERIOD, CvarsLockOnCvarHook);
	HookConVarChange(gCvarList.GAMEMODE_ROUNDTIME_ZP,  GameModesOnCvarHookTime);
	HookConVarChange(gCvarList.GAMEMODE_ROUNDTIME_CS,  GameModesOnCvarHookTime);
	HookConVarChange(gCvarList.GAMEMODE_ROUNDTIME_DE,  GameModesOnCvarHookTime);
	HookConVarChange(gCvarList.GAMEMODE_ROUND_RESTART, GameModesOnCvarHookRestart);
}

/**
 * @brief Creates commands for gamemodes module.
 **/
void GameModesOnCommandInit(/*void*/)
{
	// Hook commands
	AddCommandListener(GameModesOnCommandListened, "mp_warmup_start");
	///AddCommandListener(GameModesOnCommandListened, "mp_warmup_end");
	
	// Forward event to sub-modules
	ModesMenuOnCommandInit();
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param client            The client index.
 **/
void GameModesOnClientDisconnectPost(/*int client*/)
{
	// Check the last human/zombie
	ModesDisconnectLast();
}

/**
 * Cvar hook callback (mp_roundtime, mp_roundtime_hostage, mp_roundtime_defuse)
 * @brief Prevent from long rounds.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void GameModesOnCvarHookTime(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// If cvar is mp_roundtime_hostage or mp_roundtime_defuse, then continue
	if (hConVar == gCvarList.GAMEMODE_ROUNDTIME_CS || hConVar == gCvarList.GAMEMODE_ROUNDTIME_DE)
	{
		// Revert to specific value
		hConVar.IntValue = gCvarList.GAMEMODE_ROUNDTIME_ZP.IntValue;
	}
	
	// If value was invalid, then stop
	int iDelay = StringToInt(newValue);
	if (iDelay <= GAMEMODES_ROUND_MAX)
	{
		return;
	}
	
	// Revert to minimum value
	hConVar.SetInt(GAMEMODES_ROUND_MAX);
}

/**
 * Cvar hook callback. (mp_restartgame)
 * @brief Stops restart and just ends the round.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void GameModesOnCvarHookRestart(ConVar hConVar, char[] oldValue, char[] newValue)
{
	// Prevent round restart
	hConVar.IntValue = 0;

	// If value was invalid, then stop
	int iDelay = StringToInt(newValue);
	if (iDelay <= 0)
	{
		return;
	}
	
	// Resets number of rounds
	gServerData.RoundNumber = 0;
	
	// Resets score in the scoreboard
	SetTeamScore(TEAM_HUMAN,  0);
	SetTeamScore(TEAM_ZOMBIE, 0);

	// Terminate the round with restart time as delay
	CS_TerminateRound(1.0, CSRoundEnd_GameStart, true);
}

/**
 * Listener command callback (mp_warmup_start)
 * @brief Blocks the warmup period.
 *
 * @param entity            The entity index. (Client, or 0 for server)
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action GameModesOnCommandListened(int entity, char[] commandMsg, int iArguments)
{
	// Validate server
	if (!entity)
	{
		// Block warmup
		GameRules_SetProp("m_bWarmupPeriod", false); 
		GameRules_SetPropFloat("m_fWarmupPeriodStart", 0.0);
	}
	
	// Block commands
	return Plugin_Handled;
}

/*
 * Game modes main functions.
 */

/**
 * @brief Timer callback, use by the round counter.
 *
 * @param hTimer            The timer handle.
 **/
public Action GameModesOnCounter(Handle hTimer)
{
	// Gets amount of total alive players
	int iAlive = fnGetAlive();

	// Validate amount of alive players
	if (iAlive > 1)
	{
		// If counter is working ?
		if (gServerData.RoundCount)
		{
			// Validate beginning
			if (gServerData.RoundCount == (gCvarList.GAMEMODE.IntValue - 2))
			{
				// If help messages enabled, then show info
				if (gCvarList.MESSAGES_OBJECTIVE.BoolValue)
				{
					// Show help information
					TranslationPrintToChatAll("general round objective");
					TranslationPrintToChatAll("general ammunition reminder");
					TranslationPrintHintTextAll("general buttons reminder");
				}
				
				// If welcome message enabled, then show info
				float flTime = gCvarList.MESSAGES_WELCOME_HUD_TIME.FloatValue;
				if (flTime > 0.0) 
				{
					// Print welcome message
					TranslationPrintHudTextAll(gServerData.GameSync, gCvarList.MESSAGES_WELCOME_HUD_X.FloatValue, gCvarList.MESSAGES_WELCOME_HUD_Y.FloatValue, flTime, gCvarList.MESSAGES_WELCOME_HUD_R.IntValue, gCvarList.MESSAGES_WELCOME_HUD_G.IntValue, gCvarList.MESSAGES_WELCOME_HUD_B.IntValue, gCvarList.MESSAGES_WELCOME_HUD_A.IntValue, 0, 0.0, gCvarList.MESSAGES_WELCOME_HUD_FADEIN.FloatValue, gCvarList.MESSAGES_WELCOME_HUD_FADEOUT.FloatValue, "general welcome message");
				}
				
				// Forward event to modules
				SoundsOnCounterStart(); /// Play round start after some time
			}

			// Validate counter
			if (SoundsOnCounter()) /// (2)
			{
				// If help messages enabled, then show info
				if (gCvarList.MESSAGES_COUNTER.BoolValue)
				{
					// Show help information
					TranslationPrintHintTextAll("generic zombie comming", gServerData.RoundCount);
				}
			}
		}
		else 
		{
			// Clear timer
			gServerData.CounterTimer = null;
	
			// Start a gamemode
			GameModesOnBegin();
	
			// Destroy timer
			return Plugin_Stop;
		}
		
		// Substitute second
		gServerData.RoundCount--;
	}

	// Allow timer
	return Plugin_Continue;
}

/**
 * @brief Start a gamemode.
 *
 * @param mode              (Optional) The mode index. 
 * @param target            (Optional) The target index.
 **/
void GameModesOnBegin(int mode = -1, int target = -1)
{
	// Resets server grobal variables
	gServerData.RoundNew = false;
	gServerData.RoundEnd = false;
	
	// Gets amount of total alive players
	int iAlive = fnGetAlive(); 

	/*_________________________________________________________________________________________________________________________________________*/
	
	// Validate random mode
	if (mode == -1)
	{
		// i = mode number
		int iSize = gServerData.GameModes.Length; static int defaultMode; 
		for (int i = 0; i < iSize; i++)
		{
			// Starting default game mode ?
			if (gServerData.RoundLast != i && GetRandomInt(1, ModesGetChance(i)) == ModesGetChance(i) && iAlive > ModesGetMinPlayers(i)) mode = i; 
			else if (!ModesGetChance(i)) defaultMode = i; /// Find a default mode    
		}
		
		// Try choosing a default game mode
		if (mode == -1) mode = defaultMode;
	}

	// Sets chosen game mode index
	gServerData.RoundMode = mode;

	/*_________________________________________________________________________________________________________________________________________*/
	
	// Compute the maximum zombie amount
	int iMaxZombies = RoundToNearest(iAlive * ModesGetRatio(gServerData.RoundMode)); 
	if (iMaxZombies == iAlive) iMaxZombies--; /// Subsract for a high ratio
	else if (!iMaxZombies) iMaxZombies++; /// Increment for a low ratio

	// Initialize variables
	static char sBuffer[SMALL_LINE_LENGTH];
	
	// Gets game mode desc
	ModesGetDesc(gServerData.RoundMode, sBuffer, sizeof(sBuffer));
	if (hasLength(sBuffer)) 
	{
		// Gets desc color 
		static int iColor[4];
		ModesGetDescColor(gServerData.RoundMode, iColor, sizeof(iColor));

		// Gets desc time
		float flTime = ModesGetDescTime(gServerData.RoundMode);
		if (flTime)
		{
			// Print game mode description
			TranslationPrintHudTextAll(gServerData.GameSync, ModesGetDescPosX(gServerData.RoundMode), ModesGetDescPosY(gServerData.RoundMode), flTime, iColor[0], iColor[1], iColor[2], iColor[3], 0, 0.0, 0.0, 0.0, sBuffer);
		}
	}
	
	// Reshuffle clients array
	ModesUpdateClientArray(target);
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Gets zombie class type
	int iType = ModesGetZombieTypeID(gServerData.RoundMode);
	
	// i = client index
	for (int i = 0; i < iMaxZombies; i++) /// Turn players into the zombies
	{
		// Gets the client index from array
		int client = gServerData.Clients.Get(i);
	
		// Make zombies
		ApplyOnClientUpdate(client, _, iType);
		ToolsSetHealth(client, ToolsGetHealth(client) + (iAlive * ModesGetHealthZombie(gServerData.RoundMode))); /// Give additional health
	
		// Store the userid of a zombie for next round
		gServerData.LastZombies.Push(GetClientUserId(client));
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Gets human class type
	iType = ModesGetHumanTypeID(gServerData.RoundMode);

	// Make standard humans
	if (iType == gServerData.Human)
	{
		// i = client index    
		for (int i = iMaxZombies; i < iAlive; i++) /// Remaining players should be humans
		{
			// Gets the client index from array
			int client = gServerData.Clients.Get(i);
		
			// Switch team
			ApplyOnClientTeam(client, TEAM_HUMAN);
			ToolsSetHealth(client, ToolsGetHealth(client) + (iAlive * ModesGetHealthHuman(gServerData.RoundMode))); /// Give additional health
		}
	}
	// Make custom humans
	else
	{
		// i = client index
		for (int i = iMaxZombies; i < iAlive; i++) /// Remaining players should be humans
		{
			// Gets the client index from array
			int client = gServerData.Clients.Get(i);
		
			// Make humans
			ApplyOnClientUpdate(client, _, iType);
			ToolsSetHealth(client, ToolsGetHealth(client) + (iAlive * ModesGetHealthHuman(gServerData.RoundMode))); /// Give additional health
		}
	}

	// Forward event to modules
	SoundsOnGameModeStart();
	
	/// Remove dropped entities
	ModesKillEntities(true);

	// Resets server grobal variables (2)
	gServerData.RoundStart = true;
	
	// Validate counter
	if (gServerData.CounterTimer != null)
	{
		// Resets server counter 
		delete gServerData.CounterTimer;
	}

	// Call forward
	gForwardData._OnGameModeStart(gServerData.RoundMode);
	
	// Update mode index for the next round
	gServerData.RoundLast = gServerData.RoundMode;
}

/**
 * Event callback (round_prestart)
 * @brief The round is starting.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action GameModesOnStartPre(Event hEvent, char[] sName, bool dontBroadcast) 
{
	// Resets server global variables
	gServerData.RoundNew   = true;
	gServerData.RoundEnd   = false;
	gServerData.RoundStart = false;
	
	// Update server grobal variables
	gServerData.RoundMode  = -1;
	gServerData.RoundNumber++;
	gServerData.RoundCount = gCvarList.GAMEMODE.IntValue;
	
	// Clear server counter
	delete gServerData.CounterTimer;
	if (gServerData.RoundCount)
	{
		// Creates timer for starting gamemodes
		gServerData.CounterTimer = CreateTimer(1.0, GameModesOnCounter, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// Clear server sounds
	delete gServerData.EndTimer;
	delete gServerData.BlastTimer;
	
	// Forward event to modules
	ModesBalanceTeams();
	
	// Allow event
	return Plugin_Continue;
}

/**
 * Event callback (round_start)
 * @brief The round is start.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action GameModesOnStart(Event hEvent, char[] sName, bool dontBroadcast) 
{
	/// Remove func entities
	ModesKillEntities();
	
	// Forward event to modules
	SoundsOnRoundStart();
	
	// Allow event
	return Plugin_Continue;
}

/**
 * Event callback (round_poststart)
 * @brief The round is started.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
/*public Action GameModesOnStartPost(Event hEvent, char[] sName, bool dontBroadcast) 
{
}*/

/**
 * Event callback (cs_win_panel_round)
 * @brief The win panel was been created.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action GameModesOnPanel(Event hEvent, char[] sName, bool dontBroadcast) 
{
	// Sets whether an event broadcasting will be disabled
	if (!dontBroadcast) 
	{
		// Disable broadcasting
		hEvent.BroadcastDisabled = true;
		
		// Change event
		return Plugin_Changed;
	}
	
	// Allow event
	return Plugin_Continue;
}

/**
 * @brief Timer callback, the blast is started. *(Post)
 **/
public Action GameModesOnBlast(Handle hTimer)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate zombie
		if (IsPlayerExist(i) && gClientData[i].Zombie)
		{
			// Forward event to modules
			VEffectsOnBlast(i);
	
			// Forces a player to commit suicide
			ForcePlayerSuicide(i);
		}
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Called when TerminateRound is called.
 * 
 * @param flDelay           Time (in seconds) until new round starts.
 * @param iReason           The reason index.
 **/
public Action CS_OnTerminateRound(float& flDelay, CSRoundEndReason& reason)
{
	// Resets server grobal variables
	gServerData.RoundNew   = false;
	gServerData.RoundEnd   = true;
	gServerData.RoundStart = false;
	
	// Resets server counter
	delete gServerData.CounterTimer;

	// If restart, then stop
	if (reason == CSRoundEnd_GameStart)
	{
		// Allow end
		return Plugin_Continue;
	}

	// Gets amount of total humans and zombies
	int iHumans  = fnGetHumans();
	int iZombies = fnGetZombies();

	// Gets team scores
	int iHumanScore  = GetTeamScore(TEAM_HUMAN);
	int iZombieScore = GetTeamScore(TEAM_ZOMBIE);

	// If there are no zombies, that means there must be humans, they win the round
	if (!iZombies && iHumans)
	{
		// Increment CT score
		iHumanScore++;

		// Sets bonus overlay 
		ModesReward(BonusType_Lose, BonusType_Win, Overlay_HumanWin);

		// Sets reason
		reason = CSRoundEnd_CTWin;
	}
	// If there are zombies, then zombies win the round
	else if (iZombies && !iHumans)
	{
		// Increment T score
		iZombieScore++;

		// Sets bonus overlay 
		ModesReward(BonusType_Win, BonusType_Lose, Overlay_ZombieWin);

		// Sets reason
		reason = CSRoundEnd_TerroristWin;
	}
	// We know here, that either zombies or humans is 0 (not both)
	else
	{
		// Increment <> score
		/** skip **/

		// Sets bonus overlay 
		ModesReward(BonusType_Draw, BonusType_Draw, Overlay_Draw);

		// Sets reason
		reason = CSRoundEnd_Draw;
		
		// Create a round blast
		if (iZombies) ModesBlast(flDelay);
	}
	
	// Sets score in the scoreboard
	SetTeamScore(TEAM_HUMAN,  iHumanScore);
	SetTeamScore(TEAM_ZOMBIE, iZombieScore);
	
	// Forward event to modules
	SoundsOnRoundEnd(reason);
	
	// Call forward
	gForwardData._OnGameModeEnd(reason);
	
	// Allow end
	return Plugin_Changed;
}

/*
 * Game modes natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void GameModesOnNativeInit(/*void*/) 
{
	CreateNative("ZP_GetCurrentGameMode",          API_GetCurrentGameMode);
	CreateNative("ZP_GetLastGameMode",             API_GetLastGameMode);
	CreateNative("ZP_GetNumberGameMode",           API_GetNumberGameMode);
	CreateNative("ZP_StartGameMode",               API_StartGameMode);
	CreateNative("ZP_GetGameModeNameID",           API_GetGameModeNameID);
	CreateNative("ZP_GetGameModeName",             API_GetGameModeName);
	CreateNative("ZP_GetGameModeDesc",             API_GetGameModeDesc);
	CreateNative("ZP_GetGameModeDescColor",        API_GetGameModeDescColor);
	CreateNative("ZP_GetGameModeDescPosX",         API_GetGameModeDescPosX);
	CreateNative("ZP_GetGameModeDescPosY",         API_GetGameModeDescPosY);
	CreateNative("ZP_GetGameModeDescTime",         API_GetGameModeDescTime);
	CreateNative("ZP_GetGameModeChance",           API_GetGameModeChance);
	CreateNative("ZP_GetGameModeMinPlayers",       API_GetGameModeMinPlayers);
	CreateNative("ZP_GetGameModeRatio",            API_GetGameModeRatio);
	CreateNative("ZP_GetGameModeHealthHuman",      API_GetGameModeHealthHuman);
	CreateNative("ZP_GetGameModeHealthZombie",     API_GetGameModeHealthZombie);
	CreateNative("ZP_GetGameModeGroup",            API_GetGameModeGroup);
	CreateNative("ZP_GetGameModeSoundStartID",     API_GetGameModeSoundStartID);
	CreateNative("ZP_GetGameModeSoundEndHumanID",  API_GetGameModeSoundEndHumanID);
	CreateNative("ZP_GetGameModeSoundEndZombieID", API_GetGameModeSoundEndZombieID);
	CreateNative("ZP_GetGameModeSoundEndDrawID",   API_GetGameModeSoundEndDrawID);
	CreateNative("ZP_GetGameModeSoundAmbientID",   API_GetGameModeSoundAmbientID);
	CreateNative("ZP_GetGameModeSoundDuration",    API_GetGameModeSoundDuration);
	CreateNative("ZP_GetGameModeSoundVolume",      API_GetGameModeSoundVolume);
	CreateNative("ZP_IsGameModeInfect",            API_IsGameModeInfect);
	CreateNative("ZP_IsGameModeRespawn",           API_IsGameModeRespawn);
	CreateNative("ZP_GetGameModeHumanClassID",     API_GetGameModeHumanClassID);
	CreateNative("ZP_GetGameModeZombieClassID",    API_GetGameModeZombieClassID);
	CreateNative("ZP_GetGameModeOverlayHuman",     API_GetGameModeOverlayHuman);
	CreateNative("ZP_GetGameModeOverlayZombie",    API_GetGameModeOverlayZombie);
	CreateNative("ZP_GetGameModeOverlayDraw",      API_GetGameModeOverlayDraw);
	CreateNative("ZP_GetGameModeMatch",            API_GetGameModeMatch);
	CreateNative("ZP_GetGameModeAmount",           API_GetGameModeAmount);
	CreateNative("ZP_GetGameModeDelay",            API_GetGameModeDelay);
	CreateNative("ZP_GetGameModeLast",             API_GetGameModeLast);
	CreateNative("ZP_IsGameModeSuicide",           API_IsGameModeSuicide);
	CreateNative("ZP_IsGameModeEscape",            API_IsGameModeEscape);
	CreateNative("ZP_IsGameModeBlast",             API_IsGameModeBlast);
	CreateNative("ZP_IsGameModeXRay",              API_IsGameModeXRay);
	CreateNative("ZP_IsGameModeRegen",             API_IsGameModeRegen);
	CreateNative("ZP_IsGameModeSkill",             API_IsGameModeSkill);
	CreateNative("ZP_IsGameModeLeapJump",          API_IsGameModeLeapJump);
	CreateNative("ZP_IsGameModeWeapon",            API_IsGameModeWeapon);
	CreateNative("ZP_IsGameModeExtraItem",         API_IsGameModeExtraItem);
}
 
/**
 * @brief Gets the current game mode.
 *
 * @note native int ZP_GetCurrentGameMode();
 **/
public int API_GetCurrentGameMode(Handle hPlugin, int iNumParams)
{
	// Return the value
	return gServerData.RoundMode;
}

/**
 * @brief Gets the last game mode.
 *
 * @note native int ZP_GetLastGameMode();
 **/
public int API_GetLastGameMode(Handle hPlugin, int iNumParams)
{
	// Return the value
	return gServerData.RoundLast;
}

/**
 * @brief Gets the amount of all game modes.
 *
 * @note native int ZP_GetNumberGameMode();
 **/
public int API_GetNumberGameMode(Handle hPlugin, int iNumParams)
{
	// Return the value 
	return gServerData.GameModes.Length;
}

/**
 * @brief Start the game mode.
 *
 * @note native void ZP_StartGameMode(iD, target);
 **/
public int API_StartGameMode(Handle hPlugin, int iNumParams)
{
	// If mode already started, then stop
	if (!gServerData.RoundNew)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Can't start game mode during the round");
		return -1;
	}
	
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Gets real player index from native cell 
	int target = GetNativeCell(2);

	// Validate client
	if (target != -1 && !IsPlayerExist(target))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the target index (%d)", target);
		return -1;
	}

	// Start the game mode
	GameModesOnBegin(iD, target);
   
	// Return on success
	return iD;
}

/**
 * @brief Gets the index of a game mode at a given name.
 *
 * @note native int ZP_GetGameModeNameID(name);
 **/
public int API_GetGameModeNameID(Handle hPlugin, int iNumParams)
{
	// Retrieves the string length from a native parameter string
	int maxLen;
	GetNativeStringLength(1, maxLen);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Can't find mode with an empty name");
		return -1;
	}
	
	// Gets native data
	static char sName[SMALL_LINE_LENGTH];

	// General
	GetNativeString(1, sName, sizeof(sName));

	// Return the value
	return ModesNameToIndex(sName);  
}

/**
 * @brief Gets the name of a game mode at a given index.
 *
 * @note native void ZP_GetGameModeName(iD, name, maxlen);
 **/
public int API_GetGameModeName(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize name char
	static char sName[SMALL_LINE_LENGTH];
	ModesGetName(iD, sName, sizeof(sName));

	// Return on success
	return SetNativeString(2, sName, maxLen);
}

/**
 * @brief Gets the description of a game mode at a given index.
 *
 * @note native void ZP_GetGameModeDesc(iD, name, maxlen);
 **/
public int API_GetGameModeDesc(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize description char
	static char sDesc[SMALL_LINE_LENGTH];
	ModesGetDesc(iD, sDesc, sizeof(sDesc));

	// Return on success
	return SetNativeString(2, sDesc, maxLen);
}

/**
 * @brief Gets the description color of a game mode at a given index.
 *
 * @note native void ZP_GetGameModeDescColor(iD, color, maxlen);
 **/
public int API_GetGameModeDescColor(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize color array
	static int iColor[4];
	ModesGetDescColor(iD, iColor, sizeof(iColor));

	// Return on success
	return SetNativeArray(2, iColor, maxLen);
}

/**
 * @brief Gets the description X coordinate of the game mode.
 *
 * @note native float ZP_GetGameModeDescPosX(iD);
 **/
public int API_GetGameModeDescPosX(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value (Float fix)
	return view_as<int>(ModesGetDescPosX(iD));
}

/**
 * @brief Gets the description Y coordinate of the game mode.
 *
 * @note native float ZP_GetGameModeDescPosY(iD);
 **/
public int API_GetGameModeDescPosY(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value (Float fix)
	return view_as<int>(ModesGetDescPosY(iD));
}

/**
 * @brief Gets the description time of the game mode.
 *
 * @note native float ZP_GetGameModeDescTime(iD);
 **/
public int API_GetGameModeDescTime(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value (Float fix)
	return view_as<int>(ModesGetDescTime(iD));
}

/**
 * @brief Gets the chance of the game mode.
 *
 * @note native int ZP_GetGameModeChance(iD);
 **/
public int API_GetGameModeChance(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesGetChance(iD);
}

/**
 * @brief Gets the min players of the game mode.
 *
 * @note native int ZP_GetGameModeMinPlayers(iD);
 **/
public int API_GetGameModeMinPlayers(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesGetMinPlayers(iD);
}

/**
 * @brief Gets the ratio of the game mode.
 *
 * @note native float ZP_GetGameModeRatio(iD);
 **/
public int API_GetGameModeRatio(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value (Float fix)
	return view_as<int>(ModesGetRatio(iD));
}

/**
 * @brief Gets the human health of the game mode.
 *
 * @note native int ZP_GetGameModeHealthHuman(iD);
 **/
public int API_GetGameModeHealthHuman(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesGetHealthHuman(iD);
}

/**
 * @brief Gets the zombie health of the game mode.
 *
 * @note native int ZP_GetGameModeHealthZombie(iD);
 **/
public int API_GetGameModeHealthZombie(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesGetHealthZombie(iD);
}

/**
 * @brief Gets the group of a game mode at a given index.
 *
 * @note native void ZP_GetGameModeGroup(iD, group, maxlen);
 **/
public int API_GetGameModeGroup(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize group char
	static char sGroup[SMALL_LINE_LENGTH];
	ModesGetGroup(iD, sGroup, sizeof(sGroup));

	// Return on success
	return SetNativeString(2, sGroup, maxLen);
}

/**
 * @brief Gets the start sound key of the game mode.
 *
 * @note native int ZP_GetGameModeSoundStartID(iD);
 **/
public int API_GetGameModeSoundStartID(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetSoundStartID(iD);
}

/**
 * @brief Gets the end human sound key of the game mode.
 *
 * @note native int ZP_GetGameModeSoundEndHumanID(iD);
 **/
public int API_GetGameModeSoundEndHumanID(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetSoundEndHumanID(iD);
}

/**
 * @brief Gets the end zombie sound key of the game mode.
 *
 * @note native int ZP_GetGameModeSoundEndZombieID(iD);
 **/
public int API_GetGameModeSoundEndZombieID(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetSoundEndZombieID(iD);
}

/**
 * @brief Gets the end draw sound key of the game mode.
 *
 * @note native int ZP_GetGameModeSoundEndDrawID(iD);
 **/
public int API_GetGameModeSoundEndDrawID(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetSoundEndDrawID(iD);
}

/**
 * @brief Gets the ambient sound key of the game mode.
 *
 * @note native int ZP_GetGameModeSoundAmbientID(iD);
 **/
public int API_GetGameModeSoundAmbientID(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetSoundAmbientID(iD);
}

/**
 * @brief Gets the ambient sound duration of the game mode.
 *
 * @note native int ZP_GetGameModeSoundDuration(iD);
 **/
public int API_GetGameModeSoundDuration(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value (Float fix)
	return view_as<int>(ModesGetSoundDuration(iD));
}

/**
 * @brief Gets the ambient sound volume of the game mode.
 *
 * @note native int ZP_GetGameModeSoundVolume(iD);
 **/
public int API_GetGameModeSoundVolume(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value (Float fix)
	return view_as<int>(ModesGetSoundVolume(iD));
}

/**
 * @brief Checks the infection type of the game mode.
 *
 * @note native bool ZP_IsGameModeInfect(iD);
 **/
public int API_IsGameModeInfect(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsInfection(iD);
}

/**
 * @brief Checks the respawn type of the game mode.
 *
 * @note native bool ZP_IsGameModeRespawn(iD);
 **/
public int API_IsGameModeRespawn(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsRespawn(iD);
}

/**
 * @brief Gets the human type of a game mode.
 *
 * @note native int ZP_GetGameModeNameClassID(iD);
 **/
public int API_GetGameModeHumanClassID(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesGetHumanTypeID(iD);
}

/**
 * @brief Gets the human type of a game mode.
 *
 * @note native int ZP_GetGameModeZombieClassID(iD);
 **/
public int API_GetGameModeZombieClassID(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesGetZombieTypeID(iD);
}

/**
 * @brief Gets the human win overlay of a game mode at a given index.
 *
 * @note native void ZP_GetGameModeOverlayHuman(iD, overlay, maxlen);
 **/
public int API_GetGameModeOverlayHuman(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize overlay char
	static char sOverlay[PLATFORM_LINE_LENGTH];
	ModesGetOverlayHuman(iD, sOverlay, sizeof(sOverlay));

	// Return on success
	return SetNativeString(2, sOverlay, maxLen);
}

/**
 * @brief Gets the zombie win overlay of a game mode at a given index.
 *
 * @note native void ZP_GetGameModeOverlayZombie(iD, overlay, maxlen);
 **/
public int API_GetGameModeOverlayZombie(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize overlay char
	static char sOverlay[PLATFORM_LINE_LENGTH];
	ModesGetOverlayZombie(iD, sOverlay, sizeof(sOverlay));

	// Return on success
	return SetNativeString(2, sOverlay, maxLen);
}

/**
 * @brief Gets the draw overlay of a game mode at a given index.
 *
 * @note native void ZP_GetGameModeOverlayDraw(iD, overlay, maxlen);
 **/
public int API_GetGameModeOverlayDraw(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Gets string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if (!maxLen)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize overlay char
	static char sOverlay[PLATFORM_LINE_LENGTH];
	ModesGetOverlayDraw(iD, sOverlay, sizeof(sOverlay));

	// Return on success
	return SetNativeString(2, sOverlay, maxLen);
}

/**
 * @brief Gets the deathmatch mode of the game mode.
 *
 * @note native int ZP_GetGameModeMatch(iD);
 **/
public int API_GetGameModeMatch(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetMatch(iD);
}

/**
 * @brief Gets the amount of the game mode.
 *
 * @note native int ZP_GetGameModeAmount(iD);
 **/
public int API_GetGameModeAmount(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetAmount(iD);
}

/**
 * @brief Gets the delay of the game mode.
 *
 * @note native float ZP_GetGameModeDelay(iD);
 **/
public int API_GetGameModeDelay(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value (Float fix)
	return view_as<int>(ModesGetDelay(iD));
}

/**
 * @brief Gets the last amount of the game mode.
 *
 * @note native int ZP_GetGameModeLast(iD);
 **/
public int API_GetGameModeLast(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);

	// Validate no game mode
	if (iD == -1)
	{
		return iD;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}

	// Return value
	return ModesGetLast(iD);
}

/**
 * @brief Checks the suicide mode of the game mode.
 *
 * @note native bool ZP_IsGameModeSuicide(iD);
 **/
public int API_IsGameModeSuicide(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsSuicide(iD);
}

/**
 * @brief Checks the escape mode of the game mode.
 *
 * @note native bool ZP_IsGameModeEscape(iD);
 **/
public int API_IsGameModeEscape(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsEscape(iD);
}

/**
 * @brief Checks the blast mode of the game mode.
 *
 * @note native bool ZP_IsGameModeBlast(iD);
 **/
public int API_IsGameModeBlast(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsBlast(iD);
}

/**
 * @brief Checks the xray access of the game mode.
 *
 * @note native bool ZP_IsGameModeXRay(iD);
 **/
public int API_IsGameModeXRay(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsXRay(iD);
}

/**
 * @brief Checks the regen access of the game mode.
 *
 * @note native bool ZP_IsGameModeRegen(iD);
 **/
public int API_IsGameModeRegen(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsRegen(iD);
}

/**
 * @brief Checks the skill access of the game mode.
 *
 * @note native bool ZP_IsGameModeSkill(iD);
 **/
public int API_IsGameModeSkill(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsSkill(iD);
}

/**
 * @brief Checks the leapjump access of the game mode.
 *
 * @note native bool ZP_IsGameModeLeapJump(iD);
 **/
public int API_IsGameModeLeapJump(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsLeapJump(iD);
}

/**
 * @brief Checks the weapon access of the game mode.
 *
 * @note native bool ZP_IsGameModeWeapon(iD);
 **/
public int API_IsGameModeWeapon(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsWeapon(iD);
}

/**
 * @brief Checks the extraitem access of the game mode.
 *
 * @note native bool ZP_IsGameModeExtraItem(iD);
 **/
public int API_IsGameModeExtraItem(Handle hPlugin, int iNumParams)
{
	// Gets mode index from native cell
	int iD = GetNativeCell(1);
	
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Validate index
	if (iD >= gServerData.GameModes.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_GameModes, "Native Validation", "Invalid the mode index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ModesIsExtraItem(iD);
}

/*
 * Game modes data reading API.
 */
 
/**
 * @brief Gets the name of a game mode at a given index.
 *
 * @param iD                The mode index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void ModesGetName(int iD, char[] sName, int iMaxLen)
{
	// Validate no game mode
	if (iD == -1)
	{
		strcopy(sName, iMaxLen, "");
		return;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode name
	arrayGameMode.GetString(GAMEMODES_DATA_NAME, sName, iMaxLen);
}

/**
 * @brief Gets the description of a game mode at a given index.
 *
 * @param iD                The mode index.
 * @param sDesc             The string to return name in.
 * @param iMaxLen           The lenght of string.
 **/
void ModesGetDesc(int iD, char[] sDesc, int iMaxLen)
{
	// Validate no game mode
	if (iD == -1)
	{
		strcopy(sDesc, iMaxLen, "");
		return;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode description
	arrayGameMode.GetString(GAMEMODES_DATA_DESC, sDesc, iMaxLen);
}

/**
 * @brief Gets the description color of a game mode at a given index.
 *
 * @param iD                The mode index.
 * @param iColor            The array to return color in.
 * @param iMaxLen           The max length of the array.
 **/
void ModesGetDescColor(int iD, int[] iColor, int iMaxLen)
{
	// Validate no game mode
	if (iD == -1)
	{
		return;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode description color
	arrayGameMode.GetArray(GAMEMODES_DATA_DESCCOLOR, iColor, iMaxLen);
}

/**
 * @brief Gets the description X coordinate of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The coordinate value.
 **/
float ModesGetDescPosX(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return -1.0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode description X coordinate
	return arrayGameMode.Get(GAMEMODES_DATA_DESCPOSX);
}

/**
 * @brief Gets the description Y coordinate of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The coordinate value.
 **/
float ModesGetDescPosY(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return -1.0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode description Y coordinate
	return arrayGameMode.Get(GAMEMODES_DATA_DESCPOSY);
}

/**
 * @brief Gets the description time of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The time amount.
 **/
float ModesGetDescTime(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0.0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode description time
	return arrayGameMode.Get(GAMEMODES_DATA_DESCTIME);
}

/**
 * @brief Gets the chance of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The chance amount.
 **/
int ModesGetChance(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode chance
	return arrayGameMode.Get(GAMEMODES_DATA_CHANCE);
}

/**
 * @brief Gets the min players of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The min players amount.
 **/
int ModesGetMinPlayers(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode chance
	return arrayGameMode.Get(GAMEMODES_DATA_MINPLAYERS);
}

/**
 * @brief Gets the ratio of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The ratio amount.
 **/
float ModesGetRatio(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0.0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode ratio
	return arrayGameMode.Get(GAMEMODES_DATA_RATIO);
}

/**
 * @brief Gets the human health of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The health amount.
 **/
int ModesGetHealthHuman(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode human health
	return arrayGameMode.Get(GAMEMODES_DATA_HEALTHHUMAN);
}

/**
 * @brief Gets the zombie health of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The health amount.
 **/
int ModesGetHealthZombie(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode zombie health
	return arrayGameMode.Get(GAMEMODES_DATA_HEALTHZOMBIE);
}

/**
 * @brief Gets the group of a game mode at a given index.
 *
 * @param iD                The mode index.
 * @param sGroup            The string to return group in.
 * @param iMaxLen           The lenght of string.
 **/
void ModesGetGroup(int iD, char[] sGroup, int iMaxLen)
{
	// Validate no game mode
	if (iD == -1)
	{
		strcopy(sGroup, iMaxLen, "");
		return;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode group
	arrayGameMode.GetString(GAMEMODES_DATA_GROUP, sGroup, iMaxLen);
}

/**
 * @brief Gets the start sound key of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The key index.
 **/
int ModesGetSoundStartID(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return -1;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode start sound key
	return arrayGameMode.Get(GAMEMODES_DATA_SOUNDSTART);
}

/**
 * @brief Gets the end human sound key of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The key index.
 **/
int ModesGetSoundEndHumanID(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return -1;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode end human sound key
	return arrayGameMode.Get(GAMEMODES_DATA_SOUNDENDHUMAN);
}

/**
 * @brief Gets the end zombie sound key of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The key index.
 **/
int ModesGetSoundEndZombieID(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return -1;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode end zombie sound key
	return arrayGameMode.Get(GAMEMODES_DATA_SOUNDENDZOMBIE);
}

/**
 * @brief Gets the end draw sound key of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The key index.
 **/
int ModesGetSoundEndDrawID(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return -1;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode end draw sound key
	return arrayGameMode.Get(GAMEMODES_DATA_SOUNDENDDRAW);
}

/**
 * @brief Gets the ambient sound key of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The key index.
 **/
int ModesGetSoundAmbientID(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return -1;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode ambient sound key
	return arrayGameMode.Get(GAMEMODES_DATA_SOUNDAMBIENT);
}

/**
 * @brief Gets the ambient sound duration of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The duration amount.
 **/
float ModesGetSoundDuration(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0.0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode ambient sound duration
	return arrayGameMode.Get(GAMEMODES_DATA_SOUNDDURATION);
}

/**
 * @brief Gets the ambient sound volume of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The volume amount.
 **/
float ModesGetSoundVolume(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0.0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode ambient sound volume
	return arrayGameMode.Get(GAMEMODES_DATA_SOUNDVOLUME);
}

/**
 * @brief Checks the infection type of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsInfection(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode infection type
	return arrayGameMode.Get(GAMEMODES_DATA_INFECTION);
}

/**
 * @brief Checks the respawn type of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsRespawn(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode respawn type
	return arrayGameMode.Get(GAMEMODES_DATA_RESPAWN);
}

/**
 * @brief Gets the human type of a game mode.
 *
 * @param iD                The mode index.
 * @return                  The type index.
 **/
int ModesGetHumanTypeID(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return gServerData.Human;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode human type
	return arrayGameMode.Get(GAMEMODES_DATA_HUMANTYPE);
}

/**
 * @brief Gets the zombie type of a game mode.
 *
 * @param iD                The mode index.
 * @return                  The type index.
 **/
int ModesGetZombieTypeID(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return gServerData.Zombie;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode zombie type
	return arrayGameMode.Get(GAMEMODES_DATA_ZOMBIETYPE);
}

/**
 * @brief Gets the human win overlay of a game mode at a given index.
 *
 * @param iD                The mode index.
 * @param sOverlay          The string to return overlay in.
 * @param iMaxLen           The lenght of string.
 **/
void ModesGetOverlayHuman(int iD, char[] sOverlay, int iMaxLen)
{
	// Validate no game mode
	if (iD == -1)
	{
		strcopy(sOverlay, iMaxLen, "");
		return;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode human win overlay
	arrayGameMode.GetString(GAMEMODES_DATA_OVERLAYHUMAN, sOverlay, iMaxLen);
}

/**
 * @brief Gets the zombie win overlay of a game mode at a given index.
 *
 * @param iD                The mode index.
 * @param sOverlay          The string to return overlay in.
 * @param iMaxLen           The lenght of string.
 **/
void ModesGetOverlayZombie(int iD, char[] sOverlay, int iMaxLen)
{
	// Validate no game mode
	if (iD == -1)
	{
		strcopy(sOverlay, iMaxLen, "");
		return;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode zombie win overlay
	arrayGameMode.GetString(GAMEMODES_DATA_OVERLAYZOMBIE, sOverlay, iMaxLen);
}

/**
 * @brief Gets the draw overlay of a game mode at a given index.
 *
 * @param iD                The mode index.
 * @param sOverlay          The string to return overlay in.
 * @param iMaxLen           The lenght of string.
 **/
void ModesGetOverlayDraw(int iD, char[] sOverlay, int iMaxLen)
{
	// Validate no game mode
	if (iD == -1)
	{
		strcopy(sOverlay, iMaxLen, "");
		return;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);
	
	// Gets game mode draw overlay
	arrayGameMode.GetString(GAMEMODES_DATA_OVERLAYDRAW, sOverlay, iMaxLen);
}

/**
 * @brief Gets the deathmatch mode of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The deathmatch mode.
 **/
int ModesGetMatch(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 1;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode deathmatch mode
	return arrayGameMode.Get(GAMEMODES_DATA_DEATHMATCH);
}

/**
 * @brief Gets the amount of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The amount.
 **/
int ModesGetAmount(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode amount
	return arrayGameMode.Get(GAMEMODES_DATA_AMOUNT);
}

/**
 * @brief Gets the delay of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The delay.
 **/
float ModesGetDelay(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0.0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode delay
	return arrayGameMode.Get(GAMEMODES_DATA_DELAY);
}

/**
 * @brief Gets the last amount of the game mode.
 *
 * @param iD                The mode index.
 * @return                  The last amount.
 **/
int ModesGetLast(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return 0;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode last amount
	return arrayGameMode.Get(GAMEMODES_DATA_LAST);
}

/**
 * @brief Checks the suicide mode of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsSuicide(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode suicide mode
	return arrayGameMode.Get(GAMEMODES_DATA_SUICIDE);
}

/**
 * @brief Checks the escape mode of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsEscape(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode escape mode
	return arrayGameMode.Get(GAMEMODES_DATA_ESCAPE);
}

/**
 * @brief Checks the blast mode of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsBlast(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode blast mode
	return arrayGameMode.Get(GAMEMODES_DATA_BLAST);
}

/**
 * @brief Checks the xray access of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsXRay(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode xray access
	return arrayGameMode.Get(GAMEMODES_DATA_XRAY);
}

/**
 * @brief Checks the regen access of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsRegen(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode regen access
	return arrayGameMode.Get(GAMEMODES_DATA_REGEN);
}

/**
 * @brief Checks the skill access of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsSkill(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode skill access
	return arrayGameMode.Get(GAMEMODES_DATA_SKILL);
}

/**
 * @brief Checks the leapjump access of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsLeapJump(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode leapjump access
	return arrayGameMode.Get(GAMEMODES_DATA_LEAPJUMP);
}

/**
 * @brief Checks the weapon access of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsWeapon(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode weapon access
	return arrayGameMode.Get(GAMEMODES_DATA_WEAPON);
}

/**
 * @brief Checks the extraitem access of the game mode.
 *
 * @param iD                The mode index.
 * @return                  True or false.
 **/
bool ModesIsExtraItem(int iD)
{
	// Validate no game mode
	if (iD == -1)
	{
		return false;
	}
	
	// Gets array handle of game mode at given index
	ArrayList arrayGameMode = gServerData.GameModes.Get(iD);

	// Gets game mode extraitem access
	return arrayGameMode.Get(GAMEMODES_DATA_EXTRAITEM);
}

/*
 * Stocks game modes API.
 */
 
/**
 * @brief Find the index at which the gamemode name is at.
 * 
 * @param sName             The mode name.
 * @return                  The array index containing the given mode name.
 **/
int ModesNameToIndex(char[] sName)
{
	// Initialize name char
	static char sModeName[SMALL_LINE_LENGTH];
	
	// i = mode index
	int iSize = gServerData.GameModes.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets mode name 
		ModesGetName(i, sModeName, sizeof(sModeName));
		
		// If names match, then return index
		if (!strcmp(sName, sModeName, false))
		{
			// Return this index
			return i;
		}
	}
	
	// Name doesn't exist
	return -1;
}

/**
 * @brief Validate round ending.
 **/
bool ModesValidateRound(/*void*/)
{
	// If gamemodes disabled, then stop
	if (!gCvarList.GAMEMODE.IntValue)
	{
		return false;
	}
	
	// If mode doesn't started yet, then stop
	if (!gServerData.RoundStart)
	{
		return false;
	}

	// Gets amount of total humans and zombies
	int iHumans  = fnGetHumans();
	int iZombies = fnGetZombies();

	// If there are clients on both teams during validation, then stop
	if (iZombies && iHumans)
	{
		return false;
	}

	// If there are no zombies, that means there must be humans, they win the round
	if (!iZombies && iHumans)
	{
		CS_TerminateRound(gCvarList.GAMEMODE_RESTART_DELAY.FloatValue, CSRoundEnd_CTWin, false);
	}
	// If there are zombies, then zombies win the round
	else if (iZombies && !iHumans)
	{
		CS_TerminateRound(gCvarList.GAMEMODE_RESTART_DELAY.FloatValue, CSRoundEnd_TerroristWin, false);
	}
	// We know here, that either zombies or humans is 0 (not both)
	else
	{
		CS_TerminateRound(gCvarList.GAMEMODE_RESTART_DELAY.FloatValue, CSRoundEnd_Draw, false);
	}

	// Round is over
	return true;
}

/**
 * @brief Checking the last human/zombie disconnection.
 **/
void ModesDisconnectLast(/*void*/)
{
	// If gamemodes disabled, then stop
	if (!gCvarList.GAMEMODE.IntValue)
	{
		return;
	}
	
	// If mode doesn't started yet, then stop
	if (!gServerData.RoundStart)
	{
		return;
	}

	// Initialize variables 
	static char sName[SMALL_LINE_LENGTH]; int client;
	
	// Gets amount of total humans and zombies
	int iHumans  = fnGetHumans();
	int iZombies = fnGetZombies();

	// If the last zombie disconnected, then choose another random zombie
	if (!iZombies && iHumans > 1)
	{
		// Gets random client index
		client = fnGetRandomHuman();
		
		// Make random zombie
		ApplyOnClientUpdate(client, _, ModesGetZombieTypeID(gServerData.RoundMode));
		
		// Gets client name
		GetClientName(client, sName, sizeof(sName));
		
		// Show message
		TranslationPrintHintTextAll("generic zombie left", sName); 
	}
	// If the last human disconnected, then choose another random human
	else if (iZombies > 1 && !iHumans)
	{
		// Gets random client index
		client = fnGetRandomZombie();
		
		// Make random human
		ApplyOnClientUpdate(client, _, ModesGetHumanTypeID(gServerData.RoundMode));
		
		// Gets client name
		GetClientName(client, sName, sizeof(sName));
		
		// Show message
		TranslationPrintHintTextAll("generic human left", sName); 
	}
	// If all last players disconnected, then terminate round
	else if (!iZombies && !iHumans)
	{
		// Terminate the round with draw reason
		CS_TerminateRound(gCvarList.GAMEMODE_RESTART_DELAY.FloatValue, CSRoundEnd_Draw, false);
		
		// Show message
		TranslationPrintHintTextAll("generic player left"); 
	}
}

/**
 * @brief Balances all teams.
 **/
void ModesBalanceTeams(/*void*/)
{
	// Move team clients to random teams

	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if (IsPlayerExist(i, false))
		{
			// Validate team
			if (ToolsGetTeam(i) <= TEAM_SPECTATOR)
			{
				continue;
			}
	
			// Swith team
			ApplyOnClientTeam(i, (i & 1) ? TEAM_ZOMBIE : TEAM_HUMAN);
		}
	}
}

/**
 * @brief Kills all objective entities.
 * 
 * @param bDrop             (Optional) If true will removed dropped entities, false all 'func_' entities.
 **/
void ModesKillEntities(bool bDrop = false)
{
	// Initialize name char
	static char sClassname[NORMAL_LINE_LENGTH];

	// Is removal mode of dropped ents ?
	if (bDrop)
	{
		// If removing is disabled, then stop
		if (!gCvarList.GAMEMODE_WEAPONS_REMOVE.BoolValue)
		{
			return;
		}
  
		// i = entity index
		int MaxEntities = GetMaxEntities();
		for (int i = MaxClients; i <= MaxEntities; i++)
		{
			// Validate entity
			if (IsValidEdict(i))
			{
				// Gets valid edict classname
				GetEdictClassname(i, sClassname, sizeof(sClassname));

				// Validate weapon
				if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_')
				{
					// Gets weapon owner
					int client = WeaponsGetOwner(i);
					
					// Validate owner
					if (!IsPlayerExist(client))
					{
						// Validate non map weapons, then remove
						if (!WeaponsIsSpawnedByMap(i))
						{
							AcceptEntityInput(i, "Kill"); /// Destroy
						}
					}
				}
			}
		}
	}
	else
	{
		// i = entity index
		int MaxEntities = GetMaxEntities();
		for (int i = MaxClients; i <= MaxEntities; i++)
		{
			// Validate entity
			if (IsValidEdict(i))
			{
				// Gets valid edict classname
				GetEdictClassname(i, sClassname, sizeof(sClassname));

				// Validate objectives
				if ((sClassname[0] == 'h' && sClassname[7] == '_' && sClassname[8] == 'e') || // hostage_entity
				   (sClassname[0] == 'f' && // func_
				   (sClassname[5] == 'h' || // _hostage_rescue
				   (sClassname[5] == 'b' && (sClassname[7] == 'y' || sClassname[7] == 'm'))))) // _buyzone , _bomb_target
				{
					AcceptEntityInput(i, "Kill"); /// Destroy
				}
				// Validate weapon
				else if (sClassname[0] == 'w' && sClassname[1] == 'e' && sClassname[6] == '_')
				{
					// Gets weapon owner
					int client = WeaponsGetOwner(i);
					
					// Validate owner
					if (!IsPlayerExist(client))
					{
						// Validate spawn, if allowed sets custom properties, otherwise remove
						if (!WeaponsSpawnedByMap(i, sClassname))
						{
							AcceptEntityInput(i, "Kill"); /// Destroy
						}
					}
				}
			}
		}
	}
}

/**
 * @brief Generates a client array for the infection with the filtering of last zombies.
 *
 * @param target            (Optional) The target index.
 **/
void ModesUpdateClientArray(int target = -1)
{
	// Reset the player list
	gServerData.Clients.Clear();

	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if (IsPlayerExist(i))
		{
			// Skip clients, which was zombies previously
			if (gServerData.LastZombies.FindValue(GetClientUserId(i)) == -1)
			{
				// Push client
				gServerData.Clients.Push(i);
			}
		}
	}

	// Reshuffle both arrays
	ArrayShuffle(gServerData.Clients);
	ArrayShuffle(gServerData.LastZombies);

	// i = cell index
	int iSize = gServerData.LastZombies.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Add the last zombies to the main array if they are valid
		int client = GetClientOfUserId(gServerData.LastZombies.Get(i));
		if (IsPlayerExist(client))
		{
			// Append to list
			gServerData.Clients.Push(client);
		}
	}

	// Reset the zombies list
	gServerData.LastZombies.Clear();

	// Validate target
	if (target != -1)
	{
		// If target is found in the list, then swap it to start for zombies, to last for humans
		int client = gServerData.Clients.FindValue(target);
		if (client != -1)
		{
			// Simple swap here
			gServerData.Clients.SwapAt(client, (ModesGetRatio(gServerData.RoundMode) < 0.5) ? 0 : gServerData.Clients.Length - 1);
		}
	}
}

/**
 * @brief Gives rewards by the bonus type and shows overlay.
 * 
 * @param rZombie           The zombie bonus type.
 * @param rHuman            The human bonus type.
 * @param nOverlay          The overlay type.
 **/
void ModesReward(int rZombie, int rHuman, OverlayType nOverlay)
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++)
	{
		// Validate client
		if (IsPlayerExist(i, false))
		{
			// Validate team
			if (ToolsGetTeam(i) <= TEAM_SPECTATOR)
			{
				continue;
			}
			
			// Gets class exp and money bonuses
			static int iExp[6]; static int iMoney[6];
			ClassGetExp(gClientData[i].Class, iExp, sizeof(iExp));
			ClassGetMoney(gClientData[i].Class, iMoney, sizeof(iMoney));
			
			// Increment money/exp
			LevelSystemOnSetExp(i, gClientData[i].Exp + (gClientData[i].Zombie ? iExp[rZombie] : iExp[rHuman]));
			AccountSetClientCash(i, gClientData[i].Money + (gClientData[i].Zombie ? iMoney[rZombie] : iMoney[rHuman]));

			// Display overlay to the client
			VOverlayOnClientUpdate(i, nOverlay);
		}
	}
}

/**
 * @brief Create the round blast to kill all zombies.
 *
 * @param flDelay           Time (in seconds) until new round starts.
 **/
void ModesBlast(float flDelay)
{
	// Validate blast mode
	if (!ModesIsBlast(gServerData.RoundMode))
	{
		return;
	}

	// Validate blast time
	float flTime = gCvarList.GAMEMODE_BLAST_TIME.FloatValue;
	if (flTime < flDelay)
	{
		// Forward event to modules
		SoundsOnBlast();
		
		// If help messages enabled, then show info
		if (gCvarList.MESSAGES_BLAST.BoolValue)
		{
			// Show help information
			TranslationPrintHintTextAll("general blast reminder");
		}

		// Create timer for emit sounds
		CreateTimer(flTime, GameModesOnBlast, _, TIMER_FLAG_NO_MAPCHANGE); 
	}
} 