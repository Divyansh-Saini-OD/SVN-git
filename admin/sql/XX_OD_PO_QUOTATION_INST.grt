REM============================================================================================
REM                                 Start Of Script
REM============================================================================================
--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : C0301_PurchasePriceFromRMS data insertion into the table                   |--
--|                  XX_COM_CONVERSIONS_CONV .                                                  |--
--|                                                                                             |--
--| Program Name   : XXCOMCONV_POQTNINST.sql                                                    |--
--|                                                                                             |--
--| Purpose        : To insert conversion details into XX_COM_CONVERSIONS_CONV .                |--
--|                  The Objects created are:                                                   |--
--|                                                                                             |--
--|                  1.Insert Statement for the table XX_COM_CONVERSIONS_CONV                   |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              05-May-2007       Chandan                  baseline                        |--
--+=============================================================================================+--
SET VERIFY      OFF
SET TERM        OFF
SET FEEDBACK    OFF
SET SHOW        OFF
SET ECHO        OFF
SET TAB         OFF

SET TERM ON

PROMPT
PROMPT Deleting data from XX_COM_CONVERSIONS_CONV where conversion_code = C0301_PurchasePriceFromRMS
PROMPT

DELETE FROM XX_COM_CONVERSIONS_CONV
WHERE  CONVERSION_CODE = 'C0301_PurchasePriceFromRMS';

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Inserting data into XX_COM_CONVERSIONS_CONV with conversion_code = C0301_PurchasePriceFromRMS
PROMPT

INSERT INTO XX_COM_CONVERSIONS_CONV(
                                    CONVERSION_ID
                                   ,CONVERSION_CODE
                                   ,BATCH_SIZE
                                   ,MAX_THREADS
                                   ,EXTRACT_OR_LOAD
                                   )
                             VALUES(
                                    XX_COM_CONVERSIONS_CONV_S.nextval
                                   ,'C0301_PurchasePriceFromRMS'
                                   ,5000
                                   ,10
                                   ,'L'
                                   );
COMMIT;

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;
REM=================================================================================================
REM                                   End Of Script
REM=================================================================================================

