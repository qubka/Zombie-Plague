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
    int iDownloads = iDownloadCount = GetArraySize(arrayDownloads);
    if(!iDownloads)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "No usable data found in downloads config file: \"%s\"", sDownloadsPath);
    }

    // Initialize line char
    static char sDownloadPath[PLATFORM_MAX_PATH];
    
    // i = download array index
    for(int i = 0; i < iDownloads; i++)
    {
        // Gets download path
        arrayDownloads.GetString(i, sDownloadPath, sizeof(sDownloadPath));

        // If file exist
        if(FileExists(sDownloadPath) || FindCharInString(sDownloadPath, '@', true) != -1) //! Fix for particles
        {
            // Add to server precache list
            if(fnMultiFilePrecache(sDownloadPath)) iDownloadValidCount++; else iDownloadUnValidCount++;
        }
        // If doesn't exist, it might be directory ?
        else
        {
            // Gets last static char in the string
            int iLastChar = strlen(sDownloadPath) - 1;
            
            // Open directory
            DirectoryListing sDirectory = OpenDirectory(sDownloadPath);
            
            // If directory doesn't exist, then log, and stop
            if(sDirectory == INVALID_HANDLE || sDownloadPath[iLastChar] != '/')
            {
                // Log download error info
                LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Incorrect path \"%s\"", sDownloadPath);
                
                // Remove download from array
                RemoveFromArray(arrayDownloads, i);

                // Subtract one from count
                iDownloads--;

                // Backtrack one index, because we deleted it out from under the loop
                i--;
                continue;
            }
    
            // Initialize some variables
            static char sFile[NORMAL_LINE_LENGTH];
            static char sLine[PLATFORM_MAX_PATH];
            
            // File types
            FileType sType;
            
            // Search any files in directory and precache them
            while(ReadDirEntry(sDirectory, sFile, sizeof(sFile), sType)) 
            { 
                if(sType == FileType_File) 
                {
                    // Format full path to file
                    Format(sLine, sizeof(sLine), "%s%s", sDownloadPath, sFile);
                    
                    // Add to server precache list
                    if(fnMultiFilePrecache(sLine)) iDownloadValidCount++; else iDownloadUnValidCount++;
                }
            }
        
            // Close directory
            delete sDirectory;
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