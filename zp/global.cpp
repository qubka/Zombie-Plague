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

/*
 * Note: See global.h for header types and defines.
 */

#include "zp/global.h.cpp"
 
/***************************************************************************************
 *                                													   *
 *   					 	 *** 	 METHOD MAP CLASS 	 ***	  	  				   *		
 *                                													   *
 ***************************************************************************************/

methodmap CBasePlayer
{


	//*********************************************************************
	//*            				CONSTRUCTOR           	  				  *
	//*********************************************************************

	//! Initialize methodmap class
	public CBasePlayer(int x)
	{
		return view_as<CBasePlayer>(x);
	}

	//! Transform index to normal integer
	property int Index 
	{ 
		public get()                
		{ 
			return view_as<int>(this); 
		} 
	}

	//*********************************************************************
	//*            				PROPERTIES           	  				  *
	//*********************************************************************

	//! Health variable
	property int m_iHealth
	{
		public get() 
		{ 
			return GetClientHealth(this.Index); 
		}
		
		public set(int x) 
		{ 
			SetEntProp(this.Index, Prop_Send, "m_iHealth", x, 4); 
		}
	}

	//! Armor variable
	property int m_iArmorValue
	{
		public get() 
		{ 
			return GetClientArmor(this.Index); 
		}
		
		public set(int x) 
		{ 
			SetEntProp(this.Index, Prop_Send, "m_ArmorValue", x, 1); 
		}
	}

	//! Speed variable
	property float m_flLaggedMovementValue
	{
		public get() 
		{ 
			return GetEntPropFloat(this.Index, Prop_Data, "m_flLaggedMovementValue"); 
		}
		
		public set(float x) 
		{ 
			SetEntPropFloat(this.Index, Prop_Data, "m_flLaggedMovementValue", x); 
		}
	}

	//! Gravity variable
	property float m_flGravity
	{
		public get() 
		{ 
			return GetEntityGravity(this.Index); 
		}
		
		public set(float x)
		{ 
			SetEntityGravity(this.Index, x); 
		}
	}

	//! Flags variable
	property int m_iFrags
	{
		public get() 
		{ 
			return GetEntProp(this.Index, Prop_Data, "m_iFrags"); 
		}
		
		public set(int x)
		{ 
			SetEntProp(this.Index, Prop_Data, "m_iFrags", x); 
		}
	}

	//! Death variable
	property int m_iDeaths
	{
		public get() 
		{ 
			return GetEntProp(this.Index, Prop_Data, "m_iDeaths");
		}
		
		public set(int x) 
		{ 
			SetEntProp(this.Index, Prop_Data, "m_iDeaths", x); 
		}
	}

	//! Team variable
	property int m_iTeamNum
	{
		public get() 
		{ 
			return GetClientTeam(this.Index); 
		}
		
		public set(int x) 
		{ 
			CS_SwitchTeam(this.Index, x);
		}
	}

	//! Zombie variable
	property bool m_bZombie
	{
		public get() 
		{ 
			return gClientData[this][Client_Zombie]; 
		}
		
		public set(bool x) 
		{ 
			gClientData[this][Client_Zombie] = x; 
		}
	}

	//! Survivor variable
	property bool m_bSurvivor
	{
		public get() 
		{ 
			return gClientData[this][Client_Survivor]; 
		}
		
		public set(bool x)
		{ 
			gClientData[this][Client_Survivor] = x;
		}
	}

	//! Nemesis variable
	property bool m_bNemesis
	{
		public get() 
		{ 
			return gClientData[this][Client_Nemesis]; 
		}
		
		public set(bool x) 
		{ 
			gClientData[this][Client_Nemesis] = x; 
		}
	}

	//! Skill variable
	property bool m_bSkill
	{
		public get() 
		{ 
			return gClientData[this][Client_Skill]; 
		}
		
		public set(bool x) 
		{ 	
			gClientData[this][Client_Skill] = x; 
		}
	}

	//! Skill counter variable
	property int m_nSkillCountDown
	{
		public get() 
		{ 
			return gClientData[this][Client_SkillCountDown]; 
		}
		
		public set(int x) 
		{ 
			gClientData[this][Client_SkillCountDown] = x; 
		}
	}

	//! Skill timer variable
	property Handle m_hZombieSkillTimer
	{
		public get() 
		{ 
			return gClientData[this][Client_ZombieSkillTimer];
		}
		
		public set(Handle x) 
		{ 
			gClientData[this][Client_ZombieSkillTimer] = x;
		}
	}

	//! Zombie class variable
	property int m_nZombieClass
	{
		public get() 
		{ 
			return gClientData[this][Client_ZombieClass]; 
		}
		
		public set(int x) 
		{ 
			gClientData[this][Client_ZombieClass] = x;
		}
	}

	//! Next zombie class variable
	property int m_nZombieNext
	{
		public get() 
		{ 
			return gClientData[this][Client_ZombieClassNext]; 
		}
		
		public set(int x) 
		{ 
			gClientData[this][Client_ZombieClassNext] = x;
		}
	}

	//! Human class variable
	property int m_nHumanClass
	{
		public get() 
		{ 
			return gClientData[this][Client_HumanClass]; 
		}
		public set(int x) 
		{ 
			gClientData[this][Client_HumanClass] = x; 
		}
	}

	//! Next human class variable
	property int m_nHumanNext
	{
		public get() 
		{ 
			return gClientData[this][Client_HumanClassNext]; 
		}
		
		public set(int x) 
		{ 
			gClientData[this][Client_HumanClassNext] = x;
		}
	}

	//! Respawn team variable
	property int m_bRespawn
	{
		public get() 
		{ 
			return gClientData[this][Client_Respawn]; 
		}
		
		public set(int x) 
		{ 
			gClientData[this][Client_Respawn] = x; 
		}
	}

	//! Respawn count variable
	property int m_nRespawnTimes
	{
		public get() 
		{ 
			return gClientData[this][Client_RespawnTimes]; 
		}
		
		public set(int x) 
		{ 
			gClientData[this][Client_RespawnTimes] = x;
		}
	}

	//! Respawn timer variable
	property Handle m_hZombieRespawnTimer
	{
		public get() 
		{ 
			return gClientData[this][Client_ZombieRespawnTimer];
		}
		
		public set(Handle x) 
		{ 
			gClientData[this][Client_ZombieRespawnTimer] = x;
		}
	}

	//! Ammopacks variable
	property int m_nAmmoPacks
	{
		public get() 
		{ 
			return gClientData[this][Client_AmmoPacks]; 
		}
		
		public set(int x) 
		{
			#define GL_MONEY 65000 // It appears the maximum money a player can have is 65000
			gClientData[this][Client_AmmoPacks] = (x > GL_MONEY) ? GL_MONEY : x;  
		}
	}

	//! Spent ammopacks variable
	property int m_nLastBoughtAmount
	{
		public get() 
		{ 
			return gClientData[this][Client_LastBoughtAmount]; 
		}
		
		public set(int x)
		{ 
			gClientData[this][Client_LastBoughtAmount] = x;
		}
	}

	//! Level variable
	property int m_iLevel
	{
		public get() 
		{ 
			return gClientData[this][Client_Level]; 
		}
		
		public set(int x) 
		{
			gClientData[this][Client_Level] = x > 0 ? x : 1;
			LevelSystemOnValidate(this); //*<PREVENT FROM OVERLOAD>*/
		}
	}

	//! Exp variable
	property int m_iExp
	{
		public get() 
		{ 
			return gClientData[this][Client_Exp]; 
		}
		
		public set(int x) 
		{ 
			gClientData[this][Client_Exp] = x;
			LevelSystemOnValidateExp(this);	//*<PREVENT FROM OVERLOAD>*/
		}
	}

	//! Nightvision variable
	property int m_bNightVisionOn
	{
		public get() 
		{ 
			return GetEntProp(this.Index, Prop_Send, "m_bNightVisionOn"); 
		}
		
		public set(int x) 
		{ 
			SetEntProp(this.Index, Prop_Send, "m_bNightVisionOn", x); 
		}
	}
	
	//! Drawviewmodel variable
	property int m_bDrawViewmodel
	{
		public get() 
		{ 
			return GetEntProp(this.Index, Prop_Send, "m_bDrawViewmodel"); 
		}
		
		public set(int x) 
		{ 
			SetEntProp(this.Index, Prop_Send, "m_bDrawViewmodel", x); 
		}
	}
	
	//! Drawviewmodel variable
	property float m_flModelScale
	{
		public get() 
		{ 
			return GetEntPropFloat(this.Index, Prop_Send, "m_flModelScale"); 
		}
		
		public set(float x) 
		{ 
			SetEntPropFloat(this.Index, Prop_Send, "m_flModelScale", x); 
		}
	}

	//! Collision group variable
	property int m_iCollisionGroup
	{
		public get() 
		{ 
			return GetEntProp(this.Index, Prop_Data, "m_CollisionGroup");
		}
		
		public set(int x) 
		{ 
			SetEntProp(this.Index, Prop_Data, "m_CollisionGroup", x);
		}
	}

	//! Active weapon variable
	property int m_iActiveWeapon
	{
		public get() 
		{ 
			return GetEntPropEnt(this.Index, Prop_Data, "m_hActiveWeapon");
		}
		
		public set(int x) 
		{ 
			SetEntProp(this.Index, Prop_Data, "m_hActiveWeapon", x);
		}
	}

	//! Flags variable
	property int m_iFlags
	{
		public get() 
		{ 
			return GetEntityFlags(this.Index);
		}
		
		public set(int x) 
		{ 
			SetEntityFlags(this.Index, x);
		}
	}

	//! Move type variable
	property MoveType m_iMoveType
	{
		public get() 
		{ 
			return GetEntityMoveType(this.Index);
		}
		
		public set(MoveType x) 
		{ 
			SetEntityMoveType(this.Index, x);
		}
	}

	//*********************************************************************
	//*            					STOCKS           	  				  *
	//*********************************************************************

	//! Set money dhud
	public void m_iAccount(int x)
	{
		SetEntProp(this.Index, Prop_Send, "m_iAccount", x);
	}

	//! Set fov distance
	public void m_iFOV(int x)
	{
		SetEntProp(this.Index, Prop_Send, "m_iFOV", x);
		SetEntProp(this.Index, Prop_Send, "m_iDefaultFOV", x);
	}

	//! Set render color
	public void m_iRender(int red, int green, int blue)
	{
		#define EF_ALPHA 255
		SetEntityRenderMode(this.Index, RENDER_TRANSCOLOR);
		SetEntityRenderColor(this.Index, red, green, blue, EF_ALPHA);
	}

	//! Teleport entity
	public void m_iTeleportPlayer(float origin[3] = NULL_VECTOR, float angles[3] = NULL_VECTOR, float velocity[3] = NULL_VECTOR)
	{
		TeleportEntity(this.Index, origin, angles, velocity);
	}

	//! Respawn entity
	public void m_iRespawnPlayer()
	{
		CS_RespawnPlayer(this.Index);
	}

	//! Get origin's vector
	public void m_flGetOrigin(float x[3])
	{
		GetClientAbsOrigin(this.Index, x);
	}

	//! Get eye's vector
	public void m_flGetEyePosition(float x[3])
	{
		GetClientEyePosition(this.Index, x);
	}

	//! Get eye's angle vector
	public void m_flGetEyeAngles(float x[3])
	{
		GetClientEyeAngles(this.Index, x);
	}

	//! Get velocity's vector
	public void m_flVelocity(float x[3])
	{
		GetEntPropVector(this.Index, Prop_Data, "m_vecVelocity", x);
	}

	//! Enable/Disable flashlight or remove it
	public void m_bFlashLightOn(bool x)
	{
		#define EF_NODRAW 4
		SetEntProp(this.Index, Prop_Send, "m_fEffects", x ? (GetEntProp(this.Index, Prop_Send, "m_fEffects") ^ EF_NODRAW) : (EF_NODRAW ^ EF_NODRAW)); 
	}
	
	//! Enable/Disable some player hud
	public void m_bHideHUD(bool x)
	{
		#define TL_RADAR     (1<<12)
		#define TL_CROSSHAIR (1<<8)
		SetEntProp(this.Index, Prop_Send, "m_iHideHUD", x ? (GetEntProp(this.Index, Prop_Send, "m_iHideHUD") & ~TL_RADAR) : (GetEntProp(this.Index, Prop_Send, "m_iHideHUD") | TL_RADAR));
		SetEntProp(this.Index, Prop_Send, "m_iHideHUD", x ? (GetEntProp(this.Index, Prop_Send, "m_iHideHUD") & ~TL_CROSSHAIR) : (GetEntProp(this.Index, Prop_Send, "m_iHideHUD") | TL_CROSSHAIR));
	}
	
	//! Enable/Disable radar point
	public void m_bSpotted(bool x)
	{
		SetEntProp(this.Index, Prop_Send, "m_bSpotted", x); 
	}

	//! Enable/Disable glowing or remove it
	public void m_bSetGlow(bool x)
	{
		#define FL_ZERO	0.0
		#define FL_INFINITE 9999.0
		SetEntPropFloat(this.Index, Prop_Send, "m_flDetectedByEnemySensorTime", x ? (GetGameTime() + FL_INFINITE) : FL_ZERO);
	}

	//! Check drowning variable
	public bool m_bDrown(int x)
	{
		return GetEntProp(this.Index, Prop_Data, "m_nWaterLevel") > x;
	}

	//! Check menu open
	public bool m_bMenuEmpty()
	{
		return GetClientMenu(this.Index, INVALID_HANDLE) == MenuSource_None;
	}

	//! Give weapon
	public void CItemMaterialize(char[] weapon)
	{
		if(strlen(weapon))
		{
			GivePlayerItem(this.Index, weapon);
			FakeClientCommandEx(this.Index, "use %s", weapon);
		}
	}

	//! Remove all weapons and give default weapon
	public void CItemRemoveAll(char[] weapon)
	{
		int size = GetEntPropArraySize(this.Index, Prop_Send, "m_hMyWeapons");
		
		for (int i = 0; i < size; i++)
		{
			int index = GetEntPropEnt(this.Index, Prop_Send, "m_hMyWeapons", i);

			if(IsValidEdict(index))
			{
				RemovePlayerItem(this.Index, index);
				AcceptEntityInput(index, "Kill");
			}
		}
		
		GivePlayerItem(this.Index, weapon);
		FakeClientCommandEx(this.Index, "use %s", weapon);
	}

	//! Emit random sound depend on the key
	public void InputEmitAISound(int channel, int level, char[] key)
	{
		static char sound[PLATFORM_MAX_PATH];
		SoundsGetSound(sound, sizeof(sound), key);
		
		if(strlen(sound)) 
		{
			Format(sound, sizeof(sound), "*/%s", sound);
			EmitSoundToAll(sound, this.Index, channel, level);
		}
	}

	//! Set player model and arm model
	public void m_ModelName(char[] model = "", char[] arm = "")
	{
		if(strlen(model)) if(IsModelPrecached(model)) SetEntityModel(this.Index, model);
		if(strlen(arm)) if(IsModelPrecached(arm)) SetEntPropString(this.Index, Prop_Send, "m_szArmsModel", arm);
	}
}