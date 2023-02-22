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
void WeaponAttachOnUnload() 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i, false)) 
		{
			WeaponAttachRemoveAddons(i);
		}
	}
}

/**
 * @brief Client has been changed class state. *(Next frame)
 *
 * @param client            The client index.
 **/
void WeaponAttachOnClientUpdate(int client)
{
	WeaponAttachRemoveAddons(client);
}

/**
 * @brief Client has been spawned.
 *
 * @param client            The client index.
 **/
void WeaponAttachOnClientSpawn(int client)
{
	WeaponAttachRemoveAddons(client);
}

/**
 * @brief Client has been killed.
 *
 * @param client            The client index.
 **/
void WeaponAttachOnClientDeath(int client)
{
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
	int iBits = ToolsGetAddonBits(client); int iBitPurge; static int weapon; static int iD;
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_PrimaryWeapon)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_PrimaryWeapon))
		{
			weapon = GetPlayerWeaponSlot(client, SlotIndex_Primary);
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_PrimaryWeapon, "primary");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_PrimaryWeapon)
	{
		WeaponAttachRemoveAddons(client, BitType_PrimaryWeapon);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_SecondaryWeapon)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_SecondaryWeapon))
		{
			weapon = GetPlayerWeaponSlot(client, SlotIndex_Secondary);

			if (weapon == ToolsGetActiveWeapon(client))
			{
				weapon = WeaponsFindByName(client, "weapon_taser");
			}
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_SecondaryWeapon, "pistol");
				}
			}
		}
		}
	else if (gClientData[client].AttachmentBits & CSAddon_SecondaryWeapon)
	{
		WeaponAttachRemoveAddons(client, BitType_SecondaryWeapon);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_Flashbang1)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_Flashbang1))
		{
			weapon = WeaponsFindByName(client, "weapon_flashbang");
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_Flashbang1, "grenade0");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Flashbang1)
	{
		WeaponAttachRemoveAddons(client, BitType_Flashbang1);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_Flashbang2)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_Flashbang2))
		{
			weapon = WeaponsFindByName(client, "weapon_flashbang");
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_Flashbang2, "eholster");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Flashbang2)
	{
		WeaponAttachRemoveAddons(client, BitType_Flashbang2);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_HEGrenade)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_HEGrenade))
		{
			weapon = WeaponsFindByName(client, "weapon_hegrenade");
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_HEGrenade, "grenade1");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_HEGrenade)
	{
		WeaponAttachRemoveAddons(client, BitType_HEGrenade);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_SmokeGrenade)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_SmokeGrenade))
		{
			weapon = WeaponsFindByName(client, "weapon_smokegrenade");
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_SmokeGrenade, "grenade2");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_SmokeGrenade)
	{
		WeaponAttachRemoveAddons(client, BitType_SmokeGrenade);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_Decoy)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_Decoy))
		{
			weapon = WeaponsFindByName(client, "weapon_decoy");
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_Decoy, "grenade3");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Decoy)
	{
		WeaponAttachRemoveAddons(client, BitType_Decoy);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_Knife)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_Knife))
		{
			weapon = GetPlayerWeaponSlot(client, SlotIndex_Melee);
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_Knife, "knife");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Knife)
	{
		WeaponAttachRemoveAddons(client, BitType_Knife);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_TaGrenade)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_TaGrenade))
		{
			weapon = WeaponsFindByName(client, "weapon_tagrenade");
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_TaGrenade, "grenade4");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_TaGrenade)
	{
		WeaponAttachRemoveAddons(client, BitType_TaGrenade);
	}
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_C4)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_C4))
		{
			weapon = GetPlayerWeaponSlot(client, SlotIndex_C4);
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_C4, "c4");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_C4)
	{
		WeaponAttachRemoveAddons(client, BitType_C4);
	}

	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_DefuseKit)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_DefuseKit))
		{
			if (ToolsHasDefuser(client))
			{
				iD = ToolsGetCustomID(client);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_DefuseKit, "c4");
				}
			}
		}
	}
	/*else if (gClientData[client].AttachmentBits & CSAddon_DefuseKit)
	{
		WeaponAttachRemoveAddons(client, BitType_DefuseKit);
	}*/
	
	/*____________________________________________________________________________________________*/
	
	if (iBits & CSAddon_Shield)
	{
		if (!(gClientData[client].AttachmentBits & CSAddon_Shield))
		{
			weapon = WeaponsFindByName(client, "weapon_shield");
			
			if (weapon != -1)
			{
				iD = ToolsGetCustomID(weapon);
				if (iD != -1)
				{
					WeaponAttachCreateAddons(client, iD, BitType_Shield, "c4");
				}
			}
		}
	}
	else if (gClientData[client].AttachmentBits & CSAddon_Shield)
	{
		WeaponAttachRemoveAddons(client, BitType_Shield);
	}
	
	/*____________________________________________________________________________________________*/
	
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
void WeaponAttachCreateAddons(int client, int iD, BitType mBits, const char[] sAttach)
{
	WeaponAttachRemoveAddons(client, mBits);

	if (WeaponsGetModelDropID(iD))
	{
		if (LookupEntityAttachment(client, sAttach))
		{
			static char sModel[PLATFORM_LINE_LENGTH];
			WeaponsGetModelDrop(iD, sModel, sizeof(sModel)); 
	
			int entity = UTIL_CreateDynamic("backpack", NULL_VECTOR, NULL_VECTOR, sModel);
			
			if (entity != -1)
			{
				ToolsSetTextures(entity, WeaponsGetModelBody(iD, ModelType_Drop), WeaponsGetModelSkin(iD, ModelType_Drop)); 

				SetVariantString("!activator");
				AcceptEntityInput(entity, "SetParent", client, entity);
				ToolsSetOwner(entity, client);
				
				SetVariantString(sAttach);
				AcceptEntityInput(entity, "SetParentAttachment", client, entity);
				
				SDKHook(entity, SDKHook_SetTransmit, ToolsOnEntityTransmit);
				
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
	if (mBits == BitType_Invalid)
	{
		for (BitType i = BitType_PrimaryWeapon; i <= BitType_Shield; i++)
		{
			int entity = EntRefToEntIndex(gClientData[client].AttachmentAddons[i]);
	
			if (entity != -1) 
			{
				AcceptEntityInput(entity, "Kill");
			}

			gClientData[client].AttachmentBits = CSAddon_NONE;
			gClientData[client].AttachmentAddons[i] = -1;
		}
	}
	else
	{
		int entity = EntRefToEntIndex(gClientData[client].AttachmentAddons[mBits]);

		if (entity != -1) 
		{
			AcceptEntityInput(entity, "Kill");
		}

		gClientData[client].AttachmentBits = CSAddon_NONE;
		gClientData[client].AttachmentAddons[mBits] = -1;
	}
}
