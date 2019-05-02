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
    name            = "[ZP] Weapon: Cannon",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_FIRE_SPEED       1000.0
#define WEAPON_FIRE_DAMAGE      400.0
#define WEAPON_FIRE_GRAVITY     0.01
#define WEAPON_FIRE_RADIUS      200.0
#define WEAPON_FIRE_LIFE        0.7
#define WEAPON_FIRE_TIME        0.5
#define WEAPON_IGNITE_TIME      3.0
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_DRAW,
    ANIM_SHOOT2
};

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        // Hooks server sounds
        AddNormalSoundHook(view_as<NormalSHook>(SoundsNormalHook));
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("cannon");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"cannon\" wasn't find");

    // Weapons
    gWeapon = ZP_GetWeaponNameID("cannon");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"cannon\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("CANNON_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"CANNON_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param itemID            The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int itemID)
{
    // Check the item index
    if(itemID == gItem)
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
 * @param itemID            The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int itemID)
{
    // Check the item index
    if(itemID == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, gWeapon, SlotType_Primary);
    }
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));

    // Create an effect
    Weapon_OnCreateEffect(weaponIndex);
}

void Weapon_OnIdle(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Sets idle animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_IDLE); 
    
    // Sets next idle time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_IDLE));
}

void Weapon_OnHolster(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Stop an effect
    Weapon_OnCreateEffect(weaponIndex, "Kill");
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iAmmo, flCurrentTime

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate ammo
    if(iAmmo <= 0)
    {
        // Emit empty sound
        ClientCommand(clientIndex, "play weapons/clipempty_rifle.wav");
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.2);
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }

    // Substract ammo
    iAmmo -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo); 

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, ANIM_SHOOT1));
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
 
    // Play sound
    ZP_EmitSoundToAll(gSound, 1, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT1, ANIM_SHOOT2 });
    ZP_SetPlayerAnimation(clientIndex, AnimType_FirePrimary);
    
    // Initialize vector
    static float vPosition[5][3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 50.0, 60.0, -10.0,  vPosition[0]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, 30.0, -10.0,  vPosition[1]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, 0.0,  -10.0,  vPosition[2]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, -30.0, -10.0, vPosition[3]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, -60.0, -10.0, vPosition[4]);

    // i - fire index
    for(int i = 0; i < 5; i++)
    {
        // Create a fire
        Weapon_OnCreateFire(clientIndex, weaponIndex, vPosition[i]);
    }

    // Initialize variables
    static float vVelocity[3]; int iFlags = GetEntityFlags(clientIndex);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        ZP_CreateWeaponKickBack(clientIndex, 10.5, 7.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(clientIndex, 14.0, 10.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(clientIndex, 10.5, 6.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        ZP_CreateWeaponKickBack(clientIndex, 10.75, 10.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }
    
    // Start an effect
    Weapon_OnCreateEffect(weaponIndex, "Start");
    Weapon_OnCreateEffect(weaponIndex, "FireUser2");
}

void Weapon_OnCreateFire(int clientIndex, int weaponIndex, float vPosition[3])
{
    #pragma unused clientIndex, weaponIndex, vPosition

    // Initialize vectors
    static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];

    // Gets client eye angle
    GetClientEyeAngles(clientIndex, vAngle);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Create a rocket entity
    int entityIndex = UTIL_CreateProjectile(vPosition, vAngle);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Sets grenade model scale
        SetEntPropFloat(entityIndex, Prop_Send, "m_flModelScale", 10.0);
        
        // Returns vectors in the direction of an angle
        GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vEntVelocity, vEntVelocity);

        // Apply the magnitude by scaling the vector
        ScaleVector(vEntVelocity, WEAPON_FIRE_SPEED);

        // Adds two vectors
        AddVectors(vEntVelocity, vVelocity, vEntVelocity);

        // Push the fire
        TeleportEntity(entityIndex, NULL_VECTOR, NULL_VECTOR, vEntVelocity);
        
        // Sets an entity color
        SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
        SetEntityRenderColor(entityIndex, _, _, _, 0);
        AcceptEntityInput(entityIndex, "DisableShadow"); /// Prevents the entity from receiving shadows
        
        // Sets parent for the entity
        SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
        SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
        SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);

        // Sets gravity
        SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", WEAPON_FIRE_GRAVITY); 

        // Create touch hook
        SDKHook(entityIndex, SDKHook_Touch, FireTouchHook);

        // Create an effect
        UTIL_CreateParticle(entityIndex, vPosition, _, _, "new_flame_core", WEAPON_FIRE_LIFE);
        
        // Kill after some duration
        UTIL_RemoveEntity(entityIndex, WEAPON_FIRE_LIFE);
    }
}

void Weapon_OnCreateEffect(int weaponIndex, char[] sInput = "")
{
    #pragma unused weaponIndex, sInput

    // Gets the effect index
    int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity");
    
    // Is effect should be created ?
    if(!hasLength(sInput))
    {
        // Validate entity 
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            return;
        }
        
        // Gets the world model index
        int worldModel = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
        
        // Validate model 
        if(worldModel != INVALID_ENT_REFERENCE)
        {
            // Gets weapon muzzleflesh
            static char sMuzzle[NORMAL_LINE_LENGTH];
            ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
    
            // Create an attach fire effect
            entityIndex = UTIL_CreateParticle(worldModel, _, _, "mag_eject", sMuzzle);
            
            // Validate entity 
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Sets the effect index
                SetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity", entityIndex);
                
                // Stop an effect
                AcceptEntityInput(entityIndex, "Stop"); 
                
                // Initialize flags char
                static char sFlags[SMALL_LINE_LENGTH];
                FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:Stop::%f:-1", WEAPON_FIRE_TIME);
                
                // Sets modified flags on the entity
                SetVariantString(sFlags);
                AcceptEntityInput(entityIndex, "AddOutput");
            }
        }
    }
    else
    {
        // Validate entity 
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Toggle state
            AcceptEntityInput(entityIndex, sInput); 
        }
    }
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2)         \
                                \
    Weapon_On%0                 \
    (                           \
        %1,                     \
        %2,                     \
                                \
        GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
                                \
        GetGameTime()           \
    )    

/**
 * @brief Called on deploy of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDeploy(int clientIndex, int weaponIndex, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Deploy(clientIndex, weaponIndex);
    }
}

/**
 * @brief Called on holster of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponHolster(int clientIndex, int weaponIndex, int weaponID) 
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Holster(clientIndex, weaponIndex);
    }
}
    
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
public Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Button secondary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }
        
        // Call event
        _call.Idle(clientIndex, weaponIndex);
    }
    
    // Allow button
    return Plugin_Continue;
}

//**********************************************
//* Item (fire) hooks.                         *
//**********************************************

/**
 * @brief Fire touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action FireTouchHook(int entityIndex, int targetIndex)
{
    // Validate target
    if(IsValidEdict(targetIndex))
    {
        // Gets thrower index
        int throwerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hThrower");

        // Validate thrower
        if(throwerIndex == targetIndex)
        {
            // Return on the unsuccess
            return Plugin_Continue;
        }

        // Validate client
        if(IsPlayerExist(targetIndex))
        {
            // Validate zombie
            if(ZP_IsPlayerZombie(targetIndex)) 
            {
                // Put the fire on
                UTIL_IgniteEntity(targetIndex, WEAPON_IGNITE_TIME);  
            }
        }

        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Create an explosion
        UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, WEAPON_FIRE_DAMAGE, WEAPON_FIRE_RADIUS, "cannon", throwerIndex, entityIndex);

        // Remove the entity from the world
        AcceptEntityInput(entityIndex, "Kill");
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Called when a sound is going to be emitted to one or more clients. NOTICE: all params can be overwritten to modify the default behaviour.
 *  
 * @param clients           Array of client indexes.
 * @param numClients        Number of clients in the array (modify this value if you add/remove elements from the client array).
 * @param sSample           Sound file name relative to the "sounds" folder.
 * @param entityIndex       Entity emitting the sound.
 * @param iChannel          Channel emitting the sound.
 * @param flVolume          The sound volume.
 * @param iLevel            The sound level.
 * @param iPitch            The sound pitch.
 * @param iFlags            The sound flags.
 **/ 
public Action SoundsNormalHook(int clients[MAXPLAYERS-1], int &numClients, char[] sSample, int &entityIndex, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags)
{
    // Validate client
    if(IsValidEdict(entityIndex))
    {
        // Validate custom grenade
        if(GetEntProp(entityIndex, Prop_Data, "m_iHammerID") == gWeapon)
        {
            // Gets entity classname
            static char sClassname[SMALL_LINE_LENGTH];
            GetEdictClassname(entityIndex, sClassname, sizeof(sClassname));
            
            // Validate hegrenade projectile
            if(!strncmp(sClassname, "he", 2, false))
            {
                // Block sounds
                return Plugin_Stop; 
            } 
        }
    }
    
    // Allow sounds
    return Plugin_Continue;
}