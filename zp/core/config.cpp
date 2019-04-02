/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          config.inc
 *  Type:          Core
 *  Description:   Config API and executing.
 *
 *  Copyright (C) 2015-2019  Greyscale, Richard Helgeby
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

/*
    Using config API:
    
    -Before any of these helper functions can be used on a config file you must
     "register" the module handling the data.
    
    Example:
    
    ConfigRegisterConfig(File_Example, Structure_List, "example");
    
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
 * @section Config file reference aliases.
 **/
#define CONFIG_FILE_ALIAS_CVARS         "cvars"
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
/**
 * @endsection
 **/

/**
 * @section Config file pathes.
 **/
#define CONFIG_PATH_CVARS               "cfg/sourcemod/zombieplague.cfg"
#define CONFIG_PATH_DOWNLOADS           "zombieplague/downloads.ini"
#define CONFIG_PATH_SOUNDS              "zombieplague/sounds.ini" 
#define CONFIG_PATH_WEAPONS             "zombieplague/weapons.ini"
#define CONFIG_PATH_MENUS               "zombieplague/menus.ini"
#define CONFIG_PATH_HITGROUPS           "zombieplague/hitgroups.ini"
#define CONFIG_PATH_COSTUMES            "zombieplague/costumes.ini"
#define CONFIG_PATH_EXTRAITEMS          "zombieplague/extraitems.ini"    
#define CONFIG_PATH_GAMEMODES           "zombieplague/gamemodes.ini"
#define CONFIG_PATH_CLASSES             "zombieplague/classes.ini"
#define CONFIG_PATH_LEVELS              "zombieplague/levels.ini"
/**
 * @endsection
 **/
 
/**
 * @section List of config formats used by the plugin.
 **/
enum ConfigStructure
{
    Structure_List,               /** Config is structured as a simple list of strings. */
    Structure_ArrayList,          /** Config is structured as an array list of strings. */
    Structure_Keyvalue,           /** Config is a keyvalue structure */
};
/**
 * @endsection
 **/
 
/**
 * @section List of config files used by the plugin.
 **/
enum ConfigFile
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
    File_Levels                   /** <sourcemod root>/zombieplague/levels.ini (default) */
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
ConfigData gConfigData[ConfigFile];

/**
 * @section Actions to use when working on key/values.
 **/
enum ConfigKvAction
{
    KvAction_Create,    /** Creates a key. */
    KvAction_KVDelete,  /** Delete a key. */
    KvAction_KVSet,     /** Modify setting of a key. */
    KvAction_KVGet,     /** Get setting of a key. */
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
    gServerData.Config   = LoadGameConfigFile(PLUGIN_CONFIG);
    gServerData.SDKHooks = LoadGameConfigFile("sdkhooks.games");
    gServerData.SDKTools = LoadGameConfigFile("sdktools.games");
    gServerData.CStrike  = LoadGameConfigFile("sm-cstrike.games");
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
stock void ConfigRegisterConfig(ConfigFile iFile, ConfigStructure iStructure, char[] sAlias = "")
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
stock void ConfigSetConfigLoaded(ConfigFile iConfig, bool bLoaded)
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
stock void ConfigSetConfigStructure(ConfigFile iConfig, ConfigStructure iStructure)
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
stock void ConfigSetConfigReloadFunc(ConfigFile iConfig, Function iReloadfunc)
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
stock void ConfigSetConfigHandle(ConfigFile iConfig, ArrayList iFile)
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
stock void ConfigSetConfigPath(ConfigFile iConfig, char[] sPath)
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
stock void ConfigSetConfigAlias(ConfigFile iConfig, char[] sAlias)
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
stock bool ConfigIsConfigLoaded(ConfigFile iConfig)
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
stock ConfigStructure ConfigGetConfigStructure(ConfigFile iConfig)
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
stock Function ConfigGetConfigReloadFunc(ConfigFile iConfig)
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
stock ArrayList ConfigGetConfigHandle(ConfigFile iConfig)
{
    // Return load status
    return gConfigData[iConfig].Handler;
}

/**
 * @brief Returns the path for a given config file entry.
 * 
 * @param iConfig           Config file to get path of. (see ConfigFile enum)
 **/
stock void ConfigGetConfigPath(ConfigFile iConfig, char[] sPath, int iMaxLen)
{
    // Copy path to return string
    strcopy(sPath, iMaxLen, gConfigData[iConfig].Path);
}

/**
 * @brief Returns the alias for a given config file entry.
 * 
 * @param iConfig           Config file to get alias of. (see ConfigFile enum)
 **/
stock void ConfigGetConfigAlias(ConfigFile iConfig, char[] sAlias, int iMaxLen)
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
stock bool ConfigLoadConfig(ConfigFile iConfig, ArrayList &arrayConfig, int blockSize = NORMAL_LINE_LENGTH)
{
    // If array hasn't been created, then create
    if(arrayConfig == null)
    {
        // Creates array in handle
        arrayConfig = CreateArray(blockSize);
    }
    
    // Initialize buffer char
    static char sLine[PLATFORM_LINE_LENGTH];
    
    // Gets config structure
    ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);

    // Validate structure
    switch(iStructure)
    {
        case Structure_List :
        {
            // Opens file
            File hFile;
            bool bSuccess = ConfigOpenConfigFile(iConfig, hFile);

            // If config file failed to open, then stop
            if(!bSuccess)
            {
                return false;
            }

            // Clear out array
            arrayConfig.Clear();

            // Read lines in the file
            while(hFile.ReadLine(sLine, sizeof(sLine)))
            {
                // Cut out comments at the end of a line
                if(StrContains(sLine, "//", false) != -1)
                {
                    SplitString(sLine, "//", sLine, sizeof(sLine));
                }

                // Trim off whitespace
                TrimString(sLine);
                
                // Strips a quote pair off a string 
                StripQuotes(sLine);

                // If line is empty, then stop
                if(!hasLength(sLine))
                {
                    continue;
                }

                // Push line into array
                arrayConfig.PushString(sLine);
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
            if(!bSuccess)
            {
                return false;
            }
            
            // Destroy all old data
            ConfigClearKvArray(arrayConfig);

            // Read lines in the file
            while(hFile.ReadLine(sLine, sizeof(sLine)))
            {
                // Cut out comments at the end of a line
                if(StrContains(sLine, "//", false) != -1)
                {
                    SplitString(sLine, "//", sLine, sizeof(sLine));
                }

                // Trim off whitespace
                TrimString(sLine);

                // If line is empty, then stop
                if(!hasLength(sLine))
                {
                    continue;
                }

                // Creates new array to store information for config entry
                ArrayList arrayConfigEntry = CreateArray(blockSize);

                // Push line into array
                arrayConfigEntry.PushString(sLine); // Index: 0

                // Store this handle in the main array
                arrayConfig.Push(arrayConfigEntry);
            }
            
            // We're done this file, so now we can destory it from memory
            delete hFile;
            return true;
        }
        
        case Structure_Keyvalue :
        {
            // Opens file
            KeyValues hKeyvalue;
            bool bSuccess = ConfigOpenConfigFile(iConfig, hKeyvalue);
            
            // If config file failed to open, then stop
            if(!bSuccess)
            {
                return false;
            }
            
            // Destroy all old data
            ConfigClearKvArray(arrayConfig);
            
            // Read keys in the file
            if(hKeyvalue.GotoFirstSubKey())
            {
                do
                {
                    // Creates new array to store information for config entry
                    ArrayList arrayConfigEntry = CreateArray(blockSize);
                    
                    // Push the key name into the config entry array
                    static char sKeyName[NORMAL_LINE_LENGTH];
                    hKeyvalue.GetSectionName(sKeyName, sizeof(sKeyName));

                    // Converts uppercase chars
                    StringToLower(sKeyName);
                    
                    // Push data into array
                    arrayConfigEntry.PushString(sKeyName); // Index: 0
                    
                    // Store this handle in the main array
                    arrayConfig.Push(arrayConfigEntry);
                } 
                while(hKeyvalue.GotoNextKey());
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
stock bool ConfigReloadConfig(ConfigFile iConfig)
{
    // If file isn't loaded, then stop
    bool bLoaded = ConfigIsConfigLoaded(iConfig);
    if(!bLoaded)
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
stock bool ConfigOpenConfigFile(ConfigFile iConfig, Handle &hConfig)
{
    // Gets config structure
    ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);
    
    // Gets config file path
    static char sConfigPath[PLATFORM_LINE_LENGTH];
    ConfigGetConfigPath(iConfig, sConfigPath, sizeof(sConfigPath));
    
    // Gets config alias
    static char sConfigAlias[NORMAL_LINE_LENGTH];
    ConfigGetConfigAlias(iConfig, sConfigAlias, sizeof(sConfigAlias));
    
    // Validate structure
    switch(iStructure)
    {
        case Structure_Keyvalue :
        {
            // Creates config
            hConfig = CreateKeyValues(sConfigAlias);
            return FileToKeyValues(hConfig, sConfigPath);
        }
        
        default :
        {
            // Opens file
            hConfig = OpenFile(sConfigPath, "r");
            
            // If file couldn't be opened, then stop
            if(hConfig == null)
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
stock bool ConfigKeyvalueTreeSetting(ConfigFile iConfig, ConfigKvAction mAction = KvAction_Create, char[][] sKeys, int keysMax, char[] sSetting = "", char[] sValue = "", int iMaxLen = 0)
{
    // Gets config file structure
    ConfigStructure iStructure = ConfigGetConfigStructure(iConfig);
    
    // If the config is any other structure beside keyvalue, then stop
    if(iStructure != Structure_Keyvalue)
    {
        return false;
    }
    
    // Retrieve handle of the keyvalue tree
    KeyValues hConfig;
    bool bSuccess = ConfigOpenConfigFile(iConfig, hConfig);
    
    // If the file couldn't be opened, then stop
    if(!bSuccess)
    {
        return false;
    }
    
    // Rewind keyvalue tree
    hConfig.Rewind();
    
    // i = keys index.
    // Traverse into the keygroup, stop if it fails
    for(int i = 0; i < keysMax; v++)
    {
        // If key is empty, then break the loop
        if(!hasLength(sKeys[i]))
        {
            break;
        }
        
        // Try to jump to next level in the transversal stack, create key if specified
        bool bExists = hConfig.JumpToKey(sKeys[i], (mAction == KvAction_Create));
        
        // If exists is false, then stop
        if(!bExists)
        {
            // Key doesn't exist
            return false;
        }
    }
    
    // Switch the kv action
    switch(mAction)
    {
        case KvAction_Create :
        {
            if(!hasLength(sSetting) || !hasLength(sValue))
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
    for(int i = 0; i < iSize; i++)
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
 *
 * @return                  Config file entry, ConfigInvalid is returned if alias was not found.
 **/
stock ConfigFile ConfigAliasToConfigFile(char[] sAlias)
{
    static char sCheckAlias[NORMAL_LINE_LENGTH];
    
    // i = config file entry index
    for(int i = 0; i < sizeof(gConfigData); i++)
    {
        // Gets config alias.
        ConfigGetConfigAlias(view_as<ConfigFile>(i), sCheckAlias, sizeof(sCheckAlias));
        
        // If alias doesn't match, then skip
        if(!strcmp(sAlias, sCheckAlias, false))
        {
            // Return config file entry
            return view_as<ConfigFile>(i);
        }
    }
    
    // Invalid config file
    return File_Invalid;
}

/**
 * @brief Load config file.
 * 
 * @param sFolder           The path input.
 * @param sPath             The path output.
 * @param bRoot             This should be used instead of directly referencing to sourcemod root.
 * @return                  True if the file exists, false if not.
 **/
stock bool ConfigGetFullPath(char[] sFolder, char[] sPath, bool bRoot = true)
{
    // Validate root
    if(bRoot)
    {
        // Build full path in return string
        BuildPath(Path_SM, sPath, PLATFORM_LINE_LENGTH, sFolder);
    }
    else
    {
        // Copy folder to path buffer
        strcopy(sPath, PLATFORM_LINE_LENGTH, sFolder);
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
    if(!strcmp(sOption, "yes", false) || !strcmp(sOption, "on", false) || !strcmp(sOption, "true", false) || !strcmp(sOption, "1", false))
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
 * @param targetIndex       The target to use as translation language.
 **/
stock void ConfigBoolToSetting(bool bOption, char[] sOption, int iMaxLen, bool bYesNo = true, int targetIndex = LANG_SERVER)
{
    // Initialize buffer char
    static char sBuffer[10];
    
    // Sets language to target
    SetGlobalTransTarget(targetIndex);
    
    // If option is true, then copy "yes" to return string
    if(bOption)
    {
        // Gets yes/no translations for the target
        if(bYesNo)
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
        if(bYesNo)
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
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ConfigMenuOnCommandCatched(int clientIndex, int iArguments)
{
    ConfigMenu(clientIndex);
    return Plugin_Handled;
}

/**
 * Console command callback (zp_config_reload)
 * @brief Reloads a config file and forwards event to modules.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ConfigReloadOnCommandCatched(int clientIndex, int iArguments)
{
    // If not enough arguments given, then stop
    if(iArguments < 1)
    {
        // Write syntax info
        TranslationReplyToCommand(clientIndex, "config reload");
        TranslationReplyToCommand(clientIndex, "config reload commands");
        TranslationReplyToCommand(clientIndex, "config reload commands aliases", CONFIG_FILE_ALIAS_CVARS, CONFIG_FILE_ALIAS_DOWNLOADS, CONFIG_FILE_ALIAS_WEAPONS, CONFIG_FILE_ALIAS_SOUNDS, CONFIG_FILE_ALIAS_MENUS, CONFIG_FILE_ALIAS_HITGROUPS, CONFIG_FILE_ALIAS_COSTUMES, CONFIG_FILE_ALIAS_EXTRAITEMS, CONFIG_FILE_ALIAS_GAMEMODES, CONFIG_PATH_CLASSES, CONFIG_PATH_LEVELS);
        return Plugin_Handled;
    }

    // Initialize variables
    static char sAlias[NORMAL_LINE_LENGTH];
    static char sPath[PLATFORM_LINE_LENGTH];
    static char sMessage[PLATFORM_LINE_LENGTH];

    // i = config file entry index
    int iArgs = GetCmdArgs();
    for(int i = 1; i <= iArgs; i++)
    {
        // Gets alias to restrict
        GetCmdArg(i, sAlias, sizeof(sAlias));

        // If alias is invalid, then stop
        ConfigFile iConfig = ConfigAliasToConfigFile(sAlias);
        if(iConfig == File_Invalid)
        {
            // Write error info
            TranslationReplyToCommand(clientIndex, "config reload invalid", sAlias);
            return Plugin_Handled;
        }

        // Reloads config file
        bool bLoaded = ConfigReloadConfig(iConfig);

        // Gets config file path
        ConfigGetConfigPath(iConfig, sPath, sizeof(sPath));

        // Format log message
        FormatEx(sMessage, sizeof(sMessage), "Admin \"%N\" reloaded config file \"%s\". (zp_config_reload)", clientIndex, sPath);

        // If file isn't loaded then tell client, then stop
        if(!bLoaded)
        {
            // Write error info
            TranslationReplyToCommand(clientIndex, "config reload not load", sAlias);

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
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ConfigReloadAllOnCommandCatched(int clientIndex, int iArguments)
{
    // Begin statistics
    TranslationReplyToCommand(clientIndex, "config reload begin");

    // Initialize alias char
    static char sAlias[NORMAL_LINE_LENGTH];

    // i = config file entry index
    for(int i = 0; i < sizeof(gConfigData); i++)
    {
        // Reloads config file
        bool bSuccessful = ConfigReloadConfig(view_as<ConfigFile>(i));

        // Gets config alias
        ConfigGetConfigAlias(view_as<ConfigFile>(i), sAlias, sizeof(sAlias));

        // Validate load
        if(bSuccessful)
        {
            TranslationReplyToCommand(clientIndex, "config reload finish", sAlias);
        }
        else
        {
            TranslationReplyToCommand(clientIndex, "config reload falied", sAlias);
        }
    }
    
    // Log action to game events
    LogEvent(true, _, _, _, "Command", "Admin \"%N\" reloaded all config files", clientIndex);
    
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
 * @param clientIndex       The client index.
 **/
void ConfigMenu(int clientIndex) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Initialize variables
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sAlias[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];

    // Creates menu handle
    Menu hMenu = CreateMenu(ConfigMenuSlots);

    // Sets language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "configs menu");
    
    // i = config file entry index
    int iSize = sizeof(gConfigData);
    for(int i = 0; i < iSize; i++)
    {
        // Gets config alias
        ConfigGetConfigAlias(view_as<ConfigFile>(i), sAlias, sizeof(sAlias));
        
        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "config menu reload", sAlias);
        
        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer);
    }
    
    // If there are no cases, add an "(Empty)" line
    if(!iSize)
    {
        // Format some chars for showing in menu
        FormatEx(sBuffer, sizeof(sBuffer), "%t", "empty");
        hMenu.AddItem("empty", sBuffer, ITEMDRAW_DISABLED);
    }
    
    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT | MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * @brief Called when client selects option in the config menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int ConfigMenuSlots(Menu hMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hMenu;
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Opens menu back
                int iD[2]; iD = MenusCommandToArray("zp_config_menu");
                if(iD[0] != -1) SubMenu(clientIndex, iD[0]);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }

            // Gets menu info
            static char sBuffer[SMALL_LINE_LENGTH];
            hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
            ConfigFile iD = view_as<ConfigFile>(StringToInt(sBuffer));
            
            // Gets config alias
            ConfigGetConfigAlias(iD, sBuffer, sizeof(sBuffer));
            
            // Reloads config file
            bool bSuccessful = ConfigReloadConfig(iD);
            
            // Validate load
            if(bSuccessful)
            {
                TranslationPrintToChat(clientIndex, "config reload finish", sBuffer);
            }
            else
            {
                TranslationPrintToChat(clientIndex, "config reload falied", sBuffer);
            }
            
            // Log action to game events
            LogEvent(true, _, _, _, "Command", "Admin \"%N\" reloaded all config files", clientIndex);
            
            // Opens config menu back
            ConfigMenu(clientIndex);
        }
    }
}