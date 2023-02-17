/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          levelsystem.sp
 *  Type:          Module 
 *  Description:   Provides functions for level system.
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
 * @section Level config data indexes.
 **/
enum
{
	LEVELS_DATA_INDEX
};
/**
 * @endsection 
 **/

/**
 * @brief Level system module init function.
 **/
void LevelSystemOnInit()
{
	if (!gCvarList.LEVEL_SYSTEM.BoolValue || !gCvarList.LEVEL_HUD.BoolValue)
	{
		if (gServerData.MapLoaded)
		{
			if (gServerData.LevelSync != null)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsPlayerExist(i, false))
					{
						delete gClientData[i].LevelTimer;
					}
				}
				
				delete gServerData.LevelSync;
			}
		}
		return;
	}
	
	if (gServerData.LevelSync == null)
	{
		gServerData.LevelSync = CreateHudSynchronizer();
	}
	
	if (gServerData.MapLoaded)
	{
		LevelSystemOnLoad();

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsPlayerExist(i, false))
			{
				LevelSystemOnClientUpdate(i);
			}
		}
	}
}

/**
 * @brief Prepare all level data.
 **/
void LevelSystemOnLoad()
{
	ConfigRegisterConfig(File_Levels, Structure_IntegerList, CONFIG_FILE_ALIAS_LEVELS);
	
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return;
	}
	
	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_LEVELS, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Levels, "Config Validation", "Missing levels config file: %s", sBuffer);
		return;
	}
	
	ConfigSetConfigPath(File_Levels, sBuffer);
	
	bool bSuccess = ConfigLoadConfig(File_Levels, gServerData.Levels);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Levels, "Config Validation", "Unexpected error encountered loading: %s", sBuffer);
		return;
	}

	LevelSystemOnCacheData();

	ConfigSetConfigLoaded(File_Levels, true);
	ConfigSetConfigReloadFunc(File_Levels, GetFunctionByName(GetMyHandle(), "LevelSystemOnConfigReload"));
	ConfigSetConfigHandle(File_Levels, gServerData.Levels);
}

/**
 * @brief Caches level data from file into arrays.
 **/
void LevelSystemOnCacheData()
{
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Levels, sBuffer, sizeof(sBuffer));
	
	int iLevels = gServerData.Levels.Length;
	if (!iLevels)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Levels, "Config Validation", "No usable data found in levels config file: %s", sBuffer);
		return;
	}
	
	ArrayList hList = new ArrayList();

	for (int i = 0; i < iLevels; i++)
	{
		int iLimit = gServerData.Levels.Get(i);
		
		if (iLimit <= 0 || hList.FindValue(iLimit) != -1)
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Levels, "Config Validation", "Incorrect level \"%s\" = %d , %d", sBuffer, iLimit, i);
			
			gServerData.Levels.Erase(i);

			iLevels--;

			i--;
			continue;
		}
		
		hList.Push(iLimit);
	}
	
	if (!iLevels)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Levels, "Config Validation", "No usable data found in levels config file: %s", sBuffer);
		return;
	}
	
	SortADTArray(hList, Sort_Ascending, Sort_Integer);
	
	delete gServerData.Levels;
	gServerData.Levels = hList.Clone();
	delete hList;
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void LevelSystemOnConfigReload()
{
	LevelSystemOnLoad();
}

/**
 * @brief Creates commands for level system module.
 **/
void LevelSystemOnCommandInit()
{
	RegAdminCmd("zp_level_give", LevelSystemLevelOnCommandCatched, ADMFLAG_GENERIC, "Gives the level. Usage: zp_level_give <#userid|name|steamid|@accountid> [amount]");
	RegAdminCmd("zp_exp_give", LevelSystemExpOnCommandCatched, ADMFLAG_GENERIC, "Gives the experience. Usage: zp_exp_give <#userid|name|steamid|@accountid> [amount]");
}

/**
 * @brief Hook level system cvar changes.
 **/
void LevelSystemOnCvarInit()
{
	gCvarList.LEVEL_SYSTEM          = FindConVar("zp_level_system");
	gCvarList.LEVEL_HEALTH_RATIO    = FindConVar("zp_level_health_ratio");
	gCvarList.LEVEL_SPEED_RATIO     = FindConVar("zp_level_speed_ratio");
	gCvarList.LEVEL_GRAVITY_RATIO   = FindConVar("zp_level_gravity_ratio");
	gCvarList.LEVEL_DAMAGE_RATIO    = FindConVar("zp_level_damage_ratio");
	gCvarList.LEVEL_HUD             = FindConVar("zp_level_hud");
	gCvarList.LEVEL_HUD_ZOMBIE_R    = FindConVar("zp_level_hud_zombie_R");
	gCvarList.LEVEL_HUD_ZOMBIE_G    = FindConVar("zp_level_hud_zombie_G");
	gCvarList.LEVEL_HUD_ZOMBIE_B    = FindConVar("zp_level_hud_zombie_B");
	gCvarList.LEVEL_HUD_ZOMBIE_A    = FindConVar("zp_level_hud_zombie_A");
	gCvarList.LEVEL_HUD_HUMAN_R     = FindConVar("zp_level_hud_human_R");
	gCvarList.LEVEL_HUD_HUMAN_G     = FindConVar("zp_level_hud_human_G");
	gCvarList.LEVEL_HUD_HUMAN_B     = FindConVar("zp_level_hud_human_B");
	gCvarList.LEVEL_HUD_HUMAN_A     = FindConVar("zp_level_hud_human_A");
	gCvarList.LEVEL_HUD_SPECTATOR_R = FindConVar("zp_level_hud_spectator_R");
	gCvarList.LEVEL_HUD_SPECTATOR_G = FindConVar("zp_level_hud_spectator_G");
	gCvarList.LEVEL_HUD_SPECTATOR_B = FindConVar("zp_level_hud_spectator_B");    
	gCvarList.LEVEL_HUD_SPECTATOR_A = FindConVar("zp_level_hud_spectator_A");
	gCvarList.LEVEL_HUD_X           = FindConVar("zp_level_hud_X");
	gCvarList.LEVEL_HUD_Y           = FindConVar("zp_level_hud_Y");
	
	HookConVarChange(gCvarList.LEVEL_SYSTEM,        LevelSystemOnCvarHook);       
	HookConVarChange(gCvarList.LEVEL_HUD,           LevelSystemOnCvarHook); 
	HookConVarChange(gCvarList.LEVEL_HEALTH_RATIO,  LevelSystemOnCvarHookRatio);         
	HookConVarChange(gCvarList.LEVEL_SPEED_RATIO,   LevelSystemOnCvarHookRatio);           
	HookConVarChange(gCvarList.LEVEL_GRAVITY_RATIO, LevelSystemOnCvarHookRatio); 
}

/*
 * Level data reading API.
 */

/**
 * @brief Gets the limit at a given level.
 * 
 * @param iLevel            The level amount.
 * @return                  The limit amount.
 **/ 
int LevelSystemGetLimit(int iLevel)
{
	return gServerData.Levels.Get(iLevel-1);
}

/*
 * Level main functions.
 */

/**
 * @brief Client has been spawned.
 * 
 * @param client            The client index.
 **/
void LevelSystemOnClientSpawn(int client)
{
	LevelSystemOnClientUpdate(client);
}

/**
 * @brief Client has been killed.
 * 
 * @param client            The client index.
 **/
void LevelSystemOnClientDeath(int client)
{
	LevelSystemOnClientUpdate(client);
}

/**
 * @brief Client has been changed class state.
 *
 * @param client            The client index.
 **/
void LevelSystemOnClientUpdate(int client)
{
	if (!gCvarList.LEVEL_SYSTEM.BoolValue || !gCvarList.LEVEL_HUD.BoolValue)
	{
		return;
	}
	
	if (!IsFakeClient(client))
	{
		delete gClientData[client].LevelTimer;
		gClientData[client].LevelTimer = CreateTimer(1.0, LevelSystemOnClientHUD, GetClientUserId(client), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

/**
 * @brief Sets the client level and prevent it from overloading.
 *
 * @param client            The client index.
 * @param iLevel            The level amount.
 **/
void LevelSystemOnSetLvl(int client, int iLevel)
{
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return;
	}

	gForwardData._OnClientLevel(client, iLevel);

	if (iLevel <= 0)
	{
		iLevel = 1;
	}

	gClientData[client].Level = iLevel;

	int iMaxLevel = gServerData.Levels.Length;
	
	if (gClientData[client].Level > iMaxLevel)
	{
		gClientData[client].Level = iMaxLevel;
	}
	else
	{
		if (IsPlayerExist(client)) 
		{
			SoundsOnClientLevelUp(client);
		}
	}
	
	DataBaseOnClientUpdate(client, ColumnType_Level);
}

/**
 * @brief Sets the client experience, increasing level if it reach level experience limit and prevent it from overloading.
 *
 * @param client            The client index.
 * @param iExp              The experience amount.
 **/
void LevelSystemOnSetExp(int client, int iExp)
{
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return;
	}

	gForwardData._OnClientExp(client, iExp);
	
	if (iExp < 0)
	{
		iExp = 0;
	}

	gClientData[client].Exp = iExp;

	int iMaxLevel = gServerData.Levels.Length;
	
	if (gClientData[client].Level == iMaxLevel && gClientData[client].Exp > LevelSystemGetLimit(gClientData[client].Level))
	{
		gClientData[client].Exp = LevelSystemGetLimit(gClientData[client].Level);
	}
	else
	{
		while (gClientData[client].Level < iMaxLevel && gClientData[client].Exp >= LevelSystemGetLimit(gClientData[client].Level))
		{
			LevelSystemOnSetLvl(client, gClientData[client].Level + 1);
		}
	}
	
	DataBaseOnClientUpdate(client, ColumnType_Exp);
}

/**
 * @brief Timer callback, show HUD text within information about client level and experience.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action LevelSystemOnClientHUD(Handle hTimer, int userID)
{
	int client = GetClientOfUserId(userID); 

	if (client)
	{
		static int iColor[4];

		int target = client;

		if (!IsPlayerAlive(client))
		{
			int iSpecMode = ToolsGetObserverMode(client);
			if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_3RDPERSON)
			{
				return Plugin_Continue;
			}
			
			target = ToolsGetObserverTarget(client);
			
			if (!IsPlayerExist(target)) 
			{
				return Plugin_Continue;
			}
			
			iColor[0] = gCvarList.LEVEL_HUD_SPECTATOR_R.IntValue;
			iColor[1] = gCvarList.LEVEL_HUD_SPECTATOR_G.IntValue;
			iColor[2] = gCvarList.LEVEL_HUD_SPECTATOR_B.IntValue;
			iColor[3] = gCvarList.LEVEL_HUD_SPECTATOR_A.IntValue;
		}
		else
		{
			if (gClientData[client].Zombie)
			{
				iColor[0] = gCvarList.LEVEL_HUD_ZOMBIE_R.IntValue;
				iColor[1] = gCvarList.LEVEL_HUD_ZOMBIE_G.IntValue;
				iColor[2] = gCvarList.LEVEL_HUD_ZOMBIE_B.IntValue;
				iColor[3] = gCvarList.LEVEL_HUD_ZOMBIE_A.IntValue;
			}
			else
			{
				iColor[0] = gCvarList.LEVEL_HUD_HUMAN_R.IntValue;
				iColor[1] = gCvarList.LEVEL_HUD_HUMAN_G.IntValue;
				iColor[2] = gCvarList.LEVEL_HUD_HUMAN_B.IntValue;
				iColor[3] = gCvarList.LEVEL_HUD_HUMAN_A.IntValue;
			}
		}

		static char sInfo[SMALL_LINE_LENGTH];
		ClassGetName(gClientData[target].Class, sInfo, sizeof(sInfo));

		TranslationPrintHudText(gServerData.LevelSync, client, gCvarList.LEVEL_HUD_X.FloatValue, gCvarList.LEVEL_HUD_Y.FloatValue, 1.1, iColor[0], iColor[1], iColor[2], iColor[3], 0, 0.0, 0.0, 0.0, "info level", sInfo, gClientData[target].Level, gClientData[target].Exp, LevelSystemGetLimit(gClientData[target].Level));

		return Plugin_Continue;
	}
	
	gClientData[client].LevelTimer = null;
	
	return Plugin_Stop;
}

/**
 * Cvar hook callback (zp_level_system)
 * @brief Level system module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	LevelSystemOnInit();
}

/**
 * Cvar hook callback (zp_level_*_ratio)
 * @brief Reloads the health variable on zombie/human.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void LevelSystemOnCvarHookRatio(ConVar hConVar, char[] oldValue, char[] newValue)
{    
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return;
	}
	
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	if (gServerData.MapLoaded)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsPlayerExist(i))
			{
				ToolsSetHealth(i, ClassGetHealth(gClientData[i].Class) + (RoundToNearest(gCvarList.LEVEL_HEALTH_RATIO.FloatValue * float(gClientData[i].Level))), true);
				ToolsSetGravity(i, ClassGetGravity(gClientData[i].Class) + (gCvarList.LEVEL_GRAVITY_RATIO.FloatValue * float(gClientData[i].Level)));
			}
		}
	}
}

/**
 * Console command callback (zp_level_give)
 * @brief Gives the level.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action LevelSystemLevelOnCommandCatched(int client, int iArguments)
{
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return Plugin_Handled;
	}
	
	if (iArguments < 2)
	{
		TranslationReplyToCommand(client, "level give invalid args");
		return Plugin_Handled;
	}
	
	static char sArgument[SMALL_LINE_LENGTH];
	
	GetCmdArg(1, sArgument, sizeof(sArgument));

	int target = FindTargetByID(client, sArgument);

	if (target < 0)
	{
		return Plugin_Handled;
	}
	
	GetCmdArg(2, sArgument, sizeof(sArgument));
	
	int iLevel = StringToInt(sArgument);
	if (iLevel <= 0)
	{
		TranslationReplyToCommand(client, "level give invalid amount", iLevel);
		return Plugin_Handled;
	}

	LevelSystemOnSetLvl(target, gClientData[target].Level + iLevel);

	LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Levels, "Command", "Admin \"%N\" gived level: \"%d\" to Player \"%N\"", client, iLevel, target);
	return Plugin_Handled;
}

/**
 * Console command callback (zp_exp_give)
 * @brief Gives the experience.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action LevelSystemExpOnCommandCatched(int client, int iArguments)
{
	if (!gCvarList.LEVEL_SYSTEM.BoolValue)
	{
		return Plugin_Handled;
	}
	
	if (iArguments < 2)
	{
		TranslationReplyToCommand(client, "experience give invalid args");
		return Plugin_Handled;
	}
	
	static char sArgument[SMALL_LINE_LENGTH];
	
	GetCmdArg(1, sArgument, sizeof(sArgument));

	int target = FindTargetByID(client, sArgument);

	if (target < 0)
	{
		return Plugin_Handled;
	}
	
	GetCmdArg(2, sArgument, sizeof(sArgument));
	
	int iExp = StringToInt(sArgument);
	if (iExp <= 0)
	{
		TranslationReplyToCommand(client, "experience give invalid amount", iExp);
		return Plugin_Handled;
	}

	LevelSystemOnSetExp(target, gClientData[target].Exp + iExp);

	LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Levels, "Command", "Admin \"%N\" gived experience: \"%d\" to Player \"%N\"", client, iExp, target);
	return Plugin_Handled;
}

/*
 * Level system natives API.
 */

/**
 * @brief Sets up natives for library.
 **/
void LevelSystemOnNativeInit()
{
	CreateNative("ZP_GetLevelMax",    API_GetLevelMax);
	CreateNative("ZP_GetLevelLimit",  API_GetLevelLimit);
	CreateNative("ZP_GetClientLevel", API_GetClientLevel);
	CreateNative("ZP_SetClientLevel", API_SetClientLevel);
	CreateNative("ZP_GetClientExp",   API_GetClientExp);
	CreateNative("ZP_SetClientExp",   API_SetClientExp);
}

/**
 * @brief Gets the maximum level.
 *
 * @note native int ZP_GetLevelMax();
 **/
public int API_GetLevelMax(Handle hPlugin, int iNumParams)
{
	return gServerData.Levels.Length;
}

/**
 * @brief Gets the level experience limit.
 *
 * @note native int ZP_GetLevelLimit(iD);
 **/
public int API_GetLevelLimit(Handle hPlugin, int iNumParams)
{
	int iD = GetNativeCell(1);
	
	if (iD < 1 || iD > gServerData.Levels.Length)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Levels, "Native Validation", "Invalid the level index (%d)", iD);
		return -1;
	}

	return LevelSystemGetLimit(iD);
}

/**
 * @brief Gets the player level.
 *
 * @note native int ZP_GetClientLevel(client);
 **/
public int API_GetClientLevel(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	return gClientData[client].Level;
}

/**
 * @brief Sets the player level.
 *
 * @note native void ZP_SetClientLevel(client, iD);
 **/
public int API_SetClientLevel(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	LevelSystemOnSetLvl(client, GetNativeCell(2));
	return 0;
}

/**
 * @brief Gets the player exp.
 *
 * @note native int ZP_GetClientExp(client);
 **/
public int API_GetClientExp(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	return gClientData[client].Exp;
}

/**
 * @brief Sets the player exp.
 *
 * @note native void ZP_SetClientExp(client, iD);
 **/
public int API_SetClientExp(Handle hPlugin, int iNumParams)
{
	int client = GetNativeCell(1);

	LevelSystemOnSetExp(client, GetNativeCell(2));
	return 0;
}
