/**
 * =============================================================================
 * Zombie Plague X Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin).
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

#if defined _weaponlist_included
 #endinput
#endif
#define _weaponlist_included

/**
 * @section Number of valid slots.
 **/
enum SlotType
{ 
    SlotType_Invalid = -1,        /** Used as return value when a slot doens't exist. */
    
    SlotType_Primary,             /** Primary slot */
    SlotType_Secondary,           /** Secondary slot */
    SlotType_Melee,               /** Melee slot */
    SlotType_Equipment,           /** Equipment slot */  
    SlotType_C4,                  /** C4 slot */  
};
/**
 * @endsection
 **/
 
/**
 * @section Number of valid menus.
 **/
enum MenuType
{
     MenuType_Invisible,          /**  Used as return value when a menu doens't exist. */
     
     MenuType_Pistols,            /**  Pistol menu */
     MenuType_Shotguns,           /**  Shotgun menu */
     MenuType_Rifles,             /**  Rifle menu */
     MenuType_Snipers,            /**  Sniper menu */
     MenuType_Machineguns,        /**  Machineguns menu */
     MenuType_Knifes              /**  Knife menu */
};
/**
 * @endsection
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
    BitType_DefuseKit             /** Defuse bit */
};
/**
 * @endsection
 **/
 
/**
 * @section Number of valid models.
 **/
enum ModelType
{
    ModelType_Invalid = -1,        /** Used as return value when a model doens't exist. */
    
    ModelType_View,                /** View model */
    ModelType_World,               /** World model */
    ModelType_Drop,                /** Dropped model */
    ModelType_Projectile           /** Projectile model */
};
/**
 * @endsection
 **/
 
/**
 * @brief Called before show a weapon in the weapons menu.
 * 
 * @param clientIndex       The client index.
 * @param weaponID          The weapon index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
forward Action ZP_OnClientValidateWeapon(int clientIndex, int weaponID);
 
/**
 * @brief Called after a custom grenade is created. (Only for projectiles)
 *
 * @param clientIndex       The client index.
 * @param grenadeIndex      The grenade index.
 * @param weaponID          The weapon id.
 **/
forward void ZP_OnGrenadeCreated(int clientIndex, int grenadeIndex, int weaponID);
 
/**
 * @brief Called after a custom weapon is created.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
forward void ZP_OnWeaponCreated(int clientIndex, int weaponIndex, int weaponID);

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
forward Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID);

/**
 * @brief Called on deploy of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @noreturn
 **/
forward void ZP_OnWeaponDeploy(int clientIndex, int weaponIndex, int weaponID);

/**
 * @brief Called on holster of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @noreturn
 **/
forward void ZP_OnWeaponHolster(int clientIndex, int weaponIndex, int weaponID);

/**
 * @brief Called on reload of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @noreturn
 **/
forward void ZP_OnWeaponReload(int clientIndex, int weaponIndex, int weaponID);

/**
 * @brief Called on bullet of a weapon.
 *
 * @param clientIndex       The client index.
 * @param vBulletPosition   The position of a bullet hit.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @noreturn
 **/
forward void ZP_OnWeaponBullet(int clientIndex, float vBulletPosition[3], int weaponIndex, int weaponID);

/**
 * @brief Called on shoot of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @noreturn
 **/
forward void ZP_OnWeaponShoot(int clientIndex, int weaponIndex, int weaponID);

/**
 * @brief Called on fire of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @noreturn
 **/
forward void ZP_OnWeaponFire(int clientIndex, int weaponIndex, int weaponID);

/**
 * @brief Gives the weapon by a given name.
 *
 * @param clientIndex       The client index.
 * @param weaponID          The weapon ID.
 * @param slot              (Optional) The slot index. (mod specific)
 * @param remove            (Optional) True to delete weapon or false to just drop weapon.
 *
 * @return                  The weapon index.
 **/
native int ZP_GiveClientWeapon(int clientIndex, int weaponID, SlotType slot = SlotType_Invalid, bool remove = false);

/**
 * @brief Gets the client viewmodel. 
 *
 * @param clientIndex       The client index.
 * @param custom            True to gets the custom viewmodel, false the original.
 *           
 * @return                  The viewmodel index.
 **/
native int ZP_GetClientViewModel(int clientIndex, bool custom);

/**
 * @brief Gets the client attachmodel. (On the player's backpack)
 *
 * @param clientIndex       The client index.
 * @param bitType           The bit type.
 *         
 * @return                  The attachmodel index.
 **/
native int ZP_GetClientAttachModel(int clientIndex, BitType bitType);

/**
 * @brief Gets the custom weapon id from a given weapon index. 
 *
 * @param weaponIndex       The weapon index.
 *
 * @return                  The weapon ID or -1 if no weapon was found.
 **/
native int ZP_GetWeaponID(int weaponIndex);

/**
 * @brief Gets the custom weapon id from a given name.
 *
 * @param name              The weapon name.
 *
 * @return                  The weapon ID or -1 if no weapon was found.
 **/
native int ZP_GetWeaponNameID(char[] name);

/**
 * @brief Gets the amount of all weapons.
 *
 * @return                  The weapon amount.    
 **/
native int ZP_GetNumberWeapon();

/**
 * @brief Gets the name of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param name              The string to return name in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponName(int weaponID, char[] name, int maxlenght = 32);

/**
 * @brief Gets the info of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param info              The string to return info in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponInfo(int weaponID, char[] info, int maxlenght = 128);

/**
 * @brief Gets the entity of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param entity            The string to return entity in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponEntity(int weaponID, char[] entity, int maxlenght = 32);

/**
 * @brief Gets the group of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param group             The string to return group in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponGroup(int weaponID, char[] group, int maxlenght = 32);

/**
 * @brief Gets the class of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param class             The string to return class in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponClass(int weaponID, char[] class, int maxlenght = 128);

/**
 * @brief Gets the cost of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The cost amount.    
 **/
native int ZP_GetWeaponCost(int weaponID);

/**
 * @brief Gets the slot of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The weapon slot.    
 **/
native MenuType ZP_GetWeaponSlot(int weaponID);

/**
 * @brief Gets the level of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The level amount.    
 **/
native int ZP_GetWeaponLevel(int weaponID);

/**
 * @brief Gets the online of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The online amount.    
 **/
native int ZP_GetWeaponOnline(int weaponID);

/**
 * @brief Gets the limit of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The limit amount.    
 **/
native int ZP_GetWeaponLimit(int weaponID);

/**
 * @brief Gets the damage of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The damage amount.    
 **/
native float ZP_GetWeaponDamage(int weaponID);

/**
 * @brief Gets the knockback of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The knockback amount.    
 **/
native float ZP_GetWeaponKnockBack(int weaponID);

/**
 * @brief Gets the clip ammo of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The clip ammo amount.
 **/
native int ZP_GetWeaponClip(int weaponID);

/**
 * @brief Gets the reserve clip of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The reserve ammo amount.    
 **/
native int ZP_GetWeaponAmmo(int weaponID);

/**
 * @brief Gets the ammunition cost of the weapon.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The ammunition cost.    
 **/
native int ZP_GetWeaponAmmunition(int weaponID);

/**
 * @brief Checks the drop state of the weapon.
 *
 * @param weaponID          The weapon ID.
 *
 * @return                  True or false.   
 **/
native bool ZP_IsWeaponDrop(int weaponID);

/**
 * @brief Gets the shoot delay of the weapon.
 *
 * @param weaponID          The weapon ID.
 *
 * @return                  The delay amount.    
 **/
native float ZP_GetWeaponSpeed(int weaponID);

/**
 * @brief Gets the reload duration of the weapon.
 *
 * @param weaponID          The weapon ID.
 *
 * @return                  The duration amount.    
 **/
native float ZP_GetWeaponReload(int weaponID);

/**
 * @brief Gets the delpoy duration of the weapon.
 *
 * @param weaponID          The weapon ID.
 *
 * @return                  The duration amount.    
 **/
native float ZP_GetWeaponDeploy(int weaponID);

/**
 * @brief Gets the sound key of the weapon.
 *
 * @param weaponID          The weapon ID.
 *
 * @return                  The key index.
 **/
native int ZP_GetWeaponSoundID(int weaponID);

/**
 * @brief Gets the icon of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param icon              The string to return icon in.
 * @param maxlenght         The lenght of string.
 **/
native int ZP_GetWeaponIcon(int weaponID, char[] icon, int maxlenght = 32);

/**
 * @brief Gets the viewmodel path of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponModelView(int weaponID, char[] model, int maxlenght = 256);

/**
* @brief Gets the index of the weapon viewmodel.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The viewmodel index.    
 **/
native int ZP_GetWeaponModelViewID(int weaponID);

/**
 * @brief Gets the worldmodel path of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponModelWorld(int weaponID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the index of the weapon worldmodel.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The worldmodel index.    
 **/
native int ZP_GetWeaponModelWorldID(int weaponID);

/**
 * @brief Gets the dropmodel path of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param model             The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponModelDrop(int weaponID, char[] model, int maxlenght = 256);

/**
 * @brief Gets the index of the weapon dropmodel.
 * 
 * @param weaponID          The weapon ID.
 *
 * @return                  The dropmodel index.    
 **/
native int ZP_GetWeaponModelDropID(int weaponID);

/**
 * @brief Gets the body index of the weapon model.
 *
 * @param weaponID          The weapon ID.
 * @param modelType         The model type.
 *
 * @return                  The body index.    
 **/
native int ZP_GetWeaponModelBody(int weaponID, ModelType modelType);

/**
 * @brief Gets the skin index of the weapon model.
 *
 * @param weaponID          The weapon ID.
 * @param modelType         The model type.
 *
 * @return                  The skin index.    
 **/
native int ZP_GetWeaponModelSkin(int weaponID, ModelType modelType);

/**
 * @brief Gets the muzzle name of a weapon at a given id.
 *
 * @param weaponID          The weapon ID.
 * @param muzzle            The string to return model in.
 * @param maxlenght         The lenght of string.
 **/
native void ZP_GetWeaponModelMuzzle(int weaponID, char[] muzzle, int maxlenght = 32); 

/**
 * @brief Gets the heat amount of the weapon model.
 *
 * @param weaponID          The weapon ID.
 *
 * @return                  The heat amount.    
 **/
native float ZP_GetWeaponModelHeat(int weaponID);

/**
 * @brief Returns index if the player has a current weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponID          The weapon id.
 *
 * @return                  The weapon index.
 **/
stock int ZP_IsPlayerHasWeapon(int clientIndex, int weaponID)
{
    // i = weapon number
    static int iSize; if(!iSize) iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for (int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hMyWeapons", i);
        
        // If entity isn't valid, then skip
        if(weaponIndex != INVALID_ENT_REFERENCE)
        {
            // If weapon find, then return
            if(ZP_GetWeaponID(weaponIndex) == weaponID)
            {
                return weaponIndex;
            }
        }
        
        // Go to next weapon
        continue;
    }

    // If wasn't found
    return -1;
}

/**
 * @brief Returns true if the player hold a current weapon, false if not.
 * 
 * @param clientIndex       The client index. 
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 * 
 * @return                  True or false.
 **/
stock bool ZP_IsPlayerHoldWeapon(int clientIndex, int &weaponIndex, int weaponID)
{
    // Validate client
    if(!IsPlayerExist(clientIndex))
    {
        return false;
    }

    // Gets weapon index
    weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");

    // If entity isn't valid, then stop
    if(weaponIndex == INVALID_ENT_REFERENCE)
    {
        return false;
    }

    // If weapon didn't find, then stop
    if(ZP_GetWeaponID(weaponIndex) != weaponID)
    {
        return false;
    }

    // Return on success
    return true;
}

/**
 * @brief Gets the weapon shoot position.
 *
 * @param clientIndex       The client index.
 * @param flForward         (Optional) The forward distance.
 * @param flRight           (Optional) The right distance. 
 * @param flVertical        (Optional) The vertical distance.
 * @param vPosition         The calculated position vector output.
 **/
stock void ZP_GetPlayerGunPosition(int clientIndex, float flForward = 0.0, float flRight = 0.0, float flVertical = 0.0, float vPosition[3])
{
    // Initialize vectors
    static float vEntPosition[3]; static float vEntAngle[3]; static float vForward[3]; static float vRight[3];  static float vVertical[3]; 

    // Gets client eye angle
    GetClientEyePosition(clientIndex, vEntPosition);
    
    // Gets client eye angle
    GetClientEyeAngles(clientIndex, vEntAngle);

    // Returns vectors in the direction of an angle
    GetAngleVectors(vEntAngle, vForward, vRight, vVertical);

    // Calculate ends point by applying all vectors distances 
    vPosition[0] = vEntPosition[0] + (vForward[0] * flForward) + (vRight[0] * flRight) + (vVertical[0] * flVertical);
    vPosition[1] = vEntPosition[1] + (vForward[1] * flForward) + (vRight[1] * flRight) + (vVertical[1] * flVertical);
    vPosition[2] = vEntPosition[2] + (vForward[2] * flForward) + (vRight[2] * flRight) + (vVertical[2] * flVertical);
}

/**
 * @brief Gets the weapon animating index.
 *
 * @param clientIndex       The client index.
 *
 * @return                  The sequence index.
 **/
stock int ZP_GetWeaponAnimation(int clientIndex)
{
    // Gets client viewmodel
    int viewModel = ZP_GetClientViewModel(clientIndex, true); /// Gets anims on the custom model 

    // Validate viewmodel
    if(viewModel != INVALID_ENT_REFERENCE)
    {
        // Gets animation
        return GetEntProp(viewModel, Prop_Send, "m_nSequence");
    }
    
    // Return on unsuccess
    return -1;
}

/**
 * @brief Sets the weapon animating index.
 *
 * @param clientIndex       The client index.
 * @param nSequence         The sequence index.
 **/
stock void ZP_SetWeaponAnimation(int clientIndex, int nSequence)
{
    // Gets client viewmodel
    int viewModel = ZP_GetClientViewModel(clientIndex, false); /// Play anims on the original model 

    // Validate viewmodel
    if(viewModel != INVALID_ENT_REFERENCE)
    {
        // Sets animation
        SetEntProp(viewModel, Prop_Send, "m_nSequence", nSequence);
    }
}

/**
 * @brief Sets the weapon animating paired index. (Important for animations, which should played in the not-repeatable row, like an attack)
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param nSequence         The sequence array.
 **/
stock void ZP_SetWeaponAnimationPair(int clientIndex, int weaponIndex, int nSequence[2])
{
    // Gets client viewmodel
    int viewModel = ZP_GetClientViewModel(clientIndex, false); /// Play anims on the original model 

    // Validate viewmodel
    if(viewModel != INVALID_ENT_REFERENCE)
    {
        // Gets the current played state of animation
        bool bPrevAnim = view_as<bool>(GetEntProp(weaponIndex, Prop_Send, "m_bSilencerOn"));
        
        // Sets animation
        SetEntProp(viewModel, Prop_Send, "m_nSequence", nSequence[bPrevAnim ? 0 : 1]);
        
        // Sets inversed played state
        SetEntProp(weaponIndex, Prop_Send, "m_bSilencerOn", !bPrevAnim);
    }
}

/**
 * @brief Returns index if the player has a weapon.
 *
 * @param clientIndex       The client index.
 * @param sType             The weapon entity.
 *
 * @return                  The weapon index.
 **/
stock int ZP_GetWeaponIndex(int clientIndex, char[] sType)
{
    // Initialize classname char
    static char sClassname[SMALL_LINE_LENGTH];

    // i = weapon number
    static int iSize; if(!iSize) iSize = GetEntPropArraySize(clientIndex, Prop_Send, "m_hMyWeapons");
    for(int i = 0; i < iSize; i++)
    {
        // Gets weapon index
        int weaponIndex = GetEntPropEnt(clientIndex, Prop_Send, "m_hMyWeapons", i);

        // Validate weapon
        if(weaponIndex != INVALID_ENT_REFERENCE)
        {
            // Gets weapon classname
            GetEdictClassname(weaponIndex, sClassname, sizeof(sClassname));

            // If weapon find, then return
            if(!strcmp(sClassname[7], sType[7], false))
            {
                return weaponIndex;
            }
        }
    }

    // Weapon wasn't found
    return -1;
}

/**
 * @brief Remove a weapon from the player.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param slotType          (Optional) The slot index to replace.
 **/
stock void ZP_RemoveWeapon(int clientIndex, int weaponIndex, SlotType slotType = SlotType_Melee)
{
    // Forces a player to remove weapon
    RemovePlayerItem(clientIndex, weaponIndex);
    AcceptEntityInput(weaponIndex, "Kill");
    
    //Gets weapon index
    int weaponIndex2 = GetPlayerWeaponSlot(clientIndex, view_as<int>(slotType));
    
    // Validate weapon
    if(weaponIndex2 != INVALID_ENT_REFERENCE)
    {
        // Gets weapon classname
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(weaponIndex2, sClassname, sizeof(sClassname));
        
        // Switch the weapon
        FakeClientCommand(clientIndex, "use %s", sClassname);
    }
}

/**
 * @brief Create the tracer to a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param sAttach1          The attachment name. (view)
 * @param sAttach2          The attachment name. (world)
 * @param sEffect           The effect name.
 * @param vBulletPosition   The position of a bullet hit.
 * @param flDurationTime    The duration of life.
 **/
stock void ZP_CreateWeaponTracer(int clientIndex, int weaponIndex, char[] sAttach1, char[] sAttach2, char[] sEffect, float vBulletPosition[3], float flDurationTime)
{
    // Validate name
    if(!hasLength(sEffect))
    {
        return;
    }
    
    #define ClientSrt  0
    #define ClientEnd  1
    #define ViewerSrt  2
    #define ViewerEnd  3
                                /** Regards to Phoenix **/
                             /** Dont ask me how it works ;) **/

    // Gets client view/world model
    int viewModel = ZP_GetClientViewModel(clientIndex, true);
    int worldModel = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");

    // Validate models
    if(viewModel == INVALID_ENT_REFERENCE || worldModel == INVALID_ENT_REFERENCE)
    {    
        return;
    }

    // Validate attachments
    if((sAttach1[0] != '\0' && !ZP_LookupAttachment(viewModel, sAttach1)) || (sAttach2[0] != '\0' && !ZP_LookupAttachment(worldModel, sAttach2)))
    {
        return;
    }

    // Create an attach particle entity
    static int entityIndex[4];
    entityIndex[ClientSrt] = CreateEntityByName("info_particle_system");
    entityIndex[ClientEnd] = CreateEntityByName("info_particle_system");
    entityIndex[ViewerSrt] = CreateEntityByName("info_particle_system");
    entityIndex[ViewerEnd] = CreateEntityByName("info_particle_system");

    // If entity isn't valid, then skip
    if(entityIndex[ViewerEnd] != INVALID_ENT_REFERENCE) /// Check the last entity ;)
    {
        // Gets the client angle
        static float vAngle[3]; static float vEmpty[3];
        GetEntPropVector(clientIndex, Prop_Data, "m_angAbsRotation", vAngle);
        
        // Teleport the entity
        TeleportEntity(entityIndex[ClientEnd], vBulletPosition, vAngle, NULL_VECTOR);
        TeleportEntity(entityIndex[ViewerEnd], vBulletPosition, vAngle, NULL_VECTOR);

        // Dispatch main values of the entity
        static char sClassname[SMALL_LINE_LENGTH];
        FormatEx(sClassname, sizeof(sClassname), "particle%d", entityIndex[ClientSrt]);
        DispatchKeyValue(entityIndex[ClientSrt], "targetname", sClassname);
        DispatchKeyValue(entityIndex[ClientEnd], "effect_name", sEffect);
        DispatchKeyValue(entityIndex[ClientEnd], "cpoint1", sClassname);
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex[ClientEnd]);
        
        // Sets owner to the entity 
        SetEntPropEnt(entityIndex[ClientEnd], Prop_Send, "m_hOwnerEntity", clientIndex);
        
        // Dispatch main values of the entity
        FormatEx(sClassname, sizeof(sClassname), "particle%d",  entityIndex[ViewerSrt]);
        DispatchKeyValue(entityIndex[ViewerSrt], "targetname", sClassname);
        DispatchKeyValue(entityIndex[ViewerEnd], "effect_name", sEffect);
        DispatchKeyValue(entityIndex[ViewerEnd], "cpoint1", sClassname);
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex[ViewerEnd]);
        
        // Sets owner to the entity 
        SetEntPropEnt(entityIndex[ViewerEnd], Prop_Send, "m_hOwnerEntity", clientIndex);

        // Teleport the entity
        TeleportEntity(entityIndex[ViewerSrt], NULL_VECTOR, vAngle, NULL_VECTOR);

        // Sets parent to the entity
        SetVariantString("!activator");
        AcceptEntityInput(entityIndex[ViewerSrt], "SetParent", worldModel,  entityIndex[ViewerSrt]);
        
        // Sets attachment to the entity
        SetVariantString(sAttach2);
        AcceptEntityInput(entityIndex[ViewerSrt], "SetParentAttachment",  entityIndex[ViewerSrt], entityIndex[ViewerSrt]);

        // Teleport the entity
        TeleportEntity(entityIndex[ViewerSrt], vEmpty, NULL_VECTOR, NULL_VECTOR);

        // Sets parent to the entity
        SetVariantString("!activator");
        AcceptEntityInput(entityIndex[ClientSrt], "SetParent", viewModel, entityIndex[ClientSrt]);
        
        // Sets attachment to the entity
        SetVariantString(sAttach1);
        AcceptEntityInput(entityIndex[ClientSrt], "SetParentAttachment", entityIndex[ClientSrt], entityIndex[ClientSrt]);

        /*______________________________________________________________________________*/
        
        // Hook entity callbacks 
        SDKHook(entityIndex[ClientEnd], SDKHook_SetTransmit, TracerClientTransmit);
        SDKHook(entityIndex[ViewerEnd], SDKHook_SetTransmit, TracerViewerTransmit);

        // Activate the entity
        ActivateEntity(entityIndex[ClientEnd]);
        AcceptEntityInput(entityIndex[ClientEnd], "Start");
        ActivateEntity(entityIndex[ViewerEnd]);
        AcceptEntityInput(entityIndex[ViewerEnd], "Start");

        // Initialize time char
        UTIL_RemoveEntity(entityIndex[ClientEnd], flDurationTime);
        UTIL_RemoveEntity(entityIndex[ViewerEnd], flDurationTime);
        UTIL_RemoveEntity(entityIndex[ClientSrt], flDurationTime);
        UTIL_RemoveEntity(entityIndex[ViewerSrt], flDurationTime);
    }
}

/**
 * @brief Create the kickback effect to a weapon .
 *
 * @param clientIndex       The client index.
 * @param upBase            The upward base amount.
 * @param lateralBase       The lateral base amount.
 * @param upMod             The upward mod amount.
 * @param lateralMod        The lateral mod amount.
 * @param upMax             The upward max amount.
 * @param directionChange   The direction seed.
 **/
stock void ZP_CreateWeaponKickBack(int clientIndex, float upBase, float lateralBase, float upMod, float lateralMod, float upMax, float lateralMax, int directionChange)
{
    // Initialize variables
    static int iDirection; static int iShotsFired; static float vPunchAngle[3];
    GetEntPropVector(clientIndex, Prop_Send, "m_aimPunchAngle", vPunchAngle);

    // Gets a shots fired
    if((iShotsFired = GetEntProp(clientIndex, Prop_Send, "m_iShotsFired")) != 1)
    {
        // Calculate a base power
        upBase += iShotsFired * upMod;
        lateralBase += iShotsFired * lateralMod;
    }

    // Reduce a max power
    upMax *= -1.0;
    vPunchAngle[0] -= upBase;

    // Validate max angle
    if(upMax >= vPunchAngle[0])
    {
        vPunchAngle[0] = upMax;
    }

    // Gets a direction change
    if((iDirection = GetEntProp(clientIndex, Prop_Send, "m_iDirection")))
    {
        // Increase the angle
        vPunchAngle[1] += lateralBase;

        // Validate min angle
        if(lateralMax < vPunchAngle[1])
        {
            vPunchAngle[1] = lateralMax;
        }
    }
    else
    {
        // Decrease the angle
        lateralMax *=  -1.0;
        vPunchAngle[1] -= lateralBase;

        // Validate max angle
        if(lateralMax > vPunchAngle[1])
        {
            vPunchAngle[1] = lateralMax;
        }
    }

    // Create a direction change
    if(!GetRandomInt(0, directionChange))
    {
        SetEntProp(clientIndex, Prop_Send, "m_iDirection", !iDirection);
    }

    // Sets a punch angle
    SetEntPropVector(clientIndex, Prop_Send, "m_aimPunchAngle", vPunchAngle);
    SetEntPropVector(clientIndex, Prop_Send, "m_viewPunchAngle", vPunchAngle);
}

//**********************************************
//* Tracer hooks.                              * 
//**********************************************

/**
 * Hook: SetTransmit
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action TracerClientTransmit(int entityIndex, int clientIndex) 
{
    // Allow particle to be transmittable
    if(GetEdictFlags(entityIndex) & FL_EDICT_ALWAYS)
    {
        SetEdictFlags(entityIndex, (GetEdictFlags(entityIndex) ^ FL_EDICT_ALWAYS));
    }
    
    // Gets the owner of the entity
    int ownerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity");
    
    // Validate observer mode
    if(ownerIndex == clientIndex || (GetEntProp(clientIndex, Prop_Send, "m_iObserverMode") == SPECMODE_FIRSTPERSON && ownerIndex == GetEntPropEnt(clientIndex, Prop_Send, "m_hObserverTarget")))
    {
        // Allow transmitting
        return Plugin_Continue;
    }
    
    // Block transmitting
    return Plugin_Handled;
}

/**
 * Hook: SetTransmit
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public Action TracerViewerTransmit(int entityIndex, int clientIndex) 
{
    // Allow particle to be transmittable
    if(GetEdictFlags(entityIndex) & FL_EDICT_ALWAYS)
    {
        SetEdictFlags(entityIndex, (GetEdictFlags(entityIndex) ^ FL_EDICT_ALWAYS));
    }
    
    // Gets the owner of the entity
    int ownerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity");
    
    // Validate observer mode
    if(ownerIndex == clientIndex || (GetEntProp(clientIndex, Prop_Send, "m_iObserverMode") == SPECMODE_FIRSTPERSON && ownerIndex == GetEntPropEnt(clientIndex, Prop_Send, "m_hObserverTarget")))
    {
        // Block transmitting
        return Plugin_Handled;
    }
    
    // Allow transmitting
    return Plugin_Continue;
}