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
	name            = "[ZP] Weapon: Turret",
	author          = "qubka (Nikita Ushakov), Pelipoika",     
	description     = "Addon of custom weapons",
	version         = "2.0",
	url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Decal index
int gDecal[5]; int gTrail;

// Sound index
int gSoundShoot; int gSoundUpgrade; ConVar gKnockback;
 
// Weapon index
int gWeapon;  

// Item index
int gItem; 

// Platform
EngineOS gPlatform;
 
/**
 * @section Variables to store virtual SDK adresses.
 **/
Handle hSDKCallLookupPoseParameter; 
Handle hSDKCallLookupSequence;
Handle hSDKCallStudioFrameAdvance; 
Handle hSDKCallAddLayeredSequence;
int Animating_StudioHdr;
int AnimatingOverlay_Count;
/**
 * @endsection
 **/
 
/**
 * @section Information about the weapon.
 **/
#define WEAPON_IDLE_TIME 1.63
/**
 * @endsection
 **/

/**
 * @section Properties of the turret.
 **/
#define SENTRY_EYE_OFFSET_LEVEL_1   32.0 
#define SENTRY_EYE_OFFSET_LEVEL_2   40.0 
#define SENTRY_EYE_OFFSET_LEVEL_3   46.0
#define SENTRY_SHOOTER_OFFSET_LEVEL 70.0 
/**
 * @endsection
 **/
 
/**
 * @section Properties of the gibs shooter.
 **/
#define METAL_GIBS_AMOUNT   5.0
#define METAL_GIBS_DELAY    0.2
#define METAL_GIBS_SPEED    200.0
#define METAL_GIBS_VARIENCE 2.0  
#define METAL_GIBS_LIFE     5.0  
#define METAL_GIBS_DURATION 6.0
/**
 * @endsection
 **/

/**
 * @section Sentry models.
 **/ 
#define SENTRY_MODEL_LEVEL_1         "models/buildables/sentry1.mdl"
#define SENTRY_MODEL_LEVEL_1_UPGRADE "models/buildables/sentry1_heavy.mdl"
#define SENTRY_MODEL_LEVEL_2         "models/buildables/sentry2.mdl"
#define SENTRY_MODEL_LEVEL_2_UPGRADE "models/buildables/sentry2_heavy.mdl"
#define SENTRY_MODEL_LEVEL_3         "models/buildables/sentry3_fix2.mdl"
#define SENTRY_MODEL_LEVEL_3_UPGRADE "models/buildables/sentry3_heavy.mdl"
#define SENTRY_ROCKET_MODEL          "models/buildables/sentry3_rockets.mdl"
#define SENTRY_BLUEPRINT_MODEL       "models/buildables/sentry1_blueprint.mdl"
#define SENTRY_MODEL_LEVEL_1_GIB_1 "models/buildables/gibs/sentry1_gib1.mdl"
#define SENTRY_MODEL_LEVEL_1_GIB_2 "models/buildables/gibs/sentry1_gib2.mdl"
#define SENTRY_MODEL_LEVEL_1_GIB_3 "models/buildables/gibs/sentry1_gib3.mdl"
#define SENTRY_MODEL_LEVEL_1_GIB_4 "models/buildables/gibs/sentry1_gib4.mdl"
#define SENTRY_MODEL_LEVEL_2_GIB_1 "models/buildables/gibs/sentry2_gib1.mdl"
#define SENTRY_MODEL_LEVEL_2_GIB_2 "models/buildables/gibs/sentry2_gib2.mdl"
#define SENTRY_MODEL_LEVEL_2_GIB_3 "models/buildables/gibs/sentry2_gib3.mdl"
#define SENTRY_MODEL_LEVEL_2_GIB_4 "models/buildables/gibs/sentry2_gib4.mdl"
#define SENTRY_MODEL_LEVEL_3_GIB_1 "models/buildables/gibs/sentry3_gib1.mdl"
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

// Cvars
ConVar hCvarSentryRewards;			
ConVar hCvarSentryAttackNpc;			
ConVar hCvarSentryAttackVisibililty;
ConVar hCvarSentryBulletDamage;
ConVar hCvarSentryBulletRange;
ConVar hCvarSentryBulletDistance;
ConVar hCvarSentryBulletRadius;
ConVar hCvarSentryBulletTurn;
ConVar hCvarSentryBulletThink;
ConVar hCvarSentryBulletSpeed;
ConVar hCvarSentryRocketDelay;
ConVar hCvarSentryRocketReload;
ConVar hCvarSentryRocketSpeed;
ConVar hCvarSentryRocketDamage;
ConVar hCvarSentryRocketRadius;
ConVar hCvarSentryRocketTrail;
ConVar hCvarSentryRocketExp;
ConVar hCvarSentryControlMenu;
ConVar hCvarSentryControlUpgradeRatio;
ConVar hCvarSentryControlRefillRatio;
ConVar hCvarSentryDeathEffect;

/**
 * @brief Called when the plugin is fully initialized and all known external references are resolved. 
 *        This is only called once in the lifetime of the plugin, and is paired with OnPluginEnd().
 **/
public void OnPluginStart()
{
	hCvarSentryRewards             = CreateConVar("zp_weapon_sentry_rewards", "1", "Give rewards for damaging to the owner?", 0, true, 0.0, true, 1.0);
	hCvarSentryAttackNpc           = CreateConVar("zp_weapon_sentry_attack_npc", "0", "Attack npc? (chicken, ect)", 0, true, 0.0, true, 1.0);
	hCvarSentryAttackVisibililty   = CreateConVar("zp_weapon_sentry_attack_visibility", "50.0", "Min alpha to see target", 0, true, 0.0);
	hCvarSentryBulletDamage        = CreateConVar("zp_weapon_sentry_bullet_damage ", "20.0", "Bullet damage", 0, true, 0.0);
	hCvarSentryBulletRange         = CreateConVar("zp_weapon_sentry_bullet_range", "1100.0", "Shoot range", 0, true, 0.0);
	hCvarSentryBulletDistance      = CreateConVar("zp_weapon_sentry_bullet_distance", "8192.0", "Bullet distance", 0, true, 0.0);
	hCvarSentryBulletRadius        = CreateConVar("zp_weapon_sentry_bullet_radius", "5.0", "Damage radius", 0, true, 0.0);
	hCvarSentryBulletTurn          = CreateConVar("zp_weapon_sentry_bullet_turn", "2.0", "Turn rate", 0, true, 0.0);
	hCvarSentryBulletThink         = CreateConVar("zp_weapon_sentry_bullet_think", "0.05", "Think rate", 0, true, 0.0);
	hCvarSentryBulletSpeed         = CreateConVar("zp_weapon_sentry_bullet_speed", "0.2", "Shoot delay", 0, true, 0.0);
	hCvarSentryRocketDelay         = CreateConVar("zp_weapon_sentry_rocket_delay", "3.0", "Rocket shoot delay", 0, true, 0.0);
	hCvarSentryRocketReload        = CreateConVar("zp_weapon_sentry_rocket_reload", "1.8", "Rocket reload", 0, true, 0.0);
	hCvarSentryRocketSpeed         = CreateConVar("zp_weapon_sentry_rocket_speed", "1000.0", "Projectile speed", 0, true, 0.0);
	hCvarSentryRocketDamage        = CreateConVar("zp_weapon_sentry_rocket_damage", "300.0", "Projectile damage", 0, true, 0.0);
	hCvarSentryRocketRadius        = CreateConVar("zp_weapon_sentry_rocket_radius", "400.0", "Damage radius", 0, true, 0.0);
	hCvarSentryRocketTrail         = CreateConVar("zp_weapon_sentry_rocket_trail", "sentry_rocket", "Particle effect for the trail (''-default)");
	hCvarSentryRocketExp           = CreateConVar("zp_weapon_sentry_rocket_explosion", "expl_coopmission_skyboom", "Particle effect for the explosion (''-default)");
	hCvarSentryControlMenu         = CreateConVar("zp_weapon_sentry_control_menu", "10", "", 0, true, 0.0);
	hCvarSentryControlUpgradeRatio = CreateConVar("zp_weapon_sentry_control_upgrade_ratio", "0.5", "", 0, true, 0.0);
	hCvarSentryControlRefillRatio  = CreateConVar("zp_weapon_sentry_control_refill_ratio", "0.1 ", "", 0, true, 0.0); 
	hCvarSentryDeathEffect         = CreateConVar("zp_weapon_sentry_death", "explosion_hegrenade_interior", "Particle effect for the death (''-off)");
	
	AutoExecConfig(true, "zp_weapon_dronegun", "sourcemod/zombieplague");
}

/**
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
	if (!strcmp(sLibrary, "zombieplague", false))
	{
		GameData hConfig = LoadGameConfigFile("plugin.zombieplague"); 

		if (!hConfig) 
		{
			SetFailState("Failed to load zombieplague gamedata.");
			return;
		}

		if ((gPlatform = view_as<EngineOS>(hConfig.GetOffset("OS"))) == OS_Unknown) SetFailState("Failed to get offset: \"OS\"");    
		
		if ((Animating_StudioHdr = hConfig.GetOffset("CBaseAnimating::StudioHdr")) == -1) SetFailState("Failed to get offset: \"CBaseAnimating::StudioHdr\""); 
		int iOffset_hLightingOrigin;
		if ((iOffset_hLightingOrigin = FindSendPropInfo("CBaseAnimating", "m_hLightingOrigin")) < 1) SetFailState("Failed to find send prop: \"m_hLightingOrigin\"");
		Animating_StudioHdr += iOffset_hLightingOrigin;
		
		delete hConfig;
		
		/*__________________________________________________________________________________________________*/
		
		hConfig = LoadGameConfigFile("plugin.turret"); 

		if (!hConfig) 
		{
			SetFailState("Failed to load turret gamedata.");
			return;
		}
		
		/*_________________________________________________________________________________________________________________________________________*/
		
		{
			StartPrepSDKCall(SDKCall_Entity); 
			PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimating::LookupPoseParameter"); 
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);  
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 
			
			if ((hSDKCallLookupPoseParameter = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimating::LookupPoseParameter\". Update signature in \"plugin.turret\"");
		}
		
		/*__________________________________________________________________________________________________*/
		
		{
			StartPrepSDKCall(gPlatform == OS_Windows ? SDKCall_Entity : SDKCall_Raw); 
			PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimating::LookupSequence");
			
			PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);  
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 

			if ((hSDKCallLookupSequence = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimating::LookupSequence\". Update signature in \"plugin.turret\"");
		}

		/*__________________________________________________________________________________________________*/
		
		if ((AnimatingOverlay_Count = hConfig.GetOffset("CBaseAnimatingOverlay::Count")) == -1) SetFailState("Failed to get offset: \"CBaseAnimatingOverlay::Count\". Update offset in \"plugin.turret\""); 

		/*__________________________________________________________________________________________________*/
		
		{
			StartPrepSDKCall(SDKCall_Entity); 
			PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimatingOverlay::StudioFrameAdvance"); 
			
			if ((hSDKCallStudioFrameAdvance = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimatingOverlay::StudioFrameAdvance\". Update signature in \"plugin.turret\"");      
		}
		
		/*__________________________________________________________________________________________________*/
		
		{
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "CBaseAnimatingOverlay::AddLayeredSequence"); 
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

			if ((hSDKCallAddLayeredSequence = EndPrepSDKCall()) == null) SetFailState("Failed to load SDK call \"CBaseAnimatingOverlay::AddLayeredSequence\". Update signature in \"plugin.turret\""); 
		}
		
		/*__________________________________________________________________________________________________*/

		delete hConfig;

		LoadTranslations("zombieplague.phrases");
		LoadTranslations("turret.phrases");
		
		if (ZP_IsMapLoaded())
		{
			ZP_OnEngineExecute();
		}
	}
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute()
{
	gWeapon = ZP_GetWeaponNameID("turret");
	
	gItem = ZP_GetExtraItemNameID("turret");
	
	gSoundShoot = ZP_GetSoundKeyID("turret_sounds");
	if (gSoundShoot == -1) SetFailState("[ZP] Custom sound key ID from name : \"turret_sounds\" wasn't find");
	gSoundUpgrade = ZP_GetSoundKeyID("turret_up_sounds");
	if (gSoundUpgrade == -1) SetFailState("[ZP] Custom sound key ID from name : \"turret_up_sounds\" wasn't find");

	gKnockback = FindConVar("zp_knockback"); 
	if (gKnockback == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_knockback\" wasn't find");
}

/**
 * @brief The map is starting.
 **/
public void OnMapStart()
{
	gTrail = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheModel("materials/sprites/xfireball3.vmt", true); /// for env_explosion
	PrecacheModel("models/props_office/file_cabinet_03.mdl", true);
	PrecacheModel("models/weapons/w_eq_fraggrenade_dropped.mdl", true);
	
	PrecacheSound("survival/turret_death_01.wav", true);
	PrecacheSound("survival/turret_takesdamage_01.wav", true);
	PrecacheSound("survival/turret_takesdamage_02.wav", true);
	PrecacheSound("survival/turret_takesdamage_03.wav", true);

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
	
	public void RemoveLayer(int iLayer, float flKillRate, float flKillDelay)
	{
		this.Set(m_flKillRate, iLayer, flKillRate > 0.0 ? this.Get(m_flWeight, iLayer) / flKillRate : 100.0);
		this.Set(m_flKillDelay, iLayer, flKillDelay);
		this.KillMe(iLayer);
	}
	
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
	
	public bool IsAlive(int iLayer)         { int iFlags = this.Get(m_fFlags, iLayer); return (((iFlags & ANIM_LAYER_ACTIVE) != 0) || ((iFlags & ANIM_LAYER_KILLME) == 0)); }
	
	public int GetLayerSequence(int iLayer) { return (this.Get(m_nSequence, iLayer)); }
};

methodmap SentryGun /** Regards to Pelipoika **/
{
	public SentryGun(int owner, const float vPosition[3], const float vAngle[3], int iHealth, int iAmmo, int iRocket, int iSkin, int iLevel) 
	{
		int entity = UTIL_CreateMonster("turret_npc", vPosition, vAngle, SENTRY_MODEL_LEVEL_1, NPC_GAG | NPC_WAITFORSCRIPT | NPC_DONTDROPWEAPONS | NPC_IGNOREPLAYERPUSH);
		
		if (entity != -1)
		{
			static float vGoal[3]; static float vCurrent[3]; 

			int iRightBound = RoundToNearest(AngleMod(vAngle[1] - 50.0)); 
			int iLeftBound  = RoundToNearest(AngleMod(vAngle[1] + 50.0)); 
			if (iRightBound > iLeftBound) 
			{
				iRightBound = iLeftBound; 
				iLeftBound = RoundToNearest(AngleMod(vAngle[1] - 50.0)); 
			}
			SetEntProp(entity, Prop_Data, "m_iSpeedModSpeed", iRightBound); 
			SetEntProp(entity, Prop_Data, "m_iSpeedModRadius", iLeftBound); 
			
			vGoal[1] = float(iRightBound); 
			vGoal[0] = vCurrent[0] = 0.0; 
			vCurrent[1] = AngleMod(vAngle[1]); 
			SetEntPropVector(entity, Prop_Data, "m_vecLastPosition", vCurrent); 
			SetEntPropVector(entity, Prop_Data, "m_vecStoredPathGoal", vGoal);
			SetEntProp(entity, Prop_Data, "m_bSpeedModActive", true); 
			SetEntProp(entity, Prop_Data, "m_bIsAutoaimTarget", true);
			SetEntProp(entity, Prop_Data, "m_iInteractionState", SENTRY_STATE_SEARCHING); 
			
			/**__________________________________________________________**/

			SetEntityMoveType(entity, MOVETYPE_NONE);
			/*SetEntProp(entity, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_NONE); 
			SetEntProp(entity, Prop_Data, "m_usSolidFlags", FSOLID_NOT_SOLID);
			SetEntProp(entity, Prop_Data, "m_nSolidType", SOLID_NONE);*/

			SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_NO);
			SetEntProp(entity, Prop_Data, "m_iHealth", iHealth);
			SetEntProp(entity, Prop_Data, "m_iMaxHealth", iHealth);

			SetEntProp(entity, Prop_Send, "m_nSkin", iSkin);
			SetEntProp(entity, Prop_Send, "m_nBody", 2);

			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", owner); 

			SetEntProp(entity, Prop_Data, "m_iTeamNum", ZP_IsPlayerZombie(owner) ? TEAM_ZOMBIE : TEAM_HUMAN); 
			SetEntProp(entity, Prop_Data, "m_iAmmo", iAmmo); 
			SetEntProp(entity, Prop_Data, "m_iMySquadSlot", iRocket); 
			SetEntProp(entity, Prop_Data, "m_iHammerID", iLevel); 
			SetEntProp(entity, Prop_Data, "m_iDesiredWeaponState", SENTRY_MODE_NORMAL); 
			SetEntPropFloat(entity, Prop_Data, "m_flSoundWaitTime", 0.0);

			UTIL_SetRenderColor(entity, Color_Alpha, 0);
			//AcceptEntityInput(entity, "DisableDraw"); 
			AcceptEntityInput(entity, "DisableShadow"); 
			AcceptEntityInput(entity, "DisableReceivingFlashlight");

			//vPosition[2] -= 35.0;
			int upgrade = UTIL_CreateDynamic("upgrade", vPosition, vAngle, SENTRY_MODEL_LEVEL_1_UPGRADE, "build");

			if (upgrade != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(upgrade, "SetParent", entity, upgrade);
			
				SetEntProp(upgrade, Prop_Send, "m_nSkin", iSkin);
				SetEntProp(upgrade, Prop_Send, "m_nBody", 2);

				SetEntPropEnt(upgrade, Prop_Data, "m_hOwnerEntity", entity);

				ZP_EmitSoundToAll(gSoundUpgrade, 1, upgrade, SNDCHAN_STATIC);
				
				CreateTimer(5.0, SentryActivateHook, EntIndexToEntRef(upgrade), TIMER_FLAG_NO_MAPCHANGE);
			}

			int physics = UTIL_CreatePhysics("turret_body", vPosition, vAngle, "models/props_office/file_cabinet_03.mdl", PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);
			
			if (physics != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(physics, "SetParent", entity, physics);

				SetEntityMoveType(physics, MOVETYPE_NONE);
				SetEntProp(physics, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER); 
				SetEntProp(physics, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
			
				SetEntProp(physics, Prop_Data, "m_iTeamNum", GetEntProp(entity, Prop_Data, "m_iTeamNum")); 
				SetEntProp(physics, Prop_Data, "m_iHammerID", -1); 
			
				SetEntPropEnt(physics, Prop_Data, "m_hOwnerEntity", entity); 
				
				SetEntPropEnt(entity, Prop_Data, "m_hInteractionPartner", physics); 
						
				AcceptEntityInput(physics, "DisableDraw"); 
				AcceptEntityInput(physics, "DisableShadow"); 
				
				if (iHealth > 0)
				{
					SetEntProp(physics, Prop_Data, "m_takedamage", DAMAGE_EVENTS_ONLY);
					SetEntProp(physics, Prop_Data, "m_iHealth", iHealth);
					SetEntProp(physics, Prop_Data, "m_iMaxHealth", iHealth);
					
					SDKHook(physics, SDKHook_OnTakeDamage, SentryDamageHook);
				}
				else
				{
					SetEntProp(physics, Prop_Data, "m_takedamage", DAMAGE_NO);
				}
			}
			
			//SDKHook(entity, SDKHook_Touch, SentryTouchHook);
		}
		
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
			return GetEntPropFloat(this.Index, Prop_Data, "m_flSoundWaitTime");  
		}

		public set(float flDelay) 
		{
			SetEntPropFloat(this.Index, Prop_Data, "m_flSoundWaitTime", flDelay); 
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

	property int Team
	{
		public get() 
		{  
			return GetEntProp(this.Index, Prop_Data, "m_iTeamNum");  
		}

		public set(int iTeam) 
		{
			SetEntPropEnt(this.Index, Prop_Data, "m_iTeamNum", iTeam); 
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
			return GetEntPropEnt(this.Index, Prop_Data, "m_hOwnerEntity");  
		}

		public set(int entity) 
		{
			SetEntPropEnt(this.Index, Prop_Data, "m_hOwnerEntity", entity); 
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

	property int Physics
	{
		public get() 
		{  
			return GetEntPropEnt(this.Index, Prop_Data, "m_hInteractionPartner");  
		}

		public set(int physics) 
		{
			SetEntPropEnt(this.Index, Prop_Data, "m_hInteractionPartner", physics); 
		}
	}

	/*__________________________________________________________________________________________________*/
	
	public void GetCurAngles(float vOutput[3])
	{
		GetEntPropVector(this.Index, Prop_Data, "m_vecLastPosition", vOutput); 
	}
	
	public void SetCurAngles(const float vInput[3])
	{
		SetEntPropVector(this.Index, Prop_Data, "m_vecLastPosition", vInput); 
	}
	
	public void GetGoalAngles(float vOutput[3])
	{
		GetEntPropVector(this.Index, Prop_Data, "m_vecStoredPathGoal", vOutput); 
	}
	
	public void SetGoalAngles(const float vInput[3])
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
	
	public int FindGestureLayer(const char[] sAnim) 
	{
		int iSequence = this.LookupSequence(sAnim); 
		if (iSequence < 0) 
		{
			return -1; 
		}

		CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
		if (pOverlay.isNull) 
		{
			return -1; 
		}
		
		int iCount = this.AnimOverlayCount();
		for (int i = 0; i < iCount; i++) 
		{
			if (!pOverlay.IsAlive(i)) 
			{
				continue; 
			}

			if (pOverlay.GetLayerSequence(i) == iSequence) 
			{
				return i; 
			}
		} 
		
		return -1; 
	}

	public int AddGesture(const char[] sAnim, bool bAutoKill = true) 
	{ 
		int iSequence = this.LookupSequence(sAnim); 
		if (iSequence < 0) 
		{
			return -1; 
		}

		CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
		if (pOverlay.isNull) 
		{
			return -1; 
		}
		
		int iLayer = SDKCall(hSDKCallAddLayeredSequence, this.Index, iSequence, 0); 
		if (iLayer >= 0 && iLayer < this.AnimOverlayCount() && pOverlay.IsActive(iLayer))
		{
			pOverlay.SetLayerAutokill(iLayer, bAutoKill);
		}
		
		return iLayer;
	} 

	public bool IsPlayingGesture(const char[] sAnim)    
	{ 
		return this.FindGestureLayer(sAnim) != -1 ? true : false; 
	} 

	public void RemoveGesture(const char[] sAnim) 
	{ 
		int iLayer = this.FindGestureLayer(sAnim); 
		if (iLayer == -1) 
		{
			return; 
		}

		CAnimationOverlay pOverlay = this.CBaseAnimatingOverlay(); 
		if (pOverlay.isNull) 
		{
			return;
		}
		
		pOverlay.RemoveLayer(iLayer, 0.0, 0.0);
	}

	/*__________________________________________________________________________________________________*/

	public bool ValidTargetPlayer(int target, const float vStart[3], const float vEndPosition[3]) 
	{
		TR_TraceRayFilter(vStart, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, TurretFilter, this.Index); 

		return TR_GetFraction() == 1.0;
	} 
	 
	public void SelectTargetPoint(const float vStart[3], float vCenter[3]) 
	{
		GetCenterOrigin(this.Enemy, vCenter); 
	 
		TR_TraceRayFilter(vStart, vCenter, MASK_SOLID, RayType_EndPoint, TeamFilter, this.Index); 
		
		if (TR_DidHit()) 
		{
			int victim = TR_GetEntityIndex();
			if (victim >= MaxClients || victim <= 0)
			{
				GetEyePosition(this.Enemy, vCenter); 
				vCenter[2] -= 5.0; 
			}
		}
	}
	
	public bool CanUpgrade() 
	{
		static float vPosition[3];
		GetAbsOrigin(this.Index, vPosition); 
		
		static const float vMins[3] = { -40.0, -40.0, 0.0   }; 
		static const float vMaxs[3] = {  40.0,  40.0, 72.0  }; 
		
		ArrayList hList = new ArrayList();
		
		vPosition[2] += vMaxs[2];
		TR_EnumerateEntitiesHull(vPosition, vPosition, vMins, vMaxs, false, HullEnumerator, hList);

		bool bHit;
		if (!hList.Length)
		{
			bHit = true;
		}
		
		delete hList;
		return bHit;
	}
	
	public void EmitSound(int iIndex)
	{
		ZP_EmitSoundToAll(gSoundShoot, iIndex, this.Index, SNDCHAN_STATIC);
	}
	
	public void FoundTarget(int target) 
	{     
		this.Enemy = target; 
		
		if (this.Ammo > 0 || (this.Rockets > 0 && this.UpgradeLevel == SENTRY_MODE_ROCKET))
		{
			this.EmitSound(GetRandomInt(SENTRY_SOUND_SPOT, SENTRY_SOUND_SPOT2));
		}
		
		float flCurrentTime = GetGameTime();
		
		float flDelay = hCvarSentryBulletThink.FloatValue;
		this.State = SENTRY_STATE_ATTACKING; 
		this.NextAttack = flCurrentTime + flDelay; 
		if (this.NextRocket < flCurrentTime) 
		{ 
			this.NextRocket = flCurrentTime + flDelay * 10.0; 
		} 
	}

	public bool FindTarget() 
	{ 
		static float vPosition[3]; static float vPosition2[3]; 
	
		this.GetGunPosition(vPosition); 

		int target = -1; int old = this.Enemy;
		float flRange = hCvarSentryBulletRange.FloatValue;
		float flMinDistance = flRange * flRange;
		float flOldDistance = MAX_FLOAT;
		float flVisibility = hCvarSentryAttackVisibililty.FloatValue;
		
		for (int i = 1; i <= MaxClients; i++) 
		{
			if (!IsClientValid(i))
			{
				continue;
			}
	
			if (IsEntitySameTeam(this.Index, i))
			{
				continue;
			}

			if (GetEntProp(i, Prop_Send, "m_fEffects") & EF_NODRAW || UTIL_GetRenderColor(i, Color_Alpha) < flVisibility)
			{
				continue;
			}
			
			GetAbsOrigin(i, vPosition2);
			
			float flDistance = GetVectorDistance(vPosition, vPosition2, true);
			
			if (i == old) 
			{ 
				flOldDistance = flDistance; 
			} 
			
			if (flDistance > flMinDistance) 
			{
				continue; 
			}
			
			if (this.ValidTargetPlayer(i, vPosition, vPosition2)) 
			{ 
				flMinDistance = flDistance; 
				target = i; 
			}
		}

		if (hCvarSentryAttackNpc.BoolValue)
		{
			static char sClassname[SMALL_LINE_LENGTH];
			
			if (target == -1) 
			{
				int MaxEntities = GetMaxEntities();
				for (int i = MaxClients; i <= MaxEntities; i++)
				{
					if (IsValidEdict(i))
					{
						GetEdictClassname(i, sClassname, sizeof(sClassname));

						if (sClassname[0] == 'c' && sClassname[1] == 'h') // chicken
						{
						}
						else if (sClassname[0] == 'm' && sClassname[8] == 'g') // monster_generic
						{
							if (GetEntProp(i, Prop_Data, "m_iTeamNum") == this.Team)
							{
								continue;
							}
						}
						else continue;
					
						GetAbsOrigin(i, vPosition2);
						
						float flDistance = GetVectorDistance(vPosition, vPosition2, true);
						
						if (i == old) 
						{ 
							flOldDistance = flDistance; 
						} 
						
						if (flDistance > flMinDistance) 
						{
							continue; 
						}
						
						if (this.ValidTargetPlayer(i, vPosition, vPosition2)) 
						{ 
							flMinDistance = flDistance; 
							target = i; 
						}
					}
				}
			}
		}
		
		if (target != -1) 
		{ 
			if (target != old) 
			{ 
				if (flMinDistance < (flOldDistance * 0.75)) 
				{ 
					this.FoundTarget(target); 
				} 
			}
			
			return true; 
		} 
		
		return false; 
	}

	public bool Move() 
	{ 
		bool bMoved = false; 
		float flDelay = hCvarSentryBulletThink.FloatValue;
		float flTurnRate = hCvarSentryBulletTurn.FloatValue; 
		
		static float vGoal[3]; static float vCurrent[3];
		this.GetGoalAngles(vGoal); 
		this.GetCurAngles(vCurrent);
		
		if (vCurrent[0] != vGoal[0]) 
		{ 
			float flDir = vGoal[0] > vCurrent[0] ? 1.0 : -1.0 ; 
			vCurrent[0] += flDelay * (flTurnRate * 5) * flDir; 
	 
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
	 
			this.SetPoseParameter(this.LookupPoseParameter("aim_pitch"), -50.0, 50.0, -vCurrent[0]); 
			bMoved = true; 
		} 
		 
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
	 
			if (this.Enemy == -1) 
			{ 
				if (flNewDistance > 30.0) 
				{ 
					if (this.TurnRate < flTurnRate * 10.0) 
						this.TurnRate += flTurnRate; 
				} 
				else 
				{ 
					if (this.TurnRate > (flTurnRate * 5.0)) 
						this.TurnRate -= flTurnRate; 
				} 
			} 
			else 
			{ 
				if (flNewDistance > 30.0) 
				{ 
					if (this.TurnRate < flTurnRate * 30.0) 
						this.TurnRate += flTurnRate * 3.0; 
				} 
			} 
	 
			vCurrent[1] += flDelay * this.TurnRate * flDir; 
	 
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
	 
			static float vAngle[3]; 
			this.GetAbsAngles(vAngle); 
			
			float flYaw = AngleNormalize(vCurrent[1] - vAngle[1]); 
			this.SetPoseParameter(this.LookupPoseParameter("aim_yaw"), -180.0, 180.0, -flYaw); 
			this.SetCurAngles(vCurrent);
			bMoved = true; 
		} 
	 
		if (!bMoved || this.TurnRate <= 0.0) 
		{ 
			this.TurnRate = flTurnRate * 5.0; 
		} 
	 
		return bMoved; 
	}
	
	public void Rocket(const float vPosition[3], const float vAngle[3], const float vVelocity[3])
	{
		static char sBuffer[SMALL_LINE_LENGTH];
	
		int entity = UTIL_CreateProjectile(vPosition, vAngle, gWeapon, "models/weapons/w_eq_fraggrenade_dropped.mdl");

		if (entity != -1)
		{
			TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);

			AcceptEntityInput(entity, "DisableDraw"); 
			AcceptEntityInput(entity, "DisableShadow"); 
			
			SetEntPropString(entity, Prop_Data, "m_iGlobalname", "rocket");

			int rocket = UTIL_CreateDynamic("rocket", NULL_VECTOR, NULL_VECTOR, SENTRY_ROCKET_MODEL, "idle", false);

			if (rocket != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(rocket, "SetParent", entity, rocket);

				SetVariantString("1"); 
				AcceptEntityInput(rocket, "SetParentAttachment", entity, rocket);
			
				static char sEffect[SMALL_LINE_LENGTH];
				hCvarSentryRocketTrail.GetString(sEffect, sizeof(sEffect));

				if (hasLength(sEffect))
				{
					for (int i = 1; i <= 4; i++)
					{
						FormatEx(sBuffer, sizeof(sBuffer), "rocket%d", i);
						UTIL_CreateParticle(rocket, _, _, sBuffer, sEffect, 5.0);
					}
				}
				else
				{
					TE_SetupBeamFollow(rocket, gTrail, 0, 5.0, 10.0, 10.0, 5, {180, 180, 180, 255});
					TE_SendToAll();	
				}
			}

			SetEntProp(entity, Prop_Data, "m_iTeamNum", this.Team); 
			
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", this.Owner); 
			SetEntPropEnt(entity, Prop_Data, "m_hEffectEntity", this.Index);

			SetEntPropFloat(entity, Prop_Data, "m_flGravity", 0.01);

			SDKHook(entity, SDKHook_Touch, RocketTouchHook);
			
			CreateTimer(4.0, RocketExploadHook, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		this.Body = 1;
		
		FormatEx(sBuffer, sizeof(sBuffer), "OnUser2 !self:SetBodyGroup:0:%f:1", hCvarSentryRocketReload.FloatValue);
		
		SetVariantString(sBuffer);
		AcceptEntityInput(this.Index, "AddOutput");
		AcceptEntityInput(this.Index, "FireUser2"); /// Reset body
	}
	
	public void Shot(const float vPosition[3], float vDirection[3], const char[] sAttach) 
	{ 
		static float vEndPosition[3]; static float vVelocity[3]; static float vVelocity2[3];
		
		ScaleVector(vDirection, hCvarSentryBulletDistance.FloatValue);
		AddVectors(vDirection, vPosition, vEndPosition);
		
		vEndPosition[0] += GetRandomFloat(-10.0, 10.0); 
		vEndPosition[1] += GetRandomFloat(-10.0, 10.0); 
		vEndPosition[2] += GetRandomFloat(-10.0, 10.0); 
		
		TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, TeamFilter, this.Index); 

		if (TR_DidHit())
		{
			TR_GetEndPosition(vEndPosition); 

			UTIL_CreateTracer(this.Index, sAttach, "weapon_tracers_50cal", vEndPosition, 0.1);

			int victim = TR_GetEntityIndex();
			
			if (victim < 1)
			{
				TE_Start("BSP Decal");
				TE_WriteVector("m_vecOrigin", vEndPosition);
				TE_WriteNum("m_nEntity", victim);
				TE_WriteNum("m_nIndex", gDecal[GetRandomInt(0, 4)]);
				TE_SendToAll();
			}
			else
			{
				int owner = this.Owner;
				int attacker = hCvarSentryRewards.BoolValue && IsClientValid(owner, false) && IsEntitySameTeam(this.Index, owner) ? owner : this.Physics;
			
				UTIL_CreateDamage(_, vEndPosition, attacker, hCvarSentryBulletDamage.FloatValue, hCvarSentryBulletRadius.FloatValue, DMG_BULLET);
		
				if (IsClientValid(victim) && ZP_IsPlayerZombie(victim))
				{
					float flForce = ZP_GetClassKnockBack(ZP_GetClientClass(victim)) * ZP_GetWeaponKnockBack(gWeapon); 
					if (flForce <= 0.0)
					{
						return;
					}
					
					if (gKnockback.BoolValue)
					{
						MakeVectorFromPoints(vPosition, vEndPosition, vVelocity);

						NormalizeVector(vVelocity, vVelocity);

						ScaleVector(vVelocity, flForce);
						
						GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vVelocity2);
						
						AddVectors(vVelocity2, vVelocity, vVelocity);
					
						TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vVelocity);
					}
					else
					{
						SetEntPropFloat(victim, Prop_Send, "m_flStamina", min(flForce, 100.0));
					}
				}
			}
		}
	}

	public void Fire() 
	{ 
		static float vPosition[3]; static float vAngle[3]; static float vVelocity[3]; static float vPosition2[3];
		float flSpeed = hCvarSentryBulletSpeed.FloatValue; 
		float flCurrentTime = GetGameTime();
		
		if (this.UpgradeLevel == SENTRY_MODE_ROCKET && this.NextRocket < flCurrentTime)
		{
			if (this.Rockets > 0) 
			{ 
				if (!this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
				{
					this.AddGesture("ACT_RANGE_ATTACK2");
				}
		
				this.GetLauncherPosition(vPosition); 

				GetCenterOrigin(this.Enemy, vPosition2); 
				MakeVectorFromPoints(vPosition, vPosition2, vAngle);
				NormalizeVector(vAngle, vAngle); 
				GetVectorAngles(vAngle, vAngle); 
				GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(vVelocity, vVelocity);
				ScaleVector(vVelocity, hCvarSentryRocketSpeed.FloatValue);

				this.EmitSound(SENTRY_MODE_ROCKET); 
				this.Rocket(vPosition, vAngle, vVelocity); 

				this.NextRocket = flCurrentTime + hCvarSentryRocketDelay.FloatValue;
				this.Rockets--;
			}
			else
			{
				/*if (this.IsPlayingGesture("ACT_RANGE_ATTACK2")) 
				{ 
					this.RemoveGesture("ACT_RANGE_ATTACK2"); 
				}*/
				
				this.NextRocket = MAX_FLOAT;
			}
		}
		
		if (this.Ammo > 0) 
		{ 
			if (this.UpgradeLevel > SENTRY_MODE_NORMAL) 
			{
				if (this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
				{ 
					this.RemoveGesture("ACT_RANGE_ATTACK1_LOW"); 
				}
			}
			
			if (!this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
			{
				this.AddGesture("ACT_RANGE_ATTACK1"); 
			}

			switch (this.UpgradeLevel) 
			{ 
				case SENTRY_MODE_NORMAL    : this.EmitSound(GetRandomInt(0, 1) ? SENTRY_SOUND_SHOOT : SENTRY_SOUND_SHOOT4); 
				case SENTRY_MODE_AGRESSIVE : this.EmitSound(SENTRY_SOUND_SHOOT2); 
				case SENTRY_MODE_ROCKET    : this.EmitSound(SENTRY_SOUND_SHOOT3); 
			}

			static char sAttach[SMALL_LINE_LENGTH];
			strcopy(sAttach, sizeof(sAttach), (this.UpgradeLevel == SENTRY_MODE_NORMAL) ? "muzzle" : ((this.Ammo & 1) ? "muzzle_l" : "muzzle_r"));
			
			static int iAttach[3] = { -1, ... };
			if (iAttach[0] == -1) iAttach[0] = LookupEntityAttachment(this.Index, "muzzle");
			if (iAttach[1] == -1) iAttach[1] = LookupEntityAttachment(this.Index, "muzzle_l");
			if (iAttach[2] == -1) iAttach[2] = LookupEntityAttachment(this.Index, "muzzle_r");

			GetEntityAttachment(this.Index, (this.UpgradeLevel == SENTRY_MODE_NORMAL) ? iAttach[0] : ((this.Ammo & 1) ? iAttach[1] : iAttach[2]), vPosition, vVelocity);
			
			this.SelectTargetPoint(vPosition, vPosition2);
			MakeVectorFromPoints(vPosition, vPosition2, vAngle);
			NormalizeVector(vAngle, vAngle); 

			static char sMuzzle[NORMAL_LINE_LENGTH];
			this.Shot(vPosition, vAngle, sAttach); 
			ZP_GetWeaponModelMuzzle(gWeapon, sMuzzle, sizeof(sMuzzle));
			UTIL_CreateParticle(this.Index, _, _, sAttach, sMuzzle, flSpeed);

			if (this.UpgradeLevel > SENTRY_MODE_NORMAL) flSpeed *= 0.5;
			this.NextAttack = flCurrentTime + flSpeed;
			this.Ammo--;
			this.Lock = false;
		} 
		else 
		{
			/*if (this.UpgradeLevel > SENTRY_MODE_NORMAL) 
			{
				if (!this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW")) 
				{ 
					this.RemoveGesture("ACT_RANGE_ATTACK1"); 
					this.AddGesture("ACT_RANGE_ATTACK1_LOW");
					this.EmitSound(SENTRY_SOUND_FINISH);
				} 
			}*/

			this.EmitSound(SENTRY_SOUND_EMPTY);
			this.NextAttack = MAX_FLOAT; 
	   }
	}
	
	public void Upgrade()
	{
		if (this.UpgradeLevel == SENTRY_MODE_ROCKET)
		{
			return;
		}

		SDKUnhook(this.Index, SDKHook_ThinkPost, SentryThinkHook);
		
		int iYaw = this.LookupPoseParameter("aim_yaw"); 
		int iPitch = this.LookupPoseParameter("aim_pitch");
		
		static float vPosition[3];
		GetAbsOrigin(this.Index, vPosition);
		
		static float vAngle[3]; 
		this.GetAbsAngles(vAngle);

		int upgrade = UTIL_CreateDynamic("upgrade", vPosition, vAngle, this.UpgradeLevel ? SENTRY_MODEL_LEVEL_3_UPGRADE : SENTRY_MODEL_LEVEL_2_UPGRADE, "upgrade");

		if (upgrade != -1)
		{
			SetVariantString("!activator");
			AcceptEntityInput(upgrade, "SetParent", this.Index, upgrade);
		
			SetEntProp(upgrade, Prop_Send, "m_nSkin", this.Skin);
			SetEntProp(upgrade, Prop_Send, "m_nBody", 2);
			
			SetEntPropEnt(upgrade, Prop_Data, "m_hOwnerEntity", this.Index); 
			
			ZP_EmitSoundToAll(gSoundUpgrade, 2, upgrade, SNDCHAN_STATIC);

			SetEntPropFloat(upgrade, Prop_Send, "m_flPoseParameter", GetEntPropFloat(this.Index, Prop_Send, "m_flPoseParameter", iYaw), iYaw); 
			SetEntPropFloat(upgrade, Prop_Send, "m_flPoseParameter", GetEntPropFloat(this.Index, Prop_Send, "m_flPoseParameter", iPitch), iPitch); 
			
			CreateTimer(1.5, SentryActivateHook, EntIndexToEntRef(upgrade), TIMER_FLAG_NO_MAPCHANGE);
		}
		
		this.UpgradeLevel++;
		this.Lock = true;

		SetEntityModel(this.Index, this.UpgradeLevel == SENTRY_MODE_ROCKET ? SENTRY_MODEL_LEVEL_3 : SENTRY_MODEL_LEVEL_2);

		UTIL_SetRenderColor(this.Index, Color_Alpha, 0);
		//AcceptEntityInput(this.Index, "DisableDraw"); 
		AcceptEntityInput(this.Index, "DisableShadow"); 
		AcceptEntityInput(this.Index, "DisableReceivingFlashlight");
	}
	
	public void Rotate() 
	{ 
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
		
		if (this.UpgradeState != this.UpgradeLevel && this.CanUpgrade())
		{
			this.Upgrade();
			return;
		}
	 
		if (this.FindTarget()) 
		{ 
			return; 
		} 
		
		if (this.UpgradeLevel > SENTRY_MODE_NORMAL) 
		{ 
			if (!this.IsPlayingGesture("ACT_RANGE_ATTACK1_LOW") && !this.Lock) 
			{ 
				this.AddGesture("ACT_RANGE_ATTACK1_LOW");
				this.EmitSound(SENTRY_SOUND_FINISH);
				this.Lock = true;
			} 
		}
	 
		if (!this.Move()) 
		{
			float flCurrentTime = GetGameTime();
		
			if (this.NextSound <= flCurrentTime)
			{
				switch (this.UpgradeLevel) 
				{ 
					case SENTRY_MODE_NORMAL    : this.EmitSound(SENTRY_SOUND_SCAN); 
					case SENTRY_MODE_AGRESSIVE : this.EmitSound(SENTRY_SOUND_SCAN2); 
					case SENTRY_MODE_ROCKET    : this.EmitSound(SENTRY_SOUND_SCAN3); 
				}
				this.NextSound = flCurrentTime + 0.2;
			}
			
			static float vGoal[3]; 
			this.GetGoalAngles(vGoal);
	 
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

			if (GetRandomFloat(0.0, 1.0) < 0.3) 
			{ 
				vGoal[0] = GetRandomFloat(-10.0, 10.0); 
			}
			
			this.SetGoalAngles(vGoal);
		}
	} 

	public void Attack() 
	{
		if (!this.FindTarget()) 
		{
			this.State = SENTRY_STATE_SEARCHING;
			return; 
		} 
	 
		static float vCenter[3]; static float vPosition2[3]; static float vDirection[3]; static float vAngle[3]; 
	 
		GetCenterOrigin(this.Index, vCenter); 
		this.SelectTargetPoint(vCenter, vPosition2);
		MakeVectorFromPoints(vCenter, vPosition2, vDirection);
		GetVectorAngles(vDirection, vAngle); 
	 
		vAngle[1] = AngleMod(vAngle[1]); 
		if (vAngle[0] < -180.0) 
			vAngle[0] += 360.0; 
		if (vAngle[0] > 180.0) 
			vAngle[0] -= 360.0; 
	 
		if (vAngle[0] > 50.0) 
			vAngle[0] = 50.0; 
		else if (vAngle[0] < -50.0) 
			vAngle[0] = -50.0; 

		static float vGoal[3]; static float vCurrent[3]; static float vRange[3]; 
		this.GetGoalAngles(vGoal); 
		this.GetCurAngles(vCurrent);
		vGoal[1] = vAngle[1]; 
		vGoal[0] = vAngle[0]; 
		this.SetGoalAngles(vGoal);     
		this.Move(); 
		
		MakeVectorFromPoints(vCurrent, vGoal, vRange);
		
		float flCurrentTime = GetGameTime();
		
		if (this.NextAttack <= flCurrentTime && GetVectorLength(vRange) <= 10.0) 
		{ 
			this.Fire(); 
		} 
		 
		if (GetVectorLength(vRange) > 10.0) 
		{ 
			if (this.IsPlayingGesture("ACT_RANGE_ATTACK1")) 
			{ 
				this.RemoveGesture("ACT_RANGE_ATTACK1"); 
			} 
			
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
		static float vPosition[3]; static float vGib[3]; float vShoot[3];

		EmitSoundToAll("survival/turret_death_01.wav", this.Index, SNDCHAN_STATIC);
		
		GetAbsOrigin(this.Index, vPosition);
		
		static char sEffect[SMALL_LINE_LENGTH];
		hCvarSentryDeathEffect.GetString(sEffect, sizeof(sEffect));

		if (hasLength(sEffect))
		{
			UTIL_CreateParticle(this.Index, vPosition, _, _, sEffect, 0.2);
		}

		for (int x = 1; x <= 4; x++)
		{
			vShoot[1] += 90.0; vGib[0] = GetRandomFloat(0.0, 360.0); vGib[1] = GetRandomFloat(-15.0, 15.0); vGib[2] = GetRandomFloat(-15.0, 15.0); 
			switch (x)
			{
				case 1 : UTIL_CreateShooter(this.Index, "build_point_0", _, MAT_METAL, this.Skin, (this.UpgradeLevel == SENTRY_MODE_ROCKET) ? SENTRY_MODEL_LEVEL_3_GIB_1 : (this.UpgradeLevel ? SENTRY_MODEL_LEVEL_2_GIB_1 : SENTRY_MODEL_LEVEL_1_GIB_1), vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
				case 2 : UTIL_CreateShooter(this.Index, "build_point_0", _, MAT_METAL, this.Skin, this.UpgradeLevel ? SENTRY_MODEL_LEVEL_2_GIB_2 : SENTRY_MODEL_LEVEL_1_GIB_2, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
				case 3 : UTIL_CreateShooter(this.Index, "build_point_0", _, MAT_METAL, this.Skin, this.UpgradeLevel ? SENTRY_MODEL_LEVEL_2_GIB_3 : SENTRY_MODEL_LEVEL_1_GIB_3, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
				case 4 : UTIL_CreateShooter(this.Index, "build_point_0", _, MAT_METAL, this.Skin, this.UpgradeLevel ? SENTRY_MODEL_LEVEL_2_GIB_4 : SENTRY_MODEL_LEVEL_1_GIB_4, vShoot, vGib, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
			}
		}

		UTIL_RemoveEntity(this.Index, 0.1);
	}
	
	public int LookupPoseParameter(const char[] sPose)
	{
		Address pStudioHdrClass = this.GetStudioHdrClass();
		if (pStudioHdrClass == Address_Null)
		{
			return -1;
		}
		
		return SDKCall(hSDKCallLookupPoseParameter, this.Index, pStudioHdrClass, sPose); 
	}

	public int LookupSequence(const char[] sAnim)
	{
		if (gPlatform == OS_Windows)
		{
			return SDKCall(hSDKCallLookupSequence, this.Index, sAnim); 
		}
		else
		{
			Address pStudioHdrClass = this.GetStudioHdrClass();
			if (pStudioHdrClass == Address_Null)
			{
				return -1;
			}
			
			return SDKCall(hSDKCallLookupSequence, pStudioHdrClass, sAnim); 
		}
	}

	public Address GetStudioHdrClass()
	{
		return view_as<Address>(GetEntData(this.Index, Animating_StudioHdr));
	}
};

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int client, int weapon, float flCurrentTime)
{
	Weapon_OnCreateEffect(client, weapon, EFFECT_KILL);
}

void Weapon_OnIdle(int client, int weapon, float flCurrentTime)
{
	Weapon_OnCreateEffect(client, weapon, EFFECT_UPDATE);
	
	int entity = ZP_GetClientViewModel(client, true);
	
	if (entity != -1)
	{
		SetEntProp(entity, Prop_Send, "m_nSkin", GetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount"));
	}
	
	if (GetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
	{
		return;
	}
	
	ZP_SetWeaponAnimation(client, ANIM_IDLE); 
	
	SetEntPropFloat(weapon, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + WEAPON_IDLE_TIME);
}

void Weapon_OnDeploy(int client, int weapon, float flCurrentTime)
{
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", MAX_FLOAT);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", MAX_FLOAT);

	Weapon_OnCreateEffect(client, weapon, EFFECT_CREATE);
	
	ZP_SetWeaponAnimation(client, ANIM_DRAW);

	SetEntPropFloat(weapon, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
	
	SetGlobalTransTarget(client);
	PrintHintText(client, "%t", "rotate info");
	
	EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
}

void Weapon_OnDrop(int client, int weapon, float flCurrentTime)
{
	SetEntProp(weapon, Prop_Send, "m_nSkin", GetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount"));
	
	Weapon_OnCreateEffect(client, weapon, EFFECT_KILL);
}

void Weapon_OnPrimaryAttack(int client, int weapon, float flCurrentTime)
{
	Weapon_OnCreateEffect(client, weapon, EFFECT_PLACE);
}

void Weapon_OnSecondaryAttack(int client, int weapon, float flCurrentTime)
{
	float flAngle = GetEntPropFloat(weapon, Prop_Send, "m_flPostponeFireReadyTime") + 0.5;
	if (flAngle > 360.0) flAngle = 0.0;
	
	SetEntPropFloat(weapon, Prop_Send, "m_flPostponeFireReadyTime", flAngle);
}

void Weapon_OnCreateEffect(int client, int weapon, int iMode)
{
	int entity = GetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity");

	switch (iMode)
	{
		case EFFECT_CREATE :
		{
			if (entity != -1)
			{
				return;
			}
		
			entity = UTIL_CreateDynamic("plan", NULL_VECTOR, NULL_VECTOR, SENTRY_BLUEPRINT_MODEL, "reject");
			
			if (entity != -1)
			{
				SetEntPropEnt(weapon, Prop_Data, "m_hEffectEntity", entity);
			}
		}

		case EFFECT_KILL : 
		{
			if (entity == -1)
			{
				return;
			}
			
			AcceptEntityInput(entity, "Kill"); 
		}
		
		default :
		{
			if (entity == -1)
			{
				return;
			}
			
			static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; bool bHit;
	
			GetClientEyePosition(client, vPosition);
			ZP_GetPlayerEyePosition(client, 120.0, 0.0, 0.0, vEndPosition);

			TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

			TR_GetEndPosition(vPosition);
			TR_GetPlaneNormal(null, vAngle);
			
			if (GetEntProp(client, Prop_Data, "m_nWaterLevel") != WLEVEL_CSGO_FULL)
			{
				if (TR_DidHit() && TR_GetEntityIndex() < 1)
				{
					bHit = true;
				}
				else
				{
					ZP_GetPlayerEyePosition(client, 120.0, 0.0, -200.0, vPosition);
			
					TR_TraceRayFilter(vEndPosition, vPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);
					
					if (TR_DidHit() && TR_GetEntityIndex() < 1)
					{
						bHit = true;
					}
					
					TR_GetEndPosition(vPosition);
					TR_GetPlaneNormal(null, vAngle);
				}
			}

			vAngle[1] += GetEntPropFloat(weapon, Prop_Send, "m_flPostponeFireReadyTime");
			
			TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);
			
			if (bHit)
			{
				static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
				static const float vMaxs[3] = {  20.0,  20.0, 72.0  }; 
				
				vPosition[2] += vMaxs[2] / 2.0; /// Move center of hull upward
				TR_TraceHull(vPosition, vPosition, vMins, vMaxs, MASK_SOLID);
				
				if (!TR_DidHit())
				{
					if (iMode == EFFECT_PLACE)
					{
						SentryGun(client, vPosition, vAngle, 
								  GetEntProp(weapon, Prop_Data, "m_iClip2"), 
								  GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount"), 
								  GetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount"), 
								  GetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount"), 
								  GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType"));
						
						ZP_RemoveWeapon(client, weapon);
						
						AcceptEntityInput(entity, "Kill");
						
						SetGlobalTransTarget(client);
						PrintHintText(client, "%t", "control info");
						
						EmitSoundToClient(client, SOUND_INFO_TIPS, SOUND_FROM_PLAYER, SNDCHAN_ITEM);
					}
					else
					{
						SetVariantString("idle");
						AcceptEntityInput(entity, "SetAnimation");
					}
				}
				else
				{
					SetVariantString("reject");
					AcceptEntityInput(entity, "SetAnimation");
				}
			}
		}
	}
}

bool Weapon_OnPickupTurret(int client, int entity, float flCurrentTime)
{
	static float vPosition[3]; static float vEndPosition[3]; bool bHit;
	
	GetClientEyePosition(client, vPosition);
	ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);

	TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

	if (!TR_DidHit())
	{
		static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
		static const float vMaxs[3] = {  20.0,  20.0, 72.0  }; 
		
		TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SOLID, ClientFilter);
	}
	
	if (TR_DidHit())
	{
		entity = TR_GetEntityIndex();
		
		int turret = -1;

		if (IsEntityTurret(entity) && IsEntitySameTeam(entity, client))
		{
			turret = GetEntProp(entity, Prop_Data, "m_iHammerID") == -1 ? GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") : entity;
		}
		
		if (turret != -1)
		{
			SentryGun sentry = view_as<SentryGun>(turret); 
	
			if (sentry.Owner == client)
			{
				int weapon = ZP_GiveClientWeapon(client, gWeapon);
				
				if (weapon != -1)
				{
					SetEntProp(weapon, Prop_Data, "m_iClip2", sentry.Health);
					SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", sentry.Ammo);
					SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", sentry.Rockets);
					SetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount", sentry.Skin);
					SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", sentry.UpgradeLevel);

					AcceptEntityInput(turret, "Kill");
					
					bHit = true;
				}
			}
		}
	}

	return bHit;
}

bool Weapon_OnMenuTurret(int client, int entity, float flCurrentTime)
{
	static float vPosition[3]; static float vEndPosition[3]; bool bHit;
	
	GetClientEyePosition(client, vPosition);
	ZP_GetPlayerEyePosition(client, 80.0, 0.0, 0.0, vEndPosition);

	TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, ClientFilter);

	if (!TR_DidHit())
	{
		static const float vMins[3] = { -20.0, -20.0, 0.0   }; 
		static const float vMaxs[3] = {  20.0,  20.0, 72.0  }; 
		
		TR_TraceHullFilter(vPosition, vEndPosition, vMins, vMaxs, MASK_SOLID, ClientFilter);
	}
	
	if (TR_DidHit())
	{
		entity = TR_GetEntityIndex();

		int turret = -1;

		if (IsEntityTurret(entity) && IsEntitySameTeam(entity, client))
		{
			turret = GetEntProp(entity, Prop_Data, "m_iHammerID") == -1 ? GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") : entity;
		}

		if (turret != -1)
		{
			SentryGun sentry = view_as<SentryGun>(turret); 
	
			if (sentry.Owner == client)
			{
				SentryMenu(client, turret);
				
				bHit = true;
			}
		}
	}
	
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
 * @param weapon            The weapon index.
 * @param weaponID          The weapon id.
 **/
public void ZP_OnWeaponCreated(int weapon, int weaponID)
{
	if (weaponID == gWeapon)
	{
		SetEntProp(weapon, Prop_Data, "m_iClip2", ZP_GetWeaponClip(gWeapon));
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", ZP_GetWeaponAmmo(gWeapon));
		SetEntProp(weapon, Prop_Data, "m_iReloadHudHintCount", ZP_GetWeaponAmmunition(gWeapon));
		SetEntProp(weapon, Prop_Data, "m_iAltFireHudHintCount", GetRandomInt(0, 1));
		SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoType", SENTRY_MODE_NORMAL);
		SetEntPropFloat(weapon, Prop_Send, "m_flPostponeFireReadyTime", 0.0);
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
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
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
	if (weaponID == gWeapon)
	{
		if (iButtons & IN_ATTACK)
		{
			_call.PrimaryAttack(client, weapon); 
			iButtons &= (~IN_ATTACK);
			return Plugin_Changed;
		}

		_call.Idle(client, weapon);

		if (iButtons & IN_ATTACK2)
		{
			_call.SecondaryAttack(client, weapon); 
			iButtons &= (~IN_ATTACK2);
			return Plugin_Changed;
		}
	}
	else
	{
		if (iButtons & IN_USE && !(iLastButtons & IN_USE))
		{
			if (ZP_IsPlayerHasWeapon(client, gWeapon) == -1)
			{
				int entity; /// Initialize index
				if (_call.PickupTurret(client, entity))
				{
					iButtons &= (~IN_USE);
					return Plugin_Changed;
				}
			}
		}
	}

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
	int entity; /// Initialize index
	if (_call.MenuTurret(client, entity))
	{
		return Plugin_Handled;
	}

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
	SDKCall(hSDKCallStudioFrameAdvance, entity); 
	
	SentryGun sentry = view_as<SentryGun>(entity); 
	
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
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		int turret = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	  
		if (turret != -1)
		{
			UTIL_SetRenderColor(turret, Color_Alpha, 255);
			//AcceptEntityInput(turret, "EnableDraw"); 
			AcceptEntityInput(turret, "EnableShadow"); 
			AcceptEntityInput(turret, "EnableReceivingFlashlight");
			
			SDKHook(turret, SDKHook_ThinkPost, SentryThinkHook);
		}
		
		AcceptEntityInput(entity, "Kill");
	}
	
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
	if (IsClientValid(attacker))
	{
		int turret = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
		if (turret != -1)
		{
			if (!IsEntitySameTeam(turret, attacker))
			{
				SentryGun sentry = view_as<SentryGun>(turret); 
		
				int iHealth = sentry.Health - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

				if (!iHealth)
				{
					SDKUnhook(entity, SDKHook_OnTakeDamage, SentryDamageHook);
					SDKUnhook(turret, SDKHook_ThinkPost, SentryThinkHook);
					
					sentry.Death();
				}
				else
				{
					sentry.Health = iHealth; 
					
					switch (GetRandomInt(0, 2))
					{
						case 0 : EmitSoundToAll("survival/turret_takesdamage_01.wav", entity, SNDCHAN_STATIC);
						case 1 : EmitSoundToAll("survival/turret_takesdamage_02.wav", entity, SNDCHAN_STATIC);
						case 2 : EmitSoundToAll("survival/turret_takesdamage_03.wav", entity, SNDCHAN_STATIC);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

/**
 * @brief Sentry touch hook.
 * 
 * @param entity            The entity index.        
 * @param target            The target index.               
 **/
public Action SentryTouchHook(int entity, int target)
{
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
	if (IsEntityTurret(target))
	{
		return Plugin_Handled;
	}
	
	static float vPosition[3];
	GetAbsOrigin(entity, vPosition);

	static char sEffect[SMALL_LINE_LENGTH];
	hCvarSentryRocketExp.GetString(sEffect, sizeof(sEffect));

	int iFlags = EXP_NOSOUND;

	if (hasLength(sEffect))
	{
		UTIL_CreateParticle(_, vPosition, _, _, sEffect, 2.0);
		iFlags |= EXP_NOFIREBALL; /// remove effect sprite
	}
	
	int turret = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"); 
	
	int attacker = hCvarSentryRewards.BoolValue && IsClientValid(owner, false) && IsEntitySameTeam(entity, owner) ? owner : turret;
	
	UTIL_CreateExplosion(vPosition, iFlags, _, hCvarSentryRocketDamage.FloatValue, hCvarSentryRocketRadius.FloatValue, "rocket", attacker, entity);

	ZP_EmitSoundToAll(gSoundShoot, SENTRY_SOUND_EXPLOAD, entity, SNDCHAN_STATIC);

	AcceptEntityInput(entity, "Kill");

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
	int entity = EntRefToEntIndex(refID);

	if (entity != -1)
	{
		RocketTouchHook(entity, 0);
	}
	
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
	if (iBits & DMG_BULLET || iBits & DMG_BLAST)
	{
		if (IsEntityTurret(attacker))
		{
			if (IsEntitySameTeam(attacker, client))
			{
				flDamage = 0.0;
			}
		} 
		else if (IsEntityRocket(inflictor))
		{
			if (IsEntitySameTeam(inflictor, client))
			{
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
	if (weaponID == gWeapon)
	{
		return Plugin_Stop; 
	}
	
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
	SentryGun sentry = view_as<SentryGun>(entity); 
			
	static char sBuffer[SMALL_LINE_LENGTH];
	static char sInfo[SMALL_LINE_LENGTH];
	int iUpgrade = GetCost(hCvarSentryControlUpgradeRatio.FloatValue);
	int iRefill = GetCost(hCvarSentryControlRefillRatio.FloatValue);
	
	IntToString(entity, sInfo, sizeof(sInfo));
	
	Menu hMenu = CreateMenu(SentryMenuSlots);

	SetGlobalTransTarget(client);

	hMenu.SetTitle("%t", "turret control", iUpgrade, "menu money", iRefill, "menu money");

	FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret level", sentry.UpgradeState + 1);
	hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iUpgrade || sentry.UpgradeState >= SENTRY_MODE_ROCKET ? false : true));
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret hp", sentry.Health);
	hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iRefill || sentry.Health >= ZP_GetWeaponClip(gWeapon) ? false : true));
	
	FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret ammo", sentry.Ammo);
	hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iRefill || sentry.Ammo >= ZP_GetWeaponAmmo(gWeapon) ? false : true));
	
	if (sentry.UpgradeLevel >= SENTRY_MODE_ROCKET)
	{
		FormatEx(sBuffer, sizeof(sBuffer), "%t", "turret rockets", sentry.Rockets);
		hMenu.AddItem(sInfo, sBuffer, GetDraw(ZP_GetClientMoney(client) < iRefill || sentry.Rockets >= ZP_GetWeaponAmmunition(gWeapon) ? false : true));
	}
	
	hMenu.ExitButton = true;
	
	hMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	hMenu.Display(client, hCvarSentryControlMenu.IntValue);
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
	switch (mAction)
	{
		case MenuAction_End :
		{
			delete hMenu;
		}

		case MenuAction_Select :
		{
			if (!IsClientValid(client, false))
			{
				return 0;
			}
				
			static char sBuffer[SMALL_LINE_LENGTH];
			hMenu.GetItem(mSlot, sBuffer, sizeof(sBuffer));
			int entity = StringToInt(sBuffer);
			
			if (IsValidEdict(entity))
			{
				int iCost = GetCost(!mSlot ? hCvarSentryControlUpgradeRatio.FloatValue : hCvarSentryControlRefillRatio.FloatValue); 
				if (ZP_GetClientMoney(client) < iCost)
				{
					return 0;
				}
		
				SentryGun sentry = view_as<SentryGun>(entity); 
		
				switch (mSlot)
				{
					case 0 :
					{
						sentry.UpgradeState++;
					}
					
					case 1 :
					{
						sentry.Health = ZP_GetWeaponClip(gWeapon);
					}
					
					case 2 :
					{
						sentry.Ammo = ZP_GetWeaponAmmo(gWeapon);
					}
					
					case 3 :
					{
						sentry.Rockets = ZP_GetWeaponAmmunition(gWeapon);
					}
				}
				
				ZP_SetClientMoney(client, ZP_GetClientMoney(client) - iCost);
				
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
	return RoundToCeil(float(ZP_GetExtraItemPrice(gItem)) * flPercentage);
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
 * @brief Validates that an entity in the same team as a given client.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 * @return                  True or false.
 **/
bool IsEntitySameTeam(int entity, int client)
{
	int iTeam = GetEntProp(entity, Prop_Data, "m_iTeamNum");
	return (iTeam == TEAM_HUMAN && ZP_IsPlayerHuman(client)) || (iTeam == TEAM_ZOMBIE && ZP_IsPlayerZombie(client));
}

/**
 * @brief Validate a turret.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
bool IsEntityTurret(int entity)
{
	if (entity <= MaxClients || !IsValidEdict(entity))
	{
		return false;
	}
	
	static char sClassname[SMALL_LINE_LENGTH];
	GetEntPropString(entity, Prop_Data, "m_iName", sClassname, sizeof(sClassname));
	
	return (!strncmp(sClassname, "turret_", 7, false));
}

/**
 * @brief Validate a rocket.
 *
 * @param entity            The entity index.
 * @return                  True or false.
 **/
bool IsEntityRocket(int entity)
{
	if (entity <= MaxClients || !IsValidEdict(entity))
	{
		return false;
	}
	
	static char sClassname[SMALL_LINE_LENGTH];
	GetEntPropString(entity, Prop_Data, "m_iGlobalname", sClassname, sizeof(sClassname));
	
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
	if (IsClientValid(entity))
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
	return false;
}

/**
 * @brief Trace filter.
 *
 * @param entity            The entity index.  
 * @param contentsMask      The contents mask.
 * @param filter            The filter index.
 * @return                  True or false.
 **/
public bool TeamFilter(int entity, int contentsMask, int filter)
{
	if (IsEntityTurret(entity)) 
	{
		return false;
	}
	
	if (IsClientValid(entity) && IsEntitySameTeam(filter, entity)) 
	{
		return false;
	}
	
	return (entity != filter); 
}
