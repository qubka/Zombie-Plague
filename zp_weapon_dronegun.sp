/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
	name            = "[ZP] Weapon: DroneGun",
	author          = "qubka (Nikita Ushakov), Pelipoika",     
	description     = "Addon of custom weapons",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gDecal[5];
#pragma unused gDecal

// Sound index
int gSoundShoot; int gSoundUpgrade; ConVar hKnockBack;
#pragma unused gSoundShoot, gSoundUpgrade, hKnockBack
 
// Item index
int gWeapon;
#pragma unused gWeapon

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
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME              1.63
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT             5.0
#define METAL_GIBS_DELAY              0.2
#define METAL_GIBS_SPEED              200.0
#define METAL_GIBS_VARIENCE           2.0  
#define METAL_GIBS_LIFE               5.0  
#define METAL_GIBS_DURATION           6.0
/**
 * @endsection
 **/
 
/**
 * @section Properties of the turret.
 **/
#define SENTRY_ATTACK_NPC             // Uncomment to avoid attack chichens and npc
#define SENTRY_ATTACK_VISIVILTY       50.0
#define SENTRY_BULLET_DAMAGE          20.0
#define SENTRY_BULLET_RANGE           1100.0
#define SENTRY_BULLET_DISTANCE        8192.0
#define SENTRY_BULLET_RADIUS          5.0
#define SENTRY_BULLET_TURN            2.0
#define SENTRY_BULLET_THINK           0.05
#define SENTRY_BULLET_SPEED           0.2
#define SENTRY_EYE_OFFSET_LEVEL_1     32.0 
#define SENTRY_EYE_OFFSET_LEVEL_2     40.0 
#define SENTRY_EYE_OFFSET_LEVEL_3     46.0
#define SENTRY_SHOOTER_OFFSET_LEVEL   70.0
#define SENTRY_ROCKET_DELAY           3.0
#define SENTRY_ROCKET_RELOAD          1.8
#define SENTRY_ROCKET_SPEED           1000.0
#define SENTRY_ROCKET_DAMAGE          300.0
#define SENTRY_ROCKET_KNOCKBACK       300.0
#define SENTRY_ROCKET_GRAVITY         0.01
#define SENTRY_ROCKET_RADIUS          400.0
#define SENTRY_ROCKET_EFFECT_TIME     5.0
#define SENTRY_ROCKET_EXPLOSION_TIME  2.0
#define SENTRY_CONTROL_MENU           10
#define SENTRY_CONTROL_UPGRADE_RATIO  0.5
#define SENTRY_CONTROL_REFILL_RATIO   0.1  
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
	SENTRY_SOUND_EXPLOAD,
	SENTRY_SOUND_UPGRADE
};
/**
 * @sectionend
 **/
 
/*__________________________________________________________________________________________________*/  
 
// Animation sequences
enum
{
	ANIM_IDLE,
	ANIM_DRAW
};

// Effect modes
enum
{
	EFFECT_CREATE,
	EFFECT_KILL,
	EFFECT_UPDATE,
	EFFECT_PLACE
};

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	// Validate library
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		// Loads a game config file
		GameData hConfig = LoadGameConfigFile("plugin.turret"); 

		// Validate config
		if (!hConfig) 
		{
			SetFailState("Failed to load turret gamedata.");
			return;
		}

		/*__________________________________________________________________________________________________*/
		
		// Load other offsets
		if ((AnimatingOverlay_Count = hConfig.GetOffset("CBaseAnimatingOverlay::Count")) == -1) SetFailState("Failed to get offset: \"CBaseAnimatingOverlay::Count\". Update offset in \"plugin.turret\""); 

		/*__________________________________________________________________________________________________*/
		
		// Starts the preparation of an SDK call
		StartPrepSDKCall(SDKCall_Entity); 
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimatingOverlay::StudioFrameAdvance"); 
		
		// Validate call
		if ((hSDKCallStudioFrameAdvance = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimatingOverlay::StudioFrameAdvance\". Update signature in \"plugin.turret\"");      
		
		/*__________________________________________________________________________________________________*/
		
		// Starts the preparation of an SDK call
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimatingOverlay::AddLayeredSequence"); 
		
		// Adds a parameter to the calling convention. This should be called in normal ascending order
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		// Validate call
		if ((hSDKCallAddLayeredSequence = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimatingOverlay::AddLayeredSequence\". Update signature in \"plugin.turret\""); 
		
		/*__________________________________________________________________________________________________*/

		// Close file
		delete hConfig;
		
		// Load translations phrases used by plugin
		LoadTranslations("zombieplague.phrases");
		
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
	gWeapon = ZP_GetWeaponNameID("drone gun");
	//if (gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"drone gun\" wasn't find");
	
	// Sounds
	gSoundShoot = ZP_GetSoundKeyID("TURRET_SOUNDS");
	if (gSoundShoot == -1) SetFailState("[ZP] Custom sound key ID from name : \"TURRET_SOUNDS\" wasn't find");
	gSoundUpgrade = ZP_GetSoundKeyID("TURRET_UP_SOUNDS");
	if (gSoundUpgrade == -1) SetFailState("[ZP] Custom sound key ID from name : \"TURRET_UP_SOUNDS\" wasn't find");

	// Cvars
	hKnockBack = FindConVar("zp_knockback"); 
	if (hKnockBack == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_knockback\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart(/*void*/)
{
	// Sounds
	PrecacheSound("survival/turret_death_01.wav", true);
	PrecacheSound("survival/turret_takesdamage_01.wav", true);
	PrecacheSound("survival/turret_takesdamage_02.wav", true);
	PrecacheSound("survival/turret_takesdamage_03.wav", true);
	
	// Decals
	gDecal[0] = PrecacheDecal("decals/concrete/shot1.vmt", true);
	gDecal[1] = PrecacheDecal("decals/concrete/shot2.vmt", true);
	gDecal[2] = PrecacheDecal("decals/concrete/shot3.vmt", true);
	gDecal[3] = PrecacheDecal("decals/concrete/shot4.vmt", true);
	gDecal[4] = PrecacheDecal("decals/concrete/shot5.vmt", true);
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
	
	// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.sp#L1073
	public void RemoveLayer(int iLayer, float flKillRate, float flKillDelay)
	{
		this.Set(m_flKillRate, iLayer, flKillRate > 0.0 ? this.Get(m_flWeight, iLayer) / flKillRate : 100.0);
		this.Set(m_flKillDelay, iLayer, flKillDelay);
		this.KillMe(iLayer);
	}
	
	// @link https://github.com/droozynuu/swarm-sdk-template/blob/79af61e7756be2921eebf917e35a42577c9ca9ec/src/game/server/BaseAnimatingOverlay.sp#L1025
	public void SetLayerAutokill(int iLayer, bool bAutokill)
	{
		if (bAutokill)
		{
			this.AutoKill(iLayer);
		}
		else
		{
			this.Loop(iLayer);
		}
	}
	
	// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.sp#L815
	public bool IsAlive(int iLayer)         { int iFlags = this.Get(m_fFlags, iLayer); return (((iFlags & ANIM_LAYER_ACTIVE) != 0) || ((iFlags & ANIM_LAYER_KILLME) == 0)); }
	
	// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.sp#L1060
	public int GetLayerSequence(int iLayer) { return (this.Get(m_nSequence, iLayer)); }
};

methodmap SentryGun /** Regards to Pelipoika **/
{
	// Constructor
	public SentryGun(int owner, float vPosition[3], float vAngle[3], int iHealth, int iAmmo, int iRocket, int iSkin, int iLevel) 
	{
		// Create a monster entity
		int entity = UTIL_CreateMonster("turret", vPosition, vAngle, "models/buildables/sentry1.mdl", NPC_GAG | NPC_WAITFORSCRIPT | NPC_DONTDROPWEAPONS | NPC_IGNOREPLAYERPUSH);
		
		// Validate entity
		if (entity != -1)
		{
			// Initialize vectors
			static float vGoal[3]; static float vCurrent[3]; 

			// Sets boundaries
			int iRightBound = RoundToNearest(AngleMod(vAngle[1] - 50.0)); 
			int iLeftBound  = RoundToNearest(AngleMod(vAngle[1] + 50.0)); 
			if (iRightBound > iLeftBound) 
			{
				iRightBound = iLeftBound; 
				iLeftBound = RoundToNearest(AngleMod(vAngle[1] - 50.0)); 
			}
			SetEntProp(entity, Prop_Data, "m_iSpeedModSpeed", iRightBound); 
			SetEntProp(entity, Prop_Data, "m_iSpeedModRadius", iLeftBound); 
			
			// Start it rotating
			vGoal[1] = float(iRightBound); 
			vGoal[0] = vCurrent[0] = 0.0; 
			vCurrent[1] = AngleMod(vAngle[1]); 
			SetEntPropVector(entity, Prop_Data, "m_vecLastPosition", vCurrent); 
			SetEntPropVector(entity, Prop_Data, "m_vecStoredPathGoal", vGoal);
			SetEntProp(entity, Prop_Data, "m_bSpeedModActive", true); 
			SetEntProp(entity, Prop_Data, "m_bIsAutoaimTarget", true);
			SetEntProp(entity, Prop_Data, "m_iInteractionState", SENTRY_STATE_SEARCHING); 
			
			/**__________________________________________________________**/

			// Sets physics
			/*SetEntityMoveType(parent, MOVETYPE_NONE);
			SetEntProp(parent, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON); 
			SetEntProp(parent, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);*/
			
			// Sets effects
			SetEntProp(entity, Prop_Send, "m_nSkin", iSkin);
			SetEntProp(entity, Prop_Send, "m_nBody", 2);

			// Sets health
			SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
			SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
			SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHealth);

			// Sets owner for the entity
			SetEntPropEnt(entity, Prop_Data, "m_pParent", owner); 

			// Sets ammunition and mode
			SetEntProp(entity, Prop_Data, "m_iAmmo", iAmmo); 
			SetEntProp(entity, Prop_Data, "m_iMySquadSlot", iRocket); 
			SetEntProp(entity, Prop_Data, "m_iHammerID", iLevel); 
			SetEntProp(entity, Prop_Data, "m_iDesiredWeaponState", SENTRY_MODE_NORMAL); 
			SetEntPropFloat(entity, Prop_Data, "m_flUseLookAtAngle", 0.0); ///
			
			// Make model invisible
			UTIL_SetRenderColor(entity, Color_Alpha, 0);
			
			// Create damage hook
			SDKHook(entity, SDKHook_OnTakeDamage, SentryDamageHook);
			
			// Create a upgradable entity
			vPosition[2] -= 35.0;
			int upgrade = UTIL_CreateDynamic("upgrade", vPosition, vAngle, "models/buildables/sentry1_heavy.mdl", "build");

			// Validate entity
			if (upgrade != -1)
			{
				// Sets effects
				SetEntProp(upgrade, Prop_Send, "m_nSkin", iSkin);
				SetEntProp(upgrade, Prop_Send, "m_nBody", 2);

				// Sets owner for the entity
				SetEntPropEnt(upgrade, Prop_Data, "m_hOwnerEntity", entity);
				
				// Sets upgrade for the entity
				SetEntPropEnt(entity, Prop_Data, "m_hInteractionPartner", upgrade); 
				
				// Play sound
				ZP_EmitSoundToAll(gSoundUpgrade, 1, upgrade, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
				
				// Create timer to activate
				CreateTimer(5.0, SentryActivateHook, EntIndexToEntRef(upgrade), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		
		// Return index on the success
		return view_as<SentryGun>(entity); 
	} 
	
	/*__________________________________________________________________________________________________*/
	 
	property int Index 
	{ 
		public get() 
		{  
			return view_as<int>(this);  
		} 
	}
	
	property float NextSound
	{
		public get() 
		{  
			return GetEntPropFloat(this.Index, Prop_Data, "m_flUseLookAtAngle");  
		}

		public set(float flDelay) 
		{
			SetEntPropFloat(this.Index, Prop_Data, "m_flUseLookAtAngle", flDelay); 
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
	
	property int Enemy
	{ 
		public get() 
		{  
			return GetEntPropEnt(this.Index, Prop_Data, "m_hEnemy");  
		}

		public set(int entity) 
		{
			SetEntPropEnt(this.Index, Prop_Data, "m_hEnemy", entity); 
		}
	}

	property int Skin
	{
		public get() 
		{  
			return GetEntProp(this.Index, Prop_Send, "m_nSkin");  
		}

		public set(int iSkin) 
		{
			SetEntPropEnt(this.Index, Prop_Send, "m_nSkin", iSkin); 
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
			return GetEntProp(this.Index, Prop_Data, "m_iInteractionState");  
		}

		public set(int iState) 
		{
			SetEntProp(this.Index, Prop_Data, "m_iInteractionState", iState); 
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
	
	property bool Lock
	{ 
		public get() 
		{  
			return view_as<bool>(GetEntProp(this.Index, Prop_Data, "m_bIsAutoaimTarget"));  
		}

		public set(bool bLock) 
		{
			SetEntProp(this.Index, Prop_Data, "m_bIsAutoaimTarget", bLock); 
		}
	}
	
	property int Owner
	{ 
		public get() 
		{  
			return GetEntPropEnt(this.Index, Prop_Data, "m_pParent");  
		}

		public set(int entity) 
		{
			SetEntPropEnt(this.Index, Prop_Data, "m_pParent", entity); 
		}
	}

	property int UpgradeState
	{ 
		public get() 
		{  
			return GetEntProp(this.Index, Prop_Data, "m_iHammerID");  
		}

		public set(int iLevel) 
		{
			SetEntProp(this.Index, Prop_Data, "m_iHammerID", iLevel); 
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

	property int UpgradeModel
	{
		public get() 
		{  
			return GetEntPropEnt(this.Index, Prop_Data, "m_hInteractionPartner");  
		}

		public set(int upgrade) 
		{
			SetEntPropEnt(this.Index, Prop_Data, "m_hInteractionPartner", upgrade); 
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
		switch (this.UpgradeLevel) 
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
		if (!iOffset) iOffset = FindDataMapInfo(this.Index, "m_AnimOverlay");
		return CAnimationOverlay(GetEntData(this.Index, iOffset));
	}

	public int AnimOverlayCount()
	{
		static int iOffset;
		if (!iOffset) iOffset = FindDataMapInfo(this.Index, "m_AnimOverlay") + AnimatingOverlay_Count;
		return GetEntData(this.Index, iOffset);
	}
	
	public void SetPoseParameter(int iParameter, float flStart, float flEnd, float flValue)    
	{ 
		float flCtl = (flValue - flStart) / (flEnd - flStart); 
		if (flCtl < 0) flCtl = 0.0; 
		if (flCtl > 1) flCtl = 1.0; 
		 
		SetEntPropFloat(this.Index, Prop_Send, "m_flPoseParameter", flCtl, iParameter); 
	} 
	
	/*__________________________________________________________________________________________________*/
	
	// @info https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.sp#L811
	public int FindGestureLayer(char[] sAnim) 
	{
		// Find the sequence index
		int iSequence = ZP_LookupSequence(this.Index, sAnim); 
		if (iSequence < 0) 
		{
			return -1; 
		}

		// Validate address
		CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
		if (pOverlay.isNull) 
		{
			return -1; 
		}
		
		// i = layer index
		int iCount = this.AnimOverlayCount();
		for (int i = 0; i < iCount; i++) 
		{
			// Validate layer
			if (!pOverlay.IsAlive(i)) 
			{
				continue; 
			}

			// Validate sequence
			if (pOverlay.GetLayerSequence(i) == iSequence) 
			{
				return i; 
			}
		} 
		
		// Return on the unsuccess
		return -1; 
	}

	// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.sp#L527
	public int AddGesture(char[] sAnim, bool bAutoKill = true) 
	{ 
		// Find the sequence index
		int iSequence = ZP_LookupSequence(this.Index, sAnim); 
		if (iSequence < 0) 
		{
			return -1; 
		}

		// Validate address
		CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
		if (pOverlay.isNull) 
		{
			return -1; 
		}
		
		// Create a new layer
		int iLayer = SDKCall(hSDKCallAddLayeredSequence, this.Index, iSequence, 0); 
		if (iLayer >= 0 && iLayer < this.AnimOverlayCount() && pOverlay.IsActive(iLayer))
		{
			// Sets main properties
			pOverlay.SetLayerAutokill(iLayer, bAutoKill);
		}
		
		// Return on the success
		return iLayer;
	} 

	// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.sp#L836
	public bool IsPlayingGesture(char[] sAnim)    
	{ 
		return this.FindGestureLayer(sAnim) != -1 ? true : false; 
	} 

	// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/game/server/BaseAnimatingOverlay.sp#L866
	public void RemoveGesture(char[] sAnim) 
	{ 
		// Validate layer
		int iLayer = this.FindGestureLayer(sAnim); 
		if (iLayer == -1) 
		{
			return; 
		}

		// Validate address
		CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
		if (pOverlay.isNull) 
		{
			return;
		}
		
		// Delete it !
		pOverlay.RemoveLayer(iLayer, 0.0, 0.0);
	}

	/*__________________________________________________________________________________________________*/

	public bool ValidTargetPlayer(int target, float vStart[3], float vEndPosition[3]) 
	{
		// Create the end-point trace
		TR_TraceRayFilter(vStart, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TurretFilter, this.Index); 
		
		// Validate any kind of collision along the trace ray
		bool bHit;
		if (!TR_DidHit() || TR_GetEntityIndex() == target) 
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
		TR_TraceRayFilter(vStart, vMid, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TurretFilter, this.Index); 
		
		// Validate collision
		if (TR_DidHit()) 
		{
			// Validate victim
			int victim = TR_GetEntityIndex();
			if (victim >= MaxClients || victim <= 0)
			{
				// Hack it lower a little bit
				// The eye position is not always within the hitboxes for a standing CS player 
				GetEyePosition(this.Enemy, vMid); 
				vMid[2] -= 5.0; 
			}
		}
	}
	
	public bool CanUpgrade() 
	{
		// Gets entity position
		static float vPosition[3];
		GetAbsOrigin(this.Index, vPosition); 
		
		// Initialize the hull vectors
		static const float vMins[3] = { -40.0, -40.0, 0.0   }; 
		static const float vMaxs[3] = {  40.0,  40.0, 72.0  }; 
		
		// Create array of entities
		ArrayList hList = new ArrayList();
		
		// Create the hull trace
		vPosition[2] += vMaxs[2];
		TR_EnumerateEntitiesHull(vPosition, vPosition, vMins, vMaxs, false, HullEnumerator, hList);

		// Is hit world only ?
		bool bHit;
		if (!hList.Length)
		{
			bHit = true;
		}
		
		// Return on success
		delete hList;
		return bHit;
	}
	
	public void EmitSound(int iIndex)
	{
		// Play sound
		ZP_EmitSoundToAll(gSoundShoot, iIndex, this.Index, SNDCHAN_STATIC, SNDLEVEL_DRYER);
	}
	
	public void FoundTarget(int target) 
	{     
		// Sets target index
		this.Enemy = target; 
		
		// Validate ammunition
		if (this.Ammo > 0 || (this.Rockets > 0 && this.UpgradeLevel == SENTRY_MODE_ROCKET))
		{
			this.EmitSound(GetRandomInt(SENTRY_SOUND_SPOT, SENTRY_SOUND_SPOT2));
		}
		
		// Gets the current game tick
		float flCurrentTime = GetGameTime();
		
		// Create a small delay
		float flDelay = SENTRY_BULLET_THINK;
		this.State = SENTRY_STATE_ATTACKING; 
		this.NextAttack = flCurrentTime + flDelay; 
		if (this.NextRocket < flCurrentTime) 
		{ 
			this.NextRocket = flCurrentTime + flDelay * 10.0; 
		} 
	}

	public bool FindTarget() 
	{ 
		// Initialize vectors
		static float vPosition[3]; static float vEnemy[3]; 
	
		// Loop through players within 1100 units (sentry range)
		this.GetGunPosition(vPosition); 

		// If we have an enemy get his minimum distance to check against
		int target = -1; int old = this.Enemy;
		float flMinDistance = SENTRY_BULLET_RANGE; float flOldDistance = MAX_FLOAT; float flNewDistance;

		// i = client index
		for (int i = 1; i <= MaxClients; i++) 
		{
			// Validate client
			if (!IsPlayerExist(i))
			{
				continue;
			}
	
			// Validate zombie
			if (!ZP_IsPlayerZombie(i))
			{
				continue;
			}

			// Validate visiblity
			if (UTIL_GetRenderColor(i, Color_Alpha) < SENTRY_ATTACK_VISIVILTY)
			{
				continue;
			}
			
			// Gets victim origin
			GetAbsOrigin(i, vEnemy);
			
			// Gets target distance
			flNewDistance = GetVectorDistance(vPosition, vEnemy);
			
			// Store the current target distance if we come across it 
			if (i == old) 
			{ 
				flOldDistance = flNewDistance; 
			} 
			
			// Check to see if the target is closer than the already validated target
			if (flNewDistance > flMinDistance) 
			{
				continue; 
			}
			
			// It is closer, check to see if the target is valid
			if (this.ValidTargetPlayer(i, vPosition, vEnemy)) 
			{ 
				flMinDistance = flNewDistance; 
				target = i; 
			}
		}

#if defined SENTRY_ATTACK_NPC
		// Initialize name char
		static char sClassname[SMALL_LINE_LENGTH];
		
		// If we already have a target, don't check objects
		if (target == -1) 
		{
			// i = entity index
			int MaxEntities = GetMaxEntities();
			for (int i = MaxClients; i <= MaxEntities; i++)
			{
				// Validate entity
				if (IsValidEdict(i))
				{
					// Gets valid edict classname
					GetEdictClassname(i, sClassname, sizeof(sClassname));

					// If entity is a chicken
					if (sClassname[0] == 'c' && sClassname[1] == 'h') // chicken
					{
					}
					// If entity is a npc
					else if (sClassname[0] == 'm' && sClassname[8] == 'g') // monster_generic
					{
						// Skip turrets
						if (IsEntityTurret(i))
						{
							continue;
						}
					}
					// Otherwise skip
					else continue;
				
					// Gets victim origin
					GetAbsOrigin(i, vEnemy);
					
					// Gets target distance
					flNewDistance = GetVectorDistance(vPosition, vEnemy);
					
					// Store the current target distance if we come across it 
					if (i == old) 
					{ 
						flOldDistance = flNewDistance; 
					} 
					
					// Check to see if the target is closer than the already validated target
					if (flNewDistance > flMinDistance) 
					{
						continue; 
					}
					
					// It is closer, check to see if the target is valid
					if (this.ValidTargetPlayer(i, vPosition, vEnemy)) 
					{ 
						flMinDistance = flNewDistance; 
						target = i; 
					}
				}
			}
		}
#endif
		
		// We have a target
		if (target != -1) 
		{ 
			// Is it new target ?
			if (target != old) 
			{ 
				// flMinDistance is the new target's distance 
				// flOldDistance is the old target's distance 
				// Don't switch unless the new target is closer by some percentage 
				if (flMinDistance < (flOldDistance * 0.75)) 
				{ 
					this.FoundTarget(target); 
				} 
			}
			
			// Target was found
			return true; 
		} 
		
		// Target was missed
		return false; 
	}

	public bool Move() 
	{ 
		// Initialize variables
		bool bMoved = false; 
		float flDelay = SENTRY_BULLET_THINK;
		float flTurnRate = SENTRY_BULLET_TURN; 
		
		// Start it rotating
		static float vGoal[3]; static float vCurrent[3];
		this.GetGoalAngles(vGoal); 
		this.GetCurAngles(vCurrent);
		
		// Any x movement? 
		if (vCurrent[0] != vGoal[0]) 
		{ 
			float flDir = vGoal[0] > vCurrent[0] ? 1.0 : -1.0 ; 
			vCurrent[0] += flDelay * (flTurnRate * 5) * flDir; 
	 
			// if we started below the goal, and now we're past, peg to goal 
			if (flDir == 1) 
			{ 
				if (vCurrent[0] > vGoal[0]) 
					vCurrent[0] = vGoal[0]; 
			}  
			else 
			{ 
				if (vCurrent[0] < vGoal[0]) 
					vCurrent[0] = vGoal[0]; 
			} 
	 
			this.SetPoseParameter(ZP_LookupPoseParameter(this.Index, "aim_pitch"), -50.0, 50.0, -vCurrent[0]); 
			bMoved = true; 
		} 
		 
		// Any y movement?  
		if (vCurrent[1] != vGoal[1]) 
		{ 
			float flDir = vGoal[1] > vCurrent[1] ? 1.0 : -1.0 ; 
			float flNewDistance = FloatAbs(vGoal[1] - vCurrent[1]); 
			bool bReversed = false; 
	 
			if (flNewDistance > 180.0) 
			{ 
				flNewDistance = 360.0 - flNewDistance; 
				flDir = -flDir; 
				bReversed = true; 
			} 
	 
			// Target not exist
			if (this.Enemy == -1) 
			{ 
				if (flNewDistance > 30.0) 
				{ 
					if (this.TurnRate < flTurnRate * 10.0) 
						this.TurnRate += flTurnRate; 
				} 
				else 
				{ 
					// Slow down 
					if (this.TurnRate > (flTurnRate * 5.0)) 
						this.TurnRate -= flTurnRate; 
				} 
			} 
			else 
			{ 
				// When tracking enemies, move faster and don't slow 
				if (flNewDistance > 30.0) 
				{ 
					if (this.TurnRate < flTurnRate * 30.0) 
						this.TurnRate += flTurnRate * 3.0; 
				} 
			} 
	 
			vCurrent[1] += flDelay * this.TurnRate * flDir; 
	 
			// if we passed over the goal, peg right to it now 
			if (flDir == -1) 
			{ 
				if ((bReversed == false && vGoal[1] > vCurrent[1]) || 
					(bReversed == true  && vGoal[1] < vCurrent[1])) 
				{ 
					vCurrent[1] = vGoal[1]; 
				} 
			}  
			else 
			{ 
				if ((bReversed == false && vGoal[1] < vCurrent[1]) || 
					(bReversed == true  && vGoal[1] > vCurrent[1])) 
				{ 
					vCurrent[1] = vGoal[1]; 
				} 
			} 
	 
			if (vCurrent[1] < 0.0) 
			{ 
				vCurrent[1] += 360.0; 
			} 
			else if (vCurrent[1] >= 360.0) 
			{ 
				vCurrent[1] -= 360.0; 
			} 
	 
			if (flNewDistance < (flDelay * 0.5 * flTurnRate)) 
			{ 
				vCurrent[1] = vGoal[1]; 
			} 
	 
			// Gets angles
			static float vAngle[3]; 
			this.GetAbsAngles(vAngle); 
			
			float flYaw = AngleNormalize(vCurrent[1] - vAngle[1]); 
			this.SetPoseParameter(ZP_LookupPoseParameter(this.Index, "aim_yaw"), -180.0, 180.0, -flYaw); 
			this.SetCurAngles(vCurrent);
			bMoved = true; 
		} 
	 
		if (!bMoved || this.TurnRate <= 0.0) 
		{ 
			this.TurnRate = flTurnRate * 5.0; 
		} 
	 
		return bMoved; 
	}
	
	public void Rocket(float vPosition[3], float vAngle[3], float vVelocity[3])
	{
		// Initialize buffer char
		static char sBuffer[SMALL_LINE_LENGTH];
	
		// Create a rocket entity
		int entity = UTIL_CreateProjectile(vPosition, vAngle, "models/weapons/cso/bazooka/w_bazooka_projectile.mdl");

		// Validate entity
		if (entity != -1)
		{
			// Push the rocket
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);

			// Sets an entity color
			UTIL_SetRenderColor(entity, Color_Alpha, 0);
			AcceptEntityInput(entity, "DisableShadow"); /// Prevents the entity from receiving shadows
			
			// Sets name for entity
			SetEntPropString(entity, Prop_Data, "m_iGlobalname", "rocket");

			// Create a prop_dynamic_override entity
			int rocket = UTIL_CreateDynamic("rocket", NULL_VECTOR, NULL_VECTOR, "models/buildables/sentry3_rockets.mdl", "idle", false);

			// Validate entity
			if (rocket != -1)
			{
				// Sets parent to the entity
				SetVariantString("!activator");
				AcceptEntityInput(rocket, "SetParent", entity, rocket);

				// Sets attachment to the projectile
				SetVariantString("1"); 
				AcceptEntityInput(rocket, "SetParentAttachment", entity, rocket);
			
				// Create effects
				for (int i = 1; i <= 4; i++)
				{
					FormatEx(sBuffer, sizeof(sBuffer), "rocket%d", i);
					UTIL_CreateParticle(rocket, _, _, sBuffer, "sentry_rocket", SENTRY_ROCKET_EFFECT_TIME);
				}
			}

			// Sets gravity
			SetEntPropFloat(entity, Prop_Data, "m_flGravity", SENTRY_ROCKET_GRAVITY);
			
			// Sets weapon ID
			SetEntProp(entity, Prop_Data, "m_iHammerID", gWeapon);

			// Create touch hook
			SDKHook(entity, SDKHook_Touch, RocketTouchHook);
			
			// Create timer to kill
			CreateTimer(4.0, RocketExploadHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		// Make an effect
		this.Body = 1;
		
		// Initialize flags char
		FormatEx(sBuffer, sizeof(sBuffer), "OnUser2 !self:SetBodyGroup:0:%f:1", SENTRY_ROCKET_RELOAD);
		
		// Sets modified flags on the entity
		SetVariantString(sBuffer);
		AcceptEntityInput(this.Index, "AddOutput");
		AcceptEntityInput(this.Index, "FireUser2"); /// Reset body
	}
	
	public void Shot(float vPosition[3], float vDirection[3], char[] sAttach) 
	{ 
		// Initialize vectors
		static float vEndPosition[3]; static float vVelocity[3]; static float vSpeed[3];
		
		// Calculate and store endpoint
		ScaleVector(vDirection, SENTRY_BULLET_DISTANCE);
		AddVectors(vDirection, vPosition, vEndPosition);
		
		// Sentryguns are perfectly accurate, but this doesn't look good for tracers
		// Add a little noise to them, but not enough so that it looks like they're missing
		vEndPosition[0] += GetRandomFloat(-10.0, 10.0); 
		vEndPosition[1] += GetRandomFloat(-10.0, 10.0); 
		vEndPosition[2] += GetRandomFloat(-10.0, 10.0); 
		
		// Fire a bullet 
		TR_TraceRayFilter(vPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TurretFilter, this.Index); 

		// Validate collisions
		if (TR_DidHit())
		{
			// Returns the collision position of a trace result
			TR_GetEndPosition(vEndPosition); 

			// Bullet tracer
			UTIL_CreateTracer(this.Index, sAttach, "weapon_tracers_50cal", vEndPosition, 0.1);

			// Gets victim index
			int victim = TR_GetEntityIndex();
			
			// Is hit world ?
			if (victim < 1)
			{
				// Create a decal effect
				TE_Start("BSP Decal");
				TE_WriteVector("m_vecOrigin", vEndPosition);
				TE_WriteNum("m_nEntity", victim);
				TE_WriteNum("m_nIndex", gDecal[GetRandomInt(0, 4)]);
				TE_SendToAll();
			}
			else
			{
				// Create the damage for victims
				UTIL_CreateDamage(_, vEndPosition, this.Index, SENTRY_BULLET_DAMAGE, SENTRY_BULLET_RADIUS, DMG_BULLET);
		
				// Validate victim
				if (IsPlayerExist(victim) && ZP_IsPlayerZombie(victim))
				{
					// Validate force
					float flForce = ZP_GetClassKnockBack(ZP_GetClientClass(victim)) * ZP_GetWeaponKnockBack(gWeapon); 
					if (flForce <= 0.0)
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
						ScaleVector(vVelocity, flForce);
						
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
						if (flForce > 100.0) flForce = 100.0;
						else if (flForce <= 0.0) return;
				
						// Apply the stamina-based slowdown
						SetEntPropFloat(victim, Prop_Send, "m_flStamina", flForce);
					}
				}
			}
		}
	}

	public void Fire() 
	{ 
		// Initialize variables
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vEnemy[3];
		float flSpeed = SENTRY_BULLET_SPEED; 
		float flCurrentTime = GetGameTime();
		
		// Level 3 Turrets fire rockets every 3 seconds
		if (this.UpgradeLevel == SENTRY_MODE_ROCKET && this.NextRocket < flCurrentTime)
		{
			if (this.Rockets > 0) 
			{ 
				// Add layers
				if (!this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
				{
					this.AddGesture("ACT_RANGE_ATTACK2");
				}
		
				// Alternate between the 1 rocket launcher ports
				///ZP_GetAttachment(this.Index, "rocket", vPosition, vVelocity);  // Not work correctly
				this.GetLauncherPosition(vPosition); 

				// Calculate a velocity
				GetCenterOrigin(this.Enemy, vEnemy); 
				MakeVectorFromPoints(vPosition, vEnemy, vAngle);
				NormalizeVector(vAngle, vAngle); 
				GetVectorAngles(vAngle, vAngle); 
				GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vVelocity, vVelocity);
				ScaleVector(vVelocity, SENTRY_ROCKET_SPEED);

				// Create a rocket
				this.EmitSound(SENTRY_MODE_ROCKET); 
				this.Rocket(vPosition, vAngle, vVelocity); 

				// Sets delay for the next rocket
				this.NextRocket = flCurrentTime + SENTRY_ROCKET_DELAY;
				this.Rockets--;
			}
			else
			{
				// Kill layers
				/*if (this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
				{ 
					this.RemoveGesture("ACT_RANGE_ATTACK2"); 
				}*/
				
				// Out of rockets
				this.NextRocket = MAX_FLOAT;
			}
		}
		
		// All turrets fire shells 
		if (this.Ammo > 0) 
		{ 
			// If turret is upgraded remove low gesture
			if (this.UpgradeLevel > SENTRY_MODE_NORMAL) 
			{
				if (this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
				{ 
					this.RemoveGesture("ACT_RANGE_ATTACK1_LOW"); 
				}
			}
			
			// Add layers
			if (!this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
			{
				this.AddGesture("ACT_RANGE_ATTACK1"); 
			}

			// Play sound
			switch (this.UpgradeLevel) 
			{ 
				case SENTRY_MODE_NORMAL    : this.EmitSound(GetRandomInt(0, 1) ? SENTRY_SOUND_SHOOT : SENTRY_SOUND_SHOOT4); 
				case SENTRY_MODE_AGRESSIVE : this.EmitSound(SENTRY_SOUND_SHOOT2); 
				case SENTRY_MODE_ROCKET    : this.EmitSound(SENTRY_SOUND_SHOOT3); 
			}
			
			// Alternate between the 3 shot ports
			static char sAttach[SMALL_LINE_LENGTH];
			strcopy(sAttach, sizeof(sAttach), (this.UpgradeLevel == SENTRY_MODE_NORMAL) ? "muzzle" : ((this.Ammo & 1) ? "muzzle_l" : "muzzle_r"));
			ZP_GetAttachment(this.Index, sAttach, vPosition, vVelocity);
			
			// Calculate an angle
			this.SelectTargetPoint(vPosition, vEnemy);
			MakeVectorFromPoints(vPosition, vEnemy, vAngle);
			NormalizeVector(vAngle, vAngle); 

			// Create a bullet
			static char sMuzzle[NORMAL_LINE_LENGTH];
			this.Shot(vPosition, vAngle, sAttach); 
			ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
			UTIL_CreateParticle(this.Index, _, _, sAttach, sMuzzle, flSpeed);

			// Sets delay for the next attack
			if (this.UpgradeLevel > SENTRY_MODE_NORMAL) flSpeed *= 0.5;
			this.NextAttack = flCurrentTime + flSpeed;
			this.Ammo--;
			this.Lock = false;
		} 
		else 
		{
			// If turret is upgraded add low gesture
			/*if (this.UpgradeLevel > SENTRY_MODE_NORMAL) 
			{
				if (!this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
				{ 
					this.RemoveGesture("ACT_RANGE_ATTACK1"); 
					this.AddGesture("ACT_RANGE_ATTACK1_LOW");
					this.EmitSound(SENTRY_SOUND_FINISH);
				} 
			}*/

			// Out of ammo, play a click 
			this.EmitSound(SENTRY_SOUND_EMPTY);
			this.NextAttack = MAX_FLOAT; 
	   }
	}
	
	public void Upgrade()
	{
		// Gets upgrade for the current mode
		static char sModel[PLATFORM_LINE_LENGTH];
		switch (this.UpgradeLevel)
		{
			case SENTRY_MODE_NORMAL :    strcopy(sModel, sizeof(sModel), "models/buildables/sentry2_heavy.mdl");
			case SENTRY_MODE_AGRESSIVE : strcopy(sModel, sizeof(sModel), "models/buildables/sentry3_heavy.mdl");
			case SENTRY_MODE_ROCKET :    return;
		} 
		
		// Destroy think hook
		SDKUnhook(this.Index, SDKHook_ThinkPost, SentryThinkHook);
		
		// Gets paremeter indexes
		int iYaw = ZP_LookupPoseParameter(this.Index, "aim_yaw"); 
		int iPitch = ZP_LookupPoseParameter(this.Index, "aim_pitch");
		
		// Gets entity position
		static float vPosition[3];
		GetAbsOrigin(this.Index, vPosition);
		
		// Gets entity angle
		static float vAngle[3]; 
		this.GetAbsAngles(vAngle);

		// Create a upgradable entity
		int upgrade = UTIL_CreateDynamic("upgrade", vPosition, vAngle, sModel, "upgrade");

		// Validate entity
		if (upgrade != -1)
		{
			// Sets effects
			SetEntProp(upgrade, Prop_Send, "m_nSkin", this.Skin);
			SetEntProp(upgrade, Prop_Send, "m_nBody", 2);
			
			// Sets owner for the entity
			SetEntPropEnt(upgrade, Prop_Data, "m_hOwnerEntity", this.Index); 
			
			// Play sound
			ZP_EmitSoundToAll(gSoundUpgrade, 2, upgrade, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
			
			// Sets upgrade for the entity
			this.UpgradeModel = upgrade;
			
			// Sets same pose parameters
			SetEntPropFloat(upgrade, Prop_Send, "m_flPoseParameter", GetEntPropFloat(this.Index, Prop_Send, "m_flPoseParameter", iYaw), iYaw); 
			SetEntPropFloat(upgrade, Prop_Send, "m_flPoseParameter", GetEntPropFloat(this.Index, Prop_Send, "m_flPoseParameter", iPitch), iPitch); 
			
			// Create timer to activate
			CreateTimer(1.5, SentryActivateHook, EntIndexToEntRef(upgrade), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		// Update variables
		this.UpgradeLevel++;
		this.Lock = true;

		// Gets model for the current mode
		switch (this.UpgradeLevel)
		{
			case SENTRY_MODE_AGRESSIVE : strcopy(sModel, sizeof(sModel), "models/buildables/sentry2.mdl");
			case SENTRY_MODE_ROCKET :    strcopy(sModel, sizeof(sModel), "models/buildables/sentry3_fix2.mdl");
		}
		
		// Sets model
		SetEntityModel(this.Index, sModel);

		// Make model invisible
		UTIL_SetRenderColor(this.Index, Color_Alpha, 0);
	}
	
	public void Rotate() 
	{ 
		// If we're playing a fire gesture, stop it 
		if (this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
		{ 
			this.RemoveGesture("ACT_RANGE_ATTACK1"); 
		} 
		/*if (this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
		{ 
			this.RemoveGesture("ACT_RANGE_ATTACK1_LOW"); 
		}
		if (this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
		{ 
			this.RemoveGesture("ACT_RANGE_ATTACK2"); 
		}*/
		
		// Upgrade sentry
		if (this.UpgradeState != this.UpgradeLevel && this.CanUpgrade())
		{
			this.Upgrade();
			return;
		}
	 
		// Look for a target 
		if (this.FindTarget()) 
		{ 
			return; 
		} 
		
		// If turret is upgraded add low gesture
		if (this.UpgradeLevel > SENTRY_MODE_NORMAL) 
		{ 
			if (!this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW") && !this.Lock) 
			{ 
				this.AddGesture("ACT_RANGE_ATTACK1_LOW");
				this.EmitSound(SENTRY_SOUND_FINISH);
				this.Lock = true;
			} 
		}
	 
		// Rotate a bit
		if (!this.Move()) 
		{
			// Gets the current game tick
			float flCurrentTime = GetGameTime();
		
			// Validate delay
			if (this.NextSound <= flCurrentTime)
			{
				// Play sound
				switch (this.UpgradeLevel) 
				{ 
					case SENTRY_MODE_NORMAL    : this.EmitSound(SENTRY_SOUND_SCAN); 
					case SENTRY_MODE_AGRESSIVE : this.EmitSound(SENTRY_SOUND_SCAN2); 
					case SENTRY_MODE_ROCKET    : this.EmitSound(SENTRY_SOUND_SCAN3); 
				}
				this.NextSound = flCurrentTime + 0.2;
			}
			
			// Start it rotating
			static float vGoal[3]; 
			this.GetGoalAngles(vGoal);
	 
			// Switch rotation direction 
			if (this.TurningRight) 
			{ 
				this.TurningRight = false; 
				vGoal[1] = float(this.LeftBound); 
			} 
			else 
			{ 
				this.TurningRight = true; 
				vGoal[1] = float(this.RightBound); 
			} 

			// Randomly look up and down a bit 
			if (GetRandomFloat(0.0, 1.0) < 0.3) 
			{ 
				vGoal[0] = GetRandomFloat(-10.0, 10.0); 
			}
			
			// Store angles
			this.SetGoalAngles(vGoal);
		}
	} 

	public void Attack() 
	{
		// Validate target
		if (!this.FindTarget()) 
		{
			this.State = SENTRY_STATE_SEARCHING;
			return; 
		} 
	 
		// Initialize vectors
		static float vMid[3]; static float vEnemy[3]; static float vDirection[3]; static float vAngle[3]; 
	 
		// Track the enemy 
		GetCenterOrigin(this.Index, vMid); 
		this.SelectTargetPoint(vMid, vEnemy);
		MakeVectorFromPoints(vMid, vEnemy, vDirection);
		GetVectorAngles(vDirection, vAngle); 
	 
		// Calculate angles
		vAngle[1] = AngleMod(vAngle[1]); 
		if (vAngle[0] < -180.0) 
			vAngle[0] += 360.0; 
		if (vAngle[0] > 180.0) 
			vAngle[0] -= 360.0; 
	 
		// now all numbers should be in [1...360] 
		// pin to turret limitations to [-50...50] 
		if (vAngle[0] > 50.0) 
			vAngle[0] = 50.0; 
		else if (vAngle[0] < -50.0) 
			vAngle[0] = -50.0; 

		// Start it rotating
		static float vGoal[3]; static float vCurrent[3]; static float vRange[3]; 
		this.GetGoalAngles(vGoal); 
		this.GetCurAngles(vCurrent);
		vGoal[1] = vAngle[1]; 
		vGoal[0] = vAngle[0]; 
		this.SetGoalAngles(vGoal);     
		this.Move(); 
		
		// Gets vector from the given starting and ending points
		MakeVectorFromPoints(vCurrent, vGoal, vRange);
		
		// Gets the current game tick
		float flCurrentTime = GetGameTime();
		
		// Fire on the target if it's within 10 units of being aimed right at it 
		if (this.NextAttack <= flCurrentTime && GetVectorLength(vRange) <= 10.0) 
		{ 
			this.Fire(); 
		} 
		 
		// Validate range
		if (GetVectorLength(vRange) > 10.0) 
		{ 
			// If we're playing a fire gesture, stop it 
			if (this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
			{ 
				this.RemoveGesture("ACT_RANGE_ATTACK1"); 
			} 
			
			// If turret is upgraded add low gesture
			if (this.UpgradeLevel > SENTRY_MODE_NORMAL) 
			{ 
				if (!this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW") && !this.Lock) 
				{ 
					this.AddGesture("ACT_RANGE_ATTACK1_LOW");
					this.EmitSound(SENTRY_SOUND_FINISH);
					this.Lock = true;
				} 
			}
		}
	}
	
	public void Death()
	{
		// Initialize vectors
		static float vPosition[3]; static float vGib[3]; float vShoot[3];

		// Emit sound
		EmitSoundToAll("survival/turret_death_01.wav", this.Index, SNDCHAN_STATIC, SNDLEVEL_FRIDGE);
		
		// Gets entity position
		GetAbsOrigin(this.Index, vPosition);
		
		// Create an explosion effect
		UTIL_CreateParticle(this.Index, vPosition, _, _, "explosion_hegrenade_interior", 0.1);
		
		// Create a breaked drone effect
		static char sBuffer[NORMAL_LINE_LENGTH];
		for (int x = 0; x <= 3; x++)
		{
			// Find gib positions
			vShoot[1] += 90.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); switch (x)
			{
				case 0 : strcopy(sBuffer, sizeof(sBuffer), (this.UpgradeLevel == SENTRY_MODE_ROCKET) ? "models/buildables/gibs/sentry3_gib1.mdl" : (this.UpgradeLevel ? "models/buildables/gibs/sentry2_gib1.mdl" : "models/buildables/gibs/sentry1_gib1.mdl"));
				case 1 : strcopy(sBuffer, sizeof(sBuffer), this.UpgradeLevel ? "models/buildables/gibs/sentry2_gib2.mdl" : "models/buildables/gibs/sentry1_gib2.mdl");
				case 2 : strcopy(sBuffer, sizeof(sBuffer), this.UpgradeLevel ? "models/buildables/gibs/sentry2_gib3.mdl" : "models/buildables/gibs/sentry1_gib3.mdl");
				case 3 : strcopy(sBuffer, sizeof(sBuffer), this.UpgradeLevel ? "models/buildables/gibs/sentry2_gib4.mdl" : "models/buildables/gibs/sentry1_gib4.mdl");
			}

			// Create gibs
			UTIL_CreateShooter(this.Index, "build_point_0", _, MAT_METAL, this.Skin, sBuffer, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
		}
		
		// Gets upgradable entity
		int entity = this.UpgradeModel; 
		
		// Validate entity
		if (entity != -1)
		{
			// Kill entity
			AcceptEntityInput(entity, "Kill");
		}

		// Kill after some duration
		UTIL_RemoveEntity(this.Index, 0.1);
	}
};

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, float flCurrentTime)
{
	//#pragma unused client, weapon, flCurrentTime

	// Kill an effect
	Weapon_OnCreateEffect(client, weapon, EFFECT_KILL);
}

void Weapon_OnIdle(int client, int weapon, float flCurrentTime)
{
	//#pragma unused client, weapon, flCurrentTime

	// Update an effect
	Weapon_OnCreateEffect(client, weapon, EFFECT_UPDATE);
	
	// Gets viewmodel index
	int entity = ZP_GetClientViewModel(client, true);
	
	// Validate model 
	if (entity != -1)
	{
		// Sets skin index
		SetEntProp(entity, Prop_Send, "m_nSkin", GetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount"));
	}
	
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

void Weapon_OnDeploy(int client, int weapon, float flCurrentTime)
{
	//#pragma unused client, weapon, flCurrentTime
	
	/// Block the real attack
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);

	// Create an effect
	Weapon_OnCreateEffect(client, weapon, EFFECT_CREATE);
	
	// Sets draw animation
	ZP_SetWeaponAnimation(client, ANIM_DRAW);

	// Sets next attack time
	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
	
	// Show message
	SetGlobalTransTarget(client);
	PrintHintText(client, "%t", "rotate info");
}

void Weapon_OnDrop(int client, int weapon, float flCurrentTime)
{
	//#pragma unused client, weapon, flCurrentTime

	// Sets skin index
	SetEntProp(weapon, Prop_Send, "m_nSkin", GetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount"));
	
	// Kill an effect
	Weapon_OnCreateEffect(client, weapon, EFFECT_KILL);
}

void Weapon_OnPrimaryAttack(int client, int weapon, float flCurrentTime)
{
	//#pragma unused client, weapon, flCurrentTime

	// Place an effect
	Weapon_OnCreateEffect(client, weapon, EFFECT_PLACE);
}

void Weapon_OnSecondaryAttack(int client, int weapon, float flCurrentTime)
{
	//#pragma unused client, weapon, flCurrentTime

	// Gets rotation angle
	float flAngle = GetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle") + 0.5;
	if (flAngle > 360.0) flAngle = 0.0;

	// Sets new rotation angle
	SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", flAngle);
}

void Weapon_OnCreateEffect(int client, int weapon, int iMode)
{
	//#pragma unused client, weapon, iMode

	// Gets effect index
	int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity");

	// Go to mode
	switch (iMode)
	{
		case EFFECT_CREATE :
		{
			// Validate entity 
			if (entity != -1)
			{
				return;
			}
		
			// Creates a model
			entity = UTIL_CreateDynamic("plan", NULL_VECTOR, NULL_VECTOR, "models/buildables/sentry1_blueprint.mdl", "reject");
			
			// Validate entity
			if (entity != -1)
			{
				// Sets effect index
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
			}
		}

		case EFFECT_KILL : 
		{
			// Validate entity 
			if (entity == -1)
			{
				return;
			}
			
			// Remove entity from the world
			AcceptEntityInput(entity, "Kill"); 
		}
		
		default :
		{
			// Validate entity 
			if (entity == -1)
			{
				return;
			}
			
			// Initialize vectors
			static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; bool bHit;
	
			// Gets trace line
			GetClientEyePosition(client, vPosition);
			ZP_GetPlayerGunPosition(client, 120.0, 0.0, 0.0, vEndPosition);

			// Create the end-point trace
			TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

			// Returns the collision position/normal of a trace result
			TR_GetEndPosition(vPosition);
			TR_GetPlaneNormal(null, vAngle);
			
			// Validate water
			if (GetEntProp(client, Prop_Data, "m_nWaterLevel") != WLEVEL_CSGO_FULL)
			{
				// Is hit world ?
				if (TR_DidHit() && TR_GetEntityIndex() < 1)
				{
					bHit = true;
				}
				else
				{
					// Move to the bottom
					ZP_GetPlayerGunPosition(client, 120.0, 0.0, -200.0, vPosition);
			
					// Create the end-point trace
					TR_TraceRayFilter(vEndPosition, vPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);
					
					// Is hit world ?
					if (TR_DidHit() && TR_GetEntityIndex() < 1)
					{
						bHit = true;
					}
					
					// Returns the collision position/normal of a trace result
					TR_GetEndPosition(vPosition);
					TR_GetPlaneNormal(null, vAngle);
				}
			}

			// Adds rotation angle
			vAngle[1] += GetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle");
			
			// Teleport the entity
			TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);
			
			// Validate hit
			if (bHit)
			{
				// Initialize the hull vectors
				static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
				static const float vMaxs[3] = {  20.0,  20.0, 72.0  }; 
				
				// Create the hull trace
				vPosition[2] += vMaxs[2] / 2.0; /// Move center of hull upward
				TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
				
				// Validate no collisions
				if (!TR_DidHit())
				{
					// Validate place mode
					if (iMode == EFFECT_PLACE)
					{
						// Create a dronegun entity
						SentryGun(client, vPosition, vAngle, 
								  GetEntProp(weapon, Prop_Data, "m_iHealth"), 
								  GetEntProp(weapon, Prop_Data, "m_iMaxHealth"), 
								  GetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount"), 
								  GetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount"), 
								  GetEntProp(weapon, Prop_Data, "m_iWeaponModule"));
						
						// Forces a player to remove weapon
						ZP_RemoveWeapon(client, weapon);
						
						// Remove entity from the world
						AcceptEntityInput(entity, "Kill");
						
						// Show message
						SetGlobalTransTarget(client);
						PrintHintText(client, "%t", "control info");
					}
					else
					{
						// Sets success anim
						SetVariantString("idle");
						AcceptEntityInput(entity, "SetAnimation");
					}
				}
				else
				{
					// Sets fail anim
					SetVariantString("reject");
					AcceptEntityInput(entity, "SetAnimation");
				}
			}
		}
	}
}

bool Weapon_OnPickupTurret(int client, int entity, float flCurrentTime)
{
	//#pragma unused client, entity, flCurrentTime

	// Initialize vectors
	static float vPosition[3]; static float vEndPosition[3]; bool bHit;
	
	// Gets trace line
	GetClientEyePosition(client, vPosition);
	ZP_GetPlayerGunPosition(client, 80.0, 0.0, 0.0, vEndPosition);

	// Create the end-point trace
	TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

	// Validate collisions
	if (!TR_DidHit())
	{
		// Initialize the hull vectors
		static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
		static const float vMaxs[3] = {  20.0,  20.0, 72.0  }; 
		
		// Create the hull trace
		TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SOLID, ClientFilter);
	}
	
	// Validate collisions
	if (TR_DidHit())
	{
		// Gets entity index
		entity = TR_GetEntityIndex();

		// Validate entity
		if (IsEntityTurret(entity))
		{
			// Gets object methods
			SentryGun sentry = view_as<SentryGun>(entity); 
	
			// Validate owner
			if (sentry.Owner == client)
			{
				// Give item and select it
				int weapon = ZP_GiveClientWeapon(client, gWeapon);
				
				// Valdiate weapon
				if (weapon != -1)
				{
					// Sets variables
					SetEntProp(weapon, Prop_Data, "m_iHealth", sentry.Health);
					SetEntProp(weapon, Prop_Data, "m_iMaxHealth", sentry.Ammo);
					SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", sentry.Rockets);
					SetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount", sentry.Skin);
					SetEntProp(weapon, Prop_Data, "m_iWeaponModule", sentry.UpgradeLevel);
				
					// Gets upgradable entity
					int upgrade = sentry.UpgradeModel; 

					// Validate entity
					if (upgrade != -1)
					{
						// Kill entity
						AcceptEntityInput(upgrade, "Kill");
					}
					
					// Kill entity
					AcceptEntityInput(entity, "Kill");
					
					// Return on the success
					bHit = true;
				}
			}
		}
	}

	// Return on success
	return bHit;
}

bool Weapon_OnMenuTurret(int client, int entity, float flCurrentTime)
{
	//#pragma unused client, entity, flCurrentTime

	// Initialize vectors
	static float vPosition[3]; static float vEndPosition[3]; bool bHit;
	
	// Gets trace line
	GetClientEyePosition(client, vPosition);
	ZP_GetPlayerGunPosition(client, 80.0, 0.0, 0.0, vEndPosition);

	// Create the end-point trace
	TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

	// Validate collisions
	if (!TR_DidHit())
	{
		// Initialize the hull vectors
		static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
		static const float vMaxs[3] = {  20.0,  20.0, 72.0  }; 
		
		// Create the hull trace
		TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SOLID, ClientFilter);
	}
	
	// Validate collisions
	if (TR_DidHit())
	{
		// Gets entity index
		entity = TR_GetEntityIndex();

		// Validate entity
		if (IsEntityTurret(entity))
		{
			// Gets object methods
			SentryGun sentry = view_as<SentryGun>(entity); 
	
			// Validate owner
			if (sentry.Owner == client)
			{
				// Open menu
				SentryMenu(client, entity);
				
				// Return on the success
				bHit = true;
			}
		}
	}
	
	// Return on success
	return bHit;
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
		SetEntProp(weapon, Prop_Data, "m_iMaxHealth", ZP_GetWeaponAmmo(gWeapon));
		SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", ZP_GetWeaponAmmunition(gWeapon));
		SetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount", GetRandomInt(0, 1));
		SetEntProp(weapon, Prop_Data, "m_iWeaponModule", SENTRY_MODE_NORMAL);
		SetEntPropFloat(weapon, Prop_Data, "m_flUseLookAtAngle", 0.0);
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
		// Call event
		_call.Holster(client, weapon);
	}
}

/**
 * @brief Called on drop of a weapon.
 *
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponDrop(int weapon, int weaponID)
{
	// Validate custom weapon
	if (weaponID == gWeapon)
	{
		// Call event
		_call.Drop(-1, weapon);
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

		// Button secondary attack press
		if (iButtons & IN_ATTACK2)
		{
			// Call event
			_call.SecondaryAttack(client, weapon); 
			iButtons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
	}
	else
	{
		// Button use press
		if (iButtons & IN_USE && !(iLastButtons & IN_USE))
		{
			// Validate no weapon
			if (ZP_IsPlayerHuman(client) && ZP_IsPlayerHasWeapon(client, gWeapon) == -1)
			{
				// Call event
				int entity; /// Initialize index
				if (_call.PickupTurret(client, entity))
				{
					iButtons &= (~IN_USE);
					return Plugin_Changed;
				}
			}
		}
	}

	// Allow button
	return Plugin_Continue;
}

/**
 * @brief Called before show a main menu.
 * 
 * @param client            The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block showing. Anything else
 *                              (like Plugin_Continue) to allow showing.
**/
public Action ZP_OnClientValidateButton(int client)
{
	// Validate human
	if (ZP_IsPlayerHuman(client))
	{
		// Call event
		int entity; /// Initialize index
		if (_call.MenuTurret(client, entity))
		{
			// Block showing menu
			return Plugin_Handled;
		}
	}
	
	// Allow menu
	return Plugin_Continue;
}

//**********************************************
//* Item (drone) hooks.                        *
//**********************************************

/**
 * @brief Sentry think hook.
 *
 * @param entity            The entity index.
 **/
public void SentryThinkHook(int entity) 
{
	// Animate entity
	SDKCall(hSDKCallStudioFrameAdvance, entity); 
	
	// Gets object methods
	SentryGun sentry = view_as<SentryGun>(entity); 
	
	// Sets state
	switch (sentry.State)
	{ 
		case SENTRY_STATE_SEARCHING : sentry.Rotate();
		case SENTRY_STATE_ATTACKING : sentry.Attack();
	}
}

/**
 * @brief Timer for a sentry activation.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action SentryActivateHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Gets sentry index
		int sentry = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	  
		// validate sentry
		if (sentry != -1)
		{
			// Reset visibility
			UTIL_SetRenderColor(sentry, Color_Alpha, 255);
			
			// Create think hook
			SDKHook(sentry, SDKHook_ThinkPost, SentryThinkHook);
		}
		
		// Remove the entity from the world
		AcceptEntityInput(entity, "Kill");
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Sentry damage hook.
 * 
 * @param entity            The entity index.
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param damage            The amount of damage inflicted.
 * @param damageBits        The type of damage inflicted.
 **/
public Action SentryDamageHook(int entity, int &attacker, int &inflictor, float &flDamage, int &damageBits)
{
	// Validate attacker
	if (IsPlayerExist(attacker))
	{
		// Validate zombie
		if (ZP_IsPlayerZombie(attacker))
		{
			// Gets object methods
			SentryGun sentry = view_as<SentryGun>(entity); 
	
			// Calculate the damage
			int iHealth = sentry.Health - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

			// Destroy entity
			if (!iHealth)
			{
				// Destroy damage/think hook
				SDKUnhook(entity, SDKHook_OnTakeDamage, SentryDamageHook);
				SDKUnhook(entity, SDKHook_ThinkPost, SentryThinkHook);
				
				// Call removal
				sentry.Death();
			}
			else
			{
				// Apply damage
				sentry.Health = iHealth; 
				
				// Emit sound
				switch (GetRandomInt(0, 2))
				{
					case 0 : EmitSoundToAll("survival/turret_takesdamage_01.wav", entity, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
					case 1 : EmitSoundToAll("survival/turret_takesdamage_02.wav", entity, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
					case 2 : EmitSoundToAll("survival/turret_takesdamage_03.wav", entity, SNDCHAN_STATIC, SNDLEVEL_LIBRARY);
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
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action RocketTouchHook(int entity, int target)
{
	// Validate target
	if (!IsEntityTurret(target))
	{
		// Gets entity position
		static float vPosition[3];
		GetAbsOrigin(entity, vPosition);

		// Create an explosion effect
		UTIL_CreateParticle(_, vPosition, _, _, "expl_coopmission_skyboom", SENTRY_ROCKET_EXPLOSION_TIME);
		
		// Create an explosion
		UTIL_CreateExplosion(vPosition, EXP_NOFIREBALL | EXP_NOSOUND, _, SENTRY_ROCKET_DAMAGE, SENTRY_ROCKET_RADIUS, "rocket", _, entity);

		// Play sound
		ZP_EmitSoundToAll(gSoundShoot, SENTRY_SOUND_EXPLOAD, entity, SNDCHAN_STATIC, SNDLEVEL_NORMAL);

		// Remove the entity from the world
		AcceptEntityInput(entity, "Kill");
	}

	// Return on the success
	return Plugin_Continue;
}

/**
 * @brief Timer for a rocket exploade.
 *
 * @param hTimer            The timer handle.
 * @param refID             The reference index.
 **/
public Action RocketExploadHook(Handle hTimer, int refID)
{
	// Gets entity index from reference key
	int entity = EntRefToEntIndex(refID);

	// Validate entity
	if (entity != -1)
	{
		// Explode it
		RocketTouchHook(entity, 0);
	}
	
	// Destroy timer
	return Plugin_Stop;
}

/**
 * @brief Called before a client take a fake damage.
 * 
 * @param client            The client index.
 * @param attacker          The attacker index. (Not validated!)
 * @param inflicter         The inflicter index. (Not validated!)
 * @param flDamage          The amount of damage inflicted.
 * @param iBits             The ditfield of damage types.
 * @param weapon            The weapon index or -1 for unspecified.
 *
 * @note To block damage reset the damage to zero. 
 **/
public void ZP_OnClientValidateDamage(int client, int &attacker, int &inflictor, float &flDamage, int &iBits, int &weapon)
{
	// Client was damaged by 'turret'
	if (iBits & DMG_BULLET)
	{
		// Validate rocket
		if (IsEntityTurret(attacker))
		{
			// Validate human
			if (ZP_IsPlayerHuman(client))
			{
				// Reset damage
				flDamage = 0.0;
			}
		}
	}
	// Client was damaged by 'explosion'
	else if (iBits & DMG_BLAST)
	{
		// Validate rocket
		if (IsEntityRocket(inflictor))
		{
			// Validate human
			if (ZP_IsPlayerHuman(client))
			{
				// Reset damage
				flDamage = 0.0;
			}
		}
	}
}

/**
 * @brief Called before a grenade sound is emitted.
 *
 * @param grenade           The grenade index.
 * @param weaponID          The weapon id.
 *
 * @return                  Plugin_Continue to allow sounds. Anything else
 *                              (like Plugin_Stop) to block sounds.
 **/
public Action ZP_OnGrenadeSound(int grenade, int weaponID)
{
	// Validate custom grenade
	if (weaponID == gWeapon)
	{
		// Block sounds
		return Plugin_Stop; 
	}
	
	// Allow sounds
	return Plugin_Continue;
}

//**********************************************
//* Menu (drone) callbacks.                    *
//**********************************************

/**
 * @brief Creates a sentry control menu.
 *  
 * @param client            The client index.
 * @param entity            The entity index.
 **/ 
void SentryMenu(int client, int entity)
{
	// Gets object methods
	SentryGun sentry = view_as<SentryGun>(entity); 
			
	// Initialize variables
	static char sBuffer[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	int iUpgrade = GetCost(SENTRY_CONTROL_UPGRADE_RATIO);
	int iRefill = GetCost(SENTRY_CONTROL_REFILL_RATIO);
	
	// Convert entity index to string
	IntToString(entity, sInfo, sizeof(sInfo));
	
	// Creates sentry menu handle
	Menu hMenu = CreateMenu(SentryMenuSlots);

	// Sets language to target
	SetGlobalTransTarget(client);

	// Sets title
	hMenu.SetTitle("%t", "turret control", iUpgrade, "money", iRefill, "money");

	// Show  option
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret level", sentry.UpgradeState + 1);
	hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iUpgrade || sentry.UpgradeState >= SENTRY_MODE_ROCKET ? false : true));
	
	// Show  option
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret hp", sentry.Health);
	hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iRefill || sentry.Health >= ZP_GetWeaponClip(gWeapon) ? false : true));
	
	// Show  option
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret ammo", sentry.Ammo);
	hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iRefill || sentry.Ammo >= ZP_GetWeaponAmmo(gWeapon) ? false : true));
	
	// Validate mode
	if (sentry.UpgradeLevel >= SENTRY_MODE_ROCKET)
	{
		// Show option
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret rockets", sentry.Rockets);
		hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iRefill || sentry.Rockets >= ZP_GetWeaponAmmunition(gWeapon) ? false : true));
	}
	
	// Sets exit button
	hMenu.ExitButton = true;
	
	// Sets options and display it
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	hMenu.Display(client, SENTRY_CONTROL_MENU);
}

/**
 * @brief Called when client selects option in the turret control menu, and handles it.
 *  
 * @param hMenu             The handle of the menu being used.
 * @param mAction           The action done on the menu (see menus.inc, enum MenuAction).
 * @param client            The client index.
 * @param mSlot             The slot index selected (starting from 0).
 **/ 
public int SentryMenuSlots(Menu hMenu, MenuAction mAction, int client, int mSlot)
{
	// Switch the menu action
	switch (mAction)
	{
		// Client hit 'Exit' button
		case MenuAction_End :
		{
			delete hMenu;
		}

		// Client selected an option
		case MenuAction_Select :
		{
			// Gets menu info
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int entity = StringToInt(sBuffer);
			
			// Validate entity
			if (IsValidEdict(entity))
			{
				// Validate cost
				int iCost = GetCost(!mSlot ? SENTRY_CONTROL_UPGRADE_RATIO : SENTRY_CONTROL_REFILL_RATIO); 
				if (ZP_GetClientMoney(client) < iCost)
				{
					return 0;
				}
		
				// Gets object methods
				SentryGun sentry = view_as<SentryGun>(entity); 
		
				// Checks button
				switch (mSlot)
				{
					// Button 'Upgrade' was pressed
					case 0 :
					{
						// Increment mode
						sentry.UpgradeState++;
					}
					
					// Button 'HP' was pressed
					case 1 :
					{
						// Reset health
						sentry.Health = ZP_GetWeaponClip(gWeapon);
					}
					
					// Button 'Ammo' was pressed
					case 2 :
					{
						// Reset ammo
						sentry.Ammo = ZP_GetWeaponAmmo(gWeapon);
					}
					
					// Button 'Rocket' was pressed
					case 3 :
					{
						// Reset rocket
						sentry.Rockets = ZP_GetWeaponAmmunition(gWeapon);
					}
				}
				
				// Remove some money from the client
				ZP_SetClientMoney(client, ZP_GetClientMoney(client) - iCost);
				
				// Open menu
				SentryMenu(client, entity);
			}
		}
	}
	
	return 0;
}

//**********************************************
//* Item (drone) stocks.                       *
//**********************************************

/**
 * @brief Gets the entity's position.
 * 
 * @param entity            The entity index.     
 * @param vOutput           The vector output.
 **/
stock void GetAbsOrigin(int entity, float vOutput[3]) 
{ 
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vOutput); 
} 

/**
 * @brief Gets the entity's center position.
 * 
 * @param entity            The entity index.     
 * @param vOutput           The vector output.
 **/
stock void GetCenterOrigin(int entity, float vOutput[3]) 
{ 
	GetAbsOrigin(entity, vOutput); 
	static float vMaxs[3]; 
	if (entity <= MaxClients)
	{
		GetClientMaxs(entity, vMaxs);
	}
	else
	{
		GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vMaxs); 
	}
	vOutput[2] += vMaxs[2] / 2.0; 
}

/**
 * @brief Gets the entity's eye position.
 * 
 * @param entity            The entity index.     
 * @param vOutput           The vector output.
 **/
stock void GetEyePosition(int entity, float vOutput[3]) 
{
	if (entity <= MaxClients)
	{
		GetClientEyePosition(entity, vOutput);
	}
	else
	{
		static float vMaxs[3]; 
		GetAbsOrigin(entity, vOutput);
		GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vMaxs); 
		vOutput[2] += vMaxs[2]; 
	}
}

/**
 * @brief Gets the cost from the percentage.
 *
 * @param flPercentage      The percentage input.  
 * @return                  The cost ouput.
 **/
int GetCost(float flPercentage)
{
	return RoundToCeil(float(ZP_GetWeaponCost(gWeapon)) * flPercentage);
}

/**
 * @brief Return itemdraw flag for radio menus.
 * 
 * @param menuCondition     If this is true, item will be drawn normally.
 **/
int GetDraw(bool menuCondition)
{
	return menuCondition ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
}

/**
 * @brief Validate a turret.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityTurret(int entity)
{
	// Validate entity
	if (entity <= MaxClients || !IsValidEdict(entity))
	{
		return false;
	}
	
	// Gets name
	static char sClassname[SMALL_LINE_LENGTH];
	GetEntPropString(entity, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
	
	// Validate name
	return (!strcmp(sClassname, "turret", false));
}

/**
 * @brief Validate a rocket.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
stock bool IsEntityRocket(int entity)
{
	// Validate entity
	if (entity <= MaxClients || !IsValidEdict(entity))
	{
		return false;
	}
	
	// Gets name
	static char sClassname[SMALL_LINE_LENGTH];
	GetEntPropString(entity, Prop_Data, "m_iGlobalname", sClassname, sizeof(sClassname));
	
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
	
	if (flAngle > 180.0)  
	{ 
		flAngle -= 360.0; 
	} 
	if (flAngle < -180.0) 
	{ 
		flAngle += 360.0; 
	} 
	
	return flAngle; 
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
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 * @return                  True or false.
 **/
public bool TurretFilter(int entity, int contentsMask, int filter)
{
	if (IsEntityTurret(entity)) 
	{
		return false;
	}
	
	return (entity != filter); 
}
