REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : SOLAR Conversion                                                           |--
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
PROMPT Script - CUSTOMER DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Customer in Oracle for this RSD
PROMPT


SELECT  COUNT(*)  
FROM    XXCNV.xx_cdh_solar_siteimage       XCSS,           
        XXCNV.xx_cdh_solar_state_country   X1,
        XXCNV.xx_cdh_solar_state_country   X2,           
        fnd_lookup_values                  FLV,
        apps.hz_parties                    HZP
WHERE   UPPER(XCSS.site_type) = 'SHIPTO'       
AND     XCSS.status = 'ACTIVE'       
AND      EXISTS (SELECT  1                     
                 FROM    apps.xx_cdh_solar_conversion_group XCSCG                    
                 WHERE   XCSCG.conversion_rep_id = XCSS.conversion_rep_id                      
                 AND     (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE)                                       
                 AND       NVL(XCSCG.end_date_active,SYSDATE + 1)))       
AND XCSS.state       = X1.STATE (+)       
AND XCSS.alt_state   = X2.STATE (+)       
AND FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'       
AND FLV.enabled_flag = 'Y'       
AND FLV.language     = 'US'       
AND FLV.lookup_code  = UPPER(XCSS.REV_BAND)       
AND SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1)
AND XCSS.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND HZP.orig_system_reference  = lpad(XCSS.internid,10,0) || '-00001-S0'
AND HZP.attribute13 = 'CUSTOMER';


PROMPT
PROMPT Script - Total Number of Reps in Oracle for this RSD
PROMPT

SELECT count(distinct jrre.resource_id)
FROM   apps.jtf_rs_roles_b        jrrb,
       apps.jtf_rs_role_relations jrrr,
       apps.jtf_rs_resource_extns jrre,
       apps.xxtps_sp_mapping      tps,
       xxcnv.xx_cdh_solar_siteimage a
WHERE  tps.sp_id_orig      = a.rep_id
AND    a.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND    jrrr.attribute15    = tps.sp_id_new
AND    jrrb.role_id        = jrrr.role_id
AND    jrre.resource_id    = jrrr.role_resource_id;



PROMPT
PROMPT Script - PROSPECT DETAILS
PROMPT



PROMPT
PROMPT Script - Total number of prospects in Oracle for the RSD
PROMPT


SELECT  COUNT(*)  
FROM    XXCNV.xx_cdh_solar_siteimage xcss ,           
        XXCNV.xx_cdh_solar_state_country X1 ,
        XXCNV.xx_cdh_solar_state_country X2 ,           
        FND_LOOKUP_VALUES FLV     ,
         apps.hz_parties hzp
WHERE   UPPER(xcss.SITE_TYPE) = 'SHIPTO'       
AND     xcss.STATUS = 'ACTIVE'       
AND     EXISTS (SELECT  1                     
                FROM   apps.xx_cdh_solar_conversion_group XCSCG                    
                WHERE  XCSCG.conversion_rep_id = XCSS.conversion_rep_id                      
                AND   (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE)                                       
                       AND NVL(XCSCG.end_date_active,SYSDATE + 1)))       
AND XCSS.STATE       = X1.STATE (+)       
AND XCSS.ALT_STATE   = X2.STATE (+)       
AND FLV.LOOKUP_TYPE  = 'XX_CRM_REV_BAND_TYPES'       
AND FLV.ENABLED_FLAG = 'Y'       
AND FLV.LANGUAGE     = 'US'       
AND FLV.LOOKUP_CODE  = UPPER(XCSS.REV_BAND)       
AND SYSDATE BETWEEN NVL( FLV.START_DATE_ACTIVE,SYSDATE - 1) AND NVL(FLV.END_DATE_ACTIVE,SYSDATE + 1)
AND XCSS.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND hzp.orig_system_reference  = lpad(xcss.internid,10,0) || '-00001-S0';


PROMPT
PROMPT Script - Total Number of prospects sites in Oracle for the RSD
PROMPT


SELECT  count(*)
FROM    apps.HZ_IMP_ADDRESSES_INT au,
        apps.HZ_ORIG_SYS_REFERENCES REF,
        apps.HZ_PARTY_SITES ps,
        apps.HZ_LOCATIONS loc,
        xxcnv.xx_cdh_solar_siteimage xcss
WHERE 
(au.site_orig_system_reference =lpad(xcss.internid,10,0) || '-00001-S0' OR au.site_orig_system_reference =lpad(xcss.internid,10,0) || '-00002-S0')
AND    xcss.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND    REF.owner_table_name = 'HZ_PARTY_SITES'
AND    au.site_orig_system_reference = REF.orig_system_reference
AND    ps.orig_system_reference = REF.orig_system_reference
AND    REF.owner_table_id = ps.party_site_id
AND    loc.location_id = ps.location_id;


PROMPT
PROMPT Script - Total number of Prospects Site uses in Oracle for the  RSD
PROMPT

SELECT  count(*)
FROM    apps.HZ_IMP_ADDRESSUSES_INT au,
        apps.HZ_ORIG_SYS_REFERENCES REF,
        apps.HZ_PARTY_SITES ps,
        apps.HZ_LOCATIONS loc,
         xxcnv.xx_cdh_solar_siteimage xcss
WHERE 
(au.site_orig_system_reference lpad(xcss.internid,10,0) || '-00001-S0' OR au.site_orig_system_reference lpad(xcss.internid,10,0) || '-00002-S0')
AND    xcss.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND    REF.owner_table_name = 'HZ_PARTY_SITES'
AND    au.site_orig_system_reference = REF.orig_system_reference
AND    ps.orig_system_reference = REF.orig_system_reference
AND    REF.owner_table_id = ps.party_site_id
AND    loc.location_id = ps.location_id;


PROMPT
PROMPT Script - Total Number of prospects Contact points in Oracle for the RSD
PROMPT


SELECT count(*)
FROM   hz_party_relationships hpr,
       hz_parties             hzp,
       hz_org_contacts        hoc,
       apps.xx_cdh_solar_contactimage xcsc,
       apps.xx_cdh_solar_siteimage xcss
WHERE  hpr.subject_id                   = hzp.party_id
AND    hpr.party_relationship_id        = hoc.party_relationship_id (+)
AND    hzp.orig_system_reference = lpad(xcsc.internid,10,'0') || '-00001-S0'
AND    (rtrim(xcsc.fname) is not null or rtrim(xcsc.lname) is not null)
AND    xcss.internid = xcsc.internid 
AND    xcss.site_type  IN ('PROSPECT','TARGET')
AND    xcss.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND    hpr.party_relationship_type = 'CONTACT_OF'
AND    hpr.status  = 'A'
AND    hzp.party_type  = 'PERSON'
AND    hzp.status  = 'A'    
AND    trunc(sysdate)  BETWEEN hpr.start_date and hpr.end_date;


PROMPT
PROMPT Script - PROSPECT CONTACT DETAILS
PROMPT

PROMPT
PROMPT Script - Total Number of Prospects Contacts in Oracle
PROMPT


SELECT count(*)
FROM   hz_party_relationships hpr,
       hz_parties             hzp,
       hz_org_contacts        hoc,
       apps.xx_cdh_solar_contactimage xcsc,
       apps.xx_cdh_solar_siteimage xcss
WHERE  hpr.subject_id                   = hzp.party_id
AND    hpr.party_relationship_id        = hoc.party_relationship_id (+)
AND    hzp.orig_system_reference = lpad(xcsc.internid,10,'0') || '-00001-S0'
AND    (rtrim(xcsc.fname) is not null or rtrim(xcsc.lname) is not null)
AND    xcss.internid = xcsc.internid 
AND    xcss.site_type  IN ('PROSPECT','TARGET')
AND    xcss.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND    hpr.party_relationship_type = 'CONTACT_OF'
AND    hpr.status = 'A'
AND    hzp.party_type = 'PERSON'
AND    hzp.status  = 'A'    
AND    trunc(sysdate) BETWEEN hpr.start_date and hpr.end_date;
       

      
PROMPT
PROMPT Script - CUSTOMER CONTACT DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Customer Contacts in Oracle 
PROMPT


SELECT count(*)
FROM   hz_party_relationships hpr,
       hz_parties             hzp,
       hz_org_contacts        hoc,
       apps.xx_cdh_solar_contactimage xcsc,
       apps.xx_cdh_solar_siteimage xcss
WHERE  hpr.subject_id                   = hzp.party_id
AND    hpr.party_relationship_id        = hoc.party_relationship_id (+)
AND    hzp.orig_system_reference = lpad(xcsc.internid,10,'0') || '-00001-S0'
AND   (RTRIM(xcsc.fname) IS NOT NULL OR RTRIM(xcsc.lname) IS NOT NULL)
AND   xcss.internid = xcsc.internid 
AND   hzp.attribute13 = 'CUSTOMER'
AND   xcss.site_type = 'SHIPTO'
AND   xcss.rsd_id = (SELECT  DISTINCT rsd_id                    
                   FROM    apps.xx_cdh_solar_conversion_group XCSCG  
                   WHERE   XCSCG.conversion_group_id = :P_CONV_GRP_ID
                   AND     rownum <2)
AND   hpr.party_relationship_type = 'CONTACT_OF'
AND   hpr.status  = 'A'
AND   hzp.party_type  = 'PERSON'
AND   hzp.status   = 'A'    
AND   trunc(sysdate) BETWEEN hpr.start_date and hpr.end_date;



PROMPT
PROMPT Script - PROSPECT ASSIGNMENTS DETAILS
PROMPT



PROMPT
PROMPT Script - Total number of Prospects assignements in Oracle for the RSD
PROMPT


SELECT count(hps.party_site_id)
FROM   hz_parties hp,
       hz_party_sites hps
WHERE  hps.ORIG_SYSTEM_REFERENCE in 
               ( SELECT  lpad(xcss.internid,10,'0') || '-00001-S0' 
                 FROM   XXCNV.xx_cdh_solar_siteimage XCSS 
                       ,XXTPS.xxtps_sp_mapping       XSM 
                 WHERE  XCSS.site_type IN ('PROSPECT','TARGET')
                 AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
                 AND    XSM.sp_id_orig is NOT NULL 
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
                 WHERE  xcscg.conversion_group_id = :P_CONV_GRP_ID 
                 AND    XCSCG.validate_status = 'OK' 
                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                 AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                       ) 
                )) 
AND  hps.party_id = hp.party_id
AND  hp.attribute13 ='PROSPECT';


PROMPT
PROMPT Script - Total number of Prospects assignements failed due to Inactive Reps
PROMPT


SELECT  count(lpad(xcss.internid,10,'0') || '-00001-S0') 
FROM    XXCNV.xx_cdh_solar_siteimage XCSS 
       ,XXTPS.xxtps_sp_mapping       XSM 
WHERE  XCSS.site_type IN ('PROSPECT','TARGET')
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
                 AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                       ) 
                );
                            


PROMPT
PROMPT Script - Total Number of Prospects assignements failed due to resps mapping not there in XXTPS table
PROMPT


SELECT count(hps.party_site_id)
FROM   hz_parties hp,
       hz_party_sites hps
WHERE  hps.ORIG_SYSTEM_REFERENCE in 
               ( SELECT  lpad(xcss.internid,10,'0') || '-00001-S0' 
                 FROM   XXCNV.xx_cdh_solar_siteimage XCSS 
                       ,XXTPS.xxtps_sp_mapping       XSM 
                 WHERE  XCSS.site_type IN ('PROSPECT','TARGET')
                 AND    XCSS.conversion_rep_id = XSM.sp_id_orig(+) 
                 and    XSM.sp_id_orig is NULL 
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
                 WHERE  xcscg.conversion_group_id = :P_CONV_GRP_ID 
                 AND    XCSCG.validate_status = 'OK' 
                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                 AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                       ) 
                )) 
AND hps.party_id = hp.party_id
AND hp.attribute13 ='PROSPECT';


PROMPT
PROMPT Script - Total number of Prospects assignments failed due to resource not found in Resource Manager
PROMPT


SELECT  count(lpad(xcss.internid,10,'0') || '-00001-S0' )
FROM    XXCNV.xx_cdh_solar_siteimage XCSS 
       ,XXTPS.xxtps_sp_mapping       XSM 
WHERE  XCSS.site_type IN ('PROSPECT','TARGET')
AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
AND    XSM.sp_id_orig is not NULL 
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
AND NOT EXISTS (SELECT 1
                FROM   apps.jtf_rs_roles_b  jrrb,
                       apps.jtf_rs_role_relations jrrr,
                       apps.jtf_rs_resource_extns jrre,
                       apps.xxtps_sp_mapping      tps
                WHERE  tps.sp_id_orig  = xcss.rep_id
                AND    jrrr.attribute15    = tps.sp_id_new
                AND    jrrb.role_id        = jrrr.role_id
                AND    jrre.resource_id    = jrrr.role_resource_id);
         
         
PROMPT
PROMPT Script - Total Number of Prospects Assignments for each Reps under particular RSD in Oracle
PROMPT


SELECT  count(lpad(xcss.internid,10,'0') || '-00001-S0' )
FROM   XXCNV.xx_cdh_solar_siteimage XCSS 
      ,XXTPS.xxtps_sp_mapping       XSM 
WHERE  XCSS.site_type IN ('PROSPECT','TARGET')
AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
AND    XSM.sp_id_orig is not NULL 
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
                );
                            
                            
PROMPT
PROMPT Script - Total Number of Prospects Assignments to Admin for this RSD
PROMPT


SELECT  count(lpad(xcss.internid,10,'0') || '-00001-S0' )
FROM    XXCNV.xx_cdh_solar_siteimage XCSS 
       ,XXTPS.xxtps_sp_mapping       XSM 
WHERE  XCSS.site_type IN ('PROSPECT','TARGET')
AND    XCSS.conversion_rep_id = XSM.sp_id_orig 
and    XSM.sp_id_orig is not NULL 
AND    XCSS.status = 'ACTIVE' 
AND    XSM.sp_id_new  =  'CLEANUP'
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
                 AND    xcscg.conversion_group_id = :P_CONV_GRP_ID
                 AND    XCSCG.conversion_rep_id   = XCSS.conversion_rep_id 
                 AND   ( SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) 
                         AND NVL(XCSCG.end_date_active,SYSDATE + 1) 
                       ) 
                );
                            
                            
PROMPT
PROMPT Script - NOTES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Notes  in Oracle 
PROMPT


SELECT count(*) 
FROM   apps.xx_jtf_notes_int  a
       ,jtf_notes_b           b
WHERE  a.batch_id = :P_NOTE_BATCH_ID
AND    a.jtf_note_orig_system_ref = b.orig_system_reference
AND    b.source_object_id IS NOT NULL;


PROMPT
PROMPT Script - Total Number of Notes attached to Prospects party level in Oracle 
PROMPT


SELECT count(jnv.jtf_note_id) 
FROM   apps.hz_parties hzp,
       apps.jtf_notes_vl jnv
WHERE  jnv.source_object_code = 'PARTY'
AND    jnv.source_object_id = hzp.party_id
AND    hzp.orig_system_reference IN (
                          SELECT lpad(to_char(xcsn.internid),10,'0') || '-00001-S0' 
                          FROM apps.xx_cdh_solar_conversion_group xcscg,
                               apps.xx_cdh_solar_siteimage        xcss,
                               apps.xx_cdh_solar_noteimage        xcsn
                          WHERE xcss.conversion_rep_id = xcscg.conversion_rep_id
                          AND xcscg.conversion_group_id = :P_CONV_GRP_ID
                          AND xcss.site_type IN ('PROSPECT','TARGET')
                          AND xcss.status = 'ACTIVE'
                          AND xcsn.internid = xcss.internid
                          AND exists (SELECT 1 from   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                                      AND  flv.enabled_flag = 'Y'
                                      AND  flv.language     = 'US'
                                      AND  flv.lookup_code  = UPPER(xcss.rev_band)));
 

PROMPT
PROMPT Script - Total Number of Notes Attached to Customer at site level  in Oracle
PROMPT


SELECT count(jnv.jtf_note_id) 
FROM   apps.hz_parties hzp,
       apps.hz_party_sites hps,
       apps.jtf_notes_vl jnv
WHERE  jnv.source_object_code = 'PARTY'
AND    jnv.source_object_id = hzp.party_id
AND    hzp.party_id = hps.party_id
AND    hzp.orig_system_reference IN (
                          SELECT lpad(to_char(xcsn.internid),10,'0') || '-00001-S0' 
                          FROM apps.xx_cdh_solar_conversion_group xcscg,
                               apps.xx_cdh_solar_siteimage        xcss,
                               apps.xx_cdh_solar_noteimage        xcsn
                          WHERE xcss.conversion_rep_id = xcscg.conversion_rep_id
                          AND xcscg.conversion_group_id = :P_CONV_GRP_ID
                          AND xcss.site_type IN ('SHIPTO')
                          AND xcss.status = 'ACTIVE'
                          AND xcsn.internid = xcss.internid
                          AND exists (SELECT 1 from   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                                      AND  flv.enabled_flag = 'Y'
                                      AND  flv.language     = 'US'
                                      AND  flv.lookup_code  = UPPER(xcss.rev_band)));


PROMPT
PROMPT Script - Total Number Notes failed due to prospects not found in Oracle
PROMPT


SELECT count(jnv.jtf_note_id) 
FROM   apps.hz_parties hzp,
       apps.jtf_notes_vl jnv
WHERE  jnv.source_object_code = 'PARTY'
AND    jnv.source_object_id = hzp.party_id
AND    hzp.orig_system_reference NOT IN (
                          SELECT lpad(to_char(xcsn.internid),10,'0') || '-00001-S0' 
                          FROM apps.xx_cdh_solar_conversion_group xcscg,
                               apps.xx_cdh_solar_siteimage        xcss,
                               apps.xx_cdh_solar_noteimage        xcsn
                          WHERE xcss.conversion_rep_id = xcscg.conversion_rep_id
                          AND xcscg.conversion_group_id = :P_CONV_GRP_ID
                          AND xcss.site_type IN ('PROSPECT','TARGET')
                          AND xcss.status = 'ACTIVE'
                          AND xcsn.internid = xcss.internid
                          AND exists (SELECT 1 from   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                                      AND  flv.enabled_flag = 'Y'
                                      AND  flv.language     = 'US'
                                      AND  flv.lookup_code  = UPPER(xcss.rev_band)));
                                            
                                            
PROMPT
PROMPT Script - Total Number of Notes failed due to Customer Sites Not found in Oracle
PROMPT


SELECT count(jnv.jtf_note_id) 
FROM   apps.hz_parties      HZP,
       apps.hz_party_sites  HPS,
       apps.jtf_notes_vl    JNV
WHERE  JNV.source_object_code = 'PARTY'
AND    JNV.source_object_id = hzp.party_id
AND    HZP.party_id = hps.party_id
AND    HPS.orig_system_reference NOT IN (
                          SELECT lpad(to_char(xcsn.internid),10,'0') || '-00001-S0' 
                          FROM apps.xx_cdh_solar_conversion_group xcscg,
                               apps.xx_cdh_solar_siteimage        xcss,
                               apps.xx_cdh_solar_noteimage        xcsn
                          WHERE xcss.conversion_rep_id = xcscg.conversion_rep_id
                          AND xcscg.conversion_group_id = :P_CONV_GRP_ID
                          AND xcss.site_type IN ('SHIPTO')
                          AND xcss.status = 'ACTIVE'
                          AND xcsn.internid = xcss.internid
                          AND exists (SELECT 1 from   fnd_lookup_values flv
                                      WHERE  flv.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
                                      AND  flv.enabled_flag = 'Y'
                                      AND  flv.language     = 'US'
                                      AND  flv.lookup_code  = UPPER(xcss.rev_band)));
                                            
 
PROMPT
PROMPT Script - Total Number  notes failed  with other Reason 
PROMPT


SELECT count(*),
       oracle_error_msg
FROM   apps.xx_com_exceptions_log_conv 
WHERE  batch_id = :P_NOTE_BATCH_ID 
GROUP BY oracle_error_msg;



PROMPT
PROMPT Script - TASK DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Tasks in Oracle
PROMPT


SELECT count(*) 
FROM   apps.jtf_tasks_b           JTB,
       apps.xx_jtf_imp_tasks_int  XJITI
WHERE  XJITI.task_original_system_ref =JTB.attribute15 
AND    XJITI.batch_id = :P_TASK_BATCH_ID
AND    XJITI.interface_status='7';


PROMPT
PROMPT Script - Total Number of Tasks attached to Prospects party Level in Oracle
PROMPT


SELECT count(*) 
FROM   APPS.jtf_tasks_b          a
     , APPS.XX_jtf_imp_tasks_int c
     , apps.hz_parties           b
WHERE  c.task_original_system_ref = a.attribute15
AND    a.customer_id = b.party_id
AND    b.attribute13 = 'PROSPECT'
AND    c.batch_id  = :P_TASK_BATCH_ID
AND    c.interface_status='7';


PROMPT
PROMPT Script - Total Number of Tasks attached to Customer at  site level  in Oracle
PROMPT

SELECT count(*) 
FROM   APPS.jtf_tasks_b          A
     , APPS.XX_jtf_imp_tasks_int C
     , apps.hz_parties           B
     , apps.hz_party_sites       D
WHERE  C.task_original_system_ref = A.attribute15
AND    A.customer_id = B.party_id
AND    B.attribute13 = 'CUSTOMER'
AND    D.party_id = B.party_id
AND    C.batch_id  = :P_TASK_BATCH_ID
AND    C.interface_status='7';
 
   
PROMPT
PROMPT Script - Total Number of Tasks failed due to Prospects not found in the Oracle
PROMPT


SELECT count(*) 
FROM   apps.jtf_tasks_b          A
     , apps.XX_jtf_imp_tasks_int C
     , apps.hz_parties           B
WHERE  C.task_original_system_ref = A.attribute15
AND    A.customer_id <> B.party_id
AND    B.attribute13 = 'PROSPECT'
AND    C.batch_id  = :P_TASK_BATCH_ID
AND    C.error_id IS NOT NULL;


PROMPT
PROMPT Script - Total Number of Tasks failed due to Customer sites not found in Oracle
PROMPT


SELECT count(*) 
FROM   apps.jtf_tasks_b           A
     , apps.XX_jtf_imp_tasks_int  C
     , apps.hz_parties            B
     , apps.hz_party_sites        D
WHERE  C.task_original_system_ref  =A.attribute15
AND    A.customer_id = B.party_id
AND    B.attribute13 = 'CUSTOMER'
AND    D.party_id = b.party_id
AND    D.party_site_id is null
AND    C.batch_id  = :P_TASK_BATCH_ID
AND    C.error_id IS NOT NULL;


PROMPT
PROMPT Script - Total Number of Tasks failed with other  Reason
PROMPT


SELECT count(*),
       oracle_error_msg
FROM   apps.xx_com_exceptions_log_conv 
WHERE  batch_id = :P_TASK_BATCH_ID 
GROUP BY oracle_error_msg;



PROMPT
PROMPT Script - ACTIVITIES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Activities converted as tasks in Oracle for this RSD 
PROMPT


SELECT count(*) 
FROM   apps.jtf_tasks_b           JTB,
       apps.xx_jtf_imp_tasks_int  XJITI
WHERE  XJITI.task_original_system_ref = JTB.attribute15 
AND    XJITI.batch_id =:P_ACTIVITY_BATCH_ID
AND    XJITI.interface_status='7';


PROMPT
PROMPT Script - Total Number of Activities converted as tasks in Oracle and attached to prospects for this RSD
PROMPT

SELECT count(*) 
FROM   apps.jtf_tasks_b          A
      ,apps.XX_jtf_imp_tasks_int C
      ,apps.hz_parties           B
WHERE  C.task_original_system_ref = A.attribute15
AND    A.customer_id = B.party_id
AND    B.attribute13 = 'PROSPECT'
AND    C.batch_id  = :P_ACTIVITY_BATCH_ID
AND    C.interface_status='7';


PROMPT
PROMPT Script - Total Number of Activities converted as Tasks  in Oracle and  attached to Customer Sites for this RSD
PROMPT


SELECT count(*) 
FROM   apps.jtf_tasks_b          A
      ,apps.XX_jtf_imp_tasks_int C
      ,apps.hz_parties           B
      ,apps.hz_party_sites       D
WHERE  C.task_original_system_ref = A.attribute15
AND    A.customer_id = B.party_id
AND    B.attribute13 = 'CUSTOMER'
AND    D.party_id = B.party_id
AND    C.batch_id  = :P_ACTIVITY_BATCH_ID
AND    C.interface_status='7';


PROMPT
PROMPT Script - Total Number of Activities failed due to Prospects not found in Oracle
PROMPT


SELECT count(*) 
FROM   apps.jtf_tasks_b           JTB,
       apps.xx_jtf_imp_tasks_int  XJITI
WHERE  XJITI.task_original_system_ref <> JTB.attribute15 
AND    XJITI.batch_id = :P_ACTIVITY_BATCH_ID;


PROMPT
PROMPT Script - Total Number of Activities failed due to Customer sites not found in Oracle
PROMPT


SELECT count(*) 
FROM   apps.jtf_tasks_b           A
      ,apps.xx_jtf_imp_tasks_int  C
      ,apps.hz_parties            B
      ,apps.hz_party_sites        D
WHERE  C.task_original_system_ref = A.attribute15
AND    A.customer_id = B.party_id
AND    B.attribute13 = 'CUSTOMER'
AND    D.party_id = B.party_id
AND    D.party_site_id IS NULL
AND    C.batch_id  = :P_ACTIVITY_BATCH_ID;
  
 
PROMPT
PROMPT Script - Total Number of activities failed with other  reason
PROMPT


SELECT count(*),
       oracle_error_msg
FROM   apps.xx_com_exceptions_log_conv 
WHERE  batch_id = :P_ACTIVITY_BATCH_ID 
GROUP BY oracle_error_msg;



PROMPT
PROMPT Script - LEADS DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Leads in Oracle 
PROMPT


SELECT count(*)
FROM   apps.as_import_interface A, 
       apps.hz_party_sites      P, 
       apps.as_sales_leads      S 
WHERE  P.party_site_id=A.party_site_id 
AND    S.request_id=A.request_id 
AND    S.orig_system_reference=A.orig_system_reference 
AND    S.sales_lead_id=A.SALES_LEAD_ID 
AND    A.batch_id= :P_LEAD_BATCH_ID;


PROMPT
PROMPT Script - Total Number of Leads Failed 
PROMPT


SELECT count(*) 
FROM   as_import_interface
WHERE  batch_id = :P_LEAD_BATCH_ID
AND    load_status <>'SUCCESS';
    
    
PROMPT
PROMPT Script - Total Number of Leads failed due to API error 
PROMPT


SELECT count(load_error_message) 
FROM   as_import_interface
WHERE  batch_id = :P_LEAD_BATCH_ID
AND    load_status <>'SUCCESS';
   
   
PROMPT
PROMPT Script - Total Number of Leads failed due to OSR not found in Oracle 
PROMPT


SELECT count(*)
FROM   apps.as_import_interface A, 
       apps.hz_party_sites      P, 
       apps.as_sales_leads      S 
WHERE  P.party_site_id=A.party_site_id 
AND    S.request_id=A.request_id 
AND    S.orig_system_reference <> A.orig_system_reference 
AND    A.load_status <> 'SUCCESS'
AND    S.sales_lead_id=A.sales_lead_id 
AND    A.batch_id= :P_LEAD_BATCH_ID;



PROMPT
PROMPT Script - OPPORTUNITIES DETAILS
PROMPT



PROMPT
PROMPT Script - Number of opportunities in SOLAR for the Conversion Group 
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_opporimage        OI,
       apps.xx_cdh_solar_siteimage         SI,
       apps.xx_cdh_solar_conversion_group  CG
WHERE  OI.internid = SI.internid
AND    SI.conversion_rep_id = CG.conversion_rep_id
AND    CG.conversion_group_id = :P_CONV_GRP_ID;


PROMPT
PROMPT Script - Number of opportunities in Intermidiate Table
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1
WHERE  batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Records in staging table with all matching data values in image table
PROMPT


select count(*)
from apps.xx_cdh_solar_oppr_extr1 oe,
     apps.xx_cdh_solar_siteimage  si,
     apps.xx_cdh_solar_opporimage oi
where oe.stamp2_vc = oi.stamp2_vc
  and oe.internid  = si.internid
  and oe.conversion_group_id = :P_CONV_GRP_ID
  and oe.batch_id            = :P_OPPORTUNITY_BATCH_ID
  and ((oe.site_type      = si.site_type)      or (oe.site_type is null      and si.site_type is null))
  and ((oe.internid       = oi.internid)       or (oe.internid is null       and oi.internid is null))
  and ((oe.id             = si.id)             or (oe.id is null             and si.id is null))
  and ((oe.cust_id        = si.cust_id)        or (oe.cust_id is null        and si.cust_id is null))
  and ((oe.shipto_num     = si.shipto_num)     or (oe.shipto_num is null     and si.shipto_num is null))
  and ((oe.chgdate        = oi.chgdate)        or (oe.chgdate is null        and oi.chgdate is null))
  and ((oe.chgtime        = oi.chgtime)        or (oe.chgtime is null        and oi.chgtime is null))
  and ((oe.stamp2         = oi.stamp2)         or (oe.stamp2 is null         and oi.stamp2 is null))
  and ((oe.stamp2_vc      = oi.stamp2_vc)      or (oe.stamp2_vc is null      and oi.stamp2_vc is null))
  and ((oe.oppor_id       = oi.oppor_id)       or (oe.oppor_id is null       and oi.oppor_id is null))
  and ((oe.status         = oi.status)         or (oe.status is null         and oi.status is null))
  and ((oe.key_contact    = oi.key_contact)    or (oe.key_contact is null    and oi.key_contact is null))
  and ((oe.key_phone      = oi.key_phone)      or (oe.key_phone is null      and oi.key_phone is null))
  and ((oe.expected_close = oi.expected_close) or (oe.expected_close is null and decode(oi.expected_close,
                                                            to_date('01-JAN-1900','DD-MON-YYYY'), null,
                                                                    oi.expected_close) is null))
  and ((oe.opp_title      = oi.opp_title)      or (oe.opp_title is null      and oi.opp_title is null))
  and ((oe.amount         = oi.amount)         or (oe.amount is null         and oi.amount is null))
  and ((oe.incumbent      = oi.incumbent)      or (oe.incumbent is null      and oi.incumbent is null))
  and ((oe.commentx       = oi.commentx)       or (oe.commentx is null       and oi.commentx is null))
  and ((oe.rec_crea_dt    = oi.rec_crea_dt)    or (oe.rec_crea_dt is null    and oi.rec_crea_dt is null))
  and ((oe.rec_crea_time  = oi.rec_crea_time)  or (oe.rec_crea_time is null  and oi.rec_crea_time is null))
  and ((oe.rec_crea_by    = oi.rec_crea_by)    or (oe.rec_crea_by is null    and oi.rec_crea_by is null))
  and ((oe.rec_chng_dt    = oi.rec_chng_dt)    or (oe.rec_chng_dt is null    and oi.rec_chng_dt is null))
  and ((oe.rec_chng_by    = oi.rec_chng_by)    or (oe.rec_chng_by is null    and oi.rec_chng_by is null))
  and ((oe.rec_chng_time  = oi.rec_chng_time)  or (oe.rec_chng_time is null  and oi.rec_chng_time is null))
  and ((oe.commentx_plain = oi.commentx_plain) or (oe.commentx_plain is null and oi.commentx_plain is null))
  and ((oe.contact_stamp2 = oi.contact_stamp2) or (oe.contact_stamp2 is null and oi.contact_stamp2 is null))
  and ((oe.contact_stamp2_vc = oi.contact_stamp2_vc)  or (oe.contact_stamp2_vc is null and oi.contact_stamp2_vc is null));


PROMPT
PROMPT Script - Records in staging table that were created as Ebiz opportunities
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe
WHERE  batch_id = :P_OPPORTUNITY_BATCH_ID
AND    EXISTS (SELECT 'x'
               FROM apps.as_leads_all al
               WHERE oe.stamp2_vc || '-S0' = al.orig_system_reference);

**********************************************************************
PROMPT
PROMPT Script - Records in staging table that were written to the error table.
PROMPT


SELECT count(*)
FROM   apps.xx_com_error_log
WHERE  program_type = 'I1008_Sales_Opportunities'
AND    program_name = 'XX_SFA_OPPORTUNITY_PKG'
AND    module_name = 'SFA'
AND    creation_date BETWEEN to_date('&CONC_PGM_START_TIME','DD-MON-YYYY hh24:mi:ss')
                        AND to_date('&CONC_PGM_END_TIME','DD-MON-YYYY hh24:mi:ss');
**************************************************************************

PROMPT
PROMPT Script - Opportunity header records assigned to the correct Party Site
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al,
       apps.hz_party_sites          hps
WHERE  al.orig_system_reference = oe.stamp2_vc || '-S0'
AND    al.address_id = hps.party_site_id
AND    oe.ebiz_party_site_osr = hps.orig_system_reference
AND    oe.batch_id    = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Opportunity header records with correct Win Probibility, Close Reason, Currency, Sales Channel and Source.
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al
WHERE  al.orig_system_reference = oe.stamp2_vc || '-S0'
AND    al.win_probability  = 100           -- Win Probability field
AND    al.status           = 'IN_PROGRESS' -- Status field
AND    al.close_reason     is null         -- Close Reason field
AND    al.currency_code    = 'USD'         -- Currency field
AND    al.channel_code     = 'DIRECT'      -- Sales Channel field
AND    al.lead_source_code is null         -- Source field
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Opportunity header records with correct Opportunity Name
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al,
       apps.hz_parties              hp
WHERE  al.orig_system_reference = oe.stamp2_vc || '-S0'
AND    al.customer_id = hp.party_id
AND    al.description = hp.party_name || ' SUPPLIES'
AND    oe.batch_id    = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Opportunity header records with correct Close Date.
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al
WHERE  al.orig_system_reference = oe.stamp2_vc || '-S0'
AND    al.decision_date = decode(oe.expected_close,
                                null, trunc(al.last_update_date) + 90,
                                oe.expected_close)
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Opportunity header & line recods with corect Amount and Forecast Amount
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            alh,
       apps.as_lead_lines_all       line
WHERE  alh.orig_system_reference = oe.stamp2_vc || '-S0'
AND    alh.lead_id = line.lead_id
AND    oe.amount = alh.total_amount
AND    oe.amount = line.total_amount
AND    oe.amount = alh.total_revenue_opp_forecast_amt
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Opportunity line records with Product = "SUPPLIES"
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            alh,
       apps.as_lead_lines_all       line,
       apps.mtl_categories_vl       cat,
       apps.mtl_category_set_valid_cats vcat,
       apps.mtl_category_sets_vl        cset
WHERE  alh.orig_system_reference = oe.stamp2_vc || '-S0'
AND    alh.lead_id               = line.lead_id
AND    line.product_category_id  = cat.category_id
AND    line.product_category_id  = vcat.category_id
AND    vcat.category_set_id      = cset.category_set_id
AND    cat.description           = 'SUPPLIES'
AND    cset.category_set_name    = 'Product'
AND    oe.batch_id    = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Opportunity lines with correct competitor records
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1    oe,
       apps.as_leads_all               al,
       apps.as_lead_lines_all          line,
       apps.as_lead_comp_products      cp,
       apps.ams_competitor_products_vl acp,
       apps.hz_parties                 hzp,
       apps.xx_cdh_solar_incumbents    inc
WHERE  al.orig_system_reference = oe.stamp2_vc || '-S0'
AND    al.lead_id               = line.lead_id
AND    line.lead_line_id        = cp.lead_line_id
AND    cp.competitor_product_id = acp.competitor_product_id
AND    acp.competitor_party_id  = hzp.party_id
AND    hzp.party_name           = inc.oracle_competitor_name
AND    inc.solar_incumbent_name = oe.incumbent
AND    acp.competitor_product_code = 'SUPPLIES'
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script - Count of staging table records with no competitor or a Solar competotor that doesn't map to an Oracle competitor
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe
WHERE  oe.conversion_status = 'API_OK'
AND    NOT EXISTS (SELECT 'x'
                   FROM apps.xx_cdh_solar_incumbents inc
                   WHERE oe.incumbent = inc.solar_incumbent_name)
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script -  Count of opportunity contacts with correct Contact Name.
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al,
       apps.as_lead_contacts_all    ac,
       apps.hz_party_relationships  hzpr,
       apps.hz_parties              hzp_per
WHERE  al.orig_system_reference     = oe.stamp2_vc || '-S0'
AND    al.lead_id                   = ac.lead_id
AND    ac.contact_party_id          = hzpr.party_id
AND    hzpr.party_relationship_type = 'CONTACT_OF'
AND    hzpr.subject_id              = hzp_per.party_id
AND    upper(oe.key_contact)        like upper(nvl(hzp_per.person_first_name,'')) || '%'
AND    upper(oe.key_contact)        like '%' || upper(nvl(hzp_per.person_last_name,''))
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script -  Staging table records with no Key Contact.
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe
WHERE  oe.conversion_status = 'API_OK'
AND    oe.contact_stamp2_vc is null
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;


PROMPT
PROMPT Script -  Opportunity contacts with correct phone number in opportunity contact record.  
PROMPT           Count includes records where the phone number in the opportunity contact record should be empty.
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al,
       apps.as_lead_contacts_all    ac,
       apps.hz_party_relationships  hzpr,
       apps.hz_parties              hzp_rel,
       apps.hz_contact_points       cnt_rel,
       apps.hz_parties              hzp_per,
       apps.hz_contact_points       cnt_per
WHERE  al.orig_system_reference     = oe.stamp2_vc || '-S0'
AND    al.lead_id                   = ac.lead_id
AND    ac.contact_party_id          = hzpr.party_id
AND    hzpr.party_relationship_type = 'CONTACT_OF'
AND    hzpr.party_id                = hzp_rel.party_id
AND    hzp_rel.party_type           = 'PARTY_RELATIONSHIP'
AND    hzpr.subject_id              = hzp_per.party_id
AND    hzp_rel.primary_phone_contact_pt_id = cnt_rel.contact_point_id (+)
AND    hzp_per.primary_phone_contact_pt_id = cnt_per.contact_point_id (+)
AND    nvl(cnt_rel.raw_phone_number,'nophonexxx') = 
             nvl(cnt_per.raw_phone_number,'nophonexxx')
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;
  
  
PROMPT
PROMPT Script -  Opportunity contacts with INCORRECT phone number in opportunity contact record. 
PROMPT           If this count is > 0 it is a potential defect.
PROMPT  
  
  
SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al,
       apps.as_lead_contacts_all    ac,
       apps.hz_party_relationships  hzpr,
       apps.hz_parties              hzp_rel,
       apps.hz_contact_points       cnt_rel,
       apps.hz_parties              hzp_per,
       apps.hz_contact_points       cnt_per
WHERE  al.orig_system_reference     = oe.stamp2_vc || '-S0'
AND    al.lead_id                   = ac.lead_id
AND    ac.contact_party_id          = hzpr.party_id
AND    hzpr.party_relationship_type = 'CONTACT_OF'
AND    hzpr.party_id                = hzp_rel.party_id
AND    hzp_rel.party_type           = 'PARTY_RELATIONSHIP'
AND    hzpr.subject_id              = hzp_per.party_id
AND    hzp_rel.primary_phone_contact_pt_id = cnt_rel.contact_point_id (+)
AND    hzp_per.primary_phone_contact_pt_id = cnt_per.contact_point_id (+)
AND    nvl(cnt_rel.raw_phone_number,'nophonexxx') != 
             nvl(cnt_per.raw_phone_number,'nophonexxx')
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;
  
  
PROMPT
PROMPT Script -  Opportunity records with correct Note.  Only includes notes without a Comment value from Solar.
PROMPT  
  
  
SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al,
       apps.jtf_notes_vl            jn
WHERE  al.orig_system_reference = oe.stamp2_vc || '-S0'
AND    al.lead_id               = jn.source_object_id
AND    jn.source_object_code    = 'OPPORTUNITY'
AND    oe.commentx_plain        is null
AND    jn.notes like 'Solar Opportunity created on ' ||
                    to_char(oe.rec_crea_dt,'DD-MON-YYYY') || 
                    ' by ' || oe.rec_crea_by ||
                    ' and was last updated in Solar on ' ||
                    to_char(oe.rec_chng_dt,'DD-MON-YYYY') || '.'
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;
  
  
PROMPT
PROMPT Script -  Opportunity records with correct Note.  Only includes notes containing a Comment value from Solar.
PROMPT 


SELECT count(*)
FROM   apps.xx_cdh_solar_oppr_extr1 oe,
       apps.as_leads_all            al,
       apps.jtf_notes_vl            jn
WHERE  al.orig_system_reference = oe.stamp2_vc || '-S0'
AND    al.lead_id               = jn.source_object_id
AND    jn.source_object_code    = 'OPPORTUNITY'
AND    oe.commentx_plain        is not null
AND    jn.notes like 'Solar Opportunity created on ' ||
                    to_char(oe.rec_crea_dt,'DD-MON-YYYY') || 
                    ' by ' || oe.rec_crea_by ||
                    ' and was last updated in Solar on ' ||
                    to_char(oe.rec_chng_dt,'DD-MON-YYYY') ||
                    '.%The comment entered in Solar is:%' ||
                    oe.commentx_plain
AND    oe.batch_id = :P_OPPORTUNITY_BATCH_ID;
  
  
  
PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
