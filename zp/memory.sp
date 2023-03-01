/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          memory.sp
 *  Type:          Core
 *  Description:   Allocation/deallocation management.
 *
 *  Copyright (C) 2015-2023 qubka (Nikita Ushakov)
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
 * Maximum length of memory entry.
 **/
#define MEMORYPOOL_NAME_MAX 124

/**
 * Variables to store SDK calls handlers.
 **/
Handle hMalloc;
Handle hFree;
Handle hCreateInterface;

/**
 * Variables to store virtual SDK adresses.
 **/
Address g_pMemAlloc;

/**
 * Handles for storing memoty allocations.
 **/
ArrayList gMemoryPool;

/**
 * @section Struct of memory entry.
 **/
enum struct MemoryPoolEntry
{
	Address addr;
	char name[MEMORYPOOL_NAME_MAX];
}
/**
 * @endsection
 **/
 
/**
 * @brief Memory module init function.
 **/
void MemoryOnInit()
{
	{
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "CreateInterface");

		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
		
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		if ((hCreateInterface = EndPrepSDKCall()) == null)
		{
			LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Memory, "GameData Validation", "Failed to load SDK call \"CreateInterface\". Update signature in \"%s\"", PLUGIN_CONFIG);
		}
	}
	
	if (gServerData.Platform != OS_Windows)
	{
		return; // we not use on on linux yet 
	}

	gMemoryPool = new ArrayList(sizeof(MemoryPoolEntry));
	
	fnInitGameConfAddress(gServerData.Config, g_pMemAlloc, "g_pMemAlloc");

	if (gServerData.Engine == Engine_CSS && gServerData.Platform == OS_Linux)
	{
		{
			StartPrepSDKCall(SDKCall_Static);
			PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "Malloc");
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

			if ((hMalloc = EndPrepSDKCall()) == null)
			{
				LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Memory, "GameData Validation", "Failed to load SDK call \"Malloc\". Update signature in \"%s\"", PLUGIN_CONFIG);
			}
		}
		
		/*__________________________________________________________________________________________________*/
		
		{
			StartPrepSDKCall(SDKCall_Static);
			PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Signature, "Free");
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			
			if ((hFree = EndPrepSDKCall()) == null)
			{
				LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Memory, "GameData Validation", "Failed to load SDK call \"Free\". Update signature in \"%s\"", PLUGIN_CONFIG);
			}
		}
	}
	else
	{
		{
			StartPrepSDKCall(SDKCall_Raw);
			PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "Malloc");
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

			if ((hMalloc = EndPrepSDKCall()) == null)
			{
				LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Memory, "GameData Validation", "Failed to load SDK call \"Malloc\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
			}
		}
		
		/*__________________________________________________________________________________________________*/
		
		{
			StartPrepSDKCall(SDKCall_Raw);
			PrepSDKCall_SetFromConf(gServerData.Config, SDKConf_Virtual, "Free");
			
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			
			if ((hFree = EndPrepSDKCall()) == null)
			{
				LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Memory, "GameData Validation", "Failed to load SDK call \"Free\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
			}
		}
	}
}

/**
 * @brief Memory module unload function.
 **/
void MemoryOnUnload()
{
	MemoryCleanUpPool();
}

/**
 * @brief Creates commands for memory module.
 **/
void MemoryOnCommandInit()
{
	RegAdminCmd("zp_memory_dump", MemoryOnCommandCatched, ADMFLAG_ROOT, "Dumps active memory pool. Mainly for debugging.");
}

/**
 * Console command callback (zp_memory_dump)
 * @brief Dumps active memory pool.
 * 
 * @param client            The client index.
 * @param iArguments        The number of arguments that were in the argument string.
 **/ 
public Action MemoryOnCommandCatched(int client, int iArguments)
{
	SetGlobalTransTarget(!client ? LANG_SERVER : client);

	if (gMemoryPool == null || gMemoryPool.Length == 0)
	{
		TranslationReplyToCommand(client, "memory pool invalid");
		return Plugin_Handled;
	}
	
	MemoryPoolEntry entry;
	
	int iSize = gMemoryPool.Length;
	TranslationReplyToCommand(client, "memory pool size", iSize);
	for (int i = 0; i < iSize; i++)
	{
		gMemoryPool.GetArray(i, entry, sizeof(MemoryPoolEntry));
		ReplyToCommand(client, "[%i]: 0x%08X \"%s\"", i, entry.addr, entry.name);
	}
	
	return Plugin_Handled;
}

/**
 * @brief Cleans up memory pool and free all allocated memory.
 **/ 
stock void MemoryCleanUpPool()
{
	if (gMemoryPool == null)
	{
		return;
	}
	
	MemoryPoolEntry entry;
	
	int iSize = gMemoryPool.Length;
	for (int i = 0; i < iSize; i++)
	{
		gMemoryPool.GetArray(i, entry, sizeof(MemoryPoolEntry));
		Free(entry.addr);
	}
	
	delete gMemoryPool;
}

/**
 * @brief Adds already allocated memory to the pool.
 *
 * @param pAddress          The pointer to allocated memory. 
 * @param sName             The memory block name. 
 **/ 
stock void MemoryAddToPool(Address pAddress, const char[] sName)
{
	//ASSERT(pAddress != Address_Null);
	//ASSERT(gMemoryPool);
	
	MemoryPoolEntry entry;
	strcopy(entry.name, sizeof(MemoryPoolEntry::name), sName);
	entry.addr = pAddress;
	
	gMemoryPool.PushArray(entry);
}

/**
 * @brief Allocates the requested memory and returns a pointer to it.
 *
 * @param iSize             This is the size of the memory block, in bytes. 
 * @param sName             The memory block name. 
 *
 * @return                  The pointer to allocated memory.
 **/ 
stock Address Malloc(int iSize, const char[] sName)
{
	//ASSERT(gMemoryPool);
	//ASSERT(iSize > 0);
	
	MemoryPoolEntry entry;
	
	strcopy(entry.name, sizeof(MemoryPoolEntry::name), sName);
	
	if (gServerData.Engine == Engine_CSS && gServerData.Platform == OS_Linux)
	{
		entry.addr = SDKCall(hMalloc, 0, iSize);
	}
	else
	{
		entry.addr = SDKCall(hMalloc, g_pMemAlloc, iSize);
	}
	
	if (entry.addr == Address_Null)
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Memory, "Memory Allocation", "Failed to allocate memory (size: %i)!", iSize);
	}

	gMemoryPool.PushArray(entry);
	
	return entry.addr;
}

/**
 * @brief Deallocates the memory previously allocated by a call to calloc, malloc, or realloc.
 *
 * @param pAddress          The pointer to memory, which should be free.
 **/ 
stock void Free(Address pAddress)
{
	//ASSERT(pAddress != Address_Null);
	//ASSERT(gMemoryPool);
	
	int iD = gMemoryPool.FindValue(pAddress, MemoryPoolEntry::addr);
	if (iD == -1)
	{
		return; /// Memory wasn't allocated yet, return
	}
	
	gMemoryPool.Erase(iD);
	
	if (gServerData.Engine == Engine_CSS && gServerData.Platform == OS_Linux)
	{
		SDKCall(hFree, 0, pAddress);
	}
	else
	{
		SDKCall(hFree, g_pMemAlloc, pAddress);
	}
}

/**
 * @brief This is the primary exported function by a dll, referenced by name via dynamic binding
 *        that exposes an opqaue function pointer to the interface.
 *
 * @param gameConf          The game config handle.
 * @param sKey              Key to retrieve from the key section.
 * @param pAddress          (Optional) The optional interface address.
 **/
stock Address CreateInterface(GameData gameConf, char[] sKey, Address pAddress = Address_Null) 
{
	static char sInterface[NORMAL_LINE_LENGTH];
	fnInitGameConfKey(gameConf, sKey, sInterface, sizeof(sInterface));

	Address pInterface = SDKCall(hCreateInterface, sInterface, pAddress);
	if (pInterface == Address_Null) 
	{
		LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Memory, "GameData Validation", "Failed to get pointer to interface %s(\"%s\")", sKey, sInterface);
		return Address_Null;
	}
	
	return pInterface;
}

/*
 * Memory stocks API.
 */

/**
 * @brief Copies the values of num bytes from the location pointed to by source directly to the memory block pointed to by destination.
 *
 * @param pDest        The destination address where the content is to be copied.
 * @param sSource      The source of data to be copied.
 * @param iSize        The number of bytes to copy.
 **/
stock void memcpy(Address pDest, const char[] sSource, int iSize)
{
	int i = iSize / 4;
	memcpy4b(pDest, view_as<any>(sSource), i);
   
	for (i *= 4, pDest += view_as<Address>(i); i < iSize; i++)
	{
		StoreToAddress(pDest++, sSource[i], NumberType_Int8);
	}
}

/**
 * @brief Copies the 4 bytes from the location pointed to by source directly to the memory block pointed to by destination. 
 *
 * @param pDest        The destination address where the content is to be copied.
 * @param sSource      The source of data to be copied.
 * @param iSize        The number of bytes to copy.
 **/
stock void memcpy4b(Address pDest, const any[] sSource, int iSize)
{
	for (int i = 0; i < iSize; i++)
	{
		StoreToAddress(pDest, sSource[i], NumberType_Int32);
		pDest += view_as<Address>(4);
	}
}

/**
 * @brief Writes the DWord D (i.e. 4 bytes) to the string. 
 *
 * @param asm             The assemly string.
 * @param pAddress        The address of the call.
 * @param iOffset         (Optional) The address offset. (Where 0x0 starts)
 **/
stock void writeDWORD(const char[] asm, any pAddress, int iOffset = 0)
{
	asm[iOffset]   = pAddress & 0xFF;
	asm[iOffset+1] = pAddress >> 8 & 0xFF;
	asm[iOffset+2] = pAddress >> 16 & 0xFF;
	asm[iOffset+3] = pAddress >> 24 & 0xFF;
}