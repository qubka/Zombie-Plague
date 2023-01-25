/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          particles.sp
 *  Type:          Module
 *  Description:   Particles dictionary & manager.
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
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallDestructorParticleDictionary;
Handle hSDKCallContainerFindTable;
Handle hSDKCallTableDeleteAllStrings;

/**
 * Variables to store virtual SDK offsets.
 **/
Address pParticleSystemDictionary;
Address pNetworkStringTable;
int ParticleSystem_Count;

/**
 * @brief Particles module init function.
 *
 * @warning Windows are not require that module without DHook extention.
 **/
void ParticlesOnInit(/*void*/)
{
	// If windows, then stop
	if (gServerData.Platform == OS_Windows)
	{
		return;
	}
	
	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CParticleSystemDictionary::~CParticleSystemDictionary");
	
	// Validate call
	if ((hSDKCallDestructorParticleDictionary = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CParticleSystemDictionary::~CParticleSystemDictionary\". Update signature in \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	/*_________________________________________________________________________________________________________________________________________*/

	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "CNetworkStringTableContainer::FindTable");
	
	// Adds a parameter to the calling convention. This should be called in normal ascending order
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); // 20CCStrike15ItemSchema
	
	// Validate call
	if ((hSDKCallContainerFindTable = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CNetworkStringTableContainer::FindTable\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	/*_________________________________________________________________________________________________________________________________________*/

	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CNetworkStringTable::DeleteAllStrings");
	
	// Validate call
	if ((hSDKCallTableDeleteAllStrings = EndPrepSDKCall()) == null)
	{
		// Log failure
		LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CNetworkStringTable::DeleteAllStrings\". Update signature in \"%s\"", PLUGIN_CONFIG);
		return;
	}
	
	/*_________________________________________________________________________________________________________________________________________*/
	
	// Load other offsets
	fnInitGameConfAddress(gServerData.Config, pParticleSystemDictionary, "m_pParticleSystemDictionary");
	fnInitGameConfAddress(gServerData.Config, pNetworkStringTable, "s_NetworkStringTable");
	fnInitGameConfOffset(gServerData.Config, ParticleSystem_Count, "CParticleSystemDictionary::Count");
}

/**
 * @brief Particles module load function.
 *
 * @warning Windows are not require that module without DHook extention.
 **/
void ParticlesOnLoad(/*void*/)
{
	// If windows, then stop
	if (gServerData.Platform == OS_Windows)
	{
		return;
	}

	// Now copy data to array structure
	ParticlesOnCacheData();
	
	// Precache particles
	ParticlesOnPrecache();
}

/**
 * @brief Particles module purge function.
 *
 * @warning Windows are not require that module without DHook extention.
 **/
void ParticlesOnPurge(/*void*/)
{
	// If windows, then stop
	if (gServerData.Platform == OS_Windows)
	{
		return;
	}
	
	// Clear particles in the dictionary
	ParticlesClear();

	// Clear particles in the effect table
	Address pTable = ParticlesFindTable("ParticleEffectNames");
	if (pTable != Address_Null)   
	{
		ParticlesClearTable(pTable);
	}

	// Clear particles in the extra effect table
	pTable = ParticlesFindTable("ExtraParticleFilesTable");
	if (pTable != Address_Null)   
	{
		ParticlesClearTable(pTable);
	}
}

/**
 * @brief Caches particles data from manifest file.
 **/
void ParticlesOnCacheData(/*void*/)
{
	// Validate that table is exist and it empty
	Address pTable = ParticlesFindTable("ParticleEffectNames");
	if (pTable != Address_Null && !ParticlesCount())
	{
		// Opens the file
		File hFile = OpenFile("particles/particles_manifest.txt", "rt", true);
		
		// If doesn't exist stop
		if (hFile == null)
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Effects, "Config Validation", "Error opening file: \"particles/particles_manifest.txt\"");
			return;
		}

		// Read lines in the file
		static char sPath[PLATFORM_LINE_LENGTH];
		while (hFile.ReadLine(sPath, sizeof(sPath)))
		{
			// Checks if string has correct quotes
			int iQuotes = CountCharInString(sPath, '"');
			if (iQuotes == 4)
			{
				// Trim string
				TrimString(sPath);

				// Copy value string
				strcopy(sPath, sizeof(sPath), sPath[strlen("\"file\"")]);
				
				// Trim string
				TrimString(sPath);
				
				// Strips a quote pair off a string 
				StripQuotes(sPath);

				// Precache model
				int i; if (sPath[i] == '!') i++;
				PrecacheGeneric(sPath[i], true);
				ParticlesClearTable(pTable); /// HACK~HACK
				/// Clear tables after each file because some of them contains
				/// huge amount of particles and we work around the limit
			}
		}
	}
}

/**
 * @brief Caches particles data from the manifest file.
 **/
void ParticlesOnPrecache(/*void*/)
{
	// Initialize buffer char
	static char sBuffer[PLATFORM_LINE_LENGTH];

	// If array hasn't been created, then create
	if (gServerData.Particles == null)
	{
		// Initialize a particle list array
		gServerData.Particles = new ArrayList(NORMAL_LINE_LENGTH); 

		// i = string index
		int iCount = GetParticleEffectCount();
		for (int i = 0; i < iCount; i++)
		{
			// Gets string at a given index
			GetParticleEffectName(i, sBuffer, sizeof(sBuffer));
			
			// Push data into array 
			gServerData.Particles.PushString(sBuffer);
		}
	}
	else
	{
		// i = string index
		int iCount = gServerData.Particles.Length;
		for (int i = 0; i < iCount; i++)
		{
			// Gets string at a given index
			gServerData.Particles.GetString(i, sBuffer, sizeof(sBuffer));
			
			// Push data into table 
			PrecacheParticleEffect(sBuffer);
		}
	}
}

/*
 * Stocks particles API.
 */ 

/**
 * @brief Create an attached particle entity.
 * 
 * @param parent            The parent index.
 * @param sAttach           The attachment name.
 * @param sEffect           The particle name.
 * @param flDurationTime    The duration of an effect.
 * @return                  The entity index.
 **/
int ParticlesCreate(int parent, char[] sAttach, char[] sEffect, float flDurationTime)
{
	// Validate name
	if (!hasLength(sEffect) || (hasLength(sAttach) && !ToolsLookupAttachment(parent, sAttach)))
	{
		return -1;
	}
	
	// Initialize vector variables
	static float vPosition[3]; static float vAngle[3]; 
	
	// Validate no attach
	if (!hasLength(sAttach))
	{ 
		// Gets client position/angle
		ToolsGetAbsOrigin(parent, vPosition);
		ToolsGetAbsAngles(parent, vAngle);
	}

	// Return on success
	return UTIL_CreateParticle(parent, vPosition, vAngle, sAttach, sEffect, flDurationTime);
}

/**
 * @brief Delete an attached particle from the entity.
 * 
 * @param client            The client index.
 **/
void ParticlesRemove(int client)
{
	// Initialize classname char
	static char sClassname[SMALL_LINE_LENGTH];

	// i = entity index
	int MaxEntities = GetMaxEntities();
	for (int i = MaxClients; i <= MaxEntities; i++)
	{
		// Validate entity
		if (IsValidEdict(i))
		{
			// Gets valid edict classname
			GetEdictClassname(i, sClassname, sizeof(sClassname));

			// If entity is an attach particle entity
			if (sClassname[0] == 'i' && sClassname[5] == 'p' && sClassname[6] == 'a') // info_particle_system
			{
				// Validate parent
				if (ToolsGetOwner(i) == client)
				{
					AcceptEntityInput(i, "Kill"); /// Destroy
				}
			}
		}
	}
}

/**
 * @brief Find the table pointer by a name.
 *
 * @return                  The address of the table.                
 **/
Address ParticlesFindTable(char[] sTable)
{
	return SDKCall(hSDKCallContainerFindTable, pNetworkStringTable, sTable);
}    

/**
 * @brief Clear the table by a pointer.  
 * 
 * @param pTable            The table address.
 **/
void ParticlesClearTable(Address pTable) 
{
	SDKCall(hSDKCallTableDeleteAllStrings, pTable);
}

/**
 * @brief Delete all precached particles in the dictionary.
 *
 * @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/particles/particles.sp#L81                 
 **/
void ParticlesClear(/*void*/)
{
	SDKCall(hSDKCallDestructorParticleDictionary, pParticleSystemDictionary);
}   

/**
 * @brief Gets the amount of precached particles in the dictionary.
 *
 * @return                  The amount of particles.
 *
 * @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/particles/particles.sp#L54                  
 **/
int ParticlesCount(/*void*/)
{
	return LoadFromAddress(pParticleSystemDictionary + view_as<Address>(ParticleSystem_Count), NumberType_Int16);
}
