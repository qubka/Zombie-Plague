/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          humanclasses.cpp
 *  Type:          Manager 
 *  Description:   Human classes generator.
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
 * Number of max valid human classes.
 **/
#define HumanClassMax 64

/**
 * Array handle to store human class native data.
 **/
ArrayList arrayHumanClasses;

/**
 * Human native data indexes.
 **/
enum
{
    HUMANCLASSES_DATA_NAME,
	HUMANCLASSES_DATA_MODEL,
	HUMANCLASSES_DATA_ARM,
	HUMANCLASSES_DATA_HEALTH,
	HUMANCLASSES_DATA_SPEED,
	HUMANCLASSES_DATA_GRAVITY,
	HUMANCLASSES_DATA_ARMOR,
	HUMANCLASSES_DATA_LEVEL,
	HUMANCLASSES_DATA_FEMALE,
	HUMANCLASSES_DATA_VIP
}

/**
 * Initialization of human classes. 
 **/
void HumanClassesLoad(/*void*/)
{
	// No human classes?
	int iSize = GetArraySize(arrayHumanClasses);
	if(!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Humanclasses, "Human Class Validation", "No human classes loaded");
		return;
	}
	
	// Initialize model char
	static char sModel[BIG_LINE_LENGTH];
	
	// Precache of the human classes
	for(int i = 0; i < iSize; i++)
	{
		// Validate player model
		HumanGetModel(i, sModel, sizeof(sModel));
		if(!ModelsPlayerPrecache(sModel))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Humanclasses, "Model Validation", "Invalid model path. File not found: \"%s\".", sModel);
		}
		
		// Validate arm model
		HumanGetArmModel(i, sModel, sizeof(sModel));
		if(!ModelsPlayerPrecache(sModel))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Humanclasses, "Model Validation", "Invalid model path. File not found: \"%s\".", sModel);
		}
	}
}

/*
 * Human classes natives API.
 */

/**
 * Gets the amount of all human classes.
 *
 * native int ZP_GetNumberHumanClass();
 **/
public int API_GetNumberHumanClass(Handle isPlugin, int iNumParams)
{
	// Return the value 
	return GetArraySize(arrayHumanClasses);
}

/**
 * Gets the human class index of the client.
 *
 * native int ZP_GetClientHumanClass(clientIndex);
 **/
public int API_GetClientHumanClass(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_nHumanClass;
}

/**
 * Gets the human next class index of the client.
 *
 * native int ZP_GetClientHumanClassNext(clientIndex);
 **/
public int API_GetClientHumanClassNext(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_nHumanNext;
}

/**
 * Sets the human class index to the client.
 *
 * native void ZP_SetClientHumanClass(clientIndex, iD);
 **/
public int API_SetClientHumanClass(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Get class index from native cell
	int iD = GetNativeCell(2);

	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Set next class to the client
	cBasePlayer->m_nHumanNext = iD;
	
	// Return on success
	return iD;
}

/**
 * Registers a custom class which will be added to the human classes menu of ZP.
 *
 * native int ZP_RegisterHumanClass(name, model, arm_model, health, speed, gravity, armor, level, female, vip);
 **/
public int API_RegisterHumanClass(Handle isPlugin, int iNumParams)
{
	// If array hasn't been created, then create
	if(arrayHumanClasses == NULL)
	{
		// Create array in handle
		arrayHumanClasses = CreateArray(HumanClassMax);
	}
	
	// Retrieves the string length from a native parameter string
	int iLenth;
	GetNativeStringLength(1, iLenth);
	
	// Strings are empty ?
	if(iLenth <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Can't register human class with an empty name");
		return -1;
	}
	
	// Maximum amout reached ?
	if(GetArraySize(arrayHumanClasses) >= HumanClassMax)
	{
		LogEvent(false, LogType_Normal, LOG_CORE_EVENTS, LogModule_Humanclasses, "Human Class Validation", "Maximum number of human classes reached (%d). Skipping other classes.", HumanClassMax);
		return -1;
	}
	
	// Get native data
	static char sHumanName[SMALL_LINE_LENGTH];
	static char sHumanModel[PLATFORM_MAX_PATH];
	static char sHumanArm[PLATFORM_MAX_PATH];
	
	// General
	GetNativeString(1, sHumanName, sizeof(sHumanName));
	GetNativeString(2, sHumanModel, sizeof(sHumanModel));
	GetNativeString(3, sHumanArm, sizeof(sHumanArm));

	// Initialize array block
	ArrayList arrayHumanClass = CreateArray(HumanClassMax);
	
	// Push native data into array
	PushArrayString(arrayHumanClass, sHumanName);  		// Index: 0
	PushArrayString(arrayHumanClass, sHumanModel);  	// Index: 1
	PushArrayString(arrayHumanClass, sHumanArm);  		// Index: 2
	PushArrayCell(arrayHumanClass, GetNativeCell(4));	// Index: 3
	PushArrayCell(arrayHumanClass, GetNativeCell(5));	// Index: 4
	PushArrayCell(arrayHumanClass, GetNativeCell(6));	// Index: 5
	PushArrayCell(arrayHumanClass, GetNativeCell(7));	// Index: 6
	PushArrayCell(arrayHumanClass, GetNativeCell(8));	// Index: 7
	PushArrayCell(arrayHumanClass, GetNativeCell(9));	// Index: 8
	PushArrayCell(arrayHumanClass, GetNativeCell(10));	// Index: 9
	
	// Store this handle in the main array
	PushArrayCell(arrayHumanClasses, arrayHumanClass);

	// Return id under which we registered the class
	return GetArraySize(arrayHumanClasses)-1;
}

/**
 * Gets the name of a human class at a given index.
 *
 * native void ZP_GetHumanClassName(iD, sName, maxLen);
 **/
public int API_GetHumanClassName(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int iMaxLen = GetNativeCell(3);

	// Validate size
	if(iMaxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize name char
	static char sName[NORMAL_LINE_LENGTH];
	HumanGetName(iD, sName, sizeof(sName));

	// Return on success
	return SetNativeString(2, sName, iMaxLen);
}

/**
 * Gets the player model of a human class at a given index.
 *
 * native void ZP_GetHumanClassModel(iD, sModel, maxLen);
 **/
public int API_GetHumanClassModel(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize model char
	static char sModel[PLATFORM_MAX_PATH];
	HumanGetModel(iD, sModel, sizeof(sModel));

	// Return on success
	return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the arm model of a human class at a given index.
 *
 * native void ZP_GetHumanClassArm(iD, sModel, maxLen);
 **/
public int API_GetHumanClassArm(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize model char
	static char sModel[PLATFORM_MAX_PATH];
	HumanGetArmModel(iD, sModel, sizeof(sModel));

	// Return on success
	return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the health of the human class.
 *
 * native int ZP_GetHumanClassHealth(iD);
 **/
public int API_GetHumanClassHealth(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return HumanGetHealth(iD);
}

/**
 * Gets the speed of the human class.
 *
 * native float ZP_GetHumanClassSpeed(iD);
 **/
public int API_GetHumanClassSpeed(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return the value (Float fix)
	return view_as<int>(HumanGetSpeed(iD));
}

/**
 * Gets the gravity of the human class.
 *
 * native float ZP_GetHumanClassGravity(iD);
 **/
public int API_GetHumanClassGravity(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}

	// Return the value (Float fix)
	return view_as<int>(HumanGetGravity(iD));
}

/**
 * Gets the armor of the human class.
 *
 * native int ZP_GetHumanClassArmor(iD);
 **/
public int API_GetHumanClassArmor(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return HumanGetArmor(iD);
}

/**
 * Gets the level of the human class.
 *
 * native int ZP_GetHumanClassLevel(iD);
 **/
public int API_GetHumanClassLevel(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return HumanGetLevel(iD);
}

/**
 * Check the gender of the human class.
 *
 * native bool ZP_IsHumanClassFemale(iD);
 **/
public int API_IsHumanClassFemale(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return HumanIsFemale(iD);
}

/**
 * Check the access of the human class.
 *
 * native bool ZP_IsHumanClassVIP(iD);
 **/
public int API_IsHumanClassVIP(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return HumanIsVIP(iD);
}

/**
 * Print the info about the human class.
 *
 * native void ZP_PrintHumanClassInfo(clientIndex, iD);
 **/
public int API_PrintHumanClassInfo(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));
	
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Player doens't exist (%d)", cBasePlayer->Index);
		return -1;
	}
	
	// Get class index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if(iD >= GetArraySize(arrayHumanClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}

	// Get zombie name
	static char sHumanName[BIG_LINE_LENGTH];
	HumanGetName(iD, sHumanName, sizeof(sHumanName));
	
	// Remove translation symbol, ifit exist
	ReplaceString(sHumanName, sizeof(sHumanName), "@", "");

	// Show class info
	TranslationPrintToChat(cBasePlayer->Index, "Human info", sHumanName, HumanGetHealth(iD), HumanGetSpeed(iD), HumanGetGravity(iD));
	
	// Return on success
	return sizeof(sHumanName);
}

/*
 * Human classes data reading API.
 */

/**
 * Gets the name of a human class at a given index.
 *
 * @param iD     	 		The class index.
 * @param sName      		The string to return name in.
 * @param iMaxLen    		The max length of the string.
 **/
stock void HumanGetName(int iD, char[] sName, int iMaxLen)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class name
	GetArrayString(arrayHumanClass, HUMANCLASSES_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the player model of a human class at a given index.
 *
 * @param iD     	 		The class index.
 * @param sModel      		The string to return model in.
 * @param iMaxLen    		The max length of the string.
 **/
stock void HumanGetModel(int iD, char[] sModel, int iMaxLen)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class model
	GetArrayString(arrayHumanClass, HUMANCLASSES_DATA_MODEL, sModel, iMaxLen);
}

/**
 * Gets the knife model of a human class at a given index.
 *
 * @param iD     	 		The class index.
 * @param sModel      		The string to return model in.
 * @param iMaxLen    		The max length of the string.
 **/
stock void HumanGetArmModel(int iD, char[] sModel, int iMaxLen)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class arm's model
	GetArrayString(arrayHumanClass, HUMANCLASSES_DATA_ARM, sModel, iMaxLen);
}

/**
 * Gets the health of the human class.
 *
 * @param iD        		The class index.
 * @return          		The health amount.	
 **/
stock int HumanGetHealth(int iD)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class health
	return GetArrayCell(arrayHumanClass, HUMANCLASSES_DATA_HEALTH);
}

/**
 * Gets the speed of the human class.
 *
 * @param iD       	 		The class index.
 * @return          		The speed amount.	
 **/
stock float HumanGetSpeed(int iD)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class speed
	return GetArrayCell(arrayHumanClass, HUMANCLASSES_DATA_SPEED);
}

/**
 * Gets the gravity of the human class.
 *
 * @param iD        		The class index.
 * @return          		The gravity amount.	
 **/
stock float HumanGetGravity(int iD)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class gravity
	return GetArrayCell(arrayHumanClass, HUMANCLASSES_DATA_GRAVITY);
}

/**
 * Gets the armor of the human class.
 *
 * @param iD        		The class index.
 * @return         		 	The armor amount.	
 **/
stock int HumanGetArmor(int iD)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class armor
	return GetArrayCell(arrayHumanClass, HUMANCLASSES_DATA_ARMOR);
}

/**
 * Gets the level of the human class.
 *
 * @param iD        		The class index.
 * @return         		 	The armor amount.	
 **/
stock int HumanGetLevel(int iD)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class level
	return GetArrayCell(arrayHumanClass, HUMANCLASSES_DATA_LEVEL);
}

/**
 * Check the gender of the human class.
 *
 * @param iD        		The class index.
 * @return          		True or false.
 **/
stock bool HumanIsFemale(int iD)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class gender
	return GetArrayCell(arrayHumanClass, HUMANCLASSES_DATA_FEMALE);
}

/**
 * Check the access to the human class.
 *
 * @param iD        		The class index.
 * @return          		True or false.
 **/
stock bool HumanIsVIP(int iD)
{
	// Get array handle of human class at given index
	Handle arrayHumanClass = GetArrayCell(arrayHumanClasses, iD);

	// Get human class access
	return GetArrayCell(arrayHumanClass, HUMANCLASSES_DATA_VIP);
}

/*
 * Human classes validation API.
 */

/**
 * Validate human class for client's availability.
 *
 * @param cBasePlayer        The client index.
 **/
void HumanOnValidate(CBasePlayer* cBasePlayer)
{
	// Get array size
	int iSize = GetArraySize(arrayHumanClasses);
	
	// Choose random human class for bot
	if(IsFakeClient(cBasePlayer->Index))
	{
		cBasePlayer->m_nHumanClass = GetRandomInt(0, iSize-1);
	}
	
	// Validate that user does not have VIP flag to play it
	if(!IsPlayerHasFlag(cBasePlayer->Index, Admin_Custom1))
	{
		// But have privileged human class by default
		if(HumanIsVIP(cBasePlayer->m_nHumanClass))
		{
			// Choose any accessable human class
			for(int i = 0; i < iSize; i++)
			{
				// Skip all non-accessable human classes
				if(HumanIsVIP(i))
				{
					continue;
				}
				
				// Update human class
				cBasePlayer->m_nHumanNext = i;
				cBasePlayer->m_nHumanClass = i;
			}
		}
	}
	
	// Validate that user does not have level to play it
	if(HumanGetLevel(cBasePlayer->m_nHumanClass) > cBasePlayer->m_iLevel)
	{
		// Choose any accessable human class
		for(int i = 0; i < iSize; i++)
		{
			// Skip all non-accessable human classes
			if(HumanGetLevel(i) > cBasePlayer->m_iLevel)
			{
				continue;
			}
			
			// Update human class
			cBasePlayer->m_nHumanNext = i;
			cBasePlayer->m_nHumanClass = i;
		}
	}
}