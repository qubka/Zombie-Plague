/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          global.cpp
 *  Type:          Main
 *  Description:   General plugin functions.
 *
 *  Copyright (C) 2015-2020 Nikita Ushakov (Ireland, Dublin)
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
    ArrayList Clients;
    ArrayList LastZombies;
    
    /* Map */
    bool MapLoaded;
    ArrayList Spawns;
    ArrayList Particles;
    
    /* OS */
    Address Engine;
    EngineOS Platform;
    
    /* Timer */
    Handle CounterTimer;
    
    /* Sounds */
    Handle EndTimer; 
    Handle BlastTimer;
    
    /* Gamedata */
    Handle Config;
    Handle SDKHooks;
    Handle SDKTools;
    Handle CStrike;

    /* Database */
    Database DBI;
    StringMap Cols;
    StringMapSnapshot Columns;
    
    /* Synchronizers */
    Handle LevelSync;
    Handle AccountSync;
    Handle GameSync;
    
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
    StringMap Configs;
    StringMap Modules;
    
    /* Weapons */
    int Melee;
    StringMap Market;

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
    int AccountID;
    bool Zombie;
    bool Loaded;
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
    int Costume;
    int Time;
    bool Vision;
    int DataID;
    int LastID;
    int LastAttacker;
    int TeleTimes;
    int TeleCounter;
    float TeleOrigin[3];
    float HealthDuration;
    int AttachmentCostume;
    int AttachmentHealth;
    int AttachmentController;
    int AttachmentBits;
    int AttachmentAddons[12]; /* Amount of weapon back attachments */
    
    /* Weapons */
    int ViewModels[2];
    int IndexWeapon;
    int CustomWeapon;
    int LastWeapon;
    int LastGrenade;
    int LastKnife;
    int SwapWeapon;
    int LastSequence;
    int LastSequenceParity;
    bool ToggleSequence;
    bool RunCmd;
    
    /* Timers */
    Handle LevelTimer;
    Handle AccountTimer;
    Handle RespawnTimer;
    Handle SkillTimer;
    Handle CounterTimer;
    Handle HealTimer;
    Handle SpriteTimer;
    Handle MoanTimer;
    Handle AmbientTimer;
    Handle BuyTimer;
    Handle TeleTimer;
    
    /* Arrays */
    ArrayList ShoppingCart;
    ArrayList DefaultCart;
    StringMap ItemLimit;
    StringMap WeaponLimit;
    
    /**
     * @brief Resets all variables.
     **/
    void ResetVars(/*void*/)
    {
        this.AccountID            = 0;                
        this.Zombie               = false;
        this.Loaded               = false;
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
        this.Costume              = -1;
        this.Time                 = 0;
        this.Vision               = true;
        this.DataID               = -1;
        this.LastID               = -1;
        this.LastAttacker         = 0;
        this.TeleTimes            = 0;
        this.TeleCounter          = 0;
        this.TeleOrigin           = NULL_VECTOR;
        this.HealthDuration       = 0.0;
        this.AttachmentCostume    = -1;
        this.AttachmentHealth     = -1;
        this.AttachmentController = -1;
        this.AttachmentBits       = 0;
        this.AttachmentAddons[0]  = -1;
        this.AttachmentAddons[1]  = -1; 
        this.AttachmentAddons[2]  = -1; 
        this.AttachmentAddons[3]  = -1; 
        this.AttachmentAddons[4]  = -1;
        this.AttachmentAddons[5]  = -1; 
        this.AttachmentAddons[6]  = -1; 
        this.AttachmentAddons[7]  = -1; 
        this.AttachmentAddons[8]  = -1; 
        this.AttachmentAddons[9]  = -1;
        this.AttachmentAddons[10] = -1;
        this.AttachmentAddons[11] = -1;
        this.ViewModels[0]        = -1;
        this.ViewModels[1]        = -1;
        this.IndexWeapon          = -1;
        this.CustomWeapon         = -1;
        this.LastWeapon           = -1;
        this.LastGrenade          = -1;
        this.LastKnife            = -1;
        this.SwapWeapon           = -1;
        this.LastSequence         = -1;
        this.LastSequenceParity   = -1;
        this.ToggleSequence       = false;
        this.RunCmd               = false;
       
        delete this.ShoppingCart;
        delete this.DefaultCart;
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
        delete this.CounterTimer;
        delete this.HealTimer;
        delete this.SpriteTimer;
        delete this.MoanTimer;
        delete this.AmbientTimer;
        delete this.BuyTimer;
        delete this.TeleTimer;
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
        this.CounterTimer = null;
        this.HealTimer    = null;
        this.SpriteTimer  = null;
        this.MoanTimer    = null; 
        this.AmbientTimer = null; 
        this.BuyTimer     = null;
        this.TeleTimer     = null;
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
#define _call.%0(%1)  RequestFrame(%0, GetClientUserId(%1))
#define _exec.%0(%1)  RequestFrame(%0, EntIndexToEntRef(%1))
/**
 * @endsection
 **/
 
/**
 * @brief Called when an entity is created.
 *
 * @param entity            The entity index.
 * @param sClassname        The string with returned name.
 **/
public void OnEntityCreated(int entity, const char[] sClassname)
{
    // Forward event to modules
    WeaponOnEntityCreated(entity, sClassname);
    HitGroupsOnEntityCreated(entity, sClassname);
}