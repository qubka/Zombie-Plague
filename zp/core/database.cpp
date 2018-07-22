/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          database.cpp
 *  Type:          Main 
 *  Description:   MySQL/SQlite database storage.
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

/**
 * Steam ID length.
 **/
#define STEAMID_MAX_LENGTH     32
 
/**
 * Array handle to store database.
 **/
Handle hDataBase = INVALID_HANDLE;

/**
 * Arrays for storing ID in the SQL base.
 **/
char SteamID[MAXPLAYERS+1][STEAMID_MAX_LENGTH];

/**
 * Create a SQL database connection.
 **/
void DataBaseLoad(/*void*/)
{
    // Close database handle, if it was already created
    if(hDataBase != INVALID_HANDLE)
    {
        delete hDataBase;
    }

    // Gets database file path
    static char sDataBase[SMALL_LINE_LENGTH];
    gCvarList[CVAR_CONFIG_PATH_DATABASE].GetString(sDataBase, sizeof(sDataBase));

    // If file doesn't exist, then log and stop
    if(!SQL_CheckConfig(sDataBase))
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Missing database section: \"%s\" in \"databases.cfg\"", sDataBase);
    }

    // Initialize chars
    static char sError[BIG_LINE_LENGTH];
    static char sDriver[SMALL_LINE_LENGTH]; 
    static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH];

    // Creates an SQL connection from a named configuration
    hDataBase = SQL_Connect(sDataBase , false, sError, sizeof(sError));

    // If can't make connection, then log and stop
    if(hDataBase == INVALID_HANDLE)
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "\"%s\"", sError);
    }

    // Log what database that is loaded
    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Loading database from section \"%s\"", sDataBase);

    // Reads the driver of an opened database
    SQL_ReadDriver(hDataBase, sDriver, sizeof(sDriver)); 

    // If driver is a MySQL
    bool MySQL = !strcmp(sDriver, "mysql", false);

    // Block sql base from the other requests
    SQL_LockDatabase(hDataBase);

    // Gets database name
    gCvarList[CVAR_CONFIG_NAME_DATABASE].GetString(sDataBase, sizeof(sDataBase));

    // Delete existing database if dropping enable
    if(!gCvarList[CVAR_GAME_CUSTOM_DATABASE].BoolValue)
    {
        // Format request
        Format(sRequest, sizeof(sRequest), "DROP TABLE IF EXISTS `%s`", sDataBase);

        // Sent a request
        if(!SQL_FastQuery(hDataBase, sRequest))
        {
            // Gets an error, if it exist
            SQL_GetError(hDataBase, sError, sizeof(sError));

            // Unexpected error, stop plugin
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "\"%s\" in request: \"%s\"", sError, sRequest);
        }
        else
        {
            // Log database validation info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Dropped database: `%s` | Request : \"%s\"", sRequest);
        }
    }

    // Format request
    if(MySQL)
    {
        Format(sRequest, sizeof(sRequest), "CREATE TABLE IF NOT EXISTS `%s` (`id` int(64) NOT NULL auto_increment, `steam_id` varchar(32) NOT NULL, `money` int(64) NOT NULL, `level` int(64) NOT NULL, `exp` int(64) NOT NULL, `zclass` int(64) NOT NULL, `hclass` int(64) NOT NULL, `rebuy` int(64) NOT NULL, `costume` int(64) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `steam_id` (`steam_id`))", sDataBase);
    }
    else
    {
        Format(sRequest, sizeof(sRequest), "CREATE TABLE IF NOT EXISTS `%s` (id INTEGER PRIMARY KEY AUTOINCREMENT, steam_id TEXT UNIQUE, money INTEGER, level INTEGER, exp INTEGER, zclass INTEGER, hclass INTEGER, rebuy INTEGER, costume INTEGER)", sDataBase);
    }

    // Sent a request
    if(!SQL_FastQuery(hDataBase, sRequest))
    {
        // Gets an error, if it exist
        SQL_GetError(hDataBase, sError, sizeof(sError));

        // Unexpected error, stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "\"%s\" in request: \"%s\"", sError, sRequest);
    }
    else
    {
        // Log database validation info
        LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Executed database: `%s` | Connection type: \"%s\" | Request : \"%s\"", sDataBase, MySQL ? "MySQL" : "SQlite", sRequest);
    }

    // Unlock base
    SQL_UnlockDatabase(hDataBase);
}

/**
 * Hook commands for database core. Called when commands are created.
 **/
void DataBaseOnCommandsCreate(/*void*/)
{
    // Hook commands
    AddCommandListener(DataBaseHook, "exit");
    AddCommandListener(DataBaseHook, "quit");
    AddCommandListener(DataBaseHook, "restart");
    AddCommandListener(DataBaseHook, "_restart");
}

/**
 * Callback for command listeners. This is invoked whenever any command reaches the server, from the server console itself or a player.
 * 
 * Clients may be in the process of connecting when they are executing commands IsClientConnected(clientIndex is not guaranteed to return true. Other functions such as GetClientIP() may not work at this point either.
 * 
 * Returning Plugin_Handled or Plugin_Stop will prevent the original, baseline code from running.
 * -- TEXT BELOW IS IMPLEMENTATION, AND NOT GUARANTEED -- Even if returning Plugin_Handled or Plugin_Stop, some callbacks will still trigger. These are: * C++ command dispatch hooks from Metamod:Source plugins * Reg*Cmd() hooks that did not create new commands.
 *
 * @param entityIndex       The entity index. (Client, or 0 for server)
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action DataBaseHook(int entityIndex, const char[] commandMsg, int iArguments)
{
    // Validate Server
    if(!entityIndex)
    {
        // Switches server commands
        switch(commandMsg[0])
        {
            // Exit
            case 'e', 'q', 'r', '_' : 
            {
                //!! IMPORTANT BUG FIX !!//
                DataBaseUnload();
            }
        }
    }

    // Allow commands
    return Plugin_Continue;
}

/**
 * Purge a SQL database connection.
 **/
void DataBaseUnload(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Client is leave the server on the restart
        DataBaseOnClientDisconnect(i);
    }
}

/**
 * Client is joining the server.
 * 
 * @param clientIndex        The client index. 
 **/
void DataBaseClientInit(int clientIndex)
{
    // Resets client variables
    gClientData[clientIndex][Client_DataID] = -1;
    gClientData[clientIndex][Client_Loaded] = false;
    
    // If database doesn't exist, then stop
    if(hDataBase == INVALID_HANDLE)
    {
        return;
    }
    
    // Verify that the client is a real player
    if(!IsFakeClient(clientIndex))
    {
        // Initialize chars
        static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH]; 

        // Gets database name
        static char sDataBase[SMALL_LINE_LENGTH];
        gCvarList[CVAR_CONFIG_NAME_DATABASE].GetString(sDataBase, sizeof(sDataBase));
        
        // Validate client authentication string (SteamID)
        if(GetClientAuthId(clientIndex, AuthId_Steam2, SteamID[clientIndex], sizeof(SteamID[])))
        {
            // Format request
            Format(sRequest, sizeof(sRequest), "SELECT id, money, level, exp, zclass, hclass, rebuy, costume FROM `%s` WHERE steam_id = '%s'", sDataBase, SteamID[clientIndex]);
            
            // Sent a request
            SQL_TQuery(hDataBase, SQLBaseExtract_Callback, sRequest, clientIndex);
            
            // Log database updation info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Updation", "Player \"%N\" was connected. \"%s\"", clientIndex, sRequest);
        }
    }
}

/**
 * Client is leave the server.
 *
 * @param clientIndex        The client index.
 **/
void DataBaseOnClientDisconnect(int clientIndex)
{
    // If client was load, then save
    if(gClientData[clientIndex][Client_Loaded])
    {
        // Update info in the database
        DataBaseSaveClientInfo(clientIndex);
        
        // Resets client variables
        gClientData[clientIndex][Client_DataID] = -1;
        gClientData[clientIndex][Client_Loaded] = false;
    }
}


/**
 * General callback for threaded SQL stuff
 *
 * @param hDriver            Parent object of the handle.
 * @param hResult            Handle to the child object.
 * @param sSQLerror          Error string if there was an error.
 * @param clientIndex        Data passed in via the original threaded invocation.
 **/
public void SQLBaseExtract_Callback(Handle hDriver, Handle hResult, const char[] sSQLerror, int clientIndex)
{
    // Make sure the client didn't disconnect while the thread was running
    if(IsPlayerExist(clientIndex, false))
    {
        // If invalid query handle
        if(hResult == INVALID_HANDLE)
        {
            // Unexpected error, log it
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Database Query", "%s", sSQLerror);
        }
        else
        {
            // Client was found, get ammopacks from the table
            if(SQL_FetchRow(hResult))
            {
                // Gets client data
                gClientData[clientIndex][Client_DataID] = SQL_FetchInt(hResult, 0); 
                AccountSetClientCash(clientIndex, SQL_FetchInt(hResult, 1));
                LevelSystemOnSetLvl(clientIndex, SQL_FetchInt(hResult, 2));
                LevelSystemOnSetExp(clientIndex, SQL_FetchInt(hResult, 3));              
                gClientData[clientIndex][Client_ZombieClassNext] = SQL_FetchInt(hResult, 4);
                gClientData[clientIndex][Client_HumanClassNext] = SQL_FetchInt(hResult, 5);
                gClientData[clientIndex][Client_AutoRebuy] = view_as<bool>(SQL_FetchInt(hResult, 6));
                gClientData[clientIndex][Client_Costume] = SQL_FetchInt(hResult, 7);

                // Update info in the database
                DataBaseSaveClientInfo(clientIndex);
            }
            else
            {
                // Initialize chars
                static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH]; 

                // Gets database name
                static char sDataBase[SMALL_LINE_LENGTH];
                gCvarList[CVAR_CONFIG_NAME_DATABASE].GetString(sDataBase, sizeof(sDataBase));

                // Format request
                Format(sRequest, sizeof(sRequest), "INSERT INTO `%s` (steam_id) VALUES ('%s')", sDataBase, SteamID[clientIndex]);
                
                // Block sql base from the other requests
                SQL_LockDatabase(hDataBase);
                
                // Sent a request
                if(!SQL_FastQuery(hDataBase, sRequest))
                {
                    // Initialize char
                    static char sError[BIG_LINE_LENGTH];
                
                    // Gets an error, if it exist
                    SQL_GetError(hDataBase, sError, sizeof(sError));
                    
                    // Unexpected error, log it
                    LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Database Query", "\"%s\" in request: \"%s\"", sError, sRequest);
                }
                else
                {
                    // Log database updation info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Updation", "Player \"%N\" was catched. \"%s\"", clientIndex, sRequest);
                }

                // Unlock base
                SQL_UnlockDatabase(hDataBase);

                // Sets client data
                AccountSetClientCash(clientIndex, gCvarList[CVAR_BONUS_CONNECT].IntValue);
            }
            
            // Client was loaded
            gClientData[clientIndex][Client_Loaded] = true;
        }
    }
}

/**
 * Called for inserting amount of ammopacks in the SQL base.
 *
 * @param clientIndex            The client index.
 **/
void DataBaseSaveClientInfo(int clientIndex)
{
    // Initialize chars
    static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH]; 

    // Gets database name
    static char sDataBase[SMALL_LINE_LENGTH];
    gCvarList[CVAR_CONFIG_NAME_DATABASE].GetString(sDataBase, sizeof(sDataBase));

    // Format request
    if(gClientData[clientIndex][Client_DataID] < 1)
    {
        Format(sRequest, sizeof(sRequest), "UPDATE `%s` SET money = %d, level = %d, exp = %d, zclass = %d, hclass = %d, rebuy = %d, costume = %d WHERE steam_id = '%s'", sDataBase, gClientData[clientIndex][Client_AmmoPacks], gClientData[clientIndex][Client_Level], gClientData[clientIndex][Client_Exp], gClientData[clientIndex][Client_ZombieClassNext], gClientData[clientIndex][Client_HumanClassNext], gClientData[clientIndex][Client_AutoRebuy], gClientData[clientIndex][Client_Costume], SteamID[clientIndex]);
    }
    else
    {
        Format(sRequest, sizeof(sRequest), "UPDATE `%s` SET money = %d, level = %d, exp = %d, zclass = %d, hclass = %d, rebuy = %d, costume = %d WHERE id = %d", sDataBase, gClientData[clientIndex][Client_AmmoPacks], gClientData[clientIndex][Client_Level], gClientData[clientIndex][Client_Exp], gClientData[clientIndex][Client_ZombieClassNext], gClientData[clientIndex][Client_HumanClassNext], gClientData[clientIndex][Client_AutoRebuy], gClientData[clientIndex][Client_Costume], gClientData[clientIndex][Client_DataID]);
    }

    // Block sql base from the other requests
    SQL_LockDatabase(hDataBase);
    
    // Sent a request
    if(!SQL_FastQuery(hDataBase, sRequest))
    {
        // Initialize char
        static char sError[BIG_LINE_LENGTH];
    
        // Gets an error, if it exist
        SQL_GetError(hDataBase, sError, sizeof(sError));
        
        // Unexpected error, log it
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Database Query", "\"%s\" in request: \"%s\"", sError, sRequest);
    }
    else
    {
        // Log database updation info
        LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Updation", "Player \"%N\" was stored. \"%s\"", clientIndex, sRequest);
    }
    
    // Unlock base
    SQL_UnlockDatabase(hDataBase);
}