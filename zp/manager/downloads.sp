/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          downloads.sp
 *  Type:          Manager 
 *  Description:   Downloads validation.
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
 
/**
 * @section Download config data indexes.
 **/
enum
{
	DOWNLOADS_DATA_PATH
};
/**
 * @endsection
 **/
 
/**
 * @brief Prepare all download data.
 **/
void DownloadsOnLoad(/*void*/)
{
	// Register config file
	ConfigRegisterConfig(File_Downloads, Structure_StringList, CONFIG_FILE_ALIAS_DOWNLOADS);

	// Gets downloads file path
	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_DOWNLOADS, sBuffer, sizeof(sBuffer));

	// If file doesn't exist, then log and stop
	if (!bExists)
	{
		// Log failure and stop plugin
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Missing downloads file: \"%s\"", sBuffer);
		return;
	}

	// Sets path to the config file
	ConfigSetConfigPath(File_Downloads, sBuffer);

	// Load config from file and create array structure
	bool bSuccess = ConfigLoadConfig(File_Downloads, gServerData.Downloads, PLATFORM_LINE_LENGTH);

	// Unexpected error, stop plugin
	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Unexpected error encountered loading: %s", sBuffer);
		return;
	}
	
	// Now copy data to array structure
	DownloadsOnCacheData();
	
	// Sets config data
	ConfigSetConfigLoaded(File_Downloads, true);
	ConfigSetConfigReloadFunc(File_Downloads, GetFunctionByName(GetMyHandle(), "DownloadsOnConfigReload"));
	ConfigSetConfigHandle(File_Downloads, gServerData.Downloads);
}

/**
 * @brief Caches download data from file into arrays.
 **/
void DownloadsOnCacheData(/*void*/)
{
	// Gets config file path
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Downloads, sBuffer, sizeof(sBuffer));
	
	// Log what download file that is loaded
	LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_Downloads, "Config Validation", "Loading downloads from file \"%s\"", sBuffer);

	// Initialize numbers of downloads
	int iDownloadCount;
	int iDownloadValidCount;
	int iDownloadUnValidCount;
	
	// Validate downloads config
	int iDownloads = iDownloadCount = gServerData.Downloads.Length;
	if (!iDownloads)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "No usable data found in downloads config file: \"%s\"", sBuffer);
		return;
	}

	// i = download array index
	for (int i = 0; i < iDownloads; i++)
	{
		// Gets download path
		gServerData.Downloads.GetString(i, sBuffer, sizeof(sBuffer));

		// If file exist
		if (FileExists(sBuffer) || FileExists(sBuffer, true)) 
		{
			// Add to server precache list
			if (DownloadsOnPrecache(sBuffer)) iDownloadValidCount++; else iDownloadUnValidCount++;
		}
		// If doesn't exist, it might be directory ?
		else
		{
			// Opens directory
			DirectoryListing hDirectory = OpenDirectory(sBuffer);
			
			// If directory doesn't exist, try to open folder in .vpk
			if (hDirectory == null)
			{
				// Opens directory
				hDirectory = OpenDirectory(sBuffer, true);
			}

			// If directory doesn't exist, then log, and stop
			if (hDirectory == null)
			{
				// Log download error info
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Incorrect path \"%s\"", sBuffer);
				
				// Remove download from array
				gServerData.Downloads.Erase(i);

				// Subtract one from count
				iDownloads--;

				// Backtrack one index, because we deleted it out from under the loop
				i--;
				continue;
			}
	
			// Initialize variables
			static char sFile[PLATFORM_LINE_LENGTH]; FileType hType;
			
			// Search any files in the directory and precache them
			while (hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
			{
				// Validate file type
				if (hType == FileType_File) 
				{
					// Format full path to file
					Format(sFile, sizeof(sFile), "%s%s", sBuffer, sFile);
					
					// Add to server precache list
					if (DownloadsOnPrecache(sFile)) iDownloadValidCount++; else iDownloadUnValidCount++;
				}
			}
		
			// Close directory
			delete hDirectory;
		}
	}
	
	// Log download validation info
	LogEvent(true, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Downloads, "Config Validation", "Total blocks: \"%d\" | Unsuccessful blocks: \"%d\" | Total: \"%d\" | Successful: \"%d\" | Unsuccessful: \"%d\"", iDownloadCount, iDownloadCount - iDownloads, iDownloadValidCount + iDownloadUnValidCount, iDownloadValidCount, iDownloadUnValidCount);
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void DownloadsOnConfigReload(/*void*/)
{
	// Reloads download config
	DownloadsOnLoad();
}

/*
 * Stocks downloads API.
 */

/**
 * @brief Adds file to the download table.
 *
 * @param sPath             The path to file.
 * @return                  True or false.
 **/
bool DownloadsOnPrecache(char[] sPath)
{
	// Finds the first occurrence of a character in a string
	int iFormat = FindCharInString(sPath, '.', true);
	
	// If path is don't have format, then log, and stop
	if (iFormat == -1)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "Config Validation", "Missing file format: %s", sPath);
		return false;
	}
	
	// Validate sound format
	if (!strcmp(sPath[iFormat], ".mp3", false) || !strcmp(sPath[iFormat], ".wav", false))
	{
		// Precache sound
		return SoundsPrecacheQuirk(sPath);
	}
	// Validate model format
	else if (!strcmp(sPath[iFormat], ".mdl", false))
	{
		// Precache model
		return DecryptPrecacheModel(sPath) ? true : false;   
	}
	// Validate particle format 
	else if (!strcmp(sPath[iFormat], ".pcf", false))
	{
		// Precache paricle
		return DecryptPrecacheParticle(sPath) ? true : false; 
	}
	// Validate meterial format
	else if (!strcmp(sPath[iFormat], ".vmt", false))
	{
		// Precache textures
		return DecryptPrecacheTextures("self", sPath);
	}
	else
	{
		// Add file to download table 
		AddFileToDownloadsTable(sPath);
	}
	
	// Return on success
	return true;
}
