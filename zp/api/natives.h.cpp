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
 */
void APINativesInit(/*void*/)
{
	CreateNative("ZP_IsPlayerPrivileged", 			API_IsPlayerPrivileged);
	CreateNative("ZP_IsPlayerZombie", 				API_IsPlayerZombie);
	CreateNative("ZP_IsPlayerHuman", 				API_IsPlayerHuman);
	CreateNative("ZP_IsPlayerNemesis",				API_IsPlayerNemesis);
	CreateNative("ZP_IsPlayerSurvivor",				API_IsPlayerSurvivor);
	CreateNative("ZP_IsPlayerUseZombieSkill", 		API_IsPlayerUseZombieSkill);
	CreateNative("ZP_ForceClientRespawn",			API_ForceClientRespawn);
	CreateNative("ZP_SwitchClientClass",			API_SwitchClientClass);
	CreateNative("ZP_GetClientAmmoPack", 			API_GetClientAmmoPack);
	CreateNative("ZP_SetClientAmmoPack", 			API_SetClientAmmoPack);
	CreateNative("ZP_GetClientLastBought",			API_GetClientLastBought);
	CreateNative("ZP_SetClientLastBought",			API_SetClientLastBought);
	CreateNative("ZP_GetClientLevel", 				API_GetClientLevel);
	CreateNative("ZP_SetClientLevel", 				API_SetClientLevel);
	CreateNative("ZP_GetClientExp", 				API_GetClientExp);
	CreateNative("ZP_SetClientExp", 				API_SetClientExp);
	
	CreateNative("ZP_SetRoundGameMode", 			API_SetRoundGameMode);
	CreateNative("ZP_GetRoundState", 				API_GetRoundState);
	CreateNative("ZP_GetHumanAmount", 				API_GetHumanAmount);
	CreateNative("ZP_GetZombieAmount", 				API_GetZombieAmount);
	CreateNative("ZP_GetAliveAmount", 				API_GetAliveAmount);
	CreateNative("ZP_GetPlayingAmount", 			API_GetPlayingAmount);
	
	CreateNative("ZP_GetNumberHumanClass", 			API_GetNumberHumanClass);
	CreateNative("ZP_GetClientHumanClass", 			API_GetClientHumanClass);
	CreateNative("ZP_GetClientHumanClassNext", 		API_GetClientHumanClassNext);
	CreateNative("ZP_SetClientHumanClass", 			API_SetClientHumanClass);
	CreateNative("ZP_RegisterHumanClass", 			API_RegisterHumanClass);
	CreateNative("ZP_GetHumanClassName", 			API_GetHumanClassName);
	CreateNative("ZP_GetHumanClassModel", 			API_GetHumanClassModel);
	CreateNative("ZP_GetHumanClassArm", 			API_GetHumanClassArm);
	CreateNative("ZP_GetHumanClassHealth", 			API_GetHumanClassHealth);
	CreateNative("ZP_GetHumanClassSpeed", 			API_GetHumanClassSpeed);
	CreateNative("ZP_GetHumanClassGravity", 		API_GetHumanClassGravity);
	CreateNative("ZP_GetHumanClassArmor", 			API_GetHumanClassArmor);
	CreateNative("ZP_GetHumanClassLevel", 			API_GetHumanClassLevel);
	CreateNative("ZP_IsHumanClassFemale", 			API_IsHumanClassFemale);
	CreateNative("ZP_IsHumanClassVIP", 				API_IsHumanClassVIP);
	CreateNative("ZP_PrintHumanClassInfo", 			API_PrintHumanClassInfo);
	
	CreateNative("ZP_GetNumberZombieClass", 		API_GetNumberZombieClass);
	CreateNative("ZP_GetClientZombieClass", 		API_GetClientZombieClass);
	CreateNative("ZP_GetClientZombieClassNext", 	API_GetClientZombieClassNext);
	CreateNative("ZP_SetClientZombieClass",			API_SetClientZombieClass);
	CreateNative("ZP_RegisterZombieClass", 			API_RegisterZombieClass);
	CreateNative("ZP_GetZombieClassName", 			API_GetZombieClassName);
	CreateNative("ZP_GetZombieClassModel", 			API_GetZombieClassModel);
	CreateNative("ZP_GetZombieClassClaw", 			API_GetZombieClassClaw);
	CreateNative("ZP_GetZombieClassHealth", 		API_GetZombieClassHealth);
	CreateNative("ZP_GetZombieClassSpeed", 			API_GetZombieClassSpeed);
	CreateNative("ZP_GetZombieClassGravity", 		API_GetZombieClassGravity);
	CreateNative("ZP_GetZombieClassKnockBack", 		API_GetZombieClassKnockBack);
	CreateNative("ZP_GetZombieClassLevel", 			API_GetZombieClassLevel);	
	CreateNative("ZP_IsZombieClassFemale", 			API_IsZombieClassFemale);
	CreateNative("ZP_IsZombieClassVIP", 			API_IsZombieClassVIP);
	CreateNative("ZP_GetZombieClassSkillDuration",  API_GetZombieClassSkillDuration);
	CreateNative("ZP_GetZombieClassSkillCountdown", API_GetZombieClassSkillCountdown);
	CreateNative("ZP_GetZombieClassRegen",  		API_GetZombieClassRegen);
	CreateNative("ZP_GetZombieClassRegenInterval",  API_GetZombieClassRegenInterval);
	CreateNative("ZP_GetZombieClassClawID", 		API_GetZombieClassClawID);
	CreateNative("ZP_PrintZombieClassInfo", 		API_PrintZombieClassInfo);
	
	CreateNative("ZP_GiveClientExtraItem", 			API_GiveClientExtraItem); 
	CreateNative("ZP_SetClientExtraItemLimit", 		API_SetClientExtraItemLimit); 
	CreateNative("ZP_GetClientExtraItemLimit", 		API_GetClientExtraItemLimit); 
	CreateNative("ZP_RegisterExtraItem", 			API_RegisterExtraItem);
	CreateNative("ZP_GetNumberExtraItem", 			API_GetNumberExtraItem); 
	CreateNative("ZP_GetExtraItemName", 			API_GetExtraItemName); 
	CreateNative("ZP_GetExtraItemCost", 			API_GetExtraItemCost); 
	CreateNative("ZP_GetExtraItemTeam", 			API_GetExtraItemTeam); 
	CreateNative("ZP_GetExtraItemLevel", 			API_GetExtraItemLevel); 
	CreateNative("ZP_GetExtraItemOnline", 			API_GetExtraItemOnline); 
	CreateNative("ZP_GetExtraItemLimit", 			API_GetExtraItemLimit); 
	CreateNative("ZP_PrintExtraItemInfo", 			API_PrintExtraItemInfo); 

	CreateNative("ZP_GetNumberWeapon", 				API_GetNumberWeapon);
	CreateNative("ZP_GetWeaponName", 				API_GetWeaponName);
	CreateNative("ZP_GetWeaponEntity", 				API_GetWeaponEntity);
	CreateNative("ZP_GetWeaponIndex", 				API_GetWeaponIndex);
	CreateNative("ZP_GetWeaponCost", 				API_GetWeaponCost);
	CreateNative("ZP_GetWeaponSlot", 				API_GetWeaponSlot);
	CreateNative("ZP_GetWeaponLevel", 				API_GetWeaponLevel);
	CreateNative("ZP_GetWeaponOnline", 				API_GetWeaponOnline);
	CreateNative("ZP_GetWeaponDamage", 				API_GetWeaponDamage);
	CreateNative("ZP_GetWeaponKnockBack", 			API_GetWeaponKnockBack);
	CreateNative("ZP_GetWeaponModelClass", 			API_GetWeaponModelClass);
	CreateNative("ZP_GetWeaponModelView", 			API_GetWeaponModelView);
	CreateNative("ZP_GetWeaponModelViewID", 		API_GetWeaponModelViewID);
	CreateNative("ZP_GetWeaponModelWorld", 			API_GetWeaponModelWorld);	
	CreateNative("ZP_GetWeaponModelWorldID", 		API_GetWeaponModelWorldID);	
}

/**
 * Returns whether a player is allowed to do a certain operation or not.
 *
 * native bool ZP_IsPlayerPrivileged(clientIndex, flag);
 **/
public int API_IsPlayerPrivileged(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value
	return IsPlayerHasFlag(cBasePlayer->Index, view_as<AdminFlag>(GetNativeCell(2)));
}

/**
 * Returns true ifthe player is a zombie, false ifnot. 
 *
 * native bool ZP_IsPlayerZombie(clientIndex);
 **/
public int API_IsPlayerZombie(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value
    return cBasePlayer->m_bZombie;
}

/**
 * Returns true ifthe player is a human, false ifnot.
 *
 * native bool ZP_IsPlayerHuman(clientIndex);
 **/
public int API_IsPlayerHuman(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value
    return !cBasePlayer->m_bZombie;
}

/**
 * Returns true ifthe player is a nemesis, false ifnot. (Nemesis always have ZP_IsPlayerZombie() native)
 *
 * native bool ZP_IsPlayerNemesis(clientIndex);
 **/
public int API_IsPlayerNemesis(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value
    return cBasePlayer->m_bNemesis;
}

/**
 * Returns true ifthe player is a survivor, false ifnot.
 *
 * native bool ZP_IsPlayerSurvivor(clientIndex);
 **/
public int API_IsPlayerSurvivor(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value
    return cBasePlayer->m_bSurvivor;
}

/**
 * Returns true ifthe player use a zombie skill, false ifnot. 
 *
 * native bool ZP_IsPlayerUseZombieSkill(clientIndex);
 **/
public int API_IsPlayerUseZombieSkill(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value
    return cBasePlayer->m_bSkill;
}

/**
 * Force to respawn a player.
 *
 * native void ZP_ForceClientRespawn(clientIndex, iD);
 **/
public int API_ForceClientRespawn(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Force client to respawn
	ToolsForceToRespawn(cBasePlayer);
}

/**
 * Force to switch a player's class.
 *
 * native void ZP_SwitchClientClass(clientIndex, iD);
 **/
public int API_SwitchClientClass(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Force client to switch player's class
	switch(GetNativeCell(2))
	{
		case 0 :  InfectHumanToZombie(cBasePlayer);
		case 1 :  InfectHumanToZombie(cBasePlayer, _, true);
		case 2 :  MakeHumanIntoSurvivor(cBasePlayer);
		case 3 :  MakeZombieToHuman(cBasePlayer);
	}
}

/**
 * Gets the player's amount of ammopacks.
 *
 * native int ZP_GetClientAmmoPack(clientIndex);
 **/
public int API_GetClientAmmoPack(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_nAmmoPacks;
}

/**
 * Sets the player's amount of ammopacks.
 *
 * native void ZP_SetClientAmmoPack(clientIndex, iD);
 **/
public int API_SetClientAmmoPack(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Set ammopacks for the client
	cBasePlayer->m_nAmmoPacks = GetNativeCell(2);
}

/**
 * Gets the player's amount of previous ammopacks spended.
 *
 * native int ZP_GetClientLastBought(clientIndex);
 **/
public int API_GetClientLastBought(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_nLastBoughtAmount;
}

/**
 * Sets the player's amount of ammopacks spending.
 *
 * native void ZP_SetClientLastBoughtv(clientIndex, iD);
 **/
public int API_SetClientLastBought(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Set ammopacks for the client
	cBasePlayer->m_nLastBoughtAmount = GetNativeCell(2);
}

/**
 * Gets the player's level.
 *
 * native int ZP_GetClientLevel(clientIndex);
 **/
public int API_GetClientLevel(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_iLevel;
}

/**
 * Sets the player's level.
 *
 * native void ZP_SetClientLevel(clientIndex, iD);
 **/
public int API_SetClientLevel(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Set ammopacks for the client
	cBasePlayer->m_iLevel = GetNativeCell(2);
}

/**
 * Gets the player's exp.
 *
 * native int ZP_GetClientExp(clientIndex);
 **/
public int API_GetClientExp(Handle isPlugin, int iNumParams)
{
    // Get real player index from native cell 
    CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Return the value 
    return cBasePlayer->m_iExp;
}

/**
 * Sets the player's exp.
 *
 * native void ZP_SetClientExp(clientIndex, iD);
 **/
public int API_SetClientExp(Handle isPlugin, int iNumParams)
{
	// Get real player index from native cell 
	CBasePlayer* cBasePlayer = CBasePlayer(GetNativeCell(1));

	// Set ammopacks for the client
	cBasePlayer->m_iExp = GetNativeCell(2);
}

/**
 * Sets the game mode.
 *
 * native void ZP_SetRoundGameMode(mode);
 **/
public int API_SetRoundGameMode(Handle isPlugin, int iNumParams)
{
	// Set the mode 
	GameModesEventStart(GetNativeCell(1), GetNativeCell(2));
}

/**
 * Gets the round's state.
 *
 * native int ZP_GetRoundState(type);
 **/
public int API_GetRoundState(Handle isPlugin, int iNumParams)
{
	// Return the value 
	switch(GetNativeCell(1))
	{
		case Server_RoundNew 	:  return gServerData[Server_RoundNew];
		case Server_RoundEnd 	:  return gServerData[Server_RoundEnd];
		case Server_RoundStart  :  return gServerData[Server_RoundStart];
		case Server_RoundNumber :  return gServerData[Server_RoundNumber];
		case Server_RoundMode 	:  return gServerData[Server_RoundMode];
	}
	
	// Compilator required return over here
	return -1;
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