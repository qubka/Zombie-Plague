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
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
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
    name            = "[ZP] Weapon: Sfsniper",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of survivor weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_BEAM_LIFE                2.5
#define WEAPON_BEAM_WIDTH               "3.0"
#define WEAPON_BEAM_COLOR               "255 69 0"
/**
 * @endsection
 **/

// Weapon index
int gWeapon;
#pragma unused gWeapon

/**
    * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("sfsniper");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"sfsniper\" wasn't find");

    // Models
    PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

/**
 * @brief Called on bullet of a weapon.
 *
 * @param clientIndex       The client index.
 * @param vBulletPosition   The position of a bullet hit.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponBullet(int clientIndex, float vBulletPosition[3], int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Gets weapon position
        static float vPosition[3];
        ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, -5.0, vPosition);
        
        // Create a beam entity
        int entityIndex = UTIL_CreateBeam(vPosition, vBulletPosition, _, _, WEAPON_BEAM_WIDTH, _, _, _, _, _, _, "materials/sprites/laserbeam.vmt", _, _, BEAM_STARTSPARKS | BEAM_ENDSPARKS, _, _, _, WEAPON_BEAM_COLOR, 0.0, WEAPON_BEAM_LIFE + 1.0, "sflaser");
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Create effect hook
            CreateTimer(0.1, BeamEffectHook, EntIndexToEntRef(entityIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

/**
 * @brief Beam effect think.
 *
 * @param hThink            The think handle.    
 * @param referenceIndex    The reference index.    
 **/
public Action BeamEffectHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from the reference
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initalize values
        static int iRed; static int iGreen; static int iBlue; static int iAplha; int iNewAlpha = RoundToNearest((240.0 / WEAPON_BEAM_LIFE) / 10.0);
        
        // Gets an entity's color
        GetEntityRenderColor(entityIndex, iRed, iGreen, iBlue, iAplha);
        
        // Validate alpha
        if(iAplha < iNewAlpha || iAplha > 255)
        {
            // Remove the entity from the world
            AcceptEntityInput(entityIndex, "Kill");
            return Plugin_Stop;
        }
        
        // Sets an entity's color
        SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
        SetEntityRenderColor(entityIndex, iRed, iGreen, iBlue, iAplha - iNewAlpha); 
    }
    else
    {
        // Destroy think
        return Plugin_Stop;
    }
    
    // Return on success
    return Plugin_Continue;
}