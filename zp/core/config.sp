/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          config.inc
 *  Type:          Core
 *  Description:   Config API and executing.
 *
 *  Copyright (C) 2015-2023 Greyscale, Richard Helgeby
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

/*
	Using config API:
	
	-Before any of these helper functions can be used on a config file you must
	 "register" the module handling the data.
	
	Example:
	
	ConfigRegisterConfig(File_Example, Structure_IntegerList, "example");
	
	* The first parameter of this call is the config file we want to register.
	  this needs to be listed in the "ConfigFile" enum in config.inc.
	  
	* The second parameter is the structure of the config file we are loading.
	  The supported structures are listed in the "ConfigStructure" enum in config.inc
	  
	* The last parameter is the file alias.  Or what we use to refer to the
	  config file from a non-developer point of view.  For example zp_config_reload
	  requires the file alias to identify the config file the user wants to reload.
	
	-Next we need to define the config file path.  To do this we first need to
	 retrieve the path file from cvar.
	 
	Example:
	
	ConfigSetConfigPath(File_Example, pathexample);
	
	* The first parameter is the config file we want to set path to.
	  
	* The second parameter is the path we want to set to the config file.
	
	-Next we load config file and prepare its nested array structure.
	
	Example:
	
	new bool:success = ConfigLoadConfig(File_Example, arrayExample);
	
	* The first parameter is the config file we want to load.
	  
	* The second parameter is the array handle we want to prepare data structure in.
	  
	* The return value is true if the file was successfully loaded, false if the
	  config file couldn't be loaded.  (Invalid data, missing quotes, brackets, etc)
	
	-Next validate the config so far, stopping if no data was found or if ConfigLoadConfig
	 returned false.
	
	-Then cache the config file data into the arrays (only for Keyvalue structures)
	 by iterating through the data and pushing the values into the array.
	
	-Validate the values of the data.
	
	-Lastly we need to set specific info to the module now that it has successfully
	 loaded.
	
	Example:
	
	ConfigSetConfigLoaded(File_Example, true);
	ConfigSetConfigReloadFunc(File_Example, GetFunctionByName(GetMyHandle(), "ExampleOnConfigReload"));
	ConfigSetConfigHandle(File_Example, arrayExample);
	
	These functions will modify the config file data for other things to use.
	(such as zp_config_reload)
	
	* The first function call will set the loaded state of the config file to
	  true, failing to do this will cause the config module to think your
	  config file isn't loaded, therefore causing some undesired erroring.
	  
	* The second function sets the reload function of the config file.  This
	  function will be called upon its config file being reloaded.
	  
	* The third function stores the array handle for use by other parts of the
	  module.
*/

/**
 * @section Config file aliases.
 **/
#define CONFIG_FILE_ALIAS_CVARS         "cfg"
#define CONFIG_FILE_ALIAS_DOWNLOADS     "downloads"
#define CONFIG_FILE_ALIAS_WEAPONS       "weapons"
#define CONFIG_FILE_ALIAS_SOUNDS        "sounds"
#define CONFIG_FILE_ALIAS_MENUS         "menus"
#define CONFIG_FILE_ALIAS_HITGROUPS     "hitgroups"
#define CONFIG_FILE_ALIAS_COSTUMES      "costumes"
#define CONFIG_FILE_ALIAS_EXTRAITEMS    "extraitems"    
#define CONFIG_FILE_ALIAS_GAMEMODES     "gamemodes"
#define CONFIG_FILE_ALIAS_CLASSES       "classes"
#define CONFIG_FILE_ALIAS_LEVELS        "levels"
#define CONFIG_FILE_ALIAS_MAPS          "maps"
#define CONFIG_PATH_DEFAULT             "zombieplague"
/**
 * @endsection
 **/

/**
 * @section List of config formats used by the plugin.
 **/
enum ConfigStructure
{
	Structure_StringList,         /** Config is structured as a simple list of strings. */
	Structure_IntegerList,        /** Config is structured as a simple list of numbers. */
	Structure_ArrayList,          /** Config is structured as an array list of strings. */
	Structure_KeyValue            /** Config is a keyvalue structure */
};
/**
 * @endsection
 **/
 
/**
 * @section List of config files used by the plugin.
 **/
enum /*ConfigFile*/
{
	File_Invalid = -1,            /** Invalid config file. */
	File_Cvars,                   /** <game root>cfg/sourcemod/zombieplague.cfg (default) */
	File_Downloads,               /** <sourcemod root>/zombieplague/downloads.ini (default) */
	File_Weapons,                 /** <sourcemod root>/zombieplague/weapons.ini (default) */
	File_Sounds,                  /** <sourcemod root>/zombieplague/sounds.ini (default) */
	File_Menus,                   /** <sourcemod root>/zombieplague/menus.ini (default) */
	File_HitGroups,               /** <sourcemod root>/zombieplague/hitgroups.ini (default) */
	File_Costumes,                /** <sourcemod root>/zombieplague/costumes.ini (default) */
	File_ExtraItems,              /** <sourcemod root>/zombieplague/extraitems.ini (default) */
	File_GameModes,               /** <sourcemod root>/zombieplague/gamemodes.ini (default) */
	File_Classes,                 /** <sourcemod root>/zombieplague/classes.ini (default) */
	File_Levels,                  /** <sourcemod root>/zombieplague/levels.ini (default) */

	File_Size
};
/**
 * @endsection
 **/

/**
 * @section Struct of operation types for config arrays.
 **/
enum struct ConfigData
{
	bool Loaded;                     /** True if config is loaded, false if not. */
	ConfigStructure Structure;       /** Format of the config */
	Function ReloadFunc;             /** Function to call to reload config. */
	ArrayList Handler;               /** Handle of the config file. */
	char Path[PLATFORM_LINE_LENGTH]; /** Full path to config file. */
	char Alias[NORMAL_LINE_LENGTH];  /** Config file alias, used for client interaction. */
}
/**
 * @endsection
 **/
 
/**
 * Array to store the config data.
 **/
ConfigData gConfigData[File_Size]; 

/**
 * @section Actions to use when working on key/values.
 **/
enum ConfigKvAction
{
	KvAction_Create,  /** Creates a key. */
	KvAction_Delete,  /** Delete a key. */
	KvAction_Set,     /** Modify setting of a key. */
	KvAction_Get      /** Get setting of a key. */
};
/**
 * @endsection
 **/
 
/**
 * @brief Config module init function.
 **/
void ConfigOnInit(/*void*/)
{
	// Loads a gamedata configs file
	gServerData.Config   = new GameData(PLUGIN_CONFIG);
	gServerData.SDKHooks = new GameData("sdkhooks.games");
	gServerData.SDKTools = new GameData("sdktools.games");
	gServerData.CStrike  = new GameData("sm-cstrike.games");
	
	// Validate config
	if (gServerData.Config == null)
	{
		LogEvent(false, _, _, _, "Config Validation", "Error opening config: \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	// Initialize a config array
	gServerData.Configs = new StringMap();
}

/**
 * @brief Config module load function.
 **/
void ConfigOnLoad(/*void*/)
{
	// Clear out the array of all data
	gServerData.Configs.Clear();
	
	// Now copy data to array structure
	ConfigOnCacheData();
}

/**
 * @brief Caches config data from map folder.
 **/
void ConfigOnCacheData(/*void*/)
{
	// Initialize variables
	static char sPath[PLATFORM_LINE_LENGTH]; 
	static char sFile[PLATFORM_LINE_LENGTH]; 
	static char sName[PLATFORM_LINE_LENGTH];
	FileType hType; int iFormat;
	
	// Build full path in return string
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s/%s", CONFIG_PATH_DEFAULT, CONFIG_FILE_ALIAS_MAPS);
	
	// Opens the directory
	DirectoryListing hDirectory = OpenDirectory(sPath);
	
	// If doesn't exist stop
	if (hDirectory == null)
	{
		///LogEvent(false, _, _, _, "Config Validation", "Error opening folder: \"%s\"", sPath);
		return;
	}

	// Initialize a map list array
	ArrayList hList = new ArrayList(BIG_LINE_LENGTH);

	// Gets current map name
	GetCurrentMap(sName, sizeof(sName));
	
	// Search folders in the directory
	while (hDirectory.GetNext(sPath, sizeof(sPath), hType)) 
	{
		// Validate folder type
		if (hType == FileType_Directory) 
		{
			// Validate prefix
			if (!strncmp(sName, sPath, strlen(sPath), false))
			{
				// Push data into string
				hList.PushString(sPath);
			}
		}
	}
	
	// Close directory
	delete hDirectory;

	/// Do quick sort!
	SortADTArrayCustom(hList, view_as<SortFuncADTArray>(Sort_ByLength));

	 // i = folder array index
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Gets directory path
		hList.GetString(i, sPath, sizeof(sPath));
		
		// Build full path in return string
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s/%s/%s", CONFIG_PATH_DEFAULT, CONFIG_FILE_ALIAS_MAPS, sPath);

		// Opens the directory
		hDirectory = OpenDirectory(sPath);
		
		// If doesn't exist stop
		if (hDirectory == null)
		{
			// Log config error info
			LogEvent(false, _, _, _, "Config Validation", "Error opening folder: \"%s\"", sPath);

			// Remove folder from array
			hList.Erase(i);
			
			// Subtract one from count
			iSize--;

			// Backtrack one index, because we deleted it out from under the loop
			i--;
			continue;
		}
		
		// Search files in the directory
		while (hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
		{
			// Validate file type
			if (hType == FileType_File) 
			{
				// Finds the first occurrence of a character in a string
				iFormat = FindCharInString(sFile, '.', true);
		
				// Validate format
				if (iFormat != -1) 
				{
					// Validate config format
					if (!strcmp(sFile[iFormat], ".ini", false))
					{
						 // Format full path to config 
						FormatEx(sName, sizeof(sName), "%s/%s", sPath, sFile);
				
						// Cut the format
						sFile[iFormat] = NULL_STRING[0];
				
						// Sets path for the alias
						gServerData.Configs.SetString(sFile, sName, true);
					}
				}
			}
		}
		
		// Close directory
		delete hDirectory;
	}

	// Close list
	delete hList;
}

/**
 * @brief Creates commands for config module.
 **/
void ConfigOnCommandInit(/*void*/)
{
	// Creates config admin commands
	RegConsoleCmd("zp_config_menu", ConfigMenuOnCommandCatched, "Opens the configs menu.");
	RegAdminCmd("zp_config_reload", ConfigReloadOnCommandCatched, ADMFLAG_CONFIG, "Reloads a config file. Usage: zp_config_reload <file alias>");
	RegAdminCmd("zp_config_reloadall", ConfigReloadAllOnCommandCatched, ADMFLAG_CONFIG, "Reloads all config files. Usage: zp_config_reloadall");
}

/*
 * Stocks config API.
 */

/**
 * @brief Used by modules that rely on configs to register their config file info.
 *  
 * @note Don't forget to set 'loaded' to 'true' (ConfigSetConfigLoaded) in config load function.
 *
 * @param iFile             Config file entry to register.
 * @param sAlias            Config file alias, used for client interaction.
 **/
stock void ConfigRegisterConfig(int iFile, ConfigStructure iStructure, char[] sAlias = "")
{
	// Copy file info to data container
	gConfigData[iFile].Loaded = false;
	gConfigData[iFile].Structure = iStructure;
	gConfigData[iFile].Handler = null;
	gConfigData[iFile].ReloadFunc = INVALID_FUNCTION;
	strcopy(gConfigData[iFile].Path, PLATFORM_LINE_LENGTH, "");
	strcopy(gConfigData[iFile].Alias, NORMAL_LINE_LENGTH, sAlias);
}

/**
 * @brief Sets the loaded state of a config file entry.
 * 
 * @param iConfig           Config file to set load state of.
 * @param bLoaded           True to set as loaded, false to set as unloaded.
 **/
stock void ConfigSetConfigLoaded(int iConfig, bool bLoaded)
{
	// Sets load state
	gConfigData[iConfig].Loaded = bLoaded;
}

/**
 * @brief Sets the structure type of a config file entry.
 * 
 * @param iConfig           Config file to set structure type of.
 * @param iStructure        Structure to set as.
 **/
stock void ConfigSetConfigStructure(int iConfig, ConfigStructure iStructure)
{
	// Sets load state
	gConfigData[iConfig].Structure = iStructure;
}

/**
 * @brief Sets the reload function of a config file entry.
 * 
 * @param iConfig           Config file to set reload function of.
 * @param iReloadfunc       Reloads function.
 **/
stock void ConfigSetConfigReloadFunc(int iConfig, Function iReloadfunc)
{
	// Sets reload function.
	gConfigData[iConfig].ReloadFunc = iReloadfunc;
}

/**
 * @brief Sets the file handle of a config file entry.
 * 
 * @param iConfig           Config file to set handle of.
 * @param iFile             Config file handle.
**/
stock void ConfigSetConfigHandle(int iConfig, ArrayList iFile)
{
	// Sets file handle
	gConfigData[iConfig].Handler = iFile;
}

/**
 * @brief Sets the config file path of a config file entry.
 * 
 * @param iConfig           Config file to set file path of.
 * @param sPath             File path.
 **/
stock void ConfigSetConfigPath(int iConfig, char[] sPath)
{
	// Sets config file path
	strcopy(gConfigData[iConfig].Path, PLATFORM_LINE_LENGTH, sPath);
}

/**
 * @brief Sets the alias of a config file entry.
 * 
 * @param iConfig           Config file to set alias of.
 * @param sAlias            Alias of the config file entry.
 **/
stock void ConfigSetConfigAlias(int iConfig, char[] sAlias)
{
	// Sets config alias
	strcopy(gConfigData[iConfig].Alias, NORMAL_LINE_LENGTH, sAlias);
}

/**
 * @brief Returns if a config was successfully loaded.
 * 
 * @param iConfig           Config file to check load status of.
 * @return                  True if config is loaded, false otherwise.
 **/
stock bool ConfigIsConfigLoaded(int iConfig)
{
	// Return load status
	return gConfigData[iConfig].Loaded;
}

/**
 * @brief Returns config structure type.
 * 
 * @param iConfig           Config file to get structure type of.
 * @return                  Config structure type.
 **/
stock ConfigStructure ConfigGetConfigStructure(int iConfig)
{
	// Return load status
	return gConfigData[iConfig].Structure;
}

/**
 * @brief Returns config reload function.
 * 
 * @param iConfig           Config file to get reload function of.
 * @return                  Config reload function.
 **/
stock Function ConfigGetConfigReloadFunc(int iConfig)
{
	// Return load status
	return gConfigData[iConfig].ReloadFunc;
}

/**
 * @brief Returns config file handle.
 * 
 * @param iConfig           Config file to get file handle of.
 * @return                  Config file handle.
 **/
stock ArrayList ConfigGetConfigHandle(int iConfig)
{
	// Return load status
	return gConfigData[iConfig].Handler;
}

/**
 * @brief Returns the path for a given config file entry.
 * 
 * @param iConfig           Config file to get path of. (see int enum)
 **/
stock void ConfigGetConfigPath(int iConfig, char[] sPath, int iMaxLen)
{
	// Copy path to return string
	strcopy(sPath, iMaxLen, gConfigData[iConfig].Path);
}

/**
 * @brief Returns the alias for a given config file entry.
 * 
 * @param iConfig           Config file to get alias of. (see int enum)
 **/
stock void ConfigGetConfigAlias(int iConfig, char[] sAlias, int iMaxLen)
{
	// Copy alias to return string
	strcopy(sAlias, iMaxLen, gConfigData[iConfig].Alias);
}

/**
 * @brief Loads a config file and sets up a nested array type data storage.
 * 
 * @param iConfig           The config file to load.
 * @param arrayConfig       Handle of the main array containing file data.
 * @param blockSize         (Optional) The number of cells each member of the array can hold. 
 * @return                  True if file was loaded successfuly, false otherwise.
 **/
stock bool ConfigLoadConfig(int iConfig, ArrayList &arrayConfig, int blockSize = NORMAL_LINE_LENGTH)
{
	// If array hasn't been created, then create
	if (arrayConfig == null)
	{
		// Creates array in handle
		arrayConfig = new ArrayList(blockSize);
	}
	
	// Initialize buffer char
	static char sBuffer[PLATFORM_LINE_LENGTH];
	
	// Gets config structure
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);

	// Validate structure
	switch (iStructure)
	{
		case Structure_StringList :
		{
			// Opens file
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);

			// If config file failed to open, then stop
			if (!bSuccess)
			{
				return false;
			}

			// Clear out array
			arrayConfig.Clear();

			// Read lines in the file
			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				// Cut out comments at the end of a line
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				// Trim off whitespace
				TrimString(sBuffer);
				
				// Strips a quote pair off a string 
				StripQuotes(sBuffer);

				// If line is empty, then stop
				if (!hasLength(sBuffer))
				{
					continue;
				}

				// Push line into array
				arrayConfig.PushString(sBuffer);
			}

			// We're done this file, so now we can destory it from memory
			delete hFile;
			return true;
		}
		
		case Structure_IntegerList :
		{
			// Opens file
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);

			// If config file failed to open, then stop
			if (!bSuccess)
			{
				return false;
			}

			// Clear out array
			arrayConfig.Clear();

			// Read lines in the file
			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				// Cut out comments at the end of a line
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				// Trim off whitespace
				TrimString(sBuffer);
				
				// Strips a quote pair off a string 
				StripQuotes(sBuffer);

				// If line is empty, then stop
				if (!hasLength(sBuffer))
				{
					continue;
				}

				// Push number into array
				arrayConfig.Push(StringToInt(sBuffer));
			}

			// We're done this file, so now we can destory it from memory
			delete hFile;
			return true;
		}

		case Structure_ArrayList :
		{
			// Opens file
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);
			
			// If config file failed to open, then stop
			if (!bSuccess)
			{
				return false;
			}
			
			// Destroy all old data
			ConfigClearKvArray(arrayConfig);

			// Read lines in the file
			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				// Cut out comments at the end of a line
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				// Trim off whitespace
				TrimString(sBuffer);

				// If line is empty, then stop
				if (!hasLength(sBuffer))
				{
					continue;
				}

				// Creates new array to store information for config entry
				ArrayList arrayConfigEntry = new ArrayList(blockSize);

				// Push line into array
				arrayConfigEntry.PushString(sBuffer); // Index: 0

				// Store this handle in the main array
				arrayConfig.Push(arrayConfigEntry);
			}
			
			// We're done this file, so now we can destory it from memory
			delete hFile;
			return true;
		}
		
		case Structure_KeyValue :
		{
			// Opens file
			KeyValues hKeyvalue;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hKeyvalue);
			
			// If config file failed to open, then stop
			if (!bSuccess)
			{
				return false;
			}
			
			// Destroy all old data
			ConfigClearKvArray(arrayConfig);
			
			// Read keys in the file
			if (hKeyvalue.GotoFirstSubKey())
			{
				do
				{
					// Creates new array to store information for config entry
					ArrayList arrayConfigEntry = new ArrayList(blockSize);
					
					// Push the key name into the config entry array
					hKeyvalue.GetSectionName(sBuffer, sizeof(sBuffer));

					// Move name to low case
					StringToLower(sBuffer);

					// Push data into array
					arrayConfigEntry.PushString(sBuffer); // Index: 0
					
					// Store this handle in the main array
					arrayConfig.Push(arrayConfigEntry);
				} 
				while (hKeyvalue.GotoNextKey());
			}
			
			// We're done this file for now, so now we can destory it from memory 
			delete hKeyvalue;
			return true;
		}
	}

	// Return on fail
	return false;
}

/**
 * @brief Reloads a config file.
 * 
 * @param iConfig           The config file entry to reload.
 * @return                  True if the config is loaded, false if not.
 **/
stock bool ConfigReloadConfig(int iConfig)
{
	// If file isn't loaded, then stop
	bool bLoaded = ConfigIsConfigLoaded(iConfig);
	if (!bLoaded)
	{
		return false;
	}
	
	// Call reload function
	Function iReloadfunc = ConfigGetConfigReloadFunc(iConfig);
	
	// Call reload function
	Call_StartFunction(GetMyHandle(), iReloadfunc);
	Call_Finish();

	// Return on success
	return true;
}

/**
 * @brief Opens a config file with appropriate method.
 * 
 * @param iConfig           The config file.
 * @param iStructure        The structure of the config file.
 * @param hConfig           The handle of the opened file.
 **/
stock bool ConfigOpenConfigFile(int iConfig, Handle &hConfig)
{
	// Gets config structure
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);
	
	// Gets config file path
	static char sPath[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(iConfig, sPath, sizeof(sPath));
	
	// Gets config alias
	static char sAlias[NORMAL_LINE_LENGTH];
	ConfigGetConfigAlias(iConfig, sAlias, sizeof(sAlias));
	
	// Validate structure
	switch (iStructure)
	{
		case Structure_KeyValue :
		{
			// Creates config
			hConfig = CreateKeyValues(sAlias);
			return FileToKeyValues(hConfig, sPath);
		}
		
		default :
		{
			// Opens file
			hConfig = OpenFile(sPath, "r");
			
			// If file couldn't be opened, then stop
			if (hConfig == null)
			{
				return false;
			}
			
			// Return on success
			return true;
		}
	}
}

/**
 * @brief Creates, deletes, sets, or gets any key/setting of any ZP config keyvalue file in memory.
 *        
 * @note Only use when interacting with a command or manipulating single keys/values,
 *       using this function everywhere would be EXTREMELY inefficient.
 * 
 * @param iConfig           Config file to modify.
 * @param mAction           Action to perform on keyvalue tree. (see enum ConfigKeyvalueAction)
 * @param sKeys             Array containing keys to traverse into.
 * @param keysMax           The size of the 'keys' array.
 * @param sSetting          (Optional) The name of the setting to modify.
 * @param sValue            (Optional) The new value to set.
 * @param iMaxLen           (Optional) The maxlength of the retrieved value.
 * @return                  True if the change was made successfully, false otherwise. 
 **/
stock bool ConfigKeyvalueTreeSetting(int iConfig, ConfigKvAction mAction = KvAction_Create, char[][] sKeys, int keysMax, char[] sSetting = "", char[] sValue = "", int iMaxLen = 0)
{
	// Gets config file structure
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);
	
	// If the config is any other structure beside keyvalue, then stop
	if (iStructure != Structure_KeyValue)
	{
		return false;
	}
	
	// Retrieve handle of the keyvalue tree
	KeyValues hConfig;
	bool bSuccess = ConfigOpenConfigFile(iConfig, hConfig);
	
	// If the file couldn't be opened, then stop
	if (!bSuccess)
	{
		return false;
	}
	
	// Rewind keyvalue tree
	hConfig.Rewind();
	
	// i = keys index.
	// Traverse into the keygroup, stop if it fails
	for (int i = 0; i < keysMax; i++)
	{
		// If key is empty, then break the loop
		if (!hasLength(sKeys[i]))
		{
			break;
		}
		
		// Try to jump to next level in the transversal stack, create key if specified
		bool bExists = hConfig.JumpToKey(sKeys[i], (mAction == KvAction_Create));
		
		// If exists is false, then stop
		if (!bExists)
		{
			// Key doesn't exist
			return false;
		}
	}
	
	// Switch the kv action
	switch (mAction)
	{
		case KvAction_Create :
		{
			if (!hasLength(sSetting) || !hasLength(sValue))
			{
				// We created the key already, so return true
				return true;
			}
			
			// Sets new value
			hConfig.SetString(sSetting, sValue);
		}
		
		case KvAction_Delete :
		{
			// Return deletion result
			return hConfig.DeleteKey(sSetting);
		}
		
		case KvAction_Set :
		{
			// Sets new value
			hConfig.SetString(sSetting, sValue);
		}
		
		case KvAction_Get:
		{
			// Gets current value
			hConfig.GetString(sSetting, sValue, iMaxLen);
		}
	}
	
	// We successfully set or got the value
	return true;
}

/**
 * @brief Destroy all array handles within an array, and clear main array.
 * 
 * @param arrayKv           The array converted from a keyvalue structure.
 **/
stock void ConfigClearKvArray(ArrayList arrayKv)
{
	// i = array index
	int iSize = arrayKv.Length;
	for (int i = 0; i < iSize; i++)
	{
		// Destroy nested arrays
		ArrayList arrayKvKey = arrayKv.Get(i);
		delete arrayKvKey;
	}
	
	// Now that all data within has been destroyed, we can clear the main array
	arrayKv.Clear();
}

/**
 * @brief Finds a config file entry, (see ConfigFile enum) for a given alias.
 * 
 * @param sAlias            The alias to find config file entry of.
 * @return                  Config file entry, ConfigInvalid is returned if alias was not found.
 **/
stock int ConfigAliasToConfigFile(char[] sAlias)
{
	static char sCheckAlias[NORMAL_LINE_LENGTH];
	
	// i = config file entry index
	for (int i = File_Cvars; i < File_Size; i++)
	{
		// Gets config alias.
		ConfigGetConfigAlias(i, sCheckAlias, sizeof(sCheckAlias));
		
		// If alias doesn't match, then skip
		if (!strcmp(sAlias, sCheckAlias, false))
		{
			// Return config file entry
			return i;
		}
	}
	
	// Invalid config file
	return File_Invalid;
}

/**
 * @brief Generate config file path.
 * 
 * @param sAlias            The full path.
 * @param sPath             The path output.
 * @param iMaxLen           The string lenght.
 * @param bRoot             This should be used instead of directly referencing to sourcemod root.
 * @return                  True if the file exists, false if not.
 **/
stock bool ConfigGetFullPath(char[] sAlias, char[] sPath, int iMaxLen, bool bRoot = true)
{
	// Validate root
	if (bRoot)
	{
		// Gets path in return string
		if (!gServerData.Configs.GetString(sAlias, sPath, iMaxLen))
		{
			// Build default path in return string
			BuildPath(Path_SM, sPath, iMaxLen, "%s/%s.ini", CONFIG_PATH_DEFAULT, sAlias);
		}
	}
	else
	{
		// Copy folder to path buffer
		FormatEx(sPath, iMaxLen, "cfg/sourcemod/%s.%s", CONFIG_PATH_DEFAULT, sAlias);
	}
	
	// If file is exist, then return true
	return FileExists(sPath);
}

/**
 * @brief Converts string of "yes/on", "no/off", "false/true", "1/0" to a boolean value.  Always uses english as main language.
 * 
 * @param sOption           The string to be converted.
 * @return                  True if string is "yes", false otherwise.
 **/
stock bool ConfigSettingToBool(char[] sOption)
{
	// If option is equal to "yes", then return true
	if (!strcmp(sOption, "yes", false) || !strcmp(sOption, "on", false) || !strcmp(sOption, "true", false) || !strcmp(sOption, "1", false))
	{
		return true;
	}
	
	// Option isn't yes
	return false;
}

/**
 * @brief Converts boolean value to "yes" or "no".
 * 
 * @param bOption           True/false value to be converted to "yes/on"/"no/off", respectively.
 * @param sOption           Destination string buffer to store "yes/on" or "no/off" in.
 * @param iMaxLen           Length of destination string buffer.
 * @param bYesNo            When true, returns "yes/no", false returns "on/off."
 * @param target            The target to use as translation language.
 **/
stock void ConfigBoolToSetting(bool bOption, char[] sOption, int iMaxLen, bool bYesNo = true, int target = LANG_SERVER)
{
	// Initialize buffer char
	static char sBuffer[10];
	
	// Sets language to target
	SetGlobalTransTarget(target);
	
	// If option is true, then copy "yes" to return string
	if (bOption)
	{
		// Gets yes/no translations for the target
		if (bYesNo)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "Yes");  
			strcopy(sOption, iMaxLen, sBuffer);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "On");
			strcopy(sOption, iMaxLen, sBuffer);
		}
	}
	// If option is false, then copy "no" to return string
	else
	{
		// Gets yes/no translations for the target
		if (bYesNo)
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "No");     
			strcopy(sOption, iMaxLen, sBuffer);
		}
		else
		{
			FormatEx(sBuffer, sizeof(sBuffer), "%t", "Off");
			strcopy(sOption, iMaxLen, sBuffer);
		}
	}
}

/**
 * @brief Returns a "yes/no" string from config as a bool.
 * 
 * @param kv                The keyvalue handle.
 * @param sKey              The keyname the value is under.
 * @param sDefaultValue     (Optional) Value to return if setting is missing.
 **/
stock bool ConfigKvGetStringBool(KeyValues kv, char[] sKey, char[] sDefaultValue = "yes")
{
	// Gets string from key
	static char sValue[NORMAL_LINE_LENGTH];
	kv.GetString(sKey, sValue, sizeof(sValue), sDefaultValue);
	
	// Convert string to bool
	return ConfigSettingToBool(sValue);
}

/**
 * Console command callback (zp_config_menu)
 * @brief Opens the config menu.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ConfigMenuOnCommandCatched(int client, int iArguments)
{
	ConfigMenu(client);
	return Plugin_Handled;
}

/**
 * Console command callback (zp_config_reload)
 * @brief Reloads a config file and forwards event to modules.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ConfigReloadOnCommandCatched(int client, int iArguments)
{
	// If not enough arguments given, then stop
	if (iArguments < 1)
	{
		// Write syntax info
		TranslationReplyToCommand(client, "config reload");
		TranslationReplyToCommand(client, "config reload commands");
		TranslationReplyToCommand(client, "config reload commands aliases", CONFIG_FILE_ALIAS_CVARS, CONFIG_FILE_ALIAS_DOWNLOADS, CONFIG_FILE_ALIAS_WEAPONS, CONFIG_FILE_ALIAS_SOUNDS, CONFIG_FILE_ALIAS_MENUS, CONFIG_FILE_ALIAS_HITGROUPS, CONFIG_FILE_ALIAS_COSTUMES, CONFIG_FILE_ALIAS_EXTRAITEMS, CONFIG_FILE_ALIAS_GAMEMODES, CONFIG_FILE_ALIAS_CLASSES, CONFIG_FILE_ALIAS_LEVELS);
		return Plugin_Handled;
	}

	// Initialize variables
	static char sAlias[NORMAL_LINE_LENGTH];
	static char sPath[PLATFORM_LINE_LENGTH];
	static char sMessage[PLATFORM_LINE_LENGTH];

	// i = config file entry index
	int iArgs = GetCmdArgs();
	for (int i = 1; i <= iArgs; i++)
	{
		// Gets alias to restrict
		GetCmdArg(i, sAlias, sizeof(sAlias));

		// If alias is invalid, then stop
		int iConfig = ConfigAliasToConfigFile(sAlias);
		if (iConfig == File_Invalid)
		{
			// Write error info
			TranslationReplyToCommand(client, "config reload invalid", sAlias);
			return Plugin_Handled;
		}

		// Reloads config file
		bool bLoaded = ConfigReloadConfig(iConfig);

		// Gets config file path
		ConfigGetConfigPath(iConfig, sPath, sizeof(sPath));

		// Format log message
		FormatEx(sMessage, sizeof(sMessage), "Admin \"%N\" reloaded config file \"%s\". (zp_config_reload)", client, sPath);

		// If file isn't loaded then tell client, then stop
		if (!bLoaded)
		{
			// Write error info
			TranslationReplyToCommand(client, "config reload not load", sAlias);

			// Format a failed attempt string to the end of the log message
			Format(sMessage, sizeof(sMessage), "\"%s\" -- attempt failed, config file not loaded", sMessage);
		}
		
		// Log action to game events
		LogEvent(true, _, _, _, "Command", sMessage);
	}
	
	// Call forward
	gForwardData._OnEngineExecute();

	// Return on success
	return Plugin_Handled;
}

/**
 * Console command callback (zp_config_reloadall)
 * @brief Reloads all config files and forwards event to all modules.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ConfigReloadAllOnCommandCatched(int client, int iArguments)
{
	// Begin statistics
	TranslationReplyToCommand(client, "config reload begin");

	// Initialize alias char
	static char sAlias[NORMAL_LINE_LENGTH];

	// i = config file entry index
	for (int i = File_Cvars; i < File_Size; i++)
	{
		// Reloads config file
		bool bSuccessful = ConfigReloadConfig(i);

		// Gets config alias
		ConfigGetConfigAlias(i, sAlias, sizeof(sAlias));

		// Validate load
		if (bSuccessful)
		{
			TranslationReplyToCommand(client, "config reload finish", sAlias);
		}
		else
		{
			TranslationReplyToCommand(client, "config reload falied", sAlias);
		}
	}
	
	// Log action to game events
	LogEvent(true, _, _, _, "Command", "Admin \"%N\" reloaded all config files", client);
	
	// Call forward
	gForwardData._OnEngineExecute();

	// Return on success
	return Plugin_Handled;
}

/*
 * Menu config API.
 */

/**
 * @brief Creates the reload configs menu.
 *
 * @param client            The client index.
 **/
void ConfigMenu(int client) 
{
	// Validate client
	if (!IsPlayerExist(client, false))
	{
		return;
	}

	// Initialize variables
	static char sBuffer[NORMAL_LINE_LENGTH];
	static char sAlias[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];

	// Creates menu handle
	Menu hMenu = new Menu(ConfigMenuSlots);

	// Sets language to target
	SetGlobalTransTarget(client);
	
	// Sets title
	hMenu.SetTitle("%t", "configs menu");
	
	// i = config file entry index
	for (int i = File_Cvars; i < File_Size; i++)
	{
		// Gets config alias
		ConfigGetConfigAlias(i, sAlias, sizeof(sAlias));
		
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "config menu reload", sAlias);
		
		// Show option
		IntToString(i, sInfo, sizeof(sInfo));
		hMenu.AddItem(sInfo, sBuffer);
	}
	
	// If there are no cases, add an "(Empty)" line
	/*if (!iSize)
	{
		// Format some chars for showing in menu
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
		hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
	}*/
	
	// Sets exit and back button
	hMenu.ExitBackButton = true;

	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
	hMenu.Display(client, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the config menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ConfigMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}
		
		// Client hit 'Back' button
		case MenuAction_Cancel :
		{
			if (mSlot == MenuCancel_ExitBack)
			{
				// Opens menu back
				int iD[2]; iD = MenusCommandToArray("zp_config_menu");
				if (iD[0] != -1) SubMenu(client, iD[0]);
			}
		}
		
		// Client selected an option
		case MenuAction_Select :
		{
			// Validate client
			if (!IsPlayerExist(client, false))
			{
				return 0;
			}

			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int iD = StringToInt(sBuffer);
			
			// Gets config alias
			ConfigGetConfigAlias(iD, sBuffer, sizeof(sBuffer));
			
			// Reloads config file
			bool bSuccessful = ConfigReloadConfig(iD);
			
			// Validate load
			if (bSuccessful)
			{
				TranslationPrintToChat(client, "config reload finish", sBuffer);
			}
			else
			{
				TranslationPrintToChat(client, "config reload falied", sBuffer);
			}
			
			// Log action to game events
			LogEvent(true, _, _, _, "Command", "Admin \"%N\" reloaded all config files", client);
			
			// Opens config menu back
			ConfigMenu(client);
		}
	}
	
	return 0;
}
