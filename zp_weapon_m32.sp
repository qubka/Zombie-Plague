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
    name            = "[ZP] Weapon: M32",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about the weapon.
 **/
#define WEAPON_GRENADE_SPEED            1500.0
#define WEAPON_GRENADE_DAMAGE           100.0
#define WEAPON_GRENADE_GRAVITY          1.5
#define WEAPON_GRENADE_RADIUS           300.0
#define WEAPON_EXPLOSION_TIME           2.0
#define WEAPON_EFFECT_TIME              5.0
/**
 * @endsection
 **/

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_START_INSERT,
    ANIM_DRAW,
    ANIM_INSERT1,
    ANIM_INSERT2,
    ANIM_FINISH_INSERT
};

// Reload states
enum
{
    RELOAD_START,
    RELOAD_INSERT,
    RELOAD_END
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
    gItem = ZP_GetExtraItemNameID("m32");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"m32\" wasn't find");
    
    // Weapons
    gWeapon = ZP_GetWeaponNameID("m32");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"m32\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("M32_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"M32_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");

    // Effects
    PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
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

void Weapon_OnThink(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);
    /// HACK~HACK apply on each frame for shotguns
    
    // Validate clip/ammo
    if(iClip == ZP_GetWeaponClip(gWeapon) || iAmmo <= 0)
    {
        // Validate mode
        if(iReloadMode == RELOAD_END)
        {
            Weapon_OnReloadFinish(clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime);
            return;
        }
    }

    // Switch mode
    switch(iReloadMode)
    {
        case RELOAD_INSERT :
        {        
            // Validate animation delay
            if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
            {
                return;
            }

            // Sets reload animation
            ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_INSERT1, ANIM_INSERT2 });
            ZP_SetPlayerAnimation(clientIndex, AnimType_ReloadLoop);
            
            // Adds the delay to the game tick
            flCurrentTime += ZP_GetSequenceDuration(weaponIndex, ANIM_INSERT1);
            
            // Sets next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);

            // Sets new reload state
            SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_END);
        }
        
        case RELOAD_END :
        {
            // Sets the ammunition
            SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip + 1)
            SetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount", iAmmo - 1);
            
            // Sets new reload state
            SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
        }
    }
}

void Weapon_OnIdle(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate mode
    if(iReloadMode == RELOAD_START)
    {
        // Validate clip
        if(iClip <= 0)
        {
            // Validate ammo
            if(iAmmo)
            {
                Weapon_OnReload(clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime);
                return; /// Execute fake reload
            }
        }
    }
        
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

void Weapon_OnReload(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate ammo
    if(iAmmo <= 0)
    {
        return;
    }
    
    // Validate clip
    if(iClip >= ZP_GetWeaponClip(gWeapon))
    {
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate mode
    if(iReloadMode == RELOAD_START)
    {
        // Sets start reload animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_START_INSERT); 
        ZP_SetPlayerAnimation(clientIndex, AnimType_ReloadStart);
        
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetSequenceDuration(weaponIndex, ANIM_START_INSERT);
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);

        // Sets new reload state
        SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_INSERT);
        
        // Sets default FOV for the client
        SetEntProp(clientIndex, Prop_Send, "m_iFOV", GetEntProp(clientIndex, Prop_Send, "m_iDefaultFOV"));
    }
}

void Weapon_OnReloadFinish(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime

    // Sets end animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_FINISH_INSERT);        
    ZP_SetPlayerAnimation(clientIndex, AnimType_ReloadEnd);
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetSequenceDuration(weaponIndex, ANIM_FINISH_INSERT);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Stop reload
    SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime

    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
    
    // Cancel reload
    SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
    
    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate mode
    if(iReloadMode > RELOAD_START)
    {
        Weapon_OnReloadFinish(clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime);
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate clip
    if(iClip <= 0)
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
    iClip -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip); 

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
    
    // Create a grenade
    Weapon_OnCreateGrenade(clientIndex);

    // Initialize variables
    static float vVelocity[3]; int iFlags = GetEntityFlags(clientIndex);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        ZP_CreateWeaponKickBack(clientIndex, 5.5, 2.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        ZP_CreateWeaponKickBack(clientIndex, 7.0, 5.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        ZP_CreateWeaponKickBack(clientIndex, 5.5, 1.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        ZP_CreateWeaponKickBack(clientIndex, 5.75, 5.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }

    // Gets weapon muzzleflesh
    static char sMuzzle[NORMAL_LINE_LENGTH];
    ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));

    // Creates a muzzle
    UTIL_CreateParticle(ZP_GetClientViewModel(clientIndex, true), _, _, "1", sMuzzle, 0.1);
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iClip, int iAmmo, int iReloadMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime

    // Validate mode
    if(iReloadMode > RELOAD_START)
    {
        Weapon_OnReloadFinish(clientIndex, weaponIndex, iClip, iAmmo, iReloadMode, flCurrentTime);
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.3);
    
    // Sets FOV for the client
    int iDefaultFOV = GetEntProp(clientIndex, Prop_Send, "m_iDefaultFOV");
    SetEntProp(clientIndex, Prop_Send, "m_iFOV", GetEntProp(clientIndex, Prop_Send, "m_iFOV") == iDefaultFOV ? 55 : iDefaultFOV);
}

void Weapon_OnCreateGrenade(int clientIndex)
{
    #pragma unused clientIndex

    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, 0.0, vPosition);

    // Gets client eye angle
    GetClientEyeAngles(clientIndex, vAngle);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Create a rocket entity
    int entityIndex = UTIL_CreateProjectile(vPosition, vAngle, "models/weapons/cso/m32/w_m32_projectile.mdl");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Returns vectors in the direction of an angle
        GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vEntVelocity, vEntVelocity);

        // Apply the magnitude by scaling the vector
        ScaleVector(vEntVelocity, WEAPON_GRENADE_SPEED);

        // Adds two vectors
        AddVectors(vEntVelocity, vVelocity, vEntVelocity);

        // Push the rocket
        TeleportEntity(entityIndex, NULL_VECTOR, NULL_VECTOR, vEntVelocity);

        // Create an effect
        UTIL_CreateParticle(entityIndex, vPosition, _, _, "critical_rocket_red", WEAPON_EFFECT_TIME);

        // Sets parent for the entity
        SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
        SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
        SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);

        // Sets gravity
        SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", WEAPON_GRENADE_GRAVITY); 

        // Create touch hook
        SDKHook(entityIndex, SDKHook_Touch, GrenadeTouchHook);
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
        GetEntProp(%2, Prop_Send, "m_iClip1"), \
                                \
        GetEntProp(%2, Prop_Send, "m_iPrimaryReserveAmmoCount"), \
                                \
        GetEntProp(%2, Prop_Data, "m_iReloadHudHintCount"), \
                                \
        GetGameTime()           \
    )
    
/**
 * @brief Called after a custom weapon is created.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Reset variables
        SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", RELOAD_START);
    }
}     
    
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
        // Call event
        _call.Think(clientIndex, weaponIndex);

        // Button reload press
        if(iButtons & IN_RELOAD)
        {
            // Call event
            _call.Reload(clientIndex, weaponIndex);
            iButtons &= (~IN_RELOAD); //! Bugfix
            return Plugin_Changed;
        }
        
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }
        
        // Button secondary attack press
        if(iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
        
        // Call event
        _call.Idle(clientIndex, weaponIndex);
    }
    
    // Allow button
    return Plugin_Continue;
}

//**********************************************
//* Item (grenade) hooks.                       *
//**********************************************

/**
 * @brief Grenade touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action GrenadeTouchHook(int entityIndex, int targetIndex)
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

        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
        
        // Create an explosion
        UTIL_CreateExplosion(vPosition, /*EXP_NOFIREBALL | */EXP_NOSOUND, _, WEAPON_GRENADE_DAMAGE, WEAPON_GRENADE_RADIUS, "m32", throwerIndex, entityIndex);

        // Play sound
        ZP_EmitSoundToAll(gSound, 2, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

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