/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
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

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: Flare",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_REFERENCE         "flare grenade" // Name in weapons.ini from translation file   
#define EXTRA_ITEM_INFO              "" // Only will be taken from translation file 
#define EXTRA_ITEM_COST              7
#define EXTRA_ITEM_LEVEL             5
#define EXTRA_ITEM_ONLINE            10
#define EXTRA_ITEM_LIMIT             1
#define EXTRA_ITEM_GROUP             ""
/**
 * @endsection
 **/
 
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
 
// Variables for the key sound block
int gSound; ConVar hSoundLevel;

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize extra item
        gItem = ZP_RegisterExtraItem(EXTRA_ITEM_REFERENCE, EXTRA_ITEM_INFO, EXTRA_ITEM_COST, EXTRA_ITEM_LEVEL, EXTRA_ITEM_ONLINE, EXTRA_ITEM_LIMIT, EXTRA_ITEM_GROUP);
    }
}

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(EXTRA_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", EXTRA_ITEM_REFERENCE);

    // Sounds
    gSound = ZP_GetSoundKeyID("FLARE_GRENADE_SOUNDS");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
}

/**
 * Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Validate class
        if(ZP_IsPlayerZombie(clientIndex) || ZP_IsPlayerSurvivor(clientIndex))
        {
            return Plugin_Stop;
        }

        // Validate access
        if(ZP_IsPlayerHasWeapon(clientIndex, gWeapon))
        {
            return Plugin_Handled;
        }
    }

    // Allow showing
    return Plugin_Continue;
}

/**
 * Called after select an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The index of extraitem from ZP_RegisterExtraItem() native.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, EXTRA_ITEM_REFERENCE);
    }
}

/**
 * Called after a custom weapon is created.
 *
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int weaponIndex, int weaponID)
{
    // Validate custom grenade
    if(weaponID == gWeapon) /* OR if(ZP_GetWeaponID(weaponIndex) == gWeapon)*/
    {
        // Block grenade
        SetEntProp(weaponIndex, Prop_Data, "m_nNextThinkTick", -1);

        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound));
        EmitSoundToAll(sSound, weaponIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);

        // Create an light_dynamic entity
        int lightIndex = CreateEntityByName("light_dynamic");

        // If entity isn't valid, then skip
        if(lightIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValue(lightIndex, "inner_cone", "0");
            DispatchKeyValue(lightIndex, "cone", "80");
            DispatchKeyValue(lightIndex, "brightness", "1");
            DispatchKeyValue(lightIndex, "pitch", "90");
            DispatchKeyValue(lightIndex, "style", "5");
            DispatchKeyValue(lightIndex, "_light", GRENADE_FLARE_COLOR);
            DispatchKeyValueFloat(lightIndex, "distance", GRENADE_FLARE_DISTANCE);
            DispatchKeyValueFloat(lightIndex, "spotlight_radius", GRENADE_FLARE_RADIUS);

            // Spawn the entity into the world
            DispatchSpawn(lightIndex);

            // Activate the entity
            AcceptEntityInput(lightIndex, "TurnOn");

            // Sets parent to the entity
            SetVariantString("!activator"); 
            AcceptEntityInput(lightIndex, "SetParent", weaponIndex, lightIndex); 
            SetEntPropEnt(lightIndex, Prop_Data, "m_pParent", weaponIndex);

            // Initialize vector variables
            static float vPosition[3];
            
            // Gets parent position
            GetEntPropVector(weaponIndex, Prop_Send, "m_vecOrigin", vPosition);
            
            // Spawn the entity
            DispatchKeyValueVector(lightIndex, "origin", vPosition);
            
            // Create an effect
            FakeCreateParticle(weaponIndex, vPosition, _, "smoking", GRENADE_FLARE_DURATION);
        }

        // Initialize char
        static char sTime[SMALL_LINE_LENGTH];
        Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", GRENADE_FLARE_DURATION);

        // Sets modified flags on the entity
        SetVariantString(sTime);
        AcceptEntityInput(weaponIndex, "AddOutput");
        AcceptEntityInput(weaponIndex, "FireUser1");
    }
}