REM============================================================================================
REM                                 Start Of Script
REM============================================================================================
--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : OD C0304, Organization Hierarchy data insertion into the table             |--
--|                                                                                             |--
--| Program Name   : XX_INV_ORGHIER_INST.sql                                                    |--
--|                                                                                             |--
--| Purpose        : To insert conversion details into XX_COM_CONVERSIONS_CONV .                |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                  1.Insert Statement for the table XX_COM_CONVERSIONS_CONV                   |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              05-May-2007      Chandan                  Original                         |--
--| 1.1              14-May-2007      Chandan U H              Changed from XXPTP to XXCNV      |--
--| 1.2              20-Jun-2007      Chandan U H              Calling Common API for insert    |--
--| 1.3              20-Jun-2007      Parvez Siddiqui          TL Review                        |--
--+=============================================================================================+--

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

SET TERM ON

PROMPT
PROMPT Deleting data from XX_COM_CONVERSIONS_CONV where conversion_code = C0304_OrgHierarchy
PROMPT

DELETE FROM XX_COM_CONVERSIONS_CONV
WHERE  CONVERSION_CODE = 'C0304_OrgHierarchy';

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Inserting data into XX_COM_CONVERSIONS_CONV with conversion_code = C0304_OrgHierarchy
PROMPT

DECLARE
BEGIN
XX_COM_CONV_ELEMENTS_PKG.insert_conversion_info(
                                                 p_conversion_code      => 'C0304_OrgHierarchy'
                                                ,p_batch_size          => 5000
                                                ,p_exception_threshold => Null
                                                ,p_max_threads         => 10
                                                ,p_extract_or_load     => 'L'
                                                ,p_system_code         => Null
                                               );
END;
/
WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================

