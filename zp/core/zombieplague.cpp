/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          zombieplague.cpp
 *  Type:          Main 
 *  Description:   General plugin functions and defines.
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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
void GameEngineOnInit(/*void*/)
{
    // Gets engine of the game
    switch(GetEngineVersion(/*void*/))
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
    
    // Load other offsets
    fnInitGameConfOffset(gServerData.Config, view_as<int>(gServerData.Platform), "CServer::OS");
}

/**
 * @brief Core module load function.
 **/
void GameEngineOnLoad(/*void*/)
{
    // Call forward
    gForwardData._OnEngineExecute();
    
    // Map is load
    gServerData.MapLoaded = true;
}

/**
 * @brief Core module purge function.
 **/
void GameEngineOnPurge(/*void*/)
{
    // Clear map bool
    gServerData.MapLoaded = false;
}

/*
 * Stocks core API.
 */

/**
 * @brief Gets amount of total playing players.
 *
 * @return                  The amount of total playing players.
 **/
stock int fnGetPlaying(/*void*/)
{
    // Initialize index
    int iPlaying;

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i, false))
        {
            // Increment amount
            iPlaying++;
        }
    }
    
    // Return amount
    return iPlaying;
}
 
/**
 * @brief Gets amount of total humans.
 * 
 * @return                  The amount of total humans.
 **/
stock int fnGetHumans(/*void*/)
{
    // Initialize index
    int iHumans;
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate human
        if(IsPlayerExist(i) && !gClientData[i].Zombie)
        {
            // Increment amount
            iHumans++;
        }
    }
    
    // Return amount
    return iHumans;
}

/**
 * @brief Gets amount of total zombies.
 *
 * @return                  The amount of total zombies.
 **/
stock int fnGetZombies(/*void*/)
{
    // Initialize index
    int iZombies;
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate zombie
        if(IsPlayerExist(i) && gClientData[i].Zombie)
        {
            // Increment amount    
            iZombies++;
        }
    }
    
    // Return amount
    return iZombies;
}

/**
 * @brief Gets amount of total alive players.
 *
 * @return                  The amount of total alive players.
 **/
stock int fnGetAlive(/*void*/)
{
    // Initialize index
    int iAlive;

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i))
        {
            // Increment amount
            iAlive++;
        }
    }
    
    // Return amount
    return iAlive;
}

/**
 * @brief Gets index of the random human.
 *
 * @return                  The index of random human.
 **/
stock int fnGetRandomHuman(/*void*/)
{
    // Initialize variables
    int iRandom; static int client[MAXPLAYERS+1];

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate human
        if(IsPlayerExist(i) && !gClientData[i].Zombie)
        {
            // Increment amount
            client[iRandom++] = i;
        }
    }

    // Return index
    return (iRandom) ? client[GetRandomInt(0, iRandom-1)] : -1;
}

/**
 * @brief Gets index of the random zombie.
 *
 * @return                  The index of random zombie.
 **/
stock int fnGetRandomZombie(/*void*/)
{
    // Initialize variables
    int iRandom; static int client[MAXPLAYERS+1];

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate zombie
        if(IsPlayerExist(i) && gClientData[i].Zombie)
        {
            // Increment amount
            client[iRandom++] = i;
        }
    }

    // Return index
    return (iRandom) ? client[GetRandomInt(0, iRandom-1)] : -1;
}

/**
 * @brief Gets random array of total alive players.
 *
 * @param client            The array containing target player indexes.
 * @param target            (Optional) The target index.
 * @param bZombie           (Optional) True to state zombie, false for human on the target index.
 * @return                  The random array of total alive players.
 **/
stock void fnGetRandomAlive(int client[MAXPLAYERS+1], int target = -1, bool bZombie = false)
{
    // Initialize index
    int iAmount;

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i))
        {
            // Increment amount
            client[iAmount++] = i;
        }
    }

    // i = client index
    for(int i = iAmount - 1; i > 0; i--)
    {
        // Gets random index
        int x = GetRandomInt(0, i);

        // Simple swap
        int y = client[x];
        client[x] = client[i];
        client[i] = y;
    }
    
    // Validate target
    if(target != -1)
    {
        // i = client index
        int x = bZombie ? 0 : iAmount - 1; int y = client[x];
        for(int i = 0; i < iAmount; i++)
        {
            // Find index
            if(client[i] == target)
            {
                // Simple swap
                client[x] = target;
                client[i] = y;
                break;
            }    
        }
    }
}

/**
 * @brief Returns an offset value from a given config.
 *
 * @param gameConf          The game config handle.
 * @param iOffset           An offset, or -1 on failure.
 * @param sKey              Key to retrieve from the offset section.
 **/
stock void fnInitGameConfOffset(Handle gameConf, int &iOffset, char[] sKey)
{
    // Validate offset
    if((iOffset = GameConfGetOffset(gameConf, sKey)) == -1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get offset: \"%s\"", sKey);
    }
}

/**
 * @brief Returns an address value from a given config.
 *
 * @param gameConf          The game config handle.
 * @param pAddress          An address, or null on failure.
 * @param sKey              Key to retrieve from the address section.
 **/
stock void fnInitGameConfAddress(Handle gameConf, Address &pAddress, char[] sKey)
{
    // Validate address
    if((pAddress = GameConfGetAddress(gameConf, sKey)) == Address_Null)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get address: \"%s\"", sKey);
    }
}

/**
 * @brief Given an entity classname, finds a networkable send property offset.
 *
 * @param iOffset           An offset, or -1 on failure.
 * @param sClass            The entity classname.
 * @param sProp             The property name.
 **/
stock void fnInitSendPropOffset(int &iOffset, char[] sClass, char[] sProp)
{
    // Validate prop
    if((iOffset = FindSendPropInfo(sClass, sProp)) < 1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to find send prop: \"%s\"", sProp);
    }
}

/**
 * @brief Given an entity index, finds a networkable data property offset.
 *
 * @param iOffset           An offset, or -1 on failure.
 * @param entity            The entity index.
 * @param sProp             The property name.
 **/
stock void fnInitDataPropOffset(int &iOffset, int entity, char[] sProp)
{
    // Validate prop
    if((iOffset = FindDataMapInfo(entity, sProp)) < 1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to find data prop: \"%s\"", sProp);
    }
}

/**
 * @brief Removes a hook for when a game event is fired. (Avoid errors)
 *
 * @param sName             The name of the event.
 * @param hCallBack         An EventHook function pointer.
 * @param eMode             (Optional) EventHookMode determining the type of hook.
 * @error                   No errors.
 **/
stock void UnhookEvent2(char[] sName, EventHook hCallBack, EventHookMode eMode = EventHookMode_Post)
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
stock void RemoveCommandListener2(CommandListener hCallBack, char[] sCommand = "")
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