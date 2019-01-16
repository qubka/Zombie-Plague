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
    name            = "[ZP] Weapon: PlasmaGun",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_PLASMA_SPEED             2000.0
#define WEAPON_PLASMA_GRAVITY           0.01
#define WEAPON_PLASMA_RADIUS            200.0
#define WEAPON_PLASMA_EXPLOSION         0.1
#define WEAPON_PLASMA_SHAKE_AMP         10.0
#define WEAPON_PLASMA_SHAKE_FREQUENCY   1.0
#define WEAPON_PLASMA_SHAKE_DURATION    2.0
#define WEAPON_EFFECT_TIME              5.0
#define WEAPON_EXPLOSION_TIME           2.0
/**
 * @endsection
 **/

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_SHOOT3,
    ANIM_RELOAD,
    ANIM_DRAW
};

// Item index
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
    gWeapon = ZP_GetWeaponNameID("plasmagun");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"plasmagun\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("PLASMAGUN_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"PLASMAGUN_SHOOT_SOUNDS\" wasn't find");
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnReload(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponReload(gWeapon));
}

void Weapon_OnReloadStart(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }
    
    // Validate ammo
    if(!iAmmo)
    {
        return;
    }

    // Validate clip
    if(iClip < ZP_GetWeaponClip(gWeapon))
    {
        // Sets reload animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_RELOAD); 

        // Reset for allowing reload
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    }
}

bool Weapon_OnReloadEmulate(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, flCurrentTime
    
    // Validate reload
    return !iClip && iAmmo ? true : false;
}

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iClip, const int iAmmo, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, flCurrentTime

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(const int clientIndex, const int weaponIndex, int iClip, const int iAmmo, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iClip, iAmmo, flCurrentTime

    // Validate ammo
    if(iClip <= 0)
    {
        return;
    }
    
    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }

    // Substract ammo
    iClip -= 1; SetEntProp(weaponIndex, Prop_Send, "m_iClip1", iClip); 
    if(!iClip) SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + 1.5);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);       

    // Sets shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
    
    // Emit sound
    static char sSound[PLATFORM_LINE_LENGTH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
    EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT1, ANIM_SHOOT2 });   

    // Create a plasma
    Weapon_OnCreatePlasma(clientIndex, weaponIndex);

    // Initialize variables
    static float vVelocity[3]; static int iFlags; iFlags = GetEntityFlags(clientIndex);

    // Gets client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        Weapon_OnKickBack(clientIndex, 5.5, 2.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        Weapon_OnKickBack(clientIndex, 9.0, 5.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        Weapon_OnKickBack(clientIndex, 5.5, 1.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        Weapon_OnKickBack(clientIndex, 5.75, 5.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }
}

void Weapon_OnCreatePlasma(const int clientIndex, const int weaponIndex)
{
    #pragma unused clientIndex

    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEntVelocity[3];

    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 5.0, 0.0, vPosition);

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

        // Returns vectors in the direction of an angle
        GetAngleVectors(vAngle, vEntVelocity, NULL_VECTOR, NULL_VECTOR);

        // Normalize the vector (equal magnitude at varying distances)
        NormalizeVector(vEntVelocity, vEntVelocity);

        // Apply the magnitude by scaling the vector
        ScaleVector(vEntVelocity, WEAPON_PLASMA_SPEED);

        // Adds two vectors
        AddVectors(vEntVelocity, vVelocity, vEntVelocity);

        // Push the rocket
        TeleportEntity(entityIndex, vPosition, vAngle, vEntVelocity);

        // Sets an entity color
        SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
        SetEntityRenderColor(entityIndex, _, _, _, 0);
        DispatchKeyValue(entityIndex, "disableshadows", "1"); /// Prevents the entity from receiving shadows
        
        // Create an effect
        ZP_CreateParticle(entityIndex, vPosition, _, "gamma", WEAPON_EFFECT_TIME);
        
        // Sets parent for the entity
        SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 
        SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", clientIndex);
        SetEntPropEnt(entityIndex, Prop_Send, "m_hThrower", clientIndex);
        SetEntPropEnt(entityIndex, Prop_Send, "m_hEffectEntity", weaponIndex);

        // Sets gravity
        SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", WEAPON_PLASMA_GRAVITY); 

        // Create touch hook
        SDKHook(entityIndex, SDKHook_Touch, PlasmaTouchHook);
    }
}

void Weapon_OnKickBack(const int clientIndex, float upBase, float lateralBase, const float upMod, const float lateralMod, float upMax, float lateralMax, const int directionChange)
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
 * @brief Called on reload of a weapon.
 *
 * @param clientIndex       The client index.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponReload(int clientIndex, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Call event
        _call.Reload(clientIndex, weaponIndex);
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
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK); //! Bugfix
            return Plugin_Changed;
        }

        // Button reload press
        if(iButtons & IN_RELOAD)
        {
            // Validate overtransmitting
            if(!(iLastButtons & IN_RELOAD))
            {
                // Call event
                _call.ReloadStart(clientIndex, weaponIndex);
            }
        }
        else
        {
            // Call event
            if(_call.ReloadEmulate(clientIndex, weaponIndex))
            {
                iButtons |= IN_RELOAD; //! Bugfix
                return Plugin_Changed;
            }
        }
    }
    
    // Allow button
    return Plugin_Continue;
}

//**********************************************
//* Item (rocket) hooks.                       *
//**********************************************

/**
 * @brief Plasma touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action PlasmaTouchHook(const int entityIndex, const int targetIndex)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
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

            // Initialize vectors
            static float vEntPosition[3]; static float vVictimPosition[3]; static float vVelocity[3];

            // Gets entity position
            GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

            // Create a info_target entity
            int infoIndex = ZP_CreateEntity(vEntPosition, WEAPON_EXPLOSION_TIME);
            
            // Validate entity
            if(IsValidEdict(infoIndex))
            {
                // Create an explosion effect
                ZP_CreateParticle(infoIndex, vEntPosition, _, "explosion_molotov_air", WEAPON_EXPLOSION_TIME);
                
                // Emit sound
                static char sSound[PLATFORM_LINE_LENGTH];
                ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
                EmitSoundToAll(sSound, infoIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
            }

            // i = client index
            for(int i = 1; i <= MaxClients; i++)
            {
                // Validate client
                if((IsPlayerExist(i) && ZP_IsPlayerZombie(i)))
                {
                    // Gets victim origin
                    GetClientAbsOrigin(i, vVictimPosition);

                    // Calculate the distance
                    float flDistance = GetVectorDistance(vEntPosition, vVictimPosition);

                    // Validate distance
                    if(flDistance <= WEAPON_PLASMA_RADIUS)
                    {
                        // Create the damage for a victim
                        ZP_TakeDamage(i, throwerIndex, ZP_GetWeaponDamage(gWeapon) * (1.0 - (flDistance / WEAPON_PLASMA_RADIUS)), DMG_AIRBOAT);

                        // Calculate the velocity vector
                        SubtractVectors(vVictimPosition, vEntPosition, vVelocity);
                
                        // Create a knockback
                        ZP_CreateRadiusKnockBack(i, vVelocity, flDistance, ZP_GetWeaponKnockBack(gWeapon), WEAPON_PLASMA_RADIUS);
                        
                        // Create a shake
                        ZP_CreateShakeScreen(i, WEAPON_PLASMA_SHAKE_AMP, WEAPON_PLASMA_SHAKE_FREQUENCY, WEAPON_PLASMA_SHAKE_DURATION);
                    }
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
        // Validate custom arrow
        if(ZP_GetWeaponID(entityIndex) == gWeapon)
        {
            // Block sounds
            return Plugin_Stop; 
        }
    }
    
    // Allow sounds
    return Plugin_Continue;
}