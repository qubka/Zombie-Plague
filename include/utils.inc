/**
 * =============================================================================
 * Entity Utilities Copyright (C) 2015-2023 qubka (Nikita Ushakov).
 * =============================================================================
 *
 * This file is part of the Zombie Plague and NPC Cores.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 **/

#if defined _utils_included
 #endinput
#endif
#define _utils_included

/**
 * @section Some useful macros.
 **/
#define SMALL_LINE_LENGTH       32
#define NORMAL_LINE_LENGTH      64
#define BIG_LINE_LENGTH         128
#define CHAT_LINE_LENGTH        192
#define PLATFORM_LINE_LENGTH    256
#define HUGE_LINE_LENGTH        512
#define CONSOLE_LINE_LENGTH     1024
#define FILE_LINE_LENGTH        2048
#define TEAM_NONE               0 /**< No team yet */
#define TEAM_SPECTATOR          1 /**< Spectators  */
#define TEAM_T                  2 /**< Terrorist   */
#define TEAM_CT                 3 /**< CT          */
#define TEAM_ZOMBIE             2 /**< Zombies     */
#define TEAM_HUMAN              3 /**< Humans      */
#define SPECMODE_NONE           0
#define SPECMODE_FIRSTPERSON    4
#define SPECMODE_3RDPERSON      5
#define SPECMODE_FREELOOK       6
#define MAX_FLOAT               2147483647.0
#define MAX_INT                 2147483647
#define hasLength(%0)           (%0[0] != NULL_STRING[0]) 
/**
 * @endsection
 **/

/**
 * @section Macros for bit manipulation.
 **/
#define SetBit(%1,%2)      (%1 |= (1<<%2))
#define ClearBit(%1,%2)    (%1 &= ~(1<<%2))
#define ToogleBit(%1,%2)   (%1 ^= (1<<%2))
#define CheckBit(%1,%2)    (%1 & (1<<%2)) 
/**
 * @endsection
 **/
 
/**
 * @section Damage type values.
 **/
#define DAMAGE_NO               0
#define DAMAGE_EVENTS_ONLY      1 //! Call damage functions, but don't modify health
#define DAMAGE_YES              2
#define DAMAGE_AIM              3
/**
 * @endsection
 **/
 
/**
 * @section Water levels.
 **/
#define WLEVEL_CSGO_DRY         0
#define WLEVEL_CSGO_FEET        1
#define WLEVEL_CSGO_HALF        2
#define WLEVEL_CSGO_FULL        3
/**
 * @endsection
 **/
 
/**
 * @section Explosion flags.
 **/
#define EXP_NODAMAGE                (1<<0)
#define EXP_REPEATABLE              (1<<1)
#define EXP_NOFIREBALL              (1<<2)
#define EXP_NOSMOKE                 (1<<3)
#define EXP_NODECAL                 (1<<4)
#define EXP_NOSPARKS                (1<<5)
#define EXP_NOSOUND                 (1<<6)
#define EXP_RANDOMORIENTATION       (1<<7)
#define EXP_NOFIREBALLSMOKE         (1<<8)
#define EXP_NOPARTICLES             (1<<9)
#define EXP_NODLIGHTS               (1<<10)
#define EXP_NOCLAMPMIN              (1<<11)
#define EXP_NOCLAMPMAX              (1<<12)
#define EXP_NOUNDERWATER            (1<<13)
#define EXP_GENERICDAMAGE           (1<<14)
/**
 * @endsection
 **/

/**
 * @section Train flags.
 **/ 
#define TRAIN_NOPITCH               (1<<0)
#define TRAIN_NOCONTROL             (1<<1)
#define TRAIN_PASSABLE              (1<<2)
#define TRAIN_FIXED                 (1<<3)
#define TRAIN_HL1TRAIN              (1<<7)
#define TRAIN_USESPEEDFORSOUND      (1<<8)
#define TRAIN_UNBLOCKABLE           (1<<9)
#define TRAIN_ALLOWROLL             (1<<10) 
/**
 * @endsection
 **/
 
/**
 * @section Path flags.
 **/
#define PATH_DISABLED               (1<<0)
#define PATH_FIREONE                (1<<1)
#define PATH_BRANCHRESERVE          (1<<2)
#define PATH_DISABLETRAIN           (1<<3)
#define PATH_TELEPORTTOTHIS         (1<<4)
/** 
 * @endsection  
 **/    
	
/** 
 * @section NPC flags.  
 **/    
#define NPC_WAITTILLSEEN            (1<<0)
#define NPC_GAG                     (1<<1)
#define NPC_FALLTOGROUND            (1<<2)
#define NPC_DROPHEALTHKIT           (1<<3)
#define NPC_EFFICIENT               (1<<4)
#define NPC_WAITFORSCRIPT           (1<<7)
#define NPC_LONGVISIBILITY          (1<<8)
#define NPC_FADECORPSE              (1<<9)
#define NPC_OUTSIDEPVS              (1<<10)
#define NPC_TEMPLATE                (1<<11)
#define NPC_ALTCOLLISION            (1<<12)
#define NPC_DONTDROPWEAPONS         (1<<13)
#define NPC_IGNOREPLAYERPUSH        (1<<14)
/**
 * @endsection
 **/

/**
 * @section Physics flags.
 **/
#define PHYS_STARTASLEEP            (1<<0)
#define PHYS_NOPHYSDAMAGE           (1<<1)
#define PHYS_DEBRIS                 (1<<2)
#define PHYS_MOTIONDISABLED         (1<<3)
#define PHYS_MOTIONONCANNON         (1<<6)
#define PHYS_NOTAFFECTBYROTOR       (1<<7)
#define PHYS_GENERATEUSE            (1<<8)
#define PHYS_PREVENTPICKUP          (1<<9)
#define PHYS_PREVENTBUMP            (1<<10)
#define PHYS_DEBRISTRIGGER          (1<<12)
#define PHYS_FORCESERVERSIDE        (1<<13)
#define PHYS_PHYSGUNALWAYS          (1<<20)    
/**
 * @endsection
 **/

/**
 * @section Dynamic flags.
 **/
#define DYN_HITBOXCOLLISION         (1<<6)
#define DYN_COLLISIONDISABLED       (1<<7)
/**
 * @endsection
 **/
 
/**
 * @section Beam flags.
 **/
#define BEAM_STARTON                (1<<0)
#define BEAM_TOGGLE                 (1<<1)
#define BEAM_RANDOMSTRIKE           (1<<2)
#define BEAM_RING                   (1<<3)
#define BEAM_STARTSPARKS            (1<<4)
#define BEAM_ENDSPARKS              (1<<5)
#define BEAM_DECALEND               (1<<6)
#define BEAM_SHADESTART             (1<<7)
#define BEAM_SHADEEND               (1<<8)
#define BEAM_TAPEROUT               (1<<9)
/**
 * @endsection
 **/
 
/**
 * @section Light flags.
 **/
#define LIGHT_NOWORLD               (1<<0)
#define LIGHT_NOMODELS              (1<<1)
#define LIGHT_ADDALPHA              (1<<2)
#define LIGHT_SUBALPHA              (1<<3)
/**
 * @endsection
 **/

/**
 * @section Addon bits.
 **/
#define CSAddon_NONE                0
#define CSAddon_Flashbang1          (1<<0)
#define CSAddon_Flashbang2          (1<<1)
#define CSAddon_HEGrenade           (1<<2)
#define CSAddon_SmokeGrenade        (1<<3)
#define CSAddon_C4                  (1<<4)
#define CSAddon_DefuseKit           (1<<5)
#define CSAddon_PrimaryWeapon       (1<<6)
#define CSAddon_SecondaryWeapon     (1<<7)
#define CSAddon_Holster             (1<<8) 
#define CSAddon_Decoy               (1<<9)
#define CSAddon_Knife               (1<<10)
#define CSAddon_FaceMask            (1<<11)
#define CSAddon_TaGrenade           (1<<12)
#define CSAddon_Shield              (1<<13)
/**
 * @endsection
 **/
 
/**
 * @section Hud elements flags.
 **/
#define HIDEHUD_WEAPONSELECTION     (1<<0) /// Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT          (1<<1) 
#define HIDEHUD_ALL                 (1<<2) 
#define HIDEHUD_HEALTH              (1<<3) /// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD          (1<<4) /// Hide when local player's dead
#define HIDEHUD_NEEDSUIT            (1<<5) /// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS          (1<<6) /// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT                (1<<7) /// Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR           (1<<8) /// Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR   (1<<9) /// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE           (1<<10 
#define HIDEHUD_BONUS_PROGRESS      (1<<11 /// Hide bonus progress display (for bonus map challenges)
/**
 * @endsection
 **/
 
/**
 * @section Entity effects flags.
 **/
#define EF_BONEMERGE                (1<<0) /// Performs bone merge on client side
#define EF_BRIGHTLIGHT              (1<<1) /// DLIGHT centered at entity origin
#define EF_DIMLIGHT                 (1<<2) /// Player flashlight
#define EF_NOINTERP                 (1<<3) /// Don't interpolate the next frame
#define EF_NOSHADOW                 (1<<4) /// Disables shadow
#define EF_NODRAW                   (1<<5) /// Prevents the entity from drawing and networking
#define EF_NORECEIVESHADOW          (1<<6) /// Don't receive shadows
#define EF_BONEMERGE_FASTCULL       (1<<7) /// For use with EF_BONEMERGE. If this is set, then it places this ents origin at its parent and uses the parent's bbox + the max extents of the aiment. Otherwise, it sets up the parent's bones every frame to figure out where to place the aiment, which is inefficient because it'll setup the parent's bones even if the parent is not in the PVS.
#define EF_ITEM_BLINK               (1<<8) /// Makes the entity blink
#define EF_PARENT_ANIMATES          (1<<9) /// Always assume that the parent entity is animating
#define EF_FOLLOWBONE               (1<<10)    
/**
 * @endsection
 **/
 
 /**
 * @section Fade flags.
 **/
#define FFADE_IN                    0x0001 /// Just here so we don't pass 0 into the function
#define FFADE_OUT                   0x0002 /// Fade out (not in)
#define FFADE_MODULATE              0x0004 /// Modulate (don't blend)
#define FFADE_STAYOUT               0x0008 /// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE                 0x0010 /// Purges all other fades, replacing them with this one
/**
 * @endsection
 **/
 
/**
 * @section Solid types.
 **/
#define SOLID_NONE                  0  /// no solid model 
#define SOLID_BSP                   1  /// BSP tree 
#define SOLID_BBOX                  2  /// an AABB 
#define SOLID_OBB                   3  /// an OBB 
#define SOLID_OBB_YAW               4  /// an OBB, constrained so that it can only yaw 
#define SOLID_CUSTOM                5  /// always call into the entity for tests 
#define SOLID_VPHYSICS              6  /// solid vphysics object, get vcollide from the model and collide with that 
#define SOLID_LAST                  7  /// custom solid last
/**
 * @endsection
 **/

/**
 * @section Collision groups.
 **/
#define COLLISION_GROUP_NONE                0   /// Default; collides with static and dynamic objects. 
#define COLLISION_GROUP_DEBRIS              1   /// Collides with nothing but world and static stuff. 
#define COLLISION_GROUP_DEBRIS_TRIGGER      2   /// Same as debris, but hits triggers. 
#define COLLISION_GROUP_INTERACTIVE_DEBRIS  3   /// Collides with everything except other interactive debris or debris. 
#define COLLISION_GROUP_INTERACTIVE         4   /// Collides with everything except interactive debris or debris. 
#define COLLISION_GROUP_PLAYER              5   /// This is the default behavior expected for most prop_physics. 
#define COLLISION_GROUP_BREAKABLE_GLASS     6   /// Special group for glass debris. 
#define COLLISION_GROUP_VEHICLE             7   /// Collision group for driveable vehicles. 
#define COLLISION_GROUP_PLAYER_MOVEMENT     8   /// For HL2, same as Collision_Group_Player. 
#define COLLISION_GROUP_NPC                 9   /// Generic NPC group. 
#define COLLISION_GROUP_IN_VEHICLE          10  /// For any entity inside a vehicle. 
#define COLLISION_GROUP_WEAPON              11  /// For any weapons that need collision detection. 
#define COLLISION_GROUP_VEHICLE_CLIP        12  /// Vehicle clip brush to restrict vehicle movement. 
#define COLLISION_GROUP_PROJECTILE          13  /// Projectiles. 
#define COLLISION_GROUP_DOOR_BLOCKER        14  /// Blocks entities not permitted to get near moving doors. 
#define COLLISION_GROUP_PASSABLE_DOOR       15  /// Doors that the player shouldn't collide with. 
#define COLLISION_GROUP_DISSOLVING          16  /// Things that are dissolving are in this group. 
#define COLLISION_GROUP_PUSHAWAY            17  /// Nonsolid on client and server, pushaway in player code. 
#define COLLISION_GROUP_NPC_ACTOR           18  /// Used so NPCs in scripts ignore the player.
/**
 * @endsection
 **/

/**
 * @section Solid flags.
 **/
#define FSOLID_CUSTOMRAYTEST                0x0001 /// Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST                0x0002 /// Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID                    0x0004 /// Are we currently not solid?
#define FSOLID_TRIGGER                      0x0008 /// This is something may be collideable but fires touch functions
#define FSOLID_NOT_STANDABLE                0x0010 /// You can't stand on this
#define FSOLID_VOLUME_CONTENTS              0x0020 /// Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED          0x0040 /// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS           0x0080 /// Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED          0x0100 /// Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS         0x0200 /// This trigger will touch debris objects
/**
 * @endsection
 **/
 
/**
 * @section Material types.
 **/ 
#define MAT_NONE       "-1"
#define MAT_GLASS       "0"
#define MAT_WOOD        "1"
#define MAT_METAL       "2"
#define MAT_FLESH       "3"    
#define MAT_CONCRETE    "4"    
/**
 * @endsection
 **/

/**
 * @section Default sounds.
 **/
#define SOUND_CLIP_EMPTY            "weapons/clipempty_rifle.wav"
#define SOUND_BUTTON_CMD_ERROR      "buttons/button10.wav"
#define SOUND_BUTTON_MENU_ERROR     "buttons/button11.wav"
#define SOUND_FLASHLIGHT            "items/flashlight1.wav"
#define SOUND_NVG_ON                "items/nvg_on.wav"
#define SOUND_NVG_OFF               "items/nvg_off.wav"
#define SOUND_AMMO                  "items/pickup_ammo_01.wav"
#define SOUND_ITEM                  "items/itempickup.wav"
#define SOUND_ARMOR                 "survival/armor_pickup_01.wav"
#define SOUND_LEVELUP               "survival/bonus_award_01.wav"
#define SOUND_INFO_TIPS             "survival/info_tips_01.wav"
#define SOUND_BUY_ITEM              "survival/buy_item_01.wav"
#define SOUND_BUY_ITEM_FAILED       "survival/buy_item_failed_01.wav"
/**
 * @endsection
 **/ 

/** 
 * @section Number of valid def indexes.
 *
 * @link https://tf2b.com/itemlist.php?gid=730
 **/
enum ItemDef
{
	ItemDef_Invalid = 0,          /** Used as return value when a def doens't exist. */

	ItemDef_Deagle = 1,
	ItemDef_Elite,
	ItemDef_FiveSeven,
	ItemDef_Glock,
	ItemDef_AK47 = 7,
	ItemDef_AUG,
	ItemDef_AWP,
	ItemDef_Famas,
	ItemDef_G3SG1,
	ItemDef_GalilAR = 13,
	ItemDef_M249,
	ItemDef_M4A4 = 16,
	ItemDef_MAC10,
	ItemDef_P90 = 19,
	ItemDef_RepulsorDevice,
	ItemDef_MP5 = 23,
	ItemDef_UMP45,
	ItemDef_XM1014,
	ItemDef_Bizon,
	ItemDef_MAG7,
	ItemDef_Negev,
	ItemDef_SawedOff,
	ItemDef_TEC9,
	ItemDef_Taser,
	ItemDef_HKP2000,
	ItemDef_MP7,
	ItemDef_MP9,
	ItemDef_Nova,
	ItemDef_P250,
	ItemDef_Shield,
	ItemDef_SCAR20,
	ItemDef_SG553,
	ItemDef_SSG08,
	ItemDef_Knife,
	ItemDef_KnifeGG,
	ItemDef_FlashBang,
	ItemDef_HEGrenade,
	ItemDef_SmokeGrenade,
	ItemDef_Molotov,
	ItemDef_Decoy,
	ItemDef_IncGrenade,
	ItemDef_C4,
	ItemDef_Kevlar,
	ItemDef_KevlarHelmet,
	ItemDef_HeavySuit,
	ItemDef_NGVs = 54,
	ItemDef_Defuser,
	ItemDef_Cutters,
	ItemDef_Healthshot,
	ItemDef_KnifeT = 59,
	ItemDef_M4A1,
	ItemDef_USP,
	ItemDef_CZ75A = 63,
	ItemDef_Revolver,
	ItemDef_TAGrenade = 68,
	ItemDef_Fists,
	ItemDef_BreachCharge,
	ItemDef_Tablet = 72,
	ItemDef_Melee = 74,
	ItemDef_Axe,
	ItemDef_Hammer,
	ItemDef_Wrench = 78,
	ItemDef_KnifeGhost = 80,
	ItemDef_FireBomb,
	ItemDef_DiversionDevice,
	ItemDef_FragGrenade,
	ItemDef_SnowBall,
	ItemDef_BumpMine,
	ItemDef_Bayonet = 500,
	ItemDef_ClassicKnife = 503,
	ItemDef_FlipKnife = 505,
	ItemDef_GutKnife = 506,
	ItemDef_Karambit = 507,
	ItemDef_M9_Bayonet = 508,
	ItemDef_HuntsmanKnife = 509,
	ItemDef_FalchionKnife = 512,
	ItemDef_BowieKnife = 514,
	ItemDef_ButterflyKnife = 515,
	ItemDef_ShadowDaggers = 516,
	ItemDef_ParacordKnife = 517,
	ItemDef_SurvivalKnife = 517,
	ItemDef_UrsusKnife = 519,
	ItemDef_NavajaKnife = 520,
	ItemDef_NomadKnife = 521,
	ItemDef_StilettoKnife = 522,
	ItemDef_TalonKnife = 523,
	ItemDef_SkeletonKnife = 525
};
#define IsGrenade(%0)       (%0 == ItemDef_TAGrenade || %0 == ItemDef_HEGrenade || %0 == ItemDef_SmokeGrenade || %0 == ItemDef_FlashBang || %0 == ItemDef_BreachCharge || (%0 >= ItemDef_Molotov && %0 <= ItemDef_IncGrenade) || (%0 >= ItemDef_FireBomb && %0 <= ItemDef_BumpMine))
#define IsProjectile(%0)    (%0 == ItemDef_TAGrenade || %0 == ItemDef_HEGrenade || %0 == ItemDef_SmokeGrenade || %0 == ItemDef_FlashBang || (%0 >= ItemDef_Molotov && %0 <= ItemDef_IncGrenade) || (%0 >= ItemDef_FireBomb && %0 <= ItemDef_FragGrenade))
#define IsFireble(%0)       (%0 == ItemDef_Molotov || %0 == ItemDef_IncGrenade || %0 == ItemDef_FireBomb)
#define IsKnife(%0)         (%0 == ItemDef_Knife || %0 == ItemDef_KnifeGG || %0 == ItemDef_KnifeT || (%0 >= ItemDef_Melee && %0 <= ItemDef_Wrench) || %0 == ItemDef_KnifeGhost || (%0 >= ItemDef_Bayonet))
#define IsMelee(%0)         (IsKnife(%0) || %0 == ItemDef_Fists)
#define IsItem(%0)          (%0 == ItemDef_Kevlar || %0 == ItemDef_KevlarHelmet || %0 == ItemDef_NGVs || %0 == ItemDef_Defuser || %0 == ItemDef_HeavySuit || %0 == ItemDef_Cutters)
#define IsGun(%0)           ((%0 >= ItemDef_Deagle && %0 <= ItemDef_SSG08 && %0 != ItemDef_RepulsorDevice && %0 != ItemDef_Shield) || (%0 >= ItemDef_M4A1 && %0 <= ItemDef_Revolver))
/**
 * @endsection
 **/

/**
 * @section List of operation systems.
 **/
enum EngineOS
{
	OS_Unknown,
	OS_Windows,
	OS_Linux
};
/**
 * @endsection
 **/
 
/**
 * @section Number of valid render types.
 **/
enum ColorType     
{
	Color_Red,
	Color_Green,
	Color_Blue,
	Color_Alpha
};
/**
 * @endsection
 **/ 
 
/**
 * @brief Create a train entity.
 * 
 * @param sClassname        The classname string.
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param sPath             The name of the first path_track in the train's path.
 * @param sSpeed            The maximum speed that this train can move.
 * @param sSound            (Optional) The sound path.
 * @param iFlags            (Optional) The bits with some flags.
 *
 * @return                  The entity index.                       
 **/
stock int UTIL_CreateTrain(char[] sClassname, float vPosition[3], float vAngle[3], char[] sPath, char[] sSpeed, char[] sSound = "", int iFlags = 0)
{
	int entity = CreateEntityByName("func_tracktrain"); 
	
	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));

		DispatchKeyValueVector(entity, "origin", vPosition); 
		DispatchKeyValueVector(entity, "angles", vAngle); 
		DispatchKeyValue(entity, "targetname", sClassname);
		DispatchKeyValue(entity, "target", sPath);
		DispatchKeyValue(entity, "startspeed", sSpeed);
		DispatchKeyValue(entity, "speed", sSpeed);
		DispatchKeyValue(entity, "wheels", "256");         /// Make moving smoother
		DispatchKeyValue(entity, "bank", "20");            /// Make turning smoother
		DispatchKeyValue(entity, "orientationtype", "2");  /// Linear blend, adds some smoothness
		DispatchKeyValue(entity, "spawnflags", sFlags);  
		if (hasLength(sSound)) DispatchKeyValue(entity, "MoveSound", sSound);
		
		UTIL_SetRenderColor(entity, Color_Alpha, 0);
		
		DispatchSpawn(entity);
	}

	return entity;
}

/**
 * @brief Create a path entity.
 * 
 * @param sClassname        The classname string.
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param sNextTarget       The next '_track' in the path.
 * @param iFlags            (Optional) The bits with some flags.
 *
 * @return                  The entity index.                       
 **/
stock int UTIL_CreatePath(char[] sClassname, float vPosition[3], float vAngle[3], char[] sNextTarget, int iFlags = 0)
{
	int entity = CreateEntityByName("path_track");
	
	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));

		DispatchKeyValueVector(entity, "origin", vPosition); 
		DispatchKeyValueVector(entity, "angles", vAngle); 
		DispatchKeyValue(entity, "targetname", sClassname);
		DispatchKeyValue(entity, "target", sNextTarget);
		DispatchKeyValue(entity, "spawnflags", sFlags); 
		
		DispatchSpawn(entity);

		ActivateEntity(entity);  
	}
	
	return entity;
}

/**
 * @brief Create a monster entity.
 * 
 * @param sClassname        The classname string.
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param sModel            The model path.
 * @param iFlags            (Optional) The bits with some flags.
 *
 * @return                  The entity index.                         
 **/
stock int UTIL_CreateMonster(char[] sClassname, float vPosition[3], float vAngle[3], char[] sModel, int iFlags = 0)
{
	int entity = CreateEntityByName("monster_generic"); 
		
	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));

		DispatchKeyValue(entity, "targetname", sClassname);
		DispatchKeyValueVector(entity, "origin", vPosition); 
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValue(entity, "model", sModel); 
		DispatchKeyValue(entity, "spawnflags", sFlags); 

		DispatchSpawn(entity);
		
		SetEntProp(entity, Prop_Data, "m_bloodColor", -1);
	}
	
	return entity;
}

/**
 * @brief Create a physics entity.
 * 
 * @param sClassname        The classname string.
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param sModel            The model path.
 * @param iFlags            (Optional) The bits with some flags.
 *
 * @return                  The entity index.                       
 **/
stock int UTIL_CreatePhysics(char[] sClassname, float vPosition[3], float vAngle[3], char[] sModel, int iFlags = 0)
{
	int entity = CreateEntityByName("prop_physics_multiplayer"); 

	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));
	
		DispatchKeyValue(entity, "targetname", sClassname);
		DispatchKeyValueVector(entity, "origin", vPosition);
		DispatchKeyValueVector(entity, "angles", vAngle); 
		DispatchKeyValue(entity, "model", sModel);
		DispatchKeyValue(entity, "spawnflags", sFlags);
		
		DispatchSpawn(entity);
	}
	
	return entity;
}

/**
 * @brief Create a dynamic entity.
 * 
 * @param sClassname        The classname string.
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param sModel            The model path.
 * @param sDefaultAnim      (Optional) The default animation.
 * @param bOverride         (Optional) True for models with physics, false for fully dynamic models.
 * @param bHoldAnim         (Optional) If set, the prop will not loop its animation, but hold the last frame.
 * @param bSolid            (Optional) If set, the prop will be solid.
 * @param iFlags            (Optional) The bits with some flags.
 *
 * @return                  The entity index.                       
 **/
stock int UTIL_CreateDynamic(char[] sClassname, float vPosition[3], float vAngle[3], char[] sModel, char[] sDefaultAnim = "", bool bOverride = true, bool bHoldAnim = false, bool bSolid = false, int iFlags = DYN_COLLISIONDISABLED)
{
	int entity = CreateEntityByName(bOverride ? "prop_dynamic_override" : "prop_dynamic");

	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));

		DispatchKeyValue(entity, "targetname", sClassname);
		DispatchKeyValueVector(entity, "origin", vPosition); 
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValue(entity, "model", sModel);
		DispatchKeyValue(entity, "spawnflags", sFlags);
		DispatchKeyValue(entity, "solid", bSolid ? "1" : "0");
		DispatchKeyValue(entity, "HoldAnimation", bHoldAnim ? "1" : "0");
		if (hasLength(sDefaultAnim)) DispatchKeyValue(entity, "DefaultAnim", sDefaultAnim);
		
		DispatchSpawn(entity);
	}
	
	return entity;
}

/**
 * @brief Create a projectile entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param weaponID          (Optional) The weapon index or -1 for unspecified.
 * @param sModel            (Optional) The model path.
 *
 * @return                  The entity index.                       
 **/
stock int UTIL_CreateProjectile(float vPosition[3], float vAngle[3], int weaponID = -1, char[] sModel = "")
{
	int entity = CreateEntityByName("hegrenade_projectile");

	if (entity != -1)
	{
		SetEntProp(entity, Prop_Data, "m_iHammerID", weaponID);
		SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1);
	
		DispatchSpawn(entity);
		
		TeleportEntity(entity, vPosition, vAngle, NULL_VECTOR);

		if (hasLength(sModel)) SetEntityModel(entity, sModel);
	}

	return entity;
}

/**
 * @brief Create a stack of the smoke entity.
 * 
 * @param parent            (Optional) The parent index.
 * @param vPosition         (Optional) The position to the spawn.
 * @param vAngle            (Optional) The angle to the spawn.
 * @param sAttach           (Optional) The attachment name.
 * @param sSpreadBase       (Optional) The amount of random spread in the origins of the smoke particles when they're spawned.     
 * @param sSpreadSpeed      (Optional) The amount of random spread in the velocity of the smoke particles after they're spawned.
 * @param sSpeed            (Optional) The speed at which the smoke particles move after they're spawned.
 * @param sStartSize        (Optional) The size of the smoke particles when they're first emitted.
 * @param sEndSize          (Optional) The size of the smoke particles at the point they fade out completely.
 * @param sDensity          (Optional) The rate at which to emit smoke particles (i.e. particles to emit per second).
 * @param sLength           (Optional) The length of the smokestack. Lifetime of the smoke particles is derived from this & particle speed.
 * @param sTwist            (Optional) The amount, in degrees per second, that the smoke particles twist around the origin.
 * @param sColor            The color of the light. (RGB)
 * @param sTransparency     The amount of an alpha (0-255)
 * @param sSpriteName       The sprite path.
 * @param flRemoveTime      (Optional) The removing of the smoke.
 * @param flDurationTime    (Optional) The duration of the smoke.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateSmoke(int parent = -1, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sSpreadBase = "100", char[] sSpreadSpeed = "70", char[] sSpeed = "80", char[] sStartSize = "200", char[] sEndSize = "2", char[] sDensity = "30", char[] sLength = "400", char[] sTwist = "20", char[] sColor, char[] sTransparency, char[] sSpriteName, float flRemoveTime = 0.0, float flDurationTime = 0.0)
{
	int entity = CreateEntityByName("env_smokestack");

	if (entity != -1)
	{
		DispatchKeyValueVector(entity, "origin", vPosition); 
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValue(entity, "BaseSpread", sSpreadBase);
		DispatchKeyValue(entity, "SpreadSpeed", sSpreadSpeed);
		DispatchKeyValue(entity, "Speed", sSpeed);
		DispatchKeyValue(entity, "StartSize", sStartSize);
		DispatchKeyValue(entity, "EndSize", sEndSize);
		DispatchKeyValue(entity, "Rate", sDensity);
		DispatchKeyValue(entity, "JetLength", sLength);
		DispatchKeyValue(entity, "Twist", sTwist); 
		DispatchKeyValue(entity, "RenderColor", sColor);
		DispatchKeyValue(entity, "RenderAmt", sTransparency); 
		DispatchKeyValue(entity, "SmokeMaterial", sSpriteName);
		
		DispatchSpawn(entity);

		AcceptEntityInput(entity, "TurnOn");
		
		if (parent != -1)
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", parent, entity);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (strlen(sAttach))
			{ 
				SetVariantString(sAttach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}

		if (flDurationTime > 0.0 && flRemoveTime > 0.0)
		{
			static char sFlags[SMALL_LINE_LENGTH];
			FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:TurnOff::%f:1", flRemoveTime);
			
			SetVariantString(sFlags);
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser2");
			
			UTIL_RemoveEntity(entity, flDurationTime);
		}
	}
	
	return entity;
}

/**
 * @brief Create a particle entity.
 * 
 * @param parent            (Optional) The parent index.
 * @param vPosition         (Optional) The origin of the spawn.
 * @param vAngle            (Optional) The angle to the spawn.
 * @param sAttach           (Optional) The attachment name.
 * @param sEffect           The particle name.
 * @param flDurationTime    (Optional) The duration of an effect.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateParticle(int parent = -1, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sEffect, float flDurationTime = 0.0)
{
	int entity = CreateEntityByName("info_particle_system");
	
	if (entity != -1)
	{
		DispatchKeyValueVector(entity, "origin", vPosition);
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValue(entity, "start_active", "1");
		DispatchKeyValue(entity, "effect_name", sEffect);
		
		DispatchSpawn(entity);

		if (parent != -1)
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", parent, entity);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (strlen(sAttach))
			{ 
				SetVariantString(sAttach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}
		
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Start");
		
		if (flDurationTime > 0.0)
		{
			UTIL_RemoveEntity(entity, flDurationTime);
		}
	}
	
	return entity;
}

/**
 * @brief Create an explosion entity.
 *
 * @param vPosition         The position to the spawn.
 * @param vAngle            (Optional) The angle to the spawn.
 * @param iFlags            (Optional) The bits with some flags.
 * @param sSpriteName       (Optional) The sprite path.
 * @param flDamage          (Optional) The amount of damage done by the explosion.
 * @param flRadius          (Optional) If set, the radius in which the explosion damages entities. If unset, the radius will be based on the magnitude.
 * @param sWeapon           (Optional) The classname defines the type of entity.
 * @param attacker          (Optional) The attacker index.
 * @param inflictor         (Optional) The inflictor index.
 * @param sIgnore           (Optional) Do not harm or affect the named entity.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateExplosion(float vPosition[3]/*, float vAngle[3] = NULL_VECTOR*/, int iFlags = 0, char[] sSpriteName = "materials/sprites/xfireball3.vmt", float flDamage = 0.0, float flRadius = 0.0, char[] sWeapon = "", int attacker = -1, int inflictor = -1, char[] sIgnore = "")
{
	int entity = CreateEntityByName("env_explosion");

	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));
		
		DispatchKeyValueVector(entity, "origin", vPosition);
		DispatchKeyValue(entity, "spawnflags", sFlags);
		DispatchKeyValue(entity, "fireballsprite", sSpriteName);
		if (!(iFlags & EXP_NODAMAGE))
		{
			DispatchKeyValue(entity, "classname", sWeapon);
			IntToString(RoundToNearest(flDamage), sFlags, sizeof(sFlags));
			DispatchKeyValue(entity, "iMagnitude", sFlags);
			IntToString(RoundToNearest(flRadius), sFlags, sizeof(sFlags));
			DispatchKeyValue(entity, "iRadiusOverride", sFlags);
			if (hasLength(sIgnore)) DispatchKeyValue(entity, "ignoredEntity", sIgnore);
		}
		
		DispatchSpawn(entity);

		if (attacker != -1)
		{
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", attacker);
		}
			
		if (inflictor != -1)
		{
			SetEntPropEnt(entity, Prop_Data, "m_hInflictor", inflictor);
		}
		
		AcceptEntityInput(entity, "Explode");

		AcceptEntityInput(entity, "Kill");
	}
	
	return entity;
}

/**
 * @brief Create a point hurt entity.
 * 
 * @param parent            (Optional) The parent index. 
 * @param vPosition         (Optional) The origin of the spawn.
 * @param attacker          The attacker index.
 * @param flDamage          The amount of damage inflicted.
 * @param flRadius          The radius in which the hurt damages entities.
 * @param iBits             (Optional) The ditfield of damage types. 
 * @param weaponID          (Optional) The weapon index or -1 for unspecified.
 * @param sAttach           (Optional) The attachment name.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateDamage(int parent = -1, float vPosition[3] = NULL_VECTOR, int attacker, float flDamage, float flRadius, int iBits = DMG_GENERIC, int weaponID = -1, char[] sAttach = "")
{
	int entity = CreateEntityByName("point_hurt");           

	if (entity != -1)
	{
		static char sDamage[SMALL_LINE_LENGTH];
		
		/*
		 * The specified amount of damage will be halved. 
		 * Consider multiplying your amount of damage by 2 and using it as the Value.
		 */
		
		IntToString(RoundToNearest(flDamage) * 2, sDamage, sizeof(sDamage));
		DispatchKeyValue(entity, "Damage", sDamage);
		IntToString(iBits, sDamage, sizeof(sDamage));
		DispatchKeyValue(entity, "DamageType", sDamage);
		DispatchKeyValueFloat(entity, "Radius", flRadius);
		
		DispatchSpawn(entity);      
		TeleportEntity(entity, vPosition, NULL_VECTOR, NULL_VECTOR);
		
		SetEntProp(entity, Prop_Data, "m_iHammerID", weaponID);

		if (parent != -1)
		{
			SetVariantString("!activator"); 
			AcceptEntityInput(entity, "SetParent", parent, entity); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (hasLength(sAttach))
			{ 
				SetVariantString(sAttach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}

		AcceptEntityInput(entity, "Hurt", attacker);  
		
		AcceptEntityInput(entity, "Kill"); 
	}   
	
	return entity;
}  

/**
 * @brief Create a sprite entity.
 * 
 * @param parent            (Optional) The parent index. 
 * @param vPosition         (Optional) The origin of the spawn.
 * @param vAngle            (Optional) The angle to the spawn.
 * @param sAttach           (Optional) The attachment name.
 * @param sSprite           The sprite path.
 * @param sScale            The scale multiplier of the sprite.
 * @param sRender           Set a non-standard rendering mode on this entity.
 * @param flDurationTime    (Optional) The duration of the beam.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateSprite(int parent = -1, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sSprite, char[] sScale, char[] sRender, float flDurationTime = 0.0)
{
	int entity = CreateEntityByName("env_sprite");
	
	if (entity != -1)
	{
		DispatchKeyValueVector(entity, "origin", vPosition);
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValue(entity, "model", sSprite);
		DispatchKeyValue(entity, "scale", sScale);
		DispatchKeyValue(entity, "rendermode", sRender);
		
		DispatchSpawn(entity);
		
		ActivateEntity(entity);
		
		if (parent != -1)
		{
			SetVariantString("!activator"); 
			AcceptEntityInput(entity, "SetParent", parent, entity); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (hasLength(sAttach))
			{ 
				SetVariantString(sAttach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}
		
		if (flDurationTime > 0.0)
		{
			UTIL_RemoveEntity(entity, flDurationTime);
		}
	}

	return entity;
}

/**
 * @brief Create a material controlller entity.
 * 
 * @param parent            The parent index. 
 * @param sSprite           The sprite path.
 * @param sVar              The name of the shader parameter you want to modify.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateSpriteController(int parent, char[] sSprite, char[] sVar)
{
	int entity = CreateEntityByName("material_modify_control");
	
	if (entity != -1)
	{
		DispatchKeyValue(entity, "materialName", sSprite);
		DispatchKeyValue(entity, "materialVar", sVar);
		
		DispatchSpawn(entity);

		if (parent != -1)
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", parent, entity);
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
		}
	}
	
	return entity;
}

/**
 * @brief Create a tesla entity.
 * 
 * @param parent            (Optional) The parent index. 
 * @param vPosition         (Optional) The origin of the spawn.
 * @param vAngle            (Optional) The angle to the spawn.
 * @param sAttach           (Optional) The attachment name.
 * @param sRadius           (Optional) The radius around the origin to find a point to strike with a tesla lightning beam.
 * @param sSound            (Optional) The sound to be played whenever lightning is created.
 * @param sCountMin         (Optional) The minimum number of tesla lightning beams to create when creating an arc.
 * @param sCountMax         (Optional) The maximum number of tesla lightning beams to create when creating an arc.
 * @param sTextureName      (Optional) The material to use for the tesla lightning beams.
 * @param sColor            (Optional) The beam color.
 * @param sThickMin         (Optional) The minimum width of the tesla lightning beams.
 * @param sThinkMax         (Optional) The maximum width of the tesla lightning beams.
 * @param sLifeMin          (Optional) The minimum lifetime of the tesla lightning beams.
 * @param sLifeMax          (Optional) The maximum lifetime of the tesla lightning beams.
 * @param sIntervalMin      (Optional) The minimum time delay between random arcing.
 * @param sIntervalMax      (Optional) The maximum time delay between random arcing.
 * @param flDurationTime    (Optional) The duration of the beam.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateTesla(int parent = -1, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sRadius = "500.0", char[] sSound = "DoSpark", char[] sCountMin = "42", char[] sCountMax = "62", char[] sTextureName = "materials/sprites/physbeam.vmt", char[] sColor = "255 255 255", char[] sThickMin = "10.0", char[] sThickMax = "11.0", char[] sLifeMin = "0.3", char[] sLifeMax = "0.3", char[] sIntervalMin = "0.1", char[] sIntervalMax = "0.2", float flDurationTime = 0.0)
{
	int entity = CreateEntityByName("point_tesla");

	if (entity != -1)
	{
		DispatchKeyValueVector(entity, "origin", vPosition);
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValue(entity, "m_flRadius", sRadius);  
		DispatchKeyValue(entity, "m_SoundName", sSound);  
		DispatchKeyValue(entity, "beamcount_min", sCountMin);  
		DispatchKeyValue(entity, "beamcount_max", sCountMax);
		DispatchKeyValue(entity, "texture", sTextureName);  
		DispatchKeyValue(entity, "m_Color", sColor);  
		DispatchKeyValue(entity, "thick_min", sThickMin);     
		DispatchKeyValue(entity, "thick_max", sThickMax);     
		DispatchKeyValue(entity, "lifetime_min", sLifeMin);  
		DispatchKeyValue(entity, "lifetime_max", sLifeMax);  
		DispatchKeyValue(entity, "interval_min", sIntervalMin);     
		DispatchKeyValue(entity, "interval_max", sIntervalMax);   

		DispatchSpawn(entity);

		ActivateEntity(entity);
		AcceptEntityInput(entity, "TurnOn");     
		AcceptEntityInput(entity, "DoSpark");    

		if (parent != -1)
		{
			SetVariantString("!activator"); 
			AcceptEntityInput(entity, "SetParent", parent, entity); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (hasLength(sAttach))
			{ 
				SetVariantString(sAttach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}
		
		if (flDurationTime > 0.0)
		{
			UTIL_RemoveEntity(entity, flDurationTime);
		}
	}

	return entity;
}

/**
 * @brief Create a shooter entity.
 * 
 * @param parent            The parent index. 
 * @param sAttach           The attachment bone of the entity parent.
 * @param sRender           (Optional) Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
 * @param sSound            (Optional) Material Sound. (-1: None | 0: Glass | 1: Wood | 2: Metal | 3: Flesh | 4: Concrete)
 * @param iSkin             (Optional) Some models have multiple skins.
 * @param sTextureName      Thing to shoot out. Can be a .mdl (model) or a .vmt (material/sprite).
 * @param vAngle            (Optional) The direction the gibs will fly. 
 * @param vGibAngle         (Optional) The orientation of the spawned gibs. 
 * @param iGibs             The number of gibs - Total number of gibs to shoot each time it's activated
 * @param flDelay           The delay (in seconds) between shooting each gib. If 0, all gibs shoot at once.
 * @param flVelocity        The speed of the fired gibs.
 * @param flVariance        How much variance in the direction gibs are fired.
 * @param flLife            Time in seconds for gibs to live +/- 5%. 
 * @param flDurationTime    The duration of the gibs.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateShooter(int parent, char[] sAttach, char[] sRender = "5", char[] sSound = "-1", int iSkin = 0, char[] sTextureName, float vAngle[3] = NULL_VECTOR, float vGibAngle[3] = NULL_VECTOR, float iGibs, float flDelay, float flVelocity, float flVariance, float flLife, float flDurationTime)
{
	int entity = CreateEntityByName("env_shooter");

	if (entity != -1)
	{
		static char sSkin[SMALL_LINE_LENGTH];
		IntToString(iSkin, sSkin, sizeof(sSkin));
		
		DispatchKeyValueVector(entity, "angles", vAngle);
		DispatchKeyValueVector(entity, "gibangles", vGibAngle);
		DispatchKeyValue(entity, "rendermode", sRender);
		DispatchKeyValue(entity, "shootsounds", sSound);
		DispatchKeyValue(entity, "shootmodel", sTextureName);
		DispatchKeyValue(entity, "skin", sSkin);
		DispatchKeyValueFloat(entity, "m_iGibs", iGibs);
		DispatchKeyValueFloat(entity, "delay", flDelay);
		DispatchKeyValueFloat(entity, "m_flVelocity", flVelocity);
		DispatchKeyValueFloat(entity, "m_flVariance", flVariance);
		DispatchKeyValueFloat(entity, "m_flGibLife", flLife);

		DispatchSpawn(entity);

		ActivateEntity(entity);  
		AcceptEntityInput(entity, "Shoot");

		SetVariantString("!activator"); 
		AcceptEntityInput(entity, "SetParent", parent, entity); 
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);

		if (hasLength(sAttach))
		{ 
			SetVariantString(sAttach); 
			AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
		}

		UTIL_RemoveEntity(entity, flDurationTime);
	}
	
	return entity;
}  

/**
 * @brief Create a beam entity.
 * 
 * @param vStartPosition    The start position of the beam.    
 * @param vEndPosition      The end position of the beam.    
 * @param sDamage           (Optional) How much damage this beam does per second to things it hits when it is continually on, or instantaneously if it strikes. For continuous damage, the value should be greater than 10 or it may not work.
 * @param sFrame            (Optional) The framerate at which the beam texture should animate, if it has multiple frames.
 * @param sWidth            (Optional) The pixel width of the beam. Range: 1 to MAX_BEAM_WIDTH.
 * @param sRenderFX         (Optional) The several GoldSrc-era visibility modes which change the way the entity is rendered, typically by fading it in and out.
 * @param sType             (Optional) If you want the beam to fire an output when touched by entities, choose the entity type here. (0: Not a tripwire | 1: Player Only | 2: NPC Only | 3: Player or NPC | 4: Player or NPC or Physprop)
 * @param sRate             (Optional) The framerate at which the beam texture should animate, if it has multiple frames.
 * @param sDecalName        (Optional) The decal to be applied at the end of the beam
 * @param sScroll           (Optional) The rate at which the beam texture should scroll along the beam. Range: 0 to MAX_BEAM_SCROLLSPEED.
 * @param sScale            (Optional) The float value to multiply sprite color by when running in HDR mode.
 * @param sTextureName      (Optional) The material used to draw the beam.
 * @param sLife             (Optional) The amount of time before the beam dies. Setting to zero will make the beam stay forever.
 * @param sStrike           (Optional) The refire time between random strikes of the beam. Only used if the 'Random Strike' spawnflag is set.
 * @param iFlags            (Optional) The bits with some flags.
 * @param sAmplitude        (Optional) The amount of noise in the beam. 0 is a perfectly straight beam. Range: 0 to MAX_BEAM_NOISEAMPLITUDE.
 * @param sRadius           (Optional) If the LightningStart and/or LightningEnd values are omitted, this radius determines the area within which the endpoints will randomly strike. A new random position will be appointed for every strike.
 * @param sRenderAMT        (Optional) The beam brightness. Useless when set to 0.
 * @param sColor            The beam color.
 * @param flDelayTime       The delay after the touch.
 * @param flDurationTime    The duration of the beam.
 * @param sName             The name of the beam.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateBeam(float vStartPosition[3], float vEndPosition[3], char[] sDamage = "0", char[] sFrame = "0", char[] sWidth = "4.0", char[] sRenderFX = "0", char[] sType = "3", char[] sRate = "0", char[] sDecalName = "Bigshot", char[] sScroll = "35", char[] sScale = "1.0", char[] sTextureName = "materials/sprites/purplelaser1.vmt", char[] sLife = "0", char[] sStrike = "1", int iFlags = 0, char[] sAmplitude = "0", char[] sRadius = "256", char[] sRenderAMT = "100", char[] sColor, float flDelayTime, float flDurationTime, char[] sName)
{
	int entity = CreateEntityByName("env_beam");

	if (entity != -1)
	{
		static char sClassname[SMALL_LINE_LENGTH];
		FormatEx(sClassname, sizeof(sClassname), "%s%i", sName, entity);

		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));
		
		DispatchKeyValueVector(entity, "origin", vStartPosition);
		DispatchKeyValue(entity, "targetname", sClassname);
		DispatchKeyValue(entity, "damage", sDamage);
		DispatchKeyValue(entity, "framestart", sFrame);
		DispatchKeyValue(entity, "BoltWidth", sWidth);
		DispatchKeyValue(entity, "renderfx", sRenderFX);
		DispatchKeyValue(entity, "TouchType", sType);
		DispatchKeyValue(entity, "framerate", sRate);
		DispatchKeyValue(entity, "decalname", sDecalName);
		DispatchKeyValue(entity, "TextureScroll", sScroll);
		DispatchKeyValue(entity, "HDRColorScale", sScale);
		DispatchKeyValue(entity, "texture", sTextureName);
		DispatchKeyValue(entity, "life", sLife); 
		DispatchKeyValue(entity, "StrikeTime", sStrike); 
		DispatchKeyValue(entity, "LightningStart", sClassname);
		DispatchKeyValue(entity, "spawnflags", sFlags); 
		DispatchKeyValue(entity, "NoiseAmplitude", sAmplitude); 
		DispatchKeyValue(entity, "Radius", sRadius);
		DispatchKeyValue(entity, "renderamt", sRenderAMT);
		DispatchKeyValue(entity, "rendercolor", sColor);

		DispatchSpawn(entity);

		AcceptEntityInput(entity, "TurnOff");
		AcceptEntityInput(entity, "TurnOn");
		
		SetEntityModel(entity, sTextureName);
		
		float flWidth = StringToFloat(sWidth);
		SetEntPropFloat(entity, Prop_Data, "m_fWidth", flWidth);
		SetEntPropFloat(entity, Prop_Data, "m_fEndWidth", flWidth);
		SetEntPropVector(entity, Prop_Data, "m_vecEndPos", vEndPosition);

		if (flDurationTime > 0.0)
		{
			UTIL_RemoveEntity(entity, flDurationTime);
		}
		
		if (flDelayTime > 0.0)
		{
			FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:TurnOff::%f:1", flDelayTime - 0.001);
			
			SetVariantString(sFlags);
			AcceptEntityInput(entity, "AddOutput");
			
			FormatEx(sFlags, sizeof(sFlags), "OnUser3 !self:TurnOn::%f:1", flDelayTime);
			
			SetVariantString(sFlags);
			AcceptEntityInput(entity, "AddOutput");
			
			SetVariantString("OnTouchedByEntity !self:FireUser2::0.0:-1");
			AcceptEntityInput(entity, "AddOutput");
			SetVariantString("OnTouchedByEntity !self:FireUser3::0.0:-1");
			AcceptEntityInput(entity, "AddOutput");
		}
	}
	
	return entity;
}

/**
 * @brief Create a light dynamic entity.
 * 
 * @param parent            (Optional) The parent index. 
 * @param vPosition         (Optional) The origin of the spawn.
 * @param sAttach           (Optional) The attachment name.
 * @param sInnerCone        (Optional) The inner (bright) angle.
 * @param sCone             (Optional) The outer (fading) angle.
 * @param sBrightness       (Optional) The intensity of the spotlight.
 * @param sPitch            (Optional) Used instead of Pitch Yaw Roll's value for reasons unknown.
 * @param sStyle            (Optional) The lightstyle (see Appearance field for possible values).
 * @param iFlags            (Optional) The bits with some flags.
 * @param sColor            The color of the light. (RGBA)
 * @param flDistance        The distance of the light.
 * @param flRadius          The radius of the light.
 * @param flDurationTime    (Optional) The duration of the light.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateLight(int parent = -1, float vPosition[3] = NULL_VECTOR, char[] sAttach = "", char[] sInnerCone = "0", char[] sCone = "80", char[] sBrightness = "1", char[] sPitch = "90", char[] sStyle = "1", int iFlags = 0, char[] sColor, float flDistance, float flRadius, float flDurationTime = 0.0)
{
	int entity = CreateEntityByName("light_dynamic");

	if (entity != -1)
	{
		static char sFlags[SMALL_LINE_LENGTH];
		IntToString(iFlags, sFlags, sizeof(sFlags));

		DispatchKeyValueVector(entity, "origin", vPosition); 
		DispatchKeyValue(entity, "spawnflags", sFlags);
		DispatchKeyValue(entity, "inner_cone", sInnerCone);
		DispatchKeyValue(entity, "cone", sCone);
		DispatchKeyValue(entity, "brightness", sBrightness);
		DispatchKeyValue(entity, "pitch", sPitch);
		DispatchKeyValue(entity, "style", sStyle);
		DispatchKeyValue(entity, "_light", sColor);
		DispatchKeyValueFloat(entity, "distance", flDistance);
		DispatchKeyValueFloat(entity, "spotlight_radius", flRadius);

		DispatchSpawn(entity);

		AcceptEntityInput(entity, "TurnOn");

		if (parent != -1)
		{
			SetVariantString("!activator"); 
			AcceptEntityInput(entity, "SetParent", parent, entity); 
			SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", parent);
			
			if (hasLength(sAttach))
			{ 
				SetVariantString(sAttach); 
				AcceptEntityInput(entity, "SetParentAttachment", parent, entity);
			}
		}
		
		if (flDurationTime > 0.0)
		{
			UTIL_RemoveEntity(entity, flDurationTime);
		}
	}
	
	return entity;
}

/**
 * @brief Sets the glowing on the entity.
 * 
 * @param entity            The entity index.
 * @param enableState       Sets to true to enable glowing, false to disable.
 * @param iType             (Optional) The type of the glowing.
 * @param iRed              (Optional) Amount of a red (0-255)
 * @param iGreen            (Optional) Amount of a green (0-255)
 * @param iBlue             (Optional) Amount of a blue (0-255)
 * @param iAlpha            (Optional) Amount of an alpha (0-255)
 **/
stock void UTIL_CreateGlowing(int entity, bool enableState, int iType = 0, int iRed = 255, int iGreen = 255, int iBlue = 255, int iAlpha = 255)
{
	static int iGlowOffset;
	if (!iGlowOffset && (iGlowOffset = GetEntSendPropOffs(entity, "m_clrGlow")) == -1)
	{
		return;
	}
	
	SetEntProp(entity, Prop_Send, "m_bShouldGlow", enableState, true);
	SetEntProp(entity, Prop_Send, "m_nGlowStyle", iType);
	SetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist", 100000.0);
	
	SetEntData(entity, iGlowOffset + 0, iRed,   _, true);
	SetEntData(entity, iGlowOffset + 1, iGreen, _, true);
	SetEntData(entity, iGlowOffset + 2, iBlue,  _, true);
	SetEntData(entity, iGlowOffset + 3, iAlpha, _, true);
}

/**
 * @brief Sets the render of a entity.
 *
 * @param entity            The entity index.
 * @param color             The offset index.
 * @param iRender           The render amount.
 **/
stock void UTIL_SetRenderColor(int entity, ColorType color, int iRender)
{
	static int iRenderOffset;
	if (!iRenderOffset && (iRenderOffset = GetEntSendPropOffs(entity, "m_clrRender")) == -1)
	{
		return;
	}

	SetEntProp(entity, Prop_Send, "m_nRenderMode", RENDER_TRANSALPHA);
	SetEntData(entity, iRenderOffset + view_as<int>(color), iRender, 1, true);
}

/**
 * @brief Gets the render of a entity.
 *
 * @param entity            The entity index.
 * @param color             The offset index.
 * @return                  The render amount.
 **/
stock int UTIL_GetRenderColor(int entity, ColorType color)
{
	static int iRenderOffset;
	if (!iRenderOffset && (iRenderOffset = GetEntSendPropOffs(entity, "m_clrRender")) == -1)
	{
		return 255;
	}

	return GetEntData(entity, iRenderOffset + view_as<int>(color), 1);
}

/**
 * @brief Create the tracer to a entity. (*not client)
 *
 * @param parent            The parent index.
 * @param sAttach           The attachment name.
 * @param sEffect           The effect name.
 * @param vBullet           The position of a bullet hit.
 * @param flDurationTime    The duration of life.
 **/
stock void UTIL_CreateTracer(int parent, char[] sAttach, char[] sEffect, float vBullet[3], float flDurationTime)
{
	if (!hasLength(sEffect))
	{
		return;
	}
	
	#define StaticSrt  0
	#define StaticEnd  1
								/** Regards to Phoenix **/
							 /** Dont ask me how it works ;) **/


	static char sClassname[SMALL_LINE_LENGTH];

	static int entity[2];
	entity[StaticSrt] = CreateEntityByName("info_particle_system");
	entity[StaticEnd] = CreateEntityByName("info_particle_system");

	if (entity[StaticEnd] != -1) /// Check the last entity ;)
	{
		static float vAngle[3]; static float vEmpty[3];
		GetEntPropVector(parent, Prop_Data, "m_angAbsRotation", vAngle); 
		
		TeleportEntity(entity[StaticEnd], vBullet, vAngle, NULL_VECTOR);
		
		FormatEx(sClassname, sizeof(sClassname), "particle%d",  entity[StaticSrt]);
		DispatchKeyValue(entity[StaticSrt], "targetname", sClassname);
		DispatchKeyValue(entity[StaticEnd], "effect_name", sEffect);
		DispatchKeyValue(entity[StaticEnd], "cpoint1", sClassname);
		
		DispatchSpawn(entity[StaticEnd]);
		
		SetEntPropEnt(entity[StaticEnd], Prop_Data, "m_hOwnerEntity", parent);

		TeleportEntity(entity[StaticSrt], NULL_VECTOR, vAngle, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(entity[StaticSrt], "SetParent", parent, entity[StaticSrt]);
		
		SetVariantString(sAttach);
		AcceptEntityInput(entity[StaticSrt], "SetParentAttachment",  entity[StaticSrt], entity[StaticSrt]);

		TeleportEntity(entity[StaticSrt], vEmpty, NULL_VECTOR, NULL_VECTOR);

		/*______________________________________________________________________________*/
		
		ActivateEntity(entity[StaticEnd]);
		AcceptEntityInput(entity[StaticEnd], "Start");

		UTIL_RemoveEntity(entity[StaticEnd], flDurationTime);
		UTIL_RemoveEntity(entity[StaticSrt], flDurationTime);
	}
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Shake a client screen with specific parameters.
 * 
 * @param client            The client index.
 * @param flAmplitude       The amplitude of shake.
 * @param flFrequency       The frequency of shake.
 * @param flDurationTime    The duration of shake in the seconds.
 **/
stock void UTIL_CreateShakeScreen(int client, float flAmplitude, float flFrequency, float flDurationTime)
{
	Protobuf hShake = view_as<Protobuf>(StartMessageOne("Shake", client));

	if (hShake != null)
	{
		hShake.SetInt("command", 0);
		hShake.SetFloat("local_amplitude", flAmplitude);
		hShake.SetFloat("frequency", flFrequency);
		hShake.SetFloat("duration", flDurationTime);

		EndMessage();
	}
}

/**
 * @brief Fade a client screen with specific parameters.
 * 
 * @param client            The client index.
 * @param flDuration        The duration of fade in the seconds.
 * @param flHoldTime        The holding time of fade in the seconds.
 * @param iFlags            The bits with some flags.
 * @param vColor            The array with RGB color.
 **/
stock void UTIL_CreateFadeScreen(int client, float flDuration, float flHoldTime, int iFlags, int vColor[4])
{
	Protobuf hFade = view_as<Protobuf>(StartMessageOne("Fade", client));

	if (hFade != null)
	{
		hFade.SetInt("duration", RoundToNearest(flDuration * 1000.0)); 
		hFade.SetInt("hold_time", RoundToNearest(flHoldTime * 1000.0)); 
		hFade.SetInt("flags", iFlags); 
		hFade.SetColor("clr", vColor); 

		EndMessage();
	}
}

/**
 * @brief Push a client with specific parameters.
 * 
 * @param client            The client index.
 * @param vPosition         The force origin.
 * @param vOrigin           The client origin.
 * @param flDistance        The distance amount.
 * @param flForce           The force amount.
 * @param flRadius          The radius amount.
**/
stock void UTIL_CreatePhysForce(int client, float vPosition[3], float vOrigin[3], float flDistance, float flForce, float flRadius)
{
	static float vVelocity[3];
	MakeVectorFromPoints(vPosition, vOrigin, vVelocity);
	
	float flKnockBack = flForce * (1.0 - (flDistance / flRadius));

	NormalizeVector(vVelocity, vVelocity);

	ScaleVector(vVelocity, SquareRoot((flKnockBack * flKnockBack) / ((vVelocity[0] * vVelocity[0]) + (vVelocity[1] * vVelocity[1]) + (vVelocity[2] * vVelocity[2])))); vVelocity[2] * flForce;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

/**
 * @brief Send a hint message to the client screen with specific parameters.
 * 
 * @param client            The client index.
 * @param sMessage          The message to send.
 **/
stock void UTIL_CreateClientHint(int client, char[] sMessage)
{
	Protobuf hMessage = view_as<Protobuf>(StartMessageOne("HintText", client));

	if (hMessage != null)
	{
		hMessage.SetString("text", sMessage);

		EndMessage();
	}
}

/**
 * @brief Send a hud message to the client screen with specific parameters.
 * 
 * @param hSync             New HUD synchronization object.
 * @param client            The client index.
 * @param x                 x coordinate, from 0 to 1. -1.0 is the center.
 * @param y                 y coordinate, from 0 to 1. -1.0 is the center.
 * @param holdTime          Number of seconds to hold the text.
 * @param r                 Red color value.
 * @param g                 Green color value.
 * @param b                 Blue color value.
 * @param a                 Alpha transparency value.
 * @param effect            0/1 causes the text to fade in and fade out. 2 causes the text to flash[?].
 * @param fxTime            Duration of chosen effect (may not apply to all effects).
 * @param fadeIn            Number of seconds to spend fading in.
 * @param fadeOut           Number of seconds to spend fading out.
 * @param sMessage          The message to send.
 **/
stock void UTIL_CreateClientHud(Handle hSync, int client, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut, char[] sMessage)
{
	SetHudTextParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);
	
	ShowSyncHudText(client, hSync, sMessage);
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Precache models and also adding them into the downloading table.
 * 
 * @param sModel            The model path.
 *
 * @return                  The model index.
 **/
stock int UTIL_PrecacheModel(char[] sModel)
{
	int iModel = PrecacheModel(sModel, true);
	
	AddFileToDownloadsTable(sModel);

	static char sPath[PLATFORM_MAX_PATH];
	static const char sType[3][SMALL_LINE_LENGTH] = { ".dx90.vtx", ".phy", ".vvd" };

	for (int i = 0; i < sizeof(sType); i++)
	{
		FormatEx(sPath, sizeof(sPath), "%s", sModel);
		ReplaceString(sPath, sizeof(sPath), ".mdl", sType[i]);
		if (!FileExists(sPath)) continue;
		AddFileToDownloadsTable(sPath);
	}
	
	return iModel;
}

/**
 * @brief Ignites the entity on a fire.
 * 
 * @param entity            The entity index. 
 * @param flDurationTime    The number of seconds to set on a fire.
 **/
stock void UTIL_IgniteEntity(int entity, float flDurationTime)
{
	if (flDurationTime > 0.0) 
	{
		IgniteEntity(entity, flDurationTime);
	}
}

/**
 * @brief Extinguishes the entity that is on a fire.
 * 
 * @param entity            The entity index. 
 **/
stock void UTIL_ExtinguishEntity(int entity)
{
	int iFire = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	if (IsValidEdict(iFire))
	{
		static char sClassname[SMALL_LINE_LENGTH];
		GetEdictClassname(iFire, sClassname, sizeof(sClassname));
		
		if (!strcmp(sClassname, "entityflame", false))
		{
			SetEntPropFloat(iFire, Prop_Data, "m_flLifetime", 0.0);
		}
	}
}

/**
 * @brief Remove the entity from a world after some delay.
 * 
 * @param entity            The entity index. 
 * @param flDelayTime       The number of seconds to kill an entity.
 **/
stock void UTIL_RemoveEntity(int entity, float flDelayTime)
{
	static char sFlags[SMALL_LINE_LENGTH];
	FormatEx(sFlags, sizeof(sFlags), "OnUser1 !self:Kill::%f:1", flDelayTime);
	
	SetVariantString(sFlags);
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
}

/**
 * @brief Precache decals and also adding them into the downloading table.
 * 
 * @param sDecal            The decal path.
 *
 * @return                  The decal index.
 **/
stock int UTIL_PrecacheDecal(char[] sDecal)
{
	int iDecal = PrecacheDecal(sDecal, true);
	
	AddFileToDownloadsTable(sDecal);

	static char sPath[PLATFORM_MAX_PATH];
	
	FormatEx(sPath, sizeof(sPath), "%s", sDecal);
	ReplaceString(sPath, sizeof(sPath), ".vtf", ".vmt");
	if (FileExists(sPath)) AddFileToDownloadsTable(sPath);
	
	return iDecal;
}

/**
 * @brief Precache sounds and also adding them into the downloading table.
 * 
 * @param soundPath         The sound path.
 **/
stock void UTIL_PrecacheSound(char[] sSound)
{
	static char sPath[PLATFORM_MAX_PATH];
	
	FormatEx(sPath, sizeof(sPath), "sound/%s", sSound);
	if (!FileExists(sPath)) return;
	AddFileToDownloadsTable(sPath);
	
	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("soundprecache");
	}

	bool bSave = LockStringTables(false);
	FormatEx(sPath, sizeof(sPath), "*/%s", sSound);
	AddToStringTable(table, sPath);
	LockStringTables(bSave);
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Find the trace hull intersection.
 *
 * @param hTrace            The trace handle.
 * @param vPosition         The entity position. 
 * @param vMins             The mins vector.
 * @param vMaxs             The maxs vector.
 * @param filter            The function to use as a filter.
 * @param data              The data value to pass through to the filter function.
 **/
stock void UTIL_FindHullIntersection(Handle &hTrace, float vPosition[3], const float vMins[3], const float vMaxs[3], TraceEntityFilter filter, any data)
{
	static float vEndPosition[3]; static float vHullPosition[3]; static float vHullEnd[3]; static float vHullBox[2][3];

	TR_GetEndPosition(vHullEnd, hTrace);

	MakeVectorFromPoints(vPosition, vHullEnd, vHullEnd);
	
	ScaleVector(vHullEnd, 2.0);
	
	AddVectors(vHullEnd, vPosition, vHullEnd);
	
	Handle hTemp = TR_TraceRayFilterEx(vPosition, vHullEnd, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, filter, data);
	
	if (TR_DidHit(hTemp))
	{
		delete hTrace;
		hTrace = hTemp;
		return;
	}

	vHullBox[0] = vMins;
	vHullBox[1] = vMaxs;
	
	float flDistance = MAX_FLOAT; float flLength;
	
	for (int i, j, k = 0; i < 2; i++)
	{
		for (j = 0; j < 2; j++)
		{
			for (k = 0; k < 2; k++)
			{
				vHullPosition[0] = vHullEnd[0] + vHullBox[i][0];
				vHullPosition[1] = vHullEnd[1] + vHullBox[j][1];
				vHullPosition[2] = vHullEnd[2] + vHullBox[k][2];

				delete hTemp;
				hTemp = TR_TraceRayFilterEx(vPosition, vHullPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, filter, data);
				
				if (TR_DidHit(hTemp))
				{
					TR_GetEndPosition(vEndPosition, hTemp);
					
					MakeVectorFromPoints(vPosition, vEndPosition, vEndPosition);

					if ((flLength = GetVectorLength(vEndPosition)) < flDistance)
					{
						delete hTrace;
						hTrace = CloneHandle(hTemp);
						flDistance = flLength;
					}
				}
			}
		}
	}
	
	delete hTemp;
}

/**
 * @brief Gets the velocity and it's angle from the two vectors.
 * 
 * @param vStartPosition    The starting position.
 * @param vEndPosition      The ending position.     
 * @param vAngle            The calculated angle's vector output.
 * @param vVelocity         The calculated velocity's vector output.
 * @param flSpeedScale      (Optional) The speed scale value.
 * @param verticalScale     (Optional) Set to true for reversing vertical velocity's value, false to reset.
 **/
stock void UTIL_GetVelocityByAim(float vStartPosition[3], float vEndPosition[3], float vAngle[3], float vVelocity[3], float flSpeedScale = 1.0, bool verticalScale = false)
{
	MakeVectorFromPoints(vStartPosition, vEndPosition, vVelocity);
	
	vVelocity[2] = verticalScale ? -vVelocity[2] : 0.0;

	GetVectorAngles(vVelocity, vAngle);
	
	vAngle[0] = vAngle[2] = 0.0;

	NormalizeVector(vVelocity, vVelocity);

	ScaleVector(vVelocity, flSpeedScale);
}

/**
 * @brief Validate that the entity is can see the target.
 *
 * @note Check 3 spots, or else when standing right next to someone looking at their eyes, 
 *       the angle will be too great to see their center. Thank to Pelipoika.
 *
 * @param entity            The entity index. 
 * @param target            The target index. 
 * @param vPosition         The entity position.
 * @param filter            The function to use as a filter.
 *
 * @return                  True of false.        
 **/
stock bool UTIL_CanSeeEachOther(int entity, int target, float vPosition[3], TraceEntityFilter filter)
{
	static float vOrigin[3]; static float vMaxs[3];

	GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", vOrigin);
	
	if (UTIL_TraceRay(entity, target, vPosition, vOrigin, filter))
	{
		return true;
	}
	
	/*___________________________________________________________________________________________________________*/

	GetClientMaxs(target, vMaxs); vOrigin[2] += vMaxs[2] / 2;
	
	if (UTIL_TraceRay(entity, target, vPosition, vOrigin, filter))
	{
		return true;
	}
	
	/*___________________________________________________________________________________________________________*/

	GetClientEyePosition(target, vOrigin);
	
	if (UTIL_TraceRay(entity, target, vPosition, vOrigin, filter))
	{
		return true;
	}
		
	return false;
}

/**
 * @brief Starts up a new trace ray using a new trace result and a customized trace ray filter. 
 *
 * @param entity            The entity index.
 * @param target            The target index. 
 * @param vStartPosition    The starting position of the ray.
 * @param vEndPosition      The ending position of the ray.
 * @param filter            The function to use as a filter.
 *
 * @return                  True of false.        
 **/
stock bool UTIL_TraceRay(int entity, int target, float vStartPosition[3], float vEndPosition[3], TraceEntityFilter filter)
{
	TR_TraceRayFilter(vStartPosition, vEndPosition, (MASK_SHOT|CONTENTS_GRATE), RayType_EndPoint, filter, entity);

	bool bHit;
	if (!TR_DidHit() || TR_GetEntityIndex() == target) 
	{
		bHit = true;
	}

	return bHit;
}

/**
 * @brief Calculates the distance between two entities.
 *
 * @param client            The client index. 
 * @param entity            The entity index.
 *
 * @return                  The distance amount.        
 **/
stock float UTIL_GetDistanceBetween(int client, int entity)
{
	static float vPosition[3]; static float vEndPosition[3]; static float vMins[3]; static float vMaxs[3];

	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", vPosition);
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vEndPosition);
	
	GetClientMins(client, vMins); 
	GetClientMaxs(client, vMaxs);
	
	float flHeight = vMins[2] - vMaxs[2] + 10;
	float fDistance = vPosition[2] - vEndPosition[2];
	
	if (fDistance > flHeight) 
	{
		vPosition[2] -= flHeight;
	}
	else if (fDistance < (-1.0 * flHeight)) 
	{
		vPosition[2] -= flHeight;
	}
	else 
	{
		vPosition[2] = vEndPosition[2];
	}
	
	return GetVectorDistance(vPosition, vEndPosition);
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Searches for the index of a given string in a dispatch table.
 *
 * @param sEffect           The effect name.
 *
 * @return                  The string index.
 **/
stock int GetEffectIndex(char[] sEffect)
{
	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}

	int item = FindStringIndex(table, sEffect);

	if (item != INVALID_STRING_INDEX)
	{
		return item;
	}

	return 0;
}

/**
 * @brief Searches for the index of a given string in an effect table.
 *
 * @param sEffect           The effect name.
 *
 * @return                  The string index.
 **/
stock int GetParticleEffectIndex(char[] sEffect)
{
	static int table = INVALID_STRING_TABLE;

	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}

	int item = FindStringIndex(table, sEffect);

	if (item != INVALID_STRING_INDEX)
	{
		return item;
	}

	return 0;
}

/**
 * @brief Precache the particle in the effect table. (for client)
 *
 * @param client            (Optional) The client index.
 * @param sEffect           The effect name.
 **/
stock void PrecacheParticleFile(int client = 0, char[] sEffect)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ExtraParticleFilesTable");
	}

	if (!client)
	{
		bool bSave = LockStringTables(false);
		AddToStringTable(table, sEffect);
		LockStringTables(bSave);
	}
	else
	{
		int iCount = GetStringTableNumStrings(table);
		for (int i = 0; i < iCount; i++)
		{
			static char iD[SMALL_LINE_LENGTH];
			IntToString(client, iD, sizeof(iD));
			SetStringTableData(table, i, iD, sizeof(iD));
		}
	}
}

/**
 * @brief Precache the particle in the effect table.
 *
 * @param sEffect           The effect name.
 **/
stock void PrecacheParticleEffect(char[] sEffect)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	bool bSave = LockStringTables(false);
	AddToStringTable(table, sEffect);
	LockStringTables(bSave);
}

/**
 * @brief Gets a string of a given index in a dispatch table.
 *
 * @param iIndex            The string index.
 * @param sEffect           The string to return effect in.
 * @param iMaxLen           The lenght of string.
 **/
stock void GetEffectName(int iIndex, char[] sEffect, int iMaxLen)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}

	ReadStringTable(table, iIndex, sEffect, iMaxLen);
}

/**
 * @brief Gets a string of a given index in an effect table.
 *
 * @param iIndex            The string index.
 * @param sEffect           The string to return effect in.
 * @param iMaxLen           The lenght of string.
 **/
stock void GetParticleEffectName(int iIndex, char[] sEffect, int iMaxLen)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	ReadStringTable(table, iIndex, sEffect, iMaxLen);
}

/**
 * @brief Gets a string count in a dispatch table.
 *
 * @return                  The table size.    
 **/
stock int GetEffectNameCount()
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("EffectDispatch");
	}

	return GetStringTableNumStrings(table);
}

/**
 * @brief Gets a string count in an effect table.
 *
 * @return                  The table size.    
 **/
stock int GetParticleEffectCount()
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	return GetStringTableNumStrings(table);
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Finds the amount of all occurrences of a character in a string.
 *
 * @param sBuffer           The input string buffer.
 * @param cSymbol           The character to search for.
 * @return                  The amount of characters in the string, or -1 if the characters were not found.
 */
stock int CountCharInString(char[] sBuffer, char cSymbol)
{
	int iCount;
	
	int iLen = strlen(sBuffer);
	for (int i = 0; i < iLen; i++) 
	{
		if (sBuffer[i] == cSymbol)
		{
			iCount++;
		}
	}

	return iCount ? iCount : -1;
}

/**
 * @brief Extracts a area in a string between two positions.
 *
 * @param sBuffer           The destination string buffer.
 * @param sSource           The source string to extract from.
 * @param startPos          The start position of string to extract.
 * @param endPos            The end position of string to extract.
 * @return                  The number of cells written.
 **/
stock int ExtractString(char[] sBuffer, char[] sSource, int startPos, int endPos)
{
	int iMaxLen = endPos - startPos + 1;
	
	if (iMaxLen < 0)
	{
		sBuffer[0] = NULL_STRING[0];
		return 0;
	}
	
	return strcopy(sBuffer, iMaxLen, sSource[startPos]);
}

/**
 * @brief Converts uppercase chars in the string to lowercase chars.
 *
 * @param sBuffer           The input string buffer.
 */
stock void StringToLower(char[] sBuffer)
{
	int iLen = strlen(sBuffer);
	for (int i = 0; i < iLen; i++) 
	{
		sBuffer[i] = CharToLower(sBuffer[i]);
	}
}

/**
 * @brief Converts lowercase chars in the string to uppercase chars.
 *
 * @param sBuffer           The input string buffer.
 */
stock void StringToUpper(char[] sBuffer)
{
	int iLen = strlen(sBuffer);
	for (int i = 0; i < iLen; i++) 
	{
		sBuffer[i] = CharToUpper(sBuffer[i]);
	}
}

/**
 * @brief Returns whether a string is numeric.
 *
 * @param sBuffer           The input string buffer.
 */
stock bool IsStringNumeric(char[] sBuffer)
{
	int iLen = strlen(sBuffer);
	for (int i = 0; i < iLen; i++) 
	{
		if (!IsCharNumeric(sBuffer[i]))
		{
			return false;
		}
	}
	
	return true;
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Randomly permutes the specified list using a default source of randomness.
 *
 * @param hList             The array that is being shuffle.
 **/
stock void ShuffleArray(ArrayList hList)
{
	int iSize = hList.Length; int iLen = iSize - 1;
	for (int i = 0; i < iSize; i++)
	{
		hList.SwapAt(i, GetRandomInt(0, iLen));
	}
}

/**
 * @brief Destroy all array handles within an array, and clear it.
 * 
 * @param hArrayList        The array containing sub arrays.
 **/
stock void ClearArrayList(ArrayList hArrayList)
{
	int iSize = hArrayList.Length;
	if (!iSize)
	{
		return;
	}
	
	for (int i = 0; i < iSize; i++)
	{
		ArrayList hList = hArrayList.Get(i);
		delete hList;
	}
	
	hArrayList.Clear();
}

/**
 * @brief Destroy all array handles within an string map, and clear it.
 * 
 * @param hTrieList         The map containing sub arrays.
 **/
stock void ClearTrieList(StringMap hTrieList)
{
	StringMapSnapshot hSnapshot = hTrieList.Snapshot();
	
	int iSize = hSnapshot.Length;
	if (!iSize)
	{
		delete hSnapshot;
		return;
	}
	
	static char sKey[SMALL_LINE_LENGTH]; ArrayList hList;
	
	for (int i = 0; i < iSize; i++)
	{
		hSnapshot.GetKey(i, sKey, sizeof(sKey));
		
		if (hTrieList.GetValue(sKey, hList))
		{
			delete hList;
		}
	}

	delete hSnapshot;
	hTrieList.Clear();
}

/**
 * @brief Sort comparison function by string length.
 *
 * @param iIndex1           The first index to compare.
 * @param iIndex2           The second index to compare.
 * @param hList             The array that is being sorted (order is undefined).
 * @param hCustom           Handle optionally passed in while sorting.
 **/
stock int Sort_ByLength(int iIndex1, int iIndex2, ArrayList hList, Handle hCustom)
{
	static char sBuffer1[PLATFORM_LINE_LENGTH]; 
	hList.GetString(iIndex1, sBuffer1, sizeof(sBuffer1));
	static char sBuffer2[PLATFORM_LINE_LENGTH];
	hList.GetString(iIndex2, sBuffer2, sizeof(sBuffer2));
	
	int iLen1 = strlen(sBuffer1); int iLen2 = strlen(sBuffer2); 
	
	if (iLen1 < iLen2)
	{
		return -1;
	}
	else if (iLen1 > iLen2)
	{
		return 1;
	}
	
	return 0;
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Returns true if the client is valid, false if not.
 *
 * @param client            The client index.
 * @param bAlive            (Optional) Set to true to validate that the client is alive, false to ignore.
 * @param bBot              (Optional) Set to false to validate that the client is bot, true to ignore.
 *  
 * @return                  True or false.
 **/
stock bool IsClientValid(int client, bool bAlive = true, bool bBot = true)
{
	if (client <= 0 || client > MaxClients)
	{
		return false;
	}

	if (!IsClientInGame(client))
	{
		return false;
	}

	if (IsClientSourceTV(client) || IsClientReplay(client))
	{
		return false;
	}
	
	if (!bBot && IsFakeClient(client))
	{
		return false;
	}

	if (bAlive && !IsPlayerAlive(client))
	{
		return false;
	}

	return true;
}

/**
 * @brief Determines if the current server time is between the given min and max.
 *
 * @param min               The min time in format HHMM, where HH is the hour and MM is the minute.
 * @param max               The max time in format HHMM, where HH is the hour and MM is the minute.
 *
 * @return                  True or false.
 **/
stock bool IsTimeBetween(int min, int max)
{
	static char sTime[5];
	FormatTime(sTime, sizeof(sTime), "%H%M");
	int time = StringToInt(sTime);

	if (max <= min)
	{
		max += 2400;
		if (time <= min)
		{
			time += 2400;
		}
	}

	return min <= time && time <= max;
}

/*_____________________________________________________________________________________________________________*/


/**
 * @brief Copies the values of num bytes from the location pointed to by source directly to the memory block pointed to by destination.
 *
 * @param pDest        The destination address where the content is to be copied.
 * @param sSource      The source of data to be copied.
 * @param iSize        The number of bytes to copy.
 **/
stock void memcpy(Address pDest, char[] sSource, int iSize)
{
	int i = iSize / 4;
	memcpy4b(pDest, view_as<any>(sSource), i);
   
	for (i *= 4, pDest += view_as<Address>(i); i < iSize; i++)
	{
		StoreToAddress(pDest++, sSource[i], NumberType_Int8);
	}
}

/**
 * @brief Copies the 4 bytes from the location pointed to by source directly to the memory block pointed to by destination. 
 *
 * @param pDest        The destination address where the content is to be copied.
 * @param sSource      The source of data to be copied.
 * @param iSize        The number of bytes to copy.
 **/
stock void memcpy4b(Address pDest, any[] sSource, int iSize)
{
	for (int i = 0; i < iSize; i++)
	{
		StoreToAddress(pDest, sSource[i], NumberType_Int32);
		pDest += view_as<Address>(4);
	}
}

/**
 * @brief Writes the DWord D (i.e. 4 bytes) to the string. 
 *
 * @param asm             The assemly string.
 * @param pAddress        The address of the call.
 * @param iOffset         (Optional) The address offset. (Where 0x0 starts)
 **/
stock void writeDWORD(char[] asm, any pAddress, int iOffset = 0)
{
	asm[iOffset]   = pAddress & 0xFF;
	asm[iOffset+1] = pAddress >> 8 & 0xFF;
	asm[iOffset+2] = pAddress >> 16 & 0xFF;
	asm[iOffset+3] = pAddress >> 24 & 0xFF;
}

/**
 * Convert bit value to the bit index. 
 *
 * @link http://graphics.stanford.edu/~seander/bithacks.html#CountBitsSetParallel
 *
 * @param iBit           The bit value.
 * @return               The bit index. 
 **/
stock int bitIndex(int iBit) 
{
	iBit -= 1;
	iBit = iBit - ((iBit >> 1) & 0x55555555);
	iBit = (iBit & 0x33333333) + ((iBit >> 2) & 0x33333333);
	return (((iBit + (iBit >> 4) & 0xF0F0F0F) * 0x1010101) >> 24);
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Returns the smaller of two provided values.
 *  
 * @param v1                The first value.
 * @param v2                The second value.
 *
 * @return                  The smallest value.
 **/
stock any min(any v1, any v2) 
{
	return (v1 < v2 ? v1 : v2); 
} 

/**
 * @brief Returns the bigger of two provided values.
 *  
 * @param v1                The first value.
 * @param v2                The second value.
 *
 * @return                  The biggest value.
 **/
stock any max(any v1, any v2) 
{
	return (v1 > v2 ? v1 : v2); 
}

/**
 * @brief Clamps a value between a minimum and a maximum floating point value
 *  
 * @param v                 The value to be clamped
 * @param mi                The minimum value
 * @param ma                The maximum value
 *
 * @return                  The value clamped.
 **/
stock any clamp(any v, any mi, any ma)
{
    v = max(v, ma);
    return min(v, mi);
}