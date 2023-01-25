/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          weaponhdr.sp
 *  Type:          Module
 *  Description:   Weapon HDR models functions.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov), Andersso
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
 * @brief Creates the swapped (custom) weapon for the client.
 *
 * @param client            The cleint index.
 * @param view              The view index.
 * @param iD                The weapon id.
 **/
void WeaponHDRToggleViewModel(int client, int view, int iD)
{
	// Initialize index
	int weapon;

	// Resets toggle
	if ((gClientData[client].ToggleSequence = !gClientData[client].ToggleSequence))
	{
		// Gets swapped weapon index from the reference
		weapon = EntRefToEntIndex(gClientData[client].SwapWeapon);

		// Validate no weapon, then create a swaped pair 
		if (weapon == -1)
		{
			weapon = WeaponHDRCreateSwapWeapon(iD, client);
			gClientData[client].SwapWeapon = EntIndexToEntRef(weapon);
		}
	}
	else
	{
		// Gets weapon index from the reference
		weapon = gClientData[client].CustomWeapon;
	}

	// Sets a model for the weapon
	SetEntPropEnt(view, Prop_Send, "m_hWeapon", weapon);
}

/**
 * @brief Sets a swap weapon to a player.
 *
 * @param iD                The weapon id.
 * @param client            The client index.
 * @return                  The weapon index
 **/
int WeaponHDRCreateSwapWeapon(int iD, int client)
{
	// Gets weapon index from the reference
	int weapon1 = gClientData[client].CustomWeapon;

	// i = weapon number
	int iSize = ToolsGetMyWeapons(client);
	for (int i = 0; i < iSize; i++)
	{
		// Gets weapon index
		int weapon2 = ToolsGetWeapon(client, i);
		
		// Validate swapped weapon
		if (weapon2 != -1 && weapon1 != weapon2)
		{
			return weapon2;
		}
	}
	
	// Create a weapon entity
	weapon1 = WeaponsCreate(iD);

	// Validate weapon
	if (weapon1 != -1)
	{
		// Sets parent to the entity
		WeaponsSetOwner(weapon1, client);
		ToolsSetOwner(weapon1, client);

		// Remove an entity movetype
		SetEntityMoveType(weapon1, MOVETYPE_NONE);

		// Sets parent of a weapon
		SetVariantString("!activator");
		AcceptEntityInput(weapon1, "SetParent", client, weapon1);
	}

	// Return on success
	return weapon1;
}

/**
 * @brief Gets the view (player) weapon model.
 *
 * @param client            The cleint index.
 * @param view              The view index.
 * @return                  The model index.
 **/
int WeaponHDRGetPlayerViewModel(int client, int view)
{
	// Gets viewmodel of the client
	return GetEntDataEnt2(client, Player_ViewModel + (view * 4));
}

/**
 * @brief Sets the view (player) weapon model.
 *
 * @param client            The cleint index.
 * @param view              The view index.
 * @param iModel            The model index.
**/
void WeaponHDRSetPlayerViewModel(int client, int view, int iModel)
{
	// Sets viewmodel for the client
	SetEntDataEnt2(client, Player_ViewModel + (view * 4), iModel, true);
}

/**
 * @brief Gets the world (player) weapon model.
 *
 * @param weapon            The weapon index.
 **/
int WeaponHDRGetPlayerWorldModel(int weapon)
{ 
	// Gets worldmodel of the weapon
	return GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel");
}

/**
 * @brief Sets the world (player) weapon model.
 *
 * @param weapon            The weapon index.
 * @param iD                The weapon id.
 * @param nModel            (Optional) The model type.
 **/
void WeaponHDRSetPlayerWorldModel(int weapon, int iD, ModelType nModel = ModelType_Invalid)
{ 
	// Gets worldmodel entity
	int world = WeaponHDRGetPlayerWorldModel(weapon);

	// Validate worldmodel
	if (world != -1)
	{
		// Gets weapon worldmodel
		int iModel = WeaponsGetModelWorldID(iD);

		// Sets model index for the worldmodel
		ToolsSetModelIndex(world, iModel);
		
		// Validate model
		if (iModel) 
		{
			// Sets body/skin index for the worldmodel
			ToolsSetTextures(world, WeaponsGetModelBody(iD, nModel));
			SetEntProp(world, Prop_Data, "m_nSkin", WeaponsGetModelSkin(iD, nModel));
		}
	}                                                                                          
}

/**
 * @brief Sets the world (dropped/projectile) weapon model.
 *
 * @param weapon            The weapon index.
 * @param iD                The weapon id.
 * @param nModel            (Optional) The model type.
 **/
void WeaponHDRSetDroppedModel(int weapon, int iD, ModelType nModel = ModelType_Invalid)
{
	// If dropmodel exist, then apply it
	if (WeaponsGetModelDropID(iD))
	{
		// Validate projectile type
		if (nModel == ModelType_Projectile)
		{
			// Gets weapon dropmodel
			static char sModel[PLATFORM_LINE_LENGTH];
			WeaponsGetModelDrop(iD, sModel, sizeof(sModel));
	
			// Sets model for the weapon
			SetEntityModel(weapon, sModel);
		
			// Sets body/skin index for the weapon
			ToolsSetTextures(weapon, WeaponsGetModelBody(iD, nModel), WeaponsGetModelSkin(iD, nModel));
		}
		else
		{
			// Sets render mode
			UTIL_SetRenderColor(weapon, Color_Alpha, 0);
			
			// If dropped model wasn't created, then do
			if (GetEntPropEnt(weapon, Prop_Data, "m_hDamageFilter") == -1)
			{
				// Initialize vector variables
				static float vPosition[3]; static float vAngle[3];

				// Gets weapon position
				ToolsGetAbsOrigin(weapon, vPosition); 
				ToolsGetAbsAngles(weapon, vAngle);
		
				// Gets weapon dropmodel
				static char sModel[PLATFORM_LINE_LENGTH];
				WeaponsGetModelDrop(iD, sModel, sizeof(sModel));
		
				// Creates an attach weapon entity 
				int entity = UTIL_CreateDynamic("dropped", vPosition, vAngle, sModel);
				
				// If entity isn't valid, then skip
				if (entity != -1)
				{
					// Sets bodygroup/skin for the entity
					ToolsSetTextures(entity, WeaponsGetModelBody(iD, nModel), WeaponsGetModelSkin(iD, nModel));

					// Sets parent to the entity
					SetVariantString("!activator");
					AcceptEntityInput(entity, "SetParent", weapon, entity);
					ToolsSetOwner(entity, weapon);
					SetEntPropEnt(weapon, Prop_Data, "m_hDamageFilter", entity);
					
					// Hook entity callbacks
					SDKHook(entity, SDKHook_SetTransmit, WeaponHDROnDroppedTransmit);
				}
			}
		}
	}
}

/**
 * Hook: SetTransmit
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 **/
public Action WeaponHDROnDroppedTransmit(int entity, int client)
{
	// Gets weapon of the entity
	int weapon = ToolsGetOwner(entity);

	// Validate weapon
	if (weapon != -1)
	{
		// Validate owner
		int owner = WeaponsGetOwner(weapon);
		if (IsPlayerExist(owner))
		{
			// Block transmitting
			return Plugin_Handled;
		}
	}

	// Allow transmitting
	return Plugin_Continue;
}

/**
 * @brief Sets a visibility state of the weapon.
 *
 * @param weapon            The weapon index.
 * @param bInvisible        True or false.
 **/
void WeaponHDRSetWeaponVisibility(int weapon, bool bInvisible)
{
	int iFlags = ToolsGetEffect(weapon);
	ToolsSetEffect(weapon, bInvisible ? (iFlags & ~EF_NODRAW) : (iFlags | EF_NODRAW));
}

/**
 * @brief Generate a new sequence for the (any) custom viewmodels.
 * 
 * @author This algorithm made by 'Andersso'.
 *
 * @param iSequences        The sequence array.
 * @param iSequenceCount    The sequence count.
 * @param weapon            The weapon index.
 * @param iIndex            The sequence cell.
 * @return                  The sequence index.
 **/
int WeaponHDRBuildSwapSequenceArray(int iSequences[WEAPONS_SEQUENCE_MAX], int iSequenceCount, int weapon, int iIndex = 0)
{
	#define SWAP_SEQ_PAIRED (1<<31)
	
	// Initialize variables
	int iValue = iSequences[iIndex]; int iSwap = -1;

	// Validate empty sequence
	if (!iValue)
	{
		// Continue to next if sequence wasn't an activity
		if ((iValue = iSequences[iIndex] = ToolsGetSequenceActivity(weapon, iIndex)) == -1)
		{
			// Validate not a filled sequence
			if (++iIndex < iSequenceCount)
			{
				WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon, iIndex);
				return -1;
			}
			
			// Return on success
			return 0;
		}
	}
	// Shift a big
	else if (iValue == -1)
	{
		// Validate not a filled sequence
		if (++iIndex < iSequenceCount)
		{
			WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon, iIndex);
			return -1;
		}
		// Return on success
		return 0;
	}
	// Validate equality
	else if (iValue & SWAP_SEQ_PAIRED)
	{
		// Gets index
		iSwap = (iValue & ~SWAP_SEQ_PAIRED) >> 16;

		// Gets activity value
		iValue &= 0x0000FFFF;
	}
	else
	{
		// Return on success
		return 0;
	}

	// i = sequence index
	for (int i = iIndex + 1; i < iSequenceCount; i++)
	{
		// Find next sequence
		int iNext = WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon, i);

		// Validate cell
		if (iValue == iNext)
		{
			// Update
			iSwap = i;

			// Let the index be be stored after the 16th bit, and add a bit-flag to indicate this being done
			iSequences[i] = iNext | (iIndex << 16) | SWAP_SEQ_PAIRED;
			break;
		}
	}
	
	// Update the sequence array
	iSequences[iIndex] = iSwap;
	
	// Return the sequence cell
	return iValue;
}
