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
    // Initialize variable
    static char sPath[PLATFORM_MAX_PATH];

    //*********************************************************************
    //*               PRECACHE OF NEMESIS PLAYER MODEL                    *
    //*********************************************************************
    
    // Validate player model
    gCvarList[CVAR_NEMESIS_PLAYER_MODEL].GetString(sPath, sizeof(sPath));
    if(!ModelsPrecacheStatic(sPath))
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid nemesis model path. File not found: \"%s\"", sPath);
    }
    
    //*********************************************************************
    //*               PRECACHE OF SURVIVOR PLAYER MODEL                   *
    //*********************************************************************
    
    // Validate player model
    gCvarList[CVAR_SURVIVOR_PLAYER_MODEL].GetString(sPath, sizeof(sPath));
    if(!ModelsPrecacheStatic(sPath))
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid survivor model path. File not found: \"%s\"", sPath);
    }
    
    // Validate arm model
    gCvarList[CVAR_SURVIVOR_ARM_MODEL].GetString(sPath, sizeof(sPath));
    if(!ModelsPrecacheStatic(sPath))
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid survivor arm model path. File not found: \"%s\"", sPath);
    }
}

/**
 * Precache models and return model index.
 *
 * @note Precache with engine 'hide' models included.
 *
 * @param sModel            The model path.
 * @return                  The model index if was precached, 0 otherwise.
 **/
stock int ModelsPrecacheStatic(const char[] sModel)
{
    // If model path is empty, then stop
    if(!strlen(sModel))
    {
        return 0;
    }
    
    // If model didn't exist, then
    if(!FileExists(sModel))
    {
        // Try to find model in game folder by name
        return ModelsPrecacheStandart(sModel);
    }
    
    // If model doesn't precache yet, then continue
    if(!IsModelPrecached(sModel))
    {
        // Precache model materails
        ModelsPrecacheMaterials(sModel);

        // Precache model resources
        ModelsPrecacheResources(sModel);
    }
    
    // Return on the success
    return PrecacheModel(sModel, true);
}

/**
 * Precache weapon models and return model index.
 *
 * @param sModel            The model path. 
 * @return                  The model index if was precached, 0 otherwise.
 **/
stock int ModelsPrecacheWeapon(const char[] sModel)
{
    // If model path is empty, then stop
    if(!strlen(sModel))
    {
        return 0;
    }
    
    // If model didn't exist, then
    if(!FileExists(sModel))
    {
        // Return error
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid model path. File not found: \"%s\"", sModel);
    }

    // If model doesn't precache yet, then continue
    if(!IsModelPrecached(sModel))
    {
        // Precache model sounds
        ModelsPrecacheSounds(sModel);
        
        // Precache model materails
        ModelsPrecacheMaterials(sModel);
        
        // Precache model resources
        ModelsPrecacheResources(sModel);
    }
    
    // Return the model index
    return PrecacheModel(sModel, true);
}

/**
 * Reads the current model and precache its resources.
 *
 * @param sModel            The model path.
 **/
stock void ModelsPrecacheResources(const char[] sModel)
{
    // Add file to download table
    AddFileToDownloadsTable(sModel);

    // Initialize some variables
    static char sResource[PLATFORM_MAX_PATH];
    static const char sTypes[3][SMALL_LINE_LENGTH] = { ".dx90.vtx", ".phy", ".vvd" };

    // Finds the first occurrence of a character in a string
    int iFormat = FindCharInString(sModel, '.', true);
    
    // i = resource type
    int iSize = sizeof(sTypes);
    for(int i = 0; i < iSize; i++)
    {
        // Extract value string
        StrExtract(sResource, sModel, 0, iFormat);
        
        // Concatenates one string onto another
        StrCat(sResource, sizeof(sResource), sTypes[i]);
        
        // Validate resource
        if(FileExists(sResource)) 
        {
            // Add file to download table
            AddFileToDownloadsTable(sResource);
        }
    }
}

/**
 * Reads the current model and precache its sounds.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheSounds(const char[] sModel)
{
    // Finds the first occurrence of a character in a string
    int iFormat = FindCharInString(sModel, '.', true);
    
    // If model path is don't have format, then log, and stop
    if(iFormat == -1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Missing file format: %s", sModel);
        return false;
    }
    
    // Extract value string
    static char sPath[PLATFORM_MAX_PATH];
    StrExtract(sPath, sModel, 0, iFormat);

    // Concatenates one string onto another
    StrCat(sPath, sizeof(sPath), "_sounds.txt");
    
    // Validate if a file exists
    bool bExists = FileExists(sPath);
    
    // Open/Create the file
    File hBase = OpenFile(sPath, "at+");

    // If file doesn't exist, then write it
    if(!bExists)
    {
        // Open the file
        File hFile = OpenFile(sModel, "rb");

        // If doesn't exist stop
        if(hFile == INVALID_HANDLE)
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error opening file: \"%s\"", sModel);
            return false;
        }
        
        // Initialize some variables
        int iChar; ///int iNumSeq;

        // Find the total sequence amount
        /*
            hFile.Seek(180, SEEK_SET);
            hFile.ReadInt32(iNumSeq);
        */
        
        do /// Reads a single binary char
        {
            hFile.Seek(2, SEEK_CUR);
            hFile.ReadInt8(iChar);
        } 
        while(iChar == 0);

        // Shift the cursor a bit
        hFile.Seek(1, SEEK_CUR);

        do /// Reads a single binary char
        {
            hFile.Seek(2, SEEK_CUR);
            hFile.ReadInt8(iChar);
        } 
        while(iChar != 0);

        // Loop throught the binary
        while(!hFile.EndOfFile())
        {
            // Reads a UTF8 or ANSI string from a file
            hFile.ReadString(sPath, sizeof(sPath));
            
            // Finds the first occurrence of a character in a string
            iFormat = FindCharInString(sPath, '.', true);

            // Validate format
            if(iFormat != -1) 
            {
                // Validate sound format
                if(!strcmp(sPath[iFormat], ".mp3", false) || !strcmp(sPath[iFormat], ".wav", false))
                {
                    // Format full path to file
                    Format(sPath, sizeof(sPath), "sound/%s", sPath);
                    
                    // Store into the base
                    hBase.WriteLine(sPath);
                    
                    // Add file to download table
                    fnPrecacheSoundQuirk(sPath);
                }
            }
        }

        // Close file
        delete hFile; 
        ///return true;
    }
    else
    {
        // Read lines in the file
        while(hBase.ReadLine(sPath, sizeof(sPath)))
        {
            // Cut out comments at the end of a line
            if(StrContains(sPath, "//") != -1)
            {
                SplitString(sPath, "//", sPath, sizeof(sPath));
            }
            
            // Trim off whitespace
            TrimString(sPath);

            // If line is empty, then stop
            if(!strlen(sPath))
            {
                continue;
            }
            
            // Add file to download table
            fnPrecacheSoundQuirk(sPath);
        }
    }
    
    // Close file
    delete hBase;
    return true;
}

/**
 * Reads the current model and precache its materials.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheMaterials(const char[] sModel)
{
    // Finds the first occurrence of a character in a string
    int iFormat = FindCharInString(sModel, '.', true);
    
    // If model path is don't have format, then log, and stop
    if(iFormat == -1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Missing file format: %s", sModel);
        return false;
    }
    
    // Extract value string
    static char sPath[PLATFORM_MAX_PATH];
    StrExtract(sPath, sModel, 0, iFormat);

    // Concatenates one string onto another
    StrCat(sPath, sizeof(sPath), "_materials.txt");

    // Validate if a file exists
    bool bExists = FileExists(sPath);
    
    // Open/Create the file
    File hBase = OpenFile(sPath, "at+");

    // If file doesn't exist, then write it
    if(!bExists)
    {
        // Open the file
        File hFile = OpenFile(sModel, "rb");

        // If doesn't exist stop
        if(hFile == INVALID_HANDLE)
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error opening file: \"%s\"", sModel);
            return false;
        }
        
        // Initialize some variables
        static char sMaterial[PLATFORM_MAX_PATH]; int iNumMat; int iChar;

        // Find the total materials amount
        hFile.Seek(204, SEEK_SET);
        hFile.ReadInt32(iNumMat);
        hFile.Seek(0, SEEK_END);
        
        do /// Reads a single binary char
        {
            hFile.Seek(-2, SEEK_CUR);
            hFile.ReadInt8(iChar);
        } 
        while(iChar == 0);

        // Shift the cursor a bit
        hFile.Seek(1 , SEEK_CUR);

        do /// Reads a single binary char
        {
            hFile.Seek(-2, SEEK_CUR);
            hFile.ReadInt8(iChar);
        } 
        while(iChar != 0);

        // Reads a UTF8 or ANSI string from a file
        int iPosIndex = hFile.Position;
        hFile.ReadString(sMaterial, sizeof(sMaterial));
        hFile.Seek(iPosIndex, SEEK_SET);
        hFile.Seek(-1, SEEK_CUR);

        // i = material index
        for(int i = 0; i < iNumMat; i++)
        {
            do /// Reads a single binary char
            {
                hFile.Seek(-2, SEEK_CUR);
                hFile.ReadInt8(iChar);
            } 
            while(iChar != 0);

            // Reads a UTF8 or ANSI string from a file
            iPosIndex = hFile.Position;
            hFile.ReadString(sPath, sizeof(sPath));
            hFile.Seek(iPosIndex, SEEK_SET);
            
            // Validate size
            if(!strlen(sPath))
            {
                continue;
            }

            // Finds the first occurrence of a character in a string
            iFormat = FindCharInString(sPath, '\\', true);

            // Validate no format
            if(iFormat != -1)
            {
                // Format full path to directory
                Format(sPath, sizeof(sPath), "materials\\%s", sPath);
        
                // Open the directory
                DirectoryListing hDirectory = OpenDirectory(sPath);
                
                // If doesn't exist stop
                if(hDirectory == INVALID_HANDLE)
                {
                    LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error opening folder: \"%s\"", sPath);
                    continue;
                }

                // Initialize variables
                static char sFile[PLATFORM_MAX_PATH]; FileType hType;
                
                // Search files in the directory
                while(hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
                {
                    // Switch type
                    switch(hType) 
                    {
                        case FileType_File :
                        {
                            // Finds the first occurrence of a character in a string
                            iFormat = FindCharInString(sFile, '.', true);
                    
                            // Validate format
                            if(iFormat != -1) 
                            {
                                // Validate material format
                                if(!strcmp(sFile[iFormat], ".vmt", false))
                                {
                                    // Format full path to file
                                    Format(sFile, sizeof(sFile), "%s%s", sPath, sFile);
                                    
                                    // Store into the base
                                    hBase.WriteLine(sFile);
                                    
                                    // Precache model textures
                                    ModelsPrecacheTextures(sFile);
                                }
                            }
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
            else
            {
                // Format full path to file
                Format(sPath, sizeof(sPath), "materials\\%s%s.vmt", sMaterial, sPath);
                
                // Store into the base
                hBase.WriteLine(sPath);
                
                // Precache model textures
                ModelsPrecacheTextures(sPath);
            }
        }
        
        // Close file
        delete hFile;
        ///return true;
    }
    else
    {
        // Read lines in the file
        while(hBase.ReadLine(sPath, sizeof(sPath)))
        {
            // Cut out comments at the end of a line
            if(StrContains(sPath, "//") != -1)
            {
                SplitString(sPath, "//", sPath, sizeof(sPath));
            }
            
            // Trim off whitespace
            TrimString(sPath);

            // If line is empty, then stop
            if(!strlen(sPath))
            {
                continue;
            }
            
            // Precache model textures
            ModelsPrecacheTextures(sPath);
        }
    }
    
    // Close file
    delete hBase;
    return true;
}

/**
 * Reads the current particle and precache its textures.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheParticle(const char[] sModel)
{
    // Finds the first occurrence of a character in a string
    int iFormat = FindCharInString(sModel, '.', true);
    
    // If model path is don't have format, then log, and stop
    if(iFormat == -1)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Missing file format: %s", sModel);
        return false;
    }
    
    /// https://github.com/VSES/SourceEngine2007/blob/master/src_main/movieobjects/dmeparticlesystemdefinition.cpp
    /*static const char sParticleFuncTypes[48][SMALL_LINE_LENGTH] =
    {
        "DmeParticleSystemDefinition", "DmElement", "DmeParticleChild", "DmeParticleOperator", "particleSystemDefinitions",
        "preventNameBasedLookup", "particleSystemDefinitionDict", "snapshot", "untitled", "child", "drag", "delay", "name",
        "renderers", "operators", "initializers", "emitters", "children", "force", "constraints", "body", "duration", "DEBRIES",
        "color", "render", "radius", "lifetime", "type", "emit", "distance", "rotation", "speed", "fadeout", "DEBRIS", "size",
        "material", "function", "tint", "max", "min", "gravity", "scale", "rate", "time", "fade", "length", "definition", "thickness"
    };*/

    // Add file to download table
    AddFileToDownloadsTable(sModel);

    // Precache generic
    PrecacheGeneric(sModel, true); //! Precache only here
    
    // Extract value string
    static char sPath[PLATFORM_MAX_PATH];
    StrExtract(sPath, sModel, 0, iFormat);

    // Concatenates one string onto another
    StrCat(sPath, sizeof(sPath), "_particles.txt");
    
    // Validate if a file exists
    bool bExists = FileExists(sPath);
    
    // Open/Create the file
    File hBase = OpenFile(sPath, "at+");

    // If file doesn't exist, then write it
    if(!bExists)
    {
        // Open the file
        File hFile = OpenFile(sModel, "rb");

        // If doesn't exist stop
        if(hFile == INVALID_HANDLE)
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error opening file: \"%s\"", sModel);
            return false;
        }

        // Initialize some variables
        int iChar; ///int iNumMat;

        do /// Reads a single binary char
        {
            hFile.Seek(2, SEEK_CUR);
            hFile.ReadInt8(iChar);
        } 
        while(iChar == 0);

        // Shift the cursor a bit
        hFile.Seek(1, SEEK_CUR);

        do /// Reads a single binary char
        {
            hFile.Seek(2, SEEK_CUR);
            hFile.ReadInt8(iChar);
        } 
        while(iChar != 0);

        // Loop throught the binary
        while(!hFile.EndOfFile())
        {
            // Reads a UTF8 or ANSI string from a file
            hFile.ReadString(sPath, sizeof(sPath));

            // Finds the first occurrence of a character in a string
            iFormat = FindCharInString(sPath, '.', true);

            // Validate format
            if(iFormat != -1)
            {
                // Validate material format
                if(!strcmp(sPath[iFormat], ".vmt", false))
                {
                    // Format full path to file
                    Format(sPath, sizeof(sPath), "materials\\%s", sPath);
                    
                    // Store into the base
                    hBase.WriteLine(sPath);
                    
                    // Precache model textures
                    ModelsPrecacheTextures(sPath);
                }
            }
        }

        // Close file
        delete hFile;
        ///return true;
    }
    else
    {
        // Read lines in the file
        while(hBase.ReadLine(sPath, sizeof(sPath)))
        {
            // Cut out comments at the end of a line
            if(StrContains(sPath, "//") != -1)
            {
                SplitString(sPath, "//", sPath, sizeof(sPath));
            }
        
            // Trim off whitespace
            TrimString(sPath);

            // If line is empty, then stop
            if(!strlen(sPath))
            {
                continue;
            }
            
            // Finds the first occurrence of a character in a string
            iFormat = FindCharInString(sPath, '.', true);

            // Validate format
            if(iFormat != -1)
            {
                // Precache model textures
                ModelsPrecacheTextures(sPath);
            }
        }
    }
    
    // Close file
    delete hBase;
    return true;
}

/**
 * Reads the current material and precache its textures.
 *
 * @param sPath             The texture path.
 * @param bDecal            (Optional) If true, the texture will be precached like a decal.
 * @return                  True if was precached, false otherwise.
 **/
stock bool ModelsPrecacheTextures(const char[] sPath)
{
    // Extract value string
    static char sTexture[PLATFORM_MAX_PATH];
    StrExtract(sTexture, sPath, 0, PLATFORM_MAX_PATH);

    // If doesn't exist stop
    if(!FileExists(sTexture))
    {
        LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid material path. File not found: \"%s\"", sTexture);
        return false;
    }

    // Add file to download table
    AddFileToDownloadsTable(sTexture);
    
    // Initialize some variables
    static const char sTypes[4][SMALL_LINE_LENGTH] = { "$baseTexture", "$bumpmap", "$lightwarptexture", "$REFRACTTINTtexture" }; bool bFound[sizeof(sTypes)]; static int iShift;
    
    // Open the file
    File hFile = OpenFile(sTexture, "rt");
    
    // If doesn't exist stop
    if(hFile == INVALID_HANDLE)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error opening file: \"%s\"", sTexture);
    }
    
    // Read lines in the file
    while(hFile.ReadLine(sTexture, sizeof(sTexture)))
    {
        // Cut out comments at the end of a line
        if(StrContains(sTexture, "//") != -1)
        {
            SplitString(sTexture, "//", sTexture, sizeof(sTexture));
        }
        
        // i = texture type
        int iSize = sizeof(sTypes);
        for(int x = 0; x < iSize; x++)
        {
            // Avoid the reoccurrence 
            if(bFound[x]) 
            {
                continue;
            }
            
            // Validate type
            if((iShift = StrContains(sTexture, sTypes[x], false)) != -1)
            {
                // Shift the type away
                iShift += strlen(sTypes[x]) + 1;
        
                // Gets quotes at the beginning and at the end
                int iQuote1 = FindCharInString(sTexture[iShift], '"', true);
                int iQuote2 = FindCharInString(sTexture[iShift], '"', false);
                
                // Check if string without quote, then stop
                if(iQuote1 == -1 || iQuote2 == -1 || iQuote1 == iQuote2)
                {
                    LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Error with parsing \"%s\" in file: \"%s\"", sTypes[x], sPath);
                }
                else
                {
                    // Sets on the success
                    bFound[x] = true;
                    
                    // Extract value string
                    StrExtract(sTexture, sTexture[iShift], iQuote2 + 1, iQuote1);
                    
                    // Format full path to file
                    Format(sTexture, sizeof(sTexture), "materials\\%s.vtf", sTexture);
                    
                    // Validate size
                    if(!strlen(sTexture))
                    {
                        continue;
                    }
                    
                    // Validate material
                    if(FileExists(sTexture))
                    {
                        // Add file to download table
                        AddFileToDownloadsTable(sTexture);
                    }
                    else
                    {
                        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid texture path. File not found: \"%s\"", sTexture);
                    }
                }
            }
        }
    }

    // Close file
    delete hFile; 
    return true;
}

/**
 * Validates the specified standart models.
 *
 * @param sModel            The model path for validation.
 * @return                  The model index if was precached, 0 otherwise.
 **/
stock int ModelsPrecacheStandart(const char[] sModel)
{
    // Validate path
    if(!strncmp(sModel, "models/player/", 14, true))
    {
        // If path contains standart path
        if(!strncmp(sModel[14], "custom_player/legacy/", 21, true))
        {
            // If path contains standart path
            if(!strncmp(sModel[35], "ctm_", 4, true) || !strncmp(sModel[35], "tm_", 3, true))
            {
                // Precache model
                return PrecacheModel(sModel, true);
            }
        }
        else
        {
            // If path contains standart path
            if(!strncmp(sModel[14], "ctm_", 4, true) || !strncmp(sModel[14], "tm_", 3, true))
            {
                // Precache model
                return PrecacheModel(sModel, true);
            }
        }
    }
    else if(!strncmp(sModel, "models/weapons/", 15, true))
    {
        // If path contains standart path
        if(!strncmp(sModel[15], "ct_arms_", 8, true) || !strncmp(sModel[15], "t_arms_", 7, true))
        {
            // Precache model
            return PrecacheModel(sModel, true);
        }
    }

    // Model didn't exist, then stop
    LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Models, "Config Validation", "Invalid model path. File not found: \"%s\"", sModel);
    return 0;
}