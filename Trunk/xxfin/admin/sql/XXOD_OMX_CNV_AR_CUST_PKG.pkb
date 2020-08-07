CREATE OR REPLACE
PACKAGE BODY XXOD_OMX_CNV_AR_CUST_PKG
AS
  -- +============================================================================================+
  -- |  Office Depot                                                                              |
  -- +============================================================================================+
  -- |  Name:  XXOD_OMX_CNV_AR_CUST_PKG                                                           |
  -- |                                                                                            |
  -- |  Description:  This package is used to create Office Depot North Customers.                |
  -- |                                                                                            |
  -- |  Change Record:                                                                            |
  -- +============================================================================================+
  -- | Version     Date         Author           Remarks                                          |
  -- | =========   ===========  =============    ===============================================  |
  -- | 1.0         12-DEC-2017  Punit Gupta      Initial version                                  |
  -- | 1.1         16-MAR-2018  Punit Gupta      Defect#21481 Unable to see contacts of converted |
  -- |                                                        customers in Web Collect extract    |
  -- +============================================================================================+
  g_conc_request_id NUMBER:= fnd_global.conc_request_id;
  g_total_records   NUMBER;
PROCEDURE Print_Customer_Details
IS
  ln_row_cnt         NUMBER := 0;
  ln_total_row_cnt   NUMBER := 0;
  ln_success_row_cnt NUMBER := 0;
  ln_error_row_cnt   NUMBER := 0;
  CURSOR lcu_prnt_cust_details
  IS
    SELECT odn_cust_name,
      odn_cust_num,
      record_status,
      conv_error_msg
    FROM xxod_omx_cnv_ar_cust_stg
    WHERE record_status IN ('S','E')
    GROUP BY odn_cust_name,
      odn_cust_num,
      record_status,
      conv_error_msg
    ORDER BY odn_cust_num;
  CURSOR lcu_record_details
  IS
    SELECT * FROM xxod_omx_cnv_ar_cust_stg WHERE record_status IN ('S','E');
  --
BEGIN
  BEGIN
    FOR rec_record_details IN lcu_record_details
    LOOP
      ln_total_row_cnt                   := ln_total_row_cnt + 1;
      IF rec_record_details.record_status = 'S' THEN
        ln_success_row_cnt               := ln_success_row_cnt + 1;
      END IF;
      IF rec_record_details.record_status = 'E' THEN
        ln_error_row_cnt                 := ln_error_row_cnt + 1;
      END IF;
    END LOOP;
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD ('-',304 , '-'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Record Details from the Data File ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD ('-',304 , '-'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no of records in the Data File: ' || ln_total_row_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no of records successfully loaded: ' || ln_success_row_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Total no of records failed to load: ' || ln_error_row_cnt);
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 304, '-'));
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in Printing Record Details: '||SQLERRM);
  END;
  BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Print_Customer_Details');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, RPAD ('-',304 , '-'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'OMX Customer Details Report');
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 304, '-'));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('ODN Customer Name', 30, ' ') || ' ' || RPAD ('AOPSAcc#', 12, ' ') || ' ' || RPAD ('Status', 6, ' ') || ' ' || RPAD ('Error Message', 250, ' '));
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD ('-', 30, '-') || ' ' || RPAD ('-', 12, '-') || ' ' || RPAD ('-', 6, '-') || ' ' || RPAD ('-', 250, '-'));
    FOR rec_prnt_cust_details IN lcu_prnt_cust_details
    LOOP
      --
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,RPAD (NVL (rec_prnt_cust_details.odn_cust_name, ' '), 30, ' ') || ' ' || RPAD (NVL (rec_prnt_cust_details.odn_cust_num, ' '), 12, ' ') || ' ' || RPAD (NVL (rec_prnt_cust_details.record_status, ' '), 6, ' ') || ' ' || RPAD (NVL (rec_prnt_cust_details.conv_error_msg, ' '), 250, ' ') );
      ln_row_cnt := ln_row_cnt + 1;
    END LOOP;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in Print_Customer_Details: '||SQLERRM);
  END;
END Print_Customer_Details;
/*********************************************************************
* Procedure used to log based on gb_debug value or if p_force is TRUE.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program log file.  Will prepend
* timestamp to each message logged.  This is useful for determining
* elapse times.
*********************************************************************/
PROCEDURE Print_Debug_Msg(
    p_message IN VARCHAR2)
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  --FND_FILE.PUT_LINE(Fnd_File.log,p_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    DBMS_OUTPUT.put_line(p_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END Print_Debug_Msg;
/*********************************************************************
* Procedure used to out the text to the concurrent program.
* Will log to dbms_output if request id is not set,
* else will log to concurrent program output file.
*********************************************************************/
PROCEDURE Print_Out_Msg(
    P_Message IN VARCHAR2)
IS
  lc_message VARCHAR2(4000) := NULL;
BEGIN
  --FND_FILE.PUT_LINE(Fnd_File.output,p_message);
  IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1) THEN
    DBMS_OUTPUT.put_line(p_message);
  END IF;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END Print_Out_Msg;
PROCEDURE Load_Customers(
    x_error_buff OUT VARCHAR2 ,
    x_ret_code OUT NUMBER ,
    p_validate_only_flag IN VARCHAR2 ,
    p_process_flag       IN VARCHAR2 ,
    p_reprocess_flag     IN VARCHAR2)
AS
  CURSOR lcu_stg_tbl_validate
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_cust_stg
    WHERE record_status = 'N'
    AND odn_cust_num   IS NOT NULL;
  CURSOR lcu_unique_odn_cust
  IS
    SELECT DISTINCT odn_cust_num
    FROM xxod_omx_cnv_ar_cust_stg
    WHERE odn_cust_num IS NOT NULL;
  CURSOR lcu_dup_billto(p_odn_cust_num IN VARCHAR2)
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_cust_stg STG1
    WHERE STG1.odn_cust_num  = p_odn_cust_num
    AND STG1.bill_to_cnsgno IN
      (SELECT STG2.bill_to_cnsgno
      FROM xxod_omx_cnv_ar_cust_stg STG2
      WHERE STG2.odn_cust_num = STG1.odn_cust_num
      GROUP BY STG2.bill_to_cnsgno
      HAVING COUNT(STG2.bill_to_cnsgno)>= 2
      )
  ORDER BY RECORD_ID;
  CURSOR lcu_dup_shipto(p_odn_cust_num IN VARCHAR2)
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_cust_stg STG1
    WHERE STG1.odn_cust_num  = p_odn_cust_num
    AND STG1.ship_to_cnsgno IN
      (SELECT STG2.ship_to_cnsgno
      FROM xxod_omx_cnv_ar_cust_stg STG2
      WHERE STG2.odn_cust_num = STG1.odn_cust_num
      GROUP BY STG2.ship_to_cnsgno
      HAVING COUNT(STG2.ship_to_cnsgno)>= 2
      )
  ORDER BY RECORD_ID;
  CURSOR lcu_stg_tbl_reprocess
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_cust_stg
    WHERE record_status  = 'E'
    AND odn_cust_num    IS NOT NULL
    AND odn_cust_name   IS NOT NULL
    AND org_address1    IS NOT NULL
    AND (bill_to_cnsgno IS NOT NULL
    OR ship_to_cnsgno   IS NOT NULL)
    AND conv_error_msg NOT LIKE '%Value for orig_system_reference must be unique%';
  CURSOR lcu_stg_tbl
  IS
    SELECT odn_cust_num
    FROM xxod_omx_cnv_ar_cust_stg
    WHERE record_status = 'V'
    AND odn_cust_num   IS NOT NULL
    GROUP BY odn_cust_num;
TYPE customer_bulk_tbl_type
IS
  TABLE OF xxod_omx_cnv_ar_cust_stg%ROWTYPE;
TYPE odn_bch_customer_bulk_tbl_type
IS
  TABLE OF xxod_omx_cnv_ar_cust_stg.odn_cust_num%TYPE INDEX BY PLS_INTEGER;
TYPE odn_customer_bulk_tbl_type
IS
  TABLE OF xxod_omx_cnv_ar_cust_stg%ROWTYPE;
  lc_customer_bulk customer_bulk_tbl_type;
  lc_odn_batch_customer_bulk odn_bch_customer_bulk_tbl_type;
  lc_odn_customer_bulk odn_customer_bulk_tbl_type;
  CURSOR lcu_stg_tbl_odn(p_odn_cust_num IN VARCHAR2)
  IS
    SELECT *
    FROM xxod_omx_cnv_ar_cust_stg
    WHERE 1           =1
    AND record_status = 'V'
    AND odn_cust_num  = p_odn_cust_num
    ORDER BY record_id; -- Added on 11-JAN-2018
  lc_stg_rec xxod_omx_cnv_ar_cust_stg%ROWTYPE;
  lc_profile_class_id hz_cust_profile_classes.profile_class_id%TYPE;
  lc_prf_status hz_cust_profile_classes.status%TYPE;
  lc_credit_check hz_cust_profile_classes.credit_checking%TYPE;
  lc_standard_terms hz_cust_profile_classes.standard_terms%TYPE;
  lc_override_terms hz_cust_profile_classes.override_terms%TYPE;
  ln_org_id         NUMBER;
  ln_ctr            NUMBER;
  lc_error_flag     VARCHAR2 (1);
  lc_reject_msg_out VARCHAR2 (1000);
  --Standard API variables
  lc_init_msg_list     VARCHAR2 (1) := 'T';
  ln_msg_count         NUMBER;
  ln_msg_index_out     NUMBER;
  ln_new_party_id      NUMBER;
  ln_profile_id        NUMBER;
  ln_cust_account_id   NUMBER;
  ln_cust_party_id     NUMBER;
  ln_cust_profile_id   NUMBER;
  ln_responsibility_id NUMBER;
  --BILL TO
  ln_bill_to_location_id       NUMBER;
  ln_bill_to_party_site_id     NUMBER;
  lc_bill_to_party_site_number VARCHAR2 (50);
  ln_bill_cust_acct_site_id    NUMBER;
  ln_bill_party_site_use_id    NUMBER;
  ln_bill_site_use_id          NUMBER;
  ln_duns_party_id             NUMBER;
  ln_party_rel_id              NUMBER;
  ln_cust_account_role_id      NUMBER;
  ln_contact_point_id          NUMBER;
  lc_return_status             VARCHAR2 (1);
  lc_party_site_number         VARCHAR2 (50);
  lc_party_number              VARCHAR2 (50);
  lc_cust_party_number         VARCHAR2 (100);
  lc_cust_account_number       VARCHAR2 (100);
  bill_person_record_rec_type hz_party_v2pub.person_rec_type;
  ln_bill_party_id     NUMBER;
  lc_bill_party_number VARCHAR2(50);
  ln_bill_profile_id   NUMBER;
  bill_contact_rec_type hz_party_contact_v2pub.org_contact_rec_type;
  ln_bill_contact_id   NUMBER;
  ln_bill_party_rel_id NUMBER;
  ln_borg_party_id     NUMBER;
  lc_borg_party_number VARCHAR2(50);
  lv_bill_contact_point_rec_type hz_contact_point_v2pub.contact_point_rec_type;
  lv_bill_email_rec_type hz_contact_point_v2pub.email_rec_type;
  lv_bill_phone_rec_type hz_contact_point_v2pub.phone_rec_type;
  ln_bill_contact_point_id NUMBER;
  lv_bill_acct_role_rec_type HZ_CUST_ACCOUNT_ROLE_V2PUB.CUST_ACCOUNT_ROLE_REC_TYPE;
  ln_bill_acct_role_id NUMBER;
  lv_bill_role_resp_rec_type HZ_CUST_ACCOUNT_ROLE_V2PUB.role_responsibility_rec_TYPE;
  ln_bill_responsibility_id NUMBER;
  --SHIP TO
  ln_ship_to_location_id       NUMBER;
  ln_ship_to_party_site_id     NUMBER;
  lc_ship_to_party_site_number VARCHAR2 (50);
  ln_ship_party_site_use_id    NUMBER;
  ln_ship_site_use_id          NUMBER;
  ln_ship_cust_acct_site_id    NUMBER;
  lc_msg_data                  VARCHAR2 (2000);
  lc_output                    VARCHAR2 (2000);
  lc_msg_dummy                 VARCHAR2 (2000);
  lc_err_msg                   VARCHAR2 (2000);
  lv_bill_party_site_rec_type hz_party_site_v2pub.party_site_rec_type;
  lv_ship_party_site_rec_type hz_party_site_v2pub.party_site_rec_type;
  lv_organization_rec_type hz_party_v2pub.organization_rec_type;
  lv_organization_rec_type_null hz_party_v2pub.organization_rec_type;
  lv_cust_account_rec_type hz_cust_account_v2pub.cust_account_rec_type;
  lv_customer_profile_rec_type hz_customer_profile_v2pub.customer_profile_rec_type;
  lv_profile_class_amt_tbl_type hz_cust_prof_class_amts%ROWTYPE;
  lv_profile_amt_rec_type hz_customer_profile_v2pub.cust_profile_amt_rec_type;
  lv_bill_location_rec_type hz_location_v2pub.location_rec_type;
  lv_ship_location_rec_type hz_location_v2pub.location_rec_type;
  lv_web_rec_type hz_contact_point_v2pub.web_rec_type;
  lv_cr_cust_acc_role_rec_type hz_cust_account_role_v2pub.cust_account_role_rec_type;
  lv_bill_cust_site_use_rec_type hz_cust_account_site_v2pub.cust_site_use_rec_type;
  lv_ship_cust_site_use_rec_type hz_cust_account_site_v2pub.cust_site_use_rec_type;
  lv_ship_contact_rec_type hz_party_contact_v2pub.org_contact_rec_type;
  lv_ship_person_rec_type hz_party_v2pub.person_rec_type;
  lv_ship_contact_point_rec_type hz_contact_point_v2pub.contact_point_rec_type;
  lv_ship_email_rec_type hz_contact_point_v2pub.email_rec_type;
  lv_ship_phone_rec_type hz_contact_point_v2pub.phone_rec_type;
  lv_ship_acct_role_rec_type hz_cust_account_role_v2pub.cust_account_role_rec_type;
  ln_ship_contact_point_id NUMBER;
  ln_ship_acct_role_id     NUMBER;
  ln_ship_party_id         NUMBER;
  lv_person_rec_type hz_party_v2pub.person_rec_type;
  lc_ship_party_number VARCHAR2(50);
  lc_sorg_party_number VARCHAR2(50);
  ln_ship_contact_id   NUMBER;
  ln_sorg_party_id     NUMBER;
  ln_ship_profile_id   NUMBER;
  ln_ship_party_rel_id NUMBER;
  --ORG Contact
  lv_org_person_rec_type hz_party_v2pub.person_rec_type;
  lv_org_contact_rec_type hz_party_contact_v2pub.org_contact_rec_type;
  lv_org_location_rec_type hz_location_v2pub.location_rec_type;
  lv_org_party_site_rec_type hz_party_site_v2pub.party_site_rec_type;
  lv_org_contact_point_rec_type hz_contact_point_v2pub.contact_point_rec_type;
  lv_org_email_rec_type hz_contact_point_v2pub.email_rec_type;
  lv_org_phone_rec_type hz_contact_point_v2pub.phone_rec_type;
  lv_org_acct_role_rec_type hz_cust_account_role_v2pub.cust_account_role_rec_type;
  ln_org_acct_role_id          NUMBER;
  ln_org_party_id              NUMBER;
  lc_org_party_number          VARCHAR2(50);
  ln_org_profile_id            NUMBER;
  ln_org_contact_id            NUMBER;
  ln_org_party_rel_id          NUMBER;
  ln_corg_party_id             NUMBER;
  lc_corg_party_number         VARCHAR2(50);
  ln_collect_location_id       NUMBER;
  ln_collect_party_site_id     NUMBER;
  lc_collect_party_site_number VARCHAR2(50);
  ln_org_contact_point_id      NUMBER;
  lv_bill_partysiteuse_rec_type hz_party_site_v2pub.party_site_use_rec_type;
  lv_ship_partysiteuse_rec_type hz_party_site_v2pub.party_site_use_rec_type;
  lv_bill_custacctsite_rec_type hz_cust_account_site_v2pub.cust_acct_site_rec_type;
  lv_ship_custacctsite_rec_type hz_cust_account_site_v2pub.cust_acct_site_rec_type;
  lv_cust_profile_amt_rec_type hz_customer_profile_v2pub.cust_profile_amt_rec_type;
  ln_prfl_amt_id           NUMBER;
  ln_object_version_number NUMBER;
  lc_curr_code             VARCHAR2 (100);
  ln_collector_id          NUMBER;
  ln_version_number        NUMBER;
  ln_cust_count            NUMBER;
  ln_custacct_count        NUMBER;
  ln_billto_count          NUMBER;
  ln_shipto_count          NUMBER;
  lc_bill_to_consg_no      VARCHAR2(100);
  lc_ship_to_consg_no      VARCHAR2(100);
  ln_party_id              NUMBER;
  ln_custacct_id           NUMBER;
  lc_cust_account_num      VARCHAR2 (100);
  ln_parent_party_id       NUMBER;
  lv_relationship_rec_type hz_relationship_v2pub.relationship_rec_type;
  ln_relationship_id      NUMBER;
  ln_rel_party_id         NUMBER;
  lc_rel_party_number     VARCHAR2 (50);
  lc_relationship_flag    VARCHAR2 (1);
  lc_default_billto       VARCHAR2 (1);
  lc_default_shipto       VARCHAR2 (1);
  lc_party_name           VARCHAR2(150);
  ln_new_cust_acct_flg    VARCHAR2 (1);
  ln_new_party_created    VARCHAR2 (1);
  lc_bill_to_consg_no_dup VARCHAR2(100);
  lc_ship_to_consg_no_dup VARCHAR2(100);
BEGIN
  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Start:'||g_conc_request_id,'');
  --Start apps intialization
  IF (p_validate_only_flag = 'Y') THEN
    OPEN lcu_stg_tbl_validate;
    LOOP
      FETCH lcu_stg_tbl_validate BULK COLLECT INTO lc_customer_bulk LIMIT 5000;
      EXIT
    WHEN lc_customer_bulk.COUNT = 0;
      FOR indx IN 1 .. lc_customer_bulk.COUNT
      LOOP
        IF (lc_customer_bulk(indx).ORG_ADDRESS1 IS NULL OR lc_customer_bulk(indx).ODN_CUST_NUM IS NULL OR lc_customer_bulk(indx).ODN_CUST_NAME IS NULL) THEN
          UPDATE xxod_omx_cnv_ar_cust_stg CUST
          SET CUST.record_status = 'E',
            CUST.conv_error_msg  = 'Invalid Record - Value of Mandatory Column is Blank'
          WHERE 1                =1
            --AND (CUST.BILL_TO_CNSGNO IS NULL AND CUST.SHIP_TO_CNSGNO IS NULL)
          AND CUST.record_id = lc_customer_bulk(indx).record_id;
          x_ret_code        := 1;
        END IF;
        IF (lc_customer_bulk(indx).BILL_TO_CNSGNO IS NOT NULL AND lc_customer_bulk(indx).BILL_TO_ADDRESS1 IS NULL ) THEN
          UPDATE xxod_omx_cnv_ar_cust_stg CUST
          SET CUST.record_status = 'E',
            CUST.conv_error_msg  = 'Invalid Record - Value of Mandatory Column BILL_TO_ADDRESS1 IS Blank'
          WHERE 1                =1
          AND CUST.record_id     = lc_customer_bulk(indx).record_id;
          x_ret_code            := 1;
        END IF;
        IF (lc_customer_bulk(indx).SHIP_TO_CNSGNO IS NOT NULL AND lc_customer_bulk(indx).SHIP_TO_ADDRESS1 IS NULL ) THEN
          UPDATE xxod_omx_cnv_ar_cust_stg CUST
          SET CUST.record_status = 'E',
            CUST.conv_error_msg  = 'Invalid Record - Value of Mandatory Column BILL_TO_ADDRESS1 IS Blank'
          WHERE 1                =1
          AND CUST.record_id     = lc_customer_bulk(indx).record_id;
          x_ret_code            := 1;
        END IF;
        /*IF (lc_customer_bulk(indx).BILL_TO_CNSGNO IS NULL AND lc_customer_bulk(indx).SHIP_TO_CNSGNO IS NULL) THEN
        UPDATE xxod_omx_cnv_ar_cust_stg CUST
        SET CUST.record_status = 'E',
        CUST.conv_error_msg  = 'Invalid Record- Both BILL_TO and SHIP_TO Values are Blank'
        WHERE 1                =1
        --AND (CUST.BILL_TO_CNSGNO IS NULL AND CUST.SHIP_TO_CNSGNO IS NULL)
        AND CUST.record_id = lc_customer_bulk(indx).record_id;
        x_ret_code        := 1;
        END IF;*/
        UPDATE xxod_omx_cnv_ar_cust_stg CUST
        SET CUST.record_status  = 'V'
        WHERE 1                 =1
        AND (CUST.odn_cust_num IS NOT NULL
        AND CUST.odn_cust_name IS NOT NULL
        AND CUST.org_address1  IS NOT NULL )
        AND CUST.record_status  = 'N'
        AND CUST.record_id      = lc_customer_bulk(indx).record_id;
        --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Record Status Updated for ODN_CUST_NUM : '|| lc_customer_bulk(indx).ODN_CUST_NUM||' for RECORD_ID: '||lc_customer_bulk(indx).record_id);
      END LOOP;
    END LOOP;
    FOR rec_unique_odn_cust IN lcu_unique_odn_cust
    LOOP
      FOR rec_dup_billto IN lcu_dup_billto(rec_unique_odn_cust.odn_cust_num)
      LOOP
        UPDATE xxod_omx_cnv_ar_cust_stg STG
        SET bill_to_rpt_flg = 'Y'
        WHERE record_id     = rec_dup_billto.record_id
        AND ROWID NOT      IN
          (SELECT MIN(ROWID)
          FROM xxod_omx_cnv_ar_cust_stg STG2
          WHERE STG2.bill_to_cnsgno = rec_dup_billto.bill_to_cnsgno
		  AND STG2.odn_cust_num = rec_dup_billto.odn_cust_num
          );
      END LOOP;
      FOR rec_dup_shipto IN lcu_dup_shipto(rec_unique_odn_cust.odn_cust_num)
      LOOP
        UPDATE xxod_omx_cnv_ar_cust_stg STG
        SET ship_to_rpt_flg = 'Y'
        WHERE record_id     = rec_dup_shipto.record_id
        AND ROWID NOT IN
          (SELECT MIN(ROWID)
          FROM xxod_omx_cnv_ar_cust_stg STG2
          WHERE STG2.ship_to_cnsgno = rec_dup_shipto.ship_to_cnsgno
		  AND STG2.odn_cust_num = rec_dup_shipto.odn_cust_num
          );
      END LOOP;
    END LOOP;
  END IF;
  IF p_reprocess_flag = 'Y' THEN
    BEGIN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Start of Reprocessing of Error Records' );
      FOR rec_stg_tbl_reprocess IN lcu_stg_tbl_reprocess
      LOOP
        UPDATE xxod_omx_cnv_ar_cust_stg CUST
        SET CUST.record_status   = 'V'
        WHERE CUST.record_status = 'E'
        AND CUST.record_id       = rec_stg_tbl_reprocess.record_id;
      END LOOP;
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while updating the status of error records'||SQLCODE||SQLERRM);
      x_ret_code := 1;
    END;
  END IF;
  IF (p_validate_only_flag = 'N' AND p_process_flag = 'Y' OR p_reprocess_flag = 'Y') THEN
    BEGIN
      SELECT profile_class_id ,
        status ,
        credit_checking ,
        standard_terms ,
        override_terms
      INTO lc_profile_class_id ,
        lc_prf_status ,
        lc_credit_check ,
        lc_standard_terms ,
        lc_override_terms
      FROM hz_cust_profile_classes
      WHERE name ='OMX_AR_CONV_CUSTOMER';
    EXCEPTION
    WHEN OTHERS THEN
      FND_FILE.PUT_LINE(FND_FILE.LOG,'Exception in Cust Profile Class : ' || SQLERRM);
      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Customer Profile'||sqlerrm,'');
    END;
    OPEN lcu_stg_tbl;
    LOOP
      FETCH lcu_stg_tbl BULK COLLECT INTO lc_odn_batch_customer_bulk LIMIT 5000;
      EXIT
    WHEN lc_odn_batch_customer_bulk.COUNT = 0;
      FOR indx_odn_batch IN 1 .. lc_odn_batch_customer_bulk.COUNT
      LOOP
        --- FOR stg_tbl_rec IN lcu_stg_tbl  LOOP
        -- Initialize Variables.
        FND_FILE.PUT_LINE(FND_FILE.LOG,'Start Creating Customers');
        ln_new_party_id          := NULL;
        lc_party_name            := NULL;
        ln_profile_id            := NULL;
        ln_cust_account_id       := NULL;
        ln_cust_party_id         := NULL;
        ln_cust_profile_id       := NULL;
        ln_responsibility_id     := NULL;
        ln_sorg_party_id         := NULL;
        ln_party_id              := NULL;
        ln_custacct_id           := NULL;
        lc_cust_account_num      := NULL;
        ln_parent_party_id       := NULL;
        lv_relationship_rec_type := NULL;
        ln_relationship_id       := NULL;
        ln_rel_party_id          := NULL;
        lc_rel_party_number      := NULL;
        lc_relationship_flag     := 'N';
        lc_default_billto        := 'N';
        lc_default_shipto        := 'N';
        ln_new_cust_acct_flg     := 'N';
        ln_cust_count            := 0;
        ln_custacct_count        := 0;
        ln_new_party_created     := 'N';
        lc_bill_to_consg_no_dup  := NULL;
        lc_ship_to_consg_no_dup  := NULL;
        FOR stg_tbl_rec_odn IN lcu_stg_tbl_odn(lc_odn_batch_customer_bulk(indx_odn_batch))
        LOOP
          lc_stg_rec                     := NULL;
          lc_error_flag                  := 'N';
          lc_reject_msg_out              := NULL;
          ln_msg_count                   := NULL;
          ln_msg_index_out               := NULL;
          ln_bill_to_location_id         := NULL;
          ln_bill_to_party_site_id       := NULL;
          ln_bill_cust_acct_site_id      := NULL;
          ln_bill_party_site_use_id      := NULL;
          ln_bill_site_use_id            := NULL;
          lc_bill_to_party_site_number   := NULL;
          bill_person_record_rec_type    := NULL;
          ln_bill_party_id               := NULL;
          lc_bill_party_number           := NULL;
          ln_bill_profile_id             := NULL;
          bill_contact_rec_type          := NULL;
          ln_bill_contact_id             := NULL;
          ln_bill_party_rel_id           := NULL;
          ln_borg_party_id               := NULL;
          lc_borg_party_number           := NULL;
          lv_bill_contact_point_rec_type := NULL;
          lv_bill_email_rec_type         := NULL;
          lv_bill_phone_rec_type         := NULL;
          ln_bill_contact_point_id       := NULL;
          lv_bill_acct_role_rec_type     := NULL;
          ln_bill_acct_role_id           := NULL;
          lv_bill_role_resp_rec_type     := NULL;
          ln_bill_responsibility_id      := NULL;
          ln_duns_party_id               := NULL;
          ln_party_rel_id                := NULL;
          ln_cust_account_role_id        := NULL;
          ln_contact_point_id            := NULL;
          lc_return_status               := NULL;
          lc_party_site_number           := NULL;
          lc_party_number                := NULL;
          lc_cust_party_number           := NULL;
          lc_cust_account_number         := NULL;
          lc_msg_data                    := NULL;
          lc_output                      := NULL;
          lc_err_msg                     := NULL;
          lv_bill_party_site_rec_type    := NULL;
          lv_ship_party_site_rec_type    := NULL;
          lv_organization_rec_type       := NULL;
          lv_organization_rec_type_null  := NULL;
          lv_cust_account_rec_type       := NULL;
          lv_customer_profile_rec_type   := NULL;
          lv_profile_class_amt_tbl_type  := NULL;
          lv_profile_amt_rec_type        := NULL;
          lv_bill_location_rec_type      := NULL;
          lv_ship_location_rec_type      := NULL;
          lv_web_rec_type                := NULL;
          lv_cr_cust_acc_role_rec_type   := NULL;
          lv_bill_cust_site_use_rec_type := NULL;
          lv_ship_cust_site_use_rec_type := NULL;
          lv_person_rec_type             := NULL;
          lv_org_contact_rec_type        := NULL;
          lv_bill_partysiteuse_rec_type  := NULL;
          lv_ship_partysiteuse_rec_type  := NULL;
          lv_bill_custacctsite_rec_type  := NULL;
          lv_ship_custacctsite_rec_type  := NULL;
          ln_ship_to_location_id         := NULL;
          ln_ship_to_party_site_id       := NULL;
          lc_ship_to_party_site_number   := NULL;
          ln_ship_party_site_use_id      := NULL;
          ln_ship_site_use_id            := NULL;
          lv_ship_cust_site_use_rec_type := NULL;
          lv_ship_contact_rec_type       := NULL;
          lv_ship_person_rec_type        := NULL;
          lv_ship_contact_point_rec_type := NULL;
          lv_ship_email_rec_type         := NULL;
          lv_ship_phone_rec_type         := NULL;
          lv_ship_acct_role_rec_type     := NULL;
          ln_ship_contact_point_id       := NULL;
          ln_ship_party_id               := NULL;
          ln_ship_cust_acct_site_id      := NULL;
          ln_ship_acct_role_id           := NULL;
          lc_ship_party_number           := NULL;
          ln_ship_contact_id             := NULL;
          ln_ship_profile_id             := NULL;
          ln_ship_party_rel_id           := NULL;
          lc_sorg_party_number           := NULL;
          lv_org_person_rec_type         := NULL;
          lv_org_contact_rec_type        := NULL;
          lv_org_location_rec_type       := NULL;
          lv_org_party_site_rec_type     := NULL;
          lv_org_contact_point_rec_type  := NULL;
          ln_org_party_id                := NULL;
          lc_org_party_number            := NULL;
          ln_org_profile_id              := NULL;
          ln_org_contact_id              := NULL;
          ln_org_party_rel_id            := NULL;
          ln_org_contact_point_id        := NULL;
          ln_corg_party_id               := NULL;
          lc_corg_party_number           := NULL;
          ln_collect_location_id         := NULL;
          ln_collect_party_site_id       := NULL;
          lc_collect_party_site_number   := NULL;
          ln_billto_count                := 0;
          ln_shipto_count                := 0;
          lc_bill_to_consg_no            := NULL;
          lc_ship_to_consg_no            := NULL;
          ---------------------------------------------------------------------------
          --   create organization
          ----------------------------------------------------------------------------
          lv_organization_rec_type.organization_name               := stg_tbl_rec_odn.odn_cust_name||'-CONV'; --OMX        -- Changed by Punit on 17-JAN-2018
          lc_party_name                                            := lv_organization_rec_type.organization_name;
          lv_organization_rec_type.created_by_module               :='TCA_V2_API';
          lv_organization_rec_type.party_rec.orig_system_reference := stg_tbl_rec_odn.odn_cust_num||'-CONV'; -- stg_tbl_rec.odn_cust_num||'-OMX';
          FND_FILE.PUT_LINE(FND_FILE.LOG, '*********************************************************************************************************************') ;
          FND_FILE.PUT_LINE(FND_FILE.LOG,' Records getting processedd for PARTY NAME: '|| lc_party_name );
          FND_FILE.PUT_LINE(FND_FILE.LOG, '*********************************************************************************************************************') ;
          IF (ln_new_party_created = 'N') THEN
            BEGIN
              SELECT COUNT(1)
              INTO ln_cust_count
              FROM hz_parties HP1
              WHERE EXISTS
                (SELECT 1
                FROM hz_parties hp2,
                  hz_cust_accounts hca
                WHERE hca.party_id            = hp2.party_id
                AND hp2.party_name            = lc_party_name
                AND hp2.orig_system_reference = stg_tbl_rec_odn.odn_cust_num
                  ||'-CONV' -- stg_tbl_rec.odn_cust_num||'-OMX'
                AND hca.orig_system_reference = stg_tbl_rec_odn.odn_cust_num
                  ||'-CONV'
                AND hca.status   = 'A'
                AND hp2.status   = 'A'
                AND hp2.party_id = hp1.party_id
                );
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value of lc_party_name is: '||lc_party_name);
              FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value of ln_cust_count is: '||ln_cust_count);
              IF ln_cust_count       <> 0 THEN
                ln_new_party_created := 'Y';
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Party already exists , value of ln_new_party_created is : '||ln_new_party_created);
                BEGIN
                  SELECT hp.party_id,
                    hca.cust_account_id,
                    hca.account_number
                  INTO ln_party_id,
                    ln_custacct_id,
                    lc_cust_account_num
                  FROM hz_parties hp,
                    hz_cust_accounts hca
                  WHERE hca.party_id           = hp.party_id
                  AND hp.party_name            = lc_party_name
                  AND hp.orig_system_reference = stg_tbl_rec_odn.odn_cust_num
                    ||'-CONV' --stg_tbl_rec.odn_cust_num||'-OMX'
                  AND hca.orig_system_reference = stg_tbl_rec_odn.odn_cust_num
                    ||'-CONV'
                  AND hca.status = 'A'
                  AND hp.status  = 'A';
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'Existing Customer Account# is: '||lc_cust_account_num );
                EXCEPTION
                WHEN OTHERS THEN
                  ln_party_id    := NULL;
                  ln_custacct_id := NULL;
                END;
              ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG, 'Customer and Account Creation Process initiated for the new customer');
              END IF;
            EXCEPTION
            WHEN OTHERS THEN
              ln_cust_count := NULL;
              --FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while checking for existing account information'||SQLCODE||SQLERRM );
            END;
            IF (ln_cust_count = 0) THEN
              hz_party_v2pub.create_organization (p_init_msg_list => lc_init_msg_list ,p_organization_rec => lv_organization_rec_type ,x_party_id => ln_new_party_id ,x_party_number => lc_party_number ,x_profile_id => ln_profile_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After CREATE_ORGANIZATION, lc_return_status: ' || lc_return_status,' ln_new_party_id: ' || ln_new_party_id);
              --If API fails
              IF lc_return_status <> 'S' THEN
                lc_error_flag     :='Y';
                FOR i IN 1 .. ln_msg_count
                LOOP
                  fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                  lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                END LOOP;
                lc_output := lc_output||'- Error while creating Party for Main Organization';
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Create Organization'||lc_output,lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while creating Organization : ' || lc_output||' for ODN# :'||stg_tbl_rec_odn.odn_cust_num);
                x_ret_code := 1;
              ELSE
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Create Organization:'||stg_tbl_rec_odn.odn_cust_num,lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Organization Created for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
              END IF;
              ----------------------------------------------------------------------------
              --Create Account
              ----------------------------------------------------------------------------
              lv_organization_rec_type.party_rec.party_id := ln_new_party_id;
              --lv_organization_rec_type.party_rec.party_number:= lc_party_number;
              lv_cust_account_rec_type.account_name := stg_tbl_rec_odn.odn_cust_name;
              --lv_cust_account_rec_type.orig_system           := 'VPS';
              lv_cust_account_rec_type.orig_system_reference := stg_tbl_rec_odn.odn_cust_num ||'-CONV' ;
              lv_cust_account_rec_type.created_by_module     := 'TCA_V2_API';
              -- Cust Profile
              lv_customer_profile_rec_type.profile_class_id :=lc_profile_class_id;
              lv_customer_profile_rec_type.status           :=lc_prf_status;
              lv_customer_profile_rec_type.credit_checking  :=lc_credit_check;
              lv_customer_profile_rec_type.standard_terms   :=lc_standard_terms;
              lv_customer_profile_rec_type.override_terms   :=lc_override_terms;
              lv_customer_profile_rec_type.attribute3       :='Y'; -- Added by Punit on 09-FEB-2018 for the WebCollect changes
              hz_cust_account_v2pub.create_cust_account (p_init_msg_list => lc_init_msg_list ,p_cust_account_rec => lv_cust_account_rec_type ,p_organization_rec => lv_organization_rec_type ,p_customer_profile_rec => lv_customer_profile_rec_type ,p_create_profile_amt => 'T' ,x_cust_account_id => ln_cust_account_id ,x_account_number => lc_cust_account_number ,x_party_id => ln_cust_party_id ,x_party_number => lc_cust_party_number ,x_profile_id => ln_cust_profile_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After Create_Cust_Account, lc_return_status: ' || lc_return_status|| ', ln_cust_account_id: ' || ln_cust_account_id,lc_return_status);
              --If API fails
              IF lc_return_status <> 'S' THEN
                lc_error_flag     :='Y';
                FOR i IN 1 .. ln_msg_count
                LOOP
                  fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                  lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                END LOOP;
                lc_output := lc_output||'- Error while creating Cust Account for Main Organization';
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Create Account'||lc_output,lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while creating Account Number#'||stg_tbl_rec_odn.odn_cust_num||' is : ' || lc_output);
                x_ret_code           := 1;
                ln_new_cust_acct_flg := 'N';
                /*BEGIN
                SELECT COUNT(1)
                INTO  ln_custacct_count
                FROM  hz_cust_accounts hca
                WHERE hca.orig_system_reference = stg_tbl_rec_odn.odn_cust_num||'-CONV'
                AND   hca.status = 'A';
                --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value of ln_custacct_count during Account Creation Exception is: '||ln_custacct_count);
                IF ln_custacct_count <> 0 THEN
                --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Account already exists');
                IF ln_custacct_id IS NULL THEN
                BEGIN
                SELECT hca.cust_account_id
                INTO  ln_custacct_id
                FROM  hz_cust_accounts hca
                WHERE hca.orig_system_reference = stg_tbl_rec_odn.odn_cust_num||'-CONV'
                AND   hca.status = 'A';
                --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Value of ln_custacct_id during Account Creation Exception is: '||ln_custacct_id);
                --x_ret_code := 1;
                EXCEPTION
                WHEN OTHERS THEN
                ln_custacct_id := NULL;
                END;
                END IF;
                END IF;
                EXCEPTION
                WHEN OTHERS THEN
                ln_custacct_count := NULL;
                END;*/
                --x_ret_code := 1;
              ELSE
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Create Account Number:'||lc_cust_account_number,lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,' Create Account Number: ' || lc_cust_account_number);
                ln_new_cust_acct_flg := 'Y';
                ln_new_party_created := 'Y';
                FND_FILE.PUT_LINE(FND_FILE.LOG, ' value of ln_new_party_created is : '||ln_new_party_created);
              END IF;
              --COMMIT;
              ----------------------------------------------------------------------------------------------------------------------------------------
              --Create location
              ----------------------------------------------------------------------------------------------------------------------------------------
              IF ln_new_cust_acct_flg                       = 'Y' THEN
                lv_org_location_rec_type.address1          := stg_tbl_rec_odn.org_address1;
                lv_org_location_rec_type.address2          := stg_tbl_rec_odn.org_address2;
                lv_org_location_rec_type.address3          := '';
                lv_org_location_rec_type.city              := stg_tbl_rec_odn.org_city;
                lv_org_location_rec_type.county            := 'DEFAULT';
                lv_org_location_rec_type.state             := stg_tbl_rec_odn.org_state;
                lv_org_location_rec_type.country           := 'US';
                lv_org_location_rec_type.postal_code       := stg_tbl_rec_odn.org_zipcode;
                lv_org_location_rec_type.created_by_module := 'TCA_V2_API';
                hz_location_v2pub.create_location (p_init_msg_list => lc_init_msg_list ,p_location_rec => lv_org_location_rec_type ,x_location_id => ln_collect_location_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Create_Location_COLLECTION, lc_return_status: ' || lc_return_status || ', ln_collect_location_id: ' || ln_collect_location_id,lc_return_status);
                --FND_FILE.PUT_LINE(FND_FILE.LOG, 'After ORG Create_Location_COLLECTION, lc_return_status: ' || lc_return_status || ', ln_collect_location_id: ' || ln_collect_location_id);
                --If API fails
                IF lc_return_status <> 'S' THEN
                  lc_error_flag     :='Y';
                  FOR i IN 1 .. ln_msg_count
                  LOOP
                    fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                    lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                  END LOOP;
                  lc_output := lc_output||'- Error while creating Location for Main Organization';
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG Create_Location_COLLECTION, lc_err_msg: ' || lc_err_msg,lc_return_status);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Create_Location_COLLECTION, Error mesg: ' || lc_output);
                  x_ret_code := 1;
                ELSE
                  --  FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Create_Location_COLLECTION ln_collect_location_id: ' || ln_collect_location_id);
                  --END IF;  -- lc_return_status <> 'S' for hz_location_v2pub.create_location
                  ----------------------------------------------------------------------------------------------------------------------------------------
                  -- Create party site for Organization
                  ----------------------------------------------------------------------------------------------------------------------------------------
                  lv_org_party_site_rec_type.identifying_address_flag := 'Y';
                  lv_org_party_site_rec_type.status                   := 'A';
                  lv_org_party_site_rec_type.party_id                 := ln_new_party_id; --ln_corg_party_id;
                  lv_org_party_site_rec_type.location_id              := ln_collect_location_id;
                  lv_org_party_site_rec_type.created_by_module        := 'TCA_V2_API';
                  hz_party_site_v2pub.create_party_site (p_init_msg_list => lc_init_msg_list ,p_party_site_rec => lv_org_party_site_rec_type ,x_party_site_id => ln_collect_party_site_id ,x_party_site_number => lc_collect_party_site_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Create_Party_Site, lc_return_status: ' || lc_return_status || ', ln_collect_party_site_id: ' || ln_collect_party_site_id,lc_return_status);
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Create_Party_Site, lc_return_status: ' || lc_return_status || ', ln_collect_party_site_id: ' || ln_collect_party_site_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating party site for Main Organization';
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG Create_party_site_collect, lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' After ORG Create_party_site_collect, Error mesg: ' || lc_output);
                    x_ret_code := 1;
                  ELSE
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG create_party_site_collect ln_collect_party_site_id: ' || ln_collect_party_site_id);
                  END IF;
                END IF; -- lc_return_status <> 'S' for hz_location_v2pub.create_location
                ----------------------------------------------------------------------
                -- ORG CONTACT Create person, Create Org Contact Point
                ----------------------------------------------------------------------
                IF (stg_tbl_rec_odn.org_contact_name        IS NOT NULL) THEN
                  lv_org_person_rec_type.person_first_name  := fnd_api.g_miss_char;
                  lv_org_person_rec_type.person_middle_name := fnd_api.g_miss_char;
                  lv_org_person_rec_type.person_last_name   := stg_tbl_rec_odn.org_contact_name;
                  lv_org_person_rec_type.person_name_suffix := fnd_api.g_miss_char;
                  lv_org_person_rec_type.created_by_module  := 'TCA_V2_API';
                  hz_party_v2pub.create_person (p_init_msg_list => lc_init_msg_list ,p_person_rec => lv_org_person_rec_type ,x_party_id => ln_org_party_id ,x_party_number => lc_org_party_number ,x_profile_id => ln_org_profile_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating person for Main Organization';
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG create_person, lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG create_person, Error mesg: ' || lc_output);
                    x_ret_code := 1;
                  ELSE
                    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG create_person ln_org_party_id: ' || ln_org_party_id);
                    --END IF;  -- lc_return_status <> 'S' create_person
                    -- END IF;  -- stg_tbl_rec_odn.org_contact_name IS NOT NULL
                    --Link person to organization
                    lv_org_contact_rec_type.job_title_code                   := NULL;
                    lv_org_contact_rec_type.job_title                        := NULL; --'AP'; Changed by Punit on 09-FEB-2018
                    lv_org_contact_rec_type.created_by_module                := 'TCA_V2_API';
                    lv_org_contact_rec_type.party_rel_rec.subject_id         := ln_org_party_id;
                    lv_org_contact_rec_type.party_rel_rec.subject_type       := 'PERSON';
                    lv_org_contact_rec_type.party_rel_rec.subject_table_name := 'HZ_PARTIES';
                    lv_org_contact_rec_type.party_rel_rec.object_id          := ln_new_party_id;
                    lv_org_contact_rec_type.party_rel_rec.object_type        := 'ORGANIZATION';
                    lv_org_contact_rec_type.party_rel_rec.object_table_name  := 'HZ_PARTIES';
                    lv_org_contact_rec_type.party_rel_rec.relationship_code  := 'CONTACT_OF';
                    lv_org_contact_rec_type.party_rel_rec.relationship_type  := 'CONTACT';
                    lv_org_contact_rec_type.party_rel_rec.start_date         := SYSDATE;
                    hz_party_contact_v2pub.create_org_contact (p_init_msg_list => lc_init_msg_list ,p_org_contact_rec => lv_org_contact_rec_type ,x_org_contact_id => ln_org_contact_id ,x_party_rel_id => ln_org_party_rel_id ,x_party_id => ln_corg_party_id ,x_party_number => lc_corg_party_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating Org Contact for Main Organization ';
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG create_org_contact, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG create_org_contact, Error mesg: ' || lc_output);
                    ELSE
                      -- FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG create_org_contact ln_org_contact_id: ' || ln_org_contact_id);
                      --END IF;  lc_return_status <> 'S' create_org_contact
                      IF (stg_tbl_rec_odn.org_contact_email                 IS NOT NULL OR stg_tbl_rec_odn.org_contact_phone IS NOT NULL ) THEN
                        lv_org_contact_point_rec_type.contact_point_type    := 'PHONE';
                        lv_org_contact_point_rec_type.owner_table_name      := 'HZ_PARTIES';
                        lv_org_contact_point_rec_type.owner_table_id        := ln_corg_party_id;
                        lv_org_contact_point_rec_type.primary_flag          := 'Y';
                        lv_org_contact_point_rec_type.contact_point_purpose := 'COLLECTIONS';
                        lv_org_contact_point_rec_type.created_by_module     := 'TCA_V2_API';
                        lv_org_email_rec_type.email_format                  := 'MAILHTML';
                        lv_org_email_rec_type.email_address                 := stg_tbl_rec_odn.org_contact_email;
                        --  l_phone_rec.phone_area_code                  := stg_tbl_rec_odn.phone_area_code;
                        --  l_phone_rec.phone_country_code               := stg_tbl_rec_odn.phone_country_code;
                        lv_org_phone_rec_type.phone_number    := stg_tbl_rec_odn.org_contact_phone;
                        lv_org_phone_rec_type.phone_line_type := 'GEN';
                        --   l_phone_rec.phone_extension                  := stg_tbl_rec_odn.phone_extension;
                        lc_return_status := NULL;
                        ln_msg_count     := NULL;
                        lc_msg_data      := NULL;
                        HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT (p_init_msg_list => 'T', p_contact_point_rec => lv_org_contact_point_rec_type, p_edi_rec => NULL, p_email_rec => lv_org_email_rec_type, p_phone_rec => lv_org_phone_rec_type, p_telex_rec => NULL, p_web_rec => NULL, x_contact_point_id => ln_org_contact_point_id , x_return_status => lc_return_status, x_msg_count => ln_msg_count, x_msg_data => lc_msg_data );
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG CREATE_CONTACT_POINT, l_return_status: ' || lc_return_status || ', ln_org_contact_point_id : ' || ln_org_contact_point_id,lc_return_status );
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG CREATE_CONTACT_POINT, l_return_status: ' || lc_return_status || ', ln_org_contact_point_id : ' || ln_org_contact_point_id);
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          lc_output := lc_output||'- Error while creating Contact Point for Main Organization ';
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG CREATE_CONTACT_POINT, lc_output: ' || lc_output,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG CREATE_CONTACT_POINT, Error mesg: ' || lc_output);
                          x_ret_code := 1;
                        ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG CREATE_CONTACT_POINT ln_org_contact_point_id : ' || ln_org_contact_point_id );
                        END IF; -- lc_return_status <> 'S' CREATE_CONTACT_POINT
                      END IF;  --- stg_tbl_rec_odn.org_contact_email IS NOT NULL OR stg_tbl_rec_odn.org_contact_phone IS NOT NULL
                      -- Link organization to customer account
                      lv_org_acct_role_rec_type.created_by_module := 'TCA_V2_API';
                      lv_org_acct_role_rec_type.party_id          := ln_corg_party_id;   --Party id from org contact
                      lv_org_acct_role_rec_type.cust_account_id   := ln_cust_account_id; -- value of cust_account_id from step 1
                      lv_org_acct_role_rec_type.cust_acct_site_id := ln_bill_cust_acct_site_id;
                      lv_org_acct_role_rec_type.role_type         := 'CONTACT';
                      lv_org_acct_role_rec_type.status            := 'A';
                      HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(p_init_msg_list => 'T' , p_cust_account_role_rec => lv_org_acct_role_rec_type, x_cust_account_role_id=> ln_org_acct_role_id, x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data);
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Create cust account role l_return_status: ' || lc_return_status || ', ln_org_acct_role_id : ' || ln_org_acct_role_id,lc_return_status );
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Create cust account role l_return_status: ' || lc_return_status || ', ln_org_acct_role_id : ' || ln_org_acct_role_id);
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating Cust Account Role for Main Organization ';
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG Create_cust_account_role, lc_err_msg: ' || lc_err_msg,lc_output);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Create_cust_account_role, Error mesg: ' || lc_output);
                        x_ret_code := 1;
                      ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'ORG Cust Account role ln_org_acct_role_id : ' || ln_org_acct_role_id );
                      END IF; -- lc_return_status <> 'S' create_cust_account_role
                    END IF;   --lc_return_status <> 'S' create_org_contact
                  END IF;     -- lc_return_status <> 'S' create_person
                END IF;       -- stg_tbl_rec_odn.org_contact_name IS NOT NULL
                --------------------------------------------------------------------------------------------------------------------------------------------------------
                -- Creating Default Location MAIN_ACCT for BILL TO USE
                --------------------------------------------------------------------------------------------------------------------------------------------------------
                --IF (lc_default_billto = 'N') THEN
                lv_bill_location_rec_type.address1           := stg_tbl_rec_odn.org_address1;
                lv_bill_location_rec_type.address2           := stg_tbl_rec_odn.org_address2;
                lv_bill_location_rec_type.address3           := '';
                lv_bill_location_rec_type.city               := stg_tbl_rec_odn.org_city;
                lv_bill_location_rec_type.state              := stg_tbl_rec_odn.org_state;
                lv_bill_location_rec_type.postal_code        := stg_tbl_rec_odn.org_zipcode;
                lv_bill_cust_site_use_rec_type.location      := 'MAIN_ACCT';
                bill_person_record_rec_type.person_last_name := stg_tbl_rec_odn.org_contact_name;
                lv_bill_email_rec_type.email_address         := stg_tbl_rec_odn.org_contact_email;
                lv_bill_phone_rec_type.phone_number          := stg_tbl_rec_odn.org_contact_phone;
                lv_bill_location_rec_type.county             := 'DEFAULT';
                lv_bill_location_rec_type.country            := 'US';
                lv_bill_location_rec_type.created_by_module  := 'TCA_V2_API';
                hz_location_v2pub.create_location (p_init_msg_list => lc_init_msg_list ,p_location_rec => lv_bill_location_rec_type ,x_location_id => ln_bill_to_location_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Default Create_Location_Bill_To MAIN_ACCT, lc_return_status: ' || lc_return_status || ', ln_bill_to_location_id: ' || ln_bill_to_location_id,SQLERRM);
                --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO Create_Location_Bill_To MAIN_ACCT, lc_return_status: ' || lc_return_status || ', ln_bill_to_location_id: ' || ln_bill_to_location_id);
                --If API fails
                IF lc_return_status <> 'S' THEN
                  lc_error_flag     :='Y';
                  FOR i IN 1 .. ln_msg_count
                  LOOP
                    fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                    lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                  END LOOP;
                  lc_output := lc_output||'- Error while creating Location for BILL_TO Location MAIN_ACCT';
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO Create_Location_Bill_To, lc_err_msg: ' || lc_err_msg,lc_return_status);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO Create_Location_Bill_To, Error mesg: ' || lc_output);
                  x_ret_code := 1;
                ELSE
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO Create Location ln_bill_to_location_id: ' || ln_bill_to_location_id);
                  --END IF;  -- lc_return_status <> 'S' for create_location MAIN_ACCT
                  ---------------------------------------------------------------
                  --Create Party Site BILL TO
                  ---------------------------------------------------------------
                  lv_bill_party_site_rec_type.identifying_address_flag := 'Y';
                  lv_bill_party_site_rec_type.status                   := 'A';
                  lv_bill_party_site_rec_type.party_id                 := NVL(ln_new_party_id,ln_party_id);
                  lv_bill_party_site_rec_type.location_id              := ln_bill_to_location_id;
                  lv_bill_party_site_rec_type.created_by_module        := 'TCA_V2_API';
                  hz_party_site_v2pub.create_party_site (p_init_msg_list => lc_init_msg_list ,p_party_site_rec => lv_bill_party_site_rec_type ,x_party_site_id => ln_bill_to_party_site_id ,x_party_site_number => lc_bill_to_party_site_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Default BILL_TO Create_Party_Site, lc_return_status: ' || lc_return_status || ', ln_bill_to_party_site_id: ' || ln_bill_to_party_site_id,SQLERRM);
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO Create_Party_Site, lc_return_status: ' || lc_return_status || ', ln_bill_to_party_site_id: ' || ln_bill_to_party_site_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating party site for BILL_TO Location MAIN_ACCT';
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG Default BILL_TO Create_party_site, lc_err_msg: ' || lc_output,lc_return_status);
                    --DBMS_OUTPUT.put_line('Error mesg: ' || lc_output);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO Create_party_site, Error mesg: ' || lc_output);
                    x_ret_code := 1;
                  ELSE
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO Create Party Site , ln_bill_to_party_site_id: ' || ln_bill_to_party_site_id);
                    -- END IF;  -- lc_return_status <> 'S' for create_party_site
                    ----------------------------------------------------------------
                    -- Create Cust Acct Site BILL TO
                    ----------------------------------------------------------------
                    lv_bill_custacctsite_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); -- ln_cust_account_id
                    lv_bill_custacctsite_rec_type.party_site_id     := ln_bill_to_party_site_id;
                    lv_bill_custacctsite_rec_type.created_by_module :='TCA_V2_API';
                    --lv_bill_custacctsite_rec_type.orig_system_reference := stg_tbl_rec_odn.odn_cust_num || '-CONV' ; Commented by Punit on 21-DEC-2017
                    hz_cust_account_site_v2pub.create_cust_acct_site (lc_init_msg_list ,lv_bill_custacctsite_rec_type ,ln_bill_cust_acct_site_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Default BILL_TO create_cust_acct_site, lc_return_status: ' || lc_return_status || ', ln_bill_cust_acct_site_id: ' || ln_bill_cust_acct_site_id,lc_return_status);
                    --FND_FILE.PUT_LINE(FND_FILE.LOG, 'After ORG Default BILL_TO create_cust_acct_site, lc_return_status: ' || lc_return_status || ', ln_bill_cust_acct_site_id: ' || ln_bill_cust_acct_site_id);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating cust acct site for BILL_TO Location MAIN_ACCT';
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG Default BILL_TO create_cust_acct_site, lc_err_msg: ' || lc_output,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO create_cust_acct_site, Error mesg: ' || lc_output);
                      x_ret_code := 1;
                    ELSE
                      -- FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO Create create_cust_acct_site ln_bill_cust_acct_site_id: ' || ln_bill_cust_acct_site_id);
                      --END IF;  -- lc_return_status <> 'S' for create_cust_acct_site
                      -------------------------------------------------------------------
                      --Create party site use BILL TO
                      -------------------------------------------------------------------
                      lv_bill_partysiteuse_rec_type.site_use_type     := 'BILL_TO';
                      lv_bill_partysiteuse_rec_type.primary_per_type  := 'Y';
                      lv_bill_partysiteuse_rec_type.party_site_id     := ln_bill_to_party_site_id;
                      lv_bill_partysiteuse_rec_type.status            := 'A';
                      lv_bill_partysiteuse_rec_type.created_by_module :='TCA_V2_API';
                      hz_party_site_v2pub.create_party_site_use (p_init_msg_list => lc_init_msg_list ,p_party_site_use_rec => lv_bill_partysiteuse_rec_type ,x_party_site_use_id => ln_bill_party_site_use_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Default BILL_TO create_party_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_party_site_use_id: ' || ln_bill_party_site_use_id,lc_return_status);
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO create_party_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_party_site_use_id: ' || ln_bill_party_site_use_id);
                      --If API fails
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating party site use for BILL_TO Location MAIN_ACCT';
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG Default BILL_TO create_party_site_use , lc_err_msg: ' || lc_err_msg,lc_return_status);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO create_party_site_use , Error mesg: ' || lc_output);
                        x_ret_code := 1;
                      ELSE
                        --  FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL TO Create create_party_site_use ln_bill_party_site_use_id:: ' || ln_bill_party_site_use_id);
                        --END IF;  lc_return_status <> 'S' for create_party_site_use
                        ---------------------------------------------------------------------------
                        -- Create Cust Account site use BILL TO
                        ---------------------------------------------------------------------------
                        lv_bill_cust_site_use_rec_type.cust_acct_site_id := ln_bill_cust_acct_site_id;
                        lv_bill_cust_site_use_rec_type.site_use_code     := 'BILL_TO';
                        lv_bill_cust_site_use_rec_type.primary_flag      := 'Y';
                        lv_bill_cust_site_use_rec_type.status            := 'A';
                        lv_bill_cust_site_use_rec_type.created_by_module :='TCA_V2_API';
                        --SELECT hz_cust_site_uses_s.nextval into p_location from dual;
                        hz_cust_account_site_v2pub.create_cust_site_use ('T' ,lv_bill_cust_site_use_rec_type ,NULL ,'F' ,'F' ,ln_bill_site_use_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG Default BILL_TO create_cust_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_site_use_id: ' || ln_bill_site_use_id,lc_return_status);
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO create_cust_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_site_use_id: ' || ln_bill_site_use_id);
                        --If API fails
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          lc_output := lc_output||'- Error while creating cust acct site use for BILL_TO Location MAIN_ACCT';
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After ORG Default BILL_TO create_cust_site_use, lc_err_msg: ' || lc_output,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO create_cust_site_use, Error mesg: ' || lc_output);
                          x_ret_code := 1;
                        ELSE
                          ----FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO create_cust_site_use ln_bill_site_use_id: ' || ln_bill_site_use_id);
                          ---lc_default_billto := 'Y';
                          ----FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default, Value of lc_default_billto: ' || lc_default_billto);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL TO LOCATION AND PARTY SITE CREATED FOR LOCATION: '||lv_bill_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                        END IF; --lc_return_status <> 'S' for create_cust_site_use
                      END IF;   -- lc_return_status <> 'S' for create_party_site_use
                    END IF;     -- lc_return_status <> 'S' for create_cust_acct_site
                  END IF;       -- lc_return_status <> 'S' for create_party_site
                END IF;         -- lc_return_status <> 'S' for create_location MAIN_ACCT BILL_TO
                ----------------------------------------------------------------------
                -- Create person, Create Org Contact Point for BILL TO MAIN_ACCT
                ----------------------------------------------------------------------
                IF bill_person_record_rec_type.person_last_name  IS NOT NULL THEN
                  bill_person_record_rec_type.person_first_name  := fnd_api.g_miss_char;
                  bill_person_record_rec_type.person_middle_name := fnd_api.g_miss_char;
                  bill_person_record_rec_type.person_name_suffix := fnd_api.g_miss_char;
                  bill_person_record_rec_type.created_by_module  := 'TCA_V2_API';
                  hz_party_v2pub.create_person (p_init_msg_list => lc_init_msg_list ,p_person_rec => bill_person_record_rec_type ,x_party_id => ln_bill_party_id ,x_party_number => lc_bill_party_number ,x_profile_id => ln_bill_profile_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG Default BILL_TO create_person, lc_return_status: ' || lc_return_status || ', ln_bill_party_id: ' || ln_bill_party_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating person for BILL_TO Location MAIN_ACCT';
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO create_person, lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_person, Error mesg: ' || lc_output);
                    x_ret_code := 1;
                  ELSE
                    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO create_person , ln_bill_party_id: ' || ln_bill_party_id);
                    ---END IF;
                    --Link person to organization
                    bill_contact_rec_type.job_title_code                   := NULL;
                    bill_contact_rec_type.job_title                        := 'AP'; --Changed by Punit on 09-FEB-2018   --NULL;
                    bill_contact_rec_type.created_by_module                := 'TCA_V2_API';
                    bill_contact_rec_type.party_rel_rec.subject_id         := ln_bill_party_id;
                    bill_contact_rec_type.party_rel_rec.subject_type       := 'PERSON';
                    bill_contact_rec_type.party_rel_rec.subject_table_name := 'HZ_PARTIES';
                    bill_contact_rec_type.party_rel_rec.object_id          := NVL(ln_new_party_id,ln_party_id);
                    bill_contact_rec_type.party_rel_rec.object_type        := 'ORGANIZATION';
                    bill_contact_rec_type.party_rel_rec.object_table_name  := 'HZ_PARTIES';
                    bill_contact_rec_type.party_rel_rec.relationship_code  := 'CONTACT_OF';
                    bill_contact_rec_type.party_rel_rec.relationship_type  := 'CONTACT';
                    bill_contact_rec_type.party_rel_rec.start_date         := SYSDATE;
                    hz_party_contact_v2pub.create_org_contact (p_init_msg_list => lc_init_msg_list ,p_org_contact_rec => bill_contact_rec_type ,x_org_contact_id => ln_bill_contact_id ,x_party_rel_id => ln_bill_party_rel_id ,x_party_id => ln_borg_party_id ,x_party_number => lc_borg_party_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                    --If API fails
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_org_contact , lc_return_status: ' || lc_return_status || ', ln_bill_contact_id: ' || ln_bill_contact_id);
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating org contact for BILL_TO Location MAIN_ACCT';
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO create_org_contact, lc_err_msg: ' || lc_output,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_org_contact, Error mesg: ' || lc_output);
                    ELSE
                      -- FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO create_org_contact ln_bill_contact_id: ' || ln_bill_contact_id);
                      --END IF;
                      -- Bill to Org Contact point
                      IF (stg_tbl_rec_odn.org_contact_email               IS NOT NULL OR stg_tbl_rec_odn.org_contact_phone IS NOT NULL ) THEN
                        lv_bill_contact_point_rec_type.contact_point_type := 'PHONE';
                        lv_bill_contact_point_rec_type.owner_table_name   := 'HZ_PARTIES';
                        lv_bill_contact_point_rec_type.owner_table_id     := ln_borg_party_id;
                        --  lv_bill_contact_point_rec_type.primary_flag          := 'Y';
                        lv_bill_contact_point_rec_type.contact_point_purpose := 'BUSINESS';
                        lv_bill_contact_point_rec_type.created_by_module     := 'TCA_V2_API';
                        lv_bill_email_rec_type.email_format                  := 'MAILHTML';
                        lv_bill_phone_rec_type.phone_line_type               :='GEN';
                        --   l_phone_rec.phone_extension                  := stg_tbl_rec_odn.phone_extension;
                        lc_return_status := NULL;
                        ln_msg_count     := NULL;
                        lc_msg_data      := NULL;
                        HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT (p_init_msg_list => 'T', p_contact_point_rec => lv_bill_contact_point_rec_type, p_edi_rec => NULL, p_email_rec => lv_bill_email_rec_type, p_phone_rec => lv_bill_phone_rec_type, p_telex_rec => NULL, p_web_rec => NULL, x_contact_point_id => ln_bill_contact_point_id , x_return_status => lc_return_status, x_msg_count => ln_msg_count, x_msg_data => lc_msg_data );
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO CREATE_CONTACT_POINT, l_return_status: ' || lc_return_status || ', ln_bill_contact_point_id : ' || ln_bill_contact_point_id,lc_return_status);
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO CREATE_CONTACT_POINT, l_return_status: ' || lc_return_status || ', ln_bill_contact_point_id : ' || ln_bill_contact_point_id);
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          lc_output := lc_output||'- Error while creating contact point for BILL_TO Location MAIN_ACCT';
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO CREATE_CONTACT_POINT, lc_err_msg: ' || lc_err_msg,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO CREATE_CONTACT_POINT, Error mesg: ' || lc_output);
                        ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO CREATE_CONTACT_POINT ln_bill_contact_point_id : ' || ln_bill_contact_point_id );
                        END IF;
                      END IF; -- stg_tbl_rec_odn.org_contact_email IS NOT NULL OR stg_tbl_rec_odn.org_contact_phone IS NOT NULL for DEFAULT BILL_TO
                      -- Link organization to customer account
                      lv_bill_acct_role_rec_type.created_by_module := 'TCA_V2_API';
                      lv_bill_acct_role_rec_type.party_id          := ln_borg_party_id;                       --Party id from org contact
                      lv_bill_acct_role_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); --ln_cust_account_id; -- value of cust_account_id from step 1
                      lv_bill_acct_role_rec_type.cust_acct_site_id := ln_bill_cust_acct_site_id;
                      lv_bill_acct_role_rec_type.role_type         := 'CONTACT';
                      lv_bill_acct_role_rec_type.status            := 'A';
                      HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(p_init_msg_list => 'T' , p_cust_account_role_rec => lv_bill_acct_role_rec_type, x_cust_account_role_id=> ln_bill_acct_role_id, x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data);
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_bill_acct_role_id : ' || ln_bill_acct_role_id,lc_return_status);
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_bill_acct_role_id : ' || ln_bill_acct_role_id);
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating cust acct role for BILL_TO Location MAIN_ACCT';
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO Create_cust_account_role, lc_err_msg: ' || lc_err_msg,lc_return_status);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create_cust_account_role, Error mesg: ' || lc_output);
                      ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'MAIN_ACCT AFTER BILL_TO Create Cust Account role ln_bill_acct_role_id : ' || ln_bill_acct_role_id );
                        -- Added by Punit on 16-MAR-2018 for the issue "Unable to see contacts of converted customers in Web Collect extract"
                        -- Role Responsibility Bill to
                        lv_bill_role_resp_rec_type.created_by_module   := 'TCA_V2_API';
                        lv_bill_role_resp_rec_type.cust_account_role_id:=ln_bill_acct_role_id;
                        lv_bill_role_resp_rec_type.primary_flag        :='Y';
                        lv_bill_role_resp_rec_type.responsibility_type := 'DUN';
                        HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility(p_init_msg_list => 'T' , p_role_responsibility_rec => lv_bill_role_resp_rec_type, x_responsibility_id => ln_responsibility_id, x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data);
                        --  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers',
                        -- 'After BILL TO create_role_responsibility, l_return_status: ' || lc_return_status || ', ln_responsibility_id : ' || ln_responsibility_id,lc_return_status);
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_role_responsibility, l_return_status: ' || lc_return_status || ', ln_responsibility_id : ' || ln_responsibility_id);
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          ----log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL TO create_role_responsibility, lc_err_msg: ' || lc_err_msg,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_role_responsibility, Error mesg: ' || lc_output);
                        ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO Create Cust Account role Responsibility ln_responsibility_id : ' || ln_responsibility_id );
                        END IF;
                      END IF;
                    END IF; --lc_return_status <> 'S' create_org_contact
                  END IF;   -- lc_return_status <> 'S' create_person
                END IF ;    -- bill_person_record_rec_type.person_last_name
                --------------------------------------------------------------------------------------------------------------------------------------------------------
                -- Creating Default Location MAIN_ACCT FOR SHIP_TO USE
                --------------------------------------------------------------------------------------------------------------------------------------------------------
                -------------------------------------------------------------------------------------
                --Create party site use SHIP TO  where Location name is same for both BILL_TO AND SHIP_TO
                --------------------------------------------------------------------------------------
                IF (ln_bill_to_party_site_id                      IS NOT NULL) THEN
                  lv_ship_partysiteuse_rec_type.site_use_type     := 'SHIP_TO';
                  lv_ship_partysiteuse_rec_type.primary_per_type  := 'Y';
                  lv_ship_partysiteuse_rec_type.party_site_id     := ln_bill_to_party_site_id;
                  lv_ship_partysiteuse_rec_type.status            := 'A';
                  lv_ship_partysiteuse_rec_type.created_by_module :='TCA_V2_API';
                  hz_party_site_v2pub.create_party_site_use (p_init_msg_list => lc_init_msg_list ,p_party_site_use_rec => lv_ship_partysiteuse_rec_type ,x_party_site_use_id => ln_ship_party_site_use_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'Similar LOCATIONS DEFAULT MAIN_ACCT - After create_party_site_use SHIP_TO , lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id,lc_return_status);
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS- After create_party_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating party site use for SHIP_TO Location MAIN_ACCT';
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Similar LOCATIONS DEFAULT MAIN_ACCT - After create_party_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,' Similar LOCATIONS DEFAULT MAIN_ACCT- After create_party_site_use SHIP_TO, Error mesg: ' || lc_output);
                  ELSE
                    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS DEFAULT MAIN_ACCT - Create create_party_site_use ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                    --END IF;   -- lc_return_status create_party_site_use for MAIN_ACCT SHIP_TO
                    ---------------------------------------------------------------------------
                    -- Create Cust Account site use SHIP TO
                    ---------------------------------------------------------------------------
                    lv_ship_cust_site_use_rec_type.cust_acct_site_id := ln_bill_cust_acct_site_id; --ln_ship_cust_acct_site_id;
                    lv_ship_cust_site_use_rec_type.site_use_code     := 'SHIP_TO';
                    lv_ship_cust_site_use_rec_type.primary_flag      := 'Y';
                    lv_ship_cust_site_use_rec_type.status            := 'A';
                    lv_ship_cust_site_use_rec_type.created_by_module :='TCA_V2_API';
                    lv_ship_cust_site_use_rec_type.location          := 'MAIN_ACCT';
                    hz_cust_account_site_v2pub.create_cust_site_use ('T' ,lv_ship_cust_site_use_rec_type ,NULL ,'F' ,'F' ,ln_ship_site_use_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'Similar LOCATIONS DEFAULT MAIN_ACCT -After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id,lc_return_status);
                    --FND_FILE.PUT_LINE(FND_FILE.LOG, 'Similar LOCATIONS DEFAULT MAIN_ACCT -After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating cust acct site use for SHIP_TO Location MAIN_ACCT';
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Similar LOCATIONS-After create_cust_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS DEFAULT MAIN_ACCT-After create_cust_site_use SHIP_TO, Error mesg: ' || lc_output);
                    ELSE
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS DEFAULT MAIN_ACCT -SHIP TO create_cust_site_use ln_ship_site_use_id: ' || ln_ship_site_use_id);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO LOCATION DEFAULT MAIN_ACCT AND PARTY SITE CREATED FOR LOCATION: '||lv_ship_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                    END IF;
                  END IF; -- lc_return_status create_party_site_use for MAIN_ACCT SHIP_TO
                END IF;   --ln_bill_to_party_site_id IS NOT NULL
                --END IF; ---lc_default_billto = 'N'
              END IF; -- ln_new_cust_acct_flg = 'Y'
            END IF ;  -- ln_cust_count = 0
          END IF ;   --- ln_new_party_created = 'N';
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' value of ln_new_party_created is : '||ln_new_party_created);
          ----------------------------------------------------------------
          --Create Location  BILL TO
          -----------------------------------------------------------------
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' value of lc_bill_to_consg_no_dup is : '||lc_bill_to_consg_no_dup);
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' value of stg_tbl_rec_odn.bill_to_cnsgno is : '||stg_tbl_rec_odn.bill_to_cnsgno);
          IF (stg_tbl_rec_odn.bill_to_cnsgno             IS NOT NULL AND ln_new_party_created = 'Y' AND (stg_tbl_rec_odn.bill_to_cnsgno <> lc_bill_to_consg_no_dup OR lc_bill_to_consg_no_dup IS NULL) AND stg_tbl_rec_odn.bill_to_rpt_flg = 'N' ) THEN --AND lc_default_billto = 'Y'
            lv_bill_location_rec_type.address1           := stg_tbl_rec_odn.bill_to_address1;
            lv_bill_location_rec_type.address2           := stg_tbl_rec_odn.bill_to_address2;
            lv_bill_location_rec_type.address3           := '';
            lv_bill_location_rec_type.city               := stg_tbl_rec_odn.bill_to_city;
            lv_bill_location_rec_type.state              := stg_tbl_rec_odn.bill_to_state;
            lv_bill_location_rec_type.postal_code        := stg_tbl_rec_odn.bill_to_zipcode;
            lv_bill_cust_site_use_rec_type.location      := stg_tbl_rec_odn.bill_to_cnsgno; -- BILL_TO LOCATION CODE
            bill_person_record_rec_type.person_last_name := stg_tbl_rec_odn.bill_to_contact_name;
            lv_bill_email_rec_type.email_address         := stg_tbl_rec_odn.bill_to_contact_email;
            lv_bill_phone_rec_type.phone_number          := stg_tbl_rec_odn.bill_to_contact_phone;
            lc_bill_to_consg_no                          := lv_bill_cust_site_use_rec_type.location ;
            /*BEGIN
            /*SELECT COUNT(1)
            INTO ln_billto_count
            FROM hz_cust_site_uses_all HCSU
            WHERE EXISTS
            (SELECT 1
            FROM hz_cust_acct_sites_all HCAS
            WHERE HCAS.cust_account_id = NVL(ln_cust_account_id,ln_custacct_id)
            AND HCAS.status            = 'A'
            --AND HCAS.BILL_TO_FLAG      = 'Y'
            --AND HCAS.BILL_TO_FLAG     IN ('P','Y')
            AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
            )
            AND HCSU.STATUS            = 'A'
            AND HCSU.location          = lc_bill_to_consg_no
            AND HCSU.site_use_code     = 'BILL_TO';
            IF (ln_billto_count > 0 ) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill to Location '||lc_bill_to_consg_no||' already exists' );
            END IF;
            EXCEPTION
            WHEN OTHERS THEN
            ln_billto_count := 0;
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill to Location does not exist and it is a new location' );
            END;*/
            --IF (ln_billto_count                       = 0) THEN
            lv_bill_location_rec_type.county            := 'DEFAULT';
            lv_bill_location_rec_type.country           := 'US';
            lv_bill_location_rec_type.created_by_module := 'TCA_V2_API';
            hz_location_v2pub.create_location (p_init_msg_list => lc_init_msg_list ,p_location_rec => lv_bill_location_rec_type ,x_location_id => ln_bill_to_location_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create_Location_Bill_To, lc_return_status: ' || lc_return_status || ', ln_bill_to_location_id: ' || ln_bill_to_location_id);
            --If API fails
            IF lc_return_status <> 'S' THEN
              --lc_error_flag     :='Y';
              FOR i IN 1 .. ln_msg_count
              LOOP
                fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
              END LOOP;
              lc_output := lc_output||'- Error while creating Location for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO Create_Location_Bill_To, lc_err_msg: ' || lc_err_msg,lc_return_status);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create_Location_Bill_To, Error mesg: ' || lc_output);
              x_ret_code      := 1;
              ln_billto_count := 0;
            ELSE
              FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO Create Location ln_bill_to_location_id: ' || ln_bill_to_location_id);
              FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create Location FOR LOCATION: '||lv_bill_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
              --END IF;
              lc_bill_to_consg_no_dup := stg_tbl_rec_odn.bill_to_cnsgno;
              ln_billto_count         := 1;
              ---------------------------------------------------------------
              --Create Party Site BILL TO
              ---------------------------------------------------------------
              lv_bill_party_site_rec_type.identifying_address_flag := 'Y';
              lv_bill_party_site_rec_type.status                   := 'A';
              lv_bill_party_site_rec_type.party_id                 := NVL(ln_new_party_id,ln_party_id);
              lv_bill_party_site_rec_type.location_id              := ln_bill_to_location_id;
              lv_bill_party_site_rec_type.created_by_module        := 'TCA_V2_API';
              hz_party_site_v2pub.create_party_site (p_init_msg_list => lc_init_msg_list ,p_party_site_rec => lv_bill_party_site_rec_type ,x_party_site_id => ln_bill_to_party_site_id ,x_party_site_number => lc_bill_to_party_site_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO Create_Party_Site, lc_return_status: ' || lc_return_status || ', ln_bill_to_party_site_id: ' || ln_bill_to_party_site_id,SQLERRM);
              --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create_Party_Site, lc_return_status: ' || lc_return_status || ', ln_bill_to_party_site_id: ' || ln_bill_to_party_site_id);
              --If API fails
              IF lc_return_status <> 'S' THEN
                --lc_error_flag     :='Y';
                FOR i IN 1 .. ln_msg_count
                LOOP
                  fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                  lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                END LOOP;
                lc_output := lc_output||'- Error while creating party site for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO Create_party_site, lc_err_msg: ' || lc_err_msg,lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create_party_site, Error mesg: ' || lc_output);
                x_ret_code      := 1;
                ln_billto_count := 0;
              ELSE
                FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO Create Party Site , ln_bill_to_party_site_id: ' || ln_bill_to_party_site_id);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create Party Site CREATED FOR LOCATION: '||lv_bill_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                -- END IF;
                ----------------------------------------------------------------
                -- Create Cust Acct Site BILL TO
                ----------------------------------------------------------------
                lv_bill_custacctsite_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); -- ln_cust_account_id
                lv_bill_custacctsite_rec_type.party_site_id     := ln_bill_to_party_site_id;
                lv_bill_custacctsite_rec_type.created_by_module :='TCA_V2_API';
                ln_billto_count                                 := 1;
                --lv_bill_custacctsite_rec_type.orig_system_reference := stg_tbl_rec_odn.odn_cust_num || '-CONV' ; Commented by Punit on 21-DEC-2017
                hz_cust_account_site_v2pub.create_cust_acct_site (lc_init_msg_list ,lv_bill_custacctsite_rec_type ,ln_bill_cust_acct_site_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO create_cust_acct_site, lc_return_status: ' || lc_return_status || ', ln_bill_cust_acct_site_id: ' || ln_bill_cust_acct_site_id,lc_return_status);
                --FND_FILE.PUT_LINE(FND_FILE.LOG, 'After BILL_TO create_cust_acct_site, lc_return_status: ' || lc_return_status || ', ln_bill_cust_acct_site_id: ' || ln_bill_cust_acct_site_id);
                --If API fails
                IF lc_return_status <> 'S' THEN
                  -- lc_error_flag     :='Y';
                  FOR i IN 1 .. ln_msg_count
                  LOOP
                    fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                    lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                  END LOOP;
                  lc_output := lc_output||'- Error while creating cust acct site for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO create_cust_acct_site, lc_err_msg: ' || lc_err_msg,lc_return_status);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_cust_acct_site, Error mesg: ' || lc_output);
                  x_ret_code      := 1;
                  ln_billto_count := 0;
                ELSE
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO Create create_cust_acct_site ln_bill_cust_acct_site_id: ' || ln_bill_cust_acct_site_id);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create create_cust_acct_site CREATED FOR LOCATION: '||lv_bill_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                  --END IF;
                  -------------------------------------------------------------------
                  --Create party site use BILL TO
                  -------------------------------------------------------------------
                  ln_billto_count                                 := 1;
                  lv_bill_partysiteuse_rec_type.site_use_type     := 'BILL_TO';
                  lv_bill_partysiteuse_rec_type.primary_per_type  := 'Y';
                  lv_bill_partysiteuse_rec_type.party_site_id     := ln_bill_to_party_site_id;
                  lv_bill_partysiteuse_rec_type.status            := 'A';
                  lv_bill_partysiteuse_rec_type.created_by_module :='TCA_V2_API';
                  hz_party_site_v2pub.create_party_site_use (p_init_msg_list => lc_init_msg_list ,p_party_site_use_rec => lv_bill_partysiteuse_rec_type ,x_party_site_use_id => ln_bill_party_site_use_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO create_party_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_party_site_use_id: ' || ln_bill_party_site_use_id,lc_return_status);
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_party_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_party_site_use_id: ' || ln_bill_party_site_use_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    --lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating party site use for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO create_party_site_use , lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_party_site_use , Error mesg: ' || lc_output);
                    x_ret_code      := 1;
                    ln_billto_count := 0;
                  ELSE
                    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL TO Create create_party_site_use ln_bill_party_site_use_id:: ' || ln_bill_party_site_use_id);
                    --END IF;
                    ln_billto_count := 1;
                    ---------------------------------------------------------------------------
                    -- Create Cust Account site use BILL TO
                    ---------------------------------------------------------------------------
                    lv_bill_cust_site_use_rec_type.cust_acct_site_id := ln_bill_cust_acct_site_id;
                    lv_bill_cust_site_use_rec_type.site_use_code     := 'BILL_TO';
                    lv_bill_cust_site_use_rec_type.primary_flag      := 'Y';
                    lv_bill_cust_site_use_rec_type.status            := 'A';
                    lv_bill_cust_site_use_rec_type.created_by_module :='TCA_V2_API';
                    --SELECT hz_cust_site_uses_s.nextval into p_location from dual;
                    hz_cust_account_site_v2pub.create_cust_site_use ('T' ,lv_bill_cust_site_use_rec_type ,NULL ,'F' ,'F' ,ln_bill_site_use_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO create_cust_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_site_use_id: ' || ln_bill_site_use_id,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_cust_site_use, lc_return_status: ' || lc_return_status || ', ln_bill_site_use_id: ' || ln_bill_site_use_id);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_cust_site_use CREATED FOR LOCATION: '||lv_bill_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      -- lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating cust site use for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO create_cust_site_use, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_cust_site_use, Error mesg: ' || lc_output);
                      x_ret_code      := 1;
                      ln_billto_count := 0;
                    ELSE
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO create_cust_site_use ln_bill_site_use_id: ' || ln_bill_site_use_id);
                      --lc_default_billto := 'Y';
                      ----FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of lc_default_billto: ' || lc_default_billto);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL TO LOCATION AND PARTY SITE CREATED FOR LOCATION: '||lv_bill_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                      ln_billto_count := 1;
                    END IF;
                  END IF; -- lc_return_status <> 'S' for create_party_site_use BILL_TO
                END IF;   -- lc_return_status <> 'S' for create_cust_acct_site BILL_TO
              END IF;     -- lc_return_status <> 'S' for create_party_site BILL_TO
              --END IF;  -- lc_return_status <> 'S' for create_location BILL_TO
              ----------------------------------------------------------------------
              -- Create person, Create Org Contact Point for BILL TO
              ----------------------------------------------------------------------
              IF lc_return_status                                 = 'S' THEN --- Added by Punit on 21-FEB-2018
                IF bill_person_record_rec_type.person_last_name  IS NOT NULL THEN
                  bill_person_record_rec_type.person_first_name  := fnd_api.g_miss_char;
                  bill_person_record_rec_type.person_middle_name := fnd_api.g_miss_char;
                  bill_person_record_rec_type.person_name_suffix := fnd_api.g_miss_char;
                  bill_person_record_rec_type.created_by_module  := 'TCA_V2_API';
                  hz_party_v2pub.create_person (p_init_msg_list => lc_init_msg_list ,p_person_rec => bill_person_record_rec_type ,x_party_id => ln_bill_party_id ,x_party_number => lc_bill_party_number ,x_profile_id => ln_bill_profile_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_person, lc_return_status: ' || lc_return_status || ', ln_bill_party_id: ' || ln_bill_party_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating person for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO create_person, lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_person, Error mesg: ' || lc_output);
                    x_ret_code := 1;
                  ELSE
                    -- FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO create_person , ln_bill_party_id: ' || ln_bill_party_id);
                    --END IF;
                    --Link person to organization
                    bill_contact_rec_type.job_title_code                   := NULL;
                    bill_contact_rec_type.job_title                        := 'AP'; --Changed by Punit on 09-FEB-2018   --NULL;
                    bill_contact_rec_type.created_by_module                := 'TCA_V2_API';
                    bill_contact_rec_type.party_rel_rec.subject_id         := ln_bill_party_id;
                    bill_contact_rec_type.party_rel_rec.subject_type       := 'PERSON';
                    bill_contact_rec_type.party_rel_rec.subject_table_name := 'HZ_PARTIES';
                    bill_contact_rec_type.party_rel_rec.object_id          := NVL(ln_new_party_id,ln_party_id);
                    bill_contact_rec_type.party_rel_rec.object_type        := 'ORGANIZATION';
                    bill_contact_rec_type.party_rel_rec.object_table_name  := 'HZ_PARTIES';
                    bill_contact_rec_type.party_rel_rec.relationship_code  := 'CONTACT_OF';
                    bill_contact_rec_type.party_rel_rec.relationship_type  := 'CONTACT';
                    bill_contact_rec_type.party_rel_rec.start_date         := SYSDATE;
                    hz_party_contact_v2pub.create_org_contact (p_init_msg_list => lc_init_msg_list ,p_org_contact_rec => bill_contact_rec_type ,x_org_contact_id => ln_bill_contact_id ,x_party_rel_id => ln_bill_party_rel_id ,x_party_id => ln_borg_party_id ,x_party_number => lc_borg_party_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                    --If API fails
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_org_contact , lc_return_status: ' || lc_return_status || ', ln_bill_contact_id: ' || ln_bill_contact_id);
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating org contact for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO create_org_contact, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_org_contact, Error mesg: ' || lc_output);
                      x_ret_code := 1;
                    ELSE
                      -- FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO create_org_contact ln_bill_contact_id: ' || ln_bill_contact_id);
                      --END IF;
                      -- Bill to Org Contact point
                      IF (stg_tbl_rec_odn.bill_to_contact_email           IS NOT NULL OR stg_tbl_rec_odn.bill_to_contact_phone IS NOT NULL) THEN
                        lv_bill_contact_point_rec_type.contact_point_type := 'PHONE';
                        lv_bill_contact_point_rec_type.owner_table_name   := 'HZ_PARTIES';
                        lv_bill_contact_point_rec_type.owner_table_id     := ln_borg_party_id;
                        --  lv_bill_contact_point_rec_type.primary_flag          := 'Y';
                        lv_bill_contact_point_rec_type.contact_point_purpose := 'BUSINESS';
                        lv_bill_contact_point_rec_type.created_by_module     := 'TCA_V2_API';
                        lv_bill_email_rec_type.email_format                  := 'MAILHTML';
                        lv_bill_phone_rec_type.phone_line_type               :='GEN';
                        --   l_phone_rec.phone_extension                  := stg_tbl_rec_odn.phone_extension;
                        lc_return_status := NULL;
                        ln_msg_count     := NULL;
                        lc_msg_data      := NULL;
                        HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT (p_init_msg_list => 'T', p_contact_point_rec => lv_bill_contact_point_rec_type, p_edi_rec => NULL, p_email_rec => lv_bill_email_rec_type, p_phone_rec => lv_bill_phone_rec_type, p_telex_rec => NULL, p_web_rec => NULL, x_contact_point_id => ln_bill_contact_point_id , x_return_status => lc_return_status, x_msg_count => ln_msg_count, x_msg_data => lc_msg_data );
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO CREATE_CONTACT_POINT, l_return_status: ' || lc_return_status || ', ln_bill_contact_point_id : ' || ln_bill_contact_point_id,lc_return_status);
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO CREATE_CONTACT_POINT, l_return_status: ' || lc_return_status || ', ln_bill_contact_point_id : ' || ln_bill_contact_point_id);
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          lc_output := lc_output||'- Error while creating contact point for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO CREATE_CONTACT_POINT, lc_err_msg: ' || lc_err_msg,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO CREATE_CONTACT_POINT, Error mesg: ' || lc_output);
                          x_ret_code := 1;
                        ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO CREATE_CONTACT_POINT ln_bill_contact_point_id : ' || ln_bill_contact_point_id );
                        END IF;
                      END IF; -- stg_tbl_rec_odn.bill_to_contact_email IS NOT NULL OR stg_tbl_rec_odn.bill_to_contact_phone IS NOT NULL
                      -- Link organization to customer account
                      lv_bill_acct_role_rec_type.created_by_module := 'TCA_V2_API';
                      lv_bill_acct_role_rec_type.party_id          := ln_borg_party_id;                       --Party id from org contact
                      lv_bill_acct_role_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); --ln_cust_account_id; -- value of cust_account_id from step 1
                      lv_bill_acct_role_rec_type.cust_acct_site_id := ln_bill_cust_acct_site_id;
                      lv_bill_acct_role_rec_type.role_type         := 'CONTACT';
                      lv_bill_acct_role_rec_type.status            := 'A';
                      HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(p_init_msg_list => 'T' , p_cust_account_role_rec => lv_bill_acct_role_rec_type, x_cust_account_role_id=> ln_bill_acct_role_id, x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data);
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After BILL_TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_bill_acct_role_id : ' || ln_bill_acct_role_id,lc_return_status);
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_bill_acct_role_id : ' || ln_bill_acct_role_id);
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating cust account role for BILL_TO Location: '||stg_tbl_rec_odn.bill_to_cnsgno;
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL_TO Create_cust_account_role, lc_err_msg: ' || lc_err_msg,lc_return_status);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO Create_cust_account_role, Error mesg: ' || lc_output);
                        x_ret_code := 1;
                      ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'AFTER BILL_TO Create Cust Account role ln_bill_acct_role_id : ' || ln_bill_acct_role_id );
                        -- Added by Punit on 16-MAR-2018 for the issue "Unable to see contacts of converted customers in Web Collect extract"
                        -- Role Responsibility Bill to
                        lv_bill_role_resp_rec_type.created_by_module   := 'TCA_V2_API';
                        lv_bill_role_resp_rec_type.cust_account_role_id:=ln_bill_acct_role_id;
                        lv_bill_role_resp_rec_type.primary_flag        :='Y';
                        lv_bill_role_resp_rec_type.responsibility_type := 'DUN';
                        HZ_CUST_ACCOUNT_ROLE_V2PUB.create_role_responsibility(p_init_msg_list => 'T' , p_role_responsibility_rec => lv_bill_role_resp_rec_type, x_responsibility_id => ln_responsibility_id, x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data);
                        --  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers',
                        -- 'After BILL TO create_role_responsibility, l_return_status: ' || lc_return_status || ', ln_responsibility_id : ' || ln_responsibility_id,lc_return_status);
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_role_responsibility, l_return_status: ' || lc_return_status || ', ln_responsibility_id : ' || ln_responsibility_id);
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          ----log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After BILL TO create_role_responsibility, lc_err_msg: ' || lc_err_msg,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After BILL_TO create_role_responsibility, Error mesg: ' || lc_output);
                        ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'BILL_TO Create Cust Account Responsibility role ln_responsibility_id : ' || ln_responsibility_id );
                        END IF;
                      END IF; ---lc_return_status <> 'S' create_cust_account_role BILL_TO
                    END IF;    --lc_return_status <> 'S' create_org_contact BILL_TO
                  END IF;      -- lc_return_status <> 'S' create_person BILL_TO
                END IF ;       -- stg_tbl_rec_odn.bill_to_contact_name IS NOT NULL  BILL_TO
              END IF;          -- lc_return_status = 'S' --- Added by Punit on 21-FEB-2018
            END IF;            -- lc_return_status <> 'S' for create_location BILL_TO
            --END IF;         --ln_billto_count = 0
          ELSE
            lc_bill_to_consg_no := NULL;
            --lc_bill_to_consg_no_dup := NULL;  -- Commented by Punit on 20-FEB-2018
          END IF; --- stg_tbl_rec_odn.bill_to_cnsgno IS NOT NULL  --AND lc_default_billto = 'Y'
          ----------------------------------------------------------------
          --Create Location  SHIP TO
          -----------------------------------------------------------------
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' value of lc_ship_to_consg_no_dup is : '||lc_ship_to_consg_no_dup);
          FND_FILE.PUT_LINE(FND_FILE.LOG, ' value of stg_tbl_rec_odn.ship_to_cnsgno is : '||stg_tbl_rec_odn.ship_to_cnsgno);
          IF (stg_tbl_rec_odn.ship_to_cnsgno         IS NOT NULL AND ln_new_party_created = 'Y' AND (stg_tbl_rec_odn.ship_to_cnsgno <> lc_ship_to_consg_no_dup OR lc_ship_to_consg_no_dup IS NULL) AND stg_tbl_rec_odn.ship_to_rpt_flg = 'N' ) THEN --- AND lc_default_shipto = 'Y'
            lv_ship_location_rec_type.address1       := stg_tbl_rec_odn.ship_to_address1;
            lv_ship_location_rec_type.address2       := stg_tbl_rec_odn.ship_to_address2;
            lv_ship_location_rec_type.address3       := '';
            lv_ship_location_rec_type.city           := stg_tbl_rec_odn.ship_to_city;
            lv_ship_location_rec_type.state          := stg_tbl_rec_odn.ship_to_state;
            lv_ship_location_rec_type.postal_code    := stg_tbl_rec_odn.ship_to_zipcode;
            lv_ship_cust_site_use_rec_type.location  := stg_tbl_rec_odn.ship_to_cnsgno; -- BILL_TO LOCATION CODE
            lv_ship_person_rec_type.person_last_name := stg_tbl_rec_odn.ship_to_contact_name;
            lv_ship_email_rec_type.email_address     := stg_tbl_rec_odn.ship_to_contact_email;
            lv_ship_phone_rec_type.phone_number      := stg_tbl_rec_odn.ship_to_contact_phone;
            lc_ship_to_consg_no                      := lv_ship_cust_site_use_rec_type.location;
            /*BEGIN
            SELECT COUNT(1)
            INTO ln_shipto_count
            FROM hz_cust_site_uses_all HCSU
            WHERE EXISTS
            (SELECT 1
            FROM hz_cust_acct_sites_all HCAS
            WHERE HCAS.cust_account_id = NVL(ln_cust_account_id,ln_custacct_id)
            AND HCAS.status            = 'A'
            --AND HCAS.SHIP_TO_FLAG      = 'Y'
            --AND HCAS.SHIP_TO_FLAG     IN ('P','Y')
            AND HCAS.cust_acct_site_id = HCSU.cust_acct_site_id
            )
            AND HCSU.STATUS            = 'A'
            AND HCSU.site_use_code     = 'SHIP_TO'
            AND HCSU.location          = lc_ship_to_consg_no;
            IF (ln_shipto_count > 0 ) THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Ship to Location '||lc_ship_to_consg_no||' already exists for the customer account' );
            END IF;
            EXCEPTION
            WHEN OTHERS THEN
            ln_shipto_count := 0;
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Ship to Location does not exist and it is a new location' );
            END; */
            --IF (ln_shipto_count = 0) THEN
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside ln_shipto_count = 0 ' );
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Bill to Location is: '||lc_bill_to_consg_no);
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Ship to Location is: '||lc_ship_to_consg_no);
            IF (((lc_ship_to_consg_no <> lc_bill_to_consg_no) OR (lc_bill_to_consg_no IS NULL)) AND (lc_ship_to_consg_no IS NOT NULL)) THEN
              --FND_FILE.PUT_LINE(FND_FILE.LOG,'Inside lc_ship_to_consg_no <> lc_bill_to_consg_no' );
              --lv_ship_location_rec_type.description := stg_tbl_rec_odn.shp_to_cnsgno
              lv_ship_location_rec_type.county            := 'DEFAULT';
              lv_ship_location_rec_type.country           := 'US';
              lv_ship_location_rec_type.created_by_module := 'TCA_V2_API';
              hz_location_v2pub.create_location (p_init_msg_list => lc_init_msg_list ,p_location_rec => lv_ship_location_rec_type ,x_location_id => ln_ship_to_location_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After Create_Location_SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_to_location_id: ' || ln_ship_to_location_id,lc_return_status);
              --FND_FILE.PUT_LINE(FND_FILE.LOG, 'After Create_Location_SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_to_location_id: ' || ln_ship_to_location_id);
              --If API fails
              IF lc_return_status <> 'S' THEN
                lc_error_flag     :='Y';
                FOR i IN 1 .. ln_msg_count
                LOOP
                  fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                  lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                END LOOP;
                lc_output := lc_output||'- Error while creating Location for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After Create_Location_SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'After Create_Location_SHIP_TO, Error mesg: ' || lc_output);
                x_ret_code := 1;
              ELSE
                --FND_FILE.PUT_LINE(FND_FILE.LOG,'Create create_location ln_ship_to_location_id: ' || ln_ship_to_location_id);
                ---END IF;
                lc_ship_to_consg_no_dup := stg_tbl_rec_odn.ship_to_cnsgno;
                ---------------------------------------------------------------
                --Create Party Site SHIP_TO
                ---------------------------------------------------------------
                lv_ship_party_site_rec_type.identifying_address_flag := 'Y';
                lv_ship_party_site_rec_type.status                   := 'A';
                lv_ship_party_site_rec_type.party_id                 := NVL(ln_new_party_id,ln_party_id);
                lv_ship_party_site_rec_type.location_id              := ln_ship_to_location_id;
                lv_ship_party_site_rec_type.created_by_module        := 'TCA_V2_API';
                hz_party_site_v2pub.create_party_site (p_init_msg_list => lc_init_msg_list ,p_party_site_rec => lv_ship_party_site_rec_type ,x_party_site_id => ln_ship_to_party_site_id ,x_party_site_number => lc_ship_to_party_site_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After Create_Party_Site SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_to_party_site_id: ' || ln_ship_to_party_site_id,lc_return_status);
                --FND_FILE.PUT_LINE(FND_FILE.LOG, 'After Create_Party_Site SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_to_party_site_id: ' || ln_ship_to_party_site_id);
                --If API fails
                IF lc_return_status <> 'S' THEN
                  lc_error_flag     :='Y';
                  FOR i IN 1 .. ln_msg_count
                  LOOP
                    fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                    lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                  END LOOP;
                  lc_output := lc_output||'- Error while creating party site for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After Create_party_site_Ship_to, lc_err_msg: ' || lc_err_msg,lc_return_status);
                  FND_FILE.PUT_LINE(FND_FILE.LOG,'After Create_party_site_Ship_to, Error mesg: ' || lc_output);
                  x_ret_code := 1;
                ELSE
                  -- FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO Create create_party_site ln_ship_to_party_site_id: ' || ln_ship_to_party_site_id);
                  --END IF;
                  ----------------------------------------------------------------
                  -- Create Cust Acct Site SHIP_TO
                  ----------------------------------------------------------------
                  lv_ship_custacctsite_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); --ln_cust_account_id;
                  lv_ship_custacctsite_rec_type.party_site_id     := ln_ship_to_party_site_id;
                  lv_ship_custacctsite_rec_type.created_by_module :='TCA_V2_API';
                  --lv_ship_custacctsite_rec_type.orig_system_reference := stg_tbl_rec_odn.odn_cust_num || '-CONV' ; Commented by Punit on 21-DEC-2017
                  hz_cust_account_site_v2pub.create_cust_acct_site (lc_init_msg_list ,lv_ship_custacctsite_rec_type ,ln_ship_cust_acct_site_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After create_cust_acct_site, lc_return_status: ' || lc_return_status || ', ln_ship_cust_acct_site_id: ' || ln_ship_cust_acct_site_id,lc_return_status);
                  --FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_cust_acct_site SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_cust_acct_site_id: ' || ln_ship_cust_acct_site_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating cust acct site for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_cust_acct_site SHIP_TO , lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_cust_acct_site SHIP_TO , Error mesg: ' || lc_output);
                    x_ret_code := 1;
                  ELSE
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO create_cust_acct_site ln_ship_cust_acct_site_id: ' || ln_ship_cust_acct_site_id);
                    --END IF;
                    ------------------------------------------------------------------
                    --Create party site use SHIP TO
                    -------------------------------------------------------------------
                    lv_ship_partysiteuse_rec_type.site_use_type     := 'SHIP_TO';
                    lv_ship_partysiteuse_rec_type.primary_per_type  := 'Y';
                    lv_ship_partysiteuse_rec_type.party_site_id     := ln_ship_to_party_site_id ;
                    lv_ship_partysiteuse_rec_type.status            := 'A';
                    lv_ship_partysiteuse_rec_type.created_by_module :='TCA_V2_API';
                    hz_party_site_v2pub.create_party_site_use (p_init_msg_list => lc_init_msg_list ,p_party_site_use_rec => lv_ship_partysiteuse_rec_type ,x_party_site_use_id => ln_ship_party_site_use_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After create_party_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id,lc_return_status);
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_party_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating party site use for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_party_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,' After create_party_site_use SHIP_TO, Error mesg: ' || lc_output);
                      x_ret_code := 1;
                    ELSE
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Create create_party_site_use ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                      -- END IF;
                      ---------------------------------------------------------------------------
                      -- Create Cust site use SHIP TO
                      ---------------------------------------------------------------------------
                      lv_ship_cust_site_use_rec_type.cust_acct_site_id := ln_ship_cust_acct_site_id;
                      lv_ship_cust_site_use_rec_type.site_use_code     := 'SHIP_TO';
                      lv_ship_cust_site_use_rec_type.primary_flag      := 'Y';
                      lv_ship_cust_site_use_rec_type.status            := 'A';
                      lv_ship_cust_site_use_rec_type.created_by_module :='TCA_V2_API';
                      hz_cust_account_site_v2pub.create_cust_site_use ('T' ,lv_ship_cust_site_use_rec_type ,NULL ,'F' ,'F' ,ln_ship_site_use_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id,lc_return_status);
                      --FND_FILE.PUT_LINE(FND_FILE.LOG, 'After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id);
                      --If API fails
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating cust acct site use for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_cust_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_cust_site_use SHIP_TO, Error mesg: ' || lc_output);
                        x_ret_code := 1;
                      ELSE
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO create_cust_site_use ln_ship_site_use_id: ' || ln_ship_site_use_id);
                        --lc_default_shipto := 'Y';
                        ----FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of lc_default_shipto: ' || lc_default_shipto);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO LOCATION AND PARTY SITE CREATED FOR LOCATION: '||lv_ship_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                      END IF;
                    END IF; -- lc_return_status <> 'S' for create_party_site_use SHIP_TO
                  END IF;   -- lc_return_status <> 'S' for create_cust_acct_site SHIP_TO
                END IF;     -- lc_return_status <> 'S' for create_party_site SHIP_TO
                --END IF;  -- lc_return_status <> 'S' for create_location SHIP_TO
                ----------------------------------------------------------------------
                -- SHIP TO Create person, Create Org Contact Point
                ----------------------------------------------------------------------
                IF lc_return_status                             = 'S' THEN --- Added by Punit on 21-FEB-2018
                  IF lv_ship_person_rec_type.person_last_name  IS NOT NULL THEN
                    lv_ship_person_rec_type.person_first_name  := fnd_api.g_miss_char;
                    lv_ship_person_rec_type.person_middle_name := fnd_api.g_miss_char;
                    lv_ship_person_rec_type.person_name_suffix := fnd_api.g_miss_char;
                    lv_ship_person_rec_type.created_by_module  := 'TCA_V2_API';
                    hz_party_v2pub.create_person (p_init_msg_list => lc_init_msg_list ,p_person_rec => lv_ship_person_rec_type ,x_party_id => ln_ship_party_id ,x_party_number => lc_ship_party_number ,x_profile_id => ln_ship_profile_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating person for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_person SHIP TO Contact, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_person SHIP TO Contact, Error mesg: ' || lc_output);
                      x_ret_code := 1;
                    ELSE
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Contact create_person SHIP TO Contact  ln_ship_party_id: ' || ln_ship_party_id);
                      ---END IF;
                      --Link person to organization
                      lv_ship_contact_rec_type.job_title_code                   := NULL;
                      lv_ship_contact_rec_type.job_title                        := NULL;
                      lv_ship_contact_rec_type.created_by_module                := 'TCA_V2_API';
                      lv_ship_contact_rec_type.party_rel_rec.subject_id         := ln_ship_party_id;
                      lv_ship_contact_rec_type.party_rel_rec.subject_type       := 'PERSON';
                      lv_ship_contact_rec_type.party_rel_rec.subject_table_name := 'HZ_PARTIES';
                      lv_ship_contact_rec_type.party_rel_rec.object_id          := NVL(ln_new_party_id,ln_party_id);
                      lv_ship_contact_rec_type.party_rel_rec.object_type        := 'ORGANIZATION';
                      lv_ship_contact_rec_type.party_rel_rec.object_table_name  := 'HZ_PARTIES';
                      lv_ship_contact_rec_type.party_rel_rec.relationship_code  := 'CONTACT_OF';
                      lv_ship_contact_rec_type.party_rel_rec.relationship_type  := 'CONTACT';
                      lv_ship_contact_rec_type.party_rel_rec.start_date         := SYSDATE;
                      hz_party_contact_v2pub.create_org_contact (p_init_msg_list => lc_init_msg_list ,p_org_contact_rec => lv_ship_contact_rec_type ,x_org_contact_id => ln_ship_contact_id ,x_party_rel_id => ln_ship_party_rel_id ,x_party_id => ln_sorg_party_id ,x_party_number => lc_sorg_party_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                      --If API fails
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating org contact for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_org_contact SHIP_TO , lc_err_msg: ' || lc_err_msg,lc_return_status);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_org_contact SHIP_TO, Error mesg: ' || lc_output);
                      ELSE
                        -- FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP To Org Contact create_org_contact ln_ship_contact_id: ' || ln_ship_contact_id);
                        --END IF;
                        -- SHIP to Org Contact point
                        IF (stg_tbl_rec_odn.ship_to_contact_email           IS NOT NULL OR stg_tbl_rec_odn.ship_to_contact_phone IS NOT NULL ) THEN
                          lv_ship_contact_point_rec_type.contact_point_type := 'PHONE';
                          lv_ship_contact_point_rec_type.owner_table_name   := 'HZ_PARTIES';
                          lv_ship_contact_point_rec_type.owner_table_id     := ln_sorg_party_id;
                          --  lv_bill_contact_point_rec_type.primary_flag          := 'Y';
                          lv_ship_contact_point_rec_type.contact_point_purpose := 'BUSINESS';
                          lv_ship_contact_point_rec_type.created_by_module     := 'TCA_V2_API';
                          lv_ship_email_rec_type.email_format                  := 'MAILHTML';
                          lv_ship_phone_rec_type.phone_line_type               :='GEN';
                          --   l_phone_rec.phone_extension                  := stg_tbl_rec_odn.phone_extension;
                          lc_return_status := NULL;
                          ln_msg_count     := NULL;
                          lc_msg_data      := NULL;
                          HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT (p_init_msg_list => 'T', p_contact_point_rec => lv_ship_contact_point_rec_type, p_edi_rec => NULL, p_email_rec => lv_ship_email_rec_type, p_phone_rec => lv_ship_phone_rec_type, p_telex_rec => NULL, p_web_rec => NULL, x_contact_point_id => ln_ship_contact_point_id , x_return_status => lc_return_status, x_msg_count => ln_msg_count, x_msg_data => lc_msg_data );
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG CREATE_CONTACT_POINT SHIP_TO, l_return_status: ' || lc_return_status || ', ln_ship_contact_point_id : ' || ln_ship_contact_point_id,lc_return_status );
                          --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG CREATE_CONTACT_POINT SHIP_TO, l_return_status: ' || lc_return_status || ', ln_ship_contact_point_id : ' || ln_ship_contact_point_id);
                          IF lc_return_status <> 'S' THEN
                            lc_error_flag     :='Y';
                            FOR i IN 1 .. ln_msg_count
                            LOOP
                              fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                              lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                            END LOOP;
                            lc_output := lc_output||'- Error while creating contact point for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                            --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After CREATE_CONTACT_POINT SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'After CREATE_CONTACT_POINT SHIP_TO, Error mesg: ' || lc_output);
                            x_ret_code := 1;
                          ELSE
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_CONTACT_POINT SHIP_TO ln_ship_contact_point_id : ' || ln_ship_contact_point_id );
                          END IF;
                        END IF; -- stg_tbl_rec_odn.ship_to_contact_email IS NOT NULL OR stg_tbl_rec_odn.ship_to_contact_phone IS NOT NULL
                        -- Link organization to customer account
                        lv_ship_acct_role_rec_type.created_by_module := 'TCA_V2_API';
                        lv_ship_acct_role_rec_type.party_id          := ln_sorg_party_id;                       --Party id from org contact
                        lv_ship_acct_role_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); -- ln_cust_account_id; -- value of cust_account_id from step 1
                        lv_ship_acct_role_rec_type.cust_acct_site_id := ln_ship_cust_acct_site_id;
                        lv_ship_acct_role_rec_type.role_type         := 'CONTACT';
                        lv_ship_acct_role_rec_type.status            := 'A';
                        HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(p_init_msg_list => 'T' , p_cust_account_role_rec => lv_ship_acct_role_rec_type, x_cust_account_role_id=> ln_ship_acct_role_id, x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data);
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After SHIP TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_ship_acct_role_id : ' || ln_ship_acct_role_id,lc_return_status );
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After SHIP TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_ship_acct_role_id : ' || ln_ship_acct_role_id);
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          lc_output := lc_output||'- Error while creating cust account role for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After SHIP_TO Create_cust_account_role, lc_err_msg: ' || lc_err_msg,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After SHIP_TO Create_cust_account_role,Error mesg: ' || lc_output);
                          x_ret_code := 1;
                        ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP_TO Create Cust Account role ln_bill_acct_role_id : ' || ln_ship_acct_role_id );
                        END IF;
                      END IF; --lc_return_status <> 'S' create_org_contact SHIP_TO
                    END IF;   -- lc_return_status <> 'S' create_person  SHIP_TO
                  END IF;     -- lv_ship_person_rec_type.person_last_name IS NOT NULL
                END IF;       -- lc_return_status = 'S' --- Added by Punit on 21-FEB-2018
              END IF;         -- lc_return_status <> 'S' for create_location SHIP_TO
            ELSE              -- lc_ship_to_consg_no <> lc_bill_to_consg_no
              IF (lc_ship_to_consg_no    = lc_bill_to_consg_no AND lc_ship_to_consg_no IS NOT NULL AND lc_bill_to_consg_no IS NOT NULL AND stg_tbl_rec_odn.bill_to_rpt_flg = 'N' AND stg_tbl_rec_odn.ship_to_rpt_flg = 'N' ) THEN
                lc_ship_to_consg_no_dup := stg_tbl_rec_odn.bill_to_cnsgno;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of ln_billto_count is : '|| ln_billto_count);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of lc_ship_to_consg_no_dup under same Location Name is : '|| lc_ship_to_consg_no_dup);
                --- Added by Punit on 20-FEB-2018
                IF ln_billto_count = 1 THEN
                  -------------------------------------------------------------------------------------
                  --Create party site use SHIP TO  where Location name is same for both BILL_TO AND SHIP_TO
                  --------------------------------------------------------------------------------------
                  IF (ln_bill_to_party_site_id                      IS NOT NULL) THEN
                    lv_ship_partysiteuse_rec_type.site_use_type     := 'SHIP_TO';
                    lv_ship_partysiteuse_rec_type.primary_per_type  := 'Y';
                    lv_ship_partysiteuse_rec_type.party_site_id     := ln_bill_to_party_site_id;
                    lv_ship_partysiteuse_rec_type.status            := 'A';
                    lv_ship_partysiteuse_rec_type.created_by_module :='TCA_V2_API';
                    hz_party_site_v2pub.create_party_site_use (p_init_msg_list => lc_init_msg_list ,p_party_site_use_rec => lv_ship_partysiteuse_rec_type ,x_party_site_use_id => ln_ship_party_site_use_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'Similar LOCATIONS- After create_party_site_use SHIP_TO , lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id,lc_return_status);
                    --FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS- After create_party_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating party site use  for Similar SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Similar LOCATIONS- After create_party_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,' Similar LOCATIONS- After create_party_site_use SHIP_TO, Error mesg: ' || lc_output);
                      x_ret_code := 1;
                    ELSE
                      --FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS- Create create_party_site_use ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                      --END IF;
                      ---------------------------------------------------------------------------
                      -- Create Cust Account site use SHIP TO
                      ---------------------------------------------------------------------------
                      lv_ship_cust_site_use_rec_type.cust_acct_site_id := ln_bill_cust_acct_site_id; --ln_ship_cust_acct_site_id;
                      lv_ship_cust_site_use_rec_type.site_use_code     := 'SHIP_TO';
                      lv_ship_cust_site_use_rec_type.primary_flag      := 'Y';
                      lv_ship_cust_site_use_rec_type.status            := 'A';
                      lv_ship_cust_site_use_rec_type.created_by_module :='TCA_V2_API';
                      hz_cust_account_site_v2pub.create_cust_site_use ('T' ,lv_ship_cust_site_use_rec_type ,NULL ,'F' ,'F' ,ln_ship_site_use_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'Similar LOCATIONS-After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Similar LOCATIONS-After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id);
                      --If API fails
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating cust acct site use  for Similar SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Similar LOCATIONS-After create_cust_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS-After create_cust_site_use SHIP_TO, Error mesg: ' || lc_output);
                        x_ret_code := 1;
                      ELSE
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS-SHIP TO create_cust_site_use ln_ship_site_use_id: ' || ln_ship_site_use_id);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Similar LOCATIONS-SHIP TO LOCATION AND PARTY SITE CREATED FOR LOCATION: '||lv_ship_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                      END IF;
                    END IF; -- lc_return_status <> 'S' for create_party_site_use SHIP_TO for Similar Locations
                  END IF;   -- ln_bill_to_party_site_id IS NOT NULL
                ELSIF (ln_billto_count                         = 0) THEN
                  lv_ship_location_rec_type.county            := 'DEFAULT';
                  lv_ship_location_rec_type.country           := 'US';
                  lv_ship_location_rec_type.created_by_module := 'TCA_V2_API';
                  hz_location_v2pub.create_location (p_init_msg_list => lc_init_msg_list ,p_location_rec => lv_ship_location_rec_type ,x_location_id => ln_ship_to_location_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After Create_Location_SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_to_location_id: ' || ln_ship_to_location_id,lc_return_status);
                  FND_FILE.PUT_LINE(FND_FILE.LOG, 'After Create_Location_SHIP_TO Same BILL_TO Location already exists, lc_return_status: ' || lc_return_status || ', ln_ship_to_location_id: ' || ln_ship_to_location_id);
                  --If API fails
                  IF lc_return_status <> 'S' THEN
                    lc_error_flag     :='Y';
                    FOR i IN 1 .. ln_msg_count
                    LOOP
                      fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                      lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                    END LOOP;
                    lc_output := lc_output||'- Error while creating Location for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After Create_Location_SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After Create_Location_SHIP_TO Same BILL_TO Location already exists, Error mesg: ' || lc_output);
                    x_ret_code := 1;
                  ELSE
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'After Create_Location_SHIP_TO Same BILL_TO Location already exists,Create create_location ln_ship_to_location_id: ' || ln_ship_to_location_id);
                    ---END IF;
                    lc_ship_to_consg_no_dup := stg_tbl_rec_odn.ship_to_cnsgno;
                    ---------------------------------------------------------------
                    --Create Party Site SHIP_TO
                    ---------------------------------------------------------------
                    lv_ship_party_site_rec_type.identifying_address_flag := 'Y';
                    lv_ship_party_site_rec_type.status                   := 'A';
                    lv_ship_party_site_rec_type.party_id                 := NVL(ln_new_party_id,ln_party_id);
                    lv_ship_party_site_rec_type.location_id              := ln_ship_to_location_id;
                    lv_ship_party_site_rec_type.created_by_module        := 'TCA_V2_API';
                    hz_party_site_v2pub.create_party_site (p_init_msg_list => lc_init_msg_list ,p_party_site_rec => lv_ship_party_site_rec_type ,x_party_site_id => ln_ship_to_party_site_id ,x_party_site_number => lc_ship_to_party_site_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                    --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After Create_Party_Site SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_to_party_site_id: ' || ln_ship_to_party_site_id,lc_return_status);
                    FND_FILE.PUT_LINE(FND_FILE.LOG, 'After Create_Party_Site SHIP_TO,Same BILL_TO Location already exists, lc_return_status: ' || lc_return_status || ', ln_ship_to_party_site_id: ' || ln_ship_to_party_site_id);
                    --If API fails
                    IF lc_return_status <> 'S' THEN
                      lc_error_flag     :='Y';
                      FOR i IN 1 .. ln_msg_count
                      LOOP
                        fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                        lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                      END LOOP;
                      lc_output := lc_output||'- Error while creating party site for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After Create_party_site_Ship_to, lc_err_msg: ' || lc_err_msg,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'After Create_party_site_Ship_to, Error mesg: ' || lc_output);
                      x_ret_code := 1;
                    ELSE
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO Create create_party_site ln_ship_to_party_site_id: ' || ln_ship_to_party_site_id);
                      --END IF;
                      ----------------------------------------------------------------
                      -- Create Cust Acct Site SHIP_TO
                      ----------------------------------------------------------------
                      lv_ship_custacctsite_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); --ln_cust_account_id;
                      lv_ship_custacctsite_rec_type.party_site_id     := ln_ship_to_party_site_id;
                      lv_ship_custacctsite_rec_type.created_by_module :='TCA_V2_API';
                      --lv_ship_custacctsite_rec_type.orig_system_reference := stg_tbl_rec_odn.odn_cust_num || '-CONV' ; Commented by Punit on 21-DEC-2017
                      hz_cust_account_site_v2pub.create_cust_acct_site (lc_init_msg_list ,lv_ship_custacctsite_rec_type ,ln_ship_cust_acct_site_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                      --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After create_cust_acct_site, lc_return_status: ' || lc_return_status || ', ln_ship_cust_acct_site_id: ' || ln_ship_cust_acct_site_id,lc_return_status);
                      FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_cust_acct_site SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_cust_acct_site_id: ' || ln_ship_cust_acct_site_id);
                      --If API fails
                      IF lc_return_status <> 'S' THEN
                        lc_error_flag     :='Y';
                        FOR i IN 1 .. ln_msg_count
                        LOOP
                          fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                          lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                        END LOOP;
                        lc_output := lc_output||'- Error while creating cust acct site for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_cust_acct_site SHIP_TO , lc_err_msg: ' || lc_err_msg,lc_return_status);
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_cust_acct_site SHIP_TO , Error mesg: ' || lc_output);
                        x_ret_code := 1;
                      ELSE
                        FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO create_cust_acct_site ln_ship_cust_acct_site_id: ' || ln_ship_cust_acct_site_id);
                        --END IF;
                        ------------------------------------------------------------------
                        --Create party site use SHIP TO
                        -------------------------------------------------------------------
                        lv_ship_partysiteuse_rec_type.site_use_type     := 'SHIP_TO';
                        lv_ship_partysiteuse_rec_type.primary_per_type  := 'Y';
                        lv_ship_partysiteuse_rec_type.party_site_id     := ln_ship_to_party_site_id ;
                        lv_ship_partysiteuse_rec_type.status            := 'A';
                        lv_ship_partysiteuse_rec_type.created_by_module :='TCA_V2_API';
                        hz_party_site_v2pub.create_party_site_use (p_init_msg_list => lc_init_msg_list ,p_party_site_use_rec => lv_ship_partysiteuse_rec_type ,x_party_site_use_id => ln_ship_party_site_use_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                        --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After create_party_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id,lc_return_status);
                        --FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_party_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                        --If API fails
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          lc_output := lc_output||'- Error while creating party site use for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_party_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,' After create_party_site_use SHIP_TO, Error mesg: ' || lc_output);
                          x_ret_code := 1;
                        ELSE
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'Create create_party_site_use ln_ship_party_site_use_id: ' || ln_ship_party_site_use_id);
                          -- END IF;
                          ---------------------------------------------------------------------------
                          -- Create cust account site use SHIP TO
                          ---------------------------------------------------------------------------
                          lv_ship_cust_site_use_rec_type.cust_acct_site_id := ln_ship_cust_acct_site_id;
                          lv_ship_cust_site_use_rec_type.site_use_code     := 'SHIP_TO';
                          lv_ship_cust_site_use_rec_type.primary_flag      := 'Y';
                          lv_ship_cust_site_use_rec_type.status            := 'A';
                          lv_ship_cust_site_use_rec_type.created_by_module :='TCA_V2_API';
                          hz_cust_account_site_v2pub.create_cust_site_use ('T' ,lv_ship_cust_site_use_rec_type ,NULL ,'F' ,'F' ,ln_ship_site_use_id ,lc_return_status ,ln_msg_count ,lc_msg_data);
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG, 'After create_cust_site_use SHIP_TO, lc_return_status: ' || lc_return_status || ', ln_ship_site_use_id: ' || ln_ship_site_use_id);
                          --If API fails
                          IF lc_return_status <> 'S' THEN
                            lc_error_flag     :='Y';
                            FOR i IN 1 .. ln_msg_count
                            LOOP
                              fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                              lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                            END LOOP;
                            lc_output := lc_output||'- Error while creating cust acct site use for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                            --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_cust_site_use SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_cust_site_use SHIP_TO, Error mesg: ' || lc_output);
                            x_ret_code := 1;
                          ELSE
                            --FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO create_cust_site_use ln_ship_site_use_id: ' || ln_ship_site_use_id);
                            --lc_default_shipto := 'Y';
                            ----FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of lc_default_shipto: ' || lc_default_shipto);
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP TO LOCATION AND PARTY SITE CREATED FOR LOCATION: '||lv_ship_cust_site_use_rec_type.location||'for ODN# : ' ||stg_tbl_rec_odn.odn_cust_num);
                          END IF; -- Create cust account site use SHIP TO
                        END IF;   -- lc_return_status <> 'S' for create_party_site_use SHIP_TO
                      END IF;     -- lc_return_status <> 'S' for create_cust_acct_site SHIP_TO
                    END IF;       -- lc_return_status <> 'S' for create_party_site SHIP_TO
                    --END IF;  -- lc_return_status <> 'S' for create_location SHIP_TO
                    ----------------------------------------------------------------------
                    -- SHIP TO Create person, Create Org Contact Point
                    ----------------------------------------------------------------------
                    IF lc_return_status                             = 'S' THEN --- Added by Punit on 21-FEB-2018
                      IF lv_ship_person_rec_type.person_last_name  IS NOT NULL THEN
                        lv_ship_person_rec_type.person_first_name  := fnd_api.g_miss_char;
                        lv_ship_person_rec_type.person_middle_name := fnd_api.g_miss_char;
                        lv_ship_person_rec_type.person_name_suffix := fnd_api.g_miss_char;
                        lv_ship_person_rec_type.created_by_module  := 'TCA_V2_API';
                        hz_party_v2pub.create_person (p_init_msg_list => lc_init_msg_list ,p_person_rec => lv_ship_person_rec_type ,x_party_id => ln_ship_party_id ,x_party_number => lc_ship_party_number ,x_profile_id => ln_ship_profile_id ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                        --If API fails
                        IF lc_return_status <> 'S' THEN
                          lc_error_flag     :='Y';
                          FOR i IN 1 .. ln_msg_count
                          LOOP
                            fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                            lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                          END LOOP;
                          lc_output := lc_output||'- Error while creating person for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                          --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_person SHIP TO Contact, lc_err_msg: ' || lc_err_msg,lc_return_status);
                          FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_person SHIP TO Contact, Error mesg: ' || lc_output);
                          x_ret_code := 1;
                        ELSE
                          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Org Contact create_person SHIP TO Contact  ln_ship_party_id: ' || ln_ship_party_id);
                          ---END IF;
                          --Link person to organization
                          lv_ship_contact_rec_type.job_title_code                   := NULL;
                          lv_ship_contact_rec_type.job_title                        := NULL;
                          lv_ship_contact_rec_type.created_by_module                := 'TCA_V2_API';
                          lv_ship_contact_rec_type.party_rel_rec.subject_id         := ln_ship_party_id;
                          lv_ship_contact_rec_type.party_rel_rec.subject_type       := 'PERSON';
                          lv_ship_contact_rec_type.party_rel_rec.subject_table_name := 'HZ_PARTIES';
                          lv_ship_contact_rec_type.party_rel_rec.object_id          := NVL(ln_new_party_id,ln_party_id);
                          lv_ship_contact_rec_type.party_rel_rec.object_type        := 'ORGANIZATION';
                          lv_ship_contact_rec_type.party_rel_rec.object_table_name  := 'HZ_PARTIES';
                          lv_ship_contact_rec_type.party_rel_rec.relationship_code  := 'CONTACT_OF';
                          lv_ship_contact_rec_type.party_rel_rec.relationship_type  := 'CONTACT';
                          lv_ship_contact_rec_type.party_rel_rec.start_date         := SYSDATE;
                          hz_party_contact_v2pub.create_org_contact (p_init_msg_list => lc_init_msg_list ,p_org_contact_rec => lv_ship_contact_rec_type ,x_org_contact_id => ln_ship_contact_id ,x_party_rel_id => ln_ship_party_rel_id ,x_party_id => ln_sorg_party_id ,x_party_number => lc_sorg_party_number ,x_return_status => lc_return_status ,x_msg_count => ln_msg_count ,x_msg_data => lc_msg_data);
                          --If API fails
                          IF lc_return_status <> 'S' THEN
                            lc_error_flag     :='Y';
                            FOR i IN 1 .. ln_msg_count
                            LOOP
                              fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                              lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                            END LOOP;
                            lc_output := lc_output||'- Error while creating org contact for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                            --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create_org_contact SHIP_TO , lc_err_msg: ' || lc_err_msg,lc_return_status);
                            FND_FILE.PUT_LINE(FND_FILE.LOG,'After create_org_contact SHIP_TO, Error mesg: ' || lc_output);
                          ELSE
                            -- FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP To Org Contact create_org_contact ln_ship_contact_id: ' || ln_ship_contact_id);
                            --END IF;
                            -- SHIP to Org Contact point
                            IF (stg_tbl_rec_odn.ship_to_contact_email           IS NOT NULL OR stg_tbl_rec_odn.ship_to_contact_phone IS NOT NULL ) THEN
                              lv_ship_contact_point_rec_type.contact_point_type := 'PHONE';
                              lv_ship_contact_point_rec_type.owner_table_name   := 'HZ_PARTIES';
                              lv_ship_contact_point_rec_type.owner_table_id     := ln_sorg_party_id;
                              --  lv_bill_contact_point_rec_type.primary_flag          := 'Y';
                              lv_ship_contact_point_rec_type.contact_point_purpose := 'BUSINESS';
                              lv_ship_contact_point_rec_type.created_by_module     := 'TCA_V2_API';
                              lv_ship_email_rec_type.email_format                  := 'MAILHTML';
                              lv_ship_phone_rec_type.phone_line_type               :='GEN';
                              --   l_phone_rec.phone_extension                  := stg_tbl_rec_odn.phone_extension;
                              lc_return_status := NULL;
                              ln_msg_count     := NULL;
                              lc_msg_data      := NULL;
                              HZ_CONTACT_POINT_V2PUB.CREATE_CONTACT_POINT (p_init_msg_list => 'T', p_contact_point_rec => lv_ship_contact_point_rec_type, p_edi_rec => NULL, p_email_rec => lv_ship_email_rec_type, p_phone_rec => lv_ship_phone_rec_type, p_telex_rec => NULL, p_web_rec => NULL, x_contact_point_id => ln_ship_contact_point_id , x_return_status => lc_return_status, x_msg_count => ln_msg_count, x_msg_data => lc_msg_data );
                              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After ORG CREATE_CONTACT_POINT SHIP_TO, l_return_status: ' || lc_return_status || ', ln_ship_contact_point_id : ' || ln_ship_contact_point_id,lc_return_status );
                              --FND_FILE.PUT_LINE(FND_FILE.LOG,'After ORG CREATE_CONTACT_POINT SHIP_TO, l_return_status: ' || lc_return_status || ', ln_ship_contact_point_id : ' || ln_ship_contact_point_id);
                              IF lc_return_status <> 'S' THEN
                                lc_error_flag     :='Y';
                                FOR i IN 1 .. ln_msg_count
                                LOOP
                                  fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                                  lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                                END LOOP;
                                lc_output := lc_output||'- Error while creating contact point for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After CREATE_CONTACT_POINT SHIP_TO, lc_err_msg: ' || lc_err_msg,lc_return_status);
                                FND_FILE.PUT_LINE(FND_FILE.LOG,'After CREATE_CONTACT_POINT SHIP_TO, Error mesg: ' || lc_output);
                                x_ret_code := 1;
                              ELSE
                                FND_FILE.PUT_LINE(FND_FILE.LOG,'CREATE_CONTACT_POINT SHIP_TO ln_ship_contact_point_id : ' || ln_ship_contact_point_id );
                              END IF;
                            END IF; -- stg_tbl_rec_odn.ship_to_contact_email IS NOT NULL OR stg_tbl_rec_odn.ship_to_contact_phone IS NOT NULL
                            -- Link organization to customer account
                            lv_ship_acct_role_rec_type.created_by_module := 'TCA_V2_API';
                            lv_ship_acct_role_rec_type.party_id          := ln_sorg_party_id;                       --Party id from org contact
                            lv_ship_acct_role_rec_type.cust_account_id   := NVL(ln_cust_account_id,ln_custacct_id); -- ln_cust_account_id; -- value of cust_account_id from step 1
                            lv_ship_acct_role_rec_type.cust_acct_site_id := ln_ship_cust_acct_site_id;
                            lv_ship_acct_role_rec_type.role_type         := 'CONTACT';
                            lv_ship_acct_role_rec_type.status            := 'A';
                            HZ_CUST_ACCOUNT_ROLE_V2PUB.create_cust_account_role(p_init_msg_list => 'T' , p_cust_account_role_rec => lv_ship_acct_role_rec_type, x_cust_account_role_id=> ln_ship_acct_role_id, x_return_status => lc_return_status , x_msg_count => ln_msg_count , x_msg_data => lc_msg_data);
                            --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers', 'After SHIP TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_ship_acct_role_id : ' || ln_ship_acct_role_id,lc_return_status );
                            --FND_FILE.PUT_LINE(FND_FILE.LOG,'After SHIP TO create_cust_account_role, l_return_status: ' || lc_return_status || ', ln_ship_acct_role_id : ' || ln_ship_acct_role_id);
                            IF lc_return_status <> 'S' THEN
                              lc_error_flag     :='Y';
                              FOR i IN 1 .. ln_msg_count
                              LOOP
                                fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                                lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                              END LOOP;
                              lc_output := lc_output||'- Error while creating cust account role for SHIP_TO Location: '||stg_tbl_rec_odn.ship_to_cnsgno;
                              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After SHIP_TO Create_cust_account_role, lc_err_msg: ' || lc_err_msg,lc_return_status);
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'After SHIP_TO Create_cust_account_role,Error mesg: ' || lc_output);
                              x_ret_code := 1;
                            ELSE
                              FND_FILE.PUT_LINE(FND_FILE.LOG,'SHIP_TO Create Cust Account role ln_bill_acct_role_id : ' || ln_ship_acct_role_id );
                            END IF;
                          END IF; --lc_return_status <> 'S' create_org_contact SHIP_TO
                        END IF;   -- lc_return_status <> 'S' create_person  SHIP_TO
                      END IF;     -- lv_ship_person_rec_type.person_last_name IS NOT NULL
                    END IF;       -- lc_return_status = 'S' --- Added by Punit on 21-FEB-2018
                  END IF;         -- lc_return_status <> 'S' for create_location SHIP_TO
                END IF;           --ln_billto_count = 0 --- End of Added by Punit on 20-FEB-2018
                --lc_ship_to_consg_no_dup := stg_tbl_rec_odn.bill_to_cnsgno; Commented by Punit on 20-FEB-2018
              END IF; --lc_ship_to_consg_no = lc_bill_to_consg_no
            END IF;   -- lc_ship_to_consg_no <> lc_bill_to_consg_no
            --END IF ;    -- ln_shipto_count = 0
          END IF; -- stg_tbl_rec_odn.ship_to_cnsgno IS NOT NULL --- AND lc_default_shipto = 'Y'
          --END IF; --  stg_tbl_rec_odn.ship_to_cnsgno IS NOT NULL AND stg_tbl_rec_odn.bill_to_cnsgno IS NOT NULL
          --------------------------------------------------------------------------
          -- Party Relation Ship
          --------------------------------------------------------------------------
          BEGIN
            SELECT HP.party_id
            INTO ln_parent_party_id
            FROM hz_parties HP
            WHERE HP.orig_system_reference = stg_tbl_rec_odn.odn_cust_num
              ||'-OMX'
            AND HP.status = 'A'
              --AND EXISTS (SELECT 1 FROM HZ_CUST_ACCOUNTS HCA WHERE HCA.PARTY_ID = HP.PARTY_ID)
            AND ROWNUM = 1;
            FND_FILE.PUT_LINE(FND_FILE.LOG , 'VALUE OF ln_parent_party_id is: '||ln_parent_party_id);
            IF (ln_parent_party_id                        IS NOT NULL AND lc_relationship_flag = 'N' AND ln_new_party_id IS NOT NULL) THEN
              lv_relationship_rec_type.relationship_type  := UPPER ( 'OD_FIN_PAY_WITHIN' ) ;
              lv_relationship_rec_type.relationship_code  := UPPER ( 'PAYER_GROUP_PARENT_OF' ) ;
              lv_relationship_rec_type.subject_id         := ln_parent_party_id; --Parent parent id
              lv_relationship_rec_type.subject_table_name := UPPER ( 'HZ_PARTIES' ) ;
              lv_relationship_rec_type.subject_type       := UPPER ( 'ORGANIZATION' ) ;
              lv_relationship_rec_type.object_id          := ln_new_party_id; --Child Parent Id
              lv_relationship_rec_type.object_table_name  := UPPER ( 'HZ_PARTIES' ) ;
              lv_relationship_rec_type.object_type        := UPPER ( 'ORGANIZATION' ) ;
              lv_relationship_rec_type.start_date         := SYSDATE;
              lv_relationship_rec_type.created_by_module  := 'TCA_V2_API';
              hz_relationship_v2pub.create_relationship ( p_init_msg_list => 'T', p_relationship_rec => lv_relationship_rec_type, x_relationship_id => ln_relationship_id, x_party_id => ln_rel_party_id, x_party_number => lc_rel_party_number, x_return_status => lc_return_status, x_msg_count => ln_msg_count, x_msg_data => lc_msg_data ) ;
              --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','After create party relationship, ln_relationship_id : ' || ln_relationship_id,lc_return_status);
              IF lc_return_status <> 'S' THEN
                --lc_error_flag :='Y';              --- Commented by Punit on 15-JAN-2018
                FOR i IN 1 .. ln_msg_count
                LOOP
                  fnd_msg_pub.get (i, fnd_api.g_false, lc_msg_data, lc_msg_dummy);
                  lc_output := (TO_CHAR (i) || ': ' || lc_msg_data);
                END LOOP;
                lc_output := lc_output||'- Error while creating party relationship  for Organization: '||stg_tbl_rec_odn.odn_cust_name;
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Error while creating Parent Child Relationship:'||lc_output,lc_return_status);
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Error while creating Parent Child Relationship: ' || lc_output);
                x_ret_code := 1;
                --lc_relationship_flag   := 'Y';
              ELSE
                --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Parent Child Relationship Created with party number :'||lc_rel_party_number,lc_return_status);
                --FND_FILE.PUT_LINE(FND_FILE.LOG,'Parent Child Relationship Created with party number :'||lc_rel_party_number );
                lc_relationship_flag := 'Y';
              END IF;
            END IF; --- ln_parent_party_id IS NOT NULL
          EXCEPTION
          WHEN OTHERS THEN
            ln_parent_party_id   := NULL;
            lc_relationship_flag := 'Y';
            --FND_FILE.PUT_LINE(FND_FILE.LOG,'Parent Child Relationship does not exist'||SQLCODE||SQLERRM);
          END;
          /*ELSE
          lc_error_flag:='Y';
          lc_output:='No Vendor Found';
          END IF; */
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of lc_relationship_flag : ' ||lc_relationship_flag );
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of lc_error_flag : ' ||lc_error_flag );
          --FND_FILE.PUT_LINE(FND_FILE.LOG,'Value of lc_output : ' ||lc_output );
          IF lc_error_flag = 'N' THEN
            UPDATE xxod_omx_cnv_ar_cust_stg CUST
            SET CUST.record_status ='S' ,
              CUST.conv_error_msg  ='Created'
            WHERE 1                = 1 ---CUST.batch_id= stg_tbl_rec_odn.batch_id
            AND CUST.record_id     = stg_tbl_rec_odn.record_id
            AND CUST.odn_cust_num  = stg_tbl_rec_odn.odn_cust_num;
            --AND CUST.record_id = lc_customer_bulk(indx).record_id ;
            --interface_id=stg_tbl_rec_odn.interface_id;  -- Added by Punit on 12-JAN-2018
            COMMIT;
          ELSE
            ROLLBACK;
            UPDATE xxod_omx_cnv_ar_cust_stg CUST
            SET CUST.record_status ='E' ,
              CUST.conv_error_msg  =lc_output
            WHERE 1                =1                          --CUST.batch_id = stg_tbl_rec_odn.batch_id --request_id=stg_tbl_rec_odn.request_id; --interface_id=stg_tbl_rec_odn.interface_id;
            AND CUST.record_id     = stg_tbl_rec_odn.record_id --; --interface_id=stg_tbl_rec.interface_id;  -- Added by Punit on 12-JAN-2018
            AND CUST.odn_cust_num  = stg_tbl_rec_odn.odn_cust_num;
            --AND CUST.record_id = lc_customer_bulk(indx).record_id ;
            COMMIT;
          END IF;
        END LOOP; -- indx_odn IN 1 .. lc_odn_customer_bulk.COUNT
        --END LOOP; --- Bulk Cursor OPEN lcu_stg_tbl_odn Loop
      END LOOP; -- indx IN 1 .. lc_customer_bulk.COUNT--- stg_tbl_rec_odn IN lcu_stg_tbl_odn
    END LOOP;   -- Bulk Cursor OPEN lcu_stg_tbl Loop
    ----log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','End :'||g_conc_request_id,'');
    --FND_FILE.PUT_LINE(FND_FILE.LOG,'End Of Customer Creation'  );
  END IF; -- p_process_flag = 'Y' OR p_reprocess_flag = 'Y'
  BEGIN
    INSERT INTO xxod_omx_cnv_ar_cust_stg_hist
    SELECT * FROM xxod_omx_cnv_ar_cust_stg WHERE odn_cust_num IS NOT NULL;
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Error while inserting into History Table'||SQLCODE||SQLERRM);
  END;
  Print_Customer_Details;
EXCEPTION
WHEN OTHERS THEN
  --log_debug_msg('XXOD_OMX_CNV_AR_CUST_PKG.Load_Customers','Unexpected Error in Customer Creation: '||g_conc_request_id,sqlerrm);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Unexpected Error in Customer Creation: '|| sqlerrm);
  x_ret_code := 2;
END Load_Customers;
END XXOD_OMX_CNV_AR_CUST_PKG;
/