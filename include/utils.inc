/**
 * =============================================================================
 * Entity Utilities Copyright (C) 2019 Nikita Ushakov (Ireland, Dublin).
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
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
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
#define TEAM_NONE               0    /**< No team yet       */
#define TEAM_SPECTATOR          1    /**< Spectators        */
#define TEAM_T                  2    /**< Terrorist         */
#define TEAM_CT                 3    /**< Counter-Terrorist */
#define TEAM_ZOMBIE             2    /**< Zombies           */
#define TEAM_HUMAN              3    /**< Humans            */
#define SPECMODE_NONE           0
#define SPECMODE_FIRSTPERSON    4
#define SPECMODE_3RDPERSON      5
#define SPECMODE_FREELOOK       6
#define hasLength(%0)           (%0[0] != '\0') 
/**
 * @endsection
 **/

/**
 * @section Damage type values.
 **/
#define DAMAGE_NO               0
#define DAMAGE_EVENTS_ONLY      1    //! Call damage functions, but don't modify health
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
 * @section Physics explosion flags. 
 **/
#define PEXP_NODAMAGE               (1<<0)      /// No Damage - Only Force (Players are not ever damaged by the explosion (regardless of this flag), only objects.)
#define PEXP_PUSHPLAYERS            (1<<1)      /// Push players
#define PEXP_PUSHRADIALLY           (1<<2)      /// Push radially - not as a sphere (Radially meaning as a circle/cylinder. No upward or downward force will be generated.)
#define PEXP_TESTLOS                (1<<3)      /// Test LOS before pushing
#define PEXP_DISORIENT              (1<<4)      /// Disorient player if pushed
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
#define NPC_FALLTOFROUND            (1<<2)
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
/**
 * @endsection
 **/
 
/**
 * @section Hud elements flags.
 **/
#define HIDEHUD_WEAPONSELECTION     (1<<0)   /// Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT          (1<<1)
#define HIDEHUD_ALL                 (1<<2)
#define HIDEHUD_HEALTH              (1<<3)   /// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD          (1<<4)   /// Hide when local player's dead
#define HIDEHUD_NEEDSUIT            (1<<5)   /// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS          (1<<6)   /// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT                (1<<7)   /// Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR           (1<<8)   /// Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR   (1<<9)   /// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE           (1<<10)
#define HIDEHUD_BONUS_PROGRESS      (1<<11)  /// Hide bonus progress display (for bonus map challenges)
/**
 * @endsection
 **/
 
/**
 * @section Entity effects flags.
 **/
#define EF_BONEMERGE                (1<<0)     /// Performs bone merge on client side
#define EF_BRIGHTLIGHT              (1<<1)     /// DLIGHT centered at entity origin
#define EF_DIMLIGHT                 (1<<2)     /// Player flashlight
#define EF_NOINTERP                 (1<<3)     /// Don't interpolate the next frame
#define EF_NOSHADOW                 (1<<4)     /// Disables shadow
#define EF_NODRAW                   (1<<5)     /// Prevents the entity from drawing and networking
#define EF_NORECEIVESHADOW          (1<<6)     /// Don't receive shadows
#define EF_BONEMERGE_FASTCULL       (1<<7)     /// For use with EF_BONEMERGE. If this is set, then it places this ents origin at its parent and uses the parent's bbox + the max extents of the aiment. Otherwise, it sets up the parent's bones every frame to figure out where to place the aiment, which is inefficient because it'll setup the parent's bones even if the parent is not in the PVS.
#define EF_ITEM_BLINK               (1<<8)     /// Makes the entity blink
#define EF_PARENT_ANIMATES          (1<<9)     /// Always assume that the parent entity is animating
#define EF_FOLLOWBONE               (1<<10)    
/**
 * @endsection
 **/
 
 /**
 * @section Fade flags.
 **/
#define FFADE_IN                    0x0001      /// Just here so we don't pass 0 into the function
#define FFADE_OUT                   0x0002      /// Fade out (not in)
#define FFADE_MODULATE              0x0004      /// Modulate (don't blend)
#define FFADE_STAYOUT               0x0008      /// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE                 0x0010      /// Purges all other fades, replacing them with this one
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
#define FSOLID_CUSTOMRAYTEST                0x0001     /// Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST                0x0002     /// Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID                    0x0004     /// Are we currently not solid?
#define FSOLID_TRIGGER                      0x0008     /// This is something may be collideable but fires touch functions
#define FSOLID_NOT_STANDABLE                0x0010     /// You can't stand on this
#define FSOLID_VOLUME_CONTENTS              0x0020     /// Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED          0x0040     /// Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS           0x0080     /// Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED          0x0100     /// Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS         0x0200     /// This trigger will touch debris objects
/**
 * @endsection
 **/
 
/**
 * @section Material types.
 **/ 
#define MAT_NONE        "-1"	    
#define MAT_GLASS       "0"	    
#define MAT_WOOD        "1"	    
#define MAT_METAL       "2"	    
#define MAT_FLESH       "3"	    
#define MAT_CONCRETE    "4"	    
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
    // Create a train entity
    int entityIndex = CreateEntityByName("func_tracktrain"); 
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));

        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition); 
        DispatchKeyValueVector(entityIndex, "angles", vAngle); 
        DispatchKeyValue(entityIndex, "targetname", sClassname);
        DispatchKeyValue(entityIndex, "target", sPath);
        DispatchKeyValue(entityIndex, "startspeed", sSpeed);
        DispatchKeyValue(entityIndex, "speed", sSpeed);
        DispatchKeyValue(entityIndex, "wheels", "256");         /// Make moving smoother
        DispatchKeyValue(entityIndex, "bank", "20");            /// Make turning smoother
        DispatchKeyValue(entityIndex, "orientationtype", "2");  /// Linear blend, adds some smoothness
        DispatchKeyValue(entityIndex, "spawnflags", sFlags);  
        if(hasLength(sSound)) DispatchKeyValue(entityIndex, "MoveSound", sSound);
        
        // Sets the render mode
        SetEntityRenderMode(entityIndex, RENDER_TRANSALPHA); 
        SetEntityRenderColor(entityIndex, 0, 0, 0, 0); 
        
        // Spawn the entity
        DispatchSpawn(entityIndex);
    }

    // Return index on the success
    return entityIndex;
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
    // Create a path entity
    int entityIndex = CreateEntityByName("path_track");
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));

        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition); 
        DispatchKeyValueVector(entityIndex, "angles", vAngle); 
        DispatchKeyValue(entityIndex, "targetname", sClassname);
        DispatchKeyValue(entityIndex, "target", sNextTarget);
        DispatchKeyValue(entityIndex, "spawnflags", sFlags); 
        
        // Spawn the entity
        DispatchSpawn(entityIndex);

        // Activate the entity
        ActivateEntity(entityIndex);  
    }
    
    // Return index on the success
    return entityIndex;
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
    // Create a monster entity
    int entityIndex = CreateEntityByName("monster_generic"); 
        
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));

        // Dispatch main values of the entity
        DispatchKeyValue(entityIndex, "targetname", sClassname);
        DispatchKeyValueVector(entityIndex, "origin", vPosition); 
        DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValue(entityIndex, "model", sModel); 
        DispatchKeyValue(entityIndex, "spawnflags", sFlags); 
        
        // Spawn the entity
        DispatchSpawn(entityIndex);
    }
    
    // Return index on the success
    return entityIndex;
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
    // Create a prop_physics_multiplayer entity
    int entityIndex = CreateEntityByName("prop_physics_multiplayer"); 

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));
    
        // Dispatch main values of the entity
        DispatchKeyValue(entityIndex, "targetname", sClassname);
        DispatchKeyValueVector(entityIndex, "origin", vPosition);
        DispatchKeyValueVector(entityIndex, "angles", vAngle); 
        DispatchKeyValue(entityIndex, "model", sModel);
        DispatchKeyValue(entityIndex, "spawnflags", sFlags);
        
        // Spawn the entity
        DispatchSpawn(entityIndex);
    }
    
    // Return index on the success
    return entityIndex;
}

/**
 * @brief Create a dynamic entity. (No collision)
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param sModel            The model path.
 * @param sDefaultAnim      (Optional) The default animation.
 * @param bOverride         (Optional) True for models with physics, false for fully dynamic models.
 * @param bHoldAnim         (Optional) If set, the prop will not loop its animation, but hold the last frame.
 * @param iFlags            (Optional) The bits with some flags.
 *
 * @return                  The entity index.                       
 **/
stock int UTIL_CreateDynamic(float vPosition[3], float vAngle[3], char[] sModel, char[] sDefaultAnim = "", bool bOverride = true, bool bHoldAnim = false, int iFlags = DYN_COLLISIONDISABLED)
{
    // Create a prop_dynamic_override entity
    int entityIndex = CreateEntityByName(bOverride ? "prop_dynamic_override" : "prop_dynamic");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));

        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition); 
        DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValue(entityIndex, "model", sModel);
        DispatchKeyValue(entityIndex, "spawnflags", sFlags);
        DispatchKeyValue(entityIndex, "solid", "0");
        DispatchKeyValue(entityIndex, "HoldAnimation", bHoldAnim ? "1" : "0");
        if(hasLength(sDefaultAnim)) DispatchKeyValue(entityIndex, "DefaultAnim", sDefaultAnim);
        
        // Spawn the entity
        DispatchSpawn(entityIndex);
    }
    
    // Return index on the success
    return entityIndex;
}

/**
 * @brief Create a projectile entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.
 * @param sModel            (Optional) The model path.
 *
 * @return                  The entity index.                       
 **/
stock int UTIL_CreateProjectile(float vPosition[3], float vAngle[3], char[] sModel = "")
{
    // Create a static entity
    int entityIndex = CreateEntityByName("hegrenade_projectile");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Spawn the entity
        DispatchSpawn(entityIndex);
        TeleportEntity(entityIndex, vPosition, vAngle, NULL_VECTOR);
        
        // Sets the model
        if(hasLength(sModel)) SetEntityModel(entityIndex, sModel);
    }

    // Return index on the success
    return entityIndex;
}

/**
 * @brief Create a stack of the smoke entity.
 * 
 * @param parentIndex       (Optional) The parent index.
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
stock int UTIL_CreateSmoke(int parentIndex = INVALID_ENT_REFERENCE, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sSpreadBase = "100", char[] sSpreadSpeed = "70", char[] sSpeed = "80", char[] sStartSize = "200", char[] sEndSize = "2", char[] sDensity = "30", char[] sLength = "400", char[] sTwist = "20", char[] sColor, char[] sTransparency, char[] sSpriteName, float flRemoveTime = 0.0, float flDurationTime = 0.0)
{
    // Create a smokestack entity
    int entityIndex = CreateEntityByName("env_smokestack");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition); 
        DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValue(entityIndex, "BaseSpread", sSpreadBase);
        DispatchKeyValue(entityIndex, "SpreadSpeed", sSpreadSpeed);
        DispatchKeyValue(entityIndex, "Speed", sSpeed);
        DispatchKeyValue(entityIndex, "StartSize", sStartSize);
        DispatchKeyValue(entityIndex, "EndSize", sEndSize);
        DispatchKeyValue(entityIndex, "Rate", sDensity);
        DispatchKeyValue(entityIndex, "JetLength", sLength);
        DispatchKeyValue(entityIndex, "Twist", sTwist); 
        DispatchKeyValue(entityIndex, "RenderColor", sColor);
        DispatchKeyValue(entityIndex, "RenderAmt", sTransparency); 
        DispatchKeyValue(entityIndex, "SmokeMaterial", sSpriteName);
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Activate the entity
        AcceptEntityInput(entityIndex, "TurnOn");
        
        // Validate parent
        if(parentIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetVariantString("!activator");
            AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);
            
            // Sets attachment to the entity
            if(strlen(sAttach))
            { 
                SetVariantString(sAttach); 
                AcceptEntityInput(entityIndex, "SetParentAttachment", parentIndex, entityIndex);
            }
        }

        // Validate duration
        if(flDurationTime > 0.0 && flRemoveTime > 0.0)
        {
            // Initialize flags char
            static char sFlags[SMALL_LINE_LENGTH];
            FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:TurnOff::%f:1", flRemoveTime);
            
            // Sets modified flags on the entity
            SetVariantString(sFlags);
            AcceptEntityInput(entityIndex, "AddOutput");
            AcceptEntityInput(entityIndex, "FireUser2");
            
            // Kill entity after delay
            UTIL_RemoveEntity(entityIndex, flDurationTime);
        }
    }
    
    // Return on the success
    return entityIndex;
}

/**
 * @brief Create a particle entity.
 * 
 * @param parentIndex       (Optional) The parent index.
 * @param vPosition         (Optional) The origin of the spawn.
 * @param vAngle            (Optional) The angle to the spawn.
 * @param sAttach           (Optional) The attachment name.
 * @param sEffect           The particle name.
 * @param flDurationTime    (Optional) The duration of an effect.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateParticle(int parentIndex = INVALID_ENT_REFERENCE, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sEffect, float flDurationTime = 0.0)
{
    // Create an attach particle entity
    int entityIndex = CreateEntityByName("info_particle_system");
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition);
        DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValue(entityIndex, "start_active", "1");
        DispatchKeyValue(entityIndex, "effect_name", sEffect);
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Validate parent
        if(parentIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetVariantString("!activator");
            AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);
            
            // Sets attachment to the entity
            if(strlen(sAttach))
            { 
                SetVariantString(sAttach); 
                AcceptEntityInput(entityIndex, "SetParentAttachment", parentIndex, entityIndex);
            }
        }
        
        // Activate the entity
        ActivateEntity(entityIndex);
        AcceptEntityInput(entityIndex, "Start");
        
        // Validate duration
        if(flDurationTime > 0.0)
        {
            // Kill entity after delay
            UTIL_RemoveEntity(entityIndex, flDurationTime);
        }
    }
    
    // Return on the success
    return entityIndex;
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
 * @param attackerIndex     (Optional) The attacker index.
 * @param inflictorIndex    (Optional) The inflictor index.
 * @param sIgnore           (Optional) Do not harm or affect the named entity.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateExplosion(float vPosition[3]/*, float vAngle[3] = NULL_VECTOR*/, int iFlags = 0, char[] sSpriteName = "materials/sprites/xfireball3.vmt", float flDamage = 0.0, float flRadius = 0.0, char[] sWeapon = "", int attackerIndex = INVALID_ENT_REFERENCE, int inflictorIndex = INVALID_ENT_REFERENCE, char[] sIgnore = "")
{
    // Create an explosion entity
    int entityIndex = CreateEntityByName("env_explosion");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));
        
        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition);
        ///DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValue(entityIndex, "spawnflags", sFlags);
        DispatchKeyValue(entityIndex, "fireballsprite", sSpriteName);
        if(!(iFlags & EXP_NODAMAGE))
        {
            DispatchKeyValue(entityIndex, "classname", sWeapon);
            IntToString(RoundToNearest(flDamage), sFlags, sizeof(sFlags));
            DispatchKeyValue(entityIndex, "iMagnitude", sFlags);
            IntToString(RoundToNearest(flRadius), sFlags, sizeof(sFlags));
            DispatchKeyValue(entityIndex, "iRadiusOverride", sFlags);
            if(hasLength(sIgnore)) DispatchKeyValue(entityIndex, "ignoredEntity", sIgnore);
        }
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Validate attacker
        if(attackerIndex != INVALID_ENT_REFERENCE)
        {
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", attackerIndex);
        }
            
        // Validate inflictor
        if(inflictorIndex != INVALID_ENT_REFERENCE)
        {
            SetEntPropEnt(entityIndex, Prop_Data, "m_hInflictor", inflictorIndex);
        }
        
        // Activate the entity
        AcceptEntityInput(entityIndex, "Explode");

        // Remove the entity from the world
        AcceptEntityInput(entityIndex, "Kill");
    }
    
    // Return on the success
    return entityIndex;
}

/**
 * @brief Create a sprite entity.
 * 
 * @param parentIndex       (Optional) The parent index. 
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
stock int UTIL_CreateSprite(int parentIndex = INVALID_ENT_REFERENCE, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sSprite, char[] sScale, char[] sRender, float flDurationTime = 0.0)
{
    // Create a sprite entity
    int entityIndex = CreateEntityByName("env_sprite");
    
    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition);
        DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValue(entityIndex, "model", sSprite);
        DispatchKeyValue(entityIndex, "scale", sScale);
        DispatchKeyValue(entityIndex, "rendermode", sRender);
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex);
        
        // Activate the entity
        ActivateEntity(entityIndex);
        
        // Validate parent
        if(parentIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetVariantString("!activator"); 
            AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);
            
            // Sets attachment to the entity
            if(hasLength(sAttach))
            { 
                SetVariantString(sAttach); 
                AcceptEntityInput(entityIndex, "SetParentAttachment", parentIndex, entityIndex);
            }
        }
        
        // Validate duration
        if(flDurationTime > 0.0)
        {
            // Kill entity after delay
            UTIL_RemoveEntity(entityIndex, flDurationTime);
        }
    }

    // Return on the success
    return entityIndex;
}

/**
 * @brief Create a material controlller entity.
 * 
 * @param parentIndex       The parent index. 
 * @param sSprite           The sprite path.
 * @param sVar              The name of the shader parameter you want to modify.
 *
 * @return                  The entity index.
 **/
stock int UTIL_CreateSpriteController(int parentIndex, char[] sSprite, char[] sVar)
{
    // Create a material controller entity
    int entityIndex = CreateEntityByName("material_modify_control");
    
    // If entity isn't valid, then skip
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        DispatchKeyValue(entityIndex, "materialName", sSprite);
        DispatchKeyValue(entityIndex, "materialVar", sVar);
        
        // Spawn the entity 
        DispatchSpawn(entityIndex);

        // Validate parent
        if(parentIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetVariantString("!activator");
            AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex);
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);
        }
    }
    
    // Return on the success
    return entityIndex;
}

/**
 * @brief Create a tesla entity.
 * 
 * @param parentIndex       (Optional) The parent index. 
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
stock int UTIL_CreateTesla(int parentIndex = INVALID_ENT_REFERENCE, float vPosition[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, char[] sAttach = "", char[] sRadius = "500.0", char[] sSound = "DoSpark", char[] sCountMin = "42", char[] sCountMax = "62", char[] sTextureName = "materials/sprites/physbeam.vmt", char[] sColor = "255 255 255", char[] sThickMin = "10.0", char[] sThickMax = "11.0", char[] sLifeMin = "0.3", char[] sLifeMax = "0.3", char[] sIntervalMin = "0.1", char[] sIntervalMax = "0.2", float flDurationTime = 0.0)
{
    // Create a tesla entity
    int entityIndex = CreateEntityByName("point_tesla");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition);
        DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValue(entityIndex, "m_flRadius", sRadius);  
        DispatchKeyValue(entityIndex, "m_SoundName", sSound);  
        DispatchKeyValue(entityIndex, "beamcount_min", sCountMin);  
        DispatchKeyValue(entityIndex, "beamcount_max", sCountMax);
        DispatchKeyValue(entityIndex, "texture", sTextureName);  
        DispatchKeyValue(entityIndex, "m_Color", sColor);  
        DispatchKeyValue(entityIndex, "thick_min", sThickMin);     
        DispatchKeyValue(entityIndex, "thick_max", sThickMax);     
        DispatchKeyValue(entityIndex, "lifetime_min", sLifeMin);  
        DispatchKeyValue(entityIndex, "lifetime_max", sLifeMax);  
        DispatchKeyValue(entityIndex, "interval_min", sIntervalMin);     
        DispatchKeyValue(entityIndex, "interval_max", sIntervalMax);   

        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Activate the entity
        ActivateEntity(entityIndex);
        AcceptEntityInput(entityIndex, "TurnOn");     
        AcceptEntityInput(entityIndex, "DoSpark");    

        // Validate parent
        if(parentIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetVariantString("!activator"); 
            AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);
            
            // Sets attachment to the entity
            if(hasLength(sAttach))
            { 
                SetVariantString(sAttach); 
                AcceptEntityInput(entityIndex, "SetParentAttachment", parentIndex, entityIndex);
            }
        }
        
        // Validate duration
        if(flDurationTime > 0.0)
        {
            // Kill entity after delay
            UTIL_RemoveEntity(entityIndex, flDurationTime);
        }
    }

    // Return on the success
    return entityIndex;
}

/**
 * @brief Create a shooter entity.
 * 
 * @param parentIndex       The parent index. 
 * @param sAttach           The attachment bone of the entity parent.
 * @param sRender           (Optional) Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
 * @param sSound            (Optional) Material Sound. (-1: None | 0: Glass | 1: Wood | 2: Metal | 3: Flesh | 4: Concrete)
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
stock int UTIL_CreateShooter(int parentIndex, char[] sAttach, char[] sRender = "5", char[] sSound = "-1", char[] sTextureName, float vAngle[3] = NULL_VECTOR, float vGibAngle[3] = NULL_VECTOR, float iGibs, float flDelay, float flVelocity, float flVariance, float flLife, float flDurationTime)
{
    // Create a shooter entity
    int entityIndex = CreateEntityByName("env_shooter");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Dispatch main values of the entity
        //DispatchKeyValueVector(entityIndex, "origin", vPosition);
        DispatchKeyValueVector(entityIndex, "angles", vAngle);
        DispatchKeyValueVector(entityIndex, "gibangles", vGibAngle);
        DispatchKeyValue(entityIndex, "rendermode", sRender);
        ///DispatchKeyValue(entityIndex, "rendercolor", sColor);
        ///DispatchKeyValue(entityIndex, "renderfx", sRenderFX); 
        DispatchKeyValue(entityIndex, "shootsounds", sSound);
        DispatchKeyValue(entityIndex, "shootmodel", sTextureName);
        DispatchKeyValueFloat(entityIndex, "m_iGibs", iGibs);
        DispatchKeyValueFloat(entityIndex, "delay", flDelay);
        DispatchKeyValueFloat(entityIndex, "m_flVelocity", flVelocity);
        DispatchKeyValueFloat(entityIndex, "m_flVariance", flVariance);
        DispatchKeyValueFloat(entityIndex, "m_flGibLife", flLife);

        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Activate the entity
        ActivateEntity(entityIndex);  
        AcceptEntityInput(entityIndex, "Shoot");

        // Sets parent to the entity
        SetVariantString("!activator"); 
        AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex); 
        SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);

        // Sets attachment to the entity
        if(hasLength(sAttach))
        { 
            SetVariantString(sAttach); 
            AcceptEntityInput(entityIndex, "SetParentAttachment", parentIndex, entityIndex);
        }

        // Kill entity after delay
        UTIL_RemoveEntity(entityIndex, flDurationTime);
    }
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
    // Create a beam entity
    int entityIndex = CreateEntityByName("env_beam");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize name char
        static char sClassname[SMALL_LINE_LENGTH];
        FormatEx(sClassname, sizeof(sClassname), "%s%i", sName, entityIndex);

        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));
        
        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vStartPosition);
        DispatchKeyValue(entityIndex, "targetname", sClassname);
        DispatchKeyValue(entityIndex, "damage", sDamage);
        DispatchKeyValue(entityIndex, "framestart", sFrame);
        DispatchKeyValue(entityIndex, "BoltWidth", sWidth);
        DispatchKeyValue(entityIndex, "renderfx", sRenderFX);
        DispatchKeyValue(entityIndex, "TouchType", sType);
        DispatchKeyValue(entityIndex, "framerate", sRate);
        DispatchKeyValue(entityIndex, "decalname", sDecalName);
        DispatchKeyValue(entityIndex, "TextureScroll", sScroll);
        DispatchKeyValue(entityIndex, "HDRColorScale", sScale);
        DispatchKeyValue(entityIndex, "texture", sTextureName);
        DispatchKeyValue(entityIndex, "life", sLife); 
        DispatchKeyValue(entityIndex, "StrikeTime", sStrike); 
        DispatchKeyValue(entityIndex, "LightningStart", sClassname);
        DispatchKeyValue(entityIndex, "spawnflags", sFlags); 
        DispatchKeyValue(entityIndex, "NoiseAmplitude", sAmplitude); 
        DispatchKeyValue(entityIndex, "Radius", sRadius);
        DispatchKeyValue(entityIndex, "renderamt", sRenderAMT);
        DispatchKeyValue(entityIndex, "rendercolor", sColor);

        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Activate the entity
        AcceptEntityInput(entityIndex, "TurnOff");
        AcceptEntityInput(entityIndex, "TurnOn");
        
        // Sets the model
        SetEntityModel(entityIndex, sTextureName);
        
        // Sets the size
        float flWidth = StringToFloat(sWidth);
        SetEntPropFloat(entityIndex, Prop_Data, "m_fWidth", flWidth);
        SetEntPropFloat(entityIndex, Prop_Data, "m_fEndWidth", flWidth);
        SetEntPropVector(entityIndex, Prop_Data, "m_vecEndPos", vEndPosition);

        // Validate duration
        if(flDurationTime > 0.0)
        {
            // Kill entity after delay
            UTIL_RemoveEntity(entityIndex, flDurationTime);
        }
        
        // Validate delay
        if(flDelayTime > 0.0)
        {
            // Initialize time char
            FormatEx(sFlags, sizeof(sFlags), "OnUser2 !self:TurnOff::%f:1", flDelayTime - 0.01);
            
            // Sets modified flags on the entity
            SetVariantString(sFlags);
            AcceptEntityInput(entityIndex, "AddOutput");
            
            // Initialize time char
            FormatEx(sFlags, sizeof(sFlags), "OnUser3 !self:TurnOn::%f:1", flDelayTime);
            
            // Sets modified flags on the entity
            SetVariantString(sFlags);
            AcceptEntityInput(entityIndex, "AddOutput");
            
            // Execute touch hook tweak
            SetVariantString("OnTouchedByEntity !self:FireUser2::0.0:-1");
            AcceptEntityInput(entityIndex, "AddOutput");
            SetVariantString("OnTouchedByEntity !self:FireUser3::0.0:-1");
            AcceptEntityInput(entityIndex, "AddOutput");
        }
    }
    
    // Return on the success
    return entityIndex;
}

/**
 * @brief Create a light dynamic entity.
 * 
 * @param parentIndex       (Optional) The parent index. 
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
stock int UTIL_CreateLight(int parentIndex = INVALID_ENT_REFERENCE, float vPosition[3] = NULL_VECTOR, char[] sAttach = "", char[] sInnerCone = "0", char[] sCone = "80", char[] sBrightness = "1", char[] sPitch = "90", char[] sStyle = "1", int iFlags = 0, char[] sColor, float flDistance, float flRadius, float flDurationTime = 0.0)
{
    // Create an light_dynamic entity
    int entityIndex = CreateEntityByName("light_dynamic");

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize flag char
        static char sFlags[SMALL_LINE_LENGTH];
        IntToString(iFlags, sFlags, sizeof(sFlags));

        // Dispatch main values of the entity
        DispatchKeyValueVector(entityIndex, "origin", vPosition); 
        DispatchKeyValue(entityIndex, "spawnflags", sFlags);
        DispatchKeyValue(entityIndex, "inner_cone", sInnerCone);
        DispatchKeyValue(entityIndex, "cone", sCone);
        DispatchKeyValue(entityIndex, "brightness", sBrightness);
        DispatchKeyValue(entityIndex, "pitch", sPitch);
        DispatchKeyValue(entityIndex, "style", sStyle);
        DispatchKeyValue(entityIndex, "_light", sColor);
        DispatchKeyValueFloat(entityIndex, "distance", flDistance);
        DispatchKeyValueFloat(entityIndex, "spotlight_radius", flRadius);

        // Spawn the entity into the world
        DispatchSpawn(entityIndex);

        // Activate the entity
        AcceptEntityInput(entityIndex, "TurnOn");

        // Validate parent
        if(parentIndex != INVALID_ENT_REFERENCE)
        {
            // Sets parent to the entity
            SetVariantString("!activator"); 
            AcceptEntityInput(entityIndex, "SetParent", parentIndex, entityIndex); 
            SetEntPropEnt(entityIndex, Prop_Send, "m_hOwnerEntity", parentIndex);
            
            // Sets attachment to the entity
            if(hasLength(sAttach))
            { 
                SetVariantString(sAttach); 
                AcceptEntityInput(entityIndex, "SetParentAttachment", parentIndex, entityIndex);
            }
        }
        
        // Validate duration
        if(flDurationTime > 0.0)
        {
            // Kill entity after delay
            UTIL_RemoveEntity(entityIndex, flDurationTime);
        }
    }
    
    // Return on the success
    return entityIndex;
}

/**
 * @brief Sets the glowing on the entity.
 * 
 * @param entityIndex       The entity index. (Must be validate before)
 * @param enableState       Sets to true to enable glowing, false to disable.
 * @param iType             (Optional) The type of the glowing.
 * @param iRed              (Optional) Amount of a red (0-255)
 * @param iGreen            (Optional) Amount of a green (0-255)
 * @param iBlue             (Optional) Amount of a blue (0-255)
 * @param iAlpha            (Optional) Amount of an alpha (0-255)
 **/
stock void UTIL_CreateGlowing(int entityIndex, bool enableState, int iType = 0, int iRed = 255, int iGreen = 255, int iBlue = 255, int iAlpha = 255)
{
    // Validate offset
    static int iGlowOffset;
    if(!iGlowOffset && (iGlowOffset = GetEntSendPropOffs(entityIndex, "m_clrGlow")) == -1)
    {
        return;
    }
    
    // Sets the glowing mode
    SetEntProp(entityIndex, Prop_Send, "m_bShouldGlow", enableState, true);
    SetEntProp(entityIndex, Prop_Send, "m_nGlowStyle", iType);
    SetEntPropFloat(entityIndex, Prop_Send, "m_flGlowMaxDist", 100000.0);
    
    // Sets the alpha and colors
    SetEntData(entityIndex, iGlowOffset + 0, iRed,   _, true);
    SetEntData(entityIndex, iGlowOffset + 1, iGreen, _, true);
    SetEntData(entityIndex, iGlowOffset + 2, iBlue,  _, true);
    SetEntData(entityIndex, iGlowOffset + 3, iAlpha, _, true);
}

/**
 * @brief Create the tracer to a entity. (*not client)
 *
 * @param parentIndex       The parent index.
 * @param sAttach           The attachment name.
 * @param sEffect           The effect name.
 * @param vBulletPosition   The position of a bullet hit.
 * @param flDurationTime    The duration of life.
 **/
stock void UTIL_CreateTracer(int parentIndex, char[] sAttach, char[] sEffect, float vBulletPosition[3], float flDurationTime)
{
    // Validate name
    if(!hasLength(sEffect))
    {
        return;
    }
    
    #define StaticSrt  0
    #define StaticEnd  1
                                /** Regards to Phoenix **/
                             /** Dont ask me how it works ;) **/


    // Initialize muzzle char
    static char sClassname[SMALL_LINE_LENGTH];

    // Create an attach particle entity
    static int entityIndex[2];
    entityIndex[StaticSrt] = CreateEntityByName("info_particle_system");
    entityIndex[StaticEnd] = CreateEntityByName("info_particle_system");

    // If entity isn't valid, then skip
    if(entityIndex[StaticEnd] != INVALID_ENT_REFERENCE) /// Check the last entity ;)
    {
        // Gets the entity angle
        static float vAngle[3]; static float vEmpty[3];
        GetEntPropVector(parentIndex, Prop_Data, "m_angAbsRotation", vAngle); 
        
        // Teleport the entity
        TeleportEntity(entityIndex[StaticEnd], vBulletPosition, vAngle, NULL_VECTOR);
        
        // Dispatch main values of the entity
        FormatEx(sClassname, sizeof(sClassname), "particle%d",  entityIndex[StaticSrt]);
        DispatchKeyValue(entityIndex[StaticSrt], "targetname", sClassname);
        DispatchKeyValue(entityIndex[StaticEnd], "effect_name", sEffect);
        DispatchKeyValue(entityIndex[StaticEnd], "cpoint1", sClassname);
        
        // Spawn the entity into the world
        DispatchSpawn(entityIndex[StaticEnd]);
        
        // Sets owner to the entity 
        SetEntPropEnt(entityIndex[StaticEnd], Prop_Send, "m_hOwnerEntity", parentIndex);

        // Teleport the entity
        TeleportEntity(entityIndex[StaticSrt], NULL_VECTOR, vAngle, NULL_VECTOR);

        // Sets parent to the entity
        SetVariantString("!activator");
        AcceptEntityInput(entityIndex[StaticSrt], "SetParent", parentIndex, entityIndex[StaticSrt]);
        
        // Sets attachment to the entity
        SetVariantString(sAttach);
        AcceptEntityInput(entityIndex[StaticSrt], "SetParentAttachment",  entityIndex[StaticSrt], entityIndex[StaticSrt]);

        // Teleport the entity
        TeleportEntity(entityIndex[StaticSrt], vEmpty, NULL_VECTOR, NULL_VECTOR);

        /*______________________________________________________________________________*/
        
        // Activate the entity
        ActivateEntity(entityIndex[StaticEnd]);
        AcceptEntityInput(entityIndex[StaticEnd], "Start");

        // Kill entities after delay
        UTIL_RemoveEntity(entityIndex[StaticEnd], flDurationTime);
        UTIL_RemoveEntity(entityIndex[StaticSrt], flDurationTime);
    }
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Shake a client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param flAmplitude       The amplitude of shake.
 * @param flFrequency       The frequency of shake.
 * @param flDurationTime    The duration of shake in the seconds.
 **/
stock void UTIL_CreateShakeScreen(int clientIndex, float flAmplitude, float flFrequency, float flDurationTime)
{
    // Create message
    Protobuf hShake = view_as<Protobuf>(StartMessageOne("Shake", clientIndex));

    // Validate message
    if(hShake != null)
    {
        // Write shake information to message handle
        hShake.SetInt("command", 0);
        hShake.SetFloat("local_amplitude", flAmplitude);
        hShake.SetFloat("frequency", flFrequency);
        hShake.SetFloat("duration", flDurationTime);

        // End usermsg and send to the client
        EndMessage();
    }
}

/**
 * @brief Fade a client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param flDuration        The duration of fade in the seconds.
 * @param flHoldTime        The holding time of fade in the seconds.
 * @param iFlags            The bits with some flags.
 * @param vColor            The array with RGB color.
 **/
stock void UTIL_CreateFadeScreen(int clientIndex, float flDuration, float flHoldTime, int iFlags, int vColor[4])
{
    // Create message
    Protobuf hFade = view_as<Protobuf>(StartMessageOne("Fade", clientIndex));

    // Validate message
    if(hFade != null)
    {
        // Write shake information to message handle
        hFade.SetInt("duration", RoundToNearest(flDuration * 1000.0)); 
        hFade.SetInt("hold_time", RoundToNearest(flHoldTime * 1000.0)); 
        hFade.SetInt("flags", iFlags); 
        hFade.SetColor("clr", vColor); 

        // End usermsg and send to the client
        EndMessage();
    }
}

/**
 * @brief Create a death event. *(Fake)
 * 
 * @param clientIndex       The victim index.
 * @param attackerIndex     The attacker index.
 * @param sIcon             The icon name.
 * @param bHead             (Optional) States the additional headshot icon.
 **/
stock void UTIL_CreateIcon(int clientIndex, int attackerIndex, char[] sIcon, bool bHead = false)
{
    // Validate victim/attacker
    if(/*!IsPlayerExist(clientIndex, false) || */!IsPlayerExist(attackerIndex, false))
    {
        return;
    }
    
    // Creates and send custom death icon
    Event hEvent = CreateEvent("player_death");
    if(hEvent != null)
    {
        // Sets event properties
        hEvent.SetInt("userid", GetClientUserId(clientIndex));
        hEvent.SetInt("attacker", GetClientUserId(attackerIndex));
        hEvent.SetString("weapon", sIcon);
        hEvent.SetBool("headshot", bHead);
        
        // i = client index
        for(int i = 1; i <= MaxClients; i++)
        {
            // Send fake event
            if(IsPlayerExist(i, false) && !IsFakeClient(i)) hEvent.FireToClient(i);
        }
        
        // Close it
        hEvent.Close();
    }
}

/**
 * @brief Push a client with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param vPosition         The force origin.
 * @param vOrigin           The client origin.
 * @param flDistance        The distance amount.
 * @param flForce           The force amount.
 * @param flRadius          The radius amount.
**/
stock void UTIL_CreatePhysForce(int clientIndex, float vPosition[3], float vOrigin[3], float flDistance, float flForce, float flRadius)
{
    // Calculate the velocity vector
    static float vVelocity[3];
    SubtractVectors(vOrigin, vPosition, vVelocity);
    
    // Calculate the push power
    float flKnockBack = flForce * (1.0 - (flDistance / flRadius));

    // Normalize the vector (equal magnitude at varying distances)
    NormalizeVector(vVelocity, vVelocity);

    // Apply the magnitude by scaling the vector
    ScaleVector(vVelocity, SquareRoot((flKnockBack * flKnockBack) / ((vVelocity[0] * vVelocity[0]) + (vVelocity[1] * vVelocity[1]) + (vVelocity[2] * vVelocity[2])))); vVelocity[2] * flForce;

    // Push the client
    TeleportEntity(clientIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);
}

/**
 * @brief Send a hint message to the client screen with specific parameters.
 * 
 * @param clientIndex       The client index.
 * @param sMessage          The message to send.
 **/
stock void UTIL_CreateClientHint(int clientIndex, char[] sMessage)
{
    // Create message
    Protobuf hMessage = view_as<Protobuf>(StartMessageOne("HintText", clientIndex));

    // Validate message
    if(hMessage != null)
    {
        // Write shake information to message handle
        hMessage.SetString("text", sMessage);

        // End usermsg and send to the client
        EndMessage();
    }
}

/**
 * @brief Send a hud message to the client screen with specific parameters.
 * 
 * @param hSync             New HUD synchronization object.
 * @param clientIndex       The client index.
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
stock void UTIL_CreateClientHud(Handle hSync, int clientIndex, float x, float y, float holdTime, int r, int g, int b, int a, int effect, float fxTime, float fadeIn, float fadeOut, char[] sMessage)
{
    // Sets HUD parameters for drawing text
    SetHudTextParams(x, y, holdTime, r, g, b, a, effect, fxTime, fadeIn, fadeOut);
    
    // Print translated phrase to the client screen
    ShowSyncHudText(clientIndex, hSync, sMessage);
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
    // Precache main model
    int modelIndex = PrecacheModel(sModel, true);
    
    // Adding main model to the download list
    AddFileToDownloadsTable(sModel);

    // Initialize path char
    static char sPath[PLATFORM_MAX_PATH];
    static const char sType[3][SMALL_LINE_LENGTH] = { ".dx90.vtx", ".phy", ".vvd" };

    // i = type index
    for(int i = 0; i < sizeof(sType); i++)
    {
        // Adding other parts to download list
        FormatEx(sPath, sizeof(sPath), "%s", sModel);
        ReplaceString(sPath, sizeof(sPath), ".mdl", sType[i]);
        if(!FileExists(sPath)) continue;
        AddFileToDownloadsTable(sPath);
    }
    
    // Return model index
    return modelIndex;
}

/**
 * @brief Ignites the entity on a fire.
 * 
 * @param entityIndex       The entity index. 
 * @param flDurationTime    The number of seconds to set on a fire.
 **/
stock void UTIL_IgniteEntity(int entityIndex, float flDurationTime)
{
    // Validate duration
    if(flDurationTime > 0.0) 
    {
        // Put fire on it
        IgniteEntity(entityIndex, flDurationTime);
    }
}

/**
 * @brief Extinguishes the entity that is on a fire.
 * 
 * @param entityIndex       The entity index. 
 **/
stock void UTIL_ExtinguishEntity(int entityIndex)
{
    // Validate fire entity
    int fireIndex = GetEntPropEnt(entityIndex, Prop_Data, "m_hEffectEntity");
    if(IsValidEdict(fireIndex))
    {
        // Make sure the entity is a flame, so we can extinguish it
        static char sClassname[SMALL_LINE_LENGTH];
        GetEdictClassname(fireIndex, sClassname, sizeof(sClassname));
        
        // Validate classname
        if(!strcmp(sClassname, "entityflame", false))
        {
            // Reduce entity's lifetime 
            SetEntPropFloat(fireIndex, Prop_Data, "m_flLifetime", 0.0);
        }
    }
}

/**
 * @brief Remove the entity from a world after some delay.
 * 
 * @param entityIndex       The entity index. 
 * @param flDelayTime       The number of seconds to kill an entity.
 **/
stock void UTIL_RemoveEntity(int entityIndex, float flDelayTime)
{
    // Initialize flags char
    static char sFlags[SMALL_LINE_LENGTH];
    FormatEx(sFlags, sizeof(sFlags), "OnUser1 !self:Kill::%f:1", flDelayTime);
    
    // Sets modified flags on the entity
    SetVariantString(sFlags);
    AcceptEntityInput(entityIndex, "AddOutput");
    AcceptEntityInput(entityIndex, "FireUser1");
}

/**
 * @brief Precache decals and also adding them into the downloading table.
 * 
 * @param sDecal            The decal path.
 *
 * @return                  The decal index.
 **/
stock void UTIL_PrecacheDecal(char[] sDecal)
{
    // Precache main decal
    int decalIndex = PrecacheDecal(sDecal, true);
    
    // Adding main decal to the download list
    AddFileToDownloadsTable(sDecal);

    // Initialize path char
    static char sPath[PLATFORM_MAX_PATH];
    
    // Adding other parts to download list
    FormatEx(sPath, sizeof(sPath), "%s", sDecal);
    ReplaceString(sPath, sizeof(sPath), ".vtf", ".vmt");
    if(FileExists(sPath)) AddFileToDownloadsTable(sPath);
    
    // Return decal index
    return decalIndex;
}

/**
 * @brief Precache sounds and also adding them into the downloading table.
 * 
 * @param soundPath         The sound path.
 **/
stock void UTIL_PrecacheSound(char[] sSound)
{
    // Initialize path char
    static char sPath[PLATFORM_MAX_PATH];
    
    // Adding sound to the download list
    FormatEx(sPath, sizeof(sPath), "sound/%s", sSound);
    if(!FileExists(sPath)) return;
    AddFileToDownloadsTable(sPath);
    
    // Precache sound
    FormatEx(sPath, sizeof(sPath), "*/%s", sSound);
    AddToStringTable(FindStringTable("soundprecache"), sPath);
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Dispatch an attached effect.
 * 
 * @param entityIndex       (Optional) The entity index.
 * @param sParticle         (Optional) The particle name.
 * @param sIndex            (Optional) The particle item.
 * @param vStart            (Optional) The start origin.
 * @param vEnd              (Optional) The end origin.
 * @param vAngle            (Optional) The angle vector.
 * @param iAttachment       (Optional) The attachment index.
 **/
stock void TE_DispatchEffect(int entityIndex = 0, char[] sParticle = "", char[] sIndex = "", float vStart[3] = NULL_VECTOR, float vEnd[3] = NULL_VECTOR, float vAngle[3] = NULL_VECTOR, int iAttachment = 0) 
{
    // Dispatch effect
    TE_Start("EffectDispatch");
    if(strlen(sParticle)) TE_WriteNum("m_nHitBox", GetParticleEffectIndex(sParticle));
    if(strlen(sIndex)) TE_WriteNum("m_iEffectName", GetEffectIndex(sIndex));
    TE_WriteFloat("m_vOrigin.x", vEnd[0]);
    TE_WriteFloat("m_vOrigin.y", vEnd[1]);
    TE_WriteFloat("m_vOrigin.z", vEnd[2]);
    TE_WriteFloat("m_vStart.x", vStart[0]);
    TE_WriteFloat("m_vStart.y", vStart[1]);
    TE_WriteFloat("m_vStart.z", vStart[2]);
    TE_WriteVector("m_vAngles", vAngle);
    TE_WriteNum("entindex", entityIndex);
    if(iAttachment) 
    {
        #define PATTACH_WORLDORIGIN 5
        #define PARTICLE_DISPATCH_FROM_ENTITY (1<<0)
    
        TE_WriteNum("m_nDamageType", PATTACH_WORLDORIGIN);
        TE_WriteNum("m_fFlags", PARTICLE_DISPATCH_FROM_ENTITY); /// https://developer.valvesoftware.com/wiki/SDK_Known_Issues_List_Fixed#Server%20Dispatching%20an%20Attached%20Particle%20Effect
        TE_WriteNum("m_nAttachmentIndex", iAttachment);
    }
}

/**
 * @brief Searches for the index of a given string in a dispatch table.
 *
 * @param sEffect           The effect name.
 *
 * @return                  The item index.
 **/
stock int GetEffectIndex(char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("EffectDispatch");
    }

    // Searches for the index of a given string in a string table
    int itemIndex = FindStringIndex(tableIndex, sEffect);

    // Validate item
    if(itemIndex != INVALID_STRING_INDEX)
    {
        return itemIndex;
    }

    // Return on the unsuccess
    return 0;
}

/**
 * @brief Searches for the index of a given string in an effect table.
 *
 * @param sEffect           The effect name.
 *
 * @return                  The item index.
 **/
stock int GetParticleEffectIndex(char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;

    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }

    // Searches for the index of a given string in a string table
    int itemIndex = FindStringIndex(tableIndex, sEffect);

    // Validate item
    if(itemIndex != INVALID_STRING_INDEX)
    {
        return itemIndex;
    }

    // Return on the unsuccess
    return 0;
}

/*_____________________________________________________________________________________________________________*/

/**
 * @brief Returns true if the player is connected and alive, false if not.
 *
 * @param clientIndex       The client index.
 * @param bAlive            (Optional) Set to true to validate that the client is alive, false to ignore.
 *  
 * @return                  True or false.
 **/
stock bool IsPlayerExist(int clientIndex, bool bAlive = true)
{
    // If client isn't valid, then stop
    if(clientIndex <= 0 || clientIndex > MaxClients)
    {
        return false;
    }

    // If client isn't connected, then stop
    if(!IsClientConnected(clientIndex))
    {
        return false;
    }

    // If client isn't in game, then stop
    if(!IsClientInGame(clientIndex) || IsClientInKickQueue(clientIndex))
    {
        return false;
    }

    // If client is TV, then stop
    if(IsClientSourceTV(clientIndex))
    {
        return false;
    }

    // If client isn't alive, then stop
    if(bAlive && !IsPlayerAlive(clientIndex))
    {
        return false;
    }

    // If client exist
    return true;
}

/**
 * @brief Returns whether a player is in a spesific group or not.
 *
 * @param clientIndex       The client index.
 * @param sGroup            The SourceMod group name to check.
 *
 * @return                  True or false.
 **/
stock bool IsPlayerInGroup(int clientIndex, char[] sGroup)
{
    // Validate client
    if(!IsPlayerExist(clientIndex, false))
    {
        return false;
    }

    /*********************************
     *                               *
     *   FLAG GROUP AUTHENTICATION   *
     *                               *
     *********************************/

    // Finds a group by name
    GroupId nGroup = FindAdmGroup(sGroup);
    
    // Validate group
    if(nGroup == INVALID_GROUP_ID)
    {
        return false;
    }
     
    // Retrieves a client AdminId
    AdminId iD = GetUserAdmin(clientIndex);
    
    // Validate id
    if(iD == INVALID_ADMIN_ID)
    {
        return false;
    }

    // Initialize group char
    static char sGroupName[SMALL_LINE_LENGTH];

    // Gets immunity level
    int iImmunity = GetAdmGroupImmunityLevel(nGroup);
    
    // i = group index
    int iSize = GetAdminGroupCount(iD);
    for(int i = 0; i < iSize; i++)
    {
        // Gets group name
        nGroup = GetAdminGroup(iD, i, sGroupName, sizeof(sGroupName));

        // Validate groups
        if(!strcmp(sGroup, sGroupName, false) || iImmunity <= GetAdmGroupImmunityLevel(nGroup))
        {
            return true;
        }
    }
    
    // No groups or no match
    return false;
}