/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          natives.h.cpp
 *  Type:          API 
 *  Description:   Natives handlers for the ZP API.
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
 * Initializes all natives.
 **/
void APINativesInit(/*void*/)
{
    CreateNative("ZP_IsPlayerPrivileged",             API_IsPlayerPrivileged);
    CreateNative("ZP_IsPlayerZombie",                 API_IsPlayerZombie);
    CreateNative("ZP_IsPlayerHuman",                  API_IsPlayerHuman);
    CreateNative("ZP_IsPlayerNemesis",                API_IsPlayerNemesis);
    CreateNative("ZP_IsPlayerSurvivor",               API_IsPlayerSurvivor);
    CreateNative("ZP_IsPlayerUseZombieSkill",         API_IsPlayerUseZombieSkill);
    CreateNative("ZP_ForceClientRespawn",             API_ForceClientRespawn);
    CreateNative("ZP_SwitchClientClass",              API_SwitchClientClass);
    CreateNative("ZP_GetClientAmmoPack",              API_GetClientAmmoPack);
    CreateNative("ZP_SetClientAmmoPack",              API_SetClientAmmoPack);
    CreateNative("ZP_GetClientLastBought",            API_GetClientLastBought);
    CreateNative("ZP_SetClientLastBought",            API_SetClientLastBought);
    CreateNative("ZP_GetClientLevel",                 API_GetClientLevel);
    CreateNative("ZP_SetClientLevel",                 API_SetClientLevel);
    CreateNative("ZP_GetClientExp",                   API_GetClientExp);
    CreateNative("ZP_SetClientExp",                   API_SetClientExp);
    CreateNative("ZP_EmitSound",                      API_EmitSound);
    CreateNative("ZP_IsNewRound",                     API_IsNewRound);
    CreateNative("ZP_IsEndRound",                     API_IsEndRound);
    CreateNative("ZP_IsStartedRound",                 API_IsStartedRound);
    CreateNative("ZP_GetNumberRound",                 API_GetNumberRound);
    CreateNative("ZP_GetHumanAmount",                 API_GetHumanAmount);
    CreateNative("ZP_GetZombieAmount",                API_GetZombieAmount);
    CreateNative("ZP_GetAliveAmount",                 API_GetAliveAmount);
    CreateNative("ZP_GetPlayingAmount",               API_GetPlayingAmount);
    CreateNative("ZP_GetRandomHuman",                 API_GetRandomHuman);
    CreateNative("ZP_GetRandomZombie",                API_GetRandomZombie);  
    CreateNative("ZP_GetRandomSurvivor",              API_GetRandomSurvivor);
    CreateNative("ZP_GetRandomNemesis",               API_GetRandomNemesis);
    
    CreateNative("ZP_GetNumberHumanClass",            API_GetNumberHumanClass);
    CreateNative("ZP_GetClientHumanClass",            API_GetClientHumanClass);
    CreateNative("ZP_GetClientHumanClassNext",        API_GetClientHumanClassNext);
    CreateNative("ZP_SetClientHumanClass",            API_SetClientHumanClass);
    CreateNative("ZP_RegisterHumanClass",             API_RegisterHumanClass);
    CreateNative("ZP_GetHumanClassName",              API_GetHumanClassName);
    CreateNative("ZP_GetHumanClassModel",             API_GetHumanClassModel);
    CreateNative("ZP_GetHumanClassArm",               API_GetHumanClassArm);
    CreateNative("ZP_GetHumanClassHealth",            API_GetHumanClassHealth);
    CreateNative("ZP_GetHumanClassSpeed",             API_GetHumanClassSpeed);
    CreateNative("ZP_GetHumanClassGravity",           API_GetHumanClassGravity);
    CreateNative("ZP_GetHumanClassArmor",             API_GetHumanClassArmor);
    CreateNative("ZP_GetHumanClassLevel",             API_GetHumanClassLevel);
    CreateNative("ZP_IsHumanClassVIP",                API_IsHumanClassVIP);
    CreateNative("ZP_GetHumanClassSoundDeath",        API_GetHumanClassSoundDeath);
    CreateNative("ZP_GetHumanClassSoundHurt",         API_GetHumanClassSoundHurt);
    CreateNative("ZP_GetHumanClassSoundInfect",       API_GetHumanClassSoundInfect);
    CreateNative("ZP_PrintHumanClassInfo",            API_PrintHumanClassInfo);
    
    CreateNative("ZP_GetNumberZombieClass",           API_GetNumberZombieClass);
    CreateNative("ZP_GetClientZombieClass",           API_GetClientZombieClass);
    CreateNative("ZP_GetClientZombieClassNext",       API_GetClientZombieClassNext);
    CreateNative("ZP_SetClientZombieClass",           API_SetClientZombieClass);
    CreateNative("ZP_RegisterZombieClass",            API_RegisterZombieClass);
    CreateNative("ZP_GetZombieClassName",             API_GetZombieClassName);
    CreateNative("ZP_GetZombieClassInfo",             API_GetZombieClassInfo);
    CreateNative("ZP_GetZombieClassModel",            API_GetZombieClassModel);
    CreateNative("ZP_GetZombieClassClaw",             API_GetZombieClassClaw);
    CreateNative("ZP_GetZombieClassGrenade",          API_GetZombieClassGrenade);
    CreateNative("ZP_GetZombieClassHealth",           API_GetZombieClassHealth);
    CreateNative("ZP_GetZombieClassSpeed",            API_GetZombieClassSpeed);
    CreateNative("ZP_GetZombieClassGravity",          API_GetZombieClassGravity);
    CreateNative("ZP_GetZombieClassKnockBack",        API_GetZombieClassKnockBack);
    CreateNative("ZP_GetZombieClassLevel",            API_GetZombieClassLevel);    
    CreateNative("ZP_IsZombieClassVIP",               API_IsZombieClassVIP);
    CreateNative("ZP_GetZombieClassSkillDuration",    API_GetZombieClassSkillDuration);
    CreateNative("ZP_GetZombieClassSkillCountdown",   API_GetZombieClassSkillCountdown);
    CreateNative("ZP_GetZombieClassRegen",            API_GetZombieClassRegen);
    CreateNative("ZP_GetZombieClassRegenInterval",    API_GetZombieClassRegenInterval);
    CreateNative("ZP_GetZombieClassClawID",           API_GetZombieClassClawID);
    CreateNative("ZP_GetZombieClassGrenadeID",        API_GetZombieClassGrenadeID);
    CreateNative("ZP_GetZombieClassSoundDeath",       API_GetZombieClassSoundDeath);
    CreateNative("ZP_GetZombieClassSoundHurt",        API_GetZombieClassSoundHurt);
    CreateNative("ZP_GetZombieClassSoundIdle",        API_GetZombieClassSoundIdle);
    CreateNative("ZP_GetZombieClassSoundRespawn",     API_GetZombieClassSoundRespawn);
    CreateNative("ZP_GetZombieClassSoundBurn",        API_GetZombieClassSoundBurn);
    CreateNative("ZP_GetZombieClassSoundAttack",      API_GetZombieClassSoundAttack);
    CreateNative("ZP_GetZombieClassSoundFoot",        API_GetZombieClassSoundFoot);
    CreateNative("ZP_GetZombieClassSoundRegen",       API_GetZombieClassSoundRegen);
    CreateNative("ZP_PrintZombieClassInfo",           API_PrintZombieClassInfo);
    
    CreateNative("ZP_GiveClientExtraItem",            API_GiveClientExtraItem); 
    CreateNative("ZP_SetClientExtraItemLimit",        API_SetClientExtraItemLimit); 
    CreateNative("ZP_GetClientExtraItemLimit",        API_GetClientExtraItemLimit); 
    CreateNative("ZP_RegisterExtraItem",              API_RegisterExtraItem);
    CreateNative("ZP_GetNumberExtraItem",             API_GetNumberExtraItem); 
    CreateNative("ZP_GetExtraItemName",               API_GetExtraItemName); 
    CreateNative("ZP_GetExtraItemCost",               API_GetExtraItemCost); 
    CreateNative("ZP_GetExtraItemLevel",              API_GetExtraItemLevel); 
    CreateNative("ZP_GetExtraItemOnline",             API_GetExtraItemOnline); 
    CreateNative("ZP_GetExtraItemLimit",              API_GetExtraItemLimit); 
    CreateNative("ZP_PrintExtraItemInfo",             API_PrintExtraItemInfo); 
    
    CreateNative("ZP_GetWeaponAttachmentPos",         API_GetWeaponAttachPos);
    CreateNative("ZP_GiveClientWeapon",               API_GiveClientWeapon);
    CreateNative("ZP_GetWeaponNameID",                API_GetWeaponNameID);
    CreateNative("ZP_GetWeaponID",                    API_GetWeaponID);
    CreateNative("ZP_GetNumberWeapon",                API_GetNumberWeapon);
    CreateNative("ZP_GetWeaponName",                  API_GetWeaponName);
    CreateNative("ZP_GetWeaponEntity",                API_GetWeaponEntity);
    CreateNative("ZP_GetWeaponIndex",                 API_GetWeaponIndex);
    CreateNative("ZP_GetWeaponCost",                  API_GetWeaponCost);
    CreateNative("ZP_GetWeaponSlot",                  API_GetWeaponSlot);
    CreateNative("ZP_GetWeaponLevel",                 API_GetWeaponLevel);
    CreateNative("ZP_GetWeaponOnline",                API_GetWeaponOnline);
    CreateNative("ZP_GetWeaponDamage",                API_GetWeaponDamage);
    CreateNative("ZP_GetWeaponKnockBack",             API_GetWeaponKnockBack);
    CreateNative("ZP_GetWeaponClip",                  API_GetWeaponClip);
    CreateNative("ZP_GetWeaponAmmo",                  API_GetWeaponAmmo);
    CreateNative("ZP_GetWeaponSpeed",                 API_GetWeaponSpeed);
    CreateNative("ZP_GetWeaponReload",                API_GetWeaponReload);
    CreateNative("ZP_GetWeaponSound",                 API_GetWeaponSound);
    CreateNative("ZP_GetWeaponClass",                 API_GetWeaponClass);
    CreateNative("ZP_GetWeaponModelView",             API_GetWeaponModelView);
    CreateNative("ZP_GetWeaponModelViewID",           API_GetWeaponModelViewID);
    CreateNative("ZP_GetWeaponModelWorld",            API_GetWeaponModelWorld);    
    CreateNative("ZP_GetWeaponModelWorldID",          API_GetWeaponModelWorldID); 
    CreateNative("ZP_GetWeaponModelBody",             API_GetWeaponModelBody); 
    CreateNative("ZP_GetWeaponModelSkin",             API_GetWeaponModelSkin); 
    CreateNative("ZP_GetWeaponModelHeat",             API_GetWeaponModelHeat); 
    
    CreateNative("ZP_GetNumberHitgroup",              API_GetNumberHitgroup);
    CreateNative("ZP_GetHitgroupID",                  API_GetHitgroupID);
    CreateNative("ZP_GetHitgroupName",                API_GetHitgroupName);
    CreateNative("ZP_GetHitgroupIndex",               API_GetHitgroupIndex);
    CreateNative("ZP_IsHitgroupDamage",               API_IsHitgroupDamage);
    CreateNative("ZP_SetHitgroupDamage",              API_SetHitgroupDamage);
    CreateNative("ZP_GetHitgroupKnockback",           API_GetHitgroupKnockback);
    CreateNative("ZP_SetHitgroupKnockback",           API_SetHitgroupKnockback);

    CreateNative("ZP_GetNumberMenu",                  API_GetNumberMenu);
    CreateNative("ZP_GetMenuName",                    API_GetMenuName);
    CreateNative("ZP_GetMenuAccess",                  API_GetMenuAccess);
    CreateNative("ZP_GetMenuCommand",                 API_GetMenuCommand);
    
    CreateNative("ZP_GetCurrentGameMode",             API_GetCurrentGameMode);
    CreateNative("ZP_GetNumberGameMode",              API_GetNumberGameMode);
    CreateNative("ZP_GetServerGameMode",              API_GetServerGameMode);
    CreateNative("ZP_SetServerGameMode",              API_SetServerGameMode);
    CreateNative("ZP_RegisterGameMode",               API_RegisterGameMode);
    CreateNative("ZP_GetGameModeName",                API_GetGameModeName);
    CreateNative("ZP_GetGameModeDesc",                API_GetGameModeDesc);
    CreateNative("ZP_GetGameModeSound",               API_GetGameModeSound);
    CreateNative("ZP_GetGameModeChance",              API_GetGameModeChance);
    CreateNative("ZP_GetGameModeMinPlayers",          API_GetGameModeMinPlayers);
    CreateNative("ZP_GetGameModeRatio",               API_GetGameModeRatio);
    CreateNative("ZP_IsGameModeInfect",               API_IsGameModeInfect);
    CreateNative("ZP_IsGameModeRespawn",              API_IsGameModeRespawn);
    CreateNative("ZP_IsGameModeSurvivor",             API_IsGameModeSurvivor);
    CreateNative("ZP_IsGameModeNemesis",              API_IsGameModeNemesis);
    
    CreateNative("ZP_GetNumberCostumes",              API_GetNumberCostumes);
    CreateNative("ZP_GetClientCostume",               API_GetClientCostume);
    CreateNative("ZP_SetClientCostume",               API_SetClientCostume);
    CreateNative("ZP_GetCostumeName",                 API_GetCostumeName);
    CreateNative("ZP_GetCostumeModel",                API_GetCostumeModel);
    CreateNative("ZP_GetCostumeBody",                 API_GetCostumeBody);
    CreateNative("ZP_GetCostumeSkin",                 API_GetCostumeSkin);
    CreateNative("ZP_GetCostumeAttach",               API_GetCostumeAttach);
    CreateNative("ZP_GetCostumeAccess",               API_GetCostumeAccess);
    CreateNative("ZP_IsCostumeHide",                  API_IsCostumeHide);
}

/**
 * Returns whether a player is allowed to do a certain operation or not.
 *
 * native bool ZP_IsPlayerPrivileged(clientIndex, flag);
 **/
public int API_IsPlayerPrivileged(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return IsPlayerHasFlag(clientIndex, view_as<AdminFlag>(GetNativeCell(2)));
}

/**
 * Returns true if the player is a zombie, false if not. 
 *
 * native bool ZP_IsPlayerZombie(clientIndex);
 **/
public int API_IsPlayerZombie(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex][Client_Zombie];
}

/**
 * Returns true if the player is a human, false if not.
 *
 * native bool ZP_IsPlayerHuman(clientIndex);
 **/
public int API_IsPlayerHuman(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return !gClientData[clientIndex][Client_Zombie];
}

/**
 * Returns true if the player is a nemesis, false if not. (Nemesis always have ZP_IsPlayerZombie() native)
 *
 * native bool ZP_IsPlayerNemesis(clientIndex);
 **/
public int API_IsPlayerNemesis(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex][Client_Nemesis];
}

/**
 * Returns true if the player is a survivor, false if not.
 *
 * native bool ZP_IsPlayerSurvivor(clientIndex);
 **/
public int API_IsPlayerSurvivor(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex][Client_Survivor];
}

/**
 * Returns true if the player use a zombie skill, false if not. 
 *
 * native bool ZP_IsPlayerUseZombieSkill(clientIndex);
 **/
public int API_IsPlayerUseZombieSkill(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex][Client_Skill];
}

/**
 * Force to respawn a player.
 *
 * native void ZP_ForceClientRespawn(clientIndex, iD);
 **/
public int API_ForceClientRespawn(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Force client to respawn
    ToolsForceToRespawn(clientIndex);
}

/**
 * Force to switch a player's class.
 *
 * native void ZP_SwitchClientClass(clientIndex, attackerIndex, iD);
 **/
public int API_SwitchClientClass(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);
    int attackerIndex = GetNativeCell(2);

    // Force client to switch player's class
    switch(GetNativeCell(3))
    {
        case 0 /*TYPE_ZOMBIE*/ :   ClassMakeZombie(clientIndex, attackerIndex);       /**< Make a zombie */
        case 1 /*TYPE_NEMESIS*/ :  ClassMakeZombie(clientIndex, attackerIndex, true); /**< Make a nemesis */
        case 2 /*TYPE_SURVIVOR*/ : ClassMakeHuman(clientIndex, true);                 /**< Make a survivor */
        case 3 /*TYPE_HUMAN*/ :    ClassMakeHuman(clientIndex);                       /**< Make a human */
    }
}

/**
 * Gets the player's amount of ammopacks.
 *
 * native int ZP_GetClientAmmoPack(clientIndex);
 **/
public int API_GetClientAmmoPack(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_AmmoPacks];
}

/**
 * Sets the player's amount of ammopacks.
 *
 * native void ZP_SetClientAmmoPack(clientIndex, iD);
 **/
public int API_SetClientAmmoPack(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets ammopacks for the client
    AccountSetClientCash(clientIndex, GetNativeCell(2));
}

/**
 * Gets the player's amount of previous ammopacks spended.
 *
 * native int ZP_GetClientLastBought(clientIndex);
 **/
public int API_GetClientLastBought(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_LastBoughtAmount];
}

/**
 * Sets the player's amount of ammopacks spending.
 *
 * native void ZP_SetClientLastBoughtv(clientIndex, iD);
 **/
public int API_SetClientLastBought(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets ammopacks for the client
    gClientData[clientIndex][Client_LastBoughtAmount] = GetNativeCell(2);
}

/**
 * Gets the player's level.
 *
 * native int ZP_GetClientLevel(clientIndex);
 **/
public int API_GetClientLevel(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Level];
}

/**
 * Sets the player's level.
 *
 * native void ZP_SetClientLevel(clientIndex, iD);
 **/
public int API_SetClientLevel(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets ammopacks for the client
    LevelSystemOnSetLvl(clientIndex, GetNativeCell(2));
}

/**
 * Gets the player's exp.
 *
 * native int ZP_GetClientExp(clientIndex);
 **/
public int API_GetClientExp(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex][Client_Exp];
}

/**
 * Sets the player's exp.
 *
 * native void ZP_SetClientExp(clientIndex, iD);
 **/
public int API_SetClientExp(Handle isPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Sets ammopacks for the client
    LevelSystemOnSetExp(clientIndex, GetNativeCell(2));
}

/**
 * Gets the new round's state.
 *
 * native bool ZP_IsNewRound();
 **/
public int API_IsNewRound(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundNew];
}

/**
 * Gets the end round's state.
 *
 * native bool ZP_IsEndRound();
 **/
public int API_IsEndRound(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundEnd];
}

/**
 * Gets the new round's state.
 *
 * native bool ZP_IsStartedRound();
 **/
public int API_IsStartedRound(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundStart];
}

/**
 * Gets the number of round.
 *
 * native int ZP_GetNumberRound();
 **/
public int API_GetNumberRound(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return gServerData[Server_RoundNumber];
}

/**
 * Gets amount of total humans.
 *
 * native int ZP_GetHumanAmount();
 **/
public int API_GetHumanAmount(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetHumans();
}

/**
 * Gets amount of total zombies.
 *
 * native int ZP_GetZombieAmount();
 **/
public int API_GetZombieAmount(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetZombies();
}

/**
 * Gets amount of total alive players.
 *
 * native int ZP_GetAliveAmount();
 **/
public int API_GetAliveAmount(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetAlive();
}

/**
 * Gets amount of total playing players.
 *
 * native int ZP_GetPlayingAmount();
 **/
public int API_GetPlayingAmount(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetPlaying();
}

/**
 * Gets index of the random human.
 *
 * native int ZP_GetRandomHuman();
 **/
public int API_GetRandomHuman(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetRandomHuman();
}

/**
 * Gets index of the random zombie.
 *
 * native int ZP_GetRandomZombie();
 **/
public int API_GetRandomZombie(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetRandomZombie();
}

/**
 * Gets index of the random survivor.
 *
 * native int ZP_GetRandomSurvivor();
 **/
public int API_GetRandomSurvivor(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetRandomSurvivor();
}

/**
 * Gets index of the random nemesis.
 *
 * native int ZP_GetRandomNemesis();
 **/
public int API_GetRandomNemesis(Handle isPlugin, int iNumParams)
{
    // Return the value 
    return fnGetRandomNemesis();
}
