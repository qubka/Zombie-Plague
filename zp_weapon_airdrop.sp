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
    name            = "[ZP] ExtraItem: AirDrop",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel 
 
// Item index
int gWeapon;
#pragma unused gWeapon

// Timer index
Handle Task_EmitterCreate[MAXPLAYERS+1] = null; 

// Animation sequences
enum
{
    ANIM_IDLE,
    ANIM_SHOOT,
    ANIM_DRAW,
    ANIM_IDLE_TRIGGER_OFF,
    ANIM_IDLE_TRIGGER_ON,
    ANIM_SWITCH_TRIGGER_OFF,
    ANIM_SWITCH_TRIGGER_ON,
    ANIM_SHOOT_TRIGGER_OFF,
    ANIM_SHOOT_TRIGGER_ON,
    ANIM_DRAW_TRIGGER_OFF,
    ANIM_DRAW_TRIGGER_ON
};

// Weapon states
enum
{
    STATE_TRIGGER_OFF,
    STATE_TRIGGER_ON
};

/**
 * @section Properties of the bombardier.
 **/
#define BOMBARDING_HEIGHT               700.0
#define BOMBARDING_EXPLOSION_TIME       2.0
#define BOMBARDING_RADIUS               1500.0
#define BOMBARDING_SPEED                500.0
#define BOMBARDING_GRAVITY              0.01
/**
 * @endsection
 **/
 
/**
 * @section Properties of the airdrop.
 **/
#define AIRDROP_AMOUNT                  6
#define AIRDROP_HEIGHT                  700.0
#define AIRDROP_HEALTH                  300
#define AIRDROP_ELASTICITY              0.01
#define AIRDROP_SPEED                   175.0
#define AIRDROP_EXPLOSIONS              3
#define AIRDROP_WEAPONS                 15
#define AIRDROP_SMOKE_REMOVE            14.0
#define AIRDROP_SMOKE_TIME              17.0
#define AIRDROP_LOCK                    20.0
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
 * @section Types of drop.
 **/
enum 
{
    SAFE,
    EXPL,
    HEAVY,
    LIGHT,
    PISTOL,
    HPIST,
    TOOLS,
    HTOOL
};
/**
 * @endsection
 **/
 
/**
 * @brief Plugin is loading.
 **/
public void OnPluginStart(/*void*/)
{
    // Hooks entities output events
    HookEntityOutput("prop_physics_multiplayer", "OnPlayerUse", OnBagUse);

    // Load translations phrases used by plugin
    LoadTranslations("zombieplague.phrases");
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
        Task_EmitterCreate[i] = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
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
    delete Task_EmitterCreate[clientIndex];
}

/**
 * @brief Called when a entity used by a client.
 *
 * @param sOutput               The output char. 
 * @param entityIndex           The entity index.
 * @param activatorIndex        The activator index.
 * @param flDelay               The delay of updating.
 **/ 
public void OnBagUse(char[] sOutput, int entityIndex, int activatorIndex, float flDelay)
{
    // Is it bag ?
    if(ValidateName(entityIndex, "bag", 3))
    {
        // Call method
        BagUseHook(entityIndex);
    }
    // Is it safe ?
    else if(ValidateName(entityIndex, "safe", 4))
    {
        // Call method
        SafeUseHook(entityIndex);
    }
}

/**
 * @brief Called after a zombie core is loaded.
 **/
public void ZP_OnEngineExecute(/*void*/)
{
    // Weapons
    gWeapon = ZP_GetWeaponNameID("airdrop");
    if(gWeapon == -1) SetFailState("[ZP] Custom weapon ID from name : \"drone gun\" wasn't find");

    // Sounds
    gSound = ZP_GetSoundKeyID("HELICOPTER_SOUNDS");
    if(gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"HELICOPTER_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if(hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
    
    // Sounds
    PrecacheSound("survival/container_death_01.wav", true);
    PrecacheSound("survival/container_death_02.wav", true);
    PrecacheSound("survival/container_death_03.wav", true);
    PrecacheSound("survival/container_damage_01.wav", true);
    PrecacheSound("survival/container_damage_02.wav", true);
    PrecacheSound("survival/container_damage_03.wav", true);
    PrecacheSound("survival/container_damage_04.wav", true);
    PrecacheSound("survival/container_damage_05.wav", true);
    PrecacheSound("survival/missile_gas_01.wav", true);
    PrecacheSound("survival/dropzone_freefall.wav", true);
    PrecacheSound("survival/dropzone_parachute_deploy.wav", true);
    PrecacheSound("survival/dropzone_parachute_success.wav", true);
    PrecacheSound("survival/dropzone_parachute_success_02.wav", true);
    PrecacheSound("survival/dropbigguns.wav", true);
    PrecacheSound("survival/breach_activate_nobombs_01.wav", true);
    PrecacheSound("survival/breach_land_01.wav", true);
    PrecacheSound("survival/rocketincoming.wav", true);
    PrecacheSound("survival/rocketalarm.wav", true);
    PrecacheSound("survival/missile_land_01.wav", true);
    PrecacheSound("survival/missile_land_02.wav", true);
    PrecacheSound("survival/missile_land_03.wav", true);
    PrecacheSound("survival/missile_land_04.wav", true);
    PrecacheSound("survival/missile_land_05.wav", true);
    PrecacheSound("survival/missile_land_06.wav", true);

    // Models
    PrecacheModel("models/f18/f18.mdl", true);
    PrecacheModel("models/props_survival/safe/safe_door.mdl", true);
    PrecacheModel("models/props_survival/cash/dufflebag.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy.mdl", true);
    PrecacheModel("particle/particle_smokegrenade1.vmt", true); 
    PrecacheModel("particle/particle_smokegrenade2.vmt", true); 
    PrecacheModel("particle/particle_smokegrenade3.vmt", true); 
    PrecacheModel("models/gibs/metal_gib1.mdl", true);
    PrecacheModel("models/gibs/metal_gib2.mdl", true);
    PrecacheModel("models/gibs/metal_gib3.mdl", true);
    PrecacheModel("models/gibs/metal_gib4.mdl", true);
    PrecacheModel("models/gibs/metal_gib5.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib001.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib002.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib003.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib004.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib005.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib006.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib007.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib008.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib009.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib010.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib011.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib012.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib013.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib014.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib015.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib016.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib017.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib018.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib019.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib020.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib021.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib022.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib023.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib024.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib025.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib026.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib027.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib028.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib029.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib030.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib031.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib032.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib033.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib034.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib035.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib036.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib037.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib038.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib039.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib040.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib041.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon_gib042.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib001.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib002.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib003.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib004.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib005.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib006.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib007.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib008.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib009.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib010.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib011.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib012.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib013.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib014.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib015.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib016.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib017.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib018.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib019.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib020.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib021.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib022.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib023.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib024.mdl", true);
    PrecacheModel("models/props_survival/cases/case_explosive_gib025.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib001.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib002.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib003.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib004.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib005.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib006.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib007.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib008.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib009.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib010.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib011.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib012.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib013.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib014.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib015.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib016.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib017.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib018.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib019.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib020.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib021.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib022.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib023.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib024.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_gib025.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib001.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib002.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib003.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib004.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib005.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib006.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib007.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib008.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib009.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib010.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib011.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib012.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib013.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib014.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib015.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib016.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib017.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib018.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib019.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib020.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib021.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib022.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib023.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib024.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib025.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib026.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib027.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib028.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib029.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib030.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib031.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib032.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib033.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib034.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib035.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy_gib036.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib001.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib002.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib003.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib004.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib005.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib006.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib007.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib008.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib009.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib010.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib011.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib012.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib013.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib014.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib015.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib016.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib017.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib018.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib019.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib020.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib021.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib022.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib023.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib024.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib025.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib026.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib027.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib028.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib029.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib030.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib031.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib032.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib033.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib034.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib035.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy_gib036.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib001.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib002.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib003.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib004.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib005.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib006.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib007.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib008.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib009.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib010.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib011.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib012.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib013.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib014.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib015.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib016.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib017.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib018.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib019.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib020.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib021.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib022.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib023.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib024.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_gib025.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib001.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib002.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib003.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib004.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib005.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib006.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib007.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib008.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib009.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib010.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib011.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib012.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib013.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib014.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib015.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib016.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib017.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib018.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib019.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib020.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib021.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib022.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib023.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib024.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib025.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib026.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib027.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib028.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib029.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib030.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib031.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib032.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib033.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib034.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib035.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib036.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib037.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon_gib038.mdl", true);
}

/**
 * @brief Called after a zombie round is started.
 **/
public void ZP_OnGameModeStart(int modeIndex)
{
    // Validate access
    if(ZP_IsGameModeHumanClass(modeIndex, "human") && ZP_GetPlayingAmount() >= ZP_GetWeaponOnline(gWeapon))
    {
        // Get the random index of a human
        int clientIndex = 1;//ZP_GetRandomHuman();

        // Validate client
        if(clientIndex != INVALID_ENT_REFERENCE)
        {
            // Validate weapon
            static int weaponIndex;
            if((weaponIndex = ZP_IsPlayerHasWeapon(clientIndex, gWeapon)) != INVALID_ENT_REFERENCE)
            {
                // Reset variables
                SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_TRIGGER_OFF);
                SetEntProp(weaponIndex, Prop_Data, "m_iHealth", STATE_TRIGGER_OFF);
                SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
            }
            else
            {
                // Give item and select it
                ZP_GiveClientWeapon(clientIndex, gWeapon);

                // Show message
                SetGlobalTransTarget(clientIndex);
                PrintHintText(clientIndex, "%t", "airdrop info");
            }
        }
    }
}

//*********************************************************************
//*          Don't modify the code below this line unless             *
//*             you know _exactly_ what you are doing!!!              *
//*********************************************************************

void Weapon_OnHolster(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime

    // Cancel mode change
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
    
    // Delete timers
    delete Task_EmitterCreate[clientIndex];
}

void Weapon_OnIdle(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle") > flCurrentTime)
    {
        return;
    }
    
    // Sets the sequence index
    int iSequence = !bTrigger ? ANIM_IDLE : !iStateMode ? ANIM_IDLE_TRIGGER_OFF : ANIM_IDLE_TRIGGER_ON;
    
    // Sets idle animation
    ZP_SetWeaponAnimation(clientIndex, iSequence);
    
    // Sets next idle time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime + ZP_GetSequenceDuration(weaponIndex, iSequence));
}

void Weapon_OnDeploy(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime
    
    /// Block the real attack
    SetEntPropFloat(clientIndex, Prop_Send, "m_flNextAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextPrimaryAttack", flCurrentTime + 9999.9);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flNextSecondaryAttack", flCurrentTime + 9999.9);

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime + ZP_GetWeaponDeploy(gWeapon));
    
    // Sets draw animation
    ZP_SetWeaponAnimation(clientIndex, !bTrigger ? ANIM_DRAW : !iStateMode ? ANIM_DRAW_TRIGGER_OFF : ANIM_DRAW_TRIGGER_ON); 
}

void Weapon_OnPrimaryAttack(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime

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

    // Validate trigger 
    if(!bTrigger)
    {
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetWeaponSpeed(gWeapon);

        // Gets trace line
        GetClientEyePosition(clientIndex, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, filter2);

        // Is hit world ?
        if(TR_DidHit() && TR_GetEntityIndex() < 1)
        {
            // Sets attack animation
            ZP_SetWeaponAnimation(clientIndex, ANIM_SHOOT);  
            
            // Create timer for emitter
            delete Task_EmitterCreate[clientIndex]; /// Bugfix
            Task_EmitterCreate[clientIndex] = CreateTimer(ZP_GetWeaponSpeed(gWeapon) - 0.1, Weapon_OnCreateEmitter, GetClientUserId(clientIndex), TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else
    {
        // Adds the delay to the game tick
        flCurrentTime += ZP_GetWeaponReload(gWeapon);

        // Gets the controller
        int entityIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity"); 

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {    
            // Gets the position/angle
            GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
            GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAngle);

            // Create exp effect
            TE_SetupSparks(vPosition, NULL_VECTOR, 5000, 1000);
            TE_SendToAll();

            // Switch mode
            switch(iStateMode)
            {
                case STATE_TRIGGER_OFF : 
                {
                    // Create a smoke    
                    int smokeIndex = UTIL_CreateSmoke(_, vPosition, vAngle, _, _, _, _, _, _, _, _, _, "255 20 147", "255", "particle/particle_smokegrenade1.vmt", AIRDROP_SMOKE_REMOVE, AIRDROP_SMOKE_TIME);
                    
                    // Sent drop
                    CreateHelicopter(vPosition, vAngle);
                    
                    // Validate entity
                    if(smokeIndex != INVALID_ENT_REFERENCE)
                    {
                        // Emit sound
                        EmitSoundToAll("survival/missile_gas_01.wav", smokeIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
                    }
                }
                
                case STATE_TRIGGER_ON : 
                {
                    // Start bombarding
                    CreateJet(vPosition, vAngle);
                    
                    // Emit sound
                    EmitSoundToAll("survival/rocketalarm.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, hSoundLevel.IntValue)
                }
            }
            
            // Remove the entity from the world
            AcceptEntityInput(entityIndex, "Kill");
        }
        
        // Sets attack animation
        ZP_SetWeaponAnimation(clientIndex, !iStateMode ? ANIM_SHOOT_TRIGGER_OFF : ANIM_SHOOT_TRIGGER_ON);  
        
        // Remove trigger
        CreateTimer(0.99, Weapon_OnRemove, EntIndexToEntRef(weaponIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);   
    
    // Sets attack animation
    ZP_SetPlayerAnimation(clientIndex, AnimType_FirePrimary);
}

void Weapon_OnSecondaryAttack(int clientIndex, int weaponIndex, int bTrigger, int iStateMode, float flCurrentTime)
{
    #pragma unused clientIndex, weaponIndex, bTrigger, iStateMode, flCurrentTime

    // Validate trigger
    if(!bTrigger)
    {
        return;
    }
    
    // Validate animation delay
    if(GetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime") > flCurrentTime)
    {
        return;
    }

    // Seta the sequence index
    int iSequence = !iStateMode ? ANIM_SWITCH_TRIGGER_ON : ANIM_SWITCH_TRIGGER_OFF;

    // Sets change animation
    ZP_SetWeaponAnimation(clientIndex, iSequence);        

    // Adds the delay to the game tick
    flCurrentTime += ZP_GetSequenceDuration(weaponIndex, iSequence);

    // Sets next attack time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
    SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);   
    
    // Remove the delay to the game tick
    flCurrentTime -= 0.5;
    
    // Sets switching time
    SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", flCurrentTime);
    
    // Show message
    SetGlobalTransTarget(clientIndex);
    PrintHintText(clientIndex, "%t", !iStateMode ? "trigger on info" : "trigger off info");
}

/**
 * Timer for creating emitter.
 *
 * @param hTimer            The timer handle.
 * @param userID            The user id.
 **/
public Action Weapon_OnCreateEmitter(Handle hTimer, int userID)
{
    // Gets client index from the user ID
    int clientIndex = GetClientOfUserId(userID); static int weaponIndex;

    // Clear timer 
    Task_EmitterCreate[clientIndex] = null;

    // Validate client
    if(ZP_IsPlayerHoldWeapon(clientIndex, weaponIndex, gWeapon))
    {
         // Initialize vectors
        static float vPosition[3]; static float vEndPosition[3]; static float vAngle[3]; bool bHit;

        // Gets trace line
        GetClientEyePosition(clientIndex, vPosition);
        ZP_GetPlayerGunPosition(clientIndex, 80.0, 0.0, 0.0, vEndPosition);

        // Create the end-point trace
        TR_TraceRayFilter(vPosition, vEndPosition, MASK_SOLID, RayType_EndPoint, filter2);

        // Is hit world ?
        if(TR_DidHit() && TR_GetEntityIndex() < 1)
        {
            // Returns the collision position/angle of a trace result
            TR_GetEndPosition(vPosition);
            TR_GetPlaneNormal(null, vAngle); 
            
            // Gets the model
            static char sModel[PLATFORM_LINE_LENGTH];
            ZP_GetWeaponModelDrop(gWeapon, sModel, sizeof(sModel));
            
            // Create mine
            int entityIndex = UTIL_CreatePhysics("emitter", vPosition, vAngle, sModel, PHYS_FORCESERVERSIDE | PHYS_MOTIONDISABLED | PHYS_NOTAFFECTBYROTOR);
            
            // Validate entity
            if(entityIndex != INVALID_ENT_REFERENCE)
            {
                // Sets physics
                SetEntProp(entityIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
                SetEntProp(entityIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                
                // Sets owner to the entity
                SetEntPropEnt(entityIndex, Prop_Data, "m_pParent", clientIndex);
                SetEntPropEnt(weaponIndex, Prop_Send, "m_hEffectEntity", entityIndex);
                
                // Emit sound
                EmitSoundToAll("survival/breach_land_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
            }
            
            // Sets trigger mode
            SetEntProp(weaponIndex, Prop_Data, "m_iHealth", STATE_TRIGGER_ON);

            // Placed successfully
            bHit = true;
        }

        // Adds the delay to the game tick
        float flCurrentTime = GetGameTime() + ZP_GetWeaponDeploy(gWeapon);
        
        // Sets next attack time
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flTimeWeaponIdle", flCurrentTime);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_fLastShotTime", flCurrentTime);    

        // Sets pickup animation
        ZP_SetWeaponAnimation(clientIndex, bHit ? ANIM_DRAW_TRIGGER_OFF : ANIM_DRAW);
    }
    
    // Destroy timer
    return Plugin_Stop;
}

/**
 * Timer for removing trigger.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action Weapon_OnRemove(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int weaponIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(weaponIndex != INVALID_ENT_REFERENCE)
    {
        // Gets the active user
        int clientIndex = GetEntPropEnt(weaponIndex, Prop_Send, "m_hOwner");

        // Validate client
        if(IsPlayerExist(clientIndex, false))
        {
            // Forces a player to remove weapon
            ZP_RemoveWeapon(clientIndex, weaponIndex);
        }
        else
        {
            AcceptEntityInput(weaponIndex, "Kill");
        }
    }
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
                        \
        GetEntProp(%2, Prop_Data, "m_iHealth"), \
                        \
        GetEntProp(%2, Prop_Data, "m_iMaxHealth"), \
                        \
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
        SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", STATE_TRIGGER_OFF);
        SetEntProp(weaponIndex, Prop_Data, "m_iHealth", STATE_TRIGGER_OFF);
        SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);
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
        // Call event
        _call.Holster(clientIndex, weaponIndex);
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
        // Time to apply new mode
        static float flApplyModeTime;
        if((flApplyModeTime = GetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer")) && flApplyModeTime <= GetGameTime())
        {
            // Sets the switching time
            SetEntPropFloat(weaponIndex, Prop_Send, "m_flDoneSwitchingSilencer", 0.0);

            // Sets different mode
            SetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth", !GetEntProp(weaponIndex, Prop_Data, "m_iMaxHealth"));
            
            // Emit sound
            EmitSoundToAll("survival/breach_activate_nobombs_01.wav", clientIndex, SNDCHAN_WEAPON, hSoundLevel.IntValue);
        }
    
        // Button primary attack press
        if(iButtons & IN_ATTACK)
        {
            // Call event
            _call.PrimaryAttack(clientIndex, weaponIndex); 
            iButtons &= (~IN_ATTACK);
            return Plugin_Changed;
        }
        // Button secondary attack press
        else if(iButtons & IN_ATTACK2)
        {
            // Call event
            _call.SecondaryAttack(clientIndex, weaponIndex);
            iButtons &= (~IN_ATTACK2);
            return Plugin_Changed;
        }
        
        // Call event
        _call.Idle(clientIndex, weaponIndex);
    }

    // Allow button
    return Plugin_Continue;
}

//**********************************************
//* Jet functions.                             *
//**********************************************

/**
 * @brief Create a jet entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.    
 **/
void CreateJet(float vPosition[3], float vAngle[3])
{
    // Add to the position
    vPosition[2] += BOMBARDING_HEIGHT;

    // Gets the world size
    static float vMaxs[3];
    GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
    
    // Validate world size
    float vMax = vMaxs[2] - 100.0;
    if(vPosition[2] > vMax) vPosition[2] = vMax; 
    
    // Randomize animation
    //static char sAnim[SMALL_LINE_LENGTH];
    //FormatEx(sAnim, sizeof(sAnim), "flyby%i", GetRandomInt(1, 5));

    // Create a model entity
    int entityIndex = UTIL_CreateDynamic("f18", vPosition, vAngle, "models/f18/f18.mdl", "flyby1", false);
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Create thinks
        CreateTimer(2.7, JetBombHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);

        // Kill entity after delay
        UTIL_RemoveEntity(entityIndex, 6.6);
    }
}

/**
 * @brief Main timer for spawn bombs.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action JetBombHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Emit sound
        EmitSoundToAll("survival/rocketincoming.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);

        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];

        // Gets the position/angle
        ZP_GetAttachment(entityIndex, "sound_maker", vPosition, vAngle); vAngle[0] += 180.0;
        
        // Create a bomb entity
        entityIndex = UTIL_CreateProjectile(vPosition, vAngle, "models/player/custom_player/zombie/bomb/bomb.mdl");

        // Validate entity
        if(entityIndex != INVALID_ENT_REFERENCE)
        {
            // Correct angle
            vAngle[0] -= 90.0;//45.0;
    
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);

            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vVelocity, vVelocity);

            // Apply the magnitude by scaling the vector
            ScaleVector(vVelocity, BOMBARDING_SPEED);
    
            // Push the bomb
            TeleportEntity(entityIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);
            
             // Sets physics
            SetEntPropFloat(entityIndex, Prop_Data, "m_flGravity", BOMBARDING_GRAVITY);

            // Create touch hook
            SDKHook(entityIndex, SDKHook_Touch, BombTouchHook);
        }
    }
}

/**
 * @brief Bomb touch hook.
 * 
 * @param entityIndex           The entity index.        
 * @param targetIndex           The target index.               
 **/
public Action BombTouchHook(int entityIndex, int targetIndex)
{
    // Gets entity position
    static float vPosition[3];
    GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);

    // Create an explosion effect
    UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500", BOMBARDING_EXPLOSION_TIME);
    UTIL_CreateParticle(_, vPosition, _, _, "explosion_c4_500_fallback", BOMBARDING_EXPLOSION_TIME);
    
    // Find any players in the radius
    int i; int it = 1; /// iterator
    while((i = ZP_FindPlayerInSphere(it, vPosition, BOMBARDING_RADIUS)) != INVALID_ENT_REFERENCE)
    {
        // Skip humans
        if(ZP_IsPlayerHuman(i))
        {
            continue;
        }
        
        // Forces a player to commit suicide
        ForcePlayerSuicide(i);
    }
    
    // Emit sound
    switch(GetRandomInt(0, 5))
    {
        case 0 : EmitSoundToAll("survival/missile_land_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 1 : EmitSoundToAll("survival/missile_land_02.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 2 : EmitSoundToAll("survival/missile_land_03.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 3 : EmitSoundToAll("survival/missile_land_04.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 4 : EmitSoundToAll("survival/missile_land_05.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 5 : EmitSoundToAll("survival/missile_land_06.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }

    // Remove the entity from the world
    AcceptEntityInput(entityIndex, "Kill");
}

//**********************************************
//* Helicopter functions.                      *
//**********************************************

/**
 * @brief Create a helicopter entity.
 * 
 * @param vPosition         The position to the spawn.
 * @param vAngle            The angle to the spawn.                    
 **/
void CreateHelicopter(float vPosition[3], float vAngle[3])
{
    // Add to the position
    vPosition[2] += AIRDROP_HEIGHT;
    
    // Gets the world size
    static float vMaxs[3];
    GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
    
    // Validate world size
    float vMax = vMaxs[2] - 100.0;
    if(vPosition[2] > vMax) vPosition[2] = vMax; 
    
    // Create a model entity
    int entityIndex = UTIL_CreateDynamic("helicopter", vPosition, vAngle, "models/buildables/helicopter_rescue_v3.mdl", "helicopter_coop_hostagepickup_flyin");
    
    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Create thinks
        CreateTimer(20.0, HelicopterStopHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
        CreateTimer(0.41, HelicopterSoundHook, EntIndexToEntRef(entityIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
        // Sets main parameters
        SetEntProp(entityIndex, Prop_Data, "m_iHammerID", SAFE);
        SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", AIRDROP_AMOUNT);
    }
}

/**
 * @brief Main timer for stop helicopter.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterStopHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Set idle
        SetAnimation(entityIndex, "helicopter_coop_hostagepickup_idle");

        // Sets idle
        CreateTimer(5.0, HelicopterIdleHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Main timer for creating sound. (Helicopter)
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterSoundHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3];

        // Gets the position/angle
        ZP_GetAttachment(entityIndex, "dropped", vPosition, vAngle); 

        // Play sound
        ZP_EmitAmbientSound(gSound, 1, vPosition, SOUND_FROM_WORLD, hSoundLevel.IntValue); 
    }
    else
    {
        // Destroy timer
        return Plugin_Stop;
    }
    
    // Allow timer
    return Plugin_Continue;
}

/**
 * @brief Main timer for idling helicopter.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterIdleHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Set idle
        SetAnimation(entityIndex, "helicopter_coop_towerhover_idle");

        // Emit sound
        EmitSoundToAll("survival/dropbigguns.wav", SOUND_FROM_PLAYER, SNDCHAN_VOICE, hSoundLevel.IntValue);
        
        // Drops additional random staff
        CreateTimer(1.0, HelicopterDropHook, EntIndexToEntRef(entityIndex), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
        
        // Sets flying
        CreateTimer(6.6, HelicopterRemoveHook, EntIndexToEntRef(entityIndex), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * @brief Main timer for creating drop.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterDropHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Validate cases
        int iLeft = GetEntProp(entityIndex, Prop_Data, "m_iMaxHealth");
        if(iLeft)
        {
            // Reduce amount
            iLeft--;
            
            // Sets new amount
            SetEntProp(entityIndex, Prop_Data, "m_iMaxHealth", iLeft);
        }
        else
        {
            // Destroy timer
            return Plugin_Stop;
        }

        // Initialize vectors
        static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];
        
        // Gets the position/angle
        ZP_GetAttachment(entityIndex, "dropped", vPosition, vAngle);
        
        // Gets the drop type
        int iType = GetEntProp(entityIndex, Prop_Data, "m_iHammerID"); int dropIndex; int iCollision; int iDamage;
        switch(iType)
        {
            case SAFE :
            {
                // Create safe
                dropIndex = UTIL_CreatePhysics("safe", vPosition, NULL_VECTOR, "models/buildables/safe.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR | PHYS_GENERATEUSE);
                
                // Validate entity
                if(dropIndex != INVALID_ENT_REFERENCE)
                {
                    // Sets physics
                    iCollision = COLLISION_GROUP_PLAYER;
                    iDamage = DAMAGE_EVENTS_ONLY;

                    // Create damage hook
                    SDKHook(dropIndex, SDKHook_OnTakeDamage, SafeDamageHook);
                }
                
                // i = client index
                for(int i = 1; i <= MaxClients; i++)
                {
                    // Validate human
                    if(IsPlayerExist(i) && ZP_IsPlayerHuman(i))
                    {
                        // Show message
                        SetGlobalTransTarget(i);
                        PrintHintText(i, "%t", "airdrop safe", AIRDROP_EXPLOSIONS);
                    }
                }
            }
            
            default :
            {
                // Create case
                switch(iType)
                {
                    case EXPL   : dropIndex = UTIL_CreatePhysics("explos", vPosition, NULL_VECTOR, "models/props_survival/cases/case_explosive.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
                    case HEAVY  : dropIndex = UTIL_CreatePhysics("heavys", vPosition, NULL_VECTOR, "models/props_survival/cases/case_heavy_weapon.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
                    case LIGHT  : dropIndex = UTIL_CreatePhysics("lighst", vPosition, NULL_VECTOR, "models/props_survival/cases/case_light_weapon.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
                    case PISTOL : dropIndex = UTIL_CreatePhysics("pislol", vPosition, NULL_VECTOR, "models/props_survival/cases/case_pistol.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
                    case HPIST  : dropIndex = UTIL_CreatePhysics("pishev", vPosition, NULL_VECTOR, "models/props_survival/cases/case_pistol_heavy.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
                    case TOOLS  : dropIndex = UTIL_CreatePhysics("toolsl", vPosition, NULL_VECTOR, "models/props_survival/cases/case_tools.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
                    case HTOOL  : dropIndex = UTIL_CreatePhysics("toohev", vPosition, NULL_VECTOR, "models/props_survival/cases/case_tools_heavy.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
                }

                // Validate entity
                if(dropIndex != INVALID_ENT_REFERENCE)
                {
                    // Sets physics
                    iCollision = COLLISION_GROUP_WEAPON;
                    iDamage = DAMAGE_YES;

                    // Create damage hook
                    SDKHook(dropIndex, SDKHook_OnTakeDamage, CaseDamageHook);
                }
                
                // Randomize yaw a bit 
                vAngle[0] = GetRandomFloat(-45.0, 45.0);
            }
        }

        // Randomize the drop types (except safe)
        SetEntProp(entityIndex, Prop_Data, "m_iHammerID", GetRandomInt(EXPL, HTOOL));
        
        // Validate entity
        if(dropIndex != INVALID_ENT_REFERENCE)
        {
            // Returns vectors in the direction of an angle
            GetAngleVectors(vAngle, vVelocity, NULL_VECTOR, NULL_VECTOR);
            
            // Normalize the vector (equal magnitude at varying distances)
            NormalizeVector(vVelocity, vVelocity);
            
            // Apply the magnitude by scaling the vector
            ScaleVector(vVelocity, AIRDROP_SPEED);
        
            // Push the entity 
            TeleportEntity(dropIndex, NULL_VECTOR, NULL_VECTOR, vVelocity);
            
            // Sets physics
            SetEntProp(dropIndex, Prop_Send, "m_CollisionGroup", iCollision);
            SetEntProp(dropIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
            SetEntPropFloat(dropIndex, Prop_Send, "m_flElasticity", AIRDROP_ELASTICITY);
            
            // Sets health
            SetEntProp(dropIndex, Prop_Data, "m_takedamage", iDamage);
            SetEntProp(dropIndex, Prop_Data, "m_iHealth", AIRDROP_HEALTH);
            SetEntProp(dropIndex, Prop_Data, "m_iMaxHealth", AIRDROP_HEALTH);
            
            // Sets type
            SetEntProp(dropIndex, Prop_Data, "m_iHammerID", iType);
        }
    }
    else
    {
        // Destroy timer
        return Plugin_Stop;
    }
    
    // Allow timer
    return Plugin_Continue;
}

/**
 * @brief Main timer for remove helicopter.
 *
 * @param hTimer            The timer handle.
 * @param referenceIndex    The reference index.
 **/
public Action HelicopterRemoveHook(Handle hTimer, int referenceIndex)
{
    // Gets entity index from reference key
    int entityIndex = EntRefToEntIndex(referenceIndex);

    // Validate entity
    if(entityIndex != INVALID_ENT_REFERENCE)
    {
        // Set idle
        SetAnimation(entityIndex, "helicopter_coop_towerhover_flyaway");

        // Kill entity after delay
        UTIL_RemoveEntity(entityIndex, 8.3);
    }
}

/**
 * @brief Called when a safe used by the player.
 *
 * @param entityIndex       The entity index.
 **/ 
void SafeUseHook(int entityIndex)
{
    // If safe open, then kill
    if(GetEntProp(entityIndex, Prop_Send, "m_nBody"))
    {
        // Call death
        SafeExpload(entityIndex);
    }
}

/**
 * @brief Safe damage hook.
 *
 * @param entityIndex       The entity index.    
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action SafeDamageHook(int entityIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits)
{
    // Emit sound
    switch(GetRandomInt(0, 4))
    {
        case 0 : EmitSoundToAll("survival/container_damage_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 1 : EmitSoundToAll("survival/container_damage_02.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 2 : EmitSoundToAll("survival/container_damage_03.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 3 : EmitSoundToAll("survival/container_damage_04.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 4 : EmitSoundToAll("survival/container_damage_05.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }
    
    // Validate mode
    if(GetEntProp(entityIndex, Prop_Send, "m_nBody"))
    {
        // Calculate the damage
        int iHealth = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

        // Destroy entity
        if(!iHealth)
        {   
            // Call death
            SafeExpload(entityIndex);
        }
        else
        {
            // Apply damage
            SetEntProp(entityIndex, Prop_Data, "m_iHealth", iHealth);
        }
    }
    else
    {
        // Entity was damaged by 'explosion'
        if(iBits & DMG_BLAST)
        {
            // Validate inflicter
            if(IsValidEdict(inflictorIndex))
            {
                // Gets weapon classname
                static char sClassname[SMALL_LINE_LENGTH];
                GetEdictClassname(inflictorIndex, sClassname, sizeof(sClassname));
            
                // Initialize vectors
                static float vPosition[3]; static float vAngle[3];
            
                // Gets the position
                ZP_GetAttachment(entityIndex, "door", vPosition, vAngle);
                GetEntPropVector(inflictorIndex, Prop_Data, "m_vecAbsOrigin", vAngle);
            
                // Validate c4 projectile
                if(!strncmp(sClassname, "brea", 4, false) && GetVectorDistance(vPosition, vAngle) <= AIRDROP_LOCK)
                {
                    // Increment explosions
                    int iExp = GetEntProp(entityIndex, Prop_Data, "m_iHammerID") + 1;
                    SetEntProp(entityIndex, Prop_Data, "m_iHammerID", iExp);
            
                    // Validate explosions
                    if(iExp >= AIRDROP_EXPLOSIONS)
                    {
                        // Gets the position/angle
                        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
                        GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAngle);
                        
                        // Create bag
                        int bagIndex = UTIL_CreatePhysics("bag", vPosition, vAngle, "models/props_survival/cash/dufflebag.mdl", PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR | PHYS_GENERATEUSE);
                        
                        // Validate entity
                        if(bagIndex != INVALID_ENT_REFERENCE)
                        {
                            // Sets physics
                            SetEntProp(bagIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
                            SetEntProp(bagIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);

                            // Sets health
                            SetEntProp(bagIndex, Prop_Data, "m_takedamage", DAMAGE_NO);
                            
                            // Sets weapon amount
                            SetEntProp(bagIndex, Prop_Data, "m_iHammerID", AIRDROP_WEAPONS);
                        }

                        // Gets the position/angle
                        ZP_GetAttachment(entityIndex, "door", vPosition, vAngle);
                        
                        // Open door
                        SetEntProp(entityIndex, Prop_Send, "m_nBody", 1);
                        
                        // Create door
                        int doorIndex = UTIL_CreatePhysics("door", vPosition, vAngle, "models/props_survival/safe/safe_door.mdl", PHYS_FORCESERVERSIDE);
                        
                        // Validate entity
                        if(doorIndex != INVALID_ENT_REFERENCE)
                        {
                            // Sets physics
                            SetEntProp(doorIndex, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
                            SetEntProp(doorIndex, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
                        }
                        
                        // i = client index
                        for(int i = 1; i <= MaxClients; i++)
                        {
                            // Validate human
                            if(IsPlayerExist(i) && ZP_IsPlayerHuman(i))
                            {
                                // Show message
                                SetGlobalTransTarget(i);
                                PrintHintTextToAll("%t", "airdrop bag");
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Return on success
    return Plugin_Handled;
}

/**
 * @brief Exploade safe.
 * 
 * @param entityIndex       The entity index.                    
 **/
void SafeExpload(int entityIndex)
{
    // Destroy damage hook
    SDKUnhook(entityIndex, SDKHook_OnTakeDamage, SafeDamageHook);

    // Initialize vectors
    static float vGibAngle[3]; float vShootAngle[3];
    
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
        UTIL_CreateShooter(entityIndex, "forward", _, MAT_METAL, sBuffer, vShootAngle, vGibAngle, METAL_GIBS_AMOUNT, METAL_GIBS_DELAY, METAL_GIBS_SPEED, METAL_GIBS_VARIENCE, METAL_GIBS_LIFE, METAL_GIBS_DURATION);
    }
    
    // Emit sound
    switch(GetRandomInt(0, 2))
    {
        case 0 : EmitSoundToAll("survival/container_death_01.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 1 : EmitSoundToAll("survival/container_death_02.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
        case 2 : EmitSoundToAll("survival/container_death_03.wav", entityIndex, SNDCHAN_STATIC, hSoundLevel.IntValue);
    }

    // Kill after some duration
    UTIL_RemoveEntity(entityIndex, 0.1);
}

/**
 * @brief Called when a bag used by the player.
 *
 * @param entityIndex       The entity index.
 **/ 
void BagUseHook(int entityIndex)
{
    // Initialize vectors
    static float vPosition[3]; static float vAngle[3]; static float vVelocity[3];
                    
    // Gets entity position
    GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
    GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAngle);
    
    // Randomize a bit
    vPosition[2] += 10.0;
    vVelocity[0] = GetRandomFloat(-360.0, 360.0);
    vVelocity[1] = GetRandomFloat(-360.0, 360.0);
    vVelocity[2] = 10.0 + GetRandomFloat(0.0, 10.0);

    // Create random weapon
    SpawnRandomWeapon(vPosition, vAngle, vVelocity);
    
    // Validate weapons
    int iLeft = GetEntProp(entityIndex, Prop_Data, "m_iHammerID");
    if(iLeft)
    {
        // Reduce amount
        iLeft--;

        // Sets new amount
        SetEntProp(entityIndex, Prop_Data, "m_iHammerID", iLeft);

        // Sets filling status
        SetEntProp(entityIndex, Prop_Send, "m_nBody", LeftToBody(iLeft));
    }
    else
    {
        // Destroy!
        AcceptEntityInput(entityIndex, "Kill");
    }
}

/**
 * @brief Case damage hook.
 *
 * @param entityIndex       The entity index.    
 * @param attackerIndex     The attacker index.
 * @param inflictorIndex    The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action CaseDamageHook(int entityIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits)
{
    // Calculate the damage
    int iHealth = GetEntProp(entityIndex, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

    // Validate death
    int iType = GetEntProp(entityIndex, Prop_Data, "m_iHammerID");
    if(!iHealth && iType != -1) /// Avoid double spawn
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3];
                        
        // Gets entity position
        GetEntPropVector(entityIndex, Prop_Data, "m_vecAbsOrigin", vPosition);
        GetEntPropVector(entityIndex, Prop_Data, "m_angAbsRotation", vAngle);
    
        // Switch case type
        MenuType mSlot;
        switch(iType)
        {
            case EXPL   : mSlot = MenuType_Shotguns;
            case HEAVY  : mSlot = MenuType_Machineguns;
            case LIGHT  : mSlot = MenuType_Rifles;
            case PISTOL : mSlot = MenuType_Pistols;
            case HPIST  : mSlot = MenuType_Snipers;
            case TOOLS  : mSlot = MenuType_Knifes;
            case HTOOL  : mSlot = MenuType_Invisible;
        }
        
        // Create random weapon
        SpawnRandomWeapon(vPosition, vAngle, NULL_VECTOR, mSlot);
        
        // Block it
        SetEntProp(entityIndex, Prop_Data, "m_iHammerID", -1);
    }
}

//**********************************************
//* Item (npc) stocks.                         *
//**********************************************

/**
 * @brief Play the animation of the entity.
 * 
 * @param entityIndex       The entity index.        
 * @param sAnim             The animation name.     
 * @param iBodyGroup        (Optional) The bodygroup index.
 **/
stock void SetAnimation(int entityIndex, char[] sAnim, int iBodyGroup = 0)
{
    // Sets bodygroup of the model
    SetVariantInt(iBodyGroup);
    AcceptEntityInput(entityIndex, "SetBodyGroup");
    
    // Play animation of the model
    SetVariantString(sAnim);
    AcceptEntityInput(entityIndex, "SetAnimation");
}

/**
 * @brief Transform filling amount to body index.
 * 
 * @param iLeft             The amount which left.        
 * @return                  The skin index.
 **/
stock int LeftToBody(int iLeft)
{
    // Calculate left percentage
    float flLeft = float(iLeft) / AIRDROP_WEAPONS;
    if(flLeft > 0.8)      return 0;    
    else if(flLeft > 0.6) return 1;
    else if(flLeft > 0.4) return 2;
    else if(flLeft > 0.2) return 3;
    return 4;   
}

/**
 * @brief Spawn the random weapon.
 *       
 * @param vPosition         The origin of the spawn.
 * @param vAngle            The angle of the spawn.
 * @param vVelocity         The velocity of the spawn.
 * @param mSlot             (Optional) The slot index selected.
 **/
stock void SpawnRandomWeapon(float vPosition[3], float vAngle[3], float vVelocity[3], MenuType mSlot = MenuType_Invisible)
{
    // Valdiate random weapon id
    int iD = FindRandomWeapon(mSlot);
    if(iD != -1)
    {
        // Gets classname
        static char sClassname[PLATFORM_LINE_LENGTH];
        ZP_GetWeaponEntity(iD, sClassname, sizeof(sClassname));
        
        // Create a random weapon entity
        int weaponIndex = CreateEntityByName(sClassname);
        
        // Validate entity
        if(weaponIndex != INVALID_ENT_REFERENCE)
        {
            // Spawn the entity into the world
            DispatchSpawn(weaponIndex);
            
            // Push the entity
            TeleportEntity(weaponIndex, vPosition, vAngle, vVelocity);

            // Sets the model
            ZP_GetWeaponModelDrop(iD, sClassname, sizeof(sClassname));
            if(hasLength(sClassname)) SetEntityModel(weaponIndex, sClassname);
            
            // Sets the custom weapon id
            SetEntProp(weaponIndex, Prop_Data, "m_iHammerID", iD);
        }
    }
}

/**
 * @brief Find the random id of any custom weapons.
 *       
 * @param mSlot             (Optional) The slot index selected.
 * @return                  The weapon id.
 **/
stock int FindRandomWeapon(MenuType mSlot = MenuType_Invisible) 
{
    // Initialize name char
    static char sClassname[SMALL_LINE_LENGTH];
    
    // Gets total amount of weapons
    int iSize = ZP_GetNumberWeapon();
    
    // Dynamicly allocate array
    int[] weaponID = new int[iSize]; int x;
    
    // Validate all types
    if(mSlot == MenuType_Invisible)
    {
        // i = weapon id 
        for(int i = 0; i < iSize; i++)
        {
            // Validate class/drop/slot
            ZP_GetWeaponClass(i, sClassname, sizeof(sClassname));
            if(StrContains(sClassname, "human", false) == -1 || !ZP_IsWeaponDrop(i) || ZP_GetWeaponSlot(i) == MenuType_Knifes)
            {
                continue;
            }

            // Validate classname
            ZP_GetWeaponEntity(i, sClassname, sizeof(sClassname));
            if(!strncmp(sClassname, "item_", 5, false))
            {
                continue;
            }
            
            // Append to list
            weaponID[x++] = i;
        }
    }
    else
    {
        // i = weapon id 
        for(int i = 0; i < iSize; i++)
        {
            // Validate class/drop/slot
            ZP_GetWeaponClass(i, sClassname, sizeof(sClassname));
            if(StrContains(sClassname, "human", false) == -1 || !ZP_IsWeaponDrop(i) || ZP_GetWeaponSlot(i) != mSlot)
            {
                continue;
            }

            // Validate classname
            ZP_GetWeaponEntity(i, sClassname, sizeof(sClassname));
            if(!strncmp(sClassname, "item_", 5, false))
            {
                continue;
            }
            
            // Append to list
            weaponID[x++] = i;
        }
    }
    
    // Return on success
    return (x) ? weaponID[GetRandomInt(0, x-1)] : -1;
}

/**
 * @brief Validate the entity's classname.
 *
 * @param entityIndex       The entity index.
 * @param sClassname        The classname string.
 * @param iMaxLen           The lenght of checking.
 *
 * @return                  True or false.
 **/
stock bool ValidateName(int entityIndex, char[] sClassname, int iMaxLen)
{
    static char sName[SMALL_LINE_LENGTH];
    GetEntPropString(entityIndex, Prop_Data, "m_iName", sName, sizeof(sName));
    
    // Validate string
    return (!strncmp(sName, sClassname, iMaxLen, false));
}