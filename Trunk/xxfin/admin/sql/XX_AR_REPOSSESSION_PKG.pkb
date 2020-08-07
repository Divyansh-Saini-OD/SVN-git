CREATE OR REPLACE
PACKAGE BODY XX_AR_REPOSSESSION_PKG
AS

-- +==========================================  ============================+
-- |                  Office Depot - Project Simplify                       |
-- |                    Office Depot Organization                           |
-- +==========================================  ============================+
-- | Name  : XX_AR_REPOSSESSION_PKG                                         |
-- | Description      :  Package to format customer account data that       |
-- |                     will be sent to a collection agency.               |
-- |                                                                        |
-- |                                                                        |
-- |                                                                        |
-- |Change Record:                                                          |
-- |===============                                                         |
-- |Version     Date        Author              Remarks                     |
-- |=======     ==========  ===========         ============================|
-- |DRAFT 1A    21-JUL-2008 D. Gaudard          Initial draft version       |
-- |Defect 3996 18-JAN-2010 D.Gaudard           Remove customer status check|
-- |                                            when selecting customer to  |
-- |                                            send to an agency           |
-- |Defect 5072 05-May-2010 Navin Kumar         Passed fourth parameter to  |
-- |                                            UTL function of program.    |
-- |Defect#5103 24-Jun-2010 Cindhu Nagarajan    Moved Commit after common   |
-- |                                            file program submission to  |
-- |                                            avoid missing accounts while|
-- |                                            restarting the job in case  |
-- |                                            of job failure.             |
-- |1.3         09-Sep-2010 Ganesan JV     Fixed for defect 7023       |
-- |                                       Updated who columns in      |
-- |                                       IEX_REPOSSESSIONS           |
-- +========================================================================+

    ---------------------
    -- Global Variables
    ---------------------


    g_filehandle           UTL_FILE.FILE_TYPE;
    gc_output_file         VARCHAR2 (2500);
    gc_test_indicator      VARCHAR2 (1)  := 'P';           -- Prod ='P' Test = 'T'
    gc_edi_qualifier       VARCHAR2 (2);                   -- Prod ='01'Test ='ZZ'
    gc_current_step        VARCHAR2 (250);
    gn_total_record_cnt     NUMBER := 0;
    gn_account_total_cnt    NUMBER := 0;
    gn_max_linesize         NUMBER := 32767;              -- Added for Defect 5072


-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : SHIPTO_NOTES_DETAILS                                      |
-- | Description : This program will create and write details for the  |
-- |               transactions shipto and notes.                      |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  24-JUL-2008 D.Gaurard          Initial draft version     |
-- |                                                                   |
-- +===================================================================+


    PROCEDURE SHIPTO_NOTES_DETAILS (p_cust_account_id  IN  NUMBER,
                                   p_ship_to_site_use_id IN NUMBER,
                                   p_customer_trx_id IN NUMBER)
           AS


  lc_print_line           VARCHAR2(2500);
  lc_ship_location        apps.ar_ship_address_v.location%type;
  lc_ship_address1        apps.ar_ship_address_v.address1%type;
  lc_ship_address2        apps.ar_ship_address_v.address2%type;
  lc_ship_city            apps.ar_ship_address_v.city%type;
  lc_ship_state           apps.ar_ship_address_v.state%type;
  lc_ship_province        apps.ar_ship_address_v.province%type;
  lc_ship_country         apps.ar_ship_address_v.country%type;
  lc_ship_postal_code     apps.ar_ship_address_v.postal_code%type;
  lc_created_by           apps.ar_notes.created_by%type;
  lc_creation_date        apps.ar_notes.creation_date%type;
  lc_note_type            apps.ar_notes.note_type%type;
  lc_text                 apps.ar_notes.text%type;
  lc_type                 apps.ra_cust_trx_types_all.type%type;


 CURSOR lcu_shipto_cursor
        IS
       SELECT
 sh.location,
 sh.address1,
 sh.address2,
 sh.city,
 sh.state,
 sh.province,
 sh.country,
 sh.postal_code
FROM   apps.ar_ship_address_v SH
WHERE  sh.site_use_id = p_ship_to_site_use_id
AND    sh.primary_flag = 'Y';

CURSOR lcu_ar_notes_cursor
        IS
       SELECT
       arn.created_by,
       arn.creation_date,
       arn.note_type,
       arn.text
  FROM apps.ar_notes arn,
       apps.ra_customer_trx_all t
  WHERE arn.customer_trx_id = p_customer_trx_id
    AND t.customer_trx_id = arn.customer_trx_id
    AND t.bill_to_customer_id = p_cust_account_id;

CURSOR  lcu_jtf_notes_cursor
        IS
       SELECT
       jtf.created_by,
       jtf.creation_date,
       jtf.decoded_source_meaning,
       jtf.notes
  FROM jtf_notes_vl jtf,
       ra_cm_requests_all cm,
       iex_disputes ds
  WHERE cm.customer_trx_id = p_customer_trx_id
    AND cm.request_id = ds.cm_request_id
    AND ds.cm_request_id = jtf.source_object_id
    AND ((jtf.source_object_code = 'IEX_ACCOUNT' AND   jtf.source_object_meaning = 'Collections Account')
         OR (jtf.source_object_code = 'IEX_REPOSSESSION' AND jtf.source_object_meaning = 'Collection Repossession'))
    AND jtf.source_object_meaning = 'Collections Account'
    AND jtf.note_status_meaning = 'Public';

  BEGIN
   OPEN lcu_shipto_cursor;
    -- loop through ship to data for the transaction
    -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Ship TO');
       LOOP
          FETCH lcu_shipto_cursor INTO
                lc_ship_location,
                lc_ship_address1,
                lc_ship_address2,
                lc_ship_city,
                lc_ship_state,
                lc_ship_province,
                lc_ship_country,
                lc_ship_postal_code;

          EXIT WHEN lcu_shipto_cursor%NOTFOUND;

          ------------------------------------------------------
          -- write the ship to detail record to the output file
          ------------------------------------------------------
          lc_print_line := 'DS' || '|' ||
                            trim(lc_ship_location) || '|' ||
                            trim(lc_ship_address1) || '|' ||
                            trim(lc_ship_address2) || '|' ||
                            trim(lc_ship_city) || '|' ||
                            trim(lc_ship_state)|| '|' ||
                            trim(lc_ship_province)|| '|' ||
                            trim(lc_ship_postal_code)|| '|'||
                            trim(lc_ship_country)    ||
                            chr(13) ;


          UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
          FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

          gn_total_record_cnt  := gn_total_record_cnt +1;

       END LOOP;
       CLOSE lcu_shipto_cursor;

       OPEN lcu_ar_notes_cursor;
       -- loop through notes for the transaction
       -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Notes');

       LOOP
          FETCH lcu_ar_notes_cursor INTO
                lc_created_by,
                lc_creation_date,
                lc_note_type,
                lc_text;

          EXIT WHEN lcu_ar_notes_cursor%NOTFOUND;
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Notes');
          ------------------------------------------------------
          -- write the notes detail to the output file
          ------------------------------------------------------
          lc_print_line := 'DN' || '|' ||
                            trim(lc_created_by) || '|' ||
                            trim(lc_creation_date) || '|' ||
                            trim(lc_note_type) || '|' ||
                            trim(lc_text)      ||
                            chr(13) ;

          UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
          FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

          gn_total_record_cnt  := gn_total_record_cnt +1;

       END LOOP;
       CLOSE lcu_ar_notes_cursor;

        OPEN lcu_jtf_notes_cursor;
       -- loop through notes for the transaction
       -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Notes');

       LOOP
          FETCH lcu_jtf_notes_cursor INTO
                lc_created_by,
                lc_creation_date,
                lc_note_type,
                lc_text;

          EXIT WHEN lcu_jtf_notes_cursor%NOTFOUND;
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Notes');
          ------------------------------------------------------
          -- write the notes detail to the output file
          ------------------------------------------------------
          lc_print_line := 'DN' || '|' ||
                            trim(lc_created_by) || '|' ||
                            trim(lc_creation_date) || '|' ||
                            trim(lc_note_type) || '|' ||
                            trim(lc_text)      ||
                            chr(13) ;

          UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
          FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

          gn_total_record_cnt  := gn_total_record_cnt +1;

       END LOOP;
       CLOSE lcu_jtf_notes_cursor;
  END SHIPTO_NOTES_DETAILS;


  -- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : TRANSACTION_DETAILS                                           |
-- | Description : This program will create and write details for the  |
-- |               accounts transactions                      |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  24-JUL-2008 D.Gaurard          Initial draft version     |
-- |                                                                   |
-- +===================================================================+


    PROCEDURE TRANSACTION_DETAILS (p_cust_account_id  IN  NUMBER )
           AS

  lc_print_line           VARCHAR2(2500);
  lc_trx_number           apps.ra_customer_trx_all.trx_number%type;
  lc_trx_date             apps.ra_customer_trx_all.trx_date%type;
  lc_customer_trx_id      apps.ra_customer_trx_all.customer_trx_id%type;
  lc_amount_due_original  apps.ar_payment_schedules_all.amount_due_original%type;
  lc_amount_due_remaining apps.ar_payment_schedules_all.amount_due_remaining%type;
  lc_due_date             apps.ar_payment_schedules_all.due_date%type;
  lc_ship_to_site_use_id  apps.ra_customer_trx_all.ship_to_site_use_id%type;
  lc_type                 apps.RA_CUST_TRX_TYPES_ALL.type%type;
  lc_cust_account_id      apps.hz_cust_acct_sites_all.cust_account_id%type;

  CURSOR lcu_trx_cursor
      IS
  SELECT
    tr.trx_number,
    tr.trx_date,
    tr.customer_trx_id,
    py.amount_due_original,
    py.amount_due_remaining,
    py.due_date,
    tr.ship_to_site_use_id,
    ty.TYPE
  FROM   apps.ra_customer_trx_all tr,
         apps.ra_cust_trx_types_all ty,
         apps.ar_payment_schedules_all py
  WHERE  tr.bill_to_customer_id = p_cust_account_id
    AND  tr.bill_to_customer_id = py.customer_id
    AND  tr.trx_number = py.trx_number
    AND  tr.cust_trx_type_id = ty.cust_trx_type_id;

BEGIN
lc_cust_account_id := p_cust_account_id;
OPEN lcu_trx_cursor;

      -- loop through transaction for the account

          LOOP
            --   FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Account Transactions');

               FETCH lcu_trx_cursor INTO
                    lc_trx_number,
                    lc_trx_date,
                    lc_customer_trx_id,
                    lc_amount_due_original,
                    lc_amount_due_remaining,
                    lc_due_date,
                    lc_ship_to_site_use_id,
                    lc_type;

                EXIT WHEN lcu_trx_cursor%NOTFOUND;

                -- write the transaction detail to the output file
                lc_print_line := 'DT' || '|' || trim(lc_trx_number) || '|' ||
                               trim(lc_type) || '|' ||
                               trim(lc_trx_date) || '|' ||
                               trim(lc_customer_trx_id) || '|' ||
                               RTRIM(LTRIM(to_char(substr(NVL(lc_amount_due_original,0)
                                    ,1,18),'999999999999999.99')))|| '|' ||
                               RTRIM(LTRIM(to_char(substr(NVL(lc_amount_due_remaining,0)
                                    ,1,18),'999999999999999.99')))|| '|' ||
                               trim(lc_due_date)   ||
                               chr(13) ;

               UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
               FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
               FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

               gn_total_record_cnt  := gn_total_record_cnt +1;

               -- go find the ship to and note details for this transaction
               SHIPTO_NOTES_DETAILS(lc_cust_account_id,
                                    lc_ship_to_site_use_id,
                                    lc_customer_trx_id);
      END LOOP;
      CLOSE lcu_trx_cursor;
END TRANSACTION_DETAILS;

-----------------------------------------------------------------------------------------------

-- +===================================================================+
-- |                  Office Depot - Project Simplify                  |
-- |                    Office Depot Organization                      |
-- +===================================================================+
-- | Name  : REPOSSESSION_FORMAT                                       |
-- | Description :Main program called to format account data.          |
-- |                                                                   |
-- |                                                                   |
-- |Change Record:                                                     |
-- |===============                                                    |
-- |Version   Date        Author           Remarks                     |
-- |=======   ==========  =============    ============================|
-- |DRAFT 1A  21-JUL-2008 D. Gaudard       Initial draft version       |
-- |                                                                   |
-- +===================================================================+


   PROCEDURE REPOSSESSION_FORMAT(x_errbuff OUT NOCOPY VARCHAR2,
                                 x_retcode OUT NOCOPY VARCHAR2,
                                 p_collector_id IN VARCHAR2)
    AS
        -- ******************************************
        -- Variables defined
        -- ******************************************
        gn_request_id           NUMBER:= FND_GLOBAL.CONC_REQUEST_ID();

        gn_index                NUMBER := 0;
        ln_count                number := 0;
        lc_update_flag          CHAR := 'N';
        ln_req_id               NUMBER;
        lc_file_id              VARCHAR2(8);
        lc_time_stamp           DATE := SYSDATE;
        lc_file_header          VARCHAR2(2500);
        lc_file_trailer         VARCHAR2(2500);
        lc_print_line           VARCHAR2(2500);
        ln_contact_info         VARCHAR2(100);
        sv_contact_info         VARCHAR2(100);
        lc_disp_status          iex_repossessions.disposition_code%type := 'APPROVED_PEND';
        lc_delinquency_id       iex_repossessions.delinquency_id%type;
        lc_account_number       apps.hz_cust_accounts.account_number%type;
        lc_account_name         apps.hz_cust_accounts.account_name%type;
        lc_customer_name        apps.ar_customers_v.customer_name%type;
        lc_status               apps.hz_cust_accounts.status%type;
        lc_legacy_number        apps.hz_cust_accounts.orig_system_reference%type;
        lc_party_id             apps.hz_cust_accounts.party_id%type;
        lc_cust_acct_site_id    hz_cust_acct_sites_all.cust_acct_site_id%type;
        lc_cust_account_id      apps.hz_cust_acct_sites_all.cust_account_id%type;
        sv_cust_account_id      apps.hz_cust_acct_sites_all.cust_account_id%type;
        lc_party_site_id        apps.hz_cust_acct_sites_all.party_site_id%type;
        lc_site_use_code        apps.hz_cust_site_uses_all.site_use_code%type;
        lc_area_code            apps.ra_phones.area_code%type;
        lc_phone_number         apps.ra_phones.phone_number%type;
        lc_phone_type           apps.ra_phones.phone_type%type;
        lc_address1             apps.ar_addresses_v.address1%type;
        lc_address2             apps.ar_addresses_v.address2%type;
        lc_city                 apps.ar_addresses_v.city%type;
        lc_state                apps.ar_addresses_v.state%type;
        lc_province             apps.ar_addresses_v.province%type;
        lc_country              apps.ar_addresses_v.country%type;
        lc_postal_code          apps.ar_addresses_v.postal_code%type;
        lc_collector_id         apps.AR_collectors.collector_id%type;
        lc_collector_name       apps.AR_collectors.name%type;
        lc_description          apps.AR_collectors.description%type;
        lc_first_name           apps.ar_contacts_v.first_name%type;
        lc_last_name            apps.ar_contacts_v.last_name%type;
        lc_contact_id           apps.ar_contacts_v.contact_id%type;
        lc_usage_meaning        apps.ar_contact_roles_v.usage_meaning%type;
        lc_usage_code           apps.ar_contact_roles_v.usage_code%type;
        lc_primary_flag         apps.ar_contact_roles_v.primary_flag%type;
        ln_total_due            apps.ar_payment_schedules_all.amount_due_remaining%type;
        lc_created_by           apps.ar_notes.created_by%type;
        lc_creation_date        apps.ar_notes.creation_date%type;
        lc_note_type            apps.ar_notes.note_type%type;
        lc_text                 apps.ar_notes.text%type;
        ln_email_address        apps.hz_contact_points.email_address%type;
        ln_contact_point_purpose apps.hz_contact_points.contact_point_purpose%type;
        ln_contact_point_type   apps.hz_contact_points.contact_point_type%type;
        hd_contact_point_type   apps.hz_contact_points.contact_point_type%type;
        ln_phone_area_code      apps.hz_contact_points.phone_area_code%type;
        ln_phone_number         apps.hz_contact_points.phone_number%type;
        ln_phone_line_type      apps.hz_contact_points.phone_line_type%type;
        lc_prev_contact_id      apps.ar_contacts_v.contact_id%type;
      --  sv_phone_area_code      apps.hz_contact_points.phone_area_code%type;
      --  sv_phone_number         apps.hz_contact_points.phone_number%type;
      --  sv_phone_line_type      apps.hz_contact_points.phone_line_type%type;
        sv_first_name           apps.ar_contacts_v.first_name%type;
        sv_last_name            apps.ar_contacts_v.last_name%type;
        sv_contact_id           apps.ar_contacts_v.contact_id%type;
        sv_usage_meaning        apps.ar_contact_roles_v.usage_meaning%type;
        sv_usage_code           apps.ar_contact_roles_v.usage_code%type;
        sv_email_address        apps.hz_contact_points.email_address%type;
        sv_contact_point_purpose apps.hz_contact_points.contact_point_purpose%type;
        sv_contact_point_type   apps.hz_contact_points.contact_point_type%type;
        sv_phone_area_code      apps.hz_contact_points.phone_area_code%type;
        sv_phone_number         apps.hz_contact_points.phone_number%type;
        sv_phone_line_type      apps.hz_contact_points.phone_line_type%type;
        sv_prev_contact_id      apps.ar_contacts_v.contact_id%type;
        sv_address1             apps.ar_addresses_v.address1%type;
        sv_address2             apps.ar_addresses_v.address2%type;
        sv_city                 apps.ar_addresses_v.city%type;
        sv_state                apps.ar_addresses_v.state%type;
        sv_province             apps.ar_addresses_v.province%type;
        sv_country              apps.ar_addresses_v.country%type;
        sv_postal_code          apps.ar_addresses_v.postal_code%type;
        sv_area_code            apps.ra_phones.area_code%type;
        sv_primary_flag         apps.ar_contact_roles_v.primary_flag%type;
        sv_phone_type           apps.ra_phones.phone_type%type;


        lc_dbname              v$database.name%TYPE;


-------------------------------
        --account cursor (LC_ENTRYDETAIL)
        -------------------------------

    CURSOR lcu_account_cursor
        IS
       SELECT
       hca.account_number,
       hca.account_name,
       hca.status,
       hca.party_id,
       cl.delinquency_id,
       hca.orig_system_reference,
       hcas.cust_acct_site_id,
       hcas.cust_account_id,
       hcas.party_site_id,
       hcsu.site_use_code,
       cp.collector_name,
       cv.customer_name
   FROM hz_cust_accounts hca,
       hz_cust_acct_sites_all hcas,
       hz_cust_site_uses_all hcsu,
       iex_repossessions cl,
       ar_customer_profiles_v cp,
       ar_customers_v cv
 WHERE hca.cust_account_id = hcas.cust_account_id
   AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
 --  AND hca.status = 'A'   defect 3996: remove status check
   and hcsu.primary_flag = 'Y'
   AND hca.party_id = cl.party_id
   AND cp.collector_name = lc_collector_name
   AND cp.status = 'A'
   AND cp.customer_id = hca.cust_account_id
   AND cp.site_use_id = hcsu.site_use_id
   AND cv.customer_id = hca.cust_account_id
   AND cl.disposition_code = lc_disp_status
   AND hcsu.site_use_code = 'BILL_TO'
   order by hca.cust_account_id;

CURSOR lcu_contact_cursor
    IS
    SELECT
      cp.first_name,
      cp.last_name,
      ad.address1,
      ad.address2,
      ad.city,
      ad.state,
      ad.province,
      ad.country,
      ad.postal_code,
      cp.contact_id,
      cr.usage_meaning,
      cr.primary_flag,
      crp.email_address,
      crp.contact_point_purpose,
      crp.contact_point_type,
      crp.phone_area_code,
      crp.phone_number,
      crp.phone_line_type
    FROM ar_contacts_v CP,
         ar_addresses_v ad,
         ar_contact_roles_v cr,
         hz_contact_points crp
   WHERE cp.customer_id = lc_cust_account_id
     AND cp.status = 'A'
     AND ad.customer_id = cp.customer_id
     AND ad.address_id = lc_cust_acct_site_id
     AND ad.status = 'A'
     AND ad.identifying_address_flag = 'Y'
     AND cr.contact_id = cp.contact_iD
     AND cr.primary_flag = 'Y'
     AND cp.rel_party_id = crp.owner_table_id
     AND (crp.contact_point_purpose = 'DUNNING'
      OR  crp.contact_point_purpose = 'COLLECTIONS')
      order by cp.contact_id;
 /*    AND crp.primary_flag = 'Y'
       AND cr.usage_code = lc_usage_code;
        OR  cr.usage_code = 'CREDIT_CONTACT';
       AND cr.primary_flag = 'Y'; */

CURSOR  lcu_acct_notes_cursor
        IS
       SELECT
       created_by,
       creation_date,
       decoded_source_meaning,
       notes
  FROM jtf_notes_vl
    WHERE source_object_id = lc_cust_account_id
     AND ((source_object_code = 'IEX_ACCOUNT'
     AND source_object_meaning = 'Collections Account')
     OR  (source_object_code = 'IEX_REPOSSESSION'
     AND source_object_meaning = 'Collection Repossession'))
    AND note_status_meaning = 'Public'
    order by creation_date;


CURSOR  lcu_lit_notes_cursor
        IS
       SELECT
       an.created_by,
       an.creation_date,
       an.decoded_source_meaning,
       an.notes
  FROM jtf_notes_vl an,
       iex_litigations lg
  WHERE lg.party_id = lc_party_id
    AND lg.litigation_id = an.source_object_id
    AND ((an.source_object_code = 'IEX_ACCOUNT'
    AND   an.source_object_meaning = 'Collections Account')
     OR  (an.source_object_code = 'IEX_REPOSSESSION'
    AND   an.source_object_meaning = 'Collection Repossession'))
    AND an.source_object_meaning = 'Collections Account'
    AND  an.note_status_meaning = 'Public';

CURSOR  lcu_rep_notes_cursor
        IS
       SELECT
       rn.created_by,
       rn.creation_date,
       rn.decoded_source_meaning,
       rn.notes
  FROM jtf_notes_vl rn,
       iex_repossessions rep
  WHERE rep.delinquency_id = lc_delinquency_id
    AND rep.repossession_id = rn.source_object_id
    AND ((rn.source_object_code = 'IEX_ACCOUNT'
    AND   rn.source_object_meaning = 'Collections Account')
     OR  (rn.source_object_code = 'IEX_REPOSSESSION'
    AND   rn.source_object_meaning = 'Collection Repossession'))
    AND rn.source_object_meaning = 'Collections Account'
    AND rn.note_status_meaning = 'Public';

CURSOR lcu_collector_cursor
        IS
       SELECT
           collector_id,
           name,
           description
       FROM ar_collectors
      WHERE alias = 'Collection Agency'
        AND status = 'A'
        AND (trunc(inactive_date) > trunc(sysdate)
          OR inactive_date is null)
       Order by collector_id;


 TYPE collector_tbl_type IS TABLE OF lcu_collector_cursor%ROWTYPE
    INDEX BY PLS_INTEGER;

  lr_collector         collector_tbl_type;

  v_file_dir            VARCHAR2(50):= '/usr/tmp';
  v_filename            VARCHAR2(50);

 BEGIN

       -------------------------------
       -- Setting Production variable
       -------------------------------
       gc_current_step := ' Step: Setting Production variable ';

       lc_dbname := null;

       SELECT  name
         INTO  lc_dbname
         FROM  v$database;

       IF UPPER(lc_dbname) = 'GSIPRDGB' THEN
               gc_test_indicator := 'P';
       ELSE

               gc_test_indicator := 'T';
       END IF;

       --If the program is the scheduled job, get all collectors and write a
       --file for each
       If upper(p_collector_id) = 'ALL' THEN
            OPEN lcu_collector_cursor;
           FETCH lcu_collector_cursor
            BULK COLLECT
            INTO lr_collector;
           CLOSE lcu_collector_cursor;
       ELSE
       --if a user executed the program, create a file for just the entered
       --collector
          SELECT collector_id,
                 name,
                 description
            INTO lr_collector(gn_index).collector_id,
                 lr_collector(gn_index).name,
                 lr_collector(gn_index).description
            FROM apps.ar_collectors
           WHERE name = p_collector_id;
       END IF;

       lc_disp_status := 'APPROVED_PEND';

       IF (lr_collector.COUNT > 0) THEN
         FOR i_index IN lr_collector.FIRST..lr_collector.LAST LOOP
          lc_collector_id := lr_collector(i_index).collector_id;
          lc_collector_name := lr_collector(i_index).name;
          lc_description := lr_collector(i_index).description;
          lc_file_id := SUBSTR(lower(lc_description),1,3);
          -------------------
          -- Open output file
          -------------------
          gc_current_step := ' Step: Open output file ';
          gc_output_file := 'ar_repossession_' || (replace(lc_file_id, ' ','')) || '_' || (replace(lc_collector_id, ' ',''));

          g_FileHandle := UTL_FILE.FOPEN('XXFIN_OUTBOUND',gc_output_file,'w',gn_max_linesize);    -- Fourth Parameter added (Defect 5072)

         --FND_FILE.PUT_LINE(FND_FILE.LOG, 'collector_id' || lc_collector_id);
         --fnd_file.put_line(fnd_file.log, 'collector_name' || lc_collector_name);
         -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'output file' || gc_output_file);
         -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'disp status' || lc_disp_status);

          gn_total_record_cnt := 0;

          -------------------------------------------------------------
          -- Write the Header Record
          --------------------------------------------------------------
          lc_print_line := 'H ' || '|' ||
                            trim(lc_collector_id) ||'|' ||
                            trim(lc_description)|| '|' ||
                            SYSDATE ||'|' ||
                           'Office Depot Account Repossession Interface' ||
                           chr(13) ;


          UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
          FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

          gn_total_record_cnt := gn_total_record_cnt +1;
          gn_account_total_cnt := 0;

         -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'OPEN lcu_account_cursor');
          OPEN lcu_account_cursor;

      -- loop through accounts for collections
          LOOP
             FETCH lcu_account_cursor INTO
                   lc_account_number,
                   lc_account_name,
                   lc_status,
                   lc_party_id,
                   lc_delinquency_id,
                   lc_legacy_number,
                   lc_cust_acct_site_id,
                   lc_cust_account_id,
                   lc_party_site_id,
                   lc_site_use_code,
                   lc_COLLECTOR_NAME,
                   lc_customer_name;
             EXIT WHEN lcu_account_cursor%NOTFOUND;
         --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Account Number' || lc_account_number);

             --if the account has more than one row in the collections table
             --do not write the account details out to the file again
             IF lc_cust_account_id = sv_cust_account_id then
                 sv_cust_account_id := lc_cust_account_id;
             ELSE
                 sv_cust_account_id := lc_cust_account_id;

                 BEGIN
                   SELECT sum(amd.amount_due_remaining)
                   INTO ln_total_due
                   FROM   hz_cust_accounts_all cat,
                          ar_payment_schedules_all amd
                   WHERE  cat.account_number = lc_account_number
                     AND  cat.cust_account_id = amd.customer_id;

                   EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        ln_total_due := '';
                        WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while selecting ar_contact_roles: '
                                          || SQLERRM);
                         x_retcode := 2;
                 END;

                 --------------------------------------------------------------
                 -- Write the Account detail Record
                 --------------------------------------------------------------
           --      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Account Detail');

                 lc_print_line := 'DA' || '|' ||
                                   trim(lc_account_number) || '|' ||
                                   trim(lc_cust_account_id) || '|' ||
                                   trim(lc_customer_name) || '|' ||
                                   trim(lc_account_name) || '|' ||
                                   lc_status || '|' ||
                                    RTRIM(LTRIM(to_char(substr(NVL(ln_total_due,0)
                                    ,1,18),'999999999999999.99')))|| '|' ||
                                   trim(lc_party_id) || '|' ||
                                   trim(lc_cust_acct_site_id)|| '|' ||
                                   trim(lc_legacy_number) ||
                                   chr(13) ;

                 UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
                 FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
                 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

                 gn_account_total_cnt := gn_account_total_cnt +1;
                 gn_total_record_cnt  := gn_total_record_cnt +1;

                 --------------------------------------------------------------
                 -- Write the Account contact Record
                 --
                 ------------------------------------------------------------
        --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Account Contact Data');
             ln_count := 0;
             BEGIN
              -- LOOP
              --ln_count := ln_count +1;
                --IF ln_count = 1 then
                -- lc_usage_code := 'DUN';
               -- else
                -- lc_usage_code := 'CREDIT_CONTACT';
               -- end if;
                --EXIT WHEN ln_count > 2;
                OPEN lcu_contact_cursor;

                lc_prev_contact_id := 0;
                sv_contact_point_type := '  ';

                LOOP
                  lc_contact_id := '';

                  FETCH lcu_contact_cursor INTO
                        lc_first_name,
                        lc_last_name,
                        lc_address1,
                        lc_address2,
                        lc_city,
                        lc_state,
                        lc_province,
                        lc_country,
                        lc_postal_code,
                        lc_contact_id,
                        lc_usage_meaning,
                        lc_primary_flag,
                        ln_email_address,
                        ln_contact_point_purpose,
                        ln_contact_point_type,
                        ln_phone_area_code,
                        ln_phone_number,
                        ln_phone_line_type;

                EXIT WHEN lcu_contact_cursor%NOTFOUND;
              --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Contact ID' || lc_contact_id);
              --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Prev Contact ID' || lc_prev_contact_id);
              --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Line Count' || ln_count);
              --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Line Type' || ln_phone_line_type);

                 IF (lc_contact_id != lc_prev_contact_id)
                      and ln_count > 0 THEN
                  --     FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Contact Data');
                      --write the contact details to the output file
                             lc_print_line := 'DC' || '|' ||
                                   trim(lc_area_code)|| '|' ||
                                   trim(lc_phone_number)|| '|' ||
                                   trim(lc_phone_type)|| '|' ||
                                   trim(sv_first_name)|| '|' ||
                                   trim(sv_last_name)|| '|' ||
                                   trim(sv_address1) || '|' ||
                                   trim(sv_address2) || '|' ||
                                   trim(sv_city) || '|' ||
                                   trim(sv_state) || '|' ||
                                   trim(sv_province) || '|' ||
                                   trim(sv_postal_code)|| '|' ||
                                   trim(sv_country)|| '|' ||
                                   trim(sv_usage_meaning)|| '|' ||
                                   trim(sv_primary_flag)  ||'|' ||
                                   trim(sv_contact_point_type) || '|' ||
                                   trim(ln_contact_info) ||
                                   chr(13);

                      UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
                      FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
                      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);


                      gn_total_record_cnt  := gn_total_record_cnt +1;
                      lc_prev_contact_id := lc_contact_id;
                      sv_first_name :=  lc_first_name;
                      sv_last_name := lc_last_name;
                      sv_address1 := lc_address1;
                      sv_address2 := lc_address2;
                      sv_city := lc_city;
                      sv_state := lc_state;
                      sv_province :=  lc_province;
                      sv_country := lc_country;
                      sv_postal_code := lc_postal_code;
                      sv_contact_id :=  lc_contact_id;
                      sv_usage_meaning :=  lc_usage_meaning;
                      sv_primary_flag :=  lc_primary_flag;
                      ln_count := ln_count +1;
                      sv_contact_point_type := '  ';
                   END IF;

                   IF ln_count = 0 THEN
                      sv_first_name :=  lc_first_name;
                      sv_last_name := lc_last_name;
                      sv_address1 := lc_address1;
                      sv_address2 := lc_address2;
                      sv_city := lc_city;
                      sv_state := lc_state;
                      sv_province :=  lc_province;
                      sv_country := lc_country;
                      sv_postal_code := lc_postal_code;
                      sv_contact_id :=  lc_contact_id;
                      sv_usage_meaning :=  lc_usage_meaning;
                      sv_primary_flag :=  lc_primary_flag;

                   END IF;

                      IF ln_contact_point_type = 'PHONE'
                      and ln_phone_line_type = 'GEN' THEN
                          lc_area_code := ln_phone_area_code;
                          lc_phone_number := ln_phone_number;
                          lc_phone_type := ln_phone_line_type;
                       END IF;
                  --    FND_FILE.PUT_LINE(FND_FILE.LOG, 'SV Point Type' || sv_contact_point_type);

                       IF sv_contact_point_type = 'EMAIL' or
                          sv_contact_point_type = 'FAX' THEN
                             hd_contact_point_type := '  ';
                       ELSE
                          IF ln_contact_point_type = 'PHONE' THEN
                             ln_contact_info := ln_phone_area_code || '-' || ln_phone_number;
                             IF ln_phone_line_type = 'FAX' THEN
                                sv_contact_point_type := 'FAX';
                             ELSE
                                sv_contact_point_type := ln_phone_line_type;
                             END IF;
                          ELSE
                             ln_contact_info := ln_email_address;
                             sv_contact_point_type := 'EMAIL';
                          END IF;
                      END IF;
                      ln_count := ln_count +1;
                      lc_prev_contact_id := lc_contact_id;

               -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Contact Usage');
               /*  BEGIN
                    SELECT cr.usage_meaning,
                           cr.primary_flag
                      INTO lc_usage_meaning,
                           lc_primary_flag
                      FROM apps.ar_contact_roles_v cr
                     WHERE cr.contact_id = lc_contact_id;
                  EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        lc_usage_meaning := '';
                        lc_primary_flag := '';
                        WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while selecting ar_contact_roles: '
                                          || SQLERRM);
                   END;

                --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Contact Phones');
                  BEGIN
                    SELECT c.area_code,
                           c.phone_number,
                           c.phone_type
                     INTO lc_area_code,
                          lc_phone_number,
                          lc_phone_type
                     FROM  apps.ra_phones c
                    WHERE c.customer_id = lc_cust_account_id
                      AND c.primary_flag = 'Y'
                      AND c.contact_id = lc_contact_id;

                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                        lc_area_code := '';
                        lc_phone_number := '';
                        lc_phone_type := '';
                        WHEN OTHERS THEN
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception raised while selecting ra_phones: '
                                          || SQLERRM);
                         x_retcode := 2;
                   END;
               */

              END LOOP;
              IF ln_count > 0 THEN
            --  IF lc_area_code != '' THEN
               lc_print_line := 'DC' || '|' ||
                                   trim(lc_area_code)|| '|' ||
                                   trim(lc_phone_number)|| '|' ||
                                   trim(lc_phone_type)|| '|' ||
                                   trim(sv_first_name)|| '|' ||
                                   trim(sv_last_name)|| '|' ||
                                   trim(sv_address1) || '|' ||
                                   trim(sv_address2) || '|' ||
                                   trim(sv_city) || '|' ||
                                   trim(sv_state) || '|' ||
                                   trim(sv_province) || '|' ||
                                   trim(sv_postal_code)|| '|' ||
                                   trim(sv_country)|| '|' ||
                                   trim(sv_usage_meaning)|| '|' ||
                                   trim(sv_primary_flag)  ||'|' ||
                                   trim(sv_contact_point_type) || '|' ||
                                   trim(ln_contact_info) ||
                                   chr(13);

                      UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
                      FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
                      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

                      gn_total_record_cnt  := gn_total_record_cnt +1;
                      lc_prev_contact_id := 0;
                      ln_count := ln_count +1;
                      lc_area_code := '';
                      sv_contact_point_type := '  ';
                  END IF;
              CLOSE lcu_contact_cursor;
         --   END LOOP;
           END;

           OPEN lcu_acct_notes_cursor;
       -- loop through notes for the transaction
      -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Notes');

          LOOP
          FETCH lcu_acct_notes_cursor INTO
                lc_created_by,
                lc_creation_date,
                lc_note_type,
                lc_text;

          EXIT WHEN lcu_acct_notes_cursor%NOTFOUND;
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Notes');
          ------------------------------------------------------
          -- write the notes detail to the output file
          ------------------------------------------------------
          lc_print_line := 'DN' || '|' ||
                            trim(lc_created_by) || '|' ||
                            trim(lc_creation_date) || '|' ||
                            trim(lc_note_type) || '|' ||
                            trim(lc_text)  ||
                            chr(13) ;

          UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
          FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

          gn_total_record_cnt  := gn_total_record_cnt +1;

       END LOOP;
       CLOSE lcu_acct_notes_cursor;
     /*
          OPEN lcu_rep_notes_cursor;
       -- loop through notes for the transaction
       -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Notes');

          LOOP
          FETCH lcu_rep_notes_cursor INTO
                lc_created_by,
                lc_creation_date,
                lc_note_type,
                lc_text;

          EXIT WHEN lcu_rep_notes_cursor%NOTFOUND;
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Notes');
          ------------------------------------------------------
          -- write the notes detail to the output file
          ------------------------------------------------------
          lc_print_line := 'DN' || '|' ||
                            trim(lc_created_by) || '|' ||
                            trim(lc_creation_date) || '|' ||
                            trim(lc_note_type) || '|' ||
                            trim(lc_text)  ||
                            chr(13) ;

          UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
          FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

          gn_total_record_cnt  := gn_total_record_cnt +1;

       END LOOP;
       CLOSE lcu_rep_notes_cursor;

       OPEN lcu_lit_notes_cursor;
       -- loop through notes for the transaction
       -- FND_FILE.PUT_LINE(FND_FILE.LOG, 'Select Notes');

       LOOP
          FETCH lcu_lit_notes_cursor INTO
                lc_created_by,
                lc_creation_date,
                lc_note_type,
                lc_text;

          EXIT WHEN lcu_lit_notes_cursor%NOTFOUND;
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Notes');
          ------------------------------------------------------
          -- write the notes detail to the output file
          ------------------------------------------------------
          lc_print_line := 'DN' || '|' ||
                            trim(lc_created_by) || '|' ||
                            trim(lc_creation_date) || '|' ||
                            trim(lc_note_type) || '|' ||
                            trim(lc_text)      ||
                            chr(13) ;

          UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
          FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
          FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

          gn_total_record_cnt  := gn_total_record_cnt +1;

       END LOOP;
       CLOSE lcu_lit_notes_cursor;
      */
                 --go find the transaction details for this account
                 TRANSACTION_DETAILS(lc_cust_account_id);

              --update the collections table only if the disposition status has
              --been set to the final stage
              --  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Updating the disposition');
                 UPDATE apps.IEX_REPOSSESSIONS
                    SET disposition_code = 'OPEN',
                        repossession_date = SYSDATE,
			last_updated_by = FND_PROFILE.VALUE('USER_ID'), --Fixed for defect 7023
			LAST_UPDATE_DATE  = SYSDATE                     --Fixed for defect 7023
                  WHERE party_id = lc_party_id
                    AND disposition_code = 'APPROVED_PEND';

               -- COMMIT;  -- Commenting for Defect # 5103
               --   AND (repossession_date is null
               --    or  repossession_date = '');
           END IF;
          END LOOP;
          CLOSE lcu_account_cursor;
       --------------------------------------------------------------
       -- Write the Trailer Record
       --------------------------------------------------------------
       --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Writing Trailer');

       gn_total_record_cnt  := gn_total_record_cnt +1;
       lc_print_line := 'T ' ||'|' ||
                         SYSDATE || '|' ||
                         gn_account_total_cnt || '|' ||
                         gn_total_record_cnt  ||
                         chr(13) ;

       UTL_FILE.PUT_LINE(g_FileHandle, lc_print_line);
       FND_FILE.NEW_LINE(FND_FILE.OUTPUT,1);
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, lc_print_line);

       UTL_FILE.FFLUSH(g_FileHandle);

       UTL_FILE.FCLOSE(g_FileHandle);

       ----------------------------------------
       --Rename and copy file to file directory
       ----------------------------------------
       -- THE XXCOMFILECOPY concurrent program will move file from XXFIN_OUTBOUND
       -- directory to the XXFIN/ftp/out/nacha directory where BPEL is monitoring
       -- for the file to arrive.

       gc_current_step   := ' Step: Rename and copy file to file dir ';
       dbms_lock.sleep(5);
       ln_req_id := fnd_request.submit_request(  'XXFIN'
                                                ,'XXCOMFILCOPY'
                                                ,''
                                                ,'01-OCT-04 00:00:00'
                                                ,FALSE
                                                ,'$XXFIN_DATA/outbound/'||gc_output_file
                                                ,'$XXFIN_DATA/ftp/out/repossession/' || gc_output_file ||'_'||TO_CHAR(SYSDATE,'MMDDYYYYHH24MISS')||'.txt'
                                                ,''
                                                ,''
                                                ,'Y'
                                                ,'$XXFIN_DATA/archive/outbound');
       
       EXIT WHEN (lc_collector_id = '');
    END LOOP;
    COMMIT;  -- Added for Defect # 5103
  END IF;
    EXCEPTION

         WHEN UTL_FILE.invalid_mode THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid Mode Parameter');
            x_retcode := 2;

         WHEN UTL_FILE.invalid_path THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid File Location');
            x_retcode := 2;

         WHEN UTL_FILE.invalid_filehandle THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid Filehandle');
            x_retcode := 2;

         WHEN UTL_FILE.invalid_operation THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid Operation');
            x_retcode := 2;

         WHEN UTL_FILE.read_error THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Read Error');
            x_retcode := 2;

         WHEN UTL_FILE.internal_error THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Internal Error');
            x_retcode := 2;

         WHEN UTL_FILE.charsetmismatch THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Opened With FOPEN_NCHAR ');
            x_retcode := 2;

         WHEN UTL_FILE.file_open THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.File Already Opened');
            x_retcode := 2;

         WHEN UTL_FILE.invalid_maxlinesize THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Line Size Exceeds 32K');
            x_retcode := 2;

         WHEN UTL_FILE.invalid_filename THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.Invalid File Name');
            x_retcode := 2;

         WHEN UTL_FILE.access_denied THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.File Access Denied By');
            x_retcode := 2;

         WHEN UTL_FILE.invalid_offset THEN

            FND_FILE.PUT_LINE(FND_FILE.LOG, 'utl_file.FSEEK Param Less Than 0');
            x_retcode := 2;

  WHEN OTHERS THEN

    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Other Exception ' || SQLERRM ());

    x_retcode := 2;

    x_errbuff := gc_current_step;

END;

END XX_AR_REPOSSESSION_PKG;

/

