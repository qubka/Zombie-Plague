/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          damage.cpp
 *  Type:          Game 
 *  Description:   Modify damage values here.
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
 * @section Damage flags.
 **/
#define DMG_CSGO_FALL        (DMG_FALL)      /** Client was damaged by falling.	 **/
#define DMG_CSGO_BLAST       (DMG_BLAST)     /** Client was damaged by explosion.**/
#define DMG_CSGO_BURN        (DMG_BURN)    	 /** Client was damaged by inferno.	 **/
#define DMG_CSGO_FIRE        (DMG_DIRECT)    /** Client was damaged by fire.	 **/
#define DMG_CSGO_BULLET      (DMG_NEVERGIB)  /** Client was shot or knifed. 	 **/
#define DMG_CSGO_DROWN    	 (DMG_DROWN)     /** Client was damaged by water. 	 **/
/**
 * @endsection
 **/
 
/**
 * @section Water levels.
 **/
#define WLEVEL_CSGO_DRY  0
#define WLEVEL_CSGO_FEET 1
#define WLEVEL_CSGO_HALF 2
#define WLEVEL_CSGO_FULL 3
/**
 * @endsection
 **/

/**
 * Client is joining the server.
 * 
 * @param client    The client index.  
 */
void DamageClientInit(int clientIndex)
{
	// Hook damage callbacks
	SDKHook(clientIndex, SDKHook_TraceAttack, DamageOnTraceAttack);
	SDKHook(clientIndex, SDKHook_OnTakeDamage, DamageOnTakeDamage);
}
 
/**
 * Hook: OnTraceAttack
 * Called right before the bullet enters a client.
 * 
 * @param victimIndex		The victim index.
 * @param attackerIndex		The attacker index.
 * @param inflicterIndex	The inflictor index.
 * @param damageAmount		The amount of damage inflicted.
 * @param damageBits		The type of damage inflicted.
 * @param ammoType			The ammo type of the attacker's weapon.
 * @param hitroupBox		The hitbox index.  
 * @param hitgroupIndex		The hitgroup index.  
 **/
public Action DamageOnTraceAttack(int victimIndex, int &attackerIndex, int &inflicterIndex, float &damageAmount, int &damageBits, int &ammoType, int hitroupBox, int hitgroupIndex)
{
	// If gamemodes enable, then validate state
	if(GetConVarInt(gCvarList[CVAR_GAME_CUSTOM_START]))
	{
		// If mode doesn't started yet, then stop trace
		if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
		{
			// Stop trace
			return ACTION_HANDLED;
		}
	}
	
	// Get real player index from event key 
	CBasePlayer* cBaseVictim = CBasePlayer(victimIndex);
	CBasePlayer* cBaseAttacker = CBasePlayer(attackerIndex);
	
	// Verify that the clients are exists
	if(!IsPlayerExist(cBaseAttacker->Index) || !IsPlayerExist(cBaseVictim->Index))
	{
		// Stop trace
		return ACTION_HANDLED;
	}

	// If clients have same class, then stop trace
	if(cBaseVictim->m_bZombie == cBaseAttacker->m_bZombie || !cBaseVictim->m_bZombie == !cBaseAttacker->m_bZombie)
	{
		// Stop trace
		return ACTION_HANDLED;
	}

	// Allow trace
	return ACTION_CONTINUE;
}
 
/**
 * Hook: OnTakeDamage
 * Called right before damage is done.
 * 
 * @param victimIndex		The victim index.
 * @param attackerIndex		The attacker index.
 * @param inflicterIndex	The inflicter index.
 * @param damageAmount		The amount of damage inflicted.
 * @param damageBits		The type of damage inflicted.
 **/
public Action DamageOnTakeDamage(int victimIndex, int &attackerIndex, int &inflicterIndex, float &damageAmount, int &damageBits)
{
	//*********************************************************************
	//*                   VALIDATION OF THE INFLICTOR           		  *
	//*********************************************************************
	
	// If inflicter isn't valid, then skip
	if(IsValidEdict(inflicterIndex))
	{
		// Get classname of the inflictor
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(inflicterIndex, sClassname, sizeof(sClassname));

		// If entity is a trigger, then allow damage (Map is damaging client)
		if(StrContains(sClassname, "trigger") > -1)
		{
			// Allow damage
			return ACTION_CONTINUE;
		}
	}
	
	//*********************************************************************
	//*                     VALIDATION OF THE PLAYER           		  	  *
	//*********************************************************************
	
	// If gamemodes disabled, then skip
	if(!GetConVarInt(gCvarList[CVAR_GAME_CUSTOM_START]))
	{
		// Allow damage
		return ACTION_CONTINUE;
	}
	
	// If mode doesn't started yet, then stop
	if(gServerData[Server_RoundNew] || gServerData[Server_RoundEnd])
	{
		// Block damage
		return ACTION_HANDLED;
	}

	// If client is attacking himself, then stop
	if(victimIndex == attackerIndex)
	{
		// Block damage
		return ACTION_HANDLED;
	}
	
	// Get real player index from event key 
	CBasePlayer* cBaseVictim = CBasePlayer(victimIndex);

	// Verify that the victim is exist
	if(!IsPlayerExist(cBaseVictim->Index))
	{
		// Block damage
		return ACTION_HANDLED;
	}
	
	//*********************************************************************
	//*                    APPLY DAMAGE TO THE PLAYER           		  *
	//*********************************************************************
	
	// Client was damaged by 'fire' or 'burn
	if(damageBits & DMG_CSGO_BURN || damageBits & DMG_CSGO_FIRE)
	{
		// Verify that the victim is zombie
		if(cBaseVictim->m_bZombie)
		{
			// If the victim is in the water or freezed
			if(cBaseVictim->m_bDrown(WLEVEL_CSGO_FEET) || cBaseVictim->m_iMoveType == MOVETYPE_NONE)
			{
				// Extinguishes the victim that is on fire
				VEffectExtinguishEntity(cBaseVictim->Index);
			}
			else
			{
				// Put the fire on
				if(damageBits & DMG_CSGO_BURN) VEffectIgniteEntity(cBaseVictim->Index , GetConVarFloat(gCvarList[CVAR_GRENADE_IGNITTING]));
				
				// Emit burn sound
				if(GetRandomInt(0, 1)) cBaseVictim->InputEmitAISound(SNDCHAN_BODY, SNDLEVEL_NORMAL, (ZombieIsFemale(cBaseVictim->m_nZombieClass)) ? "ZOMBIE_FEMALE_BURN_SOUNDS" : "ZOMBIE_BURN_SOUNDS");

				// Return damage multiplier
				damageAmount *= GetConVarFloat(gCvarList[CVAR_GRENADE_DAMAGE_MOLOTOV]);
				
				// Change damage
				return ACTION_CHANGED;
			}
		}
		
		// Block damage
		return ACTION_HANDLED;
	}
	
	//###########################################################################
	
	// Client was damaged by 'falling' or 'drowning'
	else if(damageBits & DMG_CSGO_FALL || damageBits & DMG_CSGO_DROWN)
	{
		// Block damage for zombie 
		return cBaseVictim->m_bZombie ? ACTION_HANDLED : ACTION_CONTINUE;
	}
	
	//###########################################################################
	
	// Client was damaged by 'explosion'
	else if(damageBits & DMG_CSGO_BLAST)
	{
		// Set explosion damage
		damageAmount *= cBaseVictim->m_bZombie ? GetConVarFloat(gCvarList[CVAR_GRENADE_DAMAGE_HEGRENADE]) : 0.0;
	}
	
	//###########################################################################
	
	// Client was damaged by 'bullet'
	else if(damageBits & DMG_CSGO_BULLET)
	{
		// Get real player index from event key 
		CBasePlayer* cBaseAttacker = CBasePlayer(attackerIndex);
	
		// Verify that the attacker is exist
		if(!IsPlayerExist(cBaseAttacker->Index))
		{
			// Block damage
			return ACTION_HANDLED;
		}
		
		// Verify that the attacker is zombie 
		if(cBaseAttacker->m_bZombie)
		{
			// If victim is zombies, then stop
			if(cBaseVictim->m_bZombie)
			{
				// Block damage
				return ACTION_HANDLED;
			}
			
			// Emit human hurt sound
			cBaseVictim->InputEmitAISound(SNDCHAN_BODY, SNDLEVEL_NORMAL, cBaseVictim->m_bSurvivor ? "HUMAN_SURVIVOR_HURT_SOUNDS" : ((HumanIsFemale(cBaseVictim->m_nHumanClass)) ? "HUMAN_FEMALE_HURT_SOUNDS" : "HUMAN_HURT_SOUNDS"));
			
			// If the normal gamemode, then infect humans
			if(GameModesValidateInfection(gServerData[Server_RoundMode]))
			{
				// Infect victim
				return DamageOnClientInfect(cBaseVictim, cBaseAttacker, damageAmount);
			}

			// If not, then apply multiplier
			else
			{
				//!! IMPORTANT BUG FIX !!/
				// Disable flash light before receive damage ~ Player.FlashlightOff
				cBaseVictim->m_bFlashLightOn(false);  
				
				// Calculate zombie damage
				damageAmount = cBaseAttacker->m_bNemesis ? GetConVarFloat(gCvarList[CVAR_NEMESIS_DAMAGE]) : damageAmount;
			}
		}
		
		// Verify that the attacker is human 
		else
		{
			// If the zombie is frozen, then stop
			if(cBaseVictim->m_iMoveType == MOVETYPE_NONE)
			{
				// Block damage
				return ACTION_HANDLED;
			}
			
			// Emit zombie hurt sound
			cBaseVictim->InputEmitAISound(SNDCHAN_BODY, SNDLEVEL_NORMAL, cBaseVictim->m_bNemesis ? "ZOMBIE_NEMESIS_HURT_SOUNDS" : ((ZombieIsFemale(cBaseVictim->m_nZombieClass)) ? "ZOMBIE_FEMALE_HURT_SOUNDS" : "ZOMBIE_HURT_SOUNDS"));

			// Initialize zombie knockback multiplier
			float knockbackAmount = ZombieGetKnockBack(cBaseVictim->m_nZombieClass);
			
			// Verify that the attacker is survivor
			if(cBaseAttacker->m_bSurvivor)
			{
				damageAmount *= GetConVarFloat(gCvarList[CVAR_SURVIVOR_DAMAGE]);
			}
			
			// Verify that the attacker is human
			else
			{
				// Apply level's damage multiplier
				if(GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]))
				{
					damageAmount *= float(cBaseAttacker->m_iLevel) * GetConVarFloat(gCvarList[CVAR_LEVEL_DAMAGE_RATIO]);
				}
				
				// Apply weapon damage and knockback multiplier by client's active weapon
				int iIndex = WeaponsGetWeaponIndex(cBaseAttacker->m_iActiveWeapon);
				if(iIndex != -1)
				{
					damageAmount *= WeaponsGetDamage(iIndex);
					knockbackAmount *= WeaponsGetKnockBack(iIndex);
				}
			}

			// Apply knockback
			DamageOnClientKnockBack(cBaseVictim, cBaseAttacker, damageAmount * knockbackAmount);
		}

		// Give rewards for applied damage
		DamageOnClientAmmo(cBaseAttacker, damageAmount);
		DamageOnClientExp(cBaseAttacker, damageAmount);
		
		// Call forward
		API_OnClientDamaged(cBaseVictim->Index, cBaseAttacker->Index, damageAmount);
	}
	
	//###########################################################################

	
	// Apply fake damage
	return DamageOnClientFakeDamage(cBaseVictim, damageAmount);
}

/*
 * Other main functions
 */

/**
 * Damage without pain shock.
 *
 * @param cBasePlayer		The client index.
 * @param damageAmount		The amount of damage inflicted. 
 **/
stock Action DamageOnClientFakeDamage(CBasePlayer* cBasePlayer, float damageAmount)
{
	// Get health
	int healthAmount = cBasePlayer->m_iHealth;
	
	// Verify that the victim has a health
	if(healthAmount)
	{
		// Count the damage
		healthAmount -= RoundFloat(damageAmount);
		
		// If amount of damage to high, then stop
		if(healthAmount <= 0)
		{
			// Allow damage
			return ACTION_CHANGED;
		}
		else
		{
			// Set applied damage
			cBasePlayer->m_iHealth = healthAmount;
			
			// Block damage
			return ACTION_HANDLED;
		}
	}
	else
	{
		// Allow damage
		return ACTION_CHANGED;
	}
}

/**
 * Reducing armor and infect the victim.
 *
 * @param cBaseVictim		The victim index.
 * @param cBaseAttacker		The attacker index.
 * @param damageAmount		The amount of damage inflicted. 
 **/
stock Action DamageOnClientInfect(CBasePlayer* cBaseVictim, CBasePlayer* cBaseAttacker, float damageAmount)
{
	// Last human need to be killed ?
	if(!GetConVarBool(gCvarList[CVAR_HUMAN_LAST_INFECTION]) && fnGetHumans() <= 1)
	{
		// Allow damage
		return ACTION_CONTINUE;
	}
	
	// Human armor need to be reduced before infecting ?
	if(GetConVarBool(gCvarList[CVAR_HUMAN_ARMOR_PROTECT]))
	{
		// Get armor
		int armorAmount = cBaseVictim->m_iArmorValue;

		// Verify that the victim has an armor
		if(armorAmount)
		{
			// Count the damage
			armorAmount -= RoundFloat(damageAmount);
			
			// Set a new armor amount
			cBaseVictim->m_iArmorValue = (armorAmount < 0) ? 0 : armorAmount;
			
			// Block infection
			return ACTION_HANDLED;
		}
	}

	// Make a zombie
	InfectHumanToZombie(cBaseVictim, cBaseAttacker);

	// Block damage
	return ACTION_HANDLED;
}

/** 
 * Set velocity knockback for applied damage.
 *
 * @param cBaseVictim		The client index.
 * @param cBaseAttacker		The attacker index.
 * @param knockbackAmount	The knockback multiplier.
 **/
stock void DamageOnClientKnockBack(CBasePlayer* cBaseVictim, CBasePlayer* cBaseAttacker, float knockbackAmount)
{
	// If nemesis knockback disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_NEMESIS_KNOCKBACK]) && cBaseVictim->m_bNemesis)
	{
		return;
	}
	
	// Initialize vectors
	float flClientLoc[3];
	float flEyeAngle[3];
	float flAttackerLoc[3];
	float flVector[3];
	
	// Get victim's and attacker's position
	cBaseVictim->m_flGetOrigin(flClientLoc);
	cBaseAttacker->m_flGetEyeAngles(flEyeAngle);
	cBaseAttacker->m_flGetEyePosition(flAttackerLoc);

	// Calculate knockback end-vector
	TR_TraceRayFilter(flAttackerLoc, flEyeAngle, MASK_ALL, RayType_Infinite, FilterPlayers);
	TR_GetEndPosition(flClientLoc);
	
	// Get vector from the given starting and ending points
	MakeVectorFromPoints(flAttackerLoc, flClientLoc, flVector);
	
	// Normalize the vector (equal magnitude at varying distances)
	NormalizeVector(flVector, flVector);

	// Apply the magnitude by scaling the vector
	ScaleVector(flVector, knockbackAmount);

	// Push the player
	cBaseVictim->m_iTeleportPlayer(NULL_VECTOR, NULL_VECTOR, flVector);
}

/**
 * Reward ammopacks for applied damage.
 *
 * @param cBasePlayer		The client index.
 * @param damageAmount		The amount of damage inflicted. 
 **/
stock void DamageOnClientAmmo(CBasePlayer* cBasePlayer, float damageAmount)
{
	// Initialize client applied damage
	static int AppliedDamage[MAXPLAYERS+1];
	
	// Increment total damage
	AppliedDamage[cBasePlayer->Index] += RoundFloat(damageAmount);
	
	// Counting bonuses
	int nBonus = cBasePlayer->m_bZombie ? GetConVarInt(gCvarList[CVAR_BONUS_DAMAGE_ZOMBIE]) : cBasePlayer->m_bSurvivor ? GetConVarInt(gCvarList[CVAR_BONUS_DAMAGE_SURVIVOR]) : GetConVarInt(gCvarList[CVAR_BONUS_DAMAGE_HUMAN]);

	// Validate bonus
	if(!nBonus)
	{
		return;
	}
	
	// Computing multiplier
	int nMultipler = AppliedDamage[cBasePlayer->Index] / nBonus;
	
	// Validate multiplier
	if(!nMultipler) 
	{
		return;
	}
	
	// Give ammopacks for the attacker
	cBasePlayer->m_nAmmoPacks += nMultipler;
	
	// Reset damage filter
	AppliedDamage[cBasePlayer->Index] -= nMultipler * nBonus;
}

/**
 * Reward experience for applied damage.
 *
 * @param cBasePlayer		The client index.
 * @param damageAmount		The amount of damage inflicted. 
 **/
stock void DamageOnClientExp(CBasePlayer* cBasePlayer, float damageAmount)
{
	// If level system disabled, then stop
	if(!GetConVarBool(gCvarList[CVAR_LEVEL_SYSTEM]))
	{
		return;
	}
	
	// Initialize client applied damage
	static int AppliedDamage[MAXPLAYERS+1];
	
	// Increment total damage
	AppliedDamage[cBasePlayer->Index] += RoundFloat(damageAmount);
	
	// Counting bonuses
	int nBonus = cBasePlayer->m_bZombie ? GetConVarInt(gCvarList[CVAR_LEVEL_DAMAGE_ZOMBIE]) : cBasePlayer->m_bSurvivor ? GetConVarInt(gCvarList[CVAR_LEVEL_DAMAGE_SURVIVOR]) : GetConVarInt(gCvarList[CVAR_LEVEL_DAMAGE_HUMAN]);

	// Validate bonus
	if(!nBonus)
	{
		return;
	}
	
	// Computing multiplier
	int nMultipler = AppliedDamage[cBasePlayer->Index] / nBonus;
	
	// Validate multiplier
	if(!nMultipler) 
	{
		return;
	}
	
	// Give experience for the attacker
	cBasePlayer->m_iExp += nMultipler;
	
	// Reset damage filter
	AppliedDamage[cBasePlayer->Index] -= nMultipler * nBonus;
}

/*
 * Trace filtering functions
 */
 
/**
 * Trace filter.
 *  
 * @param nEntity			The entity index.
 * @param contentsMask		The contents mask.
 *
 * @return					True or false.
 **/
public bool FilterPlayers(int nEntity, int contentsMask)
{
	// If entity is a player, continue tracing
	return !(1 <= nEntity <= MaxClients);
}