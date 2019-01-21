SET VERIFY OFF;
SET SHOW OFF;
SET ECHO OFF;
SET TAB OFF;
SET FEEDBACK OFF;
 
WHENEVER SQLERROR CONTINUE;
 
WHENEVER OSERROR EXIT FAILURE ROLLBACK


create or replace 
PACKAGE BODY XX_AP_SUP_REAL_OUT_RMS_XML_PKG
AS
  -- +============================================================================================+
  --   Office Depot - Project Simplify
  --
  -- +============================================================================================+
  --   Name        : XX_AP_SUP_REAL_OUT_RMS_XML_PKG
  --   RICE ID     : I0380 Supplier_TDM_Realtime_Datalink_Outbound_Interface
  --   Solution ID :
  --   Description : IDMS Outbound Integration For RMS in XML format
  --   Change Record
  -- +============================================================================================+
  --  Version     Date         Author           Remarks
  --  =========   ===========  =============    ===============================================
  --  1.0         15-Nov-17    Sunil Kalal       Initial version
  --  1.1         06-Aug-18    Antonio Morales   Add vendor site category to AP_RMS_TO_LEGACY_BANK
  --                                             translation
  --  1.2          11-Oct-18   Sunil Kalal       NAIT-64184  Added logic for Freight terms
  --  1.3          12-Oct-18   Sunil Kalal       NAIT-64721  Added logic for CI Bank Name  for SCM.
  --  1.4          12-Oct-18   Sunil Kalal       NAIT-64249  Added Logic for 3 columns for Payment Terms with new query
  --  1.5          16-Oct-18   Sunil Kalal       NAIT-64664  Added logic for All addresses (EBS and custom addresses) in same cursor.
  --  1.6          17-oct-18   Sunil Kalal       NAIT-64249  Added new tags for  Payment Terms EBS and FOB lookup code.
  --  1.7          19-Oct-18   Sunil Kalal       NAIT-64664  Added new query for the EBS addresses
  --  1.8          01-Nov-18   Sunil Kalal       NAIT-69405  Addeed attribute5 column instead of duns_num for DUNS_NUMBER
  --  1.9          05-Dec-18   Sunil Kalal       NAIT-74711  Added logic to check for Freight Terms PP and CC Only else NULL.
  -- +============================================================================================+
  ------------------------------------------------------------
  ------------------------------------------------------------
  --
  --
PROCEDURE xx_ap_sup_addr_type_id_update(
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2 )
IS
  /*Variable declaration*/
  v_request_id     NUMBER := NULL;
  v_request_status BOOLEAN;
  v_phase          VARCHAR2 (2000) := NULL;
  v_wait_status    VARCHAR2 (2000) := NULL;
  v_dev_phase      VARCHAR2 (2000) := NULL;
  v_dev_status     VARCHAR2 (2000) := NULL;
  v_message        VARCHAR2 (2000) :=NULL;
  vc_request_id    NUMBER;
  i                NUMBER :=0;
  v_addr_type      NUMBER;
  v_addr_type_id   NUMBER;
  v_row_count      NUMBER;
  v_row_count_stg  NUMBER;
  CURSOR C1--Cursor for addr_type_id generated from sequence
  IS
    SELECT addr_type_id,address_type FROM xx_ap_sup_address_type;
BEGIN
  fnd_file.put_line (fnd_file.output, '——————————————————' );
  dbms_output.put_line('Before Submitting Conc Prog');
  v_request_id := fnd_request.submit_request('XXFIN',--v_conc_prog_appl_short_name,
  'XXAPSUPADDR',                                     --v_conc_prog_short_name,
  'OD : RMS TO EBS Supplier Addresses (Vendor Contacts) Conversion Program',NULL,FALSE
  --p_parameter1
  );
  fnd_file.put_line (fnd_file.log,'Concurrent Request for OD : RMS TO EBS Supplier Addresses (Vendor Contacts) Conversion Program Submitted
Successfully: Request id is : ' || v_request_id );
  COMMIT;
  IF v_request_id IS NOT NULL THEN
    /*Calling fnd_concurrent.wait_for_request to wait for the
    program to complete */
    v_request_status:= fnd_concurrent.wait_for_request ( request_id => v_request_id, INTERVAL => 10, max_wait => 0, phase => v_phase, status => v_wait_status, dev_phase => v_dev_phase, dev_status => v_dev_status, MESSAGE => v_message );
    fnd_file.put_line (fnd_file.LOG,'Dev_phase: '||v_dev_phase);
    fnd_file.put_line (fnd_file.LOG,'Dev_status : '||v_dev_status);
    IF v_dev_phase ='COMPLETE' AND v_dev_status = 'NORMAL' THEN
      fnd_file.put_line(fnd_file.log, 'OD : RMS TO EBS Supplier Addresses (Vendor Contacts) Conversion Program Completed Successfully');
      OPEN c1;
      LOOP
        FETCH c1 INTO v_addr_type_id , v_addr_type;
        EXIT
      WHEN c1%notfound;
        UPDATE xx_ap_sup_vendor_contact_stg
        SET addr_type_id=v_addr_type_id
        WHERE addr_type =v_addr_type;
        COMMIT;
        i := i+1;
      END LOOP;
      CLOSE c1;
      SELECT COUNT(*) INTO v_row_count_stg FROM xx_ap_sup_vendor_contact_stg;
      fnd_file.put_line (fnd_file.log,'----------------------------------------------------------------------');
      fnd_file.put_line (fnd_file.log,'Updating xx_ap_sup_vendor_contact_stg for addr_type_id. Total rows processed Successfully:'|| v_row_count_stg);
      INSERT
      INTO xx_ap_sup_vendor_contact
        (
          addr_key ,
          module ,
          key_value_1 ,
          key_value_2 ,
          seq_no ,
          primary_addr_ind ,
          add_1 ,
          add_2 ,
          add_3 ,
          city ,
          state ,
          country_id ,
          post ,
          contact_name ,
          contact_phone ,
          contact_telex ,
          contact_fax ,
          contact_email ,
          oracle_vendor_site_id ,
          od_phone_nbr_ext ,
          od_phone_800_nbr ,
          od_comment_1 ,
          od_comment_2 ,
          od_comment_3 ,
          od_comment_4 ,
          od_email_ind_flg ,
          od_ship_from_addr_id ,
          attribute1 ,
          attribute2 ,
          attribute3 ,
          attribute4 ,
          attribute5 ,
          creation_date ,
          created_by ,
          last_update_date ,
          last_updated_by ,
          last_update_login ,
          enable_flag ,
          addr_type_id
        )
      SELECT addr_key ,
        module ,
        key_value_1 ,
        key_value_2 ,
        seq_no ,
        primary_addr_ind ,
        add_1 ,
        add_2 ,
        add_3 ,
        city ,
        state ,
        country_id ,
        post ,
        contact_name ,
        contact_phone ,
        contact_telex ,
        contact_fax ,
        contact_email ,
        oracle_vendor_site_id ,
        od_phone_nbr_ext ,
        od_phone_800_nbr ,
        od_comment_1 ,
        od_comment_2 ,
        od_comment_3 ,
        od_comment_4 ,
        od_email_ind_flg ,
        od_ship_from_addr_id ,
        attribute1 ,
        attribute2 ,
        attribute3 ,
        attribute4 ,
        attribute5 ,
        creation_date ,
        created_by ,
        last_update_date ,
        last_updated_by ,
        last_update_login ,
        enable_flag ,
        addr_type_id
      FROM xx_ap_sup_vendor_contact_stg;
      COMMIT;
      SELECT COUNT(*) INTO v_row_count FROM xx_ap_sup_vendor_contact;
      fnd_file.put_line (fnd_file.log,'Inserting into xx_ap_sup_vendor_contact for addr_type_id. Total rows processed Successfully:'|| v_row_count);
    ELSE
      fnd_file.put_line (fnd_file.LOG,'SQL LOADER request did not complete succesfully.');
    END IF;
  END IF;
END xx_ap_sup_addr_type_id_update;
----
--
PROCEDURE xx_ap_supp_traits_id_update(
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2 )
IS
  /*Variable declaration*/
  v_request_id     NUMBER := NULL;
  v_request_status BOOLEAN;
  v_phase          VARCHAR2 (2000) := NULL;
  v_wait_status    VARCHAR2 (2000) := NULL;
  v_dev_phase      VARCHAR2 (2000) := NULL;
  v_dev_status     VARCHAR2 (2000) := NULL;
  v_message        VARCHAR2 (2000) :=NULL;
  vc_request_id    NUMBER;
  i                NUMBER :=0;
  v_sup_trait      NUMBER;
  v_sup_trait_id   NUMBER;
  v_row_count_stg  NUMBER;
  v_row_count      NUMBER;
  CURSOR C1--Cursor for sup_trait_id generated from sequence
  IS
    SELECT sup_trait_id,sup_trait FROM xx_ap_sup_traits;
BEGIN
  fnd_file.put_line (fnd_file.output, '——————————————————' );
  dbms_output.put_line('Before Submitting Conc Prog');
  v_request_id := fnd_request.submit_request('XXFIN',--v_conc_prog_appl_short_name,
  'XXAPSUPTRAITSMATRIX',                             --v_conc_prog_short_name,
  'OD : RMS TO EBS Supplier Traits Matrix Conversion Program',NULL,FALSE
  --p_parameter1
  );
  fnd_file.put_line (fnd_file.log,'Concurrent Request for OD : RMS TO EBS Supplier Traits Matrix Conversion Program Submitted
Successfully: Request id is : ' || v_request_id );
  COMMIT;
  IF v_request_id IS NOT NULL THEN
    /*Calling fnd_concurrent.wait_for_request to wait for the
    program to complete */
    v_request_status:= fnd_concurrent.wait_for_request ( request_id => v_request_id, INTERVAL => 10, max_wait => 0, phase => v_phase, status => v_wait_status, dev_phase => v_dev_phase, dev_status => v_dev_status, MESSAGE => v_message );
    fnd_file.put_line (fnd_file.LOG,'Dev_phase: '||v_dev_phase);
    fnd_file.put_line (fnd_file.LOG,'Dev_status : '||v_dev_status);
    IF v_dev_phase ='COMPLETE' AND v_dev_status = 'NORMAL' THEN
      fnd_file.put_line(fnd_file.log, 'OD : RMS TO EBS Supplier Traits Matrix Conversion Program Completed Successfully');
      OPEN c1;
      LOOP
        FETCH c1 INTO v_sup_trait_id , v_sup_trait;
        EXIT
      WHEN c1%notfound;
        UPDATE xx_ap_sup_traits_matrix_stg
        SET sup_trait_id =v_sup_trait_id
        WHERE sup_trait  =v_sup_trait;
        COMMIT;
        i := i+1;
      END LOOP;
      CLOSE c1;
      SELECT COUNT(*) INTO v_row_count_stg FROM xx_ap_sup_traits_matrix_stg;
      fnd_file.put_line (fnd_file.log,'----------------------------------------------------------------------');
      fnd_file.put_line (fnd_file.log,'Updating xx_ap_sup_traits_matrix_stg for sup_trait_id. Total rows processed Successfully:'|| v_row_count_stg);
      INSERT
      INTO xx_ap_sup_traits_matrix
        (
          supplier,
          attribute1 ,
          attribute2 ,
          attribute3 ,
          attribute4 ,
          creation_date ,
          created_by ,
          last_update_date ,
          last_updated_by ,
          last_update_login ,
          enable_flag ,
          sup_trait_id
        )
      SELECT supplier,
        attribute1 ,
        attribute2 ,
        attribute3 ,
        attribute4 ,
        creation_date ,
        created_by ,
        last_update_date ,
        last_updated_by ,
        last_update_login ,
        enable_flag ,
        sup_trait_id
      FROM xx_ap_sup_traits_matrix_stg;
      COMMIT;
      SELECT COUNT(*) INTO v_row_count FROM xx_ap_sup_traits_matrix;
      fnd_file.put_line (fnd_file.log,'Inserting into xx_ap_sup_traits_matrix for sup_trait_id. Total rows processed Successfully:'|| v_row_count);
    ELSE
      fnd_file.put_line (fnd_file.LOG,'SQL LOADER request did not complete succesfully.');
    END IF;
  END IF;
END xx_ap_supp_traits_id_update;
----
PROCEDURE xx_ap_supp_addl_attri_sqlldr(
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2 )
IS
  /*Variable declaration*/
  v_request_id            NUMBER := NULL;
  v_request_status        BOOLEAN;
  v_phase                 VARCHAR2 (2000) := NULL;
  v_wait_status           VARCHAR2 (2000) := NULL;
  v_dev_phase             VARCHAR2 (2000) := NULL;
  v_dev_status            VARCHAR2 (2000) := NULL;
  v_message               VARCHAR2 (2000) :=NULL;
  vc_request_id           NUMBER;
  i                       NUMBER :=0;
  j                       NUMBER :=0;
  k                       NUMBER :=0;
  v_supplier              NUMBER;
  v_vendor_site_id        NUMBER;
  v_attribute10           VARCHAR2(150);
  v_od_contract_signature VARCHAR2(150);
  v_od_contract_title     VARCHAR2(150);
  v_od_ven_sig_name       VARCHAR2(150);
  v_od_ven_sig_title      VARCHAR2(150);
  CURSOR C1--Cursor for valid vendor_site_id and attribute10 NOT NULL for ap_supplier_sites_all Table.
  IS
    SELECT aa.supplier,--optimized query for better performance
      ss.vendor_site_id,
      ss.attribute10,
      aa.od_contract_signature,
      aa.od_contract_title,
      aa.od_ven_sig_name,
      aa.od_ven_sig_title
    FROM xx_ap_sup_addl_attributes aa,
      ap_supplier_sites_all ss
    WHERE (ltrim(ss.vendor_site_code_alt,'0') = ltrim(aa.supplier,'0')
    OR ss.vendor_site_id                      = ltrim(aa.supplier,'0'))
      --    nvl(ltrim(ss.vendor_site_code_alt,'0'),to_char(ss.vendor_site_id))
    AND ss.pay_site_flag='Y'
      --aa.supplier   =ss.vendor_site_id--commented due to change NAIT--55710
    AND ss.attribute10    IS NOT NULL
    AND (ss.inactive_date IS NULL
    OR ss.inactive_date   >= TRUNC(sysdate));
  --
  CURSOR C2--Cursor for valid vendor site id does not exist in ap_supplier_sites_all thoughit exists in xx_ap_sup_addl_attributes
  IS
    SELECT supplier--New query due to change NAIT--55710
    FROM xx_ap_sup_addl_attributes xx
    WHERE NOT EXISTS
      (SELECT 1
      FROM xx_ap_sup_addl_attributes aa,
        ap_supplier_sites_all ss
      WHERE (ltrim(ss.vendor_site_code_alt,'0') = ltrim(aa.supplier,'0')
      OR ss.vendor_site_id                      = ltrim(aa.supplier,'0'))
        --TO_CHAR(aa.supplier) = NVL(ltrim(ss.vendor_site_code_alt,'0'),TO_CHAR(ss.vendor_site_id))
      AND ss.pay_site_flag ='Y'
      AND aa.supplier      = xx.supplier
        --AND ss.inactive_date      IS NULL--
      AND (ss.inactive_date IS NULL
      OR ss.inactive_date   >= TRUNC(sysdate))
      );
  /*    SELECT supplier--commented due to change NAIT--55710
  FROM xx_ap_sup_addl_attributes
  WHERE supplier NOT IN
  (SELECT aa.supplier
  FROM xx_ap_sup_addl_attributes aa,
  ap_supplier_sites_all ss
  where aa.supplier=ss.vendor_site_id--
  ); */
  CURSOR c3--Cursor for valid vendor site id exists in both tables but attribute10 is NULL.
  IS
    SELECT aa.supplier
    FROM xx_ap_sup_addl_attributes aa,
      ap_supplier_sites_all ss
    WHERE (ltrim(ss.vendor_site_code_alt,'0') = ltrim(aa.supplier,'0')
    OR ss.vendor_site_id                      = ltrim(aa.supplier,'0'))
      --TO_CHAR(aa.supplier) = NVL(ltrim(ss.vendor_site_code_alt,'0'),TO_CHAR(ss.vendor_site_id))
    AND ss.pay_site_flag ='Y'
      --aa.supplier   =ss.vendor_site_id--commented due to change NAIT--55710
    AND ss.attribute10 IS NULL
      --AND ss.inactive_date IS NULL;
    AND (ss.inactive_date IS NULL
    OR ss.inactive_date   >= TRUNC(sysdate));
BEGIN
  fnd_file.put_line (fnd_file.output, '——————————————————' );
  dbms_output.put_line('Before Submitting Conc Prog');
  v_request_id := fnd_request.submit_request('XXFIN',--v_conc_prog_appl_short_name,
  'XXAPSUPADDLATTRI',                                --v_conc_prog_short_name,
  'OD : RMS TO EBS Supplier PI Pack Attributes Conversion Program',NULL,FALSE
  --p_parameter1
  );
  fnd_file.put_line (fnd_file.log,'Concurrent Request for OD : RMS TO EBS Supplier PI Pack Attributes Conversion Program Submitted
Successfully: Request id is : ' || v_request_id );
  COMMIT;
  IF v_request_id IS NOT NULL THEN
    /*Calling fnd_concurrent.wait_for_request to wait for the
    program to complete */
    v_request_status:= fnd_concurrent.wait_for_request ( request_id => v_request_id, INTERVAL => 10, max_wait => 0, phase => v_phase, status => v_wait_status, dev_phase => v_dev_phase, dev_status => v_dev_status, MESSAGE => v_message );
    fnd_file.put_line (fnd_file.LOG,'Dev_phase: '||v_dev_phase);
    fnd_file.put_line (fnd_file.LOG,'Dev_status : '||v_dev_status);
    IF v_dev_phase ='COMPLETE' AND v_dev_status = 'NORMAL' THEN
      fnd_file.put_line(fnd_file.log, 'OD : RMS TO EBS Supplier PI Pack Attributes Conversion Program Completed Successfully');
      OPEN c1;
      LOOP
        FETCH c1
        INTO v_supplier ,
          v_vendor_site_id,
          v_attribute10,
          v_od_contract_signature,
          v_od_contract_title,
          v_od_ven_sig_name,
          v_od_ven_sig_title;
        EXIT
      WHEN c1%notfound;
        UPDATE xx_po_vendor_sites_kff
        SET segment38   = v_od_contract_signature,
          segment39     =v_od_contract_title,
          segment59     =v_od_ven_sig_name,
          segment60     =v_od_ven_sig_title
        WHERE vs_kff_id = v_attribute10;
        UPDATE xx_ap_sup_addl_attributes
        SET attribute1=attribute1
          ||'S'
        WHERE supplier=v_supplier;
        COMMIT;
        i := i+1;
      END LOOP;
      fnd_file.put_line (fnd_file.log,'----------------------------------------------------------------------');
      fnd_file.put_line (fnd_file.log,'Updating xx_po_vendor_sites_kff table for RMS Pi Pack Attributes. Total rows processed Successfully:'|| i);
      CLOSE c1;
      OPEN c2;
      LOOP
        FETCH c2 INTO v_supplier ;
        EXIT
      WHEN c2%notfound;
        UPDATE xx_ap_sup_addl_attributes
        SET attribute1=attribute1
          || 'E1'
          --       set attribute1= substr(attribute1||'Vendor_site_id does not exist.',60)
        WHERE supplier=v_supplier;
        COMMIT;
        j := j+1;
      END LOOP;
      fnd_file.put_line (fnd_file.LOG,'Total rows errored for incorrect vendor site id:'|| j);
      CLOSE c2;
      OPEN c3;
      LOOP
        FETCH c3 INTO v_supplier ;
        EXIT
      WHEN c3%notfound;
        UPDATE xx_ap_sup_addl_attributes
        SET attribute1=attribute1
          ||'E2'--'Attribute10 is NULL'
        WHERE supplier=v_supplier;
        COMMIT;
        k := k+1;
      END LOOP;
      fnd_file.put_line (fnd_file.LOG,'Total rows errored for attribute10 is NULL:'|| k);
      CLOSE c3;
    ELSE
      fnd_file.put_line (fnd_file.LOG,'SQL LOADER request did not complete succesfully.');
    END IF;
  END IF;
END xx_ap_supp_addl_attri_sqlldr;
---
FUNCTION xx_ap_addr_update_allowed(
    p_address_type_id NUMBER)
  RETURN VARCHAR2
AS
  l_update_allowed  VARCHAR2(1)  :='N';
  l_resp_short_name VARCHAR2(150):=NULL;
  l_count           NUMBER;
  l_addr_type       VARCHAR2(500);
BEGIN
  SELECT responsibility_key
  INTO l_resp_short_name
  FROM FND_RESPONSIBILITY
  WHERE responsibility_id= fnd_profile.value('RESP_ID')
  AND end_date          IS NULL;
  IF l_resp_short_name  IS NOT NULL THEN
    BEGIN
      SELECT address_type
      INTO l_addr_type
      FROM XX_AP_SUP_ADDRESS_TYPE
      WHERE addr_type_id = p_address_type_id;
    EXCEPTION
    WHEN OTHERS THEN
      l_addr_type:=NULL;
    END;
    BEGIN
      SELECT 'Y'
      INTO l_update_allowed
      FROM XX_FIN_TRANSLATEVALUES VALS ,
        XX_FIN_TRANSLATEDEFINITION DEFN
      WHERE 1                                 =1
      AND DEFN.TRANSLATE_ID                   =VALS.TRANSLATE_ID
      AND DEFN.TRANSLATION_NAME               = 'OD_RMS_SCM_ADDRESS_UPDATE'
      AND VALS.SOURCE_VALUE1                  = l_resp_short_name
      AND VALS.TARGET_VALUE1                  ='ADDR_TYPE'
      AND VALS.ENABLED_FLAG                   ='Y'
      AND NVL(VALS.END_DATE_ACTIVE,SYSDATE+1) > SYSDATE
      AND ltrim(VALS.TARGET_VALUE2,'0')       =ltrim(l_addr_type,'0');
    EXCEPTION
    WHEN OTHERS THEN
      L_UPDATE_ALLOWED :='N';
    END;
  END IF;
  RETURN l_update_allowed;
  fnd_file.put_line(fnd_file.log,'allowed ' ||l_update_allowed);
  dbms_output.put_line('allowed ' ||l_update_allowed);
END;
PROCEDURE xx_ap_supp_rms_update_telex(
    v_vendor_site_id IN NUMBER,
    v_error_message OUT VARCHAR2)
AS
  v_attribute8 VARCHAR2(150);
BEGIN
  IF v_vendor_site_id IS NOT NULL THEN
    SELECT SUBSTR(attribute8,1,2)
    INTO v_attribute8
    FROM ap_supplier_sites_all
    WHERE vendor_site_id=v_vendor_site_id;
    IF v_attribute8    IS NOT NULL THEN
      IF v_attribute8   ='TR' THEN
        UPDATE ap_supplier_sites_all
        SET telex            = 'INTFXXCD'
        WHERE vendor_site_id = v_vendor_site_id ;
        COMMIT;
        v_error_message := NULL;
        fnd_file.PUT_LINE(fnd_file.LOG,'Table updated successfully for vendor site id: '||v_vendor_site_id);
        dbms_output.put_line('Table updated successfully for vendor site id: '||v_vendor_site_id);
      ELSE
        v_error_message :='Attribute8 is not matching RMS criteria for vendor_site_id: '||v_vendor_site_id;
      END IF;
    ELSE
      v_error_message := 'Attribute8 is NULL for vendor_site_id: ' ||v_vendor_site_id;
    END IF;
  ELSE
    v_error_message := 'Vendor Site Id is NULL';
  END IF;
EXCEPTION
WHEN OTHERS THEN
  v_error_message :='Error updating TELEX column in ap_supplier_sites_all for vendor_site_id: '||v_vendor_site_id;
  fnd_file.PUT_LINE(fnd_file.LOG,'Error is :'||v_error_message);
END;
-------------
PROCEDURE xx_ap_supp_out_track(
    v_transaction_id       IN NUMBER,
    v_globalvendor_id      IN NUMBER ,
    v_name                 IN VARCHAR2,
    v_vendor_site_id       IN NUMBER,
    v_vendor_site_code     IN VARCHAR2,
    v_site_orgid           IN NUMBER ,
    v_user_id              IN VARCHAR2,
    v_user_name            IN VARCHAR2,
    v_xml_output           IN CLOB,
    v_request_id           IN NUMBER,
    v_response_status_code IN VARCHAR2,
    v_response_reason      IN VARCHAR2,
    v_error_message OUT VARCHAR2 )
AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
  INSERT
  INTO xx_ap_sup_outbound_track VALUES
    (
      v_transaction_id,
      v_globalvendor_id,
      v_name,
      v_vendor_site_id,
      v_vendor_site_code,
      v_site_orgid,
      sysdate,
      v_user_id,
      v_user_name,
      v_xml_output,--performance issue due to CLOB xml output
      v_request_id,
      v_response_status_code,
      v_response_reason
    );
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  v_error_message :='Error inserting row in xx_ap_sup_outbound_track table for transaction_id: '||v_transaction_id;
  fnd_file.PUT_LINE(fnd_file.LOG,'Error is :'||v_error_message);
END;
---------------------
PROCEDURE xx_ap_supp_real_out_rms_xml
  (
    errbuf OUT VARCHAR2,
    retcode OUT VARCHAR2
  )
AS
  /*********************************************************************************************************
  *****************************************************************************************************************/
  /* Define constants */
  p_response_code VARCHAR2
  (
    150
  )
  ;
  v_error_message VARCHAR2(150);
  c_file_path     CONSTANT VARCHAR2(15)          := 'XXFIN_OUTBOUND';
  c_blank         CONSTANT VARCHAR2(1)           := ' ';
  c_when          CONSTANT DATE                  := sysdate;
  c_separator     CONSTANT VARCHAR2(1)           := ';';
  c_fileext       CONSTANT VARCHAR2(10)          := '.txt';
  c_who           CONSTANT fnd_user.user_id%type := fnd_load_util.owner_id('INTERFACE');
  /* Define variables */
  v_system           VARCHAR2(32);
  v_last_update_date DATE;
  v_gss_last_update  DATE;
  v_rms_last_update  DATE;
  v_psft_last_update DATE;
  v_extract_time     DATE;
  v_date_diff interval DAY(4) TO second(0); --Defect #13002
  v_vendor_last_update po_vendor_sites_all.last_update_date%type;
  v_site_last_update po_vendor_sites_all.last_update_date%type;
  v_site_contact_last_update po_vendor_contacts.last_update_date%type;
  v_bpel_run_flag VARCHAR2(1)  := 'N';
  v_exit_flag     VARCHAR2(1)  := 'N';
  v_gss_flag      VARCHAR2(1)  := 'N';
  v_rms_flag      VARCHAR2(1)  := 'N';
  v_psft_flag     VARCHAR2(1)  := 'N';
  v_timestamp     VARCHAR2(30) := TO_CHAR(c_when, 'DDMONYY_HHMISS');
  v_gssfileid utl_file.file_type;
  v_rmsfileid utl_file.file_type;
  v_psftfileid utl_file.file_type;
  v_opengssfile  VARCHAR2(1) := 'N';
  v_openrmsfile  VARCHAR2(1) := 'N';
  v_openpsftfile VARCHAR2(1) := 'N';
  v_name         VARCHAR2(100);
  v_vendor_id    NUMBER;
  v_bank_name ce_banks_v.bank_name%type;--NAIT-64721 Added by Sunil
  v_supplier_number VARCHAR2(100);
  v_parent_name     VARCHAR2(100);
  v_vendor_number   VARCHAR2(30);
  v_parent_id       NUMBER;
  v_vendor_type     VARCHAR2(64);
  v_category        VARCHAR2(64);
  v_type_att9       VARCHAR2(64);
  v_gss_data po_vendor_sites_all.attribute15%type;
  v_reccnt              NUMBER := 0;
  v_file_data1          VARCHAR2(1000);
  v_file_data2          VARCHAR2(1000);
  v_file_data3          VARCHAR2(1000);
  v_file_data4          VARCHAR2(1000);
  v_file_data5          VARCHAR2(1000);
  v_file_data6          VARCHAR2(1000);
  v_file_data7          VARCHAR2(1000);
  v_gss_mfg_id          VARCHAR2(64) := NULL;
  v_gss_buying_agent_id VARCHAR2(64) := NULL;
  v_gss_freight_id      VARCHAR2(64) := NULL;
  v_gss_ship_id         VARCHAR2(64) := NULL;
  v_addr_flag           NUMBER;
  v_site_phone          VARCHAR2(100);
  v_site_fax            VARCHAR2(100);
  v_site_contact_name   VARCHAR2(100);
  v_globalvendor_id po_vendor_sites_all.attribute9%type;
  v_gssglobalvendor_id po_vendor_sites_all.attribute9%type;
  v_primary_paysite_flag po_vendor_sites_all.primary_pay_site_flag%type;
  v_purchasing_site_flag po_vendor_sites_all.purchasing_site_flag%type;
  v_pay_site_flag po_vendor_sites_all.pay_site_flag%type;
  v_area_code po_vendor_sites_all.area_code%type;
  v_phone po_vendor_sites_all.phone%type;
  v_province po_vendor_sites_all.province%type;
  v_parent_vendor_id po_vendors.parent_vendor_id%type;
  v_attribute10 VARCHAR2(500);
  --po_vendor_sites_all.attribute10%TYPE;
  v_attribute11 VARCHAR2(500);
  --po_vendor_sites_all.attribute11%TYPE;
  v_attribute12 VARCHAR2(500);
  --po_vendor_sites_all.attribute12%TYPE;
  v_attribute13 VARCHAR2(500);
  --po_vendor_sites_all.attribute13%TYPE;
  v_attribute15 VARCHAR2(500);
  v_attribute16 VARCHAR2(500);
  --business classification
  v_mbe            VARCHAR2(500);
  v_nmsdc          VARCHAR2(500);
  v_wbe            VARCHAR2(500);
  v_wbenc          VARCHAR2(500);
  v_vob            VARCHAR2(500);
  v_dodva          VARCHAR2(500);
  v_doe            VARCHAR2(500);
  v_usbln          VARCHAR2(500);
  v_lgbt           VARCHAR2(500);
  v_nglcc          VARCHAR2(500);
  v_nibnishablty   VARCHAR2(500);
  v_fob            VARCHAR2(500);
  v_sb             VARCHAR2(500);
  v_samgov         VARCHAR2(500);
  v_sba            VARCHAR2(500);
  v_sbc            VARCHAR2(500);
  v_sdbe           VARCHAR2(500);
  v_sba8a          VARCHAR2(500);
  v_hubzone        VARCHAR2(500);
  v_wosb           VARCHAR2(500);
  v_wsbe           VARCHAR2(500);
  v_edwosb         VARCHAR2(500);
  v_vosb           VARCHAR2(500);
  v_sdvosb         VARCHAR2(500);
  v_hbcumi         VARCHAR2(500);
  v_anc            VARCHAR2(500);
  v_ind            VARCHAR2(500);
  v_minority_owned VARCHAR2(500);
  --Added by Sunil
  --po_vendor_sites_all.attribute15%TYPE;
  v_attribute8 po_vendor_sites_all.attribute8%type;
  v_supp_attribute7 po_vendors.attribute7%type;
  v_supp_attribute8 po_vendors.attribute8%type;
  v_supp_attribute9 po_vendors.attribute9%type;
  v_supp_attribute10 po_vendors.attribute10%type;
  v_supp_attribute11 po_vendors.attribute10%type;
  v_vendor_site_id po_vendor_sites_all.vendor_site_id%type;
  g_vendor_site_id po_vendor_sites_all.vendor_site_id%type;
  v_vendor_site_code po_vendor_sites_all.vendor_site_code%type;
  v_vendor_site_code_alt po_vendor_sites_all.vendor_site_code_alt%type;--Added by sunil
  v_bank_account_name po_vendor_sites_all.bank_account_name%type;
  v_bank_account_num po_vendor_sites_all.bank_account_num%type;
  v_address_line1 po_vendor_sites_all.address_line1%type;
  v_address_line2 po_vendor_sites_all.address_line2%type;
  v_address_line3 po_vendor_sites_all.address_line3%type;
  v_city po_vendor_sites_all.city%type;
  v_state po_vendor_sites_all.state%type;
  v_zip po_vendor_sites_all.zip%type;
  v_country po_vendor_sites_all.country%type;
  v_orgcountry po_vendor_sites_all.country%type;
  v_site_contact_rtvname VARCHAR2(100);
  v_site_rtvaddr1 po_vendor_sites_all.address_line1%type;
  v_site_rtvaddr2 po_vendor_sites_all.address_line2%type;
  v_site_rtvaddr3 po_vendor_sites_all.address_line2%type;
  v_site_rtvcity po_vendor_sites_all.city%type;
  v_site_rtvstate po_vendor_sites_all.state%type;
  v_site_rtvzip po_vendor_sites_all.zip%type;
  v_site_rtvcountry po_vendor_sites_all.country%type;
  v_site_contact_payname VARCHAR2(100);
  v_site_payaddr1 po_vendor_sites_all.address_line1%type;
  v_site_payaddr2 po_vendor_sites_all.address_line2%type;
  v_site_payaddr3 po_vendor_sites_all.address_line2%type;
  v_site_paycity po_vendor_sites_all.city%type;
  v_site_paystate po_vendor_sites_all.state%type;
  v_site_payzip po_vendor_sites_all.zip%type;
  v_site_paycountry po_vendor_sites_all.country%type;
  v_site_contact_purchname VARCHAR2(100);
  v_site_purchaddr1 po_vendor_sites_all.address_line1%type;
  v_site_purchaddr2 po_vendor_sites_all.address_line2%type;
  v_site_purchaddr3 po_vendor_sites_all.address_line2%type;
  v_site_purchcity po_vendor_sites_all.city%type;
  v_site_purchstate po_vendor_sites_all.state%type;
  v_site_purchzip po_vendor_sites_all.zip%type;
  v_site_purchcountry po_vendor_sites_all.country%type;
  v_site_contact_ppname VARCHAR2(100);
  v_site_ppaddr1 po_vendor_sites_all.address_line1%type;
  v_site_ppaddr2 po_vendor_sites_all.address_line2%type;
  v_site_ppaddr3 po_vendor_sites_all.address_line2%type;
  v_site_ppcity po_vendor_sites_all.city%type;
  v_site_ppstate po_vendor_sites_all.state%type;
  v_site_ppzip po_vendor_sites_all.zip%type;
  v_site_ppcountry po_vendor_sites_all.country%type;
  v_inactive_date xx_po_vendor_sites_kff_v.blank99%type;
  --po_vendor_sites_all.inactive_date%TYPE;
  v_invc_curr po_vendors.invoice_currency_code%type;
  v_payment_currency_code po_vendors.payment_currency_code%type;
  v_site_lang NUMBER;
  v_site_orgid po_vendor_sites_all.org_id%type;
  v_site_language po_vendor_sites_all.language %type;
  v_site_terms po_vendor_sites_all.terms_id%type;
  v_site_terms_date_basis po_vendor_sites_all.terms_date_basis%type;
  v_terms_date_basis po_vendors.terms_date_basis%type;
  v_site_freightterms VARCHAR2(100);                                --po_vendor_sites_all.freight_terms_lookup_code%type;----NAIT-64184--Commented by Sunil
  v_site_fob_lookup_code po_vendor_sites_all.fob_lookup_code%type;----NAIT-64184--Added by Sunil
  v_site_contact_id po_vendor_contacts.vendor_contact_id%type;
  v_site_contact_fname po_vendor_contacts.first_name%type;
  v_site_contact_lname po_vendor_contacts.last_name%type;
  v_site_contact_areacode po_vendor_contacts.area_code%type;
  v_site_contact_phone po_vendor_contacts.phone%type;
  v_site_contact_fareacode po_vendor_contacts.fax_area_code%type;
  v_site_contact_fphone po_vendor_contacts.phone%type;
  v_site_contact_payemail po_vendor_contacts.email_address%type;
  v_site_contact_purchemail po_vendor_contacts.email_address%type;
  v_site_contact_ppemail po_vendor_contacts.email_address%type;
  v_site_contact_rtvemail po_vendor_contacts.email_address%type;
  v_site_contact_email po_vendor_contacts.email_address%type;
  v_site_contact_payphone   VARCHAR2(100);
  v_site_contact_purchphone VARCHAR2(100);
  v_site_contact_ppphone    VARCHAR2(100);
  v_site_contact_rtvphone   VARCHAR2(100);
  v_site_contact_payfax     VARCHAR2(100);
  v_site_contact_purchfax   VARCHAR2(100);
  v_site_contact_ppfax      VARCHAR2(100);
  v_site_contact_rtvfax     VARCHAR2(100);
  v_site_category           VARCHAR2(100);
  v_tax_reg_num po_vendors.num_1099%type;
  v_duns_num po_vendor_sites_all.duns_number%type;
  -- or DUNS_NUMBER
  v_po_vendor_vat_registration po_vendor_sites_all.vat_registration_num%type;
  v_po_site_vat_registration po_vendor_sites_all.vat_registration_num%type;
  v_debit_memo_flag po_vendor_sites_all.create_debit_memo_flag%type;
  v_pay_group_lookup_code po_vendors.pay_group_lookup_code%type;
  v_payment_method_lookup_code ap_suppliers.payment_method_lookup_code%type; -- V4.0 po_vendors.payment_method_lookup_code%TYPE;
  v_vendor_type_lookup_code po_vendors.vendor_type_lookup_code%type;
  v_minority_cd po_vendors.minority_group_lookup_code%type;
  v_minority_class VARCHAR2(30);
  --Variables for Business Classification Descriptions
  v_minority_cd_desc fnd_lookup_values_vl.meaning%type;
  v_mbe_desc fnd_lookup_values_vl.meaning%type;
  v_nmsdc_desc fnd_lookup_values_vl.meaning%type;
  v_wbe_desc fnd_lookup_values_vl.meaning%type;
  v_wbenc_desc fnd_lookup_values_vl.meaning%type;
  v_vob_desc fnd_lookup_values_vl.meaning%type;
  v_dodva_desc fnd_lookup_values_vl.meaning%type;
  v_doe_desc fnd_lookup_values_vl.meaning%type;
  v_usbln_desc fnd_lookup_values_vl.meaning%type;
  v_lgbt_desc fnd_lookup_values_vl.meaning%type;
  v_nglcc_desc fnd_lookup_values_vl.meaning%type;
  v_nibnishablty_desc fnd_lookup_values_vl.meaning%type;
  v_fob_desc fnd_lookup_values_vl.meaning%type;
  v_sb_desc fnd_lookup_values_vl.meaning%type;
  v_samgov_desc fnd_lookup_values_vl.meaning%type;
  v_sba_desc fnd_lookup_values_vl.meaning%type;
  v_sbc_desc fnd_lookup_values_vl.meaning%type;
  v_sdbe_desc fnd_lookup_values_vl.meaning%type;
  v_sba8a_desc fnd_lookup_values_vl.meaning%type;
  v_hubzone_desc fnd_lookup_values_vl.meaning%type;
  v_wosb_desc fnd_lookup_values_vl.meaning%type;
  v_wsbe_desc fnd_lookup_values_vl.meaning%type;
  v_edwosb_desc fnd_lookup_values_vl.meaning%type;
  v_vosb_desc fnd_lookup_values_vl.meaning%type;
  v_sdvosb_desc fnd_lookup_values_vl.meaning%type;
  v_hbcumi_desc fnd_lookup_values_vl.meaning%type;
  v_anc_desc fnd_lookup_values_vl.meaning%type;
  v_ind_desc fnd_lookup_values_vl.meaning%type;
  v_minority_owned_desc fnd_lookup_values_vl.meaning%type;
  --
  --    DEFINE KFF variables
  v_lead_time xx_po_vendor_sites_kff_v.blank99%type;
  v_back_order_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_delivery_policy xx_po_vendor_sites_kff_v.blank99%type;
  v_min_prepaid_code xx_po_vendor_sites_kff_v.blank99%type;
  v_vendor_min_amount xx_po_vendor_sites_kff_v.blank99%type;
  v_supplier_ship_to xx_po_vendor_sites_kff_v.blank99%type;
  v_inventory_type_code xx_po_vendor_sites_kff_v.blank99%type;
  v_vertical_market_indicator xx_po_vendor_sites_kff_v.blank99%type;
  v_handling xx_po_vendor_sites_kff_v.blank99%type;
  v_allow_auto_receipt xx_po_vendor_sites_kff_v.blank99%type;
  v_eft_settle_days xx_po_vendor_sites_kff_v.blank99%type;
  v_split_file_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_master_vendor_id xx_po_vendor_sites_kff_v.blank99%type;
  v_pi_pack_year xx_po_vendor_sites_kff_v.blank99%type;
  v_od_date_signed xx_po_vendor_sites_kff_v.blank99%type;
  v_vendor_date_signed xx_po_vendor_sites_kff_v.blank99%type;
  v_deduct_from_invoice_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_min_bus_category xx_po_vendor_sites_kff_v.blank99%type;
  v_new_store_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_new_store_terms xx_po_vendor_sites_kff_v.blank99%type;
  v_seasonal_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_start_date xx_po_vendor_sites_kff_v.blank99%type;
  v_end_date xx_po_vendor_sites_kff_v.blank99%type;
  v_seasonal_terms xx_po_vendor_sites_kff_v.blank99%type;
  v_late_ship_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_edi_distribution_code xx_po_vendor_sites_kff_v.blank99%type;
  v_od_cont_sig xx_po_vendor_sites_kff_v.blank99%type;
  v_od_cont_title xx_po_vendor_sites_kff_v.blank99%type;
  v_rtv_option xx_po_vendor_sites_kff_v.blank99%type;
  v_rtv_freight_payment_method xx_po_vendor_sites_kff_v.blank99%type;
  v_permanent_rga xx_po_vendor_sites_kff_v.blank99%type;
  v_destroy_allow_amount xx_po_vendor_sites_kff_v.blank99%type;
  v_payment_frequency xx_po_vendor_sites_kff_v.blank99%type;
  v_min_return_qty xx_po_vendor_sites_kff_v.blank99%type;
  v_min_return_amount xx_po_vendor_sites_kff_v.blank99%type;
  v_damage_destroy_limit xx_po_vendor_sites_kff_v.blank99%type;
  v_rtv_instructions xx_po_vendor_sites_kff_v.blank99%type;
  v_addl_rtv_instructions xx_po_vendor_sites_kff_v.blank99%type;
  v_rga_marked_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_remove_price_sticker_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_contact_supplier_rga_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_destroy_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_serial_num_required_flag xx_po_vendor_sites_kff_v.blank99%type;
  v_obsolete_item xx_po_vendor_sites_kff_v.blank99%type;
  v_obsolete_allowance_pct xx_po_vendor_sites_kff_v.blank99%type;
  v_obsolete_allowance_days xx_po_vendor_sites_kff_v.blank99%type;
  v_850_po xx_po_vendor_sites_kff_v.blank99%type;
  v_860_po_change xx_po_vendor_sites_kff_v.blank99%type;
  v_855_confirm_po xx_po_vendor_sites_kff_v.blank99%type;
  v_856_asn xx_po_vendor_sites_kff_v.blank99%type;
  v_846_availability xx_po_vendor_sites_kff_v.blank99%type;
  v_810_invoice xx_po_vendor_sites_kff_v.blank99%type;
  v_832_price_sales_cat xx_po_vendor_sites_kff_v.blank99%type;
  v_820_eft xx_po_vendor_sites_kff_v.blank99%type;
  v_861_damage_shortage xx_po_vendor_sites_kff_v.blank99%type;
  v_852_sales xx_po_vendor_sites_kff_v.blank99%type;
  v_rtv_related_siteid xx_po_vendor_sites_kff_v.blank99%type;
  v_od_ven_sig_name xx_po_vendor_sites_kff_v.blank99%type;
  v_od_ven_sig_title xx_po_vendor_sites_kff_v.blank99%type;
  v_rms_count  NUMBER := 0;
  v_gss_count  NUMBER := 0;
  v_psft_count NUMBER := 0;
  -- x_source_value3    VARCHAR2(200);
  x_target_value1    VARCHAR2(200);
  x_error_message    VARCHAR2(2000);
  x_target_value2    VARCHAR2(200);
  x_target_value3    VARCHAR2(200);
  x_target_value4    VARCHAR2(200);
  x_target_value5    VARCHAR2(200);
  x_target_value6    VARCHAR2(200);
  x_target_value7    VARCHAR2(200);
  x_target_value8    VARCHAR2(200);
  x_target_value9    VARCHAR2(200);
  x_target_value10   VARCHAR2(200);
  x_target_value11   VARCHAR2(200);
  x_target_value12   VARCHAR2(200);
  x_target_value13   VARCHAR2(200);
  x_target_value14   VARCHAR2(200);
  x_target_value15   VARCHAR2(200);
  x_target_value16   VARCHAR2(200);
  x_target_value17   VARCHAR2(200);
  x_target_value18   VARCHAR2(200);
  x_target_value19   VARCHAR2(200);
  x_target_value20   VARCHAR2(200);
  v_gss_outfilename  VARCHAR2(60) := 'SyncSupplierGSS_' || v_timestamp || c_fileext;
  v_psft_outfilename VARCHAR2(60) := 'SyncSupplierPSFT_' || v_timestamp || c_fileext;
  v_rms_outfilename  VARCHAR2(60) := 'SyncSupplierRMS_' || v_timestamp || c_fileext;
  -- variables for file copy
  ln_req_id              NUMBER;
  lc_sourcepath          VARCHAR2(1000);
  lc_destpath            VARCHAR2(1000);
  lb_result              BOOLEAN;
  lc_phase               VARCHAR2(1000);
  lc_status              VARCHAR2(1000);
  lc_dev_phase           VARCHAR2(1000);
  lc_dev_status          VARCHAR2(1000);
  lc_message             VARCHAR2(1000);
  lc_err_status          VARCHAR2(10);
  lc_err_mesg            VARCHAR2(1000);
  lc_err_flag            VARCHAR2(10) := 'N';
  v_terms_name           VARCHAR2(100);
  v_site_terms_name      VARCHAR2(100);
  v_site_terms_name_1    VARCHAR2(100);
  v_site_terms_name_desc VARCHAR2(250);
  v_discount_percent ap_terms_lines.discount_percent%type;--NAIT-64249 Added by Sunil
  v_discount_days ap_terms_lines.discount_days%type;      --NAIT-64249 Added by Sunil
  v_due_days ap_terms_lines.due_days%type;                --NAIT-64249 Added by Sunil
  v_site_exists_flag VARCHAR2(1) := 'Y';
  v_telex ap_supplier_sites_all.telex%type; --V4.0
  xml_output CLOB;
  /*-- Cursor to read the custom table
  CURSOR extsupplupdate_cur IS
  SELECT v.ext_system,
  v.last_update_date,
  v.extract_time,
  v.bpel_running_flag
  FROM xx_ap_supp_extract v;*/
  --sunil
  -- Main Cursor to read all the data ;
  CURSOR mainsupplupdate_cur
  IS
    SELECT a.vendor_site_id,
      a.attribute8,
      a.attribute13,
      a.vendor_site_code,
      a.vendor_site_code_alt,--NAIT-64664 added by sunil
      a.last_update_date,
      a.purchasing_site_flag,
      a.pay_site_flag,
      a.address_line1,
      a.address_line2,
      a.address_line3,
      a.city,
      upper(a.state),
      a.zip,
      NVL(a.country, 'US'),
      a.area_code,
      a.phone,
      a.inactive_date,
      a.pay_group_lookup_code,
      --nvl(ieppm.payment_method_code,a.payment_method_lookup_code),--commented for defect 33188
      NVL(ieppm.payment_method_code,'CHECK'),--added for defect 33188
      a.payment_currency_code,
      a.primary_pay_site_flag,
      --  NVL(a.freight_terms_lookup_code, 'CC'),--NAIT-64184--Commented by Sunil
      a.freight_terms_lookup_code,--NAIT-64184--Added by Sunil
      a.fob_lookup_code,          --NAIT-64184--Added by Sunil
      a.vat_registration_num,
      a.language,
      a.bank_account_num,
      a.bank_account_name,
      --      a.duns_number,--commented for NAIT-69405
      a.attribute5, --Added for NAIT-69405
      -- DUNNS number
      b.vendor_contact_id,
      b.first_name,
      b.last_name,
      b.area_code,
      b.phone,
      b.email_address,
      b.fax_area_code,
      b.fax,
      b.last_update_date,
      SUBSTR(c.vendor_name,1,30),
      c.vendor_id,--NAIT-64721 Added by Sunil
      c.segment1, --Added for NAIT-56518
      c.last_update_date,
      c.vat_registration_num,
      a.terms_date_basis,
      c.vendor_type_lookup_code,
      -- identify Garnishment suppliers
      c.parent_vendor_id,
      c.num_1099,
      -- TIN
      c.minority_group_lookup_code,
      c.attribute7,
      c.attribute8,
      c.attribute9,
      c.attribute10,
      c.attribute11,
      NVL(a.create_debit_memo_flag, 'N'),
      a.province,
      a.terms_id,
      a.org_id,
      a.telex                     -- V4.0
    FROM ap_supplier_sites_all a, -- V4.00 po_vendor_sites_all a,
      po_vendor_contacts b,
      ap_suppliers c,               -- V4.00 po_vendors c
      iby_external_payees_all iepa, --V4.0
      iby_ext_party_pmt_mthds ieppm --V4.0
    WHERE a.vendor_site_id = b.vendor_site_id(+)
    AND a.vendor_id        = c.vendor_id(+)
    AND a.org_id IN(xx_fin_country_defaults_pkg.f_org_id('CA'), xx_fin_country_defaults_pkg.f_org_id('US')) --= ou.organization_id
      -- V4.0
    AND a.vendor_site_id               = iepa.supplier_site_id
    AND iepa.ext_payee_id              = ieppm.ext_pmt_party_id(+)
    AND( (ieppm.inactive_date         IS NULL)
    OR (ieppm.inactive_date            > sysdate))
    AND a.telex                       IS NOT NULL -- Defect 28126
    AND SUBSTR(NVL(telex,'XXXXXX'),-6)<> 'INTFCD' --(a.telex IS NOT NULL AND a.telex NOT LIKE '%INTFCD')  -- V4.0, Added Telex Condition
    ORDER BY a.vendor_site_id;
  -- Site Names beginning with ?EXP-IMP?, ?TR?, ?EXP-IMP-PAY? etc and I will use
  -- those value and Site Category as EXPENSE/TRADE/GARNISHMENT to identify suppliers
  -- for outbound interface to GSS/PSFT/Peoplesoft.  But for garnishments,  they
  -- will have a classification of  ?Garnishment? and a site category that starts with EXP.
  -- Garnishments: po_vendor.vendor_type_lookup_code =  'VENDORS'
PROCEDURE init_variables
IS
BEGIN
  v_globalvendor_id         := NULL;
  v_name                    := NULL;
  v_vendor_id               :=0;   --NAIT-64721 Added by Sunil
  v_bank_name               :=NULL;--NAIT-64721 Added by Sunil
  v_supplier_number         := NULL;
  v_vendor_site_id          := 0;
  v_vendor_site_code        := NULL;
  v_vendor_site_code_alt    :=0;--added by Sunil NAIT-64664
  v_addr_flag               := 0;
  v_inactive_date           := NULL;
  v_invc_curr               := NULL;
  v_site_lang               := 1;
  v_site_terms              := NULL;
  v_site_terms_name         := NULL;
  v_site_terms_name_1       := NULL;
  v_site_terms_name_desc    := NULL;
  v_discount_percent        :=0;--NAIT-64249 Added by Sunil
  v_discount_days           :=0;--NAIT-64249 Added by Sunil
  v_due_days                :=0;--NAIT-64249 Added by Sunil
  v_site_freightterms       := NULL;
  v_site_fob_lookup_code    := NULL;
  v_debit_memo_flag         := NULL;
  v_duns_num                := NULL;
  v_parent_name             := NULL;
  v_parent_id               := NULL;
  v_tax_reg_num             := 0;
  v_attribute8              := NULL;
  v_attribute10             := NULL;
  v_attribute11             := NULL;
  v_attribute12             := NULL;
  v_attribute13             := NULL;
  v_attribute15             := NULL;
  v_attribute16             := NULL;
  v_site_contact_name       := NULL;
  v_site_contact_payphone   := NULL;
  v_site_contact_purchphone := NULL;
  v_site_contact_ppphone    := NULL;
  v_site_contact_rtvphone   := NULL;
  v_site_contact_payfax     := NULL;
  v_site_contact_purchfax   := NULL;
  v_site_contact_ppfax      := NULL;
  v_site_contact_rtvfax     := NULL;
  v_site_phone              := NULL;
  v_site_fax                := NULL;
  v_site_contact_payemail   := NULL;
  v_site_contact_purchemail := NULL;
  v_site_contact_ppemail    := NULL;
  v_site_contact_rtvemail   := NULL;
  v_site_contact_payname    := NULL;
  v_site_payaddr1           := NULL;
  v_site_payaddr2           := NULL;
  v_site_payaddr3           := NULL;
  v_site_paycity            := NULL;
  v_site_paystate           := NULL;
  v_site_payzip             := NULL;
  v_site_paycountry         := NULL;
  v_site_contact_rtvname    := NULL;
  v_site_rtvaddr1           := NULL;
  v_site_rtvaddr2           := NULL;
  v_site_rtvaddr3           := NULL;
  v_site_rtvcity            := NULL;
  v_site_rtvstate           := NULL;
  v_site_rtvzip             := NULL;
  v_site_rtvcountry         := NULL;
  v_site_contact_purchname  := NULL;
  v_site_purchaddr1         := NULL;
  v_site_purchaddr2         := NULL;
  v_site_purchaddr3         := NULL;
  v_site_purchcity          := NULL;
  v_site_purchstate         := NULL;
  v_site_purchzip           := NULL;
  v_site_purchcountry       := NULL;
  v_site_contact_ppname     := NULL;
  v_site_ppaddr1            := NULL;
  v_site_ppaddr2            := NULL;
  v_site_ppaddr3            := NULL;
  v_site_ppcity             := NULL;
  v_site_ppstate            := NULL;
  v_site_ppzip              := NULL;
  v_site_ppcountry          := NULL;
  v_attribute15             := NULL;
  v_supp_attribute7         := NULL;
  v_supp_attribute8         := NULL;
  v_supp_attribute9         := NULL;
  v_supp_attribute10        := NULL;
  v_supp_attribute11        := NULL;
  v_primary_paysite_flag    := NULL;
  v_attribute8              := NULL;
  v_bank_account_name       := NULL;
  v_bank_account_num        := NULL;
  v_minority_cd             := NULL;
  v_file_data1              := NULL;
  v_file_data2              := NULL;
  v_file_data3              := NULL;
  v_file_data4              := NULL;
  v_file_data5              := NULL;
  v_file_data6              := NULL;
  v_minority_class          := NULL;
  v_minority_cd_desc        := NULL;
  --Variables for Business Classification Descriptions.
  v_mbe_desc            := NULL;
  v_nmsdc_desc          := NULL;
  v_wbe_desc            := NULL;
  v_wbenc_desc          := NULL;
  v_vob_desc            := NULL;
  v_dodva_desc          := NULL;
  v_doe_desc            := NULL;
  v_usbln_desc          := NULL;
  v_lgbt_desc           := NULL;
  v_nglcc_desc          := NULL;
  v_nibnishablty_desc   := NULL;
  v_fob_desc            := NULL;
  v_sb_desc             := NULL;
  v_samgov_desc         := NULL;
  v_sba_desc            := NULL;
  v_sbc_desc            := NULL;
  v_sdbe_desc           := NULL;
  v_sba8a_desc          := NULL;
  v_hubzone_desc        := NULL;
  v_wosb_desc           := NULL;
  v_wsbe_desc           := NULL;
  v_edwosb_desc         := NULL;
  v_vosb_desc           := NULL;
  v_sdvosb_desc         := NULL;
  v_hbcumi_desc         := NULL;
  v_anc_desc            := NULL;
  v_ind_desc            := NULL;
  v_minority_owned_desc := NULL;
  --
  v_payment_currency_code := NULL;
  v_site_orgid            := NULL;
  v_site_exists_flag      := 'Y';
  v_orgcountry            := NULL;
END init_variables;
PROCEDURE init_kffvariables
IS
BEGIN
  -- KFF variables;
  v_lead_time                  := NULL;
  v_back_order_flag            := NULL;
  v_delivery_policy            := NULL;
  v_min_prepaid_code           := NULL;
  v_vendor_min_amount          := NULL;
  v_supplier_ship_to           := NULL;
  v_inventory_type_code        := NULL;
  v_vertical_market_indicator  := NULL;
  v_allow_auto_receipt         := NULL;
  v_handling                   := NULL;
  v_eft_settle_days            := NULL;
  v_split_file_flag            := NULL;
  v_master_vendor_id           := NULL;
  v_pi_pack_year               := NULL;
  v_od_date_signed             := NULL;
  v_vendor_date_signed         := NULL;
  v_deduct_from_invoice_flag   := NULL;
  v_min_bus_category           := NULL;
  v_new_store_flag             := NULL;
  v_new_store_terms            := NULL;
  v_seasonal_flag              := NULL;
  v_start_date                 := NULL;
  v_end_date                   := NULL;
  v_seasonal_terms             := NULL;
  v_late_ship_flag             := NULL;
  v_edi_distribution_code      := NULL;
  v_od_cont_sig                := NULL;
  v_od_cont_title              := NULL;
  v_rtv_option                 := NULL;
  v_rtv_freight_payment_method := NULL;
  v_permanent_rga              := NULL;
  v_destroy_allow_amount       := NULL;
  v_payment_frequency          := NULL;
  v_min_return_qty             := NULL;
  v_min_return_amount          := NULL;
  v_damage_destroy_limit       := NULL;
  v_rtv_instructions           := NULL;
  v_addl_rtv_instructions      := NULL;
  v_rga_marked_flag            := NULL;
  v_remove_price_sticker_flag  := NULL;
  v_contact_supplier_rga_flag  := NULL;
  v_destroy_flag               := NULL;
  v_serial_num_required_flag   := NULL;
  v_obsolete_item              := NULL;
  v_obsolete_allowance_pct     := NULL;
  v_obsolete_allowance_days    := NULL;
  v_850_po                     := NULL;
  v_860_po_change              := NULL;
  v_855_confirm_po             := NULL;
  v_856_asn                    := NULL;
  v_846_availability           := NULL;
  v_810_invoice                := NULL;
  v_832_price_sales_cat        := NULL;
  v_820_eft                    := NULL;
  v_861_damage_shortage        := NULL;
  v_852_sales                  := NULL;
  v_od_ven_sig_name            := NULL;
  v_od_ven_sig_title           := NULL;
  v_gss_mfg_id                 := NULL;
  v_gss_buying_agent_id        := NULL;
  v_gss_freight_id             := NULL;
  v_gss_ship_id                := NULL;
END init_kffvariables;
PROCEDURE xx_ap_sup_invoke_xml_out(
    v_transaction_id   IN NUMBER,
    v_globalvendor_id  IN NUMBER,
    v_name             IN VARCHAR2,
    v_vendor_site_id   IN NUMBER,
    v_vendor_site_code IN VARCHAR2,
    v_site_orgid       IN NUMBER ,
    v_user_id          IN VARCHAR2,
    v_user_name        IN VARCHAR2,
    p_xml_payload      IN CLOB,
    v_request_id       IN NUMBER,
    v_error_message OUT VARCHAR2,
    p_response_code OUT VARCHAR2 )
IS
  n        NUMBER :=0;
  l_offset NUMBER :=1;
  req utl_http.req;
  res utl_http.resp;
  url  VARCHAR2(4000) ;--:= 'https://agerndev.na.odcorp.net/vpsservice/api/v2/XXFIN_INVOICE_RESPONSE/'; --create a profile and set the VPS invoice update REST service URL;
  name VARCHAR2(4000);
  buffer CLOB;
  --  content VARCHAR2(4000) := '<Test>Test</Test>';
  payloadcontent CLOB             := p_xml_payload;
  l_wallet_location VARCHAR2(256) := NULL;
  l_password        VARCHAR2(256) := NULL;
  l_publish_debug   VARCHAR2(50)  := NULL;
  l_username        VARCHAR2(256) := NULL;
  l_vps_password    VARCHAR2(256) := NULL;
  l_enable_auth     VARCHAR2(256) := NULL;
  l_string CLOB;
  p_last_tag_pos         NUMBER :=0;
  l_next_pos             NUMBER :=1;
  v_response_status_code VARCHAR2(256);
  v_response_reason      VARCHAR2(256);
BEGIN
  BEGIN
    SELECT TARGET_VALUE1 ,
      TARGET_VALUE2
    INTO l_wallet_location ,
      l_password
    FROM XX_FIN_TRANSLATEVALUES VAL,
      XX_FIN_TRANSLATEDEFINITION DEF
    WHERE 1                 =1
    AND DEF.TRANSLATE_ID    = VAL.TRANSLATE_ID
    AND DEF.TRANSLATION_NAME='XX_FIN_IREC_TOKEN_PARAMS'
    AND VAL.SOURCE_VALUE1   = 'WALLET_LOCATION'
    AND VAL.ENABLED_FLAG    = 'Y'
    AND SYSDATE BETWEEN VAL.START_DATE_ACTIVE AND NVL(VAL.END_DATE_ACTIVE, SYSDATE+1);
  EXCEPTION
  WHEN OTHERS THEN
    FND_FILE.PUT_LINE(FND_FILE.LOG, 'Wallet Location Not Found' );
    l_wallet_location := NULL;
    l_password        := NULL;
  END;
  fnd_file.put_line(fnd_file.log, 'l_wallet_location: ' || l_wallet_location);
  BEGIN
    SELECT target_value1,
      target_value2,
      target_value3
    INTO url,
      l_username ,
      l_vps_password
    FROM XX_FIN_TRANSLATEVALUES TV,
      XX_FIN_TRANSLATEDEFINITION TD
    WHERE TD.TRANSLATION_NAME = 'XX_AP_SUPPLIER_OUTBOUND'
    AND TV.TRANSLATE_ID       = TD.TRANSLATE_ID
    AND TV.ENABLED_FLAG       = 'Y'
    AND sysdate BETWEEN TV.START_DATE_ACTIVE AND NVL(TV.END_DATE_ACTIVE,sysdate)
    AND tv.source_value1 = 'AUTH_SERVICE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'XX_AP_SUPPLIER_OUTBOUND Translation Not Found' );
    url            :=NULL;
    l_username     :=NULL;
    l_vps_password := NULL;
  END;
  --Set wallet location
  IF l_wallet_location IS NOT NULL THEN
    utl_http.set_wallet(l_wallet_location,l_password);
  END IF;
	  --  url:='http://5CG5222FFN:8080/eaiapi/supplier/publishsupplierdata';
	  -- DEV url:= 'https://ch-kube-dev-min.uschecomrnd.net/services/stage-supplier-publishing-service/eaiapi/supplier/publishsupplierdata';
	  --UAT url:='https://ch-kube-dev-min.uschecomrnd.net/services/dev-supplier-publishing-service/eaiapi/supplier/publishsupplierdata';
	  --FND_FILE.PUT_LINE(FND_FILE.LOG, 'after URL' );
	  --url :='https://ch-kube-rnd-min.uschecomrnd.net/services/supplier-publishing-service/eaiapi/supplier/publishsupplierdata';--hardcoded
  req := utl_http.begin_request(url, 'POST',' HTTP/1.1');
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Request URL: '||req.url);
  fnd_file.put_line(fnd_file.log,'Request Method: '||req.method);
  fnd_file.put_line(fnd_file.log,'Request Version: '||req.http_version);
  --Set headers
  utl_http.set_header(req, 'user-agent', 'mozilla/5.0');
  utl_http.set_header(req, 'content-type', 'application/xml');
  utl_http.set_header(req, 'Content-Length', LENGTH(payLoadContent));
  utl_http.set_header(req, 'Authorization', 'Basic ' || utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(l_username||':'||l_vps_password))));
  LOOP
    EXIT
  WHEN l_offset > dbms_lob.getlength( payloadcontent);
    utl_http.write_text(req, dbms_lob.substr(payloadcontent, 10000, l_offset ));
    fnd_file.put_line(fnd_file.output,dbms_lob.substr(xml_output, 10000, l_offset )) ;
    l_offset := l_offset + 10000;
  END LOOP;
  res := utl_http.get_response(req);
  v_response_status_code :=res.status_code;
  v_response_reason      := res.reason_phrase;
  fnd_file.put_line(fnd_file.log,'Response Status Code: '||res.status_code);
  FND_FILE.PUT_LINE(FND_FILE.LOG,'Response Reason: '||res.reason_phrase);
  fnd_file.put_line(fnd_file.log,'Response Version: '||res.http_version);
  BEGIN
    LOOP
      utl_http.read_line(res, buffer);
      --   dbms_output.put_line(buffer);
      FND_FILE.PUT_LINE(FND_FILE.output,buffer);
    END LOOP;
    utl_http.end_response(res);
  EXCEPTION
  WHEN utl_http.end_of_body THEN
    utl_http.end_response(res);
  END;
  p_response_code:=res.status_code;
  BEGIN
    IF v_response_status_code = 200 AND v_response_reason='OK' THEN
      UPDATE ap_supplier_sites_all -- V4.01, added _all table
      SET telex = v_telex
        ||' '
        || 'INTFCD'
      WHERE vendor_site_id = g_vendor_site_id ;
      COMMIT;
    ELSE
      UPDATE ap_supplier_sites_all -- V4.01, added _all table
      SET telex = v_telex
        ||' '
        || 'INTFXXCD'
      WHERE vendor_site_id = g_vendor_site_id ;
      retcode             :=2;
      COMMIT;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log, 'Error while updating Telex as INTFCD for vendor_site_id = ' || v_vendor_site_id );
    retcode :=2;
  END;
  xx_ap_supp_out_track( v_transaction_id, v_globalvendor_id , v_name , v_vendor_site_id , v_vendor_site_code , v_site_orgid , v_user_id , v_user_name , ''--p_xml_payload
  , v_request_id , v_response_status_code, v_response_reason , v_error_message );
END xx_ap_sup_invoke_xml_out;
PROCEDURE create_data_line
IS
  p_address_type1 VARCHAR2(10);
  p_request_id    NUMBER;
  p_user_id       NUMBER;
  p_user_name     VARCHAR2(150);
  l_offset        NUMBER DEFAULT 1;
  l_domdoc dbms_xmldom.domdocument;
  l_xmltype xmltype;
  l_root_node dbms_xmldom.domnode;
  l_supplier_list_req_node dbms_xmldom.domnode;
  l_supplier_list_req_element dbms_xmldom.domelement;
  l_supplier_list_node dbms_xmldom.domnode;
  l_supplier_node dbms_xmldom.domnode;
  l_bus_class_node dbms_xmldom.domnode;
  l_supp_header_node dbms_xmldom.domnode;
  l_cust_attributes_node dbms_xmldom.domnode;
  l_edi_attributes_node dbms_xmldom.domnode;
  l_supplier_traits_node dbms_xmldom.domnode;
  l_supplier_trait_node dbms_xmldom.domnode;
  l_sup_trait_action_type_n dbms_xmldom.domnode;
  l_sup_trait_action_type_tn dbms_xmldom.domnode;
  l_sup_trait_node dbms_xmldom.domnode;
  l_sup_trait_textnode dbms_xmldom.domnode;
  l_sup_trait_desc_node dbms_xmldom.domnode;
  l_sup_trait_desc_textnode dbms_xmldom.domnode;
  l_sup_master_sup_ind_node dbms_xmldom.domnode;
  l_sup_master_sup_ind_textnode dbms_xmldom.domnode;
  l_trans_id_node dbms_xmldom.domnode;
  l_trans_id_textnode dbms_xmldom.domnode;
  l_globalvendor_id_n dbms_xmldom.domnode;
  l_globalvendor_id_tn dbms_xmldom.domnode;
  l_suppliernumber_n dbms_xmldom.domnode;
  l_suppliernumber_tn dbms_xmldom.domnode;
  l_name_node dbms_xmldom.domnode;
  l_name_textnode dbms_xmldom.domnode;
  l_supplier_site_node dbms_xmldom.domnode;
  l_address_node dbms_xmldom.domnode;
  l_addr_list_element dbms_xmldom.domelement;
  l_addr_element dbms_xmldom.domelement;
  l_addr_list_node dbms_xmldom.domnode;
  l_addr_node dbms_xmldom.domnode;
  l_site_addr_node dbms_xmldom.domnode;
  l_site_purch_addr_node dbms_xmldom.domnode;
  l_site_pay_addr_node dbms_xmldom.domnode;
  l_site_pp_addr_node dbms_xmldom.domnode;
  l_site_rtv_addr_node dbms_xmldom.domnode;
  l_site_addr_contact_node dbms_xmldom.domnode;
  l_site_addr_cont_list_node dbms_xmldom.domnode;
  l_site_addr_contact_pname_node dbms_xmldom.domnode;
  l_site_addr_cont_ptitle_node dbms_xmldom.domnode;
  l_site_addr_cont_ptitle_tn dbms_xmldom.domnode;
  l_v_addr_con_salutation_n dbms_xmldom.domnode;
  l_v_addr_con_salutation_tn dbms_xmldom.domnode;
  l_v_addr_con_jobtitle_n dbms_xmldom.domnode;
  l_v_addr_con_jobtitle_tn dbms_xmldom.domnode;
  l_site_addr_cont_ph_node dbms_xmldom.domnode;
  l_site_addr_cont_phasso_node dbms_xmldom.domnode;
  l_v_site_con_addrphtype_n dbms_xmldom.domnode;
  l_v_site_con_addrphtype_tn dbms_xmldom.domnode;
  l_v_site_con_addrphone_n dbms_xmldom.domnode;
  l_v_site_con_addrphareacode_n dbms_xmldom.domnode;
  l_v_site_con_addrphareacode_tn dbms_xmldom.domnode;
  l_v_site_con_addrphcntrycd_n dbms_xmldom.domnode;
  l_v_site_con_addrphcntrycd_tn dbms_xmldom.domnode;
  l_v_site_con_addrphext_n dbms_xmldom.domnode;
  l_v_site_con_addrphext_tn dbms_xmldom.domnode;
  l_v_site_con_addrphpri_n dbms_xmldom.domnode;
  l_v_site_con_addrphpri_tn dbms_xmldom.domnode;
  l_v_add_odphnbrext_n dbms_xmldom.domnode;
  l_v_add_odphnbrext_tn dbms_xmldom.domnode;
  l_v_add_odph800nbr_n dbms_xmldom.domnode;
  l_v_add_odph800nbr_tn dbms_xmldom.domnode;
  l_site_addr_cont_fax_node dbms_xmldom.domnode;
  l_site_addr_cont_faxasso_node dbms_xmldom.domnode;
  l_v_site_con_addrfaxtype_n dbms_xmldom.domnode;
  l_v_site_con_addrfaxtype_tn dbms_xmldom.domnode;
  l_v_site_con_addrfax_n dbms_xmldom.domnode;
  l_v_site_con_addrfaxareacd_n dbms_xmldom.domnode;
  l_v_site_con_addrfaxareacd_tn dbms_xmldom.domnode;
  l_v_site_con_addrfxcntrycd_n dbms_xmldom.domnode;
  l_v_site_con_addrfxcntrycd_tn dbms_xmldom.domnode;
  l_v_site_con_addrfaxext_n dbms_xmldom.domnode;
  l_v_site_con_addrfaxext_tn dbms_xmldom.domnode;
  l_v_site_con_addrfaxpri_n dbms_xmldom.domnode;
  l_v_site_con_addrfaxpri_tn dbms_xmldom.domnode;
  l_site_addr_cont_email_node dbms_xmldom.domnode;
  l_site_addr_cont_emailasso_n dbms_xmldom.domnode;
  l_v_site_con_addremailtype_n dbms_xmldom.domnode;
  l_v_site_con_addremailtype_tn dbms_xmldom.domnode;
  l_v_site_con_addremailpri_n dbms_xmldom.domnode;
  l_v_site_con_addremailpri_tn dbms_xmldom.domnode;
  l_v_addodemailindflg_n dbms_xmldom.domnode;
  l_v_addodemailindflg_tn dbms_xmldom.domnode;
  l_v_addrareacode    VARCHAR2(100) :=NULL; --
  l_v_addrph          VARCHAR2(100) := NULL;--
  l_v_addrfaxareacode VARCHAR2(100) :=NULL;
  l_v_addrfax         VARCHAR2(100) := NULL ;
  l_site_purch_cont_list_node dbms_xmldom.domnode;
  l_site_purch_contact_node dbms_xmldom.domnode;
  l_site_pur_contact_pname_node dbms_xmldom.domnode;
  l_site_pur_cont_ptitle_node dbms_xmldom.domnode;
  l_site_pur_cont_ptitle_tn dbms_xmldom.domnode;
  l_v_pur_con_salutation_n dbms_xmldom.domnode;
  l_v_pur_con_salutation_tn dbms_xmldom.domnode;
  l_v_pur_con_jobtitle_n dbms_xmldom.domnode;
  l_v_pur_con_jobtitle_tn dbms_xmldom.domnode;
  l_site_pur_cont_ph_node dbms_xmldom.domnode;
  l_site_pur_cont_phasso_node dbms_xmldom.domnode;
  l_v_site_con_purchphtype_n dbms_xmldom.domnode;
  l_v_site_con_purchphtype_tn dbms_xmldom.domnode;
  l_v_site_con_purchphone_n dbms_xmldom.domnode;
  l_v_site_con_purphareacode_n dbms_xmldom.domnode;
  l_v_site_con_purphareacode_tn dbms_xmldom.domnode;
  l_v_site_con_purphcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_purphcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_purchphext_n dbms_xmldom.domnode;
  l_v_site_con_purchphext_tn dbms_xmldom.domnode;
  l_v_site_con_purchphpri_n dbms_xmldom.domnode;
  l_v_site_con_purchphpri_tn dbms_xmldom.domnode;
  l_v_odphnbrext_n dbms_xmldom.domnode;
  l_v_odphnbrext_tn dbms_xmldom.domnode;
  l_v_odph800nbr_n dbms_xmldom.domnode;
  l_v_odph800nbr_tn dbms_xmldom.domnode;
  l_v_purareacode VARCHAR2(100) := NULL;
  l_v_purph       VARCHAR2(100) := NULL;
  --  FAX
  l_site_pur_cont_fax_node dbms_xmldom.domnode;
  l_site_pur_cont_faxasso_node dbms_xmldom.domnode;
  l_v_site_con_purchfaxtype_n dbms_xmldom.domnode;
  l_v_site_con_purchfaxtype_tn dbms_xmldom.domnode;
  l_v_site_con_purchfax_n dbms_xmldom.domnode;
  l_v_site_con_purfaxareacode_n dbms_xmldom.domnode;
  l_v_site_con_purfaxareacode_tn dbms_xmldom.domnode;
  l_v_site_con_purfxcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_purfxcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_purchfaxext_n dbms_xmldom.domnode;
  l_v_site_con_purchfaxext_tn dbms_xmldom.domnode;
  l_v_site_con_purchfaxpri_n dbms_xmldom.domnode;
  l_v_site_con_purchfaxpri_tn dbms_xmldom.domnode;
  l_v_purfaxareacode VARCHAR2(100) := NULL;
  l_v_purfax         VARCHAR2(100) := NULL;
  --FAX
  --Email
  l_site_pur_cont_email_node dbms_xmldom.domnode;
  l_site_pur_cont_emailasso_node dbms_xmldom.domnode;
  l_v_site_con_puremailtype_n dbms_xmldom.domnode;
  l_v_site_con_puremailtype_tn dbms_xmldom.domnode;
  l_v_site_con_puremailpri_n dbms_xmldom.domnode;
  l_v_site_con_puremailpri_tn dbms_xmldom.domnode;
  --Email
  l_site_pay_cont_list_node dbms_xmldom.domnode;
  l_site_pay_contact_node dbms_xmldom.domnode;
  l_site_pay_contact_pname_node dbms_xmldom.domnode;
  l_site_pay_cont_ptitle_node dbms_xmldom.domnode;
  l_site_pay_cont_ptitle_tn dbms_xmldom.domnode;
  l_v_pay_con_salutation_n dbms_xmldom.domnode;
  l_v_pay_con_salutation_tn dbms_xmldom.domnode;
  l_v_pay_con_jobtitle_n dbms_xmldom.domnode;
  l_v_pay_con_jobtitle_tn dbms_xmldom.domnode;
  l_site_pay_cont_ph_node dbms_xmldom.domnode;
  l_site_pay_cont_phasso_node dbms_xmldom.domnode;
  l_v_site_con_payphtype_n dbms_xmldom.domnode;
  l_v_site_con_payphtype_tn dbms_xmldom.domnode;
  l_v_site_con_payphone_n dbms_xmldom.domnode;
  l_v_site_con_payphareacode_n dbms_xmldom.domnode;
  l_v_site_con_payphareacode_tn dbms_xmldom.domnode;
  l_v_site_con_payphcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_payphcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_payfxcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_payfxcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_payphext_n dbms_xmldom.domnode;
  l_v_site_con_payphext_tn dbms_xmldom.domnode;
  l_v_site_con_payphpri_n dbms_xmldom.domnode;
  l_v_site_con_payphpri_tn dbms_xmldom.domnode;
  l_site_pay_cont_fax_node dbms_xmldom.domnode;
  l_site_pay_cont_faxasso_node dbms_xmldom.domnode;
  l_v_site_con_payfaxtype_n dbms_xmldom.domnode;
  l_v_site_con_payfaxtype_tn dbms_xmldom.domnode;
  l_v_site_con_payfax_n dbms_xmldom.domnode;
  l_v_site_con_payfaxareacode_n dbms_xmldom.domnode;
  l_v_site_con_payfaxareacode_tn dbms_xmldom.domnode;
  l_v_site_con_payfaxext_n dbms_xmldom.domnode;
  l_v_site_con_payfaxext_tn dbms_xmldom.domnode;
  l_v_site_con_payfaxpri_n dbms_xmldom.domnode;
  l_v_site_con_payfaxpri_tn dbms_xmldom.domnode;
  l_site_pay_cont_email_node dbms_xmldom.domnode;
  l_site_pay_cont_emailasso_node dbms_xmldom.domnode;
  l_v_site_con_payemailtype_n dbms_xmldom.domnode;
  l_v_site_con_payemailtype_tn dbms_xmldom.domnode;
  l_v_site_con_payemailpri_n dbms_xmldom.domnode;
  l_v_site_con_payemailpri_tn dbms_xmldom.domnode;
  l_v_payareacode    VARCHAR2(100) := NULL;
  l_v_payph          VARCHAR2(100) := NULL;
  l_v_payfaxareacode VARCHAR2(100) := NULL;
  l_v_payfax         VARCHAR2(100) := NULL;
  l_site_pp_cont_list_node dbms_xmldom.domnode;
  l_site_pp_contact_node dbms_xmldom.domnode;
  l_site_pp_contact_pname_node dbms_xmldom.domnode;
  l_site_pp_cont_ptitle_node dbms_xmldom.domnode;
  l_site_pp_cont_ptitle_tn dbms_xmldom.domnode;
  l_v_pp_con_salutation_n dbms_xmldom.domnode;
  l_v_pp_con_salutation_tn dbms_xmldom.domnode;
  l_v_pp_con_jobtitle_n dbms_xmldom.domnode;
  l_v_pp_con_jobtitle_tn dbms_xmldom.domnode;
  l_site_pp_cont_ph_node dbms_xmldom.domnode;
  l_site_pp_cont_phasso_node dbms_xmldom.domnode;
  l_v_site_con_ppphtype_n dbms_xmldom.domnode;
  l_v_site_con_ppphtype_tn dbms_xmldom.domnode;
  l_v_site_con_ppphone_n dbms_xmldom.domnode;
  l_v_site_con_ppphareacode_n dbms_xmldom.domnode;
  l_v_site_con_ppphareacode_tn dbms_xmldom.domnode;
  l_v_site_con_ppphcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_ppphcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_ppphext_n dbms_xmldom.domnode;
  l_v_site_con_ppphext_tn dbms_xmldom.domnode;
  l_v_site_con_ppphpri_n dbms_xmldom.domnode;
  l_v_site_con_ppphpri_tn dbms_xmldom.domnode;
  l_site_pp_cont_fax_node dbms_xmldom.domnode;
  l_site_pp_cont_faxasso_node dbms_xmldom.domnode;
  l_v_site_con_ppfaxtype_n dbms_xmldom.domnode;
  l_v_site_con_ppfaxtype_tn dbms_xmldom.domnode;
  l_v_site_con_ppfax_n dbms_xmldom.domnode;
  l_v_site_con_ppfaxareacode_n dbms_xmldom.domnode;
  l_v_site_con_ppfaxareacode_tn dbms_xmldom.domnode;
  l_v_site_con_ppfxcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_ppfxcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_ppfaxext_n dbms_xmldom.domnode;
  l_v_site_con_ppfaxext_tn dbms_xmldom.domnode;
  l_v_site_con_ppfaxpri_n dbms_xmldom.domnode;
  l_v_site_con_ppfaxpri_tn dbms_xmldom.domnode;
  l_v_ppareacode    VARCHAR2(100) :=NULL;
  l_v_ppph          VARCHAR2(100) := NULL;
  l_v_ppfaxareacode VARCHAR2(100) := NULL;
  l_v_ppfax         VARCHAR2(100) :=NULL;
  l_site_pp_cont_email_node dbms_xmldom.domnode;
  l_site_pp_cont_emailasso_node dbms_xmldom.domnode;
  l_v_site_con_ppemailtype_n dbms_xmldom.domnode;
  l_v_site_con_ppemailtype_tn dbms_xmldom.domnode;
  l_v_site_con_ppemailpri_n dbms_xmldom.domnode;
  l_v_site_con_ppemailpri_tn dbms_xmldom.domnode;
  l_site_rtv_cont_list_node dbms_xmldom.domnode;
  l_site_rtv_contact_node dbms_xmldom.domnode;
  l_site_rtv_contact_pname_node dbms_xmldom.domnode;
  l_site_rtv_cont_ptitle_node dbms_xmldom.domnode;
  l_site_rtv_cont_ptitle_tn dbms_xmldom.domnode;
  l_v_rtv_con_salutation_n dbms_xmldom.domnode;
  l_v_rtv_con_salutation_tn dbms_xmldom.domnode;
  l_v_rtv_con_jobtitle_n dbms_xmldom.domnode;
  l_v_rtv_con_jobtitle_tn dbms_xmldom.domnode;
  l_site_rtv_cont_ph_node dbms_xmldom.domnode;
  l_site_rtv_cont_phasso_node dbms_xmldom.domnode;
  l_v_site_con_rtvphtype_n dbms_xmldom.domnode;
  l_v_site_con_rtvphtype_tn dbms_xmldom.domnode;
  l_v_site_con_rtvphone_n dbms_xmldom.domnode;
  l_v_site_con_rtvphareacode_n dbms_xmldom.domnode;
  l_v_site_con_rtvphareacode_tn dbms_xmldom.domnode;
  l_v_site_con_rtvphcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_rtvphcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_rtvphext_n dbms_xmldom.domnode;
  l_v_site_con_rtvphext_tn dbms_xmldom.domnode;
  l_v_site_con_rtvphpri_n dbms_xmldom.domnode;
  l_v_site_con_rtvphpri_tn dbms_xmldom.domnode;
  l_site_rtv_cont_fax_node dbms_xmldom.domnode;
  l_site_rtv_cont_faxasso_node dbms_xmldom.domnode;
  l_v_site_con_rtvfaxtype_n dbms_xmldom.domnode;
  l_v_site_con_rtvfaxtype_tn dbms_xmldom.domnode;
  l_v_site_con_rtvfax_n dbms_xmldom.domnode;
  l_v_site_con_rtvfaxareacode_n dbms_xmldom.domnode;
  l_v_site_con_rtvfaxareacode_tn dbms_xmldom.domnode;
  l_v_site_con_rtvfxcntrycode_n dbms_xmldom.domnode;
  l_v_site_con_rtvfxcntrycode_tn dbms_xmldom.domnode;
  l_v_site_con_rtvfaxext_n dbms_xmldom.domnode;
  l_v_site_con_rtvfaxext_tn dbms_xmldom.domnode;
  l_v_site_con_rtvfaxpri_n dbms_xmldom.domnode;
  l_v_site_con_rtvfaxpri_tn dbms_xmldom.domnode;
  l_site_rtv_cont_email_node dbms_xmldom.domnode;
  l_site_rtv_cont_emailasso_node dbms_xmldom.domnode;
  l_v_site_con_rtvemailtype_n dbms_xmldom.domnode;
  l_v_site_con_rtvemailtype_tn dbms_xmldom.domnode;
  l_v_site_con_rtvemailpri_n dbms_xmldom.domnode;
  l_v_site_con_rtvemailpri_tn dbms_xmldom.domnode;
  l_v_rtvareacode    VARCHAR2(100) := NULL;
  l_v_rtvph          VARCHAR2(100) := NULL;
  l_v_rtvfaxareacode VARCHAR2(100) := NULL;
  l_v_rtvfax         VARCHAR2(100) := NULL;
  l_site_element dbms_xmldom.domelement;
  l_site_node dbms_xmldom.domnode;
  l_vendor_site_id_node dbms_xmldom.domnode;
  l_vendor_site_id_textnode dbms_xmldom.domnode;
  l_vendor_site_code_node dbms_xmldom.domnode;
  l_vendor_site_code_textnode dbms_xmldom.domnode;
  l_vendor_address_flag_node dbms_xmldom.domnode;
  l_vendor_address_flag_textnode dbms_xmldom.domnode;
  l_v_inactive_date_n dbms_xmldom.domnode;
  l_v_inactive_date_tn dbms_xmldom.domnode;
  l_v_pay_cur_code_node dbms_xmldom.domnode;
  l_v_pay_cur_code_textnode dbms_xmldom.domnode;
  l_v_site_lang_node dbms_xmldom.domnode;
  l_v_site_lang_textnode dbms_xmldom.domnode;
  l_v_pay_site_flag_node dbms_xmldom.domnode;
  l_v_pay_site_flag_textnode dbms_xmldom.domnode;
  --
  l_v_purch_site_flag_node dbms_xmldom.domnode;
  l_v_purch_site_flag_textnode dbms_xmldom.domnode;
  l_v_site_terms_name_EBS_n dbms_xmldom.domnode;
  l_v_site_terms_name_ebs_tn dbms_xmldom.domnode;
  l_v_site_terms_name_n dbms_xmldom.domnode;
  l_v_site_terms_name_tn dbms_xmldom.domnode;
  l_v_site_terms_name_desc_n dbms_xmldom.domnode;
  l_v_site_terms_name_desc_tn dbms_xmldom.domnode;
  --NAIT-64249 Added by Sunil
  l_discount_percent_n dbms_xmldom.domnode;
  l_discount_percent_tn dbms_xmldom.domnode;
  l_discount_days_n dbms_xmldom.domnode;
  l_discount_days_tn dbms_xmldom.domnode;
  l_due_days_n dbms_xmldom.domnode;
  l_due_days_tn dbms_xmldom.domnode;
  --NAIT-64249 Added by Sunil
  l_v_site_freightterms_n dbms_xmldom.domnode;
  l_v_site_freightterms_tn dbms_xmldom.domnode;
  l_v_freight_terms_code_n dbms_xmldom.domnode;
  l_v_freight_terms_code_tn dbms_xmldom.domnode;
  l_v_site_fob_lookup_code_n dbms_xmldom.domnode;
  l_v_site_fob_lookup_code_tn dbms_xmldom.domnode;
  l_v_debit_memo_flag_n dbms_xmldom.domnode;
  l_v_debit_memo_flag_tn dbms_xmldom.domnode;
  l_v_duns_num_n dbms_xmldom.domnode;
  l_v_duns_num_tn dbms_xmldom.domnode;
  l_v_tax_reg_num_n dbms_xmldom.domnode;
  l_v_tax_reg_num_tn dbms_xmldom.domnode;
  l_v_vendor_tin_n dbms_xmldom.domnode;
  l_v_vendor_tin_tn dbms_xmldom.domnode;
  l_v_minority_class_n dbms_xmldom.domnode;
  l_v_minority_class_tn dbms_xmldom.domnode;
  l_v_minority_cd_n dbms_xmldom.domnode;
  l_v_minority_cd_tn dbms_xmldom.domnode;
  l_v_minority_cd_desc_n dbms_xmldom.domnode;
  l_v_minority_cd_desc_tn dbms_xmldom.domnode;
  l_v_mbe_n dbms_xmldom.domnode;
  l_v_mbe_tn dbms_xmldom.domnode;
  l_v_mbe_desc_n dbms_xmldom.domnode;
  l_v_mbe_desc_tn dbms_xmldom.domnode;
  l_v_nmsdc_n dbms_xmldom.domnode;
  l_v_nmsdc_tn dbms_xmldom.domnode;
  l_v_nmsdc_desc_n dbms_xmldom.domnode;
  l_v_nmsdc_desc_tn dbms_xmldom.domnode;
  l_v_wbe_n dbms_xmldom.domnode;
  l_v_wbe_tn dbms_xmldom.domnode;
  l_v_wbe_desc_n dbms_xmldom.domnode;
  l_v_wbe_desc_tn dbms_xmldom.domnode;
  l_v_wbenc_n dbms_xmldom.domnode;
  l_v_wbenc_tn dbms_xmldom.domnode;
  l_v_wbenc_desc_n dbms_xmldom.domnode;
  l_v_wbenc_desc_tn dbms_xmldom.domnode;
  l_v_vob_n dbms_xmldom.domnode;
  l_v_vob_tn dbms_xmldom.domnode;
  l_v_vob_desc_n dbms_xmldom.domnode;
  l_v_vob_desc_tn dbms_xmldom.domnode;
  l_v_dodva_n dbms_xmldom.domnode;
  l_v_dodva_tn dbms_xmldom.domnode;
  l_v_dodva_desc_n dbms_xmldom.domnode;
  l_v_dodva_desc_tn dbms_xmldom.domnode;
  l_v_doe_n dbms_xmldom.domnode;
  l_v_doe_tn dbms_xmldom.domnode;
  l_v_doe_desc_n dbms_xmldom.domnode;
  l_v_doe_desc_tn dbms_xmldom.domnode;
  l_v_usbln_n dbms_xmldom.domnode;
  l_v_usbln_tn dbms_xmldom.domnode;
  l_v_usbln_desc_n dbms_xmldom.domnode;
  l_v_usbln_desc_tn dbms_xmldom.domnode;
  l_v_lgbt_n dbms_xmldom.domnode;
  l_v_lgbt_tn dbms_xmldom.domnode;
  l_v_lgbt_desc_n dbms_xmldom.domnode;
  l_v_lgbt_desc_tn dbms_xmldom.domnode;
  l_v_nglcc_n dbms_xmldom.domnode;
  l_v_nglcc_tn dbms_xmldom.domnode;
  l_v_nglcc_desc_n dbms_xmldom.domnode;
  l_v_nglcc_desc_tn dbms_xmldom.domnode;
  l_v_nibnishablty_n dbms_xmldom.domnode;
  l_v_nibnishablty_tn dbms_xmldom.domnode;
  l_v_nibnishablty_desc_n dbms_xmldom.domnode;
  l_v_nibnishablty_desc_tn dbms_xmldom.domnode;
  l_v_fob_n dbms_xmldom.domnode;
  l_v_fob_tn dbms_xmldom.domnode;
  l_v_fob_desc_n dbms_xmldom.domnode;
  l_v_fob_desc_tn dbms_xmldom.domnode;
  l_v_sb_n dbms_xmldom.domnode;
  l_v_sb_tn dbms_xmldom.domnode;
  l_v_sb_desc_n dbms_xmldom.domnode;
  l_v_sb_desc_tn dbms_xmldom.domnode;
  l_v_samgov_n dbms_xmldom.domnode;
  l_v_samgov_tn dbms_xmldom.domnode;
  l_v_samgov_desc_n dbms_xmldom.domnode;
  l_v_samgov_desc_tn dbms_xmldom.domnode;
  l_v_sba_n dbms_xmldom.domnode;
  l_v_sba_tn dbms_xmldom.domnode;
  l_v_sba_desc_n dbms_xmldom.domnode;
  l_v_sba_desc_tn dbms_xmldom.domnode;
  l_v_sbc_n dbms_xmldom.domnode;
  l_v_sbc_tn dbms_xmldom.domnode;
  l_v_sbc_desc_n dbms_xmldom.domnode;
  l_v_sbc_desc_tn dbms_xmldom.domnode;
  l_v_sdbe_n dbms_xmldom.domnode;
  l_v_sdbe_tn dbms_xmldom.domnode;
  l_v_sdbe_desc_n dbms_xmldom.domnode;
  l_v_sdbe_desc_tn dbms_xmldom.domnode;
  l_v_sba8a_n dbms_xmldom.domnode;
  l_v_sba8a_tn dbms_xmldom.domnode;
  l_v_sba8a_desc_n dbms_xmldom.domnode;
  l_v_sba8a_desc_tn dbms_xmldom.domnode;
  l_v_hubzone_n dbms_xmldom.domnode;
  l_v_hubzone_tn dbms_xmldom.domnode;
  l_v_hubzone_desc_n dbms_xmldom.domnode;
  l_v_hubzone_desc_tn dbms_xmldom.domnode;
  l_v_wosb_n dbms_xmldom.domnode;
  l_v_wosb_tn dbms_xmldom.domnode;
  l_v_wosb_desc_n dbms_xmldom.domnode;
  l_v_wosb_desc_tn dbms_xmldom.domnode;
  l_v_wsbe_n dbms_xmldom.domnode;
  l_v_wsbe_tn dbms_xmldom.domnode;
  l_v_wsbe_desc_n dbms_xmldom.domnode;
  l_v_wsbe_desc_tn dbms_xmldom.domnode;
  l_v_edwosb_n dbms_xmldom.domnode;
  l_v_edwosb_tn dbms_xmldom.domnode;
  l_v_edwosb_desc_n dbms_xmldom.domnode;
  l_v_edwosb_desc_tn dbms_xmldom.domnode;
  l_v_vosb_n dbms_xmldom.domnode;
  l_v_vosb_tn dbms_xmldom.domnode;
  l_v_vosb_desc_n dbms_xmldom.domnode;
  l_v_vosb_desc_tn dbms_xmldom.domnode;
  l_v_sdvosb_n dbms_xmldom.domnode;
  l_v_sdvosb_tn dbms_xmldom.domnode;
  l_v_sdvosb_desc_n dbms_xmldom.domnode;
  l_v_sdvosb_desc_tn dbms_xmldom.domnode;
  l_v_hbcumi_n dbms_xmldom.domnode;
  l_v_hbcumi_tn dbms_xmldom.domnode;
  l_v_hbcumi_desc_n dbms_xmldom.domnode;
  l_v_hbcumi_desc_tn dbms_xmldom.domnode;
  l_v_anc_n dbms_xmldom.domnode;
  l_v_anc_tn dbms_xmldom.domnode;
  l_v_anc_desc_n dbms_xmldom.domnode;
  l_v_anc_desc_tn dbms_xmldom.domnode;
  l_v_ind_n dbms_xmldom.domnode;
  l_v_ind_tn dbms_xmldom.domnode;
  l_v_ind_desc_n dbms_xmldom.domnode;
  l_v_ind_desc_tn dbms_xmldom.domnode;
  l_v_minority_owned_n dbms_xmldom.domnode;
  l_v_minority_owned_tn dbms_xmldom.domnode;
  l_v_minority_owned_desc_n dbms_xmldom.domnode;
  l_v_minority_owned_desc_tn dbms_xmldom.domnode;
  --
  l_v_primary_paysite_flag_n dbms_xmldom.domnode;
  l_v_primary_paysite_flag_tn dbms_xmldom.domnode;
  l_v_site_category_n dbms_xmldom.domnode;
  l_v_site_category_tn dbms_xmldom.domnode;
  l_v_bank_account_num_n dbms_xmldom.domnode;
  l_v_bank_account_num_tn dbms_xmldom.domnode;
  l_v_bank_account_name_n dbms_xmldom.domnode;
  l_v_bank_account_name_tn dbms_xmldom.domnode;
  l_v_bank_name_n dbms_xmldom.domnode;
  l_v_bank_name_tn dbms_xmldom.domnode;
  l_v_related_pay_site_n dbms_xmldom.domnode;
  l_v_related_pay_site_tn dbms_xmldom.domnode;
  ----
  l_v_purvendsiteid_n dbms_xmldom.domnode;
  l_v_purvendsiteid_tn dbms_xmldom.domnode;
  l_v_site_puraddr_type_n dbms_xmldom.domnode;
  l_v_site_puraddr_type_tn dbms_xmldom.domnode;
  l_v_site_purseqnum_n dbms_xmldom.domnode;
  l_v_site_purseqnum_tn dbms_xmldom.domnode;
  l_v_site_purpriaddrind_n dbms_xmldom.domnode;
  l_v_site_purpriaddrind_tn dbms_xmldom.domnode;
  l_v_site_puraction_type_n dbms_xmldom.domnode;
  l_v_site_puraction_type_tn dbms_xmldom.domnode;
  l_v_site_pur_isprimaryaddr_n dbms_xmldom.domnode;
  l_v_site_pur_isprimaryaddr_tn dbms_xmldom.domnode;
  l_v_site_purchaddr1_node dbms_xmldom.domnode;
  l_v_site_purchaddr1_textnode dbms_xmldom.domnode;
  l_v_site_purchaddr2_node dbms_xmldom.domnode;
  l_v_site_purchaddr2_textnode dbms_xmldom.domnode;
  l_v_site_purchaddr3_node dbms_xmldom.domnode;
  l_v_site_purchaddr3_textnode dbms_xmldom.domnode;
  l_v_site_purchcity_node dbms_xmldom.domnode;
  l_v_site_purchcity_textnode dbms_xmldom.domnode;
  l_v_site_purchstate_node dbms_xmldom.domnode;
  l_v_site_purchstate_textnode dbms_xmldom.domnode;
  l_v_pur_add_state_abbre_n dbms_xmldom.domnode;
  l_v_pur_add_state_abbre_tn dbms_xmldom.domnode;
  l_v_site_purchzip_node dbms_xmldom.domnode;
  l_v_site_purchzip_textnode dbms_xmldom.domnode;
  l_v_site_purchcountry_node dbms_xmldom.domnode;
  l_v_site_purchcountry_textnode dbms_xmldom.domnode;
  l_v_orgcountry_node dbms_xmldom.domnode; --1
  l_v_orgcountry_textnode dbms_xmldom.domnode;
  l_v_site_pur_add_latitude_n dbms_xmldom.domnode;
  l_v_site_pur_add_latitude_tn dbms_xmldom.domnode;
  l_v_site_pur_add_longitude_n dbms_xmldom.domnode;
  l_v_site_pur_add_longitude_tn dbms_xmldom.domnode;
  l_v_site_pur_add_county_n dbms_xmldom.domnode;
  l_v_site_pur_add_county_tn dbms_xmldom.domnode;
  l_v_site_pur_add_district_n dbms_xmldom.domnode;
  l_v_site_pur_add_district_tn dbms_xmldom.domnode;
  L_V_SITE_PUR_ADD_SPE_NOTES_N DBMS_XMLDOM.DOMNODE;
  l_v_site_pur_add_spe_notes_tn dbms_xmldom.domnode;
  l_v_site_pur_od_comment1_n dbms_xmldom.domnode;
  L_V_SITE_pur_od_comment1_tn dbms_xmldom.domnode;
  l_v_site_pur_od_comment2_n dbms_xmldom.domnode;
  L_V_SITE_pur_od_comment2_tn dbms_xmldom.domnode;
  l_v_site_pur_od_comment3_n dbms_xmldom.domnode;
  L_V_SITE_pur_od_comment3_tn dbms_xmldom.domnode;
  l_v_site_pur_od_comment4_n dbms_xmldom.domnode;
  L_V_SITE_pur_od_comment4_tn dbms_xmldom.domnode;
  L_V_SITE_PUR_SHIP_ADDR_ID_N DBMS_XMLDOM.DOMNODE;
  L_V_SITE_PUR_SHIP_ADDR_ID_TN dbms_xmldom.domnode;
  l_v_site_con_purfname_n dbms_xmldom.domnode;
  l_v_site_con_purfname_tn dbms_xmldom.domnode;
  l_v_site_con_purmname_n dbms_xmldom.domnode;
  l_v_site_con_purmname_tn dbms_xmldom.domnode;
  l_v_site_con_purlname_n dbms_xmldom.domnode;
  l_v_site_con_purlname_tn dbms_xmldom.domnode;
  l_v_site_con_purname_n dbms_xmldom.domnode;
  l_v_site_con_purname_tn dbms_xmldom.domnode;
  l_v_site_con_purchph_n dbms_xmldom.domnode;
  l_v_site_con_purchph_tn dbms_xmldom.domnode;
  l_v_site_con_purchfx_n dbms_xmldom.domnode;
  l_v_site_con_purchfx_tn dbms_xmldom.domnode;
  l_v_site_con_purchemail_n dbms_xmldom.domnode;
  l_v_site_con_purchemail_tn dbms_xmldom.domnode;
  l_v_purodemailindflg_n dbms_xmldom.domnode;
  l_v_purodemailindflg_tn dbms_xmldom.domnode;
  --
  l_v_site_payaddr_type_n dbms_xmldom.domnode;
  l_v_site_payaddr_type_tn dbms_xmldom.domnode;
  l_v_site_payseqnum_n dbms_xmldom.domnode;
  l_v_site_payseqnum_tn dbms_xmldom.domnode;
  l_v_site_payaction_type_n dbms_xmldom.domnode;
  l_v_site_payaction_type_tn dbms_xmldom.domnode;
  l_v_site_pay_isprimaryaddr_n dbms_xmldom.domnode;
  l_v_site_pay_isprimaryaddr_tn dbms_xmldom.domnode;
  l_v_site_payaddr1_node dbms_xmldom.domnode;
  l_v_site_payaddr1_textnode dbms_xmldom.domnode;
  l_v_site_payaddr2_node dbms_xmldom.domnode;
  l_v_site_payaddr2_textnode dbms_xmldom.domnode;
  l_v_site_payaddr3_node dbms_xmldom.domnode;
  l_v_site_payaddr3_textnode dbms_xmldom.domnode;
  l_v_site_paycity_node dbms_xmldom.domnode;
  l_v_site_paycity_textnode dbms_xmldom.domnode;
  l_v_site_paystate_node dbms_xmldom.domnode;
  l_v_site_paystate_textnode dbms_xmldom.domnode;
  l_v_pay_add_state_abbre_n dbms_xmldom.domnode;
  l_v_pay_add_state_abbre_tn dbms_xmldom.domnode;
  l_v_site_payzip_node dbms_xmldom.domnode;
  l_v_site_payzip_textnode dbms_xmldom.domnode;
  l_v_site_paycountry_node dbms_xmldom.domnode;
  l_v_site_paycountry_textnode dbms_xmldom.domnode;
  l_v_site_pay_add_latitude_n dbms_xmldom.domnode;
  l_v_site_pay_add_latitude_tn dbms_xmldom.domnode;
  l_v_site_pay_add_longitude_n dbms_xmldom.domnode;
  l_v_site_pay_add_longitude_tn dbms_xmldom.domnode;
  l_v_site_pay_add_county_n dbms_xmldom.domnode;
  l_v_site_pay_add_county_tn dbms_xmldom.domnode;
  l_v_site_pay_add_district_n dbms_xmldom.domnode;
  l_v_site_pay_add_district_tn dbms_xmldom.domnode;
  L_V_SITE_PAY_ADD_SPE_NOTES_N DBMS_XMLDOM.DOMNODE;
  l_v_site_pay_add_spe_notes_tn dbms_xmldom.domnode;
  L_V_SITE_pay_SHIP_ADDR_ID_N dbms_xmldom.domnode;
  L_V_SITE_pay_SHIP_ADDR_ID_tN dbms_xmldom.domnode;
  l_v_site_con_payfname_n dbms_xmldom.domnode;
  l_v_site_con_payfname_tn dbms_xmldom.domnode;
  l_v_site_con_paymname_n dbms_xmldom.domnode;
  l_v_site_con_paymname_tn dbms_xmldom.domnode;
  l_v_site_con_paylname_n dbms_xmldom.domnode;
  l_v_site_con_paylname_tn dbms_xmldom.domnode;
  l_v_site_con_payname_n dbms_xmldom.domnode;
  l_v_site_con_payname_tn dbms_xmldom.domnode;
  l_v_site_con_payph_n dbms_xmldom.domnode;
  l_v_site_con_payph_tn dbms_xmldom.domnode;
  l_v_site_con_payfx_n dbms_xmldom.domnode;
  l_v_site_con_payfx_tn dbms_xmldom.domnode;
  l_v_site_con_payemail_n dbms_xmldom.domnode;
  l_v_site_con_payemail_tn dbms_xmldom.domnode;
  --
  l_v_site_ppaddr_type_n dbms_xmldom.domnode;
  l_v_site_ppaddr_type_tn dbms_xmldom.domnode;
  l_v_site_ppseqnum_n dbms_xmldom.domnode;
  l_v_site_ppseqnum_tn dbms_xmldom.domnode;
  l_v_site_ppaction_type_n dbms_xmldom.domnode;
  l_v_site_ppaction_type_tn dbms_xmldom.domnode;
  l_v_site_pp_isprimaryaddr_n dbms_xmldom.domnode;
  l_v_site_pp_isprimaryaddr_tn dbms_xmldom.domnode;
  l_v_site_ppaddr1_node dbms_xmldom.domnode;
  l_v_site_ppaddr1_textnode dbms_xmldom.domnode;
  l_v_site_ppaddr2_node dbms_xmldom.domnode;
  l_v_site_ppaddr2_textnode dbms_xmldom.domnode;
  l_v_site_ppaddr3_node dbms_xmldom.domnode;
  l_v_site_ppaddr3_textnode dbms_xmldom.domnode;
  l_v_site_ppcity_node dbms_xmldom.domnode;
  l_v_site_ppcity_textnode dbms_xmldom.domnode;
  l_v_site_ppstate_node dbms_xmldom.domnode;
  l_v_site_ppstate_textnode dbms_xmldom.domnode;
  l_v_pp_add_state_abbre_n dbms_xmldom.domnode;
  l_v_pp_add_state_abbre_tn dbms_xmldom.domnode;
  l_v_site_ppzip_node dbms_xmldom.domnode;
  l_v_site_ppzip_textnode dbms_xmldom.domnode;
  l_v_site_ppcountry_node dbms_xmldom.domnode;
  l_v_site_ppcountry_textnode dbms_xmldom.domnode;
  l_v_site_pp_add_latitude_n dbms_xmldom.domnode;
  l_v_site_pp_add_latitude_tn dbms_xmldom.domnode;
  l_v_site_pp_add_longitude_n dbms_xmldom.domnode;
  l_v_site_pp_add_longitude_tn dbms_xmldom.domnode;
  l_v_site_pp_add_county_n dbms_xmldom.domnode;
  l_v_site_pp_add_county_tn dbms_xmldom.domnode;
  l_v_site_pp_add_district_n dbms_xmldom.domnode;
  l_v_site_pp_add_district_tn dbms_xmldom.domnode;
  L_V_SITE_PP_ADD_SPE_NOTES_N DBMS_XMLDOM.DOMNODE;
  l_v_site_pp_add_spe_notes_tn dbms_xmldom.domnode;
  L_V_SITE_pp_SHIP_ADDR_ID_N dbms_xmldom.domnode;
  L_V_SITE_pp_SHIP_ADDR_ID_tN dbms_xmldom.domnode;
  l_v_site_con_ppfname_n dbms_xmldom.domnode;
  l_v_site_con_ppfname_tn dbms_xmldom.domnode;
  l_v_site_con_ppmname_n dbms_xmldom.domnode;
  l_v_site_con_ppmname_tn dbms_xmldom.domnode;
  l_v_site_con_pplname_n dbms_xmldom.domnode;
  l_v_site_con_pplname_tn dbms_xmldom.domnode;
  l_v_site_con_ppname_n dbms_xmldom.domnode;
  l_v_site_con_ppname_tn dbms_xmldom.domnode;
  l_v_site_con_ppph_n dbms_xmldom.domnode;
  l_v_site_con_ppph_tn dbms_xmldom.domnode;
  l_v_site_con_ppfx_n dbms_xmldom.domnode;
  l_v_site_con_ppfx_tn dbms_xmldom.domnode;
  l_v_site_con_ppemail_n dbms_xmldom.domnode;
  l_v_site_con_ppemail_tn dbms_xmldom.domnode;
  --
  l_v_site_rtvaddr_type_n dbms_xmldom.domnode;
  l_v_site_rtvaddr_type_tn dbms_xmldom.domnode;
  l_v_site_rtvseqnum_n dbms_xmldom.domnode;
  l_v_site_rtvseqnum_tn dbms_xmldom.domnode;
  l_v_site_rtvaction_type_n dbms_xmldom.domnode;
  l_v_site_rtvaction_type_tn dbms_xmldom.domnode;
  l_v_site_rtv_isprimaryaddr_n dbms_xmldom.domnode;
  l_v_site_rtv_isprimaryaddr_tn dbms_xmldom.domnode;
  l_v_site_rtvaddr1_node dbms_xmldom.domnode;
  l_v_site_rtvaddr1_textnode dbms_xmldom.domnode;
  l_v_site_rtvaddr2_node dbms_xmldom.domnode;
  l_v_site_rtvaddr2_textnode dbms_xmldom.domnode;
  l_v_site_rtvaddr3_node dbms_xmldom.domnode;
  l_v_site_rtvaddr3_textnode dbms_xmldom.domnode;
  l_v_site_rtvcity_node dbms_xmldom.domnode;
  l_v_site_rtvcity_textnode dbms_xmldom.domnode;
  l_v_site_rtvstate_node dbms_xmldom.domnode;
  l_v_site_rtvstate_textnode dbms_xmldom.domnode;
  l_v_rtv_add_state_abbre_n dbms_xmldom.domnode;
  l_v_rtv_add_state_abbre_tn dbms_xmldom.domnode;
  l_v_site_rtvzip_node dbms_xmldom.domnode;
  l_v_site_rtvzip_textnode dbms_xmldom.domnode;
  l_v_site_rtvcountry_node dbms_xmldom.domnode;
  l_v_site_rtvcountry_textnode dbms_xmldom.domnode;
  l_v_site_rtv_add_latitude_n dbms_xmldom.domnode;
  l_v_site_rtv_add_latitude_tn dbms_xmldom.domnode;
  l_v_site_rtv_add_longitude_n dbms_xmldom.domnode;
  l_v_site_rtv_add_longitude_tn dbms_xmldom.domnode;
  l_v_site_rtv_add_county_n dbms_xmldom.domnode;
  l_v_site_rtv_add_county_tn dbms_xmldom.domnode;
  L_V_SITE_RTV_ADD_DISTRICT_N DBMS_XMLDOM.DOMNODE;
  l_v_site_rtv_add_district_tn dbms_xmldom.domnode;
  l_v_site_rtv_add_spe_notes_n dbms_xmldom.domnode;
  L_V_SITE_RTV_ADD_SPE_NOTES_TN DBMS_XMLDOM.DOMNODE;
  L_V_SITE_RTV_SHIP_ADDR_ID_N dbms_xmldom.domnode;
  L_V_SITE_RTV_SHIP_ADDR_ID_tN dbms_xmldom.domnode;
  l_v_site_con_rtvfname_n dbms_xmldom.domnode;
  l_v_site_con_rtvfname_tn dbms_xmldom.domnode;
  l_v_site_con_rtvmname_n dbms_xmldom.domnode;
  l_v_site_con_rtvmname_tn dbms_xmldom.domnode;
  l_v_site_con_rtvlname_n dbms_xmldom.domnode;
  l_v_site_con_rtvlname_tn dbms_xmldom.domnode;
  l_v_site_con_rtvname_n dbms_xmldom.domnode;
  l_v_site_con_rtvname_tn dbms_xmldom.domnode;
  l_v_site_con_rtvph_n dbms_xmldom.domnode;
  l_v_site_con_rtvph_tn dbms_xmldom.domnode;
  l_v_site_con_rtvfx_n dbms_xmldom.domnode;
  l_v_site_con_rtvfx_tn dbms_xmldom.domnode;
  l_v_site_con_rtvemail_n dbms_xmldom.domnode;
  l_v_site_con_rtvemail_tn dbms_xmldom.domnode;
  --Custom address
  l_v_addvendsiteid_n dbms_xmldom.domnode;
  l_v_addvendsiteid_tn dbms_xmldom.domnode;
  l_v_addr_01_addr_type_node dbms_xmldom.domnode;
  l_v_addr_01_addr_type_textnode dbms_xmldom.domnode;
  l_v_site_addr_01_seqnum_n dbms_xmldom.domnode;
  l_v_site_addr_01_seqnum_tn dbms_xmldom.domnode;
  l_v_add_priaddrind_n dbms_xmldom.domnode;
  l_v_add_priaddrind_tn dbms_xmldom.domnode;
  l_v_site_addr_action_type_n dbms_xmldom.domnode;
  l_v_site_addr_action_type_tn dbms_xmldom.domnode;
  l_v_cust_add_isprimaryaddr_n dbms_xmldom.domnode;
  l_v_cust_add_isprimaryaddr_tn dbms_xmldom.domnode;
  ---------------------
  l_v_addr1_node dbms_xmldom.domnode;
  l_v_addr1_textnode dbms_xmldom.domnode;
  l_v_addr2_node dbms_xmldom.domnode;
  l_v_addr2_textnode dbms_xmldom.domnode;
  l_v_addr3_node dbms_xmldom.domnode;
  l_v_addr3_textnode dbms_xmldom.domnode;
  l_v_addr_city_node dbms_xmldom.domnode;
  l_v_addr_city_textnode dbms_xmldom.domnode;
  l_v_addr_state_node dbms_xmldom.domnode;
  l_v_addr_state_textnode dbms_xmldom.domnode;
  l_v_add_state_abbre_n dbms_xmldom.domnode;
  l_v_add_state_abbre_tn dbms_xmldom.domnode;
  l_v_addr_zip_node dbms_xmldom.domnode;
  l_v_addr_zip_textnode dbms_xmldom.domnode;
  l_v_addr_country_node dbms_xmldom.domnode;
  l_v_addr_country_textnode dbms_xmldom.domnode;
  l_v_add_latitude_n dbms_xmldom.domnode;
  l_v_add_latitude_tn dbms_xmldom.domnode;
  l_v_add_longitude_n dbms_xmldom.domnode;
  l_v_add_longitude_tn dbms_xmldom.domnode;
  l_v_add_county_n dbms_xmldom.domnode;
  l_v_add_county_tn dbms_xmldom.domnode;
  l_v_add_district_n dbms_xmldom.domnode;
  L_V_ADD_DISTRICT_TN DBMS_XMLDOM.DOMNODE;
  l_v_add_spe_notes_n dbms_xmldom.domnode;
  L_V_OD_SHIP_FROM_ADDR_ID_n DBMS_XMLDOM.DOMNODE;
  l_v_od_ship_from_addr_id_tn dbms_xmldom.domnode;
  l_v_add_spe_notes_tn dbms_xmldom.domnode;
  --
  L_V_SITE_add_od_comment1_n dbms_xmldom.domnode;
  L_V_SITE_add_od_comment1_tn dbms_xmldom.domnode;
  L_V_SITE_add_od_comment2_n dbms_xmldom.domnode;
  L_V_SITE_add_od_comment2_tn dbms_xmldom.domnode;
  L_V_SITE_add_od_comment3_n dbms_xmldom.domnode;
  L_V_SITE_add_od_comment3_tn dbms_xmldom.domnode;
  L_V_SITE_add_od_comment4_n dbms_xmldom.domnode;
  L_V_SITE_add_od_comment4_tn dbms_xmldom.domnode;
  --
  l_v_site_con_addfname_n dbms_xmldom.domnode;
  l_v_site_con_addfname_tn dbms_xmldom.domnode;
  l_v_site_con_addmname_n dbms_xmldom.domnode;
  l_v_site_con_addmname_tn dbms_xmldom.domnode;
  l_v_site_con_addlname_n dbms_xmldom.domnode;
  l_v_site_con_addlname_tn dbms_xmldom.domnode;
  l_v_addr_con_name_node dbms_xmldom.domnode;
  l_v_addr_con_name_textnode dbms_xmldom.domnode;
  l_v_addr_con_ph_node dbms_xmldom.domnode;
  l_v_addr_con_ph_textnode dbms_xmldom.domnode;
  l_v_addr_con_fax_node dbms_xmldom.domnode;
  l_v_addr_con_fax_textnode dbms_xmldom.domnode;
  l_v_addr_con_email_node dbms_xmldom.domnode;
  l_v_addr_con_email_textnode dbms_xmldom.domnode;
  --------------------
  --Custom Address
  ---kff
  l_v_lead_time_node dbms_xmldom.domnode;
  l_v_lead_time_textnode dbms_xmldom.domnode;
  l_v_back_order_flag_node dbms_xmldom.domnode;
  l_v_back_order_flag_textnode dbms_xmldom.domnode;
  l_v_delivery_policy_node dbms_xmldom.domnode;
  l_v_delivery_policy_textnode dbms_xmldom.domnode;
  l_v_min_prepaid_code_node dbms_xmldom.domnode;
  l_v_min_prepaid_code_textnode dbms_xmldom.domnode;
  l_v_vendor_min_amount_node dbms_xmldom.domnode;
  l_v_vendor_min_amount_textnode dbms_xmldom.domnode;
  l_v_supplier_ship_to_node dbms_xmldom.domnode;
  l_v_supplier_ship_to_textnode dbms_xmldom.domnode;
  l_v_inventory_type_code_n dbms_xmldom.domnode;
  l_v_inventory_type_code_tn dbms_xmldom.domnode;
  l_v_ver_market_indicator_n dbms_xmldom.domnode;
  l_v_ver_market_indicator_tn dbms_xmldom.domnode;
  l_v_allow_auto_receipt_n dbms_xmldom.domnode;
  l_v_allow_auto_receipt_tn dbms_xmldom.domnode;
  l_v_handling_node dbms_xmldom.domnode;
  l_v_handling_textnode dbms_xmldom.domnode;
  l_v_eft_settle_days_node dbms_xmldom.domnode;
  l_v_eft_settle_days_textnode dbms_xmldom.domnode;
  l_v_split_file_flag_node dbms_xmldom.domnode;
  l_v_split_file_flag_textnode dbms_xmldom.domnode;
  l_v_master_vendor_id_node dbms_xmldom.domnode;
  l_v_master_vendor_id_textnode dbms_xmldom.domnode;
  l_v_pi_pack_year_node dbms_xmldom.domnode;
  l_v_pi_pack_year_textnode dbms_xmldom.domnode;
  l_v_od_date_signed_n dbms_xmldom.domnode;
  l_v_od_date_signed_tn dbms_xmldom.domnode;
  l_v_ven_date_signed_n dbms_xmldom.domnode;
  l_v_ven_date_signed_tn dbms_xmldom.domnode;
  l_v_deduct_from_inv_flag_n dbms_xmldom.domnode;
  l_v_deduct_from_inv_flag_tn dbms_xmldom.domnode;
  l_v_new_store_flag_node dbms_xmldom.domnode;
  l_v_new_store_flag_textnode dbms_xmldom.domnode;
  l_v_new_store_terms_node dbms_xmldom.domnode;
  l_v_new_store_terms_textnode dbms_xmldom.domnode;
  l_v_seasonal_flag_node dbms_xmldom.domnode;
  l_v_seasonal_flag_textnode dbms_xmldom.domnode;
  l_v_start_date_node dbms_xmldom.domnode;
  l_v_start_date_textnode dbms_xmldom.domnode;
  l_v_end_date_node dbms_xmldom.domnode;
  l_v_end_date_textnode dbms_xmldom.domnode;
  l_v_seasonal_terms_node dbms_xmldom.domnode;
  l_v_seasonal_terms_textnode dbms_xmldom.domnode;
  l_v_late_ship_flag_node dbms_xmldom.domnode;
  l_v_late_ship_flag_textnode dbms_xmldom.domnode;
  l_v_edi_distri_code_n dbms_xmldom.domnode;
  l_v_edi_distri_code_tn dbms_xmldom.domnode;
  l_v_850_po_node dbms_xmldom.domnode;
  l_v_850_po_textnode dbms_xmldom.domnode;
  l_v_860_po_change_n dbms_xmldom.domnode;
  l_v_860_po_change_tn dbms_xmldom.domnode;
  l_v_855_confirm_po_n dbms_xmldom.domnode;
  l_v_855_confirm_po_tn dbms_xmldom.domnode;
  l_v_856_asn_node dbms_xmldom.domnode;
  l_v_856_asn_textnode dbms_xmldom.domnode;
  l_v_846_availability_node dbms_xmldom.domnode;
  l_v_846_availability_textnode dbms_xmldom.domnode;
  l_v_810_invoice_node dbms_xmldom.domnode;
  l_v_810_invoice_textnode dbms_xmldom.domnode;
  l_v_832_price_sales_cat_n dbms_xmldom.domnode;
  l_v_832_price_sales_cat_tn dbms_xmldom.domnode;
  l_v_820_eft_node dbms_xmldom.domnode;
  l_v_820_eft_textnode dbms_xmldom.domnode;
  l_v_861_damage_shortage_n dbms_xmldom.domnode;
  l_v_861_damage_shortage_tn dbms_xmldom.domnode;
  l_v_852_sales_node dbms_xmldom.domnode;
  l_v_852_sales_textnode dbms_xmldom.domnode;
  l_v_rtv_option_node dbms_xmldom.domnode;
  l_v_rtv_option_textnode dbms_xmldom.domnode;
  l_v_rtv_freight_pay_method_n dbms_xmldom.domnode;
  l_v_rtv_freight_pay_method_tn dbms_xmldom.domnode;
  l_v_permanent_rga_node dbms_xmldom.domnode;
  l_v_permanent_rga_textnode dbms_xmldom.domnode;
  l_v_destroy_allow_amt_n dbms_xmldom.domnode;
  l_v_destroy_allow_amt_tn dbms_xmldom.domnode;
  l_v_payment_freq_n dbms_xmldom.domnode;
  l_v_payment_freq_tn dbms_xmldom.domnode;
  l_v_min_return_qty_node dbms_xmldom.domnode;
  l_v_min_return_qty_textnode dbms_xmldom.domnode;
  l_v_min_return_amount_node dbms_xmldom.domnode;
  l_v_min_return_amount_textnode dbms_xmldom.domnode;
  l_v_damage_dest_limit_n dbms_xmldom.domnode;
  l_v_damage_dest_limit_tn dbms_xmldom.domnode;
  l_v_rtv_instr_n dbms_xmldom.domnode;
  l_v_rtv_instr_tn dbms_xmldom.domnode;
  l_v_addl_rtv_instr_n dbms_xmldom.domnode;
  l_v_addl_rtv_instr_tn dbms_xmldom.domnode;
  l_v_rga_marked_flag_n dbms_xmldom.domnode;
  l_v_rga_marked_flag_tn dbms_xmldom.domnode;
  l_v_rmv_price_sticker_flag_n dbms_xmldom.domnode;
  l_v_rmv_price_sticker_flag_tn dbms_xmldom.domnode;
  l_v_con_supp_rga_flag_n dbms_xmldom.domnode;
  l_v_con_supp_rga_flag_tn dbms_xmldom.domnode;
  l_v_destroy_flag_node dbms_xmldom.domnode;
  l_v_destroy_flag_textnode dbms_xmldom.domnode;
  l_v_ser_num_req_flag_n dbms_xmldom.domnode;
  l_v_ser_num_req_flag_tn dbms_xmldom.domnode;
  l_v_obsolete_item_n dbms_xmldom.domnode;
  l_v_obsolete_item_tn dbms_xmldom.domnode;
  l_v_obso_allow_pct_n dbms_xmldom.domnode;
  l_v_obso_allow_pct_tn dbms_xmldom.domnode;
  l_v_obso_allow_days_n dbms_xmldom.domnode;
  l_v_obso_allow_days_tn dbms_xmldom.domnode;
  l_v_od_cont_sig_n dbms_xmldom.domnode;
  l_v_od_cont_sig_tn dbms_xmldom.domnode;
  l_v_od_cont_title_n dbms_xmldom.domnode;
  l_v_od_cont_title_tn dbms_xmldom.domnode;
  l_v_od_ven_sig_name_n dbms_xmldom.domnode;
  l_v_od_ven_sig_name_tn dbms_xmldom.domnode;
  l_v_od_ven_sig_title_n dbms_xmldom.domnode;
  l_v_od_ven_sig_title_tn dbms_xmldom.domnode;
  l_v_gss_mfg_id_n dbms_xmldom.domnode;
  l_v_gss_mfg_id_tn dbms_xmldom.domnode;
  l_v_gss_buying_agent_id_n dbms_xmldom.domnode;
  l_v_gss_buying_agent_id_tn dbms_xmldom.domnode;
  l_v_gss_freight_id_n dbms_xmldom.domnode;
  l_v_gss_freight_id_tn dbms_xmldom.domnode;
  l_v_gss_ship_id_n dbms_xmldom.domnode;
  l_v_gss_ship_id_tn dbms_xmldom.domnode;
  v_transaction_id NUMBER;
  sup_trait_rows   NUMBER :=0;
  --Cursor for custom address details
  CURSOR c_address_data
  IS
  WITH supp AS
    (SELECT
      /*+ materialize */
      a.vendor_site_id,
      1 seq_no,
      'Y' primary_addr_ind,
      a.address_line1,
      a.address_line2,
      a.address_line3,
      a.city,
      upper(a.state) state,
      a.zip,
      NVL(a.country, 'US') country,
      b.first_name
      ||' '
      ||b.last_name contact_name,
      REPLACE(a.area_code
      ||a.phone,'-') phone,
      REPLACE(b.fax_area_code
      ||b.fax,'-') fax,
      b.email_address,
      0 od_phone_nbr_ext,
      NULL od_phone_800_nbr,
      NULL od_comment1,
      NULL od_comment2,
      NULL od_comment3,
      NULL od_comment4,
      'N' email_ind_flg,
      NULL od_ship_from_addr_id,
      a.purchasing_site_flag,
      a.pay_site_flag
    FROM ap_supplier_sites_all a,
      po_vendor_contacts b
    WHERE a.vendor_site_id                = b.vendor_site_id(+)
    AND ltrim(a.vendor_site_code_alt,'0') = ltrim(v_vendor_site_code_alt,'0')
    AND a.org_id                          =v_site_orgid
    )
SELECT key_value_1,
  address_type,
  seq_no,
  primary_addr_ind,
  add_1,
  add_2,
  add_3,
  city,
  state,
  post ,
  country_id,
  contact_name,
  contact_phone,
  contact_fax,
  contact_email,
  od_phone_nbr_ext,
  od_phone_800_nbr,
  od_comment_1,
  od_comment_2,
  od_comment_3,
  od_comment_4,
  od_email_ind_flg,
  od_ship_from_addr_id
FROM xx_ap_sup_vendor_contact vend_cont,
  xx_ap_sup_address_type addr_type
WHERE ltrim(vend_cont.key_value_1,'0') = ltrim(v_vendor_site_code_alt,'0')
AND vend_cont.addr_type_id             =addr_type.addr_type_id
AND vend_cont.enable_flag              ='Y'
AND addr_type.enable_flag              ='Y'
UNION ALL
SELECT a.vendor_site_id,
  CASE
    WHEN purchasing_site_flag = 'N'
    AND pay_site_flag         = 'N'
    THEN 3 -- RTV
    ELSE
      CASE
        WHEN purchasing_site_flag = 'Y'
        AND pay_site_flag         = 'N'
        THEN 4 -- PR
        ELSE
          CASE
            WHEN purchasing_site_flag = 'N'
            AND pay_site_flag         = 'Y'
            THEN 5 -- PY
          END
      END
  END address_type,
  seq_no,
  primary_addr_ind,
  a.address_line1,
  a.address_line2,
  a.address_line3,
  a.city,
  a.state,
  a.zip,
  a.country,
  contact_name,
  phone,
  fax,
  email_address,
  od_phone_nbr_ext,
  od_phone_800_nbr,
  od_comment1,
  od_comment2,
  od_comment3,
  od_comment4,
  email_ind_flg,
  od_ship_from_addr_id
FROM supp a
WHERE (a.purchasing_site_flag <> 'Y'
OR a.pay_site_flag            <> 'Y')
UNION ALL
SELECT a.vendor_site_id,
  seq + 3 address_type,
  seq_no,
  primary_addr_ind,
  a.address_line1,
  a.address_line2,
  a.address_line3,
  a.city,
  a.state,
  a.zip,
  a.country,
  contact_name,
  phone,
  fax,
  email_address,
  od_phone_nbr_ext,
  od_phone_800_nbr,
  od_comment1,
  od_comment2,
  od_comment3,
  od_comment4,
  email_ind_flg,
  od_ship_from_addr_id
FROM supp a,
  (SELECT level seq FROM dual CONNECT BY level < 3
  )
WHERE (a.purchasing_site_flag = 'Y'
AND a.pay_site_flag           = 'Y')
ORDER BY 2,3;
--
--Cursor for Business Classification codes and meaning.
CURSOR c_bus_class
IS
  SELECT attribute1,
    meaning
  FROM fnd_lookup_values_vl
  WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
  AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
  ORDER BY to_number(attribute1);
--
--Cursor for Supplier Traits and descriptions
CURSOR c_sup_traits
IS
  SELECT traits.sup_trait sup_trait,
    traits.description description,
    traits.master_sup_ind master_sup_ind
  FROM xx_ap_sup_traits traits ,
    xx_ap_sup_traits_matrix matrix
  WHERE traits.sup_trait_id=matrix.sup_trait_id
  AND traits.enable_flag   ='Y'
  AND matrix.enable_flag   ='Y'
  AND matrix.supplier      = NVL(TO_NUMBER(LTRIM(v_vendor_site_code_alt,'0')), v_vendor_site_id); --v_vendor_site_id;
BEGIN
  --Generate unique transaction id for every transaction
  SELECT xx_ap_sup_trans_seq.nextval
  INTO v_transaction_id
  FROM dual;
  
  --Insert into custom table for tracking purpose
  /*  INSERT
  INTO xx_ap_sup_outbound_track VALUES
  (
  v_transaction_id,
  v_globalvendor_id,
  v_name,
  v_vendor_site_id,
  v_vendor_site_code,
  v_site_orgid,
  sysdate,1,1,'A',1,'A','A'
  );*/
  
  IF v_site_orgid = 403 THEN
    v_orgcountry := 'CA';
  END IF;
  IF v_site_orgid = 404 THEN
    v_orgcountry := 'US';
  END IF;

  -- Create an empty XML document
  l_domdoc := dbms_xmldom.newdomdocument;

  -- Create a root node
  l_root_node                 := dbms_xmldom.makenode(l_domdoc);
  l_supplier_list_req_element :=dbms_xmldom.createelement(l_domdoc, 'sup:publishSupplierListRequest' );
  l_supplier_list_req_node    := dbms_xmldom.appendchild(l_root_node,dbms_xmldom.makenode(l_supplier_list_req_element));
  dbms_xmldom.setattribute(l_supplier_list_req_element, 'xmlns:sup', 'http://www.officedepot.com/service/SupplierSyncService');
  dbms_xmldom.setattribute(l_supplier_list_req_element, 'xmlns:odc', 'http://eai.officedepot.com/model/ODCommon');

  -- Create a new node Supplier and add it to the root node
  l_supplier_list_node := dbms_xmldom.appendchild( l_supplier_list_req_node--l_root_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierList' )) );

  -- Create a new node supplier and add it to the supplierList node
  l_supplier_node := dbms_xmldom.appendchild( l_supplier_list_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplier' )) );

  -- Create a new node supplier header and add it to the supplier node
  l_supp_header_node := dbms_xmldom.appendchild( l_supplier_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierHeader' )) );

  -- Each Supp node will get a Name node which contains the Supplier name as text
  l_trans_id_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:transactionId' )) );
  l_trans_id_textnode := dbms_xmldom.appendchild( l_trans_id_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_transaction_id )) );

  -- Each Supp node will get a globalvendorid
  l_globalvendor_id_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:globalVendorId' )) );
  l_globalvendor_id_tn := dbms_xmldom.appendchild( l_globalvendor_id_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_globalvendor_id )) );

  -- Each Supp node will get a Supplier Number--Added for NAIT-56518
  l_suppliernumber_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierNumber' )) );
  l_suppliernumber_tn := dbms_xmldom.appendchild( l_suppliernumber_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_supplier_number )) );

  -- Each Supp node will get a Name node which contains the Supplier name as text
  l_name_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vendorName' )) );
  l_name_textnode := dbms_xmldom.appendchild( l_name_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_name )) );

  -- Each Site node will get a Vendor Site Id
  l_vendor_site_id_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vendorSiteId' )) );
  l_vendor_site_id_textnode := dbms_xmldom.appendchild( l_vendor_site_id_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_vendor_site_id)) );

  -- Each site node will get a Vendor Site Code
  l_vendor_site_code_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vendorSiteCode' )) );
  l_vendor_site_code_textnode := dbms_xmldom.appendchild( l_vendor_site_code_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_vendor_site_code)) );

  -- Each Site node will get a Inactive date
  l_v_inactive_date_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:inactiveDate' )) );
  l_v_inactive_date_tn := dbms_xmldom.appendchild( l_v_inactive_date_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_inactive_date)) );

  -- Each Site node will get a Payment_Currency Code
  l_v_pay_cur_code_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:paymentCurrencyCode' )) );
  l_v_pay_cur_code_textnode := dbms_xmldom.appendchild( l_v_pay_cur_code_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_payment_currency_code)) );

  -- Each Site node will get a Site Language
  l_v_site_lang_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteLanguage' )) );
  l_v_site_lang_textnode := dbms_xmldom.appendchild( l_v_site_lang_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_lang)) );

  -- Each Site node will get a Pay Site Flag
  l_v_pay_site_flag_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:paySiteFlag' )) );
  l_v_pay_site_flag_textnode := dbms_xmldom.appendchild( l_v_pay_site_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_pay_site_flag)) );

  -- Each Site node will get a Purchasing Site Flag
  l_v_purch_site_flag_node := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:purchasingSiteFlag' )) );
  l_v_purch_site_flag_textnode := dbms_xmldom.appendchild( l_v_purch_site_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_purchasing_site_flag)) );

  --siteTermsNameEBS
  -- Each Site node will get a site Terms Name EBS
  l_v_site_terms_name_EBS_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteTermsNameEBS' )) );
  l_v_site_terms_name_EBS_tn := dbms_xmldom.appendchild( l_v_site_terms_name_EBS_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_terms_name_1)) );

  -- Each Site node will get a site Terms Name
  l_v_site_terms_name_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteTermsName' )) );
  l_v_site_terms_name_tn := dbms_xmldom.appendchild( l_v_site_terms_name_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_terms_name)) );

  -- Each Site node will get a site Terms Name Desc
  l_v_site_terms_name_desc_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteTermsNameDescription' )) );
  l_v_site_terms_name_desc_tn := dbms_xmldom.appendchild( l_v_site_terms_name_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_terms_name_desc)) );

  ----NAIT-64249 Added by Sunil below 3 tags.
  -- Each Site node will get a site Terms Discount Percent
  l_discount_percent_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteTermsDiscountPercent' )) );
  l_discount_percent_tn := dbms_xmldom.appendchild( l_discount_percent_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_discount_percent)) );

  -- Each Site node will get a site Terms Discount Days
  l_discount_days_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteTermsDiscountDays' )) );
  l_discount_days_tn := dbms_xmldom.appendchild( l_discount_days_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_discount_days)) );

  -- Each Site node will get a site Terms Due Days
  l_due_days_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteTermsDueDays' )) );
  l_due_days_tn := dbms_xmldom.appendchild( l_due_days_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_due_days)) );

  -- Each Site node will get a site FReight Terms EBS --NAIT-64184--Added by Sunil
  l_v_freight_terms_code_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteFreightTermsEBS' )) );
  IF v_site_freightterms NOT IN ('CC','PP') THEN--added by Sunil (NAIT-74711) 
    v_site_freightterms:=NULL;
  END IF;
  l_v_freight_terms_code_tn := dbms_xmldom.appendchild( l_v_freight_terms_code_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_freightterms)) );

  -- Each Site node will get a site Freight Terms----NAIT-64184--Added by Sunil
  if (v_site_freightterms is not null and v_site_fob_lookup_code is not null) then
    IF v_site_freightterms IN ('CC','PP') THEN---Added by sunil (NAIT-74711) 
      IF v_site_freightterms ='CC' AND v_site_fob_lookup_code='RECEIVING' THEN
        v_site_freightterms :='US-Collect/FOB Destination';
      END IF;
      IF v_site_freightterms ='CC' AND v_site_fob_lookup_code='SHIPPING' THEN
        v_site_freightterms :='US-Collect/FOB Origin';
      END IF;
      IF v_site_freightterms ='PP' AND v_site_fob_lookup_code='RECEIVING' THEN
        v_site_freightterms :='US-Prepaid/FOB Destination';
      END IF;
      IF v_site_freightterms ='PP' AND v_site_fob_lookup_code='SHIPPING' THEN
        v_site_freightterms :='US-Prepaid/FOB Origin';
      END IF;
    ELSE
      v_site_freightterms := NULL;
    END IF;
  ELSE
    v_site_freightterms := NULL;
  END IF;

  l_v_site_freightterms_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteFreightTerms' )) );
  l_v_site_freightterms_tn := dbms_xmldom.appendchild( l_v_site_freightterms_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_freightterms)) );

  -- Each Site node will get a site FOB lookup Code --NAIT-64184--Added by Sunil
  l_v_site_fob_lookup_code_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteFobEBS' )) );
  l_v_site_fob_lookup_code_tn := dbms_xmldom.appendchild( l_v_site_fob_lookup_code_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_fob_lookup_code)) );

  -- Each Site node will get a Debit Memo Flag
  l_v_debit_memo_flag_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:debitMemoFlag' )) );
  l_v_debit_memo_flag_tn := dbms_xmldom.appendchild( l_v_debit_memo_flag_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_debit_memo_flag)) );

  -- Each Site node will get a DUNS Num
  l_v_duns_num_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:dunsNum' )) );
  l_v_duns_num_tn := dbms_xmldom.appendchild( l_v_duns_num_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_duns_num)) );

  -- Each Site node will get a  Tax Reg Num
  l_v_tax_reg_num_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:taxRegNum' )) );
  l_v_tax_reg_num_tn := dbms_xmldom.appendchild( l_v_tax_reg_num_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_tax_reg_num)) );

  -- Each Site node will get a  Primary Paysite Flag
  l_v_primary_paysite_flag_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:primaryPaySiteFlag' )) );
  l_v_primary_paysite_flag_tn := dbms_xmldom.appendchild( l_v_primary_paysite_flag_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_primary_paysite_flag)) );

  -- Each Site node will get a site category
  l_v_site_category_n := dbms_xmldom.appendchild(l_supp_header_node-- l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:siteCategory' )) );
  l_v_site_category_tn := dbms_xmldom.appendchild( l_v_site_category_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_attribute8)) );

  -- Each Site node will get a Bank Acc Num
  l_v_bank_account_num_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:bankAccountNumber' )) );
  l_v_bank_account_num_tn := dbms_xmldom.appendchild( l_v_bank_account_num_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_bank_account_num)) );

  -- Each Site node will get a Bank Acc Name
  l_v_bank_account_name_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:bankAccountName' )) );
  l_v_bank_account_name_tn := dbms_xmldom.appendchild( l_v_bank_account_name_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_bank_account_name)) );

  -- Each Site node will get a Bank Acc Name EBS--Added by SUnil for NAIT- 64721
  l_v_bank_name_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:bankAccountNameEBS' )) );
  l_v_bank_name_tn := dbms_xmldom.appendchild( l_v_bank_name_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_bank_name)) );

  -- Each Site node will get a Bank Acc Name
  l_v_related_pay_site_n := dbms_xmldom.appendchild( l_supp_header_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:relatedPaySite' )) );
  l_v_related_pay_site_tn := dbms_xmldom.appendchild( l_v_related_pay_site_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_attribute13)) );

  -- Create a new node Business class and add it to the supplier node
  l_bus_class_node := dbms_xmldom.appendchild( l_supplier_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:businessClass' )) );

  -- Each business class node will get a  Minority Class
  l_v_minority_class_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minorityClass' )) );
  l_v_minority_class_tn := dbms_xmldom.appendchild( l_v_minority_class_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_minority_class)) );

  -- Each business class node will get a  Minority Code
  l_v_minority_cd_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minorityCode' )) );
  l_v_minority_cd_tn := dbms_xmldom.appendchild( l_v_minority_cd_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_minority_cd)) );

  BEGIN
    IF v_minority_cd IS NOT NULL THEN
      SELECT meaning
      INTO v_minority_cd_desc--,DESCRIPTION--*
      FROM fnd_lookup_values_vl
      WHERE lookup_type      = 'MINORITY GROUP'
      AND attribute_category = 'MINORITY GROUP'
      AND lookup_code        =v_minority_cd;
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting minority_cd_desc'||sqlerrm);
    dbms_output.put_line('Error getting minority_cd_desc');
  END;

  -- Each business class node will get a  Minority Code desc
  l_v_minority_cd_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minorityCodeDescription' )) );
  l_v_minority_cd_desc_tn := dbms_xmldom.appendchild( l_v_minority_cd_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_minority_cd_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,1)+1, instr(v_attribute16, ';',1,2)-(instr(v_attribute16, ';',1,1)+1))
  INTO v_mbe
  FROM dual;

  -- Each business class node will get a  MBE
  l_v_mbe_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:mbe' )) );
  l_v_mbe_tn := dbms_xmldom.appendchild( l_v_mbe_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_mbe)) );
  BEGIN
    SELECT meaning
    INTO v_mbe_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='MBE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_mbe_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_mbe_desc');
  END;

  -- Each business class node will get a  MBE desc
  l_v_mbe_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:mbeDescription' )) );
  l_v_mbe_desc_tn := dbms_xmldom.appendchild( l_v_mbe_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_mbe_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,2)+1, instr(v_attribute16, ';',1,3)-(instr(v_attribute16, ';',1,2)+1))
  INTO v_nmsdc
  FROM dual;

  -- Each business class node will get a nmsdc
  l_v_nmsdc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:nmsdc' )) );
  l_v_nmsdc_tn := dbms_xmldom.appendchild( l_v_nmsdc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_nmsdc)) );

  BEGIN
    SELECT meaning
    INTO v_nmsdc_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='NMSDC';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_nmsdc_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_nmsdc_desc');
  END;

  -- Each business class node will get a nmsdc desc
  l_v_nmsdc_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:nmsdcDescription' )) );
  l_v_nmsdc_desc_tn := dbms_xmldom.appendchild( l_v_nmsdc_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_nmsdc_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,3)+1, instr(v_attribute16, ';',1,4)-(instr(v_attribute16, ';',1,3)+1))
  INTO v_wbe
  FROM dual;

  -- Each business class node will get a wbe
  l_v_wbe_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wbe' )) );
  l_v_wbe_tn := dbms_xmldom.appendchild( l_v_wbe_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wbe)) );

  BEGIN
    SELECT meaning
    INTO v_wbe_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='WBE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_wbe_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_wbe_desc');
  END;

  -- Each business class node will get a wbe desc
  l_v_wbe_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wbeDescription' )) );
  l_v_wbe_desc_tn := dbms_xmldom.appendchild( l_v_wbe_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wbe_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,4)+1, instr(v_attribute16, ';',1,5)-(instr(v_attribute16, ';',1,4)+1))
  INTO v_wbenc
  FROM dual;

  -- Each business class node will get a wbenc
  l_v_wbenc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wbenc' )) );
  l_v_wbenc_tn := dbms_xmldom.appendchild( l_v_wbenc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wbenc)) );

  BEGIN
    SELECT meaning
    INTO v_wbenc_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='WBENC';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_wbenc_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_wbenc_desc');
  END;

  -- Each business class node will get a wbenc desc
  l_v_wbenc_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wbencDescription' )) );
  l_v_wbenc_desc_tn := dbms_xmldom.appendchild( l_v_wbenc_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wbenc_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,5)+1, instr(v_attribute16, ';',1,6)-(instr(v_attribute16, ';',1,5)+1))
  INTO v_vob
  FROM dual;

  -- Each business class node will get a vob
  l_v_vob_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vob' )) );
  l_v_vob_tn := dbms_xmldom.appendchild( l_v_vob_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_vob)) );

  BEGIN
    SELECT meaning
    INTO v_vob_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='VOB';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_vob_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_vob_desc');
  END;

  -- Each business class node will get a vob desc
  l_v_vob_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vobDescription' )) );
  l_v_vob_desc_tn := dbms_xmldom.appendchild( l_v_vob_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_vob_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,6)+1, instr(v_attribute16, ';',1,7)-(instr(v_attribute16, ';',1,6)+1))
  INTO v_dodva
  FROM dual;

  -- Each business class node will get a dodva
  l_v_dodva_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:dodva' )) );
  l_v_dodva_tn := dbms_xmldom.appendchild( l_v_dodva_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_dodva)) );

  BEGIN
    SELECT meaning
    INTO v_dodva_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='DODVA';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_dodva_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_dodva_desc');
  END;

  -- Each business class node will get a dodva desc
  l_v_dodva_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:dodvaDescription' )) );
  l_v_dodva_desc_tn := dbms_xmldom.appendchild( l_v_dodva_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_dodva_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,7)+1, instr(v_attribute16, ';',1,8)-(instr(v_attribute16, ';',1,7)+1))
  INTO v_doe
  FROM dual;

  -- Each business class node will get a doe
  l_v_doe_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:doe' )) );
  l_v_doe_tn := dbms_xmldom.appendchild( l_v_doe_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_doe)) );

  BEGIN
    SELECT meaning
    INTO v_doe_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='DOE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_doe_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_doe_desc');
  END;

  -- Each business class node will get a doe desc
  l_v_doe_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:doeDescription' )) );
  l_v_doe_desc_tn := dbms_xmldom.appendchild( l_v_doe_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_doe_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,8)+1, instr(v_attribute16, ';',1,9)-(instr(v_attribute16, ';',1,8)+1))
  INTO v_usbln
  FROM dual;

  -- Each business class node will get a usbln
  l_v_usbln_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:usbln' )) );
  l_v_usbln_tn := dbms_xmldom.appendchild( l_v_usbln_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_usbln)) );

  BEGIN
    SELECT meaning
    INTO v_usbln_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='USBLN';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_usbln_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_usbln_desc');
  END;

  -- Each business class node will get a usbln desc
  l_v_usbln_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:usblnDescription' )) );
  l_v_usbln_desc_tn := dbms_xmldom.appendchild( l_v_usbln_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_usbln_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,9)+1, instr(v_attribute16, ';',1,10)-(instr(v_attribute16, ';',1,9)+1))
  INTO v_lgbt
  FROM dual;

  -- Each business class node will get a lgbt
  l_v_lgbt_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:lgbt' )) );
  l_v_lgbt_tn := dbms_xmldom.appendchild( l_v_lgbt_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_lgbt)) );

  BEGIN
    SELECT meaning
    INTO v_lgbt_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='LGBT';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_lgbt_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_lgbt_desc');
  END;

  -- Each business class node will get a lgbt desc
  l_v_lgbt_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:lgbtDescription' )) );
  l_v_lgbt_desc_tn := dbms_xmldom.appendchild( l_v_lgbt_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_lgbt_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,10)+1, instr(v_attribute16, ';',1,11)-(instr(v_attribute16, ';',1,10)+1))
  INTO v_nglcc
  FROM dual;

  -- Each business class node will get a nglcc
  l_v_nglcc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:nglcc' )) );
  l_v_nglcc_tn := dbms_xmldom.appendchild( l_v_nglcc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_nglcc)) );

  BEGIN
    SELECT meaning
    INTO v_nglcc_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='NGLCC';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_nglcc_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_nglcc_desc');
  END;

  -- Each business class node will get a nglcc desc
  l_v_nglcc_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:nglccDescription' )) );
  l_v_nglcc_desc_tn := dbms_xmldom.appendchild( l_v_nglcc_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_nglcc_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16, ';',1,11)+1, instr(v_attribute16, ';',1,12)-(instr(v_attribute16, ';',1,11)+1))
  INTO v_nibnishablty
  FROM dual;

  -- Each business class node will get a nibnishablty
  l_v_nibnishablty_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:nibnishablty' )) );
  l_v_nibnishablty_tn := dbms_xmldom.appendchild( l_v_nibnishablty_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_nibnishablty)) );

  BEGIN
    SELECT meaning
    INTO v_nibnishablty_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='NIBNISHABLTY';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_nibnishablty_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_nibnishablty_desc');
  END;

  -- Each business class node will get a nibnishablty desc
  l_v_nibnishablty_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:nibnishabltyDescription' )) );
  l_v_nibnishablty_desc_tn := dbms_xmldom.appendchild( l_v_nibnishablty_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_nibnishablty_desc)) );

  --FOB
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,12)+1, instr(v_attribute16, ';',1,13)-(instr(v_attribute16, ';',1,12)+1))
  INTO v_fob
  FROM dual;

  -- Each business class node will get a fob
  l_v_fob_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:fob' )) );
  l_v_fob_tn := dbms_xmldom.appendchild( l_v_fob_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_fob)) );

  BEGIN
    IF v_fob <> 'N' THEN
      SELECT meaning
      INTO v_fob_desc--,DESCRIPTION--*
      FROM fnd_lookup_values_vl
      WHERE lookup_type      = 'FOREIGN_OWN_BUS'
      AND attribute_category = 'FOREIGN_OWN_BUS'
      AND lookup_code        =v_fob;
    ELSE
      SELECT meaning
      INTO v_fob_desc
      FROM fnd_lookup_values_vl
      WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
      AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
      AND lookup_code        ='FOB';
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_fob_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_fob_desc');
  END;

  -- Each business class node will get a fob desc
  l_v_fob_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:fobDescription' )) );
  l_v_fob_desc_tn := dbms_xmldom.appendchild( l_v_fob_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_fob_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,13)+1, instr(v_attribute16, ';',1,14)-(instr(v_attribute16, ';',1,13)+1))
  INTO v_sb
  FROM dual;

  -- Each business class node will get a sb
  l_v_sb_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sb' )) );
  l_v_sb_tn := dbms_xmldom.appendchild( l_v_sb_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sb)) );

  BEGIN
    SELECT meaning
    INTO v_sb_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='SB';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_sb_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_sb_desc');
  END;

  -- Each business class node will get a sb desc
  l_v_sb_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sbDescription' )) );
  l_v_sb_desc_tn := dbms_xmldom.appendchild( l_v_sb_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sb_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,14)+1, instr(v_attribute16, ';',1,15)-(instr(v_attribute16, ';',1,14)+1))
  INTO v_samgov
  FROM dual;

  -- Each business class node will get a samgov
  l_v_samgov_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:samgov' )) );
  l_v_samgov_tn := dbms_xmldom.appendchild( l_v_samgov_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_samgov)) );
  BEGIN
    SELECT meaning
    INTO v_samgov_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='SAMGOV';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_samgov_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_samgov_desc');
  END;

  -- Each business class node will get a samgov desc
  l_v_samgov_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:samgovDescription' )) );
  l_v_samgov_desc_tn := dbms_xmldom.appendchild( l_v_samgov_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_samgov_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,15)+1, instr(v_attribute16, ';',1,16)-(instr(v_attribute16, ';',1,15)+1))
  INTO v_sba
  FROM dual;

  -- Each business class node will get a sba
  l_v_sba_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sba' )) );
  l_v_sba_tn := dbms_xmldom.appendchild( l_v_sba_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sba)) );
  BEGIN
    SELECT meaning
    INTO v_sba_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='SBA';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_sba_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_sba_desc');
  END;

  -- Each business class node will get a sba desc
  l_v_sba_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sbaDescription' )) );
  l_v_sba_desc_tn := dbms_xmldom.appendchild( l_v_sba_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sba_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,16)+1, instr(v_attribute16, ';',1,17)-(instr(v_attribute16, ';',1,16)+1))
  INTO v_sbc
  FROM dual;

  -- Each business class node will get a sbc
  l_v_sbc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sbc' )) );
  l_v_sbc_tn := dbms_xmldom.appendchild( l_v_sbc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sbc)) );
  BEGIN
    SELECT meaning
    INTO v_sbc_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='SBC';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_sbc_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_sbc_desc');
  END;

  -- Each business class node will get a sbc desc
  l_v_sbc_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sbcDescription' )) );
  l_v_sbc_desc_tn := dbms_xmldom.appendchild( l_v_sbc_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sbc_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,17)+1, instr(v_attribute16, ';',1,18)-(instr(v_attribute16, ';',1,17)+1))
  INTO v_sdbe
  FROM dual;

  -- Each business class node will get a sdbe
  l_v_sdbe_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sdbe' )) );
  l_v_sdbe_tn := dbms_xmldom.appendchild( l_v_sdbe_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sdbe)) );

  BEGIN
    SELECT meaning
    INTO v_sdbe_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='SDBE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_sdbe_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_sdbe_desc');
  END;

  -- Each business class node will get a sdbe desc
  l_v_sdbe_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sdbeDescription' )) );
  l_v_sdbe_desc_tn := dbms_xmldom.appendchild( l_v_sdbe_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sdbe_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,18)+1, instr(v_attribute16, ';',1,19)-(instr(v_attribute16, ';',1,18)+1))
  INTO v_sba8a
  FROM dual;

  -- Each business class node will get a sba8a
  l_v_sba8a_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sba8a' )) );
  l_v_sba8a_tn := dbms_xmldom.appendchild( l_v_sba8a_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sba8a)) );

  BEGIN
    SELECT meaning
    INTO v_sba8a_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='SBA8A';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_sba8a_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_sba8a_desc');
  END;

  -- Each business class node will get a sba8a desc
  l_v_sba8a_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sba8aDescription' )) );
  l_v_sba8a_desc_tn := dbms_xmldom.appendchild( l_v_sba8a_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sba8a_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,19)+1, instr(v_attribute16, ';',1,20)-(instr(v_attribute16, ';',1,19)+1))
  INTO v_hubzone
  FROM dual;

  -- Each business class node will get a hubzone
  l_v_hubzone_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:hubzone' )) );
  l_v_hubzone_tn := dbms_xmldom.appendchild( l_v_hubzone_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_hubzone)) );

  BEGIN
    SELECT meaning
    INTO v_hubzone_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='HUBZONE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_hubzone_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_hubzone_desc');
  END;

  -- Each business class node will get a hubzone desc
  l_v_hubzone_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:hubzoneDescription' )) );
  l_v_hubzone_desc_tn := dbms_xmldom.appendchild( l_v_hubzone_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_hubzone_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,20)+1, instr(v_attribute16, ';',1,21)-(instr(v_attribute16, ';',1,20)+1))
  INTO v_wosb
  FROM dual;

  -- Each business class node will get a wosb
  l_v_wosb_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wosb' )) );
  l_v_wosb_tn := dbms_xmldom.appendchild( l_v_wosb_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wosb)) );

  BEGIN
    SELECT meaning
    INTO v_wosb_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='WOSB';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_wosb_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_wosb_desc');
  END;

  -- Each business class node will get a wosb desc
  l_v_wosb_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wosbDescription' )) );
  l_v_wosb_desc_tn := dbms_xmldom.appendchild( l_v_wosb_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wosb_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,21)+1, instr(v_attribute16, ';',1,22)-(instr(v_attribute16, ';',1,21)+1))
  INTO v_wsbe
  FROM dual;
  -- Each business class node will get a wsbe
  l_v_wsbe_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wsbe' )) );
  l_v_wsbe_tn := dbms_xmldom.appendchild( l_v_wsbe_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wsbe)) );

  BEGIN
    SELECT meaning
    INTO v_wsbe_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='WSBE';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_wsbe_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_wsbe_desc');
  END;

  -- Each business class node will get a wsbe desc
  l_v_wsbe_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:wsbeDescription' )) );
  l_v_wsbe_desc_tn := dbms_xmldom.appendchild( l_v_wsbe_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_wsbe_desc)) );
  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,22)+1, instr(v_attribute16, ';',1,23)-(instr(v_attribute16, ';',1,22)+1))
  INTO v_edwosb
  FROM dual;

  -- Each business class node will get a edwosb
  l_v_edwosb_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:edwosb' )) );
  l_v_edwosb_tn := dbms_xmldom.appendchild( l_v_edwosb_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_edwosb)) );

  BEGIN
    SELECT meaning
    INTO v_edwosb_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='EDWOSB';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_edwosb_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_edwosb_desc');
  END;

  -- Each business class node will get a edwosb desc
  l_v_edwosb_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:edwosbDescription' )) );
  l_v_edwosb_desc_tn := dbms_xmldom.appendchild( l_v_edwosb_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_edwosb_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,23)+1, instr(v_attribute16, ';',1,24)-(instr(v_attribute16, ';',1,23)+1))
  INTO v_vosb
  FROM dual;

  -- Each business class node will get a vosb
  l_v_vosb_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vosb' )) );
  l_v_vosb_tn := dbms_xmldom.appendchild( l_v_vosb_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_vosb)) );

  BEGIN
    SELECT meaning
    INTO v_vosb_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='VOSB';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_vosb_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_vosb_desc');
  END;

  -- Each business class node will get a vosb desc
  l_v_vosb_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vosbDescription' )) );
  l_v_vosb_desc_tn := dbms_xmldom.appendchild( l_v_vosb_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_vosb_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,24)+1, instr(v_attribute16, ';',1,25)-(instr(v_attribute16, ';',1,24)+1))
  INTO v_sdvosb
  FROM dual;

  -- Each business class node will get a sdvosb
  l_v_sdvosb_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sdvosb' )) );
  l_v_sdvosb_tn := dbms_xmldom.appendchild( l_v_sdvosb_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sdvosb)) );

  BEGIN
    SELECT meaning
    INTO v_sdvosb_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='SDVOSB';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_sdvosb_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_sdvosb_desc');
  END;

  -- Each business class node will get a sdvosb desc
  l_v_sdvosb_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sdvosbDescription' )) );
  l_v_sdvosb_desc_tn := dbms_xmldom.appendchild( l_v_sdvosb_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_sdvosb_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,25)+1, instr(v_attribute16, ';',1,26)-(instr(v_attribute16, ';',1,25)+1))
  INTO v_hbcumi
  FROM dual;

  -- Each business class node will get a hbcumi
  l_v_hbcumi_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:hbcumi' )) );
  l_v_hbcumi_tn := dbms_xmldom.appendchild( l_v_hbcumi_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_hbcumi)) );

  BEGIN
    SELECT meaning
    INTO v_hbcumi_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='HBCUMI';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_hbcumi_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_hbcumi_desc');
  END;

  -- Each business class node will get a hbcumi desc
  l_v_hbcumi_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:hbcumiDescription' )) );
  l_v_hbcumi_desc_tn := dbms_xmldom.appendchild( l_v_hbcumi_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_hbcumi_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,26)+1, instr(v_attribute16, ';',1,27)-(instr(v_attribute16, ';',1,26)+1))
  INTO v_anc
  FROM dual;

  -- Each business class node will get a anc
  l_v_anc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:anc' )) );
  l_v_anc_tn := dbms_xmldom.appendchild( l_v_anc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_anc)) );

  BEGIN
    SELECT meaning
    INTO v_anc_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='ANC';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_anc_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_anc_desc');
  END;

  -- Each business class node will get a anc desc
  l_v_anc_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:ancDescription' )) );
  l_v_anc_desc_tn := dbms_xmldom.appendchild( l_v_anc_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_anc_desc)) );

  SELECT SUBSTR(v_attribute16, instr(v_attribute16,';',1,27)+1, instr(v_attribute16, ';',1,28)-(instr(v_attribute16, ';',1,27)+1))
  INTO v_ind
  FROM dual;

  -- Each business class node will get a ind
  l_v_ind_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:ind' )) );
  l_v_ind_tn := dbms_xmldom.appendchild( l_v_ind_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_ind)) );

  BEGIN
    SELECT meaning
    INTO v_ind_desc
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    AND lookup_code        ='IND';
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_ind_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_ind_desc');
  END;

  -- Each business class node will get a ind desc
  l_v_ind_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:indDescription' )) );
  l_v_ind_desc_tn := dbms_xmldom.appendchild( l_v_ind_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_ind_desc)) );

  --Minority_owned

  SELECT SUBSTR(v_attribute16,instr(v_attribute16, ';',-1,1)+1, (LENGTH (v_attribute16)- instr(v_attribute16, ';',-1,1)))
  INTO v_minority_owned
  FROM dual;

  -- Each business class node will get a minority_owned
  l_v_minority_owned_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minority_owned' )) );
  l_v_minority_owned_tn := dbms_xmldom.appendchild( l_v_minority_owned_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_minority_owned)) );

  BEGIN
    IF v_minority_owned <> 'N' THEN
      SELECT meaning
      INTO v_minority_owned_desc--,DESCRIPTION--*
      FROM fnd_lookup_values_vl
      WHERE lookup_type      = 'MINORITY GROUP'
      AND attribute_category = 'MINORITY GROUP'
      AND lookup_code        =v_minority_owned;
    ELSE
      SELECT meaning
      INTO v_minority_owned_desc--,DESCRIPTION--*
      FROM fnd_lookup_values_vl
      WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS' --,'FOREIGN_OWN_BUS', 'MINORITY GROUP')
      AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'--)--,'FOREIGN_OWN_BUS', 'MINORITY GROUP')
      AND lookup_code        ='MINORITY_OWNED';
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error getting v_minority_owned_desc'||sqlerrm);
    dbms_output.put_line('Error getting v_minority_owned_desc');
  END;

  -- Each business class node will get a minority_owned desc
  l_v_minority_owned_desc_n  := dbms_xmldom.appendchild( l_bus_class_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minorityOwnedDescription' )) );
  l_v_minority_owned_desc_tn := dbms_xmldom.appendchild( l_v_minority_owned_desc_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_minority_owned_desc)) );

  l_addr_list_element:= dbms_xmldom.createelement(l_domdoc, 'sup:addressList' );
  l_addr_list_node   := dbms_xmldom.appendchild( l_supplier_node , dbms_xmldom.makenode( l_addr_list_element) );
  ---Purch Address
  IF v_site_purchaddr1 IS NOT NULL THEN
    l_addr_element := dbms_xmldom.createelement(l_domdoc, 'sup:address' );
    l_addr_node    := dbms_xmldom.appendchild( l_addr_list_node--l_supplier_node
    , dbms_xmldom.makenode( l_addr_element) );
    l_v_site_puraddr_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressType' )) );
    l_v_site_puraddr_type_tn := dbms_xmldom.appendchild( l_v_site_puraddr_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '99' )) );
    l_v_site_purseqnum_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sequenceNumber' )) );
    l_v_site_purseqnum_tn := dbms_xmldom.appendchild( l_v_site_purseqnum_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_addr_flag )) );
    l_v_site_puraction_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:actionType' )) );
    l_v_site_puraction_type_tn := dbms_xmldom.appendchild( l_v_site_puraction_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_purpriaddrind_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:primaryAddressIndicator' )) );
    l_v_site_purpriaddrind_tn := dbms_xmldom.appendchild( l_v_site_purpriaddrind_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,'' )) );
    l_v_site_purchaddr1_node := dbms_xmldom.appendchild(l_addr_node-- l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine1' )) );
    l_v_site_purchaddr1_textnode := dbms_xmldom.appendchild( l_v_site_purchaddr1_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_purchaddr1 )) );
    l_v_site_purchaddr2_node     := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine2' )) );
    l_v_site_purchaddr2_textnode := dbms_xmldom.appendchild( l_v_site_purchaddr2_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_purchaddr2 )) );
    l_v_site_purchaddr3_node     := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine3' )) );
    l_v_site_purchaddr3_textnode := dbms_xmldom.appendchild( l_v_site_purchaddr3_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_purchaddr3 )) );
    l_v_site_purchcity_node      := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:city' )) );
    l_v_site_purchcity_textnode := dbms_xmldom.appendchild( l_v_site_purchcity_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_purchcity )) );
    l_v_site_purchstate_node    := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:state' )) );
    l_v_site_purchstate_textnode := dbms_xmldom.appendchild(l_v_site_purchstate_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_purchstate )) );
    l_v_pur_add_state_abbre_n    := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:stateAbbreviation' )) );
    l_v_pur_add_state_abbre_tn := dbms_xmldom.appendchild( l_v_pur_add_state_abbre_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_purchzip_node     := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:postalCode' )) );
    l_v_site_purchzip_textnode := dbms_xmldom.appendchild( l_v_site_purchzip_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_purchzip )) );
    l_v_site_purchcountry_node := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:country' )) );
    l_v_site_purchcountry_textnode := dbms_xmldom.appendchild( l_v_site_purchcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_purchcountry )) );
    l_v_orgcountry_node            := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:orgCountry' )) );
    l_v_orgcountry_textnode     := dbms_xmldom.appendchild( l_v_orgcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_orgcountry )) );
    l_v_site_pur_add_latitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:latitude' )) );
    l_v_site_pur_add_latitude_tn := dbms_xmldom.appendchild( l_v_site_pur_add_latitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pur_add_longitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:longitude' )) );
    l_v_site_pur_add_longitude_tn := dbms_xmldom.appendchild( l_v_site_pur_add_longitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pur_add_county_n     := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:county' )) );
    l_v_site_pur_add_county_tn  := dbms_xmldom.appendchild( l_v_site_pur_add_county_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pur_add_district_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:district' )) );
    l_v_site_pur_add_district_tn := dbms_xmldom.appendchild( l_v_site_pur_add_district_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pur_add_spe_notes_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:specialNote' )) );
    L_V_SITE_PUR_ADD_SPE_NOTES_TN := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_PUR_ADD_SPE_NOTES_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC, '' )) );
    L_V_SITE_pur_od_comment1_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment1' )) );
    L_V_SITE_pur_od_comment1_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment1_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment2_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment2' )) );
    L_V_SITE_pur_od_comment2_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment2_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment3_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment3' )) );
    L_V_SITE_pur_od_comment3_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment3_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment4_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment4' )) );
    L_V_SITE_pur_od_comment4_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment4_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    ---od_ship_from_addr_id
    L_V_SITE_pur_SHIP_ADDR_ID_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATEELEMENT(L_DOMDOC, 'sup:odShipFromAddressId' )) );
    L_V_SITE_Pur_SHIP_ADDR_ID_TN := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_Pur_SHIP_ADDR_ID_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    --Contact Node
    l_site_purch_cont_list_node := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contactList' )) );
    l_site_purch_contact_node := dbms_xmldom.appendchild(l_site_purch_cont_list_node--l_site_purch_contact_node-- l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contact' )) );
    l_site_pur_contact_pname_node := dbms_xmldom.appendchild( l_site_purch_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:name' )) );
    l_v_site_con_purfname_n     := dbms_xmldom.appendchild( l_site_pur_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:firstName' )) );
    l_v_site_con_purfname_tn    := dbms_xmldom.appendchild( l_v_site_con_purfname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_purmname_n     := dbms_xmldom.appendchild( l_site_pur_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:middleName' )) );
    l_v_site_con_purmname_tn    := dbms_xmldom.appendchild( l_v_site_con_purmname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_purlname_n     := dbms_xmldom.appendchild( l_site_pur_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:lastName' )) );
    l_v_site_con_purlname_tn    := dbms_xmldom.appendchild( l_v_site_con_purlname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_purname_n      := dbms_xmldom.appendchild( l_site_pur_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:fullName' )) );
    l_v_site_con_purname_tn     := dbms_xmldom.appendchild( l_v_site_con_purname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_purchname )) );
    l_site_pur_cont_ptitle_node := dbms_xmldom.appendchild( l_site_purch_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:title' )) );
    l_v_pur_con_salutation_n := dbms_xmldom.appendchild(l_site_pur_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:salutation' )) );
    l_v_pur_con_salutation_tn := dbms_xmldom.appendchild( l_v_pur_con_salutation_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );
    l_v_pur_con_jobtitle_n    := dbms_xmldom.appendchild(l_site_pur_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:jobTitle' )) );
    l_v_pur_con_jobtitle_tn := dbms_xmldom.appendchild( l_v_pur_con_jobtitle_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );
    l_site_pur_cont_ph_node := dbms_xmldom.appendchild( l_site_purch_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:phones' )) );
    l_site_pur_cont_phasso_node := dbms_xmldom.appendchild( l_site_pur_cont_ph_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_purchphtype_n   := dbms_xmldom.appendchild(l_site_pur_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_purchphtype_tn  := dbms_xmldom.appendchild( l_v_site_con_purchphtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'Phone' )) );
    l_v_site_con_purchphone_n    := dbms_xmldom.appendchild(l_site_pur_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_purphareacode_n := dbms_xmldom.appendchild(l_v_site_con_purchphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

    IF v_site_contact_purchphone IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_purchphone,1,3) INTO l_v_purareacode FROM dual;
    ELSE
      l_v_purareacode := '';
    END IF;

    l_v_site_con_purphareacode_tn := dbms_xmldom.appendchild( l_v_site_con_purphareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_purareacode ))--
    );
    l_v_site_con_purphcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_purchphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_purphcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_purphcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );
    l_v_site_con_purchph_n       := dbms_xmldom.appendchild(l_v_site_con_purchphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

    IF v_site_contact_purchphone IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_purchphone,4,10) INTO l_v_purph FROM dual;
    ELSE
      l_v_purph := '';
    END IF;

    l_v_site_con_purchph_tn    := dbms_xmldom.appendchild( l_v_site_con_purchph_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_purph )) );
    l_v_site_con_purchphext_n  := dbms_xmldom.appendchild(l_v_site_con_purchphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_purchphext_tn := dbms_xmldom.appendchild( l_v_site_con_purchphext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_purchphpri_n  := dbms_xmldom.appendchild(l_site_pur_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_purchphpri_tn := dbms_xmldom.appendchild( l_v_site_con_purchphpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_v_odphnbrext_n  := dbms_xmldom.appendchild(l_site_pur_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhoneNumberExt' )) );
    l_v_odphnbrext_tn := dbms_xmldom.appendchild( l_v_odphnbrext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_odph800nbr_n  := dbms_xmldom.appendchild(l_site_pur_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhone800Number' )) );
    l_v_odph800nbr_tn := dbms_xmldom.appendchild( l_v_odph800nbr_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_site_pur_cont_fax_node := dbms_xmldom.appendchild( l_site_purch_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:fax' )) );
    l_site_pur_cont_faxasso_node := dbms_xmldom.appendchild( l_site_pur_cont_fax_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_purchfaxtype_n   := dbms_xmldom.appendchild(l_site_pur_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_purchfaxtype_tn  := dbms_xmldom.appendchild( l_v_site_con_purchfaxtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'fax' )) );
    l_v_site_con_purchfax_n       := dbms_xmldom.appendchild(l_site_pur_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_purfaxareacode_n := dbms_xmldom.appendchild(l_v_site_con_purchfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

    IF v_site_contact_purchfax    IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_purchfax,1,3) INTO l_v_purfaxareacode FROM dual;
    ELSE
      l_v_purfaxareacode := '';
    END IF;

    l_v_site_con_purfaxareacode_tn := dbms_xmldom.appendchild( l_v_site_con_purfaxareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_purfaxareacode ))--
    );
    l_v_site_con_purfxcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_purchfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_purfxcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_purfxcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );

    l_v_site_con_purchfx_n     := dbms_xmldom.appendchild(l_v_site_con_purchfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );
    IF v_site_contact_purchfax IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_purchfax,4,10) INTO l_v_purfax FROM dual;
    ELSE
      l_v_purfax := '';
    END IF;

    l_v_site_con_purchfx_tn := dbms_xmldom.appendchild( l_v_site_con_purchfax_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_purfax )) );

    l_v_site_con_purchfaxext_n  := dbms_xmldom.appendchild(l_v_site_con_purchfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_purchfaxext_tn := dbms_xmldom.appendchild( l_v_site_con_purchfaxext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_purchfaxpri_n  := dbms_xmldom.appendchild(l_site_pur_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_purchfaxpri_tn := dbms_xmldom.appendchild( l_v_site_con_purchfaxpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_site_pur_cont_email_node := dbms_xmldom.appendchild( l_site_purch_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:emails' )) );
    l_site_pur_cont_emailasso_node := dbms_xmldom.appendchild( l_site_pur_cont_email_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAssociation' )) );
    l_v_site_con_puremailtype_n  := dbms_xmldom.appendchild(l_site_pur_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailType' )) );
    l_v_site_con_puremailtype_tn := dbms_xmldom.appendchild( l_v_site_con_puremailtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_purchemail_n    := dbms_xmldom.appendchild( l_site_pur_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAddress' )) );
    l_v_site_con_purchemail_tn   := dbms_xmldom.appendchild( l_v_site_con_purchemail_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_purchemail )) );
    l_v_site_con_puremailpri_n   := dbms_xmldom.appendchild( l_site_pur_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_puremailpri_tn  := dbms_xmldom.appendchild( l_v_site_con_puremailpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_v_purodemailindflg_n  := dbms_xmldom.appendchild( l_site_pur_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odEmailIndicatorFlag' )) );
    l_v_purodemailindflg_tn := dbms_xmldom.appendchild( l_v_purodemailindflg_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

  END IF;

  ---Pay Address

  IF v_site_payaddr1 IS NOT NULL THEN
    l_addr_element := dbms_xmldom.createelement(l_domdoc, 'sup:address' );
    l_addr_node    := dbms_xmldom.appendchild( l_addr_list_node--l_supplier_node
    , dbms_xmldom.makenode( l_addr_element) );

    l_v_site_payaddr_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressType' )) );
    l_v_site_payaddr_type_tn := dbms_xmldom.appendchild( l_v_site_payaddr_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '99' )) );

    l_v_site_payseqnum_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sequenceNumber' )) );
    l_v_site_payseqnum_tn     := dbms_xmldom.appendchild( l_v_site_payseqnum_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_addr_flag )) );
    l_v_site_payaction_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:actionType' )) );
    l_v_site_payaction_type_tn := dbms_xmldom.appendchild( l_v_site_payaction_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_purpriaddrind_n   := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:primaryAddressIndicator' )) );
    l_v_site_purpriaddrind_tn := dbms_xmldom.appendchild( l_v_site_purpriaddrind_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,'' )) );

    l_v_site_payaddr1_node := dbms_xmldom.appendchild( l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine1' )) );
    l_v_site_payaddr1_textnode := dbms_xmldom.appendchild( l_v_site_payaddr1_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_payaddr1 )) );
    l_v_site_payaddr2_node     := dbms_xmldom.appendchild( l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine2' )) );
    l_v_site_payaddr2_textnode := dbms_xmldom.appendchild( l_v_site_payaddr2_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_payaddr2 )) );
    l_v_site_payaddr3_node     := dbms_xmldom.appendchild( l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine3' )) );
    l_v_site_payaddr3_textnode := dbms_xmldom.appendchild( l_v_site_payaddr3_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_payaddr3 )) );
    l_v_site_paycity_node      := dbms_xmldom.appendchild(l_addr_node-- l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:city' )) );
    l_v_site_paycity_textnode := dbms_xmldom.appendchild( l_v_site_paycity_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_paycity )) );
    l_v_site_paystate_node    := dbms_xmldom.appendchild(l_addr_node-- l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:state' )) );
    l_v_site_paystate_textnode := dbms_xmldom.appendchild( l_v_site_paystate_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_paystate )) );
    l_v_pay_add_state_abbre_n  := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:stateAbbreviation' )) );
    l_v_pay_add_state_abbre_tn := dbms_xmldom.appendchild( l_v_pay_add_state_abbre_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_payzip_node       := dbms_xmldom.appendchild( l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:postalCode' )) );
    l_v_site_payzip_textnode := dbms_xmldom.appendchild( l_v_site_payzip_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_payzip )) );
    l_v_site_paycountry_node := dbms_xmldom.appendchild( l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:country' )) );
    l_v_site_paycountry_textnode := dbms_xmldom.appendchild( l_v_site_paycountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_paycountry )) );
    l_v_orgcountry_node          := dbms_xmldom.appendchild( l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:orgCountry' )) );
    l_v_orgcountry_textnode     := dbms_xmldom.appendchild( l_v_orgcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_orgcountry )) );
    l_v_site_pay_add_latitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:latitude' )) );
    l_v_site_pay_add_latitude_tn := dbms_xmldom.appendchild( l_v_site_pay_add_latitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pay_add_longitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:longitude' )) );
    l_v_site_pay_add_longitude_tn := dbms_xmldom.appendchild( l_v_site_pay_add_longitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pay_add_county_n     := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:county' )) );
    l_v_site_pay_add_county_tn  := dbms_xmldom.appendchild( l_v_site_pay_add_county_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pay_add_district_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:district' )) );
    l_v_site_pay_add_district_tn := dbms_xmldom.appendchild( l_v_site_pay_add_district_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pay_add_spe_notes_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:specialNote' )) );
    L_V_SITE_PAY_ADD_SPE_NOTES_TN := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_PAY_ADD_SPE_NOTES_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC, '' )) );

    L_V_SITE_pur_od_comment1_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment1' )) );
    L_V_SITE_pur_od_comment1_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment1_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment2_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment2' )) );
    L_V_SITE_pur_od_comment2_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment2_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment3_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment3' )) );
    L_V_SITE_pur_od_comment3_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment3_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment4_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment4' )) );
    L_V_SITE_pur_od_comment4_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment4_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    ---od_ship_from_addr_id
    L_V_SITE_pay_SHIP_ADDR_ID_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATEELEMENT(L_DOMDOC, 'sup:odShipFromAddressId' )) );
    L_V_SITE_Pay_SHIP_ADDR_ID_TN := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_Pay_SHIP_ADDR_ID_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    --Contact Node
    l_site_pay_cont_list_node := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contactList' )) );
    l_site_pay_contact_node := dbms_xmldom.appendchild(l_site_pay_cont_list_node-- l_addr_node--l_site_pay_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contact' )) );
    l_site_pay_contact_pname_node := dbms_xmldom.appendchild( l_site_pay_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:name' )) );

    l_v_site_con_payfname_n     := dbms_xmldom.appendchild( l_site_pay_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:firstName' )) );
    l_v_site_con_payfname_tn    := dbms_xmldom.appendchild( l_v_site_con_payfname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_paymname_n     := dbms_xmldom.appendchild( l_site_pay_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:middleName' )) );
    l_v_site_con_paymname_tn    := dbms_xmldom.appendchild( l_v_site_con_paymname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_paylname_n     := dbms_xmldom.appendchild( l_site_pay_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:lastName' )) );
    l_v_site_con_paylname_tn    := dbms_xmldom.appendchild( l_v_site_con_paylname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_payname_n      := dbms_xmldom.appendchild( l_site_pay_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:fullName' )) );
    l_v_site_con_payname_tn     := dbms_xmldom.appendchild( l_v_site_con_payname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_payname)) );
    l_site_pay_cont_ptitle_node := dbms_xmldom.appendchild( l_site_pay_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:title' )) );

    l_v_pay_con_salutation_n := dbms_xmldom.appendchild(l_site_pay_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:salutation' )) );
    l_v_pay_con_salutation_tn := dbms_xmldom.appendchild( l_v_pay_con_salutation_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );
    l_v_pay_con_jobtitle_n    := dbms_xmldom.appendchild(l_site_pay_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:jobTitle' )) );
    l_v_pay_con_jobtitle_tn := dbms_xmldom.appendchild( l_v_pay_con_jobtitle_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );

    l_site_pay_cont_ph_node := dbms_xmldom.appendchild( l_site_pay_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:phones' )) );
    l_site_pay_cont_phasso_node := dbms_xmldom.appendchild( l_site_pay_cont_ph_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_payphtype_n  := dbms_xmldom.appendchild(l_site_pay_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_payphtype_tn := dbms_xmldom.appendchild( l_v_site_con_payphtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'Phone' )) );

    l_v_site_con_payphone_n      := dbms_xmldom.appendchild(l_site_pay_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_payphareacode_n := dbms_xmldom.appendchild(l_v_site_con_payphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

    IF v_site_contact_payphone   IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_payphone,1,3) INTO l_v_payareacode FROM dual;
    ELSE
      l_v_payareacode := '';
    END IF;

    l_v_site_con_payphareacode_tn := dbms_xmldom.appendchild( l_v_site_con_payphareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_payareacode ))--
    );
    l_v_site_con_payphcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_payphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_payphcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_payphcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );
    l_v_site_con_payph_n := dbms_xmldom.appendchild( l_v_site_con_payphone_n--l_site_pay_contact_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

    IF v_site_contact_payphone IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_payphone,4,10) INTO l_v_payph FROM dual;
    ELSE
      l_v_payph := '';
    END IF;

    l_v_site_con_payph_tn := dbms_xmldom.appendchild( l_v_site_con_payph_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_payph )) );

    l_v_site_con_payphext_n  := dbms_xmldom.appendchild(l_v_site_con_payphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_payphext_tn := dbms_xmldom.appendchild( l_v_site_con_payphext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_payphpri_n  := dbms_xmldom.appendchild(l_site_pay_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_payphpri_tn := dbms_xmldom.appendchild( l_v_site_con_payphpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_v_odphnbrext_n  := dbms_xmldom.appendchild(l_site_pay_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhoneNumberExt' )) );
    l_v_odphnbrext_tn := dbms_xmldom.appendchild( l_v_odphnbrext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_odph800nbr_n  := dbms_xmldom.appendchild(l_site_pay_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhone800Number' )) );
    l_v_odph800nbr_tn := dbms_xmldom.appendchild( l_v_odph800nbr_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_site_pay_cont_fax_node := dbms_xmldom.appendchild( l_site_pay_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:fax' )) );
    l_site_pay_cont_faxasso_node := dbms_xmldom.appendchild( l_site_pay_cont_fax_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_payfaxtype_n  := dbms_xmldom.appendchild(l_site_pay_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_payfaxtype_tn := dbms_xmldom.appendchild( l_v_site_con_payfaxtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'fax' )) );

    l_v_site_con_payfax_n         := dbms_xmldom.appendchild(l_site_pay_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_payfaxareacode_n := dbms_xmldom.appendchild(l_v_site_con_payfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

    IF v_site_contact_payfax      IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_payfax,1,3) INTO l_v_payfaxareacode FROM dual;
    ELSE
      l_v_payfaxareacode := '';
    END IF;

    l_v_site_con_payfaxareacode_tn := dbms_xmldom.appendchild( l_v_site_con_payfaxareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_payfaxareacode ))--
    );
    l_v_site_con_payfxcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_payfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_payfxcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_payfxcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );
    l_v_site_con_payfx_n     := dbms_xmldom.appendchild(l_v_site_con_payfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

    IF v_site_contact_payfax IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_payfax,4,10) INTO l_v_payfax FROM dual;
    ELSE
      l_v_payfax := '';
    END IF;

    l_v_site_con_payfx_tn     := dbms_xmldom.appendchild( l_v_site_con_payfx_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_payfax )) );
    l_v_site_con_payfaxext_n  := dbms_xmldom.appendchild(l_v_site_con_payfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_payfaxext_tn := dbms_xmldom.appendchild( l_v_site_con_payfaxext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_payfaxpri_n  := dbms_xmldom.appendchild(l_site_pay_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_payfaxpri_tn := dbms_xmldom.appendchild( l_v_site_con_payfaxpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_site_pay_cont_email_node := dbms_xmldom.appendchild( l_site_pay_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:emails' )) );
    l_site_pay_cont_emailasso_node := dbms_xmldom.appendchild( l_site_pay_cont_email_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAssociation' )) );
    l_v_site_con_payemailtype_n  := dbms_xmldom.appendchild(l_site_pay_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailType' )) );
    l_v_site_con_payemailtype_tn := dbms_xmldom.appendchild( l_v_site_con_payemailtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_payemail_n      := dbms_xmldom.appendchild( l_site_pay_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAddress' )) );
    l_v_site_con_payemail_tn     := dbms_xmldom.appendchild( l_v_site_con_payemail_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_payemail )) );
    l_v_site_con_payemailpri_n   := dbms_xmldom.appendchild( l_site_pay_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_payemailpri_tn  := dbms_xmldom.appendchild( l_v_site_con_payemailpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_purodemailindflg_n       := dbms_xmldom.appendchild( l_site_pay_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odEmailIndicatorFlag' )) );
    l_v_purodemailindflg_tn      := dbms_xmldom.appendchild( l_v_purodemailindflg_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
  END IF;

  --PP Address
  IF v_site_ppaddr1 IS NOT NULL THEN
    l_addr_element := dbms_xmldom.createelement(l_domdoc, 'sup:address' );
    l_addr_node    := dbms_xmldom.appendchild( l_addr_list_node--l_supplier_node
    , dbms_xmldom.makenode( l_addr_element) );

    l_v_site_ppaddr_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressType' )) );
    l_v_site_ppaddr_type_tn := dbms_xmldom.appendchild( l_v_site_ppaddr_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '99' )) );
    l_v_site_ppseqnum_n     := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sequenceNumber' )) );
    l_v_site_ppseqnum_tn     := dbms_xmldom.appendchild( l_v_site_ppseqnum_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_addr_flag )) );
    l_v_site_ppaction_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:actionType' )) );
    l_v_site_ppaction_type_tn := dbms_xmldom.appendchild( l_v_site_ppaction_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_purpriaddrind_n  := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:primaryAddressIndicator' )) );
    l_v_site_purpriaddrind_tn := dbms_xmldom.appendchild( l_v_site_purpriaddrind_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,'' )) );
    l_v_site_ppaddr1_node := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine1' )) );
    l_v_site_ppaddr1_textnode := dbms_xmldom.appendchild( l_v_site_ppaddr1_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_ppaddr1 )) );
    l_v_site_ppaddr2_node     := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine2' )) );
    l_v_site_ppaddr2_textnode := dbms_xmldom.appendchild( l_v_site_ppaddr2_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_ppaddr2 )) );
    l_v_site_ppaddr3_node     := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine3' )) );
    l_v_site_ppaddr3_textnode := dbms_xmldom.appendchild( l_v_site_ppaddr3_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_ppaddr3 )) );
    l_v_site_ppcity_node      := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:city' )) );
    l_v_site_ppcity_textnode := dbms_xmldom.appendchild( l_v_site_ppcity_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_ppcity )) );
    l_v_site_ppstate_node    := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:state' )) );
    l_v_site_ppstate_textnode := dbms_xmldom.appendchild( l_v_site_ppstate_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_ppstate )) );
    l_v_pp_add_state_abbre_n  := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:stateAbbreviation' )) );
    l_v_pp_add_state_abbre_tn := dbms_xmldom.appendchild( l_v_pp_add_state_abbre_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_ppzip_node       := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:postalCode' )) );
    l_v_site_ppzip_textnode := dbms_xmldom.appendchild( l_v_site_ppzip_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_ppzip )) );
    l_v_site_ppcountry_node := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:country' )) );
    l_v_site_ppcountry_textnode := dbms_xmldom.appendchild( l_v_site_ppcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_ppcountry )) );
    l_v_orgcountry_node         := dbms_xmldom.appendchild( l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:orgCountry' )) );
    l_v_orgcountry_textnode    := dbms_xmldom.appendchild( l_v_orgcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_orgcountry )) );
    l_v_site_pp_add_latitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:latitude' )) );
    l_v_site_pp_add_latitude_tn := dbms_xmldom.appendchild( l_v_site_pp_add_latitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pp_add_longitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:longitude' )) );
    l_v_site_pp_add_longitude_tn := dbms_xmldom.appendchild( l_v_site_pp_add_longitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pp_add_county_n     := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:county' )) );
    l_v_site_pp_add_county_tn  := dbms_xmldom.appendchild( l_v_site_pp_add_county_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pp_add_district_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:district' )) );
    l_v_site_pp_add_district_tn := dbms_xmldom.appendchild( l_v_site_pp_add_district_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_pp_add_spe_notes_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:specialNote' )) );
    L_V_SITE_PP_ADD_SPE_NOTES_TN := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_PP_ADD_SPE_NOTES_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC, '' )) );

    L_V_SITE_pur_od_comment1_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment1' )) );
    L_V_SITE_pur_od_comment1_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment1_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment2_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment2' )) );
    L_V_SITE_pur_od_comment2_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment2_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment3_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment3' )) );
    L_V_SITE_pur_od_comment3_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment3_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment4_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment4' )) );
    L_V_SITE_pur_od_comment4_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment4_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    --od_ship_from_addr_id
    L_V_SITE_pp_SHIP_ADDR_ID_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odShipFromAddressId' )) );
    L_V_SITE_pp_SHIP_ADDR_ID_TN := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pp_SHIP_ADDR_ID_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    --Contact Node
    l_site_pp_cont_list_node := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contactList' )) );
    l_site_pp_contact_node := dbms_xmldom.appendchild( l_site_pp_cont_list_node--l_addr_node--l_site_pp_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contact' )) );
    l_site_pp_contact_pname_node := dbms_xmldom.appendchild( l_site_pp_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:name' )) );

    l_v_site_con_ppfname_n  := dbms_xmldom.appendchild( l_site_pp_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:firstName' )) );
    l_v_site_con_ppfname_tn := dbms_xmldom.appendchild( l_v_site_con_ppfname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_ppmname_n  := dbms_xmldom.appendchild( l_site_pp_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:middleName' )) );
    l_v_site_con_ppmname_tn := dbms_xmldom.appendchild( l_v_site_con_ppmname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_pplname_n  := dbms_xmldom.appendchild( l_site_pp_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:lastName' )) );
    l_v_site_con_pplname_tn := dbms_xmldom.appendchild( l_v_site_con_pplname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_ppname_n   := dbms_xmldom.appendchild( l_site_pp_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:fullName' )) );
    l_v_site_con_ppname_tn  := dbms_xmldom.appendchild( l_v_site_con_ppname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_ppname )) );

    l_site_pp_cont_ptitle_node := dbms_xmldom.appendchild( l_site_pp_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:title' )) );

    l_v_pp_con_salutation_n := dbms_xmldom.appendchild(l_site_pp_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:salutation' )) );
    l_v_pp_con_salutation_tn := dbms_xmldom.appendchild( l_v_pp_con_salutation_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );
    l_v_pp_con_jobtitle_n    := dbms_xmldom.appendchild(l_site_pp_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:jobTitle' )) );
    l_v_pp_con_jobtitle_tn := dbms_xmldom.appendchild( l_v_pp_con_jobtitle_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );

    l_site_pp_cont_ph_node := dbms_xmldom.appendchild( l_site_pp_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:phones' )) );
    l_site_pp_cont_phasso_node := dbms_xmldom.appendchild( l_site_pp_cont_ph_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_ppphtype_n  := dbms_xmldom.appendchild(l_site_pp_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_ppphtype_tn := dbms_xmldom.appendchild( l_v_site_con_ppphtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'Phone' )) );

    l_v_site_con_ppphone_n      := dbms_xmldom.appendchild(l_site_pp_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_ppphareacode_n := dbms_xmldom.appendchild(l_v_site_con_ppphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

    IF v_site_contact_ppphone   IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_ppphone,1,3) INTO l_v_ppareacode FROM dual;
    ELSE
      l_v_ppareacode := '';
    END IF;

    l_v_site_con_ppphareacode_tn := dbms_xmldom.appendchild( l_v_site_con_ppphareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_ppareacode ))--
    );
    l_v_site_con_ppphcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_ppphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_ppphcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_ppphcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );

    l_v_site_con_ppph_n := dbms_xmldom.appendchild( l_v_site_con_ppphone_n--l_site_pay_contact_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

    IF v_site_contact_ppphone IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_ppphone,4,10) INTO l_v_ppph FROM dual;
    ELSE
      l_v_ppph := '';
    END IF;

    l_v_site_con_ppph_tn := dbms_xmldom.appendchild( l_v_site_con_ppph_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_ppph )) );

    l_v_site_con_ppphext_n  := dbms_xmldom.appendchild(l_v_site_con_ppphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_ppphext_tn := dbms_xmldom.appendchild( l_v_site_con_ppphext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_ppphpri_n  := dbms_xmldom.appendchild(l_site_pp_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_ppphpri_tn := dbms_xmldom.appendchild( l_v_site_con_ppphpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_v_odphnbrext_n  := dbms_xmldom.appendchild(l_site_pp_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhoneNumberExt' )) );
    l_v_odphnbrext_tn := dbms_xmldom.appendchild( l_v_odphnbrext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_odph800nbr_n  := dbms_xmldom.appendchild(l_site_pp_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhone800Number' )) );
    l_v_odph800nbr_tn := dbms_xmldom.appendchild( l_v_odph800nbr_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_site_pp_cont_fax_node := dbms_xmldom.appendchild( l_site_pp_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:fax' )) );
    l_site_pp_cont_faxasso_node := dbms_xmldom.appendchild( l_site_pp_cont_fax_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_ppfaxtype_n  := dbms_xmldom.appendchild(l_site_pp_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_ppfaxtype_tn := dbms_xmldom.appendchild( l_v_site_con_ppfaxtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'fax' )) );

    l_v_site_con_ppfax_n         := dbms_xmldom.appendchild(l_site_pp_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_ppfaxareacode_n := dbms_xmldom.appendchild(l_v_site_con_ppfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

    IF v_site_contact_ppfax      IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_ppfax,1,3) INTO l_v_ppfaxareacode FROM dual;
    ELSE
      l_v_ppfaxareacode := '';
    END IF;

    l_v_site_con_ppfaxareacode_tn := dbms_xmldom.appendchild( l_v_site_con_ppfaxareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_ppfaxareacode ))--
    );
    l_v_site_con_ppfxcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_ppfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_ppfxcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_ppfxcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );

    l_v_site_con_ppfx_n     := dbms_xmldom.appendchild(l_v_site_con_ppfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

    IF v_site_contact_ppfax IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_ppfax,4,10) INTO l_v_ppfax FROM dual;
    ELSE
      l_v_ppfax := '';
    END IF;

    l_v_site_con_ppfx_tn := dbms_xmldom.appendchild( l_v_site_con_ppfx_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_ppfax )) );

    l_v_site_con_ppfaxext_n  := dbms_xmldom.appendchild(l_v_site_con_ppfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_ppfaxext_tn := dbms_xmldom.appendchild( l_v_site_con_ppfaxext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_ppfaxpri_n  := dbms_xmldom.appendchild(l_site_pp_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_ppfaxpri_tn := dbms_xmldom.appendchild( l_v_site_con_ppfaxpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_site_pp_cont_email_node := dbms_xmldom.appendchild( l_site_pp_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:emails' )) );
    l_site_pp_cont_emailasso_node := dbms_xmldom.appendchild( l_site_pp_cont_email_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAssociation' )) );
    l_v_site_con_ppemailtype_n  := dbms_xmldom.appendchild(l_site_pp_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailType' )) );
    l_v_site_con_ppemailtype_tn := dbms_xmldom.appendchild( l_v_site_con_ppemailtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_ppemail_n      := dbms_xmldom.appendchild( l_site_pp_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAddress' )) );
    l_v_site_con_ppemail_tn     := dbms_xmldom.appendchild( l_v_site_con_ppemail_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_ppemail )) );
    l_v_site_con_ppemailpri_n   := dbms_xmldom.appendchild( l_site_pp_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_ppemailpri_tn  := dbms_xmldom.appendchild( l_v_site_con_ppemailpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_purodemailindflg_n      := dbms_xmldom.appendchild( l_site_pp_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odEmailIndicatorFlag' )) );
    l_v_purodemailindflg_tn     := dbms_xmldom.appendchild( l_v_purodemailindflg_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
  END IF;

  --RTV Address
  IF v_site_rtvaddr1 IS NOT NULL THEN
    l_addr_element := dbms_xmldom.createelement(l_domdoc, 'sup:address' );
    l_addr_node    := dbms_xmldom.appendchild( l_addr_list_node--l_supplier_node
    , dbms_xmldom.makenode( l_addr_element) );

    l_v_site_rtvaddr_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressType' )) );
    l_v_site_rtvaddr_type_tn := dbms_xmldom.appendchild( l_v_site_rtvaddr_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '99' )) );
    l_v_site_rtvseqnum_n     := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sequenceNumber' )) );
    l_v_site_rtvseqnum_tn     := dbms_xmldom.appendchild( l_v_site_rtvseqnum_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_addr_flag )) );
    l_v_site_rtvaction_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:actionType' )) );
    l_v_site_rtvaction_type_tn := dbms_xmldom.appendchild( l_v_site_rtvaction_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_purpriaddrind_n   := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:primaryAddressIndicator' )) );
    l_v_site_purpriaddrind_tn := dbms_xmldom.appendchild( l_v_site_purpriaddrind_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,'' )) );
    l_v_site_rtvaddr1_node := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine1' )) );
    l_v_site_rtvaddr1_textnode := dbms_xmldom.appendchild( l_v_site_rtvaddr1_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_rtvaddr1 )) );
    l_v_site_rtvaddr2_node     := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine2' )) );
    l_v_site_rtvaddr2_textnode := dbms_xmldom.appendchild( l_v_site_rtvaddr2_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_rtvaddr2 )) );
    l_v_site_rtvaddr3_node     := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine3' )) );
    l_v_site_rtvaddr3_textnode := dbms_xmldom.appendchild( l_v_site_rtvaddr3_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_rtvaddr3 )) );
    l_v_site_rtvcity_node      := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:city' )) );
    l_v_site_rtvcity_textnode := dbms_xmldom.appendchild( l_v_site_rtvcity_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_rtvcity )) );
    l_v_site_rtvstate_node    := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:state' )) );
    l_v_site_rtvstate_textnode := dbms_xmldom.appendchild( l_v_site_rtvstate_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_rtvstate )) );
    l_v_rtv_add_state_abbre_n  := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:stateAbbreviation' )) );
    l_v_rtv_add_state_abbre_tn := dbms_xmldom.appendchild( l_v_rtv_add_state_abbre_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_rtvzip_node       := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:postalCode' )) );
    l_v_site_rtvzip_textnode := dbms_xmldom.appendchild( l_v_site_rtvzip_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_rtvzip )) );
    l_v_site_rtvcountry_node := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:country' )) );
    l_v_site_rtvcountry_textnode := dbms_xmldom.appendchild( l_v_site_rtvcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_rtvcountry )) );
    l_v_orgcountry_node          := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:orgCountry' )) );
    l_v_orgcountry_textnode     := dbms_xmldom.appendchild( l_v_orgcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_orgcountry )) );
    l_v_site_rtv_add_latitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:latitude' )) );
    l_v_site_rtv_add_latitude_tn := dbms_xmldom.appendchild( l_v_site_rtv_add_latitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_rtv_add_longitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:longitude' )) );
    l_v_site_rtv_add_longitude_tn := dbms_xmldom.appendchild( l_v_site_rtv_add_longitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_rtv_add_county_n     := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:county' )) );
    l_v_site_rtv_add_county_tn  := dbms_xmldom.appendchild( l_v_site_rtv_add_county_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_rtv_add_district_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:district' )) );
    l_v_site_rtv_add_district_tn := dbms_xmldom.appendchild( l_v_site_rtv_add_district_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_rtv_add_spe_notes_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATEELEMENT(L_DOMDOC, 'sup:specialNote' )) );
    l_v_site_rtv_add_spe_notes_tn := dbms_xmldom.appendchild( l_v_site_rtv_add_spe_notes_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    L_V_SITE_pur_od_comment1_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment1' )) );
    L_V_SITE_pur_od_comment1_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment1_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment2_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment2' )) );
    L_V_SITE_pur_od_comment2_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment2_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment3_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment3' )) );
    L_V_SITE_pur_od_comment3_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment3_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );
    L_V_SITE_pur_od_comment4_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment4' )) );
    L_V_SITE_pur_od_comment4_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_pur_od_comment4_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    ---od_ship_from_addr_id
    L_V_SITE_RTV_SHIP_ADDR_ID_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odShipFromAddressId' )) );
    L_V_SITE_RTV_SHIP_ADDR_ID_tN := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_RTV_SHIP_ADDR_ID_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,'' )) );

    --Contact Node
    l_site_rtv_cont_list_node := dbms_xmldom.appendchild(l_addr_node-- l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contactList' )) );
    l_site_rtv_contact_node := dbms_xmldom.appendchild(l_site_rtv_cont_list_node--l_addr_node-- l_site_rtv_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contact' )) );
    l_site_rtv_contact_pname_node := dbms_xmldom.appendchild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:name' )) );

    l_v_site_con_rtvfname_n     := dbms_xmldom.appendchild( l_site_rtv_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:firstName' )) );
    l_v_site_con_rtvfname_tn    := dbms_xmldom.appendchild( l_v_site_con_rtvfname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_rtvmname_n     := dbms_xmldom.appendchild( l_site_rtv_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:middleName' )) );
    l_v_site_con_rtvmname_tn    := dbms_xmldom.appendchild( l_v_site_con_rtvmname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_rtvlname_n     := dbms_xmldom.appendchild( l_site_rtv_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:lastName' )) );
    l_v_site_con_rtvlname_tn    := dbms_xmldom.appendchild( l_v_site_con_rtvlname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_rtvname_n      := dbms_xmldom.appendchild( l_site_rtv_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:fullName' )) );
    l_v_site_con_rtvname_tn     := dbms_xmldom.appendchild( l_v_site_con_rtvname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_rtvname )) );
    l_site_rtv_cont_ptitle_node := dbms_xmldom.appendchild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:title' )) );

    l_v_rtv_con_salutation_n := dbms_xmldom.appendchild(l_site_rtv_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:salutation' )) );
    l_v_rtv_con_salutation_tn := dbms_xmldom.appendchild( l_v_rtv_con_salutation_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );
    l_v_rtv_con_jobtitle_n    := dbms_xmldom.appendchild(l_site_rtv_cont_ptitle_node--l_addr_node-- l_address_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:jobTitle' )) );
    l_v_rtv_con_jobtitle_tn := dbms_xmldom.appendchild( l_v_rtv_con_jobtitle_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );

    l_site_rtv_cont_ph_node := dbms_xmldom.appendchild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:phones' )) );
    l_site_rtv_cont_phasso_node := dbms_xmldom.appendchild( l_site_rtv_cont_ph_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_rtvphtype_n  := dbms_xmldom.appendchild(l_site_rtv_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_rtvphtype_tn := dbms_xmldom.appendchild( l_v_site_con_rtvphtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'Phone' )) );

    l_v_site_con_rtvphone_n      := dbms_xmldom.appendchild(l_site_rtv_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_rtvphareacode_n := dbms_xmldom.appendchild(l_v_site_con_rtvphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );
    IF v_site_contact_rtvphone   IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_rtvphone,1,3) INTO l_v_rtvareacode FROM dual;
    ELSE
      l_v_rtvareacode := '';
    END IF;
    l_v_site_con_rtvphareacode_tn := dbms_xmldom.appendchild( l_v_site_con_rtvphareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_rtvareacode ))--
    );
    l_v_site_con_rtvphcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_rtvphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_rtvphcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_rtvphcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );

    l_v_site_con_rtvph_n := dbms_xmldom.appendchild( l_v_site_con_rtvphone_n--l_site_pay_contact_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

    IF v_site_contact_rtvphone IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_rtvphone,4,10) INTO l_v_rtvph FROM dual;
    ELSE
      l_v_rtvph := '';
    END IF;

    l_v_site_con_rtvph_tn := dbms_xmldom.appendchild( l_v_site_con_rtvph_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_rtvph )) );

    l_v_site_con_rtvphext_n  := dbms_xmldom.appendchild(l_v_site_con_rtvphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_rtvphext_tn := dbms_xmldom.appendchild( l_v_site_con_rtvphext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_rtvphpri_n  := dbms_xmldom.appendchild(l_site_rtv_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_rtvphpri_tn := dbms_xmldom.appendchild( l_v_site_con_rtvphpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_v_odphnbrext_n  := dbms_xmldom.appendchild(l_site_rtv_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhoneNumberExt' )) );
    l_v_odphnbrext_tn := dbms_xmldom.appendchild( l_v_odphnbrext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_odph800nbr_n  := dbms_xmldom.appendchild(l_site_rtv_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhone800Number' )) );
    l_v_odph800nbr_tn := dbms_xmldom.appendchild( l_v_odph800nbr_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_site_rtv_cont_fax_node := dbms_xmldom.appendchild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:fax' )) );
    l_site_rtv_cont_faxasso_node := dbms_xmldom.appendchild( l_site_rtv_cont_fax_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
    l_v_site_con_rtvfaxtype_n  := dbms_xmldom.appendchild(l_site_rtv_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
    l_v_site_con_rtvfaxtype_tn := dbms_xmldom.appendchild( l_v_site_con_rtvfaxtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'fax' )) );

    l_v_site_con_rtvfax_n         := dbms_xmldom.appendchild(l_site_rtv_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
    l_v_site_con_rtvfaxareacode_n := dbms_xmldom.appendchild(l_v_site_con_rtvfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

    IF v_site_contact_rtvfax      IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_rtvfax,1,3) INTO l_v_rtvfaxareacode FROM dual;
    ELSE
      l_v_rtvfaxareacode := '';
    END IF;

    l_v_site_con_rtvfaxareacode_tn := dbms_xmldom.appendchild( l_v_site_con_rtvfaxareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_rtvfaxareacode ))--
    );
    l_v_site_con_rtvfxcntrycode_n  := dbms_xmldom.appendchild(l_v_site_con_rtvfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
    l_v_site_con_rtvfxcntrycode_tn := dbms_xmldom.appendchild( l_v_site_con_rtvfxcntrycode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
    );

    l_v_site_con_rtvfx_n     := dbms_xmldom.appendchild(l_v_site_con_rtvfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

    IF v_site_contact_rtvfax IS NOT NULL THEN
      SELECT SUBSTR(v_site_contact_rtvfax,4,10) INTO l_v_rtvfax FROM dual;
    ELSE
      l_v_rtvfax := '';
    END IF;

    l_v_site_con_rtvfx_tn := dbms_xmldom.appendchild( l_v_site_con_rtvfx_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_rtvfax )) );

    l_v_site_con_rtvfaxext_n  := dbms_xmldom.appendchild(l_v_site_con_rtvfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
    l_v_site_con_rtvfaxext_tn := dbms_xmldom.appendchild( l_v_site_con_rtvfaxext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_rtvfaxpri_n  := dbms_xmldom.appendchild(l_site_rtv_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_rtvfaxpri_tn := dbms_xmldom.appendchild( l_v_site_con_rtvfaxpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

    l_site_rtv_cont_email_node := dbms_xmldom.appendchild( l_site_rtv_contact_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:emails' )) );
    l_site_rtv_cont_emailasso_node := dbms_xmldom.appendchild( l_site_rtv_cont_email_node--l_addr_node--l_site_addr_node
    , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAssociation' )) );
    l_v_site_con_rtvemailtype_n  := dbms_xmldom.appendchild(l_site_rtv_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailType' )) );
    l_v_site_con_rtvemailtype_tn := dbms_xmldom.appendchild( l_v_site_con_rtvemailtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_site_con_rtvemail_n      := dbms_xmldom.appendchild( l_site_rtv_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAddress' )) );
    l_v_site_con_rtvemail_tn     := dbms_xmldom.appendchild( l_v_site_con_rtvemail_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, v_site_contact_rtvemail )) );
    l_v_site_con_rtvemailpri_n   := dbms_xmldom.appendchild( l_site_rtv_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
    l_v_site_con_rtvemailpri_tn  := dbms_xmldom.appendchild( l_v_site_con_rtvemailpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    l_v_purodemailindflg_n       := dbms_xmldom.appendchild( l_site_rtv_cont_emailasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odEmailIndicatorFlag' )) );
    l_v_purodemailindflg_tn      := dbms_xmldom.appendchild( l_v_purodemailindflg_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
  END IF;

  ---Address Type

  BEGIN

    FOR r_address_data IN c_address_data
    -- open cursor c_address_type
    LOOP
      l_addr_element := dbms_xmldom.createelement(l_domdoc, 'sup:address' );
      l_addr_node    := dbms_xmldom.appendchild( l_addr_list_node--l_supplier_node
      , dbms_xmldom.makenode( l_addr_element) );
      l_v_addr_01_addr_type_node := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressType' )) );

      IF LENGTH(r_address_data.address_type)=1 THEN
        SELECT lpad(TO_CHAR(r_address_data.address_type),2,'0')
        INTO p_address_type1
        FROM DUAL;
      ELSE
        p_address_type1:=r_address_data.address_type;
      END IF;

      l_v_addr_01_addr_type_textnode := dbms_xmldom.appendchild( l_v_addr_01_addr_type_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, p_address_type1 )) );

      l_v_site_addr_01_seqnum_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sequenceNumber' )) );
      l_v_site_addr_01_seqnum_tn  := dbms_xmldom.appendchild( l_v_site_addr_01_seqnum_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, r_address_data.seq_no )) );
      l_v_site_addr_action_type_n := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:actionType' )) );
      l_v_site_addr_action_type_tn := dbms_xmldom.appendchild( l_v_site_addr_action_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_add_priaddrind_n         := dbms_xmldom.appendchild( l_addr_node--l_site_purch_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:primaryAddressIndicator' )) );
      l_v_add_priaddrind_tn := dbms_xmldom.appendchild( l_v_add_priaddrind_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,r_address_data.primary_addr_ind )) );

      l_v_addr1_node := dbms_xmldom.appendchild(l_addr_node --l_site_addr_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine1' )) );
      l_v_addr1_textnode := dbms_xmldom.appendchild( l_v_addr1_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.add_1,'') )) );
      l_v_addr2_node     := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine2' )) );
      l_v_addr2_textnode := dbms_xmldom.appendchild( l_v_addr2_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.add_2,'') )) );
      l_v_addr3_node     := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:addressLine3' )) );
      l_v_addr3_textnode := dbms_xmldom.appendchild( l_v_addr3_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.add_3,'') )) );
      l_v_addr_city_node := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:city' )) );
      l_v_addr_city_textnode := dbms_xmldom.appendchild( l_v_addr_city_node--l_v_addr_city_node
      , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.city,'') )) );
      l_v_addr_state_node := dbms_xmldom.appendchild(l_addr_node-- l_site_addr_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:state' )) );
      l_v_addr_state_textnode := dbms_xmldom.appendchild( l_v_addr_state_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.state,'') )) );
      l_v_add_state_abbre_n   := dbms_xmldom.appendchild( l_addr_node--l_site_rtv_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:stateAbbreviation' )) );
      l_v_add_state_abbre_tn := dbms_xmldom.appendchild( l_v_add_state_abbre_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_addr_zip_node      := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:postalCode' )) );
      l_v_addr_zip_textnode := dbms_xmldom.appendchild( l_v_addr_zip_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.post,'') )) );
      l_v_addr_country_node := dbms_xmldom.appendchild(l_addr_node--l_site_addr_node-- l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:country' )) );
      l_v_addr_country_textnode := dbms_xmldom.appendchild( l_v_addr_country_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.country_id,'') )) );
      l_v_orgcountry_node       := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:orgCountry' )) );
      l_v_orgcountry_textnode := dbms_xmldom.appendchild( l_v_orgcountry_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(v_orgcountry,'') )) );
      l_v_add_latitude_n      := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:latitude' )) );
      l_v_add_latitude_tn := dbms_xmldom.appendchild( l_v_add_latitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_add_longitude_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:longitude' )) );
      l_v_add_longitude_tn := dbms_xmldom.appendchild( l_v_add_longitude_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_add_county_n     := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:county' )) );
      l_v_add_county_tn  := dbms_xmldom.appendchild( l_v_add_county_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_add_district_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:district' )) );
      l_v_add_district_tn := dbms_xmldom.appendchild( l_v_add_district_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_add_spe_notes_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:specialNote' )) );
      l_v_add_spe_notes_tn := dbms_xmldom.appendchild( l_v_add_spe_notes_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

      L_V_SITE_add_od_comment1_N := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment1' )) );
      L_V_SITE_add_od_comment1_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_add_od_comment1_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,r_address_data.od_comment_1 )) );
      l_v_site_add_od_comment2_n  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment2' )) );
      L_V_SITE_add_od_comment2_tn:= DBMS_XMLDOM.APPENDCHILD( L_V_SITE_add_od_comment2_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,r_address_data.od_comment_2 )) );
      l_v_site_add_od_comment3_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment3' )) );
      L_V_SITE_add_od_comment3_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_add_od_comment3_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,r_address_data.od_comment_3 )) );
      L_V_SITE_add_od_comment4_N  := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odComment4' )) );
      L_V_SITE_add_od_comment4_tn := DBMS_XMLDOM.APPENDCHILD( L_V_SITE_add_od_comment4_N , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC,r_address_data.od_comment_4 )) );

      ---od_ship_from_addr_id
      l_v_od_ship_from_addr_id_n := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odShipFromAddressId' )) );
      l_v_od_ship_from_addr_id_tn := DBMS_XMLDOM.APPENDCHILD( l_v_od_ship_from_addr_id_n , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC, r_address_data.od_ship_from_addr_id )) );

      --contact node
      l_site_addr_cont_list_node := dbms_xmldom.appendchild( l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contactList' )) );
      l_site_addr_contact_node := dbms_xmldom.appendchild(l_site_addr_cont_list_node-- l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contact' )) );
      l_site_addr_contact_pname_node := dbms_xmldom.appendchild( l_site_addr_contact_node--l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:name' )) );

      l_v_site_con_addfname_n  := dbms_xmldom.appendchild( l_site_addr_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:firstName' )) );
      l_v_site_con_addfname_tn := dbms_xmldom.appendchild( l_v_site_con_addfname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_site_con_addmname_n  := dbms_xmldom.appendchild( l_site_addr_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:middleName' )) );
      l_v_site_con_addmname_tn := dbms_xmldom.appendchild( l_v_site_con_addmname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_site_con_addlname_n  := dbms_xmldom.appendchild( l_site_addr_contact_pname_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:lastName' )) );
      l_v_site_con_addlname_tn := dbms_xmldom.appendchild( l_v_site_con_addlname_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

      l_v_addr_con_name_node := dbms_xmldom.appendchild(l_site_addr_contact_pname_node--l_addr_node-- l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:fullName' )) );
      l_v_addr_con_name_textnode   := dbms_xmldom.appendchild( l_v_addr_con_name_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, NVL(r_address_data.contact_name,''))) );
      l_site_addr_cont_ptitle_node := dbms_xmldom.appendchild( l_site_addr_contact_node--l_addr_node--l_site_addr_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:title' )) );

      l_v_addr_con_salutation_n    := dbms_xmldom.appendchild(l_site_addr_cont_ptitle_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:salutation' )) );
      l_v_addr_con_salutation_tn   := dbms_xmldom.appendchild( l_v_addr_con_salutation_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );
      l_v_addr_con_jobtitle_n      := dbms_xmldom.appendchild(l_site_addr_cont_ptitle_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:jobTitle' )) );
      l_v_addr_con_jobtitle_tn     := dbms_xmldom.appendchild( l_v_addr_con_jobtitle_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '')) );
      l_site_addr_cont_ph_node     := dbms_xmldom.appendchild( l_site_addr_contact_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:phones' )) );
      l_site_addr_cont_phasso_node := dbms_xmldom.appendchild( l_site_addr_cont_ph_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
      l_v_site_con_addrphtype_n    := dbms_xmldom.appendchild(l_site_addr_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
      l_v_site_con_addrphtype_tn   := dbms_xmldom.appendchild( l_v_site_con_addrphtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'Phone' )) );

      l_v_site_con_addrphone_n        := dbms_xmldom.appendchild(l_site_addr_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
      l_v_site_con_addrphareacode_n   := dbms_xmldom.appendchild(l_v_site_con_addrphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

      IF r_address_data.contact_phone IS NOT NULL THEN
        SELECT SUBSTR(r_address_data.contact_phone,1,3)
        INTO l_v_addrareacode
        FROM dual;
      ELSE
        l_v_addrareacode := '';
      END IF;

      l_v_site_con_addrphareacode_tn := dbms_xmldom.appendchild( l_v_site_con_addrphareacode_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_addrareacode ))--
      );
      l_v_site_con_addrphcntrycd_n  := dbms_xmldom.appendchild(l_v_site_con_addrphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
      l_v_site_con_addrphcntrycd_tn := dbms_xmldom.appendchild( l_v_site_con_addrphcntrycd_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
      );

      l_v_addr_con_ph_node := dbms_xmldom.appendchild( l_v_site_con_addrphone_n--l_site_pay_contact_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

      IF r_address_data.contact_phone IS NOT NULL THEN
        SELECT SUBSTR(r_address_data.contact_phone,4,10) INTO l_v_addrph FROM dual;
      ELSE
        l_v_addrph := '';
      END IF;

      l_v_addr_con_ph_textnode := dbms_xmldom.appendchild( l_v_addr_con_ph_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_addrph )) );

      l_v_site_con_addrphext_n  := dbms_xmldom.appendchild(l_v_site_con_addrphone_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
      l_v_site_con_addrphext_tn := dbms_xmldom.appendchild( l_v_site_con_addrphext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_site_con_addrphpri_n  := dbms_xmldom.appendchild(l_site_addr_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
      l_v_site_con_addrphpri_tn := dbms_xmldom.appendchild( l_v_site_con_addrphpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

      l_v_add_odphnbrext_n  := dbms_xmldom.appendchild(l_site_addr_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhoneNumberExt' )) );
      l_v_add_odphnbrext_tn := dbms_xmldom.appendchild( l_v_add_odphnbrext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, r_address_data.od_phone_nbr_ext )) );
      l_v_add_odph800nbr_n  := dbms_xmldom.appendchild(l_site_addr_cont_phasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odPhone800Number' )) );
      l_v_add_odph800nbr_tn := dbms_xmldom.appendchild( l_v_add_odph800nbr_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, r_address_data.od_phone_800_nbr )) );

      l_site_addr_cont_fax_node     := dbms_xmldom.appendchild( l_site_addr_contact_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:fax' )) );
      l_site_addr_cont_faxasso_node := dbms_xmldom.appendchild( l_site_addr_cont_fax_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneAssociation' )) );
      l_v_site_con_addrfaxtype_n    := dbms_xmldom.appendchild(l_site_addr_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneType' )) );
      l_v_site_con_addrfaxtype_tn   := dbms_xmldom.appendchild( l_v_site_con_addrfaxtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, 'fax' )) );
      l_v_site_con_addrfax_n        := dbms_xmldom.appendchild(l_site_addr_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phone' )) );
      l_v_site_con_addrfaxareacd_n  := dbms_xmldom.appendchild(l_v_site_con_addrfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:areaCode' )) );

      IF r_address_data.contact_fax IS NOT NULL THEN
        SELECT SUBSTR(r_address_data.contact_fax,1,3)
        INTO l_v_addrfaxareacode
        FROM dual;
      ELSE
        l_v_addrfaxareacode := ' ';
      END IF;

      l_v_site_con_addrfaxareacd_tn := dbms_xmldom.appendchild( l_v_site_con_addrfaxareacd_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_addrfaxareacode ))--
      );
      l_v_site_con_addrfxcntrycd_n  := dbms_xmldom.appendchild(l_v_site_con_addrfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:countryCode' )) );
      l_v_site_con_addrfxcntrycd_tn := dbms_xmldom.appendchild( l_v_site_con_addrfxcntrycd_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' ))--
      );

      l_v_addr_con_fax_node         := dbms_xmldom.appendchild(l_v_site_con_addrfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:phoneNumber' )) );

      IF r_address_data.contact_fax IS NOT NULL THEN
        SELECT SUBSTR(r_address_data.contact_fax,4,10) INTO l_v_addrfax FROM dual;
      ELSE
        l_v_addrfax := '';
      END IF;

      l_v_addr_con_fax_textnode := dbms_xmldom.appendchild( l_v_addr_con_fax_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, l_v_addrfax )) );

      l_v_site_con_addrfaxext_n  := dbms_xmldom.appendchild(l_v_site_con_addrfax_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:extension' )) );
      l_v_site_con_addrfaxext_tn := dbms_xmldom.appendchild( l_v_site_con_addrfaxext_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_site_con_addrfaxpri_n  := dbms_xmldom.appendchild(l_site_addr_cont_faxasso_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
      l_v_site_con_addrfaxpri_tn := dbms_xmldom.appendchild( l_v_site_con_addrfaxpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );

      l_site_addr_cont_email_node   := dbms_xmldom.appendchild( l_site_addr_contact_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:emails' )) );
      l_site_addr_cont_emailasso_n  := dbms_xmldom.appendchild( l_site_addr_cont_email_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAssociation' )) );
      l_v_site_con_addremailtype_n  := dbms_xmldom.appendchild(l_site_addr_cont_emailasso_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailType' )) );
      l_v_site_con_addremailtype_tn := dbms_xmldom.appendchild( l_v_site_con_addremailtype_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_addr_con_email_node       := dbms_xmldom.appendchild( l_site_addr_cont_emailasso_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:emailAddress' )) );
      L_V_ADDR_CON_EMAIL_TEXTNODE   := DBMS_XMLDOM.APPENDCHILD( L_V_ADDR_CON_EMAIL_NODE , DBMS_XMLDOM.MAKENODE(DBMS_XMLDOM.CREATETEXTNODE(L_DOMDOC, NVL(R_ADDRESS_DATA.CONTACT_EMAIL,'') )) );
      l_v_site_con_addremailpri_n   := dbms_xmldom.appendchild( l_site_addr_cont_emailasso_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:isPrimary' )) );
      l_v_site_con_addremailpri_tn  := dbms_xmldom.appendchild( l_v_site_con_addremailpri_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_v_addodemailindflg_n        := dbms_xmldom.appendchild( l_site_addr_cont_emailasso_n , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'odc:odEmailIndicatorFlag' )) );
      l_v_addodemailindflg_tn       := dbms_xmldom.appendchild( l_v_addodemailindflg_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, r_address_data.od_email_ind_flg )) );
    END LOOP;
  END;

  --Supplier Traits
  BEGIN
    -- Create a new node supplier traits node  and add it to the supplier node
    l_supplier_traits_node := dbms_xmldom.appendchild( l_supplier_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierTraitList' )) );

    FOR r_sup_traits IN c_sup_traits
    LOOP
      l_supplier_trait_node     := dbms_xmldom.appendchild( l_supplier_traits_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierTrait')) );
      l_sup_trait_action_type_n := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:actionType' )) );
      l_sup_trait_action_type_tn := dbms_xmldom.appendchild( l_sup_trait_action_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_sup_trait_node           := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierTrait' )) );
      l_sup_trait_textnode  := dbms_xmldom.appendchild( l_sup_trait_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, r_sup_traits.sup_trait )) );
      l_sup_trait_desc_node := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierTraitDescription' )) );
      l_sup_trait_desc_textnode := dbms_xmldom.appendchild( l_sup_trait_desc_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, r_sup_traits.description )) );
      l_sup_master_sup_ind_node := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:masterSuppIndicator' )) );
      l_sup_master_sup_ind_textnode := dbms_xmldom.appendchild( l_sup_master_sup_ind_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, r_sup_traits.master_sup_ind )) );
      sup_trait_rows                := c_sup_traits %rowcount;
    END LOOP;

    IF sup_trait_rows            =0 THEN
      l_supplier_trait_node     := dbms_xmldom.appendchild( l_supplier_traits_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierTrait')) );
      l_sup_trait_action_type_n := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:actionType' )) );
      l_sup_trait_action_type_tn := dbms_xmldom.appendchild( l_sup_trait_action_type_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_sup_trait_node           := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierTrait' )) );
      l_sup_trait_textnode  := dbms_xmldom.appendchild( l_sup_trait_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,'' )) );
      l_sup_trait_desc_node := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierTraitDescription' )) );
      l_sup_trait_desc_textnode := dbms_xmldom.appendchild( l_sup_trait_desc_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
      l_sup_master_sup_ind_node := dbms_xmldom.appendchild( l_supplier_trait_node--l_addr_node--l_address_node
      , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:masterSuppIndicator' )) );
      l_sup_master_sup_ind_textnode := dbms_xmldom.appendchild( l_sup_master_sup_ind_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc, '' )) );
    END IF;

  END;

  --Custom Attributes
  -- Create a new node Custom Attributes  and add it to the supplier node
  l_cust_attributes_node := dbms_xmldom.appendchild( l_supplier_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:customAttributes' )) );

  --KFF

  -- Each Site node will get Lead Time
  l_v_lead_time_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:leadTime' )) );
  l_v_lead_time_textnode := dbms_xmldom.appendchild( l_v_lead_time_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_lead_time)) );

  -- Each Site node will get Back Order Flag
  l_v_back_order_flag_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:backOrderFlag' )) );
  l_v_back_order_flag_textnode := dbms_xmldom.appendchild( l_v_back_order_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_back_order_flag)) );

  -- Each Site node will get Delivery Policy
  l_v_delivery_policy_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:deliveryPolicy' )) );
  l_v_delivery_policy_textnode := dbms_xmldom.appendchild( l_v_delivery_policy_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_delivery_policy)) );

  -- Each Site node will get Min Prepaid Code
  l_v_min_prepaid_code_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minPrepaidCode' )) );
  l_v_min_prepaid_code_textnode := dbms_xmldom.appendchild( l_v_min_prepaid_code_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_min_prepaid_code)) );

  -- Each Site node will get Min  Amount
  l_v_vendor_min_amount_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vendorMinAmount' )) );
  l_v_vendor_min_amount_textnode := dbms_xmldom.appendchild( l_v_vendor_min_amount_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_vendor_min_amount)) );

  -- Each Site node will get Supplier ship-to
  l_v_supplier_ship_to_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:supplierShipTo' )) );
  l_v_supplier_ship_to_textnode := dbms_xmldom.appendchild( l_v_supplier_ship_to_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_supplier_ship_to)) );

  -- Each Site node will get Inventory Type Code
  l_v_inventory_type_code_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:inventoryTypeCode' )) );
  l_v_inventory_type_code_tn := dbms_xmldom.appendchild( l_v_inventory_type_code_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_inventory_type_code)) );

  -- Each Site node will get Vertical Market Indicator
  l_v_ver_market_indicator_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:verticalMarketIndicator' )) );
  l_v_ver_market_indicator_tn := dbms_xmldom.appendchild( l_v_ver_market_indicator_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_vertical_market_indicator)) );

  -- Each Site node will get Allow Auto-Receipt
  l_v_allow_auto_receipt_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:allowAutoReceipt' )) );
  l_v_allow_auto_receipt_tn := dbms_xmldom.appendchild( l_v_allow_auto_receipt_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_allow_auto_receipt)) );

  -- Each Site node will get Handling
  l_v_handling_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:handling' )) );
  l_v_handling_textnode := dbms_xmldom.appendchild( l_v_handling_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_handling)) );

  -- Each Site node will get Eft Settle Days
  l_v_eft_settle_days_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:effectiveSettleDays' )) );
  l_v_eft_settle_days_textnode := dbms_xmldom.appendchild( l_v_eft_settle_days_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_eft_settle_days)) );

  -- Each Site node will get Split File Flag
  l_v_split_file_flag_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:splitFileFlag' )) );
  l_v_split_file_flag_textnode := dbms_xmldom.appendchild( l_v_split_file_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_split_file_flag)) );

  -- Each Site node will get Master Vendor Id
  l_v_master_vendor_id_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:masterVendorId' )) );
  l_v_master_vendor_id_textnode := dbms_xmldom.appendchild( l_v_master_vendor_id_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_master_vendor_id)) );

  -- Each Site node will get Pi Pack Year
  l_v_pi_pack_year_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:piPackYear' )) );
  l_v_pi_pack_year_textnode := dbms_xmldom.appendchild( l_v_pi_pack_year_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_pi_pack_year)) );

  -- Each Site node will get OD Date Signed
  l_v_od_date_signed_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odDateSigned' )) );
  l_v_od_date_signed_tn := dbms_xmldom.appendchild( l_v_od_date_signed_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_od_date_signed)) );

  -- Each Site node will get Vendor Date Signed
  l_v_ven_date_signed_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:vendorDateSigned' )) );
  l_v_ven_date_signed_tn := dbms_xmldom.appendchild( l_v_ven_date_signed_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_vendor_date_signed)) );

  -- Each Site node will get deduct from Invoice Flag
  l_v_deduct_from_inv_flag_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:deductFromInvoiceFlag' )) );
  l_v_deduct_from_inv_flag_tn := dbms_xmldom.appendchild( l_v_deduct_from_inv_flag_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_deduct_from_invoice_flag)) );

  -- Each Site node will get New Store Flag
  l_v_new_store_flag_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:newStoreFlag' )) );
  l_v_new_store_flag_textnode := dbms_xmldom.appendchild( l_v_new_store_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_new_store_flag)) );

  -- Each Site node will get New Store Terms
  l_v_new_store_terms_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:newStoreTerms' )) );
  l_v_new_store_terms_textnode := dbms_xmldom.appendchild( l_v_new_store_terms_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_new_store_terms)) );

  -- Each Site node will get Seasonal Flag
  l_v_seasonal_flag_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:seasonalFlag' )) );
  l_v_seasonal_flag_textnode := dbms_xmldom.appendchild( l_v_seasonal_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_seasonal_flag)) );

  -- Each Site node will get Start Date
  l_v_start_date_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:startDate' )) );
  l_v_start_date_textnode := dbms_xmldom.appendchild( l_v_start_date_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_start_date)) );

  -- Each Site node will get End Date
  l_v_end_date_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:endDate' )) );
  l_v_end_date_textnode := dbms_xmldom.appendchild( l_v_end_date_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_end_date)) );

  -- Each Site node will get Seasonal Terms
  l_v_seasonal_terms_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:seasonalTerms' )) );
  l_v_seasonal_terms_textnode := dbms_xmldom.appendchild( l_v_seasonal_terms_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_seasonal_terms)) );

  -- Each Site node will get Late Ship Flag
  l_v_late_ship_flag_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:lateShipFlag' )) );
  l_v_late_ship_flag_textnode := dbms_xmldom.appendchild( l_v_late_ship_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_late_ship_flag)) );
  l_edi_attributes_node       := dbms_xmldom.appendchild( l_cust_attributes_node--l_supplier_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:ediAttributes' )) );

  -- Each Site node will get EDI Distribution Code
  l_v_edi_distri_code_n := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:ediDistributionCode' )) );
  l_v_edi_distri_code_tn := dbms_xmldom.appendchild( l_v_edi_distri_code_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_edi_distribution_code)) );

  -- Each Site node will get 850 PO
  l_v_850_po_node := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:po850Flag' )) );
  l_v_850_po_textnode := dbms_xmldom.appendchild( l_v_850_po_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_850_po)) );

  -- Each Site node will get 846 Availability
  l_v_846_availability_node := dbms_xmldom.appendchild(l_edi_attributes_node-- l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:availability846Flag' )) );
  l_v_846_availability_textnode := dbms_xmldom.appendchild( l_v_846_availability_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_846_availability)) );

  -- Each Site node will get 810 Invoice
  l_v_810_invoice_node := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:invoice810Flag' )) );
  l_v_810_invoice_textnode := dbms_xmldom.appendchild( l_v_810_invoice_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_810_invoice)) );

  -- Each Site node will get 820 EFT
  l_v_820_eft_node := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:eft820' )) );
  l_v_820_eft_textnode := dbms_xmldom.appendchild( l_v_820_eft_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_820_eft)) );

  -- Each Site node will get 852 Sales
  l_v_852_sales_node := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:sales852' )) );
  l_v_852_sales_textnode := dbms_xmldom.appendchild( l_v_852_sales_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_852_sales)) );

  -- Each Site node will get 855 Confirm PO
  l_v_855_confirm_po_n := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:poConfirm855Flag' )) );
  l_v_855_confirm_po_tn := dbms_xmldom.appendchild( l_v_855_confirm_po_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_855_confirm_po)) );

  -- Each Site node will get 856 ASN
  l_v_856_asn_node := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:asn856Flag' )) );
  l_v_856_asn_textnode := dbms_xmldom.appendchild( l_v_856_asn_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_856_asn)) );

  -- Each Site node will get 860 PO Change
  l_v_860_po_change_n := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:poChange860Flag' )) );
  l_v_860_po_change_tn := dbms_xmldom.appendchild( l_v_860_po_change_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_860_po_change)) );

  -- Each Site node will get 861 Damage Shortage
  l_v_861_damage_shortage_n := dbms_xmldom.appendchild( l_edi_attributes_node--l_cust_attributes_node
  , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:damageShortage861Flag' )) );
  l_v_861_damage_shortage_tn := dbms_xmldom.appendchild( l_v_861_damage_shortage_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_861_damage_shortage)) );

  -- Each Site node will get 832 Price Sales Cat
  l_v_832_price_sales_cat_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:priceSalesCat832' )) );
  l_v_832_price_sales_cat_tn := dbms_xmldom.appendchild( l_v_832_price_sales_cat_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_832_price_sales_cat)) );

  -- Each Site node will get RTV Option
  l_v_rtv_option_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:rtvOption' )) );
  l_v_rtv_option_textnode := dbms_xmldom.appendchild( l_v_rtv_option_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_rtv_option)) );

  -- Each Site node will get RTV Freight Payment Method
  l_v_rtv_freight_pay_method_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:rtvFreightPaymentMethod' )) );
  l_v_rtv_freight_pay_method_tn := dbms_xmldom.appendchild( l_v_rtv_freight_pay_method_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_rtv_freight_payment_method)) );

  -- Each Site node will get Permanent RGA
  l_v_permanent_rga_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:permanentRga' )) );
  l_v_permanent_rga_textnode := dbms_xmldom.appendchild( l_v_permanent_rga_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_permanent_rga)) );

  -- Each Site node will get Destroy Allow amount
  l_v_destroy_allow_amt_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:destroyAllowAmount' )) );
  l_v_destroy_allow_amt_tn := dbms_xmldom.appendchild( l_v_destroy_allow_amt_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_destroy_allow_amount)) );

  -- Each Site node will get Payment Frequency
  l_v_payment_freq_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:paymentFrequency' )) );
  l_v_payment_freq_tn := dbms_xmldom.appendchild( l_v_payment_freq_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_payment_frequency)) );

  -- Each Site node will get Min Return Qty
  l_v_min_return_qty_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minimumReturnQuantity')) );
  l_v_min_return_qty_textnode := dbms_xmldom.appendchild( l_v_min_return_qty_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_min_return_qty)) );

  -- Each Site node will get Min Return Amt
  l_v_min_return_amount_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:minimumReturnAmount')) );
  l_v_min_return_amount_textnode := dbms_xmldom.appendchild( l_v_min_return_amount_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_min_return_amount)) );

  -- Each Site node will get Damage Destroy Limit
  l_v_damage_dest_limit_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:damageDestroyLimit')) );
  l_v_damage_dest_limit_tn := dbms_xmldom.appendchild( l_v_damage_dest_limit_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_damage_destroy_limit)) );

  -- Each Site node will get RTV Instructions
  l_v_rtv_instr_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:rtvInstructions')) );
  l_v_rtv_instr_tn := dbms_xmldom.appendchild( l_v_rtv_instr_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_rtv_instructions)) );

  -- Each Site node will get Addi.RTV Instructions
  l_v_addl_rtv_instr_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:additionalRtvInstructions')) );
  l_v_addl_rtv_instr_tn := dbms_xmldom.appendchild( l_v_addl_rtv_instr_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_addl_rtv_instructions)) );

  -- Each Site node will get RGA Marked Flag
  l_v_rga_marked_flag_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:rgaMarkedFlag')) );
  l_v_rga_marked_flag_tn := dbms_xmldom.appendchild( l_v_rga_marked_flag_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_rga_marked_flag)) );

  -- Each Site node will get Remove Price Sticker Flag
  l_v_rmv_price_sticker_flag_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:removePriceStickerFlag')) );
  l_v_rmv_price_sticker_flag_tn := dbms_xmldom.appendchild( l_v_rmv_price_sticker_flag_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_remove_price_sticker_flag)) );

  -- Each Site node will get Contact Supplier RGA Flag
  l_v_con_supp_rga_flag_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:contactSupplierRgaFlag')) );
  l_v_con_supp_rga_flag_tn := dbms_xmldom.appendchild( l_v_con_supp_rga_flag_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_contact_supplier_rga_flag)) );

  -- Each Site node will get Destroy Flag
  l_v_destroy_flag_node     := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:destroyFlag')) );
  l_v_destroy_flag_textnode := dbms_xmldom.appendchild( l_v_destroy_flag_node , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_destroy_flag)) );

  -- Each Site node will get Serial Num reqd. Flag
  l_v_ser_num_req_flag_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:serialNumRequiredFlag')) );
  l_v_ser_num_req_flag_tn := dbms_xmldom.appendchild( l_v_ser_num_req_flag_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_serial_num_required_flag)) );

  -- Each Site node will get Obsolete item
  l_v_obsolete_item_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:obsoleteItem')) );
  l_v_obsolete_item_tn := dbms_xmldom.appendchild( l_v_obsolete_item_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_obsolete_item)) );

  -- Each Site node will get Obsolete item
  l_v_obso_allow_pct_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:obsoleteAllowancePercent')) );
  l_v_obso_allow_pct_tn := dbms_xmldom.appendchild( l_v_obso_allow_pct_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_obsolete_allowance_pct)) );

  -- Each Site node will get Obsolete item
  l_v_obso_allow_days_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:obsoleteAllowanceDays')) );
  l_v_obso_allow_days_tn := dbms_xmldom.appendchild( l_v_obso_allow_days_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_obsolete_allowance_days)) );

  -- Each Site node will get OD contractor signature
  l_v_od_cont_sig_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odContSig')) );
  l_v_od_cont_sig_tn := dbms_xmldom.appendchild( l_v_od_cont_sig_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_od_cont_sig)) );

  -- Each Site node will get OD contractor title
  l_v_od_cont_title_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odContTitle')) );
  l_v_od_cont_title_tn := dbms_xmldom.appendchild( l_v_od_cont_title_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_od_cont_title)) );

  -- Each Site node will get OD vendor sig name
  l_v_od_ven_sig_name_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odVenSigName')) );
  l_v_od_ven_sig_name_tn := dbms_xmldom.appendchild( l_v_od_ven_sig_name_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_od_ven_sig_name)) );

  -- Each Site node will get OD vendor sig title
  l_v_od_ven_sig_title_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:odVenSigTitle')) );
  l_v_od_ven_sig_title_tn := dbms_xmldom.appendchild( l_v_od_ven_sig_title_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_od_ven_sig_title)) );

  -- Each Site node will get gss mfg id
  l_v_gss_mfg_id_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:gssMfgId')) );
  l_v_gss_mfg_id_tn := dbms_xmldom.appendchild( l_v_gss_mfg_id_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_gss_mfg_id)) );

  -- Each Site node will get gss buying agent id
  l_v_gss_buying_agent_id_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:gssBuyingAgentId')) );
  l_v_gss_buying_agent_id_tn := dbms_xmldom.appendchild( l_v_gss_buying_agent_id_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_gss_buying_agent_id)) );

  -- Each Site node will get gss_freight_id
  l_v_gss_freight_id_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:gssFreightId')) );
  l_v_gss_freight_id_tn := dbms_xmldom.appendchild( l_v_gss_freight_id_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_gss_freight_id)) );

  -- Each Site node will get gss_freight_id
  l_v_gss_ship_id_n  := dbms_xmldom.appendchild( l_cust_attributes_node , dbms_xmldom.makenode(dbms_xmldom.createelement(l_domdoc, 'sup:gssShipId')) );
  l_v_gss_ship_id_tn := dbms_xmldom.appendchild( l_v_gss_ship_id_n , dbms_xmldom.makenode(dbms_xmldom.createtextnode(l_domdoc,v_gss_ship_id)) );

  --KFF end
  l_xmltype := dbms_xmldom.getxmltype(l_domdoc);
  dbms_xmldom.freedocument(l_domdoc);
  xml_output:=l_xmltype.getclobval;

  p_request_id := fnd_global.conc_request_id;
  p_user_id    := fnd_global.user_id;
  p_user_name  := fnd_global.user_name;
  fnd_file.put_line(fnd_file.log, 'Request id is '||p_request_id );
  fnd_file.put_line(fnd_file.log, 'User id is '||p_user_id );
  fnd_file.put_line(fnd_file.log, 'User Name is '||p_user_name );
  xx_ap_sup_invoke_xml_out ( v_transaction_id=>v_transaction_id, v_globalvendor_id =>v_globalvendor_id , v_name =>v_name, v_vendor_site_id =>v_vendor_site_id, v_vendor_site_code =>v_vendor_site_code, v_site_orgid =>v_site_orgid , v_user_id =>p_user_id, v_user_name =>p_user_name, p_xml_payload => xml_output, v_request_id =>p_request_id, v_error_message => v_error_message, p_response_code => p_response_code );
END create_data_line;

/*Defect# 29479 Added for BUSS_CLASS_ATTR_FUNC for RMS type*/

FUNCTION buss_class_attr_func(
    p_vendor_site_id IN NUMBER)
  RETURN VARCHAR2 IS

  lv_attribute16 VARCHAR2(4000);
  lv_vend_id     NUMBER;
  lv_attr        VARCHAR2(10);
  lv_ext_attr_1  VARCHAR2(10);
  lv_separator   VARCHAR2(10) := ';';

  CURSOR c_buss_attr
  IS
    SELECT *
    FROM fnd_lookup_values_vl
    WHERE lookup_type      ='POS_BUSINESS_CLASSIFICATIONS'
    AND attribute_category = 'POS_BUSINESS_CLASSIFICATIONS'
    ORDER BY to_number(attribute1);

BEGIN
  SELECT vendor_id
  INTO lv_vend_id
  FROM ap_supplier_sites_all apss
  WHERE apss.vendor_site_id = p_vendor_site_id;

  FOR r_buss_attr IN c_buss_attr
  LOOP

    BEGIN
      SELECT 'Y',
        ext_attr_1
      INTO lv_attr,
        lv_ext_attr_1
      FROM pos_bus_class_attr pbca
      WHERE vendor_id                    = lv_vend_id
      AND lookup_code                    = r_buss_attr.lookup_code
      AND status                         = 'A'
      AND NVL(end_date_active,sysdate+1) > sysdate;

      IF r_buss_attr.lookup_code         = 'FOB' THEN
        lv_attribute16                  := lv_attribute16||lv_separator||lv_ext_attr_1;
      elsif r_buss_attr.lookup_code      = 'MINORITY_OWNED' THEN
        lv_attribute16                  := lv_attribute16||lv_separator||lv_ext_attr_1;

      ELSE
        lv_attribute16 := lv_attribute16||lv_separator||lv_attr;
      END IF;
    EXCEPTION
    WHEN OTHERS THEN
      lv_attribute16 := lv_attribute16||lv_separator||'N';
    END;

  END LOOP;
  RETURN lv_attribute16;
EXCEPTION
WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.log,'MAIN EXCEPTION :'||sqlerrm);
END buss_class_attr_func;

--=========
BEGIN

  v_extract_time := sysdate;

  -- Add code for File open
  dbms_output.put_line('Current Extract Time is:' || TO_CHAR(v_extract_time, 'DD-MON-YY HH24:Mi:SS'));
  ---+===============================================================================================
  ---|  Select the directory path for XXFIN_OUTBOUND directory
  ---+===============================================================================================

  fnd_file.put_line(fnd_file.log, '****************************************************************************');
  fnd_file.put_line(fnd_file.log, '          ');

  IF v_exit_flag = 'N' THEN

    OPEN mainsupplupdate_cur;

    -- Main Cursor to read all the data ;

    LOOP

      v_rms_flag := 'N';
      init_variables;
      init_kffvariables;
      FETCH mainsupplupdate_cur
      INTO v_vendor_site_id,
        v_attribute8,
        v_attribute13,
        v_vendor_site_code,
        v_vendor_site_code_alt, --NAIT-64664 Added by Sunil
        v_site_last_update,
        v_purchasing_site_flag,
        v_pay_site_flag,
        v_address_line1,
        v_address_line2,
        v_address_line3,
        v_city,
        v_state,
        v_zip,
        v_country,
        v_area_code,
        v_phone,
        v_inactive_date,
        v_pay_group_lookup_code,
        v_payment_method_lookup_code,
        v_payment_currency_code,
        v_primary_paysite_flag,
        v_site_freightterms,
        v_site_fob_lookup_code,--NAIT-64184--Added by Sunil
        v_po_site_vat_registration,
        v_site_language,
        v_bank_account_num,
        v_bank_account_name,
        v_duns_num,
        v_site_contact_id,
        v_site_contact_fname,
        v_site_contact_lname,
        v_site_contact_areacode,
        v_site_contact_phone,
        v_site_contact_email,
        v_site_contact_fareacode,
        v_site_contact_fphone,
        v_site_contact_last_update,
        v_name,
        v_vendor_id,      --NAIT-64721 Added by Sunil
        v_supplier_number,--Added for NAIT-56518
        v_vendor_last_update,
        v_po_vendor_vat_registration,
        v_terms_date_basis,
        v_vendor_type_lookup_code,
        v_parent_vendor_id,
        v_tax_reg_num,
        v_minority_cd,
        v_supp_attribute7,
        v_supp_attribute8,
        v_supp_attribute9,
        v_supp_attribute10,
        v_supp_attribute11,
        v_debit_memo_flag,
        v_province,
        v_site_terms,
        v_site_orgid,
        v_telex; -- V4.0, added
      -- use vendor_type_lookup_code = 'GARNISHMENT' to identify Garnishment suppliers
      EXIT WHEN NOT mainsupplupdate_cur % found;
      -- Identify the System
      -- GSS: Paysites for Expense Suppliers where the VENDOR_SITE_CODE starts with ?EX? and site category with 'EX'
      -- RMS: Trade Suppliers with site code starting with TR and Expense Suppliers VENDOR_SITE_CODE like ?EXP-IMP%?
      -- PSFT: Vendor_type_lookup_code = 'GARNISHMENT'

      g_vendor_site_id:=NULL;

      /*Defect# 29479 calling BUSS_CLASS_ATTR_FUNC for RMS type*/
      v_attribute16 := buss_class_attr_func(v_vendor_site_id);
      v_site_phone  := v_site_contact_areacode || v_site_contact_phone;
      v_site_phone  := SUBSTR(REPLACE(v_site_phone, '-', ''), 1, 11);
      v_site_fax    := v_site_contact_fareacode || v_site_contact_fphone;
      v_site_fax    := SUBSTR(REPLACE(v_site_fax, '-', ''), 1, 11);

      IF((v_country <> 'US') AND v_state IS NULL) THEN
        v_state     := v_province;
      END IF;

      -- All Expense vendors with Site Category of EX-IMP will be sent.

      IF((SUBSTR(v_attribute8, 1, 2) = 'TR')) -- Defect 6547             OR (SUBSTR (v_attribute8, 1, 6) = 'EX-IMP'))
        THEN
        v_rms_flag      := 'Y';
        g_vendor_site_id:=v_vendor_site_id;
      END IF;

      IF v_rms_flag = 'Y' THEN
        ---- NAIT-64721 Added by Sunil
        BEGIN
          IF (v_vendor_id IS NOT NULL AND v_site_orgid IS NOT NULL) THEN
            SELECT bk.bank_name
            INTO v_bank_name
            FROM ce_banks_v bk,
              ce_bank_branches_v bkb,
              iby_ext_bank_accounts bac,
              iby_account_owners iao,
              hz_parties hp,
              ap_suppliers ass ,
              ap_supplier_sites_all assa,
              hr_operating_units hou
            WHERE bk.bank_party_id      = bkb.bank_party_id
            AND bac.bank_id             = bk.bank_party_id
            AND bkb.branch_party_id     = bac.branch_id
            AND iao.ext_bank_account_id = bac.ext_bank_account_id
            AND ass.PARTY_ID            =iao.ACCOUNT_OWNER_PARTY_ID
            AND hp.party_id             = iao.account_owner_party_id
            AND ass.VENDOR_ID           =assa.VENDOR_ID
            AND hou.ORGANIZATION_ID     =assa.ORG_ID
            AND assa.org_id             = v_site_orgid
            AND ass.vendor_id           = v_vendor_id;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          v_bank_name :=NULL;
        END;

        -- Defect 7007 CR395
        BEGIN
          --------------------------------------------
          -- Per Defect 14433 added IF statement below
          --------------------------------------------
          IF v_site_orgid    = 404 THEN
            v_country       := 'US';
          elsif v_site_orgid = 403 THEN
            v_country       := 'CA';
          ELSE
            fnd_file.put_line(fnd_file.log, 'Invalid ORG_ID:  ' || v_site_orgid || ' Country code may not be derived correctly ' || 'from AP_RMS_TO_LEGACY_BANK translation table.');
          END IF;
          -- Version 1.1 -- Antonio Morales change for Bank Code
          IF v_attribute8 IN ('TR-CON','TR-OMXCON') THEN
            v_site_category := v_attribute8;
          ELSE
            v_site_category := 'OTHER';
          END IF;
          xx_fin_translate_pkg.xx_fin_translatevalue_proc ( p_translation_name => 'AP_RMS_TO_LEGACY_BANK' ,p_source_value1 => v_payment_method_lookup_code ,p_source_value2 => v_payment_currency_code ,p_source_value3 => v_country ,p_source_value4 => v_site_category -- Version 1.1 -- Antonio Morales change for Bank Code
          ,x_target_value1 => x_target_value1 ,x_target_value2 => x_target_value2 ,x_target_value3 => x_target_value3 , x_target_value4 => x_target_value4 ,x_target_value5 => x_target_value5 ,x_target_value6 => x_target_value6 , x_target_value7 => x_target_value7 ,x_target_value8 => x_target_value8 ,x_target_value9 => x_target_value9 , x_target_value10 => x_target_value10 ,x_target_value11 => x_target_value11 ,x_target_value12 => x_target_value12 , x_target_value13 => x_target_value13 ,x_target_value14 => x_target_value14 ,x_target_value15 => x_target_value15 ,x_target_value16 => x_target_value16 ,x_target_value17 => x_target_value17 ,x_target_value18 => x_target_value18 ,x_target_value19 => x_target_value19 ,x_target_value20 => x_target_value20 ,x_error_message => x_error_message );
          v_bank_account_num  := x_target_value1;
          v_bank_account_name := x_target_value1;
        EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Error retreiving Bank Code for Site ID:' || v_vendor_site_id || ' ' || v_payment_method_lookup_code || ' ' || v_payment_currency_code || v_country);
        END;

        -- end of Defect 7007 CR395
        -- Purchase Site with Paysite specified.
        --check attribute13 for Purchase sites to get the Pay site
        v_site_exists_flag := 'Y';
        IF((v_attribute13  IS NOT NULL) AND(v_purchasing_site_flag = 'Y') AND(v_pay_site_flag = 'N')) THEN
          -- Assign the Pay site value from Purchase Site DFF
          v_vendor_site_id     := to_number(v_attribute13);
          IF v_site_exists_flag = 'Y' THEN
            -- get the data from the Paysite other than Address and Contact information
            BEGIN
              SELECT *
              INTO v_inactive_date,
                v_pay_group_lookup_code,
                v_payment_method_lookup_code,
                v_payment_currency_code,
                v_primary_paysite_flag,
                v_site_freightterms,
                v_site_fob_lookup_code,--NAIT-64184--Added by Sunil
                v_po_site_vat_registration,
                v_site_language,
                v_duns_num,
                v_debit_memo_flag,
                v_province,
                v_site_terms,
                v_site_orgid
                FROM (
              SELECT  a.inactive_date,
                a.pay_group_lookup_code,
                NVL(ieppm.payment_method_code,'CHECK'),--Added for defect 33188
                a.payment_currency_code,
                a.primary_pay_site_flag,
                a.freight_terms_lookup_code,--NAIT-64184--Added by Sunil
                a.fob_lookup_code,          --NAIT-64184--Added by Sunil
                a.vat_registration_num,
                a.language,
                a.attribute5,--Added for NAIT-69405
                NVL(a.create_debit_memo_flag, 'N'),
                a.province,
                a.terms_id,
                a.org_id
              FROM ap_supplier_sites_all a,   -- V4.0 po_vendor_sites_all a
                iby_external_payees_all iepa, --V4.0
                iby_ext_party_pmt_mthds ieppm --V4.0
              WHERE a.vendor_site_id = v_vendor_site_id
                -- V4.0
              AND a.vendor_site_id       = iepa.supplier_site_id
              AND iepa.ext_payee_id      = ieppm.ext_pmt_party_id(+)
              AND( (ieppm.inactive_date IS NULL)
              OR (ieppm.inactive_date    > sysdate))
           ORDER BY NVL(ieppm.primary_flag,'Y') DESC)
           WHERE ROWNUM < 2;
            EXCEPTION
            WHEN OTHERS THEN
              fnd_file.put_line(fnd_file.log, 'Error retreiving Site data: for ' || v_vendor_site_id);
            END;
          END IF;
        END IF;
        v_site_lang := 1;
        -- for English from RMS table
        IF(v_inactive_date IS NOT NULL) THEN
          BEGIN
            v_inactive_date := TO_CHAR(to_date(v_inactive_date ,'DD-MON-YY'),'DD-MM-YYYY');
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error Inactive Date:' || v_inactive_date);
            v_inactive_date := TO_CHAR(to_date(TRUNC(sysdate) ,'DD-MON-YY'),'DD-MM-YYYY');
          END;
          --                           fnd_file.put_line (fnd_file.LOG, 'Inactive Date:'||v_inactive_date);
        END IF;
        -- logic for Address Flag;
        -- 0 ? for Return To Vendor address (address type 03),1 ? for address type 01
        -- 2 ? for address types 01, 04 ,   3 -  for address types 01, 05
        -- 4 - for address types 01, 04, 05
        --01 :  Company Address
        --01,04: Purchase Site Flag has been set
        --03: None of the flags have been set (Purchase or Pay) and Site Category = TR-RTV-ADDR
        --05: Pay Site Flag has been set
        --01,04,05: Both Purchase and Pay Site flags have been set.
        v_site_contact_name   := v_site_contact_fname || ' ' || v_site_contact_lname;
        IF v_site_contact_name = ' ' THEN
          v_site_contact_name := NULL;
        END IF;
        IF((v_purchasing_site_flag = 'N') AND(v_pay_site_flag = 'N')) THEN
          -- if RTV site is changed then don't send anything until the Paysite related to
          -- RTV is updated.
          v_rms_flag := 'Y'; -- V4.0 'N';
          -- RTV address (03: None of the flags have been set (Purchase or Pay))
          --V4.0, Commented out
          v_addr_flag             := 0;
          v_site_rtvaddr1         := v_address_line1;
          v_site_rtvaddr2         := v_address_line2;
          v_site_rtvaddr3         := v_address_line3;
          v_site_rtvcity          := v_city;
          v_site_rtvstate         := v_state;
          v_site_rtvzip           := v_zip;
          v_site_rtvcountry       := v_country;
          v_site_contact_rtvphone := v_site_phone;
          v_site_contact_rtvfax   := v_site_fax;
          v_site_contact_rtvemail := v_site_contact_email;
          v_site_contact_rtvname  := v_site_contact_name;
        END IF;
        IF((v_purchasing_site_flag = 'Y') AND(v_pay_site_flag = 'N')) THEN
          -- Purchasing address  (01,04: Purchase Site Flag has been set)
          v_addr_flag               := 2;
          v_site_purchaddr1         := v_address_line1;
          v_site_purchaddr2         := v_address_line2;
          v_site_purchaddr3         := v_address_line3;
          v_site_purchcity          := v_city;
          v_site_purchstate         := v_state;
          v_site_purchzip           := v_zip;
          v_site_purchcountry       := v_country;
          v_site_contact_purchphone := v_site_phone;
          v_site_contact_purchfax   := v_site_fax;
          v_site_contact_purchemail := v_site_contact_email;
          v_site_contact_purchname  := v_site_contact_name;
        END IF;
        IF((v_purchasing_site_flag = 'N') AND(v_pay_site_flag = 'Y')) THEN
          -- Pay Site Flag  (05: Pay Site Flag has been set)
          v_addr_flag             := 3;
          v_site_payaddr1         := v_address_line1;
          v_site_payaddr2         := v_address_line2;
          v_site_payaddr3         := v_address_line3;
          v_site_paycity          := v_city;
          v_site_paystate         := v_state;
          v_site_payzip           := v_zip;
          v_site_paycountry       := v_country;
          v_site_contact_payphone := v_site_phone;
          v_site_contact_payfax   := v_site_fax;
          v_site_contact_payemail := v_site_contact_email;
          v_site_contact_payname  := v_site_contact_name;
        END IF;
        IF((v_purchasing_site_flag = 'Y') AND(v_pay_site_flag = 'Y')) THEN
          -- Pay/Purchase address  (01,04,05: Both Purchase and Pay Site flags have been set.)
          v_addr_flag            := 4;
          v_site_ppaddr1         := v_address_line1;
          v_site_ppaddr2         := v_address_line2;
          v_site_ppaddr3         := v_address_line3;
          v_site_ppcity          := v_city;
          v_site_ppstate         := v_state;
          v_site_ppzip           := v_zip;
          v_site_ppcountry       := v_country;
          v_site_contact_ppphone := v_site_phone;
          v_site_contact_ppfax   := v_site_fax;
          v_site_contact_ppemail := v_site_contact_email;
          v_site_contact_ppname  := v_site_contact_name;
        END IF;
        -- Translate Vendor Site Payment Terms
        BEGIN
          IF v_site_terms IS NOT NULL THEN
            --                     fnd_file.put_line (fnd_file.LOG, 'Site Terms:' || v_site_terms || ' ' || v_terms_date_basis);
            BEGIN
              v_site_terms_name      := NULL;
              v_site_terms_name_desc := NULL;
              v_discount_percent     :=0;
              v_discount_days        :=0;
              v_due_days             :=0;
              ----New query added by Sunil for NAIT-64249
              SELECT aph.name ,
                aph.description ,
                NVL(apt.discount_percent,0) discount_percent ,
                NVL(apt.discount_days,0) discount_days ,
                NVL(apt.due_days,0) due_days
              INTO v_site_terms_name,
                v_site_terms_name_desc,
                v_discount_percent,
                v_discount_days,
                v_due_days
              FROM ap_terms_lines apt ,
                ap_terms_tl aph
              WHERE NVL(TRUNC(aph.end_date_active),sysdate+1) >= TRUNC(sysdate)
              AND aph.term_id                                  = apt.term_id
              AND aph.term_id                                  = v_site_terms
              AND aph.enabled_flag                             = 'Y';
            EXCEPTION
            WHEN OTHERS THEN
              v_site_terms_name      := NULL;
              v_site_terms_name_desc :=NULL;
              v_discount_percent     :=0;
              v_discount_days        :=0;
              v_due_days             :=0;
            END;
            v_site_terms_name_1 := v_site_terms_name;
            xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
            , sysdate, v_site_terms_name                                           --source_value1
            , v_terms_date_basis                                                   --'Invoice'  --source_value2
            , NULL                                                                 --source_value3
            , NULL                                                                 --source_value4
            , NULL                                                                 --source_value5
            , NULL                                                                 --source_value6
            , NULL                                                                 --source_value7
            , NULL                                                                 --source_value8
            , NULL                                                                 --source_value9
            , NULL                                                                 --source_value10
            ,x_target_value1, x_target_value2, x_target_value3, x_target_value4, x_target_value5, x_target_value6, x_target_value7, x_target_value8, x_target_value9, x_target_value10, x_target_value11, x_target_value12, x_target_value13, x_target_value14, x_target_value15, x_target_value16, x_target_value17, x_target_value18, x_target_value19, x_target_value20, x_error_message);
            v_site_terms_name := x_target_value1;

            BEGIN--Added by Sunil for terms_name_description from Translation table.
              IF v_site_terms_name IS NOT NULL AND v_terms_date_basis IS NOT NULL THEN
                BEGIN
                  SELECT source_value3
                  INTO v_site_terms_name_desc
                  FROM xx_fin_translatedefinition transdef,
                    xx_fin_translatevalues transval
                  WHERE transdef.translate_id  =transval.translate_id
                  AND transdef.translation_name='AP_PAYMENT_TERMS_RMS'
                  AND transval.source_value1   = v_site_terms_name_1
                  AND transval.source_value2   = v_terms_date_basis
                  AND transdef.enabled_flag    = 'Y'
                  AND sysdate BETWEEN transdef.start_date_active AND NVL(transdef.end_date_active,sysdate)
                  AND transval.enabled_flag = 'Y'
                  AND sysdate BETWEEN transval.start_date_active AND NVL(transval.end_date_active,sysdate);
                  --  fnd_file.put_line(fnd_file.log, 'v_site_terms_name_desc ' || v_site_terms_name_desc);
                EXCEPTION
                WHEN OTHERS THEN
                  fnd_file.put_line(fnd_file.log, 'Error deriving the RMS Payment Terms Name Description for ' || v_site_terms_name);
                  v_site_terms_name      := NULL;
                  v_site_terms_name_desc := NULL;
                END;
              ELSE
                v_site_terms_name      := NULL;
                v_site_terms_name_desc := NULL;
              END IF;
            END;
          END IF;
        EXCEPTION
        WHEN OTHERS THEN
          fnd_file.put_line(fnd_file.log, 'Error deriving the RMS Payment Terms for ' || v_site_terms || ' ' || x_error_message);
          v_site_terms_name      := NULL;
          v_site_terms_name_desc := NULL;
        END;

        BEGIN
          BEGIN
            SELECT k.lead_time,
              NVL(k.back_order_flag, 'N'),
              DECODE(k.delivery_policy, 'NEXT DAY', 'NEXT', 'NEXT VALID DELIVERY DAY', 'NDD'),
              --defect 2192
              k.min_prepaid_code,
              k.vendor_min_amount,
              k.supplier_ship_to,
              k.inventory_type_code,
              k.vertical_market_indicator,
              NVL(k.allow_auto_receipt, 'N'),
              k.handling,
              k.eft_settle_days,
              NVL(k.split_file_flag, 'N'),
              k.master_vendor_id,
              k.pi_pack_year,
              k.od_date_signed,
              k.vendor_date_signed,
              NVL(k.deduct_from_invoice_flag, 'N'),
              k.min_bus_category,
              NVL(k.new_store_flag, 'N'),
              k.new_store_terms,
              NVL(k.seasonal_flag, 'N'),
              k.start_date,
              k.end_date,
              k.seasonal_terms,
              NVL(k.late_ship_flag, 'N'),
              k.edi_distribution_code,
              k.od_contract_signature,
              k.od_contract_title,
              NVL(k.rtv_option, '1'),
              DECODE(k.rtv_freight_payment_method, 'COLLECT', 'CC', 'PREPAID', 'PP', 'NEITHER', 'NN'),
              --defect 2192
              k.permanent_rga,
              k.destroy_allow_amount,
              DECODE(k.payment_frequency, 'WEEKLY', 'W', 'DAILY', 'D', 'MONTHLY', 'M', 'QUARTERLY', 'Q', ''), -- Defect 6517
              k.min_return_qty,
              k.min_return_amount,
              k.damage_destroy_limit,
              k.rtv_instructions,
              k.addl_rtv_instructions,
              NVL(k.rga_marked_flag, 'N'),
              NVL(k.remove_price_sticker_flag, 'N'),
              NVL(k.contact_supplier_for_rga_flag, 'N'),
              NVL(k.destroy_flag, 'N'),
              DECODE(k.serial_num_required_flag, 'N', 'N', 'Y', 'Y', 'N'),
              -- if field edit not created in EBS
              k.obsolete_item,
              k.obsolete_allowance_pct,
              k.obsolete_allowance_days,
              NVL(k."850_PO", 'N'),
              NVL(k."860_PO_CHANGE", 'N'),
              NVL(k."855_CONFIRM_PO", 'N'),
              NVL(k."856_ASN", 'N'),
              NVL(k."846_AVAILABILITY", 'N'),
              NVL(k."810_INVOICE", 'N'),
              NVL(k."832_PRICE_SALES_CAT", 'N'),
              NVL(k."820_EFT", 'N'),
              NVL(k."861_DAMAGE_SHORTAGE", 'N'),
              DECODE(k."852_SALES", 'WEEKLY', 'W', 'DAILY', 'D', 'MONTHLY', 'M', 'W'),
              k.rtv_related_site,
              k.od_vendor_signature_name,
              k.od_vendor_signature_title,
              k.manufacturing_site_id,
              k.buying_agent_site_id,
              k.freight_forwarder_site_id,
              k.ship_from_port_id
            INTO v_lead_time,
              v_back_order_flag,
              v_delivery_policy,
              v_min_prepaid_code,
              v_vendor_min_amount,
              v_supplier_ship_to,
              v_inventory_type_code,
              v_vertical_market_indicator,
              v_allow_auto_receipt,
              v_handling,
              v_eft_settle_days,
              v_split_file_flag,
              v_master_vendor_id,
              v_pi_pack_year,
              v_od_date_signed,
              v_vendor_date_signed,
              v_deduct_from_invoice_flag,
              v_min_bus_category,
              v_new_store_flag,
              v_new_store_terms,
              v_seasonal_flag,
              v_start_date,
              v_end_date,
              v_seasonal_terms,
              v_late_ship_flag,
              v_edi_distribution_code,
              v_od_cont_sig,
              v_od_cont_title,
              v_rtv_option,
              v_rtv_freight_payment_method,
              v_permanent_rga,
              v_destroy_allow_amount,
              v_payment_frequency,
              v_min_return_qty,
              v_min_return_amount,
              v_damage_destroy_limit,
              v_rtv_instructions,
              v_addl_rtv_instructions,
              v_rga_marked_flag,
              v_remove_price_sticker_flag,
              v_contact_supplier_rga_flag,
              v_destroy_flag,
              v_serial_num_required_flag,
              v_obsolete_item,
              v_obsolete_allowance_pct,
              v_obsolete_allowance_days,
              v_850_po,
              v_860_po_change,
              v_855_confirm_po,
              v_856_asn,
              v_846_availability,
              v_810_invoice,
              v_832_price_sales_cat,
              v_820_eft,
              v_861_damage_shortage,
              v_852_sales,
              v_rtv_related_siteid,
              v_od_ven_sig_name,
              v_od_ven_sig_title,
              v_gss_mfg_id,
              v_gss_buying_agent_id,
              v_gss_freight_id,
              v_gss_ship_id
            FROM xx_po_vendor_sites_kff_v k--, xx_ap_sup_addl_attributes j
            WHERE k.vendor_site_id = v_vendor_site_id;
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error retreiving KFF Site data: for ' || v_vendor_site_id);
          END;

          -- Following is the default value for testing till we get Translation setup
          BEGIN
            IF v_delivery_policy IS NULL THEN
              v_delivery_policy  := 'NEXT';
            END IF;
            IF v_rtv_freight_payment_method IS NULL THEN
              v_rtv_freight_payment_method  := 'CC';
            END IF;
            IF v_new_store_terms IS NOT NULL THEN
              BEGIN
                v_terms_name := NULL;
                SELECT name
                INTO v_terms_name
                FROM ap_terms_tl
                WHERE term_id          = v_new_store_terms
                AND enabled_flag       = 'Y'
                AND(start_date_active <= sysdate
                AND(end_date_active   >= sysdate
                OR end_date_active    IS NULL));
              EXCEPTION
              WHEN OTHERS THEN
                v_terms_name := NULL;
              END;
              xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
              , sysdate, v_terms_name                                                --source_value1
              , v_terms_date_basis                                                   --source_value2
              , NULL                                                                 --source_value3
              , NULL                                                                 --source_value4
              , NULL                                                                 --source_value5
              , NULL                                                                 --source_value6
              , NULL                                                                 --source_value7
              , NULL                                                                 --source_value8
              , NULL                                                                 --source_value9
              , NULL                                                                 --source_value10
              , x_target_value1, x_target_value2, x_target_value3, x_target_value4, x_target_value5, x_target_value6, x_target_value7, x_target_value8, x_target_value9, x_target_value10, x_target_value11, x_target_value12, x_target_value13, x_target_value14, x_target_value15, x_target_value16, x_target_value17, x_target_value18, x_target_value19, x_target_value20, x_error_message);
              v_new_store_terms := x_target_value1;
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error deriving the RMS Payment Terms for ' || v_new_store_terms || ' ' || x_error_message);
          END;

          BEGIN
            IF v_seasonal_terms IS NOT NULL THEN
              BEGIN
                v_terms_name := NULL;
                SELECT name
                INTO v_terms_name
                FROM ap_terms_tl
                WHERE term_id          = v_seasonal_terms
                AND enabled_flag       = 'Y'
                AND(start_date_active <= sysdate
                AND(end_date_active   >= sysdate
                OR end_date_active    IS NULL));
              EXCEPTION
              WHEN OTHERS THEN
                v_terms_name := NULL;
              END;

              xx_fin_translate_pkg.xx_fin_translatevalue_proc('AP_PAYMENT_TERMS_RMS' --translation_name
              , sysdate, v_terms_name                                                --source_value1
              , v_terms_date_basis                                                   --source_value2
              , NULL                                                                 --source_value3
              , NULL                                                                 --source_value4
              , NULL                                                                 --source_value5
              , NULL                                                                 --source_value6
              , NULL                                                                 --source_value7
              , NULL                                                                 --source_value8
              , NULL                                                                 --source_value9
              , NULL                                                                 --source_value10
              , x_target_value1, x_target_value2, x_target_value3, x_target_value4, x_target_value5, x_target_value6, x_target_value7, x_target_value8, x_target_value9, x_target_value10, x_target_value11, x_target_value12, x_target_value13, x_target_value14, x_target_value15, x_target_value16, x_target_value17, x_target_value18, x_target_value19, x_target_value20, x_error_message);
              v_seasonal_terms := x_target_value1;
            END IF;
          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error deriving the RMS Payment Terms for (Seasonal Terms) ' || v_seasonal_terms || ' ' || x_error_message);
          END;

          IF(v_od_date_signed IS NOT NULL) THEN

            BEGIN
              --incorrect date format
              v_od_date_signed := TO_CHAR(to_date(v_od_date_signed ,'DD-MON-YY'),'DD-MM-YYYY');--Added by Sunil
            EXCEPTION
            WHEN OTHERS THEN
              v_od_date_signed := TO_CHAR(to_date(TRUNC(sysdate) ,'DD-MON-YY'),'DD-MM-YYYY');
            END;

          END IF;

          IF(v_vendor_date_signed IS NOT NULL) THEN

            BEGIN
              v_vendor_date_signed := TO_CHAR(to_date(v_vendor_date_signed ,'DD-MON-YY'),'DD-MM-YYYY');--Added by Sunil
            EXCEPTION
            WHEN OTHERS THEN
              v_vendor_date_signed := TO_CHAR(to_date(TRUNC(sysdate) ,'DD-MON-YY'),'DD-MM-YYYY');
            END;

          END IF;
  
        IF(v_start_date IS NOT NULL) THEN

            BEGIN
              v_start_date := TO_CHAR(to_date(v_start_date ,'DD-MON-YY'),'DD-MM-YYYY');--Added by Sunil
            EXCEPTION
            WHEN OTHERS THEN
              v_start_date := TO_CHAR(to_date(TRUNC(sysdate) ,'DD-MON-YY'),'DD-MM-YYYY');
            END;

          END IF;

          IF(v_end_date IS NOT NULL) THEN
            BEGIN
              v_end_date := TO_CHAR(to_date(v_end_date ,'DD-MON-YY'),'DD-MM-YYYY');--Added by Sunil
            EXCEPTION
            WHEN OTHERS THEN
              v_end_date := TO_CHAR(to_date(TRUNC(sysdate) ,'DD-MON-YY'),'DD-MM-YYYY');
            END;

          END IF;

        END;
-- APPARENTLY THIS IS NOT BEEN USED
-- Start
--        IF v_supp_attribute7 = 'Y' THEN
--          v_minority_class  := 'MBE';
--        END IF;
--        IF v_supp_attribute8 = 'Y' THEN
--          v_minority_class  := 'WBE';
--        END IF;
--        IF v_supp_attribute9 = 'Y' THEN
--          v_minority_class  := 'DVB';
--        END IF;
--        IF v_supp_attribute10 = 'Y' THEN
--          v_minority_class   := 'SBC';
--        END IF;
--        IF v_supp_attribute11 = 'Y' -- defect 2192
--          THEN
--          v_minority_class := 'BSD';
--        END IF;
-- End
        v_globalvendor_id := xx_po_global_vendor_pkg.f_get_outbound(v_vendor_site_id);--added by sunil
        create_data_line;                                                             --added by sunil
      END IF;

      IF(v_rms_flag = 'Y') THEN

        v_rms_count := v_rms_count + 1;

        IF((v_rtv_related_siteid IS NOT NULL) AND(v_pay_site_flag = 'Y')) THEN

          BEGIN
            SELECT a.vendor_site_code,
              a.address_line1,
              a.address_line2,
              a.address_line3,
              a.city,
              upper(a.state),
              a.zip,
              NVL(a.country, 'US'),
              b.first_name,
              b.last_name,
              b.area_code,
              b.phone,
              b.email_address,
              b.fax_area_code,
              b.fax,
              a.province
            INTO v_vendor_site_code,
              v_address_line1,
              v_address_line2,
              v_address_line3,
              v_city,
              v_state,
              v_zip,
              v_country,
              v_site_contact_fname,
              v_site_contact_lname,
              v_site_contact_areacode,
              v_site_contact_phone,
              v_site_contact_email,
              v_site_contact_fareacode,
              v_site_contact_fphone,
              v_province
            FROM ap_supplier_sites_all a, -- V4.0 po_vendor_sites_all a,
              po_vendor_contacts b
            WHERE a.vendor_site_id = to_number(v_rtv_related_siteid)
            AND a.vendor_site_id   = b.vendor_site_id(+)
            AND a.org_id          IN(xx_fin_country_defaults_pkg.f_org_id('CA'), xx_fin_country_defaults_pkg.f_org_id('US')) --= ou.organization_id
            ORDER BY a.vendor_site_id;

          EXCEPTION
          WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error retreiving RTV Site address data: for ' || to_number(v_rtv_related_siteid));
          END;

          v_site_contact_name       := NULL;
          v_site_contact_payphone   := NULL;
          v_site_contact_purchphone := NULL;
          v_site_contact_ppphone    := NULL;
          v_site_contact_rtvphone   := NULL;
          v_site_contact_payfax     := NULL;
          v_site_contact_purchfax   := NULL;
          v_site_contact_ppfax      := NULL;
          v_site_contact_rtvfax     := NULL;
          v_site_phone              := NULL;
          v_site_fax                := NULL;
          v_site_contact_payemail   := NULL;
          v_site_contact_purchemail := NULL;
          v_site_contact_ppemail    := NULL;
          v_site_contact_rtvemail   := NULL;
          v_site_contact_payname    := NULL;
          v_site_payaddr1           := NULL;
          v_site_payaddr2           := NULL;
          v_site_payaddr3           := NULL;
          v_site_paycity            := NULL;
          v_site_paystate           := NULL;
          v_site_payzip             := NULL;
          v_site_paycountry         := NULL;
          v_site_contact_rtvname    := NULL;
          v_site_rtvaddr1           := NULL;
          v_site_rtvaddr2           := NULL;
          v_site_rtvaddr3           := NULL;
          v_site_rtvcity            := NULL;
          v_site_rtvstate           := NULL;
          v_site_rtvzip             := NULL;
          v_site_rtvcountry         := NULL;
          v_site_contact_purchname  := NULL;
          v_site_purchaddr1         := NULL;
          v_site_purchaddr2         := NULL;
          v_site_purchaddr3         := NULL;
          v_site_purchcity          := NULL;
          v_site_purchstate         := NULL;
          v_site_purchzip           := NULL;
          v_site_purchcountry       := NULL;
          v_site_contact_ppname     := NULL;
          v_site_ppaddr1            := NULL;
          v_site_ppaddr2            := NULL;
          v_site_ppaddr3            := NULL;
          v_site_ppcity             := NULL;
          v_site_ppstate            := NULL;
          v_site_ppzip              := NULL;
          v_site_ppcountry          := NULL;
          v_site_phone              := v_site_contact_areacode || v_site_contact_phone;
          v_site_phone              := SUBSTR(REPLACE(v_site_phone, '-', ''), 1, 11);
          v_site_fax                := v_site_contact_fareacode || v_site_contact_fphone;
          v_site_fax                := SUBSTR(REPLACE(v_site_fax, '-', ''), 1, 11);
          v_site_contact_name       := v_site_contact_fname || ' ' || v_site_contact_lname;

          IF v_site_contact_name     = ' ' THEN
            v_site_contact_name     := NULL;
          END IF;
          IF((v_country <> 'US') AND v_state IS NULL) THEN
            v_state     := v_province;
          END IF;

          v_addr_flag             := 0;
          v_site_rtvaddr1         := v_address_line1;
          v_site_rtvaddr2         := v_address_line2;
          v_site_rtvaddr3         := v_address_line3;
          v_site_rtvcity          := v_city;
          v_site_rtvstate         := v_state;
          v_site_rtvzip           := v_zip;
          v_site_rtvcountry       := v_country;
          v_site_contact_rtvphone := v_site_phone;
          v_site_contact_rtvfax   := v_site_fax;
          v_site_contact_rtvemail := v_site_contact_email;
          v_site_contact_rtvname  := v_site_contact_name;
          create_data_line;
          v_rms_count := v_rms_count + 1;
        END IF;

        v_rms_flag := 'N';
      END IF;
    END LOOP;

    CLOSE mainsupplupdate_cur;
    -- Transfer the File to FTP directory
  ELSE
    dbms_output.put_line('Exit the Program, BPEL process is still running.');
    fnd_file.put_line(fnd_file.log, 'Exit the Program, BPEL process is still running.');
  END IF;
  fnd_file.put_line(fnd_file.log, '          ');
  fnd_file.put_line(fnd_file.log, '****************************************************************************');
  fnd_file.put_line(fnd_file.log, 'Number of Records: RMS=' || v_rms_count);
  fnd_file.put_line(fnd_file.log, '****************************************************************************');
  dbms_output.put_line('End of Program');
END;
END XX_AP_SUP_REAL_OUT_RMS_XML_PKG;
/

SHOW ERRORS;