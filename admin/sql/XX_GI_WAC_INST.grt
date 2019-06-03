REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--| Object Name    : OD C0272 Item Cross Reference                                   |--
--|                                                                                  |--
--| Program Name   : XX_GI_WAC_INST.grt                                              |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into XX_COM_CONVERSIONS_CONV with batch_size and |--
--|                  and conversion_code                                             |--  
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              03-Aug-2007      Abhradip Ghosh           Original              |--
--| 1.1              03-Aug-2007      Parvez Siddiqui          TL Review             |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE
             
PROMPT          
PROMPT Deleting data from XX_COM_CONVERSIONS_CONV where conversion_code = C0052_WAC
PROMPT          

DELETE FROM XX_COM_CONVERSIONS_CONV XCCC
WHERE  XCCC.conversion_code = 'C0052_WAC';

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Inserting data into XX_COM_CONVERSIONS_CONV with conversion_code = C0052_WAC
PROMPT
DECLARE
BEGIN
XX_COM_CONV_ELEMENTS_PKG.insert_conversion_info(
                                                p_conversion_code      => 'C0052_WAC'
                                                ,p_batch_size          => 5000
                                                ,p_exception_threshold => Null
                                                ,p_max_threads         => 10
                                                ,p_extract_or_load     => 'L'
                                                ,p_system_code         => Null
                                               );
END;
/

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================


