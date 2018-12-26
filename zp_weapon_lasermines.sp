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
 * Record plugin info.
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
#define WEAPON_MINE_IMPULSE /// Uncomment to use the classical beam instead.
#define WEAPON_MINE_HEALTH           200      // Mine health. ['0' = never breaked]
#define WEAPON_MINE_EXPLOSION_DAMAGE GetRandomFloat(50.0, 100.0) // Mine exp damage
#define WEAPON_MINE_EXPLOSION_RADIUS 150.0   // Mine exp radius
#define WEAPON_MINE_EXPLOSION_POWER  600.0   // Mine exp knockback
#define WEAPON_MINE_EXPLOSION_SHAKE_AMP         2.0 // Mine exp amp           
#define WEAPON_MINE_EXPLOSION_SHAKE_FREQUENCY   1.0 // Mine exp freq                
#define WEAPON_MINE_EXPLOSION_SHAKE_DURATION    3.0 // Mine exp time 
#define WEAPON_MINE_EXPLOSION_TIME              0.1 // Mine exp duration   
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
#define WEAPON_GLOW_COLOR            {0, 255, 0, 255} /// Only for impulse mode, because normal already have a child (beam)
#define WEAPON_GLOW_STYLE            0
#define WEAPON_GLOW_DISTANCE         2147483647.0
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
Handle Task_MineCreate[MAXPLAYERS+1] = INVALID_HANDLE; 

// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

// Sound index
int gSound; ConVar hSoundLevel;

// Decal index
int decalBeam;
#pragma unused decalBeam

/**
 * Called after a library is added that the current plugin references optionally. 
 * A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if(!strcmp(sLibrary, "zombieplague", false))
    {
        #if !defined WEAPON_MINE_IMPULSE
        // Hook player events
        HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
        
        // Hooks entity events
        HookEntityOutput("env_beam", "OnTouchedByEntity", BeamTouchHook);
        #endif
    }
}

/**
 * Called after a zombie core is loaded.
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
    PrecacheSound(WEAPON_MINE_IMPACT);
    PrecacheSound(WEAPON_MINE_SHOOT);
    
    // Cvars
    hSoundLevel = FindConVar("zp_game_custom_sound_level");
    if(hSoundLevel == INVALID_HANDLE) SetFailState("[ZP] Custom cvar key ID from name : \"zp_game_custom_sound_level\" wasn't find");
    
    // Models
    decalBeam = PrecacheModel(WEAPON_BEAM_MODEL, true);
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
    
    #if defined WEAPON_MINE_IMPULSE
    // Sounds
    PrecacheSound(WEAPON_MINE_IMPACT);
    PrecacheSound(WEAPON_MINE_SHOOT);
    #endif
}

/**
 * Called before show an extraitem in the equipment menu.
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
 * @param extraitemIndex    The item index.
 **/
public void ZP_OnClientBuyExtraItem(int clientIndex, int extraitemIndex)
{
    // Check the item index
    if(extraitemIndex == gItem)
    {
        // Give item and select it
        ZP_GiveClientWeapon(clientIndex, "lasermine");
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
        // Purge timer
        Task_MineCreate[i] = INVALID_HANDLE; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * Called when a client is disconnecting from the server.
 * 
 * @param clientIndex        The client index.
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

void Weapon_OnDeploy(const int clientIndex, const int weaponIndex, const float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime
    
    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);

    // Sets the next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnPrimaryAttack(const int clientIndex, const int weaponIndex, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime

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

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3];
    
    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 0.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter2);

    // Validate collisions
    if(TR_DidHit(hTrace) && TR_GetEntityIndex(hTrace) < 1)
    {
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
                
        // Sets the next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

        // Sets the deploy animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_DEPLOY);

        // Create timer for mine
        delete Task_MineCreate[clientIndex]; /// Bugfix
        Task_MineCreate[clientIndex] = CreateTimer(ZP_GetWeaponSpeed(gWeapon), Weapon_OnCreateMine, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Close the trace
    delete hTrace;
}

bool Weapon_OnPickupMine(const int clientIndex, int entityIndex, const float flCurrentTime)
{
    #pragma unused clientIndex, entityIndex, flCurrentTime

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; bool bSuccess;
    
    // Gets the weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 0.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter2);
    
    // Returns the collision position of a trace result
    TR_GetEndPosition(vEndPosition, hTrace);
    
    // Validate collisions
    if(TR_GetFraction(hTrace) >= 1.0)
    {
        // Initialize the hull intersection
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter2);
    }
    
    // Validate collisions
    if(TR_GetFraction(hTrace) < 1.0)
    {
        // Gets the entity index
        entityIndex = TR_GetEntityIndex(hTrace);

        // Validate entity
        if(IsEntityLasermine(entityIndex))
        {
            // Validate owner
            if(GetEntPropEnt(entityIndex, Prop_Data, "m_pParent") == clientIndex)
            {
                // Give item and select it
                ZP_GiveClientWeapon(clientIndex, "lasermine");

                // Kill entity
                AcceptEntityInput(entityIndex, "Kill");
                
                // Return on the success
                bSuccess = true;
            }
        }
    }

    // Close the trace
    delete hTrace;
    return bSuccess;
}

/**
 * Timer for creating mine.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateMine(Handle hTimer, const int userID)
{
    // Gets the client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_MineCreate[clientIndex] = INVALID_HANDLE;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; static float vEntAngle[3]; static char sSound[PLATFORM_MAX_PATH];
        
        // Gets the weapon position
        ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 0.0, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter2);

        // Validate collisions
        if(TR_DidHit(hTrace) && TR_GetEntityIndex(hTrace) < 1)
        {
            // Create a lasermine entity
            int entityIndex = CreateEntityByName("prop_physics_multiplayer");

            // If entity aren't valid, then skip
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Returns the collision position/angle of a trace result
                TR_GetEndPosition(vPosition, hTrace);
                TR_GetPlaneNormal(hTrace, vAngle);
                
                // Gets angles of the trace vectors
                GetVectorAngles(vAngle, vEntAngle); vEntAngle[0] += 90.0; /// Bugfix for w_
                GetVectorAngles(vAngle, vAngle);

                // Gets weapon dropped model
                static char sModel[PLATFORM_MAX_PATH];
                ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
                
                // Dispatch main values of the entity
                DispatchKeyValue(entityIndex, "targetname", "mine");
                DispatchKeyValue(entityIndex, "model", sModel);
                DispatchKeyValue(entityIndex, "spawnflags", "8832"); /// Not affected by rotor wash | Prevent pickup | Force server-side

                // Spawn the entity
                DispatchSpawn(entityIndex);

                // Teleport the mine
                TeleportEntity(entityIndex, vPosition, vEntAngle, NULL_VECTOR);
                
                // Sets the physics
                AcceptEntityInput(entityIndex, "DisableMotion");
                SetEntityMoveType(entityIndex, MOVETYPE_NONE);
                SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                SetEntProp(entityIndex, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);

                #if WEAPON_MINE_HEALTH > 0
                // Sets the health     
                SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
                SetEntProp(entityIndex, Prop_Data, "m_iHealth", WEAPON_MINE_HEALTH);
                SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", WEAPON_MINE_HEALTH);
                
                // Create damage hook
                SDKHook(entityIndex, SDKHook_OnTakeDamage, MineDamageHook);
                #endif

                // Sets owner to the entity
                SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex);    

                #if defined WEAPON_MINE_IMPULSE
                // Create timer for activating 
                CreateTimer(WEAPON_MINE_ACTIVATION, MineActivateHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
                #else
                // Initialize variables
                static char sClassname[SMALL_LINE_LENGTH]; static char sDispatch[SMALL_LINE_LENGTH]; static char sWidth[SMALL_LINE_LENGTH];       
                
                // Create a beam entities
                int beamIndex = CreateEntityByName("env_beam");
                
                // If entity aren't valid, then skip
                if(beamIndex != INVALID_ENT_REFERENCE)
                {
                    // Dispatch main values of the entity
                    Format(sClassname, sizeof(sClassname), "laser%i", beamIndex);
                    Format(sDispatch, sizeof(sDispatch), "%s,Kill,,0,-1", sClassname);
                    DispatchKeyValue(entityIndex, "OnBreak", sDispatch);
                    DispatchKeyValue(beamIndex, "targetname", sClassname);
                    DispatchKeyValue(beamIndex, "damage", "0");
                    DispatchKeyValue(beamIndex, "framestart", "0");
                    FloatToString(WEAPON_BEAM_WIDTH, sWidth, sizeof(sWidth));
                    DispatchKeyValue(beamIndex, "BoltWidth", sWidth);
                    DispatchKeyValue(beamIndex, "renderfx", "0");
                    DispatchKeyValue(beamIndex, "TouchType", "3");
                    DispatchKeyValue(beamIndex, "framerate", "0");
                    DispatchKeyValue(beamIndex, "decalname", "Bigshot");
                    DispatchKeyValue(beamIndex, "TextureScroll", "35");
                    DispatchKeyValue(beamIndex, "HDRColorScale", "1.0");
                    DispatchKeyValue(beamIndex, "texture", WEAPON_BEAM_MODEL);
                    DispatchKeyValue(beamIndex, "life", "0"); 
                    DispatchKeyValue(beamIndex, "StrikeTime", "1"); 
                    DispatchKeyValue(beamIndex, "LightningStart", sClassname);
                    DispatchKeyValue(beamIndex, "spawnflags", "0"); 
                    DispatchKeyValue(beamIndex, "NoiseAmplitude", "0"); 
                    DispatchKeyValue(beamIndex, "Radius", "256");
                    DispatchKeyValue(beamIndex, "renderamt", "100");
                    DispatchKeyValue(beamIndex, "rendercolor", "0 0 0");
                    
                    // Turn off the beam
                    AcceptEntityInput(beamIndex, "TurnOff");
                    
                    // Sets model for the beam
                    SetEntityModel(beamIndex, WEAPON_BEAM_MODEL);
                    
                    // Create the angle trace
                    hTrace = TR_TraceRayFilterEx(vPosition, vAngle, MASK_SHOT, RayType_Infinite, TraceFilter3, entityIndex);
                    
                    // Returns the collision position of a trace result
                    TR_GetEndPosition(vEndPosition, hTrace);
                    
                    // Teleport the beam
                    TeleportEntity(beamIndex, vEndPosition, NULL_VECTOR, NULL_VECTOR); 
                    
                    // Sets the size
                    SetEntPropVector(beamIndex, Prop_Data, "m_vecEndPos", vPosition);
                    SetEntPropFloat(beamIndex, Prop_Data, "m_fWidth", WEAPON_BEAM_WIDTH);
                    SetEntPropFloat(beamIndex, Prop_Data, "m_fEndWidth", WEAPON_BEAM_WIDTH);
                    
                    // Sets owner to the entity
                    SetEntPropEnt(beamIndex, Prop_Data, "m_pParent", clientIndex); 
                    SetEntPropEnt(entityIndex, Prop_Data, "m_hMoveChild", beamIndex);
                    SetEntPropEnt(beamIndex, Prop_Data, "m_hEffectEntity", entityIndex);

                    //*********************************************************************
                    //*                               OTHER                                      *
                    //*********************************************************************
                    
                    // Send data to the pack
                    DataPack hPack = CreateDataPack();
                    hPack.WriteCell(EntIndexToEntRef(entityIndex));
                    hPack.WriteCell(EntIndexToEntRef(beamIndex));
                    hPack.WriteString(sClassname);
                    
                    // Create timer for activating 
                    CreateTimer(WEAPON_MINE_ACTIVATION, MineActivateHook, hPack, TIMER_FLAG_NO_MAPCHANGE | TIMER_HNDL_CLOSE);
                    
                    // Emit sound
                    ZP_GetSound(gSound, sSound, sizeof(sSound), 2);
                    EmitSoundToAll(sSound, beamIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                }
                #endif

                // Emit sound
                ZP_GetSound(gSound, sSound, sizeof(sSound), 3);
                EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            
            // Forces a player to remove weapon
            RemovePlayerItem(clientIndex, weaponIndex);
            AcceptEntityInput(weaponIndex, "Kill");
            
            // Switch the weapon
            FakeClientCommand(clientIndex, "use weapon_knife");
        }
        else
        {
            // Adds the delay to the game tick
            float flCurrentTime = GetGameTime() + 1.0;
            
            // Sets the next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

            // Sets the pickup animation
            ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW);
        }

        // Close the trace
        delete hTrace;
    }   
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
        // Delete timers
        delete Task_MineCreate[clientIndex];
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
 * Called before show a main menu.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block showing. Anything else
 *                              (like Plugin_Continue) to allow showing.
 **/
public Action ZP_OnClientValidateMainMenu(int clientIndex)
{
    // Validate no weapon
    static int weaponIndex;
    if(!ZP_IsPlayerHasWeapon(clientIndex, gWeapon))
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
 * Mine damage hook.
 * 
 * @param entityIndex       The entity index.
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflictor index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action MineDamageHook(const int entityIndex, int &attackerIndex, int &inflicterIndex, float &damageAmount, int &damageBits)
{
    // Validate entity
    if(IsValidEdict(entityIndex))
    {
        // Validate attacker
        if(IsPlayerExist(attackerIndex))
        {
            // Validate zombie
            if(ZP_IsPlayerZombie(attackerIndex) || GetEntPropEnt(entityIndex, Prop_Data, "m_pParent") == attackerIndex)
            {
                // Calculate the damage
                int healthAmount = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToCeil(damageAmount); healthAmount = (healthAmount > 0) ? healthAmount : 0;

                // Destroy entity
                if(!healthAmount)
                {
                    // Destroy damage hook
                    SDKUnhook(entityIndex, SDKHook_OnTakeDamage, MineDamageHook);
            
                    // Expload it
                    MineExpload(entityIndex);
                }
                else
                {
                    // Apply damage
                    SetEntProp(entityIndex, Prop_Data, "m_iHealth", healthAmount);
                }
            }
        }
    }
    
    // Return on success
    return Plugin_Handled;
}

/**
 * Exploade mine.
 * 
 * @param entityIndex       The entity index.                    
 **/
void MineExpload(const int entityIndex)
{
    // Initialize vectors
    static float vEntPosition[3]; static float vEntAngle[3]; static float vVictimPosition[3]; static float vVelocity[3]; static float vAngle[3];

    // Gets the entity position
    GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

    // Gets owner of the entity
    int ownerIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");
    
    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if(IsPlayerExist(i) && (ZP_IsPlayerZombie(i) || ownerIndex == i))
        {
            // Gets victim origin
            GetClientAbsOrigin(i, vVictimPosition);
            
            // Calculate the distance
            float flDistance = GetVectorDistance(vEntPosition, vVictimPosition);
            
            // Validate distance
            if(flDistance <= WEAPON_MINE_EXPLOSION_RADIUS)
            {         
                // Create the damage for a victim
                ZP_TakeDamage(i, ownerIndex, WEAPON_MINE_EXPLOSION_DAMAGE * (1.0 - (flDistance / WEAPON_MINE_EXPLOSION_RADIUS)), DMG_VEHICLE);
                
                // Calculate the velocity vector
                SubtractVectors(vVictimPosition, vEntPosition, vVelocity);
                
                // Create a knockback
                FakeCreateKnockBack(i, vVelocity, flDistance, WEAPON_MINE_EXPLOSION_POWER, WEAPON_MINE_EXPLOSION_RADIUS);
                
                // Create a shake
                FakeCreateShakeScreen(i, WEAPON_MINE_EXPLOSION_SHAKE_AMP, WEAPON_MINE_EXPLOSION_SHAKE_FREQUENCY, WEAPON_MINE_EXPLOSION_SHAKE_DURATION);
            }
        }
    }
    
    // Create an explosion effect
    FakeCreateParticle(entityIndex, vEntPosition, _, "explosion_hegrenade_interior", WEAPON_MINE_EXPLOSION_TIME);

    // Emit sound
    static char sModel[PLATFORM_MAX_PATH];
    ZP_GetSound(gSound, sModel, sizeof(sModel), 5);
    EmitSoundToAll(sModel, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
    // Create a breaked glass effect
    for(int x = 0; x <= 4; x++)
    {
        // Find gib positions
        vAngle[1] += 72.0; vEntAngle[0] = GetRandomFloat(0.0, 360.0); vEntAngle[1] = GetRandomFloat(-15.0, 15.0); vEntAngle[2] = GetRandomFloat(-15.0, 15.0); switch(x)
        {
            case 0 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib1.mdl");
            case 1 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib2.mdl");
            case 2 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib3.mdl");
            case 3 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib4.mdl");
            case 4 : strcopy(sModel, sizeof(sModel), "models/gibs/metal_gib5.mdl");
        }
    
        // Create a shooter entity
        int gibIndex = CreateEntityByName("env_shooter");

        // If entity isn't valid, then skip
        if(gibIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValueVector(gibIndex, "angles", vAngle);
            DispatchKeyValueVector(gibIndex, "gibangles", vEntAngle);
            DispatchKeyValue(gibIndex, "rendermode", "5");
            DispatchKeyValue(gibIndex, "shootsounds", "2");
            DispatchKeyValue(gibIndex, "shootmodel", sModel);
            DispatchKeyValueFloat(gibIndex, "m_iGibs", METAL_GIBS_AMOUNT);
            DispatchKeyValueFloat(gibIndex, "delay", METAL_GIBS_DELAY);
            DispatchKeyValueFloat(gibIndex, "m_flVelocity", METAL_GIBS_SPEED);
            DispatchKeyValueFloat(gibIndex, "m_flVariance", METAL_GIBS_VARIENCE);
            DispatchKeyValueFloat(gibIndex, "m_flGibLife", METAL_GIBS_LIFE);

            // Spawn the entity into the world
            DispatchSpawn(gibIndex);

            // Activate the entity
            ActivateEntity(gibIndex);  
            AcceptEntityInput(gibIndex, "Shoot");

            // Sets parent to the entity
            SetVariantString("!activator"); 
            AcceptEntityInput(gibIndex, "SetParent", entityIndex, gibIndex); 

            // Sets attachment to the entity
            SetVariantString("1"); /// Attachment name in the mine model
            AcceptEntityInput(gibIndex, "SetParentAttachment", entityIndex, gibIndex);

            // Initialize variable
            static char sTime[SMALL_LINE_LENGTH];
            Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", METAL_GIBS_DURATION);

            // Sets modified flags on the entity
            SetVariantString(sTime);
            AcceptEntityInput(gibIndex, "AddOutput");
            AcceptEntityInput(gibIndex, "FireUser1");
        }
    }

    // Initialize variable
    static char sTime[SMALL_LINE_LENGTH];
    Format(sTime, sizeof(sTime), "OnUser1 !self:kill::%f:1", WEAPON_MINE_EXPLOSION_TIME);

    // Sets modified flags on the entity
    SetVariantString(sTime);
    AcceptEntityInput(entityIndex, "AddOutput");
    AcceptEntityInput(entityIndex, "FireUser1");
}

/**
 * Main timer for activate mine.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
#if defined WEAPON_MINE_IMPULSE
public Action MineActivateHook(Handle hTimer, const int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
        // Create a glow model
        CreateGlowableModel(entityIndex);

        // Create timer for updating 
        CreateTimer(WEAPON_MINE_UPDATE, MineUpdateHook, EntIndexToEntRef(entityIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Destroy timer
    return Plugin_Stop;
} 

/**
 * Main timer for update mine.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action MineUpdateHook(Handle hTimer, const int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; 
        
        // Gets the mine position/angle
        GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vPosition);
        GetEntPropVector(entityIndex, Prop_Send, "m_angRotation", vAngle); vAngle[0] -= 90.0; /// Bugfix for w_

        // Create the end-point trace
        Handle hTrace = TR_TraceRayFilterEx(vPosition, vAngle, MASK_SHOT, RayType_Infinite, TraceFilter, entityIndex);
        
        // Returns the collision position of a trace result
        TR_GetEndPosition(vEndPosition, hTrace);
        
        // Validate collisions
        if(TR_GetFraction(hTrace) >= 1.0)
        {
            // Initialize the hull intersection
            static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
            static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
            
            // Create the hull trace
            hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter, entityIndex);
        }
        
        // Validate collisions
        if(TR_GetFraction(hTrace) < 1.0)
        {
            // Gets the owner/victim index
            int ownerIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");
            int victimIndex = TR_GetEntityIndex(hTrace);

            // Validate victim
            if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
            {    
                // Create the damage for a victim
                ZP_TakeDamage(victimIndex, ownerIndex, ZP_GetWeaponDamage(gWeapon), DMG_BUCKSHOT);
                
                // Emit the damage sound
                static char sSound[PLATFORM_MAX_PATH];
                ZP_GetSound(gSound, sSound, sizeof(sSound), 4);
                EmitSoundToAll(sSound, victimIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
            }
            
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vEndPosition, hTrace);

            // Create a tracer effect 
            TE_SetupBeamPoints(vPosition, vEndPosition, decalBeam, 0, 0, 0, WEAPON_BEAM_LIFE, WEAPON_BEAM_WIDTH, WEAPON_BEAM_WIDTH, 10, 1.0, WEAPON_BEAM_COLOR, 30);
            TE_SendToAllInRange(vPosition, RangeType_Visibility);

            // Emit the hit sounds
            EmitAmbientSound(WEAPON_MINE_IMPACT, vEndPosition, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, WEAPON_MINE_IMPACT_LEVEL, SNDPITCH_LOW);
            EmitAmbientSound(WEAPON_MINE_SHOOT, vPosition, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, WEAPON_MINE_SHOOT_LEVEL, SNDPITCH_LOW);
        }

        // Close the trace
        delete hTrace;
        
        // Allow timer
        return Plugin_Continue;
    }
        
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Create a glowable dynamic model.
 *
 * @param entityIndex       The entity index.
 **/ 
void CreateGlowableModel(const int entityIndex)
{
    // Create a prop_dynamic_glow entity
    int glowIndex = CreateEntityByName("prop_dynamic_override");

    // Validate entity
    if(glowIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; 
    
        // Gets the mine position/angle
        GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vPosition);
        GetEntPropVector(entityIndex, Prop_Send, "m_angRotation", vAngle);

        // Gets the mine model
        static char sModel[PLATFORM_MAX_PATH];
        ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));

        // Dispatch main values of the entity
        DispatchKeyValue(glowIndex, "model", sModel);
        DispatchKeyValue(glowIndex, "disablereceiveshadows", "1");
        DispatchKeyValue(glowIndex, "disableshadows", "1");
        DispatchKeyValue(glowIndex, "spawnflags", "256"); /// Start with collision disabled
        DispatchKeyValue(glowIndex, "solid", "0");

        // Spawn the entity
        DispatchSpawn(glowIndex);

        // Sets owner to the entity
        SetEntPropEnt(entityIndex, Prop_Data, "m_hMoveChild", glowIndex);
        SetEntPropEnt(glowIndex, Prop_Data, "m_hEffectEntity", entityIndex);

        // Teleport the glow
        TeleportEntity(glowIndex, vPosition, vAngle, NULL_VECTOR);

        // Validate offset
        static int iGlowOffset; static const int vColor[4] = WEAPON_GLOW_COLOR;
        if(!iGlowOffset) iGlowOffset = GetEntSendPropOffs(glowIndex, "m_clrGlow")
        
        // Sets the glowing mode
        SetEntProp(glowIndex, Prop_Send, "m_bShouldGlow", true, true);
        SetEntProp(glowIndex, Prop_Send, "m_nGlowStyle", WEAPON_GLOW_STYLE);
        SetEntPropFloat(glowIndex, Prop_Send, "m_flGlowMaxDist", WEAPON_GLOW_DISTANCE);
        
        // Sets the alpha and colors
        SetEntData(glowIndex, iGlowOffset + 0, vColor[0],   _, true);
        SetEntData(glowIndex, iGlowOffset + 1, vColor[1], _, true);
        SetEntData(glowIndex, iGlowOffset + 2, vColor[2],  _, true);
        SetEntData(glowIndex, iGlowOffset + 3, vColor[3], _, true);
    }
}
#else
public Action MineActivateHook(Handle hTimer, DataPack hPack)
{
    // Resets the position in a data pack
    hPack.Reset();

    // Gets data from the datapack
    int entityIndex = EntRefToEntIndex(hPack.ReadCell());
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Emit sound
        static char sSound[PLATFORM_MAX_PATH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }
    
    // Gets data from the datapack
    int beamIndex = EntRefToEntIndex(hPack.ReadCell());
    
    // Validate entity
    if(beamIndex != INVALID_ENT_REFERENCE)
    {
        // Gets color of beam
        static const int vColor[4] = WEAPON_BEAM_COLOR;
        
        // Turn on the beam
        AcceptEntityInput(beamIndex, "TurnOn");
        
        // Sets an entity's color
        SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
        SetEntityRenderColor(entityIndex, vColor[0], vColor[1], vColor[2], vColor[3]);
        
        // Gets the classname
        static char sClassname[SMALL_LINE_LENGTH]; static char sDispatch[SMALL_LINE_LENGTH];
        hPack.ReadString(sClassname, sizeof(sClassname));
        
        // Sets modified flags on the beam
        Format(sDispatch, sizeof(sDispatch), "%s,TurnOff,,0.001,-1", sClassname);
        DispatchKeyValue(beamIndex, "OnTouchedByEntity", sDispatch);
        Format(sDispatch, sizeof(sDispatch), "%s,TurnOn,,0.002,-1", sClassname);
        DispatchKeyValue(beamIndex, "OnTouchedByEntity", sDispatch);
    }
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Beam touch hook.
 *
 * @param sOutput           The output char. 
 * @param entityIndex       The entity index.
 * @param activatorIndex    The activator index.
 * @param flDelay           The delay of updating.
 **/ 
public void BeamTouchHook(const char[] sOutput, const int entityIndex, const int activatorIndex, const float flDelay)
{
    // Validate entity
    if(IsEntityBeam(entityIndex))
    {
        // Validate breakness
        if((IsPlayerExist(activatorIndex) && ZP_IsPlayerZombie(activatorIndex) && IsPlayerDamageble(activatorIndex, WEAPON_MINE_UPDATE)))
        {
            // Gets the owner/victim index
            int ownerIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");

            // Apply damage
            ZP_TakeDamage(activatorIndex, ownerIndex, ZP_GetWeaponDamage(gWeapon), DMG_BUCKSHOT);

            // Emit the damage sound
            static char sSound[PLATFORM_MAX_PATH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 4);
            EmitSoundToAll(sSound, activatorIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        }
    }
}

/**
 * Event callback (player_death)
 * Client has been killed.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action EventPlayerDeath(Event hEvent, const char[] sName, bool dontBroadcast) 
{
    // Gets all required event info
    static char sClassname[SMALL_LINE_LENGTH];
    hEvent.GetString("weapon", sClassname, sizeof(sClassname));

    // Validate beam
    if(!strcmp(sClassname, "env_beam", false))
    {
        // Sets event properties
        hEvent.SetString("weapon", "taser");
        hEvent.SetBool("headshot", true);
    }
}

/**
 * Validate the damage delay.
 * 
 * @param clientIndex       The client index.
 * @param flDamageDelay     The delay of updating.
 **/
stock bool IsPlayerDamageble(const int clientIndex, const float flDamageDelay)
{
    // Initialize variable
    static float flDamageTime[MAXPLAYERS+1];
    
    // Gets the simulated game time
    float flCurrentTime = GetTickedTime();
    
    // Validate delay
    if((flCurrentTime - flDamageTime[clientIndex]) < flDamageDelay)
    {
        return false;
    }
    
    // Update the damage delay
    flDamageTime[clientIndex] = flCurrentTime;
    return true;
}
#endif

//**********************************************
//* Useful stocks.                             *
//**********************************************

/**
 * Validate a lasermine.
 *
 * @param entityIndex       The entity index.
 * @return                  The beam index.
 **/
stock int IsEntityBeam(const int entityIndex)
{
    // Validate entity
    if(entityIndex <= MaxClients || !IsValidEdict(entityIndex))
    {
        return false;
    }
    
    // Gets the classname
    static char sClassname[BIG_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate model
    return (!strncmp(sClassname, "laser", 5, false));
}

/**
 * Validate a lasermine.
 *
 * @param entityIndex       The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityLasermine(const int entityIndex)
{
    // Validate entity
    if(entityIndex <= MaxClients || !IsValidEdict(entityIndex))
    {
        return false;
    }
    
    // Gets the classname
    static char sClassname[BIG_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate model
    return (!strcmp(sClassname, "mine", false));
}

/**
 * Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @param filterIndex       The filter index.
 * @return                  True or false.
 **/
public bool TraceFilter(const int entityIndex, const int contentsMask, const int filterIndex)
{
    return (entityIndex != filterIndex);
}

/**
 * Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 *
 * @return                  True or false.
 **/
public bool TraceFilter2(const int entityIndex, const int contentsMask)
{
    return !(1 <= entityIndex <= MaxClients);
}

/**
 * Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @param filterIndex       The filter index.
 * @return                  True or false.
 **/
public bool TraceFilter3(const int entityIndex, const int contentsMask, const int filterIndex)
{
    return (!(1 <= entityIndex <= MaxClients) && entityIndex != filterIndex);
}