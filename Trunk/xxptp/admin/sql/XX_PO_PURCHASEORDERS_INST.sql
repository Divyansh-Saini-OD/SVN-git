REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : OD C0106 Purchase Orders                                                   |--
--|                                                                                             |--
--| Program Name   : XX_PO_PURCHASEORDERS_INST.sql                                              |--        
--|                                                                                             |--   
--| Purpose        : Inserting data into XX_COM_CONVERSIONS_CONV with batch_size and            |--
--|                  and conversion_code                                                        |--  
--|                                                                                             |-- 
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0               26-Jun-2007      Ritu Shukla             Original                         |--
--+=============================================================================================+-- 

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE
             
PROMPT          
PROMPT Deleting data from XX_COM_CONVERSIONS_CONV where conversion_code = C0106_PurchaseOrders
PROMPT          

DELETE FROM XX_COM_CONVERSIONS_CONV XCCC
WHERE  XCCC.conversion_code = 'C0106_PurchaseOrders';

WHENEVER SQLERROR CONTINUE

PROMPT
PROMPT Inserting data into XX_COM_CONVERSIONS_CONV with conversion_code = C0106_PurchaseOrders
PROMPT

XX_COM_CONV_ELEMENTS_PKG.insert_conversion_info(
                                                 p_conversion_code     => 'C0106_PurchaseOrders'
                                                ,p_batch_size          =>  5000
                                                ,p_exception_threshold =>  NULL
                                                ,p_max_threads         =>  10
                                                ,p_extract_or_load     => 'L'
                                                ,p_system_code         =>  NULL
                                               );

WHENEVER SQLERROR CONTINUE;

PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON

EXIT;

REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================


