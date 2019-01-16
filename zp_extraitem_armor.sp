/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
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

#include <sourcemod>
#include <sdktools>
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: Armor",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Item index
int gItemKevlar; int gItemAssault; int gItemHeavy; int gWeaponKevlar; int gWeaponAssault; int gWeaponHeavy;
#pragma unused gItemKevlar, gItemAssault, gItemHeavy, gWeaponKevlar, gWeaponAssault, gWeaponHeavy

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItemKevlar = ZP_GetExtraItemNameID("kevlar");
    if(gItemKevlar == -1) SetFailState("[ZP] Custom extraitem ID from name : \"kevlar\" wasn't find");
    gItemAssault = ZP_GetExtraItemNameID("assaultsuit");
    if(gItemAssault == -1) SetFailState("[ZP] Custom extraitem ID from name : \"assaultsuit\" wasn't find");
    gItemHeavy = ZP_GetExtraItemNameID("heavysuit");
    if(gItemHeavy == -1) SetFailState("[ZP] Custom extraitem ID from name : \"heavysuit\" wasn't find");

    // Weapons
    gWeaponKevlar = ZP_GetWeaponNameID("kevlar");
    if(gWeaponKevlar == -1) SetFailState("[ZP] Custom weapon ID from name : \"kevlar\" wasn't find");
    gWeaponAssault = ZP_GetWeaponNameID("assaultsuit");
    if(gWeaponAssault == -1) SetFailState("[ZP] Custom weapon ID from name : \"assaultsuit\" wasn't find");
    gWeaponHeavy = ZP_GetWeaponNameID("heavysuit");
    if(gWeaponHeavy == -1) SetFailState("[ZP] Custom weapon ID from name : \"heavysuit\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("ARMOR_BUY_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"ARMOR_BUY_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item's index
    if(extraitemIndex == gItemKevlar)
    {
        // Validate access
        if(GetClientArmor(clientIndex) >= ZP_GetWeaponClip(gWeaponKevlar))
        {
            return Plugin_Handled;
        }
    }
    else if(extraitemIndex == gItemAssault)
    {
        // Validate access
        if(GetClientArmor(clientIndex) >= ZP_GetWeaponClip(gWeaponAssault) || GetEntProp(clientIndex, Prop_Send, "m_bHasHelmet"))
        {
            return Plugin_Handled;
        }
    }
    else if(extraitemIndex == gItemHeavy)
    {
        // Validate access
        if(GetClientArmor(clientIndex) >= ZP_GetWeaponClip(gWeaponHeavy) || GetEntProp(clientIndex, Prop_Send, "m_bHasHeavyArmor"))
        {
            return Plugin_Handled;
        }
    }
    
    // Allow showing
    return Plugin_Continue;
}

/**
 * @brief Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item's index
    if(extraitemIndex == gItemKevlar)
    {
        // Give item
        ZP_GiveClientWeapon(clientIndex, gWeaponKevlar);
    }
    else if(extraitemIndex == gItemAssault)
    {
        // Give item
        ZP_GiveClientWeapon(clientIndex, gWeaponAssault);
    }
    else if(extraitemIndex == gItemHeavy)
    {
        // Give item
        ZP_GiveClientWeapon(clientIndex, gWeaponHeavy);
    }
}
