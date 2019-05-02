/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *  File:          paramparser.cpp
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
 *  Copyright (C) 2015-2019  Nikita Ushakov (Ireland, Dublin)
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
char sParamError[7][PLATFORM_LINE_LENGTH] = {
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

    // Cut out comments at the end of a line
    if(StrContains(sParamString, "//", false) != -1)
    {
        SplitString(sParamString, "//", sParamString, iMaxLen);
    } 
     
    // Trim string
    TrimString(sParamString);

    // Gets string length
    int iLen = strlen(sParamString);
    
    // Check if string is empty
    if(!iLen)
    {
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_EMPTY]);
        return PARAM_ERROR_EMPTY;
    }

    // Check if there space left in the destination buffer
    if(iMaxLen > PLATFORM_LINE_LENGTH || iLen > PLATFORM_LINE_LENGTH)
    {
        // Exit loop. No more parameters can be parsed
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_FULL]);
        return PARAM_ERROR_FULL;
    }
    
    /*__________________________________________________________________________*/

    // Initialize char array
    static char sValue[SMALL_LINE_LENGTH][PLATFORM_LINE_LENGTH];

    // Position of separator character
    int iSeparatorPos = FindCharInString(sParamString, cSeparator, false);

    // Parse error
    if(iSeparatorPos == -1)
    {
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_SEPARATOR]);
        return PARAM_ERROR_MISSING_SEPARATOR;
    }

    /*__________________________________________________________________________*/
    
    // Extract key name
    StrExtract(sValue[0], sParamString, 0, iSeparatorPos);

    // Trim string
    TrimString(sValue[0]);
    
    // Strips a quote pair off a string 
    StripQuotes(sValue[0]);
    
    // Check if string is empty, then stop
    if(!hasLength(sValue[0]))
    {
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_UNEXPECTED_KEY]);
        return PARAM_ERROR_UNEXPECTED_KEY;
    }

    // Push key name into array
    arrayBuffer.PushString(sValue[0]);

    /*__________________________________________________________________________*/

    // Extract value string
    StrExtract(sParamString, sParamString, iSeparatorPos + 1, iLen);

    // Trim string
    TrimString(sParamString);
    
    // Check if string is empty, then stop
    if(!hasLength(sParamString))
    {
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_UNEXPECTED_END]);
        return PARAM_ERROR_UNEXPECTED_END;
    }

    // Checks if string has incorrect quotes
    int iQuotes = CountCharInString(sParamString, '"');
    if(iQuotes & 1) /// Is odd ?
    {
        strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_QUOTES]);
        return PARAM_ERROR_MISSING_QUOTES;
    }

    // Only for one "value"
    if(iQuotes == 2)
    {
        // Strips a quote pair off a string 
        StripQuotes(sParamString);

        // Push value string into array
        arrayBuffer.PushString(sParamString);
    }
    else
    {
        // Breaks a string into pieces and stores each piece into an array of buffers
        int iAmount = ExplodeString(sParamString, ",", sValue, sizeof(sValue), sizeof(sValue[]));
        
        // i = value index
        for(int i = 0; i < iAmount; i++)
        {
            // Trim string
            TrimString(sValue[i]);
            
            // Checks if string has incorrect quotes
            iQuotes = CountCharInString(sValue[i], '"');
            if(iQuotes & 1) /// Is odd ?
            {
                strcopy(sParamString, iMaxLen, sParamError[PARAM_ERROR_MISSING_QUOTES]);
                return PARAM_ERROR_MISSING_QUOTES;
            }
            
            // Strips a quote pair off a string 
            StripQuotes(sValue[i]);

            // Push value string into array
            arrayBuffer.PushString(sValue[i]);
        }
    }


    // Return on success
    return PARAM_ERROR_NO;
}

/**************************************
 *                                    *
 *         HELPER FUNCTIONS           *
 *                                    *
 **************************************/
 
/**
 * @brief Extracts a area in a string between two positions.
 *
 * @param sBuffer           Destination string buffer.
 * @param sSource           Source string to extract from.
 * @param startPos          Start position of string to extract.
 * @param endPos            End position of string to extract.
 * @return                  The number of cells written.
 **/
int StrExtract(char[] sBuffer, char[] sSource, int startPos, int endPos)
{
    // Calculate string length. Also add space for null terminator
    int iMaxLen = endPos - startPos + 1;
    
    // Validate length
    if(iMaxLen < 0)
    {
        sBuffer[0] = '\0';
        return 0;
    }
    
    // Extract string and store it in the buffer
    return strcopy(sBuffer, iMaxLen, sSource[startPos]);
}

/**
 * @brief Checks whether a substring is found inside another string.
 * @param sBuffer           The substring to find inside the original string.
 * @param sSource           The string to search in. 
 * @param cSeparator        The separator character.
 * @return                  True or false.
 **/
bool StrContain(char[] sBuffer, char[] sSource, char cSeparator)
{
    // i = char index
    int iLen1 = strlen(sSource); int iLen2 = strlen(sBuffer); int x; int y;
    for(int i = 0; i < iLen1; i++) 
    {
        // Validate char
        if(sSource[i] == sBuffer[x])
        {
            if(++x == iLen2) /// Check length 
            {
                // Validate delimitter
                y = i + 1;
                if(y >= iLen1 || (sSource[y] == cSeparator || sSource[y] == ' '))
                {
                    return true;
                }
            }
            else if(x == 1) /// Check first comparator
            {
                // Validate prefix
                y = i - 1;
                if(y != -1 && (sSource[y] != cSeparator && sSource[y] != ' '))
                {
                    x = 0; /// Reset counter
                }
            }
        }
        else 
        {
            x = 0; /// Reset counter
        }
    }
    
    // Return on unsuccess
    return false;
}

/**
 * @brief Finds the amount of all occurrences of a character in a string.
 *
 * @param sBuffer           Input string buffer.
 * @param cSymbol           The character to search for.
 * @return                  The amount of characters in the string, or -1 if the characters were not found.
 */
int CountCharInString(char[] sBuffer, char cSymbol)
{
    // Initialize index
    int iCount;
    
    // i = char index
    int iLen = strlen(sBuffer);
    for(int i = 0; i < iLen; i++) 
    {
        // Validate char
        if (sBuffer[i] == cSymbol)
        {
            // Increment amount
            iCount++;
        }
    }

    // Return amount
    return iCount ? iCount : -1;
}

/**
 * @brief Converts uppercase chars in the string to lowercase chars.
 *
 * @param sBuffer           Input string buffer.
 */
void StringToLower(char[] sBuffer)
{
    // i = char index
    int iLen = strlen(sBuffer);
    for(int i = 0; i < iLen; i++) 
    {
        // Character to convert
        sBuffer[i] = CharToLower(sBuffer[i]);
    }
}