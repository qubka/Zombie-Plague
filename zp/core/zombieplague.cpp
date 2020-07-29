/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          zombieplague.cpp
 *  Type:          Main 
 *  Description:   General plugin functions and defines.
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
    switch (GetEngineVersion(/*void*/))
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
    gServerData.Engine = fnCreateEngineInterface(gServerData.Config, "EngineInterface");
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
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if (IsPlayerExist(i, false))
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
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate human
        if (IsPlayerExist(i) && !gClientData[i].Zombie)
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
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate zombie
        if (IsPlayerExist(i) && gClientData[i].Zombie)
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
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if (IsPlayerExist(i))
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
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate human
        if (IsPlayerExist(i) && !gClientData[i].Zombie)
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
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate zombie
        if (IsPlayerExist(i) && gClientData[i].Zombie)
        {
            // Increment amount
            client[iRandom++] = i;
        }
    }

    // Return index
    return (iRandom) ? client[GetRandomInt(0, iRandom-1)] : -1;
}

/**
 * @brief Returns an offset value from a given config.
 *
 * @param gameConf          The game config handle.
 * @param iOffset           An offset, or -1 on failure.
 * @param sKey              Key to retrieve from the offset section.
 **/
stock void fnInitGameConfOffset(GameData gameConf, int &iOffset, char[] sKey)
{
    // Validate offset
    if ((iOffset = gameConf.GetOffset(sKey)) == -1)
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
stock void fnInitGameConfAddress(GameData gameConf, Address &pAddress, char[] sKey)
{
    // Validate address
    if ((pAddress = gameConf.GetAddress(sKey)) == Address_Null)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get address: \"%s\"", sKey);
    }
}

/**
 * @brief Returns the value of a key from a given config.
 *
 * @param gameConf          The game config handle.
 * @param sKey              Key to retrieve from the key section.
 * @param sIdentifier       The string to return identifier in.
 * @param iMaxLen           The lenght of string.
 **/
stock void fnInitGameConfKey(GameData gameConf, char[] sKey, char[] sIdentifier, int iMaxLen)
{
    // Validate key
    if (!gameConf.GetKeyValue(sKey, sIdentifier, iMaxLen)) 
    {
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get key: \"%s\"", sKey);
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
    if ((iOffset = FindSendPropInfo(sClass, sProp)) < 1)
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
    if ((iOffset = FindDataMapInfo(entity, sProp)) < 1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to find data prop: \"%s\"", sProp);
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
stock Address fnCreateEngineInterface(GameData gameConf, char[] sKey, Address pAddress = Address_Null) 
{
    // Initialize intercace call
    static Handle hInterface = null;
    if (hInterface == null) 
    {
        // Starts the preparation of an SDK call
        StartPrepSDKCall(SDKCall_Static);
        PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CreateInterface");

        // Adds a parameter to the calling convention. This should be called in normal ascending order
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

        // Validate call
        if ((hInterface = EndPrepSDKCall()) == null)
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to load SDK call \"CreateInterface\". Update signature in \"%s\"", PLUGIN_CONFIG);
            return Address_Null;
        }
    }

    // Gets the value of a key from a config
    static char sInterface[NORMAL_LINE_LENGTH];
    fnInitGameConfKey(gameConf, sKey, sInterface, sizeof(sInterface));

    // Gets the address of a given interface and key
    Address pInterface = SDKCall(hInterface, sInterface, pAddress);
    if (pInterface == Address_Null) 
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get pointer to interface %s(\"%s\")", sKey, sInterface);
        return Address_Null;
    }

    // Return on the success
    return pInterface;
}

/**
 * @brief Create a memory for the custom convention call.
 *
 * @return                  The zero memory address.
 **/
stock Address fnCreateMemoryForSDKCall(/*void*/)
{
    // Validate zero memory
    static Address pZeroMemory = Address_Null;
    if (pZeroMemory != Address_Null)
    {
        return pZeroMemory;
    }
   
    // Gets the server address
    Address pServerBase; 
    fnInitGameConfAddress(gServerData.Config, pServerBase, "server");
    int pAddress = view_as<int>(pServerBase) + fnGetModuleSize(pServerBase) - 1;
   
    // Find the free memory
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
    pZeroMemory = view_as<Address>(pAddress + 0x100 & 0xFFFFFF00); // 255 bytes
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
    int iOffset = LoadFromAddress(pAddress + view_as<Address>(0x3C), NumberType_Int32);    // NT headers offset
    return LoadFromAddress(pAddress + view_as<Address>(iOffset + 0x50), NumberType_Int32); // nt->OptionalHeader.SizeOfImage
}

/**
 * @brief Copies the values of num bytes from the location pointed to by source directly to the memory block pointed to by destination.
 *
 * @param pDest        The destination address where the content is to be copied.
 * @param sSource      The source of data to be copied.
 * @param iSize        The number of bytes to copy.
 **/
stock void memcpy(Address pDest, char[] sSource, int iSize)
{
    // For more copying speed
    int i = iSize / 4;
    memcpy4b(pDest, view_as<any>(sSource), i);
   
    // Copy the rest of staff
    for (i *= 4, pDest += view_as<Address>(i); i < iSize; i++)
    {
        StoreToAddress(pDest++, sSource[i], NumberType_Int8);
    }
}

/**
 * @brief Copies the 4 bytes from the location pointed to by source directly to the memory block pointed to by destination. 
 *
 * @param pDest        The destination address where the content is to be copied.
 * @param sSource      The source of data to be copied.
 * @param iSize        The number of bytes to copy.
 **/
stock void memcpy4b(Address pDest, any[] sSource, int iSize)
{
    // Copy 4 bytes at once
    for (int i = 0; i < iSize; i++)
    {
        StoreToAddress(pDest, sSource[i], NumberType_Int32);
        pDest += view_as<Address>(4);
    }
}

/**
 * @brief Writes the DWord D (i.e. 4 bytes) to the string. 
 *
 * @param asm             The assemly string.
 * @param pAddress        The address of the call.
 * @param iOffset         (Optional) The address offset. (Where 0x0 starts)
 **/
stock void writeDWORD(char[] asm, any pAddress, int iOffset = 0)
{
    asm[iOffset]   = pAddress & 0xFF;
    asm[iOffset+1] = pAddress >> 8 & 0xFF;
    asm[iOffset+2] = pAddress >> 16 & 0xFF;
    asm[iOffset+3] = pAddress >> 24 & 0xFF;
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