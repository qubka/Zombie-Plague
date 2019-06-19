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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
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
#define DATABASE_MAIN        "zombieplague"
#define DATABASE_CHILD       "zombieweapon"
/**
 * @endsection
 **/

/**
 * @section Database state types.
 **/ 
enum /*DatabaseType*/
{
    DatabaseType_Disabled,
    DatabaseType_Enable,
    DatabaseType_Drop
}
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
    ColumnType_Costume,
    ColumnType_Vision,
    ColumnType_Time,
    ColumnType_Weapon,
    ColumnType_Default
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
    TransactionType_Describe,
    TransactionType_Info
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
    FactoryType_Keys,
    FactoryType_Parent,
    FactoryType_Add,
    FactoryType_Remove,
    FactoryType_Select,
    FactoryType_Update,
    FactoryType_Insert,
    FactoryType_Delete
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
        if(gServerData.DBI != null)
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
            
            // Close connection
            delete gServerData.DBI;
            delete gServerData.Cols;
            delete gServerData.Columns;
        }
        return;
    }
    
    // If list wasn't created, then create
    if(gServerData.Cols == null)
    {        
        // Initialize map containg columns names and types
        gServerData.Cols = new StringMap();
        
        // Push data into map
        gServerData.Cols.SetValue("id", ColumnType_ID);
        gServerData.Cols.SetValue("steam_id", ColumnType_SteamID);
        gServerData.Cols.SetValue("money", ColumnType_Money);
        gServerData.Cols.SetValue("level", ColumnType_Level);
        gServerData.Cols.SetValue("exp", ColumnType_Exp);
        gServerData.Cols.SetValue("zombie", ColumnType_Zombie); 
        gServerData.Cols.SetValue("human", ColumnType_Human); 
        gServerData.Cols.SetValue("skin", ColumnType_Costume);
        gServerData.Cols.SetValue("vision", ColumnType_Vision); 
        gServerData.Cols.SetValue("time", ColumnType_Time);

        // Generate key mapshot 
        gServerData.Columns = gServerData.Cols.Snapshot();
    }

    // Connects to a database asynchronously, so the game thread is not blocked.
    Database.Connect(SQLBaseConnect_Callback, DATABASE_SECTION, (gCvarList[CVAR_DATABASE].IntValue == DatabaseType_Drop));

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
    if(gServerData.DBI == null)
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

        // Verify that the client is a real player
        if(IsPlayerExist(i, false) && !IsFakeClient(i))
        {
            // Validate client authentication string (SteamID)
            if(GetClientAuthId(i, AuthId_Steam2, SteamID[i], sizeof(SteamID[])))
            { 
                // Generate request
                SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Select, i);
            
                // Adds a query to the transaction
                hTxn.AddQuery(sRequest, i);
            }
        }
    }
    
    // Sent a transaction 
    gServerData.DBI.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Load, DBPrio_Low); 
}

/**
 * @brief Database module unload function.
 **/
void DataBaseOnUnload(/*void*/)
{
    // If database doesn't exist, then stop
    if(gServerData.DBI == null)
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
        SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Update, i);
        
        // Adds a query to the transaction
        hTxn.AddQuery(sRequest, i);
        
        // Resets variables
        SteamID[i][0] = NULL_STRING[0];
        gClientData[i].Loaded = false;
        gClientData[i].DataID = -1;
    }

    // Sent a transaction 
    gServerData.DBI.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Unload, DBPrio_High); 
}

/**
 * Listener command callback (exit, quit, restart, _restart)
 * @brief Database module unloading.
 *
 * @param entity            The entity index. (Client, or 0 for server)
 * @param commandMsg        Command name, lower case. To get name as typed, use GetCmdArg() and specify argument 0.
 * @param iArguments        Argument count.
 **/
public Action DataBaseOnCommandListened(int entity, char[] commandMsg, int iArguments)
{
    // Validate server
    if(!entity)
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
public void DataBaseOnCvarHook(ConVar hConVar, char[] oldValue, char[] newValue)
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
 * @param client            The client index. 
 **/
void DataBaseOnClientInit(int client)
{
    // If database doesn't exist, then stop
    if(gServerData.DBI == null)
    {
        return;
    }
    
    // Verify that the client is a real player
    if(!IsFakeClient(client))
    {
        // Initialize request char
        static char sRequest[HUGE_LINE_LENGTH]; 

        // Validate client authentication string (SteamID)
        if(GetClientAuthId(client, AuthId_Steam2, SteamID[client], sizeof(SteamID[])))
        {
            // Generate request
            SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Select, client);

            // Sent a request
            gServerData.DBI.Query(SQLBaseSelect_Callback, sRequest, client, DBPrio_High);
        }
    }
}

/**
 * @brief Called once a client successfully connects.
 *
 * @param client            The client index.
 **/
void DataBaseOnClientConnect(int client)
{
    // Resets steam buffer
    SteamID[client][0] = NULL_STRING[0];
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param client            The client index.
 **/
void DataBaseOnClientDisconnectPost(int client)
{
    // Update data in the database
    DataBaseOnClientUpdate(client, ColumnType_Default);

    // Resets steam buffer
    SteamID[client][0] = NULL_STRING[0];
}

/**
 * @brief Client has been changed class state.
 *
 * @param client            The client index.
 * @param nColumn           The column type.
 * @param mFactory          (Optional) The request type.
 * @param sData             (Optional) The string input.
 **/
void DataBaseOnClientUpdate(int client, ColumnType nColumn, FactoryType mFactory = FactoryType_Update, char[] sData = "")
{
    // If database doesn't exist, then stop
    if(gServerData.DBI == null)
    {
        return;
    }
    
    // If client wasn't loaded, then stop
    if(!gClientData[client].Loaded || !hasLength(SteamID[client]))
    {
        return;
    }

    // Initialize request char
    static char sRequest[HUGE_LINE_LENGTH]; 

    // Generate request
    SQLBaseFactory__(_, sRequest, sizeof(sRequest), nColumn, mFactory, client, sData);

    // Sent a request
    gServerData.DBI.Query(SQLBaseUpdate_Callback, sRequest, client, DBPrio_Low);
}

/*
 * Callbacks SQL transactions.
 */
 
/**
 * @brief Callback for a successful transaction.
 * 
 * @param hDatabase         Handle to the database connection.
 * @param mTransaction      Data passed in via the original threaded invocation.
 * @param numQueries        Number of queries executed in the transaction.
 * @param hResults          An array of DBResultSet results, one for each of numQueries. They are closed automatically.
 * @param client            An array of each data value passed.
 **/
public void SQLTxnSuccess_Callback(Database hDatabase, TransactionType mTransaction, int numQueries, DBResultSet[] hResults, int[] client)
{
    // Gets transaction type
    switch(mTransaction)
    {
        /*
            case TransactionType_Create :
            case TransactionType_Unload :
        */
        
        case TransactionType_Load :
        {
            // i = request index
            for(int i = 0; i < numQueries; i++)
            {
                SQLBaseSelect_Callback(hDatabase, hResults[i], "", client[i]);
            }
        }

        case TransactionType_Describe, TransactionType_Info :
        {
            // Validate request
            if(numQueries <= view_as<int>(TransactionType_Info)) /// If drop include, then stop
            {
                SQLBaseAdd_Callback(hDatabase, hResults[1], (mTransaction == TransactionType_Describe));
            }
        }
    }
}

/**
 * @brief Callback for a failed transaction.
 * 
 * @param hDatabase         Handle to the database connection.
 * @param mTransaction      Data passed in via the original threaded invocation.
 * @param numQueries        Number of queries executed in the transaction.
 * @param sError            Error string if there was an error.
 * @param iFail             Index of the query that failed, or -1 if something else.
 * @param client            An array of each data value passed.
 **/
public void SQLTxnFailure_Callback(Database hDatabase, TransactionType mTransaction, int numQueries, char[] sError, int iFail, int[] client)
{
    // If invalid query handle, then log error
    if(hDatabase == null || hasLength(sError))
    {
        // Unexpected error, log it
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "ID: \"%d\" - \"%s\"", iFail, sError);
    }
}

/*
 * Callbacks SQL functions.
 */

/**
 * SQL: DROP, CREATE
 * @brief Callback for receiving asynchronous database connection.
 *
 * @param hDatabase         Handle to the database connection.
 * @param sError            Error string if there was an error.
 * @param bDropping         Data passed in via the original threaded invocation.
 **/
public void SQLBaseConnect_Callback(Database hDatabase, char[] sError, bool bDropping)
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
        if(gServerData.DBI != null)
        {
            // Validate a new database is the same connection as old database
            if(hDatabase.IsSameConnection(gServerData.DBI))
            {
                return;
            }
            
            // Close database
            delete gServerData.DBI;
        }

        // Store into a global database handler
        gServerData.DBI = hDatabase;
        
        /*______________________________________________________________________________*/
        
        // Creates a new transaction object
        Transaction hTxn = new Transaction();

        // Initialize request char
        static char sRequest[HUGE_LINE_LENGTH]; 
        
        // Drop existing database
        if(bDropping)
        {
            // Generate request
            SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Drop);

            // Adds a query to the transaction
            hTxn.AddQuery(sRequest);
        }
        
        // Gets driver for this connection
        DBDriver hDriver = gServerData.DBI.Driver;
        static char sDriver[SMALL_LINE_LENGTH]; 
        hDriver.GetIdentifier(sDriver, sizeof(sDriver));
        delete hDriver;

        // Validate MySQL connection
        bool MySQL = (sDriver[0] == 'm'); 

        // Execute requests
        static const FactoryType mFactory[4] = { FactoryType_Create, FactoryType_Dump, FactoryType_Keys, FactoryType_Parent };
        for(int x = 0; x < sizeof(mFactory); x++)
        {        
            // Generate request
            SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_Default, mFactory[x]);
        
            // Adds a query to the transaction
            hTxn.AddQuery(sRequest);
        }

        // Sent a transaction 
        gServerData.DBI.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, MySQL ? TransactionType_Describe : TransactionType_Info, DBPrio_High); 
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
public void SQLBaseAdd_Callback(Database hDatabase, DBResultSet hResult, bool MySQL)
{
    // Initialize some variables
    static char sColumn[SMALL_LINE_LENGTH]; ColumnType nColumn;
    
    // Initialize a column existance array
    ArrayList hColumn = new ArrayList(SMALL_LINE_LENGTH);
    
    // Info was found, get name from the rows
    while(hResult.FetchRow())
    {
        // Extract row name
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
    
    // i = column index
    int iSize = gServerData.Cols.Size;
    for(int i = 0; i < iSize; i++)
    {
        // Gets string from the map
        gServerData.Columns.GetKey(i, sColumn, sizeof(sColumn));
        
        // Validate non exist column
        if(hColumn.FindString(sColumn) == -1)
        {
            // Gets column type
            gServerData.Cols.GetValue(sColumn, nColumn);
            
            // Generate request
            SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), nColumn, FactoryType_Add);
            
            // Adds a query to the transaction
            hTxn.AddQuery(sRequest);
        }
    }

    // i = column index
    iSize = hColumn.Length;
    for(int i = 0; i < iSize; i++)
    {
        // Gets string from the array
        hColumn.GetString(i, sColumn, sizeof(sColumn));
        
        // Validate not exist column
        if(!gServerData.Cols.GetValue(sColumn, nColumn))
        {
            /// SQlite doesn't have column drop feature
            if(MySQL)
            {
                // Generate request
                SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Remove, _, sColumn);
                
                // Adds a query to the transaction
                hTxn.AddQuery(sRequest);
            }
            else
            {
                // x = step index
                for(int x = 0; x < 4; x++)
                {
                    // Generate request
                    SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Remove, x);
                    
                    // Adds a query to the transaction
                    hTxn.AddQuery(sRequest);
                }
                
                // Stop loop
                break;
            }
        }
    }
    
    // Sent a transaction 
    gServerData.DBI.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Create, DBPrio_Normal); 
    
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
 * @param client            Data passed in via the original threaded invocation.
 **/
public void SQLBaseSelect_Callback(Database hDatabase, DBResultSet hResult, char[] sError, int client)
{
    // Make sure the client didn't disconnect while the thread was running
    if(IsPlayerExist(client, false))
    {
        // If invalid query handle, then log error
        if(hDatabase == null || hResult == null || hasLength(sError))
        {
            // Unexpected error, log it
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
        }
        else
        {
            // Initialize request char
            static char sRequest[HUGE_LINE_LENGTH]; 

            // Client was found, get data from the row
            if(hResult.FetchRow())
            {
                // Initialize some variables 
                static char sColumn[SMALL_LINE_LENGTH]; ColumnType nColumn; int iIndex;
 
                // i = field index
                int iCount = hResult.FieldCount;
                for(int i = 0; i < iCount; i++)
                {
                    // Gets name of the field
                    hResult.FieldNumToName(i, sColumn, sizeof(sColumn));

                    // Validate that field is exist
                    if(gServerData.Cols.GetValue(sColumn, nColumn))
                    {
                        // Sets client data
                        switch(nColumn)
                        {
                            case ColumnType_ID :     gClientData[client].DataID = hResult.FetchInt(i); 
                            case ColumnType_Money :  gClientData[client].Money  = hResult.FetchInt(i); 
                            case ColumnType_Level :  gClientData[client].Level  = hResult.FetchInt(i);
                            case ColumnType_Exp :    gClientData[client].Exp    = hResult.FetchInt(i); 
                            case ColumnType_Zombie :
                            {
                                hResult.FetchString(i, sColumn, sizeof(sColumn)); iIndex = ClassNameToIndex(sColumn);
                                gClientData[client].ZombieClassNext = (iIndex != -1) ? iIndex : 0;
                            }
                            case ColumnType_Human :
                            {
                                hResult.FetchString(i, sColumn, sizeof(sColumn)); iIndex = ClassNameToIndex(sColumn);
                                gClientData[client].HumanClassNext  = (iIndex != -1) ? iIndex : 0;
                            }
                            case ColumnType_Costume :
                            {
                                // If costumes is disabled, then skip
                                if(!gCvarList[CVAR_COSTUMES].BoolValue)
                                {
                                    return;
                                }
                                
                                hResult.FetchString(i, sColumn, sizeof(sColumn));
                                gClientData[client].Costume = CostumesNameToIndex(sColumn);
                            }
                            case ColumnType_Vision : gClientData[client].Vision = view_as<bool>(hResult.FetchInt(i));
                            case ColumnType_Time :   gClientData[client].Time   = hResult.FetchInt(i);
                        }
                    }
                }
                
                // Generate request
                SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Weapon, FactoryType_Select, client);
                
                // Sent a request
                gServerData.DBI.Query(SQLBaseExtract_Callback, sRequest, client, DBPrio_Normal); 
            }
            else
            {
                // Generate request
                SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_SteamID, FactoryType_Insert, client);
                
                // Sent a request
                gServerData.DBI.Query(SQLBaseInsert_Callback, sRequest, client, DBPrio_High); 
            }
            
            // Client was loaded
            gClientData[client].Loaded = true;
        }
    }
}

/**
 * SQL: EXTRACT
 * @brief Callback for receiving asynchronous database query results.
 *
 * @param hDatabase         Parent object of the handle.
 * @param hResult           Handle to the child object.
 * @param sError            Error string if there was an error.
 * @param client            Data passed in via the original threaded invocation.
 **/
public void SQLBaseExtract_Callback(Database hDatabase, DBResultSet hResult, char[] sError, int client)
{
    // Make sure the client didn't disconnect while the thread was running
    if(IsPlayerExist(client, false))
    {
        // If invalid query handle, then log error
        if(hDatabase == null || hResult == null || hasLength(sError))
        {
            // Unexpected error, log it
            LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
        }
        else
        {
            // Client was found, get data from all rows
            while(hResult.FetchRow())
            {
                // Gets weapon name from the table 
                static char sWeapon[SMALL_LINE_LENGTH];
                hResult.FetchString(0, sWeapon, sizeof(sWeapon));
                
                // Validate index
                int iIndex = WeaponsNameToIndex(sWeapon);
                if(iIndex != -1)
                {   
                    // If array hasn't been created, then create
                    if(gClientData[client].DefaultCart == null)
                    {
                        // Initialize a default cart array
                        gClientData[client].DefaultCart = new ArrayList();
                    }
            
                    // Push data into array
                    gClientData[client].DefaultCart.Push(iIndex);
                }
            }
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
 * @param client            Data passed in via the original threaded invocation.
 **/
public void SQLBaseInsert_Callback(Database hDatabase, DBResultSet hResult, char[] sError, int client)
{
    // Make sure the client didn't disconnect while the thread was running
    if(IsPlayerExist(client, false))
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
            gClientData[client].DataID = hResult.InsertId;
            gClientData[client].Money  = gCvarList[CVAR_ACCOUNT_CONNECT].IntValue;
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
 * @param client            Data passed in via the original threaded invocation.
 **/
public void SQLBaseUpdate_Callback(Database hDatabase, DBResultSet hResult, char[] sError, int client)
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
 * @param nColumn           The column type.
 * @param mFactory          The request type.
 * @param client            (Optional) The client index.
 * @param sData             (Optional) The string input.
 **/
void SQLBaseFactory__(bool MySQL = false, char[] sRequest, int iMaxLen, ColumnType nColumn, FactoryType mFactory, int client = 0, char[] sData = "")
{   
    // Gets factory mode
    switch(mFactory)
    {
        case FactoryType_Create :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `%s` ", DATABASE_MAIN);
            StrCat(sRequest, iMaxLen, 
            MySQL ? 
              "(`id` int(64) NOT NULL AUTO_INCREMENT, \
                `steam_id` varchar(32) NOT NULL, \
                `money` int(64) NOT NULL DEFAULT 0, \
                `level` int(64) NOT NULL DEFAULT 1, \
                `exp` int(64) NOT NULL DEFAULT 0, \
                `zombie` varchar(32) NOT NULL DEFAULT '', \
                `human` varchar(32) NOT NULL DEFAULT '', \
                `skin` varchar(32) NOT NULL DEFAULT '', \
                `vision` int(64) NOT NULL DEFAULT 1, \
                `time` int(64) NOT NULL DEFAULT 0, \
                PRIMARY KEY (`id`), \
                UNIQUE KEY `steam_id` (`steam_id`));"            
            : 
              "(`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
                `steam_id` TEXT UNIQUE NOT NULL, \
                `money` INTEGER NOT NULL DEFAULT 0, \
                `level` INTEGER NOT NULL DEFAULT 1, \
                `exp` INTEGER NOT NULL DEFAULT 0, \
                `zombie` TEXT NOT NULL DEFAULT '', \
                `human` TEXT NOT NULL DEFAULT '', \
                `skin` TEXT NOT NULL DEFAULT '', \
                `vision` INTEGER NOT NULL DEFAULT 1, \
                `time` INTEGER NOT NULL DEFAULT 0);");

            // Log database creation info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Main table \"%s\" was created/loaded. \"%s\" - \"%s\"", DATABASE_MAIN, MySQL ? "MySQL" : "SQlite", sRequest);
        }
        
        case FactoryType_Parent :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `%s`", DATABASE_CHILD);
            Format(sRequest, iMaxLen, 
            MySQL ? 
              "%s (`id` int(64) NOT NULL auto_increment, \
                   `client_id` int(32) NOT NULL, \
                   `weapon` varchar(32) NOT NULL DEFAULT '', \
                   PRIMARY KEY (`id`), \
                   FOREIGN KEY (`client_id`) REFERENCES `%s` (`id`));"            
            : 
              "%s (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
                   `client_id` INTEGER NOT NULL, \
                   `weapon` TEXT NOT NULL DEFAULT '', \
                   FOREIGN KEY (`client_id`) REFERENCES `%s` (`id`));",
            sRequest, DATABASE_MAIN);
            
            // Log database creation info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Child table \"%s\" was created/loaded. \"%s\" - \"%s\"", DATABASE_CHILD, MySQL ? "MySQL" : "SQlite", sRequest);
        }
        
        case FactoryType_Drop :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "DROP TABLE IF EXISTS `%s`;", DATABASE_MAIN);
            
            // Log database dropping info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Table \"%s\" was dropped. \"%s\"", DATABASE_MAIN, sRequest);
        }
        
        case FactoryType_Dump :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, MySQL ? "DESCRIBE `%s`;" : "PRAGMA table_info(`%s`);", DATABASE_MAIN);
            
            // Log database dumping info
            LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Table \"%s\" was dumped. \"%s\"", DATABASE_MAIN, sRequest);
        }
        
        case FactoryType_Keys :
        {
             /// Format request
             FormatEx(sRequest, iMaxLen, MySQL ? "SET FOREIGN_KEY_CHECKS = 1;" : "PRAGMA foreign_keys = ON;");
        }
        
        case FactoryType_Add :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "ALTER TABLE `%s` ", DATABASE_MAIN);
            switch(nColumn)
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
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER NOT NULL ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"money\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Level :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `level` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER NOT NULL ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 1;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"level\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Exp :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `exp` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER NOT NULL ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"exp\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Zombie :
                {
                    StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `zombie` varchar(32) NOT NULL DEFAULT '';" : "ADD COLUMN `zombie` TEXT NOT NULL DEFAULT '';");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"zombie\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Human :
                {
                    StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `human` varchar(32) NOT NULL DEFAULT '';" : "ADD COLUMN `human` TEXT NOT NULL DEFAULT '';");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"human\" was added. \"%s\"", sRequest);
                }

                case ColumnType_Costume :
                {
                    StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `skin` varchar(32) NOT NULL DEFAULT '';" : "ADD COLUMN `skin` TEXT NOT NULL DEFAULT '';");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"costume\" was added. \"%s\"", sRequest);
                }
                
                case ColumnType_Vision :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `vision` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER NOT NULL ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 1;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"vision\" was added. \"%s\"", sRequest);
                }

                case ColumnType_Time :
                {
                    StrCat(sRequest, iMaxLen, "ADD COLUMN `time` ");
                    StrCat(sRequest, iMaxLen, MySQL ? "int(64) NOT NULL " : "INTEGER NOT NULL ");
                    StrCat(sRequest, iMaxLen, "DEFAULT 0;");
                    
                    // Log database adding info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"time\" was added. \"%s\"", sRequest);
                }
            }
        }

        case FactoryType_Remove :
        {
            /// Format request
            if(MySQL)
            {
                FormatEx(sRequest, iMaxLen, "ALTER TABLE `%s` DROP COLUMN `%s`;", DATABASE_MAIN, sData);
            }
            else
            {
                /// @brief Backup table and rename.
                /// @link https://grasswiki.osgeo.org/wiki/Sqlite_Drop_Column
                switch(client)
                {
                    case 0 : FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `backup` \
                                                          (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
                                                          `steam_id` TEXT UNIQUE NOT NULL, \
                                                          `money` INTEGER NOT NULL DEFAULT 0, \
                                                          `level` INTEGER NOT NULL DEFAULT 1, \
                                                          `exp` INTEGER NOT NULL DEFAULT 0, \
                                                          `zombie` TEXT NOT NULL DEFAULT '', \
                                                          `human` TEXT NOT NULL DEFAULT '', \
                                                          `skin` TEXT NOT NULL DEFAULT '', \
                                                          `vision` INTEGER NOT NULL DEFAULT 1, \
                                                          `time` INTEGER NOT NULL DEFAULT 0);");
                    case 1 : FormatEx(sRequest, iMaxLen, "INSERT INTO `backup` SELECT \
                                                          `id`, `steam_id`, `money`, `level`, `exp`, `zombie`, `human`, `skin`, `vision`, `time` \
                                                          FROM `%s`;", DATABASE_MAIN);
                    case 2 : FormatEx(sRequest, iMaxLen, "DROP TABLE `%s`;", DATABASE_MAIN);                                  
                    case 3 : FormatEx(sRequest, iMaxLen, "ALTER TABLE `backup` RENAME TO `%s`;", DATABASE_MAIN);
                }
            }
        }

        case FactoryType_Select :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "SELECT ");    
            switch(nColumn)
            {
                case ColumnType_Default :
                {
                    StrCat(sRequest, iMaxLen, "*");
                
                    // Log database updation info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was found. \"%s\"", client, sRequest);
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
                    StrCat(sRequest, iMaxLen, "`zombie`");
                }
                
                case ColumnType_Human :
                {
                    StrCat(sRequest, iMaxLen, "`human`");
                }

                case ColumnType_Costume :
                {
                    StrCat(sRequest, iMaxLen, "`skin`");
                }
                
                case ColumnType_Vision :
                {
                    StrCat(sRequest, iMaxLen, "`vision`");
                }

                case ColumnType_Time :
                {
                    StrCat(sRequest, iMaxLen, "`time`");
                }
                
                /* Child table */
                case ColumnType_Weapon :
                {
                    StrCat(sRequest, iMaxLen, "`weapon`"); /// If client wouldn't has the id, it will not throw errors
                    Format(sRequest, iMaxLen, "%s FROM `%s` WHERE `client_id`= %d", sRequest, DATABASE_CHILD, gClientData[client].DataID);
                    return;
                }
            }
            Format(sRequest, iMaxLen, "%s FROM `%s`", sRequest, DATABASE_MAIN);
            
            // Validate row id
            if(gClientData[client].DataID < 1)
            {
                Format(sRequest, iMaxLen, "%s WHERE `steam_id` = '%s';", sRequest, SteamID[client]);
            }
            else
            {
                Format(sRequest, iMaxLen, "%s WHERE `id` = %d;", sRequest, gClientData[client].DataID);
            }
        }
        
        case FactoryType_Update :
        {
            static char sBuffer[3][SMALL_LINE_LENGTH];
        
            /// Format request
            FormatEx(sRequest, iMaxLen, "UPDATE `%s` SET", DATABASE_MAIN);    
            switch(nColumn)
            {
                case ColumnType_Default :
                {
                    ClassGetName(gClientData[client].ZombieClassNext, sBuffer[0], sizeof(sBuffer[]));
                    ClassGetName(gClientData[client].HumanClassNext, sBuffer[1], sizeof(sBuffer[]));
                    CostumesGetName(gClientData[client].Costume, sBuffer[2], sizeof(sBuffer[]));

                    Format(sRequest, iMaxLen, "%s `money` = %d, \
                                                  `level` = %d, \
                                                  `exp` = %d, \
                                                  `zombie` = '%s', \
                                                  `human` = '%s', \
                                                  `skin` = '%s', \
                                                  `vision` = %d, \
                                                  `time` = %d",
                    sRequest, gClientData[client].Money, gClientData[client].Level, gClientData[client].Exp, sBuffer[0], sBuffer[1], sBuffer[2], gClientData[client].Vision, GetTime());

                    // Log database updation info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was stored. \"%s\"", client, sRequest); 
                }
                
                case ColumnType_Money :
                {
                    Format(sRequest, iMaxLen, "%s `money` = %d", sRequest, gClientData[client].Money);
                }
                
                case ColumnType_Level :
                {
                    Format(sRequest, iMaxLen, "%s `level` = %d", sRequest, gClientData[client].Level);
                }
                
                case ColumnType_Exp :
                {
                    Format(sRequest, iMaxLen, "%s `exp` = %d", sRequest, gClientData[client].Exp);
                }
                
                case ColumnType_Zombie :
                {
                    ClassGetName(gClientData[client].ZombieClassNext, sBuffer[0], sizeof(sBuffer[]));
         
                    Format(sRequest, iMaxLen, "%s `zombie` = '%s'", sRequest, sBuffer[0]);
                }
                
                case ColumnType_Human :
                {
                    ClassGetName(gClientData[client].HumanClassNext, sBuffer[1], sizeof(sBuffer[]));
         
                    Format(sRequest, iMaxLen, "%s `human` = '%s'", sRequest, sBuffer[1]);
                }

                case ColumnType_Costume :
                {
                    CostumesGetName(gClientData[client].Costume, sBuffer[2], sizeof(sBuffer[]));
                    
                    Format(sRequest, iMaxLen, "%s `skin` = '%s'", sRequest, sBuffer[2]);
                }
                
                case ColumnType_Vision :
                {
                    Format(sRequest, iMaxLen, "%s `vision` = %d", sRequest, gClientData[client].Vision);
                }

                case ColumnType_Time :
                {
                    Format(sRequest, iMaxLen, "%s `time` = %d", sRequest, GetTime()); /// Gets system time as a unix timestamp
                }
            }
            
            // Validate row id
            if(gClientData[client].DataID < 1)
            {
                Format(sRequest, iMaxLen, "%s WHERE `steam_id` = '%s';", sRequest, SteamID[client]);
            }
            else
            {
                Format(sRequest, iMaxLen, "%s WHERE `id` = %d;", sRequest, gClientData[client].DataID);
            }
        }
        
        case FactoryType_Insert :
        {
            /// Format request
            switch(nColumn)
            {
                case ColumnType_SteamID :
                {
                    FormatEx(sRequest, iMaxLen, "INSERT INTO `%s` (`steam_id`) VALUES ('%s');", DATABASE_MAIN, SteamID[client]);
                    
                    // Log database insertion info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was inserted. \"%s\"", client, sRequest);
                }
                
                case ColumnType_Weapon :
                {
                    FormatEx(sRequest, iMaxLen, "INSERT INTO `%s` (`client_id`, `weapon`) VALUES (%d, '%s');", DATABASE_CHILD, gClientData[client].DataID, sData);
            
                    // Log database insertion info
                    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was inserted. \"%s\"", client, sRequest);
                }
            }
        }
        
        case FactoryType_Delete :
        {
            /// Format request
            FormatEx(sRequest, iMaxLen, "DELETE FROM `%s` WHERE `client_id` = %d AND `weapon` = '%s';", DATABASE_CHILD, gClientData[client].DataID, sData);
        }
    }
}