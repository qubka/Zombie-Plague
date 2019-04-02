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
#include <cstrike>
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: AirDrop",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel 
 
// Item index
int gWeapon;
#pragma unused gWeapon

// Decal index
int decalSmoke; int decalBeam;
#pragma unused decalSmoke, decalBeam

// Timer index
Handle Task_EmitterCreate[MAXPLAYERS+1] = null; 

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT,
    ANIM_DRAW,
    ANIM_IDLE_TRIGGER_ON,
    ANIM_IDLE_TRIGGER_OFF,
    ANIM_SWITCH_TRIGGER_ON,
    ANIM_SWITCH_TRIGGER_OFF,
    ANIM_SHOOT_TRIGGER_ON,
    ANIM_SHOOT_TRIGGER_OFF,
    ANIM_DRAW_TRIGGER_ON,
    ANIM_DRAW_TRIGGER_OFF
};

// Weapon states
enum
{
    STATE_TRIGGER_ON,
    STATE_TRIGGER_OFF
};

/**
 * @section Information about weapon.
 **/
#define WEAPON_TIME_DELAY_SWITCH    1.5
/**
 * @endsection
 **/
 
/**
 * @section Properties of the bombardier.
 **/
#define BOMBARDING_HEIGHT               700.0
#define BOMBARDING_EXPLOSION_TIME       2.0
#define BOMBARDING_SPEED                "500"
#define BOMBARDING_RADIUS               2000.0
/**
 * @endsection
 **/
 
/**
 * @section Properties of the airdrop.
 **/
#define AIRDROP_SPEED                   "100"
#define AIRDROP_HEIGHT                  800.0
#define AIRDROP_HEALTH                  300
#define AIRDROP_EXPLOSIONS              3
#define AIRDROP_WEAPONS                 15
#define AIRDROP_SMOKE_REMOVE            14.0
#define AIRDROP_SMOKE_TIME              17.0
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT                5.0
#define METAL_GIBS_DELAY                 0.05
#define METAL_GIBS_SPEED                 500.0
#define METAL_GIBS_VARIENCE              2.0  
#define METAL_GIBS_LIFE                  2.0  
#define METAL_GIBS_DURATION              3.0
/**
 * @endsection
 **/
 
/**
 * @brief Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
    // Hooks entity path_track output events
    HookEntityOutput("path_track", "OnPass", OnTrainPass);

    // Load translations phrases used by plugin
    LoadTranslations("zombieplague.phrases");
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
        Task_EmitterCreate[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete Task_EmitterCreate[clientIndex];
}

/**
 * @brief Called when a entity touch 'path_track' node.
 *
 * @param sOutput               The output char. 
 * @param entityIndex           The entity index.
 * @param activatorIndex        The activator index.
 * @param flDelay               The delay of updating.
 **/ 
public void OnTrainPass(char[] sOutput, int entityIndex, int activatorIndex, float flDelay)
{
    // Validate activator
    if(IsValidEdict(activatorIndex))
    {
        // Is it end path ?
        if(ValidateName(entityIndex, "safepath1", 9))
        {
            DropLandHook(activatorIndex);
        }
        else if(ValidateName(entityIndex, "nucpath1", 8))
        {
            BombLandHook(activatorIndex);
        }
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("airdrop");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"drone gun\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("HELICOPTER_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HELICOPTER_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Sounds
    PrecacheSound("survival/container_death_01.wav", true);
    PrecacheSound("survival/container_death_02.wav", true);
    PrecacheSound("survival/container_death_03.wav", true);
    PrecacheSound("survival/container_damage_01.wav", true);
    PrecacheSound("survival/container_damage_02.wav", true);
    PrecacheSound("survival/container_damage_03.wav", true);
    PrecacheSound("survival/container_damage_04.wav", true);
    PrecacheSound("survival/container_damage_05.wav", true);
    PrecacheSound("survival/missile_gas_01.wav", true);
    PrecacheSound("survival/dropzone_freefall.wav", true);
    PrecacheSound("survival/dropzone_parachute_deploy.wav", true);
    PrecacheSound("survival/dropzone_parachute_success.wav", true);
    PrecacheSound("survival/dropzone_parachute_success_02.wav", true);
    PrecacheSound("survival/dropbigguns.wav", true);
    PrecacheSound("survival/breach_activate_nobombs_01.wav", true);
    PrecacheSound("survival/breach_land_01.wav", true);
    PrecacheSound("survival/rocketincoming.wav", true);
    PrecacheSound("survival/rocketalarm.wav", true);
    PrecacheSound("survival/missile_land_01.wav", true);
    PrecacheSound("survival/missile_land_02.wav", true);
    PrecacheSound("survival/missile_land_03.wav", true);
    PrecacheSound("survival/missile_land_04.wav", true);
    PrecacheSound("survival/missile_land_05.wav", true);
    PrecacheSound("survival/missile_land_06.wav", true);

    // Models
    PrecacheModel("models/f18/f18.mdl", true);
    PrecacheModel("models/props_survival/safe/safe_door.mdl", true);
    PrecacheModel("models/props_survival/parachute/chute.mdl", true);
    PrecacheModel("particle/particle_smokegrenade1.vmt", true); 
    PrecacheModel("particle/particle_smokegrenade2.vmt", true); 
    PrecacheModel("particle/particle_smokegrenade3.vmt", true); 
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
    decalSmoke = PrecacheModel("materials/sprites/smoke.vmt", true);
    decalBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

/**
 * @brief Called after a zombie round is started.
 **/
public void ZP_OnGameModeStart(int modeIndex)
{
    // Validate access
    if(ZP_IsGameModeHumanClass(modeIndex, "human") && ZP_GetPlayingAmount() >= ZP_GetWeaponOnline(gWeapon))
    {
        // Get the random index of a human
        int clientIndex = ZP_GetRandomHuman();

        // Validate client
        if(clientIndex != INVALID_ENT_REFERENCE)
        {
            // Validate weapon
            static int weaponIndex;
            if((weaponIndex = ZP_IsPlayerHasWeapon(clientIndex, gWeapon)) != INVALID_ENT_REFERENCE)
            {
                // Reset variables
                SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, STATE_TRIGGER_OFF);
                SetEntProp(weaponIndex, Prop_Data, "m_bIsAutoaimTarget", false);
                SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
            }
            else
            {
                // Give item and select it
                ZP_GiveClientWeapon(clientIndex, gWeapon);

                // Print info
                PrintHintText(clientIndex, "%t", "airdrop info");
            }
        }
    }
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime

    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
    
    // Delete timers
    delete Task_EmitterCreate[clientIndex];
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime
    
    /// Block the real attack
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, !bTrigger ? ANIM_DRAW : iStateMode ? ANIM_DRAW_TRIGGER_ON : ANIM_DRAW_TRIGGER_OFF); 
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime

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
    static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];

    // Validate trigger 
    if(!bTrigger)
    {
        // Gets trace line
        GetClientEyePosition(clientIndex, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, TraceFilter);

        // Validate collisions
        if(TR_DidHit() && TR_GetEntityIndex() < 1)
        {
            // Sets attack animation
            ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT);  
            
            // Create timer for emitter
            delete Task_EmitterCreate[clientIndex]; /// Bugfix
            Task_EmitterCreate[clientIndex] = CreateTimer(ZP_GetWeaponSpeed(gWeapon), Weapon_OnCreateEmitter, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else
    {
        // Gets the controller
        int entityIndex = GetEntPropEnt(weaponIndex, Prop_Data, "m_hDamageFilter"); 

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {    
            // Gets the position/angle
            GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
            GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAngle);

            // Create exp effect
            TE_SetupSparks(vPosition, NULL_VECTOR, 5000, 1000);
            TE_SendToAllInRange(vPosition, RangeType_Visibility);

            // Switch mode
            switch(iStateMode)
            {
                case STATE_TRIGGER_OFF : 
                {
                    // Create a smoke    
                    int smokeIndex = UTIL_CreateSmoke(_, vPosition, vAngle, _, _, _, _, _, _, _, _, _, "255 20 147", "255", "particle/particle_smokegrenade1.vmt", AIRDROP_SMOKE_REMOVE, AIRDROP_SMOKE_TIME);
                    
                    // Sent drop
                    CreateHelicopter(vPosition, vAngle);
                    
                    // Validate entity
                    if(smokeIndex != INVALID_ENT_REFERENCE)
                    {
                        // Emit sound
                        EmitSoundToAll("survival/missile_gas_01.wav", smokeIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                    }
                }
                
                case STATE_TRIGGER_ON : 
                {
                    // Start bombarding
                    CreateJet(vPosition, vAngle);
                    
                    // Emit sound
                    EmitSoundToAll("survival/rocketalarm.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, hSoundLevel.IntValue)
                }
            }
            
            // Remove the entity from the world
            AcceptEntityInput(entityIndex, "Kill");
        }
        
        // Sets attack animation
        ZP_SetWeaponAnimation(clientIndex, iStateMode ? ANIM_SHOOT_TRIGGER_ON : ANIM_SHOOT_TRIGGER_OFF);  
        
        // Remove trigger
        CreateTimer(1.0, Weapon_OnRemove, EntIndexToEntRef(weaponIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime

    // Validate trigger
    if(!bTrigger)
    {
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer") > flCurrentTime)
    {
        return;
    }
    
    // Sets change animation
    ZP_SetWeaponAnimation(clientIndex, iStateMode ? ANIM_SWITCH_TRIGGER_OFF : ANIM_SWITCH_TRIGGER_ON);        

    // Adds the delay to the game tick
    flCurrentTime += WEAPON_TIME_DELAY_SWITCH;

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);   
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets switching time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
    
    // Print info
    PrintHintText(clientIndex, "%t", iStateMode ? "trigger on info" : "trigger off info");
}

/**
 * Timer for creating emitter.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateEmitter(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_EmitterCreate[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
         // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; bool bHit;

        // Gets trace line
        GetClientEyePosition(clientIndex, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, TraceFilter);

        // Validate collisions
        if(TR_DidHit() && TR_GetEntityIndex() < 1)
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vPosition);
            TR_GetPlaneNormal(null, vAngle); 
            
            // Gets the model
            static char sModel[PLATFORM_LINE_LENGTH];
            ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
            
            // Create mine
            int entityIndex = UTIL_CreatePhysics("emitter", vPosition, vAngle, sModel, PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);
            
            // Validate entity
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Sets physics
                SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
                SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                
                // Sets owner to the entity
                SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex);
                SetEntPropEnt(weaponIndex, Prop_Data, "m_hDamageFilter", entityIndex);
                
                // Emit sound
                EmitSoundToAll("survival/breach_land_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            
            // Sets trigger mode
            SetEntProp(weaponIndex, Prop_Data, "m_bIsAutoaimTarget", true);
            
            // Adds the delay to the game tick
            float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon) - 0.3;
            
            // Sets next attack time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
            SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime); 
            
            // Placed successfully
            bHit = true;
        }

        // Adds the delay to the game tick
        float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon) - 0.3;
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

        // Sets pickup animation
        ZP_SetWeaponAnimation(clientIndex, bHit ? ANIM_DRAW_TRIGGER_OFF : ANIM_DRAW);
    }
}

/**
 * Timer for removing trigger.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action Weapon_OnRemove(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int weaponIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(weaponIndex != INVALID_ENT_REFERENCE)
    {
        // Gets the active user
        int clientIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hOwner");

        // Validate client
        if(IsPlayerExist(clientIndex, false))
        {
            // Forces a player to remove weapon
            ZP_RemoveWeapon(clientIndex, weaponIndex);
        }
        else
        {
            AcceptEntityInput(weaponIndex, "Kill");
        }
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
                        \
        GetEntProp(%2, Prop_Data, "m_bIsAutoaimTarget"), \
        GetEntProp(%2, Prop_Data, "m_iMaxHealth"/**/), \
                        \
        GetGameTime()   \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, STATE_TRIGGER_OFF);
        SetEntProp(weaponIndex, Prop_Data, "m_bIsAutoaimTarget", false);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
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
        // Time to apply new mode
        static float flApplyModeTime;
        if((flApplyModeTime = GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
        {
            // Resets the switching time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets different mode
            SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/, !GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/));
            
            // Emit sound
            EmitSoundToAll("survival/breach_activate_nobombs_01.wav", clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
        }
        else
        {
            // Validate state
            if(GetEntProp(weaponIndex, Prop_Data, "m_bIsAutoaimTarget"))
            {
                // Switch animation
                switch(ZP_GetWeaponAnimation(clientIndex))
                {
                    case ANIM_IDLE : ZP_SetWeaponAnimation(clientIndex, GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"/**/) ? ANIM_IDLE_TRIGGER_ON : ANIM_IDLE_TRIGGER_OFF);
                }
            }
        }
    
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex); 
            iButtons &= (~IN_ATTACK);
            return Plugin_Changed;
        }
        // Button secondary attack press
        else if(iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2);
            return Plugin_Changed;
        }
    }

    // Allow button
    return Plugin_Continue;
}

//**********************************************
//* Jet functions.                             *
//**********************************************

/**
 * @brief Create a jet entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.    
 **/
void CreateJet(float vPosition[3], float vAngle[3])
{
    // Add to the position
    vPosition[2] += BOMBARDING_HEIGHT;
    
    // Randomize animation
    //static char sAnim[SMALL_LINE_LENGTH];
    //FormatEx(sAnim, sizeof(sAnim), "flyby%i", GetRandomInt(1, 5));

    // Create a model entity
    int entityIndex = UTIL_CreateDynamic(vPosition, vAngle, "models/f18/f18.mdl", "flyby1");
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Create thinks
        CreateTimer(2.7, JetBombHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(6.6, HelicopterRemoveHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE); /// Use similar function
    }
}

/**
 * @brief Main timer for spawn bomb.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action JetBombHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Emit sound
        EmitSoundToAll("survival/rocketincoming.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);

        // Initialize vectors
        static float vPosition[3]; static float vAngle[3];

        // Gets the position/angle
        ZP_GetAttachment(entityIndex, "sound_maker", vPosition, vAngle);
        
        // Create all paths and link them together
        // This has to be done in reverse since target linking is done on entity activation
        static char sTrack[SMALL_LINE_LENGTH]; static char sNextTrack[SMALL_LINE_LENGTH];
        FormatEx(sTrack, sizeof(sTrack), "nucpath1%i", entityIndex); vPosition[2] -= BOMBARDING_HEIGHT;
        UTIL_CreatePath(sTrack, vPosition, NULL_VECTOR, "");
        strcopy(sNextTrack, sizeof(sNextTrack), sTrack);
        FormatEx(sTrack, sizeof(sTrack), "nucpath0%i", entityIndex); vPosition[2] += BOMBARDING_HEIGHT;
        UTIL_CreatePath(sTrack, vPosition, NULL_VECTOR, sNextTrack); 

        // Spawn bomb
        FormatEx(sNextTrack, sizeof(sNextTrack), "nuclear%i", entityIndex);
        entityIndex = UTIL_CreateTrain(sNextTrack, vPosition, NULL_VECTOR, sTrack, BOMBARDING_SPEED, _, TRAIN_NOCONTROL | TRAIN_PASSABLE | TRAIN_UNBLOCKABLE);

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            /// Fix angles (because of train attach)
            vAngle[0] = 90.0; vAngle[1] = 90.0; vAngle[2] = 270.0;
    
            // Create a model entity
            int modelIndex = UTIL_CreateDynamic(vPosition, vAngle, "models/weapons/nucler/w_ailerons.mdl", "idle");

            // Validate entity
            if(modelIndex != INVALID_ENT_REFERENCE)
            {
                // Sets the parent for the entity
                SetVariantString("!activator");
                AcceptEntityInput(modelIndex, "SetParent", entityIndex, modelIndex);
            }
        }
    }
}

/**
 * @brief Called when a bomb touch the ground.
 *
 * @param entityIndex       The entity index.
 **/ 
void BombLandHook(int entityIndex)
{
    // Gets entity position
    static float vPosition[3];
    GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);

    // Create an explosion effect
    UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500", BOMBARDING_EXPLOSION_TIME);
    UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500_fallback", BOMBARDING_EXPLOSION_TIME);
    
    // Find any players in the radius
    int i; int it = 1; /// iterator
    while((i = ZP_FindPlayerInSphere(it, vPosition, BOMBARDING_RADIUS)) != INVALID_ENT_REFERENCE)
    {
        // Skip humans
        if(ZP_IsPlayerHuman(i))
        {
            continue;
        }
        
        // Forces a player to commit suicide
        ForcePlayerSuicide(i);
    }
    
    // Emit sound
    switch(GetRandomInt(0, 5))
    {
        case 0 : EmitSoundToAll("survival/missile_land_01.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);
        case 1 : EmitSoundToAll("survival/missile_land_02.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);
        case 2 : EmitSoundToAll("survival/missile_land_03.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);
        case 3 : EmitSoundToAll("survival/missile_land_04.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);
        case 4 : EmitSoundToAll("survival/missile_land_05.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);
        case 5 : EmitSoundToAll("survival/missile_land_06.wav", entityIndex, SNDCHAN_STATIC, SNDLEVEL_AIRCRAFT);
    }

    // Remove the entity from the world
    AcceptEntityInput(entityIndex, "Kill");
}

//**********************************************
//* Helicopter functions.                      *
//**********************************************

/**
 * @brief Create a helicopter entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.                    
 **/
void CreateHelicopter(float vPosition[3], float vAngle[3])
{
    // Add to the position
    vPosition[2] += AIRDROP_HEIGHT;
    
    // Create a model entity
    int entityIndex = UTIL_CreateDynamic(vPosition, vAngle, "models/buildables/helicopter_rescue_v2.mdl", "helicopter_coop_hostagepickup_flyin");
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Create thinks
        CreateTimer(20.0, HelicopterDropHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(0.41, HelicopterSoundHook, EntIndexToEntRef(entityIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Main timer for creating drop.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterDropHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3];

        // Set idle
        SetAnimation(entityIndex, "helicopter_coop_hostagepickup_idle");

        // Gets the position/angle
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
        GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAngle);
        
        // Emit sound
        EmitSoundToAll("survival/dropbigguns.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Create all paths and link them together
        // This has to be done in reverse since target linking is done on entity activation
        static char sTrack[SMALL_LINE_LENGTH]; static char sNextTrack[SMALL_LINE_LENGTH];
        FormatEx(sTrack, sizeof(sTrack), "safepath1%i", entityIndex); vPosition[2] -= AIRDROP_HEIGHT;
        UTIL_CreatePath(sTrack, vPosition, NULL_VECTOR, "");
        strcopy(sNextTrack, sizeof(sNextTrack), sTrack);
        FormatEx(sTrack, sizeof(sTrack), "safepath0%i", entityIndex); vPosition[2] += AIRDROP_HEIGHT;
        UTIL_CreatePath(sTrack, vPosition, NULL_VECTOR, sNextTrack); 
        
        // Sets idle
        CreateTimer(5.0, HelicopterIdleHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        
        // Spawn drop
        FormatEx(sNextTrack, sizeof(sNextTrack), "safedrop%i", entityIndex);
        entityIndex = UTIL_CreateTrain(sNextTrack, vPosition, NULL_VECTOR, sTrack, AIRDROP_SPEED, _, TRAIN_NOCONTROL | TRAIN_PASSABLE | TRAIN_UNBLOCKABLE);

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            /// Fix angles (because of train attach)
            vAngle[0] = 0.0; vAngle[1] = 90.0; vAngle[2] = 270.0;
    
            // Create a model entity
            int modelIndex = UTIL_CreateDynamic(vPosition, vAngle, "models/buildables/safe.mdl", "ref");

            // Validate entity
            if(modelIndex != INVALID_ENT_REFERENCE)
            {
                // Sets the parent for the entity
                SetVariantString("!activator");
                AcceptEntityInput(modelIndex, "SetParent", entityIndex, modelIndex);
                SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", modelIndex);
            }

            // Create a model entity
            int modelIndex2 = UTIL_CreateDynamic(NULL_VECTOR, NULL_VECTOR, "models/props_survival/parachute/chute.mdl", "open");

            // Validate entity
            if(modelIndex2 != INVALID_ENT_REFERENCE)
            {
                // Emit sound
                EmitSoundToAll("survival/dropzone_parachute_deploy.wav", modelIndex2, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
                // Sets parent to the entity
                SetVariantString("!activator"); 
                AcceptEntityInput(modelIndex2, "SetParent", modelIndex, modelIndex2); 
                SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", modelIndex2);

                // Sets attachment to the entity
                SetVariantString("forward");
                AcceptEntityInput(modelIndex2, "SetParentAttachment", modelIndex, modelIndex2);
                
                // Sets idle
                CreateTimer(0.3, ParachuteIdleHook, EntIndexToEntRef(modelIndex2), TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }
}

/**
 * @brief Main timer for creating sound. (Helicopter)
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterSoundHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3];

        // Gets the position/angle
        ZP_GetAttachment(entityIndex, "dropped", vPosition, vAngle); 

        // Play sound
        ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD, SNDLEVEL_HELICOPTER); 
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
 * @brief Main timer for idling helicopter.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterIdleHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Set idle
        SetAnimation(entityIndex, "helicopter_coop_towerhover_idle");
        
        // Sets flying
        CreateTimer(6.6, HelicopterFlyHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Main timer for flyway of helicopter.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterFlyHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Set idle
        SetAnimation(entityIndex, "helicopter_coop_towerhover_flyaway");
        
        // Sets flying
        CreateTimer(8.3, HelicopterRemoveHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Main timer for idling helicopter.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterRemoveHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        /// Destroy
        AcceptEntityInput(entityIndex, "Kill"); 
    }
}

/**
 * @brief Main timer for idling parachute.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action ParachuteIdleHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Set idle
        SetAnimation(entityIndex, "idle");
        
        // Emit sound
        EmitSoundToAll("survival/dropzone_freefall.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }
}

/**
 * @brief Called when a drop touch the ground.
 *
 * @param entityIndex       The entity index.
 **/ 
void DropLandHook(int entityIndex)
{
    // Gets the parachute entity
    int modelIndex = GetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity");
    
    // Validate entity
    if(modelIndex != INVALID_ENT_REFERENCE)
    {
        // Set close
        SetAnimation(modelIndex, "collapse");
        
        // Emit sound
        EmitSoundToAll(GetRandomInt(0, 1) ? "survival/dropzone_parachute_success_02.wav" : "survival/dropzone_parachute_success.wav", modelIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }
    
    // Replace drop
    CreateTimer(0.2, DropReplaceHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
}

/**
 * @brief Main timer for replace drop.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action DropReplaceHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vMins[3]; static float vMaxs[3];

        // Gets the safe
        int modelIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_pParent");
        
        // Validate entity
        if(modelIndex != INVALID_ENT_REFERENCE)
        {
            // Gets the position/angle/size
            GetEntPropVector(modelIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
            GetEntPropVector(modelIndex, Prop_Data, "m_angAbsRotation", vAngle);
            GetEntPropVector(modelIndex, Prop_Data, "m_vecMins", vMins);
            GetEntPropVector(modelIndex, Prop_Data, "m_vecMaxs", vMaxs);
        }

        // Destroy!
        AcceptEntityInput(entityIndex, "Kill");

        // Create the hull trace
        vPosition[2] += vMaxs[2] / 2; /// Move center of hull upward
        TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
        
        // Validate collisions
        if(TR_GetFraction() < 1.0)
        {
            // Gets victim index
            int victimIndex = TR_GetEntityIndex();
            
            // Validate victim
            if(IsPlayerExist(victimIndex))
            {    
                // Kill it
                ForcePlayerSuicide(victimIndex);
            }
        }
        
        // Replace with physics object
        entityIndex = UTIL_CreatePhysics("safe", vPosition, vAngle, "models/buildables/safe.mdl", PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Sets physics
            SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
            SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);

            // Sets health
            SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
            SetEntProp(entityIndex, Prop_Data, "m_iHealth", AIRDROP_HEALTH);
            SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", AIRDROP_HEALTH);
            
            // Sets counter
            SetEntProp(entityIndex, Prop_Data, "m_iHammerID", 0);
            
            // Create damage hook
            SDKHook(entityIndex, SDKHook_OnTakeDamage, DropDamageHook);
        }
        
        // Create landing effect
        TE_SetupSmoke(vPosition, decalSmoke, 100.0, 10);
        TE_SendToAllInRange(vPosition, RangeType_Visibility);
        TE_SetupDust(vPosition, NULL_VECTOR, 50.0, 1.0);
        TE_SendToAllInRange(vPosition, RangeType_Visibility);
        
        // Print info
        PrintHintTextToAll("%t", "airdrop safe", AIRDROP_EXPLOSIONS);
    }
}

/**
 * @brief Drop damage hook.
 *
 * @param entityIndex       The entity index.    
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action DropDamageHook(int entityIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits)
{
    // Emit sound
    switch(GetRandomInt(0, 4))
    {
        case 0 : EmitSoundToAll("survival/container_damage_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 1 : EmitSoundToAll("survival/container_damage_02.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 2 : EmitSoundToAll("survival/container_damage_03.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 3 : EmitSoundToAll("survival/container_damage_04.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 4 : EmitSoundToAll("survival/container_damage_05.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }
    
    // Validate mode
    if(GetEntProp(entityIndex, Prop_Send, "m_nBody"))
    {
        // Calculate the damage
        int iHealth = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

        // Destroy entity
        if(!iHealth)
        {
            // Destroy damage hook
            SDKUnhook(entityIndex, SDKHook_OnTakeDamage, DropDamageHook);

            // Initialize vectors
            static float vGibAngle[3]; float vShootAngle[3];
            
            // Create a breaked drone effect
            static char sBuffer[SMALL_LINE_LENGTH];
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
                UTIL_CreateShooter(entityIndex, "forward", _, MAT_METAL, sBuffer, vShootAngle, vGibAngle, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
            }
            
            // Emit sound
            switch(GetRandomInt(0, 2))
            {
                case 0 : EmitSoundToAll("survival/container_death_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                case 1 : EmitSoundToAll("survival/container_death_02.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                case 2 : EmitSoundToAll("survival/container_death_03.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }

            // Kill after some duration
            UTIL_RemoveEntity(entityIndex, 0.1);
        }
        else
        {
            // Apply damage
            SetEntProp(entityIndex, Prop_Data, "m_iHealth", iHealth);
        }
    }
    else
    {
        // Validate inflicter
        if(IsValidEdict(inflictorIndex))
        {
            // Gets weapon classname
            static char sClassname[PLATFORM_LINE_LENGTH];
            GetEdictClassname(inflictorIndex, sClassname, sizeof(sClassname));
        
            // Validate c4 projectile
            if(!strncmp(sClassname, "brea", 4, false))
            {
                // Increment explosions
                int iExp = GetEntProp(entityIndex, Prop_Data, "m_iHammerID") + 1;
                SetEntProp(entityIndex, Prop_Data, "m_iHammerID", iExp);
        
                // Validate explosions
                if(iExp >= AIRDROP_EXPLOSIONS)
                {
                    // Initialize vectors
                    static float vPosition[3]; static float vAngle[3];
                    
                    // Open door
                    SetEntProp(entityIndex, Prop_Send, "m_nBody", 1);
                    
                    // x = weapon index
                    for(int x = 0; x < AIRDROP_WEAPONS; x++)
                    {
                        // Randomize position
                        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
                        GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAngle);
                        vPosition[0] += GetRandomFloat(-5.0, 5.0);
                        vPosition[1] += GetRandomFloat(-5.0, 5.0);
                        vPosition[2] += 10.0 + GetRandomFloat(-5.0, 5.0);
                        
                        // Randomize index
                        int iD = GetRandomInt(0, ZP_GetNumberWeapon() - 1);
                        
                        // Validate class/drop/slot
                        ZP_GetWeaponClass(iD, sClassname, sizeof(sClassname));
                        if(StrContains(sClassname, "human", false) == -1 || !ZP_IsWeaponDrop(iD) || ZP_GetWeaponSlot(iD) == MenuType_Knifes)
                        {
                            x--;
                            continue;
                        }
                        
                        // Validate classname
                        ZP_GetWeaponEntity(iD, sClassname, sizeof(sClassname));
                        if(!strncmp(sClassname, "item_", 5, false))
                        {
                            x--;
                            continue;
                        }
                        
                        // Create a random weapon entity
                        int weaponIndex = CreateEntityByName(sClassname);
                        
                        // Validate entity
                        if(weaponIndex != INVALID_ENT_REFERENCE)
                        {
                            // Spawn the entity into the world
                            if(DispatchSpawn(weaponIndex))
                            {
                                // Teleport the entity
                                TeleportEntity(weaponIndex, vPosition, vAngle, NULL_VECTOR);
                            
                                // Remove physics
                                SetEntityMoveType(weaponIndex, MOVETYPE_NONE);
                            
                                // Sets the custom weapon id
                                SetEntProp(weaponIndex, Prop_Data, "m_iHammerID", iD);
                            
                                // Sets the model
                                ZP_GetWeaponModelDrop(iD, sClassname, sizeof(sClassname));
                                if(sClassname[0] != '\0') SetEntityModel(weaponIndex, sClassname);
                            }
                        }
                    }
                    
                    // Gets the position/angle
                    ZP_GetAttachment(entityIndex, "door", vPosition, vAngle);
                    
                    // Create door
                    entityIndex = UTIL_CreatePhysics("door", vPosition, vAngle, "models/props_survival/safe/safe_door.mdl", PHYS_FORCESERVERSIDE);
                    
                    // Validate entity
                    if(entityIndex != INVALID_ENT_REFERENCE)
                    {
                        // Sets physics
                        SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
                        SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                    }
                }
            }
        }
    }
    
    // Return on success
    return Plugin_Handled;
}

//**********************************************
//* Item (npc) stocks.                         *
//**********************************************

/**
 * @brief Play the animation of the entity.
 * 
 * @param entityIndex       The entity index.        
 * @param sAnim             The animation name.     
 * @param iBodyGroup        (Optional) The bodygroup index.
 **/
stock void SetAnimation(int entityIndex, char[] sAnim, int iBodyGroup = 0)
{
    // Sets bodygroup of the model
    SetVariantInt(iBodyGroup);
    AcceptEntityInput(entityIndex, "SetBodyGroup");
    
    // Play animation of the model
    SetVariantString(sAnim);
    AcceptEntityInput(entityIndex, "SetAnimation");
}

/**
 * @brief Validate the entity's classname.
 *
 * @param entityIndex       The entity index.
 * @param sClassname        The classname string.
 * @param iMaxLen           The lenght of checking.
 *
 * @return                  True or false.
 **/
stock bool ValidateName(int entityIndex, char[] sClassname, int iMaxLen)
{
    static char sName[SMALL_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sName, sizeof(sName));
    
    // Validate string
    return (!strncmp(sName, sClassname, iMaxLen, false));
}

/**
 * @brief Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @return                  True or false.
 **/
public bool TraceFilter(int entityIndex, int contentsMask)
{
    return !(1 <= entityIndex <= MaxClients);
}