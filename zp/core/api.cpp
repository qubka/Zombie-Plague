/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          api.cpp
 *  Type:          Main 
 *  Description:   Native handlers for the ZP API.
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
 
/*
 * Application Programming Interface (API)
 * 
 * To allow other plugins or extensions to interact directly with Zombie Plague Mod we need to implement
 * an API.  SourceMod allows us to do this by creating global "natives" or "forwards."
 * 
 * To better understand how natives and forwards are created, go here:
 * http://wiki.alliedmods.net/Creating_Natives_(SourceMod_Scripting)
 * http://wiki.alliedmods.net/Function_Calling_API_(SourceMod_Scripting) 
 */

/**
 * @section Struct of forwards used by the plugin.
 **/
enum struct ForwardData
{
    /* Global */
    Handle OnClientUpdated;
    Handle OnClientDamaged;
    Handle OnClientValidateItem;
    Handle OnClientBuyItem;
    Handle OnClientValidateClass;
    Handle OnClientValidateCostume;
    Handle OnClientValidateWeapon;
    Handle OnClientValidateMode;
    Handle OnClientValidateMenu;
    Handle OnClientSkillUsed;
    Handle OnClientSkillOver;
    Handle OnClientMoney;
    Handle OnClientLevel;
    Handle OnClientExp;
    Handle OnGrenadeCreated;
    Handle OnWeaponCreated;
    Handle OnWeaponRunCmd;
    Handle OnWeaponDeploy;
    Handle OnWeaponHolster;
    Handle OnWeaponReload;
    Handle OnWeaponBullet;
    Handle OnWeaponShoot;
    Handle OnWeaponFire;
    Handle OnGameModeStart;
    Handle OnGameModeEnd;
    Handle OnEngineExecute;
    
    /**
     * @brief Initializes all forwards.
     **/
    void OnForwardInit(/*void*/)
    {
        this.OnClientUpdated         = CreateGlobalForward("ZP_OnClientUpdated", ET_Ignore, Param_Cell, Param_Cell);
        this.OnClientDamaged         = CreateGlobalForward("ZP_OnClientDamaged", ET_Ignore, Param_Cell, Param_CellByRef, Param_CellByRef, Param_FloatByRef, Param_CellByRef, Param_CellByRef);
        this.OnClientValidateItem    = CreateGlobalForward("ZP_OnClientValidateExtraItem", ET_Hook, Param_Cell, Param_Cell);
        this.OnClientBuyItem         = CreateGlobalForward("ZP_OnClientBuyExtraItem", ET_Ignore, Param_Cell, Param_Cell);
        this.OnClientValidateClass   = CreateGlobalForward("ZP_OnClientValidateClass", ET_Hook, Param_Cell, Param_Cell);
        this.OnClientValidateCostume = CreateGlobalForward("ZP_OnClientValidateCostume", ET_Hook, Param_Cell, Param_Cell);
        this.OnClientValidateWeapon  = CreateGlobalForward("ZP_OnClientValidateWeapon", ET_Hook, Param_Cell, Param_Cell);
        this.OnClientValidateMode    = CreateGlobalForward("ZP_OnClientValidateMode", ET_Hook, Param_Cell, Param_Cell);
        this.OnClientValidateMenu    = CreateGlobalForward("ZP_OnClientValidateMenu", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
        this.OnClientSkillUsed       = CreateGlobalForward("ZP_OnClientSkillUsed", ET_Hook, Param_Cell);
        this.OnClientSkillOver       = CreateGlobalForward("ZP_OnClientSkillOver", ET_Ignore, Param_Cell);
        this.OnClientMoney           = CreateGlobalForward("ZP_OnClientMoney", ET_Ignore, Param_Cell, Param_CellByRef);
        this.OnClientLevel           = CreateGlobalForward("ZP_OnClientLevel", ET_Ignore, Param_Cell, Param_CellByRef);
        this.OnClientExp             = CreateGlobalForward("ZP_OnClientExp", ET_Ignore, Param_Cell, Param_CellByRef);
        this.OnGrenadeCreated        = CreateGlobalForward("ZP_OnGrenadeCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
        this.OnWeaponCreated         = CreateGlobalForward("ZP_OnWeaponCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
        this.OnWeaponRunCmd          = CreateGlobalForward("ZP_OnWeaponRunCmd", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell, Param_Cell, Param_Cell);
        this.OnWeaponDeploy          = CreateGlobalForward("ZP_OnWeaponDeploy", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
        this.OnWeaponHolster         = CreateGlobalForward("ZP_OnWeaponHolster", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
        this.OnWeaponReload          = CreateGlobalForward("ZP_OnWeaponReload", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
        this.OnWeaponBullet          = CreateGlobalForward("ZP_OnWeaponBullet", ET_Ignore, Param_Cell, Param_Array, Param_Cell, Param_Cell);
        this.OnWeaponShoot           = CreateGlobalForward("ZP_OnWeaponShoot", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
        this.OnWeaponFire            = CreateGlobalForward("ZP_OnWeaponFire", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
        this.OnGameModeStart         = CreateGlobalForward("ZP_OnGameModeStart", ET_Ignore, Param_Cell);
        this.OnGameModeEnd           = CreateGlobalForward("ZP_OnGameModeEnd", ET_Ignore, Param_Cell);
        this.OnEngineExecute         = CreateGlobalForward("ZP_OnEngineExecute", ET_Ignore);
    }
    
    /**
     * @brief Called when a client became a zombie/human.
     * 
     * @param clientIndex       The client index.
     * @param attackerIndex     The attacker index.
     **/
    void _OnClientUpdated(int clientIndex, int attackerIndex)
    {
        Call_StartForward(this.OnClientUpdated);
        Call_PushCell(clientIndex);
        Call_PushCell(attackerIndex);
        Call_Finish();
    }

    /**
     * @brief Called when a client take a fake damage.
     * 
     * @param clientIndex       The client index.
     * @param attackerIndex     The attacker index.
     * @param inflictorIndex    The inflictor index.
     * @param flDamage          The amount of damage inflicted.
     * @param iBits             The ditfield of damage types.
     * @param weaponIndex       The weapon index or -1 for unspecified.
     **/
    void _OnClientDamaged(int clientIndex, int &attackerIndex, int &inflictorIndex, float &flDamage, int &iBits, int &weaponIndex)
    {
        Call_StartForward(this.OnClientDamaged);
        Call_PushCell(clientIndex);
        Call_PushCellRef(attackerIndex);
        Call_PushCellRef(inflictorIndex);
        Call_PushFloatRef(flDamage);
        Call_PushCellRef(iBits);
        Call_PushCellRef(weaponIndex);
        Call_Finish();
    }

    /**
     * @brief Called before show an extraitem in the equipment menu.
     * 
     * @param clientIndex       The client index.
     * @param itemID            The item index.
     *
     * @param resultHandle      Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
     *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
     **/
    void _OnClientValidateExtraItem(int clientIndex, int itemIndex, Action &resultHandle)
    {
        Call_StartForward(this.OnClientValidateItem);
        Call_PushCell(clientIndex);
        Call_PushCell(itemIndex);
        Call_Finish(resultHandle);
    }

    /**
     * @brief Called after select an extraitem in equipment menu.
     * 
     * @param clientIndex       The client index.
     * @param itemIndex         The item index.
     **/
    void _OnClientBuyExtraItem(int clientIndex, int itemIndex)
    {
        Call_StartForward(this.OnClientBuyItem);
        Call_PushCell(clientIndex);
        Call_PushCell(itemIndex);
        Call_Finish();
    }

    /**
     * @brief Called before show a class in the class menu.
     * 
     * @param clientIndex       The client index.
     * @param classIndex        The class index.
     *
     * @param resultHandle      Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
     *                              (like Plugin_Continue) to allow showing and selecting.
     **/
    void _OnClientValidateClass(int clientIndex, int classIndex, Action &resultHandle)
    {
        Call_StartForward(this.OnClientValidateClass);
        Call_PushCell(clientIndex);
        Call_PushCell(classIndex);
        Call_Finish(resultHandle);
    }

    /**
     * @brief Called before show a costume in the costumes menu.
     * 
     * @param clientIndex       The client index.
     * @param costumeID         The costume index.
     *
     * @param resultHandle      Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
     *                              (like Plugin_Continue) to allow showing and selecting.
     **/
    void _OnClientValidateCostume(int clientIndex, int costumeIndex, Action &resultHandle)
    {
        Call_StartForward(this.OnClientValidateCostume);
        Call_PushCell(clientIndex);
        Call_PushCell(costumeIndex);
        Call_Finish(resultHandle);
    }

    /**
     * @brief Called before show a weapon in the weapons menu.
     * 
     * @param clientIndex       The client index.
     * @param weaponIndex       The weapon index.
     *
     * @param resultHandle      Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
     *                              (like Plugin_Continue) to allow showing and selecting.
     **/
    void _OnClientValidateWeapon(int clientIndex, int weaponIndex, Action &resultHandle)
    {
        Call_StartForward(this.OnClientValidateWeapon);
        Call_PushCell(clientIndex);
        Call_PushCell(weaponIndex);
        Call_Finish(resultHandle);
    }
    
    /**
     * @brief Called before show a game mode in the modes menu.
     * 
     * @param clientIndex       The client index.
     * @param modeIndex         The mode index.
     *
     * @param resultHandle      Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
     *                              (like Plugin_Continue) to allow showing and selecting.
     **/
    void _OnClientValidateMode(int clientIndex, int modeIndex, Action &resultHandle)
    {
        Call_StartForward(this.OnClientValidateMode);
        Call_PushCell(clientIndex);
        Call_PushCell(modeIndex);
        Call_Finish(resultHandle);
    }

    /**
     * @brief Called before show a slot in the main/sub menu.
     * 
     * @param clientIndex       The client index.
     * @param slotIndex         The slot index.
     * @param subIndex          (Optional) The submenu index.
     *
     * @param resultHandle      Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
     *                              (like Plugin_Continue) to allow showing and selecting.
     **/
    void _OnClientValidateMenu(int clientIndex, int slotIndex, int subIndex = 0, Action &resultHandle)
    {
        Call_StartForward(this.OnClientValidateMenu);
        Call_PushCell(clientIndex);
        Call_PushCell(slotIndex);
        Call_PushCell(subIndex);
        Call_Finish(resultHandle);
    }

    /**
     * @brief Called when a client use a zombie skill.
     * 
     * @param clientIndex       The client index.
     *
     * @param resultHandle      Plugin_Handled or Plugin_Stop to block using skill. Anything else
     *                                (like Plugin_Continue) to allow use.
     **/
    void _OnClientSkillUsed(int clientIndex, Action &resultHandle)
    {
        Call_StartForward(this.OnClientSkillUsed);
        Call_PushCell(clientIndex);
        Call_Finish(resultHandle);
    }

    /**
     * @brief Called when a zombie skill duration is over.
     * 
     * @param clientIndex       The client index.
     **/
    void _OnClientSkillOver(int clientIndex)
    {
        Call_StartForward(this.OnClientSkillOver);
        Call_PushCell(clientIndex);
        Call_Finish();
    }
    
    /**
     * @brief Called when a client receive money.
     * 
     * @param clientIndex       The client index.
     * @param iMoney            The money amount.
     **/
    void _OnClientMoney(int clientIndex, int &iMoney)
    {
        Call_StartForward(this.OnClientMoney);
        Call_PushCell(clientIndex);
        Call_PushCellRef(iMoney);
        Call_Finish();
    }
    
    /**
     * @brief Called when a client receive level.
     * 
     * @param clientIndex       The client index.
     * @param iLevel            The level amount.
     **/
    void _OnClientLevel(int clientIndex, int &iLevel)
    {
        Call_StartForward(this.OnClientLevel);
        Call_PushCell(clientIndex);
        Call_PushCellRef(iLevel);
        Call_Finish();
    }
    
    /**
     * @brief Called when a client receive experience.
     * 
     * @param clientIndex       The client index.
     * @param iExp              The experience amount.
     **/
    void _OnClientExp(int clientIndex, int &iExp)
    {
        Call_StartForward(this.OnClientExp);
        Call_PushCell(clientIndex);
        Call_PushCellRef(iExp);
        Call_Finish();
    }
    
    /**
     * @brief Called after a custom grenade is created.
     *
     * @param clientIndex       The client index.
     * @param grenadeIndex      The grenade index.
     * @param weaponID          The weapon id.
     **/
    void _OnGrenadeCreated(int clientIndex, int grenadeIndex, int weaponID)
    {
        Call_StartForward(this.OnGrenadeCreated);
        Call_PushCell(clientIndex);
        Call_PushCell(grenadeIndex);
        Call_PushCell(weaponID);
        Call_Finish();
    }

    /**
     * @brief Called after a custom weapon is created.
     *
     * @param clientIndex       The client index.
     * @param weaponIndex       The weapon index.
     * @param weaponID          The weapon id.
     **/
    void _OnWeaponCreated(int clientIndex, int weaponIndex, int weaponID)
    {
        Call_StartForward(this.OnWeaponCreated);
        Call_PushCell(clientIndex);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish();
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
     * @param resultHandle      Plugin_Continue to allow buttons. Anything else
     *                                (like Plugin_Changed) to change buttons.
     **/
    void _OnWeaponRunCmd(int clientIndex, int &iButtons, int iLastButtons, int weaponIndex, int weaponID, Action &resultHandle)
    {
        Call_StartForward(this.OnWeaponRunCmd);
        Call_PushCell(clientIndex);
        Call_PushCellRef(iButtons);
        Call_PushCell(iLastButtons);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish(resultHandle);
    }

    /**
     * @brief Called on deploy of a weapon.
     *
     * @param clientIndex       The client index.
     * @param weaponIndex       The weapon index.
     * @param weaponID          The weapon id.
     **/
    void _OnWeaponDeploy(int clientIndex, int weaponIndex, int weaponID)
    {
        Call_StartForward(this.OnWeaponDeploy);
        Call_PushCell(clientIndex);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish();
    }

    /**
     * @brief Called on holster of a weapon.
     *
     * @param clientIndex       The client index.
     * @param weaponIndex       The weapon index.
     * @param weaponID          The weapon id.
     **/
    void _OnWeaponHolster(int clientIndex, int weaponIndex, int weaponID)
    {
        Call_StartForward(this.OnWeaponHolster);
        Call_PushCell(clientIndex);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish();
    }

    /**
     * @brief Called on reload of a weapon.
     *
     * @param clientIndex       The client index.
     * @param weaponIndex       The weapon index.
     * @param weaponID          The weapon id.
     **/
    void _OnWeaponReload(int clientIndex, int weaponIndex, int weaponID)
    {
        Call_StartForward(this.OnWeaponReload);
        Call_PushCell(clientIndex);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish();
    }

    /**
     * @brief Called on bullet of a weapon.
     *
     * @param clientIndex       The client index.
     * @param vBulletPosition   The position of a bullet hit.
     * @param weaponIndex       The weapon index.
     * @param weaponID          The weapon id.
     *
     * @noreturn
     **/
    void _OnWeaponBullet(int clientIndex, float vBulletPosition[3], int weaponIndex, int weaponID)
    {
        Call_StartForward(this.OnWeaponBullet);
        Call_PushCell(clientIndex);
        Call_PushArray(vBulletPosition, 3);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish();
    }

    /**
     * @brief Called on shoot of a weapon.
     *
     * @param clientIndex       The client index.
     * @param weaponIndex       The weapon index.
     * @param weaponID          The weapon id.
     **/
    void _OnWeaponShoot(int clientIndex, int weaponIndex, int weaponID)
    {
        Call_StartForward(this.OnWeaponShoot);
        Call_PushCell(clientIndex);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish();
    }

    /**
     * @brief Called on fire of a weapon.
     *
     * @param clientIndex       The client index.
     * @param weaponIndex       The weapon index.
     * @param weaponID          The weapon id.
     **/
    void _OnWeaponFire(int clientIndex, int weaponIndex, int weaponID)
    {
        Call_StartForward(this.OnWeaponFire);
        Call_PushCell(clientIndex);
        Call_PushCell(weaponIndex);
        Call_PushCell(weaponID);
        Call_Finish();
    }

    /**
     * @brief Called after a zombie round is started.
     * 
     * @param modeIndex         The mode index.
     **/
    void _OnGameModeStart(int modeIndex)
    {
        Call_StartForward(this.OnGameModeStart);
        Call_PushCell(modeIndex);
        Call_Finish();
    }
    
    /**
     * @brief Called after a zombie round is ended.
     * 
     * @param reasonIndex       The reason index.
     **/
    void _OnGameModeEnd(CSRoundEndReason reasonIndex)
    {
        Call_StartForward(this.OnGameModeEnd);
        Call_PushCell(reasonIndex);
        Call_Finish();
    }

    /**
     * @brief Called after a zombie core is loaded.
     **/
    void _OnEngineExecute(/*void*/)
    {
        Call_StartForward(this.OnEngineExecute);
        Call_Finish();
    }
};
/**
 * @endsection
 **/

/**
 * @brief Array to store forward data in.
 **/
ForwardData gForwardData;

/**
 * @brief Initializes all main natives and forwards.
 **/
APLRes APIOnInit(/*void*/)
{
    // Forward event to sub-modules
    ToolsOnNativeInit();
    ClassesOnNativeInit();
    ExtraItemsOnNativeInit();
    WeaponsOnNativeInit();
    SoundsOnNativeInit();
    HitGroupsOnNativeInit();
    MenusOnNativeInit();
    GameModesOnNativeInit();
    CostumesOnNativeInit();
    
    // Register natives
    APIOnNativeInit();

    // Register forwards
    gForwardData.OnForwardInit();
    
    // Register library
    RegPluginLibrary("zombieplague");
    
    // Return on success
    return APLRes_Success;
}

/**
 * @brief Initializes all natives.
 **/
void APIOnNativeInit(/*void*/)
{
    // Create main natives
    CreateNative("ZP_IsPlayerInGroup",  API_IsPlayerInGroup);
    CreateNative("ZP_IsPlayerZombie",   API_IsPlayerZombie);
    CreateNative("ZP_IsPlayerHuman",    API_IsPlayerHuman);
    CreateNative("ZP_IsNewRound",       API_IsNewRound);
    CreateNative("ZP_IsEndRound",       API_IsEndRound);
    CreateNative("ZP_IsStartedRound",   API_IsStartedRound);
    CreateNative("ZP_GetNumberRound",   API_GetNumberRound);
    CreateNative("ZP_GetHumanAmount",   API_GetHumanAmount);
    CreateNative("ZP_GetZombieAmount",  API_GetZombieAmount);
    CreateNative("ZP_GetAliveAmount",   API_GetAliveAmount);
    CreateNative("ZP_GetPlayingAmount", API_GetPlayingAmount);
    CreateNative("ZP_GetRandomHuman",   API_GetRandomHuman);
    CreateNative("ZP_GetRandomZombie",  API_GetRandomZombie); 
}

/**
 * @brief Returns whether a player is in group or not.
 *
 * @note native bool ZP_IsPlayerInGroup(clientIndex, group);
 **/
public int API_IsPlayerInGroup(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Initialize group char
    static char sGroup[SMALL_LINE_LENGTH];
    GetNativeString(2, sGroup, sizeof(sGroup));
    
    // Return the value
    return IsPlayerInGroup(clientIndex, sGroup);
}

/**
 * @brief Returns true if the player is a zombie, false if not. 
 *
 * @note native bool ZP_IsPlayerZombie(clientIndex);
 **/
public int API_IsPlayerZombie(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return gClientData[clientIndex].Zombie;
}

/**
 * @brief Returns true if the player is a human, false if not.
 *
 * @note native bool ZP_IsPlayerHuman(clientIndex);
 **/
public int API_IsPlayerHuman(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value
    return !gClientData[clientIndex].Zombie;
}

/**
 * @brief Gets the last player disconnected time.
 *
 * @note native int ZP_GetClientTime(clientIndex);
 **/
public int API_GetClientTime(Handle hPlugin, int iNumParams)
{
    // Gets real player index from native cell 
    int clientIndex = GetNativeCell(1);

    // Return the value 
    return gClientData[clientIndex].Time;
}


/*________________________________________________________________________*/

/**
 * @brief Gets the new round state.
 *
 * @note native bool ZP_IsNewRound();
 **/
public int API_IsNewRound(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.RoundNew;
}

/**
 * @brief Gets the end round state.
 *
 * @note native bool ZP_IsEndRound();
 **/
public int API_IsEndRound(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.RoundEnd;
}

/**
 * @brief Gets the new round state.
 *
 * @note native bool ZP_IsStartedRound();
 **/
public int API_IsStartedRound(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.RoundStart;
}

/**
 * @brief Gets the number of round.
 *
 * @note native int ZP_GetNumberRound();
 **/
public int API_GetNumberRound(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return gServerData.RoundNumber;
}

/**
 * @brief Gets amount of total humans.
 *
 * @note native int ZP_GetHumanAmount();
 **/
public int API_GetHumanAmount(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return fnGetHumans();
}

/**
 * @brief Gets amount of total zombies.
 *
 * @note native int ZP_GetZombieAmount();
 **/
public int API_GetZombieAmount(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return fnGetZombies();
}

/**
 * @brief Gets amount of total alive players.
 *
 * @note native int ZP_GetAliveAmount();
 **/
public int API_GetAliveAmount(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return fnGetAlive();
}

/**
 * @brief Gets amount of total playing players.
 *
 * @note native int ZP_GetPlayingAmount();
 **/
public int API_GetPlayingAmount(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return fnGetPlaying();
}

/**
 * @brief Gets index of the random human.
 *
 * @note native int ZP_GetRandomHuman();
 **/
public int API_GetRandomHuman(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return fnGetRandomHuman();
}

/**
 * @brief Gets index of the random zombie.
 *
 * @note native int ZP_GetRandomZombie();
 **/
public int API_GetRandomZombie(Handle hPlugin, int iNumParams)
{
    // Return the value 
    return fnGetRandomZombie();
}