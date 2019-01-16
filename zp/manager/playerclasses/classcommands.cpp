/**
 * ============================================================================
 *
 *   Plague
 *
 *  File:          classcommands.cpp
 *  Type:          Module 
 *  Description:   Console commands for working with classes.
 *
 *  Copyright (C) 2015-2019 Greyscale, Richard Helgeby
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
 * @brief Creates commands for classes module.
 **/
void ClassCommandsOnCommandInit(/*void*/)
{
    // Hook commands
    RegAdminCmd("zp_class_dump", ClassDumpOnCommandCatched, ADMFLAG_CONFIG, "Dumps class data at a specified index. Usage: zp_class_dump <index|name>");
}

/**
 * Console command callback (zp_class_dump)
 * @brief Dumps class data at a specified index.
 * 
 * @param clientIndex       The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action ClassDumpOnCommandCatched(const int clientIndex, const int iArguments)
{
    // If not enough arguments given, then stop
    if(iArguments < 1)
    {
        // Write syntax info
        TranslationReplyToCommand(clientIndex, "config dump class");
        return Plugin_Handled;
    }
    
    // Initialize variables
    static char sArgument[SMALL_LINE_LENGTH];
    static char sBuffer[FILE_LINE_LENGTH]; sBuffer[0] = '\0';
    static char sMessage[CONSOLE_LINE_LENGTH]; sMessage[0] = '\0';

    // Get class index
    GetCmdArg(1, sArgument, sizeof(sArgument));
    
    // Validate class
    int iD = StringToInt(sArgument);
    if(strlen(sArgument) > 1 && iD == 0)
    {
        // Find index by name
        iD = ClassNameToIndex(sArgument);
    }

    // Validate index
    int iSize = gServerData.Classes.Length;
    if(iD >= iSize || iD <= -1)
    {
        // Write error info
        TranslationReplyToCommand(clientIndex, "config dump class invalid", iD);
        return Plugin_Handled;
    }
    
    // Dump the specified cache
    TranslationReplyToCommand(clientIndex, "config dump class start", iSize);
    ClassDumpData(iD, sBuffer, sizeof(sBuffer));

    // Print all data to client
    int iPos; int iCellsWritten = 1; // Initialize for the loop
    while(iCellsWritten)
    {
        iCellsWritten = strcopy(sMessage, sizeof(sMessage), sBuffer[iPos]);
        ReplyToCommand(clientIndex, sMessage);
        iPos += iCellsWritten;
    }

    // Log action to game events
    LogEvent(true, LogType_Normal, LOG_PLAYER_COMMANDS, LogModule_Classes, "Command", "Admin \"%N\" dumped: \"%d\" class", clientIndex, iD);
    return Plugin_Handled;
}

/**
 * @brief Dump class data into a string. String buffer length should be at about 2048 cells.
 *
 * @param iD                The class index.
 * @param sBuffer           The string to return dump in.
 * @param iMaxLen           The lenght of string.
 * @return                  The number of cells written.
 */
int ClassDumpData(int iD, char[] sBuffer, const int iMaxLen)
{
    // Initialize variables
    int iCellCount; int iFormat[SMALL_LINE_LENGTH];
    static char sAttribute[HUGE_LINE_LENGTH];
    static char sFormat[PLATFORM_LINE_LENGTH];
    
    // Validate lenght
    if(!iMaxLen)
    {
        return 0;
    }
    
    /// Format strings
    FormatEx(sFormat, sizeof(sFormat), "Class data at index \"%d\":\n", iD);
    iCellCount += StrCat(sBuffer, iMaxLen, sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, "-------------------------------------------------------------------------------\n");
    
    ClassGetName(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "name:       \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);

    ClassGetInfo(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "info:       \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetType(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "type:       \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ConfigBoolToSetting(ClassIsZombie(iD), sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "zombie:     \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetModel(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "model:      \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetClawModel(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "claw_model: \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetGrenadeModel(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "gren_model: \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetArmModel(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "arm_model:  \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "body:       \"%d\"\n", ClassGetBody(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "skin:       \"%d\"\n", ClassGetSkin(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "health:     \"%d\"\n", ClassGetHealth(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "speed:      \"%.1f\"\n", ClassGetSpeed(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "gravity:    \"%.1f\"\n", ClassGetGravity(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "knockback:  \"%.1f\"\n", ClassGetKnockBack(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "armor:      \"%d\"\n", ClassGetArmor(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "level:      \"%d\"\n", ClassGetLevel(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetName(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "group:      \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "duration:   \"%.1f\"\n", ClassGetSkillDuration(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "countdown:  \"%.1f\"\n", ClassGetSkillCountdown(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ConfigBoolToSetting(ClassIsSkillBar(iD), sFormat, sizeof(sFormat), false);
    FormatEx(sAttribute, sizeof(sAttribute), "bar:        \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "regenerate: \"%d\"\n", ClassGetRegenHealth(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "interval:   \"%.1f\"\n", ClassGetRegenInterval(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ConfigBoolToSetting(ClassIsFall(iD), sFormat, sizeof(sFormat), false);
    FormatEx(sAttribute, sizeof(sAttribute), "fall:       \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "fov:        \"%d\"\n", ClassGetFov(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ConfigBoolToSetting(ClassIsCross(iD), sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "crosshair:  \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ConfigBoolToSetting(ClassIsNvgs(iD), sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "nvgs:       \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);

    ClassGetOverlay(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "overlay:    \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetWeapon(iD, iFormat, sizeof(iFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "weapon:     ");
    for(int i = 0; i < sizeof(iFormat); i++)
    {
        if(iFormat[i] != -1) Format(sAttribute, sizeof(sAttribute), "%s \"%d\"", sAttribute, iFormat[i]);
    } 
    StrCat(sAttribute, sizeof(sAttribute), "\n");
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetMoney(iD, iFormat, sizeof(iFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "money:      ");
    for(int i = 0; i < 6; i++)
    {
        if(iFormat[i] != -1) Format(sAttribute, sizeof(sAttribute), "%s \"%d\"", sAttribute, iFormat[i]);
    } 
    StrCat(sAttribute, sizeof(sAttribute), "\n");
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetMoney(iD, iFormat, sizeof(iFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "experience: ");
    for(int i = 0; i < 6; i++)
    {
        if(iFormat[i] != -1) Format(sAttribute, sizeof(sAttribute), "%s \"%d\"", sAttribute, iFormat[i]);
    } 
    StrCat(sAttribute, sizeof(sAttribute), "\n");
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "lifesteal:  \"%d\"\n", ClassGetLifeSteal(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "ammunition: \"%s\"\n", ClassGetAmmunition(iD) == 2 ? "clip ammunition" : (ClassGetAmmunition(iD) ? "BP ammunition" : "off"));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "leap:       \"%s\"\n", ClassGetLeapJump(iD) == 2 ? "only if a single player" : (ClassGetLeapJump(iD) ? "enabled" : "off"));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);

    FormatEx(sAttribute, sizeof(sAttribute), "force:      \"%.1f\"\n", ClassGetLeapForce(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "cooldown:   \"%.1f\"\n", ClassGetLeapCountdown(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    ClassGetEffectName(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "effect:     \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);

    ClassGetEffectAttach(iD, sFormat, sizeof(sFormat));
    FormatEx(sAttribute, sizeof(sAttribute), "attachment: \"%s\"\n", sFormat);
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);

    FormatEx(sAttribute, sizeof(sAttribute), "time:       \"%.1f\"\n", ClassGetEffectTime(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "death:      \"%d\"\n", ClassGetSoundDeathID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "hurt:       \"%d\"\n", ClassGetSoundHurtID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "idle:       \"%d\"\n", ClassGetSoundIdleID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "infect:     \"%d\"\n", ClassGetSoundInfectID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "respawn:    \"%d\"\n", ClassGetSoundRespawnID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "burn:       \"%d\"\n", ClassGetSoundBurnID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "attack:     \"%d\"\n", ClassGetSoundAttackID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "footstep:   \"%d\"\n", ClassGetSoundFootID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);
    
    FormatEx(sAttribute, sizeof(sAttribute), "regen:      \"%d\"\n", ClassGetSoundRegenID(iD));
    iCellCount += StrCat(sBuffer, iMaxLen, sAttribute);

    return iCellCount;
}