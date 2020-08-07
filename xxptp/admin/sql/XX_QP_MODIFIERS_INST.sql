REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : OD C0225 Modifiers Conversion                                              |--
--|                                                                                             |--
--| Program Name   : XX_QP_MODIFIERS_INST.sql                                                   |--
--|                                                                                             |--
--| Purpose        : Inserting data into XX_COM_CONVERSIONS_CONV with batch_size, max_threads   |--
--|                  and conversion_code                                                        |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1a                18-May-2007      Abhradip Ghosh          Original                         |--
--+=============================================================================================+--

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Deleting data from XX_COM_CONVERSIONS_CONV where conversion_code = C0225_Modifiers
PROMPT

DELETE FROM XX_COM_CONVERSIONS_CONV XCCC
WHERE  XCCC.conversion_code = 'C0225_Modifiers';

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Inserting data into XX_COM_CONVERSIONS_CONV with conversion_code = C0225_Modifiers
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
                                   ,'C0225_Modifiers'
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

