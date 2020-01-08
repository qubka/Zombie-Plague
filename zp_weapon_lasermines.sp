/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
#pragma semicolon 1

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
 * @section Information about the weapon.
 **/
//#define WEAPON_MINE_IMPULSE /// Uncomment to use the classical beam instead.
#define WEAPON_MINE_DAMAGE           150.0   // dmg amount
#define WEAPON_BEAM_LIFE             0.1
#define WEAPON_BEAM_WIDTH            3.0
#define WEAPON_BEAM_COLOR            {0, 0, 255, 255}
#define WEAPON_BEAM_COLOR_F          "0 0 255" // non impulse
#define WEAPON_GLOW_COLOR            {0, 255, 0, 255} /// Only for impulse mode, because normal already have a child (beam)
#define WEAPON_IDLE_TIME             1.66
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT            5.0
#define METAL_GIBS_DELAY             0.05
#define METAL_GIBS_SPEED             500.0
#define METAL_GIBS_VARIENCE          1.0  
#define METAL_GIBS_LIFE              1.0  
#define METAL_GIBS_DURATION          2.0
/**
 * @endsection
 **/

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT,
    ANIM_DRAW
};

// Timer index
Handle hMineCreate[MAXPLAYERS+1] = null; 

// Item index
int gWeapon;
#pragma unused gWeapon

// Sound index
int gSound; ConVar hSoundLevel; ConVar hKnockBack;
#pragma unused gSound, hSoundLevel, hKnockBack

// Decal index
int gBeam;
#pragma unused gBeam

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if (!strcmp(sLibrary, "zombieplague", false))
    {
        // If map loaded, then run custom forward
        if (ZP_IsMapLoaded())
        {
            // Execute it
            ZP_OnEngineExecute();
        }
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("lasermine");
    //if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"lasermine\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("LASERMINE_SHOOT_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"LASERMINE_SHOOT_SOUNDS\" wasn't find");

    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
    // Models
    gBeam = PrecacheModel("materials/sprites/purplelaser1.vmt", true);
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
    
#if defined WEAPON_MINE_IMPULSE
    // Sounds
    PrecacheSound("weapons/taser/taser_hit.wav", true);
    PrecacheSound("weapons/taser/taser_shoot.wav", true);
#endif
}

/**
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // i = client index
    for (int i = 1; i <= MaxClients; i++)
    {
        // Purge timer
        hMineCreate[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
    }
}

/**
 * @brief Called when a client is disconnecting from the server.
 * 
 * @param client            The client index.
 **/
public void OnClientDisconnect(int client)
{
    // Delete timers
    delete hMineCreate[client];
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnDeploy(int client, int weapon, float flCurrentTime)
{
    #pragma unused client, weapon, flCurrentTime
    
    /// Block the real attack
    SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);

    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
}

void Weapon_OnIdle(int client, int weapon, float flCurrentTime)
{
    #pragma unused client, weapon, flCurrentTime
    
    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Sets idle animation
    ZP_SetWeaponAnimation(client, ANIM_IDLE); 
    
    // Sets next idle time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnPrimaryAttack(int client, int weapon, float flCurrentTime)
{
    #pragma unused client, weapon, flCurrentTime

    // Validate animation delay
    if (GetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Validate water
    if (GetEntProp(client, Prop_Data, "m_nWaterLevel") == WLEVEL_CSGO_FULL)
    {
        return;
    }
    
    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3];
    
    // Gets trace line
    GetClientEyePosition(client, vPosition);
    ZP_GetPlayerGunPosition(client, 80.0, 0.0, 0.0, vEndPosition);
    
    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

    // Is hit world ?
    if (TR_DidHit() && TR_GetEntityIndex() < 1)
    {
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetWeaponReload(gWeapon);

        // Sets shoot animation
        ZP_SetWeaponAnimation(client, ANIM_SHOOT);

        // Create timer for mine
        delete hMineCreate[client]; /// Bugfix
        hMineCreate[client] = CreateTimer(ZP_GetWeaponReload(gWeapon) - 0.1, Weapon_OnCreateMine, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        // Adds the delay to the game tick
        flCurrentTime += 0.1;
    }
    
    // Sets next attack time
    SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);
}

/**
 * @brief Timer for creating mine.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateMine(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int client = GetClientOfUserId(userID); int weapon;

    // Clear timer 
    hMineCreate[client] = null;

    // Validate client
    if (ZP_IsPlayerHoldWeapon(client, weapon, gWeapon))
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; 
        
        // Gets trace line
        GetClientEyePosition(client, vPosition);
        ZP_GetPlayerGunPosition(client, 80.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

        // Is hit world ?
        if (TR_DidHit() && TR_GetEntityIndex() < 1)
        {
            // Returns the collision position/normal of a trace result
            TR_GetEndPosition(vPosition);
            TR_GetPlaneNormal(null, vAngle);

            // Gets angles of the trace vectors
            GetVectorAngles(vAngle, vAngle); vAngle[0] += 90.0; /// Bugfix for w_

            // Gets weapon dropped model
            static char sModel[PLATFORM_LINE_LENGTH];
            ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
            
            // Create a physics entity
            int entity = UTIL_CreatePhysics("mine", vPosition, vAngle, sModel, PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR | PHYS_GENERATEUSE);
            
            // Validate entity
            if (entity != -1)
            {
                // Sets physics
                SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);

                // Gets health amount
                int iHealth = GetEntProp(weapon, Prop_Data, "m_iHealth");
                
                // Sets health     
                SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
                SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
                SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHealth);
                
                // Create damage/use hook
                SDKHook(entity, SDKHook_OnTakeDamage, MineDamageHook);
                SDKHook(entity, SDKHook_UsePost, MineUseHook);
                
                // Create the angle trace
                vAngle[0] -= 90.0; /// Bugfix for beam
                TR_TraceRayFilter(vPosition, vAngle, MASK_SOLID, RayType_Infinite, PlayerFilter, entity);
                
                // Returns the collision position of a trace result
                TR_GetEndPosition(vEndPosition);
                
                // Store the end position
                SetEntPropVector(entity, Prop_Data, "m_vecViewOffset", vEndPosition);
                
                // Sets owner to the entity
                SetEntPropEnt(entity, Prop_Data, "m_pParent", client); 

                // Create activating/solid hook
                CreateTimer(ZP_GetWeaponModelHeat(gWeapon), MineActivateHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
                CreateTimer(0.1, MineSolidHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
                
                // Play sound
                ZP_EmitSoundToAll(gSound, 3, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            
            // Forces a player to remove weapon
            ZP_RemoveWeapon(client, weapon);
            
            // Destroy timer
            return Plugin_Stop;
        }

        // Adds the delay to the game tick
        float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon);
        
        // Sets next attack time
        SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime);    

        // Sets pickup animation
        ZP_SetWeaponAnimation(client, ANIM_DRAW);
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
 * @brief Called after a custom weapon is created.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int client, int weapon, int weaponID)
{
    // Validate custom weapon
    if (weaponID == gWeapon)
    {
        // Reset variables
        SetEntProp(weapon, Prop_Data, "m_iHealth", ZP_GetWeaponClip(gWeapon));
    }
}   
    
/**
 * @brief Called on deploy of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDeploy(int client, int weapon, int weaponID) 
{
    // Validate custom weapon
    if (weaponID == gWeapon)
    {
        // Call event
        _call.Deploy(client, weapon);
    }
}

/**
 * @brief Called on holster of a weapon.
 *
 * @param client            The client index.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponHolster(int client, int weapon, int weaponID) 
{
    // Validate custom weapon
    if (weaponID == gWeapon)
    {
        // Delete timers
        delete hMineCreate[client];
    }
}

/**
 * @brief Called on each frame of a weapon holding.
 *
 * @param client            The client index.
 * @param iButtons          The buttons buffer.
 * @param iLastButtons      The last buttons buffer.
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow buttons. Anything else 
 *                                (like Plugin_Changed) to change buttons.
 **/
public Action ZP_OnWeaponRunCmd(int client, int &iButtons, int iLastButtons, int weapon, int weaponID)
{
    // Validate custom weapon
    if (weaponID == gWeapon)
    {
        // Button primary attack press
        if (iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(client, weapon); 
            iButtons &= (~IN_ATTACK);
            return Plugin_Changed;
        }
        
        // Call event
        _call.Idle(client, weapon);
    }

    // Allow button
    return Plugin_Continue;
}

//**********************************************
//* Item (beam) hooks.                         *
//**********************************************

/**
 * @brief Mine use hook.
 *
 * @param entity            The entity index.
 * @param activator         The activator index.
 * @param caller            The caller index.
 * @param use               The use type.
 * @param flValue           The value parameter.
 **/ 
public void MineUseHook(int entity, int activator, int caller, UseType use, float flValue)
{
    // Validate human
    if (IsPlayerExist(activator) && ZP_IsPlayerHuman(activator) && ZP_IsPlayerHasWeapon(activator, gWeapon) == -1)
    {
        // Validate owner
        if (GetEntPropEnt(entity, Prop_Data, "m_pParent") == activator)
        {
            // Give item and select it
            int weapon = ZP_GiveClientWeapon(activator, gWeapon);
            
            // Validate weapon
            if (weapon != -1)
            {
                // Set variables
                SetEntProp(weapon, Prop_Data, "m_iHealth", GetEntProp(entity, Prop_Data, "m_iHealth"));
                
                // Kill entity
                AcceptEntityInput(entity, "Kill");
            }
        }
    }
}

/**
 * @brief Mine damage hook.
 * 
 * @param entity            The entity index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action MineDamageHook(int entity, int &attacker, int &inflictor, float &flDamage, int &damageBits)
{
    // Validate attacker
    if (IsPlayerExist(attacker))
    {
        // Validate zombie
        if (ZP_IsPlayerZombie(attacker))
        {
            // Calculate the damage
            int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

            // Destroy entity
            if (!iHealth)
            {
                // Destroy damage hook
                SDKUnhook(entity, SDKHook_OnTakeDamage, MineDamageHook);
        
                // Expload it
                MineExpload(entity);
            }
            else
            {
                // Apply damage
                SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
            }
        }
    }
    
    // Return on success
    return Plugin_Handled;
}

/**
 * @brief Exploade mine.
 * 
 * @param entity            The entity index.                    
 **/
void MineExpload(int entity)
{
    // Initialize vectors
    static float vPosition[3]; static float vGib[3]; float vShoot[3];

    // Gets entity position
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

    // Create an explosion
    UTIL_CreateExplosion(vPosition, /*EXP_NOFIREBALL | */EXP_NOSOUND | EXP_NODAMAGE);
    
    // Play sound
    ZP_EmitSoundToAll(gSound, 5, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
    // Create a breaked metal effect
    static char sBuffer[NORMAL_LINE_LENGTH];
    for (int x = 0; x <= 4; x++)
    {
        // Find gib positions
        vShoot[1] += 72.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
        {
            case 0 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib1.mdl");
            case 1 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib2.mdl");
            case 2 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib3.mdl");
            case 3 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib4.mdl");
            case 4 : strcopy(sBuffer, sizeof(sBuffer), "models/gibs/metal_gib5.mdl");
        }
        
        // Create gibs
        UTIL_CreateShooter(entity, "1", _, MAT_METAL, _, sBuffer, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
    }
    
    // Kill after some duration
    UTIL_RemoveEntity(entity, 0.1);
}

/**
 * @brief Main timer for activate mine.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action MineActivateHook(Handle hTimer, int refID)
{
    // Gets entity index from reference key
    int entity = EntRefToEntIndex(refID);

    // Validate entity
    if (entity != -1)
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; 

        // Gets mine position
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Play sound
        ZP_EmitSoundToAll(gSound, 1, entity, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
        // Create update hook
        CreateTimer(ZP_GetWeaponSpeed(gWeapon), MineUpdateHook, EntIndexToEntRef(entity), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

#if defined WEAPON_MINE_IMPULSE
        // Gets angle
        GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vEndPosition);
        
        // Gets mine model
        static char sModel[PLATFORM_LINE_LENGTH];
        GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

        // Create a prop_dynamic_override entity
        int glow = UTIL_CreateDynamic("glow", vPosition, vEndPosition, sModel, "dropped");

        // Validate entity
        if (glow != -1)
        {
            // Sets parent to the entity
            SetVariantString("!activator");
            AcceptEntityInput(glow, "SetParent", entity, glow);

            // Sets glowing mode
            static const int vColor[4] = WEAPON_GLOW_COLOR;
            UTIL_CreateGlowing(glow, true, _, vColor[0], vColor[1], vColor[2], vColor[3]);
        }
#else
        // Gets end position
        GetEntPropVector(entity, Prop_Data, "m_vecViewOffset", vEndPosition);
        
        // Create a beam entity
        int beam = UTIL_CreateBeam(vPosition, vEndPosition, _, _, _, _, _, _, _, _, _, "materials/sprites/purplelaser1.vmt", _, _, _, _, _, _, WEAPON_BEAM_COLOR_F, 0.002, 0.0, "beam");
        
        // Validate entity
        if (beam != -1)
        {
            // Sets parent to the entity
            SetEntPropEnt(entity, Prop_Data, "m_hMoveChild", beam);
            SetEntPropEnt(beam, Prop_Data, "m_hEffectEntity", entity);

            // Gets owner of the entity
            /*int owner = GetEntPropEnt(entity, Prop_Data, "m_pParent");
            
            // Validate owner
            if (owner != -1)
            {
                // Sets owner to the entity
                SetEntPropEnt(beam, Prop_Data, "m_pParent", owner); 
            }*/
        }
#endif
    }
    
    // Destroy timer
    return Plugin_Stop;
} 

/**
 * @brief Main timer for making solid mine.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action MineSolidHook(Handle hTimer, int refID)
{
    // Gets entity index from reference key
    int entity = EntRefToEntIndex(refID);

    // Validate entity
    if (entity != -1)
    {
        // Gets entity position
        static float vPosition[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);

        // Initialize the hull vectors
        static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
        static const float vMaxs[3] = {  20.0,  20.0, 20.0  }; 
        
        // Create array of entities
        ArrayList hList = new ArrayList();
        
        // Create the hull trace
        TR_EnumerateEntitiesHull(vPosition, vPosition, vMins, vMaxs, false, HullEnumerator, hList);

        // Is hit world only ?
        if (!hList.Length)
        {
            // Sets physics
            SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
            
            // Destroy timer
            delete hList;
            return Plugin_Stop;
        }
        
        // Delete list
        delete hList;
    }
    else
    {
        // Destroy timer
        return Plugin_Stop;
    }
    
    // Allow timer
    return Plugin_Continue;
}

/**
 * @brief Main timer for update mine.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action MineUpdateHook(Handle hTimer, int refID)
{
    // Gets entity index from reference key
    int entity = EntRefToEntIndex(refID);

    // Validate entity
    if (entity != -1)
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3];
        
        // Gets mine position/end pos
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
        GetEntPropVector(entity, Prop_Data, "m_vecViewOffset", vEndPosition);

#if defined WEAPON_MINE_IMPULSE
        static float vVelocity[3]; static float vSpeed[3];
    
        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, HumanFilter, entity);

        // Validate collisions
        if (TR_DidHit())
        {
            // Gets victim index
            int victim = TR_GetEntityIndex();

            // Returns the collision position of a trace result
            TR_GetEndPosition(vEndPosition);

            // Validate victim
            if (IsPlayerExist(victim) && ZP_IsPlayerZombie(victim))
            {    
                // Create the damage for victims
                ZP_TakeDamage(victim, -1, entity, WEAPON_MINE_DAMAGE, DMG_BULLET);
        
                // Play sound
                ZP_EmitSoundToAll(gSound, 4, victim, SNDCHAN_ITEM, hSoundLevel.IntValue);
                
                // Validate power
                float flPower = ZP_GetClassKnockBack(ZP_GetClientClass(victim)) * ZP_GetWeaponKnockBack(gWeapon) * WEAPON_MINE_DAMAGE; 
                if (flPower <= 0.0)
                {
                    return;
                }
                
                // If knockback system is enabled, then apply
                if (hKnockBack.BoolValue)
                {
                    // Gets vector from the given starting and ending points
                    MakeVectorFromPoints(vPosition, vEndPosition, vVelocity);

                    // Normalize the vector (equal magnitude at varying distances)
                    NormalizeVector(vVelocity, vVelocity);

                    // Apply the magnitude by scaling the vector
                    ScaleVector(vVelocity, flPower);
                    
                    // Gets client velocity
                    GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vSpeed);
                    
                    // Add to the current
                    AddVectors(vSpeed, vVelocity, vVelocity);
                
                    // Push the target
                    TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vVelocity);
                }
                else
                {
                    // Validate max
                    if (flPower > 100.0) flPower = 100.0;
                    else if (flPower <= 0.0) return;
            
                    // Apply the stamina-based slowdown
                    SetEntPropFloat(victim, Prop_Send, "m_flStamina", flPower);
                }
            }
            
            // Create a tracer effect 
            TE_SetupBeamPoints(vPosition, vEndPosition, gBeam, 0, 0, 0, WEAPON_BEAM_LIFE, WEAPON_BEAM_WIDTH, WEAPON_BEAM_WIDTH, 10, 1.0, WEAPON_BEAM_COLOR, 30);
            TE_SendToAll();

            // Emit the hit sounds
            EmitAmbientSound("weapons/taser/taser_hit.wav", vEndPosition, SOUND_FROM_WORLD, hSoundLevel.IntValue, SND_NOFLAGS, 0.5, SNDPITCH_LOW);
            EmitAmbientSound("weapons/taser/taser_shoot.wav", vPosition, SOUND_FROM_WORLD, hSoundLevel.IntValue, SND_NOFLAGS, 0.3, SNDPITCH_LOW);
        }
#else
        // Create array of entities
        ArrayList hList = new ArrayList();

        // Create the ray trace
        TR_EnumerateEntities(vPosition, vEndPosition, false, RayType_EndPoint, RayEnumerator, hList);
        
        // Is hit some one ?
        for(int i = 0; i < hList.Length; i++)
        {
            // Gets the index from a list
            int victim = hList.Get(i);
            
            // Validate victim
            if(IsPlayerExist(victim) && ZP_IsPlayerZombie(victim))
            {
                // Apply damage
                ZP_TakeDamage(victim, -1, entity, WEAPON_MINE_DAMAGE, DMG_BULLET);
            
                // Play sound
                ZP_EmitSoundToAll(gSound, 4, victim, SNDCHAN_ITEM, hSoundLevel.IntValue);
            }
        }

        // Delete list
        delete hList;
#endif
    }
    else
    {
        // Destroy timer
        return Plugin_Stop;
    }
    
    // Allow timer
    return Plugin_Continue;
}

//**********************************************
//* Useful stocks.                             *
//**********************************************

/**
 * @brief Validate a lasermine.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityBeam(int entity)
{
    // Validate entity
    if (entity <= MaxClients || !IsValidEdict(entity))
    {
        return false;
    }
    
    // Gets classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEntPropString(entity, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate model
    return (!strncmp(sClassname, "beam", 4, false));
}

/**
 * @brief Validate a lasermine.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityLasermine(int entity)
{
    // Validate entity
    if (entity <= MaxClients || !IsValidEdict(entity))
    {
        return false;
    }
    
    // Gets classname
    static char sClassname[SMALL_LINE_LENGTH];
    GetEntPropString(entity, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate model
    return (!strcmp(sClassname, "mine", false));
}

/**
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @return                  True or false.
 **/
public bool ClientFilter(int entity, int contentsMask)
{
    return !(1 <= entity <= MaxClients);
}

/**
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 * @return                  True or false.
 **/
public bool PlayerFilter(int entity, int contentsMask, int filter)
{
    // Validate player
    if (IsPlayerExist(entity)) 
    {
        return false;
    }

    return (entity != filter);
}

/**
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 * @return                  True or false.
 **/
#if defined WEAPON_MINE_IMPULSE
public bool HumanFilter(int entity, int contentsMask, int filter)
{
    // Validate human
    if (IsPlayerExist(entity) && ZP_IsPlayerHuman(entity)) 
    {
        return false;
    }

    return (entity != filter);
}
#endif

/**
 * @brief Hull filter.
 *
 * @param entity            The entity index.
 * @param hData             The array handle.
 * @return                  True to continue enumerating, otherwise false.
 **/
public bool HullEnumerator(int entity, ArrayList hData)
{
    // Validate player
    if (IsPlayerExist(entity))
    {
        TR_ClipCurrentRayToEntity(MASK_ALL, entity);
        if (TR_DidHit()) hData.Push(entity);
    }
        
    return true;
}

/**
 * @brief Ray filter.
 *
 * @param entity            The entity index.
 * @param hData             The array handle.
 * @return                  True to continue enumerating, otherwise false.
 **/
public bool RayEnumerator(int entity, ArrayList hData)
{
    // Validate player
    if (IsPlayerExist(entity))
    {
        TR_ClipCurrentRayToEntity(MASK_ALL, entity);
        if (TR_DidHit()) hData.Push(entity);
    }
        
    return true;
}