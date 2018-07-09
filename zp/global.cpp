/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          global.cpp
 *  Type:          Main 
 *  Description:   General plugin functions.
 *
 *  Copyright (C) 2015-2018 Nikita Ushakov (Ireland, Dublin)
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
 * @section: Core static macroses.
 **/
#define SMALL_LINE_LENGTH   32
#define NORMAL_LINE_LENGTH  64
#define BIG_LINE_LENGTH     128
#define MAXENTITIES         2048
#define TEAM_NONE           0    /**< No team yet */
#define TEAM_SPECTATOR      1    /**< Spectators */
#define TEAM_ZOMBIE         2    /**< Zombies */
#define TEAM_HUMAN          3    /**< Humans */
#define TEAM_OBSERVER       4    /**< Observers */
/**
 * @endsection
 **/

/**
 * @section Variables to store offset values.
 **/
int g_iOffset_PlayerVelocity;
int g_iOffset_PlayerLMV;
int g_iOffset_PlayerHasNightVision;
int g_iOffset_PlayerNightVisionOn;
int g_iOffset_PlayerDefaultFOV;
int g_iOffset_PlayerAccount;
int g_iOffset_PlayerSpotted;
int g_iOffset_PlayerDetected;
int g_iOffset_PlayerHUD;
int g_iOffset_PlayerHitGroup;
int g_iOffset_PlayerFlashLight;
int g_iOffset_EntityEffects;
int g_iOffset_PlayerArmor;
int g_iOffset_PlayerHealth;
int g_iOffset_PlayerGravity;
int g_iOffset_PlayerFrags;
int g_iOffset_PlayerDeath;
int g_iOffset_PlayerCollision;
int g_iOffset_PlayerRagdool;
int g_iOffset_EntityModelIndex;
int g_iOffset_EntityOwnerEntity;
int g_iOffset_WeaponOwner;
int g_iOffset_WeaponWorldModel;
int g_iOffset_WeaponWorldSkin;
int g_iOffset_WeaponBody;
int g_iOffset_WeaponSkin;
int g_iOffset_CharacterWeapons;
int g_iOffset_PlayerViewModel;
int g_iOffset_PlayerActiveWeapon;
int g_iOffset_PlayerObserverMode;
int g_iOffset_PlayerObserverTarget;
int g_iOffset_PlayerArms;
int g_iOffset_PlayerAddonBits;
int g_iOffset_ViewModelOwner;
int g_iOffset_ViewModelWeapon;
int g_iOffset_ViewModelSequence;
int g_iOffset_ViewModelPlaybackRate;
int g_iOffset_ViewModelIndex;
int g_iOffset_ViewModelIgnoreOffsAcc;
int g_iOffset_EconItemDefinitionIndex;
int g_iOffset_NewSequenceParity;
int g_iOffset_LastShotTime;
int g_iOffset_PlayerAmmo;
int g_iOffset_WeaponAmmoType;
int g_iOffset_WeaponClip1;
int g_iOffset_WeaponReserve;
int g_iOffset_WeaponAttachment;
int g_iOffset_GrenadeThrower;
/**
 * @endsection
 **/
 
/**
 * List of operation types for global array.
 **/
enum ServerData
{
    bool:Server_RoundNew,
    bool:Server_RoundEnd,
    bool:Server_RoundStart,
    Server_RoundNumber,
    Server_RoundMode,
    Server_RoundCount,
    Handle:Server_RoundTimer,
    Handle:Server_GameConfig,
    String:Server_MapName[PLATFORM_MAX_PATH]
};

/**
 * Arrays to store the server's data.
 **/
int gServerData[ServerData];

/**
 * List of operation types for clients arrays.
 **/
enum ClientData
{
    /* Global */
    bool:Client_Zombie,
    bool:Client_Survivor,
    bool:Client_Nemesis,
    bool:Client_Skill,
    bool:Client_Loaded,
    bool:Client_AutoRebuy,
    Float:Client_SkillCountDown,
    Client_ZombieClass,
    Client_ZombieClassNext,
    Client_HumanClass,
    Client_HumanClassNext,
    Client_Respawn,
    Client_RespawnTimes,
    Client_AmmoPacks,
    Client_LastBoughtAmount,
    Client_Level,
    Client_Exp,
    Client_DataID,
    Client_AttachmentBits,
    Client_AttachmentAddons[9], 
    Client_AttachmentEntity,
    Client_AttachmentWeapon,
    String:Client_AttachmentLast[SMALL_LINE_LENGTH],
    
    /* Weapons */
    Client_ViewModels[2],
    Client_LastSequence,
    Client_CustomWeapon,
    Client_DrawSequence,
    Client_WeaponIndex,
    bool:Client_ToggleSequence,
    Client_LastSequenceParity,
    Client_SwapWeapon,
   
    /* Timers */
    Handle:Client_HUDTimer,
    Handle:Client_RespawnTimer,
    Handle:Client_ZombieSkillTimer,
    Handle:Client_ZombieCountDownTimer,
    Handle:Client_ZombieHealTimer,
    Handle:Client_ZombieMoanTimer
};

/**
 * Arrays to store the clients' data.
 **/
int gClientData[MAXPLAYERS+1][ClientData];

/**
 * Arrays to store the weapons's data.
 **/
int gWeaponData[MAXENTITIES+1] = {INVALID_ENT_REFERENCE,...};
