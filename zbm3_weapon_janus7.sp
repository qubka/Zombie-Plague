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
    name            = "[ZP] Weapon: Janus VII",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "3.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
#define WEAPON_ITEM_REFERENCE       "janus7" // Name in weapons.ini from translation file
#define WEAPON_TIME_DELAY_SWITCH    2.2
#define WEAPON_SIGNAL_COUNTER       100
#define WEAPON_ACTIVE_COUNTER       100
#define WEAPON_BEAM_DAMAGE          1.0
#define WEAPON_BEAM_RADIUS          500.0
#define WEAPON_BEAM_SHAKE_AMP       10.0
#define WEAPON_BEAM_SHAKE_FREQUENCY 1.0
#define WEAPON_BEAM_SHAKE_DURATION  2.0
#define WEAPON_BEAM_COLOR           {255, 186, 0, 255}
#define WEAPON_BEAM_MODEL           "materials/sprites/laserbeam.vmt"
/**
 * @endsection
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT1,
    ANIM_SHOOT2,
    ANIM_RELOAD,
    ANIM_DRAW,
    ANIM_SHOOT_SIGNAL,
    ANIM_CHANGE,
    ANIM_IDLE2,
    ANIM_DRAW2,
    ANIM_SHOOT2_1,
    ANIM_SHOOT2_2,
    ANIM_CHANGE2,
    ANIM_IDLE_SIGNAL,
    ANIM_RELOAD_SIGNAL,
    ANIM_DRAW_SIGNAL
};

// Weapon states
enum
{
    STATE_NORMAL,
    STATE_SIGNAL,
    STATE_ACTIVE
}

// Weapon index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel

// Decal index
int decalBeam;

/**
 * Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Initialize weapon
    gWeapon = ZP_GetWeaponNameID(WEAPON_ITEM_REFERENCE);
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"%s\" wasn't find", WEAPON_ITEM_REFERENCE);

    // Sounds
    gSound = ZP_GetSoundKeyID("JANUSVII2_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"JANUSVII2_SHOOT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    
    // Models
    decalBeam = PrecacheModel(WEAPON_BEAM_MODEL, true);
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(const int clientIndex, const int weaponIndex, const int iCounter, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
}

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const int iCounter, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime

    // Validate mode
    if(iStateMode == STATE_ACTIVE)
    {
        /// Block the real attack
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    }
    
    // Sets the draw animation
    ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_DRAW2 : (iStateMode == STATE_SIGNAL) ? ANIM_DRAW_SIGNAL : ANIM_DRAW); 

    // Sets the shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", 0);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnShoot(const int clientIndex, const int weaponIndex, int iCounter, const int iStateMode, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Validate counter
    if(iCounter > WEAPON_SIGNAL_COUNTER)
    {
        // Sets the signal mode
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_SIGNAL);

        // Resets the shots count
        iCounter = -1;
        
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
    }
    
    // Sets the shots count
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", iCounter + 1);
}

bool Weapon_OnPrimaryAttack(const int clientIndex, const int weaponIndex, const int iCounter, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode != STATE_ACTIVE)
    {
        return false;
    }

    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
    // Validate counter
    if(iCounter > WEAPON_ACTIVE_COUNTER)
    {
        Weapon_OnFinish(clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime);
        return false;
    }

    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return false;
    }
    
    // Validate water
    if(GetEntProp(clientIndex, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return false;
    }
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

    // Sets the shots count
    SetEntProp(clientIndex, Prop_Send, "m_iShotsFired", GetEntProp(clientIndex, Prop_Send, "m_iShotsFired") + 1);
    
    // Sets the shots count
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", iCounter + 1);
    
    // Emit sound
    static char sSound[PLATFORM_MAX_PATH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
    EmitSoundToAll(sSound, clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
    
    // Sets the attack animation
    ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2});
    
    // Create a beam
    Weapon_OnCreateBeam(clientIndex, weaponIndex);

    // Initialize some variables
    static float vVelocity[3]; static int iFlags; iFlags = GetEntityFlags(clientIndex);

    // Gets the client velocity
    GetEntPropVector(clientIndex, Prop_Data, "m_vecVelocity", vVelocity);

    // Apply kick back
    if(!(SquareRoot(Pow(vVelocity[0], 2.0) + Pow(vVelocity[1], 2.0))))
    {
        Weapon_OnKickBack(clientIndex, 7.5, 4.5, 0.225, 0.05, 10.5, 7.5, 7);
    }
    else if(!(iFlags & FL_ONGROUND))
    {
        Weapon_OnKickBack(clientIndex, 10.0, 7.0, 0.5, 0.35, 14.0, 10.0, 5);
    }
    else if(iFlags & FL_DUCKING)
    {
        Weapon_OnKickBack(clientIndex, 7.5, 4.5, 0.15, 0.025, 10.5, 6.5, 9);
    }
    else
    {
        Weapon_OnKickBack(clientIndex, 6.75, 6.75, 0.175, 0.0375, 10.75, 10.75, 8);
    }
    
    // Return on the success
    return true;
}

void Weapon_OnSecondaryAttack(const int clientIndex, const int weaponIndex, const int iCounter, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Validate mode
    if(iStateMode == STATE_SIGNAL)
    {
        /// Block the real attack
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    
        // Sets the change animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE);        

        // Sets the active state
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_ACTIVE);
        
        // Resets the shots count
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);
        
        // Adds the delay to the game tick
        flCurrentTime += WEAPON_TIME_DELAY_SWITCH;
        
        // Sets the next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime); 
        
        // Remove the delay to the game tick
        flCurrentTime -= 0.5;
        
        // Sets the switching time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
    }
}

void Weapon_OnFinish(const int clientIndex, const int weaponIndex, const int iCounter, const int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, iCounter, iStateMode, flCurrentTime
    
    // Sets the change animation
    ZP_SetWeaponAnimation(clientIndex, ANIM_CHANGE2);        

    // Sets the active state
    SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_NORMAL);
    
    // Resets the shots count
    SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_SWITCH;
    
    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
}

void Weapon_OnCreateBeam(const int clientIndex, const int weaponIndex)
{
    #pragma unused clientIndex
    
    // Initialize variables
    static float vPosition[3]; static float vAngle[3]; static float vVictimPosition[3]; bool bFound;

    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 30.0, 10.0, -10.0, vPosition);

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if((IsPlayerExist(i) && ZP_IsPlayerZombie(i)))
        {
            // Gets the center position
            ZP_GetPlayerGunPosition(i, 0.0, 0.0, -45.0, vVictimPosition);

            // Calculate the distance
            float flDistance = GetVectorDistance(vPosition, vVictimPosition);

            // Validate distance
            if(flDistance <= WEAPON_BEAM_RADIUS)
            {
                // Validate visibility
                if(!TraceRay(clientIndex, vPosition, vVictimPosition, flDistance))
                {
                    continue;
                }

                // Create the damage for a victim
                ZP_TakeDamage(i, clientIndex, WEAPON_BEAM_DAMAGE, DMG_BURN);

                // Create a shake
                FakeCreateShakeScreen(i, WEAPON_BEAM_SHAKE_AMP, WEAPON_BEAM_SHAKE_FREQUENCY, WEAPON_BEAM_SHAKE_DURATION);
                
                // Sets the found state
                bFound = true; 
                break;
            }
        }
    }

    // Found the aim origin
    if(!bFound)
    {
        // Gets client eye angle
        GetClientEyeAngles(clientIndex, vAngle);

        // Calculate aim end-vector
        TR_TraceRayFilter(vPosition, vAngle, MASK_SHOT, RayType_Infinite, TraceFilter, clientIndex);
        TR_GetEndPosition(vVictimPosition);
    }

    // Gets the beam lifetime
    float flLife = ZP_GetWeaponSpeed(gWeapon);
    
    // Sent a beam
    TE_SetupBeamPoints(vPosition, vVictimPosition, decalBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 3.0, WEAPON_BEAM_COLOR, 30);
    TE_SendToClient(clientIndex);
    
    // Gets the worldmodel index
    int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hWeaponWorldModel");
    
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Gets attachment position
        ZP_GetAttachment(entityIndex, "muzzle_flash", vPosition, vAngle);
        
        // Sent a beam
        TE_SetupBeamPoints(vPosition, vVictimPosition, decalBeam, 0, 0, 0, flLife, 2.0, 2.0, 10, 3.0, WEAPON_BEAM_COLOR, 30);
        int[] iClients = new int[MaxClients]; int iCount;
        for (int i = 1; i <= MaxClients; i++)
        {
            if(!IsPlayerExist(i, false) || i == clientIndex || IsFakeClient(i)) continue;
            iClients[iCount++] = i;
        }
        TE_Send(iClients, iCount);
    }
}

void Weapon_OnKickBack(const int clientIndex, float upBase, float lateralBase, const float upMod, const float lateralMod, float upMax, float lateralMax, const int directionChange)
{
    #pragma unused clientIndex, upBase, lateralBase, upMod, lateralMod, upMax, lateralMax, directionChange 

    // Initialize some variables
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
        GetEntProp(%2, Prop_Send, "m_iClip2"), \
                                \
        GetEntProp(%2, Prop_Data, "m_iIKCounter"), \
                                \
        GetGameTime()           \
    )    

/**
 * Called after a custom weapon is created.
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
        SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_NORMAL);
        SetEntProp(weaponIndex, Prop_Send, "m_iClip2", 0);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
    }
} 
    
/**
 * Called on deploy of a weapon.
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
 * Called on holster of a weapon.
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
 * Called on shoot of a weapon.
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


/**
 * Called on each frame of a weapon holding.
 *
 * @param clientIndex       The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Change) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID)
{
    // Validate custom weapon
    if(weaponID == gWeapon)
    {
        // Time to apply new mode
        static float flApplyModeTime;
        if((flApplyModeTime = GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer")) != 0.0 && flApplyModeTime <= GetGameTime())
        {
            // Resets the switching time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets the active state
            SetEntProp(weaponIndex, Prop_Data, "m_iIKCounter", STATE_ACTIVE);
        }
        else
        {
            // Validate state
            static int iStateMode;
            if((iStateMode = GetEntProp(weaponIndex, Prop_Data, "m_iIKCounter")))
            {
                // Switch animation
                switch(ZP_GetWeaponAnimation(clientIndex))
                {
                    case ANIM_IDLE : ZP_SetWeaponAnimation(clientIndex, (iStateMode == STATE_ACTIVE) ? ANIM_IDLE2 : ANIM_IDLE_SIGNAL);
                    case ANIM_SHOOT1, ANIM_SHOOT2 : if(iStateMode == STATE_ACTIVE) ZP_SetWeaponAnimationPair(clientIndex, weaponIndex, { ANIM_SHOOT2_1, ANIM_SHOOT2_2 }); else ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT_SIGNAL); 
                    case ANIM_RELOAD : ZP_SetWeaponAnimation(clientIndex, ANIM_RELOAD_SIGNAL); 
                }
            }
        }

        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            if(_call.PrimaryAttack(clientIndex, weaponIndex))
            {
                iButtons &= (~IN_ATTACK); //! Bugfix
                return Plugin_Changed;
            }
        }
        
        // Button secondary attack press
        else if(iButtons & IN_ATTACK2)
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
 * @brief Starts up a new trace ray using a new trace result and a customized trace ray filter. 
 *
 * @param filterIndex       The filter index. 
 * @param vStartPosition    The starting position of the ray.
 * @param vEndPosition      The ending position of the ray.      
 * @param flDistance        (Optional) The distance amount. 
 * @param flLenth           (Optional) The current distance between positions' vectors output. (Squared)
 *
 * @return                  True of false.        
 **/
stock bool TraceRay(const int filterIndex, const float vStartPosition[3], const float vEndPosition[3], const float flDistance = 0.0, float &flLenth = 0.0)
{
    // Store the current distance between positions' vectors
    flLenth = GetVectorDistance(vStartPosition, vEndPosition);
    
    // Validate distance
    if(flDistance != 0.0 && flLenth > flDistance)
    {
        return false;
    }
    
    // Initialize boolean
    bool bTrace = true;

    // Starts up a new trace ray using a new trace result and a customized trace ray filter
    Handle hTrace = TR_TraceRayFilterEx(vStartPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter, filterIndex);

    // Validate trace
    if(hTrace != INVALID_HANDLE)
    {
        // Validate any kind of collision along the trace ray
        if(TR_DidHit(hTrace))
        {
            // If trace hit, then stop
            bTrace = false;
        }
        
        // Close trace handle
        delete hTrace;
    }
    
    // Return on the end
    return bTrace;
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
    return (entityIndex == clientIndex || !(1 <= entityIndex <= MaxClients));
}