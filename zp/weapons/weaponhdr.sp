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
	int view;
	
	if ((view = CreateEntityByName("predicted_viewmodel")) == -1)
	{
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons HDR", "Failed to create \"predicted_viewmodel\" entity");
		return view;
	}

	SetEntPropEnt(view, Prop_Send, "m_hOwner", client);
	SetEntProp(view, Prop_Send, "m_nViewModelIndex", 1);

	SetEntProp(view, Prop_Send, "m_bShouldIgnoreOffsetAndAccuracy", true);
	SetEntProp(view, Prop_Data, "m_bIsAutoaimTarget", false); /// toogle state

	DispatchSpawn(view);

	WeaponHDRSetPlayerViewModel(client, 1, view);
	
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
	int weapon1 = gClientData[client].CustomWeapon;

	int iSize = ToolsGetMyWeapons(client);
	for (int i = 0; i < iSize; i++)
	{
		int weapon2 = ToolsGetWeapon(client, i);
		
		if (weapon2 != -1 && weapon1 != weapon2)
		{
			return weapon2;
		}
	}
	
	weapon1 = WeaponsCreate(iD);

	if (weapon1 != -1)
	{
		WeaponsSetOwner(weapon1, client);
		ToolsSetOwner(weapon1, client);

		SetEntityMoveType(weapon1, MOVETYPE_NONE);

		SetVariantString("!activator");
		AcceptEntityInput(weapon1, "SetParent", client, weapon1);
	}

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
	int iModel;
	{
		ItemDef iItem = WeaponsGetDefIndex(iD);
		
		if (IsMelee(iItem)) 
		{
			iModel = ClassGetClawID(gClientData[client].Class);
		}
		else if (IsGrenade(iItem)) 
		{
			iModel = ClassGetGrenadeID(gClientData[client].Class);
		}
		
		if (!iModel) 
		{
			iModel = WeaponsGetModelViewID(iD);
		}
	}

	ParticlesStop(client, view2);

	if (WeaponsGetSequenceCount(iD) == -1)
	{
		int iSequenceCount = ToolsGetSequenceCount(weapon);

		if (iSequenceCount)
		{
			int iSequences[WEAPONS_SEQUENCE_MAX];

			if (iSequenceCount < WEAPONS_SEQUENCE_MAX)
			{
				WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon);
				
				WeaponsSetSequenceCount(iD, iSequenceCount);
				WeaponsSetSequenceSwap(iD, iSequences, iSequenceCount);
			}
			else
			{
				LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons HDR", "View model \"%d\" is having too many sequences! (Max %d, is %d) - Increase value of WEAPONS_SEQUENCE_MAX in plugin", iModel, WEAPONS_SEQUENCE_MAX, iSequenceCount);
			}
		}
		else
		{
			LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_Weapons, "Weapons HDR", "Failed to get sequence count for weapon using model \"%d\" - Animations may not work as expected", iModel);
		}
	}
	
	int iBody = ClassGetBody(gClientData[client].Class);
	int iSkin = ClassGetSkin(gClientData[client].Class);

	ToolsSetModelIndex(view2, iModel);
	ToolsSetTextures(view2, (iBody != -1) ? iBody : WeaponsGetModelBody(iD, ModelType_View), (iSkin != -1) ? iSkin : WeaponsGetModelSkin(iD, ModelType_View));
	
	WeaponHDRSetPlaybackRate(view2, WeaponHDRGetPlaybackRate(view1));

	WeaponHDRToggleViewModel(client, view2, iD);

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
	int weapon; bool toggle = view_as<bool>(GetEntProp(view, Prop_Data, "m_bIsAutoaimTarget"));

	if ((toggle = !toggle))
	{
		weapon = WeaponHDRGetSwappedWeapon(view);
		if (weapon == -1)
		{
			weapon = WeaponHDRCreateSwapWeapon(iD, client);
			
			WeaponHDRSetSwappedWeapon(view, weapon);
		}
	}
	else
	{
		weapon = gClientData[client].CustomWeapon;
	}

	SetEntPropEnt(view, Prop_Send, "m_hWeapon", weapon);
	
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

/**
 * @brief Gets the new sequence parity.
 *
 * @param entity            The entity index.
 * @return                  The new sequence parity.    
 **/
int WeaponHDRGetSequenceParity(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nNewSequenceParity");
}

/**
 * @brief Sets the sequence index.
 *
 * @param entity            The entity index.
 * @param flRate            The sequence index.  
 **/
void WeaponHDRSetSequence(int entity, int iSequence)
{
	SetEntProp(entity, Prop_Send, "m_nSequence", iSequence);
}

/**
 * @brief Gets the sequence index.
 *
 * @param entity            The entity index.
 * @return                  The sequence index.    
 **/
int WeaponHDRGetSequence(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_nSequence");
}

/**
 * @brief Sets the playback rate.
 *
 * @param entity            The entity index.
 * @param flRate            The playback rate.  
 **/
void WeaponHDRSetPlaybackRate(int entity, float flRate)
{
	SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", flRate);
}

/**
 * @brief Gets the playback rate.
 *
 * @param entity            The entity index.
 * @return                  The playback rate.    
 **/
float WeaponHDRGetPlaybackRate(int entity)
{
	return GetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate");
}

/**
 * @brief Sets the last sequence.
 *
 * @param entity            The entity index.
 * @param iSequence         The last sequence index.  
 **/
void WeaponHDRSetLastSequence(int entity, int iSequence)
{
	SetEntProp(entity, Prop_Data, "m_iHealth", iSequence);
}

/**
 * @brief Gets the last sequence.
 *
 * @param entity            The entity index.
 * @return                  The last sequence index.    
 **/
int WeaponHDRGetLastSequence(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iHealth");
}

/**
 * @brief Sets the last sequence parity.
 *
 * @param entity            The entity index.
 * @param iSequenceParity   The last sequence parity.  
 **/
void WeaponHDRSetLastSequenceParity(int entity, int iSequenceParity)
{
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", iSequenceParity);
}

/**
 * @brief Gets the last sequence parity.
 *
 * @param entity            The entity index.
 * @return                  The last sequence parity.    
 **/
int WeaponHDRGetLastSequenceParity(int entity)
{
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}

/**
 * @brief Sets the swapped weapon.
 *
 * @param entity            The entity index.
 * @param weapon            The weapon index.  
 **/
void WeaponHDRSetSwappedWeapon(int entity, int weapon)
{
	SetEntPropEnt(entity, Prop_Data, "m_hDamageFilter", weapon);
}

/**
 * @brief Gets the swapped weapon.
 *
 * @param entity            The entity index.
 * @return                  The weapon index.    
 **/
int WeaponHDRGetSwappedWeapon(int entity)
{
	return GetEntPropEnt(entity, Prop_Data, "m_hDamageFilter");
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
	int world = WeaponHDRGetPlayerWorldModel(weapon);

	if (world != -1)
	{
		int iModel = WeaponsGetModelWorldID(iD);

		ToolsSetModelIndex(world, iModel);
		
		if (iModel) 
		{
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
	if (WeaponsGetModelDropID(iD))
	{
		if (nModel == ModelType_Projectile)
		{
			static char sModel[PLATFORM_LINE_LENGTH];
			WeaponsGetModelDrop(iD, sModel, sizeof(sModel));
	
			SetEntityModel(weapon, sModel);
		
			ToolsSetTextures(weapon, WeaponsGetModelBody(iD, nModel), WeaponsGetModelSkin(iD, nModel));
		}
		else
		{
			UTIL_SetRenderColor(weapon, Color_Alpha, 0);
			
			if (WeaponHDRGetSwappedWeapon(weapon) == -1)
			{
				static float vPosition[3]; static float vAngle[3];

				ToolsGetAbsOrigin(weapon, vPosition); 
				ToolsGetAbsAngles(weapon, vAngle);
		
				static char sModel[PLATFORM_LINE_LENGTH];
				WeaponsGetModelDrop(iD, sModel, sizeof(sModel));

				int entity = UTIL_CreateDynamic("dropped", vPosition, vAngle, sModel);
				
				if (entity != -1)
				{
					ToolsSetTextures(entity, WeaponsGetModelBody(iD, nModel), WeaponsGetModelSkin(iD, nModel));

					SetVariantString("!activator");
					AcceptEntityInput(entity, "SetParent", weapon, entity);
					ToolsSetOwner(entity, weapon);
					
					WeaponHDRSetSwappedWeapon(weapon, entity);
					
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
	int weapon = ToolsGetOwner(entity);

	if (weapon != -1)
	{
		int owner = WeaponsGetOwner(weapon);
		if (IsPlayerExist(owner))
		{
			return Plugin_Handled;
		}
	}

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
	
	int iValue = iSequences[iIndex]; int iSwap = -1;

	if (!iValue)
	{
		if ((iValue = iSequences[iIndex] = ToolsGetSequenceActivity(weapon, iIndex)) == -1)
		{
			if (++iIndex < iSequenceCount)
			{
				WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon, iIndex);
				return -1;
			}
			
			return 0;
		}
	}
	else if (iValue == -1)
	{
		if (++iIndex < iSequenceCount)
		{
			WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon, iIndex);
			return -1;
		}
		return 0;
	}
	else if (iValue & SWAP_SEQ_PAIRED)
	{
		iSwap = (iValue & ~SWAP_SEQ_PAIRED) >> 16;

		iValue &= 0x0000FFFF;
	}
	else
	{
		return 0;
	}

	for (int i = iIndex + 1; i < iSequenceCount; i++)
	{
		int iNext = WeaponHDRBuildSwapSequenceArray(iSequences, iSequenceCount, weapon, i);

		if (iValue == iNext)
		{
			iSwap = i;

			iSequences[i] = iNext | (iIndex << 16) | SWAP_SEQ_PAIRED;
			break;
		}
	}
	
	iSequences[iIndex] = iSwap;
	
	return iValue;
}
