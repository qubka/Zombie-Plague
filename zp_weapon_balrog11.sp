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
    name            = "[ZP] Weapon: Balrog XI",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_FIRE_DAMAGE      50.0
#define WEAPON_FIRE_SPEED       1000.0
#define WEAPON_FIRE_GRAVITY     0.01
#define WEAPON_FIRE_COUNTER     4
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT,
    ANIM_START_RELOAD,
    ANIM_INSERT,
    ANIM_AFTER_RELOAD,
    ANIM_DRAW,
    ANIM_SHOOT_BSC1,
    ANIM_SHOOT_BSC2
};

// Weapon index
int gWeapon;
#pragma unused gWeapon

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
    // Weapons
    gWeapon = ZP_GetWeaponNameID("balrog11");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"balrog11\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("BALROGXI2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"BALROGXI2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int iCounter, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iAmmo, flCurrentTime
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW); 
    
    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
}

void Weapon_OnShoot(int clientIndex, int weaponIndex, int iCounter, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iAmmo, flCurrentTime
    
    // Validate ammo
    if(!GetEntProp(weaponIndex, Prop_Send, "m_iPrimaryReserveAmmoCount"))
    {
        return;
    }
    
    // Validate counter
    if(iCounter > WEAPON_FIRE_COUNTER)
    {
        // Validate clip
        if(iAmmo < ZP_GetWeaponClip(gWeapon))
        {
            // Sets clip count
            SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", iAmmo + 1);
         
            // Emit sound
            static char sSound[PLATFORM_LINE_LENGTH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
            EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            
            // Resets the shots counter
            iCounter = -1;
        }
    }
    
    // Sets shots count
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", iCounter + 1);
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int iCounter, int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iAmmo, flCurrentTime

    // Validate reload
    int iAnim = ZP_GetWeaponAnimation(clientIndex);
    if(iAnim == ANIM_START_RELOAD || iAnim == ANIM_INSERT)
    {
        return;
    }
    
    // Validate ammo
    if(iAmmo <= 0)
    {
        return;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }

    // Substract ammo
    iAmmo -= 1; SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", iAmmo); 

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
 
    // Emit sound
    static char sSound[PLATFORM_LINE_LENGTH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
    EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT_BSC1, ANIM_SHOOT_BSC2 });
    
    // Initialize vectors
    static float vPosition[5][3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 50.0, 60.0, -10.0, vPosition[0]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, 30.0, -10.0, vPosition[1]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, 0.0, -10.0, vPosition[2]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, -30.0, -10.0, vPosition[3]);
    ZP_GetPlayerGunPosition(clientIndex, 50.0, -60.0, -10.0, vPosition[4]);

    // i - fire index
    for(int i = 0; i < 5; i++)
    {
        // Create a fire
        Weapon_OnCreateFire(clientIndex, weaponIndex, vPosition[i]);
    }

    // Initialize variables
    static float vVelocity[3]; static int iFlags; iFlags = GetEntityFlags(clientIndex);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        Weapon_OnKickBack(clientIndex, 10.5, 7.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        Weapon_OnKickBack(clientIndex, 14.0, 10.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        Weapon_OnKickBack(clientIndex, 10.5, 6.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        Weapon_OnKickBack(clientIndex, 10.75, 10.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }
    
    // Gets weapon muzzleflesh
    static char sMuzzle[SMALL_LINE_LENGTH];
    ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
    
    // Create a muzzleflesh / True for getting the custom viewmodel index
    ZP_DispatchEffect(ZP_GetClientViewModel(clientIndex, true), sMuzzle, "ParticleEffect", _, _, _, 1);
    TE_SendToClient(clientIndex);
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
    int entityIndex = CreateEntityByName("hegrenade_projectile");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Spawn the entity
        DispatchSpawn(entityIndex);

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
        TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);
        
        // Sets an entity color
        SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
        SetEntityRenderColor(entityIndex, _, _, _, 0);
        DispatchKeyValue(entityIndex, "disableshadows", "1"); /// Prevents the entity from receiving shadows

        // Sets parent for the entity
        SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
        SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
        SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);
        SetEntPropEnt(entityIndex, Prop_Data, "m_hDamageFilter", weaponIndex);

        // Sets gravity
        SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", WEAPON_FIRE_GRAVITY); 

        // Create touch hook
        SDKHook(entityIndex, SDKHook_Touch, FireTouchHook);
        
        // Create fly hook
        CreateTimer(0.2, FireFlyHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        
        // Create an effect
        ZP_CreateParticle(entityIndex, vPosition, _, "env_fire_medium", 0.2);
    }
}

void Weapon_OnKickBack(int clientIndex, float upBase, float lateralBase, float upMod, float lateralMod, float upMax, float lateralMax, int directionChange)
{
    #pragma unused clientIndex, upBase, lateralBase, upMod, lateralMod, upMax, lateralMax, directionChange 

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

/**
 * @brief Main timer for fly fire hook.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action FireFlyHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Create an effect
        static float vEntPosition[3];
        GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);
        ZP_CreateParticle(entityIndex, vEntPosition, _, "env_fire_large", 0.5);

        // Create think hook
        CreateTimer(0.5, FireRemoveHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Destroy timer
    return Plugin_Stop;
}  
    
/**
 * @brief Main timer for remove fire hook.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action FireRemoveHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Remove the entity from the world
        AcceptEntityInput(entityIndex, "Kill");  
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
        GetEntProp(%2, Prop_Send, "m_iClip2"), \
                                \
        GetEntProp(%2, Prop_Data, "m_iIKCounter"), \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", 0);
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);
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
        // Button secondary attack press
        if(!(iButtons & IN_ATTACK) && iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2); //! Bugfix
            return Plugin_Changed;
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Called on shoot of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponShoot(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Shoot(clientIndex, weaponIndex);
    }
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
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Validate target
        if(IsValidEdict(targetIndex))
        {
            // Gets thrower index
            int throwerIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hThrower");
            int weaponIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_hDamageFilter");
            
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
                    // Create the damage for a victim
                    ZP_TakeDamage(targetIndex, throwerIndex, WEAPON_FIRE_DAMAGE, DMG_NEVERGIB, weaponIndex);
                }
            }
            
            // Remove the entity from the world
            AcceptEntityInput(entityIndex, "Kill");
        }
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
        if(ZP_GetWeaponID(entityIndex) == gWeapon)
        {
            // Block sounds
            return Plugin_Stop; 
        }
    }
    
    // Allow sounds
    return Plugin_Continue;
}