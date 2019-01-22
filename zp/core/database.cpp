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
 * @section Properties of the database.
 **/ 
#define DATABASE_SECTION     "zombiedatabase"
#define DATABASE_NAME        "zombieplague" 
/**
 * @endsection
 **/

/**
 * @section Database column types.
 **/
enum ColumnType
{
     ColumnType_ID,
     ColumnType_SteamID,
     ColumnType_Money,
     ColumnType_Level,
     ColumnType_Exp,
     ColumnType_Zombie,
     ColumnType_Human,
     ColumnType_Rebuy,
     ColumnType_Costume,
     ColumnType_Vision,
     ColumnType_Time,
     ColumnType_All,
};
/**
 * @endsection
 **/
 
/**
 * @section Database transaction types.
 **/ 
enum TransactionType
{
    TransactionType_Create,
    TransactionType_Load,
    TransactionType_Unload,
    TransactionType_Info,
    TransactionType_Describe
}
/**
 * @endsection
 **/
 
 /**
 * @section Database factories types.
 **/ 
enum FactoryType
{
    FactoryType_Create,
    FactoryType_Drop,
    FactoryType_Dump,
    FactoryType_Add,
    FactoryType_Select,
    FactoryType_Update,
    FactoryType_Insert
}
/**
 * @endsection
 **/ 
 
/**
 * Arrays for storing ID in the SQL base.
 **/
char SteamID[MAXPLAYERS+1][STEAMID_MAX_LENGTH+1];

/**
 * @brief Database module init function.
 **/
void DataBaseOnInit(/*void*/)
{
    // If database disabled, then stop
    if(!gCvarList[CVAR_DATABASE].IntValue)
    {
        // If database already created, then close
        if(gServerData.DataBase != null)
        {
            // Validate loaded map
            if(gServerData.MapLoaded)
            {    
                //!! Store all current data !!//
                DataBaseOnUnload();
            }
            
            // Unhook commands
            RemoveCommandListener2(DataBaseOnCommandListened, "exit");
            RemoveCommandListener2(DataBaseOnCommandListened, "quit");
            RemoveCommandListener2(DataBaseOnCommandListened, "restart");
            RemoveCommandListener2(DataBaseOnCommandListened, "_restart");
            
            // Close database
            delete gServerData.DataBase;
        }
        return;
    }

    // Connects to a database asynchronously, so the game thread is not blocked.
    Database.Connect(SQLBaseConnect_Callback, DATABASE_SECTION, (gCvarList[CVAR_DATABASE].IntValue == 2));

    // Validate loaded map
    if(gServerData.MapLoaded)
    {
        //!! Get all data !!//
        DataBaseOnLoad();
    }
    
    // Hook commands
    AddCommandListener(DataBaseOnCommandListened, "exit");
    AddCommandListener(DataBaseOnCommandListened, "quit");
    AddCommandListener(DataBaseOnCommandListened, "restart");
    AddCommandListener(DataBaseOnCommandListened, "_restart");
}

/**
 * @brief Database module load function.
 **/
void DataBaseOnLoad(/*void*/)
{
    // If database doesn't exist, then stop
    if(gServerData.DataBase == null)
    {
        return;
    }

    // Initialize request char
    static char sRequest[HUGE_LINE_LENGTH]; 

    // Creates a new transaction object
    Transaction hTxn = new Transaction();
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // If client was loaded, then skip
        if(gClientData[i].Loaded || hasLength(SteamID[i]))
        {
            continue;
        }
        
        // Generate request
        SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_All, FactoryType_Select, i);
        
        // Adds a query to the transaction
        hTxn.AddQuery(sRequest, i);
    }
    
    // Sent a transaction 
    gServerData.DataBase.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Load, DBPrio_Low); 
}

/**
 * @brief Database module unload function.
 **/
void DataBaseOnUnload(/*void*/)
{
    // If database doesn't exist, then stop
    if(gServerData.DataBase == null)
    {
        return;
    }

    // Initialize request char
    static char sRequest[HUGE_LINE_LENGTH]; 

    // Creates a new transaction object
    Transaction hTxn = new Transaction();
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // If client wasn't loaded, then skip
        if(!gClientData[i].Loaded || !hasLength(SteamID[i]))
        {
            continue;
        }
    
        // Generate request
        SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_All, FactoryType_Update, i);
        
        // Adds a query to the transaction
        hTxn.AddQuery(sRequest, i);
        
        // Reset variables
        SteamID[i][0] = '\0';
        gClientData[i].Loaded = false;
        gClientData[i].DataID = -1;
    }

    // Sent a transaction 
    gServerData.DataBase.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Unload, DBPrio_High); 
}

/**
 * Listener command callback (exit, quit, restart, _restart)
 * @brief Database module unloading.
 *
 * @param entityIndex       The entity index. (Client, or 0 for server)
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action DataBaseOnCommandListened(const int entityIndex, const char[] commandMsg, const int iArguments)
{
    // Validate server
    if(!entityIndex)
    {
        // Switches server commands
        switch(commandMsg[0])
        {
            // Exit/disabling/restart server
            case 'e', 'q', 'r', '_' : 
            {
                //!! Store all current data !!//
                DataBaseOnUnload();
            }
        }
    }

    // Allow commands
    return Plugin_Continue;
}

/**
 * @brief Hook database cvar changes.
 **/
void DataBaseOnCvarInit(/*void*/)
{    
    // Creates cvars
    gCvarList[CVAR_DATABASE] = FindConVar("zp_database");  

    // Hook cvars
    HookConVarChange(gCvarList[CVAR_DATABASE], DataBaseOnCvarHook);
}

/**
 * Cvar hook callback (zp_database)
 * @brief Database module initialization.
 * 
 * @param hConVar           The cvar handle.
 * @param oldValue          The value before the attempted change.
 * @param newValue          The new value.
 **/
public void DataBaseOnCvarHook(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
    // Validate new value
    if(oldValue[0] == newValue[0])
    {
        return;
    }
    
    // Forward event to modules
    DataBaseOnInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param clientIndex       The client index. 
 **/
void DataBaseOnClientInit(const int clientIndex)
{
    // If database doesn't exist, then stop
    if(gServerData.DataBase == null)
    {
        return;
    }
    
    // Verify that the client is a real player
    if(!IsFakeClient(clientIndex))
    {
        // Initialize request char
        static char sRequest[HUGE_LINE_LENGTH]; 

        // Validate client authentication string (SteamID)
        if(GetClientAuthId(clientIndex, AuthId_Steam2, SteamID[clientIndex], sizeof(SteamID[])))
        {
            // Generate request
            SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_All, FactoryType_Select, clientIndex);
            
            // Sent a request
            gServerData.DataBase.Query(SQLBaseSelect_Callback, sRequest, clientIndex, DBPrio_High);
        }
    }
}

/**
 * @brief Called once a client successfully connects.
 *
 * @param clientIndex       The client index.
 **/
void DataBaseOnClientConnect(const int clientIndex)
{
    // Reset steam buffer
    SteamID[clientIndex][0] = '\0';
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param clientIndex       The client index.
 **/
void DataBaseOnClientDisconnectPost(const int clientIndex)
{
    // Update data in the database
    DataBaseOnClientUpdate(clientIndex, ColumnType_All);

    // Reset steam buffer
    SteamID[clientIndex][0] = '\0';
}

/**
 * @brief Client has been changed class state.
 *
 * @param clientIndex       The client index.
 * @param columnType        The column type.
 **/
void DataBaseOnClientUpdate(const int clientIndex, const ColumnType columnType)
{
    // If database doesn't exist, then stop
    if(gServerData.DataBase == null)
    {
        return;
    }
    
    // If client wasn't loaded, then stop
    if(!gClientData[clientIndex].Loaded || !hasLength(SteamID[clientIndex]))
    {
        return;
    }

    // Initialize request char
    static char sRequest[HUGE_LINE_LENGTH]; 
    
    // Generate request
    SQLBaseFactory__(_, sRequest, sizeof(sRequest), columnType, FactoryType_Update, clientIndex);
    
    // Sent a request
    gServerData.DataBase.Query(SQLBaseUpdate_Callback, sRequest, clientIndex, DBPrio_Low);
}

/*
 * Callbacks database API.
 */
 
/**
 * @brief Callback for a successful transaction.
 * 
 * @param hDatabase         Handle to the database connection.
 * @param transactionType   Data passed in via the original threaded invocation.
 * @param numQueries        Number of queries executed in the transaction.
 * @param hResults          An array of DBResultSet results, one for each of numQueries. They are closed automatically.
 * @param clientIndex       An array of each data value passed.
 **/
public void SQLTxnSuccess_Callback(Database hDatabase, const TransactionType transactionType, const int numQueries, DBResultSet[] hResults, const int[] clientIndex)
{
    // Gets transaction type
    switch(transactionType)
    {
        // Database was 'Loaded' during map
        case TransactionType_Load :
        {
            // i = client index
            for(int i = 0; i < numQueries; i++)
            {
                SQLBaseSelect_Callback(hDatabase, hResults[i], "", clientIndex[i]);
            }
        }
        
        // Database 'SQlite' pragma info request
        case TransactionType_Info :
        {
            // Validate request
            if(numQueries == 2)
            {
                SQLBaseAdd_Callback(hDatabase, hResults[1], false);
            }
        }
        
        // Database 'MySQL' describe request
        case TransactionType_Describe :
        {
            // Validate request
            if(numQueries == 2)
            {
                SQLBaseAdd_Callback(hDatabase, hResults[1], true);
            }
        }
    }
}

/**
 * @brief Callback for a failed transaction.
 * 
 * @param hDatabase         Handle to the database connection.
 * @param data              Data passed in via the original threaded invocation.
 * @param numQueries        Number of queries executed in the transaction.
 * @param sError            Error string if there was an error.
 * @param failIndex         Index of the query that failed, or -1 if something else.
 * @param clientIndex       An array of each data value passed.
 **/
public void SQLTxnFailure_Callback(Database hDatabase, const TransactionType transactionType, const int numQueries, const char[] sError, const int failIndex, const any[] clientIndex)
{
    // If invalid query handle, then log error
    if(hDatabase == null || hasLength(sError))
    {
        // Unexpected error, log it
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "ID: \"%d\" - \"%s\"", failIndex, sError);
    }
}

/**
 * SQL: DROP, CREATE
 * @brief Callback for receiving asynchronous database connection.
 *
 * @param hDatabase         Handle to the database connection.
 * @param sError            Error string if there was an error.
 * @param bDropping         Data passed in via the original threaded invocation.
 **/
public void SQLBaseConnect_Callback(Database hDatabase, const char[] sError, const bool bDropping)
{
    // If invalid query handle, then log error
    if(hDatabase == null || hasLength(sError))
    {
        // Unexpected error, log it
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
    }
    else
    {
        // Validate a global database handler
        if(gServerData.DataBase != null)
        {
            // Validate a new database is the same connection as old database
            if(hDatabase.IsSameConnection(gServerData.DataBase))
            {
                return;
            }
            
            // Close database
            delete gServerData.DataBase;
        }

        // Store into a global database handler
        gServerData.DataBase = hDatabase;
        
        /*______________________________________________________________________________*/
        
        // Creates a new transaction object
        Transaction hTxn = new Transaction();

        // Initialize request char
        static char sRequest[HUGE_LINE_LENGTH]; 
        
        // Drop existing database
        if(bDropping)
        {
            // Generate request
            SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_All, FactoryType_Drop);

            // Adds a query to the transaction
            hTxn.AddQuery(sRequest);
        }
        
        // Gets the driver for this connection
        DBDriver hDriver = gServerData.DataBase.Driver;
        static char sDriver[SMALL_LINE_LENGTH]; 
        hDriver.GetIdentifier(sDriver, sizeof(sDriver));
        delete hDriver;

        // Validate MySQL connection
        bool MySQL = (sDriver[0] == 'm'); 

        // Generate request
        SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_All, FactoryType_Create);
        
        // Adds a query to the transaction
        hTxn.AddQuery(sRequest);
        
        // Generate request
        SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_All, FactoryType_Dump);
        
        // Adds a query to the transaction
        hTxn.AddQuery(sRequest);

        // Sent a transaction 
        gServerData.DataBase.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, MySQL ? TransactionType_Describe : TransactionType_Info, DBPrio_High); 
    }
}

/**
 * SQL: INFO, DESCRIBE
 * @brief Callback for receiving asynchronous database information.
 *
 * @param hDatabase         Parent object of the handle.
 * @param hResult           Handle to the child object.
 * @param MySQL             The type of connection. 
 **/
public void SQLBaseAdd_Callback(Database hDatabase, DBResultSet hResult, const bool MySQL)
{
    // Initialize a column existance array
    ArrayList hColumn = CreateArray(SMALL_LINE_LENGTH);

    // Info was found, get name from the rows
    while(hResult.FetchRow())
    {
        // Extract row name
        static char sColumn[SMALL_LINE_LENGTH];
        hResult.FetchString(!MySQL, sColumn, sizeof(sColumn));

        // Validate unique column
        if(hColumn.FindString(sColumn) == -1)
        {
            // Push data into array
            hColumn.PushString(sColumn);
        }
    }
    
    // Creates a new transaction object
    Transaction hTxn = new Transaction();

    // Initialize request char
    static char sRequest[HUGE_LINE_LENGTH]; 
    
    // Find any column which not exist in the table
    static const char sColumn[11][SMALL_LINE_LENGTH] = { "id", "steam_id", "money", "level", "exp", "zclass", "hclass", "rebuy", "costume", "vision", "time" };
    for(int i = 0; i < sizeof(sColumn); i++)
    {
        // Validate unique column
        if(hColumn.FindString(sColumn[i]) == -1)
        {
            // Generate request
            SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), view_as<ColumnType>(i), FactoryType_Add);
            
            // Adds a query to the transaction
            hTxn.AddQuery(sRequest);
        }
    }

    // Sent a transaction 
    gServerData.DataBase.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Create, DBPrio_Normal); 
    
    // Close list
    delete hColumn;
}

/**
 * SQL: SELECT
 * @brief Callback for receiving asynchronous database query results.
 *
 * @param hDatabase         Parent object of the handle.
 * @param hResult           Handle to the child object.
 * @param sError            Error string if there was an error.
 * @param clientIndex       Data passed in via the original threaded invocation.
 **/
public void SQLBaseSelect_Callback(Database hDatabase, DBResultSet hResult, const char[] sError, const int clientIndex)
{
    // Make sure the client didn't disconnect while the thread was running
    if(IsPlayerExist(clientIndex, false))
    {
        // If invalid query handle, then log error
        if(hDatabase == null || hResult == null || hasLength(sError))
        {
            // Unexpected error, log it
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
        }
        else
        {
            // Client was found, get data from the row
            if(hResult.FetchRow())
            {
                // Sets client data
                gClientData[clientIndex].DataID          = hResult.FetchInt(view_as<int>(ColumnType_ID)); 
                gClientData[clientIndex].Money           = hResult.FetchInt(view_as<int>(ColumnType_Money));
                gClientData[clientIndex].Level           = hResult.FetchInt(view_as<int>(ColumnType_Level));
                gClientData[clientIndex].Exp             = hResult.FetchInt(view_as<int>(ColumnType_Exp));              
                gClientData[clientIndex].ZombieClassNext = hResult.FetchInt(view_as<int>(ColumnType_Zombie));
                gClientData[clientIndex].HumanClassNext  = hResult.FetchInt(view_as<int>(ColumnType_Human));
                gClientData[clientIndex].AutoRebuy       = view_as<bool>(hResult.FetchInt(view_as<int>(ColumnType_Rebuy)));
                gClientData[clientIndex].Costume         = hResult.FetchInt(view_as<int>(ColumnType_Costume));
                gClientData[clientIndex].Vision          = view_as<bool>(hResult.FetchInt(view_as<int>(ColumnType_Vision)));
                gClientData[clientIndex].Time            = hResult.FetchInt(view_as<int>(ColumnType_Time));
            }
            else
            {
                // Initialize request char
                static char sRequest[HUGE_LINE_LENGTH]; 

                // Generate request
                SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_SteamID, FactoryType_Insert);
                
                // Sent a request
                gServerData.DataBase.Query(SQLBaseInsert_Callback, sRequest, clientIndex, DBPrio_High);    
            }
            
            // Client was loaded
            gClientData[clientIndex].Loaded = true;
        }
    }
}

/**
 * SQL: INSERT
 * @brief Callback for receiving asynchronous database query results.
 *
 * @param hDatabase         Parent object of the handle.
 * @param hResult           Handle to the child object.
 * @param sError            Error string if there was an error.
 * @param clientIndex       Data passed in via the original threaded invocation.
 **/
public void SQLBaseInsert_Callback(Database hDatabase, DBResultSet hResult, const char[] sError, const int clientIndex)
{
    // Make sure the client didn't disconnect while the thread was running
    if(IsPlayerExist(clientIndex, false))
    {
        // If invalid query handle, then log error
        if(hDatabase == null || hResult == null || hasLength(sError))
        {
            // Unexpected error, log it
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
        }
        else
        {
            // Sets client data
            gClientData[clientIndex].DataID = hResult.InsertId;
            gClientData[clientIndex].Money  = gCvarList[CVAR_ACCOUNT_CONNECT].IntValue;
        }
    } 
}
 
/**
 * SQL: UPDATE
 * @brief Callback for receiving asynchronous database query results.
 *
 * @param hDatabase         Parent object of the handle.
 * @param hResult           Handle to the child object.
 * @param sError            Error string if there was an error.
 * @param clientIndex       Data passed in via the original threaded invocation.
 **/
public void SQLBaseUpdate_Callback(Database hDatabase, DBResultSet hResult, const char[] sError, const int clientIndex)
{
    // If invalid query handle, then log error
    if(hDatabase == null || hResult == null || hasLength(sError))
    {
        // Unexpected error, log it
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
    }
}

/*
 * Stocks database API.
 */
 
/**
 * @brief Function for building any SQL request.
 *
 * @param MySQL             (Optional) The type of connection. 
 * @param sRequest          The request output.
 * @param iMaxLen           The lenght of string.
 * @param columnType        The column type.
 * @param factoryType       The request type.
 * @param clientIndex       (Optional) The client index. (for data)
 **/
void SQLBaseFactory__(const bool MySQL = false, char[] sRequest, const int iMaxLen, const ColumnType columnType, const FactoryType factoryType, const int clientIndex = 0)
{   
    // Gets factory mode
    switch(factoryType)
    {
        case FactoryType_Create :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `%s` ", DATABASE_NAME);
            StrCat(sRequest, iMaxLen, 
            MySQL ? 
              "(`id` int(64) NOT NULL auto_increment, \
                `steam_id` varchar(32) NOT NULL, \
                `money` int(64) NOT NULL DEFAULT 0, \
                `level` int(64) NOT NULL DEFAULT 1, \
                `exp` int(64) NOT NULL DEFAULT 0, \
                `zclass` int(64) NOT NULL DEFAULT 0, \
                `hclass` int(64) NOT NULL DEFAULT 0, \
                `rebuy` int(64) NOT NULL DEFAULT 1, \
                `costume` int(64) NOT NULL DEFAULT -1, \
                `vision` int(64) NOT NULL DEFAULT 1, \
                `time` int(64) NOT NULL DEFAULT 0, \
                PRIMARY KEY (`id`), \
                UNIQUE KEY `steam_id` (`steam_id`));"            
            :
              "(`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
                `steam_id` TEXT UNIQUE NOT NULL, \
                `money` INTEGER DEFAULT 0, \
                `level` INTEGER DEFAULT 1, \
                `exp` INTEGER DEFAULT 0, \
                `zclass` INTEGER DEFAULT 0, \
                `hclass` INTEGER DEFAULT 0, \
                `rebuy` INTEGER DEFAULT 1, \
                `costume` INTEGER DEFAULT -1, \
                `vision` INTEGER DEFAULT 1, \
                `time` INTEGER DEFAULT 0);");
            
            // Log database creation info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Table \"%s\" was created/loaded. \"%s\" - \"%s\"", DATABASE_NAME, MySQL ? "MySQL" : "SQlite", sRequest);
        }
        
        case FactoryType_Drop :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "DROP TABLE IF EXISTS `%s`;", DATABASE_NAME);
            
            // Log database dropping info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Table \"%s\" was dropped. \"%s\"", DATABASE_NAME, sRequest);
        }
        
        case FactoryType_Dump :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, MySQL ? "DESCRIBE `%s`;" : "PRAGMA table_info(`%s`);", DATABASE_NAME);
            
            // Log database dumping info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Table \"%s\" was dumped. \"%s\"", DATABASE_NAME, sRequest);
        }
        
        case FactoryType_Add :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "ALTER TABLE `%s` ", DATABASE_NAME);
            switch(columnType)
            {
                case ColumnType_ID :
                {
                    StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `id` int(64) NOT NULL auto_increment, ADD PRIMARY KEY (`id`);" : "ADD COLUMN `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"id\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_SteamID :
                {
                    StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `steam_id` varchar(32) NOT NULL, ADD UNIQUE `steam_id` (`steam_id`);" : "ADD COLUMN `steam_id` TEXT UNIQUE NOT NULL;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"steam_id\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Money :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `money` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"money\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Level :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `level` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 1;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"level\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Exp :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `exp` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"exp\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Zombie :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `zclass` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"zclass\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Human :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `hclass` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"hclass\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Rebuy :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `rebuy` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 1;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"rebuy\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Costume :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `costume` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT -1;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"costume\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Vision :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `vision` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 1;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"vision\" was added. \"%s\"", sRequest);
                }

                case ColumnType_Time :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `time` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"time\" was added. \"%s\"", sRequest);
                }
            }
        }

        case FactoryType_Select :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "SELECT ");    
            switch(columnType)
            {
                case ColumnType_All :
                {
                    StrCat(sRequest, iMaxLen, "*");
                
                    // Log database updation info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was found. \"%s\"", clientIndex, sRequest);
                }
                
                case ColumnType_Money :
                {
                    StrCat(sRequest, iMaxLen, "`money`");
                }
                
                case ColumnType_Level :
                {
                    StrCat(sRequest, iMaxLen, "`level`");
                }
                
                case ColumnType_Exp :
                {
                    StrCat(sRequest, iMaxLen, "`exp`");
                }
                
                case ColumnType_Zombie :
                {
                    StrCat(sRequest, iMaxLen, "`zclass`");
                }
                
                case ColumnType_Human :
                {
                    StrCat(sRequest, iMaxLen, "`hclass`");
                }
                
                case ColumnType_Rebuy :
                {
                    StrCat(sRequest, iMaxLen, "`rebuy`");
                }
                
                case ColumnType_Costume :
                {
                    StrCat(sRequest, iMaxLen, "`costume`");
                }
                
                case ColumnType_Vision :
                {
                    StrCat(sRequest, iMaxLen, "`vision`");
                }

                case ColumnType_Time :
                {
                    StrCat(sRequest, iMaxLen, "`time`");
                }
            }
            Format(sRequest, iMaxLen, "%s FROM `%s`", sRequest, DATABASE_NAME);
            
            // Validate row id
            if(gClientData[clientIndex].DataID < 1)
            {
                Format(sRequest, iMaxLen, "%s WHERE `steam_id` = '%s';", sRequest, SteamID[clientIndex]);
            }
            else
            {
                Format(sRequest, iMaxLen, "%s WHERE `id` = %d;", sRequest, gClientData[clientIndex].DataID);
            }
        }
        
        case FactoryType_Update :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "UPDATE `%s` SET", DATABASE_NAME);    
            switch(columnType)
            {
                case ColumnType_All :
                {
                    Format(sRequest, iMaxLen, "%s `money` = %d, \
                                                  `level` = %d, \
                                                  `exp` = %d, \
                                                  `zclass` = %d, \
                                                  `hclass` = %d, \
                                                  `rebuy` = %d, \
                                                  `costume` = %d, \
                                                  `vision` = %d, \
                                                  `time` = %d",
                    sRequest, gClientData[clientIndex].Money, gClientData[clientIndex].Level, gClientData[clientIndex].Exp, gClientData[clientIndex].ZombieClassNext, gClientData[clientIndex].HumanClassNext, gClientData[clientIndex].AutoRebuy, gClientData[clientIndex].Costume, gClientData[clientIndex].Vision, GetTime());

                    // Log database updation info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was stored. \"%s\"", clientIndex, sRequest); 
                }
                
                case ColumnType_Money :
                {
                    Format(sRequest, iMaxLen, "%s `money` = %d", sRequest, gClientData[clientIndex].Money);
                }
                
                case ColumnType_Level :
                {
                    Format(sRequest, iMaxLen, "%s `level` = %d", sRequest, gClientData[clientIndex].Level);
                }
                
                case ColumnType_Exp :
                {
                    Format(sRequest, iMaxLen, "%s `exp` = %d", sRequest, gClientData[clientIndex].Exp);
                }
                
                case ColumnType_Zombie :
                {
                    Format(sRequest, iMaxLen, "%s `zclass` = %d", sRequest, gClientData[clientIndex].ZombieClassNext);
                }
                
                case ColumnType_Human :
                {
                    Format(sRequest, iMaxLen, "%s `hclass` = %d", sRequest, gClientData[clientIndex].HumanClassNext);
                }
                
                case ColumnType_Rebuy :
                {
                    Format(sRequest, iMaxLen, "%s `rebuy` = %d", sRequest, gClientData[clientIndex].AutoRebuy);
                }
                
                case ColumnType_Costume :
                {
                    Format(sRequest, iMaxLen, "%s `costume` = %d", sRequest, gClientData[clientIndex].Costume);
                }
                
                case ColumnType_Vision :
                {
                    Format(sRequest, iMaxLen, "%s `vision` = %d", sRequest, gClientData[clientIndex].Vision);
                }

                case ColumnType_Time :
                {
                    Format(sRequest, iMaxLen, "%s `time` = %d", sRequest, GetTime()); //! Gets system time as a unix timestamp
                }
            }
            
            // Validate row id
            if(gClientData[clientIndex].DataID < 1)
            {
                Format(sRequest, iMaxLen, "%s WHERE `steam_id` = '%s';", sRequest, SteamID[clientIndex]);
            }
            else
            {
                Format(sRequest, iMaxLen, "%s WHERE `id` = %d;", sRequest, gClientData[clientIndex].DataID);
            }
        }
        
        case FactoryType_Insert :
        {
            /// Format request  
            switch(columnType)
            {
                case ColumnType_SteamID :
                {
                    FormatEx(sRequest, iMaxLen, "INSERT INTO `%s` (`steam_id`) VALUES ('%s');", DATABASE_NAME, SteamID[clientIndex]);
                    
                    // Log database insertion info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was inserted. \"%s\"", clientIndex, sRequest);
                }
            }
        }    
    }
}