/**
 * ============================================================================
 *
 *  Zombie Plague Mod #3 Generation
 *
 *  File:          natives.h.cpp
 *  Type:          API 
 *  Description:   Forwards handlers for the ZP API.
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
 * List of forwards used by the plugin.
 **/
enum ForwardsList
{
    Handle:OnClientInfected,
    Handle:OnClientHumanized,
    Handle:OnClientDamaged,
    Handle:OnClientValidateItem,
    Handle:OnClientBuyItem,
    Handle:OnClientValidateMenu,
    Handle:OnClientValidateZombie,
    Handle:OnClientValidateHuman,
    Handle:OnClientValidateCostume,
    Handle:OnClientSkillUsed,
    Handle:OnClientSkillOver,
    Handle:OnWeaponCreated,
    Handle:OnZombieModStarted,
    Handle:OnEngineExecute
}

/**
 * Array to store forward data in.
 **/
Handle gForwardsList[ForwardsList];

/**
 * Initializes all natives and forwards related to infection.
 **/
void APIForwardsInit(/*void*/)
{
    gForwardsList[OnClientInfected]        = CreateGlobalForward("ZP_OnClientInfected", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
    gForwardsList[OnClientHumanized]       = CreateGlobalForward("ZP_OnClientHumanized", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    gForwardsList[OnClientDamaged]         = CreateGlobalForward("ZP_OnClientDamaged", ET_Ignore, Param_Cell, Param_Cell, Param_FloatByRef, Param_Cell);
    gForwardsList[OnClientValidateItem]    = CreateGlobalForward("ZP_OnClientValidateExtraItem", ET_Hook, Param_Cell, Param_Cell);
    gForwardsList[OnClientBuyItem]         = CreateGlobalForward("ZP_OnClientBuyExtraItem", ET_Ignore, Param_Cell, Param_Cell);
    gForwardsList[OnClientValidateMenu]    = CreateGlobalForward("ZP_OnClientValidateMainMenu", ET_Hook, Param_Cell);
    gForwardsList[OnClientValidateZombie]  = CreateGlobalForward("ZP_OnClientValidateZombieClass", ET_Hook, Param_Cell, Param_Cell);
    gForwardsList[OnClientValidateHuman]   = CreateGlobalForward("ZP_OnClientValidateHumanClass", ET_Hook, Param_Cell, Param_Cell);
    gForwardsList[OnClientValidateCostume] = CreateGlobalForward("ZP_OnClientValidateCostume", ET_Hook, Param_Cell, Param_Cell);
    gForwardsList[OnClientSkillUsed]       = CreateGlobalForward("ZP_OnClientSkillUsed", ET_Hook, Param_Cell);
    gForwardsList[OnClientSkillOver]       = CreateGlobalForward("ZP_OnClientSkillOver", ET_Ignore, Param_Cell);
    gForwardsList[OnWeaponCreated]         = CreateGlobalForward("ZP_OnWeaponCreated", ET_Ignore, Param_Cell, Param_Cell);
    gForwardsList[OnZombieModStarted]      = CreateGlobalForward("ZP_OnZombieModStarted", ET_Ignore, Param_Cell);
    gForwardsList[OnEngineExecute]         = CreateGlobalForward("ZP_OnEngineExecute", ET_Ignore);
}

/**
 * Called when a client became a zombie/nemesis.
 * 
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param nemesisMode       Indicates that client will be a nemesis.
 * @param respawnMode       Indicates that infection was on spawn.
 **/
void API_OnClientInfected(const int victimIndex, const int attackerIndex, const bool nemesisMode = false, const bool respawnMode = false)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientInfected]);

    // Push the parameters
    Call_PushCell(victimIndex);
    Call_PushCell(attackerIndex);
    Call_PushCell(nemesisMode);
    Call_PushCell(respawnMode);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called when a client became a human/survivor.
 * 
 * @param clientIndex       The client index.
 * @param survivorMode      Indicates that client will be a survivor.
 * @param respawnMode       Indicates that humanizing was on spawn.
 **/
void API_OnClientHumanized(const int clientIndex, const bool survivorMode = false, const bool respawnMode = false)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientHumanized]);

    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(survivorMode);
    Call_PushCell(respawnMode);

    // Finish the call
    Call_Finish();
}

/**
 * Called when a client take a fake damage.
 * 
 * @param victimIndex       The client index.
 * @param attackerIndex     The attacker index.
 * @param damageAmount      The amount of damage inflicted.
 * @param damageType        The ditfield of damage types
 **/
void API_OnClientDamaged(const int victimIndex, const int attackerIndex, float &damageAmount, const int damageType)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientDamaged]);

    // Push the parameters
    Call_PushCell(victimIndex);
    Call_PushCell(attackerIndex);
    Call_PushFloatRef(damageAmount);
    Call_PushCell(damageType);

    // Finish the call
    Call_Finish();
}

/**
 * Called before show an extraitem in the equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param itemID            The index of extraitem from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and calling the ZP_OnClientBuyExtraItem() forward.
 **/
Action API_OnClientValidateExtraItem(const int clientIndex, const int itemIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateItem]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(itemIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called after select an extraitem in equipment menu.
 * 
 * @param clientIndex       The client index.
 * @param itemIndex         The index of extra item from ZP_RegisterExtraItem() native.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block purhase. Anything else
 *                                 (like Plugin_Continue) to allow purhase and withdraw ammopacks.
 **/
void API_OnClientBuyExtraItem(const int clientIndex, const int itemIndex)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientBuyItem]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(itemIndex);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called before show a main menu.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block showing. Anything else
 *                              (like Plugin_Continue) to allow showing.
 **/
Action API_OnClientValidateMainMenu(const int clientIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateMenu]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called before show a zombie class in the zombie class menu.
 * 
 * @param clientIndex       The client index.
 * @param classIndex        The index of class from ZP_RegisterZombieClass() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
Action API_OnClientValidateZombieClass(const int clientIndex, const int classIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateZombie]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(classIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called before show a human class in the human class menu.
 * 
 * @param clientIndex       The client index.
 * @param classIndex        The index of class from ZP_RegisterHumanClass() native.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
Action API_OnClientValidateHumanClass(const int clientIndex, const int classIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateHuman]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(classIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called before show a costume in the costumes menu.
 * 
 * @param clientIndex       The client index.
 * @param costumeID         The costume index.
 *
 * @return                  Plugin_Handled to disactivate showing and Plugin_Stop to disabled showing. Anything else
 *                              (like Plugin_Continue) to allow showing and selecting.
 **/
Action API_OnClientValidateCostume(const int clientIndex, const int costumeIndex)
{
    // Initialize future result
    Action resultHandle;
    
    // Start forward call
    Call_StartForward(gForwardsList[OnClientValidateCostume]);
    
    // Push the parameters
    Call_PushCell(clientIndex);
    Call_PushCell(costumeIndex);
    
    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called when a client use a zombie skill.
 * 
 * @param clientIndex       The client index.
 *
 * @return                  Plugin_Handled or Plugin_Stop to block using skill. Anything else
 *                                (like Plugin_Continue) to allow use.
 **/
Action API_OnClientSkillUsed(const int clientIndex)
{
    // Initialize future result
    Action resultHandle;

    // Start forward call
    Call_StartForward(gForwardsList[OnClientSkillUsed]);

    // Push the parameters
    Call_PushCell(clientIndex);

    // Finish the call
    Call_Finish(resultHandle);
    
    // Return result
    return resultHandle;
}

/**
 * Called when a zombie skill duration is over.
 * 
 * @param clientIndex       The client index.
 **/
void API_OnClientSkillOver(const int clientIndex)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnClientSkillOver]);

    // Push the parameters
    Call_PushCell(clientIndex);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called after a custom weapon is created.
 *
 * @param weaponIndex       The weapon index.
 * @param weaponID          The weapon id.
 **/
void API_OnWeaponCreated(const int weaponIndex, const int weaponID)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnWeaponCreated]);

    // Push the parameters
    Call_PushCell(weaponIndex);
    Call_PushCell(weaponID);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called after a zombie round is started.
 * 
 * @param modeIndex         The mode index.
 **/
void API_OnZombieModStarted(const int modeIndex)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnZombieModStarted]);

    // Push the parameters
    Call_PushCell(modeIndex);
    
    // Finish the call
    Call_Finish();
}

/**
 * Called after a zombie core is loaded.
 **/
void API_OnEngineExecute(/*void*/)
{
    // Start forward call
    Call_StartForward(gForwardsList[OnEngineExecute]);

    // Finish the call
    Call_Finish();
}