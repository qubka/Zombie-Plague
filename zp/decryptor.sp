/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          decryptor.sp
 *  Type:          Core
 *  Description:   Models decryptor.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 * @brief Precache models and return model index.
 *
 * @note Precache with engine 'hide' models included.
 *
 * @param sModel            The model path.
 * @return                  The model index if was precached, 0 otherwise.
 **/
int DecryptPrecacheModel(const char[] sModel)
{
	if (!hasLength(sModel))
	{
		return 0;
	}
	
	if (!FileExists(sModel))
	{
		if (FileExists(sModel, true))
		{
			return PrecacheModel(sModel, true);
		}
		
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Invalid model path. File not found: \"%s\"", sModel);
		return 0;
	}
	
	if (!IsModelPrecached(sModel))
	{
		DecryptPrecacheMaterials(sModel);

		DecryptPrecacheResources(sModel);
	}
	
	return PrecacheModel(sModel, true);
}

/**
 * @brief Precache weapon models and return model index.
 *
 * @param sModel            The model path. 
 * @return                  The model index if was precached, 0 otherwise.
 **/
int DecryptPrecacheWeapon(const char[] sModel)
{
	if (!hasLength(sModel))
	{
		return 0;
	}
	
	if (!FileExists(sModel))
	{
		if (FileExists(sModel, true))
		{
			return PrecacheModel(sModel, true);
		}

		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Invalid model path. File not found: \"%s\"", sModel);
		return 0;
	}

	if (!IsModelPrecached(sModel))
	{
		DecryptPrecacheSounds(sModel);
		
		DecryptPrecacheMaterials(sModel);
		
		DecryptPrecacheResources(sModel);
	}
	
	return PrecacheModel(sModel, true);
}

/**
 * @brief Precache particle models and return model index.
 *
 * @param sModel            The model path. 
 * @return                  The model index if was precached, 0 otherwise.
 **/
int DecryptPrecacheParticle(const char[] sModel)
{
	if (!hasLength(sModel))
	{
		return 0;
	}
	
	if (!FileExists(sModel))
	{
		if (FileExists(sModel, true))
		{
			return PrecacheGeneric(sModel, true);
		}

		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Invalid model path. File not found: \"%s\"", sModel);
		return 0;
	}

	/**if (!IsGenericPrecached(sModel))**/
	
	DecryptPrecacheEffects(sModel);
	
	return PrecacheGeneric(sModel, true);
}

/**
 * @brief Reads the current model and precache its resources.
 *
 * @param sModel            The model path.
 **/
void DecryptPrecacheResources(const char[] sModel)
{
	AddFileToDownloadsTable(sModel);

	static char sResource[PLATFORM_LINE_LENGTH];
	static char sTypes[3][SMALL_LINE_LENGTH] = { ".dx90.vtx", ".phy", ".vvd" };

	int iFormat = FindCharInString(sModel, '.', true);
	
	int iSize = sizeof(sTypes);
	for (int i = 0; i < iSize; i++)
	{
		ExtractString(sResource, sModel, 0, iFormat);
		
		StrCat(sResource, sizeof(sResource), sTypes[i]);
		
		if (FileExists(sResource)) 
		{
			AddFileToDownloadsTable(sResource);
		}
	}
}

/**
 * @brief Reads the current model and precache its sounds.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
bool DecryptPrecacheSounds(const char[] sModel)
{
	int iFormat = FindCharInString(sModel, '.', true);
	
	if (iFormat == -1)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Missing file format: %s", sModel);
		return false;
	}
	
	static char sPath[PLATFORM_LINE_LENGTH];
	ExtractString(sPath, sModel, 0, iFormat);

	StrCat(sPath, sizeof(sPath), "_sounds.txt");
	
	bool bExists = FileExists(sPath);
	
	File hBase = OpenFile(sPath, "at+");

	if (!bExists)
	{
		File hFile = OpenFile(sModel, "rb");

		if (hFile == null)
		{
			DeleteFile(sPath);
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Error opening file: \"%s\"", sModel);
			return false;
		}
		
		int iChar; ///int iNumSeq;

		/*
			hFile.Seek(180, SEEK_SET);
			hFile.ReadInt32(iNumSeq);
		*/
		
		do /// Reads a single binary char
		{
			hFile.Seek(2, SEEK_CUR);
			hFile.ReadInt8(iChar);
		} 
		while (iChar == 0);

		hFile.Seek(1, SEEK_CUR);

		do /// Reads a single binary char
		{
			hFile.Seek(2, SEEK_CUR);
			hFile.ReadInt8(iChar);
		} 
		while (iChar);

		while (!hFile.EndOfFile())
		{
			hFile.ReadString(sPath, sizeof(sPath));
			
			iFormat = FindCharInString(sPath, '.', true);

			if (iFormat != -1) 
			{
				if (!strcmp(sPath[iFormat], ".mp3", false) || !strcmp(sPath[iFormat], ".wav", false))
				{
					Format(sPath, sizeof(sPath), "sound/%s", sPath);
					
					hBase.WriteLine(sPath);
					
					SoundsPrecacheQuirk(sPath);
				}
			}
		}

		delete hFile; 
	}
	else
	{
		while (hBase.ReadLine(sPath, sizeof(sPath)))
		{
			SplitString(sPath, "//", sPath, sizeof(sPath));
			
			TrimString(sPath);

			if (!hasLength(sPath))
			{
				continue;
			}
			
			SoundsPrecacheQuirk(sPath);
		}
	}
	
	delete hBase;
	return true;
}

/**
 * @brief Reads the current model and precache its materials.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
bool DecryptPrecacheMaterials(const char[] sModel)
{
	int iFormat = FindCharInString(sModel, '.', true);
	
	if (iFormat == -1)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Missing file format: %s", sModel);
		return false;
	}
	
	static char sPath[PLATFORM_LINE_LENGTH];
	ExtractString(sPath, sModel, 0, iFormat);

	StrCat(sPath, sizeof(sPath), "_materials.txt");

	bool bExists = FileExists(sPath);
	
	File hBase = OpenFile(sPath, "at+");

	if (!bExists)
	{
		File hFile = OpenFile(sModel, "rb");

		if (hFile == null)
		{
			DeleteFile(sPath);
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Error opening file: \"%s\"", sModel);
			return false;
		}
		
		static char sMaterial[PLATFORM_LINE_LENGTH]; int iNumMat; int iChar;

		hFile.Seek(204, SEEK_SET);
		hFile.ReadInt32(iNumMat);
		hFile.Seek(0, SEEK_END);
		
		do /// Reads a single binary char
		{
			hFile.Seek(-2, SEEK_CUR);
			hFile.ReadInt8(iChar);
		} 
		while (iChar == 0);

		hFile.Seek(-1, SEEK_CUR);

		do /// Reads a single binary char
		{
			hFile.Seek(-2, SEEK_CUR);
			hFile.ReadInt8(iChar);
		} 
		while (iChar);

		int iPosIndex = hFile.Position;
		hFile.ReadString(sMaterial, sizeof(sMaterial));
		hFile.Seek(iPosIndex, SEEK_SET);
		hFile.Seek(-1, SEEK_CUR);
		
		ArrayList hList = new ArrayList(SMALL_LINE_LENGTH);

		while (hFile.Position > 1 && hList.Length < iNumMat)
		{
			do /// Reads a single binary char
			{
				hFile.Seek(-2, SEEK_CUR);
				hFile.ReadInt8(iChar);
			} 
			while (iChar);

			iPosIndex = hFile.Position;
			hFile.ReadString(sPath, sizeof(sPath));
			hFile.Seek(iPosIndex, SEEK_SET);
			hFile.Seek(-1, SEEK_CUR);

			if (!hasLength(sPath))
			{
				continue;
			}

			iFormat = FindCharInString(sPath, '\\', true);

			if (iFormat != -1)
			{
				Format(sPath, sizeof(sPath), "materials\\%s", sPath);
		
				DirectoryListing hDirectory = OpenDirectory(sPath);
				
				if (hDirectory == null)
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Error opening folder: \"%s\"", sPath);
					continue;
				}

				static char sFile[PLATFORM_LINE_LENGTH]; FileType hType;
				
				while (hDirectory.GetNext(sFile, sizeof(sFile), hType)) 
				{
					if (hType == FileType_File) 
					{
						iFormat = FindCharInString(sFile, '.', true);
				
						if (iFormat != -1) 
						{
							if (!strcmp(sFile[iFormat], ".vmt", false))
							{
								if (hList.FindString(sFile) == -1)
								{
									hList.PushString(sFile);
								}
								
								Format(sFile, sizeof(sFile), "%s%s", sPath, sFile);
								
								hBase.WriteLine(sFile);

								DecryptPrecacheTextures(sModel, sFile);
							}
						}
					}
				}

				delete hDirectory;
			}
			else
			{
				StrCat(sPath, sizeof(sPath), ".vmt");
		
				if (hList.FindString(sPath) == -1)
				{
					hList.PushString(sPath);
				}
				
				Format(sPath, sizeof(sPath), "materials\\%s%s", sMaterial, sPath);
				
				hBase.WriteLine(sPath);
				
				DecryptPrecacheTextures(sModel, sPath);
			}
		}

		delete hFile;
		delete hList;
	}
	else
	{
		while (hBase.ReadLine(sPath, sizeof(sPath)))
		{
			SplitString(sPath, "//", sPath, sizeof(sPath));
			
			TrimString(sPath);

			if (!hasLength(sPath))
			{
				continue;
			}
			
			DecryptPrecacheTextures(sModel, sPath);
		}
	}
	
	delete hBase;
	return true;
}

/**
 * @brief Reads the current model and precache its effects.
 *
 * @param sModel            The model path.
 * @return                  True if was precached, false otherwise.
 **/
bool DecryptPrecacheEffects(const char[] sModel)
{
	int iFormat = FindCharInString(sModel, '.', true);
	
	if (iFormat == -1)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Missing file format: %s", sModel);
		return false;
	}

	/*static char sParticleFuncTypes[48][SMALL_LINE_LENGTH] =
	{
		"DmeParticleSystemDefinition", "DmElement", "DmeParticleChild", "DmeParticleOperator", "particleSystemDefinitions",
		"preventNameBasedLookup", "particleSystemDefinitionDict", "snapshot", "untitled", "child", "drag", "delay", "name",
		"renderers", "operators", "initializers", "emitters", "children", "force", "constraints", "body", "duration", "DEBRIES",
		"color", "render", "radius", "lifetime", "type", "emit", "distance", "rotation", "speed", "fadeout", "DEBRIS", "size",
		"material", "function", "tint", "max", "min", "gravity", "scale", "rate", "time", "fade", "length", "definition", "thickness"
	};*/
	
	AddFileToDownloadsTable(sModel);

	static char sPath[PLATFORM_LINE_LENGTH];
	ExtractString(sPath, sModel, 0, iFormat);

	StrCat(sPath, sizeof(sPath), "_particles.txt");
	
	bool bExists = FileExists(sPath);
	
	File hBase = OpenFile(sPath, "at+");

	if (!bExists)
	{
		File hFile = OpenFile(sModel, "rb");

		if (hFile == null)
		{
			DeleteFile(sPath);
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Error opening file: \"%s\"", sModel);
			return false;
		}

		int iChar; ///int iNumMat;

		do /// Reads a single binary char
		{
			hFile.Seek(2, SEEK_CUR);
			hFile.ReadInt8(iChar);
		} 
		while (iChar == 0);

		hFile.Seek(1, SEEK_CUR);

		do /// Reads a single binary char
		{
			hFile.Seek(2, SEEK_CUR);
			hFile.ReadInt8(iChar);
		} 
		while (iChar);

		while (!hFile.EndOfFile())
		{
			hFile.ReadString(sPath, sizeof(sPath));

			iFormat = FindCharInString(sPath, '.', true);

			if (iFormat != -1)
			{
				if (!strcmp(sPath[iFormat], ".vmt", false))
				{
					Format(sPath, sizeof(sPath), "materials\\%s", sPath);
					
					hBase.WriteLine(sPath);
					
					DecryptPrecacheTextures(sModel, sPath);
				}
			}
		}

		delete hFile;
	}
	else
	{
		while (hBase.ReadLine(sPath, sizeof(sPath)))
		{
			SplitString(sPath, "//", sPath, sizeof(sPath));
		
			TrimString(sPath);

			if (!hasLength(sPath))
			{
				continue;
			}

			DecryptPrecacheTextures(sModel, sPath);
		}
	}
	
	delete hBase;
	return true;
}

/**
 * @brief Reads the current material and precache its textures.
 *
 * @param sModel            The model name.
 * @param sPath             The texture path.
 * @param bDecal            (Optional) If true, the texture will be precached like a decal.
 * @return                  True if was precached, false otherwise.
 **/
bool DecryptPrecacheTextures(const char[] sModel, const char[] sPath)
{
	int iSlash = max(FindCharInString(sModel, '/', true), FindCharInString(sModel, '\\', true));
	if (iSlash == -1) iSlash = 0; else iSlash++; /// For the root directory to get correct name
	
	static char sTexture[PLATFORM_LINE_LENGTH];
	strcopy(sTexture, sizeof(sTexture), sPath);

	if (!FileExists(sTexture))
	{
		if (FileExists(sTexture, true))
		{
			return true;
		}

		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Invalid material path. File not found: \"%s\" for \"%s\"", sTexture, sModel[iSlash]);
		return false;
	}

	AddFileToDownloadsTable(sTexture);
	
	static char sTypes[4][SMALL_LINE_LENGTH] = { "$baseTexture", "$bumpmap", "$lightwarptexture", "$REFRACTTINTtexture" }; bool bFound[sizeof(sTypes)]; int iShift;
	
	File hFile = OpenFile(sTexture, "rt");
	
	if (hFile == null)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Error opening file: \"%s\"", sTexture);
		return false;
	}
	
	while (hFile.ReadLine(sTexture, sizeof(sTexture)))
	{
		SplitString(sTexture, "//", sTexture, sizeof(sTexture));

		int iSize = sizeof(sTypes);
		for (int x = 0; x < iSize; x++)
		{
			if (bFound[x]) 
			{
				continue;
			}
			
			if ((iShift = StrContains(sTexture, sTypes[x], false)) != -1)
			{
				iShift += strlen(sTypes[x]) + 1;

				int iQuotes = CountCharInString(sTexture[iShift], '"');
				if (iQuotes != 2)
				{
					LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Error with parsing \"%s\" in file: \"%s\"", sTypes[x], sPath);
				}
				else
				{
					bFound[x] = true;

					strcopy(sTexture, sizeof(sTexture), sTexture[iShift]);
					
					TrimString(sTexture);
					
					StripQuotes(sTexture);

					if (!hasLength(sTexture))
					{
						continue;
					}
					
					Format(sTexture, sizeof(sTexture), "materials\\%s.vtf", sTexture);

					if (FileExists(sTexture))
					{
						AddFileToDownloadsTable(sTexture);
					}
					else
					{
						if (!FileExists(sTexture, true))
						{
							LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Decrypt, "Config Validation", "Invalid texture path. File not found: \"%s\"", sTexture);
						}
				   }
				}
			}
		}
	}

	delete hFile; 
	return true;
}
