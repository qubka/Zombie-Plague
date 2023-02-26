/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          zombieplague.sp
 *  Type:          Main 
 *  Description:   General plugin functions and defines.
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
 * @brief Core module init function.
 **/
void GameEngineOnInit()
{
	gServerData.Engine = GetEngineVersion();
	if (gServerData.Engine != Engine_CSGO)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support this game!");
	}
	
	fnInitGameConfOffset(gServerData.Config, view_as<int>(gServerData.Platform), "OS");
	
	gServerData.UpdateTimer = CreateTimer(60.0, GameEngineOnUpdate, _, TIMER_REPEAT);
	GameEngineOnUpdate(null);
}

/**
 * @brief Core module load function.
 **/
void GameEngineOnLoad()
{
	gForwardData._OnEngineExecute();
	
	gServerData.MapLoaded = true;
}

/**
 * @brief Core module map end function.
 **/
void GameEngineOnMapEnd()
{
	gServerData.MapLoaded = false;
	
	gServerData.PurgeTimers();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		gClientData[i].PurgeTimers();
	}
}

/**
 * @brief Hook gameengine cvar changes.
 **/
void GameEngineOnCvarInit()
{
	gCvarList.NIGHT_TIME_MIN = FindConVar("zp_night_time_min");
	gCvarList.NIGHT_TIME_MAX = FindConVar("zp_night_time_max");

	HookConVarChange(gCvarList.NIGHT_TIME_MIN, GameEngineOnCvarHook);
	HookConVarChange(gCvarList.NIGHT_TIME_MAX, GameEngineOnCvarHook);
}

/**
 * Cvar hook callback (zp_night_time_min, zp_night_time_max)
 * @brief Update time checker.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void GameEngineOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
{
	if (gServerData.UpdateTimer != null)
	{
		TriggerTimer(gServerData.UpdateTimer, true);
	}
}

/**
 * @brief Timer callback, updates some core states.
 *
 * @param hTimer            The timer handle.
 **/
public Action GameEngineOnUpdate(Handle hTimer)
{
	static char sBuffer[5];
	
	gCvarList.NIGHT_TIME_MIN.GetString(sBuffer, sizeof(sBuffer));
	int iMin = StringToInt(sBuffer);
	gCvarList.NIGHT_TIME_MAX.GetString(sBuffer, sizeof(sBuffer));
	int iMax = StringToInt(sBuffer);

	bool pPrev = gServerData.NightTime;
	gServerData.NightTime = IsTimeBetween(iMin, iMax);
	if (pPrev != gServerData.NightTime)
	{
		LogEvent(false, LogType_Normal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Update", "Zombie Plague: %s night time state!", gServerData.NightTime ? "enter" : "leave");
	}

	return Plugin_Continue;
}

/*
 * Stocks core API.
 */

/**
 * @brief Gets amount of total playing players.
 *
 * @return                  The amount of total playing players.
 **/
stock int fnGetPlaying()
{
	int iPlaying;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i, false))
		{
			iPlaying++;
		}
	}
	
	return iPlaying;
}
 
/**
 * @brief Gets amount of total humans.
 * 
 * @return                  The amount of total humans.
 **/
stock int fnGetHumans()
{
	int iHumans;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && !gClientData[i].Zombie)
		{
			iHumans++;
		}
	}
	
	return iHumans;
}

/**
 * @brief Gets amount of total zombies.
 *
 * @return                  The amount of total zombies.
 **/
stock int fnGetZombies()
{
	int iZombies;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && gClientData[i].Zombie)
		{
			iZombies++;
		}
	}
	
	return iZombies;
}

/**
 * @brief Gets amount of total alive players.
 *
 * @return                  The amount of total alive players.
 **/
stock int fnGetAlive()
{
	int iAlive;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
		{
			iAlive++;
		}
	}
	
	return iAlive;
}

/**
 * @brief Gets index of the random human.
 *
 * @return                  The index of random human.
 **/
stock int fnGetRandomHuman()
{
	int iTotal; static int client[MAXPLAYERS+1];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && !gClientData[i].Zombie)
		{
			client[iTotal++] = i;
		}
	}

	return (iTotal) ? client[GetRandomInt(0, iTotal-1)] : -1;
}

/**
 * @brief Gets index of the random zombie.
 *
 * @return                  The index of random zombie.
 **/
stock int fnGetRandomZombie()
{
	int iTotal; static int client[MAXPLAYERS+1];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && gClientData[i].Zombie)
		{
			client[iTotal++] = i;
		}
	}

	return (iTotal) ? client[GetRandomInt(0, iTotal-1)] : -1;
}

/**
 * @brief Returns an offset value from a given config.
 *
 * @param gameConf          The game config handle.
 * @param iOffset           An offset, or -1 on failure.
 * @param sKey              Key to retrieve from the offset section.
 **/
stock void fnInitGameConfOffset(GameData gameConf, int &iOffset, const char[] sKey, bool bFatal = true)
{
	if ((iOffset = gameConf.GetOffset(sKey)) == -1)
	{
		LogEvent(false, bFatal ? LogType_Fatal : LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get offset: \"%s\"", sKey);
	}
}

/**
 * @brief Returns an address value from a given config.
 *
 * @param gameConf          The game config handle.
 * @param pAddress          An address, or null on failure.
 * @param sKey              Key to retrieve from the address section.
 * @param bFatal            (Optional) If true, invalid values will stop the plugin with the specified message.
 **/
stock void fnInitGameConfAddress(GameData gameConf, Address &pAddress, const char[] sKey, bool bFatal = true)
{
	if ((pAddress = gameConf.GetAddress(sKey)) == Address_Null)
	{
		LogEvent(false, bFatal ? LogType_Fatal : LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get address: \"%s\"", sKey);
	}
}

/**
 * @brief Returns the value of a key from a given config.
 *
 * @param gameConf          The game config handle.
 * @param sKey              Key to retrieve from the key section.
 * @param sIdentifier       The string to return identifier in.
 * @param iMaxLen           The lenght of string.
 * @param bFatal            (Optional) If true, invalid values will stop the plugin with the specified message.
 **/
stock void fnInitGameConfKey(GameData gameConf, const char[] sKey, char[] sIdentifier, int iMaxLen, bool bFatal = true)
{
	if (!gameConf.GetKeyValue(sKey, sIdentifier, iMaxLen)) 
	{
		LogEvent(false, bFatal ? LogType_Fatal : LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get key: \"%s\"", sKey);
	}
}

/**
 * @brief Given an entity classname, finds a networkable send property offset.
 *
 * @param iOffset           An offset, or -1 on failure.
 * @param sClass            The entity classname.
 * @param sProp             The property name.
 * @param bFatal            (Optional) If true, invalid values will stop the plugin with the specified message.
 **/
stock void fnInitSendPropOffset(int &iOffset, const char[] sClass, const char[] sProp, bool bFatal = true)
{
	if ((iOffset = FindSendPropInfo(sClass, sProp)) < 1)
	{
		LogEvent(false, bFatal ? LogType_Fatal : LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to find send prop: \"%s\"", sProp);
	}
}

/**
 * @brief Given an entity index, finds a networkable data property offset.
 *
 * @param iOffset           An offset, or -1 on failure.
 * @param entity            The entity index.
 * @param sProp             The property name.
 * @param bFatal            (Optional) If true, invalid values will stop the plugin with the specified message.
 **/
stock void fnInitDataPropOffset(int &iOffset, int entity, const char[] sProp, bool bFatal = true)
{
	if ((iOffset = FindDataMapInfo(entity, sProp)) < 1)
	{
		LogEvent(false, bFatal ? LogType_Fatal : LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to find data prop: \"%s\"", sProp);
	}
}

/*
 * Stocks utils API.
 */

/**
 * @brief Removes a hook for when a game event is fired. (Avoid errors)
 *
 * @param sName             The name of the event.
 * @param hCallBack         An EventHook function pointer.
 * @param eMode             (Optional) EventHookMode determining the type of hook.
 * @error                   No errors.
 **/
stock void UnhookEvent2(const char[] sName, EventHook hCallBack, EventHookMode eMode = EventHookMode_Post)
{
	HookEvent(sName, hCallBack, eMode);
	UnhookEvent(sName, hCallBack, eMode);
}

/**
 * @brief Removes a previously added command listener, in reverse order of being added.
 *
 * @param hCallBack         The callback.
 * @param sCommand          The command, or if not specified, a global listener.
 *                          The command is case insensitive.
 * @error                   No errors..
 **/
stock void RemoveCommandListener2(CommandListener hCallBack, const char[] sCommand = "")
{
	AddCommandListener(hCallBack, sCommand);
	RemoveCommandListener(hCallBack, sCommand);
}

/**
 * @brief Removes a hook for when a console variable's value is changed.
 *
 * @param hConVar           The handle to the convar.
 * @param hCallBack         An OnConVarChanged function pointer.
 * @error                   No errors..
 **/
stock void UnhookConVarChange2(ConVar hConVar, ConVarChanged hCallBack)
{
	HookConVarChange(hConVar, hCallBack);
	UnhookConVarChange(hConVar, hCallBack);
}

/**
 * @brief Adds a callback that will fire when a command is sent to the server.
 *        If command was hooked before, it will remove previous listener.
 *
 * @param hConVar           The handle to the convar.
 * @param hCallBack         The callback.            
 **/
stock void CreateCommandListener(ConVar hConvar, CommandListener hCallBack)
{
	static char sName[SMALL_LINE_LENGTH];
	hConvar.GetName(sName, sizeof(sName));
	
	static char sCommand[SMALL_LINE_LENGTH];
	bool bListened = gServerData.Listeners.GetString(sName, sCommand, sizeof(sCommand));
	
	if (bListened)
	{
		RemoveCommandListener(hCallBack, sCommand);
		
		gServerData.Listeners.Remove(sName);
	}
	
	hConvar.GetString(sCommand, sizeof(sCommand));

	if (hasLength(sCommand))
	{
		AddCommandListener(hCallBack, sCommand);

		gServerData.Listeners.SetString(sName, sCommand);
	}
}