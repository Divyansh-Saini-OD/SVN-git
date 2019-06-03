REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+==================================================================================+
--|                                                                                  |--
--|                                                                                  |--
--| Program Name   : XX_GSO_PO_INST.grt                                              |--        
--|                                                                                  |--   
--| Purpose        : Inserting data into XX_GSO_PO_STG,XX_GSO_PO_HDR,XX_GSO_PO_DTL   |--
--|                  and conversion_code                                             |--  
--|                                                                                  |-- 
--| Change History  :                                                                |--
--| Version           Date             Changed By              Description           |--
--+==================================================================================+
--| 1.0              03-Mar-2011       Paddy Sanjeevi          Original              |--
--+==================================================================================+

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
             
WHENEVER SQLERROR CONTINUE
             
DELETE FROM apps.xx_gso_po_stg;

DELETE FROM apps.xx_gso_po_hdr;

DELETE FROM apps.xx_gso_po_dtl;

commit;

