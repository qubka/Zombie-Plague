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
#include <zombieplague>

#pragma newdecls required

/**
 * Record plugin info.
 **/
public Plugin WeaponM4A1Ethereal =
{
    name            = "[ZP] Weapon: Ethereal",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of survivor weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_REFERANCE                "Etherial" // Models and other properties in the 'weapons.ini'
#define WEAPON_SPEED                    0.25
#define WEAPON_BEAM_LIFE                0.105
#define WEAPON_BEAM_COLOR               {0, 194, 194, 255}
/**
 * @endsection
 **/

// ConVar for sound level
ConVar hSoundLevel;

// Variables for precache resources
int decalBeam;

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hook temp entity
        AddTempEntHook("Shotgun Shot", WeaponFireBullets);
        HookEvent("bullet_impact", WeaponImpactBullets, EventHookMode_Post);
    }
}

/**
 * The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    
    // Models
    decalBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}

/**
 * Event callback (Shotgun Shot)
 * The weapon was been shoted.
 * 
 * @param sTEName       Temp name.
 * @param iPlayers      Array containing target player indexes.
 * @param numClients    Number of players in the array.
 * @param flDelay       Delay in seconds to send the TE.
 **/
public Action WeaponFireBullets(const char[] sTEName, const int[] iPlayers, int numClients, float flDelay)
{
    // Initialize weapon index
    int weaponIndex;

    // Gets all required event info
    int clientIndex = TE_ReadNum("m_iPlayer") + 1;

    // Validate weapon
    if(!IsCustomItem(clientIndex, weaponIndex))
    {
        // Allow broadcast
        return Plugin_Continue;
    }

    // Emit fire sound
    EmitSoundToAll("*/weapons/eminem/ethereal/ethereal_shoot1.mp3", clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    EmitSoundToAll("*/weapons/eminem/ethereal/ethereal_shoot1.mp3", clientIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
    // Sets speed of shooting
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", GetGameTime() + WEAPON_SPEED);
    
    // Block broadcast
    return Plugin_Stop;
}

/**
 * Event callback (bullet_impact)
 * The bullet hits something.
 * 
 * @param hEvent            The event handle.
 * @param sName             Name of the event.
 * @param iDontBroadcast    If true, event is broadcasted to all clients, false if not.
 **/
public Action WeaponImpactBullets(Event hEvent, const char[] sName, bool iDontBroadcast) 
{
    // Initialize weapon index
    static int weaponIndex;

    // Gets all required event info
    int clientIndex = GetClientOfUserId(hEvent.GetInt("userid"));

    // If weapon isn't custom
    if(!IsCustomItem(clientIndex, weaponIndex))
    {
        return;
    }

    // Initialize vector variables
    static float flStart[3]; static float flEnd[3];

    // Gets end position
    flEnd[0] = hEvent.GetFloat("x");
    flEnd[1] = hEvent.GetFloat("y");
    flEnd[2] = hEvent.GetFloat("z");

    // Gets weapon position
    ZP_GetWeaponAttachmentPos(clientIndex, "muzzle_flash", flStart);
    
    // Sent a beam
    TE_SetupBeamPoints(flStart, flEnd, decalBeam, 0 , 0, 0, WEAPON_BEAM_LIFE, 2.0, 2.0, 10, 1.0, WEAPON_BEAM_COLOR, 30);
    TE_SendToAll();
}

//**********************************************
//* VALIDATIONS                                *
//**********************************************

/**
 * Validate custom weapon and player.
 * 
 * @param clientIndex       The client index. 
 * @param weaponIndex       The weapon index.
 * @return                  True if valid, false if not.
 **/
stock bool IsCustomItem(int clientIndex, int &weaponIndex)
{
    // Validate client
    if (!IsPlayerExist(clientIndex))
    {
        return false;
    }
    
    // Validate survivor
    if (!ZP_IsPlayerSurvivor(clientIndex))
    {
        return false;
    }

    // Gets weapon index
    weaponIndex = GetEntPropEnt(clientIndex, Prop_Data, "m_hActiveWeapon");

    // Verify that the weapon is valid
    if(!IsValidEdict(weaponIndex))
    {
        return false;
    }
    
    // Gets custom weapon id
    static int iD;
    if(!iD) iD = ZP_GetWeaponNameID(WEAPON_REFERANCE);
    
    // If weapon id isn't equal, then stop
    if(ZP_GetWeaponID(weaponIndex) != iD)
    {
        return false;
    }

    // Return on unsuccess
    return true;
}