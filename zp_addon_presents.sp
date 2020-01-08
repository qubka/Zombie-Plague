/**
 * ============================================================================
 *
 *  Zombie Plague
 *
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

#include <sourcemod>
#include <sdktools>
#include <zombieplague>

#pragma newdecls required
#pragma semicolon 1

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Addon: Presents",
    author          = "qubka (Nikita Ushakov) | Pelipoika",     
    description     = "Addon of cso presents",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @section Properties of the airdrop.
 **/
//#define PRESENT_GLOW              /// Uncomment to disable glow
#define PRESENT_MAX_AMOUNT          6
#define PRESENT_HEALTH              300
#define PRESENT_ELASTICITY          0.01
#define PRESENT_DELAY               60.0
/**
 * @endsection
 **/
 
// Timer index
Handle hPresentSpawn = null; ArrayList hPosition; bool bLoad; int gCaseCount;

// Sound index
int gSound; ConVar hSoundLevel;
#pragma unused gSound, hSoundLevel  

/**
 * @section Types of drop.
 **/
enum 
{
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
 * @brief Called after a library is added that the current plugin references optionally. 
 *        A library is either a plugin name or extension name, as exposed via its include file.
 **/
public void OnLibraryAdded(const char[] sLibrary)
{
    // Validate library
    if (!strcmp(sLibrary, "zombieplague", false))
    {
        // Initialize a position array
        hPosition = new ArrayList(3);
        
        // Load translations phrases used by plugin
        LoadTranslations("zombieplague.phrases");
        
        // Hook server events
        HookEvent("round_prestart", RoundStateHook, EventHookMode_Pre);
        HookEvent("round_end", RoundStateHook, EventHookMode_Pre);
        
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
    // Sounds
    gSound = ZP_GetSoundKeyID("PRESENT_SOUNDS");
    if (gSound == -1) SetFailState("[ZP] Custom sound key ID from name : \"PRESENT_SOUNDS\" wasn't find");
    
    // Cvars
    hSoundLevel = FindConVar("zp_seffects_level");
    if (hSoundLevel == null) SetFailState("[ZP] Custom cvar key ID from name : \"zp_seffects_level\" wasn't find");
}

/**
 * @brief The map is loading.
 **/
public void OnMapStart(/*void*/)
{
    // Loads a game config file
    Handle hConfig = LoadGameConfigFile("plugin.presents");

    // Load other addresses
    Address TheNavAreas = GameConfGetAddress(hConfig, "TheNavAreas");

    // Validate address
    if (TheNavAreas == Address_Null) SetFailState("Failed to load SDK address \"TheNavAreas\". Update address in \"plugin.presents\"");    

    // Validate count
    int TheNavAreas_Count = view_as<int>(GameConfGetAddress(hConfig, "TheNavAreas::Count"));
    if (TheNavAreas_Count <= 0)
    {
        // Log info
        PrintToServer("[ZP] Addon: Presents = unloaded on the current map. Generate \"nav_mesh\" to make it work!");
        
        // Sets on unsucess
        bLoad = false;
        
        // Close file
        delete hConfig;
        return;
    }

    // Close file
    delete hConfig;
    
    // Clear out the array of all data
    hPosition.Clear();
    
    // Gets a random positions
    for (int i = 0; i < TheNavAreas_Count; ++i)
    {
        // Valiate area
        Address pNavArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(i * 4), NumberType_Int32));
        if (pNavArea != Address_Null)
        {
            // Initialize vectors
            static float nwCorner[3]; static float seCorner[3]; static float vCenter[3];
    
            // Gets north-west corner point
            nwCorner[0] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(4), NumberType_Int32));
            nwCorner[1] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(8), NumberType_Int32));
            nwCorner[2] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(12), NumberType_Int32));

            // Gets south-east corner point
            seCorner[0] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(16), NumberType_Int32));
            seCorner[1] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(20), NumberType_Int32));
            seCorner[2] = view_as<float>(LoadFromAddress(pNavArea + view_as<Address>(24), NumberType_Int32));
            
            // Check that the area is bigger than 50 units wide on both sides
            if ((seCorner[0] - nwCorner[0]) <= 50.0 || (seCorner[1] - nwCorner[1]) <= 50.0)
            {
                continue;
            }

            // Calculate area center position
            AddVectors(nwCorner, seCorner, vCenter);
            ScaleVector(vCenter, 0.5);

            // Push data into array 
            hPosition.PushArray(vCenter, sizeof(vCenter));
        }
    }
    
    // Validate lenght
    int iSize = hPosition.Length;
    if (!iSize)
    {
        bLoad = false;
        return;
    }
    
    // Nav mesh load successfully
    bLoad = true;

    // Sounds
    PrecacheSound("survival/container_death_01.wav", true);
    PrecacheSound("survival/container_death_02.wav", true);
    PrecacheSound("survival/container_death_03.wav", true);
    PrecacheSound("survival/container_damage_01.wav", true);
    PrecacheSound("survival/container_damage_02.wav", true);
    PrecacheSound("survival/container_damage_03.wav", true);
    PrecacheSound("survival/container_damage_04.wav", true);
    PrecacheSound("survival/container_damage_05.wav", true);
    
    // Models
    PrecacheModel("models/props_survival/cases/case_explosive.mdl", true);
    PrecacheModel("models/props_survival/cases/case_heavy_weapon.mdl", true);
    PrecacheModel("models/props_survival/cases/case_light_weapon.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol.mdl", true);
    PrecacheModel("models/props_survival/cases/case_pistol_heavy.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools.mdl", true);
    PrecacheModel("models/props_survival/cases/case_tools_heavy.mdl", true);
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
 * @brief The map is ending.
 **/
public void OnMapEnd(/*void*/)
{
    // Purge timer
    hPresentSpawn = null; /// with flag TIMER_FLAG_NO_MAPCHANGE
}

/**
 * @brief Called after a zombie round is started.
 **/
public void ZP_OnGameModeStart(int mode)
{
    // Is nav mesh loaded ?
    if (!bLoad)
    {
        return;
    }
    
    // Validate access
    if (ZP_IsGameModeHumanClass(mode, "human"))
    {
        // Create spawing hook
        delete hPresentSpawn;
        hPresentSpawn = CreateTimer(PRESENT_DELAY, CaseSpawnHook, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    }
}

/**
 * Event callback (round_prestart, round_end)
 * @brief The round is starting/ending.
 * 
 * @param gEventHook        The event handle.
 * @param gEventName        The name of the event.
 * @param dontBroadcast     If true, event is broadcasted to all clients, false if not.
 **/
public Action RoundStateHook(Event hEvent, char[] sName, bool dontBroadcast) 
{
    // Resets amount
    gCaseCount = 0;
    
    // Remove timer
    delete hPresentSpawn;
}

/**
 * @brief Timer for spawing presents.
 *
 * @param hTimer            The timer handle.
 **/
public Action CaseSpawnHook(Handle hTimer)
{
    // Validate amount
    int iAmount = PRESENT_MAX_AMOUNT - gCaseCount;
    if (!iAmount)
    {
        // Allow timer
        return Plugin_Continue;
    }
    
    // i = case index
    for (int i = 0; i < iAmount; i++)
    {
        // Gets random position
        static float vPosition[3];
        if (!FindRandomPosition(vPosition))
        {
            // Increment amount
            iAmount++;
            continue;
        }

        // Gets model path
        static char sModel[PLATFORM_LINE_LENGTH]; int iType = GetRandomInt(EXPL, HTOOL); static int vColor[4];
        switch (iType)
        {
            case EXPL : 
            { 
                strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_explosive.mdl");    
                vColor = {255, 127, 80, 255};  
            }
            case HEAVY : 
            { 
                strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_heavy_weapon.mdl"); 
                vColor = {220, 20, 60, 255};   
            } 
            case LIGHT : 
            { 
                strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_light_weapon.mdl"); 
                vColor = {255, 0, 0, 255};     
            } 
            case PISTOL : 
            { 
                strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_pistol.mdl");       
                vColor = {240, 128, 128, 255}; 
            } 
            case HPIST : 
            { 
                strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_pistol_heavy.mdl"); 
                vColor = {219, 112, 147, 255}; 
            } 
            case TOOLS : 
            { 
                strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_tools.mdl");        
                vColor = {0, 0, 205, 255};     
            } 
            case HTOOL : 
            { 
                strcopy(sModel, sizeof(sModel), "models/props_survival/cases/case_tools_heavy.mdl");  
                vColor = {95, 158, 160, 255};  
            } 
        }

        // Create a prop_physics entity
        int drop = UTIL_CreatePhysics("present", vPosition, NULL_VECTOR, sModel, PHYS_FORCESERVERSIDE | PHYS_NOTAFFECTBYROTOR);
        
        // Validate entity
        if (drop != -1)
        {
            // Sets physics
            SetEntProp(drop, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_WEAPON);
            SetEntProp(drop, Prop_Data, "m_nSolidType", SOLID_VPHYSICS);
            SetEntPropFloat(drop, Prop_Data, "m_flElasticity", PRESENT_ELASTICITY);
            
            // Sets health
            SetEntProp(drop, Prop_Data, "m_takedamage", DAMAGE_YES);
            SetEntProp(drop, Prop_Data, "m_iHealth", PRESENT_HEALTH);
            SetEntProp(drop, Prop_Data, "m_iMaxHealth", PRESENT_HEALTH);
            
            // Sets type
            SetEntProp(drop, Prop_Data, "m_iHammerID", iType);
            
            // Create damage hook
            SDKHook(drop, SDKHook_OnTakeDamage, CaseDamageHook);
            
#if defined PRESENT_GLOW
            // Create a prop_dynamic_override entity
            int glow = UTIL_CreateDynamic("glow", vPosition, NULL_VECTOR, sModel, "ref");

            // Validate entity
            if (glow != -1)
            {
                // Sets parent to the entity
                SetVariantString("!activator");
                AcceptEntityInput(glow, "SetParent", drop, glow);

                // Sets glowing mode
                UTIL_CreateGlowing(glow, true, _, vColor[0], vColor[1], vColor[2], vColor[3]);
                
                // Create transmit hook
                ///SDKHook(glow, SDKHook_SetTransmit, CaseTransmitHook);
            }
#endif
        }
        
        // Increment amount
        gCaseCount++;
    }
    
    // i = client index
    for (int i = 1; i <= MaxClients; i++)
    {
        // Validate client
        if (IsPlayerExist(i))
        {
            // Validate human
            if (ZP_IsPlayerHuman(i))
            {
                // Show message
                SetGlobalTransTarget(i);
                PrintHintText(i, "%t", "present arrived");
            }
            
            // Play sound
            ZP_EmitSoundToClient(gSound, 1, i, SOUND_FROM_PLAYER, SNDCHAN_STATIC, hSoundLevel.IntValue);
        }
    }
    
    // Allow timer
    return Plugin_Continue;
}

/**
 * @brief Case damage hook.
 *
 * @param entity            The entity index.    
 * @param attacker          The attacker index.
 * @param inflictor         The inflictor index.
 * @param flDamage          The damage amount.
 * @param iBits             The damage type.
 **/
public Action CaseDamageHook(int entity, int &attacker, int &inflictor, float &flDamage, int &iBits)
{
    // Calculate the damage
    int iHealth = GetEntProp(entity, Prop_Data, "m_iHealth") - RoundToNearest(flDamage); iHealth = (iHealth > 0) ? iHealth : 0;

    // Validate death
    int iType = GetEntProp(entity, Prop_Data, "m_iHammerID");
    if (!iHealth && iType != -1) /// Avoid double spawn
    {
        // Initialize vectors
        static float vPosition[3]; static float vAngle[3];
                        
        // Gets entity position
        GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosition);
        GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", vAngle);
    
        // Switch case type
        MenuType mSlot;
        switch (iType)
        {
            case EXPL   : mSlot = MenuType_Shotguns;
            case HEAVY  : mSlot = MenuType_Machineguns;
            case LIGHT  : mSlot = MenuType_Rifles;
            case PISTOL : mSlot = MenuType_Pistols;
            case HPIST  : mSlot = MenuType_Snipers;
            case TOOLS  : mSlot = MenuType_Knifes;
            case HTOOL  : mSlot = MenuType_Invalid;
        }
        
        // Create random weapon
        SpawnRandomWeapon(vPosition, vAngle, mSlot);
        
        // Block it
        SetEntProp(entity, Prop_Data, "m_iHammerID", -1);
        
        // Decrease amount
        gCaseCount--;
    }
}

/**
 * @brief Called right before the entity transmitting to other entities.
 *
 * @param entity            The entity index.
 * @param client            The client index.
 **/
/*public Action CaseTransmitHook(int entity, int client)
{
    // Validate zombie
    if (ZP_IsPlayerZombie(client))
    {
        // Block transmitting
        return Plugin_Handled;
    }

    // Allow transmitting
    return Plugin_Continue;
}*/

//**********************************************
//* Item (npc) stocks.                         *
//**********************************************

/**
 * @brief Spawn the random weapon.
 *       
 * @param vPosition         The origin of the spawn.
 * @param vAngle            The angle of the spawn.
 * @param mSlot             The slot index selected.
 **/
stock void SpawnRandomWeapon(float vPosition[3], float vAngle[3], MenuType mSlot)
{
    // Valdiate random weapon id
    int iD = FindRandomWeapon(mSlot);
    if (iD != -1)
    {
        // Create a random weapon entity
        ZP_CreateWeapon(iD, vPosition, vAngle);
    }
}

/**
 * @brief Find the random id of any custom weapons.
 *       
 * @param mSlot             (Optional) The slot index selected.
 * @return                  The weapon id.
 **/
stock int FindRandomWeapon(MenuType mSlot = MenuType_Invalid) 
{
    // Initialize name char
    static char sClassname[SMALL_LINE_LENGTH];
    
    // Gets total amount of weapons
    int iSize = ZP_GetNumberWeapon();
    
    // Dynamicly allocate array
    int[] weaponID = new int[iSize]; int x;
    
    // Validate all types
    if (mSlot == MenuType_Invalid)
    {
        // i = weapon id 
        for (int i = 0; i < iSize; i++)
        {
            // Validate class/drop/slot
            ZP_GetWeaponClass(i, sClassname, sizeof(sClassname));
            if (StrContains(sClassname, "human", false) == -1 || !ZP_IsWeaponDrop(i))
            {
                continue;
            }

            // Validate def index
            ItemDef iItem = ZP_GetWeaponDefIndex(i);
            if (IsItem(iItem) || iItem == ItemDef_Fists)
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
        for (int i = 0; i < iSize; i++)
        {
            // Validate class/drop/slot
            ZP_GetWeaponClass(i, sClassname, sizeof(sClassname));
            if (StrContains(sClassname, "human", false) == -1 || !ZP_IsWeaponDrop(i) || ZP_GetWeaponSlot(i) != mSlot)
            {
                continue;
            }

            // Validate def index
            ItemDef iItem = ZP_GetWeaponDefIndex(i);
            if (IsItem(iItem) || iItem == ItemDef_Fists)
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
 * @brief Find the random position from the navigation mesh.
 *       
 * @param vPosition         (Optional) The position output.
 * @return                  True on no colission, false otherwise.
 **/
stock bool FindRandomPosition(float vPosition[3])
{
    // Gets random array
    hPosition.GetArray(GetRandomInt(0, hPosition.Length - 1), vPosition, sizeof(vPosition));

    // Dublicate vector
    static float vCenter[3]; vCenter = vPosition;
        
    // Initialize the hull vectors
    static const float vMins[3] = { -30.0, -30.0, 0.0   }; 
    static const float vMaxs[3] = {  30.0,  30.0, 30.0  }; 
    
    // Create the hull trace
    vCenter[2] += vMaxs[2] / 2.0; /// Move center of hull upward
    TR_TraceHull(vCenter, vCenter, vMins, vMaxs, MASK_SOLID);
    
    // Validate no collisions
    return !TR_DidHit();
}