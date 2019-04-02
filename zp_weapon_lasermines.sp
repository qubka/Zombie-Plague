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
    name            = "[ZP] Weapon: LaserMine",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of custom weapon",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about weapon.
 **/
//#define WEAPON_MINE_IMPULSE /// Uncomment to use the classical beam instead.
#define WEAPON_MINE_HEALTH           200     // Mine health. ['0' = never breaked]
#define WEAPON_MINE_EXPLOSION_DAMAGE 300.0   // Mine exp damage
#define WEAPON_MINE_EXPLOSION_RADIUS 150.0   // Mine exp radius 
#define WEAPON_MINE_UPDATE           0.5     // Mine delay (damage delay)
#define WEAPON_MINE_ACTIVATION       2.0     // Mine activation delay
#define WEAPON_MINE_IMPACT           "weapons/taser/taser_hit.wav"   /// Only standart sounds (from engine)
#define WEAPON_MINE_IMPACT_LEVEL     0.5      // Mine impact sound level
#define WEAPON_MINE_SHOOT            "weapons/taser/taser_shoot.wav" /// Only standart sounds (from engine)
#define WEAPON_MINE_SHOOT_LEVEL      0.3      // Mine shoot sound level
#define WEAPON_BEAM_MODEL            "materials/sprites/purplelaser1.vmt"//"materials/sprites/laserbeam.vmt"
#define WEAPON_BEAM_LIFE             0.1
#define WEAPON_BEAM_WIDTH            3.0
#define WEAPON_BEAM_COLOR            {0, 0, 255, 255}
#define WEAPON_BEAM_COLOR_F          "0 0 255" // Non impulse
#define WEAPON_GLOW_COLOR            {0, 255, 0, 255} /// Only for impulse mode, because normal already have a child (beam)
#define WEAPON_GLOW_STYLE            0
#define WEAPON_GLOW_DISTANCE         10000.0
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT                   5.0
#define METAL_GIBS_DELAY                    0.05
#define METAL_GIBS_SPEED                    500.0
#define METAL_GIBS_VARIENCE                 1.0  
#define METAL_GIBS_LIFE                     1.0  
#define METAL_GIBS_DURATION                 2.0
/**
 * @endsection
 **/

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_DEPLOY,
    ANIM_DRAW,
    ANIM_HOLSTER
};

// Timer index
Handle Task_MineCreate[MAXPLAYERS+1] = null; 

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

// Sound index
int gSound; ConVar hSoundLevel;

// Decal index
int decalBeam;
#pragma unused decalBeam

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        #if !defined WEAPON_MINE_IMPULSE
        // Hooks entity events
        HookEntityOutput("env_beam", "OnTouchedByEntity", BeamTouchHook);
        #endif
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Items
    gItem = ZP_GetExtraItemNameID("lasermine");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"lasermine\" wasn't find");
    
    // Weapons
    gWeapon = ZP_GetWeaponNameID("lasermine");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"lasermine\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("LASERMINE_SHOOT_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"LASERMINE_SHOOT_SOUNDS\" wasn't find");
    PrecacheSound(WEAPON_MINE_IMPACT, true);
    PrecacheSound(WEAPON_MINE_SHOOT, true);
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Models
    decalBeam = PrecacheModel(WEAPON_BEAM_MODEL, true);
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
    
    #if defined WEAPON_MINE_IMPULSE
    // Sounds
    PrecacheSound(WEAPON_MINE_IMPACT, true);
    PrecacheSound(WEAPON_MINE_SHOOT, true);
    #endif
    
    // Effects
    PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
}

/**
 * @brief Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param extraitemIndex    The item index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
public Action ZP_OnClientValidateExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
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
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, gWeapon);
    }
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Purge timer
        Task_MineCreate[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * @brief Called when a client is disconnecting from the server.
 * 
 * @param clientIndex       The client index.
 **/
public void OnClientDisconnect(int clientIndex)
{
    // Delete timers
    delete Task_MineCreate[clientIndex];
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int clientIndex, int weaponIndex, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime
    
    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime

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
    
    // Adds the delay to the game tick
    flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3];
    
    // Gets trace line
    GetClientEyePosition(clientIndex, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, TraceFilter2);

    // Validate collisions
    if(TR_DidHit() && TR_GetEntityIndex() < 1)
    {
        // Sets deploy animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_DEPLOY);

        // Create timer for mine
        delete Task_MineCreate[clientIndex]; /// Bugfix
        Task_MineCreate[clientIndex] = CreateTimer(ZP_GetWeaponSpeed(gWeapon), Weapon_OnCreateMine, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

bool Weapon_OnPickupMine(int clientIndex, int entityIndex, float flCurrentTime)
{
    #pragma unused clientIndex, entityIndex, flCurrentTime

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; bool bSuccess;
    
    // Gets trace line
    GetClientEyePosition(clientIndex, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, TraceFilter2);
    
    // Returns the collision position of a trace result
    TR_GetEndPosition(vEndPosition);
    
    // Validate collisions
    if(TR_GetFraction() >= 1.0)
    {
        // Initialize the hull intersection
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SOLID, TraceFilter2);
    }

    // Validate collisions
    if(TR_GetFraction() < 1.0)
    {
        // Gets entity index
        entityIndex = TR_GetEntityIndex();

        // Validate entity
        if(IsEntityLasermine(entityIndex))
        {
            // Validate owner
            if(GetEntPropEnt(entityIndex, Prop_Data, "m_pParent") == clientIndex)
            {
                // Give item and select it
                ZP_GiveClientWeapon(clientIndex, gWeapon);

                // Kill entity
                AcceptEntityInput(entityIndex, "Kill");
                
                // Return on the success
                bSuccess = true;
            }
        }
    }

    // Return on success
    return bSuccess;
}

/**
 * Timer for creating mine.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateMine(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_MineCreate[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; 
        
        // Gets trace line
        GetClientEyePosition(clientIndex, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, TraceFilter2);

        // Validate collisions
        if(TR_DidHit() && TR_GetEntityIndex() < 1)
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vPosition);
            TR_GetPlaneNormal(null, vAngle);
            
            // Gets angles of the trace vectors
            GetVectorAngles(vAngle, vAngle); vAngle[0] += 90.0; /// Bugfix for w_

            // Gets weapon dropped model
            static char sModel[PLATFORM_LINE_LENGTH];
            ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
            
            // Create a physics entity
            int entityIndex = UTIL_CreatePhysics("mine", vPosition, vAngle, sModel, PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);
            
            // Validate entity
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Sets physics
                SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                SetEntProp(entityIndex, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);

                #if WEAPON_MINE_HEALTH > 0
                // Sets health     
                SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
                SetEntProp(entityIndex, Prop_Data, "m_iHealth", WEAPON_MINE_HEALTH);
                SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", WEAPON_MINE_HEALTH);
                
                // Create damage hook
                SDKHook(entityIndex, SDKHook_OnTakeDamage, MineDamageHook);
                #endif
                
                // Create the angle trace
                vAngle[0] -= 90.0; /// Bugfix for beam
                TR_TraceRayFilter(vPosition, vAngle, MASK_SOLID, RayType_Infinite, TraceFilter, entityIndex);
                
                // Returns the collision position of a trace result
                TR_GetEndPosition(vEndPosition);
                
                // Store the end position
                SetEntPropVector(entityIndex, Prop_Data, "m_vecViewOffset", vEndPosition);
                
                // Sets owner to the entity
                SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex); 

                // Create timer for activating 
                CreateTimer(WEAPON_MINE_ACTIVATION, MineActivateHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);

                // Play sound
                ZP_EmitSoundToAll(gSound, 3, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            
            // Forces a player to remove weapon
            ZP_RemoveWeapon(clientIndex, weaponIndex);
        }
        else
        {
            // Adds the delay to the game tick
            float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon) - 0.3;
            
            // Sets next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

            // Sets pickup animation
            ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW);
        }
    }
    
    // Destroy timer
    return Plugin_Stop;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

#define _call.%0(%1,%2) \
                        \
    Weapon_On%0         \
    (                   \
        %1,             \
        %2,             \
        GetGameTime()   \
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
        // Delete timers
        delete Task_MineCreate[clientIndex];
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
            iButtons &= (~IN_ATTACK);
            return Plugin_Changed;
        }
    }

    // Allow button
    return Plugin_Continue;
}

/**
 * @brief Called before show a main menu.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block showing. Anything else
 *                              (like Plugin_Continue) to allow showing.
**/
public Action ZP_OnClientValidateButton(int clientIndex)
{
    // Validate no weapon
    static int weaponIndex;
    if(ZP_IsPlayerHuman(clientIndex) && ZP_IsPlayerHasWeapon(clientIndex, gWeapon) == INVALID_ENT_REFERENCE)
    {
        // Call event
        if(_call.PickupMine(clientIndex, weaponIndex))
        {
            // Block showing menu
            return Plugin_Handled;
        }
    }
    
    // Allow menu
    return Plugin_Continue;
}

//**********************************************
//* Item (beam) hooks.                         *
//**********************************************

/**
 * @brief Mine damage hook.
 * 
 * @param entityIndex       The entity index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action MineDamageHook(int entityIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &damageBits)
{
    // Validate attacker
    if(IsPlayerExist(attackerIndex))
    {
        // Validate zombie
        if(ZP_IsPlayerZombie(attackerIndex))
        {
            // Calculate the damage
            int iHealth = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

            // Destroy entity
            if(!iHealth)
            {
                // Destroy damage hook
                SDKUnhook(entityIndex, SDKHook_OnTakeDamage, MineDamageHook);
        
                // Expload it
                MineExpload(entityIndex);
            }
            else
            {
                // Apply damage
                SetEntProp(entityIndex, Prop_Data, "m_iHealth", iHealth);
            }
        }
    }
    
    // Return on success
    return Plugin_Handled;
}

/**
 * @brief Exploade mine.
 * 
 * @param entityIndex       The entity index.                    
 **/
void MineExpload(int entityIndex)
{
    // Initialize vectors
    static float vPosition[3]; static float vGibAngle[3]; float vShootAngle[3];

    // Gets entity position
    GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);

    // Create an explosion
    UTIL_CreateExplosion(vPosition, /*EXP_NOFIREBALL | */EXP_NOSOUND, _, WEAPON_MINE_EXPLOSION_DAMAGE, WEAPON_MINE_EXPLOSION_RADIUS, "prop_exploding_barrel", GetEntPropEnt(entityIndex, Prop_Data, "m_pParent"), entityIndex);
    
    // Play sound
    ZP_EmitSoundToAll(gSound, 5, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
    // Create a breaked metal effect
    static char sBuffer[NORMAL_LINE_LENGTH];
    for(int x = 0; x <= 4; x++)
    {
        // Find gib positions
        vShootAngle[1] += 72.0; vGibAngle[0] = GetRandomFloat(0.0, 360.0); vGibAngle[1] = GetRandomFloat(-15.0, 15.0); vGibAngle[2] = GetRandomFloat(-15.0, 15.0); switch(x)
        {
            case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib1.mdl");
            case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib2.mdl");
            case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib3.mdl");
            case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib4.mdl");
            case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib5.mdl");
        }
        
        // Create gibs
        UTIL_CreateShooter(entityIndex, "1", _, MAT_METAL, sBuffer, vShootAngle, vGibAngle, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
    }
    
    // Kill after some duration
    UTIL_RemoveEntity(entityIndex, 0.1);
}

/**
 * @brief Main timer for activate mine.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action MineActivateHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; 

        // Gets mine position
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Play sound
        ZP_EmitSoundToAll(gSound, 1, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
        #if defined WEAPON_MINE_IMPULSE
        // Create timer for updating 
        CreateTimer(WEAPON_MINE_UPDATE, MineUpdateHook, EntIndexToEntRef(entityIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
        // Gets the angle
        GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vEndPosition);
        
        // Gets mine model
        static char sModel[PLATFORM_LINE_LENGTH];
        GetEntPropString(entityIndex, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

        // Create a prop_dynamic_override entity
        int glowIndex = UTIL_CreateDynamic(vPosition, vEndPosition, sModel, "dropped");

        // Validate entity
        if(glowIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetVariantString("!activator");
            AcceptEntityInput(glowIndex, "SetParent", entityIndex, glowIndex);
            SetEntPropEnt(glowIndex, Prop_Send, "m_hOwnerEntity", entityIndex);

            // Sets glowing mode
            static const int vColor[4] = WEAPON_GLOW_COLOR;
            UTIL_CreateGlowing(glowIndex, true, _, vColor[0], vColor[1], vColor[2], vColor[3]);
        }
        #else
        // Gets the end position
        GetEntPropVector(entityIndex, Prop_Data, "m_vecViewOffset", vEndPosition);
        
        // Create a beam entity
        int beamIndex = UTIL_CreateBeam(vPosition, vEndPosition, _, _, _, _, _, _, _, _, _, WEAPON_BEAM_MODEL, _, _, BEAM_STARTSPARKS | BEAM_ENDSPARKS, _, _, _, WEAPON_BEAM_COLOR_F, WEAPON_MINE_UPDATE, 0.0, "laser");
        
        // Validate entity
        if(beamIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_hMoveChild", beamIndex);
            SetEntPropEnt(beamIndex, Prop_Data, "m_hEffectEntity", entityIndex);

            // Gets owner of the entity
            int ownerIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");
            
            // Validate owner
            if(ownerIndex != INVALID_ENT_REFERENCE)
            {
                // Sets owner to the entity
                SetEntPropEnt(beamIndex, Prop_Data, "m_pParent", ownerIndex); 
            }
        }
        #endif
    }
    
    // Destroy timer
    return Plugin_Stop;
} 

/**
 * @brief Main timer for update mine.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
#if defined WEAPON_MINE_IMPULSE
public Action MineUpdateHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3];
        
        // Gets mine position/end pos
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
        GetEntPropVector(entityIndex, Prop_Data, "m_vecViewOffset", vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TraceFilter3, entityIndex);
        
        // Returns the collision position of a trace result
        TR_GetEndPosition(vEndPosition);
        
        // Validate collisions
        if(TR_GetFraction() >= 1.0)
        {
            // Initialize the hull intersection
            static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
            static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
            
            // Create the hull trace
            TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter3, entityIndex);
        }
        
        // Validate collisions
        if(TR_GetFraction() < 1.0)
        {
            // Gets owner/victim index
            int ownerIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");
            int victimIndex = TR_GetEntityIndex();

            // Validate victim
            if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
            {    
                // Create the damage for a victim
                if(!ZP_TakeDamage(victimIndex, ownerIndex, entityIndex, ZP_GetWeaponDamage(gWeapon), DMG_BUCKSHOT))
                {
                    // Create a custom death event
                    static char sIcon[SMALL_LINE_LENGTH];
                    ZP_GetWeaponIcon(gWeapon, sIcon, sizeof(sIcon));
                    UTIL_CreateIcon(victimIndex, ownerIndex, sIcon);
                }

                // Play sound
                ZP_EmitSoundToAll(gSound, 4, victimIndex, SNDCHAN_BODY, hSoundLevel.IntValue);
            }
            
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vEndPosition);

            // Create a tracer effect 
            TE_SetupBeamPoints(vPosition, vEndPosition, decalBeam, 0, 0, 0, WEAPON_BEAM_LIFE, WEAPON_BEAM_WIDTH, WEAPON_BEAM_WIDTH, 10, 1.0, WEAPON_BEAM_COLOR, 30);
            TE_SendToAllInRange(vPosition, RangeType_Visibility);

            // Emit the hit sounds
            EmitAmbientSound(WEAPON_MINE_IMPACT, vEndPosition, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, WEAPON_MINE_IMPACT_LEVEL, SNDPITCH_LOW);
            EmitAmbientSound(WEAPON_MINE_SHOOT, vPosition, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, WEAPON_MINE_SHOOT_LEVEL, SNDPITCH_LOW);
        }
        
        // Allow timer
        return Plugin_Continue;
    }
        
    // Destroy timer
    return Plugin_Stop;
}
#else
/**
 * @brief Beam touch hook.
 *
 * @param sOutput           The output char. 
 * @param entityIndex       The entity index.
 * @param activatorIndex    The activator index.
 * @param flDelay           The delay of updating.
 **/ 
public void BeamTouchHook(char[] sOutput, int entityIndex, int activatorIndex, float flDelay)
{
    // Validate entity
    if(IsEntityBeam(entityIndex))
    {
        // Validate breakness
        if(IsPlayerExist(activatorIndex) && ZP_IsPlayerZombie(activatorIndex))
        {
            // Gets owner/victim index
            int ownerIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");

            // Apply damage
            if(!ZP_TakeDamage(activatorIndex, ownerIndex, entityIndex, ZP_GetWeaponDamage(gWeapon), DMG_BUCKSHOT))
            {
                // Create a custom death event
                static char sIcon[SMALL_LINE_LENGTH];
                ZP_GetWeaponIcon(gWeapon, sIcon, sizeof(sIcon));
                UTIL_CreateIcon(activatorIndex, ownerIndex, sIcon);
            }

            // Play sound
            ZP_EmitSoundToAll(gSound, 4, activatorIndex, SNDCHAN_BODY, hSoundLevel.IntValue);
        }
    }
}
#endif

//**********************************************
//* Useful stocks.                             *
//**********************************************

/**
 * @brief Validate a lasermine.
 *
 * @param entityIndex       The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityBeam(int entityIndex)
{
    // Gets classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate model
    return (!strncmp(sClassname, "laser", 5, false));
}

/**
 * @brief Validate a lasermine.
 *
 * @param entityIndex       The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityLasermine(int entityIndex)
{
    // Validate entity
    if(entityIndex <= MaxClients || !IsValidEdict(entityIndex))
    {
        return false;
    }
    
    // Gets classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate model
    return (!strcmp(sClassname, "mine", false));
}

/**
 * @brief Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @param filterIndex       The filter index.
 * @return                  True or false.
 **/
public bool TraceFilter(int entityIndex, int contentsMask, int filterIndex)
{
    if(IsPlayerExist(entityIndex)) 
    {
        return false;
    }

    return (entityIndex != filterIndex);
}

/**
 * @brief Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 *
 * @return                  True or false.
 **/
public bool TraceFilter2(int entityIndex, int contentsMask)
{
    return !(1 <= entityIndex <= MaxClients);
}

/**
 * @brief Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @param filterIndex       The filter index.
 * @return                  True or false.
 **/
#if defined WEAPON_MINE_IMPULSE
public bool TraceFilter3(int entityIndex, int contentsMask, int filterIndex)
{
    if(IsPlayerExist(entityIndex) && ZP_IsPlayerHuman(entityIndex)) 
    {
        return false;
    }

    return (entityIndex != filterIndex);
}
#endif