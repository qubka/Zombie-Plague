/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

// Define for deleting database each map
//#define DROPPING

/**
 * Record plugin info.
 **/
public Plugin DataBase =
{
	name        	= "[ZP] Addon: DataBase",
	author      	= "qubka (Nikita Ushakov)", 	
	description 	= "MYSQL or SQlite database for ammopacks, level, exp",
	version     	= "6.0",
	url         	= "https://forums.alliedmods.net/showthread.php?t=290657"
}
 
/**
 * Name of database section in the database.cfg
 **/
#define AMMOPACK_BLOCK_DATABASE 		"zombiedatabase"

/**
 * Amount of variables for new player.
 **/
#define DEFAULT_AMMOPACK	50
#define DEFAULT_LEVEL		1
#define DEFAULT_EXP			0

/**
 * Steam ID length.
 **/
#define STEAMID_MAX_LENGTH 	32

// Handle for database
Handle hDataBase = INVALID_HANDLE;

// Arrays for storing ID in the SQL base
char SteamID[MAXPLAYERS+1][STEAMID_MAX_LENGTH];
int  DataID[MAXPLAYERS+1];
bool IsLoaded[MAXPLAYERS+1];

/**
 * Create a SQL database connection.
 **/
public void OnConfigsExecuted(/*void*/)
{
	// Close database handle, if it was already created
	if(hDataBase != INVALID_HANDLE)
	{
		delete hDataBase;
	}
	
	// Returns if a named configuration is present in databases.cfg.
	if(SQL_CheckConfig(AMMOPACK_BLOCK_DATABASE))
	{
		// Initialize chars
		char sError[BIG_LINE_LENGTH];
		char sDriver[SMALL_LINE_LENGTH]; 
		char sRequest[PLATFORM_MAX_PATH];
		
		// Creates an SQL connection from a named configuration
		hDataBase = SQL_Connect(AMMOPACK_BLOCK_DATABASE, false, sError, sizeof(sError));

		// If base doesn't exist or mod can't make connection
		if(hDataBase == INVALID_HANDLE)
		{
			SetFailState(sError);
			return;
		}
		
		// Reads the driver of an opened database
		SQL_ReadDriver(hDataBase, sDriver, sizeof(sDriver)); 
		
		// If driver is a MySQL
		bool MySQLDataBase = StrEqual(sDriver, "mysql", false);
		
		// Block sql base from the other requests
		SQL_LockDatabase(hDataBase);
		
		// Delete existing database if dropping enable
		#if defined DROPPING
			// Format request
			Format(sRequest, sizeof(sRequest), "DROP TABLE IF EXISTS `zombieplague_database`");
			
			// Sent a request
			if(!SQL_FastQuery(hDataBase, sRequest))
			{
				// Get an error, if it exist
				SQL_GetError(hDataBase, sError, sizeof(sError));
				
				// Log error and stop server
				SetFailState("%s in request: \"%s\"", sError, sRequest);
				return;
			}
		#endif
		
		// Format request
		if(MySQLDataBase)
		{
			Format(sRequest, sizeof(sRequest), "CREATE TABLE IF NOT EXISTS `zombieplague_database` (`id` int(64) NOT NULL auto_increment, `steam_id` varchar(32) NOT NULL, `money` int(64) NOT NULL, `level` int(64) NOT NULL, `exp` int(64) NOT NULL, PRIMARY KEY  (`id`), UNIQUE KEY `steam_id` (`steam_id`))");
		}
		else
		{
			Format(sRequest, sizeof(sRequest), "CREATE TABLE IF NOT EXISTS `zombieplague_database` (id INTEGER PRIMARY KEY AUTOINCREMENT, steam_id TEXT UNIQUE, money INTEGER, level INTEGER, exp INTEGER)");
		}
		
		// Sent a request
		if(!SQL_FastQuery(hDataBase, sRequest))
		{
			// Get an error, if it exist
			SQL_GetError(hDataBase, sError, sizeof(sError));
			
			// Log error and stop server
			SetFailState("%s in request: \"%s\"", sError, sRequest);
			return;
		}

		// Unlock it
		SQL_UnlockDatabase(hDataBase);
	}
	else
	{
		SetFailState("Section \"%s\" doesn't found in databases.cfg", AMMOPACK_BLOCK_DATABASE);
	}
}



/**
 * SQL functions, which work with the client.
 **/
 
 
 
/**
 * Called when a client is disconnecting from the server.
 *
 * @param clientIndex		The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
	#pragma unused clientIndex
	
	// If client wasn't load, then stop
	if(!IsLoaded[clientIndex])
	{
		return;
	}
	
	// Update ammopacks in database
	SaveClientInfo(clientIndex);
	
	// Reset client's variables
	DataID[clientIndex] = -1;
	IsLoaded[clientIndex] = false;
}

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex		The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
	#pragma unused clientIndex
	
	// Reset client's variables
	DataID[clientIndex] = -1;
	IsLoaded[clientIndex] = false;
	
	// If database doesn't exist, then stop
	if(hDataBase == INVALID_HANDLE)
	{
		return;
	}
	
	// Verify that the client is non-bot
	if(IsFakeClient(clientIndex))
	{
		return;
	}
	
	// Initialize reqest char
	static char sRequest[PLATFORM_MAX_PATH];
	
	// Get client's authentication string (SteamID)
	if(!GetClientAuthId(clientIndex, AuthId_Steam2, SteamID[clientIndex], sizeof(SteamID[])))
	{
		return;
	}

	// Format request
	Format(sRequest, sizeof(sRequest), "SELECT id, money, level, exp FROM `zombieplague_database` WHERE steam_id = '%s'", SteamID[clientIndex]);
	
	// Sent a request
	SQL_TQuery(hDataBase, SQLBaseExtract_Callback, sRequest, GetClientUserId(clientIndex));
}

/**
 * General callback for threaded SQL stuff
 *
 * @param hDriver			Parent object of the handle.
 * @param hResult			Handle to the child object.
 * @param sSQLerror			Error string if there was an error.
 * @param clientID			Data passed in via the original threaded invocation.
 **/
public void SQLBaseExtract_Callback(Handle hDriver, Handle hResult, const char[] sSQLerror, any clientID)
{
	// Get real player index from event key
	int clientIndex = GetClientOfUserId(clientID);

	#pragma unused clientIndex
	
	// Make sure the client didn't disconnect while the thread was running
	if(clientIndex)
	{
		// If invalid query handle
		if(hResult == INVALID_HANDLE)
		{
			LogError(sSQLerror);
			return;
		}
		else
		{
			// Client was found, get ammopacks from the table
			if(SQL_FetchRow(hResult))
			{
				// Get client ID in the row
				DataID[clientIndex] = SQL_FetchInt(hResult, 0); 
				
				// Set client loaded amount of ammopacks
				ZP_SetClientAmmoPack(clientIndex, SQL_FetchInt(hResult, 1));
				
				// Set client level
				ZP_SetClientLevel(clientIndex, SQL_FetchInt(hResult, 2));
				
				// Set client exp
				ZP_SetClientExp(clientIndex, SQL_FetchInt(hResult, 3));
				
				// Update ammopacks in database
				SaveClientInfo(clientIndex);
			}
			else
			{
				// Initialize reqest char
				char sRequest[PLATFORM_MAX_PATH];
				
				// Format request
				Format(sRequest, sizeof(sRequest), "INSERT INTO `zombieplague_database` (steam_id) VALUES ('%s')", SteamID[clientIndex]);
				
				// Block sql base from the other requests
				SQL_LockDatabase(hDataBase);
				
				// Sent a request
				if(!SQL_FastQuery(hDataBase, sRequest))
				{
					// Initialize char
					static char sError[BIG_LINE_LENGTH];
				
					// Get an error, if it exist
					SQL_GetError(hDataBase, sError, sizeof(sError));
					
					// Log error
					LogError("%s in request: \"%s\"", sError, sRequest);
				}
				
				// Unlock it
				SQL_UnlockDatabase(hDataBase);
				
				// Set starter client stats
				ZP_SetClientAmmoPack(clientIndex, DEFAULT_AMMOPACK);
				ZP_SetClientLevel(clientIndex, DEFAULT_LEVEL);
				ZP_SetClientExp(clientIndex, DEFAULT_EXP);
			}
			
			// Client was loaded
			IsLoaded[clientIndex] = true;
		}
	}
}

/**
 * Called for inserting amount of ammopacks in the SQL base.
 *
 * @param clientIndex		The client index.
 **/
void SaveClientInfo(int clientIndex)
{
	#pragma unused clientIndex
	
	// Initialize reqest char
	static char sRequest[PLATFORM_MAX_PATH];
	
	// Format request
	if(DataID[clientIndex] < 1)
	{
		Format(sRequest, sizeof(sRequest), "UPDATE `zombieplague_database` SET money = %d, level = %d, exp = %d WHERE steam_id = '%s'", ZP_GetClientAmmoPack(clientIndex), ZP_GetClientLevel(clientIndex), ZP_GetClientExp(clientIndex), SteamID[clientIndex]);
	}
	else
	{
		Format(sRequest, sizeof(sRequest), "UPDATE `zombieplague_database` SET money = %d, level = %d, exp = %d WHERE id = %d", ZP_GetClientAmmoPack(clientIndex), ZP_GetClientLevel(clientIndex), ZP_GetClientExp(clientIndex),  DataID[clientIndex]);
	}
	
	// Block sql base from the other requests
	SQL_LockDatabase(hDataBase);
	
	// Sent a request
	if(!SQL_FastQuery(hDataBase, sRequest))
	{
		// Initialize char
		static char sError[BIG_LINE_LENGTH];
	
		// Get an error, if it exist
		SQL_GetError(hDataBase, sError, sizeof(sError));
		
		// Log error
		LogError("%s in request: \"%s\"", sError, sRequest);
	}
	
	// Unlock it
	SQL_UnlockDatabase(hDataBase);
}