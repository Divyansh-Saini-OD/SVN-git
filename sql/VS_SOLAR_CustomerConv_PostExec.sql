REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : SOLAR Customer Assignments Conversion                                      |--
--|                                                                                             |--
--| Program Name   : Postvalidation Scripts                                                     |--
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
PROMPT Script - Total Number of Customer Assignments in Oracle
PROMPT

SELECT count(hps.party_site_id)
FROM   hz_parties      HP,
       hz_party_sites  HPS
WHERE  HPS.ORIG_SYSTEM_REFERENCE IN 
               ( SELECT  XCSS.cust_id || '-' || XCSS.shipto_num || '-A0' 
                 FROM   XXCNV.xx_cdh_solar_siteimage XCSS 
                       ,XXTPS.xxtps_sp_mapping       XSM 
                 WHERE  XCSS.site_type =('SHIPTO') 
                 AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
                 AND    XSM.sp_id_orig IS NOT NULL 
                 AND    XCSS.status = 'ACTIVE' 
                 AND    EXISTS   (SELECT 1
                                  FROM   fnd_lookup_values FLV
                                  WHERE  FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                                  AND    FLV.enabled_flag = 'Y'
                                  AND    FLV.language     = 'US'
                                  AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
                                  AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1)
                                         AND NVL(FLV.end_date_active,SYSDATE + 1)
                                 )
                 AND    EXISTS   (SELECT 1 
                                  FROM   apps.xx_cdh_solar_conversion_group XCSCG 
                                  WHERE  XCSCG.validate_status = 'OK' 
                                  AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                                  AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                                          AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                                        ) 
                                 )
              ) 
and HPS.party_id = HP.party_id
and HP.attribute13 ='CUSTOMER';


PROMPT
PROMPT Script - Total number of Customer Assignments failed due to Inactive Reps
PROMPT

SELECT count(XCSS.cust_id || '-' || XCSS.shipto_num || '-A0' )
FROM   XXCNV.xx_cdh_solar_siteimage  XCSS 
      ,XXTPS.xxtps_sp_mapping        XSM 
WHERE  XCSS.site_type =('SHIPTO') 
AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
AND    XCSS.status = 'ACTIVE' 
AND    EXISTS   (SELECT 1
                 FROM   fnd_lookup_values FLV
                 WHERE  FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                 AND    FLV.enabled_flag = 'Y'
                 AND    FLV.language     = 'US'
                 AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
                 AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1)
                        AND NVL(FLV.end_date_active,SYSDATE + 1)
                )
AND    EXISTS   (SELECT 1 
                 FROM   apps.xx_cdh_solar_conversion_group XCSCG 
                 WHERE  XCSCG.validate_status <> 'OK' 
                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                 AND    (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                        ) 
                );


PROMPT
PROMPT Script - Total Number of Customer Assignments failed due to Rep mapping not there in XXTPS table
PROMPT

SELECT  count(HPS.party_site_id)
FROM    hz_parties      HP,
        hz_party_sites  HPS
WHERE   HPS.ORIG_SYSTEM_REFERENCE in 
               ( SELECT  XCSS.cust_id || '-' || XCSS.shipto_num || '-A0' 
                 FROM   XXCNV.xx_cdh_solar_siteimage XCSS 
                       ,XXTPS.xxtps_sp_mapping       XSM 
                 WHERE  XCSS.site_type =('SHIPTO') 
                 AND    XCSS.conversion_rep_id = XSM.sp_id_orig(+) 
                 AND    XSM.sp_id_orig is NULL 
                 AND    XCSS.status = 'ACTIVE' 
                 AND    EXISTS   (SELECT 1
                                  FROM   fnd_lookup_values FLV
                                  WHERE  FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                                  AND    FLV.enabled_flag = 'Y'
                                  AND    FLV.language     = 'US'
                                  AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
                                  AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1)
                                         AND NVL(FLV.end_date_active,SYSDATE + 1)
                                )
                 AND    EXISTS  (SELECT 1 
                                 FROM   apps.xx_cdh_solar_conversion_group XCSCG 
                                 WHERE  XCSCG.validate_status = 'OK' 
                                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                                 AND   (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                                        AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                                       ) 
                                )
               ) 
AND  HPS.party_id = HP.party_id
AND  HP.attribute13 = 'CUSTOMER';


PROMPT
PROMPT Script - Total number of Customer Assignments failed due to Resource not found in Resource Manager
PROMPT

SELECT  count(XCSS.cust_id || '-' || XCSS.shipto_num || '-A0' )
FROM    XXCNV.xx_cdh_solar_siteimage  XCSS 
       ,XXTPS.xxtps_sp_mapping        XSM 
WHERE  XCSS.site_type =('SHIPTO') 
AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
AND    XSM.sp_id_orig IS NOT NULL 
AND    XCSS.status = 'ACTIVE' 
AND    EXISTS   (SELECT 1
                 FROM   fnd_lookup_values FLV
                 WHERE  FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                 AND    FLV.enabled_flag = 'Y'
                 AND    FLV.language     = 'US'
                 AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
                 AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1)
                 AND NVL(FLV.end_date_active,SYSDATE + 1)
                )
AND    EXISTS   (SELECT 1 
                 FROM   apps.xx_cdh_solar_conversion_group XCSCG 
                 WHERE  XCSCG.validate_status = 'OK' 
                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                 AND    (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                        ) 
                )
AND   NOT EXISTS (SELECT 1
                  FROM   apps.jtf_rs_roles_b  JRRB,
                         apps.jtf_rs_role_relations JRRR,
                         apps.jtf_rs_resource_extns JRRE,
                         apps.xxtps_sp_mapping      TPS
                  WHERE  TPS.sp_id_orig  = XCSS.rep_id
                  AND    JRRR.attribute15    = TPS.sp_id_new
                  AND    JRRB.role_id        = JRRR.role_id
                  AND    JRRE.resource_id    = JRRR.role_resource_id);


PROMPT
PROMPT Script - Total Number of Customer  Assignments for each Reps under particular RSD in Oracle
PROMPT

SELECT  count(XCSS.cust_id || '-' || XCSS.shipto_num || '-A0' )
FROM    XXCNV.xx_cdh_solar_siteimage  XCSS 
       ,XXTPS.xxtps_sp_mapping        XSM 
WHERE   XCSS.site_type =('SHIPTO') 
AND     XCSS.conversion_rep_id = XSM.sp_id_orig 
AND     XSM.sp_id_orig IS NOT NULL 
AND     XCSS.status = 'ACTIVE' 
AND     EXISTS   (SELECT 1
                  FROM   fnd_lookup_values FLV
                  WHERE  FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                  AND    FLV.enabled_flag = 'Y'
                  AND    FLV.language     = 'US'
                  AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
                  AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1)
                          AND NVL(FLV.end_date_active,SYSDATE + 1)
                 )
AND    EXISTS   (SELECT 1 
                 FROM   apps.xx_cdh_solar_conversion_group XCSCG 
                 WHERE  XCSCG.conversion_group_id = :CONVERSIONGROUPID
                 AND    XCSCG.validate_status = 'OK' 
                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                 AND    (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                        ) 
                );


PROMPT
PROMPT Script - Total Number of Customer Assignments to Admin for this RSD
PROMPT

SELECT  count(XCSS.cust_id || '-' || XCSS.shipto_num || '-A0' )
FROM    XXCNV.xx_cdh_solar_siteimage  XCSS 
       ,XXTPS.xxtps_sp_mapping        XSM 
WHERE   XCSS.site_type =('SHIPTO') 
AND     XCSS.conversion_rep_id = XSM.sp_id_orig 
AND     XSM.sp_id_orig IS NOT NULL 
AND     XCSS.status = 'ACTIVE' 
AND     XSM.sp_id_new  =  'CLEANUP'
AND     EXISTS   (SELECT 1
                  FROM   fnd_lookup_values FLV
                  WHERE  FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                  AND    FLV.enabled_flag = 'Y'
                  AND    FLV.language     = 'US'
                  AND    FLV.lookup_code  = UPPER(XCSS.rev_band)
                  AND    SYSDATE BETWEEN NVL(FLV.start_date_active,SYSDATE - 1)
                         AND NVL(FLV.end_date_active,SYSDATE + 1)
                )
AND    EXISTS   (SELECT 1 
                 FROM   apps.xx_cdh_solar_conversion_group XCSCG 
                 WHERE  XCSCG.conversion_group_id = :CONVERSIONGROUPID
                 AND    XCSCG.validate_status = 'OK' 
                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                 AND    (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                        ) 
               );



PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
