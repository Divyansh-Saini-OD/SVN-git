REM============================================================================================
REM                                 Start Of Script
REM============================================================================================
--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : OD  C0303_ASN                                                              |--
--|                                                                                             |--
--| Program Name   : XX_PO_ASN_INST.grt                                                         |--
--|                                                                                             |--
--| Purpose        : To insert conversion details into XX_COM_CONVERSIONS_CONV .                |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                  1.Insert Statement for the table XX_COM_CONVERSIONS_CONV                   |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              31-May-2007       Gowri Nagarajan         Original                         |--
--| 1.1              12-Jul-2007       Gowri Nagarajan         Calling Common API for insert    |--
--+=============================================================================================+--

SET VERIFY      OFF
SET TERM        ON
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

PROMPT
PROMPT Deleting data from XX_COM_CONVERSIONS_CONV where conversion_code = C0303_ASN
PROMPT

DELETE FROM XX_COM_CONVERSIONS_CONV
WHERE  CONVERSION_CODE = 'C0303_ASN';

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Inserting data into XX_COM_CONVERSIONS_CONV with conversion_code = C0303_ASN
PROMPT

DECLARE
BEGIN
XX_COM_CONV_ELEMENTS_PKG.insert_conversion_info(
                                                 p_conversion_code     => 'C0303_ASN'
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

