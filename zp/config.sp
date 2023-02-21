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
 
 /*
 * Load other menus modules
 */
#include "zp/playerclasses/configmenu.sp"

/**
 * @brief Config module init function.
 **/
void ConfigOnInit()
{
	gServerData.Config   = new GameData(PLUGIN_CONFIG);
	gServerData.SDKHooks = new GameData("sdkhooks.games");
	gServerData.SDKTools = new GameData("sdktools.games");
	gServerData.CStrike  = new GameData("sm-cstrike.games");
	
	if (gServerData.Config == null)
	{
		LogEvent(false, _, _, _, "Config Validation", "Error opening config: \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	gServerData.Configs = new StringMap();
	gServerData.Listeners = new StringMap();
}

/**
 * @brief Config module load function.
 **/
void ConfigOnLoad()
{
	gServerData.Configs.Clear();
	
	ConfigOnCacheData();
}

/**
 * @brief Caches config data from map folder.
 **/
void ConfigOnCacheData()
{
	static char sPath[PLATFORM_LINE_LENGTH]; 
	static char sFile[PLATFORM_LINE_LENGTH]; 
	static char sName[PLATFORM_LINE_LENGTH];
	FileType hType; int iFormat;
	
	BuildPath(Path_SM, sPath, sizeof(sPath), "%s/%s", CONFIG_PATH_DEFAULT, CONFIG_FILE_ALIAS_MAPS);
	
	DirectoryListing hDirectory = OpenDirectory(sPath);
	
	if (hDirectory == null)
	{
		return;
	}

	ArrayList hList = new ArrayList(PLATFORM_MAX_PATH);

	GetCurrentMap(sName, sizeof(sName));
	
	while (hDirectory.GetNext(sPath, sizeof(sPath), hType)) 
	{
		if (hType == FileType_Directory) 
		{
			if (!strncmp(sName, sPath, strlen(sPath), false))
			{
				hList.PushString(sPath);
			}
		}
	}
	
	delete hDirectory;

	SortADTArrayCustom(hList, view_as<SortFuncADTArray>(Sort_ByLength));

	 // i = folder array index
	int iSize = hList.Length;
	for (int i = 0; i < iSize; i++)
	{
		hList.GetString(i, sPath, sizeof(sPath));
		
		BuildPath(Path_SM, sPath, sizeof(sPath), "%s/%s/%s", CONFIG_PATH_DEFAULT, CONFIG_FILE_ALIAS_MAPS, sPath);

		hDirectory = OpenDirectory(sPath);
		
		if (hDirectory == null)
		{
			LogEvent(false, _, _, _, "Config Validation", "Error opening folder: \"%s\"", sPath);

			hList.Erase(i);
			
			iSize--;

			i--;
			continue;
		}
		
		while (hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
		{
			if (hType == FileType_File) 
			{
				iFormat = FindCharInString(sFile, '.', true);
		
				if (iFormat != -1) 
				{
					if (!strcmp(sFile[iFormat], ".ini", false))
					{
						 // Format full path to config 
						FormatEx(sName, sizeof(sName), "%s/%s", sPath, sFile);
				
						sFile[iFormat] = NULL_STRING[0];
				
						gServerData.Configs.SetString(sFile, sName, true);
					}
				}
			}
		}
		
		delete hDirectory;
	}

	delete hList;
}

/**
 * @brief Creates commands for config module.
 **/
void ConfigOnCommandInit()
{
	RegAdminCmd("zp_config_reload", ConfigReloadOnCommandCatched, ADMFLAG_CONFIG, "Reloads a config file. Usage: zp_config_reload <file alias>");
	RegAdminCmd("zp_config_reloadall", ConfigReloadAllOnCommandCatched, ADMFLAG_CONFIG, "Reloads all config files. Usage: zp_config_reloadall");
	
	ConfigMenuOnCommandInit();
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
	return gConfigData[iConfig].Handler;
}

/**
 * @brief Returns the path for a given config file entry.
 * 
 * @param iConfig           Config file to get path of. (see int enum)
 **/
stock void ConfigGetConfigPath(int iConfig, char[] sPath, int iMaxLen)
{
	strcopy(sPath, iMaxLen, gConfigData[iConfig].Path);
}

/**
 * @brief Returns the alias for a given config file entry.
 * 
 * @param iConfig           Config file to get alias of. (see int enum)
 **/
stock void ConfigGetConfigAlias(int iConfig, char[] sAlias, int iMaxLen)
{
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
	if (arrayConfig == null)
	{
		arrayConfig = new ArrayList(blockSize);
	}
	
	static char sBuffer[PLATFORM_LINE_LENGTH];
	
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);

	switch (iStructure)
	{
		case Structure_StringList :
		{
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);

			if (!bSuccess)
			{
				return false;
			}

			arrayConfig.Clear();

			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				TrimString(sBuffer);
				
				StripQuotes(sBuffer);

				if (!hasLength(sBuffer))
				{
					continue;
				}

				arrayConfig.PushString(sBuffer);
			}

			delete hFile;
			return true;
		}
		
		case Structure_IntegerList :
		{
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);

			if (!bSuccess)
			{
				return false;
			}

			arrayConfig.Clear();

			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				TrimString(sBuffer);
				
				StripQuotes(sBuffer);

				if (!hasLength(sBuffer))
				{
					continue;
				}

				arrayConfig.Push(StringToInt(sBuffer));
			}

			delete hFile;
			return true;
		}

		case Structure_ArrayList :
		{
			File hFile;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);
			
			if (!bSuccess)
			{
				return false;
			}
			
			ClearArrayList(arrayConfig);

			while (hFile.ReadLine(sBuffer, sizeof(sBuffer)))
			{
				SplitString(sBuffer, "//", sBuffer, sizeof(sBuffer));

				TrimString(sBuffer);

				if (!hasLength(sBuffer))
				{
					continue;
				}

				ArrayList arrayConfigEntry = new ArrayList(blockSize);

				arrayConfigEntry.PushString(sBuffer); // Index: 0

				arrayConfig.Push(arrayConfigEntry);
			}
			
			delete hFile;
			return true;
		}
		
		case Structure_KeyValue :
		{
			KeyValues hKeyvalue;
			bool bSuccess = ConfigOpenConfigFile(iConfig, hKeyvalue);
			
			if (!bSuccess)
			{
				return false;
			}
			
			ClearArrayList(arrayConfig);
			
			if (hKeyvalue.GotoFirstSubKey())
			{
				do
				{
					ArrayList arrayConfigEntry = new ArrayList(blockSize);
					
					hKeyvalue.GetSectionName(sBuffer, sizeof(sBuffer));

					StringToLower(sBuffer);

					arrayConfigEntry.PushString(sBuffer); // Index: 0
					
					arrayConfig.Push(arrayConfigEntry);
				} 
				while (hKeyvalue.GotoNextKey());
			}
			
			delete hKeyvalue;
			return true;
		}
	}

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
	bool bLoaded = ConfigIsConfigLoaded(iConfig);
	if (!bLoaded)
	{
		return false;
	}
	
	Function iReloadfunc = ConfigGetConfigReloadFunc(iConfig);
	
	Call_StartFunction(GetMyHandle(), iReloadfunc);
	Call_Finish();

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
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);
	
	static char sPath[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(iConfig, sPath, sizeof(sPath));
	
	static char sAlias[NORMAL_LINE_LENGTH];
	ConfigGetConfigAlias(iConfig, sAlias, sizeof(sAlias));
	
	switch (iStructure)
	{
		case Structure_KeyValue :
		{
			hConfig = CreateKeyValues(sAlias);
			return FileToKeyValues(hConfig, sPath);
		}
		
		default :
		{
			hConfig = OpenFile(sPath, "r");
			
			if (hConfig == null)
			{
				return false;
			}
			
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
stock bool ConfigKeyValueTreeSetting(int iConfig, ConfigKvAction mAction = KvAction_Create, char[][] sKeys, int keysMax, char[] sSetting = "", char[] sValue = "", int iMaxLen = 0)
{
	ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);
	
	if (iStructure != Structure_KeyValue)
	{
		return false;
	}
	
	KeyValues hConfig;
	bool bSuccess = ConfigOpenConfigFile(iConfig, hConfig);
	
	if (!bSuccess)
	{
		return false;
	}
	
	hConfig.Rewind();
	
	for (int i = 0; i < keysMax; i++)
	{
		if (!hasLength(sKeys[i]))
		{
			break;
		}
		
		bool bExists = hConfig.JumpToKey(sKeys[i], (mAction == KvAction_Create));
		
		if (!bExists)
		{
			return false;
		}
	}
	
	switch (mAction)
	{
		case KvAction_Create :
		{
			if (!hasLength(sSetting) || !hasLength(sValue))
			{
				return true;
			}
			
			hConfig.SetString(sSetting, sValue);
		}
		
		case KvAction_Delete :
		{
			return hConfig.DeleteKey(sSetting);
		}
		
		case KvAction_Set :
		{
			hConfig.SetString(sSetting, sValue);
		}
		
		case KvAction_Get:
		{
			hConfig.GetString(sSetting, sValue, iMaxLen);
		}
	}
	
	return true;
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
	
	for (int i = File_Cvars; i < File_Size; i++)
	{
		ConfigGetConfigAlias(i, sCheckAlias, sizeof(sCheckAlias));
		
		if (!strcmp(sAlias, sCheckAlias, false))
		{
			return i;
		}
	}
	
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
	if (bRoot)
	{
		if (!gServerData.Configs.GetString(sAlias, sPath, iMaxLen))
		{
			BuildPath(Path_SM, sPath, iMaxLen, "%s/%s.ini", CONFIG_PATH_DEFAULT, sAlias);
		}
	}
	else
	{
		FormatEx(sPath, iMaxLen, "cfg/sourcemod/%s.%s", CONFIG_PATH_DEFAULT, sAlias);
	}
	
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
	if (!strcmp(sOption, "yes", false) || !strcmp(sOption, "on", false) || !strcmp(sOption, "true", false) || !strcmp(sOption, "1", false))
	{
		return true;
	}
	
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
	static char sBuffer[10];
	
	SetGlobalTransTarget(target);
	
	if (bOption)
	{
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
	else
	{
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
	static char sValue[NORMAL_LINE_LENGTH];
	kv.GetString(sKey, sValue, sizeof(sValue), sDefaultValue);
	
	return ConfigSettingToBool(sValue);
}

/**
 * @brief Returns the flag set that is added to users from this group.
 *
 * @param sGroup            The SourceMod group name to check.
 * @return                  A  bitstring containing which flags are enabled.
 **/
stock int ConfigGetAdmFlags(char[] sGroup)
{
	if (hasLength(sGroup))
	{
		GroupId nGroup = FindAdmGroup(sGroup);
		return nGroup != INVALID_GROUP_ID ? nGroup.GetFlags() : 0;
	}
	return 0;
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
	if (iArguments < 1)
	{
		TranslationReplyToCommand(client, "config reload");
		TranslationReplyToCommand(client, "config reload commands");
		TranslationReplyToCommand(client, "config reload commands aliases", CONFIG_FILE_ALIAS_CVARS, CONFIG_FILE_ALIAS_DOWNLOADS, CONFIG_FILE_ALIAS_WEAPONS, CONFIG_FILE_ALIAS_SOUNDS, CONFIG_FILE_ALIAS_MENUS, CONFIG_FILE_ALIAS_HITGROUPS, CONFIG_FILE_ALIAS_COSTUMES, CONFIG_FILE_ALIAS_EXTRAITEMS, CONFIG_FILE_ALIAS_GAMEMODES, CONFIG_FILE_ALIAS_CLASSES, CONFIG_FILE_ALIAS_LEVELS);
		return Plugin_Handled;
	}

	static char sAlias[NORMAL_LINE_LENGTH];
	static char sPath[PLATFORM_LINE_LENGTH];
	static char sMessage[PLATFORM_LINE_LENGTH];

	int iArgs = GetCmdArgs();
	for (int i = 1; i <= iArgs; i++)
	{
		GetCmdArg(i, sAlias, sizeof(sAlias));

		int iConfig = ConfigAliasToConfigFile(sAlias);
		if (iConfig == File_Invalid)
		{
			TranslationReplyToCommand(client, "config reload invalid", sAlias);
			return Plugin_Handled;
		}

		bool bLoaded = ConfigReloadConfig(iConfig);

		ConfigGetConfigPath(iConfig, sPath, sizeof(sPath));

		FormatEx(sMessage, sizeof(sMessage), "Admin \"%N\" reloaded config file \"%s\". (zp_config_reload)", client, sPath);

		if (!bLoaded)
		{
			TranslationReplyToCommand(client, "config reload not load", sAlias);

			Format(sMessage, sizeof(sMessage), "\"%s\" -- attempt failed, config file not loaded", sMessage);
		}
		
		LogEvent(true, _, _, _, "Command", sMessage);
	}
	
	gForwardData._OnEngineExecute();

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
	TranslationReplyToCommand(client, "config reload begin");

	static char sAlias[NORMAL_LINE_LENGTH];

	for (int i = File_Cvars; i < File_Size; i++)
	{
		bool bSuccessful = ConfigReloadConfig(i);

		ConfigGetConfigAlias(i, sAlias, sizeof(sAlias));

		if (bSuccessful)
		{
			TranslationReplyToCommand(client, "config reload finish", sAlias);
		}
		else
		{
			TranslationReplyToCommand(client, "config reload falied", sAlias);
		}
	}
	
	LogEvent(true, _, _, _, "Command", "Admin \"%N\" reloaded all config files", client);
	
	gForwardData._OnEngineExecute();

	return Plugin_Handled;
}