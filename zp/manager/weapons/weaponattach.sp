/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          weaponattach.sp
 *  Type:          Module
 *  Description:   Weapon attachments functions.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov), Mitchell
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
 * @section Number of valid addons.
 **/
enum BitType
{
	BitType_Invalid = -1,         /** Used as return value when an bit doens't exist. */
	
	BitType_PrimaryWeapon,        /** Primary bit */
	BitType_SecondaryWeapon,      /** Secondary bit */
	BitType_Flashbang1,           /** Flashbang1 bit */
	BitType_Flashbang2,           /** Flashbang2 bit */
	BitType_HEGrenade,            /** Hegrenade bit */
	BitType_SmokeGrenade,         /** Smokegrenade bit */
	BitType_Decoy,                /** Decoy bit */
	BitType_Knife,                /** Knife bit */
	BitType_TaGrenade,            /** Tagrenade bit */
	BitType_C4,                   /** C4 bit */
	BitType_DefuseKit,            /** Defuse bit */
	BitType_Shield                /** Shield bit */
};
/**
 * @endsection
 **/

/**
 * @brief Destroy weapon attachments.
 **/
void WeaponAttachOnUnload(/*void*/) 
{
	// i = client index
	for (int i = 1; i <= MaxClients; i++) 
	{
		// Validate client
		if (IsPlayerExist(i, false)) 
		{
			// Remove all addons
			WeaponAttachRemoveAddons(i);
		}
	}
}

/**
 * @brief Client has been changed class state. *(Post)
 *
 * @param client            The client index.
 **/
void WeaponAttachOnClientUpdate(int client)
{
	// Remove all addons
	WeaponAttachRemoveAddons(client);
}

/**
 * @brief Client has been spawned.
 *
 * @param client            The client index.
 **/
void WeaponAttachOnClientSpawn(int client)
{
	// Remove all addons
	WeaponAttachRemoveAddons(client);
}

/**
 * @brief Client has been killed.
 *
 * @param client            The client index.
 **/
void WeaponAttachOnClientDeath(int client)
{
	// Remove all addons
	WeaponAttachRemoveAddons(client);
}

/*
 * Stocks attachment API.
 */

/**
 * @brief Sets addons attachment.
 *
 * @param client            The client index.
 **/
void WeaponAttachSetAddons(int client)
{
	// Gets current bits
	int iBits = ToolsGetAddonBits(client); int iBitPurge; static int weapon; static int iD;
	
	/*____________________________________________________________________________________________*/
	
	// Validate primary bits
	if (iBits & CSAddon_PrimaryWeapon)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_PrimaryWeapon))
		{
			// Gets weapon index
			weapon = GetPlayerWeaponSlot(client, view_as<int>(SlotType_Primary));
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_PrimaryWeapon, "primary");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_PrimaryWeapon)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_PrimaryWeapon);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate secondary bits
	if (iBits & CSAddon_SecondaryWeapon)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_SecondaryWeapon))
		{
			// Gets weapon index
			weapon = GetPlayerWeaponSlot(client, view_as<int>(SlotType_Secondary));

			// Validate taser slot
			if (weapon == ToolsGetActiveWeapon(client))
			{
				// Gets weapon index
				weapon = WeaponsFindByName(client, "weapon_taser");
			}
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_SecondaryWeapon, "pistol");
				}
			}
		}
		}
	else if (gClientData[client].AttachmentBits & CSAddon_SecondaryWeapon)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_SecondaryWeapon);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate flashbang1 bits
	if (iBits & CSAddon_Flashbang1)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_Flashbang1))
		{
			// Gets weapon index
			weapon = WeaponsFindByName(client, "weapon_flashbang");
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_Flashbang1, "grenade0");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Flashbang1)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_Flashbang1);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate flashbang2 bits
	if (iBits & CSAddon_Flashbang2)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_Flashbang2))
		{
			// Gets weapon index
			weapon = WeaponsFindByName(client, "weapon_flashbang");
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_Flashbang2, "eholster");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Flashbang2)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_Flashbang2);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate hegrenade bits
	if (iBits & CSAddon_HEGrenade)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_HEGrenade))
		{
			// Gets weapon index
			weapon = WeaponsFindByName(client, "weapon_hegrenade");
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_HEGrenade, "grenade1");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_HEGrenade)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_HEGrenade);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate smokegrenade bits
	if (iBits & CSAddon_SmokeGrenade)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_SmokeGrenade))
		{
			// Gets weapon index
			weapon = WeaponsFindByName(client, "weapon_smokegrenade");
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_SmokeGrenade, "grenade2");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_SmokeGrenade)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_SmokeGrenade);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate decoy bits
	if (iBits & CSAddon_Decoy)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_Decoy))
		{
			// Gets weapon index
			weapon = WeaponsFindByName(client, "weapon_decoy");
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_Decoy, "grenade3");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Decoy)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_Decoy);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate knife bits
	if (iBits & CSAddon_Knife)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_Knife))
		{
			// Gets weapon index
			weapon = GetPlayerWeaponSlot(client, view_as<int>(SlotType_Melee));
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_Knife, "knife");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Knife)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_Knife);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate tagrenade bits
	if (iBits & CSAddon_TaGrenade)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_TaGrenade))
		{
			// Gets weapon index
			weapon = WeaponsFindByName(client, "weapon_tagrenade");
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_TaGrenade, "grenade4");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_TaGrenade)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_TaGrenade);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate c4 bits 
	if (iBits & CSAddon_C4)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_C4))
		{
			// Gets weapon index
			weapon = GetPlayerWeaponSlot(client, view_as<int>(SlotType_C4));
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_C4, "c4");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_C4)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_C4);
	}

	/*____________________________________________________________________________________________*/
	
	// Validate defuser bits 
	if (iBits & CSAddon_DefuseKit)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_DefuseKit))
		{
			// Validate defuser
			if (ToolsHasDefuser(client))
			{
				// Validate custom index
				iD = ToolsGetCustomID(client);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_DefuseKit, "c4");
				}
			}
		}
	}
	/*else if (gClientData[client].AttachmentBits & CSAddon_DefuseKit)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_DefuseKit);
	}*/
	
	/*____________________________________________________________________________________________*/
	
	// Validate shield bits 
	if (iBits & CSAddon_Shield)
	{
		// Gets client bits
		if (!(gClientData[client].AttachmentBits & CSAddon_Shield))
		{
			// Gets weapon index
			weapon = WeaponsFindByName(client, "weapon_shield");
			
			// Validate weapon
			if (weapon != -1)
			{
				// Validate custom index
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					// Create weapon addons
					WeaponAttachCreateAddons(client, iD, BitType_Shield, "c4");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Shield)
	{
		// Remove current addons
		WeaponAttachRemoveAddons(client, BitType_Shield);
	}
	
	/*____________________________________________________________________________________________*/
	
	// Validate addons
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_PrimaryWeapon]) != -1)
	{
		iBitPurge |= CSAddon_PrimaryWeapon;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_SecondaryWeapon]) != -1)
	{
		iBitPurge |= CSAddon_SecondaryWeapon;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_Flashbang1]) != -1)
	{
		iBitPurge |= CSAddon_Flashbang1;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_Flashbang2]) != -1)
	{
		iBitPurge |= CSAddon_Flashbang2;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_HEGrenade]) != -1)
	{
		iBitPurge |= CSAddon_HEGrenade;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_SmokeGrenade]) != -1)
	{
		iBitPurge |= CSAddon_SmokeGrenade;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_Decoy]) != -1)
	{
		iBitPurge |= CSAddon_Decoy;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_Knife]) != -1 || gClientData[client].Zombie)
	{
		iBitPurge |= CSAddon_Knife; iBitPurge |= CSAddon_Holster;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_TaGrenade]) != -1)
	{
		iBitPurge |= CSAddon_TaGrenade;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_C4]) != -1)
	{
		iBitPurge |= CSAddon_C4;
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_DefuseKit]) != -1)
	{
		iBitPurge |= CSAddon_DefuseKit; if (!ToolsHasDefuser(client)) WeaponAttachRemoveAddons(client, BitType_DefuseKit);
	}
	if (EntRefToEntIndex(gClientData[client].AttachmentAddons[BitType_Shield]) != -1)
	{
		iBitPurge |= CSAddon_Shield;
	}
	
	// Store the bits for next usage
	gClientData[client].AttachmentBits = iBits;
	ToolsSetAddonBits(client, iBits &~ iBitPurge);
}

/**
 * @brief Create an attachment addons entities for the client.
 *
 * @param client            The client index.
 * @param iD                The weapon id.
 * @param mBits             The bits type.
 * @param sAttach           The attachment name.
 **/
void WeaponAttachCreateAddons(int client, int iD, BitType mBits, char[] sAttach)
{
	// Remove current addons
	WeaponAttachRemoveAddons(client, mBits);

	// If dropmodel exist, then apply it
	if (WeaponsGetModelDropID(iD))
	{
		// Validate attachment
		if (ToolsLookupAttachment(client, sAttach))
		{
			// Gets weapon dropmodel
			static char sModel[PLATFORM_LINE_LENGTH];
			WeaponsGetModelDrop(iD, sModel, sizeof(sModel)); 
	
			// Create an attach addon entity 
			int entity = UTIL_CreateDynamic("backpack", NULL_VECTOR, NULL_VECTOR, sModel);
			
			// If entity isn't valid, then skip
			if (entity != -1)
			{
				// Sets bodygroup/skin for the entity
				ToolsSetTextures(entity, WeaponsGetModelBody(iD, ModelType_Drop), WeaponsGetModelSkin(iD, ModelType_Drop)); 

				// Sets parent to the entity
				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client, entity);
				ToolsSetOwner(entity, client);
				
				// Sets attachment to the entity
				SetVariantString(sAttach);
				AcceptEntityInput(entity, "SetParentAttachment", client, entity);
				
				// Hook entity callbacks
				SDKHook(entity, SDKHook_SetTransmit, ToolsOnEntityTransmit);
				
				// Store the client cache
				gClientData[client].AttachmentAddons[mBits] = EntIndexToEntRef(entity);
			}
		}
	}
}

/**
 * @brief Remove an attachment addons entities from the client.
 *
 * @param client            The client index.
 * @param mBits             The bits type.
 **/
void WeaponAttachRemoveAddons(int client, BitType mBits = BitType_Invalid) 
{
	// Validate all
	if (mBits == BitType_Invalid)
	{
		// i = slot index
		for (BitType i = BitType_PrimaryWeapon; i <= BitType_Shield; i++)
		{
			// Gets current addon from the client reference
			int entity = EntRefToEntIndex(gClientData[client].AttachmentAddons[i]);
	
			// Validate addon
			if (entity != -1) 
			{
				AcceptEntityInput(entity, "Kill");
			}

			// Clear the client cache
			gClientData[client].AttachmentBits = CSAddon_NONE;
			gClientData[client].AttachmentAddons[i] = -1;
		}
	}
	else
	{
		// Gets current addon from the client reference
		int entity = EntRefToEntIndex(gClientData[client].AttachmentAddons[mBits]);

		// Validate addon
		if (entity != -1) 
		{
			AcceptEntityInput(entity, "Kill");
		}

		// Clear the client cache
		gClientData[client].AttachmentBits = CSAddon_NONE;
		gClientData[client].AttachmentAddons[mBits] = -1;
	}
}
