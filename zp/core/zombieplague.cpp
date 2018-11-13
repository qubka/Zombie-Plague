/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          zombieplague.cpp
 *  Type:          Main 
 *  Description:   General plugin functions and defines.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

// Regex library
#include <regex>
 
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
 * List of operation systems.
 **/
enum EngineOS
{
    OS_Unknown,
    OS_Windows,
    OS_Linux,
    OS_Mac
};
 
/*
 * Engine functions
 */
 
/**
 * Called once when server is started. Will log a warning if a unsupported game is detected.
 **/
void GameEngineInit(/*void*/)
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

    // Unload the gamedata configs
    ConfigUnload(/*void*/);
}

/**
 * Called when core is loaded.
 **/
void GameEngineLoad(/*void*/)
{
    // Call forward
    API_OnEngineExecute();
}

/**
 * Gets the server operating system.
 *
 * @param oS                The platform id.
 *
 * @return                  True or false.
 **/
bool GameEnginePlatform(EngineOS oS)
{
    // Validate platform
    if(gServerData[Server_PlatForm] == OS_Unknown)
    {
        // Initialize variable
        char sBuffer[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH];
        
        // Extract status string
        ServerCommandEx(sBuffer, sizeof(sBuffer), "status");

        // Validate length
        if(strlen(sBuffer))
        {
            // Precompile a regular expression
            Regex hRegex = CompileRegex("(os\\s+:\\s+\\w+)"); 
            
            // i = str index
            int iCount = hRegex.Match(sBuffer); 
            for(int i = 0; i < iCount; i++) 
            { 
                // Returns a matched substring from a regex handle
                hRegex.GetSubString(i, sBuffer, sizeof(sBuffer)); 
                
                // Finds the first occurrence of a character in a string
                int iSystem = FindCharInString(sBuffer, ' ', true) + 1;

                // Validate operating system
                gServerData[Server_PlatForm] = !strncmp(sBuffer[iSystem], "win", 3, false) ? OS_Windows : !strncmp(sBuffer[iSystem], "lin", 3, false) ? OS_Linux : OS_Mac;
                break;
            }
            
            // Decompile expression
            delete hRegex;
        }
    }
    
    // Return on success
    return (gServerData[Server_PlatForm] == oS);
}

/*
 * Player functions
 */

/**
 * Returns true if the player is connected and alive, false if not.
 *
 * @param clientIndex       The client index.
 * @param clientAlive       (Optional) Set to true to validate that the client is alive, false to ignore.
 *
 * @return                  True or false.
 **/
stock bool IsPlayerExist(const int clientIndex, const bool clientAlive = true)
{
    // If client isn't valid, then stop
    if(clientIndex <= 0 || clientIndex > MaxClients)
    {
        return false;
    }

    // If client isn't connected, then stop
    if(!IsClientConnected(clientIndex))
    {
        return false;
    }

    // If client isn't in game, then stop
    if(!IsClientInGame(clientIndex) || IsClientInKickQueue(clientIndex)) //! Improved, thanks to fl0wer!
    {
        return false;
    }

    // If client is in GoTV, then stop
    if(IsClientSourceTV(clientIndex))
    {
        return false;
    } 

    // If client isn't alive, then stop
    if(clientAlive && !IsPlayerAlive(clientIndex))
    {
        return false;
    }

    // If client exist
    return true;
}

/**
 * Returns whether a player is in a spesific group or not.
 *
 * @param clientIndex       The client index.
 * @param sGroup            The SourceMod group name to check.
 *
 * @return                  True or false.
 **/
stock bool IsPlayerInGroup(const int clientIndex, const char[] sGroup)
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return false;
    }

    /*********************************
     *                               *
     *   FLAG GROUP AUTHENTICATION   *
     *                               *
     *********************************/

    // Finds a group by name
    GroupId nGroup = FindAdmGroup(sGroup);
    
    // Validate group
    if(nGroup == INVALID_GROUP_ID)
    {
        return false;
    }
     
    // Retrieves a client AdminId
    AdminId iD = GetUserAdmin(clientIndex);
    
    // Validate id
    if(iD == INVALID_ADMIN_ID)
    {
        return false;
    }

    // Initialize variables
    static char sGroupName[NORMAL_LINE_LENGTH];

    // Gets immunity level
    int iImmunity = GetAdmGroupImmunityLevel(nGroup);
    
    // i = group index
    int iSize = GetAdminGroupCount(iD);
    for(int i = 0; i < iSize; i++)
    {
        // Gets group name
        nGroup = GetAdminGroup(iD, i, sGroupName, sizeof(sGroupName));

        // If names match, then return index
        if(!strcmp(sGroup, sGroupName, false) || iImmunity <= GetAdmGroupImmunityLevel(nGroup))
        {
            return true;
        }
    }
    
    // No groups or no match
    return false;
}

/*
 * Server functions
 */
 
/**
 * Gets amount of total humans.
 * 
 * @return                  The amount of total humans.
 **/
stock int fnGetHumans(/*void*/)
{
    // Initialize variables
    int nHumans;
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate human
        if(IsPlayerExist(i) && !gClientData[i][Client_Zombie])
        {
            // Increment amount
            nHumans++;
        }
    }
    
    // Return amount
    return nHumans;
}

/**
 * Gets amount of total zombies.
 *
 * @return                  The amount of total zombies.
 **/
stock int fnGetZombies(/*void*/)
{
    // Initialize variables
    int nZombies;
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate zombie
        if(IsPlayerExist(i) && gClientData[i][Client_Zombie])
        {
            // Increment amount    
            nZombies++;
        }
    }
    
    // Return amount
    return nZombies;
}

/**
 * Gets amount of total alive players.
 *
 * @return                  The amount of total alive players.
 **/
stock int fnGetAlive(/*void*/)
{
    // Initialize variables
    int nAlive;

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i))
        {
            // Increment amount
            nAlive++;
        }
    }
    
    // Return amount
    return nAlive;
}

/**
 * Gets index of the random human.
 *
 * @return                  The index of random human.
 **/
stock int fnGetRandomHuman(/*void*/)
{
    // Initialize variables
    int nRandom; static int clientIndex[MAXPLAYERS+1];

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate human
        if(IsPlayerExist(i) && !gClientData[i][Client_Zombie] && !gClientData[i][Client_Survivor])
        {
            // Increment amount
            clientIndex[nRandom++] = i;
        }
    }

    // Return amount
    return (nRandom) ? clientIndex[GetRandomInt(0, nRandom-1)] : -1;
}

/**
 * Gets index of the random zombie.
 *
 * @return      The index of random zombie.
 **/
stock int fnGetRandomZombie(/*void*/)
{
    // Initialize variables
    int nRandom; static int clientIndex[MAXPLAYERS+1];

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate zombie
        if(IsPlayerExist(i) && gClientData[i][Client_Zombie] && !gClientData[i][Client_Nemesis])
        {
            // Increment amount
            clientIndex[nRandom++] = i;
        }
    }

    // Return amount
    return (nRandom) ? clientIndex[GetRandomInt(0, nRandom-1)] : -1;
}

/**
 * Gets index of the random survivor.
 *
 * @return                  The index of random survivor.
 **/
stock int fnGetRandomSurvivor(/*void*/)
{
    // Initialize variables
    int nRandom; static int clientIndex[MAXPLAYERS+1];

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate survivor
        if(IsPlayerExist(i) && gClientData[i][Client_Survivor])
        {
            // Increment amount
            clientIndex[nRandom++] = i;
        }
    }

    // Return amount
    return (nRandom) ? clientIndex[GetRandomInt(0, nRandom-1)] : -1;
}

/**
 * Gets index of the random nemesis.
 *
 * @return                  The index of random nemesis.
 **/
stock int fnGetRandomNemesis(/*void*/)
{
    // Initialize variables
    int nRandom; static int clientIndex[MAXPLAYERS+1];

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate nemesis
        if(IsPlayerExist(i) && gClientData[i][Client_Nemesis])
        {
            // Increment amount
            clientIndex[nRandom++] = i;
        }
    }

    // Return amount
    return (nRandom) ? clientIndex[GetRandomInt(0, nRandom-1)] : -1;
}

/**
 * Gets amount of total playing players.
 *
 * @return                  The amount of total playing players.
 **/
stock int fnGetPlaying(/*void*/)
{
    // Initialize variables
    int nPlaying;

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i, false))
        {
            // Increment amount
            nPlaying++;
        }
    }
    
    // Return amount
    return nPlaying;
}

/**
 * Returns an offset value from a given config.
 *
 * @param gameConf          The game config handle.
 * @param iOffset           An offset, or -1 on failure. (Destanation)
 * @param sKey              Key to retrieve from the offset section.
 **/
stock void fnInitGameConfOffset(Handle gameConf, int &iOffset, const char[] sKey)
{
    // Validate offset
    if((iOffset = GameConfGetOffset(gameConf, sKey)) == -1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get offset: \"%s\"", sKey);
    }
}

/**
 * Given a server classname, finds a networkable send property offset.
 *
 * @param iOffset           An offset, or -1 on failure. (Destanation) 
 * @param sServerClass      The classname.
 * @param sProp             The property name.
 **/
stock void fnInitSendPropOffset(int &iOffset, const char[] sServerClass, const char[] sProp)
{
    // Validate prop
    if((iOffset = FindSendPropInfo(sServerClass, sProp)) < 1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to find prop: \"%s\"", sProp);
    }
}

/**
 * Searches for the index of a given string in a dispatch table.
 *
 * @param sEffect           The effect name.
 * @return                  The item index.
 **/
stock int fnGetEffectIndex(const char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("EffectDispatch");
    }

    // Searches for the index of a given string in a string table
    int itemIndex = FindStringIndex(tableIndex, sEffect);

    // Validate item
    if(itemIndex != INVALID_STRING_INDEX)
    {
        return itemIndex;
    }

    // Return on the unsuccess
    return 0;
}

/**
 * Searches for the index of a given string in an effect table.
 *
 * @param sEffect           The effect name.
 * @return                  The item index.
 **/
stock int fnGetParticleEffectIndex(const char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }

    // Searches for the index of a given string in a string table
    int itemIndex = FindStringIndex(tableIndex, sEffect);

    // Validate item
    if(itemIndex != INVALID_STRING_INDEX)
    {
        return itemIndex;
    }

    // Return on the unsuccess
    return 0;
}

/**
 * Precache the particle in the effect table.
 *
 * @param sEffect           The effect name.
 **/
stock void fnPrecacheParticleEffect(const char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }

    // If particle doesn't precache yet, then continue
    ///if(FindStringIndex(tableIndex, sEffect) == INVALID_STRING_INDEX)

    // Precache particle
    bool bSave = LockStringTables(false);
    AddToStringTable(tableIndex, sEffect);
    LockStringTables(bSave);
}

/**
 * Precache the sound in the sounds table.
 *
 * @param sPath             The sound path.
 * @return                  True if was precached, false otherwise.
 **/
stock bool fnPrecacheSoundQuirk(const char[] sPath)
{
    // Extract value string
    static char sSound[PLATFORM_MAX_PATH];
    StrExtract(sSound, sPath, 0, PLATFORM_MAX_PATH);

    /// Look here: https://wiki.alliedmods.net/Csgo_quirks#Fake_precaching_and_EmitSound
    if(ReplaceStringEx(sSound, sizeof(sSound), "sound", "*", 5, 1, true) != -1)
    {
        // Initialize the table index
        static int tableIndex = INVALID_STRING_TABLE;

        // Validate table
        if(tableIndex == INVALID_STRING_TABLE)
        {
            // Searches for a string table
            tableIndex = FindStringTable("soundprecache");
        }

        // If sound doesn't precache yet, then continue
        if(FindStringIndex(tableIndex, sSound) == INVALID_STRING_INDEX)
        {
            // Add file to download table
            AddFileToDownloadsTable(sPath);

            // Precache sound
            ///bool bSave = LockStringTables(false);
            AddToStringTable(tableIndex, sSound);
            ///LockStringTables(bSave);
        }
    }
    else
    {
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "Config Validation", "Wrong sound path: %s", sPath);
        return false;
    }
    
    // Return on the success
    return true;
}
