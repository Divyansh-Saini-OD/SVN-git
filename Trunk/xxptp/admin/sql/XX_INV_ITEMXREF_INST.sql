REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : OD C0272 Item Cross Reference                                              |--
--|                                                                                             |--
--| Program Name   : XX_INV_ITEMXREF_INST.sql                                                   |--        
--|                                                                                             |--   
--| Purpose        : Inserting data into XX_COM_CONVERSIONS_CONV with batch_size and            |--
--|                  and conversion_code                                                        |--  
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              08-May-2007      Abhradip Ghosh           Original                         |--
--| 1.1              14-May-2007      Abhradip Ghosh           Minor Changes                    |--
--| 1.2              20-Jun-2007      Abhradip Ghosh           Calling Common API for insert    |--
--| 1.3              20-Jun-2007      Parvez Siddiqui          TL Review                        |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE
             
PROMPT          
PROMPT Deleting data from XX_COM_CONVERSIONS_CONV where conversion_code = C0272_ItemXref
PROMPT          

DELETE FROM XX_COM_CONVERSIONS_CONV XCCC
WHERE  XCCC.conversion_code = 'C0272_ItemXref';

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Inserting data into XX_COM_CONVERSIONS_CONV with conversion_code = C0272_ItemXref
PROMPT
DECLARE
BEGIN
XX_COM_CONV_ELEMENTS_PKG.insert_conversion_info(
                                                p_conversion_code      => 'C0272_ItemXref'
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


