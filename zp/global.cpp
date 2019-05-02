/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          global.cpp
 *  Type:          Main
 *  Description:   General plugin functions.
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

/**
 * @section Variables to store offset values.
 **/
int g_iOffset_Velocity;
int g_iOffset_Origin;
int g_iOffset_Angles;
int g_iOffset_LMV;
int g_iOffset_Render;
int g_iOffset_NightVisionOn;
int g_iOffset_HasNightVision;
int g_iOffset_HasDefuser;
int g_iOffset_Fov;
int g_iOffset_DefaultFOV;
int g_iOffset_Account;
int g_iOffset_Spotted;
int g_iOffset_SpottedByMask;
int g_iOffset_CanBeSpotted;
int g_iOffset_Detected;
int g_iOffset_HUD;
int g_iOffset_HitGroup;
int g_iOffset_Armor;
int g_iOffset_HasHeavyArmor;
int g_iOffset_HasHelmet;
int g_iOffset_Health;
int g_iOffset_MaxHealth;
int g_iOffset_Gravity;
int g_iOffset_Frags;
int g_iOffset_Death;
int g_iOffset_Collision;
int g_iOffset_Ragdoll;
int g_iOffset_Model;
int g_iOffset_ActiveWeapon;
int g_iOffset_MyWeapons;
int g_iOffset_ObserverMode;
int g_iOffset_ObserverTarget;
int g_iOffset_Attack;
int g_iOffset_Arms;
int g_iOffset_AddonBits;
int g_iOffset_ShotsFired;
int g_iOffset_Direction;
int g_iOffset_ModelIndex;
int g_iOffset_OwnerEntity;
int g_iOffset_Team;
int g_iOffset_Effects;
int g_iOffset_Effect;
int g_iOffset_Body;
int g_iOffset_Skin;
int g_iOffset_LightingOrigin;
int g_iOffset_Activator;
int g_iOffset_HammerID;
int g_iOffset_Owner;
int g_iOffset_WorldModel;
int g_iOffset_WorldSkin;
int g_iOffset_AmmoType;
int g_iOffset_Clip1;
int g_iOffset_Clip2;
int g_iOffset_Reserve1;
int g_iOffset_Reserve2;
int g_iOffset_PrimaryAttack;
int g_iOffset_SecondaryAttack;
int g_iOffset_TimeIdle;
int g_iOffset_LastShotTime;
int g_iOffset_RecoilIndex;
int g_iOffset_SwitchingSilencer;
int g_iOffset_SilencerOn;
int g_iOffset_GrenadeThrower;
int g_iOffset_ModelOwner;
int g_iOffset_ModelWeapon;
int g_iOffset_ModelSequence;
int g_iOffset_ModelPlaybackRate;
int g_iOffset_ModelViewIndex;
int g_iOffset_ModelIgnoreOffsAcc;
int g_iOffset_ItemDefinitionIndex;
int g_iOffset_ItemDefinition;
int g_iOffset_NewSequenceParity;
int g_iOffset_LagCompensation;
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
 * @section Struct of operation types for server arrays.
 **/
enum struct ServerData
{
    /* Globals */
    bool RoundNew;
    bool RoundEnd;
    bool RoundStart;
    int RoundNumber;
    int RoundMode;
    int RoundLast;
    int RoundCount;
    
    /* Map */
    bool MapLoaded;
    ArrayList Spawns;
    ArrayList Particles;
    
    /* OS */
    EngineOS Platform;
    
    /* Timer */
    Handle CounterTimer;
    
    /// Sounds 
    Handle EndTimer; 
    Handle BlastTimer;
    
    /* Gamedata */
    Handle Config;
    Handle SDKHooks;
    Handle SDKTools;
    Handle CStrike;
    
    /* Database */
    Database DataBase;
    
    /* Synchronizers */
    Handle LevelSync;
    Handle AccountSync;
    Handle GameSync;
    Handle SkillSync[2];
    
    /* Configs */
    ArrayList ExtraItems;
    ArrayList HitGroups;
    ArrayList GameModes;
    ArrayList Cvars;
    ArrayList Classes;
    ArrayList Types;
    ArrayList Costumes;
    ArrayList Menus;
    ArrayList Logs;
    ArrayList Weapons;
    ArrayList Downloads;
    ArrayList Sounds;
    ArrayList Levels;
    
    /**
     * @brief Clear all timers.
     **/
    void PurgeTimers(/*void*/)
    {
        this.CounterTimer = null;
        this.EndTimer     = null;
        this.BlastTimer   = null;
    }
}
/**
 * @endsection
 **/

/**
 * Array to store the server data.
 **/
ServerData gServerData;

/**
 * @section Struct of operation types for client arrays.
 **/
enum struct ClientData
{
    /* Globals */
    bool Zombie;
    bool Loaded;
    bool AutoRebuy;
    bool Skill;
    float SkillCounter;
    int Class;
    int HumanClassNext;
    int ZombieClassNext;
    int Respawn;
    int RespawnTimes;
    int Money;
    int LastPurchase;
    int Level;
    int Exp;
    int DataID;
    int Costume;
    bool Vision;
    int Time;
    int LastID;
    int LastAttacker;
    int LastKnife;
    float HealthDuration;
    int AttachmentCostume;
    int AttachmentHealth;
    int AttachmentController;
    int AttachmentBits;
    int AttachmentAddons[11]; /* Amount of weapon back attachments */
    
    /* Weapons */
    int ViewModels[2];
    int IndexWeapon;
    int CustomWeapon;
    int LastWeapon;
    int SwapWeapon;
    int LastSequence;
    int DrawSequence;
    bool ToggleSequence;
    int LastSequenceParity;
    bool RunCmd;
    
    /* Timers */
    Handle LevelTimer;
    Handle AccountTimer;
    Handle RespawnTimer;
    Handle SkillTimer;
    Handle BarTimer;
    Handle CounterTimer;
    Handle HealTimer;
    Handle SpriteTimer;
    Handle MoanTimer;
    Handle AmbientTimer;
    Handle BuyTimer;
    
    /* Arrays */
    ArrayList ShoppingCart;
    StringMap ItemLimit;
    StringMap WeaponLimit;
    
    /**
     * @brief Resets all variables.
     **/
    void ResetVars(/*void*/)
    {
        this.Zombie               = false;
        this.Loaded               = false;
        this.AutoRebuy            = false;
        this.Skill                = false;
        this.SkillCounter         = 0.0;
        this.Class                = 0;
        this.HumanClassNext       = 0;
        this.ZombieClassNext      = 0;
        this.Respawn              = TEAM_HUMAN;
        this.RespawnTimes         = 0;
        this.Money                = 0;
        this.LastPurchase         = 0;
        this.Level                = 1;
        this.Exp                  = 0;
        this.DataID               = -1;
        this.Costume              = -1;
        this.Vision               = true;
        this.Time                 = 0;
        this.LastID               = -1;
        this.LastAttacker         = 0;
        this.LastKnife            = INVALID_ENT_REFERENCE;
        this.HealthDuration       = 0.0;
        this.AttachmentCostume    = INVALID_ENT_REFERENCE;
        this.AttachmentHealth     = INVALID_ENT_REFERENCE;
        this.AttachmentController = INVALID_ENT_REFERENCE;
        this.AttachmentBits       = 0;
        this.AttachmentAddons[0]  = INVALID_ENT_REFERENCE;
        this.AttachmentAddons[1]  = INVALID_ENT_REFERENCE; 
        this.AttachmentAddons[2]  = INVALID_ENT_REFERENCE; 
        this.AttachmentAddons[3]  = INVALID_ENT_REFERENCE; 
        this.AttachmentAddons[4]  = INVALID_ENT_REFERENCE;
        this.AttachmentAddons[5]  = INVALID_ENT_REFERENCE; 
        this.AttachmentAddons[6]  = INVALID_ENT_REFERENCE; 
        this.AttachmentAddons[7]  = INVALID_ENT_REFERENCE; 
        this.AttachmentAddons[8]  = INVALID_ENT_REFERENCE; 
        this.AttachmentAddons[9]  = INVALID_ENT_REFERENCE;
        this.AttachmentAddons[10] = INVALID_ENT_REFERENCE;
        this.ViewModels[0]        = INVALID_ENT_REFERENCE;
        this.ViewModels[1]        = INVALID_ENT_REFERENCE;
        this.IndexWeapon          = INVALID_ENT_REFERENCE;
        this.CustomWeapon         = INVALID_ENT_REFERENCE;
        this.LastWeapon           = INVALID_ENT_REFERENCE;
        this.SwapWeapon           = INVALID_ENT_REFERENCE;
        this.LastSequence         = -1;
        this.DrawSequence         = -1;
        this.ToggleSequence       = false;
        this.LastSequenceParity   = -1;
        this.RunCmd               = false;
       
        delete this.ShoppingCart;
        delete this.ItemLimit;
        delete this.WeaponLimit;
    }
    
    /**
     * @brief Delete all timers.
     **/
    void ResetTimers(/*void*/)
    {
        delete this.LevelTimer;
        delete this.AccountTimer;
        delete this.RespawnTimer;
        delete this.SkillTimer;
        delete this.BarTimer;
        delete this.CounterTimer;
        delete this.HealTimer;
        delete this.SpriteTimer;
        delete this.MoanTimer;
        delete this.AmbientTimer;
        delete this.BuyTimer;
    }
    
    /**
     * @brief Clear all timers.
     **/
    void PurgeTimers(/*void*/)
    {
        this.LevelTimer   = null;
        this.AccountTimer = null;
        this.RespawnTimer = null;
        this.SkillTimer   = null;
        this.BarTimer     = null;
        this.CounterTimer = null;
        this.HealTimer    = null;
        this.SpriteTimer  = null;
        this.MoanTimer    = null; 
        this.AmbientTimer = null; 
        this.BuyTimer     = null;
    }
}
/**
 * @endsection
 **/
 
/**
 * Array to store the client data.
 **/
ClientData gClientData[MAXPLAYERS+1];

/**
 * @section Core useful functions.
 **/
#define _call.%0(%1)  RequestFrame(view_as<RequestFrameCallback>(%0), GetClientUserId(%1))
#define _next.%0(%1)  RequestFrame(view_as<RequestFrameCallback>(%0), EntIndexToEntRef(%1))
/**
 * @endsection
 **/
 
/**
 * @brief Called when an entity is created.
 *
 * @param entityIndex       The entity index.
 * @param sClassname        The string with returned name.
 **/
public void OnEntityCreated(int entityIndex, const char[] sClassname)
{
    // Forward event to modules
    WeaponOnEntityCreated(entityIndex, sClassname);
    HitGroupsOnEntityCreated(entityIndex, sClassname);
}