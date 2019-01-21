SET VERIFY OFF
SET ECHO OFF
SET TAB OFF
SET FEEDBACK OFF
SET TERM ON

PROMPT Creating PACKAGE  BODY XX_AP_GSO_SUPPLIER_PKG

PROMPT Program exits IF the creation IS NOT SUCCESSFUL

WHENEVER SQLERROR CONTINUE
 
CREATE OR REPLACE PACKAGE BODY XX_AP_GSO_SUPPLIER_PKG
-- +=========================================================================+
-- |                  Office Depot - Project Simplify                        |
-- |                  Office Depot                                           |
-- +=========================================================================+
-- | Name             : XX_AP_GSO_SUPPLIER_PKG                        |
-- | Description      : This Program will do validations and load vendors to iface table from   |
-- |                    stagging table. And also does the post updates       |
-- |                                                                         |
-- |                                                                         |
-- |Change Record:                                                           |
-- |===============                                                          |
-- |Version    Date          Author            Remarks                       |
-- |=======    ==========    =============     ==============================|
-- |    1.0    25-APR-2016   Madhu Bolli       Initial code                  |
-- |    1.1    15-Aug-2016   Madhu Bolli       Removed apps schema           |
-- +=========================================================================+
AS
   /*********************************************************************
       * Procedure used to log based on gb_debug value or if p_force is TRUE.
       * Will log to dbms_output if request id is not set,
       * else will log to concurrent program log file.  Will prepend
       * timestamp to each message logged.  This is useful for determining
       * elapse times.
       *********************************************************************/
   PROCEDURE print_debug_msg (P_Message   IN VARCHAR2,
                              p_force     IN BOOLEAN DEFAULT FALSE)
   IS
      lc_message   VARCHAR2 (4000) := NULL;
   BEGIN
      IF (gc_debug = 'Y' OR p_force)
      THEN
         lc_Message := P_Message;
         Fnd_File.Put_Line (Fnd_File.LOG, lc_Message);

         IF (   fnd_global.conc_request_id = 0
             OR fnd_global.conc_request_id = -1)
         THEN
            DBMS_OUTPUT.put_line (lc_message);
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END print_debug_msg;

   /*********************************************************************
   * Procedure used to out the text to the concurrent program.
   * Will log to dbms_output if request id is not set,
   * else will log to concurrent program output file.
   *********************************************************************/
   PROCEDURE print_out_msg (P_Message IN VARCHAR2)
   IS
      lc_message   VARCHAR2 (4000) := NULL;
   BEGIN
      Lc_Message := P_Message;
      Fnd_File.Put_Line (Fnd_File.output, Lc_Message);

      IF (fnd_global.conc_request_id = 0 OR fnd_global.conc_request_id = -1)
      THEN
         DBMS_OUTPUT.put_line (lc_message);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   END print_out_msg;

   -- +============================================================================+
   -- | Procedure Name : insert_error                                              |
   -- |                                                                            |
   -- | Description    : This procedure inserts error into the staging tables      |
   -- |                                                                            |
   -- |                                                                            |
   -- | Parameters     : p_all_error_messages          OUT NOCOPY VARCHAR2            |
   -- |                  p_program_step             IN       VARCHAR2              |
   -- |                  p_primary_key              IN       VARCHAR2              |
   -- |                  p_error_code               IN       VARCHAR2              |
   -- |                  p_error_message            IN       VARCHAR2              |
   -- |                  p_stage_col1               IN       VARCHAR2              |
   -- |                  p_stage_val1               IN       VARCHAR2              |
   -- |                  p_stage_col2               IN       VARCHAR2              |
   -- |                  p_stage_val2               IN       VARCHAR2              |
   -- |                  p_stage_col3               IN       VARCHAR2              |
   -- |                  p_stage_val3               IN       VARCHAR2              |
   -- |                  p_stage_col4               IN       VARCHAR2              |
   -- |                  p_stage_val4               IN       VARCHAR2              |
   -- |                  p_stage_col5               IN       VARCHAR2              |
   -- |                  p_stage_val5               IN       VARCHAR2              |
   -- |                  p_table_name               IN       VARCHAR2              |
   -- |                                                                            |
   -- | Returns        : N/A                                                       |
   -- |                                                                            |
   -- +============================================================================+
   PROCEDURE insert_error (
      p_all_error_messages   IN   OUT NOCOPY VARCHAR2,
      p_program_step         IN            VARCHAR2 DEFAULT NULL,
      p_primary_key          IN            VARCHAR2 DEFAULT NULL,
      p_error_code           IN            VARCHAR2,
      p_error_message        IN            VARCHAR2 DEFAULT NULL,
      p_stage_col1           IN            VARCHAR2,
      p_stage_val1           IN            VARCHAR2,
      p_stage_col2           IN            VARCHAR2 DEFAULT NULL,
      p_stage_val2           IN            VARCHAR2 DEFAULT NULL,
      p_stage_col3           IN            VARCHAR2 DEFAULT NULL,
      p_stage_val3           IN            VARCHAR2 DEFAULT NULL,
      p_stage_col4           IN            VARCHAR2 DEFAULT NULL,
      p_stage_val4           IN            VARCHAR2 DEFAULT NULL,
      p_stage_col5           IN            VARCHAR2 DEFAULT NULL,
      p_stage_val5           IN            VARCHAR2 DEFAULT NULL,
      p_table_name           IN            VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      p_all_error_messages :=
            p_all_error_messages
         || ' '
         || p_stage_col1
         || ':'
         || p_stage_val1
         || ':'
         || p_error_code
         || ';';
   EXCEPTION
      WHEN OTHERS
      THEN
         print_debug_msg ('Error in insert_error: ' || SQLERRM);
   END insert_error;



-- |  Name: xx_gso_insert_stg                                                                   |
-- |  Description: This procedure is invoked by SOA to insert the data into staging table       |
-- |                                                                                            |
-- =============================================================================================|

PROCEDURE xx_gso_insert_stg
            (  p_status         OUT VARCHAR2
              ,p_ap_gsosup_t    IN  XX_AP_GSOSUP_INB_T
              ,p_ap_gsosup_err_t    OUT XX_AP_GSOSUP_ERR_T    
            )
IS

  lt_gso_ins_err_t xx_ap_gsosup_err_t;
  i NUMBER:=0;
  j NUMBER:=0;
  lc_error_msg VARCHAR2(250);
  lc_status VARCHAR2(1):='Y';

BEGIN
 
   FOR i in 1..p_ap_gsosup_t.COUNT LOOP 

     lc_error_msg:=NULL;

     BEGIN

       INSERT 
     INTO XX_AP_DI_SUPP_SITE_STG
         (
      GSO_REFERENCE_NO            
     ,SUPPLIER_NAME                       
     ,ADDRESS_LINE1                          
     ,ADDRESS_LINE2                          
     ,ADDRESS_LINE3                          
     ,ADDRESS_LINE4                          
     ,EMAIL_ADDRESS                
     ,TERMS_CODE                            
     ,PAY_GROUP                             
     ,PI_PACK_YEAR                          
     ,OD_DATE_SIGNED                        
     ,VENDOR_DATE_SIGNED                    
     ,RTV_OPTION                            
     ,RTV_FRT_PMT_METHOD                    
     ,RGA_MARKED_FLAG                       
     ,REMOVE_PRICE_STICKER_FLAG             
     ,CONTACT_SUPPLIER_FOR_RGA              
     ,DESTROY_FLAG                          
     ,PROCESS_FLAG                
     ,CREATION_DATE
     ,CREATED_BY                             
    )
    VALUES
    ( p_ap_gsosup_t(i).GSO_REFERENCE_NO            
     ,p_ap_gsosup_t(i).SUPPLIER_NAME                       
     ,p_ap_gsosup_t(i).ADDRESS_LINE1                          
     ,p_ap_gsosup_t(i).ADDRESS_LINE2                          
     ,p_ap_gsosup_t(i).ADDRESS_LINE3                          
     ,p_ap_gsosup_t(i).ADDRESS_LINE4                          
     ,p_ap_gsosup_t(i).EMAIL_ADDRESS                
     ,p_ap_gsosup_t(i).TERMS_CODE                            
     ,p_ap_gsosup_t(i).PAY_GROUP                             
     ,p_ap_gsosup_t(i).PI_PACK_YEAR                          
     ,p_ap_gsosup_t(i).OD_DATE_SIGNED                        
     ,p_ap_gsosup_t(i).VENDOR_DATE_SIGNED                    
     ,p_ap_gsosup_t(i).RTV_OPTION                            
     ,p_ap_gsosup_t(i).RTV_FRT_PMT_METHOD                    
     ,p_ap_gsosup_t(i).RGA_MARKED_FLAG                       
     ,p_ap_gsosup_t(i).REMOVE_PRICE_STICKER_FLAG             
     ,p_ap_gsosup_t(i).CONTACT_SUPPLIER_FOR_RGA              
     ,p_ap_gsosup_t(i).DESTROY_FLAG                          
     ,'N'                
     ,SYSDATE
     ,-1
     );
     EXCEPTION
       WHEN others THEN
    lc_error_msg:=SUBSTR(SQLERRM,1,250);
    lc_status:='N';
    j:=j+1;
    lt_gso_ins_err_t(j).supplier_name:=p_ap_gsosup_t(i).supplier_name;
    lt_gso_ins_err_t(j).gso_reference_no:=p_ap_gsosup_t(i).gso_reference_no;
    lt_gso_ins_err_t(j).supp_error_msg:=lc_error_msg;
     END;
   END LOOP;
   IF lc_status='Y' THEN
      COMMIT;
   ELSE
      ROLLBACK;
   END IF;
   p_ap_gsosup_err_t    :=lt_gso_ins_err_t;
   p_status             :=lc_status;
END xx_gso_insert_stg;


-- +============================================================================================+
-- |  Name: send_rpt_output                                                                     |
-- |  Description: This procedure will send the 'OD: AP GSO Supplier Site Add Report'           |
-- |               to the user                                                                  |
-- =============================================================================================|

PROCEDURE send_rpt_output(p_request_id IN  NUMBER)
IS

  i            NUMBER:=0;
  conn                UTL_SMTP.connection;
  v_file_name         VARCHAR2 (100);
  v_dfile_name        VARCHAR2 (100);
  v_efile_name        VARCHAR2 (100);
  v_request_id         NUMBER;
  vc_request_id       NUMBER;
  v_user_id        NUMBER:=fnd_global.user_id;
  v_phase        varchar2(100)   ;
  v_status        varchar2(100)   ;
  v_dphase        varchar2(100)    ;
  v_dstatus        varchar2(100)    ;
  x_dummy        varchar2(2000)     ;
  v_error        VARCHAR2(2000)    ;
  v_addlayout         boolean;
  x_cdummy            VARCHAR2 (2000);
  v_cdphase           VARCHAR2 (100);
  v_cdstatus          VARCHAR2 (100);  v_cphase            VARCHAR2 (100);
  v_cstatus           VARCHAR2 (100);
  lc_boolean            BOOLEAN;
  lc_boolean1           BOOLEAN;
  v_rpt_date        VARCHAR2(10):=TO_CHAR(SYSDATE,'RRRRMMDD');
  Type TYPE_TAB_EMAIL  IS TABLE OF XX_FIN_TRANSLATEVALUES.target_value1%TYPE INDEX BY BINARY_INTEGER ;
  EMAIL_TBL TYPE_TAB_EMAIL;
  lc_first_rec  varchar(1);
  lc_temp_email varchar2(2000);

BEGIN

     BEGIN
       ------------------------------------------
       -- Selecting emails from translation table
       ------------------------------------------
       SELECT TV.target_value3
             ,TV.target_value4
       INTO
              EMAIL_TBL(1)
             ,EMAIL_TBL(2)
       FROM   XX_FIN_TRANSLATEVALUES TV
             ,XX_FIN_TRANSLATEDEFINITION TD
       WHERE TV.TRANSLATE_ID  = TD.TRANSLATE_ID
       AND   TRANSLATION_NAME = 'EBS_NOTIFICATIONS'
       AND   source_value1    = 'GSO';
       ------------------------------------
       --Building string of email addresses
       ------------------------------------
       lc_first_rec  := 'Y';
       For ln_cnt in 1..2 Loop
            IF EMAIL_TBL(ln_cnt) IS NOT NULL THEN
                 IF lc_first_rec = 'Y' THEN
                     lc_temp_email := EMAIL_TBL(ln_cnt);
                     lc_first_rec := 'N';
                 ELSE
                     lc_temp_email :=  lc_temp_email ||' ; ' || EMAIL_TBL(ln_cnt);
                 END IF;
            END IF;
       End loop ;
    
       IF lc_temp_email IS NULL THEN

          lc_temp_email:='ebs_test_notifications@officedepot.com';  --- to be changed check

       END IF;
    
     EXCEPTION
       WHEN others then
         lc_temp_email:='ebs_test_notifications@officedepot.com';  --- to be changed check
     END;

     v_file_name := 'XXAPGSIR_' || TO_CHAR (p_request_id) || '_1.EXCEL';
     v_dfile_name :='$XXFIN_DATA/outbound/' || 'OD_GSO_SupplierSite_Add_Report_'||v_rpt_date||'_'||TO_CHAR (p_request_id)|| '.XLS';
     v_efile_name:='OD_GSO_SupplierSite_Add_Report_'||v_rpt_date||'_'||TO_CHAR (p_request_id)|| '.XLS';

        v_file_name   := '$APPLCSF/$APPLOUT/' || v_file_name;
        vc_request_id :=fnd_request.submit_request ('XXFIN',
                                           'XXCOMFILCOPY',
                                           'OD: Common File Copy',
                                           NULL,
                                           FALSE,
                                           v_file_name,
                                           v_dfile_name,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
                                           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
                                          );

        IF vc_request_id > 0  THEN
           COMMIT;
        END IF;

        IF (fnd_concurrent.wait_for_request (vc_request_id,
                                                 1,
                                                 60000,
                                                 v_cphase,
                                                 v_cstatus,
                                                 v_cdphase,
                                                 v_cdstatus,
                                                 x_cdummy
                                             )
             )  THEN
             IF v_cdphase = 'COMPLETE' THEN 

                conn :=xx_pa_pb_mail.begin_mail
                              (sender             => 'OracleEBS@officedepot.com',
                               recipients         => lc_temp_email,
                               cc_recipients      => NULL,
                               subject            => 'OD: AP GSO Supplier Site Add Report',
                               mime_type          => xx_pa_pb_mail.multipart_mime_type
                              );

            xx_pa_pb_mail.xx_email_excel(conn=>conn,
                                 p_directory=>'XXFIN_OUTBOUND',
                               p_filename=>v_efile_name);
                xx_pa_pb_mail.end_attachment (conn => conn);
                xx_pa_pb_mail.end_mail (conn => conn);
           END IF;

        END IF;   --------IF (fnd_concurrent.wait_for_request (vc_request_id,

    -- END IF;   --     IF v_dphase = 'COMPLETE' THEN
--   END IF;
  COMMIT;
EXCEPTION
   WHEN others THEN
    Fnd_File.Put_Line (Fnd_File.LOG, 'Error in Send Report Output : '||SQLERRM);
END send_rpt_output;


   --+============================================================================+
   --| Name          : purge_stage                                          |
   --| Description   : This procedure will delete all records from the staging table|
   --|                 XX_AP_DI_SUPP_SITE_STG                                        |
   --|                                                                            |
   --| Parameters    :                                                            |
   --|                                                                            |
   --| Returns       : N/A                                                        |
   --|                                                                            |
   --+============================================================================+
   PROCEDURE purge_stage (x_ret_code        OUT NUMBER,
                                 x_return_status   OUT VARCHAR2,
                                 x_err_buf         OUT VARCHAR2)
   IS
      l_ret_code        NUMBER;
      l_return_status   VARCHAR2 (100);
      l_err_buff        VARCHAR2 (4000);
   BEGIN
      print_debug_msg (p_message   => 'BEGIN procedure purge_stage()',
                       p_force     => FALSE);

      l_ret_code := 0;
      l_return_status := 'S';
      l_err_buff := NULL;

      --===========================================================================
      -- Delete the records from Supplier staging table 'XX_AP_DI_SUPP_SITE_STG'
      --===========================================================================
      BEGIN
         DELETE FROM XX_AP_DI_SUPP_SITE_STG
         WHERE creation_date <= SYSDATE - 90;

         IF SQL%NOTFOUND
         THEN
            print_debug_msg (
               p_message   => 'No records deleted from table XX_AP_DI_SUPP_SITE_STG.',
               p_force     => TRUE);
         ELSIF SQL%FOUND
         THEN
            print_debug_msg (
               p_message   =>    'No. of records deleted from table XX_AP_DI_SUPP_SITE_STG are '
                              || SQL%ROWCOUNT,
               p_force     => TRUE);
         END IF;
         
         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            l_ret_code := 1;
            l_return_status := 'E';
            l_err_buff :=
                  'Exception when deleting Supplier and its Site Staging records'
               || SQLCODE
               || ' - '
               || SUBSTR (SQLERRM, 1, 3500);

            RETURN;
      END;

      x_ret_code := l_ret_code;
      x_return_status := l_return_status;
      x_err_buf := l_err_buff;

      print_debug_msg (p_message   => 'END procedure purge_stage()',
                       p_force     => FALSE);
   END purge_stage;
      

   --+============================================================================+
   --| Name          : validate_records                                           |
   --| Description   : This procedure will Validate records in Staging tables     |
   --|                                                                            |
   --| Parameters    : x_val_records   OUT NUMBER                                 |
   --|                 x_inval_records OUT NUMBER                                 |
   --|                 x_return_status  OUT VARCHAR2                               |
   --|                                                                            |
   --| Returns       : N/A                                                        |
   --|                                                                            |
   --+============================================================================+
   PROCEDURE validate_records (x_val_records        OUT NOCOPY NUMBER,
                               x_inval_records      OUT NOCOPY NUMBER,
                               x_ret_code           OUT        NUMBER,
                               x_return_status      OUT        VARCHAR2,
                               x_err_buf            OUT        VARCHAR2)
   IS
      --==========================================================================================
      -- Variables Declaration used for getting the data into PL/SQL Table for Processing the API
      --==========================================================================================

      l_supplier_site_type         l_sup_site_tab;

      --=================================================================
      -- Cursor Declarations for Suppliers
      --=================================================================
      CURSOR c_supplier
      IS
           SELECT xas.*
             FROM XX_AP_DI_SUPP_SITE_STG xas
            WHERE     xas.SUPP_PROCESS_FLAG IN (gn_validation_inprocess)
                  AND xas.request_id = fnd_global.conc_request_id
         ORDER BY SUPPLIER_NAME;

      --==========================================================================================
      -- Cursor Declarations for duplicate check of Suppliers
      --==========================================================================================

      CURSOR c_dup_supplier_chk (
         c_supplier_name    VARCHAR2)
      IS
         SELECT asa.vendor_name, asa.vendor_id
           FROM AP_SUPPLIERS asa, hz_parties hp
          WHERE     asa.vendor_name = c_supplier_name
                AND hp.party_id = asa.party_id;

      --=================================================================
      -- Cursor Declarations for Duplicate check of Suppliers in Interface table
      --=================================================================
      CURSOR c_dup_supplier_chk_int (
         c_supplier_name    VARCHAR2)
      IS
         SELECT xasi.vendor_name
           FROM AP_SUPPLIERS_INT xasi
          WHERE     xasi.STATUS IN ('NEW')
                AND UPPER (vendor_name) = c_supplier_name;


      --==========================================================================================
      -- Cursor Declarations for Supplier Site existence
      --==========================================================================================

      CURSOR c_sup_site_exist (
         c_vendor_id           NUMBER,
         c_vendor_site_code    VARCHAR2,
         c_address_line1       VARCHAR2,
         c_address_line2       VARCHAR2,
         c_address_line3       VARCHAR2,
         c_address_line4       VARCHAR2)
      IS
         SELECT COUNT (1)
           FROM AP_SUPPLIER_SITES_ALL assa
          WHERE     assa.vendor_id = c_vendor_id
                AND vendor_site_code LIKE c_vendor_site_code
                AND ADDRESS_LINE1 = c_address_line1
                AND NVL (ADDRESS_LINE2, -1) = c_address_line2
                AND NVL (ADDRESS_LINE3, -1) = c_address_line3
                AND NVL (ADDRESS_LINE4, -1) = c_address_line4
                AND CITY = gc_city
                AND (STATE IS NULL OR STATE = gc_state)
                AND (COUNTRY IS NULL OR COUNTRY = gc_country_code)
                AND ATTRIBUTE8 = gc_site_category;

      --==============================================================================
      -- Cursor Declarations to get table statistics of Supplier Staging
      --==============================================================================
      CURSOR c_sup_stats
      IS
         SELECT SUM (
                   DECODE (supp_process_flag, gn_validation_inprocess, 1, 0)) -- Eligible to Validate and Load
                                                                             ,
                SUM (DECODE (supp_process_flag, gn_validation_success, 1, 0)) -- Successfully Validated
                                                                             ,
                SUM (
                   DECODE (supp_process_flag, gn_validation_load_error, 1, 0)) -- Validated and Errored out
                                                                              ,
                SUM (DECODE (supp_process_flag, gn_pending_status, 1, 0)) -- Ready for Process
           FROM (  SELECT supplier_name, supp_process_flag
                     FROM XX_AP_DI_SUPP_SITE_STG xadss
                    WHERE xadss.request_id = fnd_global.conc_request_id
                 GROUP BY xadss.supplier_name, xadss.supp_process_flag);

      --==============================================================================
      -- Cursor Declarations to get table statistics of Supplier Site Staging
      --==============================================================================
      CURSOR c_sup_site_stats
      IS
         SELECT SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG,
                           gn_validation_inprocess, 1,
                           0))                -- Eligible to Validate and Load
                              ,
                SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG,
                           gn_validation_success, 1,
                           0))            -- Successfully Validated and Loaded
                              ,
                SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG,
                           gn_validation_load_error, 1,
                           0))                    -- Validated and Errored out
                              ,
                SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG, gn_pending_status, 1, 0)) -- Ready for Process
           FROM XX_AP_DI_SUPP_SITE_STG
          WHERE request_id = fnd_global.conc_request_id;

      --==========================================================================================
      -- Declaring Local variables
      --==========================================================================================

      l_procedure                  VARCHAR2 (30) := 'VALIDATE_RECORDS';
      l_program_step               VARCHAR2 (100) := NULL;

      l_ret_code                   NUMBER;
      l_return_status              VARCHAR2 (100);
      l_err_buff                   VARCHAR2 (4000);

      l_trans_count                NUMBER := 0;
      l_site_upd_cnt               NUMBER := 0;
      l_inval_records              PLS_INTEGER := 0;
      l_val_records                PLS_INTEGER := 0;

      l_sup_idx                    PLS_INTEGER := 0;

      l_error_message              VARCHAR2 (4000) := NULL;

      lc_error_supp_status_flag    VARCHAR2 (1) := 'N';
      lc_error_site_status_flag    VARCHAR2 (1) := 'N';
      l_sup_name                   AP_SUPPLIERS.VENDOR_NAME%TYPE;
      l_vendor_exist_flag          VARCHAR2 (1) := 'N';
      l_vendor_id                  NUMBER;

      ln_request_id                NUMBER := fnd_global.conc_request_id;
      ln_user_id                   NUMBER := fnd_global.user_id;
      ln_login_id                  NUMBER := fnd_global.login_id;

      l_sup_type_code              AP_SUPPLIERS.vendor_type_lookup_code%TYPE;
      l_int_sup_name               AP_SUPPLIERS.VENDOR_NAME%TYPE;


      l_ap_application_id          NUMBER := 200;
      l_po_application_id          NUMBER := 201;


      lc_valid_value               VARCHAR2 (3) := NULL;
      lc_error_code                VARCHAR2 (100) := NULL;
      lc_loc_error_message         VARCHAR2 (4000) := NULL;
      lc_all_error_messages        VARCHAR2 (4000) := NULL;


      l_sup_site_exist_cnt         NUMBER;
      l_sup_site_create_flag       VARCHAR2 (1) := 'N';
      l_site_code                  VARCHAR2 (40);

      lb_is_valid_email            BOOLEAN;
      l_terms_id                   AP_TERMS.term_id%TYPE := NULL;
      l_pay_group_code             XX_AP_DI_SUPP_SITE_STG.pay_group_code%TYPE
                                      := NULL;
      l_rtv_option_val             XX_PO_VENDOR_SITES_KFF.segment40%TYPE;
      l_rtv_frt_pmt_method_val     XX_PO_VENDOR_SITES_KFF.segment41%TYPE;
      l_bill_to_location_id        NUMBER;
      l_liability_ccid             NUMBER;
      l_terms_date_basis_code      FND_LOOKUP_VALUES.LOOKUP_CODE%TYPE;
      l_pay_group                  VARCHAR2 (50);
      lb_is_valid_date             BOOLEAN;
      lc_flag                      VARCHAR2(1);

      l_upd_cnt                    NUMBER := 0;

      l_sup_eligible_cnt           NUMBER := 0;
      l_sup_val_load_cnt           NUMBER := 0;
      l_sup_error_cnt              NUMBER := 0;
      l_sup_val_not_load_cnt       NUMBER := 0;
      l_sup_ready_process          NUMBER := 0;
      l_supsite_eligible_cnt       NUMBER := 0;
      l_supsite_val_load_cnt       NUMBER := 0;
      l_supsite_error_cnt          NUMBER := 0;
      l_supsite_val_not_load_cnt   NUMBER := 0;
      l_supsite_ready_process      NUMBER := 0;
      
      
   BEGIN
      l_program_step := 'VALIDATION';
      print_debug_msg (
         p_message   => l_program_step || ': Assigning Defaults',
         p_force     => FALSE);

      --==========================================================================================
      -- Default Process Status Flag as N means No Error Exists
      --==========================================================================================
      lc_error_supp_status_flag := 'N';
      lc_error_site_status_flag := 'N';
      -- l_error_message            := NULL;
      -- gc_error_msg               := '';


      l_ret_code := 0;
      l_return_status := 'S';
      l_err_buff := NULL;


      --==============================================================
      -- Check and Update the staging table for the Supplier Number Null 
      --==============================================================
      BEGIN
         print_debug_msg (
            p_message   => 'Check and udpate the staging table for Supplier Number as NULL',
            p_force     => FALSE);

         l_upd_cnt := 0;

         UPDATE XX_AP_DI_SUPP_SITE_STG xassc1
            SET xassc1.SUPP_PROCESS_FLAG = gn_validation_load_error,
                xassc1.SUPP_ERROR_FLAG = gc_process_error_flag,
                xassc1.SUPP_ERROR_MSG =
                   'ERROR: Supplier Name is NULL',
                xassc1.SUPP_SITE_PROCESS_FLAG = gn_validation_load_error,
                xassc1.SUPP_SITE_ERROR_FLAG = gc_process_error_flag,
                xassc1.SUPP_SITE_ERROR_MSG =
                   'ERROR: Supplier Name is NULL',
                xassc1.PROCESS_FLAG = gn_validation_load_error
          WHERE xassc1.PROCESS_FLAG = 'I'
                AND xassc1.request_id = ln_request_id
                AND xassc1.SUPP_PROCESS_FLAG = gn_validation_inprocess
                AND xassc1.SUPP_SITE_PROCESS_FLAG = gn_validation_inprocess
                AND xassc1.SUPPLIER_NAME IS NULL;

         l_upd_cnt := SQL%ROWCOUNT;
         
         IF l_upd_cnt > 0 THEN
            COMMIT;
         END IF;
         
         print_debug_msg (
            p_message   =>    'Checked and updated '
                           || l_upd_cnt
                           || ' records as error in the staging table for Supplier Name as NULL',
            p_force     => TRUE);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_buff := SQLCODE || ' - ' || SUBSTR (SQLERRM, 1, 3500);
            print_debug_msg (
               p_message   =>    'ERROR EXCEPTION: Updating the Supplier Name as NULL in Staging table - '
                              || l_err_buff,
               p_force     => TRUE);

            x_ret_code := '1';
            x_return_status := 'E';
            x_err_buf := l_err_buff;
      END;  
      
      --==============================================================
      -- Check and Update the staging table for the Duplicate sites
      --==============================================================
      BEGIN
         print_debug_msg (
            p_message   => 'Check and udpate the staging table for the Duplicate Sites',
            p_force     => FALSE);

         l_site_upd_cnt := 0;

         UPDATE XX_AP_DI_SUPP_SITE_STG xassc1
            SET xassc1.SUPP_SITE_PROCESS_FLAG = gn_validation_load_error,
                xassc1.SUPP_SITE_ERROR_FLAG = gc_process_error_flag,
                xassc1.SUPP_SITE_ERROR_MSG =
                   xassc1.SUPP_SITE_ERROR_MSG||'; ERROR: Duplicate Supplier and Site in Staging Table'                
                /**xassc1.SUPP_PROCESS_FLAG = gn_validation_load_error,
                xassc1.SUPP_ERROR_FLAG = gc_process_error_flag,
                xassc1.SUPP_ERROR_MSG =
                   xassc1.SUPP_ERROR_MSG||';ERROR: Duplicate Supplier and Site in Staging Table',
                                   
                xassc1.PROCESS_FLAG = gn_validation_load_error **/
          WHERE     xassc1.PROCESS_FLAG = 'I'
                AND xassc1.request_id = ln_request_id
                AND xassc1.SUPP_PROCESS_FLAG = gn_validation_inprocess
                AND xassc1.SUPP_SITE_PROCESS_FLAG = gn_validation_inprocess
                AND 2 <=
                       (SELECT COUNT (1)
                          FROM XX_AP_DI_SUPP_SITE_STG xassc2
                         WHERE     xassc2.SUPP_SITE_PROCESS_FLAG =
                                      gn_validation_inprocess
                               AND xassc2.request_id = ln_request_id
                               AND TRIM (UPPER (xassc2.supplier_name)) =
                                      TRIM (UPPER (xassc1.supplier_name))
                               AND TRIM (UPPER (xassc2.ADDRESS_LINE1)) =
                                      TRIM (UPPER (xassc1.ADDRESS_LINE1))
                               AND TRIM (
                                      UPPER (NVL (xassc2.ADDRESS_LINE2, -1))) =
                                      TRIM (
                                         UPPER (
                                            NVL (xassc1.ADDRESS_LINE2, -1)))
                               AND TRIM (
                                      UPPER (NVL (xassc2.ADDRESS_LINE3, -1))) =
                                      TRIM (
                                         UPPER (
                                            NVL (xassc1.ADDRESS_LINE3, -1)))
                               AND TRIM (
                                      UPPER (NVL (xassc2.ADDRESS_LINE4, -1))) =
                                      TRIM (
                                         UPPER (
                                            NVL (xassc1.ADDRESS_LINE4, -1))));

         print_debug_msg (p_message => 'Update executed', p_force => TRUE);

         l_site_upd_cnt := SQL%ROWCOUNT;
         
         IF l_site_upd_cnt > 0 THEN
            COMMIT;
         END IF;
                  
         print_debug_msg (
            p_message   =>    'Checked and updated '
                           || l_site_upd_cnt
                           || ' records as error in the staging table for the Duplicate Sites',
            p_force     => FALSE);
      EXCEPTION
         WHEN OTHERS
         THEN
            l_err_buff := SQLCODE || ' - ' || SUBSTR (SQLERRM, 1, 3500);
            print_debug_msg (
               p_message   =>    'ERROR EXCEPTION: Updating the Duplicate Site in Staging table - '
                              || l_err_buff,
               p_force     => TRUE);

            x_ret_code := '1';
            x_return_status := 'E';
            x_err_buf := l_err_buff;

            RETURN;
      END;

      --==============================================================
      -- Variables initialize and derive default values
      --==============================================================
      --==============================================================================================================
      -- Validating the Supplier Site - Liability Account
      -- One time validation and retrieving account. So, retrieve the account value at first(here).
      --==============================================================================================================


      lc_valid_value := NULL;
      lc_error_code := NULL;
      lc_loc_error_message := NULL;
      l_liability_ccid := NULL;

      XX_AP_SUPPLIER_VAL_PKG.validate_and_get_account (
         p_concat_segments   => gc_liability_account,
         p_account_type      => 'L'                          --- for Liability
                                   ,
         p_cc_id             => l_liability_ccid,
         p_valid             => lc_valid_value,
         p_error_code        => lc_error_code,
         p_error_msg         => lc_loc_error_message);

      IF (lc_valid_value <> 'Y')
      THEN
         l_liability_ccid := -1;
         print_debug_msg (
            p_message   =>    l_program_step
                           || ' Error when deriving the Liability account cc Id of account -'
                           || gc_bill_to_loc_code
                           || ' - is '
                           || lc_loc_error_message,
            p_force     => TRUE);
      END IF;

      print_debug_msg (
         p_message   =>    l_program_step
                        || ' CCid of Liability account '
                        || gc_liability_account
                        || ' is '
                        || l_liability_ccid,
         p_force     => FALSE);

      --==============================================================================================================
      -- Validating the Supplier Site - Bill To Location Code
      -- One time validation and retrieving BillToLocationCode. So, retrieve the value at first(here).
      --==============================================================================================================

      lc_valid_value := NULL;
      lc_error_code := NULL;
      lc_loc_error_message := NULL;
      l_bill_to_location_id := NULL;

      XX_AP_SUPPLIER_VAL_PKG.validate_and_get_billtoloc (
         p_bill_to_loc_code   => gc_bill_to_loc_code,
         p_bill_to_loc_id     => l_bill_to_location_id,
         p_valid              => lc_valid_value,
         p_error_code         => lc_error_code,
         p_error_msg          => lc_loc_error_message);

      IF (lc_valid_value <> 'Y')
      THEN
         l_bill_to_location_id := -1;
         print_debug_msg (
            p_message   =>    l_program_step
                           || ' Error when deriving the Bill Location Id of code -'
                           || gc_bill_to_loc_code
                           || ' - is '
                           || lc_loc_error_message,
            p_force     => TRUE);
      END IF;

      print_debug_msg (
         p_message   =>    l_program_step
                        || ' Id of Bill To Location Code '
                        || gc_bill_to_loc_code
                        || ' is '
                        || l_bill_to_location_id,
         p_force     => FALSE);

      --==============================================================================================================
      -- Validating the Supplier Site - Terms Date Basis
      -- One time validation and retrieving TermDateBasis. So, retrieve the value at first(here).
      --==============================================================================================================

      lc_valid_value := NULL;
      lc_error_code := NULL;
      lc_loc_error_message := NULL;
      l_terms_date_basis_code := NULL;

      XX_AP_SUPPLIER_VAL_PKG.validate_lookup_meaning (
         p_lookup_type      => 'TERMS DATE BASIS',
         p_meaning          => gc_terms_date_basis,
         p_application_id   => l_ap_application_id,
         p_lookup_code      => l_terms_date_basis_code,
         p_valid            => lc_valid_value,
         p_error_code       => lc_error_code,
         p_error_msg        => lc_loc_error_message);

      IF (lc_valid_value <> 'Y')
      THEN
         l_terms_date_basis_code := -1;
         print_debug_msg (
            p_message   =>    l_program_step
                           || ' terms_date_basis code error is '
                           || lc_loc_error_message,
            p_force     => TRUE);
      END IF;

      print_debug_msg (
         p_message   =>    l_program_step
                        || ' terms_date_basis code of termsDateBasis '
                        || gc_terms_date_basis
                        || ' is '
                        || l_terms_date_basis_code,
         p_force     => FALSE);


      print_debug_msg (
         p_message   =>    l_program_step
                        || ' SUPPLLIER : Opening Supplier Cursor',
         p_force     => TRUE);

      --==============================================================
      -- Start validation for each supplier
      --==============================================================
      OPEN c_supplier;

      LOOP
         FETCH c_supplier BULK COLLECT INTO l_supplier_site_type;

         IF l_supplier_site_type.COUNT > 0
         THEN
            l_program_step := 'Supplier Validation';

            FOR l_sup_idx IN l_supplier_site_type.FIRST ..
                             l_supplier_site_type.LAST
            LOOP
               print_debug_msg (
                  p_message   =>    l_program_step
                                 || ': ------------ Validating Supplier('
                                 || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                 || ') -------------------------',
                  p_force     => TRUE);
               --==============================================================
               -- Initialize the Variable to N for Each Supplier
               --==============================================================
               lc_error_supp_status_flag := 'N';
               lc_valid_value := NULL;
               lc_error_code := NULL;
               lc_all_error_messages := NULL;

               l_vendor_exist_flag := 'N';
               l_sup_type_code := NULL;
               l_vendor_id := NULL;

               --==============================================================
               -- Validation for Each Supplier
               --==============================================================


               --==============================================================
               -- Validating the SUPPLIER NAME
               --==============================================================
           
               lc_loc_error_message := NULL;
               XX_AP_SUPPLIER_VAL_PKG.valid_supplier_name_format (
                  p_sup_name     => l_supplier_site_type (l_sup_idx).SUPPLIER_NAME,
                  p_valid        => lc_valid_value,
                  p_error_code   => lc_error_code,
                  p_error_msg    => lc_loc_error_message);

               IF lc_valid_value <> 'Y'
               THEN
                  lc_error_supp_status_flag := 'Y';

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : ERROR: '
                                    || lc_loc_error_message,
                     p_force     => TRUE);

                  insert_error (
                     p_all_error_messages   => lc_all_error_messages,
                     p_primary_key          => l_supplier_site_type (
                                                 l_sup_idx).SUPPLIER_NAME,
                     p_error_code           => lc_error_code--,p_error_message               => lc_loc_error_message
                     ,
                     p_stage_col1           => 'SUPPLIER_NAME',
                     p_stage_val1           => l_supplier_site_type (
                                                 l_sup_idx).SUPPLIER_NAME);
               END IF;

               --==================================================================================
               -- If duplicate vendor name exist in AP table, AP interface table and staging table
               --==================================================================================
               l_sup_name := NULL;

               OPEN c_dup_supplier_chk (TRIM (
                                           UPPER (
                                              l_supplier_site_type (
                                                 l_sup_idx).supplier_name)));

               FETCH c_dup_supplier_chk INTO l_sup_name, l_vendor_id;

               IF l_sup_name IS NULL       -- Supplier doesn't exist in System
               THEN
                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : Supplier Name '
                                    || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                    || ' in system does not exist. So, create it after checking interface table.',
                     p_force     => FALSE);

                  l_int_sup_name := NULL;

                  OPEN c_dup_supplier_chk_int (TRIM (
                                                  UPPER (
                                                     l_supplier_site_type (
                                                        l_sup_idx).supplier_name)));

                  FETCH c_dup_supplier_chk_int INTO l_int_sup_name;

                  CLOSE c_dup_supplier_chk_int;

                  IF l_int_sup_name IS NULL
                  THEN
                     l_supplier_site_type (l_sup_idx).create_flag := 'Y';
                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : Supplier Name '
                                       || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                       || ' in interface does not exist. So, create it.',
                        p_force     => FALSE);
                  ELSE
                     lc_error_supp_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: XXOD_SUP_EXISTS_IN_INT : Suppiler '
                                       || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                       || ' already exist in Interface table.',
                        p_force     => TRUE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_SUP_EXISTS_IN_INT',
                        p_error_message        =>    'Suppiler '
                                                  || l_supplier_site_type (
                                                        l_sup_idx).SUPPLIER_NAME
                                                  || ' already exist in Interface table .',
                        p_stage_col1           => 'SUPPLIER_NAME',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME);
                  END IF;
               ELSE -- if l_sup_name IS NOT NULL   (if supplier exist in the system)
                  l_vendor_exist_flag := 'Y';
                  l_supplier_site_type (l_sup_idx).create_flag := 'N';                     
                  l_supplier_site_type (l_sup_idx).vendor_id := l_vendor_id;
                  
                  l_supplier_site_type (l_sup_idx).SUPP_PROCESS_FLAG := gn_import_success;                         
                  l_supplier_site_type (l_sup_idx).SUPP_ERROR_MSG := l_supplier_site_type (l_sup_idx).SUPP_ERROR_MSG||'Existing SupplierName';
                                             

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : Supplier Name - '
                                    || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                    || ' exists in the system.',
                     p_force     => FALSE);
                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' l_vendor_id - '
                                    || l_vendor_id,
                     p_force     => FALSE);
               END IF;                                -- IF l_sup_name IS NULL

               CLOSE c_dup_supplier_chk;

               IF lc_error_supp_status_flag = 'Y'
               THEN
               

                      l_supplier_site_type (l_sup_idx).SUPP_PROCESS_FLAG :=
                         gn_validation_load_error;
                      l_supplier_site_type (l_sup_idx).SUPP_ERROR_FLAG :=
                         gc_process_error_flag;
                      l_supplier_site_type (l_sup_idx).SUPP_ERROR_MSG :=
                         lc_all_error_messages;                  

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : Validation of Supplier '
                                    || l_supplier_site_type (l_sup_idx).supplier_name
                                    || ' is failure'
                                    || lc_all_error_messages,
                     p_force     => TRUE);

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ': ------------ Data Validation Failed Supplier('
                                    || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                    || ') -------------------------',
                     p_force     => TRUE);
               ELSE
                  IF l_supplier_site_type (l_sup_idx).create_flag = 'Y' THEN               
                    l_supplier_site_type (l_sup_idx).SUPP_PROCESS_FLAG :=
                        gn_validation_success;                               -- 4
                  END IF;
                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ': ------------ Data Validation Success Supplier('
                                    || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                    || ') -------------------------',
                     p_force     => TRUE);
               END IF;

               --====================================================================
               -- Call the Vendor Site Validations
               --====================================================================
               /**set_step (   'Start of Vendor Site Loop Validations : '
                        || gc_error_status_flag); **/

               l_program_step := 'SITE VALIDATION';

               print_debug_msg (
                  p_message   =>    l_program_step
                                 || ' : Validation of Supplier Site started',
                  p_force     => TRUE);
               lc_error_site_status_flag := 'N';
               lc_all_error_messages := NULL;
               
               
               IF l_supplier_site_type (l_sup_idx).SUPP_SITE_PROCESS_FLAG <> gn_validation_inprocess THEN
                    print_debug_msg (
                     p_message   =>   'This site is already errored in status '||l_supplier_site_type (l_sup_idx).SUPP_SITE_PROCESS_FLAG,
                     p_force     => TRUE);
                     
                     CONTINUE;               
               END IF;
               

               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  Address Line 1
               --==============================================================================================================

               IF l_supplier_site_type (l_sup_idx).ADDRESS_LINE1 IS NULL
               THEN
                  lc_error_site_status_flag := 'Y';

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : ERROR: ADDRESS_LINE1:'
                                    || l_supplier_site_type (l_sup_idx).ADDRESS_LINE1
                                    || ': XXOD_SITE_ADDR_LINE1_NULL:Vendor Site Address Line 1 cannot be NULL',
                     p_force     => FALSE);
                  insert_error (
                     p_all_error_messages   => lc_all_error_messages,
                     p_primary_key          => l_supplier_site_type (
                                                 l_sup_idx).SUPPLIER_NAME,
                     p_error_code           => 'XXOD_SITE_ADDR_LINE1_NULL',
                     p_error_message        => 'Vendor Site Address Line 1 cannot be NULL',
                     p_stage_col1           => 'ADDRESS_LINE1',
                     p_stage_val1           => l_supplier_site_type (
                                                 l_sup_idx).ADDRESS_LINE1);
               ELSE
                  lc_valid_value := NULL;
                  lc_error_code := NULL;
                  lc_loc_error_message := NULL;

                  XX_AP_SUPPLIER_VAL_PKG.validate_address_line (
                     p_address_line   => l_supplier_site_type (l_sup_idx).ADDRESS_LINE1,
                     p_valid          => lc_valid_value,
                     p_error_code     => lc_error_code,
                     p_error_msg      => lc_loc_error_message);

                  IF lc_valid_value <> 'Y'
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: ADDRESS_LINE1:'
                                       || l_supplier_site_type (l_sup_idx).ADDRESS_LINE1
                                       || ': '
                                       || lc_loc_error_message,
                        p_force     => TRUE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE1,
                        p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'ADDRESS_LINE1',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE1);
                  END IF;
               END IF;

               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  Address Line 2
               --==============================================================================================================
               IF l_supplier_site_type (l_sup_idx).ADDRESS_LINE2 IS NULL
               THEN
                  lc_error_site_status_flag := 'Y';

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : ERROR: ADDRESS_LINE2:'
                                    || l_supplier_site_type (l_sup_idx).ADDRESS_LINE2
                                    || ': XXOD_SITE_ADDR_LINE2_NULL:Vendor Site Address Line 2 cannot be NULL',
                     p_force     => FALSE);
                  insert_error (
                     p_all_error_messages   => lc_all_error_messages,
                     p_primary_key          => l_supplier_site_type (
                                                 l_sup_idx).SUPPLIER_NAME,
                     p_error_code           => 'XXOD_SITE_ADDR_LINE2_NULL',
                     p_error_message        => 'Vendor Site Address Line 2 cannot be NULL',
                     p_stage_col1           => 'ADDRESS_LINE2',
                     p_stage_val1           => l_supplier_site_type (
                                                 l_sup_idx).ADDRESS_LINE2);
               ELSE
                  lc_valid_value := NULL;
                  lc_error_code := NULL;
                  lc_loc_error_message := NULL;


                  XX_AP_SUPPLIER_VAL_PKG.validate_address_line (
                     p_address_line   => l_supplier_site_type (l_sup_idx).ADDRESS_LINE2,
                     p_valid          => lc_valid_value,
                     p_error_code     => lc_error_code,
                     p_error_msg      => lc_loc_error_message);

                  IF lc_valid_value <> 'Y'
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: ADDRESS_LINE2:'
                                       || l_supplier_site_type (l_sup_idx).ADDRESS_LINE2
                                       || ': '
                                       || lc_loc_error_message,
                        p_force     => TRUE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE2,
                        p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'ADDRESS_LINE2',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE2);
                  END IF;
               END IF;

               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  Address Line 3
               --==============================================================================================================
               IF l_supplier_site_type (l_sup_idx).ADDRESS_LINE3 IS NULL
               THEN
                  lc_error_site_status_flag := 'Y';

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : ERROR: ADDRESS_LINE3:'
                                    || l_supplier_site_type (l_sup_idx).ADDRESS_LINE3
                                    || ': XXOD_SITE_ADDR_LINE3_NULL:Vendor Site Address Line 3 cannot be NULL',
                     p_force     => FALSE);
                  insert_error (
                     p_all_error_messages   => lc_all_error_messages,
                     p_primary_key          => l_supplier_site_type (
                                                 l_sup_idx).SUPPLIER_NAME,
                     p_error_code           => 'XXOD_SITE_ADDR_LINE3_NULL',
                     p_error_message        => 'Vendor Site Address Line 3 cannot be NULL',
                     p_stage_col1           => 'ADDRESS_LINE3',
                     p_stage_val1           => l_supplier_site_type (
                                                 l_sup_idx).ADDRESS_LINE3);
               ELSE
                  lc_valid_value := NULL;
                  lc_error_code := NULL;
                  lc_loc_error_message := NULL;


                  XX_AP_SUPPLIER_VAL_PKG.validate_address_line (
                     p_address_line   => l_supplier_site_type (l_sup_idx).ADDRESS_LINE3,
                     p_valid          => lc_valid_value,
                     p_error_code     => lc_error_code,
                     p_error_msg      => lc_loc_error_message);

                  IF lc_valid_value <> 'Y'
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: ADDRESS_LINE3:'
                                       || l_supplier_site_type (l_sup_idx).ADDRESS_LINE3
                                       || ': '
                                       || lc_loc_error_message,
                        p_force     => TRUE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE3,
                        p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'ADDRESS_LINE3',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE3);
                  END IF;
               END IF;

               --==============================================================================================================
               -- Validating the Supplier Site - Address Details -  Address Line 4
               --==============================================================================================================

               IF l_supplier_site_type (l_sup_idx).ADDRESS_LINE4 IS NULL
               THEN
                  lc_error_site_status_flag := 'Y';

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' : ERROR: ADDRESS_LINE4:'
                                    || l_supplier_site_type (l_sup_idx).ADDRESS_LINE4
                                    || ': XXOD_SITE_ADDR_LINE4_NULL:Vendor Site Address Line 4 cannot be NULL',
                     p_force     => FALSE);
                  insert_error (
                     p_all_error_messages   => lc_all_error_messages,
                     p_primary_key          => l_supplier_site_type (
                                                 l_sup_idx).SUPPLIER_NAME,
                     p_error_code           => 'XXOD_SITE_ADDR_LINE4_NULL',
                     p_error_message        => 'Vendor Site Address Line 4 cannot be NULL',
                     p_stage_col1           => 'ADDRESS_LINE4',
                     p_stage_val1           => l_supplier_site_type (
                                                 l_sup_idx).ADDRESS_LINE4);
               ELSE
                  lc_valid_value := NULL;
                  lc_error_code := NULL;
                  lc_loc_error_message := NULL;


                  XX_AP_SUPPLIER_VAL_PKG.validate_address_line (
                     p_address_line   => l_supplier_site_type (l_sup_idx).ADDRESS_LINE4,
                     p_valid          => lc_valid_value,
                     p_error_code     => lc_error_code,
                     p_error_msg      => lc_loc_error_message);

                  IF lc_valid_value <> 'Y'
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: ADDRESS_LINE4:'
                                       || l_supplier_site_type (l_sup_idx).ADDRESS_LINE4
                                       || ': '
                                       || lc_loc_error_message,
                        p_force     => TRUE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE4,
                        p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'ADDRESS_LINE4',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).ADDRESS_LINE4);
                  END IF;
               END IF;

               --==============================================================================================================
               -- Prepare the Site Code -  Prefix+%+Purpose
               -- Validate the existed Supplier Site - Supplier Name, Site Code, Address Line1+Address Line2+City+State/Province
               --==============================================================================================================
               print_debug_msg (
                  p_message   =>    l_program_step
                                 || ' After basic validation of site - lc_error_site_status_flag is '
                                 || lc_error_site_status_flag,
                  p_force     => FALSE);
               l_sup_site_create_flag := 'N';
               l_site_code := NULL;

               IF lc_error_site_status_flag = 'N'
               THEN
                  l_site_code := gn_address_name_prefix || '%';

                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' Prepared Site code - l_site_code - is '
                                    || l_site_code,
                     p_force     => FALSE);
                  print_debug_msg (
                     p_message   =>    l_program_step
                                    || ' l_vendor_exist_flag is '
                                    || l_vendor_exist_flag,
                     p_force     => FALSE);

                  IF l_vendor_exist_flag = 'Y'
                  THEN
                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' l_supplier_site_type (l_sup_idx).vendor_id is '
                                       || l_supplier_site_type (l_sup_idx).vendor_id,
                        p_force     => FALSE);
                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' upper(l_supplier_site_type(l_sup_idx).ADDRESS_LINE1) is '
                                       || UPPER (
                                             l_supplier_site_type (l_sup_idx).ADDRESS_LINE1),
                        p_force     => FALSE);
                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' upper(l_supplier_site_type(l_sup_idx).ADDRESS_LINE2) is '
                                       || UPPER (
                                             l_supplier_site_type (l_sup_idx).ADDRESS_LINE2),
                        p_force     => FALSE);
                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' upper(l_supplier_site_type(l_sup_idx).ADDRESS_LINE3) is '
                                       || UPPER (
                                             l_supplier_site_type (l_sup_idx).ADDRESS_LINE3),
                        p_force     => FALSE);
                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' upper(l_supplier_site_type(l_sup_idx).ADDRESS_LINE4) is '
                                       || UPPER (
                                             l_supplier_site_type (l_sup_idx).ADDRESS_LINE4),
                        p_force     => FALSE);

                     l_sup_site_exist_cnt := 0;

                     OPEN c_sup_site_exist (l_supplier_site_type (l_sup_idx).vendor_id,
                                            l_site_code,
                                            TRIM (
                                               UPPER (
                                                  l_supplier_site_type (
                                                     l_sup_idx).ADDRESS_LINE1)),
                                            TRIM (
                                               UPPER (
                                                  l_supplier_site_type (
                                                     l_sup_idx).ADDRESS_LINE2)),
                                            TRIM (
                                               UPPER (
                                                  l_supplier_site_type (
                                                     l_sup_idx).ADDRESS_LINE3)),
                                            TRIM (
                                               UPPER (
                                                  l_supplier_site_type (
                                                     l_sup_idx).ADDRESS_LINE4)));

                     FETCH c_sup_site_exist INTO l_sup_site_exist_cnt;

                     CLOSE c_sup_site_exist;

                     IF l_sup_site_exist_cnt > 0
                     THEN
                        lc_error_site_status_flag := 'Y';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' ERROR: XXOD_SUP_SITE_DUP : Supplier Site already existed in the system for the supplier '
                                          || l_supplier_site_type (l_sup_idx).SUPPLIER_NAME,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).SUPPLIER_NAME,
                           p_error_code           => 'XXOD_SUP_SITE_DUP'--,p_error_message            => 'Supplier Site already existed in the system for the supplier '||l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                           ,
                           p_stage_col1           => 'SUPPLIER_NAME',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).SUPPLIER_NAME);
                     ELSE
                        l_sup_site_create_flag := 'Y';
                     END IF;               -- IF l_sup_site_exist_cnt > 0 THEN
                  ELSE                    -- IF l_vendor_exist_flag = 'Y' THEN
                     l_sup_site_create_flag := 'Y';
                  END IF;                 -- IF l_vendor_exist_flag = 'Y' THEN
               END IF;             -- IF  lc_error_site_status_flag = 'N' THEN

               print_debug_msg (
                  p_message   =>    l_program_step
                                 || ' After supplier site existence check - lc_error_site_status_flag is '
                                 || lc_error_site_status_flag,
                  p_force     => FALSE);
               print_debug_msg (
                  p_message   =>    l_program_step
                                 || ' After supplier site existence check - l_sup_site_create_flag is '
                                 || l_sup_site_create_flag,
                  p_force     => FALSE);

               --===================================================================================
                -- Validating the Supplier Site -GSO Reference No
               --===================================================================================

               IF l_supplier_site_type (l_sup_idx).GSO_REFERENCE_NO IS NULL
               THEN

                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR:GSO_REFERENCE_NO:'
                                       || l_supplier_site_type (l_sup_idx).GSO_REFERENCE_NO
                                       || ': XXOD_SITE_GSO_REFERENCE_NO_NULL: Supplier Site GSO Reference No cannot be NULL',
                        p_force     => FALSE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_SITE_GSO_REFERENCE_NO_NULL',
                        p_error_message        => 'Supplier Site GSO Reference No cannot be NULL',
                        p_stage_col1           => 'GSO_REFERENCE_NO',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).GSO_REFERENCE_NO);                                     

               END IF;
                         
                  --===================================================================================
                  -- Validating the Supplier Site - Email Address
                  --===================================================================================

                  IF l_supplier_site_type (l_sup_idx).email_address IS NULL
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR:EMAIL_ADDRESS:'
                                       || l_supplier_site_type (l_sup_idx).EMAIL_ADDRESS
                                       || ': XXOD_SITE_EMAIL_ADDRESS_NULL: Supplier Site Email Address cannot be NULL',
                        p_force     => FALSE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_SITE_EMAIL_ADDRESS_NULL',
                        p_error_message        => 'Supplier Site Email Address cannot be NULL',
                        p_stage_col1           => 'EMAIL_ADDRESS',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).EMAIL_ADDRESS);
                  ELSE
                     lc_error_code := NULL;
                     lc_loc_error_message := NULL;

                     lb_is_valid_email :=
                        XX_AP_SUPPLIER_VAL_PKG.is_email_valid (
                           l_supplier_site_type (l_sup_idx).EMAIL_ADDRESS);

                     IF (NOT lb_is_valid_email)
                     THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_EMAIL_ADDRESS_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: EMAIL_ADDRESS:'
                                          || l_supplier_site_type (l_sup_idx).EMAIL_ADDRESS
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).EMAIL_ADDRESS,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'EMAIL_ADDRESS',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).EMAIL_ADDRESS);
                     END IF;
                  END IF; -- IF l_supplier_site_type(l_sup_idx).EMAIL_ADDRESS IS NULL


                  --===================================================================================
                  -- Validating the Supplier Site - Terms Code
                  --===================================================================================

                  IF l_supplier_site_type (l_sup_idx).TERMS_CODE IS NULL
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR:TERMS_CODE:'
                                       || l_supplier_site_type (l_sup_idx).TERMS_CODE
                                       || ': XXOD_SITE_TERMS_CODE_NULL: Supplier Site Terms Code cannot be NULL',
                        p_force     => FALSE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_SITE_TERMS_CODE_NULL',
                        p_error_message        => 'Supplier Site Terms Code cannot be NULL',
                        p_stage_col1           => 'TERMS_CODE',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).TERMS_CODE);
                  ELSE
                     l_terms_id := NULL;
                     lc_valid_value := NULL;
                     lc_error_code := NULL;
                     lc_loc_error_message := NULL;

                     XX_AP_SUPPLIER_VAL_PKG.get_term_id (
                        p_term_name   => l_supplier_site_type (l_sup_idx).TERMS_CODE,
                        p_term_id     => l_terms_id,
                        p_valid       => lc_valid_value,
                        p_error_msg   => lc_loc_error_message);

                     IF lc_valid_value <> 'Y'
                     THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_TERMS_CODE_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: TERMS_CODE:'
                                          || l_supplier_site_type (l_sup_idx).TERMS_CODE
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).TERMS_CODE,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'TERMS_CODE',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).TERMS_CODE);
                     END IF;
                  END IF; -- IF l_supplier_site_type(l_sup_idx).TERMS_CODE IS NULL


                  --===================================================================================
                  -- Validating the Supplier Site - Pay Group
                  --===================================================================================

                  l_pay_group := NULL;

                  IF l_supplier_site_type (l_sup_idx).PAY_GROUP IS NULL
                  THEN
                     l_pay_group := gc_pay_group;
                  ELSE
                     l_pay_group := l_supplier_site_type (l_sup_idx).PAY_GROUP;
                  END IF; -- IF l_supplier_site_type(l_sup_idx).PAY_GROUP IS NULL

                  l_pay_group_code := NULL;
                  lc_valid_value := NULL;
                  lc_error_code := NULL;
                  lc_loc_error_message := NULL;

                  XX_AP_SUPPLIER_VAL_PKG.validate_lookup_meaning (
                     p_lookup_type      => 'PAY GROUP',
                     p_meaning          => l_pay_group,
                     p_application_id   => l_po_application_id,
                     p_lookup_code      => l_pay_group_code,
                     p_valid            => lc_valid_value,
                     p_error_code       => lc_error_code,
                     p_error_msg        => lc_loc_error_message);

                  IF lc_valid_value <> 'Y'
                  THEN
                     lc_error_site_status_flag := 'Y';
                     lc_error_code := 'XXOD_PAY_GROUP_INVALID';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: TERMS_CODE:'
                                       || l_supplier_site_type (l_sup_idx).PAY_GROUP
                                       || ': '
                                       || lc_loc_error_message,
                        p_force     => FALSE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).PAY_GROUP,
                        p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'PAY_GROUP',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).PAY_GROUP);
                  END IF;


                  --=============================================================================
                  -- Validating the Supplier Site - Liability Account
                  --=============================================================================

                  IF l_liability_ccid = '-1'
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: Default Liabiilty Account Value :'
                                       || gc_liability_account
                                       || ' is Invalid.',
                        p_force     => TRUE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_DEFAULT_LIABILITY_ACCOUNT_INVALID'--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'DEFAULT_LIABILITY_ACCOUNT',
                        p_stage_val1           => gc_liability_account);
                  END IF;

                  --=============================================================================
                  -- Validating the Supplier Site - Bill to Location Code
                  --=============================================================================

                  IF l_bill_to_location_id = '-1'
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: Default Bill to Location Code Value :'
                                       || gc_bill_to_loc_code
                                       || ' is Invalid.',
                        p_force     => TRUE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_DEFAULT_BILL_TO_LOC_INVALID'--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'DEFAULT_BILL_TO_LOCATION',
                        p_stage_val1           => gc_bill_to_loc_code);
                  END IF;


                  --=============================================================================
                  -- Validating the Supplier Site - Terms Date Basis Code
                  --=============================================================================

                  IF l_terms_date_basis_code = '-1'
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR: Default Terms Date Basis Value :'
                                       || gc_terms_date_basis
                                       || ' is Invalid.',
                        p_force     => FALSE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_DEFAULT_TERMS_DATE_BASIS_INVALID'--,p_error_message             => lc_loc_error_message
                        ,
                        p_stage_col1           => 'DEFAULT_TERMS_DATE_BASIS',
                        p_stage_val1           => gc_terms_date_basis);
                  END IF;


                  --==============================================================================================================
                  -- Validating the Supplier Site - DFF - RTV Option
                  --==============================================================================================================
                   l_rtv_option_val := NULL;

                      IF l_supplier_site_type(l_sup_idx).RTV_OPTION IS NULL THEN
                          l_rtv_option_val := gc_rtv_option_default_val;
                          print_debug_msg(p_message=> l_program_step||' Defaulted the rtv_option to '||l_rtv_option_val
                                                ,p_force=> FALSE);
                      ELSE

                          lc_valid_value            := NULL;
                          lc_loc_error_message      := NULL;
                          l_rtv_option_val          := l_supplier_site_type(l_sup_idx).RTV_OPTION;


                          XX_AP_SUPPLIER_VAL_PKG.validate_valueset_value (p_value_set         => 'OD_AP_RTV_OPTIONS'
                                                          ,p_value            => l_supplier_site_type(l_sup_idx).RTV_OPTION
                                                          ,p_valid            => lc_valid_value
                                                          ,p_error_msg        => lc_loc_error_message
                                                          );

                          IF (lc_valid_value <> 'Y') THEN
                              lc_error_site_status_flag := 'Y';

                              print_debug_msg(p_message=> l_program_step||' : ERROR: RTV_OPTION:'||l_supplier_site_type(l_sup_idx).RTV_OPTION||': '||lc_loc_error_message
                                            ,p_force=> TRUE);

                              insert_error (p_all_error_messages        => lc_all_error_messages
                                          ,p_primary_key              => l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                          ,p_error_code               => lc_error_code
                                           --,p_error_message         => lc_loc_error_message
                                          ,p_stage_col1                 => 'RTV_OPTION'
                                          ,p_stage_val1                => l_supplier_site_type (l_sup_idx).RTV_OPTION
                                           );
                          END IF;      -- End of IF (lc_valid_value <> 'Y')

                       END IF;  -- IF l_supplier_site_type(l_sup_idx).RTV_OPTION IS NULL;
                       
                   /**   l_rtv_option_val := NULL;

                      IF l_supplier_site_type(l_sup_idx).RTV_OPTION IS NULL THEN
                          l_rtv_option_val := gc_rtv_option_default_val;
                          print_debug_msg(p_message=> l_program_step||' Defaulted the rtv_option to '||l_rtv_option_val
                                                ,p_force=> FALSE);
                      ELSE

                          lc_valid_value     := NULL;
                          lc_error_code              := NULL;
                          lc_loc_error_message     := NULL;
                          l_rtv_option_val         := NULL;


                          XX_AP_SUPPLIER_VAL_PKG.validate_valueset_description (p_value_set         => 'OD_AP_RTV_OPTIONS'
                                                          ,p_desc_value        => l_supplier_site_type(l_sup_idx).RTV_OPTION
                                                          ,p_flex_value          => l_rtv_option_val
                                                          ,p_valid            => lc_valid_value
                                                          ,p_error_code       => lc_error_code
                                                          ,p_error_msg        => lc_loc_error_message
                                                                           );

                          IF (lc_valid_value <> 'Y') THEN
                              lc_error_site_status_flag := 'Y';

                              print_debug_msg(p_message=> l_program_step||' : ERROR: RTV_OPTION:'||l_supplier_site_type(l_sup_idx).RTV_OPTION||': '||lc_loc_error_message
                                            ,p_force=> TRUE);

                              insert_error (p_all_error_messages        => lc_all_error_messages
                                          ,p_primary_key              => l_supplier_site_type (l_sup_idx).SUPPLIER_NAME
                                          ,p_error_code               => lc_error_code
                                           --,p_error_message         => lc_loc_error_message
                                          ,p_stage_col1                 => 'RTV_OPTION'
                                          ,p_stage_val1                => l_supplier_site_type (l_sup_idx).RTV_OPTION
                                           );
                          END IF;      -- End of IF (lc_valid_value <> 'Y')

                       END IF;  -- IF l_supplier_site_type(l_sup_idx).RTV_OPTION IS NULL

      **/
                  --==============================================================================================================
                  -- Validating the Supplier Site - DFF - RTV FREIGHT PAYMENT
                  --==============================================================================================================
                  l_rtv_frt_pmt_method_val := NULL;

                  IF l_supplier_site_type (l_sup_idx).RTV_FRT_PMT_METHOD
                        IS NULL
                  THEN
                     l_rtv_frt_pmt_method_val := gc_rtv_frt_pmt_default_val;
                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' Defaulted the rtv_frt_pmt_method to '
                                       || l_rtv_frt_pmt_method_val,
                        p_force     => FALSE);
                  ELSE
                     lc_valid_value := NULL;
                     lc_error_code := NULL;
                     lc_loc_error_message := NULL;
                     l_rtv_frt_pmt_method_val := NULL;


                     XX_AP_SUPPLIER_VAL_PKG.validate_valueset_description (
                        p_value_set    => 'OD_AP_RTV_FREIGHT_PAYMENT',
                        p_desc_value   => l_supplier_site_type (l_sup_idx).RTV_FRT_PMT_METHOD,
                        p_flex_value   => l_rtv_frt_pmt_method_val,
                        p_valid        => lc_valid_value,
                        p_error_code   => lc_error_code,
                        p_error_msg    => lc_loc_error_message);

                     IF (lc_valid_value <> 'Y')
                     THEN
                        lc_error_site_status_flag := 'Y';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: RTV_FRT_PMT_METHOD:'
                                          || l_supplier_site_type (l_sup_idx).RTV_FRT_PMT_METHOD
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).RTV_FRT_PMT_METHOD,
                           p_error_code           => lc_error_code--,p_error_message         => lc_loc_error_message
                           ,
                           p_stage_col1           => 'RTV_FRT_PMT_METHOD',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).RTV_FRT_PMT_METHOD);
                     END IF;              -- End of IF (lc_valid_value <> 'Y')
                  END IF; -- IF l_supplier_site_type(l_sup_idx).RTV_FRT_PMT_METHOD IS NULL


                  --==============================================================================================================
                  -- Validating the Supplier Site - DFF - OD_DATE_SIGNED
                  --==============================================================================================================
                           
                  IF l_supplier_site_type (l_sup_idx).OD_DATE_SIGNED IS NULL
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR:OD_DATE_SIGNED:'
                                       || l_supplier_site_type (l_sup_idx).OD_DATE_SIGNED
                                       || ': XXOD_SITE_VENDOR_DATE_SIGNED_NULL: Supplier Site OD Date Signed cannot be NULL',
                        p_force     => FALSE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_SITE_OD_DATE_SIGNED_NULL',
                        p_error_message        => 'Supplier Site OD Date Signed cannot be NULL',
                        p_stage_col1           => 'OD_DATE_SIGNED',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).OD_DATE_SIGNED);
                  ELSE
                           
                     lc_error_code := NULL;
                     lc_loc_error_message := NULL;

                     lb_is_valid_date :=
                        XX_AP_SUPPLIER_VAL_PKG.isValidDateFormat (
                           l_supplier_site_type (l_sup_idx).OD_DATE_SIGNED, 'DD-MON-YY');

                     IF (NOT lb_is_valid_date)                     
                     THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_OD_DATE_SIGNED_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: OD_DATE_SIGNED:'
                                          || l_supplier_site_type (l_sup_idx).OD_DATE_SIGNED
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).OD_DATE_SIGNED,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'OD_DATE_SIGNED',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).OD_DATE_SIGNED);
                     END IF;
                  END IF; -- IF l_supplier_site_type(l_sup_idx).TERMS_CODE IS NULL



                  --==============================================================================================================
                  -- Validating the Supplier Site - DFF - VENDOR_DATE_SIGNED
                  --==============================================================================================================
                  
                  IF l_supplier_site_type (l_sup_idx).VENDOR_DATE_SIGNED IS NULL
                  THEN
                     lc_error_site_status_flag := 'Y';

                     print_debug_msg (
                        p_message   =>    l_program_step
                                       || ' : ERROR:VENDOR_DATE_SIGNED:'
                                       || l_supplier_site_type (l_sup_idx).OD_DATE_SIGNED
                                       || ': XXOD_SITE_VENDOR_DATE_SIGNED_NULL: Supplier Site VendorDateSigned cannot be NULL',
                        p_force     => FALSE);

                     insert_error (
                        p_all_error_messages   => lc_all_error_messages,
                        p_primary_key          => l_supplier_site_type (
                                                    l_sup_idx).SUPPLIER_NAME,
                        p_error_code           => 'XXOD_SITE_VENDOR_DATE_SIGNED_NULL',
                        p_error_message        => 'Supplier Site VendorDateSigned cannot be NULL',
                        p_stage_col1           => 'VENDOR_DATE_SIGNED',
                        p_stage_val1           => l_supplier_site_type (
                                                    l_sup_idx).VENDOR_DATE_SIGNED);
                  ELSE

                     lc_error_code := NULL;
                     lc_loc_error_message := NULL;

                     lb_is_valid_date :=
                        XX_AP_SUPPLIER_VAL_PKG.isValidDateFormat (
                           l_supplier_site_type (l_sup_idx).VENDOR_DATE_SIGNED, 'DD-MON-YY');

                     IF (NOT lb_is_valid_date)                     
                     THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_VENDOR_DATE_SIGNED_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: VENDOR_DATE_SIGNED:'
                                          || l_supplier_site_type (l_sup_idx).VENDOR_DATE_SIGNED
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).VENDOR_DATE_SIGNED,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'VENDOR_DATE_SIGNED',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).VENDOR_DATE_SIGNED);
                     ELSE
                     
                        l_supplier_site_type (l_sup_idx).PI_PACK_YEAR  := EXTRACT(YEAR FROM TO_DATE(l_supplier_site_type (l_sup_idx).VENDOR_DATE_SIGNED, 'DD-MON-RR'));
                     END IF;
                  END IF; -- IF l_supplier_site_type(l_sup_idx).TERMS_CODE IS NULL


                  lc_flag := l_supplier_site_type (l_sup_idx).RGA_MARKED_FLAG;
                  IF lc_flag IS NULL
                  THEN
                     l_supplier_site_type (l_sup_idx).RGA_MARKED_FLAG :=
                        gc_rga_marked_flag;
                  ELSIF lc_flag NOT IN ('Y', 'N') THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_RGA_MARKED_FLAG_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: RGA_MARKED_FLAG:'
                                          || l_supplier_site_type (l_sup_idx).RGA_MARKED_FLAG
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).RGA_MARKED_FLAG,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'RGA_MARKED_FLAG',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).RGA_MARKED_FLAG);                    
                  END IF;

                  lc_flag := l_supplier_site_type (l_sup_idx).REMOVE_PRICE_STICKER_FLAG;
                  IF lc_flag IS NULL
                  THEN
                     l_supplier_site_type (l_sup_idx).REMOVE_PRICE_STICKER_FLAG :=
                        gc_remove_price_sticker_flag;
                        
                  ELSIF lc_flag NOT IN ('Y', 'N') THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_REMOVE_PRICE_STICKER_FLAG_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: REMOVE_PRICE_STICKER_FLAG:'
                                          || l_supplier_site_type (l_sup_idx).REMOVE_PRICE_STICKER_FLAG
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).REMOVE_PRICE_STICKER_FLAG,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'REMOVE_PRICE_STICKER_FLAG',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).REMOVE_PRICE_STICKER_FLAG);                            
                  END IF;

                
                  lc_flag := l_supplier_site_type (l_sup_idx).CONTACT_SUPPLIER_FOR_RGA;
                  IF lc_flag IS NULL
                  THEN
                     l_supplier_site_type (l_sup_idx).CONTACT_SUPPLIER_FOR_RGA :=
                        gc_contact_supplier_for_rga;
                  ELSIF lc_flag NOT IN ('Y', 'N') THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_CONTACT_SUPPLIER_FOR_RGA_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: CONTACT_SUPPLIER_FOR_RGA:'
                                          || l_supplier_site_type (l_sup_idx).CONTACT_SUPPLIER_FOR_RGA
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).CONTACT_SUPPLIER_FOR_RGA,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'CONTACT_SUPPLIER_FOR_RGA',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).CONTACT_SUPPLIER_FOR_RGA);                            
                  END IF;

                  
                  lc_flag := l_supplier_site_type (l_sup_idx).DESTROY_FLAG;
                  IF lc_flag IS NULL
                  THEN
                     l_supplier_site_type (l_sup_idx).DESTROY_FLAG :=
                        gc_destroy_flag;
                  ELSIF lc_flag NOT IN ('Y', 'N') THEN
                        lc_error_site_status_flag := 'Y';
                        lc_error_code := 'XXOD_DESTROY_FLAG_INVALID';

                        print_debug_msg (
                           p_message   =>    l_program_step
                                          || ' : ERROR: DESTROY_FLAG:'
                                          || l_supplier_site_type (l_sup_idx).DESTROY_FLAG
                                          || ': '
                                          || lc_loc_error_message,
                           p_force     => TRUE);

                        insert_error (
                           p_all_error_messages   => lc_all_error_messages,
                           p_primary_key          => l_supplier_site_type (
                                                       l_sup_idx).DESTROY_FLAG,
                           p_error_code           => lc_error_code--,p_error_message             => lc_loc_error_message
                           ,
                           p_stage_col1           => 'DESTROY_FLAG',
                           p_stage_val1           => l_supplier_site_type (
                                                       l_sup_idx).DESTROY_FLAG);                            
                  END IF;

                  --====================================================================
                  --Assigning the Values to Supplier Site PL/SQL Table for Bulk Update
                  --====================================================================
                  l_supplier_site_type (l_sup_idx).CCID := l_liability_ccid;
                  l_supplier_site_type (l_sup_idx).BILL_TO_LOC_ID :=
                     l_bill_to_location_id;
                  l_supplier_site_type (l_sup_idx).terms_date_basis_code :=
                     l_terms_date_basis_code;
                  l_supplier_site_type (l_sup_idx).terms_id := l_terms_id;
                  l_supplier_site_type (l_sup_idx).PAY_GROUP_CODE :=
                     l_pay_group_code;
                  l_supplier_site_type (l_sup_idx).RTV_OPTION_DR :=
                     l_rtv_option_val;
                  l_supplier_site_type (l_sup_idx).RTV_FRT_PMT_METHOD_DR :=
                     l_rtv_frt_pmt_method_val;
           --    END IF; -- IF  lc_error_site_status_flag = 'N' -- After Supplier Site Existence Check Completed

               IF lc_error_site_status_flag = 'Y'
               THEN
                  l_supplier_site_type (l_sup_idx).SUPP_SITE_PROCESS_FLAG :=
                     gn_validation_load_error;
                  l_supplier_site_type (l_sup_idx).SUPP_SITE_ERROR_FLAG :=
                     gc_process_error_flag;
                  l_supplier_site_type (l_sup_idx).SUPP_SITE_ERROR_MSG :=
                     lc_all_error_messages;
               -- l_sup_site_fail := 'Y';
               ELSE
                  l_supplier_site_type (l_sup_idx).SUPP_SITE_PROCESS_FLAG :=
                     gn_validation_success;
               END IF;

               --====================================================================
               -- Doing Status Update for Staging Tables
               --====================================================================

               -- If Supplier is failed then fail all the Sites
               IF lc_error_supp_status_flag = 'Y'
               THEN
                  l_supplier_site_type (l_sup_idx).SUPP_SITE_PROCESS_FLAG :=
                     gn_validation_load_error;
                  l_supplier_site_type (l_sup_idx).SUPP_SITE_ERROR_FLAG :=
                     gc_process_error_flag;
                  l_supplier_site_type (l_sup_idx).SUPP_SITE_ERROR_MSG :=
                        l_supplier_site_type (l_sup_idx).SUPP_SITE_ERROR_MSG
                     || ':'
                     || 'Supplier is failed for this site.';
               END IF;                  --  IF lc_error_supp_status_flag = 'Y'
            END LOOP; -- For (l_supplier_site_type.FIRST .. l_supplier_site_type.LAST)
         END IF;                             -- l_supplier_site_type.COUNT > 0


         --============================================================================
         -- For Doing the Bulk Update
         --============================================================================
         l_program_step := NULL;
         print_debug_msg (
            p_message   =>    l_program_step
                           || ': Do Bulk Update for all Site Records ',
            p_force     => TRUE);

         IF l_supplier_site_type.COUNT > 0
         THEN
            BEGIN
               FORALL l_idxs
                   IN l_supplier_site_type.FIRST .. l_supplier_site_type.LAST
                  UPDATE XX_AP_DI_SUPP_SITE_STG
                     SET SUPP_PROCESS_FLAG =
                            l_supplier_site_type (l_idxs).SUPP_PROCESS_FLAG,
                         SUPP_ERROR_FLAG =
                            l_supplier_site_type (l_idxs).SUPP_ERROR_FLAG,
                         SUPP_ERROR_MSG =
                            l_supplier_site_type (l_idxs).SUPP_ERROR_MSG,
                         SUPPLIER_NAME =
                            l_supplier_site_type (l_idxs).SUPPLIER_NAME,
                         vendor_id = l_supplier_site_type (l_idxs).vendor_id,
                         SUPP_SITE_PROCESS_FLAG =
                            l_supplier_site_type (l_idxs).SUPP_SITE_PROCESS_FLAG,
                         SUPP_SITE_ERROR_FLAG =
                            l_supplier_site_type (l_idxs).SUPP_SITE_ERROR_FLAG,
                         SUPP_SITE_ERROR_MSG =
                            l_supplier_site_type (l_idxs).SUPP_SITE_ERROR_MSG,
                         RGA_MARKED_FLAG =
                            l_supplier_site_type (l_idxs).RGA_MARKED_FLAG,
                         REMOVE_PRICE_STICKER_FLAG =
                            l_supplier_site_type (l_idxs).REMOVE_PRICE_STICKER_FLAG,
                         CONTACT_SUPPLIER_FOR_RGA =
                            l_supplier_site_type (l_idxs).CONTACT_SUPPLIER_FOR_RGA,
                         DESTROY_FLAG =
                            l_supplier_site_type (l_idxs).DESTROY_FLAG,
                         CCID = l_supplier_site_type (l_idxs).CCID,
                         BILL_TO_LOC_ID =
                            l_supplier_site_type (l_idxs).BILL_TO_LOC_ID,
                         terms_date_basis_code =
                            l_supplier_site_type (l_idxs).terms_date_basis_code,
                         terms_id = l_supplier_site_type (l_idxs).terms_id,
                         PAY_GROUP_CODE =
                            l_supplier_site_type (l_idxs).PAY_GROUP_CODE,
                         RTV_OPTION_DR =
                            l_supplier_site_type (l_idxs).RTV_OPTION_DR,
                         RTV_FRT_PMT_METHOD_DR =
                            l_supplier_site_type (l_idxs).RTV_FRT_PMT_METHOD_DR,
                         PI_PACK_YEAR = l_supplier_site_type (l_idxs).PI_PACK_YEAR,
                         delivery_policy_dr = gc_delivery_policy,
                         supplier_ship_to_dr = gc_supplier_ship_to,
                         edi_distribution_dr = gc_edi_distribution,
                         SERIAL_REQUIRED_FLAG = gc_serial_required_flag,
                         obsolete_item_dr = gc_obsolete_item_dr,
                         CREATE_FLAG =
                            l_supplier_site_type (l_idxs).create_flag
               WHERE supplier_name = l_supplier_site_type(l_idxs).supplier_name
                 AND address_line1 =   l_supplier_site_type(l_idxs).address_line1
                 AND (address_line2 IS NULL or address_line2 =   l_supplier_site_type(l_idxs).address_line2)
                 AND (address_line3 IS NULL or address_line3 =   l_supplier_site_type(l_idxs).address_line3)
                 AND (address_line4 IS NULL or address_line4 =   l_supplier_site_type(l_idxs).address_line4)
                 AND request_id = ln_request_id;
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  l_error_message :=
                     'When No Data Found during the bulk update of site staging table';

                  --============================================================================
                  -- To Insert into Common Error Table
                  --============================================================================
                  lc_all_error_messages := NULL;
                  insert_error (
                     p_all_error_messages   => lc_all_error_messages,
                     p_primary_key          => NULL,
                     p_error_code           => 'XXOD_BULK_UPD_SITE',
                     p_stage_col1           => 'NULL',
                     p_stage_val1           => NULL);

                  print_debug_msg (
                     p_message   => l_program_step || ': ' || l_error_message,
                     p_force     => TRUE);
               WHEN OTHERS
               THEN
                  l_error_message :=
                        'When Others Exception  during the bulk update of site staging table'
                     || SQLCODE
                     || ' - '
                     || SUBSTR (SQLERRM, 1, 3800);
                  --============================================================================
                  -- To Insert into Common Error Table
                  --============================================================================
                  lc_all_error_messages := '';
                  insert_error (
                     p_all_error_messages   => lc_all_error_messages,
                     p_primary_key          => NULL,
                     p_error_code           => 'XXOD_BULK_UPD_SITE',
                     p_stage_col1           => 'NULL',
                     p_stage_val1           => NULL);

                  print_debug_msg (
                     p_message   => l_program_step || ': ' || l_error_message,
                     p_force     => TRUE);
            END;
         END IF;                          -- IF l_supplier_site_type.COUNT > 0

         EXIT WHEN c_supplier%NOTFOUND;
      END LOOP;                                             -- c_supplier loop

      CLOSE c_supplier;

      l_supplier_site_type.DELETE;



      l_sup_eligible_cnt := 0;
      l_sup_val_load_cnt := 0;
      l_sup_error_cnt := 0;
      l_sup_val_not_load_cnt := 0;
      l_sup_ready_process := 0;

      OPEN c_sup_stats;

      FETCH c_sup_stats
         INTO l_sup_eligible_cnt,
              l_sup_val_load_cnt,
              l_sup_error_cnt,
              l_sup_ready_process;

      CLOSE c_sup_stats;

      l_supsite_eligible_cnt := 0;
      l_supsite_val_load_cnt := 0;
      l_supsite_error_cnt := 0;
      --l_supsite_val_not_load_cnt := 0;
      l_supsite_ready_process := 0;

      OPEN c_sup_site_stats;

      FETCH c_sup_site_stats
         INTO l_supsite_eligible_cnt,
              l_supsite_val_load_cnt,
              l_supsite_error_cnt,
              l_supsite_ready_process;

      CLOSE c_sup_site_stats;


      x_ret_code := l_ret_code;
      x_return_status := l_return_status;
      x_err_buf := l_err_buff;

      x_val_records := l_sup_val_load_cnt + l_supsite_val_load_cnt;
      x_inval_records := l_supsite_error_cnt + l_supsite_eligible_cnt;

      print_debug_msg (
         p_message   => '--------------------------------------------------------------------------------------------',
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'SUPPLIER - Successfully Validated are '
                        || l_sup_val_load_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'SUPPLIER - Validated and Errored are '
                        || l_sup_error_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'SUPPLIER - Eligible for Validation but Untouched  are '
                        || l_sup_eligible_cnt,
         p_force     => TRUE);
      print_debug_msg (p_message => '----------------------', p_force => TRUE);
      print_debug_msg (
         p_message   =>    'SUPPLIER SITE - Successfully Validated are '
                        || l_supsite_val_load_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'SUPPLIER SITE - Validated and Errored are '
                        || l_supsite_error_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'SUPPLIER SITE - Eligible for Validation but Untouched  are '
                        || l_supsite_eligible_cnt,
         p_force     => TRUE);
         /**
      print_debug_msg (
         p_message   => '--------------------------------------------------------------------------------------------',
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'Total Validated Records - x_val_records - '
                        || x_val_records,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'Total UnValidated Records - x_inval_records - '
                        || x_inval_records,
         p_force     => TRUE);
      print_debug_msg (
         p_message   => '--------------------------------------------------------------------------------------------',
         p_force     => TRUE);
       **/         

      --====================================================================================
      -- Error out the Untouched Supplier and Site records though eligible
      --====================================================================================

      IF (l_sup_eligible_cnt > 0 OR l_supsite_eligible_cnt > 0)
      THEN
         BEGIN
            print_debug_msg (
               p_message   => 'Erroring out the Untouched Supplier and Site records though eligible',
               p_force     => TRUE);

            l_upd_cnt := 0;

            UPDATE XX_AP_DI_SUPP_SITE_STG
               SET SUPP_PROCESS_FLAG = gn_validation_load_error,
                   SUPP_ERROR_FLAG = gc_process_error_flag,
                   SUPP_ERROR_MSG =
                         SUPP_ERROR_MSG
                      || 'This process is not validated though eligible. Pls. save the log of this Concurrent Program Request#'
                      || fnd_global.conc_request_id
                      || '  and inform to System Administrator.'
             WHERE     SUPP_PROCESS_FLAG = gn_validation_inprocess
                   AND request_id = fnd_global.conc_request_id;

            l_upd_cnt := SQL%ROWCOUNT;
            print_debug_msg (
               p_message   =>    'Set to Error for '
                              || l_upd_cnt
                              || ' supplier records as these are untouched though eligible.',
               p_force     => FALSE);


            UPDATE XX_AP_DI_SUPP_SITE_STG
               SET SUPP_SITE_PROCESS_FLAG = gn_validation_load_error,
                   SUPP_SITE_ERROR_FLAG = gc_process_error_flag,
                   SUPP_SITE_ERROR_MSG =
                         SUPP_SITE_ERROR_MSG
                      || 'This site is not validated though eligible. Pls. save the log of this Concurrent Program Request#'
                      || fnd_global.conc_request_id
                      || '  and inform to System Administrator.'
             WHERE     SUPP_SITE_PROCESS_FLAG = gn_validation_inprocess
                   AND request_id = fnd_global.conc_request_id;

            l_upd_cnt := SQL%ROWCOUNT;
            print_debug_msg (
               p_message   =>    'Set to Error for '
                              || l_upd_cnt
                              || ' supplier site records as these are untouched though eligible.',
               p_force     => FALSE);
         EXCEPTION
            WHEN OTHERS
            THEN
               l_err_buff := SQLCODE || ' - ' || SUBSTR (SQLERRM, 1, 3500);
               print_debug_msg (
                  p_message   =>    'ERROR: Updating the Supplier Staging table for untouched supplier records - '
                                 || l_err_buff,
                  p_force     => TRUE);

               x_ret_code := '2';
               x_return_status := 'E';
               x_err_buf := l_err_buff;

               RETURN;
         END;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_err_buff := SQLCODE || ' - ' || SUBSTR (SQLERRM, 1, 3500);
         print_debug_msg (
            p_message   =>    'ERROR: Exception in validate_records() API - '
                           || l_err_buff,
            p_force     => TRUE);

         x_ret_code := '2';
         x_return_status := 'E';
         x_err_buf := l_err_buff;
   END validate_records;


   --+============================================================================+
   --| Name          : load_vendors                                        |
   --| Description   : This procedure will load the vendors into interface table  |
   --|                   for the validated records in staging table               |
   --|                                                                            |
   --| Parameters    : N/A                                                        |
   --|                                                                            |
   --| Returns       : N/A                                                        |
   --|                                                                            |
   --+============================================================================+
   PROCEDURE load_vendors (x_processed_records     OUT NUMBER,
                           x_unprocessed_records   OUT NUMBER,
                           x_ret_code              OUT NUMBER,
                           x_return_status         OUT VARCHAR2,
                           x_err_buf               OUT VARCHAR2)
   IS
      --==============================================================================
      -- Cursor Declarations for Suppliers
      --==============================================================================
      CURSOR c_supplier
      IS
         SELECT DISTINCT supplier_name,
                         create_flag,
                         SUPP_PROCESS_FLAG,
                         SUPP_ERROR_FLAG,
                         SUPP_ERROR_MSG
           FROM XX_AP_DI_SUPP_SITE_STG xas
          WHERE     (xas.SUPP_PROCESS_FLAG = gn_validation_success
                      OR (xas.SUPP_PROCESS_FLAG = gn_import_success   -- For duplicate Supplier, we need to create Supplier Site
                         AND xas.create_flag = 'N')
                    )
                AND xas.request_id = fnd_global.conc_request_id;

      --==============================================================================
      -- Cursor Declarations for Supplier Sites
      --==============================================================================
      CURSOR c_supplier_site (
         c_supplier_name   IN VARCHAR2)
      IS
         SELECT xsup_site.*
           FROM XX_AP_DI_SUPP_SITE_STG xsup_site
          WHERE     xsup_site.SUPP_SITE_PROCESS_FLAG = gn_validation_success
                AND xsup_site.request_id = fnd_global.conc_request_id
                AND xsup_site.supplier_name = c_supplier_name;

      --==============================================================================
      -- Cursor Declarations to get table statistics of Supplier Staging
      --==============================================================================
      CURSOR c_sup_stats
      IS
         SELECT SUM (
                   DECODE (SUPP_PROCESS_FLAG, gn_validation_inprocess, 1, 0)) -- Eligible to Validate and Load
                                                                             ,
                SUM (DECODE (SUPP_PROCESS_FLAG, gn_load_success, 1, 0)) -- Successfully Validated and Loaded
                                                                       ,
                SUM (
                   DECODE (SUPP_PROCESS_FLAG, gn_validation_load_error, 1, 0)) -- Validated and Errored out
                                                                              ,
                SUM (DECODE (SUPP_PROCESS_FLAG, gn_validation_success, 1, 0)) -- Successfully Validated but not loaded
                                                                             ,
                SUM (DECODE (SUPP_PROCESS_FLAG, gn_pending_status, 1, 0)) -- Ready for Process
           FROM (  SELECT supplier_name, supp_process_flag
                     FROM XX_AP_DI_SUPP_SITE_STG xadss
                    WHERE xadss.request_id = fnd_global.conc_request_id
                 GROUP BY xadss.supplier_name, xadss.supp_process_flag);

      --==============================================================================
      -- Cursor Declarations to get table statistics of Supplier Site Staging
      --==============================================================================
      CURSOR c_sup_site_stats
      IS
         SELECT SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG,
                           gn_validation_inprocess, 1,
                           0))                -- Eligible to Validate and Load
                              ,
                SUM (DECODE (SUPP_SITE_PROCESS_FLAG, gn_load_success, 1, 0)) -- Successfully Validated and Loaded
                                                                            ,
                SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG,
                           gn_validation_load_error, 1,
                           0))                    -- Validated and Errored out
                              ,
                SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG,
                           gn_validation_success, 1,
                           0))        -- Successfully Validated but not loaded
                              ,
                SUM (
                   DECODE (SUPP_SITE_PROCESS_FLAG, gn_pending_status, 1, 0)) -- Ready for Process
           FROM XX_AP_DI_SUPP_SITE_STG
          WHERE request_id = fnd_global.conc_request_id;



      l_sup_rec_exists              NUMBER (10) DEFAULT 0;
      l_sup_site_rec_exists         NUMBER (10) DEFAULT 0;

      l_process_status_flag         VARCHAR2 (1);
      l_process_site_status_flag    VARCHAR2 (1);

      l_vendor_id                   NUMBER;
      l_vendor_site_id              NUMBER;
      l_party_site_id               NUMBER;
      l_party_id                    NUMBER;
      l_vendor_site_code            VARCHAR2 (50);
      l_user_id                     NUMBER := fnd_global.user_id;
      l_login_id                    NUMBER := fnd_global.login_id;


      --=========================================================================================
      -- Variables Declaration used for getting the data into PL/SQL Table for processing
      --=========================================================================================
      TYPE l_sup_tab IS TABLE OF c_supplier%ROWTYPE
         INDEX BY BINARY_INTEGER;

      TYPE l_sup_site_cont_tab IS TABLE OF XX_AP_DI_SUPP_SITE_STG%ROWTYPE
         INDEX BY BINARY_INTEGER;

      --=================================================================
      -- Declaring Local variables
      --=================================================================
      l_supplier_type               l_sup_tab;
      l_sup_site                    l_sup_site_cont_tab;
      l_supplier_rec                ap_vendor_pub_pkg.r_vendor_rec_type;
      l_supplier_site_rec           ap_vendor_pub_pkg.r_vendor_site_rec_type;
      l_vendor_intf_id              NUMBER DEFAULT 0;
      l_vendor_site_intf_id         NUMBER DEFAULT 0;
      l_error_message               VARCHAR2 (2000) DEFAULT NULL;
      l_procedure                   VARCHAR2 (30) := 'LOAD_VENDORS';
      l_msg_data                    VARCHAR2 (2000) := NULL;
      l_msg_count                   NUMBER := 0;
      l_trans_count                 NUMBER := 0;
      lp_loopcont                   PLS_INTEGER := 0;
      lp_loopcnt                    PLS_INTEGER := 0;
      l_exception_msg               VARCHAR2 (1000);

      l_sup_loaded_recs             NUMBER := 0;
      l_sup_val_but_unloaded_recs   NUMBER := 0;
      l_supsite_loaded_recs         NUMBER := 0;
      l_supsite_val_unloaded_recs   NUMBER := 0;
      l_ret_code                    NUMBER;
      l_return_status               VARCHAR2 (100);
      l_err_buff                    VARCHAR2 (4000);

      l_sup_eligible_cnt            NUMBER := 0;
      l_sup_val_load_cnt            NUMBER := 0;
      l_sup_error_cnt               NUMBER := 0;
      l_sup_val_not_load_cnt        NUMBER := 0;
      l_sup_ready_process           NUMBER := 0;
      l_supsite_eligible_cnt        NUMBER := 0;
      l_supsite_val_load_cnt        NUMBER := 0;
      l_supsite_error_cnt           NUMBER := 0;
      l_supsite_val_not_load_cnt    NUMBER := 0;
      l_supsite_ready_process       NUMBER := 0;

      lc_step                       VARCHAR2 (1000) := 'load_vendors()';
      lc_all_error_messages         VARCHAR2 (4000) := NULL;
   BEGIN
      print_debug_msg (p_message   => ' load_vendors() - BEGIN',
                       p_force     => FALSE);

      --==============================================================================
      -- Default Process Status Flag as N means No Error Exists
      --==============================================================================
      l_process_status_flag := 'N';
      l_process_site_status_flag := 'N';
      l_sup_rec_exists := 0;
      l_sup_site_rec_exists := 0;
      l_error_message := NULL;
      lp_loopcnt := 0;
      lp_loopcont := 0;

      l_ret_code := 0;
      l_return_status := 'S';
      l_err_buff := NULL;

      OPEN c_supplier;

      LOOP
         FETCH c_supplier BULK COLLECT INTO l_supplier_type;

         IF l_supplier_type.COUNT > 0
         THEN
            print_debug_msg (
               p_message   => 'load_vendors() - l_supplier_type records processing.',
               p_force     => FALSE);

            FOR l_idx IN l_supplier_type.FIRST .. l_supplier_type.LAST
            LOOP
               --==============================================================================
               -- Initialize the Variable to N for Each Supplier
               --==============================================================================
               l_process_status_flag := 'N';
               l_process_site_status_flag := 'N';
               l_error_message := NULL;
               l_sup_rec_exists := 0;
               l_sup_site_rec_exists := 0;
               l_vendor_id := NULL;
               l_party_id := NULL;
               l_vendor_site_id := NULL;
               l_party_site_id := NULL;

               print_debug_msg (
                  p_message   =>    'load_vendors() - Create Flag of the supplier '
                                 || l_supplier_type (l_idx).supplier_name
                                 || ' is - '
                                 || l_supplier_type (l_idx).create_flag,
                  p_force     => FALSE);

               IF l_supplier_type (l_idx).create_flag = 'Y'
               THEN
                  --==============================================================================================
                  -- Calling the Vendor Interface Id for Passing it to Interface Table - Supplier Does Not Exists
                  --==============================================================================================
                  SELECT ap_suppliers_int_s.NEXTVAL
                    INTO l_vendor_intf_id
                    FROM SYS.DUAL;

                  --==============================================================================
                  -- Calling the Insertion of Data into standard interface table
                  --==============================================================================
                  IF l_process_status_flag = 'N'
                  THEN
                     print_debug_msg (
                        p_message   =>    lc_step
                                       || ' - Before inserting record into ap_suppliers_int with interface id -'
                                       || l_vendor_intf_id,
                        p_force     => FALSE);

                     BEGIN
                        INSERT
                          INTO ap_suppliers_int (vendor_interface_id,
                                                 vendor_name,
                                                 vendor_type_lookup_code,
                                                 status,
                                                 start_date_active,
                                                 created_by,
                                                 creation_date,
                                                 last_update_date,
                                                 last_updated_by)
                           VALUES (
                                     l_vendor_intf_id,
                                     TRIM (
                                        UPPER (
                                           l_supplier_type (l_idx).supplier_name)),
                                     gc_supplier_type_code,
                                     g_process_status_new,
                                     SYSDATE,
                                     l_user_id,
                                     SYSDATE,
                                     SYSDATE,
                                     l_user_id);

                        print_debug_msg (
                           p_message   =>    lc_step
                                          || ' - After successfully inserted the record for the supplier -'
                                          || l_supplier_type (l_idx).supplier_name,
                           p_force     => FALSE);
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           l_process_status_flag := 'Y';
                           l_error_message := SQLCODE || ' - ' || SQLERRM;
                           print_debug_msg (
                              p_message   =>    lc_step
                                             || ' ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'
                                             || l_supplier_type (l_idx).SUPPLIER_NAME
                                             || ': XXOD_SUPPLIER_INS_ERROR:'
                                             || SQLCODE
                                             || ' - '
                                             || l_error_message,
                              p_force     => TRUE);

                           lc_all_error_messages := '';

                           insert_error (
                              p_all_error_messages   => lc_all_error_messages,
                              p_primary_key          => l_supplier_type (
                                                          l_idx).SUPPLIER_NAME,
                              p_error_code           =>    'XXOD_SUPPLIER_INS_ERROR'
                                                        || SQLCODE
                                                        || ' - '
                                                        || SUBSTR (SQLERRM,
                                                                   1,
                                                                   2000),
                              p_error_message        =>    'Error while Inserting Records in Inteface Table'
                                                        || SQLCODE
                                                        || ' - '
                                                        || l_error_message,
                              p_stage_col1           => 'SUPPLIER_NAME',
                              p_stage_val1           => l_supplier_type (
                                                          l_idx).SUPPLIER_NAME,
                              p_table_name           => gc_sup_site_stg_table);
                     END;

                     IF l_process_status_flag = 'N'
                     THEN
                        l_supplier_type (l_idx).SUPP_PROCESS_FLAG :=
                           gn_load_success;

                        l_sup_loaded_recs := l_sup_loaded_recs + 1;
                     ELSIF l_process_status_flag = 'Y'
                     THEN
                        l_supplier_type (l_idx).SUPP_PROCESS_FLAG :=
                           gn_validation_load_error;
                        l_supplier_type (l_idx).SUPP_ERROR_FLAG :=
                           gc_process_error_flag;
                        l_supplier_type (l_idx).SUPP_ERROR_MSG :=
                           lc_all_error_messages;

                        l_sup_val_but_unloaded_recs :=
                           l_sup_val_but_unloaded_recs + 1;
                     END IF;

                     --==============================================================================
                     -- Calling the Vendor Site Cursor for inserting into standard interface table
                     --==============================================================================
                     IF l_process_status_flag = 'N'
                     THEN
                        FOR l_sup_site_type
                           IN c_supplier_site (
                                 l_supplier_type (l_idx).supplier_name)
                        LOOP
                           l_process_site_status_flag := 'N';
                           lc_step := 'SITEINTF';
                           lp_loopcnt := lp_loopcnt + 1;
                           l_vendor_site_code := NULL;

                           --==============================================================================
                           -- Calling the Vendor Site Interface Id for Passing it to Interface Table
                           --==============================================================================
                           SELECT ap_supplier_sites_int_s.NEXTVAL
                             INTO l_vendor_site_intf_id
                             FROM SYS.DUAL;

                           l_vendor_site_code :=
                              gn_address_name_prefix || l_vendor_site_intf_id;
                           -- As this vendor site is for 'Address Purpose' as 'Both' then no need to suffix this to vendorSiteCode

                           print_debug_msg (
                              p_message   =>    lc_step
                                             || ' : l_vendor_site_code - '
                                             || l_vendor_site_code,
                              p_force     => FALSE);

                           BEGIN
                              INSERT
                                INTO ap_supplier_sites_int (
                                        vendor_interface_id,
                                        vendor_site_interface_id,
                                        vendor_site_code,
                                        address_line1,
                                        address_line2,
                                        address_line3,
                                        address_line4,
                                        city,
                                        state,
                                        zip,
                                        country,
                                        terms_id,
                                        accts_pay_code_combination_id,
                                        terms_date_basis,
                                        purchasing_site_flag,
                                        pay_site_flag,
                                        org_id,
                                        status,
                                        pay_group_lookup_code,
                                        hold_all_payments_flag,
                                        hold_reason,
                                        attribute8,--  ,attribute14
                                        attribute4,
                                        email_address,
                                        bill_to_location_id,
                                        create_debit_memo_flag,
                                        created_by,
                                        creation_date,
                                        last_update_date,
                                        last_updated_by,
                                        supplier_notif_method,
                                        language)
                                 VALUES (
                                           l_vendor_intf_id,
                                           l_vendor_site_intf_id,
                                           l_vendor_site_code,
                                           LTRIM (
                                              RTRIM (
                                                 UPPER (
                                                    l_sup_site_type.address_line1))),
                                           LTRIM (
                                              RTRIM (
                                                 UPPER (
                                                    l_sup_site_type.address_line2))),
                                           LTRIM (
                                              RTRIM (
                                                 UPPER (
                                                    l_sup_site_type.address_line3))),
                                           LTRIM (
                                              RTRIM (
                                                 UPPER (
                                                    l_sup_site_type.address_line4))),
                                           gc_city,
                                           gc_state,
                                           gn_zip,
                                           gc_country_code,
                                           l_sup_site_type.terms_id,
                                           l_sup_site_type.ccid,
                                           l_sup_site_type.terms_date_basis_code,
                                           'Y',
                                           'Y',
                                           gn_us_org_id,
                                           g_process_status_new,
                                           l_sup_site_type.pay_group_code,
                                           gc_hold_for_payment,
                                           gc_payment_hold_reason,
                                           gc_site_category,--  ,l_sup_site_type.reference_num
                                           l_sup_site_type.gso_reference_no,
                                           l_sup_site_type.email_address,
                                           l_sup_site_type.bill_to_loc_id,
                                           gc_create_deb_memo_from_rts,
                                           l_user_id,
                                           SYSDATE,
                                           SYSDATE,
                                           l_user_id,
                                           gc_notif_method,
                                           gc_language);
                           EXCEPTION
                              WHEN OTHERS
                              THEN
                                 l_process_site_status_flag := 'Y';
                                 l_error_message :=
                                    SQLCODE || ' - ' || SQLERRM;
                                 print_debug_msg (
                                    p_message   =>    'Load_vendors() - ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'
                                                   || l_supplier_type (l_idx).SUPPLIER_NAME
                                                   || ': XXOD_SUPPLIER_INS_ERROR:'
                                                   || SQLCODE
                                                   || ' - '
                                                   || l_error_message,
                                    p_force     => TRUE);
                                 lc_all_error_messages := NULL;

                                 insert_error (
                                    p_all_error_messages   => lc_all_error_messages,
                                    p_primary_key          => l_supplier_type (
                                                                l_idx).SUPPLIER_NAME,
                                    p_error_code           =>    'XXOD_SUPP_SITE_INS_ERROR'
                                                              || SQLCODE
                                                              || ' - '
                                                              || SUBSTR (
                                                                    SQLERRM,
                                                                    1,
                                                                    2000),
                                    p_error_message        =>    'Error while Inserting Records in Site Inteface Table'
                                                              || SQLCODE
                                                              || ' - '
                                                              || l_error_message,
                                    p_stage_col1           => 'SUPPLIER_NAME',
                                    p_stage_val1           => l_supplier_type (
                                                                l_idx).SUPPLIER_NAME,
                                    p_table_name           => gc_sup_site_stg_table);
                           END;


                           l_sup_site (lp_loopcnt).supplier_name :=
                              l_sup_site_type.supplier_name;
                           l_sup_site (lp_loopcnt).vendor_site_code_int :=
                              l_vendor_site_code;
                           l_sup_site (lp_loopcnt).address_line1 :=
                              l_sup_site_type.address_line1;
                           l_sup_site (lp_loopcnt).address_line2 :=
                              l_sup_site_type.address_line2;
                           l_sup_site (lp_loopcnt).address_line3 :=
                              l_sup_site_type.address_line3;
                           l_sup_site (lp_loopcnt).address_line4 :=
                              l_sup_site_type.address_line4;

                           IF l_process_site_status_flag = 'N'
                           THEN
                              l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG :=
                                 gn_load_success;

                              l_supsite_loaded_recs :=
                                 l_supsite_loaded_recs + 1;
                           ELSIF l_process_site_status_flag = 'Y'
                           THEN
                              l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG :=
                                 gn_validation_load_error;
                              l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_FLAG :=
                                 gc_process_error_flag;
                              l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_MSG :=
                                 lc_all_error_messages;

                              l_supsite_val_unloaded_recs :=
                                 l_supsite_val_unloaded_recs + 1;
                           END IF;
                        END LOOP;                          -- Vendor Site Loop
                     ELSE    -- l_process_status_flag = 'N' Before Vendor Site
                        FOR l_sup_site_type
                           IN c_supplier_site (
                                 l_supplier_type (l_idx).supplier_name)
                        LOOP
                           lp_loopcnt := lp_loopcnt + 1;
                           l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG :=
                              gn_validation_load_error;
                           l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_FLAG :=
                              gc_process_error_flag;
                           l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_MSG :=
                                 'SUPPLIER ERROR - '
                              || l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_MSG;

                           l_supsite_val_unloaded_recs :=
                              l_supsite_val_unloaded_recs + 1;
                        END LOOP;
                     END IF; -- l_process_status_flag = 'N' Before Vendor Site
                  END IF;                      -- l_process_status_flag := 'N'
               ELSE            -- IF l_supplier_type (l_idx).create_flag = 'Y'
                  -- Setting the Processed Flag
                  --
                  --IF l_process_status_flag = 'N'
                  --THEN
                  l_supplier_type (l_idx).SUPP_PROCESS_FLAG := gn_load_success;

                  --ELSIF l_process_status_flag = 'Y'
                  --THEN
                  --   l_supplier_type (l_idx).status := 'ERROR';
                  --  set_step ('Sup Stg Status E');
                  --END IF;


                  --==============================================================================
                  -- Calling the Vendor Site Cursor for inserting into standard interface table
                  --==============================================================================
                  IF l_process_status_flag = 'N'
                  THEN
                     FOR l_sup_site_type
                        IN c_supplier_site (
                              l_supplier_type (l_idx).supplier_name)
                     LOOP
                        l_process_site_status_flag := 'N';
                        lp_loopcnt := lp_loopcnt + 1;
                        l_vendor_site_code := NULL;

                        --==============================================================================
                        -- Calling the Vendor Site Interface Id for Passing it to Interface Table
                        --==============================================================================
                        SELECT ap_supplier_sites_int_s.NEXTVAL
                          INTO l_vendor_site_intf_id
                          FROM SYS.DUAL;

                        l_vendor_site_code :=
                           gn_address_name_prefix || l_vendor_site_intf_id;
                        -- As this vendor site is for 'Address Purpose' as 'Both' then no need to suffix this to vendorSiteCode

                        print_debug_msg (
                           p_message   =>    'Load_vendors() - : l_vendor_site_code - '
                                          || l_vendor_site_code,
                           p_force     => FALSE);

                        BEGIN
                           INSERT
                             INTO ap_supplier_sites_int (
                                     vendor_id,
                                     vendor_site_interface_id,
                                     vendor_site_code,
                                     address_line1,
                                     address_line2,
                                     address_line3,
                                     address_line4,
                                     city,
                                     state,
                                     zip,
                                     country,
                                     terms_id,
                                     accts_pay_code_combination_id,
                                     terms_date_basis,
                                     purchasing_site_flag,
                                     pay_site_flag,
                                     org_id,
                                     status,
                                     pay_group_lookup_code,
                                     hold_all_payments_flag,
                                     hold_reason,
                                     attribute8,--  ,attribute14
                                     attribute4,
                                     email_address,
                                     bill_to_location_id,
                                     create_debit_memo_flag,
                                     created_by,
                                     creation_date,
                                     last_update_date,
                                     last_updated_by,
                                     supplier_notif_method,
                                     language)
                              VALUES (
                                        l_sup_site_type.vendor_id,
                                        l_vendor_site_intf_id,
                                        l_vendor_site_code,
                                        LTRIM (
                                           RTRIM (
                                              UPPER (
                                                 l_sup_site_type.address_line1))),
                                        LTRIM (
                                           RTRIM (
                                              UPPER (
                                                 l_sup_site_type.address_line2))),
                                        LTRIM (
                                           RTRIM (
                                              UPPER (
                                                 l_sup_site_type.address_line3))),
                                        LTRIM (
                                           RTRIM (
                                              UPPER (
                                                 l_sup_site_type.address_line4))),
                                        gc_city,
                                        gc_state,
                                        gn_zip,
                                        gc_country_code,
                                        l_sup_site_type.terms_id,
                                        l_sup_site_type.ccid,
                                        l_sup_site_type.terms_date_basis_code,
                                        'Y',
                                        'Y',
                                        gn_us_org_id,
                                        g_process_status_new,
                                        l_sup_site_type.pay_group_code,
                                        gc_hold_for_payment,
                                        gc_payment_hold_reason,
                                        gc_site_category,--  ,l_sup_site_type.reference_num
                                        l_sup_site_type.gso_reference_no,
                                        l_sup_site_type.email_address,
                                        l_sup_site_type.bill_to_loc_id,
                                        gc_create_deb_memo_from_rts,
                                        l_user_id,
                                        SYSDATE,
                                        SYSDATE,
                                        l_user_id,
                                        gc_notif_method,
                                        gc_language);
                        EXCEPTION
                           WHEN OTHERS
                           THEN
                              l_process_site_status_flag := 'Y';
                              l_error_message := SQLCODE || ' - ' || SQLERRM;
                              print_debug_msg (
                                 p_message   =>    'Load_vendors() - ERROR: while Inserting Records in Inteface Table- SUPPLIER_NAME:'
                                                || l_supplier_type (l_idx).SUPPLIER_NAME
                                                || ': XXOD_SUPPLIER_INS_ERROR:'
                                                || SQLCODE
                                                || ' - '
                                                || l_error_message,
                                 p_force     => TRUE);

                              lc_all_error_messages := '';

                              insert_error (
                                 p_all_error_messages   => lc_all_error_messages,
                                 p_primary_key          => l_supplier_type (
                                                             l_idx).SUPPLIER_NAME,
                                 p_error_code           =>    'XXOD_SUPP_SITE_INS_ERROR'
                                                           || SQLCODE
                                                           || ' - '
                                                           || SUBSTR (SQLERRM,
                                                                      1,
                                                                      2000),
                                 p_error_message        =>    'Error while Inserting Records in Site Inteface Table(Vendor Exist)'
                                                           || SQLCODE
                                                           || ' - '
                                                           || l_error_message,
                                 p_stage_col1           => 'SUPPLIER_NAME',
                                 p_stage_val1           => l_supplier_type (
                                                             l_idx).SUPPLIER_NAME,
                                 p_table_name           => gc_sup_site_stg_table);
                        END;

                        l_sup_site (lp_loopcnt).supplier_name :=
                           l_sup_site_type.supplier_name;
                        l_sup_site (lp_loopcnt).vendor_site_code_int :=
                           l_vendor_site_code;
                        l_sup_site (lp_loopcnt).address_line1 :=
                           l_sup_site_type.address_line1;
                        l_sup_site (lp_loopcnt).address_line2 :=
                           l_sup_site_type.address_line2;
                        l_sup_site (lp_loopcnt).address_line3 :=
                           l_sup_site_type.address_line3;
                        l_sup_site (lp_loopcnt).address_line4 :=
                           l_sup_site_type.address_line4;


                        IF l_process_site_status_flag = 'N'
                        THEN
                           l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG :=
                              gn_load_success;

                           l_supsite_loaded_recs := l_supsite_loaded_recs + 1;
                        ELSIF l_process_site_status_flag = 'Y'
                        THEN
                           l_sup_site (lp_loopcnt).SUPP_SITE_PROCESS_FLAG :=
                              gn_validation_load_error;
                           l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_FLAG :=
                              gc_process_error_flag;
                           l_sup_site (lp_loopcnt).SUPP_SITE_ERROR_MSG :=
                              gc_error_msg;

                           l_supsite_val_unloaded_recs :=
                              l_supsite_val_unloaded_recs + 1;
                        END IF;
                     END LOOP;                           -- Supplier Site Loop
                  END IF; -- l_process_status_flag = 'N' Before Starting Supplier Site
               END IF;         -- IF l_supplier_type (l_idx).create_flag = 'Y'
            END LOOP;         -- l_supplier_type.FIRST .. l_supplier_type.LAST
         END IF;                                  -- l_supplier_type.COUNT > 0

         --==============================================================================
         -- For Doing the Bulk Update
         --=============================================================================
         IF l_supplier_type.COUNT > 0
         THEN
            BEGIN
               FORALL l_idxs IN l_supplier_type.FIRST .. l_supplier_type.LAST
                  UPDATE XX_AP_DI_SUPP_SITE_STG
                     SET SUPP_PROCESS_FLAG =
                            l_supplier_type (l_idxs).SUPP_PROCESS_FLAG
                   WHERE     supplier_name =
                                l_supplier_type (l_idxs).supplier_name
                         AND request_id = fnd_global.conc_request_id
                         AND SUPP_PROCESS_FLAG = gn_validation_success;
            EXCEPTION
               WHEN OTHERS
               THEN
                  l_process_status_flag := 'Y';
                  l_error_message :=
                        'When Others Exception '
                     || SQLCODE
                     || ' - '
                     || SUBSTR (SQLERRM, 1, 3850);
            END;
         END IF;          -- l_supplier_type.COUNT For Bulk Update of Supplier

         IF l_sup_site.COUNT > 0
         THEN
            BEGIN
               FORALL l_idxss IN l_sup_site.FIRST .. l_sup_site.LAST
                  UPDATE XX_AP_DI_SUPP_SITE_STG
                     SET SUPP_SITE_PROCESS_FLAG =
                            l_sup_site (l_idxss).SUPP_SITE_PROCESS_FLAG,
                         vendor_site_code_int =
                            l_sup_site (l_idxss).vendor_site_code_int
                   WHERE     address_line1 =
                                l_sup_site (l_idxss).address_line1
                         AND (   address_line2 IS NULL
                              OR address_line2 =
                                    l_sup_site (l_idxss).address_line2)
                         AND (   address_line3 IS NULL
                              OR address_line3 =
                                    l_sup_site (l_idxss).address_line3)
                         AND (   address_line4 IS NULL
                              OR address_line4 =
                                    l_sup_site (l_idxss).address_line4)
                         AND supplier_name =
                                l_sup_site (l_idxss).supplier_name
                         AND request_id = fnd_global.conc_request_id
                         AND SUPP_SITE_PROCESS_FLAG = gn_validation_success;
            --    END LOOP;
            --      COMMIT;

            EXCEPTION
               WHEN OTHERS
               THEN
                  l_process_status_flag := 'Y';
                  l_error_message :=
                        'When Others Exception '
                     || SQLCODE
                     || ' - '
                     || SUBSTR (SQLERRM, 1, 3850);
            END;

            COMMIT;
         END IF;             -- l_sup_site_type.COUNT For Bulk Update of Sites

         EXIT WHEN c_supplier%NOTFOUND;
      END LOOP;                                         -- For Open c_supplier

      CLOSE c_supplier;

      l_supplier_type.DELETE;



      -- x_processed_records := l_sup_loaded_recs + l_supsite_loaded_recs;
      -- x_unprocessed_records := l_sup_val_but_unloaded_recs + l_supsite_val_unloaded_recs;
      x_ret_code := l_ret_code;
      x_return_status := l_return_status;
      x_err_buf := l_err_buff;

      l_sup_eligible_cnt := 0;
      l_sup_val_load_cnt := 0;
      l_sup_error_cnt := 0;
      l_sup_val_not_load_cnt := 0;
      l_sup_ready_process := 0;

      OPEN c_sup_stats;

      FETCH c_sup_stats
         INTO l_sup_eligible_cnt,
              l_sup_val_load_cnt,
              l_sup_error_cnt,
              l_sup_val_not_load_cnt,
              l_sup_ready_process;

      CLOSE c_sup_stats;

      l_supsite_eligible_cnt := 0;
      l_supsite_val_load_cnt := 0;
      l_supsite_error_cnt := 0;
      l_supsite_val_not_load_cnt := 0;
      l_supsite_ready_process := 0;

      OPEN c_sup_site_stats;

      FETCH c_sup_site_stats
         INTO l_supsite_eligible_cnt,
              l_supsite_val_load_cnt,
              l_supsite_error_cnt,
              l_supsite_val_not_load_cnt,
              l_supsite_ready_process;

      CLOSE c_sup_site_stats;

      x_processed_records := l_sup_val_load_cnt + l_supsite_val_load_cnt;
      x_unprocessed_records :=
           l_sup_error_cnt
         + l_supsite_error_cnt
         + l_sup_val_not_load_cnt
         + l_supsite_val_not_load_cnt;

      print_debug_msg (
         p_message   => '--------------------------------------------------------------------------------------------',
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - SUPPLIER - Records Validated and successfully Loaded are '
                        || l_sup_val_load_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - SUPPLIER - Records Validated and Errored are '
                        || l_sup_error_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - SUPPLIER - Records Validated Successfully but not loaded are '
                        || l_sup_val_not_load_cnt,
         p_force     => TRUE);
      print_debug_msg (p_message => '----------------------', p_force => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - SUPPLIER SITE - Records Validated and successfully Loaded are '
                        || l_supsite_val_load_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - SUPPLIER SITE - Records Validated and Errored are '
                        || l_supsite_error_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - SUPPLIER SITE - Records Validated Successfully but not loaded are '
                        || l_supsite_val_not_load_cnt,
         p_force     => TRUE);
      print_debug_msg (
         p_message   => '--------------------------------------------------------------------------------------------',
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - Total Processed Records are '
                        || x_processed_records,
         p_force     => TRUE);
      print_debug_msg (
         p_message   =>    'After Load Vendors - Total UnProcessed Records are '
                        || x_unprocessed_records,
         p_force     => TRUE);
      print_debug_msg (
         p_message   => '--------------------------------------------------------------------------------------------',
         p_force     => TRUE);


      /**
      print_debug_msg(p_message => 'Processed Supplier Records - l_sup_loaded_recs - '|| l_sup_loaded_recs
                    , p_force => true);
      print_debug_msg(p_message => 'Processed Supplier Site Records - l_supsite_loaded_recs - '|| l_supsite_loaded_recs
                    , p_force => true);
      print_debug_msg(p_message => 'UnProcessed Supplier Records - l_sup_val_but_unloaded_recs - '|| l_sup_val_but_unloaded_recs
                    , p_force => true);
      print_debug_msg(p_message => 'UnProcessed Supplier Site Records - l_supsite_val_unloaded_recs - '|| l_supsite_val_unloaded_recs
                    , p_force => true);
      print_debug_msg(p_message => 'Total Processed Records - x_processed_records - '|| x_processed_records
                    , p_force => true);
      print_debug_msg(p_message => 'Total UnProcessed Records - x_unprocessed_records - '|| x_unprocessed_records
                    , p_force => true);

      print_out_msg(p_message => '----------------------------------------------------------------------');
      print_out_msg(p_message => 'Processed Supplier Records are '|| l_sup_loaded_recs);
      print_out_msg(p_message => 'Processed Supplier Site Records are '|| l_supsite_loaded_recs);
      print_out_msg(p_message => 'UnProcessed Supplier Records are '|| l_sup_val_but_unloaded_recs);
      print_out_msg(p_message => 'UnProcessed Supplier Site Records are '|| l_supsite_val_unloaded_recs);
      print_out_msg(p_message => 'Total Processed Records are '|| x_processed_records);
      print_out_msg(p_message => 'Total UnProcessed Records are '|| x_unprocessed_records);
      print_out_msg(p_message => '----------------------------------------------------------------------');
      **/
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         --lc_error_status_flag := 'Y';
         l_error_message :=
               'Load_vendors() - EXCEPTION: ('
            || gc_package_name
            || '.'
            || l_procedure
            || '-'
            || 'load_vendors'
            || ') '
            || SQLERRM;
         print_debug_msg (p_message => l_error_message, p_force => TRUE);

         x_ret_code := 1;
         x_return_status := 'E';
         x_err_buf := l_error_message;
   END load_vendors;


   -- +============================================================================+
   -- | Procedure Name : post_update_defaults                                      |
   -- |                                                                            |
   -- | Description    : This procedure updates default values after the post Import programs|
   -- |                                                                            |
   -- |                                                                            |
   -- | Parameters     : N/A                                                        |
   -- |                                                                            |
   -- | Returns        : N/A                                                       |
   -- |                                                                            |
   -- +============================================================================+


   PROCEDURE post_update_defaults
   AS
      ln_vendor_id          NUMBER;
      ln_party_id           NUMBER;
      ln_obj_ver_no         NUMBER;
      lc_vendor_num         AP_SUPPLIERS.SEGMENT1%TYPE;
      ln_vend_id            NUMBER;
      ln_vend_site_id       NUMBER;
      ln_party_site_ID      NUMBER;
      ln_location_id        NUMBER;
      ln_org_id             NUMBER;
      lc_err_flag           VARCHAR2 (1) := 'N';
      lc_site_err_flag      VARCHAR2 (1) := 'N';
      l_vend_site_err_msg   VARCHAR2 (2000);

      l_error_status        VARCHAR2 (1) := 'N';
      l_error_msg           VARCHAR2 (2000);

      ln_conc_req_id        NUMBER := fnd_global.conc_request_id;
      ln_new_site_code      VARCHAR2 (100);


      CURSOR c_supp_tab
      IS
         SELECT DISTINCT supplier_name,
                         create_flag,
                         SUPP_PROCESS_FLAG,
                         SUPP_ERROR_FLAG,
                         SUPP_ERROR_MSG
           FROM XX_AP_DI_SUPP_SITE_STG xas
          WHERE     xas.SUPP_PROCESS_FLAG = gn_load_success
                AND xas.CREATE_FLAG = 'Y'
                AND xas.PROCESS_FLAG = 'I'
                AND xas.request_id = fnd_global.conc_request_id;

      CURSOR c_supp_site_tab
      IS
         SELECT *
           FROM XX_AP_DI_SUPP_SITE_STG
          WHERE     SUPP_SITE_PROCESS_FLAG = gn_load_success
                AND PROCESS_FLAG = 'I'
                AND request_id = fnd_global.conc_request_id;
   BEGIN
      /* Loop for CREATE_FLAG = 'Y'*/
      FOR r_supp_tab IN c_supp_tab
      LOOP
         lc_err_flag := 'N';
         print_debug_msg (p_message   => ' IN r_supp_tab LOOP :',
                          p_force     => FALSE);

         BEGIN
            SELECT vendor_id, party_id, segment1
              INTO ln_vendor_id, ln_party_id, lc_vendor_num
              FROM ap_suppliers
             WHERE vendor_name = r_supp_tab.supplier_name;
         EXCEPTION
            WHEN OTHERS
            THEN
               lc_err_flag := 'Y';

               UPDATE XX_AP_DI_SUPP_SITE_STG
                  SET SUPP_PROCESS_FLAG = gn_import_error,
                      SUPP_ERROR_MSG =
                         SUBSTR (
                               SUPP_ERROR_MSG
                            || ' : '
                            || r_supp_tab.supplier_name
                            || ' Seems Import Failed ',
                            1,
                            3999)
                WHERE     supplier_name = r_supp_tab.supplier_name
                      AND PROCESS_FLAG = 'I'
                      AND SUPP_PROCESS_FLAG = gn_load_success
                      AND request_id = ln_conc_req_id;

               print_debug_msg (
                  p_message   => ' EXCEPTION in select vendor_id:' || SQLERRM,
                  p_force     => TRUE);
         END;

         IF lc_err_flag <> 'Y'
         THEN
            BEGIN
               SELECT object_version_number
                 INTO ln_obj_ver_no
                 FROM hz_parties
                WHERE party_id = ln_party_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  print_debug_msg (
                     p_message   =>    ' EXCEPTION in select object_version_number:'
                                    || SQLERRM,
                     p_force     => TRUE);
            END;

            BEGIN
               UPDATE XX_AP_DI_SUPP_SITE_STG
                  SET SUPP_PROCESS_FLAG = gn_import_success
                      ,VENDOR_ID = ln_vendor_id
                      ,PARTY_ID = ln_party_id
                      ,VENDOR_NO = lc_vendor_num
                WHERE supplier_name = r_supp_tab.supplier_name
                      AND PROCESS_FLAG = 'I'
                      AND SUPP_PROCESS_FLAG = gn_load_success
                      AND request_id = ln_conc_req_id;
            EXCEPTION
               WHEN OTHERS
               THEN
                  print_debug_msg (
                     p_message   =>    ' EXCEPTION in UPDATE XX_AP_DI_SUPP_SITE_STG :'
                                    || SQLERRM,
                     p_force     => TRUE);

                  UPDATE XX_AP_DI_SUPP_SITE_STG
                     SET SUPP_PROCESS_FLAG = gn_import_error,
                         SUPP_ERROR_MSG =
                            SUBSTR (
                                  SUPP_ERROR_MSG
                               || ' : '
                               || r_supp_tab.supplier_name
                               || ' Not found in base tables ',
                               1,
                               3999)
                   WHERE     supplier_name = r_supp_tab.supplier_name
                         AND PROCESS_FLAG = 'I'
                         AND SUPP_PROCESS_FLAG = gn_load_success
                         AND request_id = ln_conc_req_id;
            END;
         END IF;

         COMMIT;
      END LOOP;

      /* END Loop for CREATE_FLAG = 'Y'*/

      /* LOOP for r_supp_site_tab cusrsor */
      FOR r_supp_site_tab IN c_supp_site_tab
      LOOP
         lc_site_err_flag := 'N';
         ln_vend_site_id := '';
         ln_party_site_ID := '';
         ln_location_id := NULL;

         l_error_status := 'N';
         l_error_msg := NULL;

         print_debug_msg (p_message   => 'IN LOOP r_supp_site_tab',
                          p_force     => FALSE);
         ln_vend_id := r_supp_site_tab.vendor_id;
         print_debug_msg (p_message   => 'Vendor Id :' ||ln_vend_id ,
                          p_force     => FALSE);

        
         IF lc_site_err_flag <> 'Y'
         THEN
            BEGIN
               SELECT VENDOR_SITE_ID,
                      PARTY_SITE_ID,
                      org_id,
                      location_id
                 INTO ln_vend_site_id,
                      ln_party_site_ID,
                      ln_org_id,
                      ln_location_id
                 FROM ap_supplier_sites_all
                WHERE     vendor_id = ln_vend_id
                      AND vendor_site_code =
                             r_supp_site_tab.vendor_site_code_int;
            EXCEPTION
               WHEN OTHERS
               THEN
                  ln_vend_site_id := '-1';
                  ln_party_site_ID := '-1';
            END;

            print_debug_msg (
               p_message   => 'ln_vend_site_id' || ln_vend_site_id,
               p_force     => FALSE);
            print_debug_msg (
               p_message   => 'ln_party_site_ID' || ln_party_site_ID,
               p_force     => FALSE);

            IF ln_vend_site_id != '-1'
            THEN
               BEGIN
                  UPDATE XX_AP_DI_SUPP_SITE_STG
                     SET VENDOR_ID = ln_vend_id,
                         VENDOR_SITE_ID = ln_vend_site_id,
                         PARTY_SITE_ID = ln_party_site_ID,
                         ORG_ID = ln_org_id,
                         location_id = ln_location_id,
                         SUPP_SITE_PROCESS_FLAG = gn_import_success
                   WHERE     supplier_name = r_supp_site_tab.supplier_name
                         AND vendor_site_code_int =
                                r_supp_site_tab.vendor_site_code_int
                         AND PROCESS_FLAG = 'I'
                         AND SUPP_SITE_PROCESS_FLAG = gn_load_success
                         AND request_id = ln_conc_req_id;

                  print_debug_msg (p_message   => 'Invoking Update_supp_site',
                                   p_force     => TRUE);
                  ln_new_site_code :=
                     gn_address_name_prefix || ln_vend_site_id;

                  BEGIN
                     XX_AP_SUPPLIER_VAL_PKG.update_supp_site (
                        p_vendor_id        => ln_vend_id,
                        p_vendor_site_id   => ln_vend_site_id,
                        p_party_site_id    => ln_party_site_ID,
                        p_org_id           => ln_org_id,
                        p_prefix           => gn_address_name_prefix,
                        p_error_status     => l_error_status,
                        p_error_mesg       => l_error_msg);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        print_debug_msg (
                           p_message   =>    'ERROR in Invoking update_supp_site :'
                                          || SQLERRM,
                           p_force     => TRUE);
                  END;

                  IF l_error_status = 'Y'
                  THEN
                     print_debug_msg (
                        p_message   =>    'SupplierSiteCode - '
                                       || gn_address_name_prefix
                                       || ln_vend_site_id
                                       || ' not updated correctly',
                        p_force     => TRUE);

                     UPDATE XX_AP_DI_SUPP_SITE_STG
                        SET SUPP_SITE_PROCESS_FLAG = gn_import_error,
                            SUPP_SITE_ERROR_FLAG = 'E',
                            VENDOR_SITECD_UPD_FLAG = 'E',
                            VENDOR_SITE_CODE = ln_new_site_code,
                            SUPP_SITE_ERROR_MSG =
                               SUBSTR (
                                     SUPP_SITE_ERROR_MSG
                                  || '-PostUpdate-XX_AP_SUPPLIER_VAL_PKG.update_supp_site-'
                                  || l_error_msg,
                                  1,
                                  3999)
                      WHERE     vendor_site_id = ln_vend_site_id
                            AND PROCESS_FLAG = 'I'
                            AND SUPP_SITE_PROCESS_FLAG = gn_import_success
                            AND request_id = ln_conc_req_id;
                  ELSE
                     UPDATE XX_AP_DI_SUPP_SITE_STG
                        SET VENDOR_SITECD_UPD_FLAG = 'Y',
                            VENDOR_SITE_CODE = ln_new_site_code
                      WHERE     vendor_site_id = ln_vend_site_id
                            AND PROCESS_FLAG = 'I'
                            AND SUPP_SITE_PROCESS_FLAG = gn_import_success
                            AND request_id = ln_conc_req_id;

                  END IF;
                  COMMIT;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     print_debug_msg (
                        p_message   =>    ' ERROR IN UPDATE XX_AP_DI_SUPP_SITE_STG :'
                                       || SQLERRM,
                        p_force     => TRUE);
               END;
            ELSE
               l_vend_site_err_msg :=
                     'vendor Site is not found for code:'
                  || r_supp_site_tab.vendor_site_code_int
                  || '. It seems supplier site failed in Supplier Site Open interface Import, pls. check the output of CP.';

               UPDATE XX_AP_DI_SUPP_SITE_STG
                  SET SUPP_SITE_PROCESS_FLAG = gn_import_error,
                      SUPP_SITE_ERROR_FLAG = 'E',
                      SUPP_SITE_ERROR_MSG =
                         SUBSTR (
                            SUPP_SITE_ERROR_MSG || ':' || l_vend_site_err_msg,
                            1,
                            3999)
                WHERE     supplier_name = r_supp_site_tab.supplier_name
                      AND vendor_site_code_int =
                             r_supp_site_tab.vendor_site_code_int
                      AND PROCESS_FLAG = 'I'
                      AND request_id = ln_conc_req_id
                      ANd SUPP_SITE_PROCESS_FLAG = gn_load_success;
            END IF;

            COMMIT;
         END IF;
      END LOOP;
   /* END LOOP for r_supp_site_tab cusrsor */



   EXCEPTION
      WHEN OTHERS
      THEN
         print_debug_msg (
            p_message   => ' IN EXCEPTION post_update_defaults :' || SQLERRM,
            p_force     => TRUE);
   END post_update_defaults;


   -- +============================================================================+
   -- | Procedure Name : xx_supp_dff                                                  |
   -- |                                                                            |
   -- | Description    : This procedure updates the dff values                        |
   -- |                                                                            |
   -- |                                                                            |
   -- | Parameters     : N/A                                                        |
   -- |                                                                            |
   -- | Returns        : N/A                                                       |
   -- |                                                                            |
   -- +============================================================================+

   PROCEDURE xx_supp_dff
   IS
      v_tst          VARCHAR2 (1);

      CURSOR C1
      IS
         SELECT vendor_site_id,
                ROWID drowid,
                delivery_policy_dr,
                supplier_ship_to_dr,
                PI_PACK_YEAR,
                OD_DATE_SIGNED,
                VENDOR_DATE_SIGNED,
                edi_distribution_dr,
                rtv_option_dr,
                rtv_frt_pmt_method_dr,
                RGA_MARKED_FLAG,
                REMOVE_PRICE_STICKER_FLAG,
                CONTACT_SUPPLIER_FOR_RGA,
                DESTROY_FLAG,
                SERIAL_REQUIRED_FLAG,
                obsolete_item_dr
           FROM XX_AP_DI_SUPP_SITE_STG
          WHERE     supp_site_Process_Flag = gn_import_success
                AND NVL (dff_process_Flag, 'N') = 'N'
                AND PROCESS_FLAG = 'I'; 

      v_error_flag   VARCHAR2 (1);
      v_kff_id       NUMBER;
   BEGIN
      FOR cur IN C1
      LOOP
         v_error_Flag := 'N';

         BEGIN
            SELECT xxfin.XX_PO_VENDOR_SITES_KFF_S.NEXTVAL
              INTO v_kff_id
              FROM DUAL;

            INSERT INTO xx_po_vendor_sites_kff (VS_KFF_ID,
                                                STRUCTURE_ID,
                                                ENABLED_FLAG,
                                                SUMMARY_FLAG,
                                                START_DATE_ACTIVE,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATE_DATE,
                                                SEGMENT3,
                                                SEGMENT6,
                                                SEGMENT14,
                                                SEGMENT15,
                                                SEGMENT16)
                 VALUES (v_kff_id,
                         101,
                         'Y',
                         'N',
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         cur.delivery_policy_dr,
                         cur.supplier_ship_to_dr,
                         cur.PI_PACK_YEAR,
                         TO_CHAR (cur.OD_DATE_SIGNED, 'DD-MON-YY'),
                         TO_CHAR (cur.VENDOR_DATE_SIGNED, 'DD-MON-YY'));

            UPDATE ap_supplier_sites_all
               SET attribute10 = v_kff_id
             WHERE vendor_site_id = cur.vendor_site_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_error_flag := 'Y';
         END;

         BEGIN
            SELECT xxfin.XX_PO_VENDOR_SITES_KFF_S.NEXTVAL
              INTO v_kff_id
              FROM DUAL;

            INSERT INTO xx_po_vendor_sites_kff (VS_KFF_ID,
                                                STRUCTURE_ID,
                                                ENABLED_FLAG,
                                                SUMMARY_FLAG,
                                                START_DATE_ACTIVE,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATE_DATE,
                                                SEGMENT37)
                 VALUES (v_kff_id,
                         50350,
                         'Y',
                         'N',
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         cur.edi_distribution_dr);

            UPDATE ap_supplier_sites_all
               SET attribute11 = v_kff_id
             WHERE vendor_site_id = cur.vendor_site_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_error_flag := 'Y';
         END;

         BEGIN
            SELECT xxfin.XX_PO_VENDOR_SITES_KFF_S.NEXTVAL
              INTO v_kff_id
              FROM DUAL;

            INSERT INTO xx_po_vendor_sites_kff (VS_KFF_ID,
                                                STRUCTURE_ID,
                                                ENABLED_FLAG,
                                                SUMMARY_FLAG,
                                                START_DATE_ACTIVE,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATE_DATE,
                                                SEGMENT40,
                                                SEGMENT41,
                                                SEGMENT50,
                                                SEGMENT51,
                                                SEGMENT52,
                                                SEGMENT53,
                                                SEGMENT54,
                                                SEGMENT55)
                 VALUES (v_kff_id,
                         50351,
                         'Y',
                         'N',
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         fnd_global.user_id,
                         SYSDATE,
                         cur.rtv_option_dr,
                         cur.rtv_frt_pmt_method_dr,
                         cur.RGA_MARKED_FLAG,
                         cur.REMOVE_PRICE_STICKER_FLAG,
                         cur.CONTACT_SUPPLIER_FOR_RGA,
                         cur.DESTROY_FLAG,
                         cur.SERIAL_REQUIRED_FLAG,
                         cur.obsolete_item_dr);

            UPDATE ap_supplier_sites_all
               SET attribute12 = v_kff_id
             WHERE vendor_site_id = cur.vendor_site_id;
         EXCEPTION
            WHEN OTHERS
            THEN
               v_error_flag := 'Y';
         END;

         IF v_error_Flag = 'Y'
         THEN
            UPDATE XX_AP_DI_SUPP_SITE_STG
               SET dff_process_Flag = 'E'
             WHERE ROWID = cur.drowid;
         ELSE
            UPDATE XX_AP_DI_SUPP_SITE_STG
               SET dff_process_Flag = 'Y'
             WHERE ROWID = cur.drowid;
         END IF;

         COMMIT;
      END LOOP;
   END xx_supp_dff;

   -- +============================================================================+
   -- | Procedure Name : post_update_main_prc                                                  |
   -- |                                                                            |
   -- | Description    : This procedure updates the dff values                        |
   -- |                                                                            |
   -- |                                                                            |
   -- | Parameters     : N/A                                                        |
   -- |                                                                            |
   -- | Returns       :                                                            |
   -- |                   x_errbuf                  OUT      VARCHAR2              |
   -- |                   x_retcode                 OUT      NUMBER                |
   -- |                                                                            |
   -- +============================================================================+

   PROCEDURE post_update_main_prc (x_errbuf       OUT NOCOPY VARCHAR2,
                                   x_retcode      OUT NOCOPY NUMBER)
   AS
      l_rept_req_id      NUMBER;
      l_phas_out         VARCHAR2 (60);
      l_status_out       VARCHAR2 (60);
      l_dev_phase_out    VARCHAR2 (60);
      l_dev_status_out   VARCHAR2 (60);
      l_message_out      VARCHAR2 (200);
      l_bflag            BOOLEAN;
      l_req_err_msg      VARCHAR2 (4000);
      l_log_msg          VARCHAR2 (500);
      lv_err_msg         VARCHAR2 (4000);
      l_user_id          NUMBER := FND_GLOBAL.USER_ID;
      l_resp_id          NUMBER := FND_GLOBAL.RESP_ID;
      l_resp_appl_id     NUMBER := FND_GLOBAL.RESP_APPL_ID;
      ln_conc_req_id     NUMBER := FND_GLOBAL.CONC_REQUEST_ID;
      lv_cnt_val_count   NUMBER;
      lc_boolean         BOOLEAN;
   BEGIN
      print_debug_msg (p_message   => 'Start of POST_UPDATE_MAIN_PRC ',
                       p_force     => FALSE);
      print_debug_msg (p_message   => 'CONC REQUEST ID :' || ln_conc_req_id,
                       p_force     => FALSE);
        

      /*Calling  Procedure post_update_defaults to update default ID */
      print_debug_msg (
         p_message   => '-----Invoking Procedure post_update_defaults-----',
         p_force     => FALSE);
      post_update_defaults;


      print_debug_msg (p_message   => '-----Invoking Procedure xx_supp_dff-----',
                       p_force     => TRUE);
      /*Calling  Procedure xx_supp_dff to load contact for the vendor site*/
      xx_supp_dff;

      print_debug_msg (p_message   => 'setting the telex column ',
                       p_force     => FALSE);

      BEGIN
         UPDATE AP_SUPPLIER_SITES_ALL assa
            SET telex = fnd_global.user_name
          WHERE assa.vendor_site_id IN (SELECT xadss.vendor_site_id
                                          FROM XX_AP_DI_SUPP_SITE_STG xadss
                                         WHERE     xadss.SUPP_SITE_PROCESS_FLAG =
                                                      gn_import_success
                                               AND xadss.request_id =
                                                      ln_conc_req_id);

         print_debug_msg (
            p_message   =>    'Updated telex column for - '
                           || SQL%ROWCOUNT
                           || ' rows',
            p_force     => TRUE);
      EXCEPTION
         WHEN OTHERS
         THEN
            x_retcode := 2;
            x_errbuf :=
                  'Exception in POST_UPDATE_MAIN_PRC() when updating telex column - '
               || SQLCODE
               || ' - '
               || SUBSTR (SQLERRM, 1, 3500);
            print_debug_msg (p_message   => 'x_errbuf  ' || x_errbuf,
                             p_force     => TRUE);
            RETURN;
      END;

      UPDATE XX_AP_DI_SUPP_SITE_STG
         SET PROCESS_FLAG = 'Y'
       WHERE PROCESS_FLAG = 'I' AND REQUEST_ID = ln_conc_req_id;

      COMMIT;


      print_debug_msg (p_message   => 'End of POST_UPDATE_MAIN_PRC ',
                       p_force     => FALSE);

   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf :=
               'Exception in POST_UPDATE_MAIN_PRC() - '
            || SQLCODE
            || ' - '
            || SUBSTR (SQLERRM, 1, 3500);
         print_debug_msg (p_message   => 'x_errbuf  ' || x_errbuf,
                          p_force     => TRUE);
   END post_update_main_prc;


   --+============================================================================+
   --| Name          : main                                                       |
   --| Description   : main procedure will be called from the concurrent program  |
   --|                 for Suppliers Interface                                    |
   --| Parameters    :   p_debug_level          IN       VARCHAR2                 |
   --| Returns       :                                                            |
   --|                   x_errbuf                  OUT      VARCHAR2              |
   --|                   x_retcode                 OUT      NUMBER                |
   --|                                                                            |
   --|                                                                            |
   --+============================================================================+
   PROCEDURE main_prc (x_errbuf           OUT NOCOPY VARCHAR2,
                       x_retcode          OUT NOCOPY NUMBER,
                       p_debug_level   IN            VARCHAR2)
   IS
      --================================================================
      --Declaring local variables
      --================================================================
      l_procedure             VARCHAR2 (30) := 'main_prc';
      l_log_start_date        DATE;
      l_log_end_date          DATE;
      l_out_start_date        DATE;
      l_out_end_date          DATE;
      l_log_elapse            VARCHAR2 (100);
      l_out_elapse            VARCHAR2 (100);
      l_ret_code              NUMBER;
      l_return_status         VARCHAR2 (100);
      l_err_buff              VARCHAR2 (4000);
      l_val_records           NUMBER;
      l_inval_records         NUMBER;
      l_processed_records     NUMBER;
      l_unprocessed_records   NUMBER;
      l_resp_id               NUMBER := FND_GLOBAL.RESP_ID;
      l_resp_appl_id          NUMBER := FND_GLOBAL.RESP_APPL_ID;

      l_rept_req_id           NUMBER;
      l_phas_out              VARCHAR2 (60);
      l_status_out            VARCHAR2 (60);
      l_dev_phase_out         VARCHAR2 (60);
      l_dev_status_out        VARCHAR2 (60);
      l_message_out           VARCHAR2 (200);
      l_bflag                 BOOLEAN;
      l_req_err_msg           VARCHAR2 (4000);

      lc_boolean              BOOLEAN;

      ln_request_id           NUMBER := fnd_global.conc_request_id;
      ln_user_id              NUMBER := fnd_global.user_id;
      ln_login_id             NUMBER := fnd_global.login_id;
      ln_child_request_id     NUMBER;
      ln_child_req_status     VARCHAR2 (100);
      ln_child_req_err_msg    VARCHAR2 (4000);
      l_error_message         VARCHAR2 (4000);
      
      is_go_head              VARCHAR2(1);
   BEGIN
      --================================================================
      --Initializing Global variables
      --================================================================
      gc_debug := p_debug_level;

      --================================================================
      --Adding parameters to the log file
      --================================================================
      print_debug_msg (
         p_message   => '+---------------------------------------------------------------------------+',
         p_force     => TRUE);

      print_debug_msg (p_message => 'Input Parameters', p_force => TRUE);

      print_debug_msg (
         p_message   => '+---------------------------------------------------------------------------+',
         p_force     => TRUE);

      print_debug_msg (p_message => '  ', p_force => TRUE);

      print_debug_msg (
         p_message   => 'Debug Flag :                  ' || p_debug_level,
         p_force     => TRUE);

      print_debug_msg (
         p_message   => '+---------------------------------------------------------------------------+',
         p_force     => TRUE);

      print_debug_msg (p_message => '  ', p_force => FALSE);
      print_debug_msg (p_message   => 'Start of package ' || gc_package_name,
                       p_force     => FALSE);

      print_debug_msg (p_message   => 'Start Procedure   ' || l_procedure,
                       p_force     => FALSE);

      print_debug_msg (p_message => '  ', p_force => FALSE);

      print_debug_msg (p_message   => 'Initializing Local Variables ',
                       p_force     => FALSE);

      l_ret_code := 0;
      l_return_status := 'S';
      l_err_buff := NULL;

      is_go_head := 'Y';
      
      --===================================================================
      -- delete all the data in staging table older than 90 days
      --===================================================================
         print_debug_msg (
            p_message   => 'Invoking the procedure purge_stage()',
            p_force     => FALSE);

         purge_stage (x_ret_code        => l_ret_code,
                             x_return_status   => l_return_status,
                             x_err_buf         => l_err_buff);

        IF   l_ret_code <> 0 THEN
        
             x_retcode := l_ret_code;
             x_errbuf := 'Exception-purge_stage()       - '||l_err_buff;
             is_go_head := 'N';            
        END IF;
      
          

      --===============================================================
      --Updating Request Id into DI Supplier and its Site Staging table     --
      --===============================================================

      UPDATE XX_AP_DI_SUPP_SITE_STG
         SET SUPP_PROCESS_FLAG = gn_validation_inprocess,
             SUPP_SITE_PROCESS_FLAG = gn_validation_inprocess,
             REQUEST_ID = ln_request_id,
             PROCESS_FLAG = 'I'
       WHERE SUPP_PROCESS_FLAG = gn_pending_status
         AND SUPP_SITE_PROCESS_FLAG = gn_pending_status;

      IF SQL%NOTFOUND
      THEN
         print_debug_msg (
            p_message   => 'Total No. of Supplier records ready to validate,load and import are 0');
      ELSIF SQL%FOUND
      THEN
         print_debug_msg (
            p_message   =>    'Total No. of Supplier records ready to validate, load and import are '
                           || SQL%ROWCOUNT);
      END IF;


      --===============================================================
      -- Validate the records invoking the API  validate_records()    --
      --===============================================================

      IF is_go_head = 'Y'  THEN
          
          print_debug_msg (
             p_message   => 'Invoking the procedure validate_records()',
             p_force     => FALSE);

          validate_records (x_val_records     => l_val_records,
                            x_inval_records   => l_inval_records,
                            x_ret_code        => l_ret_code,
                            x_return_status   => l_return_status,
                            x_err_buf         => l_err_buff);

          print_debug_msg (
             p_message   => '===========================================================================',
             p_force     => TRUE);
          print_debug_msg (
             p_message   => 'Completed the execution of the procedure validate_records()',
             p_force     => TRUE);
          print_debug_msg (p_message   => 'l_val_records - ' || l_val_records,
                           p_force     => TRUE);
          print_debug_msg (p_message   => 'l_inval_records - ' || l_inval_records,
                           p_force     => TRUE);
          print_debug_msg (p_message   => 'l_ret_code - ' || l_ret_code,
                           p_force     => TRUE);
          print_debug_msg (p_message   => 'l_return_status - ' || l_return_status,
                           p_force     => TRUE);
          print_debug_msg (p_message   => 'l_err_buff - ' || l_err_buff,
                           p_force     => TRUE);
          print_debug_msg (
             p_message   => '===========================================================================',
             p_force     => TRUE);

          IF (l_ret_code IS NULL OR l_ret_code <> 0) OR (l_val_records <= 0)
          THEN
             x_retcode := l_ret_code;
             x_errbuf := 'Exception-Validate_records()       - '||l_err_buff;
             
             is_go_head := 'N';
          END IF;
      
      END IF;

      --===========================================================================
      -- Load the validated records in staging table into interface table    --
      --===========================================================================
     
      IF is_go_head = 'Y'  THEN
          print_debug_msg (p_message   => 'Invoking the procedure load_vendors()',
                           p_force     => TRUE);

          load_vendors (x_processed_records     => l_processed_records,
                        x_unprocessed_records   => l_unprocessed_records,
                        x_ret_code              => l_ret_code,
                        x_return_status         => l_return_status,
                        x_err_buf               => l_err_buff);

          print_debug_msg (
             p_message   => '===========================================================================',
             p_force     => TRUE);
          print_debug_msg (
             p_message   => 'Completed the execution of the procedure load_vendors()',
             p_force     => TRUE);
          print_debug_msg (
             p_message   => 'l_processed_records - ' || l_processed_records,
             p_force     => TRUE);
          print_debug_msg (
             p_message   => 'l_unprocessed_records - ' || l_unprocessed_records,
             p_force     => TRUE);
          print_debug_msg (p_message   => 'l_ret_code - ' || l_ret_code,
                           p_force     => TRUE);
          print_debug_msg (p_message   => 'l_return_status - ' || l_return_status,
                           p_force     => TRUE);
          print_debug_msg (p_message   => 'l_err_buff - ' || l_err_buff,
                           p_force     => TRUE);
          print_debug_msg (
             p_message   => '===========================================================================',
             p_force     => TRUE);

          IF (l_ret_code IS NULL OR l_ret_code <> 0) OR (l_processed_records <= 0)
          THEN
             x_retcode := l_ret_code;
             x_errbuf := 'Exception-load_vendors()           - '||l_err_buff;
             
             is_go_head := 'N';
          END IF;
      END IF; -- load_vendors()  is_go_head = 'Y'
      

      IF is_go_head = 'Y'
      THEN
         --===========================================================================
         -- Invoke Oracle's Supplier Import Program    --
         --===========================================================================

         BEGIN
            ln_child_request_id := NULL;
            XX_AP_SUPPLIER_VAL_PKG.submit_supplier_import (
               p_request_id   => ln_child_request_id,
               p_status       => ln_child_req_status,
               p_error_msg    => ln_child_req_err_msg);


            IF ln_child_request_id = '-1'
            THEN
               print_debug_msg (p_message   => ln_child_req_err_msg,
                                p_force     => TRUE);

               UPDATE XX_AP_DI_SUPP_SITE_STG
                  SET SUPP_PROCESS_FLAG = gn_import_error,
                      SUPP_ERROR_FLAG = gc_process_error_flag,
                      SUPP_ERROR_MSG =
                         SUPP_ERROR_MSG || '- Supplier Import failed',
                      PROCESS_FLAG = gc_process_error_flag
                WHERE     SUPP_PROCESS_FLAG = gn_load_success
                      AND request_id = ln_request_id;

               UPDATE XX_AP_DI_SUPP_SITE_STG
                  SET SUPP_SITE_PROCESS_FLAG = gn_import_error,
                      SUPP_SITE_ERROR_FLAG = gc_process_error_flag,
                      SUPP_SITE_ERROR_MSG =
                         SUPP_SITE_ERROR_MSG || '- Supplier Import failed'
                WHERE     SUPP_SITE_PROCESS_FLAG = gn_load_success
                      AND request_id = ln_request_id;
               
               
               
               

               COMMIT;

               x_retcode := 1;
               x_errbuf := 'Exception-submitSupplierImport     - '||ln_child_req_err_msg;
               is_go_head := 'N';

            ELSE
               print_debug_msg (p_message   => 'Supplier Import Success',
                                p_force     => TRUE);

               ln_child_request_id := NULL;
               ln_child_req_err_msg := NULL;


               --===========================================================================
               -- For US, Invoke Oracle's Supplier Site Import Program                --
               --===========================================================================


               XX_AP_SUPPLIER_VAL_PKG.submit_supp_site_import (
                  p_ou           => gn_us_org_id,
                  p_request_id   => ln_child_request_id,
                  p_status       => ln_child_req_status,
                  p_error_msg    => ln_child_req_err_msg);

               IF ln_child_request_id = '-1'
               THEN
                  print_debug_msg (p_message   => ln_child_req_err_msg,
                                   p_force     => TRUE);

                  UPDATE XX_AP_DI_SUPP_SITE_STG
                     SET SUPP_SITE_PROCESS_FLAG = gn_import_error,
                         SUPP_SITE_ERROR_FLAG = gc_process_error_flag,
                         SUPP_SITE_ERROR_MSG =
                               SUPP_SITE_ERROR_MSG
                            || '- Supplier Site(OU_US) Import failed'
                   WHERE     SUPP_SITE_PROCESS_FLAG = gn_load_success
                         AND request_id = ln_request_id;

                  COMMIT;

                  x_retcode := 1;
                  x_errbuf := 'Exception-US-submitSupplierImport  - '||ln_child_req_err_msg;
                  is_go_head := 'N';

               ELSE
                  print_debug_msg (
                     p_message   =>    'Supplier Site Import Success for Org '
                                    || gc_us_ou,
                     p_force     => TRUE);
               END IF;

            END IF;                     -- IF ln_child_request_id = '-1'  THEN
         EXCEPTION
            WHEN OTHERS
            THEN
               l_error_message :=
                     'Import Programs - EXCEPTION        : ('
                  || gc_package_name
                  || '.'
                  || l_procedure
                  || '-'
                  || 'main_prc'
                  || ') '
                  || SQLERRM;
               print_debug_msg (p_message => l_error_message, p_force => TRUE);
               x_retcode := 2;
               x_errbuf := l_error_message;
               is_go_head := 'N';
         END;
      END IF;                               -- For Supplier Import IF is_go_head = 'Y' THEN


      IF is_go_head = 'Y' THEN
          BEGIN
             post_update_main_prc (x_errbuf => l_err_buff, x_retcode => l_ret_code);
          EXCEPTION
             WHEN OTHERS
             THEN
                l_error_message :=
                      'Post Update Programs - EXCEPTION   : ('
                   || gc_package_name
                   || '.'
                   || l_procedure
                   || '-'
                   || 'main_prc'
                   || ') '
                   || SQLERRM;
                print_debug_msg (p_message => l_error_message, p_force => TRUE);
                x_retcode := 2;
                x_errbuf := l_error_message;
                is_go_head := 'N';
          END;     
      END IF;
      

      IF is_go_head = 'N' THEN

        UPDATE XX_AP_DI_SUPP_SITE_STG
           SET SUPP_PROCESS_FLAG = gn_validation_load_error
               ,SUPP_ERROR_FLAG = gc_process_error_flag
               ,SUPP_ERROR_MSG = SUPP_ERROR_MSG || ' - Some Exception caught in main_prc() - '||substr(x_errbuf,1,500)
               ,SUPP_SITE_PROCESS_FLAG = gn_validation_load_error
               ,SUPP_SITE_ERROR_FLAG = gc_process_error_flag
               ,SUPP_SITE_ERROR_MSG = SUPP_SITE_ERROR_MSG || ' - '||substr(x_errbuf,1,500)
               ,PROCESS_FLAG = gc_process_error_flag
         WHERE SUPP_PROCESS_FLAG in (gn_validation_inprocess, gn_validation_success, gn_load_success, gn_import_success) 
           AND request_id = ln_request_id;

        COMMIT;
        
      END IF;
      
            
      lc_boolean := fnd_request.add_layout (template_appl_name      => 'XXFIN',
                                    template_code           => 'XXAPGSIR',
                                    template_language       => 'en',
                                    template_territory      => 'US',
                                    output_format           => 'EXCEL'
                                    );
      IF lc_boolean THEN
        print_debug_msg(p_message => 'Report Layout Added Successfully ', p_force => false);
      ELSE
        print_debug_msg(p_message => 'Report Layout Addition failed', p_force => true);
      END IF;

      print_debug_msg(p_message => 'Report Process - gn_request_id value is '||ln_request_id, p_force => true);
      

      l_rept_req_id := fnd_request.submit_request (application                    => 'XXFIN'
                                                    ,program                       => 'XXAPGSIR'
                                                    ,description                   => 'OD: AP GSO Supplier Site Add Report'
                                                    ,start_time                    => SYSDATE
                                                    ,sub_request                   => FALSE
                                                    ,argument1                     => ln_request_id
                                          );

      COMMIT;

      print_debug_msg(p_message => 'Report Request Submitted '||l_rept_req_id, p_force => true);
      print_out_msg(p_message => 'OD: AP GSO Supplier Site Add Report - Request Submitted with ID - '||l_rept_req_id);

      IF l_rept_req_id != 0
      THEN
              print_debug_msg(p_message => 'Call fnd_concurrent.wait_FOR_request', p_force => true);
              l_dev_phase_out := 'Start';

              WHILE UPPER (NVL (l_dev_phase_out, 'XX')) != 'COMPLETE'
              LOOP
                 l_bflag := fnd_concurrent.wait_for_request (l_rept_req_id
                                                                 ,5
                                                                 ,50
                                                                 ,l_phas_out
                                                                 ,l_status_out
                                                                 ,l_dev_phase_out
                                                                 ,l_dev_status_out
                                                                 ,l_message_out
                                                                 );
              END LOOP;
              print_out_msg(p_message => 'OD: AP GSO Supplier Site Add Report - Request with ID - '||l_rept_req_id||' completed successfully.');
      ELSE
              l_req_err_msg := 'Problem in calling OD: AP GSO Supplier Site Add Report after validation and loading';
              print_debug_msg(p_message => 'l_req_err_msg '||l_req_err_msg, p_force => true);
      END IF;
 
      print_debug_msg(p_message => 'Prepare to send the report as email attachment- ', p_force => false);
      send_rpt_output(ln_request_id);
          
      print_debug_msg(p_message => '*****Program completed successfully*****', p_force => true);
      IF x_errbuf IS NULL THEN
        x_errbuf := l_err_buff;
        x_retcode := l_ret_code;
      END IF;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         x_retcode := 2;
         x_errbuf :=
               'Exception in XX_AP_GSO_SUPPLIER_PKG.main_prc() - '
            || SQLCODE
            || ' - '
            || SUBSTR (SQLERRM, 1, 3500);
   END main_prc;
END XX_AP_GSO_SUPPLIER_PKG;
/
show errors;