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
    name            = "[ZP] Weapon: ChainSaw",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about extra items.
 **/
#define EXTRA_ITEM_REFERENCE         "chainsaw" // Name in weapons.ini from translation file     
#define EXTRA_ITEM_INFO              "chainsaw info" // Only will be taken from translation file 
#define EXTRA_ITEM_COST              20
#define EXTRA_ITEM_LEVEL             1
#define EXTRA_ITEM_ONLINE            1
#define EXTRA_ITEM_LIMIT             0
#define EXTRA_ITEM_GROUP             ""
/**
 * @endsection
 **/

/**
 * @section Information about weapon.
 **/
#define WEAPON_SLASH_DAMAGE            100.0
#define WEAPON_STAB_DAMAGE             50.0
#define WEAPON_SLASH_DISTANCE          80.0
#define WEAPON_STAB_DISTANCE           90.0
/**
 * @endsection
 **/

// Initialize variables
Handle Task_IdleUpdate[MAXPLAYERS+1] = INVALID_HANDLE; 
Handle Task_Stab[MAXPLAYERS+1] = INVALID_HANDLE; 
 
// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

// Variables for the key sound block
int gSoundAttack; int gSoundHit; ConVar hSoundLevel;

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_DUMMY,
    ANIM_EMPTY_IDLE,
    ANIM_EMPTY_SHOOT1,
    ANIM_EMPTY_RELOAD,
    ANIM_EMPTY_DRAW,
    ANIM_ATTACK_END,
    ANIM_ATTACK_LOOP1,
    ANIM_ATTACK_LOOP2,
    ANIM_ATTACK_START,
    ANIM_EMPTY_SHOOT2
};

// Weapon states
enum
{
    STATE_BEGIN,
    STATE_ATTACK
}

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
 * The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timers
        Task_IdleUpdate[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
        Task_Stab[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE 
    }
}

/**
 * Called when a client is disconnecting from the server.
 *
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Delete timers
    delete Task_IdleUpdate[clientIndex];
    delete Task_Stab[clientIndex];
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
    gSoundAttack = ZP_GetSoundKeyID("CHAINSAW_SHOOT_SOUNDS");
    gSoundHit = ZP_GetSoundKeyID("CHAINSAW_HIT_SOUNDS");
    
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
        ZP_GiveClientWeapon(clientIndex, EXTRA_ITEM_REFERENCE, SLOT_PRIMARY);
    }
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnReload(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iChargeReady, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponReload(gWeapon));
}

void Weapon_OnHolster(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iChargeReady, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime
    
    // Validate mode
    if(iChargeReady > STATE_BEGIN)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime);
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate ammo
    if(iClip < ZP_GetWeaponClip(gWeapon))
    {
        // Sets the reload animation
        ZP_SetWeaponAnimation(clientIndex, !iClip ? ANIM_EMPTY_RELOAD : ANIM_RELOAD); 

        /// Reset for allowing reload
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
        
        // Create a muzzleflesh / True for getting the custom viewmodel index
        FakeDispatchEffect(ZP_GetClientViewModel(clientIndex, true), "weapon_muzzle_smoke_long", "ParticleEffect", _, _, _, 2);
        TE_SendToClient(clientIndex);
    }
}

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iChargeReady, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime

    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, !iClip ? ANIM_EMPTY_DRAW : ANIM_DRAW); 
    
    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

    // Sets the attack state
    SetEntProp(weaponIndex, Prop_Send, "m_iIronSightMode", STATE_BEGIN);
    
    // Sets the shots counter
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);

    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(const int clientIndex, const int weaponIndex, int iClip, const int iAmmo, const int iChargeReady, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime

    // Validate ammo
    if(iClip <= 0)
    {
        // Validate mode
        if(iChargeReady > STATE_BEGIN)
        {
            Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime);
        }
        else
        {
            Weapon_OnSecondaryAttack(clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime);
        }
        return;
    }
    
    // Resets the empty sound
    SetEntProp(weaponIndex, Prop_Data, "m_bFireOnEmpty", false);

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime);
        return;
    }

    // Switch mode
    switch(iChargeReady)
    {
        case STATE_BEGIN :
        {
            // Sets the begin animation
            ZP_SetWeaponAnimation(clientIndex, ANIM_ATTACK_START);        

            // Sets the attack state
            SetEntProp(weaponIndex, Prop_Send, "m_iIronSightMode", STATE_ATTACK);

            // Sets the next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + 0.4);
        }

        case STATE_ATTACK :
        {
            // Sets the attack animation
            ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_ATTACK_LOOP1, ANIM_ATTACK_LOOP2 });   

            // Substract ammo
            iClip -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip); if(!iClip)
            {
                Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime);
                return;
            }

            // Emit the attack sound
            static char sSound[PLATFORM_MAX_PATH];
            ZP_GetSound(gSoundAttack, sSound, sizeof(sSound), 1);
            EmitSoundToAll(sSound, weaponIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);

            // Sets the next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponSpeed(gWeapon));           

            // Sets the shots count
            SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
            
            // Create a melee attack
            Weapon_OnSlash(clientIndex, weaponIndex, 0.0, true);

            // Create a muzzleflesh / True for getting the custom viewmodel index
            FakeDispatchEffect(ZP_GetClientViewModel(clientIndex, true), "weapon_muzzle_smoke", "ParticleEffect", _, _, _, 3);
            TE_SendToClient(clientIndex);
            
            // Initialize some variables
            static float vVelocity[3]; int iFlags = GetEntityFlags(clientIndex);

            // Gets the client velocity
            GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

            // Apply kick back
            if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
            {
                Weapon_OnKickBack(clientIndex, 6.5, 5.45, 5.225, 5.05, 6.5, 7.5, 7);
            }
            else if(!(iFlags & FL_ONGROUND))
            {
                Weapon_OnKickBack(clientIndex, 7.0, 5.0, 5.5, 5.35, 14.0, 11.0, 5);
            }
            else if(iFlags & FL_DUCKING)
            {
                Weapon_OnKickBack(clientIndex, 5.9, 5.35, 5.15, 5.025, 10.5, 6.5, 9);
            }
            else
            {
                Weapon_OnKickBack(clientIndex, 5.0, 5.375, 5.175, 5.0375, 10.75, 1.75, 8);
            }
        }
    }
}

void Weapon_OnSecondaryAttack(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iChargeReady, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime);
        return;
    }

    // Validate mode
    if(iChargeReady > STATE_BEGIN)
    {
        Weapon_OnEndAttack(clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime);
        return;
    }

    // Validate no ammo
    if(!iClip)
    {
        // Sets the attack animation  
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_EMPTY_SHOOT1, ANIM_EMPTY_SHOOT2 });    

        // Emit the attack sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSoundAttack, sSound, sizeof(sSound), 4);
        EmitSoundToAll(sSound, weaponIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }
    else
    {
        // Sets the attack animation
        ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT1, ANIM_SHOOT2 });     

        // Emit the attack sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSoundAttack, sSound, sizeof(sSound), GetRandomInt(2, 3));
        EmitSoundToAll(sSound, weaponIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    }

    // Create timer for stab
    delete Task_Stab[clientIndex];
    Task_Stab[clientIndex] = CreateTimer(0.105, Weapon_OnStab, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + 1.2);  
}

/*void Weapon_OnIdle(const int clientIndex, const int weaponIndex, int iClip, const int iAmmo, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, flCurrentTime
    
    // Validate reload complete
    if(GetEntProp(weaponIndex, Prop_Send, "m_bReloadVisuallyComplete"))
    {
        // Block the real attack
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
        
        // Reset completing
        SetEntProp(weaponIndex, Prop_Send, "m_bReloadVisuallyComplete", false);
    }
}*/

void Weapon_OnKickBack(const int clientIndex, float upBase, float lateralBase, const float upMod, const float lateralMod, float upMax, float lateralMax, const int directionChange)
{
    #pragma unused clientIndex, upBase, lateralBase, upMod, lateralMod, upMax, lateralMax, directionChange 

    // Initialize some variables
    int iDirection; int iShotsFired; static float vPunchAngle[3];
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

    // Sets a punch angles
    SetEntPropVector(clientIndex, Prop_Send, "m_aimPunchAngle", vPunchAngle);
    SetEntPropVector(clientIndex, Prop_Send, "m_viewPunchAngle", vPunchAngle);
}

void Weapon_OnSlash(const int clientIndex, const int weaponIndex, const float flRightShift, const bool bSlash)
{    
    #pragma unused clientIndex, weaponIndex, flRightShift, bSlash

    // Initialize variables
    static float vPosition[3]; static float vEndPosition[3];  static float vPlaneNormal[3]; static char sSound[PLATFORM_MAX_PATH];

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 10.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, bSlash ? WEAPON_SLASH_DISTANCE : WEAPON_STAB_DISTANCE, flRightShift, 10.0, vEndPosition);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter, clientIndex);

    // Validate collisions
    if(TR_GetFraction(hTrace) >= 1.0)
    {
        // Initialize the hull intersection
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter, clientIndex);
    }
    
    // Validate collisions
    if(TR_GetFraction(hTrace) < 1.0)
    {
        // Gets the victim index
        int victimIndex = TR_GetEntityIndex(hTrace);

        // Returns the collision position/angle of a trace result
        TR_GetEndPosition(vEndPosition, hTrace);
        TR_GetPlaneNormal(hTrace, vPlaneNormal); 

        // Validate victim
        if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
        {    
            // Create the damage for a victim
            ZP_TakeDamage(victimIndex, clientIndex, bSlash ? WEAPON_SLASH_DAMAGE : WEAPON_STAB_DAMAGE, DMG_NEVERGIB, weaponIndex);
            
            // Emit the hit sound
            ZP_GetSound(gSoundHit, sSound, sizeof(sSound), GetRandomInt(3, 4));
            EmitSoundToAll(sSound, victimIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);

            // Gets the weapon position
            ZP_GetPlayerGunPosition(victimIndex, 0.0, 0.0, -45.0, vPosition);
            
            // Create a blood effect
            FakeCreateParticle(victimIndex, vPosition, _, "blood", 0.3);
        }
        else
        {
            // Create a sparks effect
            TE_SetupSparks(vEndPosition, vPlaneNormal, 50, 2);
            TE_SendToAllInRange(vEndPosition, RangeType_Visibility);

            // Emit the hit sound
            ZP_GetSound(gSoundHit, sSound, sizeof(sSound), GetRandomInt(1, 2));
            EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        }
    }
    
    // Close the trace
    delete hTrace;
}

void Weapon_OnEndAttack(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const int iChargeReady, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, iChargeReady, flCurrentTime

    // Validate mode
    if(iChargeReady > STATE_BEGIN)
    {
        // Sets the begin animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_ATTACK_END);        

        // Sets the begin state
        SetEntProp(weaponIndex, Prop_Send, "m_iIronSightMode", STATE_BEGIN);

        // Sets the next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + 1.7);

        // Create timer for updating idle animation 
        delete Task_IdleUpdate[clientIndex]; /// Bugfix
        Task_IdleUpdate[clientIndex] = CreateTimer(1.5, Weapon_OnReset, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * Timer for stab effect.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnStab(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); int weaponIndex;

    // Clear timer 
    Task_Stab[clientIndex] = INVALID_HANDLE;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {    
        float flRightShift = -14.0;
        for(int i = 0; i < 15; i++)
        {
            // Do slash
            Weapon_OnSlash(clientIndex, weaponIndex, flRightShift += 4.0, false);
        }
    }

    // Destroy timer
    return Plugin_Stop;
}

/**
 * Timer for idle update.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnReset(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); int weaponIndex;

    // Clear timer 
    Task_IdleUpdate[clientIndex] = INVALID_HANDLE;
    
    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {    
        // Sets the idle animation
        ZP_SetWeaponAnimation(clientIndex, !GetEntProp(weaponIndex, Prop_Send, "m_iClip1") ? ANIM_EMPTY_IDLE : ANIM_IDLE); 
    }

    // Destroy timer
    return Plugin_Stop;
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
        GetEntProp(%2, Prop_Send, "m_iIronSightMode"), \
                                \
        GetGameTime() \
    )

/**
 * Called once a client is authorized and fully in-game, and 
 * after all post-connection authorizations have been performed.  
 *
 * This callback is gauranteed to occur on all clients, and always 
 * after each OnClientPutInServer() call.
 * 
 * @param clientIndex       The client index. 
 **/
public void OnClientPostAdminCheck(int clientIndex)
{
    // Hook entity callbacks
    SDKHook(clientIndex, SDKHook_WeaponSwitchPost, WeaponOnDeployPost);
}

/**
 * Called after a custom weapon is created.
 *
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Hook entity callbacks
        SDKHook(weaponIndex, SDKHook_ReloadPost, WeaponOnReloadPost);
    }
}

/**
 * Hook: WeaponSwitchPost
 * Player deploy any weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 **/
public void WeaponOnDeployPost(const int clientIndex, const int weaponIndex) 
{
    // Delete timers
    delete Task_IdleUpdate[clientIndex];
    delete Task_Stab[clientIndex];
    
    // Apply fake deploy hook on the next frame
    RequestFrame(view_as<RequestFrameCallback>(WeaponOnFakeDeployPost), GetClientUserId(clientIndex));
}

/**
 * FakeHook: WeaponSwitchPost
 *
 * @param userID            The user id.
 **/
public void WeaponOnFakeDeployPost(const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); int weaponIndex;

    // Validate weapon
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        // Call event
        _call.Deploy(clientIndex, weaponIndex);
    }
}

/**
 * Hook: WeaponReloadPost
 * Weapon is reloaded.
 *
 * @param weaponIndex       The weapon index.
 **/
public Action WeaponOnReloadPost(const int weaponIndex) 
{
    // Apply fake reload hook on the next frame
    RequestFrame(view_as<RequestFrameCallback>(WeaponOnFakeReloadPost), EntIndexToEntRef(weaponIndex));
}

/**
 * FakeHook: WeaponReloadPost
 *
 * @param referenceIndex    The reference index.
 **/
public void WeaponOnFakeReloadPost(const int referenceIndex) 
{
    // Get the weapon index from the reference
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate weapon
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Gets the weapon owner
        int clientIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hOwner");

        // Validate owner
        if(IsPlayerExist(clientIndex))
        {
            // Call event
            _call.Reload(clientIndex, entityIndex);
        }
    }
}

/**
 * Event: WeaponPostFrame
 * Weapon is holding.
 *  
 * @param clientIndex       The client index.
 * @param iButtons          Copyback buffer containing the current commands (as bitflags - see entity_prop_stocks.inc).
 * @param iImpulse          Copyback buffer containing the current impulse command.
 * @param flVelocity        Players desired velocity.
 * @param flAngles          Players desired view angles.    
 * @param weaponID          The entity index of the new weapon if player switches weapon, 0 otherwise.
 * @param iSubType          Weapon subtype when selected from a menu.
 * @param iCmdNum           Command number. Increments from the first command sent.
 * @param iTickCount        Tick count. A client prediction based on the server GetGameTickCount value.
 * @param iSeed             Random seed. Used to determine weapon recoil, spread, and other predicted elements.
 * @param iMouse            Mouse direction (x, y).
 **/ 
public Action OnPlayerRunCmd(int clientIndex, int &iButtons, int &iImpulse, float flVelocity[3], float flAngles[3], int &weaponID, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
    // Validate weapon
    static int weaponIndex;
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        // Initialize variable
        static int iLastButtons[MAXPLAYERS+1];

        // Call event
        ///_call.Idle(clientIndex, weaponIndex);
        
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            iLastButtons[clientIndex] = iButtons; iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }
        // Button primary attack release
        else if(iLastButtons[clientIndex] & IN_ATTACK)
        {
            // Call event
            _call.EndAttack(clientIndex, weaponIndex);
        }

        // Button secondary attack press
        if(iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iLastButtons[clientIndex] = iButtons; iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }

        // Button reload press
        if(iButtons & IN_RELOAD)
        {
            // Validate overtransmitting
            if(!(iLastButtons[clientIndex] & IN_RELOAD))
            {
                // Call event
                _call.Holster(clientIndex, weaponIndex);
            }
        }
        
        // Store the current button
        iLastButtons[clientIndex] = iButtons;
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * Trace filter.
 *  
 * @param entityIndex       The entity index.
 * @param contentsMask      The contents mask.
 * @param clientIndex       The client index.
 *
 * @return                  True or false.
 **/
public bool TraceFilter(const int entityIndex, const int contentsMask, const int clientIndex)
{
    // If entity is a player, continue tracing
    return (entityIndex != clientIndex);
}