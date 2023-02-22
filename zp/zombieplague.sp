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
 * @section Engine versions.
 **/
#define ENGINE_UNKNOWN              "could not determine the engine version"    
#define ENGINE_ORIGINAL             "Original Source Engine"         
#define ENGINE_SOURCESDK2006        "Episode 1 Source Engine"         
#define ENGINE_SOURCESDK2007        "Orange Box Source Engine"        
#define ENGINE_LEFT4DEAD            "Left 4 Dead"   
#define ENGINE_DARKMESSIAH          "Dark Messiah Multiplayer"
#define ENGINE_LEFT4DEAD2           "Left 4 Dead 2"
#define ENGINE_ALIENSWARM           "Alien Swarm"
#define ENGINE_BLOODYGOODTIME       "Bloody Good Time"
#define ENGINE_EYE                  "E.Y.E Divine Cybermancy"
#define ENGINE_PORTAL2              "Portal 2"
#define ENGINE_CSGO                 "Counter-Strike: Global Offensive"
#define ENGINE_CSS                  "Counter-Strike: Source"
#define ENGINE_DOTA                 "Dota 2"
#define ENGINE_HL2DM                "Half-Life 2 Deathmatch"
#define ENGINE_DODS                 "Day of Defeat: Source"
#define ENGINE_TF2                  "Team Fortress 2"
#define ENGINE_NUCLEARDAWN          "Nuclear Dawn"
#define ENGINE_SDK2013              "Source SDK 2013"
#define ENGINE_BLADE                "Blade Symphony"
#define ENGINE_INSURGENCY           "Insurgency"
#define ENGINE_CONTAGION            "Contagion"
/**
 * @endsection
 **/

/**
 * @brief Called once when server is started. Will log a warning if a unsupported game is detected.
 **/
void GameEngineOnInit()
{
	switch (GetEngineVersion())
	{
		case Engine_Unknown :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague %s", ENGINE_UNKNOWN);
		}
		case Engine_Original :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_ORIGINAL);
		}
		case Engine_SourceSDK2006 :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_SOURCESDK2006);
		}
		case Engine_SourceSDK2007 :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_SOURCESDK2007);
		}
		case Engine_Left4Dead :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_LEFT4DEAD);
		}
		case Engine_DarkMessiah :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_DARKMESSIAH);
		}
		case Engine_Left4Dead2 :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_LEFT4DEAD2);
		}
		case Engine_AlienSwarm :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_ALIENSWARM);
		}
		case Engine_BloodyGoodTime :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_BLOODYGOODTIME);
		}
		case Engine_EYE :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_EYE);
		}
		case Engine_Portal2 :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_PORTAL2);
		}
		case Engine_CSGO :    
		{
			LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Engine catched: \"%s\"", ENGINE_CSGO);
		}
		case Engine_CSS :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_CSS);
		}
		case Engine_DOTA :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_DOTA);
		}
		case Engine_HL2DM :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_HL2DM);
		}
		case Engine_DODS :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_DODS);
		}
		case Engine_TF2 :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_TF2);
		}
		case Engine_NuclearDawn :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_NUCLEARDAWN);
		}
		case Engine_SDK2013 :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_SDK2013);
		}
		case Engine_Blade :    
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_BLADE);
		}
		case Engine_Insurgency :
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_INSURGENCY);
		}
		case Engine_Contagion :
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "Engine Validation", "Zombie Plague doesn't support: \"%s\"", ENGINE_CONTAGION);
		}
	}
	
	fnInitGameConfOffset(gServerData.Config, view_as<int>(gServerData.Platform), "OS");
	gServerData.Engine = fnCreateEngineInterface(gServerData.Config, "EngineInterface");

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
 * @brief Core module unload function.
 **/
void GameEngineOnUnload()
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
	int iRandom; static int client[MAXPLAYERS+1];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && !gClientData[i].Zombie)
		{
			client[iRandom++] = i;
		}
	}

	return (iRandom) ? client[GetRandomInt(0, iRandom-1)] : -1;
}

/**
 * @brief Gets index of the random zombie.
 *
 * @return                  The index of random zombie.
 **/
stock int fnGetRandomZombie()
{
	int iRandom; static int client[MAXPLAYERS+1];

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i) && gClientData[i].Zombie)
		{
			client[iRandom++] = i;
		}
	}

	return (iRandom) ? client[GetRandomInt(0, iRandom-1)] : -1;
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

/**
 * @brief This is the primary exported function by a dll, referenced by name via dynamic binding
 *        that exposes an opqaue function pointer to the interface.
 *
 * @param gameConf          The game config handle.
 * @param sKey              Key to retrieve from the key section.
 * @param pAddress          (Optional) The optional interface address.
 **/
stock Address fnCreateEngineInterface(GameData gameConf, const char[] sKey, Address pAddress = Address_Null) 
{
	static Handle hInterface = null;
	if (hInterface == null) 
	{
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CreateInterface");

		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		if ((hInterface = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to load SDK call \"CreateInterface\". Update signature in \"%s\"", PLUGIN_CONFIG);
			return Address_Null;
		}
	}

	static char sInterface[NORMAL_LINE_LENGTH];
	fnInitGameConfKey(gameConf, sKey, sInterface, sizeof(sInterface));

	Address pInterface = SDKCall(hInterface, sInterface, pAddress);
	if (pInterface == Address_Null) 
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get pointer to interface %s(\"%s\")", sKey, sInterface);
		return Address_Null;
	}

	return pInterface;
}

/**
 * @brief Create a memory for the custom convention call.
 *
 * @return                  The zero memory address.
 **/
stock Address fnCreateMemoryForSDKCall()
{
	static Address pZeroMemory = Address_Null;
	if (pZeroMemory != Address_Null)
	{
		return pZeroMemory;
	}
   
	Address pServerBase; 
	fnInitGameConfAddress(gServerData.Config, pServerBase, "server");
	int pAddress = view_as<int>(pServerBase) + fnGetModuleSize(pServerBase) - 1;
   
	for (;;)
	{
		int iByte = LoadFromAddress(view_as<Address>(pAddress), NumberType_Int8);
		if (iByte != 0x00)
		{
			break;
		}
	   
		pAddress--;
	}
   
	/* Align for safe code injection */
	pZeroMemory = view_as<Address>(pAddress + 0x100 & 0xFFFFFF00); /// 255 bytes
	return pZeroMemory;
}

/**
 * @brief Gets the size of a module in the memory.
 *
 * @param pAddress          The module address.
 * @return                  The size value.
 **/
stock int fnGetModuleSize(Address pAddress)
{
	int iOffset = LoadFromAddress(pAddress + view_as<Address>(0x3C), NumberType_Int32);    /// NT headers offset
	return LoadFromAddress(pAddress + view_as<Address>(iOffset + 0x50), NumberType_Int32); /// nt->OptionalHeader.SizeOfImage
}

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