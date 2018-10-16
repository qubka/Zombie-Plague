/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          downloads.cpp
 *  Type:          Manager 
 *  Description:   Downloads table generator.
 *
 *  Copyright (C) 2015-2018 Greyscale, Richard Helgeby
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
 * Array handle to store downloadtable config data.
 **/
ArrayList arrayDownloads;

/**
 * Prepare all model/download data.
 **/
void DownloadsLoad(/*void*/)
{
    // Register config file
    ConfigRegisterConfig(File_Downloads, Structure_List, CONFIG_FILE_ALIAS_DOWNLOADS);

    // Gets downloads file path
    static char sDownloadsPath[PLATFORM_MAX_PATH];
    bool bExists = ConfigGetCvarFilePath(CVAR_CONFIG_PATH_DOWNLOADS, sDownloadsPath);

    // If file doesn't exist, then log and stop
    if(!bExists)
    {
        // Log failure and stop plugin
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Missing downloads file: \"%s\"", sDownloadsPath);
    }

    // Sets the path to the config file
    ConfigSetConfigPath(File_Downloads, sDownloadsPath);

    // Load config from file and create array structure
    bool bSuccess = ConfigLoadConfig(File_Downloads, arrayDownloads, PLATFORM_MAX_PATH);

    // Unexpected error, stop plugin
    if(!bSuccess)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Unexpected error encountered loading: %s", sDownloadsPath);
    }

    // Log what download file that is loaded
    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Loading downloads from file \"%s\"", sDownloadsPath);

    // Initialize numbers of downloads
    int iDownloadCount;
    int iDownloadValidCount;
    int iDownloadUnValidCount;
    
    // Validate downloads config
    int iDownloads = iDownloadCount = arrayDownloads.Length;
    if(!iDownloads)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "No usable data found in downloads config file: \"%s\"", sDownloadsPath);
    }

    // i = download array index
    for(int i = 0; i < iDownloads; i++)
    {
        // Gets download path
        sDownloadsPath[0] = '\0'; arrayDownloads.GetString(i, sDownloadsPath, sizeof(sDownloadsPath));

        // If file exist
        if(FileExists(sDownloadsPath) || FindCharInString(sDownloadsPath, '@', true) != -1) //! Fix for particles
        {
            // Add to server precache list
            if(DownloadsOnPrecache(sDownloadsPath)) iDownloadValidCount++; else iDownloadUnValidCount++;
        }
        // If doesn't exist, it might be directory ?
        else
        {
            // Open directory
            DirectoryListing hDirectory = OpenDirectory(sDownloadsPath);
            
            // If directory doesn't exist, then log, and stop
            if(hDirectory == INVALID_HANDLE)
            {
                // Log download error info
                LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Incorrect path \"%s\"", sDownloadsPath);
                
                // Remove download from array
                arrayDownloads.Erase(i);

                // Subtract one from count
                iDownloads--;

                // Backtrack one index, because we deleted it out from under the loop
                i--;
                continue;
            }
    
            // Initialize variables
            static char sFile[PLATFORM_MAX_PATH];
            
            // Initialize types
            FileType hType;
            
            // Search any files in the directory and precache them
            while(hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
            {
                // Switch type
                switch(hType) 
                {
                    case FileType_File :
                    {
                        // Format full path to file
                        Format(sFile, sizeof(sFile), "%s%s", sDownloadsPath, sFile);
                        
                        // Add to server precache list
                        if(DownloadsOnPrecache(sFile)) iDownloadValidCount++; else iDownloadUnValidCount++;
                    }
                    
                    /*case FileType_Unknown :
                    {
                        
                    }
                    
                    case FileType_Directory : 
                    {
                        
                    }*/
                }
            }
        
            // Close directory
            delete hDirectory;
        }
    }
    
    // Log download validation info
    LogEvent(true, LogType_Normal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Total blocks: %d | Unsuccessful blocks: %d | Total: %d | Successful: %d | Unsuccessful: %d", iDownloadCount, iDownloadCount - iDownloads, iDownloadValidCount + iDownloadUnValidCount, iDownloadValidCount, iDownloadUnValidCount);
    
    // Sets config data
    ConfigSetConfigLoaded(File_Downloads, true);
    ConfigSetConfigReloadFunc(File_Downloads, GetFunctionByName(GetMyHandle(), "DownloadsOnConfigReload"));
    ConfigSetConfigHandle(File_Downloads, arrayDownloads);
}

/**
 * Called when configs are being reloaded.
 * 
 * @param iConfig           The config being reloaded. (only if 'all' is false)
 **/
public void DownloadsOnConfigReload(ConfigFile iConfig)
{
    // Reload download config
    DownloadsLoad();
}

/**
 * Adds file to the download table.
 *
 * @param sPath             The path to file.
 * @return                  True or false.
 **/
stock bool DownloadsOnPrecache(const char[] sPath)
{
    // Finds the first occurrence of a character in a string
    int iFormat = FindCharInString(sPath, '.', true);
    
    // If path is don't have format, then log, and stop
    if(iFormat == -1)
    {
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "Config Validation", "Missing file format: %s", sPath);
        return false;
    }
    
    // Validate sound format
    if(!strcmp(sPath[iFormat], ".mp3", false) || !strcmp(sPath[iFormat], ".wav", false))
    {
        // Precache sound
        return fnPrecacheSoundQuirk(sPath);
    }
    // Validate model format
    else if(!strcmp(sPath[iFormat], ".mdl", false))
    {
        // Precache model
        return ModelsPrecacheStatic(sPath) ? true : false;   
    }
    // Validate particle format 
    else if(!strcmp(sPath[iFormat], ".pcf", false))
    {
        // Precache paricle
        return ModelsPrecacheParticle(sPath);
    }
    // Validate meterial format
    else if(!strcmp(sPath[iFormat], ".vmt", false))
    {
        // Precache textures
        return ModelsPrecacheTextures(sPath);
    }
    
    // Return on success
    return true;
}