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
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

/**
 * @section Core static macroses.
 **/
#define SMALL_LINE_LENGTH       32
#define NORMAL_LINE_LENGTH      64
#define BIG_LINE_LENGTH         128
#define CHAT_LINE_LENGTH        192
#define PLATFORM_LINE_LENGTH    256
#define HUGE_LINE_LENGTH        512
#define CONSOLE_LINE_LENGTH     1024
#define FILE_LINE_LENGTH        2048
#define TEAM_NONE               0    /**< No team yet */
#define TEAM_SPECTATOR          1    /**< Spectators */
#define TEAM_ZOMBIE             2    /**< Zombies */
#define TEAM_HUMAN              3    /**< Humans */
#define SPECMODE_NONE           0
#define SPECMODE_FIRSTPERSON    4
#define SPECMODE_3RDPERSON      5
#define SPECMODE_FREELOOK       6
/**
 * @endsection
 **/

/**
 * @section Variables to store offset values.
 **/
int g_iOffset_PlayerVelocity;
int g_iOffset_PlayerLMV;
int g_iOffset_PlayerNightVisionOn;
int g_iOffset_PlayerHasNightVision;
int g_iOffset_PlayerHasDefuser;
int g_iOffset_PlayerFov;
int g_iOffset_PlayerDefaultFOV;
int g_iOffset_PlayerAccount;
int g_iOffset_PlayerSpotted;
int g_iOffset_PlayerSpottedByMask;
int g_iOffset_PlayerDetected;
int g_iOffset_PlayerHUD;
int g_iOffset_PlayerHitGroup;
int g_iOffset_PlayerArmor;
int g_iOffset_PlayerHasHeavyArmor;
int g_iOffset_PlayerHasHelmet;
int g_iOffset_PlayerHealth;
int g_iOffset_PlayerMaxHealth;
int g_iOffset_PlayerGravity;
int g_iOffset_PlayerFrags;
int g_iOffset_PlayerDeath;
int g_iOffset_PlayerCollision;
int g_iOffset_PlayerRagdoll;
int g_iOffset_PlayerViewModel;
int g_iOffset_PlayerActiveWeapon;
int g_iOffset_PlayerLastWeapon;
int g_iOffset_PlayerObserverMode;
int g_iOffset_PlayerObserverTarget;
int g_iOffset_PlayerAttack;
int g_iOffset_PlayerArms;
int g_iOffset_PlayerAddonBits;
int g_iOffset_EntityModelIndex;
int g_iOffset_EntityOwnerEntity;
int g_iOffset_EntityTeam;
int g_iOffset_EntityEffects;
int g_iOffset_EntityOrigin;
int g_iOffset_WeaponID;
int g_iOffset_WeaponOwner;
int g_iOffset_WeaponWorldModel;
int g_iOffset_WeaponWorldSkin;
int g_iOffset_WeaponBody;
int g_iOffset_WeaponSkin;
int g_iOffset_WeaponAmmoType;
int g_iOffset_WeaponClip1;
int g_iOffset_WeaponReserve1;
int g_iOffset_WeaponReserve2;
int g_iOffset_WeaponPrimaryAttack;
int g_iOffset_WeaponSecondaryAttack;
int g_iOffset_WeaponIdle;
int g_iOffset_CharacterWeapons;
int g_iOffset_GrenadeThrower;
int g_iOffset_ViewModelOwner;
int g_iOffset_ViewModelWeapon;
int g_iOffset_ViewModelSequence;
int g_iOffset_ViewModelPlaybackRate;
int g_iOffset_ViewModelIndex;
int g_iOffset_ViewModelIgnoreOffsAcc;
int g_iOffset_EconItemDefinitionIndex;
int g_iOffset_NewSequenceParity;
int g_iOffset_LastShotTime;
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
    OS_Linux,
    OS_Mac
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
    
    /* OS */
    EngineOS Platform;
    
    /* Timer */
    Handle CounterTimer;
    
    /* Gamedata */
    Handle Config;
    Handle SDKHooks;
    Handle SDKTools;
    Handle CStrike;
    
    /* Database */
    Database DataBase;
    
    /* Synchronizers */
    Handle Account;
    Handle Level;
    Handle Game;
    Handle Skill[2];
    
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
};
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
    int LastBoughtAmount;
    int Level;
    int Exp;
    int DataID;
    int Costume;
    int Time;
    int AttachmentCostume;
    int AttachmentBits;
    int AttachmentAddons[11]; /* Amount of weapon back attachments */
    
    /* Weapons */
    int ViewModels[2];
    int IndexWeapon;
    int CustomWeapon;
    int SwapWeapon;
    int LastSequence;
    int DrawSequence;
    bool ToggleSequence;
    int LastSequenceParity;

    /* Timers */
    Handle LevelTimer;
    Handle AccountTimer;
    Handle RespawnTimer;
    Handle SkillTimer;
    Handle BarTimer;
    Handle CounterTimer;
    Handle HealTimer;
    Handle MoanTimer;
    Handle AmbientTimer;
    
    /* Arrays */
    ArrayList ShoppingCart;
    StringMap ItemLimit;
    
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
        this.LastBoughtAmount     = 0;
        this.Level                = 1;
        this.Exp                  = 0;
        this.DataID               = -1;
        this.Costume              = -1;
        this.Time                 = 0;
        this.AttachmentCostume    = INVALID_ENT_REFERENCE;
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
        this.SwapWeapon           = INVALID_ENT_REFERENCE;
        this.LastSequence         = -1;
        this.DrawSequence         = -1;
        this.ToggleSequence       = false;
        this.LastSequenceParity   = -1;
       
        delete this.ShoppingCart;
        delete this.ItemLimit;
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
        delete this.MoanTimer;
        delete this.AmbientTimer;
    }
    
    /**
     * @brief Clear all timers.
     **/
    void PurgeTimers(/*void*/)
    {
        this.LevelTimer     = null;
        this.AccountTimer   = null;
        this.RespawnTimer   = null;
        this.SkillTimer     = null;
        this.BarTimer       = null;
        this.CounterTimer   = null;
        this.HealTimer      = null;    
        this.MoanTimer      = null; 
        this.AmbientTimer   = null; 
    }
};
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
#define hasLength(%0) (%0[0] != '\0') 
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
}