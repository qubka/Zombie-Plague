/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          models.cpp
 *  Type:          Manager
 *  Description:   Models table generator.
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
 
/**
 * Prepare all model/download data.
 **/
void ModelsLoad(/*void*/)
{
	// Initialize char
	static char sPath[PLATFORM_MAX_PATH];

	//*********************************************************************
	//*               PRECACHE OF NEMESIS PLAYER MODEL            		  *
	//*********************************************************************
	
	// Load nemesis player model
	GetConVarString(gCvarList[CVAR_NEMESIS_PLAYER_MODEL], sPath, sizeof(sPath)); 
	
	// Validate player model
	if(!ModelsPlayerPrecache(sPath))
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid nemesis model path. File not found: \"%s\".", sPath);
	}
	
	//*********************************************************************
	//*               PRECACHE OF SURVIVOR PLAYER MODEL            		  *
	//*********************************************************************
	
	// Load survivor player model
	GetConVarString(gCvarList[CVAR_SURVIVOR_PLAYER_MODEL], sPath, sizeof(sPath)); 
	
	// Validate player model
	if(!ModelsPlayerPrecache(sPath))
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid survivor model path. File not found: \"%s\".", sPath);
	}
}

/**
 * Precache models and return model index.
 *   	NOTE: Precache with hiding models include.
 *
 * @param sModel			The model path. 
 **/
stock bool ModelsPlayerPrecache(const char[] sModel)
{
	// If model's path is empty, then stop
	if(!strlen(sModel))
	{
		return false;
	}
	
	// If model didn't exist
	if(!FileExists(sModel))
	{
		// Try to find model in game folder by name
		return ModelsIsStandart(sModel);
	}

	// Search for model files with the specified name and add them to downloads table
	ModelsPrecacheDirFromMainFile(sModel);
	return true;
}

/**
 * Precache weapon models and return model index.
 *
 * @param sModel			The model path. 
 * @return					The model index.
 **/
stock int ModelsViewPrecache(const char[] sModel)
{
	// If model's path is empty, then return 0 index
	if(!strlen(sModel))
	{
		return 0;
	}
	
	// If model didn't exist
	if(!FileExists(sModel))
	{
		// Return error
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid model path. File not found: \"%s\".", sModel);
	}
	
	// Convert model to index
	int iModelIndex = PrecacheModel(sModel);

	// Search for model files with the specified name and add them to downloads table
	ModelsPrecacheDirFromMainFile(sModel);
	
	// Return model index
	return iModelIndex;
}

/**
 * Reads and precache the current directory from a local filename.
 *
 * @param sModel			The model path.
 **/
void ModelsPrecacheDirFromMainFile(const char[] sModel)
{
	// Automatic precache of player models
	int iLenth = FindCharInString(sModel, '/', true);
	
	// The index of the first occurrence of the character in the string
	if(iLenth != -1)
	{
		// Copy one string onto another
		static char sPath[PLATFORM_MAX_PATH];
		strcopy(sPath, sizeof(sPath), sModel);
		
		// Cut the string after last slash
		sPath[iLenth] = '\0';
		
		// Open directory of file
		DirectoryListing sDirectory = OpenDirectory(sPath);
		
		// If doesn't exist stop
		if(sDirectory == NULL)
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error opening directory: %s", sPath);
		}
		
		// Initialize some variables
		static char sFile[NORMAL_LINE_LENGTH];
		static char sLine[PLATFORM_MAX_PATH];
		
		// File types
		FileType sType;
		
		// Search any files in directory and precache them
		while (ReadDirEntry(sDirectory, sFile, NORMAL_LINE_LENGTH, sType)) 
		{ 
			if(sType == FileType_File) 
			{
				// Format full path to file
				Format(sLine, sizeof(sLine), "%s/%s", sPath, sFile);
				
				// Add to server precache list
				DownloadsAddFileToPrecache(sLine);
			}
		}
	
		// Close directory
		delete sDirectory;
	}
}

/**
 * Validates the specified standart models from game folder.
 *
 * @param sModel			The model path for validation.
 * @return					True ifstandart model, false otherwise.
 **/
bool ModelsIsStandart(const char[] sModel)
{
	// Copy one string onto another
	static char sPath[PLATFORM_MAX_PATH];
	strcopy(sPath, sizeof(sPath), sModel);
	
	//*********************************************************************
	//*                VALIDATE STANDART MODELS FILES            		  *
	//*********************************************************************
	
	if(!strncmp(sPath, "models/player/", 14))
	{
		// Given a string, replaces all occurrences of a search string with a empty string
		ReplaceString(sPath, sizeof(sPath), "models/player/", "");
		
		// If path contains standart path
		if(!strncmp(sPath, "custom_player/legacy/", 21))
		{
			// Given a string, replaces all occurrences of a search string with a empty string
			ReplaceString(sPath, sizeof(sPath), "custom_player/legacy/", "");
			
			// If path contains standart path
			if(!strncmp(sPath, "ctm_", 4) || !strncmp(sPath, "tm_", 3))
			{
				// Precache models
				if(!IsModelPrecached(sModel)) PrecacheModel(sModel);
				return true;
			}
		}
		else
		{
			// If path contains standart path
			if(!strncmp(sPath, "ctm_", 4) || !strncmp(sPath, "tm_", 3))
			{
				// Precache models
				if(!IsModelPrecached(sModel)) PrecacheModel(sModel);
				return true;
			}
		}
	}
	
	//*********************************************************************
	//*               VALIDATE STANDART ARM MODELS FILES            	  *
	//*********************************************************************
	
	else if(!strncmp(sPath, "models/weapons/", 15))
	{
		// Given a string, replaces all occurrences of a search string with a empty string
		ReplaceString(sPath, sizeof(sPath), "models/weapons/", "");
		
		// If path contains standart path
		if(!strncmp(sPath, "ct_arms_", 8) || !strncmp(sPath, "t_arms_", 7))
		{
			// Precache models
			if(!IsModelPrecached(sModel)) PrecacheModel(sModel);
			return true;
		}
			
	}
	
	// Model didn't exist, then stop
	return false;
}