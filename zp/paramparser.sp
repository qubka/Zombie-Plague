/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          paramparser.sp
 *  Type:          Core 
 *  Description:   Provides functions for parsing single line strings, 
 *                    and parameters in key="value" format.
 *
 *
 *                 Examle raw string:
 *                  key1 = "value1"
 *                  key2 = "value2", "value3"
 *                  key3 = "value4", "value5", "value6"
 *                  key4 = "value7"
 *
 *  Copyright (C) 2015-2023  qubka (Nikita Ushakov)
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
 * @section Parsing error codes.
 **/
#define PARAM_ERROR_NO                  -1  /** No errors. */
#define PARAM_ERROR_EMPTY               0   /** Source string is empty. */
#define PARAM_ERROR_UNEXPECTED_KEY      1   /** Unexpected key name. */
#define PARAM_ERROR_UNEXPECTED_END      2   /** Unexpected end of source string. */
#define PARAM_ERROR_MISSING_SEPARATOR   3   /** Could not find a separator sign after key name. */
#define PARAM_ERROR_MISSING_QUOTES      4   /** Could not find a quotes sign (") after key name. */
#define PARAM_ERROR_UNKNOWN             5   /** Unknown error. The parser got a invalid result from a search function it couldn't handle. */
#define PARAM_ERROR_FULL                6   /** Destination array is full. */
/**
 * @endsection
 **/
 
/**
 * Errors description for a codes.
 **/
char sParamError[7][] = {
	/*"No errors",*/
	"Source string is empty",
	"Unexpected key name",
	"Unexpected end of source string",
	"Could not find a separator sign after key name",
	"Could not find a quotes sign (\") after key name",
	"Unknown error. The parser got a invalid result from a search function it couldn't handle",
	"Destination array is full"
};

/**************************************
 *                                    *
 *       PARAMETER FUNCTIONS          *
 *                                    *
 **************************************/

/**
 * @brief Parses a parameter string in key = "value" format and store the result in a ParamParseResult array.
 *
 * @param arrayBuffer       Handle of the buffer array containing value data.
 * @param sParamString      The source string to parse. Error message output.
 * @param iMaxLen           Maximum number of keys that can be stored (first dimension of buffer).
 * @param cSeparator        The separator character.
 * @return                  Returns error code if parsing error.
 **/
int ParamParseString(ArrayList &arrayBuffer, char[] sParamString, int iMaxLen, char cSeparator)
{
	/*
	 *  VALIDATION OF INPUT AND BUFFERS
	 */

	SplitString(sParamString, "//", sParamString, iMaxLen);
	 
	TrimString(sParamString);

	int iLen = strlen(sParamString);
	
	if (!iLen)
	{
		strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_EMPTY]);
		return PARAM_ERROR_EMPTY;
	}

	if (iMaxLen > PLATFORM_LINE_LENGTH || iLen > PLATFORM_LINE_LENGTH)
	{
		strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_FULL]);
		return PARAM_ERROR_FULL;
	}
	
	/*__________________________________________________________________________*/

	static char sValue[SMALL_LINE_LENGTH][PLATFORM_LINE_LENGTH];

	int iSeparatorPos = FindCharInString(sParamString, cSeparator, false);

	if (iSeparatorPos == -1)
	{
		strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_SEPARATOR]);
		return PARAM_ERROR_MISSING_SEPARATOR;
	}

	/*__________________________________________________________________________*/
	
	ExtractString(sValue[0], sParamString, 0, iSeparatorPos);

	TrimString(sValue[0]);
	
	StripQuotes(sValue[0]);
	
	if (!hasLength(sValue[0]))
	{
		strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_UNEXPECTED_KEY]);
		return PARAM_ERROR_UNEXPECTED_KEY;
	}

	arrayBuffer.PushString(sValue[0]);

	/*__________________________________________________________________________*/

	ExtractString(sParamString, sParamString, iSeparatorPos + 1, iLen);

	TrimString(sParamString);
	
	if (!hasLength(sParamString))
	{
		strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_UNEXPECTED_END]);
		return PARAM_ERROR_UNEXPECTED_END;
	}

	int iQuotes = CountCharInString(sParamString, '"');
	if (iQuotes & 1) /// Is odd ?
	{
		strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_QUOTES]);
		return PARAM_ERROR_MISSING_QUOTES;
	}

	if (iQuotes == 2)
	{
		StripQuotes(sParamString);

		arrayBuffer.PushString(sParamString);
	}
	else
	{
		int iAmount = ExplodeString(sParamString, ",", sValue, sizeof(sValue), sizeof(sValue[]));
		
		for (int i = 0; i < iAmount; i++)
		{
			TrimString(sValue[i]);
			
			iQuotes = CountCharInString(sValue[i], '"');
			if (iQuotes & 1) /// Is odd ?
			{
				strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_QUOTES]);
				return PARAM_ERROR_MISSING_QUOTES;
			}
			
			StripQuotes(sValue[i]);

			arrayBuffer.PushString(sValue[i]);
		}
	}


	return PARAM_ERROR_NO;
}