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
    name            = "[ZP] Zombie Class: Stamper",
    author          = "qubka (Nikita Ushakov)",
    description     = "Addon of zombie classses",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Information about zombie class.
 **/
#define ZOMBIE_CLASS_SKILL_SHAKE_AMP         2.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY   1.0           
#define ZOMBIE_CLASS_SKILL_SHAKE_DURATION    3.0
#define ZOMBIE_CLASS_SKILL_DISTANCE          60.0
#define ZOMBIE_CLASS_SKILL_HEALTH            200
#define ZOMBIE_CLASS_SKILL_RADIUS            400.0
#define ZOMBIE_CLASS_SKILL_POWER             1000.0         
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

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel
 
// Zombie index
int gZombie;
#pragma unused gZombie

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Classes
    gZombie = ZP_GetClassNameID("stamper");
    if(gZombie == -1) SetFailState("[ZP] Custom zombie class ID from name : \"stamper\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("COFFIN_SKILL_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"COFFIN_SKILL_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Models
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
}

/**
 * @brief Called when a client use a skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled to block using skill. Anything else
 *                              (like Plugin_Continue) to allow use.
 **/
public Action ZP_OnClientSkillUsed(int clientIndex)
{
    // Validate the zombie class index
    if(ZP_GetClientClass(clientIndex) == gZombie)
    {
        // Initialize vectors
        static float vFromPosition[3];

        // Gets weapon position
        ZP_GetPlayerGunPosition(clientIndex, ZOMBIE_CLASS_SKILL_DISTANCE, _, _, vFromPosition);

        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
        EmitSoundToAll(sSound, clientIndex, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create a trap entity
        int entityIndex = CreateEntityByName("prop_physics_multiplayer"); 

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", "models/player/custom_player/zombie/zombiepile/zombiepile.mdl");
            DispatchKeyValue(entityIndex, "spawnflags", "8832"); /// Not affected by rotor wash | Prevent pickup | Force server-side

            // Spawn the entity
            DispatchSpawn(entityIndex);

            // Teleport the coffin
            TeleportEntity(entityIndex, vFromPosition, NULL_VECTOR, NULL_VECTOR);

            // Sets physics
            SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
            SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
            
            // Sets owner to the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex);

            // Sets health
            SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
            SetEntProp(entityIndex, Prop_Data, "m_iHealth", ZOMBIE_CLASS_SKILL_HEALTH);
            SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", ZOMBIE_CLASS_SKILL_HEALTH);

            // Create damage/touch hook
            SDKHook(entityIndex, SDKHook_Touch, CoffinTouchHook);
            SDKHook(entityIndex, SDKHook_OnTakeDamage, CoffinDamageHook);
            
            // Create remove timer
            CreateTimer(ZP_GetClassSkillDuration(gZombie), CoffinExploadHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Coffin touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action CoffinTouchHook(int entityIndex, int targetIndex)
{
    // Validate target
    if(IsPlayerExist(targetIndex))
    {
        // Expload with other player coliding
        if(GetEntPropEnt(entityIndex, Prop_Data, "m_pParent") != targetIndex)
        {
            // Destroy touch hook
            SDKUnhook(entityIndex, SDKHook_Touch, CoffinTouchHook);
    
            // Expload it
            CoffinExpload(entityIndex);
        }
    }
    
    // Allow usage
    return Plugin_Continue;
}

/**
 * @brief Coffin damage hook.
 *
 * @param entityIndex       The entity index.    
 * @param attackerIndex     The attacker index.
 * @param inflicterIndex    The inflicter index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action CoffinDamageHook(int entityIndex, int &attackerIndex, int &inflicterIndex, float &flDamage, int &iBits)
{
    // Calculate the damage
    int iHealth = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

    // Destroy entity
    if(!iHealth)
    {
        // Destroy damage hook
        SDKUnhook(entityIndex, SDKHook_OnTakeDamage, CoffinDamageHook);

        // Expload it
        CoffinExpload(entityIndex);
    }
    else
    {
        // Emit sound
        static char sSound[PLATFORM_LINE_LENGTH];
        ZP_GetSound(gSound, sSound, sizeof(sSound), GetRandomInt(2, 3));
        EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
        // Apply damage
        SetEntProp(entityIndex, Prop_Data, "m_iHealth", iHealth);
    }

    // Return on success
    return Plugin_Handled;
}

/**
 * @brief Main timer for exploade coffin.
 * 
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.                    
 **/
public Action CoffinExploadHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Expload it
        CoffinExpload(entityIndex);
    }
}

/**
 * @brief Exploade coffin.
 * 
 * @param entityIndex       The entity index.                    
 **/
void CoffinExpload(int entityIndex)
{
    // Initialize vectors
    static float vEntPosition[3]; static float vGibAngle[3]; static float vVictimPosition[3]; static float vVelocity[3]; float vShootAngle[3];

    // Gets entity position
    GetEntPropVector(entityIndex, Prop_Send, "m_vecOrigin", vEntPosition);

    // i = client index
    for(int i = 1; i <= MaxClients; i++)
    {
        // Validate human
        if(IsPlayerExist(i) && ZP_IsPlayerZombie(i))
        {
            // Gets victim origin
            GetClientAbsOrigin(i, vVictimPosition);
            
            // Calculate the distance
            float flDistance = GetVectorDistance(vEntPosition, vVictimPosition);
            
            // Validate distance
            if(flDistance <= ZOMBIE_CLASS_SKILL_RADIUS)
            {                
                // Calculate the velocity vector
                SubtractVectors(vVictimPosition, vEntPosition, vVelocity);
                
                // Create a knockback
                ZP_CreateRadiusKnockBack(i, vVelocity, flDistance, ZOMBIE_CLASS_SKILL_POWER, ZOMBIE_CLASS_SKILL_RADIUS);
                
                // Create a shake
                ZP_CreateShakeScreen(i, ZOMBIE_CLASS_SKILL_SHAKE_AMP, ZOMBIE_CLASS_SKILL_SHAKE_FREQUENCY, ZOMBIE_CLASS_SKILL_SHAKE_DURATION);
            }
        }
    }
    
    // Create an explosion effect
    ZP_CreateParticle(entityIndex, vEntPosition, _, "explosion_hegrenade_dirt", 0.1);

    // Emit sound
    static char sSound[PLATFORM_LINE_LENGTH];
    ZP_GetSound(gSound, sSound, sizeof(sSound), 4);
    EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    
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
    
        // Create a shooter entity
        int gibIndex = CreateEntityByName("env_shooter");

        // If entity isn't valid, then skip
        if(gibIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValueVector(gibIndex, "angles", vShootAngle);
            DispatchKeyValueVector(gibIndex, "gibangles", vGibAngle);
            DispatchKeyValue(gibIndex, "rendermode", "5");
            DispatchKeyValue(gibIndex, "shootsounds", "2");
            DispatchKeyValue(gibIndex, "shootmodel", sBuffer);
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

            // Sets parent to the client
            SetVariantString("!activator"); 
            AcceptEntityInput(gibIndex, "SetParent", entityIndex, gibIndex); 

            // Sets attachment to the client
            SetVariantString("1"); /// Attachment name in the coffin model
            AcceptEntityInput(gibIndex, "SetParentAttachment", entityIndex, gibIndex);

            // Initialize time char
            FormatEx(sBuffer, sizeof(sBuffer), "OnUser1 !self:kill::%f:1", METAL_GIBS_DURATION);

            // Sets modified flags on the entity
            SetVariantString(sBuffer);
            AcceptEntityInput(gibIndex, "AddOutput");
            AcceptEntityInput(gibIndex, "FireUser1");
        }
    }

    // Sets modified flags on the entity
    SetVariantString("OnUser1 !self:kill::0.1:1");
    AcceptEntityInput(entityIndex, "AddOutput");
    AcceptEntityInput(entityIndex, "FireUser1");
}