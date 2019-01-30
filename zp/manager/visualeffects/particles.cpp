/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          particles.cpp
 *  Type:          Module
 *  Description:   Particles dictionary & manager.
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
 
/**
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallGetParticleSystemCount;
Handle hSDKCallUncacheAllParticleSystems;
Handle hSDKCallDestructorParticleDefinition;
Handle hSDKCallFindParticleSystemDefinition;
Handle hSDKCallDestructorParticleDictionary;
Handle hSDKCallContainerFindTable;
Handle hSDKCallTableDeleteAllStrings;

/**
 * Variables to store virtual SDK offsets.
 **/
Address particleSystemMgr;
Address particleSystemDictionary;
Address networkStringTable;

/**
 * @brief Particles module init function.
 **/
void ParticlesOnInit(/*void*/)
{
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CParticleSystemMgr::GetParticleSystemCount");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if(!(hSDKCallGetParticleSystemCount = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CParticleSystemMgr::GetParticleSystemCount\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }

    /*_________________________________________________________________________________________________________________________________________*/

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CParticleSystemMgr::UncacheAllParticleSystems");
    
    // Validate call
    if(!(hSDKCallUncacheAllParticleSystems = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CParticleSystemMgr::UncacheAllParticleSystems\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }

    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CParticleSystemDefinition::~CParticleSystemDefinition");

    // Validate call
    if(!(hSDKCallDestructorParticleDefinition = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CParticleSystemDefinition::Uncache\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CParticleSystemDictionary::FindParticleSystem");
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    
    // Validate call
    if(!(hSDKCallFindParticleSystemDefinition = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CParticleSystemDictionary::FindParticleSystem\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }

    /*_________________________________________________________________________________________________________________________________________*/

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CParticleSystemDictionary::~CParticleSystemDictionary");
    
    // Validate call
    if(!(hSDKCallDestructorParticleDictionary = EndPrepSDKCall()))
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
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    
    // Validate call
    if(!(hSDKCallContainerFindTable = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CNetworkStringTableContainer::FindTable\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Raw);
    PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CNetworkStringTable::DeleteAllStrings");
    
    // Validate call
    if(!(hSDKCallTableDeleteAllStrings = EndPrepSDKCall()))
    {
        // Log failure
        LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CNetworkStringTable::DeleteAllStrings\". Update signature in \"%s\"", PLUGIN_CONFIG);
        return;
    }
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    // Load other offsets
    fnInitGameConfAddress(gServerData.Config, particleSystemMgr, "g_pParticleSystemMgr");
    fnInitGameConfAddress(gServerData.Config, particleSystemDictionary, "m_pParticleSystemDictionary");
    fnInitGameConfAddress(gServerData.Config, networkStringTable, "s_NetworkStringTable");
}

/**
 * @brief Particles module load function.
 **/
void ParticlesOnLoad(/*void*/)
{
    // Initialize buffer char
    static char sBuffer[PLATFORM_LINE_LENGTH];

    // Validate that particles wasn't precache yet
    bool bSave = LockStringTables(false);
    int iCount = SDKCall(hSDKCallGetParticleSystemCount, particleSystemMgr);
    int iTable = SDKCall(hSDKCallContainerFindTable, networkStringTable, "ParticleEffectNames");
    if(!iCount && iTable) /// Validate that table is exist and it empty
    {
        // Opens the file
        File hFile = OpenFile("particles/particles_manifest.txt", "rt", true);
        
        // If doesn't exist stop
        if(hFile == null)
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Effects, "Config Validation", "Error opening file: \"particles/particles_manifest.txt\"");
            return;
        }

        // Read lines in the file
        while(hFile.ReadLine(sBuffer, sizeof(sBuffer)))
        {
            // Checks if string has correct quotes
            int iQuotes = CountCharInString(sBuffer, '"');
            if(iQuotes == 4)
            {
                // Trim string
                TrimString(sBuffer);

                // Copy value string
                strcopy(sBuffer, sizeof(sBuffer), sBuffer[strlen("\"file\"")]);
                
                // Trim string
                TrimString(sBuffer);
                
                // Strips a quote pair off a string 
                StripQuotes(sBuffer);

                // Precache model
                int i; if(sBuffer[i] == '!') i++;
                PrecacheGeneric(sBuffer[i], true);
                SDKCall(hSDKCallTableDeleteAllStrings, iTable); /// HACK~HACK
            }
        }
    }
    
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }
    
    // If array hasn't been created, then create
    if(gServerData.Particles == null)
    {
        // Initialize a particle list array
        gServerData.Particles = CreateArray(NORMAL_LINE_LENGTH); 

        // i = table string
        iCount = GetStringTableNumStrings(tableIndex);
        for(int i = 0; i < iCount; i++)
        {
            // Gets the string at a given index
            ReadStringTable(tableIndex, i, sBuffer, sizeof(sBuffer));
            
            // Push data into array 
            gServerData.Particles.PushString(sBuffer);
        }
    }
    else
    {
        // i = particle name
        iCount = gServerData.Particles.Length;
        for(int i = 0; i < iCount; i++)
        {
            // Gets the string at a given index
            gServerData.Particles.GetString(i, sBuffer, sizeof(sBuffer));
            
            // Push data into table 
            AddToStringTable(tableIndex, sBuffer);
        }
    }   
    LockStringTables(bSave);
}

/**
 * @brief Particles module purge function.
 **/
void ParticlesOnPurge(/*void*/)
{
    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/particles/particles.cpp#L2659
    SDKCall(hSDKCallUncacheAllParticleSystems, particleSystemMgr);

    // i = m_ParticleNameMap
    int iCount = SDKCall(hSDKCallGetParticleSystemCount, particleSystemMgr); 
    for(int i = 0; i < iCount; i++)
    {
        // @link https://github.com/ValveSoftware/source-sdk-2013/blob/0d8dceea4310fde5706b3ce1c70609d72a38efdf/sp/src/public/particles/particles.h#L2131
        Address particleSystemDefinition = SDKCall(hSDKCallFindParticleSystemDefinition, particleSystemDictionary, i);
        SDKCall(hSDKCallDestructorParticleDefinition, particleSystemDefinition);
    }
    
    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/particles/particles.cpp#L81
    SDKCall(hSDKCallDestructorParticleDictionary, particleSystemDictionary);
    
    /*_________________________________________________________________________________________________________________________________________*/
    
    /// Clear all particles effect table
    bool bSave = LockStringTables(false);
    int iTable = SDKCall(hSDKCallContainerFindTable, networkStringTable, "ParticleEffectNames");
    if(iTable)   SDKCall(hSDKCallTableDeleteAllStrings, iTable);
    LockStringTables(bSave);
}