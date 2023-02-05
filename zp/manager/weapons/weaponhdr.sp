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
 * @brief Creates the secondary viewmodel for the client.
 *
 * @param client            The client index.
 * @return                  The view index
 **/
int WeaponHDRCreateViewModel(int client)
{
	// Initialize index
	int view;
	
	// Validate entity
	if ((view = CreateEntityByName("predicted_viewmodel")) == -1)
	{
		// Unexpected error, log it
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons HDR", "Failed to create \"predicted_viewmodel\" entity");
		return view;
	}

	// Sets owner to the entity
	SetEntPropEnt(view, Prop_Send, "m_hOwner", client);
	SetEntProp(view, Prop_Send, "m_nViewModelIndex", 1);

	// Remove accuracity
	SetEntProp(view, Prop_Send, "m_bShouldIgnoreOffsetAndAccuracy", true);
	SetEntProp(view, Prop_Data, "m_bIsAutoaimTarget", false); /// toogle state

	// Spawn the entity into the world
	DispatchSpawn(view);

	// Sets viewmodel to the owner
	WeaponHDRSetPlayerViewModel(client, 1, view);
	
	// Return on success
	return view;
}

/**
 * @brief Creates the swapped weapon for the client.
 *
 * @param iD                The weapon id.
 * @param client            The client index.
 * @return                  The weapon index
 **/
int WeaponHDRCreateSwapWeapon(int iD, int client)
{
	// Gets weapon index
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
 * @brief Swaps the weapon view models for the client.
 *
 * @param client            The cleint index.
 * @param view1             The view index.
 * @param view2             The view index.
 * @param iD                The weapon id.
 **/
void WeaponHDRSwapViewModel(int client, int weapon, int view1, int view2, int iD)
{
	// Initialize variables
	int iModel;
	{
		// Gets weapon def index
		ItemDef iItem = WeaponsGetDefIndex(iD);
		
		// Validate melee
		if (IsMelee(iItem)) 
		{
			iModel = ClassGetClawID(gClientData[client].Class);
		}
		// Validate grenade
		else if (IsGrenade(iItem)) 
		{
			iModel = ClassGetGrenadeID(gClientData[client].Class);
		}
		
		// If class models missing use weapon model
		if (!iModel) iModel = WeaponsGetModelViewID(iD);
	}

	// Stops effects before showing viewmodel
	ParticlesStop(client, view2);

	// If the sequence for the weapon didn't build yet
	if (WeaponsGetSequenceCount(iD) == -1)
	{
		// Gets sequence amount from a weapon entity
		int iSequenceCount = ToolsGetSequenceCount(weapon);

		// Validate count
		if (iSequenceCount)
		{
			// Initialize the sequence array
			int iSequences[WEAPONS_SEQUENCE_MAX];

			// Validate amount
			if (iSequenceCount < WEAPONS_SEQUENCE_MAX)
			{
				// Build the sequence array
				WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon);
				
				// Update the sequence array
				WeaponsSetSequenceCount(iD, iSequenceCount);
				WeaponsSetSequenceSwap(iD, iSequences, sizeof(iSequences));
			}
			else
			{
				// Unexpected error, log it
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons HDR", "View model \"%s\" is having too many sequences! (Max %d, is %d) - Increase value of WEAPONS_SEQUENCE_MAX in plugin", "@TODO@", WEAPONS_SEQUENCE_MAX, iSequenceCount);
			}
		}
		else
		{
			// Remove swapped weapon
			WeaponsClearSequenceSwap(iD);
			
			// Unexpected error, log it
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons HDR", "Failed to get sequence count for weapon using model \"%s\" - Animations may not work as expected", "@TODO@");
		}
	}
	
	// Gets body/skin index of a class
	int iBody = ClassGetBody(gClientData[client].Class);
	int iSkin = ClassGetSkin(gClientData[client].Class);

	// Sets model/body/skin index for viewmodel
	ToolsSetModelIndex(view2, iModel);
	ToolsSetTextures(view2, (iBody != -1) ? iBody : WeaponsGetModelBody(iD, ModelType_View), (iSkin != -1) ? iSkin : WeaponsGetModelSkin(iD, ModelType_View));
	
	// Update the animation interval delay for second viewmodel 
	WeaponHDRSetPlaybackRate(view2, WeaponHDRGetPlaybackRate(view1));

	// Toggles a viewmodel model
	WeaponHDRToggleViewModel(client, view2, iD);

	// Resets the sequence parity
	WeaponHDRSetLastSequence(view1, -1);
	WeaponHDRSetLastSequenceParity(view1, -1);
}

/**
 * @brief Toggles a view model.  
 *
 * @param client            The cleint index.
 * @param view              The view index.
 * @param iD                The weapon id.
 **/
void WeaponHDRToggleViewModel(int client, int view, int iD)
{
	// Initialize variables
	int weapon; bool toggle = view_as<bool>(GetEntProp(view, Prop_Data, "m_bIsAutoaimTarget"));

	// Perform toggle
	if ((toggle = !toggle))
	{
		// Validate no weapon
		weapon = WeaponHDRGetSwappedWeapon(view);
		if (weapon == -1)
		{
			// Create a swaped pair 
			weapon = WeaponHDRCreateSwapWeapon(iD, client);
			
			// Store swapped weapon
			WeaponHDRSetSwappedWeapon(view, weapon);
		}
	}
	else
	{
		// Gets weapon index
		weapon = gClientData[client].CustomWeapon;
	}

	// Sets a model for the weapon
	SetEntPropEnt(view, Prop_Send, "m_hWeapon", weapon);
	
	// Sets a current toggle state
	SetEntProp(view, Prop_Data, "m_bIsAutoaimTarget", toggle);
}

/**
 * @brief Sets a visibility state of an entity.
 *
 * @param entity            The entity index.
 * @param bVisible          True or false.
 **/
void WeaponHDRSetVisibility(int entity, bool bVisible)
{
	int iFlags = ToolsGetEffect(entity);
	ToolsSetEffect(entity, bVisible ? (iFlags & ~EF_NODRAW) : (iFlags | EF_NODRAW));
}

int WeaponHDRGetSequenceParity(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nNewSequenceParity");
}

void WeaponHDRSetSequence(int entity, int iSequence)
{
	SetEntProp(entity, Prop_Send, "m_nSequence", iSequence);
}

int WeaponHDRGetSequence(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nSequence");
}

void WeaponHDRSetPlaybackRate(int entity, float flRate)
{
	SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", flRate);
}

float WeaponHDRGetPlaybackRate(int entity)
{
	return GetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate");
}

void WeaponHDRSetLastSequence(int entity, int iSequence)
{
	SetEntProp(entity, Prop_Data, "m_iHealth", iSequence);
}

int WeaponHDRGetLastSequence(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHealth");
}

void WeaponHDRSetLastSequenceParity(int entity, int iSequenceParity)
{
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", iSequenceParity);
}

int WeaponHDRGetLastSequenceParity(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}

void WeaponHDRSetSwappedWeapon(int entity, int weapon)
{
	SetEntPropEnt(entity, Prop_Data, "m_hDamageFilter", weapon);
}

int WeaponHDRGetSwappedWeapon(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hDamageFilter");
}

void WeaponHDRSetHolsteredViewModel(int entity, int iModel)
{
	SetEntProp(entity, Prop_Data, "m_iHammerID", iModel);
}

int WeaponHDRGetHolsteredViewModel(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHammerID");
}

/**
 * @brief Gets the view (player) weapon model.
 *
 * @param client            The cleint index.
 * @param iView             The iView index.
 * @return                  The model index.
 **/
int WeaponHDRGetPlayerViewModel(int client, int iView)
{
	// Gets viewmodel of the client
	return GetEntDataEnt2(client, Player_ViewModel + (iView * 4));
}

/**
 * @brief Sets the view (player) weapon model.
 *
 * @param client            The cleint index.
 * @param iView             The view index.
 * @param iModel            The model index.
**/
void WeaponHDRSetPlayerViewModel(int client, int iView, int iModel)
{
	SetEntDataEnt2(client, Player_ViewModel + (iView * 4), iModel, true);
}

/**
 * @brief Gets the world (player) weapon model.
 *
 * @param weapon            The weapon index.
 **/
int WeaponHDRGetPlayerWorldModel(int weapon)
{ 
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
			/// CBaseWeaponWorldModel missing m_nSkin in Prop_Send
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
			if (WeaponHDRGetSwappedWeapon(weapon) == -1)
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
					
					// Store as swapped weapon
					WeaponHDRSetSwappedWeapon(weapon, entity);
					
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
