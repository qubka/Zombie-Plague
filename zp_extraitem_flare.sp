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
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: Flare",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the grenade.
 **/
#define GRENADE_FLARE_RADIUS         150.0                 // Flare lightning size (radius)
#define GRENADE_FLARE_DISTANCE       600.0                 // Flare lightning size (distance)
#define GRENADE_FLARE_DURATION       20.0                  // Flare lightning duration in seconds
#define GRENADE_FLARE_COLOR          "255 0 0 255"         // Flare color in 'RGBA'
/**
 * @endsection
 **/
 
// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("flare grenade");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"flare grenade\" wasn't find");
    
    // Weapons
    gWeapon = ZP_GetWeaponNameID("flare grenade");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"flare grenade\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("FLARE_GRENADE_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"FLARE_GRENADE_SOUNDS\" wasn't find");
    
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
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Validate access
        if(ZP_IsPlayerHasWeapon(clientIndex, gWeapon) != INVALID_ENT_REFERENCE)
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
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, gWeapon);
    }
}

/**
 * @brief Called after a custom grenade is created.
 *
 * @param clientIndex       The client index.
 * @param grenadeIndex      The grenade index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnGrenadeCreated(int clientIndex, int grenadeIndex, int weaponID)
{
    // Validate custom grenade
    if(weaponID == gWeapon) /* OR if(ZP_GetWeaponID(grenadeIndex) == gWeapon)*/
    {
        // Block grenade
        SetEntProp(grenadeIndex, Prop_Data, "m_nNextThinkTick", -1);

        // Gets parent position
        static float vPosition[3];
        GetEntPropVector(grenadeIndex, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Play sound
        ZP_EmitSoundToAll(gSound, 1, grenadeIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

        // Create effects
        UTIL_CreateLight(grenadeIndex, vPosition, _, _, _, _, _, _, _, GRENADE_FLARE_COLOR, GRENADE_FLARE_DISTANCE, GRENADE_FLARE_RADIUS, GRENADE_FLARE_DURATION);
        UTIL_CreateParticle(grenadeIndex, vPosition, _, _, "smoking", GRENADE_FLARE_DURATION);

        // Kill after some duration
        UTIL_RemoveEntity(grenadeIndex, GRENADE_FLARE_DURATION);
    }
}