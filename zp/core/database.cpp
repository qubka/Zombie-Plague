/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          database.cpp
 *  Type:          Main 
 *  Description:   MySQL/SQlite database storage.
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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * Steam ID max length.
 **/
#define STEAMID_MAX_LENGTH   32

/**
 * Money given on first connection.
 **/
#define DATABASE_CONNECTION  50

/**
 * Section, relative to root sourcemod directory, to default 'database.cfg' file.
 **/
#define DATABASE_SECTION     "zombiedatabase"

/**
 * Name of database in the section above.
 **/
#define DATABASE_NAME        "zombieplague" 

/**
 * Array handle to store database.
 **/
Handle hDataBase;

/**
 * Arrays for storing ID in the SQL base.
 **/
char SteamID[MAXPLAYERS+1][STEAMID_MAX_LENGTH];

/**
 * Database system module init function.
 **/
void DataBaseInit(/*void*/)
{
    // If database disabled, then purge
    if(!gCvarList[CVAR_GAME_CUSTOM_DATABASE].IntValue)
    {
        // If database already created, then close
        if(hDataBase != INVALID_HANDLE)
        {
            // Validate loaded map
            if(IsMapLoaded())
            {    
                // i = client index
                for(int i = 1; i <= MaxClients; i++)
                {
                    // Client is leave the server on the disabling
                    DataBaseOnClientDisconnect(i);
                }
            }
            
            // Unhook commands
            RemoveCommandListener2(DataBaseOnExit, "exit");
            RemoveCommandListener2(DataBaseOnExit, "quit");
            RemoveCommandListener2(DataBaseOnExit, "restart");
            RemoveCommandListener2(DataBaseOnExit, "_restart");
            
            // Close database
            delete hDataBase;
        }
        return;
    }
    else
    {
        // If database already created, then stop
        if(hDataBase != INVALID_HANDLE)
        {
            return;
        }
    }

    // If file doesn't exist, then log and stop
    if(!SQL_CheckConfig(DATABASE_SECTION))
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Missing database section: \"%s\" in \"databases.cfg\"", DATABASE_SECTION);
    }

    // Initialize variables
    static char sError[BIG_LINE_LENGTH];
    static char sDriver[SMALL_LINE_LENGTH]; 
    static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH];

    // Creates an SQL connection from a named configuration
    hDataBase = SQL_Connect(DATABASE_SECTION, false, sError, sizeof(sError));

    // If can't make connection, then log and stop
    if(hDataBase == INVALID_HANDLE)
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "\"%s\"", sError);
    }

    // Log what database that is loaded
    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Loading database from section \"%s\"", DATABASE_SECTION);
    
    // Reads the driver of an opened database
    SQL_ReadDriver(hDataBase, sDriver, sizeof(sDriver)); 

    // If driver is a MySQL
    bool MySQL = !strcmp(sDriver, "mysql", false);

    // Block sql base from the other requests
    SQL_LockDatabase(hDataBase);

    // Delete existing database if dropping enable
    if(gCvarList[CVAR_GAME_CUSTOM_DATABASE].IntValue == 2)
    {
        // Format request
        FormatEx(sRequest, sizeof(sRequest), "DROP TABLE IF EXISTS `%s`", DATABASE_NAME);

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
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Dropped database: \"%s\" | Request : \"%s\"", DATABASE_NAME, sRequest);
        }
    }

    /// Format request
    if(MySQL)
    {
        /*______________________________________________________________________*/
        FormatEx(sRequest, sizeof(sRequest), "CREATE TABLE IF NOT EXISTS `%s` ( \
                                             `id` int(64) NOT NULL auto_increment, \
                                             `steam_id` varchar(32) NOT NULL, \
                                             `money` int(64) NOT NULL, \
                                             `level` int(64) NOT NULL, \
                                             `exp` int(64) NOT NULL, \
                                             `zclass` int(64) NOT NULL, \
                                             `hclass` int(64) NOT NULL, \
                                             `rebuy` int(64) NOT NULL, \
                                             `costume` int(64) NOT NULL, \
                                             `time` int(64) NOT NULL, \
                                              PRIMARY KEY (`id`), \
                                              UNIQUE KEY `steam_id` (`steam_id`))", 
        DATABASE_NAME);
        /*______________________________________________________________________*/
    }
    else
    {
        /*______________________________________________________________________*/
        FormatEx(sRequest, sizeof(sRequest), "CREATE TABLE IF NOT EXISTS `%s` ( \
                                             `id` INTEGER PRIMARY KEY AUTOINCREMENT, \
                                             `steam_id` TEXT UNIQUE, \
                                             `money` INTEGER, \
                                             `level` INTEGER, \
                                             `exp` INTEGER, \
                                             `zclass` INTEGER, \
                                             `hclass` INTEGER, \
                                             `rebuy` INTEGER, \
                                             `costume` INTEGER, \
                                             `time` INTEGER)",
        DATABASE_NAME);
        /*______________________________________________________________________*/
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
        LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Database Validation", "Executed database: \"%s\" | Connection type: \"%s\" | Request : \"%s\"", DATABASE_NAME, MySQL ? "MySQL" : "SQlite", sRequest);
    }

    // Unlock base
    SQL_UnlockDatabase(hDataBase);
    
    // Validate loaded map
    if(IsMapLoaded())
    {
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Validate client
            if(IsPlayerExist(i, false))
            {
                // Upload the client data
                DataBaseClientInit(i);
            }
        }
    }
    
    // Hook commands
    AddCommandListener(DataBaseOnExit, "exit");
    AddCommandListener(DataBaseOnExit, "quit");
    AddCommandListener(DataBaseOnExit, "restart");
    AddCommandListener(DataBaseOnExit, "_restart");
}

/**
 * Hook database cvar changes.
 **/
void DataBaseOnCvarInit(/*void*/)
{    
    // Create cvars
    gCvarList[CVAR_GAME_CUSTOM_DATABASE] = FindConVar("zp_game_custom_database");  

    // Hook cvars
    HookConVarChange(gCvarList[CVAR_GAME_CUSTOM_DATABASE], DataBaseCvarsHookEnable);
}

/**
 * Cvar hook callback (zp_game_custom_database)
 * Database module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void DataBaseCvarsHookEnable(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    DataBaseInit();
}

/**
 * Callback for command listener to turn off server.
 *
 * @param entityIndex       The entity index. (Client, or 0 for server)
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action DataBaseOnExit(const int entityIndex, const char[] commandMsg, const int iArguments)
{
    // Validate server
    if(!entityIndex)
    {
        // Switches server commands
        switch(commandMsg[0])
        {
            // Disabling/exit server
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
void DataBaseClientInit(const int clientIndex)
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
        // Initialize request char
        static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH]; 

        // Validate client authentication string (SteamID)
        if(GetClientAuthId(clientIndex, AuthId_Steam2, SteamID[clientIndex], sizeof(SteamID[])))
        {
            /// Format request
            /*_________________________________________________*/
            FormatEx(sRequest, sizeof(sRequest), "SELECT `id`, \
                                                         `money`, \
                                                         `level`, \
                                                         `exp`, \
                                                         `zclass`, \
                                                         `hclass`, \
                                                         `rebuy`, \
                                                         `costume`, \
                                                         `time` \
                                                  FROM `%s` WHERE `steam_id` = '%s'", 
            DATABASE_NAME, SteamID[clientIndex]);
            /*_________________________________________________*/
            
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
void DataBaseOnClientDisconnect(const int clientIndex)
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
public void SQLBaseExtract_Callback(Handle hDriver, Handle hResult, const char[] sSQLerror, const int clientIndex)
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
            // Client was found, get money from the table
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
                gClientData[clientIndex][Client_Time] = SQL_FetchInt(hResult, 8);

                // Update info in the database
                DataBaseSaveClientInfo(clientIndex);
            }
            else
            {
                // Initialize request char
                static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH]; 

                // Format request
                FormatEx(sRequest, sizeof(sRequest), "INSERT INTO `%s` (`steam_id`, `money`) VALUES ('%s', '%i')", DATABASE_NAME, SteamID[clientIndex], DATABASE_CONNECTION);
                
                // Block sql base from the other requests
                SQL_LockDatabase(hDataBase);
                
                // Sent a request
                if(!SQL_FastQuery(hDataBase, sRequest))
                {
                    // Initialize error char
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
                
                // Sets client data (Default)
                AccountSetClientCash(clientIndex, DATABASE_CONNECTION);
            }
            
            // Client was loaded
            gClientData[clientIndex][Client_Loaded] = true;
        }
    }
}

/**
 * Called for inserting amount of money in the SQL base.
 *
 * @param clientIndex            The client index.
 **/
void DataBaseSaveClientInfo(const int clientIndex)
{
    // Initialize request char
    static char sRequest[PLATFORM_MAX_PATH+PLATFORM_MAX_PATH]; 

    // Gets system time as a unix timestamp
    int bigUnix = GetTime();
    
    /// Format request
    if(gClientData[clientIndex][Client_DataID] < 1)
    {
        /*_______________________________________________________________*/
        FormatEx(sRequest, sizeof(sRequest), "UPDATE `%s` SET `money` = %d, \
                                                              `level` = %d, \
                                                              `exp` = %d, \
                                                              `zclass` = %d, \
                                                              `hclass` = %d, \
                                                              `rebuy` = %d, \
                                                              `costume` = %d, \
                                                              `time` = %d \
                                                          WHERE `steam_id` = '%s'",
        DATABASE_NAME, gClientData[clientIndex][Client_Money], gClientData[clientIndex][Client_Level], gClientData[clientIndex][Client_Exp], gClientData[clientIndex][Client_ZombieClassNext], gClientData[clientIndex][Client_HumanClassNext], gClientData[clientIndex][Client_AutoRebuy], gClientData[clientIndex][Client_Costume], bigUnix, SteamID[clientIndex]);
        /*_______________________________________________________________*/
    }
    else
    {
        /*_______________________________________________________________*/
        FormatEx(sRequest, sizeof(sRequest), "UPDATE `%s` SET `money` = %d, \
                                                              `level` = %d, \
                                                              `exp` = %d, \
                                                              `zclass` = %d, \
                                                              `hclass` = %d, \
                                                              `rebuy` = %d, \
                                                              `costume` = %d, \
                                                              `time` = %d \
                                                          WHERE `id` = %d",   
        DATABASE_NAME, gClientData[clientIndex][Client_Money], gClientData[clientIndex][Client_Level], gClientData[clientIndex][Client_Exp], gClientData[clientIndex][Client_ZombieClassNext], gClientData[clientIndex][Client_HumanClassNext], gClientData[clientIndex][Client_AutoRebuy], gClientData[clientIndex][Client_Costume], bigUnix, gClientData[clientIndex][Client_DataID]);
        /*_______________________________________________________________*/
    }

    // Block sql base from the other requests
    SQL_LockDatabase(hDataBase);
    
    // Sent a request
    if(!SQL_FastQuery(hDataBase, sRequest))
    {
        // Initialize error char
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