/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          zombieclases.cpp
 *  Type:          Manager 
 *  Description:   Zombie classes generator.
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
 * Number of max valid zombie classes.
 **/
#define ZombieClassMax 64
 
/**
 * Array handle to store zombie class native data.
 **/
ArrayList arrayZombieClasses;

/**
 * Zombie native data indexes.
 **/
enum
{
    ZOMBIECLASSES_DATA_NAME,
	ZOMBIECLASSES_DATA_MODEL,
	ZOMBIECLASSES_DATA_CLAW,
	ZOMBIECLASSES_DATA_HEALTH,
	ZOMBIECLASSES_DATA_SPEED,
	ZOMBIECLASSES_DATA_GRAVITY,
	ZOMBIECLASSES_DATA_KNOCKBACK,
	ZOMBIECLASSES_DATA_LEVEL,
	ZOMBIECLASSES_DATA_FEMALE,
	ZOMBIECLASSES_DATA_VIP,
	ZOMBIECLASSES_DATA_DURATION,
	ZOMBIECLASSES_DATA_COUNTDOWN,
	ZOMBIECLASSES_DATA_REGENHEALTH,
	ZOMBIECLASSES_DATA_REGENINTERVAL,
	ZOMBIECLASSES_DATA_CLAW_ID
}

/**
 * Initialization of zombie classes. 
 **/
void ZombieClassesLoad(/*void*/)
{
	// No zombie classes?
	int iSize = GetArraySize(arrayZombieClasses);
	if(!iSize)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Zombie Class Validation", "No zombie classes loaded");
		return;
	}
	
	// Initialize model char
	static char sModel[BIG_LINE_LENGTH];
	
	// Precache of the zombie classes
	for(int i = 0; i < iSize; i++)
	{
		// Validate player model
		ZombieGetModel(i, sModel, sizeof(sModel));
		if(!ModelsPlayerPrecache(sModel))
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Model Validation", "Invalid model path. File not found: \"%s\".", sModel);
		}
		
		// Validate claw model
		ZombieGetClawModel(i, sModel, sizeof(sModel));
		ZombieSetClawIndex(i, ModelsViewPrecache(sModel));
	}
}

/*
 * Zombie classes natives API.
 */

/**
 * Gets the amount of all zombie classes.
 *
 * native int ZP_GetNumberZombieClass();
 **/
public int API_GetNumberZombieClass(Handle isPlugin, int iNumParams)
{
	// Return the value 
	return GetArraySize(arrayZombieClasses);
}

/**
 * Gets the zombie class index of the client.
 *
 * native int ZP_GetClientZombieClass(clientIndex);
 **/
public int API_GetClientZombieClass(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_nZombieClass;
}

/**
 * Gets the zombie next class index of the client.
 *
 * native int ZP_GetClientZombieClassNext(clientIndex);
 **/
public int API_GetClientZombieClassNext(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_nZombieNext;
}

/**
 * Sets the zombie class index to the client.
 *
 * native void ZP_SetClientZombieClass(clientIndex, iD);
 **/
public int API_SetClientZombieClass(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Get class index from native cell
	int iD = GetNativeCell(2);

	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Set next class to the client
	cBasePlayer->m_nZombieNext = iD;
	
	// Return on success
	return iD;
}

/**
 * Load zombie class from other plugin.
 *
 * native int ZP_RegisterZombieClass(name, model, claw_model, health, speed, gravity, female, vip, duration, countdown)
 **/
public int API_RegisterZombieClass(Handle isPlugin, int iNumParams)
{
	// If array hasn't been created, then create
	if(arrayZombieClasses == NULL)
	{
		// Create array in handle
		arrayZombieClasses = CreateArray(ZombieClassMax);
	}
	
	// Retrieves the string length from a native parameter string
	int iLenth;
	GetNativeStringLength(1, iLenth);
	
	// Strings are empty ?
	if(iLenth <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Can't register zombie class with an empty name");
		return -1;
	}
	
	// Maximum amout reached ?
	if(GetArraySize(arrayZombieClasses) >= ZombieClassMax)
	{
		LogEvent(false, LogType_Normal, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Zombie Class Validation", "Maximum number of zombie classes reached (%d). Skipping other classes.", ZombieClassMax);
		return -1;
	}
	
	// Get native data
	static char sZombieName[SMALL_LINE_LENGTH];
	static char sZombieModel[PLATFORM_MAX_PATH];
	static char sZombieClaw[PLATFORM_MAX_PATH];

	// General
	GetNativeString(1, sZombieName,  sizeof(sZombieName));
	GetNativeString(2, sZombieModel, sizeof(sZombieModel));
	GetNativeString(3, sZombieClaw,  sizeof(sZombieClaw));
	
	// Initialize array block
	ArrayList arrayZombieClass = CreateArray(ZombieClassMax);
	
	// Push native data into array
	PushArrayString(arrayZombieClass, sZombieName);  	// Index: 0
	PushArrayString(arrayZombieClass, sZombieModel);  	// Index: 1
	PushArrayString(arrayZombieClass, sZombieClaw);  	// Index: 2
	PushArrayCell(arrayZombieClass, GetNativeCell(4));	// Index: 3
	PushArrayCell(arrayZombieClass, GetNativeCell(5));	// Index: 4
	PushArrayCell(arrayZombieClass, GetNativeCell(6));	// Index: 5
	PushArrayCell(arrayZombieClass, GetNativeCell(7));	// Index: 6
	PushArrayCell(arrayZombieClass, GetNativeCell(8));	// Index: 7
	PushArrayCell(arrayZombieClass, GetNativeCell(9));	// Index: 8
	PushArrayCell(arrayZombieClass, GetNativeCell(10));	// Index: 9
	PushArrayCell(arrayZombieClass, GetNativeCell(11));	// Index: 10
	PushArrayCell(arrayZombieClass, GetNativeCell(12));	// Index: 11
	PushArrayCell(arrayZombieClass, GetNativeCell(13));	// Index: 12
	PushArrayCell(arrayZombieClass, GetNativeCell(14));	// Index: 13
	PushArrayCell(arrayZombieClass, 0);					// Index: 14
	
	// Store this handle in the main array
	PushArrayCell(arrayZombieClasses, arrayZombieClass);

	// Return id under which we registered the class
	return GetArraySize(arrayZombieClasses)-1;
}

/**
 * Gets the name of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassName(iD, sName, maxLen);
 **/
public int API_GetZombieClassName(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int iMaxLen = GetNativeCell(3);

	// Validate size
	if(iMaxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize name char
	static char sName[NORMAL_LINE_LENGTH];
	ZombieGetName(iD, sName, sizeof(sName));

	// Return on success
	return SetNativeString(2, sName, iMaxLen);
}

/**
 * Gets the player model of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassModel(iD, sModel, maxLen);
 **/
public int API_GetZombieClassModel(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize model char
	static char sModel[PLATFORM_MAX_PATH];
	ZombieGetModel(iD, sModel, sizeof(sModel));

	// Return on success
	return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the knife model of a zombie class at a given index.
 *
 * native void ZP_GetZombieClassClaw(iD, sModel, maxLen);
 **/
public int API_GetZombieClassClaw(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);

	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Get string size from native cell
	int maxLen = GetNativeCell(3);

	// Validate size
	if(maxLen <= 0)
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "No buffer size");
		return -1;
	}
	
	// Initialize model char
	static char sModel[PLATFORM_MAX_PATH];
	ZombieGetClawModel(iD, sModel, sizeof(sModel));

	// Return on success
	return SetNativeString(2, sModel, maxLen);
}

/**
 * Gets the health of the zombie class.
 *
 * native int ZP_GetZombieClassHealth(iD);
 **/
public int API_GetZombieClassHealth(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieGetHealth(iD);
}

/**
 * Gets the speed of the zombie class.
 *
 * native float ZP_GetZombieClassSpeed(iD);
 **/
public int API_GetZombieClassSpeed(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return the value (Float fix)
	return view_as<int>(ZombieGetSpeed(iD));
}

/**
 * Gets the gravity of the zombie class.
 *
 * native float ZP_GetZombieClassGravity(iD);
 **/
public int API_GetZombieClassGravity(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return the value (Float fix)
	return view_as<int>(ZombieGetGravity(iD));
}

/**
 * Gets the knockback of the zombie class.
 *
 * native float ZP_GetZombieClassKnockBack(iD);
 **/
public int API_GetZombieClassKnockBack(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return the value (Float fix)
	return view_as<int>(ZombieGetKnockBack(iD));
}

/**
 * Gets the level of the zombie class.
 *
 * native int ZP_GetZombieClassLevel(iD);
 **/
public int API_GetZombieClassLevel(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieGetLevel(iD);
}

/**
 * Check the gender of the zombie class.
 *
 * native bool ZP_IsZombieClassFemale(iD);
 **/
public int API_IsZombieClassFemale(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieIsFemale(iD);
}

/**
 * Check the access of the zombie class.
 *
 * native bool ZP_IsZombieClassVIP(iD);
 **/
public int API_IsZombieClassVIP(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieIsVIP(iD);
}

/**
 * Gets the skill duration of the zombie class.
 *
 * native int ZP_GetZombieClassSkillDuration(iD);
 **/
public int API_GetZombieClassSkillDuration(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieGetSkillDuration(iD);
}

/**
 * Gets the skill countdown of the zombie class.
 *
 * native int ZP_GetZombieClassSkillCountdown(iD);
 **/
public int API_GetZombieClassSkillCountdown(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieGetSkillCountDown(iD);
}

/**
 * Gets the regen of the zombie class.
 *
 * native int ZP_GetZombieClassRegen(iD);
 **/
public int API_GetZombieClassRegen(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieGetRegenHealth(iD);
}

/**
 * Gets the regen interval of the zombie class.
 *
 * native float ZP_GetZombieClassRegenInterval(iD);
 **/
public int API_GetZombieClassRegenInterval(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return the value (Float fix)
	return view_as<int>(ZombieGetRegenInterval(iD));
}

/**
 * Gets the index of the zombie class claw model.
 *
 * native int ZP_GetZombieClassClawID(iD);
 **/
public int API_GetZombieClassClawID(Handle isPlugin, int iNumParams)
{
	// Get class index from native cell
	int iD = GetNativeCell(1);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}
	
	// Return value
	return ZombieGetClawIndex(iD);
}

/**
 * Print the info about the zombie class.
 *
 * native void ZP_PrintZombieClassInfo(clientIndex, iD);
 **/
public int API_PrintZombieClassInfo(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));
	
	// Validate client
	if(!IsPlayerExist(cBasePlayer->Index, false))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Player doens't exist (%d)", cBasePlayer->Index);
		return -1;
	}
	
	// Get class index from native cell
	int iD = GetNativeCell(2);
	
	// Validate index
	if(iD >= GetArraySize(arrayZombieClasses))
	{
		LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Zombieclasses, "Native Validation", "Invalid the class index (%d)", iD);
		return -1;
	}

	// Get zombie name
	static char sZombieName[BIG_LINE_LENGTH];
	ZombieGetName(iD, sZombieName, sizeof(sZombieName));
	
	// Remove translation symbol, ifit exist
	ReplaceString(sZombieName, sizeof(sZombieName), "@", "");

	// Show class info
	TranslationPrintToChat(cBasePlayer->Index, "Zombie info", sZombieName, ZombieGetHealth(iD), ZombieGetSpeed(iD), ZombieGetGravity(iD));
	
	// Return on success
	return sizeof(sZombieName);
}

/*
 * Zombie classes data reading API.
 */

/**
 * Gets the name of a zombie class at a given index.
 *
 * @param iD     	 		The class index.
 * @param sName     		The string to return name in.
 * @param iMaxLen    		The max length of the string.
 **/
stock void ZombieGetName(int iD, char[] sName, int iMaxLen)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class name
	GetArrayString(arrayZombieClass, ZOMBIECLASSES_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the player model of a zombie class at a given index.
 *
 * @param iD     	 		The class index.
 * @param sModel      		The string to return model in.
 * @param iMaxLen    		The max length of the string.
 **/
stock void ZombieGetModel(int iD, char[] sModel, int iMaxLen)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class model
	GetArrayString(arrayZombieClass, ZOMBIECLASSES_DATA_MODEL, sModel, iMaxLen);
}

/**
 * Gets the knife model of a zombie class at a given index.
 *
 * @param iD     	 		The class index.
 * @param sModel      		The string to return model in.
 * @param iMaxLen    		The max length of the string.
 **/
stock void ZombieGetClawModel(int iD, char[] sModel, int iMaxLen)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class claw's model
	GetArrayString(arrayZombieClass, ZOMBIECLASSES_DATA_CLAW, sModel, iMaxLen);
}

/**
 * Gets the health of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The health amount.	
 **/
stock int ZombieGetHealth(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class health
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_HEALTH);
}

/**
 * Gets the speed of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The speed amount.	
 **/
stock float ZombieGetSpeed(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class speed 
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_SPEED);
}

/**
 * Gets the gravity of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The gravity amount.	
 **/
stock float ZombieGetGravity(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class speed 
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_GRAVITY);
}

/**
 * Gets the knockback of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The knockback amount.	
 **/
stock float ZombieGetKnockBack(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class knockback 
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_KNOCKBACK);
}

/**
 * Gets the level of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The duration amount.	
 **/
stock int ZombieGetLevel(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class level 
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_LEVEL);
}

/**
 * Check the gender of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		True or false.
 **/
stock bool ZombieIsFemale(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class gender 
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_FEMALE);
}

/**
 * Check the access to the zombie class.
 *
 * @param iD        		The class index.
 * @return          		True or false.
 **/
stock bool ZombieIsVIP(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class access 
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_VIP);
}

/**
 * Gets the skill duration of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The duration amount.	
 **/
stock int ZombieGetSkillDuration(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class skill's duration 
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_DURATION);
}

/**
 * Gets the skill countdown of the zombie class.
 *
 * @param iD       	 		The class index.
 * @return         	 		The countdown amount.	
 **/
stock int ZombieGetSkillCountDown(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class skill's countdown  
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_COUNTDOWN);
}

/**
 * Gets the regen amount of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The health amount.	
 **/
stock int ZombieGetRegenHealth(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class regen's health
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_REGENHEALTH);
}

/**
 * Gets the regen interval of the zombie class.
 *
 * @param iD        		The class index.
 * @return          		The interval amount.	
 **/
stock float ZombieGetRegenInterval(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class regen's interval
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_REGENINTERVAL);
}

/**
 * Gets the index of the zombie class claw model.
 *
 * @param iD        		The class index.
 * @return          		The model index.	
 **/
stock int ZombieGetClawIndex(int iD)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Get zombie class claw's model index
	return GetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_CLAW_ID);
}

/**
 * Sets the index of the zombie class claw model.
 *
 * @param iD         		The class index.
 * @param modelIndex  		The model index.	
 **/
stock void ZombieSetClawIndex(int iD, int modelIndex)
{
	// Get array handle of zombie class at given index
	Handle arrayZombieClass = GetArrayCell(arrayZombieClasses, iD);

	// Set knife model index
	SetArrayCell(arrayZombieClass, ZOMBIECLASSES_DATA_CLAW_ID, modelIndex);
}

/*
 * Zombie classes validation API.
 */

/**
 * Validate zombie class for client's availability.
 *
 * @param cBasePlayer        The client index.
 **/
void ZombieOnValidate(CBasePlayer* cBasePlayer)
{
	// Get array size
	int iSize = GetArraySize(arrayZombieClasses);
	
	// Choose random zombie class for bot
	if(IsFakeClient(cBasePlayer->Index))
	{
		cBasePlayer->m_nZombieClass = GetRandomInt(0, iSize-1);
	}
	
	// Validate that user does not have VIP flag to play it
	if(!IsPlayerHasFlag(cBasePlayer->Index, Admin_Custom1))
	{
		// But have privileged zombie class by default
		if(ZombieIsVIP(cBasePlayer->m_nZombieClass))
		{
			// Choose any accessable zombie class
			for(int i = 0; i < iSize; i++)
			{
				// Skip all non-accessable zombie classes
				if(ZombieIsVIP(i))
				{
					continue;
				}
				
				// Update zombie class
				cBasePlayer->m_nZombieNext = i;
				cBasePlayer->m_nZombieClass = i;
			}
		}
	}
	
	// Validate that user does not have level to play it
	if(ZombieGetLevel(cBasePlayer->m_nZombieClass) > cBasePlayer->m_iLevel)
	{
		// Choose any accessable zombie class
		for(int i = 0; i < iSize; i++)
		{
			// Skip all non-accessable zombie classes
			if(ZombieGetLevel(i) > cBasePlayer->m_iLevel)
			{
				continue;
			}
			
			// Update zombie class
			cBasePlayer->m_nZombieNext = i;
			cBasePlayer->m_nZombieClass = i;
		}
	}
}