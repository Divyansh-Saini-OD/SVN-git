REM============================================================================================
REM                                 Start Of Script
REM============================================================================================

--+=============================================================================================+--
--|                                                                                             |--
--| Object Name    : SOLAR Conversion                                                           |--
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
PROMPT Script - CUSTOMER DETAILS
PROMPT



PROMPT
PROMPT Script - Total number of Customers in SOLAR for the RSD
PROMPT


SELECT  count(*)
FROM    XXCNV.xx_cdh_solar_siteimage      XCSS,
        XXCNV.xx_cdh_solar_state_country  X1,
        XXCNV.xx_cdh_solar_state_country  X2,
        fnd_lookup_values                 FLV
WHERE   UPPER(XCSS.site_type) = 'SHIPTO'
AND     XCSS.status = 'ACTIVE'
AND     EXISTS (SELECT  1
                FROM    apps.xx_cdh_solar_conversion_group XCSCG
                WHERE   XCSCG.conversion_rep_id = XCSS.conversion_rep_id
                AND     (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE)AND NVL(XCSCG.end_date_active,SYSDATE + 1))
               )
AND    XCSS.state       = X1.STATE (+)
AND    XCSS.alt_state   = X2.STATE (+)
AND    FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND    FLV.enabled_flag = 'Y'
AND    FLV.language     = 'US'
AND    FLV.lookup_code  = UPPER(XCSS.REV_BAND)
AND    SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1)
AND    XCSS.rsd_id = :RSDID;


PROMPT
PROMPT Script - Total Number of Reps in SOLAR for that RSD
PROMPT

SELECT  count(rep_id) 
FROM    XXCNV.xx_cdh_solar_siteimage 
WHERE   rsd_id = :RSDID 
AND     rep_id IS NOT NULL 
AND     conversion_rep_id IS NOT NULL;



PROMPT
PROMPT Script - PROSPECT DETAILS
PROMPT



PROMPT
PROMPT Script - Total number prospects in SOLAR for RSD
PROMPT


SELECT  COUNT(*)   
FROM    XXCNV.xx_cdh_solar_siteimage      XCSS,
        XXCNV.xx_cdh_solar_state_country  X1,
        XXCNV.xx_cdh_solar_state_country  X2,
        fnd_lookup_values                 FLV
WHERE   UPPER(XCSS.site_type) IN ('PROSPECT','TARGET')
AND     XCSS.status = 'ACTIVE' 
AND     EXISTS (SELECT  1
                FROM apps.xx_cdh_solar_conversion_group XCSCG
                WHERE XCSCG.conversion_rep_id = XCSS.conversion_rep_id
                AND (SYSDATE BETWEEN NVL(XCSCG.start_date_active,SYSDATE) AND NVL(XCSCG.end_date_active,SYSDATE + 1))
               )
AND     XCSS.state       = X1.state (+)
AND     XCSS.alt_state   = X2.state (+)
AND     FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND     FLV.enabled_flag = 'Y'
AND     FLV.language     = 'US'
AND     FLV.lookup_code  = UPPER(XCSS.rev_band)
AND     SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1)
AND     XCSS.rsd_id = :RSDID;


PROMPT
PROMPT Script - Total Number  of Prospects Sites in SOLAR for RSD
PROMPT

SELECT  COUNT(*)
FROM    apps.HZ_IMP_ADDRESSES_INT     AU,
        xxcnv.xx_cdh_solar_siteimage  XCSS
WHERE XCSS.rsd_id = :RSDID
AND (AU.site_orig_system_reference = lpad(XCSS.internid,10,0) || '-00001-S0' OR AU.site_orig_system_reference =lpad(XCSS.internid,10,0) || '-00002-S0');




PROMPT
PROMPT Script - Total Number of Prospects Site uses in SOLAR for RSD
PROMPT

SELECT  COUNT(*)
FROM apps.HZ_IMP_ADDRESSUSES_INT au,
xxcnv.xx_cdh_solar_siteimage xcss
WHERE 
(au.site_orig_system_reference = lpad(xcss.internid,10,0) || '-00001-S0' OR au.site_orig_system_reference = lpad(xcss.internid,10,0) || '-00002-S0')
and xcss.rsd_id = :RSDID;


PROMPT
PROMPT Script - Total Number of Prospects Contact Points in SOLAR for the RSD
PROMPT


SELECT  count(*)
FROM    apps.xx_cdh_solar_contactimage  XCSC,
        apps.xx_cdh_solar_siteimage     XCSS
WHERE   XCSS.internid = XCSC.internid 
AND     (RTRIM(XCSC.fname) IS NOT NULL OR RTRIM(XCSC.lname) IS NOT NULL)
AND     XCSS.site_type  IN ('PROSPECT','TARGET')
AND     XCSS.rsd_id = :RSDID;



PROMPT
PROMPT Script - PROSPECT CONTACT DETAILS
PROMPT

PROMPT
PROMPT Script - Total Number of Prospects Contacts in SOLAR
PROMPT


SELECT count(*) 
FROM   XXCNV.XX_CDH_SOLAR_CONTACTIMAGE  CSC,
       XXCNV.xx_cdh_solar_siteimage     CSS
WHERE  CSS.internid = CSC.internid
AND    UPPER(CSS.site_type) IN ('PROSPECT','TARGET')
AND    CSS.rsd_id = :RSDID;
       

      
PROMPT
PROMPT Script - CUSTOMER CONTACT DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Customer Contacts in SOLAR for the RSD
PROMPT


SELECT count(*) 
FROM   XXCNV.XX_CDH_SOLAR_CONTACTIMAGE  CSC,
       XXCNV.xx_cdh_solar_siteimage     CSS
WHERE  CSS.internid = CSC.internid
AND    UPPER(CSS.site_type) = 'SHIPTO'
AND    CSS.rsd_id = :RSDID;



PROMPT
PROMPT Script - PROSPECT ASSIGNMENTS DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Prospects Assignments in SOLAR 
PROMPT


SELECT  count(XSM.sp_id_orig) 
FROM    XXCNV.xx_cdh_solar_siteimage  XCSS 
       ,XXTPS.xxtps_sp_mapping        XSM 
       ,fnd_lookup_values             FLV
WHERE   XCSS.site_type IN ('PROSPECT','TARGET')
AND     XCSS.conversion_rep_id = XSM.sp_id_orig 
and     XSM.sp_id_orig IS NOT NULL 
AND     XCSS.status = 'ACTIVE' 
AND     FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND     FLV.enabled_flag = 'Y'
AND     FLV.language     = 'US'
AND     FLV.lookup_code  = UPPER(XCSS.REV_BAND) 
AND     SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1);


PROMPT
PROMPT Script - Total number of Prospects Assignments to each Reps in SOLAR under particular RSD
PROMPT

SELECT  count(XSM.sp_id_orig) 
FROM    XXCNV.xx_cdh_solar_siteimage  XCSS
       ,XXTPS.xxtps_sp_mapping        XSM
       ,fnd_lookup_values             FLV
WHERE   XCSS.site_type IN ('PROSPECT','TARGET')
AND     XCSS.conversion_rep_id = XSM.sp_id_orig 
AND     XSM.sp_id_orig IS NOT NULL
AND     XCSS.status = 'ACTIVE'
AND     FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND     FLV.enabled_flag = 'Y'
AND     FLV.language     = 'US'
AND     FLV.lookup_code  = UPPER( XCSS.rev_band) 
AND     SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1)
and     XCSS.rsd_id = :RSDID;



PROMPT
PROMPT Script - NOTES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Notes in SOLAR 
PROMPT


SELECT count(*) 
FROM   apps.xx_cdh_solar_noteimage A,
       apps.xx_cdh_solar_siteimage B
WHERE  A.internid =  B.internid;


PROMPT
PROMPT Script - Total Number of Notes in SOLAR attached to Prospects
PROMPT


SELECT count(*) 
FROM   apps.xx_cdh_solar_noteimage A,
       apps.xx_cdh_solar_siteimage B
WHERE  A.internid =  B.internid
AND    UPPER(B.site_type) IN ('PROSPECT','TARGET');
 

PROMPT
PROMPT Script - Total Number of Notes in SOLAR attached to Customer
PROMPT

SELECT count(*) 
FROM   apps.xx_cdh_solar_noteimage A,
       apps.xx_cdh_solar_siteimage B
WHERE  A.internid =  B.internid
AND    UPPER(B.site_type) = 'SHIPTO';



PROMPT
PROMPT Script - TASK DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Tasks in SOLAR
PROMPT


SELECT count(*) 
FROM   apps.xx_cdh_solar_todoimage  A,
       apps.xx_cdh_solar_siteimage  B,
       fnd_lookup_values            FLV
WHERE  A.internid =  B.internid
AND    B.status = 'ACTIVE'
AND    FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND    FLV.enabled_flag = 'Y'
AND    FLV.language     = 'US'
AND    FLV.lookup_code  = UPPER(B.rev_band)
AND    SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1);


PROMPT
PROMPT Script - Total Number of Tasks in SOLAR attached to Prospects
PROMPT


SELECT count(*) 
FROM   apps.xx_cdh_solar_todoimage  A,
       apps.xx_cdh_solar_siteimage  B,
       fnd_lookup_values            FLV
WHERE  A.internid =  B.internid
AND    B.status = 'ACTIVE'
AND    FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND    FLV.enabled_flag = 'Y'
AND    FLV.language     = 'US'
AND    FLV.lookup_code  = UPPER(B.rev_band)
AND    SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1)
AND    UPPER(B.site_type)  IN ('PROSPECT','TARGET');


PROMPT
PROMPT Script - Total Number of Tasks in SOLAR attached to Customer Sites
PROMPT

SELECT count(*) 
FROM   apps.xx_cdh_solar_todoimage  A,
       apps.xx_cdh_solar_siteimage  B,
       fnd_lookup_values            FLV
WHERE  A.internid =  B.internid
AND    B.status = 'ACTIVE'
AND    FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND    FLV.enabled_flag = 'Y'
AND    FLV.language     = 'US'
AND    FLV.lookup_code  = UPPER(B.rev_band)
AND    SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1)
AND    UPPER(B.site_type) = 'SHIPTO';
   
   
   
PROMPT
PROMPT Script - ACTIVITIES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number Activites in SOLAR 
PROMPT


SELECT count(*) AS cnt_act
FROM   XXCNV.xx_cdh_solar_activities_image  ACVT
      ,XXCNV.xx_cdh_solar_siteimage         XCSS
      ,fnd_lookup_values                    FLV
WHERE  ACVT.internid = XCSS.internid
AND    XCSS.site_type IN ('PROSPECT','TARGET','SHIPTO')
AND    XCSS.status ='ACTIVE'
AND    FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND    FLV.enabled_flag = 'Y'
AND    FLV.language     = 'US'
AND    FLV.lookup_code  = UPPER( XCSS.rev_band) 
AND    SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1);


PROMPT
PROMPT Script - Total Number Activites in SOLAR attached to Prospects
PROMPT

SELECT count(*) AS cnt_act
FROM   XXCNV.xx_cdh_solar_activities_image  ACVT
      ,XXCNV.xx_cdh_solar_siteimage         XCSS
      ,fnd_lookup_values                    FLV
WHERE  ACVT.internid = XCSS.internid
AND    XCSS.site_type IN ('PROSPECT','TARGET')
AND    XCSS.status ='ACTIVE'
AND    FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND    FLV.enabled_flag = 'Y'
AND    FLV.language     = 'US'
AND    FLV.lookup_code  = UPPER( XCSS.rev_band) 
AND    SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1);


PROMPT
PROMPT Script - Total Number of Activities in SOLAR attached to Customer
PROMPT


SELECT COUNT(*) AS cnt_act
FROM   XXCNV.xx_cdh_solar_activities_image  ACVT
      ,XXCNV.xx_cdh_solar_siteimage         XCSS
      ,fnd_lookup_values                    FLV
WHERE  ACVT.internid = XCSS.internid
AND    XCSS.site_type IN ('SHIPTO')
AND    XCSS.status ='ACTIVE'
AND    FLV.lookup_type  = 'XX_CRM_REV_BAND_TYPES'
AND    FLV.enabled_flag = 'Y'
AND    FLV.language     = 'US'
AND    FLV.lookup_code  = UPPER( XCSS.rev_band) 
AND    SYSDATE BETWEEN NVL( FLV.start_date_active,SYSDATE - 1) AND NVL(FLV.end_date_active,SYSDATE + 1);



PROMPT
PROMPT Script - LEADS DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Leads in SOLAR for this RSD
PROMPT


SELECT  count(*)
FROM    apps.xx_cdh_solar_siteimage  SI
WHERE   si.internid NOT IN
             (SELECT oi.internid
              FROM   apps.xx_cdh_solar_opporimage oi)
AND     SI.rsd_id = :RSDID;



PROMPT
PROMPT Script - OPPORTUNITIES DETAILS
PROMPT



PROMPT
PROMPT Script - Total Number of Opportunities in SOLAR
PROMPT


SELECT count(*)
FROM   apps.xx_cdh_solar_opporimage        OI,
       apps.xx_cdh_solar_siteimage         SI,
       apps.xx_cdh_solar_conversion_group  CG
WHERE  OI.internid = SI.internid
AND    SI.conversion_rep_id = CG.conversion_rep_id
AND    CG.conversion_group_id = :CONVERSIONGROUP;




PROMPT
PROMPT Exiting....
PROMPT

SET FEEDBACK ON
SET HEAD     ON

EXIT
REM=================================================================================================
REM                                   End Of Script                                            
REM=================================================================================================
