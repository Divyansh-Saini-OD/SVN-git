SET VERIFY OFF;
WHENEVER SQLERROR CONTINUE;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;

CREATE OR REPLACE PACKAGE BODY XX_CDH_INT_LOCATIONS_PKG
-- +========================================================================================+
-- |                  Office Depot - Project Simplify                                       |
-- |                   Oracle Consulting Organization                                       |
-- +========================================================================================+
-- | Name        :  XX_CDH_INT_LOCATIONS_PKG.pkb                                            |
-- | Description :  CDH Customer Conversion Create Contact Pkg Body                         |
-- |                                                                                        |
-- |Change Record:                                                                          |
-- |===============                                                                         |
-- |Version   Date        Author             Remarks                                        |
-- |========  =========== ================== ===============================================|
-- |DRAFT 1a  01-Apr-2008 Ambarish Mukherjee Initial draft version                          |
-- |Draft 1b  06-May-2008 Ambarish Mukherjee Changes for Master Internal Customer           |
-- |1.0       15-May-2008 Ambarish Mukherjee Skip process if OSR is null                    |
-- |1.1       24-Feb-2009 Indra Varada       Modified Logic for Fetching NON TRADE Locations|
-- +========================================================================================+
AS
gt_request_id                 fnd_concurrent_requests.request_id%TYPE
                              := fnd_global.conc_request_id();
gv_init_msg_list              VARCHAR2(1)          := fnd_api.g_true;
gn_bulk_fetch_limit           NUMBER               := XX_CDH_CONV_MASTER_PKG.g_bulk_fetch_limit;
-- +===================================================================+
-- | Name        :  populate_batch_main                                |
-- | Description :  This program would populate the required common    |
-- |                view tables for each record in hr_locations.       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE populate_batch_main
      (  x_errbuf             OUT VARCHAR2,
         x_retcode            OUT VARCHAR2
      )
IS
lv_errbuf      VARCHAR2(2000);
ln_retcode     NUMBER;

BEGIN

   populate_batch
      (  x_errbuf    => lv_errbuf,
         x_retcode   => ln_retcode
      );
      
   IF ln_retcode = 2 THEN 
      x_retcode := 2;
   ELSE    
      inactivate_accounts   
         (  x_errbuf    => lv_errbuf,
            x_retcode   => ln_retcode
         );
         
      IF ln_retcode = 2 THEN 
         x_retcode := 2; 
      END IF;
   END IF;
   
END populate_batch_main;

-- +===================================================================+
-- | Name        :  populate_batch                                     |
-- | Description :  This program would populate the required common    |
-- |                view tables for each record in hr_locations.       |
-- |                                                                   |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE populate_batch
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2
      )
IS

CURSOR lc_fetch_active_loc_cur
IS
SELECT hl.*, 'Y' trade_flag, haou.attribute1 haou_attribute1
FROM   hr_locations hl,
       hr_all_organization_units haou
WHERE  NVL(hl.inactive_date, SYSDATE+1) > SYSDATE
AND    hl.attribute3 IS NOT NULL
AND    hl.attribute3 LIKE 'TRADE%'
AND    haou.location_id = hl.location_id
UNION
SELECT hl.*, 'N' trade_flag, NULL haou_attribute1
FROM   hr_locations hl
WHERE  NVL(hl.inactive_date, SYSDATE+1) > SYSDATE
AND    hl.attribute3     IS NOT NULL
AND    hl.attribute3   LIKE 'NON TRADE%'
AND    hl.address_line_1 IS NOT NULL
AND    hl.town_or_city   IS NOT NULL
AND    hl.country        IS NOT NULL
AND    hl.postal_code    IS NOT NULL
-- Changes for Ver 1.1 begins
AND    ((hl.country = 'CA' AND hl.region_1 IS NOT NULL) OR hl.country = 'US')
AND    ((hl.country = 'US' AND hl.region_2 IS NOT NULL) OR hl.country = 'CA');
-- Changes for Ver 1.1 ends
lv_errbuf                        VARCHAR2(2000);
lv_retcode                       VARCHAR2(10);
le_skip_process                  EXCEPTION;
ld_sysdate                       DATE := SYSDATE;
lv_return_status                 VARCHAR2(1);
ln_msg_count                     NUMBER;
ln_counter                       NUMBER;
lv_msg_data                      VARCHAR2(2000);
ln_batch_id                      NUMBER;
lv_orig_system                   VARCHAR2(100) := 'RMS';
lv_created_by_module             VARCHAR2(100) := 'XXSTORE';
ln_exists                        NUMBER        := 0;
lv_master_int_osr                VARCHAR2(100) := 'MASTER_OD_INT';
lv_pay_method_name               ar_receipt_methods.name%TYPE;
ln_us_org_id                     NUMBER;
ln_ca_org_id                     NUMBER;
lv_osr                           VARCHAR2(1000);
ln_count                         NUMBER;
ln_osr_exists                    NUMBER := 0;

BEGIN
   fnd_file.put_line(fnd_file.log, 'Start of Concurrent Program - OD: Create Internal Accounts Program.');
   
   ------------------------------------------
   -- Step 1: Generate Bulk Import Batch Id
   ------------------------------------------
   
   HZ_IMP_BATCH_SUMMARY_V2PUB.create_import_batch 
         (  p_batch_name        => 'HR_LOCATIONS-'||ld_sysdate, 
            p_description       => 'HR_LOCATIONS-'||ld_sysdate, 
            p_original_system   => lv_orig_system, 
            p_load_type         => '', 
            p_est_no_of_records => 5000, 
            x_batch_id          => ln_batch_id, 
            x_return_status     => lv_return_status, 
            x_msg_count         => ln_msg_count, 
            x_msg_data          => lv_msg_data
         ); 
   IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      IF ln_msg_count > 0 THEN
         fnd_file.put_line (fnd_file.log,'Error while generating batch_id - ');
         FOR ln_counter IN 1..ln_msg_count
         LOOP
            fnd_file.put_line (fnd_file.log,'Error ->'||fnd_msg_pub.get(ln_counter, FND_API.G_FALSE));
         END LOOP;
         fnd_msg_pub.delete_msg;
      END IF;
      RAISE le_skip_process;
   ELSE
      fnd_file.put_line (fnd_file.log,'Batch ID - '||ln_batch_id||' Successfully generated!!');
   END IF;
   
   ---------------------------
   -- Step 2.1: Get US org_id
   ---------------------------
   
   BEGIN   
      SELECT hou.organization_id
      INTO   ln_us_org_id
      FROM   xx_fin_translatedefinition xdef,
             xx_fin_translatevalues     xval,
             hr_organization_units_v    hou
      WHERE  xdef.translation_name         = 'OD_COUNTRY_DEFAULTS' 
      AND    xdef.translate_id             = xval.translate_id 
      AND    xval.enabled_flag             = 'Y' 
      AND    xdef.enabled_flag             = 'Y' 
      AND    TRUNC(sysdate) BETWEEN TRUNC(NVL(xval.start_date_active, sysdate -1)) AND TRUNC(NVL(xval.end_date_active, sysdate + 1)) 
      AND    xval.source_value1            = 'US'
      AND    hou.name                      = xval.target_value2;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log,'Org_id for US not found - '||SQLERRM);
         RAISE le_skip_process;   
   END;
   
   ---------------------------
   -- Step 2.2: Get CA org_id
   ---------------------------
   
   BEGIN   
      SELECT hou.organization_id
      INTO   ln_ca_org_id
      FROM   xx_fin_translatedefinition xdef,
             xx_fin_translatevalues     xval,
             hr_organization_units_v    hou
      WHERE  xdef.translation_name         = 'OD_COUNTRY_DEFAULTS' 
      AND    xdef.translate_id             = xval.translate_id 
      AND    xval.enabled_flag             = 'Y' 
      AND    xdef.enabled_flag             = 'Y' 
      AND    TRUNC(sysdate) BETWEEN TRUNC(NVL(xval.start_date_active, sysdate -1)) AND TRUNC(NVL(xval.end_date_active, sysdate + 1)) 
      AND    xval.source_value1            = 'CA'
      AND    hou.name                      = xval.target_value2;
   EXCEPTION
      WHEN OTHERS THEN
         fnd_file.put_line (fnd_file.log,'Org_id for CA not found - '||SQLERRM);
         RAISE le_skip_process;   
   END;
   
   --------------------------------------
   -- Step 3: Create OD MASTER Customer
   --------------------------------------
   
   BEGIN
      SELECT 1
      INTO   ln_exists
      FROM   hz_orig_sys_references 
      WHERE  orig_system_reference = lv_master_int_osr
      AND    status = 'A'
      AND    owner_table_name = 'HZ_CUST_ACCOUNTS';
   EXCEPTION
      WHEN TOO_MANY_ROWS THEN
         ln_exists := 1;
      WHEN OTHERS THEN
         ln_exists := 0;
   END;
   
   IF ln_exists = 0 THEN
      
      INSERT INTO xxod_hz_imp_parties_int
         (   batch_id, 
             created_by_module, 
             organization_name, 
             party_orig_system, 
             party_orig_system_reference, 
             party_type
         )
      VALUES
         (   ln_batch_id , 
             lv_created_by_module, 
             'Master OD Internal Customer', 
             lv_orig_system, 
             lv_master_int_osr, 
             'ORGANIZATION'
         );
         
      -- Create Person Party for Contact
      
      INSERT INTO xxod_hz_imp_parties_int
         (   batch_id, 
             party_orig_system, 
             party_orig_system_reference, 
             party_type, 
             attribute20, 
             person_first_name, 
             person_last_name, 
             created_by_module
         )
      VALUES
         (   ln_batch_id, 
             lv_orig_system, 
             lv_master_int_osr||'_PER', 
             'PERSON', 
             ln_batch_id, 
             'Gabriela', 
             'Settles', 
             lv_created_by_module
         );
         
      -- Create Contact
      
      INSERT INTO xxod_hz_imp_contacts_int
         (   batch_id, 
             contact_orig_system, 
             contact_orig_system_reference, 
             created_by_module, 
             obj_orig_system, 
             obj_orig_system_reference, 
             relationship_code, 
             relationship_type, 
             start_date, 
             sub_orig_system, 
             sub_orig_system_reference
         )
      VALUES
         (   ln_batch_id, 
             lv_orig_system, 
             lv_master_int_osr||'_CONT', 
             lv_created_by_module, 
             lv_orig_system, 
             lv_master_int_osr, 
             'CONTACT_OF', 
             'CONTACT', 
             SYSDATE, 
             lv_orig_system, 
             lv_master_int_osr||'_PER'
         );
         
      -- Create Contact Point
      
      INSERT INTO xxod_hz_imp_contactpts_int
         (   BATCH_ID, 
             CONTACT_POINT_PURPOSE, 
             CONTACT_POINT_TYPE, 
             CP_ORIG_SYSTEM, 
             CP_ORIG_SYSTEM_REFERENCE, 
             CREATED_BY_MODULE, 
             PARTY_ORIG_SYSTEM, 
             PARTY_ORIG_SYSTEM_REFERENCE, 
             PHONE_COUNTRY_CODE, 
             PHONE_LINE_TYPE, 
             PRIMARY_FLAG, 
             RAW_PHONE_NUMBER, 
             REL_FLAG)
       Values
         (   ln_batch_id, 
             'BUSINESS',
             'PHONE',
             lv_orig_system,
             lv_master_int_osr||'_CP',
             'XXCONV', 
             lv_orig_system,
             lv_master_int_osr||'_CONT',
             '1', 
             'GEN', 
             'Y', 
             '5614382123', 
             'Y');

      INSERT INTO xxod_hz_imp_addresses_int
         (   address1, 
             batch_id, 
             city, 
             country, 
             county, 
             created_by_module, 
             party_orig_system, 
             party_orig_system_reference, 
             postal_code, 
             site_orig_system, 
             site_orig_system_reference, 
             state,
             address_lines_phonetic
         )
       VALUES
         (   '2200, Old Germantown Rd', 
             ln_batch_id, 
             'Delray Beach', 
             'US', 
             'Palm Beach',
             lv_created_by_module, 
             lv_orig_system, 
             lv_master_int_osr, 
             '33445', 
             lv_orig_system, 
             lv_master_int_osr, 
             'FL',
             'Office Depot, Inc'
         );
         
      INSERT INTO xxod_hz_imp_addressuses_int
         (   batch_id, 
             created_by_module, 
             party_orig_system, 
             party_orig_system_reference, 
             primary_flag, 
             site_orig_system, 
             site_orig_system_reference, 
             site_use_type
         )
      VALUES
         (   ln_batch_id, 
             lv_created_by_module, 
             lv_orig_system, 
             lv_master_int_osr, 
             'Y', 
             lv_orig_system, 
             lv_master_int_osr, 
             'BILL_TO'
         ); 
         
      INSERT INTO xxod_hz_imp_accounts_int
         (   batch_id, 
             created_by_module, 
             party_orig_system, 
             party_orig_system_reference, 
             account_orig_system_reference, 
             customer_class_code, 
             account_name, 
             customer_type, 
             account_orig_system, 
             org_id
         )
      VALUES
         (   ln_batch_id,
             lv_created_by_module,
             lv_orig_system, 
             lv_master_int_osr,
             lv_master_int_osr,
             'STORE',
             '2200, Old Germantown Rd',
             'I',
             lv_orig_system, 
             ln_us_org_id             
         ); 
         
      INSERT INTO xxod_hz_imp_account_sites_int
         (   batch_id, 
             created_by_module, 
             party_orig_system, 
             party_orig_system_reference, 
             account_orig_system, 
             account_orig_system_reference, 
             site_orig_system, 
             site_orig_system_reference, 
             acct_site_orig_system_ref, 
             acct_site_orig_system, 
             org_id
         )
      VALUES
         (   ln_batch_id, 
             lv_created_by_module,
             lv_orig_system, 
             lv_master_int_osr, 
             lv_orig_system, 
             lv_master_int_osr, 
             lv_orig_system, 
             lv_master_int_osr, 
             lv_master_int_osr, 
             lv_orig_system, 
             ln_us_org_id             
         );   
      
      
      INSERT INTO xxod_hz_imp_acct_siteuses_int
         (   batch_id, 
             created_by_module, 
             party_orig_system, 
             party_orig_system_reference, 
             acct_site_orig_system, 
             acct_site_orig_system_ref, 
             account_orig_system, 
             account_orig_system_reference, 
             site_use_code, 
             org_id, 
             location
         )
      VALUES
         (   ln_batch_id,
             lv_created_by_module,
             lv_orig_system, 
             lv_master_int_osr, 
             lv_orig_system, 
             lv_master_int_osr, 
             lv_orig_system, 
             lv_master_int_osr, 
             'BILL_TO', 
             ln_us_org_id,             
             'Master OD Internal Customer'
         );
         
         
      -- Create Account Contact
      
      INSERT INTO xxod_hz_imp_acct_contacts_int
         (   BATCH_ID,
             CREATED_BY_MODULE,
             PARTY_ORIG_SYSTEM,
             PARTY_ORIG_SYSTEM_REFERENCE,
             ACCOUNT_ORIG_SYSTEM,
             ACCOUNT_ORIG_SYSTEM_REFERENCE,
             CONTACT_ORIG_SYSTEM,
             CONTACT_ORIG_SYSTEM_REFERENCE,
             ROLE_TYPE,
             PRIMARY_FLAG
         )
      VALUES
         (   ln_batch_id,
             lv_created_by_module,
             lv_orig_system,
             lv_master_int_osr||'_PER',
             lv_orig_system,
             lv_master_int_osr,
             lv_orig_system,
             lv_master_int_osr||'_CONT',
             'CONTACT', 
             'Y');

      -- Create Account Contact Role 
      
      INSERT INTO xxod_hz_imp_acct_cntroles_int
         (   BATCH_ID, 
             CREATED_BY_MODULE, 
             PARTY_ORIG_SYSTEM, 
             PARTY_ORIG_SYSTEM_REFERENCE, 
             ACCOUNT_ORIG_SYSTEM, 
             ACCOUNT_ORIG_SYSTEM_REFERENCE, 
             CONTACT_ORIG_SYSTEM, 
             CONTACT_ORIG_SYSTEM_REFERENCE, 
             RESPONSIBILITY_TYPE, 
             PRIMARY_FLAG)
       Values
         (   ln_batch_id, 
             lv_created_by_module,
             lv_orig_system,
             lv_master_int_osr||'_PER',
             lv_orig_system,
             lv_master_int_osr,
             lv_orig_system,
             lv_master_int_osr||'_CONT',
             'LEGAL',
             'N'
         );

      
   END IF;
   
   
   --------------------
   -- Start Processing
   --------------------
   
   FOR lc_fetch_active_loc_rec IN lc_fetch_active_loc_cur
   LOOP
   
      IF lc_fetch_active_loc_rec.trade_flag = 'Y' THEN
         lv_osr := LPAD(lc_fetch_active_loc_rec.haou_attribute1,6,0)||lc_fetch_active_loc_rec.country;
      ELSE
         lv_osr := lc_fetch_active_loc_rec.location_id;
      END IF;
      
      IF lv_osr IS NOT NULL THEN
      
         --------------------------------------------
         -- Check if OSR already exists in the batch
         --------------------------------------------

         BEGIN
            SELECT 1
            INTO   ln_osr_exists
            FROM   xxod_hz_imp_parties_int
            WHERE  batch_id = ln_batch_id
            AND    party_orig_system_reference = lv_osr;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               ln_osr_exists := 0;
            WHEN OTHERS THEN
               ln_osr_exists := 1;
         END;

         IF ln_osr_exists = 0 THEN 

            --------------------------
            -- Step 3: Create Party
            --------------------------

            INSERT INTO xxod_hz_imp_parties_int
               (   batch_id, 
                   created_by_module, 
                   organization_name, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   party_type
               )
            VALUES
               (   ln_batch_id , 
                   lv_created_by_module, 
                   lc_fetch_active_loc_rec.location_code, 
                   lv_orig_system, 
                   lv_osr, 
                   'ORGANIZATION'
               );

            ------------------------------
            -- Step 4: Create Party Site
            ------------------------------

            INSERT INTO xxod_hz_imp_addresses_int
               (   address1, 
                   address2,
                   address3,
                   batch_id, 
                   city, 
                   country, 
                   county, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   postal_code, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   state,
                   province
               )
             VALUES
               (   lc_fetch_active_loc_rec.address_line_1, 
                   lc_fetch_active_loc_rec.address_line_2,
                   lc_fetch_active_loc_rec.address_line_3,
                   ln_batch_id, 
                   lc_fetch_active_loc_rec.town_or_city, 
                   lc_fetch_active_loc_rec.country, 
                   CASE lc_fetch_active_loc_rec.country
                     WHEN 'CA' THEN NULL
                     ELSE NVL(lc_fetch_active_loc_rec.region_1,',')
                   END,
                   lv_created_by_module, 
                   lv_orig_system, 
                   lv_osr, 
                   lc_fetch_active_loc_rec.postal_code, 
                   lv_orig_system, 
                   lv_osr,
                   CASE lc_fetch_active_loc_rec.country
                     WHEN 'CA' THEN NULL
                     ELSE lc_fetch_active_loc_rec.region_2
                   END,  
                   CASE lc_fetch_active_loc_rec.country
                     WHEN 'CA' THEN lc_fetch_active_loc_rec.region_1
                     ELSE NULL  
                   END
               );

            -- Creating Party Site (US) for Master Internal Customer   

            INSERT INTO xxod_hz_imp_addresses_int
               (   address1, 
                   address2,
                   address3,
                   batch_id, 
                   city, 
                   country, 
                   county, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   postal_code, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   state,
                   province
               )
             VALUES
               (   lc_fetch_active_loc_rec.address_line_1, 
                   lc_fetch_active_loc_rec.address_line_2,
                   lc_fetch_active_loc_rec.address_line_3,
                   ln_batch_id , 
                   lc_fetch_active_loc_rec.town_or_city, 
                   lc_fetch_active_loc_rec.country, 
                   CASE lc_fetch_active_loc_rec.country
                     WHEN 'CA' THEN NULL
                     ELSE NVL(lc_fetch_active_loc_rec.region_1,',')
                   END,
                   lv_created_by_module, 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lc_fetch_active_loc_rec.postal_code, 
                   lv_orig_system, 
                   lv_osr||'_RMS_US', 
                   CASE 
                     WHEN lc_fetch_active_loc_rec.country = 'CA' THEN NULL
                     ELSE lc_fetch_active_loc_rec.region_2
                   END,  
                   CASE 
                     WHEN lc_fetch_active_loc_rec.country = 'CA' THEN lc_fetch_active_loc_rec.region_1
                     ELSE NULL  
                   END
               ); 

            -- Creating Party Site (CA) for Master Internal Customer   

            INSERT INTO xxod_hz_imp_addresses_int
               (   address1, 
                   address2,
                   address3,
                   batch_id, 
                   city, 
                   country, 
                   county, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   postal_code, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   state,
                   province
               )
             VALUES
               (   lc_fetch_active_loc_rec.address_line_1, 
                   lc_fetch_active_loc_rec.address_line_2,
                   lc_fetch_active_loc_rec.address_line_3,
                   ln_batch_id , 
                   lc_fetch_active_loc_rec.town_or_city, 
                   lc_fetch_active_loc_rec.country, 
                   CASE lc_fetch_active_loc_rec.country
                     WHEN 'CA' THEN NULL
                     ELSE NVL(lc_fetch_active_loc_rec.region_1,',')
                   END,
                   lv_created_by_module, 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lc_fetch_active_loc_rec.postal_code, 
                   lv_orig_system, 
                   lv_osr||'_RMS_CA', 
                   CASE 
                     WHEN lc_fetch_active_loc_rec.country = 'CA' THEN NULL
                     ELSE lc_fetch_active_loc_rec.region_2
                   END,  
                   CASE 
                     WHEN lc_fetch_active_loc_rec.country = 'CA' THEN lc_fetch_active_loc_rec.region_1
                     ELSE NULL  
                   END
               );   


            --------------------------------------------
            -- Step 5.1: Create BILL_TO Party Site Use
            --------------------------------------------   

            INSERT INTO xxod_hz_imp_addressuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   primary_flag, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   site_use_type
               )
            VALUES
               (   ln_batch_id, 
                   lv_created_by_module, 
                   lv_orig_system, 
                   lv_osr, 
                   'Y', 
                   lv_orig_system, 
                   lv_osr, 
                   'BILL_TO'
               );

            --------------------------------------------
            -- Step 5.2: Create SHIP_TO Party Site Use
            --------------------------------------------   

            INSERT INTO xxod_hz_imp_addressuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   primary_flag, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   site_use_type
               )
            VALUES
               (   ln_batch_id, 
                   lv_created_by_module, 
                   lv_orig_system, 
                   lv_osr, 
                   'Y', 
                   lv_orig_system, 
                   lv_osr, 
                   'SHIP_TO'
               ); 

            -- Create Ship_to (US)Party for Master Internal Customer

            INSERT INTO xxod_hz_imp_addressuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   primary_flag, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   site_use_type
               )
            VALUES
               (   ln_batch_id, 
                   lv_created_by_module, 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   'Y', 
                   lv_orig_system, 
                   lv_osr||'_RMS_US', 
                   'SHIP_TO'
               ); 

            -- Create Ship_to (CA)Party for Master Internal Customer

            INSERT INTO xxod_hz_imp_addressuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   primary_flag, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   site_use_type
               )
            VALUES
               (   ln_batch_id, 
                   lv_created_by_module, 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   'Y', 
                   lv_orig_system, 
                   lv_osr||'_RMS_CA', 
                   'SHIP_TO'
               );    



            ----------------------------
            -- Step 6: Create Account
            ----------------------------

            INSERT INTO xxod_hz_imp_accounts_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   account_orig_system_reference, 
                   customer_class_code, 
                   account_name, 
                   customer_type, 
                   account_orig_system, 
                   org_id
               )
            VALUES
               (   ln_batch_id,
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_osr,
                   lv_osr,
                   lc_fetch_active_loc_rec.attribute3,
                   lc_fetch_active_loc_rec.location_code,
                   'I',
                   lv_orig_system, 
                   CASE 
                      WHEN lc_fetch_active_loc_rec.country = 'CA' THEN ln_ca_org_id
                      ELSE ln_us_org_id
                   END  
               );

            --------------------------------
            -- Step 7: Create Account Site
            --------------------------------

            INSERT INTO xxod_hz_imp_account_sites_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   account_orig_system, 
                   account_orig_system_reference, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   acct_site_orig_system_ref, 
                   acct_site_orig_system, 
                   org_id
               )
            VALUES
               (   ln_batch_id, 
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_osr, 
                   lv_orig_system, 
                   lv_osr, 
                   lv_orig_system, 
                   lv_osr, 
                   lv_osr, 
                   lv_orig_system, 
                   CASE 
                      WHEN lc_fetch_active_loc_rec.country = 'CA' THEN ln_ca_org_id
                      ELSE ln_us_org_id
                   END
               );

            -- Create US Account Site under Master Internal Customer   

            INSERT INTO xxod_hz_imp_account_sites_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   account_orig_system, 
                   account_orig_system_reference, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   acct_site_orig_system_ref, 
                   acct_site_orig_system, 
                   org_id
               )
            VALUES
               (   ln_batch_id, 
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lv_orig_system, 
                   lv_osr||'_RMS_US', 
                   lv_osr||'_RMS_US', 
                   lv_orig_system, 
                   ln_us_org_id                
               ); 

            -- Create CA Account Site under Master Internal Customer   

            INSERT INTO xxod_hz_imp_account_sites_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   account_orig_system, 
                   account_orig_system_reference, 
                   site_orig_system, 
                   site_orig_system_reference, 
                   acct_site_orig_system_ref, 
                   acct_site_orig_system, 
                   org_id
               )
            VALUES
               (   ln_batch_id, 
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lv_orig_system, 
                   lv_osr||'_RMS_CA', 
                   lv_osr||'_RMS_CA', 
                   lv_orig_system, 
                   ln_ca_org_id                
               );      


            --------------------------------------------
            -- Step 8: Create BILL_TO Account Site Uses
            --------------------------------------------   

            INSERT INTO xxod_hz_imp_acct_siteuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   acct_site_orig_system, 
                   acct_site_orig_system_ref, 
                   account_orig_system, 
                   account_orig_system_reference, 
                   site_use_code, 
                   org_id, 
                   location
               )
            VALUES
               (   ln_batch_id,
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_osr, 
                   lv_orig_system, 
                   lv_osr, 
                   lv_orig_system, 
                   lv_osr, 
                   'BILL_TO', 
                   CASE 
                      WHEN lc_fetch_active_loc_rec.country = 'CA' THEN ln_ca_org_id
                      ELSE ln_us_org_id
                   END, 
                   SUBSTR(lc_fetch_active_loc_rec.location_code,1,40)
               );

            --------------------------------------------
            -- Step 8: Create SHIP_TO Account Site Uses
            --------------------------------------------    


            INSERT INTO xxod_hz_imp_acct_siteuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   acct_site_orig_system, 
                   acct_site_orig_system_ref, 
                   account_orig_system, 
                   account_orig_system_reference, 
                   site_use_code, 
                   org_id, 
                   location
               )
            VALUES
               (   ln_batch_id,
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_osr, 
                   lv_orig_system, 
                   lv_osr, 
                   lv_orig_system, 
                   lv_osr, 
                   'SHIP_TO', 
                   CASE 
                      WHEN lc_fetch_active_loc_rec.country = 'CA' THEN ln_ca_org_id
                      ELSE ln_us_org_id
                   END, 
                   SUBSTR(lc_fetch_active_loc_rec.location_code,1,40)
               );

            -- Create ship_to (US) under Master Internal   

            INSERT INTO xxod_hz_imp_acct_siteuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   acct_site_orig_system, 
                   acct_site_orig_system_ref, 
                   account_orig_system, 
                   account_orig_system_reference, 
                   site_use_code, 
                   org_id, 
                   location
               )
            VALUES
               (   ln_batch_id,
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lv_orig_system, 
                   lv_osr||'_RMS_US', 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   'SHIP_TO', 
                   ln_us_org_id,
                   SUBSTR(lc_fetch_active_loc_rec.location_code,1,40)
               );  

            -- Create ship_to (CA) under Master Internal   

            INSERT INTO xxod_hz_imp_acct_siteuses_int
               (   batch_id, 
                   created_by_module, 
                   party_orig_system, 
                   party_orig_system_reference, 
                   acct_site_orig_system, 
                   acct_site_orig_system_ref, 
                   account_orig_system, 
                   account_orig_system_reference, 
                   site_use_code, 
                   org_id, 
                   location
               )
            VALUES
               (   ln_batch_id,
                   lv_created_by_module,
                   lv_orig_system, 
                   lv_master_int_osr, 
                   lv_orig_system, 
                   lv_osr||'_RMS_CA', 
                   lv_orig_system, 
                   lv_master_int_osr, 
                   'SHIP_TO', 
                   ln_ca_org_id,
                   SUBSTR(lc_fetch_active_loc_rec.location_code,1,40)
               );      


            ------------------------------------
            -- Step 9: Create Payment Methods
            ------------------------------------ 
            BEGIN
               SELECT name
               INTO   lv_pay_method_name
               FROM   ar_receipt_methods 
               WHERE  attribute6 = lc_fetch_active_loc_rec.location_code;
            EXCEPTION
               WHEN OTHERS THEN
                  lv_pay_method_name := NULL;
            END;     

            IF lv_pay_method_name  IS NOT NULL THEN
               INSERT INTO xxod_hz_imp_acct_paymthd_int
                  (   batch_id, 
                      created_by_module, 
                      party_orig_system, 
                      party_orig_system_reference, 
                      account_orig_system, 
                      account_orig_system_reference, 
                      org_id, 
                      payment_method_name, 
                      primary_flag, 
                      start_date
                  )
               VALUES
                  (   ln_batch_id, 
                      lv_created_by_module, 
                      lv_orig_system, 
                      lv_osr, 
                      lv_orig_system, 
                      lv_osr, 
                      CASE 
                         WHEN lc_fetch_active_loc_rec.country = 'CA' THEN ln_ca_org_id
                         ELSE ln_us_org_id
                      END, 
                      lv_pay_method_name, 
                      'N', 
                      ld_sysdate
                  );
            END IF;    
            COMMIT;
         END IF;
      END IF;   
      
   END LOOP;
   
   -------------------------
   -- Activate the Batch
   -------------------------
   
   HZ_IMP_BATCH_SUMMARY_V2PUB.activate_batch 
      (  p_batch_id      => ln_batch_id, 
         x_return_status => lv_return_status, 
         x_msg_count     => ln_msg_count, 
         x_msg_data      => lv_msg_data
      );  

   IF lv_return_status <> FND_API.G_RET_STS_SUCCESS THEN
      IF ln_msg_count > 0 THEN
         fnd_file.put_line (fnd_file.log,'Warning: Error while activating batch_id -'||ln_batch_id);
         FOR ln_counter IN 1..ln_msg_count
         LOOP
            fnd_file.put_line (fnd_file.log,'Warning ->'||fnd_msg_pub.get(ln_counter, FND_API.G_FALSE));
         END LOOP;
         fnd_msg_pub.delete_msg;
      END IF;
   ELSE
      fnd_file.put_line (fnd_file.log,'Batch_id - '||ln_batch_id||' Successfully activated!!');
   END IF;    
   

EXCEPTION
   WHEN le_skip_process THEN
      fnd_file.put_line (fnd_file.log,'Program Aborted... ');
      x_retcode := 2;
   WHEN OTHERS THEN
      x_errbuf  := 'Unexpected Error in procedure populate_batch - '||SQLERRM;
      fnd_file.put_line(fnd_file.log, x_errbuf);
      x_retcode := 2;
END populate_batch;


-- +===================================================================+
-- | Name        :  inactivate_accounts                                |
-- | Description :  This program would inactvate accounts for which the|
-- |                corresponding hr_location records have been        |
-- |                inactivated.                                       |
-- |                                                                   |
-- | Parameters  :                                                     |
-- |                                                                   |
-- | Returns     :                                                     |
-- |                                                                   |
-- +===================================================================+
PROCEDURE inactivate_accounts
      (  x_errbuf            OUT VARCHAR2,
         x_retcode           OUT VARCHAR2
      )
AS

CURSOR lc_fetch_inactive_accts_cur
IS
SELECT hl.*, 'Y' trade_flag, haou.attribute1 haou_attribute1
FROM   hr_locations hl,
       hr_all_organization_units haou
WHERE  NVL(hl.inactive_date, SYSDATE+1) < SYSDATE
AND    hl.attribute3 IS NOT NULL
AND    hl.attribute3 LIKE 'TRADE%'
AND    haou.location_id = hl.location_id
UNION
SELECT hl.*, 'N' trade_flag, NULL haou_attribute1
FROM   hr_locations hl
WHERE  NVL(hl.inactive_date, SYSDATE+1) < SYSDATE
AND    hl.attribute3     IS NOT NULL
AND    hl.attribute3   LIKE 'NON TRADE%'
AND    hl.address_line_1 IS NOT NULL
AND    hl.town_or_city   IS NOT NULL
AND    hl.country        IS NOT NULL
AND    hl.postal_code    IS NOT NULL
-- Changes for Ver 1.1 begins
AND    ((hl.country = 'CA' AND hl.region_1 IS NOT NULL) OR hl.country = 'US')
AND    ((hl.country = 'US' AND hl.region_2 IS NOT NULL) OR hl.country = 'CA');
-- Changes for Ver 1.1 ends;


lv_orig_system                   VARCHAR2(100):= 'RMS';
lv_osr                           VARCHAR2(100);
ln_osr_retcode                   NUMBER;
lv_osr_errbuf                    VARCHAR2(2000);
ln_cust_account_id               NUMBER;
ln_cust_acct_site_id             NUMBER;
lv_master_int_osr                VARCHAR2(100) := 'MASTER_OD_INT';
ln_mas_cust_account_id           NUMBER;
ln_mas_us_cust_acct_site_id      NUMBER;
ln_mas_ca_cust_acct_site_id      NUMBER;
ln_party_site_id                 NUMBER;
ln_mas_us_party_site_id          NUMBER;
ln_mas_ca_party_site_id          NUMBER;
ln_records_success               NUMBER := 0;
ln_act_records_success           NUMBER := 0;
lt_cust_acct_site_rec            HZ_CUST_ACCOUNT_SITE_V2PUB.CUST_ACCT_SITE_REC_TYPE;
lt_cust_account_rec              HZ_CUST_ACCOUNT_V2PUB.CUST_ACCOUNT_REC_TYPE;
ln_object_version_number         NUMBER;
lv_return_status                 VARCHAR2(10);
ln_msg_count                     NUMBER;
ln_msg_text                      VARCHAR2(2000);
LC_MSG_DATA                      VARCHAR2(2000);

BEGIN
    ----------------------------------------
    -- Get cust_acct_id for Master Customer
    ----------------------------------------
    
    XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_master_int_osr,
             p_owner_table_name   => 'HZ_CUST_ACCOUNTS',
             x_owner_table_id     => ln_mas_cust_account_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );

   FOR lc_fetch_inactive_accts_rec in lc_fetch_inactive_accts_cur
   LOOP
      -----------------
      -- Formulate OSR
      -----------------
      IF lc_fetch_inactive_accts_rec.trade_flag = 'Y' THEN
         lv_osr := LPAD(lc_fetch_inactive_accts_rec.haou_attribute1,6,0)||lc_fetch_inactive_accts_rec.country;
      ELSE
         lv_osr := lc_fetch_inactive_accts_rec.location_id;
      END IF;  
      
      -------------------
      -- Get cust_acct_id
      -------------------
      XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_osr,
             p_owner_table_name   => 'HZ_CUST_ACCOUNTS',
             x_owner_table_id     => ln_cust_account_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );
      
      -------------------------
      -- Get party_site_id
      -------------------------
      XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_osr,
             p_owner_table_name   => 'HZ_PARTY_SITES',
             x_owner_table_id     => ln_party_site_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );   
      
      -------------------------
      -- Get cust_acct_site_id
      -------------------------
      XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_osr,
             p_owner_table_name   => 'HZ_CUST_ACCT_SITES_ALL',
             x_owner_table_id     => ln_cust_acct_site_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );
         
      -----------------------
      -- Inactivate the site   
      -----------------------
      IF ln_cust_acct_site_id IS NOT NULL THEN 
         ln_object_version_number                        := NULL;
         lt_cust_acct_site_rec.cust_acct_site_id         := NULL;
         lt_cust_acct_site_rec.cust_account_id           := NULL;
         lt_cust_acct_site_rec.party_site_id             := NULL;
         lt_cust_acct_site_rec.status                    := NULL;

         lt_cust_acct_site_rec.cust_acct_site_id         := ln_cust_acct_site_id;
         lt_cust_acct_site_rec.cust_account_id           := ln_cust_account_id;
         lt_cust_acct_site_rec.party_site_id             := ln_party_site_id;
         lt_cust_acct_site_rec.status                    := 'I';

         SELECT object_version_number
         INTO   ln_object_version_number
         FROM   hz_cust_acct_sites_all
         WHERE  cust_acct_site_id = ln_cust_acct_site_id;

         hz_cust_account_site_v2pub.update_cust_acct_site
               (   p_init_msg_list             => FND_API.G_TRUE,
                   p_cust_acct_site_rec        => lt_cust_acct_site_rec,
                   p_object_version_number     => ln_object_version_number,
                   x_return_status             => lv_return_status,
                   x_msg_count                 => ln_msg_count,
                   x_msg_data                  => lc_msg_data
               );
         IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN

            ln_records_success := ln_records_success + 1;

         ELSE
            ln_msg_text := NULL;
            IF ln_msg_count > 0 THEN
               fnd_file.put_line(fnd_file.log, '---------------------------------------');
               fnd_file.put_line(fnd_file.log, 'update_cust_acct_site returned Error.');
               fnd_file.put_line(fnd_file.log, 'OSR                  -'||lv_osr);
               fnd_file.put_line(fnd_file.log, 'ln_cust_acct_site_id -'||ln_cust_acct_site_id);
               FOR counter IN 1..ln_msg_count 
               LOOP
                  ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                  fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
               END LOOP;
               FND_MSG_PUB.Delete_Msg;

            END IF; 
         END IF;
      END IF;   
         
      -------------------------
      -- Get party_site_id
      -------------------------
      XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_osr||'_RMS_US',
             p_owner_table_name   => 'HZ_PARTY_SITES',
             x_owner_table_id     => ln_mas_us_party_site_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );   
      
      
      ---------------------------------------------
      -- Get US cust_acct_site_id for Master Customer   
      ---------------------------------------------
      XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_osr||'_RMS_US',
             p_owner_table_name   => 'HZ_CUST_ACCT_SITES_ALL',
             x_owner_table_id     => ln_mas_us_cust_acct_site_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );
         
      -----------------------
      -- Inactivate the site   
      -----------------------
      IF ln_mas_us_cust_acct_site_id IS NOT NULL THEN
         ln_object_version_number                        := NULL;
         lt_cust_acct_site_rec.cust_acct_site_id         := NULL;
         lt_cust_acct_site_rec.cust_account_id           := NULL;
         lt_cust_acct_site_rec.party_site_id             := NULL;
         lt_cust_acct_site_rec.status                    := NULL;

         lt_cust_acct_site_rec.cust_acct_site_id         := ln_mas_us_cust_acct_site_id;
         lt_cust_acct_site_rec.cust_account_id           := ln_mas_cust_account_id;
         lt_cust_acct_site_rec.party_site_id             := ln_mas_us_party_site_id;
         lt_cust_acct_site_rec.status                    := 'I';

         SELECT object_version_number
         INTO   ln_object_version_number
         FROM   hz_cust_acct_sites_all
         WHERE  cust_acct_site_id = ln_mas_us_cust_acct_site_id;

         hz_cust_account_site_v2pub.update_cust_acct_site
               (   p_init_msg_list             => FND_API.G_TRUE,
                   p_cust_acct_site_rec        => lt_cust_acct_site_rec,
                   p_object_version_number     => ln_object_version_number,
                   x_return_status             => lv_return_status,
                   x_msg_count                 => ln_msg_count,
                   x_msg_data                  => lc_msg_data
               );
         IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN

            ln_records_success := ln_records_success + 1;

         ELSE
            ln_msg_text := NULL;
            IF ln_msg_count > 0 THEN
               fnd_file.put_line(fnd_file.log, '---------------------------------------');
               fnd_file.put_line(fnd_file.log, 'update_cust_acct_site returned Error.');
               fnd_file.put_line(fnd_file.log, 'OSR                  -'||lv_osr||'_RMS_US');
               fnd_file.put_line(fnd_file.log, 'ln_cust_acct_site_id -'||ln_mas_us_cust_acct_site_id);
               FOR counter IN 1..ln_msg_count 
               LOOP
                  ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                  fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
               END LOOP;
               FND_MSG_PUB.Delete_Msg;

            END IF; 
         END IF;
      END IF; 
      
      -------------------------
      -- Get party_site_id
      -------------------------
      XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_osr||'_RMS_CA',
             p_owner_table_name   => 'HZ_PARTY_SITES',
             x_owner_table_id     => ln_mas_ca_party_site_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );   


      ---------------------------------------------
      -- Get US cust_acct_site_id for Master Customer   
      ---------------------------------------------
      XX_CDH_CONV_MASTER_PKG.get_osr_owner_table_id
         (   p_orig_system        => lv_orig_system,
             p_orig_sys_reference => lv_osr||'_RMS_CA',
             p_owner_table_name   => 'HZ_CUST_ACCT_SITES_ALL',
             x_owner_table_id     => ln_mas_ca_cust_acct_site_id,
             x_retcode            => ln_osr_retcode,
             x_errbuf             => lv_osr_errbuf
         );

      -----------------------
      -- Inactivate the site   
      -----------------------
      IF ln_mas_ca_cust_acct_site_id IS NOT NULL THEN
         ln_object_version_number                        := NULL;
         lt_cust_acct_site_rec.cust_acct_site_id         := NULL;
         lt_cust_acct_site_rec.cust_account_id           := NULL;
         lt_cust_acct_site_rec.party_site_id             := NULL;
         lt_cust_acct_site_rec.status                    := NULL;

         lt_cust_acct_site_rec.cust_acct_site_id         := ln_mas_ca_cust_acct_site_id;
         lt_cust_acct_site_rec.cust_account_id           := ln_mas_cust_account_id;
         lt_cust_acct_site_rec.party_site_id             := ln_mas_ca_party_site_id;
         lt_cust_acct_site_rec.status                    := 'I';

         SELECT object_version_number
         INTO   ln_object_version_number
         FROM   hz_cust_acct_sites_all
         WHERE  cust_acct_site_id = ln_mas_ca_cust_acct_site_id;

         hz_cust_account_site_v2pub.update_cust_acct_site
               (   p_init_msg_list             => FND_API.G_TRUE,
                   p_cust_acct_site_rec        => lt_cust_acct_site_rec,
                   p_object_version_number     => ln_object_version_number,
                   x_return_status             => lv_return_status,
                   x_msg_count                 => ln_msg_count,
                   x_msg_data                  => lc_msg_data
               );
         IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN

            ln_records_success := ln_records_success + 1;

         ELSE
            ln_msg_text := NULL;
            IF ln_msg_count > 0 THEN
               fnd_file.put_line(fnd_file.log, '---------------------------------------');
               fnd_file.put_line(fnd_file.log, 'update_cust_acct_site returned Error.');
               fnd_file.put_line(fnd_file.log, 'OSR                  -'||lv_osr||'_RMS_CA');
               fnd_file.put_line(fnd_file.log, 'ln_cust_acct_site_id -'||ln_mas_ca_cust_acct_site_id);
               FOR counter IN 1..ln_msg_count 
               LOOP
                  ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                  fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
               END LOOP;
               FND_MSG_PUB.Delete_Msg;

            END IF; 
         END IF;
      END IF;   
      
      ---------------------------
      -- Inactivate the account   
      ---------------------------
      IF ln_cust_account_id IS NOT NULL THEN
      
         lt_cust_account_rec.cust_account_id           := NULL;
         lt_cust_account_rec.status                    := NULL;
         ln_object_version_number                      := NULL;

         lt_cust_account_rec.cust_account_id           := ln_cust_account_id;
         lt_cust_account_rec.status                    := 'I';

         SELECT object_version_number
         INTO   ln_object_version_number
         FROM   hz_cust_accounts
         WHERE  cust_account_id = ln_cust_account_id;

         HZ_CUST_ACCOUNT_V2PUB.update_cust_account
               (   p_init_msg_list          => FND_API.G_TRUE,
                   p_cust_account_rec       => lt_cust_account_rec,
                   p_object_version_number  => ln_object_version_number,
                   x_return_status          => lv_return_status,
                   x_msg_count              => ln_msg_count,
                   x_msg_data               => lc_msg_data
               );
         IF lv_return_status = FND_API.G_RET_STS_SUCCESS THEN

            ln_act_records_success := ln_act_records_success + 1;

         ELSE
            ln_msg_text := NULL;
            IF ln_msg_count > 0 THEN
               fnd_file.put_line(fnd_file.log, '---------------------------------------');
               fnd_file.put_line(fnd_file.log, 'update_cust_account returned Error.');
               fnd_file.put_line(fnd_file.log, 'OSR                -'||lv_osr);
               fnd_file.put_line(fnd_file.log, 'ln_cust_account_id -'||ln_cust_account_id);
               FOR counter IN 1..ln_msg_count 
               LOOP
                  ln_msg_text := ln_msg_text||' '||FND_MSG_PUB.Get(counter, FND_API.G_FALSE);
                  fnd_file.put_line(fnd_file.log,'Error - '|| FND_MSG_PUB.Get(counter, FND_API.G_FALSE));
               END LOOP;
               FND_MSG_PUB.Delete_Msg;

            END IF; 
         END IF;
      END IF;   
   
   END LOOP;
   
   fnd_file.put_line(fnd_file.log, 'Accounts Successfully Inactivated -'||ln_act_records_success);
   fnd_file.put_line(fnd_file.log, 'Account Sites Successfully Inactivated -'||ln_records_success);


EXCEPTION
   WHEN OTHERS THEN
 
      x_errbuf  := 'Unexpected Error in procedure inactivate_accounts - '||SQLERRM;
      fnd_file.put_line(fnd_file.log, x_errbuf);
      x_retcode := 2;

END inactivate_accounts;

END XX_CDH_INT_LOCATIONS_PKG;
/
SHOW ERRORS;

