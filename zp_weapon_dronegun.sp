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
#include <cstrike>
#include <zombieplague>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] ExtraItem: DroneGun",
    author          = "qubka (Nikita Ushakov) | Pelipoika",     
    description     = "Addon of extra items",
    version         = "2.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Timer index
Handle Task_TurretCreate[MAXPLAYERS+1] = null; 

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel 
 
// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
 * @section Variables to store virtual SDK adresses.
 **/
Handle hSDKCallStudioFrameAdvance; 
Handle hSDKCallAddLayeredSequence;
int AnimatingOverlay_Count;
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
 * @section Properties of the turret.
 **/
#define SENTRY_ATTACK_NPC             // Uncomment to avoid attack chichens and npc
#define SENTRY_BULLET_DAMAGE          20.0
#define SENTRY_BULLET_RANGE           1100.0
#define SENTRY_BULLET_RADIUS          5.0
#define SENTRY_BULLET_TURN            2.0
#define SENTRY_BULLET_THINK           0.05
#define SENTRY_BULLET_SPEED           0.2
#define SENTRY_EYE_OFFSET_LEVEL_1     32.0 
#define SENTRY_EYE_OFFSET_LEVEL_2     40.0 
#define SENTRY_EYE_OFFSET_LEVEL_3     46.0
#define SENTRY_SHOOTER_OFFSET_LEVEL   66.0
#define SENTRY_ROCKET_DELAY           3.0
#define SENTRY_ROCKET_RELOAD          1.8
#define SENTRY_ROCKET_SPEED           1000.0
#define SENTRY_ROCKET_DAMAGE          300.0
#define SENTRY_ROCKET_KNOCKBACK       300.0
#define SENTRY_ROCKET_GRAVITY         0.01
#define SENTRY_ROCKET_RADIUS          400.0
#define SENTRY_ROCKET_EFFECT_TIME     5.0
#define SENTRY_ROCKET_EXPLOSION_TIME  2.0
/**
 * @endsection
 **/
 
/**
 * @section Sentry states.
 **/ 
enum 
{ 
    SENTRY_STATE_SEARCHING, 
    SENTRY_STATE_ATTACKING
}; 
/**
 * @endsection
 **/
 
/**
 * @section Sentry modes.
 **/ 
enum 
{ 
    SENTRY_MODE_NORMAL, 
    SENTRY_MODE_AGRESSIVE,
    SENTRY_MODE_ROCKET
}; 
/**
 * @endsection
 **/
 
/**
 * @section Sentry sounds.
 **/ 
enum 
{ 
    SENTRY_SOUND_EMPTY = 1,
    SENTRY_SOUND_FINISH,
    SENTRY_SOUND_SCAN,
    SENTRY_SOUND_SCAN2,
    SENTRY_SOUND_SCAN3,
    SENTRY_SOUND_SHOOT,
    SENTRY_SOUND_SHOOT2, 
    SENTRY_SOUND_SHOOT3,
    SENTRY_SOUND_SHOOT4,
    SENTRY_SOUND_SPOT,
    SENTRY_SOUND_SPOT2,
    SENTRY_SOUND_ROCKET,
    SENTRY_SOUND_EXPLOAD
};
/**
 * @end
 **/
 
// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT,
    ANIM_DRAW
};

/**
 * @brief Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
    // Loads a game config file
    Handle hConfig = LoadGameConfigFile("plugin.turret"); 

    /*__________________________________________________________________________________________________*/
    
    // Load other offsets
    if((AnimatingOverlay_Count = GameConfGetOffset(hConfig, "CBaseAnimatingOverlay::Count")) == -1) SetFailState("Failed to get offset: \"CBaseAnimatingOverlay::Count\". Update offset in \"plugin.turret\""); 

    /*__________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity); 
    PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimatingOverlay::StudioFrameAdvance"); 
    
    // Validate call
    if((hSDKCallStudioFrameAdvance = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimatingOverlay::StudioFrameAdvance\". Update signature in \"plugin.turret\"");      
    
    /*__________________________________________________________________________________________________*/
    
    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimatingOverlay::AddLayeredSequence"); 
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

    // Validate call
    if((hSDKCallAddLayeredSequence = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimatingOverlay::AddLayeredSequence\". Update signature in \"plugin.turret\""); 
    
    /*__________________________________________________________________________________________________*/

    // Close file
    delete hConfig;
}

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
    gItem = ZP_GetExtraItemNameID("drone gun");
    if(gItem == -1) SetFailState("[ZP] Custom extraitem ID from name : \"drone gun\" wasn't find");
    
    // Weapons
    gWeapon = ZP_GetWeaponNameID("drone gun");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"drone gun\" wasn't find");
    
    // Sounds
    gSound = ZP_GetSoundKeyID("TURRET_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TURRET_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Sounds
    PrecacheSound("survival/turret_death_01.wav", true);
    PrecacheSound("survival/turret_takesdamage_01.wav", true);
    PrecacheSound("survival/turret_takesdamage_02.wav", true);
    PrecacheSound("survival/turret_takesdamage_03.wav", true);
    
    // Models
    PrecacheModel("models/props_survival/dronegun/dronegun.mdl", true);
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
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
        Task_TurretCreate[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete Task_TurretCreate[clientIndex];
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

#define ANIM_LAYER_ACTIVE        0x0001 
#define ANIM_LAYER_AUTOKILL      0x0002 
#define ANIM_LAYER_KILLME        0x0004 
#define ANIM_LAYER_DONTRESTORE   0x0008 
#define ANIM_LAYER_CHECKACCESS   0x0010 
#define ANIM_LAYER_DYING         0x0020
#define ANIM_LAYER_NOEVENTS      0x0040

enum //CAnimationLayer 
{
    m_fFlags = 0,
    m_bSequenceFinished = 4,
    m_bLooping = 5,
    m_nSequence = 8,
    m_flCycle = 12,
    m_flPlaybackRate = 16,
    m_flPrevCycle = 20,
    m_flWeight = 24,
    m_flWeightDeltaRate = 28,
    m_flBlendIn = 32,
    m_flBlendOut = 36,
    m_flKillRate = 40,
    m_flKillDelay = 44,
    m_flLayerAnimtime = 48,
    m_flLayerFadeOuttime = 52,
    /*
        ??? = 56,
        ??? = 60,
        ??? = 64,
    */
    m_nActivity = 68,
    m_nPriority = 72,
    m_nOrder = 76,
    m_flLastEventCheck = 80,
    m_flLastAccess = 84,
    m_pOwnerEntity = 88,
    CAnimationLayer_Size = 92
};

methodmap CAnimationOverlay  
{ 
    public CAnimationOverlay(int address)
    {
        return view_as<CAnimationOverlay>(address);
    }
    
    property Address Address  
    { 
        public get()  
        { 
            return view_as<Address>(this); 
        } 
    } 
    
    property bool isNull
    {
        public get()  
        { 
            return this.Address == Address_Null; 
        } 
    }

    public any Get(int iOffset, int iLayer) 
    { 
        return LoadFromAddress(this.Address + view_as<Address>(iOffset + CAnimationLayer_Size * iLayer), NumberType_Int32); 
    } 
     
    public void Set(int iOffset, int iLayer, any iValue) 
    { 
        StoreToAddress(this.Address + view_as<Address>(iOffset + CAnimationLayer_Size * iLayer), iValue, NumberType_Int32); 
    } 

    public bool IsActive(int iLayer)    { return ((this.Get(m_fFlags, iLayer) & ANIM_LAYER_ACTIVE)   != 0); } 
    public bool IsAutokill(int iLayer)  { return ((this.Get(m_fFlags, iLayer) & ANIM_LAYER_AUTOKILL) != 0); } 
    public bool IsKillMe(int iLayer)    { return ((this.Get(m_fFlags, iLayer) & ANIM_LAYER_KILLME)   != 0); } 
    public bool IsDying(int iLayer)     { return ((this.Get(m_fFlags, iLayer) & ANIM_LAYER_DYING)    != 0); } 
    public bool NoEvents(int iLayer)    { return ((this.Get(m_fFlags, iLayer) & ANIM_LAYER_NOEVENTS) != 0); }
    public void KillMe(int iLayer)      { int iFlags = this.Get(m_fFlags, iLayer); this.Set(m_fFlags, iLayer, (iFlags |= ANIM_LAYER_KILLME)); } 
    public void AutoKill(int iLayer)    { int iFlags = this.Get(m_fFlags, iLayer); this.Set(m_fFlags, iLayer, (iFlags |= ANIM_LAYER_AUTOKILL)); }
    public void Dying(int iLayer)       { int iFlags = this.Get(m_fFlags, iLayer); this.Set(m_fFlags, iLayer, (iFlags |= ANIM_LAYER_DYING));  } 
    public void Dead(int iLayer)        { int iFlags = this.Get(m_fFlags, iLayer); this.Set(m_fFlags, iLayer, (iFlags &= ~ANIM_LAYER_DYING)); }
    public void Loop(int iLayer)        { int iFlags = this.Get(m_fFlags, iLayer); this.Set(m_fFlags, iLayer, (iFlags &= ~ANIM_LAYER_AUTOKILL)); }
    
    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.cpp#L1073
    public void RemoveLayer(int iLayer, float flKillRate, float flKillDelay)
    {
        this.Set(m_flKillRate, iLayer, flKillRate > 0.0 ? this.Get(m_flWeight, iLayer) / flKillRate : 100.0);
        this.Set(m_flKillDelay, iLayer, flKillDelay);
        this.KillMe(iLayer);
    }
    
    // @link https://github.com/droozynuu/swarm-sdk-template/blob/79af61e7756be2921eebf917e35a42577c9ca9ec/src/game/server/BaseAnimatingOverlay.cpp#L1025
    public void SetLayerAutokill(int iLayer, bool bAutokill)
    {
        if(bAutokill)
        {
            this.AutoKill(iLayer);
        }
        else
        {
            this.Loop(iLayer);
        }
    }
    
    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.cpp#L815
    public bool IsAlive(int iLayer)         { int iFlags = this.Get(m_fFlags, iLayer); return (((iFlags & ANIM_LAYER_ACTIVE) != 0) || ((iFlags & ANIM_LAYER_KILLME) == 0)); }
    
    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.cpp#L1060
    public int GetLayerSequence(int iLayer) { return (this.Get(m_nSequence, iLayer)); }
}

methodmap SentryGun /** Regards to Pelipoika **/
{
    // Constructor
    public SentryGun(int ownerIndex, float vPosition[3], float vAngle[3], int iHealth, int iAmmo, int iRocket, int iUpgradeLevel) 
    {
        // Gets the model for the current mode
        static char sModel[PLATFORM_LINE_LENGTH]; int iSkin; int iBody;
        switch(iUpgradeLevel)
        {
            case SENTRY_MODE_NORMAL    : { strcopy(sModel, sizeof(sModel), "models/buildables/sentry1.mdl");      iSkin = GetRandomInt(0, 3); }
            case SENTRY_MODE_AGRESSIVE : { strcopy(sModel, sizeof(sModel), "models/buildables/sentry2.mdl");      iSkin = GetRandomInt(0, 1); }
            case SENTRY_MODE_ROCKET    : { strcopy(sModel, sizeof(sModel), "models/buildables/sentry3_fix2.mdl"); iSkin = GetRandomInt(0, 1); }
        }
    
        // Create a monster entity
        int entityIndex = UTIL_CreateMonster("turret", vPosition, vAngle, sModel, NPC_GAG | NPC_WAITFORSCRIPT | NPC_DONTDROPWEAPONS | NPC_IGNOREPLAYERPUSH);
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Initialize vectors
            static float vAbsAngle[3]; static float vGoalAngle[3]; static float vCurAngle[3]; 
            
            // Gets the angles
            GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAbsAngle); 
            
            // Sets the boundaries
            int iRightBound = RoundToNearest(AngleMod(vAbsAngle[1] - 50.0)); 
            int iLeftBound  = RoundToNearest(AngleMod(vAbsAngle[1] + 50.0)); 
            if(iRightBound > iLeftBound) 
            { 
                iRightBound = iLeftBound; 
                iLeftBound = RoundToNearest(AngleMod(vAbsAngle[1] - 50)); 
            }
            SetEntProp(entityIndex, Prop_Data, "m_iSpeedModSpeed", iRightBound); 
            SetEntProp(entityIndex, Prop_Data, "m_iSpeedModRadius", iLeftBound); 
            
            // Start it rotating
            vGoalAngle[1] = float(iRightBound); 
            vGoalAngle[0] = vCurAngle[0] = 0.0; 
            vCurAngle[1] = AngleMod(vAbsAngle[1]); 
            SetEntPropVector(entityIndex, Prop_Data, "m_vecLastPosition", vCurAngle); 
            SetEntPropVector(entityIndex, Prop_Data, "m_vecStoredPathGoal", vGoalAngle);
            SetEntProp(entityIndex, Prop_Data, "m_bSpeedModActive", true); 
            SetEntProp(entityIndex, Prop_Data, "m_NPCState", SENTRY_STATE_SEARCHING); 
            
            /**__________________________________________________________**/

            // Sets physics
            /*SetEntityMoveType(parentIndex, MOVETYPE_NONE);
            SetEntProp(parentIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON); 
            SetEntProp(parentIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);*/
            
            // Sets effects
            if(iSkin == 3) iBody = GetRandomInt(0, 1);
            SetEntProp(entityIndex, Prop_Send, "m_nSkin", iSkin);
            SetEntProp(entityIndex, Prop_Send, "m_nBody", iBody);

            // Sets health
            SetEntProp(entityIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
            SetEntProp(entityIndex, Prop_Data, "m_iHealth", iHealth);
            SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", iHealth);

            // Sets owner for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", ownerIndex); 

            // Sets ammunition and mode
            SetEntProp(entityIndex, Prop_Data, "m_iAmmo", iAmmo); 
            SetEntProp(entityIndex, Prop_Data, "m_iMySquadSlot", iRocket); 
            SetEntProp(entityIndex, Prop_Data, "m_iDesiredWeaponState", iUpgradeLevel); 
            
            // Create think/damage hook
            SDKHook(entityIndex, SDKHook_SetTransmit, SentryThinkHook);
            SDKHook(entityIndex, SDKHook_OnTakeDamage, SentryDamageHook);
          }
        
        // Return index on the success
        return view_as<SentryGun>(entityIndex); 
    } 
    
    /*__________________________________________________________________________________________________*/
     
    property int Index 
    { 
        public get() 
        {  
            return view_as<int>(this);  
        } 
    }
    
    property float NextAttack
    {
        public get() 
        {  
            return GetEntPropFloat(this.Index, Prop_Data, "m_flLastAttackTime");  
        }

        public set(float flDelay) 
        {
            SetEntPropFloat(this.Index, Prop_Data, "m_flLastAttackTime", flDelay); 
        }
    }
    
    property float NextRocket
    {
        public get() 
        {  
            return GetEntPropFloat(this.Index, Prop_Data, "m_flNextWeaponSearchTime");  
        }

        public set(float flDelay) 
        {
            SetEntPropFloat(this.Index, Prop_Data, "m_flNextWeaponSearchTime", flDelay); 
        }
    }
    
    property float TurnRate
    {
        public get() 
        {  
            return GetEntPropFloat(this.Index, Prop_Data, "m_flNextDecisionTime");  
        }

        public set(float flRate) 
        {
            SetEntPropFloat(this.Index, Prop_Data, "m_flNextDecisionTime", flRate); 
        }
    }
    
    property int Owner
    { 
        public get() 
        {  
            return GetEntPropEnt(this.Index, Prop_Data, "m_pParent");  
        }

        public set(int entityIndex) 
        {
            SetEntPropEnt(this.Index, Prop_Data, "m_pParent", entityIndex); 
        }
    } 
    
    property int Enemy
    { 
        public get() 
        {  
            return GetEntPropEnt(this.Index, Prop_Data, "m_hEnemy");  
        }

        public set(int entityIndex) 
        {
            SetEntPropEnt(this.Index, Prop_Data, "m_hEnemy", entityIndex); 
        }
    } 
    
    property int Health
    { 
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Data, "m_iHealth");  
        }

        public set(int iHealth) 
        {
            SetEntProp(this.Index, Prop_Data, "m_iHealth", iHealth); 
        }
    } 
    
    property int State
    { 
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Data, "m_NPCState");  
        }

        public set(int iState) 
        {
            SetEntProp(this.Index, Prop_Data, "m_NPCState", iState); 
        }
    } 
    
    property int RightBound
    { 
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Data, "m_iSpeedModSpeed");  
        }

        public set(int iBound) 
        {
            SetEntProp(this.Index, Prop_Data, "m_iSpeedModSpeed", iBound); 
        }
    } 
    
    property int LeftBound
    { 
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Data, "m_iSpeedModRadius");  
        }

        public set(int iBound) 
        {
            SetEntProp(this.Index, Prop_Data, "m_iSpeedModRadius", iBound); 
        }
    } 
    
    property bool TurningRight
    { 
        public get() 
        {  
            return view_as<bool>(GetEntProp(this.Index, Prop_Data, "m_bSpeedModActive"));  
        }

        public set(bool bState) 
        {
            SetEntProp(this.Index, Prop_Data, "m_bSpeedModActive", bState); 
        }
    }
    
    property int Ammo
    { 
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Data, "m_iAmmo");  
        }

        public set(int iAmmo) 
        {
            SetEntProp(this.Index, Prop_Data, "m_iAmmo", iAmmo); 
        }
    }
    
    property int Body
    { 
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Send, "m_nBody");  
        }

        public set(int iBody) 
        {
            SetEntProp(this.Index, Prop_Send, "m_nBody", iBody); 
        }
    }
    
    property int Rockets
    {
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Data, "m_iMySquadSlot");  
        }

        public set(int iRocket) 
        {
            SetEntProp(this.Index, Prop_Data, "m_iMySquadSlot", iRocket); 
        }
    }
    
    property int UpgradeLevel
    {
        public get() 
        {  
            return GetEntProp(this.Index, Prop_Data, "m_iDesiredWeaponState");  
        }

        public set(int iLevel) 
        {
            SetEntProp(this.Index, Prop_Data, "m_iDesiredWeaponState", iLevel); 
        }
    }

    /*__________________________________________________________________________________________________*/
    
    public void GetCurAngles(float vOutput[3])
    {
        GetEntPropVector(this.Index, Prop_Data, "m_vecLastPosition", vOutput); 
    }
    
    public void SetCurAngles(float vInput[3])
    {
        SetEntPropVector(this.Index, Prop_Data, "m_vecLastPosition", vInput); 
    }
    
    public void GetGoalAngles(float vOutput[3])
    {
        GetEntPropVector(this.Index, Prop_Data, "m_vecStoredPathGoal", vOutput); 
    }
    
    public void SetGoalAngles(float vInput[3])
    {
        SetEntPropVector(this.Index, Prop_Data, "m_vecStoredPathGoal", vInput); 
    }

    public void GetAbsAngles(float vOutput[3]) 
    {  
        GetEntPropVector(this.Index, Prop_Data, "m_angAbsRotation", vOutput); 
    } 
    
    public void GetGunPosition(float vOutput[3]) 
    {
        GetAbsOrigin(this.Index, vOutput); 
        switch(this.UpgradeLevel) 
        { 
            case SENTRY_MODE_NORMAL    : vOutput[2] += SENTRY_EYE_OFFSET_LEVEL_1; 
            case SENTRY_MODE_AGRESSIVE : vOutput[2] += SENTRY_EYE_OFFSET_LEVEL_2; 
            case SENTRY_MODE_ROCKET    : vOutput[2] += SENTRY_EYE_OFFSET_LEVEL_3; 
        }
    } 
    
    public void GetLauncherPosition(float vOutput[3]) 
    {
        GetAbsOrigin(this.Index, vOutput); 
        vOutput[2] += SENTRY_SHOOTER_OFFSET_LEVEL; 
    } 

    /*__________________________________________________________________________________________________*/
    
    public CAnimationOverlay CBaseAnimatingOverlay() 
    { 
        static int iOffset;
        if(!iOffset) iOffset = FindDataMapInfo(this.Index, "m_AnimOverlay");
        return CAnimationOverlay(GetEntData(this.Index, iOffset));
    }
    
    public void SetPoseParameter(int iParameter, float flStart, float flEnd, float flValue)    
    { 
        float flCtl = (flValue - flStart) / (flEnd - flStart); 
        if(flCtl < 0) flCtl = 0.0; 
        if(flCtl > 1) flCtl = 1.0; 
         
        SetEntPropFloat(this.Index, Prop_Send, "m_flPoseParameter", flCtl, iParameter); 
    } 
    
    public int LookupPoseParameter(char[] sName)    
    {
        // Validate address
        /*Address pStudioHdrClass = this.GetStudioHdr(); 
        if(pStudioHdrClass == Address_Null) 
        {
            return -1; 
        }
        
        return SDKCall(hSDKCallLookupPoseParameter, this.Index, pStudioHdrClass, sName);
        */ 
        return ZP_LookupPoseParameter(this.Index, sName);
    } 

    public void StudioFrameAdvance()
    {
        SDKCall(hSDKCallStudioFrameAdvance, this.Index); 
    }
    
    public void GetAttachment(char[] sName, float vPosition[3], float vAngle[3])    
    { 
      /*if(Platform == OS_Windows)
        {
            SDKCall(hSDKCallGetAttachment, this.Index, sName, vPosition, vAngle); 
        }
        else
        {
            int iAttach = SDKCall(hSDKCallLookupAttachment, this.Index, sName);
            if(iAttach)
            {
                SDKCall(hSDKCallGetAttachment, this.Index, iAttach, vPosition, vAngle); 
            }
        }*/
        ZP_GetAttachment(this.Index, sName, vPosition, vAngle);
    } 

    public int LookupSequence(char[] sAnim) 
    {
        /*if(Platform == OS_Windows)
        {
            return SDKCall(hSDKCallLookupSequence, this.Index, sAnim); 
        }
        else
        {
            // Validate address
            Address pStudioHdrClass = this.GetStudioHdr(); 
            if(pStudioHdrClass == Address_Null) 
            {
                return -1; 
            }
            
            return SDKCall(hSDKCallLookupSequence, pStudioHdrClass, sAnim); 
        }*/
        return ZP_LookupSequence(this.Index, sAnim);
    }
    
    public int AnimOverlayCount()
    {
        static int iOffset;
        if(!iOffset) iOffset = FindDataMapInfo(this.Index, "m_AnimOverlay") + AnimatingOverlay_Count;
        return GetEntData(this.Index, iOffset);
    }
    
    /*__________________________________________________________________________________________________*/
    
    // @info https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.cpp#L811
    public int FindGestureLayer(char[] sAnim) 
    {
        // Find the sequence index
        int iSequence = this.LookupSequence(sAnim); 
        if(iSequence < 0) 
        {
            return -1; 
        }

        // Validate address
        CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
        if(pOverlay.isNull) 
        {
            return -1; 
        }
        
        // i = layer index
        int iCount = this.AnimOverlayCount();
        for(int i = 0; i < iCount; i++) 
        {
            // Validate layer
            if(!pOverlay.IsAlive(i)) 
            {
                continue; 
            }

            // Validate sequence
            if(pOverlay.GetLayerSequence(i) == iSequence) 
            {
                return i; 
            }
        } 
        
        // Return on the unsuccess
        return -1; 
    }

    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.cpp#L527
    public int AddGesture(char[] sAnim, bool bAutoKill = true) 
    { 
        // Find the sequence index
        int iSequence = this.LookupSequence(sAnim); 
        if(iSequence < 0) 
        {
            return -1; 
        }

        // Validate address
        CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
        if(pOverlay.isNull) 
        {
            return -1; 
        }
        
        // Create a new layer
        int iLayer = SDKCall(hSDKCallAddLayeredSequence, this.Index, iSequence, 0); 
        if(iLayer >= 0 && iLayer < this.AnimOverlayCount() && pOverlay.IsActive(iLayer))
        {
            // Set the main properties
            pOverlay.SetLayerAutokill(iLayer, bAutoKill);
        }
        
        // Return on the success
        return iLayer;
    } 

    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.cpp#L836
    public bool IsPlayingGesture(char[] sAnim)    
    { 
        return this.FindGestureLayer(sAnim) != -1 ? true : false; 
    } 

    // @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.cpp#L866
    public void RemoveGesture(char[] sAnim) 
    { 
        // Validate layer
        int iLayer = this.FindGestureLayer(sAnim); 
        if(iLayer == -1) 
        {
            return; 
        }

        // Validate address
        CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
        if(pOverlay.isNull) 
        {
            return;
        }
        
        // Delete it !
        pOverlay.RemoveLayer(iLayer, 0.0, 0.0)
    }

    /*__________________________________________________________________________________________________*/

    public bool ValidTargetPlayer(int targetIndex, float vStart[3], float vEnd[3]) 
    {
        // Create the end-point trace
        TR_TraceRayFilter(vStart, vEnd, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, filter3, this.Index); 
        
        // Validate any kind of collision along the trace ray
        bool bHit;
        if(!TR_DidHit() || TR_GetEntityIndex() == targetIndex) 
        { 
            bHit = true; 
        }

        // Return on success
        return bHit;
    } 
     
    public void SelectTargetPoint(float vStart[3], float vMid[3]) 
    {
        // Track the enemy 
        GetCenterOrigin(this.Enemy, vMid); 
     
        // If we cannot see their GetCenterOrigin ( possible, as we do our target finding based 
        // on the eye position of the target) then fire at the eye position 
        TR_TraceRayFilter(vStart, vMid, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, filter3, this.Index); 
        
        // Validate collision
        if(TR_DidHit()) 
        {
            // Validate victim
            int victimIndex = TR_GetEntityIndex();
            if(victimIndex >= MaxClients || victimIndex <= 0)
            {
                // Hack it lower a little bit
                // The eye position is not always within the hitboxes for a standing CS player 
                GetEyePosition(this.Enemy, vMid); 
                vMid[2] -= 5.0; 
            }
        }
    } 
    
    public void EmitSound(int iIndex)
    {
        // Play sound
        ZP_EmitSoundToAll(gSound, iIndex, this.Index, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }
    
    public void FoundTarget(int targetIndex) 
    {     
        // Sets the target index
        this.Enemy = targetIndex; 
        
        // Validate ammunition
        if(this.Ammo > 0 || (this.Rockets > 0 && this.UpgradeLevel == SENTRY_MODE_ROCKET))
        {
            this.EmitSound(GetRandomInt(SENTRY_SOUND_SPOT, SENTRY_SOUND_SPOT2));
        }
        
        // Create a small delay
        float flDelay = SENTRY_BULLET_THINK;
        this.State = SENTRY_STATE_ATTACKING; 
        this.NextAttack = GetGameTime() + flDelay; 
        if(this.NextRocket < GetGameTime()) 
        { 
            this.NextRocket = GetGameTime() + flDelay * 10.0; 
        } 
    }

    public bool FindTarget() 
    { 
        // Initialize vectors
        static float vPosition[3]; static float vMidEnemy[3]; 
    
        // Loop through players within 1100 units (sentry range)
        this.GetGunPosition(vPosition); 

        // If we have an enemy get his minimum distance to check against
        int targetIndex = INVALID_ENT_REFERENCE; int targetOldIndex = this.Enemy; 
        float flMinDist = SENTRY_BULLET_RANGE; float flOldTargetDist = 2147483647.0; float flDist;

        // i = client index
        for(int i = 1; i <= MaxClients; i++) 
        {
            // Validate client
            if(!IsPlayerExist(i))
            {
                continue;
            }
    
            // Validate zombie
            if(!ZP_IsPlayerZombie(i))
            {
                continue;
            }
            
            // Gets victim origin
            GetAbsOrigin(i, vMidEnemy);
            
            // Gets target distance
            flDist = GetVectorDistance(vPosition, vMidEnemy);
            
            // Store the current target distance if we come across it 
            if(i == targetOldIndex) 
            { 
                flOldTargetDist = flDist; 
            } 
            
            // Check to see if the target is closer than the already validated target
            if(flDist > flMinDist) 
            {
                continue; 
            }
            
            // It is closer, check to see if the target is valid
            if(this.ValidTargetPlayer(i, vPosition, vMidEnemy)) 
            { 
                flMinDist = flDist; 
                targetIndex = i; 
            }
        }

        #if defined SENTRY_ATTACK_NPC
        // Initialize name char
        static char sClassname[SMALL_LINE_LENGTH];
        
        // If we already have a target, don't check objects
        if(targetIndex == INVALID_ENT_REFERENCE) 
        {
            // i = entity index
            int MaxEntities = GetMaxEntities();
            for(int i = MaxClients; i <= MaxEntities; i++)
            {
                // Validate entity
                if(IsValidEdict(i))
                {
                    // Gets valid edict classname
                    GetEdictClassname(i, sClassname, sizeof(sClassname));

                    // If entity is a chicken
                    if(sClassname[0] == 'c' && sClassname[1] == 'h')
                    {
                    }
                    // If entity is a monster generic
                    else if(sClassname[0] == 'm' && sClassname[8] == 'g')
                    {
                        // Skip turrets
                        if(IsEntityTurret(i))
                        {
                            continue;
                        }
                    }
                    // Otherwise skip
                    else continue;
                
                    // Gets victim origin
                    GetAbsOrigin(i, vMidEnemy);
                    
                    // Gets target distance
                    flDist = GetVectorDistance(vPosition, vMidEnemy);
                    
                    // Store the current target distance if we come across it 
                    if(i == targetOldIndex) 
                    { 
                        flOldTargetDist = flDist; 
                    } 
                    
                    // Check to see if the target is closer than the already validated target
                    if(flDist > flMinDist) 
                    {
                        continue; 
                    }
                    
                    // It is closer, check to see if the target is valid
                    if(this.ValidTargetPlayer(i, vPosition, vMidEnemy)) 
                    { 
                        flMinDist = flDist; 
                        targetIndex = i; 
                    }
                }
            }
        }
        #endif
        
        // We have a target
        if(targetIndex != INVALID_ENT_REFERENCE) 
        { 
            // Is it new target ?
            if(targetIndex != targetOldIndex) 
            { 
                // flMinDist is the new target's distance 
                // flOldTargetDist is the old target's distance 
                // Don't switch unless the new target is closer by some percentage 
                if(flMinDist < (flOldTargetDist * 0.75)) 
                { 
                    this.FoundTarget(targetIndex); 
                } 
            }
            
            // Target was found
            return true; 
        } 
        
        // Target was missed
        return false; 
    }

    public bool MoveTurret() 
    { 
        // Initialize variables
        bool bMoved = false; 
        float flDelay = SENTRY_BULLET_THINK;
        float flTurnRate = SENTRY_BULLET_TURN; 
        
        // Start it rotating
        static float vGoalAngle[3]; static float vCurAngle[3];
        this.GetGoalAngles(vGoalAngle); 
        this.GetCurAngles(vCurAngle);
        
        // Any x movement? 
        if(vCurAngle[0] != vGoalAngle[0]) 
        { 
            float flDir = vGoalAngle[0] > vCurAngle[0] ? 1.0 : -1.0 ; 
            vCurAngle[0] += flDelay * (flTurnRate * 5) * flDir; 
     
            // if we started below the goal, and now we're past, peg to goal 
            if(flDir == 1) 
            { 
                if(vCurAngle[0] > vGoalAngle[0]) 
                    vCurAngle[0] = vGoalAngle[0]; 
            }  
            else 
            { 
                if(vCurAngle[0] < vGoalAngle[0]) 
                    vCurAngle[0] = vGoalAngle[0]; 
            } 
     
            this.SetPoseParameter(this.LookupPoseParameter("aim_pitch"), -50.0, 50.0, -vCurAngle[0]); 
            bMoved = true; 
        } 
         
        // Any y movement?  
        if(vCurAngle[1] != vGoalAngle[1]) 
        { 
            float flDir = vGoalAngle[1] > vCurAngle[1] ? 1.0 : -1.0 ; 
            float flDist = FloatAbs(vGoalAngle[1] - vCurAngle[1]); 
            bool bReversed = false; 
     
            if(flDist > 180.0) 
            { 
                flDist = 360.0 - flDist; 
                flDir = -flDir; 
                bReversed = true; 
            } 
     
            // Target not exist
            if(this.Enemy == INVALID_ENT_REFERENCE) 
            { 
                if(flDist > 30.0) 
                { 
                    if(this.TurnRate < flTurnRate * 10.0) 
                        this.TurnRate += flTurnRate; 
                } 
                else 
                { 
                    // Slow down 
                    if(this.TurnRate > (flTurnRate * 5.0)) 
                        this.TurnRate -= flTurnRate; 
                } 
            } 
            else 
            { 
                // When tracking enemies, move faster and don't slow 
                if(flDist > 30.0) 
                { 
                    if(this.TurnRate < flTurnRate * 30.0) 
                        this.TurnRate += flTurnRate * 3.0; 
                } 
            } 
     
            vCurAngle[1] += flDelay * this.TurnRate * flDir; 
     
            // if we passed over the goal, peg right to it now 
            if(flDir == -1) 
            { 
                if((bReversed == false && vGoalAngle[1] > vCurAngle[1]) || 
                    (bReversed == true  && vGoalAngle[1] < vCurAngle[1])) 
                { 
                    vCurAngle[1] = vGoalAngle[1]; 
                } 
            }  
            else 
            { 
                if((bReversed == false && vGoalAngle[1] < vCurAngle[1]) || 
                    (bReversed == true  && vGoalAngle[1] > vCurAngle[1])) 
                { 
                    vCurAngle[1] = vGoalAngle[1]; 
                } 
            } 
     
            if(vCurAngle[1] < 0.0) 
            { 
                vCurAngle[1] += 360.0; 
            } 
            else if(vCurAngle[1] >= 360.0) 
            { 
                vCurAngle[1] -= 360.0; 
            } 
     
            if(flDist < (flDelay * 0.5 * flTurnRate)) 
            { 
                vCurAngle[1] = vGoalAngle[1]; 
            } 
     
            // Gets the angles
            static float vAngle[3]; 
            this.GetAbsAngles(vAngle); 
            
            float flYaw = AngleNormalize(vCurAngle[1] - vAngle[1]); 
            this.SetPoseParameter(this.LookupPoseParameter("aim_yaw"), -180.0, 180.0, -flYaw); 
            this.SetCurAngles(vCurAngle);
            bMoved = true; 
        } 
     
        if(!bMoved || this.TurnRate <= 0.0) 
        { 
            this.TurnRate = flTurnRate * 5.0; 
        } 
     
        return bMoved; 
    } 
    
    public void RocketCreate(float vPosition[3], float vAngle[3], float vVelocity[3])
    {
        // Initialize buffer char
        static char sBuffer[SMALL_LINE_LENGTH];
    
        // Create a rocket entity
        int entityIndex = UTIL_CreateProjectile(vPosition, vAngle, "models/weapons/cso/bazooka/w_bazooka_projectile.mdl");

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Push the rocket
            TeleportEntity(entityIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);

            // Sets an entity color
            SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
            SetEntityRenderColor(entityIndex, _, _, _, 0);
            AcceptEntityInput(entityIndex, "DisableShadow"); /// Prevents the entity from receiving shadows
            
            // Create a prop_dynamic_override entity
            int rocketIndex = UTIL_CreateDynamic("rocket", NULL_VECTOR, NULL_VECTOR, "models/buildables/sentry3_rockets.mdl", "idle", false);

            // Validate entity
            if(rocketIndex != INVALID_ENT_REFERENCE)
            {
                // Sets parent to the entity
                SetVariantString("!activator");
                AcceptEntityInput(rocketIndex, "SetParent", entityIndex, rocketIndex);
                
                // Sets attachment to the projectile
                SetVariantString("1"); 
                AcceptEntityInput(rocketIndex, "SetParentAttachment", entityIndex, rocketIndex);
            
                // Create effects
                for(int i = 1; i <= 4; i++)
                {
                    FormatEx(sBuffer, sizeof(sBuffer), "rocket%d", i);
                    UTIL_CreateParticle(rocketIndex, _, _, sBuffer, "sentry_rocket", SENTRY_ROCKET_EFFECT_TIME);
                }
            }
            
            // Sets parent for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", this.Index); 

            // Sets gravity
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", SENTRY_ROCKET_GRAVITY);
            
            // Sets weapon ID
            SetEntProp(entityIndex, Prop_Data, "m_iHammerID", gWeapon);

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, RocketTouchHook);
        }
        
        // Make an effect
        this.Body = 1;
                
        // Initialize flags char
        FormatEx(sBuffer, sizeof(sBuffer), "OnUser2 !self:SetBodyGroup:0:%f:1", SENTRY_ROCKET_RELOAD);
        
        // Sets modified flags on the entity
        SetVariantString(sBuffer);
        AcceptEntityInput(entityIndex, "AddOutput");
        AcceptEntityInput(entityIndex, "FireUser2"); /// Reset body
    }
    
    public void BulletCreate(float vPosition[3], float vAngle[3], float flDistance, char[] sAttach) 
    { 
        // Initialize vectors
        static float vEndPosition[3]; static float vVelocity[3]; 
        
        // Calculate a bullet path
        vEndPosition[0] = vPosition[0] + vAngle[0] * flDistance;  
        vEndPosition[1] = vPosition[1] + vAngle[1] * flDistance; 
        vEndPosition[2] = vPosition[2] + vAngle[2] * flDistance; 
         
        // Fire a bullet 
        TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, filter3, this.Index); 

        // Validate collisions
        if(TR_DidHit()) 
        {
            // Returns the collision position of a trace result
            TR_GetEndPosition(vEndPosition); 
        
            // Sentryguns are perfectly accurate, but this doesn't look good for tracers
            // Add a little noise to them, but not enough so that it looks like they're missing
            vEndPosition[0] += GetRandomFloat(-10.0, 10.0); 
            vEndPosition[1] += GetRandomFloat(-10.0, 10.0); 
            vEndPosition[2] += GetRandomFloat(-10.0, 10.0); 

            // Bullet tracer
            UTIL_CreateTracer(this.Index, sAttach, "weapon_tracers_50cal", vEndPosition, 0.1);

            // Gets victim index
            int victimIndex = TR_GetEntityIndex();
            
            // Is hit world ?
            if(victimIndex < 1)
            {
                // Returns the collision angle
                TR_GetPlaneNormal(null, vVelocity); 
                GetVectorAngles(vVelocity, vVelocity); 
        
                // Can't get surface properties from traces unfortunately
                // Just another short sighting from the SM devs :/// 
                UTIL_CreateParticle(this.Index, vEndPosition, _, _, "impact_dirt", 0.1);
                
                // Move the impact effect a bit out so it doesn't clip the wall
                float flPercentage = 0.2 / (GetVectorDistance(vPosition, vEndPosition) / 100);
                vEndPosition[0] = vEndPosition[0] + ((vPosition[0] - vEndPosition[0]) * flPercentage);
                vEndPosition[1] = vEndPosition[1] + ((vPosition[1] - vEndPosition[1]) * flPercentage);
                vEndPosition[2] = vEndPosition[2] + ((vPosition[2] - vEndPosition[2]) * flPercentage);

                // Create an another impact effect
                TE_Start("Impact"); 
                TE_WriteVector("m_vecOrigin", vEndPosition); 
                TE_WriteVector("m_vecNormal", vVelocity); 
                TE_WriteNum("m_iType", GetRandomInt(1, 10)); 
                TE_SendToAll();
            }
            else
            {
                // Create the damage for victims
                UTIL_CreateDamage(_, vEndPosition, this.Index, SENTRY_BULLET_DAMAGE, SENTRY_BULLET_RADIUS, DMG_BULLET);
        
                // Validate victim
                if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
                {    
                    // Create a blood effect
                    UTIL_CreateParticle(victimIndex, vEndPosition, _, _, "blood_impact_heavy", 0.1);
                
                    // Validate knockback
                    float flKnockBack = ZP_GetClassKnockBack(ZP_GetClientClass(victimIndex)) * ZP_GetWeaponKnockBack(gWeapon) * SENTRY_BULLET_DAMAGE; 
                    if(flKnockBack > 0.0)
                    {
                        // Gets vector from the given starting and ending points
                        MakeVectorFromPoints(vPosition, vEndPosition, vVelocity);

                        // Normalize the vector (equal magnitude at varying distances)
                        NormalizeVector(vVelocity, vVelocity);

                        // Apply the magnitude by scaling the vector
                        ScaleVector(vVelocity, flKnockBack);
                        
                        // Gets client velocity
                        static float vSpeed[3];
                        GetEntPropVector(victimIndex, Prop_Data, "m_vecVelocity", vSpeed);
                        
                        // Add to the current
                        AddVectors(vSpeed, vVelocity, vVelocity);
                    
                        // Push the target
                        TeleportEntity(victimIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);
                    }
                }
            }
        }
    }

    public void Fire() 
    { 
        // Initialize variables
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vMidEnemy[3];
        float flSpeed = SENTRY_BULLET_SPEED; 
        float flCurrentTime = GetGameTime();
        
        // Level 3 Turrets fire rockets every 3 seconds
        if(this.UpgradeLevel == SENTRY_MODE_ROCKET && this.NextRocket < flCurrentTime)
        {
            if(this.Rockets > 0) 
            { 
                if(!this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
                {
                    this.AddGesture("ACT_RANGE_ATTACK2");
                }
        
                // Alternate between the 1 rocket launcher ports
                ///this.GetAttachment("rocket", vPosition, vVelocity);  // Not work correctly
                this.GetLauncherPosition(vPosition); 

                // Calculate a velocity
                GetCenterOrigin(this.Enemy, vMidEnemy); 
                MakeVectorFromPoints(vPosition, vMidEnemy, vAngle);
                NormalizeVector(vAngle, vAngle); 
                GetVectorAngles(vAngle, vAngle); 
                GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
                NormalizeVector(vVelocity, vVelocity);
                ScaleVector(vVelocity, SENTRY_ROCKET_SPEED);

                // Create a rocket
                this.EmitSound(SENTRY_MODE_ROCKET); 
                this.RocketCreate(vPosition, vAngle, vVelocity); 

                // Sets the delay for the next rocket
                this.NextRocket = flCurrentTime + SENTRY_ROCKET_DELAY;
                this.Rockets--;
            }
            else
            {
                // Kill layers
                if(this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
                { 
                    this.RemoveGesture("ACT_RANGE_ATTACK2"); 
                }
                
                // Out of rockets
                this.NextRocket = flCurrentTime + 9999.9;
            }
        }
        
        // All turrets fire shells 
        if(this.Ammo > 0) 
        { 
            if(!this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
            { 
                this.RemoveGesture("ACT_RANGE_ATTACK1_LOW"); 
                this.AddGesture("ACT_RANGE_ATTACK1"); 
            }

            switch(this.UpgradeLevel) 
            { 
                case SENTRY_MODE_NORMAL    : this.EmitSound(GetRandomInt(0, 1) ? SENTRY_SOUND_SHOOT : SENTRY_SOUND_SHOOT4); 
                case SENTRY_MODE_AGRESSIVE : this.EmitSound(SENTRY_SOUND_SHOOT2); 
                case SENTRY_MODE_ROCKET    : this.EmitSound(SENTRY_SOUND_SHOOT3); 
            }
            
            // Alternate between the 3 shot ports
            static char sAttach[SMALL_LINE_LENGTH];
            strcopy(sAttach, sizeof(sAttach), (this.UpgradeLevel == SENTRY_MODE_NORMAL) ? "muzzle" : ((this.Ammo & 1) ? "muzzle_l" : "muzzle_r"));
            this.GetAttachment(sAttach, vPosition, vVelocity); 

            // Track the enemy
            this.SelectTargetPoint(vPosition, vMidEnemy);
            MakeVectorFromPoints(vPosition, vMidEnemy, vAngle);
            float flDistToTarget = GetVectorLength(vAngle); 
            NormalizeVector(vAngle, vAngle); 
             
            // Create a bullet
            static char sMuzzle[NORMAL_LINE_LENGTH];
            this.BulletCreate(vPosition, vAngle, flDistToTarget * 500, sAttach); 
            ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
            UTIL_CreateParticle(this.Index, _, _, sAttach, sMuzzle, flSpeed);

            // Sets the delay for the next attack
            if(this.UpgradeLevel > SENTRY_MODE_NORMAL) flSpeed *= 0.5;
            this.NextAttack = flCurrentTime + flSpeed;
            this.Ammo--; 
        } 
        else 
        {
            // Kill layers
            if(this.UpgradeLevel > SENTRY_MODE_NORMAL) 
            { 
                if(!this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
                { 
                    this.RemoveGesture("ACT_RANGE_ATTACK1"); 
                    this.AddGesture("ACT_RANGE_ATTACK1_LOW");
                    this.EmitSound(SENTRY_SOUND_FINISH);
                } 
            } 

            // Out of ammo, play a click 
            this.EmitSound(SENTRY_SOUND_EMPTY);
            this.NextAttack = flCurrentTime + 0.2; 
       }
    } 
    
    public void SentryRotate() 
    { 
        // If we're playing a fire gesture, stop it 
        if(this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
        { 
            this.RemoveGesture("ACT_RANGE_ATTACK1"); 
        } 
        if(this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
        { 
            this.RemoveGesture("ACT_RANGE_ATTACK1_LOW"); 
        }
        if(this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
        { 
            this.RemoveGesture("ACT_RANGE_ATTACK2"); 
        }
     
        // Look for a target 
        if(this.FindTarget()) 
        { 
            return; 
        } 
     
        // Rotate a bit
        if(!this.MoveTurret()) 
        {
            /*switch(this.UpgradeLevel) 
            { 
                case SENTRY_MODE_NORMAL    : this.EmitSound(SENTRY_SOUND_SCAN); 
                case SENTRY_MODE_AGRESSIVE : this.EmitSound(SENTRY_SOUND_SCAN2); 
                case SENTRY_MODE_ROCKET    : this.EmitSound(SENTRY_SOUND_SCAN3); 
            }*/
     
            // Start it rotating
            static float vGoalAngle[3]; 
            this.GetGoalAngles(vGoalAngle);
     
            // Switch rotation direction 
            if(this.TurningRight) 
            { 
                this.TurningRight = false; 
                vGoalAngle[1] = float(this.LeftBound); 
            } 
            else 
            { 
                this.TurningRight = true; 
                vGoalAngle[1] = float(this.RightBound); 
            } 

            // Randomly look up and down a bit 
            if(GetRandomFloat(0.0, 1.0) < 0.3) 
            { 
                vGoalAngle[0] = float(RoundToNearest(GetRandomFloat(-10.0, 10.0))); 
            }
            
            // Store angles
            this.SetGoalAngles(vGoalAngle);
        }
    } 

    public void Attack() 
    {
        // Validate target
        if(!this.FindTarget()) 
        {
            this.State = SENTRY_STATE_SEARCHING;
            return; 
        } 
     
        // Initialize vectors
        static float vMid[3]; static float vMidEnemy[3]; static float vDirToEnemy[3]; static float vAngle[3]; 
     
        // Track the enemy 
        GetCenterOrigin(this.Index, vMid); 
        this.SelectTargetPoint(vMid, vMidEnemy);
        MakeVectorFromPoints(vMid, vMidEnemy, vDirToEnemy);
        GetVectorAngles(vDirToEnemy, vAngle); 
     
        // Calculate angles
        vAngle[1] = AngleMod(vAngle[1]); 
        if(vAngle[0] < -180.0) 
            vAngle[0] += 360; 
        if(vAngle[0] > 180.0) 
            vAngle[0] -= 360; 
     
        // now all numbers should be in [1...360] 
        // pin to turret limitations to [-50...50] 
        if(vAngle[0] > 50.0) 
            vAngle[0] = 50.0; 
        else if(vAngle[0] < -50.0) 
            vAngle[0] = -50.0; 

        // Start it rotating
        static float vGoalAngle[3]; static float vCurAngle[3]; static float vSegment[3]; 
        this.GetGoalAngles(vGoalAngle); 
        this.GetCurAngles(vCurAngle);
        vGoalAngle[1] = vAngle[1]; 
        vGoalAngle[0] = vAngle[0]; 
        this.SetGoalAngles(vGoalAngle);     
        this.MoveTurret(); 
        
        // Gets vector from the given starting and ending angles
        MakeVectorFromPoints(vCurAngle, vGoalAngle, vSegment);
         
        // Fire on the target if it's within 10 units of being aimed right at it 
        if(this.NextAttack <= GetGameTime() && GetVectorLength(vSegment) <= 10.0) 
        { 
            this.Fire(); 
        } 
         
        // Validate range
        if(GetVectorLength(vSegment) > 10.0) 
        { 
            // If we're playing a fire gesture, stop it 
            if(this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
            { 
                this.RemoveGesture("ACT_RANGE_ATTACK1"); 
            } 
        }
    }
    
    public void Death()
    {
        // Initialize vectors
        static float vPosition[3]; static float vGibAngle[3]; float vShootAngle[3];

        // Emit sound
        EmitSoundToAll("survival/turret_death_01.wav", this.Index, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
        // Gets entity position
        GetAbsOrigin(this.Index, vPosition);
        
        // Create an explosion effect
        UTIL_CreateParticle(this.Index, vPosition, _, _, "explosion_hegrenade_interior", 0.1);
        
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
            UTIL_CreateShooter(this.Index, "build_point_0", _, MAT_METAL, sBuffer, vShootAngle, vGibAngle, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
        }

        // Kill after some duration
        UTIL_RemoveEntity(this.Index, 0.1);
    }
} 

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

void Weapon_OnIdle(int clientIndex, int weaponIndex, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime
    
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

void Weapon_OnDeploy(int clientIndex, int weaponIndex, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, flCurrentTime
    
    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
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
    flCurrentTime += ZP_GetWeaponReload(gWeapon);

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);   
    
    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];
    
    // Gets trace line
    GetClientEyePosition(clientIndex, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, 100.0, 0.0, 0.0, vEndPosition);

    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, filter2);

    // Is hit world ?
    if(TR_DidHit() && TR_GetEntityIndex() < 1)
    {
        // Returns the collision position/angle of a trace result
        TR_GetEndPosition(vPosition);
        TR_GetPlaneNormal(null, vAngle); 
        
        // Initialize the hull intersection
        static const float vMins[3] = { -13.0, -13.0, 0.0   }; 
        static const float vMaxs[3] = {  13.0,  13.0, 72.0  }; 
        
        // Create the hull trace
        vPosition[2] += vMaxs[2] / 2; /// Move center of hull upward
        TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
        
        // Validate no collisions
        if(!TR_DidHit())
        {
            // Sets shoot animation
            ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT);

            // Create timer for turret
            delete Task_TurretCreate[clientIndex]; /// Bugfix
            Task_TurretCreate[clientIndex] = CreateTimer(ZP_GetWeaponReload(gWeapon) - 0.1, Weapon_OnCreateTurret, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

/**
 * Timer for creating turret.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateTurret(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_TurretCreate[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
        // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; 
        
        // Gets trace line
        GetClientEyePosition(clientIndex, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 100.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, filter2);

        // Is hit world ?
        if(TR_DidHit() && TR_GetEntityIndex() < 1)
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vPosition);
            TR_GetPlaneNormal(null, vAngle); 
            
            // Initialize the hull intersection
            static const float vMins[3] = { -13.0, -13.0, 0.0   }; 
            static const float vMaxs[3] = {  13.0,  13.0, 72.0  }; 
            
            // Create the hull trace
            vPosition[2] += vMaxs[2] / 2; /// Move center of hull upward
            TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
            
            // Validate no collisions
            if(!TR_DidHit())
            {
                // Create a dronegun entity
                SentryGun(clientIndex, vPosition, vAngle, GetEntProp(weaponIndex, Prop_Data, "m_iHealth"), GetEntProp(weaponIndex, Prop_Data, "m_iAltFireHudHintCount"), GetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount"), GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"));
                
                // Forces a player to remove weapon
                ZP_RemoveWeapon(clientIndex, weaponIndex);
                
                // Destroy timer
                return Plugin_Stop;
            }
        }

        // Adds the delay to the game tick
        float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon);
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

        // Sets pickup animation
        ZP_SetWeaponAnimation(clientIndex, ANIM_DRAW);
    }
    
    // Destroy timer
    return Plugin_Stop;
}

bool Weapon_OnPickupTurret(int clientIndex, int entityIndex, float flCurrentTime)
{
    #pragma unused clientIndex, entityIndex, flCurrentTime

    // Initialize vectors
    static float vPosition[3]; static float vEndPosition[3]; bool bSuccess;
    
    // Gets trace line
    GetClientEyePosition(clientIndex, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

    // Create the end-point trace
    TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, filter2);

    // Validate collisions
    if(!TR_DidHit())
    {
        // Initialize the hull intersection
        static const float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static const float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SOLID, filter2);
    }
    
    // Validate collisions
    if(TR_DidHit())
    {
        // Gets entity index
        entityIndex = TR_GetEntityIndex();

        // Validate entity
        if(IsEntityTurret(entityIndex))
        {
            // Validate owner
            if(GetEntPropEnt(entityIndex, Prop_Data, "m_pParent") == clientIndex)
            {
                // Give item and select it
                int weaponIndex = ZP_GiveClientWeapon(clientIndex, gWeapon);
                
                // Valdiate weapon
                if(weaponIndex != INVALID_ENT_REFERENCE)
                {
                    // Set variables
                    SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", GetEntProp(entityIndex, Prop_Data, "m_iDesiredWeaponState"));
                    SetEntProp(weaponIndex, Prop_Data, "m_iHealth", GetEntProp(entityIndex, Prop_Data, "m_iHealth"));
                    SetEntProp(weaponIndex, Prop_Data, "m_iAltFireHudHintCount", GetEntProp(entityIndex, Prop_Data, "m_iAmmo"));
                    SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", GetEntProp(entityIndex, Prop_Data, "m_iMySquadSlot"));
                }

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
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", GetRandomInt(SENTRY_MODE_NORMAL, SENTRY_MODE_ROCKET));
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth", ZP_GetWeaponClip(gWeapon));
        SetEntProp(weaponIndex, Prop_Data, "m_iAltFireHudHintCount", ZP_GetWeaponAmmo(gWeapon));
        SetEntProp(weaponIndex, Prop_Data, "m_iReloadHudHintCount", ZP_GetWeaponAmmunition(gWeapon));
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
        // Delete timers
        delete Task_TurretCreate[clientIndex];
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
        
        // Call event
        _call.Idle(clientIndex, weaponIndex);
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
        if(_call.PickupTurret(clientIndex, weaponIndex))
        {
            // Block showing menu
            return Plugin_Handled;
        }
    }
    
    // Allow menu
    return Plugin_Continue;
}

/**
 * @brief Called when a client take a fake damage.
 * 
 * @param clientIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param bits              The ditfield of damage types.
 * @param weaponIndex       The weapon index or -1 for unspecified.
 **/
public void ZP_OnClientDamaged(int clientIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits, int &weaponIndex)
{
    // Client was damaged by 'rocket'
    if(iBits & DMG_BLAST)
    {
        // Validate rocket
        if(IsEntityRocket(attackerIndex))
        {
            // Validate victim
            if(ZP_IsPlayerHuman(clientIndex))
            {
                flDamage = 0.0;
            }
        }
        
    }
    // Client was damaged by 'bullet'
    else if(iBits & DMG_BULLET)
    {
        // Validate turret
        if(IsEntityTurret(attackerIndex))
        {
            // Validate victim
            if(ZP_IsPlayerHuman(clientIndex))
            {
                flDamage = 0.0;
            }
        }
    }
}

//**********************************************
//* Item (drone) hooks.                        *
//**********************************************

/**
 * @brief Sentry think hook.
 *
 * @param entityIndex       The entity index.
 * @param clientIndex       The client index.
 **/
public void SentryThinkHook(int entityIndex, int clientIndex) 
{
    // This bad code ensures that we don't think any more than we should 
    static int thinkIndex = 1; 
    if(!IsClientInGame(thinkIndex)) 
    { 
        thinkIndex = clientIndex; 
    } 
    if(thinkIndex != clientIndex) 
    { 
        return; 
    }
    
    // Gets the object methods
    SentryGun sentry = view_as<SentryGun>(entityIndex); 
    
    // Animate entity
    sentry.StudioFrameAdvance();
    
    // Sets the state
    switch(sentry.State) 
    { 
        case SENTRY_STATE_SEARCHING : sentry.SentryRotate(); 
        case SENTRY_STATE_ATTACKING : sentry.Attack(); 
    }
}

/**
 * @brief Sentry damage hook.
 * 
 * @param entityIndex       The entity index.
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action SentryDamageHook(int entityIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &damageBits)
{
    // Validate attacker
    if(IsPlayerExist(attackerIndex))
    {
        // Validate zombie
        if(ZP_IsPlayerZombie(attackerIndex))
        {
            // Gets the object methods
            SentryGun sentry = view_as<SentryGun>(entityIndex); 
    
            // Calculate the damage
            int iHealth = sentry.Health - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

            // Destroy entity
            if(!iHealth)
            {
                // Destroy damage hook
                SDKUnhook(entityIndex, SDKHook_OnTakeDamage, SentryDamageHook);
        
                // Call removal
                sentry.Death();
            }
            else
            {
                // Apply damage
                sentry.Health = iHealth; 
                
                // Emit sound
                switch(GetRandomInt(0, 2))
                {
                    case 0 : EmitSoundToAll("survival/turret_takesdamage_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                    case 1 : EmitSoundToAll("survival/turret_takesdamage_02.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                    case 2 : EmitSoundToAll("survival/turret_takesdamage_03.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                }
            }
        }
    }
    
    // Return on success
    return Plugin_Handled;
}

/**
 * @brief Rocket touch hook.
 * 
 * @param entityIndex       The entity index.        
 * @param targetIndex       The target index.               
 **/
public Action RocketTouchHook(int entityIndex, int targetIndex)
{
    // Validate target
    if(!IsEntityTurret(targetIndex))
    {
        // Gets entity position
        static float vPosition[3];
        GetAbsOrigin(entityIndex, vPosition);
        
        // Create an explosion effect
        UTIL_CreateParticle(_, vPosition, _, _, "expl_coopmission_skyboom", SENTRY_ROCKET_EXPLOSION_TIME);
        
        // Create an explosion
        UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, SENTRY_ROCKET_DAMAGE, SENTRY_ROCKET_RADIUS, "rocket", entityIndex, entityIndex);

        // Play sound
        ZP_EmitSoundToAll(gSound, SENTRY_SOUND_EXPLOAD, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

        // Remove the entity from the world
        AcceptEntityInput(entityIndex, "Kill");
    }

    // Return on the success
    return Plugin_Continue;
}

/**
 * @brief Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @param filterIndex       The filter index.
 * @return                  True or false.
 **/
public bool filter3(int entityIndex, int contentsMask, int filterIndex)
{
    if(IsEntityTurret(entityIndex)) 
    {
        return false;
    }
    
    return (entityIndex != filterIndex); 
}

//**********************************************
//* Item (drone) stocks.                       *
//**********************************************

/**
 * @brief Gets the entity's position.
 * 
 * @param entityIndex       The entity index.     
 * @param vOutput           The vector output.
 **/
stock void GetAbsOrigin(int entityIndex, float vOutput[3]) 
{ 
    GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vOutput); 
} 

/**
 * @brief Gets the entity's center position.
 * 
 * @param entityIndex       The entity index.     
 * @param vVector           The vector output.
 **/
stock void GetCenterOrigin(int entityIndex, float vOutput[3]) 
{ 
    GetAbsOrigin(entityIndex, vOutput); 
    static float vMax[3]; 
    if(entityIndex < MaxClients)
    {
        GetClientMaxs(entityIndex, vMax);
    }
    else
    {
        GetEntPropVector(entityIndex, Prop_Data, "m_vecMaxs", vMax); 
    }
    vOutput[2] += vMax[2] / 2; 
}

/**
 * @brief Gets the entity's eye position.
 * 
 * @param entityIndex       The entity index.     
 * @param vVector           The vector output.
 **/
stock void GetEyePosition(int entityIndex, float vOutput[3]) 
{
    if(entityIndex < MaxClients)
    {
        GetClientEyePosition(entityIndex, vOutput);
    }
    else
    {
        static float vMax[3]; 
        GetAbsOrigin(entityIndex, vOutput);
        GetEntPropVector(entityIndex, Prop_Data, "m_vecMaxs", vMax); 
        vOutput[2] += vMax[2]; 
    }
}

/**
 * @brief Validate a turret.
 *
 * @param entityIndex       The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityTurret(int entityIndex)
{
    // Validate entity
    if(entityIndex <= MaxClients || !IsValidEdict(entityIndex))
    {
        return false;
    }
    
    // Gets name
    static char sClassname[SMALL_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate name
    return (!strcmp(sClassname, "turret", false));
}

/**
 * @brief Validate a rocket.
 *
 * @param entityIndex       The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityRocket(int entityIndex)
{
    // Validate entity
    if(entityIndex <= MaxClients || !IsValidEdict(entityIndex))
    {
        return false;
    }
    
    // Gets name
    static char sClassname[SMALL_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    
    // Validate name
    return (!strcmp(sClassname, "rocket", false));
}

/**
 * @brief Gets the angle mod.
 *
 * @param flAngle           The angle output.  
 * @return                  The angle mod.
 **/
stock float AngleMod(float flAngle) 
{ 
    flAngle = (360.0 / 65536) * (RoundToNearest(flAngle * (65536.0 / 360.0)) & 65535); 
    return flAngle; 
} 

/**
 * @brief Gets the angle normal.
 *
 * @param flAngle           The angle output.  
 * @return                  The angle normal.
 **/
stock float AngleNormalize(float flAngle) 
{ 
    flAngle = flAngle - 360.0 * RoundToFloor(flAngle / 360.0);
    
    if(flAngle > 180)  
    { 
        flAngle -= 360; 
    } 
    if(flAngle < -180) 
    { 
        flAngle += 360; 
    } 
    
    return flAngle; 
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