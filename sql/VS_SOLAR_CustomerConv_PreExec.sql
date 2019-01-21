REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : SOLAR Customer Assignments Conversion                                      |--
--|                                                                                             |--
--| Program Name   : Prevalidation Scripts                                                      |--
--|                                                                                             |--
--|                                                                                             |--
--| Change History  :                                                                           |--
--| Version           Date             Changed By              Description                      |--
--+=============================================================================================+--
--| 1.0              11-Jun-2008       Sathya Prabha Rani      Initial version                  |--
--+=============================================================================================+--

SET VERIFY   OFF
SET TERM     ON
SET FEEDBACK OFF
SET SHOW     OFF
SET ECHO     OFF
SET TAB      OFF
SET HEAD     OFF

PROMPT
PROMPT Script - Total Number of Customer Sites in SOLAR
PROMPT





PROMPT
PROMPT Script - Total Number of Customer Sites in SOLAR having matching Sites in CDH
PROMPT

SELECT count(HPS.party_site_id)
FROM    hz_parties      HP,
        hz_party_sites  HPS
WHERE  HPS.ORIG_SYSTEM_REFERENCE in 
               ( SELECT  XCSS.cust_id || '-' || XCSS.shipto_num || '-A0' 
                 FROM    XXCNV.xx_cdh_solar_siteimage XCSS 
                 WHERE   XCSS.site_type ='SHIPTO' 
                 AND     XCSS.status = 'ACTIVE' 
                 AND     EXISTS   (  SELECT 1 
                                     FROM   apps.xx_cdh_solar_conversion_group XCSCG 
                                     WHERE  XCSCG.validate_status = 'OK' 
                                     AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                                     AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                                              AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                                           ) 
                                   )
               ) 
AND HPS.party_id = HP.party_id
AND HP.attribute13 ='CUSTOMER';


PROMPT
PROMPT Script - Total Number of CustomerAssignments in SOLAR for the Customer Sites
PROMPT

SELECT count(XSM.sp_id_orig) 
FROM   XXCNV.xx_cdh_solar_siteimage  XCSS 
      ,XXTPS.xxtps_sp_mapping        XSM 
WHERE  XCSS.site_type =('SHIPTO') 
AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
AND    XSM.sp_id_orig is NOT NULL 
AND    XCSS.status = 'ACTIVE' ;


PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
