/**
 * =============================================================================
 * Zombie Plague 7.x Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin).
 * =============================================================================
 *
 * This file is part of the Zombie Plague Core.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 **/

#if defined _zombieplaguemod_included
 #endinput
#endif
#define _zombieplaguemod_included

/**
 * Lenth of usual strings.
 **/
#define SMALL_LINE_LENGTH 	32
#define NORMAL_LINE_LENGTH 	64
#define BIG_LINE_LENGTH 	128

/**
 * Number of gamemodes.
 **/
enum
{
	MODE_NONE = -1,			/**< Used as return value when an mode didn't start */
	
	MODE_INFECTION,			/**< Normal infection */
	MODE_MULTI,				/**< Multi infection */
	MODE_SWARM,				/**< Swarm mode */
	MODE_NEMESIS,			/**< Nemesis round */
	MODE_SURVIVOR,			/**< Survivor round */
	MODE_ARMAGEDDON			/**< Armageddon round */
};

/**
 * Number of player's classes.
 **/
enum ZPClassType
{
	TYPE_ZOMBIE,			/**< Make a zombie */
	TYPE_NEMESIS,			/**< Make a nemesis */
	TYPE_SURVIVOR,			/**< Make a survivor */
	TYPE_HUMAN				/**< Make a human */
};

/**
 * Number of round's states.
 **/
enum ZPServerRound
{
	SERVER_ROUND_NEW,		/**< Round not started */
	SERVER_ROUND_END,		/**< Round ended ? */
	SERVER_ROUND_STARTED,	/**< Round started ? */
	SERVER_ROUND_NUMBER,	/**< Round number */
	SERVER_ROUND_MODE		/**< Round gamemode */
};

/**
 * Number of valid player's teams.
 **/
enum ZPTeamType
{
	TEAM_HUMAN,				/**< Human team */
	TEAM_ZOMBIE,			/**< Zombie team */
	TEAM_ALL				/**< Any team */
};

/**
 * Number of options.
 **/
enum ZPSelectType
{
	NO,				
	YES
};


#include "zombieplague/weapons.inc"
#include "zombieplague/extraitems.inc"
#include "zombieplague/humanclasses.inc" 
#include "zombieplague/zombieclasses.inc"


//*********************************************************************
//*           			CORE MAIN FORWARDS            				  *
//*********************************************************************

/**
 * @brief Called when a client became a zombie.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 *
 * @noreturn
 **/
forward void ZP_OnClientInfected(int clientIndex, int attackerIndex);

/**
 * @brief Called when a client became a survivor.
 * 
 * @param clientIndex		The client index.
 *
 * @noreturn
 **/
forward void ZP_OnClientHeroed(int clientIndex);

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex		The client index.
 * @param attackerIndex		The attacker index.
 * @param damageAmount		The amount of damage inflicted.
 *
 * @noreturn
 **/
forward void ZP_OnClientDamaged(int clientIndex, int attackerIndex, float &damageAmount);

/**
 * @brief Called when a client use a zombie skill.
 * 
 * @param clientIndex		The client index.
 *
 * @return					Plugin_Handled or Plugin_Stop to block using skill. Anything else
 *                          	(like Plugin_Continue) to allow use.
 **/
forward Action ZP_OnClientSkillUsed(int clientIndex);

/**
 * @brief Called when a zombie skill duration is over.
 * 
 * @param clientIndex		The client index.
 *
 * @noreturn
 **/
forward void ZP_OnClientSkillOver(int clientIndex);

/**
 * @brief Called after a zombie round is started.
 * 
 * @param modeIndex			The round mode.
 *
 * @noreturn
 **/
forward void ZP_OnZombieModStarted(int modeIndex);


//*********************************************************************
//*           			CORE MAIN NATIVES            				  *
//*********************************************************************

/**
 * Returns whether a player is allowed to do a certain operation or not.
 *
 * @param clientIndex		The client index.
 * @param flag				The access flag. See enum AdminFlag.
 *  
 * @return			        True or false.
 **/
native bool ZP_IsPlayerPrivileged(int clientIndex, AdminFlag flag);

/**
 * @brief Returns true if the player is a zombie, false if not. 
 *
 * @param clientIndex		The client index.
 *  
 * @return			        True or false.
 **/
native bool ZP_IsPlayerZombie(int clientIndex);

/**
 * @brief Returns true if the player is a human, false if not.
 *
 * @param clientIndex		The client index.
 *  
 * @return			        True or false.
 **/
native bool ZP_IsPlayerHuman(int clientIndex);

/**
 * @brief Returns true if the player is a nemesis, false if not. (In addition, Nemesis always have ZP_IsPlayerZombie() native)
 *
 * @param clientIndex		The client index.
 *  
 * @return			        True or false.
 **/
native bool ZP_IsPlayerNemesis(int clientIndex);

/**
 * @brief Returns true if the player is a survivor, false if not.
 *
 * @param clientIndex		The client index.
 *  
 * @return			        True or false.
 **/
native bool ZP_IsPlayerSurvivor(int clientIndex);

/**
 * @brief Returns true if the player use a zombie skill, false if not. 
 *
 * @param clientIndex		The client index.
 *  
 * @return			        True or false.
 **/
native bool ZP_IsPlayerUseZombieSkill(int clientIndex);

/**
 * @brief Force to respawn a player.
 *
 * @param clientIndex		The client index.
 *  
 * @noreturn
 **/
native void ZP_ForceClientRespawn(int clientIndex);

/**
 * @brief Force to switch a player's class.
 *
 * @param clientIndex		The client index.
 * @param typeIndex			The class type. See enum ZPClassType.
 *  
 * @noreturn
 **/
native void ZP_SwitchClientClass(int clientIndex, ZPClassType typeIndex);

/**
 * @brief Gets the player's amount of ammopacks.
 *
 * @param clientIndex		The client index.
 *  
 * @return			        The number of ammopacks.
 **/
native int ZP_GetClientAmmoPack(int clientIndex);

/**
 * @brief Sets the player's amount of ammopacks.
 *
 * @param clientIndex		The client index.
 * @param amountAmmo		The number of ammopacks.
 *  
 * @noreturn
 **/
native void ZP_SetClientAmmoPack(int clientIndex, int amountAmmo);

/**
 * @brief Gets the player's amount of previous ammopacks spended.
 *
 * @param clientIndex		The client index.
 *  
 * @return			        The number of ammopacks.
 **/
native int ZP_GetClientLastBought(int clientIndex);

/**
 * @brief Sets the player's amount of ammopacks spending.
 *
 * @param clientIndex		The client index.
 * @param amountAmmo		The number of ammopacks.
 *  
 * @noreturn
 **/
native void ZP_SetClientLastBought(int clientIndex, int amountAmmo);

/**
 * @brief Gets the player's level.
 *
 * @param clientIndex		The client index.
 *  
 * @return			        The number of level.
 **/
native int ZP_GetClientLevel(int clientIndex);

/**
 * @brief Sets the player's level.
 *
 * @param clientIndex		The client index.
 * @param amountLevel		The number of level.
 *  
 * @noreturn
 **/
native int ZP_SetClientLevel(int clientIndex, int amountLevel);

/**
 * @brief Gets the player's exp.
 *
 * @param clientIndex		The client index.
 *  
 * @return			        The number of exp.
 **/
native int ZP_GetClientExp(int clientIndex);

/**
 * @brief Sets the player's exp.
 *
 * @param clientIndex		The client index.
 * @param amountExp			The number of exp.
 *  
 * @noreturn
 **/
native int ZP_SetClientExp(int clientIndex, int amountExp);

//*********************************************************************
//*           			CORE USEFUL NATIVES            				  *
//*********************************************************************

/**
 * @brief Sets the game mode.
 *
 * @param modeIndex         The round mode.
 * @param clientIndex		(Optional) The client index.
 *  
 * @noreturn
 **/
native void ZP_SetRoundGameMode(int modeIndex, int clientIndex = 0);

/**
 * @brief Gets the round's state.
 *
 * @param typeIndex         The state type. See enum ZPServerRound.
 *  
 * @return			        The integer of type state.
 **/
native int ZP_GetRoundState(ZPServerRound typeIndex);

/**
 * @brief Gets amount of total humans.
 * 
 * @return	 				The amount of total humans.
 **/
native int ZP_GetHumanAmount();

/**
 * @brief Gets amount of total zombies.
 *
 * @return	 				The amount of total zombies.
 **/
native int ZP_GetZombieAmount();

/**
 * @brief Gets amount of total alive players.
 *
 * @return	 				The amount of total alive players.
 **/
native int ZP_GetAliveAmount();


/**
 * @brief Gets amount of total playing players.
 *
 * @return					The amount of total playing players.
 **/
native int ZP_GetPlayingAmount();

//*********************************************************************
//*           			OTHER USEFUL STOCKS            				  *
//*********************************************************************

/**
 * @brief Sets the view weapon's model.
 *
 * @param clientIndex		The client index.
 * @param weaponIndex		The weapon index.
 * @param modelIndex		The model index. (Must be precached)
 *
 * @noreturn
 **/
stock void SetViewModel(int clientIndex, int weaponIndex, int modelIndex)
{
	// Get view index
	int viewIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hViewModel");

	// Verify that the entity is valid
	if(IsValidEdict(viewIndex))
	{
		// Delete default model index
		SetEntProp(weaponIndex, Prop_Send, "m_nModelIndex", 0);
		
		// Set new view model index for the weapon
		SetEntProp(viewIndex, Prop_Send, "m_nModelIndex", modelIndex);
	}
}

/**
 * @brief Sets the world weapon's model.
 *
 * @param weaponIndex		The weapon index.
 * @param modelIndex		The model index. (Must be precached)
 *
 * @noreturn
 **/
stock void SetWorldModel(int weaponIndex, int modelIndex)
{
	// Get world index
	int worldIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
	
	// Verify that the entity is valid
	if(IsValidEdict(worldIndex))
	{
		// Set model for the entity
		SetEntProp(worldIndex, Prop_Send, "m_nModelIndex", modelIndex);
	}
}

/**
 * @brief Returns true if the player is connected and alive, false if not.
 *
 * @param clientIndex		The client index.
 * @param aliveness			(Optional) Set to true to validate that the client is alive, false to ignore.
 *  
 * @return					True or false.
 **/
stock bool IsPlayerExist(int clientIndex, bool aliveness = true)
{
    // If client isn't valid
    if(clientIndex <= 0 || clientIndex > MaxClients)
    {
        return false;
    }

    // If client isn't connected
    if(!IsClientConnected(clientIndex))
    {
        return false;
    }

    // If client isn't in game
    if(!IsClientInGame(clientIndex))
    {
        return false;
    }

    // If client isn't TV
    if(IsClientSourceTV(clientIndex))
    {
        return false;
    }

    // If client isn't alive
    if(aliveness && !IsPlayerAlive(clientIndex))
    {
        return false;
    }

    // If client exist
    return true;
}

/**
 * @brief Returns true if the player has a current weapon, false if not.
 *
 * @param clientIndex		The client index.
 * @param weaponName		The weapon name.
 *
 * @return					True or false.
 **/
stock bool IsPlayerHasWeapon(int clientIndex, char[] weaponName)
{
	// Initialize char
	char sClassname[SMALL_LINE_LENGTH];

	// Get number of all client weapons
	int iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
	
	// i = weapon number
	for (int i = 0; i < iSize; i++)
	{
		// Get weapon index
		int weaponIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hMyWeapons", i);
		
		// If entity isn't valid, then skip
		if(IsValidEdict(weaponIndex))
		{
			// Get weapon classname
			GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));
			
			// If weapon find, then return
			if(StrEqual(sClassname, weaponName, false))
			{
				return true;
			}
		}
		
		// Go to next weapon
		continue;
	}

	// If wasn't found
	return false;
}

/**
 * @brief Precache models and also adding them into the downloading table.
 * 
 * @param modelPath			The model path.
 *
 * @return					The model index.
 **/
stock int FakePrecacheModel(const char[] modelPath)
{
	// Precache main model
	int modelIndex = PrecacheModel(modelPath);
	
	// Adding main model to the download list
	AddFileToDownloadsTable(modelPath);

	// Initialize path char
	char fullPath[PLATFORM_MAX_PATH];
	char typePath[3][SMALL_LINE_LENGTH] = { ".dx90.vtx", ".phy", ".vvd" };
	
	// Get number of the all types
	int iSize = sizeof(typePath);
	
	// i = type index
	for(int i = 0; i < iSize; i++)
	{
		// Adding other parts to download list
		Format(fullPath, sizeof(fullPath), "%s", modelPath);
		ReplaceString(fullPath, sizeof(fullPath), ".mdl", typePath[i]);
		if(!FileExists(fullPath)) continue;
		AddFileToDownloadsTable(fullPath);
	}
	
	// Return model index
	return modelIndex;
}

/**
 * @brief Precache sounds and also adding them into the downloading table.
 * 
 * @param soundPath			The sound path. .
 **/
stock void FakePrecacheSound(const char[] soundPath)
{
	// Initialize path char
	char fullPath[PLATFORM_MAX_PATH];
	
	// Adding sound to the download list
	Format(fullPath, sizeof(fullPath), "sound/%s", soundPath);
	if(!FileExists(fullPath)) return;
	AddFileToDownloadsTable(fullPath);
	
	// Precache sound
	Format(fullPath, sizeof(fullPath), "*/%s", soundPath);
	AddToStringTable(FindStringTable("soundprecache"), fullPath);
}