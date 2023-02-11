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
void DownloadsOnLoad()
{
	ConfigRegisterConfig(File_Downloads, Structure_StringList, CONFIG_FILE_ALIAS_DOWNLOADS);

	static char sBuffer[PLATFORM_LINE_LENGTH];
	bool bExists = ConfigGetFullPath(CONFIG_FILE_ALIAS_DOWNLOADS, sBuffer, sizeof(sBuffer));

	if (!bExists)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Missing downloads file: \"%s\"", sBuffer);
		return;
	}

	ConfigSetConfigPath(File_Downloads, sBuffer);

	bool bSuccess = ConfigLoadConfig(File_Downloads, gServerData.Downloads, PLATFORM_LINE_LENGTH);

	if (!bSuccess)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Unexpected error encountered loading: %s", sBuffer);
		return;
	}
	
	DownloadsOnCacheData();
	
	ConfigSetConfigLoaded(File_Downloads, true);
	ConfigSetConfigReloadFunc(File_Downloads, GetFunctionByName(GetMyHandle(), "DownloadsOnConfigReload"));
	ConfigSetConfigHandle(File_Downloads, gServerData.Downloads);
}

/**
 * @brief Caches download data from file into arrays.
 **/
void DownloadsOnCacheData()
{
	static char sBuffer[PLATFORM_LINE_LENGTH];
	ConfigGetConfigPath(File_Downloads, sBuffer, sizeof(sBuffer));
	
	LogEvent(true, LogType_Normal, LOG_DEBUG, LogModule_Downloads, "Config Validation", "Loading downloads from file \"%s\"", sBuffer);

	int iDownloadCount;
	int iDownloadValidCount;
	int iDownloadUnValidCount;
	
	int iDownloads = iDownloadCount = gServerData.Downloads.Length;
	if (!iDownloads)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "No usable data found in downloads config file: \"%s\"", sBuffer);
		return;
	}

	for (int i = 0; i < iDownloads; i++)
	{
		gServerData.Downloads.GetString(i, sBuffer, sizeof(sBuffer));

		if (FileExists(sBuffer) || FileExists(sBuffer, true)) 
		{
			if (DownloadsOnPrecache(sBuffer)) iDownloadValidCount++; else iDownloadUnValidCount++;
		}
		else
		{
			DirectoryListing hDirectory = OpenDirectory(sBuffer);
			
			if (hDirectory == null)
			{
				hDirectory = OpenDirectory(sBuffer, true);
			}

			if (hDirectory == null)
			{
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Downloads, "Config Validation", "Incorrect path \"%s\"", sBuffer);
				
				gServerData.Downloads.Erase(i);

				iDownloads--;

				i--;
				continue;
			}
	
			static char sFile[PLATFORM_LINE_LENGTH]; FileType hType;
			
			while (hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
			{
				if (hType == FileType_File) 
				{
					Format(sFile, sizeof(sFile), "%s%s", sBuffer, sFile);
					
					if (DownloadsOnPrecache(sFile)) iDownloadValidCount++; else iDownloadUnValidCount++;
				}
			}
		
			delete hDirectory;
		}
	}
	
	LogEvent(true, LogType_Normal, LOG_DEBUG_DETAIL, LogModule_Downloads, "Config Validation", "Total blocks: \"%d\" | Unsuccessful blocks: \"%d\" | Total: \"%d\" | Successful: \"%d\" | Unsuccessful: \"%d\"", iDownloadCount, iDownloadCount - iDownloads, iDownloadValidCount + iDownloadUnValidCount, iDownloadValidCount, iDownloadUnValidCount);
}

/**
 * @brief Called when configs are being reloaded.
 **/
public void DownloadsOnConfigReload()
{
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
	int iFormat = FindCharInString(sPath, '.', true);
	
	if (iFormat == -1)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Engine, "Config Validation", "Missing file format: %s", sPath);
		return false;
	}
	
	if (!strcmp(sPath[iFormat], ".mp3", false) || !strcmp(sPath[iFormat], ".wav", false))
	{
		return SoundsPrecacheQuirk(sPath);
	}
	else if (!strcmp(sPath[iFormat], ".mdl", false))
	{
		return DecryptPrecacheModel(sPath) ? true : false;   
	}
	else if (!strcmp(sPath[iFormat], ".pcf", false))
	{
		return DecryptPrecacheParticle(sPath) ? true : false; 
	}
	else if (!strcmp(sPath[iFormat], ".vmt", false))
	{
		return DecryptPrecacheTextures("self", sPath);
	}
	else
	{
		AddFileToDownloadsTable(sPath);
	}
	
	return true;
}
