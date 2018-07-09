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
#define HumanClassMax 32

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
    HUMANCLASSES_DATA_VIP,
    HUMANCLASSES_DATA_SOUNDDEATH,
    HUMANCLASSES_DATA_SOUNDHURT,
    HUMANCLASSES_DATA_SOUNDINFECT
}

/**
 * Initialization of human classes. 
 **/
void HumanClassesLoad(/*void*/)
{
    // No human classes?
    if(arrayHumanClasses == INVALID_HANDLE)
    {
        LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Humanclasses, "Human Class Validation", "No human classes loaded");
    }

    // Initialize model char
    static char sModel[PLATFORM_MAX_PATH];

    // Precache of the human classes
    int iSize = GetArraySize(arrayHumanClasses);
    for(int i = 0; i < iSize; i++)
    {
        // Validate player model
        HumanGetModel(i, sModel, sizeof(sModel));
        if(!ModelsPlayerPrecache(sModel))
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Humanclasses, "Model Validation", "Invalid model path. File not found: \"%s\"", sModel);
        }

        // Validate arm model
        HumanGetArmModel(i, sModel, sizeof(sModel));
        if(!ModelsPlayerPrecache(sModel))
        {
            LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Humanclasses, "Model Validation", "Invalid model path. File not found: \"%s\"", sModel);
        }
    }
}

/**
 * Creates commands for human classes module. Called when commands are created.
 **/
void HumanOnCommandsCreate(/*void*/)
{
    // Hook commands
    RegConsoleCmd("zhumanclassmenu",  HumanCommandCatched,  "Open the human classes menu.");
}

/**
 * Handles the <!zhumanclassmenu> command. Open the human classes menu.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action HumanCommandCatched(int clientIndex, int iArguments)
{
    // Open the human classes menu
    HumanMenu(clientIndex);
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
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_HumanClass];
}

/**
 * Gets the human next class index of the client.
 *
 * native int ZP_GetClientHumanClassNext(clientIndex);
 **/
public int API_GetClientHumanClassNext(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_HumanClassNext];
}

/**
 * Sets the human class index to the client.
 *
 * native void ZP_SetClientHumanClass(clientIndex, iD);
 **/
public int API_SetClientHumanClass(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Gets class index from native cell
    int iD = GetNativeCell(2);

    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Sets next class to the client
    gClientData[clientIndex][Client_HumanClassNext] = iD;
    
    // Return on success
    return iD;
}

/**
 * Registers a custom class which will be added to the human classes menu of ZP.
 *
 * native int ZP_RegisterHumanClass(name, model, arm_model, health, speed, gravity, armor, level, vip, death, hurt, infect);
 **/
public int API_RegisterHumanClass(Handle isPlugin, int iNumParams)
{
    // If array hasn't been created, then create
    if(arrayHumanClasses == INVALID_HANDLE)
    {
        // Create array in handle
        arrayHumanClasses = CreateArray(HumanClassMax);
    }

    // Retrieves the string length from a native parameter string
    int maxLen;
    GetNativeStringLength(1, maxLen);
    
    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Can't register human class with an empty name");
        return -1;
    }
    
    // Gets human classes amount
    int iCount = GetArraySize(arrayHumanClasses);
    
    // Maximum amout reached ?
    if(iCount >= HumanClassMax)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Maximum number of human classes reached (%d). Skipping other classes.", HumanClassMax);
        return -1;
    }

    // Gets native data
    char sHumanName[SMALL_LINE_LENGTH];
    char sHumanModel[PLATFORM_MAX_PATH];
    char sHumanArm[PLATFORM_MAX_PATH];
    char sHumanDeath[SMALL_LINE_LENGTH];
    char sHumanHurt[SMALL_LINE_LENGTH];
    char sHumanInfect[SMALL_LINE_LENGTH];
    
    // General                                                 
    GetNativeString(1,  sHumanName,   sizeof(sHumanName));   
    GetNativeString(2,  sHumanModel,  sizeof(sHumanModel));  
    GetNativeString(3,  sHumanArm,    sizeof(sHumanArm));     
    GetNativeString(10, sHumanDeath,  sizeof(sHumanDeath));  
    GetNativeString(11, sHumanHurt,   sizeof(sHumanHurt));     
    GetNativeString(12, sHumanInfect, sizeof(sHumanInfect)); 
    
    // Initialize char
    char sName[SMALL_LINE_LENGTH];
    
    // i = Human class number
    for(int i = 0; i < iCount; i++)
    {
        // Gets human class name
        HumanGetName(i, sName, sizeof(sName));
    
        // If names match, then stop
        if(!strcmp(sHumanName, sName, false))
        {
            LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Human class already registered (%s)", sName);
            return -1;
        }
    }
    
    // Initialize array block
    ArrayList arrayHumanClass = CreateArray(HumanClassMax);
    
    // Push native data into array
    arrayHumanClass.PushString(sHumanName);   // Index: 0
    arrayHumanClass.PushString(sHumanModel);  // Index: 1
    arrayHumanClass.PushString(sHumanArm);    // Index: 2
    arrayHumanClass.Push(GetNativeCell(4));   // Index: 3
    arrayHumanClass.Push(GetNativeCell(5));   // Index: 4
    arrayHumanClass.Push(GetNativeCell(6));   // Index: 5
    arrayHumanClass.Push(GetNativeCell(7));   // Index: 6
    arrayHumanClass.Push(GetNativeCell(8));   // Index: 7
    arrayHumanClass.Push(GetNativeCell(9));   // Index: 8
    arrayHumanClass.PushString(sHumanDeath);  // Index: 9
    arrayHumanClass.PushString(sHumanHurt);   // Index: 10
    arrayHumanClass.PushString(sHumanInfect); // Index: 11
    
    // Store this handle in the main array
    arrayHumanClasses.Push(arrayHumanClass);

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
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize name char
    static char sName[SMALL_LINE_LENGTH];
    HumanGetName(iD, sName, sizeof(sName));

    // Return on success
    return SetNativeString(2, sName, maxLen);
}

/**
 * Gets the player model of a human class at a given index.
 *
 * native void ZP_GetHumanClassModel(iD, sModel, maxLen);
 **/
public int API_GetHumanClassModel(Handle isPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
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
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
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
    // Gets class index from native cell
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
    // Gets class index from native cell
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
    // Gets class index from native cell
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
    // Gets class index from native cell
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
    // Gets class index from native cell
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
 * Check the access of the human class.
 *
 * native bool ZP_IsHumanClassVIP(iD);
 **/
public int API_IsHumanClassVIP(Handle isPlugin, int iNumParams)
{
    // Gets class index from native cell
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
 * Gets the death sound of a human class at a given index.
 *
 * native void ZP_GetHumanClassSoundDeath(iD, sSound, maxLen);
 **/
public int API_GetHumanClassSoundDeath(Handle isPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize sound char
    static char sSound[SMALL_LINE_LENGTH];
    HumanGetSoundDeath(iD, sSound, sizeof(sSound));

    // Return on success
    return SetNativeString(2, sSound, maxLen);
}

/**
 * Gets the hurt sound of a human class at a given index.
 *
 * native void ZP_GetHumanClassSoundHurt(iD, sSound, maxLen);
 **/
public int API_GetHumanClassSoundHurt(Handle isPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize sound char
    static char sSound[SMALL_LINE_LENGTH];
    HumanGetSoundHurt(iD, sSound, sizeof(sSound));

    // Return on success
    return SetNativeString(2, sSound, maxLen);
}

/**
 * Gets the infect sound of a human class at a given index.
 *
 * native void ZP_GetHumanClassSoundInfect(iD, sSound, maxLen);
 **/
public int API_GetHumanClassSoundInfect(Handle isPlugin, int iNumParams)
{
    // Gets class index from native cell
    int iD = GetNativeCell(1);

    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }
    
    // Gets string size from native cell
    int maxLen = GetNativeCell(3);

    // Validate size
    if(!maxLen)
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "No buffer size");
        return -1;
    }
    
    // Initialize sound char
    static char sSound[SMALL_LINE_LENGTH];
    HumanGetSoundInfect(iD, sSound, sizeof(sSound));

    // Return on success
    return SetNativeString(2, sSound, maxLen);
}

/**
 * Print the info about the human class.
 *
 * native void ZP_PrintHumanClassInfo(clientIndex, iD);
 **/
public int API_PrintHumanClassInfo(Handle isPlugin, int iNumParams)
{
    // If help messages disable, then stop 
    if(!gCvarList[CVAR_MESSAGES_HELP].BoolValue)
    {
        return -1;
    }
    
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Player doens't exist (%d)", clientIndex);
        return -1;
    }
    
    // Gets class index from native cell
    int iD = GetNativeCell(2);
    
    // Validate index
    if(iD >= GetArraySize(arrayHumanClasses))
    {
        LogEvent(false, LogType_Native, LOG_CORE_EVENTS, LogModule_Humanclasses, "Native Validation", "Invalid the class index (%d)", iD);
        return -1;
    }

    // Gets human name
    static char sHumanName[SMALL_LINE_LENGTH];
    HumanGetName(iD, sHumanName, sizeof(sHumanName));

    // If help messages enabled, show info
    TranslationPrintToChat(clientIndex, "Human info", sHumanName, HumanGetHealth(iD), HumanGetSpeed(iD), HumanGetGravity(iD));
    
    // Return on success
    return sizeof(sHumanName);
}

/*
 * Human classes data reading API.
 */

/**
 * Gets the name of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sName             The string to return name in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetName(int iD, char[] sName, int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class name
    arrayHumanClass.GetString(HUMANCLASSES_DATA_NAME, sName, iMaxLen);
}

/**
 * Gets the player model of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetModel(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class model
    arrayHumanClass.GetString(HUMANCLASSES_DATA_MODEL, sModel, iMaxLen);
}

/**
 * Gets the knife model of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sModel            The string to return model in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetArmModel(int iD, char[] sModel, int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class arm's model
    arrayHumanClass.GetString(HUMANCLASSES_DATA_ARM, sModel, iMaxLen);
}

/**
 * Gets the health of the human class.
 *
 * @param iD                The class index.
 * @return                  The health amount.    
 **/
stock int HumanGetHealth(int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class health
    return arrayHumanClass.Get(HUMANCLASSES_DATA_HEALTH);
}

/**
 * Gets the speed of the human class.
 *
 * @param iD                The class index.
 * @return                  The speed amount.    
 **/
stock float HumanGetSpeed(int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class speed
    return arrayHumanClass.Get(HUMANCLASSES_DATA_SPEED);
}

/**
 * Gets the gravity of the human class.
 *
 * @param iD                The class index.
 * @return                  The gravity amount.    
 **/
stock float HumanGetGravity(int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class gravity
    return arrayHumanClass.Get(HUMANCLASSES_DATA_GRAVITY);
}

/**
 * Gets the armor of the human class.
 *
 * @param iD                The class index.
 * @return                  The armor amount.    
 **/
stock int HumanGetArmor(int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class armor
    return arrayHumanClass.Get(HUMANCLASSES_DATA_ARMOR);
}

/**
 * Gets the level of the human class.
 *
 * @param iD                The class index.
 * @return                  The armor amount.    
 **/
stock int HumanGetLevel(int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class level
    return arrayHumanClass.Get(HUMANCLASSES_DATA_LEVEL);
}

/**
 * Check the access to the human class.
 *
 * @param iD                The class index.
 * @return                  True or false.
 **/
stock bool HumanIsVIP(int iD)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class access
    return arrayHumanClass.Get(HUMANCLASSES_DATA_VIP);
}

/**
 * Gets the death sound of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetSoundDeath(int iD, char[] sSound, int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class death sound
    arrayHumanClass.GetString(HUMANCLASSES_DATA_SOUNDDEATH, sSound, iMaxLen);
}

/**
 * Gets the hurt sound of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetSoundHurt(int iD, char[] sSound, int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class hurt sound
    arrayHumanClass.GetString(HUMANCLASSES_DATA_SOUNDHURT, sSound, iMaxLen);
}

/**
 * Gets the infect sound of a human class at a given index.
 *
 * @param iD                The class index.
 * @param sSound            The string to return sound in.
 * @param iMaxLen           The max length of the string.
 **/
stock void HumanGetSoundInfect(int iD, char[] sSound, int iMaxLen)
{
    // Gets array handle of human class at given index
    ArrayList arrayHumanClass = arrayHumanClasses.Get(iD);

    // Gets human class infect sound
    arrayHumanClass.GetString(HUMANCLASSES_DATA_SOUNDINFECT, sSound, iMaxLen);
}

/*
 * Stocks human classes API.
 */

/**
 * Validate human class for client's availability.
 *
 * @param clientIndex       The client index.
 **/
void HumanOnValidate(int clientIndex)
{
    // Gets array size
    int iSize = GetArraySize(arrayHumanClasses);
    
    // Gets client's access
    bool IsVIP = IsPlayerHasFlag(clientIndex, Admin_Custom1);
    
    // Choose random zombie class for the client
    if(IsFakeClient(clientIndex) || (!IsVIP && gCvarList[CVAR_HUMAN_RANDOM_CLASS].BoolValue) || iSize <= gClientData[clientIndex][Client_HumanClass])
    {
        gClientData[clientIndex][Client_HumanClass] = GetRandomInt(0, iSize-1);
    }
    
    // Validate that user does not have VIP flag to play it
    if(!IsVIP)
    {
        // But have privileged human class by default
        if(HumanIsVIP(gClientData[clientIndex][Client_HumanClass]))
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
                gClientData[clientIndex][Client_HumanClassNext] = i;
                gClientData[clientIndex][Client_HumanClass] = i;
            }
        }
    }
    
    // Validate that user does not have level to play it
    if(HumanGetLevel(gClientData[clientIndex][Client_HumanClass]) > gClientData[clientIndex][Client_Level])
    {
        // Choose any accessable human class
        for(int i = 0; i < iSize; i++)
        {
            // Skip all non-accessable human classes
            if(HumanGetLevel(i) > gClientData[clientIndex][Client_Level])
            {
                continue;
            }
            
            // Update human class
            gClientData[clientIndex][Client_HumanClassNext] = i;
            gClientData[clientIndex][Client_HumanClass] = i;
        }
    }
}

/**
 * Create the human class menu.
 *
 * @param clientIndex       The client index.
 **/
void HumanMenu(int clientIndex) 
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return;
    }

    // Initialize chars
    static char sBuffer[NORMAL_LINE_LENGTH];
    static char sName[SMALL_LINE_LENGTH];
    static char sInfo[SMALL_LINE_LENGTH];
    static char sLevel[SMALL_LINE_LENGTH];

    // Create menu handle
    Menu hMenu = CreateMenu(HumanMenuSlots);

    // Sets the language to target
    SetGlobalTransTarget(clientIndex);
    
    // Sets title
    hMenu.SetTitle("%t", "Choose humanclass");
    
    // i = Human class number
    int iCount = GetArraySize(arrayHumanClasses);
    for(int i = 0; i < iCount; i++)
    {
        // Gets human class name
        HumanGetName(i, sName, sizeof(sName));
        if(!IsCharUpper(sName[0]) && !IsCharNumeric(sName[0])) sName[0] = CharToUpper(sName[0]);
        
        // Format some chars for showing in menu
        Format(sLevel, sizeof(sLevel), "[LVL:%d]", HumanGetLevel(i));
        Format(sBuffer, sizeof(sBuffer),"%t    %s", sName, HumanIsVIP(i) ? "[VIP]" : HumanGetLevel(i) > 1 ? sLevel : "");
        
        // Show option
        IntToString(i, sInfo, sizeof(sInfo));
        hMenu.AddItem(sInfo, sBuffer, MenuGetItemDraw(((!IsPlayerHasFlag(clientIndex, Admin_Custom1) && HumanIsVIP(i)) || gClientData[clientIndex][Client_Level] < HumanGetLevel(i) || gClientData[clientIndex][Client_HumanClassNext] == i) ? false : true));
    }

    // Sets exit and back button
    hMenu.ExitBackButton = true;

    // Sets options and display it
    hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT|MENUFLAG_BUTTON_EXITBACK;
    hMenu.Display(clientIndex, MENU_TIME_FOREVER); 
}

/**
 * Called when client selects option in the human class menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param clientIndex       The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int HumanMenuSlots(Menu hMenu, MenuAction mAction, int clientIndex, int mSlot)
{
    // Switch the menu action
    switch(mAction)
    {
        // Client hit 'Exit' button
        case MenuAction_End :
        {
            delete hMenu;
        }
        
        // Client hit 'Back' button
        case MenuAction_Cancel :
        {
            if(mSlot == MenuCancel_ExitBack)
            {
                // Open main menu back
                MenuMain(clientIndex);
            }
        }
        
        // Client selected an option
        case MenuAction_Select :
        {
            // Validate client
            if(!IsPlayerExist(clientIndex, false))
            {
                return;
            }

            // Initialize char
            static char sInfo[SMALL_LINE_LENGTH];

            // Gets ID of zombie class
            hMenu.GetItem(mSlot, sInfo, sizeof(sInfo));
            int iD = StringToInt(sInfo);
            
            // Sets next zombie class
            gClientData[clientIndex][Client_HumanClassNext] = iD;

            // Show class info
            TranslationPrintToChat(clientIndex, "Human info", sInfo, HumanGetHealth(iD), HumanGetSpeed(iD), HumanGetGravity(iD));
        }
    }
}