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
    name            = "[ZP] ExtraItem: DroneGun",
    author          = "qubka (Nikita Ushakov) | Pelipoika",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel 
 
// Item index
int gItem; int gWeapon;
#pragma unused gItem, gWeapon

/**
    for animating: 
        CBaseAnimating::LookupSequence      // Lookup attachment index by name 
        CBaseAnimating::GetAttachment       // Get attachment positon with the index 
         
        CBaseAnimating::StudioFrameAdvance  // Advance animation 
        CBaseAnimating::ResetSequence       // Set animation 
         
        CBaseAnimating::LookupPoseParameter // Get a poseparameter index by name 
        CBaseAnimating::GetPoseParameter    // Get sentry gun rotation and stuff 
        CBaseAnimating::SetPoseParameter    // Set sentry gun rotation and stuff 

    for layered anims: 
        CBaseAnimatingOverlay::AddGestureSequence 

    for firing: 
    to get muzzle attachment position 
        Studio_FindAttachment 
    and 
        CBaseAnimating::GetAttachment 
**/ 

/**
 * @section Variables to store virtual SDK adresses.
 **/
Handle hSDKCallStudioFrameAdvance; 
Handle hSDKCallLookupPoseParameter; 
int Animating_StudioHdr;
/*
    Handle hSDKCallGetAttachment;     
    Handle hSDKCallResetSequence; 
    Handle hSDKCallLookupSequence; 
    Handle hSDKCallLookupActivity; 
    Handle hSDKCallAddLayeredSequence;    
    //static int m_fFlags    = 0x5C; 
    static int m_fFlags    = 0x0;
    static int m_nSequence = 0x8
*/
#define ANIM_LAYER_ACTIVE        0x0001 
#define ANIM_LAYER_AUTOKILL      0x0002 
#define ANIM_LAYER_KILLME        0x0004 
#define ANIM_LAYER_DONTRESTORE   0x0008 
#define ANIM_LAYER_CHECKACCESS   0x0010 
#define ANIM_LAYER_DYING         0x0020 
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

/**
 * @section Sentry modes.
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
 * @brief Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
    // Loads a game config file
    Handle hConfig = LoadGameConfigFile("plugin.turret"); 
    
    /*__________________________________________________________________________________________________*/

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity); 
    PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimating::StudioFrameAdvance"); 
    
    // Validate call
    if((hSDKCallStudioFrameAdvance = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimating::StudioFrameAdvance\". Update signature in \"plugin.turret\"");      

    /*__________________________________________________________________________________________________*/

    // Starts the preparation of an SDK call
    StartPrepSDKCall(SDKCall_Entity); 
    PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimating::LookupPoseParameter"); 
    
    // Adds a parameter to the calling convention. This should be called in normal ascending order
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);  
    PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 
    
    // Validate call
    if((hSDKCallLookupPoseParameter = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimating::LookupPoseParameter\". Update signature in \"plugin.turret\""); 

    /*__________________________________________________________________________________________________*/
    
    // Load other offsets
    if((Animating_StudioHdr = GameConfGetOffset(hConfig, "CBaseAnimating::StudioHdr")) == -1) SetFailState("Failed to get offset: \"CBaseAnimating::StudioHdr\". Update offset in \"plugin.turret\""); 
        
    /// Info bellow
    int lightingOriginOffset;
    if((lightingOriginOffset = FindSendPropInfo("CBaseAnimating", "m_hLightingOrigin")) < 1)  SetFailState("Failed to find prop: \"CBaseAnimating::m_hLightingOrigin\"");
    
    // StudioHdr offset in gameconf is only relative to the offset of m_hLightingOrigin, in order to make the offset more resilient to game updates
    Animating_StudioHdr += lightingOriginOffset;

    // Close file
    delete hConfig;
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
    gSound = ZP_GetSoundKeyID("TURRET_DRONE_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"TURRET_DRONE_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
        // Sounds
    PrecacheSound("sound/survival/turret_death_01.wav", true);
    PrecacheSound("sound/survival/turret_idle_01.wav", true);
    PrecacheSound("sound/survival/turret_takesdamage_01.wav", true);
    PrecacheSound("sound/survival/turret_takesdamage_02.wav", true);
    PrecacheSound("sound/survival/turret_takesdamage_03.wav", true);
    PrecacheSound("sound/survival/turret_lostplayer_01.wav", true);
    PrecacheSound("sound/survival/turret_lostplayer_02.wav", true);
    PrecacheSound("sound/survival/turret_lostplayer_03.wav", true);
    PrecacheSound("sound/survival/turret_sawplayer_01.wav", true);
    PrecacheSound("sound/weapons/lowammo_01.wav", true);
    
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
        if(ZP_IsPlayerHasWeapon(clientIndex, gWeapon))
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

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

methodmap SentryGun /** Regards to Pelipoika **/
{
    // Constructor
    public SentryGun(int ownerIndex, float vPosition[3], float vAngle[3]) 
    { 
        // Create a monster entity
        int entityIndex = CreateEntityByName("monster_generic"); 
        
        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Dispatch main values of the entity
            DispatchKeyValue(entityIndex, "model", "models/props_survival/dronegun/dronegun.mdl"); 
            DispatchKeyValue(entityIndex, "targetname", "turret_gun");
            DispatchKeyValue(entityIndex, "spawnflags", "24706"); /// Gag (No IDLE sounds until angry) | Wait For Script | Don't drop weapons | Ignore player push (New with Half-Life 2: Episode One / Source 2006): Don't give way to player
             
            // Spawn the entity
            DispatchSpawn(entityIndex); 
            
            // Teleport the entity
            TeleportEntity(entityIndex, vPosition, vAngle, NULL_VECTOR);
        
            // Emit sound
            static char sSound[PLATFORM_LINE_LENGTH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 8);
            EmitSoundToAll(sSound, entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
            /**__________________________________________________________**/
            
            // Initialize vectors
            static float vAbsAngle[3]; static float vGoalAngle[3]; static float vCurAngle[3]; 
            
            // Gets the angles
            vAbsAngle = GetAbsAngles(entityIndex); 
            
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

            // Create a physics entity
            int parentIndex = CreateEntityByName("prop_physics_multiplayer"); 
            
            // Validate entity
            if(parentIndex != INVALID_ENT_REFERENCE)
            { 
                // Dispatch main values of the entity
                DispatchKeyValue(parentIndex, "model", "models/props_survival/dronegun/dronegun.mdl");
                DispatchKeyValue(parentIndex, "targetname", "turret_body");
                DispatchKeyValue(parentIndex, "disableshadows", "1"); /// Prevents the entity from receiving shadows
                DispatchKeyValue(parentIndex, "physicsmode", "1"); /// Solid, Server-side, pushes the player away
                DispatchKeyValue(parentIndex, "spawnflags", "8834"); /// Don't take physics damage | Not affected by rotor wash | Prevent pickup | Force server-side

                // Spawn the entity
                DispatchSpawn(parentIndex);
                TeleportEntity(parentIndex, vPosition, vAngle, NULL_VECTOR);
        
                // Sets physics
                AcceptEntityInput(parentIndex, "DisableMotion");
                SetEntityMoveType(parentIndex, MOVETYPE_NONE);
                SetEntProp(parentIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
                SetEntProp(parentIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                
                // Sets the render mode
                SetEntityRenderMode(parentIndex, RENDER_TRANSALPHA); 
                SetEntityRenderColor(parentIndex, 0, 0, 0, 0); 
                
                // Sets health
                SetEntProp(parentIndex, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
                SetEntProp(parentIndex, Prop_Data, "m_iHealth", ZP_GetWeaponClip(gWeapon));
                SetEntProp(parentIndex, Prop_Data, "m_iMaxHealth", ZP_GetWeaponClip(gWeapon));
                
                // Sets parent for the entity
                SetVariantString("!activator");
                AcceptEntityInput(entityIndex, "SetParent", parentIndex, parentIndex);
                SetEntPropEnt(parentIndex, Prop_Data, "m_hOwnerEntity", entityIndex);
                
                 // Create damage hook
                SDKHook(parentIndex, SDKHook_OnTakeDamage, SentryDamageHook);
            }
            
            // Sets owner for the entity
            SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", ownerIndex); 

            // Sets ammunition
            SetEntProp(entityIndex, Prop_Data, "m_iAmmo", ZP_GetWeaponAmmo(gWeapon)); 
            
            // Create think hook
            SDKHook(entityIndex, SDKHook_SetTransmit, SentryThinkHook); 
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

    /*__________________________________________________________________________________________________*/
    
    public Address GetStudioHdr() 
    { 
        return view_as<Address>(GetEntData(this.Index, Animating_StudioHdr)); 
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
        Address studioHdrClass = this.GetStudioHdr(); 
        
        // Validate address
        if(studioHdrClass == Address_Null) 
        {
            return -1; 
        }
        
        return SDKCall(hSDKCallLookupPoseParameter, this.Index, studioHdrClass, sName); 
    } 

    public int StudioFrameAdvance()
    {
        SDKCall(hSDKCallStudioFrameAdvance, this.Index); 
    }

    /*public void GetAttachment(char[] sName, float vOrigin[3], float vAngle[3])    
    { 
        SDKCall(hSDKCallGetAttachment, this.Index, sName, vOrigin, vAngle); 
    } 
    
    public Address CBaseAnimatingOverlay() 
    { 
        int iOffset = (view_as<int>(GetEntityAddress(this.Index)) + FindDataMapInfo(this.Index, "m_AnimOverlay")); 
        return view_as<Address>(LoadFromAddress(view_as<Address>(iOffset), NumberType_Int32)); 
    } 
    
    public int LookupSequence(char[] sAnim) 
    { 
        return SDKCall(hSDKCallLookupSequence, this.Index, sAnim); 
    } 
    
    public int LookupActivity(char[] sAnim) 
    { 
        return SDKCall(hSDKCallLookupActivity, this.Index, sAnim); 
    } 
    
    public void SetAnimation(char[] sAnim)    
    { 
        int iSequence = this.LookupSequence(sAnim); 
        if(iSequence < 0) 
        {
            return; 
        }
        
        SDKCall(hSDKCallResetSequence, this.Index, iSequence); 
    }
    
    public int AnimOverlayCount()
    {
        // if this offset ever breaks; replace it with 15 because it doesn't really matter. 
        // All you will be doing is accessing unallocated memory :o 
        return GetEntData(this.Index, 1212);
    }
    
    public int FindGestureLayer(char[] sAnim) 
    { 
        int iSequence = this.LookupSequence(sAnim); 
        if(iSequence < 0) 
        {
            return -1; 
        }
        
        Address Overlay = this.CBaseAnimatingOverlay(); 

        // i = overlay index
        int iCount = this.AnimOverlayCount();
        for(int i = 0; i < iCount; i++) 
        { 
            int iFlags = LoadFromAddress(Overlay + view_as<Address>(m_fFlags * i), NumberType_Int32); 
            if(!(iFlags & ANIM_LAYER_ACTIVE)) 
            {
                continue; 
            }
            
            if(iFlags & ANIM_LAYER_KILLME) 
            {
                continue; 
            }

            int x = LoadFromAddress(Overlay + view_as<Address>(m_nSequence * i), NumberType_Int32); 
            if(x == iSequence) 
            {
                return i; 
            }
        } 
        
        return -1; 
    } 
    
    public void AddGesture(char[] sAnim, bool bAutoKill  = true) 
    { 
        int iSequence = this.LookupSequence(sAnim); 
        if(iSequence < 0) 
        {
            return; 
        }

        int iCount = this.AnimOverlayCount();
        int iLayer = SDKCall(hSDKCallAddLayeredSequence, this.Index, iSequence, 0); 
        if(iLayer >= 0 && iLayer <= iCount && bAutoKill) 
        { 
            int iOffsetFlags    = m_fFlags    * iLayer; 
            int iOffsetSequence = m_nSequence * iLayer; 
             
            Address Overlay = this.CBaseAnimatingOverlay();  
            int fFlags = LoadFromAddress(Overlay + view_as<Address>(iOffsetFlags), NumberType_Int32); 
            StoreToAddress(Overlay + view_as<Address>(iOffsetFlags), fFlags |= (ANIM_LAYER_AUTOKILL|ANIM_LAYER_KILLME), NumberType_Int32); 
            StoreToAddress(Overlay + view_as<Address>(iOffsetSequence), iSequence, NumberType_Int32); 
        } 
    } 
    
    public bool IsPlayingGesture(char[] sAnim)    
    { 
        return this.FindGestureLayer(sAnim) != -1 ? true : false; 
    } 
    
    public void RemoveGesture(char[] sAnim) 
    { 
        int iLayer = this.FindGestureLayer(sAnim); 
        if(iLayer == -1) 
        {
            return; 
        }
        
        Address Overlay = this.CBaseAnimatingOverlay(); 
         
        int iOffset = m_fFlags * iLayer; 
        int fFlags  = LoadFromAddress(Overlay + view_as<Address>(iOffset), NumberType_Int32); 
         
        StoreToAddress(Overlay + view_as<Address>(iOffset), fFlags |= (ANIM_LAYER_KILLME|ANIM_LAYER_AUTOKILL|ANIM_LAYER_DYING), NumberType_Int32); 
    }*/
    
    /*__________________________________________________________________________________________________*/

    public bool ValidTargetPlayer(int targetIndex, float vStart[3], float vEnd[3]) 
    {
        // Create the end-point trace
        Handle hTrace = TR_TraceRayFilterEx(vStart, vEnd, MASK_SHOT, RayType_EndPoint, TraceFilter, this.Index); 
        
        // Validate any kind of collision along the trace ray
        bool bHit;
        if(!TR_DidHit(hTrace) || TR_GetEntityIndex(hTrace) == targetIndex) 
        { 
            bHit = true; 
        } 
        
        // Close the trace
        delete hTrace
        return bHit;
    } 
     
    public void SelectTargetPoint(float vStart[3], float vMid[3]) 
    { 
        vMid = WorldSpaceCenter(this.Enemy); 
     
        // If we cannot see their WorldSpaceCenter ( possible, as we do our target finding based 
        // on the eye position of the target) then fire at the eye position 
        Handle hTrace = TR_TraceRayFilterEx(vStart, vMid, MASK_SHOT, RayType_EndPoint, TraceFilter, this.Index); 
        
        // Validate collision
        if(TR_DidHit(hTrace)) 
        {
            // Validate victim
            int victimIndex = TR_GetEntityIndex(hTrace);
            if(victimIndex >= MaxClients || victimIndex <= 0)
            {
                // Hack it lower a little bit
                // The eye position is not always within the hitboxes for a standing CS Player 
                vMid = GetEyePosition(this.Enemy); 
                vMid[2] -= 5.0; 
            }
        }
        
        // Close the trace
        delete hTrace;
    } 
    
    public void FoundTarget(int targetIndex) 
    {     
        this.Enemy = targetIndex; 
        
        if(this.Ammo > 0)
        {
            // Emit sound
            static char sSound[PLATFORM_LINE_LENGTH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 3);
            EmitSoundToAll(sSound, this.Index, SNDCHAN_STATIC, hSoundLevel.IntValue);
        }
        
        this.State = SENTRY_STATE_ATTACKING; 
        this.NextAttack = GetGameTime() + ZP_GetWeaponReload(gWeapon); 
    }

    public bool FindTarget() 
    { 
        // Initialize vectors
        static float vSentryOrigin[3]; static float vSegment[3]; static float vTargetCenter[3]; 
    
        // Loop through players within 1100 units (sentry range)
        vSentryOrigin = GetEyePosition(this.Index); 

        // If we have an enemy get his minimum distance to check against
        int targetIndex = INVALID_ENT_REFERENCE; 
        int targetOldIndex = this.Enemy; 
        float flMinDist = ZP_GetWeaponKnockBack(gWeapon); 
        float flOldTargetDist = 2147483647.0; 
        float flDist; 
        
        // i = client index
        for(int i = 1; i <= MaxClients; i++) 
        {
            // Validate client
            if(!IsPlayerExist(i)) 
            {
                continue; 
            }
            
            // Validate human
            if(ZP_IsPlayerHuman(i)) 
            {
                continue; 
            }
            
            // Gets target distance
            vTargetCenter = GetAbsOrigin(i); 
            vTargetCenter[2] += GetEntPropFloat(i, Prop_Send, "m_vecViewOffset[2]"); 
            SubtractVectors(vTargetCenter, vSentryOrigin, vSegment); 
            flDist = GetVectorLength(vSegment); 

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
            if(this.ValidTargetPlayer(i, vSentryOrigin, vTargetCenter)) 
            { 
                flMinDist = flDist; 
                targetIndex = i; 
            } 
        } 
         
        // If we already have a target, don't check objects 
        /*if(targetIndex == INVALID_ENT_REFERENCE) 
        {
            // Find any chicken
            int chickenIndex = MAXPLAYERS + 1; 
            while((chickenIndex = FindEntityByClassname(chickenIndex, "chicken")) != -1) 
            {
                // Gets target distance
                vTargetCenter = GetEyePosition(chickenIndex); 
                SubtractVectors(vTargetCenter, vSentryOrigin, vSegment); 
                flDist = GetVectorLength(vSegment); 
     
                // Store the current target distance if we come across it 
                if(chickenIndex == targetOldIndex) 
                { 
                    flOldTargetDist = flDist; 
                } 
     
                // Check to see if the target is closer than the already validated target
                if(flDist > flMinDist) 
                {
                    continue; 
                }
                
                // It is closer, check to see if the target is valid 
                if(this.ValidTargetPlayer(chickenIndex, vSentryOrigin, vTargetCenter)) 
                { 
                    flMinDist = flDist; 
                    targetIndex = chickenIndex; 
                } 
            } 
        } */
     
        // We have a target
        if(targetIndex != INVALID_ENT_REFERENCE) 
        { 
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
            
            return true; 
        } 
        
        return false; 
    }

    public bool MoveTurret() 
    { 
        bool bMoved = false; 
        float iBaseTurnRate = ZP_GetWeaponModelHeat(gWeapon); 
        
        // Start it rotating
        static float vGoalAngle[3]; static float vCurAngle[3];
        this.GetGoalAngles(vGoalAngle); 
        this.GetCurAngles(vCurAngle);
        
        // Any x movement? 
        if(vCurAngle[0] != vGoalAngle[0]) 
        { 
            float flDir = vGoalAngle[0] > vCurAngle[0] ? 1.0 : -1.0 ; 
            vCurAngle[0] += ZP_GetWeaponReload(gWeapon) * (iBaseTurnRate * 5) * flDir; 
     
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
     
            this.SetPoseParameter(this.LookupPoseParameter("pitch"), -50.0, 50.0, vCurAngle[0]); 
            bMoved = true; 
        } 
         
        if(vCurAngle[1] != vGoalAngle[1]) 
        { 
            float flDir = vGoalAngle[1] > vCurAngle[1] ? 1.0 : -1.0 ; 
            float flDist = FloatAbs(vGoalAngle[1] - vCurAngle[1]); 
            bool bReversed = false; 
     
            if(flDist > 180) 
            { 
                flDist = 360 - flDist; 
                flDir = -flDir; 
                bReversed = true; 
            } 
     
            if(this.Enemy == INVALID_ENT_REFERENCE) 
            { 
                if(flDist > 30) 
                { 
                    if(this.TurnRate < iBaseTurnRate * 10) 
                        this.TurnRate += iBaseTurnRate; 
                } 
                else 
                { 
                    // Slow down 
                    if(this.TurnRate > (iBaseTurnRate * 5)) 
                        this.TurnRate -= iBaseTurnRate; 
                } 
            } 
            else 
            { 
                // When tracking enemies, move faster and don't slow 
                if(flDist > 30) 
                { 
                    if(this.TurnRate < iBaseTurnRate * 30) 
                        this.TurnRate += iBaseTurnRate * 3; 
                } 
            } 
     
            vCurAngle[1] += ZP_GetWeaponReload(gWeapon) * this.TurnRate * flDir; 
     
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
     
            if(vCurAngle[1] < 0) 
            { 
                vCurAngle[1] += 360; 
            } 
            else if(vCurAngle[1] >= 360) 
            { 
                vCurAngle[1] -= 360; 
            } 
     
            if(flDist < (ZP_GetWeaponReload(gWeapon) * 0.5 * iBaseTurnRate)) 
            { 
                vCurAngle[1] = vGoalAngle[1]; 
            } 
     
            // Gets the angles
            static float vAngle[3]; 
            vAngle = GetAbsAngles(this.Index); 
            
            float flYaw = AngleNormalize(vCurAngle[1] - vAngle[1]); 
            this.SetPoseParameter(this.LookupPoseParameter("yaw"), -180.0, 180.0, flYaw); 
            this.SetCurAngles(vCurAngle);
            bMoved = true; 
        } 
     
        if(!bMoved || this.TurnRate <= 0) 
        { 
            this.TurnRate = iBaseTurnRate * 5; 
        } 
     
        return bMoved; 
    } 

    public bool Fire() 
    { 
        // Initialize vectors
        static float vAimDir[3]; static float vSrc[3]; static float vAng[3]; static float vMidEnemy[3];  

        // All turrets fire shells 
        if(this.Ammo > 0) 
        { 
            /*if(!this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
            { 
                this.RemoveGesture("ACT_RANGE_ATTACK1_LOW"); 
                this.AddGesture("ACT_RANGE_ATTACK1"); 
            }*/

            // Emit sound
            static char sSound[PLATFORM_LINE_LENGTH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 5);
            EmitSoundToAll(sSound, this.Index, SNDCHAN_STATIC, hSoundLevel.IntValue);

            // Gets the positions
            ///this.GetAttachment("muzzle", vSrc, vAng);
            ZP_GetAttachment(this.Index, "muzzle", vSrc, vAng);
            this.SelectTargetPoint(vSrc, vMidEnemy);
            SubtractVectors(vMidEnemy, vSrc, vAimDir); 
            float flDistToTarget = GetVectorLength(vAimDir); 
            NormalizeVector(vAimDir, vAimDir); 
             
            // Create a bullet
            FireBullet(this.Index, this.Owner, vSrc, vAimDir, ZP_GetWeaponDamage(gWeapon), flDistToTarget * 500, DMG_BULLET, "weapon_tracers_50cal"); 
            
            // Draw muzzle
            static char sMuzzle[SMALL_LINE_LENGTH];
            ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
            ZP_CreateParticle(this.Index, vSrc, "muzzle", sMuzzle, ZP_GetWeaponSpeed(gWeapon));
            
            // Reduce ammo
            this.Ammo--; 
        } 
        else 
        {
            // Emit sound
            EmitSoundToAll("sound/weapons/lowammo_01.wav", this.Index, SNDCHAN_STATIC, hSoundLevel.IntValue);
            
            // Out of ammo, play a click 
            this.NextAttack = GetGameTime() + 0.2; 
        } 
     
        return true; 
    } 
    
    public void SentryRotate() 
    { 
        // if we're playing a fire gesture, stop it 
        /*if(this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
        { 
            this.RemoveGesture("ACT_RANGE_ATTACK1"); 
        } 
        if(this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
        { 
            this.RemoveGesture("ACT_RANGE_ATTACK1_LOW"); 
        }*/
     
        // Look for a target 
        if(this.FindTarget()) 
        { 
            return; 
        } 
     
        // Rotate a bit
        if(!this.MoveTurret()) 
        {
            // Emit sound
            static char sSound[PLATFORM_LINE_LENGTH];
            ZP_GetSound(gSound, sSound, sizeof(sSound), 1);
            EmitSoundToAll(sSound, this.Index, SNDCHAN_STATIC, hSoundLevel.IntValue);
     
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
     
        // Track enemy 
        vMid = WorldSpaceCenter(this.Index); 
        this.SelectTargetPoint(vMid, vMidEnemy);
        SubtractVectors(vMidEnemy, vMid, vDirToEnemy); 
        GetVectorAngles(vDirToEnemy, vAngle); 
     
        // Calculate angles
        vAngle[1] = AngleMod(vAngle[1]); 
        if(vAngle[0] < -180) 
            vAngle[0] += 360; 
        if(vAngle[0] > 180) 
            vAngle[0] -= 360; 
     
        // now all numbers should be in [1...360] 
        // pin to turret limitations to [-50...50] 
        if(vAngle[0] > 50) 
            vAngle[0] = 50.0; 
        else if(vAngle[0] < -50) 
            vAngle[0] = -50.0; 

        // Start it rotating
        static float vGoalAngle[3]; static float vCurAngle[3]; static float vSubtract[3]; 
        this.GetGoalAngles(vGoalAngle); 
        this.GetCurAngles(vCurAngle);
        vGoalAngle[1] = vAngle[1]; 
        vGoalAngle[0] = vAngle[0]; 
        this.SetGoalAngles(vGoalAngle);     
        this.MoveTurret(); 
        SubtractVectors(vGoalAngle, vCurAngle, vSubtract); 
         
        // Fire on the target if it's within 10 units of being aimed right at it 
        if(this.NextAttack <= GetGameTime() && GetVectorLength(vSubtract) <= 10) 
        { 
            this.Fire(); 
            this.NextAttack = GetGameTime() + ZP_GetWeaponSpeed(gWeapon);
        } 
         
        // Validate range
        /*if(GetVectorLength(vSubtract) > 10) 
        { 
            // if we're playing a fire gesture, stop it 
            if(this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
            { 
                this.RemoveGesture("ACT_RANGE_ATTACK1"); 
            } 
        }*/
    }
    
    public void Death()
    {
        // Initialize vectors
        static float vGibAngle[3]; float vShootAngle[3];

        // Emit sound
        EmitSoundToAll("sound/survival/turret_death_01.wav", this.Index, SNDCHAN_STATIC, hSoundLevel.IntValue);
        
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

            // Create a shooter entity
            int entityIndex = CreateEntityByName("env_shooter");

            // If entity isn't valid, then skip
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Dispatch main values of the entity
                DispatchKeyValueVector(entityIndex, "angles", vShootAngle);
                DispatchKeyValueVector(entityIndex, "gibangles", vGibAngle);
                DispatchKeyValue(entityIndex, "rendermode", "5");
                DispatchKeyValue(entityIndex, "shootsounds", "2");
                DispatchKeyValue(entityIndex, "shootmodel", sBuffer);
                DispatchKeyValueFloat(entityIndex, "m_iGibs", METAL_GIBS_AMOUNT);
                DispatchKeyValueFloat(entityIndex, "delay", METAL_GIBS_DELAY);
                DispatchKeyValueFloat(entityIndex, "m_flVelocity", METAL_GIBS_SPEED);
                DispatchKeyValueFloat(entityIndex, "m_flVariance", METAL_GIBS_VARIENCE);
                DispatchKeyValueFloat(entityIndex, "m_flGibLife", METAL_GIBS_LIFE);

                // Spawn the entity into the world
                DispatchSpawn(entityIndex);

                // Activate the entity
                ActivateEntity(entityIndex);  
                AcceptEntityInput(entityIndex, "Shoot");

                // Sets parent to the entity
                SetVariantString("!activator"); 
                AcceptEntityInput(entityIndex, "SetParent", this.Index, entityIndex); 

                // Sets attachment to the entity
                SetVariantString("muzzle"); /// Attachment name in the turret model
                AcceptEntityInput(entityIndex, "SetParentAttachment", this.Index, entityIndex);

                // Initialize time char
                FormatEx(sBuffer, sizeof(sBuffer), "OnUser1 !self:kill::%f:1", METAL_GIBS_DURATION);

                // Sets modified flags on the entity
                SetVariantString(sBuffer);
                AcceptEntityInput(entityIndex, "AddOutput");
                AcceptEntityInput(entityIndex, "FireUser1");
            }
        }

        // Sets modified flags on the entity
        SetVariantString("OnUser1 !self:kill::0.1:1");
        AcceptEntityInput(this.Index, "AddOutput");
        AcceptEntityInput(this.Index, "FireUser1");
    }
} 

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

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
    static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3];
    
    // Gets weapon position
    ZP_GetPlayerGunPosition(clientIndex, 0.0, 0.0, 0.0, vPosition);
    ZP_GetPlayerGunPosition(clientIndex, 150.0, 0.0, 0.0, vEndPosition);

    // Create the end-point trace
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter2);

    // Validate collisions
    if(TR_DidHit(hTrace) && TR_GetEntityIndex(hTrace) < 1)
    {
        // Returns the collision position/angle of a trace result
        TR_GetEndPosition(vPosition, hTrace);
        TR_GetPlaneNormal(hTrace, vAngle); 
        
        // Shift position
        //vPosition[2] += 15.0;
        
        // Create a dronegun entity
        SentryGun(clientIndex, vPosition, vAngle); 
        
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetWeaponSpeed(gWeapon);
                
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    
        
        // Forces a player to remove weapon
        RemovePlayerItem(clientIndex, weaponIndex);
        AcceptEntityInput(weaponIndex, "Kill");
        
        // Gets weapon index
        int weaponIndex2 = GetPlayerWeaponSlot(clientIndex, view_as<int>(SlotType_Melee)); // Switch to knife
        
        // Validate weapon
        if(IsValidEdict(weaponIndex2))
        {
            // Gets weapon classname
            static char sClassname[SMALL_LINE_LENGTH];
            GetEdictClassname(weaponIndex2, sClassname, sizeof(sClassname));
            
            // Switch the weapon
            FakeClientCommand(clientIndex, "use %s", sClassname);
        }
    }

    // Close the trace
    delete hTrace;
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
 * @param inflicterIndex    The inflicter index.
 * @param damage            The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action SentryDamageHook(int entityIndex, int &attackerIndex, int &inflicterIndex, float &flDamage, int &damageBits)
{
    // Validate attacker
    if(IsPlayerExist(attackerIndex))
    {
        // Gets the object methods
        SentryGun sentry = view_as<SentryGun>(GetEntPropEnt(entityIndex, Prop_Data, "m_hOwnerEntity")); 

        // Validate zombie
        if(ZP_IsPlayerZombie(attackerIndex) || sentry.Owner == attackerIndex)
        {
            // Calculate the damage
            int iHealth = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

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
                SetEntProp(entityIndex, Prop_Data, "m_iHealth", iHealth); 
                
                // Emit sound
                switch(GetRandomInt(0, 2))
                {
                    case 0 : EmitSoundToAll("sound/survival/turret_takesdamage_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                    case 1 : EmitSoundToAll("sound/survival/turret_takesdamage_02.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                    case 2 : EmitSoundToAll("sound/survival/turret_takesdamage_03.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                }
            }
        }
    }
    
    // Return on success
    return Plugin_Handled;
}

/**
 * @brief Bullet trace.
 *
 * @param inflicterIndex    The inflicter index.  
 * @param attackerIndex     The attacker index.  
 * @param vPosition         The shoot position.
 * @param vDirShooting      The shoot direction.
 * @param flDamage          The damage value.
 * @param flDistance        The distance value.
 * @param nDamageType       The damage type.
 * @param tracerEffect      The tracer effect.    
 **/
public void FireBullet(int inflicterIndex, int attackerIndex, float vPosition[3], float vDirShooting[3], float flDamage, float flDistance, int nDamageType, char[] tracerEffect) 
{ 
    // Initialize vectors
    static float vEndPosition[3]; static float vNormal[3]; 
    
    // Calculate a bullet path
    vEndPosition[0] = vPosition[0] + vDirShooting[0] * flDistance;  
    vEndPosition[1] = vPosition[1] + vDirShooting[1] * flDistance; 
    vEndPosition[2] = vPosition[2] + vDirShooting[2] * flDistance; 
     
    // Fire a bullet 
    Handle hTrace = TR_TraceRayFilterEx(vPosition, vEndPosition, MASK_SHOT, RayType_EndPoint, TraceFilter, inflicterIndex); 

    // Returns the collision position of a trace result
    TR_GetEndPosition(vEndPosition, hTrace);
    
    // Validate collisions
    if(TR_GetFraction(hTrace) >= 1.0)
    {
        // Initialize the hull intersection
        static float vMins[3] = { -16.0, -16.0, -18.0  }; 
        static float vMaxs[3] = {  16.0,  16.0,  18.0  }; 
        
        // Create the hull trace
        hTrace = TR_TraceHullFilterEx(vPosition, vEndPosition, vMins, vMaxs, MASK_SHOT_HULL, TraceFilter, inflicterIndex);
    }

    // Validate collisions
    if(TR_GetFraction(hTrace) < 1.0) 
    {
        // Gets victim index
        int victimIndex = TR_GetEntityIndex(hTrace);

        // Returns the collision position of a trace result
        TR_GetEndPosition(vEndPosition, hTrace); 
    
        // Sentryguns are perfectly accurate, but this doesn't look good for tracers
        // Add a little noise to them, but not enough so that it looks like they're missing
        vEndPosition[0] += GetRandomFloat(-10.0, 10.0); 
        vEndPosition[1] += GetRandomFloat(-10.0, 10.0); 
        vEndPosition[2] += GetRandomFloat(-10.0, 10.0); 

        // Bullet tracer (Not work properly!)
        //TE_DispatchEffect(inflicterIndex, tracerEffect, "ParticleEffect", vPosition, vEndPosition);
        //TE_SendToAll();

        // Validate victim
        if(IsPlayerExist(victimIndex) && ZP_IsPlayerZombie(victimIndex))
        {    
            // Create the damage for a victim
            if(!ZP_TakeDamage(victimIndex, attackerIndex, inflicterIndex, flDamage, nDamageType))
            {
                // Create a custom death event
                static char sIcon[SMALL_LINE_LENGTH];
                ZP_GetWeaponIcon(gWeapon, sIcon, sizeof(sIcon));
                ZP_CreateDeathEvent(victimIndex, attackerIndex, sIcon);
            }
            
            // Create a blood effect
            ZP_CreateParticle(victimIndex, vEndPosition, _, "blood_impact_heavy", 0.1);
        }
        else
        {
            // Returns the collision angle of a trace result
            TR_GetPlaneNormal(hTrace, vNormal); 
            GetVectorAngles(vNormal, vNormal); 
    
            // Can't get surface properties from traces unfortunately
            // Just another shortsighting from the SM devs :/// 
            ZP_CreateParticle(inflicterIndex, vEndPosition, _, "impact_dirt", 0.1);
            
            // Move the impact effect a bit out so it doesn't clip the wall
            float flPercentage = 0.2 / (GetVectorDistance(vPosition, vEndPosition) / 100);
            vEndPosition[0] = vEndPosition[0] + ((vPosition[0] - vEndPosition[0]) * flPercentage);
            vEndPosition[1] = vEndPosition[1] + ((vPosition[1] - vEndPosition[1]) * flPercentage);
            vEndPosition[2] = vEndPosition[2] + ((vPosition[2] - vEndPosition[2]) * flPercentage);
            
            // Create an another impact effect
            TE_Start("Impact"); 
            TE_WriteVector("m_vecOrigin", vEndPosition); 
            TE_WriteVector("m_vecNormal", vNormal); 
            TE_WriteNum("m_iType", GetRandomInt(1, 10)); 
            TE_SendToAllInRange(vEndPosition, RangeType_Visibility);
        }
    } 
    
    // Close the trace
    delete hTrace; 
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
    return (entityIndex != filterIndex);
}

/**
 * @brief Trace filter.
 *
 * @param entityIndex       The entity index.  
 * @param contentsMask      The contents mask.
 * @return                  True or false.
 **/
public bool TraceFilter2(int entityIndex, int contentsMask)
{
    return !(1 <= entityIndex <= MaxClients);
}

//**********************************************
//* Item (drone) stocks.                       *
//**********************************************

/**
 * @brief Gets the entity origin vector.
 *
 * @param entityIndex       The entity index.  
 * @return                  The origin vector.
 **/
stock float[] GetAbsOrigin(int entityIndex) 
{ 
    static float vPosition[3]; 
    GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition); 
    return vPosition; 
} 

/**
 * @brief Gets the entity absolute vector.
 *
 * @param entityIndex       The entity index.  
 * @return                  The angle vector.
 **/
stock float[] GetAbsAngles(int entityIndex) 
{ 
    static float vPosition[3]; 
    GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vPosition); 
    return vPosition; 
} 

/**
 * @brief Gets the entity eye angles.
 *
 * @param entityIndex       The entity index.  
 * @return                  The eye vector.
 **/
stock float[] GetEyeAngles(int entityIndex) 
{ 
    static float vAngle[3]; 
    GetClientEyeAngles(entityIndex, vAngle); 
    return vAngle; 
} 

/**
 * @brief Gets the entity eye angles.
 *
 * @param entityIndex       The entity index.  
 * @return                  The eye vector.
 **/
stock float[] GetEyePosition(int entityIndex) 
{ 
    static float vPosition[3]; 
    vPosition = GetAbsOrigin(entityIndex); 
    
    // Validate turret
    static char sClassname[SMALL_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
    if(!strcmp(sClassname, "turret_", false))
    { 
        vPosition[2] += 32.0; 
    } 
    else 
    { 
        static float vMax[3]; 
        GetEntPropVector(entityIndex, Prop_Data, "m_vecMaxs", vMax); 
        vPosition[2] += vMax[2]; 
    } 

    return vPosition; 
} 

/**
 * @brief Gets the entity center origin.
 *
 * @param entityIndex       The entity index.  
 * @return                  The center vector.
 **/
stock float[] WorldSpaceCenter(int entityIndex) 
{ 
    static float vPosition[3]; 
    vPosition = GetAbsOrigin(entityIndex); 
     
    static float vMax[3]; 
    GetEntPropVector(entityIndex, Prop_Data, "m_vecMaxs", vMax); 
    vPosition[2] += vMax[2] / 2; 
     
    return vPosition; 
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
 * @brief Calculate the bullet damage force vector.
 *
 * @param vDir              The direction vector.  
 * @patam flScale           The scale value.
 * @return                  The force vector.
 **/
stock float[] CalculateBulletDamageForce(float vDir[3], float flScale) 
{ 
    static float vForce[3]; vForce = vDir; 
    NormalizeVector(vForce, vForce); 
    ScaleVector(vForce, FindConVar("phys_pushscale").FloatValue); 
    ScaleVector(vForce, flScale); 
    return vForce; 
} 