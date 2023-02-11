/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          database.sp
 *  Type:          Main 
 *  Description:   MySQL/SQlite database storage.
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
 * @section Properties of the database.
 **/ 
#define DATABASE_SECTION     "zombiedatabase"
#define DATABASE_MAIN        "zombieplague"
#define DATABASE_ITEMS       "zombieitems" // favorites
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
	ColumnType_AccountID,
	ColumnType_Money,
	ColumnType_Level,
	ColumnType_Exp,
	ColumnType_Zombie,
	ColumnType_Human,
	ColumnType_Costume,
	ColumnType_Vision,
	ColumnType_Time,
	ColumnType_Items,
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
	FactoryType_AddU, /// SQLite add unique column
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
 * Array to store the client id strings.
 **/
char gClientID[MAXPLAYERS+1][SMALL_LINE_LENGTH]; 

/**
 * @brief Database module init function.
 **/
void DataBaseOnInit()
{
	if (!gCvarList.DATABASE.IntValue)
	{
		if (gServerData.DBI != null)
		{
			if (gServerData.MapLoaded)
			{    
				DataBaseOnUnload();
			}
			
			RemoveCommandListener2(DataBaseOnCommandListened, "exit");
			RemoveCommandListener2(DataBaseOnCommandListened, "quit");
			RemoveCommandListener2(DataBaseOnCommandListened, "restart");
			RemoveCommandListener2(DataBaseOnCommandListened, "_restart");
			
			delete gServerData.DBI;
			delete gServerData.Cols;
			delete gServerData.Columns;
		}
		return;
	}
	
	if (gServerData.Cols == null)
	{        
		gServerData.Cols = new StringMap();
		
		gServerData.Cols.SetValue("id", ColumnType_ID);
		gServerData.Cols.SetValue("account_id", ColumnType_AccountID);
		gServerData.Cols.SetValue("money", ColumnType_Money);
		gServerData.Cols.SetValue("level", ColumnType_Level);
		gServerData.Cols.SetValue("exp", ColumnType_Exp);
		gServerData.Cols.SetValue("zombie", ColumnType_Zombie); 
		gServerData.Cols.SetValue("human", ColumnType_Human); 
		gServerData.Cols.SetValue("skin", ColumnType_Costume);
		gServerData.Cols.SetValue("vision", ColumnType_Vision); 
		gServerData.Cols.SetValue("time", ColumnType_Time);

		gServerData.Columns = gServerData.Cols.Snapshot();
	}

	Database.Connect(SQLBaseConnect_Callback, DATABASE_SECTION, (gCvarList.DATABASE.IntValue == DatabaseType_Drop));

	if (gServerData.MapLoaded)
	{
		DataBaseOnLoad();
	}
	
	AddCommandListener(DataBaseOnCommandListened, "exit");
	AddCommandListener(DataBaseOnCommandListened, "quit");
	AddCommandListener(DataBaseOnCommandListened, "restart");
	AddCommandListener(DataBaseOnCommandListened, "_restart");
}

/**
 * @brief Database module load function.
 **/
void DataBaseOnLoad()
{
	if (gServerData.DBI == null)
	{
		return;
	}

	static char sRequest[HUGE_LINE_LENGTH]; 

	Transaction hTxn = new Transaction();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (gClientData[i].Loaded)
		{
			continue;
		}

		if (IsPlayerExist(i, false) && !IsFakeClient(i))
		{
			if (gClientData[i].AccountID)
			{ 
				SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Select, i);
				hTxn.AddQuery(sRequest, i);
			}
			else
			{
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "SteamID Validation", "Player: \"%N\" - doesn't have an account (steam) id", i);
			}
		}
	}
	
	gServerData.DBI.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Load, DBPrio_Low); 
}

/**
 * @brief Database module unload function.
 **/
void DataBaseOnUnload()
{
	if (gServerData.DBI == null)
	{
		return;
	}

	static char sRequest[HUGE_LINE_LENGTH]; 

	Transaction hTxn = new Transaction();
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!gClientData[i].Loaded)
		{
			continue;
		}
	
		SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Update, i);
		hTxn.AddQuery(sRequest, i);
		
		gClientData[i].Loaded = false;
		gClientData[i].DataID = -1;
	}

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
	if (!entity)
	{
		switch (commandMsg[0])
		{
			case 'e', 'q', 'r', '_' : 
			{
				DataBaseOnUnload();
			}
		}
	}

	return Plugin_Continue;
}

/**
 * @brief Hook database cvar changes.
 **/
void DataBaseOnCvarInit()
{    
	gCvarList.DATABASE = FindConVar("zp_database");  

	HookConVarChange(gCvarList.DATABASE, DataBaseOnCvarHook);
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
	if (!strcmp(oldValue, newValue, false))
	{
		return;
	}
	
	DataBaseOnInit();
}

/**
 * @brief Client has been joined.
 * 
 * @param client            The client index. 
 **/
void DataBaseOnClientInit(int client)
{
	if (IsFakeClient(client))
	{
		GetClientName(client, gClientID[client], sizeof(gClientID[]));
		return;
	}
	
	gClientData[client].AccountID = GetSteamAccountID(client);

	IntToString(gClientData[client].AccountID, gClientID[client], sizeof(gClientID[]));

	if (gServerData.DBI == null)
	{
		return;
	}
	
	if (gClientData[client].AccountID)
	{
		static char sRequest[HUGE_LINE_LENGTH];
		SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Select, client);
		
		gServerData.DBI.Query(SQLBaseSelect_Callback, sRequest, client, DBPrio_High);
	}
	else
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "SteamID Validation", "Player: \"%N\" - doesn't have an account (steam) id", client);
	}
}

/**
 * @brief Called when a client is disconnected from the server.
 *
 * @param client            The client index.
 **/
void DataBaseOnClientDisconnectPost(int client)
{
	DataBaseOnClientUpdate(client, ColumnType_Default);
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
	if (gServerData.DBI == null)
	{
		return;
	}
	
	if (!gClientData[client].Loaded)
	{
		return;
	}

	static char sRequest[HUGE_LINE_LENGTH]; 
	SQLBaseFactory__(_, sRequest, sizeof(sRequest), nColumn, mFactory, client, sData);
	
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
	switch (mTransaction)
	{
		/*
			case TransactionType_Create :
			case TransactionType_Unload :
		*/
		
		case TransactionType_Load :
		{
			for (int i = 0; i < numQueries; i++)
			{
				SQLBaseSelect_Callback(hDatabase, hResults[i], "", client[i]);
			}
		}

		case TransactionType_Describe, TransactionType_Info :
		{
			if (numQueries <= view_as<int>(TransactionType_Info)) /// If drop include, then stop
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
	if (hDatabase == null || hasLength(sError))
	{
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
	if (hDatabase == null || hasLength(sError))
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
	}
	else
	{
		if (gServerData.DBI != null)
		{
			if (hDatabase.IsSameConnection(gServerData.DBI))
			{
				return;
			}
			
			delete gServerData.DBI;
		}

		gServerData.DBI = hDatabase;
		
		/*______________________________________________________________________________*/
		
		Transaction hTxn = new Transaction();

		static char sRequest[HUGE_LINE_LENGTH]; 
		
		if (bDropping)
		{
			SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Drop);
			hTxn.AddQuery(sRequest);
		}
		
		DBDriver hDriver = gServerData.DBI.Driver;
		static char sDriver[SMALL_LINE_LENGTH]; 
		hDriver.GetIdentifier(sDriver, sizeof(sDriver));
		delete hDriver;

		bool MySQL = (sDriver[0] == 'm'); 

		static const FactoryType mFactory[4] = { FactoryType_Create, FactoryType_Dump, FactoryType_Keys, FactoryType_Parent };
		for (int x = 0; x < sizeof(mFactory); x++)
		{        
			SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_Default, mFactory[x]);
			hTxn.AddQuery(sRequest);
		}

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
	static char sColumn[SMALL_LINE_LENGTH]; ColumnType nColumn;
	
	ArrayList hList = new ArrayList(SMALL_LINE_LENGTH);
	
	while (hResult.FetchRow())
	{
		hResult.FetchString(!MySQL, sColumn, sizeof(sColumn));

		if (hList.FindString(sColumn) == -1)
		{
			hList.PushString(sColumn);
		}
	}
	
	Transaction hTxn = new Transaction();

	static char sRequest[HUGE_LINE_LENGTH]; 
	
	int iSize = gServerData.Cols.Size;
	for (int i = 0; i < iSize; i++)
	{
		gServerData.Columns.GetKey(i, sColumn, sizeof(sColumn));
		
		if (hList.FindString(sColumn) == -1)
		{
			gServerData.Cols.GetValue(sColumn, nColumn);
			
			if (nColumn == ColumnType_AccountID && !MySQL)
			{
				for (int x = 0; x < 4; x++)
				{
					SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), nColumn, FactoryType_AddU, x);
					hTxn.AddQuery(sRequest);
				}
				
				hList.Erase(hList.FindString("steam_id"));
			}
			else
			{
				SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), nColumn, FactoryType_Add);
				hTxn.AddQuery(sRequest);
				
				if (nColumn == ColumnType_AccountID) 
				{
					SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), nColumn, FactoryType_Update);
					hTxn.AddQuery(sRequest);
				}
			}
		}
	}

	iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		hList.GetString(i, sColumn, sizeof(sColumn));
		
		if (!gServerData.Cols.GetValue(sColumn, nColumn))
		{
			if (MySQL)
			{
				SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Remove, _, sColumn);
				hTxn.AddQuery(sRequest);
			}
			else
			{
				for (int x = 0; x < 4; x++)
				{
					SQLBaseFactory__(MySQL, sRequest, sizeof(sRequest), ColumnType_Default, FactoryType_Remove, x);
					hTxn.AddQuery(sRequest);
				}
				
				break;
			}
		}
	}
	
	gServerData.DBI.Execute(hTxn, SQLTxnSuccess_Callback, SQLTxnFailure_Callback, TransactionType_Create, DBPrio_Normal); 
	
	delete hList;
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
	if (IsPlayerExist(client, false))
	{
		if (hDatabase == null || hResult == null || hasLength(sError))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
		}
		else
		{
			static char sRequest[HUGE_LINE_LENGTH]; 

			if (hResult.FetchRow())
			{
				static char sColumn[SMALL_LINE_LENGTH]; ColumnType nColumn; int iD;
 
				int iCount = hResult.FieldCount;
				for (int i = 0; i < iCount; i++)
				{
					hResult.FieldNumToName(i, sColumn, sizeof(sColumn));

					if (gServerData.Cols.GetValue(sColumn, nColumn))
					{
						switch (nColumn)
						{
							case ColumnType_ID :     gClientData[client].DataID = hResult.FetchInt(i); 
							case ColumnType_Money :  gClientData[client].Money  = hResult.FetchInt(i); 
							case ColumnType_Level :  gClientData[client].Level  = hResult.FetchInt(i);
							case ColumnType_Exp :    gClientData[client].Exp    = hResult.FetchInt(i); 
							case ColumnType_Zombie :
							{
								hResult.FetchString(i, sColumn, sizeof(sColumn)); iD = ClassNameToIndex(sColumn);
								gClientData[client].ZombieClassNext = (iD != -1) ? iD : 0;
							}
							case ColumnType_Human :
							{
								hResult.FetchString(i, sColumn, sizeof(sColumn)); iD = ClassNameToIndex(sColumn);
								gClientData[client].HumanClassNext  = (iD != -1) ? iD : 0;
							}
							case ColumnType_Costume :
							{
								if (!gCvarList.COSTUMES.BoolValue)
								{
									continue;
								}
								
								hResult.FetchString(i, sColumn, sizeof(sColumn));
								gClientData[client].Costume = CostumesNameToIndex(sColumn);
							}
							case ColumnType_Vision : gClientData[client].Vision = view_as<bool>(hResult.FetchInt(i));
							case ColumnType_Time :   gClientData[client].Time   = hResult.FetchInt(i);
						}
					}
				}
				
				SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_Items, FactoryType_Select, client);
				gServerData.DBI.Query(SQLBaseExtract_Callback, sRequest, client, DBPrio_Normal); 
			}
			else
			{
				SQLBaseFactory__(_, sRequest, sizeof(sRequest), ColumnType_AccountID, FactoryType_Insert, client);
				gServerData.DBI.Query(SQLBaseInsert_Callback, sRequest, client, DBPrio_High); 
			}
			
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
	if (IsPlayerExist(client, false))
	{
		if (hDatabase == null || hResult == null || hasLength(sError))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
		}
		else
		{
			while (hResult.FetchRow())
			{
				static char sItem[SMALL_LINE_LENGTH];
				hResult.FetchString(0, sItem, sizeof(sItem));
				
				int iD = ItemsNameToIndex(sItem);
				if (iD != -1)
				{   
					if (gClientData[client].DefaultCart == null)
					{
						gClientData[client].DefaultCart = new ArrayList();
					}
			
					gClientData[client].DefaultCart.Push(iD);
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
	if (IsPlayerExist(client, false))
	{
		if (hDatabase == null || hResult == null || hasLength(sError))
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Database, "Query", "%s", sError);
		}
		else
		{
			gClientData[client].DataID = hResult.InsertId;
			gClientData[client].Money  = gCvarList.ACCOUNT_CONNECT.IntValue;
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
	if (hDatabase == null || hResult == null || hasLength(sError))
	{
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
	switch (mFactory)
	{
		case FactoryType_Create :
		{
			FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `%s` ", DATABASE_MAIN);
			StrCat(sRequest, iMaxLen, 
			MySQL ? 
			  "(`id` int(32) NOT NULL AUTO_INCREMENT, \
				`account_id` int(32) NOT NULL, \
				`money` int(32) NOT NULL DEFAULT 0, \
				`level` int(32) NOT NULL DEFAULT 1, \
				`exp` int(32) NOT NULL DEFAULT 0, \
				`zombie` varchar(32) NOT NULL DEFAULT '', \
				`human` varchar(32) NOT NULL DEFAULT '', \
				`skin` varchar(32) NOT NULL DEFAULT '', \
				`vision` int(32) NOT NULL DEFAULT 1, \
				`time` int(32) NOT NULL DEFAULT 0, \
				PRIMARY KEY (`id`), \
				UNIQUE KEY `account_id` (`account_id`));"            
			: 
			  "(`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
				`account_id` INTEGER UNIQUE NOT NULL, \
				`money` INTEGER NOT NULL DEFAULT 0, \
				`level` INTEGER NOT NULL DEFAULT 1, \
				`exp` INTEGER NOT NULL DEFAULT 0, \
				`zombie` TEXT NOT NULL DEFAULT '', \
				`human` TEXT NOT NULL DEFAULT '', \
				`skin` TEXT NOT NULL DEFAULT '', \
				`vision` INTEGER NOT NULL DEFAULT 1, \
				`time` INTEGER NOT NULL DEFAULT 0);");

			LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Main table \"%s\" was created/loaded. \"%s\" - \"%s\"", DATABASE_MAIN, MySQL ? "MySQL" : "SQlite", sRequest);
		}
		
		case FactoryType_Parent :
		{
			FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `%s`", DATABASE_ITEMS);
			Format(sRequest, iMaxLen, 
			MySQL ? 
			  "%s (`id` int(32) NOT NULL auto_increment, \
				   `client_id` int(32) NOT NULL, \
				   `item` varchar(32) NOT NULL DEFAULT '', \
				   PRIMARY KEY (`id`), \
				   FOREIGN KEY (`client_id`) REFERENCES `%s` (`id`));"            
			: 
			  "%s (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
				   `client_id` INTEGER NOT NULL, \
				   `item` TEXT NOT NULL DEFAULT '', \
				   FOREIGN KEY (`client_id`) REFERENCES `%s` (`id`));",
			sRequest, DATABASE_MAIN);
			
			LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Child table \"%s\" was created/loaded. \"%s\" - \"%s\"", DATABASE_ITEMS, MySQL ? "MySQL" : "SQlite", sRequest);
		}
		
		case FactoryType_Drop :
		{
			FormatEx(sRequest, iMaxLen, "DROP TABLE IF EXISTS `%s`;", DATABASE_MAIN);
			
			LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Table \"%s\" was dropped. \"%s\"", DATABASE_MAIN, sRequest);
		}
		
		case FactoryType_Dump :
		{
			FormatEx(sRequest, iMaxLen, MySQL ? "DESCRIBE `%s`;" : "PRAGMA table_info(`%s`);", DATABASE_MAIN);
			
			LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Table \"%s\" was dumped. \"%s\"", DATABASE_MAIN, sRequest);
		}
		
		case FactoryType_Keys :
		{
			 /// Format request
			 FormatEx(sRequest, iMaxLen, MySQL ? "SET FOREIGN_KEY_CHECKS = 1;" : "PRAGMA foreign_keys = ON;");
		}
		
		case FactoryType_Add :
		{
			FormatEx(sRequest, iMaxLen, "ALTER TABLE `%s` ", DATABASE_MAIN);
			switch (nColumn)
			{
				case ColumnType_ID :
				{
					StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `id` int(32) NOT NULL auto_increment, ADD PRIMARY KEY (`id`);" : "ADD COLUMN `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL;");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"id\" was added. \"%s\"", sRequest);
				}
				
				case ColumnType_AccountID :
				{
					StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `account_id` int(32) NOT NULL, ADD UNIQUE `account_id` (`account_id`);" : "ADD COLUMN `account_id` INTEGER UNIQUE NOT NULL;");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"account_id\" was added. \"%s\"", sRequest);
				}
				
				case ColumnType_Money :
				{
					StrCat(sRequest, iMaxLen, "ADD COLUMN `money` ");
					StrCat(sRequest, iMaxLen, MySQL ? "int(32) NOT NULL " : "INTEGER NOT NULL ");
					StrCat(sRequest, iMaxLen, "DEFAULT 0;");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"money\" was added. \"%s\"", sRequest);
				}
				
				case ColumnType_Level :
				{
					StrCat(sRequest, iMaxLen, "ADD COLUMN `level` ");
					StrCat(sRequest, iMaxLen, MySQL ? "int(32) NOT NULL " : "INTEGER NOT NULL ");
					StrCat(sRequest, iMaxLen, "DEFAULT 1;");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"level\" was added. \"%s\"", sRequest);
				}
				
				case ColumnType_Exp :
				{
					StrCat(sRequest, iMaxLen, "ADD COLUMN `exp` ");
					StrCat(sRequest, iMaxLen, MySQL ? "int(32) NOT NULL " : "INTEGER NOT NULL ");
					StrCat(sRequest, iMaxLen, "DEFAULT 0;");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"exp\" was added. \"%s\"", sRequest);
				}
				
				case ColumnType_Zombie :
				{
					StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `zombie` varchar(32) NOT NULL DEFAULT '';" : "ADD COLUMN `zombie` TEXT NOT NULL DEFAULT '';");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"zombie\" was added. \"%s\"", sRequest);
				}
				
				case ColumnType_Human :
				{
					StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `human` varchar(32) NOT NULL DEFAULT '';" : "ADD COLUMN `human` TEXT NOT NULL DEFAULT '';");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"human\" was added. \"%s\"", sRequest);
				}

				case ColumnType_Costume :
				{
					StrCat(sRequest, iMaxLen, MySQL ? "ADD COLUMN `skin` varchar(32) NOT NULL DEFAULT '';" : "ADD COLUMN `skin` TEXT NOT NULL DEFAULT '';");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"costume\" was added. \"%s\"", sRequest);
				}
				
				case ColumnType_Vision :
				{
					StrCat(sRequest, iMaxLen, "ADD COLUMN `vision` ");
					StrCat(sRequest, iMaxLen, MySQL ? "int(32) NOT NULL " : "INTEGER NOT NULL ");
					StrCat(sRequest, iMaxLen, "DEFAULT 1;");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"vision\" was added. \"%s\"", sRequest);
				}

				case ColumnType_Time :
				{
					StrCat(sRequest, iMaxLen, "ADD COLUMN `time` ");
					StrCat(sRequest, iMaxLen, MySQL ? "int(32) NOT NULL " : "INTEGER NOT NULL ");
					StrCat(sRequest, iMaxLen, "DEFAULT 0;");
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Column \"time\" was added. \"%s\"", sRequest);
				}
			}
		}
		
		case FactoryType_AddU : /// Until a new version will be here
		{
			switch (client)
			{
				case 0 : FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `backup` \
													  (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
													  `account_id` INTEGER UNIQUE NOT NULL, \
													  `money` INTEGER NOT NULL DEFAULT 0, \
													  `level` INTEGER NOT NULL DEFAULT 1, \
													  `exp` INTEGER NOT NULL DEFAULT 0, \
													  `zombie` TEXT NOT NULL DEFAULT '', \
													  `human` TEXT NOT NULL DEFAULT '', \
													  `skin` TEXT NOT NULL DEFAULT '', \
													  `vision` INTEGER NOT NULL DEFAULT 1, \
													  `time` INTEGER NOT NULL DEFAULT 0);");
				case 1 : FormatEx(sRequest, iMaxLen, "INSERT INTO `backup` SELECT \
													  `id`, (CAST(SUBSTR(`steam_id`, 11) AS INTEGER) * 2 + CAST(SUBSTR(`steam_id`, 9, 1) AS INTEGER)), \
													  `money`, `level`, `exp`, `zombie`, `human`, `skin`, `vision`, `time` \
													  FROM `%s`;", DATABASE_MAIN); 
				case 2 : FormatEx(sRequest, iMaxLen, "DROP TABLE `%s`;", DATABASE_MAIN);                                  
				case 3 : FormatEx(sRequest, iMaxLen, "ALTER TABLE `backup` RENAME TO `%s`;", DATABASE_MAIN);
			}
		}

		case FactoryType_Remove :
		{
			if (MySQL)
			{
				FormatEx(sRequest, iMaxLen, "ALTER TABLE `%s` DROP COLUMN `%s`;", DATABASE_MAIN, sData);
			}
			else
			{
				switch (client)
				{
					case 0 : FormatEx(sRequest, iMaxLen, "CREATE TABLE IF NOT EXISTS `backup` \
														  (`id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
														  `account_id` INTEGER UNIQUE NOT NULL, \
														  `money` INTEGER NOT NULL DEFAULT 0, \
														  `level` INTEGER NOT NULL DEFAULT 1, \
														  `exp` INTEGER NOT NULL DEFAULT 0, \
														  `zombie` TEXT NOT NULL DEFAULT '', \
														  `human` TEXT NOT NULL DEFAULT '', \
														  `skin` TEXT NOT NULL DEFAULT '', \
														  `vision` INTEGER NOT NULL DEFAULT 1, \
														  `time` INTEGER NOT NULL DEFAULT 0);");
					case 1 : FormatEx(sRequest, iMaxLen, "INSERT INTO `backup` SELECT \
														  `id`, `account_id`, `money`, `level`, `exp`, `zombie`, `human`, `skin`, `vision`, `time` \
														  FROM `%s`;", DATABASE_MAIN);
					case 2 : FormatEx(sRequest, iMaxLen, "DROP TABLE `%s`;", DATABASE_MAIN);                                  
					case 3 : FormatEx(sRequest, iMaxLen, "ALTER TABLE `backup` RENAME TO `%s`;", DATABASE_MAIN);
				}
			}
		}

		case FactoryType_Select :
		{
			FormatEx(sRequest, iMaxLen, "SELECT ");    
			switch (nColumn)
			{
				case ColumnType_Default :
				{
					StrCat(sRequest, iMaxLen, "*");
				
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
				case ColumnType_Items :
				{
					StrCat(sRequest, iMaxLen, "`item`"); /// If client wouldn't has the id, it will not throw errors
					Format(sRequest, iMaxLen, "%s FROM `%s` WHERE `client_id`= %d", sRequest, DATABASE_ITEMS, gClientData[client].DataID);
					return;
				}
			}
			Format(sRequest, iMaxLen, "%s FROM `%s`", sRequest, DATABASE_MAIN);
			
			if (gClientData[client].DataID < 1)
			{
				Format(sRequest, iMaxLen, "%s WHERE `account_id` = %d;", sRequest, gClientData[client].AccountID);
			}
			else
			{
				Format(sRequest, iMaxLen, "%s WHERE `id` = %d;", sRequest, gClientData[client].DataID);
			}
		}
		
		case FactoryType_Update :
		{
			static char sBuffer[3][SMALL_LINE_LENGTH];
		
			FormatEx(sRequest, iMaxLen, "UPDATE `%s` SET", DATABASE_MAIN);    
			switch (nColumn)
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

					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was stored. \"%s\"", client, sRequest); 
				}
				
				case ColumnType_AccountID :
				{
					Format(sRequest, iMaxLen, "%s `account_id` = (SELECT CAST(SUBSTR(`steam_id`, 11) AS UNSIGNED) * 2 + CAST(SUBSTR(`steam_id`, 9, 1) AS UNSIGNED));", sRequest);
					return;
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
			
			if (gClientData[client].DataID < 1)
			{
				Format(sRequest, iMaxLen, "%s WHERE `account_id` = %d;", sRequest, gClientData[client].AccountID);
			}
			else
			{
				Format(sRequest, iMaxLen, "%s WHERE `id` = %d;", sRequest, gClientData[client].DataID);
			}
		}
		
		case FactoryType_Insert :
		{
			switch (nColumn)
			{
				case ColumnType_AccountID :
				{
					FormatEx(sRequest, iMaxLen, "INSERT INTO `%s` (`account_id`) VALUES (%d);", DATABASE_MAIN, gClientData[client].AccountID);
					
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was inserted. \"%s\"", client, sRequest);
				}
				
				case ColumnType_Items :
				{
					FormatEx(sRequest, iMaxLen, "INSERT INTO `%s` (`client_id`, `item`) VALUES (%d, '%s');", DATABASE_ITEMS, gClientData[client].DataID, sData);
			
					LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Database, "Query", "Player \"%N\" was inserted. \"%s\"", client, sRequest);
				}

			}
		}

		case FactoryType_Delete :
		{
			FormatEx(sRequest, iMaxLen, "DELETE FROM `%s` WHERE `client_id` = %d AND `item` = '%s';", DATABASE_ITEMS, gClientData[client].DataID, sData);
		}
	}
}