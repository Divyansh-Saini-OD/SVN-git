SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

create or replace
PACKAGE BODY XX_CDH_CONV_OWB_PKG
-- +=========================================================================================+
-- |                  Office Depot - Project Simplify                                        |
-- |            Oracle NAIO/WIPRO/Office Depot/Consulting Organization                       |
-- +=========================================================================================+
-- | Name        : XX_CDH_OWB_CVSTG_PKG                                                      |
-- | Description : This package is developed to call the OWB processflows/workflows from     |
-- |               the cuncurrent manager. But in future, Any APIs which are involved in OWB |
-- |               ie, load from CV to INT tables, can be added to this package as well      |
-- |                                                                                         |
-- |Change Record:                                                                           |
-- |===============                                                                          |
-- |Version     Date           Author               Remarks                                  |
-- |=======    ==========      ================     =========================================|
-- |DRAFT 1A   21-JUN-2007     Binoy Mathew         Initial draft version                    |
-- |1.0        28-Jul-2007     Rajeev Kamath        Rename package; Add Call from AOPS to CV |
-- |1.1        31-Jul-2007     Binoy Mathew         Added procedure post_extract_update_aops |
-- |1.2        04-Dec-2007     Ambarish Mukherjee   Added Bulk Collect Logic                 |
-- |1.3        14-Mar-2008     Ambarish Mukherjee   Changes in update for Delta Customers    |
-- |1.4        27-Mar-2008     Ambarish Mukherjee   Changes for OWB Return Status            |
-- |1.5        15-May-2008     Indra Varada         Changes for os/osr population            |
-- |2.0        11-Jul-2008     Ambarish Mukherjee   OU Changes for DIRECT Customers for mixed  |
-- |                                                bag; existing logic to apply only for      |
-- |                                                CONTRACT Customers.                        |
-- |2.1        06-Aug-2008     Harinath Kalmanje    Added the procedure get_profile_dflt_values|
-- |2.2        14-OCT-2008     Indra Varada         QC - 11980                               |
-- |2.3        22-OCT-2008     Indra Varada         Code fixes for OU logic                  |
-- |2.4        02-DEC-2008     Sreedhar Mohan       code fix for clearing billdocs           |
-- |2.5        19-JAN-2009     Indra Varada         Modified Logic for clearing billdocs     |
-- |2.6        16-MAR-2009     Sreedhar Mohan       Populate sequence numbers for BILLDOCS   |
-- |                                                records for new customers created in AOPS|
-- |2.7        22-May-2009     Indra Varada         BILLDOCS Logic to handle DELTA and FULL  |
-- |                                                Conversion seperately                    |
-- |2.8        28-May-2009     Indra Varada         Fix for QC: 15555 and 15556              |
-- |2.9        02-Jun-2009     Indra Varada         Profiles Not to be modified if batch is  |
-- |                                                DELTA and account already exists.        |
-- |3.0        10-Jun-2009     Indra Varada         Logic to remove SPC from Interface table |
-- |                                                if it is already exists in base table    |
-- +=========================================================================================+
AS
gn_bulk_fetch_limit           NUMBER               := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;
-- +===================================================================+
-- | Name        : run_owb_pf_load                                     |
-- | Description : This program is directly called from the Cuncurent  |
-- |               Manager. It calls the OWB APIs to run the OWB       |
-- |               Processflows.                                       |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- | Parameters  :  p_batch_id                                         |
-- | Parameters  :  p_custom_max_errors                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE run_owb_pf_load(
                 x_errbuf                         OUT       VARCHAR2
                ,x_retcode                        OUT       VARCHAR2
                ,p_apps_batch_id                  IN        NUMBER
                ,p_batch_id                       IN        NUMBER
                ,p_custom_max_errors              IN        NUMBER
                ,p_process_yn                     IN        VARCHAR2
                         )
AS 
ln_exec_return_code              NUMBER ;
lc_custom_params                 VARCHAR2(2000);
lc_current_user                  VARCHAR2(200) := user;
lc_location_name                 VARCHAR2(200) ;
le_skip_procedure                EXCEPTION;
lc_run_status                    varchar2(30);
lc_run_details                   varchar2(8000);

CURSOR lc_owb_location 
IS
SELECT fnd_profile.value('XX_CDH_OWB_LOCATION') LOC
FROM   DUAL ;
       
BEGIN
   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;   
   
    log_debug_msg('=====================  BEGIN   =======================');
    log_debug_msg('=== Calling  OWB Process PF_C0024_LOAD_NA_N ===='||CHR(10));
    
    IF p_apps_batch_id IS NULL OR p_batch_id IS NULL  THEN 
       x_errbuf  := 'Both Batch Ids should be entered';
       x_retcode := '2';
       RETURN;
    END IF;
    
    for cur_owb_location in lc_owb_location loop
        lc_location_name := cur_owb_location.LOC ;
    end loop;
    
    lc_location_name := fnd_profile.value('XX_CDH_OWB_LOCATION') ;

    lc_custom_params := 'P_APPS_BATCH_ID=' || TO_CHAR(p_apps_batch_id) ;
    lc_custom_params := lc_custom_params || ',P_BATCH_ID=' || TO_CHAR(p_batch_id) ;
    lc_custom_params := lc_custom_params || ',P_CUSTOM_MAX_ERRORS=' || TO_CHAR(NVL(p_custom_max_errors,500)) ;
            
    execute immediate 'alter session set current_schema=OWB_RT' ;    
    ln_exec_return_code := wb_rt_api_exec.run_task(p_location_name=>lc_location_name,
                                                   p_task_type=>'PROCESSFLOW',
                                                   p_task_name=>'PF_C0024_LOAD_NA_N',
                                                   p_custom_params=>lc_custom_params,
                                                   p_oem_friendly=>0,
                                                   p_background=>0);


    get_owb_run_status(
                 lc_run_status
                ,lc_run_details
                ,p_batch_id
                ,'LOAD'
                            ) ;
    fnd_file.put_line (fnd_file.log,CHR(10)||'============= LOAD STATUS ==============');
    fnd_file.put_line (fnd_file.log,CHR(10)|| lc_run_details );

    execute immediate 'alter session set current_schema=' || lc_current_user ;  

    log_debug_msg(CHR(10)||'============= Procedure RUN_OWB_PF_LOAD ==============');
    log_debug_msg('======================       END        ========================');
    
    --IF lc_run_status != 'OK' then
    --   x_errbuf  := '****ERROR****';
    --   x_retcode := '2';
    --END IF;
    
    IF ln_exec_return_code = 1 THEN          -- SUCCESS
       x_retcode := 0;
    ELSIF ln_exec_return_code = 2 THEN       -- WARNING
       x_retcode := 2;
    ELSIF ln_exec_return_code = 3 THEN       -- ERROR   
       x_retcode := 2;
    END IF;   

EXCEPTION
   WHEN le_skip_procedure THEN
       x_retcode   := 0;
       fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
       execute immediate 'alter session set current_schema=' || lc_current_user ;  
       x_errbuf    :='Others Exception in RUN_OWB_PF_LOAD procedure '||SQLERRM;
       x_retcode   :='2';
END run_owb_pf_load;


-- +===================================================================+
-- | Name        : run_owb_pf_extract                                  |
-- | Description : This program is directly called from the Cuncurent  |
-- |               Manager. It calls the OWB APIs to run the OWB       |
-- |               Processflows.                                       |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- | Parameters  :  p_batch_id                                         |
-- | Parameters  :  p_custom_max_errors                                |
-- |                                                                   |
-- +===================================================================+
PROCEDURE run_owb_pf_extract(
                 x_errbuf              OUT VARCHAR2
                ,x_retcode             OUT VARCHAR2
                ,p_custom_max_errors   IN  NUMBER
                ,p_aops_batch_id       IN  NUMBER
                ,p_process_yn          IN  VARCHAR2
                             )
AS
CURSOR l_cur_ebs_batchi_d
IS 
SELECT MAX(ebs_batch_id) ebs_batch_id
FROM   xx_owb_crmbatch_status 
WHERE  aops_batch_id = p_aops_batch_id ;

ln_exec_return_code                 NUMBER ;
lc_custom_params                    VARCHAR2(2000);
lc_current_user                     VARCHAR2(200) := USER;
lc_location_name                    VARCHAR2(200) ;
lc_dblink_name                      VARCHAR2(200) ;
lc_ebs_batch_id                     NUMBER(15) ;
le_skip_procedure                   EXCEPTION;
lc_run_status                       VARCHAR2(30);
lc_run_details                      VARCHAR2(8000);

BEGIN
   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;   
    log_debug_msg('=====================  BEGIN   =======================');
    log_debug_msg('=== Calling  OWB Process PF_C0024_EXTRACT_NA_N ===='||CHR(10)); 
  
    lc_location_name := fnd_profile.value('XX_CDH_OWB_LOCATION') ;
    lc_dblink_name   := fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME');
   
    UPDATE xx_owb_crmbatch_status
    SET    aops_start_timestamp = TO_CHAR(SYSDATE, 'RRRR-MM-DD HH24:MI:SS' )
          ,aops_xxcnv_status    = 'P'
          ,aops_source          = TRIM(lc_dblink_name)
    WHERE  aops_batch_id = p_aops_batch_id;
    
    IF SQL%ROWCOUNT = 0 THEN
       INSERT INTO xx_owb_crmbatch_status 
            (   aops_batch_id 
               ,aops_start_timestamp
               ,aops_xxcnv_status
               ,aops_source 
            )
       VALUES 
            (   p_aops_batch_id
               ,TO_CHAR(SYSDATE, 'RRRR-MM-DD HH24:MI:SS' )
               ,'P'
               ,TRIM(lc_dblink_name)
            );
    END IF ;
   
    lc_custom_params := 'p_aops_batch_id='||p_aops_batch_id||', P_CUSTOM_MAX_ERRORS='||p_custom_max_errors||', P_AOPS_SOURCE='||TRIM(lc_dblink_name)||', P_LOCATION_NM='||lc_location_name;
   
    execute immediate 'alter session set current_schema=OWB_RT' ;    
    ln_exec_return_code := wb_rt_api_exec.run_task(p_location_name=>lc_location_name,
                                                   p_task_type=>'PROCESSFLOW',
                                                   p_task_name=>'PF_C0024_EXTRACT_NA_N',
                                                   p_custom_params=>lc_custom_params,
                                                   p_oem_friendly=>0,
                                                   p_background=>0);

    FOR cur_ebs_batchi_d in l_cur_ebs_batchi_d
    LOOP
       lc_ebs_batch_id := cur_ebs_batchi_d.EBS_BATCH_ID ;
    END LOOP ;
    
    get_owb_run_status(
                 lc_run_status
                ,lc_run_details
                ,lc_ebs_batch_id
                ,'EXTRACT'
                      ) ;
    --IF lc_run_status != 'OK' then
    --   x_errbuf  := '****ERROR****';
    --   x_retcode := '2';
    --END IF;
    
    IF ln_exec_return_code = 1 THEN       -- SUCCESS
       x_retcode := 0;
    ELSIF ln_exec_return_code = 2 THEN    -- WARNING
       x_retcode := 1;
    ELSIF ln_exec_return_code = 3 THEN    -- ERROR   
       x_retcode := 2;
    END IF;  
    
    fnd_file.put_line (fnd_file.log,CHR(10)||'============= EXTRACT STATUS ==============');
    fnd_file.put_line (fnd_file.log,CHR(10)|| lc_run_details );
    
    execute immediate 'alter session set current_schema=' || lc_current_user ;  
    
    log_debug_msg(CHR(10)|| '#########################################################');
    log_debug_msg('AOPS Batch Id : ' || to_char(p_aops_batch_id));
    log_debug_msg('EBS  Batch Id : ' || to_char(lc_ebs_batch_id));
    log_debug_msg('#########################################################');

/*
    UPDATE xx_owb_crmbatch_status
    SET    aops_end_timestamp   = TO_CHAR(SYSDATE,'RRRR-MM-DD HH24:MI:SS')
          ,aops_xxcnv_status    = 'C'
    WHERE aops_batch_id = ln_aops_batch_id;
*/
    log_debug_msg(CHR(10)||'============= Procedure RUN_OWB_PF_LOAD ==============');
    log_debug_msg('======================       END        ========================');

EXCEPTION
   WHEN le_skip_procedure THEN
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
      x_retcode   := 0;
   WHEN OTHERS THEN
      execute immediate 'alter session set current_schema=' || lc_current_user ;  
      x_errbuf    :='Others Exception in RUN_OWB_PF_LOAD procedure '||SQLERRM;
      x_retcode   :='2';
END run_owb_pf_extract;

-- +===================================================================+
-- | Name        : post_extract_update_aops                            |
-- | Description : This program is used to update org_id into the      |
-- |               common view tables after the OWB Extract.           |
-- |               **THIS IS ONLY FOR AOPS CUSTOMERS**                 |
-- |                                                                   |
-- | Parameters  :  p_batch_id                                         |
-- | Parameters  :  p_process_yn                                       |
-- | Parameters  :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE post_extract_update_aops
      (  x_errbuf                           OUT VARCHAR2
        ,x_retcode                          OUT VARCHAR2
        ,p_batch_id                         IN  NUMBER
        ,p_process_yn                       IN  VARCHAR2)
AS
ld_sysdate                                  DATE         := SYSDATE;
lv_os_name                                  VARCHAR2(30) := 'A0';
ln_us_org_id                                NUMBER       := 0;
ln_ca_org_id                                NUMBER       := 0;
lv_return_status                  VARCHAR2(10);
ln_msg_count                      NUMBER;
lv_msg_data                       VARCHAR2(2000);
le_skip_procedure                           EXCEPTION;
lc_target_value1                            VARCHAR2(240) ;
lc_target_value2                            VARCHAR2(240) ;
ln_org_id                                   NUMBER;
le_skip_country_loop                        EXCEPTION;
ln_act_record_id                            NUMBER;
ln_rows_updated                             NUMBER;
rec_exists                                  NUMBER;
l_orig_sys_Rec                              HZ_ORIG_SYSTEM_REF_PUB.orig_sys_reference_rec_type;
p_osr_value                                 VARCHAR2(50);
p_return_status                             VARCHAR2(10);
p_msg_data                                  VARCHAR2(2000);
p_msg_count                                 NUMBER;
l_upd_site_id                               NUMBER;
l_site_use_primary_flag                     VARCHAR2(10);
l_upd_site_use_id                           NUMBER;
l_transaction_error                         BOOLEAN := FALSE;
lr_orig_sys_reference_rec         HZ_ORIG_SYSTEM_REF_PUB.orig_sys_reference_rec_type;
lr_def_orig_sys_reference_rec     HZ_ORIG_SYSTEM_REF_PUB.orig_sys_reference_rec_type;

l_attr_group_id                             NUMBER;
l_old_attr_group_id                         NUMBER;

TYPE lt_aops_batch_cur_type     IS REF CURSOR;
lc_aops_batch_cur               lt_aops_batch_cur_type;

l_batch_type_sql                VARCHAR2(2000);
lv_aops_table_name              VARCHAR2(500);
l_delta_batch                   VARCHAR2(30)  := 'NOT_DELTA';
lc_ab_flag                      VARCHAR2(1);
lc_customer_status              VARCHAR2(1) := null;
lc_customer_type                HZ_CUST_ACCOUNTS.ATTRIBUTE18%TYPE := null;

lc_prof_class_modify            VARCHAR2(1);  
ln_profile_class_id             HZ_CUST_PROFILE_CLASSES.PROFILE_CLASS_ID%TYPE;  
lc_prof_class_name              HZ_CUST_PROFILE_CLASSES.NAME%TYPE;   
lc_retain_collect_cd            VARCHAR2(1); 
ln_collector_id                 HZ_CUSTOMER_PROFILES.COLLECTOR_ID%TYPE; 
lc_collector_name               AR_COLLECTORS.NAME%TYPE;
ln_errbuf                       VARCHAR2(2000);            
lc_prof_return_status           VARCHAR2(1);
l_chk_val                       NUMBER;
-- Cursor to Read Records from Addresses CV tables


CURSOR site_osr_cur IS 
SELECT attribute19,site_orig_system,site_orig_system_reference,created_by_module 
FROM xxod_hz_imp_addresses_int
WHERE batch_id = p_batch_id; 

TYPE l_site_tbl_type IS TABLE OF site_osr_cur%ROWTYPE;
l_site_tbl l_site_tbl_type;

-- Cursor to Read Records from Party CV tables

CURSOR party_osr_cur IS 
SELECT party_id,party_orig_system,party_orig_system_reference,created_by_module 
FROM xxod_hz_imp_parties_int
WHERE batch_id = p_batch_id;

TYPE l_party_tbl_type IS TABLE OF party_osr_cur%ROWTYPE;
l_party_tbl l_party_tbl_type;

-- Cursor to Read Records from Contacts CV tables

CURSOR contact_osr_cur IS
SELECT attribute19,contact_orig_system,contact_orig_system_reference,created_by_module 
FROM xxod_hz_imp_contacts_int
WHERE batch_id = p_batch_id;

TYPE l_contact_tbl_type IS TABLE OF contact_osr_cur%ROWTYPE;
l_contact_tbl l_contact_tbl_type;

-- Cursor to Read Records from Contact Points CV tables

CURSOR cp_osr_cur IS 
SELECT attribute19,cp_orig_system,cp_orig_system_reference,created_by_module 
FROM xxod_hz_imp_contactpts_int
WHERE batch_id = p_batch_id;

TYPE l_cp_tbl_type IS TABLE OF cp_osr_cur%ROWTYPE;
l_cp_tbl l_cp_tbl_type;



CURSOR lc_oper_unit_countries_cur
IS
SELECT xval.target_value2                   country
FROM   xx_fin_translatedefinition           xdef,
       xx_fin_translatevalues               xval
WHERE  xdef.translation_name                = 'XXOD_CDH_CONV_COUNTRY'
AND    xdef.translate_id                    = xval.translate_id
AND    xval.target_value3                   IS NOT NULL
AND    xval.source_value1                   = lv_os_name
AND    TRUNC  (SYSDATE) BETWEEN TRUNC(NVL(xval.start_date_active, SYSDATE -1)) AND TRUNC(NVL(xval.end_date_active, SYSDATE + 1))
ORDER  BY target_value3;

CURSOR lc_fetch_country_sites_cur
   (   p_country          VARCHAR2,
       p_os_name          VARCHAR2,
       p_batch_id         NUMBER
   )
IS
SELECT asu.acct_site_orig_system_ref
FROM   xxod_hz_imp_addresses_int            ai,
       xxod_hz_imp_acct_siteuses_int        asu
WHERE  ai.batch_id                          = p_batch_id
AND    ai.country                           = p_country
AND    ai.site_orig_system_reference NOT LIKE '%00001%'
AND    ai.site_orig_system                  = p_os_name
AND    asu.batch_id                         = p_batch_id
AND    asu.acct_site_orig_system            = p_os_name
AND    ai.site_orig_system_reference        = asu.acct_site_orig_system_ref
AND    asu.site_use_code                    = 'SHIP_TO'
AND    asu.org_id                          IS NULL;


CURSOR lc_fetch_one_acct_site_cur
   (   p_country          VARCHAR2,
       p_os_name          VARCHAR2,
       p_batch_id         NUMBER
   )
IS
SELECT site_orig_system_reference
FROM   xxod_hz_imp_addresses_int            xai
WHERE  xai.batch_id                         = p_batch_id
AND    xai.site_orig_system                 = p_os_name
AND    xai.country                          = p_country
AND    xai.site_orig_system_reference IN    ( SELECT account_orig_system_reference
                                              FROM   xxod_hz_imp_account_sites_int xas
                                              WHERE  xas.batch_id                  = p_batch_id
                                              AND    xas.acct_site_orig_system     = p_os_name
                                              AND    xas.org_id                   IS NULL
                                              GROUP  BY xas.account_orig_system_reference
                                              HAVING COUNT(*) = 1
                                            );
TYPE lt_site_uses_rec IS RECORD
   (  acct_site_orig_system_ref             xxod_hz_imp_acct_siteuses_int.acct_site_orig_system_ref%TYPE  );

TYPE lc_fetch_con_sites_tbl_type            IS TABLE OF lt_site_uses_rec INDEX BY BINARY_INTEGER;
lc_fetch_country_sites_tbl                  lc_fetch_con_sites_tbl_type;



CURSOR lc_fetch_orphan_site_uses_cur
   (  p_in_batch_id               NUMBER,
      p_in_os_name                VARCHAR2
   )
IS
SELECT xacs.account_orig_system_reference,
       hcas.org_id
FROM   apps.hz_orig_sys_references          hosr,
       apps.hz_cust_acct_sites_all          hcas,
       apps.xxod_hz_imp_account_sites_int   xacs
WHERE  hosr.orig_system_reference           = xacs.account_orig_system_reference
AND    xacs.batch_id                        = p_in_batch_id
AND    xacs.org_id                         IS NULL
AND    hosr.owner_table_name                = 'HZ_CUST_ACCT_SITES_ALL'
AND    hosr.status                          = 'A'
AND    hosr.orig_system                     = p_in_os_name
AND    hcas.cust_acct_site_id               = hosr.owner_table_id;

----------------------------
-- New Cursors added 09-OCT
----------------------------

CURSOR lc_fetch_direct_sites_cur
   (   p_country          VARCHAR2,
       p_os_name          VARCHAR2,
       p_batch_id         NUMBER
   )
IS
SELECT ai.site_orig_system_reference
FROM   xxod_hz_imp_addresses_int     ai
WHERE  ai.batch_id                   = p_batch_id
AND    ai.country                    = p_country
AND    ai.site_orig_system           = p_os_name
AND EXISTS
         (SELECT 1
          FROM   xxod_hz_imp_accounts_int a
          WHERE  a.batch_id                            = ai.batch_id
          AND    TRIM(a.account_orig_system)           = ai.site_orig_system
          --AND    COALESCE(a.org_id,0)                  = 0
          AND    TRIM(a.customer_attribute18)          = 'DIRECT'
          AND    TRIM(a.account_orig_system_reference) = TRIM(ai.party_orig_system_reference)
         );

CURSOR lc_fetch_ca_ship_to_cur
   (   p_os_name          VARCHAR2,
       p_batch_id         NUMBER,
       p_us_org_id        NUMBER
   )
IS
SELECT asi.account_orig_system_reference account_orig_system_reference
FROM   xxod_hz_imp_account_sites_int    asi
WHERE  asi.batch_id                     = p_batch_id
AND    asi.acct_site_orig_system        = p_os_name
AND    REGEXP_LIKE(asi.acct_site_orig_system_ref,'-00001-')
AND    asi.org_id                       = p_us_org_id
AND    ( EXISTS ( SELECT 1
                  FROM   xxod_hz_imp_account_sites_int      asi1
                  WHERE  asi1.batch_id                      = p_batch_id
                  AND    asi1.account_orig_system_reference = asi.account_orig_system_reference
                  AND    asi1.account_orig_system           = p_os_name
                  AND    asi1.org_id                       <> p_us_org_id
                )
         OR 
         EXISTS ( SELECT 1
                  FROM   hz_orig_sys_references     hosr
                  WHERE  hosr.orig_system           = p_os_name
                  AND    hosr.status                = 'A'
                  AND    hosr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
                  AND    hosr.orig_system_reference = asi.account_orig_system_reference||'CA'
                )
       )
AND EXISTS
         (SELECT 1
          FROM   xxod_hz_imp_accounts_int a
          WHERE  a.batch_id                            = asi.batch_id
          AND    TRIM(a.account_orig_system)           = asi.site_orig_system
          --AND    COALESCE(a.org_id,0)                  = 0
          AND    TRIM(a.customer_attribute18)          = 'DIRECT'
          AND    TRIM(a.account_orig_system_reference) = TRIM(asi.account_orig_system_reference)
         )
AND NOT EXISTS
         ( SELECT 1
           FROM xxod_hz_imp_account_sites_int asi2
           WHERE asi2.batch_id = p_batch_id
           AND asi2.acct_site_orig_system_ref = asi.account_orig_system_reference || 'CA');
  

CURSOR lc_fetch_us_ship_to_cur
   (   p_os_name          VARCHAR2,
       p_batch_id         NUMBER,
       p_ca_org_id        NUMBER
   )
IS
SELECT asi.account_orig_system_reference account_orig_system_reference 
FROM   xxod_hz_imp_account_sites_int    asi
WHERE  asi.batch_id                     = p_batch_id
AND    asi.acct_site_orig_system        = p_os_name
AND    REGEXP_LIKE(asi.acct_site_orig_system_ref,'-00001-')
AND    asi.org_id                       = p_ca_org_id
/*AND    ( EXISTS ( SELECT 1
                FROM   xxod_hz_imp_account_sites_int      asi1
                WHERE  asi1.batch_id                      = p_batch_id
                AND    asi1.account_orig_system_reference = asi.account_orig_system_reference
                AND    asi1.account_orig_system           = p_os_name
                AND    asi1.org_id                       <> p_ca_org_id
              )
       OR
        EXISTS ( SELECT 1
                  FROM   hz_orig_sys_references     hosr
                  WHERE  hosr.orig_system           = p_os_name
                  AND    hosr.status                = 'A'
                  AND    hosr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
                  AND    hosr.orig_system_reference = RTRIM(asi.account_orig_system_reference,'CA')
                )
       ) */
AND EXISTS
         (SELECT 1
          FROM   xxod_hz_imp_accounts_int a
          WHERE  a.batch_id                            = asi.batch_id
          AND    TRIM(a.account_orig_system)           = asi.site_orig_system
          --AND    COALESCE(a.org_id,0)                  = 0
          AND    TRIM(a.customer_attribute18)          = 'DIRECT'
          AND    TRIM(a.account_orig_system_reference) = RTRIM(TRIM(asi.account_orig_system_reference),'CA')
         )
AND NOT EXISTS
         ( SELECT 1
           FROM xxod_hz_imp_account_sites_int asi2
           WHERE asi2.batch_id = p_batch_id
           AND asi2.acct_site_orig_system_ref = asi.account_orig_system_reference);
  

CURSOR country_values_direct (p_batch_id   NUMBER, p_orig_system  VARCHAR2)
IS
SELECT cs.cust_acct_Site_id,cs.cust_account_id,cs.party_site_id,asi.org_id
       ,cs.orig_system_reference,osr.orig_system_ref_id,osr.object_version_number
FROM XXOD_HZ_IMP_ACCOUNT_SITES_INT asi,  hz_cust_acct_sites_all cs,  hz_orig_sys_references osr
WHERE asi.batch_id=p_batch_id
AND TRIM(asi.acct_site_orig_system_ref)=cs.orig_system_reference
AND osr.orig_system_reference = cs.orig_system_reference
AND osr.orig_system = p_orig_system
AND osr.owner_table_name = 'HZ_CUST_ACCT_SITES_ALL'
AND osr.owner_table_id = cs.cust_acct_site_id
AND osr.status = 'A'
AND TRIM(asi.acct_site_orig_system_ref) NOT LIKE '%0001%'
AND asi.org_id <> cs.org_id
AND cs.status = 'A'
AND EXISTS (SELECT 1
          FROM    xxod_hz_imp_accounts_int a
          WHERE  a.batch_id                            = asi.batch_id
          AND    TRIM(a.account_orig_system)           = asi.site_orig_system
          --AND    COALESCE(a.org_id,0)                  = 0
          AND    TRIM(a.customer_attribute18)          = 'DIRECT'
          AND    TRIM(a.account_orig_system_reference) = TRIM(asi.account_orig_system_reference)
         );

CURSOR site_use_inactive_cur (p_cust_site_id   NUMBER, p_orig_system  VARCHAR2)
IS
SELECT suse.orig_system_reference,osr.orig_system_ref_id,osr.object_version_number,site_use_id,suse.primary_flag
FROM hz_orig_sys_references osr,hz_cust_site_uses_all suse
WHERE suse.cust_acct_site_id=p_cust_site_id
AND osr.orig_system_reference = suse.orig_system_reference
AND osr.orig_system = p_orig_system
AND osr.owner_table_name = 'HZ_CUST_SITE_USES_ALL'
AND osr.owner_table_id = suse.site_use_id
AND osr.status = 'A'
AND suse.status = 'A';

CURSOR insert_site_use_cur (p_batch_id   NUMBER, p_site_use_id  NUMBER)
IS
SELECT suse.*,site.orig_system_Reference site_osr,acct.orig_system_reference acct_osr
FROM hz_cust_site_uses_all suse,hz_cust_acct_sites_all site, hz_cust_accounts acct
WHERE suse.site_use_id = p_site_use_id
AND site.cust_acct_site_id=suse.cust_acct_site_id
AND acct.cust_account_id = site.cust_account_id
AND suse.orig_system_reference NOT IN
(
select TRIM(i.ACCT_SITE_ORIG_SYSTEM_REF) || '-' || TRIM(i.SITE_USE_CODE)  from XXOD_HZ_IMP_ACCT_SITEUSES_INT i
WHERE i.batch_id = p_batch_id
); 

-- New Cursor added 09-OCT ENDS              

CURSOR c_billdocs (p_batch_id NUMBER) 
IS
SELECT  party_orig_system,
        account_orig_system_reference,
        customer_attribute18
FROM    XXOD_HZ_IMP_ACCOUNTS_INT 
WHERE   batch_id = p_batch_id;

--New cursor for Rel 1.1
cursor c_billdoc_exist ( p_orig_system_reference VARCHAR2, 
                          p_attr_group_id        NUMBER
                        )
IS                        
SELECT 1
FROM   HZ_CUST_ACCOUNTS acct,
       XX_CDH_CUST_ACCT_EXT_B extb
WHERE acct.orig_system_reference  = p_orig_system_reference 
AND   extb.cust_account_id        = acct.cust_account_id
AND   acct.status = 'A'
AND   extb.attr_group_id = p_attr_group_id;

cursor c_profile_records ( p_batch_id              NUMBER)
is
select trim(acct.account_orig_system_reference) account_orig_system_reference,
       trim(acct.customer_attribute18) customer_attribute18,
       trim(acct.customer_status) customer_status,
       trim(prof.attribute3) attribute3,
       trim(prof.attribute4) attribute4,
       nvl(trim(prof.customer_profile_class_name),'SFA') customer_profile_class_name
from   XXOD_HZ_IMP_ACCT_PROFILES_INT prof,
       XXOD_HZ_IMP_ACCOUNTS_INT      acct
where  prof.batch_id = p_batch_id
and    acct.batch_id = p_batch_id
and    trim(prof.account_orig_system_reference) = trim(acct.account_orig_system_reference);

cursor c_ab_flag ( p_orig_system_reference VARCHAR2, 
                   p_batch_id              NUMBER
		  )
is
select trim(attribute3)
from   XXOD_HZ_IMP_ACCT_PROFILES_INT 
where  batch_id = p_batch_id
and    trim(account_orig_system_reference) = p_orig_system_reference;

cursor c_ext_attr_id ( p_attr_group_name varchar2,
                       p_attr_group_type varchar2
                     )
is
     SELECT attr_group_id
       FROM ego_attr_groups_v
      WHERE application_id = 222
        AND attr_group_name = p_attr_group_name
        AND attr_group_type = p_attr_group_type;

lv_acct_osr                            VARCHAR2(2000);

BEGIN

   IF p_process_yn = 'N' THEN
      RAISE le_skip_procedure;
   END IF;

   log_debug_msg('=====================  BEGIN   =======================');
   log_debug_msg('=== Calling Post Extract Update: AOPS             ===='||CHR(10));

   BEGIN
       SELECT hos.orig_system
       INTO   lv_os_name
       FROM   apps.hz_orig_systems_vl hos
       WHERE  hos.orig_system_name = 'AOPS';
   EXCEPTION
      WHEN OTHERS THEN
         lv_os_name := 'A0';
   END;
   log_debug_msg('Original System Name: ' || lv_os_name);

   -------------------------------------
   -- Step 1: Set all the countries   --
   -------------------------------------
   UPDATE apps.xxod_hz_imp_addresses_int xhiai
   SET    country = (   SELECT nvl(xval.target_value1, xhiai.country)
                        FROM   apps.xx_fin_translatedefinition xdef,
                               apps.xx_fin_translatevalues xval
                        WHERE  xdef.translation_name = 'XXOD_CDH_CONV_COUNTRY' AND
                               xdef.translate_id     = xval.translate_id AND
                               xval.enabled_flag     = 'Y' AND
                               xdef.enabled_flag     = 'Y' AND
                               TRUNC(ld_sysdate) BETWEEN TRUNC(nvl(xval.start_date_active, ld_sysdate -1)) AND TRUNC(nvl(xval.end_date_active, ld_sysdate + 1)) AND
                               xval.source_value1    = lv_os_name AND
                               xval.source_value2    = xhiai.country_iso_3
                    )
   WHERE batch_id = p_batch_id;

   COMMIT;
   log_debug_msg('Country update ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   -----------------------------------------------------------------
   -- Update all records to null org_id to facilitate multiple runs
   -----------------------------------------------------------------

   UPDATE xxod_hz_imp_accounts_int
   SET    org_id    = NULL
   WHERE  batch_id  = p_batch_id;

   UPDATE xxod_hz_imp_account_sites_int
   SET    org_id    = NULL
   WHERE  batch_id  = p_batch_id;

   UPDATE xxod_hz_imp_acct_siteuses_int
   SET    org_id    = NULL
   WHERE  batch_id  = p_batch_id;

   UPDATE xxod_hz_customer_banks_int
   SET    org_id    = NULL
   WHERE  batch_id  = p_batch_id;

   UPDATE xxod_hz_imp_acct_profiles_int
   SET    org_id    = NULL
   WHERE  batch_id  = p_batch_id;

   COMMIT;

   ln_rows_updated := 0;
   ---------------------------------------------------------
   -- Step 1.1 - Update org_id for already existing accounts
   ----------------------------------------------------------

   UPDATE xxod_hz_imp_accounts_int xact
   SET    org_id = ( SELECT hcas.org_id
                     FROM   apps.hz_orig_sys_references hosr,
                            apps.hz_cust_acct_sites_all hcas
                     WHERE  hosr.orig_system_reference = xact.account_orig_system_reference
                     AND    hosr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
                     AND    hosr.status                = 'A'
                     AND    hosr.orig_system           = lv_os_name
                     AND    hcas.cust_acct_site_id     = hosr.owner_table_id
                   )
   WHERE  xact.batch_id = p_batch_id
   AND    TRIM(xact.customer_attribute18)          = 'CONTRACT'
   AND    xact.org_id  IS NULL;

   ln_rows_updated := SQL%ROWCOUNT;

   log_debug_msg('Update 1.1.1 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   COMMIT;

   IF ln_rows_updated > 0 THEN

      UPDATE apps.xxod_hz_imp_account_sites_int asi
      SET    org_id = (   SELECT org_id
                          FROM   apps.xxod_hz_imp_accounts_int a
                          WHERE  asi.account_orig_system_reference = a.account_orig_system_reference
                          AND    a.account_orig_system             = asi.account_orig_system
                          AND    a.batch_id                        = p_batch_id
                          AND    TRIM(a.customer_attribute18)      = 'CONTRACT'
                          AND    rownum                            = 1 
                      )
      WHERE batch_id = p_batch_id
      AND   asi.org_id IS NULL;

      log_debug_msg('Update 1.1.2 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
      COMMIT;

      UPDATE apps.xxod_hz_imp_acct_siteuses_int asui
      SET    asui.org_id = (   SELECT org_id
                               FROM   apps.xxod_hz_imp_accounts_int a
                               WHERE  a.account_orig_system_reference = asui.account_orig_system_reference 
                               AND    a.account_orig_system           = asui.account_orig_system
                               AND    a.batch_id                      = p_batch_id
                               AND    TRIM(a.customer_attribute18)    = 'CONTRACT'
                           )
      WHERE asui.batch_id = p_batch_id
      AND   asui.org_id  IS NULL;
      log_debug_msg('Update 1.1.3 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
      COMMIT;

      UPDATE apps.xxod_hz_customer_banks_int bank
      SET org_id = (   SELECT org_id
                       FROM   apps.xxod_hz_imp_accounts_int a
                       WHERE  bank.account_orig_system_reference = a.account_orig_system_reference 
                       AND    a.account_orig_system              = bank.account_orig_system 
                       AND    a.batch_id                         = p_batch_id
                       AND    TRIM(a.customer_attribute18)       = 'CONTRACT'       
                   )
      WHERE bank.batch_id = p_batch_id
      AND   bank.org_id  IS NULL;
      log_debug_msg('Update 1.1.4 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
      COMMIT;

      UPDATE apps.xxod_hz_imp_acct_profiles_int prof
      SET org_id = (   SELECT org_id
                       FROM   apps.xxod_hz_imp_accounts_int a
                       WHERE  prof.account_orig_system_reference = a.account_orig_system_reference 
                       AND    a.account_orig_system              = prof.account_orig_system 
                       AND    a.batch_id                         = p_batch_id
                       AND    TRIM(a.customer_attribute18)       = 'CONTRACT'
                   )
      WHERE prof.batch_id = p_batch_id
      AND   prof.org_id  IS NULL;
      log_debug_msg('Update 1.1.5 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
      COMMIT;
   END IF;

   ln_rows_updated := 0;
   ---------------------------------------------------------------
   -- Step 1.2 - Update org_id for already existing account sites
   ---------------------------------------------------------------
   FOR lc_fetch_orphan_site_uses_rec IN lc_fetch_orphan_site_uses_cur ( p_batch_id, lv_os_name)
   LOOP

      UPDATE xxod_hz_imp_account_sites_int
      SET    org_id                        = lc_fetch_orphan_site_uses_rec.org_id
      WHERE  org_id                       IS NULL
      AND    batch_id                      = p_batch_id
      AND    account_orig_system_reference = lc_fetch_orphan_site_uses_rec.account_orig_system_reference;


      UPDATE xxod_hz_imp_acct_siteuses_int
      SET    org_id                        = lc_fetch_orphan_site_uses_rec.org_id
      WHERE  org_id                       IS NULL
      AND    batch_id                      = p_batch_id
      AND    account_orig_system_reference = lc_fetch_orphan_site_uses_rec.account_orig_system_reference;

      UPDATE xxod_hz_customer_banks_int
      SET    org_id                        = lc_fetch_orphan_site_uses_rec.org_id
      WHERE  org_id                       IS NULL
      AND    batch_id                      = p_batch_id
      AND    account_orig_system_reference = lc_fetch_orphan_site_uses_rec.account_orig_system_reference;

      UPDATE apps.xxod_hz_imp_acct_profiles_int
      SET    org_id                        = lc_fetch_orphan_site_uses_rec.org_id
      WHERE  org_id                       IS NULL
      AND    batch_id                      = p_batch_id
      AND    account_orig_system_reference = lc_fetch_orphan_site_uses_rec.account_orig_system_reference;

      COMMIT;
   END LOOP;

   log_debug_msg('Update 1.2 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   ---------------------------------------------------------------
   -- Step 1.3 - Update org_id for already existing account banks
   ---------------------------------------------------------------
   UPDATE xxod_hz_customer_banks_int bank
   SET    org_id = ( SELECT hcas.org_id
                     FROM   apps.hz_orig_sys_references hosr,
                            apps.hz_cust_acct_sites_all hcas
                     WHERE  hosr.orig_system_reference = bank.account_orig_system_reference
                     AND    hosr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
                     AND    hosr.status                = 'A'
                     AND    hosr.orig_system           = lv_os_name
                     AND    hcas.cust_acct_site_id     = hosr.owner_table_id
                   )
   WHERE  bank.batch_id = p_batch_id
   AND    bank.org_id  IS NULL;

   log_debug_msg('Update 1.3 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
   COMMIT;

   ---------------------------------------------------------------
   -- Step 1.4 - Update org_id for already existing account profiles
   ---------------------------------------------------------------
   UPDATE xxod_hz_imp_acct_profiles_int prof
   SET    org_id = ( SELECT hcas.org_id
                     FROM   apps.hz_orig_sys_references hosr,
                            apps.hz_cust_acct_sites_all hcas
                     WHERE  hosr.orig_system_reference = prof.account_orig_system_reference
                     AND    hosr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
                     AND    hosr.status                = 'A'
                     AND    hosr.orig_system           = lv_os_name
                     AND    hcas.cust_acct_site_id     = hosr.owner_table_id
                   )
   WHERE  prof.batch_id = p_batch_id
   AND    prof.org_id  IS NULL;

   log_debug_msg('Update 1.4 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
   COMMIT;

   -------------------------------------------------------------------
   -- Step 1.5 - Update org_id for already existing account site uses
   -------------------------------------------------------------------
   UPDATE xxod_hz_imp_acct_siteuses_int asui
   SET    org_id = ( SELECT hcas.org_id
                     FROM   apps.hz_orig_sys_references hosr,
                            apps.hz_cust_acct_sites_all hcas
                     WHERE  hosr.orig_system_reference = asui.account_orig_system_reference
                     AND    hosr.owner_table_name      = 'HZ_CUST_ACCT_SITES_ALL'
                     AND    hosr.status                = 'A'
                     AND    hosr.orig_system           = lv_os_name
                     AND    hcas.cust_acct_site_id     = hosr.owner_table_id
                   )
   WHERE  asui.batch_id = p_batch_id
   AND    asui.org_id  IS NULL;
   log_debug_msg('Update 1.5 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   COMMIT;


   -------------------------------------------
   -- Start Regular Processing
   -- Step 2: Get org_id for ranked countries
   -------------------------------------------

   FOR lc_oper_unit_countries_rec IN lc_oper_unit_countries_cur
   LOOP
      BEGIN
         ----------------
         -- Fetch Org Id
         ----------------

         BEGIN
            SELECT hou.organization_id
            INTO   ln_org_id
            FROM   xx_fin_translatedefinition xdef,
                   xx_fin_translatevalues     xval,
                   hr_organization_units_v    hou
            WHERE  xdef.translation_name         = 'OD_COUNTRY_DEFAULTS'
            AND    xdef.translate_id             = xval.translate_id
            AND    xval.enabled_flag             = 'Y'
            AND    xdef.enabled_flag             = 'Y'
            AND    TRUNC(ld_sysdate) BETWEEN TRUNC(NVL(xval.start_date_active, ld_sysdate -1)) AND TRUNC(NVL(xval.end_date_active, ld_sysdate + 1))
            AND    xval.source_value1            = lc_oper_unit_countries_rec.country
            AND    hou.name                      = xval.target_value2;

            log_debug_msg('Org Id' || ln_org_id);


         EXCEPTION
            WHEN OTHERS THEN
               log_debug_msg('Unexpected Error while fetching org_id for country - '||lc_oper_unit_countries_rec.country);
               log_debug_msg('Error - '||SQLERRM);
               RAISE le_skip_country_loop;
         END;

         ----------------------------------------------------------------------
         -- Processing for Accounts having multiple sites
         -- For mutiple sites, if any site other than 00001 has Canada address,
         -- Account qualifies as Canada Operating Unit
         -- 11-July-2008 - Changed this logic only for Contract Customers
         ----------------------------------------------------------------------

         OPEN lc_fetch_country_sites_cur ( lc_oper_unit_countries_rec.country, lv_os_name, p_batch_id );
         LOOP

            FETCH lc_fetch_country_sites_cur BULK COLLECT INTO lc_fetch_country_sites_tbl LIMIT gn_bulk_fetch_limit;

            IF lc_fetch_country_sites_tbl.COUNT > 0 THEN
               --log_debug_msg( 'No eligible sites exist in the staging table for country - '||lc_oper_unit_countries_rec.country);
               --RAISE le_skip_country_loop;
            --END IF;

               FOR i IN lc_fetch_country_sites_tbl.FIRST .. lc_fetch_country_sites_tbl.LAST
               LOOP

                  BEGIN
                     UPDATE xxod_hz_imp_accounts_int
                     SET    org_id                           = ln_org_id
                     WHERE  batch_id                         = p_batch_id
                     AND    org_id                          IS NULL
                     AND    account_orig_system              = lv_os_name
                     AND    TRIM(customer_attribute18)       = 'CONTRACT'
                     AND    account_orig_system_reference LIKE SUBSTR(lc_fetch_country_sites_tbl(i).acct_site_orig_system_ref, 1, 8)||'%';

                  EXCEPTION
                     WHEN OTHERS THEN
                        log_debug_msg ('Unexpected Exception while updating XXOD_HZ_IMP_ACCOUNTS_INT - '||SUBSTR(lc_fetch_country_sites_tbl(i).acct_site_orig_system_ref, 1, 8)||'%');
                        log_debug_msg ('Error - '||SQLERRM);
                  END;

               END LOOP;
               COMMIT;
            END IF;

            EXIT WHEN lc_fetch_country_sites_cur%NOTFOUND;

         END LOOP;
         CLOSE lc_fetch_country_sites_cur;

         COMMIT;
         log_debug_msg('Account - OrgId update for Other countries 1 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

         -------------------------------------------------------
         -- Processing for Accounts having only one site
         -- For single site, if it has Canada address,
         -- Account qualifies as Canada Operating Unit
         -- 11-July-2008 - Changed this logic only for Contract Customers
         -------------------------------------------------------
         OPEN lc_fetch_one_acct_site_cur ( lc_oper_unit_countries_rec.country, lv_os_name, p_batch_id );
         LOOP

            FETCH lc_fetch_one_acct_site_cur BULK COLLECT INTO lc_fetch_country_sites_tbl LIMIT gn_bulk_fetch_limit;
            IF lc_fetch_country_sites_tbl.COUNT > 0 THEN
               --log_debug_msg( 'No eligible sites exist in the staging table for country - '||lc_oper_unit_countries_rec.country);
               --RAISE le_skip_country_loop;
            --END IF;

               FOR i IN lc_fetch_country_sites_tbl.FIRST .. lc_fetch_country_sites_tbl.LAST
               LOOP
                  BEGIN
                     UPDATE xxod_hz_imp_accounts_int
                     SET    org_id                           = ln_org_id
                     WHERE  batch_id                         = p_batch_id
                     AND    org_id                          IS NULL
                     AND    account_orig_system              = lv_os_name
                     AND    TRIM(customer_attribute18)       = 'CONTRACT'
                     AND    account_orig_system_reference LIKE SUBSTR(lc_fetch_country_sites_tbl(i).acct_site_orig_system_ref, 1, 8)||'%';
                  EXCEPTION
                     WHEN OTHERS THEN
                        log_debug_msg ('Unexpected Exception while updating XXOD_HZ_IMP_ACCOUNTS_INT - '||SUBSTR(lc_fetch_country_sites_tbl(i).acct_site_orig_system_ref, 1, 8)||'%');
                        log_debug_msg ('Error - '||SQLERRM);
                  END;
               END LOOP;
               COMMIT;
            END IF;

            EXIT WHEN lc_fetch_one_acct_site_cur%NOTFOUND;

         END LOOP;
         CLOSE lc_fetch_one_acct_site_cur;
         COMMIT;
         log_debug_msg('Account - OrgId update for Other countries 2 ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
         
         ------------------------------------------------------------------
         -- Processing for DIRECT Customers - Org Id Determined by Country
         -- Added 11-July
         ------------------------------------------------------------------
         
         FOR lc_fetch_direct_sites_rec IN lc_fetch_direct_sites_cur (lc_oper_unit_countries_rec.country, lv_os_name, p_batch_id)
         LOOP
         
            IF lc_fetch_direct_sites_rec.site_orig_system_reference LIKE '%00001%' THEN
               UPDATE xxod_hz_imp_account_sites_int
               SET    org_id                    = ln_org_id,
                      acct_site_orig_system_ref = lc_fetch_direct_sites_rec.site_orig_system_reference||'CA'
               --WHERE  org_id                   IS NULL
               WHERE  batch_id                  = p_batch_id
               AND    acct_site_orig_system     = lv_os_name
               AND    acct_site_orig_system_ref = lc_fetch_direct_sites_rec.site_orig_system_reference;

               UPDATE xxod_hz_imp_acct_siteuses_int
               SET    org_id                    = ln_org_id,
                      acct_site_orig_system_ref = lc_fetch_direct_sites_rec.site_orig_system_reference||'CA'
               --WHERE  org_id                   IS NULL
               WHERE  batch_id                  = p_batch_id
               AND    acct_site_orig_system     = lv_os_name
               AND    acct_site_orig_system_ref = lc_fetch_direct_sites_rec.site_orig_system_reference;
            ELSE
               UPDATE xxod_hz_imp_account_sites_int
               SET    org_id                    = ln_org_id
               --WHERE  org_id                   IS NULL
               WHERE   batch_id                  = p_batch_id
               AND    acct_site_orig_system     = lv_os_name
               AND    acct_site_orig_system_ref = lc_fetch_direct_sites_rec.site_orig_system_reference;

               UPDATE xxod_hz_imp_acct_siteuses_int
               SET    org_id                    = ln_org_id
               --WHERE  org_id                   IS NULL
               WHERE  batch_id                  = p_batch_id
               AND    acct_site_orig_system     = lv_os_name
               AND    acct_site_orig_system_ref = lc_fetch_direct_sites_rec.site_orig_system_reference;
            END IF;
         
         END LOOP;

      EXCEPTION
         WHEN le_skip_country_loop THEN
            NULL;
      END;
   END LOOP;

   -------------------------------------------
   -- Step 3: Get org_id for US country
   -------------------------------------------

   BEGIN
      SELECT hou.organization_id
      INTO   ln_us_org_id
      FROM   xx_fin_translatedefinition    xdef,
             xx_fin_translatevalues        xval,
             hr_organization_units_v       hou
      WHERE  xdef.translation_name         = 'OD_COUNTRY_DEFAULTS'
      AND    xdef.translate_id             = xval.translate_id
      AND    xval.enabled_flag             = 'Y'
      AND    xdef.enabled_flag             = 'Y'
      AND    TRUNC(ld_sysdate) BETWEEN TRUNC(NVL(xval.start_date_active, ld_sysdate -1)) AND TRUNC(NVL(xval.end_date_active, ld_sysdate + 1))
      AND    xval.source_value1            = 'US'
      AND    hou.name                      = xval.target_value2;
   EXCEPTION
      WHEN OTHERS THEN
         log_debug_msg('Unexpected Error while fetching org_id for US');
         log_debug_msg('Error - '||SQLERRM);
         RAISE le_skip_procedure;
   END;

   -----------------------------------------------------------
   -- All accounts not having org_id so far will be set to US
   -----------------------------------------------------------

   UPDATE xxod_hz_imp_accounts_int
   SET    org_id            = ln_us_org_id
   WHERE  batch_id          = p_batch_id
   AND    TRIM(customer_attribute18) = 'CONTRACT'
   AND    org_id           IS NULL;
   COMMIT;
   log_debug_msg('Account - OrgId update for US ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   --------------------------------------------------
   -- Step 4: Update the account sites to account OU
   --------------------------------------------------
   UPDATE apps.xxod_hz_imp_account_sites_int asi
   SET    org_id = (   SELECT org_id
                       FROM   apps.xxod_hz_imp_accounts_int a
                       WHERE  asi.account_orig_system_reference = a.account_orig_system_reference 
                       AND    a.account_orig_system             = asi.account_orig_system 
                       AND    a.batch_id                        = p_batch_id 
                       AND    a.org_id                         IS NOT NULL
                       AND    TRIM(customer_attribute18)        = 'CONTRACT'
                       AND    rownum                            = 1
                   )
   WHERE asi.batch_id = p_batch_id
   AND   asi.org_id IS NULL;
   COMMIT;
   log_debug_msg('Account Site - OrgId update ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   --------------------------------------------------------------------------------------
   -- Step 5: Go back to the account-sites-use and set them all to what is on the account
   --------------------------------------------------------------------------------------
   UPDATE apps.xxod_hz_imp_acct_siteuses_int asui
   SET    asui.org_id = (   SELECT org_id
                            FROM   apps.xxod_hz_imp_accounts_int a
                            WHERE  a.account_orig_system_reference = asui.account_orig_system_reference 
                            AND    a.account_orig_system           = asui.account_orig_system 
                            AND    a.org_id                       IS NOT NULL
                            AND    TRIM(customer_attribute18)      = 'CONTRACT'
                            AND    a.batch_id                      = p_batch_id
                        )
   WHERE asui.batch_id = p_batch_id
   AND   asui.org_id IS NULL;
   COMMIT;
   log_debug_msg('Account Site Uses - OrgId update (other site uses) ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   ----------------------------------------------
   -- Step 6: Update the bank to account org
   ----------------------------------------------
   UPDATE apps.xxod_hz_customer_banks_int bank
   SET org_id = (   SELECT org_id
                    FROM   apps.xxod_hz_imp_accounts_int a
                    WHERE  bank.account_orig_system_reference = a.account_orig_system_reference
                    AND    a.account_orig_system              = bank.account_orig_system
                    AND    a.batch_id                         = p_batch_id
                    AND    a.org_id                      IS NOT NULL
                    AND    TRIM(customer_attribute18)         = 'CONTRACT'
                )
   WHERE bank.batch_id = p_batch_id
   AND   bank.org_id IS NULL;
   COMMIT;
   log_debug_msg('Banks - OrgId update ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   ----------------------------------------------------
   -- Step 7: Update the profile org-id to account org
   ----------------------------------------------------
   UPDATE apps.xxod_hz_imp_acct_profiles_int prof
   SET org_id = (   SELECT org_id
                    FROM   apps.xxod_hz_imp_accounts_int a
                    WHERE  prof.account_orig_system_reference = a.account_orig_system_reference
                    AND    a.account_orig_system              = prof.account_orig_system
                    AND    a.batch_id                         = p_batch_id
                    AND    a.org_id                      IS NOT NULL
                    AND    TRIM(customer_attribute18)         = 'CONTRACT'
                )
   WHERE prof.batch_id = p_batch_id
   AND   prof.org_id IS NULL;
   COMMIT;
   log_debug_msg('Account Profiles - OrgId update ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
   
   ----------------------------------------------------
   -- Step 8: Update all remaining sites to US org
   ----------------------------------------------------
   
   UPDATE xxod_hz_imp_account_sites_int
   SET    org_id                    = ln_us_org_id
   WHERE  org_id                   IS NULL
   AND    batch_id                  = p_batch_id;
   
   UPDATE xxod_hz_imp_acct_siteuses_int
   SET    org_id                    = ln_us_org_id
   WHERE  org_id                   IS NULL
   AND    batch_id                  = p_batch_id;
   
   UPDATE xxod_hz_imp_acct_profiles_int
   SET    org_id                    = ln_us_org_id
   WHERE  org_id                   IS NULL
   AND    batch_id                  = p_batch_id;
   
   COMMIT;
   log_debug_msg('Direct Customers Step8 - US OrgId update ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));
   
   ---------------------
   -- Get Canada Org Id
   ---------------------
   
   BEGIN
      SELECT hou.organization_id
      INTO   ln_ca_org_id
      FROM   xx_fin_translatedefinition    xdef,
             xx_fin_translatevalues        xval,
             hr_organization_units_v       hou
      WHERE  xdef.translation_name         = 'OD_COUNTRY_DEFAULTS'
      AND    xdef.translate_id             = xval.translate_id
      AND    xval.enabled_flag             = 'Y'
      AND    xdef.enabled_flag             = 'Y'
      AND    TRUNC(ld_sysdate) BETWEEN TRUNC(NVL(xval.start_date_active, ld_sysdate -1)) AND TRUNC(NVL(xval.end_date_active, ld_sysdate + 1))
      AND    xval.source_value1            = 'CA'
      AND    hou.name                      = xval.target_value2;
   EXCEPTION
      WHEN OTHERS THEN
         log_debug_msg('Unexpected Error while fetching org_id for CA');
         log_debug_msg('Error - '||SQLERRM);
         RAISE le_skip_procedure;
   END;
   
   ----------------------------------------------------------
   -- Step 10: Duplicate CA Bill_to in US if 
   --          there exists a canada site
   ----------------------------------------------------------

   lv_acct_osr := '@';

   FOR lc_fetch_us_ship_to_rec IN lc_fetch_us_ship_to_cur( lv_os_name, p_batch_id, ln_ca_org_id)
   LOOP
       
      IF lv_acct_osr <> lc_fetch_us_ship_to_rec.account_orig_system_reference THEN
        
         INSERT INTO xxod_hz_imp_account_sites_int
            (   batch_id                               ,
                created_by                             ,
                created_by_module                      ,
                creation_date                          ,
                error_id                               ,
                insert_update_flag                     ,
                interface_status                       ,
                last_update_date                       ,
                last_update_login                      ,
                last_updated_by                        ,
                program_application_id                 ,
                program_id                             ,
                program_update_date                    ,
                request_id                             ,
                party_orig_system                      ,
                party_orig_system_reference            ,
                account_orig_system                    ,
                account_orig_system_reference          ,
                site_orig_system                       ,
                site_orig_system_reference             ,
                address_attribute_category             ,
                address_attribute1                     ,
                address_attribute2                     ,
                address_attribute3                     ,
                address_attribute4                     ,
                address_attribute5                     ,
                address_attribute6                     ,
                address_attribute7                     ,
                address_attribute8                     ,
                address_attribute9                     ,
                address_attribute10                    ,
                address_attribute11                    ,
                address_attribute12                    ,
                address_attribute13                    ,
                address_attribute14                    ,
                address_attribute15                    ,
                address_attribute16                    ,
                address_attribute17                    ,
                address_attribute18                    ,
                address_attribute19                    ,
                address_attribute20                    ,
                address_category_code                  ,
                bill_to_orig_address_ref               ,
                gdf_address_attr_cat                   ,
                gdf_address_attribute1                 ,
                gdf_address_attribute2                 ,
                gdf_address_attribute3                 ,
                gdf_address_attribute4                 ,
                gdf_address_attribute5                 ,
                gdf_address_attribute6                 ,
                gdf_address_attribute7                 ,
                gdf_address_attribute8                 ,
                gdf_address_attribute9                 ,
                gdf_address_attribute10                ,
                gdf_address_attribute11                ,
                gdf_address_attribute12                ,
                gdf_address_attribute13                ,
                gdf_address_attribute14                ,
                gdf_address_attribute15                ,
                gdf_address_attribute16                ,
                gdf_address_attribute17                ,
                gdf_address_attribute18                ,
                gdf_address_attribute19                ,
                gdf_address_attribute20                ,
                site_ship_via_code                     ,
                location                               ,
                location_ccid                          ,
                acct_site_orig_system_ref              ,
                acct_site_orig_system                  ,
                org_id
             )
         SELECT batch_id                               ,
                created_by                             ,
                created_by_module                      ,
                creation_date                          ,
                error_id                               ,
                insert_update_flag                     ,
                interface_status                       ,
                last_update_date                       ,
                last_update_login                      ,
                last_updated_by                        ,
                program_application_id                 ,
                program_id                             ,
                program_update_date                    ,
                request_id                             ,
                party_orig_system                      ,
                party_orig_system_reference            ,
                account_orig_system                    ,
                account_orig_system_reference          ,
                site_orig_system                       ,
                site_orig_system_reference             ,
                address_attribute_category             ,
                address_attribute1                     ,
                address_attribute2                     ,
                address_attribute3                     ,
                address_attribute4                     ,
                address_attribute5                     ,
                address_attribute6                     ,
                address_attribute7                     ,
                address_attribute8                     ,
                address_attribute9                     ,
                address_attribute10                    ,
                address_attribute11                    ,
                address_attribute12                    ,
                address_attribute13                    ,
                address_attribute14                    ,
                address_attribute15                    ,
                address_attribute16                    ,
                address_attribute17                    ,
                address_attribute18                    ,
                address_attribute19                    ,
                address_attribute20                    ,
                address_category_code                  ,
                bill_to_orig_address_ref               ,
                gdf_address_attr_cat                   ,
                gdf_address_attribute1                 ,
                gdf_address_attribute2                 ,
                gdf_address_attribute3                 ,
                gdf_address_attribute4                 ,
                gdf_address_attribute5                 ,
                gdf_address_attribute6                 ,
                gdf_address_attribute7                 ,
                gdf_address_attribute8                 ,
                gdf_address_attribute9                 ,
                gdf_address_attribute10                ,
                gdf_address_attribute11                ,
                gdf_address_attribute12                ,
                gdf_address_attribute13                ,
                gdf_address_attribute14                ,
                gdf_address_attribute15                ,
                gdf_address_attribute16                ,
                gdf_address_attribute17                ,
                gdf_address_attribute18                ,
                gdf_address_attribute19                ,
                gdf_address_attribute20                ,
                site_ship_via_code                     ,
                location                               ,
                location_ccid                          ,
                RTRIM(acct_site_orig_system_ref,'CA')  ,
                acct_site_orig_system                  ,
                ln_us_org_id
         FROM   xxod_hz_imp_account_sites_int
         WHERE  batch_id                  = p_batch_id
         AND    acct_site_orig_system_ref = lc_fetch_us_ship_to_rec.account_orig_system_reference || 'CA';

         INSERT INTO xxod_hz_imp_acct_siteuses_int
            (   batch_id                              ,
                created_by                            ,
                created_by_module                     ,
                creation_date                         ,
                error_id                              ,
                insert_update_flag                    ,
                interface_status                      ,
                last_update_date                      ,
                last_update_login                     ,
                last_updated_by                       ,
                program_application_id                ,
                program_id                            ,
                program_update_date                   ,
                request_id                            ,
                party_orig_system                     ,
                party_orig_system_reference           ,
                acct_site_orig_system                 ,
                acct_site_orig_system_ref             ,
                account_orig_system                   ,
                account_orig_system_reference         ,
                gdf_site_use_attr_cat                 ,
                gdf_site_use_attribute1               ,
                gdf_site_use_attribute2               ,
                gdf_site_use_attribute3               ,
                gdf_site_use_attribute4               ,
                gdf_site_use_attribute5               ,
                gdf_site_use_attribute6               ,
                gdf_site_use_attribute7               ,
                gdf_site_use_attribute8               ,
                gdf_site_use_attribute9               ,
                gdf_site_use_attribute10              ,
                gdf_site_use_attribute11              ,
                gdf_site_use_attribute12              ,
                gdf_site_use_attribute13              ,
                gdf_site_use_attribute14              ,
                gdf_site_use_attribute15              ,
                gdf_site_use_attribute16              ,
                gdf_site_use_attribute17              ,
                gdf_site_use_attribute18              ,
                gdf_site_use_attribute19              ,
                gdf_site_use_attribute20              ,
                site_use_attribute_category           ,
                site_use_attribute1                   ,
                site_use_attribute2                   ,
                site_use_attribute3                   ,
                site_use_attribute4                   ,
                site_use_attribute5                   ,
                site_use_attribute6                   ,
                site_use_attribute7                   ,
                site_use_attribute8                   ,
                site_use_attribute9                   ,
                site_use_attribute10                  ,
                site_use_attribute11                  ,
                site_use_attribute12                  ,
                site_use_attribute13                  ,
                site_use_attribute14                  ,
                site_use_attribute15                  ,
                site_use_attribute16                  ,
                site_use_attribute17                  ,
                site_use_attribute18                  ,
                site_use_attribute19                  ,
                site_use_attribute20                  ,
                site_use_attribute21                  ,
                site_use_attribute22                  ,
                site_use_attribute23                  ,
                site_use_attribute24                  ,
                site_use_attribute25                  ,
                site_use_code                         ,
                site_use_tax_code                     ,
                site_use_tax_exempt_num               ,
                site_use_tax_reference                ,
                org_id                                ,
                validated_flag                        ,
                demand_class_code                     ,
                gl_id_clearing                        ,
                gl_id_factor                          ,
                gl_id_freight                         ,
                gl_id_rec                             ,
                gl_id_remittance                      ,
                gl_id_rev                             ,
                gl_id_tax                             ,
                gl_id_unbilled                        ,
                gl_id_unearned                        ,
                gl_id_unpaid_rec                      ,
                site_ship_via_code                    ,
                location                              ,
                bill_to_orig_system                   ,
                bill_to_orig_address_ref              ,
                primary_flag
            )
         SELECT batch_id                              ,
                created_by                            ,
                created_by_module                     ,
                creation_date                         ,
                error_id                              ,
                insert_update_flag                    ,
                interface_status                      ,
                last_update_date                      ,
                last_update_login                     ,
                last_updated_by                       ,
                program_application_id                ,
                program_id                            ,
                program_update_date                   ,
                request_id                            ,
                party_orig_system                     ,
                party_orig_system_reference           ,
                acct_site_orig_system                 ,
                RTRIM(acct_site_orig_system_ref,'CA') ,
                account_orig_system                   ,
                account_orig_system_reference         ,
                gdf_site_use_attr_cat                 ,
                gdf_site_use_attribute1               ,
                gdf_site_use_attribute2               ,
                gdf_site_use_attribute3               ,
                gdf_site_use_attribute4               ,
                gdf_site_use_attribute5               ,
                gdf_site_use_attribute6               ,
                gdf_site_use_attribute7               ,
                gdf_site_use_attribute8               ,
                gdf_site_use_attribute9               ,
                gdf_site_use_attribute10              ,
                gdf_site_use_attribute11              ,
                gdf_site_use_attribute12              ,
                gdf_site_use_attribute13              ,
                gdf_site_use_attribute14              ,
                gdf_site_use_attribute15              ,
                gdf_site_use_attribute16              ,
                gdf_site_use_attribute17              ,
                gdf_site_use_attribute18              ,
                gdf_site_use_attribute19              ,
                gdf_site_use_attribute20              ,
                site_use_attribute_category           ,
                site_use_attribute1                   ,
                site_use_attribute2                   ,
                site_use_attribute3                   ,
                site_use_attribute4                   ,
                site_use_attribute5                   ,
                site_use_attribute6                   ,
                site_use_attribute7                   ,
                site_use_attribute8                   ,
                site_use_attribute9                   ,
                site_use_attribute10                  ,
                site_use_attribute11                  ,
                site_use_attribute12                  ,
                site_use_attribute13                  ,
                site_use_attribute14                  ,
                site_use_attribute15                  ,
                site_use_attribute16                  ,
                site_use_attribute17                  ,
                site_use_attribute18                  ,
                site_use_attribute19                  ,
                site_use_attribute20                  ,
                site_use_attribute21                  ,
                site_use_attribute22                  ,
                site_use_attribute23                  ,
                site_use_attribute24                  ,
                site_use_attribute25                  ,
                site_use_code                         ,
                site_use_tax_code                     ,
                site_use_tax_exempt_num               ,
                site_use_tax_reference                ,
                ln_us_org_id                          ,
                validated_flag                        ,
                demand_class_code                     ,
                gl_id_clearing                        ,
                gl_id_factor                          ,
                gl_id_freight                         ,
                gl_id_rec                             ,
                gl_id_remittance                      ,
                gl_id_rev                             ,
                gl_id_tax                             ,
                gl_id_unbilled                        ,
                gl_id_unearned                        ,
                gl_id_unpaid_rec                      ,
                site_ship_via_code                    ,
                location                              ,
                bill_to_orig_system                   ,
                bill_to_orig_address_ref              ,
                primary_flag
         FROM   xxod_hz_imp_acct_siteuses_int
         WHERE  batch_id                  = p_batch_id
         AND    site_use_code             = 'BILL_TO'
         AND    acct_site_orig_system_ref = lc_fetch_us_ship_to_rec.account_orig_system_reference||'CA';

         lv_acct_osr := lc_fetch_us_ship_to_rec.account_orig_system_reference;
      END IF;
   END LOOP;

   log_debug_msg('Direct Customers Step10 - ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));

   
   
   ----------------------------------------------------------
   -- Step 9: Duplicate US Bill_to in Canada if 
   --         there exists a canada site
   ----------------------------------------------------------
   
   lv_acct_osr := '@';  
   
   FOR lc_fetch_ca_ship_to_rec IN lc_fetch_ca_ship_to_cur( lv_os_name, p_batch_id, ln_us_org_id)
   LOOP
     
      log_debug_msg('Inside CA shipto Loop - ');
      log_debug_msg('lv_acct_osr - '||lv_acct_osr);
      log_debug_msg('account_orig_system_reference - '||lc_fetch_ca_ship_to_rec.account_orig_system_reference);
      
      IF lv_acct_osr <> lc_fetch_ca_ship_to_rec.account_orig_system_reference THEN
         
         BEGIN
            INSERT INTO xxod_hz_imp_account_sites_int
               (   batch_id                               ,
                   created_by                             ,
                   created_by_module                      ,
                   creation_date                          ,
                   error_id                               ,
                   insert_update_flag                     ,
                   interface_status                       ,
                   last_update_date                       ,
                   last_update_login                      ,
                   last_updated_by                        ,
                   program_application_id                 ,
                   program_id                             ,
                   program_update_date                    ,
                   request_id                             ,
                   party_orig_system                      ,
                   party_orig_system_reference            ,
                   account_orig_system                    ,
                   account_orig_system_reference          ,
                   site_orig_system                       ,
                   site_orig_system_reference             ,
                   address_attribute_category             ,
                   address_attribute1                     ,
                   address_attribute2                     ,
                   address_attribute3                     ,
                   address_attribute4                     ,
                   address_attribute5                     ,
                   address_attribute6                     ,
                   address_attribute7                     ,
                   address_attribute8                     ,
                   address_attribute9                     ,
                   address_attribute10                    ,
                   address_attribute11                    ,
                   address_attribute12                    ,
                   address_attribute13                    ,
                   address_attribute14                    ,
                   address_attribute15                    ,
                   address_attribute16                    ,
                   address_attribute17                    ,
                   address_attribute18                    ,
                   address_attribute19                    ,
                   address_attribute20                    ,
                   address_category_code                  ,
                   bill_to_orig_address_ref               ,
                   gdf_address_attr_cat                   ,
                   gdf_address_attribute1                 ,
                   gdf_address_attribute2                 ,
                   gdf_address_attribute3                 ,
                   gdf_address_attribute4                 ,
                   gdf_address_attribute5                 ,
                   gdf_address_attribute6                 ,
                   gdf_address_attribute7                 ,
                   gdf_address_attribute8                 ,
                   gdf_address_attribute9                 ,
                   gdf_address_attribute10                ,
                   gdf_address_attribute11                ,
                   gdf_address_attribute12                ,
                   gdf_address_attribute13                ,
                   gdf_address_attribute14                ,
                   gdf_address_attribute15                ,
                   gdf_address_attribute16                ,
                   gdf_address_attribute17                ,
                   gdf_address_attribute18                ,
                   gdf_address_attribute19                ,
                   gdf_address_attribute20                ,
                   site_ship_via_code                     ,
                   location                               ,
                   location_ccid                          ,
                   acct_site_orig_system_ref              ,
                   acct_site_orig_system                  ,
                   org_id
                )
            SELECT batch_id                               ,                   
                   created_by                             ,
                   created_by_module                      ,
                   creation_date                          ,
                   error_id                               ,
                   insert_update_flag                     ,
                   interface_status                       ,
                   last_update_date                       ,
                   last_update_login                      ,
                   last_updated_by                        ,
                   program_application_id                 ,
                   program_id                             ,
                   program_update_date                    ,
                   request_id                             ,
                   party_orig_system                      ,
                   party_orig_system_reference            ,
                   account_orig_system                    ,
                   account_orig_system_reference          ,
                   site_orig_system                       ,
                   site_orig_system_reference             ,
                   address_attribute_category             ,
                   address_attribute1                     ,
                   address_attribute2                     ,
                   address_attribute3                     ,
                   address_attribute4                     ,
                   address_attribute5                     ,
                   address_attribute6                     ,
                   address_attribute7                     ,
                   address_attribute8                     ,
                   address_attribute9                     ,
                   address_attribute10                    ,
                   address_attribute11                    ,
                   address_attribute12                    ,
                   address_attribute13                    ,
                   address_attribute14                    ,
                   address_attribute15                    ,
                   address_attribute16                    ,
                   address_attribute17                    ,
                   address_attribute18                    ,
                   address_attribute19                    ,
                   address_attribute20                    ,
                   address_category_code                  ,
                   bill_to_orig_address_ref               ,
                   gdf_address_attr_cat                   ,
                   gdf_address_attribute1                 ,
                   gdf_address_attribute2                 ,
                   gdf_address_attribute3                 ,
                   gdf_address_attribute4                 ,
                   gdf_address_attribute5                 ,
                   gdf_address_attribute6                 ,
                   gdf_address_attribute7                 ,
                   gdf_address_attribute8                 ,
                   gdf_address_attribute9                 ,
                   gdf_address_attribute10                ,
                   gdf_address_attribute11                ,
                   gdf_address_attribute12                ,
                   gdf_address_attribute13                ,
                   gdf_address_attribute14                ,
                   gdf_address_attribute15                ,
                   gdf_address_attribute16                ,
                   gdf_address_attribute17                ,
                   gdf_address_attribute18                ,
                   gdf_address_attribute19                ,
                   gdf_address_attribute20                ,
                   site_ship_via_code                     ,
                   location                               ,
                   location_ccid                          ,
                   acct_site_orig_system_ref||'CA'        ,
                   acct_site_orig_system                  ,
                   ln_ca_org_id
            FROM   xxod_hz_imp_account_sites_int
            WHERE  batch_id                  = p_batch_id
            AND    acct_site_orig_system_ref = lc_fetch_ca_ship_to_rec.account_orig_system_reference;

            log_debug_msg('Sites Inserted - '||SQL%ROWCOUNT);
         EXCEPTION
            WHEN OTHERS THEN
               log_debug_msg('error - '||SQLERRM);
         END;
         
         INSERT INTO XXOD_HZ_IMP_ACCT_SITEUSES_INT
            (   batch_id                              ,
                created_by                            , 
                created_by_module                     ,
                creation_date                         ,
                error_id                              ,
                insert_update_flag                    ,
                interface_status                      ,
                last_update_date                      ,
                last_update_login                     ,
                last_updated_by                       ,
                program_application_id                ,
                program_id                            ,
                program_update_date                   ,
                request_id                            ,
                party_orig_system                     ,
                party_orig_system_reference           ,
                acct_site_orig_system                 ,
                acct_site_orig_system_ref             ,
                account_orig_system                   ,
                account_orig_system_reference         ,
                gdf_site_use_attr_cat                 ,
                gdf_site_use_attribute1               ,
                gdf_site_use_attribute2               ,
                gdf_site_use_attribute3               ,
                gdf_site_use_attribute4               ,
                gdf_site_use_attribute5               ,
                gdf_site_use_attribute6               ,
                gdf_site_use_attribute7               ,
                gdf_site_use_attribute8               ,
                gdf_site_use_attribute9               ,
                gdf_site_use_attribute10              ,
                gdf_site_use_attribute11              ,
                gdf_site_use_attribute12              ,
                gdf_site_use_attribute13              ,
                gdf_site_use_attribute14              ,
                gdf_site_use_attribute15              ,
                gdf_site_use_attribute16              ,
                gdf_site_use_attribute17              ,
                gdf_site_use_attribute18              ,
                gdf_site_use_attribute19              ,
                gdf_site_use_attribute20              ,
                site_use_attribute_category           ,
                site_use_attribute1                   ,
                site_use_attribute2                   ,
                site_use_attribute3                   ,
                site_use_attribute4                   ,
                site_use_attribute5                   ,
                site_use_attribute6                   ,
                site_use_attribute7                   ,
                site_use_attribute8                   ,
                site_use_attribute9                   ,
                site_use_attribute10                  ,
                site_use_attribute11                  ,
                site_use_attribute12                  ,
                site_use_attribute13                  ,
                site_use_attribute14                  ,
                site_use_attribute15                  ,
                site_use_attribute16                  ,
                site_use_attribute17                  ,
                site_use_attribute18                  ,
                site_use_attribute19                  ,
                site_use_attribute20                  ,
                site_use_attribute21                  ,
                site_use_attribute22                  ,
                site_use_attribute23                  ,
                site_use_attribute24                  ,
                site_use_attribute25                  ,
                site_use_code                         ,
                site_use_tax_code                     ,
                site_use_tax_exempt_num               ,
                site_use_tax_reference                ,
                org_id                                ,
                validated_flag                        ,
                demand_class_code                     ,
                gl_id_clearing                        ,
                gl_id_factor                          ,
                gl_id_freight                         ,
                gl_id_rec                             ,
                gl_id_remittance                      ,
                gl_id_rev                             ,
                gl_id_tax                             ,
                gl_id_unbilled                        ,
                gl_id_unearned                        ,
                gl_id_unpaid_rec                      ,
                site_ship_via_code                    ,
                location                              ,
                bill_to_orig_system                   ,
                bill_to_orig_address_ref              ,
                primary_flag
            )
         SELECT batch_id                              ,
                created_by                            , 
                created_by_module                     ,
                creation_date                         ,
                error_id                              ,
                insert_update_flag                    ,
                interface_status                      ,
                last_update_date                      ,
                last_update_login                     ,
                last_updated_by                       ,
                program_application_id                ,
                program_id                            ,
                program_update_date                   ,
                request_id                            ,
                party_orig_system                     ,
                party_orig_system_reference           ,
                acct_site_orig_system                 ,
                acct_site_orig_system_ref||'CA'       ,
                account_orig_system                   ,
                account_orig_system_reference         ,
                gdf_site_use_attr_cat                 ,
                gdf_site_use_attribute1               ,
                gdf_site_use_attribute2               ,
                gdf_site_use_attribute3               ,
                gdf_site_use_attribute4               ,
                gdf_site_use_attribute5               ,
                gdf_site_use_attribute6               ,
                gdf_site_use_attribute7               ,
                gdf_site_use_attribute8               ,
                gdf_site_use_attribute9               ,
                gdf_site_use_attribute10              ,
                gdf_site_use_attribute11              ,
                gdf_site_use_attribute12              ,
                gdf_site_use_attribute13              ,
                gdf_site_use_attribute14              ,
                gdf_site_use_attribute15              ,
                gdf_site_use_attribute16              ,
                gdf_site_use_attribute17              ,
                gdf_site_use_attribute18              ,
                gdf_site_use_attribute19              ,
                gdf_site_use_attribute20              ,
                site_use_attribute_category           ,
                site_use_attribute1                   ,
                site_use_attribute2                   ,
                site_use_attribute3                   ,
                site_use_attribute4                   ,
                site_use_attribute5                   ,
                site_use_attribute6                   ,
                site_use_attribute7                   ,
                site_use_attribute8                   ,
                site_use_attribute9                   ,
                site_use_attribute10                  ,
                site_use_attribute11                  ,
                site_use_attribute12                  ,
                site_use_attribute13                  ,
                site_use_attribute14                  ,
                site_use_attribute15                  ,
                site_use_attribute16                  ,
                site_use_attribute17                  ,
                site_use_attribute18                  ,
                site_use_attribute19                  ,
                site_use_attribute20                  ,
                site_use_attribute21                  ,
                site_use_attribute22                  ,
                site_use_attribute23                  ,
                site_use_attribute24                  ,
                site_use_attribute25                  ,
                site_use_code                         ,
                site_use_tax_code                     ,
                site_use_tax_exempt_num               ,
                site_use_tax_reference                ,
                ln_ca_org_id                          ,
                validated_flag                        ,
                demand_class_code                     ,
                gl_id_clearing                        ,
                gl_id_factor                          ,
                gl_id_freight                         ,
                gl_id_rec                             ,
                gl_id_remittance                      ,
                gl_id_rev                             ,
                gl_id_tax                             ,
                gl_id_unbilled                        ,
                gl_id_unearned                        ,
                gl_id_unpaid_rec                      ,
                site_ship_via_code                    ,
                location                              ,
                bill_to_orig_system                   ,
                bill_to_orig_address_ref              ,
                primary_flag
         FROM   xxod_hz_imp_acct_siteuses_int
         WHERE  batch_id                  = p_batch_id
         AND    site_use_code             = 'BILL_TO'
         AND    acct_site_orig_system_ref = lc_fetch_ca_ship_to_rec.account_orig_system_reference;   
                
         log_debug_msg('Site Uses Inserted - '||SQL%ROWCOUNT);
         
         lv_acct_osr := lc_fetch_ca_ship_to_rec.account_orig_system_reference;
         
         COMMIT;
      END IF;

   END LOOP;

   COMMIT;
   log_debug_msg('Direct Customers Step9 - ... Complete. ' || to_char(sysdate, 'HH24:MI:SS'));


   ----------------------------------------------------------
   -- Step 11: Inactivate Old Site if country Changes 
   --          This applies only for direct customers
   -- Code added: 09-OCT-2008
   ----------------------------------------------------------

   FOR l_country_values_direct IN country_values_direct (p_batch_id,lv_os_name) LOOP
     BEGIN
      
       l_transaction_error := false; 
      
       SAVEPOINT org_country_changes;

       -- Inactivating Account Sites
       BEGIN
       
        SELECT cust_acct_site_id INTO l_upd_site_id
        FROM HZ_CUST_ACCT_SITES_ALL
        WHERE party_site_id = l_country_values_direct.party_site_id
        AND cust_account_id = l_country_values_direct.cust_account_id
        AND org_id = l_country_values_direct.org_id
        AND STATUS = 'I';
        
        UPDATE HZ_CUST_ACCT_SITES_ALL SET STATUS = 'A',last_update_date = SYSDATE
        WHERE cust_acct_site_id = l_upd_site_id;
        
        UPDATE hz_orig_sys_references SET status='A',end_date_active=NULL
        WHERE orig_system_reference = l_country_values_direct.orig_system_reference
        AND  orig_system = lv_os_name
        AND owner_table_id = l_upd_site_id
        AND owner_table_name = 'HZ_CUST_ACCT_SITES_ALL';
        
      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.log,'STEP 11: Error:' || SQLERRM);
        l_transaction_error := TRUE;
      END;
      
       UPDATE hz_cust_acct_sites_all
       SET status='I',
           last_update_date = SYSDATE
       WHERE cust_acct_site_id = l_country_values_direct.cust_acct_site_id;

       lr_orig_sys_reference_rec                       := lr_def_orig_sys_reference_rec;
       lr_orig_sys_reference_rec.orig_system_ref_id    := l_country_values_direct.orig_system_ref_id;
       lr_orig_sys_reference_rec.status                := 'I';
       lr_orig_sys_reference_rec.orig_system_reference := l_country_values_direct.orig_system_reference;
       lr_orig_sys_reference_rec.owner_table_name      := 'HZ_CUST_ACCT_SITES_ALL';
       lr_orig_sys_reference_rec.owner_table_id        := l_country_values_direct.cust_acct_site_id;
       lr_orig_sys_reference_rec.orig_system           := lv_os_name;
       lr_orig_sys_reference_rec.end_date_active       := TRUNC(SYSDATE);
       

       HZ_ORIG_SYSTEM_REF_PUB.update_orig_system_reference
            (   p_init_msg_list             => FND_API.G_TRUE,
                p_orig_sys_reference_rec    => lr_orig_sys_reference_rec,
                p_object_version_number     => l_country_values_direct.object_version_number,
                x_return_status             => lv_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lv_msg_data
            ); 
        
        IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           fnd_file.put_line (fnd_file.log,'STEP 11: Error:' || lv_msg_data);
           l_transaction_error := TRUE;
        END IF;
        
       -- Inactivation Account Site Uses
        
      FOR l_site_use_inactive_cur IN site_use_inactive_cur(l_country_values_direct.cust_acct_site_id,lv_os_name) LOOP
         
         l_site_use_primary_flag :=  l_site_use_inactive_cur.primary_flag;
         
          UPDATE hz_cust_site_uses_all
       	  SET primary_flag='N',
           	status='I',
           	last_update_date = SYSDATE
       	  WHERE site_use_id = l_site_use_inactive_cur.site_use_id;

       	lr_orig_sys_reference_rec                       := lr_def_orig_sys_reference_rec;
       	lr_orig_sys_reference_rec.orig_system_ref_id    := l_site_use_inactive_cur.orig_system_ref_id;
       	lr_orig_sys_reference_rec.status                := 'I';
        lr_orig_sys_reference_rec.orig_system_reference := l_site_use_inactive_cur.orig_system_reference;
        lr_orig_sys_reference_rec.owner_table_name      := 'HZ_CUST_ACCT_SITES_ALL';
        lr_orig_sys_reference_rec.owner_table_id        := l_site_use_inactive_cur.site_use_id;
        lr_orig_sys_reference_rec.orig_system           := lv_os_name;
       	lr_orig_sys_reference_rec.end_date_active       := TRUNC(SYSDATE);

       	HZ_ORIG_SYSTEM_REF_PUB.update_orig_system_reference
            (   p_init_msg_list             => FND_API.G_TRUE,
                p_orig_sys_reference_rec    => lr_orig_sys_reference_rec,
                p_object_version_number     => l_site_use_inactive_cur.object_version_number,
                x_return_status             => lv_return_status,
                x_msg_count                 => ln_msg_count,
                x_msg_data                  => lv_msg_data
            );
            
        IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
           fnd_file.put_line (fnd_file.log,'STEP 11: Error:' || lv_msg_data);
           l_transaction_error := TRUE;
        END IF;
            
         
       FOR l_copy_site_use IN insert_site_use_cur ( p_batch_id,  l_site_use_inactive_cur.site_use_id) LOOP
            
        BEGIN
       
        SELECT site_use_id INTO l_upd_site_use_id
        FROM HZ_CUST_SITE_USES_ALL
        WHERE cust_acct_site_id = l_copy_site_use.cust_acct_site_id
        AND site_use_code = l_copy_site_use.site_use_code
        AND org_id = l_country_values_direct.org_id;
        
        UPDATE HZ_CUST_SITE_USES_ALL SET STATUS = 'A',last_update_date = SYSDATE
        WHERE site_use_id = l_upd_site_use_id;
        
        UPDATE hz_orig_sys_references SET status='A',end_date_active=NULL
        WHERE orig_system_reference = l_copy_site_use.orig_system_reference
        AND  orig_system = lv_os_name
        AND owner_table_id = l_upd_site_use_id
        AND owner_table_name = 'HZ_CUST_SITE_USES_ALL';
        
      EXCEPTION WHEN NO_DATA_FOUND THEN
        NULL;
      WHEN OTHERS THEN
        fnd_file.put_line (fnd_file.log,'STEP 11: Error:' || SQLERRM);
        l_transaction_error := TRUE;
      END;
       
            INSERT INTO XXOD_HZ_IMP_ACCT_SITEUSES_INT
            (
                acct_site_orig_system_ref,
                acct_site_orig_system,
                party_orig_system_reference,
                party_orig_system,
                account_orig_system_reference,
                account_orig_system,
		--bill_to_orig_system,
		--bill_to_orig_address_ref,
                site_use_code,
                location,
                site_use_tax_reference,
                site_use_tax_code,
                site_use_attribute_category,
                site_use_attribute1,
                site_use_attribute2,
                site_use_attribute3,
                site_use_attribute4,
		site_use_attribute5,
		site_use_attribute6,
		site_use_attribute7,
		site_use_attribute8,
		site_use_attribute9,
		site_use_attribute10,
		site_use_attribute11,
		site_use_attribute12,
		site_use_attribute13,
		site_use_attribute14,
		site_use_attribute15,
		site_use_attribute16,
		site_use_attribute17,
		site_use_attribute18,
		site_use_attribute19,
		site_use_attribute20,
		site_use_attribute21,
		site_use_attribute22,
		site_use_attribute23,
		site_use_attribute24,
		site_use_attribute25,
		demand_class_code,
		gdf_site_use_attribute1,
 		gdf_site_use_attribute2,
		gdf_site_use_attribute3,
		gdf_site_use_attribute4,
		gdf_site_use_attribute5,
		gdf_site_use_attribute6,
		gdf_site_use_attribute7,
		gdf_site_use_attribute8,
		gdf_site_use_attribute9,
		gdf_site_use_attribute10,
		gdf_site_use_attribute11,
		gdf_site_use_attribute12,
		gdf_site_use_attribute13,
		gdf_site_use_attribute14,
		gdf_site_use_attribute15,
		gdf_site_use_attribute16,
		gdf_site_use_attribute17,
		gdf_site_use_attribute18,
		gdf_site_use_attribute19,
		gdf_site_use_attribute20,
		gdf_site_use_attr_cat,
		gl_id_rec,
		gl_id_rev,
		gl_id_tax,
		gl_id_freight,
		gl_id_clearing,
		gl_id_unbilled,
		gl_id_unearned,
		gl_id_unpaid_rec,
		gl_id_remittance,
		gl_id_factor,
		created_by_module,
		primary_flag,
                org_id,
                batch_id
             )  
             VALUES
             (
		l_copy_site_use.site_osr,
		lv_os_name,
                l_copy_site_use.acct_osr,
		lv_os_name,
		l_copy_site_use.acct_osr,
		lv_os_name,
                l_copy_site_use.site_use_code,
		--l_copy_site_use.bill_to_orig_system,
		--l_copy_site_use.bill_to_acct_site_ref,
		l_copy_site_use.location,
		l_copy_site_use.tax_reference,
                l_copy_site_use.tax_code,
		l_copy_site_use.attribute_category,
		l_copy_site_use.attribute1,
		l_copy_site_use.attribute2,
		l_copy_site_use.attribute3,
		l_copy_site_use.attribute4,
		l_copy_site_use.attribute5,
		l_copy_site_use.attribute6,
		l_copy_site_use.attribute7,
		l_copy_site_use.attribute8,
		l_copy_site_use.attribute9,
		l_copy_site_use.attribute10,
		l_copy_site_use.attribute11,
		l_copy_site_use.attribute12,
		l_copy_site_use.attribute13,
		l_copy_site_use.attribute14,
		l_copy_site_use.attribute15,
		l_copy_site_use.attribute16,
		l_copy_site_use.attribute17,
		l_copy_site_use.attribute18,
		l_copy_site_use.attribute19,
		l_copy_site_use.attribute20,
		l_copy_site_use.attribute21,
		l_copy_site_use.attribute22,
		l_copy_site_use.attribute23,
		l_copy_site_use.attribute24,
		l_copy_site_use.attribute25,
                l_copy_site_use.demand_class_code,
                l_copy_site_use.global_attribute1,
		l_copy_site_use.global_attribute2,
		l_copy_site_use.global_attribute3,
		l_copy_site_use.global_attribute4,
		l_copy_site_use.global_attribute5,
		l_copy_site_use.global_attribute6,
		l_copy_site_use.global_attribute7,
		l_copy_site_use.global_attribute8,
		l_copy_site_use.global_attribute9,
		l_copy_site_use.global_attribute10,
		l_copy_site_use.global_attribute11,
		l_copy_site_use.global_attribute12,
		l_copy_site_use.global_attribute13,
		l_copy_site_use.global_attribute14,
		l_copy_site_use.global_attribute15,
		l_copy_site_use.global_attribute16,
		l_copy_site_use.global_attribute17,
		l_copy_site_use.global_attribute18,
		l_copy_site_use.global_attribute19,
		l_copy_site_use.global_attribute20,
		l_copy_site_use.global_attribute_category,
		l_copy_site_use.gl_id_rec,
		l_copy_site_use.gl_id_rev,
		l_copy_site_use.gl_id_tax,
		l_copy_site_use.gl_id_freight,
		l_copy_site_use.gl_id_clearing,
		l_copy_site_use.gl_id_unbilled,
		l_copy_site_use.gl_id_unearned,
		l_copy_site_use.gl_id_unpaid_rec,
		l_copy_site_use.gl_id_remittance,
		l_copy_site_use.gl_id_factor,
		l_copy_site_use.created_by_module,
		l_site_use_primary_flag,
		l_country_values_direct.org_id,
		p_batch_id
               );
             
            END LOOP; 

       END LOOP; 
     
     EXCEPTION WHEN OTHERS THEN 
        fnd_file.put_line (fnd_file.log,'STEP 11: Error:' || SQLERRM);
        l_transaction_error := TRUE;  
     END;
     
     IF l_transaction_error THEN
        fnd_file.put_line (fnd_file.log,'STEP 11: For Account Site Could Not Be Processed ::' || l_country_values_direct.orig_system_reference);
        ROLLBACK TO org_country_changes;
     ELSE
        COMMIT;
     END IF;
     
   END LOOP; 
   
  -- Code added: 09-OCT-2008 ENDS
  
   log_debug_msg('=====================    End   =======================');
   log_debug_msg('=== Calling Post Extract Update: AOPS             ===='||CHR(10));


-- Update OS/OSR Values for Addresses

OPEN site_osr_cur;

 LOOP
    FETCH site_osr_cur BULK COLLECT INTO l_site_tbl LIMIT gn_bulk_fetch_limit;

    IF l_site_tbl.COUNT > 0 THEN
      FOR i IN l_site_tbl.FIRST .. l_site_tbl.LAST
      LOOP
       IF ((TRIM(l_site_tbl(i).attribute19) IS NOT NULL OR TRIM(l_site_tbl(i).attribute19) != '0')  AND TRIM(l_site_tbl(i).site_orig_system) IS NOT NULL 
           AND  TRIM(l_site_tbl(i).created_by_module) IS NOT NULL) THEN
                
          BEGIN
            p_osr_value := TRIM(l_site_tbl(i).attribute19);
            
            SELECT 1 INTO rec_exists
            FROM hz_orig_sys_references
            WHERE owner_table_name='HZ_PARTY_SITES'
            AND owner_table_id= TRIM(l_site_tbl(i).attribute19)
            AND status='A'
            AND orig_system = TRIM(l_site_tbl(i).site_orig_system)
            AND orig_system_reference = NVL(TRIM(l_site_tbl(i).site_orig_system_reference),p_osr_value);
            

          EXCEPTION WHEN OTHERS THEN
             l_orig_sys_Rec.orig_system := TRIM(l_site_tbl(i).site_orig_system);
             l_orig_sys_rec.orig_system_reference := NVL(TRIM(l_site_tbl(i).site_orig_system_reference),p_osr_value);
             l_orig_sys_rec.owner_table_id := TRIM(l_site_tbl(i).attribute19);
             l_orig_sys_rec.owner_table_name := 'HZ_PARTY_SITES';
             l_orig_sys_rec.created_by_module := TRIM(l_site_tbl(i).created_by_module);
            
                  HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference (
                     p_orig_sys_reference_rec => l_orig_sys_rec,
                     x_return_status          => p_return_status,
                     x_msg_count              => p_msg_count,
                     x_msg_data               => p_msg_data
                    );
                    
            IF TRIM(l_site_tbl(i).site_orig_system_reference) IS NULL THEN
              UPDATE xxod_hz_imp_addresses_int SET site_orig_system_reference = p_osr_value
              WHERE batch_id=p_batch_id AND attribute19 = TRIM(l_site_tbl(i).attribute19);
            END IF;   
                    
          END;
        END IF;       
      END LOOP;
      COMMIT;
    END IF;
    EXIT WHEN site_osr_cur%NOTFOUND;
 END LOOP;  
 
 -- Update OS/OSR Values for Party
 
 OPEN party_osr_cur;

 LOOP
    FETCH party_osr_cur BULK COLLECT INTO l_party_tbl LIMIT gn_bulk_fetch_limit;

    IF l_party_tbl.COUNT > 0 THEN
      FOR i IN l_party_tbl.FIRST .. l_party_tbl.LAST
      LOOP
       IF (TRIM(l_party_tbl(i).party_id) IS NOT NULL AND TRIM(l_party_tbl(i).party_orig_system) IS NOT NULL 
           AND  TRIM(l_party_tbl(i).created_by_module) IS NOT NULL) THEN
          BEGIN
            
            p_osr_value := TRIM(l_party_tbl(i).party_id);
            
            SELECT 1 INTO rec_exists
            FROM hz_orig_sys_references
            WHERE owner_table_name='HZ_PARTIES'
            AND owner_table_id= TRIM(l_party_tbl(i).party_id)
            AND status='A'
            AND orig_system = TRIM(l_party_tbl(i).party_orig_system)
            AND orig_system_reference = NVL(TRIM(l_party_tbl(i).party_orig_system_reference),p_osr_value);

          EXCEPTION WHEN OTHERS THEN
            l_orig_sys_Rec.orig_system := TRIM(l_party_tbl(i).party_orig_system);
            l_orig_sys_rec.orig_system_reference := NVL(TRIM(l_party_tbl(i).party_orig_system_reference),p_osr_value);
            l_orig_sys_rec.owner_table_id := TRIM(l_party_tbl(i).party_id);
            l_orig_sys_rec.owner_table_name := 'HZ_PARTIES';
            l_orig_sys_rec.created_by_module := TRIM(l_party_tbl(i).created_by_module);
            
             HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference (
                p_orig_sys_reference_rec => l_orig_sys_rec,
                x_return_status => p_return_status,
                x_msg_count => p_msg_count,
                x_msg_data => p_msg_data
               );
               
            IF TRIM(l_party_tbl(i).party_orig_system_reference) IS NULL THEN
              UPDATE xxod_hz_imp_parties_int SET party_orig_system_reference = p_osr_value
              WHERE batch_id=p_batch_id AND party_id = TRIM(l_party_tbl(i).party_id);
            END IF;      
               
          END;
        END IF;       
      END LOOP;
      COMMIT;
    END IF;
    EXIT WHEN party_osr_cur%NOTFOUND;
 END LOOP;  
 
 -- Update OS/OSR Values for Contacts
 
 OPEN contact_osr_cur;

 LOOP
    FETCH contact_osr_cur BULK COLLECT INTO l_contact_tbl LIMIT gn_bulk_fetch_limit;

    IF l_contact_tbl.COUNT > 0 THEN
      FOR i IN l_contact_tbl.FIRST .. l_contact_tbl.LAST
      LOOP
       IF ((TRIM(l_contact_tbl(i).attribute19) IS NOT NULL OR TRIM(l_contact_tbl(i).attribute19) != '0') AND TRIM(l_contact_tbl(i).contact_orig_system) IS NOT NULL 
          AND  TRIM(l_contact_tbl(i).created_by_module) IS NOT NULL) THEN
          
          BEGIN
            
            p_osr_value := TRIM(l_contact_tbl(i).attribute19);
            
            SELECT 1 INTO rec_exists
            FROM hz_orig_sys_references
            WHERE owner_table_name='HZ_ORG_CONTACTS'
            AND owner_table_id= TRIM(l_contact_tbl(i).attribute19)
            AND status='A'
            AND orig_system = TRIM(l_contact_tbl(i).contact_orig_system)
            AND orig_system_reference = NVL(TRIM(l_contact_tbl(i).contact_orig_system_reference),p_osr_value);

          EXCEPTION WHEN OTHERS THEN
            l_orig_sys_rec.orig_system := TRIM(l_contact_tbl(i).contact_orig_system);
            l_orig_sys_rec.orig_system_reference := NVL(TRIM(l_contact_tbl(i).contact_orig_system_reference),p_osr_value);
            l_orig_sys_rec.owner_table_id := TRIM(l_contact_tbl(i).attribute19);
            l_orig_sys_rec.owner_table_name := 'HZ_ORG_CONTACTS';
            l_orig_sys_rec.created_by_module := TRIM(l_contact_tbl(i).created_by_module);
             
                HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference (
                  p_orig_sys_reference_rec => l_orig_sys_rec,
                  x_return_status => p_return_status,
                  x_msg_count => p_msg_count,
                  x_msg_data => p_msg_data
                );
                
           IF TRIM(l_contact_tbl(i).contact_orig_system_reference) IS NULL THEN
              UPDATE xxod_hz_imp_contacts_int SET contact_orig_system_reference = p_osr_value
              WHERE batch_id=p_batch_id AND attribute19 = TRIM(l_contact_tbl(i).attribute19);
           END IF;           
                
         END;
       END IF;       
      END LOOP;
      COMMIT;
    END IF;
    EXIT WHEN contact_osr_cur%NOTFOUND;
 END LOOP;  
 
 -- Update OS/OSR Values for Contact Points
 
 OPEN cp_osr_cur;

 LOOP
    FETCH cp_osr_cur BULK COLLECT INTO l_cp_tbl LIMIT gn_bulk_fetch_limit;

    IF l_cp_tbl.COUNT > 0 THEN
      FOR i IN l_cp_tbl.FIRST .. l_cp_tbl.LAST
      LOOP
       IF ((TRIM(l_cp_tbl(i).attribute19) IS NOT NULL OR TRIM(l_cp_tbl(i).attribute19) != '0') AND TRIM(l_cp_tbl(i).cp_orig_system) IS NOT NULL 
           AND  TRIM(l_cp_tbl(i).created_by_module) IS NOT NULL) THEN
           
          BEGIN
            
            p_osr_value := TRIM(l_cp_tbl(i).attribute19);
            
            SELECT 1 INTO rec_exists
            FROM hz_orig_sys_references
            WHERE owner_table_name='HZ_CONTACT_POINTS'
            AND owner_table_id= TRIM(l_cp_tbl(i).attribute19)
            AND status='A'
            AND orig_system = TRIM(l_cp_tbl(i).cp_orig_system)
            AND orig_system_reference = NVL(TRIM(l_cp_tbl(i).cp_orig_system_reference),p_osr_value);

          EXCEPTION WHEN OTHERS THEN
            l_orig_sys_Rec.orig_system := TRIM(l_cp_tbl(i).cp_orig_system);
            l_orig_sys_rec.orig_system_reference := NVL(TRIM(l_cp_tbl(i).cp_orig_system_reference), p_osr_value);
            l_orig_sys_rec.owner_table_id := TRIM(l_cp_tbl(i).attribute19);
            l_orig_sys_rec.owner_table_name := 'HZ_CONTACT_POINTS';
            l_orig_sys_rec.created_by_module := TRIM(l_cp_tbl(i).created_by_module);

            HZ_ORIG_SYSTEM_REF_PUB.create_orig_system_reference (
               p_orig_sys_reference_rec => l_orig_sys_rec,
               x_return_status => p_return_status,
               x_msg_count => p_msg_count,
               x_msg_data => p_msg_data
              );
            
            IF TRIM(l_cp_tbl(i).cp_orig_system_reference) IS NULL THEN
              UPDATE xxod_hz_imp_contactpts_int SET cp_orig_system_reference = p_osr_value
              WHERE batch_id=p_batch_id AND attribute19 = TRIM(l_cp_tbl(i).attribute19);
            END IF;        

         END;
       END IF;     
      END LOOP;
      COMMIT;
    END IF;
    EXIT WHEN cp_osr_cur%NOTFOUND;
 END LOOP;  


   ----------------------------------------------------------------------------
   -- Modification 2.4 : Update existing BILLDOCS for the accounts in the batch 
   -- to the differect attribute group, OLD_BILLDOCS
   -- 02-Dec-2008
   ----------------------------------------------------------------------------
   begin
   
     lv_aops_table_name           := fnd_profile.value('XX_CDH_OWB_AOPS_DBLINK_NAME');
     l_batch_type_sql  :=  'SELECT ''DELTA'' 
                          FROM hz_imp_batch_summary bs,' || lv_aops_table_name ||
                         ' aops WHERE bs.batch_name = aops.orebatchf_aops_batch_id || '' - A0'' 
                           AND bs.batch_id=' || p_batch_id ||
                         ' AND aops.orebatchf_job_name LIKE ''DELTA%'' ' ;
                          
     OPEN lc_aops_batch_cur FOR  l_batch_type_sql;
     FETCH lc_aops_batch_cur INTO l_delta_batch;
     
     fnd_file.put_line (fnd_file.log,'BILLDOCS Batch Check SQL: ' || l_batch_type_sql);
     fnd_file.put_line(fnd_file.log,'');
     fnd_file.put_line(fnd_file.log,'Batch Type:' || l_delta_batch);
  
  
     --select attribute group id for OLD_BILLDOCS
     open c_ext_attr_id ( 'OLD_BILLDOCS', 'XX_CDH_CUST_ACCOUNT');
     fetch c_ext_attr_id into l_old_attr_group_id;
     close c_ext_attr_id;

     /*
     SELECT attr_group_id
      into  l_old_attr_group_id
       FROM ego_attr_groups_v
      WHERE application_id = 222
        AND attr_group_name = 'OLD_BILLDOCS'
        AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';
      */

     --select attribute group id for BILLDOCS
     open c_ext_attr_id ( 'BILLDOCS', 'XX_CDH_CUST_ACCOUNT');
     fetch c_ext_attr_id into l_attr_group_id;
     close c_ext_attr_id;
     /*
     SELECT attr_group_id
      into  l_attr_group_id
       FROM ego_attr_groups_v
      WHERE application_id = 222
        AND attr_group_name = 'BILLDOCS'
        AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';
     */
   --update existing BILLDOCS for the accounts in the batch to OLD_BILLDOCS
   
   IF l_delta_batch = 'NOT_DELTA' THEN

      UPDATE  XX_CDH_CUST_ACCT_EXT_B
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
				FROM  XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                      HZ_CUST_ACCOUNTS acct
                                WHERE acct.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
			     )
      and  attr_group_id=l_attr_group_id;

      UPDATE   XX_CDH_CUST_ACCT_EXT_TL
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
				FROM  XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                      HZ_CUST_ACCOUNTS acct
                                WHERE acct.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
			     )
        and  attr_group_id=l_attr_group_id;

        COMMIT;
    
    ELSE
    
      UPDATE  XX_CDH_CUST_ACCT_EXT_B extb
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
				FROM  XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                      HZ_CUST_ACCOUNTS acct
                                WHERE acct.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
                                AND   acct.status = 'I'
			     )
      and  attr_group_id=l_attr_group_id;

      UPDATE   XX_CDH_CUST_ACCT_EXT_TL
      SET     attr_group_id = l_old_attr_group_id
      where cust_account_id in (
                              SELECT acct.cust_account_id
				FROM  XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                      HZ_CUST_ACCOUNTS acct
                                WHERE acct.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
			        AND   acct.status = 'I'
                             )
        and  attr_group_id=l_attr_group_id;
        
        -- Added By IVARADA As part of Change 2.7
        -- Delete Logic to avoid duplicate BILLDOCS from being created
        -- This BILLDOC record in Interface table has to be deleted if the account is active
        -- and there exists atleast one BILLDOC entry for that account

        /* commented as this is obsolete in Rel 1.1. Any extensible created 
        -- in AOPS will be deleted and a new record will be created
        -- in EBS in XXOD_HZ_IMP_EXT_ATTRIBS_INT for ACCOUNT's BILLDOCS
        
        DELETE FROM XXOD_HZ_IMP_EXT_ATTRIBS_INT
        WHERE batch_id = p_batch_id 
        AND TRIM(attribute_group_code) = 'BILLDOCS'
        AND TRIM(interface_entity_name) = 'ACCOUNT'
        AND TRIM(interface_entity_reference) IN (
                                          SELECT acct.orig_system_reference
                                          FROM  XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                                HZ_CUST_ACCOUNTS acct,
                                                XX_CDH_CUST_ACCT_EXT_B extb
                                          WHERE acct.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                          AND   extb.cust_account_id        = acct.cust_account_id
                                          AND   ext_int.batch_id =  p_batch_id
                                          AND   trim(ext_int.interface_entity_name) = 'ACCOUNT'
                                          AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
                                          AND   acct.status = 'A'
                                          AND   extb.attr_group_id = l_attr_group_id
                                          );

        COMMIT;
        */
        
        /*
	--commented as we are handling this
	--under modification 2.8a
        DELETE FROM XXOD_HZ_IMP_ACCT_PROFILES_INT prof
        WHERE prof.batch_id = p_batch_id
        AND   TRIM(prof.account_orig_system_reference) IN
                                                   (
                                                     SELECT orig_system_reference
                                                     FROM HZ_CUST_ACCOUNTS acct
                                                     WHERE acct.orig_system_reference = TRIM(prof.account_orig_system_reference)
                                                     AND   status='A'
                                                    );
                                                    
        fnd_file.put_line(fnd_file.log,'Total Number Of Profiles Deleted From Interface Tables:' || SQL%ROWCOUNT);
        */                                            
        COMMIT;
    
    END IF;

    exception
     when others then
      rollback;
   end;
   --Update existing BILLDOCS for the account sites in the batch to OLD_BILLDOCS
   begin
     --select attribute group id for OLD_BILLDOCS and ACCOUNT_SITE
     l_old_attr_group_id := null;

     open c_ext_attr_id ( 'OLD_BILLDOCS', 'XX_CDH_CUST_ACCT_SITE');
     fetch c_ext_attr_id into l_old_attr_group_id;
     close c_ext_attr_id;
     /*
     SELECT attr_group_id
      into  l_old_attr_group_id
       FROM ego_attr_groups_v
      WHERE application_id = 222
        AND attr_group_name = 'OLD_BILLDOCS'
        AND attr_group_type = 'XX_CDH_CUST_ACCT_SITE';
     */

     --select attribute group id for BILLDOCS and ACCOUNT_SITE
     l_attr_group_id := null;
     open c_ext_attr_id ( 'BILLDOCS', 'XX_CDH_CUST_ACCT_SITE');
     fetch c_ext_attr_id into l_attr_group_id;
     close c_ext_attr_id;
     /*
     SELECT attr_group_id
      into  l_attr_group_id
       FROM ego_attr_groups_v
      WHERE application_id = 222
        AND attr_group_name = 'BILLDOCS'
        AND attr_group_type = 'XX_CDH_CUST_ACCT_SITE';
     */

   IF l_delta_batch = 'NOT_DELTA' THEN

        UPDATE  apps.XX_CDH_ACCT_SITE_EXT_B
        SET     attr_group_id = l_old_attr_group_id
        where cust_acct_site_id in (
                                SELECT acct_site.cust_acct_site_id
				FROM XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                     HZ_CUST_ACCT_SITES_ALL acct_site
                                WHERE acct_site.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT_SITE'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
                                )
        and  attr_group_id=l_attr_group_id;

        UPDATE  apps.XX_CDH_ACCT_SITE_EXT_TL
        SET     attr_group_id = l_old_attr_group_id
        where cust_acct_site_id in (
                                 SELECT acct_site.cust_acct_site_id
				FROM XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                     HZ_CUST_ACCT_SITES_ALL acct_site
                                WHERE acct_site.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT_SITE'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
                                )
        and  attr_group_id=l_attr_group_id;

        COMMIT;
    
    ELSE
      
        UPDATE  apps.XX_CDH_ACCT_SITE_EXT_B
        SET     attr_group_id = l_old_attr_group_id
        where cust_acct_site_id in (
                                SELECT acct_site.cust_acct_site_id
				FROM XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                     HZ_CUST_ACCT_SITES_ALL acct_site,
                                     HZ_CUST_ACCOUNTS       acct
                                WHERE acct_site.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   acct.cust_account_id   =  acct_site.cust_account_id
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT_SITE'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
                                AND   (acct_site.status = 'I' OR acct.status = 'I')
                                )
        and  attr_group_id=l_attr_group_id;

        UPDATE  apps.XX_CDH_ACCT_SITE_EXT_TL
        SET     attr_group_id = l_old_attr_group_id
        where cust_acct_site_id in (
                                 SELECT acct_site.cust_acct_site_id
				 FROM XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                     HZ_CUST_ACCT_SITES_ALL acct_site,
                                     HZ_CUST_ACCOUNTS       acct
                                WHERE acct_site.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                AND   ext_int.batch_id =  p_batch_id
                                AND   trim(ext_int.interface_entity_name) = 'ACCOUNT_SITE'
                                AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
                                AND   (acct_site.status = 'I' OR acct.status = 'I')
                                )
        and  attr_group_id=l_attr_group_id;
        
        -- Added By IVARADA As part of Change 2.7
        -- Delete Logic to avoid duplicate BILLDOCS from being created
        -- This BILLDOC record in Interface table has to be deleted if the account site is active
        -- and there exists atleast one BILLDOC entry for that account site
        
        
        DELETE FROM XXOD_HZ_IMP_EXT_ATTRIBS_INT
        WHERE batch_id = p_batch_id 
        AND TRIM(attribute_group_code) = 'BILLDOCS'
        AND TRIM(interface_entity_name) = 'ACCOUNT_SITE'
        AND TRIM(interface_entity_reference) IN (
                                           SELECT acct_site.orig_system_reference
                                            FROM XXOD_HZ_IMP_EXT_ATTRIBS_INT ext_int,
                                                 HZ_CUST_ACCT_SITES_ALL acct_site,
                                                 XX_CDH_ACCT_SITE_EXT_B  extb
                                          WHERE acct_site.orig_system_reference  = trim(ext_int.orig_system_reference) 
                                          AND   extb.cust_acct_site_id = acct_site.cust_acct_site_id
                                          AND   ext_int.batch_id =  p_batch_id
                                          AND   trim(ext_int.interface_entity_name) = 'ACCOUNT_SITE'
                                          AND   trim(ext_int.attribute_group_code)  = 'BILLDOCS'
                                          AND   extb.attr_group_id = l_attr_group_id
                                          AND   acct_site.status = 'A'
                                          );

        COMMIT;

    
    END IF;  

    -- Added By IVARADA as part of change 3.0
    -- DELETE Logic for SPC Data Inorder to Avoid Overwriting User Updates
      
   IF l_delta_batch <> 'NOT_DELTA' THEN

       l_attr_group_id := NULL; 
      
       SELECT attr_group_id
       INTO l_attr_group_id
       FROM APPS.ego_attr_groups_v
       WHERE application_id = 222
       AND attr_group_name = 'SPC_INFO'
       AND attr_group_type = 'XX_CDH_CUST_ACCOUNT';
       
       fnd_file.put_line(fnd_file.log,'Deleting SPC Records From Interface Table.......');
       
       DELETE FROM xxod_hz_imp_ext_attribs_int xx
       WHERE batch_id = p_batch_id
       AND TRIM(attribute_group_code) = 'SPC_INFO'
       AND TRIM(interface_entity_name) = 'ACCOUNT'
       AND EXISTS (
                   SELECT 1 
                   FROM HZ_CUST_ACCOUNTS acct
                       ,XX_CDH_CUST_ACCT_EXT_B ext
                   WHERE acct.orig_system_reference = TRIM(xx.interface_entity_reference)
                   AND ext.cust_account_id = acct.cust_account_id
                   AND ext.attr_group_id = l_attr_group_id
                   AND ext.n_ext_attr1 = TRIM(xx.n_ext_attr1)
                   );
         
        COMMIT; 
                   
        fnd_file.put_line(fnd_file.log,'Total# Of SPC Records Deleted For Interface Tables:' || SQL%ROWCOUNT);
      
    END IF;
      
   exception
     when others then
       rollback;
   end;

   -------------------------
   --End of Modification 2.4
   -------------------------
   /* Comment the following code */
   --commented as this is obsolete in Rel 1.1. Any extensible created 
   -- in AOPS will be deleted and a new record will be created
   -- in EBS in XXOD_HZ_IMP_EXT_ATTRIBS_INT for ACCOUNT's BILLDOCS
   ----------------------------------------------------------------------------
   -- Modification 2.6 : Populate new sequence numbers for BILLDOCS records for
   --                    new customers created in AOPS
   -- 16-MAR-2009
   ----------------------------------------------------------------------------
   /*
   begin

       update XXOD_HZ_IMP_EXT_ATTRIBS_INT
       set    n_ext_attr2 = XX_CDH_CUST_DOC_ID_S.nextval
       where  batch_id=p_batch_id
       and    trim(orig_system)='A0'
       and    trim(interface_entity_name)='ACCOUNT'
       and    trim(attribute_group_code)='BILLDOCS'
       and    trim(n_ext_attr2)=0;

       COMMIT;
 
     exception
       when others then
         rollback;
   end;
   */
   -------------------------
   --End of Modification 2.6
   -------------------------
   
   -------------------------
   --Modification 2.8a: If the batch is DELTA, delete the records in the 
   --extensible interface table and create them from Oracle afresh
   -------------------------
   IF (trim(l_delta_batch) = 'DELTA' ) THEN

       --first delete all the BILLDOCS extensibles created by AOPS conversion
       --extraction
       DELETE FROM xxod_hz_imp_ext_attribs_int
       WHERE batch_id = p_batch_id
       AND TRIM(attribute_group_code) = 'BILLDOCS'
       AND TRIM(interface_entity_name) = 'ACCOUNT';

       COMMIT;

       --Create BILLDOCS in EBS for all the eligible accounts in the Create Batch
       for i_billdoc_rec in c_billdocs (p_batch_id)
       LOOP

         l_attr_group_id := null;
         lc_ab_flag := null;
         open c_ext_attr_id ( 'BILLDOCS', 'XX_CDH_CUST_ACCOUNT');
         fetch c_ext_attr_id into l_attr_group_id;
         close c_ext_attr_id;

         open c_billdoc_exist ( i_billdoc_rec.account_orig_system_reference, l_attr_group_id);
         FETCH c_billdoc_exist INTO l_chk_val;
         IF c_billdoc_exist%NOTFOUND  THEN
           open c_ab_flag ( i_billdoc_rec.account_orig_system_reference, p_batch_id);
           fetch c_ab_flag into lc_ab_flag;
           
           if (lc_ab_flag = 'Y') then
             XXCDH_BILLDOCS_PKG.create_billdocs(
                                                 P_BATCH_ID,
                                                 i_billdoc_rec.party_orig_system,
                                                 i_billdoc_rec.account_orig_system_reference,
                                                 i_billdoc_rec.customer_attribute18
                                               );
           end if;
          close c_ab_flag;
         END IF;
         close c_billdoc_exist;
       END LOOP;
   END IF;
   
   ---------------------------
   --End of Modification 2.8a
   ---------------------------
   
   -------------------------
   --Modification 2.8b: For all the profile records in the interface table, 
   --derive the profile class, payment term, collector_id other profile
   --attributes
   -------------------------

   --If profile is coming as new, Update the profile interface record
   --by deriving the profile class name and collector name as per the
   --flags coming from AOPS
   lc_customer_status := null;
   lc_customer_type := null;
   lc_prof_class_name := null;
   lc_retain_collect_cd := null;
   ln_collector_id := null;
   lc_collector_name := null;
   lc_prof_return_status := null;

   for i_prof_rec in c_profile_records(p_batch_id)
   LOOP
     lc_customer_status := null;
     lc_customer_type := null;
     lc_prof_class_name := null;
     lc_retain_collect_cd := null;
     ln_collector_id := null;
     lc_collector_name := null;
     lc_prof_return_status := null;

     XX_OD_CUST_PROF_CLASS_MAP_PKG.derive_prof_class_dtls 
              (
              p_customer_osr            =>     i_prof_rec.account_orig_system_reference,
              p_reactivated_flag        =>     i_prof_rec.attribute4,
              p_ab_flag                 =>     i_prof_rec.attribute3,
              p_status                  =>     i_prof_rec.customer_status,
              p_customer_type           =>     i_prof_rec.customer_attribute18,
	      p_cust_template           =>     i_prof_rec.customer_profile_class_name,
              x_prof_class_modify       =>     lc_prof_class_modify,
              x_prof_class_name         =>     lc_prof_class_name,
              x_prof_class_id           =>     ln_profile_class_id,
              x_retain_collect_cd       =>     lc_retain_collect_cd,
              x_collector_code          =>     ln_collector_id,
              x_collector_name          =>     lc_collector_name,
              x_errbuf                  =>     ln_errbuf,
              x_return_status           =>     lc_prof_return_status
             );
									  
     if ( lc_prof_class_modify = 'Y' and lc_prof_return_status = 'S') then
       
       UPDATE XXOD_HZ_IMP_ACCT_PROFILES_INT 
       SET    customer_profile_class_name = lc_prof_class_name,
              collector_name = lc_collector_name,
	      standard_term_name = null,
	      statements = null,
	      statement_cycle_name = null,
	      trx_credit_limit = null,
	      overall_credit_limit = null,
	      dunning_letters = null,
	      dunning_letter_set_name = null,
	      discount_terms = null,
	      discount_grace_days = null,
	      currency_code = null
       where  batch_id = p_batch_id
         and  trim(account_orig_system_reference) = i_prof_rec.account_orig_system_reference;

       commit;

     else

        DELETE FROM XXOD_HZ_IMP_ACCT_PROFILES_INT prof
        WHERE prof.batch_id = p_batch_id
        AND   TRIM(prof.account_orig_system_reference) = i_prof_rec.account_orig_system_reference;

     end if;     
     
   END LOOP;
   -------------------------
   --End of Modification 2.8b
   -------------------------



   -------------------------
   --Modification 2.9: Populate Segmentation and Loyalty codes
   -------------------------
   XX_CDH_CREATE_CLASSIFICS_PKG.main (
                                        x_errbuf,     
                                        x_retcode,    
                                        p_batch_id
                                      );

EXCEPTION
   WHEN le_skip_procedure THEN
      x_retcode   := 0;
      fnd_file.put_line (fnd_file.log,'Processing was skipped!!');
   WHEN OTHERS THEN
      x_errbuf    :='Others Exception in post_extract_update_aops procedure '|| SQLERRM;
      x_retcode   :='2';

END post_extract_update_aops;


-- +=============================================================+
-- | Name  : update_crmload_status                               |
-- | Description: This procedure will be responsible to          |
-- +=============================================================+

PROCEDURE update_crmload_status
      (   p_ebs_batch_id        NUMBER
         ,p_status              VARCHAR2
         ,p_audit_id            NUMBER
         ,p_ebs_exec_status     VARCHAR2
      )
  
AS
   l_owb_execution_audit_id NUMBER(22);
BEGIN

   SELECT owb_execution_audit_id
   INTO   l_owb_execution_audit_id
   FROM   xx_owb_job_control
   WHERE  audit_id = p_audit_id;

   UPDATE xx_owb_crmbatch_status 
   SET    ebs_xxcnv_status = p_status
         ,ebs_end_timestamp = TO_CHAR(SYSDATE,'RRRR-MM-DD HH24:MI:SS')
         ,ebs_owb_execution_audit_id = l_owb_execution_audit_id
         ,ebs_xxcnv_exec_status = p_ebs_exec_status
   WHERE  ebs_batch_id = p_ebs_batch_id ;
   IF sql%rowcount = 0 then 
      insert INTO xx_owb_crmbatch_status
         (
          EBS_BATCH_ID,
          EBS_XXCNV_STATUS,
          EBS_XXCNV_EXEC_STATUS,
          EBS_START_TIMESTAMP,
          EBS_END_TIMESTAMP,
          EBS_OWB_EXECUTION_AUDIT_ID
         ) values 
         (
          p_ebs_batch_id,
          p_status,
          p_ebs_exec_status,
          null,
          TO_CHAR(SYSDATE,'RRRR-MM-DD HH24:MI:SS'),
          l_owb_execution_audit_id
         )  ;
   END IF ;
   COMMIT;

END update_crmload_status;

-- +=============================================================+
-- | Name  : load_grandparents                                   |
-- | Description: This procedure will be responsible to          |
-- +=============================================================+


PROCEDURE load_grandparents
      (   x_errbuf                 OUT VARCHAR2
         ,x_retcode                OUT VARCHAR2
         ,p_custom_max_errors      IN  NUMBER
                         )
AS 
ln_exec_return_code                 NUMBER ;
lc_custom_params                    VARCHAR2(2000);
lc_current_user                     VARCHAR2(200) := USER;
lc_location_name                    VARCHAR2(200) ;

CURSOR lc_owb_location IS
SELECT fnd_profile.value('XX_CDH_OWB_LOCATION') LOC
FROM   DUAL ;
       
BEGIN
    log_debug_msg('=====================  BEGIN   =======================');
    log_debug_msg('=== Calling  OWB Process PF_C0024_GRANDPARENT_NA_N ===='||CHR(10));
    
    FOR cur_owb_location in lc_owb_location LOOP
        lc_location_name := cur_owb_location.LOC ;
    END LOOP;


--    lc_custom_params := lc_custom_params || 'P_CUSTOM_MAX_ERRORS=' || TO_CHAR(NVL(p_custom_max_errors,500)) ;
            
    execute immediate 'alter session set current_schema=OWB_RT' ;    
    ln_exec_return_code := wb_rt_api_exec.run_task(p_location_name=>lc_location_name,
                                                   p_task_type=>'PROCESSFLOW',
                                                   p_task_name=>'PF_C0024_GRANDPARENT_NA_N',
                                                   p_custom_params=>lc_custom_params,
                                                   p_oem_friendly=>0,
                                                   p_background=>0);

    execute immediate 'alter session set current_schema=' || lc_current_user ;  

    log_debug_msg(CHR(10)||'============= Procedure PF_C0024_GRANDPARENT_NA_N ==============');
    log_debug_msg('======================       END        ========================');

EXCEPTION
    WHEN OTHERS THEN
        execute immediate 'alter session set current_schema=' || lc_current_user ;  
        x_errbuf    :='Others Exception in RUN_OWB_PF_LOAD procedure '||SQLERRM;
        x_retcode   :='2';
END load_grandparents;


-- +===================================================================+
-- | Name        : get_owb_run_status                                  |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- +===================================================================+

PROCEDURE get_owb_run_status
      (   x_run_status          OUT   VARCHAR2
         ,x_run_details         OUT   VARCHAR2
         ,p_batch_id            IN    NUMBER
         ,p_process_type        IN    VARCHAR2
      )
IS
CURSOR c_audit 
IS 
SELECT DECODE(p_process_type,'LOAD',ebs_owb_execution_audit_id,aops_owb_execution_audit_id) audit_id
FROM   xx_owb_crmbatch_status
WHERE  ebs_batch_id = p_batch_id  ;

CURSOR c_map_list(p_parent_audit_id NUMBER)
IS
SELECT m.execution_audit_id map_audit_id,
       m.task_name activity_name,
       m.task_type activity_type,
       m.return_result run_status
FROM   all_rt_audit_executions m
WHERE  m.parent_execution_audit_id = p_parent_audit_id
AND    m.task_type = 'PLSQL'
ORDER BY  m.execution_audit_id;

CURSOR c_step_list(p_map_audit_id  NUMBER)
IS
SELECT mp.map_name,
       --st.step_name,
       --DECODE(SUBSTR(st.step_name,1,21),'XX_OWB_REJECT_RECORDS',(SELECT  RTT_OBJECT_NAME FROM OWB_RT.WB_RT_AUDIT_STRUCT WHERE RTD_IID = st.step_id AND RTT_OBJECT_NAME LIKE '%STG' AND ROWNUM<=1),st.step_name) step_name,
       tg.target_name step_name,
       st.step_id,
       st.number_records_selected,
       st.number_records_inserted,
       st.number_records_updated
FROM   all_rt_audit_map_runs mp,
       all_rt_audit_step_runs st,
       all_rt_audit_step_run_targets tg
WHERE  mp.map_run_id = st.map_run_id
AND    execution_audit_id = p_map_audit_id  
AND    tg.step_id = st.step_id
AND    tg.target_name <> 'XX_OWB_REJECT_RECORDS';

CURSOR c_err_msg(p_exec_aud_id NUMBER)
IS 
SELECT DISTINCT map_name,target_name, run_error_message 
FROM   all_rt_audit_map_run_errors a, 
       all_rt_audit_map_runs b
WHERE  a.map_run_id = b.map_run_id 
AND    b.execution_audit_id = p_exec_aud_id;
      
      
ln_reject_count              NUMBER:=0;
ln_process_audit_id          NUMBER;
lc_pf_name                   VARCHAR2(30);
lc_output                    VARCHAR2(8000);
lc_error                     VARCHAR2(8000);
lc_map_status                VARCHAR2(10):='OK';
l_audit_id                   NUMBER ;

BEGIN
   FOR c_audit1 IN c_audit
   LOOP
     l_audit_id := c_audit1.AUDIT_ID ;
   END LOOP;

   -- get list of mappings in this process and loop through them to get the audit stats
   lc_output := RPAD('-',100,'-');
   lc_output := lc_output||chr(10)||RPAD('PROCESS NAME  :',16,' ')||lc_pf_name;

   lc_output := lc_output||chr(10)||RPAD('-',100,'-');
   lc_output := lc_output||chr(10)||/*rpad('MAP NAME',30,' ')||chr(9)||*/rpad('STEP_NAME',30,' ')||chr(9)||rpad('ROWS',8,' ')||chr(9)||rpad('ROWS',8,' ')||chr(9)||rpad('ROWS',8,' ')||chr(9)||rpad('ROWS',8,' ');
   lc_output := lc_output||chr(10)||/*rpad(' ',30,' ')||chr(9)||*/rpad(' ',30,' ')||chr(9)||rpad('SELECTED',8,' ')||chr(9)||rpad('INSERTED',8,' ')||chr(9)||rpad('UPDATED',8,' ')||chr(9)||rpad('REJECTED',8,' ');
   lc_output := lc_output||chr(10)||RPAD('-',100,'-');

   FOR rec_map IN c_map_list(l_audit_id)
   LOOP
      FOR  rec_step IN c_step_list(rec_map.map_audit_id)
      LOOP
         IF rec_step.step_name LIKE '%STG' THEN
            SELECT COUNT(1)
            INTO   ln_reject_count
            FROM   xx_owb_reject_records
            WHERE  audit_id = l_audit_id
               AND table_nm = REPLACE (rec_step.step_name,'_STG','_L');
         END IF;

         rec_step.number_records_inserted := rec_step.number_records_inserted - ln_reject_count;

         lc_output:=lc_output||chr(10)|| /*rpad(replace(rec_step.map_name,'"'),30,' ')||chr(9)||*/ rpad(rec_step.step_name,30,' ')||chr(9)||rpad(rec_step.number_records_selected,8,' ')||chr(9)||rpad(rec_step.number_records_inserted,8,' ')||chr(9)||rpad(rec_step.number_records_updated,8,' ')||chr(9)||rpad(ln_reject_count,8,' ') || rec_map.run_status ;

         ln_reject_count := 0;
         IF lc_map_status = 'OK' THEN
            lc_map_status := rec_map.run_status;
         END IF;
      END LOOP;
      IF lc_map_status != 'OK' then
         FOR c_err_msg1 IN c_err_msg(rec_map.map_audit_id)   
         LOOP
            IF LENGTH(NVL(lc_error,'a')) < 6000 then
               lc_error:=lc_error ||chr(10)||rpad(replace(c_err_msg1.map_name,'"'),30,' ')||chr(9)||rpad(c_err_msg1.target_name,30,' ')||chr(9)|| c_err_msg1.run_error_message;
            END IF;
         END LOOP;
      END IF;
   END LOOP;
   IF lc_map_status != 'OK' then
      lc_error := chr(10)|| RPAD('-',120,'-') ||
                  chr(10)|| RPAD('MAP NAME',30,' ')||chr(9)||rpad('TARGET TABLE',30,' ')||chr(9)||rpad('ERROR',8,' ') ||
                  chr(10)|| RPAD('-',120,'-') || lc_error; 
      IF length(lc_error) + length(lc_output) < 8000 then
         lc_output := lc_output || lc_error ;
      END IF ;  
   END IF;
   x_run_details := lc_output ;
   x_run_status := lc_map_status;
END get_owb_run_status;

-- +===================================================================+
-- | Name        : log_debug_msg                                       |
-- | Description :                                                     |
-- |                                                                   |
-- | Parameters  :  p_debug_msg                                        |
-- |                                                                   |
-- +===================================================================+
PROCEDURE log_debug_msg
      (  p_debug_msg              IN VARCHAR2)
AS

BEGIN
    FND_FILE.PUT_LINE(FND_FILE.LOG,p_debug_msg);
END log_debug_msg;

-- +===================================================================+
-- | Name        :  get_profile_dflt_values                            |
-- | Description :  This procedure returns default values for datatypes| 
-- |                   from fnd_profile_option_values table            |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- +===================================================================+      
PROCEDURE get_profile_dflt_values 
      (   p_char_dflt_val                  OUT    VARCHAR2
         ,p_num_dflt_val                   OUT    VARCHAR2
         ,p_date_dflt_val                  OUT    VARCHAR2
         ,p_tl_dflt_val                    OUT    VARCHAR2
      )
AS
BEGIN
SELECT
fnd_profile_option_values.profile_option_value INTO p_char_dflt_val
FROM
fnd_profile_option_values,
fnd_profile_options_vl
  WHERE 
  ( fnd_profile_option_values.profile_option_id = fnd_profile_options_vl.profile_option_id ) AND
  ( fnd_profile_options_vl.profile_option_name in ( 'HZ_IMP_G_MISS_CHAR' ) ); 

SELECT
fnd_profile_option_values.profile_option_value INTO p_num_dflt_val
FROM
fnd_profile_option_values,
fnd_profile_options_vl
  WHERE 
  ( fnd_profile_option_values.profile_option_id = fnd_profile_options_vl.profile_option_id ) AND
  ( fnd_profile_options_vl.profile_option_name in ( 'HZ_IMP_G_MISS_NUM' ) ); 
  
EXCEPTION
WHEN others THEN
DBMS_OUTPUT.PUT_LINE('Error is '||SQLCODE ||','||SQLERRM);
raise_application_error(-20001,'Error in executing XX_CDH_CONV_OWB_PKG.GET_PROFILE_DFLT_VALUES procedure');
END get_profile_dflt_values;

END XX_CDH_CONV_OWB_PKG;
/
SHOW ERRORS;
EXIT;
