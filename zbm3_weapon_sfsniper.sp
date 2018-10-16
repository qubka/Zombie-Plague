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
    name            = "[ZP] Weapon: Sfsniper",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of survivor weapon",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_ITEM_REFERENCE           "sfsniper" // Name in weapons.ini from translation file
#define WEAPON_BEAM_LIFE                2.5
#define WEAPON_BEAM_WIDTH               3.0
#define WEAPON_BEAM_COLOR               {255, 69, 0, 255}
#define WEAPON_BEAM_MODEL               "materials/sprites/laserbeam.vmt"
/**
 * @endsection
 **/

// Weapon index
int gWeapon;

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_ITEM_REFERENCE);

    // Models
    PrecacheModel(WEAPON_BEAM_MODEL, true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnBullet(const int clientIndex, const int weaponIndex, float vBulletPosition[3])
{
    #pragma unused clientIndex, weaponIndex, vBulletPosition

    // Initialize vectors
    static float vEntPosition[3];

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, -5.0, vEntPosition);
    
    // Create a beam entity
    int entityIndex = CreateEntityByName("env_beam");

    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize variables
        static char sClassname[SMALL_LINE_LENGTH]; static char sWidth[SMALL_LINE_LENGTH]; static const int vColor[4] = WEAPON_BEAM_COLOR;
        
        // Dispatch main values of the entity
        Format(sClassname, sizeof(sClassname), "sflaser%i", entityIndex);
        DispatchKeyValue(entityIndex, "targetname", sClassname);
        DispatchKeyValue(entityIndex, "damage", "0");
        DispatchKeyValue(entityIndex, "framestart", "0");
        FloatToString(WEAPON_BEAM_WIDTH, sWidth, sizeof(sWidth));
        DispatchKeyValue(entityIndex, "BoltWidth", sWidth);
        DispatchKeyValue(entityIndex, "renderfx", "0");
        DispatchKeyValue(entityIndex, "TouchType", "3");
        DispatchKeyValue(entityIndex, "framerate", "0");
        DispatchKeyValue(entityIndex, "decalname", "Bigshot");
        DispatchKeyValue(entityIndex, "TextureScroll", "35");
        DispatchKeyValue(entityIndex, "HDRColorScale", "1.0");
        DispatchKeyValue(entityIndex, "texture", WEAPON_BEAM_MODEL);
        DispatchKeyValue(entityIndex, "life", "0"); 
        DispatchKeyValue(entityIndex, "StrikeTime", "1"); 
        DispatchKeyValue(entityIndex, "LightningStart", sClassname);
        DispatchKeyValue(entityIndex, "spawnflags", "0"); 
        DispatchKeyValue(entityIndex, "NoiseAmplitude", "0"); 
        DispatchKeyValue(entityIndex, "Radius", "256");
        DispatchKeyValue(entityIndex, "renderamt", "100");
        DispatchKeyValue(entityIndex, "rendercolor", "0 0 0");

        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Activate the entity
        AcceptEntityInput(entityIndex, "TurnOff"); AcceptEntityInput(entityIndex, "TurnOn"); 
        
        // Sets the model
        SetEntityModel(entityIndex, WEAPON_BEAM_MODEL);
        
        // Teleport the beam
        TeleportEntity(entityIndex, vEntPosition, NULL_VECTOR, NULL_VECTOR); 
        
        // Sets the size
        SetEntPropVector(entityIndex, Prop_Data, "m_vecEndPos", vBulletPosition);
        SetEntPropFloat(entityIndex, Prop_Data, "m_fWidth", WEAPON_BEAM_WIDTH);
        SetEntPropFloat(entityIndex, Prop_Data, "m_fEndWidth", WEAPON_BEAM_WIDTH);

        // Initialize variable
        static char sTime[SMALL_LINE_LENGTH];
        Format(sTime, sizeof(sTime), "%s,TurnOff,,0.001,-1", sClassname);
        DispatchKeyValue(entityIndex, "OnTouchedByEntity", sTime);
        Format(sTime, sizeof(sTime), "%s,TurnOn,,0.002,-1", sClassname);
        DispatchKeyValue(entityIndex, "OnTouchedByEntity", sTime);

        // Sets an entity's color
        SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
        SetEntityRenderColor(entityIndex, vColor[0], vColor[1], vColor[2], vColor[3]);

        // Create effect hook
        CreateTimer(0.1, BeamEffectHook, EntIndexToEntRef(entityIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * Beam effect think.
 *
 * @param hThink                The think handle.    
 * @param referenceIndex        The reference index.    
 **/
public Action BeamEffectHook(Handle hThink, int referenceIndex)
{
    // Gets the entity index from the reference
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initalize values
        static int iRed; static int iGreen; static int iBlue; static int iAplha; int iNewAlpha = RoundToFloor((240.0 / WEAPON_BEAM_LIFE) / 10.0); static const int vColor[4] = WEAPON_BEAM_COLOR;
        
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
        SetEntityRenderColor(entityIndex, vColor[0], vColor[1], vColor[2], iAplha - iNewAlpha); 
    }
    else
    {
        // Destroy think
        return Plugin_Stop;
    }
    
    // Return on success
    return Plugin_Continue;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2,%3)      \
                                \
    Weapon_On%0                 \
    (                           \
        %1,                     \
        %2,                     \
        %3                      \
    )    



/**
 * Called on bullet of a weapon.
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
        // Call event
        _call.Bullet(clientIndex, weaponIndex, vBulletPosition);
    }
}